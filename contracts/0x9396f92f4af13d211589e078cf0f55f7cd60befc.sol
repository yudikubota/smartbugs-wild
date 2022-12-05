pragma solidity ^0.4.16;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
 contract TokenERC20 {
    // tokenæ»éï¼é»è®¤ä¼ä¸ºpublicåéçæä¸ä¸ªgetterå½æ°æ¥å£ï¼åç§°ä¸ºtotalSupply().
 //   uint256 public totalSupply;

    // è·åè´¦æ·_owneræ¥ætokençæ°é 
//    function balanceOf(address _owner) constant returns (uint256 balance);

    //ä»æ¶æ¯åéèè´¦æ·ä¸­å¾_toè´¦æ·è½¬æ°éä¸º_valueçtoken
  //  function transfer(address _to, uint256 _value) returns (bool success);

    //ä»è´¦æ·_fromä¸­å¾è´¦æ·_toè½¬æ°éä¸º_valueçtokenï¼ä¸approveæ¹æ³éåä½¿ç¨
  //  function transferFrom(address _from, address _to, uint256 _value) returns   
    //(bool success);

    //æ¶æ¯åéè´¦æ·è®¾ç½®è´¦æ·_spenderè½ä»åéè´¦æ·ä¸­è½¬åºæ°éä¸º_valueçtoken
   // function approve(address _spender, uint256 _value) returns (bool success);

    //è·åè´¦æ·_spenderå¯ä»¥ä»è´¦æ·_ownerä¸­è½¬åºtokençæ°é
   // function allowance(address _owner, address _spender) constant returns 
    //(uint256 remaining);

    //åçè½¬è´¦æ¶å¿é¡»è¦è§¦åçäºä»¶ 
   // event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //å½å½æ°approve(address _spender, uint256 _value)æåæ§è¡æ¶å¿é¡»è§¦åçäºä»¶
   // event Approval(address indexed _owner, address indexed _spender, uint256 
   // _value);
string public name;
string public symbol;
uint8 public decimals = 5; 
uint256 public totalSupply;
mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;
event Transfer(address indexed from, address indexed to, uint256 value);
event Burn(address indexed from, uint256 value);
function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
	totalSupply = initialSupply * 10 ** uint256(decimals); 
	balanceOf[msg.sender] = totalSupply;       
	name = tokenName;                     
	symbol = tokenSymbol;                 
}


    /**
     * Internal transfer, only can be called by this contract
     */

function _transfer(address _from, address _to, uint _value) internal {
	require(_to != 0x0);
	require(balanceOf[_from] >= _value); // Update total supply with the decimal amount
	require(balanceOf[_to] + _value > balanceOf[_to]);
	uint previousBalances = balanceOf[_from] + balanceOf[_to];
	balanceOf[_from] -= _value;
	balanceOf[_to] += _value; // Update total supply with the decimal amount
	Transfer(_from, _to, _value);
	assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}
function transfer(address _to, uint256 _value) public {
	_transfer(msg.sender, _to, _value);
}
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	require(_value <= allowance[_from][msg.sender]);     // Check allowance
	allowance[_from][msg.sender] -= _value;
	_transfer(_from, _to, _value); // Update total supply with the decimal amount
	return true;
}

    /**
     * Internal transfer, only can be called by this contract
     */

function approve(address _spender, uint256 _value) public
returns (bool success) {
	allowance[msg.sender][_spender] = _value;  // Set the symbol for display purposes
	return true;
}


function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	public
	returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;  // Set the symbol for display purposes
		}
	}

function burn(uint256 _value) public returns (bool success) {
	require(balanceOf[msg.sender] >= _value);    // Set the symbol for display purposes
	balanceOf[msg.sender] -= _value;            // Set the symbol for display purposes
	totalSupply -= _value;               
	Burn(msg.sender, _value);  // Set the symbol for display purposes
	return true;
}

function burnFrom(address _from, uint256 _value) public returns (bool success) {
	require(balanceOf[_from] >= _value);         // Set the symbol for display purposes
	require(_value <= allowance[_from][msg.sender]);  
	balanceOf[_from] -= _value;          
	allowance[_from][msg.sender] -= _value;   // Set the symbol for display purposes
	totalSupply -= _value;            
	Burn(_from, _value);  // Set the symbol for display purposes
	return true;
}
}