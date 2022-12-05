{"Owned.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
"},"Vault.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.7.0;

import "Owned.sol";

contract Vault is Owned {
    function withdraw() public onlyOwner {
        require(
            block.timestamp > 2137158000,
            "Not yet."
        );
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}
}
"}}