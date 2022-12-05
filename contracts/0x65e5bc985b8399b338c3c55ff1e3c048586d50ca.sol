{"Address.sol":{"content":"pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/utils/Address.sol

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
}"},"Context.sol":{"content":"pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

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
}"},"ERC20.sol":{"content":"pragma solidity ^0.6.12;

import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

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

    mapping (address => uint256) internal _balances;

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
    function decimals() public view override returns (uint8) {
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
}"},"IERC20.sol":{"content":"pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the number of decimal places.
     */
    function decimals() external view returns (uint8);

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
}"},"IUniswapV2Pair.sol":{"content":"
pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}"},"IUniswapV2Router02.sol":{"content":"pragma solidity ^0.6.12;

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}"},"Ownable.sol":{"content":"pragma solidity ^0.6.12;

import './Context.sol';

// File: @openzeppelin/contracts/access/Ownable.sol

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
}"},"SafeERC20.sol":{"content":"pragma solidity ^0.6.12;

import './SafeMath.sol';
import './Address.sol';
import './IERC20.sol';

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
}"},"SafeMath.sol":{"content":"pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
}"},"SURF.sol":{"content":"
/*
   _____ __  ______  ______     ___________   _____    _   ______________
  / ___// / / / __ \/ ____/    / ____/  _/ | / /   |  / | / / ____/ ____/
  \__ \/ / / / /_/ / /_       / /_   / //  |/ / /| | /  |/ / /   / __/   
 ___/ / /_/ / _, _/ __/  _   / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
/____/\____/_/ |_/_/    (_) /_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/  

Website: https://surf.finance
Created by Proof and sol_dev, with help from Zoma and Mr Fahrenheit
Audited by Aegis DAO and Sherlock Security

*/

pragma solidity ^0.6.12;

import './ERC20.sol';
import './IERC20.sol';
import './Ownable.sol';
import './Whirlpool.sol';

interface Callable {
    function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
    function receiveApproval(address _from, uint256 _tokens, address _token, bytes calldata _data) external;
}

// SURF Token with Governance. The governance contract will own the SURF, Tito, and Whirlpool contracts,
// allowing SURF token holders to make and vote on proposals that can modify many parts of the protocol.
contract SURF is ERC20("SURF.Finance", "SURF"), Ownable {

    // There will be a max supply of 10,000,000 SURF tokens
    uint256 public constant MAX_SUPPLY = 10000000 * 10**18;
    bool public maxSupplyHit = false;

    // The SURF transfer fee that gets rewarded to Whirlpool stakers (1 = 0.1%). Defaults to 1%
    uint256 public transferFee = 10;

    // Mapping of whitelisted sender and recipient addresses that don't pay the transfer fee. Allows SURF token holders to whitelist future contracts
    mapping(address => bool) public senderWhitelist;
    mapping(address => bool) public recipientWhitelist;

    // The Tito contract
    address public titoAddress;

    // The Whirlpool contract
    address payable public whirlpoolAddress;

    // The Uniswap SURF-ETH LP token address
    address public surfPoolAddress;

    // Creates `_amount` token to `_to`. Can only be called by the Tito contract.
    function mint(address _to, uint256 _amount) public {
        require(maxSupplyHit != true, "max supply hit");
        require(msg.sender == titoAddress, "not Tito");
        uint256 supply = totalSupply();
        if (supply.add(_amount) >= MAX_SUPPLY) {
            _amount = MAX_SUPPLY.sub(supply);
            maxSupplyHit = true;
        }

        if (_amount > 0) {
            _mint(_to, _amount);
            _moveDelegates(address(0), _delegates[_to], _amount);
        }
    }

    // Sets the addresses of the Tito farming contract, the Whirlpool staking contract, and the Uniswap SURF-ETH LP token
    function setContractAddresses(address _titoAddress, address payable _whirlpoolAddress, address _surfPoolAddress) public onlyOwner {
        if (_titoAddress != address(0)) titoAddress = _titoAddress;
        if (_whirlpoolAddress != address(0)) whirlpoolAddress = _whirlpoolAddress;
        if (_surfPoolAddress != address(0)) surfPoolAddress = _surfPoolAddress;
    }

    // Sets the SURF transfer fee that gets rewarded to Whirlpool stakers. Can't be higher than 10%.
    function setTransferFee(uint256 _transferFee) public onlyOwner {
        require(_transferFee <= 100, "over 10%");
        transferFee = _transferFee;
    }

    // Add an address to the sender or recipient transfer whitelist
    function addToTransferWhitelist(bool _addToSenderWhitelist, address _address) public onlyOwner {
        if (_addToSenderWhitelist == true) senderWhitelist[_address] = true;
        else recipientWhitelist[_address] = true;
    }

    // Remove an address from the sender or recipient transfer whitelist
    function removeFromTransferWhitelist(bool _removeFromSenderWhitelist, address _address) public onlyOwner {
        if (_removeFromSenderWhitelist == true) senderWhitelist[_address] = false;
        else recipientWhitelist[_address] = false;
    }

    // Both the Tito and Whirlpool contracts will lock the SURF-ETH LP tokens they receive from their staking/unstaking fees here (ensuring liquidity forever).
    // This function allows SURF token holders to decide what to do with the locked LP tokens in the future
    function migrateLockedLPTokens(address _to, uint256 _amount) public onlyOwner {
        IERC20 surfPool = IERC20(surfPoolAddress);
        require(_amount > 0 && _amount <= surfPool.balanceOf(address(this)), "bad amount");
        surfPool.transfer(_to, _amount);
    }

    function approveAndCall(address _spender, uint256 _tokens, bytes calldata _data) external returns (bool) {
        approve(_spender, _tokens);
        Callable(_spender).receiveApproval(msg.sender, _tokens, address(this), _data);
        return true;
    }

    function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
        uint256 _balanceBefore = balanceOf(_to);
        transfer(_to, _tokens);
        uint256 _tokensReceived = balanceOf(_to) - _balanceBefore;
        uint32 _size;
        assembly {
            _size := extcodesize(_to)
        }
        if (_size > 0) {
            require(Callable(_to).tokenCallback(msg.sender, _tokensReceived, _data));
        }
        return true;
    }

    // There's a fee on every SURF transfer that gets sent to the Whirlpool staking contract which will start getting rewarded to stakers after the max supply is hit.
    // The transfer fee will reduce the front-running of Uniswap trades and will provide a major incentive to hold and stake SURF long-term.
    // Transfers to/from the Tito or Whirlpool contracts will not pay a fee.
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 transferFeeAmount;
        uint256 tokensToTransfer;

        if (amount > 0) {

            // Send a fee to the Whirlpool staking contract if this isn't a whitelisted transfer
            if (_isWhitelistedTransfer(sender, recipient) != true) {
                transferFeeAmount = amount.mul(transferFee).div(1000);
                _balances[whirlpoolAddress] = _balances[whirlpoolAddress].add(transferFeeAmount);
                _moveDelegates(_delegates[sender], _delegates[whirlpoolAddress], transferFeeAmount);
                Whirlpool(whirlpoolAddress).addSurfReward(sender, transferFeeAmount);
                emit Transfer(sender, whirlpoolAddress, transferFeeAmount);
            }

            tokensToTransfer = amount.sub(transferFeeAmount);

            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

            if (tokensToTransfer > 0) {
                _balances[recipient] = _balances[recipient].add(tokensToTransfer);
                _moveDelegates(_delegates[sender], _delegates[recipient], tokensToTransfer);

                // If the Whirlpool staking contract is the transfer recipient, addSurfReward gets called to keep things in sync
                if (recipient == whirlpoolAddress) Whirlpool(whirlpoolAddress).addSurfReward(sender, tokensToTransfer);
            }

        }

        emit Transfer(sender, recipient, tokensToTransfer);
    }

    // Internal function to determine if a SURF transfer is being sent or received by a whitelisted address
    function _isWhitelistedTransfer(address _sender, address _recipient) internal view returns (bool) {
        // The Whirlpool and Tito contracts are always whitelisted
        return
            _sender == whirlpoolAddress || _recipient == whirlpoolAddress ||
            _sender == titoAddress || _recipient == titoAddress ||
            senderWhitelist[_sender] == true || recipientWhitelist[_recipient] == true;
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @dev A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @dev The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @dev An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @dev An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

   /**
    * @dev Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SURF::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SURF::delegateBySig: invalid nonce");
        require(now <= expiry, "SURF::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "SURF::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SURFs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "SURF::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}"},"Tito.sol":{"content":"
/*
   _____ __  ______  ______     ___________   _____    _   ______________
  / ___// / / / __ \/ ____/    / ____/  _/ | / /   |  / | / / ____/ ____/
  \__ \/ / / / /_/ / /_       / /_   / //  |/ / /| | /  |/ / /   / __/   
 ___/ / /_/ / _, _/ __/  _   / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
/____/\____/_/ |_/_/    (_) /_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/  

Website: https://surf.finance
Created by Proof and sol_dev, with help from Zoma and Mr Fahrenheit
Audited by Aegis DAO and Sherlock Security

*/

pragma solidity ^0.6.12;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './IUniswapV2Router02.sol';
import './UniStakingInterfaces.sol';
import './SURF.sol';
import './Whirlpool.sol';

// Tito is the master of SURF. He can make SURF, is a fair guy, and a great instructor.
contract Tito is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 staked; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 uniRewardDebt; // UNI staking reward debt. See explanation below.
        uint256 claimed; // Tracks the amount of SURF claimed by the user.
        uint256 uniClaimed; // Tracks the amount of UNI claimed by the user.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        IERC20 lpToken; // Address of LP token contract.
        uint256 apr; // Fixed APR for the pool. Determines how many SURFs to distribute per block.
        uint256 lastSurfRewardBlock; // Last block number that SURF rewards were distributed.
        uint256 accSurfPerShare; // Accumulated SURFs per share, times 1e12. See below.
        uint256 accUniPerShare; // Accumulated UNIs per share, times 1e12. See below.
        address uniStakeContract; // Address of UNI staking contract (if applicable).
    }

    // We do some fancy math here. Basically, any point in time, the amount of SURFs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.staked * pool.accSurfPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accSurfPerShare` (and `lastSurfRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `staked` amount gets updated.
    //   4. User's `rewardDebt` gets updated.

    // The SURF TOKEN!
    SURF public surf;
    // The address of the SURF-ETH Uniswap pool
    address public surfPoolAddress;
     // The Whirlpool staking contract
    Whirlpool public whirlpool;
    // The Uniswap v2 Router
    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // The UNI Staking Rewards Factory
    StakingRewardsFactory internal uniStakingFactory = StakingRewardsFactory(0x3032Ab3Fa8C01d786D29dAdE018d7f2017918e12);
    // The UNI Token
    IERC20 internal uniToken = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    // The WETH Token
    IERC20 internal weth;
    // Dev address
    address payable public devAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => bool) public existingPools;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Mapping of whitelisted contracts so that certain contracts like the Aegis pool can interact with the Tito contract
    mapping(address => bool) public contractWhitelist;
    // The block number when SURF mining starts.
    uint256 public startBlock;
    // Becomes true once the SURF-ETH Uniswap is created (no sooner than 500 blocks after launch)
    bool public surfPoolActive = false;
    // The staking fees collected during the first 500 blocks will seed the SURF-ETH Uniswap pool
    uint256 public initialSurfPoolETH  = 0;
    // 5% of every deposit into any secondary pool (not SURF-ETH) will be converted to SURF (on Uniswap) and sent to the Whirlpool staking contract which becomes active and starts distributing the accumulated SURF to stakers once the max supply is hit
    uint256 public surfSentToWhirlpool = 0;
    // The amount of ETH donated to the SURF community by partner projects
    uint256 public donatedETH = 0;
    // Certain partner projects need to donate 25 ETH to the SURF community to get a beach
    uint256 internal constant minimumDonationAmount = 25 * 10**18;
    // Mapping of addresses that donated ETH on behalf of a partner project
    mapping(address => address) internal donaters;
    // Mapping of the size of donations from partner projects
    mapping(address => uint256) internal donations;
    // Approximate number of blocks per year - assumes 13 second blocks
    uint256 internal constant APPROX_BLOCKS_PER_YEAR  = uint256(uint256(365 days) / uint256(13 seconds));
    // The default APR for each pool will be 1,000%
    uint256 internal constant DEFAULT_APR = 1000;
    // There will be a 1000 block Soft Launch in which SURF is minted to each pool at a static rate to make the start as fair as possible
    uint256 internal constant SOFT_LAUNCH_DURATION = 1000;
    // During the Soft Launch, all pools except for the SURF-ETH pool will mint 40 SURF per block. Once it's activated, the SURF-ETH pool will mint the same amount of SURF per block as all of the other pools combined until the end of the Soft Launch
    uint256 internal constant SOFT_LAUNCH_SURF_PER_BLOCK = 40 * 10**18;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 surfAmount, uint256 uniAmount);
    event ClaimAll(address indexed user, uint256 surfAmount, uint256 uniAmount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SurfBuyback(address indexed user, uint256 ethSpentOnSurf, uint256 surfBought);
    event SurfPoolActive(address indexed user, uint256 surfLiquidity, uint256 ethLiquidity);

    constructor(
        SURF _surf,
        address payable _devAddress,
        uint256 _startBlock
    ) public {
        surf = _surf;
        devAddress = _devAddress;
        startBlock = _startBlock;
        weth = IERC20(uniswapRouter.WETH());

        // Calculate the address the SURF-ETH Uniswap pool will exist at
        address uniswapfactoryAddress = uniswapRouter.factory();
        address surfAddress = address(surf);
        address wethAddress = address(weth);

        // token0 must be strictly less than token1 by sort order to determine the correct address
        (address token0, address token1) = surfAddress < wethAddress ? (surfAddress, wethAddress) : (wethAddress, surfAddress);

        surfPoolAddress = address(uint(keccak256(abi.encodePacked(
            hex'ff',
            uniswapfactoryAddress,
            keccak256(abi.encodePacked(token0, token1)),
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        ))));

        _addInitialPools();
    }

    receive() external payable {}

    // Internal function to add a new LP Token pool
    function _addPool(address _token, address _lpToken) internal {

        uint256 apr = DEFAULT_APR;
        if (_token == address(surf)) apr = apr * 5;

        uint256 lastSurfRewardBlock = block.number > startBlock ? block.number : startBlock;

        poolInfo.push(
            PoolInfo({
                token: IERC20(_token),
                lpToken: IERC20(_lpToken),
                apr: apr,
                lastSurfRewardBlock: lastSurfRewardBlock,
                accSurfPerShare: 0,
                accUniPerShare: 0,
                uniStakeContract: address(0)
            })
        );

        existingPools[_lpToken] = true;
    }

    // Internal function that adds all of the pools that will be available at launch. Called by the constructor
    function _addInitialPools() internal {

        _addPool(address(surf), surfPoolAddress); // SURF-ETH

        _addPool(0xdAC17F958D2ee523a2206206994597C13D831ec7, 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852); // ETH-USDT
        _addPool(0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11); // DAI-ETH
        _addPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc); // USDC-ETH
        _addPool(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940); // WBTC-ETH
        _addPool(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xd3d2E2692501A5c9Ca623199D38826e513033a17); // UNI-ETH
        _addPool(0x514910771AF9Ca656af840dff83E8264EcF986CA, 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974); // LINK-ETH
        _addPool(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f); // AAVE-ETH
        _addPool(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, 0x43AE24960e5534731Fc831386c07755A2dc33D47); // SNX-ETH
        _addPool(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, 0xC2aDdA861F89bBB333c90c492cB837741916A225); // MKR-ETH
        _addPool(0xc00e94Cb662C3520282E6f5717214004A7f26888, 0xCFfDdeD873554F362Ac02f8Fb1f02E5ada10516f); // COMP-ETH
        _addPool(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28); // YFI-ETH
        _addPool(0xba100000625a3754423978a60c9317c58a424e3D, 0xA70d458A4d9Bc0e6571565faee18a48dA5c0D593); // BAL-ETH
        _addPool(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b, 0x4d5ef58aAc27d99935E5b6B4A6778ff292059991); // DPI-ETH
        _addPool(0xD46bA6D942050d489DBd938a2C909A5d5039A161, 0xc5be99A02C6857f9Eac67BbCE58DF5572498F40c); // AMPL-ETH
        _addPool(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39, 0x55D5c232D921B9eAA6b37b5845E439aCD04b4DBa); // HEX-ETH
        _addPool(0x93ED3FBe21207Ec2E8f2d3c3de6e058Cb73Bc04d, 0x343FD171caf4F0287aE6b87D75A8964Dc44516Ab); // PNK-ETH
        _addPool(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5, 0xdc98556Ce24f007A5eF6dC1CE96322d65832A819); // PICKLE-ETH
        _addPool(0x84294FC9710e1252d407d3D80A84bC39001bd4A8, 0x0C5136B5d184379fa15bcA330784f2d5c226Fe96); // NUTS-ETH
        _addPool(0x821144518dfE9e7b44fCF4d0824e15e8390d4637, 0x490B5B2489eeFC4106C69743F657e3c4A2870aC5); // ATIS-ETH
        _addPool(0xB9464ef80880c5aeA54C7324c0b8Dd6ca6d05A90, 0xa8D0f6769AB020877f262D8Cd747c188D9097d7E); // LOCK-ETH
        _addPool(0x926dbD499d701C61eABe2d576e770ECCF9c7F4F3, 0xC7c0EDf0b5f89eff96aF0E31643Bd588ad63Ea23); // aDAO-ETH
        _addPool(0x3A9FfF453d50D4Ac52A6890647b823379ba36B9E, 0x260E069deAd76baAC587B5141bB606Ef8b9Bab6c); // SHUF-ETH
        _addPool(0x9720Bcf5a92542D4e286792fc978B63a09731CF0, 0x08538213596fB2c392e9c5d4935ad37645600a57); // OTBC-ETH
        _addPool(0xEEF9f339514298C6A857EfCfC1A762aF84438dEE, 0x23d15EDceb5B5B3A23347Fa425846DE80a2E8e5C); // HEZ-ETH

        // These beaches will be manually added after their teams make the 25 ETH donation
        // _addPool(0x6F87D756DAf0503d08Eb8993686c7Fc01Dc44fB1, 0xd2E0C4928789e5DB620e53af29F5fC7bcA262635); // TRADE-ETH
        
    }

    // Get the pending SURFs for a user from 1 pool
    function _pendingSurf(uint256 _pid, address _user) internal view returns (uint256) {
        if (_pid == 0 && surfPoolActive != true) return 0;

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accSurfPerShare = pool.accSurfPerShare;
        uint256 lpSupply = _getPoolSupply(_pid);

        if (block.number > pool.lastSurfRewardBlock && lpSupply != 0) {
            uint256 surfReward = _calculateSurfReward(_pid, lpSupply);

            // Make sure that surfReward won't push the total supply of SURF past surf.MAX_SUPPLY()
            uint256 surfTotalSupply = surf.totalSupply();
            if (surfTotalSupply.add(surfReward) >= surf.MAX_SUPPLY()) {
                surfReward = surf.MAX_SUPPLY().sub(surfTotalSupply);
            }

            accSurfPerShare = accSurfPerShare.add(surfReward.mul(1e12).div(lpSupply));
        }

        return user.staked.mul(accSurfPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Get the pending UNIs for a user from 1 pool
    function _pendingUni(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accUniPerShare = pool.accUniPerShare;
        uint256 lpSupply = _getPoolSupply(_pid);

        if (pool.uniStakeContract != address(0) && lpSupply != 0) {
            uint256 uniReward = IStakingRewards(pool.uniStakeContract).earned(address(this));
            accUniPerShare = accUniPerShare.add(uniReward.mul(1e12).div(lpSupply));
        }
        return user.staked.mul(accUniPerShare).div(1e12).sub(user.uniRewardDebt);
    }

    // Calculate the current surfReward for a specific pool
    function _calculateSurfReward(uint256 _pid, uint256 _lpSupply) internal view returns (uint256 surfReward) {
        
        if (surf.maxSupplyHit() != true) {

            PoolInfo memory pool = poolInfo[_pid];

            uint256 multiplier = block.number - pool.lastSurfRewardBlock;
                
            // There will be a 1000 block Soft Launch where SURF is minted at a static rate to make things as fair as possible
            if (block.number < startBlock + SOFT_LAUNCH_DURATION) {

                // The SURF-ETH pool isn't active until the Uniswap pool is created, which can't happen until at least 500 blocks have passed. Once active, it mints 1000 SURF per block (the same amount of SURF per block as all of the other pools combined) until the Soft Launch ends
                if (_pid != 0) {
                    // For the first 1000 blocks, give 40 SURF per block to all other pools that have staked LP tokens
                    surfReward = multiplier * SOFT_LAUNCH_SURF_PER_BLOCK;
                } else if (surfPoolActive == true) {
                    surfReward = multiplier * 25 * SOFT_LAUNCH_SURF_PER_BLOCK;
                }
            
            } else if (_pid != 0 && surfPoolActive != true) {
                // Keep minting 40 tokens per block since the Soft Launch is over but the SURF-ETH pool still isn't active (would only be due to no one calling the activateSurfPool function)
                surfReward = multiplier * SOFT_LAUNCH_SURF_PER_BLOCK;
            } else if (surfPoolActive == true) { 
                // Afterwards, give surfReward based on the pool's fixed APR.
                // Fast low gas cost way of calculating prices since this can be called every block.
                uint256 surfPrice = _getSurfPrice();
                uint256 lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / pool.lpToken.totalSupply(); 
                uint256 scaledTotalLiquidityValue = _lpSupply * lpTokenPrice;
                surfReward = multiplier * ((pool.apr * scaledTotalLiquidityValue / surfPrice) / APPROX_BLOCKS_PER_YEAR) / 100;
            }

        }

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Internal view function to get all of the stored data for a single pool
    function _getPoolData(uint256 _pid) internal view returns (address, address, bool, uint256, uint256, uint256, uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return (address(pool.token), address(pool.lpToken), pool.uniStakeContract != address(0), pool.apr, pool.lastSurfRewardBlock, pool.accSurfPerShare, pool.accUniPerShare);
    }

    // View function to see all of the stored data for every pool on the frontend
    function _getAllPoolData() internal view returns (address[] memory, address[] memory, bool[] memory, uint[] memory, uint[] memory, uint[2][] memory) {
        uint256 length = poolInfo.length;
        address[] memory tokenData = new address[](length);
        address[] memory lpTokenData = new address[](length);
        bool[] memory isUniData = new bool[](length);
        uint[] memory aprData = new uint[](length);
        uint[] memory lastSurfRewardBlockData = new uint[](length);
        uint[2][] memory accTokensPerShareData = new uint[2][](length);

        for (uint256 pid = 0; pid < length; ++pid) {
            (tokenData[pid], lpTokenData[pid], isUniData[pid], aprData[pid], lastSurfRewardBlockData[pid], accTokensPerShareData[pid][0], accTokensPerShareData[pid][1]) = _getPoolData(pid);
        }

        return (tokenData, lpTokenData, isUniData, aprData, lastSurfRewardBlockData, accTokensPerShareData);
    }

    // Internal view function to get all of the extra data for a single pool
    function _getPoolMetadataFor(uint256 _pid, address _user, uint256 _surfPrice) internal view returns (uint[17] memory poolMetadata) {
        PoolInfo memory pool = poolInfo[_pid];

        uint256 totalSupply;
        uint256 totalLPSupply;
        uint256 stakedLPSupply;
        uint256 tokenPrice;
        uint256 lpTokenPrice;
        uint256 totalLiquidityValue;
        uint256 surfPerBlock;

        if (_pid != 0 || surfPoolActive == true) {
            totalSupply = pool.token.totalSupply();
            totalLPSupply = pool.lpToken.totalSupply();
            stakedLPSupply = _getPoolSupply(_pid);

            tokenPrice = 10**uint256(pool.token.decimals()) * weth.balanceOf(address(pool.lpToken)) / pool.token.balanceOf(address(pool.lpToken));
            lpTokenPrice = 10**18 * 2 * weth.balanceOf(address(pool.lpToken)) / totalLPSupply; 
            totalLiquidityValue = stakedLPSupply * lpTokenPrice / 1e18;
        }

        // Only calculate with fixed apr after the Soft Launch
        if (block.number >= startBlock + SOFT_LAUNCH_DURATION) {
            surfPerBlock = ((pool.apr * 1e18 * totalLiquidityValue / _surfPrice) / APPROX_BLOCKS_PER_YEAR) / 100;
        } else {
            if (_pid != 0) {
                surfPerBlock = SOFT_LAUNCH_SURF_PER_BLOCK;
            } else if (surfPoolActive == true) {
                surfPerBlock = 25 * SOFT_LAUNCH_SURF_PER_BLOCK;
            }
        }

        // Global pool information
        poolMetadata[0] = totalSupply;
        poolMetadata[1] = totalLPSupply;
        poolMetadata[2] = stakedLPSupply;
        poolMetadata[3] = tokenPrice;
        poolMetadata[4] = lpTokenPrice;
        poolMetadata[5] = totalLiquidityValue;
        poolMetadata[6] = surfPerBlock;
        poolMetadata[7] = pool.token.decimals();

        // User pool information
        if (_pid != 0 || surfPoolActive == true) {
            UserInfo memory _userInfo = userInfo[_pid][_user];
            poolMetadata[8] = pool.token.balanceOf(_user);
            poolMetadata[9] = pool.token.allowance(_user, address(this));
            poolMetadata[10] = pool.lpToken.balanceOf(_user);
            poolMetadata[11] = pool.lpToken.allowance(_user, address(this));
            poolMetadata[12] = _userInfo.staked;
            poolMetadata[13] = _pendingSurf(_pid, _user);
            poolMetadata[14] = _pendingUni(_pid, _user);
            poolMetadata[15] = _userInfo.claimed;
            poolMetadata[16] = _userInfo.uniClaimed;
        }
    }

    // View function to see all of the extra pool data (token prices, total staked supply, total liquidity value, etc) on the frontend
    function _getAllPoolMetadataFor(address _user) internal view returns (uint[17][] memory allMetadata) {
        uint256 length = poolInfo.length;

        // Extra data for the frontend
        allMetadata = new uint[17][](length);

        // We'll need the current SURF price to make our calculations
        uint256 surfPrice = _getSurfPrice();

        for (uint256 pid = 0; pid < length; ++pid) {
            allMetadata[pid] = _getPoolMetadataFor(pid, _user, surfPrice);
        }
    }

    // View function to see all of the data for all pools on the frontend
    function getAllPoolInfoFor(address _user) external view returns (address[] memory tokens, address[] memory lpTokens, bool[] memory isUnis, uint[] memory aprs, uint[] memory lastSurfRewardBlocks, uint[2][] memory accTokensPerShares, uint[17][] memory metadatas) {
        (tokens, lpTokens, isUnis, aprs, lastSurfRewardBlocks, accTokensPerShares) = _getAllPoolData();
        metadatas = _getAllPoolMetadataFor(_user);
    }

    // Internal view function to get the current price of SURF on Uniswap
    function _getSurfPrice() internal view returns (uint256 surfPrice) {
        uint256 surfBalance = surf.balanceOf(surfPoolAddress);
        if (surfBalance > 0) {
            surfPrice = 10**18 * weth.balanceOf(surfPoolAddress) / surfBalance;
        }
    }

    // View function to show all relevant platform info on the frontend
    function getAllInfoFor(address _user) external view returns (bool poolActive, uint256[8] memory info) {
        poolActive = surfPoolActive;
        info[0] = blocksUntilLaunch();
        info[1] = blocksUntilSurfPoolCanBeActivated();
        info[2] = blocksUntilSoftLaunchEnds();
        info[3] = surf.totalSupply();
        info[4] = _getSurfPrice();
        if (surfPoolActive) {
            info[5] = IERC20(surfPoolAddress).balanceOf(address(surf));
        }
        info[6] = surfSentToWhirlpool;
        info[7] = surf.balanceOf(_user);
    }

    // View function to see the number of blocks remaining until launch on the frontend
    function blocksUntilLaunch() public view returns (uint256) {
        if (block.number >= startBlock) return 0;
        else return startBlock.sub(block.number);
    }

    // View function to see the number of blocks remaining until the SURF pool can be activated on the frontend
    function blocksUntilSurfPoolCanBeActivated() public view returns (uint256) {
        uint256 surfPoolActivationBlock = startBlock + SOFT_LAUNCH_DURATION.div(2);
        if (block.number >= surfPoolActivationBlock) return 0;
        else return surfPoolActivationBlock.sub(block.number);
    }

    // View function to see the number of blocks remaining until the Soft Launch ends on the frontend
    function blocksUntilSoftLaunchEnds() public view returns (uint256) {
        uint256 softLaunchEndBlock = startBlock + SOFT_LAUNCH_DURATION;
        if (block.number >= softLaunchEndBlock) return 0;
        else return softLaunchEndBlock.sub(block.number);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = (surfPoolActive == true ? 0 : 1); pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        require(msg.sender == tx.origin || msg.sender == owner() || contractWhitelist[msg.sender] == true, "no contracts"); // Prevent flash loan attacks that manipulate prices.
        
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = _getPoolSupply(_pid);

        // Handle the UNI staking rewards contract for the LP token if one exists.
        // The SURF-ETH pool would break by using the UNI staking rewards contract if one is made for it so it will be ignored
        if (_pid != 0) {
            // Check to see if the LP token has a UNI staking rewards contract to forward deposits to so that users can earn both SURF and UNI
            if (pool.uniStakeContract == address(0)) {
                (address uniStakeContract,) = uniStakingFactory.stakingRewardsInfoByStakingToken(address(pool.lpToken));

                // If a UNI staking rewards contract exists then transfer all of the LP tokens to it to start earning UNI
                if (uniStakeContract != address(0)) {
                    pool.uniStakeContract = uniStakeContract;

                    if (lpSupply > 0) {
                        pool.lpToken.safeApprove(uniStakeContract, 0);
                        pool.lpToken.safeApprove(uniStakeContract, lpSupply);
                        IStakingRewards(pool.uniStakeContract).stake(lpSupply);
                    }
                }
            }

            // A UNI staking rewards contract for this LP token is being used so get any pending UNI rewards
            if (pool.uniStakeContract != address(0)) {
                uint256 pendingUniTokens = IStakingRewards(pool.uniStakeContract).earned(address(this));
                if (pendingUniTokens > 0) {
                    uint256 uniBalanceBefore = uniToken.balanceOf(address(this));
                    IStakingRewards(pool.uniStakeContract).getReward();
                    uint256 uniBalanceAfter = uniToken.balanceOf(address(this));
                    pendingUniTokens = uniBalanceAfter.sub(uniBalanceBefore);
                    pool.accUniPerShare = pool.accUniPerShare.add(pendingUniTokens.mul(1e12).div(lpSupply));
                }
            }
        }

        // Only update the pool if the max SURF supply hasn't been hit
        if (surf.maxSupplyHit() != true) {
            
            if ((block.number <= pool.lastSurfRewardBlock) || (_pid == 0 && surfPoolActive != true)) {
                return;
            }
            if (lpSupply == 0) {
                pool.lastSurfRewardBlock = block.number;
                return;
            }

            uint256 surfReward = _calculateSurfReward(_pid, lpSupply);

            // Make sure that surfReward won't push the total supply of SURF past surf.MAX_SUPPLY()
            uint256 surfTotalSupply = surf.totalSupply();
            if (surfTotalSupply.add(surfReward) >= surf.MAX_SUPPLY()) {
                surfReward = surf.MAX_SUPPLY().sub(surfTotalSupply);
            }

            // surf.mint(devAddress, surfReward.div(10)); Not minting 10% to the devs like Sushi, Sashimi, and Takeout do

            if (surfReward > 0) {
                surf.mint(address(this), surfReward);
                pool.accSurfPerShare = pool.accSurfPerShare.add(surfReward.mul(1e12).div(lpSupply));
                pool.lastSurfRewardBlock = block.number;
            }

            if (surf.maxSupplyHit() == true) {
                whirlpool.activate();
            }
        }
    }

    // Internal view function to get the amount of LP tokens staked in the specified pool
    function _getPoolSupply(uint256 _pid) internal view returns (uint256 lpSupply) {
        PoolInfo memory pool = poolInfo[_pid];

        if (pool.uniStakeContract != address(0)) {
            lpSupply = IStakingRewards(pool.uniStakeContract).balanceOf(address(this));
        } else {
            lpSupply = pool.lpToken.balanceOf(address(this));
        }
    }

    // Deposits LP tokens in the specified pool to start earning the user SURF
    function deposit(uint256 _pid, uint256 _amount) external {
        depositFor(_pid, msg.sender, _amount);
    }

    // Deposits LP tokens in the specified pool on behalf of another user
    function depositFor(uint256 _pid, address _user, uint256 _amount) public {
        require(msg.sender == tx.origin || contractWhitelist[msg.sender] == true, "no contracts");
        require(surf.maxSupplyHit() != true, "pools closed");
        require(_pid != 0 || surfPoolActive == true, "surf pool not active");
        require(_amount > 0, "deposit something");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // The sender needs to give approval to the Tito contract for the specified amount of the LP token first
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Claim any pending SURF and UNI
        _claimRewardsFromPool(_pid, _user);
        
        // Each pool has a 10% staking fee. If staking in the SURF-ETH pool, 100% of the fee gets permanently locked in the SURF contract (gives SURF liquidity forever).
        // If staking in any other pool, 50% of the fee is used to buyback SURF which is sent to the Whirlpool staking contract where it will start getting distributed to stakers after the max supply is hit, and 50% goes to the team.
        // The team is never minted or rewarded SURF for any reason to keep things as fair as possible.
        uint256 stakingFeeAmount = _amount.div(10);
        uint256 remainingUserAmount = _amount.sub(stakingFeeAmount);

        // If a UNI staking rewards contract is available, use it
        if (pool.uniStakeContract != address(0)) {
            pool.lpToken.safeApprove(pool.uniStakeContract, 0);
            pool.lpToken.safeApprove(pool.uniStakeContract, remainingUserAmount);
            IStakingRewards(pool.uniStakeContract).stake(remainingUserAmount);
        }

        // The user is depositing to the SURF-ETH pool so permanently lock all of the LP tokens from the staking fee in the SURF contract
        if (_pid == 0) {
            pool.lpToken.transfer(address(surf), stakingFeeAmount);
        } else {
            uint256 ethBalanceBeforeSwap = address(this).balance;

            // Remove the liquidity from the pool
            uint256 deadline = block.timestamp + 5 minutes;
            pool.lpToken.safeApprove(address(uniswapRouter), 0);
            pool.lpToken.safeApprove(address(uniswapRouter), stakingFeeAmount);
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(pool.token), stakingFeeAmount, 0, 0, address(this), deadline);

            // Swap the ERC-20 token for ETH
            uint256 tokensToSwap = pool.token.balanceOf(address(this));
            require(tokensToSwap > 0, "bad token swap");
            address[] memory poolPath = new address[](2);
            poolPath[0] = address(pool.token);
            poolPath[1] = address(weth);
            pool.token.safeApprove(address(uniswapRouter), 0);
            pool.token.safeApprove(address(uniswapRouter), tokensToSwap);
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensToSwap, 0, poolPath, address(this), deadline);

            uint256 ethBalanceAfterSwap = address(this).balance;
            uint256 ethReceivedFromStakingFee;
            uint256 teamFeeAmount;

            // If surfPoolActive == true then perform a buyback of SURF using all of the ETH in the contract and then send it to the Whirlpool staking contract. Otherwise, the ETH will be used to seed the initial liquidity in the SURF-ETH Uniswap pool when activateSurfPool is called
            if (surfPoolActive == true) {
                require(ethBalanceAfterSwap > 0, "bad eth swap");

                teamFeeAmount = ethBalanceAfterSwap.div(2);
                ethReceivedFromStakingFee = ethBalanceAfterSwap.sub(teamFeeAmount);

                // The SURF-ETH pool is active, so let's use the ETH to buyback SURF and send it to the Whirlpool staking contract
                uint256 surfBought = _buySurf(ethReceivedFromStakingFee);

                // Send the SURF rewards to the Whirlpool staking contract
                surfSentToWhirlpool += surfBought;
                _safeSurfTransfer(address(whirlpool), surfBought);
            } else {
                ethReceivedFromStakingFee = ethBalanceAfterSwap.sub(ethBalanceBeforeSwap);
                require(ethReceivedFromStakingFee > 0, "bad eth swap");

                teamFeeAmount = ethReceivedFromStakingFee.div(2);
            }

            if (teamFeeAmount > 0) devAddress.transfer(teamFeeAmount);
        }

        // Add the remaining amount to the user's staked balance
        uint256 _currentRewardDebt = 0;
        uint256 _currentUniRewardDebt = 0;
        if (surfPoolActive != true) {
            _currentRewardDebt = user.staked.mul(pool.accSurfPerShare).div(1e12).sub(user.rewardDebt);
            _currentUniRewardDebt = user.staked.mul(pool.accUniPerShare).div(1e12).sub(user.uniRewardDebt);
        }
        user.staked = user.staked.add(remainingUserAmount);
        user.rewardDebt = user.staked.mul(pool.accSurfPerShare).div(1e12).sub(_currentRewardDebt);
        user.uniRewardDebt = user.staked.mul(pool.accUniPerShare).div(1e12).sub(_currentUniRewardDebt);

        emit Deposit(_user, _pid, _amount);
    }

    // Internal function that buys back SURF with the amount of ETH specified
    function _buySurf(uint256 _amount) internal returns (uint256 surfBought) {
        uint256 ethBalance = address(this).balance;
        if (_amount > ethBalance) _amount = ethBalance;
        if (_amount > 0) {
            uint256 deadline = block.timestamp + 5 minutes;
            address[] memory surfPath = new address[](2);
            surfPath[0] = address(weth);
            surfPath[1] = address(surf);
            uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: _amount}(0, surfPath, address(this), deadline);
            surfBought = amounts[1];
        }
        if (surfBought > 0) emit SurfBuyback(msg.sender, _amount, surfBought);
    }

    // Internal function to claim earned SURF and UNI from Tito. Claiming won't work until surfPoolActive == true
    function _claimRewardsFromPool(uint256 _pid, address _user) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (surfPoolActive != true || user.staked == 0) return;

        uint256 userUniPending = user.staked.mul(pool.accUniPerShare).div(1e12).sub(user.uniRewardDebt);
        uint256 uniBalance = uniToken.balanceOf(address(this));
        if (userUniPending > uniBalance) userUniPending = uniBalance;
        if (userUniPending > 0) {
            user.uniClaimed += userUniPending;
            uniToken.transfer(_user, userUniPending);
        }

        uint256 userSurfPending = user.staked.mul(pool.accSurfPerShare).div(1e12).sub(user.rewardDebt);
        if (userSurfPending > 0) {
            user.claimed += userSurfPending;
            _safeSurfTransfer(_user, userSurfPending);
        }

        if (userSurfPending > 0 || userUniPending > 0) {
            emit Claim(_user, _pid, userSurfPending, userUniPending);
        }
    }

    // Claim all earned SURF and UNI from a single pool. Claiming won't work until surfPoolActive == true
    function claim(uint256 _pid) public {
        require(surfPoolActive == true, "surf pool not active");
        updatePool(_pid);
        _claimRewardsFromPool(_pid, msg.sender);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo memory pool = poolInfo[_pid];
        user.rewardDebt = user.staked.mul(pool.accSurfPerShare).div(1e12);
        user.uniRewardDebt = user.staked.mul(pool.accUniPerShare).div(1e12);
    }

    // Claim all earned SURF and UNI from all pools. Claiming won't work until surfPoolActive == true
    function claimAll() public {
        require(surfPoolActive == true, "surf pool not active");

        uint256 totalPendingSurfAmount = 0;
        uint256 totalPendingUniAmount = 0;
        
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.staked > 0) {
                updatePool(pid);

                PoolInfo storage pool = poolInfo[pid];
                uint256 accSurfPerShare = pool.accSurfPerShare;
                uint256 accUniPerShare = pool.accUniPerShare;

                uint256 pendingPoolSurfRewards = user.staked.mul(accSurfPerShare).div(1e12).sub(user.rewardDebt);
                user.claimed += pendingPoolSurfRewards;
                totalPendingSurfAmount = totalPendingSurfAmount.add(pendingPoolSurfRewards);
                user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);

                uint256 pendingPoolUniRewards = user.staked.mul(accUniPerShare).div(1e12).sub(user.uniRewardDebt);
                user.uniClaimed += pendingPoolUniRewards;
                totalPendingUniAmount = totalPendingUniAmount.add(pendingPoolUniRewards);
                user.uniRewardDebt = user.staked.mul(accUniPerShare).div(1e12);
            }
        }

        require(totalPendingSurfAmount > 0 || totalPendingUniAmount > 0, "nothing to claim");

        uint256 uniBalance = uniToken.balanceOf(address(this));
        if (totalPendingUniAmount > uniBalance) totalPendingUniAmount = uniBalance;
        if (totalPendingUniAmount > 0) uniToken.transfer(msg.sender, totalPendingUniAmount);

        if (totalPendingSurfAmount > 0) _safeSurfTransfer(msg.sender, totalPendingSurfAmount);

        emit ClaimAll(msg.sender, totalPendingSurfAmount, totalPendingUniAmount);
    }

    // Withdraw LP tokens and earned SURF from Tito. Withdrawing won't work until surfPoolActive == true
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(surfPoolActive == true, "surf pool not active");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not good");
        
        updatePool(_pid);

        // Claim any pending SURF and UNI
        _claimRewardsFromPool(_pid, msg.sender);

        PoolInfo memory pool = poolInfo[_pid];

        // If a UNI staking rewards contract is in use, withdraw from it
        if (pool.uniStakeContract != address(0)) {
            IStakingRewards(pool.uniStakeContract).withdraw(_amount);
        }

        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.staked.mul(pool.accSurfPerShare).div(1e12);
        user.uniRewardDebt = user.staked.mul(pool.accUniPerShare).div(1e12);

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Convenience function to allow users to migrate all of their staked SURF-ETH LP tokens from Tito to the Whirlpool staking contract after the max supply is hit. Migrating won't work until whirlpool.active() == true
    function migrateSURFLPtoWhirlpool() public {
        require(whirlpool.active() == true, "whirlpool not active");
        UserInfo storage user = userInfo[0][msg.sender];
        uint256 amountToMigrate = user.staked;
        require(amountToMigrate > 0, "migrate: not good");
        
        updatePool(0);

        // Claim any pending SURF
        _claimRewardsFromPool(0, msg.sender);

        user.staked = 0;
        user.rewardDebt = 0;

        poolInfo[0].lpToken.safeApprove(address(whirlpool), 0);
        poolInfo[0].lpToken.safeApprove(address(whirlpool), amountToMigrate);
        whirlpool.stakeFor(msg.sender, amountToMigrate);
        emit Withdraw(msg.sender, 0, amountToMigrate);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 staked = user.staked;
        require(staked > 0, "no tokens");

        PoolInfo memory pool = poolInfo[_pid];

        // If a UNI staking rewards contract is in use, withdraw from it
        if (pool.uniStakeContract != address(0)) {
            IStakingRewards(pool.uniStakeContract).withdraw(staked);
        }
        
        user.staked = 0;
        user.rewardDebt = 0;
        user.uniRewardDebt = 0;

        pool.lpToken.safeTransfer(address(msg.sender), staked);
        emit EmergencyWithdraw(msg.sender, _pid, staked);
    }

    // Internal function to safely transfer SURF in case there is a rounding error
    function _safeSurfTransfer(address _to, uint256 _amount) internal {
        uint256 surfBalance = surf.balanceOf(address(this));
        if (_amount > surfBalance) _amount = surfBalance;
        surf.transfer(_to, _amount);
    }

    // Creates the SURF-ETH Uniswap pool and adds the initial liqudity that will be permanently locked. Can be called by anyone, but no sooner than 500 blocks after launch. 
    function activateSurfPool() public {
        require(surfPoolActive == false, "already active");
        require(block.number > startBlock + SOFT_LAUNCH_DURATION.div(2), "too soon");
        uint256 initialEthLiquidity = address(this).balance;
        require(initialEthLiquidity > 0, "need ETH");

        massUpdatePools();

        // The ETH raised from the staking fees collected before surfPoolActive == true is used to seed the ETH side of the SURF-ETH Uniswap pool.
        // This means that the higher the staking volume during the first 500 blocks, the higher the initial price of SURF
        if (donatedETH > 0 && donatedETH < initialEthLiquidity) initialEthLiquidity = initialEthLiquidity.sub(donatedETH);

        // Mint 1,000,000 new SURF to seed the SURF liquidity in the SURF-ETH Uniswap pool
        uint256 initialSurfLiquidity = 1000000 * 10**18;
        surf.mint(address(this), initialSurfLiquidity);

        // Add the liquidity to the SURF-ETH Uniswap pool
        surf.approve(address(uniswapRouter), initialSurfLiquidity);
        ( , , uint256 lpTokensReceived) = uniswapRouter.addLiquidityETH{value: initialEthLiquidity}(address(surf), initialSurfLiquidity, 0, 0, address(this), block.timestamp + 5 minutes);

        // Activate the SURF-ETH pool
        initialSurfPoolETH = initialEthLiquidity;
        surfPoolActive = true;

        // Permanently lock the LP tokens in the SURF contract
        IERC20(surfPoolAddress).transfer(address(surf), lpTokensReceived);

        // Buy SURF with all of the donatedETH from partner projects. This SURF will be sent to the Whirlpool staking contract and will start getting distributed to all stakers when the max supply is hit
        uint256 donatedAmount = donatedETH;
        uint256 ethBalance = address(this).balance;
        if (donatedAmount > ethBalance) donatedAmount = ethBalance;
        if (donatedAmount > 0) {
            uint256 surfBought = _buySurf(donatedAmount);

            // Send the SURF rewards to the Whirlpool staking contract
            surfSentToWhirlpool += surfBought;
            _safeSurfTransfer(address(whirlpool), surfBought);
            donatedETH = 0;
        }

        emit SurfPoolActive(msg.sender, initialSurfLiquidity, initialEthLiquidity);
    }

    // For use by partner teams that are donating to the SURF community. The funds will be used to purchase SURF tokens which will be distributed to stakers once the max supply is hit
    function donate(address _lpToken) public payable {
        require(msg.value >= minimumDonationAmount);
        require(donaters[_lpToken] == address(0));

        donatedETH = donatedETH.add(msg.value);
        donaters[_lpToken] = msg.sender;
        donations[_lpToken] = msg.value;
    }

    // For use by partner teams that donated to the SURF community. The funds can be removed if a beach wasn't created for the specified lp token (meaning the SURF team didn't hold up their end of the agreement)
    function removeDonation(address _lpToken) public {
        require(block.number < startBlock); // Donations can only be removed if the beach hasn't been added by the startBlock
        
        address returnAddress = donaters[_lpToken];
        require(msg.sender == returnAddress);
        
        uint256 donationAmount = donations[_lpToken];
        require(donationAmount > 0);
        
        uint256 ethBalance = address(this).balance;
        require(donationAmount <= ethBalance);

        // Only refund the donation if the beach wasn't created
        require(existingPools[_lpToken] != true);

        donatedETH = donatedETH.sub(donationAmount);
        donaters[_lpToken] = address(0);
        donations[_lpToken] = 0;

        msg.sender.transfer(donationAmount);
    }

    //////////////////////////
    // Governance Functions //
    //////////////////////////
    // The following functions can only be called by the owner (the SURF token holder governance contract)

    // Sets the address of the Whirlpool staking contract that bought SURF gets sent to for distribution to stakers once the max supply is hit
    function setWhirlpoolContract(Whirlpool _whirlpool) public onlyOwner {
        whirlpool = _whirlpool;
    }

    // Add a new LP Token pool
    function addPool(address _token, address _lpToken, uint256 _apr, bool _requireDonation) public onlyOwner {
        require(surf.maxSupplyHit() != true);
        require(existingPools[_lpToken] != true, "pool exists");
        require(_requireDonation != true || donations[_lpToken] >= minimumDonationAmount, "must donate");

        _addPool(_token, _lpToken);
        if (_apr != DEFAULT_APR) poolInfo[poolInfo.length-1].apr = _apr;
    }

    // Update the given pool's APR
    function setApr(uint256 _pid, uint256 _apr) public onlyOwner {
        require(surf.maxSupplyHit() != true);
        updatePool(_pid);
        poolInfo[_pid].apr = _apr;
    }

    // Add a contract to the whitelist so that it can interact with Tito. This is needed for the Aegis pool contract to be able to stake on behalf of everyone in the pool.
    // We want limited interaction from contracts due to the growing "flash loan" trend that can be used to dramatically manipulate a token's price in a single block.
    function addToWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = true;
    }

    // Remove a contract from the whitelist
    function removeFromWhitelist(address _contractAddress) public onlyOwner {
        contractWhitelist[_contractAddress] = false;
    }

}"},"UniStakingInterfaces.sol":{"content":"pragma solidity ^0.6.12;

interface StakingRewardsFactory {
    function stakingRewardsInfoByStakingToken(address) external view returns (address, uint256);
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}"},"Whirlpool.sol":{"content":"
/*
   _____ __  ______  ______     ___________   _____    _   ______________
  / ___// / / / __ \/ ____/    / ____/  _/ | / /   |  / | / / ____/ ____/
  \__ \/ / / / /_/ / /_       / /_   / //  |/ / /| | /  |/ / /   / __/   
 ___/ / /_/ / _, _/ __/  _   / __/ _/ // /|  / ___ |/ /|  / /___/ /___   
/____/\____/_/ |_/_/    (_) /_/   /___/_/ |_/_/  |_/_/ |_/\____/_____/  

Website: https://surf.finance
Created by Proof and sol_dev, with help from Zoma and Mr Fahrenheit
Audited by Aegis DAO and Sherlock Security

*/

pragma solidity ^0.6.12;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './IUniswapV2Router02.sol';
import './SURF.sol';
import './Tito.sol';

// The Whirlpool staking contract becomes active after the max supply it hit, and is where SURF-ETH LP token stakers will continue to receive dividends from other projects in the SURF ecosystem
contract Whirlpool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user
    struct UserInfo {
        uint256 staked; // How many SURF-ETH LP tokens the user has staked
        uint256 rewardDebt; // Reward debt. Works the same as in the Tito contract
        uint256 claimed; // Tracks the amount of SURF claimed by the user
    }

    // The SURF TOKEN!
    SURF public surf;
    // The Tito contract
    Tito public tito;
    // The SURF-ETH Uniswap LP token
    IERC20 public surfPool;
    // The Uniswap v2 Router
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // WETH
    IERC20 public weth;

    // Info of each user that stakes SURF-ETH LP tokens
    mapping (address => UserInfo) public userInfo;
    // The amount of SURF sent to this contract before it became active
    uint256 public initialSurfReward = 0;
    // 1% of the initialSurfReward will be rewarded to stakers per day for 100 days
    uint256 public initialSurfRewardPerDay;
    // How often the initial 1% payouts can be processed
    uint256 public constant INITIAL_PAYOUT_INTERVAL = 24 hours;
    // The unstaking fee that is used to increase locked liquidity and reward Whirlpool stakers (1 = 0.1%). Defaults to 10%
    uint256 public unstakingFee = 100;
    // The amount of SURF-ETH LP tokens kept by the unstaking fee that will be converted to SURF and distributed to stakers (1 = 0.1%). Defaults to 50%
    uint256 public unstakingFeeConvertToSurfAmount = 500;
    // When the first 1% payout can be processed (timestamp). It will be 24 hours after the Whirlpool contract is activated
    uint256 public startTime;
    // When the last 1% payout was processed (timestamp)
    uint256 public lastPayout;
    // The total amount of pending SURF available for stakers to claim
    uint256 public totalPendingSurf;
    // Accumulated SURFs per share, times 1e12.
    uint256 public accSurfPerShare;
    // The total amount of SURF-ETH LP tokens staked in the contract
    uint256 public totalStaked;
    // Becomes true once the 'activate' function called by the Tito contract when the max SURF supply is hit
    bool public active = false;

    event Stake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 surfAmount);
    event Withdraw(address indexed user, uint256 amount);
    event SurfRewardAdded(address indexed user, uint256 surfReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    constructor(SURF _surf, Tito _tito) public {
        tito = _tito;
        surf = _surf;
        surfPool = IERC20(tito.surfPoolAddress());
        weth = IERC20(uniswapRouter.WETH());
    }

    receive() external payable {
        emit EthRewardAdded(msg.sender, msg.value);
    }

    function activate() public {
        require(active != true, "already active");
        require(surf.maxSupplyHit() == true, "too soon");

        active = true;

        // Now that the Whirlpool staking contract is active, reward 1% of the initialSurfReward per day for 100 days
        startTime = block.timestamp + INITIAL_PAYOUT_INTERVAL; // The first payout can be processed 24 hours after activation
        lastPayout = startTime;
        initialSurfRewardPerDay = initialSurfReward.div(100);
    }

    // The _transfer function in the SURF contract calls this to let the Whirlpool contract know that it received the specified amount of SURF to be distributed to stakers 
    function addSurfReward(address _from, uint256 _amount) public {
        require(msg.sender == address(surf), "not surf contract");
        require(tito.surfPoolActive() == true, "no surf pool");
        require(_amount > 0, "no surf");

        if (active != true || totalStaked == 0) {
            initialSurfReward = initialSurfReward.add(_amount);
        } else {
            totalPendingSurf = totalPendingSurf.add(_amount);
            accSurfPerShare = accSurfPerShare.add(_amount.mul(1e12).div(totalStaked));
        }

        emit SurfRewardAdded(_from, _amount);
    }

    // Allows external sources to add ETH to the contract which is used to buy and then distribute SURF to stakers
    function addEthReward() public payable {
        require(tito.surfPoolActive() == true, "no surf pool");

        // We will purchase SURF with all of the ETH in the contract in case some was sent directly to the contract instead of using addEthReward
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "no eth");

        // Use the ETH to buyback SURF which will be distributed to stakers
        _buySurf(ethBalance);

        // The _transfer function in the SURF contract calls the Whirlpool contract's updateSurfReward function so we don't need to update the balances after buying the SURF
        emit EthRewardAdded(msg.sender, msg.value);
    }

    // Internal function to buy back SURF with the amount of ETH specified
    function _buySurf(uint256 _amount) internal {
        uint256 deadline = block.timestamp + 5 minutes;
        address[] memory surfPath = new address[](2);
        surfPath[0] = address(weth);
        surfPath[1] = address(surf);
        uniswapRouter.swapExactETHForTokens{value: _amount}(0, surfPath, address(this), deadline);
    }

    // Handles paying out the initialSurfReward over 100 days
    function _processInitialPayouts() internal {
        if (active != true || block.timestamp < startTime || initialSurfReward == 0 || totalStaked == 0) return;

        // How many days since last payout?
        uint256 daysSinceLastPayout = (block.timestamp - lastPayout) / INITIAL_PAYOUT_INTERVAL;

        // If less than 1, don't do anything
        if (daysSinceLastPayout == 0) return;

        // Work out how many payouts have been missed
        uint256 nextPayoutNumber = (block.timestamp - startTime) / INITIAL_PAYOUT_INTERVAL;
        uint256 previousPayoutNumber = nextPayoutNumber - daysSinceLastPayout;

        // Calculate how much additional reward we have to hand out
        uint256 surfReward = rewardAtPayout(nextPayoutNumber) - rewardAtPayout(previousPayoutNumber);
        if (surfReward > initialSurfReward) surfReward = initialSurfReward;
        initialSurfReward = initialSurfReward.sub(surfReward);

        // Payout the surfReward to the stakers
        totalPendingSurf = totalPendingSurf.add(surfReward);
        accSurfPerShare = accSurfPerShare.add(surfReward.mul(1e12).div(totalStaked));

        // Update lastPayout time
        lastPayout += (daysSinceLastPayout * INITIAL_PAYOUT_INTERVAL);
    }

    // Handles claiming the user's pending SURF rewards
    function _claimReward(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.staked > 0) {
            uint256 pendingSurfReward = user.staked.mul(accSurfPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingSurfReward > 0) {
                totalPendingSurf = totalPendingSurf.sub(pendingSurfReward);
                user.claimed += pendingSurfReward;
                _safeSurfTransfer(_user, pendingSurfReward);
                emit Claim(_user, pendingSurfReward);
            }
        }
    }

    // Stake SURF-ETH LP tokens to get rewarded with more SURF
    function stake(uint256 _amount) public {
        stakeFor(msg.sender, _amount);
    }

    // Stake SURF-ETH LP tokens on behalf of another address
    function stakeFor(address _user, uint256 _amount) public {
        require(active == true, "not active");
        require(_amount > 0, "stake something");

        _processInitialPayouts();

        // Claim any pending SURF
        _claimReward(_user);

        surfPool.safeTransferFrom(address(msg.sender), address(this), _amount);

        UserInfo storage user = userInfo[_user];
        totalStaked = totalStaked.add(_amount);
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
        emit Stake(_user, _amount);
    }

    // Claim earned SURF. Claiming won't work until active == true
    function claim() public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(user.staked > 0, "no stake");
        
        _processInitialPayouts();

        // Claim any pending SURF
        _claimReward(msg.sender);

        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
    }

    // Unstake and withdraw SURF-ETH LP tokens and any pending SURF rewards. There is a 10% unstaking fee, meaning the user will only receive 90% of their LP tokens back.
    // For the LP tokens kept by the unstaking fee, 50% will get locked forever in the SURF contract, and 50% will get converted to SURF and distributed to stakers.
    function withdraw(uint256 _amount) public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not good");
        
        _processInitialPayouts();

        uint256 unstakingFeeAmount = _amount.mul(unstakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(unstakingFeeAmount);

        // Half of the LP tokens kept by the unstaking fee will be locked forever in the SURF contract, the other half will be converted to SURF and distributed to stakers
        uint256 lpTokensToConvertToSurf = unstakingFeeAmount.mul(unstakingFeeConvertToSurfAmount).div(1000);
        uint256 lpTokensToLock = unstakingFeeAmount.sub(lpTokensToConvertToSurf);

        // Remove the liquidity from the Uniswap SURF-ETH pool and buy SURF with the ETH received
        // The _transfer function in the SURF.sol contract automatically calls whirlpool.addSurfReward() so we don't have to in this function
        if (lpTokensToConvertToSurf > 0) {
            surfPool.safeApprove(address(uniswapRouter), lpTokensToConvertToSurf);
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(surf), lpTokensToConvertToSurf, 0, 0, address(this), block.timestamp + 5 minutes);
            addEthReward();
        }

        // Permanently lock the LP tokens in the SURF contract
        if (lpTokensToLock > 0) surfPool.transfer(address(surf), lpTokensToLock);

        // Claim any pending SURF
        _claimReward(msg.sender);

        totalStaked = totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        surfPool.safeTransfer(address(msg.sender), remainingUserAmount);
        user.rewardDebt = user.staked.mul(accSurfPerShare).div(1e12);
        emit Withdraw(msg.sender, remainingUserAmount);
    }

    // Internal function to safely transfer SURF in case there is a rounding error
    function _safeSurfTransfer(address _to, uint256 _amount) internal {
        uint256 surfBal = surf.balanceOf(address(this));
        if (_amount > surfBal) {
            surf.transfer(_to, surfBal);
        } else {
            surf.transfer(_to, _amount);
        }
    }

    // Sets the unstaking fee. Can't be higher than 50%. _convertToSurfAmount is the % of the LP tokens from the unstaking fee that will be converted to SURF and distributed to stakers.
    // unstakingFee - unstakingFeeConvertToSurfAmount = The % of the LP tokens from the unstaking fee that will be permanently locked in the SURF contract
    function setUnstakingFee(uint256 _unstakingFee, uint256 _convertToSurfAmount) public onlyOwner {
        require(_unstakingFee <= 500, "over 50%");
        require(_convertToSurfAmount <= 1000, "bad amount");
        unstakingFee = _unstakingFee;
        unstakingFeeConvertToSurfAmount = _convertToSurfAmount;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // SURF and SURF-ETH LP tokens (the only 2 ERC2O's that should be in this contract) can't be withdrawn this way.
    function recoverERC20(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(surf) && _tokenAddress != address(surfPool));
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
    }

    function payoutNumber() public view returns (uint256) {
        if (block.timestamp < startTime) return 0;

        uint256 payout = (block.timestamp - startTime).div(INITIAL_PAYOUT_INTERVAL);
        if (payout > 100) return 100;
        else return payout;
    }

    function timeUntilNextPayout() public view returns (uint256) {
        if (initialSurfReward == 0) return 0;
        else {
            uint256 payout = payoutNumber();
            uint256 nextPayout = startTime.add((payout + 1).mul(INITIAL_PAYOUT_INTERVAL));
            return nextPayout - block.timestamp;
        }
    }

    function rewardAtPayout(uint256 _payoutNumber) public view returns (uint256) {
        if (_payoutNumber == 0) return 0;
        return initialSurfRewardPerDay * _payoutNumber;
    }

    function getAllInfoFor(address _user) external view returns (bool isActive, uint256[12] memory info) {
        isActive = active;
        info[0] = surf.balanceOf(address(this));
        info[1] = initialSurfReward;
        info[2] = totalPendingSurf;
        info[3] = startTime;
        info[4] = lastPayout;
        info[5] = totalStaked;
        info[6] = surf.balanceOf(_user);
        if (tito.surfPoolActive()) {
            info[7] = surfPool.balanceOf(_user);
            info[8] = surfPool.allowance(_user, address(this));
        }
        info[9] = userInfo[_user].staked;
        info[10] = userInfo[_user].staked.mul(accSurfPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
        info[11] = userInfo[_user].claimed;
    }

}"}}