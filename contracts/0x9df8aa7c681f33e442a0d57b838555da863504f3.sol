{"ERC721.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate Fork (https://github.com/distractedm1nd/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

error NotOwner();

// https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}"},"PixelatedLlama.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
   __ _                                               
  / /| | __ _ _ __ ___   __ _/\   /\___ _ __ ___  ___ 
 / / | |/ _` | '_ ` _ \ / _` \ \ / / _ \ '__/ __|/ _ \
/ /__| | (_| | | | | | | (_| |\ V /  __/ |  \__ \  __/
\____/_|\__,_|_| |_| |_|\__,_| \_/ \___|_|  |___/\___|

**/

/// @title Pixelated Llama
/// @author delta devs (https://twitter.com/deltadevelopers)

/// @notice Thrown when attempting to mint while the dutch auction has not started yet.
error AuctionNotStarted();
/// @notice Thrown when attempting to mint whilst the total supply (of either static or animated llamas) has been reached.
error MintedOut();
/// @notice Thrown when the value of the transaction is not enough when attempting to purchase llama during dutch auction or minting post auction.
error NotEnoughEther();

contract PixelatedLlama is ERC721, Ownable {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant provenanceHash = 0x7481a3a60827a9db04e46389b14c42d8f0ba2106ed9b239db8249929a8ab9f0b;

    /// @notice The total supply of Llamas, consisting of both static & animated llamas.
    uint256 public constant totalSupply = 4000;

    /// @notice The total supply cap of animated llamas.
    uint256 public constant animatedSupplyCap = 500;

    /// @notice The total supply cap of static llamas.
    /// @dev This does not mean there are 4000 llamas, it means that 4000 is the last tokenId of a static llama.
    uint256 public constant staticSupplyCap = 4000;

    /// @notice The total supply cap of the dutch auction.
    /// @dev 1600 is the (phase 2) whitelist allocation.
    uint256 public constant auctionSupplyCap = staticSupplyCap - 1600;

    /// @notice The current supply of animated llamas, and a counter for the next static tokenId.
    uint256 public animatedSupply;

    /// @notice The current static supply of llamas, and a counter for the next animated tokenId.
    /// @dev Starts at the animated supply cap, since the first 500 tokenIds are used for the animated llama supply.
    uint256 public staticSupply = animatedSupplyCap;

    /// @notice The UNIX timestamp of the begin of the dutch auction.
    uint256 constant auctionStartTime = 1645628400;

    /// @notice The start price of the dutch auction.
    uint256 public auctionStartPrice = 1.14 ether;

    /// @notice Allocation of static llamas mintable per address.
    /// @dev Used for both free minters in Phase 1, and WL minters after the DA.
    mapping(address => uint256) public staticWhitelist;

    /// @notice Allocation of animated llamas mintable per address.
    /// @dev Not used for the WL phase, only for free mints.
    mapping(address => uint256) public animatedWhitelist;

    /// @notice The mint price of a static llama.
    uint256 public staticPrice;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The base URI which retrieves token metadata.
    string baseURI;

    /// @notice Guarantees that the dutch auction has started.
    /// @dev This also warms up the storage slot for auctionStartTime to save gas in getCurrentTokenPrice
    modifier auctionStarted() {
        if (block.timestamp < auctionStartTime) revert AuctionNotStarted();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _baseURI) ERC721("Pixelated Llama", "PXLLMA") {
        baseURI = _baseURI;
    }

    /*///////////////////////////////////////////////////////////////
                            METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Uploads the number of mintable static llamas for each WL address.
    /// @param addresses The WL addresses.
    function uploadStaticWhitelist(
        address[] calldata addresses
    ) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            staticWhitelist[addresses[i]] = 1;
        }
    }

    /// @notice Uploads the number of mintable static llamas for each WL address.
    /// @param addresses The WL addresses.
    /// @param counts The number of static llamas allocated to the same index in the first array.
    function uploadStaticWhitelist(
        address[] calldata addresses,
        uint256[] calldata counts
    ) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            staticWhitelist[addresses[i]] = counts[i];
        }
    }

    /// @notice Uploads the number of mintable animated llamas for each WL address.
    /// @param addresses The WL addresses.
    /// @param counts The number of animated llamas allocated to the same index in the first array.
    function uploadAnimatedWhitelist(
        address[] calldata addresses,
        uint256[] calldata counts
    ) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            animatedWhitelist[addresses[i]] = counts[i];
        }
    }

    /*///////////////////////////////////////////////////////////////
                            DUTCH AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints one static llama during the dutch auction.
    function mintAuction() public payable auctionStarted {
        if (msg.value < getCurrentTokenPrice()) revert NotEnoughEther();
        if (staticSupply >= auctionSupplyCap) revert MintedOut();
        unchecked {
            _mint(msg.sender, staticSupply);
            staticSupply++;
        }
    }

    /// @notice Calculates the auction price with the accumulated rate deduction since the auction's begin
    /// @return The auction price at the current time, or 0 if the deductions are greater than the auction's start price.
    function validCalculatedTokenPrice() private view returns (uint256) {
        uint256 priceReduction = ((block.timestamp - auctionStartTime) /
            5 minutes) * 0.1 ether;
        return
            auctionStartPrice >= priceReduction
                ? (auctionStartPrice - priceReduction)
                : 0;
    }

    /// @notice Calculates the current dutch auction price, given accumulated rate deductions and a minimum price.
    /// @return The current dutch auction price.
    function getCurrentTokenPrice() public view returns (uint256) {
        return max(validCalculatedTokenPrice(), 0.01 ether);
    }

    /// @notice Returns the price needed for a user to mint the static llamas allocated to him.
    function getWhitelistPrice() public view returns (uint256) {
        return staticPrice * staticWhitelist[msg.sender]; 
    }

    /*///////////////////////////////////////////////////////////////
                            FREE & WL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to set the price for static llamas (after the DA).
    /// @param _staticPrice The new price for a static llama.
    function setStaticPrice(uint256 _staticPrice)
        public
        onlyOwner
    {
        staticPrice = _staticPrice;
    }

    /// @notice Mints all static llamas allocated to the sender, for use by free minters in the first phase, and WL minters post-auction.
    function mintStaticLlama() public payable {
        uint256 count = staticWhitelist[msg.sender];
        if (staticSupply + count > staticSupplyCap) revert MintedOut();
        if (msg.value < staticPrice * count) revert NotEnoughEther();

        unchecked {
            delete staticWhitelist[msg.sender];
            _bulkMint(msg.sender, staticSupply, count);
            staticSupply += count;
        }
    }

    /// @notice Mints all animated llamas allocated to the sender, for use by free minters in the first phase.
    function mintAnimatedLlama() public payable {
        uint256 count = animatedWhitelist[msg.sender];
        if (animatedSupply + count > animatedSupplyCap) revert MintedOut();

        unchecked {
            delete animatedWhitelist[msg.sender];
            _bulkMint(msg.sender, animatedSupply, count);
            animatedSupply += count;
        }
    }

    /// @notice Mints all allocated llamas to the sender in one transaction.
    function bulkMint() public payable {
        mintAnimatedLlama();
        mintStaticLlama();
    }

    /// @notice Mints multiple llamas in bulk.
    /// @param to The address to transfer minted assets to.
    /// @param id The token ID of the first llama that will be minted.
    /// @param count The amount of llamas to be minted.
    function _bulkMint(
        address to,
        uint256 id,
        uint256 count
    ) internal {
        /// @dev We never mint to address(0) so this require is unnecessary.
        // require(to != address(0), "INVALID_RECIPIENT");

        unchecked {
            balanceOf[to] += count;
        }

        for (uint256 i = id; i < id + count; i++) {
            /// @dev The following require has been removed because the tokens mint in succession and this function is no longer called post mint phase.
            // require(ownerOf[i] == address(0), "ALREADY_MINTED");
            ownerOf[i] = to;
            emit Transfer(address(0), to, i);
        }
    }

    /// @notice Withdraws collected funds to the contract owner.
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Permits the contract owner to roll over unminted animated llamas in case of a failed mint-out.
    function rollOverAnimated(address wallet) public onlyOwner {
        uint count = animatedSupplyCap - animatedSupply;
        _bulkMint(wallet, animatedSupply, count);
        unchecked {
            animatedSupply += count;
        }
    }

    /// @notice Permits the contract owner to roll over unminted static llamas in case of a failed mint-out.
    function rollOverStatic(address wallet) public onlyOwner {
        uint count = staticSupplyCap - staticSupply;
        _bulkMint(wallet, staticSupply, count);
        unchecked {
            staticSupply += count;
        }
    }

    /*///////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the greater of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, Ownable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT
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
"}}