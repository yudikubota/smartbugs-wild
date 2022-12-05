{{
  "language": "Solidity",
  "sources": {
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/Cane.sol": {
      "content": "pragma solidity ^0.6.12;

import "./lib/ERC20.sol";

// File: contracts/Cane.sol
contract Cane is ERC20 {

    address minter;
    uint256 tradingStartTimestamp;
    uint256 public constant maxSupply = 12500 * 1e18;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter can call this function.');
        _;
    }

    modifier limitEarlyBuy (uint256 _amount) {
        require(tradingStartTimestamp <= block.timestamp ||
            _amount <= (5 * 1e18), "ERC20: early buys limited"
        );
        _;
    }

    constructor(address _minter, uint256 _tradingStartTimestamp) public ERC20('Hurricane Finance', 'HCANE') {
        tradingStartTimestamp = _tradingStartTimestamp;
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        require(_totalSupply.add(amount) <= maxSupply, "ERC20: max supply exceeded");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}
"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/CategoryFive.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswap.sol";
import "./interfaces/IWETH.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";
import "./lib/Math.sol";
import "./lib/Address.sol";
import "./lib/SafeERC20.sol";
import "./lib/FeeHelpers.sol";
import "./Cane.sol";
import "./Hugo.sol";


// File: contracts/CategoryFive.sol

contract CategoryFive is ReentrancyGuard, Ownable {
 
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, uint256 amount, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 poolId, uint256 amount, uint256 amountLP);
    event Claimed(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedAndStaked(address indexed to, uint256 poolId, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);
    event EmergencyWithdraw(address indexed to, uint256 poolId, uint256 amount);
    event ClaimedLPReward(address indexed to, uint256 poolId, uint256 lpEthReward, uint256 lpCaneReward);

    Cane public cane; // Hurricane farming token
    Hugo public hugo; // Hurricane governance token

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address payable public treasury;
    bool public treasuryDisabled = false;

    struct AccountInfo {
        uint256 index;
        uint256 balance;
        uint256 maxBalance;
        uint256 lastWithdrawTimestamp;
        uint256 lastStakedTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
        uint256 lpEthReward;
        uint256 lpEthRewardPaid;
        uint256 lpCaneReward;
        uint256 lpCaneRewardPaid;
    }
    struct PoolInfo {
        IERC20 pairAddress; // Address of LP token contract
        IERC20 otherToken; // Reference to other token in pair (e.g. 'weth')
        uint256 rewardAllocation; // Rewards allocated for this pool
        uint256 totalSupply; // Total supply of tokens in pool
        uint256 borrowedSupply; // Total CANE token borrowed for pool
        uint256 rewardPerTokenStored; // Rewards per token in this pool
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => AccountInfo)) public accountInfos;
    // List for supporting accountInfos interation
    mapping(uint256 => address payable[]) public accountInfosIndex;

    struct Airgrabber {
        uint256 ethAmount; // Amount of ETH due
        uint256 caneAmount; // Amount of CANE due
        bool ethClaimed; // Track eth claim status
        bool caneClaimed; // Track claimed CANE
    }
    mapping(address => Airgrabber) public airgrabbers;

    uint256 public constant HALVING_DURATION = 14 days;
    uint256 public rewardAllocation = 5000 * 10 ** 18;
    uint256 public halvingTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;

    // configurable parameters via gov voting (days 30+ parameters only)
    uint256 public rewardHalvingPercent = 50;
    uint256 public claimBurnFee = 1;
    uint256 public claimTreasuryFeePercent = 2;
    uint256 public claimLPFeePercent = 2;
    uint256 public claimLiquidBalancePercent = 95;
    uint256 public unstakeLPFeePercent = 2;
    uint256 public unstakeTreasuryFeePercent = 2;
    uint256 public unstakeBurnFeePercent = 1;
    uint256 public withdrawalLimitPercent = 20;
    uint256 public katrinaExitFeePercent = 3;

    // Goal is for farming to be started as early as this timestamp
    // Date and time (GMT): Tuesday, December 15, 2020 7:00 PM UTC
    uint256 public farmingStartTimestamp = 1608058800;
    bool public farmingStarted = false;

    // References to our 2 core pools
    uint256 private constant HUGO_POOL_ID = 0;
    uint256 private constant KATRINA_POOL_ID = 1;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Uniswap Router Address
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Prevent big buys for first few mins after farming starts
    uint256 public constant NOBUY_DURATION = 5 minutes;

    constructor(address payable _treasury) public {
        cane = new Cane(address(this), farmingStartTimestamp.add(NOBUY_DURATION));
        hugo = new Hugo(address(this));

        router = IUniswapV2Router02(ROUTER_ADDRESS);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        treasury = _treasury;

        IERC20(cane).safeApprove(address(router), uint256(-1));

        // Calc initial reward rate
        rewardRate = rewardAllocation.div(HALVING_DURATION);

        // Initialize CANE staking pool w/ 30% of rewards at launch
        // New allocations can be set dynamically via governance
        poolInfo.push(PoolInfo({
            pairAddress: cane,
            otherToken: cane,
            rewardAllocation: rewardAllocation.mul(30).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));

        // Initialize Katrina liquidity pool w/ 70% of rewards at launch
        // New allocations can be set dynamically via governance
        poolInfo.push(PoolInfo({
            pairAddress: IERC20(factory.createPair(address(cane), weth)),
            otherToken: IERC20(weth),
            rewardAllocation: rewardAllocation.mul(70).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stakeToHugo(uint256 _amount, bool _claimAndStakeRewards) public nonReentrant {
        _checkFarming();
        _updateReward(HUGO_POOL_ID);
        _halving(HUGO_POOL_ID);

        // Retrieve pool & account Info
        PoolInfo storage pool = poolInfo[HUGO_POOL_ID];
        AccountInfo storage account = accountInfos[HUGO_POOL_ID][msg.sender];

        // find user rewards due in each pool and auto claim
        if (_claimAndStakeRewards) {
            uint256 rewardsDue = account.reward; // current reward due in Hugo
            for (uint256 pid = 1; pid < poolInfo.length; pid++) {
                if (accountInfos[pid][msg.sender].reward > 0) {
                    rewardsDue = rewardsDue.add(accountInfos[pid][msg.sender].reward);
                    accountInfos[pid][msg.sender].reward = 0;
                }
            }

            if (rewardsDue > 0) { // transfer to Hugo staking pool directly without any fees
                // mint rewards directly to pool, plus send equiv Hugo gov tokens to user
                cane.mint(address(this), rewardsDue);
                hugo.mint(msg.sender, rewardsDue);

                emit ClaimedAndStaked(msg.sender, HUGO_POOL_ID, rewardsDue);

                account.balance = account.balance.add(rewardsDue);
                // Track to always allow full withdrawals against withdrawalLimit
                if (account.balance > account.maxBalance) {
                    account.maxBalance = account.balance;
                }
                account.lastStakedTimestamp = block.timestamp;
                if (account.index == 0) {
                    accountInfosIndex[HUGO_POOL_ID].push(msg.sender);
                    account.index = accountInfosIndex[HUGO_POOL_ID].length;
                }

                pool.totalSupply = pool.totalSupply.add(rewardsDue);

                if (account.reward > 0) {
                    account.reward = 0;
                }
            }
        }

        if (_amount > 0) { // allows staking only rewards to Hugo
            require(cane.balanceOf(msg.sender) >= _amount, 'Invalid balance');
            cane.transferFrom(msg.sender, address(this), _amount);

            // Add balance to pool's total supply
            pool.totalSupply = pool.totalSupply.add(_amount);

            // Add to iterator tracker if not exists
            account.balance = account.balance.add(_amount);
            // Track to always allow full withdrawals against withdrawalLimit
            if (account.balance > account.maxBalance) {
                account.maxBalance = account.balance;
            }
            account.lastStakedTimestamp = block.timestamp;
            
            if (account.index == 0) {
                accountInfosIndex[HUGO_POOL_ID].push(msg.sender);
                account.index = accountInfosIndex[HUGO_POOL_ID].length;
            }

            // Mint equivalent number of our gov token for user
            hugo.mint(msg.sender, _amount);

            emit Staked(msg.sender, _amount, 0);
        }
    }

    function stake(uint256 _poolId, uint256 _amount, address payable sender) external payable nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        if (_poolId == KATRINA_POOL_ID) {
            _amount = msg.value;
        }

        require(_amount > 0, 'Invalid amount');
        require(!address(msg.sender).isContract() || address(msg.sender) == address(this), 'Invalid user');

        require(_poolId < poolInfo.length, 'Invalid pool');
        require(_poolId > HUGO_POOL_ID, 'Stake in Hugo');

        if (address(msg.sender) != address(this)) {
            sender = msg.sender;
        }

        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][sender];

        // Use 2% of deposit sent to purchase CANE
        uint256 boughtCane = 0;
        if (pool.totalSupply > 0 && 
            farmingStartTimestamp.add(NOBUY_DURATION) <= block.timestamp && 
            _poolId == KATRINA_POOL_ID) {
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(pool.otherToken);
            swapPath[1] = address(cane);
            IERC20(pool.otherToken).safeApprove(address(router), 0);
            IERC20(pool.otherToken).safeApprove(address(router), _amount.div(50));
            uint256[] memory amounts = router.swapExactETHForTokens{ value: _amount.div(50) }
                (uint(0), swapPath, address(this), block.timestamp + 1 days);
            
            boughtCane = amounts[amounts.length - 1];
            _amount = _amount.sub(_amount.div(50));
        }

        uint256 caneTokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        
        // If otherTokenAmount = 0 then set initial price to 1 ETH = 1 CANE
        uint256 amountCaneTokenDesired = 0;
        if (_poolId == KATRINA_POOL_ID) {
            amountCaneTokenDesired = (otherTokenAmount == 0) ? 
                _amount * 1 : _amount.mul(caneTokenAmount).div(otherTokenAmount);
        } else {
            require(otherTokenAmount > 0, "Pool not started"); // require manual add for new LPs
            amountCaneTokenDesired = _amount.mul(caneTokenAmount).div(otherTokenAmount);
        }

        // Mint borrowed cane and update borrowed amount in pool
        cane.mint(address(this), amountCaneTokenDesired.sub(boughtCane));
        pool.borrowedSupply = pool.borrowedSupply.add(amountCaneTokenDesired);

        // Add liquidity in uniswap
        IERC20(cane).approve(address(router), amountCaneTokenDesired);
        
        uint256 liquidity;
        if (_poolId == KATRINA_POOL_ID) { // use addLiquidityETH
            (,, liquidity) = router.addLiquidityETH{value : _amount}(
                address(cane), amountCaneTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        } else { // use addLiquidity for token/cane liquidity
            IERC20(pool.otherToken).approve(address(router), _amount);
            (,, liquidity) = router.addLiquidity(
                address(pool.otherToken), address(cane), 
                _amount, amountCaneTokenDesired, 0, 0, address(this), block.timestamp + 1 days);
        }

        // Add LP token to total supply
        pool.totalSupply = pool.totalSupply.add(liquidity);

        // Add to balance and iterator tracker if not exists
        account.balance = account.balance.add(liquidity);
        // Track to always allow full withdrawals against withdrawalLimit
        if (account.balance > account.maxBalance) {
            account.maxBalance = account.balance;
        }
        if (account.index == 0) {
            accountInfosIndex[_poolId].push(sender);
            account.index = accountInfosIndex[_poolId].length;
        }

        // Set stake timestamp as last withdraw timestamp
        // to prevent withdraw immediately after first staking
        account.lastStakedTimestamp = block.timestamp;
        if (account.lastWithdrawTimestamp == 0) {
            account.lastWithdrawTimestamp = block.timestamp;
        }

        emit Staked(sender, _amount, liquidity);
    }

    function withdraw(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        require(_poolId < poolInfo.length, 'Invalid pool');

        // Retrieve account in pool
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];

        require(account.lastWithdrawTimestamp + 12 hours <= block.timestamp, 'Invalid withdraw time');
        require(account.balance > 0, 'Invalid balance');

        uint256 _amount = account.maxBalance.mul(withdrawalLimitPercent).div(100);
        if (account.balance < _amount) {
            _amount = account.balance;
        }

        // Reduce total supply in pool
        pool.totalSupply = pool.totalSupply.sub(_amount);
        // Reduce user's balance
        account.balance = account.balance.sub(_amount);
        // Update user's withdraw timestamp
        account.lastWithdrawTimestamp = block.timestamp;

        uint256[] memory totalToken = new uint256[](2);

        uint256 otherTokenAmountMinusFees = 0;

        if (_poolId == HUGO_POOL_ID) { // burn Hugo
            totalToken[1] = _amount;
            hugo.burn(msg.sender, _amount);

            uint256 burnFee = _amount.div(FeeHelpers.getUnstakeBurnFee(account.lastStakedTimestamp, unstakeBurnFeePercent)); // calculate fee
            cane.burn(BURN_ADDRESS, burnFee);
            otherTokenAmountMinusFees = _amount.sub(burnFee);
        } else { // Remove liquidity in uniswap
            IERC20(pool.pairAddress).approve(address(router), _amount);
            if (_poolId == KATRINA_POOL_ID) {
                (uint256 caneTokenAmount, uint256 otherTokenAmount) = router.removeLiquidityETH(address(cane), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = caneTokenAmount;
                totalToken[1] = otherTokenAmount;
            } else {
                (uint256 caneTokenAmount, uint256 otherTokenAmount) = router.removeLiquidity(address(cane), address(pool.otherToken), _amount, 0, 0, address(this), block.timestamp + 1 days);
                totalToken[0] = caneTokenAmount;
                totalToken[1] = otherTokenAmount;
            }

            // Burn borrowed cane and update count
            cane.burn(address(this), totalToken[0]);
            pool.borrowedSupply = pool.borrowedSupply.sub(totalToken[0]);
        }

        // Calculate and transfer withdrawal fee to treasury
        uint256 treasuryFee = 0;
        if (_poolId == KATRINA_POOL_ID) {
            treasuryFee = FeeHelpers.getKatrinaExitFee(katrinaExitFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            treasury.transfer(treasuryFee);
        } else {
            treasuryFee = FeeHelpers.getUnstakeTreasuryFee(account.lastStakedTimestamp, unstakeTreasuryFeePercent);
            treasuryFee = totalToken[1].div(treasuryFee);
            pool.otherToken.transfer(treasury, treasuryFee);
        }
        
        if (_poolId == HUGO_POOL_ID) {
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(treasuryFee);
        } else {
            otherTokenAmountMinusFees = totalToken[1].sub(treasuryFee);
        }
        
        // Calculate and transfer withdrawal fee for distribution to other LPs
        if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
            uint256 lpFee = 0;
            if (_poolId == KATRINA_POOL_ID) {
                lpFee = FeeHelpers.getKatrinaExitFee(katrinaExitFeePercent);
            } else {
                lpFee = FeeHelpers.getUnstakeLPFee(account.lastStakedTimestamp, unstakeLPFeePercent);
            }

            lpFee = totalToken[1].div(lpFee);
            for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                // Send portion of fee and track amounts if we have an LP balance and is not sender
                if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                    if (_poolId == KATRINA_POOL_ID) {
                        lpAccount.lpEthReward = lpAccount.lpEthReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    } else {
                        lpAccount.lpCaneReward = lpAccount.lpCaneReward.add(lpAccount.balance.mul(lpFee).div(pool.totalSupply));
                    }
                }
            }
            otherTokenAmountMinusFees = otherTokenAmountMinusFees.sub(lpFee);
        }

        totalToken[1] = otherTokenAmountMinusFees;

        if (_poolId == KATRINA_POOL_ID) {
            msg.sender.transfer(totalToken[1]);
        } else {
            pool.otherToken.transfer(msg.sender, totalToken[1]);
        }

        // Remove from list if balance is zero
        if (account.balance == 0 && account.index > 0 && account.index <= accountInfosIndex[_poolId].length) {
            uint256 accountIndex = account.index - 1; // Fetch real index in array
            accountInfos[_poolId][accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]].index = accountIndex + 1; // Give it my index
            accountInfosIndex[_poolId][accountIndex] = accountInfosIndex[_poolId][accountInfosIndex[_poolId].length - 1]; // Give it my address
            accountInfosIndex[_poolId].pop();
            account.index = 0; // Keep struct ref valid, but remove from tracking list of active LPs
        }

        emit Withdrawn(msg.sender, _poolId, _amount, totalToken[1]);
    }

    // Claim functions for extracting pool rewards
    function claim(uint256 _poolId) external nonReentrant {
        _checkFarming();
        _updateReward(_poolId);
        _halving(_poolId);

        require(_poolId < poolInfo.length, 'Invalid pool');

        // Retrieve account in pool
        PoolInfo storage pool = poolInfo[_poolId];
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        
        uint256 reward = account.reward;

        require(reward > 0, 'No rewards');

        if (reward > 0) {
            // Reduce rewards due
            account.reward = 0;
            // Apply variable % burn fee
            cane.mint(BURN_ADDRESS, reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)));
            // Extract liquid qty and send liquid to user wallet
            cane.mint(msg.sender, reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)));
            // Extract treasury fee and send
            cane.mint(address(treasury), reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)));

            // Extract LPs fees amount and distribute
            if (accountInfosIndex[_poolId].length > 0 && pool.totalSupply > 0) {
                for (uint256 i = 0; i < accountInfosIndex[_poolId].length; i ++) {
                    AccountInfo storage lpAccount = accountInfos[_poolId][accountInfosIndex[_poolId][i]];
                    // Send portion of fee and track amounts if we have an LP balance and is not sender
                    if (lpAccount.balance > 0 && accountInfosIndex[_poolId][i] != msg.sender) {
                        lpAccount.lpCaneReward = lpAccount.lpCaneReward.add(lpAccount.balance
                            .mul(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)))
                            .div(pool.totalSupply));
                    }
                }
            }

            // Remove liquid and treasury/lp/burn fees, then remainder goes back to LP
            uint256[] memory rewardAmounts = new uint256[](2);
            rewardAmounts[0] = reward
                .sub(reward.div(FeeHelpers.getClaimBurnFee(account.lastStakedTimestamp, claimBurnFee)))
                .sub(reward.div(FeeHelpers.getClaimLiquidBalancePcnt(account.lastStakedTimestamp, claimLiquidBalancePercent)))
                .sub(reward.div(FeeHelpers.getClaimTreasuryFee(account.lastStakedTimestamp, claimTreasuryFeePercent)))
                .sub(reward.div(FeeHelpers.getClaimLPFee(account.lastStakedTimestamp, claimLPFeePercent)));
            rewardAmounts[1] = rewardAmounts[0].div(2);
            // Mint [ALL] the qty of tokens needed to buy ETH and add LP
            cane.mint(address(this), rewardAmounts[0]);
            // Build swap pair from token to token (eg: WETH)
            address[] memory swapPath = new address[](2);
            swapPath[0] = address(cane);
            swapPath[1] = address(weth);
            // Sell minted half for ETH equivalent
            IERC20(cane).safeApprove(address(router), 0);
            IERC20(cane).safeApprove(address(router), rewardAmounts[1]);
            uint256[] memory swappedTokens = router.swapExactTokensForETH(rewardAmounts[1], uint(0), swapPath, address(this), block.timestamp + 1 days);
            // Use other minted half for CANE part, add to lp
            uint256[] memory totalLp = new uint256[](3);
            IERC20(cane).safeApprove(address(router), 0);
            IERC20(cane).safeApprove(address(router), rewardAmounts[1]);
            (totalLp[0], totalLp[1], totalLp[2]) = router.addLiquidityETH{value: swappedTokens[swappedTokens.length - 1]}
                (address(cane), rewardAmounts[1], 0, 0, address(this), block.timestamp + 5 minutes);
            // Check for any leftover CANE dust, return to treasury
            if (rewardAmounts[1].sub(totalLp[0]) > 0) {
                cane.mint(treasury, rewardAmounts[1].sub(totalLp[0]));
            }
            // Check for any leftover ETH dust, return to treasury
            if (swappedTokens[swappedTokens.length - 1].sub(totalLp[1]) > 0) {
                treasury.transfer(swappedTokens[swappedTokens.length - 1].sub(totalLp[1]));
            }

            // Add LP token to total and borrowed supply to KAT pool
            PoolInfo storage katPool = poolInfo[KATRINA_POOL_ID];
            AccountInfo storage katAccount = accountInfos[KATRINA_POOL_ID][msg.sender];

            katPool.totalSupply = katPool.totalSupply.add(totalLp[2]);
            katPool.borrowedSupply = katPool.borrowedSupply.add(totalLp[0]);
            
            // Add to balance and iterator if not already in pool
            katAccount.balance = katAccount.balance.add(totalLp[2]);
            if (katAccount.index == 0) {
                accountInfosIndex[KATRINA_POOL_ID].push(msg.sender);
                katAccount.index = accountInfosIndex[KATRINA_POOL_ID].length;
            }

            emit Claimed(msg.sender, _poolId, reward);
        }
    }

    // allow LPs to claim fee rewards with no penalties
    function claimLP(uint256 _poolId) external {
        AccountInfo storage account = accountInfos[_poolId][msg.sender];
        require (account.lpEthReward > 0 || account.lpCaneReward > 0, 'No LP rewards');
        emit ClaimedLPReward(msg.sender, _poolId, account.lpEthReward, account.lpCaneReward);

        if (account.lpEthReward > 0) {
            // Reduce rewards due, track total paid, and send ETH
            account.lpEthRewardPaid = account.lpEthRewardPaid.add(account.lpEthReward);
            msg.sender.transfer(account.lpEthReward);
            account.lpEthReward = 0;
        }
        if (account.lpCaneReward > 0) {
            account.lpCaneRewardPaid = account.lpCaneRewardPaid.add(account.lpCaneReward);
            cane.mint(msg.sender, account.lpCaneReward);
            account.lpCaneReward = 0;
        }
    }

    // stake airgrabber's tokens to Hugo
    function stakeAirgrabber() external {
        require(airgrabbers[msg.sender].caneAmount > 0, "No CANE to stake");
        require(!airgrabbers[msg.sender].caneClaimed, "Already airgrabbed CANE");
        airgrabbers[msg.sender].caneClaimed = true;
        cane.mint(msg.sender, airgrabbers[msg.sender].caneAmount);
        stakeToHugo(airgrabbers[msg.sender].caneAmount, false);
    }

    // stake airgrabber's tokens to Katrina
    function stakeAirgrabberLP() external {
        require(airgrabbers[msg.sender].ethAmount > 0, "No ETH to stake");
        require(!airgrabbers[msg.sender].ethClaimed, "Already airgrabbed ETH");
        airgrabbers[msg.sender].ethClaimed = true;
        this.stake{value: airgrabbers[msg.sender].ethAmount}(KATRINA_POOL_ID, airgrabbers[msg.sender].ethAmount, msg.sender);
    }

    // withdraw airgrabber's ETH to their wallet
    function withdrawAirgrabber() external {
        require(airgrabbers[msg.sender].ethAmount > 0, "No ETH to stake");
        require(!airgrabbers[msg.sender].ethClaimed, "Already airgrabbed ETH");
        airgrabbers[msg.sender].ethClaimed = true;
        msg.sender.transfer(airgrabbers[msg.sender].ethAmount);
    }

    // Accepts user's address and adds their ETH/CANE stakes due from the airgrab
    function addAirgrabber(address _airgrabber, uint256 _ethAmount, uint256 _caneAmount) external onlyOwner {
        require(!airgrabbers[_airgrabber].ethClaimed || !airgrabbers[_airgrabber].caneClaimed, "Airgrabber already claimed");
        airgrabbers[_airgrabber] = Airgrabber({
            ethAmount: _ethAmount,
            caneAmount: _caneAmount,
            ethClaimed: false,
            caneClaimed: false
        });
    }

    // transfer to treasury if problem found. allow disabling 
    // of this function, if we find all is well over time
    function disableSendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Already disabled");
        treasuryDisabled = true;
    }
    function sendToTreasury() external onlyOwner {
        require(!treasuryDisabled, "Invalid operation");
        treasury.transfer(address(this).balance);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // _rewardAllocation must be % number (e.g. 15 means 15%)
    
    function add(
        uint256 _rewardAllocation, 
        IERC20 _pairAddress, 
        IERC20 _otherToken
        ) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 _totalAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        for (uint256 pid = 0; pid < poolInfo.length; ++ pid) {
            _totalAllocation = _totalAllocation.add(poolInfo[pid].rewardAllocation);
        }
        require (_totalAllocation <= rewardAllocation, "Allocation exceeded");

        poolInfo.push(PoolInfo({
            pairAddress: _pairAddress,
            otherToken: _otherToken,
            rewardAllocation: rewardAllocation.mul(_rewardAllocation).div(100),
            borrowedSupply: 0,
            totalSupply: 0,
            rewardPerTokenStored: 0
        }));
    }

    // Update the given pool's CANE rewards. Can only be called by the owner.
    // _rewardAllocation must be % number (e.g. 15 means 15%)
    function set(uint256 _poolId, uint256 _rewardAllocation) external onlyOwner {
        require (_rewardAllocation <= 100, "Invalid allocation");
        uint256 totalAllocation = rewardAllocation.sub(poolInfo[_poolId].rewardAllocation).add(
            rewardAllocation.mul(_rewardAllocation).div(100)
        );
        require (totalAllocation <= rewardAllocation, "Allocation exceeded");
        
        if (poolInfo[_poolId].rewardAllocation != rewardAllocation.mul(_rewardAllocation).div(100)) {
            poolInfo[_poolId].rewardAllocation = rewardAllocation.mul(_rewardAllocation).div(100);
        }
    }

    // Fetches length of accounts in a pool
    // Allows easy front end iteration of accountInfos
    function accountInfosLength(uint256 _poolId) external view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        return accountInfosIndex[_poolId].length;
    }

    // Fetches details of account in the pool specified
    // Allows easy front end iteration of accountInfos
    function accountInfosByIndex(uint256 _poolId, uint256 _index) 
        external view returns (
            uint256 index,
            uint256 balance,
            uint256 lastWithdrawTimestamp,
            uint256 lastStakedTimestamp,
            uint256 reward,
            uint256 rewardPerTokenPaid,
            uint256 lpEthReward,
            uint256 lpEthRewardPaid,
            uint256 lpCaneReward,
            uint256 lpCaneRewardPaid,
            address userAddress) {

        require(_poolId < poolInfo.length, 'Invalid pool');
        userAddress = accountInfosIndex[_poolId][_index];
        AccountInfo memory account = accountInfos[_poolId][userAddress];
        return (
            account.index,
            account.balance,
            account.lastWithdrawTimestamp,
            account.lastStakedTimestamp,
            account.reward,
            account.rewardPerTokenPaid,
            account.lpEthReward,
            account.lpEthRewardPaid,
            account.lpCaneReward,
            account.lpCaneRewardPaid,
            userAddress
            );
    }

    // Fetches individual balances for each token in a pair
    function balanceOfPool(uint256 _poolId) external view returns (uint256, uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        
        uint256 otherTokenAmount = IERC20(pool.otherToken).balanceOf(address(pool.pairAddress));
        uint256 caneTokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));

        return (otherTokenAmount, caneTokenAmount);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function burnedTokenAmount() external view returns (uint256) {
        return cane.balanceOf(BURN_ADDRESS);
    }

    function rewardPerToken(uint256 _poolId) public view returns (uint256) {
        require(_poolId < poolInfo.length, 'Invalid pool');
        PoolInfo storage pool = poolInfo[_poolId];
        if (pool.totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }

        uint256 poolRewardRate = pool.rewardAllocation.mul(rewardRate).div(rewardAllocation);

        return pool.rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(poolRewardRate)
            .mul(1e18)
            .div(pool.totalSupply)
        );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTimestamp);
    }

    function rewardEarned(uint256 _poolId, address account) public view returns (uint256) {
        return accountInfos[_poolId][account].balance.mul(
            rewardPerToken(_poolId).sub(accountInfos[_poolId][account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[_poolId][account].reward);
    }

    // Token price in eth
    function tokenPrice(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolId];
        uint256 ethAmount = IERC20(weth).balanceOf(address(pool.pairAddress));
        uint256 tokenAmount = IERC20(cane).balanceOf(address(pool.pairAddress));
        
        return tokenAmount > 0 ?
        // Current price
        ethAmount.mul(1e18).div(tokenAmount) :
        // Initial price
        (uint256(1e18).div(1));
    }

    // Set all configurable parameters
    function setGoverningParameters(uint256[] memory _parameters) external onlyOwner {
        require(_parameters[0] >= 5 && _parameters[0] <= 50, "Invalid range");  //_parameters[0] _rewardHalvingPercent
        require(_parameters[1] >= 10 && _parameters[1] <= 50, "Invalid range"); //_parameters[1] _withdrawalLimitPercent
        require(_parameters[2] >= 1 && _parameters[2] <= 5, "Invalid range");   //_parameters[2] _claimBurnFee
        require(_parameters[3] >= 1 && _parameters[3] <= 5, "Invalid range");   //_parameters[3] _claimTreasuryFeePercent
        require(_parameters[4] >= 1 && _parameters[4] <= 5, "Invalid range");   //_parameters[4] _claimLPFeePercent
        require(_parameters[5] >= 25 && _parameters[5] <= 95, "Invalid range"); //_parameters[5] _claimLiquidBalancePercent
        require(_parameters[6] >= 1 && _parameters[6] <= 5, "Invalid range");   //_parameters[6] _unstakeBurnFeePercent
        require(_parameters[7] >= 1 && _parameters[7] <= 5, "Invalid range");   //_parameters[7] _unstakeTreasuryFeePercent
        require(_parameters[8] >= 1 && _parameters[8] <= 5, "Invalid range");   //_parameters[8] _unstakeLPFeePercent
        require(_parameters[9] >= 2 && _parameters[9] <= 10, "Invalid range");  //_parameters[9] _katrinaExitFeePercent
        require(_parameters[2]   // _claimBurnFee
            .add(_parameters[3]) // _claimTreasuryFeePercent
            .add(_parameters[4]) // _claimLPFeePercent
            .add(_parameters[5]) // _claimLiquidBalancePercent
            == 100, 'Invalid claim fees');
        rewardHalvingPercent = _parameters[0];
        withdrawalLimitPercent = _parameters[1];
        claimBurnFee = _parameters[2];
        claimTreasuryFeePercent = _parameters[3];
        claimLPFeePercent = _parameters[4];
        claimLiquidBalancePercent = _parameters[5];
        unstakeBurnFeePercent = _parameters[6];
        unstakeTreasuryFeePercent = _parameters[7];
        unstakeLPFeePercent = _parameters[8];
        katrinaExitFeePercent = _parameters[9];
    }
    
    // Only allow our farmingStartTimestamp to be changed between 72 hours
    // of the original schedule. Gives us flexibility in when to go live
    // if some unexpected circumstances happens (such as high gas prices)
    //
    // We must start farming somewhere between Dec 15, 2020 and Dec 16, 2020 19:00 GMT
    // Thanks Karl (Cat3) for the suggestion ;-)
    function setFarmingStartTimestamp(uint256 _farmingStartTimestamp) external onlyOwner {
        require(!farmingStarted && _farmingStartTimestamp >= 1608058800 && _farmingStartTimestamp <= 1608145200, "Invalid range");
        farmingStartTimestamp = _farmingStartTimestamp;
    }

    // Update user rewards
    function _updateReward(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        pool.rewardPerTokenStored = rewardPerToken(_poolId);
        lastUpdateTimestamp = lastRewardTimestamp();
        if (msg.sender != address(0)) {
            accountInfos[_poolId][msg.sender].reward = rewardEarned(_poolId, msg.sender);
            accountInfos[_poolId][msg.sender].rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }

    // Do halving when timestamp reached
    function _halving(uint256 _poolId) internal {
        if (block.timestamp >= halvingTimestamp) {
            rewardAllocation = rewardAllocation.mul(rewardHalvingPercent).div(100);

            rewardRate = rewardAllocation.div(HALVING_DURATION);
            halvingTimestamp = halvingTimestamp.add(HALVING_DURATION);

            _updateReward(_poolId);
            emit Halving(rewardAllocation);
        }
    }
    // Check if farming is started
    function _checkFarming() internal {
        require(farmingStartTimestamp <= block.timestamp, 'Farming has not yet started. Try again later.');
        if (!farmingStarted) {
            // We made it to this line, so farming has finally started! The Hurricane.Finance team 
            // would love to thank the following team members for their unwavering support:
            // Kart (Cat3); Foxtrot Delta; Storm Wins; psychologist; Lito; and Lizzie
            // ...and of course, me, Meteorologist - hehehe.
            //
            // Let's go, Hurricanes!
            farmingStarted = true;
            halvingTimestamp = block.timestamp.add(HALVING_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }
}"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/Hugo.sol": {
      "content": "pragma solidity ^0.6.12;

import "./lib/ERC20.sol";

// File: contracts/Hugo.sol
contract Hugo is ERC20 {
    
    address minter;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter can call this function.');
        _;
    }

    constructor(address _minter) public ERC20('Hurricane Gov', 'HGOV') {
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }
}
"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/interfaces/IERC20.sol": {
      "content": "pragma solidity ^0.6.12;

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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/interfaces/IUniswap.sol": {
      "content": "pragma solidity ^0.6.12;

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

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
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

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
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

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

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/interfaces/IWETH.sol": {
      "content": "pragma solidity ^0.6.12;

// File: contracts/uniswapv2/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/Address.sol": {
      "content": "pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/utils/Address.sol

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/Context.sol": {
      "content": "pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/ERC20.sol": {
      "content": "pragma solidity ^0.6.12;

import "./Address.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "../interfaces/IERC20.sol";

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
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
     * Requirements
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
}
"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/FeeHelpers.sol": {
      "content": "pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Math.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library FeeHelpers {
    using SafeMath for uint256;
    
    function getClaimBurnFee(uint256 lastStakedTimestamp, uint256 claimBurnFee) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(claimBurnFee);
        }
    }

    function getClaimTreasuryFee(uint256 lastStakedTimestamp, uint256 claimTreasuryFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(9);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(8);
        } else if (block.timestamp < lastStakedTimestamp + 3 days || block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(5);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(4);
        } else {
            return base.mul(100).div(claimTreasuryFeePercent);
        }
    }

    function getClaimLPFee(uint256 lastStakedTimestamp, uint256 claimLPFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(12);
        } else if (block.timestamp < lastStakedTimestamp + 3 days || block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(claimLPFeePercent);
        }
    }
    
    function getClaimLiquidBalancePcnt(uint256 lastStakedTimestamp, uint256 claimLiquidBalancePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days) {
            return base.mul(100).div(1);
        } else if (block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(10);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 3 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(20);
        } else {
            return base.mul(100).div(claimLiquidBalancePercent);
        }
    }

    function getUnstakeBurnFee(uint256 lastStakedTimestamp, uint256 unstakeBurnFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(unstakeBurnFeePercent);
        }
    }

    function getUnstakeTreasuryFee(uint256 lastStakedTimestamp, uint256 unstakeTreasuryFeePercent) public view returns (uint256) {
        uint256 base = 1;

        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(5);
        } else {
            return base.mul(100).div(unstakeTreasuryFeePercent);
        }
    }
    
    function getUnstakeLPFee(uint256 lastStakedTimestamp, uint256 unstakeLPFeePercent) public view returns (uint256) {
        uint256 base = 1;
        if (block.timestamp < lastStakedTimestamp + 1 days || block.timestamp < lastStakedTimestamp + 2 days) {
            return base.mul(100).div(25);
        } else if (block.timestamp < lastStakedTimestamp + 3 days) {
            return base.mul(100).div(20);
        } else if (block.timestamp < lastStakedTimestamp + 4 days) {
            return base.mul(100).div(15);
        } else if (block.timestamp > lastStakedTimestamp + 4 days && block.timestamp < lastStakedTimestamp + 29 days) {
            return base.mul(100).div(10);
        } else {
            return base.mul(100).div(unstakeLPFeePercent);
        }
    }

    function getKatrinaExitFee(uint256 katrinaExitFeePercent) public pure returns (uint256) {
        uint256 base = 1;
        return base.mul(100).div(katrinaExitFeePercent);
    }
}"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/Math.sol": {
      "content": "pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/Math.sol

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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/Ownable.sol": {
      "content": "pragma solidity ^0.6.12;

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}
"
    },
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/ReentrancyGuard.sol": {
      "content": "pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
contract ReentrancyGuard {
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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/SafeERC20.sol": {
      "content": "pragma solidity ^0.6.12;

import "./Address.sol";
import "./SafeMath.sol";

import "../interfaces/IERC20.sol";

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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
    "/Users/mwilliams/Library/Mobile Documents/com~apple~CloudDocs/Projects/Qubicles/Technology/Hurricane/testing/contracts/lib/SafeMath.sol": {
      "content": "pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        "FeeHelpers": "0x1dfff442355eA663aEEcF868df691b9013454B58"
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