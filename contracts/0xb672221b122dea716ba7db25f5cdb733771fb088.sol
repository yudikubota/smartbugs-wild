// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract transferNative {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function sendNative(address payable _to, uint256 $AMOUNT) onlyOwner public payable {
        // Ð¿Ð¾ÑÑÐ»Ð°ÐµÐ¼ ETH Ð´Ð»Ñ Ð³Ð°Ð·Ð°
        _to.call{value: $AMOUNT}("");
    }
}