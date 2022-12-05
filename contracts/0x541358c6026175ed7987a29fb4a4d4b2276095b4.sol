pragma solidity ^0.4.4;
contract Token {

    /// @return è¿åtokençåè¡é
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner æ¥è¯¢ä»¥å¤ªåå°åtokenä½é¢
    /// @return The balance è¿åä½é¢
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice msg.senderï¼äº¤æåéèï¼åé _valueï¼ä¸å®æ°éï¼ç token å° _toï¼æ¥åèï¼  
    /// @param _to æ¥æ¶èçå°å
    /// @param _value åétokençæ°é
    /// @return æ¯å¦æå
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice åéè åé _valueï¼ä¸å®æ°éï¼ç token å° _toï¼æ¥åèï¼  
    /// @param _from åéèçå°å
    /// @param _to æ¥æ¶èçå°å
    /// @param _value åéçæ°é
    /// @return æ¯å¦æå
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice åè¡æ¹ æ¹å ä¸ä¸ªå°ååéä¸å®æ°éçtoken
    /// @param _spender éè¦åétokençå°å
    /// @param _value åétokençæ°é
    /// @return æ¯å¦æå
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner æ¥ætokençå°å
    /// @param _spender å¯ä»¥åétokençå°å
    /// @return è¿åè®¸åéçtokençæ°é
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    /// åéTokenäºä»¶
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    /// æ¹åäºä»¶
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //é»è®¤tokenåè¡éä¸è½è¶è¿(2^256 - 1)
        //å¦æä½ ä¸è®¾ç½®åè¡éï¼å¹¶ä¸éçæ¶é´çååæ´å¤çtokenï¼éè¦ç¡®ä¿æ²¡æè¶è¿æå¤§å¼ï¼ä½¿ç¨ä¸é¢ç if è¯­å¥
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //åä¸é¢çæ¹æ³ä¸æ ·ï¼å¦æä½ æ³ç¡®ä¿åè¡éä¸è¶è¿æå¤§å¼
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
contract Coin is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //tokenåç§°: Coin 
    uint8 public decimals;                //å°æ°ä½
    string public symbol;                 //æ è¯
    string public version = 'H0.1';       //çæ¬å·

    function Coin(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits);    // åè¡é
        balances[msg.sender] = totalSupply;                             // åçº¦åå¸èçä½é¢æ¯åè¡æ°é                      
        name = _tokenName;                                              // tokenåç§°
        decimals = _decimalUnits;                                       // tokenå°æ°ä½
        symbol = _tokenSymbol;                                          // tokenæ è¯
    }

    /* æ¹åç¶åè°ç¨æ¥æ¶åçº¦ */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //è°ç¨ä½ æ³è¦éç¥åçº¦ç receiveApprovalcall æ¹æ³ ï¼è¿ä¸ªæ¹æ³æ¯å¯ä»¥ä¸éè¦åå«å¨è¿ä¸ªåçº¦éçã
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //åè®¾è¿ä¹åæ¯å¯ä»¥æåï¼ä¸ç¶åºè¯¥è°ç¨vanilla approveã
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}