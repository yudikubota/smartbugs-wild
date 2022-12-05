{"ABIResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract ABIResolver is ResolverBase {
    bytes4 constant private ABI_INTERFACE_ID = 0x2203ab56;

    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

    mapping(bytes32=>mapping(uint256=>bytes)) abis;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == ABI_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"Address.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
"},"AddrResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract AddrResolver is ResolverBase {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32=>mapping(uint=>bytes)) _addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddrCoinType(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddrCoinType(bytes32 node, uint coinType, bytes memory a) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"balanceable.sol":{"content":"/**
 *  Balanceable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./ERC20.sol";


/// @title Balanceable - This is a contract used to get a balance
contract Balanceable {
    /// @dev This function is used to get a balance
    /// @param _address of which balance we are trying to ascertain
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @return balance associated with an address, for any token, in the wei equivalent
    function _balance(address _address, address _asset) internal view returns (uint256) {
        if (_asset != address(0)) {
            return ERC20(_asset).balanceOf(_address);
        } else {
            return _address.balance;
        }
    }
}
"},"base64.sol":{"content":"pragma solidity ^0.5.15;

/**
 * This method was modified from the GPLv3 solidity code found in this repository
 * https://github.com/vcealicu/melonport-price-feed/blob/master/pricefeed/PriceFeed.sol
 */

/// @title Base64 provides base 64 decoding functionality.
contract Base64 {
    bytes constant BASE64_DECODE_CHAR = hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e003e003f3435363738393a3b3c3d00000000000000000102030405060708090a0b0c0d0e0f10111213141516171819000000003f001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f30313233";

    /// @return decoded array of bytes.
    /// @param _encoded base 64 encoded array of bytes.
    function _base64decode(bytes memory _encoded) internal pure returns (bytes memory) {
        byte v1;
        byte v2;
        byte v3;
        byte v4;
        uint length = _encoded.length;
        bytes memory result = new bytes(length);
        uint index;

        // base64 encoded strings can't be length 0 and they must be divisble by 4
        require(length > 0  && length % 4 == 0, "invalid base64 encoding");

        if (keccak256(abi.encodePacked(_encoded[length - 2])) == keccak256("=")) {
            length -= 2;
        } else if (keccak256(abi.encodePacked(_encoded[length - 1])) == keccak256("=")) {
            length -= 1;
        }

        uint count = length >> 2 << 2;
        uint i;

        for (i = 0; i < count;) {
            v1 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v2 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v3 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v4 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];

            result[index++] = (v1 << 2 | v2 >> 4) & 0xff;
            result[index++] = (v2 << 4 | v3 >> 2) & 0xff;
            result[index++] = (v3 << 6 | v4) & 0xff;
        }

        if (length - count == 2) {
            v1 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v2 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];

            result[index++] = (v1 << 2 | v2 >> 4) & 0xff;
        } else if (length - count == 3) {
            v1 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v2 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];
            v3 = BASE64_DECODE_CHAR[uint8(_encoded[i++])];

            result[index++] = (v1 << 2 | v2 >> 4) & 0xff;
            result[index++] = (v2 << 4 | v3 >> 2) & 0xff;
        }

        // Set to correct length.
        assembly {
            mstore(result, index)
        }

        return result;
    }
}
"},"base64Exporter.sol":{"content":"pragma solidity ^0.5.17;

import "./base64.sol";


contract Base64Exporter is Base64 {
    /// @dev export _base64decode() as an external function.
    function base64decode(bytes calldata _encoded) external pure returns (bytes memory) {
        return _base64decode(_encoded);
    }
}
"},"burner.sol":{"content":"/**
 *  IBurner - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;


// The BurnerToken interface is the interface to a token contract which
// provides the total burnable supply for the TokenHolder contract.
interface IBurner {
    function currentSupply() external view returns (uint256);
}
"},"burnerToken.sol":{"content":"pragma solidity ^0.5.17;

import "./SafeMath.sol";


interface TokenHolder {
    function burn(address, uint256) external returns (bool);
}


contract BurnerToken {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public currentSupply;

    address public owner;
    string public name;
    uint8 public decimals;
    string public symbol;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //Holds accumulated dividend tokens other than TKN
    TokenHolder public tokenholder;

    constructor() public {
        owner = msg.sender;
        name = "Monolith TKN";
        decimals = 8;
        symbol = "TKN";
    }

    function totalSupply() external view returns (uint256) {
        return currentSupply;
    }

    function mint(address addr, uint256 amount) external {
        balanceOf[addr] = balanceOf[addr].add(amount);
        currentSupply = currentSupply.add(amount);
        emit Transfer(address(0), addr, amount);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        if (balanceOf[msg.sender] < _value) return false;
        if (_to == address(0)) return false;

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (_to == address(0)) return false;
        if (balanceOf[_from] < _value) return false;

        uint256 allowed = allowance[_from][msg.sender];
        if (allowed < _value) return false; //PROBLEM!
        /* require(_value <= allowed, "amount exceeds allowance"); */

        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowed.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) external returns (bool success) {
        uint256 oldValue = allowance[msg.sender][_spender];
        allowance[msg.sender][_spender] = oldValue.add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) external returns (bool success) {
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function setTokenHolder(address _th) external {
        tokenholder = TokenHolder(_th);
    }

    function burn(uint256 _amount) public returns (bool result) {
        if (_amount > balanceOf[msg.sender]) return false;

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        currentSupply = currentSupply.sub(_amount);
        result = tokenholder.burn(msg.sender, _amount);
        if (!result) revert();
        emit Transfer(msg.sender, address(0), _amount);
    }
}
"},"bytesUtils.sol":{"content":"/**
 *  BytesUtils - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./SafeMath.sol";


/// @title BytesUtils provides basic byte slicing and casting functionality.
library BytesUtils {
    using SafeMath for uint256;

    /// @dev This function converts to an address
    /// @param _bts bytes
    /// @param _from start position
    function _bytesToAddress(bytes memory _bts, uint256 _from) internal pure returns (address) {
        require(_bts.length >= _from.add(20), "slicing out of range");

        bytes20 convertedAddress;
        uint256 startByte = _from.add(32); //first 32 bytes denote the array length

        assembly {
            convertedAddress := mload(add(_bts, startByte))
        }

        return address(convertedAddress);
    }

    /// @dev This function slices bytes into bytes4
    /// @param _bts some bytes
    /// @param _from start position
    function _bytesToBytes4(bytes memory _bts, uint256 _from) internal pure returns (bytes4) {
        require(_bts.length >= _from.add(4), "slicing out of range");

        bytes4 slicedBytes4;
        uint256 startByte = _from.add(32); //first 32 bytes denote the array length

        assembly {
            slicedBytes4 := mload(add(_bts, startByte))
        }

        return slicedBytes4;
    }

    /// @dev This function slices a uint
    /// @param _bts some bytes
    /// @param _from start position
    // credit to https://ethereum.stackexchange.com/questions/51229/how-to-convert-bytes-to-uint-in-solidity
    // and Nick Johnson https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity/4177#4177
    function _bytesToUint256(bytes memory _bts, uint256 _from) internal pure returns (uint256) {
        require(_bts.length >= _from.add(32), "slicing out of range");

        uint256 convertedUint256;
        uint256 startByte = _from.add(32); //first 32 bytes denote the array length

        assembly {
            convertedUint256 := mload(add(_bts, startByte))
        }

        return convertedUint256;
    }
}
"},"bytesUtilsExporter.sol":{"content":"pragma solidity ^0.5.17;

import "./bytesUtils.sol";


contract BytesUtilsExporter {
    using BytesUtils for bytes;

    /// @dev export _bytesToAddress() as an external function.
    function bytesToAddress(bytes calldata _bts, uint256 _from) external pure returns (address) {
        return _bts._bytesToAddress(_from);
    }

    /// @dev export _bytesToBytes4() as an external function.
    function bytesToBytes4(bytes calldata _bts, uint256 _from) external pure returns (bytes4) {
        return _bts._bytesToBytes4(_from);
    }

    /// @dev export _bytesToUint256() as an external function.
    function bytesToUint256(bytes calldata _bts, uint256 _from) external pure returns (uint256) {
        return _bts._bytesToUint256(_from);
    }
}
"},"ContentHashResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract ContentHashResolver is ResolverBase {
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    event ContenthashChanged(bytes32 indexed node, bytes hash);

    mapping(bytes32=>bytes) hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == CONTENT_HASH_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"controllable.sol":{"content":"/**
 *  Controllable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./controller.sol";
import "./ensResolvable.sol";


/// @title Controllable implements access control functionality of the Controller found via ENS.
contract Controllable is ENSResolvable {
    // Default values for mainnet ENS
    // controller.tokencard.eth
    bytes32 private constant _DEFAULT_CONTROLLER_NODE = 0x7f2ce995617d2816b426c5c8698c5ec2952f7a34bb10f38326f74933d5893697;

    /// @dev Is the registered ENS node identifying the controller contract.
    bytes32 private _controllerNode = _DEFAULT_CONTROLLER_NODE;

    /// @notice Constructor initializes the controller contract object.
    /// @param _controllerNode_ is the ENS node of the Controller.
    /// @dev pass in bytes32(0) to use the default, production node labels for ENS
    constructor(bytes32 _controllerNode_) internal {
        // Set controllerNode or use default
        if (_controllerNode_ != bytes32(0)) {
            _controllerNode = _controllerNode_;
        }
    }

    /// @notice Checks if message sender is a controller.
    modifier onlyController() {
        require(_isController(msg.sender), "sender is not a controller");
        _;
    }

    /// @notice Checks if message sender is an admin.
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "sender is not an admin");
        _;
    }

    /// @return the controller node registered in ENS.
    function controllerNode() public view returns (bytes32) {
        return _controllerNode;
    }

    /// @return true if the provided account is a controller.
    function _isController(address _account) internal view returns (bool) {
        return IController(_ensResolve(_controllerNode)).isController(_account);
    }

    /// @return true if the provided account is an admin.
    function _isAdmin(address _account) internal view returns (bool) {
        return IController(_ensResolve(_controllerNode)).isAdmin(_account);
    }
}
"},"controller.sol":{"content":"/**
 *  Controller - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./ownable.sol";
import "./transferrable.sol";


/// @title The IController interface provides access to the isController and isAdmin checks.
interface IController {
    function isController(address) external view returns (bool);

    function isAdmin(address) external view returns (bool);
}


/// @title Controller stores a list of controller addresses that can be used for authentication in other contracts.
/// @notice The Controller implements a hierarchy of concepts, Owner, Admin, and the Controllers.
/// @dev Owner can change the Admins
/// @dev Admins and can the Controllers
/// @dev Controllers are used by the application.
contract Controller is IController, Ownable, Transferrable {
    event AddedController(address _sender, address _controller);
    event RemovedController(address _sender, address _controller);

    event AddedAdmin(address _sender, address _admin);
    event RemovedAdmin(address _sender, address _admin);

    event Claimed(address _to, address _asset, uint256 _amount);

    event Stopped(address _sender);
    event Started(address _sender);

    mapping(address => bool) private _isAdmin;
    uint256 private _adminCount;

    mapping(address => bool) private _isController;
    uint256 private _controllerCount;

    bool private _stopped;

    /// @notice Constructor initializes the owner with the provided address.
    /// @param _ownerAddress_ address of the owner.
    constructor(address payable _ownerAddress_) public Ownable(_ownerAddress_, false) {}

    /// @notice Checks if message sender is an admin.
    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "sender is not an admin");
        _;
    }

    /// @notice Check if Owner or Admin
    modifier onlyAdminOrOwner() {
        require(_isOwner(msg.sender) || _isAdmin[msg.sender], "sender is not an admin");
        _;
    }

    /// @notice Check if controller is stopped
    modifier notStopped() {
        require(!isStopped(), "controller is stopped");
        _;
    }

    /// @notice Add a new admin to the list of admins.
    /// @param _account address to add to the list of admins.
    function addAdmin(address _account) external onlyOwner notStopped {
        _addAdmin(_account);
    }

    /// @notice Remove a admin from the list of admins.
    /// @param _account address to remove from the list of admins.
    function removeAdmin(address _account) external onlyOwner {
        _removeAdmin(_account);
    }

    /// @return the current number of admins.
    function adminCount() external view returns (uint256) {
        return _adminCount;
    }

    /// @notice Add a new controller to the list of controllers.
    /// @param _account address to add to the list of controllers.
    function addController(address _account) external onlyAdminOrOwner notStopped {
        _addController(_account);
    }

    /// @notice Remove a controller from the list of controllers.
    /// @param _account address to remove from the list of controllers.
    function removeController(address _account) external onlyAdminOrOwner {
        _removeController(_account);
    }

    /// @notice count the Controllers
    /// @return the current number of controllers.
    function controllerCount() external view returns (uint256) {
        return _controllerCount;
    }

    /// @notice is an address an Admin?
    /// @return true if the provided account is an admin.
    function isAdmin(address _account) external view notStopped returns (bool) {
        return _isAdmin[_account];
    }

    /// @notice is an address a Controller?
    /// @return true if the provided account is a controller.
    function isController(address _account) external view notStopped returns (bool) {
        return _isController[_account];
    }

    /// @notice this function can be used to see if the controller has been stopped
    /// @return true is the Controller has been stopped
    function isStopped() public view returns (bool) {
        return _stopped;
    }

    /// @notice Internal-only function that adds a new admin.
    function _addAdmin(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isAdmin[_account] = true;
        _adminCount++;
        emit AddedAdmin(msg.sender, _account);
    }

    /// @notice Internal-only function that removes an existing admin.
    function _removeAdmin(address _account) private {
        require(_isAdmin[_account], "provided account is not an admin");
        _isAdmin[_account] = false;
        _adminCount--;
        emit RemovedAdmin(msg.sender, _account);
    }

    /// @notice Internal-only function that adds a new controller.
    function _addController(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isController[_account] = true;
        _controllerCount++;
        emit AddedController(msg.sender, _account);
    }

    /// @notice Internal-only function that removes an existing controller.
    function _removeController(address _account) private {
        require(_isController[_account], "provided account is not a controller");
        _isController[_account] = false;
        _controllerCount--;
        emit RemovedController(msg.sender, _account);
    }

    /// @notice stop our controllers and admins from being useable
    function stop() external onlyAdminOrOwner {
        _stopped = true;
        emit Stopped(msg.sender);
    }

    /// @notice start our controller again
    function start() external onlyOwner {
        _stopped = false;
        emit Started(msg.sender);
    }

    //// @notice Withdraw tokens from the smart contract to the specified account.
    function claim(address payable _to, address _asset, uint256 _amount) external onlyAdmin notStopped {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }
}
"},"date.sol":{"content":"/**
 *  Date - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;


/// @title Date provides redimentary date parsing functionality.
/// @notice This method parses months found in an ISO date to a number
contract Date {
    bytes32 private constant _JANUARY = keccak256("Jan");
    bytes32 private constant _FEBRUARY = keccak256("Feb");
    bytes32 private constant _MARCH = keccak256("Mar");
    bytes32 private constant _APRIL = keccak256("Apr");
    bytes32 private constant _MAY = keccak256("May");
    bytes32 private constant _JUNE = keccak256("Jun");
    bytes32 private constant _JULY = keccak256("Jul");
    bytes32 private constant _AUGUST = keccak256("Aug");
    bytes32 private constant _SEPTEMBER = keccak256("Sep");
    bytes32 private constant _OCTOBER = keccak256("Oct");
    bytes32 private constant _NOVEMBER = keccak256("Nov");
    bytes32 private constant _DECEMBER = keccak256("Dec");

    /// @return the number of the month based on its name.
    /// @param _month the first three letters of a month's name e.g. "Jan".
    function _monthToNumber(string memory _month) internal pure returns (uint8) {
        bytes32 month = keccak256(abi.encodePacked(_month));
        if (month == _JANUARY) {
            return 1;
        } else if (month == _FEBRUARY) {
            return 2;
        } else if (month == _MARCH) {
            return 3;
        } else if (month == _APRIL) {
            return 4;
        } else if (month == _MAY) {
            return 5;
        } else if (month == _JUNE) {
            return 6;
        } else if (month == _JULY) {
            return 7;
        } else if (month == _AUGUST) {
            return 8;
        } else if (month == _SEPTEMBER) {
            return 9;
        } else if (month == _OCTOBER) {
            return 10;
        } else if (month == _NOVEMBER) {
            return 11;
        } else if (month == _DECEMBER) {
            return 12;
        } else {
            revert("not a valid month");
        }
    }
}
"},"DNSResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";
import "./RRUtils.sol";

contract DNSResolver is ResolverBase {
    using RRUtils for *;
    using ENSBytesUtils for bytes;

    bytes4 constant private DNS_RECORD_INTERFACE_ID = 0xa8fa5682;
    bytes4 constant private DNS_ZONE_INTERFACE_ID = 0x5c47637c;

    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    // Zone hashes for the domains.
    // A zone hash is an EIP-1577 content hash in binary format that should point to a
    // resource containing a single zonefile.
    // node => contenthash
    mapping(bytes32=>bytes) private zonehashes;

    // Version the mapping for each zone.  This allows users who have lost
    // track of their entries to effectively delete an entire zone by bumping
    // the version number.
    // node => version
    mapping(bytes32=>uint256) private versions;

    // The records themselves.  Stored as binary RRSETs
    // node => version => name => resource => data
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>mapping(uint16=>bytes)))) private records;

    // Count of number of entries for a given name.  Required for DNS resolvers
    // when resolving wildcards.
    // node => version => name => number of records
    mapping(bytes32=>mapping(uint256=>mapping(bytes32=>uint16))) private nameEntriesCount;

    /**
     * Set one or more DNS records.  Records are supplied in wire-format.
     * Records with the same node/name/resource must be supplied one after the
     * other to ensure the data is updated correctly. For example, if the data
     * was supplied:
     *     a.example.com IN A 1.2.3.4
     *     a.example.com IN A 5.6.7.8
     *     www.example.com IN CNAME a.example.com.
     * then this would store the two A records for a.example.com correctly as a
     * single RRSET, however if the data was supplied:
     *     a.example.com IN A 1.2.3.4
     *     www.example.com IN CNAME a.example.com.
     *     a.example.com IN A 5.6.7.8
     * then this would store the first A record, the CNAME, then the second A
     * record which would overwrite the first.
     *
     * @param node the namehash of the node for which to set the records
     * @param data the DNS wire format records to set
     */
    function setDNSRecords(bytes32 node, bytes calldata data) external authorised(node) {
        uint16 resource = 0;
        uint256 offset = 0;
        bytes memory name;
        bytes memory value;
        bytes32 nameHash;
        // Iterate over the data to add the resource records
        for (RRUtils.RRIterator memory iter = data.iterateRRs(0); !iter.done(); iter.next()) {
            if (resource == 0) {
                resource = iter.dnstype;
                name = iter.name();
                nameHash = keccak256(abi.encodePacked(name));
                value = bytes(iter.rdata());
            } else {
                bytes memory newName = iter.name();
                if (resource != iter.dnstype || !name.equals(newName)) {
                    setDNSRRSet(node, name, resource, data, offset, iter.offset - offset, value.length == 0);
                    resource = iter.dnstype;
                    offset = iter.offset;
                    name = newName;
                    nameHash = keccak256(name);
                    value = bytes(iter.rdata());
                }
            }
        }
        if (name.length > 0) {
            setDNSRRSet(node, name, resource, data, offset, data.length - offset, value.length == 0);
        }
    }

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) public view returns (bytes memory) {
        return records[node][versions[node]][name][resource];
    }

    /**
     * Check if a given node has records.
     * @param node the namehash of the node for which to check the records
     * @param name the namehash of the node for which to check the records
     */
    function hasDNSRecords(bytes32 node, bytes32 name) public view returns (bool) {
        return (nameEntriesCount[node][versions[node]][name] != 0);
    }

    /**
     * Clear all information for a DNS zone.
     * @param node the namehash of the node for which to clear the zone
     */
    function clearDNSZone(bytes32 node) public authorised(node) {
        versions[node]++;
        emit DNSZoneCleared(node);
    }

    /**
     * setZonehash sets the hash for the zone.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The zonehash to set
     */
    function setZonehash(bytes32 node, bytes calldata hash) external authorised(node) {
        bytes memory oldhash = zonehashes[node];
        zonehashes[node] = hash;
        emit DNSZonehashChanged(node, oldhash, hash);
    }

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory) {
        return zonehashes[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == DNS_RECORD_INTERFACE_ID ||
               interfaceID == DNS_ZONE_INTERFACE_ID ||
               super.supportsInterface(interfaceID);
    }

    function setDNSRRSet(
        bytes32 node,
        bytes memory name,
        uint16 resource,
        bytes memory data,
        uint256 offset,
        uint256 size,
        bool deleteRecord) private
    {
        uint256 version = versions[node];
        bytes32 nameHash = keccak256(name);
        bytes memory rrData = data.substring(offset, size);
        if (deleteRecord) {
            if (records[node][version][nameHash][resource].length != 0) {
                nameEntriesCount[node][version][nameHash]--;
            }
            delete(records[node][version][nameHash][resource]);
            emit DNSRecordDeleted(node, name, resource);
        } else {
            if (records[node][version][nameHash][resource].length == 0) {
                nameEntriesCount[node][version][nameHash]++;
            }
            records[node][version][nameHash][resource] = rrData;
            emit DNSRecordChanged(node, name, resource, rrData);
        }
    }
}
"},"ECDSA.sol":{"content":"/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n Ã· 2 + 1, and for v in (282): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
"},"ENS.sol":{"content":"/**
 * BSD 2-Clause License
 *
 * Copyright (c) 2018, True Names Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
pragma solidity ^0.5.0;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed _node, address _owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed _node, address _resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed _node, uint64 _ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setRecord(bytes32 _node, address _owner, address _resolver, uint64 _ttl) external;
    function setSubnodeRecord(bytes32 _node, bytes32 _label, address _owner, address _resolver, uint64 _ttl) external;
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) external returns(bytes32);
    function setResolver(bytes32 _node, address _resolver) external;
    function setOwner(bytes32 _node, address _owner) external;
    function setTTL(bytes32 _node, uint64 _ttl) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function owner(bytes32 _node) external view returns (address);
    function resolver(bytes32 _node) external view returns (address);
    function ttl(bytes32 _node) external view returns (uint64);
    function recordExists(bytes32 _node) external view returns (bool);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
"},"ENSBytesUtils.sol":{"content":"pragma solidity >0.4.23;

library ENSBytesUtils {
    /*
    * @dev Returns the keccak-256 hash of a byte range.
    * @param self The byte string to hash.
    * @param offset The position to start hashing at.
    * @param len The number of bytes to hash.
    * @return The hash of the byte range.
    */
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal.
    * @param self The first bytes to compare.
    * @param other The second bytes to compare.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, bytes memory other) internal pure returns (int) {
        return compare(self, 0, self.length, other, 0, other.length);
    }

    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal. Comparison is done per-rune,
    *      on unicode codepoints.
    * @param self The first bytes to compare.
    * @param offset The offset of self.
    * @param len    The length of self.
    * @param other The second bytes to compare.
    * @param otheroffset The offset of the other string.
    * @param otherlen    The length of the other string.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, uint offset, uint len, bytes memory other, uint otheroffset, uint otherlen) internal pure returns (int) {
        uint shortest = len;
        if (otherlen < len)
        shortest = otherlen;

        uint selfptr;
        uint otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask;
                if (shortest > 32) {
                    mask = uint256(- 1); // aka 0xffffff....
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint diff = (a & mask) - (b & mask);
                if (diff != 0)
                return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int(len) - int(otherlen);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @param len The number of bytes to compare
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset, uint len) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

    /*
    * @dev Returns true if the two byte ranges are equal with offsets.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset) internal pure returns (bool) {
        return keccak(self, offset, self.length - offset) == keccak(other, otherOffset, other.length - otherOffset);
    }

    /*
    * @dev Compares a range of 'self' to all of 'other' and returns True iff
    *      they are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other) internal pure returns (bool) {
        return self.length >= offset + other.length && equals(self, offset, other, 0, other.length);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, bytes memory other) internal pure returns(bool) {
        return self.length == other.length && equals(self, 0, other, 0, self.length);
    }

    /*
    * @dev Returns the 8-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 8 bits of the string, interpreted as an integer.
    */
    function readUint8(bytes memory self, uint idx) internal pure returns (uint8 ret) {
        return uint8(self[idx]);
    }

    /*
    * @dev Returns the 16-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 16 bits of the string, interpreted as an integer.
    */
    function readUint16(bytes memory self, uint idx) internal pure returns (uint16 ret) {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

    /*
    * @dev Returns the 32-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bits of the string, interpreted as an integer.
    */
    function readUint32(bytes memory self, uint idx) internal pure returns (uint32 ret) {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

    /*
    * @dev Returns the n byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes.
    * @param len The number of bytes.
    * @return The specified 32 bytes of the string.
    */
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
    * @dev Copies a substring into a new byte string.
    * @param self The byte string to copy from.
    * @param offset The offset to start copying at.
    * @param len The number of bytes to copy.
    */
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    // Maps characters from 0x30 to 0x7A to their base32 values.
    // 0xFF represents invalid characters in that range.
    bytes constant base32HexTable = hex'00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F';

    /**
     * @dev Decodes unpadded base32 data of up to one word in length.
     * @param self The data to decode.
     * @param off Offset into the string to start at.
     * @param len Number of characters to decode.
     * @return The decoded data, left aligned.
     */
    function base32HexDecodeWord(bytes memory self, uint off, uint len) internal pure returns(bytes32) {
        require(len <= 52);

        uint ret = 0;
        uint8 decoded;
        for(uint i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint(uint8(char)) - 0x30]);
            require(decoded <= 0x20);
            if(i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint bitlen = len * 5;
        if(len % 8 == 0) {
            // Multiple of 8 characters, no padding
            ret = (ret << 5) | decoded;
        } else if(len % 8 == 2) {
            // Two extra characters - 1 byte
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if(len % 8 == 4) {
            // Four extra characters - 2 bytes
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if(len % 8 == 5) {
            // Five extra characters - 3 bytes
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if(len % 8 == 7) {
            // Seven extra characters - 4 bytes
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }
}
"},"ENSRegistry.sol":{"content":"pragma solidity ^0.5.0;

import "./ENS.sol";

/**
 * The ENS registry contract.
 */
contract ENSRegistry is ENS {

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping (bytes32 => Record) records;
    mapping (address => mapping(address => bool)) operators;

    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 _node) {
        address owner = records[_node].owner;
        require(owner == msg.sender || operators[owner][msg.sender]);
        _;
    }

    /**
     * @dev Constructs a new ENS registrar.
     */
    constructor() public {
        records[0x0].owner = msg.sender;
    }

    /**
     * @dev Sets the record for a node.
     * @param _node The node to update.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the resolver.
     * @param _ttl The TTL in seconds.
     */
    function setRecord(bytes32 _node, address _owner, address _resolver, uint64 _ttl) external {
        setOwner(_node, _owner);
        _setResolverAndTTL(_node, _resolver, _ttl);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param _node The parent node.
     * @param _label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the resolver.
     * @param _ttl The TTL in seconds.
     */
    function setSubnodeRecord(bytes32 _node, bytes32 _label, address _owner, address _resolver, uint64 _ttl) external {
        bytes32 subnode = setSubnodeOwner(_node, _label, _owner);
        _setResolverAndTTL(subnode, _resolver, _ttl);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param _node The node to transfer ownership of.
     * @param _owner The address of the new owner.
     */
    function setOwner(bytes32 _node, address _owner) public authorised(_node) {
        _setOwner(_node, _owner);
        emit Transfer(_node, _owner);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param _node The parent node.
     * @param _label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) public authorised(_node) returns(bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(_node, _label));
        _setOwner(subnode, _owner);
        emit NewOwner(_node, _label, _owner);
        return subnode;
    }

    /**
     * @dev Sets the resolver address for the specified node.
     * @param _node The node to update.
     * @param _resolver The address of the resolver.
     */
    function setResolver(bytes32 _node, address _resolver) public authorised(_node) {
        emit NewResolver(_node, _resolver);
        records[_node].resolver = _resolver;
    }

    /**
     * @dev Sets the TTL for the specified node.
     * @param _node The node to update.
     * @param _ttl The TTL in seconds.
     */
    function setTTL(bytes32 _node, uint64 _ttl) public authorised(_node) {
        emit NewTTL(_node, _ttl);
        records[_node].ttl = _ttl;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param _node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 _node) public view returns (address) {
        address addr = records[_node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param _node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 _node) public view returns (address) {
        return records[_node].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param _node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 _node) public view returns (uint64) {
        return records[_node].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param _node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 _node) public view returns (bool) {
        return records[_node].owner != address(0x0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param _owner The address that owns the records.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }

    function _setOwner(bytes32 _node, address _owner) internal {
        records[_node].owner = _owner;
    }

    function _setResolverAndTTL(bytes32 _node, address _resolver, uint64 _ttl) internal {
        if(_resolver != records[_node].resolver) {
            records[_node].resolver = _resolver;
            emit NewResolver(_node, _resolver);
        }

        if(_ttl != records[_node].ttl) {
            records[_node].ttl = _ttl;
            emit NewTTL(_node, _ttl);
        }
    }
}
"},"ensResolvable.sol":{"content":"/**
 *  ENSResolvable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./ENS.sol";
import "./PublicResolver.sol";


///@title ENSResolvable - Ethereum Name Service Resolver
///@notice contract should be used to get an address for an ENS node
contract ENSResolvable {
    /// @notice _ensRegistry points to the ENS registry smart contract.
    address private _ensRegistry;

    /// @param _ensReg_ is the ENS registry used
    constructor(address _ensReg_) internal {
        _ensRegistry = _ensReg_;
    }

    /// @notice this is used to that one can observe which ENS registry is being used
    function ensRegistry() external view returns (address) {
        return _ensRegistry;
    }

    /// @notice helper function used to get the address of a node
    /// @param _node of the ENS entry that needs resolving
    /// @return the address of the said node
    function _ensResolve(bytes32 _node) internal view returns (address) {
        return PublicResolver(ENS(_ensRegistry).resolver(_node)).addr(_node);
    }
}
"},"ERC165.sol":{"content":"pragma solidity ^0.5.15;

/// @title ERC165 interface specifies a standard way of querying if a contract implements an interface.
interface ERC165 {
    function supportsInterface(bytes4) external view returns (bool);
}
"},"ERC20.sol":{"content":"pragma solidity ^0.5.15;

/// @title ERC20 interface is a subset of the ERC20 specification.
/// @notice see https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address _who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}
"},"holder.sol":{"content":"/**
 *  Holder (aka Asset Contract) - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./transferrable.sol";
import "./balanceable.sol";
import "./burner.sol";
import "./controllable.sol";
import "./tokenWhitelistable.sol";


/// @title Holder - The TKN Asset Contract
/// @notice When the TKN contract calls the burn method, a share of the tokens held by this contract are disbursed to the burner.
contract Holder is Balanceable, ENSResolvable, Controllable, Transferrable, TokenWhitelistable {
    using SafeMath for uint256;

    event Received(address _from, uint256 _amount);
    event CashAndBurned(address _to, address _asset, uint256 _amount);
    event Claimed(address _to, address _asset, uint256 _amount);

    /// @dev Check if the sender is the burner contract
    modifier onlyBurner() {
        require(msg.sender == _burner, "burner contract is not the sender");
        _;
    }

    // Burner token which can be burned to redeem shares.
    address private _burner;

    /// @notice Constructor initializes the holder contract.
    /// @param _burnerContract_ is the address of the token contract TKN with burning functionality.
    /// @param _ens_ is the address of the ENS registry.
    /// @param _tokenWhitelistNode_ is the ENS node of the Token whitelist.
    /// @param _controllerNode_ is the ENS node of the Controller
    constructor(address _burnerContract_, address _ens_, bytes32 _tokenWhitelistNode_, bytes32 _controllerNode_)
        public
        ENSResolvable(_ens_)
        Controllable(_controllerNode_)
        TokenWhitelistable(_tokenWhitelistNode_)
    {
        _burner = _burnerContract_;
    }

    /// @notice Ether may be sent from anywhere.
    function() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Burn handles disbursing a share of tokens in this contract to a given address.
    /// @param _to The address to disburse to
    /// @param _amount The amount of TKN that will be burned if this succeeds
    function burn(address payable _to, uint256 _amount) external onlyBurner returns (bool) {
        if (_amount == 0) {
            return true;
        }
        // The burner token deducts from the supply before calling.
        uint256 supply = IBurner(_burner).currentSupply().add(_amount);
        address[] memory redeemableAddresses = _redeemableTokens();
        for (uint256 i = 0; i < redeemableAddresses.length; i++) {
            uint256 redeemableBalance = _balance(address(this), redeemableAddresses[i]);
            if (redeemableBalance > 0) {
                uint256 redeemableAmount = redeemableBalance.mul(_amount).div(supply);
                _safeTransfer(_to, redeemableAddresses[i], redeemableAmount);
                emit CashAndBurned(_to, redeemableAddresses[i], redeemableAmount);
            }
        }

        return true;
    }

    /// @notice This allows for the admin to reclaim the non-redeemableTokens.
    /// @param _to this is the address which the reclaimed tokens will be sent to.
    /// @param _nonRedeemableAddresses this is the array of tokens to be claimed.
    function nonRedeemableTokenClaim(address payable _to, address[] calldata _nonRedeemableAddresses) external onlyAdmin returns (bool) {
        for (uint256 i = 0; i < _nonRedeemableAddresses.length; i++) {
            //revert if token is redeemable
            require(!_isTokenRedeemable(_nonRedeemableAddresses[i]), "redeemables cannot be claimed");
            uint256 claimBalance = _balance(address(this), _nonRedeemableAddresses[i]);
            if (claimBalance > 0) {
                _safeTransfer(_to, _nonRedeemableAddresses[i], claimBalance);
                emit Claimed(_to, _nonRedeemableAddresses[i], claimBalance);
            }
        }

        return true;
    }

    /// @notice Returned the address of the burner contract.
    /// @return the TKN address.
    function burner() external view returns (address) {
        return _burner;
    }
}
"},"InterfaceResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";
import "./AddrResolver.sol";

contract InterfaceResolver is ResolverBase, AddrResolver {
    bytes4 constant private INTERFACE_INTERFACE_ID = bytes4(keccak256("interfaceImplementer(bytes32,bytes4)"));
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    mapping(bytes32=>mapping(bytes4=>address)) interfaces;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 168 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP168 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 168 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if(a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", INTERFACE_META_ID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 168 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == INTERFACE_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"isValidSignatureExporter.sol":{"content":"pragma solidity ^0.5.17;

import "./wallet.sol";


interface IWallet {
    function isValidSignature(bytes calldata, bytes calldata) external view returns (bytes4);
}


contract IsValidSignatureExporter {
    address walletAddress;

    constructor(address _wallet) public {
        walletAddress = _wallet;
    }

    /// @dev exports isValidSignature(bytes,bytes) aka EIP-1271, so it can tested (no overloading in Go)
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4) {
        return IWallet(walletAddress).isValidSignature(_data, _signature);
    }
}
"},"licence.sol":{"content":"/**
 *  Licence - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./controllable.sol";
import "./ensResolvable.sol";
import "./transferrable.sol";


/// @title ILicence interface describes methods for loading a TokenCard and updating licence amount.
interface ILicence {
    function load(address, uint256) external payable;

    function updateLicenceAmount(uint256) external;
}


/// @title Licence loads the TokenCard and transfers the licence amout to the TKN Holder Contract.
/// @notice the rest of the amount gets sent to the CryptoFloat
contract Licence is Transferrable, ENSResolvable, Controllable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /*******************/
    /*     Events     */
    /*****************/

    event UpdatedLicenceDAO(address _newDAO);
    event UpdatedCryptoFloat(address _newFloat);
    event UpdatedTokenHolder(address _newHolder);
    event UpdatedTKNContractAddress(address _newTKN);
    event UpdatedLicenceAmount(uint256 _newAmount);

    event TransferredToTokenHolder(address _from, address _to, address _asset, uint256 _amount);
    event TransferredToCryptoFloat(address _from, address _to, address _asset, uint256 _amount);

    event Claimed(address _to, address _asset, uint256 _amount);

    /// @notice This is 100% scaled up by a factor of 10 to give us an extra 1 decimal place of precision
    uint256 public constant MAX_AMOUNT_SCALE = 1000;
    uint256 public constant MIN_AMOUNT_SCALE = 1;

    address private _tknContractAddress = 0xaAAf91D9b90dF800Df4F55c205fd6989c977E73a; // solium-disable-line uppercase

    address payable private _cryptoFloat;
    address payable private _tokenHolder;
    address private _licenceDAO;

    bool private _lockedCryptoFloat;
    bool private _lockedTokenHolder;
    bool private _lockedLicenceDAO;
    bool private _lockedTKNContractAddress;

    /// @notice This is the _licenceAmountScaled by a factor of 10
    /// @dev i.e. 1% is 10 _licenceAmountScaled, 0.1% is 1 _licenceAmountScaled
    uint256 private _licenceAmountScaled;

    /// @notice Reverts if called by any address other than the DAO contract.
    modifier onlyDAO() {
        require(msg.sender == _licenceDAO, "the sender isn't the DAO");
        _;
    }

    /// @notice Constructor initializes the card licence contract.
    /// @param _licence_ is the initial card licence amount. this number is scaled 10 = 1%, 9 = 0.9%
    /// @param _float_ is the address of the multi-sig cryptocurrency float contract.
    /// @param _holder_ is the address of the token holder contract
    /// @param _tknAddress_ is the address of the TKN ERC20 contract
    /// @param _ens_ is the address of the ENS Registry
    /// @param _controllerNode_ is the ENS node corresponding to the controller
    constructor(uint256 _licence_, address payable _float_, address payable _holder_, address _tknAddress_, address _ens_, bytes32 _controllerNode_)
        public
        ENSResolvable(_ens_)
        Controllable(_controllerNode_)
    {
        require(MIN_AMOUNT_SCALE <= _licence_ && _licence_ <= MAX_AMOUNT_SCALE, "licence amount out of range");
        _licenceAmountScaled = _licence_;
        _cryptoFloat = _float_;
        _tokenHolder = _holder_;
        if (_tknAddress_ != address(0)) {
            _tknContractAddress = _tknAddress_;
        }
    }

    /// @notice Ether can be deposited from any source, so this contract should be payable by anyone.
    function() external payable {}

    /// @notice this allows for people to see the scaled licence amount
    /// @return the scaled licence amount, used to calculate the split when loading.
    function licenceAmountScaled() external view returns (uint256) {
        return _licenceAmountScaled;
    }

    /// @notice allows one to see the address of the CryptoFloat
    /// @return the address of the multi-sig cryptocurrency float contract.
    function cryptoFloat() external view returns (address) {
        return _cryptoFloat;
    }

    /// @notice allows one to see the address TKN holder contract
    /// @return the address of the token holder contract.
    function tokenHolder() external view returns (address) {
        return _tokenHolder;
    }

    /// @notice allows one to see the address of the DAO
    /// @return the address of the DAO contract.
    function licenceDAO() external view returns (address) {
        return _licenceDAO;
    }

    /// @notice The address of the TKN token
    /// @return the address of the TKN contract.
    function tknContractAddress() external view returns (address) {
        return _tknContractAddress;
    }

    /// @notice This locks the cryptoFloat address
    /// @dev so that it can no longer be updated
    function lockFloat() external onlyAdmin {
        _lockedCryptoFloat = true;
    }

    /// @notice This locks the TokenHolder address
    /// @dev so that it can no longer be updated
    function lockHolder() external onlyAdmin {
        _lockedTokenHolder = true;
    }

    /// @notice This locks the DAO address
    /// @dev so that it can no longer be updated
    function lockLicenceDAO() external onlyAdmin {
        _lockedLicenceDAO = true;
    }

    /// @notice This locks the TKN address
    /// @dev so that it can no longer be updated
    function lockTKNContractAddress() external onlyAdmin {
        _lockedTKNContractAddress = true;
    }

    /// @notice Updates the address of the cyptoFloat.
    /// @param _newFloat This is the new address for the CryptoFloat
    function updateFloat(address payable _newFloat) external onlyAdmin {
        require(!floatLocked(), "float is locked");
        _cryptoFloat = _newFloat;
        emit UpdatedCryptoFloat(_newFloat);
    }

    /// @notice Updates the address of the Holder contract.
    /// @param _newHolder This is the new address for the TokenHolder
    function updateHolder(address payable _newHolder) external onlyAdmin {
        require(!holderLocked(), "holder contract is locked");
        _tokenHolder = _newHolder;
        emit UpdatedTokenHolder(_newHolder);
    }

    /// @notice Updates the address of the DAO contract.
    /// @param _newDAO This is the new address for the Licence DAO
    function updateLicenceDAO(address _newDAO) external onlyAdmin {
        require(!licenceDAOLocked(), "DAO is locked");
        _licenceDAO = _newDAO;
        emit UpdatedLicenceDAO(_newDAO);
    }

    /// @notice Updates the address of the TKN contract.
    /// @param _newTKN This is the new address for the TKN contract
    function updateTKNContractAddress(address _newTKN) external onlyAdmin {
        require(!tknContractAddressLocked(), "TKN is locked");
        _tknContractAddress = _newTKN;
        emit UpdatedTKNContractAddress(_newTKN);
    }

    /// @notice Updates the TKN licence amount
    /// @param _newAmount is a number between MIN_AMOUNT_SCALE (1) and MAX_AMOUNT_SCALE
    function updateLicenceAmount(uint256 _newAmount) external onlyDAO {
        require(MIN_AMOUNT_SCALE <= _newAmount && _newAmount <= MAX_AMOUNT_SCALE, "licence amount out of range");
        _licenceAmountScaled = _newAmount;
        emit UpdatedLicenceAmount(_newAmount);
    }

    /// @notice Load the holder and float contracts based on the licence amount and asset amount.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of assets to be transferred including the licence amount.
    function load(address _asset, uint256 _amount) external payable {
        uint256 loadAmount = _amount;
        // If TKN then no licence to be paid
        if (_asset == _tknContractAddress) {
            ERC20(_asset).safeTransferFrom(msg.sender, _cryptoFloat, loadAmount);
        } else {
            loadAmount = _amount.mul(MAX_AMOUNT_SCALE).div(_licenceAmountScaled + MAX_AMOUNT_SCALE);
            uint256 licenceAmount = _amount.sub(loadAmount);

            if (_asset != address(0)) {
                ERC20(_asset).safeTransferFrom(msg.sender, _tokenHolder, licenceAmount);
                ERC20(_asset).safeTransferFrom(msg.sender, _cryptoFloat, loadAmount);
            } else {
                require(msg.value == _amount, "ETH sent is not equal to amount");
                _tokenHolder.transfer(licenceAmount);
                _cryptoFloat.transfer(loadAmount);
            }

            emit TransferredToTokenHolder(msg.sender, _tokenHolder, _asset, licenceAmount);
        }

        emit TransferredToCryptoFloat(msg.sender, _cryptoFloat, _asset, loadAmount);
    }

    //// @notice Withdraw tokens from the smart contract to the specified account.
    function claim(address payable _to, address _asset, uint256 _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

    /// @notice returns whether or not the CryptoFloat address is locked
    function floatLocked() public view returns (bool) {
        return _lockedCryptoFloat;
    }

    /// @notice returns whether or not the TokenHolder address is locked
    function holderLocked() public view returns (bool) {
        return _lockedTokenHolder;
    }

    /// @notice returns whether or not the Licence DAO address is locked
    function licenceDAOLocked() public view returns (bool) {
        return _lockedLicenceDAO;
    }

    /// @notice returns whether or not the TKN address is locked
    function tknContractAddressLocked() public view returns (bool) {
        return _lockedTKNContractAddress;
    }
}
"},"NameResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract NameResolver is ResolverBase {
    bytes4 constant private NAME_INTERFACE_ID = 0x691f3431;

    event NameChanged(bytes32 indexed node, string name);

    mapping(bytes32=>string) names;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string calldata name) external authorised(node) {
        names[node] = name;
        emit NameChanged(node, name);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == NAME_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"nonCompliantToken.sol":{"content":"pragma solidity ^0.5.17;

import "./SafeMath.sol";


/// @title NonCompliantToken is a mock ERC20 token that is not compatible with the ERC20 interface.
contract NonCompliantToken {
    using SafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    /// @dev Total supply of tokens in circulation.
    uint256 public totalSupply;

    /// @dev Balances for each account.
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Transfer a token. This throws on insufficient balance.
    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        if (_to == address(0)) revert();
        if (balanceOf[_from] < _value) revert();

        uint256 allowed = allowance[_from][msg.sender];
        if (allowed < _value) revert();

        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        allowance[_from][msg.sender] = SafeMath.sub(allowed, _value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
            revert();
        }

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /// @dev Credit an address.
    function credit(address to, uint256 amount) public returns (bool) {
        balanceOf[to] += amount;
        totalSupply += amount;
        return true;
    }

    /// @dev Debit an address.
    function debit(address from, uint256 amount) public {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}
"},"oracle.sol":{"content":"/**
 *  Oracle - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./controllable.sol";
import "./transferrable.sol";
import "./ensResolvable.sol";
import "./date.sol";
import "./parseIntScientific.sol";
import "./tokenWhitelistable.sol";
import "./SafeMath.sol";
import "./oraclizeAPI_0.5.sol";
import "./base64.sol";


/// @title Oracle provides asset exchange rates and conversion functionality.
contract Oracle is ENSResolvable, usingOraclize, Transferrable, Base64, Date, Controllable, ParseIntScientific, TokenWhitelistable {
    using strings for *;
    using SafeMath for uint256;

    /*******************/
    /*     Events     */
    /*****************/

    event SetGasPrice(address _sender, uint256 _gasPrice);

    event RequestedUpdate(string _symbol, bytes32 _queryID);
    event FailedUpdateRequest(string _reason);

    event VerifiedProof(bytes _publicKey, string _result);

    event SetCryptoComparePublicKey(address _sender, bytes _publicKey);

    event Claimed(address _to, address _asset, uint256 _amount);

    /**********************/
    /*     Constants     */
    /********************/

    uint256 private constant _PROOF_LEN = 165;
    uint256 private constant _ECDSA_SIG_LEN = 65;
    uint256 private constant _ENCODING_BYTES = 2;
    uint256 private constant _HEADERS_LEN = _PROOF_LEN - 2 * _ENCODING_BYTES - _ECDSA_SIG_LEN; // 2 bytes encoding headers length + 2 for signature.
    uint256 private constant _DIGEST_BASE64_LEN = 44; //base64 encoding of the SHA256 hash (32-bytes) of the result: fixed length.
    uint256 private constant _DIGEST_OFFSET = _HEADERS_LEN - _DIGEST_BASE64_LEN; // the starting position of the result hash in the headers string.

    uint256 private constant _MAX_BYTE_SIZE = 256; //for calculating length encoding

    // This is how the cryptocompare json begins
    bytes32 private constant _PREFIX_HASH = keccak256('{"ETH":');

    bytes public cryptoCompareAPIPublicKey;
    mapping(bytes32 => address) private _queryToToken;

    /// @notice Construct the oracle with multiple controllers, address resolver and custom gas price.
    /// @param _resolver_ is the address of the oraclize resolver
    /// @param _ens_ is the address of the ENS.
    /// @param _controllerNode_ is the ENS node corresponding to the Controller.
    /// @param _tokenWhitelistNode_ is the ENS corresponding to the Token Whitelist.
    constructor(address _resolver_, address _ens_, bytes32 _controllerNode_, bytes32 _tokenWhitelistNode_)
        public
        ENSResolvable(_ens_)
        Controllable(_controllerNode_)
        TokenWhitelistable(_tokenWhitelistNode_)
    {
        cryptoCompareAPIPublicKey = hex"a0f4f688350018ad1b9785991c0bde5f704b005dc79972b114dbed4a615a983710bfc647ebe5a320daa28771dce6a2d104f5efa2e4a85ba3760b76d46f8571ca";
        OAR = OraclizeAddrResolverI(_resolver_);
        oraclize_setCustomGasPrice(10000000000);
        oraclize_setProof(proofType_Native);
    }

    /// @notice Updates the Crypto Compare public API key.
    /// @param _publicKey new Crypto Compare public API key
    function updateCryptoCompareAPIPublicKey(bytes calldata _publicKey) external onlyAdmin {
        cryptoCompareAPIPublicKey = _publicKey;
        emit SetCryptoComparePublicKey(msg.sender, _publicKey);
    }

    /// @notice Sets the gas price used by Oraclize query.
    /// @param _gasPrice in wei for Oraclize
    function setCustomGasPrice(uint256 _gasPrice) external onlyController {
        oraclize_setCustomGasPrice(_gasPrice);
        emit SetGasPrice(msg.sender, _gasPrice);
    }

    /// @notice Update ERC20 token exchange rates for all supported tokens.
    /// @param _gasLimit the gas limit is passed, this is used for the Oraclize callback
    function updateTokenRates(uint256 _gasLimit) external payable onlyController {
        _updateTokenRates(_gasLimit);
    }

    /// @notice Update ERC20 token exchange rates for the list of tokens provided.
    /// @param _gasLimit the gas limit is passed, this is used for the Oraclize callback
    /// @param _tokenList the list of tokens that need to be updated
    function updateTokenRatesList(uint256 _gasLimit, address[] calldata _tokenList) external payable onlyController {
        _updateTokenRatesList(_gasLimit, _tokenList);
    }

    /// @notice Withdraw tokens from the smart contract to the specified account.
    function claim(address payable _to, address _asset, uint256 _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

    /// @notice Handle Oraclize query callback and verifiy the provided origin proof.
    /// @param _queryID Oraclize query ID.
    /// @param _result query result in JSON format.
    /// @param _proof origin proof from crypto compare.
    // solium-disable-next-line mixedcase
    function __callback(bytes32 _queryID, string memory _result, bytes memory _proof) public {
        // Require that the caller is the Oraclize contract.
        require(msg.sender == oraclize_cbAddress(), "sender is not oraclize");
        // Use the query ID to find the matching token address.
        address token = _queryToToken[_queryID];
        // Get the corresponding token object.
        (, , , bool available, , , uint256 lastUpdate) = _getTokenInfo(token);
        require(available, "token must be available");

        bool valid;
        uint256 timestamp;
        (valid, timestamp) = _verifyProof(_result, _proof, cryptoCompareAPIPublicKey, lastUpdate);

        // Require that the proof is valid.
        if (valid) {
            // Parse the JSON result to get the rate in wei.
            uint256 parsedRate = _parseIntScientificWei(parseRate(_result));
            // Set the update time of the token rate.
            uint256 parsedLastUpdate = timestamp;
            // Remove query from the list.
            delete _queryToToken[_queryID];

            _updateTokenRate(token, parsedRate, parsedLastUpdate);
        }
    }

    /// @notice Extracts JSON rate value from the response object.
    /// @param _json body of the JSON response from the CryptoCompare API.
    function parseRate(string memory _json) internal pure returns (string memory) {
        uint256 jsonLen = abi.encodePacked(_json).length;
        //{"ETH":}.length = 8, assuming a (maximum of) 18 digit prevision
        require(jsonLen > 8 && jsonLen <= 28, "misformatted input");

        bytes memory jsonPrefix = new bytes(7);
        copyBytes(abi.encodePacked(_json), 0, 7, jsonPrefix, 0);
        require(keccak256(jsonPrefix) == _PREFIX_HASH, "prefix mismatch");

        strings.slice memory body = _json.toSlice();
        body.split(":".toSlice());
        //we are sure that ':' is included in the string, body now contains the rate+'}'
        jsonLen = body._len;
        body.until("}".toSlice());
        require(body._len == jsonLen - 1, "not json format");
        //ensure that the json is properly terminated with a '}'
        return body.toString();
    }

    /// @notice Re-usable helper function that performs the Oraclize Query.
    /// @param _gasLimit the gas limit is passed, this is used for the Oraclize callback
    function _updateTokenRates(uint256 _gasLimit) private {
        address[] memory tokenAddresses = _tokenAddressArray();
        // Check if there are any existing tokens.
        if (tokenAddresses.length == 0) {
            // Emit a query failure event.
            emit FailedUpdateRequest("no tokens");
            // Check if the contract has enough Ether to pay for the query.
        } else if (oraclize_getPrice("URL") * tokenAddresses.length > address(this).balance) {
            // Emit a query failure event.
            emit FailedUpdateRequest("insufficient balance");
        } else {
            // Set up the cryptocompare API query strings.
            strings.slice memory apiPrefix = "https://min-api.cryptocompare.com/data/price?fsym=".toSlice();
            strings.slice memory apiSuffix = "&tsyms=ETH&sign=true".toSlice();

            // Create a new oraclize query for each supported token.
            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                // Store the token symbol used in the query.
                (string memory symbol, , , , , , ) = _getTokenInfo(tokenAddresses[i]);

                strings.slice memory sym = symbol.toSlice();
                // Create a new oraclize query from the component strings.
                bytes32 queryID = oraclize_query("URL", apiPrefix.concat(sym).toSlice().concat(apiSuffix), _gasLimit);
                // Store the query ID together with the associated token address.
                _queryToToken[queryID] = tokenAddresses[i];
                // Emit the query success event.
                emit RequestedUpdate(sym.toString(), queryID);
            }
        }
    }

    /// @notice Re-usable helper function that performs the Oraclize Query for a specific list of tokens.
    /// @param _gasLimit the gas limit is passed, this is used for the Oraclize callback.
    /// @param _tokenList the list of tokens that need to be updated.
    function _updateTokenRatesList(uint256 _gasLimit, address[] memory _tokenList) private {
        // Check if there are any existing tokens.
        if (_tokenList.length == 0) {
            // Emit a query failure event.
            emit FailedUpdateRequest("empty token list");
            // Check if the contract has enough Ether to pay for the query.
        } else if (oraclize_getPrice("URL") * _tokenList.length > address(this).balance) {
            // Emit a query failure event.
            emit FailedUpdateRequest("insufficient balance");
        } else {
            // Set up the cryptocompare API query strings.
            strings.slice memory apiPrefix = "https://min-api.cryptocompare.com/data/price?fsym=".toSlice();
            strings.slice memory apiSuffix = "&tsyms=ETH&sign=true".toSlice();

            // Create a new oraclize query for each supported token.
            for (uint256 i = 0; i < _tokenList.length; i++) {
                //token must exist, revert if it doesn't
                (string memory tokenSymbol, , , bool available, , , ) = _getTokenInfo(_tokenList[i]);
                require(available, "token must be available");
                // Store the token symbol used in the query.
                strings.slice memory symbol = tokenSymbol.toSlice();
                // Create a new oraclize query from the component strings.
                bytes32 queryID = oraclize_query("URL", apiPrefix.concat(symbol).toSlice().concat(apiSuffix), _gasLimit);
                // Store the query ID together with the associated token address.
                _queryToToken[queryID] = _tokenList[i];
                // Emit the query success event.
                emit RequestedUpdate(symbol.toString(), queryID);
            }
        }
    }

    /// @notice Verify the origin proof returned by the cryptocompare API.
    /// @param _result query result in JSON format.
    /// @param _proof origin proof from cryptocompare.
    /// @param _publicKey cryptocompare public key.
    /// @param _lastUpdate timestamp of the last time the requested token was updated.
    function _verifyProof(string memory _result, bytes memory _proof, bytes memory _publicKey, uint256 _lastUpdate) private returns (bool, uint256) {
        // expecting fixed length proofs
        if (_proof.length != _PROOF_LEN) {
            revert("invalid proof length");
        }

        // proof should be 65 bytes long: R (32 bytes) + S (32 bytes) + v (1 byte)
        if (uint256(uint8(_proof[1])) != _ECDSA_SIG_LEN) {
            revert("invalid signature length");
        }

        bytes memory signature = new bytes(_ECDSA_SIG_LEN);

        signature = copyBytes(_proof, 2, _ECDSA_SIG_LEN, signature, 0);

        // Extract the headers, big endian encoding of headers length
        if (
            uint256(uint8(_proof[_ENCODING_BYTES + _ECDSA_SIG_LEN])) * _MAX_BYTE_SIZE + uint256(uint8(_proof[_ENCODING_BYTES + _ECDSA_SIG_LEN + 1])) !=
            _HEADERS_LEN
        ) {
            revert("invalid headers length");
        }

        bytes memory headers = new bytes(_HEADERS_LEN);
        headers = copyBytes(_proof, 2 * _ENCODING_BYTES + _ECDSA_SIG_LEN, _HEADERS_LEN, headers, 0);

        // Check if the signature is valid and if the signer address is matching.
        if (!_verifySignature(headers, signature, _publicKey)) {
            revert("invalid signature");
        }

        // Check if the date is valid.
        bytes memory dateHeader = new bytes(20);
        // keep only the relevant string(e.g. "16 Nov 2018 16:22:18")
        dateHeader = copyBytes(headers, 11, 20, dateHeader, 0);

        bool dateValid;
        uint256 timestamp;
        (dateValid, timestamp) = _verifyDate(string(dateHeader), _lastUpdate);

        // Check whether the date returned is valid or not
        if (!dateValid) {
            revert("invalid date");
        }

        // Check if the signed digest hash matches the result hash.
        bytes memory digest = new bytes(_DIGEST_BASE64_LEN);
        digest = copyBytes(headers, _DIGEST_OFFSET, _DIGEST_BASE64_LEN, digest, 0);

        if (keccak256(abi.encodePacked(sha256(abi.encodePacked(_result)))) != keccak256(_base64decode(digest))) {
            revert("result hash not matching");
        }

        emit VerifiedProof(_publicKey, _result);
        return (true, timestamp);
    }

    /// @notice Verify the HTTP headers and the signature
    /// @param _headers HTTP headers provided by the cryptocompare api
    /// @param _signature signature provided by the cryptocompare api
    /// @param _publicKey cryptocompare public key.
    function _verifySignature(bytes memory _headers, bytes memory _signature, bytes memory _publicKey) private returns (bool) {
        address signer;
        bool signatureOK;

        // Checks if the signature is valid by hashing the headers
        (signatureOK, signer) = ecrecovery(sha256(_headers), _signature);
        return signatureOK && signer == address(uint160(uint256(keccak256(_publicKey))));
    }

    /// @notice Verify the signed HTTP date header.
    /// @param _dateHeader extracted date string e.g. Wed, 12 Sep 2018 15:18:14 GMT.
    /// @param _lastUpdate timestamp of the last time the requested token was updated.
    function _verifyDate(string memory _dateHeader, uint256 _lastUpdate) private pure returns (bool, uint256) {
        // called by verifyProof(), _dateHeader is always a string of length = 20
        assert(abi.encodePacked(_dateHeader).length == 20);

        // Split the date string and get individual date components.
        strings.slice memory date = _dateHeader.toSlice();
        strings.slice memory timeDelimiter = ":".toSlice();
        strings.slice memory dateDelimiter = " ".toSlice();

        uint256 day = _parseIntScientific(date.split(dateDelimiter).toString());
        require(day > 0 && day < 32, "day error");

        uint256 month = _monthToNumber(date.split(dateDelimiter).toString());
        require(month > 0 && month < 13, "month error");

        uint256 year = _parseIntScientific(date.split(dateDelimiter).toString());
        require(year > 2017 && year < 3000, "year error");

        uint256 hour = _parseIntScientific(date.split(timeDelimiter).toString());
        require(hour < 25, "hour error");

        uint256 minute = _parseIntScientific(date.split(timeDelimiter).toString());
        require(minute < 60, "minute error");

        uint256 second = _parseIntScientific(date.split(timeDelimiter).toString());
        require(second < 60, "second error");

        uint256 timestamp = year * (10**10) + month * (10**8) + day * (10**6) + hour * (10**4) + minute * (10**2) + second;

        return (timestamp > _lastUpdate, timestamp);
    }
}
"},"oraclize.sol":{"content":"pragma solidity ^0.5.17;


contract OraclizeConnector {
    address public cbAddress;
    uint256 gasPrice;
    bytes1 public proofType;

    constructor(address _cbAddress) public {
        cbAddress = _cbAddress;
    }

    function query(string memory _arg) private pure returns (bytes32) {
        return keccak256(bytes(_arg));
    }

    function query(uint256 _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32) {
        if (_timestamp == 0 && bytes(_datasource).length == 0) {
            return query(_arg);
        }
        return keccak256(bytes(_arg));
    }

    function query_withGasLimit(uint256 _timestamp, string calldata _datasource, string calldata _arg, uint256 _gaslimit) external payable returns (bytes32) {
        if (_timestamp == 0 && bytes(_datasource).length == 0 && _gaslimit == 0) {
            return query(_arg);
        }
        return keccak256(bytes(_arg));
    }

    function getPrice(string memory _datasource) public pure returns (uint256) {
        if (bytes(_datasource).length == 0) {
            return 1000000;
        }
        return 1000000; //10^6
    }

    function getPrice(string memory _datasource, uint256 gaslimit) public pure returns (uint256) {
        if (gaslimit == 0) {
            return getPrice(_datasource);
        }
        return 1000000; //10^6
    }

    function setProofType(bytes1 _proofType) external {
        proofType = _proofType;
    }

    function setCustomGasPrice(uint256 _gasPrice) external {
        gasPrice = _gasPrice;
    }
}


contract OraclizeAddrResolver {
    address private oraclizedAddress;

    constructor(address _oraclizedAddress) public {
        oraclizedAddress = _oraclizedAddress;
    }

    function getAddress() public view returns (address) {
        return oraclizedAddress;
    }
}
"},"oraclizeAPI_0.5.sol":{"content":"/*

ORACLIZE_API

Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/
pragma solidity >= 0.5.0 < 0.6.0; // Incompatible compiler version - please select a compiler within the stated pragma range, or use a different version of the oraclizeAPI!

// Dummy contract only used to emit to end-user they are using wrong solc
contract solcChecker {
/* INCOMPATIBLE SOLC: import the following instead: "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol" */ function f(bytes calldata x) external;
}

contract OraclizeI {

    address public cbAddress;

    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string memory _datasource) public returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string memory _datasource, uint _gasLimit) public returns (uint _dsprice);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _address);
}
/*

Begin solidity-cborutils

https://github.com/smartcontractkit/solidity-cborutils

MIT License

Copyright (c) 2018 SmartContract ChainLink, Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}
/*

End solidity-cborutils

*/
contract usingOraclize {

    using CBOR for Buffer.buffer;

    OraclizeI oraclize;
    OraclizeAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string oraclize_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) oraclize_randomDS_args;
    mapping(bytes32 => bool) oraclize_randomDS_sessionKeysHashVerified;

    modifier oraclizeAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            oraclize_setNetwork(networkID_auto);
        }
        if (address(oraclize) != OAR.getAddress()) {
            oraclize = OraclizeI(OAR.getAddress());
        }
        _;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);
        _;
    }

    function oraclize_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID; // NOTE: Silence the warning and remain backwards compatible
      return oraclize_setNetwork();
    }

    function oraclize_setNetworkName(string memory _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string memory _networkName) {
        return oraclize_network_name;
    }

    function oraclize_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OraclizeAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            oraclize_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }
    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    /* function __callback(bytes32 _myid, string memory _result) public {
        __callback(_myid, _result, new bytes(0));
    } */

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) public {
      _myid; _result; _proof;
      oraclize_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function oraclize_getPrice(string memory _datasource) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource);
    }

    function oraclize_getPrice(string memory _datasource, uint _gasLimit) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query.value(price)(0, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query.value(price)(_timestamp, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query_withGasLimit.value(price)(_timestamp, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return oraclize.query_withGasLimit.value(price)(0, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2.value(price)(0, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2.value(price)(_timestamp, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2_withGasLimit.value(price)(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return oraclize.query2_withGasLimit.value(price)(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_setProof(byte _proofP) oraclizeAPI internal {
        return oraclize.setProofType(_proofP);
    }


    function oraclize_cbAddress() oraclizeAPI internal returns (address _callbackAddress) {
        return oraclize.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function oraclize_setCustomGasPrice(uint _gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(_gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32 _sessionKeyHash) {
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
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

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        oraclize_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        oraclize_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi, use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi, use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi, use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
}
/*

END ORACLIZE_API

*/
"},"ownable.sol":{"content":"/**
 *  Ownable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;


/// @title Ownable has an owner address and provides basic authorization control functions.
/// This contract is modified version of the MIT OpenZepplin Ownable contract
/// This contract allows for the transferOwnership operation to be made impossible
/// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
contract Ownable {
    event TransferredOwnership(address _from, address _to);
    event LockedOwnership(address _locked);

    address payable private _owner;
    bool private _isTransferable;

    /// @notice Constructor sets the original owner of the contract and whether or not it is one time transferable.
    constructor(address payable _account_, bool _transferable_) internal {
        _owner = _account_;
        _isTransferable = _transferable_;
        // Emit the LockedOwnership event if no longer transferable.
        if (!_isTransferable) {
            emit LockedOwnership(_account_);
        }
        emit TransferredOwnership(address(0), _account_);
    }

    /// @notice Reverts if called by any account other than the owner.
    modifier onlyOwner() {
        require(_isOwner(msg.sender), "sender is not an owner");
        _;
    }

    /// @notice Allows the current owner to transfer control of the contract to a new address.
    /// @param _account address to transfer ownership to.
    /// @param _transferable indicates whether to keep the ownership transferable.
    function transferOwnership(address payable _account, bool _transferable) external onlyOwner {
        // Require that the ownership is transferable.
        require(_isTransferable, "ownership is not transferable");
        // Require that the new owner is not the zero address.
        require(_account != address(0), "owner cannot be set to zero address");
        // Set the transferable flag to the value _transferable passed in.
        _isTransferable = _transferable;
        // Emit the LockedOwnership event if no longer transferable.
        if (!_transferable) {
            emit LockedOwnership(_account);
        }
        // Emit the ownership transfer event.
        emit TransferredOwnership(_owner, _account);
        // Set the owner to the provided address.
        _owner = _account;
    }

    /// @notice check if the ownership is transferable.
    /// @return true if the ownership is transferable.
    function isTransferable() external view returns (bool) {
        return _isTransferable;
    }

    /// @notice Allows the current owner to relinquish control of the contract.
    /// @dev Renouncing to ownership will leave the contract without an owner and unusable.
    /// @dev It will not be possible to call the functions with the `onlyOwner` modifier anymore.
    function renounceOwnership() external onlyOwner {
        // Require that the ownership is transferable.
        require(_isTransferable, "ownership is not transferable");
        // note that this could be terminal
        _owner = address(0);

        emit TransferredOwnership(_owner, address(0));
    }

    /// @notice Find out owner address
    /// @return address of the owner.
    function owner() public view returns (address payable) {
        return _owner;
    }

    /// @notice Check if owner address
    /// @return true if sender is the owner of the contract.
    function _isOwner(address _address) internal view returns (bool) {
        return _address == _owner;
    }
}
"},"parseIntScientific.sol":{"content":"/**
 *  ParseIntScientific - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity ^0.5.17;

import "./SafeMath.sol";


/// @title ParseIntScientific provides floating point in scientific notation (e.g. e-5) parsing functionality.
contract ParseIntScientific {
    using SafeMath for uint256;

    bytes1 private constant _PLUS_ASCII = bytes1(uint8(43)); //decimal value of '+'
    bytes1 private constant _DASH_ASCII = bytes1(uint8(45)); //decimal value of '-'
    bytes1 private constant _DOT_ASCII = bytes1(uint8(46)); //decimal value of '.'
    bytes1 private constant _ZERO_ASCII = bytes1(uint8(48)); //decimal value of '0'
    bytes1 private constant _NINE_ASCII = bytes1(uint8(57)); //decimal value of '9'
    bytes1 private constant _E_ASCII = bytes1(uint8(69)); //decimal value of 'E'
    bytes1 private constant _LOWERCASE_E_ASCII = bytes1(uint8(101)); //decimal value of 'e'

    /// @notice ParseIntScientific delegates the call to _parseIntScientific(string, uint) with the 2nd argument being 0.
    function _parseIntScientific(string memory _inString) internal pure returns (uint256) {
        return _parseIntScientific(_inString, 0);
    }

    /// @notice ParseIntScientificWei parses a rate expressed in ETH and returns its wei denomination
    function _parseIntScientificWei(string memory _inString) internal pure returns (uint256) {
        return _parseIntScientific(_inString, 18);
    }

    /// @notice ParseIntScientific parses a JSON standard - floating point number.
    /// @param _inString is input string.
    /// @param _magnitudeMult multiplies the number with 10^_magnitudeMult.
    function _parseIntScientific(string memory _inString, uint256 _magnitudeMult) internal pure returns (uint256) {
        bytes memory inBytes = bytes(_inString);
        uint256 mint = 0; // the final uint returned
        uint256 mintDec = 0; // the uint following the decimal point
        uint256 mintExp = 0; // the exponent
        uint256 decMinted = 0; // how many decimals were 'minted'.
        uint256 expIndex = 0; // the position in the byte array that 'e' was found (if found)
        bool integral = false; // indicates the existence of the integral part, it should always exist (even if 0) e.g. 'e+1'  or '.1' is not valid
        bool decimals = false; // indicates a decimal number, set to true if '.' is found
        bool exp = false; // indicates if the number being parsed has an exponential representation
        bool minus = false; // indicated if the exponent is negative
        bool plus = false; // indicated if the exponent is positive
        uint256 i;
        for (i = 0; i < inBytes.length; i++) {
            if ((inBytes[i] >= _ZERO_ASCII) && (inBytes[i] <= _NINE_ASCII) && (!exp)) {
                // 'e' not encountered yet, minting integer part or decimals
                if (decimals) {
                    // '.' encountered
                    // use safeMath in case there is an overflow
                    mintDec = mintDec.mul(10);
                    mintDec = mintDec.add(uint8(inBytes[i]) - uint8(_ZERO_ASCII));
                    decMinted++; //keep track of the #decimals
                } else {
                    // integral part (before '.')
                    integral = true;
                    // use safeMath in case there is an overflow
                    mint = mint.mul(10);
                    mint = mint.add(uint8(inBytes[i]) - uint8(_ZERO_ASCII));
                }
            } else if ((inBytes[i] >= _ZERO_ASCII) && (inBytes[i] <= _NINE_ASCII) && (exp)) {
                //exponential notation (e-/+) has been detected, mint the exponent
                mintExp = mintExp.mul(10);
                mintExp = mintExp.add(uint8(inBytes[i]) - uint8(_ZERO_ASCII));
            } else if (inBytes[i] == _DOT_ASCII) {
                //an integral part before should always exist before '.'
                require(integral, "missing integral part");
                // an extra decimal point makes the format invalid
                require(!decimals, "duplicate decimal point");
                //the decimal point should always be before the exponent
                require(!exp, "decimal after exponent");
                decimals = true;
            } else if (inBytes[i] == _DASH_ASCII) {
                // an extra '-' should be considered an invalid character
                require(!minus, "duplicate -");
                require(!plus, "extra sign");
                require(expIndex + 1 == i, "- sign not immediately after e");
                minus = true;
            } else if (inBytes[i] == _PLUS_ASCII) {
                // an extra '+' should be considered an invalid character
                require(!plus, "duplicate +");
                require(!minus, "extra sign");
                require(expIndex + 1 == i, "+ sign not immediately after e");
                plus = true;
            } else if ((inBytes[i] == _E_ASCII) || (inBytes[i] == _LOWERCASE_E_ASCII)) {
                //an integral part before should always exist before 'e'
                require(integral, "missing integral part");
                // an extra 'e' or 'E' should be considered an invalid character
                require(!exp, "duplicate exponent symbol");
                exp = true;
                expIndex = i;
            } else {
                revert("invalid digit");
            }
        }

        if (minus || plus) {
            // end of string e[x|-] without specifying the exponent
            require(i > expIndex + 2);
        } else if (exp) {
            // end of string (e) without specifying the exponent
            require(i > expIndex + 1);
        }

        if (minus) {
            // e^(-x)
            if (mintExp >= _magnitudeMult) {
                // the (negative) exponent is bigger than the given parameter for "shifting left".
                // use integer division to reduce the precision.
                require(mintExp - _magnitudeMult < 78, "exponent > 77"); //
                mint /= 10**(mintExp - _magnitudeMult);
                return mint;
            } else {
                // the (negative) exponent is smaller than the given parameter for "shifting left".
                //no need for underflow check
                _magnitudeMult = _magnitudeMult - mintExp;
            }
        } else {
            // e^(+x), positive exponent or no exponent
            // just shift left as many times as indicated by the exponent and the shift parameter
            _magnitudeMult = _magnitudeMult.add(mintExp);
        }

        if (_magnitudeMult >= decMinted) {
            // the decimals are fewer or equal than the shifts: use all of them
            // shift number and add the decimals at the end
            // include decimals if present in the original input
            require(decMinted < 78, "more than 77 decimal digits parsed"); //
            mint = mint.mul(10**(decMinted));
            mint = mint.add(mintDec);
            //// add zeros at the end if the decimals were fewer than #_magnitudeMult
            require(_magnitudeMult - decMinted < 78, "exponent > 77"); //
            mint = mint.mul(10**(_magnitudeMult - decMinted));
        } else {
            // the decimals are more than the #_magnitudeMult shifts
            // use only the ones needed, discard the rest
            decMinted -= _magnitudeMult;
            require(decMinted < 78, "more than 77 decimal digits parsed"); //
            mintDec /= 10**(decMinted);
            // shift number and add the decimals at the end
            require(_magnitudeMult < 78, "more than 77 decimal digits parsed"); //
            mint = mint.mul(10**(_magnitudeMult));
            mint = mint.add(mintDec);
        }
        return mint;
    }
}
"},"parseIntScientificExporter.sol":{"content":"pragma solidity ^0.5.17;

import "./parseIntScientific.sol";


contract ParseIntScientificExporter is ParseIntScientific {
    /// @dev exports _parseIntScientific(string) as an external function.
    function parseIntScientific(string calldata _a) external pure returns (uint256) {
        return _parseIntScientific(_a);
    }

    /// @dev exports _parseIntScientific(string, uint) as an external function.
    function parseIntScientificDecimals(string calldata _a, uint256 _b) external pure returns (uint256) {
        return _parseIntScientific(_a, _b);
    }

    /// @dev exports _parseIntScientificWei(string) as an external function.
    function parseIntScientificWei(string calldata _a) external pure returns (uint256) {
        return _parseIntScientificWei(_a);
    }
}
"},"PubkeyResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract PubkeyResolver is ResolverBase {
    bytes4 constant private PUBKEY_INTERFACE_ID = 0xc8690233;

    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x, y the X and Y coordinates of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == PUBKEY_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"PublicResolver.sol":{"content":"/**
 * BSD 2-Clause License
 *
 * Copyright (c) 2018, True Names Limited
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ENS.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./DNSResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver is ABIResolver, AddrResolver, ContentHashResolver, DNSResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    ENS ens;

    /**
     * A mapping of authorisations. An address that is authorised for a name
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (node, owner, caller) => isAuthorised
     */
    mapping(bytes32=>mapping(address=>mapping(address=>bool))) public authorisations;

    event AuthorisationChanged(bytes32 indexed node, address indexed owner, address indexed target, bool isAuthorised);

    constructor(ENS _ens) public {
        ens = _ens;
    }

    /**
     * @dev Sets or clears an authorisation.
     * Authorisations are specific to the caller. Any account can set an authorisation
     * for any name, but the authorisation that is checked will be that of the
     * current owner of a name. Thus, transferring a name effectively clears any
     * existing authorisations, and new authorisations can be set in advance of
     * an ownership transfer if desired.
     *
     * @param node The name to change the authorisation on.
     * @param target The address that is to be authorised or deauthorised.
     * @param isAuthorised True if the address should be authorised, or false if it should be deauthorised.
     */
    function setAuthorisation(bytes32 node, address target, bool isAuthorised) external {
        authorisations[node][msg.sender][target] = isAuthorised;
        emit AuthorisationChanged(node, msg.sender, target, isAuthorised);
    }

    function isAuthorised(bytes32 node) internal view returns(bool) {
        address owner = ens.owner(node);
        return owner == msg.sender || authorisations[node][owner][msg.sender];
    }

    function multicall(bytes[] calldata data) external returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }
}
"},"ResolverBase.sol":{"content":"pragma solidity ^0.5.0;

contract ResolverBase {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == INTERFACE_META_ID;
    }

    function isAuthorised(bytes32 node) internal view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}
"},"RRUtils.sol":{"content":"pragma solidity >0.4.23;

import "./ENSBytesUtils.sol";

/**
* @dev RRUtils is a library that provides utilities for parsing DNS resource records.
*/
library RRUtils {
    using ENSBytesUtils for *;

    /**
    * @dev Returns the number of bytes in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The length of the DNS name at 'offset', in bytes.
    */
    function nameLength(bytes memory self, uint offset) internal pure returns(uint) {
        uint idx = offset;
        while (true) {
            assert(idx < self.length);
            uint labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
        }
        return idx - offset;
    }

    /**
    * @dev Returns a DNS format name at the specified offset of self.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The name.
    */
    function readName(bytes memory self, uint offset) internal pure returns(bytes memory ret) {
        uint len = nameLength(self, offset);
        return self.substring(offset, len);
    }

    /**
    * @dev Returns the number of labels in the DNS name at 'offset' in 'self'.
    * @param self The byte array to read a name from.
    * @param offset The offset to start reading at.
    * @return The number of labels in the DNS name at 'offset', in bytes.
    */
    function labelCount(bytes memory self, uint offset) internal pure returns(uint) {
        uint count = 0;
        while (true) {
            assert(offset < self.length);
            uint labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
            count += 1;
        }
        return count;
    }

    /**
    * @dev An iterator over resource records.
    */
    struct RRIterator {
        bytes data;
        uint offset;
        uint16 dnstype;
        uint16 class;
        uint32 ttl;
        uint rdataOffset;
        uint nextOffset;
    }

    /**
    * @dev Begins iterating over resource records.
    * @param self The byte string to read from.
    * @param offset The offset to start reading at.
    * @return An iterator object.
    */
    function iterateRRs(bytes memory self, uint offset) internal pure returns (RRIterator memory ret) {
        ret.data = self;
        ret.nextOffset = offset;
        next(ret);
    }

    /**
    * @dev Returns true iff there are more RRs to iterate.
    * @param iter The iterator to check.
    * @return True iff the iterator has finished.
    */
    function done(RRIterator memory iter) internal pure returns(bool) {
        return iter.offset >= iter.data.length;
    }

    /**
    * @dev Moves the iterator to the next resource record.
    * @param iter The iterator to advance.
    */
    function next(RRIterator memory iter) internal pure {
        iter.offset = iter.nextOffset;
        if (iter.offset >= iter.data.length) {
            return;
        }

        // Skip the name
        uint off = iter.offset + nameLength(iter.data, iter.offset);

        // Read type, class, and ttl
        iter.dnstype = iter.data.readUint16(off);
        off += 2;
        iter.class = iter.data.readUint16(off);
        off += 2;
        iter.ttl = iter.data.readUint32(off);
        off += 4;

        // Read the rdata
        uint rdataLength = iter.data.readUint16(off);
        off += 2;
        iter.rdataOffset = off;
        iter.nextOffset = off + rdataLength;
    }

    /**
    * @dev Returns the name of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the owner name from the RR.
    */
    function name(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.offset, nameLength(iter.data, iter.offset));
    }

    /**
    * @dev Returns the rdata portion of the current record.
    * @param iter The iterator.
    * @return A new bytes object containing the RR's RDATA.
    */
    function rdata(RRIterator memory iter) internal pure returns(bytes memory) {
        return iter.data.substring(iter.rdataOffset, iter.nextOffset - iter.rdataOffset);
    }

    /**
    * @dev Checks if a given RR type exists in a type bitmap.
    * @param self The byte string to read the type bitmap from.
    * @param offset The offset to start reading at.
    * @param rrtype The RR type to check for.
    * @return True if the type is found in the bitmap, false otherwise.
    */
    function checkTypeBitmap(bytes memory self, uint offset, uint16 rrtype) internal pure returns (bool) {
        uint8 typeWindow = uint8(rrtype >> 8);
        uint8 windowByte = uint8((rrtype & 0xff) / 8);
        uint8 windowBitmask = uint8(uint8(1) << (uint8(7) - uint8(rrtype & 0x7)));
        for (uint off = offset; off < self.length;) {
            uint8 window = self.readUint8(off);
            uint8 len = self.readUint8(off + 1);
            if (typeWindow < window) {
                // We've gone past our window; it's not here.
                return false;
            } else if (typeWindow == window) {
                // Check this type bitmap
                if (len * 8 <= windowByte) {
                    // Our type is past the end of the bitmap
                    return false;
                }
                return (self.readUint8(off + windowByte + 2) & windowBitmask) != 0;
            } else {
                // Skip this type bitmap
                off += len + 2;
            }
        }

        return false;
    }

    function compareNames(bytes memory self, bytes memory other) internal pure returns (int) {
        if (self.equals(other)) {
            return 0;
        }

        uint off;
        uint otheroff;
        uint prevoff;
        uint otherprevoff;
        uint counts = labelCount(self, 0);
        uint othercounts = labelCount(other, 0);

        // Keep removing labels from the front of the name until both names are equal length
        while (counts > othercounts) {
            prevoff = off;
            off = progress(self, off);
            counts--;
        }

        while (othercounts > counts) {
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            othercounts--;
        }

        // Compare the last nonequal labels to each other
        while (counts > 0 && !self.equals(off, other, otheroff)) {
            prevoff = off;
            off = progress(self, off);
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            counts -= 1;
        }

        if (off == 0) {
            return -1;
        }
        if(otheroff == 0) {
            return 1;
        }

        return self.compare(prevoff + 1, self.readUint8(prevoff), other, otherprevoff + 1, other.readUint8(otherprevoff));
    }

    function progress(bytes memory body, uint off) internal pure returns(uint) {
        return off + 1 + body.readUint8(off);
    }
}
"},"SafeERC20.sol":{"content":"/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ERC20 token, bytes memory data) internal {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
"},"strings.sol":{"content":"/*
 * Copyright 2016 Nick Johnson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <arachnid@notdot.net>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.5.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}
"},"TextResolver.sol":{"content":"pragma solidity ^0.5.0;

import "./ResolverBase.sol";

contract TextResolver is ResolverBase {
    bytes4 constant private TEXT_INTERFACE_ID = 0x59d1d43c;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    mapping(bytes32=>mapping(string=>string)) texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == TEXT_INTERFACE_ID || super.supportsInterface(interfaceID);
    }
}
"},"token.sol":{"content":"pragma solidity ^0.5.17;

import "./SafeMath.sol";


/// @title Token is a mock ERC20 token used for testing.
contract Token {
    using SafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    /// @dev Total supply of tokens in circulation.
    uint256 public totalSupply;

    /// @dev Balances for each account.
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Transfer a token. This throws on insufficient balance.
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (_to == address(0)) return false;
        if (balanceOf[_from] < _value) return false;

        uint256 allowed = allowance[_from][msg.sender];
        if (allowed < _value) return false; //PROBLEM!
        /* require(_value <= allowed, "amount exceeds allowance"); */

        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        allowance[_from][msg.sender] = SafeMath.sub(allowed, _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Credit an address.
    function credit(address to, uint256 amount) public returns (bool) {
        balanceOf[to] += amount;
        totalSupply += amount;
        return true;
    }

    /// @dev Debit an address.
    function debit(address from, uint256 amount) public {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}
"},"tokenWhitelist.sol":{"content":"/**
 *  TokenWhitelist - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./controllable.sol";
import "./transferrable.sol";
import "./bytesUtils.sol";
import "./strings.sol";
import "./SafeMath.sol";


/// @title The ITokenWhitelist interface provides access to a whitelist of tokens.
interface ITokenWhitelist {
    function getTokenInfo(address) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);

    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256);

    function tokenAddressArray() external view returns (address[] memory);

    function redeemableTokens() external view returns (address[] memory);

    function methodIdWhitelist(bytes4) external view returns (bool);

    function getERC20RecipientAndAmount(address, bytes calldata) external view returns (address, uint256);

    function stablecoin() external view returns (address);

    function updateTokenRate(address, uint256, uint256) external;
}


/// @title TokenWhitelist stores a list of tokens used by the Consumer Contract Wallet, the Oracle, the TKN Holder and the TKN Licence Contract
contract TokenWhitelist is ENSResolvable, Controllable, Transferrable {
    using strings for *;
    using SafeMath for uint256;
    using BytesUtils for bytes;

    event UpdatedTokenRate(address _sender, address _token, uint256 _rate);

    event UpdatedTokenLoadable(address _sender, address _token, bool _loadable);
    event UpdatedTokenRedeemable(address _sender, address _token, bool _redeemable);

    event AddedToken(address _sender, address _token, string _symbol, uint256 _magnitude, bool _loadable, bool _redeemable);
    event RemovedToken(address _sender, address _token);

    event AddedMethodId(bytes4 _methodId);
    event RemovedMethodId(bytes4 _methodId);
    event AddedExclusiveMethod(address _token, bytes4 _methodId);
    event RemovedExclusiveMethod(address _token, bytes4 _methodId);

    event Claimed(address _to, address _asset, uint256 _amount);

    /// @dev these are the methods whitelisted by default in executeTransaction() for protected tokens
    bytes4 private constant _APPROVE = 0x095ea7b3; // keccak256(approve(address,uint256)) => 0x095ea7b3
    bytes4 private constant _BURN = 0x42966c68; // keccak256(burn(uint256)) => 0x42966c68
    bytes4 private constant _TRANSFER = 0xa9059cbb; // keccak256(transfer(address,uint256)) => 0xa9059cbb
    bytes4 private constant _TRANSFER_FROM = 0x23b872dd; // keccak256(transferFrom(address,address,uint256)) => 0x23b872dd

    struct Token {
        string symbol; // Token symbol
        uint256 magnitude; // 10^decimals
        uint256 rate; // Token exchange rate in wei
        bool available; // Flags if the token is available or not
        bool loadable; // Flags if token is loadable to the TokenCard
        bool redeemable; // Flags if token is redeemable in the TKN Holder contract
        uint256 lastUpdate; // Time of the last rate update
    }

    mapping(address => Token) private _tokenInfoMap;

    // @notice specifies whitelisted methodIds for protected tokens in wallet's excuteTranaction() e.g. keccak256(transfer(address,uint256)) => 0xa9059cbb
    mapping(bytes4 => bool) private _methodIdWhitelist;

    address[] private _tokenAddressArray;

    /// @notice keeping track of how many redeemable tokens are in the tokenWhitelist
    uint256 private _redeemableCounter;

    /// @notice Address of the stablecoin.
    address private _stablecoin;

    /// @notice is registered ENS node identifying the oracle contract.
    bytes32 private _oracleNode;

    /// @notice Constructor initializes ENSResolvable, and Controllable.
    /// @param _ens_ is the ENS registry address.
    /// @param _oracleNode_ is the ENS node of the Oracle.
    /// @param _controllerNode_ is our Controllers node.
    /// @param _stablecoinAddress_ is the address of the stablecoint used by the wallet for the card load limit.
    constructor(address _ens_, bytes32 _oracleNode_, bytes32 _controllerNode_, address _stablecoinAddress_)
        public
        ENSResolvable(_ens_)
        Controllable(_controllerNode_)
    {
        _oracleNode = _oracleNode_;
        _stablecoin = _stablecoinAddress_;
        //a priori ERC20 whitelisted methods
        _methodIdWhitelist[_APPROVE] = true;
        _methodIdWhitelist[_BURN] = true;
        _methodIdWhitelist[_TRANSFER] = true;
        _methodIdWhitelist[_TRANSFER_FROM] = true;
    }

    modifier onlyAdminOrOracle() {
        address oracleAddress = _ensResolve(_oracleNode);
        require(_isAdmin(msg.sender) || msg.sender == oracleAddress, "either oracle or admin");
        _;
    }

    /// @notice Add ERC20 tokens to the list of whitelisted tokens.
    /// @param _tokens ERC20 token contract addresses.
    /// @param _symbols ERC20 token names.
    /// @param _magnitude 10 to the power of number of decimal places used by each ERC20 token.
    /// @param _loadable is a bool that states whether or not a token is loadable to the TokenCard.
    /// @param _redeemable is a bool that states whether or not a token is redeemable in the TKN Holder Contract.
    /// @param _lastUpdate is a unit representing an ISO datetime e.g. 20180913153211.
    function addTokens(
        address[] calldata _tokens,
        bytes32[] calldata _symbols,
        uint256[] calldata _magnitude,
        bool[] calldata _loadable,
        bool[] calldata _redeemable,
        uint256 _lastUpdate
    ) external onlyAdmin {
        // Require that all parameters have the same length.
        require(
            _tokens.length == _symbols.length &&
                _tokens.length == _magnitude.length &&
                _tokens.length == _loadable.length &&
                _tokens.length == _loadable.length,
            "parameter lengths do not match"
        );
        // Add each token to the list of supported tokens.
        for (uint256 i = 0; i < _tokens.length; i++) {
            // Require that the token isn't already available.
            require(!_tokenInfoMap[_tokens[i]].available, "token already available");
            // Store the intermediate values.
            string memory symbol = _symbols[i].toSliceB32().toString();
            // Add the token to the token list.
            _tokenInfoMap[_tokens[i]] = Token({
                symbol: symbol,
                magnitude: _magnitude[i],
                rate: 0,
                available: true,
                loadable: _loadable[i],
                redeemable: _redeemable[i],
                lastUpdate: _lastUpdate
            });
            // Add the token address to the address list.
            _tokenAddressArray.push(_tokens[i]);
            //if the token is redeemable increase the redeemableCounter
            if (_redeemable[i]) {
                _redeemableCounter = _redeemableCounter.add(1);
            }
            // Emit token addition event.
            emit AddedToken(msg.sender, _tokens[i], symbol, _magnitude[i], _loadable[i], _redeemable[i]);
        }
    }

    /// @notice Remove ERC20 tokens from the whitelist of tokens.
    /// @param _tokens ERC20 token contract addresses.
    function removeTokens(address[] calldata _tokens) external onlyAdmin {
        // Delete each token object from the list of supported tokens based on the addresses provided.
        for (uint256 i = 0; i < _tokens.length; i++) {
            // Store the token address.
            address token = _tokens[i];
            //token must be available, reverts on duplicates as well
            require(_tokenInfoMap[token].available, "token is not available");
            //if the token is redeemable decrease the redeemableCounter
            if (_tokenInfoMap[token].redeemable) {
                _redeemableCounter = _redeemableCounter.sub(1);
            }
            // Delete the token object.
            delete _tokenInfoMap[token];
            // Remove the token address from the address list.
            for (uint256 j = 0; j < _tokenAddressArray.length.sub(1); j++) {
                if (_tokenAddressArray[j] == token) {
                    _tokenAddressArray[j] = _tokenAddressArray[_tokenAddressArray.length.sub(1)];
                    break;
                }
            }
            _tokenAddressArray.length--;
            // Emit token removal event.
            emit RemovedToken(msg.sender, token);
        }
    }

    /// @notice based on the method it returns the recipient address and amount/value, ERC20 specific.
    /// @param _data is the transaction payload.
    function getERC20RecipientAndAmount(address _token, bytes calldata _data) external view returns (address, uint256) {
        // Require that there exist enough bytes for encoding at least a method signature + data in the transaction payload:
        // 4 (signature)  + 32(address or uint256)
        require(_data.length >= 4 + 32, "not enough method-encoding bytes");
        // Get the method signature
        bytes4 signature = _data._bytesToBytes4(0);
        // Check if method Id is supported
        require(isERC20MethodSupported(_token, signature), "unsupported method");
        // returns the recipient's address and amount is the value to be transferred
        if (signature == _BURN) {
            // 4 (signature) + 32(uint256)
            return (_token, _data._bytesToUint256(4));
        } else if (signature == _TRANSFER_FROM) {
            // 4 (signature) + 32(address) + 32(address) + 32(uint256)
            require(_data.length >= 4 + 32 + 32 + 32, "not enough data for transferFrom");
            return (_data._bytesToAddress(4 + 32 + 12), _data._bytesToUint256(4 + 32 + 32));
        } else {
            //transfer or approve
            // 4 (signature) + 32(address) + 32(uint)
            require(_data.length >= 4 + 32 + 32, "not enough data for transfer/appprove");
            return (_data._bytesToAddress(4 + 12), _data._bytesToUint256(4 + 32));
        }
    }

    /// @notice Toggles whether or not a token is loadable or not.
    function setTokenLoadable(address _token, bool _loadable) external onlyAdmin {
        // Require that the token exists.
        require(_tokenInfoMap[_token].available, "token is not available");

        // this sets the loadable flag to the value passed in
        _tokenInfoMap[_token].loadable = _loadable;

        emit UpdatedTokenLoadable(msg.sender, _token, _loadable);
    }

    /// @notice Toggles whether or not a token is redeemable or not.
    function setTokenRedeemable(address _token, bool _redeemable) external onlyAdmin {
        // Require that the token exists.
        require(_tokenInfoMap[_token].available, "token is not available");

        // this sets the redeemable flag to the value passed in
        _tokenInfoMap[_token].redeemable = _redeemable;

        emit UpdatedTokenRedeemable(msg.sender, _token, _redeemable);
    }

    /// @notice Update ERC20 token exchange rate.
    /// @param _token ERC20 token contract address.
    /// @param _rate ERC20 token exchange rate in wei.
    /// @param _updateDate date for the token updates. This will be compared to when oracle updates are received.
    function updateTokenRate(address _token, uint256 _rate, uint256 _updateDate) external onlyAdminOrOracle {
        // Require that the token exists.
        require(_tokenInfoMap[_token].available, "token is not available");
        // Update the token's rate.
        _tokenInfoMap[_token].rate = _rate;
        // Update the token's last update timestamp.
        _tokenInfoMap[_token].lastUpdate = _updateDate;
        // Emit the rate update event.
        emit UpdatedTokenRate(msg.sender, _token, _rate);
    }

    //// @notice Withdraw tokens from the smart contract to the specified account.
    function claim(address payable _to, address _asset, uint256 _amount) external onlyAdmin {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }

    /// @notice This returns all of the fields for a given token.
    /// @param _a is the address of a given token.
    /// @return string of the token's symbol.
    /// @return uint of the token's magnitude.
    /// @return uint of the token's exchange rate to ETH.
    /// @return bool whether the token is available.
    /// @return bool whether the token is loadable to the TokenCard.
    /// @return bool whether the token is redeemable to the TKN Holder Contract.
    /// @return uint of the lastUpdated time of the token's exchange rate.
    function getTokenInfo(address _a) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage tokenInfo = _tokenInfoMap[_a];
        return (tokenInfo.symbol, tokenInfo.magnitude, tokenInfo.rate, tokenInfo.available, tokenInfo.loadable, tokenInfo.redeemable, tokenInfo.lastUpdate);
    }

    /// @notice This returns all of the fields for our StableCoin.
    /// @return string of the token's symbol.
    /// @return uint of the token's magnitude.
    /// @return uint of the token's exchange rate to ETH.
    /// @return bool whether the token is available.
    /// @return bool whether the token is loadable to the TokenCard.
    /// @return bool whether the token is redeemable to the TKN Holder Contract.
    /// @return uint of the lastUpdated time of the token's exchange rate.
    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        Token storage stablecoinInfo = _tokenInfoMap[_stablecoin];
        return (
            stablecoinInfo.symbol,
            stablecoinInfo.magnitude,
            stablecoinInfo.rate,
            stablecoinInfo.available,
            stablecoinInfo.loadable,
            stablecoinInfo.redeemable,
            stablecoinInfo.lastUpdate
        );
    }

    /// @notice This returns an array of all whitelisted token addresses.
    /// @return address[] of whitelisted tokens.
    function tokenAddressArray() external view returns (address[] memory) {
        return _tokenAddressArray;
    }

    /// @notice This returns an array of all redeemable token addresses.
    /// @return address[] of redeemable tokens.
    function redeemableTokens() external view returns (address[] memory) {
        address[] memory redeemableAddresses = new address[](_redeemableCounter);
        uint256 redeemableIndex = 0;
        for (uint256 i = 0; i < _tokenAddressArray.length; i++) {
            address token = _tokenAddressArray[i];
            if (_tokenInfoMap[token].redeemable) {
                redeemableAddresses[redeemableIndex] = token;
                redeemableIndex += 1;
            }
        }
        return redeemableAddresses;
    }

    /// @notice This returns true if a method Id is supported for the specific token.
    /// @return true if _methodId is supported in general or just for the specific token.
    function isERC20MethodSupported(address _token, bytes4 _methodId) public view returns (bool) {
        require(_tokenInfoMap[_token].available, "non-existing token");
        return (_methodIdWhitelist[_methodId]);
    }

    /// @notice This returns true if the method is supported for all protected tokens.
    /// @return true if _methodId is in the method whitelist.
    function isERC20MethodWhitelisted(bytes4 _methodId) external view returns (bool) {
        return (_methodIdWhitelist[_methodId]);
    }

    /// @notice This returns the number of redeemable tokens.
    /// @return current # of redeemables.
    function redeemableCounter() external view returns (uint256) {
        return _redeemableCounter;
    }

    /// @notice This returns the address of our stablecoin of choice.
    /// @return the address of the stablecoin contract.
    function stablecoin() external view returns (address) {
        return _stablecoin;
    }

    /// @notice this returns the node hash of our Oracle.
    /// @return the oracle node registered in ENS.
    function oracleNode() external view returns (bytes32) {
        return _oracleNode;
    }
}
"},"tokenWhitelistable.sol":{"content":"/**
 *  TokenWhitelistable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./tokenWhitelist.sol";
import "./ensResolvable.sol";


/// @title TokenWhitelistable implements access to the TokenWhitelist located behind ENS.
contract TokenWhitelistable is ENSResolvable {
    /// @notice Is the registered ENS node identifying the tokenWhitelist contract
    bytes32 private _tokenWhitelistNode;

    /// @notice Constructor initializes the TokenWhitelistable object.
    /// @param _tokenWhitelistNode_ is the ENS node of the TokenWhitelist.
    constructor(bytes32 _tokenWhitelistNode_) internal {
        _tokenWhitelistNode = _tokenWhitelistNode_;
    }

    /// @notice This shows what TokenWhitelist is being used
    /// @return TokenWhitelist's node registered in ENS.
    function tokenWhitelistNode() external view returns (bytes32) {
        return _tokenWhitelistNode;
    }

    /// @notice This returns all of the fields for a given token.
    /// @param _a is the address of a given token.
    /// @return string of the token's symbol.
    /// @return uint of the token's magnitude.
    /// @return uint of the token's exchange rate to ETH.
    /// @return bool whether the token is available.
    /// @return bool whether the token is loadable to the TokenCard.
    /// @return bool whether the token is redeemable to the TKN Holder Contract.
    /// @return uint of the lastUpdated time of the token's exchange rate.
    function _getTokenInfo(address _a) internal view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getTokenInfo(_a);
    }

    /// @notice This returns all of the fields for our stablecoin token.
    /// @return string of the token's symbol.
    /// @return uint of the token's magnitude.
    /// @return uint of the token's exchange rate to ETH.
    /// @return bool whether the token is available.
    /// @return bool whether the token is loadable to the TokenCard.
    /// @return bool whether the token is redeemable to the TKN Holder Contract.
    /// @return uint of the lastUpdated time of the token's exchange rate.
    function _getStablecoinInfo() internal view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getStablecoinInfo();
    }

    /// @notice This returns an array of our whitelisted addresses.
    /// @return address[] of our whitelisted tokens.
    function _tokenAddressArray() internal view returns (address[] memory) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).tokenAddressArray();
    }

    /// @notice This returns an array of all redeemable token addresses.
    /// @return address[] of redeemable tokens.
    function _redeemableTokens() internal view returns (address[] memory) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).redeemableTokens();
    }

    /// @notice Update ERC20 token exchange rate.
    /// @param _token ERC20 token contract address.
    /// @param _rate ERC20 token exchange rate in wei.
    /// @param _updateDate date for the token updates. This will be compared to when oracle updates are received.
    function _updateTokenRate(address _token, uint256 _rate, uint256 _updateDate) internal {
        ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).updateTokenRate(_token, _rate, _updateDate);
    }

    /// @notice based on the method it returns the recipient address and amount/value, ERC20 specific.
    /// @param _data is the transaction payload.
    function _getERC20RecipientAndAmount(address _destination, bytes memory _data) internal view returns (address, uint256) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).getERC20RecipientAndAmount(_destination, _data);
    }

    /// @notice Checks whether a token is available.
    /// @return bool available or not.
    function _isTokenAvailable(address _a) internal view returns (bool) {
        (, , , bool available, , , ) = _getTokenInfo(_a);
        return available;
    }

    /// @notice Checks whether a token is redeemable.
    /// @return bool redeemable or not.
    function _isTokenRedeemable(address _a) internal view returns (bool) {
        (, , , , , bool redeemable, ) = _getTokenInfo(_a);
        return redeemable;
    }

    /// @notice Checks whether a token is loadable.
    /// @return bool loadable or not.
    function _isTokenLoadable(address _a) internal view returns (bool) {
        (, , , , bool loadable, , ) = _getTokenInfo(_a);
        return loadable;
    }

    /// @notice This gets the address of the stablecoin.
    /// @return the address of the stablecoin contract.
    function _stablecoin() internal view returns (address) {
        return ITokenWhitelist(_ensResolve(_tokenWhitelistNode)).stablecoin();
    }
}
"},"tokenWhitelistableExporter.sol":{"content":"pragma solidity ^0.5.17;

import "./tokenWhitelistable.sol";
import "./ensResolvable.sol";


contract TokenWhitelistableExporter is ENSResolvable, TokenWhitelistable {
    constructor(address _ens_, bytes32 _tokenWhitelistName_) public ENSResolvable(_ens_) TokenWhitelistable(_tokenWhitelistName_) {}

    function getTokenInfo(address _a) external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return _getTokenInfo(_a);
    }

    function getStablecoinInfo() external view returns (string memory, uint256, uint256, bool, bool, bool, uint256) {
        return _getStablecoinInfo();
    }

    function tokenAddressArray() external view returns (address[] memory) {
        return _tokenAddressArray();
    }

    function redeemableTokens() external view returns (address[] memory) {
        return _redeemableTokens();
    }

    function updateTokenRate(address _token, uint256 _rate, uint256 _updateDate) external {
        return _updateTokenRate(_token, _rate, _updateDate);
    }

    function getERC20RecipientAndAmount(address _destination, bytes calldata _data) external view returns (address, uint256) {
        return _getERC20RecipientAndAmount(_destination, _data);
    }

    function isTokenLoadable(address _a) external view returns (bool) {
        return _isTokenLoadable(_a);
    }

    function isTokenAvailable(address _a) external view returns (bool) {
        return _isTokenAvailable(_a);
    }

    function isTokenRedeemable(address _a) external view returns (bool) {
        return _isTokenRedeemable(_a);
    }
}
"},"transferrable.sol":{"content":"/**
 *  Transferrable - The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./SafeERC20.sol";


/// @title SafeTransfer, allowing contract to withdraw tokens accidentally sent to itself
contract Transferrable {
    using SafeERC20 for ERC20;

    /// @dev This function is used to move tokens sent accidentally to this contract method.
    /// @dev The owner can chose the new destination address
    /// @param _to is the recipient's address.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount to be transferred in base units.
    function _safeTransfer(address payable _to, address _asset, uint256 _amount) internal {
        // address(0) is used to denote ETH
        if (_asset == address(0)) {
            _to.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(_to, _amount);
        }
    }
}
"},"wallet.sol":{"content":"/**
 *  The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./licence.sol";
import "./ownable.sol";
import "./controllable.sol";
import "./balanceable.sol";
import "./transferrable.sol";
import "./ensResolvable.sol";
import "./tokenWhitelistable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ERC165.sol";
import "./ECDSA.sol";


/// @title ControllableOwnable combines Controllable and Ownable
/// @dev providing an additional modifier to check if Owner or Controller
contract ControllableOwnable is Controllable, Ownable {
    /// @dev Check if the sender is the Owner or one of the Controllers
    modifier onlyOwnerOrController() {
        require(_isOwner(msg.sender) || _isController(msg.sender), "only owner||controller");
        _;
    }
}


/// @title SelfCallableOwnable allows either owner or the contract itself to call its functions
/// @dev providing an additional modifier to check if Owner or self is calling
/// @dev the "self" here is used for the meta transactions
contract SelfCallableOwnable is Ownable {
    /// @dev Check if the sender is the Owner or self
    modifier onlyOwnerOrSelf() {
        require(_isOwner(msg.sender) || msg.sender == address(this), "only owner||self");
        _;
    }
}


/// @title AddressWhitelist provides payee-whitelist functionality.
/// @dev This contract will allow the user to maintain a whitelist of addresses
/// @dev These addresses will live outside of the various spend limits
contract AddressWhitelist is ControllableOwnable, SelfCallableOwnable {
    using SafeMath for uint256;

    event AddedToWhitelist(address _sender, address[] _addresses);
    event CancelledWhitelistAddition(address _sender, bytes32 _hash);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);

    event CancelledWhitelistRemoval(address _sender, bytes32 _hash);
    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);

    mapping(address => bool) public whitelistMap;
    address[] public whitelistArray;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public isSetWhitelist;

    /// @dev Check if the provided addresses contain the owner or the zero-address address.
    modifier hasNoOwnerOrZeroAddress(address[] memory _addresses) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!_isOwner(_addresses[i]), "contains owner address");
            require(_addresses[i] != address(0), "contains 0 address");
        }
        _;
    }

    /// @dev Check that neither addition nor removal operations have already been submitted.
    modifier noActiveSubmission() {
        require(!submittedWhitelistAddition && !submittedWhitelistRemoval, "whitelist sumbission pending");
        _;
    }

    /// @dev Cancel pending whitelist addition.
    function cancelWhitelistAddition(bytes32 _hash) external onlyOwnerOrController {
        // Check if operation has been submitted.
        require(submittedWhitelistAddition, "no pending submission");
        // Require that confirmation hash and the hash of the pending whitelist addition match
        require(_hash == calculateHash(_pendingWhitelistAddition), "non-matching pending whitelist hash");
        // Reset pending addresses.
        delete _pendingWhitelistAddition;
        // Reset the submitted operation flag.
        submittedWhitelistAddition = false;
        // Emit the cancellation event.
        emit CancelledWhitelistAddition(msg.sender, _hash);
    }

    /// @dev Cancel pending removal of whitelisted addresses.
    function cancelWhitelistRemoval(bytes32 _hash) external onlyOwnerOrController {
        // Check if operation has been submitted.
        require(submittedWhitelistRemoval, "no pending submission");
        // Require that confirmation hash and the hash of the pending whitelist removal match
        require(_hash == calculateHash(_pendingWhitelistRemoval), "non-matching pending whitelist hash");
        // Reset pending addresses.
        delete _pendingWhitelistRemoval;
        // Reset pending addresses.
        submittedWhitelistRemoval = false;
        // Emit the cancellation event.
        emit CancelledWhitelistRemoval(msg.sender, _hash);
    }

    /// @dev Confirm pending whitelist addition.
    /// @dev This will only ever be applied post 2FA, by one of the Controllers
    /// @param _hash is the hash of the pending whitelist array, a form of lamport lock
    function confirmWhitelistAddition(bytes32 _hash) external onlyController {
        // Require that the whitelist addition has been submitted.
        require(submittedWhitelistAddition, "no pending submission");
        // Require that confirmation hash and the hash of the pending whitelist addition match
        require(_hash == calculateHash(_pendingWhitelistAddition), "non-matching pending whitelist hash");
        // Whitelist pending addresses.
        for (uint256 i = 0; i < _pendingWhitelistAddition.length; i++) {
            // check if it doesn't exist already.
            if (!whitelistMap[_pendingWhitelistAddition[i]]) {
                // add to the Map and the Array
                whitelistMap[_pendingWhitelistAddition[i]] = true;
                whitelistArray.push(_pendingWhitelistAddition[i]);
            }
        }
        // Emit the addition event.
        emit AddedToWhitelist(msg.sender, _pendingWhitelistAddition);
        // Reset pending addresses.
        delete _pendingWhitelistAddition;
        // Reset the submission flag.
        submittedWhitelistAddition = false;
    }

    /// @dev Confirm pending removal of whitelisted addresses.
    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {
        // Require that the pending whitelist is not empty and the operation has been submitted.
        require(submittedWhitelistRemoval, "no pending submission");
        // Require that confirmation hash and the hash of the pending whitelist removal match
        require(_hash == calculateHash(_pendingWhitelistRemoval), "non-matching pending whitelist hash");
        // Remove pending addresses.
        for (uint256 i = 0; i < _pendingWhitelistRemoval.length; i++) {
            // check if it exists
            if (whitelistMap[_pendingWhitelistRemoval[i]]) {
                whitelistMap[_pendingWhitelistRemoval[i]] = false;
                for (uint256 j = 0; j < whitelistArray.length.sub(1); j++) {
                    if (whitelistArray[j] == _pendingWhitelistRemoval[i]) {
                        whitelistArray[j] = whitelistArray[whitelistArray.length - 1];
                        break;
                    }
                }
                whitelistArray.length--;
            }
        }
        // Emit the removal event.
        emit RemovedFromWhitelist(msg.sender, _pendingWhitelistRemoval);
        // Reset pending addresses.
        delete _pendingWhitelistRemoval;
        // Reset the submission flag.
        submittedWhitelistRemoval = false;
    }

    /// @dev Getter for pending addition array.
    function pendingWhitelistAddition() external view returns (address[] memory) {
        return _pendingWhitelistAddition;
    }

    /// @dev Getter for pending removal array.
    function pendingWhitelistRemoval() external view returns (address[] memory) {
        return _pendingWhitelistRemoval;
    }

    /// @dev Add initial addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function setWhitelist(address[] calldata _addresses) external onlyOwnerOrSelf hasNoOwnerOrZeroAddress(_addresses) {
        // Require that the whitelist has not been initialized.
        require(!isSetWhitelist, "whitelist initialized");
        // Add each of the provided addresses to the whitelist.
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Dedup addresses before writing to the whitelist
            if (!whitelistMap[_addresses[i]]) {
                // adds to the whitelist mapping
                whitelistMap[_addresses[i]] = true;
                // adds to the whitelist array
                whitelistArray.push(_addresses[i]);
            }
        }
        isSetWhitelist = true;
        // Emit the addition event.
        emit AddedToWhitelist(msg.sender, whitelistArray);
    }

    /// @dev Add addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function submitWhitelistAddition(address[] calldata _addresses) external onlyOwnerOrSelf noActiveSubmission hasNoOwnerOrZeroAddress(_addresses) {
        // Require that the whitelist has been initialized.
        require(isSetWhitelist, "whitelist not initialized");
        // Require this array of addresses not empty
        require(_addresses.length > 0, "empty whitelist");
        // Set the provided addresses to the pending addition addresses.
        _pendingWhitelistAddition = _addresses;
        // Flag the operation as submitted.
        submittedWhitelistAddition = true;
        // Emit the submission event.
        emit SubmittedWhitelistAddition(_addresses, calculateHash(_addresses));
    }

    /// @dev Remove addresses from the whitelist.
    /// @param _addresses are the Ethereum addresses to be removed.
    function submitWhitelistRemoval(address[] calldata _addresses) external onlyOwnerOrSelf noActiveSubmission {
        // Require that the whitelist has been initialized.
        require(isSetWhitelist, "whitelist not initialized");
        // Require that the array of addresses is not empty
        require(_addresses.length > 0, "empty whitelist");
        // Add the provided addresses to the pending addition list.
        _pendingWhitelistRemoval = _addresses;
        // Flag the operation as submitted.
        submittedWhitelistRemoval = true;
        // Emit the submission event.
        emit SubmittedWhitelistRemoval(_addresses, calculateHash(_addresses));
    }

    /// @dev Method used to hash our whitelist address arrays.
    function calculateHash(address[] memory _addresses) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addresses));
    }
}


/// @title DailyLimitTrait This trait allows for daily limits to be included in other contracts.
/// This contract will allow for a DailyLimit object to be instantiated and used.
library DailyLimitTrait {
    using SafeMath for uint256;

    event UpdatedAvailableLimit();

    struct DailyLimit {
        uint256 value;
        uint256 available;
        uint256 limitTimestamp;
        uint256 pending;
        bool controllerConfirmationRequired;
    }

    /// @dev Confirm pending set daily limit operation.
    function _confirmLimitUpdate(DailyLimit storage self, uint256 _amount) internal {
        // Require that pending and confirmed spend limit are the same
        require(self.pending == _amount, "confirmed/submitted limit mismatch");
        // Modify spend limit based on the pending value.
        _modifyLimit(self, self.pending);
    }

    /// @dev Use up amount within the daily limit. Will fail if amount is larger than daily limit.
    function _enforceLimit(DailyLimit storage self, uint256 _amount) internal {
        // Account for the spend limit daily reset.
        _updateAvailableLimit(self);
        require(self.available >= _amount, "available<amount");
        self.available = self.available.sub(_amount);
    }

    /// @dev Returns the available daily balance - accounts for daily limit reset.
    /// @return amount of available to spend within the current day in base units.
    function _getAvailableLimit(DailyLimit storage self) internal view returns (uint256) {
        if (now > self.limitTimestamp.add(24 hours)) {
            return self.value;
        } else {
            return self.available;
        }
    }

    /// @dev Modify the spend limit and spend available based on the provided value.
    /// @dev _amount is the daily limit amount in wei.
    function _modifyLimit(DailyLimit storage self, uint256 _amount) private {
        // Account for the spend limit daily reset.
        _updateAvailableLimit(self);
        // Set the daily limit to the provided amount.
        self.value = _amount;
        // Lower the available limit if it's higher than the new daily limit.
        if (self.available > self.value) {
            self.available = self.value;
        }
    }

    /// @dev Set the daily limit.
    /// @param _amount is the daily limit amount in base units.
    function _setLimit(DailyLimit storage self, uint256 _amount) internal {
        // Require that the spend limit has not been set yet.
        require(!self.controllerConfirmationRequired, "limit already set");
        // Modify spend limit based on the provided value.
        _modifyLimit(self, _amount);
        // Flag the operation as set.
        self.controllerConfirmationRequired = true;
    }

    /// @dev Submit a daily limit update, needs to be confirmed.
    /// @param _amount is the daily limit amount in base units.
    function _submitLimitUpdate(DailyLimit storage self, uint256 _amount) internal {
        // Require that the spend limit has been set.
        require(self.controllerConfirmationRequired, "limit hasn't been set yet");
        // Assign the provided amount to pending daily limit.
        self.pending = _amount;
    }

    /// @dev Update available spend limit based on the daily reset.
    function _updateAvailableLimit(DailyLimit storage self) private {
        if (now > self.limitTimestamp.add(24 hours)) {
            // Update the current timestamp.
            self.limitTimestamp = now;
            // Set the available limit to the current spend limit.
            self.available = self.value;
            emit UpdatedAvailableLimit();
        }
    }
}


/// @title  it provides daily spend limit functionality.
contract SpendLimit is ControllableOwnable, SelfCallableOwnable {
    event SetSpendLimit(address _sender, uint256 _amount);
    event SubmittedSpendLimitUpdate(uint256 _amount);

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _spendLimit;

    /// @dev Constructor initializes the daily spend limit in wei.
    constructor(uint256 _limit_) internal {
        _spendLimit = DailyLimitTrait.DailyLimit(_limit_, _limit_, now, 0, false);
    }

    /// @dev Confirm pending set daily limit operation.
    function confirmSpendLimitUpdate(uint256 _amount) external onlyController {
        _spendLimit._confirmLimitUpdate(_amount);
        emit SetSpendLimit(msg.sender, _amount);
    }

    /// @dev Sets the initial daily spend (aka transfer) limit for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function setSpendLimit(uint256 _amount) external onlyOwnerOrSelf {
        _spendLimit._setLimit(_amount);
        emit SetSpendLimit(msg.sender, _amount);
    }

    /// @dev View your available limit
    function spendLimitAvailable() external view returns (uint256) {
        return _spendLimit._getAvailableLimit();
    }

    /// @dev Is there an active spend limit change
    function spendLimitPending() external view returns (uint256) {
        return _spendLimit.pending;
    }

    /// @dev Has the spend limit been initialised
    function spendLimitControllerConfirmationRequired() external view returns (bool) {
        return _spendLimit.controllerConfirmationRequired;
    }

    /// @dev View how much has been spent already
    function spendLimitValue() external view returns (uint256) {
        return _spendLimit.value;
    }

    /// @dev Submit a daily transfer limit update for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function submitSpendLimitUpdate(uint256 _amount) external onlyOwnerOrSelf {
        _spendLimit._submitLimitUpdate(_amount);
        emit SubmittedSpendLimitUpdate(_amount);
    }
}


/// @title GasTopUpLimit provides daily limit functionality.
contract GasTopUpLimit is ControllableOwnable, SelfCallableOwnable {
    event SetGasTopUpLimit(address _sender, uint256 _amount);
    event SubmittedGasTopUpLimitUpdate(uint256 _amount);

    uint256 private constant _MAXIMUM_GAS_TOPUP_LIMIT = 500 finney;
    uint256 private constant _MINIMUM_GAS_TOPUP_LIMIT = 1 finney;

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _gasTopUpLimit;

    /// @dev Constructor initializes the daily gas topup limit in wei.
    constructor() internal {
        _gasTopUpLimit = DailyLimitTrait.DailyLimit(_MAXIMUM_GAS_TOPUP_LIMIT, _MAXIMUM_GAS_TOPUP_LIMIT, now, 0, false);
    }

    /// @dev Confirm pending set top up gas limit operation.
    function confirmGasTopUpLimitUpdate(uint256 _amount) external onlyController {
        _gasTopUpLimit._confirmLimitUpdate(_amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }

    /// @dev View your available gas top-up limit
    function gasTopUpLimitAvailable() external view returns (uint256) {
        return _gasTopUpLimit._getAvailableLimit();
    }

    /// @dev Is there an active gas top-up limit change
    function gasTopUpLimitPending() external view returns (uint256) {
        return _gasTopUpLimit.pending;
    }

    /// @dev Has the gas top-up limit been initialised
    function gasTopUpLimitControllerConfirmationRequired() external view returns (bool) {
        return _gasTopUpLimit.controllerConfirmationRequired;
    }

    /// @dev View how much gas top-up has been spent already
    function gasTopUpLimitValue() external view returns (uint256) {
        return _gasTopUpLimit.value;
    }

    /// @dev Sets the daily gas top up limit.
    /// @param _amount is the gas top up amount in wei.
    function setGasTopUpLimit(uint256 _amount) external onlyOwnerOrSelf {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "out of range top-up");
        _gasTopUpLimit._setLimit(_amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }

    /// @dev Submit a daily gas top up limit update.
    /// @param _amount is the daily top up gas limit amount in wei.
    function submitGasTopUpLimitUpdate(uint256 _amount) external onlyOwnerOrSelf {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "out of range top-up");
        _gasTopUpLimit._submitLimitUpdate(_amount);
        emit SubmittedGasTopUpLimitUpdate(_amount);
    }
}


/// @title LoadLimit provides daily load limit functionality.
contract LoadLimit is ControllableOwnable, SelfCallableOwnable, TokenWhitelistable {
    event SetLoadLimit(address _sender, uint256 _amount);
    event SubmittedLoadLimitUpdate(uint256 _amount);

    uint256 private constant _MAXIMUM_STABLECOIN_LOAD_LIMIT = 10000; // USD
    uint256 private _maximumLoadLimit;

    using DailyLimitTrait for DailyLimitTrait.DailyLimit;

    DailyLimitTrait.DailyLimit internal _loadLimit;

    constructor(bytes32 _tokenWhitelistNode_) internal TokenWhitelistable(_tokenWhitelistNode_) {
        (, uint256 stablecoinMagnitude, , , , , ) = _getStablecoinInfo();
        require(stablecoinMagnitude > 0, "no stablecoin");
        _maximumLoadLimit = _MAXIMUM_STABLECOIN_LOAD_LIMIT * stablecoinMagnitude;
        _loadLimit = DailyLimitTrait.DailyLimit(_maximumLoadLimit, _maximumLoadLimit, now, 0, false);
    }

    /// @dev Sets a daily card load limit.
    /// @param _amount is the card load amount in current stablecoin base units.
    function setLoadLimit(uint256 _amount) external onlyOwnerOrSelf {
        require(_amount <= _maximumLoadLimit, "out of range load amount");
        _loadLimit._setLimit(_amount);
        emit SetLoadLimit(msg.sender, _amount);
    }

    /// @dev Submit a daily load limit update.
    /// @param _amount is the daily load limit amount in wei.
    function submitLoadLimitUpdate(uint256 _amount) external onlyOwnerOrSelf {
        require(_amount <= _maximumLoadLimit, "out of range load amount");
        _loadLimit._submitLimitUpdate(_amount);
        emit SubmittedLoadLimitUpdate(_amount);
    }

    /// @dev Confirm pending set load limit operation.
    function confirmLoadLimitUpdate(uint256 _amount) external onlyController {
        _loadLimit._confirmLimitUpdate(_amount);
        emit SetLoadLimit(msg.sender, _amount);
    }

    /// @dev View your available load limit
    function loadLimitAvailable() external view returns (uint256) {
        return _loadLimit._getAvailableLimit();
    }

    /// @dev Is there an active load limit change
    function loadLimitPending() external view returns (uint256) {
        return _loadLimit.pending;
    }

    /// @dev Has the load limit been initialised
    function loadLimitControllerConfirmationRequired() external view returns (bool) {
        return _loadLimit.controllerConfirmationRequired;
    }

    /// @dev View how much laod limit has been spent already
    function loadLimitValue() external view returns (uint256) {
        return _loadLimit.value;
    }
}


/// @title Asset wallet with extra security features, gas top up management and card integration.
contract Wallet is ENSResolvable, GasTopUpLimit, LoadLimit, AddressWhitelist, SpendLimit, ERC165, Transferrable, Balanceable {
    using Address for address;
    using ECDSA for bytes32;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    event BulkTransferred(address _to, address[] _assets);
    event ExecutedRelayedTransaction(bytes _data, bytes _returndata);
    event ExecutedTransaction(address _destination, uint256 _value, bytes _data, bytes _returndata);
    event IncreasedRelayNonce(address _sender, uint256 _currentNonce);
    event LoadedTokenCard(address _asset, uint256 _amount);
    event Received(address _from, uint256 _amount);
    event ToppedUpGas(address _sender, address _owner, uint256 _amount);
    event Transferred(address _to, address _asset, uint256 _amount);
    event UpdatedAvailableLimit(); // This is here because our tests don't inherit events from a library

    string public constant WALLET_VERSION = "3.2.0";

    // keccak256("isValidSignature(bytes,bytes)") = 20c13b0bc670c284a9f19cdf7a533ca249404190f8dc132aac33e733b965269e
    bytes4 private constant _EIP_1271 = 0x20c13b0b;
    // keccak256("isValidSignature(bytes32,bytes)") = 1626ba7e356f5979dd355a3d2bfb43e80420a480c3b854edce286a82d7496869
    bytes4 private constant _EIP_1654 = 0x1626ba7e;

    /// @dev Supported ERC165 interface ID.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7; // solium-disable-line uppercase

    /// @dev this is an internal nonce to prevent replay attacks from relayer
    uint256 public relayNonce;

    /// @dev Is the registered ENS node identifying the licence contract.
    bytes32 private _licenceNode;

    /// @dev Constructor initializes the wallet top up limit and the vault contract.
    /// @param _owner_ is the owner account of the wallet contract.
    /// @param _transferable_ indicates whether the contract ownership can be transferred.
    /// @param _ens_ is the address of the ENS registry.
    /// @param _tokenWhitelistNode_ is the ENS name node of the Token whitelist.
    /// @param _controllerNode_ is the ENS name node of the Controller contract.
    /// @param _licenceNode_ is the ENS name node of the Licence contract.
    /// @param _spendLimit_ is the initial spend limit.
    constructor(
        address payable _owner_,
        bool _transferable_,
        address _ens_,
        bytes32 _tokenWhitelistNode_,
        bytes32 _controllerNode_,
        bytes32 _licenceNode_,
        uint256 _spendLimit_
    ) public ENSResolvable(_ens_) SpendLimit(_spendLimit_) Ownable(_owner_, _transferable_) Controllable(_controllerNode_) LoadLimit(_tokenWhitelistNode_) {
        _licenceNode = _licenceNode_;
    }

    /// @dev Checks if the value is not zero.
    modifier isNotZero(uint256 _value) {
        require(_value != 0, "value=0");
        _;
    }

    /// @dev Ether can be deposited from any source, so this contract must be payable by anyone.
    function() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev This is a bulk transfer convenience function, used to migrate contracts.
    /// @notice If any of the transfers fail, this will revert.
    /// @param _to is the recipient's address, can't be the zero (0x0) address: transfer() will revert.
    /// @param _assets is an array of addresses of ERC20 tokens or 0x0 for ether.
    function bulkTransfer(address payable _to, address[] calldata _assets) external onlyOwnerOrSelf {
        // check to make sure that _assets isn't empty
        require(_assets.length != 0, "asset array is empty");
        // This loops through all of the transfers to be made
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 amount = _balance(address(this), _assets[i]);
            // use our safe, daily limit protected transfer
            transfer(_to, _assets[i], amount);
        }

        emit BulkTransferred(_to, _assets);
    }

    /// @dev This function allows for the controller to relay transactions on the owner's behalf,
    /// the relayed message has to be signed by the owner.
    /// @param _nonce only used for relayed transactions, must match the wallet's relayNonce.
    /// @param _data abi encoded data payload.
    /// @param _signature signed prefix + data.
    function executeRelayedTransaction(uint256 _nonce, bytes calldata _data, bytes calldata _signature) external onlyController {
        // Expecting prefixed data ("monolith:") indicating relayed transaction...
        // ...and an Ethereum Signed Message to protect user from signing an actual Tx
        uint256 id;
        assembly {
            id := chainid() //1 for Ethereum mainnet, > 1 for public testnets.
        }
        bytes32 dataHash = keccak256(abi.encodePacked("monolith:", id, address(this), _nonce, _data)).toEthSignedMessageHash();
        // Verify signature validity i.e. signer == owner
        require(isValidSignature(dataHash, _signature) == _EIP_1654, "sig not valid");
        // Verify and increase relayNonce to prevent replay attacks from the relayer
        require(_nonce == relayNonce, "tx replay");
        _increaseRelayNonce();

        // invoke wallet function with an external call
        (bool success, bytes memory returndata) = address(this).call(_data);
        require(success, string(returndata));

        emit ExecutedRelayedTransaction(_data, returndata);
    }

    /// @dev This allows the user to cancel a transaction that was unexpectedly delayed by the relayer
    function increaseRelayNonce() external onlyOwner {
        _increaseRelayNonce();
    }

    /// @dev This bumps the relayNonce and emits an event accordingly
    function _increaseRelayNonce() internal {
        relayNonce++;

        emit IncreasedRelayNonce(msg.sender, relayNonce);
    }

    /// @dev Implements EIP-1271: receives the raw data (bytes)
    ///      https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md
    /// @param _data Arbitrary length data signed on the behalf of address(this)
    /// @param _signature Signature byte array associated with _data
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4) {
        bytes32 dataHash = keccak256(abi.encodePacked(_data));
        // isValidSignature call reverts if not valid.
        require(isValidSignature(dataHash, _signature) == _EIP_1654, "sig not valid");
        return _EIP_1271;
    }

    /// @return licence contract node registered in ENS.
    function licenceNode() external view returns (bytes32) {
        return _licenceNode;
    }

    /// @dev Load a token card with the specified asset amount.
    /// @dev the amount send should be inclusive of the percent licence.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of assets to be transferred in base units.
    function loadTokenCard(address _asset, uint256 _amount) external payable onlyOwnerOrSelf {
        // check if token is allowed to be used for loading the card
        require(_isTokenLoadable(_asset), "token not loadable");
        // Convert token amount to stablecoin value.
        uint256 stablecoinValue = convertToStablecoin(_asset, _amount);
        // Check against the daily spent limit and update accordingly, require that the value is under remaining limit.
        _loadLimit._enforceLimit(stablecoinValue);
        // Get the TKN licenceAddress from ENS
        address licenceAddress = _ensResolve(_licenceNode);
        if (_asset != address(0)) {
            ERC20(_asset).safeApprove(licenceAddress, _amount);
            ILicence(licenceAddress).load(_asset, _amount);
        } else {
            ILicence(licenceAddress).load.value(_amount)(_asset, _amount);
        }

        emit LoadedTokenCard(_asset, _amount);
    }

    /// @dev Checks for interface support based on ERC165.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return _interfaceID == _ERC165_INTERFACE_ID;
    }

    /// @dev Refill owner's gas balance, revert if the transaction amount is too large
    /// @param _amount is the amount of ether to transfer to the owner account in wei.
    function topUpGas(uint256 _amount) external isNotZero(_amount) onlyOwnerOrController {
        // Check against the daily spent limit and update accordingly, require that the value is under remaining limit.
        _gasTopUpLimit._enforceLimit(_amount);
        // Then perform the transfer
        owner().transfer(_amount);
        // Emit the gas top up event.
        emit ToppedUpGas(msg.sender, owner(), _amount);
    }

    /// @dev This function allows for the wallet to send a batch of transactions instead of one,
    /// it calls executeTransaction() so that the daily limit is enforced.
    /// @param _transactionBatch data encoding the transactions to be sent,
    /// following executeTransaction's format i.e. (destination, value, data)
    function batchExecuteTransaction(bytes memory _transactionBatch) public onlyOwnerOrSelf {
        uint256 batchLength = _transactionBatch.length + 32; // because the pos starts from 32
        uint256 remainingBytesLength = _transactionBatch.length; // remaining bytes to be processed
        uint256 pos = 32; //the first 32 bytes denote the byte array length, start from actual data

        address destination; // destination address
        uint256 value; // trasanction value
        uint256 dataLength; // externall call data length
        bytes memory data; // call data

        while (pos < batchLength) {
            // there should always be at least 84 bytes remaining: the minimun #bytes required to encode a Tx
            remainingBytesLength = remainingBytesLength.sub(84);
            assembly {
                // shift right by 96 bits (256 - 160) to get the destination address (and zero the excessive bytes)
                destination := shr(96, mload(add(_transactionBatch, pos)))
                // get value: pos + 20 bytes (destinnation address)
                value := mload(add(_transactionBatch, add(pos, 20)))
                // get data: pos  + 20 (destination address) + 32 (value) bytes
                // the first 32 bytes denote the byte array length
                dataLength := mload(add(_transactionBatch, add(pos, 52)))
                data := add(_transactionBatch, add(pos, 52))
            }
            // pos += 20 + 32 + 32 + dataLength, reverts in case of overflow
            pos = pos.add(dataLength).add(84);
            // revert in case the encoded dataLength is gonna cause an out of bound access
            require(pos <= batchLength, "out of bounds");

            // if length is 0 ignore the data field
            if (dataLength == 0) {
                data = bytes("");
            }
            // call executeTransaction(), if one of them reverts then the whole batch reverts.
            executeTransaction(destination, value, data);
        }
    }

    /// @dev Convert ERC20 token amount to the corresponding ether amount.
    /// @param _token ERC20 token contract address.
    /// @param _amount amount of token in base units.
    function convertToEther(address _token, uint256 _amount) public view returns (uint256) {
        // Store the token in memory to save map entry lookup gas.
        (, uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);
        // If the token exists require that its rate is not zero.
        if (available) {
            require(rate != 0, "rate=0");
            // Safely convert the token amount to ether based on the exchange rate.
            return _amount.mul(rate).div(magnitude);
        }
        return 0;
    }

    /// @dev Convert ether or ERC20 token amount to the corresponding stablecoin amount.
    /// @param _token ERC20 token contract address.
    /// @param _amount amount of token in base units.
    function convertToStablecoin(address _token, uint256 _amount) public view returns (uint256) {
        // avoid the unnecessary calculations if the token to be loaded is the stablecoin itself
        if (_token == _stablecoin()) {
            return _amount;
        }
        uint256 amountToSend = _amount;

        // 0x0 represents ether
        if (_token != address(0)) {
            // convert to eth first, same as convertToEther()
            // Store the token in memory to save map entry lookup gas.
            (, uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);
            // require that token both exists in the whitelist and its rate is not zero.
            require(available, "token not available");
            require(rate != 0, "rate=0");
            // Safely convert the token amount to ether based on the exchangeonly rate.
            amountToSend = _amount.mul(rate).div(magnitude);
        }
        // _amountToSend now is in ether
        // Get the stablecoin's magnitude and its current rate.
        (, uint256 stablecoinMagnitude, uint256 stablecoinRate, bool stablecoinAvailable, , , ) = _getStablecoinInfo();
        // Check if the stablecoin rate is set.
        require(stablecoinAvailable, "token not available");
        require(stablecoinRate != 0, "stablecoin rate=0");
        // Safely convert the token amount to stablecoin based on its exchange rate and the stablecoin exchange rate.
        return amountToSend.mul(stablecoinMagnitude).div(stablecoinRate);
    }

    /// @dev This function allows for the owner to send any transaction from the Wallet to arbitrary addresses
    /// @param _destination address of the transaction
    /// @param _value ETH amount in wei
    /// @param _data transaction payload binary
    function executeTransaction(address _destination, uint256 _value, bytes memory _data) public onlyOwnerOrSelf returns (bytes memory) {
        // If value is send across as a part of this executeTransaction, this will be sent to any payable
        // destination. As a result enforceLimit if destination is not whitelisted.
        if (!whitelistMap[_destination]) {
            _spendLimit._enforceLimit(_value);
        }
        // Check if the destination is a Contract and it is one of our supported tokens
        if (address(_destination).isContract() && _isTokenAvailable(_destination)) {
            // to is the recipient's address and amount is the value to be transferred
            address to;
            uint256 amount;
            (to, amount) = _getERC20RecipientAndAmount(_destination, _data);
            if (!whitelistMap[to]) {
                // If the address (of the token contract, e.g) is not in the TokenWhitelist used by the convert method
                // then etherValue will be zero
                uint256 etherValue = convertToEther(_destination, amount);
                _spendLimit._enforceLimit(etherValue);
            }
            // use callOptionalReturn provided in SafeERC20 in case the ERC20 method
            // returns false instead of reverting!
            ERC20(_destination).callOptionalReturn(_data);

            // if ERC20 call completes, return a boolean "true" as bytes emulating ERC20
            bytes memory b = new bytes(32);
            b[31] = 0x01;

            emit ExecutedTransaction(_destination, _value, _data, b);
            return b;
        }

        (bool success, bytes memory returndata) = _destination.call.value(_value)(_data);
        require(success, string(returndata));

        emit ExecutedTransaction(_destination, _value, _data, returndata);
        // returns all of the bytes returned by _destination contract
        return returndata;
    }

    /// @dev Implements EIP-1654: receives the hashed message(bytes32)
    /// https://github.com/ethereum/EIPs/issues/1654.md
    /// @param _hashedData Hashed data signed on the behalf of address(this)
    /// @param _signature Signature byte array associated with _dataHash
    function isValidSignature(bytes32 _hashedData, bytes memory _signature) public view returns (bytes4) {
        address from = _hashedData.recover(_signature);
        require(_isOwner(from), "invalid signature");
        return _EIP_1654;
    }

    /// @dev Transfers the specified asset to the recipient's address.
    /// @param _to is the recipient's address.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of assets to be transferred in base units.
    function transfer(address payable _to, address _asset, uint256 _amount) public onlyOwnerOrSelf isNotZero(_amount) {
        // Checks if the _to address is not the zero-address
        require(_to != address(0), "destination=0");

        // If address is not whitelisted, take daily limit into account.
        if (!whitelistMap[_to]) {
            // initialize ether value in case the asset is ETH
            uint256 etherValue = _amount;
            // Convert token amount to ether value if asset is an ERC20 token.
            if (_asset != address(0)) {
                etherValue = convertToEther(_asset, _amount);
            }
            // Check against the daily spent limit and update accordingly
            // Check against the daily spent limit and update accordingly, require that the value is under remaining limit.
            _spendLimit._enforceLimit(etherValue);
        }
        // Transfer token or ether based on the provided address.
        _safeTransfer(_to, _asset, _amount);
        // Emit the transfer event.
        emit Transferred(_to, _asset, _amount);
    }
}
"},"walletCache.sol":{"content":"/**
 *  The Consumer Contract Wallet - Wallet Deployer Cache
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./wallet.sol";
import "./ensResolvable.sol";
import "./controllable.sol";


/// @title IWalletCache interface describes a method for poping an already cached wallet
interface IWalletCache {
    function walletCachePop() external returns (Wallet);
}


//// @title Wallet cache with wallet pre-caching functionality.
contract WalletCache is ENSResolvable, Controllable {
    event CachedWallet(Wallet _wallet);

    /*****   Constants   *****/
    // Default values for mainnet ENS
    // licence.tokencard.eth
    bytes32 private constant _DEFAULT_LICENCE_NODE = 0xd0ff8bd67f6e25e4e4b010df582a36a0ee9b78e49afe6cc1cff5dd5a83040330;
    // token-whitelist.tokencard.eth
    bytes32 private constant _DEFAULT_TOKEN_WHITELIST_NODE = 0xe84f90570f13fe09f288f2411ff9cf50da611ed0c7db7f73d48053ffc974d396;
    // wallet-deployer.v3.tokencard.eth
    bytes32 private constant _DEFAULT_WALLET_DEPLOYER_NODE = 0x1d0c0adbe6addd93659446311e0767a56b67d41ef38f0cb66dcf7560d28a5a38;

    bytes32 public licenceNode = _DEFAULT_LICENCE_NODE;
    bytes32 public tokenWhitelistNode = _DEFAULT_TOKEN_WHITELIST_NODE;
    bytes32 public walletDeployerNode = _DEFAULT_WALLET_DEPLOYER_NODE;

    Wallet[] public cachedWallets;

    address public ens;
    uint256 public defaultSpendLimit;

    /// @notice parameters are passed in so that they can be used to construct new instances of the wallet
    /// @dev pass in bytes32 to use the default, production node labels for ENS
    constructor(
        address _ens_,
        uint256 _defaultSpendLimit_,
        bytes32 _controllerNode_,
        bytes32 _licenceNode_,
        bytes32 _tokenWhitelistNode_,
        bytes32 _walletDeployerNode_
    ) public ENSResolvable(_ens_) Controllable(_controllerNode_) {
        ens = _ens_;
        defaultSpendLimit = _defaultSpendLimit_;

        // Set licenceNode or use default
        if (_licenceNode_ != bytes32(0)) {
            licenceNode = _licenceNode_;
        }
        // Set tokenWhitelistNode or use default
        if (_tokenWhitelistNode_ != bytes32(0)) {
            tokenWhitelistNode = _tokenWhitelistNode_;
        }
        // Set walletDeployerNode or use default
        if (_walletDeployerNode_ != bytes32(0)) {
            walletDeployerNode = _walletDeployerNode_;
        }
    }

    modifier onlyWalletDeployer() {
        require(msg.sender == _ensResolve(walletDeployerNode), "not called by wallet-deployer");
        _;
    }

    /// @notice This public method allows anyone to pre-cache wallets
    function cacheWallet() public {
        // the address(uint160()) cast is done as the Wallet owner (1st argument) needs to be payable
        Wallet wallet = new Wallet(
            address(uint160(_ensResolve(walletDeployerNode))),
            true,
            ens,
            tokenWhitelistNode,
            controllerNode(),
            licenceNode,
            defaultSpendLimit
        );
        cachedWallets.push(wallet);

        emit CachedWallet(wallet);
    }

    /// @notice This public method allows only the wallet deployer to pop pre-cached wallets or create a new one in case there aren't any
    function walletCachePop() external onlyWalletDeployer returns (Wallet) {
        if (cachedWallets.length < 1) {
            cacheWallet();
        }

        Wallet wallet = cachedWallets[cachedWallets.length - 1];
        cachedWallets.pop();

        return wallet;
    }

    /// @notice returns the number of pre-cached wallets
    function cachedWalletsCount() external view returns (uint256) {
        return cachedWallets.length;
    }
}
"},"walletDeployer.sol":{"content":"/**
 *  The Consumer Contract Wallet - Wallet Deployer
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.5.17;

import "./wallet.sol";
import "./walletCache.sol";
import "./controllable.sol";


//// @title Wallet deployer with pre-caching if wallets functionality.
contract WalletDeployer is ENSResolvable, Controllable {
    event DeployedWallet(Wallet _wallet, address _owner);
    event MigratedWallet(Wallet _wallet, Wallet _oldWallet, address _owner, uint256 _paid);

    /*****   Constants   *****/
    // Default values for mainnet ENS
    // wallet-cache.v3.tokencard.eth
    bytes32 private constant _DEFAULT_WALLET_CACHE_NODE = 0xaf553cb0d77690819f9d6fbaa04416e1fdcfa01b2a9a833c7a11e6ae0bc1be88;
    bytes32 public walletCacheNode = _DEFAULT_WALLET_CACHE_NODE;

    mapping(address => address) public deployedWallets;

    /// @notice it needs to know to address of the wallet cache

    constructor(address _ens_, bytes32 _controllerNode_, bytes32 _walletCacheNode_) public ENSResolvable(_ens_) Controllable(_controllerNode_) {
        // Set walletCacheNode or use default
        if (_walletCacheNode_ != bytes32(0)) {
            walletCacheNode = _walletCacheNode_;
        }
    }

    /// @notice This function is used to deploy a Wallet for a given owner address
    /// @param _owner is the owner address for the new Wallet to be
    function deployWallet(address payable _owner) external onlyController {
        Wallet wallet = IWalletCache(_ensResolve(walletCacheNode)).walletCachePop();
        emit DeployedWallet(wallet, _owner);

        deployedWallets[_owner] = address(wallet);

        // This sets the changeableOwner boolean to false, i.e. no more change ownership
        wallet.transferOwnership(_owner, false);
    }

    /// @notice This function is used to migrate an owner's security settings from a previous version of the wallet
    /// @param _owner is the owner address for the new Wallet to be
    /// @param _spendLimit is the user's set daily spend limit
    /// @param _gasTopUpLimit is the user's set daily gas top-up limit
    /// @param _whitelistedAddresses is the set of the user's whitelisted addresses
    function migrateWallet(
        address payable _owner,
        Wallet _oldWallet,
        bool _initializedSpendLimit,
        bool _initializedGasTopUpLimit,
        bool _initializedLoadLimit,
        bool _initializedWhitelist,
        uint256 _spendLimit,
        uint256 _gasTopUpLimit,
        uint256 _loadLimit,
        address[] calldata _whitelistedAddresses
    ) external payable onlyController {
        require(deployedWallets[_owner] == address(0x0), "wallet already deployed for owner");
        require(_oldWallet.owner() == _owner, "owner mismatch");

        Wallet wallet = IWalletCache(_ensResolve(walletCacheNode)).walletCachePop();
        emit MigratedWallet(wallet, _oldWallet, _owner, msg.value);

        deployedWallets[_owner] = address(wallet);

        // Sets up the security settings as per the _oldWallet
        if (_initializedSpendLimit) {
            wallet.setSpendLimit(_spendLimit);
        }
        if (_initializedGasTopUpLimit) {
            wallet.setGasTopUpLimit(_gasTopUpLimit);
        }
        if (_initializedLoadLimit) {
            wallet.setLoadLimit(_loadLimit);
        }
        if (_initializedWhitelist) {
            wallet.setWhitelist(_whitelistedAddresses);
        }

        wallet.transferOwnership(_owner, false);

        if (msg.value > 0) {
            _owner.transfer(msg.value);
        }
    }
}
"}}