{"Babylonian.sol":{"content":"// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}
"},"BackedToken.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./ERC20.sol";

contract BackedToken is ERC20 {
    address public owner;
    
    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
        owner = msg.sender;
    }
    
    function ownerMint (address account, uint amount) public {
        require(msg.sender == owner, "Only owner may mint");
        _mint(account, amount);
    }
    
    function ownerBurn (address account, uint amount) public {
        require(msg.sender == owner, "Only owner may burn third party");
        _burn(account, amount);        
    }
    
    function selfBurn (uint amount) public {
        _burn(msg.sender, amount);        
    }
}"},"BitMath.sol":{"content":"// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}
"},"ClaimPriorityDate.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";

contract ClaimPriorityDate {
    using SafeMath for uint256;
    
    mapping(address => uint) public weiDeposited;  
    mapping(address => uint) public priorityDate;
    
    string purpose;
    address owner;
    bool isEnabled;
    uint startDate;
    
    constructor(string memory _purpose) {
        owner = msg.sender;
        isEnabled = true;
        purpose = _purpose;
        startDate = block.timestamp;
    }
    
    function permanentlyDisable() public {
        require(msg.sender == owner);
        isEnabled = false;
    }
    
    function depositClaim() public payable {
        require(isEnabled);
        require(weiDeposited[msg.sender] == 0); ///  You already have a deposit and this smart contract does not support multiple deposits with multiple Priority Dates. Either use a new Ethereum address to claim another (later) priority date. Or forfeit your current priority date by withdrawing to exactly zero and then depositing again"
        require(msg.value > 0, "You must deposit a positive amount.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].add(msg.value);
        priorityDate[msg.sender] = block.timestamp;
    }
    
    receive() external payable {
        require(isEnabled);
        require(weiDeposited[msg.sender] == 0); ///  You already have a deposit and this smart contract does not support multiple deposits with multiple Priority Dates. Either use a new Ethereum address to claim another (later) priority date. Or forfeit your current priority date by withdrawing to exactly zero and then depositing again"
        require(msg.value > 0, "You must deposit a positive amount.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].add(msg.value);
        priorityDate[msg.sender] = block.timestamp;
    }
    
    function withdrawClaim(uint _weiWithdraw) public {
        require( weiDeposited[msg.sender] >= _weiWithdraw, "You are trying to withdraw more wei than you deposited.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].sub( _weiWithdraw );
        msg.sender.transfer(_weiWithdraw);
    }
    
}    
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

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
}"},"DriverVaultSystemSpaceX.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";
import "./GeneralToken.sol";

contract DriverVaultSystemSpaceX {
    
    using SafeMath for uint256;
    
    GeneralToken public ivtToken;
    
    constructor() { 
        ivtToken = new GeneralToken(10 ** 30, msg.sender, "ItoVault Token V_1_0_0", "IVT V1_0");
    }
    
}"},"ERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
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
     * Requirements:
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
     * Requirements:
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
"},"ExampleOracleSimple.sol":{"content":"pragma solidity =0.7.2;

import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './FixedPoint.sol';



import './UniswapV2OracleLibrary.sol';
import './UniswapV2Library.sol';

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract ExampleOracleSimple {
    using FixedPoint for *;

    uint public immutable PERIOD;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;
    

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(address factory, address tokenA, address tokenB, uint _PERIOD) public {
        
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair = _pair;
        
        token0 = _pair.token0();
        token1 = _pair.token1();
        
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        
        PERIOD = _PERIOD;
        
        require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES'); // ensure that there's liquidity in the pair 
    }

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');
        
    
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        
        
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'ExampleOracleSimple: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}"},"FixedPoint.sol":{"content":"// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

import './FullMath.sol';
import './Babylonian.sol';
import './BitMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}
"},"FullMath.sol":{"content":"// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}
"},"GeneralToken.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";


contract GeneralToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;  
    
    address public startingOwner;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) public balances;

    mapping(address => mapping (address => uint256)) public allowed;
    
    uint256 public totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total, address _startingOwner, string memory _name, string memory _symbol) {  
    name = _name;
    symbol = _symbol;
	totalSupply_ = total;
	startingOwner = _startingOwner;
	balances[startingOwner] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    
    function ownerApprove(address target, uint numTokens) public returns (bool) {
        require(msg.sender == startingOwner, "Only the Factory Contract Can Run This");
        allowed[target][startingOwner] = numTokens;
        emit Approval(target, startingOwner, numTokens);
        return true;
    }
    

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
 
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
"},"Math.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}"},"Migrations.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
"},"MyStringStore.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: UNLICENSED

contract MyStringStore {
  string public myString = "Hello World";

  function set(string memory x) public {
    myString = x;
  }
}"},"SafeMath-old.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.7.2;

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
}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.7.2;

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
}"},"UniswapV2Library.sol":{"content":"pragma solidity >=0.5.0;

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
"},"UniswapV2OracleLibrary.sol":{"content":"pragma solidity >=0.5.0;

import './IUniswapV2Pair.sol';
import './FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}
"},"VaultSystemSpaceX.sol":{"content":"pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";           // Todo: Change Safemath Name Over 
import "./ExampleOracleSimple.sol";
import "./GeneralToken.sol";
import "./BackedToken.sol";

contract VaultSystemSpaceX {
    using SafeMath for uint256;
    
    event LogUint(string name, uint value);
    
    BackedToken public vSPACEXToken;                       // This token is initialized below.

    
    // Start Config Area to Change Between Testnet and Mainnet
    address public constant UNISWAP_FACTORY_ADDR = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant WETH_ADDR = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // For Kovan change to 0xd0A1E359811322d97991E03f863a0C30C2cF029C
    GeneralToken public ivtToken = GeneralToken(0xb5BC0481ff9EF553F11f031A469cd9DF71280A27); // For Kovan, use any; for mainnet use 0xb5bc0481ff9ef553f11f031a469cd9df71280a27
    
    
    uint constant public LIQ_WAIT_TIME = 28 hours; // Mainnet: 28 hours
    uint public constant TWAP_PERIOD = 2 hours; // Mainnet: 2 hours
    uint public constant GLOBAL_SETTLEMENT_PERIOD = 14 days; // Mainnet 14 days
    // End Config Area to Change Between Testnet and Mainnet
    
    
    uint public cAME18 = 10 ** 18;
    
    address payable public owner;                           // owner is also governor here. to be passed to IVTDAO in the future
    address payable public oracle;                          // oracle is only the oracle for secondary prices
    
    
    // NB: None of the storage variables below should store numbers greater than 1E36.   uint256 overflow above 1E73.
    // So, it is safe to mul two numbers always. But to mul more than 2 requires decimal counting.
    
    uint public maxvSPACEXE18 = (10 ** 6) * (10 ** 18);     // Upper Bound of a million vSPACEXE18 tokens
    uint public outstandingvSPACEXE18 = 0;                  // Current outstanding vSPACEX tokens
    
    
    // Vault Variables (in vSPY_1 notation, these are forward vaults, and not reverse vaults)
    uint public initialLTVE10   = 5 * 10 ** 9;              // Maximum initial loan to value of a vault                 [Integer / 1E10]
    uint public maintLTVE10     = 6 * 10 ** 9;              // Maximum maintnenance loan to value of a vault            [Integer / 1E10]
    uint public liqPenaltyE10   = 5 * 10 ** 8;              // Bonus paid to any address for liquidating non-compliant
                                                            // contract                                                 [Integer / 1E10]
                                                            
                                                            
    // Global Settlement Variables
    bool public inGlobalSettlement = false;
    uint public globalSettlementStartTime;
    uint public settledWeiPervSPACEX; 
    bool public isGloballySettled = false;
    
    // Corporate Action Multiplier
    
    

    
    // Price Feed Variables
    ExampleOracleSimple public uniswapTWAPOracle;
    uint public weiPervSPACEXTWAP = 10 ** 18;
    bool public isTWAPOracleAttached = false;
    
    uint public weiPervSPACEXSecondary = 10 ** 18;
    uint public weiPervSPACEXMin = 10 ** 18;
    uint public weiPervSPACEXMax = 10 ** 18;
    
    uint public secondaryStartTime;
    uint public secondaryEndTime;
    

    

    // In this system, individual vaults *are* addresses.  Instances of vaults then are mapped by bare address
    // Each vault has an "asset" side and a "debt" side
    // The following variables track all Vaults.  Not strictly needed, but helps liquidate non-compliant vaults
    mapping(address => bool) public isAddressRegistered;    // Forward map to emulate a "set" struct
    address[] public registeredAddresses;                   // Backward map for "set" struct
    

    // Vaults are defined here
    mapping(address => uint) public weiAsset;               // Weis the Vault owns -- the asset side. NET of queued assets
    mapping(address => uint) public vSPACEXDebtE18;         // vSPACEX -- the debt side of the balance sheet of each Vault.  NET of queued assets

    // Each Vault has a liquidation "queue".  It is not a strict queue.  While items are always enqueued on top (high serial number)
    // Items only *tend* to dequeue on bottom.
    
    struct VaultLiquidationQ {
        uint size;                              // Number of elements in this queue
        uint[] weiAssetInSpot;                  // wei amount being liquidated
        uint[] vSPACEXDebtInSpotE18;            // Amount of vSPACEX Debt being liqudiated.  Not strictly necessary but for recordkeeping.
        uint[] liqStartTime;                    // When did liquidation start?
        uint[] weiPervSPACEXTWAPAtChallenge;    // TWAP price at challenge time
        bool[] isLiqChallenged;                 // Is this liquidation being challenged?
        bool[] isHarvested;                     // Is this liquidation already harvested?
        uint[] liqChallengeWei;                 // Amount that has been put in for liquidation challenge purposes
        address payable[] liquidator;           // Who is liquidating?
    }
    
    mapping(address => VaultLiquidationQ) public VaultLiquidationQs;

    
    constructor() {
        owner = msg.sender;
        oracle = msg.sender;
        vSPACEXToken = new BackedToken("vSPACEX Token V1", "vSPACEX");
        //Pass in already existing ivtToken address

    }
    

    
    // This function attaches the Uniswap TWAP, without updating price at first.  After 24 hours of deploy, governance must update this price in order to make this smart contract usable.
    function govAttachTWAP() public {
        require(msg.sender == owner, "Denied: Gov Must Attach TWAP");
        require(isTWAPOracleAttached == false, "TWAP Already Attached");
        isTWAPOracleAttached = true;
        
        uniswapTWAPOracle = new ExampleOracleSimple(UNISWAP_FACTORY_ADDR, WETH_ADDR, address(vSPACEXToken), TWAP_PERIOD);
        
    }

    
    // Anyone can update the TWAP price.  Gov should update this at least once before the system is considered stable.
    function updateTWAPPrice() public { 
        uniswapTWAPOracle.update();
        weiPervSPACEXTWAP = uniswapTWAPOracle.consult(address(vSPACEXToken), 10 ** 18); // Verified 2021-02-17 Price Not Inverted
        weiPervSPACEXMax = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXTWAP : weiPervSPACEXSecondary;
        weiPervSPACEXMin = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXSecondary : weiPervSPACEXTWAP;
    }
    
    // Oracle Functions
    function oracleUpdatesecondaryTime(uint _secondaryStartTime, uint _secondaryEndTime) public {
        require(msg.sender == oracle, "Deny Update 2ndry Time: You are not oracle");
        require( (_secondaryStartTime <= _secondaryEndTime)  &&  (_secondaryEndTime <= block.timestamp), "Invalid time");
        
        secondaryStartTime = _secondaryStartTime;
        secondaryEndTime = _secondaryEndTime;
    }
    
    function oracleUpdateweiPervSPACEXSecondary(uint _weiPervSPACEXSecondary) public {
        require(msg.sender == oracle, "Denied: You are not oracle");
        weiPervSPACEXSecondary = _weiPervSPACEXSecondary;
        weiPervSPACEXMax = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXTWAP : weiPervSPACEXSecondary;
        weiPervSPACEXMin = (weiPervSPACEXTWAP >  weiPervSPACEXSecondary) ? weiPervSPACEXSecondary : weiPervSPACEXTWAP;
    }
    

    // Governance Functions
    function govUpdateinitialLTVE10(uint _initialLTVE10) public {
        require(msg.sender == owner, "Denied: You are not gov");
        initialLTVE10 = _initialLTVE10;
    }
    
    function govUpdatecAME18(uint _cAME18) public {
        require(msg.sender == owner, "Denied: You are not gov");
        cAME18 = _cAME18;
    }
    
    
    function govUpdatemaintLTVE10(uint _maintLTVE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maintLTVE10 = _maintLTVE10;
    }
    
    function govUpdateliqPenaltyE10(uint _liqPenaltyE10) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        liqPenaltyE10 = _liqPenaltyE10;
    }
    
    function govChangeOwner(address payable _owner) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        owner = _owner;
    }
    
    function govChangeOracle(address payable _oracle) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        oracle = _oracle;
    }
    
    function govChangemaxvSPACEXE18(uint _maxvSPACEXE18) public {
        require(msg.sender == owner, "Disallowed: You are not governance");
        maxvSPACEXE18 = _maxvSPACEXE18;
    }
    
    function govStartGlobalSettlement() public { // To be tested
        require(msg.sender == owner, "Disallowed: You are not governance");
        inGlobalSettlement = true;
        globalSettlementStartTime = block.timestamp;
    }
    
    
    
    
    // Vault Functions
    function depositWEI() public payable { // Same as receive fallback; but explictily declared for symmetry
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }
    
    receive() external payable { // Same as depositWEI()
        require(msg.value > 0, "Must Deposit Nonzero Wei"); 
        // Receiving is automatic so double entry accounting not possible here
        weiAsset[msg.sender] = weiAsset[msg.sender].add( msg.value );
        
        if(isAddressRegistered[msg.sender] != true) { // if user was not registered before
            isAddressRegistered[msg.sender] = true;
            registeredAddresses.push(msg.sender);
        }
    }

    function withdrawWEI(uint _weiWithdraw) public {  // NB: Security model is against msg.sender
        // Presuming contract withdrawal is from own vault
        require( _weiWithdraw < 10 ** 28, "Protective max bound for uint argument");
        
        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (initialLTVE10/1E10)
        // => After withdrawal (vSPYDebtE18)/1E18 * weiPervSPY <= (weiAsset - _weiWithdraw) * (initialLTVE10/1E10)
        uint LHS = vSPACEXDebtE18[msg.sender].mul( weiPervSPACEXMax ).mul( 10 ** 10 ); // presuming weiPervSPACEXMax < 10 ** 24 (million ETH spacex)
        uint RHS = (weiAsset[msg.sender].sub( _weiWithdraw )).mul( initialLTVE10 ).mul( 10 ** 18 );
        require ( LHS <= RHS, "Initial margin not enough to withdraw");
        
        // Double Entry Accounting
        weiAsset[msg.sender] = weiAsset[msg.sender].sub( _weiWithdraw ); // penalize wei deposited before sending money out
        msg.sender.transfer(_weiWithdraw);
    }
    
    
    function lendvSPACEX(uint _vSPACEXLendE18) public {
        //presuming message sender is using his own vault
        require(_vSPACEXLendE18 < 10 ** 30, "Protective max bound for uint argument");
        require(outstandingvSPACEXE18.add( _vSPACEXLendE18 ) <= maxvSPACEXE18, "Current version limits max amount of vSPACEX possible");
        
        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (initialLTVE10/1E10)
        // I need: (_vSPYLendE18 + vSPYDebtE18)/1E18 * weiPervSPY  < weiAsset * (initialLTVE10/1E10)
        uint LHS = vSPACEXDebtE18[msg.sender].add( _vSPACEXLendE18 ).mul( weiPervSPACEXMax ).mul( 10 ** 10 );
        uint RHS = weiAsset[msg.sender].mul( initialLTVE10 ).mul( 10 ** 18 );
        require(LHS < RHS, "Your initial margin is insufficient for lending");
        
        // Double Entry Accounting
        vSPACEXDebtE18[msg.sender] = vSPACEXDebtE18[msg.sender].add( _vSPACEXLendE18 ); // penalize debt first.
        outstandingvSPACEXE18 = outstandingvSPACEXE18.add(_vSPACEXLendE18);
        vSPACEXToken.ownerMint(msg.sender, _vSPACEXLendE18);
    }
    
    function repayvSPACEX(uint _vSPACEXRepayE18) public {
        require(_vSPACEXRepayE18 < 10 ** 30, "Protective max bound for uint argument");
        
        // vSPACEXToken.ownerApprove(msg.sender, _vSPACEXRepayE18);  //Todo: Make a separate react button for owner to approve.
        
        // Double Entry Accounting
        // vSPACEXToken.transferFrom(msg.sender, address(this), _vSPACEXRepayE18); // the actual deduction from the token contract
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXRepayE18);
        vSPACEXDebtE18[msg.sender] = vSPACEXDebtE18[msg.sender].sub( _vSPACEXRepayE18 );
        outstandingvSPACEXE18 = outstandingvSPACEXE18.sub(_vSPACEXRepayE18);
    }
    
    
    
    
    function findNoncompliantVaults(uint _limitNum) public view returns(address[] memory, uint[] memory, uint[] memory, uint) {   // Return the first N noncompliant vaults
        require(_limitNum > 0, "Must run this on a positive integer");
        address[] memory noncompliantAddresses = new address[](_limitNum);
        uint[] memory LHSs_vault = new uint[](_limitNum);
        uint[] memory RHSs_vault = new uint[](_limitNum);
        
        uint j = 0;  // Iterator up to _limitNum
        for (uint i=0; i<registeredAddresses.length; i++) { // Iterate up to all the registered addresses.  NB: Should cost zero gas because this is a view function.
            if(j>= _limitNum) { // Exits if _limitNum noncompliant vaults are found
                break;
            } 
            // Vault maintainance margin violation: (vSPYDebtE18)/1E18 * weiPervSPY  > weiAsset * (maintLTVE10)/1E10 for a violation
            uint LHS_vault = vSPACEXDebtE18[registeredAddresses[i]].mul(weiPervSPACEXMax);
            uint RHS_vault  = weiAsset[registeredAddresses[i]].mul( maintLTVE10 ).mul( 10 ** 8);
            
            if( (LHS_vault > RHS_vault) ) {
                noncompliantAddresses[j] = registeredAddresses[i];
                LHSs_vault[j] = LHS_vault;
                RHSs_vault[j] = RHS_vault;

                j = j + 1;
            }
        }
        return(noncompliantAddresses, LHSs_vault, RHSs_vault, j);
    }
    
    
    
    function liquidateNonCompliant(uint _vSPACEXProvidedE18, address payable target_address) public returns(uint) { // liquidates a portion of the contract for non-compliance
    
        // If the system is in the final stage of GS, you can't start a liquidation.
        require( isGloballySettled == false,"Cannot liq after GS closes." );
        
        // While it possible to have a more complex liquidation system, since liqudations are off-equilibrium, for the MVP 
        // We have decided we want overly aggressive liqudiations 
        require( _vSPACEXProvidedE18 <= vSPACEXDebtE18[target_address], "You cannot provide more vSPACEX than vSPACEXDebt outstanding");


        // Maintenence Equation: (vSPYDebtE18/1E18) * weiPervSPY <= (weiAsset) * (maintLTVE10/1E10)
        // For a violation, the above will be flipped: (vSPYDebtE18/1E18) * weiPervSPY > (weiAsset) * (maintLTVE10/1E10)        
        uint LHS = vSPACEXDebtE18[target_address].mul( weiPervSPACEXMax ).mul( 10 ** 10);
        uint RHS = weiAsset[target_address].mul( maintLTVE10 ).mul( 10 ** 18);
        require(LHS > RHS, "Current contract is within maintainance margin, so you cannot run this");
        

        // If this vault is underwater-with-respect-to-rewards (different than noncompliant), liquidation is pro-rata
        // underater iff: weiAsset[target_address] < vSPYDebtE18[target_address]/1E18 * weiPervSPY * (liqPenaltyE10+1E10)/1E10
        uint LHS2 = weiAsset[target_address].mul( 10 ** 18 ).mul( 10 ** 10);
        uint RHS2 = vSPACEXDebtE18[target_address].mul( weiPervSPACEXMax ).mul( liqPenaltyE10.add( 10 ** 10 ));
        
        uint weiClaim;
        if( LHS2 < RHS2 ) { // pro-rata claim
            // weiClaim = ( _vSPYProvidedE18 /  vSPYDebtE18[target_address]) * weiAsset[target_address];
            weiClaim = _vSPACEXProvidedE18.mul( weiAsset[target_address] ).div( vSPACEXDebtE18[target_address] );
        } else {
            // maxWeiClaim = _vSPYProvidedE18/1E18 * weiPervSPY * (1+liqPenaltyE10/1E10)
            weiClaim = _vSPACEXProvidedE18.mul( weiPervSPACEXMax ).mul( liqPenaltyE10.add( 10 ** 10 )).div( 10 ** 18 ).div( 10 ** 10 );
        }
        require(weiClaim <= weiAsset[target_address], "Code Error if you reached this point");
        
        
        // Double Entry Accounting for returning vSPY Debt back
        // vSPACEXToken.ownerApprove(msg.sender, _vSPACEXProvidedE18);  // Todo: Require Owner to approve token first.
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXProvidedE18); // the actual deduction from the token contract
        vSPACEXDebtE18[target_address] = vSPACEXDebtE18[target_address].sub( _vSPACEXProvidedE18 );
        outstandingvSPACEXE18 = outstandingvSPACEXE18.sub( _vSPACEXProvidedE18 );
        
        
        // Double Entry Accounting for deducting the vault's assets
        weiAsset[target_address] = weiAsset[target_address].sub( weiClaim );
        
        
        if(weiPervSPACEXSecondary == weiPervSPACEXMax) {    // If the secondary price is the basis of liquidation, no wait is needed
            msg.sender.transfer( weiClaim );
            return 10 ** 30; // Sentinel for 
        } else {  // Otherwise, we need to wait LIQ_WAIT_TIME for liquidation
        
       
        uint i = VaultLiquidationQs[target_address].size; // Index i must always be less than size.  Solidity is zero indexed
        VaultLiquidationQs[target_address].size = VaultLiquidationQs[target_address].size.add( 1 );
        
        VaultLiquidationQs[target_address].weiAssetInSpot.push(weiClaim);                                // wei amount being liquidated
        VaultLiquidationQs[target_address].vSPACEXDebtInSpotE18.push(_vSPACEXProvidedE18);               // amount of vSPACEX Debt being liqudiated
        VaultLiquidationQs[target_address].liqStartTime.push(block.timestamp);                           // when did liquidation start?
        VaultLiquidationQs[target_address].weiPervSPACEXTWAPAtChallenge.push(weiPervSPACEXTWAP);         // TWAP price at challenge time
        VaultLiquidationQs[target_address].isLiqChallenged.push(false);                                  // Is this liquidation being challenged?
        VaultLiquidationQs[target_address].liqChallengeWei.push(0);                                      // Amount that has been put in for liquidation challenge purposes
        VaultLiquidationQs[target_address].liquidator.push(msg.sender); 
        VaultLiquidationQs[target_address].isHarvested.push(false); 
        return i;   // Liquidator expictly gets back their claim ticket number
        }
    }
    
    function settleUnchallengedLiquidation(address _targetVault, uint _position) public { // Liquidator can call
        // If in Global Settlement Final: Still allow, because otherwise wei locked in Q cannot be retrieved
        // critical requirements
        require(_position <  VaultLiquidationQs[_targetVault].size, "Err: PosInv"); // position needs to be valid
        require(msg.sender == VaultLiquidationQs[_targetVault].liquidator[_position] , "Err: LiqCal"); // only liqudiator can call
        require(VaultLiquidationQs[_targetVault].liqStartTime[_position] + LIQ_WAIT_TIME < block.timestamp, "Err: WaitL"); // must be LIQ_WAIT_TIME (28 hour in v1) later.
        require(VaultLiquidationQs[_targetVault].isLiqChallenged[_position] == false, "Err: AlrCha"); // Must not be challenged
        require(VaultLiquidationQs[_targetVault].isHarvested[_position] == false, "Err: AlrHar"); // Must not be harvseted yet
        
        // other assumptions
        require( VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] > 0, "SErr: Wei");
        require( VaultLiquidationQs[_targetVault].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP");
        require( VaultLiquidationQs[_targetVault].liqChallengeWei[_position] == 0, "SErr: lCW"); 
        
        // end the challenge
        
        // set the future claimable values to zero
        VaultLiquidationQs[_targetVault].isHarvested[_position] = true; // blocks a second transfer from happening
        uint weiClaim = VaultLiquidationQs[_targetVault].weiAssetInSpot[_position];
        VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] = 0;
        
        // make the transfer
        VaultLiquidationQs[_targetVault].liquidator[_position].transfer( weiClaim );
    }
    
    
        
    
    function challengeLiquidation(uint _position) public payable  {                     // usually owner of vault calls, but anyone can benefit the owner
    
        require( isGloballySettled == false,"Cannot challenge after GS Closes." );      // Vault owner will have had at least GLOBAL_SETTLEMENT_PERIOD or 28 hours to challenge.  
        // No need to allow this edge case of more challenges after global settlement closes.
    
        require(_position <  VaultLiquidationQs[msg.sender].size, "Err: PosInv");                      // position needs to be valid
        require(VaultLiquidationQs[msg.sender].isHarvested[_position] == false, "Err: AlrHar");        // Must not be harvested yet
        require(VaultLiquidationQs[msg.sender].isLiqChallenged[_position] == false, "Err: AlrCha");    // Must not be challenged

        
        require(msg.value >= ( VaultLiquidationQs[msg.sender].weiPervSPACEXTWAPAtChallenge[_position].mul( VaultLiquidationQs[msg.sender].vSPACEXDebtInSpotE18[_position] ).div(10 ** 18)), "Err: ChaAmt" ); 
        // Require owner to challenge the liqudiation with an amount of wei equal to the vSPACEX the liquidator provided, at the Uniswap price then.
        
        // other assumptions
        require( VaultLiquidationQs[msg.sender].weiAssetInSpot[_position] > 0 , "SErr: Wei");
        require( VaultLiquidationQs[msg.sender].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP" );
        require( VaultLiquidationQs[msg.sender].liqChallengeWei[_position] == 0, "SErr: lCW");
        // INTENTIONALLY don't block challenges even after LIQ_WAIT_TIME, as long as vault hasn't yet been harvested
        // No restriction on liqudiator
        
        // at this point, record the challenged
        VaultLiquidationQs[msg.sender].isLiqChallenged[_position] = true;
        VaultLiquidationQs[msg.sender].liqChallengeWei[_position] = msg.value;
    } 
    
    
    
    function endChallengeLiquidation(address _targetVault, uint _position) public {                 // Anyone can run, but only owner and liqudiator have direct incentive.
        // NB: who the challege in ends in favor of depends on when it is run.  Thus it is in favor of the winning claimaint to run soon.
        require(_position <  VaultLiquidationQs[_targetVault].size, "Err: PosInv");                                // position needs to be valid
        require( VaultLiquidationQs[_targetVault].isLiqChallenged[_position] == true, "Err: NotCha");             // Must be challenged
        require( VaultLiquidationQs[_targetVault].isHarvested[_position] == false, "Err: AlrHar");                  // Must not be harvested yet
        
        if(isGloballySettled == false) { // Only in case of world where Global Settlement is closed, can the secondaryPrice can be old
            require( secondaryStartTime > VaultLiquidationQs[_targetVault].liqStartTime[_position], "Err: OldSO" );     // requires the secondary oracle to have been updated after the challenge started.
        }
        
        // optional checks
        require( VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] > 0 , "SErr: Wei");
        require( VaultLiquidationQs[_targetVault].vSPACEXDebtInSpotE18[_position] > 0, "SErr: vSP"); 
        require( VaultLiquidationQs[_targetVault].liqStartTime[_position]  + LIQ_WAIT_TIME < block.timestamp , "SErr: lCW"); // 28 hours must have elapsed as sanity check
        // TWAP price checked later
        // Function runner could be anyone
        
        // Payoff is both the base liquidate amount and the challenge amount:
        uint weiClaim = VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] + VaultLiquidationQs[_targetVault].liqChallengeWei[_position];
        VaultLiquidationQs[_targetVault].weiAssetInSpot[_position] = 0;
        VaultLiquidationQs[_targetVault].liqChallengeWei[_position] = 0;
        
        
        
        // settle vaults
        VaultLiquidationQs[_targetVault].isLiqChallenged[_position] = false;
        VaultLiquidationQs[_targetVault].isHarvested[_position] = true;
        
        
        // transfer out
        if( weiPervSPACEXSecondary * 3 < VaultLiquidationQs[_targetVault].weiPervSPACEXTWAPAtChallenge[_position] ) { // if the secondary price is much less than old TWAP (thus short squeeze)
            // End in favor of the challenger (vault owner).  Credit the target Vault.
            weiAsset[_targetVault] = weiClaim.add( weiAsset[_targetVault] );
        } else { // this was not a short squeeze
            // End in favor of the liquidator
            VaultLiquidationQs[_targetVault].liquidator[_position].transfer( weiClaim );
        }
    }
    
    // The following functions are off off-equilibrium.  Thus they are vetted to be safe, but not necessarily efficient/optimal.


    // Global Settlement Functions. Global settlement must start with governance. However, afterwards, closing of Global Settlement can be done by anyone
    function registerGloballySettled() public { // Anyone can run this closing function
        require(inGlobalSettlement, "Gov must start settlement");
        require(block.timestamp > (globalSettlementStartTime + GLOBAL_SETTLEMENT_PERIOD), "Wait TIME to finalize.");
        require(!isGloballySettled, "Settlement Already Closed");
        settledWeiPervSPACEX = weiPervSPACEXSecondary;  // For fidelity, only actual SPACEX transaction prices (not vSPACEX coin) used for settlement.
        isGloballySettled = true;
    }
    
    function settledConvertvSPACEXtoWei(uint _vSPACEXTokenToConvertE18) public { // After Global Settlement (GS) someone who has vSPACEX can run to redeem.
        require(isGloballySettled);
        require(_vSPACEXTokenToConvertE18 < 10 ** 30, "Protective max bound for input hit");
        
        uint weiToReturn = _vSPACEXTokenToConvertE18.mul( settledWeiPervSPACEX ).div( 10 ** 18); // Rounds down
        
        // vSPACEX accounting is no longer double entry.  Destroy vSPACEX to get wei
        //vSPACEXToken.ownerApprove(msg.sender, _vSPACEXTokenToConvertE18);                       // Factory gives itself approval. Todo: Require owner give this contract control
        vSPACEXToken.ownerBurn(msg.sender, _vSPACEXTokenToConvertE18);                          // the actual deduction from the token contract
        msg.sender.transfer(weiToReturn);                                                       // return wei
    }
    
    
    function settledConvertVaulttoWei() public {        // After GS, someone who has a vault can withdraw the remaining value in the vault.
        require(isGloballySettled);
        
        uint weiDebt = vSPACEXDebtE18[msg.sender].mul( settledWeiPervSPACEX ).div( 10 ** 18).add( 1 );       // Convert vSPACEX Debt to Wei. Round up.
        require(weiAsset[msg.sender] > weiDebt, "This CTV is not above water, cannot convert");     
        
        uint weiEquity = weiAsset[msg.sender] - weiDebt;
        
        
        // Zero out CTV and transfer equity remaining
        vSPACEXDebtE18[msg.sender] = 0;
        weiAsset[msg.sender] = 0;
        msg.sender.transfer(weiEquity);  
    }

    


    function detachOwner() public { // an emergency function to commitally shut off the owner account while retaining residual functionality of tokens
        require(msg.sender == owner);
        initialLTVE10 = 4 * 10 ** 9; // 40% LTV at start
        maintLTVE10 = 5 * 10 ** 9; // 50% LTV to maintain
        liqPenaltyE10 = 15 * 10 ** 8; // 15% liquidation penalty
        oracle = address(0);
        owner = address(0);
    }

    
}





"}}