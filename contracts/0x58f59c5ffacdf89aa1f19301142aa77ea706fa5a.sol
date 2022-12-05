pragma solidity^0.4.20;  
//å®ä¾åä»£å¸
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
  bool lock = false;
 
 
    /**
     * åå°åæé å½æ°
     */
    function Ownable () public {
        owner = msg.sender;
    }
 
    /**
     * å¤æ­å½ååçº¦è°ç¨èæ¯å¦æ¯åçº¦çææè
     */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * åçº¦çææèææ´¾ä¸ä¸ªæ°çç®¡çå
     * @param  newOwner address æ°çç®¡çåå¸æ·å°å
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract BebPos is Ownable{

    //ä¼åæ°æ®ç»æ
   struct BebUser {
        address customerAddr;//ä¼åaddress
        uint256 amount; //å­æ¬¾éé¢ 
        uint256 bebtime;//å­æ¬¾æ¶é´
        //uint256 interest;//å©æ¯
    }
    uint256 Bebamount;//BEBæªåè¡æ°é
    uint256 bebTotalAmount;//BEBæ»é
    uint256 sumAmount = 0;//ä¼åçæ»é 
    uint256 OneMinuteBEB;//åå§å1åéäº§çBEBæ°é
    tokenTransfer public bebTokenTransfer; //ä»£å¸ 
    uint8 decimals = 18;
    uint256 OneMinute=1 minutes; //1åé
    //ä¼å ç»æ 
    mapping(address=>BebUser)public BebUsers;
    address[] BebUserArray;//å­æ¬¾çå°åæ°ç»
    //äºä»¶
    event messageBetsGame(address sender,bool isScuccess,string message);
    //BEBçåçº¦å°å 
    function BebPos(address _tokenAddress,uint256 _Bebamount,uint256 _bebTotalAmount,uint256 _OneMinuteBEB){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
         Bebamount=_Bebamount*10**18;//åå§è®¾å®ä¸ºåè¡æ°é
         bebTotalAmount=_bebTotalAmount*10**18;//åå§è®¾å®BEBæ»é
         OneMinuteBEB=_OneMinuteBEB*10**18;//åå§å1åéäº§çBEBæ°é 
         BebUserArray.push(_tokenAddress);
     }
         //å­å¥ BEB
    function BebDeposit(address _addr,uint256 _value) public{
        //å¤æ­ä¼åå­æ¬¾éé¢æ¯å¦ç­äº0
       if(BebUsers[msg.sender].amount == 0){
           //å¤æ­æªåè¡æ°éæ¯å¦å¤§äº20ä¸ªBEB
           if(Bebamount > OneMinuteBEB){
           bebTokenTransfer.transferFrom(_addr,address(address(this)),_value);//å­å¥BEB
           BebUsers[_addr].customerAddr=_addr;
           BebUsers[_addr].amount=_value;
           BebUsers[_addr].bebtime=now;
           sumAmount+=_value;//æ»å­æ¬¾å¢å 
           //å å¥å­æ¬¾æ°ç»å°å
           //addToAddress(msg.sender);//å å¥å­æ¬¾æ°ç»å°å
           messageBetsGame(msg.sender, true,"è½¬å¥æå");
            return;   
           }
           else{
            messageBetsGame(msg.sender, true,"è½¬å¥å¤±è´¥,BEBæ»éå·²ç»å¨é¨åè¡å®æ¯");
            return;   
           }
       }else{
            messageBetsGame(msg.sender, true,"è½¬å¥å¤±è´¥,è¯·åååºåçº¦ä¸­çä½é¢");
            return;
       }
    }

    //åæ¬¾
    function redemption() public {
        address _address = msg.sender;
        BebUser storage user = BebUsers[_address];
        require(user.amount > 0);
        //
        uint256 _time=user.bebtime;//å­æ¬¾æ¶é´
        uint256 _amuont=user.amount;//ä¸ªäººå­æ¬¾éé¢
           uint256 AA=(now-_time)/OneMinute*OneMinuteBEB;//ç°å¨æ¶é´-å­æ¬¾æ¶é´/60ç§*æ¯åéçäº§20BEB
           uint256 BB=bebTotalAmount-Bebamount;//è®¡ç®åºå·²æµéæ°é
           uint256 CC=_amuont*AA/BB;//å­æ¬¾*AA/å·²æµéæ°é
           //å¤æ­æªåè¡æ°éæ¯å¦å¤§äº20BEB
           if(Bebamount > OneMinuteBEB){
              Bebamount-=CC; 
             //user.interest+=CC;//åè´¦æ·å¢å å©æ¯
             user.bebtime=now;//éç½®å­æ¬¾æ¶é´ä¸ºç°å¨
           }
        //å¤æ­æªåè¡æ°éæ¯å¦å¤§äº20ä¸ªBEB
        if(Bebamount > OneMinuteBEB){
            Bebamount-=CC;//ä»åè¡æ»éå½ä¸­åå°
            sumAmount-=_amuont;
            bebTokenTransfer.transfer(msg.sender,CC+user.amount);//è½¬è´¦ç»ä¼å + ä¼åæ¬é+å½åå©æ¯ 
           //æ´æ°æ°æ® 
            BebUsers[_address].amount=0;//ä¼åå­æ¬¾0
            BebUsers[_address].bebtime=0;//ä¼åå­æ¬¾æ¶é´0
            //BebUsers[_address].interest=0;//å©æ¯å½0
            messageBetsGame(_address, true,"æ¬éåå©æ¯æååæ¬¾");
            return;
        }
        else{
            Bebamount-=CC;//ä»åè¡æ»éå½ä¸­åå°
            sumAmount-=_amuont;
            bebTokenTransfer.transfer(msg.sender,_amuont);//è½¬è´¦ç»ä¼å + ä¼åæ¬é 
           //æ´æ°æ°æ® 
            BebUsers[_address].amount=0;//ä¼åå­æ¬¾0
            BebUsers[_address].bebtime=0;//ä¼åå­æ¬¾æ¶é´0
            //BebUsers[_address].interest=0;//å©æ¯å½0
            messageBetsGame(_address, true,"BEBæ»éå·²ç»åè¡å®æ¯ï¼ååæ¬é");
            return;  
        }
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function getSumAmount() public view returns(uint256){
        return sumAmount;
    }
    function getBebAmount() public view returns(uint256){
        return Bebamount;
    }
    function getBebAmountzl() public view returns(uint256){
        uint256 _sumAmount=bebTotalAmount-Bebamount;
        return _sumAmount;
    }

    function getLength() public view returns(uint256){
        return (BebUserArray.length);
    }
     function getUserProfit(address _form) public view returns(address,uint256,uint256,uint256){
       address _address = _form;
       BebUser storage user = BebUsers[_address];
       assert(user.amount > 0);
       uint256 A=(now-user.bebtime)/OneMinute*OneMinuteBEB;
       uint256 B=bebTotalAmount-Bebamount;
       uint256 C=user.amount*A/B;
        return (_address,user.bebtime,user.amount,C);
    }
    function()payable{
        
    }
}