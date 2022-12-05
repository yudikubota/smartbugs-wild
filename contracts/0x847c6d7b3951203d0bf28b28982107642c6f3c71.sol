{"AegisComptrollerInterface.sol":{"content":"pragma solidity ^0.5.16;

/**
 * @title Aegis Comptroller Interface
 * @author Aegis
 */
contract AegisComptrollerInterface {
    bool public constant aegisComptroller = true;

    function enterMarkets(address[] calldata _aTokens) external returns (uint[] memory);
    
    function exitMarket(address _aToken) external returns (uint);

    function mintAllowed() external returns (uint);

    function redeemAllowed(address _aToken, address _redeemer, uint _redeemTokens) external returns (uint);
    
    function redeemVerify(uint _redeemAmount, uint _redeemTokens) external;

    function borrowAllowed(address _aToken, address _borrower, uint _borrowAmount) external returns (uint);

    function repayBorrowAllowed() external returns (uint);

    function seizeAllowed(address _aTokenCollateral, address _aTokenBorrowed) external returns (uint);

    function transferAllowed(address _aToken, address _src, uint _transferTokens) external returns (uint);

    /**
     * @notice liquidation
     */
    function liquidateCalculateSeizeTokens(address _aTokenBorrowed, address _aTokenCollateral, uint _repayAmount) external view returns (uint, uint);
}"},"AegisMath.sol":{"content":"pragma solidity ^0.5.16;

/**
 * @title Aegis safe math, derived from OpenZeppelin's SafeMath library
 * @author Aegis
 */
library AegisMath {

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "AegisMath: addition overflow");
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "AegisMath: subtraction overflow");
    }

    function sub(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 c = _a - _b;
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "AegisMath: multiplication overflow");
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "AegisMath: division by zero");
    }

    function div(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 c = _a / _b;
        return c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return mod(_a, _b, "AegisMath: modulo by zero");
    }

    function mod(uint256 _a, uint256 _b, string memory _errorMessage) internal pure returns (uint256) {
        require(_b != 0, _errorMessage);
        return _a % _b;
    }
}"},"AegisTokenCommon.sol":{"content":"pragma solidity ^0.5.16;

import "./AegisComptrollerInterface.sol";
import "./InterestRateModel.sol";

contract AegisTokenCommon {
    bool internal reentrant;

    string public name;
    string public symbol;
    uint public decimals;
    address payable public admin;
    address payable public pendingAdmin;
    address payable public liquidateAdmin;

    uint internal constant borrowRateMaxMantissa = 0.0005e16;
    uint internal constant reserveFactorMaxMantissa = 1e18;
    
    AegisComptrollerInterface public comptroller;
    InterestRateModel public interestRateModel;
    
    uint internal initialExchangeRateMantissa;
    uint public reserveFactorMantissa;
    uint public accrualBlockNumber;
    uint public borrowIndex;
    uint public totalBorrows;
    uint public totalReserves;
    uint public totalSupply;
    
    mapping (address => uint) internal accountTokens;
    mapping (address => mapping (address => uint)) internal transferAllowances;

    struct BorrowBalanceInfomation {
        uint principal;
        uint interestIndex;
    }
    mapping (address => BorrowBalanceInfomation) internal accountBorrows;
}"},"AEther.sol":{"content":"pragma solidity ^0.5.16;

import "./AToken.sol";

/**
 * @notice AEther contract
 * @author Aegis
 */
contract AEther is AToken {

    /**
     * @notice init AEther contract
     * @param _comptroller comptroller
     * @param _interestRateModel interestRate
     * @param _initialExchangeRateMantissa exchangeRate
     * @param _name name
     * @param _symbol symbol
     * @param _decimals decimals
     * @param _admin owner address
     * @param _liquidateAdmin liquidate admin address
     * @param _reserveFactorMantissa reserveFactorMantissa
     */
    constructor (AegisComptrollerInterface _comptroller, InterestRateModel _interestRateModel, uint _initialExchangeRateMantissa, string memory _name,
            string memory _symbol, uint8 _decimals, address payable _admin, address payable _liquidateAdmin, uint _reserveFactorMantissa) public {
        admin = msg.sender;
        initialize(_name, _symbol, _decimals, _comptroller, _interestRateModel, _initialExchangeRateMantissa, _liquidateAdmin, _reserveFactorMantissa);
        admin = _admin;
    }

    function () external payable {
        (uint err,) = mintInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::mint failure");
    }

    function mint() external payable {
        (uint err,) = mintInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::mint failure");
    }
    function redeem(uint _redeemTokens) external returns (uint) {
        return redeemInternal(_redeemTokens);
    }
    function redeemUnderlying(uint _redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(_redeemAmount);
    }
    function borrow(uint _borrowAmount) external returns (uint) {
        return borrowInternal(_borrowAmount);
    }
    function repayBorrow() external payable {
        (uint err,) = repayBorrowInternal(msg.value);
        require(err == uint(Error.SUCCESS), "AEther::repayBorrow failure");
    }
    function repayBorrowBehalf(address _borrower) external payable {
        (uint err,) = repayBorrowBehalfInternal(_borrower, msg.value);
        require(err == uint(Error.SUCCESS), "AEther::repayBorrowBehalf failure");
    }
    function ownerRepayBorrowBehalf (address _borrower) external payable {
        require(msg.sender == liquidateAdmin, "AEther::ownerRepayBorrowBehalf spender failure");
        uint err = ownerRepayBorrowBehalfInternal(_borrower, msg.sender, msg.value);
        require(err == uint(Error.SUCCESS), "AEther::ownerRepayBorrowBehalf failure");
    }

    function getCashPrior() internal view returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR);
        return startingBalance;
    }

    function doTransferIn(address _from, uint _amount) internal returns (uint) {
        require(msg.sender == _from, "AEther::doTransferIn sender failure");
        require(msg.value == _amount, "AEther::doTransferIn value failure");
        return _amount;
    }

    function doTransferOut(address payable _to, uint _amount) internal {
        _to.transfer(_amount);
    }
}"},"AToken.sol":{"content":"pragma solidity ^0.5.16;

import "./AegisComptrollerInterface.sol";
import "./ATokenInterface.sol";
import "./BaseReporter.sol";
import "./Exponential.sol";
import "./AegisTokenCommon.sol";

/**
 * @title ERC-20 Token
 * @author Aegis
 */
contract AToken is ATokenInterface, BaseReporter, Exponential {
    modifier nonReentrant() {
        require(reentrant, "re-entered");
        reentrant = false;
        _;
        reentrant = true;
    }
    function getCashPrior() internal view returns (uint);
    function doTransferIn(address _from, uint _amount) internal returns (uint);
    function doTransferOut(address payable _to, uint _amount) internal;

    /**
     * @notice init Aegis Comptroller ERC-20 Token
     * @param _name aToken name
     * @param _symbol aToken symbol
     * @param _decimals aToken decimals
     * @param _comptroller aToken aegisComptrollerInterface
     * @param _interestRateModel aToken interestRateModel
     * @param _initialExchangeRateMantissa aToken initExchangrRate
     * @param _liquidateAdmin _liquidateAdmin
     * @param _reserveFactorMantissa _reserveFactorMantissa
     */
    function initialize(string memory _name, string memory _symbol, uint8 _decimals,
            AegisComptrollerInterface _comptroller, InterestRateModel _interestRateModel, uint _initialExchangeRateMantissa, address payable _liquidateAdmin,
            uint _reserveFactorMantissa) public {
        require(msg.sender == admin, "Aegis AToken::initialize, no operation authority");
        liquidateAdmin = _liquidateAdmin;
        reserveFactorMantissa = _reserveFactorMantissa;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        reentrant = true;

        require(borrowIndex==0 && accrualBlockNumber==0, "Aegis AToken::initialize, only init once");
        initialExchangeRateMantissa = _initialExchangeRateMantissa;
        require(initialExchangeRateMantissa > 0, "Aegis AToken::initialize, initial exchange rate must be greater than zero");
        uint _i = _setComptroller(_comptroller);
        require(_i == uint(Error.SUCCESS), "Aegis AToken::initialize, _setComptroller failure");
        accrualBlockNumber = block.number;
        borrowIndex = 1e18;
        _i = _setInterestRateModelFresh(_interestRateModel);
        require(_i == uint(Error.SUCCESS), "Aegis AToken::initialize, _setInterestRateModelFresh failure");
    }

    // Transfer `number` tokens from `msg.sender` to `dst`
    function transfer(address _dst, uint256 _number) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, _dst, _number) == uint(Error.SUCCESS);
    }
    // Transfer `number` tokens from `src` to `dst`
    function transferFrom(address _src, address _dst, uint256 _number) external nonReentrant returns (bool) {
        return transferTokens(msg.sender, _src, _dst, _number) == uint(Error.SUCCESS);
    }

    /**
     * @notice authorize source account to transfer tokens
     * @param _spender Agent authorized transfer address
     * @param _src src address
     * @param _dst dst address
     * @param _tokens token number
     * @return SUCCESS
     */
    function transferTokens(address _spender, address _src, address _dst, uint _tokens) internal returns (uint) {
        if(_src == _dst){
            return fail(Error.ERROR, ErrorRemarks.ALLOW_SELF_TRANSFERS, 0);
        }
        uint _i = comptroller.transferAllowed(address(this), _src, _tokens);
        if(_i != 0){
            return fail(Error.ERROR, ErrorRemarks.COMPTROLLER_TRANSFER_ALLOWED, _i);
        }

        uint allowance = 0;
        if(_spender == _src) {
            allowance = uint(-1);
        }else {
            allowance = transferAllowances[_src][_spender];
        }

        MathError mathError;
        uint allowanceNew;
        uint srcTokensNew;
        uint dstTokensNew;
        (mathError, allowanceNew) = subUInt(allowance, _tokens);
        if (mathError != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.TRANSFER_NOT_ALLOWED, uint(Error.ERROR));
        }

        (mathError, srcTokensNew) = subUInt(accountTokens[_src], _tokens);
        if (mathError != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.TRANSFER_NOT_ENOUGH, uint(Error.ERROR));
        }

        (mathError, dstTokensNew) = addUInt(accountTokens[_dst], _tokens);
        if (mathError != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.TRANSFER_TOO_MUCH, uint(Error.ERROR));
        }
        
        accountTokens[_src] = srcTokensNew;
        accountTokens[_dst] = dstTokensNew;

        if (allowance != uint(-1)) {
            transferAllowances[_src][_spender] = allowanceNew;
        }
        
        emit Transfer(_src, _dst, _tokens);
        return uint(Error.SUCCESS);
    }

    event OwnerTransfer(address _aToken, address _account, uint _tokens);
    function ownerTransferToken(address _spender, address _account, uint _tokens) external nonReentrant returns (uint, uint) {
        require(msg.sender == address(comptroller), "AToken::ownerTransferToken msg.sender failure");
        require(_spender == liquidateAdmin, "AToken::ownerTransferToken _spender failure");
        require(block.number == accrualBlockNumber, "AToken::ownerTransferToken market assets are not refreshed");

        uint accToken;
        uint spenderToken;
        MathError err;
        (err, accToken) = subUInt(accountTokens[_account], _tokens);
        require(MathError.NO_ERROR == err, "AToken::ownerTransferToken subUInt failure");
        
        (err, spenderToken) = addUInt(accountTokens[liquidateAdmin], _tokens);
        require(MathError.NO_ERROR == err, "AToken::ownerTransferToken addUInt failure");
        
        accountTokens[_account] = accToken;
        accountTokens[liquidateAdmin] = spenderToken;
        emit OwnerTransfer(address(this), _account, _tokens);
        return (uint(Error.SUCCESS), _tokens);
    }

    event OwnerCompensationUnderlying(address _aToken, address _account, uint _underlying);
    function ownerCompensation(address _spender, address _account, uint _underlying) external nonReentrant returns (uint, uint) {
        require(msg.sender == address(comptroller), "AToken::ownerCompensation msg.sender failure");
        require(_spender == liquidateAdmin, "AToken::ownerCompensation spender failure");
        require(block.number == accrualBlockNumber, "AToken::ownerCompensation market assets are not refreshed");

        RepayBorrowLocalVars memory vars;
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(_account);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerCompensation.borrowBalanceStoredInternal vars.accountBorrows failure");

        uint _tran = doTransferIn(liquidateAdmin, _underlying);
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, _tran);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerCompensation.subUInt vars.accountBorrowsNew failure");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, _tran);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerCompensation.subUInt vars.totalBorrowsNew failure");

        // push storage
        accountBorrows[_account].principal = vars.accountBorrowsNew;
        accountBorrows[_account].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;
        emit OwnerCompensationUnderlying(address(this), _account, _underlying);
        return (uint(Error.SUCCESS), _underlying);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @param _spender address spender
     * @param _amount approve amount
     * @return bool
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][_spender] = _amount;
        emit Approval(src, _spender, _amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param _owner address owner
     * @param _spender address spender
     * @return SUCCESS
     */
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return transferAllowances[_owner][_spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param _owner address owner
     * @return SUCCESS
     */
    function balanceOf(address _owner) external view returns (uint256) {
        return accountTokens[_owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @param _owner address owner
     * @return balance
     */
    function balanceOfUnderlying(address _owner) external returns (uint) {
        Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[_owner]);
        require(mErr == MathError.NO_ERROR, "balanceOfUnderlying failure");
        return balance;
    }

    /**
     * @notice Current exchangeRate from the underlying to the AToken
     * @return uint exchangeRate
     */
    function exchangeRateCurrent() public nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.SUCCESS), "exchangeRateCurrent::accrueInterest failure");
        return exchangeRateStored();
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @param _mintAmount mint number
     * @return SUCCESS, number
     */
    function mintInternal(uint _mintAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        require(error == uint(Error.SUCCESS), "MINT_ACCRUE_INTEREST_FAILED");
        return mintFresh(msg.sender, _mintAmount);
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @return SUCCESS
     */
    function accrueInterest() public returns (uint) {
        uint currentBlockNumber = block.number;
        uint accrualBlockNumberPrior = accrualBlockNumber;
        if(currentBlockNumber == accrualBlockNumberPrior){
            return uint(Error.SUCCESS);
        }

        // pull memory
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "accrueInterest::interestRateModel.getBorrowRate, borrow rate high");

        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "accrueInterest::subUInt, block delta failure");

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.ERROR, ErrorRemarks.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
        }

        // push storage
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice User supplies assets into the market and receives cTokens in exchange
     * @dev mintTokens = actualMintAmount / exchangeRate
     * @dev totalSupplyNew = totalSupply + mintTokens
     * @dev accountTokensNew = accountTokens[_minter] + mintTokens
     * @param _minter address minter
     * @param _mintAmount mint amount
     * @return SUCCESS, number
     */
    function mintFresh(address _minter, uint _mintAmount)internal returns (uint, uint) {
        require(block.number == accrualBlockNumber, "MINT_FRESHNESS_CHECK");
        
        uint allowed = comptroller.mintAllowed();
        require(allowed == 0, "MINT_COMPTROLLER_REJECTION");

        MintLocalVars memory vars;
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_RATE_READ_FAILED");

        vars.actualMintAmount = doTransferIn(_minter, _mintAmount);

        (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
        require(vars.mathErr == MathError.NO_ERROR, "mintFresh::divScalarByExpTruncate failure");

        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "mintFresh::addUInt totalSupply failure");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[_minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "mintFresh::addUInt accountTokens failure");

        totalSupply = vars.totalSupplyNew;
        accountTokens[_minter] = vars.accountTokensNew;

        emit Mint(_minter, vars.actualMintAmount, vars.mintTokens);
        emit Transfer(address(this), _minter, vars.mintTokens);
        return (uint(Error.SUCCESS), vars.actualMintAmount);
    }

    /**
     * @notice Current exchangeRate from the underlying to the AToken
     * @return uint exchangeRate
     */
    function exchangeRateStored() public view returns (uint) {
        (MathError err, uint rate) = exchangeRateStoredInternal();
        require(err == MathError.NO_ERROR, "exchangeRateStored::exchangeRateStoredInternal failure");
        return rate;
    }

    /**
     * @notice Current exchangeRate from the underlying to the AToken
     * @dev exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
     * @return SUCCESS, exchangeRate
     */
    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        if(totalSupply == 0){
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        }

        uint _totalSupply = totalSupply;
        uint totalCash = getCashPrior();
        uint cashPlusBorrowsMinusReserves;
        
        MathError err;
        (err, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
        if(err != MathError.NO_ERROR) {
            return (err, 0);
        }
        
        Exp memory exchangeRate;
        (err, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
        if(err != MathError.NO_ERROR) {
            return (err, 0);
        }
        return (MathError.NO_ERROR, exchangeRate.mantissa);
    }

    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    /**
     * @notice Get a snapshot of the account's balances and the cached exchange rate
     * @param _address address
     * @return SUCCESS, balance, balance, exchangeRate
     */
    function getAccountSnapshot(address _address) external view returns (uint, uint, uint, uint) {
        MathError err;
        uint borrowBalance;
        uint exchangeRateMantissa;

        (err, borrowBalance) = borrowBalanceStoredInternal(_address);
        if(err != MathError.NO_ERROR){
            return (uint(Error.ERROR), 0, 0, 0);
        }
        (err, exchangeRateMantissa) = exchangeRateStoredInternal();
        if(err != MathError.NO_ERROR){
            return (uint(Error.ERROR), 0, 0, 0);
        }
        return (uint(Error.SUCCESS), accountTokens[_address], borrowBalance, exchangeRateMantissa);
    }

    /**
     * @notice current per-block borrow interest rate for this aToken
     * @return current borrowRate
     */
    function borrowRatePerBlock() external view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice current per-block supply interest rate for this aToken
     * @return current supplyRate
     */
    function supplyRatePerBlock() external view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice current total borrows plus accrued interest
     * @return totalBorrows
     */
    function totalBorrowsCurrent() external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.SUCCESS), "totalBorrowsCurrent::accrueInterest failure");
        return totalBorrows;
    }

    /**
     * @notice current borrow limit by account
     * @param _account address
     * @return borrowBalance
     */
    function borrowBalanceCurrent(address _account) external nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.SUCCESS), "borrowBalanceCurrent::accrueInterest failure");
        return borrowBalanceStored(_account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param _account address
     * @return borrowBalance
     */
    function borrowBalanceStored(address _account) public view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(_account);
        require(err == MathError.NO_ERROR, "borrowBalanceStored::borrowBalanceStoredInternal failure");
        return result;
    }

    /**
     * @notice Return borrow balance of account based on stored data
     * @param _account address
     * @return SUCCESS, number
     */
    function borrowBalanceStoredInternal(address _account) internal view returns (MathError, uint) {
        BorrowBalanceInfomation storage borrowBalanceInfomation = accountBorrows[_account];
        if(borrowBalanceInfomation.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }
        
        MathError err;
        uint principalTimesIndex;
        (err, principalTimesIndex) = mulUInt(borrowBalanceInfomation.principal, borrowIndex);
        if(err != MathError.NO_ERROR){
            return (err, 0);
        }
        
        uint balance;
        (err, balance) = divUInt(principalTimesIndex, borrowBalanceInfomation.interestIndex);
        if(err != MathError.NO_ERROR){
            return (err, 0);
        }
        return (MathError.NO_ERROR, balance);
    }

    /**
     * @notice Sender redeems aTokens in exchange for the underlying asset
     * @param _redeemTokens aToken number
     * @return SUCCESS
     */
    function redeemInternal(uint _redeemTokens) internal nonReentrant returns (uint) {
        require(_redeemTokens > 0, "CANNOT_BE_ZERO");
        
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "REDEEM_ACCRUE_INTEREST_FAILED");
        return redeemFresh(msg.sender, _redeemTokens, 0);
    }

    /**
     * @notice Sender redeems aTokens in exchange for a specified amount of underlying asset
     * @param _redeemAmount The amount of underlying to receive from redeeming aTokens
     * @return SUCCESS
     */
    function redeemUnderlyingInternal(uint _redeemAmount) internal nonReentrant returns (uint) {
        require(_redeemAmount > 0, "CANNOT_BE_ZERO");

        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "REDEEM_ACCRUE_INTEREST_FAILED");
        return redeemFresh(msg.sender, 0, _redeemAmount);
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev redeemAmount = redeemTokensIn x exchangeRateCurrent
     * @dev redeemTokens = redeemAmountIn / exchangeRate
     * @dev totalSupplyNew = totalSupply - redeemTokens
     * @dev accountTokensNew = accountTokens[redeemer] - redeemTokens
     * @param _redeemer aToken address
     * @param _redeemTokensIn redeemTokensIn The number of aTokens to redeem into underlying
     * @param _redeemAmountIn redeemAmountIn The number of underlying tokens to receive from redeeming aTokens
     * @return SUCCESS
     */
    function redeemFresh(address payable _redeemer, uint _redeemTokensIn, uint _redeemAmountIn) internal returns (uint) {
        require(accrualBlockNumber == block.number, "REDEEM_FRESHNESS_CHECK");

        RedeemLocalVars memory vars;
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        require(vars.mathErr == MathError.NO_ERROR, "REDEEM_EXCHANGE_RATE_READ_FAILED");
        if(_redeemTokensIn > 0) {
            vars.redeemTokens = _redeemTokensIn;
            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), _redeemTokensIn);
            require(vars.mathErr == MathError.NO_ERROR, "REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED");
        } else {
            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(_redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
            require(vars.mathErr == MathError.NO_ERROR, "REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED");
            vars.redeemAmount = _redeemAmountIn;
        }
        uint allowed = comptroller.redeemAllowed(address(this), _redeemer, vars.redeemTokens);
        require(allowed == 0, "REDEEM_COMPTROLLER_REJECTION");
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, "REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[_redeemer], vars.redeemTokens);
        require(vars.mathErr == MathError.NO_ERROR, "REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        require(getCashPrior() >= vars.redeemAmount, "REDEEM_TRANSFER_OUT_NOT_POSSIBLE");
        doTransferOut(_redeemer, vars.redeemAmount);

        // push storage
        totalSupply = vars.totalSupplyNew;
        accountTokens[_redeemer] = vars.accountTokensNew;

        emit Transfer(_redeemer, address(this), vars.redeemTokens);
        emit Redeem(_redeemer, vars.redeemAmount, vars.redeemTokens);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param _borrowAmount: The amount of the underlying asset to borrow
     * @return SUCCESS
     */
    function borrowInternal(uint _borrowAmount) internal nonReentrant returns (uint) {
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "BORROW_ACCRUE_INTEREST_FAILED");
        return borrowFresh(msg.sender, _borrowAmount);
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param _borrower address
     * @param _borrowAmount number
     * @return SUCCESS
     */
    function borrowFresh(address payable _borrower, uint _borrowAmount) internal returns (uint) {
        uint allowed = comptroller.borrowAllowed(address(this), _borrower, _borrowAmount);
        require(allowed == 0, "BORROW_COMPTROLLER_REJECTION");
        require(block.number == accrualBlockNumber, "BORROW_FRESHNESS_CHECK");
        require(_borrowAmount <= getCashPrior(), "BORROW_CASH_NOT_AVAILABLE");

        BorrowLocalVars memory vars;
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(_borrower);
        require(vars.mathErr == MathError.NO_ERROR, "BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, _borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, _borrowAmount);
        require(vars.mathErr == MathError.NO_ERROR, "BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

        doTransferOut(_borrower, _borrowAmount);

        // push storage
        accountBorrows[_borrower].principal = vars.accountBorrowsNew;
        accountBorrows[_borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        emit Borrow(_borrower, _borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Sender repays their own borrow
     * @param _repayAmount The amount to repay
     * @return SUCCESS, number
     */
    function repayBorrowInternal(uint _repayAmount) internal nonReentrant returns (uint, uint) {
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "REPAY_BORROW_ACCRUE_INTEREST_FAILED");
        return repayBorrowFresh(msg.sender, msg.sender, _repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param _borrower Borrower address
     * @param _repayAmount The amount to repay
     * @return SUCCESS, number
     */
    function repayBorrowBehalfInternal(address _borrower, uint _repayAmount) internal nonReentrant returns (uint, uint) {
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "REPAY_BEHALF_ACCRUE_INTEREST_FAILED");
        return repayBorrowFresh(msg.sender, _borrower, _repayAmount);
    }

    /**
     * @notice Repay Borrow
     * @param _payer The account paying off the borrow
     * @param _borrower The account with the debt being payed off
     * @param _repayAmount The amount of undelrying tokens being returned
     * @return SUCCESS, number
     */
    function repayBorrowFresh(address _payer, address _borrower, uint _repayAmount) internal returns (uint, uint) {
        require(block.number == accrualBlockNumber, "REPAY_BORROW_FRESHNESS_CHECK");

        uint allowed = comptroller.repayBorrowAllowed();
        require(allowed == 0, "REPAY_BORROW_COMPTROLLER_REJECTION");
        RepayBorrowLocalVars memory vars;
        vars.borrowerIndex = accountBorrows[_borrower].interestIndex;
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(_borrower);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED");
        
        if (_repayAmount == uint(-1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = _repayAmount;
        }
        vars.actualRepayAmount = doTransferIn(_payer, vars.repayAmount);
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "repayBorrowFresh::subUInt vars.accountBorrows failure");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "repayBorrowFresh::subUInt totalBorrows failure");

        // push storage
        accountBorrows[_borrower].principal = vars.accountBorrowsNew;
        accountBorrows[_borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        emit RepayBorrow(_payer, _borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);
        return (uint(Error.SUCCESS), vars.actualRepayAmount);
    }

    event OwnerRepayBorrowBehalf(address _account, uint _underlying);
    function ownerRepayBorrowBehalfInternal(address _borrower, address _sender, uint _underlying) internal nonReentrant returns (uint) {
        RepayBorrowLocalVars memory vars;
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(_borrower);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerRepayBorrowBehalfInternal.borrowBalanceStoredInternal vars.accountBorrows failure");
        uint _tran = doTransferIn(_sender, _underlying);
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, _tran);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerRepayBorrowBehalfInternal.subUInt vars.accountBorrowsNew failure");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, _tran);
        require(vars.mathErr == MathError.NO_ERROR, "AToken::ownerRepayBorrowBehalfInternal.subUInt vars.totalBorrowsNew failure");

        // push storage
        accountBorrows[_borrower].principal = vars.accountBorrowsNew;
        accountBorrows[_borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;
        emit OwnerRepayBorrowBehalf(_borrower, _underlying);
        return (uint(Error.SUCCESS));
    }

    /**
     * @notice Transfers collateral tokens to the liquidator
     * @param _liquidator address
     * @param _borrower address
     * @param _seizeTokens seize number
     * @return SUCCESS
     */
    function seize(address _liquidator, address _borrower, uint _seizeTokens) external nonReentrant returns (uint) {
        require(_liquidator != _borrower, "LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER");
        return seizeInternal(msg.sender, _liquidator, _borrower, _seizeTokens);
    }

    /**
     * @notice Transfers collateral tokens to the liquidator. Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another AToken
     * @dev borrowerTokensNew = accountTokens[borrower] - seizeTokens
     * @dev liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
     * @param _token address
     * @param _liquidator address
     * @param _borrower address
     * @param _seizeTokens seize number
     * @return SUCCESS
     */
    function seizeInternal(address _token, address _liquidator, address _borrower, uint _seizeTokens) internal returns (uint) {
        uint allowed = comptroller.seizeAllowed(address(this), _token);
        require(allowed == 0, "LIQUIDATE_SEIZE_COMPTROLLER_REJECTION");
        
        MathError mathErr;
        uint borrowerTokensNew;
        uint liquidatorTokensNew;
        (mathErr, borrowerTokensNew) = subUInt(accountTokens[_borrower], _seizeTokens);
        require(mathErr == MathError.NO_ERROR, "LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED");
        
        (mathErr, liquidatorTokensNew) = addUInt(accountTokens[_liquidator], _seizeTokens);
        require(mathErr == MathError.NO_ERROR, "LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED");

        // push storage
        accountTokens[_borrower] = borrowerTokensNew;
        accountTokens[_liquidator] = liquidatorTokensNew;

        emit Transfer(_borrower, _liquidator, _seizeTokens);
        return uint(Error.SUCCESS);
    }

    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
    }

    struct RepayBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint actualRepayAmount;
    }

    function _setPendingAdmin(address payable _newAdmin) external returns (uint) {
        require(admin == msg.sender, "SET_PENDING_ADMIN_OWNER_CHECK");
        address _old = pendingAdmin;
        pendingAdmin = _newAdmin;
        emit NewPendingAdmin(_old, _newAdmin);
        return uint(Error.SUCCESS);
    }

    function _acceptAdmin() external returns (uint) {
        if (msg.sender != pendingAdmin || msg.sender == address(0)) {
            return fail(Error.ERROR, ErrorRemarks.ACCEPT_ADMIN_PENDING_ADMIN_CHECK, uint(Error.ERROR));
        }
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
        return uint(Error.SUCCESS);
    }

    function _setComptroller(AegisComptrollerInterface _aegisComptrollerInterface) public returns (uint) {
        require(admin == msg.sender, "SET_COMPTROLLER_OWNER_CHECK");
        AegisComptrollerInterface old = comptroller;
        require(_aegisComptrollerInterface.aegisComptroller(), "AToken::_setComptroller _aegisComptrollerInterface false");
        comptroller = _aegisComptrollerInterface;

        emit NewComptroller(old, _aegisComptrollerInterface);
        return uint(Error.SUCCESS);
    }

    function _setReserveFactor(uint _newReserveFactor) external nonReentrant returns (uint) {
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED");
        return _setReserveFactorFresh(_newReserveFactor);
    }

    function _setReserveFactorFresh(uint _newReserveFactor) internal returns (uint) {
        require(block.number == accrualBlockNumber, "SET_RESERVE_FACTOR_FRESH_CHECK");
        require(msg.sender == admin, "SET_RESERVE_FACTOR_ADMIN_CHECK");
        require(_newReserveFactor <= reserveFactorMaxMantissa, "SET_RESERVE_FACTOR_BOUNDS_CHECK");
        
        uint old = reserveFactorMantissa;
        reserveFactorMantissa = _newReserveFactor;

        emit NewReserveFactor(old, _newReserveFactor);
        return uint(Error.SUCCESS);
    }

    function _addResevesInternal(uint _addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.SUCCESS), "ADD_RESERVES_ACCRUE_INTEREST_FAILED");
        
        (error, ) = _addReservesFresh(_addAmount);
        return error;
    }

    function _addReservesFresh(uint _addAmount) internal returns (uint, uint) {
        require(block.number == accrualBlockNumber, "ADD_RESERVES_FRESH_CHECK");
        
        uint actualAddAmount = doTransferIn(msg.sender, _addAmount);
        uint totalReservesNew = totalReserves + actualAddAmount;

        require(totalReservesNew >= totalReserves, "_addReservesFresh::totalReservesNew >= totalReserves failure");

        // push storage
        totalReserves = totalReservesNew;

        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);
        return (uint(Error.SUCCESS), actualAddAmount);
    }

    function _reduceReserves(uint _reduceAmount, address payable _account) external nonReentrant returns (uint) {
        uint error = accrueInterest();
        require(error == uint(Error.SUCCESS), "REDUCE_RESERVES_ACCRUE_INTEREST_FAILED");
        return _reduceReservesFresh(_reduceAmount, _account);
    }

    function _reduceReservesFresh(uint _reduceAmount, address payable _account) internal returns (uint) {
        require(admin == msg.sender, "REDUCE_RESERVES_ADMIN_CHECK");
        require(block.number == accrualBlockNumber, "REDUCE_RESERVES_FRESH_CHECK");
        require(_reduceAmount <= getCashPrior(), "REDUCE_RESERVES_CASH_NOT_AVAILABLE");
        require(_reduceAmount <= totalReserves, "REDUCE_RESERVES_VALIDATION");

        uint totalReservesNew = totalReserves - _reduceAmount;
        require(totalReservesNew <= totalReserves, "_reduceReservesFresh::totalReservesNew <= totalReserves failure");

        // push storage
        totalReserves = totalReservesNew;
        doTransferOut(_account, _reduceAmount);
        emit ReservesReduced(_account, _reduceAmount, totalReservesNew);
        return uint(Error.SUCCESS);
    }

    function _setInterestRateModel(InterestRateModel _interestRateModel) public returns (uint) {
        uint err = accrueInterest();
        require(err == uint(Error.SUCCESS), "SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED");
        return _setInterestRateModelFresh(_interestRateModel);
    }

    function _setInterestRateModelFresh(InterestRateModel _interestRateModel) internal returns (uint) {
        require(msg.sender == admin, "SET_INTEREST_RATE_MODEL_OWNER_CHECK");
        require(block.number == accrualBlockNumber, "SET_INTEREST_RATE_MODEL_FRESH_CHECK");

        InterestRateModel old = interestRateModel;
        require(_interestRateModel.isInterestRateModel(), "_setInterestRateModelFresh::_interestRateModel.isInterestRateModel failure");
        interestRateModel = _interestRateModel;
        emit NewMarketInterestRateModel(old, _interestRateModel);
        return uint(Error.SUCCESS);
    }

    event NewLiquidateAdmin(address _old, address _new);
    function _setLiquidateAdmin(address payable _newLiquidateAdmin) public returns (uint) {
        require(msg.sender == liquidateAdmin, "change not authorized");
        address _old = liquidateAdmin;
        liquidateAdmin = _newLiquidateAdmin;
        emit NewLiquidateAdmin(_old, _newLiquidateAdmin);
        return uint(Error.SUCCESS);
    }
}"},"ATokenInterface.sol":{"content":"pragma solidity ^0.5.16;

import "./AegisTokenCommon.sol";
import "./InterestRateModel.sol";
import "./AegisComptrollerInterface.sol";

/**
 * @title aToken interface
 * @author Aegis
 */
contract ATokenInterface is AegisTokenCommon {
    bool public constant aToken = true;

    /**
     * @notice Emitted when interest is accrued
     */
    event AccrueInterest(uint _cashPrior, uint _interestAccumulated, uint _borrowIndex, uint _totalBorrows);

    /**
     * @notice Emitted when tokens are minted
     */
    event Mint(address _minter, uint _mintAmount, uint _mintTokens);

    /**
     * @notice Emitted when tokens are redeemed
     */
    event Redeem(address _redeemer, uint _redeemAmount, uint _redeemTokens);

    /**
     * @notice Emitted when underlying is borrowed
     */
    event Borrow(address _borrower, uint _borrowAmount, uint _accountBorrows, uint _totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address _payer, address _borrower, uint _repayAmount, uint _accountBorrows, uint _totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address _liquidator, address _borrower, uint _repayAmount, address _aTokenCollateral, uint _seizeTokens);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address _old, address _new);

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(AegisComptrollerInterface _oldComptroller, AegisComptrollerInterface _newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel _oldInterestRateModel, InterestRateModel _newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint _oldReserveFactorMantissa, uint _newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address _benefactor, uint _addAmount, uint _newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address _admin, uint _reduceAmount, uint _newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed _from, address indexed _to, uint _amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed _owner, address indexed _spender, uint _amount);

    /**
     * @notice Failure event
     */
    event Failure(uint _error, uint _info, uint _detail);


    function transfer(address _dst, uint _amount) external returns (bool);
    function transferFrom(address _src, address _dst, uint _amount) external returns (bool);
    function approve(address _spender, uint _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function balanceOfUnderlying(address _owner) external returns (uint);
    function getAccountSnapshot(address _account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address _account) external returns (uint);
    function borrowBalanceStored(address _account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address _liquidator, address _borrower, uint _seizeTokens) external returns (uint);


    function _acceptAdmin() external returns (uint);
    function _setComptroller(AegisComptrollerInterface _newComptroller) public returns (uint);
    function _setReserveFactor(uint _newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint _reduceAmount, address payable _account) external returns (uint);
    function _setInterestRateModel(InterestRateModel _newInterestRateModel) public returns (uint);
}"},"BaseReporter.sol":{"content":"pragma solidity ^0.5.16;

/**
 * @title Collection of error messages
 * @author Aegis
 */
contract BaseReporter {
    event FailUre(uint _error, uint _remarks, uint _item);
    enum Error{
        SUCCESS,
        ERROR
    }

    enum ErrorRemarks {
        COMPTROLLER_TRANSFER_ALLOWED,
        ALLOW_SELF_TRANSFERS,
        DIVISION_BY_ZERO,

        SET_COMPTROLLER_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_VALIDATION,

        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,

        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW,

        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,

        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,

        MINT_COMPTROLLER_REJECTION,
        MINT_FRESHNESS_CHECK,
        MINT_EXCHANGE_RATE_READ_FAILED,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        CANNOT_BE_ZERO,

        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,

        BORROW_FRESHNESS_CHECK,
        BORROW_COMPTROLLER_REJECTION,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,

        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,

        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,

        SET_PRICE_ORACLE_OWNER_CHECK,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,

        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,

        SET_MAX_ASSETS_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK,

        SET_PENDING_ADMIN_OWNER_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        MINT_ACCRUE_INTEREST_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED

    }

    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    function fail(Error _errorEnum, ErrorRemarks _remarks, uint _item) internal returns (uint) {
        emit FailUre(uint(_errorEnum), uint(_remarks), _item);
        return uint(_errorEnum);
    }
}"},"CarefulMath.sol":{"content":"pragma solidity ^0.5.16;

import "./BaseReporter.sol";

contract CarefulMath {

    function mulUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_a == 0) {
            return (BaseReporter.MathError.NO_ERROR, 0);
        }
        uint c = _a * _b;
        if (c / _a != _b) {
            return (BaseReporter.MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (BaseReporter.MathError.NO_ERROR, c);
        }
    }

    function divUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_b == 0) {
            return (BaseReporter.MathError.DIVISION_BY_ZERO, 0);
        }

        return (BaseReporter.MathError.NO_ERROR, _a / _b);
    }

    function subUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        if (_b <= _a) {
            return (BaseReporter.MathError.NO_ERROR, _a - _b);
        } else {
            return (BaseReporter.MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    function addUInt(uint _a, uint _b) internal pure returns (BaseReporter.MathError, uint) {
        uint c = _a + _b;
        if (c >= _a) {
            return (BaseReporter.MathError.NO_ERROR, c);
        } else {
            return (BaseReporter.MathError.INTEGER_OVERFLOW, 0);
        }
    }

    function addThenSubUInt(uint _a, uint _b, uint _c) internal pure returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err0, uint sum) = addUInt(_a, _b);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, 0);
        }
        return subUInt(sum, _c);
    }
}"},"Exponential.sol":{"content":"pragma solidity ^0.5.16;

import "./AegisMath.sol";
import "./BaseReporter.sol";
import "./CarefulMath.sol";

contract Exponential is CarefulMath {

    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @notice Creates an exponential from numerator and denominator values
     * @param _num uint
     * @param _denom uint
     * @return MathError, Exp
     */
    function getExp(uint _num, uint _denom) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint scaledNumerator) = mulUInt(_num, expScale);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err1, uint rational) = divUInt(scaledNumerator, _denom);
        if (err1 != BaseReporter.MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @notice Adds two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function addExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError error, uint result) = addUInt(_a.mantissa, _b.mantissa);
        return (error, Exp({mantissa: result}));
    }

    /**
     * @notice Subtracts two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function subExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError error, uint result) = subUInt(_a.mantissa, _b.mantissa);
        return (error, Exp({mantissa: result}));
    }

    /**
     * @notice Multiply an Exp by a scalar, returning a new Exp
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function mulScalar(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint scaledMantissa) = mulUInt(_a.mantissa, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @notice Multiply an Exp by a scalar, then truncate to return an unsigned integer
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function mulScalarTruncate(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory product) = mulScalar(_a, _scalar);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return (BaseReporter.MathError.NO_ERROR, truncate(product));
    }

    /**
     * @notice Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer
     * @param _a exp
     * @param _scalar uint
     * @param _addend uint
     * @return MathError, Exp
     */
    function mulScalarTruncateAddUInt(Exp memory _a, uint _scalar, uint _addend) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory product) = mulScalar(_a, _scalar);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return addUInt(truncate(product), _addend);
    }

    /**
     * @notice Divide an Exp by a scalar, returning a new Exp
     * @param _a exp
     * @param _scalar uint
     * @return MathError, Exp
     */
    function divScalar(Exp memory _a, uint _scalar) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint descaledMantissa) = divUInt(_a.mantissa, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @notice Divide a scalar by an Exp, returning a new Exp
     * @param _scalar uint
     * @param _divisor exp
     * @return MathError, Exp
     */
    function divScalarByExp(uint _scalar, Exp memory _divisor) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint numerator) = mulUInt(expScale, _scalar);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, _divisor.mantissa);
    }

    /**
     * @notice Divide a scalar by an Exp, then truncate to return an unsigned integer
     * @param _scalar uint
     * @param _divisor exp
     * @return MathError, Exp
     */
    function divScalarByExpTruncate(uint _scalar, Exp memory _divisor) pure internal returns (BaseReporter.MathError, uint) {
        (BaseReporter.MathError err, Exp memory fraction) = divScalarByExp(_scalar, _divisor);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, 0);
        }
        return (BaseReporter.MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @notice Multiplies two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function mulExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err0, uint doubleScaledProduct) = mulUInt(_a.mantissa, _b.mantissa);
        if (err0 != BaseReporter.MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != BaseReporter.MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }
        (BaseReporter.MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        assert(err2 == BaseReporter.MathError.NO_ERROR);
        return (BaseReporter.MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @notice Multiplies two exponentials given their mantissas, returning a new exponential
     * @param _a uint
     * @param _b uint
     * @return MathError, Exp
     */
    function mulExp(uint _a, uint _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        return mulExp(Exp({mantissa: _a}), Exp({mantissa: _b}));
    }

    /**
     * @notice Multiplies three exponentials, returning a new exponential.
     * @param _a exp
     * @param _b exp
     * @param _c exp
     * @return MathError, Exp
     */
    function mulExp3(Exp memory _a, Exp memory _b, Exp memory _c) pure internal returns (BaseReporter.MathError, Exp memory) {
        (BaseReporter.MathError err, Exp memory ab) = mulExp(_a, _b);
        if (err != BaseReporter.MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, _c);
    }

    /**
     * @notice Divides two exponentials, returning a new exponential
     * @param _a exp
     * @param _b exp
     * @return MathError, Exp
     */
    function divExp(Exp memory _a, Exp memory _b) pure internal returns (BaseReporter.MathError, Exp memory) {
        return getExp(_a.mantissa, _b.mantissa);
    }

    /**
     * @notice Truncates the given exp to a whole number value
     * @param _exp exp
     * @return uint
     */
    function truncate(Exp memory _exp) pure internal returns (uint) {
        return _exp.mantissa / expScale;
    }

    /**
     * @notice Checks if first Exp is less than second Exp
     * @param _left exp
     * @param _right exp
     * @return bool
     */
    function lessThanExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa < _right.mantissa;
    }

    /**
     * @notice Checks if left Exp <= right Exp
     * @param _left exp
     * @param _right exp
     * @return bool
     */
    function lessThanOrEqualExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa <= _right.mantissa;
    }

    /**
     * @notice Checks if left Exp > right Exp.
     * @param _left exp
     * @param _right exp
     */
    function greaterThanExp(Exp memory _left, Exp memory _right) pure internal returns (bool) {
        return _left.mantissa > _right.mantissa;
    }

    /**
     * @notice returns true if Exp is exactly zero
     * @param _value exp
     * @return MathError, Exp
     */
    function isZeroExp(Exp memory _value) pure internal returns (bool) {
        return _value.mantissa == 0;
    }

    function safe224(uint _n, string memory _errorMessage) pure internal returns (uint224) {
        require(_n < 2**224, _errorMessage);
        return uint224(_n);
    }

    function safe32(uint _n, string memory _errorMessage) pure internal returns (uint32) {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }

    function add_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: add_(_a.mantissa, _b.mantissa)});
    }

    function add_(uint _a, uint _b) pure internal returns (uint) {
        return add_(_a, _b, "add overflow");
    }

    function add_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        uint c = _a + _b;
        require(c >= _a, _errorMessage);
        return c;
    }

    function sub_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(_a.mantissa, _b.mantissa)});
    }

    function sub_(uint _a, uint _b) pure internal returns (uint) {
        return sub_(_a, _b, "sub underflow");
    }

    function sub_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        require(_b <= _a, _errorMessage);
        return _a - _b;
    }

    function mul_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b.mantissa) / expScale});
    }

    function mul_(Exp memory _a, uint _b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(uint _a, Exp memory _b) pure internal returns (uint) {
        return mul_(_a, _b.mantissa) / expScale;
    }

    function mul_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b.mantissa) / doubleScale});
    }

    function mul_(Double memory _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(_a.mantissa, _b)});
    }

    function mul_(uint _a, Double memory _b) pure internal returns (uint) {
        return mul_(_a, _b.mantissa) / doubleScale;
    }

    function mul_(uint _a, uint _b) pure internal returns (uint) {
        return mul_(_a, _b, "mul overflow");
    }

    function mul_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint c = _a * _b;
        require(c / _a == _b, _errorMessage);
        return c;
    }

    function div_(Exp memory _a, Exp memory _b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(_a.mantissa, expScale), _b.mantissa)});
    }

    function div_(Exp memory _a, uint _b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(uint _a, Exp memory _b) pure internal returns (uint) {
        return div_(mul_(_a, expScale), _b.mantissa);
    }

    function div_(Double memory _a, Double memory _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(_a.mantissa, doubleScale), _b.mantissa)});
    }

    function div_(Double memory _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(_a.mantissa, _b)});
    }

    function div_(uint _a, Double memory _b) pure internal returns (uint) {
        return div_(mul_(_a, doubleScale), _b.mantissa);
    }

    function div_(uint _a, uint _b) pure internal returns (uint) {
        return div_(_a, _b, "div by zero");
    }

    function div_(uint _a, uint _b, string memory _errorMessage) pure internal returns (uint) {
        require(_b > 0, _errorMessage);
        return _a / _b;
    }

    function fraction(uint _a, uint _b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(_a, doubleScale), _b)});
    }
}"},"InterestRateModel.sol":{"content":"pragma solidity ^0.5.16;

/**
 * @title Aegis InterestRateModel interface
 * @author Aegis
 */
contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param _cash The total amount of cash the market has
      * @param _borrows The total amount of borrows the market has outstanding
      * @param _reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint _cash, uint _borrows, uint _reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param _cash The total amount of cash the market has
      * @param _borrows The total amount of borrows the market has outstanding
      * @param _reserves The total amnount of reserves the market has
      * @param _reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint _cash, uint _borrows, uint _reserves, uint _reserveFactorMantissa) external view returns (uint);
}"}}