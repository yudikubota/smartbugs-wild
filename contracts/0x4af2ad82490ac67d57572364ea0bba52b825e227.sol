/**!
* @mainpage
* @brief     DDLåçº¦æä»¶
* @details  DDLåçº¦é»è¾å®ç°æä»¶
* @author     Jason
* @date        2020-9-20
* @version     V1.0
* @copyright    Copyright (c) 2019-2020   
**********************************************************************************
* @attention
* ç¼è¯å·¥å·: http://remix.ethereum.org
* ç¼è¯åæ°: Enable optimization, EVM Version: petersburg, é»è®¤EVMçæ¬è°ç¨address(this).balanceæ¶ä¼ throws error invalid opcode SELFBALANCE 

* ç¼è¯å¨çæ¬ï¼solidity   0.7.0 ä»¥ä¸çæ¬
* @par ä¿®æ¹æ¥å¿:
* <table>
* <tr><th>Date        <th>Version  <th>Author    <th>Description
* <tr><td>2020-9-15  <td>1.0      <td>Jason  <td>åå»ºåå§çæ¬
* </table>
*
**********************************************************************************
*/
pragma solidity ^ 0.7.0;

contract DDLClub {
	using SafeMath64 for uint64;
	//Weiè½¬æ¢
	uint64 constant private WEI = 1000000000000000000;

	//Weiè½¬æ¢å° åä½ï¼eth*10^2 å³ ä¿çå°æ°ç¹å2ä½
	uint64 constant private WEI_ETH2 = 10000000000000000;

	//Weiè½¬æ¢å° åä½ï¼eth*10^4 å³ ä¿çå°æ°ç¹å4ä½
	uint64 constant private WEI_ETH4 = 100000000000000;

	//ç§ç½æµè¯å°å
	address constant private ROOT_ADDR = 0x5422d363BFBee232382eA65f6a4C0c400b99A6ed;

	address constant private ADMIN_ADDR = 0xa04c077C326C019842fcA35B2Edb74Cd059d8755;
	//æä½åå°åï¼ç±ç®¡çåè®¾ç½®
	address private op_addr = 0xeD5830B3cbDdcecB11f8D9F5FC5bfC2DB89dd2Ae;

	uint32 constant private TIME_BASE = 1598889600; //åºåæ¶é´ 2020-09-01 00:00:00

 	uint16 constant private MAX_UINT16 = 65535;
	//é«é¶äººæè¡¥å©ï¼çº§å·®å¼
	uint16[16] private ADV_ALLOWANCE = [uint16(0),25, 50,75,100,125,150,175,200,225,250,275,300,325,350,375];//é«é¶äººæè¡¥å©ï¼çº§å·®

	// å®ä¹äºä»¶
    event ev_join(address indexed addr, address indexed paddr, address indexed refaddr, uint32 sidx, uint32 playid, uint32 nlayer, uint256 _value); //ä¼ååä¸æ¸¸æäºä»¶
    event ev_adv_up(address indexed addr,  uint32 playid, uint32 _oldLevel, uint32 _newLevel); //é«é¶äººæåçº§äºä»¶
    event ev_vip_up(address indexed addr,  uint32 playid, uint64 _timestamp, uint32 _ratio); //VIPåçº§äºä»¶
	event ev_set_vip18_bonus(address indexed addr,  uint32 playId, uint16 burnTimes, uint16 slideTimes, uint64 val, string comment); //è®¾ç½®VIP18æ¶çäºä»¶
	event ev_bonus(address indexed addr,  uint32 playid,  address indexed saddr,  uint64 val, string comment); //è·å¾æ¶çäºä»¶
    event ev_withdraw(address indexed addr,   uint32 playid,  uint256 _value, string comment); //æç°
 	event ev_op_setting(address indexed addr, uint32 playid, string comment); //åå°æä½åè®¾ç½®åæ°

	//å®ä¹ä¼åç»æä½
	struct Player {
		//å¨ç¶è¿æ¥ç¹çä½ç½®ï¼0-2ï¼
		uint8 pindex;
		//ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®ç³»ç»å·ï¼0-2ï¼
		uint8 next_idx;
		//é«é¶èº«ä»½çº§å«(0:æ®é,1:åçº§äººæ,2:é«é¶äººæ,3:ä¸æ,4-äºæ,5-ä¸æ,6-åæ,7-äºæ,8-é¶çº§,9-éçº§,10-éé,11-é»ç³,12-éé»,13-èå®ç³,14-ç¿¡ç¿ çº§,15-è£èªæé»çº§)
		uint8 adv_level; 
		//ä¸å±2å±æ»ä¼åæ°
		uint8 m2_count;
		//ä¸å±3å±æ»ä¼åæ° Number of members on begin 4 floor
		uint8 m3_count;
		//ä¼åå½åå¨VIPçº§å«ä¸çå¥éæ¯ä¾ åä½ï¼*100
		uint8 vip_ratio;
 
 		//éæºè®¤è¯ç ï¼ç¨äºä¸­å¿åç³»ç»ç»å®
		uint16 auth_code;
		//æ»è¢«ç§ä¼¤æ¬¡æ°
		uint16 burn_times;
		//è·å¾æ»è½å¥éæ¬¡æ°
		uint16 slide_times;

		//ä¸ä¸ªç³»ç»é«é¶äººææ°
		uint16[3] advN;
		//ä¸ä¸ªç³»ç»ä¸çVIPç¨æ·æ°
		uint16[3] vipN;

		//ä¼åå å¥æ¶é´ï¼ç¸å¯¹äºåºåæ¶é´TIME_BASE
		uint32 join_timestamp;
	 	//ä¼åvipåçº§æ¶é´ï¼ç¸å¯¹äºåºåæ¶é´TIME_BASE
		uint32 vip_up_timestamp;

		
		//ä¼åä»£æ°ï¼ä»1å¼å§
		uint32 gen_num;
 		//ä¼åä¼ä¸å±æ°
		uint32 floors;
		//ä¼åæ¨èäººæ°
		uint32 ref_num; 

		//ä¼åè¿æ¥IDï¼æ°ç»ä¸æ 
		uint32 parent_id;
		//ä¼åæ¨èäººIDï¼æ°ç»ä¸æ 
		uint32 ref_id;

		//ä¼åä¼ä¸å¢éäººæ°ï¼ä¸åæ¬èªå·±ï¼
		uint32 team_num;

		//ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®
		uint32 next_id;
		//ä¼åå­ä»£ï¼ä¸è½¨
		uint32[3] children;

		//ä¼åå·²å®ç°æ¶ç(1åå¥é+ç´æ¥æ¨èè´¹) eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 base_earnings;
		//é«é¶äººæè¡¥å©æ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 adv_earnings;
		//ä¼åç¬¬18å±vipæ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 vip18_earnings;
		//ä¼åvipæ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 vip_earnings;
		//ä¼åå·²æç°æ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 withdraw_earnings;
	}
 
	Player[] players;
	mapping (address => uint32) public playerIdx;
    mapping (uint32 => address) public id2Addr;
 
	/**
	* è·åä¼åæä½ä¿¡æ¯
	*/
  	function get_player_pos_info(address addr) external view 
  	returns(
  		address parent_addr, //ä¼åè¿æ¥äººå°å
  		address ref_addr, //ä¼åæ¨èäººå°å
		address children1, //ä¼åå­æ¥ç¹1å°å
		address children2, //ä¼åå­æ¥ç¹2å°å
		address children3, //ä¼åå­æ¥ç¹3å°å
		uint8 adv_level,//é«é¶èº«ä»½çº§å«(0-æ®é,1-é«é¶äººæ,2- ä¸æé«é¶äººæ,3-äºæé«é¶äººæ,4-ä¸æé«é¶äººæ,5-åæé«é¶äººæ,6-äºæé«é¶äººæ)
		uint8 vip_ratio,//VIPçå¥éæ¯ä¾ åä½ï¼*100
		uint8 pindex, //å¨ç¶è¿æ¥ç¹çä½ç½®ï¼0-2ï¼
		uint8 nextidx, //ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®çç³»ç»å·ï¼0-2ï¼
		uint32 gen_num, //ä¼åä»£æ°ï¼ä»1å¼å§ 
		uint32 nextid,//ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®
		uint32 playerId //ä¼åId
  		){
	 		uint32 playId = playerIdx[addr];
			if(playId == 0){//å¦æplayIdä¸º0, è¯´æç¨æ·ä¸å­å¨
				return(address(0), address(0), address(0), address(0), address(0), 0, 0, 0, 0, 0, 0, 0); //the address have not join the game
			}
			Player storage _p = players[playId];
 			return(id2Addr[_p.parent_id], id2Addr[_p.ref_id], 
 				_p.children[0] > 0 ? id2Addr[_p.children[0]]:address(0), 
 				_p.children[1] > 0 ? id2Addr[_p.children[1]]:address(0), 
 				_p.children[2] > 0 ? id2Addr[_p.children[2]]:address(0), 
 				_p.adv_level,_p.vip_ratio,_p.pindex, _p.next_idx, _p.gen_num, _p.next_id, playId);
	}

	/**
	* è·åä¼åæä½ Id ä¿¡æ¯
	*/
  	function get_player_pos_id_info(uint32 playId) external view 
  	returns(
  		uint8 pindex, //å¨ç¶è¿æ¥ç¹çä½ç½®ï¼0-2ï¼
		uint8 nextidx, //ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®çç³»ç»å·ï¼0-2ï¼
		uint8 adv_level,//é«é¶èº«ä»½çº§å«(0-æ®é,1-é«é¶äººæ,2- ä¸æé«é¶äººæ,3-äºæé«é¶äººæ,4-ä¸æé«é¶äººæ,5-åæé«é¶äººæ,6-äºæé«é¶äººæ)
		uint8 vip_ratio,//VIPçå¥éæ¯ä¾ åä½ï¼*100
		uint32 gen_num, //ä¼åä»£æ°ï¼ä»1å¼å§ 
  		uint32 parentId, //ä¼åè¿æ¥äººId
  		uint32 refId, //ä¼åæ¨èäººId
		uint32 children1, //ä¼åå­æ¥ç¹1 Id
		uint32 children2, //ä¼åå­æ¥ç¹2  Id
		uint32 children3, //ä¼åå­æ¥ç¹3  Id
		uint32 nextid,//ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®
		address addr //ä¼åå°å
  		){
			if(playId < 1 || playId >= players.length){//è¯´æç¨æ·ä¸å­å¨
				return(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, address(0)); //the address have not join the game
			}
			Player storage _p = players[playId];
			addr = id2Addr[playId];
 			return(_p.pindex, _p.next_idx,_p.adv_level,_p.vip_ratio, _p.gen_num, _p.parent_id, _p.ref_id, _p.children[0], _p.children[1], _p.children[2], _p.next_id, addr);
	}

	/**
	* è·åä¼åæ»äººæ°
	*/
  	function get_player_count() external view 
  	returns(uint32){
  		return uint32(players.length - 1);
  	}
	/**
	* è·åä¼ååºæ¬ä¿¡æ¯
	*/
  	function get_player_base_info(address addr) external view 
  	returns(
		uint8 adv_level,//é«é¶èº«ä»½çº§å«(0-æ®é,1-é«é¶äººæ,2- ä¸æé«é¶äººæ,3-äºæé«é¶äººæ,4-ä¸æé«é¶äººæ,5-åæé«é¶äººæ,6-äºæé«é¶äººæ)
		uint8 vip_ratio,//VIPçå¥éæ¯ä¾ åä½ï¼*100
		uint32 ref_num,//ä¼åæ¨èäººæ°
		uint32 floors, //ä¼åä¼ä¸å±æ°
		uint32 playerId, //ä¼åId
		uint32 team_num,//ä¼åä¼ä¸å¢éäººæ°ï¼ä¸åæ¬èªå·±ï¼
		uint64 join_timestamp //ä¼åå å¥æ¶é´ï¼ç¸å¯¹äºåºåæ¶é´TIME_BASE
  		){
	 		uint32 playId = playerIdx[addr];
			if(playId == 0){//å¦æplayIdä¸º0, è¯´æç¨æ·ä¸å­å¨
				return(0, 0, 0, 0, 0, 0, 0); //the address have not join the game
			}
			Player storage _p = players[playId];
 			return( _p.adv_level, _p.vip_ratio, _p.ref_num,  _p.floors, playId, _p.team_num, uint64(_p.join_timestamp+TIME_BASE));
	}

	/**
	* è·åä¼åæ¶çä¿¡æ¯
	*/
  	function get_player_earning_info(address addr) external view 
  	returns(
  		uint16 burn_times,//æ»è¢«ç§ä¼¤æ¬¡æ°
		uint16 slide_times,//è·å¾æ»è½å¥éæ¬¡æ°
		uint32 playerId, //ä¼åId
		uint64 base_earnings, //ä¼åå·²å®ç°æ¶ç(1åå¥é+ç´æ¥æ¨èè´¹)
		uint64 adv_earnings, //é«é¶äººæè¡¥å©æ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 vip_earnings, //ä¼åvipæ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 vip18_earnings, //ä¼åå¨18å±ä¸è·å¾çvipæ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
		uint64 withdraw_earnings//ä¼åå·²æç°æ¶ç eth*10^4 ä¿çå°æ°ç¹å4ä½
  		){
	 		playerId = playerIdx[addr];
			if(playerId == 0){//å¦æplayIdä¸º0, è¯´æç¨æ·ä¸å­å¨
				return(0, 0, 0, 0, 0, 0, 0, 0);
			}
			Player storage _p = players[playerId];
 			return(_p.burn_times, _p.slide_times, playerId, _p.base_earnings, _p.adv_earnings, _p.vip_earnings, _p.vip18_earnings, _p.withdraw_earnings);
	}

	/**
	* è·åä¼åvipä¿¡æ¯
	*/
  	function get_player_vip_info(address addr) external view 
  	returns(
		uint8 ratio,//VIPçå¥éæ¯ä¾ åä½ï¼*100
		uint16 vip_num1,//ç¬¬ä¸æ¡çº¿VIPäººæ°
		uint16 vip_num2,//ç¬¬äºæ¡çº¿VIPäººæ°
		uint16 vip_num3,//ç¬¬ä¸æ¡çº¿VIPäººæ°
		uint32 playerId, //ä¼åId
		uint64 vipearnings,//å¨VIPçº§å«ä¸è·å¾çæ¶ç åä½ï¼eth*10000
		uint64 vip18earnings,//å¨18å±ä¸è·å¾çæ¶ç åä½ï¼eth*10000
		uint64 vip_up_timestamp //ä¼åvipåçº§æ¶é´ï¼ç¸å¯¹äºåºåæ¶é´TIME_BASE
  		){
	 		playerId = playerIdx[addr];
			if(playerId == 0){//å¦æplayIdä¸º0, è¯´æç¨æ·ä¸å­å¨
				return(0, 0, 0, 0, 0, 0, 0, 0); //the address have not join the game
			}
			Player storage _p = players[playerId];
 			return(_p.vip_ratio, _p.vipN[0], _p.vipN[1], _p.vipN[2], playerId, _p.vip_earnings, _p.vip18_earnings, _p.vip_up_timestamp == 0 ? 0: uint64(_p.vip_up_timestamp+TIME_BASE));
	}

	/**
	* è·åé«é¶ä¼åä¿¡æ¯
	*/
  	function get_player_adv_info(address addr) external view 
  	returns(
		uint8 level,//é«é¶èº«ä»½çº§å«(0-æ®é,1-é«é¶äººæ,2- ä¸æé«é¶äººæ,3-äºæé«é¶äººæ,4-ä¸æé«é¶äººæ,5-åæé«é¶äººæ,6-äºæé«é¶äººæ)
		uint8 m2_count,//ä¸å±2å±æ»ä¼åæ°
		uint8 m3_count,//ä¸å±3å±æ»ä¼åæ°
		uint16 advN1,//ç¬¬ä¸æ¡çº¿ä¸é«é¶äººææ°
		uint16 advN2,//ç¬¬äºæ¡çº¿ä¸é«é¶äººææ°
		uint16 advN3,//ç¬¬ä¸æ¡çº¿ä¸é«é¶äººææ°
		uint32 playerId //ä¼åId
  		){
	 		playerId = playerIdx[addr];
			if(playerId == 0){//å¦æplayIdä¸º0, è¯´æç¨æ·ä¸å­å¨
				return(0, 0, 0, 0, 0, 0, 0); //the address have not join the game
			}
			Player storage _p = players[playerId];
 			return( _p.adv_level, _p.m2_count, _p.m3_count, _p.advN[0], _p.advN[1],  _p.advN[2], playerId);
	}
 
	constructor() public {
		Player memory _player = Player({
            parent_id: 0,
            ref_id:0, 
	 		join_timestamp: uint32(block.timestamp-TIME_BASE),
            gen_num: 1,
         	floors: 0,
            team_num: 0,
            ref_num: 0,
            burn_times: 0,
            slide_times: 0,
            next_id: 1,
            next_idx: 0,
            pindex: 0,
            m2_count: 0,
            m3_count: 0,
            adv_level: 0,
            vip_ratio:0,
            auth_code:0,
            advN:[uint16(0),0,0],
			vipN:[uint16(0),0,0],
         	children:[uint32(0),0,0],
			vip_up_timestamp:0,
			base_earnings: 0,
			adv_earnings: 0,
			vip_earnings:0,
			vip18_earnings:0,
			withdraw_earnings: 0
        });
		//å å¥æ ¹èç¹
		players.push(_player);
		players.push(_player); //å¤å¤å¶ä¸æ¬¡ï¼ç®çæ¯ä½¿ç¬¬ä¸ä¸ªåç´ çæ°ç»ä¸æ ä¸º1ï¼IDä¹ä¸º1ï¼æ¹ä¾¿åé¢çé»è¾å¤æ­
		uint32 playerId = uint32(players.length - 1);
		playerIdx[ROOT_ADDR] = playerId;
		id2Addr[playerId] = ROOT_ADDR;
		//sn2Id[_player.player_sn] = playerId;
	}
	
 	fallback() external {
	}
	receive() payable external {
	   //currentBalance = address(this).balance + msg.value;
	}
	//function() payable external{ }
	modifier onlyAdmin() {
		require(msg.sender == ADMIN_ADDR);
		_;
	}
	modifier onlyOperator() {
		require(msg.sender == op_addr);
		_;
	}
 
 	/**
	* è®¾ç½®æä½å,ç±ç®¡çåæä½
	* opAddr æä½åå°å
	*/
	function setOperator(address opAddr) public onlyAdmin{
		op_addr = opAddr;
	}
	/**
	* è·åæä½åå°å
	*/
	function getOperator() external view onlyOperator returns(
		address addr
	){
		return op_addr;
	}
	/*
	function grand() internal view returns(uint16) {
        uint256 random = uint256(keccak256(abi.encode(block.timestamp)));
        return uint16(10000+random%50000);
    }*/

	/**
	* åä¸æ¸¸æ
	* refaddrï¼æ¨èäººå°å
	* paddrï¼æ¥ç¹äººå°å(æå®ä¸ºæ¨èäººå°ååèªå¨åé)
	*/
	function join(address refaddr, address paddr) public payable 
	returns(
		uint32 playerId
	){
		require(msg.value/WEI_ETH2 == 25 , "Amount is invalid");//æ¿æ´»éé¢ä¸º0.25ä¸ªETH

		playerId = playerIdx[msg.sender];
 		require(playerId == 0 , "You are already registered");//æ¿æ´»éé¢ä¸º0.25ä¸ªETH

		uint8 status;
		uint8 index;
		uint32 refId;
		uint32 parentId;
        uint32 nextid;

		(refId, parentId, index, status) = calc_player_pos_info(refaddr, paddr);
		if(status == 1) revert("Parent has no free connect points");
		if(status == 2) revert("The parent does not exist");
		require(players[parentId].children[index] == 0 , "parent is invalid");//ç¡®ä¿ç¶èç¹ä¸çç¹ä½æ²¡æè¢«å ä½
		require(players[parentId].gen_num < 4294967295 , "gen_num is too large");//ç¡®ä¿å±æ·±ä¸ä¼æº¢åº
		require(players.length < 4294967295 , "The number exceeds the limit");//42äº¿
		//require(parentId != 0 , "Parent is invalid!");//ç¡®ä¿ç¶èç¹ä¸çç¹ä½æ²¡æè¢«å ä½
		//uint16 authcode = grand();

		playerId = uint32(players.length);
		//å½æ°ä¸­å£°æå¹¶åå»ºç»æä½éè¦ä½¿ç¨memoryå³é®å­
		Player memory _player = Player({
            parent_id: parentId,
         	ref_id: refId,
            next_id: playerId,
            next_idx: 0,
	 		join_timestamp: uint32(block.timestamp-TIME_BASE),
            gen_num: players[parentId].gen_num+1,
            floors: 0,
            team_num: 0,
            ref_num: 0,
            burn_times: 0,
            slide_times: 0,
            pindex: index,
            m2_count: 0,
            m3_count: 0,
            adv_level: 0,
           	vip_ratio:0,
            auth_code:0,
            advN:[uint16(0),0,0],
			vipN:[uint16(0),0,0],
         	children:[uint32(0),0,0],
			vip_up_timestamp:0,
			base_earnings: 0,
			adv_earnings: 0,
			vip_earnings:0,
			vip18_earnings:0,
			withdraw_earnings: 0
        });
		players.push(_player);
		//playerId = uint64(players.length - 1);
		playerIdx[msg.sender] = playerId;
		id2Addr[playerId] = msg.sender;
		players[parentId].children[index] = playerId;
 		//ä¿®æ¹æ¨èäººæ°
		players[refId].ref_num++;
  		
  		//ç´æ¥æ¨èè´¹ 0.075ETH
		players[refId].base_earnings = players[refId].base_earnings.add(750);
  		
		join_calc(_player, parentId);
		emit ev_join(msg.sender, id2Addr[parentId], id2Addr[refId], index, playerId, _player.gen_num, msg.value); //è§¦åä¼ååä¸æ¸¸æäºä»¶
		 
		return playerId;
	}


	function join_calc(Player memory _player, uint32 parentId) internal{
		uint8 tidx;
  		uint8 advLevel;
  		uint16 advNum;
  		uint32 nlayers;
 		uint32 nextid;
  		uint64 diff;
  		Player storage _p;
  		Player storage _tplayer;
  		for(uint32 i=_player.gen_num; i>1; i--){
			_p = players[parentId];
			//å¾ä¸è®¡ç®æ¯ä¸ªç¶ç¹ä½ç  ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®
			 _tplayer = players[_p.next_id];
 
			if(_tplayer.gen_num > 0 && _tplayer.children[_p.next_idx] > 0){ //è¢«å ç¨
				uint8 nextidx = (_p.next_idx+1) % 3;
				if(_tplayer.children[nextidx] > 0){
					nextidx = (nextidx+1) % 3; //æä½å ç¨ï¼ç»§ç»­æ¾
					if(_tplayer.children[nextidx] > 0) nextidx = 3; //è¯´æè¯¥ä½ç½®ç3ä¸ªå­èç¹é½æ¾æ»¡ï¼éè¦å¦å¤æ¾ä¸ä¸ªç©ºé²ä½ç½®
				}
				if(nextidx > 2){
					//å3ä¸ªå­©å­ä¼ä¸ ä¸ä¸ä¸ªæåå°è¦å­æ¾çä½ç½® åå½åèç¹å±å·®æå°ç åä¸ºæ¬èç¹çä¸ä¸ä¸ªä½ç½®
					uint32 uNext0 = players[_p.children[0]].next_id;
					uint32 uNext1 = players[_p.children[1]].next_id;
					uint32 uNext2 = players[_p.children[2]].next_id;
					nextid = players[uNext0].gen_num > players[uNext1].gen_num ? uNext1 : uNext0;
					nextid = players[nextid].gen_num > players[uNext2].gen_num ? uNext2 : nextid;
					nextidx = players[nextid].next_idx;
					_p.next_id = nextid;
				}
				_p.next_idx = nextidx;
			}


			if(advNum > 0){
				if(MAX_UINT16 - _p.advN[tidx] > advNum) _p.advN[tidx]+=advNum; //ç¶èç¹è¿æ¡çº¿ä¸çé«é¶äººææ°å¢å ,æº¢åºæ£æ¥
				else _p.advN[tidx] = MAX_UINT16;

				if(_p.adv_level > 1){
					advLevel = get_adv_level(_p.advN);
					if(_p.adv_level != advLevel){
						emit ev_adv_up(id2Addr[parentId], parentId, _p.adv_level, advLevel); //é«é¶äººæåçº§
						_p.adv_level = advLevel;	
					}
				}
			}
			//ç¶ç¹ä½å¢éäººæ°å 1ï¼æ¾ç¤ºç¨ï¼æº¢åºä¸ç®¡
			_p.team_num++; 

			//è®¡ç®æ¶ç
			//1 åå¥é æ¿èªå·±ä¼ä¸ 18 å±
			if(_player.gen_num - _p.gen_num < 19){
				//_p.base_earnings = _p.base_earnings.add(uint64(msg.value/WEI_ETH4 / 100));
				_p.base_earnings = _p.base_earnings.add(uint64(msg.value/WEI_ETH2));
			}
			//é«é¶äººæè¡¥å©
			if(_p.adv_level > 0){
				if(ADV_ALLOWANCE[_p.adv_level] > diff){
					_p.adv_earnings = _p.adv_earnings.add(ADV_ALLOWANCE[_p.adv_level] - diff);
					//emit ev_bonus(id2Addr[parentId], parentId, msg.sender, ADV_ALLOWANCE[_p.adv_level] - diff, "adv allowance"); //è·å¾æ¶çäºä»¶
					diff = ADV_ALLOWANCE[_p.adv_level];
				}
			}

			nlayers = _player.gen_num - _p.gen_num;
			//é«é¶äººæå3å±äººæ°å¤æ­
			if(nlayers < 4){
				_p.m3_count++; //åªè®°å½ä¼ä¸3å±åçä¼åæ°ï¼ç¨äºé«é¶åçº§å¤æ­
				if(nlayers < 3) _p.m2_count++;
				if( _p.m2_count >=12 && _p.adv_level == 0){
					 _p.adv_level = 1; //æä¸ºåçº§äººæ
					 emit ev_adv_up(id2Addr[parentId], parentId, 0, 1); //äººæåçº§
				}
				if(_p.m3_count >=39 && _p.adv_level == 1){
					 _p.adv_level = 2; //æä¸ºé«é¶äººæ
					 emit ev_adv_up(id2Addr[parentId], parentId, 1, 2); //é«é¶äººæåçº§
					 advNum ++;
					 tidx = _p.pindex;
				}

				if(_p.adv_level > 1){
					advLevel = get_adv_level(_p.advN);
					if(_p.adv_level != advLevel){
						emit ev_adv_up(id2Addr[parentId], parentId, _p.adv_level, advLevel); //é«é¶äººæåçº§
						_p.adv_level = advLevel;	
					}
				}
			}
			//è®¡ç®ä¼åä¼ä¸å±æ°
			if(nlayers > _p.floors) {
				_p.floors = nlayers;
			}
			parentId = _p.parent_id;
  		}
	}
	/**
	* æ¿æ´»é»ç³vipç³»ç»
	* è¿åå¼ï¼ æåè¿åtrue
	*/
	function active_vip() public payable 
	returns(
		bool bOk
	){
		//for test comment
		require(msg.value/WEI_ETH2 == 10, "Amount is invalid.");
		
		uint32 playId = playerIdx[msg.sender];
		require(playId > 0, "You have not registered");
 
		require(players[playId].vip_ratio == 0, "The vip system has been activated");

		Player storage _p = players[playId];
		//_p.vip_level = 1;
		_p.vip_up_timestamp = uint32(block.timestamp-TIME_BASE);
		_p.vip_ratio=get_vip_ratio(_p.vipN);
 		uint8 ratio;
		uint32 gnum = _p.gen_num;
		uint32 parentId = _p.parent_id;
		uint64 diff;
		uint64 val = uint64(msg.value / WEI_ETH2);
		while(gnum > 1){

			//è¿æ¡çº¿VIPäººæ°å¢å 
			if(players[parentId].vipN[_p.pindex] < MAX_UINT16){
				players[parentId].vipN[_p.pindex] += 1;
			}
 			_p = players[parentId];

 			//è®¡ç®VIP ç³»ç»å¥å± 
			if(_p.vip_ratio > diff){
				_p.vip_earnings = _p.vip_earnings.add(val*(_p.vip_ratio-diff)); //è¿éä¸ç¨åé¤100ï¼å ä¸ºåé¢val å·²å¤é¤100ï¼ vip_earnings çåä½æ¯ eth * 10^4
				diff = _p.vip_ratio;
				//emit ev_bonus(id2Addr[parentId], id2Addr[playId], val*(_p.vip_ratio-diff), "vip up"); //è·å¾æ¶çäºä»¶
			}
			if(_p.vip_ratio > 0){ //èªå·±å¿é¡»åæ¿æ´»VIP
				ratio=get_vip_ratio(_p.vipN); //æ ¹æ®åæ¡çº¿çäººæ°ï¼è®¾ç½®å¥éæ¯ä¾
				if(ratio != _p.vip_ratio){
					_p.vip_ratio = ratio;
					//emit ev_vip_up(id2Addr[parentId], parentId, uint64(_p.vip_up_timestamp+TIME_BASE), _p.vip_ratio); //Vipåçº§äºä»¶
				}
			}
			parentId = _p.parent_id;
			gnum --;
  		}
  		emit ev_vip_up(id2Addr[playId], playId, uint64(players[playId].vip_up_timestamp+TIME_BASE),players[playId].vip_ratio); //Vipåçº§äºä»¶
	}
	/**
	* æ ¹æ®èç¹VIP äººæ°ï¼ç¡®å®æ¶çæ¯ä¾
	* è¿åå¼ï¼æ¶çæ¯ä¾ åä½: *100
	*/
	function get_vip_ratio(uint16[3] memory nVipN) internal pure returns (uint8){
		uint16 nmin = min16(nVipN[0], nVipN[1], nVipN[2]);
		uint16 n;
		if(nVipN[0] > 0) n += 1;
		if(nVipN[1] > 0) n += 1;
		if(nVipN[2] > 0) n += 1;
		if(n < 3){
			if(n == 0) return 20;
			if(n == 1) return 25;
			if(n == 2) return 30;
		}else{
			if(nmin < 20) return 35; //ä¸ä¸ªä¸å±ç³»ç»ä¸­é½æä¼åæååçº§æä¸ºâ¾¦çº§VIPä¼åã
			if(nmin < 50) return 40;  //æ°éæå°çâ¼ä¸ªç³»ç»è¾¾å°äº20ä¸ªä½å°äº50
 			if(nmin < 100) return 45;
			if(nmin < 500) return 50;
			if(nmin < 1000) return 60;
			if(nmin < 10000) return 70;
			else return 70;
		}
	}

	/**
	* æ ¹æ®èç¹é«é¶äººææ° ï¼ç¡®å®é«é¶ç­çº§
	* è¿åå¼ï¼é«é¶èº«ä»½çº§å«(0:æ®é,1:åçº§äººæ,2:é«é¶äººæ,3:ä¸æ,4-äºæ,5-ä¸æ,6-åæ,7-äºæ,8-é¶çº§,9-éçº§,10-éé,11-é»ç³,12-éé»,13-èå®ç³,14-ç¿¡ç¿ çº§,15-è£èªæé»çº§)
	*/
	function get_adv_level(uint16[3] memory nAdvN) internal pure returns (uint8){
		uint16 nmin = min16(nAdvN[0], nAdvN[1], nAdvN[2]);
		uint16 n;
		if(nAdvN[0] > 0) n += 1;
		if(nAdvN[1] > 0) n += 1;
		if(nAdvN[2] > 0) n += 1;
		if(n < 3){
			if(n == 0) return 2;
			if(n == 1) return 3;
			if(n == 2) return 4;
		}else{
			if(nmin < 10) return 5; //3æé«é¶äººæï¼ä¸æ¡çº¿åå¹å»ä¸ä¸ªé«é¶äººæåä»¥ä¸ç­çº§
			if(nmin < 30) return 6;
			if(nmin < 60) return 7;
			if(nmin < 100) return 8;
			if(nmin < 500) return 9;
			if(nmin < 1000) return 10;
			if(nmin < 5000) return 11;
			if(nmin < 10000) return 12;
			if(nmin < 100000) return 13;
			if(nmin < 1000000) return 14;
			else return 15;
		}
	}

	/**
	* æ ¹æ®ç¡®å®ç¹ä½, refaddr ä¸ºæ¨èäººå°åï¼ paddrä¸ºæ¥ç¹äººå°å(å¯éï¼æå®ä¸ºæ¨èäººå°ååèªå¨åé)
	* è¿åå¼ï¼refIdä¸ºæ¨èäººId, parentIdä¸ºè¿æ¥äººIdï¼index ä¸ºå¨è¿æ¥äººchildrençæ°ç»ç´¢å¼ï¼status: 0æ­£å¸¸ï¼1æ¥ç¹äººæ²¡æç©ºä½ï¼2æ¥ç¹äººä¸å­å¨
	*/
	function calc_player_pos_info(address refaddr, address paddr) internal view
	returns (
		uint32 refId,
        uint32 parentId,
        uint8 index,
        uint8 status
    ){
    	if(refaddr == address(0)){
			refId = playerIdx[ROOT_ADDR];
		}else{
			refId = playerIdx[refaddr]; //å¦ærefaddræ²¡åä¸æ¸¸æï¼é£ä¹refIdèªå¨ä¸º0ï¼
		}
	 	if(paddr == refaddr){
			paddr = id2Addr[refId];
			parentId = playerIdx[paddr];
		}else{//æå®æ¥ç¹äººï¼å°±å¿é¡»ç´æ¥æ¥å°ä»ä¸é¢
			parentId = playerIdx[paddr]; 
			if(parentId == 0){//å¦æpaddræ²¡åä¸æ¸¸æ, è¿å
				return (0, 0, 0, 2);
			}
			if(players[parentId].children[0] == 0) index = 0;
			else if(players[parentId].children[1] == 0) index = 1;
			else if(players[parentId].children[2] == 0) index = 2;
			else status = 1;//æ¥ç¹äººæ²¡æç©ºé²ä½
			return (refId, parentId, index, status);  
		}
  		parentId = players[parentId].next_id;
		if(players[parentId].children[0] == 0) index = 0;
		else if(players[parentId].children[1] == 0) index = 1;
		else if(players[parentId].children[2] == 0) index = 2;
		else status = 1; //ä¸åæ³çparent? æ°¸è¿ä¸ä¼åç
		return (refId, parentId, index, status);
	}
   
	/**
	* æç°,å¨é¨æç°
	*/
	function withdraw()
	public {
		uint32 playId = playerIdx[msg.sender];
		require(playId > 0, "You have not registered");
 		//uint256 wval = val*WEI_ETH2;
		Player storage _p = players[playId];
		uint256  totalEarnings = uint256(_p.base_earnings) + _p.adv_earnings + _p.vip_earnings  + _p.vip18_earnings;//æ»æ¶ç,   åä½eth*10^4
		require(_p.withdraw_earnings <= totalEarnings);
		 
		uint256 undrawnEarnings = totalEarnings - _p.withdraw_earnings;//æªæç°ä½é¢ = æ»æ¶ç-åå·²æç°æ¶ç
		totalEarnings = undrawnEarnings*WEI_ETH4; //å°åä½eth*10^4 è½¬æ¢ä¸ºwei
		require(totalEarnings / undrawnEarnings == WEI_ETH4, "undrawn earnings invalid"); //è½¬æ¢åæ³æ§æ£æ¥

		//require(totalEarnings >= wval, "Not enough balance."); //ä½é¢æ£æ¥
		require(address(this).balance >= totalEarnings, "Contract is not enough balance.");//åçº¦ä½é¢æ£æ¥
        
        uint64 withdrawVal = uint64(undrawnEarnings);
        
		_p.withdraw_earnings = _p.withdraw_earnings.add(withdrawVal); //åæ£é¤
		msg.sender.transfer(totalEarnings);
		//è§¦åæç°äºä»¶
		emit ev_withdraw(msg.sender, playId, withdrawVal, "player");
	}


	/**
	* ç®¡çåæç°
	* val: è¦æç°çé¢åº¦ï¼åä½eth*10^2
	*/
	function withdraw_admin(uint256 val) public payable onlyAdmin{
		val = val * WEI_ETH2; //å°åä½eth*10^2 è½¬æ¢ä¸ºwei
		require(val <= address(this).balance, "Not enough balance.");
		address(uint160(ADMIN_ADDR)).transfer(val);
		//è§¦åæç°äºä»¶
		emit ev_withdraw(ADMIN_ADDR, 0, val,"admin");
	}

 	function min16(uint16 a, uint16 b, uint16 c) internal pure returns (uint16) {
        uint16	d =  a > b ? b : a;
		return d > c ? c : d;
    }

	/**
	* è®¾ç½®ä¼å18å±vipæ¶ç,ç±ä¸­å¿åç®¡çåæä½
	* playId ä¼åId
	* valï¼ 18å±æ»æ¶çï¼åä½ ETH * 10^4
	* burnTimesï¼ è¢«ç§ä¼¤æ¬¡æ°
	* slideTimesï¼ è·å¾æ»è½å¥éæ¬¡æ°
	*/
	function op_set_vip18_earnings(uint32 playId, uint64 val, uint16 burnTimes, uint16 slideTimes) external onlyOperator{
		require(id2Addr[playId] != address(0), "playId have not registered");
		Player storage _p = players[playId];
		_p.vip18_earnings = val;
	 	_p.slide_times = slideTimes; //æ»è½æ¬¡æ°
		_p.burn_times = burnTimes; //ç§ä¼¤æ¬¡æ°
		emit ev_set_vip18_bonus(id2Addr[playId], playId, burnTimes, slideTimes, val, "set vip18 earnings"); //è®¾ç½®VIPæ¶çäºä»¶
 	}

	 /**
	* è®¾ç½®ä¼åæä½åæ°, ç±ç®¡çåæä½
	* playId  ä¼åId
	* nextid ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®
	* nextidxï¼ ä¸ä¸ä¸ªä¼ä¸æåå°è¦å­æ¾çä½ç½®ç³»ç»å·ï¼0-2ï¼
	*/
	function op_set_next_param(uint32 playId, uint32 nextid, uint8 nextidx) external onlyOperator{
		require(id2Addr[playId] != address(0), "playId have not registered");
		Player storage _p = players[playId];	
		_p.next_id=nextid;
		_p.next_idx=nextidx;
		emit ev_op_setting(msg.sender, playId, "set next param"); //åå°æä½åè®¾ç½®åæ°
 	}
	//è®¾ç½®ä¼åæ¶ç,è¯¥æ¥å£æ­£å¸¸ç¨ä¸å°ï¼éä»¥ç®¡çåèº«ä»½è°ç¨
	function op_set_earnings_param(uint32 playId,  uint64 baseEarnings, uint64 advEarnings, uint64 vipEarnings, uint64 vip18Earnings, uint64 withdrawEarnings) external onlyAdmin{
		require(id2Addr[playId] != address(0), "playId have not registered");
		Player storage _p = players[playId];	
		 _p.base_earnings=baseEarnings;
		 _p.adv_earnings=advEarnings;
		 _p.vip_earnings=vipEarnings;
		 _p.vip18_earnings=vip18Earnings;
		 _p.withdraw_earnings=withdrawEarnings;
		 emit ev_op_setting(msg.sender, playId, "set earnings param"); //åå°æä½åè®¾ç½®åæ°
 	}
	//è®¾ç½®ä¼åå¨åæ¡çº¿ä¸çVIPãé«é¶äººæäººæ°, è¯¥æ¥å£æ­£å¸¸ç¨ä¸å°ï¼éä»¥æä½åèº«ä»½è°ç¨
	function op_set_N_param(uint32 playId,  uint16[3] memory advN, uint16[3] memory vipN) external onlyOperator{
		require(id2Addr[playId] != address(0), "playId have not registered");
		Player storage _p = players[playId];	
		 _p.vipN[0] = vipN[0];
		 _p.vipN[1] = vipN[1];
		 _p.vipN[2] = vipN[2];

		 _p.advN[0] = advN[0];
		 _p.advN[1] = advN[1];
		 _p.advN[2] = advN[2];
		 emit ev_op_setting(msg.sender, playId, "set N param"); //åå°æä½åè®¾ç½®åæ°
 	}

	/**
	* è·åä¼åè®¤è¯ç 
	*/
	function get_authcode(address addr) external view onlyAdmin returns (uint16) {
		uint32 playId = playerIdx[addr];
		require(playId > 0, "The address have not registered");
		return players[playId].auth_code;
 	}

	/**
	* è®¾ç½®ä¼åè®¤è¯ç 
	*/
	function set_authcode(uint16 authcode) external{
		uint32 playId = playerIdx[msg.sender];
		require(playId > 0, "The address have not registered");
		players[playId].auth_code = authcode;
 	}
	/**
	* è®¤è¯
	*/
	function auth(address addr, uint16 authcode) external view returns(bool){
		uint32 playId = playerIdx[addr];
		if(playId == 0) return false;
		if(authcode == 0) return false;
		return authcode == players[playId].auth_code ? true : false;
	}
}

library SafeMath64 {
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        if (a == 0) {
            return 0;
        }
        uint64 c = a * b;
        require(c / a == b);
        return c;
    }
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a);
        uint64 c = a - b;
        return c;
    }
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a);
        return c;
    }
}