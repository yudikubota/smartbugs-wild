pragma solidity ^0.4.4;
contract SafeMath {
    
    // ä¹æ³ï¼internalä¿®é¥°çå½æ°åªè½å¤å¨å½ååçº¦æå­åçº¦ä¸­ä½¿ç¨ï¼
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) { 
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
  
    // é¤æ³
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
 
    // åæ³
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }
 
    // å æ³
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}
 
contract Test is SafeMath{
    // ä»£å¸çåå­
    string public name; 
    // ä»£å¸çç¬¦å·
    string public symbol;
    // ä»£å¸æ¯æçå°æ°ä½
    uint8 public decimals;
    // ä»£è¡¨åè¡çæ»é
    uint256 public totalSupply;
    // ç®¡çè
    address public owner;
 
    // è¯¥mappingä¿å­è´¦æ·ä½é¢ï¼Keyè¡¨ç¤ºè´¦æ·å°åï¼Valueè¡¨ç¤ºtokenä¸ªæ°
    mapping (address => uint256) public balanceOf;
    // è¯¥mappinä¿å­æå®å¸å·è¢«ææçtokenä¸ªæ°
    // key1è¡¨ç¤ºææäººï¼key2è¡¨ç¤ºè¢«ææäººï¼value2è¡¨ç¤ºè¢«æætokençä¸ªæ°
    mapping (address => mapping (address => uint256)) public allowance;
    // å»ç»æå®å¸å·tokençä¸ªæ°
    mapping (address => uint256) public freezeOf;
 
    // å®ä¹äºä»¶
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
 
    // æé å½æ°ï¼1000000, "ZhongB", 18, "ZB"ï¼
    constructor( 
        uint256 initialSupply,  // åè¡æ°é
        string tokenName,       // tokençåå­ BinanceToken
        uint8 decimalUnits,     // æå°åå²ï¼å°æ°ç¹åé¢çå°¾æ° 1ether = 10** 18wei
        string tokenSymbol      // ZB
    ) public {
        decimals = decimalUnits;                           
        balanceOf[msg.sender] = initialSupply * 10 ** 18;    
        totalSupply = initialSupply * 10 ** 18;   
        name = tokenName;      
        symbol = tokenSymbol;
        owner = msg.sender;
    }
    
    //å¢å
    function mintToken(address _to, uint256 _value) public returns (bool success){
        // é²æ­¢_toæ æ
        assert(_to != 0x0);
        // é²æ­¢_valueæ æ                       
        assert(_value > 0);
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(0, msg.sender, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
    // è½¬è´¦ï¼æä¸ªäººè±è´¹èªå·±çå¸
    function transfer(address _to, uint256 _value) public {
        // é²æ­¢_toæ æ
        assert(_to != 0x0);
        // é²æ­¢_valueæ æ                       
        assert(_value > 0);
        // é²æ­¢è½¬è´¦äººçä½é¢ä¸è¶³
        assert(balanceOf[msg.sender] >= _value);
        // é²æ­¢æ°æ®æº¢åº
        assert(balanceOf[_to] + _value >= balanceOf[_to]);
        // ä»è½¬è´¦äººçè´¦æ·ä¸­åå»ä¸å®çtokençä¸ªæ°
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     
        // å¾æ¥æ¶å¸å·å¢å ä¸å®çtokenä¸ªæ°
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); 
        // è½¬è´¦æååè§¦åTransferäºä»¶ï¼éç¥å¶ä»äººæè½¬è´¦äº¤æåç
        emit Transfer(msg.sender, _to, _value);// Notify anyone listening that this transfer took place
    }
 
    // ææï¼æææäººè±è´¹èªå·±è´¦æ·ä¸­ä¸å®æ°éçtoken
    function approve(address _spender, uint256 _value) public returns (bool success) {
        assert(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
 
 
    // ææè½¬è´¦ï¼è¢«ææäººä»_fromå¸å·ä¸­ç»_toå¸å·è½¬äº_valueä¸ªtoken
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // é²æ­¢å°åæ æ
        assert(_to != 0x0);
        // é²æ­¢è½¬è´¦éé¢æ æ
        assert(_value > 0);
        // æ£æ¥ææäººè´¦æ·çä½é¢æ¯å¦è¶³å¤
        assert(balanceOf[_from] >= _value);
        // æ£æ¥æ°æ®æ¯å¦æº¢åº
        assert(balanceOf[_to] + _value >= balanceOf[_to]);
        // æ£æ¥è¢«ææäººå¨allowanceä¸­å¯ä»¥ä½¿ç¨çtokenæ°éæ¯å¦è¶³å¤
        assert(_value <= allowance[_from][msg.sender]);
        // ä»ææäººå¸å·ä¸­åå»ä¸å®æ°éçtoken
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value); 
        // å¾æ¥æ¶äººå¸å·ä¸­å¢å ä¸å®æ°éçtoken
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); 
        // ä»allowanceä¸­åå»è¢«ææäººå¯ä½¿ç¨tokençæ°é
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        // äº¤ææååè§¦åTransferäºä»¶ï¼å¹¶è¿åtrue
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    // æ¶æ¯å¸
    function burn(uint256 _value) public returns (bool success) {
        // æ£æ¥å½åå¸å·ä½é¢æ¯å¦è¶³å¤
        assert(balanceOf[msg.sender] >= _value);
        // æ£æ¥_valueæ¯å¦ææ
        assert(_value > 0);
        // ä»senderè´¦æ·ä¸­ä¸­åå»ä¸å®æ°éçtoken
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        // æ´æ°åè¡å¸çæ»é
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        // æ¶å¸æååè§¦åBurnäºä»¶ï¼å¹¶è¿åtrue
        emit Burn(msg.sender, _value);
        return true;
    }
 
    // å»ç»
    function freeze(uint256 _value) public returns (bool success) {
        // æ£æ¥senderè´¦æ·ä½é¢æ¯å¦è¶³å¤
        assert(balanceOf[msg.sender] >= _value);
        // æ£æ¥_valueæ¯å¦ææ
        assert(_value > 0);
        // ä»senderè´¦æ·ä¸­åå»ä¸å®æ°éçtoken
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); 
        // å¾freezeOfä¸­ç»senderè´¦æ·å¢å æå®æ°éçtoken
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value); 
        // freezeæååè§¦åFreezeäºä»¶ï¼å¹¶è¿åtrue
        emit Freeze(msg.sender, _value);
        return true;
    }
 
    // è§£å»
    function unfreeze(uint256 _value) public returns (bool success) {
        // æ£æ¥è§£å»éé¢æ¯å¦ææ
        assert(freezeOf[msg.sender] >= _value);
        // æ£æ¥_valueæ¯å¦ææ
        assert(_value > 0); 
        // ä»freezeOfä¸­åå»æå®senderè´¦æ·ä¸å®æ°éçtoken
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value); 
        // åsenderè´¦æ·ä¸­å¢å ä¸å®æ°éçtoken
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);    
        // è§£å»æååè§¦åäºä»¶
        emit Unfreeze(msg.sender, _value);
        return true;
    }
 
    // ç®¡çèèªå·±åé±
    function withdrawEther(uint256 amount) public {
        // æ£æ¥senderæ¯å¦æ¯å½ååçº¦çç®¡çè
        assert(msg.sender == owner);
        // senderç»owneråétoken
        owner.transfer(amount);
    }
}