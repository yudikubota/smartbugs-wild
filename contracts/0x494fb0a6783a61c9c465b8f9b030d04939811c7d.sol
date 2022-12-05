{{
  "language": "Solidity",
  "sources": {
    "contracts/X2ETHMarket.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./libraries/utils/ReentrancyGuard.sol";
import "./libraries/token/IERC20.sol";

import "./interfaces/IX2ETHFactory.sol";
import "./interfaces/IX2PriceFeed.sol";
import "./interfaces/IX2Token.sol";
import "./interfaces/IX2Market.sol";
import "./interfaces/IChi.sol";

contract X2ETHMarket is ReentrancyGuard, IX2Market {
    using SafeMath for uint256;

    // use a single storage slot
    // max uint64 has 19 digits so it can support the INITIAL_REBASE_DIVISOR
    // increasing by 10^9 times
    uint64 public override previousBullDivisor;
    uint64 public override previousBearDivisor;
    uint64 public override cachedBullDivisor;
    uint64 public override cachedBearDivisor;

    // use a single storage slot
    // max uint176 can store prices up to 52 digits
    uint176 public override lastPrice;
    uint80 public lastRound;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    // X2Token.balance uses uint128, max uint128 has 38 digits
    // with an initial rebase divisor of 10^10
    // and 18 decimals for ETH, collateral of up to 10 billion ETH
    // can be supported
    uint64 public constant INITIAL_REBASE_DIVISOR = 10**10;
    uint256 public constant MAX_DIVISOR = uint64(-1);
    int256 public constant MAX_PRICE = uint176(-1);

    uint256 public constant MAX_FUNDING_POINTS = 100; // 0.1%
    uint256 public constant FUNDING_POINTS_DIVISOR = 100000;
    uint256 public constant MIN_FUNDING_INTERVAL = 30 minutes;

    address public override bullToken;
    address public override bearToken;
    address public priceFeed;
    uint256 public multiplierBasisPoints;
    uint256 public maxProfitBasisPoints;
    uint256 public feeReserve;

    address public factory;
    IChi public chi;

    uint256 public fundingPoints;
    uint256 public fundingInterval;
    uint256 public lastFundingTime;

    bool public isInitialized;

    event DistributeFees(address feeReceiver, uint256 amount);
    event DistributeInterest(address feeReceiver, uint256 amount);
    event Rebase(uint256 price, uint64 bullDivisor, uint64 bearDivisor);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2ETHMarket: forbidden");
        _;
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *
                           msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function initialize(
        address _factory,
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints
    ) public {
        require(!isInitialized, "X2ETHMarket: already initialized");
        require(_maxProfitBasisPoints <= BASIS_POINTS_DIVISOR, "X2ETHMarket: maxProfitBasisPoints limit exceeded");
        isInitialized = true;

        factory = _factory;
        priceFeed = _priceFeed;
        multiplierBasisPoints = _multiplierBasisPoints;
        maxProfitBasisPoints = _maxProfitBasisPoints;

        lastPrice = uint176(latestPrice());
        require(lastPrice != 0, "X2ETHMarket: unsupported price feed");
    }

    function setFunding(uint256 _fundingPoints, uint256 _fundingInterval) public override onlyFactory {
        require(_fundingPoints <= MAX_FUNDING_POINTS, "X2ETHMarket: fundingPoints exceeds limit");
        require(_fundingInterval >= MIN_FUNDING_INTERVAL, "X2ETHMarket: fundingInterval below limit");

        fundingPoints = _fundingPoints;
        fundingInterval = _fundingInterval;
    }

    function setBullToken(address _bullToken) public onlyFactory {
        require(bullToken == address(0), "X2ETHMarket: bullToken already set");
        bullToken = _bullToken;
        cachedBullDivisor = INITIAL_REBASE_DIVISOR;
        previousBullDivisor = INITIAL_REBASE_DIVISOR;
    }

    function setBearToken(address _bearToken) public onlyFactory {
        require(bearToken == address(0), "X2ETHMarket: bearToken already set");
        bearToken = _bearToken;
        cachedBearDivisor = INITIAL_REBASE_DIVISOR;
        previousBearDivisor = INITIAL_REBASE_DIVISOR;
    }

    function setChi(IChi _chi) public onlyFactory {
        chi = _chi;
    }

    function buy(address _token, address _receiver) public payable nonReentrant returns (uint256) {
        return _buy(_token, _receiver);
    }

    function buyUsingChi(address _token, address _receiver) public payable nonReentrant discountCHI returns (uint256) {
        return _buy(_token, _receiver);
    }

    function sell(address _token, uint256 _amount, address _receiver) public nonReentrant returns (uint256) {
        return _sell(_token, _amount, _receiver, true);
    }

    function sellUsingChi(address _token, uint256 _amount, address _receiver) public nonReentrant discountCHI returns (uint256) {
        return _sell(_token, _amount, _receiver, true);
    }

    function sellAll(address _token, address _receiver) public nonReentrant returns (uint256) {
        uint256 amount = IERC20(_token).balanceOf(msg.sender);
        return _sell(_token, amount, _receiver, true);
    }

    function sellAllUsingChi(address _token, address _receiver) public nonReentrant discountCHI returns (uint256) {
        uint256 amount = IERC20(_token).balanceOf(msg.sender);
        return _sell(_token, amount, _receiver, true);
    }

    // since an X2Token's distributor can be set by the factory's gov,
    // the market should allow an option to sell the token without invoking
    // the distributor
    // this ensures that tokens can always be sold even if the distributor
    // is set to an address that intentionally fails when `distribute` is called
    function sellWithoutDistribution(address _token, uint256 _amount, address _receiver) public nonReentrant returns (uint256) {
        return _sell(_token, _amount, _receiver, false);
    }

    function rebase() public returns (bool) {
        uint256 _lastPrice = uint256(lastPrice);
        uint256 nextPrice = latestPrice();
        uint80 _latestRound = latestRound();
        uint256 _lastRound = lastRound;
        if (_latestRound == _lastRound) { return false; }

        (uint256 _cachedBullDivisor, uint256 _cachedBearDivisor) = getDivisors(_lastPrice, nextPrice);
        _updateLastFundingTime();

        // the latest round is just one after the last recorded round
        // so update the previous divisors to the cached divisors
        // and update the cached divisors to the latest divisors
        if (_latestRound == _lastRound + 1) {
            lastPrice = uint176(nextPrice);
            lastRound = _latestRound;
            previousBullDivisor = cachedBullDivisor;
            previousBearDivisor = cachedBearDivisor;
            cachedBullDivisor = uint64(_cachedBullDivisor);
            cachedBearDivisor = uint64(_cachedBearDivisor);

            emit Rebase(nextPrice, uint64(_cachedBullDivisor), uint64(_cachedBearDivisor));
            return true;
        }

        // if the previous price cannot be retrieved then
        // update the previous divisors to the cached divisors
        // and update the cached divisors to the latest divisors
        (bool ok, uint256 previousPrice) = getRoundPrice(_latestRound - 1);
        if (!ok) {
            lastPrice = uint176(nextPrice);
            lastRound = _latestRound;
            previousBullDivisor = cachedBullDivisor;
            previousBearDivisor = cachedBearDivisor;
            cachedBullDivisor = uint64(_cachedBullDivisor);
            cachedBearDivisor = uint64(_cachedBearDivisor);
            emit Rebase(nextPrice, uint64(_cachedBullDivisor), uint64(_cachedBearDivisor));
            return false;
        }

        (uint256 _previousBullDivisor, uint256 _previousBearDivisor) = getDivisors(_lastPrice, previousPrice);

        lastPrice = uint176(nextPrice);
        lastRound = _latestRound;
        previousBullDivisor = uint64(_previousBullDivisor);
        previousBearDivisor = uint64(_previousBearDivisor);
        cachedBullDivisor = uint64(_cachedBullDivisor);
        cachedBearDivisor = uint64(_cachedBearDivisor);
        emit Rebase(nextPrice, uint64(_cachedBullDivisor), uint64(_cachedBearDivisor));
        return true;
    }

    function distributeFees() public nonReentrant returns (uint256) {
        address feeReceiver = IX2ETHFactory(factory).feeReceiver();
        require(feeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 fees = feeReserve;
        feeReserve = 0;

        (bool success,) = feeReceiver.call{value: fees}("");
        require(success, "X2ETHMarket: transfer failed");

        emit DistributeFees(feeReceiver, fees);

        return fees;
    }

    function distributeInterest() public nonReentrant returns (uint256) {
        address feeReceiver = IX2ETHFactory(factory).feeReceiver();
        require(feeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 interest = interestReserve();

        (bool success,) = feeReceiver.call{value: interest}("");
        require(success, "X2ETHMarket: transfer failed");

        emit DistributeInterest(feeReceiver, interest);

        return interest;
    }

    function interestReserve() public view returns (uint256) {
        uint256 bullRefSupply = IX2Token(bullToken)._totalSupply();
        uint256 bearRefSupply = IX2Token(bearToken)._totalSupply();

        // the actual underlying supplies
        uint256 totalBulls = bullRefSupply.div(cachedBullDivisor);
        uint256 totalBears = bearRefSupply.div(cachedBearDivisor);

        uint256 balance = address(this).balance;
        return balance.sub(totalBulls).sub(totalBears).sub(feeReserve);
    }

    function getDivisor(address _token) public override view returns (uint256) {
        uint80 _lastRound = lastRound;
        uint80 _latestRound = latestRound();
        bool isBull = _token == bullToken;

        // if the latest round is the same as the last recorded round
        // then select the largest divisor from the previous and cached divisors
        if (_latestRound == _lastRound) {
            return isBull ? _max(previousBullDivisor, cachedBullDivisor) : _max(previousBearDivisor, cachedBearDivisor);
        }

        uint256 _lastPrice = uint256(lastPrice);
        uint256 nextPrice = latestPrice();
        (uint256 nextBullDivisor, uint256 nextBearDivisor) = getDivisors(_lastPrice, nextPrice);

        // if the latest round is just after the last recorded round
        // then select the largest divisor from the cached divisor and the
        // divisor for the next price
        if (_latestRound == _lastRound + 1) {
            return isBull ? _max(cachedBullDivisor, nextBullDivisor) : _max(cachedBearDivisor, nextBearDivisor);
        }

        (bool ok, uint256 previousPrice) = getRoundPrice(_latestRound - 1);
        // if the price just before the lastest round cannot be retrieved
        // then fallback to selecting the largest divisor from the cached divisor
        // and the divisor for the next price
        if (!ok) {
            return isBull ? _max(cachedBullDivisor, nextBullDivisor) : _max(cachedBearDivisor, nextBearDivisor);
        }

        (uint256 _previousBullDivisor, uint256 _previousBearDivisor) = getDivisors(_lastPrice, previousPrice);
        return isBull ? _max(_previousBullDivisor, nextBullDivisor) : _max(_previousBearDivisor, nextBearDivisor);
    }

    function getRoundPrice(uint80 round) public view returns (bool, uint256) {
        address _priceFeed = priceFeed;
        (, int256 price, , ,) = IX2PriceFeed(_priceFeed).getRoundData(round);
        if (price <= 0 || price > MAX_PRICE) {
            return (false, 0);
        }

        return (true, uint256(price));
    }

    function latestPrice() public override view returns (uint256) {
        int256 answer = IX2PriceFeed(priceFeed).latestAnswer();
        // avoid negative, zero or overflow values being returned
        if (answer <= 0 || answer > MAX_PRICE) {
            return uint256(lastPrice);
        }
        return uint256(answer);
    }

    function latestRound() public view returns (uint80) {
        return IX2PriceFeed(priceFeed).latestRound();
    }

    function getDivisors(uint256 _lastPrice, uint256 _nextPrice) public override view returns (uint256, uint256) {
        uint256 bullRefSupply = IX2Token(bullToken)._totalSupply();
        uint256 bearRefSupply = IX2Token(bearToken)._totalSupply();

        // the actual underlying supplies
        uint256 totalBulls = bullRefSupply.div(cachedBullDivisor);
        uint256 totalBears = bearRefSupply.div(cachedBearDivisor);

        // scope variables to avoid stack too deep errors
        {
        // refSupply is the smaller of the two supplies
        uint256 refSupply = totalBulls < totalBears ? totalBulls : totalBears;
        uint256 delta = _nextPrice > _lastPrice ? _nextPrice.sub(_lastPrice) : _lastPrice.sub(_nextPrice);
        // profit is [(smaller supply) * (change in price) / (last price)] * multiplierBasisPoints
        uint256 profit = refSupply.mul(delta).div(_lastPrice).mul(multiplierBasisPoints).div(BASIS_POINTS_DIVISOR);

        // cap the profit to the (max profit percentage) of the smaller supply
        uint256 maxProfit = refSupply.mul(maxProfitBasisPoints).div(BASIS_POINTS_DIVISOR);
        if (profit > maxProfit) { profit = maxProfit; }

        totalBulls = _nextPrice > _lastPrice ? totalBulls.add(profit) : totalBulls.sub(profit);
        totalBears = _nextPrice > _lastPrice ? totalBears.sub(profit) : totalBears.add(profit);
        }

        if (fundingPoints > 0 && fundingInterval > 0) {
            uint256 intervals = block.timestamp.sub(lastFundingTime).div(fundingInterval);
            if (intervals > 0) {
                if (totalBulls > totalBears) {
                    totalBulls = totalBulls.sub(totalBulls.mul(intervals).mul(fundingPoints).div(FUNDING_POINTS_DIVISOR));
                } else {
                    totalBears = totalBears.sub(totalBears.mul(intervals).mul(fundingPoints).div(FUNDING_POINTS_DIVISOR));
                }
            }
        }

        return (_getNextDivisor(bullRefSupply, totalBulls, cachedBullDivisor), _getNextDivisor(bearRefSupply, totalBears, cachedBearDivisor));
    }

    function _updateLastFundingTime() private {
        if (fundingPoints > 0 && fundingInterval > 0) {
            lastFundingTime = block.timestamp;
        }
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function _getNextDivisor(uint256 _refSupply, uint256 _nextSupply, uint256 _fallbackDivisor) private pure returns (uint256) {
        if (_nextSupply == 0) {
            return INITIAL_REBASE_DIVISOR;
        }

        // round up the divisor
        uint256 divisor = _refSupply.mul(10).div(_nextSupply).add(9).div(10);
        // prevent the cachedDivisor from overflowing or being set to 0
        if (divisor == 0 || divisor > MAX_DIVISOR) { return _fallbackDivisor; }

        return divisor;
    }

    function _collectFees(uint256 _amount) private returns (uint256) {
        uint256 fee = IX2ETHFactory(factory).getFee(address(this), _amount);
        if (fee == 0) { return 0; }

        feeReserve = feeReserve.add(fee);
        return fee;
    }

    function _buy(address _token, address _receiver) private returns (uint256) {
        bool isBull = _token == bullToken;
        require(isBull || _token == bearToken, "X2ETHMarket: unsupported token");
        uint256 amount = msg.value;
        require(amount > 0, "X2ETHMarket: insufficient collateral sent");

        rebase();

        uint256 fee = _collectFees(amount);
        uint256 depositAmount = amount.sub(fee);
        IX2Token(_token).mint(_receiver, depositAmount, isBull ? cachedBullDivisor : cachedBearDivisor);

        return depositAmount;
    }

    function _sell(address _token, uint256 _amount, address _receiver, bool distribute) private returns (uint256) {
        require(_token == bullToken || _token == bearToken, "X2ETHMarket: unsupported token");
        rebase();

        IX2Token(_token).burn(msg.sender, _amount, distribute);

        uint256 fee = _collectFees(_amount);
        uint256 withdrawAmount = _amount.sub(fee);
        (bool success,) = _receiver.call{value: withdrawAmount}("");
        require(success, "X2ETHMarket: transfer failed");

        return withdrawAmount;
    }
}
"
    },
    "contracts/libraries/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "contracts/libraries/utils/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
"
    },
    "contracts/libraries/token/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"
    },
    "contracts/interfaces/IX2ETHFactory.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2ETHFactory {
    function feeReceiver() external view returns (address);
    function getFee(address market, uint256 amount) external view returns (uint256);
}
"
    },
    "contracts/interfaces/IX2PriceFeed.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2PriceFeed {
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}
"
    },
    "contracts/interfaces/IX2Token.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Token {
    function distributor() external view returns (address);
    function _totalSupply() external view returns (uint256);
    function _balanceOf(address account) external view returns (uint256);
    function market() external view returns (address);
    function getDivisor() external view returns (uint256);
    function getReward(address account) external view returns (uint256);
    function costOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount, uint256 divisor) external;
    function burn(address account, uint256 amount, bool distribute) external;
    function setDistributor(address _distributor) external;
    function setInfo(string memory name, string memory symbol) external;
}
"
    },
    "contracts/interfaces/IX2Market.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Market {
    function bullToken() external view returns (address);
    function bearToken() external view returns (address);
    function latestPrice() external view returns (uint256);
    function lastPrice() external view returns (uint176);
    function getDivisor(address token) external view returns (uint256);
    function getDivisors(uint256 _lastPrice, uint256 _nextPrice) external view returns (uint256, uint256);
    function setFunding(uint256 fundingPoints, uint256 fundingInterval) external;
    function previousBullDivisor() external view returns (uint64);
    function previousBearDivisor() external view returns (uint64);
    function cachedBullDivisor() external view returns (uint64);
    function cachedBearDivisor() external view returns (uint64);
}
"
    },
    "contracts/interfaces/IChi.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IChi {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}