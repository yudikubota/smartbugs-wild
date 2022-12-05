{"ACOAssetHelper.sol":{"content":"pragma solidity ^0.6.6;

library ACOAssetHelper {
    
    /**
     * @dev Internal function to get if the address is for Ethereum (0x0).
     * @param _address Address to be checked.
     * @return Whether the address is for Ethereum.
     */ 
    function _isEther(address _address) internal pure returns(bool) {
        return _address == address(0);
    }
    
    /**
     * @dev Internal function to approve ERC20 tokens.
     * @param token Address of the token.
     * @param spender Authorized address.
     * @param amount Amount to authorize.
     */
    function _callApproveERC20(address token, address spender, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(0x095ea7b3, spender, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOAssetHelper::_callApproveERC20");
    }
    
    /**
     * @dev Internal function to transfer ERC20 tokens.
     * @param token Address of the token.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
    function _callTransferERC20(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOAssetHelper::_callTransferERC20");
    }
    
    /**
     * @dev Internal function to call transferFrom on ERC20 tokens.
     * @param token Address of the token.
     * @param sender Address of the sender.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
     function _callTransferFromERC20(address token, address sender, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOAssetHelper::_callTransferFromERC20");
    }
    
    /**
     * @dev Internal function to the asset symbol.
     * @param asset Address of the asset.
     * @return The asset symbol.
     */
    function _getAssetSymbol(address asset) internal view returns(string memory) {
        if (_isEther(asset)) {
            return "ETH";
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x95d89b41));
            require(success, "ACOAssetHelper::_getAssetSymbol");
            return abi.decode(returndata, (string));
        }
    }
    
    /**
     * @dev Internal function to the asset decimals.
     * @param asset Address of the asset.
     * @return The asset decimals.
     */
    function _getAssetDecimals(address asset) internal view returns(uint8) {
        if (_isEther(asset)) {
            return uint8(18);
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x313ce567));
            require(success, "ACOAssetHelper::_getAssetDecimals");
            return abi.decode(returndata, (uint8));
        }
    }

    /**
     * @dev Internal function to the asset name.
     * @param asset Address of the asset.
     * @return The asset name.
     */
    function _getAssetName(address asset) internal view returns(string memory) {
        if (_isEther(asset)) {
            return "Ethereum";
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x06fdde03));
            require(success, "ACOAssetHelper::_getAssetName");
            return abi.decode(returndata, (string));
        }
    }
    
    /**
     * @dev Internal function to the asset balance of an account.
     * @param asset Address of the asset.
     * @param account Address of the account.
     * @return The account balance.
     */
    function _getAssetBalanceOf(address asset, address account) internal view returns(uint256) {
        if (_isEther(asset)) {
            return account.balance;
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x70a08231, account));
            require(success, "ACOAssetHelper::_getAssetBalanceOf");
            return abi.decode(returndata, (uint256));
        }
    }
    
    /**
     * @dev Internal function to the asset allowance between two addresses.
     * @param asset Address of the asset.
     * @param owner Address of the owner of the tokens.
     * @param spender Address of the spender authorized.
     * @return The owner allowance for the spender.
     */
    function _getAssetAllowance(address asset, address owner, address spender) internal view returns(uint256) {
        if (_isEther(asset)) {
            return 0;
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0xdd62ed3e, owner, spender));
            require(success, "ACOAssetHelper::_getAssetAllowance");
            return abi.decode(returndata, (uint256));
        }
    }

    /**
     * @dev Internal function to transfer an asset. 
     * @param asset Address of the asset to be transferred.
     * @param to Address of the destination.
     * @param amount The amount to be transferred.
     */
    function _transferAsset(address asset, address to, uint256 amount) internal {
        if (_isEther(asset)) {
            (bool success,) = to.call{value:amount}(new bytes(0));
            require(success, 'ACOAssetHelper::_transferAsset');
        } else {
            _callTransferERC20(asset, to, amount);
        }
    }
    
	/**
     * @dev Internal function to receive an asset. 
     * @param asset Address of the asset to be received.
     * @param amount The amount to be received.
     */
    function _receiveAsset(address asset, uint256 amount) internal {
        if (_isEther(asset)) {
            require(msg.value == amount, "ACOAssetHelper:: Invalid ETH amount");
        } else {
            require(msg.value == 0, "ACOAssetHelper:: Ether is not expected");
            _callTransferFromERC20(asset, msg.sender, address(this), amount);
        }
    }
}"},"ACONameFormatter.sol":{"content":"pragma solidity ^0.6.6;

import './BokkyPooBahsDateTimeLibrary.sol';
import './Strings.sol';

library ACONameFormatter {
    
    /**
     * @dev Function to get the `value` formatted.
	 * The function returns a string for the `value` with a point (character '.') in the proper position considering the `decimals`.
	 * Beyond that, the string returned presents only representative digits.
	 * For example, a `value` with 18 decimals:
	 *  - For 100000000000000000000 the return is "100"
	 *  - For 100100000000000000000 the return is "100.1"
	 *  - For 100000000000000000 the return is "0.1"
	 *  - For 100000000000000 the return is "0.0001"
	 *  - For 100000000000000000001 the return is "100.000000000000000001"
	 * @param value The number to be formatted.
	 * @param decimals The respective number decimals.
     * @return The value formatted on a string.
     */
    function formatNumber(uint256 value, uint8 decimals) internal pure returns(string memory) {
        uint256 digits;
        uint256 count;
        bool foundRepresentativeDigit = false;
        uint256 addPointAt = 0;
        uint256 temp = value;
        uint256 number = value;
        while (temp != 0) {
            if (!foundRepresentativeDigit && (temp % 10 != 0 || count == uint256(decimals))) {
                foundRepresentativeDigit = true;
                number = temp;
            }
            if (foundRepresentativeDigit) {
                if (count == uint256(decimals)) {
                    addPointAt = digits;
                }
                digits++;
            }
            temp /= 10;
            count++;
        }
        if (count <= uint256(decimals)) {
            digits = digits + 2 + uint256(decimals) - count;
            addPointAt = digits - 2;
        } else if (addPointAt > 0) {
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = number;
        for (uint256 i = 0; i < digits; ++i) {
            if (i > 0 && i == addPointAt) {
                buffer[index--] = byte(".");
            } else if (number == 0) {
                buffer[index--] = byte("0");
            } else {
                buffer[index--] = byte(uint8(48 + number % 10));
                number /= 10;
            }
        }
        return string(buffer);
    }
    
    /**
     * @dev Function to get the `unixTime` formatted.
     * @param unixTime The UNIX time to be formatted.
     * @return The unix time formatted on a string.
     */
    function formatTime(uint256 unixTime) internal pure returns(string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute,) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(unixTime); 
        return string(abi.encodePacked(
            _getDateNumberWithTwoCharacters(day),
            _getMonthFormatted(month),
            _getYearFormatted(year),
            "-",
            _getDateNumberWithTwoCharacters(hour),
            _getDateNumberWithTwoCharacters(minute),
            "UTC"
            )); 
    }
    
    /**
     * @dev Function to get the token type description.
     * @return The token type description.
     */
    function formatType(bool isCall) internal pure returns(string memory) {
        if (isCall) {
            return "C";
        } else {
            return "P";
        }
    }
    
    /**
     * @dev Function to get the year formatted with 2 characters.
     * @return The year formatted.
     */
    function _getYearFormatted(uint256 year) private pure returns(string memory) {
        bytes memory yearBytes = bytes(Strings.toString(year));
        bytes memory result = new bytes(2);
        uint256 startIndex = yearBytes.length - 2;
        for (uint256 i = startIndex; i < yearBytes.length; i++) {
            result[i - startIndex] = yearBytes[i];
        }
        return string(result);
    }
    
    /**
     * @dev Function to get the month abbreviation.
     * @return The month abbreviation.
     */
    function _getMonthFormatted(uint256 month) private pure returns(string memory) {
        if (month == 1) {
            return "JAN";
        } else if (month == 2) {
            return "FEB";
        } else if (month == 3) {
            return "MAR";
        } else if (month == 4) {
            return "APR";
        } else if (month == 5) {
            return "MAY";
        } else if (month == 6) {
            return "JUN";
        } else if (month == 7) {
            return "JUL";
        } else if (month == 8) {
            return "AUG";
        } else if (month == 9) {
            return "SEP";
        } else if (month == 10) {
            return "OCT";
        } else if (month == 11) {
            return "NOV";
        } else if (month == 12) {
            return "DEC";
        } else {
            return "INVALID";
        }
    }
    
    /**
     * @dev Function to get the date number with 2 characters.
     * @return The 2 characters for the number.
     */
    function _getDateNumberWithTwoCharacters(uint256 number) private pure returns(string memory) {
        string memory _string = Strings.toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", _string));
        } else {
            return _string;
        }
    }
}"},"ACOPool.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './SafeMath.sol';
import './Address.sol';
import './ACONameFormatter.sol';
import './ACOAssetHelper.sol';
import './ERC20.sol';
import './IACOPool.sol';
import './IACOFactory.sol';
import './IACOStrategy.sol';
import './IACOToken.sol';
import './IACOFlashExercise.sol';
import './IUniswapV2Router02.sol';
import './IChiToken.sol';

/**
 * @title ACOPool
 * @dev A pool contract to trade ACO tokens.
 */
contract ACOPool is Ownable, ERC20, IACOPool {
    using Address for address;
    using SafeMath for uint256;
    
    uint256 internal constant POOL_PRECISION = 1000000000000000000; // 18 decimals
    uint256 internal constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
	/**
     * @dev Struct to store an ACO token trade data.
     */
    struct ACOTokenData {
		/**
         * @dev Amount of tokens sold by the pool.
         */
        uint256 amountSold;
		
		/**
         * @dev Amount of tokens purchased by the pool.
         */
        uint256 amountPurchased;
		
		/**
         * @dev Index of the ACO token on the stored array.
         */
        uint256 index;
    }
    
	/**
     * @dev Emitted when the strategy address has been changed.
     * @param oldStrategy Address of the previous strategy.
     * @param newStrategy Address of the new strategy.
     */
    event SetStrategy(address indexed oldStrategy, address indexed newStrategy);
	
	/**
     * @dev Emitted when the base volatility has been changed.
     * @param oldBaseVolatility Value of the previous base volatility.
     * @param newBaseVolatility Value of the new base volatility.
     */
    event SetBaseVolatility(uint256 indexed oldBaseVolatility, uint256 indexed newBaseVolatility);
	
	/**
     * @dev Emitted when a collateral has been deposited on the pool.
     * @param account Address of the account.
     * @param amount Amount deposited.
     */
    event CollateralDeposited(address indexed account, uint256 amount);
	
	/**
     * @dev Emitted when the collateral and premium have been redeemed on the pool.
     * @param account Address of the account.
     * @param underlyingAmount Amount of underlying asset redeemed.
     * @param strikeAssetAmount Amount of strike asset redeemed.
     */
    event Redeem(address indexed account, uint256 underlyingAmount, uint256 strikeAssetAmount);
	
	/**
     * @dev Emitted when the collateral has been restored on the pool.
     * @param amountOut Amount of the premium sold.
     * @param collateralIn Amount of collateral restored.
     */
    event RestoreCollateral(uint256 amountOut, uint256 collateralIn);
	
	/**
     * @dev Emitted when an ACO token has been redeemed.
     * @param acoToken Address of the ACO token.
     * @param collateralIn Amount of collateral redeemed.
     * @param amountSold Total amount of ACO token sold by the pool.
     * @param amountPurchased Total amount of ACO token purchased by the pool.
     */
    event ACORedeem(address indexed acoToken, uint256 collateralIn, uint256 amountSold, uint256 amountPurchased);
	
	/**
     * @dev Emitted when an ACO token has been exercised.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens exercised.
     * @param collateralIn Amount of collateral received.
     */
    event ACOExercise(address indexed acoToken, uint256 tokenAmount, uint256 collateralIn);
	
	/**
     * @dev Emitted when an ACO token has been bought or sold by the pool.
     * @param isPoolSelling True whether the pool is selling an ACO token, otherwise the pool is buying.
     * @param account Address of the account that is doing the swap.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens swapped.
     * @param price Value of the premium paid in strike asset.
     * @param protocolFee Value of the protocol fee paid in strike asset.
     * @param underlyingPrice The underlying price in strike asset.
     */
    event Swap(
        bool indexed isPoolSelling, 
        address indexed account, 
        address indexed acoToken, 
        uint256 tokenAmount, 
        uint256 price, 
        uint256 protocolFee,
        uint256 underlyingPrice
    );
    
	/**
	 * @dev UNIX timestamp that the pool can start to trade ACO tokens.
	 */
    uint256 public poolStart;
	
	/**
	 * @dev The protocol fee percentage. (100000 = 100%)
	 */
    uint256 public fee;
	
	/**
	 * @dev Address of the ACO flash exercise contract.
	 */
    IACOFlashExercise public acoFlashExercise;
	
	/**
	 * @dev Address of the ACO factory contract.
	 */
    IACOFactory public acoFactory;
	
	/**
	 * @dev Address of the Uniswap V2 router.
	 */
    IUniswapV2Router02 public uniswapRouter;
	
	/**
	 * @dev Address of the Chi gas token.
	 */
    IChiToken public chiToken;
	
	/**
	 * @dev Address of the protocol fee destination.
	 */
    address public feeDestination;
    
	/**
	 * @dev Address of the underlying asset accepts by the pool.
	 */
    address public underlying;
	
	/**
	 * @dev Address of the strike asset accepts by the pool.
	 */
    address public strikeAsset;
	
	/**
	 * @dev Value of the minimum strike price on ACO token that the pool accept to trade.
	 */
    uint256 public minStrikePrice;
	
	/**
	 * @dev Value of the maximum strike price on ACO token that the pool accept to trade.
	 */
    uint256 public maxStrikePrice;
	
	/**
	 * @dev Value of the minimum UNIX expiration on ACO token that the pool accept to trade.
	 */
    uint256 public minExpiration;
	
	/**
	 * @dev Value of the maximum UNIX expiration on ACO token that the pool accept to trade.
	 */
    uint256 public maxExpiration;
	
	/**
	 * @dev True whether the pool accepts CALL options, otherwise the pool accepts only PUT options. 
	 */
    bool public isCall;
	
	/**
	 * @dev True whether the pool can also buy ACO tokens, otherwise the pool only sells ACO tokens. 
	 */
    bool public canBuy;
    
	/**
	 * @dev Address of the strategy. 
	 */
    IACOStrategy public strategy;
	
	/**
	 * @dev Percentage value for the base volatility. (100000 = 100%) 
	 */
    uint256 public baseVolatility;
    
	/**
	 * @dev Total amount of collateral deposited.  
	 */
    uint256 public collateralDeposited;
	
	/**
	 * @dev Total amount in strike asset spent buying ACO tokens.  
	 */
    uint256 public strikeAssetSpentBuying;
	
	/**
	 * @dev Total amount in strike asset earned selling ACO tokens.  
	 */
    uint256 public strikeAssetEarnedSelling;
    
	/**
	 * @dev Array of ACO tokens currently negotiated.  
	 */
    address[] public acoTokens;
	
	/**
	 * @dev Mapping for ACO tokens data currently negotiated.  
	 */
    mapping(address => ACOTokenData) public acoTokensData;
    
	/**
	 * @dev Underlying asset precision. (18 decimals = 1000000000000000000)
	 */
    uint256 internal underlyingPrecision;
	
	/**
	 * @dev Strike asset precision. (6 decimals = 1000000)
	 */
    uint256 internal strikeAssetPrecision;
    
	/**
     * @dev Modifier to check if the pool is open to trade.
     */
    modifier open() {
        require(isStarted() && notFinished(), "ACOPool:: Pool is not open");
        _;
    }
    
	/**
     * @dev Modifier to apply the Chi gas token and save gas.
     */
    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
	
    /**
     * @dev Function to initialize the contract.
     * It should be called by the ACO pool factory when creating the pool.
     * It must be called only once. The first `require` is to guarantee that behavior.
     * @param initData The initialize data.
     */
    function init(InitData calldata initData) external override {
        require(underlying == address(0) && strikeAsset == address(0) && minExpiration == 0, "ACOPool::init: Already initialized");
        
        require(initData.acoFactory.isContract(), "ACOPool:: Invalid ACO Factory");
        require(initData.acoFlashExercise.isContract(), "ACOPool:: Invalid ACO flash exercise");
        require(initData.chiToken.isContract(), "ACOPool:: Invalid Chi Token");
        require(initData.fee <= 12500, "ACOPool:: The maximum fee allowed is 12.5%");
        require(initData.poolStart > block.timestamp, "ACOPool:: Invalid pool start");
        require(initData.minExpiration > block.timestamp, "ACOPool:: Invalid expiration");
        require(initData.minStrikePrice <= initData.maxStrikePrice, "ACOPool:: Invalid strike price range");
        require(initData.minStrikePrice > 0, "ACOPool:: Invalid strike price");
        require(initData.minExpiration <= initData.maxExpiration, "ACOPool:: Invalid expiration range");
        require(initData.underlying != initData.strikeAsset, "ACOPool:: Same assets");
        require(ACOAssetHelper._isEther(initData.underlying) || initData.underlying.isContract(), "ACOPool:: Invalid underlying");
        require(ACOAssetHelper._isEther(initData.strikeAsset) || initData.strikeAsset.isContract(), "ACOPool:: Invalid strike asset");
        
        super.init();
        
        poolStart = initData.poolStart;
        acoFlashExercise = IACOFlashExercise(initData.acoFlashExercise);
        acoFactory = IACOFactory(initData.acoFactory);
        chiToken = IChiToken(initData.chiToken);
        fee = initData.fee;
        feeDestination = initData.feeDestination;
        underlying = initData.underlying;
        strikeAsset = initData.strikeAsset;
        minStrikePrice = initData.minStrikePrice;
        maxStrikePrice = initData.maxStrikePrice;
        minExpiration = initData.minExpiration;
        maxExpiration = initData.maxExpiration;
        isCall = initData.isCall;
        canBuy = initData.canBuy;
        
        address _uniswapRouter = IACOFlashExercise(initData.acoFlashExercise).uniswapRouter();
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        
        _setStrategy(initData.strategy);
        _setBaseVolatility(initData.baseVolatility);
        
        _setAssetsPrecision(initData.underlying, initData.strikeAsset);
        
        _approveAssetsOnRouter(initData.isCall, initData.canBuy, _uniswapRouter, initData.underlying, initData.strikeAsset);
    }

    receive() external payable {
    }
    
    /**
     * @dev Function to get the token name.
     */
    function name() public view override returns(string memory) {
        return _name();
    }
    
    /**
     * @dev Function to get the token symbol, that it is equal to the name.
     */
    function symbol() public view override returns(string memory) {
        return _name();
    }
    
	/**
     * @dev Function to get the token decimals.
     */
    function decimals() public view override returns(uint8) {
        return 18;
    }
    
	/**
     * @dev Function to get whether the pool already started trade ACO tokens.
     */
    function isStarted() public view returns(bool) {
        return block.timestamp >= poolStart;
    }
    
	/**
     * @dev Function to get whether the pool is not finished.
     */
    function notFinished() public view returns(bool) {
        return block.timestamp < maxExpiration;
    }
    
	/**
     * @dev Function to get the number of ACO tokens currently negotiated.
     */
    function numberOfACOTokensCurrentlyNegotiated() public override view returns(uint256) {
        return acoTokens.length;
    }
    
	/**
     * @dev Function to get the pool collateral asset.
     */
    function collateral() public override view returns(address) {
        if (isCall) {
            return underlying;
        } else {
            return strikeAsset;
        }
    }
    
    /**
     * @dev Function to quote an ACO token swap.
     * @param isBuying True whether it is quoting to buy an ACO token, otherwise it is quoting to sell an ACO token.
     * @param acoToken Address of the ACO token.
     * @param tokenAmount Amount of ACO tokens to swap.
     * @return The swap price, the protocol fee charged on the swap, and the underlying price in strike asset.
     */
    function quote(bool isBuying, address acoToken, uint256 tokenAmount) open public override view returns(uint256, uint256, uint256) {
        (uint256 swapPrice, uint256 protocolFee, uint256 underlyingPrice,) = _internalQuote(isBuying, acoToken, tokenAmount);
        return (swapPrice, protocolFee, underlyingPrice);
    }
    
    /**
     * @dev Function to set the pool strategy address.
     * Only can be called by the ACO pool factory contract.
     * @param newStrategy Address of the new strategy.
     */
    function setStrategy(address newStrategy) onlyOwner external override {
        _setStrategy(newStrategy);
    }
    
    /**
     * @dev Function to set the pool base volatility percentage. (100000 = 100%)
     * Only can be called by the ACO pool factory contract.
     * @param newBaseVolatility Value of the new base volatility.
     */
    function setBaseVolatility(uint256 newBaseVolatility) onlyOwner external override {
        _setBaseVolatility(newBaseVolatility);
    }
    
    /**
     * @dev Function to deposit on the pool.
     * Only can be called when the pool is not started.
     * @param collateralAmount Amount of collateral to be deposited.
     * @param to Address of the destination of the pool token.
     * @return The amount of pool tokens minted.
     */
    function deposit(uint256 collateralAmount, address to) public override payable returns(uint256) {
        require(!isStarted(), "ACOPool:: Pool already started");
        require(collateralAmount > 0, "ACOPool:: Invalid collateral amount");
        require(to != address(0) && to != address(this), "ACOPool:: Invalid to");
        
        (uint256 normalizedAmount, uint256 amount) = _getNormalizedDepositAmount(collateralAmount);
        
        ACOAssetHelper._receiveAsset(collateral(), amount);
        
        collateralDeposited = collateralDeposited.add(amount);
        _mintAction(to, normalizedAmount);
        
        emit CollateralDeposited(msg.sender, amount);
        
        return normalizedAmount;
    }
    
    /**
     * @dev Function to swap an ACO token with the pool.
     * Only can be called when the pool is opened.
     * @param isBuying True whether it is quoting to buy an ACO token, otherwise it is quoting to sell an ACO token.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction Value of the swap restriction. The minimum premium to receive on a selling or the maximum value to pay on a purchase.
     * @param to Address of the destination. ACO tokens when is buying or strike asset on a selling.
     * @param deadline UNIX deadline for the swap to be executed.
     * @return The amount ACO tokens received when is buying or the amount of strike asset received on a selling.
     */
    function swap(
        bool isBuying, 
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) open public override returns(uint256) {
        return _swap(isBuying, acoToken, tokenAmount, restriction, to, deadline);
    }
    
    /**
     * @dev Function to swap an ACO token with the pool and use Chi token to save gas.
     * Only can be called when the pool is opened.
     * @param isBuying True whether it is quoting to buy an ACO token, otherwise it is quoting to sell an ACO token.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction Value of the swap restriction. The minimum premium to receive on a selling or the maximum value to pay on a purchase.
     * @param to Address of the destination. ACO tokens when is buying or strike asset on a selling.
     * @param deadline UNIX deadline for the swap to be executed.
     * @return The amount ACO tokens received when is buying or the amount of strike asset received on a selling.
     */
    function swapWithGasToken(
        bool isBuying, 
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) open discountCHI public override returns(uint256) {
        return _swap(isBuying, acoToken, tokenAmount, restriction, to, deadline);
    }
    
    /**
     * @dev Function to redeem the collateral and the premium from the pool.
     * Only can be called when the pool is finished.
     * @return The amount of underlying asset received and the amount of strike asset received.
     */
    function redeem() public override returns(uint256, uint256) {
        return _redeem(msg.sender);
    }
    
    /**
     * @dev Function to redeem the collateral and the premium from the pool from an account.
     * Only can be called when the pool is finished.
     * The allowance must be respected.
     * The transaction sender will receive the redeemed assets.
     * @param account Address of the account.
     * @return The amount of underlying asset received and the amount of strike asset received.
     */
    function redeemFrom(address account) public override returns(uint256, uint256) {
        return _redeem(account);
    }
    
    /**
     * @dev Function to redeem the collateral from the ACO tokens negotiated on the pool.
     * It redeems the collateral only if the respective ACO token is expired.
     */
    function redeemACOTokens() public override {
        for (uint256 i = acoTokens.length; i > 0; --i) {
            address acoToken = acoTokens[i - 1];
			uint256 expiryTime = IACOToken(acoToken).expiryTime();
            _redeemACOToken(acoToken, expiryTime);
        }
    }
	
    /**
     * @dev Function to redeem the collateral from an ACO token.
     * It redeems the collateral only if the ACO token is expired.
     * @param acoToken Address of the ACO token.
     */
	function redeemACOToken(address acoToken) public override {
        (,uint256 expiryTime) = _getValidACOTokenStrikePriceAndExpiration(acoToken);
		_redeemACOToken(acoToken, expiryTime);
    }
    
    /**
     * @dev Function to exercise an ACO token negotiated on the pool.
     * Only ITM ACO tokens are exercisable.
     * @param acoToken Address of the ACO token.
     */
    function exerciseACOToken(address acoToken) public override {
        (uint256 strikePrice, uint256 expiryTime) = _getValidACOTokenStrikePriceAndExpiration(acoToken);
        uint256 exercisableAmount = _getExercisableAmount(acoToken);
        require(exercisableAmount > 0, "ACOPool:: Exercise is not available");
        
        address _strikeAsset = strikeAsset;
        address _underlying = underlying;
        bool _isCall = isCall;
        
        uint256 collateralAmount;
        address _collateral;
        if (_isCall) {
            _collateral = _underlying;
            collateralAmount = exercisableAmount;
        } else {
            _collateral = _strikeAsset;
            collateralAmount = IACOToken(acoToken).getCollateralAmount(exercisableAmount);
            
        }
        uint256 collateralAvailable = _getPoolBalanceOf(_collateral);
        
        ACOTokenData storage data = acoTokensData[acoToken];
        (bool canExercise, uint256 minIntrinsicValue) = strategy.checkExercise(IACOStrategy.CheckExercise(
            _underlying,
            _strikeAsset,
            _isCall,
            strikePrice, 
            expiryTime,
            collateralAmount,
            collateralAvailable,
            data.amountPurchased,
            data.amountSold
        ));
        require(canExercise, "ACOPool:: Exercise is not possible");
        
        if (IACOToken(acoToken).allowance(address(this), address(acoFlashExercise)) < exercisableAmount) {
            _setAuthorizedSpender(acoToken, address(acoFlashExercise));    
        }
        acoFlashExercise.flashExercise(acoToken, exercisableAmount, minIntrinsicValue, block.timestamp);
        
        uint256 collateralIn = _getPoolBalanceOf(_collateral).sub(collateralAvailable);
        emit ACOExercise(acoToken, exercisableAmount, collateralIn);
    }
    
    /**
     * @dev Function to restore the collateral on the pool by selling the other asset balance.
     */
    function restoreCollateral() public override {
        address _strikeAsset = strikeAsset;
        address _underlying = underlying;
        bool _isCall = isCall;
        
        uint256 underlyingBalance = _getPoolBalanceOf(_underlying);
        uint256 strikeAssetBalance = _getPoolBalanceOf(_strikeAsset);
        
        uint256 balanceOut;
        address assetIn;
        address assetOut;
        if (_isCall) {
            balanceOut = strikeAssetBalance;
            assetIn = _underlying;
            assetOut = _strikeAsset;
        } else {
            balanceOut = underlyingBalance;
            assetIn = _strikeAsset;
            assetOut = _underlying;
        }
        require(balanceOut > 0, "ACOPool:: No balance");
        
        uint256 acceptablePrice = strategy.getAcceptableUnderlyingPriceToSwapAssets(_underlying, _strikeAsset, false);
        
        uint256 minToReceive;
        if (_isCall) {
            minToReceive = balanceOut.mul(underlyingPrecision).div(acceptablePrice);
        } else {
            minToReceive = balanceOut.mul(acceptablePrice).div(underlyingPrecision);
        }
        _swapAssetsExactAmountOut(assetOut, assetIn, minToReceive, balanceOut);
        
        uint256 collateralIn;
        if (_isCall) {
            collateralIn = _getPoolBalanceOf(_underlying).sub(underlyingBalance);
        } else {
            collateralIn = _getPoolBalanceOf(_strikeAsset).sub(strikeAssetBalance);
        }
        emit RestoreCollateral(balanceOut, collateralIn);
    }
    
    /**
     * @dev Internal function to swap an ACO token with the pool.
     * @param isPoolSelling True whether the pool is selling an ACO token, otherwise the pool is buying.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @param restriction Value of the swap restriction. The minimum premium to receive on a selling or the maximum value to pay on a purchase.
     * @param to Address of the destination. ACO tokens when is buying or strike asset on a selling.
     * @param deadline UNIX deadline for the swap to be executed.
     * @return The amount ACO tokens received when is buying or the amount of strike asset received on a selling.
     */
    function _swap(
        bool isPoolSelling, 
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) internal returns(uint256) {
        require(block.timestamp <= deadline, "ACOPool:: Swap deadline");
        require(to != address(0) && to != acoToken && to != address(this), "ACOPool:: Invalid destination");
        
        (uint256 swapPrice, uint256 protocolFee, uint256 underlyingPrice, uint256 collateralAmount) = _internalQuote(isPoolSelling, acoToken, tokenAmount);
        
        uint256 amount;
        if (isPoolSelling) {
            amount = _internalSelling(to, acoToken, collateralAmount, tokenAmount, restriction, swapPrice, protocolFee);
        } else {
            amount = _internalBuying(to, acoToken, tokenAmount, restriction, swapPrice, protocolFee);
        }
        
        if (protocolFee > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, feeDestination, protocolFee);
        }
        
        emit Swap(isPoolSelling, msg.sender, acoToken, tokenAmount, swapPrice, protocolFee, underlyingPrice);
        
        return amount;
    }
    
    /**
     * @dev Internal function to quote an ACO token price.
     * @param isPoolSelling True whether the pool is selling an ACO token, otherwise the pool is buying.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @return The quote price, the protocol fee charged, the underlying price, and the collateral amount.
     */
    function _internalQuote(bool isPoolSelling, address acoToken, uint256 tokenAmount) internal view returns(uint256, uint256, uint256, uint256) {
        require(isPoolSelling || canBuy, "ACOPool:: The pool only sell");
        require(tokenAmount > 0, "ACOPool:: Invalid token amount");
        (uint256 strikePrice, uint256 expiryTime) = _getValidACOTokenStrikePriceAndExpiration(acoToken);
        require(expiryTime > block.timestamp, "ACOPool:: ACO token expired");
        
        (uint256 collateralAmount, uint256 collateralAvailable) = _getSizeData(isPoolSelling, acoToken, tokenAmount);
        (uint256 price, uint256 underlyingPrice,) = _strategyQuote(acoToken, isPoolSelling, strikePrice, expiryTime, collateralAmount, collateralAvailable);
        
        price = price.mul(tokenAmount).div(underlyingPrecision);
        
        uint256 protocolFee = 0;
        if (fee > 0) {
            protocolFee = price.mul(fee).div(100000);
            if (isPoolSelling) {
                price = price.add(protocolFee);
            } else {
                price = price.sub(protocolFee);
            }
        }
        require(price > 0, "ACOPool:: Invalid quote");
        return (price, protocolFee, underlyingPrice, collateralAmount);
    }
    
    /**
     * @dev Internal function to the size data for a quote.
     * @param isPoolSelling True whether the pool is selling an ACO token, otherwise the pool is buying.
     * @param acoToken Address of the ACO token.
	 * @param tokenAmount Amount of ACO tokens to swap.
     * @return The collateral amount and the collateral available on the pool.
     */
    function _getSizeData(bool isPoolSelling, address acoToken, uint256 tokenAmount) internal view returns(uint256, uint256) {
        uint256 collateralAmount;
        uint256 collateralAvailable;
        if (isCall) {
            collateralAvailable = _getPoolBalanceOf(underlying);
            collateralAmount = tokenAmount; 
        } else {
            collateralAvailable = _getPoolBalanceOf(strikeAsset);
            collateralAmount = IACOToken(acoToken).getCollateralAmount(tokenAmount);
            require(collateralAmount > 0, "ACOPool:: Token amount is too small");
        }
        require(!isPoolSelling || collateralAmount <= collateralAvailable, "ACOPool:: Insufficient liquidity");
        
        return (collateralAmount, collateralAvailable);
    }
    
    /**
     * @dev Internal function to quote on the strategy contract.
     * @param acoToken Address of the ACO token.
     * @param isPoolSelling True whether the pool is selling an ACO token, otherwise the pool is buying.
	 * @param strikePrice ACO token strike price.
     * @param expiryTime ACO token expiry time on UNIX.
     * @param collateralAmount Amount of collateral for the order size.
     * @param collateralAvailable Amount of collateral available on the pool.
     * @return The quote price, the underlying price and the volatility.
     */
    function _strategyQuote(
        address acoToken,
        bool isPoolSelling,
        uint256 strikePrice,
        uint256 expiryTime,
        uint256 collateralAmount,
        uint256 collateralAvailable
    ) internal view returns(uint256, uint256, uint256) {
        ACOTokenData storage data = acoTokensData[acoToken];
        return strategy.quote(IACOStrategy.OptionQuote(
            isPoolSelling, 
            underlying, 
            strikeAsset, 
            isCall, 
            strikePrice, 
            expiryTime, 
            baseVolatility, 
            collateralAmount, 
            collateralAvailable,
            collateralDeposited,
            strikeAssetEarnedSelling,
            strikeAssetSpentBuying,
            data.amountPurchased,
            data.amountSold
        ));
    }
    
    /**
     * @dev Internal function to sell ACO tokens.
     * @param to Address of the destination of the ACO tokens.
     * @param acoToken Address of the ACO token.
	 * @param collateralAmount Order collateral amount.
     * @param tokenAmount Order token amount.
     * @param maxPayment Maximum value to be paid for the ACO tokens.
     * @param swapPrice The swap price quoted.
     * @param protocolFee The protocol fee amount.
     * @return The ACO token amount sold.
     */
    function _internalSelling(
        address to,
        address acoToken, 
        uint256 collateralAmount, 
        uint256 tokenAmount,
        uint256 maxPayment,
        uint256 swapPrice,
        uint256 protocolFee
    ) internal returns(uint256) {
        require(swapPrice <= maxPayment, "ACOPool:: Swap restriction");
        
        ACOAssetHelper._callTransferFromERC20(strikeAsset, msg.sender, address(this), swapPrice);
        
        uint256 acoBalance = _getPoolBalanceOf(acoToken);

        ACOTokenData storage acoTokenData = acoTokensData[acoToken];
        uint256 _amountSold = acoTokenData.amountSold;
        if (_amountSold == 0 && acoTokenData.amountPurchased == 0) {
			acoTokenData.index = acoTokens.length;
            acoTokens.push(acoToken);    
        }
        if (tokenAmount > acoBalance) {
            tokenAmount = acoBalance;
            if (acoBalance > 0) {
                collateralAmount = IACOToken(acoToken).getCollateralAmount(tokenAmount.sub(acoBalance));
            }
            if (collateralAmount > 0) {
                address _collateral = collateral();
                if (ACOAssetHelper._isEther(_collateral)) {
                    tokenAmount = tokenAmount.add(IACOToken(acoToken).mintPayable{value: collateralAmount}());
                } else {
                    if (_amountSold == 0) {
                        _setAuthorizedSpender(_collateral, acoToken);    
                    }
                    tokenAmount = tokenAmount.add(IACOToken(acoToken).mint(collateralAmount));
                }
            }
        }
        
        acoTokenData.amountSold = tokenAmount.add(_amountSold);
        strikeAssetEarnedSelling = swapPrice.sub(protocolFee).add(strikeAssetEarnedSelling); 
        
        ACOAssetHelper._callTransferERC20(acoToken, to, tokenAmount);
        
        return tokenAmount;
    }
	
    /**
     * @dev Internal function to buy ACO tokens.
     * @param to Address of the destination of the premium.
     * @param acoToken Address of the ACO token.
     * @param tokenAmount Order token amount.
     * @param minToReceive Minimum value to be received for the ACO tokens.
     * @param swapPrice The swap price quoted.
     * @param protocolFee The protocol fee amount.
     * @return The premium amount transferred.
     */
    function _internalBuying(
        address to,
        address acoToken, 
        uint256 tokenAmount, 
        uint256 minToReceive,
        uint256 swapPrice,
        uint256 protocolFee
    ) internal returns(uint256) {
        require(swapPrice >= minToReceive, "ACOPool:: Swap restriction");
        
        uint256 requiredStrikeAsset = swapPrice.add(protocolFee);
        if (isCall) {
            _getStrikeAssetAmount(requiredStrikeAsset);
        }
        
        ACOAssetHelper._callTransferFromERC20(acoToken, msg.sender, address(this), tokenAmount);
        
        ACOTokenData storage acoTokenData = acoTokensData[acoToken];
        uint256 _amountPurchased = acoTokenData.amountPurchased;
        if (_amountPurchased == 0 && acoTokenData.amountSold == 0) {
			acoTokenData.index = acoTokens.length;
            acoTokens.push(acoToken);    
        }
        acoTokenData.amountPurchased = tokenAmount.add(_amountPurchased);
        strikeAssetSpentBuying = requiredStrikeAsset.add(strikeAssetSpentBuying);
        
        ACOAssetHelper._transferAsset(strikeAsset, to, swapPrice);
        
        return swapPrice;
    }
    
    /**
     * @dev Internal function to get the normalized deposit amount.
	 * The pool token has always with 18 decimals.
     * @param collateralAmount Amount of collateral to be deposited.
     * @return The normalized token amount and the collateral amount.
     */
    function _getNormalizedDepositAmount(uint256 collateralAmount) internal view returns(uint256, uint256) {
        uint256 basePrecision = isCall ? underlyingPrecision : strikeAssetPrecision;
        uint256 normalizedAmount;
        if (basePrecision > POOL_PRECISION) {
            uint256 adjust = basePrecision.div(POOL_PRECISION);
            normalizedAmount = collateralAmount.div(adjust);
            collateralAmount = normalizedAmount.mul(adjust);
        } else if (basePrecision < POOL_PRECISION) {
            normalizedAmount = collateralAmount.mul(POOL_PRECISION.div(basePrecision));
        } else {
            normalizedAmount = collateralAmount;
        }
        require(normalizedAmount > 0, "ACOPool:: Invalid collateral amount");
        return (normalizedAmount, collateralAmount);
    }
    
    /**
     * @dev Internal function to get an amount of strike asset for the pool.
	 * The pool swaps the collateral for it if necessary.
     * @param strikeAssetAmount Amount of strike asset required.
     */
    function _getStrikeAssetAmount(uint256 strikeAssetAmount) internal {
        address _strikeAsset = strikeAsset;
        uint256 balance = _getPoolBalanceOf(_strikeAsset);
        if (balance < strikeAssetAmount) {
            uint256 amountToPurchase = strikeAssetAmount.sub(balance);
            address _underlying = underlying;
            uint256 acceptablePrice = strategy.getAcceptableUnderlyingPriceToSwapAssets(_underlying, _strikeAsset, true);
            uint256 maxPayment = amountToPurchase.mul(underlyingPrecision).div(acceptablePrice);
            _swapAssetsExactAmountIn(_underlying, _strikeAsset, amountToPurchase, maxPayment);
        }
    }
	
    /**
     * @dev Internal function to redeem the collateral from an ACO token.
     * It redeems the collateral only if the ACO token is expired.
     * @param acoToken Address of the ACO token.
	 * @param expiryTime ACO token expiry time in UNIX.
     */
	function _redeemACOToken(address acoToken, uint256 expiryTime) internal {
		if (expiryTime <= block.timestamp) {

            uint256 collateralIn = 0;
            if (IACOToken(acoToken).currentCollateralizedTokens(address(this)) > 0) {	
			    collateralIn = IACOToken(acoToken).redeem();
            }
			
			ACOTokenData storage data = acoTokensData[acoToken];
			uint256 lastIndex = acoTokens.length - 1;
			if (lastIndex != data.index) {
				address last = acoTokens[lastIndex];
				acoTokensData[last].index = data.index;
				acoTokens[data.index] = last;
			}
			
			emit ACORedeem(acoToken, collateralIn, data.amountSold, data.amountPurchased);
			
			acoTokens.pop();
			delete acoTokensData[acoToken];
		}
    }
    
    /**
     * @dev Internal function to redeem the collateral and the premium from the pool from an account.
     * @param account Address of the account.
     * @return The amount of underlying asset received and the amount of strike asset received.
     */
    function _redeem(address account) internal returns(uint256, uint256) {
        uint256 share = balanceOf(account);
        require(share > 0, "ACOPool:: Account with no share");
        require(!notFinished(), "ACOPool:: Pool is not finished");
        
        redeemACOTokens();
        
        uint256 _totalSupply = totalSupply();
        uint256 underlyingBalance = share.mul(_getPoolBalanceOf(underlying)).div(_totalSupply);
        uint256 strikeAssetBalance = share.mul(_getPoolBalanceOf(strikeAsset)).div(_totalSupply);
        
        _callBurn(account, share);
        
        if (underlyingBalance > 0) {
            ACOAssetHelper._transferAsset(underlying, msg.sender, underlyingBalance);
        }
        if (strikeAssetBalance > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, msg.sender, strikeAssetBalance);
        }
        
        emit Redeem(msg.sender, underlyingBalance, strikeAssetBalance);
        
        return (underlyingBalance, strikeAssetBalance);
    }
    
    /**
     * @dev Internal function to burn pool tokens.
     * @param account Address of the account.
     * @param tokenAmount Amount of pool tokens to be burned.
     */
    function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }
    
    /**
     * @dev Internal function to swap assets on the Uniswap V2 with an exact amount of an asset to be sold.
     * @param assetOut Address of the asset to be sold.
	 * @param assetIn Address of the asset to be purchased.
     * @param minAmountIn Minimum amount to be received.
     * @param amountOut The exact amount to be sold.
     */
    function _swapAssetsExactAmountOut(address assetOut, address assetIn, uint256 minAmountIn, uint256 amountOut) internal {
        address[] memory path = new address[](2);
        if (ACOAssetHelper._isEther(assetOut)) {
            path[0] = acoFlashExercise.weth();
            path[1] = assetIn;
            uniswapRouter.swapExactETHForTokens{value: amountOut}(minAmountIn, path, address(this), block.timestamp);
        } else if (ACOAssetHelper._isEther(assetIn)) {
            path[0] = assetOut;
            path[1] = acoFlashExercise.weth();
            uniswapRouter.swapExactTokensForETH(amountOut, minAmountIn, path, address(this), block.timestamp);
        } else {
            path[0] = assetOut;
            path[1] = assetIn;
            uniswapRouter.swapExactTokensForTokens(amountOut, minAmountIn, path, address(this), block.timestamp);
        }
    }
    
    /**
     * @dev Internal function to swap assets on the Uniswap V2 with an exact amount of an asset to be purchased.
     * @param assetOut Address of the asset to be sold.
	 * @param assetIn Address of the asset to be purchased.
     * @param amountIn The exact amount to be purchased.
     * @param maxAmountOut Maximum amount to be paid.
     */
    function _swapAssetsExactAmountIn(address assetOut, address assetIn, uint256 amountIn, uint256 maxAmountOut) internal {
        address[] memory path = new address[](2);
        if (ACOAssetHelper._isEther(assetOut)) {
            path[0] = acoFlashExercise.weth();
            path[1] = assetIn;
            uniswapRouter.swapETHForExactTokens{value: maxAmountOut}(amountIn, path, address(this), block.timestamp);
        } else if (ACOAssetHelper._isEther(assetIn)) {
            path[0] = assetOut;
            path[1] = acoFlashExercise.weth();
            uniswapRouter.swapTokensForExactETH(amountIn, maxAmountOut, path, address(this), block.timestamp);
        } else {
            path[0] = assetOut;
            path[1] = assetIn;
            uniswapRouter.swapTokensForExactTokens(amountIn, maxAmountOut, path, address(this), block.timestamp);
        }
    }
    
    /**
     * @dev Internal function to set the strategy address.
     * @param newStrategy Address of the new strategy.
     */
    function _setStrategy(address newStrategy) internal {
        require(newStrategy.isContract(), "ACOPool:: Invalid strategy");
        emit SetStrategy(address(strategy), newStrategy);
        strategy = IACOStrategy(newStrategy);
    }
    
    /**
     * @dev Internal function to set the base volatility percentage. (100000 = 100%)
     * @param newBaseVolatility Value of the new base volatility.
     */
    function _setBaseVolatility(uint256 newBaseVolatility) internal {
        require(newBaseVolatility > 0, "ACOPool:: Invalid base volatility");
        emit SetBaseVolatility(baseVolatility, newBaseVolatility);
        baseVolatility = newBaseVolatility;
    }
    
    /**
     * @dev Internal function to set the pool assets precisions.
     * @param _underlying Address of the underlying asset.
     * @param _strikeAsset Address of the strike asset.
     */
    function _setAssetsPrecision(address _underlying, address _strikeAsset) internal {
        underlyingPrecision = 10 ** uint256(ACOAssetHelper._getAssetDecimals(_underlying));
        strikeAssetPrecision = 10 ** uint256(ACOAssetHelper._getAssetDecimals(_strikeAsset));
    }
    
    /**
     * @dev Internal function to infinite authorize the pool assets on the Uniswap V2 router.
     * @param _isCall True whether it is a CALL option, otherwise it is PUT.
     * @param _canBuy True whether the pool can also buy ACO tokens, otherwise it only sells.
     * @param _uniswapRouter Address of the Uniswap V2 router.
     * @param _underlying Address of the underlying asset.
     * @param _strikeAsset Address of the strike asset.
     */
    function _approveAssetsOnRouter(
        bool _isCall, 
        bool _canBuy, 
        address _uniswapRouter,
        address _underlying,
        address _strikeAsset
    ) internal {
        if (_isCall) {
            if (!ACOAssetHelper._isEther(_strikeAsset)) {
                _setAuthorizedSpender(_strikeAsset, _uniswapRouter);
            }
            if (_canBuy && !ACOAssetHelper._isEther(_underlying)) {
                _setAuthorizedSpender(_underlying, _uniswapRouter);
            }
        } else if (!ACOAssetHelper._isEther(_underlying)) {
            _setAuthorizedSpender(_underlying, _uniswapRouter);
        }
    }
    
    /**
     * @dev Internal function to infinite authorize a spender on an asset.
     * @param asset Address of the asset.
     * @param spender Address of the spender to be authorized.
     */
    function _setAuthorizedSpender(address asset, address spender) internal {
        ACOAssetHelper._callApproveERC20(asset, spender, MAX_UINT);
    }
    
    /**
     * @dev Internal function to get the pool balance of an asset.
     * @param asset Address of the asset.
     * @return The pool balance.
     */
    function _getPoolBalanceOf(address asset) internal view returns(uint256) {
        return ACOAssetHelper._getAssetBalanceOf(asset, address(this));
    }
    
    /**
     * @dev Internal function to get the exercible amount of an ACO token.
     * @param acoToken Address of the ACO token.
     * @return The exercisable amount.
     */
    function _getExercisableAmount(address acoToken) internal view returns(uint256) {
        uint256 balance = _getPoolBalanceOf(acoToken);
        if (balance > 0) {
            uint256 collaterized = IACOToken(acoToken).currentCollateralizedTokens(address(this));
            if (balance > collaterized) {
                return balance.sub(collaterized);
            }
        }
        return 0;
    }
    
    /**
     * @dev Internal function to get an accepted ACO token by the pool.
     * @param acoToken Address of the ACO token.
     * @return The ACO token strike price, and the ACO token expiration.
     */
    function _getValidACOTokenStrikePriceAndExpiration(address acoToken) internal view returns(uint256, uint256) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime) = acoFactory.acoTokenData(acoToken);
        require(
            _underlying == underlying && 
            _strikeAsset == strikeAsset && 
            _isCall == isCall && 
            _strikePrice >= minStrikePrice &&
            _strikePrice <= maxStrikePrice &&
            _expiryTime >= minExpiration &&
            _expiryTime <= maxExpiration,
            "ACOPool:: Invalid ACO Token"
        );
        return (_strikePrice, _expiryTime);
    }
    
    /**
     * @dev Internal function to get the token name.
     * The token name is assembled  with the token data:
     * ACO POOL UNDERLYING_SYMBOL-STRIKE_ASSET_SYMBOL-TYPE-{ONLY_SELL}-MIN_STRIKE_PRICE-MAX_STRIKE_PRICE-MIN_EXPIRATION-MAX_EXPIRATION
     * @return The token name.
     */
    function _name() internal view returns(string memory) {
        uint8 strikeDecimals = ACOAssetHelper._getAssetDecimals(strikeAsset);
        string memory strikePriceFormatted;
        if (minStrikePrice != maxStrikePrice) {
            strikePriceFormatted = string(abi.encodePacked(ACONameFormatter.formatNumber(minStrikePrice, strikeDecimals), "-", ACONameFormatter.formatNumber(maxStrikePrice, strikeDecimals)));
        } else {
            strikePriceFormatted = ACONameFormatter.formatNumber(minStrikePrice, strikeDecimals);
        }
        string memory dateFormatted;
        if (minExpiration != maxExpiration) {
            dateFormatted = string(abi.encodePacked(ACONameFormatter.formatTime(minExpiration), "-", ACONameFormatter.formatTime(maxExpiration)));
        } else {
            dateFormatted = ACONameFormatter.formatTime(minExpiration);
        }
        return string(abi.encodePacked(
            "ACO POOL ",
            ACOAssetHelper._getAssetSymbol(underlying),
            "-",
            ACOAssetHelper._getAssetSymbol(strikeAsset),
            "-",
            ACONameFormatter.formatType(isCall),
            (canBuy ? "" : "-SELL"),
            "-",
            strikePriceFormatted,
            "-",
            dateFormatted
        ));
    }
}"},"Address.sol":{"content":"pragma solidity ^0.6.6;

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}
"},"BokkyPooBahsDateTimeLibrary.sol":{"content":"pragma solidity ^0.6.6;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}
"},"ERC20.sol":{"content":"pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./IERC20.sol";

/**
 * @title ERC20
 * @dev Base implementation of ERC20 token.
 */
abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    function name() public view virtual returns(string memory);
    function symbol() public view virtual returns(string memory);
    function decimals() public view virtual returns(uint8);

    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        _approveAction(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        _transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(amount));
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(amount));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        _transferAction(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _approveAction(owner, spender, amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _approveAction(account, msg.sender, _allowances[account][msg.sender].sub(amount));
        _burnAction(account, amount);
    }

    function _transferAction(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20::_transferAction: Invalid sender");
        require(recipient != address(0), "ERC20::_transferAction: Invalid recipient");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approveAction(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20::_approveAction: Invalid owner");
        require(spender != address(0), "ERC20::_approveAction: Invalid spender");

        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }
    
    function _mintAction(address account, uint256 amount) internal {
        require(account != address(0), "ERC20::_mintAction: Invalid account");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        
        emit Transfer(address(0), account, amount);
    }

    function _burnAction(address account, uint256 amount) internal {
        require(account != address(0), "ERC20::_burnAction: Invalid account");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        
        emit Transfer(account, address(0), amount);
    }
}    
"},"IACOFactory.sol":{"content":"pragma solidity ^0.6.6;

interface IACOFactory {
	function init(address _factoryAdmin, address _acoTokenImplementation, uint256 _acoFee, address _acoFeeDestination) external;
    function acoFee() external view returns(uint256);
    function factoryAdmin() external view returns(address);
    function acoTokenImplementation() external view returns(address);
    function acoFeeDestination() external view returns(address);
    function acoTokenData(address acoToken) external view returns(address, address, bool, uint256, uint256);
    function createAcoToken(address underlying, address strikeAsset, bool isCall, uint256 strikePrice, uint256 expiryTime, uint256 maxExercisedAccounts) external returns(address);
    function setFactoryAdmin(address newFactoryAdmin) external;
    function setAcoTokenImplementation(address newAcoTokenImplementation) external;
    function setAcoFee(uint256 newAcoFee) external;
    function setAcoFeeDestination(address newAcoFeeDestination) external;
}"},"IACOFlashExercise.sol":{"content":"pragma solidity ^0.6.6;

interface IACOFlashExercise {
    function uniswapFactory() external view returns(address);
    function uniswapRouter() external view returns(address);
    function weth() external view returns(address);
    function getUniswapPair(address acoToken) external view returns(address);
    function getExerciseData(address acoToken, uint256 tokenAmount, address[] calldata accounts) external view returns(uint256, uint256);
    function getEstimatedReturn(address acoToken, uint256 tokenAmount) external view returns(uint256);
    function flashExercise(address acoToken, uint256 tokenAmount, uint256 minimumCollateral, uint256 salt) external;
    function flashExerciseAccounts(address acoToken, uint256 tokenAmount, uint256 minimumCollateral, address[] calldata accounts) external;
    function uniswapV2Call(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}
"},"IACOPool.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './IERC20.sol';

interface IACOPool is IERC20 {
    struct InitData {
        uint256 poolStart;
        address acoFlashExercise;
        address acoFactory;
        address chiToken;
        uint256 fee;
        address feeDestination;
        address underlying;
        address strikeAsset;
        uint256 minStrikePrice; 
        uint256 maxStrikePrice;
        uint256 minExpiration;
        uint256 maxExpiration;
        bool isCall; 
        bool canBuy;
        address strategy;
        uint256 baseVolatility;    
    }
    
	function init(InitData calldata initData) external;
    function numberOfACOTokensCurrentlyNegotiated() external view returns(uint256);
    function collateral() external view returns(address);
    function setStrategy(address strategy) external;
    function setBaseVolatility(uint256 baseVolatility) external;
    function quote(bool isBuying, address acoToken, uint256 tokenAmount) external view returns(uint256 swapPrice, uint256 fee, uint256 underlyingPrice);
    function swap(bool isBuying, address acoToken, uint256 tokenAmount, uint256 restriction, address to, uint256 deadline) external returns(uint256);
    function swapWithGasToken(bool isBuying, address acoToken, uint256 tokenAmount, uint256 restriction, address to, uint256 deadline) external returns(uint256);
    function exerciseACOToken(address acoToken) external;
    function redeemACOTokens() external;
	function redeemACOToken(address acoToken) external;
    function deposit(uint256 collateralAmount, address to) external payable returns(uint256 acoPoolTokenAmount);
    function redeem() external returns(uint256 underlyingReceived, uint256 strikeAssetReceived);
    function redeemFrom(address account) external returns(uint256 underlyingReceived, uint256 strikeAssetReceived);
    function restoreCollateral() external;
}"},"IACOStrategy.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IACOStrategy {
    
    struct OptionQuote {
        bool isSellingQuote;
        address underlying;
        address strikeAsset;
        bool isCallOption;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 baseVolatility;
        uint256 collateralOrderAmount;
        uint256 collateralAvailable;
        uint256 collateralTotalDeposited;
        uint256 strikeAssetEarnedSelling;
        uint256 strikeAssetSpentBuying;
        uint256 amountPurchased;
        uint256 amountSold;
    }
    
    struct CheckExercise {
        address underlying;
        address strikeAsset;
        bool isCallOption;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 collateralAmount;
        uint256 collateralAvailable;
        uint256 amountPurchased;
        uint256 amountSold;
    }
    
    function quote(OptionQuote calldata quoteData) external view returns(uint256 optionPrice, uint256 underlyingPrice, uint256 volatility);
    function getUnderlyingPrice(address underlying, address strikeAsset) external view returns(uint256 underlyingPrice);
    function getAcceptableUnderlyingPriceToSwapAssets(address underlying, address strikeAsset, bool isBuying) external view returns(uint256 acceptablePrice);
    function checkExercise(CheckExercise calldata exerciseData) external view returns(bool canExercise, uint256 minIntrinsicValue);
}"},"IACOToken.sol":{"content":"pragma solidity ^0.6.6;

import "./IERC20.sol";

interface IACOToken is IERC20 {
	function init(address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime, uint256 _acoFee, address payable _feeDestination, uint256 _maxExercisedAccounts) external;
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function underlying() external view returns (address);
    function strikeAsset() external view returns (address);
    function feeDestination() external view returns (address);
    function isCall() external view returns (bool);
    function strikePrice() external view returns (uint256);
    function expiryTime() external view returns (uint256);
    function totalCollateral() external view returns (uint256);
    function acoFee() external view returns (uint256);
	function maxExercisedAccounts() external view returns (uint256);
    function underlyingSymbol() external view returns (string memory);
    function strikeAssetSymbol() external view returns (string memory);
    function underlyingDecimals() external view returns (uint8);
    function strikeAssetDecimals() external view returns (uint8);
    function currentCollateral(address account) external view returns(uint256);
    function unassignableCollateral(address account) external view returns(uint256);
    function assignableCollateral(address account) external view returns(uint256);
    function currentCollateralizedTokens(address account) external view returns(uint256);
    function unassignableTokens(address account) external view returns(uint256);
    function assignableTokens(address account) external view returns(uint256);
    function getCollateralAmount(uint256 tokenAmount) external view returns(uint256);
    function getTokenAmount(uint256 collateralAmount) external view returns(uint256);
    function getBaseExerciseData(uint256 tokenAmount) external view returns(address, uint256);
    function numberOfAccountsWithCollateral() external view returns(uint256);
    function getCollateralOnExercise(uint256 tokenAmount) external view returns(uint256, uint256);
    function collateral() external view returns(address);
    function mintPayable() external payable returns(uint256);
    function mintToPayable(address account) external payable returns(uint256);
    function mint(uint256 collateralAmount) external returns(uint256);
    function mintTo(address account, uint256 collateralAmount) external returns(uint256);
    function burn(uint256 tokenAmount) external returns(uint256);
    function burnFrom(address account, uint256 tokenAmount) external returns(uint256);
    function redeem() external returns(uint256);
    function redeemFrom(address account) external returns(uint256);
    function exercise(uint256 tokenAmount, uint256 salt) external payable returns(uint256);
    function exerciseFrom(address account, uint256 tokenAmount, uint256 salt) external payable returns(uint256);
    function exerciseAccounts(uint256 tokenAmount, address[] calldata accounts) external payable returns(uint256);
    function exerciseAccountsFrom(address account, uint256 tokenAmount, address[] calldata accounts) external payable returns(uint256);
}"},"IChiToken.sol":{"content":"pragma solidity ^0.6.6;

import './IERC20.sol';

interface IChiToken is IERC20 {
    function mint(uint256 value) external;
    function computeAddress2(uint256 salt) external view returns(address);
    function free(uint256 value) external returns(uint256);
    function freeUpTo(uint256 value) external returns(uint256);
    function freeFrom(address from, uint256 value) external returns(uint256);
    function freeFromUpTo(address from, uint256 value) external returns(uint256);
}"},"IERC20.sol":{"content":"pragma solidity ^0.6.6;

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

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
"},"IUniswapV2Router02.sol":{"content":"pragma solidity 0.6.6;

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
}"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function init() internal {
        require(_owner == address(0), "Ownable: Contract initialized");
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}"},"SafeMath.sol":{"content":"pragma solidity ^0.6.6;

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"},"Strings.sol":{"content":"pragma solidity ^0.6.6;

// Contract on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
"}}