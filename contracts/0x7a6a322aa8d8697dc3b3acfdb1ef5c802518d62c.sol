/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract BebBank is Ownable{
    uint256 jiechu;//ååº
    uint256 huankuan;//è¿æ¬¾
    uint256 shouyi;//æ¶ç
    uint256 yuerbaoAmount;//ä½é¢å®æ»éé¢
    uint256 dingqibaoAmount;//å®æå®æ»éé¢
    uint256 zonglixi;//æ»å©æ¯
    uint256 yuebaohuilv=8;//ä½é¢å®å¹´å©ç
    uint256 dingqibaohuilv=20;//å®æå®å¹´å©ç
    struct useryuerbao{
        uint256 amount;//å­æ¬¾éé¢
        uint256 lixishouyi;//å©æ¯æ¶ç
        uint256 cunkuantime;//å­æ¬¾æ¶é´
        bool vote;//ç¶æ
    }
    struct userDingqi{
        uint256 amount;//å­æ¬¾éé¢
        uint256 lixishouyi;//å©æ¯æ¶ç
        uint256 cunkuantime;//å­æ¬¾æ¶é´
        uint256 yuefen;//å­æ¬¾æ¶é´
        bool vote;//ç¶æ
    }
    mapping(address=>useryuerbao)public users;
    mapping(address=>userDingqi)public userDingqis;
    //ä½é¢å®å­
    function yuerbaoCunkuan()payable public{
        require(tx.origin == msg.sender);
        useryuerbao storage _user=users[msg.sender];
        require(!_user.vote,"Please withdraw money first.ï¼");
        _user.amount=msg.value;
        _user.cunkuantime=now;
        _user.vote=true;
        yuerbaoAmount+=msg.value;
    }
    //ä½é¢å®å
    function yuerbaoQukuan() public{
        require(tx.origin == msg.sender);
        useryuerbao storage _users=users[msg.sender];
        require(_users.vote,"You have no depositï¼");
        uint256 _amount=_users.amount;
        uint256 lixieth=_amount*yuebaohuilv/100;
        uint256 minteeth=lixieth/365/1440;
        uint256 _minte=(now-_users.cunkuantime)/60;
        require(_minte>=1,"Must be greater than one minute ");
        uint256 _shouyieth=minteeth*_minte;
        uint256 _sumshouyis=_amount+_shouyieth;
        require(this.balance>=_sumshouyis,"Sorry, your credit is running lowï¼");
        msg.sender.transfer(_sumshouyis);
        _users.amount=0;
        _users.cunkuantime=0;
        _users.vote=false;
        zonglixi+=_shouyieth;
        _users.lixishouyi+=_shouyieth;
    }
    //å®æå®å­
    function dingqibaoCunkuan(uint256 _yuefen)payable public{
        require(tx.origin == msg.sender);
        userDingqi storage _userDingqi=userDingqis[msg.sender];
        require(!_userDingqi.vote,"Please withdraw money first.ï¼");
        require(_yuefen>=1,"Deposit must be greater than or equal to 1 monthï¼");
        require(_yuefen<=12,"Deposit must be less than or equal to 12 monthsï¼");
        _userDingqi.amount=msg.value;
        _userDingqi.cunkuantime=now;
        _userDingqi.vote=true;
        _userDingqi.yuefen=_yuefen;
        dingqibaoAmount+=msg.value;
    }
    //å®æå®å
    function dingqibaoQukuan() public{
        require(tx.origin == msg.sender);
        userDingqi storage _userDingqis=userDingqis[msg.sender];
        require(_userDingqis.vote,"You have no depositï¼");
        uint256 _mintes=(now-_userDingqis.cunkuantime)/86400/30;
        require(_mintes>=_userDingqis.yuefen,"Your deposit is not due yetï¼");
        uint256 _amounts=_userDingqis.amount;
        uint256 lixiETHs=_amounts*dingqibaohuilv/100;
        uint256 minteETHs=lixiETHs/12;
        uint256 _shouyis=minteETHs*_mintes;
        uint256 _sumshouyi=_amounts+_shouyis;
        require(this.balance>=_sumshouyi,"Sorry, your credit is running lowï¼");
        msg.sender.transfer(_sumshouyi);
        _userDingqis.amount=0;
        _userDingqis.cunkuantime=0;
        _userDingqis.vote=false;
        _userDingqis.yuefen=0;
        zonglixi+=_shouyis;
        _userDingqis.lixishouyi+=_shouyis;
    }
    //æ±ç
    function guanliHuilv(uint256 _yuebaohuilv,uint256 _dingqibaohuilv)onlyOwner{
        require(_dingqibaohuilv>0);
        require(_yuebaohuilv>0);
        dingqibaohuilv=_dingqibaohuilv;
        yuebaohuilv=_yuebaohuilv;
    }
    //è¿æ¬¾+æ¶ç
    function guanliHuankuan(uint256 _shouyi)payable onlyOwner{
        huankuan+=msg.value;
        jiechu-=msg.value;
        shouyi+=_shouyi;
    }
    //åæ¬¾
    function guanliJiekuan(uint256 _eth)onlyOwner{
        uint256 ethsjie=_eth*10**18;
        jiechu+=ethsjie;
        owner.transfer(ethsjie);
    }
    //åçº¦ä½é¢
    function getBalance() public view returns(uint256){
         return this.balance;
    }
    //æ¥è¯¢æ»ä»åºå©æ¯
    function getsumlixi() public view returns(uint256){
         return zonglixi;
    }
    //æ¥è¯¢æ»ä»åºå©æ¯
    function getzongcunkuan() public view returns(uint256,uint256,uint256){
         return (yuerbaoAmount,dingqibaoAmount,jiechu);
    }
    //æ±ç
    function gethuilv() public view returns(uint256,uint256){
         return (yuebaohuilv,dingqibaohuilv);
    }
    //ä½é¢å®æ¥è¯¢
    function getYuerbao() public view returns(uint256,uint256,uint256,uint256,uint256,bool){
        useryuerbao storage _users=users[msg.sender];
        uint256 _amount=_users.amount;
        uint256 lixieth=_amount*yuebaohuilv/100;
        uint256 minteeth=lixieth/365/1440;
        uint256 _minte=(now-_users.cunkuantime)/60;
        if(_users.cunkuantime==0){
            _minte=0;
        }
        uint256 _shouyieth=minteeth*_minte;
         return (_users.amount,_users.lixishouyi,_users.cunkuantime,_shouyieth,_minte,_users.vote);
    }//å®æå®æ¥è¯¢
    function getDignqibao() public view returns(uint256,uint256,uint256,uint256,uint256,bool){
        userDingqi storage _users=userDingqis[msg.sender];
        uint256 _amounts=_users.amount;
        uint256 lixiETHs=_amounts*dingqibaohuilv/100;
        uint256 minteETHs=lixiETHs/12*_users.yuefen;
         return (_users.amount,_users.lixishouyi,_users.cunkuantime,_users.yuefen,minteETHs,_users.vote);
    }
    function ETHwithdrawal(uint256 amount) payable  onlyOwner {
       uint256 _amount=amount* 10 ** 18;
       require(this.balance>=_amount,"Insufficient contract balance");
       owner.transfer(_amount);
    }
    function ()payable{
        
    }
}