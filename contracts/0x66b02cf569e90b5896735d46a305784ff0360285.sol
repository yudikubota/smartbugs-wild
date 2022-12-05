{"BlobStorage.sol":{"content":"pragma solidity 0.5.10;

import './LibInteger.sol';
import './LibBlob.sol';

/**
 * @title BlobStorage 
 * @dev Store core details about the blobs permanently
 */
contract BlobStorage
{
    using LibInteger for uint;

    /**
     * @dev The admin of the contract
     */
    address payable private _admin;

    /**
     * @dev Permitted addresses to carry out storage functions
     */
    mapping (address => bool) private _permissions;

    /**
     * @dev Names of tokens
     */
    mapping (uint => uint) private _names;

    /**
     * @dev Listing prices of tokens
     */
    mapping (uint => uint) private _listings;

    /**
     * @dev Original minters of tokens
     */
    mapping (uint => address payable) private _minters;

    /**
     * @dev Names currently reserved
     */
    mapping (uint => bool) private _reservations;

    /**
     * @dev The metadata of blobs
     */
    mapping (uint => uint[]) private _metadata;

    /**
     * @dev Initialise the contract
     */
    constructor() public
    {
        //The contract creator becomes the admin
        _admin = msg.sender;
    }

    /**
     * @dev Allow access only for the admin of contract
     */
    modifier onlyAdmin()
    {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Allow access only for the permitted addresses
     */
    modifier onlyPermitted()
    {
        require(_permissions[msg.sender]);
        _;
    }

    /**
     * @dev Give or revoke permission of accounts
     * @param account The address to change permission
     * @param permission True if the permission should be granted, false if it should be revoked
     */
    function permit(address account, bool permission) public onlyAdmin
    {
        _permissions[account] = permission;
    }

    /**
     * @dev Withdraw from the balance of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole balance will be withdrawn
     */
    function clean(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _admin.transfer(address(this).balance);
        } else {
            _admin.transfer(amount);
        }
    }

    /**
     * @dev Set the name of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setName(uint id, uint value) public onlyPermitted
    {
        _names[id] = value;
    }

    /**
     * @dev Set the listing price of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setListing(uint id, uint value) public onlyPermitted
    {
        _listings[id] = value;
    }

    /**
     * @dev Set the original minter of token
     * @param id The id of token
     * @param value The value to be set
     */
    function setMinter(uint id, address payable value) public onlyPermitted
    {
        _minters[id] = value;
    }

    /**
     * @dev Set whether the name is reserved
     * @param name The name
     * @param value True if the name is reserved, otherwise false
     */
    function setReservation(uint name, bool value) public onlyPermitted
    {
        _reservations[name] = value;
    }

    /**
     * @dev Add a new version of metadata to the token
     * @param id The token id
     * @param value The value to be set
     */
    function incrementMetadata(uint id, uint value) public onlyPermitted
    {
        _metadata[id].push(value);
    }

    /**
     * @dev Remove the latest version of metadata from token
     * @param id The token id
     */
    function decrementMetadata(uint id) public onlyPermitted
    {
        _metadata[id].length = _metadata[id].length.sub(1);
    }

    /**
     * @dev Get name of token
     * @param id The id of token
     * @return string The name
     */
    function getName(uint id) public view returns (uint)
    {
        return _names[id];
    }

    /**
     * @dev Get listing price of token
     * @param id The id of token
     * @return uint The listing price
     */
    function getListing(uint id) public view returns (uint)
    {
        return _listings[id];
    }

    /**
     * @dev Get original minter of token
     * @param id The id of token
     * @return uint The original minter
     */
    function getMinter(uint id) public view returns (address payable)
    {
        return _minters[id];
    }

    /**
     * @dev Check whether the provided name is reserved
     * @param name The name to check
     * @return bool True if the name is reserved, otherwise false
     */
    function isReserved(uint name) public view returns (bool)
    {
        return _reservations[name];
    }

    /**
     * @dev Check whether the provided address is permitted
     * @param account The address to check
     * @return bool True if the address is permitted, otherwise false
     */
    function isPermitted(address account) public view returns (bool)
    {
        return _permissions[account];
    }

    /**
     * @dev Get latest version of metadata of token
     * @param id The id of token
     * @return uint The metadata value
     */
    function getLatestMetadata(uint id) public view returns (uint)
    {
        if (_metadata[id].length > 0) {
            return _metadata[id][_metadata[id].length.sub(1)];
        } else {
            return 0;
        }
    }

    /**
     * @dev Get previous version of metadata of token
     * @param id The id of token
     * @return uint The metadata value
     */
    function getPreviousMetadata(uint id) public view returns (uint)
    {
        if (_metadata[id].length > 1) {
            return _metadata[id][_metadata[id].length.sub(2)];
        } else {
            return 0;
        }
    }
}"},"LibBlob.sol":{"content":"pragma solidity 0.5.10;

/**
 * @title LibBlob
 * @dev Blob related utility functions
 */
library LibBlob
{
    struct Metadata
    {
        uint partner;
        uint level;
        uint param1;
        uint param2;
        uint param3;
        uint param4;
        uint param5;
        uint param6;
    }

    struct Name
    {
        uint char1;
        uint char2;
        uint char3;
        uint char4;
        uint char5;
        uint char6;
        uint char7;
        uint char8;
    }

    /**
     * @dev Convert metadata to a single integer
     * @param metadata The metadata to be converted
     * @return uint The integer representing the metadata
     */
    function metadataToUint(Metadata memory metadata) internal pure returns (uint)
    {
        uint params = uint(metadata.partner);
        params |= metadata.level<<32;
        params |= metadata.param1<<64;
        params |= metadata.param2<<96;
        params |= metadata.param3<<128;
        params |= metadata.param4<<160;
        params |= metadata.param5<<192;
        params |= metadata.param6<<224;

        return params;
    }

    /**
     * @dev Convert given integer to a metadata object
     * @param params The integer to be converted
     * @return Metadata The metadata represented by the integer
     */
    function uintToMetadata(uint params) internal pure returns (Metadata memory)
    {
        Metadata memory metadata;

        metadata.partner = uint(uint32(params));
        metadata.level = uint(uint32(params>>32));
        metadata.param1 = uint(uint32(params>>64));
        metadata.param2 = uint(uint32(params>>96));
        metadata.param3 = uint(uint32(params>>128));
        metadata.param4 = uint(uint32(params>>160));
        metadata.param5 = uint(uint32(params>>192));
        metadata.param6 = uint(uint32(params>>224));

        return metadata;
    }

    /**
     * @dev Convert name to a single integer
     * @param name The name to be converted
     * @return uint The integer representing the name
     */
    function nameToUint(Name memory name) internal pure returns (uint)
    {
        uint params = uint(name.char1);
        params |= name.char2<<32;
        params |= name.char3<<64;
        params |= name.char4<<96;
        params |= name.char5<<128;
        params |= name.char6<<160;
        params |= name.char7<<192;
        params |= name.char8<<224;

        return params;
    }

    /**
     * @dev Convert given integer to a name object
     * @param params The integer to be converted
     * @return Name The name represented by the integer
     */
    function uintToName(uint params) internal pure returns (Name memory)
    {
        Name memory name;

        name.char1 = uint(uint32(params));
        name.char2 = uint(uint32(params>>32));
        name.char3 = uint(uint32(params>>64));
        name.char4 = uint(uint32(params>>96));
        name.char5 = uint(uint32(params>>128));
        name.char6 = uint(uint32(params>>160));
        name.char7 = uint(uint32(params>>192));
        name.char8 = uint(uint32(params>>224));

        return name;
    }
}
"},"LibInteger.sol":{"content":"pragma solidity 0.5.10;

/**
 * @title LibInteger 
 * @dev Integer related utility functions
 */
library LibInteger
{    
    /**
     * @dev Safely multiply, revert on overflow
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function mul(uint a, uint b) internal pure returns (uint)
    {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Safely divide, revert if divisor is zero
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function div(uint a, uint b) internal pure returns (uint)
    {
        require(b > 0, "");
        uint c = a / b;

        return c;
    }

    /**
     * @dev Safely substract, revert if answer is negative
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function sub(uint a, uint b) internal pure returns (uint)
    {
        require(b <= a, "");
        uint c = a - b;

        return c;
    }

    /**
     * @dev Safely add, revert if overflow
     * @param a The first number
     * @param b The second number
     * @return uint The answer
    */
    function add(uint a, uint b) internal pure returns (uint)
    {
        uint c = a + b;
        require(c >= a, "");

        return c;
    }

    /**
     * @dev Convert number to string
     * @param value The number to convert
     * @return string The string representation
    */
    function toString(uint value) internal pure returns (string memory)
    {
        if (value == 0) {
            return "0";
        }

        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        uint index = digits - 1;
        
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        
        return string(buffer);
    }
}
"}}