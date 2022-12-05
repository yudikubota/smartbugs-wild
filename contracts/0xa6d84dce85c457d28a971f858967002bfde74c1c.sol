{{
  "language": "Solidity",
  "sources": {
    "/Users/akshaycm/Documents/rfits-token/contracts/SyntLayerToken.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
//Import abstractions
import { IUniswapV2Router02, IBalancer, IFreeFromUpTo, Ownable , SafeMath } from './abstractions/Balancer.sol';
import { REFLECTBase } from './abstractions/ReflectToken.sol';
import './libraries/TransferHelper.sol';
//Import uniswap interfaces
import './interfaces/IUniswapFactory.sol';
import './interfaces/IUniswapV2Pair.sol';

contract SyntLayer is REFLECTBase {
    using SafeMath for uint256;

    event Rebalance(uint256 tokenBurnt);
    event RewardLiquidityProviders(uint256 liquidityRewards);

    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapV2Pair = address(0);
    address payable public treasury;

    mapping(address => bool) public unlockedAddr;

    IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
    IUniswapV2Pair iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    uint256 public minRebalanceAmount;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval;
    uint256 public liqAddBalance = 0;

    uint256 constant INFINITE_ALLOWANCE = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;


    uint256 public lpUnlocked;
    bool public locked;
    //Use CHI to save on gas on rebalance
    bool public useCHI = false;
    bool approved = false;
    bool doAddLiq = true;

    /// @notice Liq Add Cut fee at 1% initially
    uint256 public LIQFEE = 100;
    /// @notice LiqLock is set at 0.2%
    uint256 public LIQLOCK = 20;
    /// @notice Rebalance amount is 2.5%
    uint256 public REBALCUT = 250;
    /// @notice Caller cut is at 2%
    uint256 public CALLCUT = 200;
    /// @notice Fee BASE
    uint256 constant public BASE = 10000;

    IBalancer balancer;

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *
                           msg.data.length;
        if(useCHI){
            if(chi.balanceOf(address(this)) > 0) {
                chi.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
            }
            else {
                chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
            }
        }
    }

    constructor(address balancerAddr) public {
        lastRebalance = block.timestamp;
        rebalanceInterval = 1 seconds;
        lpUnlocked = block.timestamp + 90 days;
        minRebalanceAmount = 20 ether;
        treasury = msg.sender;
        balancer = IBalancer(balancerAddr);
        locked = true;
        unlockedAddr[msg.sender] = true;
        unlockedAddr[balancerAddr] = true;
        isFeeless[address(this)] = true;
        isFeeless[balancerAddr] = true;
        isFeeless[msg.sender] = true;
    }

    function setBalancer(address newBalancer) public onlyOwner {
        balancer = IBalancer(newBalancer);
        isFeeless[newBalancer] = true;
        unlockedAddr[newBalancer] = true;
    }

    /* Fee getters */
    function getLiqAddBudget(uint256 amount) public view returns (uint256) {
        return amount.mul(LIQFEE).div(BASE);
    }

    function getLiqLockBudget(uint256 amount) public view returns (uint256) {
        return amount.mul(LIQLOCK).div(BASE);
    }


    function getRebalanceCut(uint256 amount) public view returns (uint256) {
        return amount.mul(REBALCUT).div(BASE);
    }

    function getCallerCut(uint256 amount) public view returns (uint256) {
        return amount.mul(CALLCUT).div(BASE);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        //First remove feelet set for current owner
        toggleFeeless(owner());
        //Remove unlock flag for current owner
        toggleUnlockable(owner());
        //Add feeless for new owner
        toggleFeeless(newOwner);
        //Add unlocked for new owner
        toggleUnlockable(newOwner);
        //Transfer ownersip
        super.transferOwnership(newOwner);
    }

    // transfer function with liq add and liq rewards
    function _transfer(address from, address to, uint256 amount) internal override  {
        // calculate liquidity lock amount
        // dont transfer burn from this contract
        // or can never lock full lockable amount
        if(locked && !unlockedAddr[from])
            revert("Locked until end of distribution");

        if (!isFeeless[from] && !isFeeless[to] && !locked) {
            uint256 liquidityLockAmount = getLiqLockBudget(amount);
            uint256 LiqPoolAddition = getLiqAddBudget(amount);
            //Transfer to liq add amount
            super._transfer(from, address(this), LiqPoolAddition);
            liqAddBalance = liqAddBalance.add(LiqPoolAddition);
            //Transfer to liq lock amount
            super._transfer(from, address(this), liquidityLockAmount);
            //Amount that is ending up after liq rewards and liq budget
            uint256 totalsub = LiqPoolAddition.add(liquidityLockAmount);
            super._transfer(from, to, amount.sub(totalsub));
        }
        else {
            super._transfer(from, to, amount);
        }
    }

    // receive eth from uniswap swap
    receive () external payable {}

    function initPair() public {
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        //Set uniswap pair interface
        iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    }

    function setUniPair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        iuniswapV2Pair = IUniswapV2Pair(uniswapV2Pair);
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function setTreasury(address treasuryN) public onlyOwner {
        treasury = payable(treasuryN);
        balancer.setTreasury(treasuryN);
    }

    /* Fee setters */
    function setLiqFee(uint newFee) public onlyOwner {
        LIQFEE = newFee;
    }
    function setLiquidityLockCut(uint256 newFee) public onlyOwner {
        LIQLOCK = newFee;
    }

    function setRebalanceCut(uint256 newFee) public onlyOwner {
        REBALCUT = newFee;
    }
    function setCallerRewardCut(uint256 newFee) public onlyOwner {
        CALLCUT = newFee;
    }

    function toggleCHI() public onlyOwner {
        useCHI = !useCHI;
    }

    function setRebalanceInterval(uint256 _interval) public onlyOwner {
        rebalanceInterval = _interval;
    }

    function _transferLP(address dest,uint256 amount) internal{
        iuniswapV2Pair.transfer(dest, amount);
    }

    function unlockLPPartial(uint256 amount) public onlyOwner {
        require(block.timestamp > lpUnlocked, "Not unlocked yet");
        _transferLP(msg.sender,amount);
    }

    function unlockLP() public onlyOwner {
        require(block.timestamp > lpUnlocked, "Not unlocked yet");
        uint256 amount = iuniswapV2Pair.balanceOf(address(this));
        _transferLP(msg.sender, amount);
    }

    function toggleFeeless(address _addr) public onlyOwner {
        isFeeless[_addr] = !isFeeless[_addr];
    }

    function toggleUnlockable(address _addr) public onlyOwner {
        unlockedAddr[_addr] = !unlockedAddr[_addr];
    }

    function setMinRebalanceAmount(uint256 amount_) public onlyOwner {
        minRebalanceAmount = amount_;
    }

    function rebalanceable() public view returns (bool) {
        return block.timestamp > lastRebalance.add(rebalanceInterval);
    }

    function hasMinRebalanceBalance(address addr) public view returns (bool) {
        return balanceOf(addr) >= minRebalanceAmount;
    }

    function _rewardLiquidityProviders(uint256 liquidityRewards) private {
        super._transfer(address(this), uniswapV2Pair, liquidityRewards);
        iuniswapV2Pair.sync();
        emit RewardLiquidityProviders(liquidityRewards);
    }

    function remLiquidity(uint256 lpAmount) private returns(uint ETHAmount) {
        iuniswapV2Pair.approve(uniswapV2Router, lpAmount);
        (ETHAmount) = router
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                lpAmount,
                0,
                0,
                address(balancer),
                block.timestamp
            );
    }

    function ApproveInf(address tokenT,address spender) internal{
        TransferHelper.safeApprove(tokenT,spender,INFINITE_ALLOWANCE);
    }

    function toggleAddLiq() public onlyOwner {
        doAddLiq = !doAddLiq;
    }

    function rebalanceLiquidity() public discountCHI {
        require(hasMinRebalanceBalance(msg.sender), "!hasMinRebalanceBalance");
        require(rebalanceable(), '!rebalanceable');
        lastRebalance = block.timestamp;

        if(!approved) {
            ApproveInf(address(this),uniswapV2Router);
            ApproveInf(uniswapV2Pair,uniswapV2Router);
            approved = true;
        }
        //Approve CHI incase its enabled
        if(useCHI) ApproveInf(address(chi),address(chi));
        // lockable supply is the token balance of this contract minus the liqaddbalance
        if(lockableSupply() > 0)
            _rewardLiquidityProviders(lockableSupply());

        uint256 amountToRemove = getRebalanceCut(iuniswapV2Pair.balanceOf(address(this)));
        // Sell half of balance tokens to eth and add liq
        if(balanceOf(address(this)) >= liqAddBalance && liqAddBalance > 0 && doAddLiq) {
            //Send tokens to balancer
            super._transfer(address(this),address(balancer),liqAddBalance);
            require(balancer.AddLiq(),"!AddLiq");
            liqAddBalance = 0;
        }
        // needed in case contract already owns eth
        remLiquidity(amountToRemove);
        uint _locked = balancer.rebalance(msg.sender);
        //Sync after changes
        iuniswapV2Pair.sync();
        emit Rebalance(_locked);
    }

    // returns token amount
    function lockableSupply() public view returns (uint256) {
        return balanceOf(address(this)) > 0 ? balanceOf(address(this)).sub(liqAddBalance,"underflow on lockableSupply") : 0;
    }

    // returns token amount
    function lockedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = iuniswapV2Pair.totalSupply();
        uint256 lpBalance = lockedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _lockedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _lockedSupply;
    }

    // returns token amount
    function burnedSupply() external view returns (uint256) {
        uint256 lpTotalSupply = iuniswapV2Pair.totalSupply();
        uint256 lpBalance = burnedLiquidity();
        uint256 percentOfLpTotalSupply = lpBalance.mul(1e12).div(lpTotalSupply);

        uint256 uniswapBalance = balanceOf(uniswapV2Pair);
        uint256 _burnedSupply = uniswapBalance.mul(percentOfLpTotalSupply).div(1e12);
        return _burnedSupply;
    }

    // returns LP amount, not token amount
    function burnableLiquidity() public view returns (uint256) {
        return iuniswapV2Pair.balanceOf(address(this));
    }

    // returns LP amount, not token amount
    function burnedLiquidity() public view returns (uint256) {
        return iuniswapV2Pair.balanceOf(address(0));
    }

    // returns LP amount, not token amount
    function lockedLiquidity() public view returns (uint256) {
        return burnableLiquidity().add(burnedLiquidity());
    }
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/abstractions/Balancer.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import { Ownable, SafeMath } from '../interfaces/CommonImports.sol';
import { IERC20Burnable } from '../interfaces/IERC20Burnable.sol';
import '../interfaces/IUniswapV2Router02.sol';
import '../interfaces/IBalancer.sol';

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract BalancerNew is Ownable, IBalancer {
    using SafeMath for uint256;

    address internal UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address payable public override treasury;
    IERC20Burnable token;
    IUniswapV2Router02 routerInterface = IUniswapV2Router02(UniRouter);
    address internal WETH = routerInterface.WETH();

    constructor() public {
        treasury = msg.sender;
    }

    function setToken(address tokenAddr) public onlyOwner {
        token = IERC20Burnable(tokenAddr);
    }

    function setTreasury(address treasuryN) external override{
        require(msg.sender == address(token), "only token");
        treasury = payable(treasuryN);
    }

    receive () external payable {}

    /** Path stuff **/
    function getPath(address tokent,bool isSell) internal view returns (address[] memory path){
        path = new address[](2);
        path[0] = isSell ? tokent : WETH;
        path[1] = isSell ? WETH : tokent;
        return path;
    }

    function getSellPath(address tokent) public view returns (address[] memory path) {
        path = getPath(tokent,true);
    }

    function getBuyPath(address tokent) public view returns (address[] memory path){
        path = getPath(tokent,false);
    }
    /** Path stuff end **/

    function rebalance(address rewardRecp) external override returns (uint256) {
        require(msg.sender == address(token), "only token");
        swapEthForTokens();
        uint256 lockableBalance = token.balanceOf(address(this));
        uint256 callerReward = token.getCallerCut(lockableBalance);
        token.transfer(rewardRecp, callerReward);
        token.burn(lockableBalance.sub(callerReward,"Underflow on burn"));
        return lockableBalance.sub(callerReward,"underflow on return");
    }

    function swapEthForTokens() private {

        uint256 treasuryAmount = token.getCallerCut(address(this).balance);
        (bool success,) = treasury.call{value: treasuryAmount}("");
        require(success,"treasury send failed");

        routerInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
                0,
                getBuyPath(address(token)),
                address(this),
                block.timestamp.add(200)
            );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        //Approve before swap
        token.approve(UniRouter,tokenAmount);
        routerInterface.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                getSellPath(address(token)),
                address(this),
                block.timestamp.add(200)
        );
    }



    function addLiq(uint256 tokenAmount,uint256 ethamount) private {
        //Approve before adding liq
        token.approve(UniRouter,tokenAmount);
        routerInterface.addLiquidityETH{value:ethamount}(
            address(token),
            tokenAmount,
            0,
            ethamount.div(2),//Atleast half of eth should be added
            address(token),
            block.timestamp.add(200)
        );
    }

    function AddLiq() external override returns (bool) {
        //Sell half of the amount to ETH
        uint256 tokenAmount  = token.balanceOf(address(this)).div(2);
        //Swap half of it to eth
        swapTokensForETH(tokenAmount);
        //Add liq with remaining eth and tokens
        addLiq(token.balanceOf(address(this)),address(this).balance);
        //If any eth remains swap to token
        if(address(this).balance > 0)
            swapEthForTokens();
        return true;
    }

}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/abstractions/ReflectToken.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import { Ownable, SafeMath } from './Balancer.sol';
import { IERC20 } from '../interfaces/IERC20Burnable.sol';

contract REFLECTBase is Ownable ,IERC20{
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public isFeeless;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000 ether;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = 'SyntLayer';
    string private _symbol = 'SYNL';
    uint8 private _decimals = 18;

    event Redestributed(address from, uint256 t, uint256 rAmount, uint256 tAmount);

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        if (isFeeless[sender] || isFeeless[recipient]) {
            rTransferAmount = rTransferAmount.add(rFee);
            tTransferAmount = tTransferAmount.add(tFee);
        } else {
            _reflectFee(rFee, tFee);
            emit Redestributed(sender, 1, rAmount, tAmount);
        }

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        if (isFeeless[sender] || isFeeless[recipient]) {
            rTransferAmount = rTransferAmount.add(rFee);
            tTransferAmount = tTransferAmount.add(tFee);
        } else {
            _reflectFee(rFee, tFee);
            emit Redestributed(sender, 2, rAmount, tAmount);
        }

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        if (isFeeless[sender] || isFeeless[recipient]) {
            rTransferAmount = rTransferAmount.add(rFee);
            tTransferAmount = tTransferAmount.add(tFee);
        } else {
            _reflectFee(rFee, tFee);
            emit Redestributed(sender, 3, rAmount, tAmount);
        }

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        if (isFeeless[sender] || isFeeless[recipient]) {
            rTransferAmount= rTransferAmount.add(rFee);
            tTransferAmount = tTransferAmount.add(tFee);
        } else {
            _reflectFee(rFee, tFee);
            emit Redestributed(sender, 4, rAmount, tAmount);
        }

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
        _rOwned[account] = _rOwned[account].sub(amount, "ERC20: burn amount exceeds balance");
        _tTotal = _tTotal.sub(amount, "ERC20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}
"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/CommonImports.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/IBalancer.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
interface IBalancer {
  function treasury (  ) external view returns ( address payable );
  function setTreasury ( address treasuryN ) external;
  function rebalance ( address rewardRecp ) external returns ( uint256 );
  function AddLiq (  ) external returns (bool);
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/IERC20Burnable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import {IERC20} from '../interfaces/CommonImports.sol';
interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function getLiqAddBudget(uint256 amount) external view returns (uint256);
    function getCallerCut(uint256 amount) external view returns (uint256);
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/IUniswapFactory.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/IUniswapV2Pair.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import { IERC20 } from './IERC20Burnable.sol';
interface IUniswapV2Pair is IERC20 {
    function sync() external;
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/interfaces/IUniswapV2Router02.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external payable;
    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}"
    },
    "/Users/akshaycm/Documents/rfits-token/contracts/libraries/TransferHelper.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferWithReturn(address token, address to, uint value) internal returns (bool) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

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

pragma solidity >=0.6.0 <0.8.0;

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
      "enabled": true,
      "runs": 10000
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