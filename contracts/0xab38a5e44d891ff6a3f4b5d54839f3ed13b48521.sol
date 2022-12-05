{{
  "language": "Solidity",
  "sources": {
    "contracts/X2Token.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/token/SafeERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IX2Fund.sol";
import "./interfaces/IX2Market.sol";
import "./interfaces/IX2Token.sol";

// rewards code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract X2Token is IERC20, IX2Token, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Ledger {
        uint128 balance;
        uint128 cost;
    }

    // max uint128 has 38 digits
    // the initial divisor has 10 digits
    // each 1 wei of rewards will increase cumulativeRewardPerToken by
    // 1*10^10 (PRECISION 10^20 / divisor 10^10)
    // assuming a supply of only 1 wei of X2Tokens
    // if the reward token has 18 decimals, total rewards of up to
    // 1 billion reward tokens is supported
    // max uint96 has 28 digits, so max claimable rewards also supports
    // 1 billion reward tokens
    struct Reward {
        uint128 previousCumulativeRewardPerToken;
        uint96 claimable;
        uint32 lastBoughtAt;
    }

    uint256 constant HOLDING_TIME = 10 minutes;
    uint256 constant PRECISION = 1e20;
    uint256 constant MAX_BALANCE = uint128(-1);
    uint256 constant MAX_REWARD = uint96(-1);
    uint256 constant MAX_CUMULATIVE_REWARD = uint128(-1);
    uint256 constant MAX_QUANTITY_POINTS = 1e30;

    string public name = "X2";
    string public symbol = "X2";
    uint8 public constant decimals = 18;

    // _totalSupply also tracks totalStaked
    uint256 public override _totalSupply;

    address public override market;
    address public factory;
    address public override distributor;
    address public override rewardToken;

    // ledgers track balances and costs
    mapping (address => Ledger) public ledgers;
    mapping (address => mapping (address => uint256)) public allowances;

    // track previous cumulated rewards and claimable rewards for accounts
    mapping(address => Reward) public rewards;
    // track overall cumulative rewards
    uint256 public override cumulativeRewardPerToken;

    bool public isInitialized;

    event Claim(address receiver, uint256 amount);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2Token: forbidden");
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == market, "X2Token: forbidden");
        _;
    }

    receive() external payable {}

    function initialize(address _factory, address _market) public {
        require(!isInitialized, "X2Token: already initialized");
        isInitialized = true;
        factory = _factory;
        market = _market;
    }

    function setDistributor(address _distributor, address _rewardToken) external override onlyFactory {
        distributor = _distributor;
        rewardToken = _rewardToken;
    }

    function setInfo(string memory _name, string memory _symbol) external override onlyFactory {
        name = _name;
        symbol = _symbol;
    }

    function mint(address _account, uint256 _amount, uint256 _divisor) external override onlyMarket {
        _mint(_account, _amount, _divisor);
    }

    function burn(address _account, uint256 _burnPoints, bool _distribute) external override onlyMarket returns (uint256) {
        return _burn(_account, _burnPoints, _distribute);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Token: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true, false);

        Reward storage reward = rewards[_account];
        uint256 rewardToClaim = reward.claimable;
        reward.claimable = 0;

        IERC20(rewardToken).transfer(_receiver, rewardToClaim);

        emit Claim(_receiver, rewardToClaim);
    }

    function getDivisor() public override view returns (uint256) {
        return IX2Market(market).getDivisor(address(this));
    }

    function lastBoughtAt(address _account) public override view returns (uint256) {
        return uint256(rewards[_account].lastBoughtAt);
    }

    function hasPendingPurchase(address _account) public view returns (bool) {
        return lastBoughtAt(_account) > block.timestamp.sub(HOLDING_TIME);
    }

    function getPendingProfit(address _account) public override view returns (uint256) {
        if (!hasPendingPurchase(_account)) {
            return 0;
        }

        uint256 balance = uint256(ledgers[_account].balance).div(getDivisor());
        uint256 cost = costOf(_account);
        return balance <= cost ? 0 : balance.sub(cost);
    }

    function balanceOf(address _account) public view override returns (uint256) {
        uint256 balance = uint256(ledgers[_account].balance).div(getDivisor());
        if (!hasPendingPurchase(_account)) {
            return balance;
        }
        uint256 cost = costOf(_account);
        return balance < cost ? balance : cost;
    }

    function _balanceOf(address _account) public view override returns (uint256) {
        return uint256(ledgers[_account].balance);
    }

    function costOf(address _account) public override view returns (uint256) {
        return uint256(ledgers[_account].cost);
    }

    function getReward(address _account) public override view returns (uint256) {
        return uint256(rewards[_account].claimable);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(!hasPendingPurchase(_sender), "X2Token: holding time not yet passed");
        require(_sender != address(0), "X2Token: transfer from the zero address");
        require(_recipient != address(0), "X2Token: transfer to the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_sender, _amount, divisor, true);
        _increaseBalance(_recipient, _amount, divisor, false);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount, uint256 _divisor) private {
        require(_account != address(0), "X2Token: mint to the zero address");

        _increaseBalance(_account, _amount, _divisor, true);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _burnPoints, bool _distribute) private returns (uint256) {
        require(_account != address(0), "X2Token: burn from the zero address");

        uint256 divisor = getDivisor();

        Ledger memory ledger = ledgers[_account];
        uint256 balance = uint256(ledger.balance).div(divisor);
        uint256 amount = balance.mul(_burnPoints).div(MAX_QUANTITY_POINTS);
        uint256 scaledAmount = amount;

        if (hasPendingPurchase(_account) && balance > ledger.cost) {
            // if there is a pending purchase and the user's balance
            // is greater than their cost, it means they have a pending profit
            // we scale up the amount to burn the proportional amount of
            // pending profit
            amount = uint256(ledger.cost).mul(_burnPoints).div(MAX_QUANTITY_POINTS);
            scaledAmount = amount.mul(balance).div(ledger.cost);
        }

        _decreaseBalance(_account, scaledAmount, divisor, _distribute);

        emit Transfer(_account, address(0), amount);

        return amount;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Token: approve from the zero address");
        require(_spender != address(0), "X2Token: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _increaseBalance(address _account, uint256 _amount, uint256 _divisor, bool _updateLastBoughtAt) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, true, _updateLastBoughtAt);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        uint256 nextBalance = uint256(ledger.balance).add(scaledAmount);
        require(nextBalance < MAX_BALANCE, "X2Token: balance limit exceeded");

        uint256 cost = uint256(ledger.cost).add(_amount);
        require(cost < MAX_BALANCE, "X2Token: cost limit exceeded");

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.add(scaledAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount, uint256 _divisor, bool _distribute) private {
        if (_amount == 0) { return; }

        uint256 cachedTotalSupply = _totalSupply;
        _updateRewards(_account, cachedTotalSupply, _distribute, false);

        uint256 scaledAmount = _amount.mul(_divisor);
        Ledger memory ledger = ledgers[_account];

        // since _amount is not zero, so scaledAmount should not be zero
        // if ledger.balance is zero, then uint256(ledger.balance).sub(scaledAmount)
        // should fail, so we can calculate cost with ...div(ledger.balance)
        // as ledger.balance should not be zero
        uint256 nextBalance = uint256(ledger.balance).sub(scaledAmount);
        uint256 cost = uint256(ledger.cost).mul(nextBalance).div(ledger.balance);

        ledgers[_account] = Ledger(
            uint128(nextBalance),
            uint128(cost)
        );

        _totalSupply = cachedTotalSupply.sub(scaledAmount);
    }

    function _updateRewards(address _account, uint256 _cachedTotalSupply, bool _distribute, bool _updateLastBoughtAt) private {
        uint256 blockReward;
        Reward memory reward = rewards[_account];

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when _totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (_cachedTotalSupply > 0 && blockReward > 0) {
            // PRECISION is 10^20 and the BASE_DIVISOR is 10^10
            // cachedTotalSupply = _totalSupply * divisor
            // the divisor will be around 10^10
            // if 1000 ETH worth is minted, then cachedTotalSupply = 1000 * 10^18 * 10^10 = 10^31
            // cumulativeRewardPerToken will increase by blockReward * 10^20 / (10^31)
            // if the blockReward is 0.001 REWARD_TOKENS
            // then cumulativeRewardPerToken will increase by 10^-3 * 10^18 * 10^20 / (10^31)
            // which is 10^35 / 10^31 or 10^4
            // if rewards are distributed every hour then at least 0.168 REWARD_TOKENS should be distributed per week
            // so that there will not be precision issues for distribution
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(_cachedTotalSupply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // ledgers[_account].balance = balance * divisor
        // this divisor will be around 10^10
        // assuming that cumulativeRewardPerToken increases by at least 10^4
        // the claimableReward will increase by balance * 10^10 * 10^4 / 10^20
        // if the total supply is 1000 ETH
        // a user must own at least 10^-6 ETH or 0.000001 ETH worth of tokens to get some rewards
        uint256 claimableReward = uint256(reward.claimable).add(
            uint256(ledgers[_account].balance).mul(_cumulativeRewardPerToken.sub(reward.previousCumulativeRewardPerToken)).div(PRECISION)
        );

        if (claimableReward > MAX_REWARD) {
            claimableReward = MAX_REWARD;
        }

        if (_cumulativeRewardPerToken > MAX_CUMULATIVE_REWARD) {
            _cumulativeRewardPerToken = MAX_CUMULATIVE_REWARD;
        }

        rewards[_account] = Reward(
            // update previous cumulative reward for sender
            uint128(_cumulativeRewardPerToken),
            uint96(claimableReward),
            _updateLastBoughtAt ? uint32(block.timestamp % 2**32) : reward.lastBoughtAt
        );
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
    "contracts/libraries/token/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    "contracts/interfaces/IX2Fund.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Fund {
    function distribute() external returns (uint256);
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
    function lastPrice() external view returns (uint256);
    function getFunding() external view returns (uint256, uint256);
    function getDivisor(address token) external view returns (uint256);
    function getDivisors(uint256 _lastPrice, uint256 _nextPrice) external view returns (uint256, uint256);
    function setAppFee(uint256 feeBasisPoints) external;
    function setFunding(uint256 divisor) external;
    function cachedBullDivisor() external view returns (uint128);
    function cachedBearDivisor() external view returns (uint128);
}
"
    },
    "contracts/interfaces/IX2Token.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2Token {
    function cumulativeRewardPerToken() external view returns (uint256);
    function lastBoughtAt(address account) external view returns (uint256);
    function getPendingProfit(address account) external view returns (uint256);
    function distributor() external view returns (address);
    function rewardToken() external view returns (address);
    function _totalSupply() external view returns (uint256);
    function _balanceOf(address account) external view returns (uint256);
    function market() external view returns (address);
    function getDivisor() external view returns (uint256);
    function getReward(address account) external view returns (uint256);
    function costOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount, uint256 divisor) external;
    function burn(address account, uint256 amount, bool distribute) external returns (uint256);
    function setDistributor(address _distributor, address _rewardToken) external;
    function setInfo(string memory name, string memory symbol) external;
}
"
    },
    "contracts/libraries/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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