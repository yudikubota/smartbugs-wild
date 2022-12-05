// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

contract ETH_3Day {
    using SafeMath for uint256;
    uint256 constant public CONTRACT_BALANCE_STEP = 3;
    address public manager;
    uint256 public day = 3 days;
    uint256 public rechargeTime;
    uint256 public minAmount = 1 ether;
    uint256 public percentage = 900;
    uint256 public totalUsers;
    bool public ISEND;
    
    struct RechargeInfo{
        address rec_addr;
        uint256 rec_value;
        uint256 rec_time;
    }
    RechargeInfo[] public rechargeAddress;
    struct UserInfo {
		address   referrer;   
        address[] directPush; 
        uint256 amountWithdrawn;
        uint256 distributionIncome72;
    }
    mapping(address => UserInfo) public user;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => bool)) public userDireMap;
    
    constructor()public{
        manager = msg.sender;
     }

    // åå¼
    function deposit(address referrer) payable public {
        require(msg.value > 0 && ISEND == false);
        // require(msg.value >= minAmount,"Top up cannot be less than 1 eth");
        
        UserInfo storage u = user[msg.sender];
        //  å½åç¨æ·æ²¡æä¸    &&      æ¨èäºº ä¸è½æ¯ èªå·±
		if (u.referrer == address(0) && referrer != msg.sender) {
			// æ·»å ä¸çº§
            u.referrer = referrer;
            if (userDireMap[referrer][msg.sender] == false){
                // ç»ä¸çº§æ·»å å½åä¸çº§
                user[referrer].directPush.push(msg.sender);
                userDireMap[referrer][msg.sender] = true;
            }
		}
		
		if (balance[msg.sender] == 0){
		    totalUsers = totalUsers.add(1);
		}
		// åå¼
		balance[msg.sender] = balance[msg.sender].add(msg.value);
		rechargeAddress.push(RechargeInfo({rec_addr:msg.sender,rec_value:msg.value,rec_time:block.timestamp}));
		rechargeTime = block.timestamp;
    }
    
    // æå¸
    function withdraw(uint256 value) public {
        require(value > 0);
        // éªè¯æ¯å¦æè¶³å¤æåé¢åº¦
        uint256 count = getIncome(msg.sender);
        require(count >= value,"Not enough quota");
        // æå¸
        msg.sender.transfer(value);
        user[msg.sender].amountWithdrawn = user[msg.sender].amountWithdrawn.add(value);
    }
    
    // pool æ»é
    function getPoolETH() view public returns(uint256){
        return address(this).balance;
    }
    
    // åå¼æ»ç¬æ°
    function getRecTotal() view public returns(uint256){
        return rechargeAddress.length;
    }
    
    // æå10ç¬äº¤æ
    function getRec10() view public returns(RechargeInfo[] memory){
        uint256 l = rechargeAddress.length;
        uint256 a = 0;
        uint256 i = 0;
        if (rechargeAddress.length>10){
            l = 10;
            a = rechargeAddress.length.sub(10);
        }
        RechargeInfo[] memory data = new RechargeInfo[](l);
        for (;a < rechargeAddress.length; a++){
            data[i] = rechargeAddress[a];
            i = i+1;
        }
        return data;
    }
    
    // è¶è¿72å°æ¶åå¸
    function distribution72() public {
        if (isTime() == false){return;}
        uint256 a = 0;
        if (rechargeAddress.length>50){
            a = rechargeAddress.length.sub(50);
        }
        uint256 total = (address(this).balance.mul(percentage)).div(uint256(1000));
        for (;a < rechargeAddress.length; a++){
            user[rechargeAddress[a].rec_addr].distributionIncome72 = user[rechargeAddress[a].rec_addr].distributionIncome72.add(total.div(100));
        }
        ISEND = true;
        return;
    }
    
    // å½åæ¶é´æ¯å¦å¤§äº 72 å°æ¶
    function isTime()view public returns(bool) {
        if ((block.timestamp.sub(rechargeTime)) >= day && rechargeTime != 0){
            return true;
        }
        return false;
    }
    
    // ç´æ¨åæ° å¬å¼ï¼ç´æ¨æ»é / æ¬é
    function directPushMultiple(address addr) view public isAddress(addr) returns(uint256) {
        if(balance[addr] == 0){
            return 0;
        }
        return getDirectTotal(addr).div(balance[addr]);
    }
    
    // æå¤§æ¶ç å¬å¼ï¼ç´æ¨æ»é - æåºæ»é
    function getMaxIncome(address addr) view public isAddress(addr) returns(uint256){
        return getDirectTotal(addr).sub(user[addr].amountWithdrawn);
    }
    
    // å½åæ¶ç å¬å¼ï¼æ¬é * 3 - æåºæ»é
    function getIncome(address addr) view public isAddress(addr) returns(uint256){
        uint256 multiple = directPushMultiple(addr);
        if (multiple < 3){
            return 0;
        }
        return (balance[addr].mul(3).sub(user[addr].amountWithdrawn));
    }
    
    // å½åå·²æåæ°é
    function numberWithdrawn(address addr) view public isAddress(addr) returns(uint256) {
        return user[addr].amountWithdrawn;
    }

    // è¿½æè®¡ç® å¬å¼ï¼ï¼ç´æ¨æ»é - å·²æåæ°é - å½åå¯æåæ°éï¼ / 3
    function additionalThrow(address addr) view public isAddress(addr) returns(uint256){
        return (getDirectTotal(addr).sub(user[addr].amountWithdrawn).sub(getIncome(addr))).div(3);
    }

    
    // è·åä¸çº§åå¼æ»é¢
    function getDirectTotal(address addr) view public isAddress(addr) returns(uint256) {
        UserInfo memory u = user[addr];
        if (u.directPush.length == 0){return (0);}
        uint256 total;
        for (uint256 i= 0; i<u.directPush.length;i++){
            total += balance[u.directPush[i]];
        }
        return (total);
    }
    
    // 72æ¶çé¢å
    function distributionIncome72()public{
        require(user[msg.sender].distributionIncome72 > 0);
        msg.sender.transfer(user[msg.sender].distributionIncome72);
    }
    
    // è·åç¨æ·ä¸çº§
    function getDirectLength(address addr) view public isAddress(addr) returns(uint256){
        return user[addr].directPush.length;
    }
    
    // Owner æå¸
    function ownerWitETH(uint256 value) public onlyOwner{
        require(getPoolETH() >= value);
        msg.sender.transfer(value);
    }
    
    // æéè½¬ç§»
    function ownerTransfer(address newOwner) public onlyOwner isAddress(newOwner) {
        manager = newOwner;
    }
    
    modifier isAddress(address addr) {
        require(addr != address(0));
        _;
    }
    
    modifier onlyOwner {
        require(manager == msg.sender);
        _;
    }

}