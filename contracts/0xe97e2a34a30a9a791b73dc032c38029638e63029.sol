{{
  "language": "Solidity",
  "sources": {
    "contracts/HolyNephalemSecondary.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*                                                                                
 *                                     ~~                                       
 *                                    .BG                                       
 *                                    J&&J                                      
 *                                   ~&&&&^                                     
 *                                   G&&&&P                                     
 *                                  J&&&&&&?                                    
 *                                 ^BB&&&&BB:                                   
 *                         :Y~     J?Y&&&&J??     ~Y.                           
 *                        7#&~     7:?&&&&7:!     ~&#!                          
 *                       Y&&B.       7&#&&!       .B&&J                         
 *                     .P&&&P        7&&&&!        P&&&5.                       
 *                     P&&#&5        ?&&&&7        5&#&&5                       
 *                    Y#YB#&Y        J&&&&?        5&&GY#J                      
 *                   ~P7^J&#P        Y&&&&J        P&&J^?P~                     
 *                   ^7: ~##G        G&###P       .B&&~ :!^                     
 *                       ^###^      ^######^      ~&&&^                         
 *                       ^&&&Y      5######Y      5&&#:                         
 *                       ^&&&#^    7########7    ~&&&#:                         
 *                       !&###B7^~Y########&&Y~^?#####~                         
 *                       Y&##############&&&&&&#&#####J                         
 *                      .G############&&&&&&##########G                         
 *                      ?###########&&&&&#############&7                        
 *                     .Y5PGGBB##&&&&&###########BBGGP5J.                       
 *                      .:^~!7?J5PB##########BP5J?7!~^:.                        
 *                             .:^7YG######GY7~:.                               
 *                                 .~YB##BY~.                                   
 *                                   .7BB?.                                     
 *                                     ??                                       
 *                                     ..                                       
 */                                                                              

contract HolyNephalemSecondary is Ownable, ReentrancyGuard  {

    /* Construction */

    constructor() {
        constructDistribution();
    }

    /* Fallbacks */

    receive() payable external {}
    fallback() payable external {}

    /* Owner */

    /// @notice Prevents ownership renouncement
    function renounceOwnership() public override onlyOwner {}

    /* Funds */

    uint16 private shareDenominator = 10000;
    uint16[] private shares;
    address[] private payees;

    /// @notice Assigns payees and their associated shares
    /// @dev Uses the addPayee function to assign the share distribution
    function constructDistribution() private {
        addPayee(0x8f5C577c85D7Ff99ecA58457cadcaaB7B2433C85, 7000);
        addPayee(0xb71BF456529a0392C48EFAE846Cf6d30C705561D, 1500);
        addPayee(0x86212f0fe1944f37208e0A71c81c772440B89eF6, 1500);
    }

    /// @notice Adds a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function addPayee(address payee, uint16 share) public onlyOwner {
        require(payees.length == shares.length, "Payee and shares must be the same length.");
        require(totalShares() + share <= shareDenominator, "Cannot overassign share distribution.");
        payees.push(payee);
        shares.push(share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function updatePayee(address payee, uint16 share) external onlyOwner {
        require(address(this).balance == 0, "Must have a zero balance before updating payee shares");
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = share;
        }
        require(totalShares() <= shareDenominator, "Cannot overassign share distribution.");
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Sets a payees shares to zero, but does not remove them from the array. Payee will be ignored in the distributeFunds function
    function removePayee(address payee) external onlyOwner {
        for (uint i=0; i < payees.length; i++) {
            if(payees[i] == payee) shares[i] = 0;
        }
    }

    /// @notice Gets the total number of shares assigned to payees
    /// @dev Calculates total shares from shares[] array.
    function totalShares() private view returns(uint16) {
        uint16 sharesTotal = 0;
        for (uint i=0; i < shares.length; i++) {
            sharesTotal += shares[i];
        }
        return sharesTotal;
    }

    /// @notice Fund distribution function.
    /// @dev Uses the payees and shares array to calculate 
    function distributeFunds() external onlyOwner nonReentrant {

        uint currentBalance = address(this).balance;

        for (uint i=0; i < payees.length; i++) {
            if(shares[i] == 0) continue;
            uint share = (shares[i] * currentBalance) / shareDenominator;
            (bool sent,) = payable(payees[i]).call{value : share}("");
            require(sent, "Failed to distribute to payee.");
        }

        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }
}"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
"
    },
    "@openzeppelin/contracts/security/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT
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
"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT
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
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": false,
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
    },
    "metadata": {
      "useLiteralContent": true
    },
    "libraries": {}
  }
}}