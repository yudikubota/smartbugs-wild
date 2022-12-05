/**
 *Submitted for verification at Etherscan.io on 2020-01-21
*/

/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
interface tokenTransferUSDT {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balances(address receiver) returns(uint256);
}
interface tokenTransferBET {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}
contract SafeMath {
      address public owner;
       
  function SafeMath () public {
        owner = msg.sender;
    }
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}
contract bebBUYtwo is SafeMath{
tokenTransfer public bebTokenTransfer; //ä»£å¸ 
tokenTransferUSDT public bebTokenTransferUSDT;
tokenTransferBET public bebTokenTransferBET;
    uint8 decimals;
    uint256 bebethex;//eth-beb
    uint256 BEBday;
    uint256 bebjiage;
    uint256 bebtime;
    uint256 usdtex;
    address ownerstoex;
    uint256 ProfitSUMBEB;
    uint256 SUMdeposit;
    uint256 SUMWithdraw;
    uint256 USDTdeposit;
    uint256 USDTWithdraw;
    uint256 BEBzanchen;//èµææ»é
    uint256 BEBfandui;//åå¯¹æ»é
    address shenqingzhichu;//ç³è¯·äººå°å
    uint256 shenqingAmount;//ç³è¯·éé¢
    uint256 huobileixing;//è´§å¸ç±»å1=ETHï¼2=BEBï¼3=USDT
    string purpose;//ç¨é
    bool KAIGUAN;//è¡¨å³å¼å³
    string boody;//æ¯å¦éè¿
    struct BEBuser{
        uint256 amount;
        uint256 dayamount;//æ¯å¤©
        uint256 bebdays;//å¤©æ°
        uint256 usertime;//æ¶é´
        uint256 zhiyaBEB;
        uint256 sumProfit;
        uint256 amounts;
        bool vote;
    }
    struct USDTuser{
        uint256 amount;
        uint256 dayamount;//æ¯å¤©
        uint256 bebdays;//å¤©æ°
        uint256 usertime;//æ¶é´
        uint256 zhiyaBEB;
        uint256 sumProfit;
    }
    mapping(address=>USDTuser)public USDTusers;
    mapping(address=>BEBuser)public BEBusers;
    function bebBUYtwo(address _tokenAddress,address _usdtadderss,address _BETadderss,address _addr){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         bebTokenTransferUSDT =tokenTransferUSDT(_usdtadderss);
         bebTokenTransferBET =tokenTransferBET(_BETadderss);
         ownerstoex=_addr;
         bebethex=5795;
         decimals=18;
         BEBday=20;
         bebjiage=172540000000000;
         bebtime=now;
         usdtex=166;
     }
     //USDT
      function setUSDT(uint256 _value) public{
         require(_value>=1000000);
         uint256 _usdts=SafeMath.safeMul(_value,120);//100;
         uint256 _usdt=SafeMath.safeDiv(_usdts,100);//100;
         uint256 _bebex=SafeMath.safeMul(bebjiage,usdtex);
         uint256 _usdtexs=SafeMath.safeDiv(1000000000000000000,_bebex);
         uint256 _usdtex=SafeMath.safeMul(_usdtexs,_value);
         USDTuser storage _user=USDTusers[msg.sender];
         require(_user.amount==0,"Already invested ");
         bebTokenTransferUSDT.transferFrom(msg.sender,address(this),_value);
         bebTokenTransfer.transferFrom(msg.sender,address(this),_usdtex);
         _user.zhiyaBEB=_usdtex;
         _user.amount=_value;
         _user.dayamount=SafeMath.safeDiv(_usdt,BEBday);
         _user.usertime=now;
         _user.sumProfit+=_value*20/100;
         ProfitSUMBEB+=_usdtex*10/100;
         USDTdeposit+=_value;
         
     }
     function setETH()payable public{
         require(msg.value>=500000000000000000);
         uint256 _eths=SafeMath.safeMul(msg.value,120);
         uint256 _eth=SafeMath.safeDiv(_eths,100);
         uint256 _beb=SafeMath.safeMul(msg.value,bebethex);
         BEBuser storage _user=BEBusers[msg.sender];
         require(_user.amount==0,"Already invested ");
         bebTokenTransfer.transferFrom(msg.sender,address(this),_beb);
         _user.zhiyaBEB=_beb;
         _user.amount=msg.value;
         _user.dayamount=SafeMath.safeDiv(_eth,BEBday);
         _user.usertime=now;
         _user.sumProfit+=msg.value*20/100;
         ProfitSUMBEB+=_beb*10/100;
         SUMdeposit+=msg.value;
         
     }
     function DayQuKuan()public{
         if(now-bebtime>86400){
            bebtime+=86400;
            bebjiage+=660000000000;//æ¯æ¥åºå®ä¸æ¶¨0.00000066ETH
            bebethex=1 ether/bebjiage;
        }
        BEBuser storage _users=BEBusers[msg.sender];
        uint256 _eths=_users.dayamount;
        require(_eths>0,"You didn't invest");
        require(_users.bebdays<BEBday,"Expired");
        uint256 _time=(now-_users.usertime)/86400;
        require(_time>=1,"Less than a day");
        uint256 _ddaayy=_users.bebdays+1;
        if(BEBday==20){
        msg.sender.transfer(_users.dayamount);
        SUMWithdraw+=_users.dayamount;
        _users.bebdays=_ddaayy;
        _users.usertime=now;
        if(_ddaayy==BEBday){
        uint256 _bebs=_users.zhiyaBEB*90/100;
         bebTokenTransfer.transfer(msg.sender,_bebs);
         _users.amount=0;
         _users.dayamount=0;
          _users.bebdays=0;
          _users.zhiyaBEB=0;
        }
        }else{
         uint256 _values=SafeMath.safeDiv(_users.zhiyaBEB,BEBday);
         bebTokenTransfer.transfer(msg.sender,_values);
        _users.bebdays=_ddaayy;
        _users.usertime=now;
        if(_ddaayy==BEBday){
         uint256 _bebss=_users.zhiyaBEB*90/100;
         bebTokenTransfer.transfer(msg.sender,_bebss);
         _users.amount=0;
         _users.dayamount=0;
          _users.bebdays=0;
          _users.zhiyaBEB=0;
        }   
        }
        
     }
     function DayQuKuanUsdt()public{
         if(now-bebtime>86400){
            bebtime+=86400;
            bebjiage+=660000000000;//æ¯æ¥åºå®ä¸æ¶¨0.00000066ETH
            bebethex=1 ether/bebjiage;
        }
        USDTuser storage _users=USDTusers[msg.sender];
        uint256 _eths=_users.dayamount;
        require(_eths>0,"You didn't invest");
        require(_users.bebdays<BEBday,"Expired");
        uint256 _time=(now-_users.usertime)/86400;
        require(_time>=1,"Less than a day");
        uint256 _ddaayy=_users.bebdays+1;
        if(BEBday==20){
        bebTokenTransferUSDT.transfer(msg.sender,_eths);
        USDTWithdraw+=_eths;
        _users.bebdays=_ddaayy;
        _users.usertime=now;
        if(_ddaayy==BEBday){
        uint256 _bebs=_users.zhiyaBEB*90/100;
         bebTokenTransfer.transfer(msg.sender,_bebs);
         _users.amount=0;
         _users.dayamount=0;
          _users.bebdays=0;
          _users.zhiyaBEB=0;
        }
        }else{
         uint256 _values=SafeMath.safeDiv(_users.zhiyaBEB,BEBday);
         bebTokenTransfer.transfer(msg.sender,_values);
        _users.bebdays=_ddaayy;
        _users.usertime=now;
        if(_ddaayy==BEBday){
         uint256 _bebss=_users.zhiyaBEB*90/100;
         bebTokenTransfer.transfer(msg.sender,_bebss);
         _users.amount=0;
         _users.dayamount=0;
          _users.bebdays=0;
          _users.zhiyaBEB=0;
        }   
        }
        
     }
     //ç³è¯·æ¯åº
     function ChaiwuzhiChu(address _addr,uint256 _values,uint256 _leixing,string _purpose)public{
         require(!KAIGUAN,"The last round of voting is not over");
         require(getTokenBalanceBET(address(this))<1,"And bet didn't get it back");
         uint256 _value=getTokenBalanceBET(msg.sender);//BETæææ°é
        require(_value>=1 ether,"You have no right to apply");
         KAIGUAN=true;//å¼å§æç¥¨
         shenqingzhichu=_addr;//ç³è¯·äººå°å
         shenqingAmount=_values;//ç³è¯·æ¯åºéé¢
         huobileixing=_leixing;//1=eth,2=BEB,3=USDT
         purpose=_purpose;
         boody="æç¥¨ä¸­...";
     }
     //æç¥¨èµæ
    function setVoteZancheng()public{
        BEBuser storage _user=BEBusers[msg.sender];
        require(KAIGUAN);
        uint256 _value=getTokenBalanceBET(msg.sender);//BETæææ°é
        require(_value>=1 ether,"You have no right to vote");
        require(!_user.vote,"You have voted");
        bebTokenTransferBET.transferFrom(msg.sender,address(this),_value);//è½¬å¥BET
        BEBzanchen+=_value;//èµæå¢å 
        _user.amounts=_value;//èµå¼
        _user.vote=true;//èµå¼å·²ç»æç¥¨
        if(BEBzanchen>=51 ether){
            //æç¥¨éè¿æ§è¡è´¢å¡æ¯åº
            if(huobileixing!=0){
                if(huobileixing==1){
                 shenqingzhichu.transfer(shenqingAmount);//æ¯åºETH
                 KAIGUAN=false;
                 BEBfandui=0;//ç¥¨æ°å½é¶
                 BEBzanchen=0;//ç¥¨æ°å½é¶
                 huobileixing=0;//æ¤éæ¬æ¬¡ç³è¯·
                 boody="éè¿";
                 //shenqingzhichu=0;//æ¤éå°å
                 //shenqingAmount=0;//æ¤éç³è¯·éé¢
                }else{
                    if(huobileixing==2){
                      bebTokenTransfer.transfer(shenqingzhichu,shenqingAmount);//æ¯åºBEB
                      KAIGUAN=false;
                      BEBfandui=0;//ç¥¨æ°å½é¶
                      BEBzanchen=0;//ç¥¨æ°å½é¶
                      huobileixing=0;//æ¤éæ¬æ¬¡ç³è¯·
                      boody="éè¿";
                    }else{
                        bebTokenTransferUSDT.transfer(shenqingzhichu,shenqingAmount);//æ¯åºUSDT
                        KAIGUAN=false;
                        BEBfandui=0;//ç¥¨æ°å½é¶
                        BEBzanchen=0;//ç¥¨æ°å½é¶
                        huobileixing=0;//æ¤éæ¬æ¬¡ç³è¯·
                        boody="éè¿";
                    }          
                 }
            }
        }
    }
    //æç¥¨åå¯¹
    function setVoteFandui()public{
        require(KAIGUAN);
        BEBuser storage _user=BEBusers[msg.sender];
        uint256 _value=getTokenBalanceBET(msg.sender);
        require(_value>=1 ether,"You have no right to vote");
        require(!_user.vote,"You have voted");
        bebTokenTransferBET.transferFrom(msg.sender,address(this),_value);//è½¬å¥BET
        BEBfandui+=_value;//èµæå¢å 
        _user.amounts=_value;//èµå¼
        _user.vote=true;//èµå¼å·²ç»æç¥¨
        if(BEBfandui>=51 ether){
            //åå¯¹å¤§äº51%è¡¨å³ä¸éè¿
            BEBfandui=0;//ç¥¨æ°å½é¶
            BEBzanchen=0;//ç¥¨æ°å½é¶
            huobileixing=0;//æ¤éæ¬æ¬¡ç³è¯·
            shenqingzhichu=0;//æ¤éå°å
            shenqingAmount=0;//æ¤éç³è¯·éé¢
            KAIGUAN=false;
            boody="æç»";
        }
    }
    //ååBET
     function quhuiBET()public{
        require(!KAIGUAN,"Bet cannot be retrieved while voting is in progress");
        BEBuser storage _user=BEBusers[msg.sender];
        require(_user.vote,"You did not vote");
        bebTokenTransferBET.transfer(msg.sender,_user.amounts);//éåBET
        _user.vote=false;
        _user.amounts=0;
     }
     function setBEB(uint256 _value)public{
         require(_value>0);
         bebTokenTransfer.transferFrom(msg.sender,address(this),_value);
         ProfitSUMBEB+=_value;
     }
     function setusdtex(uint256 _value)public{
         require(ownerstoex==msg.sender);
         usdtex=_value;
     }
     function querBalance()public view returns(uint256){
         return this.balance;
     }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function getTokenBalanceUSDT() public view returns(uint256){
         return bebTokenTransferUSDT.balances(address(this));
    }
    function BETwithdrawal(uint256 amount)onlyOwner {
      bebTokenTransferBET.transfer(msg.sender,amount);
    }
    function setBEBday(uint256 _BEBday)onlyOwner{
        BEBday=_BEBday;
    }
    function getTokenBalanceBET(address _addr) public view returns(uint256){
         return bebTokenTransferBET.balanceOf(_addr);
    }
    function getQuanju()public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256){
            
         return (bebjiage,bebethex,ProfitSUMBEB,SUMdeposit,SUMWithdraw,USDTdeposit,USDTWithdraw);
    }
    function getUSDTuser(address _addr)public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
            USDTuser storage _users=USDTusers[_addr];
            //uint256 amount;//USDTæ»æèµ
        //uint256 dayamount;//æ¯å¤©åæ¬æ¯
        //uint256 bebdays;//åæ¬¾å¤©æ°
        //uint256 usertime;//ä¸ä¸æ¬¡åæ¬¾æ¶é´
        //uint256 zhiyaBEB;è´¨æ¼BEBæ°é
        //uint256 sumProfit;æ»æ¶ç
         return (_users.amount,_users.dayamount,_users.bebdays,_users.usertime,_users.zhiyaBEB,_users.sumProfit);
    }
    function getBEBuser(address _addr)public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool){
            BEBuser storage _users=BEBusers[_addr];
            //uint256 amount;//æèµéé¢
            //uint256 dayamount;//æ¯å¤©åæ¬æ¯
            //uint256 bebdays;//åæ¬¾å¤©æ°
            //uint256 usertime;//ä¸ä¸æ¬¡åæ¬¾æ¶é´
            //uint256 zhiyaBEB;//è´¨æ¼BEBæ°é
            //uint256 sumProfit;//æ»æ¶ç
            // uint256 amounts;//æç¥¨BETæ°é
           //bool vote;//æ¯å¦æç¥¨
         return (_users.amount,_users.dayamount,_users.bebdays,_users.usertime,_users.zhiyaBEB,_users.sumProfit,_users.amounts,_users.vote);
    }
    function getBETvote()public view returns(uint256,uint256,address,uint256,uint256,string,bool,string){
            //uint256 BEBzanchen;//èµææ»é
    //uint256 BEBfandui;//åå¯¹æ»é
    //address shenqingzhichu;//ç³è¯·äººå°å
    //uint256 shenqingAmount;//ç³è¯·éé¢
    //uint256 huobileixing;//è´§å¸ç±»å1=ETHï¼2=BEBï¼3=USDT
    //string purpose;//ç¨é
    //bool KAIGUAN;//è¡¨å³å¼å³
    //string boody;//æ¯å¦éè¿ï¼ç¶æ
         return (BEBzanchen,BEBfandui,shenqingzhichu,shenqingAmount,huobileixing,purpose,KAIGUAN,boody);
    }
    
    function ()payable{
        
    }
}