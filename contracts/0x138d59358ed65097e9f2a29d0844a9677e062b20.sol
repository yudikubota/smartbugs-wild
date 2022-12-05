{{
  "language": "Solidity",
  "sources": {
    "/contracts/TinyBurn.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC721Burnable {
    function burn(uint256 tokenId) external;
}

contract TinyBurn {
    constructor() {}

    function massBurn(address tokenContract, uint256[] calldata tokens)
        public
        returns (bool)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC721Burnable(tokenContract).burn(tokens[i]);
        }
        return true;
    }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "evmVersion": "berlin",
    "libraries": {},
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