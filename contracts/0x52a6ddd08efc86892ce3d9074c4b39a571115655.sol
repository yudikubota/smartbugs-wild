{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
     * imposed by `transfer`, making them unable to receive vaults via
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
"},"Controllable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Profitable.sol";

contract Controllable is Profitable {
    mapping(address => bool) private verifiedControllers;
    uint256 private numControllers = 0;

    event ControllerSet(address account, bool isVerified);
    event DirectRedemption(uint256 punkId, address by, address indexed to);

    function isController(address account) public view returns (bool) {
        return verifiedControllers[account];
    }

    function getNumControllers() public view returns (uint256) {
        return numControllers;
    }

    function setController(address account, bool isVerified)
        public
        onlyOwner
        whenNotLockedM
    {
        require(isVerified != verifiedControllers[account], "Already set");
        if (isVerified) {
            numControllers++;
        } else {
            numControllers--;
        }
        verifiedControllers[account] = isVerified;
        emit ControllerSet(account, isVerified);
    }

    modifier onlyController() {
        require(isController(_msgSender()), "Not a controller");
        _;
    }

    function directRedeem(uint256 tokenId, address to) public onlyController {
        require(getERC20().balanceOf(to) >= 10**18, "ERC20 balance too small");
        bool toSelf = (to == address(this));
        require(
            toSelf || (getERC20().allowance(to, address(this)) >= 10**18),
            "ERC20 allowance too small"
        );
        require(getReserves().contains(tokenId), "Not in holdings");
        getERC20().burnFrom(to, 10**18);
        getReserves().remove(tokenId);
        if (!toSelf) {
            getCPM().transferPunk(to, tokenId);
        }
        emit DirectRedemption(tokenId, _msgSender(), to);
    }
}
"},"CryptoPunksMarket.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

contract CryptoPunksMarket {
    address owner;

    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint256 public punksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint256 => Bid) public punkBids;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(
        address indexed from,
        address indexed to,
        uint256 punkIndex
    );
    event PunkOffered(
        uint256 indexed punkIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event PunkBidEntered(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBidWithdrawn(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBought(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public payable {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        owner = msg.sender;
        totalSupply = 10000; // Update total supply
        punksRemainingToAssign = totalSupply;
        name = "CRYPTOPUNKS"; // Set the name for display purposes
        symbol = "Ï¾"; // Set the symbol for display purposes
        decimals = 0; // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint256 punkIndex) public {
        // require(msg.sender == owner, "msg.sender != owner");
        require(!allPunksAssigned);
        require(punkIndex < 10000);
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != address(0)) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            emit PunkTransfer(address(0), to, punkIndex);
        }
    }

    function setInitialOwners(
        address[] memory addresses,
        uint256[] memory indices
    ) public {
        require(msg.sender == owner);
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() public {
        require(msg.sender == owner);
        allPunksAssigned = true;
    }

    function getPunk(uint256 punkIndex) public {
        // require(allPunksAssigned);
        require(punksRemainingToAssign != 0);
        require(punkIndexToAddress[punkIndex] == address(0));
        require(punkIndex < 10000);
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        emit Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) public {
        // // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
        // Check for the case where there is a bid from the new owner and revault it.
        // Any other bid can stay in place.
        Bid storage bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and revault value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function punkNoLongerForSale(uint256 punkIndex) public {
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            msg.sender,
            0,
            address(0)
        );
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei)
        public
    {
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            address(0)
        );
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public {
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) public payable {
        // require(allPunksAssigned);
        Offer storage offer = punksOfferedForSale[punkIndex];
        require(punkIndex < 10000);
        require(offer.isForSale); // punk not actually for sale
        (offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender); // punk not supposed to be sold to this user
        require(msg.value >= offer.minValue); // Didn't send enough ETH
        require(offer.seller == punkIndexToAddress[punkIndex]); // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and revault it.
        // Any other bid can stay in place.
        Bid storage bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and revault value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function withdraw() public {
        // require(allPunksAssigned);
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending revault before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint256 punkIndex) public payable {
        require(punkIndex < 10000);
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] != address(0));
        require(punkIndexToAddress[punkIndex] != msg.sender);
        require(msg.value != 0);
        Bid storage existing = punkBids[punkIndex];
        require(msg.value > existing.value);
        if (existing.value > 0) {
            // Revault the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) public {
        require(punkIndex < 10000);
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        address seller = msg.sender;
        Bid storage bid = punkBids[punkIndex];
        require(bid.value != 0);
        require(bid.value >= minPrice);

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        emit Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            bid.bidder,
            0,
            address(0)
        );
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint256 punkIndex) public {
        require(punkIndex < 10000);
        // require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] != address(0));
        require(punkIndexToAddress[punkIndex] != msg.sender);
        Bid storage bid = punkBids[punkIndex];
        require(bid.bidder == msg.sender);
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        // Revault the bid money
        msg.sender.transfer(amount);
    }
}
"},"EnumerableSet.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(value)));
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint256(_at(set._inner, index)));
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}
"},"ERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount)
        internal
        virtual
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount)
        internal
        virtual
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _changeName(string memory name_) internal {
        _name = name_;
    }

    function _changeSymbol(string memory symbol_) internal {
        _symbol = symbol_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
    {}
}
"},"ERC20Burnable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}
"},"ICryptoPunksMarket.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

interface ICryptoPunksMarket {
    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(
        address indexed from,
        address indexed to,
        uint256 punkIndex
    );
    event PunkOffered(
        uint256 indexed punkIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event PunkBidEntered(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBidWithdrawn(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBought(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    function setInitialOwner(address to, uint256 punkIndex) external;

    function setInitialOwners(
        address[] calldata addresses,
        uint256[] calldata indices
    ) external;

    function allInitialOwnersAssigned() external;

    function getPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;

    function punkNoLongerForSale(uint256 punkIndex) external;

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei)
        external;

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) external;

    function buyPunk(uint256 punkIndex) external;

    function withdraw() external;

    function enterBidForPunk(uint256 punkIndex) external;

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

    function withdrawBidForPunk(uint256 punkIndex) external;

    function punkIndexToAddress(uint256 punkIndex) external returns (address);
    function punksOfferedForSale(uint256 punkIndex)
        external
        returns (
            bool isForSale,
            uint256 _punkIndex,
            address seller,
            uint256 minValue,
            address onlySellTo
        );

    function balanceOf(address user) external returns (uint256);
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
"},"IXToken.sol":{"content":"// SPDX-License-Identifier: MIT

import "./IERC20.sol";

pragma solidity 0.6.8;

interface IXToken is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function changeName(string calldata name) external;

    function changeSymbol(string calldata symbol) external;

    function setVaultAddress(address vaultAddress) external;
}
"},"Manageable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Randomizable.sol";

contract Manageable is Randomizable {
    event MigrationComplete(address to);
    event TokenNameChange(string name);
    event TokenSymbolChange(string symbol);

    function migrate(address to) public onlyOwner whenNotLockedL {
        uint256 reservesLength = getReserves().length();
        for (uint256 i = 0; i < reservesLength; i++) {
            uint256 tokenId = getReserves().at(i);
            getCPM().transferPunk(to, tokenId);
        }
        emit MigrationComplete(to);
    }

    function changeTokenName(string memory newName)
        public
        onlyOwner
        whenNotLockedM
    {
        getERC20().changeName(newName);
        emit TokenNameChange(newName);
    }

    function changeTokenSymbol(string memory newSymbol)
        public
        onlyOwner
        whenNotLockedM
    {
        getERC20().changeSymbol(newSymbol);
        emit TokenSymbolChange(newSymbol);
    }

    function setReverseLink() public onlyOwner whenNotLockedS {
        getERC20().setVaultAddress(address(this));
    }
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"},"Pausable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";

contract Pausable is Ownable {
    bool private isPaused = false;

    event Paused();
    event Unpaused();

    function getIsPaused() public view returns (bool) {
        return isPaused;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    modifier whenPaused {
        require(isPaused, "Contract is not paused");
        _;
    }

    modifier whenNotPaused {
        require(!isPaused, "Contract is paused");
        _;
    }
}
"},"Profitable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Timelocked.sol";

contract Profitable is Timelocked {
    mapping(address => bool) private verifiedIntegrators;
    uint256 private numIntegrators = 0;
    uint256[] private mintFees = [0, 0, 0];
    uint256[] private burnFees = [0, 0, 0, (5 * 10**18), 20];
    uint256[] private dualFees = [0, 0, 0];

    event MintFeesSet(uint256[] mintFees);
    event BurnFeesSet(uint256[] burnFees);
    event DualFeesSet(uint256[] dualFees);
    event IntegratorSet(address account, bool isVerified);
    event Withdrawal(address to, uint256 amount);

    function getMintFees() public view returns (uint256[] memory) {
        return mintFees;
    }

    function getBurnFees() public view returns (uint256[] memory) {
        return burnFees;
    }

    function getDualFees() public view returns (uint256[] memory) {
        return dualFees;
    }

    function _getMintFees() internal view returns (uint256[] storage) {
        return mintFees;
    }

    function _getBurnFees() internal view returns (uint256[] storage) {
        return burnFees;
    }

    function _getDualFees() internal view returns (uint256[] storage) {
        return dualFees;
    }

    function setMintFees(uint256[] memory newMintFees)
        public
        onlyOwner
        whenNotLockedM
    {
        require(newMintFees.length == 3, "Wrong length");
        mintFees = newMintFees;
        emit MintFeesSet(newMintFees);
    }

    function setBurnFees(uint256[] memory newBurnFees)
        public
        onlyOwner
        whenNotLockedL
    {
        require(newBurnFees.length == 5, "Wrong length");
        burnFees = newBurnFees;
        emit BurnFeesSet(newBurnFees);
    }

    function setDualFees(uint256[] memory newDualFees)
        public
        onlyOwner
        whenNotLockedM
    {
        require(newDualFees.length == 3, "Wrong length");
        dualFees = newDualFees;
        emit DualFeesSet(newDualFees);
    }

    function isIntegrator(address account) public view returns (bool) {
        return verifiedIntegrators[account];
    }

    function getNumIntegrators() public view returns (uint256) {
        return numIntegrators;
    }

    function setIntegrator(address account, bool isVerified)
        public
        onlyOwner
        whenNotLockedM
    {
        require(isVerified != verifiedIntegrators[account], "Already set");
        if (isVerified) {
            numIntegrators = numIntegrators.add(1);
        } else {
            numIntegrators = numIntegrators.sub(1);
        }
        verifiedIntegrators[account] = isVerified;
        emit IntegratorSet(account, isVerified);
    }

    function getFee(address account, uint256 numTokens, uint256[] storage fees)
        internal
        view
        returns (uint256)
    {
        uint256 fee = 0;
        if (verifiedIntegrators[account]) {
            return 0;
        } else if (numTokens == 1) {
            fee = fees[0];
        } else {
            fee = fees[1] + numTokens * fees[2];
        }
        // if this is a burn operation...
        if (fees.length > 3) {
            // if reserves are low...
            uint256 reservesLength = getReserves().length();
            uint256 padding = fees[4];
            if (reservesLength - numTokens <= padding) {
                uint256 addedFee = 0;
                for (uint256 i = 0; i < numTokens; i++) {
                    if (
                        reservesLength - i <= padding && reservesLength - i > 0
                    ) {
                        addedFee += (fees[3] *
                            (padding - (reservesLength - i) + 1));
                    }
                }
                fee += addedFee;
            }
        }
        return fee;
    }

    function withdraw(address payable to) public onlyOwner whenNotLockedM {
        uint256 balance = address(this).balance;
        to.transfer(balance);
        emit Withdrawal(to, balance);
    }
}
"},"Randomizable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Controllable.sol";

contract Randomizable is Controllable {
    uint256 private randNonce = 0;

    function getPseudoRand(uint256 modulus) internal returns (uint256) {
        randNonce = randNonce.add(1);
        return
            uint256(keccak256(abi.encodePacked(now, _msgSender(), randNonce))) %
            modulus;
    }
}
"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the revault on every call to nonReentrant will be lower in
    // amount. Since revaults are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full revault coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a revault is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"},"Timelocked.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./XVaultSafe.sol";
import "./SafeMath.sol";

contract Timelocked is XVaultSafe {
    using SafeMath for uint256;
    enum Timelock {Short, Medium, Long}

    uint256 private securityLevel;

    function getSecurityLevel() public view returns (string memory) {
        if (securityLevel == 0) {
            return "red";
        } else if (securityLevel == 1) {
            return "orange";
        } else if (securityLevel == 2) {
            return "yellow";
        } else {
            return "green";
        }
    }

    function increaseSecurityLevel() public onlyOwner {
        require(securityLevel < 3, "Already max");
        securityLevel = securityLevel + 1;
    }

    function timeInDays(uint256 num) internal pure returns (uint256) {
        return num * 60 * 60 * 24;
    }

    function getDelay(Timelock lockId) public view returns (uint256) {
        if (securityLevel == 0) {
            return 2; // for testing
        }
        if (lockId == Timelock.Short) {
            if (securityLevel == 1) {
                return timeInDays(1);
            } else if (securityLevel == 2) {
                return timeInDays(2);
            } else {
                return timeInDays(3);
            }
        } else if (lockId == Timelock.Medium) {
            if (securityLevel == 1) {
                return timeInDays(2);
            } else if (securityLevel == 2) {
                return timeInDays(3);
            } else {
                return timeInDays(5);
            }
        } else {
            if (securityLevel == 1) {
                return timeInDays(3);
            } else if (securityLevel == 2) {
                return timeInDays(5);
            } else {
                return timeInDays(10);
            }
        }
    }

    mapping(Timelock => uint256) private releaseTimes;

    event Locked(Timelock lockId);

    event UnlockInitiated(Timelock lockId, uint256 whenUnlocked);

    function getReleaseTime(Timelock lockId) public view returns (uint256) {
        return releaseTimes[lockId];
    }

    function initiateUnlock(Timelock lockId) public onlyOwner {
        uint256 newReleaseTime = now.add(getDelay(lockId));
        releaseTimes[lockId] = newReleaseTime;
        emit UnlockInitiated(lockId, newReleaseTime);
    }

    function lock(Timelock lockId) public onlyOwner {
        releaseTimes[lockId] = 0;
        emit Locked(lockId);
    }

    modifier whenNotLockedS {
        uint256 releaseTime = releaseTimes[Timelock.Short];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
    modifier whenNotLockedM {
        uint256 releaseTime = releaseTimes[Timelock.Medium];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
    modifier whenNotLockedL {
        uint256 releaseTime = releaseTimes[Timelock.Long];
        require(releaseTime > 0, "Locked");
        require(now > releaseTime, "Not unlocked");
        _;
    }
}
"},"XToken.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract XToken is Context, Ownable, ERC20Burnable {
    address private vaultAddress;

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        _mint(msg.sender, 0);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function changeName(string memory name) public onlyOwner {
        _changeName(name);
    }

    function changeSymbol(string memory symbol) public onlyOwner {
        _changeSymbol(symbol);
    }

    function getVaultAddress() public view returns (address) {
        return vaultAddress;
    }

    function setVaultAddress(address newAddress) public onlyOwner {
        vaultAddress = newAddress;
    }
}
"},"XVault.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Manageable.sol";

contract XVault is Manageable {
    event TokenMinted(uint256 tokenId, address indexed to);
    event TokensMinted(uint256[] tokenIds, address indexed to);
    event TokenBurned(uint256 tokenId, address indexed to);
    event TokensBurned(uint256[] tokenIds, address indexed to);

    constructor(address erc20Address, address cpmAddress) public {
        setERC20Address(erc20Address);
        setCpmAddress(cpmAddress);
    }

    function getCryptoPunkAtIndex(uint256 index) public view returns (uint256) {
        return getReserves().at(index);
    }

    function getReservesLength() public view returns (uint256) {
        return getReserves().length();
    }

    function isCryptoPunkDeposited(uint256 tokenId) public view returns (bool) {
        return getReserves().contains(tokenId);
    }

    function mintPunk(uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 fee = getFee(_msgSender(), 1, _getMintFees());
        require(msg.value >= fee, "Value too low");
        _mintPunk(tokenId, false);
    }

    function _mintPunk(uint256 tokenId, bool partOfDualOp)
        private
        returns (bool)
    {
        address msgSender = _msgSender();

        require(tokenId < 10000, "tokenId too high");
        (bool forSale, uint256 _tokenId, address seller, uint256 minVal, address buyer) = getCPM()
            .punksOfferedForSale(tokenId);
        require(_tokenId == tokenId, "Wrong punk");
        require(forSale, "Punk not available");
        require(buyer == address(this), "Transfer not approved");
        require(minVal == 0, "Min value not zero");
        require(msgSender == seller, "Sender is not seller");
        require(
            msgSender == getCPM().punkIndexToAddress(tokenId),
            "Sender is not owner"
        );
        getCPM().buyPunk(tokenId);
        getReserves().add(tokenId);
        if (!partOfDualOp) {
            uint256 tokenAmount = 10**18;
            getERC20().mint(msgSender, tokenAmount);
        }
        emit TokenMinted(tokenId, _msgSender());
        return true;
    }

    function mintPunkMultiple(uint256[] memory tokenIds)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), tokenIds.length, _getMintFees());
        require(msg.value >= fee, "Value too low");
        _mintPunkMultiple(tokenIds, false);
    }

    function _mintPunkMultiple(uint256[] memory tokenIds, bool partOfDualOp)
        private
        returns (uint256)
    {
        require(tokenIds.length > 0, "No tokens");
        require(tokenIds.length <= 100, "Over 100 tokens");
        uint256[] memory newTokenIds = new uint256[](tokenIds.length);
        uint256 numNewTokens = 0;
        address msgSender = _msgSender();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId < 10000, "tokenId too high");
            (bool forSale, uint256 _tokenId, address seller, uint256 minVal, address buyer) = getCPM()
                .punksOfferedForSale(tokenId);
            bool rightToken = _tokenId == tokenId;
            bool isApproved = buyer == address(this);
            bool priceIsZero = minVal == 0;
            bool isSeller = msgSender == seller;
            bool isOwner = msgSender == getCPM().punkIndexToAddress(tokenId);
            if (
                forSale &&
                rightToken &&
                isApproved &&
                priceIsZero &&
                isSeller &&
                isOwner
            ) {
                getCPM().buyPunk(tokenId);
                getReserves().add(tokenId);
                newTokenIds[numNewTokens] = tokenId;
                numNewTokens = numNewTokens.add(1);
            }
        }
        if (numNewTokens > 0) {
            if (!partOfDualOp) {
                uint256 tokenAmount = numNewTokens * (10**18);
                getERC20().mint(msgSender, tokenAmount);
            }
            emit TokensMinted(newTokenIds, msgSender);
        }
        return numNewTokens;
    }

    function redeemPunk() public payable nonReentrant whenNotPaused {
        uint256 fee = getFee(_msgSender(), 1, _getBurnFees());
        require(msg.value >= fee, "Value too low");
        _redeemPunk(false);
    }

    function _redeemPunk(bool partOfDualOp) private {
        address msgSender = _msgSender();
        uint256 tokenAmount = 10**18;
        require(
            partOfDualOp || (getERC20().balanceOf(msgSender) >= tokenAmount),
            "ERC20 balance too small"
        );
        require(
            partOfDualOp ||
                (getERC20().allowance(msgSender, address(this)) >= tokenAmount),
            "ERC20 allowance too small"
        );
        uint256 reservesLength = getReserves().length();
        uint256 randomIndex = getPseudoRand(reservesLength);
        uint256 tokenId = getReserves().at(randomIndex);
        if (!partOfDualOp) {
            getERC20().burnFrom(msgSender, tokenAmount);
        }
        getReserves().remove(tokenId);
        getCPM().transferPunk(msgSender, tokenId);
        emit TokenBurned(tokenId, msgSender);
    }

    function redeemPunkMultiple(uint256 numTokens)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), numTokens, _getBurnFees());
        require(msg.value >= fee, "Value too low");
        _redeemPunkMultiple(numTokens, false);
    }

    function _redeemPunkMultiple(uint256 numTokens, bool partOfDualOp) private {
        require(numTokens > 0, "No tokens");
        require(numTokens <= 100, "Over 100 tokens");
        address msgSender = _msgSender();
        uint256 tokenAmount = numTokens * (10**18);
        require(
            partOfDualOp || (getERC20().balanceOf(msgSender) >= tokenAmount),
            "ERC20 balance too small"
        );
        require(
            partOfDualOp ||
                (getERC20().allowance(msgSender, address(this)) >= tokenAmount),
            "ERC20 allowance too small"
        );
        if (!partOfDualOp) {
            getERC20().burnFrom(msgSender, tokenAmount);
        }
        uint256[] memory tokenIds = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 reservesLength = getReserves().length();
            uint256 randomIndex = getPseudoRand(reservesLength);
            uint256 tokenId = getReserves().at(randomIndex);
            tokenIds[i] = tokenId;
            getReserves().remove(tokenId);
            getCPM().transferPunk(msgSender, tokenId);
        }
        emit TokensBurned(tokenIds, msgSender);
    }

    function mintAndRedeem(uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), 1, _getDualFees());
        require(msg.value >= fee, "Value too low");
        require(_mintPunk(tokenId, true), "Minting failed");
        _redeemPunk(true);
    }

    function mintAndRedeemMultiple(uint256[] memory tokenIds)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 numTokens = tokenIds.length;
        require(numTokens > 0, "No tokens");
        require(numTokens <= 20, "Over 20 tokens");
        uint256 fee = getFee(_msgSender(), numTokens, _getDualFees());
        require(msg.value >= fee, "Value too low");
        uint256 numTokensMinted = _mintPunkMultiple(tokenIds, true);
        if (numTokensMinted > 0) {
            _redeemPunkMultiple(numTokens, true);
        }
    }

    function mintRetroactively(uint256 tokenId, address to)
        public
        onlyOwner
        whenNotLockedS
    {
        require(
            getCPM().punkIndexToAddress(tokenId) == address(this),
            "Not owner"
        );
        require(!getReserves().contains(tokenId), "Already in reserves");
        uint256 cryptoPunkBalance = getCPM().balanceOf(address(this));
        require(
            (getERC20().totalSupply() / (10**18)) < cryptoPunkBalance,
            "No excess NFTs"
        );
        getReserves().add(tokenId);
        getERC20().mint(to, 10**18);
        emit TokenMinted(tokenId, _msgSender());
    }

    function redeemRetroactively(address to) public onlyOwner whenNotLockedS {
        require(
            getERC20().balanceOf(address(this)) >= (10**18),
            "Not enough PUNK"
        );
        getERC20().burn(10**18);
        uint256 reservesLength = getReserves().length();
        uint256 randomIndex = getPseudoRand(reservesLength);

        uint256 tokenId = getReserves().at(randomIndex);
        getReserves().remove(tokenId);
        getCPM().transferPunk(to, tokenId);
        emit TokenBurned(tokenId, _msgSender());
    }
}
"},"XVaultBase.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Pausable.sol";
import "./IXToken.sol";
import "./ICryptoPunksMarket.sol";

contract XVaultBase is Pausable {
    address private erc20Address;
    address private cpmAddress;

    IXToken private erc20;
    ICryptoPunksMarket private cpm;

    function getERC20Address() public view returns (address) {
        return erc20Address;
    }

    function getCpmAddress() public view returns (address) {
        return cpmAddress;
    }

    function getERC20() internal view returns (IXToken) {
        return erc20;
    }

    function getCPM() internal view returns (ICryptoPunksMarket) {
        return cpm;
    }

    function setERC20Address(address newAddress) internal {
        require(erc20Address == address(0), "Already initialized ERC20");
        erc20Address = newAddress;
        erc20 = IXToken(erc20Address);
    }

    function setCpmAddress(address newAddress) internal {
        require(cpmAddress == address(0), "Already initialized CPM");
        cpmAddress = newAddress;
        cpm = ICryptoPunksMarket(cpmAddress);
    }
}
"},"XVaultSafe.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./XVaultBase.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";

contract XVaultSafe is XVaultBase, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private reserves;
    bool private inSafeMode = true;

    event TokenBurnedSafely(uint256 punkId, address indexed to);

    function getReserves()
        internal
        view
        returns (EnumerableSet.UintSet storage)
    {
        return reserves;
    }

    function getInSafeMode() public view returns (bool) {
        return inSafeMode;
    }

    function turnOffSafeMode() public onlyOwner {
        inSafeMode = false;
    }

    function turnOnSafeMode() public onlyOwner {
        inSafeMode = true;
    }

    modifier whenNotInSafeMode {
        require(!inSafeMode, "Contract is in safe mode");
        _;
    }

    function simpleRedeem() public whenPaused nonReentrant {
        require(
            getERC20().balanceOf(msg.sender) >= 10**18,
            "ERC20 balance too small"
        );
        require(
            getERC20().allowance(msg.sender, address(this)) >= 10**18,
            "ERC20 allowance too small"
        );
        uint256 tokenId = reserves.at(0);
        getERC20().burnFrom(msg.sender, 10**18);
        reserves.remove(tokenId);
        getCPM().transferPunk(msg.sender, tokenId);
        emit TokenBurnedSafely(tokenId, msg.sender);
    }
}
"}}