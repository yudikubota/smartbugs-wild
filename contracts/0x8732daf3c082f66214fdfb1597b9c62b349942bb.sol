{"ACONameFormatter.sol":{"content":"pragma solidity ^0.6.6;

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
}"},"ACOToken.sol":{"content":"pragma solidity ^0.6.6;

import "./ERC20.sol";
import "./Address.sol";
import "./ACONameFormatter.sol";

/**
 * @title ACOToken
 * @dev The implementation of the ACO token.
 * The token is ERC20 compliant.
 */
contract ACOToken is ERC20 {
    using Address for address;
    
    /**
     * @dev Struct to store the accounts that generated tokens with a collateral deposit.
     */
    struct TokenCollateralized {
        /**
         * @dev Current amount of tokens.
         */
        uint256 amount;
        
        /**
         * @dev Index on the collateral owners array.
         */
        uint256 index;
    }
    
    /**
     * @dev Emitted when collateral is deposited on the contract.
     * @param account Address of the collateral owner.
     * @param amount Amount of collateral deposited.
     */
    event CollateralDeposit(address indexed account, uint256 amount);
    
    /**
     * @dev Emitted when collateral is withdrawn from the contract.
     * @param account Address of the account.
     * @param recipient Address of the collateral destination.
     * @param amount Amount of collateral withdrawn.
     * @param fee The fee amount charged on the withdrawal.
     */
    event CollateralWithdraw(address indexed account, address indexed recipient, uint256 amount, uint256 fee);
    
    /**
     * @dev Emitted when the collateral is used on an assignment.
     * @param from Address of the account of the collateral owner.
     * @param to Address of the account that exercises tokens to get the collateral.
     * @param paidAmount Amount paid to the collateral owner.
     * @param tokenAmount Amount of tokens used to exercise.
     */
    event Assigned(address indexed from, address indexed to, uint256 paidAmount, uint256 tokenAmount);

    /**
     * @dev The ERC20 token address for the underlying asset (0x0 for Ethereum). 
     */
    address public underlying;
    
    /**
     * @dev The ERC20 token address for the strike asset (0x0 for Ethereum). 
     */
    address public strikeAsset;
    
    /**
     * @dev Address of the fee destination charged on the exercise.
     */
    address payable public feeDestination;
    
    /**
     * @dev True if the type is CALL, false for PUT.
     */
    bool public isCall;
    
    /**
     * @dev The strike price for the token with the strike asset precision.
     */
    uint256 public strikePrice;
    
    /**
     * @dev The UNIX time for the token expiration.
     */
    uint256 public expiryTime;
    
    /**
     * @dev The total amount of collateral on the contract.
     */
    uint256 public totalCollateral;
    
    /**
     * @dev The fee value. It is a percentage value (100000 is 100%).
     */
    uint256 public acoFee;
    
    /**
     * @dev Symbol of the underlying asset.
     */
    string public underlyingSymbol;
    
    /**
     * @dev Symbol of the strike asset.
     */
    string public strikeAssetSymbol;
    
    /**
     * @dev Decimals for the underlying asset.
     */
    uint8 public underlyingDecimals;
    
    /**
     * @dev Decimals for the strike asset.
     */
    uint8 public strikeAssetDecimals;
    
    /**
     * @dev The maximum number of accounts that can be exercised by transaction.
     */
    uint256 public maxExercisedAccounts;
    
    /**
     * @dev Underlying precision. (10 ^ underlyingDecimals)
     */
    uint256 internal underlyingPrecision;
    
    /**
     * @dev Accounts that generated tokens with a collateral deposit.
     */
    mapping(address => TokenCollateralized) internal tokenData;
    
    /**
     * @dev Array with all accounts with collateral deposited.
     */
    address[] internal _collateralOwners;
    
    /**
     * @dev Internal data to control the reentrancy.
     */
    bool internal _notEntered;
    
    /**
     * @dev Selector for ERC20 transfer function.
     */
    bytes4 internal _transferSelector;
    
    /**
     * @dev Selector for ERC20 transfer from function.
     */
    bytes4 internal _transferFromSelector;
    
    /**
     * @dev Modifier to check if the token is not expired.
     * It is executed only while the token is not expired.
     */
    modifier notExpired() {
        require(_notExpired(), "ACOToken::Expired");
        _;
    }
    
    /**
     * @dev Modifier to prevent a contract from calling itself during the function execution.
     */
    modifier nonReentrant() {
        require(_notEntered, "ACOToken::Reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    /**
     * @dev Function to initialize the contract.
     * It should be called when creating the token.
     * It must be called only once. The first `require` is to guarantee that behavior.
     * @param _underlying Address of the underlying asset (0x0 for Ethereum).
     * @param _strikeAsset Address of the strike asset (0x0 for Ethereum).
     * @param _isCall True if the type is CALL, false for PUT.
     * @param _strikePrice The strike price with the strike asset precision.
     * @param _expiryTime The UNIX time for the token expiration.
     * @param _acoFee Value of the ACO fee. It is a percentage value (100000 is 100%).
     * @param _feeDestination Address of the fee destination charged on the exercise.
     * @param _maxExercisedAccounts The maximum number of accounts that can be exercised by transaction.
     */
    function init(
        address _underlying,
        address _strikeAsset,
        bool _isCall,
        uint256 _strikePrice,
        uint256 _expiryTime,
        uint256 _acoFee,
        address payable _feeDestination,
        uint256 _maxExercisedAccounts
    ) public {
        require(underlying == address(0) && strikeAsset == address(0) && strikePrice == 0, "ACOToken::init: Already initialized");
        
        require(_expiryTime > now, "ACOToken::init: Invalid expiry");
        require(_strikePrice > 0, "ACOToken::init: Invalid strike price");
        require(_underlying != _strikeAsset, "ACOToken::init: Same assets");
        require(_acoFee <= 500, "ACOToken::init: Invalid ACO fee"); // Maximum is 0.5%
        require(_isEther(_underlying) || _underlying.isContract(), "ACOToken::init: Invalid underlying");
        require(_isEther(_strikeAsset) || _strikeAsset.isContract(), "ACOToken::init: Invalid strike asset");
        require(_maxExercisedAccounts >= 25 && _maxExercisedAccounts <= 150, "ACOToken::init: Invalid number to max exercised accounts");
        
        underlying = _underlying;
        strikeAsset = _strikeAsset;
        isCall = _isCall;
        strikePrice = _strikePrice;
        expiryTime = _expiryTime;
        acoFee = _acoFee;
        feeDestination = _feeDestination;
        maxExercisedAccounts = _maxExercisedAccounts;
        underlyingDecimals = _getAssetDecimals(_underlying);
        require(underlyingDecimals < 78, "ACOToken::init: Invalid underlying decimals");
        strikeAssetDecimals = _getAssetDecimals(_strikeAsset);
        underlyingSymbol = _getAssetSymbol(_underlying);
        strikeAssetSymbol = _getAssetSymbol(_strikeAsset);
        underlyingPrecision = 10 ** uint256(underlyingDecimals);

        _transferSelector = bytes4(keccak256(bytes("transfer(address,uint256)")));
        _transferFromSelector = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        _notEntered = true;
    }
    
    /**
     * @dev Function to guarantee that the contract will not receive ether directly.
     */
    receive() external payable {
        revert();
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
     * @dev Function to get the token decimals, that it is equal to the underlying asset decimals.
     */
    function decimals() public view override returns(uint8) {
        return underlyingDecimals;
    }
    
    /**
     * @dev Function to get the current amount of collateral for an account.
     * @param account Address of the account.
     * @return The current amount of collateral.
     */
    function currentCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(currentCollateralizedTokens(account));
    }
    
    /**
     * @dev Function to get the current amount of unassignable collateral for an account.
     * After expiration, the unassignable collateral is equal to the account's collateral balance.
     * @param account Address of the account.
     * @return The respective amount of unassignable collateral.
     */
    function unassignableCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(unassignableTokens(account));
    }
    
    /**
     * @dev Function to get  the current amount of assignable collateral for an account.
     * After expiration, the assignable collateral is zero.
     * @param account Address of the account.
     * @return The respective amount of assignable collateral.
     */
    function assignableCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(assignableTokens(account));
    }
    
    /**
     * @dev Function to get the current amount of collateralized tokens for an account.
     * @param account Address of the account.
     * @return The current amount of collateralized tokens.
     */
    function currentCollateralizedTokens(address account) public view returns(uint256) {
        return tokenData[account].amount;
    }
    
    /**
     * @dev Function to get the current amount of unassignable tokens for an account.
     * After expiration, the unassignable tokens is equal to the account's collateralized tokens.
     * @param account Address of the account.
     * @return The respective amount of unassignable tokens.
     */
    function unassignableTokens(address account) public view returns(uint256) {
        if (balanceOf(account) > tokenData[account].amount || !_notExpired()) {
            return tokenData[account].amount;
        } else {
            return balanceOf(account);
        }
    }
    
    /**
     * @dev Function to get  the current amount of assignable tokens for an account.
     * After expiration, the assignable tokens is zero.
     * @param account Address of the account.
     * @return The respective amount of assignable tokens.
     */
    function assignableTokens(address account) public view returns(uint256) {
        if (_notExpired()) {
            return _getAssignableAmount(account);
        } else {
            return 0;
        }
    }
    
    /**
     * @dev Function to get the equivalent collateral amount for a token amount.
     * @param tokenAmount Amount of tokens.
     * @return The respective amount of collateral.
     */
    function getCollateralAmount(uint256 tokenAmount) public view returns(uint256) {
        if (isCall) {
            return tokenAmount;
        } else if (tokenAmount > 0) {
            return _getTokenStrikePriceRelation(tokenAmount);
        } else {
            return 0;
        }
    }
    
    /**
     * @dev Function to get the equivalent token amount for a collateral amount.
     * @param collateralAmount Amount of collateral.
     * @return The respective amount of tokens.
     */
    function getTokenAmount(uint256 collateralAmount) public view returns(uint256) {
        if (isCall) {
            return collateralAmount;
        } else if (collateralAmount > 0) {
            return collateralAmount.mul(underlyingPrecision).div(strikePrice);
        } else {
            return 0;
        }
    }

    /**
     * @dev Function to get the number of addresses that have collateral deposited.
     * @return The number of addresses.
     */
    function numberOfAccountsWithCollateral() public view returns(uint256) {
        return _collateralOwners.length;
    }
    
    /**
     * @dev Function to get the base data for exercise of an amount of token.
     * To call the exercise the value returned must be added by the number of accounts that could be exercised:
     * - using the Â´exerciseÂ´ or Â´exerciseFromÂ´ functions it will be equal to `maxExercisedAccounts`.
     * - using the Â´exerciseAccountsÂ´ or `exerciseAccountsFrom` functions it will be equal to the number of accounts sent as function argument.
     * @param tokenAmount Amount of tokens.
     * @return The asset and the respective base amount that should be sent to get the collateral.
     */
    function getBaseExerciseData(uint256 tokenAmount) public view returns(address, uint256) {
        if (isCall) {
            return (strikeAsset, _getTokenStrikePriceRelation(tokenAmount)); 
        } else {
            return (underlying, tokenAmount);
        }
    }
    
    /**
     * @dev Function to get the collateral to be received on an exercise and the respective fee.
     * @param tokenAmount Amount of tokens.
     * @return The collateral to be received and the respective fee.
     */
    function getCollateralOnExercise(uint256 tokenAmount) public view returns(uint256, uint256) {
        uint256 collateralAmount = getCollateralAmount(tokenAmount);
        uint256 fee = collateralAmount.mul(acoFee).div(100000);
        collateralAmount = collateralAmount.sub(fee);
        return (collateralAmount, fee);
    }
    
    /**
     * @dev Function to get the collateral asset.
     * @return The address of the collateral asset.
     */
    function collateral() public view returns(address) {
        if (isCall) {
            return underlying;
        } else {
            return strikeAsset;
        }
    }
    
    /**
     * @dev Function to mint tokens with Ether deposited as collateral.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @return The amount of tokens minted.
     */
    function mintPayable() external payable returns(uint256) {
        require(_isEther(collateral()), "ACOToken::mintPayable: Invalid call");
        return _mintToken(msg.sender, msg.value);
    }
    
    /**
     * @dev Function to mint tokens with Ether deposited as collateral to an informed account.
     * However, the minted tokens are assigned to the transaction sender.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @param account Address of the account that will be the collateral owner.
     * @return The amount of tokens minted.
     */
    function mintToPayable(address account) external payable returns(uint256) {
        require(_isEther(collateral()), "ACOToken::mintToPayable: Invalid call");
       return _mintToken(account, msg.value);
    }
    
    /**
     * @dev Function to mint tokens with ERC20 deposited as collateral.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @param collateralAmount Amount of collateral deposited.
     * @return The amount of tokens minted.
     */
    function mint(uint256 collateralAmount) external returns(uint256) {
        address _collateral = collateral();
        require(!_isEther(_collateral), "ACOToken::mint: Invalid call");
        
        _transferFromERC20(_collateral, msg.sender, address(this), collateralAmount);
        return _mintToken(msg.sender, collateralAmount);
    }
    
    /**
     * @dev Function to mint tokens with ERC20 deposited as collateral to an informed account.
     * However, the minted tokens are assigned to the transaction sender.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @param account Address of the account that will be the collateral owner.
     * @param collateralAmount Amount of collateral deposited.
     * @return The amount of tokens minted.
     */
    function mintTo(address account, uint256 collateralAmount) external returns(uint256) {
        address _collateral = collateral();
        require(!_isEther(_collateral), "ACOToken::mintTo: Invalid call");
        
        _transferFromERC20(_collateral, msg.sender, address(this), collateralAmount);
        return _mintToken(account, collateralAmount);
    }
    
    /**
     * @dev Function to burn tokens and get the collateral, not assigned, back.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @param tokenAmount Amount of tokens to be burned.
     * @return The amount of collateral transferred.
     */
    function burn(uint256 tokenAmount) external returns(uint256) {
        return _burn(msg.sender, tokenAmount);
    }
    
    /**
     * @dev Function to burn tokens from a specific account and send the collateral to its address.
     * The token allowance must be respected.
     * The collateral is sent to the transaction sender.
     * NOTE: The function only works when the token is NOT expired yet. 
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens to be burned.
     * @return The amount of collateral transferred.
     */
    function burnFrom(address account, uint256 tokenAmount) external returns(uint256) {
        return _burn(account, tokenAmount);
    }
    
    /**
     * @dev Function to get the collateral, not assigned, back.
     * NOTE: The function only works when the token IS expired. 
     * @return The amount of collateral transferred.
     */
    function redeem() external returns(uint256) {
        return _redeem(msg.sender);
    }
    
    /**
     * @dev Function to get the collateral from a specific account sent back to its address .
     * The token allowance must be respected.
     * The collateral is sent to the transaction sender.
     * NOTE: The function only works when the token IS expired. 
     * @param account Address of the account.
     * @return The amount of collateral transferred.
     */
    function redeemFrom(address account) external returns(uint256) {
        require(tokenData[account].amount <= allowance(account, msg.sender), "ACOToken::redeemFrom: Allowance too low");
        return _redeem(account);
    }
    
    /**
     * @dev Function to exercise the tokens, paying to get the equivalent collateral.
     * The paid amount is sent to the collateral owners that were assigned.
     * NOTE: The function only works when the token is NOT expired. 
     * @param tokenAmount Amount of tokens.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised.
     * @return The amount of collateral transferred.
     */
    function exercise(uint256 tokenAmount, uint256 salt) external payable returns(uint256) {
        return _exercise(msg.sender, tokenAmount, salt);
    }
    
    /**
     * @dev Function to exercise the tokens from an account, paying to get the equivalent collateral.
     * The token allowance must be respected.
     * The paid amount is sent to the collateral owners that were assigned.
     * The collateral is transferred to the transaction sender.
     * NOTE: The function only works when the token is NOT expired. 
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised.
     * @return The amount of collateral transferred.
     */
    function exerciseFrom(address account, uint256 tokenAmount, uint256 salt) external payable returns(uint256) {
        return _exercise(account, tokenAmount, salt);
    }
    
    /**
     * @dev Function to exercise the tokens, paying to get the equivalent collateral.
     * The paid amount is sent to the collateral owners (on accounts list) that were assigned.
     * NOTE: The function only works when the token is NOT expired. 
     * @param tokenAmount Amount of tokens.
     * @param accounts The array of addresses to get collateral from.
     * @return The amount of collateral transferred.
     */
    function exerciseAccounts(uint256 tokenAmount, address[] calldata accounts) external payable returns(uint256) {
        return _exerciseFromAccounts(msg.sender, tokenAmount, accounts);
    }
    
    /**
     * @dev Function to exercise the tokens from a specific account, paying to get the equivalent collateral sent to its address.
     * The token allowance must be respected.
     * The paid amount is sent to the collateral owners (on accounts list) that were assigned.
     * The collateral is transferred to the transaction sender.
     * NOTE: The function only works when the token is NOT expired. 
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens.
     * @param accounts The array of addresses to get the deposited collateral.
     * @return The amount of collateral transferred.
     */
    function exerciseAccountsFrom(address account, uint256 tokenAmount, address[] calldata accounts) external payable returns(uint256) {
        return _exerciseFromAccounts(account, tokenAmount, accounts);
    }
    
    /**
     * @dev Internal function to redeem respective collateral from an account.
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens.
     * @return The amount of collateral transferred.
     */
    function _redeemCollateral(address account, uint256 tokenAmount) internal returns(uint256) {
        require(_accountHasCollateral(account), "ACOToken::_redeemCollateral: No collateral available");
        require(tokenAmount > 0, "ACOToken::_redeemCollateral: Invalid token amount");
        
        TokenCollateralized storage data = tokenData[account];
        data.amount = data.amount.sub(tokenAmount);
        
        _removeCollateralDataIfNecessary(account);
        
        return _transferCollateral(account, getCollateralAmount(tokenAmount), 0);
    }
    
    /**
     * @dev Internal function to mint tokens.
     * The tokens are minted for the transaction sender.
     * @param account Address of the account.
     * @param collateralAmount Amount of collateral deposited.
     * @return The amount of tokens minted.
     */
    function _mintToken(address account, uint256 collateralAmount) nonReentrant notExpired internal returns(uint256) {
        require(collateralAmount > 0, "ACOToken::_mintToken: Invalid collateral amount");
        
        if (!_accountHasCollateral(account)) {
            tokenData[account].index = _collateralOwners.length;
            _collateralOwners.push(account);
        }
        
        uint256 tokenAmount = getTokenAmount(collateralAmount);
        require(tokenAmount != 0, "ACOToken::_mintToken: Invalid token amount");
        tokenData[account].amount = tokenData[account].amount.add(tokenAmount);
        
        totalCollateral = totalCollateral.add(collateralAmount);
        
        emit CollateralDeposit(account, collateralAmount);
        
        super._mintAction(msg.sender, tokenAmount);
        return tokenAmount;
    }
    
    /**
     * @dev Internal function to transfer collateral. 
     * When there is a fee, the calculated fee is also transferred to the destination fee address.
     * The collateral destination is always the transaction sender address.
     * @param account Address of the account.
     * @param collateralAmount Amount of collateral to be transferred.
     * @param fee Amount of fee charged.
     * @return The amount of collateral transferred.
     */
    function _transferCollateral(address account, uint256 collateralAmount, uint256 fee) internal returns(uint256) {
        
        totalCollateral = totalCollateral.sub(collateralAmount.add(fee));
        
        address _collateral = collateral();
        if (_isEther(_collateral)) {
            payable(msg.sender).transfer(collateralAmount);
            if (fee > 0) {
                feeDestination.transfer(fee);   
            }
        } else {
            _transferERC20(_collateral, msg.sender, collateralAmount);
            if (fee > 0) {
                _transferERC20(_collateral, feeDestination, fee);
            }
        }
        
        emit CollateralWithdraw(account, msg.sender, collateralAmount, fee);
        return collateralAmount;
    }
    
    /**
     * @dev Internal function to exercise the tokens from an account. 
     * @param account Address of the account that is exercising.
     * @param tokenAmount Amount of tokens.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised.
     * @return The amount of collateral transferred.
     */
    function _exercise(address account, uint256 tokenAmount, uint256 salt) nonReentrant internal returns(uint256) {
        _validateAndBurn(account, tokenAmount, maxExercisedAccounts);
         _exerciseOwners(account, tokenAmount, salt);
        (uint256 collateralAmount, uint256 fee) = getCollateralOnExercise(tokenAmount);
        return _transferCollateral(account, collateralAmount, fee);
    }
    
    /**
     * @dev Internal function to exercise the tokens from an account. 
     * @param account Address of the account that is exercising.
     * @param tokenAmount Amount of tokens.
     * @param accounts The array of addresses to get the collateral from.
     * @return The amount of collateral transferred.
     */
    function _exerciseFromAccounts(address account, uint256 tokenAmount, address[] memory accounts) nonReentrant internal returns(uint256) {
        _validateAndBurn(account, tokenAmount, accounts.length);
        _exerciseAccounts(account, tokenAmount, accounts);
        (uint256 collateralAmount, uint256 fee) = getCollateralOnExercise(tokenAmount);
        return _transferCollateral(account, collateralAmount, fee);
    }
    
    /**
     * @dev Internal function to exercise the assignable tokens from the stored list of collateral owners. 
     * @param exerciseAccount Address of the account that is exercising.
     * @param tokenAmount Amount of tokens.
     * @param salt Random number to calculate the start index of the array of accounts to be exercised.
     */
    function _exerciseOwners(address exerciseAccount, uint256 tokenAmount, uint256 salt) internal {
        uint256 accountsExercised = 0;
        uint256 start = salt.mod(_collateralOwners.length);
        uint256 index = start;
        uint256 count = 0;
        while (tokenAmount > 0 && count < _collateralOwners.length) {
            
            uint256 remainingAmount = _exerciseAccount(_collateralOwners[index], tokenAmount, exerciseAccount);
            if (remainingAmount < tokenAmount) {
                accountsExercised++;
                require(accountsExercised < maxExercisedAccounts || remainingAmount == 0, "ACOToken::_exerciseOwners: Too many accounts to exercise");
            }
            tokenAmount = remainingAmount;
            
            ++index;
            if (index == _collateralOwners.length) {
                index = 0;
            }
            ++count;
        }
        require(tokenAmount == 0, "ACOToken::_exerciseOwners: Invalid remaining amount");
        
        uint256 indexOnModifyIteration;
        bool shouldModifyIteration = false;
        if (index == 0) {
            index = _collateralOwners.length;
        } else if (index <= start) {
            indexOnModifyIteration = index - 1;
            shouldModifyIteration = true;
            index = _collateralOwners.length;
        }
            
        for (uint256 i = 0; i < count; ++i) {
            --index;
            if (shouldModifyIteration && index < start) {
                index = indexOnModifyIteration;
                shouldModifyIteration = false;
            }
            _removeCollateralDataIfNecessary(_collateralOwners[index]);
        }
    }
    
    /**
     * @dev Internal function to exercise the assignable tokens from an accounts list. 
     * @param exerciseAccount Address of the account that is exercising.
     * @param tokenAmount Amount of tokens.
     * @param accounts The array of addresses to get the collateral from.
     */
    function _exerciseAccounts(address exerciseAccount, uint256 tokenAmount, address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; ++i) {
            if (tokenAmount == 0) {
                break;
            }
            tokenAmount = _exerciseAccount(accounts[i], tokenAmount, exerciseAccount);
            _removeCollateralDataIfNecessary(accounts[i]);
        }
        require(tokenAmount == 0, "ACOToken::_exerciseAccounts: Invalid remaining amount");
    }
    
    /**
     * @dev Internal function to exercise the assignable tokens from an account and transfer to its address the respective payment. 
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens.
     * @param exerciseAccount Address of the account that is exercising.
     * @return Remaining amount of tokens.
     */
    function _exerciseAccount(address account, uint256 tokenAmount, address exerciseAccount) internal returns(uint256) {
        uint256 available = _getAssignableAmount(account);
        if (available > 0) {
            
            TokenCollateralized storage data = tokenData[account];
            uint256 valueToTransfer;
            if (available < tokenAmount) {
                valueToTransfer = available;
                tokenAmount = tokenAmount.sub(available);
            } else {
                valueToTransfer = tokenAmount;
                tokenAmount = 0;
            }
            
            (address exerciseAsset, uint256 amount) = getBaseExerciseData(valueToTransfer);
            // To guarantee that the minter will be paid.
            amount = amount.add(1);
            
            data.amount = data.amount.sub(valueToTransfer); 
            
            if (_isEther(exerciseAsset)) {
                payable(account).transfer(amount);
            } else {
                _transferERC20(exerciseAsset, account, amount);
            }
            emit Assigned(account, exerciseAccount, amount, valueToTransfer);
        }
        return tokenAmount;
    }
    
    /**
     * @dev Internal function to validate the exercise operation and burn the respective tokens.
     * @param account Address of the account that is exercising.
     * @param tokenAmount Amount of tokens.
     * @param maximumNumberOfAccounts The maximum number of accounts that can be exercised.
     */
    function _validateAndBurn(address account, uint256 tokenAmount, uint256 maximumNumberOfAccounts) notExpired internal {
        require(tokenAmount > 0, "ACOToken::_validateAndBurn: Invalid token amount");
        
        // Whether an account has deposited collateral it only can exercise the extra amount of unassignable tokens.
        if (_accountHasCollateral(account)) {
            require(tokenAmount <= balanceOf(account).sub(tokenData[account].amount), "ACOToken::_validateAndBurn: Token amount not available"); 
        }
        
        _callBurn(account, tokenAmount);
        
        (address exerciseAsset, uint256 expectedAmount) = getBaseExerciseData(tokenAmount);
        expectedAmount = expectedAmount.add(maximumNumberOfAccounts);

        if (_isEther(exerciseAsset)) {
            require(msg.value == expectedAmount, "ACOToken::_validateAndBurn: Invalid ether amount");
        } else {
            require(msg.value == 0, "ACOToken::_validateAndBurn: No ether expected");
            _transferFromERC20(exerciseAsset, msg.sender, address(this), expectedAmount);
        }
    }
    
    /**
     * @dev Internal function to calculate the token strike price relation.
     * @param tokenAmount Amount of tokens.
     * @return Calculated value with strike asset precision.
     */
    function _getTokenStrikePriceRelation(uint256 tokenAmount) internal view returns(uint256) {
        return tokenAmount.mul(strikePrice).div(underlyingPrecision);
    }
    
    /**
     * @dev Internal function to get the collateral sent back from an account.
     * Function to be called when the token IS expired.
     * @param account Address of the account.
     * @return The amount of collateral transferred.
     */
    function _redeem(address account) nonReentrant internal returns(uint256) {
        require(!_notExpired(), "ACOToken::_redeem: Token not expired yet");
        
        uint256 collateralAmount = _redeemCollateral(account, tokenData[account].amount);
        super._burnAction(account, balanceOf(account));
        return collateralAmount;
    }
    
    /**
     * @dev Internal function to burn tokens from an account and get the collateral, not assigned, back.
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens to be burned.
     * @return The amount of collateral transferred.
     */
    function _burn(address account, uint256 tokenAmount) nonReentrant notExpired internal returns(uint256) {
        uint256 collateralAmount = _redeemCollateral(account, tokenAmount);
        _callBurn(account, tokenAmount);
        return collateralAmount;
    }
    
    /**
     * @dev Internal function to burn tokens.
     * @param account Address of the account.
     * @param tokenAmount Amount of tokens to be burned.
     */
    function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }
    
    /**
     * @dev Internal function to get the amount of assignable token from an account.
     * @param account Address of the account.
     * @return The assignable amount of tokens.
     */
    function _getAssignableAmount(address account) internal view returns(uint256) {
        if (tokenData[account].amount > balanceOf(account)) {
            return tokenData[account].amount.sub(balanceOf(account));
        } else {
            return 0;
        }
    }
    
    /**
     * @dev Internal function to remove the token data with collateral if its total amount was assigned.
     * @param account Address of account.
     */
    function _removeCollateralDataIfNecessary(address account) internal {
        TokenCollateralized storage data = tokenData[account];
        if (!_hasCollateral(data)) {
            uint256 lastIndex = _collateralOwners.length - 1;
            if (lastIndex != data.index) {
                address last = _collateralOwners[lastIndex];
                tokenData[last].index = data.index;
                _collateralOwners[data.index] = last;
            }
            _collateralOwners.pop();
            delete tokenData[account];
        }
    }
    
    /**
     * @dev Internal function to get if the token is not expired.
     * @return Whether the token is NOT expired.
     */
    function _notExpired() internal view returns(bool) {
        return now < expiryTime;
    }
    
    /**
     * @dev Internal function to get if an account has collateral deposited.
     * @param account Address of the account.
     * @return Whether the account has collateral deposited.
     */
    function _accountHasCollateral(address account) internal view returns(bool) {
        return _hasCollateral(tokenData[account]);
    }
    
    /**
     * @dev Internal function to get if an account has collateral deposited.
     * @param data Token data from an account.
     * @return Whether the account has collateral deposited.
     */    
    function _hasCollateral(TokenCollateralized storage data) internal view returns(bool) {
        return data.amount > 0;
    }
    
    /**
     * @dev Internal function to get if the address is for Ethereum (0x0).
     * @param _address Address to be checked.
     * @return Whether the address is for Ethereum.
     */ 
    function _isEther(address _address) internal pure returns(bool) {
        return _address == address(0);
    } 
    
    /**
     * @dev Internal function to get the token name.
     * The token name is assembled  with the token data:
     * ACO UNDERLYING_SYMBOL-STRIKE_PRICE_STRIKE_ASSET_SYMBOL-TYPE-EXPIRYTIME
     * @return The token name.
     */
    function _name() internal view returns(string memory) {
        return string(abi.encodePacked(
            "ACO ",
            underlyingSymbol,
            "-",
            ACONameFormatter.formatNumber(strikePrice, strikeAssetDecimals),
            strikeAssetSymbol,
            "-",
            ACONameFormatter.formatType(isCall),
            "-",
            ACONameFormatter.formatTime(expiryTime)
        ));
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
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSignature("decimals()"));
            require(success, "ACOToken::_getAssetDecimals: Invalid asset decimals");
            return abi.decode(returndata, (uint8));
        }
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
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSignature("symbol()"));
            require(success, "ACOToken::_getAssetSymbol: Invalid asset symbol");
            return abi.decode(returndata, (string));
        }
    }
    
    /**
     * @dev Internal function to transfer ERC20 tokens.
     * @param token Address of the token.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
     function _transferERC20(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_transferSelector, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOToken::_transferERC20");
    }
    
    /**
     * @dev Internal function to call transferFrom on ERC20 tokens.
     * @param token Address of the token.
     * @param sender Address of the sender.
     * @param recipient Address of the transfer destination.
     * @param amount Amount to transfer.
     */
     function _transferFromERC20(address token, address sender, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_transferFromSelector, sender, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOToken::_transferFromERC20");
    }
}
"},"Address.sol":{"content":"pragma solidity ^0.6.6;

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
"},"IERC20.sol":{"content":"pragma solidity ^0.6.6;

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
"},"SafeMath.sol":{"content":"pragma solidity ^0.6.6;

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