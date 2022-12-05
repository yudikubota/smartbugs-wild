{{
  "language": "Solidity",
  "sources": {
    "solidity/contracts/Payer.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract Payer {
  function pay() public payable {
    payable(block.coinbase).transfer(msg.value);
  }
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "metadata": {
      "useLiteralContent": true
    },
    "libraries": {}
  }
}}