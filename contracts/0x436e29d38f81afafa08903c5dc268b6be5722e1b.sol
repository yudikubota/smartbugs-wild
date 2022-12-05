{"Fibonacci.sol":{"content":"// SPDX-License-Identifier: No License

import "./Library.sol";

pragma solidity ^0.8.7;



//Fibonacci Token (FIB). An innovative token originally invented by @Nov

// t.me/FibonacciToken

/*                                               @@@@...@@@...@@@@                              
                                          @@...............................@@                      
                                    @@..........................................@.                
                               @@...................................................@             
                            @..........................................................@          
                        @................................................................@         
                     @.....................................................................@       
                   @.........................................................................&     
                 @............................................................................@    
              @................................................................................@   
             @..................................................................................@  
           @.....................................................................................@ 
          @.......................................................................................@ 
        @.........................................................................................@ 
       @..........................................................................................@ 
      @.......................................................    @@@.@..@  ,,,,,,,,,,,,,,,,,,,,,,@ 
     @........................................................ @....@.... @,,,,,,,,,,,,,,,,,,,,,,@ 
    @........................................................@......@..,,, @,,,,,,,,,,,,,,,,,,,,,@  
   @........................................................@........@@,@  ,,,,,,,,,,,,,,,,,,,,@   
  @.........................................................@..............,,,,,,,,,,,,,,,,,,,@    
  @..........................................................@.............,,,,,,,,,,,,,,,,,@      
 @........................................................... @............,,,,,,,,,,,,,,,@        
 @...........................................................   @..........,,,,,,,,,,,,,@          
 @...........................................................      @.......,,,,,,,,@@              
 
 
 
 
 */

//Update this version also has increasing fees that resets in a certain amount of time (1 day default) from your last sell or tx.
                                                                                                    
//Fiobonacci Token is a token that does not let price drop below a certain point 0.618 ratio from ATH for default.
//Every new ATH sets the price floor a new high, So price will be lifted at all times.
//This is against BNB not any stable token is BNB price drops any chart indicator will show you price is dropped below the threshold, this is not the case 
//Please look BNB pairing for charts not USD if you wanna see the real movements against BNB.

//Also apart from that , there is increased tax for investors who sell at close or at ATH. (About %5 percent near ATH).

//From psychological point of view I concluded these results:

//Token is self "marketing" or "shilling" , If you bought this token and price is below a certain point you will need other people to invest to gain access to your funds.
//So , any normal investor would "shill" their token to others , this would create a snowball effect and cycle would repeat with more people everytime.
//Normally when a token's price crashes people would just accept it and move on , this is not the case here.

//Selling close to ATH is a %12.5 percent loss for the maker. So any logical person would wait others to drop the price %5 percent before selling
//But if most people thinks like that amount of sell pressure at ATH is lowered by a lot.



//There is classic reflection and liquidity and burn traits of token which you can see below ( default is %0.5 , %3 , %0.5)
//Max wallet is %1.
//I do have a small dev fee %0.5 , but can be increased to 1.5% if something happens and i need funds for the token , (Maybe a marketing , or a new liquidity for other DEX etc.);
//I cannot increase dev fees beyond 1.5% contract does not allow that.

//Invest only what you can afford to lose.
//Price might be mathematically set to increase , BUT IF NO ONE BUYS THE TOKEN IT WILL STUCK !!!! BE CAREFUL WITH YOUR INVESTMENTS!!!.

//This is an experiment on BSC.Lets see if it goes viral.

//Disclaimer: By acquiring this token , you accept your own risks.

contract Fibonacci is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;


    mapping(address => uint256) private _dumpTaxes;
    mapping(address => uint256) private _dumpTaxesBlockTime;


    uint256 private constant MAX_EXCLUDED = 1024;
    EnumerableSet.AddressSet private _isExcludedFromReward;
    EnumerableSet.AddressSet private _isExcludedFromFee;
    EnumerableSet.AddressSet private _isExcludedFromSwapAndLiquify;

    EnumerableSet.AddressSet private _isBlackListed;
    EnumerableSet.AddressSet private _isWhiteListed;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private constant _name = "Fibonacci";
    string private constant _symbol = "FIB";
    uint8 private constant _decimals = 18;

    uint256 public _taxFeeVariable = 0;
    uint256 public _liquidityFeeVariable = 0;
    uint256 public _devFeeVariable = 0;
    uint256 public _burnFeeVariable = 0;


    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _devFee = 0;
    uint256 public _burnFee = 0;
    
    uint256 public _maxWalletSize = (_tTotal * 1) / 100; 
    
    uint256 private constant TOTAL_FEES_LIMIT = 2000;
    
    uint256 private constant DEV_FEES_LIMIT = 150;  //If needed.

    uint256 private constant MIN_TX_LIMIT = 100;
    uint256 public _maxTxAmount = 100000000 * 10**18;
    uint256 public _numTokensSellToAddToLiquidity = 20000 * 10**18;

    uint256 private _totalDevFeesCollected = 0;

    //Fibonacci Variables
    //They are multipled by 4 adding for Liq , Reflection , Burn and Dev fee.

    uint256 private constant ATH_DUMPER_FEE_MIN_LIMIT = 250;
    uint256 private constant ATH_DUMPER_FEE_MAX_LIMIT = 550;
    uint256 public _ATHDumperBurnAdd = 350;
 
    //Activates ATH Burn (max 17.5 percent.)
    uint256 private constant MIN_PER_ATH_LIMIT = 835;
    uint256 private constant MAX_PER_ATH_LIMIT = 975; 
    uint256 public PER_ATH_BURN_ACTIVATE = 950;
    
    uint256 _ATHPriceINBNB = 1000;
    
    //CurrentPrice but multipled by 10**20
    uint256 PriceNow = 1;
    uint256 MultPrecision = 10**20;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    
    //Golden ratio cannot be set higher than 619. MAX is just in case something fail, halves the floor price.
    //1/3 = 3.333 MAX so this token only can drop 66 percent at ALL costs. (Against BNB)
    
    
    uint256 private constant  GoldenRatioDMAX = 333;
    //1/1.618 = 0.618 (Math is interesting)
    uint256 public  GoldenRatioDivider = 618 ;
    //Cant be honeypot
    uint256 private constant GoldenRatioDMIN = 900;
    uint256 private RatioNow = 1000;

    // Liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;

    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    IUniswapV2Pair public uniSwapV2PairContract;


    address public pancakeRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//0x10ED43C718714eb63d5aA57B78B54704E256024E;
   

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event DevFeesCollected(uint256 bnbCollected);

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address cOwner) Ownable(cOwner) {
        _rOwned[cOwner] = _rTotal;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(pancakeRouter);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // Exclude system addresses from fee
        
         IUniswapV2Pair pairContract = IUniswapV2Pair(_uniswapV2Pair);
         uniSwapV2PairContract = pairContract;
        
        _isExcludedFromFee.add(owner());
        _isExcludedFromFee.add(address(this));
        _isExcludedFromSwapAndLiquify.add(_uniswapV2Pair);

        _isWhiteListed.add(address(this));
        _isWhiteListed.add(_uniswapV2Pair);
        _isWhiteListed.add(owner());


        _taxesForEachSell[0] = 25;
        _taxesForEachSell[1] = 75;
        _taxesForEachSell[2] = 175;
        _taxesForEachSell[3] = 180;
        _taxesForEachSell[4] = 200;
        _taxesForEachSell[5] = 350;
        _taxesForEachSell[6] = 740;
        _taxesForEachSell[7] = 1180;
        _taxesForEachSell[8] = 2500;
        _taxesForEachSell[9] = 12500;

        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    // BEP20
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward.contains(account)) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    
    //Fibonacci Price Checker Future
    function setPriceOfTokenSellFuture(uint256 soldBNB,uint256 golden) internal returns (uint256){

        uint256 FibonacciSupply; uint256 WBNB;

        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;

       }
         else{
        
        FibonacciSupply = token1;
            WBNB = token0;
        
        }

        FibonacciSupply = FibonacciSupply.add(golden);
        WBNB = WBNB.sub(soldBNB);
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }
        
        //Multipled by 10**20 to make division right;
         uint256 priceINBNB = (WBNB.mul(MultPrecision)).div(FibonacciSupply);
         
         
         if(priceINBNB > _ATHPriceINBNB){
             _ATHPriceINBNB = priceINBNB;
         }
         
         
        RatioNow = (priceINBNB.mul(1000)).div(_ATHPriceINBNB);
         
        return priceINBNB;
         
    } 


      function setPriceOfTokenBoughtFuture(uint256 addedBNB,uint256 soldgolden) internal returns (uint256){
        uint256 FibonacciSupply; uint256 WBNB;
    
        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;

       }
         else{
        
        FibonacciSupply = token1;
            WBNB = token0;
        
        }


       FibonacciSupply = FibonacciSupply.sub(soldgolden);
       WBNB = WBNB.add(addedBNB);
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }
        
        //Multipled by 10**20 to make division right;
         uint256 priceINBNB = (WBNB.mul(MultPrecision)).div(FibonacciSupply);
         
         
         if(priceINBNB > _ATHPriceINBNB){
             _ATHPriceINBNB = priceINBNB;
         }
         
         
        RatioNow = (priceINBNB.mul(1000)).div(_ATHPriceINBNB);
         
        return priceINBNB;
         
    } 


    function getPriceOfTokenNow() public view returns (uint256,uint256){
        return (RatioNow,_ATHPriceINBNB);        
    } 
    
    function getPriceOfTokenFuture(uint256 substractedBNB,uint256 addedGoldenRatio) public view returns (uint256){
              uint256 FibonacciSupply; uint256 WBNB;

        //For some reason this gets swapped at every added liq.
       (uint256 token0,uint256 token1, uint256 blocktimestamp) = uniSwapV2PairContract.getReserves();
        
        
       if(token0 > token1){
           FibonacciSupply = token0;
            WBNB = token1;
       }
         else{
        FibonacciSupply = token1;
            WBNB = token0;
        }
        //Lets not blow up.
        if(FibonacciSupply == 0){
            
            return 1;
        }

        //Multipled by 10**20 to make division right;
        uint256 totalGNow = FibonacciSupply.add(addedGoldenRatio);
        uint256 priceINBNB = ((WBNB.sub(substractedBNB)).mul(MultPrecision)).div(totalGNow);

        return priceINBNB;

    } 


    //10 is 1 percent.
    function setMaxWalletSize(uint256 maxWallet) external onlyOwner{
        require(maxWallet >= 10 , "Can't decerease maxwallet more than that.");
        _maxWalletSize = (_tTotal * maxWallet) / 10000; 

    }
    
    function setGoldenRatio(uint256 ratio) external onlyOwner{
        require(ratio > GoldenRatioDMAX,"Fibonacci cannot be lower than this.");
        require(ratio <= GoldenRatioDMIN,"Fibonacci cannot be higher than this.");
        GoldenRatioDivider = ratio;       

    }
    function setATHDumperFee(uint256 fee) external onlyOwner {
        require(fee <= ATH_DUMPER_FEE_MAX_LIMIT,"I know you want to punish them , but they are human too.");
        require(fee >= ATH_DUMPER_FEE_MIN_LIMIT, "I ain't that merciful.");
         _ATHDumperBurnAdd = fee;
    }

    function setATHDumperMaxPercent(uint256 feePercent) external onlyOwner {
        require(feePercent <= MAX_PER_ATH_LIMIT,"Can't increase ATH sell tax percentage more than this.");
        require(feePercent >= MIN_PER_ATH_LIMIT, "Can't decrease ATH sell tax percentage more than this.");
         PER_ATH_BURN_ACTIVATE = feePercent;
    }
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward.contains(sender),
            "Excluded addresses cannot call this function"
        );

        (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
            tAmount
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, , ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (uint256 rAmount, , ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rAmount;
        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount, ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(
            !_isExcludedFromReward.contains(account),
            "Account is already excluded in reward"
        );
        require(
            _isExcludedFromReward.length() < MAX_EXCLUDED,
            "Excluded reward set reached maximum capacity"
        );

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward.add(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(
            _isExcludedFromReward.contains(account),
            "Account is already included in reward"
        );

        _isExcludedFromReward.remove(account);
        _tOwned[account] = 0;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function devPercentageOfLiquidity() public view returns (uint256) {
        return (_devFee * 10000) / (_devFee.add(_liquidityFee));
    }

    /**
        @dev This is the portion of liquidity that will be sent to the uniswap router.
        Dev fees are considered part of the liquidity conversion.
     */
    function pureLiquidityPercentage() public view returns (uint256) {
        return (_liquidityFee * 10000) / (_devFee.add(_liquidityFee));
    }

    function totalDevFeesCollected() external view onlyDev returns (uint256) {
        return _totalDevFeesCollected;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee.add(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee.remove(account);
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(
            taxFee.add(_liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(
            _taxFee.add(liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _liquidityFee = liquidityFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner {
        require(
            devFee <= DEV_FEES_LIMIT,
            "Dev fees can not exceed the declared limit"
        );
        require(
            _taxFee.add(_liquidityFee).add(devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _devFee = devFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(
            _taxFee.add(_liquidityFee).add(_devFee).add(burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _burnFee = burnFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(
            maxTxPercent <= 10000,
            "Maximum transaction limit percentage can't be more than 100%"
        );
        require(
            maxTxPercent >= MIN_TX_LIMIT,
            "Maximum transaction limit can't be less than the declared limit"
        );
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    function setMinLiquidityPercent(uint256 minLiquidityPercent)
        external
        onlyOwner
    {
        require(
            minLiquidityPercent <= 10000,
            "Minimum liquidity percentage percentage can't be more than 100%"
        );
        require(
            minLiquidityPercent > 0,
            "Minimum liquidity percentage percentage can't be zero"
        );
        _numTokensSellToAddToLiquidity = _tTotal.mul(minLiquidityPercent).div(
            10000
        );
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee.contains(account);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward.contains(account);
    }

    function setIsExcludedFromSwapAndLiquify(address a, bool b)
        external
        onlyOwner
    {
        if (b) {
            _isExcludedFromSwapAndLiquify.add(a);
        } else {
            _isExcludedFromSwapAndLiquify.remove(a);
        }
    }

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }
    

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(to != devWallet(), "Dev wallet address cannot receive tokens");
        require(from != devWallet(), "Dev wallet address cannot send tokens");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool isOverMinTokenBalance = contractTokenBalance >=
            _numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromSwapAndLiquify.contains(from) &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if (
            _isExcludedFromFee.contains(from) || _isExcludedFromFee.contains(to)
        ) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function collectDevFees() public onlyDev {
        _totalDevFeesCollected = _totalDevFeesCollected.add(
            address(this).balance
        );
        devWallet().transfer(address(this).balance);
        emit DevFeesCollected(address(this).balance);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        // This variable holds the liquidity tokens that won't be converted
        uint256 liqTokens = tokenAmount.mul(pureLiquidityPercentage()).div(
            20000
        );
        // Everything else from the tokens should be converted
        uint256 tokensForBnbExchange = tokenAmount.sub(liqTokens);
        // This would be in the non-percentage form, 0 (0%) < devPortion < 10000 (100%)
        // The devPortion here indicates the portion of the converted tokens (BNB) that
        // would be assigned to the devWallet
        uint256 devPortion = tokenAmount.mul(devPercentageOfLiquidity()).div(
            tokensForBnbExchange
        );

        uint256 initialBalance = address(this).balance;

        swapTokensForBnb(tokensForBnbExchange);

        // How many BNBs did we gain after this conversion?
        uint256 gainedBnb = address(this).balance.sub(initialBalance);

        // Calculate the amount of BNB that's assigned to devWallet
        uint256 balanceToDev = (gainedBnb.mul(devPortion)).div(10000);
        // The leftover BNBs are purely for liquidity
        uint256 liqBnb = gainedBnb.sub(balanceToDev);

        addLiquidity(liqTokens, liqBnb);

        emit SwapAndLiquify(tokensForBnbExchange, liqBnb, liqTokens);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lockedLiquidity(),
            block.timestamp
        );
    }

    //These are required for adding Liq and potential save mechanism if something fails
    //When shutdowncancel activated Owner can no longer interfere.
    bool AthThingEnabled = true;

    function setFeesToZero() external onlyOwner{
        
        _taxFeeVariable = 0;
        _liquidityFeeVariable = 0;
        _devFeeVariable = 0;
        _burnFeeVariable = 0;

    }

    function setFeesBackToDefault() external onlyOwner{

        _taxFee = 50;
        _liquidityFee = 300;
        _devFee = 150;
        _burnFee = 50;
   

    }

    function setFeesBackToNormalInternal() internal {

        _taxFeeVariable = _taxFee;
        _liquidityFeeVariable = _liquidityFee;
        _devFeeVariable = _devFee;
        _burnFeeVariable = _burnFee;
   

    }

    function setATHthingEnabled(bool isit) external onlyOwner{
        AthThingEnabled = isit;
    }

    function setFeeResetTime(uint256 time) external onlyOwner{
        feeResetTime = time;
    }

    uint256 feeResetTime = 60*60*24*14; //2 Weeks
    bool cancelSellConstraints  = false;
    bool canCancel = true;

    function ShutDownCancel() external onlyOwner{
        cancelSellConstraints = true;
        canCancel = false;
    }
    function setSellContraints(bool what) external onlyOwner{
        if(canCancel){
            cancelSellConstraints = what;
        }
    }

    //Sets increasing tax enabled.
    bool private increasingTax = false;
    function setIncreasingTaxForSellsEnabled(bool what) external onlyOwner{
        if(canCancel){
        increasingTax = what;
        }
    }

    //If something fails and tax are getting added constantly this function will be activated.
    bool private setToNormalOnSomeError  = false;
        function setToNormalOnAnyError(bool what) external onlyOwner{
        setToNormalOnSomeError = what;
    }

    function addATHFees() internal returns (bool) {
        bool ATHsAdded = false;
        if(AthThingEnabled){
        if(RatioNow > PER_ATH_BURN_ACTIVATE){   
             ATHsAdded = true;            
             _liquidityFeeVariable += _ATHDumperBurnAdd;
             _burnFeeVariable += _ATHDumperBurnAdd;
             _taxFeeVariable += _ATHDumperBurnAdd;
             _devFeeVariable += _ATHDumperBurnAdd;
                }
              }
        return ATHsAdded;  
    
    }
    
    mapping(uint256 => uint256) private _taxesForEachSell;

    function setTaxesByAmount(uint256 taxnumber,uint256 tax) external onlyOwner{
        _taxesForEachSell[taxnumber] = tax; 
    }

    function setTaxesToDefaultForSellTaxes() external onlyOwner(){
        _taxesForEachSell[0] = 25;
        _taxesForEachSell[1] = 55;
        _taxesForEachSell[2] = 60;
        _taxesForEachSell[3] = 120;
        _taxesForEachSell[4] = 180;
        _taxesForEachSell[5] = 350;
        _taxesForEachSell[6] = 740;
        _taxesForEachSell[7] = 1180;
        _taxesForEachSell[8] = 2500;
        _taxesForEachSell[9] = 12500;
    }

    function getMyTaxInformation () view public returns (uint256 myTx,uint256 tax,uint256 leftTime){
        uint256 blocktime = block.timestamp;
        uint256 currentSellTaxNumber = _dumpTaxes[msg.sender];
        uint256 currentBlockTimeSeller = _dumpTaxesBlockTime[msg.sender];
        uint256 time = 0;
        uint256 addedTaxesTotal = _taxesForEachSell[currentSellTaxNumber];
        if(blocktime > currentBlockTimeSeller){
            time = blocktime.sub(currentBlockTimeSeller);
         }
        
        if(addedTaxesTotal == 0 && currentSellTaxNumber > 3){
                        addedTaxesTotal = maxSellTax;

                    }
        return (currentSellTaxNumber,addedTaxesTotal,time);
    }

    uint256 private maxSellTax = 12500;

    function setMaxSellTax(uint256 maxTax) external onlyOwner {
        maxSellTax = maxTax;
    }

    function addIncreasedTaxes(address sender) internal{
        uint256 blocktime = block.timestamp;
        uint256 currentSellTaxNumber = _dumpTaxes[sender];
        uint256 currentBlockTimeSeller = _dumpTaxesBlockTime[sender];
        uint256 addedTaxesTotal = 0;

        if(increasingTax){
              if(sender != _uniswapV2Pair){
                if(blocktime > currentBlockTimeSeller){

                    uint256 left = blocktime.sub(currentBlockTimeSeller);
                    _dumpTaxesBlockTime[sender] = blocktime;
                    addedTaxesTotal = _taxesForEachSell[currentSellTaxNumber];
                    if(addedTaxesTotal == 0 && currentSellTaxNumber > 3){
                        addedTaxesTotal = maxSellTax;
                    }

                    if(left >= feeResetTime){
                        _dumpTaxes[sender] = 0;
                        addedTaxesTotal = 0;
                    }
                     if(left < feeResetTime){
                        _dumpTaxes[sender] = currentSellTaxNumber + 1;
                    }

                }
                }
              }

         _liquidityFeeVariable += addedTaxesTotal;
         _burnFeeVariable += addedTaxesTotal;
         _taxFeeVariable += addedTaxesTotal;
         _devFeeVariable += addedTaxesTotal;      

    }

    function removeTaxes(uint256 taxes) internal{
            if(_liquidityFeeVariable >= taxes){
             _liquidityFeeVariable = _liquidityFeeVariable - taxes;
            }
            if(_burnFeeVariable >= taxes){
             _burnFeeVariable = _burnFeeVariable - taxes; 
            }
            if(_taxFeeVariable >= taxes){
             _taxFeeVariable = _taxFeeVariable - taxes; 
            }
            if(_devFeeVariable >= taxes){
             _devFeeVariable = _devFeeVariable - taxes;
            }
    }


    bool whitelistEnabled = false;
    bool blacklistEnabled = false;

    function addToWhiteList(address added) external onlyOwner
    {
        _isWhiteListed.add(added);
    }


    function addToBlackList(address added) external onlyOwner
    {
        _isBlackListed.add(added);
    }

    function setWhitelistEnabled(bool whitelist) external onlyOwner {
        whitelistEnabled = whitelist;
    }

    function setBlackListEnabled(bool blacklist) external onlyOwner {
        blacklistEnabled = blacklist;
    }
    bool private removeDevM = false;
    function removeDevMode () external onlyOwner{
        removeDevM = true;
        devMod = false;


    }
    bool private devMod = true;
    function devMode(bool buys) external onlyOwner
    {
        require(!removeDevM,"Dev mode is closed forever.");
        devMod = buys;
    }


    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        

        //Checking _maxWalletSize
        if(!devMod){  
        if (recipient != _uniswapV2Pair && recipient != DEAD && recipient != pancakeRouter ) {

            require(balanceOf(recipient) + amount <= _maxWalletSize, "Transfer amount exceeds the max size.");
            
        }
        }
        //BlackList
        if(blacklistEnabled){
            require(!_isBlackListed.contains(sender) , "Address is blacklisted.");
            require(!_isBlackListed.contains(recipient) , "Address is blacklisted.");
        }
         //Whitelist
        if(whitelistEnabled){
            require(_isWhiteListed.contains(sender) , "Address is not whitelisted.");
            require(_isWhiteListed.contains(recipient) , "Address is not whitelisted.");
        }
        
        //Cancels liq additions while devmod is on.
        if(devMod){  
            if(recipient == _uniswapV2Pair){
                require(sender == owner(),"Only owner can add liq.");
            }

        }
        
        //Adding ATH sell fee and sell constraints
        if(recipient == _uniswapV2Pair && cancelSellConstraints){ //IF selling
            
              address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapV2Router.WETH();
                
               uint256 WillbedrainedBNB = _uniswapV2Router.getAmountsOut(amount,path)[1];
               uint256 futurePrice = getPriceOfTokenFuture(WillbedrainedBNB,amount);
               
               
               //So if any future price goes below GoldenRatioDivider no selling will happen.
               
                require(futurePrice.mul(1000).div(_ATHPriceINBNB) >= GoldenRatioDivider,"Transaction will drop the price below the GoldenRatio , reverted.");
                require(RatioNow >= GoldenRatioDivider,"Idk how you passed that requirement but it stops here.");
                
               //Set price of token for sells.
                setPriceOfTokenSellFuture(WillbedrainedBNB,amount);
                //set IncreasedTaxes.
                addIncreasedTaxes(sender);
                //ATH dumper fee
                addATHFees();
            
        }

        if(sender == _uniswapV2Pair && cancelSellConstraints){  //If buying    
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _uniswapV2Router.WETH();
                //This will be an estimate but should be pretty good if no big changes to price.
               uint256 WillbeAddedBNB = _uniswapV2Router.getAmountsOut(amount,path)[1];
               setPriceOfTokenBoughtFuture(WillbeAddedBNB,amount);

         }
            //Add the tax on everytransaction no matter what.So cannot send it to another wallets without tax.
         if(sender != _uniswapV2Pair && recipient != _uniswapV2Pair){
             //set IncreasedTaxes.
             addIncreasedTaxes(sender);
         }

        if (!takeFee || devMod) {
            _taxFeeVariable = 0;
            _liquidityFeeVariable = 0;
            _devFeeVariable = 0;
            _burnFeeVariable = 0;
        }

        bool senderExcluded = _isExcludedFromReward.contains(sender);
        bool recipientExcluded = _isExcludedFromReward.contains(recipient);
        if (senderExcluded && !recipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!senderExcluded && recipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!senderExcluded && !recipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (senderExcluded && recipientExcluded) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
     
        setFeesBackToNormalInternal();


   

        
        
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 rBurn,
        uint256 tFee,
        uint256 tBurn
    ) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(_taxFeeVariable).div(10000);
        // We treat the dev fee as part of the total liquidity fee
        uint256 tLiquidity = tAmount.mul(_liquidityFeeVariable.add(_devFeeVariable)).div(10000);
        uint256 tBurn = tAmount.mul(_burnFeeVariable).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _isExcludedFromReward.length(); i++) {
            address excludedAddress = _isExcludedFromReward.at(i);
            if (
                _rOwned[excludedAddress] > rSupply ||
                _tOwned[excludedAddress] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[excludedAddress]);
            tSupply = tSupply.sub(_tOwned[excludedAddress]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function takeTransactionFee(
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        if (tAmount <= 0) {
            return;
        }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcludedFromReward.contains(to)) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
}
"},"Library.sol":{"content":"pragma solidity ^0.8.7;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
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



pragma solidity ^0.8.7;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}


pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



pragma solidity ^0.8.7;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;
    address private _lockedLiquidity;
    address payable private _devWallet;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function lockedLiquidity() public view returns (address) {
        return _lockedLiquidity;
    }

    function devWallet() internal view returns (address payable) {
        return _devWallet;
    }
    
    function devWalletByOwner() external view onlyOwner returns (address payable) {
        return _devWallet;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDev() {
        require(
            _devWallet == _msgSender(),
            "Caller is not the devWallet address"
        );
        _;
    }

    function setDevWalletAddress(address payable devWalletAddress)
        public
        virtual
        onlyOwner
    {
        require(
            _devWallet == address(0),
            "Dev wallet address cannot be changed once set"
        );
        _devWallet = devWalletAddress;
    }

    function setLockedLiquidityAddress(address liquidityAddress)
        public
        virtual
        onlyOwner
    {
        require(
            _lockedLiquidity == address(0),
            "Locked liquidity address cannot be changed once set"
        );
        _lockedLiquidity = liquidityAddress;
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

"}}