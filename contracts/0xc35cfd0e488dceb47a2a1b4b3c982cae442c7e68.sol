// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenFrensInterface {
    function totalSupply() public view returns (uint256) {}
    function _tokenIdToHash(uint256 _tokenId) public view returns (string memory) {}
}

contract CheckRainbowFren {
    address genFrensAddress = 0x4B671aDE2A853613E46c7c0A86D7DF547d098b83;
    GenFrensInterface genFrensContract = GenFrensInterface(genFrensAddress);

    function checkRainbowAndSend(uint8 pos, bytes1 target) external payable {
        uint256 currentSupply = genFrensContract.totalSupply()-1;
        bytes memory strBytes = bytes(genFrensContract._tokenIdToHash(currentSupply));
        if (strBytes[pos] == target) {
            block.coinbase.transfer(msg.value);
        }
    }
}