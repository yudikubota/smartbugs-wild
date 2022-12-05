/**
 *Submitted for verification at Etherscan.io on 2019-09-03
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-16
*/

pragma solidity ^0.4.16;
contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function trashOf(address _owner) public constant returns (uint256 trash);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function inTrash(uint256 _value) internal returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event InTrash(address indexed _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event transferLogs(address,string,uint);
}

contract TTS is Token {
    // ===============
    // BASE 
    // ===============
    string public name;                 //åç§°
    string public symbol;               //tokenç®ç§°
    uint32 internal rate;               //é¨ç¥¨æ±ç
    uint32 internal consume;            //é¨ç¥¨æ¶è
    uint256 internal totalConsume;      //é¨ç¥¨æ»æ¶è
    uint256 internal bigJackpot;        //å¤§å¥æ±  
    uint256 internal smallJackpot;      //å°å¥æ± 
    uint256 public consumeRule;       //ååè§å
    address internal owner;             //åçº¦ä½è
  
    // ===============
    // INIT 
    // ===============
    modifier onlyOwner(){
        require (msg.sender==owner);
        _;
    }
    function () payable public {}
    
    // æé å¨
    function TTS(uint256 _initialAmount, string _tokenName, uint32 _rate) public payable {
        owner = msg.sender;
        totalSupply = _initialAmount ;         // è®¾ç½®åå§æ»é
        balances[owner] = totalSupply; // åå§tokenæ°éç»äºæ¶æ¯åéèï¼å ä¸ºæ¯æé å½æ°ï¼æä»¥è¿éä¹æ¯åçº¦çåå»ºè
        name = _tokenName;            
        symbol = _tokenName;
        rate = _rate;
        consume = _rate/10;
        totalConsume = 0;
        consumeRule = 0;
        bigJackpot = 0;
        smallJackpot = 0;
    }  
    // ===============
    // CHECK 
    // ===============
    // ç¨æ·ä»£å¸
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    // ç¨æ·ä»£å¸æ¶èå¼
    function trashOf(address _owner) public constant returns (uint256 trashs) {
        return trash[_owner];
    }
    // é¨ç¥¨æ±ç
    function getRate() public constant returns(uint32 rates){
        return rate;
    }
    // é¨ç¥¨æ¶è
    function getConsume() public constant returns(uint32 consumes){
        return consume;
    }
    // é¨ç¥¨æ»æ¶è
    function getTotalConsume() public constant returns(uint256 totalConsumes){
        return totalConsume;
    }
    // å¤§å¥æ± 
    function getBigJackpot() public constant returns(uint256 bigJackpots){
        return bigJackpot;
    }
    // å°å¥æ± 
    function getSmallJackpot() public constant returns(uint256 smallJackpots){
        return smallJackpot;
    }
    // è·ååçº¦è´¦æ·ä½é¢
    function getBalance() public constant returns(uint){
        return address(this).balance;
    }
    
    // ===============
    // ETH 
    // ===============
    // æ¹éåºè´¦
    function sendAll(address[] _users,uint[] _prices,uint _allPrices) public onlyOwner{
        require(_users.length>0);
        require(_prices.length>0);
        require(address(this).balance>=_allPrices);
        for(uint32 i =0;i<_users.length;i++){
            require(_users[i]!=address(0));
            require(_prices[i]>0);
            _users[i].transfer(_prices[i]);  
            transferLogs(_users[i],'è½¬è´¦',_prices[i]);
        }
    }
    // æå¸
    function getEth(uint _price) public onlyOwner{
        if(_price>0){
            if(address(this).balance>=_price){
                owner.transfer(_price);
            }
        }else{
           owner.transfer(address(this).balance); 
        }
    }
    
    // ===============
    // TICKET 
    // ===============
    // è®¾ç½®é¨ç¥¨åæ¢æ¯ä¾
    function setRate(uint32 _rate) public onlyOwner{
        rate = _rate;
        consume = _rate/10;
        consumeRule = 0;
    }
    
    // è´­ä¹°é¨ç¥¨
    function tickets() public payable returns(bool success){
        require(msg.value % 1 ether == 0);
        uint e = msg.value / 1 ether;
        e=e*rate;
        require(balances[owner]>=e);
        balances[owner]-=e;
        balances[msg.sender]+=e;
        Transfer(owner, msg.sender, e);
        return true;
    }
    // é¨ç¥¨æ¶è
    function ticketConsume()public payable returns(bool success){
        require(msg.value % 1 ether == 0);
        uint e = msg.value / 1 ether * consume;
        
        require(balances[msg.sender]>=e); 
        balances[msg.sender]-=e;
        trash[msg.sender]+=e;
        totalConsume+=e;
        consumeRule+=e;
        if(consumeRule>=1000000){
            consumeRule-=1000000;
            rate = rate / 2;
            consume = consume / 2;
        }
        setJackpot(msg.value);
        return true;
    }

    // ===============
    // JACKPOT 
    // ===============
    // ç´¯å å¥æ± 
    function setJackpot(uint256 _value) internal{
        uint256 jackpot = _value * 12 / 100;
        bigJackpot += jackpot * 7 / 10;
        smallJackpot += jackpot * 3 / 10;
    }
    // å°å¥æ± åºè´¦
    function smallCheckOut(address[] _users) public onlyOwner{
        require(_users.length>0);
        require(address(this).balance>=smallJackpot);
        uint256 pricce = smallJackpot / _users.length;
        for(uint32 i =0;i<_users.length;i++){
            require(_users[i]!=address(0));
            require(pricce>0);
            _users[i].transfer(pricce);  
            transferLogs(_users[i],'è½¬è´¦',pricce);
        }
        smallJackpot=0;
    }
    // å¤§å¥æ± åºè´¦
    function bigCheckOut(address[] _users) public onlyOwner{
        require(_users.length>0 && bigJackpot>=30000 ether&&address(this).balance>=bigJackpot);
        uint256 pricce = bigJackpot / _users.length;
        for(uint32 i =0;i<_users.length;i++){
            require(_users[i]!=address(0));
            require(pricce>0);
            _users[i].transfer(pricce);  
            transferLogs(_users[i],'è½¬è´¦',pricce);
        }
        bigJackpot = 0;
    }
    // ===============
    // TOKEN 
    // ===============
    function inTrash(uint256 _value) internal returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//ä»æ¶æ¯åéèè´¦æ·ä¸­åå»tokenæ°é_value
        trash[msg.sender] += _value;//å½ååå¾æ¡¶å¢å tokenæ°é_value
        totalConsume += _value;
        InTrash(msg.sender,  _value);//è§¦ååå¾æ¡¶æ¶èäºä»¶
        return true;
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
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//æ¥æ¶è´¦æ·å¢å tokenæ°é_value
        balances[_from] -= _value; //æ¯åºè´¦æ·_fromåå»tokenæ°é_value
        allowed[_from][msg.sender] -= _value;//æ¶æ¯åéèå¯ä»¥ä»è´¦æ·_fromä¸­è½¬åºçæ°éåå°_value
        Transfer(_from, _to, _value);//è§¦åè½¬å¸äº¤æäºä»¶
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)   { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//åè®¸_spenderä»_ownerä¸­è½¬åºçtokenæ°
    }
    
    mapping (address => uint256) trash;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}