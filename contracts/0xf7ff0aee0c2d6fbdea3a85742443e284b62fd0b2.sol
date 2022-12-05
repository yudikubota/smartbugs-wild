{{
  "language": "Solidity",
  "sources": {
    "contracts/governance/AavePropositionPower.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/// @title AavePropositionPower
/// @author Aave
/// @notice Asset to control the permissions on the actions in AaveProtoGovernance, like:
///  - Register a new Proposal
contract AavePropositionPower is ERC20Capped, ERC20Detailed {

    /// @notice Constructor
    /// @param name Asset name
    /// @param symbol Asset symbol
    /// @param decimals Asset decimals
    /// @param council List of addresses which will receive tokens initially
    /// @param cap The cap of tokens to mint, length of the council list
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address[] memory council,
        uint256 cap
    )
    public ERC20Capped(cap * 1 ether) ERC20Detailed(name, symbol, decimals) {
        require(cap == council.length, "INCONSISTENT_CAP_AND_COUNCIL_SIZE");
        for (uint256 i = 0; i < cap; i++) {
            _mint(council[i], 1 ether);
        }
    }
}"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol": {
      "content": "pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";

/**
 * @dev Extension of {ERC20Mintable} that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol": {
      "content": "pragma solidity ^0.5.0;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/access/roles/MinterRole.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
"
    },
    "@openzeppelin/contracts/access/Roles.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
"
    },
    "contracts/governance/AaveProtoGovernance.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "../interfaces/IGovernanceParamsProvider.sol";
import "../interfaces/IAssetVotingWeightProvider.sol";
import "../interfaces/IProposalExecutor.sol";
import "../interfaces/IAaveProtoGovernance.sol";


/// @title AaveProtoGovernance
/// @author Aave
/// @notice Smart contract containing voting logic and registering voting proposals.
///  - Allows to granular resolution per proposal
///  - Fixes the voting logic
///  - Keeps all the data related with all the proposals
///  - Allows voters to submit, override or cancel votes directly
///  - Allows relayers to submit, override or cancel votes on behalf of voters
///  - Once the voting and validation periods finish, executes a DELEGATECALL to the proposalExecutor of the
///    corresponding proposal
///  - The creation of a new proposal can only be triggered by an account with a certain amount of AavePropositionPower
contract AaveProtoGovernance is IAaveProtoGovernance {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    struct Voter {
        /// @notice Vote with 0 always as abstain.
        ///  In a YES/NO scenario, YES would be 1, NO would be 2
        uint256 vote;
        /// @notice Weight of the asset coming from the IAssetVotingWeightProvider
        uint256 weight;
        /// @notice Asset balance used to vote
        uint256 balance;
        /// @notice The nonce of the voter address, to protect agains vote replay attacks
        //  It is increased in 1 unit on both voting and cancel vote of an user. When the
        //  user vote overrides his previous vote, it is double increased
        uint256 nonce;
        /// @notice Address of the asset using to vote, locked in the voter address
        IERC20 asset;
    }

    struct Proposal {
        /// @notice Hashed type of the proposal, for example keccak256(UPGRADE_ADDRESS_PROPOSAL)
        bytes32 proposalType;
        /// @notice Count of the current units of votes accumulated until the current moment (each time somebody votes + 1)
        uint256 totalVotes;
        /// @notice Threshold required calculated offchain from the aggregated total supply of the whitelisted
        ///  assets multiplied by the voting weight of each asset
        ///  Example: With 2 whitelisted tokens with 1 and 2 as respective voting weights and 10 000 and 20 000
        ///  respective total supplies, the aggregated voting power would be (10000 * 1) + (20000 * 2) = 50000,
        ///  so a threshold equivalent to the 50% of total voting power would be 25000
        uint256 threshold;
        /// @notice Variable to control how many changes to Voting state are allowed
        /// (both initially from Initializing and from Validating every time the threshold is crossed down
        ///  due to double votes)
        uint256 maxMovesToVotingAllowed;
        /// @notice Current amount of times the proposal went to Voting state
        uint256 movesToVoting;
        /// @notice Minimum number of blocks the proposal needs to be in Voting before being able to change to
        /// Validating
        uint256 votingBlocksDuration;
        /// @notice Minimum number of blocks the proposal needs to be in Validating before being able to be executed
        uint256 validatingBlocksDuration;
        /// @notice Block number where the current status started
        uint256 currentStatusInitBlock;
        /// @notice Block number when the proposal was created
        uint256 initProposalBlock;
        /// @notice Mapping choice id => voting power accumulated in the choice
        mapping(uint256 => uint256) votes;
        /// @notice Mapping of voters: Voting Wallet address => vote information
        mapping(address => Voter) voters;
        /// @notice Smart contract in charge of .execute() a certain payload
        address proposalExecutor;
        /// @notice Status of the proposal
        ProposalStatus proposalStatus;
    }

    /// @notice State Machine
    ///  - Initializing: temporary state during the newProposal() execution, before changing to Voting.
    ///  - Voting: Once newProposal() execution finishes. Voters are able to vote or cancel their votes.
    ///  - Validating: After the voting period ends and the proposal threshold gets crossed by one of the
    ///      allowed choices. During this period, everybody is be able to call challengeVoters() in order
    ///      to invalidate votes result of double-voting attacks. If the threshold is crossed down at any point,
    ///      the state changes again to Voting. The validating period will have a defined time
    ///      length, after which (since the point where the proposal was moved from Voting status)
    ///      the resolveProposal() function could be called
    ///  - Executed: After the proposal is resolved
    enum ProposalStatus {Initializing, Voting, Validating, Executed}

    event ProposalCreated(
        uint256 indexed proposalId,
        bytes32 indexed ipfsHash,
        bytes32 indexed proposalType,
        uint256 propositionPowerOfCreator,
        uint256 threshold,
        uint256 maxMovesToVotingAllowed,
        uint256 votingBlocksDuration,
        uint256 validatingBlocksDuration,
        address proposalExecutor
    );
    event StatusChangeToVoting(uint256 indexed proposalId, uint256 movesToVoting);
    event StatusChangeToValidating(uint256 indexed proposalId);
    event StatusChangeToExecuted(uint256 indexed proposalId);
    event VoteEmitted(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 indexed vote,
        IERC20 asset,
        uint256 weight,
        uint256 balance
    );
    event VoteCancelled(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 indexed vote,
        IERC20 asset,
        uint256 weight,
        uint256 balance,
        uint256 proposalStatusBefore
    );
    event YesWins(uint256 indexed proposalId, uint256 abstainVotingPower, uint256 yesVotingPower, uint256 noVotingPower);
    event NoWins(uint256 indexed proposalId, uint256 abstainVotingPower, uint256 yesVotingPower, uint256 noVotingPower);
    event AbstainWins(uint256 indexed proposalId, uint256 abstainVotingPower, uint256 yesVotingPower, uint256 noVotingPower);

    /// @notice 0: Abstain, 1: YES, 2: NO
    uint256 public constant COUNT_CHOICES = 2;

    /// @notice Taking as reference the LEND token supply, a minimum of 13M of LEND token (1% of supply)
    //  on the AssetVotingWeightProvider) can be set as threshold in a new proposal
    uint256 public constant MIN_THRESHOLD = 13000000 ether;

    /// @notice Minimum number of blocks for a proposal's votingBlocksDuration and validatingBlocksDuration
    uint256 public constant MIN_STATUS_DURATION = 1660;  // ~6h with 13s blocktime

    /// @notice Minimum for a proposal's maxMovesToVotingAllowed
    uint256 public constant MIN_MAXMOVESTOVOTINGALLOWED = 2;

    /// @notice Maximum for a proposal's maxMovesToVotingAllowed
    uint256 public constant MAX_MAXMOVESTOVOTINGALLOWED = 6;

    /// @notice Smart contract holding the global parameters needed in this AaveProtoGovernance
    IGovernanceParamsProvider private govParamsProvider;

    Proposal[] private proposals;

    constructor(IGovernanceParamsProvider _govParamsProvider) public {
        govParamsProvider = _govParamsProvider;
    }

    /// @notice Fallback function, not allowing transfer of ETH
    function() external payable {
        revert("ETH_TRANSFER_NOT_ALLOWED");
    }

    /// @notice Registers a new proposal
    ///  - Allowed only for holders of aavePropositionPower with more than 100/propositionPowerThreshold % of the total supply
    ///  - It sets the proposalStatus of the proposal to Voting
    /// @param _proposalType Hashed type of the proposal
    /// @param _ipfsHash bytes32-formatted IPFS hash, removed the first 2 bytes of the multihash (multihash identifier)
    /// @param _threshold Threshold required calculated offchain from the aggregated total supply of the whitelisted
    ///                 assets multiplied by the voting weight of each asset
    /// @param _proposalExecutor Smart contract in charge of .execute() a certain payload
    /// @param _votingBlocksDuration Minimum number of blocks the proposal needs to be in Voting before being able
    ///                              to change to Validating
    /// @param _validatingBlocksDuration Minimum number of blocks the proposal needs to be in Validating before being
    ///                                  able to be executed
    /// @param _maxMovesToVotingAllowed Variable to control how many changes to Voting state are allowed
    function newProposal(
        bytes32 _proposalType,
        bytes32 _ipfsHash,
        uint256 _threshold,
        address _proposalExecutor,
        uint256 _votingBlocksDuration,
        uint256 _validatingBlocksDuration,
        uint256 _maxMovesToVotingAllowed
    ) external {
        IERC20 _propositionPower = govParamsProvider.getPropositionPower();
        uint256 _propositionPowerOfCreator = _propositionPower.balanceOf(msg.sender);

        // Creation of block to avoid "Stack too deep"
        {
            uint256 _propositionPowerTotalSupply = _propositionPower.totalSupply();
            require(_propositionPowerTotalSupply > 0 &&
                _propositionPowerOfCreator >= _propositionPowerTotalSupply.div(govParamsProvider.getPropositionPowerThreshold()),
            "INVALID_PROPOSITION_POWER_BALANCE");
            require(_threshold >= MIN_THRESHOLD, "INVALID_THRESHOLD");
            require(_votingBlocksDuration >= MIN_STATUS_DURATION, "INVALID_VOTING_BLOCKS_DURATION");
            require(_validatingBlocksDuration >= MIN_STATUS_DURATION, "INVALID_VALIDATING_BLOCKS_DURATION");
            require(_maxMovesToVotingAllowed >= MIN_MAXMOVESTOVOTINGALLOWED &&
                _maxMovesToVotingAllowed <= MAX_MAXMOVESTOVOTINGALLOWED,
            "INVALID_MAXVOTESTOVOTINGALLOWED");
        }

        uint256 _proposalId = proposals.push(Proposal({
            proposalType: _proposalType,
            totalVotes: 0,
            threshold: _threshold,
            maxMovesToVotingAllowed: _maxMovesToVotingAllowed,
            movesToVoting: 0,
            votingBlocksDuration: _votingBlocksDuration,
            validatingBlocksDuration: _validatingBlocksDuration,
            currentStatusInitBlock: 0,
            initProposalBlock: block.number,
            proposalExecutor: _proposalExecutor,
            proposalStatus: ProposalStatus.Initializing
        })).sub(1);

        internalMoveToVoting(_proposalId);

        emit ProposalCreated(
            _proposalId,
            _ipfsHash,
            _proposalType,
            _propositionPowerOfCreator,
            _threshold,
            _maxMovesToVotingAllowed,
            _votingBlocksDuration,
            _validatingBlocksDuration,
            _proposalExecutor
        );
    }

    /// @notice Verifies the consistency of the action's params and their correct signature
    function verifyParamsConsistencyAndSignature(
        bytes32 _paramsHashByRelayer,
        bytes32 _paramsHashBySigner,
        bytes memory _signature,
        address _signer
    ) public pure {
        require(_paramsHashBySigner == _paramsHashByRelayer, "INCONSISTENT_HASHES");
        require(_signer == _paramsHashByRelayer.toEthSignedMessageHash().recover(_signature), "SIGNATURE_NOT_VALID");
    }

    /// @notice Verifies the nonce of a voter on a proposal
    /// @param _proposalId The id of the proposal
    /// @param _voter The address of the voter
    /// @param _relayerNonce The nonce submitted by the relayer
    function verifyNonce(uint256 _proposalId, address _voter, uint256 _relayerNonce) public view {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.voters[_voter].nonce.add(1) == _relayerNonce, "INVALID_NONCE");
    }

    /// @notice Validates an action submitted by a relayer
    /// @param _paramsHashByRelayer Hash of the params of the action, hashed by the relayer on-chain
    /// @param _paramsHashBySigner Hash of the params of the action, hashed by the signer off-chain, received by the relayer
    /// @param _signature Signature of the hashed params by the signer, created by the signer offchain, received by the relayer
    /// @param _signer The address of the signer
    /// @param _proposalId The id of the proposal
    /// @param _relayerNonce The nonce by the relayer
    function validateRelayAction(
        bytes32 _paramsHashByRelayer,
        bytes32 _paramsHashBySigner,
        bytes memory _signature,
        address _signer,
        uint256 _proposalId,
        uint256 _relayerNonce)
    public view {
        verifyParamsConsistencyAndSignature(_paramsHashByRelayer, _paramsHashBySigner, _signature, _signer);
        verifyNonce(_proposalId, _signer, _relayerNonce);
    }

    /// @notice Internal function to change proposalStatus to Voting
    /// @param _proposalId The id of the proposal
    function internalMoveToVoting(uint256 _proposalId) internal {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.proposalStatus = ProposalStatus.Voting;
        _proposal.currentStatusInitBlock = block.number;
        _proposal.movesToVoting++;
        emit StatusChangeToVoting(_proposalId, _proposal.movesToVoting);
    }

    /// @notice Internal function to change proposalStatus from Voting to Validating
    /// @param _proposalId The id of the proposal
    function internalMoveToValidating(uint256 _proposalId) internal {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.proposalStatus = ProposalStatus.Validating;
        _proposal.currentStatusInitBlock = block.number;
        emit StatusChangeToValidating(_proposalId);
    }

    /// @notice Internal function to change proposalStatus from Validating to Executed
    ///  once the proposal is resolved
    /// @param _proposalId The id of the proposal
    function internalMoveToExecuted(uint256 _proposalId) internal {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.proposalStatus = ProposalStatus.Executed;
        emit StatusChangeToExecuted(_proposalId);
    }

    /// @notice Function called by a voter to submit his vote directly
    function submitVoteByVoter(uint256 _proposalId, uint256 _vote, IERC20 _asset) external {
        internalSubmitVote(_proposalId, _vote, msg.sender, _asset);
    }

    /// @notice Function called by any address relaying signed vote params from another wallet.
    //   Initially this relayer is thought to be a "hot" wallet of the voter,
    ///  allowing this way to keep the voting asset funds in a "cold" wallet, create an offline
    ///  signature with it and forwarding everything to the "hot" wallet to submit.
    ///  This function is completely opened, as the nonce + signature methods protects against
    ///  any malicious actor.
    function submitVoteByRelayer(
        uint256 _proposalId,
        uint256 _vote,
        address _voter,
        IERC20 _asset,
        uint256 _nonce,
        bytes calldata _signature,
        bytes32 _paramsHashByVoter)
    external {
        validateRelayAction(
            keccak256(abi.encodePacked(_proposalId, _vote, _voter, _asset, _nonce)),
            _paramsHashByVoter,
            _signature,
            _voter,
            _proposalId,
            _nonce);
        internalSubmitVote(_proposalId, _vote, _voter, _asset);
    }

    /// @notice Function called by a voter to cancel his vote directly
    /// @param _proposalId The id of the proposal
    function cancelVoteByVoter(uint256 _proposalId) external {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Voting, "VOTING_STATUS_REQUIRED");
        internalCancelVote(_proposalId, msg.sender);
    }

    /// @notice Same logic as submitVoteByRelayer, but to cancel a current vote by a _voter
    /// @param _proposalId The id of the proposal
    /// @param _nonce The current nonce of the voter in the proposal
    /// @param _voter The address of the voter
    /// @param _signature The signature of the tx, created by the voter and sent to the relayer
    /// @param _paramsHashByVoter Params hash to validate against the signature
    function cancelVoteByRelayer(
        uint256 _proposalId,
        address _voter,
        uint256 _nonce,
        bytes calldata _signature,
        bytes32 _paramsHashByVoter)
    external {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Voting, "VOTING_STATUS_REQUIRED");
        validateRelayAction(
            keccak256(abi.encodePacked(_proposalId, _voter, _nonce)),
            _paramsHashByVoter,
            _signature,
            _voter,
            _proposalId,
            _nonce);
        internalCancelVote(_proposalId, _voter);
    }

    /// @notice Internal function to submit a vote. This function is called from
    ///  the external voting functions, by relayers and directly by voters
    ///  - If the voter has already voted, override the vote with the new one
    ///  - The vote is only allowed if the _asset is whitelisted in the assetVotingWeightProvider
    ///  - The _vote needs to be amongst the valid voting choices
    ///  - The _voter voter address needs to have _asset amount locked
    /// @param _proposalId The id of the proposal
    /// @param _vote A value between 0 and COUNT_CHOICES (included)
    /// @param _asset The asset locked in the _voter address, used to vote
    /// @param _voter the voter address, original signer of the transaction
    function internalSubmitVote(uint256 _proposalId, uint256 _vote, address _voter, IERC20 _asset) internal {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Voting, "VOTING_STATUS_REQUIRED");
        uint256 _assetVotingWeight = govParamsProvider.getAssetVotingWeightProvider().getVotingWeight(_asset);
        require(_assetVotingWeight != 0, "ASSET_NOT_LISTED");
        require(_vote <= COUNT_CHOICES, "INVALID_VOTE_PARAM");
        uint256 _voterAssetBalance = _asset.balanceOf(_voter);
        require(_voterAssetBalance > 0, "INVALID_VOTER_BALANCE");

        // If the voter is replacing a previous vote, cancel the previous one first, to avoid double counting
        if (address(_proposal.voters[_voter].asset) != address(0)) {
            internalCancelVote(_proposalId, _voter);
        }

        uint256 _assetWeight = _assetVotingWeight;
        uint256 _votingPower = _voterAssetBalance.mul(_assetWeight);
        _proposal.totalVotes = _proposal.totalVotes.add(1);
        _proposal.votes[_vote] = _votingPower.add(_proposal.votes[_vote]);
        Voter storage voter = _proposal.voters[_voter];
        voter.vote = _vote;
        voter.weight = _assetWeight;
        voter.balance = _voterAssetBalance;
        voter.asset = _asset;
        voter.nonce = voter.nonce.add(1);

        emit VoteEmitted(_proposalId, _voter, _vote, voter.asset, _assetWeight, _voterAssetBalance);

        tryToMoveToValidating(_proposalId);
    }

    /// @notice Function to move to Validating the proposal in the case the last vote action
    ///  was done before the required votingBlocksDuration passed
    /// @param _proposalId The id of the proposal
    function tryToMoveToValidating(uint256 _proposalId) public {
        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Voting, "VOTING_STATUS_REQUIRED");
        if (_proposal.currentStatusInitBlock.add(_proposal.votingBlocksDuration) <= block.number) {
            for (uint256 i = 0; i <= COUNT_CHOICES; i++) {
                if (_proposal.votes[i] > _proposal.threshold) {
                    internalMoveToValidating(_proposalId);
                    return;
                }
            }
        }
    }

    /// @notice Internal fuction to cancel a vote. This function is called from
    ///  the external cancel vote functions (by relayers and directly by voters),
    ///  from challengeVoters() and from internalSubmitVote()
    /// @param _proposalId The id of the proposal
    /// @param _voter the voter address, original signer of the transaction
    function internalCancelVote(uint256 _proposalId, address _voter) internal {
        Proposal storage _proposal = proposals[_proposalId];
        Voter storage voter = _proposal.voters[_voter];
        Voter memory _cachedVoter = voter;

        require(_cachedVoter.balance > 0, "VOTER_WITHOUT_VOTE");

        _proposal.votes[_cachedVoter.vote] = _proposal.votes[_cachedVoter.vote].sub(
            _cachedVoter.balance.mul(
                _cachedVoter.weight
            )
        );
        _proposal.totalVotes = _proposal.totalVotes.sub(1);
        voter.weight = 0;
        voter.balance = 0;
        voter.vote = 0;
        voter.asset = IERC20(address(0));
        voter.nonce = voter.nonce.add(1);
        emit VoteCancelled(
            _proposalId,
            _voter,
            _cachedVoter.vote,
            _cachedVoter.asset,
            _cachedVoter.weight,
            _cachedVoter.balance,
            uint256(_proposal.proposalStatus)
        );
    }

    /// @notice Called during the Validating period in order to cancel invalid votes
    ///  where the voter was trying a double-voting attack
    /// @param _proposalId The id of the proposal
    /// @param _voters List of voters to challenge
    function challengeVoters(uint256 _proposalId, address[] calldata _voters) external {

        Proposal storage _proposal = proposals[_proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Validating, "VALIDATING_STATUS_REQUIRED");

        for (uint256 i = 0; i < _voters.length; i++) {
            address _voterAddress = _voters[i];
            Voter memory _voter = _proposal.voters[_voterAddress];
            uint256 _voterAssetBalance = _voter.asset.balanceOf(_voterAddress);
            if (_voterAssetBalance < _voter.balance) {
                internalCancelVote(_proposalId, _voterAddress);
            }
        }

        if (_proposal.movesToVoting < _proposal.maxMovesToVotingAllowed &&
            _proposal.votes[getLeadingChoice(_proposalId)] < _proposal.threshold) {
            internalMoveToVoting(_proposalId);
        }
    }

    /// @notice Function to resolve a proposal
    ///  - It only validates that the state is correct and the validating minimum blocks have passed,
    ///    as at that point, the % of the leading option doesn't matter
    ///  - If the resolution is YES, do a DELEGATECALL to the execute() of the proposalExecutor of the proposal
    ///  - If the resolution is ABSTAIN or NO, just change the state to Executed
    /// @param _proposalId The id of the proposal
    function resolveProposal(uint256 _proposalId) external {
        Proposal storage _proposal = proposals[_proposalId];

        require(_proposal.proposalStatus == ProposalStatus.Validating, "VALIDATING_STATUS_REQUIRED");
        require(_proposal.currentStatusInitBlock.add(_proposal.validatingBlocksDuration) <= block.number, "NOT_ENOUGH_BLOCKS_IN_VALIDATING");
        require(_proposal.initProposalBlock.add(getLimitBlockOfProposal(_proposalId)) >= block.number, "BLOCK_ABOVE_THE_PROPOSAL_LIMIT");

        uint256 _leadingChoice = getLeadingChoice(_proposalId);

        if (_leadingChoice == 1) {
            (bool _success,) = _proposal.proposalExecutor.delegatecall(abi.encodeWithSignature("execute()"));
            require(_success, "resolveProposal(). DELEGATECALL_REVERTED");
            emit YesWins(_proposalId, _proposal.votes[0], _proposal.votes[1], _proposal.votes[2]);
        } else if (_leadingChoice == 2) {
            emit NoWins(_proposalId, _proposal.votes[0], _proposal.votes[1], _proposal.votes[2]);
        } else {
            emit AbstainWins(_proposalId, _proposal.votes[0], _proposal.votes[1], _proposal.votes[2]);
        }
        internalMoveToExecuted(_proposalId);
    }

    /// @notice Return the limit block of the proposal from where it will not be possible to resolve it anymore
    ///  - The double of the sum(voting blocks, validating blocks) multiplied by the maxMovesToVotingAllowed
    /// @param _proposalId The id of the proposal
    /// @return uint256 The limit block number
    function getLimitBlockOfProposal(uint256 _proposalId) public view returns(uint256 _limitBlockProposal) {
        Proposal memory _proposal = proposals[_proposalId];
        uint256 _maxMovesToVotingAllowed = _proposal.maxMovesToVotingAllowed;
        uint256 _votingBlocksDuration = _proposal.votingBlocksDuration;
        uint256 _validatingBlocksDuration = _proposal.validatingBlocksDuration;
        _limitBlockProposal = _maxMovesToVotingAllowed.mul(2).mul(
            _votingBlocksDuration.add(_validatingBlocksDuration)
        );
    }

    /// @notice Gets the current leading choice in votes
    /// @param _proposalId The id of the proposal
    /// @return uint256 The numeric reference of the choice
    function getLeadingChoice(uint256 _proposalId) public view returns(uint256) {
        uint256 _leadingChoice = 0;
        uint256 _tempCandidate = 0;
        Proposal storage _proposal = proposals[_proposalId];
        for (uint256 i = 0; i <= COUNT_CHOICES; i++) {
            if (_proposal.votes[i] > _tempCandidate) {
                _leadingChoice = i;
                _tempCandidate = _proposal.votes[i];
            }
        }
        return _leadingChoice;
    }

    /// @notice Get the basic data of a proposal
    /// @param _proposalId The id of the proposal
    /// @return Proposal The basic data of the proposal
    function getProposalBasicData(uint256 _proposalId) external view returns(
        uint256 _totalVotes,
        uint256 _threshold,
        uint256 _maxMovesToVotingAllowed,
        uint256 _movesToVoting,
        uint256 _votingBlocksDuration,
        uint256 _validatingBlocksDuration,
        uint256 _currentStatusInitBlock,
        uint256 _initProposalBlock,
        uint256 _proposalStatus,
        address _proposalExecutor,
        bytes32 _proposalType
    ) {
        require(_proposalId < proposals.length, "INVALID_PROPOSAL_ID");
        Proposal storage _proposal = proposals[_proposalId];
        _totalVotes = _proposal.totalVotes;
        _threshold = _proposal.threshold;
        _maxMovesToVotingAllowed = _proposal.maxMovesToVotingAllowed;
        _movesToVoting = _proposal.movesToVoting;
        _votingBlocksDuration = _proposal.votingBlocksDuration;
        _validatingBlocksDuration = _proposal.validatingBlocksDuration;
        _currentStatusInitBlock = _proposal.currentStatusInitBlock;
        _initProposalBlock = _proposal.initProposalBlock;
        _proposalStatus = uint256(_proposal.proposalStatus);
        _proposalExecutor = _proposal.proposalExecutor;
        _proposalType = _proposal.proposalType;
    }

    /// @notice Get the voting data of a voter on a particular proposal
    /// @param _proposalId The id of the proposal
    /// @param _voterAddress _voterAddress The address of the voter
    /// @return Voter The data of the voter
    function getVoterData(uint256 _proposalId, address _voterAddress) external view returns(
        uint256 _vote,
        uint256 _weight,
        uint256 _balance,
        uint256 _nonce,
        IERC20 _asset
    ) {
        require(_proposalId < proposals.length, "INVALID_PROPOSAL_ID");
        Voter storage _voter = proposals[_proposalId].voters[_voterAddress];
        _vote = _voter.vote;
        _weight = _voter.weight;
        _balance = _voter.balance;
        _nonce = _voter.nonce;
        _asset = _voter.asset;
    }

    /// @notice Get the total votes-related data of a proposal
    /// @param _proposalId The id of the proposal
    /// @return uint256[3] The array with the accumulated voting power for every choice (ABSTAIN, YES, NO)
    function getVotesData(uint256 _proposalId) external view returns(uint256[3] memory) {
        require(_proposalId < proposals.length, "INVALID_PROPOSAL_ID");
        Proposal storage _proposal = proposals[_proposalId];
        uint256[3] memory _votes = [_proposal.votes[0],_proposal.votes[1],_proposal.votes[2]];
        return _votes;
    }

    /// @notice Return the address of the govParamsProvider
    /// @return address The address of the govParamsProvider
    function getGovParamsProvider() external view returns(address _govParamsProvider) {
        return address(govParamsProvider);
    }

}"
    },
    "@openzeppelin/contracts/cryptography/ECDSA.sol": {
      "content": "pragma solidity ^0.5.0;

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
"
    },
    "contracts/interfaces/IGovernanceParamsProvider.sol": {
      "content": "pragma solidity ^0.5.16;

import "./IAssetVotingWeightProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGovernanceParamsProvider {
    function setPropositionPowerThreshold(uint256 _propositionPowerThreshold) external;
    function setPropositionPower(IERC20 _propositionPower) external;
    function setAssetVotingWeightProvider(IAssetVotingWeightProvider _assetVotingWeightProvider) external;
    function getPropositionPower() external view returns(IERC20);
    function getPropositionPowerThreshold() external view returns(uint256);
    function getAssetVotingWeightProvider() external view returns(IAssetVotingWeightProvider);
}"
    },
    "contracts/interfaces/IAssetVotingWeightProvider.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAssetVotingWeightProvider {
    function getVotingWeight(IERC20 _asset) external view returns(uint256);
    function setVotingWeight(IERC20 _asset, uint256 _weight) external;
}"
    },
    "contracts/interfaces/IProposalExecutor.sol": {
      "content": "pragma solidity ^0.5.16;

interface IProposalExecutor {
    function execute() external;
}"
    },
    "contracts/interfaces/IAaveProtoGovernance.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IAaveProtoGovernance {
    function newProposal(
        bytes32 _proposalType,
        bytes32 _ipfsHash,
        uint256 _threshold,
        address _proposalExecutor,
        uint256 _votingBlocksDuration,
        uint256 _validatingBlocksDuration,
        uint256 _maxMovesToVotingAllowed
    ) external;
    function submitVoteByVoter(uint256 _proposalId, uint256 _vote, IERC20 _asset) external;
    function submitVoteByRelayer(
        uint256 _proposalId,
        uint256 _vote,
        address _voter,
        IERC20 _asset,
        uint256 _nonce,
        bytes calldata _signature,
        bytes32 _paramsHashByVoter
    ) external;
    function cancelVoteByVoter(uint256 _proposalId) external;
    function cancelVoteByRelayer(
        uint256 _proposalId,
        address _voter,
        uint256 _nonce,
        bytes calldata _signature,
        bytes32 _paramsHashByVoter
    ) external;
    function tryToMoveToValidating(uint256 _proposalId) external;
    function challengeVoters(uint256 _proposalId, address[] calldata _voters) external;
    function resolveProposal(uint256 _proposalId) external;

    function getLimitBlockOfProposal(uint256 _proposalId) external view returns(uint256 _limitBlockProposal);
    function getLeadingChoice(uint256 _proposalId) external view returns(uint256);
    function getProposalBasicData(uint256 _proposalId) external view returns(
        uint256 _totalVotes,
        uint256 _threshold,
        uint256 _maxMovesToVotingAllowed,
        uint256 _movesToVoting,
        uint256 _votingBlocksDuration,
        uint256 _validatingBlocksDuration,
        uint256 _currentStatusInitBlock,
        uint256 _initProposalBlock,
        uint256 _proposalStatus,
        address _proposalExecutor,
        bytes32 _proposalType
    );
    function getVoterData(uint256 _proposalId, address _voterAddress) external view returns(
        uint256 _vote,
        uint256 _weight,
        uint256 _balance,
        uint256 _nonce,
        IERC20 _asset
    );
    function getVotesData(uint256 _proposalId) external view returns(uint256[3] memory);
    function getGovParamsProvider() external view returns(address _govParamsProvider);

    function verifyParamsConsistencyAndSignature(
        bytes32 _paramsHashByRelayer,
        bytes32 _paramsHashBySigner,
        bytes calldata _signature,
        address _signer
    ) external pure;
    function verifyNonce(uint256 _proposalId, address _voter, uint256 _relayerNonce) external view;
    function validateRelayAction(
        bytes32 _paramsHashByRelayer,
        bytes32 _paramsHashBySigner,
        bytes calldata _signature,
        address _signer,
        uint256 _proposalId,
        uint256 _relayerNonce
    ) external view;
}"
    },
    "contracts/governance/AssetVotingWeightProvider.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";

import "../interfaces/IAssetVotingWeightProvider.sol";

/// @title AssetVotingWeightProvider
/// @notice Smart contract to register whitelisted assets with its voting weight per asset
///  - The ownership is on the AaveProtoGovernance, that way the whitelisting of new assets or
///    the change of the weight of a current one will be done through governance.
contract AssetVotingWeightProvider is Ownable, IAssetVotingWeightProvider {

    event AssetWeightSet(IERC20 indexed asset, address indexed setter, uint256 weight);

    mapping(address => uint256) private votingWeights;

    /// @notice Constructor
    /// @param _assets Dynamic array of asset addresses
    /// @param _weights Dynamic array of asset weights, for each one of _assets
    constructor(IERC20[] memory _assets, uint256[] memory _weights) public {
        require(_assets.length == _weights.length, "INCONSISTENT_ASSETS_WEIGHTS_LENGTHS");
        for (uint256 i = 0; i < _assets.length; i++) {
            internalSetVotingWeight(_assets[i], _weights[i]);
        }
    }

    /// @notice Gets the weight of an asset
    /// @param _asset The asset smart contract address
    /// @return The uint256 weight of the asset
    function getVotingWeight(IERC20 _asset) public view returns(uint256) {
        address asset = address(_asset);
        return votingWeights[asset];
    }

    /// @notice Sets the weight for an asset
    /// @param _asset The asset smart contract address
    /// @param _weight The asset smart contract address
    /// @return The uint256 weight of the asset
    function setVotingWeight(IERC20 _asset, uint256 _weight) external onlyOwner {
        internalSetVotingWeight(_asset, _weight);
    }

    /// @notice Internal function to set the weight for an asset
    /// @param _asset The asset smart contract address
    /// @return The uint256 weight of the asset
    function internalSetVotingWeight(IERC20 _asset, uint256 _weight) internal {
        address asset = address(_asset);
        votingWeights[asset] = _weight;
        emit AssetWeightSet(_asset, msg.sender, _weight);
    }

}"
    },
    "@openzeppelin/contracts/ownership/Ownable.sol": {
      "content": "pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "contracts/governance/GovernanceParamsProvider.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../interfaces/IGovernanceParamsProvider.sol";

contract GovernanceParamsProvider is Ownable, IGovernanceParamsProvider {

    event AssetVotingWeightProviderSet(address indexed setter, IAssetVotingWeightProvider  assetVotingWeightProvider);
    event PropositionPowerThresholdSet(address indexed setter, uint256  propositionPowerThreshold);
    event PropositionPowerSet(address indexed setter, IERC20 propositionPower);

    /// @notice Address of the smart contract providing the weight of the whitelisted assets
    IAssetVotingWeightProvider private assetVotingWeightProvider;

    /// @notice Used to get the percentage of the supply of propositionPower needed to register a proposal
    uint256 private propositionPowerThreshold;

    /// @notice Address of the asset to control who can register new proposals
    IERC20 private propositionPower;

    constructor(
        uint256 _propositionPowerThreshold,
        IERC20 _propositionPower,
        IAssetVotingWeightProvider _assetVotingWeightProvider
    ) public {
        internalSetPropositionPowerThreshold(_propositionPowerThreshold);
        internalSetPropositionPower(_propositionPower);
        internalSetAssetVotingWeightProvider(_assetVotingWeightProvider);
    }

    /// @notice Sets the propositionPowerThreshold
    /// @param _propositionPowerThreshold The address of the propositionPowerThreshold
    function setPropositionPowerThreshold(uint256 _propositionPowerThreshold) external onlyOwner {
        internalSetPropositionPowerThreshold(_propositionPowerThreshold);
    }

    /// @notice Sets the propositionPower
    /// @param _propositionPower The address of the propositionPower
    function setPropositionPower(IERC20 _propositionPower) external onlyOwner {
        internalSetPropositionPower(_propositionPower);
    }

    /// @notice Sets the assetVotingWeightProvider
    /// @param _assetVotingWeightProvider The address of the assetVotingWeightProvider
    function setAssetVotingWeightProvider(IAssetVotingWeightProvider _assetVotingWeightProvider) external onlyOwner {
        internalSetAssetVotingWeightProvider(_assetVotingWeightProvider);
    }

    /// @notice Sets the propositionPowerThreshold
    /// @param _propositionPowerThreshold The numeric propositionPowerThreshold
    function internalSetPropositionPowerThreshold(uint256 _propositionPowerThreshold) internal {
        propositionPowerThreshold = _propositionPowerThreshold;
        emit PropositionPowerThresholdSet(msg.sender, _propositionPowerThreshold);
    }

    /// @notice Sets the propositionPower
    /// @param _propositionPower The address of the propositionPower
    function internalSetPropositionPower(IERC20 _propositionPower) internal {
        propositionPower = _propositionPower;
        emit PropositionPowerSet(msg.sender, _propositionPower);
    }

    /// @notice Sets the assetVotingWeightProvider
    /// @param _assetVotingWeightProvider The address of the assetVotingWeightProvider
    function internalSetAssetVotingWeightProvider(IAssetVotingWeightProvider _assetVotingWeightProvider) internal {
        assetVotingWeightProvider = _assetVotingWeightProvider;
        emit AssetVotingWeightProviderSet(msg.sender, _assetVotingWeightProvider);
    }

    /// @notice Return the address of the propositionPower
    /// @return The address of the propositionPower
    function getPropositionPower() external view returns(IERC20) {
        return propositionPower;
    }

    /// @notice Returns the propositionPowerThreshold
    /// @return The propositionPowerThreshold
    function getPropositionPowerThreshold() external view returns(uint256) {
        return propositionPowerThreshold;
    }

    /// @notice Returns the assetVotingWeightProvider address
    /// @return The address of the assetVotingWeightProvider
    function getAssetVotingWeightProvider() external view returns(IAssetVotingWeightProvider) {
        return assetVotingWeightProvider;
    }
}"
    },
    "contracts/interfaces/ILendingPoolAddressesProvider.sol": {
      "content": "pragma solidity ^0.5.16;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

contract ILendingPoolAddressesProvider {

    function getLendingPool() public view returns (address);
    function setLendingPoolImpl(address _pool) public;

    function getLendingPoolCore() public view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) public;

    function getLendingPoolConfigurator() public view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) public;

    function getLendingPoolDataProvider() public view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) public;

    function getLendingPoolParametersProvider() public view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public;

    function getTokenDistributor() public view returns (address);
    function setTokenDistributor(address _tokenDistributor) public;


    function getFeeProvider() public view returns (address);
    function setFeeProviderImpl(address _feeProvider) public;

    function getLendingPoolLiquidationManager() public view returns (address);
    function setLendingPoolLiquidationManager(address _manager) public;

    function getLendingPoolManager() public view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) public;

    function getPriceOracle() public view returns (address);
    function setPriceOracle(address _priceOracle) public;

    function getLendingRateOracle() public view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) public;

}"
    },
    "contracts/libraries/openzeppelin-upgradeability/AdminUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./BaseAdminUpgradeabilityProxy.sol";

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
    /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    constructor(address _logic, address _admin, bytes memory _data) public payable UpgradeabilityProxy(_logic, _data) {
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/BaseAdminUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./UpgradeabilityProxy.sol";

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
   * @return The address of the proxy admin.
   */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
   * @return The address of the implementation.
   */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
   * @return The admin slot.
   */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            adm := sload(slot)
        }
    }

    /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
   * @dev Only fall back when the sender is not the admin.
   */
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/UpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    constructor(address _logic, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/BaseUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
    event Upgraded(address indexed implementation);

    /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/Proxy.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
    /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
    function() external payable {
        _fallback();
    }

    /**
   * @return The Address of the implementation.
   */
    function _implementation() internal view returns (address);

    /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }

    /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
    function _willFallback() internal {}

    /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/Initializable.sol": {
      "content": "pragma solidity >=0.4.24 <0.6.0;

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
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/InitializableAdminUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./BaseAdminUpgradeabilityProxy.sol";
import "./InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
    /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, address _admin, bytes memory _data) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(_logic, _data);
        assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/InitializableUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}
"
    },
    "contracts/libraries/openzeppelin-upgradeability/VersionedInitializable.sol": {
      "content": "pragma solidity >=0.4.24 <0.6.0;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 private lastInitializedRevision = 0;

    /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
    bool private initializing;

    /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(initializing || isConstructor() || revision > lastInitializedRevision, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure returns(uint256);


    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}
"
    },
    "contracts/mocks/AddressStorage.sol": {
      "content": "pragma solidity ^0.5.16;

contract AddressStorage {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
    }

}
"
    },
    "contracts/mocks/FailingProposalExecutor.sol": {
      "content": "pragma solidity ^0.5.16;

import "../interfaces/IProposalExecutor.sol";

contract FailingProposalExecutor is IProposalExecutor {

    /// @notice Fallback function, not allowing transfer of ETH
    function() external payable {
        revert("ETH_TRANSFER_NOT_ALLOWED");
    }

    function execute() external {
        require(false, "FORCED_REVERT");
    }

}"
    },
    "contracts/mocks/LendingPoolAddressesProvider.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../libraries/openzeppelin-upgradeability/InitializableAdminUpgradeabilityProxy.sol";

import "./AddressStorage.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

/**
* @title LendingPoolAddressesProvider contract
* @notice Is the main registry of the protocol. All the different components of the protocol are accessible
* through the addresses provider.
* @author Aave
**/

contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider, AddressStorage {
    //events
    event LendingPoolUpdated(address indexed newAddress);
    event LendingPoolCoreUpdated(address indexed newAddress);
    event LendingPoolParametersProviderUpdated(address indexed newAddress);
    event LendingPoolManagerUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolLiquidationManagerUpdated(address indexed newAddress);
    event LendingPoolDataProviderUpdated(address indexed newAddress);
    event EthereumAddressUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event FeeProviderUpdated(address indexed newAddress);
    event TokenDistributorUpdated(address indexed newAddress);

    event ProxyCreated(bytes32 id, address indexed newAddress);

    bytes32 private constant LENDING_POOL = "LENDING_POOL";
    bytes32 private constant LENDING_POOL_CORE = "LENDING_POOL_CORE";
    bytes32 private constant LENDING_POOL_CONFIGURATOR = "LENDING_POOL_CONFIGURATOR";
    bytes32 private constant LENDING_POOL_PARAMETERS_PROVIDER = "PARAMETERS_PROVIDER";
    bytes32 private constant LENDING_POOL_MANAGER = "LENDING_POOL_MANAGER";
    bytes32 private constant LENDING_POOL_LIQUIDATION_MANAGER = "LIQUIDATION_MANAGER";
    bytes32 private constant LENDING_POOL_FLASHLOAN_PROVIDER = "FLASHLOAN_PROVIDER";
    bytes32 private constant DATA_PROVIDER = "DATA_PROVIDER";
    bytes32 private constant ETHEREUM_ADDRESS = "ETHEREUM_ADDRESS";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant LENDING_RATE_ORACLE = "LENDING_RATE_ORACLE";
    bytes32 private constant FEE_PROVIDER = "FEE_PROVIDER";
    bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";
    bytes32 private constant TOKEN_DISTRIBUTOR = "TOKEN_DISTRIBUTOR";


    /**
    * @dev returns the address of the LendingPool proxy
    * @return the lending pool proxy address
    **/
    function getLendingPool() public view returns (address) {
        return getAddress(LENDING_POOL);
    }


    /**
    * @dev updates the implementation of the lending pool
    * @param _pool the new lending pool implementation
    **/
    function setLendingPoolImpl(address _pool) public onlyOwner {
        updateImplInternal(LENDING_POOL, _pool);
        emit LendingPoolUpdated(_pool);
    }

    /**
    * @dev returns the address of the LendingPoolCore proxy
    * @return the lending pool core proxy address
     */
    function getLendingPoolCore() public view returns (address payable) {
        address payable core = address(uint160(getAddress(LENDING_POOL_CORE)));
        return core;
    }

    /**
    * @dev updates the implementation of the lending pool core
    * @param _lendingPoolCore the new lending pool core implementation
    **/
    function setLendingPoolCoreImpl(address _lendingPoolCore) public onlyOwner {
        updateImplInternal(LENDING_POOL_CORE, _lendingPoolCore);
        emit LendingPoolCoreUpdated(_lendingPoolCore);
    }

    /**
    * @dev returns the address of the LendingPoolConfigurator proxy
    * @return the lending pool configurator proxy address
    **/
    function getLendingPoolConfigurator() public view returns (address) {
        return getAddress(LENDING_POOL_CONFIGURATOR);
    }

    /**
    * @dev updates the implementation of the lending pool configurator
    * @param _configurator the new lending pool configurator implementation
    **/
    function setLendingPoolConfiguratorImpl(address _configurator) public onlyOwner {
        updateImplInternal(LENDING_POOL_CONFIGURATOR, _configurator);
        emit LendingPoolConfiguratorUpdated(_configurator);
    }

    /**
    * @dev returns the address of the LendingPoolDataProvider proxy
    * @return the lending pool data provider proxy address
     */
    function getLendingPoolDataProvider() public view returns (address) {
        return getAddress(DATA_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool data provider
    * @param _provider the new lending pool data provider implementation
    **/
    function setLendingPoolDataProviderImpl(address _provider) public onlyOwner {
        updateImplInternal(DATA_PROVIDER, _provider);
        emit LendingPoolDataProviderUpdated(_provider);
    }

    /**
    * @dev returns the address of the LendingPoolParametersProvider proxy
    * @return the address of the Lending pool parameters provider proxy
    **/
    function getLendingPoolParametersProvider() public view returns (address) {
        return getAddress(LENDING_POOL_PARAMETERS_PROVIDER);
    }

    /**
    * @dev updates the implementation of the lending pool parameters provider
    * @param _parametersProvider the new lending pool parameters provider implementation
    **/
    function setLendingPoolParametersProviderImpl(address _parametersProvider) public onlyOwner {
        updateImplInternal(LENDING_POOL_PARAMETERS_PROVIDER, _parametersProvider);
        emit LendingPoolParametersProviderUpdated(_parametersProvider);
    }

    /**
    * @dev returns the address of the FeeProvider proxy
    * @return the address of the Fee provider proxy
    **/
    function getFeeProvider() public view returns (address) {
        return getAddress(FEE_PROVIDER);
    }

    /**
    * @dev updates the implementation of the FeeProvider proxy
    * @param _feeProvider the new lending pool fee provider implementation
    **/
    function setFeeProviderImpl(address _feeProvider) public {
        updateImplInternal(FEE_PROVIDER, _feeProvider);
        emit FeeProviderUpdated(_feeProvider);
    }

    /**
    * @dev returns the address of the LendingPoolLiquidationManager. Since the manager is used
    * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
    * the addresses are changed directly.
    * @return the address of the Lending pool liquidation manager
    **/

    function getLendingPoolLiquidationManager() public view returns (address) {
        return getAddress(LENDING_POOL_LIQUIDATION_MANAGER);
    }

    /**
    * @dev updates the address of the Lending pool liquidation manager
    * @param _manager the new lending pool liquidation manager address
    **/
    function setLendingPoolLiquidationManager(address _manager) public onlyOwner {
        _setAddress(LENDING_POOL_LIQUIDATION_MANAGER, _manager);
        emit LendingPoolLiquidationManagerUpdated(_manager);
    }

    /**
    * @dev the functions below are storing specific addresses that are outside the context of the protocol
    * hence the upgradable proxy pattern is not used
    **/


    function getLendingPoolManager() public view returns (address) {
        return getAddress(LENDING_POOL_MANAGER);
    }

    function setLendingPoolManager(address _lendingPoolManager) public {
        _setAddress(LENDING_POOL_MANAGER, _lendingPoolManager);
        emit LendingPoolManagerUpdated(_lendingPoolManager);
    }

    function getPriceOracle() public view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function setPriceOracle(address _priceOracle) public onlyOwner {
        _setAddress(PRICE_ORACLE, _priceOracle);
        emit PriceOracleUpdated(_priceOracle);
    }

    function getLendingRateOracle() public view returns (address) {
        return getAddress(LENDING_RATE_ORACLE);
    }

    function setLendingRateOracle(address _lendingRateOracle) public onlyOwner {
        _setAddress(LENDING_RATE_ORACLE, _lendingRateOracle);
        emit LendingRateOracleUpdated(_lendingRateOracle);
    }


    function getTokenDistributor() public view returns (address) {
        return getAddress(TOKEN_DISTRIBUTOR);
    }

    function setTokenDistributor(address _tokenDistributor) public onlyOwner {
        _setAddress(TOKEN_DISTRIBUTOR, _tokenDistributor);
        emit TokenDistributorUpdated(_tokenDistributor);
    }


    /**
    * @dev internal function to update the implementation of a specific component of the protocol
    * @param _id the id of the contract to be updated
    * @param _newAddress the address of the new implementation
    **/
    function updateImplInternal(bytes32 _id, address _newAddress) internal {
        address payable proxyAddress = address(uint160(getAddress(_id)));

        InitializableAdminUpgradeabilityProxy proxy = InitializableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

        if (proxyAddress == address(0)) {
            proxy = new InitializableAdminUpgradeabilityProxy();
            proxy.initialize(_newAddress, address(this), params);
            _setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
        } else {
            proxy.upgradeToAndCall(_newAddress, params);
        }

    }
}
"
    },
    "contracts/mocks/ProposalExecutor.sol": {
      "content": "pragma solidity ^0.5.16;

import "../interfaces/IProposalExecutor.sol";
import "./LendingPoolAddressesProvider.sol";

contract ProposalExecutor is IProposalExecutor {

    event ProposalExecuted(
        address indexed executor,
        address indexed lendingPoolAddressesProvider,
        address indexed newAddress
    );

    /// @notice Fallback function, not allowing transfer of ETH
    function() external payable {
        revert("ETH_TRANSFER_NOT_ALLOWED");
    }

    function execute() external {
        // Hardcoded address because of the determinism on buidlerevm
        address _addressesProvider = 0x7c2C195CD6D34B8F845992d380aADB2730bB9C6F;
        address _newLendingPoolManager = 0x0000000000000000000000000000000000000001;
        LendingPoolAddressesProvider(_addressesProvider).setLendingPoolManager(_newLendingPoolManager);
        emit ProposalExecuted(address(this), _addressesProvider, _newLendingPoolManager);
    }

}"
    },
    "contracts/mocks/TestVotingAssetA.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/// @title TestVotingAssetA
/// @author Aave
/// @notice An ERC20 mintable and burnable token to use as whitelisted
///  voting asset on proposals
contract TestVotingAssetA is ERC20Burnable, ERC20Mintable, ERC20Detailed {

    /// @notice Constructor
    /// @param name Asset name
    /// @param symbol Asset symbol
    /// @param decimals Asset decimals
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
    public ERC20Detailed(name, symbol, decimals) {}
}"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}
"
    },
    "contracts/mocks/TestVotingAssetB.sol": {
      "content": "pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/// @title TestVotingAssetB
/// @author Aave
/// @notice An ERC20 mintable and burnable token to use as whitelisted
///  voting asset on proposals
contract TestVotingAssetB is ERC20Burnable, ERC20Mintable, ERC20Detailed {

    /// @notice Constructor
    /// @param name Asset name
    /// @param symbol Asset symbol
    /// @param decimals Asset decimals
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
    public ERC20Detailed(name, symbol, decimals) {}
}"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": false
    },
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
    "evmVersion": "istanbul",
    "libraries": {}
  }
}}