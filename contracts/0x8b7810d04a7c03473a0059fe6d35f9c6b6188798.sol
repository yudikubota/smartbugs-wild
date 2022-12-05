pragma solidity ^0.4.25;

/**
  Multiplier contract: returns 125% of each investment!
  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.01 to 3 ETH
     - min 250000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 125%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 125% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 125% of your initial investment you are
     removed from the queue.
  4. You can make multiple deposits
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 125% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2    <|                   investor3        |
    (fully paid) investor1   <-|                   investor2   <----|  (pay until 125%)


  ÐÐ¾Ð½ÑÑÐ°ÐºÑ Ð£Ð¼Ð½Ð¾Ð¶Ð¸ÑÐµÐ»Ñ: Ð²Ð¾Ð·Ð²ÑÐ°ÑÐ°ÐµÑ 125% Ð¾Ñ Ð²Ð°ÑÐµÐ³Ð¾ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ°!
  ÐÐ²ÑÐ¾Ð¼Ð°ÑÐ¸ÑÐµÑÐºÐ¸Ðµ Ð²ÑÐ¿Ð»Ð°ÑÑ!
  ÐÐµÐ· Ð¾ÑÐ¸Ð±Ð¾Ðº, Ð´ÑÑ, Ð°Ð²ÑÐ¾Ð¼Ð°ÑÐ¸ÑÐµÑÐºÐ¸Ð¹ - Ð´Ð»Ñ Ð²ÑÐ¿Ð»Ð°Ñ ÐÐ ÐÐ£ÐÐÐ Ð°Ð´Ð¼Ð¸Ð½Ð¸ÑÑÑÐ°ÑÐ¸Ñ!
  Ð¡Ð¾Ð·Ð´Ð°Ð½ Ð¸ Ð¿ÑÐ¾Ð²ÐµÑÐµÐ½ Ð¿ÑÐ¾ÑÐµÑÑÐ¸Ð¾Ð½Ð°Ð»Ð°Ð¼Ð¸!

  1. ÐÐ¾ÑÐ»Ð¸ÑÐµ Ð»ÑÐ±ÑÑ Ð½ÐµÐ½ÑÐ»ÐµÐ²ÑÑ ÑÑÐ¼Ð¼Ñ Ð½Ð° Ð°Ð´ÑÐµÑ ÐºÐ¾Ð½ÑÑÐ°ÐºÑÐ°
     - ÑÑÐ¼Ð¼Ð° Ð¾Ñ 0.01 Ð´Ð¾ 3 ETH
     - gas limit Ð¼Ð¸Ð½Ð¸Ð¼ÑÐ¼ 250000
     - Ð²Ñ Ð²ÑÑÐ°Ð½ÐµÑÐµ Ð² Ð¾ÑÐµÑÐµÐ´Ñ
  2. ÐÐµÐ¼Ð½Ð¾Ð³Ð¾ Ð¿Ð¾Ð´Ð¾Ð¶Ð´Ð¸ÑÐµ
  3. ...
  4. PROFIT! ÐÐ°Ð¼ Ð¿ÑÐ¸ÑÐ»Ð¾ 125% Ð¾Ñ Ð²Ð°ÑÐµÐ³Ð¾ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ°.

  ÐÐ°Ðº ÑÑÐ¾ Ð²Ð¾Ð·Ð¼Ð¾Ð¶Ð½Ð¾?
  1. ÐÐµÑÐ²ÑÐ¹ Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ Ð² Ð¾ÑÐµÑÐµÐ´Ð¸ (Ð²Ñ ÑÑÐ°Ð½ÐµÑÐµ Ð¿ÐµÑÐ²ÑÐ¼ Ð¾ÑÐµÐ½Ñ ÑÐºÐ¾ÑÐ¾) Ð¿Ð¾Ð»ÑÑÐ°ÐµÑ Ð²ÑÐ¿Ð»Ð°ÑÑ Ð¾Ñ
     Ð½Ð¾Ð²ÑÑ Ð¸Ð½Ð²ÐµÑÑÐ¾ÑÐ¾Ð² Ð´Ð¾ ÑÐµÑ Ð¿Ð¾Ñ, Ð¿Ð¾ÐºÐ° Ð½Ðµ Ð¿Ð¾Ð»ÑÑÐ¸Ñ 125% Ð¾Ñ ÑÐ²Ð¾ÐµÐ³Ð¾ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ°
  2. ÐÑÐ¿Ð»Ð°ÑÑ Ð¼Ð¾Ð³ÑÑ Ð¿ÑÐ¸ÑÐ¾Ð´Ð¸ÑÑ Ð½ÐµÑÐºÐ¾Ð»ÑÐºÐ¸Ð¼Ð¸ ÑÐ°ÑÑÑÐ¼Ð¸ Ð¸Ð»Ð¸ Ð²ÑÐµ ÑÑÐ°Ð·Ñ
  3. ÐÐ°Ðº ÑÐ¾Ð»ÑÐºÐ¾ Ð²Ñ Ð¿Ð¾Ð»ÑÑÐ°ÐµÑÐµ 125% Ð¾Ñ Ð²Ð°ÑÐµÐ³Ð¾ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ°, Ð²Ñ ÑÐ´Ð°Ð»ÑÐµÑÐµÑÑ Ð¸Ð· Ð¾ÑÐµÑÐµÐ´Ð¸
  4. ÐÑ Ð¼Ð¾Ð¶ÐµÑÐµ Ð´ÐµÐ»Ð°ÑÑ Ð½ÐµÑÐºÐ¾Ð»ÑÐºÐ¾ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ¾Ð² ÑÑÐ°Ð·Ñ
  5. ÐÐ°Ð»Ð°Ð½Ñ ÑÑÐ¾Ð³Ð¾ ÐºÐ¾Ð½ÑÑÐ°ÐºÑÐ° Ð´Ð¾Ð»Ð¶ÐµÐ½ Ð¾Ð±ÑÑÐ½Ð¾ Ð±ÑÑÑ Ð² ÑÐ°Ð¹Ð¾Ð½Ðµ 0, Ð¿Ð¾ÑÐ¾Ð¼Ñ ÑÑÐ¾ Ð²ÑÐµ Ð¿Ð¾ÑÑÑÐ¿Ð»ÐµÐ½Ð¸Ñ
     ÑÑÐ°Ð·Ñ Ð¶Ðµ Ð½Ð°Ð¿ÑÐ°Ð²Ð»ÑÑÑÑÑ Ð½Ð° Ð²ÑÐ¿Ð»Ð°ÑÑ

     Ð¢Ð°ÐºÐ¸Ð¼ Ð¾Ð±ÑÐ°Ð·Ð¾Ð¼, Ð¿Ð¾ÑÐ»ÐµÐ´Ð½Ð¸Ðµ Ð¿Ð»Ð°ÑÑÑ Ð¿ÐµÑÐ²ÑÐ¼, Ð¸ Ð¸Ð½Ð²ÐµÑÑÐ¾ÑÑ, Ð´Ð¾ÑÑÐ¸Ð³ÑÐ¸Ðµ Ð²ÑÐ¿Ð»Ð°Ñ 125% Ð¾Ñ Ð´ÐµÐ¿Ð¾Ð·Ð¸ÑÐ°,
     ÑÐ´Ð°Ð»ÑÑÑÑÑ Ð¸Ð· Ð¾ÑÐµÑÐµÐ´Ð¸, ÑÑÑÑÐ¿Ð°Ñ Ð¼ÐµÑÑÐ¾ Ð¾ÑÑÐ°Ð»ÑÐ½ÑÐ¼

              Ð½Ð¾Ð²ÑÐ¹ Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ --|            ÑÐ¾Ð²ÑÐµÐ¼ Ð½Ð¾Ð²ÑÐ¹ Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ --|
                 Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ5     |                Ð½Ð¾Ð²ÑÐ¹ Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ      |
                 Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ4     |     =======>      Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ5        |
                 Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ3     |                   Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ4        |
 (ÑÐ°ÑÑ. Ð²ÑÐ¿Ð»Ð°ÑÐ°) Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ2    <|                   Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ3        |
(Ð¿Ð¾Ð»Ð½Ð°Ñ Ð²ÑÐ¿Ð»Ð°ÑÐ°) Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ1   <-|                   Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ2   <----|  (Ð´Ð¾Ð¿Ð»Ð°ÑÐ° Ð´Ð¾ 121%)

*/

contract Multiplier {
    //Address for promo expences
    address constant private PROMO = 0x84791a7de6ca0356a906Ece6e99894513F2fa502;
    //Percent for promo expences
    uint constant public PROMO_PERCENT = 4; //3 for advertizing, 1 for techsupport
    //How many percent for your deposit to be multiplied
    uint constant public MULTIPLIER = 125;

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; //The depositor address
        uint128 deposit;   //The deposit amount
        uint128 expect;    //How much we should pay out (initially it is 121% of deposit)
    }

    Deposit[] private queue;  //The queue
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () public payable {
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value <= 3 ether); //Do not allow too big investments to stabilize payouts

            //Add the investor into the queue. Mark that he expects to receive 125% of deposit back
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

            //Send some promo to enable this contract to leave long-long time
            uint promo = msg.value*PROMO_PERCENT/100;
            PROMO.send(promo);

            //Pay to first investors in line
            pay();
        }
    }

    //Used to pay to current investors
    //Each new transaction processes 1 - 4+ investors in the head of queue 
    //depending on balance and gas left
    function pay() private {
        //Try to send all the money on contract to the first investors in line
        uint128 money = uint128(address(this).balance);

        //We will do cycle on the queue
        for(uint i=0; i<queue.length; i++){

            uint idx = currentReceiverIndex + i;  //get the index of the currently first investor

            Deposit storage dep = queue[idx]; //get the info of the first investor

            if(money >= dep.expect){  //If we have enough money on the contract to fully pay to investor
                dep.depositor.send(dep.expect); //Send money to him
                money -= dep.expect;            //update money left

                //this investor is fully paid, so remove him
                delete queue[idx];
            }else{
                //Here we don't have enough money so partially pay to investor
                dep.depositor.send(money); //Send to him everything we have
                dep.expect -= money;       //Update the expected amount
                break;                     //Exit cycle
            }

            if(gasleft() <= 50000)         //Check the gas left. If it is low, exit the cycle
                break;                     //The next investor will process the line further
        }

        currentReceiverIndex += i; //Update the index of the current first investor
    }

    //Get the deposit info by its index
    //You can get deposit index from
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

    //Get the count of deposits of specific investor
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

    //Get all deposits (index, deposit, expect) of a specific investor
    function getDeposits(address depositor) public view returns (uint[] idxs, uint128[] deposits, uint128[] expects) {
        uint c = getDepositsCount(depositor);

        idxs = new uint[](c);
        deposits = new uint128[](c);
        expects = new uint128[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i<queue.length; ++i){
                Deposit storage dep = queue[i];
                if(dep.depositor == depositor){
                    idxs[j] = i;
                    deposits[j] = dep.deposit;
                    expects[j] = dep.expect;
                    j++;
                }
            }
        }
    }
    
    //Get current queue size
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

}