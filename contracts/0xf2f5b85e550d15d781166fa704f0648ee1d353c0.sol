{{
  "language": "Solidity",
  "sources": {
    "contracts/Pray.sol": {
      "content": "// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.9;

contract Pray {
    receive() external payable {}

    function _transfer() external {
        uint256 bal = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success);
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
    },
    "libraries": {}
  }
}}