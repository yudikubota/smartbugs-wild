{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

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
"},"IERC165.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
"},"IERC721.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
"},"IERC721Receiver.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
"},"SocialPixel.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

    /**************************************************************************
    * Interfaces & Libraries
    ***************************************************************************/
    import "IERC165.sol";
    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "Address.sol";
    import "Ownable.sol";

    contract SocialPixel is IERC165, IERC721, IERC721Receiver, Ownable {
    using Address for address;

    struct Pixel {
        string message;
        uint256 price;
        bool isSale;
    }


    /**************************************************************************
    * public variables
    ***************************************************************************/
    uint32[10000] public colors; //colors are encoded as rgb in the follow format: 1rrrgggbbb. For example, red is 1255000000.


    /**************************************************************************
    * private variables
    ***************************************************************************/
    //mapping from token ID to Pixel struct
    mapping (uint256 => Pixel) private pixelNumberToPixel;
    
    //mapping from token ID to owner
    mapping (uint256 => address) private pixelNumberToOwner;
    
    //mapping from token ID to approved address
    mapping (uint256 => address) private pixelNumberToApproved;
    
    //mapping from owner to number of owned token
    mapping (address => uint256) private ownerToPixelAmount;
    
    //mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private ownerToOperatorToBool;
    
    //mapping of supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;




    /**************************************************************************
    * public constants
    ***************************************************************************/
    uint256 public constant numberOfPixels = 10000;
    uint256 public constant feeRate = 100;




    /**************************************************************************
    * private constants
    ***************************************************************************/
    uint256 private defaultWeiPrice = 10000000000000000;   // 0.01 eth
    



    /**************************************************************************
    * modifiers
    ***************************************************************************/
    modifier onlyPixelOwner(uint256 _pixelNumber) {
        require(msg.sender == pixelNumberToOwner[_pixelNumber]);
        _;
    }
    
    modifier validPixel(uint256 _pixelNumber) {
        require(_pixelNumber < numberOfPixels);
        _;
    }
    
    modifier validColor(uint32 _color) {
        require(_color >= 1000000000 && _color <= 1255255255);
        _;
    }



    /**************************************************************************
    * constructor
    ***************************************************************************/
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        ownerToPixelAmount[owner()] = numberOfPixels;
    }



    /**************************************************************************
    * public methods
    ***************************************************************************/
    function getPixel(uint256 _pixelNumber) 
        public view validPixel(_pixelNumber)
        returns(address, string memory, uint256, bool) 
    {
        address pixelOwner = pixelNumberToOwner[_pixelNumber]; 
        
        if (pixelOwner == address(0)) {
            return (owner(), "", defaultWeiPrice, true);
        }
        
        Pixel memory pixel;
        pixel = pixelNumberToPixel[_pixelNumber];
        return (pixelOwner, pixel.message, pixel.price, pixel.isSale);
    }
    
    function getColors() public view returns(uint32[10000] memory)  {
        return colors;
    }

    function buyPixel(uint256 _pixelNumber, uint32 _color, string memory _message)
        payable
        public validColor(_color)
    {
        require(msg.sender != address(0));
        
        address currentOwner;
        uint256 currentPrice;
        bool currentSaleState;
        (currentOwner,,currentPrice, currentSaleState) = getPixel(_pixelNumber);
        
        require(currentSaleState == true);

        require(currentPrice <= msg.value);

        uint fee = msg.value / feeRate;

        payable(currentOwner).transfer(msg.value - fee);

        pixelNumberToPixel[_pixelNumber] = Pixel(_message, currentPrice, false);
        
        colors[_pixelNumber] = _color;
        changeAdjacentColors(_pixelNumber, _color);

        transfer(msg.sender, _pixelNumber);
    }
    
    function setColor(uint256 _pixelNumber, uint32 _color) 
        public validPixel(_pixelNumber) validColor(_color)
        onlyPixelOwner(_pixelNumber)
    {
        colors[_pixelNumber] = _color;
        changeAdjacentColors(_pixelNumber, _color);
    }


    function setMessage(uint256 _pixelNumber, string memory _message)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].message = _message;
    }


    function setPrice(uint256 _pixelNumber, uint256 _weiAmount) 
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].price = _weiAmount;
    }


    function setForSale(uint256 _pixelNumber)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].isSale = true;
    }
    
    function setNotForSale(uint256 _pixelNumber)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].isSale = false;
    }



    /**************************************************************************
    * internal methods
    ***************************************************************************/
    function changeAdjacentColors(uint256 _pixelNumber, uint32 _color) internal {
        
        uint256 i;
        uint256 j;
        
        if (_pixelNumber >= 0 && _pixelNumber < 100) { 
            if (_pixelNumber == 0) {
                j = 3;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else if (_pixelNumber == 99) {
                j = 5;
                i = 2;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                j = 5;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            }
        } else if (_pixelNumber % 100 == 99) { 
            if (_pixelNumber == 9999) {
                i = 4;
                j = 7;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                i = 2;
            j = 7;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
            }
            
        } else if (_pixelNumber >= 9900 && _pixelNumber < 10000 ) { 
            if (_pixelNumber == 9900) {
                i = 6;
                j = 9;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                i = 4;
                j = 9;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            }
        } else if (_pixelNumber % 100 == 0) {
            i = 6;
            j = 11;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
        } else {
            j = 8;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
        }  
    }

    function _changeAdjacentColors(uint256 i, uint256 j, uint256 _pixelNumber, uint32 color) internal {
        
        int256[16] memory offSets = [int256(1), 101, 100, 99, -1, -101, -100, -99, 1, 101, 100, 99, -1, -101, -100, -99];
        
        for (uint256 x = i; x < j; x++) {
            int256 adjPixel = int256(_pixelNumber) + offSets[x];
            colors[uint256(adjPixel)] = mixColors(color, colors[uint256(adjPixel)]);
        }
        
    }
    
    function mixColors(uint32 c0, uint32 c1) internal pure returns (uint32) {
        return 1000000000 + (((c0 / 1000000) % 1000) + ((c1 / 1000000) % 1000))/2*1000000 + (((c0 / 1000) % 1000) + ((c1 / 1000) % 1000))/2*1000 + ((c0 % 1000) + (c1 % 1000))/2;
    }

    /**************************************************************************
    * methods for contract owner
    ***************************************************************************/

    function withdrawBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function setDefaultPrice(uint256 _price) external onlyOwner {
        defaultWeiPrice = _price;
    }

    /**************************************************************************
    * ERC-721 compliance
    ***************************************************************************/

    //Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    //ERC-721 implementation
    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");

        return ownerToPixelAmount[_owner];
    }

    function ownerOf(uint256 _pixelNumber) external override view returns (address) {
        address owner;
        (owner,,,) = getPixel(_pixelNumber);
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _pixelNumber, bytes calldata data) external override  {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner || msg.sender == pixelNumberToApproved[_pixelNumber] || ownerToOperatorToBool[tokenOwner][msg.sender],
                "ERC721: message sender is not the owner or approved address");
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _pixelNumber, data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _pixelNumber) external override  {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner || msg.sender == pixelNumberToApproved[_pixelNumber] || ownerToOperatorToBool[tokenOwner][msg.sender],
                "ERC721: message sender is not the owner or approved address");
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _pixelNumber, "");
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function transferFrom(address _from, address _to, uint256 _pixelNumber) external override {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner ||
                msg.sender == pixelNumberToApproved[_pixelNumber] ||
                ownerToOperatorToBool[tokenOwner][msg.sender]);
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
    }

    function approve(address _approved, uint256 _pixelNumber) external override {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner ||
                msg.sender == pixelNumberToApproved[_pixelNumber] ||
                ownerToOperatorToBool[tokenOwner][msg.sender]);
        pixelNumberToApproved[_pixelNumber] = _approved;

        emit Approval(tokenOwner, _approved, _pixelNumber);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender);

        ownerToOperatorToBool[msg.sender][_operator] = _approved;
        
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _pixelNumber) external override view returns (address) {
        address owner = pixelNumberToOwner[_pixelNumber];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return pixelNumberToApproved[_pixelNumber];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperatorToBool[_owner][_operator];
    }

    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override pure external returns (bytes4) {
         return MAGIC_ON_ERC721_RECEIVED;
    }

    //ERC-721 implementation helper functions
    function transfer(address _to, uint256 _pixelNumber) internal {
        address from;
        (from,,,) = getPixel(_pixelNumber);
        clearApproval(_pixelNumber);

        removeToken(from, _pixelNumber);
        addToken(_to, _pixelNumber);

        emit Transfer(from, _to, _pixelNumber);
    }

    function clearApproval(uint256 _pixelNumber) private {
        if (pixelNumberToApproved[_pixelNumber] != address(0)) {
            delete pixelNumberToApproved[_pixelNumber];
        }
    }

    function removeToken(address _from, uint256 _pixelNumber) internal {
        ownerToPixelAmount[_from] = ownerToPixelAmount[_from] - 1;
        delete pixelNumberToOwner[_pixelNumber];
    }

    function addToken(address _to, uint256 _pixelNumber) internal {
        require(pixelNumberToOwner[_pixelNumber] == address(0));

        pixelNumberToOwner[_pixelNumber] = _to;
        ownerToPixelAmount[_to] = ownerToPixelAmount[_to] + 1;
    }

}"}}