{"Context.sol":{"content":"pragma solidity ^0.5.0;

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
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"},"ERC20.sol":{"content":"pragma solidity ^0.5.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

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

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function allowance(address owner, address spender)
        public
        view
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}
"},"ERC20Detailed.sol":{"content":"pragma solidity ^0.5.0;

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
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
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

"},"Esm.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.7.0;

import "./Owned.sol";
import "./WhiteList.sol";

interface ITokenStake {
    function updateIndex() external;
}

contract Esm is Owned, WhiteList {
    /// @notice Access stake pause
    uint256 public stakeLive = 1;
    /// @notice Access redeem pause
    uint256 public redeemLive = 1;
    /// @notice System closed time
    uint256 public time;
    /// @notice TokenStake for updating on closed
    ITokenStake public tokenStake;

    /// @notice System closed yet event
    event ShutDown(uint256 blocknumber, uint256 time);

    /**
     * @notice Construct a new Esm
     */
    constructor() public Owned(msg.sender) {}

    /**
     * @notice Set with tokenStake
     * @param _tokenStake Address of tokenStake
     */
    function setupTokenStake(address _tokenStake) public onlyWhiter {
        tokenStake = ITokenStake(_tokenStake);
    }

    /**
     * @notice Open stake, if stake pasued
     */
    function openStake() external onlyWhiter {
        stakeLive = 1;
    }

    /**
     * @notice Paused stake, if stake opened
     */
    function pauseStake() external onlyWhiter {
        stakeLive = 0;
    }

    /**
     * @notice Open redeem, if redeem paused
     */
    function openRedeem() external onlyWhiter {
        redeemLive = 1;
    }

    /**
     * @notice Pause redeem, if redeem opened
     */
    function pauseRedeem() external onlyWhiter {
        redeemLive = 0;
    }

    /**
     * @notice Status of staking
     */
    function isStakePaused() external view returns (bool) {
        return stakeLive == 0;
    }

    /**
     * @notice Status of redeem
     */
    function isRedeemPaused() external view returns (bool) {
        return redeemLive == 0;
    }

    /**
     * @notice Status of closing-sys
     */
    function isClosed() external view returns (bool) {
        return time > 0;
    }

    /**
     * @notice If anything error, project manager can shutdown it
     *         anybody cant stake, but can redeem
     */
    function shutdown() external onlyWhiter {
        require(time == 0, "System closed yet.");
        tokenStake.updateIndex();
        time = block.timestamp;
        emit ShutDown(block.number, time);
    }
}
"},"IDparam.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IDparam {
    event FeeRateEvent(uint256 feeRate);
    event LiquidationLineEvent(uint256 liquidationRate);
    event MinMintEvent(uint256 minMint);

    function stakeRate() external view returns (uint256);

    function liquidationLine() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function minMint() external view returns (uint256);

    function setFeeRate(uint256 _feeRate) external;

    function setLiquidationLine(uint256 _liquidationLine) external;

    function setMinMint(uint256 _minMint) external;

    function isLiquidation(uint256 price) external view returns (bool);

    function isNormal(uint256 price) external view returns (bool);
}
"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
"},"Math.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}
"},"Owned.sol":{"content":"pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}
"},"Pausable.sol":{"content":"pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/Pausable
contract Pausable is Owned {
    uint256 public lastPauseTime;
    bool public paused;

    constructor() internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = now;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(
            !paused,
            "This action cannot be performed while the contract is paused"
        );
        _;
    }
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"},"SLPStake.sol":{"content":"pragma solidity >=0.5.0 <0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./STPT.sol";
import "./IERC20.sol";
import "./Owned.sol";
import "./IDparam.sol";
import "./WhiteList.sol";

interface IESM {
    function isStakePaused() external view returns (bool);

    function isRedeemPaused() external view returns (bool);

    function isClosed() external view returns (bool);

    function time() external view returns (uint256);

    function shutdown() external;
}

contract SLPStake is Owned, WhiteList {
    using Math for uint256;
    using SafeMath for uint256;
    
       /**
     * @notice Struct reward pools state
     * @param index Accumulated earnings index
     * @param block Update index, updating blockNumber together
     */
    struct RewardState {
        uint256 index;
        uint256 block;
    }
    /**
     * @notice reward pools state
     * @param index Accumulated earnings index by staker
     * @param reward Accumulative reward
     */
    struct StakerState {
        uint256 index;
        uint256 reward;
    }
    
      /// @notice TThe reward pool put into by the project side 
    uint256 public reward;
    /// @notice The number of token per-block 
    uint256 public rewardSpeed = 11.57e18;
    /// @notice Inital index  
    uint256 public initialIndex = 1e36;
    /// @notice Amplification factor 
    uint256 public doubleScale = 1e36;
    /// @notice The instance reward pools state
    RewardState public rewardState;

    /// @notice All staker-instances state 
    mapping(address => StakerState) public stakerStates;
    
    /// @notice Token address
    STPTToken token;
    IERC20 coin;
    /// @notice The amount by staker with token
    mapping(address => uint256) public tokens;
    /// @notice The total amount of out-coin in sys
    uint256 public totalToken;
       /// @notice Dparam address
    IDparam params;
    /// @notice Esm address
    IESM esm;
    

    /// @notice Setup Dparam address success
    event SetupParam(address param);
    /// @notice Setup Esm address success
    event SetupEsm(address esm);
    /// @notice Setup Token&Coin address success
    event SetupCoin(address token,address coin);
    /// @notice Stake success
    event StakeEvent(uint256 token);
    /// @notice redeem success
    event RedeemEvent(uint256 token);
    /// @notice Update index success
    event IndexUpdate(uint256 delt, uint256 block, uint256 index);
    /// @notice ClaimToken success
    event ClaimToken(address holder, uint256 amount);
    /// @notice InjectReward success
    event InjectReward(uint256 amount);
    /// @notice ExtractReward success
    event ExtractReward(address reciver, uint256 amount);

     constructor(address _esm) public Owned(msg.sender) {
          esm = IESM(_esm);
       rewardState = RewardState(initialIndex, getBlockNumber());
    }
    
      /**
     * @notice get StableToken address.
     * @return ERC20 address
     */
    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    /**
     * @notice inject token address & coin address only once.
     * @param _token token address
     */
    function setup(address _token,address _coin) public onlyWhiter {
        token = STPTToken(_token);
        coin = IERC20(_coin);
        emit SetupCoin(_token,_coin);
    }
    
     /**
     * @notice Get the number of debt by the `account` 
     * @param account token address
     * @return (tokenAmount)
     */
    function debtOf(address account) public view returns (uint256) {
        return (tokens[account]);
    }
    
     /**
     * @notice Normally redeem anyAmount internal
     */
    function stake(uint256 tokenAmount) public {
        require(!esm.isStakePaused(), "Stake paused");
        
        address from = msg.sender;
        
        accuredToken(from);
        
        token.transferFrom(from, address(this), tokenAmount);
  
        totalToken = totalToken.add(tokenAmount);
        tokens[from] = tokens[from].add(tokenAmount);
        emit StakeEvent(tokenAmount);
    }
    
    /**
     * @notice Normally redeem anyAmount internal 
     * @param receiver Address of receiving
     */
    function _normalRedeem(uint256 tokenAmount, address receiver)
        internal
            {
        require(!esm.isRedeemPaused(), "Redeem paused");
        address staker = msg.sender;
        require(tokens[staker] > 0, "No collateral");
        require(tokenAmount > 0, "The quantity is less than zero");
        require(tokenAmount <= tokens[staker], "input amount overflow");

        accuredToken(staker);
        token.transfer(receiver, tokenAmount);

        tokens[staker] = tokens[staker].sub(tokenAmount);
        totalToken = totalToken.sub(tokenAmount);

        emit RedeemEvent(tokenAmount);
    }
    

    
    /**
     * @notice Abnormally redeem anyAmount internal
     * @param receiver Address of receiving
     */
    function _abnormalRedeem(uint256 tokenAmount, address receiver) internal {
        require(esm.isClosed(), "System not Closed yet.");
        address from = msg.sender;
        require(tokenAmount > 0, "The quantity is less than zero");
        require(token.balanceOf(from) > 0, "The coin no balance.");
        require(tokenAmount <= tokens[from], "Coin balance exceed");

        token.transfer(receiver, tokenAmount);
        tokens[from] = tokens[from].sub(tokenAmount);
        totalToken = totalToken.sub(tokenAmount);

        emit RedeemEvent(tokenAmount);
    }

    /**
     * @notice Normally redeem anyAmount 
     * @param receiver Address of receiving
     */
    function redeem(uint256 tokenAmount, address receiver) public {
        _normalRedeem(tokenAmount, receiver);
    }

    /**
     * @notice Normally redeem anyAmount to msg.sender 
     */
    function redeem(uint256 tokenAmount) public {
        redeem(tokenAmount, msg.sender);
    }

    /**
     * @notice normally redeem them all at once 
     * @param holder reciver
     */
    function redeemMax(address holder) public {
        redeem(tokens[msg.sender], holder);
    }

    /**
     * @notice normally redeem them all at once to msg.sender 
     */
    function redeemMax() public {
        redeemMax(msg.sender);
    }

    /**
     * @notice System shutdown under the redemption rule 
     * @param tokenAmount The number coin
     * @param receiver Address of receiving
     */
    function oRedeem(uint256 tokenAmount, address receiver) public {
        _abnormalRedeem(tokenAmount, receiver);
    }

    /**
     * @notice System shutdown under the redemption rule 
     * @param tokenAmount The number coin
     */
    function oRedeem(uint256 tokenAmount) public {
        oRedeem(tokenAmount, msg.sender);
    }

    /**
     * @notice Refresh reward speed.
     */
    function setRewardSpeed(uint256 speed) public onlyWhiter {
        updateIndex();
        rewardSpeed = speed;
    }

    /**
     * @notice Used to correct the effect of one's actions on one's own earnings
     *         System shutdown will no longer count
     */
    function updateIndex() public {
        if (esm.isClosed()) {
            return;
        }

        uint256 blockNumber = getBlockNumber();
        uint256 deltBlock = blockNumber.sub(rewardState.block);

        if (deltBlock > 0) {
            uint256 accruedReward = rewardSpeed.mul(deltBlock);
            uint256 ratio = totalToken == 0
                ? 0
                : accruedReward.mul(doubleScale).div(totalToken);
            rewardState.index = rewardState.index.add(ratio);
            rewardState.block = blockNumber;
            emit IndexUpdate(deltBlock, blockNumber, rewardState.index);
        }
    }

    /**
     * @notice Used to correct the effect of one's actions on one's own earnings
     *         System shutdown will no longer count
     * @param account staker address
     */
    function accuredToken(address account) internal {
        updateIndex();
        StakerState storage stakerState = stakerStates[account];
        stakerState.reward = _getReward(account);
        stakerState.index = rewardState.index;
    }

    /**
     * @notice Calculate the current holder's mining income
     * @param staker Address of holder
     */
    function _getReward(address staker) internal view returns (uint256 value) {
        StakerState storage stakerState = stakerStates[staker];
        value = stakerState.reward.add(
            rewardState.index.sub(stakerState.index).mul(tokens[staker]).div(
                doubleScale
            )
        );
    }

    /**
     * @notice Estimate the mortgagor's reward
     * @param account Address of staker
     */
    function getHolderReward(address account)
        public
        view
        returns (uint256 value)
    {
        uint256 blockReward2 = (totalToken == 0 || esm.isClosed())
            ? 0
            : getBlockNumber()
                .sub(rewardState.block)
                .mul(rewardSpeed)
                .mul(tokens[account])
                .div(totalToken);
        value = _getReward(account) + blockReward2;
    }

    /**
     * @notice Extract the current reward in one go
     * @param holder Address of receiver
     */
    function claimToken(address holder) public {
        accuredToken(holder);
        StakerState storage stakerState = stakerStates[holder];
        uint256 value = stakerState.reward.min(reward);
        require(value > 0, "The reward of address is zero.");

        coin.transfer(holder, value);
        reward = reward.sub(value);

        stakerState.index = rewardState.index;
        stakerState.reward = stakerState.reward.sub(value);
        emit ClaimToken(holder, value);
    }

    /**
     * @notice Get block number now
     */
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Inject token to reward
     * @param amount The number of injecting
     */
    function injectReward(uint256 amount) external onlyOwner {
        coin.transferFrom(msg.sender, address(this), amount);
        reward = reward.add(amount);
        emit InjectReward(amount);
    }

    /**
     * @notice Extract token from reward
     * @param account Address of receiver
     * @param amount The number of extracting
     */
    function extractReward(address account, uint256 amount) external onlyOwner {
        require(amount <= reward, "withdraw overflow.");
        coin.transfer(account, amount);
        reward = reward.sub(amount);
        emit ExtractReward(account, amount);
    }

    
}"},"State.sol":{"content":"pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/State
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(
            msg.sender == associatedContract,
            "Only the associated contract can perform this action"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}
"},"STPT.sol":{"content":"/**
 *Submitted for verification at Etherscan.io on 2020-09-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-24
*/

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract STPTToken {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        // require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}"},"WhiteList.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./Owned.sol";

contract WhiteList is Owned {
    /// @notice Users with permissions
    mapping(address => uint256) public whiter;

    /// @notice Append address into whiteList successevent
    event AppendWhiter(address adder);

    /// @notice Remove address into whiteList successevent
    event RemoveWhiter(address remover);

    /**
     * @notice Construct a new WhiteList, default owner in whiteList
     */
    constructor() internal {
        appendWhiter(owner);
    }

    modifier onlyWhiter() {
        require(isWhiter(), "WhiteList: msg.sender not in whilteList.");
        _;
    }

    /**
     * @notice Only onwer can append address into whitelist
     * @param account The address not added, can added to the whitelist
     */
    function appendWhiter(address account) public onlyOwner {
        require(account != address(0), "WhiteList: address not zero");
        require(
            !isWhiter(account),
            "WhiteListe: the account exsit whilteList yet"
        );
        whiter[account] = 1;
        emit AppendWhiter(account);
    }

    /**
     * @notice Only onwer can remove address into whitelist
     * @param account The address in whitelist yet
     */
    function removeWhiter(address account) public onlyOwner {
        require(
            isWhiter(account),
            "WhiteListe: the account not exist whilteList"
        );
        delete whiter[account];
        emit RemoveWhiter(account);
    }

    /**
     * @notice Check whether acccount in whitelist
     * @param account Any address
     */
    function isWhiter(address account) public view returns (bool) {
        return whiter[account] == 1;
    }

    /**
     * @notice Check whether msg.sender in whitelist overrides.
     */
    function isWhiter() public view returns (bool) {
        return isWhiter(msg.sender);
    }
}
"}}