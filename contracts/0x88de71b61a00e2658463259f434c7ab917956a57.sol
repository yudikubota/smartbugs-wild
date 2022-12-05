pragma solidity ^0.4.25;

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    /**
     * åå§åæé 
     */
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // ä¾åºçä»½é¢ï¼ä»½é¢è·æå°çä»£å¸åä½æå³ï¼ä»½é¢ = å¸æ° * 10 ** decimalsã
        balanceOf[msg.sender] = totalSupply;                // åå»ºèæ¥æææçä»£å¸
        name = tokenName;                                   // ä»£å¸åç§°
        symbol = tokenSymbol;                               // ä»£å¸ç¬¦å·
    }

    /**
     * ä»£å¸äº¤æè½¬ç§»çåé¨å®ç°
     */
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

    /**
     *  ä»£å¸äº¤æè½¬ç§»
     *  ä»èªå·±ï¼åå»ºäº¤æèï¼è´¦å·åé`_value`ä¸ªä»£å¸å° `_to`è´¦å·
     * ERC20æ å
     * @param _to æ¥æ¶èå°å
     * @param _value è½¬ç§»æ°é¢
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * è´¦å·ä¹é´ä»£å¸äº¤æè½¬ç§»
     * ERC20æ å
     * @param _from åéèå°å
     * @param _to æ¥æ¶èå°å
     * @param _value è½¬ç§»æ°é¢
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * è®¾ç½®æä¸ªå°åï¼åçº¦ï¼å¯ä»¥åå»ºäº¤æèåä¹è±è´¹çä»£å¸æ°ã
     *
     * åè®¸åéè`_spender` è±è´¹ä¸å¤äº `_value` ä¸ªä»£å¸
     * ERC20æ å
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}