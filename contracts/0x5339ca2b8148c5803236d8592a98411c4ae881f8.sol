{{
  "language": "Solidity",
  "sources": {
    "contracts/5/EIP1167/CloneFactory.sol": {
      "content": "pragma solidity 0.5.16;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}
"
    },
    "contracts/5/ERC20/ERC20NonTransferrable.sol": {
      "content": "pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20NonTransferrable is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        return false;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        return false;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return false;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return false;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    "contracts/5/Fantastic12.sol": {
      "content": "pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./standard_bounties/StandardBountiesWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ShareToken.sol";
import "./FeeModel.sol";

contract Fantastic12 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using StandardBountiesWrapper for address;

  // Constants
  string  public constant VERSION = "0.1.5";
  uint256 internal constant PRECISION = 10 ** 18;

  // Instance variables
  mapping(address => bool) public isMember;
  mapping(address => mapping(uint256 => bool)) public hasUsedSalt; // Stores whether a salt has been used for a member
  IERC20 public DAI;
  ShareToken public SHARE;
  FeeModel public FEE_MODEL;
  uint256 public MAX_MEMBERS;
  uint256 public memberCount;
  uint256 public withdrawLimit;
  uint256 public withdrawnToday;
  uint256 public lastWithdrawTimestamp;
  uint256 public consensusThresholdPercentage; // at least (consensusThresholdPercentage * memberCount / PRECISION) approvers are needed to execute an action
  bool public initialized;

  address payable[] internal issuersOrFulfillers;
  address[] internal approvers;

  // Modifiers
  modifier onlyMember {
    require(isMember[msg.sender], "Not member");
    _;
  }

  modifier withConsensus(
    bytes4           _funcSelector,
    bytes     memory _funcParams,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  ) {
    require(
      _consensusReached(
        consensusThreshold(),
        _funcSelector,
        _funcParams,
        _members,
        _signatures,
        _salts
      ), "No consensus");
    _;
  }

  modifier withUnanimity(
    bytes4           _funcSelector,
    bytes     memory _funcParams,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  ) {
    require(
      _consensusReached(
        memberCount,
        _funcSelector,
        _funcParams,
        _members,
        _signatures,
        _salts
      ), "No unanimity");
    _;
  }

  // Events
  event Shout(string message);
  event Declare(string message);
  event AddMember(address newMember, uint256 tribute);
  event RageQuit(address quitter);
  event PostBounty(uint256 bountyID, uint256 reward);
  event AddBountyReward(uint256 bountyID, uint256 reward);
  event RefundBountyReward(uint256 bountyID, uint256 refundAmount);
  event ChangeBountyData(uint256 bountyID);
  event ChangeBountyDeadline(uint256 bountyID);
  event AcceptBountySubmission(uint256 bountyID, uint256 fulfillmentID);
  event PerformBountyAction(uint256 bountyID);
  event FulfillBounty(uint256 bountyID);
  event UpdateBountyFulfillment(uint256 bountyID, uint256 fulfillmentID);

  // Initializer
  function init(
    address _summoner,
    address _DAI_ADDR,
    address _SHARE_ADDR,
    address _FEE_MODEL_ADDR,
    uint256 _summonerShareAmount
  ) public {
    require(! initialized, "Initialized");
    initialized = true;
    MAX_MEMBERS = 12;
    memberCount = 1;
    DAI = IERC20(_DAI_ADDR);
    SHARE = ShareToken(_SHARE_ADDR);
    FEE_MODEL = FeeModel(_FEE_MODEL_ADDR);
    issuersOrFulfillers = new address payable[](1);
    issuersOrFulfillers[0] = address(this);
    approvers = new address[](1);
    approvers[0] = address(this);
    withdrawLimit = PRECISION.mul(1000); // default: 1000 DAI
    consensusThresholdPercentage = PRECISION.mul(75).div(100); // default: 75%

    // Add `_summoner` as the first member
    isMember[_summoner] = true;
    // Mint share tokens for summoner
    SHARE.mint(_summoner, _summonerShareAmount);
  }

  // Functions

  /**
    Censorship-resistant messaging
   */
  function shout(string memory _message) public onlyMember {
    emit Shout(_message);
  }

  function declare(
    string memory _message,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.declare.selector,
      abi.encode(_message),
      _members,
      _signatures,
      _salts
    )
  {
    emit Declare(_message);
  }

  /**
    Member management
   */

  function addMembers(
    address[] memory _newMembers,
    uint256[] memory _tributes,
    uint256[] memory _shares,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.addMembers.selector,
      abi.encode(_newMembers, _tributes, _shares),
      _members,
      _signatures,
      _salts
    )
  {
    require(_newMembers.length == _tributes.length && _tributes.length == _shares.length, "_newMembers, _tributes, _shares not of the same length");
    for (uint256 i = 0; i < _newMembers.length; i = i.add(1)) {
      _addMember(_newMembers[i], _tributes[i], _shares[i]);
    }
  }

  function _addMember(
    address _newMember,
    uint256 _tribute,
    uint256 _share
  )
    internal
  {
    require(_newMember != address(0), "Member cannot be zero address");
    require(!isMember[_newMember], "Member cannot be added twice");
    require(memberCount < MAX_MEMBERS, "Max member count reached");

    // Receive tribute from `_newMember`
    require(DAI.transferFrom(_newMember, address(this), _tribute), "Tribute transfer failed");

    // Add `_newMember` to squad
    isMember[_newMember] = true;
    memberCount = memberCount.add(1);

    // Mint shares for `_newMember`
    _mintShares(_newMember, _share);

    emit AddMember(_newMember, _tribute);
  }

  function rageQuit() public {
    uint256 shareBalance = SHARE.balanceOf(msg.sender);
    uint256 withdrawAmount = DAI.balanceOf(address(this)).mul(shareBalance).div(SHARE.totalSupply());

    // Burn `msg.sender`'s share tokens
    SHARE.burn(msg.sender, shareBalance);

    // Give `msg.sender` their portion of the squad funds
    uint256 fee = FEE_MODEL.getFee(memberCount, withdrawAmount);
    DAI.safeTransfer(msg.sender, withdrawAmount.sub(fee));
    DAI.safeTransfer(FEE_MODEL.beneficiary(), fee);

    // Remove `msg.sender` from squad
    isMember[msg.sender] = false;
    memberCount = memberCount.sub(1);

    emit RageQuit(msg.sender);
  }

  function rageQuitWithTokens(address[] memory _tokens) public {
    uint256 shareBalance = SHARE.balanceOf(msg.sender);
    uint256 shareTotalSupply = SHARE.totalSupply();

    // Burn `msg.sender`'s share tokens
    SHARE.burn(msg.sender, shareBalance);

    // Give `msg.sender` their portion of the squad funds
    uint256 withdrawAmount;
    uint256 fee;
    for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
      if (_tokens[i] == address(0)) {
        // Ether
        withdrawAmount = address(this).balance.mul(shareBalance).div(shareTotalSupply);
        if (withdrawAmount == 0) break;
        fee = FEE_MODEL.getFee(memberCount, withdrawAmount);
        if (fee <= withdrawAmount) {
          msg.sender.transfer(withdrawAmount.sub(fee));
          FEE_MODEL.beneficiary().transfer(fee);
        } else {
          msg.sender.transfer(withdrawAmount);
        }
      } else {
        // ERC20 token
        IERC20 token = IERC20(_tokens[i]);
        withdrawAmount = token.balanceOf(address(this)).mul(shareBalance).div(shareTotalSupply);
        if (withdrawAmount == 0) break;
        fee = FEE_MODEL.getFee(memberCount, withdrawAmount);
        if (fee <= withdrawAmount) {
          token.safeTransfer(msg.sender, withdrawAmount.sub(fee));
          token.safeTransfer(FEE_MODEL.beneficiary(), fee);
        } else {
          token.safeTransfer(msg.sender, withdrawAmount);
        }
      }
    }

    // Remove `msg.sender` from squad
    isMember[msg.sender] = false;
    memberCount = memberCount.sub(1);

    emit RageQuit(msg.sender);
  }

  /**
    Fund management
   */

  function transferDAI(
    address[] memory _dests,
    uint256[] memory _amounts,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.transferDAI.selector,
      abi.encode(_dests, _amounts),
      _members,
      _signatures,
      _salts
    )
  {
    require(_dests.length == _amounts.length, "_dests not same length as _amounts");
    for (uint256 i = 0; i < _dests.length; i = i.add(1)) {
      _transferDAI(_dests[i], _amounts[i]);
    }
  }

  function transferTokens(
    address payable[] memory _dests,
    uint256[] memory _amounts,
    address[] memory _tokens,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.transferTokens.selector,
      abi.encode(_dests, _amounts, _tokens),
      _members,
      _signatures,
      _salts
    )
  {
    require(_dests.length == _amounts.length && _dests.length == _tokens.length, "_dests, _amounts, _tokens not of same length");
    for (uint256 i = 0; i < _dests.length; i = i.add(1)) {
      if (_tokens[i] == address(DAI)) {
        _transferDAI(_dests[i], _amounts[i]);
      } else {
        _transferToken(_tokens[i], _dests[i], _amounts[i]);
      }
    }
  }

  function mintShares(
    address[] memory _dests,
    uint256[] memory _amounts,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.mintShares.selector,
      abi.encode(_dests, _amounts),
      _members,
      _signatures,
      _salts
    )
  {
    require(_dests.length == _amounts.length, "_dests and _amounts not of same length");
    for (uint256 i = 0; i < _dests.length; i = i.add(1)) {
      _mintShares(_dests[i], _amounts[i]);
    }
  }

  /**
    Parameter setters
   */

  function setWithdrawLimit(
    uint256 _newLimit,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withUnanimity(
      this.setWithdrawLimit.selector,
      abi.encode(_newLimit),
      _members,
      _signatures,
      _salts
    )
  {
    withdrawLimit = _newLimit;
  }

  function setConsensusThreshold(
    uint256 _newThresholdPercentage,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withUnanimity(
      this.setConsensusThreshold.selector,
      abi.encode(_newThresholdPercentage),
      _members,
      _signatures,
      _salts
    )
  {
    require(_newThresholdPercentage <= PRECISION, "Consensus threshold > 1");
    consensusThresholdPercentage = _newThresholdPercentage;
  }

  function setMaxMembers(
    uint256 _newMaxMembers,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withUnanimity(
      this.setMaxMembers.selector,
      abi.encode(_newMaxMembers),
      _members,
      _signatures,
      _salts
    )
  {
    require(_newMaxMembers >= memberCount, "_newMaxMembers < memberCount");
    MAX_MEMBERS = _newMaxMembers;
  }

  /**
    Posting bounties
   */

  function postBounty(
    string memory _dataIPFSHash,
    uint256 _deadline,
    uint256 _reward,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.postBounty.selector,
      abi.encode(_dataIPFSHash, _deadline, _reward, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
    returns (uint256 _bountyID)
  {
    return _postBounty(_dataIPFSHash, _deadline, _reward, _standardBounties, _standardBountiesVersion);
  }

  function _postBounty(
    string memory _dataIPFSHash,
    uint256 _deadline,
    uint256 _reward,
    address _standardBounties,
    uint256 _standardBountiesVersion
  )
    internal
    returns (uint256 _bountyID)
  {
    require(_reward > 0, "Reward can't be 0");

    // Approve DAI reward to bounties contract
    _approveDAI(_standardBounties, _reward);

    _bountyID = _standardBounties.issueAndContribute(
      _standardBountiesVersion,
      address(this),
      issuersOrFulfillers,
      approvers,
      _dataIPFSHash,
      _deadline,
      address(DAI),
      _reward
    );

    emit PostBounty(_bountyID, _reward);
  }

  function addBountyReward(
    uint256 _bountyID,
    uint256 _reward,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.addBountyReward.selector,
      abi.encode(_bountyID, _reward, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    // Approve DAI reward to bounties contract
    _approveDAI(_standardBounties, _reward);

    _standardBounties.contribute(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _reward
    );

    emit AddBountyReward(_bountyID, _reward);
  }

  function refundBountyReward(
    uint256 _bountyID,
    uint256[] memory _contributionIDs,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.refundBountyReward.selector,
      abi.encode(_bountyID, _contributionIDs, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    uint256 beforeBalance = DAI.balanceOf(address(this));
    _standardBounties.refundMyContributions(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _contributionIDs
    );

    emit RefundBountyReward(_bountyID, DAI.balanceOf(address(this)).sub(beforeBalance));
  }

  function changeBountyData(
    uint256 _bountyID,
    string memory _dataIPFSHash,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.changeBountyData.selector,
      abi.encode(_bountyID, _dataIPFSHash, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _standardBounties.changeData(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _dataIPFSHash
    );
    emit ChangeBountyData(_bountyID);
  }

  function changeBountyDeadline(
    uint256 _bountyID,
    uint256 _deadline,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.changeBountyDeadline.selector,
      abi.encode(_bountyID, _deadline, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _standardBounties.changeDeadline(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _deadline
    );
    emit ChangeBountyDeadline(_bountyID);
  }

  function acceptBountySubmission(
    uint256 _bountyID,
    uint256 _fulfillmentID,
    uint256[] memory _tokenAmounts,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.acceptBountySubmission.selector,
      abi.encode(_bountyID, _fulfillmentID, _tokenAmounts, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _standardBounties.acceptFulfillment(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _fulfillmentID,
      _tokenAmounts
    );
    emit AcceptBountySubmission(_bountyID, _fulfillmentID);
  }

  /**
    Working on bounties
   */

  function performBountyAction(
    uint256 _bountyID,
    string memory _dataIPFSHash,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.performBountyAction.selector,
      abi.encode(_bountyID, _dataIPFSHash, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _standardBounties.performAction(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _dataIPFSHash
    );
    emit PerformBountyAction(_bountyID);
  }

  function fulfillBounty(
    uint256 _bountyID,
    string memory _dataIPFSHash,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.fulfillBounty.selector,
      abi.encode(_bountyID, _dataIPFSHash, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _standardBounties.fulfillBounty(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      issuersOrFulfillers,
      _dataIPFSHash
    );
    emit FulfillBounty(_bountyID);
  }

  function updateBountyFulfillment(
    uint256 _bountyID,
    uint256 _fulfillmentID,
    string memory _dataIPFSHash,
    address _standardBounties,
    uint256 _standardBountiesVersion,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  )
    public
    withConsensus(
      this.updateBountyFulfillment.selector,
      abi.encode(_bountyID, _fulfillmentID, _dataIPFSHash, _standardBounties, _standardBountiesVersion),
      _members,
      _signatures,
      _salts
    )
  {
    _updateBountyFulfillment(_bountyID, _fulfillmentID, _dataIPFSHash, _standardBounties, _standardBountiesVersion);
  }

  function _updateBountyFulfillment(
    uint256 _bountyID,
    uint256 _fulfillmentID,
    string memory _dataIPFSHash,
    address _standardBounties,
    uint256 _standardBountiesVersion
  )
    internal
  {
    _standardBounties.updateFulfillment(
      _standardBountiesVersion,
      address(this),
      _bountyID,
      _fulfillmentID,
      issuersOrFulfillers,
      _dataIPFSHash
    );
    emit UpdateBountyFulfillment(_bountyID, _fulfillmentID);
  }

  /**
    Consensus
   */

  function naiveMessageHash(
    bytes4       _funcSelector,
    bytes memory _funcParams,
    uint256      _salt
  ) public view returns (bytes32) {
    // "|END|" is used to separate _funcParams from the rest, to prevent maliciously ambiguous signatures
    return keccak256(abi.encodeWithSelector(_funcSelector, _funcParams, "|END|", _salt, address(this)));
  }

  function consensusThreshold() public view returns (uint256) {
    uint256 blockingThresholdMemberCount = PRECISION.sub(consensusThresholdPercentage).mul(memberCount).div(PRECISION);
    return memberCount.sub(blockingThresholdMemberCount);
  }

  function _consensusReached(
    uint256          _threshold,
    bytes4           _funcSelector,
    bytes     memory _funcParams,
    address[] memory _members,
    bytes[]   memory _signatures,
    uint256[] memory _salts
  ) internal returns (bool) {
    // Check if the number of signatures exceed the consensus threshold
    if (_members.length != _signatures.length || _members.length < _threshold) {
      return false;
    }
    // Check if each signature is valid and signed by a member
    for (uint256 i = 0; i < _members.length; i = i.add(1)) {
      address member = _members[i];
      uint256 salt = _salts[i];
      if (!isMember[member] || hasUsedSalt[member][salt]) {
        // Invalid member or salt already used
        return false;
      }

      bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveMessageHash(_funcSelector, _funcParams, salt));
      address recoveredAddress = ECDSA.recover(msgHash, _signatures[i]);
      if (recoveredAddress != member) {
        // Invalid signature
        return false;
      }

      // Signature valid, record use of salt
      hasUsedSalt[member][salt] = true;
    }

    return true;
  }

  function _timestampToDayID(uint256 _timestamp) internal pure returns (uint256) {
    return _timestamp.sub(_timestamp % 86400).div(86400);
  }

  // limits how much could be withdrawn each day, should be called before transfer() or approve()
  function _applyWithdrawLimit(uint256 _amount) internal {
    // check if the limit will be exceeded
    if (_timestampToDayID(now).sub(_timestampToDayID(lastWithdrawTimestamp)) >= 1) {
      // new day, don't care about existing limit
      withdrawnToday = 0;
    }
    uint256 newWithdrawnToday = withdrawnToday.add(_amount);
    require(newWithdrawnToday <= withdrawLimit, "Withdraw limit exceeded");
    withdrawnToday = newWithdrawnToday;
    lastWithdrawTimestamp = now;
  }

  function _transferDAI(address _to, uint256 _amount) internal {
    if (_amount == 0) return;
    _applyWithdrawLimit(_amount);
    uint256 fee = FEE_MODEL.getFee(memberCount, _amount);
    DAI.safeTransfer(_to, _amount);
    DAI.safeTransfer(FEE_MODEL.beneficiary(), fee);
  }

  function _approveDAI(address _to, uint256 _amount) internal {
    if (_amount == 0) return;
    _applyWithdrawLimit(_amount);
    uint256 fee = FEE_MODEL.getFee(memberCount, _amount);
    DAI.safeApprove(_to, 0);
    DAI.safeApprove(_to, _amount);
    DAI.safeTransfer(FEE_MODEL.beneficiary(), fee);
  }

  function _transferToken(address _token, address payable _to, uint256 _amount) internal {
    if (_amount == 0) return;
    uint256 fee = FEE_MODEL.getFee(memberCount, _amount);
    if (_token == address(0)) {
      // Ether
      _to.transfer(_amount);
      FEE_MODEL.beneficiary().transfer(fee);
    } else {
      IERC20 token = IERC20(_token);
      token.safeTransfer(_to, _amount);
      token.safeTransfer(FEE_MODEL.beneficiary(), fee);
    }
  }

  function _mintShares(address _to, uint256 _amount) internal {
    // can only give shares to squad members
    require(isMember[_to], "Shares minted for non-member");

    // calculate how much the shares will be worth and apply the withdraw limit
    uint256 sharesValue = _amount.mul(DAI.balanceOf(address(this))).div(_amount.add(SHARE.totalSupply()));
    _applyWithdrawLimit(sharesValue);
    require(SHARE.mint(_to, _amount), "Failed to mint shares");
  }

  function() external payable {}
}"
    },
    "@openzeppelin/contracts/cryptography/ECDSA.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n Ã· 2 + 1, and for v in (282): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
"
    },
    "contracts/5/standard_bounties/StandardBountiesWrapper.sol": {
      "content": "pragma solidity 0.5.16;

import "./v1/IStandardBountiesV1.sol";
import "./v2/StandardBounties.sol";

library StandardBountiesWrapper {
  function issueAndContribute(
    address _standardBounties,
    uint _standardBountiesVersion,
    address payable _sender,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _depositAmount)
    internal
    returns(uint)
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      return BOUNTIES.issueAndActivateBounty(
        _sender,
        _deadline,
        _data,
        _depositAmount,
        _sender,
        true,
        _token,
        _depositAmount
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      return BOUNTIES.issueAndContribute(
        _sender,
        _issuers,
        _approvers,
        _data,
        _deadline,
        _token,
        20, // ERC20
        _depositAmount
      );
    }
  }

  function contribute(
    address _standardBounties,
    uint _standardBountiesVersion,
    address payable _sender,
    uint _bountyId,
    uint _amount)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      (,,uint fulfillmentAmount,,,) = BOUNTIES.getBounty(_bountyId);
      BOUNTIES.increasePayout(
        _bountyId,
        add(fulfillmentAmount, _amount),
        _amount
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.contribute(
        _sender,
        _bountyId,
        _amount
      );
    }
  }

  function refundMyContributions(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    uint[] memory _contributionIds)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      BOUNTIES.killBounty(
        _bountyId
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.refundMyContributions(
        _sender,
        _bountyId,
        _contributionIds
      );
    }
  }

  function changeData(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    string memory _data)
    internal
  {
    if (_standardBountiesVersion == 1) {
      revert("Can't change data of V1 bounty");
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.changeData(
        _sender,
        _bountyId,
        0,
        _data
      );
    }
  }

  function changeDeadline(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    uint _deadline)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      BOUNTIES.extendDeadline(
        _bountyId,
        _deadline
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.changeDeadline(
        _sender,
        _bountyId,
        0,
        _deadline
      );
    }
  }

  function acceptFulfillment(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint[] memory _tokenAmounts)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      BOUNTIES.acceptFulfillment(
        _bountyId,
        _fulfillmentId
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.acceptFulfillment(
        _sender,
        _bountyId,
        _fulfillmentId,
        0,
        _tokenAmounts
      );
    }
  }

  function performAction(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    string memory _data)
    internal
  {
    if (_standardBountiesVersion == 1) {
      revert("Not supported by V1");
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.performAction(
        _sender,
        _bountyId,
        _data
      );
    }
  }

  function fulfillBounty(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    address payable[] memory  _fulfillers,
    string memory _data)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      BOUNTIES.fulfillBounty(
        _bountyId,
        _data
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.fulfillBounty(
        _sender,
        _bountyId,
        _fulfillers,
        _data
      );
    }
  }

  function updateFulfillment(
    address _standardBounties,
    uint _standardBountiesVersion,
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    address payable[] memory _fulfillers,
    string memory _data)
    internal
  {
    if (_standardBountiesVersion == 1) {
      IStandardBountiesV1 BOUNTIES = IStandardBountiesV1(_standardBounties);
      BOUNTIES.updateFulfillment(
        _bountyId,
        _fulfillmentId,
        _data
      );
    } else if (_standardBountiesVersion == 2) {
      StandardBounties BOUNTIES = StandardBounties(_standardBounties);
      BOUNTIES.updateFulfillment(
        _sender,
        _bountyId,
        _fulfillmentId,
        _fulfillers,
        _data
      );
    }
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }
}"
    },
    "contracts/5/standard_bounties/v1/IStandardBountiesV1.sol": {
      "content": "pragma solidity 0.5.16;

interface IStandardBountiesV1 {

  /*
   * Events
   */
  event BountyIssued(uint bountyId);
  event BountyActivated(uint bountyId, address issuer);
  event BountyFulfilled(uint bountyId, address indexed fulfiller, uint256 indexed _fulfillmentId);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId);
  event FulfillmentAccepted(uint bountyId, address indexed fulfiller, uint256 indexed _fulfillmentId);
  event BountyKilled(uint bountyId, address indexed issuer);
  event ContributionAdded(uint bountyId, address indexed contributor, uint256 value);
  event DeadlineExtended(uint bountyId, uint newDeadline);
  event BountyChanged(uint bountyId);
  event IssuerTransferred(uint _bountyId, address indexed _newIssuer);
  event PayoutIncreased(uint _bountyId, uint _newFulfillmentAmount);

  /*
   * Public functions
   */

  /// @dev issueBounty(): instantiates a new draft bounty
  /// @param _issuer the address of the intended issuer of the bounty
  /// @param _deadline the unix timestamp after which fulfillments will no longer be accepted
  /// @param _data the requirements of the bounty
  /// @param _fulfillmentAmount the amount of wei to be paid out for each successful fulfillment
  /// @param _arbiter the address of the arbiter who can mediate claims
  /// @param _paysTokens whether the bounty pays in tokens or in ETH
  /// @param _tokenContract the address of the contract if _paysTokens is true
  function issueBounty(
    address _issuer,
    uint _deadline,
    string calldata _data,
    uint256 _fulfillmentAmount,
    address _arbiter,
    bool _paysTokens,
    address _tokenContract
  )
      external
      returns (uint);

  /// @dev issueAndActivateBounty(): instantiates a new draft bounty
  /// @param _issuer the address of the intended issuer of the bounty
  /// @param _deadline the unix timestamp after which fulfillments will no longer be accepted
  /// @param _data the requirements of the bounty
  /// @param _fulfillmentAmount the amount of wei to be paid out for each successful fulfillment
  /// @param _arbiter the address of the arbiter who can mediate claims
  /// @param _paysTokens whether the bounty pays in tokens or in ETH
  /// @param _tokenContract the address of the contract if _paysTokens is true
  /// @param _value the total number of tokens being deposited upon activation
  function issueAndActivateBounty(
    address _issuer,
    uint _deadline,
    string calldata _data,
    uint256 _fulfillmentAmount,
    address _arbiter,
    bool _paysTokens,
    address _tokenContract,
    uint256 _value
  )
      external
      payable
      returns (uint);

  /// @dev contribute(): a function allowing anyone to contribute tokens to a
  /// bounty, as long as it is still before its deadline. Shouldn't keep
  /// them by accident (hence 'value').
  /// @param _bountyId the index of the bounty
  /// @param _value the amount being contributed in ether to prevent accidental deposits
  /// @notice Please note you funds will be at the mercy of the issuer
  ///  and can be drained at any moment. Be careful!
  function contribute (uint _bountyId, uint _value)
      external
      payable;

  /// @notice Send funds to activate the bug bounty
  /// @dev activateBounty(): activate a bounty so it may pay out
  /// @param _bountyId the index of the bounty
  /// @param _value the amount being contributed in ether to prevent
  /// accidental deposits
  function activateBounty(uint _bountyId, uint _value)
      external
      payable;

  /// @dev fulfillBounty(): submit a fulfillment for the given bounty
  /// @param _bountyId the index of the bounty
  /// @param _data the data artifacts representing the fulfillment of the bounty
  function fulfillBounty(uint _bountyId, string calldata _data)
      external;

  /// @dev updateFulfillment(): Submit updated data for a given fulfillment
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment
  /// @param _data the new data being submitted
  function updateFulfillment(uint _bountyId, uint _fulfillmentId, string calldata _data)
      external;

  /// @dev acceptFulfillment(): accept a given fulfillment
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment being accepted
  function acceptFulfillment(uint _bountyId, uint _fulfillmentId)
      external;

  /// @dev killBounty(): drains the contract of it's remaining
  /// funds, and moves the bounty into stage 3 (dead) since it was
  /// either killed in draft stage, or never accepted any fulfillments
  /// @param _bountyId the index of the bounty
  function killBounty(uint _bountyId)
      external;

  /// @dev extendDeadline(): allows the issuer to add more time to the
  /// bounty, allowing it to continue accepting fulfillments
  /// @param _bountyId the index of the bounty
  /// @param _newDeadline the new deadline in timestamp format
  function extendDeadline(uint _bountyId, uint _newDeadline)
      external;

  /// @dev transferIssuer(): allows the issuer to transfer ownership of the
  /// bounty to some new address
  /// @param _bountyId the index of the bounty
  /// @param _newIssuer the address of the new issuer
  function transferIssuer(uint _bountyId, address _newIssuer)
      external;


  /// @dev changeBountyDeadline(): allows the issuer to change a bounty's deadline
  /// @param _bountyId the index of the bounty
  /// @param _newDeadline the new deadline for the bounty
  function changeBountyDeadline(uint _bountyId, uint _newDeadline)
      external;

  /// @dev changeData(): allows the issuer to change a bounty's data
  /// @param _bountyId the index of the bounty
  /// @param _newData the new requirements of the bounty
  function changeBountyData(uint _bountyId, string calldata _newData)
      external;

  /// @dev changeBountyfulfillmentAmount(): allows the issuer to change a bounty's fulfillment amount
  /// @param _bountyId the index of the bounty
  /// @param _newFulfillmentAmount the new fulfillment amount
  function changeBountyFulfillmentAmount(uint _bountyId, uint _newFulfillmentAmount)
      external;

  /// @dev changeBountyArbiter(): allows the issuer to change a bounty's arbiter
  /// @param _bountyId the index of the bounty
  /// @param _newArbiter the new address of the arbiter
  function changeBountyArbiter(uint _bountyId, address _newArbiter)
      external;

  /// @dev increasePayout(): allows the issuer to increase a given fulfillment
  /// amount in the active stage
  /// @param _bountyId the index of the bounty
  /// @param _newFulfillmentAmount the new fulfillment amount
  /// @param _value the value of the additional deposit being added
  function increasePayout(uint _bountyId, uint _newFulfillmentAmount, uint _value)
      external
      payable;

  /// @dev getFulfillment(): Returns the fulfillment at a given index
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment to return
  /// @return Returns a tuple for the fulfillment
  function getFulfillment(uint _bountyId, uint _fulfillmentId)
      external
      returns (bool, address, string memory);

  /// @dev getBounty(): Returns the details of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns a tuple for the bounty
  function getBounty(uint _bountyId)
      external
      returns (address, uint, uint, bool, uint, uint);

  /// @dev getBountyArbiter(): Returns the arbiter of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns an address for the arbiter of the bounty
  function getBountyArbiter(uint _bountyId)
      external
      returns (address);

  /// @dev getBountyData(): Returns the data of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns a string calldata for the bounty data
  function getBountyData(uint _bountyId)
      external
      returns (string memory);

  /// @dev getBountyToken(): Returns the token contract of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns an address for the token that the bounty uses
  function getBountyToken(uint _bountyId)
      external
      returns (address);

  /// @dev getNumBounties() returns the number of bounties in the registry
  /// @return Returns the number of bounties
  function getNumBounties()
      external
      returns (uint);

  /// @dev getNumFulfillments() returns the number of fulfillments for a given milestone
  /// @param _bountyId the index of the bounty
  /// @return Returns the number of fulfillments
  function getNumFulfillments(uint _bountyId)
      external
      returns (uint);
}"
    },
    "contracts/5/standard_bounties/v2/StandardBounties.sol": {
      "content": "pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./inherited/ERC20Token.sol";
import "./inherited/ERC721Basic.sol";


/// @title StandardBounties
/// @dev A contract for issuing bounties on Ethereum paying in ETH, ERC20, or ERC721 tokens
/// @author Mark Beylin <mark.beylin@consensys.net>, GonÃ§alo SÃ¡ <goncalo.sa@consensys.net>, Kevin Owocki <kevin.owocki@consensys.net>, Ricardo Guilherme Schmidt (@3esmit), Matt Garnett <matt.garnett@consensys.net>, Craig Williams <craig.williams@consensys.net>
contract StandardBounties {

  using SafeMath for uint256;

  /*
   * Structs
   */

  struct Bounty {
    address payable [] issuers; // An array of individuals who have complete control over the bounty, and can edit any of its parameters
    address [] approvers; // An array of individuals who are allowed to accept the fulfillments for a particular bounty
    uint deadline; // The Unix timestamp before which all submissions must be made, and after which refunds may be processed
    address token; // The address of the token associated with the bounty (should be disregarded if the tokenVersion is 0)
    uint tokenVersion; // The version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
    uint balance; // The number of tokens which the bounty is able to pay out or refund
    bool hasPaidOut; // A boolean storing whether or not the bounty has paid out at least once, meaning refunds are no longer allowed
    Fulfillment [] fulfillments; // An array of Fulfillments which store the various submissions which have been made to the bounty
    Contribution [] contributions; // An array of Contributions which store the contributions which have been made to the bounty
  }

  struct Fulfillment {
    address payable [] fulfillers; // An array of addresses who should receive payouts for a given submission
    address submitter; // The address of the individual who submitted the fulfillment, who is able to update the submission as needed
  }

  struct Contribution {
    address payable contributor; // The address of the individual who contributed
    uint amount; // The amount of tokens the user contributed
    bool refunded; // A boolean storing whether or not the contribution has been refunded yet
  }

  /*
   * Storage
   */

  uint public numBounties; // An integer storing the total number of bounties in the contract
  mapping(uint => Bounty) public bounties; // A mapping of bountyIDs to bounties
  mapping (uint => mapping (uint => bool)) public tokenBalances; // A mapping of bountyIds to tokenIds to booleans, storing whether a given bounty has a given ERC721 token in its balance


  address public owner; // The address of the individual who's allowed to set the metaTxRelayer address
  address public metaTxRelayer; // The address of the meta transaction relayer whose _sender is automatically trusted for all contract calls

  bool public callStarted; // Ensures mutex for the entire contract

  /*
   * Modifiers
   */

  modifier callNotStarted(){
    require(!callStarted);
    callStarted = true;
    _;
    callStarted = false;
  }

  modifier validateBountyArrayIndex(
    uint _index)
  {
    require(_index < numBounties);
    _;
  }

  modifier validateContributionArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].contributions.length);
    _;
  }

  modifier validateFulfillmentArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].fulfillments.length);
    _;
  }

  modifier validateIssuerArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].issuers.length);
    _;
  }

  modifier validateApproverArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].approvers.length);
    _;
  }

  modifier onlyIssuer(
  address _sender,
  uint _bountyId,
  uint _issuerId)
  {
  require(_sender == bounties[_bountyId].issuers[_issuerId]);
  _;
  }

  modifier onlySubmitter(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId)
  {
    require(_sender ==
            bounties[_bountyId].fulfillments[_fulfillmentId].submitter);
    _;
  }

  modifier onlyContributor(
  address _sender,
  uint _bountyId,
  uint _contributionId)
  {
    require(_sender ==
            bounties[_bountyId].contributions[_contributionId].contributor);
    _;
  }

  modifier isApprover(
    address _sender,
    uint _bountyId,
    uint _approverId)
  {
    require(_sender == bounties[_bountyId].approvers[_approverId]);
    _;
  }

  modifier hasNotPaid(
    uint _bountyId)
  {
    require(!bounties[_bountyId].hasPaidOut);
    _;
  }

  modifier hasNotRefunded(
    uint _bountyId,
    uint _contributionId)
  {
    require(!bounties[_bountyId].contributions[_contributionId].refunded);
    _;
  }

  modifier senderIsValid(
    address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }

 /*
  * Public functions
  */

  constructor() public {
    // The owner of the contract is automatically designated to be the deployer of the contract
    owner = msg.sender;
  }

  /// @dev setMetaTxRelayer(): Sets the address of the meta transaction relayer
  /// @param _relayer the address of the relayer
  function setMetaTxRelayer(address _relayer)
    external
  {
    require(msg.sender == owner); // Checks that only the owner can call
    require(metaTxRelayer == address(0)); // Ensures the meta tx relayer can only be set once
    metaTxRelayer = _relayer;
  }

  /// @dev issueBounty(): creates a new bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _issuers the array of addresses who will be the issuers of the bounty
  /// @param _approvers the array of addresses who will be the approvers of the bounty
  /// @param _data the IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the timestamp which will become the deadline of the bounty
  /// @param _token the address of the token which will be used for the bounty
  /// @param _tokenVersion the version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
  function issueBounty(
    address payable _sender,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion)
    public
    senderIsValid(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721); // Ensures a bounty can only be issued with a valid token version
    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    uint bountyId = numBounties; // The next bounty's index will always equal the number of existing bounties

    Bounty storage newBounty = bounties[bountyId];
    newBounty.issuers = _issuers;
    newBounty.approvers = _approvers;
    newBounty.deadline = _deadline;
    newBounty.tokenVersion = _tokenVersion;

    if (_tokenVersion != 0) {
      newBounty.token = _token;
    }

    numBounties = numBounties.add(1); // Increments the number of bounties, since a new one has just been added

    emit BountyIssued(bountyId,
                      _sender,
                      _issuers,
                      _approvers,
                      _data, // Instead of storing the string on-chain, it is emitted within the event for easy off-chain consumption
                      _deadline,
                      _token,
                      _tokenVersion);

    return (bountyId);
  }

  /// @param _depositAmount the amount of tokens being deposited to the bounty, which will create a new contribution to the bounty


  function issueAndContribute(
    address payable _sender,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount)
    public
    payable
    returns(uint)
  {
    uint bountyId = issueBounty(_sender, _issuers, _approvers, _data, _deadline, _token, _tokenVersion);

    contribute(_sender, bountyId, _depositAmount);

    return (bountyId);
  }


  /// @dev contribute(): Allows users to contribute tokens to a given bounty.
  ///                    Contributing merits no privelages to administer the
  ///                    funds in the bounty or accept submissions. Contributions
  ///                    are refundable but only on the condition that the deadline
  ///                    has elapsed, and the bounty has not yet paid out any funds.
  ///                    All funds deposited in a bounty are at the mercy of a
  ///                    bounty's issuers and approvers, so please be careful!
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _amount the amount of tokens being contributed
  function contribute(
    address payable _sender,
    uint _bountyId,
    uint _amount)
    public
    payable
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    callNotStarted
  {
    require(_amount > 0); // Contributions of 0 tokens or token ID 0 should fail

    bounties[_bountyId].contributions.push(
      Contribution(_sender, _amount, false)); // Adds the contribution to the bounty

    if (bounties[_bountyId].tokenVersion == 0){

      bounties[_bountyId].balance = bounties[_bountyId].balance.add(_amount); // Increments the balance of the bounty

      require(msg.value == _amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {

      bounties[_bountyId].balance = bounties[_bountyId].balance.add(_amount); // Increments the balance of the bounty

      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      require(ERC20Token(bounties[_bountyId].token).transferFrom(_sender,
                                                                 address(this),
                                                                 _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      tokenBalances[_bountyId][_amount] = true; // Adds the 721 token to the balance of the bounty


      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      ERC721BasicToken(bounties[_bountyId].token).transferFrom(_sender,
                                                               address(this),
                                                               _amount);
    } else {
      revert();
    }

    emit ContributionAdded(_bountyId,
                           bounties[_bountyId].contributions.length - 1, // The new contributionId
                           _sender,
                           _amount);
  }

  /// @dev refundContribution(): Allows users to refund the contributions they've
  ///                            made to a particular bounty, but only if the bounty
  ///                            has not yet paid out, and the deadline has elapsed.
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionId the index of the contribution being refunded
  function refundContribution(
    address _sender,
    uint _bountyId,
    uint _contributionId)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateContributionArrayIndex(_bountyId, _contributionId)
    onlyContributor(_sender, _bountyId, _contributionId)
    hasNotPaid(_bountyId)
    hasNotRefunded(_bountyId, _contributionId)
    callNotStarted
  {
    require(now > bounties[_bountyId].deadline); // Refunds may only be processed after the deadline has elapsed

    Contribution storage contribution =
      bounties[_bountyId].contributions[_contributionId];

    contribution.refunded = true;

    transferTokens(_bountyId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor

    emit ContributionRefunded(_bountyId, _contributionId);
  }

  /// @dev refundMyContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundMyContributions(
    address _sender,
    uint _bountyId,
    uint [] memory _contributionIds)
    public
    senderIsValid(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      refundContribution(_sender, _bountyId, _contributionIds[i]);
    }
  }

  /// @dev refundContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundContributions(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint [] memory _contributionIds)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    callNotStarted
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      require(_contributionIds[i] < bounties[_bountyId].contributions.length);

      Contribution storage contribution =
        bounties[_bountyId].contributions[_contributionIds[i]];

      require(!contribution.refunded);

      contribution.refunded = true;

      transferTokens(_bountyId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor
    }

    emit ContributionsRefunded(_bountyId, _sender, _contributionIds);
  }

  /// @dev drainBounty(): Allows an issuer to drain the funds from the bounty
  /// @notice when using this function, if an issuer doesn't drain the entire balance, some users may be able to refund their contributions, while others may not (which is unfair to them). Please use it wisely, only when necessary
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is making the call
  /// @param _amounts an array of amounts of tokens to be sent. The length of the array should be 1 if the bounty is in ETH or ERC20 tokens. If it's an ERC721 bounty, the array should be the list of tokenIDs.
  function drainBounty(
    address payable _sender,
    uint _bountyId,
    uint _issuerId,
    uint [] memory _amounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    callNotStarted
  {
    if (bounties[_bountyId].tokenVersion == 0 || bounties[_bountyId].tokenVersion == 20){
      require(_amounts.length == 1); // ensures there's only 1 amount of tokens to be returned
      require(_amounts[0] <= bounties[_bountyId].balance); // ensures an issuer doesn't try to drain the bounty of more tokens than their balance permits
      transferTokens(_bountyId, _sender, _amounts[0]); // Performs the draining of tokens to the issuer
    } else {
      for (uint i = 0; i < _amounts.length; i++){
        require(tokenBalances[_bountyId][_amounts[i]]);// ensures an issuer doesn't try to drain the bounty of a token it doesn't have in its balance
        transferTokens(_bountyId, _sender, _amounts[i]);
      }
    }

    emit BountyDrained(_bountyId, _sender, _amounts);
  }

  /// @dev performAction(): Allows users to perform any generalized action
  ///                       associated with a particular bounty, such as applying for it
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the action being performed (see docs for schema details)
  function performAction(
    address _sender,
    uint _bountyId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    emit ActionPerformed(_bountyId, _sender, _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev fulfillBounty(): Allows users to fulfill the bounty to get paid out
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function fulfillBounty(
    address _sender,
    uint _bountyId,
    address payable [] memory  _fulfillers,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    require(now < bounties[_bountyId].deadline); // Submissions are only allowed to be made before the deadline
    require(_fulfillers.length > 0); // Submissions with no fulfillers would mean no one gets paid out

    bounties[_bountyId].fulfillments.push(Fulfillment(_fulfillers, _sender));

    emit BountyFulfilled(_bountyId,
                         (bounties[_bountyId].fulfillments.length - 1),
                         _fulfillers,
                         _data, // The _data string is emitted in an event for easy off-chain consumption
                         _sender);
  }

  /// @dev updateFulfillment(): Allows the submitter of a fulfillment to update their submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment
  /// @param _fulfillers the new array of addresses which will receive payouts for the submission
  /// @param _data the new IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function updateFulfillment(
  address _sender,
  uint _bountyId,
  uint _fulfillmentId,
  address payable [] memory _fulfillers,
  string memory _data)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
  onlySubmitter(_sender, _bountyId, _fulfillmentId) // Only the original submitter of a fulfillment may update their submission
  {
    bounties[_bountyId].fulfillments[_fulfillmentId].fulfillers = _fulfillers;
    emit FulfillmentUpdated(_bountyId,
                            _fulfillmentId,
                            _fulfillers,
                            _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev acceptFulfillment(): Allows any of the approvers to accept a given submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment to be accepted
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function acceptFulfillment(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
    isApprover(_sender, _bountyId, _approverId)
    callNotStarted
  {
    // now that the bounty has paid out at least once, refunds are no longer possible
    bounties[_bountyId].hasPaidOut = true;

    Fulfillment storage fulfillment =
      bounties[_bountyId].fulfillments[_fulfillmentId];

    require(_tokenAmounts.length == fulfillment.fulfillers.length); // Each fulfiller should get paid some amount of tokens (this can be 0)

    for (uint256 i = 0; i < fulfillment.fulfillers.length; i++){
        if (_tokenAmounts[i] > 0) {
          // for each fulfiller associated with the submission
          transferTokens(_bountyId, fulfillment.fulfillers[i], _tokenAmounts[i]);
        }
    }
    emit FulfillmentAccepted(_bountyId,
                             _fulfillmentId,
                             _sender,
                             _tokenAmounts);
  }

  /// @dev fulfillAndAccept(): Allows any of the approvers to fulfill and accept a submission simultaneously
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function fulfillAndAccept(
    address _sender,
    uint _bountyId,
    address payable [] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
  {
    // first fulfills the bounty on behalf of the fulfillers
    fulfillBounty(_sender, _bountyId, _fulfillers, _data);

    // then accepts the fulfillment
    acceptFulfillment(_sender,
                      _bountyId,
                      bounties[_bountyId].fulfillments.length - 1,
                      _approverId,
                      _tokenAmounts);
  }



  /// @dev changeBounty(): Allows any of the issuers to change the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the new array of addresses who will be the issuers of the bounty
  /// @param _approvers the new array of addresses who will be the approvers of the bounty
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeBounty(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    address payable [] memory _approvers,
    string memory _data,
    uint _deadline)
    public
    senderIsValid(_sender)
  {
    require(_bountyId < numBounties); // makes the validateBountyArrayIndex modifier in-line to avoid stack too deep errors
    require(_issuerId < bounties[_bountyId].issuers.length); // makes the validateIssuerArrayIndex modifier in-line to avoid stack too deep errors
    require(_sender == bounties[_bountyId].issuers[_issuerId]); // makes the onlyIssuer modifier in-line to avoid stack too deep errors

    require(_issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    bounties[_bountyId].issuers = _issuers;
    bounties[_bountyId].approvers = _approvers;
    bounties[_bountyId].deadline = _deadline;
    emit BountyChanged(_bountyId,
                       _sender,
                       _issuers,
                       _approvers,
                       _data,
                       _deadline);
  }

  /// @dev changeIssuer(): Allows any of the issuers to change a particular issuer of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuerIdToChange the index of the issuer who is being changed
  /// @param _newIssuer the address of the new issuer
  function changeIssuer(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerIdToChange)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(_issuerId < bounties[_bountyId].issuers.length || _issuerId == 0);

    bounties[_bountyId].issuers[_issuerIdToChange] = _newIssuer;

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev changeApprover(): Allows any of the issuers to change a particular approver of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approverId the index of the approver who is being changed
  /// @param _approver the address of the new approver
  function changeApprover(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver)
    external
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    validateApproverArrayIndex(_bountyId, _approverId)
  {
    bounties[_bountyId].approvers[_approverId] = _approver;

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev changeData(): Allows any of the issuers to change the data the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  function changeData(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    emit BountyDataChanged(_bountyId, _sender, _data); // The new _data is emitted within an event rather than being stored on-chain for minimized gas costs
  }

  /// @dev changeDeadline(): Allows any of the issuers to change the deadline the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeDeadline(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _deadline)
    external
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].deadline = _deadline;

    emit BountyDeadlineChanged(_bountyId, _sender, _deadline);
  }

  /// @dev addIssuers(): Allows any of the issuers to add more issuers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to add to the list of valid issuers
  function addIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      bounties[_bountyId].issuers.push(_issuers[i]);
    }

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev replaceIssuers(): Allows any of the issuers to replace the issuers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to replace the list of valid issuers
  function replaceIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(_issuers.length > 0 || bounties[_bountyId].approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck

    bounties[_bountyId].issuers = _issuers;

    emit BountyIssuersUpdated(_bountyId, _sender, bounties[_bountyId].issuers);
  }

  /// @dev addApprovers(): Allows any of the issuers to add more approvers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to add to the list of valid approvers
  function addApprovers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address [] memory _approvers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      bounties[_bountyId].approvers.push(_approvers[i]);
    }

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev replaceApprovers(): Allows any of the issuers to replace the approvers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to replace the list of valid approvers
  function replaceApprovers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address [] memory _approvers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    require(bounties[_bountyId].issuers.length > 0 || _approvers.length > 0); // Ensures there's at least 1 issuer or approver, so funds don't get stuck
    bounties[_bountyId].approvers = _approvers;

    emit BountyApproversUpdated(_bountyId, _sender, bounties[_bountyId].approvers);
  }

  /// @dev getBounty(): Returns the details of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns a tuple for the bounty
  function getBounty(uint _bountyId)
    external
    view
    returns (Bounty memory)
  {
    return bounties[_bountyId];
  }


  function transferTokens(uint _bountyId, address payable _to, uint _amount)
    internal
  {
    if (bounties[_bountyId].tokenVersion == 0){
      require(_amount > 0); // Sending 0 tokens should throw
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.sub(_amount);

      _to.transfer(_amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {
      require(_amount > 0); // Sending 0 tokens should throw
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.sub(_amount);

      require(ERC20Token(bounties[_bountyId].token).transfer(_to, _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      require(tokenBalances[_bountyId][_amount]);

      tokenBalances[_bountyId][_amount] = false; // Removes the 721 token from the balance of the bounty

      ERC721BasicToken(bounties[_bountyId].token).transferFrom(address(this),
                                                               _to,
                                                               _amount);
    } else {
      revert();
    }
  }

  /*
   * Events
   */

  event BountyIssued(uint _bountyId, address payable _creator, address payable [] _issuers, address [] _approvers, string _data, uint _deadline, address _token, uint _tokenVersion);
  event ContributionAdded(uint _bountyId, uint _contributionId, address payable _contributor, uint _amount);
  event ContributionRefunded(uint _bountyId, uint _contributionId);
  event ContributionsRefunded(uint _bountyId, address _issuer, uint [] _contributionIds);
  event BountyDrained(uint _bountyId, address _issuer, uint [] _amounts);
  event ActionPerformed(uint _bountyId, address _fulfiller, string _data);
  event BountyFulfilled(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data, address _submitter);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data);
  event FulfillmentAccepted(uint _bountyId, uint  _fulfillmentId, address _approver, uint[] _tokenAmounts);
  event BountyChanged(uint _bountyId, address _changer, address payable [] _issuers, address payable [] _approvers, string _data, uint _deadline);
  event BountyIssuersUpdated(uint _bountyId, address _changer, address payable [] _issuers);
  event BountyApproversUpdated(uint _bountyId, address _changer, address [] _approvers);
  event BountyDataChanged(uint _bountyId, address _changer, string _data);
  event BountyDeadlineChanged(uint _bountyId, address _changer, uint _deadline);
}
"
    },
    "contracts/5/standard_bounties/v2/inherited/ERC20Token.sol": {
      "content": "/*
You should inherit from StandardToken or, for a token like you would want to
deploy in something like Mist, see HumanStandardToken.sol.
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won't have anything useful.)

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/
pragma solidity 0.5.16;

import "./Token.sol";

contract ERC20Token is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
"
    },
    "contracts/5/standard_bounties/v2/inherited/Token.sol": {
      "content": "// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity 0.5.16;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() pure returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) view public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _value);
}
"
    },
    "contracts/5/standard_bounties/v2/inherited/ERC721Basic.sol": {
      "content": " pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. This function MUST use 50,000 gas or less. Return of other
   * than the magic value MUST result in the transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _from The sending address
   * @param _tokenId The NFT identifier which is being transfered
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    returns(bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
  event Transfer(
    address  _from,
    address  _to,
    uint256  _tokenId
  );
  event Approval(
    address  _owner,
    address  _approved,
    uint256  _tokenId
  );
  event ApprovalForAll(
    address  _owner,
    address  _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public;
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0xf0b9e5ba;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;


  uint public testint;
  /**
   * @dev Guarantees msg.sender is owner of the given token
   * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
   */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

contract ERC721BasicTokenMock is ERC721BasicToken {
  function mint(address _to, uint256 _tokenId) public {
    super._mint(_to, _tokenId);
  }

  function burn(uint256 _tokenId) public {
    super._burn(ownerOf(_tokenId), _tokenId);
  }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/SafeERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "contracts/5/ShareToken.sol": {
      "content": "pragma solidity 0.5.16;

import "./ERC20/ERC20NonTransferrable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract ShareToken is Ownable, ERC20NonTransferrable {
    using SafeMath for uint256;

    bool public initialized;
    string public name;
    string public symbol;
    uint8 public decimals;

    function init(
        address ownerAddr,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
        public
    {
        require(! initialized, "Already initialized");
        initialized = true;

        _transferOwnership(ownerAddr);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }
}"
    },
    "@openzeppelin/contracts/ownership/Ownable.sol": {
      "content": "pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "contracts/5/FeeModel.sol": {
      "content": "pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract FeeModel is Ownable {
  using SafeMath for uint256;

  uint256 internal constant PRECISION = 10 ** 18;

  address payable public beneficiary = 0x332D87209f7c8296389C307eAe170c2440830A47;

  function getFee(uint256 _memberCount, uint256 _txAmount) public pure returns (uint256) {
    uint256 feePercentage;

    if (_memberCount <= 4) {
      feePercentage = _percent(1); // 1% for 1-4 members
    } else if (_memberCount <= 12) {
      feePercentage = _percent(3); // 3% for 5-12 members
    } else {
      feePercentage = _percent(5); // 5% for >12 members
    }

    return _txAmount.mul(feePercentage).div(PRECISION);
  }

  function setBeneficiary(address payable _addr) public onlyOwner {
    require(_addr != address(0), "0 address");
    beneficiary = _addr;
  }

  function _percent(uint256 _percentage) internal pure returns (uint256) {
    return PRECISION.mul(_percentage).div(100);
  }
}"
    },
    "contracts/5/mocks/MockERC20.sol": {
      "content": "pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";

contract MockERC20 is ERC20Mintable {}"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol": {
      "content": "pragma solidity ^0.5.0;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
"
    },
    "@openzeppelin/contracts/access/roles/MinterRole.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
"
    },
    "@openzeppelin/contracts/access/Roles.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
"
    },
    "contracts/5/PaidFantastic12Factory.sol": {
      "content": "pragma solidity 0.5.16;

import "./Fantastic12.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./EIP1167/CloneFactory.sol";

contract PaidFantastic12Factory is Ownable, CloneFactory {
  address public constant DAI_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address public squadTemplate;
  address public shareTokenTemplate;
  address public feeModel;

  event CreateSquad(address indexed summoner, address squad);

  constructor(address _squadTemplate, address _shareTokenTemplate, address _feeModel) public {
    squadTemplate = _squadTemplate;
    shareTokenTemplate = _shareTokenTemplate;
    feeModel = _feeModel;
  }

  function createSquad(
    address _summoner,
    string memory _shareTokenName,
    string memory _shareTokenSymbol,
    uint8 _shareTokenDecimals,
    uint256 _summonerShareAmount
  )
    public
    returns (Fantastic12 _squad)
  {
    // Create squad
    ShareToken shareToken = ShareToken(createClone(shareTokenTemplate));
    _squad = Fantastic12(_toPayableAddr(createClone(squadTemplate)));
    shareToken.init(
      address(_squad),
      _shareTokenName,
      _shareTokenSymbol,
      _shareTokenDecimals
    );
    _squad.init(
      _summoner,
      DAI_ADDR,
      address(shareToken),
      feeModel,
      _summonerShareAmount
    );
    emit CreateSquad(_summoner, address(_squad));
  }

  function setFeeModel(address _addr) public onlyOwner {
    feeModel = _addr;
  }

  function _toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}"
    },
    "contracts/5/standard_bounties/v2/BountiesMetaTxRelayer.sol": {
      "content": "pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./StandardBounties.sol";

contract BountiesMetaTxRelayer {

  // This contract serves as a relayer for meta txns being sent to the Bounties contract

  StandardBounties public bountiesContract;
  mapping(address => uint) public replayNonce;


  constructor(address _contract) public {
    bountiesContract = StandardBounties(_contract);
  }

  function metaIssueBounty(
    bytes memory signature,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _nonce)
    public
    returns (uint)
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaIssueBounty",
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _token,
                                                  _tokenVersion,
                                                  _nonce));
    address signer = getSigner(metaHash, signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;
    return bountiesContract.issueBounty(address(uint160(signer)),
                                         _issuers,
                                         _approvers,
                                         _data,
                                         _deadline,
                                         _token,
                                         _tokenVersion);
  }

  function metaIssueAndContribute(
    bytes memory signature,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount,
    uint _nonce)
    public
    payable
    returns (uint)
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaIssueAndContribute",
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _token,
                                                  _tokenVersion,
                                                  _depositAmount,
                                                  _nonce));
    address signer = getSigner(metaHash, signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    if (msg.value > 0){
      return bountiesContract.issueAndContribute.value(msg.value)(address(uint160(signer)),
                                                 _issuers,
                                                 _approvers,
                                                 _data,
                                                 _deadline,
                                                 _token,
                                                 _tokenVersion,
                                                 _depositAmount);
    } else {
      return bountiesContract.issueAndContribute(address(uint160(signer)),
                                                 _issuers,
                                                 _approvers,
                                                 _data,
                                                 _deadline,
                                                 _token,
                                                 _tokenVersion,
                                                 _depositAmount);
    }

  }

  function metaContribute(
    bytes memory _signature,
    uint _bountyId,
    uint _amount,
    uint _nonce)
    public
    payable
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaContribute",
                                                  _bountyId,
                                                  _amount,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    if (msg.value > 0){
      bountiesContract.contribute.value(msg.value)(address(uint160(signer)), _bountyId, _amount);
    } else {
      bountiesContract.contribute(address(uint160(signer)), _bountyId, _amount);
    }
  }


  function metaRefundContribution(
    bytes memory _signature,
    uint _bountyId,
    uint _contributionId,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundContribution",
                                                  _bountyId,
                                                  _contributionId,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.refundContribution(signer, _bountyId, _contributionId);
  }

  function metaRefundMyContributions(
    bytes memory _signature,
    uint _bountyId,
    uint [] memory _contributionIds,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundMyContributions",
                                                  _bountyId,
                                                  _contributionIds,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.refundMyContributions(signer, _bountyId, _contributionIds);
  }

  function metaRefundContributions(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint [] memory _contributionIds,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundContributions",
                                                  _bountyId,
                                                  _issuerId,
                                                  _contributionIds,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.refundContributions(signer, _bountyId, _issuerId, _contributionIds);
  }

  function metaDrainBounty(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint [] memory _amounts,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaDrainBounty",
                                                  _bountyId,
                                                  _issuerId,
                                                  _amounts,
                                                  _nonce));
    address payable signer = address(uint160(getSigner(metaHash, _signature)));

    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.drainBounty(signer, _bountyId, _issuerId, _amounts);
  }

  function metaPerformAction(
    bytes memory _signature,
    uint _bountyId,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaPerformAction",
                                                  _bountyId,
                                                  _data,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.performAction(signer, _bountyId, _data);
  }

  function metaFulfillBounty(
    bytes memory _signature,
    uint _bountyId,
    address payable [] memory  _fulfillers,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaFulfillBounty",
                                                  _bountyId,
                                                  _fulfillers,
                                                  _data,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.fulfillBounty(signer, _bountyId, _fulfillers, _data);
  }

  function metaUpdateFulfillment(
    bytes memory _signature,
    uint _bountyId,
    uint _fulfillmentId,
    address payable [] memory  _fulfillers,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaUpdateFulfillment",
                                                  _bountyId,
                                                  _fulfillmentId,
                                                  _fulfillers,
                                                  _data,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.updateFulfillment(signer, _bountyId, _fulfillmentId, _fulfillers, _data);
  }

  function metaAcceptFulfillment(
    bytes memory _signature,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint [] memory _tokenAmounts,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAcceptFulfillment",
                                                  _bountyId,
                                                  _fulfillmentId,
                                                  _approverId,
                                                  _tokenAmounts,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.acceptFulfillment(signer,
                       _bountyId,
                       _fulfillmentId,
                       _approverId,
                       _tokenAmounts);
  }

  function metaFulfillAndAccept(
    bytes memory _signature,
    uint _bountyId,
    address payable [] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint [] memory _tokenAmounts,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaFulfillAndAccept",
                                                  _bountyId,
                                                  _fulfillers,
                                                  _data,
                                                  _approverId,
                                                  _tokenAmounts,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.fulfillAndAccept(signer,
                      _bountyId,
                      _fulfillers,
                      _data,
                      _approverId,
                      _tokenAmounts);
  }

  function metaChangeBounty(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    address payable [] memory _approvers,
    string memory _data,
    uint _deadline,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeBounty",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.changeBounty(signer,
                  _bountyId,
                  _issuerId,
                  _issuers,
                  _approvers,
                  _data,
                  _deadline);
  }

  function metaChangeIssuer(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeIssuer",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuerIdToChange,
                                                  _newIssuer,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.changeIssuer(signer,
                  _bountyId,
                  _issuerId,
                  _issuerIdToChange,
                  _newIssuer);
  }

  function metaChangeApprover(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeApprover",
                                                  _bountyId,
                                                  _issuerId,
                                                  _approverId,
                                                  _approver,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.changeApprover(signer,
                  _bountyId,
                  _issuerId,
                  _approverId,
                  _approver);
  }

  function metaChangeData(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeData",
                                                  _bountyId,
                                                  _issuerId,
                                                  _data,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.changeData(signer,
                _bountyId,
                _issuerId,
                _data);
  }

  function metaChangeDeadline(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint  _deadline,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeDeadline",
                                                  _bountyId,
                                                  _issuerId,
                                                  _deadline,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.changeDeadline(signer,
                    _bountyId,
                    _issuerId,
                    _deadline);
  }

  function metaAddIssuers(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAddIssuers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuers,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.addIssuers(signer,
                _bountyId,
                _issuerId,
                _issuers);
  }

  function metaReplaceIssuers(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaReplaceIssuers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuers,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.replaceIssuers(signer,
                    _bountyId,
                    _issuerId,
                    _issuers);
  }

  function metaAddApprovers(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _approvers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAddApprovers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _approvers,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.addIssuers(signer,
                _bountyId,
                _issuerId,
                _approvers);
  }

  function metaReplaceApprovers(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _approvers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaReplaceApprovers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _approvers,
                                                  _nonce));
    address signer = getSigner(metaHash, _signature);
    //make sure signer doesn't come back as 0x0
    require(signer != address(0));
    require(_nonce == replayNonce[signer]);

    //increase the nonce to prevent replay attacks
    replayNonce[signer]++;

    bountiesContract.replaceIssuers(signer,
                    _bountyId,
                    _issuerId,
                    _approvers);
  }

  function getSigner(
    bytes32 _hash,
    bytes memory _signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (_signature.length != 65) {
      return address(0);
    }
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return address(0);
    } else {
      return ecrecover(keccak256(
        abi.encode("\x19Ethereum Signed Message:\n32", _hash)
      ), v, r, s);
    }
  }
}
"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
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
    }
  }
}}