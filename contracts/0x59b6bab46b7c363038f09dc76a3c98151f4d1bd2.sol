{"Context.sol":{"content":"// SPDX-License-Identifier: MIT

// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
"},"GratuitySplitter.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IWolfPack.sol';
import './Ownable.sol';
import './IERC20.sol';
import "./Strings.sol";

contract GratuitySplitter is Ownable {

    using Strings for uint256;

    IWolfPack private WolfPackContract;
    IERC20 private wrappedEth;
    IERC20 private denToken;
    
    address private communityWallet;
    uint256 private _totalReleased;
    uint64 private pullThreshold;

    mapping(address => uint16) private minterToAmountMinted;
    mapping(address => uint256) private _released;

    event GratuityReceived(address from, uint amount);
    event GratuityReleased(address to, uint256 amount);

    function setWolfPackContractAddress(address contractAddress) external onlyOwner {
        WolfPackContract = IWolfPack(contractAddress);
    }

    function setWrappedEthContractAddress(address contractAddress) external onlyOwner {
        wrappedEth = IERC20(contractAddress);
    }

    function setDenTokenContractAddress(address contractAddress) external onlyOwner {
        denToken = IERC20(contractAddress);
    }
    
    function setCommunityWallet(address _address) external onlyOwner {
        communityWallet = _address;
    }

    function getCommunityWallet() external view returns(address) {
        return communityWallet;
    }

    function setPullThreshold(uint64 _pullThreshold) external onlyOwner {
        pullThreshold = _pullThreshold;
    }

    function getPullThreshold() external view returns(uint64) {
        return (pullThreshold / 1000000000000000000);
    }

    function withdrawWETH(address _to) external onlyOwner {
        wrappedEth.transfer(_to, wrappedEth.balanceOf(address(this)));
    }

    function withdrawDEN(address _to) external onlyOwner {
        denToken.transfer(_to, denToken.balanceOf(address(this)));
    }

    receive() external payable virtual {
        emit GratuityReceived(msg.sender, msg.value);
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a member.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function pullGratuity(address payable account) public {
        require(account == msg.sender, "You can only withdraw to your own wallet!");
        require(
            minterToAmountMinted[account] > 0 ||
            WolfPackContract.balanceOf(account) > 0 ||
            account == communityWallet,
            "Account not eligible for withdrawal!"
        );
        uint gratuity = availableWithdrawalBalance(account);
        require(gratuity > 0, "Nothing available to withdraw!");
        require(
            gratuity >= pullThreshold,
            string(
                abi.encodePacked(
                    "You Haven't reached the required threshold yet! The threshold is: ",
                    uint(pullThreshold / 1000000000000000000).toString()
                )
            )
        );

        

        _released[account] += gratuity;
        _totalReleased += gratuity;

        bool success = account.send(gratuity);
        require(success, "Gratuity release didn't go through");
        emit GratuityReleased(account, gratuity);
    }

    function availableWithdrawalBalance(address account) public view returns(uint) {

        uint totalReceived = address(this).balance + _totalReleased;
        uint gratuity;
        uint amountMinted = minterToAmountMinted[account];
        uint balance = _tokenBalance(account);

        if (amountMinted > 0) {
            gratuity += ((totalReceived * 3) * amountMinted) / 11900;
        }
        if (balance > 0) {
            gratuity += ((totalReceived * 2) * balance) / 11900;
        }
        if (account == communityWallet) {
            gratuity += (totalReceived * 2) / 7;
        }
        
        gratuity -= _released[account];
        return gratuity;
    }

    function _tokenBalance(address account) public view returns(uint) {
        uint balance = WolfPackContract.balanceOf(account);
        if (account == communityWallet) {
            return (balance + (1701 - WolfPackContract.getSupply()));
        } else {
            return balance;
        }
    }

    /**
     * @dev Returns an array of the minters.
     *      If they were airdropped it will set it to the team address.
     *      To add a minter for a specific ID, call the WolfPack contract. 
     */
    function mintersList() external view returns(address[] memory) {
        address[] memory minters = new address[](1700);
        for (uint256 i = 1; i <= 1700; i++) {
            if (WolfPackContract.getTokenMinter(i) != address(0)) {
                minters[i] = WolfPackContract.getTokenMinter(i);
            } else {
                minters[i] = communityWallet;
            }
        }
        return minters;
    }

    /**
     * @dev Gets the amount of tokens a minter has minted.
     */
    function amountPerMinter(address _minter) external view returns(uint16) {
        uint16 counter;
        if (_minter == communityWallet) {
            for (uint256 i = 1; i <= 1700; i++) {
                address tokenMinter = WolfPackContract.getTokenMinter(i);
                if (tokenMinter == address(0) || tokenMinter == _minter) {
                    counter += 1;
                }
            }
        } else {
            for (uint256 i = 1; i <= 1700; i++) {
                if (WolfPackContract.getTokenMinter(i) == _minter) {
                    counter += 1;
                }
            }
        }
        return counter;
    }

    /**
     * @dev get minterToAmountMinted mapping
     * @notice this can be used to verify if the token amount per minter is set correctly.
     */
    function getMinterToAmountMinted(address minter) external view returns(uint16) {
        return minterToAmountMinted[minter];
    }

    /**
     * @dev set minterToAmountMinted mapping
     */
    function setMinterToAmountMinted(address minter, uint16 amount) external onlyOwner {
        minterToAmountMinted[minter] = amount;
    }

}
"},"IERC20.sol":{"content":"// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}"},"IWolfPack.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWolfPack {

    function getTokenMinter(uint256 _tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function getSupply() external view returns (uint256);
    
}"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

// source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT

// source: Openzeppelin

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
"}}