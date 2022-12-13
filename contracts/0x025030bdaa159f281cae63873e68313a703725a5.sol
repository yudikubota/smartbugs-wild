{{
  "language": "Solidity",
  "sources": {
    "contracts/dapp_interfaces/gnosis/IBatchExchange.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

struct Order {
        uint16 buyToken;
        uint16 sellToken;
        uint32 validFrom; // order is valid from auction collection period: validFrom inclusive
        uint32 validUntil; // order is valid till auction collection period: validUntil inclusive
        uint128 priceNumerator;
        uint128 priceDenominator;
        uint128 usedAmount; // remainingAmount = priceDenominator - usedAmount
}

interface IBatchExchange {

    function withdraw(address user, address token)
        external;

    function deposit(address token, uint256 amount)
        external;

    function getPendingWithdraw(address user, address token)
        external
        view
        returns (uint256, uint32);

    function getCurrentBatchId()
        external
        view
        returns (uint32);

    function hasValidWithdrawRequest(address user, address token)
        external
        view
        returns (bool);

    function tokenAddressToIdMap(address addr)
        external
        view
        returns (uint16);

    function orders(address userAddress)
        external
        view
        returns (Order[] memory);


    // Returns orderId
    function placeOrder(uint16 buyToken, uint16 sellToken, uint32 validUntil, uint128 buyAmount, uint128 sellAmount)
        external
        returns (uint256);

    function requestFutureWithdraw(address token, uint256 amount, uint32 batchId)
        external;

    function requestWithdraw(address token, uint256 amount)
        external;

}
"
    },
    "contracts/gelato_conditions/gnosis/ConditionBatchExchangeWithdrawStateful.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "../GelatoStatefulConditionsStandard.sol";
import "../../dapp_interfaces/gnosis/IBatchExchange.sol";
import {IGelatoCore} from "../../gelato_core/interfaces/IGelatoCore.sol";

contract ConditionBatchExchangeWithdrawStateful is GelatoStatefulConditionsStandard {


    constructor(IGelatoCore _gelatoCore) GelatoStatefulConditionsStandard(_gelatoCore)
        public
        {}

    // userProxy => taskReceiptId => refBatchId
    mapping(address => mapping(uint256 => uint256)) public refBatchId;

    uint32 public constant BATCH_TIME = 300;

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(address _userProxy)
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(this.checkRefBatchId.selector, uint256(0), _userProxy);
    }

    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        address userProxy = abi.decode(_conditionData[36:], (address));
        return checkRefBatchId(_taskReceiptId, userProxy);
    }

    // Specific Implementation
    /// @dev Abi encode these parameter inputs. Use a placeholder for _taskReceiptId.
    /// @param _taskReceiptId Will be stripped from encoded data and replaced by
    ///  the value passed in from GelatoCore.
    function checkRefBatchId(uint256 _taskReceiptId, address _userProxy)
        public
        view
        virtual
        returns(string memory)
    {
        uint256 _refBatchId = refBatchId[_userProxy][_taskReceiptId];
        uint256 currentBatchId = uint32(block.timestamp / BATCH_TIME);
        if (_refBatchId < currentBatchId) return OK;
        return "NotOkBatchIdDidNotPass";
    }

    /// @dev This function should be called via the userProxy of a Gelato Task as part
    ///  of the Task.actions, if the Condition state should be updated after the task.
    /// This is for Task Cycles/Chains and we fetch the TaskReceipt.id of the
    //  next Task that will be auto-submitted by GelatoCore in the same exec Task transaction.
    function setRefBatchId(uint256 _delta, uint256 _idDelta) external {
        uint256 currentBatchId = uint32(block.timestamp / BATCH_TIME);
        uint256 newRefBatchId = currentBatchId + _delta;
        refBatchId[msg.sender][_getIdOfNextTaskInCycle() + _idDelta] = newRefBatchId;
    }
}"
    },
    "contracts/gelato_conditions/GelatoStatefulConditionsStandard.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./GelatoConditionsStandard.sol";
import {IGelatoCore} from "../gelato_core/interfaces/IGelatoCore.sol";

abstract contract GelatoStatefulConditionsStandard is GelatoConditionsStandard {
    IGelatoCore public immutable gelatoCore;

    constructor(IGelatoCore _gelatoCore) public { gelatoCore = _gelatoCore; }

    function _getIdOfNextTaskInCycle() internal view returns(uint256 nextTaskReceiptId) {
        try gelatoCore.currentTaskReceiptId() returns(uint256 currentId) {
            nextTaskReceiptId = currentId + 1;
        } catch Error(string memory _err) {
            revert(
                string(abi.encodePacked(
                    "GelatoStatefulConditionsStandard._getIdOfNextTaskInCycle", _err
                ))
            );
        } catch {
            revert("GelatoStatefulConditionsStandard._getIdOfNextTaskInCycle:undefined");
        }
    }
}
"
    },
    "contracts/gelato_core/interfaces/IGelatoCore.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "../../gelato_provider_modules/IGelatoProviderModule.sol";
import {IGelatoCondition} from "../../gelato_conditions/IGelatoCondition.sol";

struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    IGelatoProviderModule module;  //  can be IGelatoProviderModule(0) for self-Providers
}

struct Condition {
    IGelatoCondition inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

interface IGelatoCore {
    event LogTaskSubmitted(
        uint256 indexed taskReceiptId,
        bytes32 indexed taskReceiptHash,
        TaskReceipt taskReceipt
    );

    event LogExecSuccess(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorSuccessFee,
        uint256 sysAdminSuccessFee
    );
    event LogCanExecFailed(
        address indexed executor,
        uint256 indexed taskReceiptId,
        string reason
    );
    event LogExecReverted(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorRefund,
        string reason
    );

    event LogTaskCancelled(uint256 indexed taskReceiptId, address indexed cancellor);

    /// @notice API to query whether Task can be submitted successfully.
    /// @dev In submitTask the msg.sender must be the same as _userProxy here.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _userProxy The userProxy from which the task will be submitted.
    /// @param _task Selected provider, conditions, actions, expiry date of the task
    function canSubmitTask(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external
        view
        returns(string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @dev If _sumOfRequestedTaskSubmits = 1 && _tasks.length = 2, only the first task
    ///  would be submitted, but not the second
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    ///  that should have occured once the cycle is complete:
    ///  _sumOfRequestedTaskSubmits = 0 => One Task will resubmit the next Task infinitly
    ///  _sumOfRequestedTaskSubmits = 1 => One Task will resubmit no other task
    ///  _sumOfRequestedTaskSubmits = 2 => One Task will resubmit 1 other task
    ///  ...
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(TaskReceipt calldata _TR, uint256 _gasLimit, uint256 _execTxGasPrice)
        external
        view
        returns(string memory);

    /// @notice Executors call this when Conditions allow it to execute submitted Tasks.
    /// @dev Executors get rewarded for successful Execution. The Task remains open until
    ///   successfully executed, or when the execution failed, despite of gelatoMaxGas usage.
    ///   In the latter case Executors are refunded by the Task Provider.
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function exec(TaskReceipt calldata _TR) external;

    /// @notice Cancel task
    /// @dev Callable only by userProxy or selected provider
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel multiple tasks at once
    /// @dev Callable only by userProxy or selected provider
    /// @param _taskReceipts TaskReceipts: id, userProxy, Task.
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /// @notice Compute hash of task receipt
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @return hash of taskReceipt
    function hashTaskReceipt(TaskReceipt calldata _TR) external pure returns(bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns(uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId) external view returns(bytes32);
}
"
    },
    "contracts/gelato_conditions/GelatoConditionsStandard.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IGelatoCondition.sol";

abstract contract GelatoConditionsStandard is IGelatoCondition {
    string internal constant OK = "OK";
}
"
    },
    "contracts/gelato_conditions/IGelatoCondition.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {

    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256 _cycleId)
        external
        view
        returns(string memory);
}"
    },
    "contracts/gelato_provider_modules/IGelatoProviderModule.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {Action, Task} from "../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoProviderModule {

    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(address _userProxy, address _provider, Task calldata _task)
        external
        view
        returns(string memory);

    /// @notice Convert action specific payload into proxy specific payload
    /// @dev Encoded multiple actions into a multisend
    /// @param _taskReceiptId Unique ID of Gelato Task to be executed.
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @param _cycleId For Tasks that form part of a cycle/chain.
    /// @return Encoded payload that will be used for low-level .call on user proxy
    /// @return checkReturndata if true, fwd returndata from userProxy.call to ProviderModule
    function execPayload(
        uint256 _taskReceiptId,
        address _userProxy,
        address _provider,
        Task calldata _task,
        uint256 _cycleId
    )
        external
        view
        returns(bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
}
"
    },
    "contracts/user_proxies/gelato_user_proxy/GelatoUserProxyFactory.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoUserProxyFactory} from "./interfaces/IGelatoUserProxyFactory.sol";
import {Address} from "../../external/Address.sol";
import {GelatoUserProxy} from "./GelatoUserProxy.sol";
import {GelatoUserProxySet} from "../../libraries/GelatoUserProxySet.sol";
import {Action, Provider, Task} from "../../gelato_core/interfaces/IGelatoCore.sol";

contract GelatoUserProxyFactory is IGelatoUserProxyFactory {

    using Address for address payable;  /// for oz's sendValue method
    using GelatoUserProxySet for GelatoUserProxySet.Set;

    address public immutable override gelatoCore;

    mapping(GelatoUserProxy => address) public override userByGelatoProxy;
    mapping(address => GelatoUserProxySet.Set) private _gelatoProxiesByUser;

    constructor(address _gelatoCore) public { gelatoCore = _gelatoCore; }

    //  ==================== CREATE =======================================
    function create() public payable override returns (GelatoUserProxy userProxy) {
        userProxy = new GelatoUserProxy{value: msg.value}(msg.sender, gelatoCore);
        _storeGelatoUserProxy(userProxy);
    }

    function createExecActions(Action[] calldata _actions)
        external
        payable
        override
        returns (GelatoUserProxy userProxy)
    {
        userProxy = create();
        if (_actions.length != 0) _execActions(userProxy, _actions);
    }

    function createSubmitTasks(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        override
        returns (GelatoUserProxy userProxy)
    {
        userProxy = create();
        if (_tasks.length != 0) _submitTasks(userProxy, _provider, _tasks, _expiryDates);
    }

    function createExecActionsSubmitTasks(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = create();
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length != 0) _submitTasks(userProxy, _provider, _tasks, _expiryDates);
    }

    function createExecActionsSubmitTaskCycle(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = create();
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length == 0)
            revert("GelatoUserProxyFactory.createExecActionsSubmitTaskCycle: 0 _tasks");
        _submitTaskCycle(userProxy, _provider, _tasks, _expiryDate, _cycles);
    }

    function createExecActionsSubmitTaskChain(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = create();
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length == 0)
            revert("GelatoUserProxyFactory.createExecActionsSubmitTaskChain: 0 _tasks");
        _submitTaskChain(userProxy, _provider, _tasks, _expiryDate, _sumOfRequestedTaskSubmits);
    }

    //  ==================== CREATE 2 =======================================
    function createTwo(uint256 _saltNonce)
        public
        payable
        override
        returns (GelatoUserProxy userProxy)
    {
        bytes32 salt = keccak256(abi.encode(msg.sender, _saltNonce));
        userProxy = new GelatoUserProxy{salt: salt, value: msg.value}(msg.sender, gelatoCore);
        require(
            address(userProxy) == predictProxyAddress(msg.sender, _saltNonce),
            "GelatoUserProxyFactory.createTwo: wrong address prediction"
        );
        _storeGelatoUserProxy(userProxy);
    }

    function createTwoExecActions(uint256 _saltNonce, Action[] calldata _actions)
        external
        payable
        override
        returns (GelatoUserProxy userProxy)
    {
        userProxy = createTwo(_saltNonce);
        if (_actions.length != 0) _execActions(userProxy, _actions);
    }

    function createTwoSubmitTasks(
        uint256 _saltNonce,
        // Submit Tasks Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        override
        returns (GelatoUserProxy userProxy)
    {
        userProxy = createTwo(_saltNonce);
        if (_tasks.length != 0) _submitTasks(userProxy, _provider, _tasks, _expiryDates);
    }

    // A standard _saltNonce can be used for deterministic shared address derivation
    function createTwoExecActionsSubmitTasks(
        uint256 _saltNonce,
        Action[] calldata _actions,
        // Submit Tasks Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = createTwo(_saltNonce);
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length != 0) _submitTasks(userProxy, _provider, _tasks, _expiryDates);
    }

    function createTwoExecActionsSubmitTaskCycle(
        uint256 _saltNonce,
        Action[] calldata _actions,
        // Submit TaskCycle Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = createTwo(_saltNonce);
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length == 0)
            revert("GelatoUserProxyFactory.createTwoExecActionsSubmitTaskCycle: 0 _tasks");
        _submitTaskCycle(userProxy, _provider, _tasks, _expiryDate, _cycles);
    }

    function createTwoExecActionsSubmitTaskChain(
        uint256 _saltNonce,
        Action[] calldata _actions,
        // Submit TaskChain Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
        payable
        override
        returns(GelatoUserProxy userProxy)
    {
        userProxy = createTwo(_saltNonce);
        if (_actions.length != 0) _execActions(userProxy, _actions);
        if (_tasks.length == 0)
            revert("GelatoUserProxyFactory.createTwoExecActionsSubmitTaskChain: 0 _tasks");
        _submitTaskChain(userProxy, _provider, _tasks, _expiryDate, _sumOfRequestedTaskSubmits);
    }

    //  ==================== GETTERS =======================================
    function predictProxyAddress(address _user, uint256 _saltNonce)
        public
        view
        override
        returns(address)
    {
        // Standard Way of deriving salt
        bytes32 salt = keccak256(abi.encode(_user, _saltNonce));

        // Derive undeployed userProxy address
        return address(uint(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(proxyCreationCode(), abi.encode(_user, gelatoCore)))
        ))));
    }

    function isGelatoUserProxy(address _proxy) external view override returns(bool) {
        return userByGelatoProxy[GelatoUserProxy(payable(_proxy))] != address(0);
    }

    function isGelatoProxyUser(address _user, GelatoUserProxy _userProxy)
        external
        view
        override
        returns(bool)
    {
        return _gelatoProxiesByUser[_user].contains(_userProxy);
    }

    function gelatoProxiesByUser(address _user)
        external
        view
        override
        returns(GelatoUserProxy[] memory)
    {
        return _gelatoProxiesByUser[_user].enumerate();
    }

    function getGelatoUserProxyByIndex(address _user, uint256 _index)
        external
        view
        override
        returns(GelatoUserProxy)
    {
        return _gelatoProxiesByUser[_user].get(_index);
    }

    function proxyCreationCode() public pure override returns(bytes memory) {
        return type(GelatoUserProxy).creationCode;
    }

    //  ==================== HELPERS =======================================
    // store and emit LogCreation
    function _storeGelatoUserProxy(GelatoUserProxy _userProxy) private {
        _gelatoProxiesByUser[msg.sender].add(_userProxy);
        userByGelatoProxy[_userProxy] = msg.sender;
        emit LogCreation(msg.sender, _userProxy, msg.value);
    }

    function _execActions(GelatoUserProxy _userProxy, Action[] calldata _actions) private {
        try _userProxy.multiExecActions(_actions) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxyFactory._execActions:", err)));
        } catch {
            revert("GelatoUserProxyFactory._execActions:undefined");
        }
    }

    function _submitTasks(
        GelatoUserProxy _userProxy,
        // Submit Tasks Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        private
    {
        try _userProxy.multiSubmitTasks(_provider, _tasks, _expiryDates) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxyFactory._submitTasks:", err)));
        } catch {
            revert("GelatoUserProxyFactory._submitTasks:undefined");
        }
    }

    function _submitTaskCycle(
        GelatoUserProxy _userProxy,
        // Submit TaskCyle Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        private
    {
        try _userProxy.submitTaskCycle(_provider, _tasks, _expiryDate, _cycles) {
        } catch Error(string memory err) {
            revert(
                string(abi.encodePacked("GelatoUserProxyFactory._submitTaskCycle:", err))
            );
        } catch {
            revert("GelatoUserProxyFactory._submitTaskCycle:undefined");
        }
    }

    function _submitTaskChain(
        GelatoUserProxy _userProxy,
        // Submit TaskChain Data
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        private
    {
        try _userProxy.submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        ) {
        } catch Error(string memory err) {
            revert(
                string(abi.encodePacked("GelatoUserProxyFactory._submitTaskChain:", err))
            );
        } catch {
            revert("GelatoUserProxyFactory._submitTaskChain:undefined");
        }
    }
}
"
    },
    "contracts/user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxyFactory.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoUserProxy} from "../GelatoUserProxy.sol";
import {Action, Provider, Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoUserProxyFactory {
    event LogCreation(
        address indexed user,
        GelatoUserProxy indexed userProxy,
        uint256 funding
    );

    //  ==================== CREATE =======================================
    /// @notice Create a GelatoUserProxy.
    /// @return userProxy address of deployed proxy contract.
    function create()
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a GelatoUserProxy and exec actions
    /// @param _actions Optional actions to execute.
    /// @return userProxy address of deployed proxy contract.
    function createExecActions(Action[] calldata _actions)
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a GelatoUserProxy and submit Tasks to Gelato in the same tx.
    /// @param _provider Provider for each of the _tasks.
    /// @param _tasks Tasks to submit to Gelato. Must each have their own Provider.
    /// @param _expiryDates expiryDate for each of the _tasks.
    ///  CAUTION: The ordering of _tasks<=>_expiryDates must be coordinated.
    /// @return userProxy address of deployed proxy contract.
    function createSubmitTasks(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a GelatoUserProxy.
    /// @param _actions Optional actions to execute.
    /// @param _provider Provider for each of the _tasks.
    /// @param _tasks Tasks to submit to Gelato. Must each have their own Provider.
    /// @param _expiryDates expiryDate for each of the _tasks.
    ///  CAUTION: The ordering of _tasks<=>_expiryDates must be coordinated.
    /// @return userProxy address of deployed proxy contract.
    function createExecActionsSubmitTasks(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    /// @notice Like create but for submitting a Task Cycle to Gelato. A
    //   Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed
    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _actions Optional actions to execute.
    /// @param _provider Gelato Provider object for _tasks: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function createExecActionsSubmitTaskCycle(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    /// @notice Like create but for submitting a Task Cycle to Gelato. A
    //   Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @param _actions Optional actions to execute.
    /// @param _provider Gelato Provider object for _tasks: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    //   that should have occured once the cycle is complete:
    ///  1) _sumOfRequestedTaskSubmits=X: number of times to run the same task or the sum
    ///   of total cyclic task executions in the case of a sequence of different tasks.
    ///  2) _submissionsLeft=0: infinity - run the same task or sequence of tasks infinitely.
    function createExecActionsSubmitTaskChain(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    //  ==================== CREATE 2 =======================================

    /// @notice Create a GelatoUserProxy using the create2 opcode.
    /// @param _saltNonce salt is generated thusly: keccak256(abi.encode(_user, _saltNonce))
    /// @return userProxy address of deployed proxy contract.
    function createTwo(uint256 _saltNonce)
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a GelatoUserProxy using the create2 opcode and exec actions
    /// @param _saltNonce salt is generated thusly: keccak256(abi.encode(_user, _saltNonce))
    /// @param _actions Optional actions to execute.
    /// @return userProxy address of deployed proxy contract.
    function createTwoExecActions(uint256 _saltNonce, Action[] calldata _actions)
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a salted GelatoUserProxy and submit Tasks to Gelato in the same tx.
    /// @param _provider Provider for each of the _tasks.
    /// @param _tasks Tasks to submit to Gelato. Must each have their own Provider.
    /// @param _expiryDates expiryDate for each of the _tasks.
    ///  CAUTION: The ordering of _tasks<=>_expiryDates must be coordinated.
    /// @return userProxy address of deployed proxy contract.
    function createTwoSubmitTasks(
        uint256 _saltNonce,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        returns (GelatoUserProxy userProxy);

    /// @notice Create a GelatoUserProxy using the create2 opcode.
    /// @dev This allows for creating  a GelatoUserProxy instance at a specific address.
    ///  which can be predicted and e.g. prefunded.
    /// @param _saltNonce salt is generated thusly: keccak256(abi.encode(_user, _saltNonce))
    /// @param _actions Optional actions to execute.
    /// @param _provider Provider for each of the _tasks.
    /// @param _tasks Tasks to submit to Gelato. Must each have their own Provider.
    /// @param _expiryDates expiryDate for each of the _tasks.
    ///  CAUTION: The ordering of _tasks<=>_expiryDates must be coordinated.
    function createTwoExecActionsSubmitTasks(
        uint256 _saltNonce,
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    /// @notice Just like createAndSubmitTaskCycle just using create2, thus allowing for
    ///  knowing the address the GelatoUserProxy will be assigned to in advance.
    /// @param _saltNonce salt is generated thusly: keccak256(abi.encode(_user, _saltNonce))
    function createTwoExecActionsSubmitTaskCycle(
        uint256 _saltNonce,
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    /// @notice Just like createAndSubmitTaskChain just using create2, thus allowing for
    ///  knowing the address the GelatoUserProxy will be assigned to in advance.
    /// @param _saltNonce salt is generated thusly: keccak256(abi.encode(_user, _saltNonce))
    function createTwoExecActionsSubmitTaskChain(
        uint256 _saltNonce,
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external
        payable
        returns(GelatoUserProxy userProxy);

    //  ==================== GETTERS =======================================
    function predictProxyAddress(address _user, uint256 _saltNonce)
        external
        view
        returns(address);

    /// @notice Get address of user (EOA) from proxy contract address
    /// @param _userProxy Address of proxy contract
    /// @return User (EOA) address
    function userByGelatoProxy(GelatoUserProxy _userProxy) external view returns(address);

    /// @notice Get a list of userProxies that belong to one user.
    /// @param _user Address of user
    /// @return array of deployed GelatoUserProxies that belong to the _user.
    function gelatoProxiesByUser(address _user) external view returns(GelatoUserProxy[] memory);

    function getGelatoUserProxyByIndex(address _user, uint256 _index)
        external
        view
        returns(GelatoUserProxy);

    /// @notice Check if proxy was deployed from gelato proxy factory
    /// @param _userProxy Address of proxy contract
    /// @return true if it was deployed from gelato user proxy factory
    function isGelatoUserProxy(address _userProxy) external view returns(bool);

    /// @notice Check if user has deployed a proxy from gelato proxy factory
    /// @param _user Address of user
    /// @param _userProxy Address of supposed userProxy
    /// @return true if user deployed a proxy from gelato user proxy factory
    function isGelatoProxyUser(address _user, GelatoUserProxy _userProxy)
        external
        view
        returns(bool);

    /// @notice Returns address of gelato
    /// @return Gelato core address
    function gelatoCore() external pure returns(address);

    /// @notice Returns the CreationCode used by the Factory to create GelatoUserProxies.
    /// @dev This is internally used by the factory to predict the address during create2.
    function proxyCreationCode() external pure returns(bytes memory);
}"
    },
    "contracts/external/Address.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

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
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "contracts/user_proxies/gelato_user_proxy/GelatoUserProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoUserProxy} from "./interfaces/IGelatoUserProxy.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {
    Action, Operation, Provider, Task, TaskReceipt, IGelatoCore
} from "../../gelato_core/interfaces/IGelatoCore.sol";

contract GelatoUserProxy is IGelatoUserProxy {

    using GelatoBytes for bytes;

    address public immutable override factory;
    address public immutable override user;
    address public immutable override gelatoCore;

    constructor(address _user, address _gelatoCore)
        public
        payable
        noZeroAddress(_user)
        noZeroAddress(_gelatoCore)
    {
        factory = msg.sender;
        user = _user;
        gelatoCore = _gelatoCore;
    }

    receive() external payable {}

    modifier noZeroAddress(address _) {
        require(_ != address(0), "GelatoUserProxy.noZeroAddress");
        _;
    }

    modifier onlyUser() {
        require(msg.sender == user, "GelatoUserProxy.onlyUser: failed");
        _;
    }

    modifier userOrFactory() {
        require(
            msg.sender == user || msg.sender == factory,
            "GelatoUserProxy.userOrFactory: failed");
        _;
    }

    modifier auth() {
        require(
            msg.sender == gelatoCore || msg.sender == user || msg.sender == factory,
            "GelatoUserProxy.auth: failed"
        );
        _;
    }

    function submitTask(Provider calldata _provider, Task calldata _task, uint256 _expiryDate)
        public
        override
        userOrFactory
    {

        try IGelatoCore(gelatoCore).submitTask(_provider, _task, _expiryDate) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxy.submitTask:", err)));
        } catch {
            revert("GelatoUserProxy.submitTask:undefinded");
        }
    }

    function multiSubmitTasks(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external
        override
    {
        require(
            _tasks.length == _expiryDates.length,
            "GelatoUserProxy.multiSubmitTasks: each task needs own expiryDate"
        );
        for (uint i; i < _tasks.length; i++)
            submitTask(_provider, _tasks[i], _expiryDates[i]);
    }

    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles  // num of full cycles
    )
        public
        override
        userOrFactory
    {
        try IGelatoCore(gelatoCore).submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        ) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxy.submitTaskCycle:", err)));
        } catch {
            revert("GelatoUserProxy.submitTaskCycle:undefinded");
        }
    }

    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits  // num of all prospective task submissions
    )
        public
        override
        userOrFactory
    {
        try IGelatoCore(gelatoCore).submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        ) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxy.submitTaskChain:", err)));
        } catch {
            revert("GelatoUserProxy.submitTaskChain:undefinded");
        }
    }

    function cancelTask(TaskReceipt calldata _TR) external override onlyUser {
        try IGelatoCore(gelatoCore).cancelTask(_TR) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxy.cancelTask:", err)));
        } catch {
            revert("GelatoUserProxy.cancelTask:undefinded");
        }
    }

    function multiCancelTasks(TaskReceipt[] calldata _TRs) external override onlyUser {
        try IGelatoCore(gelatoCore).multiCancelTasks(_TRs) {
        } catch Error(string memory err) {
            revert(string(abi.encodePacked("GelatoUserProxy.multiCancelTasks:", err)));
        } catch {
            revert("GelatoUserProxy.multiCancelTasks:undefinded");
        }
    }

    // @dev we have to write duplicate code due to calldata _action FeatureNotImplemented
    function execAction(Action calldata _action) external payable override auth {
        if (_action.operation == Operation.Call)
            _callAction(_action.addr, _action.data, _action.value);
        else if (_action.operation == Operation.Delegatecall)
            _delegatecallAction(_action.addr, _action.data);
        else
            revert("GelatoUserProxy.execAction: invalid operation");
    }

    // @dev we have to write duplicate code due to calldata _action FeatureNotImplemented
    function multiExecActions(Action[] calldata _actions) public payable override auth {
        for (uint i = 0; i < _actions.length; i++) {
            if (_actions[i].operation == Operation.Call)
                _callAction(_actions[i].addr, _actions[i].data, _actions[i].value);
            else if (_actions[i].operation == Operation.Delegatecall)
                _delegatecallAction(address(_actions[i].addr), _actions[i].data);
            else
                revert("GelatoUserProxy.multiExecActions: invalid operation");
        }
    }

    // @dev we have to write duplicate code due to calldata _action FeatureNotImplemented
    function execActionsAndSubmitTaskCycle(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable
        override
        auth
    {
        if (_actions.length != 0) multiExecActions(_actions);
        if(_tasks.length != 0) submitTaskCycle(_provider, _tasks, _expiryDate, _cycles);
    }

    function _callAction(address _action, bytes calldata _data, uint256 _value)
        internal
        noZeroAddress(_action)
    {
        (bool success, bytes memory returndata) = _action.call{value: _value}(_data);
        if (!success) returndata.revertWithErrorString("GelatoUserProxy._callAction:");
    }

    function _delegatecallAction(address _action, bytes calldata _data)
        internal
        noZeroAddress(_action)
    {
        (bool success, bytes memory returndata) = _action.delegatecall(_data);
        if (!success) returndata.revertWithErrorString("GelatoUserProxy._delegatecallAction:");
    }
}"
    },
    "contracts/libraries/GelatoUserProxySet.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoUserProxy} from "../user_proxies/gelato_user_proxy/GelatoUserProxy.sol";


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
 * As of v2.5.0, only `GelatoUserProxy` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.Set;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta CaÃ±ada
 * @author Luis Schliessske (modified to GelatoUserProxySet)
 */
library GelatoUserProxySet {

    struct Set {
        // Position of the proxy in the `gelatoUserProxies` array, plus 1 because index 0
        // means a proxy is not in the set.
        mapping (GelatoUserProxy => uint256) index;
        GelatoUserProxy[] gelatoUserProxies;
    }

    /**
     * @dev Add a proxy to a set. O(1).
     * Returns false if the proxy was already in the set.
     */
    function add(Set storage set, GelatoUserProxy proxy)
        internal
        returns (bool)
    {
        if (!contains(set, proxy)) {
            set.gelatoUserProxies.push(proxy);
            // The element is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel proxy
            set.index[proxy] = set.gelatoUserProxies.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a proxy from a set. O(1).
     * Returns false if the proxy was not present in the set.
     */
    function remove(Set storage set, GelatoUserProxy proxy)
        internal
        returns (bool)
    {
        if (contains(set, proxy)){
            uint256 toDeleteIndex = set.index[proxy] - 1;
            uint256 lastIndex = set.gelatoUserProxies.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                GelatoUserProxy lastValue = set.gelatoUserProxies[lastIndex];

                // Move the last proxy to the index where the deleted proxy is
                set.gelatoUserProxies[toDeleteIndex] = lastValue;
                // Update the index for the moved proxy
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted proxy
            delete set.index[proxy];

            // Delete the old entry for the moved proxy
            set.gelatoUserProxies.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the proxy is in the set. O(1).
     */
    function contains(Set storage set, GelatoUserProxy proxy)
        internal
        view
        returns (bool)
    {
        return set.index[proxy] != 0;
    }

    /**
     * @dev Returns an array with all gelatoUserProxies in the set. O(N).
     * Note that there are no guarantees on the ordering of gelatoUserProxies inside the
     * array, and it may change when more gelatoUserProxies are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Set storage set)
        internal
        view
        returns (GelatoUserProxy[] memory)
    {
        GelatoUserProxy[] memory output = new GelatoUserProxy[](set.gelatoUserProxies.length);
        for (uint256 i; i < set.gelatoUserProxies.length; i++) output[i] = set.gelatoUserProxies[i];
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.gelatoUserProxies.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of gelatoUserProxies inside the
    * array, and it may change when more gelatoUserProxies are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Set storage set, uint256 index)
        internal
        view
        returns (GelatoUserProxy)
    {
        return set.gelatoUserProxies[index];
    }
}"
    },
    "contracts/user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    Action, Provider, Task, TaskReceipt
} from "../../../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoUserProxy {

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(Provider calldata _provider, Task calldata _task, uint256 _expiryDate)
        external;

    /// @notice API to submit multiple "single" Tasks.
    /// @dev CAUTION: The ordering of _tasks<=>_expiryDates must be coordinated.
    /// @param _providers Gelato Provider object: provider address and module.
    /// @param _tasks An array of Gelato Task objects: provider, conditions, actions.
    /// @param _expiryDates From then on the task cannot be executed. 0 for infinity.
    function multiSubmitTasks(
        Provider calldata _providers,
        Task[] calldata _tasks,
        uint256[] calldata _expiryDates
    )
        external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    //   that should have occured once the cycle is complete:
    ///  1) _sumOfRequestedTaskSubmits=X: number of times to run the same task or the sum
    ///   of total cyclic task executions in the case of a sequence of different tasks.
    ///  2) _submissionsLeft=0: infinity - run the same task or sequence of tasks infinitely.
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external;


    /// @notice Execs actions and submits task cycle in one tx
    /// @param _actions Actions to execute
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function execActionsAndSubmitTaskCycle(
        Action[] calldata _actions,
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external
        payable;

    /// @notice Cancel a task receipt on gelato
    /// @dev Proxy users or the Task providers can cancel.
    /// @param _TR Task Receipt to cancel
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel Tasks with their receipts on gelato
    /// @dev Proxy users or the Task providers can cancel.
    /// @param _TRs Task Receipts of Tasks to cancel
    function multiCancelTasks(TaskReceipt[] calldata _TRs) external;

    /// @notice Execute an action
    /// @param _action Action to execute
    function execAction(Action calldata _action) external payable;

    /// @notice Execute multiple actions
    /// @param _actions Actions to execute
    function multiExecActions(Action[] calldata _actions) external payable;

    /// @notice Get the factory address whence the proxy was created.
    /// @return Address of proxy's factory
    function factory() external pure returns(address);

    /// @notice Get the owner (EOA) address of the proxy
    /// @return Address of proxy owner
    function user() external pure returns(address);

    /// @notice Get the address of gelato
    /// @return Address of gelato
    function gelatoCore() external pure returns(address);
}
"
    },
    "contracts/libraries/GelatoBytes.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithErrorString(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly { selector := mload(add(0x20, _bytes)) }
            if (selector == 0x08c379a0) {  // Function selector for Error(string)
                assembly { _bytes := add(_bytes, 68) }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(string(abi.encodePacked(_tracingInfo, "NoErrorSelector")));
            }
        } else {
            revert(string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata")));
        }
    }
}"
    },
    "contracts/gelato_provider_modules/gnosis_safe_proxy_provider/ProviderModuleGnosisSafeProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoProviderModuleStandard} from "../GelatoProviderModuleStandard.sol";
import {IProviderModuleGnosisSafeProxy} from "./IProviderModuleGnosisSafeProxy.sol";
import {Ownable} from "../../external/Ownable.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {GelatoActionPipeline} from "../../gelato_actions/GelatoActionPipeline.sol";
import {
    IGnosisSafe
} from "../../user_proxies/gnosis_safe_proxy/interfaces/IGnosisSafe.sol";
import {
    IGnosisSafeProxy
} from "../../user_proxies/gnosis_safe_proxy/interfaces/IGnosisSafeProxy.sol";
import {Task} from "../../gelato_core/interfaces/IGelatoCore.sol";

contract ProviderModuleGnosisSafeProxy is
    GelatoProviderModuleStandard,
    IProviderModuleGnosisSafeProxy,
    Ownable
{
    using GelatoBytes for bytes;

    mapping(bytes32 => bool) public override isProxyExtcodehashProvided;
    mapping(address => bool) public override isMastercopyProvided;
    address public override immutable gelatoCore;
    address public override immutable gelatoActionPipeline;

    constructor(
        bytes32[] memory hashes,
        address[] memory masterCopies,
        address _gelatoCore,
        address _gelatoActionPipeline
    )
        public
    {
        multiProvide(hashes, masterCopies);
        gelatoCore = _gelatoCore;
        gelatoActionPipeline = _gelatoActionPipeline;
    }

    // ================= GELATO PROVIDER MODULE STANDARD ================
    // @dev since we check extcodehash prior to execution, we forego the execution option
    //  where the userProxy is deployed at execution time.
    function isProvided(address _userProxy, address, Task calldata)
        external
        view
        override
        returns(string memory)
    {
        bytes32 codehash;
        assembly { codehash := extcodehash(_userProxy) }
        if (!isProxyExtcodehashProvided[codehash])
            return "ProviderModuleGnosisSafeProxy.isProvided:InvalidGSPCodehash";
        address mastercopy = IGnosisSafeProxy(_userProxy).masterCopy();
        if (!isMastercopyProvided[mastercopy])
            return "ProviderModuleGnosisSafeProxy.isProvided:InvalidGSPMastercopy";
        if (!isGelatoCoreWhitelisted(_userProxy))
            return "ProviderModuleGnosisSafeProxy.isProvided:GelatoCoreNotWhitelisted";
        return OK;
    }

    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        override
        returns(bytes memory payload, bool proxyReturndataCheck)
    {
        // execTransactionFromModuleReturnData catches reverts so must check for reverts
        proxyReturndataCheck = true;

        if (_task.actions.length == 1) {
            payload = abi.encodeWithSelector(
                IGnosisSafe.execTransactionFromModuleReturnData.selector,
                _task.actions[0].addr,  // to
                _task.actions[0].value,
                _task.actions[0].data,
                _task.actions[0].operation
            );
        } else if (_task.actions.length > 1) {
            // Action.Operation encoded into multiSendPayload and handled by Multisend
            bytes memory gelatoActionPipelinePayload = abi.encodeWithSelector(
                GelatoActionPipeline.execActionsAndPipeData.selector,
                _task.actions
            );

            payload = abi.encodeWithSelector(
                IGnosisSafe.execTransactionFromModuleReturnData.selector,
                gelatoActionPipeline,  // to
                0,  // value
                gelatoActionPipelinePayload,  // data
                IGnosisSafe.Operation.DelegateCall
            );

        } else {
            revert("ProviderModuleGnosisSafeProxy.execPayload: 0 _task.actions length");
        }
    }

    function execRevertCheck(bytes calldata _proxyReturndata)
        external
        pure
        virtual
        override
    {
        (bool success, bytes memory returndata) = abi.decode(_proxyReturndata, (bool,bytes));
        if (!success) returndata.revertWithErrorString(":ProviderModuleGnosisSafeProxy:");
    }

    // GnosisSafeProxy
    function provideProxyExtcodehashes(bytes32[] memory _hashes) public override onlyOwner {
        for (uint i; i < _hashes.length; i++) {
            require(
                !isProxyExtcodehashProvided[_hashes[i]],
                "ProviderModuleGnosisSafeProxy.provideProxyExtcodehashes: redundant"
            );
            isProxyExtcodehashProvided[_hashes[i]] = true;
            emit LogProvideProxyExtcodehash(_hashes[i]);
        }
    }

    function unprovideProxyExtcodehashes(bytes32[] memory _hashes) public override onlyOwner {
        for (uint i; i < _hashes.length; i++) {
            require(
                isProxyExtcodehashProvided[_hashes[i]],
                "ProviderModuleGnosisSafeProxy.unprovideProxyExtcodehashes: redundant"
            );
            delete isProxyExtcodehashProvided[_hashes[i]];
            emit LogUnprovideProxyExtcodehash(_hashes[i]);
        }
    }

    function provideMastercopies(address[] memory _mastercopies) public override onlyOwner {
        for (uint i; i < _mastercopies.length; i++) {
            require(
                !isMastercopyProvided[_mastercopies[i]],
                "ProviderModuleGnosisSafeProxy.provideMastercopy: redundant"
            );
            isMastercopyProvided[_mastercopies[i]] = true;
            emit LogProvideMastercopy(_mastercopies[i]);
        }
    }

    function unprovideMastercopies(address[] memory _mastercopies) public override onlyOwner {
        for (uint i; i < _mastercopies.length; i++) {
            require(
                isMastercopyProvided[_mastercopies[i]],
                "ProviderModuleGnosisSafeProxy.unprovideMastercopies: redundant"
            );
            delete isMastercopyProvided[_mastercopies[i]];
            emit LogUnprovideMastercopy(_mastercopies[i]);
        }
    }

    // Batch (un-)provide
    function multiProvide(bytes32[] memory _hashes, address[] memory _mastercopies)
        public
        override
        onlyOwner
    {
        provideProxyExtcodehashes(_hashes);
        provideMastercopies(_mastercopies);
    }

    function multiUnprovide(bytes32[] calldata _hashes, address[] calldata _mastercopies)
        external
        override
        onlyOwner
    {
        unprovideProxyExtcodehashes(_hashes);
        unprovideMastercopies(_mastercopies);
    }

    function isGelatoCoreWhitelisted(address _userProxy)
        view
        internal
        returns(bool)
    {
        address[] memory whitelistedModules = IGnosisSafe(_userProxy).getModules();
        for (uint i = 0; i < whitelistedModules.length; i++)
            if (whitelistedModules[i] == gelatoCore) return true;
        return false;
    }

}"
    },
    "contracts/gelato_provider_modules/GelatoProviderModuleStandard.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "./IGelatoProviderModule.sol";
import {Task} from "../gelato_core/interfaces/IGelatoCore.sol";

abstract contract GelatoProviderModuleStandard is IGelatoProviderModule {

    string internal constant OK = "OK";

    function isProvided(address, address, Task calldata)
        external
        view
        virtual
        override
        returns(string memory)
    {
        return OK;
    }

    /// @dev Overriding fns should revert with the revertMsg they detected on the userProxy
    function execRevertCheck(bytes calldata) external pure override virtual {
        // By default no reverts detected => do nothing
    }
}
"
    },
    "contracts/gelato_provider_modules/gnosis_safe_proxy_provider/IProviderModuleGnosisSafeProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IProviderModuleGnosisSafeProxy{
    event LogProvideProxyExtcodehash(bytes32 indexed extcodehash);
    event LogUnprovideProxyExtcodehash(bytes32 indexed extcodehash);

    event LogProvideMastercopy(address indexed mastercopy);
    event LogUnprovideMastercopy(address indexed mastercopy);

    // GnosisSafeProxy
    function provideProxyExtcodehashes(bytes32[] calldata _hashes) external;
    function unprovideProxyExtcodehashes(bytes32[] calldata _hashes) external;

    function provideMastercopies(address[] calldata _mastercopies) external;
    function unprovideMastercopies(address[] calldata _mastercopies) external;

    // Batch (un-)provide
    function multiProvide(bytes32[] calldata _hashes, address[] calldata _mastercopies)
        external;

    function multiUnprovide(bytes32[] calldata _hashes, address[] calldata _mastercopies)
        external;

    function isProxyExtcodehashProvided(bytes32 _hash)
        external
        view
        returns(bool);
    function isMastercopyProvided(address _mastercopy)
        external
        view
        returns(bool);


    function gelatoCore() external pure returns(address);
    function gelatoActionPipeline() external pure returns(address);
}
"
    },
    "contracts/external/Ownable.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "contracts/gelato_actions/GelatoActionPipeline.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {Action, Operation, DataFlow} from "../gelato_core/interfaces/IGelatoCore.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {IGelatoInFlowAction} from "./action_pipeline_interfaces/IGelatoInFlowAction.sol";
import {IGelatoOutFlowAction} from "./action_pipeline_interfaces/IGelatoOutFlowAction.sol";
import {
    IGelatoInAndOutFlowAction
} from "./action_pipeline_interfaces/IGelatoInAndOutFlowAction.sol";

/// @title GelatoActionPipeline
/// @notice Runtime Environment for executing multiple Actions that can share data
contract GelatoActionPipeline {

    using GelatoBytes for bytes;

    address public immutable thisActionAddress;
    constructor() public { thisActionAddress = address(this); }

    /// @notice This code can be delegatecalled by User Proxies during the execution
    ///  of multiple Actions, in order to let data flow between them, in
    ///  accordance with their Action.DataFlow specifications.
    /// @dev ProviderModules should encode their execPayload with this function selector.
    /// @param _actions List of _actions to be executed sequentially in pipeline
    function execActionsAndPipeData(Action[] calldata _actions) external {
        require(thisActionAddress != address(this), "GelatoActionPipeline.delegatecallOnly");

        // Store for reusable data from Actions that DataFlow.Out or DataFlow.InAndOut
        bytes memory dataFromLastOutFlowAction;

        // We execute Actions sequentially and store reusable outflowing Data
        for (uint i = 0; i < _actions.length; i++) {
            require(_actions[i].addr != address(0), "GelatoActionPipeline.noZeroAddress");

            bytes memory actionPayload;

            if (_actions[i].dataFlow == DataFlow.In) {
                actionPayload = abi.encodeWithSelector(
                    IGelatoInFlowAction.execWithDataFlowIn.selector,
                    _actions[i].data,
                    dataFromLastOutFlowAction
                );
            } else if (_actions[i].dataFlow == DataFlow.Out) {
                actionPayload = abi.encodeWithSelector(
                    IGelatoOutFlowAction.execWithDataFlowOut.selector,
                    _actions[i].data
                );
            } else if (_actions[i].dataFlow == DataFlow.InAndOut) {
                actionPayload = abi.encodeWithSelector(
                    IGelatoInAndOutFlowAction.execWithDataFlowInAndOut.selector,
                    _actions[i].data,
                    dataFromLastOutFlowAction
                );
            } else {
                actionPayload = _actions[i].data;
            }

            bool success;
            bytes memory returndata;
            if (_actions[i].operation == Operation.Call){
                (success, returndata) = _actions[i].addr.call{value: _actions[i].value}(
                    actionPayload
                );
            } else {
                (success, returndata) = _actions[i].addr.delegatecall(actionPayload);
            }

            if (!success)
                returndata.revertWithErrorString("GelatoActionPipeline.execActionsAndPipeData:");

            if (
                _actions[i].dataFlow == DataFlow.Out ||
                _actions[i].dataFlow == DataFlow.InAndOut
            ) {
                // All OutFlow actions return (bytes memory). But the low-level
                // delegatecall encoded those bytes into returndata.
                // So we have to decode them again to obtain the original bytes value.
                dataFromLastOutFlowAction = abi.decode(returndata, (bytes));
            }
        }
    }

    function isValid(Action[] calldata _actions)
        external
        pure
        returns (
            bool ok,
            uint256 outActionIndex,
            uint256 inActionIndex,
            bytes32 currentOutflowType,
            bytes32 nextInflowType
        )
    {
        ok = true;
        for (uint256 i = 0; i < _actions.length; i++) {
            if (_actions[i].dataFlow == DataFlow.In || _actions[i].dataFlow == DataFlow.InAndOut) {
                // Make sure currentOutflowType matches what the inFlowAction expects
                try IGelatoInFlowAction(_actions[i].addr).DATA_FLOW_IN_TYPE()
                    returns (bytes32 inFlowType)
                {
                    if (inFlowType != currentOutflowType) {
                        nextInflowType = inFlowType;
                        inActionIndex = i;
                        ok = false;
                        break;
                    } else {
                        ok = true;
                    }
                } catch {
                    revert("GelatoActionPipeline.isValid: error DATA_FLOW_IN_TYPE");
                }
            }
            if (_actions[i].dataFlow == DataFlow.Out || _actions[i].dataFlow == DataFlow.InAndOut) {
                if (ok == false) break;
                // Store this Actions outFlowType to be used by the next inFlowAction
                try IGelatoOutFlowAction(_actions[i].addr).DATA_FLOW_OUT_TYPE()
                    returns (bytes32 outFlowType)
                {
                    currentOutflowType = outFlowType;
                    outActionIndex = i;
                    ok = false;
                } catch {
                    revert("GelatoActionPipeline.isValid: error DATA_FLOW_OUT_TYPE");
                }
            }
        }
    }
}"
    },
    "contracts/user_proxies/gnosis_safe_proxy/interfaces/IGnosisSafe.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IGnosisSafe {
    enum Operation {Call, DelegateCall}

    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures
    ) external returns (bool success);

    function enableModule(address module) external;
    function disableModule(address prevModule, address module) external;

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success, bytes memory returndata);

    function isOwner(address owner) external view returns (bool);
    function getOwners() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);
}
"
    },
    "contracts/user_proxies/gnosis_safe_proxy/interfaces/IGnosisSafeProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IGnosisSafeProxy {
    function masterCopy() external view returns (address);
}"
    },
    "contracts/gelato_actions/action_pipeline_interfaces/IGelatoInFlowAction.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

/// @title IGelatoInFlowAction
/// @notice Solidity interface for Actions that make use of DataFlow.In
/// @dev Inherit this, if you want your Action to use DataFlow.In in a standard way.
interface IGelatoInFlowAction {
    /// @notice Executes the action implementation with data flowing in from a previous
    ///  Action in the sequence.
    /// @dev The _inFlowData format should be defined by DATA_FLOW_IN_TYPE
    /// @param _actionData Known prior to execution and probably encoded off-chain.
    /// @param _inFlowData Not known prior to execution. Passed in via GelatoActionPipeline.
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable;

    /// @notice Returns the expected format of the execWithDataFlowIn _inFlowData.
    /// @dev Strict adherence to these formats is crucial for GelatoActionPipelines.
    function DATA_FLOW_IN_TYPE() external pure returns (bytes32);
}
"
    },
    "contracts/gelato_actions/action_pipeline_interfaces/IGelatoOutFlowAction.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

/// @title IGelatoOutFlowAction
/// @notice Solidity interface for Actions that make use of DataFlow.Out
/// @dev Inherit this, if you want implement your Action.DataFlow.Out in a standard way.
interface IGelatoOutFlowAction {
    /// @notice Executes the Action implementation with data flowing out to consecutive
    ///  Actions in a GelatoActionPipeline.
    /// @dev The outFlowData format should be defined by DATA_FLOW_OUT_TYPE
    /// @param _actionData Known prior to execution and probably encoded off-chain.
    /// @return outFlowData The bytes encoded data this action implementation emits.
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        returns (bytes memory outFlowData);

    /// @notice Returns the expected format of the execWithDataFlowOut outFlowData.
    /// @dev Strict adherence to these formats is crucial for GelatoActionPipelines.
    function DATA_FLOW_OUT_TYPE() external pure returns (bytes32);
}
"
    },
    "contracts/gelato_actions/action_pipeline_interfaces/IGelatoInAndOutFlowAction.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {Action} from "../../gelato_core/interfaces/IGelatoCore.sol";

/// @title IGelatoInAndOutFlowAction
/// @notice Solidity interface for Actions that make use of DataFlow.InAndOut
interface IGelatoInAndOutFlowAction {

    /// @notice Executes the Action implementation with data flowing in from a previous
    ///  Action in the GelatoActionPipeline and with data flowing out to consecutive
    ///  Actions in the pipeline.
    /// @dev The _inFlowData format should be defined by DATA_FLOW_IN_TYPE and
    ///  the outFlowData format should be defined by DATA_FLOW_OUT_TYPE.
    /// @param _actionData Known prior to execution and probably encoded off-chain.
    /// @param _inFlowData Not known prior to execution. Passed in via GelatoActionPipeline.
    /// @return outFlowData The bytes encoded data this action implementation emits.
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        returns (bytes memory outFlowData);

    /// @notice Returns the expected format of the execWithDataFlowIn _inFlowData.
    /// @dev Strict adherence to these formats is crucial for GelatoActionPipelines.
    function DATA_FLOW_IN_TYPE() external pure returns (bytes32);

    /// @notice Returns the expected format of the execWithDataFlowOut outFlowData.
    /// @dev Strict adherence to these formats is crucial for GelatoActionPipelines.
    function DATA_FLOW_OUT_TYPE() external pure returns (bytes32);
}"
    },
    "contracts/user_proxies/gnosis_safe_proxy/interfaces/IGnosisSafeProxyFactory.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IGnosisSafe.sol";

interface IGnosisSafeProxyFactory {

    event ProxyCreation(address proxy);

    /// @dev Allows to create new proxy contact and exec a message call to the
    ///      new proxy within one transaction. Emits ProxyCreation.
    /// @param masterCopy Address of master copy.
    /// @param data Payload for message call sent to new proxy contract.
    /// @return proxy address
    function createProxy(address masterCopy, bytes calldata data)
        external
        returns (IGnosisSafe proxy);

    /// @dev Allows to create new proxy contact and exec a message call to the
    ///      new proxy within one transaction. Emits ProxyCreation.
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the
    ///                   address of the new proxy contract.
    /// @return proxy address
    function createProxyWithNonce(
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce
    )
        external
        returns (IGnosisSafe proxy);

    /// @dev Allows to create new proxy contact, exec a message call to the
    //       new proxy and call a specified callback within one transaction
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate
    ///                  the address of the new proxy contract.
    /// @param callback Callback that will be invoced after the new proxy contract
    ///                 has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    )
        external
        returns (IGnosisSafe proxy);

    /// @dev Allows to get the address for a new proxy contact created via `createProxyWithNonce`
    ///      This method is only meant for address calculation purpose when you use an
    ///      initializer that would revert, therefore the response is returned with a revert.
    ///      When calling this method set `from` to the address of the proxy factory.
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the
    ///                  address of the new proxy contract.
    /// @return proxy address from a revert() reason string message
    function calculateCreateProxyWithNonceAddress(
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce
    )
        external
        returns (address proxy);

    /// @dev Allows to retrieve the runtime code of a deployed Proxy.
    ///      This can be used to check that the expected Proxy was deployed.
    /// @return proxysRuntimeBytecode bytes
    function proxyRuntimeCode() external pure returns (bytes memory);

    /// @dev Allows to retrieve the creation code used for the Proxy deployment.
    ///      With this it is easily possible to calculate predicted address.
    /// @return proxysCreationCode bytes
    function proxyCreationCode() external pure returns (bytes memory);

}

interface IProxyCreationCallback {
    function proxyCreated(
        address proxy,
        address _mastercopy,
        bytes calldata initializer,
        uint256 saltNonce
    )
        external;
}"
    },
    "contracts/gelato_provider_modules/gelato_user_proxy_provider/ProviderModuleGelatoUserProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoProviderModuleStandard} from "../GelatoProviderModuleStandard.sol";
import {
    Action, Operation, DataFlow, Task
} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoUserProxyFactory
} from "../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxyFactory.sol";
import {
    IGelatoUserProxy
} from "../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol";
import {GelatoActionPipeline} from "../../gelato_actions/GelatoActionPipeline.sol";

contract ProviderModuleGelatoUserProxy is GelatoProviderModuleStandard {

    IGelatoUserProxyFactory public immutable gelatoUserProxyFactory;
    address public immutable gelatoActionPipeline;

    constructor(
        IGelatoUserProxyFactory _gelatoUserProxyFactory,
        address _gelatoActionPipeline
    )
        public
    {
        gelatoUserProxyFactory = _gelatoUserProxyFactory;
        gelatoActionPipeline = _gelatoActionPipeline;
    }

    // ================= GELATO PROVIDER MODULE STANDARD ================
    function isProvided(address _userProxy, address, Task calldata)
        external
        view
        override
        returns(string memory)
    {
        bool proxyOk = gelatoUserProxyFactory.isGelatoUserProxy(_userProxy);
        if (!proxyOk) return "ProviderModuleGelatoUserProxy.isProvided:InvalidUserProxy";
        return OK;
    }

    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        override
        returns(bytes memory payload, bool)  // bool==false: no execRevertCheck
    {
        if (_task.actions.length > 1) {
            bytes memory gelatoActionPipelinePayload = abi.encodeWithSelector(
                GelatoActionPipeline.execActionsAndPipeData.selector,
                _task.actions
            );
            Action memory pipelinedActions = Action({
                addr: gelatoActionPipeline,
                data: gelatoActionPipelinePayload,
                operation: Operation.Delegatecall,
                dataFlow: DataFlow.None,
                value: 0,
                termsOkCheck: false
            });
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                pipelinedActions
            );
        } else if (_task.actions.length == 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                _task.actions[0]
            );
        } else {
            revert("ProviderModuleGelatoUserProxy.execPayload: 0 _task.actions length");
        }
    }
}"
    },
    "contracts/mocks/provider_modules/gelato_user_proxy_provider/MockProviderModuleGelatoUserProxyExecRevertCheckRevert.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    GelatoProviderModuleStandard
} from "../../../gelato_provider_modules/GelatoProviderModuleStandard.sol";
import {Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoUserProxy
} from "../../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol";

contract MockProviderModuleGelatoUserProxyExecRevertCheckRevert is
    GelatoProviderModuleStandard
{
    // Incorrect execPayload func on purpose
    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        virtual
        override
        returns(bytes memory payload, bool execRevertCheck)
    {
        if (_task.actions.length > 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.multiExecActions.selector,
                _task.actions
            );
        } else if (_task.actions.length == 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                _task.actions[0]
            );
        } else {
            revert("ProviderModuleGelatoUserProxy.execPayload: 0 _actions length");
        }
        execRevertCheck = true;
    }

    function execRevertCheck(bytes memory)
        public
        pure
        virtual
        override
    {
        revert("MockProviderModuleGelatoUserProxyExecRevertCheck.execRevertCheck");
    }
}"
    },
    "contracts/mocks/provider_modules/gelato_user_proxy_provider/MockProviderModuleGelatoUserProxyExecRevertCheckError.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    GelatoProviderModuleStandard
} from "../../../gelato_provider_modules/GelatoProviderModuleStandard.sol";
import {Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoUserProxy
} from "../../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol";

contract MockProviderModuleGelatoUserProxyExecRevertCheckError is
    GelatoProviderModuleStandard
{

    // Incorrect execPayload func on purpose
    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        virtual
        override
        returns(bytes memory payload, bool execRevertCheck)
    {
        if (_task.actions.length > 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.multiExecActions.selector,
                _task.actions
            );
        } else if (_task.actions.length == 1) {
            payload = abi.encodeWithSelector(
                IGelatoUserProxy.execAction.selector,
                _task.actions[0]
            );
        } else {
            revert("ProviderModuleGelatoUserProxy.execPayload: 0 _actions length");
        }
        execRevertCheck = true;
    }

    function execRevertCheck(bytes memory)
        public
        pure
        virtual
        override
    {
        assert(false);
    }
}"
    },
    "contracts/mocks/provider_modules/gelato_user_proxy_provider/MockProviderModuleExecPayloadWrong.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    GelatoProviderModuleStandard
} from "../../../gelato_provider_modules/GelatoProviderModuleStandard.sol";
import {Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract MockProviderModuleExecPayloadWrong is GelatoProviderModuleStandard {
    // Incorrect execPayload func on purpose
    function execPayload(uint256, address, address, Task calldata, uint256)
        external
        view
        override
        returns(bytes memory, bool)
    {
        return (abi.encodeWithSelector(this.bogus.selector), false);
    }

    function bogus() external {}
}"
    },
    "contracts/mocks/provider_modules/gelato_user_proxy_provider/MockProviderModuleExecPayloadRevert.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    GelatoProviderModuleStandard
} from "../../../gelato_provider_modules/GelatoProviderModuleStandard.sol";
import {Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract MockProviderModuleExecPayloadRevert is GelatoProviderModuleStandard {
    // Incorrect execPayload func on purpose
    function execPayload(uint256, address, address, Task calldata, uint256)
        external
        view
        override
        returns(bytes memory, bool)
    {
        revert("MockProviderModuleExecPayloadRevert.execPayload: test revert");
    }
}"
    },
    "contracts/mocks/gelato_actions/one-off/MockActionMaliciousProvider.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoActionsStandard} from "../../../gelato_actions/GelatoActionsStandard.sol";
import {IGelatoAction} from "../../../gelato_actions/IGelatoAction.sol";
import {
    IGelatoProviders,
    TaskSpec
} from "../../../gelato_core/interfaces/IGelatoProviders.sol";
import {IGelatoProviderModule} from "../../../gelato_provider_modules/IGelatoProviderModule.sol";

// This Action is the Provider and must be called from any UserProxy with .call a
contract MockActionMaliciousProvider  {
    IGelatoProviders immutable gelato;

    constructor(IGelatoProviders _gelato) public { gelato = _gelato; }

    receive() external payable {}

    function action() public payable virtual {
        uint256 providerFunds = gelato.providerFunds(address(this));
        try gelato.unprovideFunds(providerFunds) {
        } catch Error(string memory err) {
            revert(
                string(
                    abi.encodePacked("MockActionMaliciousProvider.action.unprovideFunds:", err)
                )
            );
        } catch {
            revert("MockActionMaliciousProvider.action.unprovideFunds:undefinded");
        }
    }

    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external
        payable
    {
        try gelato.multiProvide{value: msg.value}(_executor, _taskSpecs, _modules) {
        } catch Error(string memory err) {
            revert(
                string(abi.encodePacked("MockActionMaliciousProvider.multiProvide:", err))
            );
        } catch {
            revert("MockActionMaliciousProvider.multiProvide:undefinded");
        }
    }
}
"
    },
    "contracts/gelato_actions/GelatoActionsStandard.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {IGelatoAction} from "./IGelatoAction.sol";
import {DataFlow} from "../gelato_core/interfaces/IGelatoCore.sol";

/// @title GelatoActionsStandard
/// @dev find all the NatSpecs inside IGelatoAction
abstract contract GelatoActionsStandard is IGelatoAction {

    string internal constant OK = "OK";
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable thisActionAddress;

    constructor() public { thisActionAddress = address(this); }

    modifier delegatecallOnly(string memory _tracingInfo) {
        require(
            thisActionAddress != address(this),
            string(abi.encodePacked(_tracingInfo, ":delegatecallOnly"))
        );
        _;
    }

    function termsOk(
        uint256,  // _taskReceiptId
        address,  // _userProxy
        bytes calldata,  // _actionData
        DataFlow,
        uint256,  // _value: for actions that send ETH around
        uint256  // cycleId
    )
        external
        view
        virtual
        override
        returns(string memory)  // actionTermsOk
    {
        // Standard return value for actionConditions fulfilled and no erros:
        return OK;
    }
}
"
    },
    "contracts/gelato_actions/IGelatoAction.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {DataFlow} from "../gelato_core/interfaces/IGelatoCore.sol";

/// @title IGelatoAction - solidity interface of GelatoActionsStandard
/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    event LogOneWay(
        address origin,
        address sendToken,
        uint256 sendAmount,
        address destination
    );

    event LogTwoWay(
        address origin,
        address sendToken,
        uint256 sendAmount,
        address destination,
        address receiveToken,
        uint256 receiveAmount,
        address receiver
    );

    /// @notice Providers can use this for pre-execution sanity checks, to prevent reverts.
    /// @dev GelatoCore checks this in canExec and passes the parameters.
    /// @param _taskReceiptId The id of the task from which all arguments are passed.
    /// @param _userProxy The userProxy of the task. Often address(this) for delegatecalls.
    /// @param _actionData The encoded payload to be used in the Action.
    /// @param _dataFlow The dataFlow of the Action.
    /// @param _value A special param for ETH sending Actions. If the Action sends ETH
    ///  in its Action function implementation, one should expect msg.value therein to be
    ///  equal to _value. So Providers can check in termsOk that a valid ETH value will
    ///  be used because they also have access to the same value when encoding the
    ///  execPayload on their ProviderModule.
    /// @param _cycleId For tasks that are part of a Cycle.
    /// @return Returns OK, if Task can be executed safely according to the Provider's
    ///  terms laid out in this function implementation.
    function termsOk(
        uint256 _taskReceiptId,
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256 _value,
        uint256 _cycleId
    )
        external
        view
        returns(string memory);
}
"
    },
    "contracts/gelato_core/interfaces/IGelatoProviders.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "../../gelato_provider_modules/IGelatoProviderModule.sol";
import {Action, Provider, Task, TaskReceipt} from "../interfaces/IGelatoCore.sol";
import {IGelatoCondition} from "../../gelato_conditions/IGelatoCondition.sol";

// TaskSpec - Will be whitelised by providers and selected by users
struct TaskSpec {
    IGelatoCondition[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

interface IGelatoProviders {
    // Provider Funding
    event LogFundsProvided(
        address indexed provider,
        uint256 amount,
        uint256 newProviderFunds
    );
    event LogFundsUnprovided(
        address indexed provider,
        uint256 realWithdrawAmount,
        uint256 newProviderFunds
    );

    // Executor By Provider
    event LogProviderAssignedExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );
    event LogExecutorAssignedExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );

    // Actions
    event LogTaskSpecProvided(address indexed provider, bytes32 indexed taskSpecHash);
    event LogTaskSpecUnprovided(address indexed provider, bytes32 indexed taskSpecHash);
    event LogTaskSpecGasPriceCeilSet(
        address indexed provider,
        bytes32 taskSpecHash,
        uint256 oldTaskSpecGasPriceCeil,
        uint256 newTaskSpecGasPriceCeil
    );

    // Provider Module
    event LogProviderModuleAdded(
        address indexed provider,
        IGelatoProviderModule indexed module
    );
    event LogProviderModuleRemoved(
        address indexed provider,
        IGelatoProviderModule indexed module
    );

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether Task Spec is being offered by the selected provider
    /// @dev Checked in submitTask(), unless provider == userProxy
    /// @param _provider Address of selected provider
    /// @param _taskSpec Task Spec
    /// @return Expected to return "OK"
    function isTaskSpecProvided(address _provider, TaskSpec calldata _taskSpec)
        external
        view
        returns(string memory);

    /// @notice Validates that provider has provider module whitelisted + conducts isProvided check in ProviderModule
    /// @dev Checked in submitTask() if provider == userProxy
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return Expected to return "OK"
    function providerModuleChecks(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    )
        external
        view
        returns(string memory);


    /// @notice Validate if provider module and seleced TaskSpec is whitelisted by provider
    /// @dev Combines "isTaskSpecProvided" and providerModuleChecks
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return res Expected to return "OK"
    function isTaskProvided(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    )
        external
        view
        returns(string memory res);


    /// @notice Validate if selected TaskSpec is whitelisted by provider and that current gelatoGasPrice is below GasPriceCeil
    /// @dev If gasPriceCeil is != 0, Task Spec is whitelisted
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @param _gelatoGasPrice Task Receipt defined in IGelatoCore
    /// @return res Expected to return "OK"
    function providerCanExec(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _gelatoGasPrice
    )
        external
        view
        returns(string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns(uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor) external;

    // (Un-)provide Task Spec

    /// @notice Whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil is == 0, Task Spec will be executed at any gas price (no ceil)
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function provideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice De-whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil was set to NO_CEIL, Input NO_CEIL constant as GasPriceCeil
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function unprovideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice Update gasPriceCeil of selected Task Spec
    /// @param _taskSpecHash Result of hashTaskSpec()
    /// @param _gasPriceCeil New gas price ceil for Task Spec
    function setTaskSpecGasPriceCeil(bytes32 _taskSpecHash, uint256 _gasPriceCeil) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules) external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules) external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _taskSpecs List of Task Spec which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external
        payable;


    /// @notice De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _taskSpecs List of Task Spec which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns(uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(uint256 _gelatoMaxGas, uint256 _gelatoGasPrice)
        external
        view
        returns(uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        external
        view
        returns(bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns(uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor) external view returns(bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns(address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor) external view returns(uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns(bool);

    // Task Spec and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _taskSpecHash Hash of provider TaskSpec
    /// @return Max gas price an executor will execute the transaction with in wei
    function taskSpecGasPriceCeil(address _provider, bytes32 _taskSpecHash)
        external
        view
        returns(uint256);

    /// @notice Returns the hash of the formatted TaskSpec.
    /// @dev The action.data field of each Action is stripped before hashing.
    /// @param _taskSpec TaskSpec
    /// @return keccak256 hash of encoded condition address and Action List
    function hashTaskSpec(TaskSpec calldata _taskSpec) external view returns(bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns(uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns(bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns(IGelatoProviderModule[] memory);
}
"
    },
    "contracts/gelato_core/GelatoProviders.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviders, TaskSpec} from "./interfaces/IGelatoProviders.sol";
import {GelatoSysAdmin} from "./GelatoSysAdmin.sol";
import {Address} from "../external/Address.sol";
import {GelatoString} from "../libraries/GelatoString.sol";
import {Math} from "../external/Math.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";
import {ProviderModuleSet} from "../libraries/ProviderModuleSet.sol";
import {
    Condition, Action, Operation, DataFlow, Provider, Task, TaskReceipt
} from "./interfaces/IGelatoCore.sol";
import {IGelatoCondition} from "../gelato_conditions/IGelatoCondition.sol";

/// @title GelatoProviders
/// @notice Provider Management API - Whitelist TaskSpecs
/// @dev Find all NatSpecs inside IGelatoProviders
abstract contract GelatoProviders is IGelatoProviders, GelatoSysAdmin {

    using Address for address payable;  /// for sendValue method
    using GelatoString for string;
    using ProviderModuleSet for ProviderModuleSet.Set;
    using SafeMath for uint256;

    // This is only for internal use by hashTaskSpec()
    struct NoDataAction {
        address addr;
        Operation operation;
        DataFlow dataFlow;
        bool value;
        bool termsOkCheck;
    }

    uint256 public constant override NO_CEIL = type(uint256).max;

    mapping(address => uint256) public override providerFunds;
    mapping(address => uint256) public override executorStake;
    mapping(address => address) public override executorByProvider;
    mapping(address => uint256) public override executorProvidersCount;
    // The Task-Spec Gas-Price-Ceil => taskSpecGasPriceCeil
    mapping(address => mapping(bytes32 => uint256)) public override taskSpecGasPriceCeil;
    mapping(address => ProviderModuleSet.Set) internal _providerModules;

    // GelatoCore: canSubmit
    function isTaskSpecProvided(address _provider, TaskSpec memory _taskSpec)
        public
        view
        override
        returns(string memory)
    {
        if (taskSpecGasPriceCeil[_provider][hashTaskSpec(_taskSpec)] == 0)
            return "TaskSpecNotProvided";
        return OK;
    }

    // IGelatoProviderModule: GelatoCore canSubmit & canExec
    function providerModuleChecks(
        address _userProxy,
        Provider memory _provider,
        Task memory _task
    )
        public
        view
        override
        returns(string memory)
    {
        if (!isModuleProvided(_provider.addr, _provider.module))
            return "InvalidProviderModule";

        if (_userProxy != _provider.addr) {
            IGelatoProviderModule providerModule = IGelatoProviderModule(
                _provider.module
            );

            try providerModule.isProvided(_userProxy, _provider.addr, _task)
                returns(string memory res)
            {
                return res;
            } catch {
                return "GelatoProviders.providerModuleChecks";
            }
        } else return OK;
    }

    // GelatoCore: canSubmit
    function isTaskProvided(
        address _userProxy,
        Provider memory _provider,
        Task memory _task
    )
        public
        view
        override
        returns(string memory res)
    {
        TaskSpec memory _taskSpec = _castTaskToSpec(_task);
        res = isTaskSpecProvided(_provider.addr, _taskSpec);
        if (res.startsWithOK())
            return providerModuleChecks(_userProxy, _provider, _task);
    }

    // GelatoCore canExec Gate
    function providerCanExec(
        address _userProxy,
        Provider memory _provider,
        Task memory _task,
        uint256 _gelatoGasPrice
    )
        public
        view
        override
        returns(string memory)
    {
        if (_userProxy == _provider.addr) {
            if (_task.selfProviderGasPriceCeil < _gelatoGasPrice)
                return "SelfProviderGasPriceCeil";
        } else {
            bytes32 taskSpecHash = hashTaskSpec(_castTaskToSpec(_task));
            if (taskSpecGasPriceCeil[_provider.addr][taskSpecHash] < _gelatoGasPrice)
                return "taskSpecGasPriceCeil-OR-notProvided";
        }
        return providerModuleChecks(_userProxy, _provider, _task);
    }

    // Provider Funding
    function provideFunds(address _provider) public payable override {
        require(msg.value > 0, "GelatoProviders.provideFunds: zero value");
        uint256 newProviderFunds = providerFunds[_provider].add(msg.value);
        emit LogFundsProvided(_provider, msg.value, newProviderFunds);
        providerFunds[_provider] = newProviderFunds;
    }

    // Unprovide funds
    function unprovideFunds(uint256 _withdrawAmount)
        public
        override
        returns(uint256 realWithdrawAmount)
    {
        uint256 previousProviderFunds = providerFunds[msg.sender];
        realWithdrawAmount = Math.min(_withdrawAmount, previousProviderFunds);

        uint256 newProviderFunds = previousProviderFunds - realWithdrawAmount;

        // Effects
        providerFunds[msg.sender] = newProviderFunds;

        // Interaction
        msg.sender.sendValue(realWithdrawAmount);

        emit LogFundsUnprovided(msg.sender, realWithdrawAmount, newProviderFunds);
    }

    // Called by Providers
    function providerAssignsExecutor(address _newExecutor) public override {
        address currentExecutor = executorByProvider[msg.sender];

        // CHECKS
        require(
            currentExecutor != _newExecutor,
            "GelatoProviders.providerAssignsExecutor: already assigned."
        );
        if (_newExecutor != address(0)) {
            require(
                isExecutorMinStaked(_newExecutor),
                "GelatoProviders.providerAssignsExecutor: isExecutorMinStaked()"
            );
        }

        // EFFECTS: Provider reassigns from currentExecutor to newExecutor (or no executor)
        if (currentExecutor != address(0)) executorProvidersCount[currentExecutor]--;
        executorByProvider[msg.sender] = _newExecutor;
        if (_newExecutor != address(0)) executorProvidersCount[_newExecutor]++;

        emit LogProviderAssignedExecutor(msg.sender, currentExecutor, _newExecutor);
    }

    // Called by Executors
    function executorAssignsExecutor(address _provider, address _newExecutor) public override {
        address currentExecutor = executorByProvider[_provider];

        // CHECKS
        require(
            currentExecutor == msg.sender,
            "GelatoProviders.executorAssignsExecutor: msg.sender is not assigned executor"
        );
        require(
            currentExecutor != _newExecutor,
            "GelatoProviders.executorAssignsExecutor: already assigned."
        );
        // Checks at the same time if _nexExecutor != address(0)
        require(
            isExecutorMinStaked(_newExecutor),
            "GelatoProviders.executorAssignsExecutor: isExecutorMinStaked()"
        );

        // EFFECTS: currentExecutor reassigns to newExecutor
        executorProvidersCount[currentExecutor]--;
        executorByProvider[_provider] = _newExecutor;
        executorProvidersCount[_newExecutor]++;

        emit LogExecutorAssignedExecutor(_provider, currentExecutor, _newExecutor);
    }

    // (Un-)provide Condition Action Combos at different Gas Price Ceils
    function provideTaskSpecs(TaskSpec[] memory _taskSpecs) public override {
        for (uint i; i < _taskSpecs.length; i++) {
            if (_taskSpecs[i].gasPriceCeil == 0) _taskSpecs[i].gasPriceCeil = NO_CEIL;
            bytes32 taskSpecHash = hashTaskSpec(_taskSpecs[i]);
            setTaskSpecGasPriceCeil(taskSpecHash, _taskSpecs[i].gasPriceCeil);
            emit LogTaskSpecProvided(msg.sender, taskSpecHash);
        }
    }

    function unprovideTaskSpecs(TaskSpec[] memory _taskSpecs) public override {
        for (uint i; i < _taskSpecs.length; i++) {
            bytes32 taskSpecHash = hashTaskSpec(_taskSpecs[i]);
            require(
                taskSpecGasPriceCeil[msg.sender][taskSpecHash] != 0,
                "GelatoProviders.unprovideTaskSpecs: redundant"
            );
            delete taskSpecGasPriceCeil[msg.sender][taskSpecHash];
            emit LogTaskSpecUnprovided(msg.sender, taskSpecHash);
        }
    }

    function setTaskSpecGasPriceCeil(bytes32 _taskSpecHash, uint256 _gasPriceCeil)
        public
        override
    {
            uint256 currentTaskSpecGasPriceCeil = taskSpecGasPriceCeil[msg.sender][_taskSpecHash];
            require(
                currentTaskSpecGasPriceCeil != _gasPriceCeil,
                "GelatoProviders.setTaskSpecGasPriceCeil: Already whitelisted with gasPriceCeil"
            );
            taskSpecGasPriceCeil[msg.sender][_taskSpecHash] = _gasPriceCeil;
            emit LogTaskSpecGasPriceCeilSet(
                msg.sender,
                _taskSpecHash,
                currentTaskSpecGasPriceCeil,
                _gasPriceCeil
            );
    }

    // Provider Module
    function addProviderModules(IGelatoProviderModule[] memory _modules) public override {
        for (uint i; i < _modules.length; i++) {
            require(
                !isModuleProvided(msg.sender, _modules[i]),
                "GelatoProviders.addProviderModules: redundant"
            );
            _providerModules[msg.sender].add(_modules[i]);
            emit LogProviderModuleAdded(msg.sender, _modules[i]);
        }
    }

    function removeProviderModules(IGelatoProviderModule[] memory _modules) public override {
        for (uint i; i < _modules.length; i++) {
            require(
                isModuleProvided(msg.sender, _modules[i]),
                "GelatoProviders.removeProviderModules: redundant"
            );
            _providerModules[msg.sender].remove(_modules[i]);
            emit LogProviderModuleRemoved(msg.sender, _modules[i]);
        }
    }

    // Batch (un-)provide
    function multiProvide(
        address _executor,
        TaskSpec[] memory _taskSpecs,
        IGelatoProviderModule[] memory _modules
    )
        public
        payable
        override
    {
        if (msg.value != 0) provideFunds(msg.sender);
        if (_executor != address(0)) providerAssignsExecutor(_executor);
        provideTaskSpecs(_taskSpecs);
        addProviderModules(_modules);
    }

    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] memory _taskSpecs,
        IGelatoProviderModule[] memory _modules
    )
        public
        override
    {
        if (_withdrawAmount != 0) unprovideFunds(_withdrawAmount);
        unprovideTaskSpecs(_taskSpecs);
        removeProviderModules(_modules);
    }

    // Provider Liquidity
    function minExecProviderFunds(uint256 _gelatoMaxGas, uint256 _gelatoGasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 maxExecTxCost = (EXEC_TX_OVERHEAD + _gelatoMaxGas) * _gelatoGasPrice;
        return maxExecTxCost + (maxExecTxCost * totalSuccessShare) / 100;
    }

    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        public
        view
        override
        returns(bool)
    {
        return minExecProviderFunds(_gelatoMaxGas, _gelatoGasPrice) <= providerFunds[_provider];
    }

    // An Executor qualifies and remains registered for as long as he has minExecutorStake
    function isExecutorMinStaked(address _executor) public view override returns(bool) {
        return executorStake[_executor] >= minExecutorStake;
    }

    // Providers' Executor Assignment
    function isExecutorAssigned(address _executor) public view override returns(bool) {
        return executorProvidersCount[_executor] != 0;
    }

    // Helper fn that can also be called to query taskSpecHash off-chain
    function hashTaskSpec(TaskSpec memory _taskSpec) public view override returns(bytes32) {
        NoDataAction[] memory noDataActions = new NoDataAction[](_taskSpec.actions.length);
        for (uint i = 0; i < _taskSpec.actions.length; i++) {
            NoDataAction memory noDataAction = NoDataAction({
                addr: _taskSpec.actions[i].addr,
                operation: _taskSpec.actions[i].operation,
                dataFlow: _taskSpec.actions[i].dataFlow,
                value: _taskSpec.actions[i].value == 0 ? false : true,
                termsOkCheck: _taskSpec.actions[i].termsOkCheck
            });
            noDataActions[i] = noDataAction;
        }
        return keccak256(abi.encode(_taskSpec.conditions, noDataActions));
    }

    // Providers' Module Getters
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        public
        view
        override
        returns(bool)
    {
        return _providerModules[_provider].contains(_module);
    }

    function providerModules(address _provider)
        external
        view
        override
        returns(IGelatoProviderModule[] memory)
    {
        return _providerModules[_provider].enumerate();
    }

    // Internal helper for is isTaskProvided() and providerCanExec
    function _castTaskToSpec(Task memory _task)
        private
        pure
        returns(TaskSpec memory taskSpec)
    {
        taskSpec = TaskSpec({
            conditions: _stripConditionData(_task.conditions),
            actions: _task.actions,
            gasPriceCeil: 0  // default: provider can set gasPriceCeil dynamically.
        });
    }

    function _stripConditionData(Condition[] memory _conditionsWithData)
        private
        pure
        returns(IGelatoCondition[] memory conditionInstances)
    {
        conditionInstances = new IGelatoCondition[](_conditionsWithData.length);
        for (uint i; i < _conditionsWithData.length; i++)
            conditionInstances[i] = _conditionsWithData[i].inst;
    }

}
"
    },
    "contracts/gelato_core/GelatoSysAdmin.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {IGelatoSysAdmin} from "./interfaces/IGelatoSysAdmin.sol";
import {Ownable} from "../external/Ownable.sol";
import {Address} from "../external/Address.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {Math} from "../external/Math.sol";

abstract contract GelatoSysAdmin is IGelatoSysAdmin, Ownable {

    using Address for address payable;
    using GelatoBytes for bytes;
    using SafeMath for uint256;

    // Executor compensation for estimated tx costs not accounted for by startGas
    uint256 public constant override EXEC_TX_OVERHEAD = 55000;
    string internal constant OK = "OK";

    address public override gelatoGasPriceOracle;
    bytes public override oracleRequestData;
    uint256 public override gelatoMaxGas;
    uint256 public override internalGasRequirement;
    uint256 public override minExecutorStake;
    uint256 public override executorSuccessShare;
    uint256 public override sysAdminSuccessShare;
    uint256 public override totalSuccessShare;
    uint256 public override sysAdminFunds;

    // == The main functions of the Sys Admin (DAO) ==
    // The oracle defines the system-critical gelatoGasPrice
    function setGelatoGasPriceOracle(address _newOracle) external override onlyOwner {
        require(_newOracle != address(0), "GelatoSysAdmin.setGelatoGasPriceOracle: 0");
        emit LogGelatoGasPriceOracleSet(gelatoGasPriceOracle, _newOracle);
        gelatoGasPriceOracle = _newOracle;
    }

    function setOracleRequestData(bytes calldata _requestData) external override onlyOwner {
        emit LogOracleRequestDataSet(oracleRequestData, _requestData);
        oracleRequestData = _requestData;
    }

    // exec-tx gasprice: pulled in from the Oracle by the Executor during exec()
    function _getGelatoGasPrice() internal view returns(uint256) {
        (bool success, bytes memory returndata) = gelatoGasPriceOracle.staticcall(
            oracleRequestData
        );
        if (!success)
            returndata.revertWithErrorString("GelatoSysAdmin._getGelatoGasPrice:");
        int oracleGasPrice = abi.decode(returndata, (int256));
        if (oracleGasPrice <= 0) revert("GelatoSysAdmin._getGelatoGasPrice:0orBelow");
        return uint256(oracleGasPrice);
    }

    // exec-tx gas
    function setGelatoMaxGas(uint256 _newMaxGas) external override onlyOwner {
        emit LogGelatoMaxGasSet(gelatoMaxGas, _newMaxGas);
        gelatoMaxGas = _newMaxGas;
    }

    // exec-tx GelatoCore internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external override onlyOwner {
        emit LogInternalGasRequirementSet(internalGasRequirement, _newRequirement);
        internalGasRequirement = _newRequirement;
    }

    // Minimum Executor Stake Per Provider
    function setMinExecutorStake(uint256 _newMin) external override onlyOwner {
        emit LogMinExecutorStakeSet(minExecutorStake, _newMin);
        minExecutorStake = _newMin;
    }

    // Executors' profit share on exec costs
    function setExecutorSuccessShare(uint256 _percentage) external override onlyOwner {
        emit LogExecutorSuccessShareSet(
            executorSuccessShare,
            _percentage,
            _percentage + sysAdminSuccessShare
        );
        executorSuccessShare = _percentage;
        totalSuccessShare = _percentage + sysAdminSuccessShare;
    }

    // Sys Admin (DAO) Business Model
    function setSysAdminSuccessShare(uint256 _percentage) external override onlyOwner {
        emit LogSysAdminSuccessShareSet(
            sysAdminSuccessShare,
            _percentage,
            executorSuccessShare + _percentage
        );
        sysAdminSuccessShare = _percentage;
        totalSuccessShare = executorSuccessShare + _percentage;
    }

    function withdrawSysAdminFunds(uint256 _amount, address payable _to)
        external
        override
        onlyOwner
        returns(uint256 realWithdrawAmount)
    {
        uint256 currentBalance = sysAdminFunds;

        realWithdrawAmount = Math.min(_amount, currentBalance);

        uint256 newSysAdminFunds = currentBalance - realWithdrawAmount;

        // Effects
        sysAdminFunds = newSysAdminFunds;

        _to.sendValue(realWithdrawAmount);
        emit LogSysAdminFundsWithdrawn(currentBalance, newSysAdminFunds);
    }

    // Executors' total fee for a successful exec
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 estExecCost = _gas.mul(_gasPrice);
        return estExecCost + estExecCost.mul(executorSuccessShare).div(
            100,
            "GelatoSysAdmin.executorSuccessFee: div error"
        );
    }

    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 estExecCost = _gas.mul(_gasPrice);
        return
            estExecCost.mul(sysAdminSuccessShare).div(
            100,
            "GelatoSysAdmin.sysAdminSuccessShare: div error"
        );
    }
}
"
    },
    "contracts/libraries/GelatoString.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns(bool) {
        if (bytes(_str).length >= 2 && bytes(_str)[0] == "O" && bytes(_str)[1] == "K")
            return true;
        return false;
    }
}"
    },
    "contracts/external/Math.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

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
}"
    },
    "contracts/external/SafeMath.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

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
}"
    },
    "contracts/libraries/ProviderModuleSet.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";


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
 * As of v2.5.0, only `IGelatoProviderModule` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.Set;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta CaÃ±ada
 * @author Luis Schliessske (modified to ProviderModuleSet)
 */
library ProviderModuleSet {

    struct Set {
        // Position of the module in the `modules` array, plus 1 because index 0
        // means a module is not in the set.
        mapping (IGelatoProviderModule => uint256) index;
        IGelatoProviderModule[] modules;
    }

    /**
     * @dev Add a module to a set. O(1).
     * Returns false if the module was already in the set.
     */
    function add(Set storage set, IGelatoProviderModule module)
        internal
        returns (bool)
    {
        if (!contains(set, module)) {
            set.modules.push(module);
            // The element is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel module
            set.index[module] = set.modules.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a module from a set. O(1).
     * Returns false if the module was not present in the set.
     */
    function remove(Set storage set, IGelatoProviderModule module)
        internal
        returns (bool)
    {
        if (contains(set, module)){
            uint256 toDeleteIndex = set.index[module] - 1;
            uint256 lastIndex = set.modules.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                IGelatoProviderModule lastValue = set.modules[lastIndex];

                // Move the last module to the index where the deleted module is
                set.modules[toDeleteIndex] = lastValue;
                // Update the index for the moved module
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted module
            delete set.index[module];

            // Delete the old entry for the moved module
            set.modules.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the module is in the set. O(1).
     */
    function contains(Set storage set, IGelatoProviderModule module)
        internal
        view
        returns (bool)
    {
        return set.index[module] != 0;
    }

    /**
     * @dev Returns an array with all modules in the set. O(N).
     * Note that there are no guarantees on the ordering of modules inside the
     * array, and it may change when more modules are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Set storage set)
        internal
        view
        returns (IGelatoProviderModule[] memory)
    {
        IGelatoProviderModule[] memory output = new IGelatoProviderModule[](set.modules.length);
        for (uint256 i; i < set.modules.length; i++) output[i] = set.modules[i];
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.modules.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of modules inside the
    * array, and it may change when more modules are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Set storage set, uint256 index)
        internal
        view
        returns (IGelatoProviderModule)
    {
        return set.modules[index];
    }
}"
    },
    "contracts/gelato_core/interfaces/IGelatoSysAdmin.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IGelatoSysAdmin {
    struct GelatoSysAdminInitialState {
        address gelatoGasPriceOracle;
        bytes oracleRequestData;
        uint256 gelatoMaxGas;
        uint256 internalGasRequirement;
        uint256 minExecutorStake;
        uint256 executorSuccessShare;
        uint256 sysAdminSuccessShare;
        uint256 totalSuccessShare;
    }

    // Events
    event LogGelatoGasPriceOracleSet(address indexed oldOracle, address indexed newOracle);
    event LogOracleRequestDataSet(bytes oldData, bytes newData);

    event LogGelatoMaxGasSet(uint256 oldMaxGas, uint256 newMaxGas);
    event LogInternalGasRequirementSet(uint256 oldRequirment, uint256 newRequirment);

    event LogMinExecutorStakeSet(uint256 oldMin, uint256 newMin);

    event LogExecutorSuccessShareSet(uint256 oldShare, uint256 newShare, uint256 total);
    event LogSysAdminSuccessShareSet(uint256 oldShare, uint256 newShare, uint256 total);

    event LogSysAdminFundsWithdrawn(uint256 oldBalance, uint256 newBalance);

    // State Writing

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _newOracle Address of new oracle
    function setGelatoGasPriceOracle(address _newOracle) external;

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _requestData The encoded payload for the staticcall to the oracle.
    function setOracleRequestData(bytes calldata _requestData) external;

    /// @notice Assign new maximum gas limit providers can consume in executionWrapper()
    /// @dev Only callable by sysAdmin
    /// @param _newMaxGas New maximum gas limit
    function setGelatoMaxGas(uint256 _newMaxGas) external;

    /// @notice Assign new interal gas limit requirement for exec()
    /// @dev Only callable by sysAdmin
    /// @param _newRequirement New internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external;

    /// @notice Assign new minimum executor stake
    /// @dev Only callable by sysAdmin
    /// @param _newMin New minimum executor stake
    function setMinExecutorStake(uint256 _newMin) external;

    /// @notice Assign new success share for executors to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setExecutorSuccessShare(uint256 _percentage) external;

    /// @notice Assign new success share for sysAdmin to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setSysAdminSuccessShare(uint256 _percentage) external;

    /// @notice Withdraw sysAdmin funds
    /// @dev Only callable by sysAdmin
    /// @param _amount Amount to withdraw
    /// @param _to Address to receive the funds
    function withdrawSysAdminFunds(uint256 _amount, address payable _to) external returns(uint256);

    // State Reading
    /// @notice Unaccounted tx overhead that will be refunded to executors
    function EXEC_TX_OVERHEAD() external pure returns(uint256);

    /// @notice Addess of current Gelato Gas Price Oracle
    function gelatoGasPriceOracle() external view returns(address);

    /// @notice Getter for oracleRequestData state variable
    function oracleRequestData() external view returns(bytes memory);

    /// @notice Gas limit an executor has to submit to get refunded even if actions revert
    function gelatoMaxGas() external view returns(uint256);

    /// @notice Internal gas limit requirements ti ensure executor payout
    function internalGasRequirement() external view returns(uint256);

    /// @notice Minimum stake required from executors
    function minExecutorStake() external view returns(uint256);

    /// @notice % Fee executors get as a reward for a successful execution
    function executorSuccessShare() external view returns(uint256);

    /// @notice Total % Fee executors and sysAdmin collectively get as a reward for a successful execution
    /// @dev Saves a state read
    function totalSuccessShare() external view returns(uint256);

    /// @notice Get total fee providers pay executors for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns(uint256);

    /// @notice % Fee sysAdmin gets as a reward for a successful execution
    function sysAdminSuccessShare() external view returns(uint256);

    /// @notice Get total fee providers pay sysAdmin for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns(uint256);

    /// @notice Get sysAdminds funds
    function sysAdminFunds() external view returns(uint256);
}
"
    },
    "contracts/gelato_core/GelatoExecutors.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoExecutors} from "./interfaces/IGelatoExecutors.sol";
import {GelatoProviders} from "./GelatoProviders.sol";
import {Address} from  "../external/Address.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {Math} from "../external/Math.sol";

/// @title GelatoExecutors
/// @author Luis Schliesske & Hilmar Orth
/// @notice Stake Management of executors & batch Unproving providers
/// @dev Find all NatSpecs inside IGelatoExecutors
abstract contract GelatoExecutors is IGelatoExecutors, GelatoProviders {

    using Address for address payable;  /// for sendValue method
    using SafeMath for uint256;

    // Executor De/Registrations and Staking
    function stakeExecutor() external payable override {
        uint256 currentStake = executorStake[msg.sender];
        uint256 newStake = currentStake + msg.value;
        require(
            newStake >= minExecutorStake,
            "GelatoExecutors.stakeExecutor: below minStake"
        );
        executorStake[msg.sender] = newStake;
        emit LogExecutorStaked(msg.sender, currentStake, newStake);
    }

    function unstakeExecutor() external override {
        require(
            !isExecutorAssigned(msg.sender),
            "GelatoExecutors.unstakeExecutor: msg.sender still assigned"
        );
        uint256 unbondedStake = executorStake[msg.sender];
        require(
            unbondedStake != 0,
            "GelatoExecutors.unstakeExecutor: already unstaked"
        );
        delete executorStake[msg.sender];
        msg.sender.sendValue(unbondedStake);
        emit LogExecutorUnstaked(msg.sender);
    }

    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        override
        returns(uint256 realWithdrawAmount)
    {
        require(
            isExecutorMinStaked(msg.sender),
            "GelatoExecutors.withdrawExcessExecutorStake: not minStaked"
        );

        uint256 currentExecutorStake = executorStake[msg.sender];
        uint256 excessExecutorStake = currentExecutorStake - minExecutorStake;

        realWithdrawAmount = Math.min(_withdrawAmount, excessExecutorStake);

        uint256 newExecutorStake = currentExecutorStake - realWithdrawAmount;

        // Effects
        executorStake[msg.sender] = newExecutorStake;

        // Interaction
        msg.sender.sendValue(realWithdrawAmount);
        emit LogExecutorBalanceWithdrawn(msg.sender, realWithdrawAmount);
    }

    // To unstake, Executors must reassign ALL their Providers to another staked Executor
    function multiReassignProviders(address[] calldata _providers, address _newExecutor)
        external
        override
    {
        for (uint i; i < _providers.length; i++)
            executorAssignsExecutor(_providers[i], _newExecutor);
    }
}"
    },
    "contracts/gelato_core/interfaces/IGelatoExecutors.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IGelatoExecutors {
    event LogExecutorStaked(address indexed executor, uint256 oldStake, uint256 newStake);
    event LogExecutorUnstaked(address indexed executor);

    event LogExecutorBalanceWithdrawn(
        address indexed executor,
        uint256 withdrawAmount
    );

    /// @notice Stake on Gelato to become a whitelisted executor
    /// @dev Msg.value has to be >= minExecutorStake
    function stakeExecutor() external payable;

    /// @notice Unstake on Gelato to become de-whitelisted and withdraw minExecutorStake
    function unstakeExecutor() external;

    /// @notice Re-assigns multiple providers to other executors
    /// @dev Executors must re-assign all providers before being able to unstake
    /// @param _providers List of providers to re-assign
    /// @param _newExecutor Address of new executor to assign providers to
    function multiReassignProviders(address[] calldata _providers, address _newExecutor)
        external;


    /// @notice Withdraw excess Execur Stake
    /// @dev Can only be called if executor is isExecutorMinStaked
    /// @param _withdrawAmount Amount to withdraw
    /// @return Amount that was actually withdrawn
    function withdrawExcessExecutorStake(uint256 _withdrawAmount) external returns(uint256);

}
"
    },
    "contracts/gelato_actions/transfer/ActionTransfer.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {IERC20} from "../../external/IERC20.sol";
import {Address} from "../../external/Address.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";

/// @dev This action is for user proxies that store funds.
contract ActionTransfer is GelatoActionsStandardFull {
    // using SafeERC20 for IERC20; <- internal library methods vs. try/catch
    using Address for address payable;
    using SafeERC20 for IERC20;

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    function getActionData(address _sendToken, uint256 _sendAmount, address _destination)
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _sendToken,
            _sendAmount,
            _destination
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @dev Always use this function for encoding _actionData off-chain
    ///  Will be called by GelatoActionPipeline if Action.dataFlow.None
    function action(address sendToken, uint256 sendAmount, address destination)
        public
        virtual
        delegatecallOnly("ActionTransfer.action")
    {
        if (sendToken != ETH_ADDRESS) {
            IERC20 sendERC20 = IERC20(sendToken);
            sendERC20.safeTransfer(destination, sendAmount, "ActionTransfer.action:");
            emit LogOneWay(address(this), sendToken, sendAmount, destination);
        } else {
            payable(destination).sendValue(sendAmount);
        }
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        address destination = abi.decode(_actionData[68:100], (address));
        action(sendToken, sendAmount, destination);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sendToken, uint256 sendAmount, address destination) = abi.decode(
            _actionData[4:],
            (address,uint256,address)
        );
        action(sendToken, sendAmount, destination);
        return abi.encode(sendToken, sendAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        address destination = abi.decode(_actionData[68:100], (address));
        action(sendToken, sendAmount, destination);
        return abi.encode(sendToken, sendAmount);
    }

    // ===== ACTION TERMS CHECK ========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionTransfer: invalid action selector";

        if (_dataFlow == DataFlow.In || _dataFlow == DataFlow.InAndOut)
            return "ActionTransfer: termsOk check invalidated by inbound DataFlow";

        (address sendToken, uint256 sendAmount) = abi.decode(
            _actionData[4:68],
            (address,uint256)
        );

        if (sendToken == ETH_ADDRESS) {
            if (_userProxy.balance < sendAmount)
                return "ActionTransfer: NotOkUserProxyETHBalance";
        } else {
            try IERC20(sendToken).balanceOf(_userProxy) returns(uint256 sendTokenBalance) {
                if (sendTokenBalance < sendAmount)
                    return "ActionTransfer: NotOkUserProxyERC20Balance";
            } catch {
                return "ActionTransfer: ErrorBalanceOf";
            }
        }

        // STANDARD return string to signal actionConditions Ok
        return OK;
    }
}
"
    },
    "contracts/gelato_actions/GelatoActionsStandardFull.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "./GelatoActionsStandard.sol";
import {IGelatoInFlowAction} from "./action_pipeline_interfaces/IGelatoInFlowAction.sol";
import {IGelatoOutFlowAction} from "./action_pipeline_interfaces/IGelatoOutFlowAction.sol";
import {
    IGelatoInAndOutFlowAction
} from "./action_pipeline_interfaces/IGelatoInAndOutFlowAction.sol";

/// @title GelatoActionsStandardFull
/// @notice ActionStandard that inherits from all the PipeAction interfaces.
/// @dev Inherit this to enforce implementation of all PipeAction functions.
abstract contract GelatoActionsStandardFull is
    GelatoActionsStandard,
    IGelatoInFlowAction,
    IGelatoOutFlowAction,
    IGelatoInAndOutFlowAction
{
    function DATA_FLOW_IN_TYPE()
        external
        pure
        virtual
        override(IGelatoInFlowAction, IGelatoInAndOutFlowAction)
        returns (bytes32);

    function DATA_FLOW_OUT_TYPE()
        external
        pure
        virtual
        override(IGelatoOutFlowAction, IGelatoInAndOutFlowAction)
        returns (bytes32);
}"
    },
    "contracts/external/IERC20.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

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
    },
    "contracts/external/SafeERC20.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @notice Adapted by @gitpusha from Gelato to include error strings.
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value, string memory context)
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value),
            context
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value,
        string memory context
    )
        internal
    {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value),
            context
        );
    }

    function safeApprove(IERC20 token, address spender, uint256 value, string memory context)
        internal
    {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            string(
                abi.encodePacked(
                    context, "SafeERC20: approve from non-zero to non-zero allowance"
                )
            )
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value),
            context
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value,
        string memory context
    )
        internal
    {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance),
            context
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value,
        string memory context
    )
        internal
    {
        uint256 newAllowance = token.allowance(
            address(this),
            spender
        ).sub(
            value,
            string(abi.encodePacked(context, "SafeERC20: decreased allowance below zero")
        ));
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance),
            context
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     * @param context Debugging Info for the revert message (addition to original library)
     */
    function callOptionalReturn(IERC20 token, bytes memory data, string memory context)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(
            address(token).isContract(),
            string(abi.encodePacked(context, "SafeERC20: call to non-contract"))
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(
            success, string(abi.encodePacked(context, "SafeERC20: low-level call failed"))
        );

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                string(
                    abi.encodePacked(context, "SafeERC20: ERC20 operation did not succeed")
                )
            );
        }
    }
}
"
    },
    "contracts/mocks/gelato_actions/one-off/Gnosis/MockBatchExchange.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "../../../../gelato_actions/GelatoActionsStandard.sol";
import {SafeERC20} from "../../../../external/SafeERC20.sol";
import {IERC20} from "../../../../external/IERC20.sol";

contract MockBatchExchange {

    using SafeERC20 for IERC20;

    event LogWithdrawRequest();
    event LogCounter();

    mapping(address => uint256) public withdrawAmounts;
    mapping(address => bool) public validWithdrawRequests;

    uint256 public counter;

    function withdraw(address _proxyAddress, address _token)
        public
    {
        IERC20 token = IERC20(_token);
        uint256 withdrawAmount = withdrawAmounts[_token];
        token.safeTransfer(_proxyAddress, withdrawAmount, "MockBatchExchange.withdraw");
    }

    function setWithdrawAmount(address _token, uint256 _withdrawAmount)
        public
    {
        IERC20 token = IERC20(_token);
        require(
            token.balanceOf(address(this)) >= _withdrawAmount,
            "MockBatchExchange: Insufficient Token balance"
        );
        withdrawAmounts[_token] = _withdrawAmount;
    }

    function hasValidWithdrawRequest(address _proxyAddress, address)
        view
        public
        returns(bool)
    {
        if (validWithdrawRequests[_proxyAddress]) return true;
    }

    function setValidWithdrawRequest(address _proxyAddress)
        public
    {
        validWithdrawRequests[_proxyAddress] = true;
        emit LogWithdrawRequest();
        counter++;
        if(counter == 1 ) emit LogCounter();
    }

    // buyTokenId, sellTokenId, withdrawBatchId, _buyAmount, sellAmount
    function placeOrder(uint16 buyToken, uint16 sellToken, uint32 validUntil, uint128 buyAmount, uint128 sellAmount)
        public
        returns (uint256)
    {

    }

    function deposit(address _sellToken, uint128 _sellAmount)
        public
    {
        IERC20 sellToken = IERC20(_sellToken);
        sellToken.safeTransferFrom(
            msg.sender, address(this), _sellAmount, "MockBatchExchange.deposit:"
        );
    }

    function requestFutureWithdraw(address token, uint256 amount, uint32 batchId)
        public
    {
    }

    function tokenAddressToIdMap(address _token)
        public
        view
        returns(uint16 test)
    {

    }


}
"
    },
    "contracts/gelato_conditions/price/kyber/ConditionKyberRateStateful.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoStatefulConditionsStandard} from "../../GelatoStatefulConditionsStandard.sol";
import {IKyberNetworkProxy} from "../../../dapp_interfaces/kyber/IKyberNetworkProxy.sol";
import {SafeMath} from "../../../external/SafeMath.sol";
import {IERC20} from "../../../external/IERC20.sol";
import {IGelatoCore} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract ConditionKyberRateStateful is GelatoStatefulConditionsStandard {
    using SafeMath for uint256;

    IKyberNetworkProxy public immutable KYBER;

    // userProxy => taskReceipt.id => refPrice
    mapping(address => mapping(uint256 => uint256)) public refRate;

    constructor(IKyberNetworkProxy _kyberNetworkProxy, IGelatoCore _gelatoCore)
        public
        GelatoStatefulConditionsStandard(_gelatoCore)
    {
        KYBER = _kyberNetworkProxy;
    }

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(
        address _userProxy,
        address _sendToken,
        uint256 _sendAmount,
        address _receiveToken,
        bool _greaterElseSmaller
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.checkRefKyberRate.selector,
            uint256(0),  // taskReceiptId placeholder
            _userProxy,
            _sendToken,
            _sendAmount,
            _receiveToken,
            _greaterElseSmaller
        );
    }

    // STANDARD Interface
    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address userProxy,
         address sendToken,
         uint256 sendAmount,
         address receiveToken,
         bool greaterElseSmaller
        ) = abi.decode(
             _conditionData[36:],  // slice out selector & taskReceiptId
             (address,address,uint256,address,bool)
         );
        return checkRefKyberRate(
            _taskReceiptId, userProxy, sendToken, sendAmount, receiveToken, greaterElseSmaller
        );
    }

    // Specific Implementation
    function checkRefKyberRate(
        uint256 _taskReceiptId,
        address _userProxy,
        address _sendToken,
        uint256 _sendAmount,
        address _receiveToken,
        bool _greaterElseSmaller
    )
        public
        view
        virtual
        returns(string memory)
    {
        uint256 currentRefRate = refRate[_userProxy][_taskReceiptId];
        try KYBER.getExpectedRate(_sendToken, _receiveToken, _sendAmount)
            returns(uint256 expectedRate, uint256)
        {
            if (_greaterElseSmaller) {  // greaterThan
                if (expectedRate >= currentRefRate) return OK;
                return "NotOkKyberExpectedRateIsNotGreaterThanRefRate";
            } else {  // smallerThan
                if (expectedRate <= currentRefRate) return OK;
                return "NotOkKyberExpectedRateIsNotSmallerThanRefRate";
            }
        } catch {
            return "KyberGetExpectedRateError";
        }
    }

    /// @dev This function should be called via the userProxy of a Gelato Task as part
    ///  of the Task.actions, if the Condition state should be updated after the task.
    /// @param _rateDelta The change in price after which this condition should return for a given taskId
    /// @param _idDelta Default to 0. If you submit multiple tasks in one action, this can help
    // customize which taskId the state should be allocated to
    function setRefRate(
        address _sendToken,
        uint256 _sendAmount,
        address _receiveToken,
        bool _greaterElseSmaller,
        uint256 _rateDelta,
        uint256 _idDelta
    )
        external
    {
        uint256 taskReceiptId = _getIdOfNextTaskInCycle() + _idDelta;
        try KYBER.getExpectedRate(_sendToken, _receiveToken, _sendAmount)
            returns(uint256 expectedRate, uint256)
        {
            if (_greaterElseSmaller) {
                refRate[msg.sender][taskReceiptId] = expectedRate.add(_rateDelta);
            } else {
                refRate[msg.sender][taskReceiptId] = expectedRate.sub(
                    _rateDelta,
                    "ConditionKyberRateStateful.setRefRate: Underflow"
                );
            }
        } catch {
            revert("ConditionKyberRateStateful.setRefRate: KyberGetExpectedRateError");
        }
    }

    function getKyberRate(address _sendToken, uint256 _sendAmount, address _receiveToken)
        external
        view
        returns(uint256)
    {
        try KYBER.getExpectedRate(_sendToken, _receiveToken, _sendAmount)
            returns(uint256 expectedRate, uint256)
        {
            return expectedRate;
        } catch {
            revert("ConditionKyberRateStateful.setRefRate: KyberGetExpectedRateError");
        }
    }
}"
    },
    "contracts/dapp_interfaces/kyber/IKyberNetworkProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

/// @title IKyberNetworkProxy
/// @notice Interface to the KyberNetworkProxy contract.
///  The KyberNetworkProxy contract's role is to facilitate two main functionalities:
///  1) return the expected exchange rate, and 2) to execute a trade.
/// @dev https://developer.kyber.network/docs/API_ABI-KyberNetworkProxy/
interface IKyberNetworkProxy {
    /**
     * @dev Makes a trade between src and dest token and send dest tokens to destAddress
     * @param src source ERC20 token contract address
     * @param srcAmount source ERC20 token amount in its token decimals
     * @param dest destination ERC20 token contract address
     * @param destAddress recipient address for destination ERC20 token
     * @param maxDestAmount limit on the amount of destination tokens
     * @param minConversionRate minimum conversion rate; trade is canceled if actual rate is lower
     * @param walletId wallet address to send part of the fees to
     * @return Amount of actual destination tokens
     * @notice srcAmount | maxDestAmount These amounts should be in the source and
         destination token decimals respectively. For example, if the user wants to swap
         from / to 10 POWR,which has 6 decimals, it would be 10 * (10 ** 6) = 10000000
     * @notice maxDestAmount should not be 0. Set it to an arbitarily large amount
         if you want all source tokens to be converted.
     * @notice minConversionRate: This rate is independent of the source and
         destination token decimals. To calculate this rate, take yourRate * 10**18.
         For example, even though ZIL has 12 token decimals, if we want the minimum
         conversion rate to be 1 ZIL = 0.00017 ETH, then
         minConversionRate = 0.00017 * (10 ** 18).
     * @notice walletId: If you are part of our fee sharing program, this will be
         your registered wallet address. Set it as 0 if you are not a participant.
     * @notice Since ETH is not an ERC20 token, we use
        0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee as a proxy address to represent it.
     * @notice If src is ETH, then you also need to send ether along with your call.
     * @notice There is a minimum trading value of 1000 wei tokens.
        Anything fewer is considered as 0.
     */
    function trade(
        address src,
        uint256 srcAmount,
        address dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId
    )
        external
        payable
        returns (uint256);

    /**
     * @dev Get the expected exchange rate.
     * @param src source ERC20 token contract address
     * @param dest destination ERC20 token contract address
     * @param srcQty wei amount of source ERC20 token
     * @return The expected exchange rate and slippage rate.
     * @notice Returned values are in precision values (10**18)
        To understand what this rate means, divide the obtained value by 10**18
        (tA, tB,)
     */
    function getExpectedRate(address src, address dest, uint256 srcQty)
        external
        view
        returns (uint256, uint256);
}
"
    },
    "contracts/gelato_conditions/price/kyber/ConditionKyberRate.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoConditionsStandard} from "../../GelatoConditionsStandard.sol";
import {IKyberNetworkProxy} from "../../../dapp_interfaces/kyber/IKyberNetworkProxy.sol";
import {SafeMath} from "../../../external/SafeMath.sol";

contract ConditionKyberRate is GelatoConditionsStandard {
    using SafeMath for uint256;

    IKyberNetworkProxy public immutable KYBER;
    constructor(IKyberNetworkProxy _kyberProxy) public { KYBER = _kyberProxy; }

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(
        address _src,
        uint256 _srcAmt,
        address _dest,
        uint256 _refRate,
        bool _greaterElseSmaller
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.checkRate.selector,
            _src,
            _srcAmt,
            _dest,
            _refRate,
            _greaterElseSmaller
        );
    }

    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address src,
         uint256 srcAmt,
         address dest,
         uint256 refRate,
         bool greaterElseSmaller) = abi.decode(
            _conditionData[4:],
            (address,uint256,address,uint256,bool)
        );
        return checkRate(src, srcAmt, dest, refRate, greaterElseSmaller);
    }

    // Specific Implementation
    function checkRate(
        address _src,
        uint256 _srcAmt,
        address _dest,
        uint256 _refRate,
        bool _greaterElseSmaller
    )
        public
        view
        virtual
        returns(string memory)
    {
        try KYBER.getExpectedRate(_src, _dest, _srcAmt)
            returns(uint256 expectedRate, uint256)
        {
            if (_greaterElseSmaller) {  // greaterThan
                if (expectedRate >= _refRate) return OK;
                return "NotOkKyberExpectedRateIsNotGreaterThanRefRate";
            } else {  // smallerThan
                if (expectedRate <= _refRate) return OK;
                return "NotOkKyberExpectedRateIsNotSmallerThanRefRate";
            }
        } catch {
            return "KyberGetExpectedRateError";
        }
    }
}"
    },
    "contracts/mocks/gelato_conditions/MockConditionDummyRevert.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoConditionsStandard} from "../../gelato_conditions/GelatoConditionsStandard.sol";

contract MockConditionDummyRevert is GelatoConditionsStandard {
    // STANDARD interface
    function ok(uint256, bytes calldata _revertCheckData, uint256)
        external
        view
        virtual
        override
        returns(string memory)
    {
        bool returnOk = abi.decode(_revertCheckData, (bool));
        return revertCheck(returnOk);
    }

    function revertCheck(bool _returnOk) public pure virtual returns(string memory) {
        if (_returnOk) return OK;
        revert("MockConditionDummyRevert.ok: test revert");
    }
}"
    },
    "contracts/mocks/gelato_conditions/MockConditionDummy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoConditionsStandard} from "../../gelato_conditions/GelatoConditionsStandard.sol";

contract MockConditionDummy is GelatoConditionsStandard {
    // STANDARD interface
    function ok(uint256, bytes calldata _dummyCheckData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        bool returnOk = abi.decode(_dummyCheckData, (bool));
        return dummyCheck(returnOk);
    }

    function dummyCheck(bool _returnOk) public pure virtual returns(string memory returnString) {
       _returnOk ? returnString = OK : returnString = "NotOk";
    }
}"
    },
    "contracts/gelato_conditions/gnosis/ConditionBatchExchangeFundsWithdrawable.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "../GelatoConditionsStandard.sol";
import "../../dapp_interfaces/gnosis/IBatchExchange.sol";

contract ConditionBatchExchangeFundsWithdrawable is GelatoConditionsStandard {

    address public immutable batchExchangeAddress;
    constructor(address _batchExchange) public { batchExchangeAddress = _batchExchange; }

    function ok(uint256, bytes calldata _withdrawableCheckData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address proxy, address sellToken, address buyToken) = abi.decode(
            _withdrawableCheckData,
            (address,address,address)
        );
        return withdrawableCheck(proxy, sellToken, buyToken);
    }

    function withdrawableCheck(address _proxy, address _sellToken, address _buyToken)
        public
        view
        virtual
        returns(string memory)  // executable?
    {
        (bool sellTokenWithdrawable, bool buyTokenWithdrawable) = getConditionValue(
            _proxy,
            _sellToken,
            _buyToken
        );
        if (!sellTokenWithdrawable) return "SellTokenNotWithdrawable";
        if (!buyTokenWithdrawable) return "BuyTokenNotWithdrawable";
        return OK;
    }

    function getConditionValue(
        address _proxy,
        address _sellToken,
        address _buyToken
    )
        public
        view
        returns(bool sellTokenWithdrawable, bool buyTokenWithdrawable)
    {
        IBatchExchange batchExchange = IBatchExchange(batchExchangeAddress);
        sellTokenWithdrawable = batchExchange.hasValidWithdrawRequest(_proxy, _sellToken);
        buyTokenWithdrawable = batchExchange.hasValidWithdrawRequest(_proxy, _buyToken);
    }
}"
    },
    "contracts/gelato_conditions/eth_utils/eth_time/ConditionTime.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoConditionsStandard} from "../../GelatoConditionsStandard.sol";

contract ConditionTime is GelatoConditionsStandard {

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(uint256 _timestamp)
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encode(_timestamp);
    }

    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        uint256 timestamp = abi.decode(_conditionData, (uint256));
        return timeCheck(timestamp);
    }

    // Specific implementation
    function timeCheck(uint256 _timestamp) public view virtual returns(string memory) {
        if (_timestamp <= block.timestamp) return OK;
        return "NotOkTimestampDidNotPass";
    }
}"
    },
    "contracts/gelato_conditions/eth_utils/eth_time/ConditionTimeStateful.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoStatefulConditionsStandard} from "../../GelatoStatefulConditionsStandard.sol";
import {SafeMath} from "../../../external/SafeMath.sol";
import {IGelatoCore} from "../../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../../external/IERC20.sol";

contract ConditionTimeStateful is GelatoStatefulConditionsStandard {

    using SafeMath for uint256;

    // userProxy => taskReceiptId => refTime
    mapping(address => mapping(uint256 => uint256)) public refTime;

    constructor(IGelatoCore _gelatoCore)
        GelatoStatefulConditionsStandard(_gelatoCore)
        public
    {}

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(address _userProxy)
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(this.checkRefTime.selector, uint256(0), _userProxy);
    }

    // STANDARD interface
    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        address userProxy = abi.decode(_conditionData[36:], (address));
        return checkRefTime(_taskReceiptId, userProxy);
    }

    // Specific Implementation
    /// @dev Abi encode these parameter inputs. Use a placeholder for _taskReceiptId.
    /// @param _taskReceiptId Will be stripped from encoded data and replaced by
    ///  the value passed in from GelatoCore.
    function checkRefTime(uint256 _taskReceiptId, address _userProxy)
        public
        view
        virtual
        returns(string memory)
    {
        uint256 _refTime = refTime[_userProxy][_taskReceiptId];
        if (_refTime <= block.timestamp) return OK;
        return "NotOkTimestampDidNotPass";
    }

    /// @dev This function should be called via the userProxy of a Gelato Task as part
    ///  of the Task.actions, if the Condition state should be updated after the task.
    /// This is for Task Cycles/Chains and we fetch the TaskReceipt.id of the
    //  next Task that will be auto-submitted by GelatoCore in the same exec Task transaction.
    /// @param _timeDelta The time after which this condition should return for a given taskId
    /// @param _idDelta Default to 0. If you submit multiple tasks in one action, this can help
    // customize which taskId the state should be allocated to
    function setRefTime(uint256 _timeDelta, uint256 _idDelta) external {
        uint256 currentTime = block.timestamp;
        uint256 newRefTime = currentTime + _timeDelta;
        refTime[msg.sender][_getIdOfNextTaskInCycle() + _idDelta] = newRefTime;
    }
}
"
    },
    "contracts/gelato_conditions/balances/ConditionBalanceStateful.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoStatefulConditionsStandard} from "../GelatoStatefulConditionsStandard.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IGelatoCore} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../external/IERC20.sol";


contract ConditionBalanceStateful is GelatoStatefulConditionsStandard {

    using SafeMath for uint256;

    // userProxy => taskReceiptId => refBalance
    mapping(address => mapping(uint256 => uint256)) public refBalance;

    constructor(IGelatoCore _gelatoCore)
        GelatoStatefulConditionsStandard(_gelatoCore)
        public
    {}

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(
        address _userProxy,
        address _account,
        address _token,
        bool _greaterElseSmaller
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.checkRefBalance.selector,
            uint256(0),  //  taskReceiptId placeholder
            _userProxy,
            _account,
            _token,
            _greaterElseSmaller
        );
    }

    /// @param _conditionData The encoded data from getConditionData()
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address _userProxy,
         address _account,
         address _token,
         bool _greaterElseSmaller) = abi.decode(
             _conditionData[36:],  // slice out selector and _taskReceiptId
             (address,address,address,bool)
        );
        return checkRefBalance(
            _taskReceiptId, _userProxy, _account, _token, _greaterElseSmaller
        );
    }

    // Specific Implementation
    /// @dev Abi encode these parameter inputs. Use a placeholder for _taskReceiptId.
    /// @param _taskReceiptId Will be stripped from encoded data and replaced by
    ///  the value passed in from GelatoCore.
    function checkRefBalance(
        uint256 _taskReceiptId,
        address _userProxy,
        address _account,
        address _token,
        bool _greaterElseSmaller
    )
        public
        view
        virtual
        returns(string memory)
    {
        uint256 _refBalance = refBalance[_userProxy][_taskReceiptId];
        // ETH balances
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (_greaterElseSmaller) {  // greaterThan
                if (_account.balance >= _refBalance) return OK;
                return "NotOkETHBalanceIsNotGreaterThanRefBalance";
            } else {  // smallerThan
                if (_account.balance <= _refBalance) return OK;
                return "NotOkETHBalanceIsNotSmallerThanRefBalance";
            }
        } else {
            // ERC20 balances
            IERC20 erc20 = IERC20(_token);
            try erc20.balanceOf(_account) returns (uint256 erc20Balance) {
                if (_greaterElseSmaller) {  // greaterThan
                    if (erc20Balance >= _refBalance) return OK;
                    return "NotOkERC20BalanceIsNotGreaterThanRefBalance";
                } else {  // smallerThan
                    if (erc20Balance <= _refBalance) return OK;
                    return "NotOkERC20BalanceIsNotSmallerThanRefBalance";
                }
            } catch {
                return "ERC20Error";
            }
        }
    }

    /// @dev This function should be called via the userProxy of a Gelato Task as part
    ///  of the Task.actions, if the Condition state should be updated after the task.
    /// This is for Task Cycles/Chains and we fetch the TaskReceipt.id of the
    //  next Task that will be auto-submitted by GelatoCore in the same exec Task transaction.
    /// @param _balanceDelta The change in balance after which this condition should return for a given taskId
    /// @param _idDelta Default to 0. If you submit multiple tasks in one action, this can help
    // customize which taskId the state should be allocated to
    function setRefBalance(
        address _account,
        address _token,
        int256 _balanceDelta,
        uint256 _idDelta
    )
        external
    {
        uint256 currentBalanceOfAccount;
        uint256 newRefBalance;
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) // ETH
            currentBalanceOfAccount = _account.balance;
        else currentBalanceOfAccount = IERC20(_token).balanceOf(_account);
        require(
            int256(currentBalanceOfAccount) + _balanceDelta >= 0,
            "ConditionBalanceStateful.setRefBalanceDelta: underflow"
        );
        newRefBalance = uint256(int256(currentBalanceOfAccount) + _balanceDelta);
        refBalance[msg.sender][_getIdOfNextTaskInCycle() + _idDelta] = newRefBalance;
    }
}"
    },
    "contracts/gelato_conditions/balances/ConditionBalance.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoConditionsStandard} from "../GelatoConditionsStandard.sol";
import {IERC20} from "../../external/IERC20.sol";

contract ConditionBalance is  GelatoConditionsStandard {

    /// @dev use this function to encode the data off-chain for the condition data field
    function getConditionData(
        address _account,
        address _token,
        uint256 _refBalance,
        bool _greaterElseSmaller
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.balanceCheck.selector,
            _account,
            _token,
            _refBalance,
            _greaterElseSmaller
        );
    }

    /// @param _conditionData The encoded data from getConditionData()
     function ok(uint256, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (address _account,
         address _token,
         uint256 _refBalance,
         bool _greaterElseSmaller) = abi.decode(
            _conditionData[4:],
            (address,address,uint256,bool)
        );
        return balanceCheck(_account, _token, _refBalance, _greaterElseSmaller);
    }

    // Specific Implementation
    function balanceCheck(
        address _account,
        address _token,
        uint256 _refBalance,
        bool _greaterElseSmaller
    )
        public
        view
        virtual
        returns(string memory)
    {
        // ETH balances
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (_greaterElseSmaller) {  // greaterThan
                if (_account.balance >= _refBalance) return OK;
                return "NotOkETHBalanceIsNotGreaterThanRefBalance";
            } else {  // smallerThan
                if (_account.balance <= _refBalance) return OK;
                return "NotOkETHBalanceIsNotSmallerThanRefBalance";
            }
        } else {
            // ERC20 balances
            IERC20 erc20 = IERC20(_token);
            try erc20.balanceOf(_account) returns (uint256 erc20Balance) {
                if (_greaterElseSmaller) {  // greaterThan
                    if (erc20Balance >= _refBalance) return OK;
                    return "NotOkERC20BalanceIsNotGreaterThanRefBalance";
                } else {  // smallerThan
                    if (erc20Balance <= _refBalance) return OK;
                    return "NotOkERC20BalanceIsNotSmallerThanRefBalance";
                }
            } catch {
                return "ERC20Error";
            }
        }
    }
}"
    },
    "contracts/gelato_actions/kyber/ActionKyberTrade.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IERC20} from "../../external/IERC20.sol";
import {IKyberNetworkProxy} from "../../dapp_interfaces/kyber/IKyberNetworkProxy.sol";

contract ActionKyberTrade is GelatoActionsStandardFull {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IKyberNetworkProxy public immutable KYBER;

    constructor(IKyberNetworkProxy _kyberNetworkProxy) public {
        KYBER =_kyberNetworkProxy;
    }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    function getActionData(
        address _origin,
        address _sendToken, // ERC20 or ETH (symbol)
        uint256 _sendAmount,
        address _receiveToken, // ERC20 or ETH (symbol)
        address _receiver
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _origin,
            _sendToken,
            _sendAmount,
            _receiveToken,
            _receiver
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    function action(
        address _origin,
        address _sendToken, // ERC20 or ETH (symbol)
        uint256 _sendAmount,
        address _receiveToken,  // ERC20 or ETH (symbol)
        address _receiver
    )
        public
        virtual
        delegatecallOnly("ActionKyberTrade.action")
        returns (uint256 receiveAmount)
    {
        address receiver = _receiver == address(0) ? address(this) : _receiver;

        if (_sendToken == ETH_ADDRESS) {
            try KYBER.trade{value: _sendAmount}(
                _sendToken,
                _sendAmount,
                _receiveToken,
                receiver,
                type(uint256).max,  // maxDestAmount
                0,  // minConversionRate (if price condition, limit order still possible)
                0xe1F076849B781b1395Fd332dC1758Dbc129be6EC  // fee-sharing: gelato-node
            )
                returns(uint256 receiveAmt)
            {
                receiveAmount = receiveAmt;
            } catch {
                revert("ActionKyberTrade.action: trade with ETH Error");
            }
        } else {
            IERC20 sendERC20 = IERC20(_sendToken);

            // origin funds lightweight UserProxy
            if (_origin != address(0) && _origin != address(this)) {
                sendERC20.safeTransferFrom(
                    _origin, address(this), _sendAmount, "ActionKyberTrade.action:"
                );
            }

            // UserProxy approves KyberNetworkProxy
            sendERC20.safeIncreaseAllowance(
                address(KYBER), _sendAmount, "ActionKyberTrade.action:"
            );

            try KYBER.trade(
                _sendToken,
                _sendAmount,
                _receiveToken,
                receiver,
                type(uint256).max,  // maxDestAmount
                0,  // minConversionRate (if price condition, limit order still possible)
                0xe1F076849B781b1395Fd332dC1758Dbc129be6EC  // fee-sharing: gelato-node
            )
                returns(uint256 receiveAmt)
            {
                receiveAmount = receiveAmt;
            } catch {
                revert("ActionKyberTrade.action: trade with ERC20 Error");
            }
        }

        emit LogTwoWay(
            _origin,  // origin
            _sendToken,
            _sendAmount,
            address(KYBER),  // destination
            _receiveToken,
            receiveAmount,
            receiver
        );
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        address origin = abi.decode(_actionData[4:36], (address));
        (address receiveToken, address receiver) = abi.decode(
            _actionData[100:],
            (address,address)
        );
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        action(origin, sendToken, sendAmount, receiveToken, receiver);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address origin,  // 4:36
         address sendToken,  // 36:68
         uint256 sendAmount,  // 68:100
         address receiveToken,  // 100:132
         address receiver /* 132:164 */) = abi.decode(
             _actionData[4:],  // 0:4 == selector
             (address,address,uint256,address,address)
        );
        uint256 receiveAmount = action(origin, sendToken, sendAmount, receiveToken, receiver);
        return abi.encode(receiveToken, receiveAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        address origin = abi.decode(_actionData[4:36], (address));
        (address receiveToken, address receiver) = abi.decode(
            _actionData[100:],
            (address,address)
        );
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        uint256 receiveAmount = action(origin, sendToken, sendAmount, receiveToken, receiver);
        return abi.encode(receiveToken, receiveAmount);
    }

    // ====== ACTION TERMS CHECK ==========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionKyberTrade: invalid action selector";

        if (_dataFlow == DataFlow.In || _dataFlow == DataFlow.InAndOut)
            return "ActionKyberTrade: termsOk check invalidated by inbound DataFlow";

        (address origin,  // 4:36
         address sendToken,  // 36:68
         uint256 sendAmount,  // 68:100
         /*address receiveToken*/,  // 100:132
         address receiver) = abi.decode(
             _actionData[4:],  // 0:4 == selector
             (address,address,uint256,address,address)
        );

        // Safety for the next Action that consumes data from this Action
        if (_dataFlow == DataFlow.Out && _userProxy != receiver && address(0) != receiver)
            return "ActionKyberTrade: UserProxy must be receiver if DataFlow.Out";

        if (sendToken == ETH_ADDRESS) {
            if (origin != _userProxy && origin != address(0))
                return "ActionKyberTrade: MustHaveUserProxyOrZeroAsOriginForETHTrade";

            if (_userProxy.balance < sendAmount)
                return "ActionKyberTrade: NotOkUserProxyETHBalance";
        } else {
            IERC20 sendERC20 = IERC20(sendToken);

            // UserProxy is prefunded
            if (origin == _userProxy || origin == address(0)) {
                try sendERC20.balanceOf(_userProxy) returns(uint256 proxySendTokenBalance) {
                    if (proxySendTokenBalance < sendAmount)
                        return "ActionKyberTrade: NotOkUserProxySendTokenBalance";
                } catch {
                    return "ActionKyberTrade: ErrorBalanceOf-1";
                }
            } else {
                // UserProxy is not prefunded
                try sendERC20.balanceOf(origin) returns(uint256 originSendTokenBalance) {
                    if (originSendTokenBalance < sendAmount)
                        return "ActionKyberTrade: NotOkOriginSendTokenBalance";
                } catch {
                    return "ActionKyberTrade: ErrorBalanceOf-2";
                }

                try sendERC20.allowance(origin, _userProxy)
                    returns(uint256 userProxySendTokenAllowance)
                {
                    if (userProxySendTokenAllowance < sendAmount)
                        return "ActionKyberTrade: NotOkUserProxySendTokenAllowance";
                } catch {
                    return "ActionKyberTrade: ErrorAllowance";
                }
            }
        }

        // Make sure Trading Pair is valid
        // @DEV we don't do this as this check is very expensive
        // However, by chaining another action that inspects this data before this
        // one, the same check can likely be made in a cheaper way. E.g.
        // a Provider Action that inspects whether sendToken/receiveToken is
        // on a custom whitelist.
        // try KYBER.getExpectedRate(sendToken, receiveToken, sendAmount)
        //     returns (uint256 expectedRate, uint256)
        // {
        //     if (expectedRate == 0) return "ActionKyberTrade:noReserve";
        // } catch {
        //     return "ActionKyberTrade:getExpectedRate-Error";
        // }

        // STANDARD return string to signal actionConditions Ok
        return OK;
    }
}
"
    },
    "contracts/gelato_actions/uniswap/ActionUniswapTrade.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IERC20} from "../../external/IERC20.sol";
import {IUniswapExchange} from "../../dapp_interfaces/uniswap/IUniswapExchange.sol";
import {IUniswapFactory} from "../../dapp_interfaces/uniswap/IUniswapFactory.sol";

contract ActionUniswapTrade is GelatoActionsStandardFull {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapFactory public immutable UNI_FACTORY;

    constructor(IUniswapFactory _uniswapFactory) public {
        UNI_FACTORY =_uniswapFactory;
    }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    function getActionData(
        address _origin,
        address _sendToken, // exchange
        uint256 _sendAmount, // tokens_sold
        address _receiveToken, // token_addr
        address _receiver
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _origin,
            _sendToken,
            _sendAmount,
            _receiveToken,
            _receiver
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @dev Always use this function for encoding _actionData off-chain
    ///  Will be called by GelatoActionPipeline if Action.dataFlow.None
    function action(
        address _origin,
        address _sendToken, // exchange
        uint256 _sendAmount, // tokens_sold
        address _receiveToken, // token_addr
        address _receiver
    )
        public
        virtual
        delegatecallOnly("ActionUniswapTrade.action")
        returns (uint256 receiveAmount)
    {
        address receiver = _receiver == address(0) ? address(this) : _receiver;
        IUniswapExchange sendTokenExchange;

        if (_sendToken == ETH_ADDRESS) {
            IUniswapExchange receiveTokenExchange = UNI_FACTORY.getExchange(
                IERC20(_receiveToken)
            );
            if (receiveTokenExchange != IUniswapExchange(0)) {
                // Swap ETH => ERC20
                try receiveTokenExchange.ethToTokenTransferInput{value: _sendAmount}(
                    1,
                    block.timestamp,
                    receiver
                )
                    returns (uint256 receivedTokens)
                {
                    receiveAmount = receivedTokens;
                } catch {
                    revert("ActionUniswapTrade.action: ethToTokenTransferInput");
                }
            } else {
                revert("ActionUniswapTrade.action: Invalid ReceiveTokenExchange-1");
            }
        } else {
            IERC20 sendERC20 = IERC20(_sendToken);
            sendTokenExchange = UNI_FACTORY.getExchange(IERC20(sendERC20));

            if (sendTokenExchange != IUniswapExchange(0)) {

                // origin funds lightweight UserProxy
                if (_origin != address(0) && _origin != address(this)) {
                    sendERC20.safeTransferFrom(
                        _origin, address(this), _sendAmount, "ActionUniswapTrade.action:"
                    );
                }

                // UserProxy approves Uniswap
                sendERC20.safeIncreaseAllowance(
                    address(sendTokenExchange), _sendAmount, "ActionUniswapTrade.action:"
                );

                if (_receiveToken == ETH_ADDRESS) {
                    // swap ERC20 => ETH
                    try sendTokenExchange.tokenToEthTransferInput(
                        _sendAmount,
                        1,
                        block.timestamp,
                        receiver
                    )
                        returns (uint256 receivedETH)
                    {
                        receiveAmount = receivedETH;
                    } catch {
                        revert("ActionUniswapTrade.action: tokenToEthTransferInput");
                    }
                } else {
                    IUniswapExchange receiveTokenExchange = UNI_FACTORY.getExchange(
                        IERC20(_receiveToken)
                    );
                    if (receiveTokenExchange != IUniswapExchange(0)) {
                        try sendTokenExchange.tokenToTokenTransferInput(
                            _sendAmount,
                            1,
                            1,
                            block.timestamp,
                            receiver,
                            address(_receiveToken)
                        )
                            returns (uint256 receivedTokens)
                        {
                            receiveAmount = receivedTokens;
                        } catch {
                            revert("ActionUniswapTrade.action: tokenToTokenTransferInput");
                        }
                    } else {
                        revert("ActionUniswapTrade.action: Invalid ReceiveTokenExchange-2");
                    }
                }
            } else {
                revert("ActionUniswapTrade: Invalid SendTokenExchange");
            }
        }

        emit LogTwoWay(
            _origin,  // origin
            _sendToken,
            _sendAmount,
            address(sendTokenExchange),  // destination
            _receiveToken,
            receiveAmount,
            receiver
        );
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        address origin = abi.decode(_actionData[4:36], (address));
        (address receiveToken, address receiver) = abi.decode(
            _actionData[100:],
            (address,address)
        );
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        action(origin, sendToken, sendAmount, receiveToken, receiver);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address origin,  // 4:36
         address sendToken,  // 36:68
         uint256 sendAmount,  // 68:100
         address receiveToken,  // 100:132
         address receiver /* 132:164 */) = abi.decode(
             _actionData[4:],  // 0:4 == selector
             (address,address,uint256,address,address)
        );
        uint256 receiveAmount = action(origin, sendToken, sendAmount, receiveToken, receiver);
        return abi.encode(receiveToken, receiveAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        address origin = abi.decode(_actionData[4:36], (address));
        (address receiveToken, address receiver) = abi.decode(
            _actionData[100:],
            (address,address)
        );
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        uint256 receiveAmount = action(origin, sendToken, sendAmount, receiveToken, receiver);
        return abi.encode(receiveToken, receiveAmount);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionUniswapTrade: invalid action selector";

        if (_dataFlow == DataFlow.In || _dataFlow == DataFlow.InAndOut)
            return "ActionUniswapTrade: termsOk check invalidated by inbound DataFlow";

        (address origin,  // 4:36
         address sendToken,  // 36:68
         uint256 sendAmount,  // 68:100
         address receiveToken,  // 100:132
         /*address receiver*/) = abi.decode(
             _actionData[4:],  // 0:4 == selector
             (address,address,uint256,address,address)
        );

        // Safety for the next Action that consumes data from this Action
        if (
            _dataFlow == DataFlow.Out &&
            _userProxy != abi.decode(_actionData[132:164], (address)) &&  // receiver
            address(0) != abi.decode(_actionData[132:164], (address))  // receiver
        )
            return "ActionUniswapTrade: UserProxy must be receiver if DataFlow.Out";

        if (sendToken == ETH_ADDRESS) {
            IERC20 receiveERC20 = IERC20(receiveToken);
            IUniswapExchange receiveTokenExchange = UNI_FACTORY.getExchange(receiveERC20);
            if (receiveTokenExchange == IUniswapExchange(0))
                return "ActionUniswapTrade: receiveTokenExchangeDoesNotExist-1";

            if (origin != _userProxy && origin != address(0))
                return "ActionUniswapTrade: MustHaveUserProxyOrZeroAsOriginForETHTrade";
            if (_userProxy.balance < sendAmount)
                return "ActionUniswapTrade: NotOkUserProxyETHBalance";
        } else {
            IERC20 sendERC20 = IERC20(sendToken);

            // Make sure sendToken-receiveToken Pair is valid
            IUniswapExchange sendTokenExchange = UNI_FACTORY.getExchange(sendERC20);
            if (sendTokenExchange == IUniswapExchange(0))
                return "ActionUniswapTrade: sendTokenExchangeDoesNotExist";
            if (receiveToken != ETH_ADDRESS) {
                IERC20 receiveERC20 = IERC20(receiveToken);
                IUniswapExchange receiveTokenExchange = UNI_FACTORY.getExchange(receiveERC20);
                if (receiveTokenExchange == IUniswapExchange(0))
                    return "ActionUniswapTrade: receiveTokenExchangeDoesNotExist-2";
            }

            // UserProxy is prefunded
            if (origin == _userProxy || origin == address(0)) {
                try sendERC20.balanceOf(_userProxy) returns(uint256 proxySendTokenBalance) {
                    if (proxySendTokenBalance < sendAmount)
                        return "ActionUniswapTrade: NotOkUserProxySendTokenBalance";
                } catch {
                    return "ActionUniswapTrade: ErrorBalanceOf-1";
                }
            } else {
                // UserProxy is not prefunded
                try sendERC20.balanceOf(origin) returns(uint256 originSendTokenBalance) {
                    if (originSendTokenBalance < sendAmount)
                        return "ActionUniswapTrade: NotOkOriginSendTokenBalance";
                } catch {
                    return "ActionUniswapTrade: ErrorBalanceOf-2";
                }

                try sendERC20.allowance(origin, _userProxy)
                    returns(uint256 userProxySendTokenAllowance)
                {
                    if (userProxySendTokenAllowance < sendAmount)
                        return "ActionUniswapTrade: NotOkUserProxySendTokenAllowance";
                } catch {
                    return "ActionUniswapTrade: ErrorAllowance";
                }
            }
        }

        // STANDARD return string to signal actionConditions Ok
        return OK;
    }
}
"
    },
    "contracts/dapp_interfaces/uniswap/IUniswapExchange.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "../../external/IERC20.sol";

interface IUniswapExchange {
    function getEthToTokenInputPrice(uint256 ethSold)
        external
        view
        returns (uint256 tokensBought);

    function getTokenToEthOutputPrice(uint256 ethbought)
        external
        view
        returns (uint256 tokensToBeSold);

    function getTokenToEthInputPrice(uint256 tokensSold)
        external
        view
        returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 MintTokens, uint256 deadline)
        external
        payable
        returns (uint256 tokensBought);

    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 tokensSold);

    function ethToTokenTransferInput(
        uint256 MintTokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokensBought);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);

    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 MintTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddr
    ) external returns (uint256 tokensBought);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256);

}
"
    },
    "contracts/dapp_interfaces/uniswap/IUniswapFactory.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getExchange(IERC20 token)
        external
        view
        returns (IUniswapExchange exchange);
}
"
    },
    "contracts/gelato_actions/transfer/ActionERC20TransferFrom.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../external/IERC20.sol";
import {Address} from "../../external/Address.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";

contract ActionERC20TransferFrom is GelatoActionsStandardFull {
    // using SafeERC20 for IERC20; <- internal library methods vs. try/catch
    using Address for address;
    using SafeERC20 for IERC20;

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    /// Use "address _sendToken" for Human Readable ABI.
    function getActionData(
        address _user,
        IERC20 _sendToken,
        uint256 _sendAmount,
        address _destination
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _user,
            _sendToken,
            _sendAmount,
            _destination
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @dev Always use this function for encoding _actionData off-chain
    ///  Will be called by GelatoActionPipeline if Action.dataFlow.None
    /// Use "address _sendToken" for Human Readable ABI.
    function action(
        address _user,
        IERC20 _sendToken,
        uint256 _sendAmount,
        address _destination
    )
        public
        virtual
        delegatecallOnly("ActionERC20TransferFrom.action")
    {
        _sendToken.safeTransferFrom(
            _user, _destination, _sendAmount, "ActionERC20TransferFrom.action:"
        );
        emit LogOneWay(_user, address(_sendToken), _sendAmount, _destination);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        address user = abi.decode(_actionData[4:36], (address));
        address destination = abi.decode(_actionData[100:132], (address));
        (IERC20 sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (IERC20,uint256));
        action(user, sendToken, sendAmount, destination);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address user,
         IERC20 sendToken,
         uint256 sendAmount,
         address destination) = abi.decode(
            _actionData[4:],
            (address,IERC20,uint256,address)
        );
        action(user, sendToken, sendAmount, destination);
        return abi.encode(sendToken, sendAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        address user = abi.decode(_actionData[4:36], (address));
        address destination = abi.decode(_actionData[100:132], (address));
        (IERC20 sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (IERC20,uint256));
        action(user, sendToken, sendAmount, destination);
        return abi.encode(sendToken, sendAmount);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionERC20TransferFrom: invalid action selector";

        if (_dataFlow == DataFlow.In || _dataFlow == DataFlow.InAndOut)
            return "ActionERC20TransferFrom: termsOk check invalidated by inbound DataFlow";

        (address user, IERC20 sendToken, uint256 sendAmount, ) = abi.decode(
            _actionData[4:],
            (address,IERC20,uint256,address)
        );

        try sendToken.balanceOf(user) returns(uint256 sendERC20Balance) {
            if (sendERC20Balance < sendAmount)
                return "ActionERC20TransferFrom: NotOkUserSendTokenBalance";
        } catch {
            return "ActionERC20TransferFrom: ErrorBalanceOf";
        }

        try sendToken.allowance(user, _userProxy) returns(uint256 allowance) {
            if (allowance < sendAmount)
                return "ActionERC20TransferFrom: NotOkUserProxySendTokenAllowance";
        } catch {
            return "ActionERC20TransferFrom: ErrorAllowance";
        }

        return OK;
    }
}
"
    },
    "contracts/gelato_actions/provider/ActionFeeHandler.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../external/IERC20.sol";
import {Address} from "../../external/Address.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {Ownable} from "../../external/Ownable.sol";

contract ActionFeeHandler is GelatoActionsStandardFull {
    // using SafeERC20 for IERC20; <- internal library methods vs. try/catch
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address payable public immutable provider;
    FeeHandlerFactory public immutable feeHandlerFactory;
    uint256 public immutable feeNum;
    uint256 public immutable feeDen;

    constructor(
        address payable _provider,
        FeeHandlerFactory _feeHandlerFactory,
        uint256 _num,
        uint256 _den
    )
        public
    {
        require(_num <= _den, "ActionFeeHandler.constructor: _num greater than _den");
        provider = _provider;
        feeHandlerFactory = _feeHandlerFactory;
        feeNum = _num;
        feeDen = _den;
    }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    function getActionData(address _sendToken, uint256 _sendAmount, address _feePayer)
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(this.action.selector, _sendToken, _sendAmount, _feePayer);
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    function isTokenWhitelisted(address _token) public view returns(bool) {
        return feeHandlerFactory.isWhitelistedToken(provider, _token);
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @dev Use this function for encoding off-chain. DelegatecallOnly!
    function action(address _sendToken, uint256 _sendAmount, address _feePayer)
        public
        virtual
        delegatecallOnly("ActionFeeHandler.action")
        returns (uint256 sendAmountAfterFee)
    {
        uint256 fee = _sendAmount.mul(feeNum).sub(1) / feeDen + 1;
        if (address(this) == _feePayer) {
            if (_sendToken == ETH_ADDRESS) provider.sendValue(fee);
            else IERC20(_sendToken).safeTransfer(provider, fee, "ActionFeeHandler.action:");
        } else {
        IERC20(_sendToken).safeTransferFrom(
            _feePayer, provider, fee, "ActionFeeHandler.action:"
        );
        }
        sendAmountAfterFee = _sendAmount.sub(fee);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        address feePayer = abi.decode(_actionData[68:], (address));
        action(sendToken, sendAmount, feePayer);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sendToken, uint256 sendAmount, address feePayer) = abi.decode(
            _actionData[4:],
            (address,uint256,address)
        );
        uint256 sendAmountAfterFee = action(sendToken, sendAmount, feePayer);
        return abi.encode(sendToken, sendAmountAfterFee);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sendToken, uint256 sendAmount) = abi.decode(_inFlowData, (address,uint256));
        address feePayer = abi.decode(_actionData[68:], (address));
        uint256 sendAmountAfterFee = action(sendToken, sendAmount, feePayer);
        return abi.encode(sendToken, sendAmountAfterFee);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionFeeHandler: invalid action selector";

        if (_dataFlow == DataFlow.In || _dataFlow == DataFlow.InAndOut)
            return "ActionFeeHandler: termsOk check invalidated by inbound DataFlow";

        (address sendToken, uint256 sendAmount, address feePayer) = abi.decode(
            _actionData[4:],
            (address,uint256,address)
        );

        if (sendAmount == 0)
            return "ActionFeeHandler: Insufficient sendAmount";

        if (!isTokenWhitelisted(sendToken))
            return "ActionFeeHandler: Token not whitelisted for fee";

        IERC20 sendERC20 = IERC20(sendToken);

        if (_userProxy == feePayer) {
            if (sendToken == ETH_ADDRESS) {
                if (_userProxy.balance < sendAmount)
                    return "ActionFeeHandler: NotOkUserProxyETHBalance";
            } else {
                try sendERC20.balanceOf(_userProxy) returns (uint256 balance) {

                    if (balance < sendAmount)
                        return "ActionFeeHandler: NotOkUserProxySendTokenBalance";
                } catch {
                    return "ActionFeeHandler: ErrorBalanceOf";
                }
            }
        } else {
            if (sendToken == ETH_ADDRESS)
                return "ActionFeeHandler: CannotTransferFromETH";
            try sendERC20.balanceOf(feePayer) returns (uint256 balance) {
                    if (balance < sendAmount)
                        return "ActionFeeHandler: NotOkFeePayerSendTokenBalance";
                } catch {
                    return "ActionFeeHandler: ErrorBalanceOf";
                }
            try sendERC20.allowance(feePayer, _userProxy) returns (uint256 allowance) {
                if (allowance < sendAmount)
                    return "ActionFeeHandler: NotOkFeePayerSendTokenAllowance";
            } catch {
                return "ActionFeeHandler: ErrorAllowance";
            }
        }

        return OK;
    }
}

contract FeeHandlerFactory {

    event Created(
        address indexed provider,
        ActionFeeHandler indexed feeHandler,
        uint256 indexed num
    );

    // Denominator => For a fee of 1% => Input num = 100, as 100 / 10.000 = 0.01 == 1%
    uint256 public constant DEN = 10000;

    // provider => num => ActionFeeHandler
    mapping(address => mapping(uint256 => ActionFeeHandler)) public feeHandlerByProviderAndNum;
    mapping(address => ActionFeeHandler[]) public feeHandlersByProvider;
    mapping(address => mapping(address => bool)) public isWhitelistedToken;

    /// @notice Deploys a new feeHandler instance
    /// @dev Input _num = 100 for 1% fee, _num = 50 for 0.5% fee, etc
    function create(uint256 _num) public returns (ActionFeeHandler feeHandler) {
        require(
            feeHandlerByProviderAndNum[msg.sender][_num] == ActionFeeHandler(0),
            "FeeHandlerFactory.create: already deployed"
        );
        require(_num <= DEN, "FeeHandlerFactory.create: num greater than DEN");
        feeHandler = new ActionFeeHandler(msg.sender, this, _num, DEN);
        feeHandlerByProviderAndNum[msg.sender][_num] = feeHandler;
        feeHandlersByProvider[msg.sender].push(feeHandler);
        emit Created(msg.sender, feeHandler, _num);
    }

    // Provider Token whitelist
    function addTokensToWhitelist(address[] calldata _tokens) external {
        for (uint i; i < _tokens.length; i++) {
            isWhitelistedToken[msg.sender][_tokens[i]] = true;
        }
    }

    function removeTokensFromWhitelist(address[] calldata _tokens) external {
        for (uint i; i < _tokens.length; i++) {
            isWhitelistedToken[msg.sender][_tokens[i]] = false;
        }
    }
}
"
    },
    "contracts/gelato_core/GelatoGasPriceOracle.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import "./interfaces/IGelatoGasPriceOracle.sol";
import "../external/Ownable.sol";

contract GelatoGasPriceOracle is IGelatoGasPriceOracle, Ownable {

    address public override oracle;

    // This gasPrice is pulled into GelatoCore.exec() via GelatoSysAdmin._getGelatoGasPrice()
    uint256 private gasPrice;

    constructor(uint256 _gasPrice) public {
        setOracle(msg.sender);
        setGasPrice(_gasPrice);
    }

    modifier onlyOracle {
        require(msg.sender == oracle, "GelatoGasPriceOracle.onlyOracle");
        _;
    }

    function setOracle(address _newOracle) public override onlyOwner {
        emit LogOracleSet(oracle, _newOracle);
        oracle = _newOracle;
    }

    function setGasPrice(uint256 _newGasPrice) public override onlyOracle {
        emit LogGasPriceSet(gasPrice, _newGasPrice);
        gasPrice = _newGasPrice;
    }

    function latestAnswer() view external override returns(int256) {
        return int256(gasPrice);
    }
}
"
    },
    "contracts/gelato_core/interfaces/IGelatoGasPriceOracle.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

interface IGelatoGasPriceOracle {
    // Owner
    event LogOracleSet(address indexed oldOracle, address indexed newOracle);

    // Oracle
    event LogGasPriceSet(uint256 indexed oldGasPrice, uint256 indexed newGasPrice);

    // Owner

    /// @notice Set new address that can set the gas price
    /// @dev Only callable by owner
    /// @param _newOracle Address of new oracle admin
    function setOracle(address _newOracle) external;

    // Oracle

    /// @notice Set new gelato gas price
    /// @dev Only callable by oracle admin
    /// @param _newGasPrice New gas price in wei
    function setGasPrice(uint256 _newGasPrice) external;

    /// @notice Get address of oracle admin that can set gas prices
    /// @return Oracle Admin address
    function oracle() external view returns(address);

    /// @notice Get current gas price
    /// @return Gas price in wei
    function latestAnswer() external view returns(int256);
}
"
    },
    "contracts/gelato_actions/gnosis/ActionPlaceOrderBatchExchange.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoActionsStandardFull} from "../GelatoActionsStandardFull.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../external/IERC20.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IBatchExchange} from "../../dapp_interfaces/gnosis/IBatchExchange.sol";
import {Task} from "../../gelato_core/interfaces/IGelatoCore.sol";

/// @title ActionPlaceOrderBatchExchange
/// @author Luis Schliesske & Hilmar Orth
/// @notice Gelato Action that
///  1) withdraws funds form user's  EOA,
///  2) deposits on Batch Exchange,
///  3) Places order on batch exchange and
//   4) requests future withdraw on batch exchange
contract ActionPlaceOrderBatchExchange is GelatoActionsStandardFull {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_UINT = type(uint256).max;
    uint32 public constant BATCH_TIME = 300;

    IBatchExchange public immutable batchExchange;

    constructor(IBatchExchange _batchExchange) public { batchExchange = _batchExchange; }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    /// Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    function getActionData(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buyAmount,
        uint32 _batchDuration
    )
        public
        pure
        virtual
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _origin,
            _sellToken,
            _sellAmount,
            _buyToken,
            _buyAmount,
            _batchDuration
        );
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_IN_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @notice Place order on Batch Exchange and request future withdraw for buy/sell token
    /// @dev Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    /// @param _sellToken ERC20 Token to sell on Batch Exchange
    /// @param _sellAmount Amount to sell
    /// @param _buyToken ERC20 Token to buy on Batch Exchange
    /// @param _buyAmount Amount to receive (at least)
    /// @param _batchDuration After how many batches funds should be
    function action(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buyAmount,
        uint32 _batchDuration
    )
        public
        virtual
        delegatecallOnly("ActionPlaceOrderBatchExchange.action")
    {
        IERC20 sellToken = IERC20(_sellToken);

        // 1. Get current batch id
        uint32 withdrawBatchId = uint32(block.timestamp / BATCH_TIME) + _batchDuration;

        // 2. Optional: If light proxy, transfer from funds to proxy
        if (_origin != address(0) && _origin != address(this)) {
            sellToken.safeTransferFrom(
                _origin,
                address(this),
                _sellAmount,
                "ActionPlaceOrderBatchExchange.action:"
            );
        }

        // 3. Fetch token Ids for sell & buy token on Batch Exchange
        uint16 sellTokenId = batchExchange.tokenAddressToIdMap(_sellToken);
        uint16 buyTokenId = batchExchange.tokenAddressToIdMap(_buyToken);

        // 4. Approve _sellToken to BatchExchange Contract
        sellToken.safeIncreaseAllowance(
            address(batchExchange),
            _sellAmount,
            "ActionPlaceOrderBatchExchange.action:"
        );

        // 5. Deposit _sellAmount on BatchExchange
        try batchExchange.deposit(address(_sellToken), _sellAmount) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.deposit _sellToken failed");
        }

        // 6. Place Order on Batch Exchange
        // uint16 buyToken, uint16 sellToken, uint32 validUntil, uint128 buyAmount, uint128 _sellAmount
        try batchExchange.placeOrder(
            buyTokenId,
            sellTokenId,
            withdrawBatchId,
            _buyAmount,
            _sellAmount
        ) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.placeOrderfailed");
        }

        // 7. First check if we have a valid future withdraw request for the selltoken
        uint256 sellTokenWithdrawAmount = uint256(_sellAmount);
        try batchExchange.getPendingWithdraw(address(this), _sellToken)
            returns(uint256 reqWithdrawAmount, uint32 requestedBatchId)
        {
            // Check if the withdraw request is not in the past
            if (requestedBatchId >= uint32(block.timestamp / BATCH_TIME)) {
                // If we requested a max_uint withdraw, the withdraw amount will not change
                if (reqWithdrawAmount == MAX_UINT)
                    sellTokenWithdrawAmount = reqWithdrawAmount;
                // If not, we add the previous amount to the new one
                else
                    sellTokenWithdrawAmount = sellTokenWithdrawAmount.add(reqWithdrawAmount);
            }
        } catch {
            revert("ActionPlaceOrderBatchExchange.getPendingWithdraw _sellToken failed");
        }

        // 8. Request future withdraw on Batch Exchange for sellToken
        try batchExchange.requestFutureWithdraw(_sellToken, sellTokenWithdrawAmount, withdrawBatchId) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.requestFutureWithdraw _sellToken failed");
        }

        // 9. Request future withdraw on Batch Exchange for buyToken
        // @DEV using MAX_UINT as we don't know in advance how much buyToken we will get
        try batchExchange.requestFutureWithdraw(_buyToken, MAX_UINT, withdrawBatchId) {
        } catch {
            revert("ActionPlaceOrderBatchExchange.requestFutureWithdraw _buyToken failed");
        }

    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address origin,
         address sellToken,
         uint128 sellAmount,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);
        return abi.encode(sellToken, sellAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buyAmount,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buyAmount, batchDuration);

        return abi.encode(sellToken, sellAmount);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address _userProxy,
        bytes calldata _actionData,
        DataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)  // actionCondition
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionPlaceOrderBatchExchange: invalid action selector";

        (address origin, address _sellToken, uint128 sellAmount, address buyToken) = abi.decode(
            _actionData[4:132],
            (address,address,uint128,address)
        );

        IERC20 sellToken = IERC20(_sellToken);

        if (origin == address(0) || origin == _userProxy) {
            try sellToken.balanceOf(_userProxy) returns(uint256 proxySendTokenBalance) {
                if (proxySendTokenBalance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkUserProxySendTokenBalance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorBalanceOf-1";
            }
        } else {
            try sellToken.balanceOf(origin) returns(uint256 originSendTokenBalance) {
                if (originSendTokenBalance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkOriginSendTokenBalance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorBalanceOf-2";
            }

            try sellToken.allowance(origin, _userProxy)
                returns(uint256 userProxySendTokenAllowance)
            {
                if (userProxySendTokenAllowance < sellAmount)
                    return "ActionPlaceOrderBatchExchange: NotOkUserProxySendTokenAllowance";
            } catch {
                return "ActionPlaceOrderBatchExchange: ErrorAllowance";
            }
        }

        uint32 currentBatchId = uint32(block.timestamp / BATCH_TIME);

        try batchExchange.getPendingWithdraw(_userProxy, _sellToken)
            returns(uint256, uint32 requestedBatchId)
        {
            // Check if the withdraw request is valid => we need the withdraw to exec first
            if (requestedBatchId != 0 && requestedBatchId < currentBatchId) {
                return "ActionPlaceOrderBatchExchange WaitUntilPreviousBatchWasWithdrawn sellToken";
            }
        } catch {
            return "ActionPlaceOrderBatchExchange getPendingWithdraw failed sellToken";
        }

        try batchExchange.getPendingWithdraw(_userProxy, buyToken)
            returns(uint256, uint32 requestedBatchId)
        {
            // Check if the withdraw request is valid => we need the withdraw to exec first
            if (requestedBatchId != 0 && requestedBatchId < currentBatchId) {
                return "ActionPlaceOrderBatchExchange WaitUntilPreviousBatchWasWithdrawn buyToken";
            }
        } catch {
            return "ActionPlaceOrderBatchExchange getPendingWithdraw failed buyToken";
        }

        // STANDARD return string to signal actionConditions Ok
        return OK;
    }

    // ======= ACTION HELPERS =========
    function _handleInFlowData(bytes calldata _inFlowData)
        internal
        pure
        virtual
        returns(address sellToken, uint128 sellAmount)
    {
        uint256 sellAmount256;
        (sellToken, sellAmount256) = abi.decode(_inFlowData, (address,uint256));
        sellAmount = uint128(sellAmount256);
        require(
            sellAmount == sellAmount256,
            "ActionPlaceOrderBatchExchange._handleInFlowData: sellAmount conversion error"
        );
    }

    function _extractReusableActionData(bytes calldata _actionData)
        internal
        pure
        virtual
        returns (address origin, address buyToken, uint128 buyAmount, uint32 batchDuration)
    {
        (origin,/*sellToken*/,/*sellAmount*/, buyToken, buyAmount, batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
    }
}"
    },
    "contracts/gelato_actions/gnosis/ActionPlaceOrderBatchExchangeWithSlippage.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {ActionPlaceOrderBatchExchange} from "./ActionPlaceOrderBatchExchange.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";
import {IBatchExchange} from "../../dapp_interfaces/gnosis/IBatchExchange.sol";
import {Task} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IKyberNetworkProxy} from "../../dapp_interfaces/kyber/IKyberNetworkProxy.sol";

/// @title ActionPlaceOrderBatchExchangeWithSlippage
/// @author Luis Schliesske & Hilmar Orth
/// @notice Gelato Action that
///  1) Calculates buyAmout based on inputted slippage value,
///  2) withdraws funds form user's  EOA,
///  3) deposits on Batch Exchange,
///  4) Places order on batch exchange and
//   5) requests future withdraw on batch exchange
contract ActionPlaceOrderBatchExchangeWithSlippage is ActionPlaceOrderBatchExchange {

    using SafeMath for uint256;
    using SafeERC20 for address;

    IKyberNetworkProxy public immutable KYBER;

    constructor(
        IBatchExchange _batchExchange,
        IKyberNetworkProxy _kyberNetworkProxy
    )
        ActionPlaceOrderBatchExchange(_batchExchange)
        public
    {
        KYBER = _kyberNetworkProxy;
    }

    /// @dev use this function to encode the data off-chain for the action data field
    /// Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    function getActionData(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buySlippage,
        uint32 _batchDuration
    )
        public
        pure
        virtual
        override
        returns(bytes memory)
    {
        return abi.encodeWithSelector(
            this.action.selector,
            _origin,
            _sellToken,
            _sellAmount,
            _buyToken,
            _buySlippage,
            _batchDuration
        );
    }

    /// @notice Place order on Batch Exchange and request future withdraw for buy/sell token
    /// @dev Use "address _sellToken" and "address _buyToken" for Human Readable ABI.
    /// @param _sellToken Token to sell on Batch Exchange
    /// @param _sellAmount Amount to sell
    /// @param _buyToken Token to buy on Batch Exchange
    /// @param _buySlippage Slippage inlcuded for the buySlippage in order placement
    /// @param _batchDuration After how many batches funds should be
    function action(
        address _origin,
        address _sellToken,
        uint128 _sellAmount,
        address _buyToken,
        uint128 _buySlippage,
        uint32 _batchDuration
    )
        public
        virtual
        override
        delegatecallOnly("ActionPlaceOrderBatchExchangeWithSlippage.action")
    {
        uint128 expectedBuyAmount = getKyberBuyAmountWithSlippage(
            _sellToken,
            _buyToken,
            _sellAmount,
            _buySlippage
        );
        super.action(
            _origin, _sellToken, _sellAmount, _buyToken, expectedBuyAmount, _batchDuration
        );
    }

    function getKyberBuyAmountWithSlippage(
        address _sellToken,
        address _buyToken,
        uint128 _sellAmount,
        uint256 _slippage
    )
        view
        public
        returns(uint128 expectedBuyAmount128)
    {
        uint256 sellTokenDecimals = getDecimals(_sellToken);
        uint256 buyTokenDecimals = getDecimals(_buyToken);

        try KYBER.getExpectedRate(address(_sellToken), address(_buyToken), _sellAmount)
            returns(uint256 expectedRate, uint256)
        {
            // Returned values in kyber are in 18 decimals
            // regardless of the destination token's decimals
            uint256 expectedBuyAmount256 = expectedRate
                // * sellAmount, as kyber returns the price for 1 unit
                .mul(_sellAmount)
                // * buy decimal tokens, to convert expectedRate * sellAmount to buyToken decimals
                .mul(10 ** buyTokenDecimals)
                // / sell token decimals to account for sell token decimals of _sellAmount
                .div(10 ** sellTokenDecimals)
                // / 10**18 to account for kyber always returning with 18 decimals
                .div(1e18);

            // return amount minus slippage. e.g. _slippage = 5 => 5% slippage
            if(_slippage != 0) {
                expectedBuyAmount256
                    = expectedBuyAmount256 - expectedBuyAmount256.mul(_slippage).div(100);
            }
            expectedBuyAmount128 = uint128(expectedBuyAmount256);
            require(
                expectedBuyAmount128 == expectedBuyAmount256,
                "ActionPlaceOrderBatchExchangeWithSlippage.getKyberRate: uint conversion"
            );
        } catch {
            revert("ActionPlaceOrderBatchExchangeWithSlippage.getKyberRate:Error");
        }
    }

    function getDecimals(address _token)
        internal
        view
        returns(uint256)
    {
        (bool success, bytes memory data) = _token.staticcall{gas: 30000}(
            abi.encodeWithSignature("decimals()")
        );

        if (!success) {
            (success, data) = _token.staticcall{gas: 30000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }
        if (success) return abi.decode(data, (uint256));
        else revert("ActionPlaceOrderBatchExchangeWithSlippage.getDecimals:revert");
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.In
    //  => do not use for _actionData encoding
    function execWithDataFlowIn(bytes calldata _actionData, bytes calldata _inFlowData)
        external
        payable
        virtual
        override
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buySlippage,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buySlippage, batchDuration);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address origin,
         address sellToken,
         uint128 sellAmount,
         address buyToken,
         uint128 buySlippage,
         uint32 batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
        action(origin, sellToken, sellAmount, buyToken, buySlippage, batchDuration);
        return abi.encode(sellToken, sellAmount);
    }

    /// @dev Will be called by GelatoActionPipeline if Action.dataFlow.InAndOut
    //  => do not use for _actionData encoding
    function execWithDataFlowInAndOut(
        bytes calldata _actionData,
        bytes calldata _inFlowData
    )
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        (address sellToken, uint128 sellAmount) = _handleInFlowData(_inFlowData);
        (address origin,
         address buyToken,
         uint128 buySlippage,
         uint32 batchDuration) = _extractReusableActionData(_actionData);

        action(origin, sellToken, sellAmount, buyToken, buySlippage, batchDuration);

        return abi.encode(sellToken, sellAmount);
    }

    // ======= ACTION HELPERS =========
    function _handleInFlowData(bytes calldata _inFlowData)
        internal
        pure
        virtual
        override
        returns(address sellToken, uint128 sellAmount)
    {
        uint256 sellAmount256;
        (sellToken, sellAmount256) = abi.decode(_inFlowData, (address,uint256));
        sellAmount = uint128(sellAmount256);
        require(
            sellAmount == sellAmount256,
            "ActionPlaceOrderBatchExchange._handleInFlowData: sellAmount conversion error"
        );
    }

    function _extractReusableActionData(bytes calldata _actionData)
        internal
        pure
        virtual
        override
        returns (address origin, address buyToken, uint128 buySlippage, uint32 batchDuration)
    {
        (origin,/*sellToken*/,/*sellAmount*/, buyToken, buySlippage, batchDuration) = abi.decode(
            _actionData[4:],
            (address,address,uint128,address,uint128,uint32)
        );
    }
}"
    },
    "contracts/gelato_actions/gnosis/ActionWithdrawBatchExchange.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "../GelatoActionsStandard.sol";
import {
    IGelatoOutFlowAction
} from "../action_pipeline_interfaces/IGelatoOutFlowAction.sol";
import {DataFlow} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {IERC20} from "../../external/IERC20.sol";
import {IBatchExchange} from "../../dapp_interfaces/gnosis/IBatchExchange.sol";
import {GelatoBytes} from "../../libraries/GelatoBytes.sol";
import {SafeERC20} from "../../external/SafeERC20.sol";
import {SafeMath} from "../../external/SafeMath.sol";

/// @title ActionWithdrawBatchExchange
/// @author Luis Schliesske & Hilmar Orth
/// @notice Gelato Action that withdraws funds from BatchExchange and returns withdrawamount
/// @dev Can be used in a GelatoActionPipeline as OutFlowAction.
contract ActionWithdrawBatchExchange is GelatoActionsStandard, IGelatoOutFlowAction {

    using SafeMath for uint256;
    using SafeERC20 for address;

    IBatchExchange public immutable batchExchange;

    constructor(IBatchExchange _batchExchange) public { batchExchange = _batchExchange; }

    // ======= DEV HELPERS =========
    /// @dev use this function to encode the data off-chain for the action data field
    /// Human Readable ABI: ["function getActionData(address _token)"]
    function getActionData(IERC20 _token)
        public
        pure
        returns(bytes memory)
    {
        return abi.encodeWithSelector(this.action.selector, _token);
    }

    /// @dev Used by GelatoActionPipeline.isValid()
    function DATA_FLOW_OUT_TYPE() public pure virtual override returns (bytes32) {
        return keccak256("TOKEN,UINT256");
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    /// @notice Withdraw token from Batch Exchange
    /// @dev delegatecallOnly
    /// Human Readable ABI: ["function action(address _token)"]
    /// @param _token Token to withdraw from Batch Exchange
    function action(address _token)
        public
        virtual
        delegatecallOnly("ActionWithdrawBatchExchange.action")
        returns (uint256 withdrawAmount)
    {
        IERC20 token = IERC20(_token);
        uint256 preTokenBalance = token.balanceOf(address(this));

        try batchExchange.withdraw(address(this), _token) {
            uint256 postTokenBalance = token.balanceOf(address(this));
            if (postTokenBalance > preTokenBalance)
                withdrawAmount = postTokenBalance - preTokenBalance;
        } catch {
           revert("ActionWithdrawBatchExchange.withdraw _token failed");
        }
    }

    ///@dev Will be called by GelatoActionPipeline if Action.dataFlow.Out
    //  => do not use for _actionData encoding
    function execWithDataFlowOut(bytes calldata _actionData)
        external
        payable
        virtual
        override
        returns (bytes memory)
    {
        address token = abi.decode(_actionData[4:], (address));
        uint256 withdrawAmount = action(token);
        return abi.encode(token, withdrawAmount);
    }

    // ======= ACTION TERMS CHECK =========
    // Overriding and extending GelatoActionsStandard's function (optional)
    function termsOk(
        uint256,  // taskReceipId
        address, //_userProxy,
        bytes calldata _actionData,
        DataFlow,
        uint256,  // value
        uint256  // cycleId
    )
        public
        view
        virtual
        override
        returns(string memory)
    {
        if (this.action.selector != GelatoBytes.calldataSliceSelector(_actionData))
            return "ActionWithdrawBatchExchange: invalid action selector";
        // address token = abi.decode(_actionData[4:], (address));
        // bool tokenWithdrawable = batchExchange.hasValidWithdrawRequest(_userProxy, token);
        // if (!tokenWithdrawable)
        //     return "ActionWithdrawBatchExchange: Token not withdrawable yet";
        return OK;
    }
}"
    },
    "contracts/mocks/gelato_actions/one-off/MockActionDummyRevert.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "../../../gelato_actions/GelatoActionsStandard.sol";
import {DataFlow} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract MockActionDummyRevert is GelatoActionsStandard {
    function action(bool) public payable virtual {
        revert("MockActionDummyRevert.action: test revert");
    }

    function termsOk(uint256, address, bytes calldata _data, DataFlow, uint256, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        bool isOk = abi.decode(_data, (bool));
        if (isOk) return OK;
        revert("MockActionDummyOutOfGas.termsOk");
    }
}
"
    },
    "contracts/mocks/gelato_actions/one-off/MockActionDummyOutOfGas.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "../../../gelato_actions/GelatoActionsStandard.sol";
import {DataFlow} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract MockActionDummyOutOfGas is GelatoActionsStandard {

    uint256 public overflowVar;

    function action(bool) public payable virtual {
        assert(false);
    }

    function placeholder() public pure {
        assert(false);
    }

    function termsOk(uint256, address, bytes calldata _data, DataFlow, uint256, uint256)
        public
        view
        virtual
        override
        returns(string memory)
    {
        (bool isOk) = abi.decode(_data, (bool));
        bool _;
        bytes memory __;
        (_, __) = address(this).staticcall(abi.encodePacked(this.placeholder.selector));
        if (isOk) return OK;
        revert("MockActionDummyOutOfGas.termsOk");
    }
}
"
    },
    "contracts/mocks/gelato_actions/one-off/MockActionDummy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {GelatoActionsStandard} from "../../../gelato_actions/GelatoActionsStandard.sol";
import {DataFlow} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract MockActionDummy is GelatoActionsStandard {
    event LogAction(bool falseOrTrue);

    function action(bool _falseOrTrue) public payable virtual {
        emit LogAction(_falseOrTrue);
    }

    function termsOk(uint256, address, bytes calldata _data, DataFlow, uint256, uint256)
        external
        view
        virtual
        override
        returns(string memory)
    {
        bool isOk = abi.decode(_data[4:], (bool));
        if (isOk) return OK;
        return "NotOk";
    }
}
"
    },
    "contracts/gelato_core/GelatoCore.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, Provider, Task, TaskReceipt} from "./interfaces/IGelatoCore.sol";
import {GelatoExecutors} from "./GelatoExecutors.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {GelatoTaskReceipt} from "../libraries/GelatoTaskReceipt.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {IGelatoCondition} from "../gelato_conditions/IGelatoCondition.sol";
import {IGelatoAction} from "../gelato_actions/IGelatoAction.sol";
import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";

/// @title GelatoCore
/// @author Luis Schliesske & Hilmar Orth
/// @notice Task: submission, validation, execution, and cancellation
/// @dev Find all NatSpecs inside IGelatoCore
contract GelatoCore is IGelatoCore, GelatoExecutors {

    using GelatoBytes for bytes;
    using GelatoTaskReceipt for TaskReceipt;
    using SafeMath for uint256;

    // Setting State Vars for GelatoSysAdmin
    constructor(GelatoSysAdminInitialState memory _) public {
        gelatoGasPriceOracle = _.gelatoGasPriceOracle;
        oracleRequestData = _.oracleRequestData;
        gelatoMaxGas = _.gelatoMaxGas;
        internalGasRequirement = _.internalGasRequirement;
        minExecutorStake = _.minExecutorStake;
        executorSuccessShare = _.executorSuccessShare;
        sysAdminSuccessShare = _.sysAdminSuccessShare;
        totalSuccessShare = _.totalSuccessShare;
    }

    // ================  STATE VARIABLES ======================================
    // TaskReceiptIds
    uint256 public override currentTaskReceiptId;
    // taskReceipt.id => taskReceiptHash
    mapping(uint256 => bytes32) public override taskReceiptHash;

    // ================  SUBMIT ==============================================
    function canSubmitTask(
        address _userProxy,
        Provider memory _provider,
        Task memory _task,
        uint256 _expiryDate
    )
        external
        view
        override
        returns(string memory)
    {
        // EXECUTOR CHECKS
        if (!isExecutorMinStaked(executorByProvider[_provider.addr]))
            return "GelatoCore.canSubmitTask: executor not minStaked";

        // ExpiryDate
        if (_expiryDate != 0)
            if (_expiryDate < block.timestamp)
                return "GelatoCore.canSubmitTask: expiryDate";

        // Check Provider details
        string memory isProvided;
        if (_userProxy == _provider.addr) {
            if (_task.selfProviderGasLimit < internalGasRequirement.mul(2))
                return "GelatoCore.canSubmitTask:selfProviderGasLimit too low";
            isProvided = providerModuleChecks(_userProxy, _provider, _task);
        }
        else isProvided = isTaskProvided(_userProxy, _provider, _task);
        if (!isProvided.startsWithOK())
            return string(abi.encodePacked("GelatoCore.canSubmitTask.isProvided:", isProvided));

        // Success
        return OK;
    }

    function submitTask(
        Provider memory _provider,
        Task memory _task,
        uint256 _expiryDate
    )
        external
        override
    {
        Task[] memory singleTask = new Task[](1);
        singleTask[0] = _task;
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(singleTask);
        _storeTaskReceipt(false, msg.sender, _provider, 0, singleTask, _expiryDate, 0, 1);
    }

    function submitTaskCycle(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycles  // how many full cycles should be submitted
    )
        external
        override
    {
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(_tasks);
        _storeTaskReceipt(
            true, msg.sender, _provider, 0, _tasks, _expiryDate, 0, _cycles * _tasks.length
        );
    }

    function submitTaskChain(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits  // see IGelatoCore for explanation
    )
        external
        override
    {
        if (_sumOfRequestedTaskSubmits != 0) {
            require(
                _sumOfRequestedTaskSubmits >= _tasks.length,
                "GelatoCore.submitTaskChain: less requested submits than tasks"
            );
        }
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(_tasks);
        _storeTaskReceipt(
            true, msg.sender, _provider, 0, _tasks, _expiryDate, 0, _sumOfRequestedTaskSubmits
        );
    }

    function _storeTaskReceipt(
        bool _newCycle,
        address _userProxy,
        Provider memory _provider,
        uint256 _index,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycleId,
        uint256 _submissionsLeft
    )
        private
    {
        // Increment TaskReceipt ID storage
        uint256 nextTaskReceiptId = currentTaskReceiptId + 1;
        currentTaskReceiptId = nextTaskReceiptId;

        // Generate new Task Receipt
        TaskReceipt memory taskReceipt = TaskReceipt({
            id: nextTaskReceiptId,
            userProxy: _userProxy, // Smart Contract Accounts ONLY
            provider: _provider,
            index: _index,
            tasks: _tasks,
            expiryDate: _expiryDate,
            cycleId: _newCycle ? nextTaskReceiptId : _cycleId,
            submissionsLeft: _submissionsLeft // 0=infinity, 1=once, X=maxTotalExecutions
        });

        // Hash TaskReceipt
        bytes32 hashedTaskReceipt = hashTaskReceipt(taskReceipt);

        // Store TaskReceipt Hash
        taskReceiptHash[taskReceipt.id] = hashedTaskReceipt;

        emit LogTaskSubmitted(taskReceipt.id, hashedTaskReceipt, taskReceipt);
    }

    // ================  CAN EXECUTE EXECUTOR API ============================
    // _gasLimit must be gelatoMaxGas for all Providers except SelfProviders.
    function canExec(TaskReceipt memory _TR, uint256 _gasLimit, uint256 _gelatoGasPrice)
        public
        view
        override
        returns(string memory)
    {
        if (!isExecutorMinStaked(executorByProvider[_TR.provider.addr]))
            return "ExecutorNotMinStaked";

        if (!isProviderLiquid(_TR.provider.addr, _gasLimit, _gelatoGasPrice))
            return "ProviderIlliquidity";

        string memory res = providerCanExec(
            _TR.userProxy,
            _TR.provider,
            _TR.task(),
            _gelatoGasPrice
        );
        if (!res.startsWithOK()) return res;

        bytes32 hashedTaskReceipt = hashTaskReceipt(_TR);
        if (taskReceiptHash[_TR.id] != hashedTaskReceipt) return "InvalidTaskReceiptHash";

        if (_TR.expiryDate != 0 && _TR.expiryDate <= block.timestamp)
            return "TaskReceiptExpired";

        // Optional CHECK Condition for user proxies
        if (_TR.task().conditions.length != 0) {
            for (uint i; i < _TR.task().conditions.length; i++) {
                try _TR.task().conditions[i].inst.ok(
                    _TR.id,
                    _TR.task().conditions[i].data,
                    _TR.cycleId
                )
                    returns(string memory condition)
                {
                    if (!condition.startsWithOK())
                        return string(abi.encodePacked("ConditionNotOk:", condition));
                } catch Error(string memory error) {
                    return string(abi.encodePacked("ConditionReverted:", error));
                } catch {
                    return "ConditionReverted:undefined";
                }
            }
        }

        // Optional CHECK Action Terms
        for (uint i; i < _TR.task().actions.length; i++) {
            // Only check termsOk if specified, else continue
            if (!_TR.task().actions[i].termsOkCheck) continue;

            try IGelatoAction(_TR.task().actions[i].addr).termsOk(
                _TR.id,
                _TR.userProxy,
                _TR.task().actions[i].data,
                _TR.task().actions[i].dataFlow,
                _TR.task().actions[i].value,
                _TR.cycleId
            )
                returns(string memory actionTermsOk)
            {
                if (!actionTermsOk.startsWithOK())
                    return string(abi.encodePacked("ActionTermsNotOk:", actionTermsOk));
            } catch Error(string memory error) {
                return string(abi.encodePacked("ActionReverted:", error));
            } catch {
                return "ActionRevertedNoMessage";
            }
        }

        // Executor Validation
        if (msg.sender == address(this)) return OK;
        else if (msg.sender == executorByProvider[_TR.provider.addr]) return OK;
        else return "InvalidExecutor";
    }

    // ================  EXECUTE EXECUTOR API ============================
    enum ExecutionResult { ExecSuccess, CanExecFailed, ExecRevert }
    enum ExecutorPay { Reward, Refund }

    // Execution Entry Point: tx.gasprice must be greater or equal to _getGelatoGasPrice()
    function exec(TaskReceipt memory _TR) external override {

        // Store startGas for gas-consumption based cost and payout calcs
        uint256 startGas = gasleft();

        // memcopy of gelatoGasPrice, to avoid multiple storage reads
        uint256 gelatoGasPrice = _getGelatoGasPrice();

        // Only assigned executor can execute this function
        require(
            msg.sender == executorByProvider[_TR.provider.addr],
            "GelatoCore.exec: Invalid Executor"
        );

        // The gas stipend the executor must provide. Special case for SelfProviders.
        uint256 gasLimit
            = _TR.selfProvider() ? _TR.task().selfProviderGasLimit : gelatoMaxGas;

        ExecutionResult executionResult;
        string memory reason;

        try this.executionWrapper{
            gas: gasleft().sub(internalGasRequirement, "GelatoCore.exec: Insufficient gas")
        }(_TR, gasLimit, gelatoGasPrice)
            returns (ExecutionResult _executionResult, string memory _reason)
        {
            executionResult = _executionResult;
            reason = _reason;
        } catch Error(string memory error) {
            executionResult = ExecutionResult.ExecRevert;
            reason = error;
        } catch {
            // If any of the external calls in executionWrapper resulted in e.g. out of gas,
            // Executor is eligible for a Refund, but only if Executor sent gelatoMaxGas.
            executionResult = ExecutionResult.ExecRevert;
            reason = "GelatoCore.executionWrapper:undefined";
        }

        if (executionResult == ExecutionResult.ExecSuccess) {
            // END-1: SUCCESS => TaskReceipt was deleted in _exec & Reward
            (uint256 executorSuccessFee, uint256 sysAdminSuccessFee) = _processProviderPayables(
                _TR.provider.addr,
                ExecutorPay.Reward,
                startGas,
                gasLimit,
                gelatoGasPrice
            );
            emit LogExecSuccess(msg.sender, _TR.id, executorSuccessFee, sysAdminSuccessFee);

        } else if (executionResult == ExecutionResult.CanExecFailed) {
            // END-2: CanExecFailed => No TaskReceipt Deletion & No Refund
            emit LogCanExecFailed(msg.sender, _TR.id, reason);

        } else {
            // executionResult == ExecutionResult.ExecRevert
            // END-3.1: ExecReverted NO gelatoMaxGas => No TaskReceipt Deletion & No Refund
            if (startGas < gasLimit)
                emit LogExecReverted(msg.sender, _TR.id, 0, reason);
            else {
                // END-3.2: ExecReverted BUT gelatoMaxGas was used
                //  => TaskReceipt Deletion (delete in _exec was reverted) & Refund
                delete taskReceiptHash[_TR.id];
                (uint256 executorRefund,) = _processProviderPayables(
                    _TR.provider.addr,
                    ExecutorPay.Refund,
                    startGas,
                    gasLimit,
                    gelatoGasPrice
                );
                emit LogExecReverted(msg.sender, _TR.id, executorRefund, reason);
            }
        }
    }

    // Used by GelatoCore.exec(), to handle Out-Of-Gas from execution gracefully
    function executionWrapper(
        TaskReceipt memory taskReceipt,
        uint256 _gasLimit,  // gelatoMaxGas or task.selfProviderGasLimit
        uint256 _gelatoGasPrice
    )
        external
        returns(ExecutionResult, string memory)
    {
        require(msg.sender == address(this), "GelatoCore.executionWrapper:onlyGelatoCore");

        // canExec()
        string memory canExecRes = canExec(taskReceipt, _gasLimit, _gelatoGasPrice);
        if (!canExecRes.startsWithOK()) return (ExecutionResult.CanExecFailed, canExecRes);

        // Will revert if exec failed => will be caught in exec flow
        _exec(taskReceipt);

        // Execution Success: Executor REWARD
        return (ExecutionResult.ExecSuccess, "");
    }

    function _exec(TaskReceipt memory _TR) private {
        // INTERACTIONS
        // execPayload and proxyReturndataCheck values read from ProviderModule
        bytes memory execPayload;
        bool proxyReturndataCheck;

        try IGelatoProviderModule(_TR.provider.module).execPayload(
            _TR.id,
            _TR.userProxy,
            _TR.provider.addr,
            _TR.task(),
            _TR.cycleId
        )
            returns(bytes memory _execPayload, bool _proxyReturndataCheck)
        {
            execPayload = _execPayload;
            proxyReturndataCheck = _proxyReturndataCheck;
        } catch Error(string memory _error) {
            revert(string(abi.encodePacked("GelatoCore._exec.execPayload:", _error)));
        } catch {
            revert("GelatoCore._exec.execPayload:undefined");
        }

        // To prevent single task exec reentrancy we delete hash before external call
        delete taskReceiptHash[_TR.id];

        // Execution via UserProxy
        (bool success, bytes memory userProxyReturndata) = _TR.userProxy.call(execPayload);

        // Check if actions reverts were caught by userProxy
        if (success && proxyReturndataCheck) {
            try _TR.provider.module.execRevertCheck(userProxyReturndata) {
                // success: no revert from providerModule signifies no revert found
            } catch Error(string memory _error) {
                revert(string(abi.encodePacked("GelatoCore._exec.execRevertCheck:", _error)));
            } catch {
                revert("GelatoCore._exec.execRevertCheck:undefined");
            }
        }

        // SUCCESS
        if (success) {
            // Optional: Automated Cyclic Task Submissions
            if (_TR.submissionsLeft != 1) {
                _storeTaskReceipt(
                    false,  // newCycle?
                    _TR.userProxy,
                    _TR.provider,
                    _TR.nextIndex(),
                    _TR.tasks,
                    _TR.expiryDate,
                    _TR.cycleId,
                    _TR.submissionsLeft == 0 ? 0 : _TR.submissionsLeft - 1
                );
            }
        } else {
            // FAILURE: reverts, caught or uncaught in userProxy.call, were detected
            // We revert all state from _exec/userProxy.call and catch revert in exec flow
            // Caution: we also revert the deletion of taskReceiptHash.
            userProxyReturndata.revertWithErrorString("GelatoCore._exec:");
        }
    }

    function _processProviderPayables(
        address _provider,
        ExecutorPay _payType,
        uint256 _startGas,
        uint256 _gasLimit,  // gelatoMaxGas or selfProviderGasLimit
        uint256 _gelatoGasPrice
    )
        private
        returns(uint256 executorCompensation, uint256 sysAdminCompensation)
    {
        uint256 estGasUsed = _startGas - gasleft();

        // Provider payable Gas Refund capped at gelatoMaxGas
        //  (- consecutive state writes + gas refund from deletion)
        uint256 cappedGasUsed =
            estGasUsed < _gasLimit
                ? estGasUsed + EXEC_TX_OVERHEAD
                : _gasLimit + EXEC_TX_OVERHEAD;

        if (_payType == ExecutorPay.Reward) {
            executorCompensation = executorSuccessFee(cappedGasUsed, _gelatoGasPrice);
            sysAdminCompensation = sysAdminSuccessFee(cappedGasUsed, _gelatoGasPrice);
            // ExecSuccess: Provider pays ExecutorSuccessFee and SysAdminSuccessFee
            providerFunds[_provider] = providerFunds[_provider].sub(
                executorCompensation.add(sysAdminCompensation),
                "GelatoCore._processProviderPayables: providerFunds underflow"
            );
            executorStake[msg.sender] += executorCompensation;
            sysAdminFunds += sysAdminCompensation;
        } else {
            // ExecFailure: Provider REFUNDS estimated costs to executor
            executorCompensation = cappedGasUsed.mul(_gelatoGasPrice);
            providerFunds[_provider] = providerFunds[_provider].sub(
                executorCompensation,
                "GelatoCore._processProviderPayables: providerFunds underflow"
            );
            executorStake[msg.sender] += executorCompensation;
        }
    }

    // ================  CANCEL USER / EXECUTOR API ============================
    function cancelTask(TaskReceipt memory _TR) public override {
        // Checks
        require(
            msg.sender == _TR.userProxy || msg.sender == _TR.provider.addr,
            "GelatoCore.cancelTask: sender"
        );
        // Effects
        bytes32 hashedTaskReceipt = hashTaskReceipt(_TR);
        require(
            hashedTaskReceipt == taskReceiptHash[_TR.id],
            "GelatoCore.cancelTask: invalid taskReceiptHash"
        );
        delete taskReceiptHash[_TR.id];
        emit LogTaskCancelled(_TR.id, msg.sender);
    }

    function multiCancelTasks(TaskReceipt[] memory _taskReceipts) external override {
        for (uint i; i < _taskReceipts.length; i++) cancelTask(_taskReceipts[i]);
    }

    // Helpers
    function hashTaskReceipt(TaskReceipt memory _TR) public pure override returns(bytes32) {
        return keccak256(abi.encode(_TR));
    }

    function _handleSelfProviderGasDefaults(Task[] memory _tasks) private view {
        for (uint256 i; i < _tasks.length; i++) {
            if (_tasks[i].selfProviderGasLimit == 0) {
                _tasks[i].selfProviderGasLimit = gelatoMaxGas;
            } else {
                require(
                    _tasks[i].selfProviderGasLimit >= internalGasRequirement.mul(2),
                    "GelatoCore._handleSelfProviderGasDefaults:selfProviderGasLimit too low"
                );
            }
            if (_tasks[i].selfProviderGasPriceCeil == 0)
                _tasks[i].selfProviderGasPriceCeil = NO_CEIL;
        }
    }
}
"
    },
    "contracts/libraries/GelatoTaskReceipt.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;

import {Task, TaskReceipt} from "../gelato_core/interfaces/IGelatoCore.sol";

library GelatoTaskReceipt {
    function task(TaskReceipt memory _TR) internal pure returns(Task memory) {
        return _TR.tasks[_TR.index];
    }

    function nextIndex(TaskReceipt memory _TR) internal pure returns(uint256) {
        return _TR.index == _TR.tasks.length - 1 ? 0 : _TR.index + 1;
    }

    function selfProvider(TaskReceipt memory _TR) internal pure returns(bool) {
        return _TR.provider.addr == _TR.userProxy;
    }
}"
    },
    "contracts/gelato_helpers/GelatoMultiCall.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, TaskReceipt} from "../gelato_core/interfaces/IGelatoCore.sol";
import {GelatoTaskReceipt} from "../libraries/GelatoTaskReceipt.sol";

/// @title GelatoMultiCall - Aggregate results from multiple read-only function calls on GelatoCore
/// @author Hilmar X (inspired by Maker's Multicall)
contract GelatoMultiCall {

    using GelatoTaskReceipt for TaskReceipt;

    IGelatoCore public immutable gelatoCore;

    constructor(IGelatoCore _gelatoCore) public { gelatoCore = _gelatoCore; }

    struct Reponse { uint256 taskReceiptId; string response; }

    function multiCanExec(
        TaskReceipt[] memory _TR,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        public
        view
        returns (uint256 blockNumber, Reponse[] memory responses)
    {
        blockNumber = block.number;
        responses = new Reponse[](_TR.length);
        for(uint256 i = 0; i < _TR.length; i++) {
            try gelatoCore.canExec(_TR[i], getGasLimit(_TR[i], _gelatoMaxGas), _gelatoGasPrice)
                returns(string memory response)
            {
                responses[i] = Reponse({taskReceiptId: _TR[i].id, response: response});
            } catch {
                responses[i] = Reponse({
                    taskReceiptId: _TR[i].id,
                    response: "GelatoMultiCall.multiCanExec: failed"
                });
            }
        }
    }

    function getGasLimit(TaskReceipt memory _TR, uint256 _gelatoMaxGas)
        private
        pure
        returns(uint256 gasLimit)
    {
        gasLimit = _TR.selfProvider() ? _TR.task().selfProviderGasLimit : _gelatoMaxGas;
    }

}"
    },
    "contracts/gelato_provider_modules/ds_proxy_provider/ProviderModuleDSProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {GelatoProviderModuleStandard} from "../GelatoProviderModuleStandard.sol";
import {Task} from "../../gelato_core/interfaces/IGelatoCore.sol";
import {
    DSProxyFactory
} from "../../user_proxies/ds_proxy/Proxy.sol";
import {
    IDSProxy
} from "../../user_proxies/ds_proxy/interfaces/IProxy.sol";
import {DSAuthority} from "../../user_proxies/ds_proxy/Auth.sol";
import {GelatoActionPipeline} from "../../gelato_actions/GelatoActionPipeline.sol";

contract ProviderModuleDSProxy is GelatoProviderModuleStandard {

    address public immutable dsProxyFactory;
    address public immutable gelatoCore;
    GelatoActionPipeline public immutable gelatoActionPipeline;

    constructor(
        address _dsProxyFactory,
        address _gelatoCore,
        GelatoActionPipeline _gelatActionPipeline
    )
        public
    {
        dsProxyFactory = _dsProxyFactory;
        gelatoCore = _gelatoCore;
        gelatoActionPipeline = _gelatActionPipeline;
    }

    // ================= GELATO PROVIDER MODULE STANDARD ================
    function isProvided(address _userProxy, address, Task calldata)
        external
        view
        override
        returns(string memory)
    {
        // Was proxy deployed from correct factory?
        bool proxyOk = DSProxyFactory(dsProxyFactory).isProxy(
            _userProxy
        );
        if (!proxyOk) return "ProviderModuleGelatoUserProxy.isProvided:InvalidUserProxy";

        // Is gelato core whitelisted?
        DSAuthority authority = IDSProxy(_userProxy).authority();
        bool isGelatoWhitelisted = authority.canCall(gelatoCore, _userProxy, IDSProxy(_userProxy).execute.selector);
        if (!isGelatoWhitelisted) return "ProviderModuleGelatoUserProxy.isProvided:GelatoCoreNotWhitelisted";

        return OK;
    }

    /// @dev DS PROXY ONLY ALLOWS DELEGATE CALL for single actions, that's why we also use multisend
    function execPayload(uint256, address, address, Task calldata _task, uint256)
        external
        view
        override
        returns(bytes memory payload, bool)
    {
        // Action.Operation encoded into gelatoActionPipelinePayload and handled by GelatoActionPipeline
        bytes memory gelatoActionPipelinePayload = abi.encodeWithSelector(
            GelatoActionPipeline.execActionsAndPipeData.selector,
            _task.actions
        );

        // Delegate call by default
        payload = abi.encodeWithSignature(
            "execute(address,bytes)",
            gelatoActionPipeline,  // to
            gelatoActionPipelinePayload  // data
        );

    }
}"
    },
    "contracts/user_proxies/ds_proxy/Proxy.sol": {
      "content": "// proxy.sol - execute actions atomically through the proxy's identity

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.5.0;

import {DSAuth} from "./Auth.sol";
import {DSNote} from "./Note.sol";

// DSProxy
// Allows code execution using a persistant identity This can be very
// useful to execute a sequence of atomic actions. Since the owner of
// the proxy can be changed, this allows for dynamic ownership models
// i.e. a multisig
contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;  // global cache for contracts

    constructor(address _cacheAddr) public {
        setCache(_cacheAddr);
    }

    fallback() external {
    }

    receive() external payable {
    }

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        returns (address target, bytes memory response)
    {
        target = cache.read(_code);
        if (target == address(0)) {
            // deploy contract & store its address in cache
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes memory _data)
        public
        auth
        note
        payable
        returns (bytes memory response)
    {
        require(_target != address(0), "ds-proxy-target-address-required");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    //set new cache
    function setCache(address _cacheAddr)
        public
        auth
        note
        returns (bool)
    {
        require(_cacheAddr != address(0), "ds-proxy-cache-address-required");
        cache = DSProxyCache(_cacheAddr);  // overwrite cache
        return true;
    }
}

// DSProxyFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract DSProxyFactory {
    event Created(address indexed sender, address indexed owner, address proxy, address cache);
    mapping(address=>bool) public isProxy;
    DSProxyCache public cache;

    constructor() public {
        cache = new DSProxyCache();
    }

    // deploys a new proxy instance
    // sets owner of proxy to caller
    function build() public returns (address payable proxy) {
        proxy = build(msg.sender);
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(address owner) public returns (address payable proxy) {
        proxy = address(new DSProxy(address(cache)));
        emit Created(msg.sender, owner, address(proxy), address(cache));
        DSProxy(proxy).setOwner(owner);
        isProxy[proxy] = true;
    }
}

// DSProxyCache
// This global cache stores addresses of contracts previously deployed
// by a proxy. This saves gas from repeat deployment of the same
// contracts and eliminates blockchain bloat.

// By default, all proxies deployed from the same factory store
// contracts in the same cache. The cache a proxy instance uses can be
// changed.  The cache uses the sha3 hash of a contract's bytecode to
// lookup the address
contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
            case 1 {
                // throw if contract failed to deploy
                revert(0, 0)
            }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}"
    },
    "contracts/user_proxies/ds_proxy/interfaces/IProxy.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.5.0;

import {DSAuthority} from "../Auth.sol";

interface IDSProxy {

    function execute(address _target, bytes calldata _data)
        external
        returns (bytes memory response);

    function authority()
        external
        view
        returns (DSAuthority);
}"
    },
    "contracts/user_proxies/ds_proxy/Auth.sol": {
      "content": "// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.4.23;


abstract contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view virtual returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}"
    },
    "contracts/user_proxies/ds_proxy/Note.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}"
    },
    "contracts/user_proxies/ds_proxy/Guard.sol": {
      "content": "// guard.sol -- simple whitelist implementation of DSAuthority

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.4.23;

import {DSAuth, DSAuthority} from "./Auth.sol";

contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 constant public ANY = bytes32(uint(-1));

    mapping (bytes32 => mapping (bytes32 => mapping (bytes32 => bool))) acl;

    function canCall(
        address src_, address dst_, bytes4 sig
    ) public view override returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));

        return acl[src][dst][sig]
            || acl[src][dst][ANY]
            || acl[src][ANY][sig]
            || acl[src][ANY][ANY]
            || acl[ANY][dst][sig]
            || acl[ANY][dst][ANY]
            || acl[ANY][ANY][sig]
            || acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes32 sig) public {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }
    function forbid(address src, address dst, bytes32 sig) public {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }

}

contract DSGuardFactory {
    mapping (address => bool)  public  isGuard;

    function newGuard() public returns (DSGuard guard) {
        guard = new DSGuard();
        guard.setOwner(msg.sender);
        isGuard[address(guard)] = true;
    }
}"
    },
    "contracts/mocks/provider_modules/gelato_user_proxy_provider/MockProviderModuleGelatoUserProxyExecRevertCheckOk.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {
    MockProviderModuleGelatoUserProxyExecRevertCheckRevert
} from "./MockProviderModuleGelatoUserProxyExecRevertCheckRevert.sol";
import {Action} from "../../../gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoUserProxy
} from "../../../user_proxies/gelato_user_proxy/interfaces/IGelatoUserProxy.sol";

contract MockProviderModuleGelatoUserProxyExecRevertCheckOk is
    MockProviderModuleGelatoUserProxyExecRevertCheckRevert
{
    function execRevertCheck(bytes memory)
        public
        pure
        virtual
        override
    {
        // do nothing
    }
}"
    },
    "contracts/user_proxies/ds_proxy/scripts/SubmitTaskScript.sol": {
      "content": "// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, Provider, Task} from "../../../gelato_core/interfaces/IGelatoCore.sol";

contract SubmitTaskScript {

    IGelatoCore public immutable gelatoCore;

    constructor(address _gelatoCore) public {
        gelatoCore = IGelatoCore(_gelatoCore);
    }

    /// @dev will be delegate called by ds_proxy
    function submitTask(Provider memory _provider, Task memory _task, uint256 _expiryDate)
        public
    {
        gelatoCore.submitTask(_provider, _task, _expiryDate);
    }

    /// @dev will be delegate called by ds_proxy
    function submitTaskCycle(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        public
    {
        gelatoCore.submitTaskCycle(_provider, _tasks, _expiryDate, _cycles);
    }

    /// @dev will be delegate called by ds_proxy
    function submitTaskChain(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        public
    {
        gelatoCore.submitTaskCycle(_provider, _tasks, _expiryDate, _sumOfRequestedTaskSubmits);
    }
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "metadata": {
      "useLiteralContent": true
    }
  }
}}