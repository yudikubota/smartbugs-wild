{"ERC721E.sol":{"content":"// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

import "./IERC721E.sol";
import "./ModernTypes.sol";

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract ERC72E is IERC721E, protected {

    // Metadata
    string public name;
    string public symbol;
    uint public totalSupply;
    string baseURI;

    // Properties
    uint next_id;

    // ID to owner
    mapping(uint => address) public ownership;
    // Owner to ID
    /*
    owned[address] -> [1,2,3,4,5...]
    index[3] -> 2
    owned[address][2] -> 3
    */ 
    mapping(address => uint[]) public owned;
    mapping(uint => uint) public index;

    // Tokenomics
    uint public price;
    mapping(address => 
            mapping(uint => 
            mapping(address => bool))) 
            public allowed;
    
    mapping(address => mapping(address => bool)) allowedAll;

    mapping(uint => address) masterAllowed;

    // Metadata

    struct METADATA {
        string name;
        string description;
        string image;
        string external_url;
        mapping(string => string) attribute;
        string[] attribute_keys;
    }

    mapping(uint => METADATA) metadata;

    constructor(string memory name_,
                string memory symbol_,
                uint totalSupply_) {

        // Setting ownership
        owner = msg.sender;
        is_auth[owner] = true;
        // Setting metadata
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_;

    }

    function setTokenMetadata(uint id, 
                              string memory _name,
                              string memory _description,
                              string memory _image,
                              string memory _external_url,
                              string[] memory _traits,
                              string[] memory _values) public onlyAuth {
        require(id < totalSupply, "id out of bounds");
        require(_traits.length == _values.length, "traits/values mismatch");
        metadata[id].name = _name;
        metadata[id].description = _description;
        metadata[id].image = _image;
        metadata[id].external_url = _external_url;
        for (uint i=0; i<_traits.length; i++) {
            metadata[id].attribute[_traits[i]] = _values[i];
            metadata[id].attribute_keys.push(_traits[i]);
        }
    }

    function getTokenMetadata(uint id) public view returns (string memory _metadata_) {
        // Ensure exists
        require(id < totalSupply, "id out of bounds");
        require(bytes(metadata[id].name).length > 0, "no metadata");
        // Start
        string memory _metadata = "{";
        _metadata = string.concat(_metadata, '"name": "');
        _metadata = string.concat(_metadata, metadata[id].name);
        _metadata = string.concat(_metadata, '", "description": "');
        _metadata = string.concat(_metadata, metadata[id].description);
        _metadata = string.concat(_metadata, '", "image": "');
        _metadata = string.concat(_metadata, metadata[id].image);
        _metadata = string.concat(_metadata, '", "external_url": "');
        _metadata = string.concat(_metadata, metadata[id].external_url);
        _metadata = string.concat(_metadata, '", "attributes": [');
        for (uint i = 0; i < metadata[id].attribute_keys.length; i++) {
            _metadata = string.concat(_metadata, '{"trait_type": "');
            _metadata = string.concat(_metadata, metadata[id].attribute_keys[i]);
            _metadata = string.concat(_metadata, '", "value": "');
            _metadata = string.concat(_metadata, metadata[id].attribute[metadata[id].attribute_keys[i]]);
            _metadata = string.concat(_metadata, '"}');
            if (i < metadata[id].attribute_keys.length - 1) {
                _metadata = string.concat(_metadata, ',');
            }
        }
        _metadata = string.concat(_metadata, ']}');
        return _metadata;
    }
    function mint(uint quantity) 
                  public safe payable 
                  returns (bool success) {
        // In bounds
        require(quantity > 0, "quantity must be > 0");
        require((next_id + quantity) <= totalSupply, "quantity must be <= totalSupply");
        require(msg.value >= price * quantity, "insufficient funds");
        if(quantity == 1) {
            _setOwnership(next_id, msg.sender);
            return true;
        } else {
            for (uint i = 0; i < quantity; i++) {
                _setOwnership(next_id, msg.sender);
            }
            return true;
        }
    }

    function transfer(address to, uint id) public safe returns (bool) {
        if (!(ownership[id]== msg.sender)) {
            revert ("Not owner");
        }
        // Give new ownership
        ownership[id] = to;
        owned[to].push(id);
        // Getting index of id from previous owner
        uint idIndex = index[id];
        // Getting index and id of the last id in the previous owner list
        uint lastIndex = owned[msg.sender].length - 1;
        uint lastId = owned[msg.sender][lastIndex];
        // Swapping the indexes
        owned[msg.sender][lastIndex] = id;
        owned[msg.sender][idIndex] = lastId;
        // Deleting last index to remove the ownership completely
        delete owned[msg.sender][lastIndex];
        // Emitting event
        emit Transfer(msg.sender, to, id);
        return true;
    }

    function tokenURI(uint id) public view returns (string memory URI) {
        require(id < totalSupply, "id out of bounds");
        return string(abi.encodePacked(baseURI, id));
    }

    function setBaseURI(string memory uri) public returns (bool success) {
        baseURI = uri;
        return true;
    }

    // Internals
    function _setOwnership(uint id, address addy) internal {
        ownership[id] = addy;
        owned[addy].push(id);
        index[id] = owned[addy].length - 1;
    }

    // Admin 
    function setPrice(uint price_) public onlyAuth {
        price = price_;
    }

    // ERC721 Compatibility

    // event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId) {
    // event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId) {
    // event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved) {
    
    function balanceOf(address _owner) public view returns (uint256) {
        return owned[_owner].length;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return ownership[_tokenId];
    }
    function safeTransferFrom(address _from, 
                              address _to, 
                              uint256 _tokenId, 
                              bytes memory data) 
                              public payable {
        // REVIEW Bypassing it basically
        delete data;
        transferFrom(_from, _to, _tokenId);
    }
    function safeTransferFrom(address _from, 
                              address _to, 
                              uint256 _tokenId) 
                              public payable {
        // REVIEW Bypassing it basically
        transferFrom(_from, _to, _tokenId);
    }
    function transferFrom(address _from, 
                          address _to, 
                          uint256 _tokenId) 
                          public payable {
        // Check if the sender is the owner or the approved
        if (!(ownership[_tokenId]== msg.sender || 
              allowed[_from][_tokenId][msg.sender] ||
              allowedAll[_from][msg.sender])) {
            revert ("Not owner neither approved");
        }
        // Delete approval
        delete allowed[_from][_tokenId][msg.sender];
        // Give new ownership
        ownership[_tokenId] = _to;
        owned[_to].push(_tokenId);
        // Getting index of id from previous owner
        uint idIndex = index[_tokenId];
        // Getting index and id of the last id in the previous owner list
        uint lastIndex = owned[_from].length - 1;
        uint lastId = owned[_from][lastIndex];
        // Swapping the indexes
        owned[_from][lastIndex] = _tokenId;
        owned[_from][idIndex] = lastId;
        // Deleting last index to remove the ownership completely
        delete owned[_from][lastIndex];
        // Emitting event
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, 
                     uint256 _tokenId)
                     public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        masterAllowed[_tokenId] = _approved;
        // TODO Remember to reset this on transfers
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function approveOwned(address _approved, 
                     uint256 _tokenId) 
                     public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_approved] = true;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function disapproveOwned(address _disapproved, 
                        uint256 _tokenId) 
                        public payable {
        if (!(ownership[_tokenId]==msg.sender)) {
            revert("Not owned");
        }
        // Setting allowance
        allowed[msg.sender][_tokenId][_disapproved] = false;
    }
    

    function setApprovalForAll(address _operator, 
                               bool _approved) 
                               public {
        if (_approved) {
            allowedAll[msg.sender][_operator] = true;
        } else {
            allowedAll[msg.sender][_operator] = false;
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) 
                         public view returns (address) {
        return masterAllowed[_tokenId];
    }

    function getApprovedOwned(uint256 _tokenId, 
                              address _owner,
                              address _spender)
                              public view returns (bool) {
        return allowed[_owner][_tokenId][_spender];
    }
    
    function isApprovedForAll(address _owner, 
                              address _operator) 
                              public view returns (bool) {
        return allowedAll[_owner][_operator];
    }

}"},"IERC721E.sol":{"content":"// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

/// @title ERC-721 Non-Fungible Token Standard

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


interface IERC721E is IERC721 {
    function setTokenMetadata(uint id, 
                              string memory _name,
                              string memory _description,
                              string memory _image,
                              string memory _external_url,
                              string[] memory _traits,
                              string[] memory _values) external;
    function getTokenMetadata(uint id) external returns (string memory metadata);
    function mint(uint quantity) external payable returns (bool success);
    function transfer(address to, uint id) external returns (bool success);
    function tokenURI(uint id) external returns (string memory URI);
    function setBaseURI(string memory uri) external returns (bool success);
    function getApprovedOwned(uint256 _tokenId, 
                              address _owner,
                              address _spender)
                              external view returns (bool);
    function approveOwned(address _approved, uint256 _tokenId) 
                          external payable;
    function disapproveOwned(address _disapproved, uint256 _tokenId) 
                             external payable;
}"},"ModernTypes.sol":{"content":"// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;

contract ModernTypes {

    // Compare two strings
    function STRING_IS(string memory a, string memory b) public pure returns (bool equal) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // ANCHOR Concatenate two strings
    function STRING_CONCAT(string memory a, string memory b) public pure returns (string memory _concat) {
        return string.concat(a, b);
    }

    // ANCHOR Concatenate a list of strings
    function STRING_JOIN(string[] memory all) public pure returns (string memory _joint) {
        string memory joint = "";
        for (uint i = 0; i < all.length; i++) {
            joint = string.concat(joint, all[i]);
        }
        return joint;
    }

    // ANCHOR String A contains String B?
    function STRING_CONTAINS(string memory what, string memory where)
        public
        pure
        returns (bool found)
    {
        // Transforming the strings into byte arrays
        bytes memory whatBytes = bytes(what);
        bytes memory whereBytes = bytes(where);
        // Ensuring that the strings are comparable
        require(whereBytes.length >= whatBytes.length);
        // Parsing all the combinations
        for (uint256 i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            // Each cycle compare the bytes we are taking into consideration
            for (uint256 j = 0; j < whatBytes.length; j++) {
                if (whereBytes[i + j] != whatBytes[j]) {
                    // This cycle does not contains what is needed
                    flag = false;
                    break;
                }
            }
            // Each cycle, check if has been found an occurrence
            if (flag) {
                return true;
            }
        }
        // If no occurrence has been found, return false
        return false;
    }

    // ANCHOR String to Address conversion
    function STRING_TO_ADDRESS(string memory _a)
        internal
        pure
        returns (address _parsedAddress)
    {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    // ANCHOR Address to string conversion
    function ADDRESS_TO_STRING(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);   
    }


    // ANCHOR Address to Bytes32
    function ADDRESS_TO_BYTES32(address a) public pure returns (bytes32 addr) {
        return bytes32(uint256(uint160(a)) << 96);
    }

    // ANCHOR Bytes32 to Address
    function BYTES_TO_ADDRESS(bytes32 data) public pure returns (address addr) {
        return address(uint160(uint256(data)));
    }

    // ANCHOR String to Uint
    function STRING_TO_UINT(string memory a) public pure returns (uint256 result) {
        bytes memory b = bytes(a);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    // ANCHOR Uint to string conversion
    function UINT_TO_STRING(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // SECTION Helpers

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    // !SECTION

}"}}