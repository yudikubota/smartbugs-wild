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
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
"},"RoyaltySplitter.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";

/*
Automatically distributes royalties once autoWithdrawLimit exceeded.
Developed by Co-Labs. www.co-labs.studio
*/
contract Shareholders is Ownable {
    address payable[] public shareholders;
    uint256[] public shares;
    uint256 public autoWithdrawLimit = 1 ether;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if (address(this).balance > autoWithdrawLimit) {
            withdraw();
        }
    }

    constructor() { 
        shareholders.push(payable(0xDB6FfD47E81deb48360C4f73d169Fbb743Be0E26)); 
        shares.push(250);
        shareholders.push(payable(0x376776aA01c0B4f714A2B36F7258E79DA0307188)); 
        shares.push(250);
        shareholders.push(payable(0x37fb006F219781b42D50bd1efDb3C3449E3FEB1A)); 
        shares.push(250);
        shareholders.push(payable(0xb15FE66373908b9c1702fdAfC921F37B6CFf66f7));
        shares.push(83);
        shareholders.push(payable(0x95B85D3DA72b26A5847d78438f84f36322D16ef6)); 
        shares.push(83);
        shareholders.push(payable(0x25E1c3272f2268AFC42e9896Aa3eC96cD6ef4826)); 
        shares.push(84);
        

    }

    function changeShareholders(address payable[] memory newShareholders, uint256[] memory newShares) public onlyOwner {
        delete shareholders;
        delete shares;
        uint256 length = newShareholders.length;
        require(newShareholders.length == newShares.length, "number of new shareholders must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            shareholders.push(newShareholders[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = shareholders.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
        }
        return totalShares;
    }

    function changeAutoWithdrawLimit(uint256 _newLimit) external onlyOwner {
        autoWithdrawLimit = _newLimit;
    }

    function withdraw() public {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = shareholders.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = shareholders[j];
            share = shares[j];
            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

   

}
"}}