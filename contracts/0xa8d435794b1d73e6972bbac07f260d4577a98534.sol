{"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
contract Ownable {
    bytes32 private constant ownerPosition = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address ownerAddress) {
        setOwner(ownerAddress);
    }

    function setOwner(address newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, newOwner)
        }
    }

    function getOwner() public view returns (address owner) {
        bytes32 position = ownerPosition;
        assembly {
            owner := sload(position)
        }
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner());
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }
}"},"Proxy.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";

contract Proxy is Ownable {

    bytes32 private constant targetPosition = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address target) Ownable(msg.sender) {
        setTarget(target);
    }

    function getTarget() public view returns (address target) {
        bytes32 position = targetPosition;
        assembly {
            target := sload(position)
        }
    }

    function setTarget(address newTarget) internal onlyOwner {
        bytes32 position = targetPosition;
        assembly {
            sstore(position, newTarget)
        }
    }

    function upgradeTarget(address newTarget) public onlyOwner {
        setTarget(newTarget);
    }

    receive() external payable {}

    fallback() external payable onlyOwner {
        address _target = getTarget();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, ptr, calldatasize(), 0x0,0)
            let size := returndatasize()
            returndatacopy(ptr, 0x0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}"}}