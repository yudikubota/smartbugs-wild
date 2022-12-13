{{
  "language": "Solidity",
  "sources": {
    "src/MessageKingOfTheHill.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MessageKingOfTheHill {
    string public topMessage;
    uint256 public highestPrice;
    address public highestBidder;

    function publish(string memory proposedMessage) public payable {
        if (msg.value > highestPrice) {
            //Send money back to prior highest bidder
            (bool sent,) = payable(highestBidder).call{value: highestPrice}("");
            require(sent, "Failed to send Ether");

            //Update to new message
            topMessage = proposedMessage;
            //Update to new high bid
            highestPrice = msg.value;
            //Update new highest bidder address
            highestBidder = msg.sender;
        }
        else {
            revert();
        }
    }
}
"
    }
  },
  "settings": {
    "remappings": [
      "ds-test/=lib/forge-std/lib/ds-test/src/",
      "forge-std/=lib/forge-std/src/"
    ],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "metadata": {
      "bytecodeHash": "ipfs"
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
    "evmVersion": "london",
    "libraries": {}
  }
}}