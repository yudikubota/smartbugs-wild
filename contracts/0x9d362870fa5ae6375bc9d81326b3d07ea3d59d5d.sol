{"ACOAssetHelper.sol":{"content":"pragma solidity ^0.6.6;

library ACOAssetHelper {
    uint256 internal constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

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
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "approve");
    }
    
    /**
     * @dev Internal function to transfer ERC20 tokens.
     * @param token Address of the token.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
    function _callTransferERC20(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "transfer");
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
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "transferFrom");
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
            require(success, "symbol");
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
            require(success, "decimals");
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
            require(success, "name");
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
            require(success, "balanceOf");
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
            require(success, "allowance");
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
            require(success, "send");
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
            require(msg.value == amount, "Invalid ETH amount");
        } else {
            require(msg.value == 0, "No payable");
            _callTransferFromERC20(asset, msg.sender, address(this), amount);
        }
    }

    /**
     * @dev Internal function to check asset allowance and set to Infinity if necessary.
     * @param asset Address of the asset.
     * @param owner Address of the owner of the tokens.
     * @param spender Address of the spender authorized.
     * @param amount Amount to check allowance.
     */
    function _setAssetInfinityApprove(address asset, address owner, address spender, uint256 amount) internal {
        if (_getAssetAllowance(asset, owner, spender) < amount) {
            _callApproveERC20(asset, spender, MAX_UINT);
        }
    }
}"},"ACOPool2.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './Ownable.sol';
import './Address.sol';
import './ACOAssetHelper.sol';
import './ACOPoolLib.sol';
import './ERC20.sol';
import './IACOFactory.sol';
import './IACOPoolFactory2.sol';
import './IACOAssetConverterHelper.sol';
import './IACOToken.sol';
import './IChiToken.sol';
import './IACOPool2.sol';
import './ILendingPool.sol';

/**
 * @title ACOPool2
 * @dev A pool contract to trade ACO tokens.
 * 
 * The SC errors are defined as code to shrunk the SC bytes size and work around the EIP170.
 * The codes are explained in the table below:
 ********************************************************************************************
 * CODE | FUNCTION                            | DESCRIPTION						            *
 *------------------------------------------------------------------------------------------*
 * E00  | init                                | SC is already initialized                   *
 *------------------------------------------------------------------------------------------*
 * E01  | init                                | Underlying and strike asset are the same    *
 *------------------------------------------------------------------------------------------*
 * E02  | init                                | Invalid underlying address                  *
 *------------------------------------------------------------------------------------------*
 * E03  | init                                | Invalid strike asset address                *
 *------------------------------------------------------------------------------------------*
 * E10  | _deposit                            | Invalid collateral amount                   *
 *------------------------------------------------------------------------------------------*
 * E11  | _deposit                            | Invalid destination address                 *
 *------------------------------------------------------------------------------------------*
 * E12  | _deposit                            | Invalid deposit for lending pool token      *
 *------------------------------------------------------------------------------------------*
 * E13  | _deposit                            | The minimum shares were not satisfied       *
 *------------------------------------------------------------------------------------------*
 * E20  | _withdrawWithLocked                 | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E21  | _withdrawWithLocked                 | Invalid withdraw for lending pool token     *
 *------------------------------------------------------------------------------------------*
 * E30  | _withdrawNoLocked                   | Invalid shares amount                       *
 *------------------------------------------------------------------------------------------*
 * E31  | _withdrawNoLocked                   | Invalid withdraw for lending pool token     *
 *------------------------------------------------------------------------------------------*
 * E40  | _swap                               | Swap deadline reached                       *
 *------------------------------------------------------------------------------------------*
 * E41  | _swap                               | Invalid destination address                 *
 *------------------------------------------------------------------------------------------*
 * E42  | _internalSelling                    | The maximum payment restriction was reached *
 *------------------------------------------------------------------------------------------*
 * E43  | _internalSelling                    | The maximum number of open ACOs was reached *
 *------------------------------------------------------------------------------------------*
 * E50  | _quote                              | Invalid token amount                        *
 *------------------------------------------------------------------------------------------*
 * E51  | _quote                              | Invalid ACO token                           *
 *------------------------------------------------------------------------------------------*
 * E60  | restoreCollateral                   | No balance to restore                       *
 *------------------------------------------------------------------------------------------*
 * E70  | lendCollateral                      | Lend is not available for this pool         *
 *------------------------------------------------------------------------------------------*
 * E80  | withdrawStuckToken                  | The token is forbidden to withdraw          *
 *------------------------------------------------------------------------------------------*
 * E81  | _setPoolDataForAcoPermission        | Invalid below tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E82  | _setPoolDataForAcoPermission        | Invalid above tolerance percentage          *
 *------------------------------------------------------------------------------------------*
 * E83  | _setPoolDataForAcoPermission        | Invalid expiration range                    *
 *------------------------------------------------------------------------------------------*
 * E84  | _setBaseVolatility                  | Invalid base volatility                     *
 *------------------------------------------------------------------------------------------*
 * E85  | _setStrategy                        | Invalid strategy address                    *
 *------------------------------------------------------------------------------------------*
 * E86  | _setPoolAdmin                       | Invalid pool admin address                  *
 *------------------------------------------------------------------------------------------*
 * E87  | _setProtocolConfig                  | No price on the Oracle                      *
 *------------------------------------------------------------------------------------------*
 * E88  | _setProtocolConfig                  | Invalid fee destination address             *
 *------------------------------------------------------------------------------------------*
 * E89  | _setProtocolConfig                  | Invalid fee value                           *
 *------------------------------------------------------------------------------------------*
 * E90  | _setProtocolConfig                  | Invalid penalty percentage                  *
 *------------------------------------------------------------------------------------------*
 * E91  | _setProtocolConfig                  | Invalid underlying price adjust percentage  *
 *------------------------------------------------------------------------------------------*
 * E92  | _setProtocolConfig                  | Invalid maximum number of open ACOs allowed *
 *------------------------------------------------------------------------------------------*
 * E98  | _onlyAdmin                          | Only the pool admin can call the method     *
 *------------------------------------------------------------------------------------------*
 * E99  | _onlyProtocolOwner                  | Only the pool factory can call the method   *
 ********************************************************************************************
 */
contract ACOPool2 is Ownable, ERC20 {
    using Address for address;
    
    uint256 internal constant PERCENTAGE_PRECISION = 100000;

    event SetValidAcoCreator(address indexed creator, bool indexed previousPermission, bool indexed newPermission);
    
    event SetProtocolConfig(IACOPool2.PoolProtocolConfig oldConfig, IACOPool2.PoolProtocolConfig newConfig);
	
	event SetPoolDataForAcoPermission(uint256 oldTolerancePriceBelow, uint256 oldTolerancePriceAbove, uint256 oldMinExpiration, uint256 oldMaxExpiration, uint256 newTolerancePriceBelow, uint256 newTolerancePriceAbove, uint256 newMinExpiration, uint256 newMaxExpiration);

    event SetBaseVolatility(uint256 indexed oldBaseVolatility, uint256 indexed newBaseVolatility);

	event SetStrategy(address indexed oldStrategy, address indexed newStrategy);
	
    event SetPoolAdmin(address indexed oldAdmin, address indexed newAdmin);

    event RestoreCollateral(uint256 amountOut, uint256 collateralRestored);

    event LendCollateral(uint256 collateralAmount);

	event ACORedeem(address indexed acoToken, uint256 valueSold, uint256 collateralLocked, uint256 collateralRedeemed);

    event Deposit(address indexed account, uint256 shares, uint256 collateralAmount);

    event Withdraw(
		address indexed account, 
		uint256 shares, 
		bool noLocked, 
		uint256 underlyingWithdrawn, 
		uint256 strikeAssetWithdrawn, 
		address[] acos, 
		uint256[] acosAmount
	);

	event Swap(
        address indexed account, 
        address indexed acoToken, 
        uint256 tokenAmount, 
        uint256 price, 
        uint256 protocolFee,
        uint256 underlyingPrice,
		uint256 volatility
    );

    IACOFactory public acoFactory;
	IChiToken public chiToken;
	ILendingPool public lendingPool;
    address public underlying;
    address public strikeAsset;
    bool public isCall;

    address public admin;
	address public strategy;
    uint256 public baseVolatility;
    uint256 public tolerancePriceAbove;
    uint256 public tolerancePriceBelow;
    uint256 public minExpiration;
    uint256 public maxExpiration;
    
	uint16 public lendingPoolReferral;
	uint256 public withdrawOpenPositionPenalty;
	uint256 public underlyingPriceAdjustPercentage;
    uint256 public fee;
	uint256 public maximumOpenAco;
	address public feeDestination;
    IACOAssetConverterHelper public assetConverter;
    
    address[] public acoTokens;
    address[] public openAcos;

    mapping(address => bool) public validAcoCreators;
    mapping(address => IACOPool2.AcoData) public acoData;

    address internal lendingToken;
	uint256 internal underlyingPrecision;

	modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function init(IACOPool2.InitData calldata initData) external {
		require(underlying == address(0) && strikeAsset == address(0), "E00");
        
        require(initData.underlying != initData.strikeAsset, "E01");
        require(ACOAssetHelper._isEther(initData.underlying) || initData.underlying.isContract(), "E02");
        require(ACOAssetHelper._isEther(initData.strikeAsset) || initData.strikeAsset.isContract(), "E03");
        
        super.init();

        acoFactory = IACOFactory(initData.acoFactory);
        chiToken = IChiToken(initData.chiToken);
        lendingPool = ILendingPool(initData.lendingPool);
        underlying = initData.underlying;
        strikeAsset = initData.strikeAsset;
        isCall = initData.isCall;
		
		_setProtocolConfig(initData.config);
		_setPoolAdmin(initData.admin);
		_setPoolDataForAcoPermission(initData.tolerancePriceBelow, initData.tolerancePriceAbove, initData.minExpiration, initData.maxExpiration);
        _setBaseVolatility(initData.baseVolatility);
        _setStrategy(initData.strategy);
		
		if (!initData.isCall) {
		    lendingToken = ILendingPool(initData.lendingPool).getReserveData(initData.strikeAsset).aTokenAddress;
            _setAuthorizedSpender(initData.strikeAsset, initData.lendingPool);
        }
		underlyingPrecision = 10 ** uint256(ACOAssetHelper._getAssetDecimals(initData.underlying));
    }

    receive() external payable {
    }

    function name() public override view returns(string memory) {
        return ACOPoolLib.name(underlying, strikeAsset, isCall);
    }

	function symbol() public override view returns(string memory) {
        return name();
    }

    function decimals() public override view returns(uint8) {
        return ACOAssetHelper._getAssetDecimals(collateral());
    }

    function numberOfAcoTokensNegotiated() external view returns(uint256) {
        return acoTokens.length;
    }

    function numberOfOpenAcoTokens() external view returns(uint256) {
        return openAcos.length;
    }

	function collateral() public view returns(address) {
        return (isCall ? underlying : strikeAsset);
    }

    function canSwap(address acoToken) external view returns(bool) {
        (address _underlying, address _strikeAsset, bool _isCall, uint256 _strikePrice, uint256 _expiryTime) = acoFactory.acoTokenData(acoToken);
		if (_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall) && 
		    ACOPoolLib.acoExpirationIsValid(_expiryTime, minExpiration, maxExpiration)) {
            uint256 price = _getPrice(_underlying, _strikeAsset);
            return ACOPoolLib.acoStrikePriceIsValid(tolerancePriceBelow, tolerancePriceAbove, _strikePrice, price);
        }
        return false;
    }

	function quote(address acoToken, uint256 tokenAmount) external view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility
    ) {
        (swapPrice, protocolFee, underlyingPrice, volatility,) = _quote(acoToken, tokenAmount);
    }

	function getDepositShares(uint256 collateralAmount) external view returns(uint256) {
        (,,uint256 collateralBalance,) = _getCollateralNormalized(true);

        if (collateralBalance == 0) {
            return collateralAmount;
        } else {
            return collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
    }

	function getWithdrawNoLockedData(uint256 shares) external view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
    ) {
        uint256 _totalSupply = totalSupply();
		if (shares > 0 && shares <= _totalSupply) {
			
			(uint256 underlyingBalance, 
             uint256 strikeAssetBalance, 
             uint256 collateralBalance, 
             uint256 collateralLockedRedeemable) = _getCollateralNormalized(false);
             
            (underlyingWithdrawn, strikeAssetWithdrawn, isPossible) = ACOPoolLib.getBaseWithdrawNoLockedData(
                shares,
                _totalSupply,
                isCall,
                underlyingBalance, 
                strikeAssetBalance, 
                collateralBalance, 
                collateralLockedRedeemable
            );
		}
    }

	function getWithdrawWithLocked(uint256 shares) external view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
    ) {
        uint256 _totalSupply = totalSupply();	
        if (shares > 0 && shares <= _totalSupply) {
        
            (underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getBaseAssetsWithdrawWithLocked(shares, underlying, strikeAsset, isCall, _totalSupply, lendingToken);
		
            acos = new address[](openAcos.length);
            acosAmount = new uint256[](openAcos.length);
			for (uint256 i = 0; i < openAcos.length; ++i) {
				address acoToken = openAcos[i];
				uint256 tokens = IACOToken(acoToken).currentCollateralizedTokens(address(this));
				
				acos[i] = acoToken;
				acosAmount[i] = tokens.mul(shares).div(_totalSupply);
			}
		}
    }

	function getGeneralData() external view returns(
        uint256 underlyingBalance,
		uint256 strikeAssetBalance,
		uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable,
		uint256 poolSupply
    ) {
        poolSupply = totalSupply();
        (underlyingBalance, strikeAssetBalance,, collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getCollateralData(true);
    }
    
    function setPoolDataForAcoPermission(
        uint256 newTolerancePriceBelow, 
        uint256 newTolerancePriceAbove,
        uint256 newMinExpiration,
        uint256 newMaxExpiration
    ) external {
        _onlyAdmin();
        _setPoolDataForAcoPermission(newTolerancePriceBelow, newTolerancePriceAbove, newMinExpiration, newMaxExpiration);
    }

	function setBaseVolatility(uint256 newBaseVolatility) external {
        _onlyAdmin();
		_setBaseVolatility(newBaseVolatility);
	}
	
	function setStrategy(address newStrategy) external {
        _onlyAdmin();
		_setStrategy(newStrategy);
	}
	
	function setPoolAdmin(address newAdmin) external {
	    _onlyAdmin();
		_setPoolAdmin(newAdmin);
	}

	function setValidAcoCreator(address newAcoCreator, bool newPermission) external {
        _onlyProtocolOwner();
        _setValidAcoCreator(newAcoCreator, newPermission);
    }
    
    function setProtocolConfig(IACOPool2.PoolProtocolConfig calldata newConfig) external {
        _onlyProtocolOwner();
        _setProtocolConfig(newConfig);
    }

    function withdrawStuckToken(address token, address destination) external {
        _onlyProtocolOwner();
        require(token != underlying && token != strikeAsset && !acoData[token].open && (isCall || token != lendingToken), "E80");
        uint256 _balance = ACOAssetHelper._getAssetBalanceOf(token, address(this));
        if (_balance > 0) {
            ACOAssetHelper._transferAsset(token, destination, _balance);
        }
    }

	function deposit(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to, 
	    bool isLendingToken
    ) external payable returns(uint256) {
        return _deposit(collateralAmount, minShares, to, isLendingToken);
    }

	function depositWithGasToken(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to, 
	    bool isLendingToken
    ) discountCHI external payable returns(uint256) {
        return _deposit(collateralAmount, minShares, to, isLendingToken);
    }

    function withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account, withdrawLendingToken);
    }

	function withdrawWithLockedWithGasToken(uint256 shares, address account, bool withdrawLendingToken) discountCHI external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount) = _withdrawWithLocked(shares, account, withdrawLendingToken);
    }

	function withdrawNoLocked(
	    uint256 shares, 
	    uint256 minCollateral, 
	    address account, 
	    bool withdrawLendingToken
    ) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account, withdrawLendingToken);
    }

	function withdrawNoLockedWithGasToken(
	    uint256 shares, 
	    uint256 minCollateral, 
	    address account, 
	    bool withdrawLendingToken
    ) discountCHI external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (underlyingWithdrawn, strikeAssetWithdrawn) = _withdrawNoLocked(shares, minCollateral, account, withdrawLendingToken);
    }

	function swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) external {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }

    function swapWithGasToken(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) discountCHI external {
        _swap(acoToken, tokenAmount, restriction, to, deadline);
    }

    function redeemACOTokens() public {
        for (uint256 i = openAcos.length; i > 0; --i) {
            address acoToken = openAcos[i - 1];
            redeemACOToken(acoToken);
        }
    }

	function redeemACOToken(address acoToken) public {
		IACOPool2.AcoData storage data = acoData[acoToken];
		if (data.open && IACOToken(acoToken).expiryTime() <= block.timestamp) {
			
            data.open = false;
			uint256 lastIndex = openAcos.length - 1;
    		uint256 index = data.openIndex;
    		if (lastIndex != index) {
    		    address last = openAcos[lastIndex];
    			openAcos[index] = last;
    			acoData[last].openIndex = index;
    		}
    		data.openIndex = 0;
            openAcos.pop();

            if (IACOToken(acoToken).currentCollateralizedTokens(address(this)) > 0) {	
			    data.collateralRedeemed = IACOToken(acoToken).redeem();
			    if (!isCall) {
			        _depositOnLendingPool(data.collateralRedeemed);
			    }
            }
			
			emit ACORedeem(acoToken, data.valueSold, data.collateralLocked, data.collateralRedeemed);
		}
    }

	function restoreCollateral() external {
        _onlyAdmin();
        
        uint256 balanceOut;
        address assetIn;
        address assetOut;
        if (isCall) {
            balanceOut = _getPoolBalanceOf(strikeAsset);
            assetIn = underlying;
            assetOut = strikeAsset;
        } else {
            balanceOut = _getPoolBalanceOf(underlying);
            assetIn = strikeAsset;
            assetOut = underlying;
        }
        require(balanceOut > 0, "E60");
        
		uint256 etherAmount = 0;
        if (ACOAssetHelper._isEther(assetOut)) {
			etherAmount = balanceOut;
        }
        uint256 collateralRestored = assetConverter.swapExactAmountOut{value: etherAmount}(assetOut, assetIn, balanceOut);
        if (!isCall) {
            _depositOnLendingPool(collateralRestored);
        }

        emit RestoreCollateral(balanceOut, collateralRestored);
    }

	function lendCollateral() external {
		require(!isCall, "E70");
	    uint256 strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
	    if (strikeAssetBalance > 0) {
	        _depositOnLendingPool(strikeAssetBalance);
	        emit LendCollateral(strikeAssetBalance);
	    }
    }

	function _quote(address acoToken, uint256 tokenAmount) internal view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 underlyingPrice, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        require(tokenAmount > 0, "E50");
        
        (address _underlying, address _strikeAsset, bool _isCall, uint256 strikePrice, uint256 expiryTime) = acoFactory.acoTokenData(acoToken);
        
		require(_acoBasicDataIsValid(acoToken, _underlying, _strikeAsset, _isCall), "E51");
		
		underlyingPrice = _getPrice(_underlying, _strikeAsset);
		
        (swapPrice, protocolFee, volatility, collateralAmount) = ACOPoolLib.quote(ACOPoolLib.QuoteData(
    		_isCall,
            tokenAmount, 
    		_underlying,
    		_strikeAsset,
    		strikePrice, 
    		expiryTime, 
    		lendingToken,
    		strategy,
    		baseVolatility,
    		fee,
    		minExpiration,
    		maxExpiration,
    		tolerancePriceBelow,
    		tolerancePriceAbove,
    		underlyingPrice,
    		underlyingPrecision));
    }
    
	function _deposit(
	    uint256 collateralAmount, 
	    uint256 minShares, 
	    address to,
	    bool isLendingToken
    ) internal returns(uint256 shares) {
        require(collateralAmount > 0, "E10");
        require(to != address(0) && to != address(this), "E11");
        require(!isLendingToken || !isCall, "E12");
		
		(,,uint256 collateralBalance,) = _getCollateralNormalized(true);

		address _collateral = collateral();
		if (ACOAssetHelper._isEther(_collateral)) {
            collateralBalance = collateralBalance.sub(msg.value);
		}
        
        if (collateralBalance == 0) {
            shares = collateralAmount;
        } else {
            shares = collateralAmount.mul(totalSupply()).div(collateralBalance);
        }
        require(shares >= minShares, "E13");

        if (isLendingToken) {
            ACOAssetHelper._receiveAsset(lendingToken, collateralAmount);
        } else {
            ACOAssetHelper._receiveAsset(_collateral, collateralAmount);
            if (!isCall) {
                _depositOnLendingPool(collateralAmount);
            }
        }
        
        super._mintAction(to, shares);
        
        emit Deposit(to, shares, collateralAmount);
    }

	function _withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	) {
        require(shares > 0, "E20");
        require(!withdrawLendingToken || !isCall, "E21");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
		(underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getAmountToLockedWithdraw(shares, _totalSupply, lendingToken, underlying, strikeAsset, isCall);
		
		(acos, acosAmount) = _transferOpenPositions(shares, _totalSupply);

		_transferWithdrawnAssets(underlyingWithdrawn, strikeAssetWithdrawn, withdrawLendingToken);

        emit Withdraw(account, shares, false, underlyingWithdrawn, strikeAssetWithdrawn, acos, acosAmount);
    }
    
    function _withdrawNoLocked(
        uint256 shares, 
        uint256 minCollateral, 
        address account, 
        bool withdrawLendingToken
    ) internal returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        require(shares > 0, "E30");
        bool _isCall = isCall;
        require(!withdrawLendingToken || !_isCall, "E31");
        
		redeemACOTokens();
		
        uint256 _totalSupply = totalSupply();
        _callBurn(account, shares);
        
        (underlyingWithdrawn, strikeAssetWithdrawn) = _getAmountToNoLockedWithdraw(shares, _totalSupply, minCollateral, _isCall);
        
        _transferWithdrawnAssets(underlyingWithdrawn, strikeAssetWithdrawn, withdrawLendingToken);
		
        emit Withdraw(account, shares, true, underlyingWithdrawn, strikeAssetWithdrawn, new address[](0), new uint256[](0));
    }

    function _transferWithdrawnAssets(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn, 
        bool withdrawLendingToken
    ) internal {
        if (strikeAssetWithdrawn > 0) {
            if (withdrawLendingToken) {
    		    ACOAssetHelper._transferAsset(lendingToken, msg.sender, strikeAssetWithdrawn);
    		} else if (isCall) {
    		    ACOAssetHelper._transferAsset(strikeAsset, msg.sender, strikeAssetWithdrawn);
    		} else {
    		    _withdrawOnLendingPool(strikeAssetWithdrawn, msg.sender);
    		}
        }
        if (underlyingWithdrawn > 0) {
		    ACOAssetHelper._transferAsset(underlying, msg.sender, underlyingWithdrawn);
        }
    }

	function _getCollateralNormalized(bool isDeposit) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralLockedRedeemable
    ) {
        uint256 collateralLocked;
        uint256 collateralOnOpenPosition;
        (underlyingBalance, strikeAssetBalance, collateralBalance, collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getCollateralData(isDeposit);
        collateralBalance = collateralBalance.add(collateralLocked).sub(collateralOnOpenPosition);
    }

	function _getCollateralData(bool isDeposit) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		uint256 underlyingPrice = _getPrice(underlying, strikeAsset);
		(underlyingBalance, strikeAssetBalance, collateralBalance) = _getBaseCollateralData(underlyingPrice, isDeposit);
		(collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _poolOpenPositionCollateralBalance(underlyingPrice, isDeposit);
	}
	
	function _getBaseCollateralData(
	    uint256 underlyingPrice,
	    bool isDeposit
	) internal view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance
    ) {
        (underlyingBalance, strikeAssetBalance, collateralBalance) = ACOPoolLib.getBaseCollateralData(
            lendingToken,
            underlying, 
            strikeAsset, 
            isCall, 
            underlyingPrice, 
            underlyingPriceAdjustPercentage, 
            underlyingPrecision, 
            isDeposit
        );
    }

	function _poolOpenPositionCollateralBalance(uint256 underlyingPrice, bool isDeposit) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        ACOPoolLib.OpenPositionData memory openPositionData = ACOPoolLib.OpenPositionData(
            underlyingPrice,
            baseVolatility,
            underlyingPriceAdjustPercentage,
            fee,
            underlyingPrecision,
            strategy,
            address(acoFactory),
            address(0)
        );
		for (uint256 i = 0; i < openAcos.length; ++i) {
			address acoToken = openAcos[i];
            
            openPositionData.acoToken = acoToken;
            (uint256 locked, uint256 openPosition, uint256 lockedRedeemable) = ACOPoolLib.getOpenPositionCollateralBalance(openPositionData);
            
            collateralLocked = collateralLocked.add(locked);
            collateralOnOpenPosition = collateralOnOpenPosition.add(openPosition);
            collateralLockedRedeemable = collateralLockedRedeemable.add(lockedRedeemable);
		}
		if (!isDeposit) {
			collateralOnOpenPosition = collateralOnOpenPosition.mul(PERCENTAGE_PRECISION.add(withdrawOpenPositionPenalty)).div(PERCENTAGE_PRECISION);
		}
	}
    
    function _getAmountToNoLockedWithdraw(
        uint256 shares, 
        uint256 _totalSupply, 
        uint256 minCollateral,
        bool _isCall
    ) internal view returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	) {
        (uint256 underlyingBalance, 
         uint256 strikeAssetBalance, 
         uint256 collateralBalance,) = _getCollateralNormalized(false);

        (underlyingWithdrawn, strikeAssetWithdrawn) = ACOPoolLib.getAmountToNoLockedWithdraw(shares, _totalSupply, underlyingBalance, strikeAssetBalance, collateralBalance, minCollateral, _isCall);
    }

	function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }

	function _swap(
        address acoToken, 
        uint256 tokenAmount, 
        uint256 restriction, 
        address to, 
        uint256 deadline
    ) internal {
        require(block.timestamp <= deadline, "E40");
        require(to != address(0) && to != acoToken && to != address(this), "E41");
        
        (uint256 swapPrice, uint256 protocolFee, uint256 underlyingPrice, uint256 volatility, uint256 collateralAmount) = _quote(acoToken, tokenAmount);
        
        _internalSelling(to, acoToken, collateralAmount, tokenAmount, restriction, swapPrice, protocolFee);

        if (protocolFee > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, feeDestination, protocolFee);
        }
        
        emit Swap(msg.sender, acoToken, tokenAmount, swapPrice, protocolFee, underlyingPrice, volatility);
    }

    function _internalSelling(
        address to,
        address acoToken, 
        uint256 collateralAmount, 
        uint256 tokenAmount,
        uint256 maxPayment,
        uint256 swapPrice,
        uint256 protocolFee
    ) internal {
        require(swapPrice <= maxPayment, "E42");
        
        ACOAssetHelper._callTransferFromERC20(strikeAsset, msg.sender, address(this), swapPrice);
        uint256 remaining = swapPrice.sub(protocolFee);
        
        if (!isCall) {
            _withdrawOnLendingPool(collateralAmount.sub(remaining), address(this));
        }
        
		address _collateral = collateral();
        IACOPool2.AcoData storage data = acoData[acoToken];
		if (ACOAssetHelper._isEther(_collateral)) {
			tokenAmount = IACOToken(acoToken).mintPayable{value: collateralAmount}();
		} else {
			if (!data.open) {
				_setAuthorizedSpender(_collateral, acoToken);    
			}
			tokenAmount = IACOToken(acoToken).mint(collateralAmount);
		}

		if (!data.open) {
            require(openAcos.length < maximumOpenAco, "E43");
			acoData[acoToken] = IACOPool2.AcoData(true, remaining, collateralAmount, 0, acoTokens.length, openAcos.length);
            acoTokens.push(acoToken);    
            openAcos.push(acoToken);   
        } else {
			data.collateralLocked = collateralAmount.add(data.collateralLocked);
			data.valueSold = remaining.add(data.valueSold);
		}
        
        ACOAssetHelper._callTransferERC20(acoToken, to, tokenAmount);
    }

	function _transferOpenPositions(uint256 shares, uint256 _totalSupply) internal returns(
        address[] memory acos, 
        uint256[] memory acosAmount
    ) {
        uint256 size = openAcos.length;
        acos = new address[](size);
        acosAmount = new uint256[](size);
		for (uint256 i = 0; i < size; ++i) {
			address acoToken = openAcos[i];
			uint256 tokens = IACOToken(acoToken).currentCollateralizedTokens(address(this));
			
			acos[i] = acoToken;
			acosAmount[i] = tokens.mul(shares).div(_totalSupply);
			
            if (acosAmount[i] > 0) {
			    IACOToken(acoToken).transferCollateralOwnership(msg.sender, acosAmount[i]);
            }
		}
	}

    function _depositOnLendingPool(uint256 amount) internal {
        lendingPool.deposit(strikeAsset, amount, address(this), lendingPoolReferral);
    }

    function _withdrawOnLendingPool(uint256 amount, address to) internal {
        lendingPool.withdraw(strikeAsset, amount, to);
    }

	function _acoBasicDataIsValid(address acoToken, address _underlying, address _strikeAsset, bool _isCall) internal view returns(bool) {
		return _underlying == underlying && _strikeAsset == strikeAsset && _isCall == isCall && validAcoCreators[acoFactory.creators(acoToken)];
	}

	function _getPoolBalanceOf(address asset) internal view returns(uint256) {
        return ACOAssetHelper._getAssetBalanceOf(asset, address(this));
    }
	
	function _getPrice(address _underlying, address _strikeAsset) internal view returns(uint256) {
	    return assetConverter.getPrice(_underlying, _strikeAsset);
	}

	function _setAuthorizedSpender(address asset, address spender) internal {
        ACOAssetHelper._callApproveERC20(asset, spender, ACOAssetHelper.MAX_UINT);
    }

    function _setPoolDataForAcoPermission(
        uint256 newTolerancePriceBelow, 
        uint256 newTolerancePriceAbove,
        uint256 newMinExpiration,
        uint256 newMaxExpiration
    ) internal {
        require(newTolerancePriceBelow < PERCENTAGE_PRECISION, "E81");
        require(newTolerancePriceAbove < PERCENTAGE_PRECISION, "E82");
        require(newMaxExpiration >= newMinExpiration, "E83");
        
        emit SetPoolDataForAcoPermission(tolerancePriceBelow, tolerancePriceAbove, minExpiration, maxExpiration, newTolerancePriceBelow, newTolerancePriceAbove, newMinExpiration, newMaxExpiration);
        
        tolerancePriceBelow = newTolerancePriceBelow;
        tolerancePriceAbove = newTolerancePriceAbove;
        minExpiration = newMinExpiration;
        maxExpiration = newMaxExpiration;
    }

    function _setBaseVolatility(uint256 newBaseVolatility) internal {
        require(newBaseVolatility > 0, "E84");
        emit SetBaseVolatility(baseVolatility, newBaseVolatility);
        baseVolatility = newBaseVolatility;
    }
    
    function _setStrategy(address newStrategy) internal {
        require(IACOPoolFactory2(owner()).strategyPermitted(newStrategy), "E85");
        emit SetStrategy(address(strategy), newStrategy);
        strategy = newStrategy;
    }

    function _setPoolAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "E86");
        emit SetPoolAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function _setValidAcoCreator(address creator, bool newPermission) internal {
        emit SetValidAcoCreator(creator, validAcoCreators[creator], newPermission);
        validAcoCreators[creator] = newPermission;
    }
    
    function _setProtocolConfig(IACOPool2.PoolProtocolConfig memory newConfig) internal {
        address _underlying = underlying;
        address _strikeAsset = strikeAsset;
		require(IACOAssetConverterHelper(newConfig.assetConverter).getPrice(_underlying, _strikeAsset) > 0, "E87");
        require(newConfig.feeDestination != address(0), "E88");
        require(newConfig.fee <= 12500, "E89");
        require(newConfig.withdrawOpenPositionPenalty <= PERCENTAGE_PRECISION, "E90");
        require(newConfig.underlyingPriceAdjustPercentage < PERCENTAGE_PRECISION, "E91");
        require(newConfig.maximumOpenAco > 0, "E92");
        		
		if (isCall) {
            if (!ACOAssetHelper._isEther(_strikeAsset)) {
                _setAuthorizedSpender(_strikeAsset, newConfig.assetConverter);
            }
        } else if (!ACOAssetHelper._isEther(_underlying)) {
            _setAuthorizedSpender(_underlying, newConfig.assetConverter);
        }
        
        emit SetProtocolConfig(IACOPool2.PoolProtocolConfig(lendingPoolReferral, withdrawOpenPositionPenalty, underlyingPriceAdjustPercentage, fee, maximumOpenAco, feeDestination, address(assetConverter)), newConfig);
        
        assetConverter = IACOAssetConverterHelper(newConfig.assetConverter);
        lendingPoolReferral = newConfig.lendingPoolReferral;
        feeDestination = newConfig.feeDestination;
        fee = newConfig.fee;
        withdrawOpenPositionPenalty = newConfig.withdrawOpenPositionPenalty;
        underlyingPriceAdjustPercentage = newConfig.underlyingPriceAdjustPercentage;
        maximumOpenAco = newConfig.maximumOpenAco;
    }
    
    function _onlyAdmin() internal view {
        require(admin == msg.sender, "E98");
    }
    
    function _onlyProtocolOwner() internal view {
        require(owner() == msg.sender, "E99");
    }
}"},"ACOPoolLib.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IACOPoolStrategy.sol";
import "./IACOFactory.sol";
import "./IACOToken.sol";
import "./ILendingPool.sol";

library ACOPoolLib {
	using SafeMath for uint256;
	
	struct OpenPositionData {
        uint256 underlyingPrice;
        uint256 baseVolatility;
        uint256 underlyingPriceAdjustPercentage;
        uint256 fee;
        uint256 underlyingPrecision;
        address strategy;
        address acoFactory;
	    address acoToken;
	}
	
	struct QuoteData {
		bool isCall;
        uint256 tokenAmount; 
		address underlying;
		address strikeAsset;
		uint256 strikePrice; 
		uint256 expiryTime;
		address lendingToken;
		address strategy;
		uint256 baseVolatility;
		uint256 fee;
		uint256 minExpiration;
		uint256 maxExpiration;
		uint256 tolerancePriceBelow;
		uint256 tolerancePriceAbove;
		uint256 underlyingPrice;
		uint256 underlyingPrecision;
	}
	
	struct OpenPositionExtraData {
        bool isCall;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 tokenAmount;
	    address underlying;
        address strikeAsset; 
	}
	
	uint256 public constant PERCENTAGE_PRECISION = 100000;
	
	function name(address underlying, address strikeAsset, bool isCall) public view returns(string memory) {
        return string(abi.encodePacked(
            "ACO POOL WRITE ",
            _getAssetSymbol(underlying),
            "-",
            _getAssetSymbol(strikeAsset),
            "-",
            (isCall ? "CALL" : "PUT")
        ));
    }
    
	function acoStrikePriceIsValid(
		uint256 tolerancePriceBelow,
		uint256 tolerancePriceAbove,
		uint256 strikePrice, 
		uint256 price
	) public pure returns(bool) {
		return (tolerancePriceBelow == 0 && tolerancePriceAbove == 0) ||
			(tolerancePriceBelow == 0 && strikePrice > price.mul(PERCENTAGE_PRECISION.add(tolerancePriceAbove)).div(PERCENTAGE_PRECISION)) ||
			(tolerancePriceAbove == 0 && strikePrice < price.mul(PERCENTAGE_PRECISION.sub(tolerancePriceBelow)).div(PERCENTAGE_PRECISION)) ||
			(strikePrice >= price.mul(PERCENTAGE_PRECISION.sub(tolerancePriceBelow)).div(PERCENTAGE_PRECISION) && 
			 strikePrice <= price.mul(PERCENTAGE_PRECISION.add(tolerancePriceAbove)).div(PERCENTAGE_PRECISION));
	}

	function acoExpirationIsValid(uint256 acoExpiryTime, uint256 minExpiration, uint256 maxExpiration) public view returns(bool) {
		return acoExpiryTime >= block.timestamp.add(minExpiration) && acoExpiryTime <= block.timestamp.add(maxExpiration);
	}

    function getBaseAssetsWithdrawWithLocked(
        uint256 shares,
        address underlying,
        address strikeAsset,
        bool isCall,
        uint256 totalSupply,
        address lendingToken
    ) public view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
    ) {
		uint256 underlyingBalance = _getPoolBalanceOf(underlying);
		uint256 strikeAssetBalance;
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
		}
		
		underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
    }
    
    function getBaseWithdrawNoLockedData(
        uint256 shares,
        uint256 totalSupply,
        bool isCall,
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance, 
        uint256 collateralLockedRedeemable
    ) public pure returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
    ) {
		uint256 collateralAmount = shares.mul(collateralBalance).div(totalSupply);
		
		if (isCall) {
			underlyingWithdrawn = collateralAmount;
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
			isPossible = (collateralAmount <= underlyingBalance.add(collateralLockedRedeemable));
		} else {
			strikeAssetWithdrawn = collateralAmount;
			underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
			isPossible = (collateralAmount <= strikeAssetBalance.add(collateralLockedRedeemable));
		}
    }
    
    function getAmountToLockedWithdraw(
        uint256 shares, 
        uint256 totalSupply, 
        address lendingToken,
        address underlying, 
        address strikeAsset, 
        bool isCall
    ) public view returns(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn
    ) {
		uint256 underlyingBalance = _getPoolBalanceOf(underlying);
		uint256 strikeAssetBalance;
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
		}
		
		underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
    }
    
    function getAmountToNoLockedWithdraw(
        uint256 shares, 
        uint256 totalSupply,
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance,
        uint256 collateralBalance,
        uint256 minCollateral,
        bool isCall
    ) public pure returns(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn
    ) {
		uint256 collateralAmount = shares.mul(collateralBalance).div(totalSupply);
		require(collateralAmount >= minCollateral, "ACOPoolLib: The minimum collateral was not satisfied");

        if (isCall) {
			require(collateralAmount <= underlyingBalance, "ACOPoolLib: Collateral balance is not sufficient");
			underlyingWithdrawn = collateralAmount;
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
        } else {
			require(collateralAmount <= strikeAssetBalance, "ACOPoolLib: Collateral balance is not sufficient");
			strikeAssetWithdrawn = collateralAmount;
			underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		}
    }
    
	function getBaseCollateralData(
	    address lendingToken,
	    address underlying,
	    address strikeAsset,
	    bool isCall,
	    uint256 underlyingPrice,
	    uint256 underlyingPriceAdjustPercentage,
	    uint256 underlyingPrecision,
	    bool isDeposit
    ) public view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance
    ) {
		underlyingBalance = _getPoolBalanceOf(underlying);
		
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
			collateralBalance = underlyingBalance;
			if (isDeposit && strikeAssetBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, underlyingPriceAdjustPercentage, false); 
				collateralBalance = collateralBalance.add(strikeAssetBalance.mul(underlyingPrecision).div(priceAdjusted));
			}
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
			collateralBalance = strikeAssetBalance;
			if (isDeposit && underlyingBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, underlyingPriceAdjustPercentage, true); 
				collateralBalance = collateralBalance.add(underlyingBalance.mul(priceAdjusted).div(underlyingPrecision));
			}
		}
	}
	
	function getOpenPositionCollateralBalance(OpenPositionData memory data) public view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        OpenPositionExtraData memory extraData = _getOpenPositionCollateralExtraData(data.acoToken, data.acoFactory);
        (collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getOpenPositionCollateralBalance(data, extraData);
    }
    
    function quote(QuoteData memory data) public view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        require(data.expiryTime > block.timestamp, "ACOPoolLib: ACO token expired");
        require(acoExpirationIsValid(data.expiryTime, data.minExpiration, data.maxExpiration), "ACOPoolLib: Invalid ACO token expiration");
		require(acoStrikePriceIsValid(data.tolerancePriceBelow, data.tolerancePriceAbove, data.strikePrice, data.underlyingPrice), "ACOPoolLib: Invalid ACO token strike price");

        uint256 collateralAvailable;
        (collateralAmount, collateralAvailable) = _getOrderSizeData(data.tokenAmount, data.underlying, data.isCall, data.strikePrice, data.lendingToken, data.underlyingPrecision);
        uint256 calcPrice;
        (calcPrice, volatility) = _strategyQuote(data.strategy, data.underlying, data.strikeAsset, data.isCall, data.strikePrice, data.expiryTime, data.underlyingPrice, data.baseVolatility, collateralAmount, collateralAvailable);
        (swapPrice, protocolFee) = _setSwapPriceAndFee(calcPrice, data.tokenAmount, data.fee, data.underlyingPrecision);
    }
    
    
    function _getCollateralAmount(
		uint256 tokenAmount,
		uint256 strikePrice,
		bool isCall,
		uint256 underlyingPrecision
	) private pure returns(uint256) {
        if (isCall) {
            return tokenAmount;
        } else if (tokenAmount > 0) {
            return tokenAmount.mul(strikePrice).div(underlyingPrecision);
        } else {
            return 0;
        }
    }
    
    function _getOrderSizeData(
        uint256 tokenAmount,
        address underlying,
        bool isCall,
        uint256 strikePrice,
        address lendingToken,
        uint256 underlyingPrecision
    ) private view returns(
        uint256 collateralAmount, 
        uint256 collateralAvailable
    ) {
        if (isCall) {
            collateralAvailable = _getPoolBalanceOf(underlying);
            collateralAmount = tokenAmount; 
        } else {
            collateralAvailable = _getPoolBalanceOf(lendingToken);
            collateralAmount = _getCollateralAmount(tokenAmount, strikePrice, isCall, underlyingPrecision);
            require(collateralAmount > 0, "ACOPoolLib: The token amount is too small");
        }
        require(collateralAmount <= collateralAvailable, "ACOPoolLib: Insufficient liquidity");
    }
    
	function _strategyQuote(
        address strategy,
		address underlying,
		address strikeAsset,
		bool isCall,
		uint256 strikePrice,
        uint256 expiryTime,
        uint256 underlyingPrice,
		uint256 baseVolatility,
        uint256 collateralAmount,
        uint256 collateralAvailable
    ) private view returns(uint256 swapPrice, uint256 volatility) {
        (swapPrice, volatility) = IACOPoolStrategy(strategy).quote(IACOPoolStrategy.OptionQuote(
			underlyingPrice,
            underlying, 
            strikeAsset, 
            isCall, 
            strikePrice, 
            expiryTime, 
            baseVolatility, 
            collateralAmount, 
            collateralAvailable
        ));
    }
    
    function _setSwapPriceAndFee(
        uint256 calcPrice, 
        uint256 tokenAmount, 
        uint256 fee,
        uint256 underlyingPrecision
    ) private pure returns(uint256 swapPrice, uint256 protocolFee) {
        
        swapPrice = calcPrice.mul(tokenAmount).div(underlyingPrecision);
        
        if (fee > 0) {
            protocolFee = swapPrice.mul(fee).div(PERCENTAGE_PRECISION);
			swapPrice = swapPrice.add(protocolFee);
        }
        require(swapPrice > 0, "ACOPoolLib: Invalid quoted price");
    }
    
    function _getOpenPositionCollateralExtraData(address acoToken, address acoFactory) private view returns(OpenPositionExtraData memory extraData) {
        (address underlying, address strikeAsset, bool isCall, uint256 strikePrice, uint256 expiryTime) = IACOFactory(acoFactory).acoTokenData(acoToken);
        uint256 tokenAmount = IACOToken(acoToken).currentCollateralizedTokens(address(this));
        extraData = OpenPositionExtraData(isCall, strikePrice, expiryTime, tokenAmount, underlying, strikeAsset);
    }
    
	function _getOpenPositionCollateralBalance(
		OpenPositionData memory data,
		OpenPositionExtraData memory extraData
	) private view returns(
	    uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        collateralLocked = _getCollateralAmount(extraData.tokenAmount, extraData.strikePrice, extraData.isCall, data.underlyingPrecision);
        
        if (extraData.expiryTime > block.timestamp) {
    		(uint256 price,) = _strategyQuote(data.strategy, extraData.underlying, extraData.strikeAsset, extraData.isCall, extraData.strikePrice, extraData.expiryTime, data.underlyingPrice, data.baseVolatility, 0, 1);
    		if (data.fee > 0) {
    		    price = price.mul(PERCENTAGE_PRECISION.add(data.fee)).div(PERCENTAGE_PRECISION);
    		}
    		if (extraData.isCall) {
    			uint256 priceAdjusted = _getUnderlyingPriceAdjusted(data.underlyingPrice, data.underlyingPriceAdjustPercentage, false); 
    			collateralOnOpenPosition = price.mul(extraData.tokenAmount).div(priceAdjusted);
    		} else {
    			collateralOnOpenPosition = price.mul(extraData.tokenAmount).div(data.underlyingPrecision);
    		}
        } else {
            collateralLockedRedeemable = collateralLocked;
        }
	}
	
	function _getUnderlyingPriceAdjusted(uint256 underlyingPrice, uint256 underlyingPriceAdjustPercentage, bool isMaximum) private pure returns(uint256) {
		if (isMaximum) {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.add(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		} else {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.sub(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		}
    }
    
    function _getPoolBalanceOf(address asset) private view returns(uint256) {
        if (asset == address(0)) {
            return address(this).balance;
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
            require(success, "ACOPoolLib::_getAssetBalanceOf");
            return abi.decode(returndata, (uint256));
        }
    }
    
    function _getAssetSymbol(address asset) private view returns(string memory) {
        if (asset == address(0)) {
            return "ETH";
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x95d89b41));
            require(success, "ACOPoolLib::_getAssetSymbol");
            return abi.decode(returndata, (string));
        }
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

    function totalSupply() public view override virtual returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override virtual returns(uint256) {
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
"},"IACOAssetConverterHelper.sol":{"content":"pragma solidity ^0.6.6;

interface IACOAssetConverterHelper {
    function setPairTolerancePercentage(address baseAsset, address quoteAsset, uint256 tolerancePercentage) external;
    function setAggregator(address baseAsset, address quoteAsset, address aggregator) external;
    function setUniswapMiddleRoute(address baseAsset, address quoteAsset, address[] calldata uniswapMiddleRoute) external;
    function withdrawStuckAsset(address asset, address destination) external;
    function hasAggregator(address baseAsset, address quoteAsset) external view returns(bool);
    function getPairData(address baseAsset, address quoteAsset) external view returns(address, uint256, uint256, uint256);
    function getUniswapMiddleRouteByIndex(address baseAsset, address quoteAsset, uint256 index) external view returns(address);
    function getPrice(address baseAsset, address quoteAsset) external view returns(uint256);
    function getPriceWithTolerance(address baseAsset, address quoteAsset, bool isMinimumPrice) external view returns(uint256);
    function getExpectedAmountOutToSwapExactAmountIn(address assetToSold, address assetToBuy, uint256 amountToBuy) external view returns(uint256);
    function getExpectedAmountOutToSwapExactAmountInWithSpecificTolerance(address assetToSold, address assetToBuy, uint256 amountToBuy, uint256 tolerancePercentage) external view returns(uint256);
    function swapExactAmountOut(address assetToSold, address assetToBuy, uint256 amountToSold) external payable returns(uint256);
    function swapExactAmountOutWithSpecificTolerance(address assetToSold, address assetToBuy, uint256 amountToSold, uint256 tolerancePercentage) external payable returns(uint256);
    function swapExactAmountOutWithMinAmountToReceive(address assetToSold, address assetToBuy, uint256 amountToSold, uint256 minAmountToReceive) external payable returns(uint256);
    function swapExactAmountIn(address assetToSold, address assetToBuy, uint256 amountToBuy) external payable returns(uint256);
    function swapExactAmountInWithSpecificTolerance(address assetToSold, address assetToBuy, uint256 amountToBuy, uint256 tolerancePercentage) external payable returns(uint256);
    function swapExactAmountInWithMaxAmountToSold(address assetToSold, address assetToBuy, uint256 amountToBuy, uint256 maxAmountToSold) external payable returns(uint256);
}"},"IACOFactory.sol":{"content":"pragma solidity ^0.6.6;

interface IACOFactory {
	function init(address _factoryAdmin, address _acoTokenImplementation, uint256 _acoFee, address _acoFeeDestination) external;
    function acoFee() external view returns(uint256);
    function factoryAdmin() external view returns(address);
    function acoTokenImplementation() external view returns(address);
    function acoFeeDestination() external view returns(address);
    function acoTokenData(address acoToken) external view returns(address, address, bool, uint256, uint256);
    function creators(address acoToken) external view returns(address);
    function createAcoToken(address underlying, address strikeAsset, bool isCall, uint256 strikePrice, uint256 expiryTime, uint256 maxExercisedAccounts) external returns(address);
    function setFactoryAdmin(address newFactoryAdmin) external;
    function setAcoTokenImplementation(address newAcoTokenImplementation) external;
    function setAcoFee(uint256 newAcoFee) external;
    function setAcoFeeDestination(address newAcoFeeDestination) external;
}"},"IACOPool2.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import './IERC20.sol';

interface IACOPool2 is IERC20 {

    struct InitData {
        address acoFactory;
        address chiToken;
        address lendingPool;
        address underlying;
        address strikeAsset;
        bool isCall; 
        uint256 tolerancePriceBelow;
        uint256 tolerancePriceAbove; 
        uint256 minExpiration;
        uint256 maxExpiration;
        uint256 baseVolatility;  
        address admin;
        address strategy;  
        PoolProtocolConfig config;
    }

	struct AcoData {
        bool open;
        uint256 valueSold;
        uint256 collateralLocked;
        uint256 collateralRedeemed;
        uint256 index;
		uint256 openIndex;
    }
    
    struct PoolProtocolConfig {
        uint16 lendingPoolReferral;
        uint256 withdrawOpenPositionPenalty;
        uint256 underlyingPriceAdjustPercentage;
        uint256 fee;
        uint256 maximumOpenAco;
        address feeDestination;
        address assetConverter;
    }
    
	function init(InitData calldata initData) external;
	function numberOfAcoTokensNegotiated() external view returns(uint256);
    function numberOfOpenAcoTokens() external view returns(uint256);
    function collateral() external view returns(address);
	function canSwap(address acoToken) external view returns(bool);
	function quote(address acoToken, uint256 tokenAmount) external view returns(
		uint256 swapPrice, 
		uint256 protocolFee, 
		uint256 underlyingPrice, 
		uint256 volatility
	);
	function getDepositShares(uint256 collateralAmount) external view returns(uint256 shares);
	function getWithdrawNoLockedData(uint256 shares) external view returns(
		uint256 underlyingWithdrawn, 
		uint256 strikeAssetWithdrawn, 
		bool isPossible
	);
	function getWithdrawWithLocked(uint256 shares) external view returns(
		uint256 underlyingWithdrawn, 
		uint256 strikeAssetWithdrawn, 
		address[] memory acos, 
		uint256[] memory acosAmount
	);
	function getGeneralData() external view returns(
        uint256 underlyingBalance,
		uint256 strikeAssetBalance,
		uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable,
        uint256 poolSupply
    );
	function setLendingPoolReferral(uint16 newLendingPoolReferral) external;
	function setPoolDataForAcoPermission(uint256 newTolerancePriceBelow, uint256 newTolerancePriceAbove, uint256 newMinExpiration, uint256 newMaxExpiration) external;
	function setPoolAdmin(uint256 newAdmin) external;
	function setProtocolConfig(PoolProtocolConfig calldata newConfig) external;
	function setFeeData(address newFeeDestination, uint256 newFee) external;
	function setAssetConverter(address newAssetConverter) external;
    function setTolerancePriceBelow(uint256 newTolerancePriceBelow) external;
    function setTolerancePriceAbove(uint256 newTolerancePriceAbove) external;
    function setMinExpiration(uint256 newMinExpiration) external;
    function setMaxExpiration(uint256 newMaxExpiration) external;
    function setFee(uint256 newFee) external;
    function setFeeDestination(address newFeeDestination) external;
	function setWithdrawOpenPositionPenalty(uint256 newWithdrawOpenPositionPenalty) external;
	function setUnderlyingPriceAdjustPercentage(uint256 newUnderlyingPriceAdjustPercentage) external;
	function setMaximumOpenAco(uint256 newMaximumOpenAco) external;
	function setStrategy(address newStrategy) external;
	function setBaseVolatility(uint256 newBaseVolatility) external;
	function setValidAcoCreator(address newAcoCreator, bool newPermission) external;
    function withdrawStuckToken(address token, address destination) external;
    function deposit(uint256 collateralAmount, uint256 minShares, address to, bool isLendingToken) external payable returns(uint256 acoPoolTokenAmount);
	function depositWithGasToken(uint256 collateralAmount, uint256 minShares, address to, bool isLendingToken) external payable returns(uint256 acoPoolTokenAmount);
	function withdrawNoLocked(uint256 shares, uint256 minCollateral, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	);
	function withdrawNoLockedWithGasToken(uint256 shares, uint256 minCollateral, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
	);
    function withdrawWithLocked(uint256 shares, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	);
	function withdrawWithLockedWithGasToken(uint256 shares, address account, bool withdrawLendingToken) external returns (
		uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		address[] memory acos,
		uint256[] memory acosAmount
	);
    function swap(address acoToken, uint256 tokenAmount, uint256 restriction, address to, uint256 deadline) external;
    function swapWithGasToken(address acoToken, uint256 tokenAmount, uint256 restriction, address to, uint256 deadline) external;
    function redeemACOTokens() external;
	function redeemACOToken(address acoToken) external;
    function restoreCollateral() external;
    function lendCollateral() external;
}"},"IACOPoolFactory2.sol":{"content":"pragma solidity ^0.6.6;

interface IACOPoolFactory2 {
    function factoryAdmin() external view returns(address);
    function acoPoolImplementation() external view returns(address);
    function acoFactory() external view returns(address);
	function assetConverterHelper() external view returns(address);
    function chiToken() external view returns(address);
    function acoPoolFee() external view returns(uint256);
    function acoPoolFeeDestination() external view returns(address);
	function acoPoolUnderlyingPriceAdjustPercentage() external view returns(uint256);
	function acoPoolWithdrawOpenPositionPenalty() external view returns(uint256);
    function acoPoolMaximumOpenAco() external view returns(uint256);
    function poolAdminPermission(address account) external view returns(bool);
    function strategyPermitted(address strategy) external view returns(bool);
    function acoPoolBasicData(address acoPool) external view returns(address underlying, address strikeAsset, bool isCall);
}"},"IACOPoolStrategy.sol":{"content":"pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface IACOPoolStrategy {
    
    struct OptionQuote {
        uint256 underlyingPrice;
        address underlying;
        address strikeAsset;
        bool isCallOption;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 baseVolatility;
        uint256 collateralOrderAmount;
        uint256 collateralAvailable;
    }

    function quote(OptionQuote calldata quoteData) external view returns(uint256 optionPrice, uint256 volatility);
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
    function transferCollateralOwnership(address recipient, uint256 tokenCollateralizedAmount) external;
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
"},"ILendingPool.sol":{"content":"// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}


/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}


interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
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
"}}