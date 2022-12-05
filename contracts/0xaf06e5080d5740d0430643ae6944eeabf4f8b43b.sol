{{
  "language": "Solidity",
  "sources": {
    "contracts/TradableNFTs.sol": {
      "content": "//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract TradableNFTs is IERC721Receiver, Pausable, Ownable {
  struct Depositor {
    int256 principal;
    int256 deficit;
    int256 aux;
  }
  int256 public constant PRECISION = 10**15;
  address internal coreBlocksAddress;
  int256 public rendFactor = 0;
  int256 public totalPrincipal = 0;
  uint256 public totalDeposited = 0;
  uint256 public depositPrice = 1 * 10**16;
  uint256 public depositLimit = 250;
  uint256 public transactionLimit = 25;
  int256 public leftNFTs = 0;
  address public adminAddress;
  bool public tradePaused = false;
  bool public depositPaused = false;

  mapping(address => Depositor) public depositorList;
  mapping(address => uint256) public allowedList;
  event Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data,
    uint256 _gas
  );

  event Deposit(uint256 quantity);
  event Trade(uint256 quantity);
  event Withdraw(uint256 quantity);

  modifier onlyAdmin() {
    require(_msgSender() == adminAddress, 'Must be admin');
    _;
  }

  modifier notPausedOrAdmin() {
    require(!paused() || _msgSender() == adminAddress, 'Paused');
    _;
  }

  modifier reachedTransactionLimit(uint256 length) {
    require(
      length <= transactionLimit || _msgSender() == adminAddress,
      'Reached max per transaction'
    );
    _;
  }

  modifier transferIsApproved() {
    require(
      IERC721(coreBlocksAddress).isApprovedForAll(msg.sender, address(this)),
      'Need access to transfer the NFTs'
    );
    _;
  }

  modifier isNFTsOwner(uint256[] memory offeredNFTs) {
    for (uint8 i = 0; i < offeredNFTs.length; i++) {
      require(
        msg.sender == IERC721(coreBlocksAddress).ownerOf(offeredNFTs[i]),
        'Only owner can transfer the NFTs'
      );
    }
    _;
  }

  modifier hasRequestedNFTs(uint256[] memory requestedNFTs) {
    for (uint8 i = 0; i < requestedNFTs.length; i++) {
      require(
        address(this) == IERC721(coreBlocksAddress).ownerOf(requestedNFTs[i]),
        'Requested NFTs not found'
      );
    }
    _;
  }

  constructor(address _coreBlocksAddress, address _admin) {
    require(
      _coreBlocksAddress != address(0) && _admin != address(0),
      '0 address'
    );
    coreBlocksAddress = _coreBlocksAddress;
    adminAddress = _admin;
    transferOwnership(_admin);
  }

  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function toggleTradePause() external onlyAdmin {
    tradePaused = !tradePaused;
  }

  function toggleDepositPause() external onlyAdmin {
    depositPaused = !depositPaused;
  }

  function setAdmin(address _adminAddress) external onlyAdmin {
    require(_adminAddress != address(0), '0 address');
    adminAddress = _adminAddress;
  }

  function _increaseNumber(int256 number) internal pure returns (int256) {
    return number * PRECISION;
  }

  function _decreaseNumber(int256 number) internal pure returns (int256) {
    return number / PRECISION;
  }

  function _calculateDeficit(int256 principal) internal view returns (int256) {
    if (rendFactor == 0) {
      return 0;
    }
    return _decreaseNumber(rendFactor * principal);
  }

  function _calculateRend() internal {
    if (totalPrincipal == 0) {
      rendFactor = 0;
    } else {
      rendFactor += _increaseNumber(PRECISION) / totalPrincipal;
    }
  }

  function _ceil(int256 a, int256 m) internal pure returns (int256) {
    return ((a + m - 1) * m) / m;
  }

  function getNFTBalance(address _depositorAddress)
    public
    view
    returns (int256)
  {
    Depositor memory depositor = depositorList[_depositorAddress];

    if (depositor.principal == 0) return 0 + _decreaseNumber(depositor.aux);

    return
      (depositor.principal +
        depositor.aux +
        _decreaseNumber(rendFactor * depositor.principal)) - depositor.deficit;
  }

  function getBalanceFormatted(address _depositorAddress)
    public
    view
    returns (int256)
  {
    return _decreaseNumber(getNFTBalance(_depositorAddress));
  }

  function getFullBalance(address _depositorAddress)
    external
    view
    returns (
      int256 balance,
      int256 balanceFormatted,
      int256 principal,
      int256 principalTotal
    )
  {
    Depositor memory depositor = depositorList[_depositorAddress];
    balance = getNFTBalance(_depositorAddress);
    balanceFormatted = getBalanceFormatted(_depositorAddress);
    principal = depositor.principal;
    principalTotal = totalPrincipal;
  }

  function getOwnerBalance() external view returns (int256) {
    return leftNFTs;
  }

  function setDepositPrice(uint256 price) external onlyAdmin {
    depositPrice = price;
  }

  function setDepositLimit(uint256 newLimit) external onlyAdmin {
    depositLimit = newLimit;
  }

  function setTransactionLimit(uint256 newLimit) external onlyAdmin {
    transactionLimit = newLimit;
  }

  function trade(uint256[] memory offeredNFTs, uint256[] memory requestedNFTs)
    external
    payable
    notPausedOrAdmin
    reachedTransactionLimit(offeredNFTs.length + requestedNFTs.length)
    isNFTsOwner(offeredNFTs)
    transferIsApproved
    hasRequestedNFTs(requestedNFTs)
  {
    require(!tradePaused, 'Trade paused');
    require(
      offeredNFTs.length - 1 == requestedNFTs.length,
      'Requested more than given NFTs'
    );

    _calculateRend();

    if (rendFactor == 0) {
      leftNFTs += _increaseNumber(1);
    }

    totalDeposited += 1;
    emit Trade(offeredNFTs.length);

    for (uint8 i = 0; i < offeredNFTs.length; i++) {
      IERC721(coreBlocksAddress).safeTransferFrom(
        msg.sender,
        address(this),
        offeredNFTs[i]
      );
    }
    for (uint8 i = 0; i < requestedNFTs.length; i++) {
      IERC721(coreBlocksAddress).safeTransferFrom(
        address(this),
        msg.sender,
        requestedNFTs[i]
      );
    }
  }

  function deposit(uint256[] memory depositIds)
    external
    payable
    notPausedOrAdmin
    reachedTransactionLimit(depositIds.length)
    isNFTsOwner(depositIds)
    transferIsApproved
  {
    require(!depositPaused, 'Deposit paused');
    Depositor memory depositor = depositorList[msg.sender];
    require(
      allowedList[msg.sender] > 0 || msg.value >= depositPrice,
      'Insufficient eth sent'
    );
    require(
      uint256(_decreaseNumber(depositor.principal)) + depositIds.length - 1 <=
        depositLimit,
      'Reached deposit limit'
    );
    require(depositIds.length > 1, 'You need to deposit more NFTs');

    int256 bPrincipal = _increaseNumber(int256(depositIds.length) - 1);
    _calculateRend();

    if (rendFactor == 0) {
      leftNFTs += _increaseNumber(1);
    }

    int256 bDeficit = _calculateDeficit(bPrincipal);
    totalDeposited += depositIds.length;
    totalPrincipal += bPrincipal;

    depositorList[msg.sender] = Depositor({
      principal: depositor.principal + bPrincipal,
      deficit: depositor.deficit + bDeficit,
      aux: depositor.aux
    });
    if (allowedList[msg.sender] > 0) {
      allowedList[msg.sender] -= 1;
    }
    emit Deposit(depositIds.length);

    for (uint8 i = 0; i < depositIds.length; i++) {
      IERC721(coreBlocksAddress).safeTransferFrom(
        msg.sender,
        address(this),
        depositIds[i]
      );
    }
  }

  function withdrawNFTs(uint256[] memory requestedNFTs)
    external
    payable
    notPausedOrAdmin
    reachedTransactionLimit(requestedNFTs.length)
    hasRequestedNFTs(requestedNFTs)
  {
    int256 _balance = getBalanceFormatted(msg.sender);
    Depositor memory depositor = depositorList[msg.sender];
    int256 _requestedLength = int256(requestedNFTs.length);
    if (_requestedLength < _balance) {
      require(
        _requestedLength < _decreaseNumber(depositor.principal),
        'Requested need to be < principal or = balance'
      );
    } else {
      require(_requestedLength == _balance, 'Balance doesnt match');
    }

    int256 bRequested = _increaseNumber(_requestedLength);

    if (_requestedLength == _balance) {
      leftNFTs += getNFTBalance(msg.sender) - bRequested;
      totalPrincipal -= depositor.principal;
      delete depositorList[msg.sender];
    } else {
      int256 newPrincipal = depositor.principal - bRequested;
      int256 bDeficit = _calculateDeficit(newPrincipal);
      depositorList[msg.sender].aux =
        getNFTBalance(msg.sender) -
        depositor.principal;
      depositorList[msg.sender].principal = newPrincipal;
      depositorList[msg.sender].deficit = bDeficit;
      totalPrincipal -= bRequested;
    }

    totalDeposited -= requestedNFTs.length;
    emit Withdraw(requestedNFTs.length);

    for (uint8 i = 0; i < requestedNFTs.length; i++) {
      IERC721(coreBlocksAddress).safeTransferFrom(
        address(this),
        msg.sender,
        requestedNFTs[i]
      );
    }
  }

  function withdrawAdminNFTs(uint256[] memory requestedNFTs)
    external
    onlyAdmin
    hasRequestedNFTs(requestedNFTs)
  {
    int256 bRequested = _increaseNumber(int256(requestedNFTs.length));
    if (totalPrincipal == 0) {
      // dev: no deposited nfts and leftNfts > 0 and < 1, ceil the balance to allow admin get the left one Block
      require(bRequested <= _ceil(leftNFTs, PRECISION), 'Balance doesnt match');
    } else {
      // dev: admin never can take an incompleted piece while there is deposited nfts
      require(bRequested <= leftNFTs, 'Balance doesnt match');
    }

    if (leftNFTs - bRequested <= 0) {
      leftNFTs = 0;
    } else {
      leftNFTs -= bRequested;
    }
    totalDeposited -= requestedNFTs.length;

    emit Withdraw(requestedNFTs.length);

    for (uint8 i = 0; i < requestedNFTs.length; i++) {
      IERC721(coreBlocksAddress).safeTransferFrom(
        address(this),
        adminAddress,
        requestedNFTs[i]
      );
    }
  }

  function addToAllowedList(address[] memory _addresses, uint256 _times)
    external
    onlyAdmin
  {
    for (uint8 i = 0; i < _addresses.length; i++) {
      allowedList[_addresses[i]] = _times;
    }
  }

  function withdrawEther() external onlyAdmin {
    uint256 balance = address(this).balance;
    payable(adminAddress).transfer(balance);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) external override returns (bytes4) {
    emit Received(operator, from, tokenId, data, gasleft());
    return IERC721Receiver(address(this)).onERC721Received.selector;
  }
}
"
    },
    "@openzeppelin/contracts/token/ERC721/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
"
    },
    "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
    "@openzeppelin/contracts/security/Pausable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
"
    },
    "@openzeppelin/contracts/utils/introspection/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
      "enabled": false,
      "runs": 200
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