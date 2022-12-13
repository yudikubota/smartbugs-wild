{"CryptoCapsule.sol":{"content":"pragma solidity >=0.4.21 <0.6.6;
import "./Owner.sol";

contract CryptoCapsule is Owner {
    
    
    event NewLaunch(uint _capsuleId, uint _token);
    
    uint private launchFee;
    
    struct Capsule {
        uint key;
        string content;
        uint64 closedUntil;
        uint64 launchTime;
        bool isSealed;
    }
    
    Capsule[] private capsules;
    
    mapping(uint => address) public capsuleToOwner;
    mapping(address => uint) public capsuleOwnerCount;
    
   function launch (uint  _key, string calldata _content, uint64 _closedUntil, uint64 _launchTime, uint _token) external payable { 
        require(msg.value >= launchFee);
        capsules.push(Capsule(_key, _content, _closedUntil, _launchTime, false));
        uint capsuleId = capsules.length - 1;
        capsuleToOwner[capsuleId] = msg.sender;
        capsuleOwnerCount[msg.sender]++;
        emit NewLaunch(capsuleId, _token);
    }
    
    function open(uint _key, uint _id) external view returns (string memory _content, uint _launchTime, uint _closedUntil){
        Capsule storage capsule = capsules[_id];
        string memory content;
        require(!capsule.isSealed, "This capsule was sealed!");
        require(_key == capsules[_id].key, "No capsule found for this Key!");
        if (capsule.closedUntil > now) {
            content = "error";
        }else{
            content = capsule.content;
        }
        return (content, capsule.launchTime, capsule.closedUntil);
    }
    
    function seal(uint _key, uint _id) external{
        require(msg.sender == capsuleToOwner[_id], "You are not the owner!");
        Capsule storage capsule = capsules[_id];
        require(!capsule.isSealed, "This capsule has already been sealed!");
        require(_key == capsule.key, "No capsule found for this Key!");
        capsule.isSealed = true;
        
    }
    
    function setFee (uint _launchFee) external isOwner {
        launchFee = _launchFee;
    }
    
    function getFee() external view returns (uint _data) {
        return launchFee;
    }
    
    function getNum() external view  returns (uint _data) {
        return capsules.length;
    }
    
    function getBalance() external view isOwner returns (uint _data){
        return address(this).balance;
    }
    
     function withdraw(address payable _address) external isOwner {
        _address.transfer(address(this).balance);
        
    }
    
    
}"},"Owner.sol":{"content":"pragma solidity >=0.4.21 <0.7.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}"}}