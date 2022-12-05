pragma solidity ^0.4.16;
contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract TokenDemo is Token {

    string public name;                   //åç§°ï¼ä¾å¦"My test token"
    uint8 public decimals;               //è¿åtokenä½¿ç¨çå°æ°ç¹åå ä½ãæ¯å¦å¦æè®¾ç½®ä¸º3ï¼å°±æ¯æ¯æ0.001è¡¨ç¤º.
    string public symbol;               //tokenç®ç§°,like MTT

    function TokenDemo(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);         // è®¾ç½®åå§æ»é
        balances[msg.sender] = totalSupply; // åå§tokenæ°éç»äºæ¶æ¯åéèï¼å ä¸ºæ¯æé å½æ°ï¼æä»¥è¿éä¹æ¯åçº¦çåå»ºè

        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //é»è®¤totalSupply ä¸ä¼è¶è¿æå¤§å¼ (2^256 - 1).
        //å¦æéçæ¶é´çæ¨ç§»å°ä¼ææ°çtokençæï¼åå¯ä»¥ç¨ä¸é¢è¿å¥é¿åæº¢åºçå¼å¸¸
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;//ä»æ¶æ¯åéèè´¦æ·ä¸­åå»tokenæ°é_value
        balances[_to] += _value;//å¾æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        Transfer(msg.sender, _to, _value);//è§¦åè½¬å¸äº¤æäºä»¶
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        balances[_from] -= _value; //æ¯åºè´¦æ·_fromåå»tokenæ°é_value
        allowed[_from][msg.sender] -= _value;//æ¶æ¯åéèå¯ä»¥ä»è´¦æ·_fromä¸­è½¬åºçæ°éåå°_value
        Transfer(_from, _to, _value);//è§¦åè½¬å¸äº¤æäºä»¶
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//åè®¸_spenderä»_ownerä¸­è½¬åºçtokenæ°
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}