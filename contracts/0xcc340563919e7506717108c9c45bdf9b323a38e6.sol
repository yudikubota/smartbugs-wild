{{
  "language": "Solidity",
  "sources": {
    "/home/aaron/fct/TheSink/coupons/contracts/DEE.sol": {
      "content": "pragma solidity ^0.6.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEE {
    using SafeMath for uint256;
    uint256 public unsettled;
    uint256 public staked;
    uint airDropped;
    uint8 constant toAirdrop = 200;
    uint public tokenClaimCount;

    struct Fees {
        uint stake;
        uint dev;
        uint farm;
        uint airdrop;
    }
    Fees fees;
    address payable public admin;
    address payable public partnership;
    address public TheStake;
    address public UniswapPair;
    address public bounce;
    address public lockedTokens;

    address [] assets;
    address [] tokensClaimable;
    address payable[] public shareHolders;
    struct Participant {
        bool staking;
        uint256 stake;
    }

    address[toAirdrop] airdropList;
    mapping(address => Participant) public staking;
    mapping(address => mapping(address => uint256)) public payout;
    mapping(address => uint256) public ethPayout;
    mapping(address => uint256) public tokenUnsettled;
    mapping(address => uint256) public totalTokensClaimable;

    IERC20 LPToken;

    receive() external payable { }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the admin can do this");
        _;
    }

    constructor(address _TheStake)  public {
        admin = msg.sender;
        fees.stake = 40;
        fees.dev = 10;
        fees.airdrop = 40;
        fees.farm = 60;
        TheStake = _TheStake;
    }

    /* Admin Controls */
    function changeAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setPartner(address payable _partnership) external onlyAdmin {
        partnership = _partnership;
    }

    function setUniswapPair(address _uniswapPair) external onlyAdmin {
        UniswapPair = _uniswapPair;
    }

    function addAsset(address _asset) external onlyAdmin {
        assets.push(_asset);
    }

    function remAsset(address _asset) external onlyAdmin {
        for(uint i = 0; i < assets.length ; i++ ) {
            if(assets[i] == _asset) delete assets[i];
        }
    }

    function setStake(address _stake) external onlyAdmin {
        require(TheStake == address(0), "This can only be done once.");
        TheStake = _stake;
    }

    function setBounce(address _bounce) external onlyAdmin {
        require(bounce == address(0), "This can only be done once.");
        bounce = _bounce;
    }
    
    function setLockedTokens(address _contract) external onlyAdmin {
        lockedTokens = _contract;
    }    

    function setLPToken(address _lptokens) external onlyAdmin {
        LPToken = IERC20(_lptokens);
    }
    
    function addPendingTokenRewards(uint256 _transferFee, address _token) external {
        require(assetFound(msg.sender) == true, 'Only Assets can Add Fees.');
        uint topay = _transferFee.add(tokenUnsettled[_token]);

        if(topay < 10000 || topay < shareHolders.length || shareHolders.length == 0)
            tokenUnsettled[_token] = topay;
        else {
            tokenUnsettled[_token] = 0;
            payout[admin][_token] =  payout[admin][_token].add(percent(fees.dev*10000/totalFee(), topay) );

            addClaimableToken(_token, topay);
            addRecentTransactor(tx.origin);

            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(10000) / staked;
               if(address(LPToken) != address(0)) {
                    uint farmPerc = LPToken.balanceOf(hodler).mul(10000) / LPtotalSupply();
                    if(farmPerc > 0) payout[hodler][_token] = payout[hodler][_token].add(percent(farmPerc, percent(fees.farm*10000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.airdrop*10000/totalFee(), topay)));    
               }
               payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.stake*10000/totalFee(), topay)));
            }
        }
    }

    function addPendingETHRewards() external payable {
        require(assetFound(msg.sender) == true, 'Only Assets can Add Fees.');
        uint topay = unsettled.add(msg.value);
        if(topay < 10000 || topay < shareHolders.length || shareHolders.length == 0)
            unsettled = topay;
        else {
            unsettled = 0;
            ethPayout[admin] = ethPayout[admin].add(percent(fees.dev*10000/totalFee(), topay));
             
            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(10000) / staked;
               if(address(LPToken) != address(0)) {
                   uint farmPerc = LPToken.balanceOf(hodler).mul(10000) / LPtotalSupply();
                   if(farmPerc > 0) ethPayout[hodler] = ethPayout[hodler].add(percent(farmPerc, percent(fees.farm*10000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.airdrop*10000/totalFee(), topay)));    
               }               
               ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.stake*10000/totalFee(), topay)));
            }
        }
    }

    function stake(uint256 _amount) external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");
        IERC20 _stake = IERC20(TheStake);
        _stake.transferFrom(msg.sender, address(this), _amount);
        staking[msg.sender].stake = staking[msg.sender].stake.add(_amount);
        staked = staked.add(_amount);
        if(staking[msg.sender].staking == false){
            staking[msg.sender].staking = true;
            shareHolders.push(msg.sender);
        }
    }
 
    function unstake(uint _amount) external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");        
        IERC20 _stake = IERC20(TheStake);
        if(_amount == 0) _amount = staking[msg.sender].stake;
        claimBoth();
        require(staking[msg.sender].stake >= _amount, "Trying to remove too much stake");
        staking[msg.sender].stake = staking[msg.sender].stake.sub(_amount);
        staked = staked.sub(_amount);
        if(staking[msg.sender].stake <= 0) {
            staking[msg.sender].staking = false;
            for(uint i = 0 ; i < shareHolders.length ; i++){
                if(shareHolders[i] == msg.sender){
                    delete shareHolders[i];
                    break;
                }
            }
        }
        _stake.transfer(msg.sender, _amount);
    }

    function claim() public {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");        
        for(uint i = 0; i < tokensClaimable.length; i++) {
            address _claimToken = tokensClaimable[i];
            if(payout[msg.sender][_claimToken] > 0) {
                uint256 topay = payout[msg.sender][_claimToken];
                delete payout[msg.sender][_claimToken];
                IERC20(_claimToken).transfer(msg.sender, topay);
            }
        }
    }

    function claimEth() public payable {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");
        uint topay = ethPayout[msg.sender];
        require(ethPayout[msg.sender] > 0, "NO PAYOUT");
        delete ethPayout[msg.sender];
        msg.sender.transfer(topay);
    }

    function claimBoth() public payable {
        if(ethPayout[msg.sender] > 0) claimEth();
        claim();
    }

    function burned(address _token) public view returns(uint256) {
        if(_token == TheStake) return IERC20(_token).balanceOf(address(this)).sub(staked);
        return IERC20(_token).balanceOf(address(this));
    }

    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256){
        if( _amount < 10000 ||
            _sender == address(this) ||
            _sender == UniswapPair ||
            _sender == admin ||
            _sender == bounce)
            return(_amount, 0);
        uint fee_amount = percent(totalFee(), _amount);
        return (_amount.sub(fee_amount), fee_amount);
    }

    function totalFee() private view returns(uint) {
        return fees.airdrop + fees.dev + fees.stake + fees.farm;
    }

    function eligableForAirdrop(address _addr) private view returns (bool) {
        for(uint i; i < toAirdrop; i++) {
            if(airdropList[i] == _addr) return true;
        }
        return false;
    }

    function assetFound(address _asset) private view returns(bool) {
        for(uint i = 0; i < assets.length; i++) {
            if( assets[i] == _asset) return true;
        }
        return false;
    }
    
    function addClaimableToken(address _token, uint256 _amount) private {
        totalTokensClaimable[_token] = totalTokensClaimable[_token].add(_amount);
        for(uint i = 0; i < tokensClaimable.length ; i++ ) {
            if(_token == tokensClaimable[i]) return;
        }
        tokensClaimable.push(_token);
    }

    function addRecentTransactor(address _actor) internal {
        airdropList[airDropped] = _actor;
        airDropped += 1;
        if(airDropped >= toAirdrop) airDropped = 0;
    }

    function LPtotalSupply() internal view returns (uint256) {
        return LPToken.totalSupply().sub(IERC20(LPToken).balanceOf(lockedTokens));
    }
    
    function percent(uint256 perc, uint256 whole) private pure returns(uint256) {
        uint256 a = (whole / 10000).mul(perc);
        return a;
    }

}"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

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
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {
      "": {}
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