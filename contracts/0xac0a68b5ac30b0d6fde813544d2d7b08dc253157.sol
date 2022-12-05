{"Context.sol":{"content":"// SPDX-License-Identifier: MIT
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
}"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
}"},"SafeSharp.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeSharp.sol";

contract SafeSharp is Ownable {
    mapping(address => bool) public referralPartners;

    /*****------- CONSTANTS -------******/
    bool public weeklyBettingOn = true;
    bool public survivorBettingOn = true;
    uint256 public HOUSE_PAY_BIP = 1000;
    uint256 public REFERRAL_PAY_BIP = 180;
    uint256 public PARTNER_REFERRAL_PAY_BIP = 250;
    uint256 public smallBet = 0.02 ether;
    uint256 public mediumBet = 0.06 ether;
    uint256 public largeBet = 0.1 ether;

    address public HOUSE_ADDRESS = 0xcE6377f66982d3C9dc83f1d7E08D29839296e2F5;

    /*****------- DATATYPES -------******/
    /// Status

    uint256 public weekLive = 1;

    struct WeeklyBet {
        uint256 week;
        uint256[] picks;
        address picker;
        address referral;
        uint256 betAmount;
        uint256 paidOut;
        uint dateTime;
        bool active;
    }

    struct SurvivorBet {
        uint256[] picks;
        address picker;
        address referral;
        uint256 betAmount;
        uint256 paidOut;
        uint dateTime;
        bool active;
    }

    mapping(address => uint256) public weeklyBetLog;
    mapping(address => uint256) public survivorBetLog;

    // map week to an array of bets. e.g. weeklyBets[1] = array of week 1 bets
    SurvivorBet[] public survivorBetSmall;
    SurvivorBet[] public survivorBetMedium;
    SurvivorBet[] public survivorBetLarge;

    SurvivorBet[] public winnersSurvivor;

    // map week to the pool amount for that week. e.g. weeklyPoolSmall[4] = 50 which means 50 ETH
    uint256 public survivorPoolSmall;
    uint256 public survivorPoolMedium;
    uint256 public survivorPoolLarge;

    // map week to an array of bets. e.g. weeklyBets[1] = array of week 1 bets
    mapping(uint256 => WeeklyBet[]) public weeklyBetSmall;
    mapping(uint256 => WeeklyBet[]) public weeklyBetMedium;
    mapping(uint256 => WeeklyBet[]) public weeklyBetLarge;

    mapping(uint256 => WeeklyBet[]) public winnersWeekly;

    // map week to the pool amount for that week. e.g. weeklyPoolSmall[4] = 50 which means 50 ETH
    mapping(uint256 => uint256) public weeklyPoolSmall;
    mapping(uint256 => uint256) public weeklyPoolMedium;
    mapping(uint256 => uint256) public weeklyPoolLarge;

    /*****------- CONSTRUCTOR -------******/
    constructor() public {}

    function setWeek(uint256 _week) external onlyOwner {
        weekLive = _week;
    }

    function setPartnerRoyalty(address _address) external onlyOwner {
        referralPartners[_address] = true;
    }

    function resetPartnerRoyalty(address _address) external onlyOwner {
        referralPartners[_address] = false;
    }

    function setPartnerReferral(uint256 bip) external onlyOwner {
        require(bip <= HOUSE_PAY_BIP, "Partner referral BIP is higher than the House BIP");
        PARTNER_REFERRAL_PAY_BIP = bip;
    }

    function setNormalReferral(uint256 bip) external onlyOwner {
        require(bip <= HOUSE_PAY_BIP, "Referral BIP is higher than the House BIP");
        REFERRAL_PAY_BIP = bip;
    }

    function setHouse(uint256 bip) external onlyOwner {
        require(bip <= 10000, "Referral BIP is higher than 100%");
        HOUSE_PAY_BIP = bip;
    }

    function getWeeklyPicksByAddress(address _address) public view returns (WeeklyBet[] memory)
    {
        WeeklyBet[] memory pool = new WeeklyBet[](weeklyBetLog[_address]);
        uint256 counter = 0;

        for (uint256 i; i < 18; i++) {
            for (uint256 x; x < weeklyBetSmall[i].length; x++) {
                if (weeklyBetSmall[i][x].picker == _address) {
                    pool[counter] = weeklyBetSmall[i][x];
                    counter += 1;
                }
            }
        }

        for (uint256 i; i < 18; i++) {
            for (uint256 x; x < weeklyBetMedium[i].length; x++) {
                if (weeklyBetMedium[i][x].picker == _address) {
                    pool[counter] = weeklyBetMedium[i][x];
                    counter += 1;
                }
            }
        }

        for (uint256 i; i < 18; i++) {
            for (uint256 x; x < weeklyBetLarge[i].length; x++) {
                if (weeklyBetLarge[i][x].picker == _address) {
                    pool[counter] = weeklyBetLarge[i][x];
                    counter += 1;
                }
            }
        }
        return pool;
    }

    function getSurvivorPicksByAddress(address _address) public view returns (SurvivorBet[] memory) {
        SurvivorBet[] memory pool = new SurvivorBet[](survivorBetLog[_address]);
        uint256 counter = 0;
        for (uint256 i; i < survivorBetSmall.length; i++) {
            if (_address == survivorBetSmall[i].picker) {
                pool[counter] = survivorBetSmall[i];
                counter += 1;
            }
        }
        for (uint256 i; i < survivorBetMedium.length; i++) {
            if (_address == survivorBetMedium[i].picker) {
                pool[counter] = survivorBetMedium[i];
                counter += 1;
            }
        }

        for (uint256 i; i < survivorBetLarge.length; i++) {
            if (_address == survivorBetLarge[i].picker) {
                pool[counter] = survivorBetLarge[i];
                counter += 1;
            }
        }

        return pool;
    }

    function getSurvivorPool(uint256 _betSize) public view returns (SurvivorBet[] memory) {
        SurvivorBet[] memory pool;
        if (_betSize == 0) {
            pool = new SurvivorBet[](survivorBetSmall.length);
            for (uint256 i; i < survivorBetSmall.length; i++) {
                pool[i] = survivorBetSmall[i];
            }
        } else if (_betSize == 1) {
            pool = new SurvivorBet[](survivorBetMedium.length);
            for (uint256 i; i < survivorBetMedium.length; i++) {
                pool[i] = survivorBetMedium[i];
            }
        } else {
            pool = new SurvivorBet[](survivorBetLarge.length);
            for (uint256 i; i < survivorBetLarge.length; i++) {
                pool[i] = survivorBetLarge[i];
            }
        }
        return pool;
    }

    function setSurvivor(
        uint256[] memory _picks,
        address _referral,
        uint _dateTime
    ) external payable {
        require(msg.value >= smallBet, "Not enough for a bet");
        require(survivorBettingOn, "Survivor betting is not live");
        require(_picks.length == 18, "Picks array must be 19 in length");
        SurvivorBet memory _survivorBet = SurvivorBet(
            _picks,
            msg.sender,
            _referral,
            msg.value,
            0,
            _dateTime, 
            true
        );
        survivorBetLog[msg.sender] = survivorBetLog[msg.sender] + 1;
        if (msg.value == largeBet) {
            survivorBetLarge.push(_survivorBet);
            survivorPoolLarge +=
                msg.value -
                ((msg.value * HOUSE_PAY_BIP) / 10000);
        } else if (msg.value == mediumBet) {
            survivorBetMedium.push(_survivorBet);
            survivorPoolMedium +=
                msg.value -
                ((msg.value * HOUSE_PAY_BIP) / 10000);
        } else {
            survivorBetSmall.push(_survivorBet);
            survivorPoolSmall +=
                msg.value -
                ((msg.value * HOUSE_PAY_BIP) / 10000);
        }

        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        // if the referring address is a non-zero address:
        if (_referral != address(0)) {
            // check if referral address is true in referral partners
            if (referralPartners[_referral]) {
                payable(_referral).transfer((msg.value * PARTNER_REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - PARTNER_REFERRAL_PAY_BIP;
            } else {
                payable(_referral).transfer((msg.value * REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
            }
        }
        payable(HOUSE_ADDRESS).transfer(
            (msg.value * HOUSE_PAY_NET_BIP) / 10000
        );
    }

    /// Bet size should be "smallBet", "mediumBet", or "largeBet"
    function setWeeklyPick(
        uint256 _week,
        uint256[] memory _picks,
        address _referral,
        uint _dateTime
    ) external payable {
        require(msg.value >= smallBet, "Not enough for a bet");
        require(weeklyBettingOn, "Weekly betting is not live");
        require(_picks.length == 19, "Picks array must be 19 in length");
        require(_week >= weekLive, "That week has already passed. Please bet in a current or later week");

        WeeklyBet memory _weeklyBet = WeeklyBet(
            _week,
            _picks,
            msg.sender,
            _referral,
            msg.value,
            0,
            _dateTime,
            true
        );
        weeklyBetLog[msg.sender] = weeklyBetLog[msg.sender] + 1;

        if (msg.value == largeBet) {
            weeklyBetLarge[_week].push(_weeklyBet);
            weeklyPoolLarge[_week] += msg.value - ((msg.value * HOUSE_PAY_BIP) / 10000);
        } else if (msg.value == mediumBet) {
            weeklyBetMedium[_week].push(_weeklyBet);
            weeklyPoolMedium[_week] += msg.value - ((msg.value * HOUSE_PAY_BIP) / 10000);
        } else {
            weeklyBetSmall[_week].push(_weeklyBet);
            weeklyPoolSmall[_week] += msg.value - ((msg.value * HOUSE_PAY_BIP) / 10000);
        }

        uint256 HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP;
        // if the referring address is a non-zero address:
        if (_referral != address(0)) {
            // check if referral address is true in referral partners
            if (referralPartners[_referral]) {
                payable(_referral).transfer((msg.value * PARTNER_REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - PARTNER_REFERRAL_PAY_BIP;
            } else {
                payable(_referral).transfer((msg.value * REFERRAL_PAY_BIP) / 10000);    
                HOUSE_PAY_NET_BIP = HOUSE_PAY_BIP - REFERRAL_PAY_BIP;
            }
        }
        payable(HOUSE_ADDRESS).transfer(
            (msg.value * HOUSE_PAY_NET_BIP) / 10000
        );
    }

    /*****------- OWNER FUNCTIONS -------******/
    function flipWeekly() external onlyOwner {
        weeklyBettingOn = !weeklyBettingOn;
    }

    function flipSurvivor() external onlyOwner {
        survivorBettingOn = !survivorBettingOn;
    }

    function setHouseAddress(address _address) external onlyOwner {
        HOUSE_ADDRESS = _address;
    }

    function setHouseAmount(uint256 _percentage) external onlyOwner {
        HOUSE_PAY_BIP = _percentage;
    }

    function setReferralAmount(uint256 _referral) external onlyOwner {
        REFERRAL_PAY_BIP = _referral;
    }

    /**** PICK AND PAY OUT SIZE POOL FOR SURVIVOR  ****/
    /*** Size 0 = small, Size 1 = medium, Size 2 = large ***/
    function pickSurvivorWinner(uint256[][] memory correctPicks, uint8 size) external onlyOwner returns (uint256) {
        require(size == 0 || size == 1 || size == 2, "Size variable not valid");
        // require(correctPicks.length == 18, "Picks array must be 19 in length");
        uint256 highestRightCount = 0;
        SurvivorBet[] memory pool;
        uint256 winningAmount;
        if (size == 0) {
            pool = survivorBetSmall;
            winningAmount = survivorPoolSmall;
            survivorPoolSmall = 0;
        } else if (size == 1) {
            pool = survivorBetMedium;
            winningAmount = survivorPoolMedium;
            survivorPoolMedium = 0;
        } else {
            pool = survivorBetLarge;
            winningAmount = survivorPoolLarge;
            survivorPoolLarge = 0;
        }

        for (uint256 i; i < pool.length; i++) {
            if (size == 0) {
                survivorBetSmall[i].active = false;
            } else if (size == 1) {
                survivorBetMedium[i].active = false;
            } else {
                survivorBetLarge[i].active = false;
            }
            uint256 thisPickersCount = 0;
            for (uint256 x; x < pool[i].picks.length; x++) {
                bool weekPickCorrect;
                for (uint256 cp; cp < correctPicks[x].length; cp++) {
                    if (correctPicks[x][cp] == pool[i].picks[x]) {
                        weekPickCorrect = true;
                        break;
                    }
                }
                if (weekPickCorrect) {
                    thisPickersCount++;
                    weekPickCorrect = false;
                } else {
                    break;
                }
            }

            if (thisPickersCount > highestRightCount) {
                delete winnersSurvivor;
                winnersSurvivor.push(pool[i]);
                highestRightCount = thisPickersCount;
            } else if (thisPickersCount == highestRightCount) {
                winnersSurvivor.push(pool[i]);
            }
        }

        for (uint256 i; i < winnersSurvivor.length; i++) {
            uint256 payAmount = winningAmount / winnersSurvivor.length;
            address winnersAddress = winnersSurvivor[i].picker;
            for (uint256 x; x < pool.length; x++) {
                if (size == 0) {
                    if (survivorBetSmall[x].picker == winnersAddress) {
                        survivorBetSmall[x].paidOut = payAmount;
                    } 
                } else if (size == 1) {
                    if (survivorBetMedium[x].picker == winnersAddress) {
                        survivorBetMedium[x].paidOut = payAmount;
                    }
                } else {
                    if (survivorBetLarge[x].picker == winnersAddress) {
                        survivorBetLarge[x].paidOut = payAmount;
                    }
                }
            }
            payable(winnersAddress).transfer(payAmount);
        }
        delete winnersSurvivor;
        return highestRightCount;
    }

    /**** PICK AND PAY OUT SIZE POOL WEEKLY  ****/
    /*** Size 0 = small, Size 1 = medium, Size 2 = large ***/
    function pickWeeklyWinner(uint256 week, uint256[] memory correctPicks, uint8 size) external onlyOwner returns (uint256) {
        require(size == 0 || size == 1 || size == 2, "Size variable not valid");
        require(correctPicks.length == 19, "Picks array must be 19 in length");
        uint256 highestRightCount = 0;
        WeeklyBet[] memory pool;
        uint256 winningAmount;
        if (size == 0) {
            pool = weeklyBetSmall[week];
            winningAmount = weeklyPoolSmall[week];
            weeklyPoolSmall[week] = 0;
        } else if (size == 1) {
            pool = weeklyBetMedium[week];
            winningAmount = weeklyPoolMedium[week];
            weeklyPoolMedium[week] = 0;
        } else {
            pool = weeklyBetLarge[week];
            winningAmount = weeklyPoolLarge[week];
            weeklyPoolLarge[week] = 0;
        }

        for (uint256 i; i < pool.length; i++) {
            if (size == 0) {
                weeklyBetSmall[week][i].active = false;
            } else if (size == 1) {
                weeklyBetMedium[week][i].active = false;
            } else {
                weeklyBetLarge[week][i].active = false;
            }
            uint256 thisPickersCount = 0;
            for (uint256 x; x < pool[i].picks.length; x++) {
                if (correctPicks[x] == pool[i].picks[x]) {
                    thisPickersCount++;
                }
            }

            if (thisPickersCount > highestRightCount) {
                delete winnersWeekly[week];

                winnersWeekly[week].push(pool[i]);
                highestRightCount = thisPickersCount;
            } else if (thisPickersCount == highestRightCount) {
                winnersWeekly[week].push(pool[i]);
            }
        }

        for (uint256 i; i < winnersWeekly[week].length; i++) {
            uint256 payAmount = winningAmount / winnersWeekly[week].length;
            address winnersAddress = winnersWeekly[week][i].picker;
            for (uint256 x; x < pool.length; x++) {
                if (size == 0) {
                    if (weeklyBetSmall[week][x].picker == winnersAddress) {
                        weeklyBetSmall[week][x].paidOut = payAmount;
                    }
                } else if (size == 1) {
                    if (weeklyBetMedium[week][x].picker == winnersAddress) {
                        weeklyBetMedium[week][x].paidOut = payAmount;
                    }
                } else {
                    if (weeklyBetLarge[week][x].picker == winnersAddress) {
                        weeklyBetLarge[week][x].paidOut = payAmount;
                    }
                }
            }
            payable(winnersAddress).transfer(payAmount);
        }
        delete winnersWeekly[week];
        return highestRightCount;
    }


    /// Betsize is either 0,1,2
    /// if weekly is false, it'll pull from survivor
    /// if pulling from survivor, input week = -1 
    function withdrawFromPool(uint256 size, bool weekly, uint256 week) external onlyOwner {
        uint256 winningAmount;
        if (weekly) {
            if (size == 0) {
                winningAmount = weeklyPoolSmall[week];
                weeklyPoolSmall[week] = 0;
            } else if (size == 1) {
                winningAmount = weeklyPoolMedium[week];
                weeklyPoolMedium[week] = 0;
            } else {
                winningAmount = weeklyPoolLarge[week];
                weeklyPoolLarge[week] = 0;
            }
        } else {
            if (size == 0) {
                winningAmount = survivorPoolSmall;
                survivorPoolSmall = 0;
            } else if (size == 1) {
                winningAmount = survivorPoolMedium;
                survivorPoolMedium = 0;
            } else {
                winningAmount = survivorPoolLarge;
                survivorPoolLarge = 0;
            }
        }
        (bool success, ) = msg.sender.call{value: winningAmount}("");
        require(success, "Withdraw failed.");
    }
}
"}}