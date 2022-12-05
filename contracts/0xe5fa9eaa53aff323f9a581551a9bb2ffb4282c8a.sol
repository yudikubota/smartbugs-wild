{"ERC20.sol":{"content":"pragma solidity ^0.5.8;
import './SafeMath.sol';

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  uint256 public currentSupply;
  address public master;
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) external onlyPayloadSize(3 * 32) {
    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) external {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
"},"Invitation.sol":{"content":"pragma solidity ^0.5.8;
import './SafeMath.sol';

contract InvitationBasic {
    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external;
    function getParent(address addr) external view returns(address);
    function getAncestors(address addr) external view returns(address[] memory);
    function isRoot(address addr) external view returns (bool);
    function isSignedUp(address addr) public view returns (bool);
    function newRoot(address addr, uint256 phase) external;
    function newSignupCount(uint256 phase) external view returns (uint);
    function getPoints(uint256 phase, address addr) external view returns (uint256);
    function getTop(uint256 phase) external view returns(address[] memory);
    function distributeBonus(uint256 len) external pure returns(uint256[] memory);
}

contract Invitation is InvitationBasic {
    using SafeMath for uint256;

    /*
     * STATES
     */
    address public master;
    address public caller;

    bool public paused;

    mapping (address => bool) public rootList;
    mapping (address => address) public referenceParentList;
    mapping (address => address[]) public referenceChildList;
    mapping (uint256 => mapping (address => uint256)) public addressPoints;
    mapping (uint256 => address[]) public newSignupList;
    mapping (uint256 => address[]) public inviterList;
    mapping (uint256 => address[]) public top;

    uint maxChildrenCount = 0;
    uint256 basePoints = 100000;
    uint256 pointRate = 0;
    uint256 maxPointLevel = 10;
    uint256 winnerCount = 10;

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function setWinnerCount(uint256 _count) external onlyOwner {
        winnerCount = _count;
    }

    function isSignedUp(address addr) public view returns (bool) {
        return rootList[addr] == true || referenceParentList[addr] != address(0);
    }

    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external onlyCaller notPaused {
        require(isSignedUp(referrer), "invalid referrer");
        require(!isSignedUp(addr), "address has signed up");

        setUpParent(referrer, addr);
        updatePoints(referrer, addr, ePhase);
        newSignupList[phase].push(addr);
    }

    function isRoot(address addr) external view returns (bool) {
        return rootList[addr] == true;
    }

    function newRoot(address addr, uint256 phase) external onlyCaller notPaused {
        require(!isSignedUp(addr), "address has signed up");
        rootList[addr] = true;
        newSignupList[phase].push(addr);
    }

    function getTop(uint256 phase) external view returns(address[] memory) {
      return top[phase];
    }

    /*
    function getTopInviter(uint256 phase, uint256 topN) external onlyCaller returns(address[] memory) {
        if (inviterList[phase].length == 0 || top[phase].length > 0){
            return top[phase];
        }
        uint256 k = topN;
        randomizedSelect(inviterList[phase], 0, inviterList[phase].length - 1, k, phase);

        for (uint256 i = 0; i< k && i < inviterList[phase].length; i++){
            top[phase].push(inviterList[phase][i]);
        }
        return top[phase];
    }
    */

    function getChild(address addr) external view returns(address[] memory) {
        return referenceChildList[addr];
    }

    function getPoints(uint256 phase, address addr) external view returns (uint256) {
        return addressPoints[phase][addr];
    }

    function getParent(address addr) external view returns(address) {
        return referenceParentList[addr];
    }

    function getNewSignup(uint256 phase) external view returns(address[] memory) {
        return newSignupList[phase];
    }

    function newSignupCount(uint256 phase) external view returns (uint) {
        return newSignupList[phase].length;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    constructor(uint _maxChildrenCount, uint _pointRate, uint256 _winnerCount) public {
        master = msg.sender; // master account
        maxChildrenCount = _maxChildrenCount;  // child node max number
        pointRate = _pointRate;  // e.g. 618
        winnerCount = _winnerCount;
    }

    function setUpParent(address pAddress, address addr) internal {
        pAddress = findParent(pAddress);
        referenceParentList[addr] = pAddress;
        referenceChildList[pAddress].push(addr);
    }

    function updateTop(address addr, uint256 phase) internal {
        for (uint256 k = 0; k < top[phase].length; k++){
            if (top[phase][k] == addr) {
                for (uint256 i = k; i > 0; i--){
                    if (addressPoints[phase][top[phase][i]] > addressPoints[phase][top[phase][i-1]]) {
                        (top[phase][i], top[phase][i-1]) = (top[phase][i-1], top[phase][i]);
                    } else {
                        break;
                    }
                }
                return;
            }
        }

        if (top[phase].length < winnerCount){
            top[phase].push(addr);
        } else if (addressPoints[phase][addr] > addressPoints[phase][top[phase][top[phase].length - 1]]){
            top[phase][top[phase].length - 1] = addr;
        }

        for (uint256 i = top[phase].length - 1; i > 0; i--){
            if (addressPoints[phase][top[phase][i]] > addressPoints[phase][top[phase][i-1]]) {
                (top[phase][i], top[phase][i-1]) = (top[phase][i-1], top[phase][i]);
            } else {
              break;
            }
        }
    }

    function updatePoints(address referrer, address addr, uint256 phase) internal {
        uint256 points = basePoints;
        if (addressPoints[phase][referrer] == 0) {
            inviterList[phase].push(referrer);
        }
        addressPoints[phase][referrer] = addressPoints[phase][referrer].add(points);
        points = points.mul(pointRate).div(1000);
        updateTop(referrer, phase);

        address parent = referenceParentList[addr];
        uint256 level = 0;
        while (parent != address(0) && level < maxPointLevel){
            level = level.add(1);
            if (parent == referrer) {
                parent = referenceParentList[parent];
                continue;
            }
            if (addressPoints[phase][parent] == 0) {
                inviterList[phase].push(parent);
            }
            addressPoints[phase][parent] = addressPoints[phase][parent].add(points);
            points = points.mul(pointRate).div(1000);
            updateTop(parent, phase);
            parent = referenceParentList[parent];
        }
    }

    function findParent(address root) internal view returns (address) {
        uint len = 10000;
        address[] memory temp = new address[](len);
        uint startIndex = 0;
        uint currentIndex = 0;
        temp[startIndex] = root;
        while (true){
            address currentAddress = temp[startIndex];
            startIndex++;
            if (startIndex == len){
                startIndex = 0;
            }
            if (referenceChildList[currentAddress].length < maxChildrenCount){
                return currentAddress;
            }else {
                for(uint i = 0; i< referenceChildList[currentAddress].length; i++){
                    currentIndex++;
                    if (currentIndex == len){
                        currentIndex = 0;
                    }
                    temp[currentIndex] = referenceChildList[currentAddress][i];
                }
            }
        }
    }

    /*
    function randomizedSelect(address[] storage addressList, uint left, uint right, uint256 k, uint256 phase) internal{
        if (left == right) {
            return;
        }

        if (left < right) {
            uint mid = partition(addressList, left, right, phase);
            uint i = mid - left + 1;
            if (i == k){
                return;
            }

            if (k < i) {
                return randomizedSelect(addressList, left, mid - 1, k, phase);
            } else {
                return randomizedSelect(addressList, mid + 1, right, k - i, phase);
            }
        }
    }

    function partition(address[] storage addressList, uint left, uint right, uint256 phase) internal returns(uint) {
        address tmp = addressList[left];

        while (left < right) {
            while (left < right && addressPoints[phase][addressList[right]] < addressPoints[phase][tmp]) {
                right--;
            }
            addressList[left] = addressList[right];
            while (left < right && addressPoints[phase][addressList[left]] >= addressPoints[phase][tmp]) {
                left++;
            }
            addressList[right] = addressList[left];
        }
        addressList[left] = tmp;
        return left;
    }
    */

    function distributeBonus(uint256 len) external pure returns(uint256[] memory) {
        uint256[] memory factors = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            if (i < len.div(2)) {
              factors[i] = len.add(len.div(2).sub(i));
            } else {
              if (len % 2 == 0 ) {
                factors[i] = len.add(len.div(2)).sub(1).sub(i);
              } else {
                factors[i] = len.add(len.div(2)).sub(i);
              }
            }
        }
        return factors;
    }

    function getAncestors(address addr) external view returns(address[] memory) {
        address[] memory ancestors = new address[](maxPointLevel);
        address parent = referenceParentList[addr];

        for (uint256 i = 0; parent != address(0) && i < maxPointLevel; i++) {
            ancestors[i] = parent;
            parent = referenceParentList[parent];
        }
        return ancestors;
    }
}
"},"LuckyDraw.sol":{"content":"pragma solidity ^0.5.8;

contract LuckyDrawBasic {
    function buyTicket(address addr, uint256 phase) external;
    function aggregateIcexWinners(uint256 phase) external;
    function getWinners(uint256 phase) external view returns(address[] memory);
}

contract LuckyDraw is LuckyDrawBasic {
    /*
     * STATES
     */
    address public master;
    address public caller;

    bool public paused;

    uint winnerCount = 10;
    mapping (uint256 => address[]) winnerList;
    mapping (uint256 => mapping(address => bool)) playerList;
    mapping (uint256 => uint256) playerNumbers;
    uint nonce = 0;

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    constructor() public {
        master = msg.sender;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function buyTicket(address addr, uint256 phase) external onlyCaller notPaused {
        if (!playerList[phase][addr]){
            playerNumbers[phase]++;
            if (winnerList[phase].length < winnerCount){
                winnerList[phase].push(addr);
            }else {
                uint index = randomIndex(addr, playerNumbers[phase]);
                if (index < winnerCount){
                    winnerList[phase][index] = addr;
                }
            }
            playerList[phase][addr] = true;
        }
    }

    // costs a bit, but will only invoke once, and paid by operator
    function aggregateIcexWinners(uint256 phase) external onlyCaller notPaused {
        for(uint i = 0 ; i < phase; ++i) {
            address[] memory candidates = winnerList[i];
            for(uint j = 0; j < candidates.length; ++j) {
                if (!playerList[phase][candidates[j]]) {
                    if (winnerList[phase].length < winnerCount) {
                        winnerList[phase].push(candidates[j]);
                    } else {
                        uint index = randomIndex(candidates[j], winnerCount * (phase + 1));
                        if (index < winnerCount){
                            winnerList[phase][index] = candidates[j];
                        }
                    }
                }
            }
        }
    }

    function getWinners(uint256 phase) external view returns(address[] memory) {
        return winnerList[phase];
    }

    function randomIndex(address addr, uint number) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, addr, nonce))) % number;
        nonce++;
        return randomnumber;
    }
}
"},"Migrations.sol":{"content":"pragma solidity >=0.4.25 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.8;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
"},"VDPool.sol":{"content":"pragma solidity ^0.5.8;
import './SafeMath.sol';

contract VDPoolBasic {
    function price() external view returns(uint256);
    function currentLevel() external view returns(uint256);
    function currentLevelRemaining() external view returns(uint256);
}

contract VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256);
}

contract VDPool is VDPoolBasic {
    using SafeMath for uint256;
    /*
     * STATES
     */
    address public master;
    address public caller;

    uint256 public ethCapacity = 0;
    uint256 public basicExchangeRate = 0;
    uint256 public currentLevel = 0;
    uint256 public currentLevelStartBlock = 0;
    uint256 public cooldownBlocks = 0; // by default wait 1 block before enterring next level
    VDPoolThrottler throttlerContract;
    uint256 public currentPrice = 0;
    uint256 public currentLevelRemaining = 0;

    bool public paused;

    /*
     * EVENTS
     */
    event LevelDescend(uint256 level, uint256 price, uint256 startBlock, uint256 cooldownBlocks, uint256 currentBlock);

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    constructor(uint256 _ethCapacity, uint256 _currentLevel, uint256 _basicExchangeRate) public {
        master = msg.sender;
        ethCapacity = _ethCapacity;
        currentLevel = _currentLevel;
        currentPrice = (currentLevel.sub(1)).mul(10).add(_basicExchangeRate);
        currentLevelRemaining = _ethCapacity;
        basicExchangeRate = _basicExchangeRate;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    function setCooldownBlocks(uint256 bn) external onlyOwner {
        cooldownBlocks = bn;
    }

    function setThrottlerContract(address contractAddress) external onlyOwner {
        throttlerContract = VDPoolThrottler(contractAddress);
    }

    function price() external view returns (uint256) {
        uint256 tokens = computeTokenAmount(1 ether);
        return tokens;
    }

    function computeTokenAmount(uint256 ethAmount) public view returns (uint256) {
        uint256 tokens = ethAmount.mul(currentPrice);
        return tokens;
    }

    function buyToken(uint256 ethAmount) external onlyCaller notPaused returns (uint256) {
        require(currentLevelStartBlock <= block.number, "cooling down");
        uint256 eth = ethAmount;
        uint256 tokens = 0;
        while (eth > 0) {
            if (eth <= currentLevelRemaining) {
                tokens = tokens + computeTokenAmount(eth);
                currentLevelRemaining = currentLevelRemaining.sub(eth);
                eth = 0;
            }else {
                tokens = tokens + computeTokenAmount(currentLevelRemaining);
                eth = eth.sub(currentLevelRemaining);
                currentLevelRemaining = 0;
            }

            if (currentLevelRemaining == 0){
                currentLevel = currentLevel.sub(1);
                require (currentLevel > 0, "end of levels");
                currentPrice = (currentLevel.sub(1)).mul(10).add(basicExchangeRate);
                currentLevelRemaining = ethCapacity;
                if (address(throttlerContract) != address(0)) {
                    cooldownBlocks = throttlerContract.getCooldownBlocks();
                }
                if (currentLevelStartBlock > block.number ) {
                    // handling the case of desending multiple level in one tx
                    currentLevelStartBlock = currentLevelStartBlock + cooldownBlocks;
                } else {
                    currentLevelStartBlock = block.number + cooldownBlocks;
                }
                emit LevelDescend(currentLevel, currentPrice, currentLevelStartBlock, cooldownBlocks, block.number);
            }
        }

        return tokens;
    }
}
"},"VDPoolThrottler.sol":{"content":"pragma solidity ^0.5.8;


contract VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256);
}

contract DummyThrottler is VDPoolThrottler {
    function getCooldownBlocks() external view returns(uint256) {
      return 1;
  }
}
"},"XDS.sol":{"content":"pragma solidity ^0.5.8;
import './ERC20.sol';

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract VDPoolBasic {
    function price() external view returns (uint256);
    function buyToken(uint256 ethAmount) external returns (uint256);
    function currentLevel() external view returns(uint256);
    function currentLevelRemaining() external view returns(uint256);
}

contract InvitationBasic {
    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external;
    function isRoot(address addr) external view returns (bool);
    function newRoot(address addr, uint256 phase) external;
    function getParent(address addr) external view returns(address);
    function getAncestors(address addr) external view returns(address[] memory);
    function isSignedUp(address addr) public view returns (bool);
    function getPoints(uint256 phase, address addr) external view returns (uint256);
    function newSignupCount(uint256 phase) external view returns (uint256);
    function getTop(uint256 phase) external view returns(address[] memory);
    function distributeBonus(uint256 len) external pure returns(uint256[] memory);
}

contract LuckyDrawBasic {
    function buyTicket(address addr, uint256 phase) external;
    function aggregateIcexWinners(uint256 phase) external;
    function getWinners(uint256 phase) external view returns(address[] memory);
}

contract XDS is StandardToken {
    using address_make_payable for address;

    /*
     * CONSTANTS
     */

    uint16[] public bonusRate = [200, 150, 100, 50];

    /*
     * STATES
     */
    address public settler;
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    address public reservedAccount;
    uint256 public reservedAmount;
    address public foundationAddr;

    uint256 public firstBlock = 0;
    uint256 public blockPerPhase = 0;

    mapping (uint256 => uint256) public ethBalance;
    mapping (uint256 => mapping (address => uint256)) public addressInvestment;
    mapping (address => uint256) public totalInvestment;
    mapping (address => uint256) public crBonus; // controlled release bonus
    address[] icexInvestors;
    mapping (uint256 => address[]) public topInvestor;
    mapping (uint256 => bool) public settled;

    InvitationBasic invitationContract;
    LuckyDrawBasic luckydrawContract;
    VDPoolBasic vdPoolContract;

    uint256 public signUpFee = 0;
    uint256 public rootFee = 0;
    uint256 referrerBonus = 0;
    uint256 ancestorBonus = 0;
    uint16 topInvestorCounter = 0;
    uint16 icexCRBonusRatio = 75;
    uint256 crBonusReleasePhases = 10;
    uint256 ethBonusReleasePhases = 20;

    uint256 luckyDrawRate = 10;
    uint256 invitationRate = 70;
    uint256 topInvestorRate = 20;

    uint256 foundationRate = 50;

    uint256 icexRewardETHPool = 0;

    /*
     * EVENTS
     */
    /// Emitted only once after token sale starts.
    event SaleStarted();

    event Settled(uint256 phase, uint256 ethDistributed, uint256 ethToPool);

    event LuckydrawSettle(uint256 phase, address indexed who, uint256 ethAmount);
    event InvitationSettle(uint256 phase, address indexed who, uint256 ethAmount);
    event InvestorSettle(uint256 phase, address indexed who, uint256 ethAmount);

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only master can call");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _blockPerPhase, uint256 _totalSupply, uint256 _reservedAmount, address _reservedAccount, address _foundationAddr) public {
        master = msg.sender;  // master account
        settler = master;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        currentSupply = _reservedAmount;

        reservedAmount = _reservedAmount;
        reservedAccount = _reservedAccount;
        balances[reservedAccount] = reservedAmount;
        emit Transfer(address(this), reservedAccount, reservedAmount);

        foundationAddr = _foundationAddr; // foundation account

        blockPerPhase = _blockPerPhase; // block number per phase
    }

    /*
     * EXTERNAL FUNCTIONS
     */

    function setOwner(address newOwner) external onlyOwner {
        master = newOwner;
    }

    function setSettler(address newSettler) external onlyOwner {
        settler = newSettler;
    }

    function transfer(address _to, uint256 _value) external onlyPayloadSize(2 * 32) {
        if ( _to == address(this)) {
            require(_value == rootFee, "only valid value is root fee for this recipient");
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            require(!isSignedUp(), "not qulifiled as new root");
            invitationContract.newRoot(msg.sender, currentPhase());
        } else if ( _value == signUpFee && invitationContract.isSignedUp(_to) && !isSignedUp()) {
            uint256 fee = _value;
            balances[msg.sender] = balances[msg.sender].sub(fee);

            uint256 phase = currentPhase();
            uint256 ePhase = phase;
            if (phase < bonusRate.length) {
                ePhase = bonusRate.length - 1;
            }

            invitationContract.signUp(_to, msg.sender, phase, ePhase);
            //direct referrer
            balances[_to] = balances[_to].add(referrerBonus);
            emit Transfer(msg.sender, _to, referrerBonus);
            fee = fee.sub(referrerBonus);

            // go up referrer tree
            address[] memory ancestors = invitationContract.getAncestors(msg.sender);
            for ( uint256 i = 0; i < ancestors.length && fee >= ancestorBonus; i++) {
                if (ancestors[i] == address(0)) {
                    break;
                }
                balances[ancestors[i]] = balances[ancestors[i]].add(ancestorBonus);
                emit Transfer(msg.sender, ancestors[i], ancestorBonus);
                fee = fee.sub(ancestorBonus);
            }

            balances[foundationAddr] = balances[foundationAddr].add(fee);
            emit Transfer(msg.sender, foundationAddr, fee);
        } else {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }
    }

    function setInvitationContract(address addr, uint256 _rootFee, uint256 _signUpFee, uint256 _ancestorBonus, uint256 _referrerBonus, uint256 _invitationRate) external onlyOwner {
        invitationContract = InvitationBasic(addr);

        rootFee = _rootFee; // price to be root
        signUpFee = _signUpFee; // sign up ticker price
        ancestorBonus = _ancestorBonus;  // ancestor node bonus
        referrerBonus = _referrerBonus;  // referrer node bonus
        invitationRate = _invitationRate;
    }

    function setVdPoolContract(address addr, uint16 _topInvestorCounter, uint256 _topInvestorRate, uint256 _foundationRate) external onlyOwner {
        vdPoolContract = VDPoolBasic(addr);

        topInvestorCounter = _topInvestorCounter;  // number of top investor used during settlment
        topInvestorRate = _topInvestorRate;  // top investor settle rate

        foundationRate = _foundationRate; // foudation share
    }

    function setLuckyDrawContract(address addr, uint256 _luckyDrawRate) external onlyOwner {
        luckydrawContract = LuckyDrawBasic(addr);
        luckyDrawRate = _luckyDrawRate;
    }

    function settle(uint256 phase) external {
        require(settler == address(0) || settler == msg.sender, "only settler can call");
        require(phase >= 0, "invalid phase");
        require(phase < currentPhase(), "phase not matured yet");
        require (!settled[phase], "phase already settled");

        uint256 pool = 0;
        uint256 toPool = 0;
        if (phase < bonusRate.length) {
            if(ethBalance[phase] > 0) {
                toPool = ethBalance[phase].mul(bonusRate.length).div(bonusRate.length + ethBonusReleasePhases);
                icexRewardETHPool = icexRewardETHPool.add(toPool);
                transferToFoundation(ethBalance[phase].sub(toPool));
            }
            // settling last phase of ICEX, combine pools
            if (phase == bonusRate.length - 1) {
                pool = icexRewardETHPool;
            }
        } else {
            pool = ethBalance[phase];
            distributeCRBonus(phase);
        }

        if (pool > 0 ) {
            settleLuckydraw(phase, pool, phase < bonusRate.length);
            settleTopInvestor(phase, pool);
            settleInvitation(phase, pool);
        }

        settled[phase] = true;
        emit Settled(phase, pool, toPool);
    }

    function start(uint256 _firstBlock) external onlyOwner {
        require(!saleStarted(), "Sale has not started yet");
        require(firstBlock == 0 , "Resonance already started");
        firstBlock = _firstBlock;
        emit SaleStarted();
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () external payable {
        issueToken(msg.sender);
    }

    function price() external view returns(uint256) {
        return vdPoolContract.price();
    }

    function currentLevel() external view returns(uint256) {
        return vdPoolContract.currentLevel();
    }

    function currentRemainingEth() external view returns(uint256) {
        return vdPoolContract.currentLevelRemaining();
    }

    function currentBonusRate() external view returns(uint16) {
        uint256 phase = currentPhase();
        if (phase < bonusRate.length){
            return bonusRate[phase];
        }
        return 0;
    }

    function isSignedUp() public view returns (bool) {
        return invitationContract.isSignedUp(msg.sender);
    }

    function topInvestors(uint256 phase) external view returns (address[] memory) {
        return topInvestor[phase];
    }

    function luckyWinners(uint256 phase) external view returns (address[] memory) {
        return luckydrawContract.getWinners(phase);
    }

    function invitationWinners(uint256 phase) external view returns(address[] memory) {
        return invitationContract.getTop(phase);
    }

    function drain(uint256 amount) external onlyOwner {
        transferToFoundation(amount);
    }

    /*
     * PUBLIC FUNCTIONS
     */
    function saleStarted() public view returns (bool) {
        return (firstBlock > 0 && block.number >= firstBlock);
    }

    function currentPhase() public view returns(uint256) {
        return (block.number - firstBlock).div(blockPerPhase);
    }

    function issueToken(address recipient) public payable {
        require(saleStarted(), "Sale is not in progress");
        require(msg.value >= 0.1 ether, "minimal of 0.1 eth required");
        uint256 phase = currentPhase();
        uint256 totalEth = msg.value;

        updateTopInvestor(recipient, msg.value, phase);
        // ICEX
        if (phase < bonusRate.length){
            uint256 bonus = totalEth.mul(bonusRate[phase]).div(100);
            totalEth = totalEth.add(bonus);
            if (crBonus[recipient] == 0 ) {
                icexInvestors.push(recipient);
            }
        }

        uint256 tokens = vdPoolContract.buyToken(totalEth);

        totalInvestment[recipient] = totalInvestment[recipient].add(msg.value);
        currentSupply = currentSupply.add(tokens);

        require(currentSupply <= totalSupply, "exceed token supply cap");

        if (phase < bonusRate.length){
            uint256 crTokens = tokens.mul(bonusRate[phase]).div(100 + bonusRate[phase]).mul(icexCRBonusRatio).div(100);
            require(crTokens >= 0 && tokens > crTokens, 'invalid cr bonus value');
            crBonus[recipient] = crBonus[recipient].add(crTokens.div(crBonusReleasePhases));
            balances[recipient] = balances[recipient].add(tokens).sub(crTokens);
            emit Transfer(address(this), recipient, tokens.sub(crTokens));
        } else {
            balances[recipient] = balances[recipient].add(tokens);
            emit Transfer(address(this), recipient, tokens);
        }

        uint256 foundation = msg.value.mul(foundationRate).div(100);
        transferToFoundation(foundation);
        ethBalance[phase] = ethBalance[phase].add(msg.value).sub(foundation);
        luckydrawContract.buyTicket(recipient, phase);
    }

    /*
     * INTERNAL FUNCTIONS
     */

    function updateTopInvestor(address addr, uint256 ethAmount, uint256 phase) internal {
        uint256 ePhase = phase;
        if (phase < bonusRate.length) {
            ePhase = bonusRate.length - 1; // save it for the last phase of ICEX
        }
        addressInvestment[ePhase][addr] = addressInvestment[ePhase][addr].add(ethAmount);

        for (uint256 k = 0; k < topInvestor[ePhase].length; k++){
            if (topInvestor[ePhase][k] == addr) {
                for (uint256 i = k; i > 0; i--){
                    if (addressInvestment[ePhase][topInvestor[ePhase][i]] > addressInvestment[ePhase][topInvestor[ePhase][i-1]]) {
                        (topInvestor[ePhase][i], topInvestor[ePhase][i-1]) = (topInvestor[ePhase][i-1], topInvestor[ePhase][i]);
                    } else {
                      break;
                    }
                }
                return;
            }
        }

        if (topInvestor[ePhase].length < topInvestorCounter){
            topInvestor[ePhase].push(addr);
        } else if (addressInvestment[ePhase][addr] > addressInvestment[ePhase][topInvestor[ePhase][topInvestor[ePhase].length - 1]]){
            topInvestor[ePhase][topInvestor[ePhase].length - 1] = addr;
        }

        for (uint256 i = topInvestor[ePhase].length - 1; i > 0; i--){
            if (addressInvestment[ePhase][topInvestor[ePhase][i]] > addressInvestment[ePhase][topInvestor[ePhase][i-1]]) {
                (topInvestor[ePhase][i], topInvestor[ePhase][i-1]) = (topInvestor[ePhase][i-1], topInvestor[ePhase][i]);
            } else {
              break;
            }
        }
    }

    function transferToFoundation(uint256 ethAmount) internal {
        address payable addr = foundationAddr.make_payable();
        addr.transfer(ethAmount);
    }

    function settleLuckydraw(uint256 phase, uint256 ethAmount, bool isIcex) internal {
        if (isIcex) {
            luckydrawContract.aggregateIcexWinners(phase);
        }
        address[] memory winners = luckydrawContract.getWinners(phase);

        uint256 bonus = ethAmount.mul(luckyDrawRate).div(100).div(winners.length);
        if (winners.length == 0 && bonus > 0){
            transferToFoundation(bonus);
            return;
        }

        for (uint256 i = 0; i < winners.length; i++) {
            address payable addr = winners[i].make_payable();
            addr.transfer(bonus);
            emit LuckydrawSettle(phase, winners[i], bonus);
        }
    }

    function settleTopInvestor (uint256 phase, uint256 ethAmount) internal {
        uint256 bonus = ethAmount.mul(topInvestorRate).div(100);
        if (topInvestor[phase].length == 0 && bonus > 0){
            transferToFoundation(bonus);
            return;
        }

        uint256 len = topInvestor[phase].length;
        uint256[] memory factors = invitationContract.distributeBonus(len);
        for (uint256 i = 0; i < topInvestor[phase].length; i++) {
            address payable addr = topInvestor[phase][i].make_payable();
            uint256 iBonus = bonus.mul(factors[i]).div(len).div(len);
            addr.transfer(iBonus);
            emit InvestorSettle(phase, addr, iBonus);
        }
    }

    function settleInvitation (uint256 phase, uint256 ethAmount) internal {
        uint256 totalBonus = ethAmount.mul(invitationRate).div(100);
        address[] memory winners = invitationContract.getTop(phase);
        if (winners.length == 0 && totalBonus > 0){
            transferToFoundation(totalBonus);
            return;
        }

        uint256 len = winners.length;
        uint256[] memory factors = invitationContract.distributeBonus(len);
        for (uint256 i = 0; i < factors.length; i++) {
            uint256 bonus = totalBonus.mul(factors[i]).div(len).div(len);
            address payable addr = winners[i].make_payable();
            addr.transfer(bonus);
            emit InvitationSettle(phase, winners[i], bonus);
        }
    }

    function distributeCRBonus(uint256 phase) internal {
        if (phase < bonusRate.length || phase >= bonusRate.length + crBonusReleasePhases) {
          return;
        }

        for (uint256 i = 0; i < icexInvestors.length; i++) {
            address addr = icexInvestors[i];
            balances[addr] = balances[addr].add(crBonus[addr]);
            emit Transfer(address(this), addr, crBonus[addr]);
        }
    }
}
"}}