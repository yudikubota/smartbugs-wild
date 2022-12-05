{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
"},"ImmutablesArtRoyaltyManager.sol":{"content":"// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

/*
$$$$$$\ $$\      $$\ $$\      $$\ $$\   $$\ $$$$$$$$\  $$$$$$\  $$$$$$$\  $$\       $$$$$$$$\  $$$$$$\       $$$$$$\  $$$$$$$\ $$$$$$$$\
\_$$  _|$$$\    $$$ |$$$\    $$$ |$$ |  $$ |\__$$  __|$$  __$$\ $$  __$$\ $$ |      $$  _____|$$  __$$\     $$  __$$\ $$  __$$\\__$$  __|
  $$ |  $$$$\  $$$$ |$$$$\  $$$$ |$$ |  $$ |   $$ |   $$ /  $$ |$$ |  $$ |$$ |      $$ |      $$ /  \__|    $$ /  $$ |$$ |  $$ |  $$ |
  $$ |  $$\$$\$$ $$ |$$\$$\$$ $$ |$$ |  $$ |   $$ |   $$$$$$$$ |$$$$$$$\ |$$ |      $$$$$\    \$$$$$$\      $$$$$$$$ |$$$$$$$  |  $$ |
  $$ |  $$ \$$$  $$ |$$ \$$$  $$ |$$ |  $$ |   $$ |   $$  __$$ |$$  __$$\ $$ |      $$  __|    \____$$\     $$  __$$ |$$  __$$<   $$ |
  $$ |  $$ |\$  /$$ |$$ |\$  /$$ |$$ |  $$ |   $$ |   $$ |  $$ |$$ |  $$ |$$ |      $$ |      $$\   $$ |    $$ |  $$ |$$ |  $$ |  $$ |
$$$$$$\ $$ | \_/ $$ |$$ | \_/ $$ |\$$$$$$  |   $$ |   $$ |  $$ |$$$$$$$  |$$$$$$$$\ $$$$$$$$\ \$$$$$$  |$$\ $$ |  $$ |$$ |  $$ |  $$ |
\______|\__|     \__|\__|     \__| \______/    \__|   \__|  \__|\_______/ \________|\________| \______/ \__|\__|  \__|\__|  \__|  \__|
$$$$$$$\   $$$$$$\ $$\     $$\  $$$$$$\  $$\    $$$$$$$$\ $$\     $$\
$$  __$$\ $$  __$$\\$$\   $$  |$$  __$$\ $$ |   \__$$  __|\$$\   $$  |
$$ |  $$ |$$ /  $$ |\$$\ $$  / $$ /  $$ |$$ |      $$ |    \$$\ $$  /
$$$$$$$  |$$ |  $$ | \$$$$  /  $$$$$$$$ |$$ |      $$ |     \$$$$  /
$$  __$$< $$ |  $$ |  \$$  /   $$  __$$ |$$ |      $$ |      \$$  /
$$ |  $$ |$$ |  $$ |   $$ |    $$ |  $$ |$$ |      $$ |       $$ |
$$ |  $$ | $$$$$$  |   $$ |    $$ |  $$ |$$$$$$$$\ $$ |       $$ |
\__|  \__| \______/    \__|    \__|  \__|\________|\__|       \__|
$$\      $$\  $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$\
$$$\    $$$ |$$  __$$\ $$$\  $$ |$$  __$$\ $$  __$$\ $$  _____|$$  __$$\
$$$$\  $$$$ |$$ /  $$ |$$$$\ $$ |$$ /  $$ |$$ /  \__|$$ |      $$ |  $$ |
$$\$$\$$ $$ |$$$$$$$$ |$$ $$\$$ |$$$$$$$$ |$$ |$$$$\ $$$$$\    $$$$$$$  |
$$ \$$$  $$ |$$  __$$ |$$ \$$$$ |$$  __$$ |$$ |\_$$ |$$  __|   $$  __$$<
$$ |\$  /$$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |
$$ | \_/ $$ |$$ |  $$ |$$ | \$$ |$$ |  $$ |\$$$$$$  |$$$$$$$$\ $$ |  $$ |
\__|     \__|\__|  \__|\__|  \__|\__|  \__| \______/ \________|\__|  \__|
*/

pragma solidity ^0.8.0;

/**
 * @author Gutenblock.eth
 * @title ImmutablesArtRoyaltyManager
 * @dev This contract allows to split Ether royalty payments between the
 * Immutables.art contract and an Immutables.art project artist.
 *
 * `ImmutablesArtRoyaltyManager` follows a _pull payment_ model. This means that payments
 * are not automatically forwarded to the accounts but kept in this contract,
 * and the actual transfer is triggered as a separate step by calling the
 * {release} function.
 *
 * The contract is written to serve as an implementation for minimal proxy clones.
 */

import "./Context.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

contract ImmutablesArtRoyaltyManager is Context, Initializable, ReentrancyGuard {
    using Address for address payable;

    /// @dev The address of the ImmutablesArt contract.
    address public immutablesArtContract;
    /// @dev The projectId of the associated ImmutablesArt project.
    uint256 public immutablesArtProjectId;

    /// @dev The address of the artist.
    address public artist;
    /// @dev The address of the additionalPayee set by the artist.
    address public additionalPayee;
    /// @dev The artist's percentage of the total expressed in basis points
    ///      (1/10,000ths).  The artist can allot up to all of this to
    ///      an additionalPayee.
    uint16 public artistPercent;
    /// @dev The artist's percentage, after additional payee,
    ///      of the total expressed as basis points (1/10,000ths).
    uint16 public artistPercentMinusAdditionalPayeePercent;
    /// @dev The artist's additional payee percentae of the total
    /// @dev expressed in basis points (1/10,000ths).  Valid from 0 to artistPercent.
    uint16 public additionalPayeePercent;

    /// EVENTS

    event PayeeAdded(address indexed account, uint256 percent);
    event PayeeRemoved(address indexed account, uint256 percent);
    event PaymentReleased(address indexed to, uint256 amount);
    event PaymentReleasedERC20(IERC20 indexed token, address indexed to, uint256 amount);
    event PaymentReceived(address indexed from, uint256 amount);

    /**
     * @dev Creates an uninitialized instance of `ImmutablesArtRoyaltyManager`.
     */
    constructor() { }

    /**
     * @dev Initialized an instance of `ImmutablesArtRoyaltyManager`
     */
    function initialize(address _immutablesArtContract, uint256 _immutablesArtProjectId,
                        address _artist, uint16 _artistPercent,
                        address _additionalPayee, uint16 _additionalPayeePercent
                        ) public initializer() {
        immutablesArtContract = _immutablesArtContract;
        immutablesArtProjectId = _immutablesArtProjectId;

        artist = _artist;
        artistPercent = _artistPercent;
        additionalPayee = _additionalPayee;
        additionalPayeePercent = _additionalPayeePercent;
        artistPercentMinusAdditionalPayeePercent = _artistPercent - _additionalPayeePercent;

        emit PayeeAdded(immutablesArtContract, 10000 - artistPercent);
        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function artistUpdateAddress(address _newArtistAddress) public {
        // only the parent contract and the artist can call this function.
        // the parent contract only calls this function at the request of the artist.
        require(_msgSender() == immutablesArtContract || _msgSender() == artist, "auth");

        // update the artist address
        emit PayeeRemoved(artist, artistPercentMinusAdditionalPayeePercent);
        artist = _newArtistAddress;
        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
    }

    function artistUpdateAdditionalPayeeInfo(address _newAdditionalPayee, uint16 _newPercent) public {
        // only the parent contract and the artist can call this function.
        // the parent contract only calls this function at the request of the artist.
        require(_msgSender() == immutablesArtContract || _msgSender() == artist, "auth");

        // the maximum amount the artist can give to an additional payee is
        // the current artistPercent plus the current additionalPayeePercent.
        require(_newPercent <= artistPercent, "percent too big");

        // Before changing the additional payee information,
        // payout ETH to everyone as indicated when prior payments were made.
        // since we won't know what ERC20 token addresses if any are held,
        // by the contract, we cant force payout on additional payee change.
        release();

        // Change the additional payee and relevant percentages.
        emit PayeeRemoved(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeRemoved(additionalPayee, additionalPayeePercent);
        }

        additionalPayee = _newAdditionalPayee;
        additionalPayeePercent = _newPercent;
        artistPercentMinusAdditionalPayeePercent = artistPercent - _newPercent;

        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
    }

    /**
     * @dev Triggers payout of all ETH royalties.
     */
    function release() public virtual nonReentrant() {
        // checks
        uint256 _startingBalance = address(this).balance;

        // Since this is called when there is a payee change,
        // we do not want to use require and cause a revert
        // if there is no balance.
        if(_startingBalance > 0) {
            // effects
            uint256 _artistAmount = _startingBalance * artistPercentMinusAdditionalPayeePercent / 10000;
            uint256 _additionalPayeeAmount = _startingBalance * additionalPayeePercent / 10000;
            uint256 _contractAmount = _startingBalance - _artistAmount - _additionalPayeeAmount;

            // interactions
            payable(immutablesArtContract).sendValue(_contractAmount);
            emit PaymentReleased(immutablesArtContract, _contractAmount);
            if(artist != address(0) && _artistAmount > 0) {
              payable(artist).sendValue(_artistAmount);
              emit PaymentReleased(artist, _artistAmount);
            }
            if(additionalPayee != address(0) && _additionalPayeeAmount > 0) {
              payable(additionalPayee).sendValue(_additionalPayeeAmount);
              emit PaymentReleased(additionalPayee, _additionalPayeeAmount);
            }
        }
    }

    /**
     * @dev Triggers payout of all ERC20 royalties.
     */
    function releaseERC20(IERC20 token) public virtual nonReentrant() {
        // checks
        uint256 _startingBalance = token.balanceOf(address(this));
        require(_startingBalance > 0, "no tokens");

        // effects
        uint256 _artistAmount = _startingBalance * artistPercentMinusAdditionalPayeePercent / 10000;
        uint256 _additionalPayeeAmount = _startingBalance * additionalPayeePercent / 10000;
        uint256 _contractAmount = _startingBalance - _artistAmount - _additionalPayeeAmount;

        // interactions
        SafeERC20.safeTransfer(token, immutablesArtContract, _contractAmount);
        emit PaymentReleasedERC20(token, immutablesArtContract, _contractAmount);
        if(artist != address(0) && _artistAmount > 0) {
          SafeERC20.safeTransfer(token, artist, _artistAmount);
          emit PaymentReleasedERC20(token, artist, _artistAmount);
        }
        if(additionalPayee != address(0) && _additionalPayeeAmount > 0) {
          SafeERC20.safeTransfer(token, additionalPayee, _additionalPayeeAmount);
          emit PaymentReleasedERC20(token, additionalPayee, _additionalPayeeAmount);
        }
    }
}
"},"Initializable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
"},"SafeERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"}}