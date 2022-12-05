{{
  "language": "Solidity",
  "sources": {
    "contracts/xvix/TimeVault.sol": {
      "content": "//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../interfaces/IXVIX.sol";
import "../interfaces/ITimeVault.sol";
import "../interfaces/IX2Fund.sol";

contract TimeVault is ITimeVault, IERC20, ReentrancyGuard {
    using SafeMath for uint256;

    string public constant name = "XVIX TimeVault";
    string public constant symbol = "XVIX:TV";
    uint8 public constant decimals = 18;

    uint256 constant PRECISION = 1e30;

    uint256 public constant WITHDRAWAL_DELAY = 7 days;
    uint256 public constant WITHDRAWAL_WINDOW = 48 hours;

    address public token;
    address public gov;
    address public distributor;

    uint256 public override totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public withdrawalTimestamps;
    mapping (address => uint256) public withdrawalAmounts;
    mapping (uint256 => uint256) public override withdrawalSlots;

    uint256 public cumulativeRewardPerToken;
    mapping (address => uint256) public claimableReward;
    mapping (address => uint256) public previousCumulatedRewardPerToken;

    event Deposit(address account, uint256 amount);
    event BeginWithdrawal(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event GovChange(address gov);
    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "TimeVault: forbidden");
        _;
    }

    constructor(address _token) public {
        token = _token;
        gov = msg.sender;
    }

    receive() external payable {}

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setDistributor(address _distributor) external onlyGov {
        distributor = _distributor;
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "TimeVault: insufficient amount");
        address account = msg.sender;
        _updateRewards(account, true);

        IERC20(token).transferFrom(account, address(this), _amount);
        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Deposit(account, _amount);
        emit Transfer(address(0), account, _amount);
    }

    function beginWithdrawal(uint256 _amount) external nonReentrant {
        address account = msg.sender;
        require(_amount > 0, "TimeVault: insufficient amount");
        require(_amount <= balanceOf(account), "TimeVault: insufficient balance");

        _decreaseWithdrawalSlot(withdrawalTimestamps[account], withdrawalAmounts[account]);

        uint256 time = block.timestamp.add(WITHDRAWAL_DELAY);
        withdrawalTimestamps[account] = time;
        withdrawalAmounts[account] = _amount;

        _increaseWithdrawalSlot(time, _amount);
        emit BeginWithdrawal(account, _amount);
    }

    function withdraw(address _receiver) external nonReentrant {
        address account = msg.sender;
        _updateRewards(account, true);
        _withdraw(account, _receiver);
    }

    function withdrawWithoutDistribution(address _receiver) external nonReentrant {
        address account = msg.sender;
        _updateRewards(account, false);
        _withdraw(account, _receiver);
    }

    function claim(address _receiver) external nonReentrant {
        address _account = msg.sender;
        _updateRewards(_account, true);

        uint256 rewardToClaim = claimableReward[_account];
        claimableReward[_account] = 0;

        (bool success,) = _receiver.call{value: rewardToClaim}("");
        require(success, "TimeVault: transfer failed");

        emit Claim(_receiver, rewardToClaim);
    }

    function getWithdrawalSlot(uint256 _time) public pure returns (uint256) {
        return _time.div(WITHDRAWAL_WINDOW);
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function transfer(address /* recipient */, uint256 /* amount */) public override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function allowance(address /* owner */, address /* spender */) public view virtual override returns (uint256) {
        return 0;
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    // empty implementation, TimeVault tokens are non-transferrable
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) public virtual override returns (bool) {
        revert("TimeVault: non-transferrable");
    }

    function _withdraw(address _account, address _receiver) private {
        uint256 currentTime = block.timestamp;
        uint256 minTime = withdrawalTimestamps[_account];
        require(minTime != 0, "TimeVault: withdrawal not initiated");
        require(currentTime > minTime, "TimeVault: withdrawal timing not reached");

        uint256 maxTime = minTime.add(WITHDRAWAL_WINDOW);
        require(currentTime < maxTime, "TimeVault: withdrawal window already passed");

        uint256 amount = withdrawalAmounts[_account];
        require(amount <= balanceOf(_account), "TimeVault: insufficient amount");

        _decreaseWithdrawalSlot(minTime, amount);

        withdrawalTimestamps[_account] = 0;
        withdrawalAmounts[_account] = 0;

        balances[_account] = balances[_account].sub(amount);
        totalSupply = totalSupply.sub(amount);

        IXVIX(token).rebase();
        IERC20(token).transfer(_receiver, amount);

        emit Withdraw(_account, amount);
        emit Transfer(_account, address(0), amount);
    }

    function _increaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        uint256 slot = getWithdrawalSlot(_time);
        withdrawalSlots[slot] = withdrawalSlots[slot].add(_amount);
    }

    function _decreaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        if (_time == 0 || _amount == 0) { return; }
        uint256 slot = getWithdrawalSlot(_time);
        if (_amount > withdrawalSlots[slot]) {
            withdrawalSlots[slot] = 0;
            return;
        }
        withdrawalSlots[slot] = withdrawalSlots[slot].sub(_amount);
    }

    function _updateRewards(address _account, bool _distribute) private {
        uint256 blockReward;

        if (_distribute && distributor != address(0)) {
            blockReward = IX2Fund(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        // only update cumulativeRewardPerToken when there are stakers, i.e. when totalSupply > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (totalSupply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(totalSupply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        uint256 _previousCumulatedReward = previousCumulatedRewardPerToken[_account];
        uint256 _claimableReward = claimableReward[_account].add(
            uint256(balances[_account]).mul(_cumulativeRewardPerToken.sub(_previousCumulatedReward)).div(PRECISION)
        );

        claimableReward[_account] = _claimableReward;
        previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;
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
    "contracts/interfaces/IXVIX.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXVIX {
    function setGov(address gov) external;
    function normalDivisor() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
}
"
    },
    "contracts/interfaces/ITimeVault.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimeVault {
    function withdrawalSlots(uint256 slot) external view returns (uint256);
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