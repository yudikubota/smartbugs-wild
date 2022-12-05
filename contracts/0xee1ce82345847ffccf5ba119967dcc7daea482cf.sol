{{
  "language": "Solidity",
  "sources": {
    "contracts/ASCIIGenerator.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract ASCIIGenerator is Ownable {
    using Base64 for string;
    using Strings for uint256;

    uint256 [][] public imageRows;
    string internal description = "MEV Army Legion Banners by x0r are fully on-chain and customizable. Banners are legion owned, and when you customize a banner, it will change for everyone who owns that banner.";
    string internal SVGHeaderPartOne = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1500 550'><defs><style>.cls-1{font-size: 10px; fill:";
    string internal SVGHeaderPartTwo = ";font-family: monospace}</style></defs><g><rect width='1500' height='550' fill='black' />";
    string internal firstTextTagPart = "<text lengthAdjust='spacing' textLength='1500' class='cls-1' x='0' y='";
    string internal SVGFooter = "</g></svg>";
    uint256 internal tspanLineHeight = 12;


    //================== ASCII GENERATOR FUNCTIONS ==================

    /** 
    * @notice Generates full metadata
    */
    function generateMetadata(string memory _legionName, uint256 _legion, string memory _fillChar, string memory _color) public view returns (string memory){
        string memory SVG = generateSVG(_legion, _fillChar, _color);

        string memory metadata = Base64.encode(bytes(string(abi.encodePacked('{"name":"', _legionName, ' Banner','","description":"', description,'","image":"', SVG, '"}'))));
        
        return string(abi.encodePacked('data:application/json;base64,', metadata));
    }

    /** 
    * @notice Generates the SVG image
    */
    function generateSVG(uint256 _legion, string memory _fillChar, string memory _color) public view returns (string memory){

        // generate core ascii text 
        string [45] memory rows = generateCoreAscii(_legion, _fillChar);

        // create SVG header with the text color of the given legion
        string memory SVGHeader = string(abi.encodePacked(SVGHeaderPartOne, _color, SVGHeaderPartTwo));

        // read text tag into memory
        string memory _firstTextTagPart = firstTextTagPart;

        string memory center;
        string memory span;
        uint256 y = tspanLineHeight;

        // generate SVG elements
        for(uint256 i; i < rows.length; i++){
            span = string(abi.encodePacked(_firstTextTagPart, y.toString(), "'>", rows[i], "</text>")); 
            center = string(abi.encodePacked(center, span));
            y += tspanLineHeight;
        }

        // Base64 encode the SVG text 
        string memory SVGImage = Base64.encode(bytes(string(abi.encodePacked(SVGHeader, center, SVGFooter))));
        return string(abi.encodePacked('data:image/svg+xml;base64,', SVGImage));
    }

    /** 
    * @notice Generates all ASCII rows of the image
    */
    function generateCoreAscii(uint256 _legion, string memory _fillChar) public view returns (string [45] memory){
        string [45] memory asciiImage;

        for (uint256 i; i < asciiImage.length; i++) {
            asciiImage[i] = rowToString(imageRows[_legion - 1][i], _fillChar);
        }
        
        return asciiImage;
    }

    /** 
    * @notice Generates one ASCII row as a string
    */
    function rowToString(uint256 _row, string memory _fillchar) internal pure returns (string memory){
        string memory rowString;
        
        for (uint256 i; i < 250; i++) {
            if ( ((_row >> 1 * i) & 1) == 0) {
                rowString = string(abi.encodePacked(rowString, "."));
            } else {
                rowString = string(abi.encodePacked(rowString, _fillchar));
            }
        }

        return rowString;
    }


    
    //================== STORE IMAGE DATA ==================

    function storeImageStores(uint256 [][] memory _imageRows) external onlyOwner {
        imageRows = _imageRows;
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    function setSVGParts(
        uint256 _tspanLineHeight, 
        string calldata _SVGHeaderPartOne, 
        string calldata _SVGHeaderPartTwo,
        string calldata _firstTextTagPart,
        string calldata _SVGFooter) external onlyOwner {
            tspanLineHeight = _tspanLineHeight;
            SVGHeaderPartOne = _SVGHeaderPartOne;
            SVGHeaderPartTwo = _SVGHeaderPartTwo;
            firstTextTagPart = _firstTextTagPart;
            SVGFooter = _SVGFooter;
    }

    function getSVGParts() external view returns (string memory, string memory, string memory, string memory, uint256){
        return (SVGHeaderPartOne, SVGHeaderPartTwo, firstTextTagPart, SVGFooter, tspanLineHeight);
    }

}"
    },
    "@openzeppelin/contracts/utils/Strings.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
"
    },
    "@openzeppelin/contracts/utils/Base64.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 1000
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
    "libraries": {}
  }
}}