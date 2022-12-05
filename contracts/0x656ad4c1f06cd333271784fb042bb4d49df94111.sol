{{
  "language": "Solidity",
  "sources": {
    "/home/aaron/fun/solidity/contracts/DEE.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Fountain.sol";

contract DEE {
    using SafeMath for uint256;

    event Staked(address indexed from, uint256 amountFUN);
    event Unstaked(address indexed to, uint256 amountFUN);
    event Claimed(address indexed to, uint256 amountETH);
    event FeePaid(address indexed from, uint256 amount, address indexed token);
    event ETHFeePaid(address indexed from, uint256 amount);

    uint256 public unsettled;
    uint256 public staked;
    uint airDropped;
    uint8 constant toAirdrop = 200;
    uint public tokenClaimCount;

    struct Fees {
        uint8 stake;
        uint8 dev;
        uint8 farm;
        uint8 airdrop;
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

    constructor()  public {
        admin = msg.sender;
        fees.stake = 4;
        fees.dev = 1;
        fees.airdrop = 3;
        fees.farm = 7;
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

        if(topay < 1000 || topay < shareHolders.length || shareHolders.length == 0)
            tokenUnsettled[_token] = topay;
        else {
            tokenUnsettled[_token] = 0;
            payout[admin][_token] =  payout[admin][_token].add(percent(fees.dev*1000/totalFee(), topay) );

            addClaimableToken(_token, topay);
            addRecentTransactor(tx.origin);

            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(1000) / staked;
               if(address(LPToken) != address(0)) {
                    uint farmPerc = LPToken.balanceOf(hodler).mul(1000) / LPtotalSupply();
                    if(farmPerc > 0) payout[hodler][_token] = payout[hodler][_token].add(percent(farmPerc, percent(fees.farm*1000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.airdrop*1000/totalFee(), topay)));    
               }
               payout[hodler][_token] = payout[hodler][_token].add(percent(perc, percent(fees.stake*1000/totalFee(), topay)));
            }
            emit FeePaid(msg.sender, topay, _token);
        }
    }

    function addPendingETHRewards() external payable {
        require(assetFound(msg.sender) == true, 'Only Assets can Add Fees.');
        uint topay = unsettled.add(msg.value);
        if(topay < 1000 || topay < shareHolders.length || shareHolders.length == 0)
            unsettled = topay;
        else {
            unsettled = 0;
            ethPayout[admin] = ethPayout[admin].add(percent(fees.dev*1000/totalFee(), topay));
             
            for(uint i = 0 ; i < shareHolders.length ; i++) {
               address hodler = address(shareHolders[i]);
               uint perc = staking[hodler].stake.mul(1000) / staked;
               if(address(LPToken) != address(0)) {
                   uint farmPerc = LPToken.balanceOf(hodler).mul(1000) / LPtotalSupply();
                   if(farmPerc > 0) ethPayout[hodler] = ethPayout[hodler].add(percent(farmPerc, percent(fees.farm*1000/totalFee(), topay)));
               }
               if(eligableForAirdrop(hodler) ) {
                    ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.airdrop*1000/totalFee(), topay)));    
               }               
               ethPayout[hodler] = ethPayout[hodler].add(percent(perc, percent(fees.stake*1000/totalFee(), topay)));
            }
            emit ETHFeePaid(msg.sender, topay);
        }
    }

    function stake(uint256 _amount) external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");
        Fountain _stake = Fountain(TheStake);
        _stake.transferFrom(msg.sender, address(this), _amount);
        staking[msg.sender].stake = staking[msg.sender].stake.add(_amount);
        staked = staked.add(_amount);
        if(staking[msg.sender].staking == false){
            staking[msg.sender].staking = true;
            shareHolders.push(msg.sender);
        }
        emit Staked(msg.sender, _amount);
    }
 
    function unstake() external {
        require(msg.sender == tx.origin, "LIMIT_CONTRACT_INTERACTION");        
        Fountain _stake = Fountain(TheStake);
        uint256 _amount = staking[msg.sender].stake;
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
        emit Unstaked(msg.sender, _amount);
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
        emit Claimed(msg.sender, topay);
    }

    function claimBoth() public payable {
        if(ethPayout[msg.sender] > 0) claimEth();
        claim();
    }

    function burned(address _token) public view returns(uint256) {
        if(_token == TheStake) return Fountain(_token).balanceOf(address(this)).sub(staked);
        return IERC20(_token).balanceOf(address(this));
    }

    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256){
        if( _amount < 1000 ||
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
        uint256 a = (whole / 1000).mul(perc);
        return a;
    }

}"
    },
    "/home/aaron/fun/solidity/contracts/Fountain.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IDEE.sol";

contract Fountain is Context, IERC20 {
    using SafeMath for uint256;
    
    address payable shareHolders;
    address public admin;

    address[] cantBePausedList;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool public started = false; //Not started
    bool public ended = false; //Not ended
    bool public paused = true; //Start paused
    address[3] minters;

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the admin can do this");
        _;
    }

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (address [] memory _minters, address payable _shareHolder, address [] memory _unpausable) public {
        _name = "Fountain.Services";
        _symbol = "FUN";
        _decimals = 18;
        admin = msg.sender;
        cantBePausedList.push(msg.sender);
        for(uint i = 0; i < _minters.length ; i++) minters[i] = _minters[i];
        for(uint i = 0; i < _unpausable.length ; i++) cantBePausedList.push(_unpausable[i]);
        shareHolders = _shareHolder;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function wipePauseList() external onlyAdmin {
        delete cantBePausedList;
    }
    
    function unlockPause() external onlyAdmin {
        paused = false;
    }
     
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * Via cVault Finance
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(paused == false || cantBePaused(msg.sender), "Paused transfers for launch");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount);
        IDEE hodlers = IDEE(shareHolders);
        (uint256 transferToAmount, uint256 transferFee) = hodlers.calculateAmountsAfterFee(msg.sender, amount);

        // Addressing a broken checker contract
        require(transferToAmount.add(transferFee) == amount, "Math broke, does gravity still work?");

        _balances[recipient] = _balances[recipient].add(transferToAmount);
        emit Transfer(sender, recipient, transferToAmount);
        
        if(transferFee > 0 && shareHolders != address(0)){
            _balances[shareHolders] = _balances[shareHolders].add(transferFee);
            emit Transfer(sender, shareHolders, transferFee);
            if(shareHolders != address(0)){
                hodlers.addPendingTokenRewards(transferFee, address(this));
            }
        }
    }

       /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }      

    function cantBePaused(address _addr) internal view returns (bool) {
        for(uint i; i < cantBePausedList.length ; i++) {
            if(cantBePausedList[i] == _addr) return true;
        }
        return false;
    }

    modifier onlyMinters {
        bool found = false;
        for(uint i = 0; i < minters.length; i++) {
            if(minters[i] == msg.sender) { found = true; break; }
        }
        require(found, 'ONLY MINTERS CAN MINT');
        _;
    }

    function mint(address account, uint256 amount) external onlyMinters {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinters {
        _burn(account, amount);
    }

}
"
    },
    "/home/aaron/fun/solidity/contracts/interfaces/IDEE.sol": {
      "content": "pragma solidity >=0.6.2;

interface IDEE {
    function addPendingETHRewards() external payable;
    function addPendingTokenRewards(uint256 _transferFee, address _token) external;
    function calculateAmountsAfterFee(address _sender, uint _amount) external view returns(uint256, uint256);
}"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
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