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
"},"uniV2Staking.sol":{"content":"pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

interface synStakingInterface {
  // Stakes SYN
  function stake(uint256 amount) external;
  // Unstakes SYN
  function unstake(uint256 amount) external;
  // Claims any ETH owed to msg.sender for staking SYN
  function claimReward() external;
  // Emergency removes staked SYN
  function emergencyRemove(uint256 amount) external;
}

contract uniV2Staking is Owned {
  using SafeMath for uint256;

  struct userStakeStruct {
    uint256 uniV2Tokens;
    uint256 fpuEntered;
  }

  IERC20 public synToken;
  IERC20 public uniV2Token;
  synStakingInterface public synStaking;

  mapping(address => userStakeStruct) public userStake;
  // Map of original SYN owner -> amount of SYN they've staked via this contract
  mapping(address => uint) public stakedSyn;


  // Total amount of UniV2Tokens staked
  uint256 public uniV2TotalStaked;
  // Amount of fees per UniV2Token currently staked
  uint256 public fpuTotal;
  // Total fees this contract has earned that can be given to UniV2Token stakers
  uint256 public feesTotal;

  event feesIn(
    uint256 ethIn,
    uint256 fpuTotal,
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
  event newSynStaking(
    address oldSynStaking,
    address newSynStaking
  );

  constructor() public {
    synToken = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    // SYN-ETH pair https://info.uniswap.org/pair/0xdf27a38946a1ace50601ef4e10f07a9cc90d7231
    uniV2Token = IERC20(0xdF27A38946a1AcE50601Ef4e10f07A9CC90d7231);
    // Syn Staking impl
    setSynStaking(0xf21c4F3a748F38A0B244f649d19FdcC55678F576);
  }

  // Allow this contract to receive ETH
  receive() external payable {}

  // Stake uniV2Tokens
  function stake(uint256 amount) external {
    require(uniV2Token.transferFrom(msg.sender, address(this), amount));
    claimReward();
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.add(amount);
    userStake[msg.sender].fpuEntered = fpuTotal;
    uniV2TotalStaked = uniV2TotalStaked.add(amount);
    emit userStakeEvent(msg.sender, amount);
  }

  // Unstake uniV2Tokens
  function unstake(uint256 amount) external {
    require(userStake[msg.sender].uniV2Tokens >= amount);
    claimReward();
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.sub(amount);
    uniV2TotalStaked = uniV2TotalStaked.sub(amount);
    uniV2Token.transfer(msg.sender, amount);
    emit userUnStakeEvent(msg.sender, amount);
  }

  // Claims msg.sender's reward for staking uniV2Tokens
  function claimReward() public {
    // Claim earned ETH from SYN staking. This also forwards fees into synStaking
    synStaking.claimReward();
    // Update state to deal w/ earned ETH we just claimed
    updateTotals();
    // Give sender their owed ETH
    if(userStake[msg.sender].uniV2Tokens > 0) {
        uint256 ethOut = userStake[msg.sender].uniV2Tokens >= uniV2TotalStaked ?
                feesTotal : getUserRewards(msg.sender);
        userStake[msg.sender].fpuEntered = fpuTotal;
        feesTotal = feesTotal.sub(ethOut);
        msg.sender.transfer(ethOut);
        emit userClaimEvent(msg.sender, ethOut);
    }
  }

  function updateTotals() public {
    uint256 ethIn = address(this).balance.sub(feesTotal);
    if(ethIn > 0 && uniV2TotalStaked != 0) {
        uint256 addFpu = ethIn.mul(10**18).div(uniV2TotalStaked);
        fpuTotal = fpuTotal.add(addFpu);
        feesTotal = feesTotal.add(addFpu.mul(uniV2TotalStaked).div(10**18));
        emit feesIn(ethIn, fpuTotal, feesTotal);
    }
  }

  // Emergency removal of staked uniV2Tokens
  function emergencyRemove(uint256 amount) public {
    require(userStake[msg.sender].uniV2Tokens >= amount);
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.sub(amount);
    uniV2TotalStaked = uniV2TotalStaked.sub(amount);
    uniV2Token.transfer(msg.sender, amount);
  }

  function getUserRewards(address account) public view returns(uint256) {
      return(fpuTotal.sub(userStake[account].fpuEntered)
                .mul(userStake[account].uniV2Tokens).div(10**18));
  }

  // ---- Fns to add/remove SYN to stake via this contract ----

  // Note `stakeSyn` and `unstakeSyn` can result in ETH rewards being given to this
  // contract as a result of the `synStaking.(un)stake` call. This is okay because calls
  // to `stake`, `unstake`, and `claimReward` in this contract call `updateTotals`,
  // which will calculate ethIn based off any new eth balance this contract has
  // before it performs anything important

  // Stake SYN via this contract, giving all earned fees to this contract
  function stakeSyn(uint amount) external {
    uint synBalanceBefore = synToken.balanceOf(address(this));
    // Transfer the SYN into this contract first
    require(synToken.transferFrom(msg.sender, address(this), amount));
    // To cover the case of someone accidentally sending SYN directly to this contract.
    // It'll get staked and owned by whoever calls stakeSyn first
    uint synAmountToStake = synToken.balanceOf(address(this)).sub(synBalanceBefore);
    // Now allow synStaking to transfer our synAmountToStake SYN into synStaking
    synToken.approve(address(synStaking), synAmountToStake);
    // Stake it
    synStaking.stake(synAmountToStake);
    // Record that sender has staked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].add(synAmountToStake);
  }

  // Unstake SYN that has been staked via this contract, giving all earned fees to this contract
  function unstakeSyn(uint amount) external {
    // Prevent someone from unstaking more SYN than they have staked via this contract
    require(amount <= stakedSyn[msg.sender]);
    // Unstake it
    synStaking.unstake(amount);
    // Record that sender has unstaked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].sub(amount);
    // Transfer the syn that was unstaked from this contract to the sender
    require(synToken.transfer(msg.sender, amount));
  }

  function emergencyRemoveSyn(uint amount) external {
    // Prevent someone from emergency removing more syn than they have staked via this contract
    require(amount <= stakedSyn[msg.sender]);
    // Record that sender has unstaked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].sub(amount);
    // Emergency remove that syn
    synStaking.emergencyRemove(amount);
    // Transfer the syn that was removed from this contract to the sender
    require(synToken.transferFrom(address(this), msg.sender, amount));
  }

  // ---- Owner only ----

  function setSynStaking(address _synStaking) public onlyOwner() {
    address oldSynStaking = address(synStaking);
    synStaking = synStakingInterface(_synStaking);
    emit newSynStaking(
      oldSynStaking,
      _synStaking
    );
  }
}
"}}