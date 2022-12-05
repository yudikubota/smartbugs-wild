{{
  "language": "Solidity",
  "sources": {
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

    function bake(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        uint256 _outputAmount,
        uint256 _maxPrice
    ) public {
        require(msg.sender == controller, "NOT_CONTROLLER");
        require(_receivers.length == _amounts.length, "UNEQUAL_LENGTH");

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

            uint256 userAmount = _amounts[i];
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

    function deposit() public payable {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        require(address(this).balance <= cap, "MAX_CAP");
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

    function withdrawETH(uint256 _amount, address payable _receiver) public {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_amount);
        _receiver.transfer(_amount);
        emit WithdrawETH(msg.sender, _amount, _receiver);
    }

    function withdrawOutput(uint256 _amount, address _receiver) external {
        outputBalanceOf[msg.sender] = outputBalanceOf[msg.sender].sub(_amount);
        pie.transfer(_receiver, _amount);
        emit WithdrawOuput(msg.sender, _amount, _receiver);
    }

    function setCap(uint256 _cap) external {
        require(msg.sender == controller, "NOT_CONTROLLER");
        cap = _cap;
    }

    function setController(address _controller) external {
        require(msg.sender == controller, "NOT_CONTROLLER");
        controller = _controller;
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
        pie.transfer(msg.sender, amount);
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
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
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