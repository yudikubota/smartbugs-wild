pragma solidity ^0.4.16;
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
/**
 * ownedæ¯åçº¦çç®¡çè
 */
contract owned {
    address public owner;
 
    /**
     * åå°åæé å½æ°
     */
    function owned () public {
        owner = msg.sender;
    }
 
    /**
     * å¤æ­å½ååçº¦è°ç¨èæ¯å¦æ¯åçº¦çææè
     */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * åçº¦çææèææ´¾ä¸ä¸ªæ°çç®¡çå
     * @param  newOwner address æ°çç®¡çåå¸æ·å°å
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
 
/**
 * åºç¡ä»£å¸åçº¦
 */
contract TokenERC20 {
    string public name; //åè¡çä»£å¸åç§°
    string public symbol; //åè¡çä»£å¸ç¬¦å·
    uint8 public decimals = 18;  //ä»£å¸åä½ï¼å±ç¤ºçå°æ°ç¹åé¢å¤å°ä¸ª0ã
    uint256 public totalSupply; //åè¡çä»£å¸æ»é
 
    /*è®°å½ææä½é¢çæ å°*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
 
    /* å¨åºåé¾ä¸åå»ºä¸ä¸ªäºä»¶ï¼ç¨ä»¥éç¥å®¢æ·ç«¯*/
    //è½¬å¸éç¥äºä»¶
    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed from, uint256 value);  //åå»ç¨æ·ä½é¢äºä»¶
 
    /* åå§ååçº¦ï¼å¹¶ä¸æåå§çææä»£å¸é½ç»è¿åçº¦çåå»ºè
     * @param initialSupply ä»£å¸çæ»æ°
     * @param tokenName ä»£å¸åç§°
     * @param tokenSymbol ä»£å¸ç¬¦å·
     */
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        //åå§åæ»é
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        //ç»æå®å¸æ·åå§åä»£å¸æ»éï¼åå§åç¨äºå¥å±åçº¦åå»ºè
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }
 
 
    /**
     * ç§ææ¹æ³ä»ä¸ä¸ªå¸æ·åéç»å¦ä¸ä¸ªå¸æ·ä»£å¸
     * @param  _from address åéä»£å¸çå°å
     * @param  _to address æ¥åä»£å¸çå°å
     * @param  _value uint256 æ¥åä»£å¸çæ°é
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
 
      //é¿åè½¬å¸çå°åæ¯0x0
      require(_to != 0x0);
 
      //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
      require(balanceOf[_from] >= _value);
 
      //æ£æ¥æ¯å¦æº¢åº
      require(balanceOf[_to] + _value > balanceOf[_to]);
 
      //ä¿å­æ°æ®ç¨äºåé¢çå¤æ­
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
 
      //ä»åéèåæåéé¢
      balanceOf[_from] -= _value;
 
      //ç»æ¥æ¶èå ä¸ç¸åçé
      balanceOf[_to] += _value;
 
      //éç¥ä»»ä½çå¬è¯¥äº¤æçå®¢æ·ç«¯
      Transfer(_from, _to, _value);
 
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
     * è°ç¨è¿ç¨ï¼ä¼æ£æ¥è®¾ç½®çåè®¸æå¤§äº¤æé¢
     * @param  _from address åéèå°å
     * @param  _to address æ¥åèå°å
     * @param  _value uint256 è¦è½¬ç§»çä»£å¸æ°é
     * @return success        æ¯å¦äº¤ææå
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
        require(_value <= allowance[_from][msg.sender]);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
        //æ£æ¥å¸æ·ä½é¢æ¯å¦å¤§äºè¦åå»çå¼
        require(balanceOf[msg.sender] >= _value);
        //ç»æå®å¸æ·åå»ä½é¢
        balanceOf[msg.sender] -= _value;
        //ä»£å¸é®é¢åç¸åºæ£é¤
        totalSupply -= _value;
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
        //æ£æ¥å¸æ·ä½é¢æ¯å¦å¤§äºè¦åå»çå¼
        require(balanceOf[_from] >= _value);
        //æ£æ¥ å¶ä»å¸æ· çä½é¢æ¯å¦å¤ä½¿ç¨
        require(_value <= allowance[_from][msg.sender]);
        //åæä»£å¸
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        //æ´æ°æ»é
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}
 
/**
 * ä»£å¸å¢åã
 * ä»£å¸å»ç»ã
 * ä»£å¸èªå¨éå®åè´­ä¹°ã
 * é«çº§ä»£å¸åè½
 */
contract MyAdvancedToken is owned, TokenERC20 {
 
    //ååºçæ±ç,ä¸ä¸ªä»£å¸ï¼å¯ä»¥ååºå¤å°ä¸ªä»¥å¤ªå¸ï¼åä½æ¯wei
    uint256 public sellPrice;
 
    //ä¹°å¥çæ±ç,1ä¸ªä»¥å¤ªå¸ï¼å¯ä»¥ä¹°å ä¸ªä»£å¸
    uint256 public buyPrice;
 
    //æ¯å¦å»ç»å¸æ·çåè¡¨
    mapping (address => bool) public frozenAccount;
 
    //å®ä¹ä¸ä¸ªäºä»¶ï¼å½æèµäº§è¢«å»ç»çæ¶åï¼éç¥æ­£å¨çå¬äºä»¶çå®¢æ·ç«¯
    event FrozenFunds(address target, bool frozen);
 
 
    /*åå§ååçº¦ï¼å¹¶ä¸æåå§çææçä»¤çé½ç»è¿åçº¦çåå»ºè
     * @param initialSupply ææå¸çæ»æ°
     * @param tokenName ä»£å¸åç§°
     * @param tokenSymbol ä»£å¸ç¬¦å·
     */
        function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
 
 
    /**
     * ç§ææ¹æ³ï¼ä»æå®å¸æ·è½¬åºä½é¢
     * @param  _from address åéä»£å¸çå°å
     * @param  _to address æ¥åä»£å¸çå°å
     * @param  _value uint256 æ¥åä»£å¸çæ°é
     */
    function _transfer(address _from, address _to, uint _value) internal {
 
        //é¿åè½¬å¸çå°åæ¯0x0
        require (_to != 0x0);
 
        //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
        require (balanceOf[_from] > _value);
 
        //æ£æ¥æ¯å¦æº¢åº
        require (balanceOf[_to] + _value > balanceOf[_to]);
 
        //æ£æ¥ å»ç»å¸æ·
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
 
        //ä»åéèåæåéé¢
        balanceOf[_from] -= _value;
 
        //ç»æ¥æ¶èå ä¸ç¸åçé
        balanceOf[_to] += _value;
 
        //éç¥ä»»ä½çå¬è¯¥äº¤æçå®¢æ·ç«¯
        Transfer(_from, _to, _value);
 
    }
 
    /**
     * åçº¦æ¥æèï¼å¯ä»¥ä¸ºæå®å¸æ·åé ä¸äºä»£å¸
     * @param  target address å¸æ·å°å
     * @param  mintedAmount uint256 å¢å çéé¢(åä½æ¯wei)
     */
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
 
        //ç»æå®å°åå¢å ä»£å¸ï¼åæ¶æ»éä¹ç¸å 
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
 
 
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
 
    /**
     * å¢å å»ç»å¸æ·åç§°
     *
     * ä½ å¯è½éè¦çç®¡åè½ä»¥ä¾¿ä½ è½æ§å¶è°å¯ä»¥/è°ä¸å¯ä»¥ä½¿ç¨ä½ åå»ºçä»£å¸åçº¦
     *
     * @param  target address å¸æ·å°å
     * @param  freeze bool    æ¯å¦å»ç»
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
 
    /**
     * è®¾ç½®ä¹°åä»·æ ¼
     *
     * å¦æä½ æ³è®©ether(æå¶ä»ä»£å¸)ä¸ºä½ çä»£å¸è¿è¡èä¹¦,ä»¥ä¾¿å¯ä»¥å¸åºä»·èªå¨åä¹°åä»£å¸,æä»¬å¯ä»¥è¿ä¹åãå¦æè¦ä½¿ç¨æµ®å¨çä»·æ ¼ï¼ä¹å¯ä»¥å¨è¿éè®¾ç½®
     *
     * @param newSellPrice æ°çååºä»·æ ¼
     * @param newBuyPrice æ°çä¹°å¥ä»·æ ¼
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
 
    /**
     * ä½¿ç¨ä»¥å¤ªå¸è´­ä¹°ä»£å¸
     */
    function buy() payable public {
      uint amount = msg.value / buyPrice;
 
      _transfer(this, msg.sender, amount);
    }
 
    /**
     * @dev ååºä»£å¸
     * @return è¦ååºçæ°é(åä½æ¯wei)
     */
    function sell(uint256 amount) public {
 
        //æ£æ¥åçº¦çä½é¢æ¯å¦åè¶³
        require(this.balance >= amount * sellPrice);
 
        _transfer(msg.sender, this, amount);
 
        msg.sender.transfer(amount * sellPrice);
    }
}