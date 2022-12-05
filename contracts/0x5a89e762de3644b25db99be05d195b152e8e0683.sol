{"IUniswapV2Pair.sol":{"content":"pragma solidity >=0.5.0;

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
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}
"},"UniswapTwapPriceOracleV2Ceiling.sol":{"content":"// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "SafeMath.sol";

import "IUniswapV2Pair.sol";

/**
 * @title UniswapTwapPriceOracleV2Ceiling
 * @dev based on UniswapTwapPriceOracleRoot by David Lucid <david@rari.capital> (https://github.com/davidlucid)
 * @notice Stores cumulative prices and returns TWAPs for assets on Uniswap V2 pairs.
 */
contract UniswapTwapPriceOracleV2Ceiling {
    using SafeMath for uint256;

    /**
     * @dev Current price ceiling for the oracle
     */
    uint public priceCeiling;

    /**
     * @dev maximum amount ceilining can be set above current price, in basis points, above. 1 = 0.01%
     */
    uint public maxBPCeiling;

    /**
     * @dev minimum amount ceiling can be set above current price in, basis points, above current price. 1 = 0.01%
     */
    uint public minBPCeiling;

    /**
     * @dev WETH token contract address.
     */
    address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @dev underlying token contract address.
     */
    address constant public underlying = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;

    /**
     * @dev uniswapV2 pair between underlying and WETH
     */
    IUniswapV2Pair constant public pair = IUniswapV2Pair(0x328dFd0139e26cB0FEF7B0742B49b0fe4325F821);

    /**
     * @dev Governance address, can set maxBPCeiling and minBPCeiling
     */
    address public governance;

    /**
     * @dev Guardian address, can raise or lower price ceiling
     */
    address public guardian;

    /**
     * @dev Minimum TWAP interval.
     */
    uint256 immutable public MIN_TWAP_TIME;

    /**
     * @dev Internal baseUnit used as mantissa, set from decimals of underlying.
     */
    uint immutable private baseUnit;

    constructor(uint MIN_TWAP_TIME_, uint maxBPCeiling_, uint minBPCeiling_, uint underlyingDecimals, address governance_, address guardian_) public {
        MIN_TWAP_TIME = MIN_TWAP_TIME_;
        maxBPCeiling = maxBPCeiling_;
        minBPCeiling = minBPCeiling_;
        governance = governance_;
        guardian = guardian_;
        baseUnit = 10 ** underlyingDecimals;
        priceCeiling = type(uint).max;
        //Update oracle at deployment, to avoid having to check against 0 observations for the rest of the oracle's lifetime
        _update();
    }

    /**
     * @dev Return the TWAP value price0. Revert if TWAP time range is not within the threshold.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     */
    function priceTWAP() internal view returns (uint) {
        uint length = observationCount;
        Observation memory lastObservation = observations[(length - 1) % OBSERVATION_BUFFER];
        if (lastObservation.timestamp > now - MIN_TWAP_TIME) {
            require(length > 1, 'No length-2 TWAP observation.');//TODO: A lot of checking to do for something that's only relevant when only 1 observation have been made
            lastObservation = observations[(length - 2) % OBSERVATION_BUFFER];
        }
        uint elapsedTime = now - lastObservation.timestamp;
        require(elapsedTime >= MIN_TWAP_TIME, 'Bad TWAP time.');
        return (currentPxCumu() - lastObservation.priceCumulative) / elapsedTime; // overflow is desired
    }
    /**
     * @dev Return the current price cumulative value on Uniswap.
     * Copied from: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/BaseKP3ROracle.sol
     */
    function currentPxCumu() internal view returns (uint pxCumu) {
        uint32 currTime = uint32(now);
        pxCumu = pair.price0CumulativeLast();
        (uint reserve0, uint reserve1, uint32 lastTime) = pair.getReserves();
        if (lastTime != now) {
            uint32 timeElapsed = currTime - lastTime; // overflow is desired
            pxCumu += uint((reserve1 << 112) / reserve0) * timeElapsed; // overflow is desired
        }
    }
    /**
     * @dev Returns the price of `underlying` in terms of `baseToken` given `factory`.
     */
    function price() public view returns (uint) {
        // Return ERC20/ETH TWAP
        uint twapPrice = priceTWAP().div(2 ** 56).mul(baseUnit).div(2 ** 56);
        return twapPrice < priceCeiling ? twapPrice : priceCeiling;
    }

    /**
     * @dev Struct for cumulative price observations.
     */
    struct Observation {
        uint32 timestamp;
        uint256 priceCumulative;
    }

    /**
     * @dev Length after which observations roll over to index 0.
     */
    uint8 public constant OBSERVATION_BUFFER = 4;

    /**
     * @dev Total observation count for each pair.
     */
    uint256 public observationCount;

    /**
     * @dev Array of cumulative price observations for each pair.
     */
    Observation[OBSERVATION_BUFFER] public observations;

    /// @dev Internal function to check if oracle is workable (updateable AND reserves have changed AND deviation threshold is satisfied).
    function workable(uint256 minPeriod, uint256 deviationThreshold) external view returns (bool) {
        // Workable if:
        // The elapsed time since the last observation is > minPeriod AND reserves have changed AND deviation threshold is satisfied 
        // Note that we loop observationCount around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        (, , uint32 lastTime) = pair.getReserves();
        return (block.timestamp - observations[(observationCount - 1) % OBSERVATION_BUFFER].timestamp) > (minPeriod >= MIN_TWAP_TIME ? minPeriod : MIN_TWAP_TIME) &&
            lastTime != observations[(observationCount - 1) % OBSERVATION_BUFFER].timestamp &&
            _deviation() >= deviationThreshold;
    }

    /// @dev Internal function to return oracle deviation from its TWAP price as a ratio scaled by 1e18
    function _deviation() internal view returns (uint256) {
        // Get TWAP price
        uint256 twapPrice = priceTWAP().div(2 ** 56).mul(baseUnit).div(2 ** 56); // Scaled by 1e18, not 2 ** 112
    
        // Get spot price
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        uint256 spotPrice = reserve1.mul(baseUnit).div(reserve0);

        // Get ratio and return deviation
        uint256 ratio = spotPrice.mul(1e18).div(twapPrice);
        return ratio >= 1e18 ? ratio - 1e18 : 1e18 - ratio;
    }
    
    /// @dev Internal function to check if oracle is updatable at all.
    function _updateable() internal view returns (bool) {
        // Updateable if:
        // 1) The elapsed time since the last observation is > MIN_TWAP_TIME
        // 2) The observation price (current price) is below priceCeiling
        // Note that we loop observationCount around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        return(block.timestamp - observations[(observationCount - 1) % OBSERVATION_BUFFER].timestamp) > MIN_TWAP_TIME;
    }
    
    function timeSinceLastUpdate() public view returns (uint) {
        return block.timestamp - observations[(observationCount - 1) % OBSERVATION_BUFFER].timestamp;
    }

    /// @notice Update the oracle
    function update() external returns(bool) {
        if(!_updateable()){
            return false;
        }
        _update();
        return true;
    }


    /// @dev Internal function to update
    function _update() internal{
        // Get cumulative price
        uint256 priceCumulative = pair.price0CumulativeLast();
        
        // Loop observationCount around OBSERVATION_BUFFER so we don't waste gas on new storage slots
        (, , uint32 lastTime) = pair.getReserves();
        observations[observationCount % OBSERVATION_BUFFER] = Observation(lastTime, priceCumulative);
        observationCount++;
    }
    // **************************
    // **  GUARDIAN FUNCTIONS  **
    // **************************

    /**
     * @dev Function for setting newPriceCeiling, only callable by guardian
     * @param newPriceCeiling_ The new price ceiling, must be within max and min parameters
     */
    function setPriceCeiling(uint newPriceCeiling_) external {
        require(msg.sender == guardian);
        uint currentPrice = price();
        require(newPriceCeiling_ <= currentPrice + currentPrice*maxBPCeiling/10_000);
        require(newPriceCeiling_ >= currentPrice + currentPrice*minBPCeiling/10_000);
        priceCeiling = newPriceCeiling_;
        emit newPriceCeiling(newPriceCeiling_);
    }

    // **************************
    // ** GOVERNANCE FUNCTIONS **
    // **************************

    /**
     * @dev Function for setting new governance, only callable by governance
     * @param newGovernance_ address of the new guardian
     */
    function setGovernance(address newGovernance_) external {
        require(msg.sender == governance);
        governance = newGovernance_;
        emit newGovernance(newGovernance_);
    }

    /**
     * @dev Function for setting new guardian, only callable by governance
     * @param newGuardian_ address of the new guardian
     */
    function setGuardian(address newGuardian_) external {
        require(msg.sender == governance);
        guardian = newGuardian_;
        emit newGuardian(newGuardian_);
    }

    /**
     * @dev Function for setting new max height of price ceiling in basis points. 1 = 0.01%
     * @param newMaxBPCeiling_ New maximum amount a ceiling can go above current price
     */
    function setMaxBPCeiling(uint newMaxBPCeiling_) external {
        require(msg.sender == governance);
        require(newMaxBPCeiling_ >= minBPCeiling);
        maxBPCeiling = newMaxBPCeiling_;
        emit newMaxBPCeiling(newMaxBPCeiling_);
    }

    /**
     * @dev Function for setting new min height of price ceiling in basis points. 1 = 0.01%
     * @param newMinBPCeiling_ New minimum amount a ceiling must be above current price
     */
    function setMinBPCeiling(uint newMinBPCeiling_) external {
        require(msg.sender == governance);
        require(maxBPCeiling >= newMinBPCeiling_);
        minBPCeiling = newMinBPCeiling_;
        emit newMinBPCeiling(newMinBPCeiling_);
    }

    // ************
    // ** EVENTS **
    // ************
    event newPriceCeiling(uint newPriceCeiling);
    event newGuardian(address newGuardian);
    event newGovernance(address newGovernance);
    event newMaxBPCeiling(uint newMaxBPCeiling);
    event newMinBPCeiling(uint newMinBPCeiling);
}
"}}