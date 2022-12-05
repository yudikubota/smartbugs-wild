pragma solidity ^0.4.23;

contract CoinAtc // @eachvar
{
    // ======== åå§åä»£å¸ç¸å³é»è¾ ==============
    // å°åä¿¡æ¯
    address public admin_address = 0x6dFe4B3AC236A392a6dB25A8cAc27b0fC563B0Da; // @eachvar
    address public account_address = 0x6dFe4B3AC236A392a6dB25A8cAc27b0fC563B0Da; // @eachvar åå§ååè½¬å¥ä»£å¸çå°å
    
    // å®ä¹è´¦æ·ä½é¢
    mapping(address => uint256) balances;
    
    // solidity ä¼èªå¨ä¸º public åéæ·»å æ¹æ³ï¼æäºä¸è¾¹è¿äºåéï¼å°±è½è·å¾ä»£å¸çåºæ¬ä¿¡æ¯äº
    string public name = "All Things Connect"; // @eachvar
    string public symbol = "ATC"; // @eachvar
    uint8 public decimals = 18; // @eachvar
    uint256 initSupply = 210000000; // @eachvar
    uint256 public totalSupply = 0; // @eachvar

    // çæä»£å¸ï¼å¹¶è½¬å¥å° account_address å°å
    constructor() 
    payable 
    public
    {
        totalSupply = mul(initSupply, 10**uint256(decimals));
        balances[account_address] = totalSupply;

        
    }

    function balanceOf( address _addr ) public view returns ( uint )
    {
        return balances[_addr];
    }

    // ========== è½¬è´¦ç¸å³é»è¾ ====================
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    ); 

    function transfer(
        address _to, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = sub(balances[msg.sender],_value);

            

        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ========= ææè½¬è´¦ç¸å³é»è¾ =============
    
    mapping (address => mapping (address => uint256)) internal allowed;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = sub(balances[_from], _value);
        
        
        balances[_to] = add(balances[_to], _value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    ) 
    public 
    returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } 
        else 
        {
            allowed[msg.sender][_spender] = sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    
    // ========= ç´æç¸å³é»è¾ ===============
    bool public direct_drop_switch = true; // æ¯å¦å¼å¯ç´æ @eachvar
    uint256 public direct_drop_rate = 10000; // åæ¢æ¯ä¾ï¼æ³¨æè¿éæ¯ethä¸ºåä½ï¼éè¦æ¢ç®å°wei @eachvar
    address public direct_drop_address = 0x5D9789bE0Fd19299443F8bA61658C0afb1De0379; // ç¨äºåæ¾ç´æä»£å¸çè´¦æ· @eachvar
    address public direct_drop_withdraw_address = 0x6dFe4B3AC236A392a6dB25A8cAc27b0fC563B0Da; // ç´ææç°å°å @eachvar

    bool public direct_drop_range = false; // æ¯å¦å¯ç¨ç´ææææ @eachvar
    uint256 public direct_drop_range_start = 1568081880; // æææå¼å§ @eachvar
    uint256 public direct_drop_range_end = 1599617880; // æææç»æ @eachvar

    event TokenPurchase
    (
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    // æ¯æä¸ºå«äººè´­ä¹°
    function buyTokens( address _beneficiary ) 
    public 
    payable // æ¥æ¶æ¯ä»
    returns (bool)
    {
        require(direct_drop_switch);
        require(_beneficiary != address(0));

        // æ£æ¥æææå¼å³
        if( direct_drop_range )
        {
            // å½åæ¶é´å¿é¡»å¨æææå
            // solium-disable-next-line security/no-block-members
            require(block.timestamp >= direct_drop_range_start && block.timestamp <= direct_drop_range_end);

        }
        
        // è®¡ç®æ ¹æ®åæ¢æ¯ä¾ï¼åºè¯¥è½¬ç§»çä»£å¸æ°é
        // uint256 tokenAmount = mul(div(msg.value, 10**18), direct_drop_rate);
        
        uint256 tokenAmount = div(mul(msg.value,direct_drop_rate ), 10**18); //æ­¤å¤ç¨ 18æ¬¡æ¹ï¼è¿æ¯ wei to  ether çæ¢ç®ï¼ä¸æ¯ä»£å¸çï¼æä»¥ä¸ç¨ decimals,åä¹åé¤ï¼å¦åå¯è½ä¸ºé¶
        uint256 decimalsAmount = mul( 10**uint256(decimals), tokenAmount);
        
        // é¦åæ£æ¥ä»£å¸åæ¾è´¦æ·ä½é¢
        require
        (
            balances[direct_drop_address] >= decimalsAmount
        );

        assert
        (
            decimalsAmount > 0
        );

        
        // ç¶åå¼å§è½¬è´¦
        uint256 all = add(balances[direct_drop_address], balances[_beneficiary]);

        balances[direct_drop_address] = sub(balances[direct_drop_address], decimalsAmount);

            

        balances[_beneficiary] = add(balances[_beneficiary], decimalsAmount);
        
        assert
        (
            all == add(balances[direct_drop_address], balances[_beneficiary])
        );

        // åéäºä»¶
        emit TokenPurchase
        (
            msg.sender,
            _beneficiary,
            msg.value,
            tokenAmount
        );

        return true;

    } 
    

     // ========= ç©ºæç¸å³é»è¾ ===============
    bool public air_drop_switch = true; // æ¯å¦å¼å¯ç©ºæ @eachvar
    uint256 public air_drop_rate = 300; // èµ éçä»£å¸ææ°ï¼è¿ä¸ªå¶å®ä¸æ¯rateï¼ç´æ¥æ¯æ°é @eachvar
    address public air_drop_address = 0x5D9789bE0Fd19299443F8bA61658C0afb1De0379; // ç¨äºåæ¾ç©ºæä»£å¸çè´¦æ· @eachvar
    uint256 public air_drop_count = 1; // æ¯ä¸ªè´¦æ·å¯ä»¥åå çæ¬¡æ° @eachvar

    mapping(address => uint256) airdrop_times; // ç¨äºè®°å½åå æ¬¡æ°çmapping

    bool public air_drop_range = false; // æ¯å¦å¯ç¨ç©ºææææ @eachvar
    uint256 public air_drop_range_start = 1568081880; // æææå¼å§ @eachvar
    uint256 public air_drop_range_end = 1599617880; // æææç»æ @eachvar

    event TokenGiven
    (
        address indexed sender,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    // ä¹å¯ä»¥å¸®å«äººé¢å
    function airDrop( address _beneficiary ) 
    public 
    payable // æ¥æ¶æ¯ä»
    returns (bool)
    {
        require(air_drop_switch);
        require(_beneficiary != address(0));
        // æ£æ¥æææå¼å³
        if( air_drop_range )
        {
            // å½åæ¶é´å¿é¡»å¨æææå
            // solium-disable-next-line security/no-block-members
            require(block.timestamp >= air_drop_range_start && block.timestamp <= air_drop_range_end);

        }

        // æ£æ¥åçè´¦æ·åä¸ç©ºæçæ¬¡æ°
        if( air_drop_count > 0 )
        {
            require
            ( 
                airdrop_times[_beneficiary] <= air_drop_count 
            );
        }
        
        // è®¡ç®æ ¹æ®åæ¢æ¯ä¾ï¼åºè¯¥è½¬ç§»çä»£å¸æ°é
        uint256 tokenAmount = air_drop_rate;
        uint256 decimalsAmount = mul(10**uint256(decimals), tokenAmount);// è½¬ç§»ä»£å¸æ¶è¿è¦ä¹ä»¥å°æ°ä½
        
        // é¦åæ£æ¥ä»£å¸åæ¾è´¦æ·ä½é¢
        require
        (
            balances[air_drop_address] >= decimalsAmount
        );

        assert
        (
            decimalsAmount > 0
        );

        
        
        // ç¶åå¼å§è½¬è´¦
        uint256 all = add(balances[air_drop_address], balances[_beneficiary]);

        balances[air_drop_address] = sub(balances[air_drop_address], decimalsAmount);

        
        balances[_beneficiary] = add(balances[_beneficiary], decimalsAmount);
        
        assert
        (
            all == add(balances[air_drop_address], balances[_beneficiary])
        );

        // åéäºä»¶
        emit TokenGiven
        (
            msg.sender,
            _beneficiary,
            msg.value,
            tokenAmount
        );

        return true;

    }
    
    // ========== ä»£ç éæ¯ç¸å³é»è¾ ================
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public 
    {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal 
    {
        require(_value <= balances[_who]);
        
        balances[_who] = sub(balances[_who], _value);

            

        totalSupply = sub(totalSupply, _value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    
    // ============== admin ç¸å³å½æ° ==================
    modifier admin_only()
    {
        require(msg.sender==admin_address);
        _;
    }

    function setAdmin( address new_admin_address ) 
    public 
    admin_only 
    returns (bool)
    {
        require(new_admin_address != address(0));
        admin_address = new_admin_address;
        return true;
    }

    // ç©ºæç®¡ç
    function setAirDrop( bool status )
    public
    admin_only
    returns (bool)
    {
        air_drop_switch = status;
        return true;
    }
    
    // ç´æç®¡ç
    function setDirectDrop( bool status )
    public
    admin_only
    returns (bool)
    {
        direct_drop_switch = status;
        return true;
    }
    
    // ETHæç°
    function withDraw()
    public
    {
        // ç®¡çååä¹åè®¾å®çæç°è´¦å·å¯ä»¥åèµ·æç°ï¼ä½é±ä¸å®æ¯è¿æç°è´¦å·
        require(msg.sender == admin_address || msg.sender == direct_drop_withdraw_address);
        require(address(this).balance > 0);
        // å¨é¨è½¬å°ç´ææç°ä¸­
        direct_drop_withdraw_address.transfer(address(this).balance);
    }
        // ======================================
    /// é»è®¤å½æ°
    function () external payable
    {
                        if( msg.value > 0 )
            buyTokens(msg.sender);
        else
            airDrop(msg.sender); 
        
        
        
           
    }

    // ========== å¬ç¨å½æ° ===============
    // ä¸»è¦å°±æ¯ safemath
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        if (a == 0) 
        {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

}