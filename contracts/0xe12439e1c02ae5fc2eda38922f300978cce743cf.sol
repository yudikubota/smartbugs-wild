{{
  "language": "Solidity",
  "sources": {
    "contracts/KryptoWriteAd.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './PausableNFT.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * It aint much, but it's honest work.
 */
contract KryptoWriteAd is PausableNFT, Ownable {
  using Address for address;
  using SafeMath for uint256;

  // uint256 constant CONTRACT_SHARE_TENTHS = 1; // implicit
  uint256 constant MINTER_SHARE_TENTHS = 2;
  uint256 constant PREVIOUS_OWNER_SHARE_TENTHS = 7;

  uint256 public discountLimit = 5; // x -> every x is free.
  uint256 public mintingCost;

  bool private reEntrancyLocked = false;

  constructor(
    uint88 _gasCompensation,
    uint96 _initialTokenPrice,
    uint256 _mintingCost,
    uint8 _priceIncreaseTenths
  ) {
    gasCompensation = _gasCompensation;
    initialTokenPrice = _initialTokenPrice;
    mintingCost = _mintingCost;
    priceIncreaseTenths = _priceIncreaseTenths;
  }

  function buy(uint256 _id) external payable {
    require(!reEntrancyLocked);
    reEntrancyLocked = true;

    require(_id < nextTokenId);

    TokenInfo storage info = tokenInfo[_id];

    uint256 newPrice = _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease));
    uint256 total = newPrice.add(uint256(info.previousGasCompensation));
    _bought(info.owner, msg.sender, _id, total);
    require(msg.value >= total);

    uint256 refund = msg.value.sub(total);

    if (refund > 0) {
      (bool refundSuccess, ) = msg.sender.call{value: refund}('');
      require(refundSuccess);
    }

    uint256 previousPrice = uint256(info.previousPrice);
    uint256 previousGasCompensation = uint256(info.previousGasCompensation);
    address previousOwner = info.owner;
    uint256 priceIncrease = newPrice.sub(previousPrice);

    info.owner = msg.sender;
    info.previousPrice = _toUint96(newPrice);
    info.previousPriceIncrease = priceIncreaseTenths;
    info.previousGasCompensation = gasCompensation;

    info.minter.call{value: _multiplyByTenths(priceIncrease, MINTER_SHARE_TENTHS)}('');
    previousOwner.call{
      value: previousPrice.add(_multiplyByTenths(priceIncrease, PREVIOUS_OWNER_SHARE_TENTHS)).add(
        previousGasCompensation
      )
    }('');

    reEntrancyLocked = false;
  }

  function buyMany(uint256[] memory ids) external payable {
    require(!reEntrancyLocked);
    reEntrancyLocked = true;
    require(ids.length > 0);

    uint256 totalCost = 0;

    for (uint256 i = 0; i < ids.length; i++) {
      require(ids[i] < nextTokenId);
      TokenInfo storage info = tokenInfo[ids[i]];

      uint256 newPrice = _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease));
      uint256 total = newPrice.add(uint256(info.previousGasCompensation));
      _bought(info.owner, msg.sender, ids[i], total);
      totalCost = totalCost.add(total);

      uint256 previousPrice = info.previousPrice;
      uint256 previousGasCompensation = uint256(info.previousGasCompensation);
      address previousOwner = info.owner;
      uint256 priceIncrease = newPrice.sub(previousPrice);

      info.owner = msg.sender;
      info.previousPrice = _toUint96(newPrice);
      info.previousPriceIncrease = priceIncreaseTenths;
      info.previousGasCompensation = gasCompensation;

      info.minter.call{value: _multiplyByTenths(priceIncrease, MINTER_SHARE_TENTHS)}('');
      previousOwner.call{
        value: previousPrice.add(_multiplyByTenths(priceIncrease, PREVIOUS_OWNER_SHARE_TENTHS)).add(
          previousGasCompensation
        )
      }('');
    }
    require(msg.value >= totalCost, 'payment too low');

    uint256 refund = msg.value.sub(totalCost);
    if (refund > 0) {
      (bool refundSuccess, ) = msg.sender.call{value: refund}('');
      require(refundSuccess, 'could not refund');
    }

    reEntrancyLocked = false;
  }

  function calcBuyCost(uint256 id) external view returns (uint256) {
    TokenInfo storage info = tokenInfo[id];
    return
      _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease)).add(
        uint256(info.previousGasCompensation)
      );
  }

  function calcMintManyCost(uint256 amount) public view returns (uint256) {
    if (mintingCost == 0) {
      return 0;
    }
    if (amount < discountLimit) {
      return amount.mul(mintingCost);
    }

    return amount.sub(amount.div(discountLimit)).mul(mintingCost);
  }

  function mint() external payable {
    require(msg.value == mintingCost, 'payment / token price mismatch');
    _mint(msg.sender);
  }

  function mintMany(uint256 amount) external payable {
    require(amount > 0);
    uint256 cost = calcMintManyCost(amount);
    require(msg.value == cost); // must pay exact. so no refunds necessary.

    for (uint256 i = 0; i < amount; i++) {
      _mint(msg.sender);
    }
  }

  function setGasCompensation(uint88 amount) external onlyOwner {
    require(amount < 2**88);
    gasCompensation = amount;
  }

  function setInitialTokenPrice(uint96 price) external onlyOwner {
    require(price > 0);
    initialTokenPrice = price;
  }

  function setMinterAddress(uint256 id, address newAddress) external {
    TokenInfo storage info = tokenInfo[id];
    require(msg.sender == info.minter && msg.sender != address(0));
    info.minter = newAddress;
  }

  function setMintingCost(uint256 cost) external onlyOwner {
    mintingCost = cost;
  }

  function setMintingDiscountLimit(uint256 limit) external onlyOwner {
    require(limit > 0);
    discountLimit = limit;
  }

  function setPaused(bool status) external onlyOwner {
    if (status) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setPriceIncreaseTenths(uint8 tenths) external onlyOwner {
    require(tenths < 2**8 && tenths >= 11); // price guaranteed to increase by 1.1x or more
    priceIncreaseTenths = tenths;
  }

  function withdraw() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function _multiplyByTenths(uint256 value, uint256 tenths) internal pure returns (uint256) {
    return value.div(10).mul(tenths);
  }
}
"
    },
    "contracts/PausableNFT.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import './NFT.sol';
import './Pausable.sol';

/**
 * @dev NFT with pausable token transfers and minting

 */
abstract contract PausableNFT is NFT, Pausable {
  /**
   * @dev Based on {ERC1155-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer() internal virtual override {
    require(!paused(), 'PausableNFT: token transfer while paused');
  }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "contracts/NFT.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract NFT {
  using SafeMath for uint256;
  using Address for address;

  event Buy(address indexed from, address indexed to, uint256 id, uint256 price);
  event Mint(address indexed account, uint256 id);

  uint88 public gasCompensation; // adjusted so that early buyers may profit while price increase is below gas costs
  uint96 public initialTokenPrice;
  uint256 public nextTokenId = 0;
  uint8 public priceIncreaseTenths;

  struct TokenInfo {
    address minter;
    uint8 previousPriceIncrease;
    uint88 previousGasCompensation;
    address owner;
    uint96 previousPrice;
  }

  mapping(uint256 => TokenInfo) public tokenInfo;

  function _beforeTokenTransfer() internal virtual {}

  /**
   * @dev checks if transfer is allowed and emits Buy
   */
  function _bought(
    address from,
    address to,
    uint256 id,
    uint256 price
  ) internal {
    require(to != address(0), 'Transfer to the zero address');

    _beforeTokenTransfer();
    emit Buy(from, to, id, price);
  }

  /**
   * @dev Creates 1 token and assigns minter, price increase, gas compensation and price
   *
   * Emits a {Mint} event.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account) internal virtual {
    require(account != address(0), 'NFT: mint to the zero address');
    _beforeTokenTransfer();

    tokenInfo[nextTokenId] = TokenInfo(account, priceIncreaseTenths, gasCompensation, account, initialTokenPrice);

    emit Mint(msg.sender, nextTokenId);
    nextTokenId++;
  }

  function _toUint96(uint256 value) internal pure returns (uint96) {
    require(value < 2**96, "_toUint96: value doesn't fit in 96 bits");
    return uint96(value);
  }
}
"
    },
    "contracts/Pausable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
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
  function paused() public view returns (bool) {
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
    require(!_paused, 'Pausable: paused');
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
    require(_paused, 'Pausable: not paused');
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
    // emit Paused(_msgSender());
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
    // emit Unpaused(_msgSender());
  }
}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}