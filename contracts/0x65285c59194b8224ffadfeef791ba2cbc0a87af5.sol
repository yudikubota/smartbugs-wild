// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: ClaimSpotSale.sol




pragma solidity ^0.8.17;

/// @author someone in metaverse
contract MobtiesVIP is Ownable {
    uint256 public claimSpotsSold = 0;
    mapping(address => uint256) public claimSpotsBoughtBy;

    uint256 public claimSpotsToSell = 500;
    uint256 public costPerClaim = 0.35 * 1e18;
    uint256 public maxMintClaimSpotAmount = 10;
    uint256 public claimSpotMintActiveTime = type(uint256).max;

    event PurchasedClaimSpot(address, uint256);

    /// @notice people can buy claim spots here when sale is open
    function purchaseClaimSpot(uint256 _mintAmount) external payable {
        require(_mintAmount > 0, "need to mint at least 1 spot");
        require(msg.value == costPerClaim * _mintAmount, "incorrect funds");
        require(
            block.timestamp > claimSpotMintActiveTime,
            "The Claim Spot Mint is paused"
        );
        require(
            claimSpotsBoughtBy[msg.sender] + _mintAmount <=
                maxMintClaimSpotAmount,
            "max mint amount per session exceeded"
        );
        require(
            claimSpotsSold + _mintAmount <= claimSpotsToSell,
            "max mint amount per session exceeded"
        );

        claimSpotsBoughtBy[msg.sender] += _mintAmount;
        claimSpotsSold += _mintAmount;

        emit PurchasedClaimSpot(msg.sender, _mintAmount);
    }

    /// @notice owner can withdraw funds from here
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /// @dev setters

    /// @notice owner can change the price of claim spots
    function setCostPerClaim(uint256 _costPerClaim) public onlyOwner {
        costPerClaim = _costPerClaim;
    }

    /// @notice owner can change the total number of claim spots to sell
    function setClaimSpotsToSell(uint256 _claimSpotsToSell) public onlyOwner {
        claimSpotsToSell = _claimSpotsToSell;
    }

    /// @notice owner can change the per wallet max mint claim spots
    function setMaxMintClaimSpotAmount(uint256 _maxMintClaimSpotAmount)
        public
        onlyOwner
    {
        maxMintClaimSpotAmount = _maxMintClaimSpotAmount;
    }

    /// @notice Owner can open or close the sale. To open put 0, to close put 99999999999999999999, to start at specific time get time value from here https://www.epochconverter.com/
    function setClaimSpotMintActiveTime(uint256 _claimSpotMintActiveTime)
        public
        onlyOwner
    {
        claimSpotMintActiveTime = _claimSpotMintActiveTime;
    }
}