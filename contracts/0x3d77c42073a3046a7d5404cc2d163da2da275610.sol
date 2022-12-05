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
"},"ECDSA.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n Ã· 2 + 1, and for v in (302): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
"},"GLVTSaleUpgradeableToken.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IMintableUpgradeable.sol";


/**
 * @dev Developed to facilitate the sales of GLVT NFT tokens.
 *
 * The contract components should be pretty straightforward, with the exception
 * of `authorizedMint`, which is the primary feature supporting any form of pre-public
 * sale of the NFTs. Essentially, an address will be designated as the `mintAuthority`
 * and will be used to sign authorisations for minting ahead of the public sales
 * period.
 */
contract GLVTSaleUpgradeableToken is Ownable, Pausable, ReentrancyGuard {
    IMintableUpgradeable internal _tokenContract;
    address public mintAuthority;
    uint256 public whitelistSaleTimestamp;
    uint256 public publicSaleTimestamp;
    uint256 public publicSalePrice;
    uint256 public totalMinted = 0;
    uint256 public totalSupply;
    bool public ended = false;
    uint256 public constant maxTokensPerMint = 3;

    /// @dev Tracking attributes for authorized minting
    mapping (bytes32 => uint256) internal _nonces;
    bytes32 internal _hashedContractName;
    bytes32 internal _hashedContractVersion;
    bytes32 internal constant _typeHash = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /**
     * @dev Typehash for generating authorized mint signatures
     *
     * The components of the typehash and their definitions is given as follows:
     * @custom:param to Address authorized to mint (i.e. the caller of the mint operation).
     * @custom:param quantity Total quantity that `to` is allowed to mint using this signature.
     * @custom:param timestamp Earliest timestamp minting is permitted.
     * @custom:param price Price-per-token in ETH.
     * @custom:param nonce Nonce word used to add uniqueness to the signature.
     * @custom:param type Mint type, emitted with the {Mint} event for downstream use.
     */
    bytes32 internal constant authorizedMintTypehash = keccak256(
        "AuthorizedMint(address to,uint256 quantity,uint256 timestamp,uint256 price,bytes32 nonce,uint256 type)"
    );

    /// @dev Event for downstream use
    event Mint(address to, uint256 mintType, uint256 tokenId);

    /**
     * Throws if the caller is not an externally owned address.
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Caller cannot be another contract");
        _;
    }

    /**
     * @param tokenContract GLVT token address.
     * @param mintAuthority_ Address of authorized mint authority.
     * @param whitelistSaleTimestamp_ Minimum timestamp for commencement of whitelist sales.
     * @param publicSaleTimestamp_ Minimum timestamp for commencement of public sale.
     * @param publicSalePrice_ Price for public sale minting in ETH.
     * @param totalSupply_ Total number of tokens up for sale.
     * @param contractName Contract name (used for authorized mint validation).
     * @param contractVersion Contract version (used for authorized mint validation).
     */
    constructor(
        address tokenContract,
        address mintAuthority_,
        uint256 whitelistSaleTimestamp_,
        uint256 publicSaleTimestamp_,
        uint256 publicSalePrice_,
        uint256 totalSupply_,
        string memory contractName,
        string memory contractVersion
    ) {
        _tokenContract = IMintableUpgradeable(tokenContract);
        mintAuthority = mintAuthority_;
        whitelistSaleTimestamp = whitelistSaleTimestamp_;
        publicSaleTimestamp = publicSaleTimestamp_;
        publicSalePrice = publicSalePrice_;
        totalSupply = totalSupply_;

        // setting up for authorized minting
        _hashedContractName = keccak256(bytes(contractName));
        _hashedContractVersion = keccak256(bytes(contractVersion));
    }

    /**
     * Authorized mint (i.e. non-public channel for minting).
     *
     * @param quantity Number of tokens to mint.
     * @param mintableQuantity Total number of tokens mintable with this authorization.
     * @param mintTimestamp Minimum timestamp for minting with this authorization.
     * @param mintPrice Authorized per-token price in ETH.
     * @param nonceWord Unique authorization qualifier.
     * @param mintType Mint type (used to emit {Mint} event for downstream use).
     * @param signature Authorization signature.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Mint `quantity` must not exceed `mintableQuantity`.
     * - Block timestamp must be equal or greater than `mintTimestamp`.
     * - Total number of tokens minted (including the current attempt) for the specified
     *   `nonceWord` must not exceed `mintableQuantity`.
     * - Amount of ETH sent must be equal to or more than `quantity` * `mintPrice`.
     * - The number of tokens minted so far plus `quantity` must not exceed the total sale supply.
     */
    function authorizedMint(
        uint256 quantity,
        uint256 mintableQuantity,
        uint256 mintTimestamp,
        uint256 mintPrice,
        bytes32 nonceWord,
        uint256 mintType,
        bytes memory signature
    ) external payable virtual whenNotPaused nonReentrant returns (uint256) {
        require(quantity <= mintableQuantity, "GLVT: Exceeds authorized quantity.");
        require(block.timestamp >= mintTimestamp, "GLVT: Authorized mint timestamp not reached.");
        // writing ```_nonces[nonceWord] + quantity <= mintableQuantity``` may be more readable,
        // but we risk an overflow if the nonce has been invalidated (i.e. set to the max value)
        uint256 noncesUsed = _nonces[nonceWord];
        require(
            mintableQuantity > noncesUsed && mintableQuantity - noncesUsed >= quantity,
            "GLVT: Authorized mint quantity exceeded."
        );

        bytes32 structHash = keccak256(
            abi.encode(
                authorizedMintTypehash,
                msg.sender,
                mintableQuantity,
                mintTimestamp,
                mintPrice,
                nonceWord,
                mintType
            )
        );
        bytes32 domainSeparatorV4 = keccak256(
            abi.encode(
                _typeHash,
                _hashedContractName,
                _hashedContractVersion,
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparatorV4, structHash);
        _validateSignature(signature, digest, mintAuthority);

        _nonces[nonceWord] += quantity;
        return _mint(msg.sender, quantity, mintPrice, mintType);
    }

    /**
     * Flip the end state of the sale.
     *
     * If sale is ongoing, it will be set to ended. If sale has ended, it will
     * be set to ongoing.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function flipEndState() external virtual onlyOwner {
        ended = !ended;
    }

    /**
     * Invalidates the specified nonce, rendering it unusable for authorized minting.
     *
     * @param nonceWord Nonce to invalidate.
     */
    function invalidateAuthorizedMintNonce(bytes32 nonceWord) external virtual onlyOwner {
        _nonces[nonceWord] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    /**
     * Public sale.
     *
     * @param quantity Number of tokens to mint.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Public sale must have commenced.
     * - Amount of ETH sent must be equal to or more than `quantity` * public sale price.
     * - The number of tokens minted so far plus `quantity` must not exceed the total sale supply.
     * - Value for `quantity` must not exceed `maxTokensPerMint`.
     */
    function mint(uint256 quantity) external payable virtual whenNotPaused nonReentrant onlyEOA returns (uint256) {
        require(isPublicSale(), "GLVT: Public sale has not begun.");
        require(quantity > 0, "GLVT: Quantity must be greater than zero.");
        require(quantity <= maxTokensPerMint, "GLVT: Exceeds max tokens per mint");
        // type 2 for public sale
        return _mint(msg.sender, quantity, publicSalePrice, 2);
    }

    /**
     * Pause the contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * Set the address of the authorized mint authority.
     *
     * @param authority Address of the new authority.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setMintAuthority(address authority) external onlyOwner {
        require(authority != address(0), "GLVT: Mint authority cannot be zero address.");
        mintAuthority = authority;
    }

    /**
     * Set the public sale price.
     *
     * @param price Public sale price in ETH.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setPublicSalePrice(uint256 price) external virtual onlyOwner {
        publicSalePrice = price;
    }

    /**
     * Set the timestamp for commencement of public sale.
     *
     * @param timestamp Timestamp for commencement of public sale.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setPublicSaleTimestamp(uint256 timestamp) external virtual onlyOwner {
        publicSaleTimestamp = timestamp;
    }

    /**
     * Set the timestamp for commencement of whitelist sale.
     *
     * @param timestamp Timestamp for commencement of whitelist sale.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setWhitelistSaleTimestamp(uint256 timestamp) external virtual onlyOwner {
        whitelistSaleTimestamp = timestamp;
    }

    /**
     * Pause the contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * Withdraw all available ETH held by this contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function withdraw() external virtual onlyOwner nonReentrant {
        // send and transfer both have a hard dependency of 2300 on gas costs, so
        // there's a risk of future failure
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "GLVT: Transfer failed.");
    }

    /**
     * Returns the number of tokens an authorized mint nonce has been used for.
     *
     * @return uses Quantity of tokens nonce has been used for.
     */
    function nonceUses(bytes32 nonceWord) external view virtual returns (uint256) {
        return _nonces[nonceWord];
    }

    /**
     * Returns the address of the NFT smart contract.
     *
     * @return tokenContractAddress Address of the NFT smart contract.
     */
    function tokenContractAddress() external view virtual returns (address) {
        return address(_tokenContract);
    }

    /**
     * Checks if public sale has commenced.
     *
     * @return commenced True if public sale has commenced.
     */
    function isPublicSale() public view virtual returns (bool) {
        return block.timestamp >= publicSaleTimestamp;
    }

    /**
     * Checks if whitelist sale has commenced.
     *
     * @return commenced True if whitelist sale has commenced.
     */
    function isWhitelistSale() public view virtual returns (bool) {
        return block.timestamp >= whitelistSaleTimestamp;
    }

    /**
     * Mint tokens by calling upon the GLVT token contract.
     *
     * Any excess ETH is refunded to the caller.
     *
     * @param to Recipient address.
     * @param quantity Number of tokens to mint.
     * @param price Per-token price in ETH.
     * @param mintType Mint type.
     *
     * Emits a {Mint} event.
     */
    function _mint(address to, uint256 quantity, uint256 price, uint256 mintType) internal virtual returns (uint256) {
        require(!ended, "GLVT: Sale ended");
        uint256 requiredEth = price * quantity;
        require(msg.value >= requiredEth, "GLVT: Insufficient ETH for minting.");
        require(totalMinted + quantity <= totalSupply, "GLVT: Total supply exceeded.");

        totalMinted += quantity;
        uint256 startTokenId = _tokenContract.safeMint(to, quantity);
        for (uint i = 0; i < quantity; i++) {
            emit Mint(to, mintType, startTokenId + i);
        }

        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }

        return startTokenId;
    }

    /**
     * Disassembles a signature into its (v, r, s) components.
     *
     * @param signature Signature.
     * @return (v, r, s) components of the signature.
     */
    function _disassembleSignature(bytes memory signature) internal view virtual returns (uint8, bytes32, bytes32) {
        require(signature.length == 65, "GLVT: Invalid signature length.");
        // taken from OpenZeppelin {ECDSA-tryRecover}
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return (v, r, s);
    }

    /**
     * @dev Validates a signature.
     *
     * Given a signature and the original message digest, this function disassembles
     * the signature and recovers the address of the original signatory. The address
     * of the original signatory is compared against the given signatory to ensure
     * its validity.
     *
     * @param signature Signature.
     * @param digest Message body.
     * @param signatory Expected address of signatory.
     */
    function _validateSignature(bytes memory signature, bytes32 digest, address signatory) internal view virtual {
        (uint8 v, bytes32 r, bytes32 s) = _disassembleSignature(signature);
        address recovered = ECDSA.recover(digest, v, r, s);
        require(recovered != address(0), "GLVT: Invalid signature.");
        require(recovered == signatory, "GLVT: Unauthorized.");
    }
}
"},"IMintableUpgradeable.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintableUpgradeable {
    function safeMint(address to, uint256 quantity) external returns (uint256);
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
"},"Pausable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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