{"IERC20.sol":{"content":"pragma solidity >= 0.6.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"ownable.sol":{"content":"pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"},"synstaking.sol":{"content":"pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

interface synStakingProxyInterface {
    function forwardfees() external;
}

contract synStaking is Owned {
  using SafeMath for uint256;

  constructor() public {
    SYNTKN = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    synStakingProxy = 0x0070F3e1147c03a1Bb0caF80035B7c362D312119;
    staking = synStakingProxyInterface(0x0070F3e1147c03a1Bb0caF80035B7c362D312119);
  }

  event feesIn(
      uint256 ethIn,
      uint256 fpsTotal,
      uint256 feesTotal
  );
  event userStakeEvent(
      address account,
      uint256 amount
  );
  event userUnStakeEvent(
      address account,
      uint256 amount
  );
  event userClaimEvent(
      address account,
      uint256 ethOut
  );

  IERC20 public SYNTKN;
  address public synStakingProxy;
  synStakingProxyInterface public staking;

  struct userStakeStruct {
    uint256 syn;
    uint256 fpsEntered;
  }

  uint256 public fpsTotal;
  uint256 public synTotal;
  uint256 public feesTotal;

  bool public stakingActive;

  mapping(address => userStakeStruct) public userStake;

    receive() external payable {
  }


  function stake(uint256 amount) public {
    require(SYNTKN.transferFrom(msg.sender, address(this), amount));
    claimReward();
    userStake[msg.sender].syn = userStake[msg.sender].syn.add(amount);
    userStake[msg.sender].fpsEntered = fpsTotal;
    synTotal = synTotal.add(amount);
    emit userStakeEvent(msg.sender, amount);
  }


  function unstake(uint256 amount) public {
    require(userStake[msg.sender].syn >= amount);
    claimReward();
    userStake[msg.sender].syn = userStake[msg.sender].syn.sub(amount);
    synTotal = synTotal.sub(amount);
    SYNTKN.transfer(msg.sender, amount);
    emit userUnStakeEvent(msg.sender, amount);
  }

  function claimReward() public {
    if(stakingActive && synStakingProxy.balance > 0) {
        staking.forwardfees();
    }
    updateTotals();
    if(userStake[msg.sender].syn > 0) {
        uint256 ethOut = userStake[msg.sender].syn >= synTotal ?
                feesTotal : getUserRewards(msg.sender);
        userStake[msg.sender].fpsEntered = fpsTotal;
        feesTotal = feesTotal.sub(ethOut);
        msg.sender.transfer(ethOut);
        emit userClaimEvent(msg.sender, ethOut);
    }
  }

  function updateTotals() public {
    uint256 ethIn = address(this).balance.sub(feesTotal);
    if(ethIn > 0 && synTotal != 0) {
        uint256 addFps = ethIn.mul(10**18).div(synTotal);
        fpsTotal = fpsTotal.add(addFps);
        feesTotal = feesTotal.add(addFps.mul(synTotal).div(10**18));
        emit feesIn(ethIn, fpsTotal, feesTotal);
    }
  }

  function emergencyRemove(uint256 amount) public {
    require(userStake[msg.sender].syn >= amount);
    userStake[msg.sender].syn = userStake[msg.sender].syn.sub(amount);
    synTotal = synTotal.sub(amount);
    SYNTKN.transfer(msg.sender, amount);
  }

  function getUserRewards(address account) public view returns(uint256) {
      return(fpsTotal.sub(userStake[account].fpsEntered)
                .mul(userStake[account].syn).div(10**18));
  }

  function setStakingStatus(bool status) public onlyOwner() {
    stakingActive = status;
  }
  function setStakingProxy(address stakingProxy) public onlyOwner() {
    synStakingProxy = stakingProxy;
    staking = synStakingProxyInterface(stakingProxy);
  }

}
"}}