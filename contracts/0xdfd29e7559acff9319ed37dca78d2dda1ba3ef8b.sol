{{
  "language": "Solidity",
  "sources": {
    "contracts/controller.sol": {
      "content": "pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.3.2/access/Ownable.sol";

interface Hollow {
    function createTo(address to, string memory URI) external;
    function editTokenURI(uint256 tokenId, string memory newURI) external;
    function transferOwnership(address newOwner) external;
}

contract HollowController is Ownable {
    address hollowDeployer = address(0xb1120f07C94d7F2E16C7F50707A26A74bF0B12Ec);
    
    Hollow hollowContract;
    
    constructor(address _hollowContractAddress) {
        hollowContract = Hollow(_hollowContractAddress);
    }
    
    function transferHollowOwnership(address _newOwner) public onlyOwner {
        hollowContract.transferOwnership(_newOwner);
    }
    
    function mintMultiple(string[] memory _tokenURIs) public onlyOwner {
        for(uint256 i = 0; i < _tokenURIs.length; i++) {
            hollowContract.createTo(hollowDeployer, _tokenURIs[i]);
        }
    }
    
    function mintMultipleTo(address to, string[] memory _tokenURIs) public onlyOwner {
        for(uint256 i = 0; i < _tokenURIs.length; i++) {
            hollowContract.createTo(to, _tokenURIs[i]);
        }
    }
    
    function editMultiple(uint256[] memory _tokenIds, string[] memory _newTokenURIs) public onlyOwner {
        require(_tokenIds.length == _newTokenURIs.length, "Array lengths must match");
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            hollowContract.editTokenURI(_tokenIds[i], _newTokenURIs[i]);
        }
    }
}"
    },
    "@openzeppelin/contracts@4.3.2/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
"
    },
    "@openzeppelin/contracts@4.3.2/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

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
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    }
  }
}}