{"InterestRateModel.sol":{"content":"pragma solidity 0.5.17;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param fees The total amount of fees the market has
      * @param momaFees The total amount of Moma fees the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(
        uint cash, 
        uint borrows, 
        uint reserves, 
        uint fees, 
        uint momaFees
    ) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @param fees The total amount of fees the market has
      * @param feeFactorMantissa The current fee factor the market has
      * @param momaFees The total amount of Moma fees the market has
      * @param momaFeeFactorMantissa The current Moma fees factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(
        uint cash, 
        uint borrows, 
        uint reserves, 
        uint reserveFactorMantissa, 
        uint fees, 
        uint feeFactorMantissa, 
        uint momaFees, 
        uint momaFeeFactorMantissa
    ) external view returns (uint);
}
"},"MEtherDelegator.sol":{"content":"pragma solidity 0.5.17;

import "./MTokenInterfaces.sol";
import "./MomaFactoryInterface.sol";

/**
 * @title Moma's MEtherDelegator Contract
 * @notice Ether MToken which delegate to an implementation
 * @author Moma
 */
contract MEtherDelegator is MTokenStorage, MDelegatorInterface {
    /**
     * @notice Construct a new money market
     * @param momaMaster_ The address of the momaMaster
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param becomeImplementationData The encoded args for becomeImplementation
     * @param feeReceiver_ Address of the free receiver of this token
     */
    constructor(MomaMasterInterface momaMaster_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                bytes memory becomeImplementationData,
                address payable feeReceiver_) public {
        // Get the address of the implementation the contract delegates to from factory
        address implementation_ = MomaFactoryInterface(momaMaster_.factory()).mEtherImplementation();
        require(implementation_ != address(0), 'MEtherDelegator: ZERO FORBIDDEN');

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,uint256,string,string,uint8,address)",
                                                            momaMaster_,
                                                            initialExchangeRateMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_,
                                                            feeReceiver_));

        // New implementations always get set via the settor (post-initialize)
        _setImplementation(implementation_, false, becomeImplementationData);

    }

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public {
        require(msg.sender == momaMaster.admin(), "MEtherDelegator::_setImplementation: Caller must be admin");

        // Check is mEther
        require(MomaFactoryInterface(momaMaster.factory()).isMEtherImplementation(implementation_) == true, 'MEtherDelegator: not mEtherImplementation');

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transfer(address,uint256)", dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("transferFrom(address,address,uint256)", src, dst, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        bytes memory data = delegateToImplementation(abi.encodeWithSignature("approve(address,uint256)", spender, amount));
        return abi.decode(data, (bool));
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("allowance(address,address)", owner, spender));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint) {
        bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
        return abi.decode(data, (uint));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    function () external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}
"},"MomaFactoryInterface.sol":{"content":"pragma solidity 0.5.17;

interface MomaFactoryInterface {

    event PoolCreated(address pool, address creator, uint poolLength);
    event NewMomaFarming(address oldMomaFarming, address newMomaFarming);
    event NewFarmingDelegate(address oldDelegate, address newDelegate);
    event NewFeeAdmin(address oldFeeAdmin, address newFeeAdmin);
    event NewDefualtFeeReceiver(address oldFeeReceiver, address newFeeReceiver);
    event NewDefualtFeeFactor(uint oldFeeFactor, uint newFeeFactor);
    event NewNoFeeTokenStatus(address token, bool oldNoFeeTokenStatus, bool newNoFeeTokenStatus);
    event NewTokenFeeFactor(address token, uint oldFeeFactor, uint newFeeFactor);
    event NewOracle(address oldOracle, address newOracle);
    event NewTimelock(address oldTimelock, address newTimelock);
    event NewMomaMaster(address oldMomaMaster, address newMomaMaster);
    event NewMEther(address oldMEther, address newMEther);
    event NewMErc20(address oldMErc20, address newMErc20);
    event NewMErc20Implementation(address oldMErc20Implementation, address newMErc20Implementation);
    event NewMEtherImplementation(address oldMEtherImplementation, address newMEtherImplementation);
    event NewLendingPool(address pool);
    event NewPoolFeeAdmin(address pool, address oldPoolFeeAdmin, address newPoolFeeAdmin);
    event NewPoolFeeReceiver(address pool, address oldPoolFeeReceiver, address newPoolFeeReceiver);
    event NewPoolFeeFactor(address pool, uint oldPoolFeeFactor, uint newPoolFeeFactor);
    event NewPoolFeeStatus(address pool, bool oldPoolFeeStatus, bool newPoolFeeStatus);

    function isMomaFactory() external view returns (bool);
    function oracle() external view returns (address);
    function momaFarming() external view returns (address);
    function farmingDelegate() external view returns (address);
    function mEtherImplementation() external view returns (address);
    function mErc20Implementation() external view returns (address);
    function admin() external view returns (address);
    function feeAdmin() external view returns (address);
    function defualtFeeReceiver() external view returns (address);
    function defualtFeeFactorMantissa() external view returns (uint);
    function feeFactorMaxMantissa() external view returns (uint);

    function tokenFeeFactors(address token) external view returns (uint);
    // function pools(address pool) external view returns (PoolInfo memory);
    function allPools(uint) external view returns (address);

    function createPool() external returns (address);
    function allPoolsLength() external view returns (uint);
    function getMomaFeeAdmin(address pool) external view returns (address);
    function getMomaFeeReceiver(address pool) external view returns (address payable);
    function getMomaFeeFactorMantissa(address pool, address underlying) external view returns (uint);
    function isMomaPool(address pool) external view returns (bool);
    function isLendingPool(address pool) external view returns (bool);
    function isTimelock(address b) external view returns (bool);
    function isMomaMaster(address b) external view returns (bool);
    function isMEtherImplementation(address b) external view returns (bool);
    function isMErc20Implementation(address b) external view returns (bool);
    function isMToken(address b) external view returns (bool);
    function isCodeSame(address a, address b) external view returns (bool);

    function upgradeLendingPool() external returns (bool);
    
    function setFeeAdmin(address _newFeeAdmin) external;
    function setDefualtFeeReceiver(address payable _newFeeReceiver) external;
    function setDefualtFeeFactor(uint _newFeeFactor) external;
    function setTokenFeeFactor(address token, uint _newFeeFactor) external;

    function setPoolFeeAdmin(address pool, address _newPoolFeeAdmin) external;
    function setPoolFeeReceiver(address pool, address payable _newPoolFeeReceiver) external;
    function setPoolFeeFactor(address pool, uint _newFeeFactor) external;
    function setPoolFeeStatus(address pool, bool _noFee) external;
}
"},"MomaMasterInterface.sol":{"content":"pragma solidity 0.5.17;

interface MomaMasterInterface {
    /// @notice Indicator that this is a MomaMaster contract (for inspection)
    function isMomaMaster() external view returns (bool);

    function factory() external view returns (address);
    function admin() external view returns (address payable);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata mTokens) external returns (uint[] memory);
    function exitMarket(address mToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address mToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address mToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address mToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address mToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address mToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address mToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address mToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address mToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address mTokenBorrowed,
        address mTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address mTokenCollateral,
        address mTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address mToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address mToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address mTokenBorrowed,
        address mTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}
"},"MTokenInterfaces.sol":{"content":"pragma solidity 0.5.17;

import "./MomaMasterInterface.sol";
import "./InterestRateModel.sol";

contract MTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for fees
     */
    uint internal constant feeFactorMaxMantissa = 0.3e18;

    /**
     * @notice Maximum fraction of interest that can be set aside for moma fees
     */
    uint internal constant momaFeeFactorMaxMantissa = 0.3e18;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 0.4e18;

    /**
     * @notice Fee receiver for this market
     */
    address payable public feeReceiver;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    MomaMasterInterface public momaMaster;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first MTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for fees
     */
    uint public feeFactorMantissa = 0.1e18;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa = 0.1e18;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of fees of the underlying held in this market
     */
    uint public totalFees;

    /**
     * @notice Total amount of Moma fees of the underlying held in this market
     */
    uint public totalMomaFees;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Indicator that this is a MToken contract (for inspection)
     */
    bool public constant isMToken = true;
}


contract MTokenInterface is MTokenStorage {

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address mTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when momaMaster is changed
     */
    event NewMomaMaster(MomaMasterInterface oldMomaMaster, MomaMasterInterface newMomaMaster);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when feeReceiver is changed
     */
    event NewFeeReceiver(address oldFeeReceiver, address newFeeReceiver);

    /**
     * @notice Event emitted when the fee factor is changed
     */
    event NewFeeFactor(uint oldFeeFactorMantissa, uint newFeeFactorMantissa);

    /**
     * @notice Event emitted when the fees are collected
     */
    event FeesCollected(address feeReceiver, uint collectAmount, uint newTotalFees);

    /**
     * @notice Event emitted when the moma fees are collected
     */
    event MomaFeesCollected(address momaFeeReceiver, uint collectAmount, uint newTotalMomaFees);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Failure event
     */
    event Failure(uint error, uint info, uint detail);


    /*** User Interface ***/

    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function getMomaFeeFactor() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);


    /*** Admin Functions ***/

    function _setFeeReceiver(address payable newFeeReceiver) external returns (uint);
    function _setFeeFactor(uint newFeeFactorMantissa) external returns (uint);
    function _collectFees(uint collectAmount) external returns (uint);
    function _collectMomaFees(uint collectAmount) external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint);
}

contract MErc20Storage {
    /**
     * @notice Underlying asset for this MToken
     */
    address public underlying;
}

contract MErc20Interface is MErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, MTokenInterface mTokenCollateral) external returns (uint);


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external returns (uint);
}

contract MDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract MDelegatorInterface is MDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract MDelegateInterface is MDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}
"}}