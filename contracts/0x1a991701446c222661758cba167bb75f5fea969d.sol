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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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
    "contracts/interfaces/IAddressRegistry.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAddressRegistry {
    event AvalancheUpdated(address indexed newAddress);
    event LGEUpdated(address indexed newAddress);
    event LodgeUpdated(address indexed newAddress);
    event LoyaltyUpdated(address indexed newAddress);
    event PwdrUpdated(address indexed newAddress);
    event PwdrPoolUpdated(address indexed newAddress);
    event SlopesUpdated(address indexed newAddress);
    event SnowPatrolUpdated(address indexed newAddress);
    event TreasuryUpdated(address indexed newAddress);
    event UniswapRouterUpdated(address indexed newAddress);
    event VaultUpdated(address indexed newAddress);
    event WethUpdated(address indexed newAddress);
    
    function getAvalanche() external view returns (address);
    function setAvalanche(address _address) external;

    function getLGE() external view returns (address);
    function setLGE(address _address) external;

    function getLodge() external view returns (address);
    function setLodge(address _address) external;

    function getLoyalty() external view returns (address);
    function setLoyalty(address _address) external;

    function getPwdr() external view returns (address);
    function setPwdr(address _address) external;

    function getPwdrPool() external view returns (address);
    function setPwdrPool(address _address) external;

    function getSlopes() external view returns (address);
    function setSlopes(address _address) external;

    function getSnowPatrol() external view returns (address);
    function setSnowPatrol(address _address) external;

    function getTreasury() external view returns (address payable);
    function setTreasury(address _address) external;

    function getUniswapRouter() external view returns (address);
    function setUniswapRouter(address _address) external;

    function getVault() external view returns (address);
    function setVault(address _address) external;

    function getWeth() external view returns (address);
    function setWeth(address _address) external;
}"
    },
    "contracts/registry/AddressRegistry.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAddressRegistry } from "../interfaces/IAddressRegistry.sol";
import { AddressStorage } from "./AddressStorage.sol";

contract AddressRegistry is IAddressRegistry, Ownable, AddressStorage {
    event AvalancheUpdated(address indexed newAddress);
    event LGEUpdated(address indexed newAddress);
    event LodgeUpdated(address indexed newAddress);
    event LoyaltyUpdated(address indexed newAddress);
    event PwdrUpdated(address indexed newAddress);
    event PwdrPoolUpdated(address indexed newAddress);
    event SlopesUpdated(address indexed newAddress);
    event SnowPatrolUpdated(address indexed newAddress);
    event TreasuryUpdated(address indexed newAddress);
    event UniswapRouterUpdated(address indexed newAddress);
    event VaultUpdated(address indexed newAddress);
    event WethUpdated(address indexed newAddress);

    bytes32 private constant AVALANCHE_KEY = "AVALANCHE";
    bytes32 private constant LGE_KEY = "LGE";
    bytes32 private constant LODGE_KEY = "LODGE";
    bytes32 private constant LOYALTY_KEY = "LOYALTY";
    bytes32 private constant PWDR_KEY = "PWDR";
    bytes32 private constant PWDR_POOL_KEY = "PWDR_POOL";
    bytes32 private constant SLOPES_KEY = "SLOPES";
    bytes32 private constant SNOW_PATROL_KEY = "SNOW_PATROL";
    bytes32 private constant TREASURY_KEY = "TREASURY";
    bytes32 private constant UNISWAP_ROUTER_KEY = "UNISWAP_ROUTER";
    bytes32 private constant WETH_KEY = "WETH";
    bytes32 private constant VAULT_KEY = "VAULT";

    function getAvalanche() public override view returns (address) {
        return getAddress(AVALANCHE_KEY);
    }

    function setAvalanche(address _address) public override onlyOwner {
        _setAddress(AVALANCHE_KEY, _address);
        emit AvalancheUpdated(_address);
    }

    function getLGE() public override view returns (address) {
        return getAddress(LGE_KEY);
    }

    function setLGE(address _address) public override onlyOwner {
        _setAddress(LGE_KEY, _address);
        emit LGEUpdated(_address);
    }

    function getLodge() public override view returns (address) {
        return getAddress(LODGE_KEY);
    }

    function setLodge(address _address) public override onlyOwner {
        _setAddress(LODGE_KEY, _address);
        emit LodgeUpdated(_address);
    }

    function getLoyalty() public override view returns (address) {
        return getAddress(LOYALTY_KEY);
    }

    function setLoyalty(address _address) public override onlyOwner {
        _setAddress(LOYALTY_KEY, _address);
        emit LoyaltyUpdated(_address);
    }

    function getPwdr() public override view returns (address) {
        return getAddress(PWDR_KEY);
    }

    function setPwdr(address _address) public override onlyOwner {
        _setAddress(PWDR_KEY, _address);
        emit PwdrUpdated(_address);
    }

    function getPwdrPool() public override view returns (address) {
        return getAddress(PWDR_POOL_KEY);
    }

    function setPwdrPool(address _address) public override onlyOwner {
        _setAddress(PWDR_POOL_KEY, _address);
        emit PwdrPoolUpdated(_address);
    }

    function getSlopes() public override view returns (address) {
        return getAddress(SLOPES_KEY);
    }

    function setSlopes(address _address) public override onlyOwner {
        _setAddress(SLOPES_KEY, _address);
        emit SlopesUpdated(_address);
    }

    function getSnowPatrol() public override view returns (address) {
        return getAddress(SNOW_PATROL_KEY);
    }

    function setSnowPatrol(address _address) public override onlyOwner {
        _setAddress(SNOW_PATROL_KEY, _address);
        emit SnowPatrolUpdated(_address);
    }

    function getTreasury() public override view returns (address payable) {
        address payable _address = address(uint160(getAddress(TREASURY_KEY)));
        return _address;
    }

    function setTreasury(address _address) public override onlyOwner {
        _setAddress(TREASURY_KEY, _address);
        emit TreasuryUpdated(_address);
    }

    function getUniswapRouter() public override view returns (address) {
        return getAddress(UNISWAP_ROUTER_KEY);
    }

    function setUniswapRouter(address _address) public override onlyOwner {
        _setAddress(UNISWAP_ROUTER_KEY, _address);
        emit UniswapRouterUpdated(_address);
    }

    function getVault() public override view returns (address) {
        return getAddress(VAULT_KEY);
    }

    function setVault(address _address) public override onlyOwner {
        _setAddress(VAULT_KEY, _address);
        emit VaultUpdated(_address);
    }

    function getWeth() public override view returns (address) {
        return getAddress(WETH_KEY);
    }

    function setWeth(address _address) public override onlyOwner {
        _setAddress(WETH_KEY, _address);
        emit WethUpdated(_address);
    }
}"
    },
    "contracts/registry/AddressRegistryManager.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAddressRegistry } from "../interfaces/IAddressRegistry.sol";
import { AddressRegistry } from "../registry/AddressRegistry.sol";

// AddressRegistry Owner which enforces a 48hr timelock on address changes
contract AddressRegistryManager is Ownable {
    event TimelockInitialized(address indexed user, bytes32 method);

    bytes32 private constant AVALANCHE_KEY = "AVALANCHE";
    bytes32 private constant LGE_KEY = "LGE";
    bytes32 private constant LODGE_KEY = "LODGE";
    bytes32 private constant LOYALTY_KEY = "LOYALTY";
    bytes32 private constant OWNERSHIP_KEY = "OWNERSHIP";
    bytes32 private constant PWDR_KEY = "PWDR";
    bytes32 private constant PWDR_POOL_KEY = "PWDR_POOL";
    bytes32 private constant SLOPES_KEY = "SLOPES";
    bytes32 private constant SNOW_PATROL_KEY = "SNOW_PATROL";
    bytes32 private constant TREASURY_KEY = "TREASURY";
    bytes32 private constant UNISWAP_ROUTER_KEY = "UNISWAP_ROUTER";
    bytes32 private constant WETH_KEY = "WETH";
    bytes32 private constant VAULT_KEY = "VAULT";

    uint256 private constant TIMELOCK_PERIOD = 48 hours;
    address internal addressRegistry;
    mapping(bytes32 => uint256) public accessTimestamps;

    constructor(address _addressRegistry) public {
        addressRegistry = _addressRegistry;
    }

    function setTimelock(bytes32 method) private returns (bool) {
        if (accessTimestamps[method] == 0) {
            accessTimestamps[method] = block.timestamp + getTimelockPeriod();
            emit TimelockInitialized(msg.sender, method);
            return false;
        } else if (block.timestamp < accessTimestamps[method]) {
            revert("Timelock period has not concluded");
        } else {
            accessTimestamps[method] = 0;
            return true;
        }
    }

    function returnOwnership() public onlyOwner {
        if (setTimelock(OWNERSHIP_KEY)) {
            AddressRegistry registry = AddressRegistry(addressRegistry);
            registry.transferOwnership(msg.sender);
        }
    }

    function setAvalanche(address _address) public onlyOwner {
        if (setTimelock(AVALANCHE_KEY)) {
            IAddressRegistry(addressRegistry).setAvalanche(_address);
        }
    }

    function setLGE(address _address) public onlyOwner {
        if (setTimelock(LGE_KEY)) {
            IAddressRegistry(addressRegistry).setLGE(_address);
        }
    }

    function setLodge(address _address) public onlyOwner {
        if (setTimelock(LODGE_KEY)) {
            IAddressRegistry(addressRegistry).setLodge(_address);
        }
    }

    function setLoyalty(address _address) public onlyOwner {
        if (setTimelock(LOYALTY_KEY)) {
            IAddressRegistry(addressRegistry).setLoyalty(_address);
        }
    }

    function setPwdr(address _address) public onlyOwner {
        if (setTimelock(PWDR_KEY)) {
            IAddressRegistry(addressRegistry).setPwdr(_address);
        }
    }

    function setPwdrPool(address _address) public onlyOwner {
        if (setTimelock(PWDR_POOL_KEY)) {
            IAddressRegistry(addressRegistry).setPwdrPool(_address);
        }
    }

    function setSlopes(address _address) public onlyOwner {
        if (setTimelock(SLOPES_KEY)) {
            IAddressRegistry(addressRegistry).setSlopes(_address);
        }
    }

    function setSnowPatrol(address _address) public onlyOwner {
        if (setTimelock(SNOW_PATROL_KEY)) {
            IAddressRegistry(addressRegistry).setSnowPatrol(_address);
        }
    }

    function setTreasury(address _address) public onlyOwner {
        if (setTimelock(TREASURY_KEY)) {
            IAddressRegistry(addressRegistry).setTreasury(_address);
        }
    }

    function setUniswapRouter(address _address) public onlyOwner {
        if (setTimelock(UNISWAP_ROUTER_KEY)) {
            IAddressRegistry(addressRegistry).setUniswapRouter(_address);
        }
    }

    function setVault(address _address) public onlyOwner {
        if (setTimelock(VAULT_KEY)) {
            IAddressRegistry(addressRegistry).setVault(_address);
        }
    }

    function setWeth(address _address) public onlyOwner {
        if (setTimelock(WETH_KEY)) {
            IAddressRegistry(addressRegistry).setWeth(_address);
        }
    }

    function getTimelockPeriod() public virtual pure returns (uint256) {
        return TIMELOCK_PERIOD;
    }
}"
    },
    "contracts/registry/AddressStorage.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract AddressStorage {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
    }
}
"
    }
  }
}}