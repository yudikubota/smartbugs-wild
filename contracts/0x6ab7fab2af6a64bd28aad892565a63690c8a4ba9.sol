{"AggregatorV3Interface.sol":{"content":"// SPDX-License-Identifier: MIT
// Source: https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
"},"Helpers.sol":{"content":"// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import './SafeMath.sol';

library Helpers {
    using SafeMath for uint256;

    /**
     * @param number number to get percentage of
     * @param percent percentage (8 decimals)
     * @return The percentage of the number
     */
    function percentageOf(uint256 number, uint256 percent) internal pure returns (uint256) {
        return number.mul(percent).div(100000000);
    }

    /**
     * @param keccak keccak256 hash to use
     * @return The referral code
     */
    function keccak256ToReferralCode(bytes32 keccak) internal pure returns (bytes3) {
        bytes3 code;
        for (uint8 i = 0; i < 3; ++i) {
            code |= bytes3(keccak[i]) >> (i * 8);
        }
        return code;
    }

}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"},"Wallet.sol":{"content":"// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import './SafeMath.sol';
import './Helpers.sol';

struct Buyer {
    uint256 eth; // Amount of sent ETH
    uint256 zapp; // Amount of bought ZAPP
}

struct EarlyAdopter {
    uint256 zapp; // Early adopter purchase amount
}

struct Referrer {
    bytes3 code; // Referral code
    uint256 time; // Time of code generation
    Referee[] referrals; // List of referrals
}

struct Referee {
    uint256 zapp; // Purchase amount
}

struct Hunter {
    bool verified; // Verified by Zappermint (after Token Sale)
    uint256 bonus; // Bounty bonus (after Token Sale)
}

struct Wallet {
    address payable addr; // Address of the wallet

    Buyer buyer; // Buyer data
    bool isBuyer; // Whether this wallet is a buyer
    
    EarlyAdopter earlyAdopter; // Early adopter data
    bool isEarlyAdopter; // Whether this wallet is an early adopter
    
    Referrer referrer; // Referrer data
    bool isReferrer; // Whether this wallet is a referrer
    
    Referee referee; // Referee data
    bool isReferee; // Whether this wallet is a referee
    
    Hunter hunter; // Hunter data
    bool isHunter; // Whether this wallet is a hunter
    
    bool claimed; // Whether ZAPP has been claimed
}

/**
 * Functionality for the Wallet struct
 */
library WalletInterface {
    using SafeMath for uint256;

    /**
     * @param self the wallet
     * @param referrerMin the minimum amount of ZAPP that has to be bought to be a referrer (for hunters)
     * @param checkVerified whether to check if the hunter is verified (set to false to show progress during token sale)
     * @return The amount of ZAPP bits that have been bought with the referrer's code (18 decimals)
     */
    function calculateReferredAmount(Wallet storage self, uint256 referrerMin, bool checkVerified) internal view returns (uint256) {
        // 0 if not a referrer
        if (!self.isReferrer) return 0;

        // 0 if unverified hunter without enough bought ZAPP
        if (checkVerified && self.isHunter && !self.hunter.verified && self.buyer.zapp < referrerMin) return 0;

        // Calculate the sum of all referrals
        uint256 amount = 0;
        for (uint256 i = 0; i < self.referrer.referrals.length; ++i) {
            amount = amount.add(self.referrer.referrals[i].zapp);
        }
        return amount;
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @return The amount of ZAPP bits the early adopter will get as bonus (18 decimals)
     */
    function getEarlyAdopterBonus(Wallet storage self, uint256 bonus) internal view returns (uint256) {
        if (!self.isEarlyAdopter) return 0;
        return Helpers.percentageOf(self.earlyAdopter.zapp, bonus);
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @param referrerMin the minimum amount of ZAPP a referrer must have bought to be eligible (18 decimals)
     * @param checkVerified whether to check if the hunter is verified
     * @return The amount of ZAPP bits the referrer will get as bonus (18 decimals)
     */
    function getReferrerBonus(Wallet storage self, uint256 bonus, uint256 referrerMin, bool checkVerified) internal view returns (uint256) {
        if (!self.isReferrer) return 0;
        return Helpers.percentageOf(calculateReferredAmount(self, referrerMin, checkVerified), bonus);
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @return The amount of ZAPP bits the referee will get as bonus (18 decimals)
     */
    function getRefereeBonus(Wallet storage self, uint256 bonus) internal view returns (uint256) {
        if (!self.isReferee) return 0;
        return Helpers.percentageOf(self.referee.zapp, bonus);
    }

    /**
     * @param self the wallet
     * @param checkVerified whether to check if the hunter is verified
     * @return The amount of ZAPP bits the hunter will get as bonus (18 decimals)
     */
    function getHunterBonus(Wallet storage self, bool checkVerified) internal view returns (uint256) {
        if (!self.isHunter) return 0;
        if (checkVerified && !self.hunter.verified) return 0;
        return self.hunter.bonus;
    }

    /**
     * @param self the wallet
     * @return The amount of ZAPP bits the buyer has bought (18 decimals)
     */
    function getBuyerZAPP(Wallet storage self) internal view returns (uint256) {
        if (!self.isBuyer) return 0;
        return self.buyer.zapp;
    }

    /**
     * Makes a purchase for the wallet
     * @param self the wallet
     * @param eth amount of sent ETH (18 decimals)
     * @param zapp amount of bought ZAPP (18 decimals)
     */
    function purchase(Wallet storage self, uint256 eth, uint256 zapp) internal {
        // Become buyer
        self.isBuyer = true;
        // Add ETH to buyer data
        self.buyer.eth = self.buyer.eth.add(eth);
        // Add ZAPP to buyer data
        self.buyer.zapp = self.buyer.zapp.add(zapp);
    } 

    /**
     * Adds early adoption bonus
     * @param self the wallet
     * @param zapp amount of bought ZAPP (18 decimals)
     * NOTE Doesn't check for early adoption end time
     */
    function earlyAdoption(Wallet storage self, uint256 zapp) internal {
        // Become early adopter
        self.isEarlyAdopter = true;
        // Add ZAPP to early adopter data
        self.earlyAdopter.zapp = self.earlyAdopter.zapp.add(zapp);
    }

    /**
     * Adds referral bonuses
     * @param self the wallet
     * @param zapp amount of bought ZAPP (18 decimals)
     * @param referrer referrer wallet
     * NOTE Doesn't check for minimum purchase amount
     */
    function referral(Wallet storage self, uint256 zapp, Wallet storage referrer) internal {
        // Become referee
        self.isReferee = true;
        // Add ZAPP to referee data
        self.referee.zapp = self.referee.zapp.add(zapp);
        // Add referral to referrer
        referrer.referrer.referrals.push(Referee(zapp));
    }

    /**
     * Register as hunter
     * @param self the wallet
     */
    function register(Wallet storage self, uint256 reward, mapping(bytes3 => address) storage codes) internal {
        // Become hunter
        self.isHunter = true;
        // Set initial bonus to the register reward
        self.hunter.bonus = reward;
        // Become referrer
        self.isReferrer = true;
        // Generate referral code
        generateReferralCode(self, codes);
    }

    /**
     * Verify hunter and add his rewards
     * @param self the wallet
     * @param bonus hunted bounties
     * NOTE Also becomes a hunter, even if unregistered
     */
    function verify(Wallet storage self, uint256 bonus) internal {
        // Become hunter
        self.isHunter = true;
        // Set data
        self.hunter.verified = true;
        self.hunter.bonus = self.hunter.bonus.add(bonus);
    }

    /**
     * Generates a new code to assign to the referrer
     * @param self the wallet
     * @param codes the code map to check for duplicates
     * @return Unique referral code
     */
    function generateReferralCode(Wallet storage self, mapping(bytes3 => address) storage codes) internal returns (bytes3) {
        // Only on referrers
        if (!self.isReferrer) return bytes3(0);

        // Only generate once
        if (self.referrer.code != bytes3(0)) return self.referrer.code;

        bytes memory enc = abi.encodePacked(self.addr);
        bytes3 code = bytes3(0);
        while (true) {
            bytes32 keccak = keccak256(enc);
            code = Helpers.keccak256ToReferralCode(keccak);
            if (code != bytes3(0) && codes[code] == address(0)) break;
            // If the code already exists, we hash the hash to generate a new code
            enc = abi.encodePacked(keccak);
        }

        // Save the code for the referrer and in the code map to avoid duplicates
        self.referrer.code = code;
        self.referrer.time = block.timestamp;
        codes[code] = self.addr;
        return code;
    }

}"},"ZappermintTokenSale.sol":{"content":"// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import './SafeMath.sol';
import './AggregatorV3Interface.sol';
import './Wallet.sol';

// Crowdsale contract for ZAPP. Functionalities:
// - Timed: opens Jan 14, 2021, 6:00:00PM UTC (1610647200) and closes Feb 14, 2021, 6:00:00PM UTC (1613325600)
// - Capped: soft cap of 6M ZAPP, hard cap of 120M ZAPP
// - Refundable: ETH can be refunded if soft cap hasn't been reached
// - Post Delivery: ZAPP can be claimed after Token Sale end, if soft cap has been reached
// - Early Adopter: Bonus ZAPP for a set duration
// - Referral System: Bonus ZAPP when buying with referral link
contract ZappermintTokenSale {
    using SafeMath for uint256; // Avoid overflow issues
    using WalletInterface for Wallet; // Wallet functionality

// ----
// Variables
// ----

    // Token Sale configuration
    uint256 private _openingTime; // Start of Token Sale
    uint256 private _closingTime; // End of Token Sale
    uint256 private _claimTime; // Claim opening time
    uint256 private _softCap; // Minimum amount of ZAPP to sell (18 decimals)
    uint256 private _hardCap; // Maximum amount of ZAPP to sell (18 decimals)
    uint256 private _ethPrice; // Fallback ETH/USD price in case ChainLink breaks (8 decimals)
    uint256 private _zappPrice; // ZAPP/USD price (8 decimals)
    address private _zappContract; // Zappermint Token Contract
    address private _owner; // Owner of the contract
    
    // Wallets
    mapping(address => Wallet) private _wallets; // Addresses that have interacted with the Token Sale
    address[] _walletKeys; // Address list, for iterating over `_wallets`

    // Early Adopters
    uint256 private _earlyAdoptionEndTime; // End of early adoption bonus
    uint256 private _earlyAdoptionBonus; // Percentage of purchase to receive as bonus (8 decimals)

    // Referrals
    uint256 private _referrerMin; // Referrer minimum ZAPP bits (18 decimals)
    uint256 private _refereeMin; // Referee minimum ZAPP bits (18 decimals)
    uint256 private _referralBonus; // Percentage of purchase to receive as bonus (8 decimals)
    uint256[5] private _rankRewards; // Referrer rank reward list
    mapping(bytes3 => address) private _codes; // Referral codes
    
    // Bounty Hunters
    address[] _registeredHunters; // Registered hunter list
    uint256 private _maxHunters; // Maximum amount of registered bounty hunters
    uint256 private _registerBonus; // Bonus for registering as bounty hunter

    // Token Sale progress
    uint256 private _soldZAPP; // Amount of ZAPP sold (18 decimals)
    bool private _ended; // Whether the Token Sale has ended

    // Third party
    AggregatorV3Interface private _priceFeed; // ChainLink ETH/USD Price Feed

// ----
// Modifiers
// ----

    /**
     * Only allow function with this modifier to run while the Token Sale is open
     */
    modifier whileOpen {
        require(isOpen(), "Token Sale not open");
        _;
    }

    /**
     * Only allow function with this modifier to run while the Token Sale is not closed
     * NOTE The difference with whileOpen is that this returns true also before Token Sale opens
     */
    modifier whileNotClosed {
        require(!isClosed(), "Token Sale closed");
        _;
    }

    /**
     * Only allow function with this modifier to run while the claims are open
     */
    modifier whileClaimable {
        require(isClaimable(), "ZAPP can't be claimed yet");
        _;
    }

    /**
     * Only allow function with this modifier to run after the Token Sale has ended
     */
    modifier afterEnd {
        require(_ended, "Token Sale not ended");
        _;
    }

    /**
     * Only allow function with this modifier to run before the Token Sale has ended
     */
    modifier beforeEnd {
        require(!_ended, "Token Sale ended");
        _;
    }

    /**
     * Only allow function with this modifier to run when the Token Sale has reached the soft cap
     */
    modifier aboveSoftCap {
        require(isSoftCapReached(), "Token Sale hasn't reached soft cap");
        _;
    }

    /**
     * Only allow function with this modifier to run when the Token Sale hasn't reached the soft cap
     */
    modifier belowSoftCap {
        require(!isSoftCapReached(), "Token Sale reached soft cap");
        _;
    }

    /**
     * Only allow function with this modifier to be run by the Zappermint Token Contract
     */
    modifier onlyZAPPContract {
        require(msg.sender == _zappContract, "Only the Zappermint Token Contract can do this");
        _;
    }

    /**
     * Only allow function with this modifier to be run by the owner
     */
    modifier onlyOwner {
        require(msg.sender == _owner, "Only the owner can do this");
        _;
    }

// ----
// Constructor
// ----

    /**
     * Solves the Stack too deep error for the constructor
     * @param openingTime start time of the Token Sale (epoch)
     * @param closingTime end time of the Token Sale (epoch)
     * @param claimTime claim opening time (epoch)
     * @param softCap minimum amount of ZAPP to sell (18 decimals)
     * @param hardCap maximum amount of ZAPP to sell (18 decimals)
     * @param ethPrice price of 1 ETH in USD (8 decimals) to use in case ChainLink breaks
     * @param zappPrice price of 1 ZAPP in USD (8 decimals)
     * @param referrerMin minimum amount of ZAPP referrer must have purchased before getting a referral link (18 decimals)
     * @param refereeMin minimum amount of ZAPP referee must purchase to get referral bonus (18 decimals)
     * @param referralBonus percentage of purchase to receive as bonus (8 decimals)
     * @param rankRewards referrer rank reward list
     * @param earlyAdoptionEndTime end of early adoption bonus
     * @param earlyAdoptionBonus percentage of purchase to receive as bonus (8 decimals)
     * @param maxHunters maximum amount of bounty hunters
     * @param registerBonus bonus for registering as bounty hunter
     * @param aggregator address of ChainLink Aggregator price feed
     */
    struct ContractArguments {
        uint256 openingTime;
        uint256 closingTime; 
        uint256 claimTime;
        uint256 softCap;
        uint256 hardCap;
        uint256 ethPrice;
        uint256 zappPrice;
        uint256 referrerMin;
        uint256 refereeMin;
        uint256 referralBonus;
        uint256[5] rankRewards;
        uint256 earlyAdoptionEndTime;
        uint256 earlyAdoptionBonus;
        uint256 maxHunters;
        uint256 registerBonus;
        address aggregator;
    }

    constructor(ContractArguments memory args) {
        require(args.openingTime >= block.timestamp, "Opening time is before current time");
        require(args.closingTime > args.openingTime, "Opening time is not before closing time");
        require(args.claimTime >= args.closingTime, "Claiming time is not after closing time");
        require(args.softCap < args.hardCap, "Hard cap is below soft cap");

        _openingTime = args.openingTime;
        _closingTime = args.closingTime;
        _claimTime = args.claimTime;
        _softCap = args.softCap;
        _hardCap = args.hardCap;
        _ethPrice = args.ethPrice;
        _zappPrice = args.zappPrice;
        _referrerMin = args.referrerMin;
        _refereeMin = args.refereeMin;
        _referralBonus = args.referralBonus;
        _rankRewards = args.rankRewards;
        _earlyAdoptionEndTime = args.earlyAdoptionEndTime;
        _earlyAdoptionBonus = args.earlyAdoptionBonus;
        _maxHunters = args.maxHunters;
        _registerBonus = args.registerBonus;
        _priceFeed = AggregatorV3Interface(args.aggregator);

        _owner = msg.sender;
    }

// ----
// Getters
// ----

    /**
     * @return Token Sale opening time
     */
    function getOpeningTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return Whether Token Sale is open
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime && !_ended;
    }    

    /**
     * @return Token Sale closing time
     */
    function getClosingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return Whether Token Sale is closed
     */
    function isClosed() public view returns (bool) {
        return block.timestamp > _closingTime || _ended;
    }

    /**
     * @return Whether the Token Sale has been ended by the owner
     */
    function isEnded() public view returns (bool) {
        return _ended;
    }

    /**
     * @return Early adoption end time
     */
    function getEarlyAdoptionEndTime() public view returns (uint256) {
        return _earlyAdoptionEndTime;
    }

    /**
     * @return Whether the early adoption is active
     */
    function isEarlyAdoptionActive() public view returns (bool) {
        return block.timestamp <= _earlyAdoptionEndTime;
    }

    /**
     * @return Percentage of purchase to receive as bonus during early adoption (8 decimals)
     */
    function getEarlyAdoptionBonus() public view returns (uint256) {
        return _earlyAdoptionBonus;
    }

    /**
     * @return The claim opening time
     */
    function getClaimTime() public view returns (uint256) {
        return _claimTime;
    }

    /**
     * @return Whether the ZAPP can be claimed
     */
    function isClaimable() public view returns (bool) {
        return block.timestamp >= _claimTime && _ended && _zappContract != address(0);
    }

    /**
     * @return The minimum amount of ZAPP to sell (18 decimals)
     */
    function getSoftCap() public view returns (uint256) {
        return _softCap;
    }

    /**
     * @return Whether the soft cap has been reached
     */
    function isSoftCapReached() public view returns (bool) {
        return _soldZAPP >= _softCap;
    }

    /**
     * @return The maximum amount of ZAPP to sell (18 decimals)
     */
    function getHardCap() public view returns (uint256) {
        return _hardCap;
    }

    /** 
     * @return Whether the hard cap has been reached
     */
    function isHardCapReached() public view returns (bool) {
        return _soldZAPP >= _hardCap;
    }

    /**
     * @return The total amount of ZAPP sold so far (18 decimals)
     */
    function getSoldZAPP() public view returns (uint256) {
        return _soldZAPP;    
    }

    /**
     * @return The current number of ZAPP a buyer gets per 1 ETH
     * NOTE Based on ETH/USD pair. 1 ZAPP = 0.05 USD
     */
    function getRate() public view returns (uint256) {
        return getLatestPrice().div(_zappPrice); // 8 decimals
    }

    /**
     * @return The price of 1 ETH in USD. Attempts using ChainLink Aggregator, falls back to `_ethPrice` if broken.
     * NOTE 8 decimals
     */
    function getLatestPrice() public view returns (uint256) {
        // Try/catch only works on external function calls. `this.f()` uses a message call instead of a direct jump, 
        //   which is considered external.
        //   https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls
        // Note when ChainLink is broken, this will log an internal `revert` error, but the code will complete successfully
        try this.getChainlinkPrice() returns (uint256 price) {
            return price;
        }
        catch {
            return _ethPrice;
        }
    }

    /**
     * @return The price of 1 ETH in USD (from ChainLink Aggregator) 
     * NOTE 8 decimals
     */
    function getChainlinkPrice() public view returns (uint256) {
        // Get the ETH/USD price from ChainLink's Aggregator
        (,int256 p,,,) = _priceFeed.latestRoundData();
        
        // This price is a signed int, so make sure it's higher than 0
        require(p > 0, "Price feed invalid");

        // We can now safely cast it to unsigned int and use SafeMath on it
        uint256 price = uint256(p);

        // Verify the number of decimals. We work with 8 decimals for USD prices, 
        //   but ChainLink can choose to change this at any point outside of our control.
        // We ensure that the price has 8 decimals with the math below.
        // Note that the exponent must be positive, so we use div instead of mul in case
        //   the number of decimals is smaller than 8.
        uint8 decimals = _priceFeed.decimals();
        if (decimals == 8) return price;
        else if (decimals < 8) return price.div(10**(8 - decimals));
        else return price.mul(10**(decimals - 8));
    }

    /**
     * @return Minimum amount of ZAPP a referrer must have bought to get a referral link (18 decimals)
     */
    function getReferrerMin() public view returns (uint256) {
        return _referrerMin;
    }

    /**
     * @return Minimum amount of ZAPP a referee must buy to get referral bonus (18 decimals)
     */
    function getRefereeMin() public view returns (uint256) {
        return _refereeMin;
    }

    /**
     * @return Percentage of purchase to receive as bonus (8 decimals)
     */
    function getReferralBonus() public view returns (uint256) {
        return _referralBonus;
    }

    /**
     * @return The referral code for this address
     */
    function getReferralCode() public view returns (bytes3) {
        return _wallets[msg.sender].referrer.code;
    }

    /**
     * @param code referral code
     * @return Whether the referral code is valid
     */
    function isReferralCodeValid(bytes3 code) public view returns (bool) {
        return _codes[code] != address(0) && _codes[code] != msg.sender;
    }

    /**
     * @return The referral rank reward list
     */
    function getRankRewards() public view returns (uint256[5] memory) {
        return _rankRewards;
    }

    /**
     * @return The amount of registered Bounty Hunters
     */
    function getRegisteredHunters() public view returns (uint256) {
        return _registeredHunters.length;
    }

    /**
     * @return The maximum number of Bounty Hunters that can register
     */
    function getMaxHunters() public view returns (uint256) {
        return _maxHunters;
    }

    /**
     * @return The bonus for registering as Bounty Hunter
     */
    function getRegisterBonus() public view returns (uint256) {
        return _registerBonus;
    }

    /**
     * @return Whether Bounty Hunters can still register
     */
    function canRegister() public view returns (bool) {
        return getRegisteredHunters() < getMaxHunters();
    }

    /**
     * @param addr address to check
     * @return Whether the address is a Bounty Hunter
     */
    function isHunter(address addr) public view returns (bool) {
        return _wallets[addr].isHunter;
    }

    /**
     * @param addr address to check
     * @return Whether the address is a registered Bounty Hunter 
     */
    function isHunterRegistered(address addr) public view returns (bool) {
        for (uint256 i = 0; i < _registeredHunters.length; ++i) {
            if (_registeredHunters[i] == addr) return true;
        }
        return false;
    }

    /**
     * @return Whether the Bounty Hunter is verified by Zappermint
     */
    function isHunterVerified(address addr) public view returns (bool) {
        return _wallets[addr].hunter.verified;
    }

    /**
     * @param addr address to get ETH of
     * @return The amount of wei this address has spent (18 decimals)
     */
    function getBuyerETH(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].buyer.eth;
    }

    /**
     * @param addr address to get ZAPP of
     * @return The amount of ZAPP bits this address has bought (18 decimals)
     */
    function getBuyerZAPP(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].buyer.zapp;
    }

    /**
     * @param addr address to get bonus of
     * @return The amount of ZAPP bits this address will get as early adopter bonus (18 decimals)
     */
    function getEarlyAdopterBonus(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].getEarlyAdopterBonus(_earlyAdoptionBonus);
    }

    /**
     * @param addr address to get bonus of
     * @return The amount of ZAPP bits this address will get as referrer bonus (18 decimals)
     */
    function getReferrerBonus(address addr) public  view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].getReferrerBonus(_referralBonus, _referrerMin, isClaimable());
    }

    /**
     * @param addr address to get bonus of
     * @return The amount of ZAPP bits this address will receive as bonus for his purchase(s) (18 decimals)
     */
    function getRefereeBonus(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].getRefereeBonus(_referralBonus);
    }

    /**
     * @param addr address to get bonus of
     * @return The amount of ZAPP bits this address will receive as bonus for his bounty campaign (18 decimals)
     */
    function getHunterBonus(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return _wallets[addr].getHunterBonus(isClaimable());
    }

    /**
     * @param addr address to get reward of
     * @return The amount of ZAPP bits this address will be rewarded with for referrer rank (18 decimals)
     */
    function getReferrerRankReward(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        uint256 rank = getReferrerRank(addr);
        if (rank == 0) return 0;
        --rank;
        if (rank < _rankRewards.length) return _rankRewards[rank];
        return 0;
    }

    /**
     * @param addr address to get reward of
     * @return The total amount of ZAPP bits this address will get as bonus (18 decimals)
     * NOTE Hunter and referrer rank rewards only added when claimable
     */
    function getWalletTotalBonus(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        uint256 total = getEarlyAdopterBonus(addr)
            .add(getReferrerBonus(addr))
            .add(getRefereeBonus(addr));
        
        bool verified = isHunterVerified(addr);
        bool claimable = isClaimable();
        
        // Add hunter bonus when verified
        if (verified) {
            total = total.add(getHunterBonus(addr));
        } 
        // Also add hunter bonus when not claimable yet
        else if (!claimable) {
            total = total.add(getHunterBonus(addr));
        }

        // Add rank reward when claimable
        if (claimable) {
            total = total.add(getReferrerRankReward(addr));
        } 
        
        return total;
    }

    /**
     * @param addr address to get ZAPP of
     * @return The total amount of ZAPP bits this address can claim (18 decimals)
     */
    function getWalletTotalZAPP(address addr) public view returns (uint256) {
        if (hasWalletClaimed(addr)) return 0;
        return getBuyerZAPP(addr)
            .add(getWalletTotalBonus(addr));
    }

    /**
     * @param addr address to get claimed state of
     * @return Whether this address has claimed their ZAPP
     */
    function hasWalletClaimed(address addr) public view returns (bool) {
        return _wallets[addr].claimed;
    }

    /**
     * @param addr address to get referrals of
     * @return The list of successful referrals of the referrer
     */
    function getReferrals(address addr) public view returns (uint256[] memory) {
        uint256 length = _wallets[addr].referrer.referrals.length;
        uint256[] memory referrals = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            referrals[i] = _wallets[addr].referrer.referrals[i].zapp;
        }
        return referrals;
    }

    /**
     * Get the ranking position of the referrer
     * @param addr referrer address
     * @return The one-based rank of the referrer. 0 if not a referrer
     */
    function getReferrerRank(address addr) public view returns (uint256) {
        // Non-referrers don't have a rank
        if (!_wallets[addr].isReferrer) return 0;
        // Must have at least one referral
        if (_wallets[addr].referrer.referrals.length == 0) return 0;

        // Start at rank 1
        uint256 rank = 1;
        uint256 amount1 = _wallets[addr].calculateReferredAmount(_referrerMin, isClaimable());
        if (amount1 == 0) return 0;

        // Find every referrer with a higher referral sum
        for (uint256 key = 0; key < _walletKeys.length; ++key) {
            // Skip self
            if (addr == _walletKeys[key]) continue;

            // Skip non-referrers
            if (!_wallets[_walletKeys[key]].isReferrer) continue;
            
            uint256 amount2 = _wallets[_walletKeys[key]].calculateReferredAmount(_referrerMin, isClaimable());
            if (amount2 == 0) continue;
            
            // Increase the rank if another referrer has a higher sum
            if (amount2 > amount1) ++rank;
            // Increase the rank if another referrer has same amount but earlier time
            else if (amount2 == amount1 && _wallets[_walletKeys[key]].referrer.time < _wallets[addr].referrer.time) ++rank;
        }
        return rank;
    }

    /**
     * Get the top 5 referrers
     * @return The array of referred amounts of the top 5 referrers
     * NOTE This can vary depending on the isClaimable state
     */
    function getTopReferrers() public view returns (uint256[5] memory) {
        uint256[5] memory top = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
        for (uint256 key = 0; key < _walletKeys.length; ++key) {
            uint256 amount = _wallets[_walletKeys[key]].calculateReferredAmount(_referrerMin, isClaimable());
            for (uint256 t = 0; t < top.length; ++t) {
                if (amount > top[t]) {
                    for (uint256 i = 4; i > t; --i) {
                        top[i] = top[i - 1];
                    }
                    top[t] = amount;
                    break;
                }
            }
        }
        return top;
    }

    /**
     * @return Total amount of ZAPP that has been bought during Early Adoption
     */
    function getTotalEarlyAdoptionZAPP() public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _walletKeys.length; ++i) {
            total = total.add(_wallets[_walletKeys[i]].earlyAdopter.zapp);
        }
        return total;
    }

    /**
     * @return Total amount of ZAPP that has been bought without referral code
     */
    function getTotalWithoutCodeZAPP() public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _walletKeys.length; ++i) {
            total = total.add(_wallets[_walletKeys[i]].buyer.zapp)
                         .sub(_wallets[_walletKeys[i]].referee.zapp);
        }
        return total;
    }

    /**
     * @return Total amount of ZAPP that has been bought with referral code
     */
    function getTotalReferredZAPP() public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _walletKeys.length; ++i) {
            total = total.add(_wallets[_walletKeys[i]].referee.zapp);
        }
        return total;
    }

    /**
     * @return Total amount of ZAPP that has been bought with Bounty Hunter referral code
     */
    function getTotalHunterReferredZAPP() public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < _registeredHunters.length; ++i) {
            total = total.add(_wallets[_registeredHunters[i]].calculateReferredAmount(_referrerMin, false));
        } 
        return total;
    }

    /**
     * @return The Zappermint Token Contract address
     */
    function getZAPPContract() public view returns (address) {
        return _zappContract;
    }

    /**
     * @return The owner of the Token Sale Contract
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

// ----
// Currency helpers
// ----

    /**
     * Calculate amount of ZAPP for a given amount of wei
     * @param weiAmount amount of wei (18 decimals)
     * @return ZAPP
     */
    function calculateZAPPAmount(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(getRate());
    }

    /**
     * Calculate amount of ETH for a given amount of ZAPP bits
     * @param zappAmount amount of ZAPP bits (18 decimals)
     * @return Wei
     */
    function calculateETHAmount(uint256 zappAmount) public view returns (uint256) {
        return zappAmount.div(getRate());
    }

// ----
// Setters
// ----

    /**
     * Changes the ETH price in case ChainLink breaks
     * @param price price of 1 ETH in USD (8 decimals)
     */
    function setETHPrice(uint256 price) public beforeEnd onlyOwner {
        _ethPrice = price;
    }

    /**
     * Changes the max amount of Bounty Hunters that can register
     * @param max new max amount
     */
    function setMaxHunters(uint256 max) public beforeEnd onlyOwner {
        _maxHunters = max;
    }

    /**
     * Closes the Token Sale manually
     */
    function endTokenSale() public onlyOwner {
        _ended = true;
    }

    /**
     * Sets the address of the Zappermint Token Contract
     * @param zappContract address of the Zappermint Token Contract
     */
    function setZAPPContract(address zappContract) public onlyOwner {
        _zappContract = zappContract;
    }

    /**
     * Transfers ownership
     * @param newOwner address of the new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

// ----
// Transaction functions
// ----

    /**
     * Fallback function shouldn't do anything, as it won't have any ETH to buy ZAPP with
     */
    fallback () external whileOpen {
        revert("Fallback function called");
    }

    /**
     * Receive function to buy ZAPP
     */
    receive() external payable whileOpen {
        buyZAPP();
    }

    /**
     * Buy ZAPP without referral code
     */
    function buyZAPP() public payable whileOpen {
        uint256 zapp = _buyZAPP(msg.sender, msg.value);
        _assignBonuses(msg.sender, zapp, bytes3(0));
    }

    /**
     * Buy ZAPP with referral code
     * @param code used referral code
     */
    function buyZAPPWithCode(bytes3 code) public payable whileOpen {
        uint256 zapp = _buyZAPP(msg.sender, msg.value);
        _assignBonuses(msg.sender, zapp, code);
    }

    /**
     * Register as Bounty Hunter
     * NOTE This generates a code for the address, disregarding the bought zapp amount
     */
    function registerHunter() public whileNotClosed {
        require(!isHunterRegistered(msg.sender), "Already a Bounty Hunter");
        require(canRegister(), "Maximum amount of Bounty Hunters has been reached");
        
        // Register without purchase
        if (_wallets[msg.sender].addr == address(0)) {
            _wallets[msg.sender].addr = msg.sender;
            _walletKeys.push(msg.sender);
        }
        
        _wallets[msg.sender].register(_registerBonus, _codes);
        _registeredHunters.push(msg.sender);
    }

    /**
     * Verifies Bounty Hunters and adds their collected bounty rewards
     * @param hunters list of Bounty Hunters
     * @param bonuses list of bounty rewards (18 decimals)
     * NOTE Lists need to be of same length
     */
    function verifyHunters(address[] memory hunters, uint256[] memory bonuses) public afterEnd aboveSoftCap onlyOwner {
        require(hunters.length == bonuses.length, "Data length mismatch");
        for (uint256 i = 0; i < hunters.length; ++i) {
            // Verify without purchase
            if (_wallets[hunters[i]].addr == address(0)) {
                _wallets[hunters[i]].addr = payable(hunters[i]);
                _walletKeys.push(msg.sender);
            }
            _wallets[hunters[i]].verify(bonuses[i]);
        }
    }

    /**
     * Transfers the contract's wei to a wallet, after Token Sale ended and has reached the soft cap
     * @param wallet address to send wei to
     */
    function claimETH(address payable wallet) public afterEnd aboveSoftCap onlyOwner {
        wallet.transfer(address(this).balance);
    }

    /**
     * Lets a wallet claim their ZAPP through the Zappermint Token Contract, after claim opening time 
     *   and if token sale has reached the soft cap
     * @return Amount of bought ZAPP and amount of bonus ZAPP
     * NOTE The payout implementation of this can be found in the Zappermint Token Contract
     */
    function claimZAPP() public afterEnd aboveSoftCap whileClaimable onlyZAPPContract returns (uint256, uint256) {
        address beneficiary = tx.origin; // Use tx, as msg points to the Zappermint Token Contract

        require(!hasWalletClaimed(beneficiary), "Already claimed");
        uint256 zapp = getBuyerZAPP(beneficiary);
        uint256 bonus = getWalletTotalBonus(beneficiary);

        // Adjust claimed state
        _wallets[beneficiary].claimed = true;

        // Return amount of ZAPP and bonus of the wallet
        // NOTE Returned separately so the Token Contract can send the ZAPP from the correct pools
        return (zapp, bonus);
    }

    /**
     * Lets the buyer claim their ETH, after Token Sale ended and hasn't reached the soft cap
     */
    function claimRefund() public afterEnd belowSoftCap {
        address beneficiary = msg.sender;

        require(_wallets[beneficiary].isBuyer, "Not a buyer");
        require(!_wallets[beneficiary].claimed, "Already claimed");

        // Get buyer variables before changing state (otherwise will return 0!)
        uint256 zapp = getBuyerZAPP(beneficiary);
        uint256 eth = getBuyerETH(beneficiary);

        // Adjust claimed state
        _wallets[beneficiary].claimed = true;

        // Adjust Token Sale state
        _soldZAPP = _soldZAPP.sub(zapp);

        // Refund the ETH of the buyer
        _wallets[beneficiary].addr.transfer(eth);
    }

// ----
// Internal functions
// ----

    /**
     * Calculate amount of ZAPP for a given amount of wei
     * @param weiAmount amount of wei
     * @param rate ZAPP/ETH rate
     * @return ZAPP bits (18 decimals)
     * NOTE Internally used as optimization by avoiding multiple Chainlink calls
     */
    function _calculateZAPPAmount(uint256 weiAmount, uint256 rate) internal pure returns (uint256) {
        return weiAmount.mul(rate);
    }

    /**
     * Calculate amount of ETH for a given amount of ZAPP bits
     * @param zappAmount amount of ZAPP bits (18 decimals)
     * @param rate ZAPP/ETH rate
     * @return wei
     * NOTE Internally used as optimization by avoiding multiple Chainlink calls
     */
    function _calculateETHAmount(uint256 zappAmount, uint256 rate) internal pure returns (uint256) {
        return zappAmount.div(rate);
    }

    /**
     * Buys ZAPP
     * @param beneficiary address of buyer
     * @param eth amount of ETH sent
     * @return Amount of ZAPP bought
     */
    function _buyZAPP(address beneficiary, uint256 eth) internal returns (uint256) {
        // Verify amount of ETH
        require(eth > 0, "Not enough ETH");

        // First purchase
        if (_wallets[beneficiary].addr == address(0)) {
            _wallets[beneficiary].addr = payable(beneficiary);
            _walletKeys.push(beneficiary);
        }

        // Make sure the rate is consistent in this purchase
        uint256 rate = getRate();

        // Calculate the amount of ZAPP to receive and add it to the total sold
        uint256 zapp = _calculateZAPPAmount(eth, rate); 
        _soldZAPP = _soldZAPP.add(zapp);

        // Verify that this purchase isn't surpassing the hard cap, otherwise refund exceeding amount 
        int256 exceeding = int256(_soldZAPP - _hardCap);
        uint256 exceedingZAPP = 0;
        uint256 exceedingETH = 0;
        if (exceeding > 0) {
            // Adjust sold amount and close Token Sale
            _soldZAPP = _hardCap;
            _ended = true;

            // Adjust amount of bought ZAPP and paid ETH
            exceedingZAPP = uint256(exceeding);
            exceedingETH = _calculateETHAmount(exceedingZAPP, rate);
            zapp = zapp.sub(exceedingZAPP);
            eth = eth.sub(exceedingETH);
        }

        // Adjust the buyer
        _wallets[beneficiary].purchase(eth, zapp);

        // Purchase adds total bought ZAPP to more than referrer minimum
        if (!_wallets[beneficiary].isReferrer && _wallets[beneficiary].buyer.zapp >= _referrerMin) {
            _wallets[beneficiary].isReferrer = true;
            _wallets[beneficiary].generateReferralCode(_codes);
        }

        // Refund the exceeding ETH
        // NOTE Checks-Effects-Interactions pattern
        if (exceeding > 0) _wallets[beneficiary].addr.transfer(exceedingETH);

        return zapp;
    }

    /**
     * Assigns all active bonuses for a purchase
     * @param beneficiary address of the buyer
     * @param zapp amount of ZAPP bits purchased (18 decimals)
     * @param code used referral code (set to 0 if no code used)
     */
    function _assignBonuses(address beneficiary, uint256 zapp, bytes3 code) internal {
        // Referral bonus if code is valid and purchased enough ZAPP
        if (isReferralCodeValid(code)) {
            if (zapp >= _refereeMin) {
                _wallets[beneficiary].referral(zapp, _wallets[_codes[code]]);
            }
        }
        // Early adopter bonus if code invalid and early adoption active
        else {
            if (isEarlyAdoptionActive()) {
                _wallets[beneficiary].earlyAdoption(zapp);
            }
        }
    }

}"}}