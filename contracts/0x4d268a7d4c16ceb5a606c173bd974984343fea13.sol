{{
  "language": "Solidity",
  "sources": {
    "contracts/X2TimeDistributor.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/math/SafeMath.sol";
import "./interfaces/IX2TimeDistributor.sol";

contract X2TimeDistributor is IX2TimeDistributor {
    using SafeMath for uint256;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;

    address public gov;

    mapping (address => uint256) public override ethPerInterval;
    mapping (address => uint256) public override lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount);

    constructor() public {
        gov = msg.sender;
    }

    receive() external payable {}

    function setDistribution(address[] calldata _receivers, uint256[] calldata _amounts) external {
        require(msg.sender == gov, "X2TimeDistributor: forbidden");

        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];

            if (lastDistributionTime[receiver] != 0) {
                uint256 currentTime = block.timestamp;
                uint256 timeDiff = currentTime.sub(lastDistributionTime[receiver]);
                uint256 intervals = timeDiff.div(DISTRIBUTION_INTERVAL);
                require(intervals == 0, "X2TimeDistributor: pending distribution");
            }

            uint256 amount = _amounts[i];
            ethPerInterval[receiver] = amount;
            lastDistributionTime[receiver] = block.timestamp;
            emit DistributionChange(receiver, amount);
        }
    }

    function distribute() external returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) { return 0; }

        uint256 amount = getDistributionAmount(receiver);
        lastDistributionTime[msg.sender] = block.timestamp;

        if (amount == 0) { return 0; }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "X2TimeDistributor: transfer failed");

        emit Distribute(msg.sender, amount);
        return amount;
    }

    function getDistributionAmount(address receiver) public override view returns (uint256) {
        uint256 _ethPerInterval = ethPerInterval[receiver];
        if (_ethPerInterval == 0) { return 0; }

        uint256 intervals = getIntervals(receiver);
        uint256 amount = _ethPerInterval.mul(intervals);

        if (address(this).balance < amount) { return 0; }

        return amount;
    }

    function getIntervals(address receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime[receiver]);
        return timeDiff.div(DISTRIBUTION_INTERVAL);
    }
}
"
    },
    "contracts/libraries/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    "contracts/interfaces/IX2TimeDistributor.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2TimeDistributor {
    function getDistributionAmount(address receiver) external view returns (uint256);
    function ethPerInterval(address receiver) external view returns (uint256);
    function lastDistributionTime(address receiver) external view returns (uint256);
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