{"DummyOwnerService.sol":{"content":"pragma solidity 0.8.3;

import "./ProjectOwnerServiceInterface.sol";

contract DummyOwnerService is ProjectOwnerServiceInterface {

    function getProjectOwner(address _address) external override view returns(address) {
        return 0xA0b3bDe4f4c86438BEE13673647a9616ffDE0496; // KG address
    }
    
    function getProjectFeeInWei(address _address) external override view returns(uint256) {
        return 1000000000000000; // 0,001 eth
    }

    function isProjectRegistered(address _address) external override view returns(bool) {
        return true;
    }

    function isProjectOwnerService() external override view returns(bool){
        return true;
    }

}"},"ERC721.sol":{"content":"pragma solidity 0.8.3;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 is ERC165  {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}"},"ERC721Map.sol":{"content":"pragma solidity 0.8.3;

import "./Withdrawable.sol";
import "./ERC721.sol";

contract ERC721Map is Withdrawable {

    event ERC721NameSet(address indexed _address, uint256 indexed _tokenId, string _name);
    event AddressBanned(address indexed _address);
    event AddressUnbanned(address indexed _address);

    // All added addresses are ERC721
    mapping(address => mapping(uint256 => string)) contractToMap;

    bool public isPaused;

    constructor() public {
        isPaused = false;
    }

    // Banned owners 
    mapping (address => bool) public bannedAddresses;

    function isBanned(address _address) external view returns(bool){
        return bannedAddresses[_address];
    }

    /**
    * Banning the address will make the contract ignore all the records 
    * that blocked address owns. This blocks NFT owners NOT contract addresses. 
     */
    function ban(address _address) public onlyOwner {
        bannedAddresses[_address] = true;
        emit AddressBanned(_address);
    }

    function unban(address _address) public onlyOwner {
        bannedAddresses[_address] = false;
        emit AddressUnbanned(_address);
    }

    /**
    * When contract is paused it's impossible to set a name. We leave a space here to migrate to a new 
    * contract and block current contract from writting to it while making the read operations 
    * possible. 
    */
    function setIsPaused(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function _setTokenName(address _address, uint256 _tokenId, string memory _nftName) internal {
        ERC721 nft = ERC721(_address);

        require(!isPaused);
        require(nft.supportsInterface(0x80ac58cd));
        require(nft.ownerOf(_tokenId) == msg.sender);

        contractToMap[_address][_tokenId] = _nftName;
        emit ERC721NameSet(_address, _tokenId, _nftName);
    }

    function getTokenName(address _address, uint256 _tokenId) external view returns(string memory) {
        ERC721 nft = ERC721(_address);
        require(nft.supportsInterface(0x80ac58cd));
        require(!this.isBanned(nft.ownerOf(_tokenId)));

        return contractToMap[_address][_tokenId];
    }

    /**
    * For testing purposes, it's not really required. You may test if your contract 
    * is compatible with our service. 
    *
    * @return true if contract is supported. Throws an exception otherwise. 
    */
    function isContractSupported(address _address) external view returns (bool) {
            ERC721 nft = ERC721(_address);

            // 0x80ac58cd is ERC721 
            return nft.supportsInterface(0x80ac58cd);
    }

}"},"ERC721NameService.sol":{"content":"pragma solidity 0.8.3;

import "./ERC721Map.sol";
import "./ProjectOwnerServiceInterface.sol";

contract ERC721NameService is ERC721Map {

    // Fee in wei for the name service
    uint256 public baseFee;

    address public ownerServiceAddress;

    constructor() public {
        baseFee = 0;
    }

    function setBaseFee(uint256 _fee) public onlyOwner {
        baseFee = _fee;
    }

    function setOwnerService(address _address) public onlyOwner {
        if(_address == address(0x0)) {
            ownerServiceAddress = address(0x0);
            return;
        }

        ProjectOwnerServiceInterface service = ProjectOwnerServiceInterface(_address);
        require(service.isProjectOwnerService());

        ownerServiceAddress = _address;
    }
    
    function getProjectFeeInWei(address _address) public view returns(uint256) {
        if(ownerServiceAddress != address(0x0)) {
            ProjectOwnerServiceInterface ownerService = ProjectOwnerServiceInterface(ownerServiceAddress);
            if(ownerService.isProjectRegistered(_address)) {
                return ownerService.getProjectFeeInWei(_address);
            }
        }

        return 0;
    }

    function setTokenName(address _address, uint256 _tokenId, string memory _nftName) public payable {
        uint256 projectFee = getProjectFeeInWei(_address);
        uint256 totalFee = projectFee + baseFee;
        require(msg.value >= totalFee);
        
        uint256 ourFee = totalFee - projectFee;

        if(projectFee > 0) {
            ProjectOwnerServiceInterface ownerService = ProjectOwnerServiceInterface(ownerServiceAddress);
            address projectOwner = ownerService.getProjectOwner(_address);
            addPendingWithdrawal(projectOwner, projectFee);
        }

        addPendingWithdrawal(owner, ourFee);
        _setTokenName(_address, _tokenId, _nftName);
    }

}"},"Ownable.sol":{"content":"pragma solidity 0.8.3;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
"},"ProjectOwnerServiceInterface.sol":{"content":"pragma solidity 0.8.3;

interface ProjectOwnerServiceInterface {

    function getProjectOwner(address _address) external view returns(address);
    
    function getProjectFeeInWei(address _address) external view returns(uint256);

    function isProjectRegistered(address _address) external view returns(bool);

    function isProjectOwnerService() external view returns(bool);

}"},"Withdrawable.sol":{"content":"pragma solidity 0.8.3;

import "./Ownable.sol";

/**
 * @dev Contract that holds pending withdrawals. Responsible for withdrawals.
 */
contract Withdrawable is Ownable {

    mapping(address => uint) private pendingWithdrawals;

    event Withdrawal(address indexed receiver, uint amount);
    event BalanceChanged(address indexed _address, uint oldBalance, uint newBalance);

    /**
    * Returns amount of wei that given address is able to withdraw.
    */
    function getPendingWithdrawal(address _address) public view returns (uint) {
        return pendingWithdrawals[_address];
    }

    /**
    * Add pending withdrawal for an address.
    */
    function addPendingWithdrawal(address _address, uint _amount) internal {
        require(_address != address(0x0));

        uint oldBalance = pendingWithdrawals[_address];
        pendingWithdrawals[_address] += _amount;

        emit BalanceChanged(_address, oldBalance, oldBalance + _amount);
    }

    /**
    * Withdraws all pending withdrawals.
    */
    function withdraw() external {
        uint amount = getPendingWithdrawal(msg.sender);
        require(amount > 0);

        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
        emit BalanceChanged(msg.sender, amount, 0);
    }

}"}}