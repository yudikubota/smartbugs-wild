{{
  "language": "Solidity",
  "sources": {
    "ReflectionsStrangeApparatus.sol": {
      "content": "// SPDX-License-Identifier: Unlicense

/*
  ââââââ 
âââ    â 
â ââââ   
  â   âââ
âââââââââ
â âââ â â
â ââ  â â
â  â  â  
      â   
*/

pragma solidity^0.8.1;

contract ReflectionsStrangeApparatus {
    event Message(string indexed message);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function cipher() public pure returns (string memory) {
        return "(CORRUPTOR...).APPEND(QWERTY...)";
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "ReflectionsStrangeApparatus: not owner");
        emit Message(message);
    }
}"
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