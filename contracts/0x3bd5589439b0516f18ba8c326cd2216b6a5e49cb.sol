{"IERC20.sol":{"content":"pragma solidity >= 0.6.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"ownable.sol":{"content":"pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"},"priceAggregatorInterface.sol":{"content":"pragma solidity >= 0.6.6;

interface priceAggregatorInterface {
  function registerVaultAggregator(address oracle) external;
  function priceRequest(
    address vault,
    uint256 lastUpdated
  )
  external
  view
  returns(int256[] memory, uint256);
  function roundIdCheck(address vault) external view returns(bool);
}
"},"priceCalculator.sol":{"content":"//////////////////////////////////////////////////
//SYNLEV Price Calculator Contract V 1.2
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './SignedSafeMath.sol';
import './IERC20.sol';
import './vaultInterface.sol';
import './priceAggregatorInterface.sol';

contract priceCalculator is Owned {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  constructor() public {
    lossLimit = 9 * 10**8;
    kControl = 15 * 10**8;
    proposeDelay = 1;
    priceAggregator = priceAggregatorInterface(0x7196545d854D03D9c87B7588F6D9e1e42D876E95);
  }

  uint256 public constant uSmallFactor = 10**9;
  int256 public constant smallFactor = 10**9;

  uint256 public lossLimit;
  uint256 public kControl;
  priceAggregatorInterface public priceAggregator;
  address public priceAggregatorPropose;
  uint256 public priceAggregatorProposeTimestamp;

  uint256 public proposeDelay;
  uint256 public proposeDelayPropose;
  uint256 public proposeDelayTimestamp;

  /*
   * @notice Calculates the most recent price data.
   * @dev If there is no new price data it returns current price/equity data.
   * Safety checks are done by SynLev price aggregator. All calcualtions done
   * via equity in ETH, not price to avoid rounding errors. Caculates price
   * based on the "losing side", then subracts from the other. Mitigates a
   * prefrence in rounding error to either bull or bear tokens.
   */
  function getUpdatedPrice(address vault, uint256 latestRoundId)
  public
  view
  returns(
    uint256[6] memory latestPrice,
    uint256 rRoundId,
    bool updated
  ) {
    //Requests price data from price aggregator proxy
    (
      int256[] memory priceData,
      uint256 roundId
    ) = priceAggregator.priceRequest(vault, latestRoundId);
    vaultInterface ivault = vaultInterface(vault);
    address bull = ivault.getBullToken();
    address bear = ivault.getBearToken();
    uint256 bullEquity = ivault.getTokenEquity(bull);
    uint256 bearEquity = ivault.getTokenEquity(bear);
    //Only update if price data if price array contains 2 or more values
    //If there is no new price data pricedate array will have 0 length
    if(priceData.length > 0 && bullEquity != 0 && bearEquity != 0) {
      (uint256 rBullEquity, uint256 rBearEquity) = priceCalcLoop(priceData, bullEquity, bearEquity, ivault);
      uint256[6] memory data = equityToReturnData(bull, bear, rBullEquity, rBearEquity, ivault);
      return(data, roundId, true);
    }
    else {
      return(
        [ivault.getPrice(bull),
        ivault.getPrice(bear),
        ivault.getLiqEquity(bull),
        ivault.getLiqEquity(bear),
        ivault.getEquity(bull),
        ivault.getEquity(bear)],
        roundId,
        false
      );
    }
  }

  function priceCalcLoop(
    int256[] memory priceData,
    uint256 bullEquity,
    uint256 bearEquity,
    vaultInterface ivault
    )
    public
    view
    returns(uint256 rBullEquity, uint256 rBearEquity)
    {
      uint256 multiplier = ivault.getMultiplier();
      uint256 totalEquity = ivault.getTotalEquity();
      uint256 movement;
      uint256 bearKFactor;
      uint256 bullKFactor;
      int256  signedPriceDelta;
      uint256 pricedelta;
      for (uint i = 1; i < priceData.length; i++) {
        //Grab k factor based on running equity
        bullKFactor = getKFactor(bullEquity, bullEquity, bearEquity, totalEquity);
        bearKFactor = getKFactor(bearEquity, bullEquity, bearEquity, totalEquity);
        if(priceData[i-1] != priceData[i]) {
          //Bearish movement, calc equity from the perspective of bull
          if(priceData[i-1] > priceData[i]) {
            //Treats 0 price value as 1, 0 causes divides by 0 error
            if(priceData[i-1] == 0) priceData[i-1] = 1;
            //Gets price change in absolute terms.

            signedPriceDelta = priceData[i-1].sub(priceData[i]);
            signedPriceDelta = signedPriceDelta.mul(smallFactor);
            signedPriceDelta = signedPriceDelta.div(priceData[i-1]);
            pricedelta = uint256(signedPriceDelta);

            //Converts price change to be in terms of bull equity change
            //As a percentage
            pricedelta = pricedelta.mul(multiplier.mul(bullKFactor)).div(uSmallFactor);
            //Dont allow loss to be greater than set loss limit
            pricedelta = pricedelta < lossLimit ? pricedelta : lossLimit;
            //Calculate equity loss of bull equity
            movement = bullEquity.mul(pricedelta);
            movement = movement.div(uSmallFactor);
            //Adds equity movement to running bear euqity and removes that
            //Loss from running bull equity
            bearEquity = bearEquity.add(movement);
            bullEquity = totalEquity.sub(bearEquity);
          }
          //Bullish movement, calc equity from the perspective of bear
          //Same process as above. only from bear perspective
          else if(priceData[i-1] < priceData[i]) {
            if(priceData[i-1] == 0) priceData[i-1] = 1;

            signedPriceDelta = priceData[i].sub(priceData[i-1]);
            signedPriceDelta = signedPriceDelta.mul(smallFactor);
            signedPriceDelta = signedPriceDelta.div(priceData[i-1]);
            pricedelta = uint256(signedPriceDelta);

            pricedelta = pricedelta.mul(multiplier.mul(bearKFactor)).div(uSmallFactor);
            pricedelta = pricedelta < lossLimit ? pricedelta : lossLimit;
            movement = bearEquity.mul(pricedelta);
            movement = movement.div(uSmallFactor);
            bullEquity = bullEquity.add(movement);
            bearEquity = totalEquity.sub(bullEquity);
          }
        }
      }
      return(bullEquity, bearEquity);
  }

  function equityToReturnData(
    address bull,
    address bear,
    uint256 bullEquity,
    uint256 bearEquity,
    vaultInterface ivault
    )
    public
    view
    returns(uint256[6] memory)
  {
      uint256 bullPrice =
        bullEquity
        .mul(1 ether)
        .div(IERC20(bull).totalSupply().add(ivault.getLiqTokens(bull)));
      uint256 bearPrice =
        bearEquity
        .mul(1 ether)
        .div(IERC20(bear).totalSupply().add(ivault.getLiqTokens(bear)));
      uint256 bullLiqEquity =
        bullPrice
        .mul(ivault.getLiqTokens(bull))
        .div(1 ether);
      uint256 bearLiqEquity =
        bearPrice
        .mul(ivault.getLiqTokens(bear))
        .div(1 ether);

      return([
        bullPrice,
        bearPrice,
        bullLiqEquity,
        bearLiqEquity,
        bullEquity.sub(bullLiqEquity),
        bearEquity.sub(bearLiqEquity)
      ]);
  }


  /*
   * @notice Calculates k factor of selected token. K factor is the multiplier
   * that adjusts the leverage level to maintain 100% liquidty at all times.
   * @dev K factor is scaled 10^9. A K factor of 1 represents a 1:1 ratio of
   * bull and bear equity.
   * @param targetEquity The total euqity of the target bull token
   * @param bullEquity The total equity bull tokens
   * @param bearEquity The total equity bear tokens
   * @param totalEquity The total equity of bull and bear tokens
   * @return K factor
   */
  function getKFactor(
    uint256 targetEquity,
    uint256 bullEquity,
    uint256 bearEquity,
    uint256 totalEquity
  )
  public
  view
  returns(uint256) {
    //If either token has 0 equity k value is 0
    if(bullEquity  == 0 || bearEquity == 0) {
      return(0);
    }
    else {
      //Avoids divides by 0 error
      targetEquity = targetEquity > 0 ? targetEquity : 1;
      uint256 kFactor =
        totalEquity.mul(10**9).div(targetEquity.mul(2)) < kControl ?
        totalEquity.mul(10**9).div(targetEquity.mul(2)): kControl;
      return(kFactor);
    }
  }

  ///////////////////
  //ADMIN FUNCTIONS//
  ///////////////////
  function setLossLimit(uint256 amount) public onlyOwner() {
    lossLimit = amount;
  }
  function setkControl(uint256 amount) public onlyOwner() {
    kControl = amount;
  }
  function proposeVaultPriceAggregator(address account) public onlyOwner() {
    priceAggregatorPropose = account;
    priceAggregatorProposeTimestamp = block.timestamp;
  }
  function updateVaultPriceAggregator() public onlyOwner() {
    require(priceAggregatorPropose != address(0));
    require(priceAggregatorProposeTimestamp + proposeDelay <= block.timestamp);
    priceAggregator = priceAggregatorInterface(priceAggregatorPropose);
    priceAggregatorPropose = address(0);
  }

  function proposeProposeDelay(uint256 delay) public onlyOwner() {
    proposeDelayPropose = delay;
    proposeDelayTimestamp = block.timestamp;
  }
  function updateProposeDelay() public onlyOwner() {
    require(proposeDelayPropose != 0);
    require(proposeDelayTimestamp + proposeDelay <= block.timestamp);
    proposeDelay = proposeDelayPropose;
    proposeDelayPropose = 0;
  }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"},"SignedSafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}
"},"vaultInterface.sol":{"content":"pragma solidity >= 0.6.6;

interface vaultInterface {
  function tokenBuy(address token, address account) external;
  function tokenSell(address token, address payable account) external;
  function addLiquidity(address account) external;
  function removeLiquidity(uint256 shares) external;
  function updatePrice() external;

  function getActive() external view returns(bool);
  function getMultiplier() external view returns(uint256);
  function getBullToken() external view returns(address);
  function getBearToken() external view returns(address);
  function getLatestRoundId() external view returns(uint256);
  function getPrice(address token) external view returns(uint256);
  function getEquity(address token) external view returns(uint256);
  function getBuyFee() external view returns(uint256);
  function getSellFee() external view returns(uint256);
  function getTotalLiqShares() external view returns(uint256);
  function getLiqFees() external view returns(uint256);
  function getBalanceEquity() external view returns(uint256);
  function getLiqTokens(address token) external view returns(uint256);
  function getLiqEquity(address token) external view returns(uint256);
  function getUserShares(address account) external view returns(uint256);

  function getTotalEquity() external view returns(uint256);
  function getTokenEquity(address token) external view returns(uint256);
  function getTotalLiqEquity() external view returns(uint256);
  function getDepositEquity() external view returns(uint256);
}
"}}