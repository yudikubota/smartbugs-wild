{"EnumerableSet.sol":{"content":"// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/structs/EnumerableSet.sol@v4.0.0

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
"},"IERC20.sol":{"content":"pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}"},"Presale01.sol":{"content":"// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

/**
  Allows a decentralised presale to take place, and on success creates an AMM pair and locks liquidity on Unicrypt.
  B_TOKEN, or base token, is the token the presale attempts to raise. (Usally ETH).
  S_TOKEN, or sale token, is the token being sold, which investors buy with the base token.
  If the base currency is set to the WETH9 address, the presale is in ETH.
  Otherwise it is for an ERC20 token - such as DAI, USDC, WBTC etc.
  For the Base token - It is advised to only use tokens such as ETH (WETH), DAI, USDC or tokens that have no rebasing, or complex fee on transfers. 1 token should ideally always be 1 token.
  Token withdrawls are done on a percent of total contribution basis (opposed to via a hardcoded 'amount'). This allows 
  fee on transfer, rebasing, or any magically changing balances to still work for the Sale token.
*/

pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPresaleLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function uniswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getRound1Length () external view returns (uint256);
    function getRound0Offset () external view returns (uint256);
    function userHoldsSufficientRound1Token (address _user) external view returns (bool);
    function referrerIsValid(address _referrer) external view returns (bool);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getNonEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getReferralFee () external view returns (uint256);
    function getEthCreationFee () external view returns (uint256);
    function getUNCLInfo () external view returns (address, uint256, address);
}

contract Presale01 is ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
  uint16 public CONTRACT_VERSION = 5;
  
  struct PresaleInfo {
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of presale tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT; // divided by 1000
    uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
    uint256 START_BLOCK;
    uint256 END_BLOCK;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
  }

  struct PresaleInfo2 {
    address payable PRESALE_OWNER;
    bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
    uint16 COUNTRY_CODE;
    uint128 UNCL_MAX_PARTICIPANTS; // max number of UNCL reserve allocation participants
    uint128 UNCL_PARTICIPANTS; // number of uncl reserve allocation participants
  }
  
  struct PresaleFeeInfo {
    uint256 UNICRYPT_BASE_FEE; // divided by 1000
    uint256 UNICRYPT_TOKEN_FEE; // divided by 1000
    uint256 REFERRAL_FEE; // divided by 1000
    address payable REFERRAL_FEE_ADDRESS; // if this is not address(0), there is a valid referral
  }
  
  struct PresaleStatus {
    bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
    bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the presale
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
    uint256 ROUND1_LENGTH; // in blocks
    uint256 ROUND_0_START;
    uint256 NUM_BUYERS; // number of unique participants
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
    uint256 unclOwed; // num uncl owed if user used UNCL for pre-allocation
  }
  
  PresaleInfo public PRESALE_INFO;
  PresaleInfo2 public PRESALE_INFO_2;
  PresaleFeeInfo public PRESALE_FEE_INFO;
  PresaleStatus public STATUS;
  address public PRESALE_GENERATOR;
  IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
  IPresaleSettings public PRESALE_SETTINGS;
  address UNICRYPT_DEV_ADDRESS;
  IUniswapV2Factory public UNI_FACTORY;
  IWETH public WETH;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private WHITELIST;
  uint public UNCL_AMOUNT_OVERRIDE;
  uint public UNCL_BURN_ON_FAIL; // amount of UNCL to burn on failed presale

  constructor(address _presaleGenerator, IPresaleSettings _presaleSettings, address _weth) {
    PRESALE_GENERATOR = _presaleGenerator;
    PRESALE_SETTINGS = _presaleSettings;
    WETH = IWETH(_weth);
    UNI_FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(0xCA07E89e9674e9BC5bB9CaDE6771FEc8e14e4042);
    UNICRYPT_DEV_ADDRESS = 0xAA3d85aD9D128DFECb55424085754F6dFa643eb1;
  }
  
  function init1 (
    uint16 _countryCode,
    uint256 _amount,
    uint256 _tokenPrice,
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _roundZeroStart,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      PRESALE_INFO_2.COUNTRY_CODE = _countryCode;
      PRESALE_INFO.AMOUNT = _amount;
      PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
      PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      PRESALE_INFO.HARDCAP = _hardcap;
      PRESALE_INFO.SOFTCAP = _softcap;
      PRESALE_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      PRESALE_INFO.LISTING_RATE = _listingRate;
      PRESALE_INFO.START_BLOCK = _startblock;
      PRESALE_INFO.END_BLOCK = _endblock;
      PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
      PRESALE_INFO_2.UNCL_MAX_PARTICIPANTS = uint128(_hardcap / _maxEthPerBuyer / 2);
      if (_roundZeroStart < block.number + PRESALE_SETTINGS.getRound0Offset()) {
        STATUS.ROUND_0_START = block.number + PRESALE_SETTINGS.getRound0Offset();
      } else {
        STATUS.ROUND_0_START = _roundZeroStart;
      }

      if (PRESALE_INFO.START_BLOCK < STATUS.ROUND_0_START) {
        PRESALE_INFO.START_BLOCK = STATUS.ROUND_0_START + PRESALE_SETTINGS.getRound0Offset();
        PRESALE_INFO.END_BLOCK = PRESALE_INFO.START_BLOCK + (_endblock - _startblock);
      }
  }
  
  function init2 (
    address payable _presaleOwner,
    IERC20 _baseToken,
    IERC20 _presaleToken,
    uint256 _unicryptBaseFee,
    uint256 _unicryptTokenFee,
    uint256 _referralFee,
    address payable _referralAddress
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      PRESALE_INFO_2.PRESALE_OWNER = _presaleOwner;
      PRESALE_INFO_2.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
      PRESALE_INFO.S_TOKEN = _presaleToken;
      PRESALE_INFO.B_TOKEN = _baseToken;
      PRESALE_FEE_INFO.UNICRYPT_BASE_FEE = _unicryptBaseFee;
      PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE = _unicryptTokenFee;
      PRESALE_FEE_INFO.REFERRAL_FEE = _referralFee;
      
      PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS = _referralAddress;
      STATUS.ROUND1_LENGTH = PRESALE_SETTINGS.getRound1Length();
  }
  
  modifier onlyPresaleOwner() {
    require(PRESALE_INFO_2.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
    _;
  }

  function setUNCLAmount (uint _amount) external {
    require(msg.sender == UNICRYPT_DEV_ADDRESS, 'NOT DEV');
    UNCL_AMOUNT_OVERRIDE = _amount;
  }

  function getUNCLOverride () public view returns (address, uint256) {
    (address unclAddress, uint256 unclAmount,) = PRESALE_SETTINGS.getUNCLInfo();
    unclAmount = UNCL_AMOUNT_OVERRIDE == 0 ? unclAmount : UNCL_AMOUNT_OVERRIDE;
    return (unclAddress, unclAmount);
  }

  function getElapsedSinceRound1 () external view returns (int) {
    return int(block.number) - int(PRESALE_INFO.START_BLOCK);
  }

  function getElapsedSinceRound0 () external view returns (int) {
    return int(block.number) - int(STATUS.ROUND_0_START);
  }

  function getInfo () public view returns (uint16, PresaleInfo memory, PresaleInfo2 memory, PresaleFeeInfo memory, PresaleStatus memory, uint256) {
    return (CONTRACT_VERSION, PRESALE_INFO, PRESALE_INFO_2, PRESALE_FEE_INFO, STATUS, presaleStatus());
  }
  
  function presaleStatus () public view returns (uint256) {
    if (STATUS.LP_GENERATION_COMPLETE) {
      return 4; // FINALIZED - withdraws enabled and markets created
    }
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end block
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= PRESALE_INFO.START_BLOCK) && (block.number <= PRESALE_INFO.END_BLOCK)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }

  function reserveAllocationWithUNCL () external payable nonReentrant {
    require(presaleStatus() == 0, 'NOT QUED'); // ACTIVE
    require(block.number > STATUS.ROUND_0_START, 'NOT YET');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(buyer.unclOwed == 0, 'UNCL NOT ZERO');
    require(PRESALE_INFO_2.UNCL_PARTICIPANTS < PRESALE_INFO_2.UNCL_MAX_PARTICIPANTS, 'NO SLOT');
    (address unclAddress, uint256 unclAmount) = getUNCLOverride();
    TransferHelper.safeTransferFrom(unclAddress, msg.sender, address(this), unclAmount);
    uint256 unclToBurn = unclAmount / 4;
    UNCL_BURN_ON_FAIL += unclToBurn;
    buyer.unclOwed = unclAmount - unclToBurn;
    PRESALE_INFO_2.UNCL_PARTICIPANTS ++;
  }

  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable nonReentrant {
    if (presaleStatus() == 0) {
      require(BUYERS[msg.sender].unclOwed > 0, 'NOT RESERVED');
    } else {
      require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
      bool userHoldsUnicryptTokens = PRESALE_SETTINGS.userHoldsSufficientRound1Token(msg.sender);
      if (block.number < PRESALE_INFO.START_BLOCK + STATUS.ROUND1_LENGTH) { // 276 blocks = 1 hour
        require(userHoldsUnicryptTokens, 'INSUFFICENT ROUND 1 TOKEN BALANCE');
      }
    }
    _userDeposit(_amount);
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function _userDeposit (uint256 _amount) internal {
    // DETERMINE amount_in
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 amount_in = PRESALE_INFO_2.PRESALE_IN_ETH ? msg.value : _amount;
    uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER - buyer.baseDeposited;
    uint256 remaining;
    if (presaleStatus() == 0) {
      remaining = (PRESALE_INFO_2.UNCL_MAX_PARTICIPANTS * PRESALE_INFO.MAX_SPEND_PER_BUYER) - STATUS.TOTAL_BASE_COLLECTED;
    } else {
      remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    }
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }

    // UPDATE STORAGE
    uint256 tokensSold = amount_in * PRESALE_INFO.TOKEN_PRICE  / (10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }
    buyer.baseDeposited += amount_in;
    buyer.tokensOwed += tokensSold;
    STATUS.TOTAL_BASE_COLLECTED += amount_in;
    STATUS.TOTAL_TOKENS_SOLD += tokensSold;
    
    // FINAL TRANSFERS OUT AND IN
    // return unused ETH
    if (PRESALE_INFO_2.PRESALE_IN_ETH && amount_in < msg.value) {
      payable(msg.sender).transfer(msg.value - amount_in);
    }
    // deduct non ETH token from user
    if (!PRESALE_INFO_2.PRESALE_IN_ETH) {
      TransferHelper.safeTransferFrom(address(PRESALE_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
  }
  
  // withdraw presale tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 tokensRemainingDenominator = STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN;
    uint256 tokensOwed = PRESALE_INFO.S_TOKEN.balanceOf(address(this)) * buyer.tokensOwed / tokensRemainingDenominator;
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_TOKENS_WITHDRAWN += buyer.tokensOwed;
    buyer.tokensOwed = 0;
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(buyer.baseDeposited > 0 || buyer.unclOwed > 0, 'NOTHING TO WITHDRAW');
    if (buyer.baseDeposited > 0) {
      uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED - STATUS.TOTAL_BASE_WITHDRAWN;
      uint256 remainingBaseBalance = PRESALE_INFO_2.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
      uint256 tokensOwed = remainingBaseBalance * buyer.baseDeposited / baseRemainingDenominator;
      require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
      STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;
      buyer.baseDeposited = 0;
      TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), payable(msg.sender), tokensOwed, !PRESALE_INFO_2.PRESALE_IN_ETH);
    }
    if (buyer.unclOwed > 0) {
      (address unclAddress,,) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, payable(msg.sender), buyer.unclOwed);
      buyer.unclOwed = 0;
    }
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlyPresaleOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_INFO_2.PRESALE_OWNER, PRESALE_INFO.S_TOKEN.balanceOf(address(this)));
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on uniswap and it contains the presale token as liquidity 
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  /* function forceFailIfPairExists () external {
    require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
    if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
    }
  } */
  
  // if something goes wrong in LP generation
  function forceFailByUnicrypt () external {
      require(msg.sender == UNICRYPT_DEV_ADDRESS);
      require(!STATUS.FORCE_FAILED);
      STATUS.FORCE_FAILED = true;
      // send UNCL to uncl burn address
      (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, unclFeeAddress, UNCL_BURN_ON_FAIL);
  }

  // Allows the owner to end a presale before a pool has been created
  function forceFailByPresaleOwner () external onlyPresaleOwner {
      require(!STATUS.LP_GENERATION_COMPLETE, 'POOL EXISTS');
      require(!STATUS.FORCE_FAILED);
      STATUS.FORCE_FAILED = true;
      (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, unclFeeAddress, UNCL_BURN_ON_FAIL);
  }
  
  // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the presale parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    // require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(presaleStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the presale if the pair exists and contains presale token liquidity
    if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
    }
    
    uint256 unicryptBaseFee = STATUS.TOTAL_BASE_COLLECTED * PRESALE_FEE_INFO.UNICRYPT_BASE_FEE / 1000;
    
    // base token liquidity
    uint256 baseLiquidity = (STATUS.TOTAL_BASE_COLLECTED - unicryptBaseFee) * PRESALE_INFO.LIQUIDITY_PERCENT / 1000;
    if (PRESALE_INFO_2.PRESALE_IN_ETH) {
        WETH.deposit{value : baseLiquidity}();
    }
    TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity * PRESALE_INFO.LISTING_RATE / (10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER), tokenLiquidity);
    
    PRESALE_LOCK_FORWARDER.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO_2.PRESALE_OWNER);
    // transfer fees
    uint256 unicryptTokenFee = STATUS.TOTAL_TOKENS_SOLD * PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE / 1000;
    // referrals are checked for validity in the presale generator
    if (PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS != address(0)) {
        // Base token fee
        uint256 referralBaseFee = unicryptBaseFee * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS, referralBaseFee, !PRESALE_INFO_2.PRESALE_IN_ETH);
        unicryptBaseFee -= referralBaseFee;
        // Token fee
        uint256 referralTokenFee = unicryptTokenFee * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS, referralTokenFee);
        unicryptTokenFee -= referralTokenFee;
    }
    TransferHelper.safeTransferBaseToken(
      address(PRESALE_INFO.B_TOKEN), 
      PRESALE_INFO_2.PRESALE_IN_ETH ? PRESALE_SETTINGS.getEthAddress() : PRESALE_SETTINGS.getNonEthAddress(), 
      unicryptBaseFee, 
      !PRESALE_INFO_2.PRESALE_IN_ETH
    );
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_SETTINGS.getTokenAddress(), unicryptTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance - STATUS.TOTAL_TOKENS_SOLD;
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), 0x000000000000000000000000000000000000dEaD, burnAmount);
    }
    
    // send remaining base tokens to presale owner
    uint256 remainingBaseBalance = PRESALE_INFO_2.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_INFO_2.PRESALE_OWNER, remainingBaseBalance, !PRESALE_INFO_2.PRESALE_IN_ETH);

    // send UNCL to uncl burn address
    (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
    TransferHelper.safeTransfer(unclAddress, unclFeeAddress, IERC20(unclAddress).balanceOf(address(this)));
    
    STATUS.LP_GENERATION_COMPLETE = true;
  }
  
  // postpone or bring a presale forward, this will only work when a presale is inactive.
  // i.e. current start block > block.number
  function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyPresaleOwner {
    require(presaleStatus() == 0 && _startBlock > STATUS.ROUND_0_START + PRESALE_SETTINGS.getRound0Offset(), 'UB1');
    require(_endBlock - _startBlock <= PRESALE_SETTINGS.getMaxPresaleLength(), 'UB2');
    PRESALE_INFO.START_BLOCK = _startBlock;
    PRESALE_INFO.END_BLOCK = _endBlock;
  }
}"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.0.0

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
"},"TransferHelper.sol":{"content":"pragma solidity ^0.8.0;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}"}}