{{
  "language": "Solidity",
  "sources": {
    "/Users/marvinkruse/Git/misc/auditSign/contracts/auditSign.sol": {
      "content": "// SPDX-License-Identifier: MIT
//
//   _             _                           _          _          _
//  | |__   _   _ | |_  ___  _ __  ___    ___ | | __ ___ | |_     __| |  ___ __   __
//  | '_ \ | | | || __|/ _ \| '__|/ _ \  / __|| |/ // _ \| __|   / _` | / _ \\ \ / /
//  | |_) || |_| || |_|  __/| |  | (_) || (__ |   <|  __/| |_  _| (_| ||  __/ \ V /
//  |_.__/  \__, | \__|\___||_|   \___/  \___||_|\_\\___| \__|(_)\__,_| \___|  \_/
//          |___/
//
// AuditSign contracts are storing the signatures of audit reports, developed by
// byterocket.dev. The IPFS hash is stored on-chain and signed by both parties,
// the auditors (us) and the client. This way, third parties and users may
// verify for themselves, that an audit report is legitimate.

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract auditSign is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // Stores the actual signature together with the signers address,
    // name and the signing date
    struct Signature {
        string name;
        address signer;
        bytes signature;
        uint256 date;
    }

    // Stores the audit report
    struct Audit {
        string name;
        string ipfsHash;
        uint256 date;
    }

    // Mirroring Contracts on other networks
    // ChainID => Address
    mapping(uint256 => address) public mirrorContracts;

    // IPFS Base URL
    string public ipfsBase;

    // Audit Reports
    Audit[] public audits;
    // IPFSHash => Index
    mapping(string => uint256) public indexOfAudit;
    // IPFSHash => true/false
    mapping(string => bool) internal auditExists;

    // Signatures
    // IPFSHash => Signatures
    mapping(string => Signature[]) public signatures;
    // IPFSHash => SignerAddress => true/false
    mapping(string => mapping(address => bool)) internal hasSignedAuditReport;

    // Allowed addresses to submit signatures (currently just our backend node,
    // since we are paying for the signing process)
    mapping(address => bool) internal hasSigningRights;

    // Events
    event NewAudit(string indexed ipfsHash, string auditName);
    event NewSignature(
        string indexed ipfsHash,
        address indexed signer,
        string signerName,
        bytes signature
    );

    function initialize(string memory _baseUrl, address _adminAddress, address _signerAddress)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        hasSigningRights[_signerAddress] = true;
        transferOwnership(_adminAddress);
        ipfsBase = _baseUrl;
    }

    // Change the signing rights of an address
    function modifySigningRights(address _address, bool _access)
        external
        onlyOwner
    {
        hasSigningRights[_address] = _access;
    }

    // Change the IPFS base url
    function modifyBaseUrl(string memory _baseUrl) external onlyOwner {
        ipfsBase = _baseUrl;
    }

    // Add or change a record for a mirroring contract
    function changeMirrorContract(uint256 _chainID, address _mirrorContract)
        external
        onlyOwner
    {
        mirrorContracts[_chainID] = _mirrorContract;
    }

    // Only allows authorized addresses to submit a new signature
    modifier onlySigner() {
        require(hasSigningRights[msg.sender], "AUDITSIGN/NOT-AUTHORIZED");
        _;
    }

    // createAudit will create a new audit object which can be signed from now on
    function createAudit(string memory _name, string memory _ipfsHash)
        public
        onlySigner
    {
        require(!auditExists[_ipfsHash], "AUDITSIGN/AUDIT-ALREADY-EXISTS");

        auditExists[_ipfsHash] = true;
        indexOfAudit[_ipfsHash] = audits.length;
        Audit memory newAudit = Audit(_name, _ipfsHash, now);
        audits.push(newAudit);

        emit NewAudit(_ipfsHash, _name);
    }

    // signAudit allows people to attach a signatures to an NFT token
    // They have to be either whitelisted (if the token works with a whitelist)
    // or everyone can sign if it's not a token using a whitelist
    function signAudit(
        string memory _ipfsHash,
        string memory _name,
        address _signer,
        bytes memory _signature
    ) public onlySigner {
        require(auditExists[_ipfsHash], "AUDITSIGN/AUDIT-DOESNT-EXIST");

        // Message that was signed conforms to this structure:
        // This Audit Report (IPFSHash: Q0123012301012301230101230123010123012301)
        // by byterocket was signed by Name
        //(Address: 0x5123012301012301230101230123010123012301)!
        string memory signedMessage =
            string(
                abi.encodePacked(
                    "This Audit Report (IPFS-Hash: ",
                    _ipfsHash,
                    ") by byterocket was signed by ",
                    _name,
                    " (Address: ",
                    addressToString(_signer),
                    ")!"
                )
            );

        // Recreating the messagehash that was signed
        // Sidenote: I am aware that bytes(str).length isn't perfect, but
        // as the strings can only contain A-Z, a-z and 0-9 characters,
        // it's always 1 byte = 1 characater, so it's fine in this case
        // - and the most efficient
        bytes32 messageHash =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    uintToString(bytes(signedMessage).length),
                    signedMessage
                )
            );

        // Checking whether the signer matches the signature (signature is correct)
        address signer = messageHash.recover(_signature);
        require(signer == _signer, "AUDITSIGN/WRONG-SIGNATURE");

        // Users can only sign a report once
        require(
            !hasSignedAuditReport[_ipfsHash][signer],
            "AUDITSIGN/ALREADY-SIGNED"
        );

        // Store the signer and the signature
        Signature memory newSignature =
            Signature(_name, signer, _signature, now);
        signatures[_ipfsHash].push(newSignature);
        hasSignedAuditReport[_ipfsHash][signer] = true;

        emit NewSignature(_ipfsHash, signer, _name, _signature);
    }

    // signMultipleAudits just calls signAudit based on the input to save some gas
    function signMultipleAudits(
        string memory _ipfsHash,
        string[] memory _names,
        address[] memory _signers,
        bytes[] memory _signatures
    ) public {
        uint256 amount = _names.length;
        require(
            _signers.length == amount && _signatures.length == amount,
            "AUDITSIGN/LENGTHS-DONT-MATCH"
        );

        for (uint256 i = 0; i < amount; i++) {
            signAudit(_ipfsHash, _names[i], _signers[i], _signatures[i]);
        }
    }

    // createAndSignAudit combined the functions of createAudit and multiple signAudits to save gas
    function createAndSignAudit(
        string memory _auditName,
        string memory _ipfsHash,
        string[] memory _signerNames,
        address[] memory _signers,
        bytes[] memory _signatures
    ) external {
        createAudit(_auditName, _ipfsHash);
        signMultipleAudits(_ipfsHash, _signerNames, _signers, _signatures);
    }

    // getSignatures returns all signers of an audit report with their name and signature
    function getSignatures(string memory _ipfsHash)
        external
        view
        returns (
            string[] memory namesOfSigners,
            address[] memory addressesOfSigners,
            bytes[] memory allSignatures
        )
    {
        namesOfSigners = new string[](signatures[_ipfsHash].length);
        addressesOfSigners = new address[](signatures[_ipfsHash].length);
        allSignatures = new bytes[](signatures[_ipfsHash].length);

        for (uint256 i = 0; i < signatures[_ipfsHash].length; i++) {
            namesOfSigners[i] = signatures[_ipfsHash][i].name;
            addressesOfSigners[i] = signatures[_ipfsHash][i].signer;
            allSignatures[i] = signatures[_ipfsHash][i].signature;
        }

        return (namesOfSigners, addressesOfSigners, allSignatures);
    }

    // From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function uintToString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    // From https://ethereum.stackexchange.com/questions/70300/how-to-convert-an-ethereum-address-to-an-ascii-string-in-solidity
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}
"
    },
    "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}
"
    },
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}
"
    },
    "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
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
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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
    "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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
    "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol": {
      "content": "// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {
      "": {}
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