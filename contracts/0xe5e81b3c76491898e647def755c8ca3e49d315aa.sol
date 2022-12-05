{{
  "language": "Solidity",
  "sources": {
    "contracts/DRFLord.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IWETH.sol";
import "./interfaces/IDRF.sol";

contract DRFLord is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed account, uint256 ethAmount, uint256 lpAmount);
    event Withdrawn(address indexed account, uint256 drfAmount, uint256 ethAmount, uint256 lpAmount);
    event Claimed(address indexed account, uint256 ethAmount, uint256 lpAmount);
    event Halved(uint256 rewardAllocation);
    event Rebalanced();
    event SwappedSDRF(uint256 amount);

    bool private _initialized;

    IUniswapV2Factory uniswapFactory;
    IUniswapV2Router02 uniswapRouter;
    address weth;
    address drf;
    address sdrf;
    address sdrfFarm;
    address payable devTreasury;
    address pairAddress;

    bool public isFarmOpen = false;
    uint256 public farmOpenTime;

    uint256 private constant MAX = uint256(- 1);
    uint256 public constant INITIAL_PRICE = 4000;
    uint256 public maxStake = 25 ether;

    uint256 public rewardAllocation;
    uint256 public rewardRate;
    uint256 public constant rewardDuration = 15 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public finishTime;

    struct AccountInfo {
        uint256 balance;
        uint256 peakBalance;
        uint256 withdrawTime;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }

    /// @notice Account info
    mapping(address => AccountInfo) public accountInfos;

    /// @notice Peak LP token balance
    uint256 public peakPairTokenBalance;

    /// @dev Total staked token
    uint256 private _totalSupply;

    /// @notice Principal supply is used to generate perpetual yield
    /// @dev Used to give liquidity provider in liquidity pair rewards
    /// If this value is not zero, it means the principal is not used, and still exist in lord contract
    uint256 public principalSupply;

    /// @notice Marketing funds
    uint256 public marketingSupply;

    /// @notice Sale supply
    uint256 public saleSupply;

    /// @notice Lend supply
    uint256 public lendSupply;

    /// @notice Swappable DRF for sDRF
    uint256 public swappableSupply;

    /// @notice Deposited DRF from SDRF Farm
    uint256 public sdrfFarmDepositSupply;

    /// @notice Burned supply that locked forever
    uint256 public burnSupply;

    /// @notice Drift liquidity threshold
    uint256 public driftThreshold = 75;

    /// @notice Brake liquidity threshold
    uint256 public brakeThreshold = 50;

    /// @notice Last rebalance time
    uint256 public rebalanceTime;

    /// @notice rebalance waiting time
    uint256 public rebalanceWaitingTime = 1 hours;

    /// @notice Min balance to receive reward as rebalance caller
    uint256 public rebalanceRewardMinBalance = 1000e18;

    enum State {Normal, Drift, Brake}
    struct StateInfo {
        uint256 reflectFeeDenominator;
        uint256 buyTxFeeDenominator;
        uint256 sellTxFeeDenominator;
        uint256 buyBonusDenominator;
        uint256 sellFeeDenominator;
        uint256 rebalanceRewardDenominator;
        uint256 buyBackDenominator;
    }

    /// @notice Current state
    State public state;
    /// @notice State info
    mapping(State => StateInfo) public stateInfo;
    /// @notice Last state time
    uint256 public stateActivatedTime;

    /// @notice Token to pair with DRF when generating liquidity
    address public liquidityToken;
    /// @notice If set, LP provider for this liquidity will receive rewards.
    /// Usually DRF-PartnerToken
    address public liquidityPairToken;

    /// @dev Added to receive ETH when remove liquidity on Uniswap
    receive() external payable {
    }

    constructor(address _uniswapRouter, address _drf, address _sdrf, uint256 _farmOpenTime) public {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
        weth = uniswapRouter.WETH();
        drf = _drf;
        sdrf = _sdrf;
        pairAddress = uniswapFactory.createPair(drf, weth);
        farmOpenTime = _farmOpenTime;
        devTreasury = msg.sender;
        liquidityToken = weth;

        // 5% from total supply
        principalSupply = 500000e18;
        // 5% from total supply
        marketingSupply = 500000e18;
        // Sale supply
        saleSupply = 4000000e18;
        // Lend supply for lp provider
        lendSupply = 2000000e18;
        // Farming allocation / 2
        rewardAllocation = 1500000e18;

        // Approve uniswap router to spend weth
        approveUniswap(weth);
        // Approve uniswap router to spend drf
        approveUniswap(drf);
        // Approve uniswap router to spend lp token
        approveUniswap(pairAddress);

        // Initialize
        lastUpdateTime = farmOpenTime;
        finishTime = farmOpenTime.add(rewardDuration);
        rewardRate = rewardAllocation.div(rewardDuration);
        rebalanceTime = farmOpenTime;
    }

    /* ========== Modifiers ========== */

    modifier onlySDRFFarm {
        require(msg.sender == sdrfFarm, 'Only farm');
        _;
    }

    modifier farmOpen {
        require(isFarmOpen, 'Farm not open');
        _;
    }

    modifier checkOpenFarm()  {
        require(farmOpenTime <= block.timestamp, 'Farm not open');
        if (!isFarmOpen) {
            // Set flag
            isFarmOpen = true;
        }
        _;
    }

    modifier checkHalving() {
        if (block.timestamp >= finishTime) {
            // Halved reward
            rewardAllocation = rewardAllocation.div(2);
            // Calculate reward rate
            rewardRate = rewardAllocation.div(rewardDuration);
            // Set finish time
            finishTime = block.timestamp.add(rewardDuration);
            // Set last update time
            lastUpdateTime = block.timestamp;
            // Emit event
            emit Halved(rewardAllocation);
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            accountInfos[account].reward = earned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    /* ========== Only Owner ========== */

    function init(address _sdrfFarm) external onlyOwner {
        // Make sure we can only init one time
        if (!_initialized) {
            // Set flag
            _initialized = true;
            // Set farm
            sdrfFarm = _sdrfFarm;
            // 1.5% reflect, 0.5% buy reserve, 0.5% sell reserve, 4% buy bonus, 2% sell fee, (5% lock liquidity reward from reserve), 12.5% buy back
            setStateInfo(State.Normal, 67, 200, 200, 25, 50, 20, 8, false);
            // 1% reflect, 1% buy reserve, 1% sell reserve, 6.25% buy bonus, 2% sell fee, (4% lock liquidity reward from reserve), 20% buy back
            setStateInfo(State.Drift, 100, 100, 100, 16, 50, 25, 5, false);
            // 1% reflect, 1% buy reserve, 5% sell reserve, 8% buy bonus, 2% sell fee, (3% lock liquidity reward from reserve), 50% buy back
            setStateInfo(State.Brake, 100, 100, 20, 12, 50, 33, 2, false);
            // Apply fee
            _applyStateFee();
        }
    }

    function setStateInfo(
        State _state,
        uint256 _reflectFeeDenominator,
        uint256 _buyTxFeeDenominator,
        uint256 _sellTxFeeDenominator,
        uint256 _buyBonusDenominator,
        uint256 _sellFeeDenominator,
        uint256 _rebalanceRewardDenominator,
        uint256 _buyBackDenominator,
        bool applyImmediately
    ) public onlyOwner {
        // Make sure fee is valid
        require(_reflectFeeDenominator >= 10, 'Invalid denominator');
        require(_buyTxFeeDenominator >= 10, 'Invalid denominator');
        require(_sellTxFeeDenominator >= 10, 'Invalid denominator');
        require(_buyBonusDenominator >= 10, 'Invalid denominator');
        require(_sellFeeDenominator >= 10, 'Invalid denominator');
        require(_rebalanceRewardDenominator >= 10, 'Invalid denominator');
        require(_buyBackDenominator > 0, 'Invalid denominator');

        stateInfo[_state].reflectFeeDenominator = _reflectFeeDenominator;
        stateInfo[_state].buyTxFeeDenominator = _buyTxFeeDenominator;
        stateInfo[_state].sellTxFeeDenominator = _sellTxFeeDenominator;
        stateInfo[_state].buyBonusDenominator = _buyBonusDenominator;
        stateInfo[_state].sellFeeDenominator = _sellFeeDenominator;
        stateInfo[_state].rebalanceRewardDenominator = _rebalanceRewardDenominator;
        stateInfo[_state].buyBackDenominator = _buyBackDenominator;

        if (applyImmediately) {
            _applyStateFee();
        }
    }

    function setMaxStake(uint256 _maxStake) external onlyOwner {
        maxStake = _maxStake;
    }

    function setStateThreshold(uint256 _driftThreshold, uint256 _brakeThreshold) external onlyOwner {
        driftThreshold = _driftThreshold;
        brakeThreshold = _brakeThreshold;
    }

    function setRebalanceWaitingTime(uint256 _waitingTime) external onlyOwner {
        rebalanceWaitingTime = _waitingTime;
    }

    function setRebalanceRewardMinBalance(uint256 _minBalance) external onlyOwner {
        rebalanceRewardMinBalance = _minBalance;
    }

    function setLiquidityToken(address _liquidityToken) external onlyOwner {
        liquidityToken = _liquidityToken;
    }

    function setLiquidityPairAddress(address _liquidityPairToken) external onlyOwner {
        liquidityPairToken = _liquidityPairToken;
    }

    function depositPrincipalSupply() public onlyOwner {
        if (principalSupply > 0) {
            IDRF(drf).depositPrincipalSupply(principalSupply);
            principalSupply = 0;
        }
    }

    function withdrawPrincipalSupply() public onlyOwner {
        if (principalSupply == 0) {
            principalSupply = IDRF(drf).withdrawPrincipalSupply();
        }
    }

    function withdrawMarketingSupply(address recipient, uint256 amount) external onlyOwner {
        require(marketingSupply > 0, 'No supply');
        marketingSupply = marketingSupply.sub(amount);
        IERC20(drf).transfer(recipient, amount);
    }

    function approveUniswap(address token) public onlyOwner {
        IERC20(token).approve(address(uniswapRouter), MAX);
    }

    function connectLiquidityToken(address _liquidityToken, address _liquidityPairToken) external onlyOwner {
        liquidityToken = _liquidityToken;
        liquidityPairToken = _liquidityPairToken;
        depositPrincipalSupply();

        // Approve uniswap to spend liquidity token
        approveUniswap(liquidityToken);
        approveUniswap(liquidityPairToken);
    }

    function disconnectLiquidityToken() external onlyOwner {
        liquidityToken = weth;
        liquidityPairToken = address(0);
        withdrawPrincipalSupply();
    }

    /* ========== Only SDRF Farm ========== */

    function depositFromSDRFFarm(address sender, uint256 amount) external onlySDRFFarm {
        // Transfer from sender
        IERC20(drf).transferFrom(sender, address(this), amount);
        // Increase deposit
        sdrfFarmDepositSupply = sdrfFarmDepositSupply.add(amount);
    }

    function redeemFromSDRFFarm(address recipient, uint256 amount) external onlySDRFFarm {
        require(sdrfFarmDepositSupply >= amount, 'Insufficient supply');
        // Reduce first
        sdrfFarmDepositSupply = sdrfFarmDepositSupply.sub(amount);
        // Transfer to recipient
        IERC20(drf).transfer(recipient, amount);
    }

    /* ========== Mutative ========== */

    /// @notice Stake ETH.
    function stake() external payable nonReentrant checkOpenFarm checkHalving updateReward(msg.sender) {
        _stake(msg.sender, msg.value);
    }

    /// @notice Stake ETH.
    function stakeTo(address recipient) external payable nonReentrant checkOpenFarm checkHalving updateReward(msg.sender) {
        _stake(recipient, msg.value);
    }

    /// @notice Withdraw LP.
    function withdraw(uint256 amount) external nonReentrant farmOpen checkHalving updateReward(msg.sender) {
        _withdraw(msg.sender, msg.sender, amount);
    }

    /// @notice Withdraw LP.
    function withdrawTo(address payable recipient, uint256 amount) external nonReentrant farmOpen checkHalving updateReward(msg.sender) {
        _withdraw(msg.sender, recipient, amount);
    }

    /// @notice Claim reward
    function claimReward() external nonReentrant farmOpen checkHalving updateReward(msg.sender) returns (uint256 net, uint256 tax) {
        (net, tax) = _claimReward(msg.sender, msg.sender);
    }

    /// @notice Claim reward
    function claimRewardTo(address recipient) external nonReentrant farmOpen checkHalving updateReward(msg.sender) returns (uint256 net, uint256 tax) {
        (net, tax) = _claimReward(msg.sender, recipient);
    }

    /// @notice Rebalance
    function rebalance() external {
        // Let's wait before releasing liquidity
        require(rebalanceTime.add(rebalanceWaitingTime) <= block.timestamp, 'Too soon');
        // Update time
        rebalanceTime = block.timestamp;

        // If there is no principal in this contract, it means the principal is actually being used
        if (principalSupply == 0) {
            // Distribute principal rewards for liquidity provider or reserve supply
            IDRF(drf).distributePrincipalRewards(liquidityPairToken);
        }

        // Get reserve supply to be locked as liquidity
        uint256 liquiditySupply = IDRF(drf).reserveSupply();
        // If there is supply
        if (liquiditySupply > 0) {
            // If sender has required DRF, give reward
            if (IERC20(drf).balanceOf(msg.sender) >= rebalanceRewardMinBalance) {
                // Calc reward for msg sender
                uint256 senderReward = liquiditySupply.div(stateInfo[state].rebalanceRewardDenominator);
                // Reduce first
                liquiditySupply = liquiditySupply.sub(senderReward);
                // Send reward
                IERC20(drf).transfer(msg.sender, senderReward);
            }

            // If we are not in brake state, we can provide other token liquidity
            // otherwise enforce DRF-ETH
            address token = state != State.Brake ? liquidityToken : weth;

            uint256 drfDust;
            // Add liquidity DRF-Token. Default is DRF-WETH
            if (token == weth) {
                (drfDust,) = _addLiquidityDRFETH(liquiditySupply);
                // Adjust reserve supply
                IDRF(drf).setReserveSupply(drfDust);
                // Check if should change state
                _checkState();
            } else {
                uint256 tokenDust;
                (drfDust, tokenDust,) = _addLiquidityToken(drf, token, liquiditySupply);
                // Adjust reserve supply
                IDRF(drf).setReserveSupply(drfDust);
                // Send dust out
                IERC20(liquidityToken).transfer(devTreasury, tokenDust);
            }
        }

        // If we have good amount of ETH
        if (address(this).balance > 0.01 ether) {
            // Buy back and burn
            _buyBack();
        }

        emit Rebalanced();
    }

    /// @notice Swap SDRF to DRF
    function swap(uint256 amount) external {
        require(state != State.Brake, 'Swap disabled');
        require(swappableSupply >= amount, 'Insufficient supply');

        // Reduce swappable supply
        swappableSupply = swappableSupply.sub(amount);
        // Receive sDRF
        IERC20(sdrf).transferFrom(msg.sender, address(this), amount);
        // Transfer DRF
        IERC20(drf).transfer(msg.sender, amount);
        // Emit event
        emit SwappedSDRF(amount);
    }

    /* ========== Private ========== */

    function _stake(address recipient, uint256 ethAmount) private {
        require(ethAmount > 0, 'Cannot stake 0');
        require(ethAmount <= maxStake, 'Max stake reached');

        // 10% compensation fee
        uint256 fee = ethAmount.div(10);
        ethAmount = ethAmount.sub(fee);
        devTreasury.transfer(fee);

        uint256 pairETHBalance = IERC20(weth).balanceOf(pairAddress);
        uint256 pairDRFBalance = IERC20(drf).balanceOf(pairAddress);
        // If eth amount = 0 then set initial price
        uint256 drfAmount = pairETHBalance == 0 ? ethAmount.mul(INITIAL_PRICE) : ethAmount.mul(pairDRFBalance).div(pairETHBalance);

        // If there is still sale supply
        if (saleSupply > 0) {
            // Get sale amount
            uint256 saleAmount = drfAmount > saleSupply ? saleSupply : drfAmount;
            // Reduce sale supply
            saleSupply = saleSupply.sub(saleAmount);
            // Send DRF to recipient
            IERC20(drf).transfer(recipient, saleAmount);
        }

        drfAmount = drfAmount.div(2);
        uint256 pairTokenAmount;

        if (lendSupply >= drfAmount) {
            // Use half of eth
            ethAmount = ethAmount.div(2);
            // Reduce DRF can be lend
            lendSupply = lendSupply.sub(drfAmount);
            // Add liquidity in uniswap
            (,, pairTokenAmount) = uniswapRouter.addLiquidityETH{value : ethAmount}(drf, drfAmount, 0, 0, address(this), MAX);
        } else {
            uint256 wethDust;
            IWETH(weth).deposit{value : ethAmount}();
            (wethDust,, pairTokenAmount) = _addLiquidityToken(weth, drf, ethAmount);
            IWETH(weth).withdraw(wethDust);
        }

        // Add to balance
        accountInfos[recipient].balance = accountInfos[recipient].balance.add(pairTokenAmount);
        // Set peak balance
        if (accountInfos[recipient].balance > accountInfos[recipient].peakBalance) {
            accountInfos[recipient].peakBalance = accountInfos[recipient].balance;
        }
        // Set stake timestamp as withdraw time to prevent withdraw immediately after first staking
        if (accountInfos[recipient].withdrawTime == 0) {
            accountInfos[recipient].withdrawTime = block.timestamp;
        }

        // Increase total supply
        _totalSupply = _totalSupply.add(pairTokenAmount);
        // Set peak pair token balance
        uint256 pairTokenBalance = IERC20(pairAddress).balanceOf(address(this));
        if (pairTokenBalance > peakPairTokenBalance) {
            peakPairTokenBalance = pairTokenBalance;
        }

        // Check if should change state
        _checkState();

        emit Staked(recipient, ethAmount, pairTokenAmount);
    }

    function _withdraw(address sender, address payable recipient, uint256 amount) private {
        require(state != State.Brake, 'Withdraw disabled');
        require(amount > 0 && amount <= maxWithdrawOf(sender), 'Invalid withdraw');
        require(amount <= accountInfos[sender].balance, 'Insufficient balance');

        // Reduce balance
        accountInfos[sender].balance = accountInfos[sender].balance.sub(amount);
        // Set withdraw time
        accountInfos[sender].withdrawTime = block.timestamp;
        // Reduce total supply
        _totalSupply = _totalSupply.sub(amount);

        // Remove liquidity in uniswap
        (uint256 drfAmount, uint256 ethAmount) = uniswapRouter.removeLiquidity(drf, weth, amount, 0, 0, address(this), MAX);
        // Send DRF to recipient
        IERC20(drf).transfer(recipient, drfAmount);
        // Withdraw ETH and send to recipient
        IWETH(weth).withdraw(ethAmount);
        recipient.transfer(ethAmount);

        // Check if should change state
        _checkState();

        emit Withdrawn(recipient, drfAmount, ethAmount, amount);
    }

    function _claimReward(address sender, address recipient) private returns (uint256 net, uint256 tax) {
        uint256 reward = accountInfos[sender].reward;
        require(reward > 0, 'No reward');

        // Reduce reward first
        accountInfos[sender].reward = 0;

        // Calculate tax and net
        tax = taxForReward(reward);
        net = reward.sub(tax);

        // Add tax to swappable reserve
        swappableSupply = swappableSupply.add(tax);

        // Send drf as reward
        IDRF(drf).transfer(recipient, net);

        emit Claimed(recipient, net, tax);
    }

    /// @notice Check if should change state based on liquidity
    function _checkState() private {
        uint256 pairTokenBalance = IERC20(pairAddress).balanceOf(address(this));
        uint256 baseThreshold = peakPairTokenBalance.div(100);
        uint256 driftStateThreshold = baseThreshold.mul(driftThreshold);
        uint256 brakeStateThreshold = baseThreshold.mul(brakeThreshold);

        // If drift state already run for 1 day, and liquidity high enough
        if (state == State.Drift && stateActivatedTime.add(1 days) <= block.timestamp && pairTokenBalance > driftStateThreshold) {
            state = State.Normal;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If brake state already run for 1 day, and liquidity high enough
        else if (state == State.Brake && stateActivatedTime.add(1 days) <= block.timestamp && pairTokenBalance > brakeStateThreshold) {
            state = State.Drift;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If liquidity reached drift state from normal state
        else if (state == State.Normal && pairTokenBalance <= driftStateThreshold) {
            state = State.Drift;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
        // If liquidity reached brake state from drift state
        else if (state == State.Drift && pairTokenBalance <= brakeStateThreshold) {
            state = State.Brake;
            stateActivatedTime = block.timestamp;
            _applyStateFee();
        }
    }

    /// @notice Apply fee to DRF token
    function _applyStateFee() private {
        IDRF(drf).setFee(
            stateInfo[state].reflectFeeDenominator,
            stateInfo[state].buyTxFeeDenominator,
            stateInfo[state].sellTxFeeDenominator,
            stateInfo[state].buyBonusDenominator,
            stateInfo[state].sellFeeDenominator
        );
    }

    /// @notice Add liquidity to DRF-ETH pair using DRF amount
    function _addLiquidityDRFETH(uint256 drfAmount) private returns (uint256 drfDust, uint256 ethDust) {
        uint256 drfToSwapForETH = drfAmount.div(2);
        uint256 drfToAddLiquidity = drfAmount.sub(drfToSwapForETH);
        uint256 ethBalanceBeforeSwap = address(this).balance;

        // Swap path
        address[] memory path = new address[](2);
        path[0] = drf;
        path[1] = weth;

        // Swap DRF for ETH
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            drfToSwapForETH,
            0,
            path,
            address(this),
            MAX
        );

        uint256 ethToAddLiquidity = address(this).balance.sub(ethBalanceBeforeSwap);

        // Add liquidity
        (uint256 drfUsed, uint256 ethUsed,) = uniswapRouter.addLiquidityETH{value : ethToAddLiquidity}(
            drf,
            drfToAddLiquidity,
            0,
            0,
            address(this),
            MAX
        );

        drfDust = drfAmount.sub(drfToSwapForETH);
        drfDust = drfDust > drfUsed ? drfDust.sub(drfUsed) : 0;
        ethDust = ethToAddLiquidity > ethUsed ? ethToAddLiquidity.sub(ethUsed) : 0;
    }

    /// @notice Add liquidity using token A amount
    function _addLiquidityToken(address tokenA, address tokenB, uint256 tokenAAmount) private returns (uint256 tokenADust, uint256 tokenBDust, uint256 pairTokenAmount) {
        uint256 tokenAToSwap = tokenAAmount.div(2);
        uint256 tokenAToAddLiquidity = tokenAAmount.sub(tokenAToSwap);
        uint256 tokenBBalanceBeforeSwap = IERC20(tokenB).balanceOf(address(this));

        // Swap path
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        // Swap DRF for token
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAToSwap,
            0,
            path,
            address(this),
            MAX
        );

        uint256 tokenBToAddLiquidity = IERC20(tokenB).balanceOf(address(this)).sub(tokenBBalanceBeforeSwap);

        // Add liquidity
        (uint256 tokenAUsed, uint256 tokenBUsed, uint256 liquidity) = uniswapRouter.addLiquidity(
            tokenA,
            tokenB,
            tokenAToAddLiquidity,
            tokenBToAddLiquidity,
            0,
            0,
            address(this),
            MAX
        );

        tokenADust = tokenAAmount.sub(tokenAToSwap);
        tokenADust = tokenADust > tokenAUsed ? tokenADust.sub(tokenAUsed) : 0;
        tokenBDust = tokenBToAddLiquidity > tokenBUsed ? tokenBToAddLiquidity.sub(tokenBUsed) : 0;
        pairTokenAmount = liquidity;
    }

    /// @notice Buy back and burn DRF
    function _buyBack() private {
        // Swap path
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = drf;

        // Use ETH to market buy
        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value : address(this).balance.div(stateInfo[state].buyBackDenominator)}
        (0, path, address(this), MAX);

        // Add as burned supply
        burnSupply = burnSupply.add(amounts[1]);
    }

    /* ========== View ========== */

    /// @notice Get staked token total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Get staked token balance
    function balanceOf(address account) public view returns (uint256) {
        return accountInfos[account].balance;
    }

    /// @notice Get account max withdraw
    function maxWithdrawOf(address account) public view returns (uint256) {
        // Get how many day already passes
        uint256 dayCount = block.timestamp.sub(accountInfos[account].withdrawTime).add(1).div(1 days);
        // If already 10 days passes
        if (dayCount >= 10) {
            return Math.min(accountInfos[account].peakBalance, balanceOf(account));
        } else {
            return Math.min(accountInfos[account].peakBalance.div(10).mul(dayCount), balanceOf(account));
        }
    }

    /// @notice Get reward tax percentage
    function rewardTaxPercentage() public view returns (uint256) {
        return state == State.Brake ? 80 : 10;
    }

    /// @notice Get claim reward tax
    function taxForReward(uint256 reward) public view returns (uint256 tax) {
        tax = reward.div(100).mul(rewardTaxPercentage());
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, finishTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
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
    },
    "@openzeppelin/contracts/token/ERC20/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "@openzeppelin/contracts/math/Math.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
    "@openzeppelin/contracts/utils/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
    "contracts/uniswapv2/interfaces/IUniswapV2Factory.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}
"
    },
    "contracts/uniswapv2/interfaces/IUniswapV2Router02.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

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
}"
    },
    "contracts/uniswapv2/interfaces/IUniswapV2Pair.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}"
    },
    "contracts/uniswapv2/interfaces/IWETH.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}"
    },
    "contracts/interfaces/IDRF.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDRF is IERC20 {

    function reserveSupply() external returns (uint256);

    function bonusSupply() external returns (uint256);

    function lockedSupply() external returns (uint256);

    function setFee(uint256 _reflectFeeDenominator, uint256 _buyTxFeeDenominator, uint256 _sellTxFeeDenominator, uint256 _buyBonusDenominator, uint256 _sellFeeDenominator) external;

    function setReserveSupply(uint256 amount) external;

    function depositPrincipalSupply(uint256 amount) external;

    function withdrawPrincipalSupply() external returns(uint256);

    function distributePrincipalRewards(address _pairAddress) external;

}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
"
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
    "contracts/uniswapv2/interfaces/IUniswapV2Router01.sol": {
      "content": "// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

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
}"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}