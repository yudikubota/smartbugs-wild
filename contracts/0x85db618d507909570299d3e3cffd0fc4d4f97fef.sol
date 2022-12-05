{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

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
}
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

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
"},"curve.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "./SafeERC20.sol";

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function claim_rewards() external;

    function claimable_tokens(address) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function withdraw(uint256) external;
}

interface ICurveFi {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 amount, int128 i) external view returns (uint256);
}

interface ICrvV3 is IERC20 {
    function minter() external view returns (address);
}

interface IMinter {
    function mint(address) external;
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

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
"},"Math.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
"},"SafeERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
"},"synthetix.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "./SafeERC20.sol";

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

interface ISynth is IERC20 {
    function transferAndSettle(address to, uint256 value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ISynthetix is IERC20 {
    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);
}

interface IExchanger {
    // Views
    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(
        address from,
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) external returns (uint256 amountReceived);
}

interface DelegateApprovals {
    function approveExchangeOnBehalf(address delegate) external;
}
"},"uniswap.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {}
"},"ZapYvecrvSwapSusd.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Math} from "./Math.sol";
import {Ownable} from "./Ownable.sol";
import {SafeERC20, SafeMath, IERC20, Address} from "./SafeERC20.sol";

import {ICurveFi} from "./curve.sol";
import {IUniswapV2Router02} from "./uniswap.sol";
import {ISynthetix, IExchanger, ISynth} from "./synthetix.sol";

interface IYVault is IERC20 {
    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 shares, address recipient) external;

    function pricePerShare() external view returns (uint256);
}

contract ZapYvecrvSusd is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    IYVault public yVault = IYVault(address(0x0e880118C29F095143dDA28e64d95333A9e75A47));
    ICurveFi public curveStableSwap = ICurveFi(address(0xc5424B857f758E906013F3555Dad202e4bdB4567)); // Curve ETH/sEth StableSwap pool contract
    IUniswapV2Router02 public swapRouter;
    // IAddressResolver public SynthetixResolver = IAddressResolver(address(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83)); // synthetix AddressResolver contract
    ISynthetix public synthetix = ISynthetix(address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)); // synthetix ProxyERC20
    IExchanger public synthetixExchanger = IExchanger(address(0x0bfDc04B38251394542586969E2356d0D731f7DE));

    IERC20 public want = IERC20(address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c)); // Curve.fi ETH/sEth (eCRV)
    IERC20 public weth = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ISynth public sEth = ISynth(address(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb)); // synthetix ProxysETH
    ISynth public sUsd = ISynth(address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51)); // synthetix ProxyERC20sUSD

    // uint256 public constant DEFAULT_SLIPPAGE = 50; // slippage allowance out of 10000: 5%
    bool private _noReentry = false;
    address[] public swapPathZapIn;
    address[] public swapPathZapOut;

    constructor() public Ownable() {
        swapRouter = IUniswapV2Router02(sushiswapRouter);

        swapPathZapIn = new address[](2);
        swapPathZapIn[0] = address(weth);
        swapPathZapIn[1] = address(sUsd);

        swapPathZapOut = new address[](2);
        swapPathZapOut[0] = address(sUsd);
        swapPathZapOut[1] = address(weth);

        // In approves
        // Route: ETH ->(swapRouter)-> sUsd ->(synthetix)-> sEth ->(curveStableSwap)-> eCRV/want ->(yVault)-> yveCRV
        sUsd.approve(address(synthetix), uint256(-1));
        sEth.approve(address(curveStableSwap), uint256(-1));
        want.safeApprove(address(yVault), uint256(-1));

        // Out approves
        // Route: yveCRV ->(yVault)-> eCRV/want ->(curveStableSwap)-> sEth ->(synthetix)-> sUsd ->(swapRouter)-> ETH
        want.safeApprove(address(curveStableSwap), uint256(-1));
        sEth.approve(address(synthetix), uint256(-1));
        sUsd.approve(address(swapRouter), uint256(-1));
    }

    // Accept ETH and zap in with no token swap
    receive() external payable {
        if (_noReentry) {
            return;
        }
        _zapIn(0);
    }

    //
    // Zap In
    //

    // Zap In - Step 1
    function estimateZapInWithSwap(uint256 ethAmount, uint256 percentSwapSeth) external view returns (uint256) {
        require(percentSwapSeth >= 0 && percentSwapSeth <= 100, "INVALID PERCENTAGE VALUE");

        uint256 estimatedSethAmount = 0;
        if (percentSwapSeth > 0) {
            uint256 swappingEthAmount = ethAmount.mul(percentSwapSeth).div(100);
            ethAmount = ethAmount.sub(swappingEthAmount);

            uint256[] memory amounts = swapRouter.getAmountsOut(swappingEthAmount, swapPathZapIn);
            uint256 estimatedSusdAmount = amounts[amounts.length - 1];
            (estimatedSethAmount, , ) = synthetixExchanger.getAmountsForExchange(estimatedSusdAmount, "sUSD", "sETH");
        }

        return curveStableSwap.calc_token_amount([ethAmount, estimatedSethAmount], true);
    }

    // Zap In - Step 2 (optional)
    // Requires user to run: DelegateApprovals.approveExchangeOnBehalf(<zap_contract_address>)
    // synthetix DelegateApprovals contract: 0x15fd6e554874B9e70F832Ed37f231Ac5E142362f
    function swapEthToSeth() external payable {
        uint256 swappingEthAmount = address(this).balance;
        swapRouter.swapExactETHForTokens{value: swappingEthAmount}(swappingEthAmount, swapPathZapIn, address(this), now);

        uint256 susdAmount = sUsd.balanceOf(address(this));
        sUsd.transfer(msg.sender, susdAmount);
        synthetix.exchangeOnBehalf(msg.sender, "sUSD", susdAmount, "sETH");
    }

    // Zap In - Step 3
    // Requires user to run: sEth.approve(<zap_contract_address>, <seth_amount>)
    // synthetix ProxysETH contract: 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    function zapIn(uint256 sethAmount) external payable {
        if (_noReentry) {
            return;
        }
        // if (slippageAllowance == 0) {
        //     slippageAllowance = DEFAULT_SLIPPAGE;
        // }
        _zapIn(sethAmount);
    }

    function _zapIn(uint256 sethAmount) internal {
        uint256 ethBalance = address(this).balance;
        sethAmount = Math.min(sethAmount, sEth.balanceOf(msg.sender));
        require(ethBalance > 0 || sethAmount > 0, "INSUFFICIENT FUNDS");

        if (sethAmount > 0) {
            // uint256 waitLeft = synthetixExchanger.maxSecsLeftInWaitingPeriod(msg.sender, "sEth")
            sEth.transferFromAndSettle(msg.sender, address(this), sethAmount);
        }
        curveStableSwap.add_liquidity{value: ethBalance}([ethBalance, sethAmount], 0);

        uint256 outAmount = want.balanceOf(address(this));
        // require(outAmount.mul(slippageAllowance.add(10000)).div(10000) >= ethBalance.add(sethBalance), "TOO MUCH SLIPPAGE");

        yVault.deposit(outAmount, msg.sender);
    }

    //
    // Zap Out
    //

    // Zap Out - Step 1
    function estimateZapOutWithSwap(uint256 yvTokenAmount, uint256 percentSwapSusd) external view returns (uint256) {
        require(percentSwapSusd >= 0 && percentSwapSusd <= 100, "INVALID PERCENTAGE VALUE");

        uint256 wantAmount = yvTokenAmount.mul(yVault.pricePerShare());

        uint256 estimatedSwappedEthAmount = 0;
        if (percentSwapSusd > 0) {
            uint256 swappingWantAmount = wantAmount.mul(percentSwapSusd).div(100);
            wantAmount = wantAmount.sub(swappingWantAmount);

            uint256 sethAmount = curveStableSwap.calc_withdraw_one_coin(swappingWantAmount, 1);
            (uint256 susdAmount, , ) = synthetixExchanger.getAmountsForExchange(sethAmount, "sETH", "sUSD");
            uint256[] memory amounts = swapRouter.getAmountsOut(susdAmount, swapPathZapOut);
            estimatedSwappedEthAmount = amounts[amounts.length - 1];
        }

        uint256 estimatedEthAmount = curveStableSwap.calc_withdraw_one_coin(wantAmount, 0);

        return estimatedEthAmount.add(estimatedSwappedEthAmount);
    }

    // Zap Out - Step 2
    // Requires user to run: DelegateApprovals.approveExchangeOnBehalf(<zap_contract_address>)
    // synthetix DelegateApprovals contract: 0x15fd6e554874B9e70F832Ed37f231Ac5E142362f
    function zapOut(uint256 yvTokenAmount, uint256 percentSwapSusd) external {
        require(percentSwapSusd >= 0 && percentSwapSusd <= 100, "INVALID PERCENTAGE VALUE");

        uint256 yvTokenBalance = Math.min(yvTokenAmount, yVault.balanceOf(msg.sender));
        require(yvTokenBalance > 0, "INSUFFICIENT FUNDS");

        yVault.withdraw(yvTokenBalance, address(this));
        uint256 wantBalance = want.balanceOf(address(this));

        _noReentry = true;
        curveStableSwap.remove_liquidity_one_coin(wantBalance.mul(percentSwapSusd).div(100), 0, 0);
        wantBalance = want.balanceOf(address(this));
        curveStableSwap.remove_liquidity_one_coin(wantBalance, 0, 0);
        _noReentry = false;

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            msg.sender.transfer(ethBalance);
        }

        uint256 sethBalance = sEth.balanceOf(address(this));
        if (sethBalance > 0) {
            sEth.transfer(msg.sender, sethBalance);
            synthetix.exchangeOnBehalf(msg.sender, "sETH", sethBalance, "sUSD");
        }

        uint256 leftover = yVault.balanceOf(address(this));
        if (leftover > 0) {
            yVault.transfer(msg.sender, leftover);
        }
    }

    // Zap Out - Step 3 (Optional)
    // Requires user to run: sUsd.approve(<zap_contract_address>, <susd_amount>)
    // synthetix ProxysETH contract: 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb
    function swapSusdToEth(uint256 susdAmount) external {
        uint256 susdBalance = Math.min(susdAmount, sUsd.balanceOf(msg.sender));
        require(susdBalance > 0, "INSUFFICIENT FUNDS");

        // uint256 waitLeft = synthetixExchanger.maxSecsLeftInWaitingPeriod(msg.sender, "sUsd");
        sUsd.transferFromAndSettle(msg.sender, address(this), susdBalance);
        susdBalance = sUsd.balanceOf(address(this));
        swapRouter.swapExactTokensForETH(susdBalance, 0, swapPathZapOut, address(this), now);

        uint256 ethBalance = address(this).balance;
        msg.sender.transfer(ethBalance);
    }

    //
    // Misc external functions
    //

    //There should never be any tokens in this contract
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            amount = Math.min(address(this).balance, amount);
            msg.sender.transfer(amount);
        } else {
            IERC20 want = IERC20(token);
            amount = Math.min(want.balanceOf(address(this)), amount);
            want.safeTransfer(msg.sender, amount);
        }
    }

    function updateVaultAddress(address _vault) external onlyOwner {
        yVault = IYVault(_vault);
        want.safeApprove(_vault, uint256(-1));
    }

    function setSwapRouter(
        bool isUniswap,
        address[] calldata _swapPathZapIn,
        address[] calldata _swapPathZapOut
    ) external onlyOwner {
        if (isUniswap) {
            swapRouter = IUniswapV2Router02(uniswapRouter);
        } else {
            swapRouter = IUniswapV2Router02(sushiswapRouter);
        }

        swapPathZapIn = _swapPathZapIn;
        swapPathZapIn = _swapPathZapOut;

        sUsd.approve(address(swapRouter), uint256(-1)); // For zap out
    }
}
"}}