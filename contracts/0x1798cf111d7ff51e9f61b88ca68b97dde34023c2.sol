{"Admin.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}
"},"IAdmin.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}
"},"Vote.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './VoteStorage.sol';

contract Vote is VoteStorage {

    event NewImplementation(address newImplementation);

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    receive() external payable {}

    fallback() external payable {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}
"},"VoteStorage.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './Admin.sol';

abstract contract VoteStorage is Admin {

    address public implementation;

    string public topic;

    uint256 public numOptions;

    uint256 public deadline;

    // voters may contain duplicated address, if one submits more than one votes
    address[] public voters;

    // voter address => vote
    // vote starts from 1, 0 is reserved for no vote
    mapping (address => uint256) public votes;

}
"}}