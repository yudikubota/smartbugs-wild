pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;  // åèµæååçæ¶æ¬¾æ¹
    uint public fundingGoal;   // åèµé¢åº¦
    uint public amountRaised;   // åä¸æ°é
    uint public deadline;      // åèµæªæ­¢æ

    uint public price;    //  token ä¸ä»¥å¤ªåçæ±ç , tokenåå¤å°é±
    token public tokenReward;   // è¦åçtoken

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false;  // ä¼ç­¹æ¯å¦è¾¾å°ç®æ 
    bool crowdsaleClosed = false;   //  ä¼ç­¹æ¯å¦ç»æ

    /**
    * äºä»¶å¯ä»¥ç¨æ¥è·è¸ªä¿¡æ¯
    **/
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * æé å½æ°, è®¾ç½®ç¸å³å±æ§
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        address addressOfTokenUsedAsReward) {
            beneficiary = ifSuccessfulSendTo;
            fundingGoal = fundingGoalInEthers * 1 ether;
            deadline = now + durationInMinutes * 1 minutes;
            price = finneyCostOfEachToken * 1 finney;
            tokenReward = token(addressOfTokenUsedAsReward);   // ä¼ å¥å·²åå¸ç token åçº¦çå°åæ¥åå»ºå®ä¾
    }

    /**
     * æ å½æ°åçFallbackå½æ°ï¼
     * å¨ååçº¦è½¬è´¦æ¶ï¼è¿ä¸ªå½æ°ä¼è¢«è°ç¨
     */
    function () payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    /**
    *  å®ä¹å½æ°ä¿®æ¹å¨modifierï¼ä½ç¨åPythonçè£é¥°å¨å¾ç¸ä¼¼ï¼
    * ç¨äºå¨å½æ°æ§è¡åæ£æ¥æç§åç½®æ¡ä»¶ï¼å¤æ­éè¿ä¹åæä¼ç»§ç»­æ§è¡è¯¥æ¹æ³ï¼
    * _ è¡¨ç¤ºç»§ç»­æ§è¡ä¹åçä»£ç 
    **/
    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * å¤æ­ä¼ç­¹æ¯å¦å®æèèµç®æ ï¼ è¿ä¸ªæ¹æ³ä½¿ç¨äºafterDeadlineå½æ°ä¿®æ¹å¨
     *
     */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    /**
     * å®æèèµç®æ æ¶ï¼èèµæ¬¾åéå°æ¶æ¬¾æ¹
     * æªå®æèèµç®æ æ¶ï¼æ§è¡éæ¬¾
     *
     */
    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}