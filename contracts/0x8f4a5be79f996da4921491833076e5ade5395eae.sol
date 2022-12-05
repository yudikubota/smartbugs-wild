pragma solidity >=0.4.22 <0.6.0;



contract EquityChain 
{
    string public standard = 'https://ecs.cc';
    string public name="å»ä¸­å¿åæçé¾éè¯ç³»ç»-ï¼Equity Chain Systemï¼"; //ä»£å¸åç§°
    string public symbol="ECS"; //ä»£å¸ç¬¦å·
    uint8 public decimals = 18;  //ä»£å¸åä½ï¼å±ç¤ºçå°æ°ç¹åé¢å¤å°ä¸ª0,åä»¥å¤ªå¸ä¸æ ·åé¢æ¯æ¯18ä¸ª0
    uint256 public totalSupply=100000000 ether; //ä»£å¸æ»é
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);  //è½¬å¸éç¥äºä»¶
    event Burn(address indexed from, uint256 value);  //åå»ç¨æ·ä½é¢äºä»¶

    address Old_EquityChain=0x42c4327883c4ABF85e48F9BB82E1EA0b9215aE99;
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    modifier onlyPople(){
         address addr = msg.sender;
        uint codeLength;
        assembly {codeLength := extcodesize(addr)}//æ§è¡æ±ç¼è¯­è¨ï¼è¿åaddrä¹å°±æ¯è°ç¨èå°åçå¤§å°
        require(codeLength == 0, "sorry humans only");//æ±æ­ï¼åªæäººç±»
        require(tx.origin == msg.sender, "sorry, human only");//æ±æ­ï¼åªæäººç±»
        _;
    }
    modifier onlyUnLock(){
        require(msg.sender==owner || msg.sender==owner1 || info.is_over_finance==1);
        _;
    }
    /*
    ERC20ä»£ç 
    */
    function _transfer(address _from, address _to, uint256 _value) internal{

      //é¿åè½¬å¸çå°åæ¯0x0
      require(_to != address(0x0));
      //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
      require(balanceOf[_from] >= _value);
      //æ£æ¥æ¯å¦æº¢åº
      require(balanceOf[_to] + _value > balanceOf[_to]);
      //ä¿å­æ°æ®ç¨äºåé¢çå¤æ­
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      //ä»åéèåæåéé¢
      balanceOf[_from] -= _value;
      //ç»æ¥æ¶èå ä¸ç¸åçé
      balanceOf[_to] += _value;
      //éç¥ä»»ä½çå¬è¯¥äº¤æçå®¢æ·ç«¯
      emit Transfer(_from, _to, _value);
      //å¤æ­ä¹°ãååæ¹çæ°æ®æ¯å¦åè½¬æ¢åä¸è´
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

      //å¢å äº¤æéï¼å¤æ­ä»·æ ¼æ¯å¦ä¸æ¶¨
      add_price(_value);
      //è½¬è´¦çæ¶åï¼å¦æç®æ æ²¡æ³¨åè¿ï¼è¿è¡æ³¨å
      if(st_user[_to].code==0)
      {
          register(_to,st_user[_from].code);
      }
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //æ£æ¥åéèæ¯å¦æ¥æè¶³å¤ä½é¢
        require(_value <= allowance[_from][msg.sender]);   // Check allowance
        //åé¤å¯è½¬è´¦æé
        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /*å·¥å·*/
    function Encryption(uint32 num) internal pure returns(uint32 com_num) {
      require(num>0 && num<=1073741823,"IDæå¤§ä¸è½è¶è¿1073741823");
       uint32 ret=num;
       //ç¬¬ä¸æ­¥ï¼è·å¾numæå4ä½
       uint32 xor=(num<<24)>>24;
       
       xor=(xor<<24)+(xor<<16)+(xor<<8);
       
       xor=(xor<<2)>>2;
       ret=ret ^ xor;
       ret=ret | 1073741824;
        return (ret);
   }
   //ä¹æ³
    function safe_mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
//é¤æ³
    function safe_div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
//åæ³
    function safe_sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
//å æ³
    function safe_add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    //è·å¾æ¯ä¾ï¼ç¾åæ¯ï¼
    function get_scale(uint32 i)internal pure returns(uint32 )    {
        if(i==0)
            return 10;
        else if(i==1)
            return 5;
        else if(i==2)
            return 2;
        else
            return 1;
    }

     //------------------------------------------æ³¨å------------------------------------
    function register(address addr,uint32 be_code)internal{
        assert(st_by_code[be_code] !=address(0x0) || be_code ==131537862);
        info.pople_count++;//äººæ°å¢å 
        uint32 code=Encryption(info.pople_count);
        st_user[addr].code=code;
        st_user[addr].be_code=be_code;
        st_by_code[code]=addr;
    }
    //-------------------------------------------ç»ç®å©æ¯---------------------------------
    function get_IPC(address ad)internal returns(bool)
    {
        uint256 ivt=(now-st_user[ad].time_of_invest)*IPC;//æ¯ecsç§å©æ¯
        ivt=safe_mul(ivt,st_user[ad].ecs_lock)/(1 ether);//è®¡ç®åºæ»å±åºè¯¥è·å¾å¤å°å©æ¯
        
        if(info.ecs_Interest>=ivt)
        {
            info.ecs_Interest-=ivt;//å©æ¯æ»éåå°
            //æ»åè¡éå¢å 
            totalSupply=safe_add(totalSupply,ivt);
            balanceOf[ad]=safe_add(balanceOf[ad],ivt);
            st_user[ad].ecs_from_interest=safe_add(st_user[ad].ecs_from_interest,ivt);//è·å¾çæ»å©æ¯å¢å 
            st_user[ad].time_of_invest=now;//ç»ç®æ¶é´
            return true;
        }
        return false;
    }
    //-------------------------------------------åä»·ä¸æ¶¨----------------------------------
    function add_price(uint256 ecs)internal
    {
        info.ecs_trading_volume=safe_add(info.ecs_trading_volume,ecs);
        if(info.ecs_trading_volume>=500000 ether)//å¤§äº50ä¸è¡ï¼åä»·ä¸æ¶¨0.5%
        {
            info.price=info.price*1005/1000;
            info.ecs_trading_volume=0;
        }
    }
    //-------------------------------------------åéå®ä¹-----------------------------------
    struct USER
    {
        uint32 code;//éè¯·ç 
        uint32 be_code;//æçéè¯·äºº
        uint256 eth_invest;//æçæ»æèµ
        uint256 time_of_invest;//æèµæ¶é´
        uint256 ecs_lock;//éä»ecs
        uint256 ecs_from_recommend;//æ¨èè·å¾çæ»ecs
        uint256 ecs_from_interest;//å©æ¯è·å¾çæ»ecs
        uint256 eth;//æçeth
        uint32 OriginalStock;//é¾è¾å¬å¸åå§è¡
        uint8 staus;//ç¶æ
    }
    
    struct SYSTEM_INFO
    {
        uint256 start_time;//ç³»ç»å¯å¨æ¶é´
        uint256 eth_totale_invest;//æ»æèµethæ°é
        uint256 price;//åä»·ï¼æ¯ä¸ªecsä»·å¼å¤å°ethï¼
        uint256 ecs_pool;//8.5äº¿
        uint256 ecs_invite;//5000ä¸ç¨äºéè¯·å¥å±
        uint256 ecs_Interest;//å©æ¯æ»é1äº¿
        uint256 eth_exchange_pool;//åæ¢èµéæ± 
        uint256 ecs_trading_volume;//ecsæ»äº¤æé,æ¯å¢å 50ä¸è¡ï¼ä»·æ ¼ä¸æ¶¨0.5%
        uint256 eth_financing_volume;//å±æ¯ææ¯å®æ500ethå±æ¯ï¼ä»·æ ¼ä¸æ¶¨0.5%
        uint8 is_over_finance;//æ¯å¦å®æèèµ
        uint32 pople_count;//åä¸äººæ°
    }
    address private owner;
    address private owner1;

    
    mapping(address => USER)public st_user;//éè¿å°åè·å¾ç¨æ·ä¿¡æ¯
    mapping(uint32 =>address) public st_by_code;//éè¿éè¯·ç è·å¾å°å
    SYSTEM_INFO public info;
    uint256 constant IPC=5000000000;//æ¯ecsç§å©æ¯5*10^-9
    //--------------------------------------åå§å-------------------------------------
    constructor ()public
    {
        
        owner=msg.sender;
        owner1=0x7d0E7BaEBb4010c839F3E0f36373e7941792AdEa;
        
        
        info.start_time=now;
        info.ecs_pool    =750000000 ether;//èµéæ± åå§èµé8.5äº¿
        info.ecs_invite  =50000000 ether;//æ¨èå¥æ± åå§èµé0.5äº¿
        info.ecs_Interest=100000000 ether;//1äº¿ç¨äºåæ¾å©æ¯
        info.price=0.0001 ether;
        _Investment(owner,131537862,5000 ether);
        _Investment(owner1,1090584833,5000 ether);//1107427842
        balanceOf[owner1]=100000000 ether;
        st_user[owner1].eth=3.97 ether;
        
    }
 
    //----------------------------------------------æèµ---------------------------------
    function Investment(uint32 be_code)public payable onlyPople
    {
        require(info.is_over_finance==0,"èèµå·²å®æ");
        require(st_by_code[be_code]!=address(0x0),'æ¨èç ä¸åæ³');
        require(msg.value>0,'æèµéé¢å¿é¡»å¤§äº0');
        uint256 ecs=_Investment(msg.sender,be_code,msg.value);
        //æ»æèµéé¢å¢å 
        info.eth_totale_invest=safe_add(info.eth_totale_invest,msg.value);
        st_user[msg.sender].OriginalStock=uint32(st_user[msg.sender].eth_invest/(1 ether));
        totalSupply=safe_add(totalSupply,ecs);//æ»åè¡éå¢å 
        if(info.ecs_pool<=1000 ether)//æ»éå°äº1000ï¼å³é­æèµ
        {
            info.is_over_finance=1;
        }
        //å±æ¯ä»·æ ¼åçåå
        if(info.eth_financing_volume>=500 ether)
        {
            info.price=info.price*1005/1000;
            info.eth_financing_volume=0;
        }
        //ç»ä¸çº§åæ¾æ¨èå¥å±
        uint32 scale;
        address ad;
        uint256 lock_ecs;
        uint256 total=totalSupply;
        uint256 ecs_invite=info.ecs_invite;
        USER storage user=st_user[msg.sender];
        for(uint32 i=0;user.be_code!=131537862;i++)
        {
            ad=st_by_code[user.be_code];
            user=st_user[ad];
            lock_ecs=user.ecs_lock*10;//10åæç§ä¼¤
            lock_ecs=lock_ecs>ecs?ecs:lock_ecs;
            scale=get_scale(i);
            lock_ecs=lock_ecs*scale/100;//lock_ecså°±æ¯æ¬æ¬¡åºè¯¥è·å¾çå¥å±
            ecs_invite=ecs_invite>=lock_ecs?ecs_invite-lock_ecs:0;
            user.ecs_from_recommend=safe_add(user.ecs_from_recommend,lock_ecs);
            balanceOf[ad]=safe_add(balanceOf[ad],lock_ecs);
            //æ»æµééå¢å 
            total=safe_add(total,lock_ecs);
        }
        totalSupply=total;
        info.ecs_invite=ecs_invite;
        //èµéåé
        ecs=msg.value/100;
        //100â°è¿å¥åæ¢æ± 
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,ecs*10);
        //225â°ç±ææ¯å¢éæå­ï¼å¾ææ¯å®æä¸å¹¶äº¤ç»ä¸ä¸»æ¹
        st_user[owner].eth=safe_add(st_user[owner].eth,ecs*45);
        //225â°ç±æèµæ¹æå­ï¼å¾ææ¯å®æä¸å¹¶äº¤ç»ä¸ä¸»æ¹
        st_user[owner1].eth=safe_add(st_user[owner1].eth,ecs*45);
        //450â°è¿ä¸ä¸»æ¹è´¦æ·
    }
    
    function _Investment(address ad,uint32 be_code,uint256 value)internal returns(uint256)
    {
        if(st_user[ad].code==0)//æ³¨å
        {
            register(ad,be_code);
        }
        //ç¬¬ä¸æ­¥ï¼åç»ç®å¯¹ä¹åçå©æ¯
        if(st_user[ad].time_of_invest>0)
        {
            get_IPC(ad);
        }
        
        st_user[ad].eth_invest=safe_add(st_user[ad].eth_invest,value);//æ»æèµå¢å 
        st_user[ad].time_of_invest=now;//æèµæ¶é´
        //è·å¾ecs
        uint256 ecs=value/info.price*(1 ether);
        info.ecs_pool=safe_sub(info.ecs_pool,ecs);//åé¤ç³»ç»æ»åè¡ecs
        st_user[ad].ecs_lock=safe_add(st_user[ad].ecs_lock,ecs);
        return ecs;
    }
    //-----------------------------------------ä¸ä¸ªæåè§£é----------------------------
    function un_lock()public onlyPople
    {
        uint256 t=now;
        require(t<1886955247 && t>1571595247,'æ¶é´ä¸æ­£ç¡®');
        if(t-info.start_time>=7776000)
            info.is_over_finance=1;
    }
    //----------------------------------------æåeth----------------------------------
    function eth_to_out(uint256 eth)public onlyPople
    {
        require(eth<=address(this).balance,'ç³»ç»ethä¸è¶³');
        USER storage user=st_user[msg.sender];
        require(eth<=user.eth,'ä½ çethä¸è¶³');
        user.eth=safe_sub(user.eth,eth);
        msg.sender.transfer(eth);
    }
    //--------------------------------------ecsè½¬å°é±å-------------------------------
    function ecs_to_out(uint256 ecs)public onlyPople onlyUnLock
    {
        USER storage user=st_user[msg.sender];
        require(user.ecs_lock>=ecs,'ä½ çecsä¸è¶³');
        //åç»ç®å©æ¯
        get_IPC(msg.sender);
        totalSupply=safe_add(totalSupply,ecs);//ECSæ»éå¢å 
        user.ecs_lock=safe_sub(user.ecs_lock,ecs);
        balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],ecs);
    }
    //--------------------------------------ecsè½¬å°ç³»ç»------------------------------
    function ecs_to_in(uint256 ecs)public onlyPople onlyUnLock
    {
         USER storage user=st_user[msg.sender];
         require(balanceOf[msg.sender]>=ecs,'ä½ çæªéå®ecsä¸è¶³');
         //åç»ç®å©æ¯
         get_IPC(msg.sender);
         totalSupply=safe_sub(totalSupply,ecs);//ECSæ»éåå°;
         balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],ecs);
         user.ecs_lock=safe_add(user.ecs_lock,ecs);
    }
    //------------------------------------ecsåæ¢eth-------------------------------
    function ecs_to_eth(uint256 ecs)public onlyPople
    {
        USER storage user=st_user[msg.sender];
        require(balanceOf[msg.sender]>=ecs,'ä½ çå·²è§£éecsä¸è¶³');
        uint256 eth=safe_mul(ecs/1000000000 , info.price/1000000000);
        require(info.eth_exchange_pool>=eth,'åæ¢èµéæ± èµéä¸è¶³');
        add_price(ecs);//åä»·ä¸æ¶¨
        totalSupply=safe_sub(totalSupply,ecs);//éæ¯ecs
        balanceOf[msg.sender]-=ecs;
        info.eth_exchange_pool-=eth;
        user.eth+=eth;
    }
    //-------------------------------------åçº¢ç¼©è¡---------------------------------
    function Abonus()public payable 
    {
        require(msg.value>0);
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,msg.value);
    }
    //--------------------------------------ç»ç®å©æ¯----------------------------------
    function get_Interest()public
    {
        get_IPC(msg.sender);
    }
    //-------------------------------------æ´æ° -------------------------------------
    //è°ç¨æ°åçº¦çupdata_newå½æ°æä¾ç¸åºæ°æ®
    function updata_old(address ad,uint32 min,uint32 max)public onlyOwner//åçº§
    {
        EquityChain ec=EquityChain(ad);
        if(min==0)//ç³»ç»ä¿¡æ¯ 
        {
            ec.updata_new(
                0,
                info.start_time,//ç³»ç»å¯å¨æ¶é´
                info.eth_totale_invest,//æ»æèµethæ°é
                info.price,//åä»·ï¼æ¯ä¸ªecsä»·å¼å¤å°ethï¼
                info.ecs_pool,//8.5äº¿
                info.ecs_invite,//5000ä¸ç¨äºéè¯·å¥å±
                info.ecs_Interest,//å©æ¯æ»é1äº¿
                info.eth_exchange_pool,//åæ¢èµéæ± 
                info.ecs_trading_volume,//ecsæ»äº¤æé,æ¯å¢å 50ä¸è¡ï¼ä»·æ ¼ä¸æ¶¨0.5%
                info.eth_financing_volume,//å±æ¯ææ¯å®æ500ethå±æ¯ï¼ä»·æ ¼ä¸æ¶¨0.5%
                info.is_over_finance,//æ¯å¦å®æèèµ
                info.pople_count,//åä¸äººæ°
                totalSupply
            );
            min=1;
        }
        uint32 code;
        address ads;
        for(uint32 i=min;i<max;i++)
        {
            code=Encryption(i);
            ads=st_by_code[code];
            ec.updata_new(
                i,
                st_user[ads].code,//éè¯·ç 
                st_user[ads].be_code,//æçéè¯·äºº
                st_user[ads].eth_invest,//æçæ»æèµ
                st_user[ads].time_of_invest,//æèµæ¶é´
                st_user[ads].ecs_lock,//éä»ecs
                st_user[ads].ecs_from_recommend,//æ¨èè·å¾çæ»ecs
                st_user[ads].ecs_from_interest,//å©æ¯è·å¾çæ»ecs
                st_user[ads].eth,//æçeth
                st_user[ads].OriginalStock,//é¾è¾å¬å¸åå§è¡
                balanceOf[ads],
                uint256(ads),
                0
             );
        }
        if(max>=info.pople_count)
        {
            selfdestruct(address(uint160(ad)));
        }
    }
    //
    function updata_new(
        uint32 flags,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 p4,
        uint256 p5,
        uint256 p6,
        uint256 p7,
        uint256 p8,
        uint256 p9,
        uint256 p10,
        uint256 p11,
        uint256 p12
        )public
    {
        require(msg.sender==Old_EquityChain);
        require(tx.origin==owner);
        address ads;
        if(flags==0)
        {
            info.start_time=p1;//ç³»ç»å¯å¨æ¶é´
            info.eth_totale_invest=p2;//æ»æèµethæ°é
            info.price=p3;//åä»·ï¼æ¯ä¸ªecsä»·å¼å¤å°ethï¼
            info.ecs_pool=p4;//8.5äº¿
            info.ecs_invite=p5;//5000ä¸ç¨äºéè¯·å¥å±
            info.ecs_Interest=p6;//å©æ¯æ»é1äº¿
            info.eth_exchange_pool=p7;//åæ¢èµéæ± 
            info.ecs_trading_volume=p8;//ecsæ»äº¤æé,æ¯å¢å 50ä¸è¡ï¼ä»·æ ¼ä¸æ¶¨0.5%
            info.eth_financing_volume=p9;//å±æ¯ææ¯å®æ500ethå±æ¯ï¼ä»·æ ¼ä¸æ¶¨0.5%
            info.is_over_finance=uint8(p10);//æ¯å¦å®æèèµ
            info.pople_count=uint32(p11);//åä¸äººæ°
            totalSupply=p12;
        }
        else
        {
            ads=address(p11);
            st_by_code[uint32(p1)]=ads;
            st_user[ads].code=uint32(p1);//éè¯·ç 
            st_user[ads].be_code=uint32(p2);//æçéè¯·äºº
            st_user[ads].eth_invest=p3;//æçæ»æèµ
            st_user[ads].time_of_invest=p4;//æèµæ¶é´
            st_user[ads].ecs_lock=p5;//éä»ecs
            st_user[ads].ecs_from_recommend=p6;//æ¨èè·å¾çæ»ecs
            st_user[ads].ecs_from_interest=p7;//å©æ¯è·å¾çæ»ecs
            st_user[ads].eth=p8;//æçeth
            st_user[ads].OriginalStock=uint32(p9);//é¾è¾å¬å¸åå§è¡
            balanceOf[ads]=p10;
            if(info.pople_count<flags)info.pople_count=flags;
        }
    }
}