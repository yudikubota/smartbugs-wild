/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity >=0.4.25 <0.7.0;


/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint value) public;
    
    
}
//æ¥å¿æå° 
contract Console {
    event LogUint(string, uint);
    function log(string s , uint x) internal {
    emit LogUint(s, x);
    }
    
    event LogInt(string, int);
    function log(string s , int x) internal {
    emit LogInt(s, x);
    }
    
    event LogBytes(string, bytes);
    function log(string s , bytes x) internal {
    emit LogBytes(s, x);
    }
    
    event LogBytes32(string, bytes32);
    function log(string s , bytes32 x) internal {
    emit LogBytes32(s, x);
    }

    event LogAddress(string, address);
    function log(string s , address x) internal {
    emit LogAddress(s, x);
    }

    event LogBool(string, bool);
    function log(string s , bool x) internal {
    emit LogBool(s, x);
    }
}
contract Ownable{
    address public owner;
    //åå§åç®¡çåå°å
    mapping (address => bool) public AdminAccounts;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
      * @dev éªè¯åçº¦æ¥æè
      */
    modifier onlyOwner() {
        require(msg.sender == owner || AdminAccounts[msg.sender]);
        _;
    }
    /**
      * @dev éªè¯ç®¡çå
      */
    modifier onlyAdmin() {
        require(AdminAccounts[msg.sender] = true);
        _;
    }
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return AdminAccounts[_maker];
    }
    
    /**
    * @dev è½¬è®©åçº¦
    * @param newOwner æ°æ¥æèå°å
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    //æ¥æèæç®¡çåæååçº¦ä½é¢
    function OwnerCharge() public payable onlyOwner {
        owner.transfer(this.balance);
    }
    //æåå°æå®å°å
    function OwnerChargeTo(address _address) public payable returns(bool){
        if(msg.sender == owner || AdminAccounts[msg.sender]){
             _address.transfer(this.balance);
             return true;
        }
       return false;
    }
    //æ·»å ç®¡çåå°å
    function addAdminList (address _evilUser) public onlyOwner {
            AdminAccounts[_evilUser] = true;
            AddedAdminList(_evilUser);
        
    }

    function removeAdminList (address _clearedUser) public onlyOwner {
            AdminAccounts[_clearedUser] = false;
            RemovedAdminList(_clearedUser);
    }

    event AddedAdminList(address _user);

    event RemovedAdminList(address _user);
}

contract Transit is Console,Ownable{

  using SafeMath256 for uint256;
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
    address public AdminAddress;
    function Transit(address Admin) public{
        AdminAccounts[Admin] = true;
    }
    //æ¥è¯¢å½åçä½é¢
    function getBalance() constant returns(uint){
        return this.balance;
    }
    //æ¹éä¸­ä¸æ é®é¢ï¼ä½è°ç¨åçº¦éé¢çtokenå°æå®çå°åä¼é»è®¤è½¬å°0x1da73c4ec1355f953ad0aaca3ef20e342aea92a ä¸ç¥æ¯ä»ä¹é®é¢  ææ¶åç¨withdraw
    function batchTtransferEther(address[]  _to,uint256[] _value) public payable {
        require(_to.length>0);

        for(uint256 i=0;i<_to.length;i++)
        {
            _to[i].transfer(_value[i]);
        }
    }

    //æ¹éè½¬ä»£å¸ #å¤æå®éé¢
    function batchTransferVoken(address from,address caddress,address[] _to,uint256[] _value)public returns (bool){
        require(_to.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<_to.length;i++){
            caddress.call(id,from,_to[i],_value[i]);
        }
        return true;
    }
	//æ¹éè½¬usdt
	function forecchusdt(address from,address caddress,address[] _to,uint256[] _value)public payable{
        require(_to.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<_to.length;i++){
            caddress.call(id,from,_to[i],_value[i]);
        }
    }
    //åå¸å·æ¹éå½é æå®åçº¦ä»£å¸Arrayï¼æç§åéäº¤æçå¸å·
    function tosonfrom(address from,address[] tc_address,uint256[] t_value,uint256 e_value)public payable{
        log("address=>",from);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i=0;i<tc_address.length;i++){
            tc_address[i].call(id,msg.sender,from,t_value[i]);
        }
        from.transfer(e_value);
    }

}