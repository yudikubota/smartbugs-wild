{{
  "language": "Solidity",
  "sources": {
    "contracts/OKLGDividendDistributor.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IConditional.sol';
import './interfaces/IMultiplier.sol';
import './OKLGWithdrawable.sol';

contract OKLGDividendDistributor is OKLGWithdrawable {
  using SafeMath for uint256;

  struct Dividend {
    uint256 totalExcluded; // excluded dividend
    uint256 totalRealised;
    uint256 lastClaim; // used for boosting logic
  }

  address public shareholderToken;
  uint256 public totalSharesDeposited; // will only be actual deposited tokens without handling any reflections or otherwise
  address wrappedNative;
  IUniswapV2Router02 router;

  // used to fetch in a frontend to get full list
  // of tokens that dividends can be claimed
  address[] public tokens;
  mapping(address => bool) tokenAwareness;

  mapping(address => uint256) shareholderClaims;

  // amount of shares a user has
  mapping(address => uint256) public shares;
  // dividend information per user
  mapping(address => mapping(address => Dividend)) public dividends;

  address public boostContract;
  address public boostMultiplierContract;
  uint256 public floorBoostClaimTimeSeconds = 60 * 60 * 12;
  uint256 public ceilBoostClaimTimeSeconds = 60 * 60 * 24;

  // per token dividends
  mapping(address => uint256) public totalDividends;
  mapping(address => uint256) public totalDistributed; // to be shown in UI
  mapping(address => uint256) public dividendsPerShare;

  uint256 public constant ACC_FACTOR = 10**36;
  address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

  constructor(
    address _dexRouter,
    address _shareholderToken,
    address _wrappedNative
  ) {
    router = IUniswapV2Router02(_dexRouter);
    shareholderToken = _shareholderToken;
    wrappedNative = _wrappedNative;
  }

  function stake(address token, uint256 amount) external {
    _stake(msg.sender, token, amount, false);
  }

  function _stake(
    address shareholder,
    address token,
    uint256 amount,
    bool contractOverride
  ) private {
    if (shares[shareholder] > 0 && !contractOverride) {
      distributeDividend(token, shareholder, false);
    }

    IERC20 shareContract = IERC20(shareholderToken);
    uint256 stakeAmount = amount == 0
      ? shareContract.balanceOf(shareholder)
      : amount;

    // for compounding we will pass in this contract override flag and assume the tokens
    // received by the contract during the compounding process are already here, therefore
    // whatever the amount is passed in is what we care about and leave it at that. If a normal
    // staking though by a user, transfer tokens from the user to the contract.
    uint256 finalAmount = amount;
    if (!contractOverride) {
      uint256 shareBalanceBefore = shareContract.balanceOf(address(this));
      shareContract.transferFrom(shareholder, address(this), stakeAmount);
      finalAmount = shareContract.balanceOf(address(this)).sub(
        shareBalanceBefore
      );
    }

    totalSharesDeposited = totalSharesDeposited.add(finalAmount);
    shares[shareholder] += finalAmount;
    dividends[shareholder][token].totalExcluded = getCumulativeDividends(
      token,
      shares[shareholder]
    );
  }

  function unstake(address token, uint256 amount) external {
    require(
      shares[msg.sender] > 0 && (amount == 0 || shares[msg.sender] <= amount),
      'you can only unstake if you have some staked'
    );
    distributeDividend(token, msg.sender, false);

    IERC20 shareContract = IERC20(shareholderToken);

    // handle reflections tokens
    uint256 baseWithdrawAmount = amount == 0 ? shares[msg.sender] : amount;
    uint256 totalSharesBalance = shareContract.balanceOf(address(this)).sub(
      totalDividends[shareholderToken].sub(totalDistributed[shareholderToken])
    );
    uint256 appreciationRatio18 = totalSharesBalance.mul(10**18).div(
      totalSharesDeposited
    );
    uint256 finalWithdrawAmount = baseWithdrawAmount
      .mul(appreciationRatio18)
      .div(10**18);

    shareContract.transfer(msg.sender, finalWithdrawAmount);
    totalSharesDeposited = totalSharesDeposited.sub(baseWithdrawAmount);
    shares[msg.sender] -= baseWithdrawAmount;
    dividends[msg.sender][token].totalExcluded = getCumulativeDividends(
      token,
      shares[msg.sender]
    );
  }

  // tokenAddress == address(0) means native token
  // any other token should be ERC20 listed on DEX router provided in constructor
  //
  // NOTE: Using this function will add tokens to the core rewards/dividends to be
  // distributed to all shareholders. However, to implement boosting, the token
  // should be directly transferred to this contract. Anything above and
  // beyond the totalDividends[tokenAddress] amount will be used for boosting.
  function depositDividends(address tokenAddress, uint256 erc20DirectAmount)
    external
    payable
  {
    require(
      erc20DirectAmount > 0 || msg.value > 0,
      'value must be greater than 0'
    );
    require(
      totalSharesDeposited > 0,
      'must be shares deposited to be rewarded dividends'
    );

    if (!tokenAwareness[tokenAddress]) {
      tokenAwareness[tokenAddress] = true;
      tokens.push(tokenAddress);
    }

    IERC20 token;
    uint256 amount;
    if (tokenAddress == address(0)) {
      payable(address(this)).call{ value: msg.value }('');
      amount = msg.value;
    } else if (erc20DirectAmount > 0) {
      token = IERC20(tokenAddress);
      uint256 balanceBefore = token.balanceOf(address(this));

      token.transferFrom(msg.sender, address(this), erc20DirectAmount);

      amount = token.balanceOf(address(this)).sub(balanceBefore);
    } else {
      token = IERC20(tokenAddress);
      uint256 balanceBefore = token.balanceOf(address(this));

      address[] memory path = new address[](2);
      path[0] = wrappedNative;
      path[1] = tokenAddress;

      router.swapExactETHForTokensSupportingFeeOnTransferTokens{
        value: msg.value
      }(0, path, address(this), block.timestamp);

      amount = token.balanceOf(address(this)).sub(balanceBefore);
    }

    totalDividends[tokenAddress] = totalDividends[tokenAddress].add(amount);
    dividendsPerShare[tokenAddress] = dividendsPerShare[tokenAddress].add(
      ACC_FACTOR.mul(amount).div(totalSharesDeposited)
    );
  }

  function distributeDividend(
    address token,
    address shareholder,
    bool compound
  ) internal {
    if (shares[shareholder] == 0) {
      return;
    }

    uint256 amount = getUnpaidEarnings(token, shareholder);
    if (amount > 0) {
      totalDistributed[token] = totalDistributed[token].add(amount);
      // native transfer
      if (token == address(0)) {
        if (compound) {
          IERC20 shareToken = IERC20(shareholderToken);
          uint256 balBefore = shareToken.balanceOf(address(this));
          address[] memory path = new address[](2);
          path[0] = wrappedNative;
          path[1] = shareholderToken;
          router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
          }(0, path, address(this), block.timestamp);
          uint256 amountReceived = shareToken.balanceOf(address(this)).sub(
            balBefore
          );
          if (amountReceived > 0) {
            _stake(shareholder, token, amountReceived, true);
          }
        } else {
          payable(shareholder).call{ value: amount }('');
        }
      } else {
        IERC20(token).transfer(shareholder, amount);
      }

      _payBoostedRewards(token, shareholder);

      shareholderClaims[shareholder] = block.timestamp;
      dividends[shareholder][token].totalRealised = dividends[shareholder][
        token
      ].totalRealised.add(amount);
      dividends[shareholder][token].totalExcluded = getCumulativeDividends(
        token,
        shares[shareholder]
      );
      dividends[shareholder][token].lastClaim = block.timestamp;
    }
  }

  function _payBoostedRewards(address token, address shareholder) internal {
    bool canCurrentlyClaim = canClaimBoostedRewards(token, shareholder) &&
      eligibleForRewardBooster(shareholder);
    if (!canCurrentlyClaim) {
      return;
    }

    uint256 amount = calculateBoostRewards(token, shareholder);
    if (amount > 0) {
      if (token == address(0)) {
        payable(shareholder).call{ value: amount }('');
      } else {
        IERC20(token).transfer(shareholder, amount);
      }
    }
  }

  function claimDividend(address token, bool compound) external {
    distributeDividend(token, msg.sender, compound);
  }

  function canClaimBoostedRewards(address token, address shareholder)
    public
    view
    returns (bool)
  {
    return
      dividends[shareholder][token].lastClaim == 0 ||
      (block.timestamp >
        dividends[shareholder][token].lastClaim.add(
          floorBoostClaimTimeSeconds
        ) &&
        block.timestamp <=
        dividends[shareholder][token].lastClaim.add(ceilBoostClaimTimeSeconds));
  }

  function getDividendTokens() external view returns (address[] memory) {
    return tokens;
  }

  function getBoostMultiplier(address wallet) public view returns (uint256) {
    return
      boostMultiplierContract == address(0)
        ? 0
        : IMultiplier(boostMultiplierContract).getMultiplier(wallet);
  }

  function calculateBoostRewards(address token, address shareholder)
    public
    view
    returns (uint256)
  {
    // use the token circulating supply for boosting rewards since that's
    // how the calculation has been done thus far and we want the boosted
    // rewards to have some longevity.
    IERC20 shareToken = IERC20(shareholderToken);
    uint256 totalCirculatingShareTokens = shareToken.totalSupply() -
      shareToken.balanceOf(DEAD);
    uint256 availableBoostRewards = address(this).balance;
    if (token != address(0)) {
      availableBoostRewards = IERC20(token).balanceOf(address(this));
    }
    uint256 excluded = totalDividends[token].sub(totalDistributed[token]);
    uint256 finalAvailableBoostRewards = availableBoostRewards.sub(excluded);
    uint256 userShareBoostRewards = finalAvailableBoostRewards
      .mul(shares[shareholder])
      .div(totalCirculatingShareTokens);

    uint256 rewardsWithBooster = eligibleForRewardBooster(shareholder)
      ? userShareBoostRewards.add(
        userShareBoostRewards.mul(getBoostMultiplier(shareholder)).div(10**2)
      )
      : userShareBoostRewards;
    return
      rewardsWithBooster > finalAvailableBoostRewards
        ? finalAvailableBoostRewards
        : rewardsWithBooster;
  }

  function eligibleForRewardBooster(address shareholder)
    public
    view
    returns (bool)
  {
    return
      boostContract != address(0) &&
      IConditional(boostContract).passesTest(shareholder);
  }

  // returns the unpaid earnings
  function getUnpaidEarnings(address token, address shareholder)
    public
    view
    returns (uint256)
  {
    if (shares[shareholder] == 0) {
      return 0;
    }

    uint256 earnedDividends = getCumulativeDividends(
      token,
      shares[shareholder]
    );
    uint256 dividendsExcluded = dividends[shareholder][token].totalExcluded;
    if (earnedDividends <= dividendsExcluded) {
      return 0;
    }

    return earnedDividends.sub(dividendsExcluded);
  }

  function getCumulativeDividends(address token, uint256 share)
    internal
    view
    returns (uint256)
  {
    return share.mul(dividendsPerShare[token]).div(ACC_FACTOR);
  }

  function setShareholderToken(address _token) external onlyOwner {
    shareholderToken = _token;
  }

  function setBoostClaimTimeInfo(uint256 floor, uint256 ceil)
    external
    onlyOwner
  {
    floorBoostClaimTimeSeconds = floor;
    ceilBoostClaimTimeSeconds = ceil;
  }

  function setBoostContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IConditional _contCheck = IConditional(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.passesTest(address(0)) == true ||
          _contCheck.passesTest(address(0)) == false,
        'contract does not implement interface'
      );
    }
    boostContract = _contract;
  }

  function setBoostMultiplierContract(address _contract) external onlyOwner {
    if (_contract != address(0)) {
      IMultiplier _contCheck = IMultiplier(_contract);
      // allow setting to zero address to effectively turn off check logic
      require(
        _contCheck.getMultiplier(address(0)) >= 0,
        'contract does not implement interface'
      );
    }
    boostMultiplierContract = _contract;
  }

  receive() external payable {}
}
"
    },
    "@openzeppelin/contracts/utils/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
"
    },
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol": {
      "content": "pragma solidity >=0.6.2;

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
"
    },
    "contracts/interfaces/IConditional.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface for the Buy Back Reward contract that can be used to build
 * custom logic to elevate user rewards
 */
interface IConditional {
  /**
   * @dev Returns whether a wallet passes the test.
   */
  function passesTest(address wallet) external view returns (bool);
}
"
    },
    "contracts/interfaces/IMultiplier.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMultiplier {
  function getMultiplier(address wallet) external view returns (uint256);
}
"
    },
    "contracts/OKLGWithdrawable.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }
}
"
    },
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol": {
      "content": "pragma solidity >=0.6.2;

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
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
"
    },
    "@openzeppelin/contracts/interfaces/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"
    }
  },
  "settings": {
    "metadata": {
      "bytecodeHash": "none"
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
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}