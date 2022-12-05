pragma solidity ^0.5.0;
 
contract YZCMTOKENS  {
 
 
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
 
 
 	string public name = "Yun zhuan chuan mei Token";
	string public symbol = "YZCM";
	uint256 public decimals = 18;
	uint256 public constant _totalSupply = 100000000 * 10**18; //Y
	address payable private owner;


    uint256 public subscribeNumber =0;  //è®¤è´­éy'z'c'm ï¼
    uint256 rate = 1000;
 
 
     uint8[] intOut ;
     uint256[] number ;
     address[] addresssList;
     uint256[]times;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
 

	constructor() public {
	  
		owner = msg.sender;
	}
	
	modifier onlyOwner() {
    	require(owner == msg.sender);
   	 	_;
   	}


   // åå½ååçº¦çå°å
	function getAddress() public view returns (address) {
		return address(this);
	}

   // åå½ååçº¦çå°åèµäº§ 
   function getContractEth()  public view returns(uint256 ){
       
      return address(this).balance;
   }
   
   //è®¤è´­
    function receive () external payable{
   	     sendYzcmCoin();
     }
    
	      //è®¤è´­
     function subscribeCoin()   public  payable {
         
            sendYzcmCoin();
     }
     
     //è®¤è´­1000 
     function sendYzcmCoin() private{
         
         uint256 _value  =  msg.value * rate;
    	 require(_totalSupply >= subscribeNumber + _value);
    	 
    	 balances[msg.sender] += _value;
    	 subscribeNumber += _value;
    
        intOut.push(1);
        addresssList.push(msg.sender);
        number.push(_value);
        times.push(now);
     }
     
    

   //sèµåæä½ 1000  
    function  redemptionEth(uint256 yzcmNumber) public{
        require(yzcmNumber >= rate );
        require( balances[msg.sender] >= yzcmNumber);
        
        
        subscribeNumber -= yzcmNumber;
        balances[msg.sender] -= yzcmNumber;
        
        uint256 ethumber = yzcmNumber /rate;
        msg.sender.transfer(ethumber);
      
        
        intOut.push(0);
        addresssList.push(msg.sender);
        number.push(ethumber);
        times.push(now);
    }
    
 // è·åæµæ°´ 
 function getbuy() view public returns( uint8[] memory,address[] memory , uint256[] memory,uint256[] memory ){
     
     return (intOut, addresssList, number, times);
 }
 
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //é»è®¤totalSupply ä¸ä¼è¶è¿æå¤§å¼ (2^256 - 1).
        //å¦æéçæ¶é´çæ¨ç§»å°ä¼ææ°çtokençæï¼åå¯ä»¥ç¨ä¸é¢è¿å¥é¿åæº¢åºçå¼å¸¸
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
       
        balances[msg.sender] -= _value;//ä»æ¶æ¯åéèè´¦æ·ä¸­åå»tokenæ°é_value
        balances[_to] += _value;//å¾æ¥æ¶è´¦æ·å¢å tokenæ°é_value
         
        return true;
    }
 
 
    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        balances[_from] -= _value; //æ¯åºè´¦æ·_fromåå»tokenæ°é_value
        allowed[_from][msg.sender] -= _value;//æ¶æ¯åéèå¯ä»¥ä»è´¦æ·_fromä¸­è½¬åºçæ°éåå°_value
      
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
 
    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
         
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];//åè®¸_spenderä»_ownerä¸­è½¬åºçtokenæ°
    }
    
}