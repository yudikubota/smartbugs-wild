pragma solidity ^0.4.21;

contract FangTangCoin {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    address public creator;
    
    bool public autoSend = false;
    uint public start;
    uint public end;
    uint public rate;
    uint public freeCount;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => uint8) public buyCountOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    // buy token 
    function () public payable {
        require(autoSend);
        require(now >= start && now <= end);
        
        uint256 weiAmount = msg.value;
        uint256 tokens;
        if (rate == 0) 
            tokens = freeCount*decimals;
        else 
            tokens = (weiAmount/1000000000000000000)*rate;
        
        require(tokens > 0);
        
        // ä¸è¦èªå·±æå°èªå·±è´¦æ·
        require(creator != msg.sender);

        // é¦åæ£æ¥åtokençè´¦æ·æ¯å¦æ¥æå¯¹åºæ°éçä»£å¸ 
        require(balanceOf[creator] >= tokens);
        


        // å½ rate ä¸º 0 æ¶ï¼æ£æ¥æ¯å¦å·²ç»é¢åè¿
        if (rate == 0)
            require(buyCountOf[msg.sender] < 1);
            
        // å¼å§è½¬ç§»ä»£å¸
        uint previousBalances = balanceOf[msg.sender] + balanceOf[creator];
        balanceOf[msg.sender] += tokens;
        balanceOf[creator] -= tokens;
        
        // è¿ä¸ªæ¯äºä»¶
        emit Transfer(creator,msg.sender, tokens);
        assert(balanceOf[msg.sender] + balanceOf[creator] == previousBalances);
        
         if (rate == 0) 
            buyCountOf[msg.sender] += 1;
        
    }
    
    function getETH() public {
        require(address(this).balance > 0 && msg.sender == creator);
        creator.transfer(address(this).balance);
    }
    
    function FangTangCoin( 
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimals,
        bool tokenAutoSend,
        uint tokenStart,
        uint tokenEnd,
        uint tokenPrice,
        uint tokenFreeCount
    ) public payable
    {
        name = tokenName;                       
        symbol = tokenSymbol; 
        decimals = tokenDecimals;
        
        creator = msg.sender;
        totalSupply = initialSupply * ( 10 ** uint256(decimals) ); 
        balanceOf[msg.sender] = totalSupply;
        
        autoSend = tokenAutoSend;
        start = tokenStart;
        end = tokenEnd;
        rate = tokenPrice;
        freeCount = tokenFreeCount;
        
        
    }
    
    function transfer(address _to, uint256 _value) public {
        
        // _value = _value * ( 10 ** uint256(decimals) );
        
        require(_to != 0x0);
        require(msg.sender != _to);
        
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[msg.sender] + balanceOf[_to];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        // è¿ä¸ªæ¯äºä»¶
        emit Transfer(msg.sender, _to, _value);
        assert(balanceOf[msg.sender] + balanceOf[_to] == previousBalances);
    }
    
    

}