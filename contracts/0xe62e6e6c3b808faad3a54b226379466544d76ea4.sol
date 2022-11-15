pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Alchemy {
    using SafeMath for uint256;

    // ä»£å¸çå¬å±åéï¼åç§°ãä»£å·ãå°æ°ç¹åé¢çä½æ°ãä»£å¸åè¡æ»é
    string public name;
    string public symbol;
    uint8 public decimals = 6; // å®æ¹å»ºè®®18ä½
    uint256 public totalSupply;
    address public owner;

    address[] public ownerContracts;// åè®¸è°ç¨çæºè½åçº¦
    address public userPool;
    address public platformPool;
    address public smPool;

    //  çç§æ± éç½®
    mapping(string => address) burnPoolAddreses;

    // ä»£å¸ä½é¢çæ°æ®
    mapping (address => uint256) public balanceOf;
    // ä»£ä»éé¢éå¶
    // æ¯å¦map[A][B]=60ï¼æææ¯ç¨æ·Bå¯ä»¥ä½¿ç¨Açé±è¿è¡æ¶è´¹ï¼ä½¿ç¨ä¸éæ¯60ï¼æ­¤æ¡æ°æ®ç±Aæ¥è®¾ç½®ï¼ä¸è¬Bå¯ä»¥ä½¿ä¸­é´æä¿å¹³å°
    mapping (address => mapping (address => uint256)) public allowance;

    // äº¤ææåäºä»¶ï¼ä¼éç¥ç»å®¢æ·ç«¯
    event Transfer(address indexed from, address indexed to, uint256 value);

    // äº¤æETHæåäºä»¶ï¼ä¼éç¥ç»å®¢æ·ç«¯
    event TransferETH(address indexed from, address indexed to, uint256 value);

    // å°éæ¯çä»£å¸ééç¥ç»å®¢æ·ç«¯
    event Burn(address indexed from, uint256 value);

    /**
     * æé å½æ°
     * åå§åä»£å¸åè¡çåæ°
     */
    //990000000,"AlchemyChain","ALC"
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) payable public  {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // è®¡ç®åè¡é
        balanceOf[msg.sender] = totalSupply;                // å°åè¡çå¸ç»åå»ºè
        name = tokenName;                                   // è®¾ç½®ä»£å¸åç§°
        symbol = tokenSymbol;                               // è®¾ç½®ä»£å¸ç¬¦å·
        owner = msg.sender;
    }

    // ä¿®æ¹å¨
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //æ¥è¯¢å½åçä»¥ä»¥å¤ªä½é¢
    function getETHBalance() view public returns(uint){
        return address(this).balance;
    }

    //æ¹éå¹³åä»¥å¤ªä½é¢
    function transferETH(address[] _tos) public onlyOwner returns (bool) {
        require(_tos.length > 0);
        require(address(this).balance > 0);
        for(uint32 i=0;i<_tos.length;i++){
            _tos[i].transfer(address(this).balance/_tos.length);
            emit TransferETH(owner, _tos[i], address(this).balance/_tos.length);
        }
        return true;
    }

    //ç´æ¥è½¬è´¦æå®æ°é
    function transferETH(address _to, uint256 _value) payable public onlyOwner returns (bool){
        require(_value > 0);
        require(address(this).balance >= _value);
        require(_to != address(0));
        _to.transfer(_value);
        emit TransferETH(owner, _to, _value);
        return true;
    }

    //ç´æ¥è½¬è´¦å¨é¨æ°é
    function transferETH(address _to) payable public onlyOwner returns (bool){
        require(_to != address(0));
        require(address(this).balance > 0);
        _to.transfer(address(this).balance);
        emit TransferETH(owner, _to, address(this).balance);
        return true;
    }

    //ç´æ¥è½¬è´¦å¨é¨æ°é
    function transferETH() payable public onlyOwner returns (bool){
        require(address(this).balance > 0);
        owner.transfer(address(this).balance);
        emit TransferETH(owner, owner, address(this).balance);
        return true;
    }

    // æ¥æ¶ä»¥å¤ª
    function () payable public {
        // å¶ä»é»
    }

    // ä¼ç­¹
    function funding() payable public returns (bool) {
        require(msg.value <= balanceOf[owner]);
        // SafeMath.sub will throw if there is not enough balance.
        balanceOf[owner] = balanceOf[owner].sub(msg.value);
        balanceOf[tx.origin] = balanceOf[tx.origin].add(msg.value);
        emit Transfer(owner, tx.origin, msg.value);
        return true;
    }

    function _contains() internal view returns (bool) {
        for(uint i = 0; i < ownerContracts.length; i++){
            if(ownerContracts[i] == msg.sender){
                return true;
            }
        }
        return false;
    }

    function setOwnerContracts(address _adr) public onlyOwner {
        if(_adr != 0x0){
            ownerContracts.push(_adr);
        }
    }

    //ä¿®æ¹ç®¡çå¸å·
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    /**
     * åé¨è½¬è´¦ï¼åªè½è¢«æ¬åçº¦è°ç¨
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(userPool != 0x0);
        require(platformPool != 0x0);
        require(smPool != 0x0);
        // æ£æµæ¯å¦ç©ºå°å
        require(_to != 0x0);
        // æ£æµä½é¢æ¯å¦åè¶³
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        // æ£æµæº¢åº
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // ä¿å­ä¸ä¸ªä¸´æ¶åéï¼ç¨äºæåæ£æµå¼æ¯å¦æº¢åº
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // åºè´¦
        balanceOf[_from] = balanceOf[_from].sub(_value);
        uint256 burnTotal = 0;
        uint256 platformToal = 0;
        // å¥è´¦å¦ææ¥åæ¹æ¯æºè½åçº¦å°åï¼åç´æ¥éæ¯
        if (this == _to) {
            //totalSupply -= _value;                      // ä»åè¡çå¸ä¸­å é¤
            burnTotal = _value*3;
            platformToal = burnTotal.mul(15).div(100);
            require(balanceOf[owner] >= (burnTotal + platformToal));
            balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
            balanceOf[platformPool] = balanceOf[platformPool].add(platformToal);
            balanceOf[owner] -= (burnTotal + platformToal);
            emit Transfer(_from, _to, _value);
            emit Transfer(owner, userPool, burnTotal);
            emit Transfer(owner, platformPool, platformToal);
            emit Burn(_from, _value);
        } else if (smPool == _from) {//ç§åæ¹ä»£ç¨æ·æå¥çç§æ°éä»£å¸
            address smBurnAddress = burnPoolAddreses["smBurn"];
            require(smBurnAddress != 0x0);
            burnTotal = _value*3;
            platformToal = burnTotal.mul(15).div(100);
            require(balanceOf[owner] >= (burnTotal + platformToal));
            balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
            balanceOf[platformPool] = balanceOf[platformPool].add(platformToal);
            balanceOf[owner] -= (burnTotal + platformToal);
            emit Transfer(_from, _to, _value);
            emit Transfer(_to, smBurnAddress, _value);
            emit Transfer(owner, userPool, burnTotal);
            emit Transfer(owner, platformPool, platformToal);
            emit Burn(_to, _value);
        } else {
            address appBurnAddress = burnPoolAddreses["appBurn"];
            address webBurnAddress = burnPoolAddreses["webBurn"];
            address normalBurnAddress = burnPoolAddreses["normalBurn"];
            //çç§è½¬å¸ç¹æ®å¤ç
            if (_to == appBurnAddress || _to == webBurnAddress || _to == normalBurnAddress) {
                burnTotal = _value*3;
                platformToal = burnTotal.mul(15).div(100);
                require(balanceOf[owner] >= (burnTotal + platformToal));
                balanceOf[userPool] = balanceOf[userPool].add(burnTotal);
                balanceOf[platformPool] = balanceOf[platformPool].add(platformToal);
                balanceOf[owner] -= (burnTotal + platformToal);
                emit Transfer(_from, _to, _value);
                emit Transfer(owner, userPool, burnTotal);
                emit Transfer(owner, platformPool, platformToal);
                emit Burn(_from, _value);
            } else {
                balanceOf[_to] = balanceOf[_to].add(_value);
                emit Transfer(_from, _to, _value);
                // æ£æµå¼æ¯å¦æº¢åºï¼æèææ°æ®è®¡ç®éè¯¯
                assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
            }

        }
    }

    /**
     * ä»£å¸è½¬è´¦
     * ä»èªå·±çè´¦æ·ä¸ç»å«äººè½¬è´¦
     * @param _to è½¬å¥è´¦æ·
     * @param _value è½¬è´¦éé¢
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * ä»£å¸è½¬è´¦
     * ä»èªå·±çè´¦æ·ä¸ç»å«äººè½¬è´¦
     * @param _to è½¬å¥è´¦æ·
     * @param _value è½¬è´¦éé¢
     */
    function transferTo(address _to, uint256 _value) public {
        require(_contains());
        _transfer(tx.origin, _to, _value);
    }

    /**
     * ä»å¶ä»è´¦æ·è½¬è´¦
     * ä»å¶ä»çè´¦æ·ä¸ç»å«äººè½¬è´¦
     * @param _from è½¬åºè´¦æ·
     * @param _to è½¬å¥è´¦æ·
     * @param _value è½¬è´¦éé¢
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     // æ£æ¥åè®¸äº¤æçéé¢
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * è®¾ç½®ä»£ä»éé¢éå¶
     * åè®¸æ¶è´¹èä½¿ç¨çä»£å¸éé¢
     * @param _spender åè®¸ä»£ä»çè´¦å·
     * @param _value åè®¸ä»£ä»çéé¢
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * è®¾ç½®ä»£ä»éé¢éå¶å¹¶éç¥å¯¹æ¹ï¼åçº¦ï¼
     * è®¾ç½®ä»£ä»éé¢éå¶
     * @param _spender åè®¸ä»£ä»çè´¦å·
     * @param _value åè®¸ä»£ä»çéé¢
     * @param _extraData åæ§æ°æ®
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * éæ¯èªå·±çä»£å¸
     * ä»ç³»ç»ä¸­éæ¯ä»£å¸
     * @param _value éæ¯é
     */
    function burn(uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);   // æ£æµä½é¢æ¯å¦åè¶³
        balanceOf[msg.sender] -= _value;            // éæ¯ä»£å¸
        totalSupply -= _value;                      // ä»åè¡çå¸ä¸­å é¤
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * éæ¯å«äººçä»£å¸
     * ä»ç³»ç»ä¸­éæ¯ä»£å¸
     * @param _from éæ¯çå°å
     * @param _value éæ¯é
     */
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value);                // æ£æµä½é¢æ¯å¦åè¶³
        require(_value <= allowance[_from][msg.sender]);    // æ£æµä»£ä»é¢åº¦
        balanceOf[_from] -= _value;                         // éæ¯ä»£å¸
        allowance[_from][msg.sender] -= _value;             // éæ¯é¢åº¦
        totalSupply -= _value;                              // ä»åè¡çå¸ä¸­å é¤
        emit Burn(_from, _value);
        return true;
    }

    /**
     * æ¹éè½¬è´¦
     * ä»èªå·±çè´¦æ·ä¸ç»å«äººè½¬è´¦
     * @param _to è½¬å¥è´¦æ·
     * @param _value è½¬è´¦éé¢
     */
    function transferArray(address[] _to, uint256[] _value) public {
        require(_to.length == _value.length);
        uint256 sum = 0;
        for(uint256 i = 0; i< _value.length; i++) {
            sum += _value[i];
        }
        require(balanceOf[msg.sender] >= sum);
        for(uint256 k = 0; k < _to.length; k++){
            _transfer(msg.sender, _to[k], _value[k]);
        }
    }

    /**
     * è®¾ç½®ç¼éæ± ï¼å¹³å°æ¶çæ± å°å
     */
    function setUserPoolAddress(address _userPoolAddress, address _platformPoolAddress, address _smPoolAddress) public onlyOwner {
        require(_userPoolAddress != 0x0);
        require(_platformPoolAddress != 0x0);
        require(_smPoolAddress != 0x0);
        userPool = _userPoolAddress;
        platformPool = _platformPoolAddress;
        smPool = _smPoolAddress;
    }

    /**
     * è®¾ç½®çç§æ± å°å,keyä¸ºsmBurn,appBurn,webBurn,normalBurn
     */
    function setBurnPoolAddress(string key, address _burnPoolAddress) public onlyOwner {
        if (_burnPoolAddress != 0x0)
        burnPoolAddreses[key] = _burnPoolAddress;
    }

    /**
     *  è·åçç§æ± å°å,keyä¸ºsmBurn,appBurn,webBurn,normalBurn
     */
    function  getBurnPoolAddress(string key) public view returns (address) {
        return burnPoolAddreses[key];
    }

    /**
     * ç§åè½¬å¸ç¹æ®å¤ç
     */
    function smTransfer(address _to, uint256 _value) public returns (bool)  {
        require(smPool == msg.sender);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * çç§è½¬å¸ç¹æ®å¤ç
     */
    function burnTransfer(address _from, uint256 _value, string key) public returns (bool)  {
        require(burnPoolAddreses[key] != 0x0);
        _transfer(_from, burnPoolAddreses[key], _value);
        return true;
    }

}