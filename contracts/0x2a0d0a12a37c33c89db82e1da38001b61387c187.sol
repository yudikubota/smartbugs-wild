pragma solidity >=0.4.21 <0.6.0;

//import "./DataContract.sol";
// å½©ç¥¨åçº¦
contract LotteryShop{
    //æ°æ®åçº¦
    //DataContract dataContract;
    //è´­ä¹°å½©ç¥¨äºä»¶ï¼å¨è´­ä¹°å½©ç¥¨æ¹æ³ä¸­è°ç¨
    event BuyLottery(address indexed buyer,uint money,uint16 luckNum);
    //å¼å¥äºä»¶ï¼å¨å¼å¥æ¹æ³ä¸­è°ç¨
    event DrawLottery(address winner,uint money,uint16 luckNum);

    //è´­ä¹°è®°å½ï¼è´­ä¹°èçaddress, å½©ç¥¨å·ç ï¼
    mapping(address=>uint) buyMapping;
    //è´­ä¹°ç¨æ·çå°å
    address payable[]  usrAdrList;

    //ç®¡çåå°å
    address  manageAdr;
    //åçº¦å°å
    address payable contractAdr;
    //æ°æ®åçº¦å°å
    address payable dataContractAdr;
    constructor() public {//address _dataContractAddr
        //å°åçº¦é¨ç½²äººçå°åä¿å­èµ·æ¥ä½ä¸ºç®¡çåå°å
        manageAdr=msg.sender;
        //å°å½ååçº¦å¯¹è±¡çå°åä¿å­
        // contractAdr = address(this);
        contractAdr = address(uint160(address(this)));// address(this);
        //contractAdr = msg.sender;
        //åå§åæé æ°æ®åçº¦
        //dataContract = DataContract(_dataContractAddr);
        //dataContractAdr = address(uint160(_dataContractAddr));

    }

    //0.1 æ¾ç¤ºç®¡çåå°å
    /*function ShowManageAdr() constant returns(address){
        return manageAdr;
    }*/

    //0.2 æ¾ç¤ºè°ç¨èçå½©ç¥¨æ°æ®
    /*function ShowInvokerCaiPiao() constant returns(uint){
        return buyMapping[msg.sender];
    }*/
    function ShowInvokerCaiPiao()  public view returns(uint){
        return buyMapping[msg.sender];
    }
    function ShowInvokerBalance()  public view returns(uint){
        return msg.sender.balance;
    }

    //0.3 æ¾ç¤ºç®¡çåä½é¢
    /*function ShowManageBalance() constant returns(uint){
        return manageAdr.balance;
    }*/
    function ShowManageBalance()  public view  returns(uint){
        return manageAdr.balance;
    }

    //0.4 æ¾ç¤ºåçº¦ä½é¢
    /*function ShowContractMoney() constant returns(uint){
        return contractAdr.balance;
    }*/
    function ShowContractMoney() public view returns(uint){
        return contractAdr.balance;
    }
    function ShowContractAdr() public view returns(address payable){
         return contractAdr;
    }
    function ShowManageAdr() public view returns(address){
        return manageAdr;
    }
    //0.5 è·åä¹°å®¶å°ååè¡¨
    function getAllUsrAddress() public view returns(address payable[] memory){
        return usrAdrList;
    }
    //0.5 ä¹°å½©ç¥¨æ¹æ³
    function BuyCaiPiao(uint16 haoMa) payable public {
        //0. å¤æ­ç¨æ·è´¦æ·æ¯å¦æ1 eth
        //require(msg.value == 1 ether);
        //1. å¤æ­å½©ç¥¨è´­ä¹°åè¡¨éæ¯å¦å·²ç»å­å¨å½åç¨æ·
        require(buyMapping[msg.sender]==0);

        //2. å°ç¨æ·çé±è½¬å°åçº¦è´¦æ·
        //contractAdr.send(msg.value);
        //dataContractAdr.transfer(msg.value);
        //dataContract.setBlance2(msg.sender,msg.value);

        //3.1 è°ç¨äºä»¶æ¥å¿
        emit BuyLottery(msg.sender,msg.value,haoMa);

        //3.2 æ·»å å°mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 å°å°åå­å¥ä¹°å®¶æ°ç»
        usrAdrList.push(msg.sender);
    }
    //0.5 ä¹°å½©ç¥¨æ¹æ³
    /*function BuyCaiPiao(uint16 haoMa,uint etherValue) public {
        //0. å¤æ­ç¨æ·è´¦æ·æ¯å¦æ1 eth
        require(etherValue == 1 ether);
        //1. å¤æ­å½©ç¥¨è´­ä¹°åè¡¨éæ¯å¦å·²ç»å­å¨å½åç¨æ·
        require(buyMapping[msg.sender]==0);
        //2. å°ç¨æ·çé±è½¬å°åçº¦è´¦æ·
        //dataContract.setBlance(etherValue);
        dataContract.setBlance2(msg.sender,etherValue);
        //3.1 è°ç¨äºä»¶æ¥å¿
        emit BuyLottery(msg.sender,etherValue,haoMa);

        //3.2 æ·»å å°mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 å°å°åå­å¥ä¹°å®¶æ°ç»
        usrAdrList.push(msg.sender);
    }*/
    //0.5 ä¹°å½©ç¥¨æ¹æ³
   /* function BuyCaiPiao(uint16 haoMa) payable public {
        //0. å¤æ­ç¨æ·è´¦æ·æ¯å¦æ1 eth
        require(msg.value == 1 ether);
        //1. å¤æ­å½©ç¥¨è´­ä¹°åè¡¨éæ¯å¦å·²ç»å­å¨å½åç¨æ·
        require(buyMapping[msg.sender]==0);

        //2. å°ç¨æ·çé±è½¬å°åçº¦è´¦æ·
        //contractAdr.send(msg.value);
        // contractAdr.transfer(msg.value);

        //3.1 è°ç¨äºä»¶æ¥å¿
        emit BuyLottery(msg.sender,msg.value,haoMa);

        //3.2 æ·»å å°mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 å°å°åå­å¥ä¹°å®¶æ°ç»
        usrAdrList.push(msg.sender);
    }*/

    function KaiJiangTest()  public view returns(uint){
        //1.çæä¸ä¸ªéæºçå¼å¥å·ç 
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        //1.1 åæ¨¡10ï¼ä¿è¯å¥å·å¨10ä»¥å
        luckNum = luckNum % 3;
        return luckNum;
    }


    //1. å¼å¥ - å¿é¡»æ¯ç®¡çåæè½æä½
    function KaiJiang() adminOnly public returns(uint){

        //1.çæä¸ä¸ªéæºçå¼å¥å·ç 
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        //1.1 åæ¨¡10ï¼ä¿è¯å¥å·å¨10ä»¥å
        luckNum = luckNum % 3;

        //å¼åºè´¹
        //emit DrawLottery( msg.sender,contractAdr.balance*0.001,uint16(luckNum));
        //msg.sender.transfer(contractAdr.balance*0.001);

        address payable tempAdr;
        //2.å¾ªç¯ç¨æ·å°åæ°ç»
        for(uint32 i=0; i< usrAdrList.length;i++){
            tempAdr = usrAdrList[i];
            //2.1 å¤æ­ç¨æ·å°å å¨ mappingä¸­ å¯¹åºç CaiPiao.hao çæ°å­æ¯å¦ä¸æ ·
            if(buyMapping[tempAdr] == luckNum){
                //2.2 è®°å½æ¥å¿
                emit DrawLottery(tempAdr,(contractAdr.balance),uint16(luckNum));
                //2.3 å°åçº¦éææçé±è½¬ç» ä¸­å¥è´¦æ·å°å
               // tempAdr.send(contractAdr.balance);
                tempAdr.transfer((contractAdr.balance));
                //2.4 ææç»­è´¹
                //emit DrawLottery(msg.sender,1 ether,uint16(luckNum));
                //msg.sender.transfer(1 ether);

                //emit DrawLottery(tempAdr,msg.value,uint16(luckNum));
                //tempAdr.transfer(msg.value);
                break;
            }
        }
        //3.è¿å ä¸­å¥å·ç 
        return luckNum;
    }

    //2. éç½®æ°æ®
    function resetData() adminOnly public{
        //2.1 å¾ªç¯ ä¹°å®¶æ°ç»ï¼å é¤ è´­ä¹°è®°å½mappingä¸­å¯¹åºçè®°å½
        for(uint16 i = 0;i<usrAdrList.length;i++){
            delete buyMapping[usrAdrList[i]];
        }
        //2.2 å é¤ ä¹°å®¶æ°ç»
        delete usrAdrList;
    }

    //3. éæ¯åçº¦
    function kill() adminOnly public{
        //3.1 è°ç¨åçº¦èªæ¯å½æ°ï¼æåçº¦è´¦æ·ä½é¢è½¬ç»å½åè°ç¨èï¼ç®¡çåï¼
        selfdestruct(msg.sender);
    }

    //4. ç®¡çåä¿®é¥°ç¬¦ï¼åªåè®¸ç®¡çåæä½
    modifier adminOnly() {
        require(msg.sender == manageAdr);
        //ä»£ç ä¿®é¥°å¨æä¿®é¥°å½æ°çä»£ç 
        _;
    }
}