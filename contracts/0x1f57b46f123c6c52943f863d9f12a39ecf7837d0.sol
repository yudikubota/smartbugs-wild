pragma solidity 0.4.25;
/**
 * å¤é¨è°ç¨å¤é¨ä»£å¸ã
 */
 interface token {
    function transfer(address receiver, uint amount) external;
}

/**
 * ä¼ç­¹åçº¦
 */
contract Crowdsale {
    address public beneficiary = msg.sender; //åçäººå°åï¼æµè¯æ¶ä¸ºåçº¦åå»ºè
    uint public fundingGoal;  //ä¼ç­¹ç®æ ï¼åä½æ¯ether
    uint public amountRaised; //å·²ç­¹ééé¢æ°éï¼ åä½æ¯ether
    uint public deadline; //æªæ­¢æ¶é´
    uint public price;  //ä»£å¸ä»·æ ¼
    token public tokenReward;   // è¦åçtoken
    bool public fundingGoalReached = false;  //è¾¾æä¼ç­¹ç®æ 
    bool public crowdsaleClosed = false; //ä¼ç­¹å³é­


    mapping(address => uint256) public balance; //ä¿å­ä¼ç­¹å°ååå¯¹åºçä»¥å¤ªå¸æ°é

    // åçäººå°ä¼ç­¹éé¢è½¬èµ°çéç¥
    event GoalReached(address _beneficiary, uint _amountRaised);

    // ç¨æ¥è®°å½ä¼ç­¹èµéåå¨çéç¥ï¼_isContributionè¡¨ç¤ºæ¯å¦æ¯æèµ ï¼å ä¸ºæå¯è½æ¯æèµ èéåºæåèµ·èè½¬ç§»ä¼ç­¹èµé
    event FundTransfer(address _backer, uint _amount, bool _isContribution);

    /**
     * åå§åæé å½æ°
     *
     * @param fundingGoalInEthers ä¼ç­¹ä»¥å¤ªå¸æ»é
     * @param durationInMinutes ä¼ç­¹æªæ­¢,åä½æ¯åé
     */
    constructor(
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint TokenCostOfEachether,
        address addressOfTokenUsedAsReward
    )  public {
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = TokenCostOfEachether ; //1ä¸ªä»¥å¤ªå¸å¯ä»¥ä¹°å ä¸ªä»£å¸
        tokenReward = token(addressOfTokenUsedAsReward); 
    }


    /**
     * é»è®¤å½æ°
     *
     * é»è®¤å½æ°ï¼å¯ä»¥ååçº¦ç´æ¥ææ¬¾
     */
    function () payable public {

        //å¤æ­æ¯å¦å³é­ä¼ç­¹
        require(!crowdsaleClosed);
        uint amount = msg.value;

        //ææ¬¾äººçéé¢ç´¯å 
        balance[msg.sender] += amount;

        //ææ¬¾æ»é¢ç´¯å 
        amountRaised += amount;

        //è½¬å¸æä½ï¼è½¬å¤å°ä»£å¸ç»ææ¬¾äºº
         tokenReward.transfer(msg.sender, amount * price);
         emit FundTransfer(msg.sender, amount, true);
    }

    /**
     * å¤æ­æ¯å¦å·²ç»è¿äºä¼ç­¹æªæ­¢éæ
     */
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * æ£æµä¼ç­¹ç®æ æ¯å¦å·²ç»è¾¾å°
     */
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal){
            //è¾¾æä¼ç­¹ç®æ 
            fundingGoalReached = true;
          emit  GoalReached(beneficiary, amountRaised);
        }

        //å³é­ä¼ç­¹
        crowdsaleClosed = true;
    }
    function backtoken(uint backnum) public{
        uint amount = backnum * 10 ** 18;
        tokenReward.transfer(beneficiary, amount);
       emit FundTransfer(beneficiary, amount, true);
    }
    
    function backeth() public{
        beneficiary.transfer(amountRaised);
        emit FundTransfer(beneficiary, amountRaised, true);
    }

    /**
     * æ¶åèµé
     *
     * æ£æ¥æ¯å¦è¾¾å°äºç®æ ææ¶é´éå¶ï¼å¦ææï¼å¹¶ä¸è¾¾å°äºèµéç®æ ï¼
     * å°å¨é¨éé¢åéç»åçäººãå¦ææ²¡æè¾¾å°ç®æ ï¼æ¯ä¸ªè´¡ç®èé½å¯ä»¥éåº
     * ä»ä»¬è´¡ç®çéé¢
     * æ³¨ï¼è¿éä»£ç åºè¯¥æ¯éå¶äºä¼ç­¹æ¶é´ç»æä¸ä¼ç­¹ç®æ æ²¡æè¾¾æçæåµä¸æåè®¸éåºãå¦æå»æéå¶æ¡ä»¶afterDeadlineï¼åºè¯¥æ¯å¯ä»¥åè®¸ä¼ç­¹æ¶é´è¿æªå°ä¸ä¼ç­¹ç®æ æ²¡æè¾¾æçæåµä¸éåº
     */
    function safeWithdrawal() afterDeadline public {

        //å¦ææ²¡æè¾¾æä¼ç­¹ç®æ 
        if (!fundingGoalReached) {
            //è·ååçº¦è°ç¨èå·²ææ¬¾ä½é¢
            uint amount = balance[msg.sender];

            if (amount > 0) {
                //è¿ååçº¦åèµ·èææä½é¢
                beneficiary.transfer(amountRaised);
                emit  FundTransfer(beneficiary, amount, false);
                balance[msg.sender] = 0;
            }
        }

        //å¦æè¾¾æä¼ç­¹ç®æ ï¼å¹¶ä¸åçº¦è°ç¨èæ¯åçäºº
        if (fundingGoalReached && beneficiary == msg.sender) {

            //å°ææææ¬¾ä»åçº¦ä¸­ç»åçäºº
            beneficiary.transfer(amountRaised);

          emit  FundTransfer(beneficiary, amount, false);
        }
    }
}