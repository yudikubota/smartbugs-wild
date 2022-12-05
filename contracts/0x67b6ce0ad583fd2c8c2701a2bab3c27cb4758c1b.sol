{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "berlin",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "remappings": [],
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
    }
  },
  "sources": {
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

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
"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    },
    "@openzeppelin/contracts/utils/structs/EnumerableSet.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
"
    },
    "contracts/Balance.sol": {
      "content": "// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Balance is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Maximum inspector count.
  uint256 public constant MAXIMUM_INSPECTOR_COUNT = 100;

  /// @notice Maximum consumer count.
  uint256 public constant MAXIMUM_CONSUMER_COUNT = 100;

  /// @notice Maximum accept or reject claims by one call.
  uint256 public constant MAXIMUM_CLAIM_PACKAGE = 500;

  /// @notice Treasury contract
  address payable public treasury;

  /// @dev Inspectors list.
  EnumerableSet.AddressSet internal _inspectors;

  /// @dev Consumers list.
  EnumerableSet.AddressSet internal _consumers;

  /// @notice Account balance.
  mapping(address => uint256) public balanceOf;

  /// @notice Account claim.
  mapping(address => uint256) public claimOf;

  /// @notice Possible statuses that a bill may be in.
  enum BillStatus {
    Pending,
    Accepted,
    Rejected
  }

  struct Bill {
    // Identificator.
    uint256 id;
    // Claimant.
    address claimant;
    // Target account.
    address account;
    // Claim gas fee.
    uint256 gasFee;
    // Claim protocol fee.
    uint256 protocolFee;
    // Current bill status.
    BillStatus status;
  }

  /// @notice Bills.
  mapping(uint256 => Bill) public bills;

  /// @notice Bill count.
  uint256 public billCount;

  event TreasuryChanged(address indexed treasury);

  event InspectorAdded(address indexed inspector);

  event InspectorRemoved(address indexed inspector);

  event ConsumerAdded(address indexed consumer);

  event ConsumerRemoved(address indexed consumer);

  event Deposit(address indexed recipient, uint256 amount);

  event Refund(address indexed recipient, uint256 amount);

  event Claim(address indexed account, uint256 indexed bill, string description);

  event AcceptClaim(uint256 indexed bill);

  event RejectClaim(uint256 indexed bill);

  constructor(address payable _treasury) {
    treasury = _treasury;
  }

  modifier onlyInspector() {
    require(_inspectors.contains(_msgSender()), "Balance: caller is not the inspector");
    _;
  }

  /**
   * @notice Change treasury contract address.
   * @param _treasury New treasury contract address.
   */
  function changeTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasuryChanged(treasury);
  }

  /**
   * @notice Add inspector.
   * @param inspector Added inspector.
   */
  function addInspector(address inspector) external onlyOwner {
    require(!_inspectors.contains(inspector), "Balance::addInspector: inspector already added");
    require(
      _inspectors.length() < MAXIMUM_INSPECTOR_COUNT,
      "Balance::addInspector: inspector must not exceed maximum count"
    );

    _inspectors.add(inspector);

    emit InspectorAdded(inspector);
  }

  /**
   * @notice Remove inspector.
   * @param inspector Removed inspector.
   */
  function removeInspector(address inspector) external onlyOwner {
    require(_inspectors.contains(inspector), "Balance::removeInspector: inspector already removed");

    _inspectors.remove(inspector);

    emit InspectorRemoved(inspector);
  }

  /**
   * @notice Get all inspectors.
   * @return All inspectors addresses.
   */
  function inspectors() external view returns (address[] memory) {
    address[] memory result = new address[](_inspectors.length());

    for (uint256 i = 0; i < _inspectors.length(); i++) {
      result[i] = _inspectors.at(i);
    }

    return result;
  }

  /**
   * @notice Add consumer.
   * @param consumer Added consumer.
   */
  function addConsumer(address consumer) external onlyOwner {
    require(!_consumers.contains(consumer), "Balance::addConsumer: consumer already added");
    require(
      _consumers.length() < MAXIMUM_CONSUMER_COUNT,
      "Balance::addConsumer: consumer must not exceed maximum count"
    );

    _consumers.add(consumer);

    emit ConsumerAdded(consumer);
  }

  /**
   * @notice Remove consumer.
   * @param consumer Removed consumer.
   */
  function removeConsumer(address consumer) external onlyOwner {
    require(_consumers.contains(consumer), "Balance::removeConsumer: consumer already removed");

    _consumers.remove(consumer);

    emit ConsumerRemoved(consumer);
  }

  /**
   * @notice Get all consumers.
   * @return All consumers addresses.
   */
  function consumers() external view returns (address[] memory) {
    address[] memory result = new address[](_consumers.length());

    for (uint256 i = 0; i < _consumers.length(); i++) {
      result[i] = _consumers.at(i);
    }

    return result;
  }

  /**
   * @notice Get net balance of account.
   * @param account Target account.
   * @return Net balance (balance minus claim).
   */
  function netBalanceOf(address account) public view returns (uint256) {
    return balanceOf[account] - claimOf[account];
  }

  /**
   * @notice Deposit ETH to balance.
   * @param recipient Target recipient.
   */
  function deposit(address recipient) external payable {
    require(recipient != address(0), "Balance::deposit: invalid recipient");
    require(msg.value > 0, "Balance::deposit: negative or zero deposit");

    balanceOf[recipient] += msg.value;

    emit Deposit(recipient, msg.value);
  }

  /**
   * @notice Refund ETH from balance.
   * @param amount Refunded amount.
   */
  function refund(uint256 amount) external {
    address payable recipient = payable(_msgSender());
    require(amount > 0, "Balance::refund: negative or zero refund");
    require(amount <= netBalanceOf(recipient), "Balance::refund: refund amount exceeds net balance");

    balanceOf[recipient] -= amount;
    recipient.transfer(amount);

    emit Refund(recipient, amount);
  }

  /**
   * @notice Send claim.
   * @param account Target account.
   * @param gasFee Claim gas fee.
   * @param protocolFee Claim protocol fee.
   * @param description Claim description.
   */
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256) {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == account || _consumers.contains(tx.origin),
      "Balance: caller is not a consumer"
    );

    uint256 amount = gasFee + protocolFee;
    require(amount > 0, "Balance::claim: negative or zero claim");
    require(amount <= netBalanceOf(account), "Balance::claim: claim amount exceeds net balance");

    claimOf[account] += amount;
    billCount++;
    bills[billCount] = Bill(billCount, _msgSender(), account, gasFee, protocolFee, BillStatus.Pending);
    emit Claim(account, billCount, description);

    return billCount;
  }

  /**
   * @notice Accept bills package.
   * @param _bills Target bills.
   * @param gasFees Confirmed claims gas fees by bills.
   * @param protocolFees Confirmed claims protocol fees by bills.
   */
  function acceptClaims(
    uint256[] memory _bills,
    uint256[] memory gasFees,
    uint256[] memory protocolFees
  ) external onlyInspector {
    require(
      _bills.length == gasFees.length && _bills.length == protocolFees.length,
      "Balance::acceptClaims: arity mismatch"
    );
    require(_bills.length <= MAXIMUM_CLAIM_PACKAGE, "Balance::acceptClaims: too many claims");

    uint256 transferredAmount;
    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::acceptClaims: bill not found");

      uint256 gasFee = gasFees[i];
      uint256 protocolFee = protocolFees[i];
      uint256 amount = gasFee + protocolFee;

      Bill storage bill = bills[billId];
      uint256 claimAmount = bill.gasFee + bill.protocolFee;
      require(bill.status == BillStatus.Pending, "Balance::acceptClaims: bill already processed");
      require(amount <= claimAmount, "Balance::acceptClaims: claim amount exceeds max fee");

      bill.status = BillStatus.Accepted;
      bill.gasFee = gasFee;
      bill.protocolFee = protocolFee;
      claimOf[bill.account] -= claimAmount;
      balanceOf[bill.account] -= amount;
      transferredAmount += amount;

      emit AcceptClaim(bill.id);
    }
    treasury.transfer(transferredAmount);
  }

  /**
   * @notice Reject bills package.
   * @param _bills Target bills.
   */
  function rejectClaims(uint256[] memory _bills) external onlyInspector {
    require(_bills.length < MAXIMUM_CLAIM_PACKAGE, "Balance::rejectClaims: too many claims");

    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::rejectClaims: bill not found");

      Bill storage bill = bills[billId];
      require(bill.status == BillStatus.Pending, "Balance::rejectClaims: bill already processed");
      uint256 amount = bill.gasFee + bill.protocolFee;

      bill.status = BillStatus.Rejected;
      claimOf[bill.account] -= amount;

      emit RejectClaim(bill.id);
    }
  }
}
"
    }
  }
}}