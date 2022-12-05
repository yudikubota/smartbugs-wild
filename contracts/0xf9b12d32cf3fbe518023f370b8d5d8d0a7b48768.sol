{"Address.sol":{"content":"pragma solidity ^0.6.4;

// OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}"},"DPiggyAssetData.sol":{"content":"pragma solidity ^0.6.4;

import "DPiggyBaseProxyData.sol";
import "ReentrancyGuard.sol";

/**
 * @title DPiggyAssetData
 * @dev Contract for all dPiggy asset stored data.
 * It must inherit from DPiggyBaseProxyData contract for properly generate the proxy.
 * Each dPiggy asset has your own DPiggyAssetData.
 */
contract DPiggyAssetData is DPiggyBaseProxyData, ReentrancyGuard {
    
    /**
     * @dev The Struct to store each Compound redeem execution data.
     */
    struct Execution {
        /**
         * @dev The time in Unix.
         */
        uint256 time;
        
        /**
         * @dev The calculated rate based on Dai amount variation on Compound.
         */
        uint256 rate;
        
        /**
         * @dev The total amount of Dai on Compound.
         */
        uint256 totalDai;
        
        /**
         * @dev The amount of Dai redeemed on Compound.
         */
        uint256 totalRedeemed;
        
        /**
         * @dev The amount of asset purchased.
         */
        uint256 totalBought;
        
        /**
         * @dev The total of Dai deposited on the contract.
         */
        uint256 totalBalance;
        
        /**
         * @dev The total of Dai with fee exemption.
         */
        uint256 totalFeeDeduction;
        
        /**
         * @dev The total of Dai redeemed that was regarded as the fee.
         */
        uint256 feeAmount;
    }
    
    /**
     * @dev The Struct to store the user data.
     */
    struct UserData {
        /**
         * @dev The last execution Id on deposit.
         */
        uint256 baseExecutionId;
        
        /**
         * @dev The rate on deposit.
         * The value is the weighted average of all deposit rates with the same base execution Id.
         * It is used to calculate the user's corresponding profit on the next Compound redeem execution (baseExecutionId + 1).
         */
        uint256 baseExecutionAvgRate;
        
        /**
         * @dev The amount of Dai on deposit.
         * The value is the amount of Dai accumulated of all deposits with the same base execution Id.
         */
        uint256 baseExecutionAccumulatedAmount;
        
        /**
         * @dev The accumulated weight for the rate calculation.
         * The value is auxiliary for the base execution rate calculation for all deposits with the same base execution Id.
         */
        uint256 baseExecutionAccumulatedWeightForRate;
        
        /**
         * @dev The amount of Dai that will be applied the fee on the next Compound redeem execution (baseExecutionId + 1).
         */
        uint256 baseExecutionAmountForFee;
        
        /**
         * @dev The total of Dai deposited.
         */
        uint256 currentAllocated;
        
        /**
         * @dev The total of Dai previously deposited before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousAllocated;
        
        /**
         * @dev The previous Dai profit before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousProfit;
        
        /**
         * @dev The previous asset amount before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousAssetAmount;
        
        /**
         * @dev The previous fee on Dai before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousFeeAmount;
        
        /**
         * @dev The total amount of asset redeemed.
         */
        uint256 redeemed;
    }
    
    /**
     * @dev Emitted when the minimum time between Compound redeem executions has been changed.
     * @param newTime The new minimum time between Compound redeem executions.
     * @param oldTime The previous minimum time between Compound redeem executions.
     */
    event SetMinimumTimeBetweenExecutions(uint256 newTime, uint256 oldTime);
    
    /**
     * @dev Emitted when a user has deposited Dai on the contract.
     * @param user The user's address.
     * @param amount The amount of Dai deposited.
     * @param rate The calculated rate.
     * @param baseExecutionId The last Compound redeem execution Id.
     * @param baseExecutionAmountForFee The amount of Dai that will be applied the fee on the next Compound redeem execution (baseExecutionId + 1).
     */
    event Deposit(address indexed user, uint256 amount, uint256 rate, uint256 baseExecutionId, uint256 baseExecutionAmountForFee);
    
    /**
     * @dev Emitted when a user has redeemed the asset profit on the contract.
     * @param user The user's address.
     * @param amount The amount of asset redeemed.
     */
    event Redeem(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a Compound redeem has been executed.
     * @param executionId The respective Id.
     * @param rate The calculated rate.
     * @param totalBalance The total of Dai deposited on the contract.
     * @param totalRedeemed The amount of Dai redeemed on Compound.
     * @param fee The total of Dai redeemed that was regarded as the fee.
     * @param totalBought The amount of asset purchased.
     * @param totalAucBurned The amount of Auc purchased and burned with the fee.
     */
    event CompoundRedeem(uint256 indexed executionId, uint256 rate, uint256 totalBalance, uint256 totalRedeemed, uint256 fee, uint256 totalBought, uint256 totalAucBurned);
    
    /**
     * @dev Emitted when a user has finished the own participation on the dPiggy asset.
     * All asset profit is redeemed as well as all the Dai deposited. 
     * @param user The user's address.
     * @param totalRedeemed The amount of Dai redeemed on Compound.
     * @param yield The user yield in Dai redeemed since the last Compound redeem execution.
     * @param fee The total of Dai redeemed that was regarded as the fee.
     * @param totalAucBurned The amount of Auc purchased and burned with the fee.
     */
    event Finish(address indexed user, uint256 totalRedeemed, uint256 yield, uint256 fee, uint256 totalAucBurned);
    
    /**
     * @dev Emitted when the contract is initialized with a previous data due to a proxy migration.
     * @param previousContract The previous contract address.
     */
    event SetMigration(address previousContract);

    /**
     * @dev The ERC20 token address on the chain or '0x0' for Ethereum. 
     * It is the asset for the respective contract. 
     */
    address public tokenAddress;
    
    /**
     * @dev Minimum time in seconds between executions to run the Compound redeem.
     */
    uint256 public minimumTimeBetweenExecutions;
    
    /**
     * @dev Last Compound redeem execution Id (it is an incremental number).
     */
    uint256 public executionId;
    
    /**
     * @dev The total balance of Dai deposited.
     */
    uint256 public totalBalance;
    
    /**
     * @dev The amount of deposited Dai that has a fee exemption due to the Auc escrowed.
     */
    uint256 public feeExemptionAmountForAucEscrowed;
    
    /**
     * @dev It indicates if the contract asset is the cDai.
     */
    bool public isCompound;
    
    /**
     * @dev The difference between the amount of Dai deposited and the respective value normalized to the last Compound redeem execution time.
     * _key is the execution Id.
     * _value is the difference of Dai.
     */
    mapping(uint256 => uint256) public totalBalanceNormalizedDifference;
    
    /**
     * @dev The difference between the amount of Dai with fee exemption and the respective value normalized to the last Compound redeem execution time.
     * _key is the execution Id.
     * _value is the difference of Dai.
     */
    mapping(uint256 => uint256) public feeExemptionNormalizedDifference;
    
    /**
     * @dev The remaining profit redeemed from Compound.
     * Used on Compound asset to adjust the remaining value on the contract between executions.
     * _key is the execution Id.
     * _value is the redeemed value.
     */
    mapping(uint256 => uint256) public remainingValueRedeemed;
    
    /**
     * @dev The amount of Dai that has a fee exemption for the respective execution due to the user deposit time.
     * _key is the execution Id.
     * _value is the amount of Dai.
     * The user amount of Dai proportion is calculated based on the difference between the deposit time and the next execution time.
     */
    mapping(uint256 => uint256) public feeExemptionAmountForUserBaseData;
    
    /**
     * @dev The Compound redeem executions data.
     * _key is the execution Id.
     * _value is the execution data.
     */
    mapping(uint256 => Execution) public executions;
    
    /**
     * @dev The user data for the asset.
     * _key is the user address.
     * _value is the user data.
     */
    mapping(address => UserData) public usersData;
}
"},"DPiggyAssetProxy.sol":{"content":"pragma solidity ^0.6.4;

import "DPiggyBaseProxy.sol";
import "DPiggyAssetData.sol";

/**
 * @title DPiggyAssetProxy
 * @dev A proxy contract for dPiggy asset.
 * It must inherit first from DPiggyBaseProxy contract for properly works.
 * The stored data is on DPiggyAssetData contract.
 */
contract DPiggyAssetProxy is DPiggyBaseProxy, DPiggyAssetData {
    constructor(
        address _admin, 
        address _implementation, 
        bytes memory data
    ) public payable DPiggyBaseProxy(_admin, _implementation, data) {
    } 
}"},"DPiggyBaseProxy.sol":{"content":"pragma solidity ^0.6.4;

import "Address.sol";
import "DPiggyBaseProxyData.sol";
import "DPiggyBaseProxyInterface.sol";

/**
 * @title DPiggyBaseProxy
 * @dev A proxy contract that implements delegation of calls to other contracts.
 * The stored data is on DPiggyBaseProxyData contract.
 */
contract DPiggyBaseProxy is DPiggyBaseProxyData, DPiggyBaseProxyInterface {

    constructor(address _admin, address _implementation, bytes memory data) public payable {
        admin = _admin;
        _setImplementation(_implementation, data);
    } 
  
    /**
     * @dev Fallback function that delegates the execution to an implementation contract.
     */
    fallback() external payable {
        address addr = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
  
    /**
     * @dev Function to be compliance with EIP 897.
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-897.md
     * It is an "upgradable proxy".
     */
    function proxyType() public pure returns(uint256) {
        return 2; 
    }
    
    /**
     * @dev Function to set the proxy implementation address.
     * Only can be called by the proxy admin.
     * The implementation address must a contract.
     * @param newImplementation Address of the new proxy implementation.
     * @param data ABI encoded with signature data that will be delegated over the new implementation.
     */
    function setImplementation(address newImplementation, bytes calldata data) onlyAdmin external override(DPiggyBaseProxyInterface) payable {
        require(Address.isContract(newImplementation));
        address oldImplementation = implementation;
        _setImplementation(newImplementation, data);
        emit SetProxyImplementation(newImplementation, oldImplementation);
    }
    
    /**
     * @dev Function to set the proxy admin address.
     * Only can be called by the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function setAdmin(address newAdmin) onlyAdmin external override(DPiggyBaseProxyInterface) {
        require(newAdmin != address(0));
        address oldAdmin = admin;
        admin = newAdmin;
        emit SetProxyAdmin(newAdmin, oldAdmin);
    }
    
    /**
     * @dev Internal function to set the implementation address.
     * @param _implementation Address of the new proxy implementation.
     * @param data ABI encoded with signature data that will be delegated over the new implementation.
     */
    function _setImplementation(address _implementation, bytes memory data) internal {
        implementation = _implementation;
        if (data.length > 0) {
            (bool success,) = _implementation.delegatecall(data);
            assert(success);
        }
    }
}
"},"DPiggyBaseProxyData.sol":{"content":"pragma solidity ^0.6.4;

/**
 * @title DPiggyBaseProxyData
 * @dev Contract for all DPiggyBaseProxyData stored data.
 */
contract DPiggyBaseProxyData {
    
    /**
     * @dev Emitted when the proxy implementation has been changed.
     * @param newImplementation Address of the new proxy implementation.
     * @param oldImplementation Address of the previous proxy implementation.
     */
    event SetProxyImplementation(address indexed newImplementation, address oldImplementation);
    
    /**
     * @dev Emitted when the admin address has been changed.
     * @param newAdmin Address of the new admin.
     * @param oldAdmin Address of the previous admin.
     */
    event SetProxyAdmin(address indexed newAdmin, address oldAdmin);
    
    /**
     * @dev Modifier to check if the `msg.sender` is the admin.
     * Only admin address can execute.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    /**
     * @dev The contract address of the implementation.
     */
    address public implementation;
    
    /**
     * @dev The admin address.
     */
    address public admin;
}
"},"DPiggyBaseProxyInterface.sol":{"content":"pragma solidity ^0.6.4;

/**
 * @title DPiggyBaseProxyInterface
 * @dev DPiggyBaseProxy interface with external functions.
 */
interface DPiggyBaseProxyInterface {
    function setImplementation(address newImplementation, bytes calldata data) external payable;
    function setAdmin(address newAdmin) external;
}"},"ReentrancyGuard.sol":{"content":"pragma solidity ^0.6.4;

/**
 * @title ReentrancyGuard
 * @dev Base contract with a modifier that implements a reentrancy guard.
 */
contract ReentrancyGuard {
    /**
     * @dev Internal data to control the reentrancy.
     */
    bool internal _notEntered;

    /**
     * @dev Modifier to prevents a contract from calling itself during the function execution.
     */
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard:: reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}"}}