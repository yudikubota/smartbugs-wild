pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/**
 * æ å ERC-20-2 åçº¦
 */
contract ERC_20_2 {
    //- Token åç§°
    string public name; 
    //- Token ç¬¦å·
    string public symbol;
    //- Token å°æ°ä½
    uint8 public decimals;
    //- Token æ»åè¡é
    uint256 public totalSupply;
    //- åçº¦éå®ç¶æ
    bool public lockAll = false;
    //- åçº¦åé è
    address public creator;
    //- åçº¦ææè
    address public owner;
    //- åçº¦æ°ææè
    address internal newOwner = 0x0;

    //- å°åæ å°å³ç³»
    mapping (address => uint256) public balanceOf;
    //- å°åå¯¹åº Token
    mapping (address => mapping (address => uint256)) public allowance;
    //- å»ç»åè¡¨
    mapping (address => bool) public frozens;

    //- Token äº¤æéç¥äºä»¶
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //- Token äº¤ææ©å±éç¥äºä»¶
    event TransferExtra(address indexed _from, address indexed _to, uint256 _value, bytes _extraData);
    //- Token æ¹åéç¥äºä»¶
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //- Token æ¶èéç¥äºä»¶
    event Burn(address indexed _from, uint256 _value);
    //- Token å¢ééç¥äºä»¶
    event Offer(uint256 _supplyTM);
    //- åçº¦ææèåæ´éç¥
    event OwnerChanged(address _oldOwner, address _newOwner);
    //- å°åå»ç»éç¥
    event FreezeAddress(address indexed _target, bool _frozen);

    /**
     * æé å½æ°
     *
     * åå§åä¸ä¸ªåçº¦
     * @param initialSupplyHM åå§æ»éï¼åä½ç¾ä¸ï¼
     * @param tokenName Token åç§°
     * @param tokenSymbol Token ç¬¦å·
     * @param tokenDecimals Token å°æ°ä½
     */
    constructor(uint256 initialSupplyHM, string tokenName, string tokenSymbol, uint8 tokenDecimals) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        totalSupply = initialSupplyHM * 100 * 10000 * 10 ** uint256(decimals);
        
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        creator = msg.sender;
    }

    /**
     * ææèä¿®é¥°ç¬¦
     */
    modifier onlyOwner {
        require(msg.sender == owner, "éæ³åçº¦æ§è¡è");
        _;
    }
	
    /**
     * å¢å åè¡é
     * @param _supplyTM å¢éï¼åä½åä¸ï¼
     */
    function offer(uint256 _supplyTM) onlyOwner public returns (bool success){
		uint256 tm = _supplyTM * 1000 * 10000 * 10 ** uint256(decimals);
        totalSupply += tm;
        balanceOf[msg.sender] += tm;
        emit Offer(_supplyTM);
        return true;
    }

    /**
     * è½¬ç§»åçº¦ææè
     * @param _newOwner æ°åçº¦ææèå°å
     */
    function transferOwnership(address _newOwner) onlyOwner public returns (bool success){
        require(owner != _newOwner, "æ æåçº¦æ°ææè");
        newOwner = _newOwner;
        return true;
    }
    
    /**
     * æ¥åå¹¶æä¸ºæ°çåçº¦ææè
     */
    function acceptOwnership() public returns (bool success){
        require(msg.sender == newOwner && newOwner != 0x0, "æ æåçº¦æ°ææè");
        address oldOwner = owner;
        owner = newOwner;
        newOwner = 0x0;
        emit OwnerChanged(oldOwner, owner);
        return true;
    }

    /**
     * è®¾å®åçº¦éå®ç¶æ
     * @param _lockAll ç¶æ
     */
    function setLockAll(bool _lockAll) onlyOwner public returns (bool success){
        lockAll = _lockAll;
        return true;
    }

    /**
     * è®¾å®è´¦æ·å»ç»ç¶æ
     * @param _target å»ç»ç®æ 
     * @param _freeze å»ç»ç¶æ
     */
    function setFreezeAddress(address _target, bool _freeze) onlyOwner public returns (bool success){
        frozens[_target] = _freeze;
        emit FreezeAddress(_target, _freeze);
        return true;
    }

    /**
     * ä»æææ¹è½¬ç§»æå®æ°éç Token ç»æ¥æ¶æ¹
     * @param _from æææ¹
     * @param _to æ¥æ¶æ¹
     * @param _value æ°é
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        //- éå®æ ¡éª
        require(!lockAll, "åçº¦å¤äºéå®ç¶æ");
        //- å°åææéªè¯
        require(_to != 0x0, "æ ææ¥æ¶å°å");
        //- ä½é¢éªè¯
        require(balanceOf[_from] >= _value, "æææ¹è½¬ç§»æ°éä¸è¶³");
        //- æææ¹å»ç»æ ¡éª
        require(!frozens[_from], "æææ¹å¤äºå»ç»ç¶æ"); 
        //- æ¥æ¶æ¹å»ç»æ ¡éª
        //require(!frozenAccount[_to]); 

        //- ä¿å­é¢æ ¡éªæ»é
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        //- æææ¹åå°ä»£å¸
        balanceOf[_from] -= _value;
        //- æ¥æ¶æ¹å¢å ä»£å¸
        balanceOf[_to] += _value;
        //- è§¦åè½¬è´¦äºä»¶
		emit Transfer(_from, _to, _value);

        //- ç¡®ä¿äº¤æè¿åï¼æææ¹åæ¥æ¶æ¹æææ»éä¸å
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * è½¬ç§»è½¬æå®æ°éç Token ç»æ¥æ¶æ¹
     *
     * @param _to æ¥æ¶æ¹å°å
     * @param _value æ°é
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	
    /**
     * è½¬ç§»è½¬æå®æ°éç Token ç»æ¥æ¶æ¹ï¼å¹¶åæ¬æ©å±æ°æ®ï¼è¯¥æ¹æ³å°ä¼è§¦åä¸¤ä¸ªäºä»¶ï¼
     *
     * @param _to æ¥æ¶æ¹å°å
     * @param _value æ°é
     * @param _extraData æ©å±æ°æ®
     */
    function transferExtra(address _to, uint256 _value, bytes _extraData) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
		emit TransferExtra(msg.sender, _to, _value, _extraData);
        return true;
    }

    /**
     * ä»æææ¹è½¬ç§»æå®æ°éç Token ç»æ¥æ¶æ¹
     *
     * @param _from æææ¹
     * @param _to æ¥æ¶æ¹
     * @param _value æ°é
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //- ææé¢åº¦æ ¡éª
        require(_value <= allowance[_from][msg.sender], "ææé¢åº¦ä¸è¶³");

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * æææå®å°åçè½¬ç§»é¢åº¦
     *
     * @param _spender ä»£çæ¹
     * @param _value ææé¢åº¦
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * æææå®å°åçè½¬ç§»é¢åº¦ï¼å¹¶éç¥ä»£çæ¹åçº¦
     *
     * @param _spender ä»£çæ¹
     * @param _value è½¬è´¦æé«é¢åº¦
     * @param _extraData æ©å±æ°æ®ï¼ä¼ éç»ä»£çæ¹åçº¦ï¼
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);//- ä»£çæ¹åçº¦
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function _burn(address _from, uint256 _value) internal {
        //- éå®æ ¡éª
        require(!lockAll, "åçº¦å¤äºéå®ç¶æ");
        //- ä½é¢éªè¯
        require(balanceOf[_from] >= _value, "æææ¹ä½é¢ä¸è¶³");
        //- å»ç»æ ¡éª
        require(!frozens[_from], "æææ¹å¤äºå»ç»ç¶æ"); 

        //- æ¶è Token
        balanceOf[_from] -= _value;
        //- æ»éä¸è°
        totalSupply -= _value;

        emit Burn(_from, _value);
    }

    /**
     * æ¶èæå®æ°éç Token
     *
     * @param _value æ¶èæ°é
     */
    function burn(uint256 _value) public returns (bool success) {

        _burn(msg.sender, _value);
        return true;
    }

    /**
     * æ¶èæææ¹ææé¢åº¦åæå®æ°éç Token
     *
     * @param _from æææ¹
     * @param _value æ¶èæ°é
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        //- ææé¢åº¦æ ¡éª
        require(_value <= allowance[_from][msg.sender], "ææé¢åº¦ä¸è¶³");
      
        allowance[_from][msg.sender] -= _value;

        _burn(_from, _value);
        return true;
    }

    function() payable public{
    }
}