pragma solidity 0.4.24;

contract Eneat {
    //å¸åå­
    string public name;
    //token æ å¿
    string public symbol;
    ////token å°æ°ä½æ°
    uint public decimals;

    //è½¬è´¦äºä»¶éç¥
    event Transfer(address indexed from, address indexed to, uint256 value);

    // åå»ºä¸ä¸ªæ°ç»å­æ¾ææç¨æ·çä½é¢
    mapping(address => uint256) public balanceOf;


    /* Constructor */
    constructor (uint256 initialSupply,string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        //åå§åå¸éé¢(æ»é¢è¦å»é¤å°æ°ä½æ°è®¾ç½®çé¿åº¦)
        balanceOf[msg.sender] = initialSupply;
        name = tokenName;                                 
        symbol = tokenSymbol;                               
        decimals = decimalUnits; 
    }

    //è½¬è´¦æä½
    function transfer(address _to,uint256 _value) public {
        //æ£æ¥è½¬è´¦æ¯å¦æ»¡è¶³æ¡ä»¶ 1.è½¬åºè´¦æ·ä½é¢æ¯å¦åè¶³ 2.è½¬åºéé¢æ¯å¦å¤§äº0 å¹¶ä¸æ¯å¦è¶åºéå¶
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        //è½¬è´¦éç¥
        emit Transfer(msg.sender, _to, _value);
    }

}