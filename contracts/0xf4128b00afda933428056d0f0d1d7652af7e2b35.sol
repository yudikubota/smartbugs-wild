{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "istanbul",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "remappings": [],
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  },
  "sources": {
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

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
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    "@openzeppelin/contracts/token/ERC20/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    "@openzeppelin/contracts/utils/Address.sol": {
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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    },
    "contracts/HegicStakingPool.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract HegicStakingPool is Ownable, ERC20{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // Tokens
    IERC20 public immutable HEGIC;
    IERC20 public immutable WBTC;

    mapping(Asset => IHegicStaking) public staking; 

    uint public STAKING_LOT_PRICE = 888_000e18;
    uint public ACCURACY = 1e32;

    address payable public FALLBACK_RECIPIENT;
    address payable public FEE_RECIPIENT;
    
    uint public DISCOUNTED_LOTS = 10;
    uint public DISCOUNT_FIRST_LOTS = 20000; // 25%
    uint public DISCOUNT_FIRST_LOT = 50000; // 50%

    uint public performanceFee = 5000;
    bool public depositsAllowed = true;
    uint public lockUpPeriod = 15 minutes;

    uint public totalBalance;
    uint public lockedBalance;
    uint public totalNumberOfStakingLots;
    mapping(Asset => uint) public numberOfStakingLots;
    mapping(Asset => uint) public totalProfitPerToken;

    enum Asset {WBTC, ETH}

    address[] owners;
    mapping(address => uint) public ownerPerformanceFee;
    mapping(address => bool) public isNotFirstTime;
    mapping(address => uint) public lastDepositTime;
    mapping(address => mapping(Asset => uint)) lastProfit;
    mapping(address => mapping(Asset => uint)) savedProfit;

    event Deposit(address account, uint amount);
    event Withdraw(address account, uint amount);
    event BuyLot(uint id, Asset asset, address account);
    event SellLot(uint id, Asset asset, address account);
    event ClaimedProfit(address account, Asset asset, uint netProfit, uint fee);

    constructor(IERC20 _HEGIC, IERC20 _WBTC, IHegicStaking _stakingWBTC, IHegicStaking _stakingETH) public ERC20("Staked HEGIC", "sHEGIC"){
        HEGIC = _HEGIC;
        WBTC = _WBTC;
        staking[Asset.WBTC] = _stakingWBTC;
        staking[Asset.ETH] = _stakingETH;

        FEE_RECIPIENT = msg.sender;
        FALLBACK_RECIPIENT = msg.sender;

        // Approving to Staking Lot Contract
        _HEGIC.approve(address(staking[Asset.WBTC]), 888e30);
        _HEGIC.approve(address(staking[Asset.ETH]), 888e30);
    }

    // Payable 
    receive() external payable {}

    /**
     * @notice Stops the ability to add new deposits
     * @param _allow If set to false, new deposits will be rejected
     */
    function allowDeposits(bool _allow) external onlyOwner {
        depositsAllowed = _allow;
    }

    /**
     * @notice Changes Fee paid to creator (only paid when taking profits)
     * @param _fee New fee
     */
    function changePerformanceFee(uint _fee) external onlyOwner {
        require(_fee >= 0, "Fee too low");
        require(_fee <= 8000, "Fee too high");
        
        performanceFee = _fee;
    }

    /**
     * @notice Changes Fee Recipient address
     * @param _recipient New address
     */
    function changeFeeRecipient(address _recipient) external onlyOwner {
        FEE_RECIPIENT = payable(_recipient);
    }

    /**
     * @notice Changes Fallback Recipient address. This is only used in case of unexpected behavior
     * @param _recipient New address
     */
    function changeFallbackRecipient(address _recipient) external onlyOwner {
        FALLBACK_RECIPIENT = payable(_recipient);
    }

    /**
     * @notice Toggles effect of lockup period by setting lockUpPeriod to 0 (disabled) or to 15 minutes(enabled)
     * @param _unlock Boolean: if true, unlocks funds
     */
    function unlockAllFunds(bool _unlock) external onlyOwner {
        if(_unlock) lockUpPeriod = 0;
        else lockUpPeriod = 15 minutes;
    }

    /**
     * @notice Deposits _amount HEGIC in the contract. 
     * 
     * @param _amount Number of HEGIC to deposit in the contract // number of sHEGIC that will be minted
     */
    function deposit(uint _amount) external {
        require(_amount > 0, "Amount too low");
        require(depositsAllowed, "Deposits are not allowed at the moment");
        // set fee for that staking lot owner - this effectively sets the maximum FEE an owner can have
        // each time user deposits, this checks if current fee is higher or lower than previous fees
        // and updates it if it is lower
        if(ownerPerformanceFee[msg.sender] > performanceFee || !isNotFirstTime[msg.sender]) {
            ownerPerformanceFee[msg.sender] = performanceFee;
            // those that deposit in first DISCOUNTED_LOTS lots get a discount
            if(!isNotFirstTime[msg.sender] && totalNumberOfStakingLots < 1){
                ownerPerformanceFee[msg.sender] = ownerPerformanceFee[msg.sender].mul(uint(100000).sub(DISCOUNT_FIRST_LOT)).div(100000);
            } else if(!isNotFirstTime[msg.sender] && totalNumberOfStakingLots < DISCOUNTED_LOTS){
                ownerPerformanceFee[msg.sender] = ownerPerformanceFee[msg.sender].mul(uint(100000).sub(DISCOUNT_FIRST_LOTS)).div(100000);
            }
            isNotFirstTime[msg.sender] = true;
        }
        lastDepositTime[msg.sender] = block.timestamp;
        // receive deposit
        depositHegic(_amount);

        while(totalBalance.sub(lockedBalance) >= STAKING_LOT_PRICE){
            buyStakingLot();
        }
    }

    /**
     * @notice Withdraws _amount HEGIC from the contract. 
     * 
     * @param _amount Number of HEGIC to withdraw from contract // number of sHEGIC that will be burnt
     */
    function withdraw(uint _amount) public {
        require(_amount <= balanceOf(msg.sender), "Not enough balance");
        require(lastDepositTime[msg.sender].add(lockUpPeriod) <= block.timestamp, "You deposited less than 15 mins ago. Your funds are locked");

        while(totalBalance.sub(lockedBalance) < _amount){
            sellStakingLot();
        }

        withdrawHegic(_amount);
    }

    /**
     * @notice Withdraws _amount HEGIC from the contract and claims all profit pending in contract
     * 
     */
    function claimProfitAndWithdraw() external {
        claimAllProfit();
        withdraw(balanceOf(msg.sender));
    }

    /**
     * @notice Claims profit for both assets. Profit will be paid to msg.sender
     * This is the most gas-efficient way to claim profits (instead of separately)
     * 
     */
    function claimAllProfit() public {
        claimProfit(Asset.WBTC);
        claimProfit(Asset.ETH);
    }

    /**
     * @notice Claims profit for specific _asset. Profit will be paid to msg.sender
     * 
     * @param _asset Asset (ETH or WBTC)
     */
    function claimProfit(Asset _asset) public {
        uint profit = saveProfit(msg.sender, _asset);
        savedProfit[msg.sender][_asset] = 0;
        
        _transferProfit(profit, _asset, msg.sender, ownerPerformanceFee[msg.sender]);
    }

    /**
     * @notice Returns profit to be paid when claimed
     * 
     * @param _account Account to get profit for
     * @param _asset Asset (ETH or WBTC)
     */
    function profitOf(address _account, Asset _asset) public view returns (uint profit) {
        return savedProfit[_account][_asset].add(getUnsaved(_account, _asset));
    }

    /**
     * @notice Returns address of Hegic's ETH Staking Lot contract
     */
    function getHegicStakingETH() public view returns (IHegicStaking HegicStakingETH){
        return staking[Asset.ETH];
    }

    /**
     * @notice Returns address of Hegic's WBTC Staking Lot contract
     */
    function getHegicStakingWBTC() public view returns (IHegicStaking HegicStakingWBTC){
        return staking[Asset.WBTC];
    }

    /**
     * @notice Support function. Gets profit that has not been saved (either in Staking Lot contracts)
     * or in this contract
     * 
     * @param _account Account to get unsaved profit for
     * @param _asset Asset (ETH or WBTC)
     */
    function getUnsaved(address _account, Asset _asset) public view returns (uint profit) {
        profit = totalProfitPerToken[_asset].sub(lastProfit[_account][_asset]).add(getUnreceivedProfitPerToken(_asset)).mul(balanceOf(_account)).div(ACCURACY);
    }

    /**
     * @notice Internal function. Update profit per token for _asset
     * 
     * @param _asset Underlying asset (ETH or WBTC)
     */
    function updateProfit(Asset _asset) internal {
        uint profit;
        profit = staking[_asset].profitOf(address(this));
        if(profit > 0) staking[_asset].claimProfit();
        
        if(totalBalance <= 0) {
            if(_asset == Asset.ETH) FALLBACK_RECIPIENT.transfer(profit);
            else if(_asset == Asset.WBTC) WBTC.safeTransfer(FALLBACK_RECIPIENT, profit);
        } else totalProfitPerToken[_asset] = totalProfitPerToken[_asset].add(profit.mul(ACCURACY).div(totalBalance));
    }

    /**
     * @notice Internal function. Transfers net profit to the owner of the sHEGIC. 
     * 
     * @param _amount Amount of Asset (ETH or WBTC) to be sent
     * @param _asset Asset to be sent (ETH or WBTC)
     * @param _account Receiver of the net profit
     * @param _fee Fee % to be applied to the profit (100% = 100000)
     */
    function _transferProfit(uint _amount, Asset _asset, address _account, uint _fee) internal {
        uint netProfit = _amount.mul(uint(100000).sub(_fee)).div(100000);
        uint fee = _amount.sub(netProfit);

        if(_asset == Asset.ETH){
            payable(_account).transfer(netProfit);
            FEE_RECIPIENT.transfer(fee);
        } else if (_asset == Asset.WBTC) {
            WBTC.safeTransfer(_account, netProfit);
            WBTC.safeTransfer(FEE_RECIPIENT, fee);
        }
        emit ClaimedProfit(_account, _asset, netProfit, fee);
    }

    /**
     * @notice Internal function to transfer deposited HEGIC to the contract and mint sHEGIC (Staked HEGIC)
     * @param _amount Amount of HEGIC to deposit // Amount of sHEGIC that will be minted
     */
    function depositHegic(uint _amount) internal {
        totalBalance = totalBalance.add(_amount); 

        HEGIC.safeTransferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Internal function. Moves _amount HEGIC from contract to user
     * also burns staked HEGIC (sHEGIC) tokens
     * @param _amount Amount of HEGIC to withdraw // Amount of sHEGIC that will be burned
     */
    function withdrawHegic(uint _amount) internal {

        emit Withdraw(msg.sender, _amount);

        _burn(msg.sender, _amount);
        HEGIC.safeTransfer(msg.sender, _amount);
        totalBalance = totalBalance.sub(_amount);
    }

    /**
     * @notice Internal function. Chooses which lot to buy (ETH or WBTC) and buys it
     *
     */
    function buyStakingLot() internal {
        // we buy 1 ETH staking lot, then 1 WBTC staking lot, then 1 eth, ...
        Asset asset = Asset.ETH;
        if(numberOfStakingLots[Asset.ETH] > numberOfStakingLots[Asset.WBTC]){
            asset = Asset.WBTC;
        }

        if(staking[asset].totalSupply() == staking[asset].MAX_SUPPLY()){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }

        require(staking[asset].totalSupply() < staking[asset].MAX_SUPPLY(), "There are no more available lots for purchase");

        lockedBalance = lockedBalance.add(STAKING_LOT_PRICE);
        staking[asset].buy(1);
        emit BuyLot(block.timestamp, asset, msg.sender);
        totalNumberOfStakingLots++;
        numberOfStakingLots[asset]++;
    }

    /**
     * @notice Internal function. Chooses which lot to sell (ETH or WBTC) and sells it
     *
     */
    function sellStakingLot() internal {
        Asset asset = Asset.ETH;
        if(numberOfStakingLots[Asset.ETH] < numberOfStakingLots[Asset.WBTC]){
            asset = Asset.WBTC;
        }

        // I check if the staking lot to be sold is locked by HEGIC.
        // if it is, I try switching underlying asset (which should be the previously bought lot). 
        if(staking[asset].lastBoughtTimestamp(address(this))
                .add(staking[asset].lockupPeriod()) > block.timestamp){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }
        
        if(staking[asset].balanceOf(address(this)) == 0){
            if(asset == Asset.ETH) asset = Asset.WBTC;
            else asset = Asset.ETH;
        }

        require(
            staking[asset].lastBoughtTimestamp(address(this))
                .add(staking[asset].lockupPeriod()) <= block.timestamp,
             "Lot sale is locked by Hegic. Funds should be available in less than 24h"
        );

        lockedBalance = lockedBalance.sub(STAKING_LOT_PRICE);
        staking[asset].sell(1);
        emit SellLot(block.timestamp, asset, msg.sender);
        totalNumberOfStakingLots--;
        numberOfStakingLots[asset]--;
    }

    /**
     * @notice Support function. Calculates how much profit would receive each token if the contract claimed
     * profit accumulated in Hegic's Staking Lot contracts
     * 
     * @param _asset Asset (WBTC or ETH)
     */
    function getUnreceivedProfitPerToken(Asset _asset) public view returns (uint unreceivedProfitPerToken){
        uint profit = staking[_asset].profitOf(address(this));
        
        unreceivedProfitPerToken = profit.mul(ACCURACY).div(totalBalance);
    }

    /**
     * @notice Saves profit for a certain _account. This profit is absolute in value
     * this function is called before every token transfer to keep the state of profits correctly
     * 
     * @param _account account to save profit to
     */
    function saveProfit(address _account) internal {
        saveProfit(_account, Asset.WBTC);
        saveProfit(_account, Asset.ETH);
    }

    /**
     * @notice Internal function that saves unpaid profit to keep accounting.
     * 
     * @param _account Account to save profit to
     * @param _asset Asset (WBTC or ETH)     
     */
    function saveProfit(address _account, Asset _asset) internal returns (uint profit) {
        updateProfit(_asset);
        uint unsaved = getUnsaved(_account, _asset);
        lastProfit[_account][_asset] = totalProfitPerToken[_asset];
        profit = savedProfit[_account][_asset].add(unsaved);
        savedProfit[_account][_asset] = profit;
    }

    /**
     * @notice Support function. Relevant to the profit system. It will save state of profit before each 
     * token transfer (either deposit or withdrawal)
     * 
     * @param from Account sending tokens 
     * @param to Account receiving tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) saveProfit(from);
        if (to != address(0)) saveProfit(to);
    }

    /**
     * @notice Returns a boolean indicating if that specific _account can withdraw or not
     * (due to lockupperiod reasons)
     * @param _account Account to check withdrawal status 
     */
    function canWithdraw(address _account) public view returns (bool) {
        return (lastDepositTime[_account].add(lockUpPeriod) <= block.timestamp);
    }
}
"
    },
    "contracts/Interfaces.sol": {
      "content": "/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IHegicStaking is IERC20 {
    function lockupPeriod() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function lastBoughtTimestamp(address) external view returns (uint256);

    function claimProfit() external returns (uint profit);
    function buy(uint amount) external;
    function sell(uint amount) external;
    function profitOf(address account) external view returns (uint profit);
}

interface IHegicStakingETH is IHegicStaking {
    function sendProfit() external payable;
}

interface IHegicStakingERC20 is IHegicStaking {
    function sendProfit(uint amount) external;
}
"
    }
  }
}}