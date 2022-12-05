{"BIBtransfer.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

// -----------    House Of First   -----------
// - Black is Beautiful -- Transfer Contract -

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

pragma solidity ^0.8.10;

contract BIBtransfer is Ownable, ReentrancyGuard {
    uint256 public price = 0.025 * (10 ** 18);
    uint256 public supply = 0; // nfts purchased
    uint256 public maxSupply = 200; // nfts available for purchase
    uint256 public nftsTransferred = 0;
    uint256 public maxMint = 20;
    uint256 public allowancePerAddress = 50;
    bool public salePaused = false;
    address public vaultAddress = 0xb2C7c59fB26932A673993a85D0FA66c6298f8F01;
    address public bibAddress = 0x9b0674fE9c91414378a5dFAFB3376775A65CDEba;
    address public constant WHITELIST_SIGNER = 0x8430e0B7be3315735C303b82E4471D59AC152Aa5; // MM signer

    mapping(address => uint256) public whitelistPurchases;
    mapping(address => uint256) public owedNfts;
    address[] internal _addressesToMonitor;
    uint256[] internal _mintedNftIds;

    function getMintedNftIds() external view returns (uint256[] memory) {
        return _mintedNftIds;
    }

    function getAddressesToMonitor() external view returns (address[] memory) {
        return _addressesToMonitor;
    }

    function getNftsTransferred() public view returns (uint256) {
        return nftsTransferred;
    }

    function needToTransfer() public view returns (bool) {
        return supply != nftsTransferred;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function totalAvailable() public view returns (uint256) {
        return maxSupply - supply;
    }

    function toggleSalePause(bool _salePaused) onlyOwner external {
       salePaused = _salePaused;
    }

    function setWhitelistPurchases(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner {
        require(quantity.length == recipient.length, "Invalid quantities and recipients (length mismatch)");
        for (uint256 i = 0; i < recipient.length; ++i) {
            whitelistPurchases[recipient[i]] = quantity[i];
        }
    }

    function setWhitelistPurchasesSimple(uint256 quantity, address[] calldata recipient) external onlyOwner {
        for (uint256 i = 0; i < recipient.length; ++i) {
            whitelistPurchases[recipient[i]] = quantity;
        }
    }

    function setMintedNftIds(uint256[] calldata nftIds) external onlyOwner {
        delete _mintedNftIds;
        for (uint256 i = 0; i < nftIds.length; ++i) {
            _mintedNftIds.push(nftIds[i]);
        }
    }

    function setPrice(uint256 _price) onlyOwner external {
        price = _price;
    }

    function setNftsTransferred(uint256 _transferred) onlyOwner external {
        nftsTransferred = _transferred;
    }

    function setSupply(uint256 _supply) onlyOwner external {
        supply = _supply;
    }

    function setMaxSupply(uint256 _maxSupply) onlyOwner external {
        maxSupply = _maxSupply;
    }

    function setMaxMint(uint256 _maxMint) onlyOwner external {
        maxMint = _maxMint;
    }

    function setAllowancePerAddress(uint256 _allowancePerAddress) onlyOwner external {
        allowancePerAddress = _allowancePerAddress;
    }

    function setVaultAddress(address _vaultAddress) onlyOwner external {
        vaultAddress = _vaultAddress;
    }
    
    function setbibAddress(address _bibAddress) onlyOwner external {
        bibAddress = _bibAddress;
    }

    function getNFTPrice() public view returns (uint256) {
        return price;
    }
    
    function getTokensAvailable() public view returns (uint256) {
        return totalAvailable();
    }

    function getWhitelistPurchases(address addr) external view returns (uint256) {
        return whitelistPurchases[addr];
    }

    function getOwedNfts(address addr) external view returns (uint256) {
        return owedNfts[addr];
    }

    /* whitelist */
    function isWhitelisted(address user, bytes memory signature) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(user));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, signature) == WHITELIST_SIGNER;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function whitelistMintNFT(uint256 numberOfNfts, bytes memory signature) public payable nonReentrant {
        require(!salePaused, "Sale Paused");
        require(msg.value >= price * numberOfNfts, "Not Enough ETH");
        require(isWhitelisted(msg.sender, signature), "Address not whitelisted");
        require(numberOfNfts > 0 && numberOfNfts <= allowancePerAddress, "Invalid numberOfNfts");
        require(supply + numberOfNfts <= maxSupply, "Exceeds max supply");
        require(whitelistPurchases[msg.sender] + numberOfNfts <= allowancePerAddress, "Exceeds Allocation");

        whitelistPurchases[msg.sender] += numberOfNfts;
        owedNfts[msg.sender] += numberOfNfts;
        _addressesToMonitor.push(msg.sender);
        supply += numberOfNfts;
    }

    function transferOwedNfts(address recipient, uint256[] calldata nftTokenIds) onlyOwner external returns (uint256) {
        uint256 transferCount = nftTokenIds.length;
        require(owedNfts[recipient] >= transferCount, "More nfts than owed");
        for (uint256 i = 0; i < transferCount; ++i) {
            IERC721(bibAddress).safeTransferFrom(vaultAddress, recipient, nftTokenIds[i]);
            _mintedNftIds.push(nftTokenIds[i]);
        }
        owedNfts[recipient] -= transferCount;
        nftsTransferred += transferCount;
        delete transferCount;
        return owedNfts[recipient];
    }

    // for transparency regarding ETH raised
    uint256 totalWithdrawn = 0;

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
}"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
"}}