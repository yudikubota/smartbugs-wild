pragma solidity ^0.4.19;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;

	// ç¨mappingä¿å­æ¯ä¸ªå°åå¯¹åºçä½é¢
	mapping (address => uint256) public balanceOf;
	// å­å¨å¯¹è´¦å·çæ§å¶
	mapping (address => mapping (address => uint256)) public allowance;
	// äºä»¶ï¼ç¨æ¥éç¥å®¢æ·ç«¯äº¤æåç
	event Transfer(address indexed from, address indexed to, uint256 value);
	// äºä»¶ï¼ç¨æ¥éç¥å®¢æ·ç«¯ä»£å¸è¢«æ¶è´¹
	event Burn(address indexed from, uint256 value);
	
	/*
	*åå§åæé 
	*/
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // ä¾åºçä»½é¢ï¼ä»½é¢è·æå°çä»£å¸åä½æå³ï¼ä»½é¢ = å¸
		balanceOf[msg.sender] = totalSupply;                // åå»ºèæ¥æææçä»£å¸
		name = tokenName;                                   // ä»£å¸åç§°
		symbol = tokenSymbol;                               // ä»£å¸ç¬¦å·
}

	//ä»£å¸äº¤æè½¬ç§»çåé¨å®ç°
	function _transfer(address _from, address _to, uint _value) internal {
		// ç¡®ä¿ç®æ å°åä¸ä¸º0x0ï¼å ä¸º0x0å°åä»£è¡¨éæ¯
		require(_to != 0x0);
		// æ£æ¥åéèä½é¢
		require(balanceOf[_from] >= _value);
		// ç¡®ä¿è½¬ç§»ä¸ºæ­£æ°ä¸ª
		require(balanceOf[_to] + _value > balanceOf[_to]);
		
		// ä»¥ä¸ç¨æ¥æ£æ¥äº¤æï¼
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		// Subtract from the sender
		balanceOf[_from] -= _value;
		
		// Add the same to the recipient
		balanceOf[_to] += _value;
		Transfer(_from, _to, _value);
		
		// ç¨assertæ¥æ£æ¥ä»£ç é»è¾ã
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}

	/*****
	**ä»£å¸äº¤æè½¬ç§»
	**ä»èªå·±ï¼åå»ºäº¤æèï¼è´¦å·åé`_value`ä¸ªä»£å¸å° `_to`è´¦å·
	**@param _to æ¥æ¶èå°å
	**@param _value è½¬ç§»æ°é¢
	**/
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	 }
	 
	 /*****
	**è´¦å·ä¹é´ä»£å¸äº¤æè½¬ç§»
	**@param _from åéèå°å
	**@param _to æ¥æ¶èå°å
	**@param _value è½¬ç§»æ°é¢
	**/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);     // Check allowance
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}
	 /*****
	**è®¾ç½®æä¸ªå°åï¼åçº¦ï¼å¯ä»¥åå»ºäº¤æèåä¹è±è´¹çä»£å¸æ°
	**åè®¸åéè`_spender` è±è´¹ä¸å¤äº `_value` ä¸ªä»£å¸
	**@param _spender The address authorized to spend
	**@param _value the max amount they can spend
	**/
	function approve(address _spender, uint256 _value) public
		returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	/*****
	**è®¾ç½®åè®¸ä¸ä¸ªå°åï¼åçº¦ï¼ä»¥æï¼åå»ºäº¤æèï¼çåä¹å¯æå¤è±è´¹çä»£å¸æ°
	**@param _spender è¢«ææçå°åï¼åçº¦ï¼
	**@param _value æå¤§å¯è±è´¹ä»£å¸æ°
	**@param _extraData åéç»åçº¦çéå æ°æ®
	**/
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	 public
	 returns (bool success) {
	 tokenRecipient spender = tokenRecipient(_spender);
	 if (approve(_spender, _value)) {
		// éç¥åçº¦
		spender.receiveApproval(msg.sender, _value, this, _extraData);
		return true;
		}
	 }
	///éæ¯æï¼åå»ºäº¤æèï¼è´¦æ·ä¸­æå®ä¸ªä»£å¸
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
		balanceOf[msg.sender] -= _value;            // Subtract from the sender
		totalSupply -= _value;                      // Updates totalSupply
		Burn(msg.sender, _value);
		return true;
	}
	/*****
	**éæ¯ç¨æ·è´¦æ·ä¸­æå®ä¸ªä»£å¸
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
    /// tokenæ»éï¼é»è®¤ä¼ä¸ºpublicåéçæä¸ä¸ªgetterå½æ°æ¥å£ï¼åç§°ä¸ºtotalSupply().
    uint256 public totalSupply;
 
    /// è·åè´¦æ·_owneræ¥ætokençæ°é
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    //ä»æ¶æ¯åéèè´¦æ·ä¸­å¾_toè´¦æ·è½¬æ°éä¸º_valueçtoken
    function transfer(address _to, uint256 _value) returns (bool success);
 
    //ä»è´¦æ·_fromä¸­å¾è´¦æ·_toè½¬æ°éä¸º_valueçtokenï¼ä¸approveæ¹æ³éåä½¿ç¨
    function transferFrom(address _from, address _to, uint256 _value) returns  (bool success);
 
    //æ¶æ¯åéè´¦æ·è®¾ç½®è´¦æ·_spenderè½ä»åéè´¦æ·ä¸­è½¬åºæ°éä¸º_valueçtoken
    function approve(address _spender, uint256 _value) returns (bool success);
 
    //è·åè´¦æ·_spenderå¯ä»¥ä»è´¦æ·_ownerä¸­è½¬åºtokençæ°é
    function allowance(address _owner, address _spender) constant returns  (uint256 remaining);
 
    //åçè½¬è´¦æ¶å¿é¡»è¦è§¦åçäºä»¶ 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    //å½å½æ°approve(address _spender, uint256 _value)æåæ§è¡æ¶å¿é¡»è§¦åçäºä»¶
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}