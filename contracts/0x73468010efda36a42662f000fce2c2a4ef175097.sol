pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract TokenERC20 {
    //ä»¤ççå¬å±åé
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    //åå«ä½æ¯å¼ºçå»ºè®®çé»è®¤å¼ï¼é¿åæ´æ¹å®
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    //è¿å°åå»ºä¸ä¸ªåå«ææä½é¢çæ°ç»
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    //è¿å°å¨åºåé¾ä¸çæä¸ä¸ªå¬å±äºä»¶ï¼è¯¥äºä»¶å°éç¥å®¢æ·ç«¯
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    //è¿å°å¨åºåé¾ä¸çæä¸ä¸ªå¬å±äºä»¶ï¼è¯¥äºä»¶å°éç¥å®¢æ·ç«¯
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    //è¿å°éç¥å®¢æ·ç§æ¯çæ°é
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    /**
     * æé å½æ°
     * Constructor function
     *
     * ä½¿ç¨åå§ä¾åºä»¤çåå§åå¥çº¦ï¼ä»¥åå¥çº¦çåå»ºèæä¾ä»¤ç
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) 
    
    public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * åé¨è½¬è´¦ï¼åªè½ææ¬ååè°ç¨
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        //é²æ­¢ä¼ è¾å°0x0å°åãä½¿ç¨çç§()
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        //æ£æ¥å¯ä»¶äººæ¯å¦æè¶³å¤çé±
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        //æ£æ¥æº¢åº
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        //å°å¶ä¿å­ä¸ºå°æ¥çæ­è¨
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        //åå»åéè
        // Subtract from the sender
        balanceOf[_from] -= _value;
        //åæ¶ä»¶äººæ·»å ç¸åçåå®¹
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        //æ­è¨ç¨äºä½¿ç¨éæåææ¥åç°ä»£ç ä¸­çbugãä»ä»¬ä¸åºè¯¥å¤±è´¥
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * ä¼ éä»¤ç
     * Transfer tokens
     *
     * å°â_valueâä»¤çä»æ¨çå¸æ·åéå°â_toâ
     * Send `_value` tokens to `_to` from your account
     *
     * _toæ¶ä»¶äººçå°å
     * @param _to The address of the recipient
     * 
     * _valueåéçæ°é
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * ä»å¶ä»å°åè½¬ç§»ä»¤ç
     * Transfer tokens from other address
     *
     * ä»£è¡¨â_fromâåâ_toâåéâ_valueâä»¤ç
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     *  _fromåä»¶äººå°å
     * @param _from The address of the sender
     * 
     *  _toæ¶ä»¶äººçå°å
     * @param _to The address of the recipient
     * 
     *  _valueåéçæ°é
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * é¢çå¶ä»å°å
     * Set allowance for other address
     * 
     * åè®¸â_spenderâä»£è¡¨æ¨è±è´¹ä¸è¶è¿â_valueâä»¤ç
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * _spenderææä½¿ç¨çå°å
     * @param _spender The address authorized to spend
     * 
     * _valueä»ä»¬å¯ä»¥è±è´¹çæå¤§éé¢
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * é¢çå¶ä»å°ååéç¥
     * Set allowance for other address and notify 
     * 
     *åè®¸â_spenderâä»£è¡¨æ¨è±è´¹ä¸è¶è¿â_valueâä»¤çï¼ç¶åpingå³äºå®çå¥çº¦
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it 
     * 
     *_spenderææä½¿ç¨çå°å
     * @param _spender The address authorized to spend
     * 
     * _valueä»ä»¬å¯ä»¥è±è´¹çæå¤§éé¢
     * @param _value the max amount they can spend
     * 
     * _ataåæ¹åçåååéä¸äºé¢å¤çä¿¡æ¯
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * æ§æ¯ä»¤ç
     * Destroy tokens
     *
     * ä¸å¯éå°ä»ç³»ç»ä¸­å é¤' _value 'ä»¤ç
     * Remove `_value` tokens from the system irreversibly
     *
     *  _valueè¦ç§çé±çæ°é
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * éæ¯æ¥èªå¶ä»å¸æ·çä»¤ç
     * Destroy tokens from other account
     *
     *ä»£è¡¨â_fromâä¸å¯éå°ä»ç³»ç»ä¸­å é¤â_valueâä»¤çã
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     *  _fromåä»¶äººå°å
     * @param _from the address of the sender
     * 
     * _valueè¦ç§çé±çæ°é
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}