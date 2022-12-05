{"Address.sol":{"content":"pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"},"Counters.sol":{"content":"pragma solidity ^0.6.0;

import "./SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}
"},"GelatoCore.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoCore.sol";
import "./GelatoUserProxyManager.sol";
import "./GelatoCoreAccounting.sol";
import "./Counters.sol";

/// @title GelatoCore
/// @notice Execution Claim: minting, checking, execution, and cancellation
/// @dev Find all NatSpecs inside IGelatoCore
contract GelatoCore is IGelatoCore, GelatoUserProxyManager, GelatoCoreAccounting {

    // Library for unique ExecutionClaimIds
    using Counters for Counters.Counter;
    using Address for address payable;  /// for oz's sendValue method

    // ================  STATE VARIABLES ======================================
    Counters.Counter private executionClaimIds;
    // executionClaimId => userProxyWithExecutionClaimId
    mapping(uint256 => IGelatoUserProxy) public override userProxyWithExecutionClaimId;
    // executionClaimId => bytes32 executionClaimHash
    mapping(uint256 => bytes32) public override executionClaimHash;

    // ================  MINTING ==============================================
    function mintExecutionClaim(
        address _selectedExecutor,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector
    )
        external
        payable
        override
        onlyRegisteredExecutors(_selectedExecutor)
    {
        // ______ Authenticate msg.sender is proxied user or a proxy _______
        IGelatoUserProxy userProxy;
        if (_isUser(msg.sender)) userProxy = proxyByUser[msg.sender];
        else if (_isUserProxy(msg.sender)) userProxy = IGelatoUserProxy(msg.sender);
        // solhint-disable-next-line
        else revert("GelatoCore.mintExecutionClaim: msg.sender is not proxied");
        // =============
        // ______ Read Gas Values & Charge Minting Deposit _______________________
        uint256[3] memory conditionGasActionGasMinExecutionGas;
        {
            uint256 conditionGas = _condition.conditionGas();
            require(conditionGas != 0, "GelatoCore.mintExecutionClaim: 0 conditionGas");
            conditionGasActionGasMinExecutionGas[0] = conditionGas;

            uint256 actionGas = _action.actionGas();
            require(actionGas != 0, "GelatoCore.mintExecutionClaim: 0 actionGas");
            conditionGasActionGasMinExecutionGas[1] = actionGas;

            uint256 minExecutionGas = _getMinExecutionGas(conditionGas, actionGas);
            conditionGasActionGasMinExecutionGas[2] = minExecutionGas;

            require(
                msg.value == minExecutionGas.mul(executorPrice[_selectedExecutor]),
                "GelatoCore.mintExecutionClaim: msg.value failed"
            );
        }

        // =============
        // ______ Mint new executionClaim ______________________________________
        executionClaimIds.increment();
        uint256 executionClaimId = executionClaimIds.current();
        userProxyWithExecutionClaimId[executionClaimId] = userProxy;
        // =============
        // ______ ExecutionClaim Hashing ______________________________________
        uint256 executionClaimExpiryDate = now.add(executorClaimLifespan[_selectedExecutor]);

        // Include executionClaimId to avoid hash collisions
        executionClaimHash[executionClaimId] = _computeExecutionClaimHash(
            _selectedExecutor,
            executionClaimId,
            msg.sender, // user
            userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            conditionGasActionGasMinExecutionGas,
            executionClaimExpiryDate,
            msg.value
        );

        // =============
        emit LogExecutionClaimMinted(
            _selectedExecutor,
            executionClaimId,
            msg.sender,  // _user
            userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            conditionGasActionGasMinExecutionGas,
            executionClaimExpiryDate,
            msg.value
        );
    }

    // ================  CAN EXECUTE EXECUTOR API ============================
    function canExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        view
        override
        returns (GelatoCoreEnums.CanExecuteResults, uint8 reason)
    {
        return _canExecute(
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );
    }

    // ================  EXECUTE SUITE ======================================
    function execute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        override
    {
        return _execute(
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );
    }

    function cancelExecutionClaim(
        address _selectedExecutor,
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        override
    {
        bool executionClaimExpired = _executionClaimExpiryDate <= now;
        if (msg.sender != _user) {
            require(
                executionClaimExpired && msg.sender == _selectedExecutor,
                "GelatoCore.cancelExecutionClaim: msgSender problem"
            );
        }
        bytes32 computedExecutionClaimHash = _computeExecutionClaimHash(
            _selectedExecutor,
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );
        // Checks
        require(
            computedExecutionClaimHash == executionClaimHash[_executionClaimId],
            "GelatoCore.cancelExecutionClaim: hash compare failed"
        );
        // Effects
        delete userProxyWithExecutionClaimId[_executionClaimId];
        delete executionClaimHash[_executionClaimId];
        emit LogExecutionClaimCancelled(
            _executionClaimId,
            _user,
            msg.sender,
            executionClaimExpired
        );
        // Interactions
        msg.sender.sendValue(_mintingDeposit);
    }

    // ================  STATE READERS ======================================
    function getCurrentExecutionClaimId()
        external
        view
        override
        returns(uint256 currentId)
    {
        currentId = executionClaimIds.current();
    }

    function getUserWithExecutionClaimId(uint256 _executionClaimId)
        external
        view
        override
        returns(address)
    {
        IGelatoUserProxy userProxy = userProxyWithExecutionClaimId[_executionClaimId];
        return userByProxy[address(userProxy)];
    }


    // ================  CAN EXECUTE IMPLEMENTATION ==================================
    function _canExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes memory _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes memory _actionPayloadWithSelector,
        uint256[3] memory _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        private
        view
        returns (GelatoCoreEnums.CanExecuteResults, uint8 reason)
    {
        // _____________ Static CHECKS __________________________________________
        if (executionClaimHash[_executionClaimId] == bytes32(0)) {
            if (_executionClaimId <= executionClaimIds.current()) {
                return (
                    GelatoCoreEnums.CanExecuteResults.ExecutionClaimAlreadyExecutedOrCancelled,
                    uint8(GelatoCoreEnums.StandardReason.NotOk)
                );
            } else {
                return (
                    GelatoCoreEnums.CanExecuteResults.ExecutionClaimNonExistant,
                    uint8(GelatoCoreEnums.StandardReason.NotOk)
                );
            }
        }

        if (_executionClaimExpiryDate < now) {
            return (
                GelatoCoreEnums.CanExecuteResults.ExecutionClaimExpired,
                uint8(GelatoCoreEnums.StandardReason.NotOk)
            );
        }

        bytes32 computedExecutionClaimHash = _computeExecutionClaimHash(
            msg.sender,  // selected? executor
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );

        if (computedExecutionClaimHash != executionClaimHash[_executionClaimId]) {
            return (
                GelatoCoreEnums.CanExecuteResults.WrongCalldata,
                uint8(GelatoCoreEnums.StandardReason.NotOk)
            );
        }

        // _____________ Dynamic CHECKS __________________________________________
        // **** ConditionCheck *****
        (bool success, bytes memory returndata)
            = address(_condition).staticcall.gas(_conditionGasActionGasMinExecutionGas[0])(
                _conditionPayloadWithSelector
        );

        if (!success) {
            return (
                GelatoCoreEnums.CanExecuteResults.UnhandledConditionError,
                uint8(GelatoCoreEnums.StandardReason.UnhandledError)
            );
        } else {
            bool conditionReached;
            (conditionReached, reason) = abi.decode(returndata, (bool, uint8));
            if (!conditionReached) return (GelatoCoreEnums.CanExecuteResults.ConditionNotOk, reason);
            // Condition Reached
            else return (GelatoCoreEnums.CanExecuteResults.Executable, reason);
        }
    }

    // ================  EXECUTE IMPLEMENTATION ======================================
    function _execute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes memory _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes memory _actionPayloadWithSelector,
        uint256[3] memory _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        private
    {
        uint256 startGas = gasleft();
        require(
            startGas >= _conditionGasActionGasMinExecutionGas[2].sub(30000),
            "GelatoCore._execute: Insufficient gas sent"
        );

        // _______ canExecute() CHECK ______________________________________________
        {
            GelatoCoreEnums.CanExecuteResults canExecuteResult;
            uint8 canExecuteReason;
            (canExecuteResult, canExecuteReason) = _canExecute(
                _executionClaimId,
                _user,
                _userProxy,
                _condition,
                _conditionPayloadWithSelector,
                _action,
                _actionPayloadWithSelector,
                _conditionGasActionGasMinExecutionGas,
                _executionClaimExpiryDate,
                _mintingDeposit
            );

            if (canExecuteResult == GelatoCoreEnums.CanExecuteResults.Executable) {
                emit LogCanExecuteSuccess(
                    msg.sender,
                    _executionClaimId,
                    _user,
                    _condition,
                    canExecuteResult,
                    canExecuteReason
                );
            } else {
                emit LogCanExecuteFailed(
                    msg.sender,
                    _executionClaimId,
                    _user,
                    _condition,
                    canExecuteResult,
                    canExecuteReason
                );
                return;  // END OF EXECUTION
            }
        }

        // EFFECTS
        delete executionClaimHash[_executionClaimId];
        delete userProxyWithExecutionClaimId[_executionClaimId];

        // INTERACTIONS
        bool actionExecuted;
        string memory executionFailureReason;
        try _userProxy.delegatecallGelatoAction(
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas[1]
        ) {
            actionExecuted = true;
        } catch Error(string memory revertReason) {
            executionFailureReason = revertReason;
        } catch {
            executionFailureReason = "UnhandledUserProxyError";
        }

        if (actionExecuted) {
            emit LogSuccessfulExecution(
                msg.sender,  // executor
                _executionClaimId,
                _user,
                _condition,
                _action,
                tx.gasprice,
                // ExecutionCost Estimate: ignore fn call overhead, due to delete gas refunds
                (startGas.sub(gasleft())).mul(tx.gasprice),
                _mintingDeposit  // executorReward
            );
            // Executor gets full reward only if Execution was successful
            executorBalance[msg.sender] = executorBalance[msg.sender].add(_mintingDeposit);
        } else {
            address payable payableUser = address(uint160(_user));
            emit LogExecutionFailure(
                msg.sender,
                _executionClaimId,
                payableUser,
                _condition,
                _action,
                executionFailureReason
            );
            // Transfer Minting deposit back to user
            payableUser.sendValue(_mintingDeposit);
        }
    }

    // ================ EXECUTION CLAIM HASHING ========================================
    function _computeExecutionClaimHash(
        address _selectedExecutor,
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes memory _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes memory _actionPayloadWithSelector,
        uint256[3] memory _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        private
        pure
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _selectedExecutor,
                _executionClaimId,
                _user,
                _userProxy,
                _condition,
                _conditionPayloadWithSelector,
                _action,
                _actionPayloadWithSelector,
                _conditionGasActionGasMinExecutionGas,
                _executionClaimExpiryDate,
                _mintingDeposit
            )
        );
    }

    // ================ GAS BENCHMARKING ==============================================
    function gasTestConditionCheck(
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        uint256 _conditionGas
    )
        external
        view
        override
        returns(bool conditionReached, uint8 reason)
    {
        uint256 startGas = gasleft();
        /* solhint-disable indent */
        (bool success,
         bytes memory returndata) = address(_condition).staticcall.gas(_conditionGas)(
            _conditionPayloadWithSelector
        );
        /* solhint-enable indent */
        if (!success) revert("GelatoCore.gasTestConditionCheck: Unhandled Error/wrong Args");
        else (conditionReached, reason) = abi.decode(returndata, (bool, uint8));
        if (conditionReached) revert(string(abi.encodePacked(startGas - gasleft())));
        else revert("GelatoCore.gasTestConditionCheck: Not Executable/wrong Args");
    }

    function gasTestCanExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        view
        override
        returns (GelatoCoreEnums.CanExecuteResults canExecuteResult, uint8 reason)
    {
        uint256 startGas = gasleft();
        (canExecuteResult, reason) = _canExecute(
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );
        if (canExecuteResult == GelatoCoreEnums.CanExecuteResults.Executable)
            revert(string(abi.encodePacked(startGas - gasleft())));
        revert("GelatoCore.gasTestCanExecute: Not Executable/Wrong Args");
    }

    function gasTestActionViaGasTestUserProxy(
        IGelatoUserProxy _gasTestUserProxy,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        override
        gasTestProxyCheck(address(_gasTestUserProxy))
    {
        // Always reverts inside GelatoGasTestUserProxy.executeDelegateCall
        _gasTestUserProxy.delegatecallGelatoAction(
            _action,
            _actionPayloadWithSelector,
            _actionGas
        );
        revert("GelatoCore.gasTestActionViaGasTestUserProxy: did not revert");
    }

    function gasTestGasTestUserProxyExecute(
        IGelatoUserProxy _userProxy,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        override
        userProxyCheck(_userProxy)
    {
        uint256 startGas = gasleft();
        bool actionExecuted;
        string memory executionFailureReason;
        try _userProxy.delegatecallGelatoAction(
            _action,
            _actionPayloadWithSelector,
            _actionGas
        ) {
            actionExecuted = true;
            revert(string(abi.encodePacked(startGas - gasleft())));
        } catch Error(string memory reason) {
            executionFailureReason = reason;
            revert("GelatoCore.gasTestTestUserProxyExecute: Defined Error Caught");
        } catch {
            revert("GelatoCore.gasTestTestUserProxyExecute: Undefined Error Caught");
        }
    }

    function gasTestExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        override
    {
        uint256 startGas = gasleft();
        _execute(
            _executionClaimId,
            _user,
            _userProxy,
            _condition,
            _conditionPayloadWithSelector,
            _action,
            _actionPayloadWithSelector,
            _conditionGasActionGasMinExecutionGas,
            _executionClaimExpiryDate,
            _mintingDeposit
        );
        revert(string(abi.encodePacked(startGas - gasleft())));
    }
}"},"GelatoCoreAccounting.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoCoreAccounting.sol";
import "./Address.sol";
import "./SafeMath.sol";

/// @title GelatoCoreAccounting
/// @notice APIs for GelatoCore Owner and executorClaimLifespan
/// @dev Find all NatSpecs inside IGelatoCoreAccounting
abstract contract GelatoCoreAccounting is IGelatoCoreAccounting {

    using Address for address payable;  /// for oz's sendValue method
    using SafeMath for uint256;

    //_____________ Gelato Executor Economics _______________________
    mapping(address => uint256) public override executorPrice;
    mapping(address => uint256) public override executorClaimLifespan;
    mapping(address => uint256) public override executorBalance;
    // =========================
    // the minimum executionClaimLifespan imposed upon executors
    uint256 public constant override minExecutionClaimLifespan = 10 minutes;
    //_____________ Gas values for executionClaim cost calculations _______
    uint256 public constant override gelatoCoreExecGasOverhead = 80000;
    uint256 public constant override userProxyExecGasOverhead = 40000;
    uint256 public constant override totalExecutionGasOverhead = (
        gelatoCoreExecGasOverhead + userProxyExecGasOverhead
    );

    // __ Executor De/Registrations _______
    function registerExecutor(
        uint256 _executorPrice,
        uint256 _executorClaimLifespan
    )
        external
        override
    {
        require(
            _executorClaimLifespan >= minExecutionClaimLifespan,
            "GelatoCoreAccounting.registerExecutor: _executorClaimLifespan cannot be 0"
        );
        executorPrice[msg.sender] = _executorPrice;
        executorClaimLifespan[msg.sender] = _executorClaimLifespan;
        emit LogRegisterExecutor(
            msg.sender,
            _executorPrice,
            _executorClaimLifespan
        );
    }

    modifier onlyRegisteredExecutors(address _executor) {
        require(
            executorClaimLifespan[_executor] != 0,
            "GelatoCoreAccounting.onlyRegisteredExecutors: failed"
        );
        _;
    }

    function deregisterExecutor()
        external
        override
        onlyRegisteredExecutors(msg.sender)
    {
        executorPrice[msg.sender] = 0;
        executorClaimLifespan[msg.sender] = 0;
        emit LogDeregisterExecutor(msg.sender);
    }

    // __ Executor Economics _______
    function setExecutorPrice(uint256 _newExecutorGasPrice)
        external
        override
    {
        emit LogSetExecutorPrice(executorPrice[msg.sender], _newExecutorGasPrice);
        executorPrice[msg.sender] = _newExecutorGasPrice;
    }

    function setExecutorClaimLifespan(uint256 _newExecutorClaimLifespan)
        external
        override
    {
        require(
            _newExecutorClaimLifespan >= minExecutionClaimLifespan,
            "GelatoCoreAccounting.setExecutorClaimLifespan: failed"
        );
        emit LogSetExecutorClaimLifespan(
            executorClaimLifespan[msg.sender],
            _newExecutorClaimLifespan
        );
        executorClaimLifespan[msg.sender] = _newExecutorClaimLifespan;
    }

    function withdrawExecutorBalance()
        external
        override
    {
        // Checks
        uint256 currentExecutorBalance = executorBalance[msg.sender];
        require(
            currentExecutorBalance > 0,
            "GelatoCoreAccounting.withdrawExecutorBalance: failed"
        );
        // Effects
        executorBalance[msg.sender] = 0;
        // Interaction
        msg.sender.sendValue(currentExecutorBalance);
        emit LogWithdrawExecutorBalance(msg.sender, currentExecutorBalance);
    }

    // _______ APIs for executionClaim pricing ______________________________________
    function getMintingDepositPayable(
        address _selectedExecutor,
        IGelatoCondition _condition,
        IGelatoAction _action
    )
        external
        view
        override
        onlyRegisteredExecutors(_selectedExecutor)
        returns(uint256 mintingDepositPayable)
    {
        uint256 conditionGas = _condition.conditionGas();
        uint256 actionGas = _action.actionGas();
        uint256 executionMinGas = _getMinExecutionGas(conditionGas, actionGas);
        mintingDepositPayable = executionMinGas.mul(executorPrice[_selectedExecutor]);
    }

    function getMinExecutionGas(uint256 _conditionGas, uint256 _actionGas)
        external
        pure
        override
        returns(uint256)
    {
        return _getMinExecutionGas(_conditionGas, _actionGas);
    }

    function _getMinExecutionGas(uint256 _conditionGas, uint256 _actionGas)
        internal
        pure
        returns(uint256)
    {
        return totalExecutionGasOverhead.add(_conditionGas).add(_actionGas);
    }
    // =======
}"},"GelatoCoreEnums.sol":{"content":"pragma solidity ^0.6.0;

abstract contract GelatoCoreEnums {

    enum CanExecuteResults {
        ExecutionClaimAlreadyExecutedOrCancelled,
        ExecutionClaimNonExistant,
        ExecutionClaimExpired,
        WrongCalldata,  // also returns if a not-selected executor calls fn
        ConditionNotOk,
        UnhandledConditionError,
        Executable
    }

    // Not needed atm due to revert with string memory reason
    /* enum ExecutionResults {
        ActionGasNotOk,
        ActionNotOk,  // Mostly for caught/handled (by action) action errors
        DappNotOk,  // Mostly for caught/handled (by action) dapp errors
        UnhandledActionError,
        UnhandledUserProxyError,
        Success
    } */

    enum StandardReason { Ok, NotOk, UnhandledError }
}"},"GelatoGasTestUserProxy.sol":{"content":"pragma solidity ^0.6.0;

import "./GelatoUserProxy.sol";

contract GelatoGasTestUserProxy is GelatoUserProxy {

    constructor(address _user) public GelatoUserProxy(_user) {}

    function delegatecallGelatoAction(
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        payable
        override
        auth
        noZeroAddress(address(_action))
    {
        uint256 startGas = gasleft();

        // Return if insufficient actionGas (+ 210000 gas overhead buffer) is sent
        if (gasleft() < _actionGas + 21000)
            revert("GelatoGasTestUserProxy.delegatecallGelatoAction: actionGas failed");

        // Low level try / catch (fails if gasleft() < _actionGas)
        (bool success,
         bytes memory revertReason) = address(_action).delegatecall.gas(_actionGas)(
            _actionPayloadWithSelector
        );
        // Unhandled errors during action execution
        if (!success) {
            // error during action execution
            revertReason;  // silence compiler warning
            revert("GelatoGasTestUserProxy.delegatecallGelatoAction: unsuccessful");
        } else { // success
            revert(string(abi.encodePacked(startGas - gasleft())));
        }
    }
}"},"GelatoGasTestUserProxyManager.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoGasTestUserProxyManager.sol";
import "./GelatoGasTestUserProxy.sol";

abstract contract GelatoGasTestUserProxyManager is IGelatoGasTestUserProxyManager {

    mapping(address => address) public override userByGasTestProxy;
    mapping(address => address) public override gasTestProxyByUser;

    modifier gasTestProxyCheck(address _) {
        require(_isGasTestProxy(_), "GelatoGasTestUserProxyManager.isGasTestProxy");
        _;
    }

    function createGasTestUserProxy()
        external
        override
        returns(address gasTestUserProxy)
    {
        gasTestUserProxy = address(new GelatoGasTestUserProxy(msg.sender));
        userByGasTestProxy[msg.sender] = gasTestUserProxy;
        gasTestProxyByUser[gasTestUserProxy] = msg.sender;
    }

    function _isGasTestProxy(address _) private view returns(bool) {
        return gasTestProxyByUser[_] != address(0);
    }
}"},"GelatoUserProxy.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoUserProxy.sol";
import "./IGelatoAction.sol";

/// @title GelatoUserProxy
/// @dev find all NatSpecs inside IGelatoUserProxy
contract GelatoUserProxy is IGelatoUserProxy {
    address public override user;
    address public override gelatoCore;

    constructor(address _user)
        public
        noZeroAddress(_user)
    {
        user = _user;
        gelatoCore = msg.sender;
    }

    modifier onlyUser() {
        require(
            msg.sender == user,
            "GelatoUserProxy.onlyUser: failed"
        );
        _;
    }

    modifier auth() {
        require(
            msg.sender == user || msg.sender == gelatoCore,
            "GelatoUserProxy.auth: failed"
        );
        _;
    }

    modifier noZeroAddress(address _) {
        require(
            _ != address(0),
            "GelatoUserProxy.noZeroAddress"
        );
        _;
    }

    function callAccount(address _account, bytes calldata _payload)
        external
        payable
        override
        onlyUser
        noZeroAddress(_account)
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _account.call(_payload);
        require(success, "GelatoUserProxy.call(): failed");
    }

    function delegatecallAccount(address _account, bytes calldata _payload)
        external
        payable
        override
        onlyUser
        noZeroAddress(_account)
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _account.delegatecall(_payload);
        require(success, "GelatoUserProxy.delegatecall(): failed");
    }

    function delegatecallGelatoAction(
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        payable
        override
        virtual
        auth
        noZeroAddress(address(_action))
    {
        // Return if insufficient actionGas (+ 210000 gas overhead buffer) is sent
        if (gasleft() < _actionGas + 21000) revert("GelatoUserProxy: ActionGasNotOk");
        // No try/catch, in order to bubble up action revert messages
        (bool success,
         bytes memory revertReason) = address(_action).delegatecall.gas(_actionGas)(
             _actionPayloadWithSelector
        );
        assembly {
            revertReason := add(revertReason, 68)
        }
        if (!success) revert(string(revertReason));
    }
}"},"GelatoUserProxyManager.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoUserProxyManager.sol";
import "./GelatoGasTestUserProxyManager.sol";

/// @title GelatoUserProxyManager
/// @notice registry and factory for GelatoUserProxies
/// @dev find all NatSpecs inside IGelatoUserProxyManager
abstract contract GelatoUserProxyManager is IGelatoUserProxyManager, GelatoGasTestUserProxyManager {

    uint256 public override userCount;
    mapping(address => address) public override userByProxy;
    mapping(address => IGelatoUserProxy) public override proxyByUser;
    // public override doesnt work for storage arrays
    address[] public users;
    IGelatoUserProxy[] public userProxies;

    modifier userHasNoProxy {
        require(
            userByProxy[msg.sender] == address(0),
            "GelatoUserProxyManager: user already has a proxy"
        );
        _;
    }

    modifier userProxyCheck(IGelatoUserProxy _userProxy) {
        require(
            _isUserProxy(address(_userProxy)),
            "GelatoUserProxyManager.userProxyCheck: _userProxy not registered"
        );
        _;
    }

    function createUserProxy()
        external
        override
        userHasNoProxy
        returns(IGelatoUserProxy userProxy)
    {
        userProxy = new GelatoUserProxy(msg.sender);
        userByProxy[address(userProxy)] = msg.sender;
        proxyByUser[msg.sender] = userProxy;
        users.push(msg.sender);
        userProxies.push(userProxy);
        userCount++;
        emit LogCreateUserProxy(userProxy, msg.sender);
    }

    // ______ State Read APIs __________________
    function isUser(address _user)
        external
        view
        override
        returns(bool)
    {
        return _isUser(_user);
    }

    function isUserProxy(address _userProxy)
        external
        view
        override
        returns(bool)
    {
        return _isUserProxy(_userProxy);
    }

    // ______________ State Readers ______________________________________
    function _isUser(address _user)
        internal
        view
        returns(bool)
    {
        return proxyByUser[_user] != IGelatoUserProxy(0);
    }

    function _isUserProxy(address _userProxy)
        internal
        view
        returns(bool)
    {
        return userByProxy[_userProxy] != address(0);
    }
    // =========================
}
"},"IGelatoAction.sol":{"content":"pragma solidity ^0.6.0;

/// @title IGelatoAction - solidity interface of GelatoActionsStandard
/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    function actionSelector() external pure returns(bytes4);
    function actionGas() external pure returns(uint256);

    /* CAUTION: all actions must have their action() function according to the
    following standard format:
        function action(
            address _user,
            address _userProxy,
            address _source,
            uint256 _sourceAmount,
            address _destination,
            ...
        )
            external;
    action function not defined here because non-overridable, due to
    different arguments passed across different actions
    */

    /**
     * @notice Returns whether the action-specific conditions are fulfilled
     * @dev if actions have specific conditions they should override and extend this fn
     * @param _actionPayloadWithSelector: the actionPayload (with actionSelector)
     * @return actionCondition
     */
    function actionConditionsCheck(bytes calldata _actionPayloadWithSelector)
        external
        view
        returns(string memory);

    /// All actions must override this with their own implementation
    /*function getUsersSendTokenBalance(
        address _user,
        address _userProxy,
        address _source,
        uint256 _sourceAmount,
        address _destination,
        ...
    )
        external
        view
        override
        virtual
        returns(uint256 userSrcBalance);
    getUsersSendTokenBalance not defined here because non-overridable, due to
    different arguments passed across different actions
    */
}"},"IGelatoCondition.sol":{"content":"pragma solidity ^0.6.0;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {
    /* CAUTION All Conditions must reserve the first 3 fields of their `enum Reason` as such:
        0: Ok,  // 0: standard field for Fulfilled Conditions and No Errors
        1: NotOk,  // 1: standard field for Unfulfilled Conditions or Handled Errors
        2: UnhandledError  // 2: standard field for Unhandled or Uncaught Errors
    */

    /* CAUTION: the following functions are part of the standard IGelatoCondition interface but cannot be overriden
        - "function reached(args) external view": non-standardisable due to different arguments passed across different conditions
        - "function getConditionValue(same args as reached function) external view/pure": always takes same args as reached()
    */

    function conditionSelector() external pure returns(bytes4);
    function conditionGas() external pure returns(uint256);
}"},"IGelatoCore.sol":{"content":"pragma solidity ^0.6.0;

import "./GelatoCoreEnums.sol";
import "./IGelatoUserProxy.sol";
import "./IGelatoCondition.sol";
import "./IGelatoAction.sol";

/// @title IGelatoCore - solidity interface of GelatoCore
/// @notice canExecute API and minting, execution, cancellation of ExecutionClaims
/// @dev all the APIs and events are implemented inside GelatoCore
interface IGelatoCore {

    event LogExecutionClaimMinted(
        address indexed selectedExecutor,
        uint256 indexed executionClaimId,
        address indexed user,
        IGelatoUserProxy userProxy,
        IGelatoCondition condition,
        bytes conditionPayloadWithSelector,
        IGelatoAction action,
        bytes actionPayloadWithSelector,
        uint256[3] conditionGasActionTotalGasMinExecutionGas,
        uint256 executionClaimExpiryDate,
        uint256 mintingDeposit
    );

    // Caution: there are no guarantees that CanExecuteResult and/or reason
    //  are implemented in a logical fashion by condition/action developers.
    event LogCanExecuteSuccess(
        address indexed executor,
        uint256 indexed executionClaimId,
        address indexed user,
        IGelatoCondition condition,
        GelatoCoreEnums.CanExecuteResults canExecuteResult,
        uint8 reason
    );

    event LogCanExecuteFailed(
        address indexed executor,
        uint256 indexed executionClaimId,
        address indexed user,
        IGelatoCondition condition,
        GelatoCoreEnums.CanExecuteResults canExecuteResult,
        uint8 reason
    );

    event LogSuccessfulExecution(
        address indexed executor,
        uint256 indexed executionClaimId,
        address indexed user,
        IGelatoCondition condition,
        IGelatoAction action,
        uint256 gasPriceUsed,
        uint256 executionCostEstimate,
        uint256 executorReward
    );

    // Caution: there are no guarantees that ExecutionResult and/or reason
    //  are implemented in a logical fashion by condition/action developers.
    event LogExecutionFailure(
        address indexed executor,
        uint256 indexed executionClaimId,
        address payable indexed user,
        IGelatoCondition condition,
        IGelatoAction action,
        string executionFailureReason
    );

    event LogExecutionClaimCancelled(
        uint256 indexed executionClaimId,
        address indexed user,
        address indexed cancelor,
        bool executionClaimExpired
    );

    /**
     * @dev API for minting execution claims on gelatoCore
     * @notice re-entrancy guard because accounting ops are present inside fn
     * @notice msg.value is a refundable deposit - only a fee if executed
     * @notice minting event split into two, due to stack too deep issue
     */
    function mintExecutionClaim(
        address _selectedExecutor,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector
    )
        external
        payable;

    /**
     * @notice If return value == 6, the claim is executable
     * @dev The API for executors to check whether a claim is executable.
     *       Caution: there are no guarantees that CanExecuteResult and/or reason
     *       are implemented in a logical fashion by condition/action developers.
     * @return GelatoCoreEnums.CanExecuteResults The outcome of the canExecuteCheck
     * @return reason The reason for the outcome of the canExecute Check
     */
    function canExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionTotalGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        view
        returns (GelatoCoreEnums.CanExecuteResults, uint8 reason);


    /**
     * @notice the API executors call when they execute an executionClaim
     * @dev if return value == 0 the claim got executed
     */
    function execute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionTotalGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external;

    /**
     * @dev API for canceling executionClaims
     * @notice re-entrancy protection due to accounting operations and interactions
     * @notice prior to executionClaim expiry, only owner of _userProxy can cancel
        for a refund. Post executionClaim expiry, _selectedExecutor can also cancel,
        for a reward.
     * @notice .sendValue instead of .transfer due to IstanbulHF
     */
    function cancelExecutionClaim(
        address _selectedExecutor,
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionTotalGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external;

    /// @dev get the current executionClaimId
    /// @return currentId uint256 current executionClaim Id
    function getCurrentExecutionClaimId() external view returns(uint256 currentId);

    /// @dev api to read from the userProxyByExecutionClaimId state variable
    /// @param _executionClaimId TO DO
    /// @return address of the userProxy behind _executionClaimId
    function userProxyWithExecutionClaimId(uint256 _executionClaimId)
        external
        view
        returns(IGelatoUserProxy);

    function getUserWithExecutionClaimId(uint256 _executionClaimId)
        external
        view
        returns(address);

    /// @dev interface to read from the hashedExecutionClaims state variable
    /// @param _executionClaimId TO DO
    /// @return the bytes32 hash of the executionClaim with _executionClaimId
    function executionClaimHash(uint256 _executionClaimId)
        external
        view
        returns(bytes32);

    // = GAS_BENCHMARKING ==============
    function gasTestConditionCheck(
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        uint256 _conditionGas
    )
        external
        view
        returns(bool executable, uint8 reason);

    function gasTestCanExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionTotalGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external
        view
        returns (GelatoCoreEnums.CanExecuteResults canExecuteResult, uint8 reason);

    function gasTestActionViaGasTestUserProxy(
        IGelatoUserProxy _gasTestUserProxy,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external;

    function gasTestGasTestUserProxyExecute(
        IGelatoUserProxy _userProxy,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external;

    function gasTestExecute(
        uint256 _executionClaimId,
        address _user,
        IGelatoUserProxy _userProxy,
        IGelatoCondition _condition,
        bytes calldata _conditionPayloadWithSelector,
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256[3] calldata _conditionGasActionTotalGasMinExecutionGas,
        uint256 _executionClaimExpiryDate,
        uint256 _mintingDeposit
    )
        external;
}"},"IGelatoCoreAccounting.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoCondition.sol";
import "./IGelatoAction.sol";

/// @title IGelatoCoreAccounting - solidity interface of GelatoCoreAccounting
/// @notice APIs for GelatoCore Owners and Executors
/// @dev all the APIs and events are implemented inside GelatoCoreAccounting
interface IGelatoCoreAccounting {

    event LogRegisterExecutor(
        address payable indexed executor,
        uint256 executorPrice,
        uint256 executorClaimLifespan
    );

    event LogDeregisterExecutor(address payable indexed executor);

    event LogSetExecutorPrice(uint256 executorPrice, uint256 newExecutorPrice);

    event LogSetExecutorClaimLifespan(
        uint256 executorClaimLifespan,
        uint256 newExecutorClaimLifespan
    );

    event LogWithdrawExecutorBalance(
        address indexed executor,
        uint256 withdrawAmount
    );

    event LogSetMinExecutionClaimLifespan(
        uint256 minExecutionClaimLifespan,
        uint256 newMinExecutionClaimLifespan
    );

    event LogSetGelatoCoreExecGasOverhead(
        uint256 gelatoCoreExecGasOverhead,
        uint256 _newGasOverhead
    );

    event LogSetUserProxyExecGasOverhead(
        uint256 userProxyExecGasOverhead,
        uint256 _newGasOverhead
    );

    /**
     * @dev fn to register as an executorClaimLifespan
     * @param _executorPrice the price factor the executor charges for its services
     * @param _executorClaimLifespan the lifespan of claims minted for this executor
     * @notice while executorPrice could be 0, executorClaimLifespan must be at least
       what the core protocol defines as the minimum (e.g. 10 minutes).
     * @notice NEW
     */
    function registerExecutor(uint256 _executorPrice, uint256 _executorClaimLifespan) external;

    /**
     * @dev fn to deregister as an executor
     * @notice ideally this fn is called by all executors as soon as they stop
       running their node/business. However, this behavior cannot be enforced.
       Frontends/Minters have to monitor executors' uptime themselves, in order to
       determine which listed executors are alive and have strong service guarantees.
     */
    function deregisterExecutor() external;

    /**
     * @dev fn for executors to configure their pricing of claims minted for them
     * @param _newExecutorGasPrice the new price to be listed for the executor
     * @notice param can be 0 for executors that operate pro bono - caution:
        if executors set their price to 0 then they get nothing, not even gas refunds.
     */
    function setExecutorPrice(uint256 _newExecutorGasPrice) external;

    /**
     * @dev fn for executors to configure the lifespan of claims minted for them
     * @param _newExecutorClaimLifespan the new lifespan to be listed for the executor
     * @notice param cannot be 0 - use deregisterExecutor() to deregister
     */
    function setExecutorClaimLifespan(uint256 _newExecutorClaimLifespan) external;

    /**
     * @dev function for executors to withdraw their ETH on core
     * @notice funds withdrawal => re-entrancy protection.
     * @notice new: we use .sendValue instead of .transfer due to IstanbulHF
     */
    function withdrawExecutorBalance() external;

    /// @dev get the gelato-wide minimum executionClaim lifespan
    /// @return the minimum executionClaim lifespan for all executors
    function minExecutionClaimLifespan() external view returns(uint256);

    /// @dev get an executor's price
    /// @param _executor TO DO
    /// @return uint256 executor's price factor
    function executorPrice(address _executor) external view returns(uint256);

    /// @dev get an executor's executionClaim lifespan
    /// @param _executor TO DO
    /// @return uint256 executor's executionClaim lifespan
    function executorClaimLifespan(address _executor) external view returns(uint256);

    /// @dev get the gelato-internal wei balance of an executor
    /// @param _executor z
    /// @return uint256 wei amount of _executor's gelato-internal deposit
    function executorBalance(address _executor) external view returns(uint256);

    /// @dev getter for gelatoCoreExecGasOverhead state variable
    /// @return uint256 gelatoCoreExecGasOverhead
    function gelatoCoreExecGasOverhead() external pure returns(uint256);

    /// @dev getter for userProxyExecGasOverhead state variable
    /// @return uint256 userProxyExecGasOverhead
    function userProxyExecGasOverhead() external pure returns(uint256);

    /// @dev getter for internalExecutionGas state variable
    /// @return uint256 internalExecutionGas
    function totalExecutionGasOverhead() external pure returns(uint256);

    /**
     * @dev get the deposit payable for minting on gelatoCore
     * @param _action the action contract to be executed
     * @param _selectedExecutor the executor that should call the action
     * @return mintingDepositPayable wei amount to deposit on GelatoCore for minting
     * @notice minters (e.g. frontends) should use this API to get the msg.value
       payable to GelatoCore's mintExecutionClaim function.
     */
    function getMintingDepositPayable(
        address _selectedExecutor,
        IGelatoCondition _condition,
        IGelatoAction _action
    )
        external
        view
        returns(uint256 mintingDepositPayable);

    /// @dev calculates gas requirements based off _actionGasTotal
    /// @param _conditionGas the gas forwared to condition.staticcall inside gelatoCore.execute
    /// @param _actionGas the gas forwarded with the action call
    /// @return the minimum gas required for calls to gelatoCore.execute()
    function getMinExecutionGas(uint256 _conditionGas, uint256 _actionGas)
        external
        pure
        returns(uint256);
}"},"IGelatoGasTestUserProxyManager.sol":{"content":"pragma solidity ^0.6.0;


interface IGelatoGasTestUserProxyManager {
    function createGasTestUserProxy() external returns(address gasTestUserProxy);
    function userByGasTestProxy(address _user) external view returns(address);
    function gasTestProxyByUser(address _gasTestProxy) external view returns(address);
}"},"IGelatoUserProxy.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoAction.sol";
import "./GelatoCoreEnums.sol";

/// @title IGelatoUserProxy - solidity interface of GelatoConditionsStandard
/// @notice GelatoUserProxy.execute() API called by gelatoCore during .execute()
/// @dev all the APIs are implemented inside GelatoUserProxy
interface IGelatoUserProxy {
    function callAccount(address, bytes calldata) external payable returns(bool, bytes memory);
    function delegatecallAccount(address, bytes calldata) external payable returns(bool, bytes memory);

    function delegatecallGelatoAction(
        IGelatoAction _action,
        bytes calldata _actionPayloadWithSelector,
        uint256 _actionGas
    )
        external
        payable;

    function user() external view returns(address);
    function gelatoCore() external view returns(address);
}"},"IGelatoUserProxyManager.sol":{"content":"pragma solidity ^0.6.0;

import "./IGelatoUserProxy.sol";

/// @title IGelatoUserProxyManager - solidity interface of GelatoUserProxyManager
/// @notice APIs for GelatoUserProxy creation and registry.
/// @dev all the APIs and events are implemented inside GelatoUserProxyManager
interface IGelatoUserProxyManager {
    event LogCreateUserProxy(IGelatoUserProxy indexed userProxy, address indexed user);

    /// @notice deploys gelato proxy for users that have no proxy yet
    /// @dev This function should be called for users that have nothing deployed yet
    /// @return address of the deployed GelatoUserProxy
    function createUserProxy() external returns(IGelatoUserProxy);

    // ______ State Read APIs __________________
    function userCount() external view returns(uint256);
    function userByProxy(address _userProxy) external view returns(address);
    function proxyByUser(address _user) external view returns(IGelatoUserProxy);
    function isUser(address _user) external view returns(bool);
    function isUserProxy(address _userProxy) external view returns(bool);
    //function users() external view returns(address[] memory);
    //function userProxies() external view returns(IGelatoUserProxy[] memory);
    // =========================
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.6.0;

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
"}}