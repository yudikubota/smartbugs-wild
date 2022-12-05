pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
 
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b);
 
        return c;
    }
 
    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
        return c;
    }
 
    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
 
        return c;
    }
 
    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
 
        return c;
    }
 
    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
 
contract ERC20Interface {
      function totalSupply() public  constant returns (uint totalSupply); //è¿åæ»éé¢
      function balanceOf(address _owner) public constant returns (uint balance);//è¿åå°åè´¦æ·éé¢æ»æ°
      function transfer(address _to, uint _value) public returns (bool success);//è½¬è´¦
      function transferFrom(address _from, address _to, uint _value) public returns (bool success);//ææä¹åæè½è½¬è´¦
      function approve(address _spender, uint _value) public returns (bool success);//è´¦æ·ææ
      function allowance(address _owner, address _spender) public constant returns (uint remaining);//ææéé¢
      event Transfer(address indexed _from, address indexed _to, uint _value);
      event Approval(address indexed _owner, address indexed _spender, uint _value);
    }
 
 
 
/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
/**
* @dev The Ownable constructor sets the original `owner` of the contract to the sender
* account.
*/
    function Ownable() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
 
}
 
contract SLOToken is ERC20Interface,Ownable {
    string public symbol; //ä»£å¸ç¬¦å·
    string public name;   //ä»£å¸åç§°
    
    uint8 public decimal; //ç²¾ç¡®å°æ°ä½
    uint public _totalSupply; //æ»çåè¡ä»£å¸æ°
    
    mapping(address => uint) balances; //å°åæ å°éé¢æ°
    mapping(address =>mapping(address =>uint)) allowed; //ææå°åä½¿ç¨éé¢ç»å®
    
 
    //å¼å¥safemath ç±»åº
    using SafeMath for uint;
    
    //æé å½æ°
    //function LOPOToken() public{
    function SLOToken() public{
        symbol = "SLOT";
        name = "Alphaslot";
        decimal = 18;
        _totalSupply = 1000000000000000000000000000;
        balances[msg.sender]=_totalSupply;//ç»åéèå°åææéé¢
        Transfer(address(0),msg.sender,_totalSupply );//è½¬è´¦äºä»¶
    }
 
    function totalSupply() public constant returns (uint totalSupply){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint balance){
        return balances[_owner];
    }
 
    function transfer(address _to, uint _value) public returns (bool success){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender,_to,_value);
        return true;
    }
 
    function approve(address _spender, uint _value) public returns (bool success){
        allowed[msg.sender][_spender]=_value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) public constant returns (uint remaining){
        return allowed[_owner][_spender];
    }
 
    function transferFrom(address _from, address _to, uint _value) public returns (bool success){
        allowed[_from][_to] = allowed[_from][_to].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from,_to,_value);
        return true;
    }
 
    //å¿åå½æ°åæ» ç¦æ­¢è½¬è´¦ç»me
    function() payable {
        revert();
    }

 
    //è½¬è´¦ç»ä»»ä½åçº¦
    function transferAnyERC20Token(address tokenaddress,uint tokens) public onlyOwner returns(bool success){
        ERC20Interface(tokenaddress).transfer(msg.sender,tokens);
    }
}