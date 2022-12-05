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
"},"ILand.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ILand {
  function maximumSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
"},"LandYield.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILand.sol";


contract LandYield is Ownable, ReentrancyGuard {
  // Land token contract interface
  ILand public landContract;

  address private _treasury;
  address private _admin;

  uint256 private _totalYieldPerLand;
  uint256 private _totalReleasedYield;
  uint256 private _owedTreasuryYield;
  mapping (uint256 => uint256) private _releasedYield;

  // Add this modifier to all functions which are only accessible by the owner or the selected admin
  modifier onlyManager() {
    require(msg.sender == owner() || msg.sender == _admin, "Unauthorized Access");
    _;
  }

  constructor(address _landContractAddress) {
    landContract = ILand(_landContractAddress);
    _treasury = msg.sender;
    _admin = msg.sender;
  }

  function admin() external view returns (address) {
    return _admin;
  }

  function setAdmin(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    _admin = _address;
  }

  function treasury() external view returns (address) {
    return _treasury;
  }

  function setTreasury(address _address) external onlyManager {
    require(_address != address(0), "Invalid Address");
    _treasury = _address;
  }

  function totalYieldPerLand() external view returns (uint256) {
    return _totalYieldPerLand;
  }

  function totalReleasedYield() external view returns (uint256) {
    return _totalReleasedYield;
  }

  function owedTreasuryYield() external view returns (uint256) {
    return _owedTreasuryYield;
  }

  // Called by registered primary token sales contracts for distributing the profits for land owners and treasury
  function distributeSalesYield(uint256 _landYield) external payable nonReentrant {
    require(msg.value > 0, "Insufficient Yield");

    // Calculate and update the total yield per land
    // And also update the yield allocated for the treasury (+ any division remainders)
    uint256 landCount = landContract.maximumSupply();
    _totalYieldPerLand += _landYield / landCount;
    _owedTreasuryYield += (msg.value - _landYield) + (_landYield % landCount);
  }

  function releasedYieldByTokenId(uint256 _tokenId) external view returns (uint256) {
    return _releasedYield[_tokenId];
  }

  // Calculate and return the total amount of owed (land) yield for the specified account
  function totalOwedYieldByAccount(address _account) external view returns (uint256) {
    uint256 landOwned = landContract.balanceOf(_account);
    uint256 totalOwedYield = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(_account, i);
      uint256 owedYield = _totalYieldPerLand - _releasedYield[tokenId];

      if (owedYield > 0) {
        totalOwedYield += owedYield;
      }
    }

    return totalOwedYield;
  }

  // Can be called by land owners for withdrawing collected yields
  function releaseForLandOwner() external nonReentrant {
    uint256 landOwned = landContract.balanceOf(msg.sender);
    require(landOwned > 0, "Reserved For Land Owners");

    // Iterate through all owned land tokens and calculate the total unclaimed yield
    uint256 totalOwedYield = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(msg.sender, i);
      uint256 owedYield = _totalYieldPerLand - _releasedYield[tokenId];

      if (owedYield > 0) {
        totalOwedYield += owedYield;
        _releasedYield[tokenId] = _totalYieldPerLand;
      }
    }

    require(totalOwedYield > 0, "Insufficient Yield");
    _totalReleasedYield += totalOwedYield;

    payable(msg.sender).transfer(totalOwedYield);
  }

  // Handles yield received as royalties from OpenSea, allocated for the land owners
  receive() external payable {
    require(msg.value > 0, "Insufficient Yield");

    // Update the total yield per land and put the remainder due to integer-division (if any) to the treasury
    uint256 landCount = landContract.maximumSupply();
    _totalYieldPerLand += msg.value / landCount;
    _owedTreasuryYield += msg.value % landCount;
  }

  function releaseForTreasury() external onlyManager nonReentrant {
    require(_owedTreasuryYield > 0, "Insufficient Yield");

    uint256 totalOwedYield = _owedTreasuryYield;
    _owedTreasuryYield = 0;
    _totalReleasedYield += totalOwedYield;

    payable(_treasury).transfer(totalOwedYield);
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
"}}