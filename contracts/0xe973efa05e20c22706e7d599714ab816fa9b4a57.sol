{{
  "language": "Solidity",
  "sources": {
    "contracts/RandomNumber.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RandomNumber {
    uint salt = 0;

    event NumberPicked(uint _randomNumber);

    function getRandom(uint max) public {
      uint randomNumber = (uint256(keccak256(abi.encodePacked(block.number, block.difficulty, msg.sender, salt))) % max);
      salt++;
      emit NumberPicked(randomNumber);
    }
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    }
  }
}}