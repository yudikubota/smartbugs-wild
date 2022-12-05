{{
  "language": "Solidity",
  "sources": {
    "/Users/nh2/dev/nazizombies/contracts/ERC20_Mintable.sol": {
      "content": "pragma solidity ^0.5.17;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard ERC20 token (+ minting)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20_Mintable is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    address public minter;

    string public name;
    uint8 public decimals;
    string public symbol;

    event Mint(address indexed to, uint256 amount);

    constructor (string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) public {
        minter = msg.sender;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public returns (bool) {
        require(msg.sender == minter);
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}"
    },
    "/Users/nh2/dev/nazizombies/contracts/IERC20.sol": {
      "content": "pragma solidity ^0.5.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}"
    },
    "/Users/nh2/dev/nazizombies/contracts/MerkleTreeWithHistory.sol": {
      "content": "// https://tornado.cash
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

pragma solidity 0.5.17;

library Hasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) public pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor(uint32 _treeLevels) public {
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);

    for (uint32 i = 1; i < levels; i++) {
      currentZero = hashLeftRight(currentZero, currentZero);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }

    roots[0] = hashLeftRight(currentZero, currentZero);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = Hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = Hasher.MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];

        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }

      currentLevelHash = hashLeftRight(left, right);

      currentIndex /= 2;
    }

    currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    roots[currentRootIndex] = currentLevelHash;
    return nextIndex - 1;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns(bool) {
    if (_root == 0) {
      return false;
    }
    uint32 i = currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}
"
    },
    "/Users/nh2/dev/nazizombies/contracts/ReentrancyGuard.sol": {
      "content": "pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}
"
    },
    "/Users/nh2/dev/nazizombies/contracts/SafeMath.sol": {
      "content": "pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}"
    },
    "/Users/nh2/dev/nazizombies/contracts/Tornado.sol": {
      "content": "// https://anon.credit
// https://anoncredit.eth.link
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*
*
* "Full anonymity is not plausible."
* 
*/

pragma solidity 0.5.17;

import "./MerkleTreeWithHistory.sol";
import "./IERC20.sol";
import "./ERC20_Mintable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}

contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public denomination; // 100 ETH
  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;
  IVerifier public verifier;

  uint256 public _1e18 = 1000000000000000000;
  uint256 public startTime; // epoch time at contract deployment
  uint256 public growthPhaseEndTime; // epoch time of end of growth phase (00:00 PST, July 4th, 2021)
  uint256 public bonusRoundLength; // length of a period in seconds

  uint256 public totalDeposits; // total number of deposits
  uint256 public totalWithdrawals; // total number of withdrawals
  
  mapping(uint256 => BonusPool) public bonusPoolByRound;

  struct BonusPool {
    address creditToken; // credit token address for this round
    uint256 bonusCollected; // total accumulated bonus ETH
    uint256 bonusWithdrawn; // total ETH withdrawn from bonus pool
    uint256 bonusRolledOver; // total ETH rolled over from the previous round
  }
  
  uint256 public baseBonusRate; // % of deposit set aside for bonus pool (unit = bps)
  uint256 public growthBonusRate; // extra % of deposit set aside for growth phase bonus pool (unit = bps)
  ERC20_Mintable public bonusToken; // ANON token generated on every deposit
  address public stakingToken; // ETH/ANON token used to stake and earn bonus rewards

  mapping(address => Staker) public stakers;

  struct Staker {
    uint256 unlockRound;
    uint256 stakingTokenBalance;
  }

  modifier stakingActivated {
    require(stakingToken != address(0), "staking has not been activated");
    _;
  }
 
  uint256 public operatorBonusTokenShare; // the operator's share of bonus tokens issued (10%) (unit = bps)

  // operator can update snark verification key
  // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
  address public operator;
  modifier onlyOperator {
    require(msg.sender == operator, "Only operator can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);
  event Stake(address indexed staker, uint256 amountToStake, uint256 creditsMinted);
  event AddToStake(address indexed staker, uint256 amountToStake, uint256 totalStake, uint256 creditsMinted);
  event Unstake(address indexed staker, uint256 amountUnstaked);
  event CollectBonus(address indexed staker, uint256 creditsToRedeem, uint256 bonusCollected);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _operator operator address (see operator comment above)
  */
  constructor(
    IVerifier _verifier,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _operator,
    uint256 _baseBonusRate,
    uint256 _growthBonusRate,
    uint256 _growthPhaseEndTime,
    uint256 _bonusRoundLength,
    uint256 _operatorBonusTokenShare
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(_denomination > 0, "denomination should be greater than 0");
    startTime = now;
    verifier = _verifier;
    operator = _operator;
    denomination = _denomination;
    baseBonusRate = _baseBonusRate;
    growthBonusRate = _growthBonusRate;
    growthPhaseEndTime = _growthPhaseEndTime;
    bonusRoundLength = _bonusRoundLength;
    operatorBonusTokenShare = _operatorBonusTokenShare;
    bonusToken = new ERC20_Mintable("anon", 18, "ANON");
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(address(bonusToken) != address(0), "token not deployed");
    require(!commitments[_commitment], "The commitment has been submitted");

    uint256 bonusRound = getCurrentBonusRound();

    uint256 depositReserve = _calcDepositReserve();
    uint256 bonusRate = baseBonusRate;

    if (bonusRound == 0) { // growth phase
      bonusRate = bonusRate.add(growthBonusRate);
    }

    uint256 depositBonus = denomination.add(depositReserve).mul(bonusRate).div(10000);
    uint256 depositAmount = denomination.add(depositReserve).add(depositBonus);
      
    require(msg.value >= depositAmount,"deposit amount is insufficient");

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound];
    bonusPool.bonusCollected = bonusPool.bonusCollected.add(depositBonus);
    totalDeposits = totalDeposits.add(1);

    if (bonusRound == 0) { // growth phase
      bonusToken.mint(msg.sender, _1e18);
      bonusToken.mint(operator, _1e18.mul(operatorBonusTokenShare).div(10000));
    }

    uint256 refund = msg.value.sub(depositAmount);
    msg.sender.transfer(refund);

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  function _calcDepositReserve() internal view returns (uint256) {
    uint256 anonSet = totalDeposits.sub(totalWithdrawals);
    return _calcReserveBondingCurve(anonSet);
  }

  function _calcWithdrawalReserve() internal view returns (uint256) {
    if (totalDeposits == totalWithdrawals) {
      return 0;
    }
    uint256 anonSet = totalDeposits.sub(totalWithdrawals).sub(1); // 1 less to match the deposit bonus
    return _calcReserveBondingCurve(anonSet);
  }

  function _calcReserveBondingCurve(uint256 anonSet) internal view returns (uint256) {
    if (anonSet <= 100) {
      // 0 -> 0%; 100 -> 3% (0.03 / anon)
      return denomination.mul(anonSet).mul(300).div(10000).div(100);
    } else if (anonSet > 100 && anonSet <= 1000) {
      // 100 -> 3%; 1,000 -> 12% (0.01 / anon)
      return (denomination.mul(2).add(denomination.mul(anonSet).mul(100).div(10000))).div(100);
    } else if (anonSet > 1000 && anonSet <= 10000) {
      // 1,000 -> 12%; 10,000 -> 39% (0.003 / anon)
      return (denomination.mul(9).add(denomination.mul(anonSet).mul(30).div(10000))).div(100);
    } else {
      // 10,000+ -> 39%
      return denomination.mul(39).div(100);
    }
  }

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _relayerFee, uint256 _refund) external payable nonReentrant {
    require(address(bonusToken) != address(0), "token not deployed");
    uint256 withdrawAmount = denomination.add(_calcWithdrawalReserve());
    require(_relayerFee <= withdrawAmount, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _relayerFee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    
    // sanity checks
    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");

    totalWithdrawals = totalWithdrawals.add(1);

    (bool success, ) = _recipient.call.value(withdrawAmount.sub(_relayerFee))("");
    require(success, "payment to _recipient did not go thru");

    if (_relayerFee > 0) {
      (success, ) = _relayer.call.value(_relayerFee)("");
      require(success, "payment to _relayer did not go thru");
    }
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _relayerFee);
  }

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }

  // open a fresh stake
  function stake(uint256 amount) stakingActivated external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    require(staker.stakingTokenBalance == 0, "user is already staked");
    require(IERC20(stakingToken).transferFrom(msg.sender, address(this), amount), "staking token transfer failed");

    uint256 bonusRound = getCurrentBonusRound();
    staker.unlockRound = bonusRound.add(1);

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) { // first stake in new round
      bonusPool.creditToken = address(new ERC20_Mintable("credit" , 18, "CREDIT"));
    }

    staker.stakingTokenBalance = staker.stakingTokenBalance.add(amount);
    uint256 timeRemaining = getBonusRoundEndingTime(bonusRound).sub(now);
    uint256 creditsToMint = amount.mul(timeRemaining).mul(timeRemaining);
    ERC20_Mintable(bonusPool.creditToken).mint(msg.sender, creditsToMint);
    emit Stake(msg.sender, amount, creditsToMint);
  }

  // add to an existing stake
  function addToStake(uint256 amount) external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    require(staker.stakingTokenBalance > 0, "staker has no balance");
    require(IERC20(stakingToken).transferFrom(msg.sender, address(this), amount), "staking token transfer failed");

    uint256 bonusRound = getCurrentBonusRound();
    require(staker.unlockRound == bonusRound.add(1), "staker is not active in current round");

    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    
    staker.stakingTokenBalance = staker.stakingTokenBalance.add(amount);
    uint256 timeRemaining = getBonusRoundEndingTime(bonusRound).sub(now);
    uint256 creditsToMint = amount.mul(timeRemaining).mul(timeRemaining);
    ERC20_Mintable(bonusPool.creditToken).mint(msg.sender, creditsToMint);
    emit AddToStake(msg.sender, amount, staker.stakingTokenBalance, creditsToMint);
  }

  // withdraw a stake
  function unstake() external {
    require(address(bonusToken) != address(0), "token not deployed");
    Staker storage staker = stakers[msg.sender];
    uint256 bonusRound = getCurrentBonusRound();

    uint256 tokensToUnstake = staker.stakingTokenBalance;
    staker.stakingTokenBalance = 0;

    require(staker.unlockRound <= bonusRound, "staker is locked in to the current round");
    require(IERC20(stakingToken).transfer(msg.sender, tokensToUnstake), "staking token transfer failed");
    emit Unstake(msg.sender, tokensToUnstake);
  }

  function stakerCollectBonus(uint256 creditsToRedeem) external {
    require(address(bonusToken) != address(0), "token not deployed");
    uint256 bonusRound = getCurrentBonusRound();
    require(bonusRound > 0, "no bonus rewards yet");

    BonusPool storage bonusPool = bonusPoolByRound[bonusRound.sub(1)];
    ERC20_Mintable credit = ERC20_Mintable(bonusPool.creditToken);

    require(credit.transferFrom(msg.sender, address(this), creditsToRedeem), "credit token transfer failed");

    if (bonusPool.bonusWithdrawn == 0 && bonusRound > 1) { // first staker to withdraw bonus
      // rollover any remaining balance from the previous bonus pool
      uint256 remainingBonusFromLastRound = getBonusRoundBalance(bonusRound.sub(2));
      bonusPool.bonusCollected = bonusPool.bonusCollected.add(remainingBonusFromLastRound);
      bonusPool.bonusRolledOver = remainingBonusFromLastRound;
      bonusPoolByRound[bonusRound.sub(2)].bonusWithdrawn = bonusPoolByRound[bonusRound.sub(2)].bonusCollected;
    }

    uint256 stakerBonus = bonusPool.bonusCollected.mul(creditsToRedeem).div(credit.totalSupply());
    bonusPool.bonusWithdrawn = bonusPool.bonusWithdrawn.add(stakerBonus);
    msg.sender.transfer(stakerBonus);
    emit CollectBonus(msg.sender, creditsToRedeem, stakerBonus);
  }

  function setStakingToken(address _stakingToken) external onlyOperator {
    require(stakingToken == address(0), "staking token already set");
    require(_stakingToken != address(0), "must provide staking token address");
    stakingToken = _stakingToken;
  }

  /** @dev operator can change his address */
  function changeOperator(address _newOperator) external onlyOperator {
    operator = _newOperator;
  }

  function getCurrentBonusRound() public view returns (uint256) {
    if (now < growthPhaseEndTime) {
      return 0;
    } else {
      return (now.sub(growthPhaseEndTime)).div(bonusRoundLength).add(1);
    }
  }

  function getBonusRoundEndingTime(uint256 bonusRound) public view returns (uint256) {
    if (bonusRound == 0) {
      return growthPhaseEndTime;
    } else {
      return growthPhaseEndTime.add((bonusRound).mul(bonusRoundLength));
    }
  }

  function getDepositAmount() public view returns (uint256) {
    uint256 bonusRound = getCurrentBonusRound();
    uint256 depositReserve = _calcDepositReserve();
    uint256 bonusRate = baseBonusRate;

    if (bonusRound == 0) { // growth phase
      bonusRate = bonusRate.add(growthBonusRate);
    }

    uint256 depositBonus = (denomination.add(depositReserve)).mul(bonusRate).div(10000);
    uint256 depositAmount = denomination.add(depositReserve).add(depositBonus);
    return depositAmount;
  }

  function getWithdrawalAmount() public view returns (uint256) {
    uint256 withdrawalReserve = _calcWithdrawalReserve();
    uint256 withdrawalAmount = denomination.add(withdrawalReserve);
    return withdrawalAmount;

  }

  function getReservePool() public view returns (uint256) {
    uint256 bonusRound = getCurrentBonusRound();
    uint256 totalBonusRoundBalance = getBonusRoundBalance(bonusRound);

    if (bonusRound > 0) {
      totalBonusRoundBalance = totalBonusRoundBalance.add(getBonusRoundBalance(bonusRound.sub(1)));
    }

    if (bonusRound > 1) { 
      totalBonusRoundBalance = totalBonusRoundBalance.add(getBonusRoundBalance(bonusRound.sub(2)));
    }

    return address(this).balance.sub(denomination.mul(totalDeposits.sub(totalWithdrawals))).sub(totalBonusRoundBalance);
  }

  function getBonusRoundBalance(uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    return bonusPool.bonusCollected.sub(bonusPool.bonusWithdrawn);
  }

  function getStakerCreditsByRound(address staker, uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) {
     return 0;
    }
    return ERC20_Mintable(bonusPool.creditToken).balanceOf(staker);
  }

  function getTotalCreditsByRound(uint256 bonusRound) public view returns (uint256) {
    BonusPool memory bonusPool = bonusPoolByRound[bonusRound];
    if (bonusPool.creditToken == address(0)) {
     return 0;
    }
    return ERC20_Mintable(bonusPool.creditToken).totalSupply();
  }

  function getDepositReserve() public view returns (uint256) {
    return _calcDepositReserve();
  }

  function getWithdrawalReserve() public view returns (uint256) {
    return _calcWithdrawalReserve();
  }

  function getReserveBondingCurve(uint256 anonSet) public view returns (uint256) {
    return _calcReserveBondingCurve(anonSet);
  }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {
      "": {
        "Hasher": "0x83584f83f26aF4eDDA9CBe8C730bc87C364b28fe"
      }
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}