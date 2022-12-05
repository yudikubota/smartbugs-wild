{"Context.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
"},"IERC165.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
"},"IERC721.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
"},"IERC721Enumerable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
"},"IImbuedNFT.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";

/** @title NFT contract for imbued works of art
    @author 0xsublime.eth
    @notice This contract is the persistent center of the Imbued Art project,
    and allows unstoppable ownership of the NFTs. The minting is controlled by a
    separate contract, which is upgradeable. This contract enforces a 700 token
    limit: 7 editions of 100 tokens.

    The dataContract is intended to serve as a store for metadata, animations,
    code, etc.

    The owner of a token can imbue it with meaning. The imbuement is a string,
    up to 32 bytes long. The history of a tokens owenrship and its imbuements
    are stored and are retrievable via view functions.

    Token transfers are initially turned off for all editions. Once a transfers
    are activated on an edition of tokens, it cannot be disallowed again.
 */
interface IImbuedNFT is IERC721Enumerable {

    /// @dev The contract controlling minting
    function mintContract() external view returns (address);
    /// @dev For storing metadata, animations, code.
    function dataContract() external view returns (address); 

    function NUM_EDITIONS() external pure returns (uint256);
    function EDITION_SIZE() external pure returns (uint256);

    /// Tokens are marked transferable at the edition level.
    function editionTransferable(uint256) external pure returns (bool);

    function baseURI() external pure returns (string memory);

    /// Maps a token to its history of owners.
    function id2provenance(uint256) external view returns (address[] memory);
    /// Maps a (token, owner) pair to its imbuement.
    function idAndOwner2imbuement(uint256, address) external view returns (string memory);

    event Imbued(uint256 indexed tokenId, address indexed owner, string imbuement);
    event EditionTransferable(uint256 indexed edition);

    // ===================================
    // Mint contract privileged functions.
    // ===================================

    /** @dev The mint function can only be called by the minter address.
        @param recipient The recipient of the minted token, needs to be an EAO or a contract which accepts ERC721s.
        @param tokenId The token ID to mint.
     */
    function mint(address recipient, uint256 tokenId) external;
    // ==============
    // NFT functions.
    // ==============

    /** Saves an imbuement for a token and owner.
        An imbuement is a string, up to 32 bytes (equivalent to 32 ASCII
        characters).  Once set, it is immuatble.  Only the owner, or an address
        which has permission to control the token, can imbue it.
        @param tokenId The token to imbue.
        @param imbuement The string that should be saved
     */
    function imbue(uint256 tokenId, string calldata imbuement) external;

    // ===============
    // View functions.
    // ===============

    /// Get the complete list of imbuements for a token.
    /// @param id ID of the token to get imbuements for
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return A string array, each string at most 32 bytes.
    function imbuements(uint256 id, uint256 start, uint256 end) external view returns (string[] memory);

    /// Get the chronological list of owners of a token.
    /// @param id The token ID to get the provenance for.
    /// @param start start of the range to return (inclusive)
    /// @param end end of the range to return (non-inclusive), or 0 for max length.
    /// @return An address array of all owners, listed chornologically.
    function provenance(uint256 id, uint256 start, uint256 end) external view returns (address[] memory);

    // =====================
    // Only owner functions.
    // =====================

    function setMintContract(address _mintContract) external;
    function setDataContract(address _dataContract) external;

    function setBaseURI(string memory newBaseURI) external;

    /// @dev Edition transfers can only be allowed, there is no way to disallow them later.
    function setEditionTransferable(uint256 edition) external;


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}
"},"ImbuedMinterV2.sol":{"content":"// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IImbuedNFT.sol";

/// Minter contract of Imbued Art tokens.
/// This contract allows any holder of an Imbued Art token (address
/// `0x000001e1b2b5f9825f4d50bd4906aff2f298af4e`) to mint one new Imbued NFT for
/// each they already own. The contract allows tokens of ID up to
/// `maxWhitelistId` to mint new tokens.
/// The price per token is `whitelistPrice`.
/// The owner of the minter account may mint tokens at no cost (they also are
/// priviliged to withdraw any funds deposited into the account, so this only
/// cuts out an extra transaction).
/// However, note that the Imbued Art contract restricts even the admin on what can be minted:
/// The highest tokenId that can ever be minted is 699, and an admin can't mint
/// a token with an id that already exists.
contract ImbuedMintV2 is Ownable {
    IImbuedNFT immutable public NFT;

    uint16 public maxWhiteListId = 99;
    uint16 public nextId = 101;
    uint16 public maxId = 199;
    uint256 public whitelistPrice = 0.05 ether;

    mapping (uint256 => bool) public tokenid2claimed; // token ids that are claimed.

    constructor(uint16 _maxWhiteListId, uint16 _startId, uint16 _maxId, uint256 _whitelistPrice, IImbuedNFT nft) {
        maxWhiteListId = _maxWhiteListId;
        nextId = _startId;
        maxId = _maxId;
        whitelistPrice = _whitelistPrice;
        NFT = nft;
    }

    /// Minting using whitelisted tokens.  You pass a list of token ids under
    /// your own, pay `whitelistPrice` * `tokenIds.length`, and receive
    /// `tokenIds.length` newly minted tokens.
    /// @param tokenIds a list of tokens
    function mint(uint16[] calldata tokenIds) external payable {
        uint8 amount = uint8(tokenIds.length);
        require(msg.value == amount * whitelistPrice, "wrong amount of ether sent");

        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                uint256 id = tokenIds[i];
                require(id <= maxWhiteListId, "not a whitelisted token id");
                require(!tokenid2claimed[id], "token already used for claim");
                address tokenOwner = NFT.ownerOf(id);
                require(msg.sender == tokenOwner , "sender is not token owner");
                tokenid2claimed[id] = true;
            }
        }
        _mint(msg.sender, amount);
    }

    // only owner

    /// (Admin only) Admin can mint without paying fee, because they are allowed to withdraw anyway.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param amount the number of tokens to mint, starting with id `nextId()`.
    function adminMintAmount(address recipient, uint8 amount) external payable onlyOwner() {
        _mint(recipient, amount);
    }

    /// (Admin only) Can mint *any* token ID. Intended foremost for minting
    /// major versions for the artworks.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param tokenId which id to mint, may not be a previously minted one.
    function adminMintSpecific(address recipient, uint256 tokenId) external payable onlyOwner() {
        NFT.mint(recipient, tokenId);
    }

    /// (Admin only) Set the highest token id which may be used for a whitelist mint.
    /// @param newMaxWhitelistId the new maximum token id that is whitelisted.
    function setMaxWhitelistId(uint16 newMaxWhitelistId) external payable onlyOwner() {
        maxWhiteListId = newMaxWhitelistId;
    }

    /// (Admin only) Set the next id that will be minted by whitelisters or
    /// `adminMintAmount`.  If this id has already been minted, all minting
    /// except `adminMintSpecific` will be impossible.
    /// @param newNextId the next id that will be minted.
    function setNextId(uint16 newNextId) external payable onlyOwner() {
        nextId = newNextId;
    }

    /// (Admin only) Set the maximum mintable ID (for whitelist minters).
    /// @param newMaxId the new maximum id that can be whitelist minted (inclusive).
    function setMaxId(uint16 newMaxId) external payable onlyOwner() {
        maxId = newMaxId;
    }
    
    /// (Admin only) Set the price per token for whitelisted minters
    /// @param newPrice the new price in wei.
    function setWhitelistPrice(uint256 newPrice) external payable onlyOwner() {
        whitelistPrice = newPrice;
    }

    /// (Admin only) Withdraw the entire contract balance to the recipient address.
    /// @param recipient where to send the ether balance.
    function withdrawAll(address payable recipient) external payable onlyOwner() {
        recipient.call{value: address(this).balance}("");
    }

    /// (Admin only) self-destruct the minting contract.
    /// @param recipient where to send the ether balance.
    function kill(address payable recipient) external payable onlyOwner() {
        selfdestruct(recipient);
    }

    // internal

    // Reentrancy protection: not needed. The only variable that has not yet
    // been updated is nextId.  If you try to mint again using re-entrancy, the
    // mint itself will fail.
    function _mint(address recipient, uint8 amount) internal {
        uint256 nextCache = nextId;
        unchecked {
            uint256 newNext = nextCache + amount;
            require(newNext - 1 <= maxId, "can't mint that many");
            for (uint256 i = 0; i < amount; i++) {
                require((nextCache + i) % 100 != 0, "minting a major token");
                NFT.mint(recipient, nextCache + i); // reentrancy danger. Handled by fact that same ID can't be minted twice.
            }
            nextId = uint16(newNext);
        }
    }
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
"}}