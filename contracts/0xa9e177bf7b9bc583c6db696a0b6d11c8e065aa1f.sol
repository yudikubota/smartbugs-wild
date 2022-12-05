{{
  "language": "Solidity",
  "sources": {
    "/home/travis/Documents/Ubuntu_Shared/misc-frax-contracts/contracts/IFraxPartial.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.5.7;

interface IFraxPartial {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function owner_address() external returns (address);
    function creator_address() external returns (address);
    function timelock_address() external returns (address);
    function controller_address() external returns (address);
    function fxs_address() external returns (address);
    function frax_eth_oracle_address() external returns (address);
    function fxs_eth_oracle_address() external returns (address);
    function weth_address() external returns (address);
    function eth_usd_consumer_address() external returns (address);

    function genesis_supply() external returns (uint256);
    function frax_pools_array() external returns (address[] memory);

    function frax_pools(address a) external returns (bool);
    function global_collateral_ratio() external returns (uint256);
    function redemption_fee() external returns (uint256);
    function minting_fee() external returns (uint256);
    function frax_step() external returns (uint256);
    function refresh_cooldown() external returns (uint256);
    function price_target() external returns (uint256);
    function price_band() external returns (uint256);

    function DEFAULT_ADMIN_ADDRESS() external returns (address);
    function COLLATERAL_RATIO_PAUSER() external returns (bytes32);
    function collateral_ratio_paused() external returns (bool);
    function last_call_time() external returns (uint256);
    
    /* ========== VIEWS ========== */
    function frax_price() external returns (uint256);
    function fxs_price()  external returns (uint256);
    function eth_usd_price() external returns (uint256);
    function frax_info() external returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function globalCollateralValue() external returns (uint256);

    /* ========== PUBLIC FUNCTIONS ========== */
    function refreshCollateralRatio() external;
}"
    },
    "/home/travis/Documents/Ubuntu_Shared/misc-frax-contracts/contracts/IFraxPool.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.5.7;

interface IFraxPool {
    function minting_fee() external returns (uint256);
    function redemption_fee() external returns (uint256);
    function buyback_fee() external returns (uint256);
    function recollat_fee() external returns (uint256);
    function collatDollarBalance() external returns (uint256);
    function availableExcessCollatDV() external returns (uint256);
    function getCollateralPrice() external returns (uint256);
    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external;
    function mint1t1FRAX(uint256 collateral_amount, uint256 FRAX_out_min) external;
    function mintAlgorithmicFRAX(uint256 fxs_amount_d18, uint256 FRAX_out_min) external;
    function mintFractionalFRAX(uint256 collateral_amount, uint256 fxs_amount, uint256 FRAX_out_min) external;
    function redeem1t1FRAX(uint256 FRAX_amount, uint256 COLLATERAL_out_min) external;
    function redeemFractionalFRAX(uint256 FRAX_amount, uint256 FXS_out_min, uint256 COLLATERAL_out_min) external;
    function redeemAlgorithmicFRAX(uint256 FRAX_amount, uint256 FXS_out_min) external;
    function collectRedemption() external;
    function recollateralizeFRAX(uint256 collateral_amount, uint256 FXS_out_min) external;
    function buyBackFXS(uint256 FXS_amount, uint256 COLLATERAL_out_min) external;
    function toggleMinting() external;
    function toggleRedeeming() external;
    function toggleRecollateralize() external;
    function toggleBuyBack() external;
    function toggleCollateralPrice(uint256 _new_price) external;
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external;
    function setTimelock(address new_timelock) external;
    function setOwner(address _owner_address) external;
}"
    },
    "/home/travis/Documents/Ubuntu_Shared/misc-frax-contracts/contracts/IUniswapV2Router02.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.5.7;


interface IUniswapV2Router02 {
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
    "/home/travis/Documents/Ubuntu_Shared/misc-frax-contracts/contracts/IWETH.sol": {
      "content": "pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}"
    },
    "/home/travis/Documents/Ubuntu_Shared/misc-frax-contracts/contracts/StakingUtilities.sol": {
      "content": "pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import './IUniswapV2Router02.sol';
import './IFraxPool.sol';
import './IFraxPartial.sol';
import './IWETH.sol';


contract StakingUtilities {
    using SafeMath for uint256;
    address constant private USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private FRAX_ADDRESS = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant private FXS_ADDRESS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address payable constant public UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public POOL_ADDRESS = 0x1864Ca3d47AaB98Ee78D11fc9DCC5E7bADdA1c0d;
    address public NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    IERC20 constant internal USDC_ERC20 = IERC20(USDC_ADDRESS);
    IERC20 constant internal WETH_ERC20 = IERC20(WETH_ADDRESS);
    IERC20 constant internal FRAX_ERC20 = IERC20(FRAX_ADDRESS);
    IERC20 constant internal FXS_ERC20 = IERC20(FXS_ADDRESS);
    IERC20 constant internal ETH_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH constant internal WETH_IWETH = IWETH(WETH_ADDRESS);

    IFraxPool internal FRAX_POOL = IFraxPool(POOL_ADDRESS);
    IFraxPartial internal FRAX = IFraxPartial(FRAX_ADDRESS);

    IUniswapV2Router02 constant internal UniswapV2Router02 = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    address public owner_address;
    
    address payable public owner_address_payable;
    bool public is_paused;
    uint256 public minting_fee;
    uint256 private missing_decimals;
    uint256 public ADD_LIQUIDITY_SLIPPAGE = 950; // will be .div(1000)

    // Super jank
    mapping(uint256 => address[]) PATHS; 

    struct MintFF_Params {
        uint256 fxs_price_usd; 
        uint256 col_price_usd;
        uint256 fxs_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner {
        require(msg.sender == owner_address, "Only the contract owner may perform this action");
        _;
    }

    modifier notPaused {
        require(is_paused == false, "Contract is paused");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor () public {
        owner_address = msg.sender;
        owner_address_payable = msg.sender;
        is_paused = false;
        PATHS[0] = [WETH_ADDRESS, USDC_ADDRESS];
        PATHS[1] = [WETH_ADDRESS, FRAX_ADDRESS, FXS_ADDRESS];
        minting_fee = FRAX_POOL.minting_fee();
        missing_decimals = 12; // manually set for USDC now
    }

    /* ========== VIEWS ========== */

    // Must be internal because of the struct
    function calcMintFractionalFRAX(MintFF_Params memory params) public view returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint FRAX. We do this by seeing the minimum mintable FRAX based on each amount 
        uint256 fxs_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the FXS
            fxs_dollar_value_d18 = params.fxs_amount.mul(params.fxs_price_usd).div(1e6);
            c_dollar_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);

        }
        uint calculated_fxs_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(params.col_ratio))
                    .sub(c_dollar_value_d18);

        uint fxs_needed = calculated_fxs_dollar_value_d18.mul(1e6).div(params.fxs_price_usd);

        uint mint_amount = c_dollar_value_d18.add(calculated_fxs_dollar_value_d18);
        mint_amount = (mint_amount.mul(uint(1e6).sub(minting_fee))).div(1e6);

        return (
            mint_amount,
            fxs_needed
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */


    function mintFRAXWrapper(
        uint256 input_collat,
        uint256 input_fxs,
        uint256 frax_out_min
    ) public returns (uint256 [2] memory)
    {
        uint256 collateral_amount_d18 = input_collat * (10 ** missing_decimals);

        MintFF_Params memory input_params = MintFF_Params(
            FRAX.fxs_price(),
            FRAX_POOL.getCollateralPrice(),
            input_fxs,
            collateral_amount_d18,
            FRAX.global_collateral_ratio()
        );

        (uint256 mint_amount, uint256 fxs_needed) = calcMintFractionalFRAX(input_params);

        require(input_fxs >= fxs_needed, "input_fxs >= fxs_needed");

        require(mint_amount >= frax_out_min, "Not enough FRAX minted");

        // Approve FXS for FraxPool
        IERC20(FXS_ADDRESS).approve(POOL_ADDRESS, fxs_needed);

        // Approve USDC for FraxPool
        IERC20(USDC_ADDRESS).approve(POOL_ADDRESS, input_collat);

        // Mint
        FRAX_POOL.mintFractionalFRAX(input_collat, fxs_needed, mint_amount);

        return [mint_amount, fxs_needed];
    }

    function FXS_To_USDC(
        uint256 FXS_for_USDC_swap,
        uint256 col_out_min
    ) public returns (uint256)
    {
        address[] memory FXS_FRAX_USDC_PATH = new address[](3);
        FXS_FRAX_USDC_PATH[0] = FXS_ADDRESS;
        FXS_FRAX_USDC_PATH[1] = FRAX_ADDRESS;
        FXS_FRAX_USDC_PATH[2] = USDC_ADDRESS;

        // Do the swap
        (uint[] memory amounts) = UniswapV2Router02.swapExactTokensForTokens(
            FXS_for_USDC_swap,
            col_out_min,
            FXS_FRAX_USDC_PATH,
            address(this),
            2105300114 // A long time from now
        );

        // Make sure enough USDC was received
        require(amounts[2] >= col_out_min, "FXS_To_USDC: Not enough USDC received from swap");

        return (amounts[2]);
    }

    function FXS_To_WETH(
        uint256 FXS_for_WETH_swap,
        uint256 weth_out_min
    ) public returns (uint256)
    {
        address[] memory FXS_FRAX_WETH_PATH = new address[](3);
        FXS_FRAX_WETH_PATH[0] = FXS_ADDRESS;
        FXS_FRAX_WETH_PATH[1] = FRAX_ADDRESS;
        FXS_FRAX_WETH_PATH[2] = WETH_ADDRESS;

        // Do the swap
        (uint[] memory amounts) = UniswapV2Router02.swapExactTokensForTokens(
            FXS_for_WETH_swap,
            weth_out_min,
            FXS_FRAX_WETH_PATH,
            address(this),
            2105300114 // A long time from now
        );

        // Make sure enough WETH was received
        require(amounts[2] >= weth_out_min, "FXS_To_WETH: Not enough WETH received from swap");

        return (amounts[2]);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Assumes a FRAX_USDC LP 
    // INPUT_PARAMS[0] uint256 FXS_total_input
    // INPUT_PARAMS[1] uint256 FXS_for_mint
    // INPUT_PARAMS[2] uint256 FXS_for_USDC_swap
    // INPUT_PARAMS[3] uint256 col_out_min
    // INPUT_PARAMS[4] uint256 col_allocated_for_mint_slipped
    // INPUT_PARAMS[5] uint256 frax_out_min
    function swapFXSForFRAXUSDCLP(
        uint256[] calldata INPUT_PARAMS
    ) external notPaused {

        // =================== Pull in the needed FXS ===================
        IERC20(FXS_ADDRESS).transferFrom(msg.sender, address(this), INPUT_PARAMS[0]);

        // =================== Approve FXS for Uniswap ===================
        IERC20(FXS_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, INPUT_PARAMS[0]);

        // =================== FXS -> USDC via Uniswap ===================
        (uint256 received_USDC) = FXS_To_USDC(INPUT_PARAMS[2], INPUT_PARAMS[3]);

        // =================== Estimate and mint the FRAX component ===================
        // (uint256 mint_amount, uint256 fxs_needed )
        uint256[2] memory mint_results = mintFRAXWrapper(INPUT_PARAMS[4], INPUT_PARAMS[1], INPUT_PARAMS[5]);

        // =================== Add Liquidity ===================

        // Approve FRAX for Uniswap
        IERC20(FRAX_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, mint_results[0]);

        // Approve USDC for Uniswap
        IERC20(USDC_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, received_USDC);

        // Add liquidity and send the token to the sender 
        (uint256 lp_frax_used, uint256 lp_usdc_used, ) = UniswapV2Router02.addLiquidity(
			FRAX_ADDRESS, 
			USDC_ADDRESS,
			mint_results[0], 
			mint_results[0].div(1e12), 
            mint_results[0].mul(ADD_LIQUIDITY_SLIPPAGE).div(1000),
            mint_results[0].mul(ADD_LIQUIDITY_SLIPPAGE).div(1e15), // div(1e12).mul(ADD_LIQUIDITY_SLIPPAGE).div(1e3)
            msg.sender,
            2105300114 // A long time from now
		);

        // Return unused FRAX to sender.
        FRAX_ERC20.transfer(msg.sender, mint_results[0].sub(lp_frax_used));

        // Return unused USDC to sender.
        USDC_ERC20.transfer(msg.sender, received_USDC.sub(INPUT_PARAMS[4]).sub(lp_usdc_used));

        // Return unused FXS to sender.
        FXS_ERC20.transfer(msg.sender, INPUT_PARAMS[0].sub(INPUT_PARAMS[2]).sub(mint_results[1]));

    }

    // Assumes a FRAX_WETH LP 
    // INPUT_PARAMS[0] uint256 FXS_total_input
    // INPUT_PARAMS[1] uint256 FXS_for_mint
    // INPUT_PARAMS[2] uint256 FXS_for_col_swap
    // INPUT_PARAMS[3] uint256 col_out_min
    // INPUT_PARAMS[4] uint256 FXS_for_WETH_swap
    // INPUT_PARAMS[5] uint256 weth_out_min
    // INPUT_PARAMS[6] uint256 frax_out_min
    function swapFXSForFRAXWETHLP(
        uint256[] calldata INPUT_PARAMS
    ) external notPaused {

        // =================== Pull in the needed FXS ===================
        IERC20(FXS_ADDRESS).transferFrom(msg.sender, address(this), INPUT_PARAMS[0]);

        // =================== Approve FXS for Uniswap ===================
        IERC20(FXS_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, INPUT_PARAMS[0]);

        // =================== FXS -> USDC via Uniswap ===================
        (uint256 received_USDC) = FXS_To_USDC(INPUT_PARAMS[2], INPUT_PARAMS[3]);

        // =================== FXS -> WETH via Uniswap ===================
        (uint256 received_WETH) = FXS_To_WETH(INPUT_PARAMS[4], INPUT_PARAMS[5]);

        // =================== Estimate and mint the FRAX component ===================
        // (uint256 mint_amount, uint256 fxs_needed )
        uint256[2] memory mint_results = mintFRAXWrapper(INPUT_PARAMS[3], INPUT_PARAMS[1], INPUT_PARAMS[6]);

         // =================== Add Liquidity ===================

        // Approve FRAX for Uniswap
        IERC20(FRAX_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, mint_results[0]);

        // Approve USDC for Uniswap
        IERC20(WETH_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, received_WETH);

        // Add liquidity and send the token to the sender 
        (uint256 lp_frax_used, uint256 lp_weth_used, ) = UniswapV2Router02.addLiquidity(
			FRAX_ADDRESS, 
			WETH_ADDRESS,
			mint_results[0], 
			received_WETH, 
            mint_results[0].mul(ADD_LIQUIDITY_SLIPPAGE).div(1000),
            received_WETH.mul(ADD_LIQUIDITY_SLIPPAGE).div(1000),
            msg.sender,
            2105300114 // A long time from now
		);

        {}

        // Return unused FRAX to sender.
        FRAX_ERC20.transfer(msg.sender, mint_results[0].sub(lp_frax_used));

        // Return unused USDC to sender.
        USDC_ERC20.transfer(msg.sender, received_USDC.sub(INPUT_PARAMS[3]));

        // Return unused WETH to sender.
        WETH_ERC20.transfer(msg.sender, received_WETH.sub(INPUT_PARAMS[5]).sub(lp_weth_used));

        // Return unused FXS to sender.
        FXS_ERC20.transfer(msg.sender, INPUT_PARAMS[0].sub(INPUT_PARAMS[2]).sub(INPUT_PARAMS[4]).sub(mint_results[1]));

    }

    // Assumes a FRAX_FXS LP 
    // INPUT_PARAMS[0] uint256 FXS_total_input
    // INPUT_PARAMS[1] uint256 FXS_for_mint
    // INPUT_PARAMS[2] uint256 FXS_for_col_swap
    // INPUT_PARAMS[3] uint256 col_out_min
    // INPUT_PARAMS[4] uint256 FXS_bypassed
    // INPUT_PARAMS[5] uint256 fxs_bypassed_min
    // INPUT_PARAMS[6] uint256 frax_out_min
    function swapFXSForFRAXFXSLP(
        uint256[] calldata INPUT_PARAMS
    ) external notPaused {

        // =================== Pull in the needed FXS ===================
        IERC20(FXS_ADDRESS).transferFrom(msg.sender, address(this), INPUT_PARAMS[0]);

        // =================== Approve FXS for Uniswap ===================
        IERC20(FXS_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, INPUT_PARAMS[0]);

        // =================== FXS -> USDC via Uniswap ===================
        // Scoped for stack size concerns
        {
            (uint256 received_USDC) = FXS_To_USDC(INPUT_PARAMS[2], INPUT_PARAMS[3]);

            // Return unused USDC to sender.
            USDC_ERC20.transfer(msg.sender, received_USDC.sub(INPUT_PARAMS[3]));
        }

        // =================== Estimate and mint the FRAX component ===================
        // (uint256 mint_amount, uint256 fxs_needed )
        uint256[2] memory mint_results = mintFRAXWrapper(INPUT_PARAMS[3], INPUT_PARAMS[1], INPUT_PARAMS[6]);

         // =================== Add Liquidity ===================

        // Approve FRAX for Uniswap
        IERC20(FRAX_ADDRESS).approve(UNISWAP_ROUTER_ADDRESS, mint_results[0]);

        // Add liquidity and send the token to the sender 
        (uint256 lp_frax_used, uint256 lp_fxs_used, ) = UniswapV2Router02.addLiquidity(
			FRAX_ADDRESS, 
			FXS_ADDRESS,
			mint_results[0], 
			INPUT_PARAMS[4], 
            mint_results[0].mul(ADD_LIQUIDITY_SLIPPAGE).div(1000),
            INPUT_PARAMS[5].mul(ADD_LIQUIDITY_SLIPPAGE).div(1000), 
            msg.sender,
            2105300114 // A long time from now
		);

        // Return unused FRAX to sender.
        FRAX_ERC20.transfer(msg.sender, mint_results[0].sub(lp_frax_used));



        // Return unused FXS to sender.
        FXS_ERC20.transfer(msg.sender, INPUT_PARAMS[0].sub(INPUT_PARAMS[2]).sub(mint_results[1]).sub(lp_fxs_used));

    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // The smart contract should never end up having to need this as there should be no deposits. Just for emergency purposes
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner_address, tokenAmount);
    }

    function withdraw() external onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }

    function selfDestruct() external payable onlyOwner {
        selfdestruct(owner_address_payable);
    }

    function togglePaused() external onlyOwner {
        is_paused = !is_paused;
    } 

    function setPoolAddress(address _pool_address) external onlyOwner {
        POOL_ADDRESS = _pool_address;
        FRAX_POOL = IFraxPool(_pool_address);
    }

    function setLiquiditySlippage(uint256 _add_liquidity_slippage) external onlyOwner {
        ADD_LIQUIDITY_SLIPPAGE = _add_liquidity_slippage;
    }
}"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.5.0;

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
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
      "runs": 100000
    },
    "evmVersion": "istanbul",
    "libraries": {},
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