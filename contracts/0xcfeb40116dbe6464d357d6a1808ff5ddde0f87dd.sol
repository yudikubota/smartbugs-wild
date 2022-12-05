{"Address.sol":{"content":"pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
"},"Context.sol":{"content":"pragma solidity ^0.5.0;

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
"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

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
    
    function burnFrom(address sender, uint256 amount) external returns (bool);

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
"},"Ownable.sol":{"content":"pragma solidity ^0.5.0;

import "./Context.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    
    //////////////////////////////////////////////////////////////////////////////
    
    // mapping(address => bool) blacklist;
    // event LockUser(address indexed who);
    // event UnlockUser(address indexed who);
    
    // modifier permissionCheck {
    //   require(!blacklist[_msgSender()],"transfer is not enabeled now!");
    //   _;
    // } 
    
    // function setLockUser(address who) public onlyOwner {
    //   blacklist[who] = true;
    //   emit LockUser(who);
    // }
    
    // function unlockUser(address who) public onlyOwner {
    //   blacklist[who] = false;
    //   emit UnlockUser(who);
    // }
    
}
"},"SafeERC20.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    
    function safeBurnFrom(IERC20 token, address from, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.burnFrom.selector, from,value));
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
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;

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
"},"StakePool.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

//import "./Base.sol";
import "./StakeSet.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

// contract Blog{
//     function burnFrom(address account, uint256 amount) public;
// }

contract StakePool is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using StakeSet for StakeSet.Set;


    ///////////////////////////////// constant /////////////////////////////////
    //uint constant DECIMALS = 10 ** 18;

    uint[4] STAKE_PER = [20, 30, 50, 100];
    uint[4] STAKE_POWER_RATE = [100, 120, 150, 200];

    //mainnet:'0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    //ropsten:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
    //rinkeby:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
    //goerli:'0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6',
    //kovan:'0xd0A1E359811322d97991E03f863a0C30C2cF029C'
    // todo: wethToken address
    address constant wethToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public payToken =address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public aToken = address(0x1e8433F5017B3006f634293Ed9Ecf0e9504CdB25);
    address public secretSigner;

    ///////////////////////////////// storage /////////////////////////////////
    uint private _totalStakeToken;
    uint private _totalStakeEth;
    uint private _totalStakeUsdt;
    bool private _isOnlyToken;
    uint public currentId;
    uint private _totalOrders;
    uint private _totalWeight;
   // uint private _total_dynamic_hashrate;
    mapping(address => uint) private _userOrders;
    mapping(address => uint) private _weights;
    mapping(address => uint) private _withdrawalAmount;
    mapping (address => uint256) private _bypass;
    mapping(address => StakeSet.Set) private _stakeOf;
    mapping(uint => bool) public withdrawRewardIdOf;
    

    // tokenAddress => lpAddress
    mapping(address => address) public lpAddress;


    event Stake(address indexed user, uint indexed stakeType, uint indexed stakeId, uint payTokenAmount, uint amount);
    event Withdraw(address indexed user, uint indexed stakeId, uint payTokenAmount, uint amount);
    event WithdrawReward(address indexed _to, uint amount);

    
    function totalStakeUsdt() public view returns (uint) {
        return _totalStakeUsdt;
    }

    function totalStakeToken() public view returns (uint) {
        return _totalStakeToken;
    }
    
    function totalStakeEth() public view returns (uint) {
        return _totalStakeEth;
    }
    
    function userOrders(address account) public view returns (uint) {
        return _userOrders[account];
    }
    
    function isOnlyToken() public view returns (bool) {
        return _isOnlyToken;
    }
    
    function totalOrders() public view returns (uint) {
        return _totalOrders;
    }
    
    function withdrawalAmount(address account) public view returns (uint) {
        return _withdrawalAmount[account];
    }
    
    function bypass(address user) public view returns (uint) {
        return _bypass[user];
    }

    function setPayToken(address _payToken) external onlyOwner returns (bool) {
        payToken = _payToken;
        return true;
    }

    function setAToken(address _aToken) external onlyOwner returns (bool) {
        aToken = _aToken;
        return true;
    }
    
    function setIsOnlyToken(bool _IsOnly) external onlyOwner returns (bool) {
        _isOnlyToken = _IsOnly;
        return true;
    }
    
    function setBypass(address user ,uint256 mode) public onlyOwner returns (bool) {
        _bypass[user]=mode;
        return true;
    }

    /**
     * @dev set swap pair address (aka. Lp Token address)
     */
    function setLpAddress(address _token, address _lp) external onlyOwner returns (bool) {
        lpAddress[_token] = _lp;
        return true;
    }

    function totalWeight() public view returns (uint) {
        return _totalWeight;
    }
    
    // function totalDynamicHashrate() public view returns (uint) {
    //     return _total_dynamic_hashrate;
    // }

    function weightOf(address account) public view returns (uint) {
        return _weights[account];
    }
    
    function setSecretSigner(address _secretSigner) onlyOwner external {
        require(_secretSigner != address(0), "address invalid");
        secretSigner = _secretSigner;
    }

    /**
     * @dev get stake item by '_account' and '_index'
     */
    function getStakeOf(address _account, uint _index) external view returns (StakeSet.Item memory) {
        require(_stakeOf[_account].length() > _index, "getStakeOf: _stakeOf[_account].length() > _index");
        return _stakeOf[_account].at(_index);
    }

    /**
     * @dev get '_account' stakes by page
     */
    function getStakes(address _account, uint _index, uint _offset) external view returns (StakeSet.Item[] memory items) {
        uint totalSize = userOrders(_account);
        require(0 < totalSize && totalSize > _index, "getStakes: 0 < totalSize && totalSize > _index");
        uint offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        items = new StakeSet.Item[](offset);
        for (uint i = 0; i < offset; i++) {
            items[i] = _stakeOf[_account].at(_index + i);
        }
    }
    
    

    /**
     * @dev stake
     * @param _stakeType type of stake rate 1: 8/2, 2: 7/3, 3: 5/5 (payTokenAmount/aTokenAmount)
     * @param _amount    aToken amount
     */
    function stake(uint _stakeType, uint _amount) external payable {
        require(0 < _stakeType && _stakeType <= 4, "stake: 0 < _stakeType && _stakeType <= 4");
        require(0 < _amount, "stake: 0 < _amount");
        uint256 tokenprice = getUSDTPrice(aToken);
        uint256 ethprice;
        uint256 tokenAmount;
        //address payTokenAddr;
        uint256 coinType;
        if(_stakeType==4){
            if(!_isOnlyToken){
                require(_bypass[msg.sender]==1, "stake: Temporarily not opened");
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), _amount);
            }else{
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), _amount);
            }
            tokenAmount=_amount;
            _totalStakeToken = _totalStakeToken.add(_amount);
            //payTokenAddr=address(0);
        }else{
            ethprice = getUSDTPrice(wethToken);
            if (0 < msg.value) { // pay with ETH  25
            // transfer to this
            require(msg.value>=(10**12)*4,"stake: msg.value>=(10**12)*4");
            tokenAmount = ethprice.mul(msg.value).mul(STAKE_PER[_stakeType - 1]).div(uint(100).sub(STAKE_PER[_stakeType - 1])).div(tokenprice).div(10**12);
            IERC20(aToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
            //payTokenAddr = wethToken;
            coinType =1;
            _totalStakeEth = _totalStakeEth.add(msg.value);
            _totalStakeToken = _totalStakeToken.add(tokenAmount);
            } else { // pay with USDT
                // transfer to this
                require(4 <= _amount, "stake: 4 <= _amount");
                tokenAmount = _amount.mul(10**6).mul(STAKE_PER[_stakeType - 1]).div(uint(100).sub(STAKE_PER[_stakeType - 1])).div(tokenprice);
                IERC20(payToken).safeTransferFrom(msg.sender, address(this), _amount);
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
                //payTokenAddr = payToken;
                coinType =2;
                _totalStakeUsdt = _totalStakeUsdt.add(_amount);
                _totalStakeToken = _totalStakeToken.add(tokenAmount);
            }
        }
        StakeSet.Item memory item;
        // calculate power
        uint aTokenValue = tokenprice.mul(tokenAmount).div(10**6);
        uint payTokenValue;
        if(coinType==2){
            payTokenValue = _amount;
            item.payTokenAmount = _amount;
        }else if(coinType==1){
            payTokenValue = ethprice.mul(msg.value).div(10**18);
            item.payTokenAmount = msg.value;
        }else{
            item.payTokenAmount = 0;
        }
        uint power = (aTokenValue.add(payTokenValue)).mul(STAKE_POWER_RATE[_stakeType - 1]).div(100);

        _totalOrders = _totalOrders.add(1);
        _userOrders[msg.sender] = _userOrders[msg.sender].add(1);
        _userOrders[address(0)] = _userOrders[address(0)].add(1);
        _totalWeight = _totalWeight.add(power);
        _weights[msg.sender] = _weights[msg.sender].add(power);

        // update _stakeOf
       // StakeSet.Item memory item;
        item.id = ++currentId;
        item.createTime = block.timestamp;
        item.aTokenAmount = tokenAmount;
        // item.payTokenAddr = payTokenAddr;
        item.useraddress = msg.sender;
        item.power = power;
        item.stakeType = _stakeType;
        item.coinType=coinType;

        // if(getReferees(msg.sender)==address(0)&&msg.sender!=owner()&&getReferees(owner())!=msg.sender){
        //     setReferees(owner());
        // }

        //calcDynamicHashrate(power,msg.sender);
        // item.dpower = getDynamicHashrate(msg.sender);
        _stakeOf[msg.sender].add(item);
        _stakeOf[address(0)].add(item);

        emit Stake(msg.sender, _stakeType, item.id, item.payTokenAmount, _amount);
    }

    /**
     * @dev withdraw stake
     * @param _stakeId  stakeId
     */
    function withdraw(uint _stakeId) external {
        require(currentId >= _stakeId, "withdraw: currentId >= _stakeId");

        // get _stakeOf
        StakeSet.Item memory item = _stakeOf[msg.sender].idAt(_stakeId);
        // transfer to msg.sender
        uint aTokenAmount = item.aTokenAmount;
        uint payTokenAmount = item.payTokenAmount;
        uint _totalToken;
        uint _totalEth;
        uint _totalUsdt;
        // todo: 7 days
        //if (15 minutes > block.timestamp - item.createTime) {
        if (7 days > block.timestamp - item.createTime) {
            aTokenAmount = aTokenAmount.mul(95).div(100);
            payTokenAmount = payTokenAmount.mul(95).div(100);
            _totalToken = _totalToken.add(item.aTokenAmount.mul(5).div(100));
            if (1 == item.coinType){
                _totalEth = _totalEth.add(item.payTokenAmount.mul(5).div(100));
            }else{
                _totalUsdt = _totalUsdt.add(item.payTokenAmount.mul(5).div(100));
            }
        }
        if (1 == item.coinType) { // pay with ETH
            msg.sender.transfer(payTokenAmount);
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeEth = _totalStakeEth.sub(item.payTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        } else if (2 == item.coinType){ // pay with USDT
            IERC20(payToken).safeTransfer(msg.sender, payTokenAmount);
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeUsdt = _totalStakeUsdt.sub(item.payTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        }else{
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        }
        if(_totalToken>0){
            //IERC20(aToken).safeTransfer(owner(), _totalToken);
            IERC20(aToken).safeTransfer(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566), _totalToken);
        }
        if(_totalUsdt>0){
            //IERC20(payToken).safeTransfer(owner(), _totalUsdt);
            IERC20(payToken).safeTransfer(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566), _totalUsdt);
        }
        if(_totalEth>0){
            //address(uint160(owner())).transfer(_totalEth);
            address(uint160(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566))).transfer(_totalEth);
        }
        
        _totalOrders = _totalOrders.sub(1);
        _userOrders[msg.sender] = _userOrders[msg.sender].sub(1);
        _userOrders[address(0)] = _userOrders[address(0)].sub(1);
        _totalWeight = _totalWeight.sub(item.power);
        _weights[msg.sender] = _weights[msg.sender].sub(item.power);

        // update _stakeOf
        _stakeOf[msg.sender].remove(item);
        _stakeOf[address(0)].remove(item);
        emit Withdraw(msg.sender, _stakeId, payTokenAmount, aTokenAmount);
    }
    
    function withdrawReward(uint _withdrawRewardId, address _to, uint _amount, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(_userOrders[_to]>0,"withdrawReward : orders >0");
        require(!withdrawRewardIdOf[_withdrawRewardId], "withdrawReward: invalid withdrawRewardId");
        require(address(0) != _to, "withdrawReward: address(0) != _to");
        require(0 < _amount, "withdrawReward: 0 < _amount");
        require(address(0) != secretSigner, "withdrawReward: address(0) != secretSigner");
        bytes32 msgHash = keccak256(abi.encodePacked(_withdrawRewardId, _to, _amount));
        require(ecrecover(msgHash, _v, _r, _s) == secretSigner, "withdrawReward: incorrect signer");
        require(_withdrawal_balances.sub(_amount)>0,"withdrawReward: Withdrawal is beyond");
        // transfer reward token
        _withdrawal_balances = _withdrawal_balances.sub(_amount);
        IERC20(aToken).safeTransfer(_to, _amount.mul(97).div(100));
        //IERC20(aToken).safeTransfer(owner(), _amount.mul(3).div(100));
        IERC20(aToken).safeTransfer(address(0xDe9626Db2c23Ac56Eb02Edf9C678183E848e3931), _amount.mul(3).div(100));
        // update _withdrawRewardId
        withdrawRewardIdOf[_withdrawRewardId] = true;
        _withdrawalAmount[_to]=_withdrawalAmount[_to].add(_amount);
        emit WithdrawReward(_to, _amount);
    }


    // todo: get token usdt price from swap
    function getUSDTPrice(address _token) public view returns (uint) {

        if (payToken == _token) {return 1 ether;}
        (bool success, bytes memory returnData) = lpAddress[_token].staticcall(abi.encodeWithSignature("getReserves()"));
        if (success) {
            (uint112 reserve0, uint112 reserve1, ) = abi.decode(returnData, (uint112, uint112, uint32));
            uint DECIMALS = 10**18;
            if(_token==aToken){
                DECIMALS = 10**6;
                //return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
            }
            //return uint(reserve0).mul(DECIMALS).div(uint(reserve1));
            return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
        }

        return 0;
    }


    function () external payable {}
    
    /////////////////////////////////////////////////////////////////////////////////////////
    
    mapping (address => address) private _referees;
    mapping (address => address[]) private _mygeneration;
    mapping (address => uint256) private _vip;
    //mapping (address => uint256) private _dynamic_hashrate;
    uint256 private _withdrawal_balances=14400000000;
    uint256 private _lastUpdated = now;

    function fiveMinutesHavePassed() public view returns (bool) {
      return (now >= (_lastUpdated + 1 days));
    }
    
  
    function getReferees(address user) public view returns (address) {
        return _referees[user];
    }
    
    
    function mygeneration(address user) public view returns (address[] memory) {
        return _mygeneration[user];
    }
    
    function getVip(address account) public view returns (uint256) {
        return _vip[account];
        
    }
    
    
    function getWithdrawalBalances() public view returns (uint256) {
        return _withdrawal_balances;
    }
    
    
    function addWithdrawalBalances() public  returns (bool) {
        require(fiveMinutesHavePassed(),"addWithdrawalBalances:It can only be added once a day");
        uint256 amounnt;
        if(_totalWeight<=1000000*10**6&&_totalWeight>0){
            amounnt = 1440*10**6;
        }else if(_totalWeight>1000000*10**6&&_totalWeight<10000000*10**6){
            amounnt = _totalWeight.mul(1440).div(100000000);
        }else if(_totalWeight>=10000000*10**6){
            amounnt = 14400*10**6;
        }
         _lastUpdated = now;
        _withdrawal_balances = _withdrawal_balances.add(amounnt);
        return true;
    }
    
    // function getDynamicHashrate(address user) public view returns (uint256) {
    //     return _dynamic_hashrate[user];
    // }
    
    
    function isSetRef(address my,address myreferees) public view returns (bool) {
        if(myreferees == address(0) || myreferees==my){
            return false; 
        }
        if(_referees[my]!=address(0)){
            return false; 
        }
        if(_mygeneration[my].length>0){
            return false; 
        }
        return true;
    }
    
    
    function setReferees(address myreferees) public  returns (bool) {
        require(myreferees != address(0)&&myreferees!=_msgSender(), "ERC20: myreferees from the zero address or Not for myself");
        require(_referees[_msgSender()]==address(0), "ERC20: References have been given");
        require(_mygeneration[_msgSender()].length==0, "ERC20: Recommended to each other");
        // require(_referees[myreferees]!=_msgSender(), "ERC20: Recommended to each other");
        _referees[_msgSender()] = myreferees;
        address[] storage arr=_mygeneration[myreferees];
        arr.push(_msgSender());
        return true; 
    }
    
    
    // function getHashrate(uint256 staticHashrate,uint m) private  pure returns (uint256 hashrate) {
    //         if(m==0){
    //             hashrate = staticHashrate.mul(18).div(100);
    //         }else if(m==1){
    //             hashrate = staticHashrate.mul(16).div(100);
    //         }else if(m==2){
    //             hashrate = staticHashrate.mul(14).div(100);
    //         }else if(m==3){
    //             hashrate = staticHashrate.mul(12).div(100);
    //         }else if(m==4){
    //             hashrate = staticHashrate.mul(10).div(100);
    //         }else if(4<m&&m<=8){
    //             hashrate = staticHashrate.mul(5).div(100);
    //         }else if(8<m&&m<=12){
    //             hashrate = staticHashrate.mul(2).div(100);
    //         }
    //     return hashrate;
    // }
    
    // function calcDynamicHashrate(uint256 staticHashrate,address user) private  returns (bool) {
    //     address[] memory arr = new address[](13);
    //     uint  i = 0;
    //     while(_referees[user]!=address(0)&&i<13){
    //             arr[i]=_referees[user];
    //             user = _referees[user];
    //             i++;
    //     }
    //     uint  m = 0;
    //     uint256 totalHtate;
    //     while(arr[m]!=address(0)&&m<13){
    //         if(userOrders(arr[m])>0){
    //             uint256 hrate = getHashrate(staticHashrate,m);
    //              _dynamic_hashrate[arr[m]]=_dynamic_hashrate[arr[m]].add(hrate);
    //             totalHtate = totalHtate.add(hrate);
    //             address[] memory mygenerationarr=_mygeneration[arr[m]];
    //             for(uint n = 0;n<mygenerationarr.length;n++){
    //                 if(_vip[mygenerationarr[n]]==3){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(5).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(5).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==4){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(6).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(6).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==5){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(7).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(7).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==6){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(8).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(8).div(100));
    //                 }
    //             }
    //         }
    //         m++;
    //     }
    //     _total_dynamic_hashrate= _total_dynamic_hashrate.add(totalHtate);
    //     return true; 
    // }
    
    function levelCostU(uint256 value,uint256 vip) public pure returns(uint256 u) {
        require(value<=6&&value>vip, "levelCostU: vip false");
            if(value==1){
                u=100;
            }else if(value==2){
                if(vip==0){
                    u=300;
                }else{
                    u=200;
                }
            }else if(value==3){
                if(vip==0){
                    u=500;
                }else if(vip==1){
                    u=400;
                }else{
                    u=200;
                }
            }else if(value==4){
                if(vip==0){
                    u=700;
                }else if(vip==1){
                    u=600;
                }else if(vip==2){
                    u=400;
                }else{
                    u=200;
                }
            }else if(value==5){
                if(vip==0){
                    u=1000;
                }else if(vip==1){
                    u=900;
                }else if(vip==2){
                    u=700;
                }else if(vip==3){
                    u=500;
                }else{
                    u=300;
                }
            }else{
                if(vip==0){
                    u=1500;
                }else if(vip==1){
                    u=1400;
                }else if(vip==2){
                    u=1200;
                }else if(vip==3){
                    u=1000;
                }else if(vip==4){
                    u=800;
                }else{
                     u=500;
                }
            }
    }
    
    function user_burn(uint256 value) public  returns(bool) {
        require(value<=6&&value>_vip[_msgSender()], "user_burn: vip false");
        uint256 u = levelCostU(value,_vip[_msgSender()]);
        uint256 price = getUSDTPrice(aToken);
        require(price>=0, "user_burn: need token price");
        uint256 burnTokenAmount = u.mul(10**12).div(price);
        //blog.burnFrom(_msgSender(),burnTokenAmount);
        IERC20(aToken).safeBurnFrom(_msgSender(), burnTokenAmount);
         _vip[_msgSender()]=value;
      return true;
    }
   
}"},"StakeSet.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

library StakeSet {

    struct Item {
        uint id;
        uint createTime;
        uint power;
        uint aTokenAmount;
        uint payTokenAmount;
        uint stakeType;
        uint coinType;
        //uint dpower;
        //address payTokenAddr;
        address useraddress;

    }

    struct Set {
        Item[] _values;
        // id => index
        mapping (uint => uint) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, Item memory value) internal returns (bool) {
        if (!contains(set, value.id)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.id] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Set storage set, Item memory value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value.id];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            Item memory lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue.id] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value.id];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint valueId) internal view returns (bool) {
        return set._indexes[valueId] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Set storage set, uint256 index) internal view returns (Item memory) {
        require(set._values.length > index, "StakeSet: index out of bounds");
        return set._values[index];
    }

    function idAt(Set storage set, uint256 valueId) internal view returns (Item memory) {
        require(set._indexes[valueId] != 0, "StakeSet: set._indexes[valueId] != 0");
        uint index = set._indexes[valueId] - 1;
        require(set._values.length > index, "StakeSet: index out of bounds");
        return set._values[index];
    }

}
"}}