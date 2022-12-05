{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "petersburg",
    "libraries": {},
    "metadata": {
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
      "content": "pragma solidity ^0.5.0;

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
"
    },
    "@openzeppelin/contracts/math/Math.sol": {
      "content": "pragma solidity ^0.5.0;

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
"
    },
    "@openzeppelin/contracts/ownership/Ownable.sol": {
      "content": "pragma solidity ^0.5.0;

import "../GSN/Context.sol";
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
}
"
    },
    "@openzeppelin/contracts/utils/Create2.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 *
 * _Available since v2.5.0._
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}. Note that
     * a contract cannot be deployed twice using the same salt.
     */
    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the `bytecode`
     * or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes memory bytecode) internal view returns (address) {
        return computeAddress(salt, bytecode, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes memory bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 bytecodeHashHash = keccak256(bytecodeHash);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }
}
"
    },
    "contracts/GSNModules/GSNLib.sol": {
      "content": "pragma solidity ^0.5.0;

import { SliceLib } from "../libraries/SliceLib.sol";

library GSNLib {
  bytes32 constant SIGNATURE_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;
  function toSignature(bytes memory input) internal pure returns (bytes4 signature) {
    bytes32 local = SIGNATURE_MASK;
    assembly {
      signature := and(mload(add(0x20, input)), local)
    }
  }
  function splitPayload(bytes memory payload) internal pure returns (bytes4 signature, bytes memory args) {
    signature = toSignature(payload);
    args = SliceLib.copy(SliceLib.toSlice(payload, 4));
  }
}
"
    },
    "contracts/GSNModules/GSNModule04.sol": {
      "content": "pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {IProxyWalletFactory} from "../interfaces/IProxyWalletFactory.sol";
import {GSNLib} from "./GSNLib.sol";
import {ProxyWalletLib} from "../ProxyWallet/ProxyWalletLib.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { IChi } from "../interfaces/IChi.sol";

contract GSNModule04 is Ownable {
    using GSNLib for *;
    address public whitelistedRelayer;
    address constant CHI_TOKEN = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    // Maximum amount of CHI to burn
    uint256 constant MAX_BURN_AMOUNT = 8;

    constructor(address _whitelistedRelayer) public Ownable() {
        whitelistedRelayer = _whitelistedRelayer;
        // Prefill all slots with current gas price
        for (uint256 i = 0; i < AVERAGE_N_RECORDS; i++) {
            _storeThisGasPrice();
        }
    }

    function _getGSNModule() internal view returns (GSNModule04 gsnModule) {
        gsnModule = GSNModule04(ProxyWalletLib.getGSNModule());
    }

    function _getChiAddress() public view returns (address) {
        return CHI_TOKEN;
    }

    bytes32 constant GAS_PRICE_STORAGE_SLOT =
        0x6176eedb4178e8eb1b4156527c106860b74026ff26f7dbc11da0c373efba968a; // keccak256("gasprice")
    bytes32 constant GAS_PRICE_NEXT_POSITION_SLOT =
        0x69cf67c52ac5c3626369a2c4ce103b3fffd46fa4d3948f125cbfdc25a5f01d2c; // keccak256("gasprice-length")
    uint256 constant AVERAGE_N_RECORDS = 5;

    function _storeNextGasPricePosition(uint256 length) internal {
        bytes32 slot = GAS_PRICE_NEXT_POSITION_SLOT;
        assembly {
            sstore(slot, length)
        }
    }

    function _readNextGasPricePosition() public view returns (uint256 length) {
        bytes32 slot = GAS_PRICE_NEXT_POSITION_SLOT;
        assembly {
            length := sload(slot)
        }
    }

    function _storeGasPrice(
        uint256 i,
        uint256 gasPrice
    ) internal {
        bytes32 slot = keccak256(abi.encodePacked(GAS_PRICE_STORAGE_SLOT, i));
        assembly {
            sstore(slot, gasPrice)
        }
    }

    function _readGasPrice(uint256 i)
        public
        view
        returns (uint256 gasPrice)
    {
        bytes32 slot = keccak256(abi.encodePacked(GAS_PRICE_STORAGE_SLOT, i));
        assembly {
            gasPrice := sload(slot)
        }
    }

    function _storeThisGasPrice() internal {
        // Get the index of the slot to store gas price in
        uint256 position = _readNextGasPricePosition();
        _storeGasPrice(position, tx.gasprice);
        // Rotate through every AVERAGE_N_RECORDS slots
        _storeNextGasPricePosition((position + 1) % AVERAGE_N_RECORDS);
    }

    function _getMeanGasPrice() public view returns (uint256 result) {
        uint256 sum;
        for (uint256 i = 0; i < AVERAGE_N_RECORDS; i++) {
            uint256 gasPrice = _readGasPrice(i);
            sum += gasPrice;
        }
        result = sum / AVERAGE_N_RECORDS;
    }

    bytes32 constant GASPRICE_THRESHOLD_SLOT =
        0x07350205221d0ce9cc016414b10dfaac01bc9c2a8ddbb38c7fb370049017d90d; // keccak256("gasprice.threshold")

    function setGasPriceThreshold(uint256 threshold) public onlyOwner {
        bytes32 slot = GASPRICE_THRESHOLD_SLOT;
        assembly {
            sstore(slot, threshold)
        }
    }

    function getGasPriceThresholdHandler() public view returns (uint256 threshold) {
        bytes32 slot = GASPRICE_THRESHOLD_SLOT;
        assembly {
            threshold := sload(slot)
        }
    }

    function getGasPriceThreshold() public view returns (uint256 threshold) {
        return _getGSNModule().getGasPriceThresholdHandler();
    }

    function acceptRelayedCall(
        address relay,
        address from,
        bytes memory encodedFunction,
        uint256, /* transactionFee */
        uint256, /* gasPrice */
        uint256, /* gasLimit */
        uint256, /* nonce */
        bytes memory, /* approvalData */
        uint256 /* maxPossibleCharge */
    ) public view returns (uint256 doCall, bytes memory) {
        (bytes4 signature, bytes memory args) = encodedFunction.splitPayload();
        // Allow whitelisted relayer to perform any proxy call
        address _whitelistedRelayer = whitelistedRelayer; // save 800 gas
        if (
            signature == IProxyWalletFactory(0).proxy.selector &&
            (relay == _whitelistedRelayer || _whitelistedRelayer == address(0x0))) {
            doCall = 0;
        } else doCall = 1;
    }

    function preRelayedCall(
        bytes memory /* context */
    ) public returns (bytes32) {
        _storeThisGasPrice();
    }

    function postRelayedCall(
        bytes memory, /* context */
        bool, /* success */
        uint256 gasAmount,
        bytes32 /* preRetVal */
    ) public {
        // If moving average of past 5 txs' gas prices is above threshold
        if (_getMeanGasPrice() >= getGasPriceThreshold()) {
            // Burn Chi to reduce gas costs
            IChi(_getChiAddress()).freeUpTo(
                Math.min((gasAmount + 14154) / 41947, MAX_BURN_AMOUNT)
            ); // divide by twice the max gasrefund Chi token qty since we can only get 50% refunded
        }
    }
}
"
    },
    "contracts/ProxyWallet/ProxyWalletLib.sol": {
      "content": "pragma solidity ^0.5.0;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { MemcpyLib } from "../libraries/MemcpyLib.sol";

library ProxyWalletLib {
  bytes32 constant _OWNER_SLOT = 0x734a2a5caf82146a5ddd5263d9af379f9f72724959f0567ddc9df2c40cf2cc20; // keccak256("owner")
  bytes32 constant _WALLET_FACTORY_SALT = 0x154d67e25bcc1ea1986fa661b5b80b8facf3a90be6159e155e199e54a74fcb4d; // keccak256("wallet-factory")
  bytes32 constant _IMPLEMENTATION_SLOT = 0x8ba0ed1f62da1d3048614c2c1feb566f041c8467eb00fb8294776a9179dc1643; // keccak256("implementation")
  bytes32 constant _GSN_MODULE_SLOT = 0x73c1ac149a67e4e6e228d78c3a8df342639f43de1a2480627ae6fad35761d9af; // keccak256("gsn-module")
  function WALLET_FACTORY_SALT() internal pure returns (bytes32 salt) {
    salt = _WALLET_FACTORY_SALT;
  }
  function getImplementation() internal view returns (address implementation) {
     bytes32 local = _IMPLEMENTATION_SLOT;
     assembly {
       implementation := sload(local)
     }
  }
  function setImplementation(address implementation) internal {
    bytes32 local = _IMPLEMENTATION_SLOT;
    assembly {
      sstore(local, implementation)
    }
  }
  function setGSNModule(address gsnModule) internal {
    bytes32 local = _GSN_MODULE_SLOT;
    assembly {
      sstore(local, gsnModule)
    }
  }
  function getGSNModule() internal view returns (address gsnModule) {
    bytes32 local = _GSN_MODULE_SLOT;
    assembly {
      gsnModule := sload(local)
    }
  }
  function getOwner() internal view returns (address owner) {
    bytes32 OWNER_SLOT = _OWNER_SLOT;
    assembly {
      owner := sload(OWNER_SLOT)
    }
  }
  enum CallType {
    INVALID,
    CALL,
    DELEGATECALL
  }
  struct ProxyCall {
    CallType typeCode;
    address payable to;
    uint256 value;
    bytes data;
  }
  function setOwner(address owner) internal {
    bytes32 local = _OWNER_SLOT;
    assembly {
      sstore(local, owner)
    }
  }
  function proxyCall(ProxyCall memory callDetails) internal returns (bool success, bytes memory returnData) {
    if (callDetails.typeCode == CallType.DELEGATECALL) {
      (success, returnData) = callDetails.to.delegatecall(callDetails.data);
    } else if (callDetails.typeCode == CallType.CALL) {
      (success, returnData) = callDetails.to.call.value(callDetails.value)(callDetails.data);
    }
  }
  function computeCreationCode(address target) internal view returns (bytes memory clone) {
    clone = computeCreationCode(address(this), target);
  }
  function computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
      bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
      clone = new bytes(99 + consData.length);
      assembly {
        mstore(add(clone, 0x20),
           0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
        mstore(add(clone, 0x2d),
           mul(deployer, 0x01000000000000000000000000))
        mstore(add(clone, 0x41),
           0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
           mstore(add(clone, 0x60),
           mul(target, 0x01000000000000000000000000))
        mstore(add(clone, 116),
           0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      }
      for (uint256 i = 0; i < consData.length; i++) {
        clone[i + 99] = consData[i];
      }
  }
  function deriveInstanceAddress(address target, bytes32 salt) internal view returns (address) {
    return Create2.computeAddress(salt, computeCreationCode(target));
  }
  function deriveInstanceAddress(address from, address target, bytes32 salt) internal pure returns (address) {
     return Create2.computeAddress(salt, computeCreationCode(from, target), from);
  }
}
"
    },
    "contracts/interfaces/IChi.sol": {
      "content": "pragma solidity ^0.5.0;

interface IChi {
  function freeUpTo(uint256) external returns (uint256);
  function mint(uint256) external;
  function transfer(address, uint256) external returns (bool);
}
"
    },
    "contracts/interfaces/IProxyWalletFactory.sol": {
      "content": "pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

import { ProxyWalletLib } from "../ProxyWallet/ProxyWalletLib.sol";

interface IProxyWalletFactory {
  function proxy(ProxyWalletLib.ProxyCall[] calldata /* calls */) external payable returns (bytes[] memory /* returnValues */);
  function getImplementation() external view returns (address);
}
"
    },
    "contracts/libraries/MemcpyLib.sol": {
      "content": "pragma solidity ^0.5.0;

library MemcpyLib {
  function memcpy(bytes32 dest, bytes32 src, uint256 len) internal pure {
    assembly {
      for {} iszero(lt(len, 0x20)) { len := sub(len, 0x20) } {
        mstore(dest, mload(src))
        dest := add(dest, 0x20)
        src := add(src, 0x20)
      }
      let mask := sub(shl(mul(sub(32, len), 8), 1), 1)
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
  }
}
"
    },
    "contracts/libraries/SliceLib.sol": {
      "content": "pragma solidity ^0.5.0;

import { MemcpyLib } from "./MemcpyLib.sol";

library SliceLib {
  struct Slice {
    uint256 data;
    uint256 length;
    uint256 offset;
  }
  function toPtr(bytes memory input, uint256 offset) internal pure returns (uint256 data) {
    assembly {
      data := add(input, add(offset, 0x20))
    }
  }
  function toSlice(bytes memory input, uint256 offset, uint256 length) internal pure returns (Slice memory retval) {
    retval.data = toPtr(input, offset);
    retval.length = length;
    retval.offset = offset;
  }
  function toSlice(bytes memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function toSlice(bytes memory input, uint256 offset) internal pure returns (Slice memory) {
    if (input.length < offset) offset = input.length;
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input, uint256 offset, uint256 length) internal pure returns (Slice memory) {
    return Slice({
      data: input.data + offset,
      offset: input.offset + offset,
      length: length
    });
  }
  function toSlice(Slice memory input, uint256 offset) internal pure returns (Slice memory) {
    return toSlice(input, offset, input.length - offset);
  }
  function toSlice(Slice memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }
  function maskLastByteOfWordAt(uint256 data) internal pure returns (uint8 lastByte) {
    assembly {
      lastByte := and(mload(data), 0xff)
    }
  }
  function get(Slice memory slice, uint256 index) internal pure returns (bytes1 result) {
    return bytes1(maskLastByteOfWordAt(slice.data - 0x1f + index));
  }
  function setByteAt(uint256 ptr, uint8 value) internal pure {
    assembly {
      mstore8(ptr, value)
    }
  }
  function set(Slice memory slice, uint256 index, uint8 value) internal pure {
    setByteAt(slice.data + index, value);
  }
  function wordAt(uint256 ptr, uint256 length) internal pure returns (bytes32 word) {
    assembly {
      let mask := sub(shl(mul(length, 0x8), 0x1), 0x1)
      word := and(mload(sub(ptr, sub(0x20, length))), mask)
    }
  }
  function asWord(Slice memory slice) internal pure returns (bytes32 word) {
    uint256 data = slice.data;
    uint256 length = slice.length;
    return wordAt(data, length);
  }
  function toDataStart(bytes memory input) internal pure returns (bytes32 start) {
    assembly {
      start := add(input, 0x20)
    }
  }
  function copy(Slice memory slice) internal pure returns (bytes memory retval) {
    uint256 length = slice.length;
    retval = new bytes(length);
    bytes32 src = bytes32(slice.data);
    bytes32 dest = toDataStart(retval);
    MemcpyLib.memcpy(dest, src, length);
  }
  function keccakAt(uint256 data, uint256 length) internal pure returns (bytes32 result) {
    assembly {
      result := keccak256(data, length)
    }
  }
  function toKeccak(Slice memory slice) internal pure returns (bytes32 result) {
    return keccakAt(slice.data, slice.length);
  }
}
"
    }
  }
}}