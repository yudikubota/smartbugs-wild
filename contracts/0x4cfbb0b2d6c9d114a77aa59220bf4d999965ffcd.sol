{"AbstractSweeper.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Controller.sol";
import "./Token.sol";

abstract contract AbstractSweeper {
  Controller internal controller;

  constructor(Controller _controller) {
    controller = _controller;
  }

  modifier canSweep() {
    require(
      msg.sender == controller.authorizedCaller()
      || msg.sender == controller.owner()
      || msg.sender == controller.dev(),
      "not authorized"
    );
    require(controller.halted() == false, "controller is halted");
    _;
  }

  function sweep(address token, uint amount) public virtual returns (bool);

  fallback () payable external { revert(); }
  receive () payable external { revert(); }
}

contract DefaultSweeper is AbstractSweeper {
  constructor(Controller _controller) AbstractSweeper(_controller) {}

  function sweep(address _token, uint _amount) override public canSweep returns (bool) {
    bool success = false;
    address payable destination = controller.destination();

    if (_token != address(0)) {
      Token token = Token(_token);
      uint amount = _amount;
      if (amount > token.balanceOf(address(this))) {
          return false;
      }
      success = token.transfer(destination, amount);
    }
    else {
      uint amountInWei = _amount;
      if (amountInWei > address(this).balance) {
          return false;
      }

      success = destination.send(amountInWei);
    }

    if (success) {
      controller.logSweep(this, destination, _token, _amount);
    }
    return success;
  }
}"},"AbstractSweeperList.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeper.sol";

abstract contract AbstractSweeperList {
  function sweeperOf(address _token) public virtual returns (address);
}"},"Controller.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeper.sol";
import "./AbstractSweeperList.sol";
import "./UserWallet.sol";

contract Controller is AbstractSweeperList {
  address public owner;
  address public authorizedCaller;
  address public dev;
  address payable public destination;

  bool public halted;

  address public defaultSweeper = address(new DefaultSweeper(this));
  mapping (address => address) sweepers;

  event LogNewWallet(address receiver);
  event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);
  
  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  modifier onlyAdmins() {
    require(msg.sender == authorizedCaller || msg.sender == owner || msg.sender == dev, "not admin");
    _;
  }

  constructor() {
    owner = msg.sender;
    destination = payable(msg.sender);
    authorizedCaller = msg.sender;
    dev = msg.sender;
  }

  function changeAuthorizedCaller(address _newCaller) public onlyOwner {
    authorizedCaller = _newCaller;
  }

  function changeDestination(address payable _dest) public onlyOwner {
    destination = _dest;
  }

  function changeOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  function changeDev(address _dev) public onlyOwner {
    dev = _dev;
  }

  function makeWallet() public onlyAdmins returns (address wallet)  {
    wallet = address(new UserWallet(this));
    emit LogNewWallet(wallet);
  }

  function halt() public onlyAdmins {
    halted = true;
  }

  function start() public onlyOwner {
    halted = false;
  }

  function addSweeper(address _token, address _sweeper) public onlyOwner {
    sweepers[_token] = _sweeper;
  }

  function sweeperOf(address _token) override public view returns (address) {
    address sweeper = sweepers[_token];
    if (sweeper == address(0)) sweeper = defaultSweeper;
    return sweeper;
  }

  function logSweep(AbstractSweeper from, address to, address token, uint amount) public {
    emit LogSweep(address(from), to, token, amount);
  }
}"},"Token.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Token {
  function balanceOf(address) public virtual returns (uint);
  function transfer(address, uint) public virtual returns (bool);
}"},"UserWallet.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeperList.sol";

contract UserWallet {
  AbstractSweeperList sweeperList;
  constructor(AbstractSweeperList _sweeperlist) {
    sweeperList = _sweeperlist;
  }

  fallback () payable external { }
  receive () payable external { }

  function tokenFallback(address _from, uint _value, bytes memory _data) public pure {}

  function sweep(address _token, uint) public returns (bool) {
    (bool success, ) = sweeperList.sweeperOf(_token).delegatecall(msg.data);
    return success;
  }
}"}}