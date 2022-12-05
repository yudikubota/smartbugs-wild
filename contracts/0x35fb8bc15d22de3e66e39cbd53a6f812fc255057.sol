{{
  "language": "Solidity",
  "sources": {
    "contracts/DInterest.sol": {
      "content": "pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libs/DecMath.sol";
import "./moneymarkets/IMoneyMarket.sol";
import "./FeeModel.sol";


// DeLorean Interest -- It's coming back from the future!
// EL PSY CONGROO
// Author: Zefram Lou
// Contact: zefram@baconlabs.dev
contract DInterest is ReentrancyGuard {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;

    // Constants
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant ONE = 10**18;

    // Used for maintaining an accurate average block time
    uint256 internal _blocktime; // Number of seconds needed to generate each block, decimal
    uint256 internal _lastCallBlock; // Last block when the contract was called
    uint256 internal _lastCallTimestamp; // Last timestamp when the contract was called
    uint256 internal _numBlocktimeDatapoints; // Number of block time datapoints collected
    modifier updateBlocktime {
        if (block.number > _lastCallBlock) {
            uint256 blocksSinceLastCall = block.number.sub(_lastCallBlock);
            // newBlockTime = (now - _lastCallTimestamp) / (block.number - _lastCallBlock)
            // decimal
            uint256 newBlocktime = now.sub(_lastCallTimestamp).decdiv(
                blocksSinceLastCall
            );
            // _blocktime = (blocksSinceLastCall * newBlocktime + _numBlocktimeDatapoints * _blocktime) / (_numBlocktimeDatapoints + blocksSinceLastCall)
            // decimal
            _blocktime = _blocktime
                .mul(_numBlocktimeDatapoints)
                .add(newBlocktime.mul(blocksSinceLastCall))
                .div(_numBlocktimeDatapoints.add(blocksSinceLastCall));
            _lastCallBlock = block.number;
            _lastCallTimestamp = now;
            _numBlocktimeDatapoints = _numBlocktimeDatapoints.add(
                blocksSinceLastCall
            );
        }
        _;
    }

    // User deposit data
    struct Deposit {
        uint256 amount; // Amount of stablecoin deposited
        uint256 maturationTimestamp; // Unix timestamp after which the deposit may be withdrawn, in seconds
        uint256 initialDeficit; // Deficit incurred to the pool at time of deposit
        bool active; // True if not yet withdrawn, false if withdrawn
    }
    mapping(address => Deposit[]) public userDeposits;
    mapping(address => Deposit[]) public sponsorDeposits;

    // Params
    uint256 public UIRMultiplier; // Upfront interest rate multiplier
    uint256 public MinDepositPeriod; // Minimum deposit period, in seconds

    // Instance variables
    uint256 public totalDeposit;

    // External smart contracts
    IMoneyMarket public moneyMarket;
    ERC20 public stablecoin;
    FeeModel public feeModel;

    // Events
    event EDeposit(
        address indexed sender,
        uint256 depositID,
        uint256 amount,
        uint256 maturationTimestamp,
        uint256 upfrontInterestAmount
    );
    event EWithdraw(address indexed sender, uint256 depositID, bool early);
    event ESponsorDeposit(
        address indexed sender,
        uint256 depositID,
        uint256 amount,
        uint256 maturationTimestamp,
        string data
    );
    event ESponsorWithdraw(address indexed sender, uint256 depositID);

    constructor(
        uint256 _UIRMultiplier,
        uint256 _MinDepositPeriod,
        address _moneyMarket,
        address _stablecoin,
        address _feeModel
    ) public {
        _blocktime = 15 * PRECISION; // Default block time is 15 seconds
        _lastCallBlock = block.number;
        _lastCallTimestamp = now;
        _numBlocktimeDatapoints = 10**6; // Start with many datapoints to prevent initial fluctuation

        UIRMultiplier = _UIRMultiplier;
        MinDepositPeriod = _MinDepositPeriod;

        totalDeposit = 0;
        moneyMarket = IMoneyMarket(_moneyMarket);
        stablecoin = ERC20(_stablecoin);
        feeModel = FeeModel(_feeModel);
    }

    /**
        Public actions
     */

    function deposit(uint256 amount, uint256 maturationTimestamp)
        external
        updateBlocktime
        nonReentrant
    {
        _deposit(amount, maturationTimestamp);
    }

    function withdraw(uint256 depositID) external updateBlocktime nonReentrant {
        _withdraw(depositID);
    }

    function earlyWithdraw(uint256 depositID) external updateBlocktime nonReentrant {
        _earlyWithdraw(depositID);
    }

    function multiDeposit(
        uint256[] calldata amountList,
        uint256[] calldata maturationTimestampList
    ) external updateBlocktime nonReentrant {
        require(
            amountList.length == maturationTimestampList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < amountList.length; i = i.add(1)) {
            _deposit(amountList[i], maturationTimestampList[i]);
        }
    }

    function multiWithdraw(uint256[] calldata depositIDList)
        external
        updateBlocktime
        nonReentrant
    {
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _withdraw(depositIDList[i]);
        }
    }

    function multiEarlyWithdraw(uint256[] calldata depositIDList)
        external
        updateBlocktime
        nonReentrant
    {
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _earlyWithdraw(depositIDList[i]);
        }
    }

    /**
        Public getters
     */

    function calculateUpfrontInterestRate(uint256 depositPeriodInSeconds)
        public
        view
        returns (uint256 upfrontInterestRate)
    {
        uint256 moneyMarketInterestRatePerSecond = moneyMarket
            .supplyRatePerSecond(_blocktime);

        // upfrontInterestRate = (1 - 1 / (1 + moneyMarketInterestRatePerSecond * depositPeriodInSeconds * UIRMultiplier))
        upfrontInterestRate = ONE.sub(
            ONE.decdiv(
                ONE.add(
                    moneyMarketInterestRatePerSecond
                        .mul(depositPeriodInSeconds)
                        .decmul(UIRMultiplier)
                )
            )
        );
    }

    function blocktime() external view returns (uint256) {
        return _blocktime;
    }

    function deficit()
        external
        view
        returns (bool isNegative, uint256 deficitAmount)
    {
        uint256 totalValue = moneyMarket.totalValue();
        if (totalValue >= totalDeposit) {
            isNegative = false;
            deficitAmount = totalValue.sub(totalDeposit);
        } else {
            isNegative = true;
            deficitAmount = totalDeposit.sub(totalValue);
        }
    }

    /**
        Sponsor actions
     */

    function sponsorDeposit(
        uint256 amount,
        uint256 maturationTimestamp,
        string calldata data
    ) external updateBlocktime nonReentrant {
        // Ensure deposit period is at least MinDepositPeriod
        uint256 depositPeriod = maturationTimestamp.sub(now);
        require(
            depositPeriod >= MinDepositPeriod,
            "DInterest: Deposit period too short"
        );

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Record deposit data for `msg.sender`
        sponsorDeposits[msg.sender].push(
            Deposit({
                amount: amount,
                maturationTimestamp: maturationTimestamp,
                initialDeficit: 0,
                active: true
            })
        );

        // Update totalDeposit
        totalDeposit = totalDeposit.add(amount);

        // Lend `amount` stablecoin to money market
        if (stablecoin.allowance(address(this), address(moneyMarket)) > 0) {
            stablecoin.safeApprove(address(moneyMarket), 0);
        }
        stablecoin.safeApprove(address(moneyMarket), amount);
        moneyMarket.deposit(amount);

        // Emit event
        emit ESponsorDeposit(
            msg.sender,
            sponsorDeposits[msg.sender].length.sub(1),
            amount,
            maturationTimestamp,
            data
        );
    }

    function sponsorWithdraw(uint256 depositID)
        external
        updateBlocktime
        nonReentrant
    {
        Deposit memory depositEntry = sponsorDeposits[msg.sender][depositID];

        // Verify deposit is active and set to inactive
        require(depositEntry.active, "DInterest: Deposit not active");
        depositEntry.active = false;

        // Verify `now >= depositEntry.maturationTimestamp`
        require(
            now >= depositEntry.maturationTimestamp,
            "DInterest: Deposit not mature"
        );

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Withdraw `depositEntry.amount` stablecoin from money market
        moneyMarket.withdraw(depositEntry.amount);

        // Send `depositEntry.amount` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, depositEntry.amount);

        // Emit event
        emit ESponsorWithdraw(msg.sender, depositID);
    }

    /**
        Internals
     */

    function _deposit(uint256 amount, uint256 maturationTimestamp) internal {
        // Ensure deposit period is at least MinDepositPeriod
        uint256 depositPeriod = maturationTimestamp.sub(now);
        require(
            depositPeriod >= MinDepositPeriod,
            "DInterest: Deposit period too short"
        );

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Update totalDeposit
        totalDeposit = totalDeposit.add(amount);

        // Calculate `upfrontInterestAmount` stablecoin to return to `msg.sender`
        uint256 upfrontInterestRate = calculateUpfrontInterestRate(
            depositPeriod
        );
        uint256 upfrontInterestAmount = amount.decmul(upfrontInterestRate);
        uint256 feeAmount = feeModel.getFee(upfrontInterestAmount);

        // Record deposit data for `msg.sender`
        userDeposits[msg.sender].push(
            Deposit({
                amount: amount,
                maturationTimestamp: maturationTimestamp,
                initialDeficit: upfrontInterestAmount,
                active: true
            })
        );

        // Deduct `feeAmount` from `upfrontInterestAmount`
        upfrontInterestAmount = upfrontInterestAmount.sub(feeAmount);

        // Lend `amount - upfrontInterestAmount` stablecoin to money market
        uint256 principalAmount = amount.sub(upfrontInterestAmount).sub(
            feeAmount
        );
        if (stablecoin.allowance(address(this), address(moneyMarket)) > 0) {
            stablecoin.safeApprove(address(moneyMarket), 0);
        }
        stablecoin.safeApprove(address(moneyMarket), principalAmount);
        moneyMarket.deposit(principalAmount);

        // Send `feeAmount` stablecoin to `feeModel.beneficiary()`
        stablecoin.safeTransfer(feeModel.beneficiary(), feeAmount);

        // Send `upfrontInterestAmount` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, upfrontInterestAmount);

        // Emit event
        emit EDeposit(
            msg.sender,
            userDeposits[msg.sender].length.sub(1),
            amount,
            maturationTimestamp,
            upfrontInterestAmount
        );
    }

    function _withdraw(uint256 depositID) internal {
        Deposit memory depositEntry = userDeposits[msg.sender][depositID];

        // Verify deposit is active and set to inactive
        require(depositEntry.active, "DInterest: Deposit not active");
        depositEntry.active = false;

        // Verify `now >= depositEntry.maturationTimestamp`
        require(
            now >= depositEntry.maturationTimestamp,
            "DInterest: Deposit not mature"
        );

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Withdraw `depositEntry.amount` stablecoin from money market
        moneyMarket.withdraw(depositEntry.amount);

        // Send `depositEntry.amount` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, depositEntry.amount);

        // Emit event
        emit EWithdraw(msg.sender, depositID, false);
    }

    function _earlyWithdraw(uint256 depositID) internal {
        Deposit memory depositEntry = userDeposits[msg.sender][depositID];

        // Verify deposit is active and set to inactive
        require(depositEntry.active, "DInterest: Deposit not active");
        depositEntry.active = false;

        // Transfer `depositEntry.initialDeficit` from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), depositEntry.initialDeficit);

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Withdraw `depositEntry.amount` stablecoin from money market
        moneyMarket.withdraw(depositEntry.amount.sub(depositEntry.initialDeficit));

        // Send `depositEntry.amount` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, depositEntry.amount);

        // Emit event
        emit EWithdraw(msg.sender, depositID, true);
    }
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * Requirements:
     *
     * - this function can only be called from a constructor.
     */
    function _setupDecimals(uint8 decimals_) internal {
        require(!address(this).isContract(), "ERC20: decimals cannot be changed after construction");
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.6.0;

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
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.6.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/SafeERC20.sol": {
      "content": "pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "@openzeppelin/contracts/utils/ReentrancyGuard.sol": {
      "content": "pragma solidity ^0.6.0;

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
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}
"
    },
    "contracts/libs/DecMath.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";

// Decimal math library
library DecMath {
    uint256 internal constant PRECISION = 10**18;

    function decmul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        c = c / PRECISION;

        return c;
    }

    function decdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a * PRECISION;
        require(c / a == PRECISION, "SafeMath: multiplication overflow");
        c = c / b;

        return c;
    }
}
"
    },
    "contracts/moneymarkets/IMoneyMarket.sol": {
      "content": "pragma solidity 0.6.5;

// Interface for money market protocols (Compound, Aave, bZx, etc.)
interface IMoneyMarket {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amountInUnderlying) external;
    function supplyRatePerSecond(uint256 blocktime)
        external
        view
        returns (uint256); // The supply interest rate per second, scaled by 10^18
    function totalValue() external view returns (uint256); // The total value locked in the money market, in terms of the underlying stablecoin
    function price() external view returns (uint256); // Used for calculating interest generated (e.g. cDai's price for Compound)
}"
    },
    "contracts/FeeModel.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeModel is Ownable {
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    address payable public beneficiary = 0x332D87209f7c8296389C307eAe170c2440830A47;

    function getFee(uint256 _txAmount)
        public
        pure
        returns (uint256 _feeAmount)
    {
        _feeAmount = _txAmount.div(10);
    }

    function setBeneficiary(address payable _addr) public onlyOwner {
        require(_addr != address(0), "0 address");
        beneficiary = _addr;
    }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    "contracts/mocks/ATokenMock.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/DecMath.sol";

contract ATokenMock is ERC20 {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 internal constant YEAR = 31556952; // Number of seconds in one Gregorian calendar year (365.2425 days)

    ERC20 public dai;
    uint256 public liquidityRate;
    address[] public users;

    constructor(address _dai)
        public
        ERC20("aDAI", "aDAI")
    {
        dai = ERC20(_dai);

        liquidityRate = 10 ** 26; // 10% APY
    }

    function redeem(uint256 _amount) external {
        _burn(msg.sender, _amount);
        dai.transfer(msg.sender, _amount);
    }

    function principalBalanceOf(address _user) external view returns (uint256) {
        return balanceOf(_user); // TODO
    }

    function mint(address _user, uint256 _amount) external {
        _mint(_user, _amount);
        users.push(_user);
    }

    function mintInterest(uint256 _seconds) external {
        uint256 interest;
        address user;
        for (uint256 i = 0; i < users.length; i++) {
            user = users[i];
            interest = balanceOf(user).mul(_seconds).decmul(liquidityRate.div(YEAR.mul(10**9)));
            _mint(user, interest);
        }
    }

    function setLiquidityRate(uint256 _liquidityRate) external {
        liquidityRate = _liquidityRate;
    }
}"
    },
    "contracts/mocks/CERC20Mock.sol": {
      "content": "/**
    Modified from https://github.com/bugduino/idle-contracts/blob/master/contracts/mocks/cDAIMock.sol
    at commit b85dafa8e55e053cb2d403fc4b28cfe86f2116d4

    Original license:
    Copyright 2020 Idle Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

pragma solidity 0.6.5;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CERC20Mock is ERC20 {
    address public dai;

    uint256 internal _supplyRate;
    uint256 internal _exchangeRate;

    constructor(address _dai)
        public
        ERC20("cDAI", "cDAI")
    {
        dai = _dai;
        _exchangeRate = 2 * (10 ** 26); // 1 cDAI = 0.02 DAI
        _supplyRate = 45290900000; // 10% supply rate per year
    }

    function mint(uint256 amount) external returns (uint256) {
        require(
            IERC20(dai).transferFrom(msg.sender, address(this), amount),
            "Error during transferFrom"
        ); // 1 DAI
        _mint(msg.sender, (amount * 10**18) / _exchangeRate);
        return 0;
    }

    function redeemUnderlying(uint256 amount) external returns (uint256) {
        _burn(msg.sender, (amount * 10**18) / _exchangeRate);
        require(
            IERC20(dai).transfer(msg.sender, amount),
            "Error during transfer"
        ); // 1 DAI
        return 0;
    }

    function exchangeRateStored() external view returns (uint256) {
        return _exchangeRate;
    }

    function _setExchangeRateStored(uint256 _rate) external returns (uint256) {
        _exchangeRate = _rate;
    }

    function supplyRatePerBlock() external view returns (uint256) {
        return _supplyRate;
    }

    function _setSupplyRatePerBlock(uint256 _rate) external {
        _supplyRate = _rate;
    }
}
"
    },
    "contracts/mocks/ERC20Mock.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("", "") {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}"
    },
    "contracts/mocks/LendingPoolAddressesProviderMock.sol": {
      "content": "pragma solidity 0.6.5;

contract LendingPoolAddressesProviderMock {
    address internal pool;

    function getLendingPool() external view returns (address) {
        return pool;
    }

    function setLendingPoolImpl(address _pool) external {
        pool = _pool;
    }
}"
    },
    "contracts/mocks/LendingPoolMock.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ATokenMock.sol";

contract LendingPoolMock {
    mapping(address => address) internal reserveAToken;

    function setReserveAToken(address _reserve, address _aTokenAddress) external {
        reserveAToken[_reserve] = _aTokenAddress;
    }

    function deposit(address _reserve, uint256 _amount, uint16)
        external
    {
        ERC20 token = ERC20(_reserve);
        token.transferFrom(msg.sender, address(this), _amount);

        // Mint aTokens
        address aTokenAddress = reserveAToken[_reserve];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        aToken.mint(msg.sender, _amount);
        token.transfer(aTokenAddress, _amount);
    }

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256 liquidityRate,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address aTokenAddress,
            uint40
        )
    {
        aTokenAddress = reserveAToken[_reserve];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        liquidityRate = aToken.liquidityRate();
    }
}
"
    },
    "contracts/moneymarkets/aave/AaveMarket.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/IAToken.sol";
import "./imports/ILendingPool.sol";
import "./imports/ILendingPoolAddressesProvider.sol";

contract AaveMarket is IMoneyMarket, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;

    uint256 internal constant YEAR = 31556952; // Number of seconds in one Gregorian calendar year (365.2425 days)
    uint16 internal constant REFERRALCODE = 20; // Aave referral program code

    ILendingPoolAddressesProvider public provider; // Used for fetching the current address of LendingPool
    ERC20 public stablecoin;

    constructor(address _provider, address _stablecoin) public {
        provider = ILendingPoolAddressesProvider(_provider);
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external override(IMoneyMarket) onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Approve `amount` stablecoin to lendingPool
        if (stablecoin.allowance(address(this), address(lendingPool)) > 0) {
            stablecoin.safeApprove(address(lendingPool), 0);
        }
        stablecoin.safeApprove(address(lendingPool), amount);

        // Deposit `amount` stablecoin to lendingPool
        lendingPool.deposit(address(stablecoin), amount, REFERRALCODE);
    }

    function withdraw(uint256 amountInUnderlying) external override(IMoneyMarket) onlyOwner {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Initialize aToken
        (, , , , , , , , , , , address aTokenAddress, ) = lendingPool
            .getReserveData(address(stablecoin));
        IAToken aToken = IAToken(aTokenAddress);

        // Redeem `amountInUnderlying` aToken, since 1 aToken = 1 stablecoin
        aToken.redeem(amountInUnderlying);

        // Transfer `amountInUnderlying` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, amountInUnderlying);
    }

    function supplyRatePerSecond(uint256 /*blocktime*/)
        external
        view
        override(IMoneyMarket)
        returns (uint256)
    {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // The annual supply interest rate, scaled by 10^27
        (, , , , uint256 liquidityRate, , , , , , , , ) = lendingPool
            .getReserveData(address(stablecoin));

        // supplyRatePerSecond = liquidityRate / 10^9 / YEAR = liquidityRate / (YEAR * 10^9)
        return liquidityRate.div(YEAR.mul(10**9));
    }

    function totalValue() external view override(IMoneyMarket) returns (uint256) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Initialize aToken
        (, , , , , , , , , , , address aTokenAddress, ) = lendingPool
            .getReserveData(address(stablecoin));
        IAToken aToken = IAToken(aTokenAddress);

        return aToken.balanceOf(address(this));
    }

    function price() external view override(IMoneyMarket) returns (uint256) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Initialize aToken
        (, , , , , , , , , , , address aTokenAddress, ) = lendingPool
            .getReserveData(address(stablecoin));
        IAToken aToken = IAToken(aTokenAddress);

        uint256 principalBalance = aToken.principalBalanceOf(address(this));
        if (principalBalance == 0) {
            return 0;
        }
        uint256 balance = aToken.balanceOf(address(this));
        return balance.decdiv(principalBalance);
    }
}
"
    },
    "contracts/moneymarkets/aave/imports/IAToken.sol": {
      "content": "pragma solidity 0.6.5;

// Aave aToken interface
interface IAToken {
    function redeem(uint256 _amount) external;
    function balanceOf(address owner) external view returns (uint256);
    function principalBalanceOf(address _user) external view returns (uint256);
}"
    },
    "contracts/moneymarkets/aave/imports/ILendingPool.sol": {
      "content": "pragma solidity 0.6.5;

// Aave lending pool interface
interface ILendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode)
        external;
    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );
}
"
    },
    "contracts/moneymarkets/aave/imports/ILendingPoolAddressesProvider.sol": {
      "content": "pragma solidity 0.6.5;

// Aave lending pool addresses provider interface
interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
    function setLendingPoolImpl(address _pool) external;

    function getLendingPoolCore() external view returns (address payable);
    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    function getLendingPoolConfigurator() external view returns (address);
    function setLendingPoolConfiguratorImpl(address _configurator) external;

    function getLendingPoolDataProvider() external view returns (address);
    function setLendingPoolDataProviderImpl(address _provider) external;

    function getLendingPoolParametersProvider() external view returns (address);
    function setLendingPoolParametersProviderImpl(address _parametersProvider) external;

    function getTokenDistributor() external view returns (address);
    function setTokenDistributor(address _tokenDistributor) external;


    function getFeeProvider() external view returns (address);
    function setFeeProviderImpl(address _feeProvider) external;

    function getLendingPoolLiquidationManager() external view returns (address);
    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);
    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);
    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);
    function setLendingRateOracle(address _lendingRateOracle) external;
}
"
    },
    "contracts/moneymarkets/compound/CompoundERC20Market.sol": {
      "content": "pragma solidity 0.6.5;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/ICERC20.sol";

contract CompoundERC20Market is IMoneyMarket, Ownable {
    using DecMath for uint256;
    using SafeERC20 for ERC20;

    uint256 internal constant ERRCODE_OK = 0;

    ICERC20 public cToken;
    ERC20 public stablecoin;

    constructor(address _cToken, address _stablecoin) public {
        cToken = ICERC20(_cToken);
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external override(IMoneyMarket) onlyOwner {
        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit `amount` stablecoin into cToken
        if (stablecoin.allowance(address(this), address(cToken)) > 0) {
            stablecoin.safeApprove(address(cToken), 0);
        }
        stablecoin.safeApprove(address(cToken), amount);
        require(
            cToken.mint(amount) == ERRCODE_OK,
            "CompoundERC20Market: Failed to mint cTokens"
        );
    }

    function withdraw(uint256 amountInUnderlying) external override(IMoneyMarket) onlyOwner {
        // Withdraw `amountInUnderlying` stablecoin from cToken
        require(
            cToken.redeemUnderlying(amountInUnderlying) == ERRCODE_OK,
            "CompoundERC20Market: Failed to redeem"
        );

        // Transfer `amountInUnderlying` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, amountInUnderlying);
    }

    function supplyRatePerSecond(uint256 blocktime)
        external
        view
        override(IMoneyMarket)
        returns (uint256)
    {
        return cToken.supplyRatePerBlock().decdiv(blocktime);
    }

    function totalValue() external view override(IMoneyMarket) returns (uint256) {
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        // Amount of stablecoin units that 1 unit of cToken can be exchanged for, scaled by 10^18
        uint256 cTokenPrice = cToken.exchangeRateStored();
        return cTokenBalance.decmul(cTokenPrice);
    }

    function price() external view override(IMoneyMarket) returns (uint256) {
        return cToken.exchangeRateStored();
    }
}
"
    },
    "contracts/moneymarkets/compound/imports/ICERC20.sol": {
      "content": "pragma solidity 0.6.5;

// Compound finance ERC20 market interface
interface ICERC20 {
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount)
        external
        returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function getAccountSnapshot(address account)
        external
        view
        returns (uint256, uint256, uint256, uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function totalBorrowsCurrent() external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function getCash() external view returns (uint256);
    function accrueInterest() external returns (uint256);
    function seize(address liquidator, address borrower, uint256 seizeTokens)
        external
        returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);
}
"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
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
    }
  }
}}