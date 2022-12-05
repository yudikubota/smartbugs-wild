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
"},"Clones.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
"},"ERC165.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
"},"ERC721.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
"},"IERC165.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
"},"IERC2981.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
"},"IERC721.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
"},"IERC721Metadata.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
"},"IERC721Receiver.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
"},"ImmutablesArt.sol":{"content":"// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

/*
âââââââ   ââââââââ   âââââââ   ââââââââââââ ââââââ âââââââ âââ     ââââââââââââââââ    ââââââ âââââââ âââââââââ
ââââââââ ââââââââââ ââââââââ   âââââââââââââââââââââââââââââââ     ââââââââââââââââ   âââââââââââââââââââââââââ
ââââââââââââââââââââââââââââ   âââ   âââ   âââââââââââââââââââ     ââââââ  ââââââââ   ââââââââââââââââ   âââ
ââââââââââââââââââââââââââââ   âââ   âââ   âââââââââââââââââââ     ââââââ  ââââââââ   ââââââââââââââââ   âââ
ââââââ âââ ââââââ âââ ââââââââââââ   âââ   âââ  âââââââââââââââââââââââââââââââââââââââââ  ââââââ  âââ   âââ
ââââââ     ââââââ     âââ âââââââ    âââ   âââ  ââââââââââ ââââââââââââââââââââââââââââââ  ââââââ  âââ   âââ
*/

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./SafeERC20.sol";
import "./Clones.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./ImmutablesArtRoyaltyManager.sol";

/// @author Gutenblock.eth
/// @title ImmutablesAdmin
contract ImmutablesAdmin is Ownable, ReentrancyGuard {
  using Address for address payable;

  /// @dev Address of a third party curator.
  address public curator;
  /// @dev basis point (1/10,000th) share of third party curator on payout.
  uint16 public curatorPercent;

  /// @dev Address of a third party beneficiary.
  address public beneficiary;
  /// @dev basis point (1/10,000th) share of third party beneficiary on payout.
  uint16 public beneficiaryPercent;

  /// @dev Teammember administration mapping
  mapping(address => bool) public isTeammember;

  /// @dev MODIFIERS

  modifier onlyTeammember() {
      require(isTeammember[msg.sender], "team");
      _;
  }

  /// @dev EVENTS

  event AdminModifiedTeammembers(
    address indexed user,
    bool isTeammember
  );

  /** @dev Allows the contract owner to add a teammember.
    * @param _address of teammember to add.
    */
  function contractOwnerAddTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = true;
      emit AdminModifiedTeammembers(_address, true);
  }

  /** @dev Allows the contract owner to remove a teammember.
    * @param _address of teammember to remove.
    */
  function contractOwnerRemoveTeammember(address _address) external onlyOwner() {
      isTeammember[_address] = false;
      emit AdminModifiedTeammembers(_address, false);
  }

  /// @dev FINANCIAL

  /** @dev Allows the contract owner to set a curator address and percentage.
    * @dev Force payout of any curator that was previously set
    * @dev so that funds paid with a curator set are paid out as promised.
    * @param _newCurator address of a curator teammember.
    * @param _newPercent the basis point (1/10,000th) share of contract revenue for the curator.
    */
  function contractOwnerUpdateCuratorAddressAndPercent(address _newCurator, uint16 _newPercent) external onlyOwner() {
    require(_newPercent <= (10000-beneficiaryPercent));
    withdraw();
    isTeammember[curator] = false;
    emit AdminModifiedTeammembers(curator, false);
    isTeammember[_newCurator] = true;
    emit AdminModifiedTeammembers(_newCurator, true);
    curator = _newCurator;
    curatorPercent = _newPercent;
  }

  /** @dev Allows the contract owner to set a beneficiary address and percentage.
    * @dev Force payout of any beneficiary that was previously set
    * @dev so that funds paid with a beneficiary set are paid out as promised.
    * @param _newBeneficiary address of a beneficiary.
    * @param _newPercent the basis point (1/10,000th) share of contract revenue for the beneficiary.
    */
  function contractOwnerUpdateBeneficiaryAddressAndPercent(address _newBeneficiary, uint16 _newPercent) external onlyOwner() {
    require(_newPercent <= (10000-curatorPercent));
    withdraw();
    beneficiary = _newBeneficiary;
    beneficiaryPercent = _newPercent;
  }

  /** @dev Allows the withdraw of funds.
    * @dev Everyone is paid and the contract balance is zeroed out.
    */
  function withdraw() public nonReentrant() {
    // checks
    // effects
    uint256 _startingBalance = address(this).balance;
    uint256 _curatorValue = _startingBalance * curatorPercent / 10000;
    uint256 _beneficiaryValue = _startingBalance * beneficiaryPercent / 10000;
    uint256 _contractValue = _startingBalance - _curatorValue - _beneficiaryValue;

    // interactions
    payable(this.owner()).sendValue(_contractValue);
    payable(curator).sendValue(_curatorValue);
    payable(beneficiary).sendValue(_beneficiaryValue);
  }

  /** @dev Allows the withdraw of funds.
    * @dev Everyone is paid and the contract balance is zeroed out.
    */
  function withdrawERC20(IERC20 token) external nonReentrant() {
    // checks
    uint256 _startingBalance = token.balanceOf(address(this));
    require(_startingBalance > 0, "no tokens");

    // effects
    uint256 _curatorValue = _startingBalance * curatorPercent / 10000;
    uint256 _beneficiaryValue = _startingBalance * beneficiaryPercent / 10000;
    uint256 _contractValue = _startingBalance - _curatorValue - _beneficiaryValue;

    // interactions
    SafeERC20.safeTransfer(token, this.owner(), _contractValue);
    if(curator != address(0) && _curatorValue > 0) {
      SafeERC20.safeTransfer(token, curator, _curatorValue);
    }
    if(beneficiary != address(0) && _beneficiaryValue > 0) {
      SafeERC20.safeTransfer(token, beneficiary, _beneficiaryValue);
    }
  }
}

/// @author Gutenblock.eth
/// @title ImmutablesAdminProject
contract ImmutablesAdminProject is ImmutablesAdmin {
  /// @dev The fee paid to the contract to create a project.
  uint256 public projectFee;
  /// @dev The last projectId created.
  uint256 public currentProjectId;
  /// @dev Featured project.
  uint256 public featuredProjectId;

  /// @dev basis point (1/10,000th) share the artist receives of each sale.
  uint16 public artistPercent;
  /// @dev whether or not artists need to be pre-screened.
  bool public artistScreeningEnabled = false;

  /// @dev Template Cloneable Royalty Manager Contract
  ImmutablesArtRoyaltyManager public implementation;

  struct Project {
    // Name of the project and the corresponding Immutables.co page name.
    string name;
    // Name of the artist.
    string artist;
    // Project description.
    string description;

    // Current highest minted edition number.
    uint256 currentEditionId;
    // Maximum number of editions that can be minted.
    uint256 maxEditions;

    // The maximum number of editions to display at once in the grid view.
    // For works that are easier to generate many may be shown at once.
    // For more processor intensive works the artist may want to limit the
    // number on screen at any given time to reduce lag.
    uint8 maxGridDimension;

    // The Immutables.co Post transaction hash containing the generative art
    // script to run.
    string scriptTransactionHash;
    // The type of script that is referenced in the transaction hash.
    // Used to tell Grid what type of Cell to use for the script.
    string scriptType;

    // A category that can be assigned by a Teammember for curation.
    string category;

    // Whether the project is Active and available for third parties to view.
    bool active;
    // Whether the project minting is paused to the public.
    bool paused;
    // Whether or not the main project attributes are locked from editing.
    bool locked;
  }

  /// @dev Mappings between the page string and tokenId.
  mapping(uint256 => Project) public projects;

  /// @dev Mappings between the projectId, Price, and Artist Payees
  mapping(uint256 => address) public projectIdToArtistAddress;
  mapping(uint256 => uint256) public projectIdToPricePerEditionInWei;
  mapping(uint256 => address) public projectIdToAdditionalPayee;
  mapping(uint256 => uint16) public projectIdToAdditionalPayeePercent;

  /// @dev Allow for a per-project royalty address
  mapping(uint256 => address) public projectIdToRoyaltyAddress;

  /// @dev EIP2981 royaltyInfo basis point (1/10,000th) share of secondary
  ///      sales (for all projects).
  uint16 public secondaryRoyaltyPercent;

  /// @dev A mapping from a project to a base URL like a IPFS CAR file CID
  ///     (e.g., that can be obtained from from nft.storage)
  mapping(uint256 => string) public projectIdToImageURLBase;
  /// @dev The file extension for the individual items in the CAR file
  ///      (e.g., ".png")
  mapping(uint256 => string) public projectIdToImageURLExt;
  /// @dev Whether to use the Image URL in the Grid View instead of live render.
  mapping(uint256 => bool) public projectIdUseImageURLInGridView;

  /// @dev Mapping of artists authorized to use the platform
  ///      if artist screening is enabled.
  mapping(address => bool) public isAuthorizedArtist;

  /// @dev MODIFIERS

  modifier onlyUnlocked(uint256 _projectId) {
      require(!projects[_projectId].locked, "locked");
      _;
  }

  modifier onlyArtist(uint256 _projectId) {
    require(msg.sender == projectIdToArtistAddress[_projectId], "artist");
    _;
  }

  modifier onlyArtistOrTeammember(uint256 _projectId) {
      require(isTeammember[msg.sender] || msg.sender == projectIdToArtistAddress[_projectId], "artistTeam");
      _;
  }

  modifier onlyAuthorizedArtist() {
    if(artistScreeningEnabled) {
      require(isAuthorizedArtist[msg.sender], "auth");
    }
    _;
  }

  /// @dev EVENTS

  event AddressCreatedProject(
    address indexed artist,
    uint256 indexed projectId,
    string projectName
  );

  event AdminUpdatedAuthorizedArtist(
    address indexed user,
    bool isAuthorizedArtist
  );

  event AdminUpdatedProjectCategory(
      uint256 indexed projectId,
      string category
  );

  event CreatedImmutablesArtRoyaltyManagerForProjectId(
      address indexed royaltyManager,
      uint256 indexed projectId
  );

  /// @dev CONSTRUCTOR

  constructor() {
    implementation = new ImmutablesArtRoyaltyManager();
    implementation.initialize(address(this), 1, address(this), artistPercent, address(0), 0);
  }

  /** @dev Allows the teammember to add an artist.
    * @param _address of artist to add
    */
  function teamAddAuthorizedArtist(address _address) external onlyTeammember() {
      isAuthorizedArtist[_address] = true;
      emit AdminUpdatedAuthorizedArtist(_address, true);
  }

  /** @dev Allows the teammember to remove an artist.
    * @param _address of artist to remove
    */
  function teamRemoveAuthorizedArtist(address _address) external onlyTeammember() {
      isAuthorizedArtist[_address] = false;
      emit AdminUpdatedAuthorizedArtist(_address, false);
  }

  /** @dev Allows the teammember to set a featured project id
    * @param _projectId of featured project
    */
  function teamUpdateFeaturedProject(uint256 _projectId) external onlyTeammember() {
    require(_projectId <= currentProjectId);
    featuredProjectId = _projectId;
  }

  /** @dev Allows the contract owner to update the project fee.
    * @param _newProjectFee The new project fee in Wei.
    */
  function contractOwnerUpdateProjectFee(uint256 _newProjectFee) external onlyOwner() {
    projectFee = _newProjectFee;
  }

  /** @dev Allows the contract owner to update the artist cut of sales.
    * @param _percent The new artist percentage
    */
  function contractOwnerUpdateArtistPercent(uint16 _percent) external onlyOwner() {
    require(_percent >= 5000, ">=5000");   // minimum amount an artist should get 50.00%
    require(_percent <= 10000, "<=10000"); // maximum amount artists should get 100.00%
    artistPercent = _percent;
  }

  /** @dev Allows the contract owner to unlock a project.
    * @param _projectId of the project to unlock
    */
  function contractOwnerUnlockProject(uint256 _projectId) external onlyOwner() {
    projects[_projectId].locked = false;
  }

  /** @dev Allows the contract owner to set the royalty percent.
    * @param _newPercent royalty percent
    */
  function contractOwnerUpdateGlobalSecondaryRoyaltyPercent(uint16 _newPercent) external onlyOwner() {
    secondaryRoyaltyPercent = _newPercent;
  }

  /// @dev ANYONE - CREATING A PROJECT AND PROJECT ADMINISTRATION

  /** @dev Allows anyone to create a project _projectName, with _pricePerTokenInWei and _maxEditions.
    * @param _projectName A name of a project
    * @param _pricePerTokenInWei The price for each mint
    * @param _maxEditions The total number of editions for this project
    */
  function anyoneCreateProject(
    string calldata _projectName,
    string calldata _artistName,
    string calldata _description,
    uint256 _pricePerTokenInWei,
    uint256 _maxEditions,
    string calldata _scriptTransactionHash,
    string calldata _scriptType
  ) external payable onlyAuthorizedArtist() {
      require(msg.value >= projectFee, "project fee");
      require(bytes(_projectName).length > 0);
      require(bytes(_artistName).length > 0);
      require(_maxEditions > 0 && _maxEditions <= 1000000);

      currentProjectId++;
      uint256 _projectId = currentProjectId;
      projects[_projectId].name = _projectName;
      projects[_projectId].artist = _artistName;
      projects[_projectId].description = _description;

      projectIdToArtistAddress[_projectId] = msg.sender;
      projectIdToPricePerEditionInWei[_projectId] = _pricePerTokenInWei;
      projects[_projectId].currentEditionId = 0;
      projects[_projectId].maxEditions = _maxEditions;

      projects[_projectId].maxGridDimension = 10;

      projects[_projectId].scriptTransactionHash = _scriptTransactionHash;
      projects[_projectId].scriptType = _scriptType;

      projects[_projectId].active = false;
      projects[_projectId].paused = true;
      projects[_projectId].locked = false;

      setupImmutablesArtRoyaltyManagerForProjectId(_projectId);

      emit AddressCreatedProject(msg.sender, _projectId, _projectName);
  }

  /** @dev Clones a Royalty Manager Contract for a new Project ID
    * @param _projectId the projectId.
    */
  function setupImmutablesArtRoyaltyManagerForProjectId(uint256 _projectId) internal {
      // checks
      require(projectIdToRoyaltyAddress[_projectId] == address(0), "royalty manager already exists for _projectId");

      // effects
      address _newManager = Clones.clone(address(implementation));
      projectIdToRoyaltyAddress[_projectId] = address(_newManager);

      // interactions
      ImmutablesArtRoyaltyManager(payable(_newManager)).initialize(address(this), _projectId, projectIdToArtistAddress[_projectId], artistPercent, address(0), 0);
      emit CreatedImmutablesArtRoyaltyManagerForProjectId(address(_newManager), _projectId);
  }

  /** @dev Releases funds from a Royalty Manager for a Project Id
    * @param _projectId the projectId.
    */
  function releaseRoyaltiesForProject(uint256 _projectId) external {
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).release();
  }

  /// @dev ARTIST UPDATE FUNCTIONS

  /** @dev Allows the artist to update the artist's Eth address in the contract, and in the Royalty Manager.
    * @param _projectId the projectId.
    * @param _newArtistAddress the new Eth address for the artist.
    */
  function artistUpdateProjectArtistAddress(uint256 _projectId, address _newArtistAddress) external onlyArtist(_projectId) {
      projectIdToArtistAddress[_projectId] = _newArtistAddress;
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).artistUpdateAddress(_newArtistAddress);
  }

  /** @dev Allows the artist to update project additional payee info.
    * @param _projectId the projectId.
    * @param _additionalPayee the additional payee address.
    * @param _additionalPayeePercent the basis point (1/10,000th) share of project for the _additionalPayee up to artistPercent (e.g., 5000 = 50.0%).
    */
  function artistUpdateProjectAdditionalPayeeInfo(uint256 _projectId, address _additionalPayee, uint16 _additionalPayeePercent) external onlyArtist(_projectId)  {
      // effects
      projectIdToAdditionalPayee[_projectId] = _additionalPayee;
      projectIdToAdditionalPayeePercent[_projectId] = _additionalPayeePercent;

      // interactions
      ImmutablesArtRoyaltyManager(payable(projectIdToRoyaltyAddress[_projectId])).artistUpdateAdditionalPayeeInfo(_additionalPayee, _additionalPayeePercent);
  }

  // ARTIST OR TEAMMEMBER UPDATE FUNCTIONS

  /** @dev Allows the artist or team to update the price per token in wei for a project.
    * @param _projectId the projectId.
    * @param _pricePerTokenInWei new price per token for projectId
    */
  function artistTeamUpdateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external onlyArtistOrTeammember(_projectId) {
      projectIdToPricePerEditionInWei[_projectId] = _pricePerTokenInWei;
  }

  /** @dev Allows the artist or team to update the maximum number of editions
    * @dev to display at once in the grid view.
    * @param _projectId the projectId.
    * @param _maxGridDimension the maximum number of editions per side of Grid View Square.
    */
  function artistTeamUpdateProjectMaxGridDimension(uint256 _projectId, uint8 _maxGridDimension) external onlyArtistOrTeammember(_projectId) {
      require(_maxGridDimension > 0);
      require(_maxGridDimension <= 255);
      projects[_projectId].maxGridDimension = _maxGridDimension;
  }

  /** @dev Allows the artist or team to update the maximum number of editions
    * @dev that can be minted for a project.
    * @param _projectId the projectId.
    * @param _maxEditions the maximum number of editions for a project.
    */
  function artistTeamUpdateProjectMaxEditions(uint256 _projectId, uint256 _maxEditions) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      require(_maxEditions >= projects[_projectId].currentEditionId);
      require(_maxEditions <= 1000000);
      projects[_projectId].maxEditions = _maxEditions;
  }

  /** @dev Allows the artist or team to update the project name.
    * @param _projectId the projectId.
    * @param _projectName the new project name.
    */
  function artistTeamUpdateProjectName(uint256 _projectId, string memory _projectName) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].name = _projectName;
  }

  /** @dev Allows the artist or team to update the artist's name.
    * @param _projectId the projectId.
    * @param _artistName the new artist name.
    */
  function artistTeamUpdateArtistName(uint256 _projectId, string memory _artistName) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].artist = _artistName;
  }

  /** @dev Allows the artist or team update project description.
    * @param _projectId the projectId.
    * @param _description the description for the project.
    */
  function artistTeamUpdateProjectDescription(uint256 _projectId, string calldata _description) onlyUnlocked(_projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].description = _description;
  }

  /** @dev Allows the artist or team to update the project code transaction
    * @dev hash. The project code should be added to the referenced Immutables
    * @dev page as a Post starting with a line contaning three tick marks ```
    * @dev and ending with a line consisting of three tick marks ```.  The code
    * @dev will then be stored in a Post that has an Eth transaction hash.
    * @dev Add the transaction hash for the code Post to the project using this
    * @dev function. The code will then be pulled from this transaction hash
    * @dev for each render associated with this project.
    * @param _projectId the projectId.
    * @param _scriptTransactionHash the Ethereum transaction hash storing the code.
    */
  function artistTeamUpdateProjectScriptTransactionHash(uint256 _projectId, string memory _scriptTransactionHash) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
      projects[_projectId].scriptTransactionHash = _scriptTransactionHash;
  }

  /** @dev Allows the artist or team to update the project script type.
    * @dev The code contained in the transaction hash will be interpreted
    * @dev by the front end based on the script type.
    * @param _projectId the projectId.
    * @param _scriptType the script type (e.g., p5js)
    */
  function artistTeamUpdateProjectScriptType(uint256 _projectId, string memory _scriptType) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
         projects[_projectId].scriptType = _scriptType;
  }

  /** @dev Allows the artist or team toggle whether the project is paused.
    * @dev A paused project can only be minted by the artist or team.
    * @param _projectId the projectId.
    */
  function artistTeamToggleProjectIsPaused(uint256 _projectId) external onlyArtistOrTeammember(_projectId) {
      projects[_projectId].paused = !projects[_projectId].paused;
  }

  /** @dev Allows the artist or team to set an image URL and file extension.
    * @dev Once project editions are minted, an IPFS CAR file can be created.
    * @dev The CAR file can contain image files with filenames corresponding to
    * @dev the Immutables.art tokenIds for the project. The CAR file can be
    * @dev stored on IPFS, the conract updated with the _newImageURLBase and
    * @dev _newFileExtension and then token images can be found by going to:
    * @dev _newImageBase = ipfs://[cid for the car file]/
    * @dev _newImageURLExt = ".png"
    * @dev Resulting URL = ipfs://[cid for the car file]/[tokenId].png
    * @param _projectId the projectId.
    * @param _newImageURLBase the base for the image url (e.g., "ipfs://[cid]/" )
    * @param _newImageURLExt the file extension for the image file (e.g., ".png" , ".gif" , etc.).
    * @param _useImageURLInGridView bool whether to use the ImageURL in the Grid instead of a live render.
    */
  function artistTeamUpdateProjectImageURLInfo(uint256 _projectId,
                                      string calldata _newImageURLBase,
                                      string calldata _newImageURLExt,
                                      bool _useImageURLInGridView)
                                      external onlyArtistOrTeammember(_projectId) {
    projectIdToImageURLBase[_projectId] = _newImageURLBase;
    projectIdToImageURLExt[_projectId] = _newImageURLExt;
    projectIdUseImageURLInGridView[_projectId] = _useImageURLInGridView;
  }

  /** @dev Allows the artist or team to lock a project.
    * @dev Projects that are locked cannot have certain attributes modified.
    * @param _projectId the projectId.
    */
  function artistTeamLockProject(uint256 _projectId) external onlyUnlocked(_projectId) onlyArtistOrTeammember(_projectId) {
      projects[_projectId].locked = true;
  }

  // TEAMMEMBER ONLY UPDATE FUNCTIONS

  /** @dev Allows the team to set a category for a project.
    * @param _projectId the projectId.
    * @param _category string category name for the project.
    */
  function teamUpdateProjectCategory(uint256 _projectId, string calldata _category) external onlyTeammember() {
      projects[_projectId].category = _category;
      emit AdminUpdatedProjectCategory(_projectId, _category);
  }

  /** @dev Allows the team toggle whether the project is active.
    * @dev Only active projects are visible to the public.
    * @param _projectId the projectId.
    */
  function teamToggleProjectIsActive(uint256 _projectId) external onlyTeammember() {
      projects[_projectId].active = !projects[_projectId].active;
  }

  /** @dev Allows the team to toggle whether or not only approved artists are
    * @dev allowed to create projects.
    */
  function teamToggleArtistScreeningEnabled() external onlyTeammember() {
      artistScreeningEnabled = !artistScreeningEnabled;
  }
}

/// @author Gutenblock.eth
/// @title ImmutablesOptionalMetadataServer
contract ImmutablesOptionalMetadataServer is Ownable {
    /// @dev Stores the base web address for the Immutables web server.
    string public immutablesWEB;
    /// @dev Stores the base URI for the Immutables Metadata server.
    string public immutablesURI;
    /// @dev Whether to serve metadata from the server, or from the contract.
    bool public useMetadataServer;

    constructor () {
      immutablesWEB = "http://immutables.art/#/";
      immutablesURI = "http://nft.immutables.art/";
      useMetadataServer = false;
    }

    /** @dev Allows the contract owner to update the website URL.
      * @param _newImmutablesWEB The new website URL as a string.
      */
    function contractOwnerUpdateWebsite(string calldata _newImmutablesWEB) external onlyOwner() {
      immutablesWEB = _newImmutablesWEB;
    }

    /** @dev Allows the contract owner to update the metadata server URL.
      * @param _newImmutablesURI The new metadata server url as a string.
      */
    function contractOwnerUpdateAPIURL(string calldata _newImmutablesURI) external onlyOwner() {
      immutablesURI = _newImmutablesURI;
    }

    /** @dev Allows the contract owner to set the metadata source.
      * @param _shouldUseMetadataServer true or false
      */
    function contractOwnerUpdateUseMetadataServer(bool _shouldUseMetadataServer) external onlyOwner() {
      useMetadataServer = _shouldUseMetadataServer;
    }
}

/// @author Gutenblock.eth
/// @title ImmutablesArt
contract ImmutablesArt is ImmutablesAdminProject, ImmutablesOptionalMetadataServer, ERC721, IERC2981 {
    using Strings for uint256;
    using Address for address payable;

    /// @dev GLOBAL VARIABLES

    /// @dev The total suppliy of tokens (Editions of all Projects).
    uint256 public maxTotalSupply;
    /// @dev The last tokenId minted.
    uint256 public currentTokenId;

    /// @dev Mappings between the tokenId, projectId, editionIds, and Hashes
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256) public tokenIdToEditionId;
    mapping(uint256 => uint256[]) public projectIdToTokenIds;

    /// @dev MODIFIERS

    modifier onlyOwnerOfToken(uint256 _tokenId) {
      require(msg.sender == ownerOf(_tokenId), "must own");
      _;
    }

    modifier onlyArtistOrOwnerOfToken(uint256 _tokenId) {
      require(msg.sender == ownerOf(_tokenId) || msg.sender == projectIdToArtistAddress[tokenIdToProjectId[_tokenId]], "artistOwner");
      _;
    }

    /// @dev EVENTS

    event PaymentReceived(address from, uint256 amount);

    event AddressMintedProjectEditionAsToken(
      address indexed purchaser,
      uint256 indexed projectId,
      uint256 editionId,
      uint256 indexed tokenId
    );

    event TokenUpdatedWithMessage(
      address indexed user,
      uint256 indexed tokenId,
      string message
    );

    /// @dev CONTRACT CONSTRUCTOR

    constructor () ERC721("Immutables.art", "][art") ImmutablesOptionalMetadataServer() {
      projectFee = 0 ether;

      maxTotalSupply = ~uint256(0);
      currentTokenId = 0;

      currentProjectId = 0;

      artistScreeningEnabled = false;
      artistPercent = 9000; // 90.00%

      curator = address(0);
      curatorPercent = 0;

      beneficiary = address(0);
      beneficiaryPercent = 0;

      secondaryRoyaltyPercent = 1000; // 10.00%

      isTeammember[msg.sender] = true;

      emit AdminModifiedTeammembers(msg.sender, true);
    }

    /// @dev FINANCIAL

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @dev HELPER FUNCTIONS

    /** @dev Returns a list of tokenIds for a given projectId.
      * @param _projectId the projectId.
      * @return _tokenIds an array of tokenIds for the given project.
      */
    function getTokenIdsForProjectId(uint256 _projectId) external view returns (uint256[] memory _tokenIds) {
        return projectIdToTokenIds[_projectId];
    }

    /** @dev Used if a web2.0 style metadata server is required for more full
      * @dev featured legacy marketplace compatability.
      * @return _ the metadata server baseURI if a metadata server is used.
      */
    function _baseURI() internal view override returns (string memory) {
      return immutablesURI;
    }

    /** @dev Returns a string from a uint256
      * @param value uint256 data type string
      * @return _ string data type.
      */
    function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /** @dev Returns an image reference for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ an IPFS url to an image, or an SVG image if there is no IPFS image.
      */
    function getImageForTokenId(uint256 _tokenId) internal view returns (string memory) {
      string memory _base = projectIdToImageURLBase[tokenIdToProjectId[_tokenId]];
      string memory _ext = projectIdToImageURLExt[tokenIdToProjectId[_tokenId]];
      if(bytes(_base).length > 0 && bytes(_ext).length > 0) {
        return string(abi.encodePacked(_base,toString(_tokenId),_ext));
      } else {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(getSVGForTokenId(_tokenId)))));
      }
    }

    /** @dev Returns an SVG string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a SVG image string.
      */
    function getSVGForTokenId(uint256 _tokenId) public view returns (string memory) {
      string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .edition { fill: #ffffff; font-family: Open Sans; font-size: 12px; } .base { fill: #ffffff; font-family: Open Sans; font-size: 180px; } </style> <rect width="100%" height="100%" fill="#9400D3" /> <text class="edition" x="50%" y="5%" dominant-baseline="middle" text-anchor="middle">';
      output = string(abi.encodePacked(output, projects[tokenIdToProjectId[_tokenId]].name, ' # ', toString(tokenIdToEditionId[_tokenId])));
      output = string(abi.encodePacked(output,'</text><text class="edition" x="50%" y="10%" dominant-baseline="middle" text-anchor="middle">][art # ', toString(_tokenId)));
      output = string(abi.encodePacked(output,'</text><text class="base" x="50%" y = "50%" dominant-baseline="middle" text-anchor="middle">][</text></svg>'));
      return output;
    }

    /** @dev Returns a metadata attributes string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a metadata attributes string.
      */
    function getMetadataAttributesStringForTokenId(uint256 _tokenId) internal view returns (string memory) {
      uint256 _projectId = tokenIdToProjectId[_tokenId];
      string memory output = string(
        abi.encodePacked(
          '"attributes": [',
                '{"trait_type": "Project", "value": "', projects[_projectId].name,'"},',
                '{"trait_type": "Artist", "value": "', projects[_projectId].artist,'"},',
                '{"trait_type": "Category","value": "', projects[_projectId].category,'"}',
          ']'
        )
      );
      return output;
    }

    /** @dev Returns a metadata string for a tokenId.
      * @param _tokenId the tokenId.
      * @return _ a metadata string.
      */
    function getMetadataStringForTokenId(uint256 _tokenId) internal view returns (string memory) {
      uint256 _projectId = tokenIdToProjectId[_tokenId];
      string memory _url = string(abi.encodePacked(immutablesWEB, toString(_projectId), '/', toString(tokenIdToEditionId[_tokenId])));
      //string memory _collection = string(abi.encodePacked(projects[_projectId].name, " by ", projects[_projectId].artist));
      string memory output = string(
        abi.encodePacked(
          '{"name": "', projects[_projectId].name, ' # ', toString(tokenIdToEditionId[_tokenId]),
          '", "description": "', projects[_projectId].description,
          '", "external_url": "', _url,
          '", ', getMetadataAttributesStringForTokenId(_tokenId)
        )
      );
      return output;
    }

    /** @dev Returns a tokenURI URL or Metadata string depending on useMetadataServer
      * @param _tokenId the _tokenId.
      * @return _ String of a URI or Base64 encoded metadata and image string.
      */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      if(useMetadataServer) { // IF THE METADATA SERVER IS IN USE RETURN A URL
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
      } else { // ELSE WE ARE SERVERLESS AND RETURN METADATA DIRECTLY h/t DEAFBEEF FIRST NFT
        string memory json = Base64.encode(
          bytes(
            string(
              abi.encodePacked(
                getMetadataStringForTokenId(_tokenId),
                ', "image": "',
                getImageForTokenId(_tokenId),
                '"}'
              )
            )
          )
        );
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
      }
    }

    /// @dev royaltiesAddress - IERC2981

    /** @dev Returns the ERC2981 royaltyInfo.
      * @param _tokenId the _tokenId.
      * @param _salePrice the sales price to use for the royalty calculation.
      * @return receiver the recipient of the royalty payment.
      * @return royaltyAmount the calcualted royalty amount.
      */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
      require(_tokenId <= currentTokenId, "tokenId");
      return (projectIdToRoyaltyAddress[tokenIdToProjectId[_tokenId]], _salePrice * secondaryRoyaltyPercent / 10000);
    }

    /// @dev CONTRACT ADMINISTRATION

    /** @dev The artist or owner of a token can post a message associated with
      * @dev an edition of the project.
      * @param _tokenId the tokenId.
      * @param _message the message to add to the token.
      */
    function artistOwnerUpdateTokenWithMessage(uint256 _tokenId, string calldata _message) external onlyArtistOrOwnerOfToken(_tokenId) {
      require(bytes(_message).length > 0);
      emit TokenUpdatedWithMessage(msg.sender, _tokenId, _message);
    }

    /// @dev ANYONE - MINTING AN EDITION

    /** @dev Anyone can mint an edition of a project.
      * @param _projectId the projectId of the project to mint.
      */
    function anyoneMintProjectEdition(uint256 _projectId) external payable {
      // checks
      require(msg.value >= projectIdToPricePerEditionInWei[_projectId], "mint fee");
      require(projects[_projectId].currentEditionId < projects[_projectId].maxEditions, "sold out");
      // require project to be active or the artist or teammember to be trying to mint
      require(projects[_projectId].active || msg.sender == projectIdToArtistAddress[_projectId] || isTeammember[msg.sender], "not active");
      // require project to be unpaused or the artist or teammember to be trying to mint
      require(!projects[_projectId].paused || msg.sender == projectIdToArtistAddress[_projectId] || isTeammember[msg.sender], "paused");

      // effects
      uint256 _newTokenId = ++currentTokenId;
      uint256 _newEditionId = ++projects[_projectId].currentEditionId;

      tokenIdToProjectId[_newTokenId] = _projectId;
      tokenIdToEditionId[_newTokenId] = _newEditionId;
      projectIdToTokenIds[_projectId].push(_newTokenId);

      // interactions
      _mint(msg.sender, _newTokenId);
      //(bool success, ) = payable(projectIdToRoyaltyAddress[_projectId]).call{value:msg.value}("");
      //require(success, "Transfer to Royalty Manager contract failed.");
      payable(projectIdToRoyaltyAddress[_projectId]).sendValue(msg.value);

      emit AddressMintedProjectEditionAsToken(msg.sender, _projectId, _newEditionId, _newTokenId);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
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
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
"}}