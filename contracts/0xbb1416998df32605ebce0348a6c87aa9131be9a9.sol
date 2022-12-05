{"ballot.sol":{"content":"pragma solidity ^0.4.19;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;

	// ï¿½ï¿½mappingï¿½ï¿½ï¿½ï¿½Ã¿ï¿½ï¿½ï¿½ï¿½Ö·ï¿½ï¿½Ó¦ï¿½ï¿½ï¿½ï¿½ï¿½
	mapping (address => uint256) public balanceOf;
	// ï¿½æ´¢ï¿½ï¿½ï¿½ËºÅµÄ¿ï¿½ï¿½ï¿½
	mapping (address => mapping (address => uint256)) public allowance;
	// ï¿½Â¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í¨Öªï¿½Í»ï¿½ï¿½Ë½ï¿½ï¿½×·ï¿½ï¿½ï¿½
	event Transfer(address indexed from, address indexed to, uint256 value);
	// ï¿½Â¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í¨Öªï¿½Í»ï¿½ï¿½Ë´ï¿½ï¿½Ò±ï¿½ï¿½ï¿½ï¿½ï¿½
	event Burn(address indexed from, uint256 value);
	
	/*
	*ï¿½ï¿½Ê¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	*/
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // ï¿½ï¿½Ó¦ï¿½Ä·Ý¶î£¬ï¿½Ý¶ï¿½ï¿½ï¿½ï¿½Ð¡ï¿½Ä´ï¿½ï¿½Òµï¿½Î»ï¿½Ð¹Ø£ï¿½ï¿½Ý¶ï¿½ = ï¿½ï¿½
		balanceOf[msg.sender] = totalSupply;                // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Óµï¿½ï¿½ï¿½ï¿½ï¿½ÐµÄ´ï¿½ï¿½ï¿½
		name = tokenName;                                   // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		symbol = tokenSymbol;                               // ï¿½ï¿½ï¿½Ò·ï¿½ï¿½ï¿½
}

	//ï¿½ï¿½ï¿½Ò½ï¿½ï¿½ï¿½×ªï¿½Æµï¿½ï¿½Ú²ï¿½Êµï¿½ï¿½
	function _transfer(address _from, address _to, uint _value) internal {
		// È·ï¿½ï¿½Ä¿ï¿½ï¿½ï¿½Ö·ï¿½ï¿½Îª0x0ï¿½ï¿½ï¿½ï¿½Îª0x0ï¿½ï¿½Ö·ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		require(_to != 0x0);
		// ï¿½ï¿½é·¢ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		require(balanceOf[_from] >= _value);
		// È·ï¿½ï¿½×ªï¿½ï¿½Îªï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		require(balanceOf[_to] + _value > balanceOf[_to]);
		
		// ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½é½»ï¿½×£ï¿½
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		// Subtract from the sender
		balanceOf[_from] -= _value;
		
		// Add the same to the recipient
		balanceOf[_to] += _value;
		Transfer(_from, _to, _value);
		
		// ï¿½ï¿½assertï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß¼ï¿½ï¿½ï¿½
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}

	/*****
	**ï¿½ï¿½ï¿½Ò½ï¿½ï¿½ï¿½×ªï¿½ï¿½
	**ï¿½ï¿½ï¿½Ô¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß£ï¿½ï¿½ËºÅ·ï¿½ï¿½ï¿½`_value`ï¿½ï¿½ï¿½ï¿½ï¿½Òµï¿½ `_to`ï¿½Ëºï¿½
	**@param _to ï¿½ï¿½ï¿½ï¿½ï¿½ßµï¿½Ö·
	**@param _value ×ªï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	**/
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	 }
	 
	 /*****
	**ï¿½Ëºï¿½Ö®ï¿½ï¿½ï¿½ï¿½Ò½ï¿½ï¿½ï¿½×ªï¿½ï¿½
	**@param _from ï¿½ï¿½ï¿½ï¿½ï¿½ßµï¿½Ö·
	**@param _to ï¿½ï¿½ï¿½ï¿½ï¿½ßµï¿½Ö·
	**@param _value ×ªï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	**/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);     // Check allowance
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}
	 /*****
	**ï¿½ï¿½ï¿½ï¿½Ä³ï¿½ï¿½ï¿½ï¿½Ö·ï¿½ï¿½ï¿½ï¿½Ô¼ï¿½ï¿½ï¿½ï¿½ï¿½Ô´ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½å»¨ï¿½ÑµÄ´ï¿½ï¿½ï¿½ï¿½ï¿½
	**ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½`_spender` ï¿½ï¿½ï¿½Ñ²ï¿½ï¿½ï¿½ï¿½ï¿½ `_value` ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	**@param _spender The address authorized to spend
	**@param _value the max amount they can spend
	**/
	function approve(address _spender, uint256 _value) public
		returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	/*****
	**ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ò»ï¿½ï¿½ï¿½ï¿½Ö·ï¿½ï¿½ï¿½ï¿½Ô¼ï¿½ï¿½ï¿½ï¿½ï¿½Ò£ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß£ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½à»¨ï¿½ÑµÄ´ï¿½ï¿½ï¿½ï¿½ï¿½
	**@param _spender ï¿½ï¿½ï¿½ï¿½È¨ï¿½Äµï¿½Ö·ï¿½ï¿½ï¿½ï¿½Ô¼ï¿½ï¿½
	**@param _value ï¿½ï¿½ï¿½É»ï¿½ï¿½Ñ´ï¿½ï¿½ï¿½ï¿½ï¿½
	**@param _extraData ï¿½ï¿½ï¿½Í¸ï¿½ï¿½ï¿½Ô¼ï¿½Ä¸ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	**/
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	 public
	 returns (bool success) {
	 tokenRecipient spender = tokenRecipient(_spender);
	 if (approve(_spender, _value)) {
		// Í¨Öªï¿½ï¿½Ô¼
		spender.receiveApproval(msg.sender, _value, this, _extraData);
		return true;
		}
	 }
	///ï¿½ï¿½ï¿½ï¿½ï¿½Ò£ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß£ï¿½ï¿½Ë»ï¿½ï¿½ï¿½Ö¸ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
		balanceOf[msg.sender] -= _value;            // Subtract from the sender
		totalSupply -= _value;                      // Updates totalSupply
		Burn(msg.sender, _value);
		return true;
	}
	/*****
	**ï¿½ï¿½ï¿½ï¿½ï¿½Ã»ï¿½ï¿½Ë»ï¿½ï¿½ï¿½Ö¸ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	**Remove `_value` tokens from the system irreversibly on behalf of `_from
	**@param _from the address of the sender
	**@param _value the amount of money to burn
	**/
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
		require(_value <= allowance[_from][msg.sender]);    // Check allowance
		balanceOf[_from] -= _value;                         // Subtract from the targeted balance
		allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
		totalSupply -= _value;                              // Update totalSupply
		Burn(_from, _value);
		return true;
	}
}






pragma solidity ^0.4.19;
 
contract Token {
    /// tokenï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ä¬ï¿½Ï»ï¿½Îªpublicï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ò»ï¿½ï¿½getterï¿½ï¿½ï¿½ï¿½ï¿½Ó¿Ú£ï¿½ï¿½ï¿½ï¿½ï¿½ÎªtotalSupply().
    uint256 public totalSupply;
 
    /// ï¿½ï¿½È¡ï¿½Ë»ï¿½_ownerÓµï¿½ï¿½tokenï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    //ï¿½ï¿½ï¿½ï¿½Ï¢ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ë»ï¿½ï¿½ï¿½ï¿½ï¿½_toï¿½Ë»ï¿½×ªï¿½ï¿½ï¿½ï¿½Îª_valueï¿½ï¿½token
    function transfer(address _to, uint256 _value) returns (bool success);
 
    //ï¿½ï¿½ï¿½Ë»ï¿½_fromï¿½ï¿½ï¿½ï¿½ï¿½Ë»ï¿½_to×ªï¿½ï¿½ï¿½ï¿½Îª_valueï¿½ï¿½tokenï¿½ï¿½ï¿½ï¿½approveï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¹ï¿½ï¿½
    function transferFrom(address _from, address _to, uint256 _value) returns  (bool success);
 
    //ï¿½ï¿½Ï¢ï¿½ï¿½ï¿½ï¿½ï¿½Ë»ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ë»ï¿½_spenderï¿½Ü´Ó·ï¿½ï¿½ï¿½ï¿½Ë»ï¿½ï¿½ï¿½×ªï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Îª_valueï¿½ï¿½token
    function approve(address _spender, uint256 _value) returns (bool success);
 
    //ï¿½ï¿½È¡ï¿½Ë»ï¿½_spenderï¿½ï¿½ï¿½Ô´ï¿½ï¿½Ë»ï¿½_ownerï¿½ï¿½×ªï¿½ï¿½tokenï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
    function allowance(address _owner, address _spender) constant returns  (uint256 remaining);
 
    //ï¿½ï¿½ï¿½ï¿½×ªï¿½ï¿½Ê±ï¿½ï¿½ï¿½ï¿½Òªï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Â¼ï¿½ 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    //ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½approve(address _spender, uint256 _value)ï¿½É¹ï¿½Ö´ï¿½ï¿½Ê±ï¿½ï¿½ï¿½ë´¥ï¿½ï¿½ï¿½ï¿½ï¿½Â¼ï¿½
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


"},"TokenERC20.sol":{"content":"pragma solidity ^0.4.19;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;

	// ï¿½ï¿½mappingï¿½ï¿½ï¿½ï¿½Ã¿ï¿½ï¿½ï¿½ï¿½Ö·ï¿½ï¿½Ó¦ï¿½ï¿½ï¿½ï¿½ï¿½
	mapping (address => uint256) public balanceOf;
	// ï¿½æ´¢ï¿½ï¿½ï¿½ËºÅµÄ¿ï¿½ï¿½ï¿½
	mapping (address => mapping (address => uint256)) public allowance;
	// ï¿½Â¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í¨Öªï¿½Í»ï¿½ï¿½Ë½ï¿½ï¿½×·ï¿½ï¿½ï¿½
	event Transfer(address indexed from, address indexed to, uint256 value);
	// ï¿½Â¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Í¨Öªï¿½Í»ï¿½ï¿½Ë´ï¿½ï¿½Ò±ï¿½ï¿½ï¿½ï¿½ï¿½
	event Burn(address indexed from, uint256 value);
	
	/*
	*ï¿½ï¿½Ê¼ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
	*/
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // ï¿½ï¿½Ó¦ï¿½Ä·Ý¶î£¬ï¿½Ý¶ï¿½ï¿½ï¿½ï¿½Ð¡ï¿½Ä´ï¿½ï¿½Òµï¿½Î»ï¿½Ð¹Ø£ï¿½ï¿½Ý¶ï¿½ = ï¿½ï¿½
		balanceOf[msg.sender] = totalSupply;                // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Óµï¿½ï¿½ï¿½ï¿½ï¿½ÐµÄ´ï¿½ï¿½ï¿½
		name = tokenName;                                   // ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
		symbol = tokenSymbol;                               // ï¿½ï¿½ï¿½Ò·ï¿½ï¿½ï¿½
}
}"}}