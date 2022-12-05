{"Context.sol":{"content":"// SPDX-License-Identifier: MIT

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
"},"ICollectorPool.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ICollectorPool {
  function maximumSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
"},"ILandCollection.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILandCollection {
  function totalMinted(uint256 groupId) external view returns (uint256);
  function maximumSupply(uint256 groupId) external view returns (uint256);
  function mintToken(address account, uint256 groupId, uint256 count, uint256 seed) external;
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function ownerOf(uint256 tokenId) external view returns (address);
}
"},"ILandYield.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILandYield {
  function distributePrimaryYield() external;
}
"},"IMintPass.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IMintPass {
  function passExists(uint256 _passId) external view returns (bool);
  function passDetail(uint256 _tokenId) external view returns (address, uint256, uint256);
  function mintToken(
    address _account,
    uint256 _passId,
    uint256 _count
  ) external;
  function burnToken(uint256 _tokenId) external;
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
"},"ZokuMinter.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILandCollection.sol";
import "./ILandYield.sol";
import "./IMintPass.sol";
import "./ICollectorPool.sol";


contract ZokuMinter is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public landCollection;
  // LandYield contract interface
  ILandYield public landYield;
  // MintPass token contract interface
  IMintPass public mintPass;
  // CollectorPool contract interface
  ICollectorPool public collectorPool;

  // Used to determine whether minting is open to public
  bool public openForPublic;
  // Used to determine whether minting is open to MintPass holders
  bool public openForPass;
  // Stores the currently set token price
  uint256 public tokenPrice;
  // Stores the number of maximum tokens mintable in a single tx
  uint256 public mintLimit;

  // Stores the universal groupId tracked by the main Collection
  uint256 public groupId;

  constructor(
    uint256 _groupId,
    uint256 _price,
    address _landCollection,
    address _landYield,
    address _mintPass,
    address _collectorPool
  ) {
    mintLimit = 15;
    groupId = _groupId;
    tokenPrice = _price;
    landCollection = ILandCollection(_landCollection);
    landYield = ILandYield(_landYield);
    mintPass = IMintPass(_mintPass);
    collectorPool = ICollectorPool(_collectorPool);
  }

  // Only to be used in case there's a need to upgrade the yield contract mid-sales
  function setLandYield(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    landYield = ILandYield(_address);
  }

  // Only to be used in case there's a need to upgrade the collector pool contract mid-sales
  function setCollectorPool(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    collectorPool = ICollectorPool(_address);
  }

  // Update the state of the public minting
  function setOpenForPublic(bool _state) external onlyOwner {
    require(openForPublic != _state, "Identical State Has Been Set");
    openForPublic = _state;
  }

  // Update the state of the priority minting
  function setOpenForPass(bool _state) external onlyOwner {
    require(openForPass != _state, "Identical State Has Been Set");
    openForPass = _state;
  }

  // Update the token price only if there's a valid reason to do so
  function setTokenPrice(uint256 _price) external onlyOwner {
    require(_price > 0, "Invalid Price");
    tokenPrice = _price;
  }

  // Set maximum mint limit per tx
  function setMintLimit(uint256 _limit) external onlyOwner {
    require(_limit > 0 && _limit <= 20, "Invalid Value For Limit");
    mintLimit = _limit;
  }

  // Accepts optional passTokenIds for priority minting using MintPass tokens (only before public sales)
  function mint(uint256[] calldata _passTokenIds) external payable nonReentrant {
    // Check if tokens are still available for sale
    uint256 maxSupply = landCollection.maximumSupply(groupId);
    uint256 totalMinted = landCollection.totalMinted(groupId);
    uint256 available = maxSupply - totalMinted;
    available = (available > mintLimit ? mintLimit : available);
    require(available > 0, "Sold Out");

    uint256 mintCount;
    uint256 totalSpent = 0;

    if (_passTokenIds.length > 0) {
      // If passTokenIds are specified, check if priority minting is open and calculate actual total prices after discounts
      require(openForPass, "Priority Minting Is Closed");
      mintCount = _passTokenIds.length;
      mintCount = (mintCount > available ? available : mintCount);

      for (uint256 i = 0; i < mintCount; i++) {
        address passOwner;
        uint256 passDiscount;
        (passOwner, , passDiscount) = mintPass.passDetail(_passTokenIds[i]);
        require(passOwner == msg.sender, "Invalid Pass Specified");

        totalSpent += tokenPrice * (100 - passDiscount) / 100;
      }

      require(msg.value >= totalSpent, "Insufficient Funds");

      for (uint256 i = 0; i < mintCount; i++) {
        mintPass.burnToken(_passTokenIds[i]);
      }
    } else {
      require(openForPublic, "Publis Sale Is Closed");
      require(msg.value >= tokenPrice, "Insufficient Funds");
      mintCount = msg.value / tokenPrice;
      mintCount = (mintCount > available ? available : mintCount);
      totalSpent = mintCount * tokenPrice;
    }

    landCollection.mintToken(msg.sender, groupId, mintCount, available);

    if (totalSpent > 0) {
      // Transfer the funds to the yield contract for land owners and treasury, and leave the rest for collectors
      uint256 yield = totalSpent * 85 / 100;
      uint256 treasury = totalSpent * 5 / 100;
      (bool success, ) = address(landYield).call{value: yield + treasury}(
        abi.encodeWithSignature("distributeSalesYield(uint256)", yield)
      );
      require(success, "Failed To Distribute To Yield");

      // Send back any excess funds
      uint256 refund = msg.value - totalSpent;
      if (refund > 0) {
        payable(msg.sender).transfer(refund);
      }
    }
  }

  // Transfers the remaining funds to the collector pool
  function withdraw() external onlyOwner {
    uint256 totalFunds = address(this).balance;
    require(totalFunds > 0, "Insufficient Funds");
    // Send funds via call function for the collector pool funds
    (bool success, ) = address(collectorPool).call{value: totalFunds}("");
    require(success, "Failed To Distribute To Pool");
  }
}
"}}