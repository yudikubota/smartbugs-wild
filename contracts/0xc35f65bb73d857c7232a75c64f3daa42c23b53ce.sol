pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;							/* name ä»£å¸åç§° */
    string public symbol;						/* symbol ä»£å¸å¾æ  */
    uint8  public decimals = 18;			/* decimals ä»£å¸å°æ°ç¹ä½æ° */ 
    uint256 public totalSupply;			//ä»£å¸æ»é

    
    /* è®¾ç½®ä¸ä¸ªæ°ç»å­å¨æ¯ä¸ªè´¦æ·çä»£å¸ä¿¡æ¯ï¼åå»ºææè´¦æ·ä½é¢æ°ç» */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    /* eventäºä»¶ï¼å®çä½ç¨æ¯æéå®¢æ·ç«¯åçäºè¿ä¸ªäºä»¶ï¼ä½ ä¼æ³¨æå°é±åææ¶åä¼å¨å³ä¸è§å¼¹åºä¿¡æ¯ */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     /*åå§ååçº¦ï¼å°æåçä»¤çæå¥åå»ºèçè´¦æ·ä¸­*/
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  //ä»¥å¤ªå¸æ¯10^18ï¼åé¢18ä¸ª0ï¼æä»¥é»è®¤decimalsæ¯18,ç»ä»¤çè®¾ç½®18ä½å°æ°çé¿åº¦
        balanceOf[msg.sender] = totalSupply;                		// ç»åå»ºèææåå§ä»¤ç
        name = tokenName;                                   		// è®¾ç½®ä»£å¸ï¼tokenï¼åç§°
        symbol = tokenSymbol;                               		// è®¾ç½®ä»£å¸ï¼tokenï¼ç¬¦å·
    }

    /**
     * Internal transfer, only can be called by this contract
     */
     /**
     * ç§ææ¹æ³ä»ä¸ä¸ªå¸æ·åéç»å¦ä¸ä¸ªå¸æ·ä»£å¸
     * @param  _from address åéä»£å¸çå°å
     * @param  _to address æ¥åä»£å¸çå°å
     * @param  _value uint256 æ¥åä»£å¸çæ°é
     */
    function _transfer(address _from, address _to, uint _value) internal {
    
        // Prevent transfer to 0x0 address. Use burn() instead
        //é¿åè½¬å¸çå°åæ¯0x0
        require(_to != 0x0);
        
        // Check if the sender has enough
        //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
        require(balanceOf[_from] >= _value);
        
        // Check for overflows
        //æ£æ¥æ¯å¦æº¢åº
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        // Save this for an assertion in the future
        //ä¿å­æ°æ®ç¨äºåé¢çå¤æ­
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        // Subtract from the sender
        //ä»åéèåæåéé¢
        balanceOf[_from] -= _value;
        
        // Add the same to the recipient
        //ç»æ¥æ¶èå ä¸ç¸åçé
        balanceOf[_to] += _value;
        
        //éç¥ä»»ä½çå¬è¯¥äº¤æçå®¢æ·ç«¯
        Transfer(_from, _to, _value);
        
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        
        //å¤æ­ä¹°ãååæ¹çæ°æ®æ¯å¦åè½¬æ¢åä¸è´
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    
     /**
     * ä»ä¸»å¸æ·åçº¦è°ç¨èåéç»å«äººä»£å¸
     * @param  _to address æ¥åä»£å¸çå°å
     * @param  _value uint256 æ¥åä»£å¸çæ°é
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     /**
     * ä»æä¸ªæå®çå¸æ·ä¸­ï¼åå¦ä¸ä¸ªå¸æ·åéä»£å¸
     *
     * è°ç¨è¿ç¨ï¼ä¼æ£æ¥è®¾ç½®çåè®¸æå¤§äº¤æé¢
     *
     * @param  _from address åéèå°å
     * @param  _to address æ¥åèå°å
     * @param  _value uint256 è¦è½¬ç§»çä»£å¸æ°é
     * @return success        æ¯å¦äº¤ææå
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

 		/**
     * è®¾ç½®å¸æ·åè®¸æ¯ä»çæå¤§éé¢
     * ä¸è¬å¨æºè½åçº¦çæ¶åï¼é¿åæ¯ä»è¿å¤ï¼é æé£é©
     * @param _spender å¸æ·å°å
     * @param _value éé¢
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

		/**
     * è®¾ç½®å¸æ·åè®¸æ¯ä»çæå¤§éé¢
     * ä¸è¬å¨æºè½åçº¦çæ¶åï¼é¿åæ¯ä»è¿å¤ï¼é æé£é©ï¼å å¥æ¶é´åæ°ï¼å¯ä»¥å¨ tokenRecipient ä¸­åå¶ä»æä½
     * @param _spender å¸æ·å°å
     * @param _value éé¢
     * @param _extraData æä½çæ¶é´
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * åå°ä»£å¸è°ç¨èçä½é¢
     * æä½ä»¥åæ¯ä¸å¯éç
     * @param _value è¦å é¤çæ°é
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * å é¤å¸æ·çä½é¢ï¼å«å¶ä»å¸æ·ï¼
     * å é¤ä»¥åæ¯ä¸å¯éç
     * @param _from è¦æä½çå¸æ·å°å
     * @param _value è¦åå»çæ°é
     */
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