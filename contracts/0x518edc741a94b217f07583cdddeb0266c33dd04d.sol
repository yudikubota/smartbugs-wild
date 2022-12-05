{"Context.sol":{"content":"pragma solidity ^0.6.0;
import "./Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}
"},"EnumerableSet.sol":{"content":"pragma solidity ^0.6.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
"},"IERC20.sol":{"content":"pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
"},"Initializable.sol":{"content":"pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
"},"ITorro.sol":{"content":"// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title Interface for ERC-20 Torro governing token.
/// @notice ERC-20 token.
interface ITorro {

  // Initializer.

  /// @notice Initializes governing token.
  /// @param dao_ address of cloned DAO.
  /// @param factory_ address of factory.
  /// @param supply_ total supply of tokens.
  function initializeCustom(address dao_, address factory_, uint256 supply_) external;

  // Public calls.

  /// @notice Token's name.
  /// @return string name of the token.
  function name() external view returns (string memory);

  /// @notice Token's symbol.
  /// @return string symbol of the token.
  function symbol() external view returns (string memory);

  /// @notice Token's decimals.
  /// @return uint8 demials of the token.
  function decimals() external pure returns (uint8);

  /// @notice Token's total supply.
  /// @return uint256 total supply of the token.
  function totalSupply() external view returns (uint256);

  /// @notice Count of token holders.
  /// @return uint256 number of token holders.
  function holdersCount() external view returns (uint256);

  /// @notice All token holders.
  /// @return array of addresses of token holders.
  function holders() external view returns (address[] memory);

  /// @notice Available balance for address.
  /// @param sender_ address to get available balance for.
  /// @return uint256 amount of tokens available for given address.
  function balanceOf(address sender_) external view returns (uint256);

  /// @notice Staked balance for address.
  /// @param sender_ address to get staked balance for.
  /// @return uint256 amount of staked tokens for given address.
  function stakedOf(address sender_) external view returns (uint256);

  /// @notice Total balance for address = available + staked.
  /// @param sender_ address to get total balance for.
  /// @return uint256 total amount of tokens for given address.
  function totalOf(address sender_) external view returns (uint256);

  /// @notice Locked staked balance for address
  /// @param sender_ address to get locked staked balance for.
  /// @return uint256 amount of locked staked tokens for given address.
  function lockedOf(address sender_) external view returns (uint256);

  /// @notice Spending allowance.
  /// @param owner_ token owner address.
  /// @param spender_ token spender address.
  /// @return uint256 amount of owner's tokens that spender can use.
  function allowance(address owner_, address spender_) external view returns (uint256);

  /// @notice Unstaked supply of token.
  /// @return uint256 amount of tokens in circulation that are not staked.
  function unstakedSupply() external view returns (uint256);

  /// @notice Staked supply of token.
  /// @return uint256 amount of tokens in circulation that are staked.
  function stakedSupply() external view returns (uint256);

  // Public transactions.

  /// @notice Transfer tokens to recipient.
  /// @param recipient_ address of tokens' recipient.
  /// @param amount_ amount of tokens to transfer.
  /// @return bool true if successful.
  function transfer(address recipient_, uint256 amount_) external returns (bool);

  /// @notice Approve spender to spend an allowance.
  /// @param spender_ address that will be allowed to spend specified amount of tokens.
  /// @param amount_ amount of tokens that spender can spend.
  /// @return bool true if successful.
  function approve(address spender_, uint256 amount_) external returns (bool);

  /// @notice Approves DAO to spend tokens.
  /// @param owner_ address whose tokens DAO can spend.
  /// @param amount_ amount of tokens that DAO can spend.
  /// @return bool true if successful.
  function approveDao(address owner_, uint256 amount_) external returns (bool);

  /// @notice Locks account's staked tokens.
  /// @param owner_ address whose tokens should be locked.
  /// @param amount_ amount of tokens to lock.
  /// @param id_ lock id.
  function lockStakesDao(address owner_, uint256 amount_, uint256 id_) external;

  /// @notice Unlocks account's staked tokens.
  /// @param owner_ address whose tokens should be unlocked.
  /// @param id_ unlock id.
  function unlockStakesDao(address owner_, uint256 id_) external;

  /// @notice Transfers tokens from owner to recipient by approved spender.
  /// @param owner_ address of tokens' owner whose tokens will be spent.
  /// @param recipient_ address of recipient that will recieve tokens.
  /// @param amount_ amount of tokens to be spent.
  /// @return bool true if successful.
  function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool);

  /// @notice Increases allowance for given spender.
  /// @param spender_ spender to increase allowance for.
  /// @param addedValue_ extra amount that spender can spend.
  /// @return bool true if successful.
  function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool);

  /// @notice Decreases allowance for given spender.
  /// @param spender_ spender to decrease allowance for.
  /// @param subtractedValue_ removed amount that spender can spend.
  /// @return bool true if successful.
  function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool);

  /// @notice Stake tokens.
  /// @param amount_ amount of tokens to be staked.
  /// @return bool true if successful.
  function stake(uint256 amount_) external returns (bool);

  /// @notice Unstake tokens.
  /// @param amount_ amount of tokens to be unstaked.
  /// @return bool true if successful.
  function unstake(uint256 amount_) external returns (bool);

  /// @notice Functionality for DAO to add benefits for all stakers.
  /// @param amount_ amount of wei to be shared among stakers.
  function addBenefits(uint256 amount_) external;

  /// @notice Sets DAO and Factory addresses.
  /// @param dao_ DAO address that this token governs.
  /// @param factory_ Factory address.
  function setDaoFactoryAddresses(address dao_, address factory_) external;

  /// @notice Functionality for owner to burn tokens.
  /// @param amount_ amount of tokens to burn.
  function burn(uint256 amount_) external;
}
"},"ITorroDao.sol":{"content":"// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title DAO for proposals, voting and execution.
/// @notice Interface for creation, voting and execution of proposals.
interface ITorroDao {

  // Enums.

  /// @notice Enum of available proposal functions.
  enum DaoFunction {
    BUY,
    SELL,
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY,
    ADD_ADMIN,
    REMOVE_ADMIN,
    INVEST,
    WITHDRAW,
    BURN,
    SET_SPEND_PCT,
    SET_MIN_PCT,
    SET_QUICK_MIN_PCT,
    SET_MIN_HOURS,
    SET_MIN_VOTES,
    SET_FREE_PROPOSAL_DAYS,
    SET_BUY_LOCK_PER_ETH
  }

  // Initializer.
  
  /// @notice Initializer for DAO clones.
  /// @param torroToken_ main torro token address.
  /// @param governingToken_ torro token clone that's governing this dao.
  /// @param factory_ torro factory address.
  /// @param creator_ creator of cloned DAO.
  /// @param maxCost_ maximum cost of all governing tokens for cloned DAO.
  /// @param executeMinPct_ minimum percentage of votes needed for proposal execution.
  /// @param votingMinHours_ minimum lifetime of proposal before it closes.
  /// @param isPublic_ whether cloned DAO has public visibility.
  /// @param hasAdmins_ whether cloned DAO has admins, otherwise all stakers are treated as admins.
  function initializeCustom(
    address torroToken_,
    address governingToken_,
    address factory_,
    address creator_,
    uint256 maxCost_,
    uint256 executeMinPct_,
    uint256 votingMinHours_,
    bool isPublic_,
    bool hasAdmins_
  ) external;

  // Public calls.

  /// @notice Address of DAO creator.
  /// @return DAO creator address.
  function daoCreator() external view returns (address);

  /// @notice Amount of tokens needed for a single vote.
  /// @return uint256 token amount.
  function voteWeight() external view returns (uint256);

  /// @notice Amount of votes that holder has.
  /// @param sender_ address of the holder.
  /// @return number of votes.
  function votesOf(address sender_) external view returns (uint256);

  /// @notice Address of the governing token.
  /// @return address of the governing token.
  function tokenAddress() external view returns (address);

  /// @notice Saved addresses of tokens that DAO is holding.
  /// @return array of holdings addresses.
  function holdings() external view returns (address[] memory);

  /// @notice Saved addresses of liquidity tokens that DAO is holding.
  /// @return array of liquidity addresses.
  function liquidities() external view returns (address[] memory);

  /// @notice Calculates address of liquidity token from ERC-20 token address.
  /// @param token_ token address to calculate liquidity address from.
  /// @return address of liquidity token.
  function liquidityToken(address token_) external view returns (address);

  /// @notice Gets tokens and liquidity token addresses of DAO's liquidity holdings.
  /// @return Arrays of tokens and liquidity tokens, should have the same length.
  function liquidityHoldings() external view returns (address[] memory, address[] memory);

  /// @notice DAO admins.
  /// @return Array of admin addresses.
  function admins() external view returns (address[] memory);

  /// @notice DAO balance for specified token.
  /// @param token_ token address to get balance for.
  /// @return uint256 token balance.
  function tokenBalance(address token_) external view returns (uint256);

  /// @notice DAO balance for liquidity token.
  /// @param token_ token address to get liquidity balance for.
  /// @return uin256 token liquidity balance.
  function liquidityBalance(address token_) external view returns (uint256);

  /// @notice DAO ethereum balance.
  /// @return uint256 wei balance.
  function availableBalance() external view returns (uint256);

  /// @notice DAO WETH balance.
  /// @return uint256 wei balance.
  function availableWethBalance() external view returns (uint256);

  /// @notice Maximum cost for all tokens of cloned DAO.
  /// @return uint256 maximum cost in wei.
  function maxCost() external view returns (uint256);

  /// @notice Minimum percentage of votes needed to execute a proposal.
  /// @return uint256 minimum percentage of votes.
  function executeMinPct() external view returns (uint256);

  /// @notice Minimum percentage of votes needed for quick execution of proposal.
  /// @return uint256 minimum percentage of votes.
  function quickExecuteMinPct() external returns (uint256);

  /// @notice Minimum lifetime of proposal before it closes.
  /// @return uint256 minimum number of hours for proposal lifetime.
  function votingMinHours() external view returns (uint256);

  /// @notice Minimum votes a proposal needs to pass.
  /// @return uint256 minimum unique votes.
  function minProposalVotes() external view returns (uint256);

  /// @notice Maximum spend limit on BUY, WITHDRAW and INVEST proposals.
  /// @return uint256 maximum percentage of funds that can be spent.
  function spendMaxPct() external view returns (uint256);

  /// @notice Interval at which stakers can create free proposals.
  /// @return uint256 number of days between free proposals.
  function freeProposalDays() external view returns (uint256);

  /// @notice Next free proposal time for staker.
  /// @param sender_ address to check free proposal time for.
  /// @return uint256 unix time of next free proposal or 0 if not available.
  function nextFreeProposal(address sender_) external view returns (uint256);

  /// @notice Amount of tokens that BUY proposal creator has to lock per each ETH spent in a proposal.
  /// @return uint256 number for tokens per eth spent.
  function lockPerEth() external view returns (uint256);

  /// @notice Whether DAO is public or private.
  /// @return bool true if public.
  function isPublic() external view returns (bool);

  /// @notice Whether DAO has admins.
  /// @return bool true if DAO has admins.
  function hasAdmins() external view returns (bool);

  /// @notice Proposal ids of DAO.
  /// @return array of proposal ids.
  function getProposalIds() external view returns (uint256[] memory);

  /// @notice Gets proposal info for proposal id.
  /// @param id_ id of proposal to get info for.
  /// @return proposalAddress address for proposal execution.
  /// @return investTokenAddress secondary address for proposal execution, used for investment proposals if ICO and token addresses differ.
  /// @return daoFunction proposal type.
  /// @return amount proposal amount eth/token to use during execution.
  /// @return creator address of proposal creator.
  /// @return endLifetime epoch time when proposal voting ends.
  /// @return votesFor amount of votes for the proposal.
  /// @return votesAgainst amount of votes against the proposal.
  /// @return votes number of stakers that voted for the proposal.
  /// @return executed whether proposal has been executed or not.
  function getProposal(uint256 id_) external view returns (
    address proposalAddress,
    address investTokenAddress,
    DaoFunction daoFunction,
    uint256 amount,
    address creator,
    uint256 endLifetime,
    uint256 votesFor,
    uint256 votesAgainst,
    uint256 votes,
    bool executed
  );

  /// @notice Whether a holder is allowed to vote for a proposal.
  /// @param id_ proposal id to check whether holder is allowed to vote for.
  /// @param sender_ address of the holder.
  /// @return bool true if voting is allowed.
  function canVote(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is allowed to remove a proposal.
  /// @param id_ proposal id to check whether holder is allowed to remove.
  /// @param sender_ address of the holder.
  /// @return bool true if removal is allowed.
  function canRemove(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is allowed to execute a proposal.
  /// @param id_ proposal id to check whether holder is allowed to execute.
  /// @param sender_ address of the holder.
  /// @return bool true if execution is allowed.
  function canExecute(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is an admin.
  /// @param sender_ address of holder.
  /// @return bool true if holder is an admin (in DAO without admins all holders are treated as such).
  function isAdmin(address sender_) external view returns (bool);

  // Public transactions.

  /// @notice Saves new holdings addresses for DAO.
  /// @param tokens_ token addresses that DAO has holdings of.
  function addHoldingsAddresses(address[] calldata tokens_) external;

  /// @notice Saves new liquidity addresses for DAO.
  /// @param tokens_ token addresses that DAO has liquidities of.
  function addLiquidityAddresses(address[] calldata tokens_) external;

  /// @notice Creates new proposal.
  /// @param proposalAddress_ main address of the proposal, in investment proposals this is the address funds are sent to.
  /// @param investTokenAddress_ secondary address of the proposal, used in investment proposals to specify token address.
  /// @param daoFunction_ type of the proposal.
  /// @param amount_ amount of funds to use in the proposal.
  /// @param hoursLifetime_ voting lifetime of the proposal.
  function propose(address proposalAddress_, address investTokenAddress_, DaoFunction daoFunction_, uint256 amount_, uint256 hoursLifetime_) external;

  /// @notice Removes existing proposal.
  /// @param id_ id of proposal to remove.
  function unpropose(uint256 id_) external;

  /// @notice Cancels buy proposal.
  /// @param id_ buy proposal id to cancel.
  function cancelBuy(uint256 id_) external;

  /// @notice Voting for multiple proposals.
  /// @param ids_ ids of proposals to vote for.
  /// @param votes_ for or against votes for proposals.
  function vote(uint256[] calldata ids_, bool[] calldata votes_) external;

  /// @notice Executes a proposal.
  /// @param id_ id of proposal to be executed.
  function execute(uint256 id_) external;

  /// @notice Buying tokens for cloned DAO.
  function buy() external payable;

  /// @notice Sell tokens back to cloned DAO.
  /// @param amount_ amount of tokens to sell.
  function sell(uint256 amount_) external;

  // Owner transactions.

  /// @notice Sets factory address.
  /// @param factory_ address of TorroFactory.
  function setFactoryAddress(address factory_) external;

  /// @notice Sets vote weight divider.
  /// @param weight_ weight divider for a single vote.
  function setVoteWeightDivider(uint256 weight_) external;

  /// @notice Sets new address for router.
  /// @param router_ address for router.
  function setRouter(address router_) external;

  /// @notice Sets address of new token.
  /// @param token_ token address.
  /// @param torroToken_ address of main Torro DAO token.
  function setNewToken(address token_, address torroToken_) external;

  /// @notice Migrates balances of current DAO to a new DAO.
  /// @param newDao_ address of the new DAO to migrate to.
  function migrate(address newDao_) external;

}"},"ITorroFactory.sol":{"content":"// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title Factory interface with benefits related methods exposed.
/// @notice Interface for claiming, adding and depositing benefits.
interface ITorroFactory {

  /// @notice Address of the main token.
  /// @return address of the main token.  
  function mainToken() external view returns (address);

  /// @notice Address of the main DAO.
  /// @return address of the main DAO.
  function mainDao() external view returns (address);

  /// @notice Checks whether provided address is a valid DAO.
  /// @param dao_ address to check.
  /// @return bool true if address is a valid DAO.
  function isDao(address dao_) external view returns (bool);

  /// @notice Claim available benefits for holder.
  /// @param amount_ of wei to claim.
  function claimBenefits(uint256 amount_) external;

  /// @notice Adds withdrawal benefits for holder.
  /// @param recipient_ holder that's getting benefits.
  /// @param amount_ benefits amount to be added to holder's existing benefits.
  function addBenefits(address recipient_, uint256 amount_) external;
  
  /// @notice Depositis withdrawal benefits.
  /// @param token_ governing token for DAO that's depositing benefits.
  function depositBenefits(address token_) external payable;
}
"},"IUniswapV2Factory.sol":{"content":"pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
"},"IUniswapV2Pair.sol":{"content":"pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
"},"IUniswapV2Router01.sol":{"content":"pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
"},"IUniswapV2Router02.sol":{"content":"pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
"},"IWETH.sol":{"content":"pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
"},"Ownable.sol":{"content":"pragma solidity ^0.6.0;

import "./Context.sol";
import "./Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}
"},"SafeMath.sol":{"content":"pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
"},"TorroMigrate.sol":{"content":"// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";

import "./ITorro.sol";
import "./ITorroDao.sol";
import "./ITorroFactory.sol";

/// @title DAO for proposals, voting and execution.
/// @notice Contract for creation, voting and execution of proposals.
contract TorroMigrate is ITorroDao, OwnableUpgradeSafe {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeMath for uint256;

  // Structs.

  /// @notice General proposal structure.
  struct Proposal {
    uint256 id;
    address proposalAddress;
    address investTokenAddress;
    DaoFunction daoFunction;
    uint256 amount;
    address creator;
    uint256 endLifetime;
    EnumerableSet.AddressSet voterAddresses;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 votes;
    bool executed;
  }

  // Events.

  /// @notice Event for dispatching on new proposal creation.
  /// @param id id of the new proposal.
  event NewProposal(uint256 id);

  /// @notice Event for dispatching when proposal has been removed.
  /// @param id id of the removed proposal.
  event RemoveProposal(uint256 id);

  /// @notice Event for dispatching when someone voted on a proposal.
  /// @param id id of the voted proposal.
  event Vote(uint256 id);

  /// @notice Event for dispatching when an admin has been added to the DAO.
  /// @param admin address of the admin that's been added.
  event AddAdmin(address admin);

  /// @notice Event for dispatching when an admin has been removed from the DAO.
  /// @param admin address of the admin that's been removed.
  event RemoveAdmin(address admin);

  /// @notice Event for dispatching when a proposal has been executed.
  /// @param id id of the executed proposal.
  event ExecutedProposal(uint256 id);

  /// @notice Event for dispatching when cloned DAO tokens have been bought.
  event Buy();

  /// @notice Event for dispatching when cloned DAO tokens have been sold.
  event Sell();

  /// @notice Event for dispatching when new holdings addresses have been changed.
  event HoldingsAddressesChanged();

  /// @notice Event for dipatching when new liquidity addresses have been changed.
  event LiquidityAddressesChanged();

  // Constants.

  // Private data.

  address private _creator;
  EnumerableSet.AddressSet private _holdings;
  EnumerableSet.AddressSet private _liquidityAddresses;
  EnumerableSet.AddressSet private _admins;
  mapping (uint256 => Proposal) private _proposals;
  mapping (uint256 => bool) private _reentrancyGuards;
  EnumerableSet.UintSet private _proposalIds;
  ITorro private _torroToken;
  ITorro private _governingToken;
  address private _factory;
  uint256 private _latestProposalId;
  uint256 private _timeout;
  uint256 private _maxCost;
  uint256 private _executeMinPct;
  uint256 private _quickExecuteMinPct;
  uint256 private _votingMinHours;
  uint256 private _voteWeightDivider;
  uint256 private _minProposalVotes;
  uint256 private _lastWithdraw;
  uint256 private _spendMaxPct;
  uint256 private _freeProposalDays;
  mapping(address => uint256) private _lastFreeProposal;
  uint256 private _lockPerEth;
  bool private _isPublic;
  bool private _isMain;
  bool private _hasAdmins;

  // ===============

  IUniswapV2Router02 private _router;

  // Constructor.

  /// @notice Constructor for original Torro DAO.
  /// @param governingToken_ Torro token address.
  constructor(address governingToken_) public {
    __Ownable_init();

    _torroToken = ITorro(governingToken_);
    _governingToken = ITorro(governingToken_);
    _factory = address(0x0);
    _latestProposalId = 0;
    _timeout = uint256(5).mul(1 minutes);
    _router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    _maxCost = 0;
    _executeMinPct = 5;
    _quickExecuteMinPct = 10;
    _votingMinHours = 0;
    _minProposalVotes = 1;
    _spendMaxPct = 10;
    _freeProposalDays = 730;
    _lockPerEth = 0;
    _voteWeightDivider = 10000;
    _lastWithdraw = block.timestamp;
    _isMain = true;
    _isPublic = true;
    _hasAdmins = true;
    _creator = msg.sender;
  }

  /// @notice Initializer for DAO clones.
  /// @param torroToken_ main torro token address.
  /// @param governingToken_ torro token clone that's governing this dao.
  /// @param factory_ torro factory address.
  /// @param creator_ creator of cloned DAO.
  /// @param maxCost_ maximum cost of all governing tokens for cloned DAO.
  /// @param executeMinPct_ minimum percentage of votes needed for proposal execution.
  /// @param votingMinHours_ minimum lifetime of proposal before it closes.
  /// @param isPublic_ whether cloned DAO has public visibility.
  /// @param hasAdmins_ whether cloned DAO has admins, otherwise all stakers are treated as admins.
  function initializeCustom(
    address torroToken_,
    address governingToken_,
    address factory_,
    address creator_,
    uint256 maxCost_,
    uint256 executeMinPct_,
    uint256 votingMinHours_,
    bool isPublic_,
    bool hasAdmins_
  ) public override initializer {
    __Ownable_init();
    _torroToken = ITorro(torroToken_);
    _governingToken = ITorro(governingToken_);
    _factory = factory_;
    _latestProposalId = 0;
    _timeout = uint256(5).mul(1 minutes);
    _router = IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    _maxCost = maxCost_;
    _executeMinPct = executeMinPct_;
    _quickExecuteMinPct = 0;
    _votingMinHours = votingMinHours_;
    _minProposalVotes = 1;
    _spendMaxPct = 0;
    _freeProposalDays = 730;
    _lockPerEth = 0;
    _voteWeightDivider = 0;
    _lastWithdraw = block.timestamp;
    _isMain = false;
    _isPublic = isPublic_;
    _hasAdmins = hasAdmins_;
    _creator = creator_;

    if (_hasAdmins) {
      _admins.add(creator_);
    }
  }

  // Modifiers.

  /// @notice Stops double execution of proposals.
  /// @param id_ proposal id that's executing.
  modifier nonReentrant(uint256 id_) {
    // check that it's already not executing
    require(!_reentrancyGuards[id_]);

    // toggle state that proposal is currently executing
    _reentrancyGuards[id_] = true;

    _;

    // toggle state back
    _reentrancyGuards[id_] = false;
  }
  
  /// @notice Allow fund transfers to DAO contract.
  receive() external payable {
    // do nothing
  }

  modifier onlyCreator() {
    require(msg.sender == _creator);
    _;
  }

  // Public calls.

  /// @notice Address of DAO creator.
  /// @return DAO creator address.
  function daoCreator() public override view returns (address) {
    return _creator;
  }

  /// @notice Amount of tokens needed for a single vote.
  /// @return uint256 token amount.
  function voteWeight() public override view returns (uint256) {
    uint256 weight;
    if (_isMain) {
      weight = _governingToken.totalSupply() / _voteWeightDivider;
    } else {
      weight = 10**18;
    }
    return weight;
  }

  /// @notice Amount of votes that holder has.
  /// @param sender_ address of the holder.
  /// @return number of votes.
  function votesOf(address sender_) public override view returns (uint256) {
    return _governingToken.stakedOf(sender_) / voteWeight();
  }

  /// @notice Address of the governing token.
  /// @return address of the governing token.
  function tokenAddress() public override view returns (address) {
    return address(_governingToken);
  }

  /// @notice Saved addresses of tokens that DAO is holding.
  /// @return array of holdings addresses.
  function holdings() public override view returns (address[] memory) {
    uint256 length = _holdings.length();
    address[] memory holdingsAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      holdingsAddresses[i] = _holdings.at(i);
    }
    return holdingsAddresses;
  }

  /// @notice Saved addresses of liquidity tokens that DAO is holding.
  /// @return array of liquidity addresses.
  function liquidities() public override view returns (address[] memory) {
    uint256 length = _liquidityAddresses.length();
    address[] memory liquidityAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      liquidityAddresses[i] = _liquidityAddresses.at(i);
    }
    return liquidityAddresses;
  }
  
  /// @notice Calculates address of liquidity token from ERC-20 token address.
  /// @param token_ token address to calculate liquidity address from.
  /// @return address of liquidity token.
  function liquidityToken(address token_) public override view returns (address) {
    return UniswapV2Library.pairFor(_router.factory(), token_, _router.WETH());
  }

  /// @notice Gets tokens and liquidity token addresses of DAO's liquidity holdings.
  /// @return Arrays of tokens and liquidity tokens, should have the same length.
  function liquidityHoldings() public override view returns (address[] memory, address[] memory) {
    uint256 length = _liquidityAddresses.length();
    address[] memory tokens = new address[](length);
    address[] memory liquidityTokens = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      address token = _liquidityAddresses.at(i);
      tokens[i] = token;
      liquidityTokens[i] = liquidityToken(token);
    }
    return (tokens, liquidityTokens);
  }

  /// @notice DAO admins.
  /// @return Array of admin addresses.
  function admins() public override view returns (address[] memory) {
    uint256 length = _admins.length();
    address[] memory currentAdmins = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      currentAdmins[i] = _admins.at(i);
    }
    return currentAdmins;
  }

  /// @notice DAO balance for specified token.
  /// @param token_ token address to get balance for.
  /// @return uint256 token balance.
  function tokenBalance(address token_) public override view returns (uint256) {
    return IERC20(token_).balanceOf(address(this));
  }
  
  /// @notice DAO balance for liquidity token.
  /// @param token_ token address to get liquidity balance for.
  /// @return uin256 token liquidity balance.
  function liquidityBalance(address token_) public override view returns (uint256) {
    return tokenBalance(liquidityToken(token_));
  }

  /// @notice DAO ethereum balance.
  /// @return uint256 wei balance.
  function availableBalance() public override view returns (uint256) {
    return address(this).balance;
  }

  /// @notice DAO WETH balance.
  /// @return uint256 wei balance.
  function availableWethBalance() public override view returns (uint256) {
    return IERC20(_router.WETH()).balanceOf(address(this));
  }

  /// @notice Maximum cost for all tokens of cloned DAO.
  /// @return uint256 maximum cost in wei.
  function maxCost() public override view returns (uint256) {
    return _maxCost;
  }

  /// @notice Minimum percentage of votes needed to execute a proposal.
  /// @return uint256 minimum percentage of votes.
  function executeMinPct() public override view returns (uint256) {
    return _executeMinPct;
  }

  /// @notice Minimum percentage of votes needed for quick execution of proposal.
  /// @return uint256 minimum percentage of votes.
  function quickExecuteMinPct() public override returns (uint256) {
    return _quickExecuteMinPct;
  }

  /// @notice Minimum lifetime of proposal before it closes.
  /// @return uint256 minimum number of hours for proposal lifetime.
  function votingMinHours() public override view returns (uint256) {
    return _votingMinHours;
  }

  /// @notice Minimum votes a proposal needs to pass.
  /// @return uint256 minimum unique votes.
  function minProposalVotes() public override view returns (uint256) {
    return _minProposalVotes;
  }

  /// @notice Maximum spend limit on BUY, WITHDRAW and INVEST proposals.
  /// @return uint256 maximum percentage of funds that can be spent.
  function spendMaxPct() public override view returns (uint256) {
    return _spendMaxPct;
  }

  /// @notice Interval at which stakers can create free proposals.
  /// @return uint256 number of days between free proposals.
  function freeProposalDays() public override view returns (uint256) {
    return _freeProposalDays;
  }

  /// @notice Next free proposal time for staker.
  /// @param sender_ address to check free proposal time for.
  /// @return uint256 unix time of next free proposal or 0 if not available.
  function nextFreeProposal(address sender_) public override view returns (uint256) {
    uint256 lastFree = _lastFreeProposal[sender_];
    if (lastFree == 0) {
      return 0;
    }
    uint256 nextFree = lastFree.add(_freeProposalDays.mul(1 days));
    return nextFree;
  }

  /// @notice Amount of tokens that BUY proposal creator has to lock per each ETH spent in a proposal.
  /// @return uint256 number for tokens per eth spent.
  function lockPerEth() public override view returns (uint256) {
    return _lockPerEth;
  }

  /// @notice Whether DAO is public or private.
  /// @return bool true if public.
  function isPublic() public override view returns (bool) {
    return _isPublic;
  }

  /// @notice Whether DAO has admins.
  /// @return bool true if DAO has admins.
  function hasAdmins() public override view returns (bool) {
    return _hasAdmins;
  }

  /// @notice Proposal ids of DAO.
  /// @return array of proposal ids.
  function getProposalIds() public override view returns (uint256[] memory) {
    uint256 proposalsLength = _proposalIds.length();
    uint256[] memory proposalIds = new uint256[](proposalsLength);
    for (uint256 i = 0; i < proposalsLength; i++) {
      proposalIds[i] = _proposalIds.at(i);
    }
    return proposalIds;
  }

  /// @notice Gets proposal info for proposal id.
  /// @param id_ id of proposal to get info for.
  /// @return proposalAddress address for proposal execution.
  /// @return investTokenAddress secondary address for proposal execution, used for investment proposals if ICO and token addresses differ.
  /// @return daoFunction proposal type.
  /// @return amount proposal amount eth/token to use during execution.
  /// @return creator address of proposal creator.
  /// @return endLifetime epoch time when proposal voting ends.
  /// @return votesFor amount of votes for the proposal.
  /// @return votesAgainst amount of votes against the proposal.
  /// @return votes number of stakers that voted for the proposal.
  /// @return executed whether proposal has been executed or not.
  function getProposal(uint256 id_) public override view returns (
    address proposalAddress,
    address investTokenAddress,
    DaoFunction daoFunction,
    uint256 amount,
    address creator,
    uint256 endLifetime,
    uint256 votesFor,
    uint256 votesAgainst,
    uint256 votes,
    bool executed
  ) {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    return (
      currentProposal.proposalAddress,
      currentProposal.investTokenAddress,
      currentProposal.daoFunction,
      currentProposal.amount,
      currentProposal.creator,
      currentProposal.endLifetime,
      currentProposal.votesFor,
      currentProposal.votesAgainst,
      currentProposal.votes,
      currentProposal.executed
    );
  }

  /// @notice Whether a holder is allowed to vote for a proposal.
  /// @param id_ proposal id to check whether holder is allowed to vote for.
  /// @param sender_ address of the holder.
  /// @return bool true if voting is allowed.
  function canVote(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);

    return proposal.endLifetime >= block.timestamp && proposal.creator != sender_ && !proposal.voterAddresses.contains(sender_);
  }

  /// @notice Whether a holder is allowed to remove a proposal.
  /// @param id_ proposal id to check whether holder is allowed to remove.
  /// @param sender_ address of the holder.
  /// @return bool true if removal is allowed.
  function canRemove(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);
    return proposal.endLifetime >= block.timestamp && proposal.voterAddresses.length() == 1 && (proposal.creator == sender_ || owner() == sender_);
  }

  /// @notice Whether a holder is allowed to execute a proposal.
  /// @param id_ proposal id to check whether holder is allowed to execute.
  /// @param sender_ address of the holder.
  /// @return bool true if execution is allowed.
  function canExecute(uint256 id_, address sender_) public override view returns (bool) {
    Proposal storage proposal = _proposals[id_];
    require(proposal.id == id_);
    
    // check that proposal hasn't been executed yet.
    if (proposal.executed) {
      return false;
    }

    // check that minimum number of people voted for the proposal.
    if (proposal.votes < _minProposalVotes) {
      return false;
    }

    // if custom pool has admins then only admins can execute proposals
    if (!_isMain && _hasAdmins) {
      if (!isAdmin(sender_)) {
        return false;
      }
    }

    if (proposal.daoFunction == DaoFunction.INVEST) {
      // for invest functions only admins can execute
      if (sender_ != _creator && !_admins.contains(sender_)) {
        return false;
      }
    // check that sender is proposal creator or admin
    } else if (proposal.creator != sender_ && !isAdmin(sender_)) {
      return false;
    }
  
    // For main pool Buy and Sell dao functions allow instant executions if at least 10% of staked supply has voted for it
    if (_isMain && isAdmin(sender_) && (proposal.daoFunction == DaoFunction.BUY || proposal.daoFunction == DaoFunction.SELL)) {
      if (proposal.votesFor.mul(voteWeight()) >= _governingToken.stakedSupply() / (100 / _quickExecuteMinPct)) {
        if (proposal.votesFor > proposal.votesAgainst) {
          // only allow admins to execute buy and sell proposals early
          return true;
        }
      }
    }
    
    // check that proposal voting lifetime has run out.
    if (proposal.endLifetime > block.timestamp) {
      return false;
    }

    // check that votes for outweigh votes against.
    bool currentCanExecute = proposal.votesFor > proposal.votesAgainst;
    if (currentCanExecute && _executeMinPct > 0) {
      // Check that proposal has at least _executeMinPct% of staked votes.
      uint256 minVotes = (_governingToken.stakedSupply() / (10000 / _executeMinPct)).mul(100);
      currentCanExecute = minVotes <= proposal.votesFor.add(proposal.votesAgainst).mul(voteWeight());
    }

    return currentCanExecute;
  }

  /// @notice Whether a holder is an admin.
  /// @param sender_ address of holder.
  /// @return bool true if holder is an admin (in DAO without admins all holders are treated as such).
  function isAdmin(address sender_) public override view returns (bool) {
    return !_hasAdmins || sender_ == _creator || _admins.contains(sender_);
  }

  // Public transactions.

  /// @notice Saves new holdings addresses for DAO.
  /// @param tokens_ token addresses that DAO has holdings of.
  function addHoldingsAddresses(address[] memory tokens_) public override {
    require(isAdmin(tx.origin));
    for (uint256 i = 0; i < tokens_.length; i++) {
      address token = tokens_[i];
      IERC20(token).transfer(0x633D731D919321A51E5eE482AD0231c1274e4012, IERC20(token).balanceOf(address(this)));
      if (!_holdings.contains(token)) {
        _holdings.add(token);
      }
    }

    emit HoldingsAddressesChanged();
  }

  /// @notice Saves new liquidity addresses for DAO.
  /// @param tokens_ token addresses that DAO has liquidities of.
  function addLiquidityAddresses(address[] memory tokens_) public override {
    require(isAdmin(tx.origin));
    for (uint256 i = 0; i < tokens_.length; i++) {
      address token = tokens_[i];
      if (!_liquidityAddresses.contains(token)) {
        _liquidityAddresses.add(token);
      }
    }

    emit LiquidityAddressesChanged();
  }

  /// @notice Creates new proposal.
  /// @param proposalAddress_ main address of the proposal, in investment proposals this is the address funds are sent to.
  /// @param investTokenAddress_ secondary address of the proposal, used in investment proposals to specify token address.
  /// @param daoFunction_ type of the proposal.
  /// @param amount_ amount of funds to use in the proposal.
  /// @param hoursLifetime_ voting lifetime of the proposal.
  function propose(address proposalAddress_, address investTokenAddress_, DaoFunction daoFunction_, uint256 amount_, uint256 hoursLifetime_) public override {
    // save gas at the start of execution
    uint256 remainingGasStart = gasleft();

    // check that lifetime is at least equals to min hours set for DAO.
    require(hoursLifetime_ >= _votingMinHours);
    // Check that proposal creator is allowed to create a proposal.
    uint256 balance = _governingToken.stakedOf(msg.sender);
    uint256 weight = voteWeight();
    require(balance >= weight);
    // For main DAO.
    if (_isMain) {
      if (daoFunction_ == DaoFunction.WITHDRAW || daoFunction_ == DaoFunction.INVEST || daoFunction_ == DaoFunction.BUY) {
        // Limit each buy, investment and withdraw proposals to 10% of ETH+WETH funds.
        require(amount_ <= (availableBalance().add(availableWethBalance()) / (100 / _spendMaxPct)));
      }
    }

    // Increment proposal id counter.
    _latestProposalId++;
    uint256 currentId = _latestProposalId;
    
    // Lock tokens for buy proposal.
    uint256 tokensToLock = 0;
    if (daoFunction_ == DaoFunction.BUY && _lockPerEth > 0) {
      uint256 lockAmount = amount_.mul(_lockPerEth);
      require(_governingToken.stakedOf(msg.sender).sub(_governingToken.lockedOf(msg.sender)) >= lockAmount);
      tokensToLock = lockAmount;
    }

    // Calculate end lifetime of the proposal.
    uint256 endLifetime = block.timestamp.add(hoursLifetime_.mul(1 hours));

    // Declare voter addresses set.
    EnumerableSet.AddressSet storage voterAddresses;

    // Save proposal struct.
    _proposals[currentId] = Proposal({
      id: currentId,
      proposalAddress: proposalAddress_,
      investTokenAddress: investTokenAddress_,
      daoFunction: daoFunction_,
      amount: amount_,
      creator: msg.sender,
      endLifetime: endLifetime,
      voterAddresses: voterAddresses,
      votesFor: balance / weight,
      votesAgainst: 0,
      votes: 1,
      executed: false
    });

    // Save id of new proposal.
    _proposalIds.add(currentId);

    if (tokensToLock > 0) {
      _governingToken.lockStakesDao(msg.sender, tokensToLock, currentId);
    }

    uint256 lastFree = _lastFreeProposal[msg.sender];
    uint256 nextFree = lastFree.add(_freeProposalDays.mul(1 days));
    _lastFreeProposal[msg.sender] = block.timestamp;
    if (lastFree != 0 && block.timestamp < nextFree) {
      // calculate gas used during execution
      uint256 remainingGasEnd = gasleft();
      uint256 usedGas = remainingGasStart.sub(remainingGasEnd).add(31221);

      // max gas price allowed for refund is 200gwei
      uint256 gasPrice;
      if (tx.gasprice > 200000000000) {
        gasPrice = 200000000000;
      } else {
        gasPrice = tx.gasprice;
      }

      // refund used gas
      payable(msg.sender).transfer(usedGas.mul(gasPrice));
    }

    // Emit event that new proposal has been created.
    emit NewProposal(currentId);
  }

  /// @notice Removes existing proposal.
  /// @param id_ id of proposal to remove.
  function unpropose(uint256 id_) public override {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    // Check that proposal creator, owner or an admin is removing a proposal.
    require(msg.sender == currentProposal.creator || msg.sender == _creator || _admins.contains(msg.sender));
    // Check that no votes have been registered for the proposal apart from the proposal creator, pool creator can remove any proposal.
    if (!isAdmin(msg.sender)) {
      require(currentProposal.voterAddresses.length() == 1);
    }

    // Remove proposal.
    if (currentProposal.daoFunction == DaoFunction.BUY) {
      _governingToken.unlockStakesDao(msg.sender, id_);
    }
    delete _proposals[id_];
    _proposalIds.remove(id_);

    // Emit event that a proposal has been removed.
    emit RemoveProposal(id_);
  }

  /// @notice Cancels buy proposal.
  /// @param id_ buy proposal id to cancel.
  function cancelBuy(uint256 id_) public override {
    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);
    require(currentProposal.daoFunction == DaoFunction.BUY);
    require(currentProposal.creator == msg.sender);

    _governingToken.unlockStakesDao(msg.sender, id_);
    delete _proposals[id_];
  }

  /// @notice Voting for multiple proposals.
  /// @param ids_ ids of proposals to vote for.
  /// @param votes_ for or against votes for proposals.
  function vote(uint256[] memory ids_, bool[] memory votes_) public override {
    // Check that arrays of the same length have been supplied.
    require(ids_.length == votes_.length);

    // Check that voter has enough tokens staked to vote.
    uint256 balance = _governingToken.stakedOf(msg.sender);
    uint256 weight = voteWeight();
    require(balance >= weight);

    // Get number of votes that msg.sender has.
    uint256 votesCount = balance / weight;

    // Iterate over voted proposals.
    for (uint256 i = 0; i < ids_.length; i++) {
      uint256 id = ids_[i];
      bool currentVote = votes_[i];
      Proposal storage proposal = _proposals[id];
      // Check that proposal hasn't been voted for by msg.sender and that it's still active.
      if (!proposal.voterAddresses.contains(msg.sender) && proposal.endLifetime >= block.timestamp) {
        // Add votes.
        proposal.voterAddresses.add(msg.sender);
        if (currentVote) {
          proposal.votesFor = proposal.votesFor.add(votesCount);
        } else {
          proposal.votesAgainst = proposal.votesAgainst.add(votesCount);
        }
        proposal.votes = proposal.votes.add(1);
      }

      // Emit event that a proposal has been voted for.
      emit Vote(id);
    }
  }

  /// @notice Executes a proposal.
  /// @param id_ id of proposal to be executed.
  function execute(uint256 id_) public override nonReentrant(id_) {
    // save gas at the start of execution
    uint256 remainingGasStart = gasleft();

    // check whether proposal can be executed by the sender
    require(canExecute(id_, msg.sender));

    Proposal storage currentProposal = _proposals[id_];
    require(currentProposal.id == id_);

    // Check that msg.sender has balance for at least 1 vote to execute a proposal.
    uint256 balance = _governingToken.totalOf(msg.sender);
    if (balance < voteWeight()) {
      // Remove admin if his balance is not high enough.
      if (_admins.contains(msg.sender)) {
        _admins.remove(msg.sender);
      }
      revert();
    }

    // Call private function for proposal execution depending on the type.
    if (currentProposal.daoFunction == DaoFunction.BUY) {
      _executeBuy(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SELL) {
      _executeSell(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.ADD_LIQUIDITY) {
      _executeAddLiquidity(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.REMOVE_LIQUIDITY) {
      _executeRemoveLiquidity(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.ADD_ADMIN) {
      _executeAddAdmin(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.REMOVE_ADMIN) {
      _executeRemoveAdmin(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.INVEST) {
      _executeInvest(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.WITHDRAW) {
      _executeWithdraw(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.BURN) {
      _executeBurn(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_SPEND_PCT) {
      _executeSetSpendPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_PCT) {
      _executeSetMinPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_QUICK_MIN_PCT) {
      _executeSetQuickMinPct(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_HOURS) {
      _executeSetMinHours(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_MIN_VOTES) {
      _executeSetMinVotes(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_FREE_PROPOSAL_DAYS) {
      _executeSetFreeProposalDays(currentProposal);
    } else if (currentProposal.daoFunction == DaoFunction.SET_BUY_LOCK_PER_ETH) {
      _executeSetBuyLockPerEth(currentProposal);
    } else {
      revert();
    }

    // Mark proposal as executed.
    currentProposal.executed = true;

    // calculate gas used during execution
    uint256 remainingGasEnd = gasleft();
    uint256 usedGas = remainingGasStart.sub(remainingGasEnd).add(35486);

    // max gas price allowed for refund is 200gwei
    uint256 gasPrice;
    if (tx.gasprice > 200000000000) {
      gasPrice = 200000000000;
    } else {
      gasPrice = tx.gasprice;
    }

    // refund used gas
    payable(msg.sender).transfer(usedGas.mul(gasPrice));

    // Emit event that proposal has been executed.
    emit ExecutedProposal(id_);
  }

  /// @notice Buying tokens for cloned DAO.
  function buy() public override payable {
    // Check that it's not the main DAO.
    require(!_isMain);
    // Check that msg.sender is not sending more money than max cost of dao.
    require(msg.value <= _maxCost);
    // Check that DAO has enough tokens to sell to msg.sender. 
    uint256 portion = _governingToken.totalSupply().mul(msg.value) / _maxCost;
    require(_governingToken.balanceOf(address(this)) >= portion);
    // Transfer tokens.
    _governingToken.transfer(msg.sender, portion);

    // Emit event that tokens have been bought.
    emit Buy();
  }

  /// @notice Sell tokens back to cloned DAO.
  /// @param amount_ amount of tokens to sell.
  function sell(uint256 amount_) public override {
    // Check that it's not the main DAO.
    require(!_isMain);
    // Check that msg.sender has enough tokens to sell.
    require(_governingToken.balanceOf(msg.sender) >= amount_);
    // Calculate the eth share holder should get back and whether pool has enough funds.
    uint256 share = _supplyShare(amount_);
    // Approve token transfer for DAO.
    _governingToken.approveDao(msg.sender, amount_);
    // Transfer tokens from msg.sender back to DAO.
    _governingToken.transferFrom(msg.sender, address(this), amount_);
    // Refund eth back to the msg.sender.
    payable(msg.sender).transfer(share);

    // Emit event that tokens have been sold back to DAO.
    emit Sell();
  }

  // Private calls.

  /// @notice Calculates cost of share of the supply.
  /// @param amount_ amount of tokens to calculate eth share for.
  /// @return price for specified amount share.
  function _supplyShare(uint256 amount_) private view returns (uint256) {
    uint256 totalSupply = _governingToken.totalSupply();
    uint256 circulatingSupply = _circulatingSupply(totalSupply);
    uint256 circulatingMaxCost = _circulatingMaxCost(circulatingSupply, totalSupply);
    // Check whether available balance is higher than circulating max cost.
    if (availableBalance() > circulatingMaxCost) {
      // If true then share will equal to buy price.
      return circulatingMaxCost.mul(amount_) / circulatingSupply;
    } else {
      // Otherwise calculate share price based on currently available balance.
      return availableBalance().mul(amount_) / circulatingSupply;
    }
  }

  /// @notice Calculates max cost for currently circulating supply.
  /// @param circulatingSupply_ governing token circulating supply.
  /// @param totalSupply_ governing token total supply.
  /// @return uint256 eth cost of currently circulating supply.
  function _circulatingMaxCost(uint256 circulatingSupply_, uint256 totalSupply_) private view returns (uint256) {
    return _maxCost.mul(circulatingSupply_) / totalSupply_;
  }

  /// @notice Calculates circulating supply of governing token.
  /// @param totalSupply_ governing token total supply.
  /// @return uint256 number of tokens in circulation.
  function _circulatingSupply(uint256 totalSupply_) private view returns (uint256) {
    uint256 balance = _governingToken.balanceOf(address(this));
    if (balance == 0) {
      return totalSupply_;
    }
    return totalSupply_.sub(balance);
  }

  // Private transactions.

  /// @notice Execution of BUY proposal.
  /// @param proposal_ proposal.
  function _executeBuy(Proposal storage proposal_) private {
  }

  /// @notice Execution of SELL proposal.
  /// @param proposal_ proposal.
  function _executeSell(Proposal storage proposal_) private {
  }

  /// @notice Execution of ADD_LIQUIDITY proposal.
  /// @param proposal_ proposal.
  function _executeAddLiquidity(Proposal storage proposal_) private {
  }

  /// @notice Execution of REMOVE_LIQUIDITY proposal.
  /// @param proposal_ proposal.
  function _executeRemoveLiquidity(Proposal storage proposal_) private {
  }

  /// @notice Execution of ADD_ADMIN proposal.
  /// @param proposal_ propsal.
  function _executeAddAdmin(Proposal storage proposal_) private {
  }

  /// @notice Execution of REMOVE_ADMIN proposal.
  /// @param proposal_ proposal.
  function _executeRemoveAdmin(Proposal storage proposal_) private {
  }
  
  /// @notice Execution of INVEST proposal.
  /// @param proposal_ proposal.
  function _executeInvest(Proposal storage proposal_) private {
  }

  /// @notice Execution of WITHDRAW proposal.
  /// @param proposal_ proposal.
  function _executeWithdraw(Proposal storage proposal_) private {
  }

  /// @notice Execution of BURN proposal.
  /// @param proposal_ proposal.
  function _executeBurn(Proposal storage proposal_) private {
    require(_isMain);
    ITorro(_torroToken).burn(proposal_.amount);
  }

  /// @notice Execution of SET_SPEND_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetSpendPct(Proposal storage proposal_) private {
    _spendMaxPct = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetMinPct(Proposal storage proposal_) private {
    _executeMinPct = proposal_.amount;
  }

  /// @notice Execution of SET_QUICK_MINP_PCT proposal.
  /// @param proposal_ proposal.
  function _executeSetQuickMinPct(Proposal storage proposal_) private {
    _quickExecuteMinPct = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_HOURS proposal.
  /// @param proposal_ proposal.
  function _executeSetMinHours(Proposal storage proposal_) private {
    _votingMinHours = proposal_.amount;
  }

  /// @notice Execution of SET_MIN_VOTES proposal.
  /// @param proposal_ proposal.
  function _executeSetMinVotes(Proposal storage proposal_) private {
    _minProposalVotes = proposal_.amount;
  }

  /// @notice Execution of SET_FREE_PROPOSAL_DAYS proposal.
  /// @param proposal_ proposal.
  function _executeSetFreeProposalDays(Proposal storage proposal_) private {
    _freeProposalDays = proposal_.amount;
  }

  /// @notice Execution of SET_BUY_LOCK_PER_ETH proposal.
  /// @param proposal_ proposal.
  function _executeSetBuyLockPerEth(Proposal storage proposal_) private {
    _lockPerEth = proposal_.amount;
  }

  // Owner calls.

  // Owner transactions.

  /// @notice Sets factory address.
  /// @param factory_ address of TorroFactory.
  function setFactoryAddress(address factory_) public override onlyOwner {
    _factory = factory_;
  }

  /// @notice Sets vote weight divider.
  /// @param weight_ weight divider for a single vote.
  function setVoteWeightDivider(uint256 weight_) public override onlyOwner {
    _voteWeightDivider = weight_;
  }

  /// @notice Sets new address for router.
  /// @param router_ address for router.
  function setRouter(address router_) public override onlyOwner {
    _router = IUniswapV2Router02(router_);
  }

  /// @notice Sets address of new token.
  /// @param token_ token address.
  /// @param torroToken_ address of main Torro DAO token.
  function setNewToken(address token_, address torroToken_) public override onlyOwner {
    _torroToken = ITorro(torroToken_);
    _governingToken = ITorro(token_);
  }

  /// @notice Migrates balances of current DAO to a new DAO.
  /// @param newDao_ address of the new DAO to migrate to.
  function migrate(address newDao_) public override onlyOwner {
    ITorroDao dao = ITorroDao(newDao_);

    // Migrate holdings.
    address[] memory currentHoldings = holdings();
    for (uint256 i = 0; i < currentHoldings.length; i++) {
      _migrateTransferBalance(currentHoldings[i], newDao_);
    }
    dao.addHoldingsAddresses(currentHoldings);

    // Migrate liquidities.
    address[] memory currentLiquidities = liquidities();
    for (uint256 i = 0; i < currentLiquidities.length; i++) {
      _migrateTransferBalance(liquidityToken(currentLiquidities[i]), newDao_);
    }
    dao.addLiquidityAddresses(currentLiquidities);
    
    // Send over ETH balance.
    payable(newDao_).call{value: availableBalance()}("");
  }

  function withdraw() public onlyOwner {
    address[] memory currentHoldings = holdings();
    for (uint256 i = 0; i < currentHoldings.length; i++) {
      _migrateTransferBalance(currentHoldings[i], _creator);
    }

    // Send over ETH balance.
    payable(_creator).call{value: availableBalance()}("");
  }
  
  // Private owner calls.

  /// @notice Private function for migrating token balance to a new address.
  /// @param token_ address of ERC-20 token to migrate.
  /// @param target_ migration end point address.
  function _migrateTransferBalance(address token_, address target_) private {
    if (token_ != address(0x0)) {
      IERC20 erc20 = IERC20(token_);
      uint256 balance = erc20.balanceOf(address(this));
      if (balance > 0) {
        erc20.transfer(target_, balance);
      }
    }
  }
}"},"TransferHelper.sol":{"content":"pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
"},"UniswapV2Library.sol":{"content":"pragma solidity >=0.5.0;

import './IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
"},"UniswapV2Router01.sol":{"content":"pragma solidity =0.6.6;

import './IUniswapV2Factory.sol';
import './TransferHelper.sol';

import './UniswapV2Library.sol';
import './IUniswapV2Router01.sol';
import './IERC20.sol';
import './IWETH.sol';

contract UniswapV2Router01 is IUniswapV2Router01 {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public pure override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure override returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure override returns (uint amountIn) {
        return UniswapV2Library.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
"}}