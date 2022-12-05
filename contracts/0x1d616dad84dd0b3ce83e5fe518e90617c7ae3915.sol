{{
  "language": "Solidity",
  "sources": {
    "contracts/interfaces/IExperiPie.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IExperiPie is IERC20 {
    // fee functions
    function setEntryFee(uint256 _fee) external;

    function getEntryFee() external view returns (uint256);

    function setExitFee(uint256 _fee) external;

    function getExitFee() external view returns (uint256);

    function setAnnualizedFee(uint256 _fee) external;

    function getAnnualizedFee() external view returns (uint256);

    function setFeeBeneficiary(address _beneficiary) external;

    function getFeeBeneficiary() external view returns (address);

    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    function getEntryFeeBeneficiaryShare() external view returns (uint256);

    function setExitFeeBeneficiaryShare(uint256 _share) external;

    function getExitFeeBeneficiaryShare() external view returns (uint256);

    function calcOutStandingAnnualizedFee() external view returns (uint256);

    function chargeOutstandingAnnualizedFee() external;

    // function initialize(address[] memory _tokens, uint256 _maxCap) external;
    function joinPool(uint256 _amount) external;

    function exitPool(uint256 _amount) external;

    function getLock() external view returns (bool);

    function getLockBlock() external view returns (uint256);

    function setLock(uint256 _lock) external;

    function getCap() external view returns (uint256);

    function setCap(uint256 _maxCap) external returns (uint256);

    function balance(address _token) external view returns (uint256);

    function getTokens() external view returns (address[] memory);

    function addToken(address _token) external;

    function removeToken(address _token) external;

    function getTokenInPool(address _token) external view returns (bool);

    function mint(address _receiver, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    // CallFacet
    function call(
        address[] memory _targets,
        bytes[] memory _calldata,
        uint256[] memory _values
    ) external;

    function addCaller(address _caller) external;

    function removeCaller(address _caller) external;

    function canCall(address _caller) external view returns (bool);

    function getCallers() external view returns (address[] memory);

    // Ownership

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address);

    // ERC20
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // ERC20 facet
    function initialize(
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
"
    },
    "contracts/test/TestPieRecipe.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/PieRecipe.sol";

contract TestPieRecipe {
    using SafeMath for uint256;
    mapping(address => uint256) private balance;

    uint256 public calcToPieAmount;

    function toPie(address _pie, uint256 _poolAmount) public payable {
        IERC20 pie = IERC20(_pie);
        uint256 amount = calcToPie(_pie, _poolAmount);
        require(msg.value == amount, "Amount ETH too low");
        pie.transfer(msg.sender, _poolAmount);
    }

    function testSetCalcToPieAmount(uint256 _amount) external {
        calcToPieAmount = _amount;
    }

    function calcToPie(address _pie, uint256 _poolAmount)
        public
        view
        returns (uint256)
    {
        return calcToPieAmount;
    }
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    "contracts/interfaces/PieRecipe.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface PieRecipe {
    function toPie(address _pie, uint256 _poolAmount) external payable;

    function calcToPie(address _pie, uint256 _poolAmount)
        external
        view
        returns (uint256);
}
"
    },
    "contracts/oven/Oven.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/PieRecipe.sol";

contract Oven {
    using SafeMath for uint256;

    event Deposit(address user, uint256 amount);
    event WithdrawETH(address user, uint256 amount, address receiver);
    event WithdrawOuput(address user, uint256 amount, address receiver);
    event Bake(address user, uint256 amount, uint256 price);

    mapping(address => uint256) public ethBalanceOf;
    mapping(address => uint256) public outputBalanceOf;
    address public controller;
    IERC20 public pie;
    PieRecipe public recipe;
    uint256 public cap;

    constructor(
        address _controller,
        address _pie,
        address _recipe
    ) public {
        controller = _controller;
        pie = IERC20(_pie);
        recipe = PieRecipe(_recipe);
    }

    modifier ovenIsReady {
        require(address(pie) != address(0), "PIE_NOT_SET");
        require(address(recipe) != address(0), "RECIPE_NOT_SET");
        _;
    }

    modifier controllerOnly {
        require(msg.sender == controller, "NOT_CONTROLLER");
        _;
    }

    // _maxprice should be equal to the sum of _receivers.
    // this variable is needed because in the time between calling this function
    // and execution, the _receiver amounts can differ.
    function bake(
        address[] calldata _receivers,
        uint256 _outputAmount,
        uint256 _maxPrice
    ) public ovenIsReady controllerOnly {
        uint256 realPrice = recipe.calcToPie(address(pie), _outputAmount);
        require(realPrice <= _maxPrice, "PRICE_ERROR");

        uint256 totalInputAmount = 0;
        for (uint256 i = 0; i < _receivers.length; i++) {
            // This logic aims to execute the following logic
            // E.g. 5 eth is needed to mint the outputAmount
            // User 1: 2 eth (100% used)
            // User 2: 2 eth (100% used)
            // User 3: 2 eth (50% used)
            // User 4: 2 eth (0% used)

            uint256 userAmount = ethBalanceOf[_receivers[i]];
            if (totalInputAmount == realPrice) {
                break;
            } else if (totalInputAmount.add(userAmount) <= realPrice) {
                totalInputAmount = totalInputAmount.add(userAmount);
            } else {
                userAmount = realPrice.sub(totalInputAmount);
                // e.g. totalInputAmount = realPrice
                totalInputAmount = totalInputAmount.add(userAmount);
            }

            ethBalanceOf[_receivers[i]] = ethBalanceOf[_receivers[i]].sub(
                userAmount
            );

            uint256 userBakeAmount = _outputAmount.mul(userAmount).div(
                realPrice
            );
            outputBalanceOf[_receivers[i]] = outputBalanceOf[_receivers[i]].add(
                userBakeAmount
            );

            emit Bake(_receivers[i], userBakeAmount, userAmount);
        }
        // Provided balances are too low.
        require(totalInputAmount == realPrice, "INSUFFICIENT_FUNDS");
        recipe.toPie{value: realPrice}(address(pie), _outputAmount);
    }

    function deposit() public payable ovenIsReady {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        require(address(this).balance <= cap, "MAX_CAP");
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

    function withdrawAll(address payable _receiver) external ovenIsReady {
        withdrawAllETH(_receiver);
        withdrawOutput(_receiver);
    }

    function withdrawAllETH(address payable _receiver) public ovenIsReady {
        withdrawETH(ethBalanceOf[msg.sender], _receiver);
    }

    function withdrawETH(uint256 _amount, address payable _receiver)
        public
        ovenIsReady
    {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_amount);
        _receiver.transfer(_amount);
        emit WithdrawETH(msg.sender, _amount, _receiver);
    }

    function withdrawOutput(address _receiver) public ovenIsReady {
        uint256 _amount = outputBalanceOf[msg.sender];
        outputBalanceOf[msg.sender] = 0;
        pie.transfer(_receiver, _amount);
        emit WithdrawOuput(msg.sender, _amount, _receiver);
    }

    function setCap(uint256 _cap) external controllerOnly {
        cap = _cap;
    }

    function setController(address _controller) external controllerOnly {
        controller = _controller;
    }

    function setPie(address _pie) public controllerOnly {
        // Only able to change pie from address(0) to an actual address
        // Otherwise old outputBalances can conflict with a new pie
        require(address(pie) == address(0), "PIE_ALREADY_SET");
        pie = IERC20(_pie);
    }

    function setRecipe(address _recipe) public controllerOnly {
        // Only able to change pie from address(0) to an actual address
        // Otherwise old outputBalances can conflict with a new pie
        require(address(recipe) == address(0), "RECIPE_ALREADY_SET");
        recipe = PieRecipe(_recipe);
    }

    function setPieAndRecipe(address _pie, address _recipe) external {
        setPie(_pie);
        setRecipe(_recipe);
    }

    function getCap() external view returns (uint256) {
        return cap;
    }

    function saveToken(address _token) external {
        require(_token != address(pie), "INVALID_TOKEN");

        IERC20 token = IERC20(_token);

        token.transfer(
            address(0x4efD8CEad66bb0fA64C8d53eBE65f31663199C6d),
            token.balanceOf(address(this))
        );
    }
}
"
    },
    "contracts/oven/OvenFactoryContract.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Oven.sol";

contract OvenFactoryContract is Ownable {
    event OvenCreated(
        address Oven,
        address Controller,
        address Pie,
        address Recipe
    );

    address[] public ovens;
    mapping(address => bool) public isOven;
    address public defaultController;

    function setDefaultController(address _controller) external onlyOwner {
        defaultController = _controller;
    }

    function CreateEmptyOven() external {
        CreateOven(address(0), address(0));
    }

    // TODO, everyone can create an oven?
    function CreateOven(address _pie, address _recipe) public {
        require(defaultController != address(0), "CONTROLLER_NOT_SET");

        Oven oven = new Oven(address(this), _pie, _recipe);
        ovens.push(address(oven));
        isOven[address(oven)] = true;

        oven.setCap(uint256(-1));
        oven.setController(defaultController);
        emit OvenCreated(address(oven), defaultController, _pie, _recipe);
    }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    },
    "contracts/test/TestPie.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestPie {
    using SafeMath for uint256;

    mapping(address => uint256) private balance;

    constructor(uint256 _supply, address _address) {
        balance[_address] = _supply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        return true;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balance[_address];
    }
}
"
    },
    "contracts/recipes/recipes/UniswapV2Library.sol": {
      "content": "pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

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
}"
    },
    "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol": {
      "content": "pragma solidity >=0.5.0;

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
"
    },
    "contracts/recipes/recipes/SafeMath.sol": {
      "content": "
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "ds-math-div-zero");
        uint256 c = a / b;
        return c;
    }
}"
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
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}