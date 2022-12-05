pragma solidity ^0.4.8;
contract Token{
    // tokenæ»éï¼é»è®¤ä¼ä¸ºpublicåéçæä¸ä¸ªgetterå½æ°æ¥å£ï¼åç§°ä¸ºtotalSupply().
    uint256 public totalSupply;

    /// è·åè´¦æ·_owneræ¥ætokençæ°é 
    function balanceOf(address _owner) constant returns (uint256 balance);

    //ä»æ¶æ¯åéèè´¦æ·ä¸­å¾_toè´¦æ·è½¬æ°éä¸º_valueçtoken
    function transfer(address _to, uint256 _value) returns (bool success);

    //ä»è´¦æ·_fromä¸­å¾è´¦æ·_toè½¬æ°éä¸º_valueçtokenï¼ä¸approveæ¹æ³éåä½¿ç¨
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

    //æ¶æ¯åéè´¦æ·è®¾ç½®è´¦æ·_spenderè½ä»åéè´¦æ·ä¸­è½¬åºæ°éä¸º_valueçtoken
    function approve(address _spender, uint256 _value) returns (bool success);

    //è·åè´¦æ·_spenderå¯ä»¥ä»è´¦æ·_ownerä¸­è½¬åºtokençæ°é
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

    //åçè½¬è´¦æ¶å¿é¡»è¦è§¦åçäºä»¶ 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //å½å½æ°approve(address _spender, uint256 _value)æåæ§è¡æ¶å¿é¡»è§¦åçäºä»¶
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //é»è®¤totalSupply ä¸ä¼è¶è¿æå¤§å¼ (2^256 - 1).
        //å¦æéçæ¶é´çæ¨ç§»å°ä¼ææ°çtokençæï¼åå¯ä»¥ç¨ä¸é¢è¿å¥é¿åæº¢åºçå¼å¸¸
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//ä»æ¶æ¯åéèè´¦æ·ä¸­åå»tokenæ°é_value
        balances[_to] += _value;//å¾æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        Transfer(msg.sender, _to, _value);//è§¦åè½¬å¸äº¤æäºä»¶
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= 
        // _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        balances[_from] -= _value; //æ¯åºè´¦æ·_fromåå»tokenæ°é_value
        allowed[_from][msg.sender] -= _value;//æ¶æ¯åéèå¯ä»¥ä»è´¦æ·_fromä¸­è½¬åºçæ°éåå°_value
        Transfer(_from, _to, _value);//è§¦åè½¬å¸äº¤æäºä»¶
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//åè®¸_spenderä»_ownerä¸­è½¬åºçtokenæ°
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CHMTToken is StandardToken{

    string public name = "The central plains he mother tower";
    string public symbol = "CHMT";
    uint8 public decimals = 0;
    uint public INITIAL_SUPPLY = 50000000;
    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}