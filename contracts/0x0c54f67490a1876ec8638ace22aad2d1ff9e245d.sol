pragma solidity 0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


/**
 * @title LUCä»£å¸åçº¦
 */
contract LUC {
    /* å¬å±åé */
    string public name; //ä»£å¸åç§°
    string public symbol; //ä»£å¸ç¬¦å·æ¯å¦'$'
    uint8 public decimals = 4;  //ä»£å¸åä½ï¼å±ç¤ºçå°æ°ç¹åé¢å¤å°ä¸ª0,åé¢æ¯æ¯4ä¸ª0
    uint256 public totalSupply; //ä»£å¸æ»é

    /*è®°å½ææä½é¢çæ å°*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* å¨åºåé¾ä¸åå»ºä¸ä¸ªäºä»¶ï¼ç¨ä»¥éç¥å®¢æ·ç«¯*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //è½¬å¸éç¥äºä»¶
    event Burn(address indexed from, uint256 value);  //åå»ç¨æ·ä½é¢äºä»¶


    /* åå§ååçº¦ï¼å¹¶ä¸æåå§çææä»£å¸é½ç»è¿åçº¦çåå»ºè
     * @param initialSupply ä»£å¸çæ»æ°
     * @param tokenName ä»£å¸åç§°
     * @param tokenSymbol ä»£å¸ç¬¦å·
     */
    constructor(
       uint256 initialSupply, string tokenName, string tokenSymbol
    ) public {
         //åå§åæ»é
        totalSupply = initialSupply * 10 ** uint256(decimals);    //å¸¦çå°æ°çç²¾åº¦

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
      emit  Transfer(_from, _to, _value);

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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
        require(_value <= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * è®¾ç½®å¸æ·åè®¸æ¯ä»çæå¤§éé¢
     *
     * ä¸è¬å¨æºè½åçº¦çæ¶åï¼é¿åæ¯ä»è¿å¤ï¼é æé£é©
     *
     * @param _spender å¸æ·å°å
     * @param _value éé¢
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        //é²æ­¢äºå¡é¡ºåºä¾èµ
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));

        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * è®¾ç½®å¸æ·åè®¸æ¯ä»çæå¤§éé¢
     *
     * ä¸è¬å¨æºè½åçº¦çæ¶åï¼é¿åæ¯ä»è¿å¤ï¼é æé£é©ï¼å å¥æ¶é´åæ°ï¼å¯ä»¥å¨ tokenRecipient ä¸­åå¶ä»æä½
     *
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
     *
     * æä½ä»¥åæ¯ä¸å¯éç
     *
     * @param _value è¦å é¤çæ°é
     */
    function burn(uint256 _value) public returns (bool success) {
        //æ£æ¥å¸æ·ä½é¢æ¯å¦å¤§äºè¦åå»çå¼
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough

        //ç»æå®å¸æ·åå»ä½é¢
        balanceOf[msg.sender] -= _value;

        //ä»£å¸é®é¢åç¸åºæ£é¤
        totalSupply -= _value;

        emit  Burn(msg.sender, _value);
        return true;
    }

    /**
     * å é¤å¸æ·çä½é¢ï¼å«å¶ä»å¸æ·ï¼
     *
     * å é¤ä»¥åæ¯ä¸å¯éç
     *
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
        emit Burn(_from, _value);
        return true;
    }
}