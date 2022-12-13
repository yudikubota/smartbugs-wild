{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "berlin",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 1000000
    },
    "remappings": [],
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
  },
  "sources": {
    "contracts/libraries/JBCurrencies.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library JBCurrencies {
  uint256 public constant ETH = 1;
  uint256 public constant USD = 2;
}
"
    }
  }
}}