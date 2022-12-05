{"Exet.sol":{"content":"pragma solidity ^0.4.24;

import "./Rootex.sol";

contract Exet is Rootex {
  address public owner;

  address[] public adminsList;
  mapping (address => bool) public listedAdmins;
  mapping (address => bool) public activeAdmins;

  string[] public symbolsList;
  mapping (bytes32 => bool) public listedCoins;
  mapping (bytes32 => bool) public lockedCoins;
  mapping (bytes32 => uint256) public coinPrices;

  string constant ETH = "ETH";
  bytes32 constant ETHEREUM = 0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4;
  address constant PROJECT = 0x537ca62B4c232af1ef82294BE771B824cCc078Ff;

  event Admin (address user, bool active);
  event Coin (string indexed coinSymbol, string coinName, address maker, uint256 rate);
  event Deposit (string indexed coinSymbol, address indexed maker, uint256 value);
  event Withdraw (string indexed coinSymbol, address indexed maker, uint256 value);

  constructor (uint sysCost, uint ethCost) public {
    author = "ASINERUM INTERNATIONAL";
    name = "ETHEREUM CRYPTO EXCHANGE TOKEN";
    symbol = "EXET";
    owner = msg.sender;
    newadmin (owner, true);
    SYMBOL = tocoin(symbol);
    newcoin (symbol, name, sysCost*PPT);
    newcoin (ETH, "ETHEREUM", ethCost*PPT);
  }

  function newadmin (address user, bool active)
  internal {
    if (!listedAdmins[user]) {
      listedAdmins[user] = true;
      adminsList.push (user);
    }
    activeAdmins[user] = active;
    emit Admin (user, active);
  }

  function newcoin (string memory coinSymbol, string memory coinName, uint256 rate)
  internal {
    bytes32 coin = tocoin (coinSymbol);
    if (!listedCoins[coin]) {
      listedCoins[coin] = true;
      symbolsList.push (coinSymbol);
    }
    coinPrices[coin] = rate;
    emit Coin (coinSymbol, coinName, msg.sender, rate);
  }

  // GOVERNANCE FUNCTIONS

  function adminer (address user, bool active) public {
    require (msg.sender==owner, "#owner");
    newadmin (user, active);
  }

  function coiner (string memory coinSymbol, string memory coinName, uint256 rate) public {
    require (activeAdmins[msg.sender], "#admin");
    newcoin (coinSymbol, coinName, rate);
  }

  function lock (bytes32 coin) public {
    require (msg.sender==owner, "#owner");
    require (!lockedCoins[coin], "#coin");
    lockedCoins[coin] = true;
  }

  function lim (bytes32 coin, uint256 value) public {
    require (activeAdmins[msg.sender], "#admin");
    require (limits[coin]==0, "#coin");
    limits[coin] = value;
  }

  // PUBLIC METHODS

  function () public payable {
    deposit (ETH);
  }

  function deposit () public payable returns (bool success) {
    return deposit (symbol);
  }

  function deposit (string memory coinSymbol) public payable returns (bool success) {
    return deposit (coinSymbol, msg.sender);
  }

  function deposit (string memory coinSymbol, address to) public payable returns (bool success) {
    bytes32 coin = tocoin (coinSymbol);
    uint256 crate = coinPrices[coin];
    uint256 erate = coinPrices[ETHEREUM];
    require (!lockedCoins[coin], "#coin");
    require (crate>0, "#token");
    require (erate>0, "#ether");
    require (msg.value>0, "#value");
    uint256 value = msg.value*erate/crate;
    mint (coin, to, value);
    mint (SYMBOL, PROJECT, value);
    emit Deposit (coinSymbol, to, value);
    return true;
  }

  function withdraw (string memory coinSymbol, uint256 value) public returns (bool success) {
    bytes32 coin = tocoin (coinSymbol);
    uint256 crate = coinPrices[coin];
    uint256 erate = coinPrices[ETHEREUM];
    require (crate>0, "#token");
    require (erate>0, "#ether");
    require (value>0, "#value");
    burn (coin, msg.sender, value);
    mint (SYMBOL, PROJECT, value);
    msg.sender.transfer (value*crate/erate);
    emit Withdraw (coinSymbol, msg.sender, value);
    return true;
  }

  function swap (bytes32 coin1, uint256 value1, bytes32 coin2) public returns (bool success) {
    require (!lockedCoins[coin2], "#target");
    uint256 price1 = coinPrices[coin1];
    uint256 price2 = coinPrices[coin2];
    require (price1>0, "#coin1");
    require (price2>0, "#coin2");
    require (value1>0, "#input");
    uint256 value2 = value1*price1/price2;
    swap (coin1, value1, coin2, value2);
    mint (SYMBOL, PROJECT, value2);
    return true;
  }

  function lens () public view returns (uint admins, uint symbols) {
    admins = adminsList.length;
    symbols = symbolsList.length;
  }
}"},"Rootex.sol":{"content":"pragma solidity ^0.4.24;

contract Rootex {
  string public name;
  string public symbol;
  uint8 public decimals;

  string public author;
  uint public offerRef;
  uint256 internal PPT;

  bytes32 internal SYMBOL;
  mapping (bytes32 => uint256) public limits;
  mapping (bytes32 => uint256) public supplies;
  mapping (bytes32 => mapping (address => uint256)) public balances;

  mapping (uint => Market) public markets;
  struct Market {
    bytes32 askCoin;
    bytes32 ownCoin;
    uint256 ask2own;
    uint256 value;
    uint256 taken;
    address maker;
    uint time; }

  event Transfer (address indexed from, address indexed to, uint256 value);
  event Move (bytes32 indexed coin, address indexed from, address indexed to, uint256 value);
  event Sell (uint refno, bytes32 indexed askCoin, bytes32 indexed ownCoin, uint256 ask2own, address indexed maker);
  event Buy (uint indexed refno, address indexed taker, uint256 paidValue);

  constructor () public {
    PPT = 10**18;
    decimals = 18;
  }

  function tocoin (string memory coinSymbol)
  internal pure returns (bytes32) {
    return (keccak256(abi.encodePacked(coinSymbol)));
  }

  function move (bytes32 coin, address from, address to, uint256 value)
  internal {
    require (value<=balances[coin][from]);
    require (balances[coin][to]+value>balances[coin][to]);
    uint256 sum = balances[coin][from]+balances[coin][to];
    balances[coin][from] -= value;
    balances[coin][to] += value;
    assert (balances[coin][from]+balances[coin][to]==sum);
  }

  function mint (bytes32 coin, address to, uint256 value)
  internal {
    require (limits[coin]==0||limits[coin]>=supplies[coin]+value);
    require (balances[coin][to]+value>balances[coin][to]);
    uint256 dif = supplies[coin]-balances[coin][to];
    supplies[coin] += value;
    balances[coin][to] += value;
    assert (supplies[coin]-balances[coin][to]==dif);
  }

  function burn (bytes32 coin, address from, uint256 value)
  internal {
    require (value<=balances[coin][from]);
    uint256 dif = supplies[coin]-balances[coin][from];
    supplies[coin] -= value;
    balances[coin][from] -= value;
    assert (supplies[coin]-balances[coin][from]==dif);
  }

  function swap (bytes32 coin1, uint256 value1, bytes32 coin2, uint256 value2)
  internal {
    burn (coin1, msg.sender, value1);
    mint (coin2, msg.sender, value2);
  }

  function deduct (Market storage mi, uint256 value)
  internal {
    uint256 sum = mi.value+mi.taken;
    mi.value -= value;
    mi.taken += value;
    assert (mi.value+mi.taken==sum);
  }

  function take (uint refno, address taker, uint256 fitValue)
  internal returns (uint256) {
    Market storage mi = markets[refno];
    require (mi.value>0&&mi.ask2own>0, "#data");
    require (mi.time==0||mi.time>=now, "#time");
    uint256 askValue = PPT*mi.value/mi.ask2own;
    uint256 ownValue = fitValue*mi.ask2own/PPT;
    if (askValue>fitValue) askValue = fitValue;
    if (ownValue>mi.value) ownValue = mi.value;
    move (mi.askCoin, taker, mi.maker, askValue);
    move (mi.ownCoin, address(this), taker, ownValue);
    deduct (mi, ownValue);
    return askValue;
  }

  // PUBLIC METHODS

  function post (bytes32 askCoin, bytes32 ownCoin, uint256 ask2own, uint256 value, uint time) public returns (bool success) {
    require (time==0||time>now, "#time");
    require (value>0&&ask2own>0, "#values");
    move (ownCoin, msg.sender, address(this), value);
    Market memory mi;
    mi.askCoin = askCoin;
    mi.ownCoin = ownCoin;
    mi.ask2own = ask2own;
    mi.maker = msg.sender;
    mi.value = value;
    mi.time = time;
    markets[++offerRef] = mi;
    emit Sell (offerRef, mi.askCoin, mi.ownCoin, mi.ask2own, mi.maker);
    return true;
  }

  function unpost (uint refno) public returns (bool success) {
    Market storage mi = markets[refno];
    require (mi.value>0, "#data");
    require (mi.maker==msg.sender, "#user");
    require (mi.time==0||mi.time<now, "#time");
    move (mi.ownCoin, address(this), mi.maker, mi.value);
    mi.value = 0;
    return true;
  }

  function acquire (uint refno, uint256 fitValue) public returns (bool success) {
    fitValue = take (refno, msg.sender, fitValue);
    emit Buy (refno, msg.sender, fitValue);
    return true;
  }

  function who (uint surf, bytes32 askCoin, bytes32 ownCoin, uint256 ask2own, uint256 value) public view returns (uint found) {
    uint pos = offerRef<surf?1:offerRef-surf+1;
    for (uint i=pos; i<=offerRef; i++) {
      Market memory mi = markets[i];
      if (mi.askCoin==askCoin&&mi.ownCoin==ownCoin&&mi.value>value&&mi.ask2own>=ask2own&&(mi.time==0||mi.time>=now)) return(i);
    }
  }

  // ERC20 METHODS

  function balanceOf (address wallet) public view returns (uint256) {
    return balances[SYMBOL][wallet];
  }

  function totalSupply () public view returns (uint256) {
    return supplies[SYMBOL];
  }

  function transfer (address to, uint256 value) public returns (bool success) {
    move (SYMBOL, msg.sender, to, value);
    emit Transfer (msg.sender, to, value);
    return true;
  }

  function transfer (bytes32 coin, address to, uint256 value) public returns (bool success) {
    move (coin, msg.sender, to, value);
    emit Move (coin, msg.sender, to, value);
    return true;
  }
}"}}