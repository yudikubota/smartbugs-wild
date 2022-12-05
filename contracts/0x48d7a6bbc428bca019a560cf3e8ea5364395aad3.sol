{{
  "language": "Solidity",
  "sources": {
    "/Users/jake/plasma-contracts/plasma_framework/contracts/Migrations.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/Imports.sol": {
      "content": "pragma solidity 0.5.11;

// Import contracts from third party Solidity libraries to make them available in tests.

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

contract Import {
    // dummy empty contract to allow the compiler not always trying to re-compile this file.
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/attackers/FailFastReentrancyGuardAttacker.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/utils/FailFastReentrancyGuard.sol";
import "../../src/framework/PlasmaFramework.sol";

contract FailFastReentrancyGuardAttacker is FailFastReentrancyGuard {
    PlasmaFramework private framework;

    event RemoteCallFailed();

    constructor(PlasmaFramework plasmaFramework) public {
        framework = plasmaFramework;
    }

    function guardedLocal() public nonReentrant(framework) {
        guardedLocal();
    }

    function guardedRemote() external nonReentrant(framework) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(this).call(abi.encodeWithSignature("guardedRemote()"));
        if (!success) {
            emit RemoteCallFailed();
        }
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/attackers/FallbackFunctionFailAttacker.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

contract FallbackFunctionFailAttacker {
    function () external payable {
        revert("fail on fallback function");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/attackers/OutOfGasFallbackAttacker.sol": {
      "content": "pragma solidity 0.5.11;

contract OutOfGasFallbackAttacker {
    function () external payable {
        while (true) {}
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/SpendingConditionMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/exits/interfaces/ISpendingCondition.sol";

contract SpendingConditionMock is ISpendingCondition {
    bool internal expectedResult;
    bool internal shouldRevert;
    Args internal expectedArgs;

    string constant internal REVERT_MESSAGE = "Test spending condition reverts";

    struct Args {
        bytes inputTx;
        uint256 utxoPos;
        bytes spendingTx;
        uint16 inputIndex;
        bytes witness;
    }

    /** mock what would "verify()" returns */
    function mockResult(bool result) public {
        expectedResult = result;
    }

    /** when called, the spending condition would always revert on purpose */
    function mockRevert() public {
        shouldRevert = true;
    }

    /** provide the expected args, it would check with the value called for "verify()" */
    function shouldVerifyArgumentEquals(Args memory args) public {
        expectedArgs = args;
    }

    /** override */
    function verify(
        bytes calldata inputTx,
        uint256 utxoPos,
        bytes calldata spendingTx,
        uint16 inputIndex,
        bytes calldata witness
    )
        external
        view
        returns (bool)
    {
        if (shouldRevert) {
            revert(REVERT_MESSAGE);
        }

        // only run the check when "shouldVerifyArgumentEqauals" is called
        if (expectedArgs.inputTx.length > 0) {
            require(keccak256(expectedArgs.inputTx) == keccak256(inputTx), "input tx not as expected");
            require(expectedArgs.utxoPos == utxoPos, "utxoPos not as expected");
            require(keccak256(expectedArgs.spendingTx) == keccak256(spendingTx), "spending tx not as expected");
            require(expectedArgs.inputIndex == inputIndex, "input index not as expected");
            require(keccak256(expectedArgs.witness) == keccak256(witness), "witness not as expected");
        }
        return expectedResult;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/SpyPlasmaFrameworkForExitGame.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/framework/PlasmaFramework.sol";
import "../../src/utils/PosLib.sol";
import "../../src/framework/models/BlockModel.sol";

contract SpyPlasmaFrameworkForExitGame is PlasmaFramework {
    using PosLib for PosLib.Position;

    uint256 public enqueuedCount = 0;
    mapping (uint256 => BlockModel.Block) public blocks;

    event EnqueueTriggered(
        uint256 vaultId,
        address token,
        uint64 exitableAt,
        uint256 txPos,
        uint256 exitId,
        address exitProcessor
    );

    /** This spy contract set the authority and maintainer both to the caller */
    constructor(uint256 _minExitPeriod, uint256 _initialImmuneVaults, uint256 _initialImmuneExitGames)
        public
        PlasmaFramework(_minExitPeriod, _initialImmuneVaults, _initialImmuneExitGames, msg.sender, msg.sender)
    {
    }

    /** override for test */
    function enqueue(
        uint256 _vaultId,
        address _token,
        uint64 _exitableAt,
        PosLib.Position calldata _txPos,
        uint160 _exitId,
        IExitProcessor _exitProcessor
    )
        external
        returns (uint256)
    {
        enqueuedCount += 1;
        emit EnqueueTriggered(
            _vaultId,
            _token,
            _exitableAt,
            _txPos.getTxPositionForExitPriority(),
            _exitId,
            address(_exitProcessor)
        );
        return enqueuedCount;
    }

    /**
     Custom test helpers
     */
    function setBlock(uint256 _blockNum, bytes32 _root, uint256 _timestamp) external {
        blocks[_blockNum] = BlockModel.Block(_root, _timestamp);
    }

    function setOutputFinalized(bytes32 _outputId, uint160 _exitId) external {
        outputsFinalizations[_outputId] = _exitId;
    }

    /**
     * Override to remove check that block exists
     */
    function isDeposit(uint256 blockNum) public view returns (bool) {
        return blockNum % childBlockInterval != 0;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/StateTransitionVerifierMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/exits/interfaces/IStateTransitionVerifier.sol";

contract StateTransitionVerifierMock is IStateTransitionVerifier {
    bool public expectedResult;
    bool public shouldRevert;
    Args public expectedArgs;

    struct Args {
        bytes inFlightTx;
        bytes[] inputTxs;
        uint16[] outputIndexOfInputTxs;
    }

    /** mock what "isCorrectStateTransition()" returns */
    function mockResult(bool result) public {
        expectedResult = result;
    }

    /** when called, the "isCorrectStateTransition" function reverts on purpose */
    function mockRevert() public {
        shouldRevert = true;
    }

    /** provide the expected args, it would check with the value called for "verify()" */
    function shouldVerifyArgumentEquals(Args memory args)
        public
    {
        expectedArgs = args;
    }

    function isCorrectStateTransition(
        bytes calldata inFlightTx,
        bytes[] calldata inputTxs,
        uint16[] calldata outputIndexOfInputTxs
    )
        external
        view
        returns (bool)
    {
        if (shouldRevert) {
            revert("Failing on purpose");
        }

        // only run the check when "shouldVerifyArgumentEqauals" is called
        if (expectedArgs.inFlightTx.length > 0) {
            require(keccak256(inFlightTx) == keccak256(expectedArgs.inFlightTx), "in-flight tx is not as expected");

            require(inputTxs.length == expectedArgs.inputTxs.length, "input txs array length mismatches expected data");
            for (uint i = 0; i < expectedArgs.inputTxs.length; i++) {
                require(keccak256(inputTxs[i]) == keccak256(expectedArgs.inputTxs[i]), "input tx is not as expected");
            }

            require(outputIndexOfInputTxs.length == expectedArgs.outputIndexOfInputTxs.length, "outputIndex array length mismatches expected data");
            for (uint i = 0; i < expectedArgs.outputIndexOfInputTxs.length; i++) {
                require(outputIndexOfInputTxs[i] == expectedArgs.outputIndexOfInputTxs[i], "output index of input txs is not as expected");
            }
        }

        return expectedResult;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/dummyVaults/SpyErc20VaultForExitGame.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/vaults/Erc20Vault.sol";
import "../../../src/framework/PlasmaFramework.sol";

contract SpyErc20VaultForExitGame is Erc20Vault {
    event Erc20WithdrawCalled(
        address target,
        address token,
        uint256 amount
    );

    constructor(PlasmaFramework _framework) public Erc20Vault(_framework) {}

    /** override for test */
    function withdraw(address payable _target, address _token, uint256 _amount) external {
        emit Erc20WithdrawCalled(_target, _token, _amount);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/dummyVaults/SpyEthVaultForExitGame.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/vaults/EthVault.sol";
import "../../../src/framework/PlasmaFramework.sol";

contract SpyEthVaultForExitGame is EthVault {
    uint256 public constant SAFE_GAS_STIPEND = 2300;

    event EthWithdrawCalled(
        address target,
        uint256 amount
    );

    constructor(PlasmaFramework _framework) public EthVault(_framework, SAFE_GAS_STIPEND) {}

    /** override for test */
    function withdraw(address payable _target, uint256 _amount) external {
        emit EthWithdrawCalled(_target, _amount);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/payment/PaymentInFlightExitModelUtilsMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../../src/exits/payment/PaymentInFlightExitModelUtils.sol";
import { PaymentExitDataModel as ExitModel } from "../../../src/exits/payment/PaymentExitDataModel.sol";

contract PaymentInFlightExitModelUtilsMock {

    ExitModel.InFlightExit public ife;

    constructor(uint256 exitMap, uint64 exitStartTimestamp) public {
        ife.exitMap = exitMap;
        ife.exitStartTimestamp = exitStartTimestamp;
    }

    /** Helper functions */
    function setWithdrawData(
        string memory target,
        uint16 index,
        ExitModel.WithdrawData memory data
    )
        public
    {
        if (stringEquals(target, "inputs")) {
            ife.inputs[index] = data;
        } else if (stringEquals(target, "outputs")) {
            ife.outputs[index] = data;
        } else {
            revert("target should be either inputs or outputs");
        }
    }

    function stringEquals(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /** Wrapper functions */
    function isInputEmpty(uint16 index)
        external
        view
        returns (bool)
    {
        return PaymentInFlightExitModelUtils.isInputEmpty(ife, index);
    }

    function isOutputEmpty(uint16 index)
        external
        view
        returns (bool)
    {
        return PaymentInFlightExitModelUtils.isOutputEmpty(ife, index);
    }

    function isInputPiggybacked(uint16 index)
        external
        view
        returns (bool)
    {
        return PaymentInFlightExitModelUtils.isInputPiggybacked(ife, index);
    }

    function isOutputPiggybacked(uint16 index)
        external
        view
        returns (bool)
    {
        return PaymentInFlightExitModelUtils.isOutputPiggybacked(ife, index);
    }

    function setInputPiggybacked(uint16 index)
        external
    {
        PaymentInFlightExitModelUtils.setInputPiggybacked(ife, index);
    }

    function clearInputPiggybacked(uint16 index)
        external
    {
        PaymentInFlightExitModelUtils.clearInputPiggybacked(ife, index);
    }

    function setOutputPiggybacked(uint16 index)
        external
    {
        PaymentInFlightExitModelUtils.setOutputPiggybacked(ife, index);
    }

    function clearOutputPiggybacked(uint16 index)
        external
    {
        PaymentInFlightExitModelUtils.clearOutputPiggybacked(ife, index);
    }

    function isInFirstPhase(uint256 minExitPeriod)
        external
        view
        returns (bool)
    {
        return PaymentInFlightExitModelUtils.isInFirstPhase(ife, minExitPeriod);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/payment/routers/PaymentInFlightExitRouterMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../../../src/exits/payment/PaymentExitDataModel.sol";
import "../../../../src/exits/payment/routers/PaymentInFlightExitRouter.sol";
import "../../../../src/exits/payment/routers/PaymentInFlightExitRouterArgs.sol";
import "../../../../src/framework/PlasmaFramework.sol";
import "../../../../src/exits/interfaces/IStateTransitionVerifier.sol";
import "../../../../src/exits/payment/PaymentInFlightExitModelUtils.sol";

import "../../../../src/utils/FailFastReentrancyGuard.sol";

contract PaymentInFlightExitRouterMock is FailFastReentrancyGuard, PaymentInFlightExitRouter {
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    PlasmaFramework public framework;

    PaymentInFlightExitRouterArgs.StartExitArgs private startIfeArgs;
    PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnInputArgs private piggybackInputArgs;
    PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnOutputArgs private piggybackOutputArgs;
    PaymentInFlightExitRouterArgs.ChallengeCanonicityArgs private challengeCanonicityArgs;
    PaymentInFlightExitRouterArgs.ChallengeInputSpentArgs private challengeInputSpentArgs;
    PaymentInFlightExitRouterArgs.ChallengeOutputSpent private challengeOutputSpentArgs;

    constructor(PaymentExitGameArgs.Args memory args)
        public
        PaymentInFlightExitRouter(args)
    {
        framework = args.framework;
    }

    /** override and calls processInFlightExit for test */
    function processExit(uint160 exitId, uint256, address ercContract) external {
        PaymentInFlightExitRouter.processInFlightExit(exitId, ercContract);
    }

    function setInFlightExit(uint160 exitId, PaymentExitDataModel.InFlightExit memory exit) public {
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];
        ife.isCanonical = exit.isCanonical;
        ife.exitStartTimestamp = exit.exitStartTimestamp;
        ife.exitMap = exit.exitMap;
        ife.position = exit.position;
        ife.bondOwner = exit.bondOwner;
        ife.bondSize = exit.bondSize;
        ife.oldestCompetitorPosition = exit.oldestCompetitorPosition;

        for (uint i = 0; i < exit.inputs.length; i++) {
            ife.inputs[i] = exit.inputs[i];
        }

        for (uint i = 0; i < exit.outputs.length; i++) {
            ife.outputs[i] = exit.outputs[i];
        }
    }

    function getInFlightExitInput(uint160 exitId, uint16 inputIndex) public view returns (PaymentExitDataModel.WithdrawData memory) {
        return inFlightExitMap.exits[exitId].inputs[inputIndex];
    }

    function setInFlightExitInputPiggybacked(uint160 exitId, uint16 inputIndex) public payable {
        inFlightExitMap.exits[exitId].setInputPiggybacked(inputIndex);
    }

    function setInFlightExitOutputPiggybacked(uint160 exitId, uint16 outputIndex) public payable {
        inFlightExitMap.exits[exitId].setOutputPiggybacked(outputIndex);
    }

    function getInFlightExitOutput(uint160 exitId, uint16 outputIndex) public view returns (PaymentExitDataModel.WithdrawData memory) {
        return inFlightExitMap.exits[exitId].outputs[outputIndex];
    }

    /** calls the flagOutputFinalized function on behalf of the exit game */
    function proxyFlagOutputFinalized(bytes32 outputId, uint160 exitId) public {
        framework.flagOutputFinalized(outputId, exitId);
    }

    /**
     * This function helps test reentrant by making this function itself the first call with 'nonReentrant' protection
     * So all other PaymentExitGame functions that is protected by 'nonReentrant' too would fail as it would be considered as re-entrancy
     */
    function testNonReentrant(string memory testTarget) public nonReentrant(framework) {
        if (stringEquals(testTarget, "startInFlightExit")) {
            PaymentInFlightExitRouter.startInFlightExit(startIfeArgs);
        } else if (stringEquals(testTarget, "piggybackInFlightExitOnInput")) {
            PaymentInFlightExitRouter.piggybackInFlightExitOnInput(piggybackInputArgs);
        } else if (stringEquals(testTarget, "piggybackInFlightExitOnOutput")) {
            PaymentInFlightExitRouter.piggybackInFlightExitOnOutput(piggybackOutputArgs);
        } else if (stringEquals(testTarget, "challengeInFlightExitNotCanonical")) {
            PaymentInFlightExitRouter.challengeInFlightExitNotCanonical(challengeCanonicityArgs);
        } else if (stringEquals(testTarget, "respondToNonCanonicalChallenge")) {
            PaymentInFlightExitRouter.respondToNonCanonicalChallenge(bytes(""), 0, bytes(""));
        } else if (stringEquals(testTarget, "challengeInFlightExitInputSpent")) {
            PaymentInFlightExitRouter.challengeInFlightExitInputSpent(challengeInputSpentArgs);
        } else if (stringEquals(testTarget, "challengeInFlightExitOutputSpent")) {
            PaymentInFlightExitRouter.challengeInFlightExitOutputSpent(challengeOutputSpentArgs);
        } else if (stringEquals(testTarget, "deleteNonPiggybackedInFlightExit")) {
            PaymentInFlightExitRouter.deleteNonPiggybackedInFlightExit(uint160(0));
        }

        revert("non defined function");
    }

    /** empty function that accepts ETH to fund the contract as test setup */
    function depositFundForTest() public payable {}

    function stringEquals(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/payment/routers/PaymentStandardExitRouterMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../../../src/exits/payment/PaymentExitGameArgs.sol";
import "../../../../src/exits/payment/routers/PaymentStandardExitRouter.sol";
import "../../../../src/exits/payment/routers/PaymentStandardExitRouterArgs.sol";
import "../../../../src/framework/PlasmaFramework.sol";

contract PaymentStandardExitRouterMock is PaymentStandardExitRouter {
    PlasmaFramework private framework;

    PaymentStandardExitRouterArgs.StartStandardExitArgs private startStandardExitArgs;
    PaymentStandardExitRouterArgs.ChallengeStandardExitArgs private challengeStandardExitArgs;

    constructor(PaymentExitGameArgs.Args memory args)
        public
        PaymentStandardExitRouter(args)
    {
        framework = args.framework;
    }

    /** override and calls processStandardExit for test */
    function processExit(uint160 exitId, uint256, address ercContract) external {
        PaymentStandardExitRouter.processStandardExit(exitId, ercContract);
    }

    /** helper functions for testing */
    function setExit(uint160 exitId, PaymentExitDataModel.StandardExit memory exitData) public {
        PaymentStandardExitRouter.standardExitMap.exits[exitId] = exitData;
    }

    function proxyFlagOutputFinalized(bytes32 outputId, uint160 exitId) public {
        framework.flagOutputFinalized(outputId, exitId);
    }

    function depositFundForTest() public payable {}

    /**
     * This function helps test reentrant by making this function itself the first call with 'nonReentrant' protection
     * So all other PaymentExitGame functions that is protected by 'nonReentrant' too would fail as it would be considered as re-entrancy
     */
    function testNonReentrant(string memory testTarget) public nonReentrant(framework) {
        if (stringEquals(testTarget, "startStandardExit")) {
            PaymentStandardExitRouter.startStandardExit(startStandardExitArgs);
        } else if (stringEquals(testTarget, "challengeStandardExit")) {
            PaymentStandardExitRouter.challengeStandardExit(challengeStandardExitArgs);
        }
    }

    function stringEquals(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/utils/ExitIdWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/utils/PosLib.sol";
import "../../../src/exits/utils/ExitId.sol";

contract ExitIdWrapper {
    function isStandardExit(uint160 _exitId) public pure returns (bool) {
        return ExitId.isStandardExit(_exitId);
    }

    function getStandardExitId(bool _isDeposit, bytes memory _txBytes, uint256 _utxoPos)
        public
        pure
        returns (uint160)
    {
        PosLib.Position memory utxoPos = PosLib.decode(_utxoPos);
        return ExitId.getStandardExitId(_isDeposit, _txBytes, utxoPos);
    }

    function getInFlightExitId(bytes memory _txBytes)
        public
        pure
        returns (uint160)
    {
        return ExitId.getInFlightExitId(_txBytes);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/utils/ExitableTimestampWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/exits/utils/ExitableTimestamp.sol";

contract ExitableTimestampWrapper {
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    ExitableTimestamp.Calculator internal calculator;

    constructor(uint256 _minExitPeriod) public {
        calculator = ExitableTimestamp.Calculator(_minExitPeriod);
    }

    function calculateDepositTxOutputExitableTimestamp(
        uint256 _now
    )
        public
        view
        returns (uint64)
    {
        return calculator.calculateDepositTxOutputExitableTimestamp(_now);
    }

    function calculateTxExitableTimestamp(
        uint256 _now,
        uint256 _blockTimestamp
    )
        public
        view
        returns (uint64)
    {
        return calculator.calculateTxExitableTimestamp(_now, _blockTimestamp);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/utils/MoreVpFinalizationWrapper.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../../src/exits/utils/MoreVpFinalization.sol";

contract MoreVpFinalizationWrapper {
    function isStandardFinalized(
        PlasmaFramework framework,
        bytes memory txBytes,
        uint256 txPos,
        bytes memory inclusionProof
    )
        public
        view
        returns (bool)
    {
        return MoreVpFinalization.isStandardFinalized(
            framework,
            txBytes,
            PosLib.decode(txPos),
            inclusionProof
        );
    }

    function isProtocolFinalized(
        PlasmaFramework framework,
        bytes memory txBytes
    )
        public
        view
        returns (bool)
    {
        return MoreVpFinalization.isProtocolFinalized(
            framework,
            txBytes
        );
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/exits/utils/OutputIdWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/exits/utils/OutputId.sol";

contract OutputIdWrapper {
    function computeDepositOutputId(
        bytes memory _txBytes,
        uint8 _outputIndex,
        uint256 _utxoPosValue
    )
        public
        pure
        returns (bytes32)
    {
        return OutputId.computeDepositOutputId(_txBytes, _outputIndex, _utxoPosValue);
    }

    function computeNormalOutputId(
        bytes memory _txBytes,
        uint8 _outputIndex
    )
        public
        pure
        returns (bytes32)
    {
        return OutputId.computeNormalOutputId(_txBytes, _outputIndex);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/BlockControllerMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/framework/BlockController.sol";

contract BlockControllerMock is BlockController {
    address private maintainer;

    constructor(
        uint256 interval,
        uint256 minExitPeriod,
        uint256 initialImmuneVaults,
        address authority
    )
        public
        BlockController(
            interval,
            minExitPeriod,
            initialImmuneVaults,
            authority
        )
    {
        maintainer = msg.sender;
    }

    /**
     * override to make it non-abstract contract
     * this mock file set the user that deploys the contract as maintainer to simplify the test.
     */
    function getMaintainer() public view returns (address) {
        return maintainer;
    }

    function setBlock(uint256 _blockNum, bytes32 _root, uint256 _timestamp) external {
        blocks[_blockNum] = BlockModel.Block(_root, _timestamp);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/DummyExitGame.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./registries/ExitGameRegistryMock.sol";
import "../../src/framework/ExitGameController.sol";
import "../../src/framework/interfaces/IExitProcessor.sol";
import "../../src/vaults/Erc20Vault.sol";
import "../../src/vaults/EthVault.sol";
import "../../src/utils/PosLib.sol";

contract DummyExitGame is IExitProcessor {
    uint256 public priorityFromEnqueue;

    ExitGameRegistryMock public exitGameRegistry;
    ExitGameController public exitGameController;
    EthVault public ethVault;
    Erc20Vault public erc20Vault;

    event ExitFinalizedFromDummyExitGame (
        uint256 indexed exitId,
        uint256 vaultId,
        address ercContract
    );

    // override ExitProcessor interface
    function processExit(uint160 exitId, uint256 vaultId, address ercContract) public {
        emit ExitFinalizedFromDummyExitGame(exitId, vaultId, ercContract);
    }

    // setter function only for test, not a real Exit Game function
    function setExitGameRegistry(address _contract) public {
        exitGameRegistry = ExitGameRegistryMock(_contract);
    }

    function checkOnlyFromNonQuarantinedExitGame() public view returns (bool) {
        return exitGameRegistry.checkOnlyFromNonQuarantinedExitGame();
    }

    // setter function only for test, not a real Exit Game function
    function setExitGameController(address _contract) public {
        exitGameController = ExitGameController(_contract);
    }

    function enqueue(uint256 vaultId, address token, uint64 exitableAt, uint256 txPos, uint160 exitId, IExitProcessor exitProcessor)
        public
    {
        priorityFromEnqueue = exitGameController.enqueue(vaultId, token, exitableAt, PosLib.decode(txPos), exitId, exitProcessor);
    }

    function proxyBatchFlagOutputsFinalized(bytes32[] memory outputIds, uint160 exitId) public {
        exitGameController.batchFlagOutputsFinalized(outputIds, exitId);
    }

    function proxyFlagOutputFinalized(bytes32 outputId, uint160 exitId) public {
        exitGameController.flagOutputFinalized(outputId, exitId);
    }

    // setter function only for test, not a real Exit Game function
    function setEthVault(EthVault vault) public {
        ethVault = vault;
    }

    function proxyEthWithdraw(address payable target, uint256 amount) public {
        ethVault.withdraw(target, amount);
    }

    // setter function only for test, not a real Exit Game function
    function setErc20Vault(Erc20Vault vault) public {
        erc20Vault = vault;
    }

    function proxyErc20Withdraw(address payable target, address token, uint256 amount) public {
        erc20Vault.withdraw(target, token, amount);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/DummyVault.sol": {
      "content": "pragma solidity 0.5.11;

import "./registries/VaultRegistryMock.sol";
import "../../src/framework/BlockController.sol";

contract DummyVault {
    VaultRegistryMock internal vaultRegistry;
    BlockController internal blockController;

    // setter function only for test, not a real Vault function
    function setVaultRegistry(address _contract) public {
        vaultRegistry = VaultRegistryMock(_contract);
    }

    function checkOnlyFromNonQuarantinedVault() public view returns (bool) {
        return vaultRegistry.checkOnlyFromNonQuarantinedVault();
    }

    // setter function only for test, not a real Vault function
    function setBlockController(address _contract) public {
        blockController = BlockController(_contract);
    }

    function submitDepositBlock(bytes32 _blockRoot) public {
        blockController.submitDepositBlock(_blockRoot);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/ExitGameControllerMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/framework/ExitGameController.sol";

contract ExitGameControllerMock is ExitGameController {
    address private maintainer;

    constructor(uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
        ExitGameController(_minExitPeriod, _initialImmuneExitGames)
    {
        maintainer = msg.sender;
    }

    /**
     * override to make it non-abstract contract
     * this mock file set the user that deploys the contract as maintainer to simplify the test.
     */
    function getMaintainer() public view returns (address) {
        return maintainer;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/ProtocolWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/framework/Protocol.sol";

contract ProtocolWrapper {
    // solhint-disable-next-line func-name-mixedcase
    function MVP() public pure returns (uint8) {
        return Protocol.MVP();
    }

    // solhint-disable-next-line func-name-mixedcase
    function MORE_VP() public pure returns (uint8) {
        return Protocol.MORE_VP();
    }

    function isValidProtocol(uint8 protocol) public pure returns (bool) {
        return Protocol.isValidProtocol(protocol);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/ReentrancyExitGame.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/framework/ExitGameController.sol";
import "../../src/framework/interfaces/IExitProcessor.sol";

contract ReentrancyExitGame is IExitProcessor {
    ExitGameController public exitGameController;
    uint256 public vaultId;
    address public testToken;
    uint256 public reentryMaxExitToProcess;

    constructor(ExitGameController _controller, uint256 _vaultId, address _token, uint256 _reentryMaxExitToProcess) public {
        exitGameController = _controller;
        vaultId = _vaultId;
        testToken = _token;
        reentryMaxExitToProcess = _reentryMaxExitToProcess;
    }

    // override ExitProcessor interface
    // This would call the processExits back to mimic reentracy attack
    function processExit(uint160, uint256, address) public {
        exitGameController.processExits(vaultId, testToken, 0, reentryMaxExitToProcess);
    }

    function enqueue(uint256 _vaultId, address _token, uint64 _exitableAt, uint256 _txPos, uint160 _exitId, IExitProcessor _exitProcessor)
        public
    {
        exitGameController.enqueue(_vaultId, _token, _exitableAt, PosLib.decode(_txPos), _exitId, _exitProcessor);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/registries/ExitGameRegistryMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/framework/registries/ExitGameRegistry.sol";

contract ExitGameRegistryMock is ExitGameRegistry {
    address private maintainer;

    constructor (uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
        ExitGameRegistry(_minExitPeriod, _initialImmuneExitGames)
    {
    }

    /** override to make it non-abstract contract */
    function getMaintainer() public view returns (address) {
        return maintainer;
    }

    /** test helper function */
    function setMaintainer(address maintainerToSet) public {
        maintainer = maintainerToSet;
    }

    function checkOnlyFromNonQuarantinedExitGame() public onlyFromNonQuarantinedExitGame view returns (bool) {
        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/registries/VaultRegistryMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/framework/registries/VaultRegistry.sol";

contract VaultRegistryMock is VaultRegistry {
    address private maintainer;

    constructor (uint256 _minExitPeriod, uint256 _initialImmuneVaults)
        public
        VaultRegistry(_minExitPeriod, _initialImmuneVaults)
    {
    }

    /** override to make it non-abstract contract */
    function getMaintainer() public view returns (address) {
        return maintainer;
    }

    /** test helper function */
    function setMaintainer(address maintainerToSet) public {
        maintainer = maintainerToSet;
    }

    function checkOnlyFromNonQuarantinedVault() public onlyFromNonQuarantinedVault view returns (bool) {
        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/utils/ExitPriorityWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/framework/utils/ExitPriority.sol";
import "../../../src/utils/PosLib.sol";

contract ExitPriorityWrapper {
    function computePriority(uint64 exitableAt, uint256 txPos, uint160 exitId) public pure returns (uint256) {
        return ExitPriority.computePriority(exitableAt, PosLib.decode(txPos), exitId);
    }

    function parseExitableAt(uint256 priority) public pure returns (uint64) {
        return ExitPriority.parseExitableAt(priority);
    }

    function parseExitId(uint256 priority) public pure returns (uint160) {
        return ExitPriority.parseExitId(priority);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/framework/utils/PriorityQueueLoadTest.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/framework/utils/PriorityQueue.sol";

contract PriorityQueueLoadTest is PriorityQueue {

    /**
     * Helper function to inject heap data. It only appends batch of data to the end of array used as heap.
     * The client using this should make sure the data is in the order of an valid heap.
     */
    function setHeapData(uint256[] calldata heapList) external {
        for (uint i = 0; i < heapList.length; i++) {
            PriorityQueue.queue.heapList.push(heapList[i]);
        }
        PriorityQueue.queue.currentSize += heapList.length;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/python_tests_wrappers/PriorityQueueTest.sol": {
      "content": "pragma solidity ^0.5.0;
import "../../src/framework/utils/PriorityQueue.sol";

/**
 * @title PriorityQueue
 * @dev Min-heap priority queue implementation.
 */
contract PriorityQueueTest{

    /*
     * Events
     */

    event DelMin(uint256 val);

    /*
     *  Storage
     */

    PriorityQueue public queue;
    /*
     *  Public functions
     */

    constructor()
        public
    {
        queue = new PriorityQueue();
    }

    /**
     * @dev Inserts an element into the queue. Does not perform deduplication.
     */
    function insert(uint256 _element)
        public
    {
        queue.insert(_element);
    }

    /**
     * @dev Overrides the default implementation, by simply emitting an even on deletion, so that the result is testable.
     * @return The smallest element in the priority queue.
     */
    function delMin()
        public
        returns (uint256 value)
    {
        value = queue.delMin();
        emit DelMin(value);
    }

    /*
     * Read-only functions
     */
    /**
     * @dev Returns the top element of the heap.
     * @return The smallest element in the priority queue.
     */
    function getMin()
        public
        view
        returns (uint256)
    {
        return queue.getMin();
    }

    function currentSize()
        external
        view
        returns (uint256)
    {
        return queue.currentSize();
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/python_tests_wrappers/RLPTest.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../src/utils/RLPReader.sol";


/**
 * @title RLPTest
 * @dev Contract for testing RLP decoding.
 */
contract RLPTest {
    function eight(bytes memory tx_bytes)
        public
        pure
        returns (uint256, address, address)
    {
        RLPReader.RLPItem[] memory txList = RLPReader.toList(RLPReader.toRlpItem(tx_bytes));
        return (
            RLPReader.toUint(txList[5]),
            RLPReader.toAddress(txList[6]),
            RLPReader.toAddress(txList[7])
        );
    }

    function eleven(bytes memory tx_bytes)
        public
        pure
        returns (uint256, address, address, address)
    {
        RLPReader.RLPItem[] memory  txList = RLPReader.toList(RLPReader.toRlpItem(tx_bytes));
        return (
            RLPReader.toUint(txList[7]),
            RLPReader.toAddress(txList[8]),
            RLPReader.toAddress(txList[9]),
            RLPReader.toAddress(txList[10])
        );
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/transactions/FungibleTokenOutputWrapper.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/transactions/FungibleTokenOutputModel.sol";

contract FungibleTokenOutputWrapper {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function decodeOutput(bytes memory encodedOutput)
        public
        pure
        returns (FungibleTokenOutputModel.Output memory)
    {
        GenericTransaction.Output memory genericOutput = GenericTransaction.decodeOutput(encodedOutput.toRlpItem());
        return FungibleTokenOutputModel.decodeOutput(genericOutput);
    }

    function getOutput(bytes memory transaction, uint16 outputIndex)
        public
        pure
        returns (FungibleTokenOutputModel.Output memory)
    {
        GenericTransaction.Transaction memory genericTx = GenericTransaction.decode(transaction);
        return FungibleTokenOutputModel.getOutput(genericTx, outputIndex);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/transactions/GenericTransactionWrapper.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/transactions/GenericTransaction.sol";

contract GenericTransactionWrapper {

    function decode(bytes memory transaction) public pure returns (GenericTransaction.Transaction memory) {
        return GenericTransaction.decode(transaction);
    }

    function getOutput(bytes memory transaction, uint16 outputIndex) public pure returns (GenericTransaction.Output memory) {
        GenericTransaction.Transaction memory genericTx = GenericTransaction.decode(transaction);
        return GenericTransaction.getOutput(genericTx, outputIndex);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/transactions/PaymentTransactionModelMock.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/transactions/PaymentTransactionModel.sol";

contract PaymentTransactionModelMock {
    using RLPReader for bytes;

    function decode(bytes memory transaction) public pure returns (PaymentTransactionModel.Transaction memory) {
        return PaymentTransactionModel.decode(transaction);
    }

    function getOutputOwner(uint256 outputType, address owner, address token, uint256 amount) public pure returns (address payable) {
        FungibleTokenOutputModel.Output memory output = FungibleTokenOutputModel.Output({
            outputType: outputType,
            outputGuard: bytes20(owner),
            token: token,
            amount: amount
        });
        return PaymentTransactionModel.getOutputOwner(output);
    }

    function getOutput(bytes memory transaction, uint16 outputIndex) public pure returns (FungibleTokenOutputModel.Output memory) {
        PaymentTransactionModel.Transaction memory decodedTx = PaymentTransactionModel.decode(transaction);
        return PaymentTransactionModel.getOutput(decodedTx, outputIndex);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/transactions/eip712Libs/PaymentEip712LibMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../../src/transactions/eip712Libs/PaymentEip712Lib.sol";
import "../../../src/transactions/PaymentTransactionModel.sol";

contract PaymentEip712LibMock {
    function hashTx(address _verifyingContract, bytes memory _rlpTx)
        public
        pure
        returns (bytes32)
    {
        PaymentEip712Lib.Constants memory eip712 = PaymentEip712Lib.initConstants(_verifyingContract);
        return PaymentEip712Lib.hashTx(eip712, PaymentTransactionModel.decode(_rlpTx));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/BitsWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/utils/Bits.sol";

contract BitsWrapper {
    function setBit(uint _self, uint8 _index) public pure returns (uint)
    {
        return Bits.setBit(_self, _index);
    }

    function clearBit(uint _self, uint8 _index) public pure returns (uint)
    {
        return Bits.clearBit(_self, _index);
    }

    /**
     * @dev It makes sense to expose just `bitSet` to be able to test both of Bits `getBit` and `bitSet`
     */
    function bitSet(uint _self, uint8 _index) public pure returns (bool)
    {
        return Bits.bitSet(_self, _index);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/BondSizeMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/exits/utils/BondSize.sol";

contract BondSizeMock {
    using BondSize for BondSize.Params;

    BondSize.Params public bond;

    constructor (uint128 initialBondSize, uint16 lowerBoundDivisor, uint16 upperBoundMultiplier) public {
        bond = BondSize.buildParams(initialBondSize, lowerBoundDivisor, upperBoundMultiplier);
    }

    function bondSize() public view returns (uint128) {
        return bond.bondSize();
    }

    function updateBondSize(uint128 newBondSize) public {
        bond.updateBondSize(newBondSize);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/MerkleWrapper.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/utils/Merkle.sol";

contract MerkleWrapper {

    function checkMembership(bytes memory leaf, uint256 index, bytes32 rootHash, bytes memory proof)
        public
        pure
        returns (bool)
    {
        return Merkle.checkMembership(leaf, index, rootHash, proof);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/OnlyWithValueMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/utils/OnlyWithValue.sol";

contract OnlyWithValueMock is OnlyWithValue {
    event OnlyWithValuePassed();

    function checkOnlyWithValue(uint256 _value) public payable onlyWithValue(_value) {
        emit OnlyWithValuePassed();
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/PosLibWrapper.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../src/utils/PosLib.sol";

contract PosLibWrapper {
    using PosLib for PosLib.Position;

    function toStrictTxPos(PosLib.Position memory pos)
        public
        pure
        returns (PosLib.Position memory)
    {
        return pos.toStrictTxPos();
    }

    function getTxPositionForExitPriority(PosLib.Position memory pos)
        public
        pure
        returns (uint256)
    {
        return pos.getTxPositionForExitPriority();
    }

    function encode(PosLib.Position memory pos) public pure returns (uint256) {
        return pos.encode();
    }

    function decode(uint256 pos) public pure returns (PosLib.Position memory) {
        return PosLib.decode(pos);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/QuarantineMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/framework/utils/Quarantine.sol";

contract QuarantineMock {
    using Quarantine for Quarantine.Data;
    Quarantine.Data internal _quarantine;

    constructor(uint256 _period, uint256 _initialImmuneCount)
        public
    {
        _quarantine.quarantinePeriod = _period;
        _quarantine.immunitiesRemaining = _initialImmuneCount;
    }

    function quarantineContract(address _contractAddress) public {
        _quarantine.quarantine(_contractAddress);
    }

    function isQuarantined(address _contractAddress) public view returns (bool) {
        return _quarantine.isQuarantined(_contractAddress);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/RLPMock.sol": {
      "content": "pragma solidity 0.5.11;

pragma experimental ABIEncoderV2;

import "../../src/utils/RLPReader.sol";

contract RLPMock {

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant internal WORD_SIZE = 32;

    function decodeBytes32(bytes memory _data) public pure returns (bytes32) {
        return _data.toRlpItem().toBytes32();
    }

    function decodeAddress(bytes memory _data) public pure returns (address) {
        return _data.toRlpItem().toAddress();
    }
    
    function decodeBytes20(bytes memory _data) public pure returns (bytes20) {
        return bytes20(_data.toRlpItem().toAddress());
    }

    function decodeBytes(bytes memory _data) public pure returns (bytes memory) {
        return toBytes(_data.toRlpItem());
    }

    function decodeUint(bytes memory _data) public pure returns (uint) {
        return _data.toRlpItem().toUint();
    }

    function decodeInt(bytes memory _data) public pure returns (int) {
        return int(_data.toRlpItem().toUint());
    }

    function decodeString(bytes memory _data) public pure returns (string memory) {
        return string(toBytes(_data.toRlpItem()));
    }

    function decodeList(bytes memory _data) public pure returns (bytes[] memory) {

        RLPReader.RLPItem[] memory items = _data.toRlpItem().toList();

        bytes[] memory result =  new bytes[](items.length);
        for (uint i = 0; i < items.length; i++) {
            result[i] = toRlpBytes(items[i]);
        }
        return result;
    }

    function toBytes(RLPReader.RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "Item length must be > 0");

        (uint256 itemLen, uint256 offset) = RLPReader.decodeLengthAndOffset(item.memPtr);
        require(itemLen == item.len, "Decoded RLP length is invalid");
        uint len = itemLen - offset;
        bytes memory result = new bytes(len);

        uint destPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            destPtr := add(0x20, result)
        }

        copyUnsafe(item.memPtr + offset, destPtr, len);
        return result;
    }

    function copyUnsafe(uint src, uint dest, uint len) private pure {
        if (len == 0) return;
        uint remainingLength = len;

        // copy as many word sizes as possible
        for (uint i = WORD_SIZE; len >= i; i += WORD_SIZE) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
            remainingLength -= WORD_SIZE;
            require(remainingLength < len, "Remaining length not less than original length");
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - remainingLength) - 1;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toRlpBytes(RLPReader.RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint resultPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            resultPtr := add(0x20, result)
        }

        copyUnsafe(item.memPtr, resultPtr, item.len);
        return result;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/RLPMockSecurity.sol": {
      "content": "pragma solidity 0.5.11;

pragma experimental ABIEncoderV2;

import "../../src/utils/RLPReader.sol";

contract RLPMockSecurity {

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function decodeBytes32(bytes memory _data) public pure returns (bytes32) {
        return bytes32(_data.toRlpItem().toUint());
    }

    function decodeBytes20(bytes memory _data) public pure returns (bytes20) {
        return bytes20(_data.toRlpItem().toAddress());
    }

    function decodeUint(bytes memory _data) public pure returns (uint) {
        return _data.toRlpItem().toUint();
    }

    function decodeList(bytes memory _data) public pure returns (RLPReader.RLPItem[] memory) {
        return _data.toRlpItem().toList();
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/utils/SafeEthTransferMock.sol": {
      "content": "pragma solidity 0.5.11;

import "../../src/utils/SafeEthTransfer.sol";

contract SafeEthTransferMock {
    bool public transferResult;

    function transferRevertOnError(address payable receiver, uint256 amount, uint256 gasStipend)
        public
    {
        SafeEthTransfer.transferRevertOnError(receiver, amount, gasStipend);
    }

    function transferReturnResult(address payable receiver, uint256 amount, uint256 gasStipend)
        public
    {
        transferResult = SafeEthTransfer.transferReturnResult(receiver, amount, gasStipend);
    }

    /** helper function to pre-fund the contract to test */
    function setupInitialFundToTestTransfer() external payable {}
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/mocks/vaults/NonCompliantERC20.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// A 'NonCompliantERC20' token is one that uses an old version of the ERC20 standard,
// as described here https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
// Basically, this version does not return anything from `transfer` and `transferFrom`,
// whereas most modern implementions of ERC20 return a boolean to indicate success or failure.
contract NonCompliantERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    uint256 private totalSupply;

    constructor(uint256 _initialAmount) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _to, uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }

    function transferFrom(address _from, address _to, uint _value) public {
        uint256 _allowance = allowances[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowances[_from][msg.sender] = _allowance.sub(_value);
    }

    function approve(address _spender, uint _value) public {
        allowances[msg.sender][_spender] = _value;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/fee/FeeClaimOutputToPaymentTxCondition.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

import "../interfaces/ISpendingCondition.sol";
import "../utils/OutputId.sol";
import "../../framework/PlasmaFramework.sol";
import "../../transactions/FungibleTokenOutputModel.sol";
import "../../transactions/GenericTransaction.sol";
import "../../transactions/PaymentTransactionModel.sol";
import "../../transactions/eip712Libs/PaymentEip712Lib.sol";
import "../../utils/PosLib.sol";

contract FeeClaimOutputToPaymentTxCondition is ISpendingCondition {
    using PaymentEip712Lib for PaymentEip712Lib.Constants;
    using PosLib for PosLib.Position;

    uint256 public feeTxType;
    uint256 public feeClaimOutputType;
    uint256 public paymentTxType;
    PaymentEip712Lib.Constants internal eip712;

    constructor(
        PlasmaFramework _framework,
        uint256 _feeTxType,
        uint256 _feeClaimOutputType,
        uint256 _paymentTxType
    )
        public
    {
        eip712 = PaymentEip712Lib.initConstants(address(_framework));
        feeTxType = _feeTxType;
        feeClaimOutputType = _feeClaimOutputType;
        paymentTxType = _paymentTxType;
    }

    /**
     * @dev This implementation checks signature for spending fee claim output. It should be signed with the owner signature.
     *      The fee claim output that is spendable follows Fungible Token Output format.
     * @param feeTxBytes Encoded fee transaction
     * @param utxoPos Position of the fee utxo
     * @param paymentTxBytes Payment transaction (in bytes) that spends the fee claim output
     * @param inputIndex Input index of the payment tx that points to the fee claim output
     * @param signature Signature of the owner of fee claiming output
     */
    function verify(
        bytes calldata feeTxBytes,
        uint256 utxoPos,
        bytes calldata paymentTxBytes,
        uint16 inputIndex,
        bytes calldata signature
    )
        external
        view
        returns (bool)
    {
        PosLib.Position memory decodedUtxoPos = PosLib.decode(utxoPos);
        require(decodedUtxoPos.outputIndex == 0, "Fee claim output must be the first output of fee tx");

        GenericTransaction.Transaction memory feeTx = GenericTransaction.decode(feeTxBytes);
        FungibleTokenOutputModel.Output memory feeClaimOutput = FungibleTokenOutputModel.getOutput(feeTx, decodedUtxoPos.outputIndex);

        require(feeTx.txType == feeTxType, "Unexpected tx type for fee transaction");
        require(feeClaimOutput.outputType == feeClaimOutputType, "Unexpected output type for fee claim output");

        PaymentTransactionModel.Transaction memory paymentTx = PaymentTransactionModel.decode(paymentTxBytes);
        require(paymentTx.txType == paymentTxType, "Unexpected tx type for payment transaction");

        require(
            paymentTx.inputs[inputIndex] == bytes32(decodedUtxoPos.encode()),
            "Payment tx points to the incorrect output UTXO position of the fee claim output"
        );

        address owner = address(feeClaimOutput.outputGuard);
        address signer = ECDSA.recover(eip712.hashTx(paymentTx), signature);
        require(signer != address(0), "Failed to recover the signer from the signature");
        require(owner == signer, "Tx is not signed correctly");

        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/fee/FeeExitGame.sol": {
      "content": "pragma solidity 0.5.11;

/**
* It is an empty contract by design. We only want to be able to register the tx type to the framework.
* For simplicity, a fee claiming tx does not have the ability to exit directly.
* It should be first spend to a Payment tx and then exit the fund from Payment tx.
*/
contract FeeExitGame {
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/interfaces/ISpendingCondition.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @notice Interface of the spending condition
 * @dev For the interface design and discussion, see the following GH issue
 *      https://github.com/omisego/plasma-contracts/issues/214
 */
interface ISpendingCondition {

    /**
     * @notice Verifies the spending condition
     * @param inputTx Encoded input transaction, in bytes
     * @param utxoPos Position of the utxo
     * @param spendingTx Spending transaction, in bytes
     * @param inputIndex The input index of the spending tx that points to the output
     * @param witness The witness data of the spending condition
     */
    function verify(
        bytes calldata inputTx,
        uint256 utxoPos,
        bytes calldata spendingTx,
        uint16 inputIndex,
        bytes calldata witness
    ) external view returns (bool);
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/interfaces/IStateTransitionVerifier.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

interface IStateTransitionVerifier {

    /**
    * @notice Verifies state transition logic
    * @param txBytes The transaction that does the state transition to verify
    * @param inputTxs Input transaction to the transaction to verify
    * @param outputIndexOfInputTxs Output index of the input txs that the transaction input points to
    */
    function isCorrectStateTransition(
        bytes calldata txBytes,
        bytes[] calldata inputTxs,
        uint16[] calldata outputIndexOfInputTxs
    )
        external
        view
        returns (bool);
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/PaymentExitDataModel.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @notice Model library for PaymentExit
 */
library PaymentExitDataModel {
    uint8 constant public MAX_INPUT_NUM = 4;
    uint8 constant public MAX_OUTPUT_NUM = 4;

    /**
     * @dev Exit model for a standard exit
     * @param exitable Boolean that defines whether exit is possible. Used by the challenge game to flag the result.
     * @param utxoPos The UTXO position of the transaction's exiting output
     * @param outputId The output identifier, in OutputId format
     * @param exitTarget The address to which the exit withdraws funds
     * @param amount The amount of funds to withdraw with this exit
     * @param bondSize The size of the bond put up for this exit to start, and which is used to cover the cost of challenges
     */
    struct StandardExit {
        bool exitable;
        uint256 utxoPos;
        bytes32 outputId;
        address payable exitTarget;
        uint256 amount;
        uint256 bondSize;
    }

    /**
     * @dev Mapping of (exitId => StandardExit) that stores all standard exit data
     */
    struct StandardExitMap {
        mapping (uint160 => PaymentExitDataModel.StandardExit) exits;
    }

    /**
     * @dev The necessary data needed for processExit for in-flight exit inputs/outputs
     */
    struct WithdrawData {
        bytes32 outputId;
        address payable exitTarget;
        address token;
        uint256 amount;
        uint256 piggybackBondSize;
    }

    /**
     * @dev Exit model for an in-flight exit
     * @param isCanonical A boolean that defines whether the exit is canonical
     *                    A canonical exit withdraws the outputs while a non-canonical exit withdraws the  inputs
     * @param exitStartTimestamp Timestamp for the start of the exit
     * @param exitMap A bitmap that stores piggyback flags
     * @param position The position of the youngest input of the in-flight exit transaction
     * @param inputs Fixed-size array of data required to withdraw inputs (if undefined, the default value is empty)
     * @param outputs Fixed-size array of data required to withdraw outputs (if undefined, the default value is empty)
     * @param bondOwner Recipient of the bond, when the in-flight exit is processed
     * @param bondSize The size of the bond put up for this exit to start. Used to cover the cost of challenges.
     * @param oldestCompetitorPosition The position of the oldest competing transaction
     *                                 The exiting transaction is only canonical if all competing transactions are younger.
     */
    struct InFlightExit {
        // Canonicity is assumed at start, and can be challenged and set to `false` after start
        // Response to non-canonical challenge can set it back to `true`
        bool isCanonical;
        uint64 exitStartTimestamp;

        /**
         * exit map Stores piggybacks and finalized exits
         * right most 0 ~ MAX_INPUT bits is flagged when input is piggybacked
         * right most MAX_INPUT ~ MAX_INPUT + MAX_OUTPUT bits is flagged when output is piggybacked
         */
        uint256 exitMap;
        uint256 position;
        WithdrawData[MAX_INPUT_NUM] inputs;
        WithdrawData[MAX_OUTPUT_NUM] outputs;
        address payable bondOwner;
        uint256 bondSize;
        uint256 oldestCompetitorPosition;
    }

    /**
     * @dev Mapping of (exitId => InFlightExit) that stores all in-flight exit data
     */
    struct InFlightExitMap {
        mapping (uint160 => PaymentExitDataModel.InFlightExit) exits;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/PaymentExitGame.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./PaymentExitGameArgs.sol";
import "./routers/PaymentStandardExitRouter.sol";
import "./routers/PaymentInFlightExitRouter.sol";
import "../utils/ExitId.sol";
import "../registries/SpendingConditionRegistry.sol";
import "../../framework/interfaces/IExitProcessor.sol";
import "../../framework/PlasmaFramework.sol";
import "../../utils/OnlyFromAddress.sol";

/**
 * @notice The exit game contract implementation for Payment Transaction
 */
contract PaymentExitGame is IExitProcessor, OnlyFromAddress, PaymentStandardExitRouter, PaymentInFlightExitRouter {
    PlasmaFramework private plasmaFramework;

    /**
     * @dev use struct PaymentExitGameArgs to avoid stack too deep compilation error.
     */
    constructor(PaymentExitGameArgs.Args memory args)
        public
        PaymentStandardExitRouter(args)
        PaymentInFlightExitRouter(args)
    {
        plasmaFramework = args.framework;

        // makes sure that the spending condition has already renounced ownership
        require(args.spendingConditionRegistry.owner() == address(0), "Spending condition registry ownership needs to be renounced");
    }

    /**
     * @notice Callback processes exit function for the PlasmaFramework to call
     * @param exitId The exit ID
     * @param token Token (ERC20 address or address(0) for ETH) of the exiting output
     */
    function processExit(uint160 exitId, uint256, address token) external onlyFrom(address(plasmaFramework)) {
        if (ExitId.isStandardExit(exitId)) {
            PaymentStandardExitRouter.processStandardExit(exitId, token);
        } else {
            PaymentInFlightExitRouter.processInFlightExit(exitId, token);
        }
    }

    /**
     * @notice Helper function to compute the standard exit ID
     */
    function getStandardExitId(bool _isDeposit, bytes memory _txBytes, uint256 _utxoPos)
        public
        pure
        returns (uint160)
    {
        PosLib.Position memory utxoPos = PosLib.decode(_utxoPos);
        return ExitId.getStandardExitId(_isDeposit, _txBytes, utxoPos);
    }

    /**
     * @notice Helper function to compute the in-flight exit ID
     */
    function getInFlightExitId(bytes memory _txBytes)
        public
        pure
        returns (uint160)
    {
        return ExitId.getInFlightExitId(_txBytes);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/PaymentExitGameArgs.sol": {
      "content": "pragma solidity 0.5.11;

import "../registries/SpendingConditionRegistry.sol";
import "../interfaces/IStateTransitionVerifier.sol";
import "../../framework/PlasmaFramework.sol";

library PaymentExitGameArgs {
    /**
     * @param framework The Plasma framework
     * @param ethVaultId Vault id for EthVault
     * @param erc20VaultId Vault id for the Erc20Vault
     * @param spendingConditionRegistry the spendingConditionRegistry that can provide spending condition implementation by types
     * @param stateTransitionVerifier state transition verifier predicate contract that checks the transaction correctness
     * @param supportTxType the tx type of this exit game is using
     * @param safeGasStipend a gas amount limit when transferring Eth to protect from attack with draining gas
     */
    struct Args {
        PlasmaFramework framework;
        uint256 ethVaultId;
        uint256 erc20VaultId;
        SpendingConditionRegistry spendingConditionRegistry;
        IStateTransitionVerifier stateTransitionVerifier;
        uint256 supportTxType;
        uint256 safeGasStipend;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/PaymentInFlightExitModelUtils.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../utils/Bits.sol";
import "../../transactions/PaymentTransactionModel.sol";
import { PaymentExitDataModel as ExitModel } from "./PaymentExitDataModel.sol";

library PaymentInFlightExitModelUtils {
    using Bits for uint256;

    function isInputEmpty(ExitModel.InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        require(index < PaymentTransactionModel.MAX_INPUT_NUM(), "Invalid input index");
        return isEmptyWithdrawData(ife.inputs[index]);
    }

    function isOutputEmpty(ExitModel.InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        require(index < PaymentTransactionModel.MAX_OUTPUT_NUM(), "Invalid output index");
        return isEmptyWithdrawData(ife.outputs[index]);
    }

    function isInputPiggybacked(ExitModel.InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        require(index < PaymentTransactionModel.MAX_INPUT_NUM(), "Invalid input index");
        return ife.exitMap.bitSet(uint8(index));
    }

    function isOutputPiggybacked(ExitModel.InFlightExit memory ife, uint16 index)
        internal
        pure
        returns (bool)
    {
        require(index < PaymentTransactionModel.MAX_OUTPUT_NUM(), "Invalid output index");
        uint8 indexInExitMap = uint8(index + PaymentTransactionModel.MAX_INPUT_NUM());
        return ife.exitMap.bitSet(indexInExitMap);
    }

    function setInputPiggybacked(ExitModel.InFlightExit storage ife, uint16 index)
        internal
    {
        require(index < PaymentTransactionModel.MAX_INPUT_NUM(), "Invalid input index");
        ife.exitMap = ife.exitMap.setBit(uint8(index));
    }

    function clearInputPiggybacked(ExitModel.InFlightExit storage ife, uint16 index)
        internal
    {
        require(index < PaymentTransactionModel.MAX_INPUT_NUM(), "Invalid input index");
        ife.exitMap = ife.exitMap.clearBit(uint8(index));
    }

    function setOutputPiggybacked(ExitModel.InFlightExit storage ife, uint16 index)
        internal
    {
        require(index < PaymentTransactionModel.MAX_OUTPUT_NUM(), "Invalid output index");
        uint8 indexInExitMap = uint8(index + PaymentTransactionModel.MAX_INPUT_NUM());
        ife.exitMap = ife.exitMap.setBit(indexInExitMap);
    }

    function clearOutputPiggybacked(ExitModel.InFlightExit storage ife, uint16 index)
        internal
    {
        require(index < PaymentTransactionModel.MAX_OUTPUT_NUM(), "Invalid output index");
        uint8 indexInExitMap = uint8(index + PaymentTransactionModel.MAX_INPUT_NUM());
        ife.exitMap = ife.exitMap.clearBit(indexInExitMap);
    }

    function isInFirstPhase(ExitModel.InFlightExit memory ife, uint256 minExitPeriod)
        internal
        view
        returns (bool)
    {
        uint256 periodTime = minExitPeriod / 2;
        return ((block.timestamp - ife.exitStartTimestamp) / periodTime) < 1;
    }

    function isEmptyWithdrawData(ExitModel.WithdrawData memory data) private pure returns (bool) {
        return data.outputId == bytes32("") &&
                data.exitTarget == address(0) &&
                data.token == address(0) &&
                data.amount == 0 &&
                data.piggybackBondSize == 0;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/PaymentTransactionStateTransitionVerifier.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStateTransitionVerifier.sol";
import "../payment/PaymentExitDataModel.sol";
import "../../transactions/FungibleTokenOutputModel.sol";
import "../../transactions/PaymentTransactionModel.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
* @notice Verifies state transitions for payment transaction
* @dev For payment transaction to be valid, the state transition should check that the sum of the inputs is larger than the sum of the outputs
*/
contract PaymentTransactionStateTransitionVerifier {
    using SafeMath for uint256;

    /**
     * @dev For payment transaction to be valid, the state transition should check that the sum of the inputs is larger than the sum of the outputs
     */
    function isCorrectStateTransition(
        bytes calldata txBytes,
        bytes[] calldata inputTxs,
        uint16[] calldata outputIndexOfInputTxs
    )
        external
        pure
        returns (bool)
    {
        if (inputTxs.length != outputIndexOfInputTxs.length) {
            return false;
        }

        FungibleTokenOutputModel.Output[] memory inputs = new FungibleTokenOutputModel.Output[](inputTxs.length);
        for (uint i = 0; i < inputTxs.length; i++) {
            uint16 outputIndex = outputIndexOfInputTxs[i];
            FungibleTokenOutputModel.Output memory output = FungibleTokenOutputModel.getOutput(
                GenericTransaction.decode(inputTxs[i]),
                outputIndex
            );
            inputs[i] = output;
        }

        PaymentTransactionModel.Transaction memory transaction = PaymentTransactionModel.decode(txBytes);
        FungibleTokenOutputModel.Output[] memory outputs = new FungibleTokenOutputModel.Output[](transaction.outputs.length);
        for (uint i = 0; i < transaction.outputs.length; i++) {
            outputs[i] = FungibleTokenOutputModel.Output(
                    transaction.outputs[i].outputType,
                    transaction.outputs[i].outputGuard,
                    transaction.outputs[i].token,
                    transaction.outputs[i].amount
                );
        }

        return _isCorrectStateTransition(inputs, outputs);
    }

    function _isCorrectStateTransition(
        FungibleTokenOutputModel.Output[] memory inputs,
        FungibleTokenOutputModel.Output[] memory outputs
    )
        private
        pure
        returns (bool)
    {
        bool correctTransition = true;
        uint i = 0;
        while (correctTransition && i < outputs.length) {
            address token = outputs[i].token;
            FungibleTokenOutputModel.Output[] memory inputsForToken = filterWithToken(inputs, token);
            FungibleTokenOutputModel.Output[] memory outputsForToken = filterWithToken(outputs, token);

            correctTransition = isCorrectSpend(inputsForToken, outputsForToken);
            i += 1;
        }
        return correctTransition;
    }

    function filterWithToken(
        FungibleTokenOutputModel.Output[] memory outputs,
        address token
    )
        private
        pure
        returns (FungibleTokenOutputModel.Output[] memory)
    {
        // Required for calculating the size of the filtered array
        uint256 arraySize = 0;
        for (uint i = 0; i < outputs.length; ++i) {
            if (outputs[i].token == token) {
                arraySize += 1;
            }
        }

        FungibleTokenOutputModel.Output[] memory outputsWithToken = new FungibleTokenOutputModel.Output[](arraySize);
        uint j = 0;
        for (uint i = 0; i < outputs.length; ++i) {
            if (outputs[i].token == token) {
                outputsWithToken[j] = outputs[i];
                j += 1;
            }
        }

        return outputsWithToken;
    }

    function isCorrectSpend(
        FungibleTokenOutputModel.Output[] memory inputs,
        FungibleTokenOutputModel.Output[] memory outputs
    )
        internal
        pure
        returns (bool)
    {
        uint256 amountIn = sumAmounts(inputs);
        uint256 amountOut = sumAmounts(outputs);
        return amountIn >= amountOut;
    }

    function sumAmounts(FungibleTokenOutputModel.Output[] memory outputs) private pure returns (uint256) {
        uint256 amount = 0;
        for (uint i = 0; i < outputs.length; i++) {
            amount = amount.add(outputs[i].amount);
        }
        return amount;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentChallengeIFEInputSpent.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../interfaces/ISpendingCondition.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/ExitId.sol";
import "../../utils/OutputId.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../../utils/Merkle.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../utils/PosLib.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../transactions/GenericTransaction.sol";

library PaymentChallengeIFEInputSpent {
    using PosLib for PosLib.Position;
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    struct Controller {
        PlasmaFramework framework;
        SpendingConditionRegistry spendingConditionRegistry;
        uint256 safeGasStipend;
    }

    event InFlightExitInputBlocked(
        address indexed challenger,
        bytes32 indexed txHash,
        uint16 inputIndex
    );

    /**
     * @dev Data to be passed around helper functions
     */
    struct ChallengeIFEData {
        Controller controller;
        PaymentInFlightExitRouterArgs.ChallengeInputSpentArgs args;
        PaymentExitDataModel.InFlightExit ife;
    }

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentChallengeIFEInputSpent
     */
    function buildController(
        PlasmaFramework framework,
        SpendingConditionRegistry spendingConditionRegistry,
        uint256 safeGasStipend
    )
        public
        pure
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            spendingConditionRegistry: spendingConditionRegistry,
            safeGasStipend: safeGasStipend
        });
    }

    /**
     * @notice Main logic implementation for 'challengeInFlightExitInputSpent'
     * @dev emits InFlightExitInputBlocked event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of 'challengeInFlightExitInputSpent' function from client
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.ChallengeInputSpentArgs memory args
    )
        public
    {
        require(args.senderData == keccak256(abi.encodePacked(msg.sender)), "Incorrect senderData");

        uint160 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];

        require(ife.exitStartTimestamp != 0, "In-flight exit does not exist");
        require(ife.isInputPiggybacked(args.inFlightTxInputIndex), "The indexed input has not been piggybacked");

        require(
            keccak256(args.inFlightTx) != keccak256(args.challengingTx),
            "The challenging transaction is the same as the in-flight transaction"
        );

        ChallengeIFEData memory data = ChallengeIFEData({
            controller: self,
            args: args,
            ife: inFlightExitMap.exits[exitId]
        });

        verifySpentInputEqualsIFEInput(data);
        verifyChallengingTransactionProtocolFinalized(data);
        verifySpendingCondition(data);

        // Remove the input from the piggyback map
        ife.clearInputPiggybacked(args.inFlightTxInputIndex);

        uint256 piggybackBondSize = ife.inputs[args.inFlightTxInputIndex].piggybackBondSize;
        SafeEthTransfer.transferRevertOnError(msg.sender, piggybackBondSize, self.safeGasStipend);

        emit InFlightExitInputBlocked(msg.sender, keccak256(args.inFlightTx), args.inFlightTxInputIndex);
    }

    function verifySpentInputEqualsIFEInput(ChallengeIFEData memory data) private view {
        bytes32 ifeInputOutputId = data.ife.inputs[data.args.inFlightTxInputIndex].outputId;

        PosLib.Position memory utxoPos = PosLib.decode(data.args.inputUtxoPos);
        bytes32 challengingTxInputOutputId = data.controller.framework.isDeposit(utxoPos.blockNum)
                ? OutputId.computeDepositOutputId(data.args.inputTx, utxoPos.outputIndex, utxoPos.encode())
                : OutputId.computeNormalOutputId(data.args.inputTx, utxoPos.outputIndex);

        require(ifeInputOutputId == challengingTxInputOutputId, "Spent input is not the same as piggybacked input");
    }

    function verifyChallengingTransactionProtocolFinalized(ChallengeIFEData memory data)
        private
        view
    {
        bool isProtocolFinalized = MoreVpFinalization.isProtocolFinalized(
            data.controller.framework,
            data.args.challengingTx
        );

        // MoreVP protocol finalization would only return false only when tx does not exists.
        // Should fail already in early stages (eg. decode)
        assert(isProtocolFinalized);
    }

    function verifySpendingCondition(ChallengeIFEData memory data) private view {
        GenericTransaction.Transaction memory challengingTx = GenericTransaction.decode(data.args.challengingTx);

        GenericTransaction.Transaction memory inputTx = GenericTransaction.decode(data.args.inputTx);
        PosLib.Position memory utxoPos = PosLib.decode(data.args.inputUtxoPos);
        GenericTransaction.Output memory output = GenericTransaction.getOutput(inputTx, utxoPos.outputIndex);

        ISpendingCondition condition = data.controller.spendingConditionRegistry.spendingConditions(
            output.outputType, challengingTx.txType
        );
        require(address(condition) != address(0), "Spending condition contract not found");

        bool isSpent = condition.verify(
            data.args.inputTx,
            data.args.inputUtxoPos,
            data.args.challengingTx,
            data.args.challengingTxInputIndex,
            data.args.challengingTxWitness
        );
        require(isSpent, "Spending condition failed");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentChallengeIFENotCanonical.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../interfaces/ISpendingCondition.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/ExitId.sol";
import "../../utils/OutputId.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../../utils/PosLib.sol";
import "../../../utils/Merkle.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../transactions/GenericTransaction.sol";

library PaymentChallengeIFENotCanonical {
    using PosLib for PosLib.Position;
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    /**
     * @dev supportedTxType Allows reuse of code in different Payment Tx versions
     */
    struct Controller {
        PlasmaFramework framework;
        SpendingConditionRegistry spendingConditionRegistry;
        uint256 supportedTxType;
    }

    event InFlightExitChallenged(
        address indexed challenger,
        bytes32 indexed txHash,
        uint256 challengeTxPosition
    );

    event InFlightExitChallengeResponded(
        address indexed challenger,
        bytes32 indexed txHash,
        uint256 challengeTxPosition
    );

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentChallengeIFENotCanonical
     */
    function buildController(
        PlasmaFramework framework,
        SpendingConditionRegistry spendingConditionRegistry,
        uint256 supportedTxType
    )
        public
        pure
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            spendingConditionRegistry: spendingConditionRegistry,
            supportedTxType: supportedTxType
        });
    }

    /**
     * @notice Main logic implementation for 'challengeInFlightExitNotCanonical'
     * @dev emits InFlightExitChallenged event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of 'challengeInFlightExitNotCanonical' function from client
     */
    function challenge(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.ChallengeCanonicityArgs memory args
    )
        public
    {
        uint160 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];
        require(args.inFlightTxInputIndex < ife.inputs.length, "Input index out of bounds");
        require(ife.exitStartTimestamp != 0, "In-flight exit does not exist");

        require(ife.isInFirstPhase(self.framework.minExitPeriod()),
                "Canonicity challenge phase for this exit has ended");

        require(
            keccak256(args.inFlightTx) != keccak256(args.competingTx),
            "The competitor transaction is the same as transaction in-flight"
        );

        PosLib.Position memory inputUtxoPos = PosLib.decode(args.inputUtxoPos);

        bytes32 outputId;
        if (self.framework.isDeposit(inputUtxoPos.blockNum)) {
            outputId = OutputId.computeDepositOutputId(args.inputTx, inputUtxoPos.outputIndex, args.inputUtxoPos);
        } else {
            outputId = OutputId.computeNormalOutputId(args.inputTx, inputUtxoPos.outputIndex);
        }
        require(outputId == ife.inputs[args.inFlightTxInputIndex].outputId,
                "Provided inputs data does not point to the same outputId from the in-flight exit");

        GenericTransaction.Output memory output = GenericTransaction.getOutput(
            GenericTransaction.decode(args.inputTx),
            inputUtxoPos.outputIndex
        );

        ISpendingCondition condition = self.spendingConditionRegistry.spendingConditions(
            output.outputType, self.supportedTxType
        );
        require(address(condition) != address(0), "Spending condition contract not found");

        bool isSpentByCompetingTx = condition.verify(
            args.inputTx,
            args.inputUtxoPos,
            args.competingTx,
            args.competingTxInputIndex,
            args.competingTxWitness
        );
        require(isSpentByCompetingTx, "Competing input spending condition is not met");

        // Determine the position of the competing transaction
        uint256 competitorPosition = verifyCompetingTxFinalizedInThePosition(self, args);

        require(
            ife.oldestCompetitorPosition == 0 || ife.oldestCompetitorPosition > competitorPosition,
            "Competing transaction is not older than already known competitor"
        );

        ife.oldestCompetitorPosition = competitorPosition;
        ife.bondOwner = msg.sender;

        // Set a flag so that only the inputs are exitable, unless a response is received.
        ife.isCanonical = false;

        emit InFlightExitChallenged(msg.sender, keccak256(args.inFlightTx), competitorPosition);
    }

    /**
     * @notice Main logic implementation for 'respondToNonCanonicalChallenge'
     * @dev emits InFlightExitChallengeResponded event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param inFlightTx The in-flight tx, in RLP-encoded bytes
     * @param inFlightTxPos The UTXO position of the in-flight exit. Should hardcode 0 for the outputIndex.
     * @param inFlightTxInclusionProof Inclusion proof for the in-flight tx
     */
    function respond(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        bytes memory inFlightTx,
        uint256 inFlightTxPos,
        bytes memory inFlightTxInclusionProof
    )
        public
    {
        uint160 exitId = ExitId.getInFlightExitId(inFlightTx);
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];
        require(ife.exitStartTimestamp != 0, "In-flight exit does not exist");
        require(inFlightTxPos > 0, "In-flight transaction position must not be 0");

        require(
            ife.oldestCompetitorPosition > inFlightTxPos,
            "In-flight transaction must be older than competitors to respond to non-canonical challenge");

        PosLib.Position memory txPos = PosLib.decode(inFlightTxPos);
        (bytes32 root, ) = self.framework.blocks(txPos.blockNum);
        require(root != bytes32(""), "Failed to get the block root hash of the tx position");

        verifyPositionOfTransactionIncludedInBlock(
            inFlightTx, txPos, root, inFlightTxInclusionProof
        );

        ife.oldestCompetitorPosition = inFlightTxPos;
        ife.isCanonical = true;
        ife.bondOwner = msg.sender;

        emit InFlightExitChallengeResponded(msg.sender, keccak256(inFlightTx), inFlightTxPos);
    }

    function verifyPositionOfTransactionIncludedInBlock(
        bytes memory txbytes,
        PosLib.Position memory txPos,
        bytes32 root,
        bytes memory inclusionProof
    )
        private
        pure
    {
        require(txPos.outputIndex == 0, "Output index of txPos has to be 0");
        require(
            Merkle.checkMembership(txbytes, txPos.txIndex, root, inclusionProof),
            "Transaction is not included in block of Plasma chain"
        );
    }

    function verifyCompetingTxFinalizedInThePosition(
        Controller memory self,
        PaymentInFlightExitRouterArgs.ChallengeCanonicityArgs memory args
    )
        private
        view
        returns (uint256)
    {
        // default to infinite low priority position
        uint256 competitorPosition = ~uint256(0);

        if (args.competingTxPos == 0) {
            bool isProtocolFinalized = MoreVpFinalization.isProtocolFinalized(
                self.framework,
                args.competingTx
            );
            // MoreVP protocol finalization would only return false only when tx does not exists.
            // Should fail already in early stages (eg. decode)
            assert(isProtocolFinalized);
        } else {
            PosLib.Position memory competingTxPos = PosLib.decode(args.competingTxPos);
            require(competingTxPos.outputIndex == 0, "OutputIndex of competingTxPos should be 0");

            bool isStandardFinalized = MoreVpFinalization.isStandardFinalized(
                self.framework,
                args.competingTx,
                competingTxPos,
                args.competingTxInclusionProof
            );
            require(isStandardFinalized, "Competing tx is not standard finalized with the given tx position");
            competitorPosition = args.competingTxPos;
        }
        return competitorPosition;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentChallengeIFEOutputSpent.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../interfaces/ISpendingCondition.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/ExitId.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../../utils/Merkle.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../utils/PosLib.sol";
import "../../../transactions/GenericTransaction.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../transactions/PaymentTransactionModel.sol";

library PaymentChallengeIFEOutputSpent {
    using PosLib for PosLib.Position;
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    struct Controller {
        PlasmaFramework framework;
        SpendingConditionRegistry spendingConditionRegistry;
        uint256 safeGasStipend;
    }

    event InFlightExitOutputBlocked(
        address indexed challenger,
        bytes32 indexed txHash,
        uint16 outputIndex
    );

    /**
     * @notice Main logic implementation for 'challengeInFlightExitOutputSpent'
     * @dev emits InFlightExitOutputBlocked event on success
     * @param controller The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of 'challengeInFlightExitOutputSpent' function from client
     */
    function run(
        Controller memory controller,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.ChallengeOutputSpent memory args
    )
        public
    {
        require(args.senderData == keccak256(abi.encodePacked(msg.sender)), "Incorrect senderData");

        uint160 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[exitId];
        require(ife.exitStartTimestamp != 0, "In-flight exit does not exist");

        PosLib.Position memory utxoPos = PosLib.decode(args.outputUtxoPos);
        uint16 outputIndex = utxoPos.outputIndex;
        require(
            ife.isOutputPiggybacked(outputIndex),
            "Output is not piggybacked"
        );

        verifyInFlightTransactionStandardFinalized(controller, args);
        verifyChallengingTransactionProtocolFinalized(controller, args);
        verifyChallengingTransactionSpendsOutput(controller, args);

        ife.clearOutputPiggybacked(outputIndex);

        uint256 piggybackBondSize = ife.outputs[outputIndex].piggybackBondSize;
        SafeEthTransfer.transferRevertOnError(msg.sender, piggybackBondSize, controller.safeGasStipend);

        emit InFlightExitOutputBlocked(msg.sender, keccak256(args.inFlightTx), outputIndex);
    }

    function verifyInFlightTransactionStandardFinalized(
        Controller memory controller,
        PaymentInFlightExitRouterArgs.ChallengeOutputSpent memory args
    )
        private
        view
    {
        PosLib.Position memory utxoPos = PosLib.decode(args.outputUtxoPos);
        bool isStandardFinalized = MoreVpFinalization.isStandardFinalized(
            controller.framework,
            args.inFlightTx,
            utxoPos.toStrictTxPos(),
            args.inFlightTxInclusionProof
        );

        require(isStandardFinalized, "In-flight transaction must be standard finalized (included in Plasma) to be able to spend");
    }

    function verifyChallengingTransactionProtocolFinalized(
        Controller memory controller,
        PaymentInFlightExitRouterArgs.ChallengeOutputSpent memory args
    )
        private
        view
    {
        bool isProtocolFinalized = MoreVpFinalization.isProtocolFinalized(
            controller.framework,
            args.challengingTx
        );

        // MoreVP protocol finalization would only return false only when tx does not exists.
        // Should fail already in early stages (eg. decode)
        assert(isProtocolFinalized);
    }

    function verifyChallengingTransactionSpendsOutput(
        Controller memory controller,
        PaymentInFlightExitRouterArgs.ChallengeOutputSpent memory args
    )
        private
        view
    {
        PosLib.Position memory utxoPos = PosLib.decode(args.outputUtxoPos);
        GenericTransaction.Transaction memory challengingTx = GenericTransaction.decode(args.challengingTx);

        GenericTransaction.Transaction memory ifeTx = GenericTransaction.decode(args.inFlightTx);
        GenericTransaction.Output memory ifeTxOutput = GenericTransaction.getOutput(ifeTx, utxoPos.outputIndex);

        ISpendingCondition condition = controller.spendingConditionRegistry.spendingConditions(
            ifeTxOutput.outputType,
            challengingTx.txType
        );
        require(address(condition) != address(0), "Spending condition contract not found");

        bool isSpentBySpendingTx = condition.verify(
            args.inFlightTx,
            utxoPos.encode(),
            args.challengingTx,
            args.challengingTxInputIndex,
            args.challengingTxWitness
        );

        require(isSpentBySpendingTx, "Challenging transaction does not spend the output");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentChallengeStandardExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../routers/PaymentStandardExitRouterArgs.sol";
import "../../interfaces/ISpendingCondition.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../utils/OutputId.sol";
import "../../../vaults/EthVault.sol";
import "../../../vaults/Erc20Vault.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/Protocol.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../utils/PosLib.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../transactions/GenericTransaction.sol";

library PaymentChallengeStandardExit {
    using PosLib for PosLib.Position;
    using PaymentTransactionModel for PaymentTransactionModel.Transaction;

    struct Controller {
        PlasmaFramework framework;
        SpendingConditionRegistry spendingConditionRegistry;
        uint256 safeGasStipend;
    }

    event ExitChallenged(
        uint256 indexed utxoPos
    );

    /**
     * @dev Data to be passed around helper functions
     */
    struct ChallengeStandardExitData {
        Controller controller;
        PaymentStandardExitRouterArgs.ChallengeStandardExitArgs args;
        PaymentExitDataModel.StandardExit exitData;
        uint256 challengeTxType;
    }

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentChallengeStandardExit
     */
    function buildController(
        PlasmaFramework framework,
        SpendingConditionRegistry spendingConditionRegistry,
        uint256 safeGasStipend
    )
        public
        pure
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            spendingConditionRegistry: spendingConditionRegistry,
            safeGasStipend: safeGasStipend
        });
    }

    /**
     * @notice Main logic function to challenge standard exit
     * @dev emits ExitChallenged event on success
     * @param self The controller struct
     * @param exitMap The storage of all standard exit data
     * @param args Arguments of challenge standard exit function from client
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.StandardExitMap storage exitMap,
        PaymentStandardExitRouterArgs.ChallengeStandardExitArgs memory args
    )
        public
    {
        require(args.senderData == keccak256(abi.encodePacked(msg.sender)), "Incorrect senderData");

        GenericTransaction.Transaction memory challengeTx = GenericTransaction.decode(args.challengeTx);

        ChallengeStandardExitData memory data = ChallengeStandardExitData({
            controller: self,
            args: args,
            exitData: exitMap.exits[args.exitId],
            challengeTxType: challengeTx.txType
        });
        verifyChallengeExitExists(data);
        verifyChallengeTxProtocolFinalized(data);
        verifySpendingCondition(data);

        exitMap.exits[args.exitId].exitable = false;

        SafeEthTransfer.transferRevertOnError(msg.sender, data.exitData.bondSize, self.safeGasStipend);

        emit ExitChallenged(data.exitData.utxoPos);
    }

    function verifyChallengeExitExists(ChallengeStandardExitData memory data) private pure {
        require(data.exitData.exitable == true, "The exit does not exist");
    }

    function verifyChallengeTxProtocolFinalized(ChallengeStandardExitData memory data) private view {
        bool isProtocolFinalized = MoreVpFinalization.isProtocolFinalized(data.controller.framework, data.args.challengeTx);
        // MoreVP protocol finalization would only return false only when tx does not exists.
        // Should fail already in early stages (eg. decode)
        assert(isProtocolFinalized);
    }

    function verifySpendingCondition(ChallengeStandardExitData memory data) private view {
        PaymentStandardExitRouterArgs.ChallengeStandardExitArgs memory args = data.args;

        PosLib.Position memory utxoPos = PosLib.decode(data.exitData.utxoPos);
        FungibleTokenOutputModel.Output memory output = PaymentTransactionModel
            .decode(args.exitingTx)
            .getOutput(utxoPos.outputIndex);

        ISpendingCondition condition = data.controller.spendingConditionRegistry.spendingConditions(
            output.outputType, data.challengeTxType
        );
        require(address(condition) != address(0), "Spending condition contract not found");

        bytes32 outputId = data.controller.framework.isDeposit(utxoPos.blockNum)
                ? OutputId.computeDepositOutputId(args.exitingTx, utxoPos.outputIndex, utxoPos.encode())
                : OutputId.computeNormalOutputId(args.exitingTx, utxoPos.outputIndex);
        require(outputId == data.exitData.outputId, "Invalid exiting tx causing outputId mismatch");

        bool isSpentByChallengeTx = condition.verify(
            args.exitingTx,
            utxoPos.encode(),
            args.challengeTx,
            args.inputIndex,
            args.witness
        );
        require(isSpentByChallengeTx, "Spending condition failed");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentDeleteInFlightExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../transactions/PaymentTransactionModel.sol";

library PaymentDeleteInFlightExit {
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    struct Controller {
        uint256 minExitPeriod;
        uint256 safeGasStipend;
    }

    event InFlightExitDeleted(
        uint160 indexed exitId
    );

    /**
     * @notice Main logic function to delete the non piggybacked in-flight exit
     * @param exitId The exitId of the standard exit
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage exitMap,
        uint160 exitId
    )
        public
    {
        PaymentExitDataModel.InFlightExit memory ife = exitMap.exits[exitId];
        require(ife.exitStartTimestamp != 0, "In-flight exit does not exist");
        require(!ife.isInFirstPhase(self.minExitPeriod), "Cannot delete in-flight exit still in first phase");
        require(!isPiggybacked(ife), "The in-flight exit is already piggybacked");

        delete exitMap.exits[exitId];
        SafeEthTransfer.transferRevertOnError(ife.bondOwner, ife.bondSize, self.safeGasStipend);
        emit InFlightExitDeleted(exitId);
    }

    function isPiggybacked(ExitModel.InFlightExit memory ife)
        private
        pure
        returns (bool)
    {
        for (uint16 i = 0; i < PaymentTransactionModel.MAX_INPUT_NUM(); i++) {
            if (ife.isInputPiggybacked(i)) {
                return true;
            }
        }

        for (uint16 i = 0; i < PaymentTransactionModel.MAX_OUTPUT_NUM(); i++) {
            if (ife.isOutputPiggybacked(i)) {
                return true;
            }
        }

        return false;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentPiggybackInFlightExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../utils/ExitableTimestamp.sol";
import "../../utils/ExitId.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../utils/PosLib.sol";

library PaymentPiggybackInFlightExit {
    using PosLib for PosLib.Position;
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    struct Controller {
        PlasmaFramework framework;
        ExitableTimestamp.Calculator exitableTimestampCalculator;
        IExitProcessor exitProcessor;
        uint256 minExitPeriod;
        uint256 ethVaultId;
        uint256 erc20VaultId;
    }

    event InFlightExitInputPiggybacked(
        address indexed exitTarget,
        bytes32 indexed txHash,
        uint16 inputIndex
    );

    event InFlightExitOutputPiggybacked(
        address indexed exitTarget,
        bytes32 indexed txHash,
        uint16 outputIndex
    );

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentPiggybackInFlightExit
     */
    function buildController(
        PlasmaFramework framework,
        IExitProcessor exitProcessor,
        uint256 ethVaultId,
        uint256 erc20VaultId
    )
        public
        view
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            exitableTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            exitProcessor: exitProcessor,
            minExitPeriod: framework.minExitPeriod(),
            ethVaultId: ethVaultId,
            erc20VaultId: erc20VaultId
        });
    }

    /**
     * @notice The main controller logic for 'piggybackInFlightExitOnInput'
     * @dev emits InFlightExitInputPiggybacked event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of 'piggybackInFlightExitOnInput' function from client
     */
    function piggybackInput(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnInputArgs memory args
    )
        public
    {
        uint160 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage exit = inFlightExitMap.exits[exitId];

        require(exit.exitStartTimestamp != 0, "No in-flight exit to piggyback on");
        require(exit.isInFirstPhase(self.minExitPeriod), "Piggyback is possible only in the first phase of the exit period");

        require(!exit.isInputEmpty(args.inputIndex), "Indexed input is empty");
        require(!exit.isInputPiggybacked(args.inputIndex), "Indexed input already piggybacked");

        PaymentExitDataModel.WithdrawData storage withdrawData = exit.inputs[args.inputIndex];

        require(withdrawData.exitTarget == msg.sender, "Can be called only by the exit target");
        withdrawData.piggybackBondSize = msg.value;

        if (isFirstPiggybackOfTheToken(exit, withdrawData.token)) {
            enqueue(self, withdrawData.token, PosLib.decode(exit.position), exitId);
        }

        exit.setInputPiggybacked(args.inputIndex);

        emit InFlightExitInputPiggybacked(msg.sender, keccak256(args.inFlightTx), args.inputIndex);
    }

    /**
     * @notice The main controller logic for 'piggybackInFlightExitOnOutput'
     * @dev emits InFlightExitOutputPiggybacked event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of 'piggybackInFlightExitOnOutput' function from client
     */
    function piggybackOutput(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnOutputArgs memory args
    )
        public
    {
        uint160 exitId = ExitId.getInFlightExitId(args.inFlightTx);
        PaymentExitDataModel.InFlightExit storage exit = inFlightExitMap.exits[exitId];

        require(exit.exitStartTimestamp != 0, "No in-flight exit to piggyback on");
        require(exit.isInFirstPhase(self.minExitPeriod), "Piggyback is possible only in the first phase of the exit period");

        require(!exit.isOutputEmpty(args.outputIndex), "Indexed output is empty");
        require(!exit.isOutputPiggybacked(args.outputIndex), "Indexed output already piggybacked");

        PaymentExitDataModel.WithdrawData storage withdrawData = exit.outputs[args.outputIndex];

        require(withdrawData.exitTarget == msg.sender, "Can be called only by the exit target");
        withdrawData.piggybackBondSize = msg.value;

        if (isFirstPiggybackOfTheToken(exit, withdrawData.token)) {
            enqueue(self, withdrawData.token, PosLib.decode(exit.position), exitId);
        }

        exit.setOutputPiggybacked(args.outputIndex);

        emit InFlightExitOutputPiggybacked(msg.sender, keccak256(args.inFlightTx), args.outputIndex);
    }

    function enqueue(
        Controller memory controller,
        address token,
        PosLib.Position memory utxoPos,
        uint160 exitId
    )
        private
    {
        (, uint256 blockTimestamp) = controller.framework.blocks(utxoPos.blockNum);
        require(blockTimestamp != 0, "There is no block for the exit position to enqueue");

        uint64 exitableAt = controller.exitableTimestampCalculator.calculateTxExitableTimestamp(now, blockTimestamp);

        uint256 vaultId;
        if (token == address(0)) {
            vaultId = controller.ethVaultId;
        } else {
            vaultId = controller.erc20VaultId;
        }

        controller.framework.enqueue(vaultId, token, exitableAt, utxoPos.toStrictTxPos(), exitId, controller.exitProcessor);
    }

    function isFirstPiggybackOfTheToken(ExitModel.InFlightExit memory ife, address token)
        private
        pure
        returns (bool)
    {
        for (uint i = 0; i < PaymentTransactionModel.MAX_INPUT_NUM(); i++) {
            if (ife.isInputPiggybacked(uint16(i)) && ife.inputs[i].token == token) {
                return false;
            }
        }

        for (uint i = 0; i < PaymentTransactionModel.MAX_OUTPUT_NUM(); i++) {
            if (ife.isOutputPiggybacked(uint16(i)) && ife.outputs[i].token == token) {
                return false;
            }
        }

        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentProcessInFlightExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../vaults/EthVault.sol";
import "../../../vaults/Erc20Vault.sol";

library PaymentProcessInFlightExit {
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;

    struct Controller {
        PlasmaFramework framework;
        EthVault ethVault;
        Erc20Vault erc20Vault;
        uint256 safeGasStipend;
    }

    event InFlightExitOmitted(
        uint160 indexed exitId,
        address token
    );

    event InFlightExitOutputWithdrawn(
        uint160 indexed exitId,
        uint16 outputIndex
    );

    event InFlightExitInputWithdrawn(
        uint160 indexed exitId,
        uint16 inputIndex
    );

    event InFlightBondReturnFailed(
        address indexed receiver,
        uint256 amount
    );

    /**
     * @notice Main logic function to process in-flight exit
     * @dev emits InFlightExitOmitted event if the exit is omitted
     * @dev emits InFlightBondReturnFailed event if failed to pay out bond. Would continue to process the exit.
     * @dev emits InFlightExitInputWithdrawn event if the input of IFE is withdrawn successfully
     * @dev emits InFlightExitOutputWithdrawn event if the output of IFE is withdrawn successfully
     * @param self The controller struct
     * @param exitMap The storage of all in-flight exit data
     * @param exitId The exitId of the in-flight exit
     * @param token The ERC20 token address of the exit; uses address(0) to represent ETH
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage exitMap,
        uint160 exitId,
        address token
    )
        public
    {
        PaymentExitDataModel.InFlightExit storage exit = exitMap.exits[exitId];

        if (exit.exitStartTimestamp == 0) {
            emit InFlightExitOmitted(exitId, token);
            return;
        }

        /* To prevent a double spend, it is needed to know if an output can be exited.
         * An output can not be exited if:
         * - it is finalized by a standard exit
         * - it is finalized by an in-flight exit as input of a non-canonical transaction
         * - it is blocked from exiting, because it is an input of a canonical transaction
         *   that exited from one of it's outputs
         * - it is finalized by an in-flight exit as an output of a canonical transaction
         * - it is an output of a transaction for which at least one of its inputs is already finalized
         *
         * Hence, Plasma Framework stores each output with an exit id that finalized it.
         * When transaction is marked as canonical but any of it's input was finalized by
         * other exit, it is not allowed to exit from the transaction's outputs.
         * In that case exit from an unspent input is possible.
         * When all inputs of a transaction that is marked as canonical are either not finalized or finalized
         * by the same exit (which means they were marked as finalized when processing the same exit for a different token),
         * only exit from outputs is possible.
         *
         * See: https://github.com/omisego/plasma-contracts/issues/102#issuecomment-495809967 for more details
         */
        if (!exit.isCanonical || isAnyInputFinalizedByOtherExit(self.framework, exit, exitId)) {
            for (uint16 i = 0; i < exit.inputs.length; i++) {
                PaymentExitDataModel.WithdrawData memory withdrawal = exit.inputs[i];

                if (shouldWithdrawInput(self, exit, withdrawal, token, i)) {
                    withdrawFromVault(self, withdrawal);
                    emit InFlightExitInputWithdrawn(exitId, i);
                }
            }

            flagOutputsWhenNonCanonical(self.framework, exit, token, exitId);
        } else {
            for (uint16 i = 0; i < exit.outputs.length; i++) {
                PaymentExitDataModel.WithdrawData memory withdrawal = exit.outputs[i];

                if (shouldWithdrawOutput(self, exit, withdrawal, token, i)) {
                    withdrawFromVault(self, withdrawal);
                    emit InFlightExitOutputWithdrawn(exitId, i);
                }
            }

            flagOutputsWhenCanonical(self.framework, exit, token, exitId);
        }

        returnInputPiggybackBonds(self, exit, token);
        returnOutputPiggybackBonds(self, exit, token);

        clearPiggybackInputFlag(exit, token);
        clearPiggybackOutputFlag(exit, token);

        if (allPiggybacksCleared(exit)) {
            bool success = SafeEthTransfer.transferReturnResult(
                exit.bondOwner, exit.bondSize, self.safeGasStipend
            );

            // we do not want to block a queue if bond return is unsuccessful
            if (!success) {
                emit InFlightBondReturnFailed(exit.bondOwner, exit.bondSize);
            }
            delete exitMap.exits[exitId];
        }
    }

    function isAnyInputFinalizedByOtherExit(
        PlasmaFramework framework,
        PaymentExitDataModel.InFlightExit memory exit,
        uint160 exitId
    )
        private
        view
        returns (bool)
    {
        uint256 nonEmptyInputIndex;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (!exit.isInputEmpty(i)) {
                nonEmptyInputIndex++;
            }
        }
        bytes32[] memory outputIdsOfInputs = new bytes32[](nonEmptyInputIndex);
        nonEmptyInputIndex = 0;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (!exit.isInputEmpty(i)) {
                outputIdsOfInputs[nonEmptyInputIndex] = exit.inputs[i].outputId;
                nonEmptyInputIndex++;
            }
        }
        return framework.isAnyInputFinalizedByOtherExit(outputIdsOfInputs, exitId);
    }

    function shouldWithdrawInput(
        Controller memory controller,
        PaymentExitDataModel.InFlightExit memory exit,
        PaymentExitDataModel.WithdrawData memory withdrawal,
        address token,
        uint16 index
    )
        private
        view
        returns (bool)
    {
        return withdrawal.token == token &&
                exit.isInputPiggybacked(index) &&
                !controller.framework.isOutputFinalized(withdrawal.outputId);
    }

    function shouldWithdrawOutput(
        Controller memory controller,
        PaymentExitDataModel.InFlightExit memory exit,
        PaymentExitDataModel.WithdrawData memory withdrawal,
        address token,
        uint16 index
    )
        private
        view
        returns (bool)
    {
        return withdrawal.token == token &&
                exit.isOutputPiggybacked(index) &&
                !controller.framework.isOutputFinalized(withdrawal.outputId);
    }

    function withdrawFromVault(
        Controller memory self,
        PaymentExitDataModel.WithdrawData memory withdrawal
    )
        private
    {
        if (withdrawal.token == address(0)) {
            self.ethVault.withdraw(withdrawal.exitTarget, withdrawal.amount);
        } else {
            self.erc20Vault.withdraw(withdrawal.exitTarget, withdrawal.token, withdrawal.amount);
        }
    }

    function flagOutputsWhenNonCanonical(
        PlasmaFramework framework,
        PaymentExitDataModel.InFlightExit memory exit,
        address token,
        uint160 exitId
    )
        private
    {
        uint256 piggybackedInputNumOfTheToken;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (exit.inputs[i].token == token && exit.isInputPiggybacked(i)) {
                piggybackedInputNumOfTheToken++;
            }
        }

        bytes32[] memory outputIdsToFlag = new bytes32[](piggybackedInputNumOfTheToken);
        uint indexForOutputIds = 0;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (exit.inputs[i].token == token && exit.isInputPiggybacked(i)) {
                outputIdsToFlag[indexForOutputIds] = exit.inputs[i].outputId;
                indexForOutputIds++;
            }
        }
        framework.batchFlagOutputsFinalized(outputIdsToFlag, exitId);
    }

    function flagOutputsWhenCanonical(
        PlasmaFramework framework,
        PaymentExitDataModel.InFlightExit memory exit,
        address token,
        uint160 exitId
    )
        private
    {
        uint256 inputNumOfTheToken;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (!exit.isInputEmpty(i)) {
                inputNumOfTheToken++;
            }
        }

        uint256 piggybackedOutputNumOfTheToken;
        for (uint16 i = 0; i < exit.outputs.length; i++) {
            if (exit.outputs[i].token == token && exit.isOutputPiggybacked(i)) {
                piggybackedOutputNumOfTheToken++;
            }
        }

        bytes32[] memory outputIdsToFlag = new bytes32[](inputNumOfTheToken + piggybackedOutputNumOfTheToken);
        uint indexForOutputIds = 0;
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (!exit.isInputEmpty(i)) {
                outputIdsToFlag[indexForOutputIds] = exit.inputs[i].outputId;
                indexForOutputIds++;
            }
        }
        for (uint16 i = 0; i < exit.outputs.length; i++) {
            if (exit.outputs[i].token == token && exit.isOutputPiggybacked(i)) {
                outputIdsToFlag[indexForOutputIds] = exit.outputs[i].outputId;
                indexForOutputIds++;
            }
        }
        framework.batchFlagOutputsFinalized(outputIdsToFlag, exitId);
    }

    function returnInputPiggybackBonds(
        Controller memory self,
        PaymentExitDataModel.InFlightExit storage exit,
        address token
    )
        private
    {
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            PaymentExitDataModel.WithdrawData memory withdrawal = exit.inputs[i];

            // If the input has been challenged, isInputPiggybacked() will return false
            if (token == withdrawal.token && exit.isInputPiggybacked(i)) {
                bool success = SafeEthTransfer.transferReturnResult(
                    withdrawal.exitTarget, withdrawal.piggybackBondSize, self.safeGasStipend
                );

                // we do not want to block a queue if bond return is unsuccessful
                if (!success) {
                    emit InFlightBondReturnFailed(withdrawal.exitTarget, withdrawal.piggybackBondSize);
                }
            }
        }
    }

    function returnOutputPiggybackBonds(
        Controller memory self,
        PaymentExitDataModel.InFlightExit storage exit,
        address token
    )
        private
    {
        for (uint16 i = 0; i < exit.outputs.length; i++) {
            PaymentExitDataModel.WithdrawData memory withdrawal = exit.outputs[i];

            // If the output has been challenged, isOutputPiggybacked() will return false
            if (token == withdrawal.token && exit.isOutputPiggybacked(i)) {
                bool success = SafeEthTransfer.transferReturnResult(
                    withdrawal.exitTarget, withdrawal.piggybackBondSize, self.safeGasStipend
                );

                // we do not want to block a queue if bond return is unsuccessful
                if (!success) {
                    emit InFlightBondReturnFailed(withdrawal.exitTarget, withdrawal.piggybackBondSize);
                }
            }
        }
    }

    function clearPiggybackInputFlag(
        PaymentExitDataModel.InFlightExit storage exit,
        address token
    )
        private
    {
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (token == exit.inputs[i].token) {
                exit.clearInputPiggybacked(i);
            }
        }
    }

    function clearPiggybackOutputFlag(
        PaymentExitDataModel.InFlightExit storage exit,
        address token
    )
        private
    {
        for (uint16 i = 0; i < exit.outputs.length; i++) {
            if (token == exit.outputs[i].token) {
                exit.clearOutputPiggybacked(i);
            }
        }
    }

    function allPiggybacksCleared(PaymentExitDataModel.InFlightExit memory exit) private pure returns (bool) {
        for (uint16 i = 0; i < exit.inputs.length; i++) {
            if (exit.isInputPiggybacked(i))
                return false;
        }

        for (uint16 i = 0; i < exit.outputs.length; i++) {
            if (exit.isOutputPiggybacked(i))
                return false;
        }

        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentProcessStandardExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../routers/PaymentStandardExitRouterArgs.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../utils/SafeEthTransfer.sol";
import "../../../vaults/EthVault.sol";
import "../../../vaults/Erc20Vault.sol";

library PaymentProcessStandardExit {
    struct Controller {
        PlasmaFramework framework;
        EthVault ethVault;
        Erc20Vault erc20Vault;
        uint256 safeGasStipend;
    }

    event ExitOmitted(
        uint160 indexed exitId
    );

    event ExitFinalized(
        uint160 indexed exitId
    );

    event BondReturnFailed(
        address indexed receiver,
        uint256 amount
    );

    /**
     * @notice Main logic function to process standard exit
     * @dev emits ExitOmitted event if the exit is omitted
     * @dev emits ExitFinalized event if the exit is processed and funds are withdrawn
     * @param self The controller struct
     * @param exitMap The storage of all standard exit data
     * @param exitId The exitId of the standard exit
     * @param token The ERC20 token address of the exit. Uses address(0) to represent ETH.
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.StandardExitMap storage exitMap,
        uint160 exitId,
        address token
    )
        public
    {
        PaymentExitDataModel.StandardExit memory exit = exitMap.exits[exitId];

        if (!exit.exitable || self.framework.isOutputFinalized(exit.outputId)) {
            emit ExitOmitted(exitId);
            delete exitMap.exits[exitId];
            return;
        }

        self.framework.flagOutputFinalized(exit.outputId, exitId);

        // we do not want to block a queue if bond return is unsuccessful
        bool success = SafeEthTransfer.transferReturnResult(exit.exitTarget, exit.bondSize, self.safeGasStipend);
        if (!success) {
            emit BondReturnFailed(exit.exitTarget, exit.bondSize);
        }

        if (token == address(0)) {
            self.ethVault.withdraw(exit.exitTarget, exit.amount);
        } else {
            self.erc20Vault.withdraw(exit.exitTarget, token, exit.amount);
        }

        delete exitMap.exits[exitId];

        emit ExitFinalized(exitId);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentStartInFlightExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../PaymentInFlightExitModelUtils.sol";
import "../routers/PaymentInFlightExitRouterArgs.sol";
import "../../interfaces/ISpendingCondition.sol";
import "../../interfaces/IStateTransitionVerifier.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/ExitableTimestamp.sol";
import "../../utils/ExitId.sol";
import "../../utils/OutputId.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../../utils/PosLib.sol";
import "../../../utils/Merkle.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../transactions/GenericTransaction.sol";

library PaymentStartInFlightExit {
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using PosLib for PosLib.Position;
    using PaymentInFlightExitModelUtils for PaymentExitDataModel.InFlightExit;
    using PaymentTransactionModel for PaymentTransactionModel.Transaction;

    /**
     * @dev supportedTxType enables code reuse in different Payment Tx versions
     */
    struct Controller {
        PlasmaFramework framework;
        ExitableTimestamp.Calculator exitTimestampCalculator;
        SpendingConditionRegistry spendingConditionRegistry;
        IStateTransitionVerifier transitionVerifier;
        uint256 supportedTxType;
    }

    event InFlightExitStarted(
        address indexed initiator,
        bytes32 indexed txHash
    );

     /**
     * @dev data to be passed around start in-flight exit helper functions
     * @param controller the Controller struct of this library
     * @param exitId ID of the exit
     * @param inFlightTxRaw In-flight transaction as bytes
     * @param inFlightTx Decoded in-flight transaction
     * @param inFlightTxHash Hash of in-flight transaction
     * @param inputTxs Input transactions as bytes
     * @param inputUtxosPos Postions of input utxos coded as integers
     * @param inputTxsInclusionProofs Merkle proofs for input transactions
     * @param inFlightTxWitnesses Witnesses for in-flight transactions
     * @param outputIds Output IDs for input transactions.
     */
    struct StartExitData {
        Controller controller;
        uint160 exitId;
        bytes inFlightTxRaw;
        PaymentTransactionModel.Transaction inFlightTx;
        bytes32 inFlightTxHash;
        bytes[] inputTxs;
        PosLib.Position[] inputUtxosPos;
        bytes[] inputTxsInclusionProofs;
        bytes[] inFlightTxWitnesses;
        bytes32[] outputIds;
    }

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentStartInFlightExit
     */
    function buildController(
        PlasmaFramework framework,
        SpendingConditionRegistry spendingConditionRegistry,
        IStateTransitionVerifier transitionVerifier,
        uint256 supportedTxType
    )
        public
        view
        returns (Controller memory)
    {
        return Controller({
            framework: framework,
            exitTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            spendingConditionRegistry: spendingConditionRegistry,
            transitionVerifier: transitionVerifier,
            supportedTxType: supportedTxType
        });
    }

    /**
     * @notice Main logic function to start in-flight exit
     * @dev emits InFlightExitStarted event on success
     * @param self The controller struct
     * @param inFlightExitMap The storage of all in-flight exit data
     * @param args Arguments of start in-flight exit function from client
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap,
        PaymentInFlightExitRouterArgs.StartExitArgs memory args
    )
        public
    {
        StartExitData memory startExitData = createStartExitData(self, args);
        verifyStart(startExitData, inFlightExitMap);
        startExit(startExitData, inFlightExitMap);
        emit InFlightExitStarted(msg.sender, startExitData.inFlightTxHash);
    }

    function createStartExitData(
        Controller memory controller,
        PaymentInFlightExitRouterArgs.StartExitArgs memory args
    )
        private
        view
        returns (StartExitData memory)
    {
        StartExitData memory exitData;
        exitData.controller = controller;
        exitData.exitId = ExitId.getInFlightExitId(args.inFlightTx);
        exitData.inFlightTxRaw = args.inFlightTx;
        exitData.inFlightTx = PaymentTransactionModel.decode(args.inFlightTx);
        exitData.inFlightTxHash = keccak256(args.inFlightTx);
        exitData.inputTxs = args.inputTxs;
        exitData.inputUtxosPos = decodeInputTxsPositions(args.inputUtxosPos);
        exitData.inputTxsInclusionProofs = args.inputTxsInclusionProofs;
        exitData.inFlightTxWitnesses = args.inFlightTxWitnesses;
        exitData.outputIds = getOutputIds(controller, exitData.inputTxs, exitData.inputUtxosPos);
        return exitData;
    }

    function decodeInputTxsPositions(uint256[] memory inputUtxosPos) private pure returns (PosLib.Position[] memory) {
        require(inputUtxosPos.length <= PaymentTransactionModel.MAX_INPUT_NUM(), "Too many transactions provided");

        PosLib.Position[] memory utxosPos = new PosLib.Position[](inputUtxosPos.length);
        for (uint i = 0; i < inputUtxosPos.length; i++) {
            utxosPos[i] = PosLib.decode(inputUtxosPos[i]);
        }
        return utxosPos;
    }

    function getOutputIds(Controller memory controller, bytes[] memory inputTxs, PosLib.Position[] memory utxoPos)
        private
        view
        returns (bytes32[] memory)
    {
        require(inputTxs.length == utxoPos.length, "Number of input transactions does not match number of provided input utxos positions");
        bytes32[] memory outputIds = new bytes32[](inputTxs.length);
        for (uint i = 0; i < inputTxs.length; i++) {
            bool isDepositTx = controller.framework.isDeposit(utxoPos[i].blockNum);
            outputIds[i] = isDepositTx
                ? OutputId.computeDepositOutputId(inputTxs[i], utxoPos[i].outputIndex, utxoPos[i].encode())
                : OutputId.computeNormalOutputId(inputTxs[i], utxoPos[i].outputIndex);
        }
        return outputIds;
    }

    function verifyStart(
        StartExitData memory exitData,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap
    )
        private
        view
    {
        verifyExitNotStarted(exitData.exitId, inFlightExitMap);
        verifyInFlightTxType(exitData);
        verifyNumberOfInputsMatchesNumberOfInFlightTransactionInputs(exitData);
        verifyNoInputSpentMoreThanOnce(exitData.inFlightTx);
        verifyInputTransactionIsStandardFinalized(exitData);
        verifyInputsSpent(exitData);
        verifyStateTransition(exitData);
    }

    function verifyExitNotStarted(
        uint160 exitId,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap
    )
        private
        view
    {
        PaymentExitDataModel.InFlightExit storage exit = inFlightExitMap.exits[exitId];
        require(exit.exitStartTimestamp == 0, "There is an active in-flight exit from this transaction");
    }

    function verifyInFlightTxType(StartExitData memory exitData) private pure {
        require(exitData.inFlightTx.txType == exitData.controller.supportedTxType, "Unsupported transaction type of the exit game");
    }

    function verifyNumberOfInputsMatchesNumberOfInFlightTransactionInputs(StartExitData memory exitData) private pure {
        require(exitData.inputTxs.length != 0, "In-flight transaction must have inputs");
        require(
            exitData.inputTxs.length == exitData.inFlightTx.inputs.length,
            "Number of input transactions does not match number of in-flight transaction inputs"
        );
        require(
            exitData.inputTxsInclusionProofs.length == exitData.inFlightTx.inputs.length,
            "Number of input transactions inclusion proofs does not match the number of in-flight transaction inputs"
        );
        require(
            exitData.inFlightTxWitnesses.length == exitData.inFlightTx.inputs.length,
            "Number of input transaction witnesses does not match the number of in-flight transaction inputs"
        );
    }

    function verifyNoInputSpentMoreThanOnce(PaymentTransactionModel.Transaction memory inFlightTx) private pure {
        if (inFlightTx.inputs.length > 1) {
            for (uint i = 0; i < inFlightTx.inputs.length; i++) {
                for (uint j = i + 1; j < inFlightTx.inputs.length; j++) {
                    require(inFlightTx.inputs[i] != inFlightTx.inputs[j], "In-flight transaction must have unique inputs");
                }
            }
        }
    }

    function verifyInputTransactionIsStandardFinalized(StartExitData memory exitData) private view {
        for (uint i = 0; i < exitData.inputTxs.length; i++) {
            bool isStandardFinalized = MoreVpFinalization.isStandardFinalized(
                exitData.controller.framework,
                exitData.inputTxs[i],
                exitData.inputUtxosPos[i].toStrictTxPos(),
                exitData.inputTxsInclusionProofs[i]
            );
            require(isStandardFinalized, "Input transaction is not standard finalized");
        }
    }

    function verifyInputsSpent(StartExitData memory exitData) private view {
        for (uint16 i = 0; i < exitData.inputTxs.length; i++) {
            uint16 outputIndex = exitData.inputUtxosPos[i].outputIndex;
            GenericTransaction.Output memory output = GenericTransaction.getOutput(
                GenericTransaction.decode(exitData.inputTxs[i]),
                outputIndex
            );

            ISpendingCondition condition = exitData.controller.spendingConditionRegistry.spendingConditions(
                output.outputType, exitData.controller.supportedTxType
            );

            require(address(condition) != address(0), "Spending condition contract not found");

            bool isSpentByInFlightTx = condition.verify(
                exitData.inputTxs[i],
                exitData.inputUtxosPos[i].encode(),
                exitData.inFlightTxRaw,
                i,
                exitData.inFlightTxWitnesses[i]
            );
            require(isSpentByInFlightTx, "Spending condition failed");
        }
    }

    function verifyStateTransition(StartExitData memory exitData) private view {
        uint16[] memory outputIndexForInputTxs = new uint16[](exitData.inputTxs.length);
        for (uint i = 0; i < exitData.inFlightTx.inputs.length; i++) {
            outputIndexForInputTxs[i] = exitData.inputUtxosPos[i].outputIndex;
        }

        require(
            exitData.controller.transitionVerifier.isCorrectStateTransition(exitData.inFlightTxRaw, exitData.inputTxs, outputIndexForInputTxs),
            "Invalid state transition"
        );
    }

    function startExit(
        StartExitData memory startExitData,
        PaymentExitDataModel.InFlightExitMap storage inFlightExitMap
    )
        private
    {
        PaymentExitDataModel.InFlightExit storage ife = inFlightExitMap.exits[startExitData.exitId];
        ife.isCanonical = true;
        ife.bondOwner = msg.sender;
        ife.bondSize = msg.value;
        ife.position = getYoungestInputUtxoPosition(startExitData.inputUtxosPos);
        ife.exitStartTimestamp = uint64(block.timestamp);
        setInFlightExitInputs(ife, startExitData);
        setInFlightExitOutputs(ife, startExitData);
    }

    function getYoungestInputUtxoPosition(PosLib.Position[] memory inputUtxosPos) private pure returns (uint256) {
        uint256 youngest = inputUtxosPos[0].encode();
        for (uint i = 1; i < inputUtxosPos.length; i++) {
            uint256 encodedUtxoPos = inputUtxosPos[i].encode();
            if (encodedUtxoPos > youngest) {
                youngest = encodedUtxoPos;
            }
        }
        return youngest;
    }

    function setInFlightExitInputs(
        PaymentExitDataModel.InFlightExit storage ife,
        StartExitData memory exitData
    )
        private
    {
        for (uint i = 0; i < exitData.inputTxs.length; i++) {
            uint16 outputIndex = exitData.inputUtxosPos[i].outputIndex;
            FungibleTokenOutputModel.Output memory output = FungibleTokenOutputModel.getOutput(
                GenericTransaction.decode(exitData.inputTxs[i]),
                outputIndex
            );

            ife.inputs[i].outputId = exitData.outputIds[i];
            ife.inputs[i].exitTarget = address(uint160(output.outputGuard));
            ife.inputs[i].token = output.token;
            ife.inputs[i].amount = output.amount;
        }
    }

    function setInFlightExitOutputs(
        PaymentExitDataModel.InFlightExit storage ife,
        StartExitData memory exitData
    )
        private
    {
        for (uint16 i = 0; i < exitData.inFlightTx.outputs.length; i++) {
            // deposit transaction can't be in-flight exited
            bytes32 outputId = OutputId.computeNormalOutputId(exitData.inFlightTxRaw, i);
            FungibleTokenOutputModel.Output memory output = exitData.inFlightTx.getOutput(i);

            ife.outputs[i].outputId = outputId;
            ife.outputs[i].exitTarget = address(uint160(output.outputGuard));
            ife.outputs[i].token = output.token;
            ife.outputs[i].amount = output.amount;
        }
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/controllers/PaymentStartStandardExit.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentExitDataModel.sol";
import "../routers/PaymentStandardExitRouterArgs.sol";
import "../../utils/ExitableTimestamp.sol";
import "../../utils/ExitId.sol";
import "../../utils/OutputId.sol";
import "../../utils/MoreVpFinalization.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../utils/PosLib.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../utils/ExitableTimestamp.sol";

library PaymentStartStandardExit {
    using ExitableTimestamp for ExitableTimestamp.Calculator;
    using PosLib for PosLib.Position;
    using PaymentTransactionModel for PaymentTransactionModel.Transaction;

    struct Controller {
        IExitProcessor exitProcessor;
        PlasmaFramework framework;
        ExitableTimestamp.Calculator exitableTimestampCalculator;
        uint256 ethVaultId;
        uint256 erc20VaultId;
        uint256 supportedTxType;
    }

    /**
     * @dev Data to be passed around startStandardExit helper functions
     */
    struct StartStandardExitData {
        Controller controller;
        PaymentStandardExitRouterArgs.StartStandardExitArgs args;
        PosLib.Position utxoPos;
        PaymentTransactionModel.Transaction outputTx;
        FungibleTokenOutputModel.Output output;
        uint160 exitId;
        bool isTxDeposit;
        uint256 txBlockTimeStamp;
        bytes32 outputId;
    }

    event ExitStarted(
        address indexed owner,
        uint160 exitId
    );

    /**
     * @notice Function that builds the controller struct
     * @return Controller struct of PaymentStartStandardExit
     */
    function buildController(
        IExitProcessor exitProcessor,
        PlasmaFramework framework,
        uint256 ethVaultId,
        uint256 erc20VaultId,
        uint256 supportedTxType
    )
        public
        view
        returns (Controller memory)
    {
        return Controller({
            exitProcessor: exitProcessor,
            framework: framework,
            exitableTimestampCalculator: ExitableTimestamp.Calculator(framework.minExitPeriod()),
            ethVaultId: ethVaultId,
            erc20VaultId: erc20VaultId,
            supportedTxType: supportedTxType
        });
    }

    /**
     * @notice Main logic function to start standard exit
     * @dev emits ExitStarted event on success
     * @param self The controller struct
     * @param exitMap The storage of all standard exit data
     * @param args Arguments of start standard exit function from client
     */
    function run(
        Controller memory self,
        PaymentExitDataModel.StandardExitMap storage exitMap,
        PaymentStandardExitRouterArgs.StartStandardExitArgs memory args
    )
        public
    {
        StartStandardExitData memory data = setupStartStandardExitData(self, args);
        verifyStartStandardExitData(self, data, exitMap);
        saveStandardExitData(data, exitMap);
        enqueueStandardExit(data);

        emit ExitStarted(msg.sender, data.exitId);
    }

    function setupStartStandardExitData(
        Controller memory controller,
        PaymentStandardExitRouterArgs.StartStandardExitArgs memory args
    )
        private
        view
        returns (StartStandardExitData memory)
    {
        PosLib.Position memory utxoPos = PosLib.decode(args.utxoPos);
        PaymentTransactionModel.Transaction memory outputTx = PaymentTransactionModel.decode(args.rlpOutputTx);
        FungibleTokenOutputModel.Output memory output = outputTx.getOutput(utxoPos.outputIndex);
        bool isTxDeposit = controller.framework.isDeposit(utxoPos.blockNum);
        uint160 exitId = ExitId.getStandardExitId(isTxDeposit, args.rlpOutputTx, utxoPos);
        (, uint256 blockTimestamp) = controller.framework.blocks(utxoPos.blockNum);

        bytes32 outputId = isTxDeposit
            ? OutputId.computeDepositOutputId(args.rlpOutputTx, utxoPos.outputIndex, utxoPos.encode())
            : OutputId.computeNormalOutputId(args.rlpOutputTx, utxoPos.outputIndex);

        return StartStandardExitData({
            controller: controller,
            args: args,
            utxoPos: utxoPos,
            outputTx: outputTx,
            output: output,
            exitId: exitId,
            isTxDeposit: isTxDeposit,
            txBlockTimeStamp: blockTimestamp,
            outputId: outputId
        });
    }

    function verifyStartStandardExitData(
        Controller memory self,
        StartStandardExitData memory data,
        PaymentExitDataModel.StandardExitMap storage exitMap
    )
        private
        view
    {
        require(data.outputTx.txType == data.controller.supportedTxType, "Unsupported transaction type of the exit game");
        require(data.txBlockTimeStamp != 0, "There is no block for the position");

        require(PaymentTransactionModel.getOutputOwner(data.output) == msg.sender, "Only output owner can start an exit");

        require(isStandardFinalized(data), "The transaction must be standard finalized");
        PaymentExitDataModel.StandardExit memory exit = exitMap.exits[data.exitId];
        require(exit.amount == 0, "Exit has already started");

        require(self.framework.isOutputFinalized(data.outputId) == false, "Output is already spent");
    }

    function isStandardFinalized(StartStandardExitData memory data)
        private
        view
        returns (bool)
    {
        return MoreVpFinalization.isStandardFinalized(
            data.controller.framework,
            data.args.rlpOutputTx,
            data.utxoPos.toStrictTxPos(),
            data.args.outputTxInclusionProof
        );
    }

    function saveStandardExitData(
        StartStandardExitData memory data,
        PaymentExitDataModel.StandardExitMap storage exitMap
    )
        private
    {
        exitMap.exits[data.exitId] = PaymentExitDataModel.StandardExit({
            exitable: true,
            utxoPos: data.utxoPos.encode(),
            outputId: data.outputId,
            exitTarget: msg.sender,
            amount: data.output.amount,
            bondSize: msg.value
        });
    }

    function enqueueStandardExit(StartStandardExitData memory data) private {

        uint64 exitableAt;
        ExitableTimestamp.Calculator memory exitableTimestampCalculator = data.controller.exitableTimestampCalculator;

        if (data.isTxDeposit){
            exitableAt = exitableTimestampCalculator.calculateDepositTxOutputExitableTimestamp(block.timestamp);
        } else {
            exitableAt = exitableTimestampCalculator.calculateTxExitableTimestamp(block.timestamp, data.txBlockTimeStamp);
        }

        uint256 vaultId;
        if (data.output.token == address(0)) {
            vaultId = data.controller.ethVaultId;
        } else {
            vaultId = data.controller.erc20VaultId;
        }

        data.controller.framework.enqueue(
            vaultId, data.output.token, exitableAt, data.utxoPos.toStrictTxPos(),
            data.exitId, data.controller.exitProcessor
        );
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/routers/PaymentInFlightExitRouter.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./PaymentInFlightExitRouterArgs.sol";
import "../PaymentExitDataModel.sol";
import "../PaymentExitGameArgs.sol";
import "../controllers/PaymentStartInFlightExit.sol";
import "../controllers/PaymentPiggybackInFlightExit.sol";
import "../controllers/PaymentChallengeIFENotCanonical.sol";
import "../controllers/PaymentChallengeIFEInputSpent.sol";
import "../controllers/PaymentChallengeIFEOutputSpent.sol";
import "../controllers/PaymentDeleteInFlightExit.sol";
import "../controllers/PaymentProcessInFlightExit.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../interfaces/IStateTransitionVerifier.sol";
import "../../utils/BondSize.sol";
import "../../../utils/FailFastReentrancyGuard.sol";
import "../../../utils/OnlyFromAddress.sol";
import "../../../utils/OnlyWithValue.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";


contract PaymentInFlightExitRouter is
    IExitProcessor,
    OnlyFromAddress,
    OnlyWithValue,
    FailFastReentrancyGuard
{
    using PaymentStartInFlightExit for PaymentStartInFlightExit.Controller;
    using PaymentPiggybackInFlightExit for PaymentPiggybackInFlightExit.Controller;
    using PaymentChallengeIFENotCanonical for PaymentChallengeIFENotCanonical.Controller;
    using PaymentChallengeIFEInputSpent for PaymentChallengeIFEInputSpent.Controller;
    using PaymentChallengeIFEOutputSpent for PaymentChallengeIFEOutputSpent.Controller;
    using PaymentDeleteInFlightExit for PaymentDeleteInFlightExit.Controller;
    using PaymentProcessInFlightExit for PaymentProcessInFlightExit.Controller;
    using BondSize for BondSize.Params;

    // Initial IFE bond size = 185000 (gas cost of challenge) * 20 gwei (current fast gas price) * 10 (safety margin)
    uint128 public constant INITIAL_IFE_BOND_SIZE = 37000000000000000 wei;

    // Initial piggyback bond size = 140000 (gas cost of challenge) * 20 gwei (current fast gas price) * 10 (safety margin)
    uint128 public constant INITIAL_PB_BOND_SIZE = 28000000000000000 wei;

    // Each bond size upgrade can increase to a maximum of 200% or decrease to 50% of the current bond
    uint16 public constant BOND_LOWER_BOUND_DIVISOR = 2;
    uint16 public constant BOND_UPPER_BOUND_MULTIPLIER = 2;

    PaymentExitDataModel.InFlightExitMap internal inFlightExitMap;
    PaymentStartInFlightExit.Controller internal startInFlightExitController;
    PaymentPiggybackInFlightExit.Controller internal piggybackInFlightExitController;
    PaymentChallengeIFENotCanonical.Controller internal challengeCanonicityController;
    PaymentChallengeIFEInputSpent.Controller internal challengeInputSpentController;
    PaymentChallengeIFEOutputSpent.Controller internal challengeOutputSpentController;
    PaymentDeleteInFlightExit.Controller internal deleteNonPiggybackIFEController;
    PaymentProcessInFlightExit.Controller internal processInflightExitController;
    BondSize.Params internal startIFEBond;
    BondSize.Params internal piggybackBond;

    PlasmaFramework private framework;

    event IFEBondUpdated(uint128 bondSize);
    event PiggybackBondUpdated(uint128 bondSize);

    event InFlightExitStarted(
        address indexed initiator,
        bytes32 indexed txHash
    );

    event InFlightExitInputPiggybacked(
        address indexed exitTarget,
        bytes32 indexed txHash,
        uint16 inputIndex
    );

    event InFlightExitOmitted(
        uint160 indexed exitId,
        address token
    );

    event InFlightBondReturnFailed(
        address indexed receiver,
        uint256 amount
    );

    event InFlightExitOutputWithdrawn(
        uint160 indexed exitId,
        uint16 outputIndex
    );

    event InFlightExitInputWithdrawn(
        uint160 indexed exitId,
        uint16 inputIndex
    );

    event InFlightExitOutputPiggybacked(
        address indexed exitTarget,
        bytes32 indexed txHash,
        uint16 outputIndex
    );

    event InFlightExitChallenged(
        address indexed challenger,
        bytes32 indexed txHash,
        uint256 challengeTxPosition
    );

    event InFlightExitChallengeResponded(
        address indexed challenger,
        bytes32 indexed txHash,
        uint256 challengeTxPosition
    );

    event InFlightExitInputBlocked(
        address indexed challenger,
        bytes32 indexed txHash,
        uint16 inputIndex
    );

    event InFlightExitOutputBlocked(
        address indexed challenger,
        bytes32 indexed txHash,
        uint16 outputIndex
    );

    event InFlightExitDeleted(
        uint160 indexed exitId
    );

    constructor(PaymentExitGameArgs.Args memory args)
        public
    {
        framework = args.framework;

        EthVault ethVault = EthVault(args.framework.vaults(args.ethVaultId));
        require(address(ethVault) != address(0), "Invalid ETH vault");

        Erc20Vault erc20Vault = Erc20Vault(args.framework.vaults(args.erc20VaultId));
        require(address(erc20Vault) != address(0), "Invalid ERC20 vault");

        startInFlightExitController = PaymentStartInFlightExit.buildController(
            args.framework,
            args.spendingConditionRegistry,
            args.stateTransitionVerifier,
            args.supportTxType
        );

        piggybackInFlightExitController = PaymentPiggybackInFlightExit.buildController(
            args.framework,
            this,
            args.ethVaultId,
            args.erc20VaultId
        );

        challengeCanonicityController = PaymentChallengeIFENotCanonical.buildController(
            args.framework,
            args.spendingConditionRegistry,
            args.supportTxType
        );

        challengeInputSpentController = PaymentChallengeIFEInputSpent.buildController(
            args.framework,
            args.spendingConditionRegistry,
            args.safeGasStipend
        );

        challengeOutputSpentController = PaymentChallengeIFEOutputSpent.Controller(
            args.framework,
            args.spendingConditionRegistry,
            args.safeGasStipend
        );

        deleteNonPiggybackIFEController = PaymentDeleteInFlightExit.Controller({
            minExitPeriod: args.framework.minExitPeriod(),
            safeGasStipend: args.safeGasStipend
        });

        processInflightExitController = PaymentProcessInFlightExit.Controller({
            framework: args.framework,
            ethVault: ethVault,
            erc20Vault: erc20Vault,
            safeGasStipend: args.safeGasStipend
        });
        startIFEBond = BondSize.buildParams(INITIAL_IFE_BOND_SIZE, BOND_LOWER_BOUND_DIVISOR, BOND_UPPER_BOUND_MULTIPLIER);
        piggybackBond = BondSize.buildParams(INITIAL_PB_BOND_SIZE, BOND_LOWER_BOUND_DIVISOR, BOND_UPPER_BOUND_MULTIPLIER);
    }

    /**
     * @notice Getter functions to retrieve in-flight exit data of the PaymentExitGame
     * @param exitIds The exit IDs of the in-flight exits
     */
    function inFlightExits(uint160[] calldata exitIds) external view returns (PaymentExitDataModel.InFlightExit[] memory) {
        PaymentExitDataModel.InFlightExit[] memory exits = new PaymentExitDataModel.InFlightExit[](exitIds.length);
        for (uint i = 0; i < exitIds.length; i++) {
            uint160 exitId = exitIds[i];
            exits[i] = inFlightExitMap.exits[exitId];
        }
        return exits;
    }

    /**
     * @notice Starts withdrawal from a transaction that may be in-flight
     * @param args Input argument data to challenge (see also struct 'StartExitArgs')
     */
    function startInFlightExit(PaymentInFlightExitRouterArgs.StartExitArgs memory args)
        public
        payable
        nonReentrant(framework)
        onlyWithValue(startIFEBondSize())
    {
        startInFlightExitController.run(inFlightExitMap, args);
    }

    /**
     * @notice Piggyback on an input of an in-flight exiting tx. Processed only if the in-flight exit is non-canonical.
     * @param args Input argument data to piggyback (see also struct 'PiggybackInFlightExitOnInputArgs')
     */
    function piggybackInFlightExitOnInput(
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnInputArgs memory args
    )
        public
        payable
        nonReentrant(framework)
        onlyWithValue(piggybackBondSize())
    {
        piggybackInFlightExitController.piggybackInput(inFlightExitMap, args);
    }

    /**
     * @notice Piggyback on an output of an in-flight exiting tx. Processed only if the in-flight exit is canonical.
     * @param args Input argument data to piggyback (see also struct 'PiggybackInFlightExitOnOutputArgs')
     */
    function piggybackInFlightExitOnOutput(
        PaymentInFlightExitRouterArgs.PiggybackInFlightExitOnOutputArgs memory args
    )
        public
        payable
        nonReentrant(framework)
        onlyWithValue(piggybackBondSize())
    {
        piggybackInFlightExitController.piggybackOutput(inFlightExitMap, args);
    }

    /**
     * @notice Challenges an in-flight exit to be non-canonical
     * @param args Input argument data to challenge (see also struct 'ChallengeCanonicityArgs')
     */
    function challengeInFlightExitNotCanonical(PaymentInFlightExitRouterArgs.ChallengeCanonicityArgs memory args)
        public
        nonReentrant(framework)
    {
        challengeCanonicityController.challenge(inFlightExitMap, args);
    }

    /**
     * @notice Respond to a non-canonical challenge by providing its position and by proving its correctness
     * @param inFlightTx The RLP-encoded in-flight transaction
     * @param inFlightTxPos The position of the in-flight exiting transaction. The output index within the position is unused and should be set to 0
     * @param inFlightTxInclusionProof Proof that the in-flight exiting transaction is included in a Plasma block
     */
    function respondToNonCanonicalChallenge(
        bytes memory inFlightTx,
        uint256 inFlightTxPos,
        bytes memory inFlightTxInclusionProof
    )
        public
        nonReentrant(framework)
    {
        challengeCanonicityController.respond(inFlightExitMap, inFlightTx, inFlightTxPos, inFlightTxInclusionProof);
    }

    /**
     * @notice Challenges an exit from in-flight transaction input
     * @param args Argument data to challenge (see also struct 'ChallengeInputSpentArgs')
     */
    function challengeInFlightExitInputSpent(PaymentInFlightExitRouterArgs.ChallengeInputSpentArgs memory args)
        public
        nonReentrant(framework)
    {
        challengeInputSpentController.run(inFlightExitMap, args);
    }

     /**
     * @notice Challenges an exit from in-flight transaction output
     * @param args Argument data to challenge (see also struct 'ChallengeOutputSpent')
     */
    function challengeInFlightExitOutputSpent(PaymentInFlightExitRouterArgs.ChallengeOutputSpent memory args)
        public
        nonReentrant(framework)
    {
        challengeOutputSpentController.run(inFlightExitMap, args);
    }

    /**
     * @notice Deletes in-flight exit if the first phase has passed and not being piggybacked
     * @dev Since IFE is enqueued during piggyback, a non-piggybacked IFE means that it will never be processed.
     *      This means that the IFE bond will never be returned.
     *      see: https://github.com/omisego/plasma-contracts/issues/440
     * @param exitId The exitId of the in-flight exit
     */
    function deleteNonPiggybackedInFlightExit(uint160 exitId) public nonReentrant(framework) {
        deleteNonPiggybackIFEController.run(inFlightExitMap, exitId);
    }

    /**
     * @notice Process in-flight exit
     * @dev This function is designed to be called in the main processExit function, thus, using internal
     * @param exitId The in-flight exit ID
     * @param token The token (in erc20 address or address(0) for ETH) of the exiting output
     */
    function processInFlightExit(uint160 exitId, address token) internal {
        processInflightExitController.run(inFlightExitMap, exitId, token);
    }

    /**
     * @notice Retrieves the in-flight exit bond size
     */
    function startIFEBondSize() public view returns (uint128) {
        return startIFEBond.bondSize();
    }

    /**
     * @notice Updates the in-flight exit bond size, taking two days to become effective.
     * @param newBondSize The new bond size
     */
    function updateStartIFEBondSize(uint128 newBondSize) public onlyFrom(framework.getMaintainer()) {
        startIFEBond.updateBondSize(newBondSize);
        emit IFEBondUpdated(newBondSize);
    }

    /**
     * @notice Retrieves the piggyback bond size
     */
    function piggybackBondSize() public view returns (uint128) {
        return piggybackBond.bondSize();
    }

    /**
     * @notice Updates the piggyback bond size, taking two days to become effective
     * @param newBondSize The new bond size
     */
    function updatePiggybackBondSize(uint128 newBondSize) public onlyFrom(framework.getMaintainer()) {
        piggybackBond.updateBondSize(newBondSize);
        emit PiggybackBondUpdated(newBondSize);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/routers/PaymentInFlightExitRouterArgs.sol": {
      "content": "pragma solidity 0.5.11;

library PaymentInFlightExitRouterArgs {
    /**
    * @notice Wraps arguments for startInFlightExit.
    * @param inFlightTx RLP encoded in-flight transaction.
    * @param inputTxs Transactions that created the inputs to the in-flight transaction. In the same order as in-flight transaction inputs.
    * @param inputUtxosPos Utxos that represent in-flight transaction inputs. In the same order as input transactions.
    * @param inputTxsInclusionProofs Merkle proofs that show the input-creating transactions are valid. In the same order as input transactions.
    * @param inFlightTxWitnesses Witnesses for in-flight transaction. In the same order as input transactions.
    */
    struct StartExitArgs {
        bytes inFlightTx;
        bytes[] inputTxs;
        uint256[] inputUtxosPos;
        bytes[] inputTxsInclusionProofs;
        bytes[] inFlightTxWitnesses;
    }

    /**
    * @notice Wraps arguments for piggybacking on in-flight transaction input exit
    * @param inFlightTx RLP-encoded in-flight transaction
    * @param inputIndex Index of the input to piggyback on
    */
    struct PiggybackInFlightExitOnInputArgs {
        bytes inFlightTx;
        uint16 inputIndex;
    }

    /**
    * @notice Wraps arguments for piggybacking on in-flight transaction output exit
    * @param inFlightTx RLP-encoded in-flight transaction
    * @param outputIndex Index of the output to piggyback on
    */
    struct PiggybackInFlightExitOnOutputArgs {
        bytes inFlightTx;
        uint16 outputIndex;
    }

    /**
     * @notice Wraps arguments for challenging non-canonical in-flight exits
     * @param inputTx Transaction that created the input shared by the in-flight transaction and its competitor
     * @param inputUtxoPos Position of input utxo
     * @param inFlightTx RLP-encoded in-flight transaction
     * @param inFlightTxInputIndex Index of the shared input in the in-flight transaction
     * @param competingTx RLP-encoded competing transaction
     * @param competingTxInputIndex Index of shared input in competing transaction
     * @param competingTxPos (Optional) Position of competing transaction in the chain, if included. OutputIndex of the position should be 0.
     * @param competingTxInclusionProof (Optional) Merkle proofs showing that the competing transaction was contained in chain
     * @param competingTxWitness Witness for competing transaction
     */
    struct ChallengeCanonicityArgs {
        bytes inputTx;
        uint256 inputUtxoPos;
        bytes inFlightTx;
        uint16 inFlightTxInputIndex;
        bytes competingTx;
        uint16 competingTxInputIndex;
        uint256 competingTxPos;
        bytes competingTxInclusionProof;
        bytes competingTxWitness;
    }

    /**
     * @notice Wraps arguments for challenging in-flight exit input spent
     * @param inFlightTx RLP-encoded in-flight transaction
     * @param inFlightTxInputIndex Index of spent input
     * @param challengingTx RLP-encoded challenging transaction
     * @param challengingTxInputIndex Index of spent input in a challenging transaction
     * @param challengingTxWitness Witness for challenging transactions
     * @param inputTx RLP-encoded input transaction
     * @param inputUtxoPos UTXO position of input transaction's output
     * @param senderData A keccak256 hash of the sender's address
     */
    struct ChallengeInputSpentArgs {
        bytes inFlightTx;
        uint16 inFlightTxInputIndex;
        bytes challengingTx;
        uint16 challengingTxInputIndex;
        bytes challengingTxWitness;
        bytes inputTx;
        uint256 inputUtxoPos;
        bytes32 senderData;
    }

     /**
     * @notice Wraps arguments for challenging in-flight transaction output exit
     * @param inFlightTx RLP-encoded in-flight transaction
     * @param inFlightTxInclusionProof Proof that an in-flight transaction is included in Plasma
     * @param outputUtxoPos UTXO position of challenged output
     * @param challengingTx RLP-encoded challenging transaction
     * @param challengingTxInputIndex Input index of challenged output in a challenging transaction
     * @param challengingTxWitness Witness for challenging transaction
     * @param senderData A keccak256 hash of the sender's address
     */
    struct ChallengeOutputSpent {
        bytes inFlightTx;
        bytes inFlightTxInclusionProof;
        uint256 outputUtxoPos;
        bytes challengingTx;
        uint16 challengingTxInputIndex;
        bytes challengingTxWitness;
        bytes32 senderData;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/routers/PaymentStandardExitRouter.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./PaymentStandardExitRouterArgs.sol";
import "../PaymentExitGameArgs.sol";
import "../PaymentExitDataModel.sol";
import "../controllers/PaymentStartStandardExit.sol";
import "../controllers/PaymentProcessStandardExit.sol";
import "../controllers/PaymentChallengeStandardExit.sol";
import "../../registries/SpendingConditionRegistry.sol";
import "../../utils/BondSize.sol";
import "../../../vaults/EthVault.sol";
import "../../../vaults/Erc20Vault.sol";
import "../../../framework/PlasmaFramework.sol";
import "../../../framework/interfaces/IExitProcessor.sol";
import "../../../utils/OnlyWithValue.sol";
import "../../../utils/OnlyFromAddress.sol";
import "../../../utils/FailFastReentrancyGuard.sol";

contract PaymentStandardExitRouter is
    IExitProcessor,
    OnlyFromAddress,
    OnlyWithValue,
    FailFastReentrancyGuard
{
    using PaymentStartStandardExit for PaymentStartStandardExit.Controller;
    using PaymentChallengeStandardExit for PaymentChallengeStandardExit.Controller;
    using PaymentProcessStandardExit for PaymentProcessStandardExit.Controller;
    using BondSize for BondSize.Params;

    // Initial bond size = 70000 (gas cost of challenge) * 20 gwei (current fast gas price) * 10 (safety margin)
    uint128 public constant INITIAL_BOND_SIZE = 14000000000000000 wei;

    // Each bond size upgrade can either at most increase to 200% or decrease to 50% of current bond
    uint16 public constant BOND_LOWER_BOUND_DIVISOR = 2;
    uint16 public constant BOND_UPPER_BOUND_MULTIPLIER = 2;

    PaymentExitDataModel.StandardExitMap internal standardExitMap;
    PaymentStartStandardExit.Controller internal startStandardExitController;
    PaymentProcessStandardExit.Controller internal processStandardExitController;
    PaymentChallengeStandardExit.Controller internal challengeStandardExitController;
    BondSize.Params internal startStandardExitBond;

    PlasmaFramework private framework;

    event StandardExitBondUpdated(uint128 bondSize);

    event ExitStarted(
        address indexed owner,
        uint160 exitId
    );

    event ExitChallenged(
        uint256 indexed utxoPos
    );

    event ExitOmitted(
        uint160 indexed exitId
    );

    event ExitFinalized(
        uint160 indexed exitId
    );

    event BondReturnFailed(
        address indexed receiver,
        uint256 amount
    );

    constructor(PaymentExitGameArgs.Args memory args)
        public
    {
        framework = args.framework;

        EthVault ethVault = EthVault(args.framework.vaults(args.ethVaultId));
        require(address(ethVault) != address(0), "Invalid ETH vault");

        Erc20Vault erc20Vault = Erc20Vault(args.framework.vaults(args.erc20VaultId));
        require(address(erc20Vault) != address(0), "Invalid ERC20 vault");

        startStandardExitController = PaymentStartStandardExit.buildController(
            this,
            args.framework,
            args.ethVaultId,
            args.erc20VaultId,
            args.supportTxType
        );

        challengeStandardExitController = PaymentChallengeStandardExit.buildController(
            args.framework,
            args.spendingConditionRegistry,
            args.safeGasStipend
        );

        processStandardExitController = PaymentProcessStandardExit.Controller(
            args.framework, ethVault, erc20Vault, args.safeGasStipend
        );

        startStandardExitBond = BondSize.buildParams(INITIAL_BOND_SIZE, BOND_LOWER_BOUND_DIVISOR, BOND_UPPER_BOUND_MULTIPLIER);
    }

    /**
     * @notice Getter retrieves standard exit data of the PaymentExitGame
     * @param exitIds Exit IDs of the standard exits
     */
    function standardExits(uint160[] calldata exitIds) external view returns (PaymentExitDataModel.StandardExit[] memory) {
        PaymentExitDataModel.StandardExit[] memory exits = new PaymentExitDataModel.StandardExit[](exitIds.length);
        for (uint i = 0; i < exitIds.length; i++){
            uint160 exitId = exitIds[i];
            exits[i] = standardExitMap.exits[exitId];
        }
        return exits;
    }

    /**
     * @notice Retrieves the standard exit bond size
     */
    function startStandardExitBondSize() public view returns (uint128) {
        return startStandardExitBond.bondSize();
    }

    /**
     * @notice Updates the standard exit bond size, taking two days to become effective
     * @param newBondSize The new bond size
     */
    function updateStartStandardExitBondSize(uint128 newBondSize) public onlyFrom(framework.getMaintainer()) {
        startStandardExitBond.updateBondSize(newBondSize);
        emit StandardExitBondUpdated(newBondSize);
    }

    /**
     * @notice Starts a standard exit of a given output, using output-age priority
     */
    function startStandardExit(
        PaymentStandardExitRouterArgs.StartStandardExitArgs memory args
    )
        public
        payable
        nonReentrant(framework)
        onlyWithValue(startStandardExitBondSize())
    {
        startStandardExitController.run(standardExitMap, args);
    }

    /**
     * @notice Challenge a standard exit by showing the exiting output was spent
     */
    function challengeStandardExit(PaymentStandardExitRouterArgs.ChallengeStandardExitArgs memory args)
        public
        nonReentrant(framework)
    {
        challengeStandardExitController.run(standardExitMap, args);
    }

    /**
     * @notice Process standard exit
     * @dev This function is designed to be called in the main processExit function, using internal
     * @param exitId The standard exit ID
     * @param token The token (in erc20 address or address(0) for ETH) of the exiting output
     */
    function processStandardExit(uint160 exitId, address token) internal {
        processStandardExitController.run(standardExitMap, exitId, token);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/routers/PaymentStandardExitRouterArgs.sol": {
      "content": "pragma solidity 0.5.11;

library PaymentStandardExitRouterArgs {
    /**
     * @notice Wraps arguments for startStandardExit
     * @param utxoPos Position of the exiting output
     * @param rlpOutputTx The RLP-encoded transaction that creates the exiting output
     * @param outputTxInclusionProof A Merkle proof showing that the transaction was included
    */
    struct StartStandardExitArgs {
        uint256 utxoPos;
        bytes rlpOutputTx;
        bytes outputTxInclusionProof;
    }

    /**
     * @notice Input args data for challengeStandardExit
     * @param exitId Identifier of the standard exit to challenge
     * @param exitingTx RLP-encoded transaction that creates the exiting output
     * @param challengeTx RLP-encoded transaction that spends the exiting output
     * @param inputIndex Input of the challenging tx, corresponding to the exiting output
     * @param witness Witness data that proves the exiting output is spent
     * @param senderData A keccak256 hash of the sender's address
     */
    struct ChallengeStandardExitArgs {
        uint160 exitId;
        bytes exitingTx;
        bytes challengeTx;
        uint16 inputIndex;
        bytes witness;
        bytes32 senderData;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/payment/spendingConditions/PaymentOutputToPaymentTxCondition.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";

import "../../interfaces/ISpendingCondition.sol";
import "../../../utils/PosLib.sol";
import "../../../transactions/PaymentTransactionModel.sol";
import "../../../transactions/eip712Libs/PaymentEip712Lib.sol";

contract PaymentOutputToPaymentTxCondition is ISpendingCondition {
    using PaymentEip712Lib for PaymentEip712Lib.Constants;
    using PosLib for PosLib.Position;
    using PaymentTransactionModel for PaymentTransactionModel.Transaction;

    uint256 internal supportInputTxType;
    uint256 internal supportSpendingTxType;
    PaymentEip712Lib.Constants internal eip712;

    /**
     * @dev This is designed to be re-useable for all versions of payment transaction, so that
     *      inputTxType and spendingTxType of the payment output is injected instead
     */
    constructor(address framework, uint256 inputTxType, uint256 spendingTxType) public {
        eip712 = PaymentEip712Lib.initConstants(framework);
        supportInputTxType = inputTxType;
        supportSpendingTxType = spendingTxType;
    }

    /**
     * @notice Verifies the spending condition
     * @param inputTxBytes Encoded input transaction, in bytes
     * @param utxoPos Position of the utxo
     * @param spendingTxBytes Spending transaction, in bytes
     * @param inputIndex Input index of the spending tx that points to the output
     * @param signature Signature of the output owner
     */
    function verify(
        bytes calldata inputTxBytes,
        uint256 utxoPos,
        bytes calldata spendingTxBytes,
        uint16 inputIndex,
        bytes calldata signature
    )
        external
        view
        returns (bool)
    {
        PaymentTransactionModel.Transaction memory inputTx = PaymentTransactionModel.decode(inputTxBytes);
        require(inputTx.txType == supportInputTxType, "Input tx is an unsupported payment tx type");

        PaymentTransactionModel.Transaction memory spendingTx = PaymentTransactionModel.decode(spendingTxBytes);
        require(spendingTx.txType == supportSpendingTxType, "The spending tx is an unsupported payment tx type");

        require(
            spendingTx.inputs[inputIndex] == bytes32(utxoPos),
            "Spending tx points to the incorrect output UTXO position"
        );

        PosLib.Position memory decodedUtxoPos = PosLib.decode(utxoPos);
        address owner = PaymentTransactionModel.getOutputOwner(inputTx.getOutput(decodedUtxoPos.outputIndex));
        address signer = ECDSA.recover(eip712.hashTx(spendingTx), signature);
        require(signer != address(0), "Failed to recover the signer from the signature");
        require(owner == signer, "Tx is not signed correctly");

        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/registries/SpendingConditionRegistry.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

import "../interfaces/ISpendingCondition.sol";

/**
 * @title SpendingConditionRegistry
 * @notice The registry contracts of the spending condition
 * @dev This is designed to renounce ownership before injecting the registry contract to ExitGame contracts
 *      After registering all the essential condition contracts, the owner should renounce its ownership to
 *      ensure no further conditions are registered for an ExitGame contract.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol#L55
 */
contract SpendingConditionRegistry is Ownable {
    // mapping of hash(outputType, spendingTxTpye) => ISpendingCondition
    mapping(bytes32 => ISpendingCondition) internal _spendingConditions;

    function spendingConditions(uint256 outputType, uint256 spendingTxType) public view returns (ISpendingCondition) {
        bytes32 key = keccak256(abi.encode(outputType, spendingTxType));
        return _spendingConditions[key];
    }

    /**
     * @notice Register the spending condition contract
     * @param outputType The output type of the spending condition
     * @param spendingTxType Spending tx type of the spending condition
     * @param condition The spending condition contract
     */
    function registerSpendingCondition(uint256 outputType, uint256 spendingTxType, ISpendingCondition condition)
        public
        onlyOwner
    {
        require(outputType != 0, "Registration not possible with output type 0");
        require(spendingTxType != 0, "Registration not possible with spending tx type 0");
        require(Address.isContract(address(condition)), "Registration not possible with a non-contract address");

        bytes32 key = keccak256(abi.encode(outputType, spendingTxType));
        require(address(_spendingConditions[key]) == address(0), "The (output type, spending tx type) pair is already registered");

        _spendingConditions[key] = condition;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/utils/BondSize.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @notice Stores an updateable bond size
 * @dev Bond design details at https://github.com/omisego/research/issues/107#issuecomment-525267486
 * @dev Security depends on the min/max value, which can be updated to compare to the current bond size, plus the waiting period
 *      Min/max value of the next bond size prevents the possibility to set bond size too low or too high, which risks breaking the system
 *      Waiting period ensures that a user does not get an unexpected bond without notice.
 */
library BondSize {
    uint64 constant public WAITING_PERIOD = 2 days;

    /**
     * @dev Struct is designed to be packed into two 32-bytes storage slots
     * @param previousBondSize The bond size prior to upgrade, which should remain the same until the waiting period completes
     * @param updatedBondSize The bond size to use once the waiting period completes
     * @param effectiveUpdateTime A timestamp for the end of the waiting period, when the updated bond size is implemented
     * @param lowerBoundDivisor The divisor that checks the lower bound for an update. Each update cannot be lower than (current bond / lowerBoundDivisor)
     * @param upperBoundMultiplier The multiplier that checks the upper bound for an update. Each update cannot be larger than (current bond * upperBoundMultiplier)
     */
    struct Params {
        uint128 previousBondSize;
        uint128 updatedBondSize;
        uint128 effectiveUpdateTime;
        uint16 lowerBoundDivisor;
        uint16 upperBoundMultiplier;
    }

    function buildParams(uint128 initialBondSize, uint16 lowerBoundDivisor, uint16 upperBoundMultiplier)
        internal
        pure
        returns (Params memory)
    {
        // Set the initial value far into the future
        uint128 initialEffectiveUpdateTime = 2 ** 63;
        return Params({
            previousBondSize: initialBondSize,
            updatedBondSize: 0,
            effectiveUpdateTime: initialEffectiveUpdateTime,
            lowerBoundDivisor: lowerBoundDivisor,
            upperBoundMultiplier: upperBoundMultiplier
        });
    }

    /**
    * @notice Updates the bond size
    * @dev The new bond size value updates once the two day waiting period completes
    * @param newBondSize The new bond size
    */
    function updateBondSize(Params storage self, uint128 newBondSize) internal {
        validateBondSize(self, newBondSize);

        if (self.updatedBondSize != 0 && now >= self.effectiveUpdateTime) {
            self.previousBondSize = self.updatedBondSize;
        }
        self.updatedBondSize = newBondSize;
        self.effectiveUpdateTime = uint64(now) + WAITING_PERIOD;
    }

    /**
    * @notice Returns the current bond size
    */
    function bondSize(Params memory self) internal view returns (uint128) {
        if (now < self.effectiveUpdateTime) {
            return self.previousBondSize;
        } else {
            return self.updatedBondSize;
        }
    }

    function validateBondSize(Params memory self, uint128 newBondSize) private view {
        uint128 currentBondSize = bondSize(self);
        require(newBondSize > 0, "Bond size cannot be zero");
        require(newBondSize >= currentBondSize / self.lowerBoundDivisor, "Bond size is too low");
        require(uint256(newBondSize) <= uint256(currentBondSize) * self.upperBoundMultiplier, "Bond size is too high");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/utils/ExitId.sol": {
      "content": "pragma solidity 0.5.11;

import "../../utils/Bits.sol";
import "../../utils/PosLib.sol";

library ExitId {
    using PosLib for PosLib.Position;
    using Bits for uint160;
    using Bits for uint256;

    /**
     * @notice Checks whether exitId is a standard exit ID
     */
    function isStandardExit(uint160 _exitId) internal pure returns (bool) {
        return _exitId.getBit(151) == 0;
    }

    /**
     * @notice Given transaction bytes and UTXO position, returns its exit ID
     * @dev Computation of a deposit ID is different to any other tx because txBytes of a deposit tx can be a non-unique value
     * @notice Output index must be within range 0 - 255
     * @param _isDeposit Defines whether the tx for the exitId is a deposit tx
     * @param _txBytes Transaction bytes
     * @param _utxoPos UTXO position of the exiting output
     * @return _standardExitId Unique ID of the standard exit
     *     Anatomy of returned value, most significant bits first:
     *     8-bits - output index
     *     1-bit - in-flight flag (0 for standard exit)
     *     151-bits - hash(tx) or hash(tx|utxo) for deposit
     */
    function getStandardExitId(
        bool _isDeposit,
        bytes memory _txBytes,
        PosLib.Position memory _utxoPos
    )
        internal
        pure
        returns (uint160)
    {
        if (_isDeposit) {
            bytes32 hashData = keccak256(abi.encodePacked(_txBytes, _utxoPos.encode()));
            return _computeStandardExitId(hashData, _utxoPos.outputIndex);
        }

        return _computeStandardExitId(keccak256(_txBytes), _utxoPos.outputIndex);
    }

    /**
    * @notice Given transaction bytes, returns in-flight exit ID
    * @param _txBytes Transaction bytes
    * @return Unique in-flight exit ID
    */
    function getInFlightExitId(bytes memory _txBytes) internal pure returns (uint160) {
        return uint160((uint256(keccak256(_txBytes)) >> 105).setBit(151));
    }

    function _computeStandardExitId(bytes32 _txhash, uint16 _outputIndex)
        private
        pure
        returns (uint160)
    {
        uint256 exitId = (uint256(_txhash) >> 105) | (uint256(_outputIndex) << 152);
        uint160 croppedExitId = uint160(exitId);

        require(uint256(croppedExitId) == exitId, "ExitId overflows");

        return croppedExitId;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/utils/ExitableTimestamp.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/math/Math.sol";

library ExitableTimestamp {
    struct Calculator {
        uint256 minExitPeriod;
    }

    /**
     * @notice Calculates the exitable timestamp for a mined transaction
     * @dev This is the main function when asking for exitable timestamp in most cases.
     *      The only exception is to calculate the exitable timestamp for a deposit output in standard exit.
     *      Should use the function 'calculateDepositTxOutputExitableTimestamp' for that case.
     */
    function calculateTxExitableTimestamp(
        Calculator memory _calculator,
        uint256 _now,
        uint256 _blockTimestamp
    )
        internal
        pure
        returns (uint64)
    {
        return uint64(Math.max(_blockTimestamp + (_calculator.minExitPeriod * 2), _now + _calculator.minExitPeriod));
    }

    /**
     * @notice Calculates the exitable timestamp for deposit transaction output for standard exit
     * @dev This function should only be used in standard exit for calculating exitable timestamp of a deposit output.
     *      For in-fight exit, the priority of a input tx which is a deposit tx should still be using the another function 'calculateTxExitableTimestamp'.
     *      See discussion here: https://git.io/Je4N5
     *      Reason of deposit output has different exitable timestamp: https://git.io/JecCV
     */
    function calculateDepositTxOutputExitableTimestamp(
        Calculator memory _calculator,
        uint256 _now
    )
        internal
        pure
        returns (uint64)
    {
        return uint64(_now + _calculator.minExitPeriod);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/utils/MoreVpFinalization.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../../framework/PlasmaFramework.sol";
import "../../framework/Protocol.sol";
import "../../utils/Merkle.sol";
import "../../utils/PosLib.sol";
import "../../transactions/GenericTransaction.sol";

/**
 * @notice Library to check finalization for MoreVP protocol
 * @dev This library assumes that the tx is of the GenericTransaction format
 */
library MoreVpFinalization {
    using PosLib for PosLib.Position;

    /**
    * @notice Checks whether a transaction is "standard finalized".
    *         For MoreVP, it means the transaction should be included in a plasma block.
    */
    function isStandardFinalized(
        PlasmaFramework framework,
        bytes memory txBytes,
        PosLib.Position memory txPos,
        bytes memory inclusionProof
    )
        internal
        view
        returns (bool)
    {
        require(txPos.outputIndex == 0, "Invalid transaction position");
        GenericTransaction.Transaction memory genericTx = GenericTransaction.decode(txBytes);
        uint8 protocol = framework.protocols(genericTx.txType);
        require(protocol == Protocol.MORE_VP(), "MoreVpFinalization: not a MoreVP protocol tx");

        (bytes32 root,) = framework.blocks(txPos.blockNum);
        require(root != bytes32(""), "Failed to get the root hash of the block num");

        return Merkle.checkMembership(
            txBytes, txPos.txIndex, root, inclusionProof
        );
    }

    /**
    * @notice Checks whether a transaction is "protocol finalized"
    *         For MoreVP, since it allows in-flight tx, so only checks for the existence of the transaction
    */
    function isProtocolFinalized(
        PlasmaFramework framework,
        bytes memory txBytes
    )
        internal
        view
        returns (bool)
    {
        if (txBytes.length == 0) {
            return false;
        }

        GenericTransaction.Transaction memory genericTx = GenericTransaction.decode(txBytes);
        uint8 protocol = framework.protocols(genericTx.txType);
        require(protocol == Protocol.MORE_VP(), "MoreVpFinalization: not a MoreVP protocol tx");

        return true;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/exits/utils/OutputId.sol": {
      "content": "pragma solidity 0.5.11;

library OutputId {
    /**
     * @notice Computes the output ID for a deposit tx
     * @dev Deposit tx bytes might not be unique because all inputs are empty
     *      Two deposits with the same output value would result in the same tx bytes
     *      As a result, we need to hash with utxoPos to ensure uniqueness
     * @param _txBytes Transaction bytes
     * @param _outputIndex Output index of the output
     * @param _utxoPosValue (Optional) UTXO position of the deposit output
     */
    function computeDepositOutputId(bytes memory _txBytes, uint256 _outputIndex, uint256 _utxoPosValue)
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(_txBytes, _outputIndex, _utxoPosValue));
    }

    /**
     * @notice Computes the output ID for normal (non-deposit) tx
     * @dev Since txBytes for non-deposit tx is unique, directly hash the txBytes with outputIndex
     * @param _txBytes Transaction bytes
     * @param _outputIndex Output index of the output
     */
    function computeNormalOutputId(bytes memory _txBytes, uint256 _outputIndex)
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(_txBytes, _outputIndex));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/BlockController.sol": {
      "content": "pragma solidity 0.5.11;

import "./models/BlockModel.sol";
import "./registries/VaultRegistry.sol";
import "../utils/OnlyFromAddress.sol";

/**
* @notice Controls the logic and functions for block submissions in PlasmaFramework
* @dev There are two types of blocks: child block and deposit block
*      Each child block has an interval of 'childBlockInterval'
*      The interval is preserved for deposits. Each deposit results in one deposit block.
*      For instance, a child block would be in block 1000 and the next deposit would result in block 1001.
*
*      Only the authority address can perform a block submission.
*      Details on limitations for the authority address can be found here: https://github.com/omisego/elixir-omg#managing-the-operator-address
*/
contract BlockController is OnlyFromAddress, VaultRegistry {
    address public authority;
    uint256 public childBlockInterval;
    uint256 public nextChildBlock;
    uint256 public nextDeposit;
    bool public isChildChainActivated;

    mapping (uint256 => BlockModel.Block) public blocks; // block number => Block data

    event BlockSubmitted(
        uint256 blknum
    );

    event ChildChainActivated(
        address authority
    );

    constructor(
        uint256 _interval,
        uint256 _minExitPeriod,
        uint256 _initialImmuneVaults,
        address _authority
    )
        public
        VaultRegistry(_minExitPeriod, _initialImmuneVaults)
    {
        authority = _authority;
        childBlockInterval = _interval;
        nextChildBlock = childBlockInterval;
        nextDeposit = 1;
        isChildChainActivated = false;
    }

    /**
     * @notice Activates the child chain so that child chain can start to submit child blocks to root chain
     * @notice Can only be called once by the authority.
     * @notice Sets isChildChainActivated to true and emits the ChildChainActivated event.
     * @dev This is a preserved action for authority account to start its nonce with 1.
     *      Child chain rely ethereum nonce to protect re-org: https://git.io/JecDG
     *      see discussion: https://git.io/JenaT, https://git.io/JecDO
     */
    function activateChildChain() external onlyFrom(authority) {
        require(isChildChainActivated == false, "Child chain already activated");
        isChildChainActivated = true;
        emit ChildChainActivated(authority);
    }

    /**
     * @notice Allows the authority to submit the Merkle root of a Plasma block
     * @dev emit BlockSubmitted event
     * @dev Block number jumps 'childBlockInterval' per submission
     * @dev See discussion in https://github.com/omisego/plasma-contracts/issues/233
     * @param _blockRoot Merkle root of the Plasma block
     */
    function submitBlock(bytes32 _blockRoot) external onlyFrom(authority) {
        require(isChildChainActivated == true, "Child chain has not been activated by authority address yet");
        uint256 submittedBlockNumber = nextChildBlock;

        blocks[submittedBlockNumber] = BlockModel.Block({
            root: _blockRoot,
            timestamp: block.timestamp
        });

        nextChildBlock += childBlockInterval;
        nextDeposit = 1;

        emit BlockSubmitted(submittedBlockNumber);
    }

    /**
     * @notice Submits a block for deposit
     * @dev Block number adds 1 per submission; it's possible to have at most 'childBlockInterval' deposit blocks between two child chain blocks
     * @param _blockRoot Merkle root of the Plasma block
     * @return The deposit block number
     */
    function submitDepositBlock(bytes32 _blockRoot) public onlyFromNonQuarantinedVault returns (uint256) {
        require(isChildChainActivated == true, "Child chain has not been activated by authority address yet");
        require(nextDeposit < childBlockInterval, "Exceeded limit of deposits per child block interval");

        uint256 blknum = nextDepositBlock();
        blocks[blknum] = BlockModel.Block({
            root : _blockRoot,
            timestamp : block.timestamp
        });

        nextDeposit++;
        return blknum;
    }

    function nextDepositBlock() public view returns (uint256) {
        return nextChildBlock - childBlockInterval + nextDeposit;
    }

    function isDeposit(uint256 blockNum) public view returns (bool) {
        require(blocks[blockNum].timestamp != 0, "Block does not exist");
        return blockNum % childBlockInterval != 0;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/ExitGameController.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./interfaces/IExitProcessor.sol";
import "./registries/ExitGameRegistry.sol";
import "./utils/PriorityQueue.sol";
import "./utils/ExitPriority.sol";
import "../utils/PosLib.sol";

/**
 * @notice Controls the logic and functions for ExitGame to interact with the PlasmaFramework
 *         Plasma M(ore)VP relies on exit priority to secure the user from invalid transactions
 *         The priority queue ensures the exit is processed with the exit priority
 *         For details, see the Plasma MVP spec: https://ethresear.ch/t/minimal-viable-plasma/426
 */
contract ExitGameController is ExitGameRegistry {
    // exit hashed (priority, vault id, token) => IExitProcessor
    mapping (bytes32 => IExitProcessor) public delegations;
    // hashed (vault id, token) => PriorityQueue
    mapping (bytes32 => PriorityQueue) public exitsQueues;
    // outputId => exitId
    mapping (bytes32 => uint160) public outputsFinalizations;
    bool private mutex = false;

    event ExitQueueAdded(
        uint256 vaultId,
        address token
    );

    event ProcessedExitsNum(
        uint256 processedNum,
        uint256 vaultId,
        address token
    );

    event ExitQueued(
        uint160 indexed exitId,
        uint256 priority
    );

    constructor(uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
        ExitGameRegistry(_minExitPeriod, _initialImmuneExitGames)
    {
    }

    /**
     * @dev Prevents reentrant calls by using a mutex.
     */
    modifier nonReentrant() {
        require(!mutex, "Reentrant call");
        mutex = true;
        _;
        assert(mutex);
        mutex = false;
    }

    /**
     * @notice Activates non reentrancy mode
     *         Guards against reentering into publicly accessible code that modifies state related to exits
     * @dev Accessible only from non quarantined exit games, uses a mutex
     */
    function activateNonReentrant() external onlyFromNonQuarantinedExitGame() {
        require(!mutex, "Reentrant call");
        mutex = true;
    }

    /**
     * @notice Deactivates non reentrancy mode
     * @dev Accessible only from non quarantined exit games, uses a mutex
     */
    function deactivateNonReentrant() external onlyFromNonQuarantinedExitGame() {
        assert(mutex);
        mutex = false;
    }

    /**
     * @notice Checks if the queue for a specified token was created
     * @param vaultId ID of the vault that handles the token
     * @param token Address of the token
     * @return bool Defines whether the queue for a token was created
     */
    function hasExitQueue(uint256 vaultId, address token) public view returns (bool) {
        bytes32 key = exitQueueKey(vaultId, token);
        return hasExitQueue(key);
    }

    /**
     * @notice Adds queue to the Plasma framework
     * @dev The queue is created as a new contract instance
     * @param vaultId ID of the vault
     * @param token Address of the token
     */
    function addExitQueue(uint256 vaultId, address token) external {
        require(vaultId != 0, "Vault ID must not be 0");
        bytes32 key = exitQueueKey(vaultId, token);
        require(!hasExitQueue(key), "Exit queue exists");
        exitsQueues[key] = new PriorityQueue();
        emit ExitQueueAdded(vaultId, token);
    }

    /**
     * @notice Enqueue exits from exit game contracts is a function that places the exit into the
     *         priority queue to enforce the priority of exit during 'processExits'
     * @dev emits ExitQueued event, which can be used to back trace the priority inside the queue
     * @dev Caller of this function should add "pragma experimental ABIEncoderV2;" on top of file
     * @dev Priority (exitableAt, txPos, exitId) must be unique per queue. Do not enqueue when the same priority is already in the queue.
     * @param vaultId Vault ID of the vault that stores exiting funds
     * @param token Token for the exit
     * @param exitableAt The earliest time a specified exit can be processed
     * @param txPos Transaction position for the exit priority. For SE it should be the exit tx, for IFE it should be the youngest input tx position.
     * @param exitId ID used by the exit processor contract to determine how to process the exit
     * @param exitProcessor The exit processor contract, called during "processExits"
     * @return A unique priority number computed for the exit
     */
    function enqueue(
        uint256 vaultId,
        address token,
        uint64 exitableAt,
        PosLib.Position calldata txPos,
        uint160 exitId,
        IExitProcessor exitProcessor
    )
        external
        onlyFromNonQuarantinedExitGame
        returns (uint256)
    {
        bytes32 key = exitQueueKey(vaultId, token);
        require(hasExitQueue(key), "The queue for the (vaultId, token) pair is not yet added to the Plasma framework");
        PriorityQueue queue = exitsQueues[key];

        uint256 priority = ExitPriority.computePriority(exitableAt, txPos, exitId);

        queue.insert(priority);

        bytes32 delegationKey = getDelegationKey(priority, vaultId, token);
        require(address(delegations[delegationKey]) == address(0), "The same priority is already enqueued");
        delegations[delegationKey] = exitProcessor;

        emit ExitQueued(exitId, priority);
        return priority;
    }

    /**
     * @notice Processes any exits that have completed the challenge period. Exits are processed according to the exit priority.
     * @dev Emits ProcessedExitsNum event
     * @param vaultId Vault ID of the vault that stores exiting funds
     * @param token The token type to process
     * @param topExitId Unique identifier for prioritizing the first exit to process. Set to zero to skip this check.
     * @param maxExitsToProcess Maximum number of exits to process
     * @return Total number of processed exits
     */
    function processExits(uint256 vaultId, address token, uint160 topExitId, uint256 maxExitsToProcess) external nonReentrant {
        bytes32 key = exitQueueKey(vaultId, token);
        require(hasExitQueue(key), "The token is not yet added to the Plasma framework");
        PriorityQueue queue = exitsQueues[key];
        require(queue.currentSize() > 0, "Exit queue is empty");

        uint256 uniquePriority = queue.getMin();
        uint160 exitId = ExitPriority.parseExitId(uniquePriority);
        require(topExitId == 0 || exitId == topExitId,
            "Top exit ID of the queue is different to the one specified");

        bytes32 delegationKey = getDelegationKey(uniquePriority, vaultId, token);
        IExitProcessor processor = delegations[delegationKey];
        uint256 processedNum = 0;

        while (processedNum < maxExitsToProcess && ExitPriority.parseExitableAt(uniquePriority) < block.timestamp) {
            delete delegations[delegationKey];
            queue.delMin();
            processedNum++;

            processor.processExit(exitId, vaultId, token);

            if (queue.currentSize() == 0) {
                break;
            }

            uniquePriority = queue.getMin();
            delegationKey = getDelegationKey(uniquePriority, vaultId, token);
            exitId = ExitPriority.parseExitId(uniquePriority);
            processor = delegations[delegationKey];
        }

        emit ProcessedExitsNum(processedNum, vaultId, token);
    }

    /**
     * @notice Checks whether any of the output with the given outputIds is already spent
     * @param _outputIds Output IDs to check
     */
    function isAnyInputFinalizedByOtherExit(bytes32[] calldata _outputIds, uint160 exitId) external view returns (bool) {
        for (uint i = 0; i < _outputIds.length; i++) {
            uint160 finalizedExitId = outputsFinalizations[_outputIds[i]];
            if (finalizedExitId != 0 && finalizedExitId != exitId) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Batch flags already spent outputs (only not already spent)
     * @param outputIds Output IDs to flag
     */
    function batchFlagOutputsFinalized(bytes32[] calldata outputIds, uint160 exitId) external onlyFromNonQuarantinedExitGame {
        for (uint i = 0; i < outputIds.length; i++) {
            require(outputIds[i] != bytes32(""), "Should not flag with empty outputId");
            if (outputsFinalizations[outputIds[i]] == 0) {
                outputsFinalizations[outputIds[i]] = exitId;
            }
        }
    }

    /**
     * @notice Flags a single output as spent if it is not flagged already
     * @param outputId The output ID to flag as spent
     */
    function flagOutputFinalized(bytes32 outputId, uint160 exitId) external onlyFromNonQuarantinedExitGame {
        require(outputId != bytes32(""), "Should not flag with empty outputId");
        if (outputsFinalizations[outputId] == 0) {
            outputsFinalizations[outputId] = exitId;
        }
    }

     /**
     * @notice Checks whether output with a given outputId is finalized
     * @param outputId Output ID to check
     */
    function isOutputFinalized(bytes32 outputId) external view returns (bool) {
        return outputsFinalizations[outputId] != 0;
    }

    function getNextExit(uint256 vaultId, address token) external view returns (uint256) {
        bytes32 key = exitQueueKey(vaultId, token);
        return exitsQueues[key].getMin();
    }

    function exitQueueKey(uint256 vaultId, address token) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(vaultId, token));
    }

    function hasExitQueue(bytes32 queueKey) private view returns (bool) {
        return address(exitsQueues[queueKey]) != address(0);
    }

    function getDelegationKey(uint256 priority, uint256 vaultId, address token) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(priority, vaultId, token));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/PlasmaFramework.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./BlockController.sol";
import "./ExitGameController.sol";
import "./registries/VaultRegistry.sol";
import "./registries/ExitGameRegistry.sol";

contract PlasmaFramework is VaultRegistry, ExitGameRegistry, ExitGameController, BlockController {
    uint256 public constant CHILD_BLOCK_INTERVAL = 1000;

    /**
     * The minimum finalization period is the Plasma guarantee that all exits are safe provided the user takes action within the specified time period
     * When the child chain is rogue, user should start their exit and challenge any invalid exit within this period
     * An exit can be processed/finalized after minimum two finalization periods from its inclusion position, unless it is an exit for a deposit,
     * which would use one finalization period, instead of two
     *
     * For the Abstract Layer Design, OmiseGO also uses some multitude of this period to update its framework
     * See also ExitGameRegistry.sol, VaultRegistry.sol, and Vault.sol for more information on the update waiting time (the quarantined period)
     *
     * MVP: https://ethresear.ch/t/minimal-viable-plasma/426
     * MoreVP: https://github.com/omisego/elixir-omg/blob/master/docs/morevp.md#timeline
     * Special period for deposit: https://git.io/JecCV
     */
    uint256 public minExitPeriod;
    address private maintainer;
    string public version;

    constructor(
        uint256 _minExitPeriod,
        uint256 _initialImmuneVaults,
        uint256 _initialImmuneExitGames,
        address _authority,
        address _maintainer
    )
        public
        BlockController(CHILD_BLOCK_INTERVAL, _minExitPeriod, _initialImmuneVaults, _authority)
        ExitGameController(_minExitPeriod, _initialImmuneExitGames)
    {
        minExitPeriod = _minExitPeriod;
        maintainer = _maintainer;
    }

    function getMaintainer() public view returns (address) {
        return maintainer;
    }

    /**
     * @notice Gets the semantic version of the current deployed contracts
    */
    function getVersion() external view returns (string memory) {
        return version;
    }
    
    /**
     * @notice Sets the semantic version of the current deployed contracts
     * @param _version is semver string
     */
    function setVersion(string memory _version) public onlyFrom(getMaintainer()) {
        version = _version;
    }
}"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/Protocol.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @notice Protocols for the PlasmaFramework
 */
library Protocol {
    uint8 constant internal MVP_VALUE = 1;
    uint8 constant internal MORE_VP_VALUE = 2;

    // solhint-disable-next-line func-name-mixedcase
    function MVP() internal pure returns (uint8) {
        return MVP_VALUE;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MORE_VP() internal pure returns (uint8) {
        return MORE_VP_VALUE;
    }

    function isValidProtocol(uint8 protocol) internal pure returns (bool) {
        return protocol == MVP_VALUE || protocol == MORE_VP_VALUE;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/interfaces/IExitProcessor.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @dev An interface that allows custom logic to process exits for different requirements.
 *      This interface is used to dispatch to each custom processor when 'processExits' is called on PlasmaFramework.
 */
interface IExitProcessor {
    /**
     * @dev Function interface for processing exits.
     * @param exitId Unique ID for exit per tx type
     * @param vaultId ID of the vault that funds the exit
     * @param token Address of the token contract
     */
    function processExit(uint160 exitId, uint256 vaultId, address token) external;
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/models/BlockModel.sol": {
      "content": "pragma solidity 0.5.11;

library BlockModel {
    /**
     * @notice Block data structure that is stored in the contract
     * @param root The Merkle root block hash of the Plasma blocks
     * @param timestamp The timestamp, in seconds, when the block is saved
     */
    struct Block {
        bytes32 root;
        uint256 timestamp;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/registries/ExitGameRegistry.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/utils/Address.sol";

import "../Protocol.sol";
import "../utils/Quarantine.sol";
import "../../utils/OnlyFromAddress.sol";

contract ExitGameRegistry is OnlyFromAddress {
    using Quarantine for Quarantine.Data;

    mapping(uint256 => address) private _exitGames; // txType => exit game contract address
    mapping(address => uint256) private _exitGameToTxType; // exit game contract address => tx type
    mapping(uint256 => uint8) private _protocols; // tx type => protocol (MVP/MORE_VP)
    Quarantine.Data private _exitGameQuarantine;

    event ExitGameRegistered(
        uint256 txType,
        address exitGameAddress,
        uint8 protocol
    );

    /**
     * @dev It takes at least 3 * minExitPeriod before each new exit game contract is able to start protecting existing transactions
     *      see: https://github.com/omisego/plasma-contracts/issues/172
     *           https://github.com/omisego/plasma-contracts/issues/197
     */
    constructor (uint256 _minExitPeriod, uint256 _initialImmuneExitGames)
        public
    {
        _exitGameQuarantine.quarantinePeriod = 4 * _minExitPeriod;
        _exitGameQuarantine.immunitiesRemaining = _initialImmuneExitGames;
    }

    /**
     * @notice A modifier to verify that the call is from a non-quarantined exit game
     */
    modifier onlyFromNonQuarantinedExitGame() {
        require(_exitGameToTxType[msg.sender] != 0, "The call is not from a registered exit game contract");
        require(!_exitGameQuarantine.isQuarantined(msg.sender), "ExitGame is quarantined");
        _;
    }

    /**
     * @notice interface to get the 'maintainer' address.
     * @dev see discussion here: https://git.io/Je8is
     */
    function getMaintainer() public view returns (address);

    /**
     * @notice Checks whether the contract is safe to use and is not under quarantine
     * @dev Exposes information about exit games quarantine
     * @param _contract Address of the exit game contract
     * @return boolean Whether the contract is safe to use and is not under quarantine
     */
    function isExitGameSafeToUse(address _contract) public view returns (bool) {
        return _exitGameToTxType[_contract] != 0 && !_exitGameQuarantine.isQuarantined(_contract);
    }

    /**
     * @notice Registers an exit game within the PlasmaFramework. Only the maintainer can call the function.
     * @dev Emits ExitGameRegistered event to notify clients
     * @param _txType The tx type where the exit game wants to register
     * @param _contract Address of the exit game contract
     * @param _protocol The transaction protocol, either 1 for MVP or 2 for MoreVP
     */
    function registerExitGame(uint256 _txType, address _contract, uint8 _protocol) public onlyFrom(getMaintainer()) {
        require(_txType != 0, "Should not register with tx type 0");
        require(Address.isContract(_contract), "Should not register with a non-contract address");
        require(_exitGames[_txType] == address(0), "The tx type is already registered");
        require(_exitGameToTxType[_contract] == 0, "The exit game contract is already registered");
        require(Protocol.isValidProtocol(_protocol), "Invalid protocol value");

        _exitGames[_txType] = _contract;
        _exitGameToTxType[_contract] = _txType;
        _protocols[_txType] = _protocol;
        _exitGameQuarantine.quarantine(_contract);

        emit ExitGameRegistered(_txType, _contract, _protocol);
    }

    /**
     * @notice Public getter for retrieving protocol with tx type
     */
    function protocols(uint256 _txType) public view returns (uint8) {
        return _protocols[_txType];
    }

    /**
     * @notice Public getter for retrieving exit game address with tx type
     */
    function exitGames(uint256 _txType) public view returns (address) {
        return _exitGames[_txType];
    }

    /**
     * @notice Public getter for retrieving tx type with exit game address
     */
    function exitGameToTxType(address _exitGame) public view returns (uint256) {
        return _exitGameToTxType[_exitGame];
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/registries/VaultRegistry.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/utils/Address.sol";

import "../utils/Quarantine.sol";
import "../../utils/OnlyFromAddress.sol";

contract VaultRegistry is OnlyFromAddress {
    using Quarantine for Quarantine.Data;

    mapping(uint256 => address) private _vaults; // vault id => vault address
    mapping(address => uint256) private _vaultToId; // vault address => vault id
    Quarantine.Data private _vaultQuarantine;

    event VaultRegistered(
        uint256 vaultId,
        address vaultAddress
    );

    /**
     * @dev It takes at least 2 minExitPeriod for each new vault contract to start.
     *      This is to protect deposit transactions already in mempool,
     *      and also make sure user only needs to SE within first week when invalid vault is registered.
     *      see: https://github.com/omisego/plasma-contracts/issues/412
     *           https://github.com/omisego/plasma-contracts/issues/173
     */
    constructor(uint256 _minExitPeriod, uint256 _initialImmuneVaults)
        public
    {
        _vaultQuarantine.quarantinePeriod = 2 * _minExitPeriod;
        _vaultQuarantine.immunitiesRemaining = _initialImmuneVaults;
    }

    /**
     * @notice interface to get the 'maintainer' address.
     * @dev see discussion here: https://git.io/Je8is
     */
    function getMaintainer() public view returns (address);

    /**
     * @notice A modifier to check that the call is from a non-quarantined vault
     */
    modifier onlyFromNonQuarantinedVault() {
        require(_vaultToId[msg.sender] > 0, "The call is not from a registered vault");
        require(!_vaultQuarantine.isQuarantined(msg.sender), "Vault is quarantined");
        _;
    }

    /**
     * @notice Register a vault within the PlasmaFramework. Only a maintainer can make the call.
     * @dev emits VaultRegistered event to notify clients
     * @param _vaultId The ID for the vault contract to register
     * @param _vaultAddress Address of the vault contract
     */
    function registerVault(uint256 _vaultId, address _vaultAddress) public onlyFrom(getMaintainer()) {
        require(_vaultId != 0, "Should not register with vault ID 0");
        require(Address.isContract(_vaultAddress), "Should not register with a non-contract address");
        require(_vaults[_vaultId] == address(0), "The vault ID is already registered");
        require(_vaultToId[_vaultAddress] == 0, "The vault contract is already registered");

        _vaults[_vaultId] = _vaultAddress;
        _vaultToId[_vaultAddress] = _vaultId;
        _vaultQuarantine.quarantine(_vaultAddress);

        emit VaultRegistered(_vaultId, _vaultAddress);
    }

    /**
     * @notice Public getter for retrieving vault address with vault ID
     */
    function vaults(uint256 _vaultId) public view returns (address) {
        return _vaults[_vaultId];
    }

    /**
     * @notice Public getter for retrieving vault ID with vault address
     */
    function vaultToId(address _vaultAddress) public view returns (uint256) {
        return _vaultToId[_vaultAddress];
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/utils/ExitPriority.sol": {
      "content": "pragma solidity 0.5.11;

import "../../utils/PosLib.sol";

library ExitPriority {

    using PosLib for PosLib.Position;

    /**
     * @dev Returns an exit priority for a given UTXO position and a unique ID.
     * The priority for Plasma M(ore)VP protocol is a combination of 'exitableAt' and 'txPos'.
     * Since 'exitableAt' only provides granularity of block, add 'txPos' to provide priority for a transaction.
     * @notice Detailed explanation on field lengths can be found at https://github.com/omisego/plasma-contracts/pull/303#discussion_r328850572
     * @param exitId Unique exit identifier
     * @return An exit priority
     *   Anatomy of returned value, most significant bits first
     *   42 bits  - timestamp in seconds (exitable_at); we can represent dates until year 141431
     *   54 bits  - blocknum * 10^5 + txindex; 54 bits represent all transactions for 85 years. Be aware that child chain block number jumps with the interval of CHILD_BLOCK_INTERVAL, which would be 1000 in production.
     *   160 bits - exit id
     */
    function computePriority(uint64 exitableAt, PosLib.Position memory txPos, uint160 exitId)
        internal
        pure
        returns (uint256)
    {
        return (uint256(exitableAt) << 214) | (txPos.getTxPositionForExitPriority() << 160) | uint256(exitId);
    }

    function parseExitableAt(uint256 priority) internal pure returns (uint64) {
        return uint64(priority >> 214);
    }

    function parseExitId(uint256 priority) internal pure returns (uint160) {
        // Exit ID uses only 160 least significant bits
        return uint160(priority);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/utils/PriorityQueue.sol": {
      "content": "pragma solidity 0.5.11;

import "../../utils/OnlyFromAddress.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title PriorityQueue
 * @dev Min-heap priority queue implementation
 */
contract PriorityQueue is OnlyFromAddress {
    using SafeMath for uint256;

    struct Queue {
        uint256[] heapList;
        uint256 currentSize;
    }

    Queue public queue;
    address public framework;

    constructor() public {
        queue.heapList = [0];
        queue.currentSize = 0;

        // it is expected that this should be called by PlasmaFramework
        // and only PlasmaFramework contract can add things to the queue
        framework = msg.sender;
    }

    /**
     * @notice Gets num of elements in the queue
     */
    function currentSize() external view returns (uint256) {
        return queue.currentSize;
    }

    /**
     * @notice Gets all elements in the queue
     */
    function heapList() external view returns (uint256[] memory) {
        return queue.heapList;
    }

    /**
     * @notice Inserts an element into the queue by the framework
     * @dev Does not perform deduplication
     */
    function insert(uint256 _element) external onlyFrom(framework) {
        queue.heapList.push(_element);
        queue.currentSize = queue.currentSize.add(1);
        percUp(queue, queue.currentSize);
    }

    /**
     * @notice Deletes the smallest element from the queue by the framework
     * @dev Fails when queue is empty
     * @return The smallest element in the priority queue
     */
    function delMin() external onlyFrom(framework) returns (uint256) {
        require(queue.currentSize > 0, "Queue is empty");
        uint256 retVal = queue.heapList[1];
        queue.heapList[1] = queue.heapList[queue.currentSize];
        delete queue.heapList[queue.currentSize];
        queue.currentSize = queue.currentSize.sub(1);
        percDown(queue, 1);
        queue.heapList.length = queue.heapList.length.sub(1);
        return retVal;
    }

    /**
     * @notice Returns the smallest element from the queue
     * @dev Fails when queue is empty
     * @return The smallest element in the priority queue
     */
    function getMin() external view returns (uint256) {
        require(queue.currentSize > 0, "Queue is empty");
        return queue.heapList[1];
    }

    function percUp(Queue storage self, uint256 pointer) private {
        uint256 i = pointer;
        uint256 j = i;
        uint256 newVal = self.heapList[i];
        while (newVal < self.heapList[i.div(2)]) {
            self.heapList[i] = self.heapList[i.div(2)];
            i = i.div(2);
        }
        if (i != j) {
            self.heapList[i] = newVal;
        }
    }

    function percDown(Queue storage self, uint256 pointer) private {
        uint256 i = pointer;
        uint256 j = i;
        uint256 newVal = self.heapList[i];
        uint256 mc = minChild(self, i);
        while (mc <= self.currentSize && newVal > self.heapList[mc]) {
            self.heapList[i] = self.heapList[mc];
            i = mc;
            mc = minChild(self, i);
        }
        if (i != j) {
            self.heapList[i] = newVal;
        }
    }

    function minChild(Queue storage self, uint256 i) private view returns (uint256) {
        if (i.mul(2).add(1) > self.currentSize) {
            return i.mul(2);
        } else {
            if (self.heapList[i.mul(2)] < self.heapList[i.mul(2).add(1)]) {
                return i.mul(2);
            } else {
                return i.mul(2).add(1);
            }
        }
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/framework/utils/Quarantine.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @notice Provides a way to quarantine (disable) contracts for a specified period of time
 * @dev The immunitiesRemaining member allows deployment to the platform with some
 * pre-verified contracts that don't get quarantined
 */
library Quarantine {
    struct Data {
        mapping(address => uint256) store;
        uint256 quarantinePeriod;
        uint256 immunitiesRemaining;
    }

    /**
     * @notice Checks whether a contract is quarantined
     */
    function isQuarantined(Data storage _self, address _contractAddress) internal view returns (bool) {
        return block.timestamp < _self.store[_contractAddress];
    }

    /**
     * @notice Places a contract into quarantine
     * @param _contractAddress The address of the contract
     */
    function quarantine(Data storage _self, address _contractAddress) internal {
        require(_contractAddress != address(0), "An empty address cannot be quarantined");
        require(_self.store[_contractAddress] == 0, "The contract is already quarantined");

        if (_self.immunitiesRemaining == 0) {
            _self.store[_contractAddress] = block.timestamp + _self.quarantinePeriod;
        } else {
            _self.immunitiesRemaining--;
        }
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/transactions/FungibleTokenOutputModel.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./GenericTransaction.sol";
import "../utils/RLPReader.sol";

/**
 * @notice Data structure and its decode function for ouputs of fungible token transactions
 */
library FungibleTokenOutputModel {
    using RLPReader for RLPReader.RLPItem;

    struct Output {
        uint256 outputType;
        bytes20 outputGuard;
        address token;
        uint256 amount;
    }

    /**
     * @notice Given a GenericTransaction.Output, decodes the `data` field.
     * The data field is an RLP list that must satisfy the following conditions:
     *      - It must have 3 elements: [`outputGuard`, `token`, `amount`]
     *      - `outputGuard` is a 20 byte long array
     *      - `token` is a 20 byte long array
     *      - `amount` must be an integer value with no leading zeros. It may not be zero.
     * @param genericOutput A GenericTransaction.Output
     * @return A fully decoded FungibleTokenOutputModel.Output struct
     */
    function decodeOutput(GenericTransaction.Output memory genericOutput)
        internal
        pure
        returns (Output memory)
    {
        RLPReader.RLPItem[] memory dataList = genericOutput.data.toList();
        require(dataList.length == 3, "Output data must have 3 items");

        Output memory outputData = Output({
            outputType: genericOutput.outputType,
            outputGuard: bytes20(dataList[0].toAddress()),
            token: dataList[1].toAddress(),
            amount: dataList[2].toUint()
        });

        require(outputData.amount != 0, "Output amount must not be 0");
        require(outputData.outputGuard != bytes20(0), "Output outputGuard must not be 0");
        return outputData;
    }

    /**
    * @dev Decodes and returns the output at a specific index in the transaction
    */
    function getOutput(GenericTransaction.Transaction memory transaction, uint16 outputIndex)
        internal
        pure
        returns
        (Output memory)
    {
        require(outputIndex < transaction.outputs.length, "Output index out of bounds");
        return decodeOutput(transaction.outputs[outputIndex]);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/transactions/GenericTransaction.sol": {
      "content": "pragma solidity 0.5.11;

import "../utils/RLPReader.sol";

/**
 * @title GenericTransaction
 * @notice GenericTransaction is a generic transaction format that makes few assumptions about the
 * content of the transaction. A transaction must satisy the following requirements:
 * - It must be a list of 5 items: [txType, inputs, outputs, txData, metaData]
 * - `txType` must be a uint not equal to zero
 * - inputs must be a list of RLP items.
 * - outputs must be a list of `Output`s
 * - an `Output` is a list of 2 items: [outputType, data]
 * - `Output.outputType` must be a uint not equal to zero
 * - `Output.data` is an RLP item. It can be a list.
 * - no assumptions are made about `txData`. Note that `txData` can be a list.
 * - `metaData` must be 32 bytes long.
 */
library GenericTransaction {

    uint8 constant private TX_NUM_ITEMS = 5;

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    struct Transaction {
        uint256 txType;
        RLPReader.RLPItem[] inputs;
        Output[] outputs;
        RLPReader.RLPItem txData;
        bytes32 metaData;
    }

    struct Output {
        uint256 outputType;
        RLPReader.RLPItem data;
    }

    /**
    * @dev Decodes an RLP encoded transaction into the generic format.
    */
    function decode(bytes memory transaction) internal pure returns (Transaction memory) {
        RLPReader.RLPItem[] memory rlpTx = transaction.toRlpItem().toList();
        require(rlpTx.length == TX_NUM_ITEMS, "Invalid encoding of transaction");
        uint256 txType = rlpTx[0].toUint();
        require(txType > 0, "Transaction type must not be 0");

        RLPReader.RLPItem[] memory outputList = rlpTx[2].toList();
        Output[] memory outputs = new Output[](outputList.length);
        for (uint i = 0; i < outputList.length; i++) {
            outputs[i] = decodeOutput(outputList[i]);
        }

        bytes32 metaData = rlpTx[4].toBytes32();

        return Transaction({
            txType: txType,
            inputs: rlpTx[1].toList(),
            outputs: outputs,
            txData: rlpTx[3],
            metaData: metaData
        });
    }

    /**
    * @dev Returns the output at a specific index in the transaction
    */
    function getOutput(Transaction memory transaction, uint16 outputIndex)
        internal
        pure
        returns (Output memory)
    {
        require(outputIndex < transaction.outputs.length, "Output index out of bounds");
        return transaction.outputs[outputIndex];
    }

    /**
    * @dev Decodes an RLPItem to an output
    */
    function decodeOutput(RLPReader.RLPItem memory encodedOutput)
        internal
        pure
        returns (Output memory)
    {
        RLPReader.RLPItem[] memory rlpList = encodedOutput.toList();
        require(rlpList.length == 2, "Output must have 2 items");

        Output memory output = Output({
            outputType: rlpList[0].toUint(),
            data: rlpList[1]
        });

        require(output.outputType != 0, "Output type must not be 0");
        return output;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/transactions/PaymentTransactionModel.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./FungibleTokenOutputModel.sol";
import "../utils/RLPReader.sol";

/**
 * @notice Data structure and its decode function for Payment transaction
 */
library PaymentTransactionModel {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant private _MAX_INPUT_NUM = 4;
    uint8 constant private _MAX_OUTPUT_NUM = 4;

    uint8 constant private ENCODED_LENGTH = 4;

    // solhint-disable-next-line func-name-mixedcase
    function MAX_INPUT_NUM() internal pure returns (uint8) {
        return _MAX_INPUT_NUM;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MAX_OUTPUT_NUM() internal pure returns (uint8) {
        return _MAX_OUTPUT_NUM;
    }

    struct Transaction {
        uint256 txType;
        bytes32[] inputs;
        FungibleTokenOutputModel.Output[] outputs;
        uint256 txData;
        bytes32 metaData;
    }

    /**
     * @notice Decodes a encoded byte array into a PaymentTransaction
     * The following rules about the rlp-encoded transaction are enforced:
     *      - `txType` must be an integer value with no leading zeros
     *      - `inputs` is an list of 0 to 4 elements
     *      - Each `input` is a 32 byte long array
     *      - An `input` may not be all zeros
     *      - `outputs` is an list of 0 to 4 elements
     *      - Each `output` is a list of 2 elements: [`outputType`, `data`]
     *      - `output.outputType` must be an integer value with no leading zeros
     *      - See FungibleTokenOutputModel for deatils on `output.data` encoding.
     *      - An `output` may not be null; A null output is one whose amount is zero
     * @param _tx An RLP-encoded transaction
     * @return A decoded PaymentTransaction struct
     */
    function decode(bytes memory _tx) internal pure returns (PaymentTransactionModel.Transaction memory) {
        return fromGeneric(GenericTransaction.decode(_tx));
    }

    /**
     * @notice Converts a GenericTransaction to a PaymentTransaction
     * @param genericTx A GenericTransaction.Transaction struct
     * @return A PaymentTransaction.Transaction struct
     */
    function fromGeneric(GenericTransaction.Transaction memory genericTx)
        internal
        pure
        returns (PaymentTransactionModel.Transaction memory)
    {
        require(genericTx.inputs.length <= _MAX_INPUT_NUM, "Transaction inputs num exceeds limit");
        require(genericTx.outputs.length != 0, "Transaction cannot have 0 outputs");
        require(genericTx.outputs.length <= _MAX_OUTPUT_NUM, "Transaction outputs num exceeds limit");

        bytes32[] memory inputs = new bytes32[](genericTx.inputs.length);
        for (uint i = 0; i < genericTx.inputs.length; i++) {
            bytes32 input = genericTx.inputs[i].toBytes32();
            require(uint256(input) != 0, "Null input not allowed");
            inputs[i] = input;
        }

        FungibleTokenOutputModel.Output[] memory outputs = new FungibleTokenOutputModel.Output[](genericTx.outputs.length);
        for (uint i = 0; i < genericTx.outputs.length; i++) {
            outputs[i] = FungibleTokenOutputModel.decodeOutput(genericTx.outputs[i]);
        }

        // txData is unused, it must be 0
        require(genericTx.txData.toUint() == 0, "txData must be 0");

        return Transaction({
            txType: genericTx.txType,
            inputs: inputs,
            outputs: outputs,
            txData: 0,
            metaData: genericTx.metaData
        });
    }

    /**
     * @notice Retrieve the 'owner' from the output, assuming the
     *         'outputGuard' field directly holds the owner's address
     */
    function getOutputOwner(FungibleTokenOutputModel.Output memory output) internal pure returns (address payable) {
        return address(uint160(output.outputGuard));
    }

    /**
     * @notice Gets output at provided index
     *
     */
    function getOutput(Transaction memory transaction, uint16 outputIndex) internal pure returns (FungibleTokenOutputModel.Output memory) {
        require(outputIndex < transaction.outputs.length, "Output index out of bounds");
        return transaction.outputs[outputIndex];
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/transactions/eip712Libs/PaymentEip712Lib.sol": {
      "content": "pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "../PaymentTransactionModel.sol";
import "../../utils/PosLib.sol";

/**
 * @title PaymentEip712Lib
 * @notice Utilities for hashing structural data for PaymentTransaction (see EIP-712)
 *
 * @dev EIP712: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
 *      We rely on the contract address to protect against replay attacks instead of using chain ID
 *      For more information, see https://github.com/omisego/plasma-contracts/issues/98#issuecomment-490792098
 */
library PaymentEip712Lib {
    using PosLib for PosLib.Position;

    bytes2 constant internal EIP191_PREFIX = "\x19\x01";

    bytes32 constant internal EIP712_DOMAIN_HASH = keccak256(
        "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
    );

    bytes32 constant internal TX_TYPE_HASH = keccak256(
        "Transaction(uint256 txType,Input input0,Input input1,Input input2,Input input3,Output output0,Output output1,Output output2,Output output3,uint256 txData,bytes32 metadata)Input(uint256 blknum,uint256 txindex,uint256 oindex)Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)"
    );

    bytes32 constant internal INPUT_TYPE_HASH = keccak256("Input(uint256 blknum,uint256 txindex,uint256 oindex)");
    bytes32 constant internal OUTPUT_TYPE_HASH = keccak256("Output(uint256 outputType,bytes20 outputGuard,address currency,uint256 amount)");
    bytes32 constant internal SALT = 0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83;

    bytes32 constant internal EMPTY_INPUT_HASH = keccak256(abi.encode(INPUT_TYPE_HASH, 0, 0, 0));
    bytes32 constant internal EMPTY_OUTPUT_HASH = keccak256(abi.encode(OUTPUT_TYPE_HASH, 0, bytes20(0x0), address(0x0), 0));

    struct Constants {
        // solhint-disable-next-line var-name-mixedcase
        bytes32 DOMAIN_SEPARATOR;
    }

    function initConstants(address _verifyingContract) internal pure returns (Constants memory) {
        // solhint-disable-next-line var-name-mixedcase
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_HASH,
            keccak256("OMG Network"),
            keccak256("1"),
            address(_verifyingContract),
            SALT
        ));

        return Constants({
            DOMAIN_SEPARATOR: DOMAIN_SEPARATOR
        });
    }

    // The 'encode(domainSeparator, message)' of the EIP712 specification
    // See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification
    function hashTx(Constants memory _eip712, PaymentTransactionModel.Transaction memory _tx)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            EIP191_PREFIX,
            _eip712.DOMAIN_SEPARATOR,
            _hashTx(_tx)
        ));
    }

    // The 'hashStruct(message)' function of transaction
    // See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-hashstruct
    function _hashTx(PaymentTransactionModel.Transaction memory _tx)
        private
        pure
        returns (bytes32)
    {
        // Pad empty value to input array
        bytes32[] memory inputs = new bytes32[](PaymentTransactionModel.MAX_INPUT_NUM());
        for (uint i = 0; i < _tx.inputs.length; i++) {
            inputs[i] = _tx.inputs[i];
        }

        // Pad empty value to output array
        FungibleTokenOutputModel.Output[] memory outputs = new FungibleTokenOutputModel.Output[](PaymentTransactionModel.MAX_OUTPUT_NUM());
        for (uint i = 0; i < _tx.outputs.length; i++) {
            outputs[i] = _tx.outputs[i];
        }

        return keccak256(abi.encode(
            TX_TYPE_HASH,
            _tx.txType,
            _hashInput(inputs[0]),
            _hashInput(inputs[1]),
            _hashInput(inputs[2]),
            _hashInput(inputs[3]),
            _hashOutput(outputs[0]),
            _hashOutput(outputs[1]),
            _hashOutput(outputs[2]),
            _hashOutput(outputs[3]),
            _tx.txData,
            _tx.metaData
        ));
    }

    function _hashInput(bytes32 _input) private pure returns (bytes32) {
        uint256 inputUtxoValue = uint256(_input);
        if (inputUtxoValue == 0) {
            return EMPTY_INPUT_HASH;
        }

        PosLib.Position memory utxo = PosLib.decode(inputUtxoValue);
        return keccak256(abi.encode(
            INPUT_TYPE_HASH,
            utxo.blockNum,
            utxo.txIndex,
            uint256(utxo.outputIndex)
        ));
    }

    function _hashOutput(FungibleTokenOutputModel.Output memory _output)
        private
        pure
        returns (bytes32)
    {
        if (_output.amount == 0) {
            return EMPTY_OUTPUT_HASH;
        }

        return keccak256(abi.encode(
            OUTPUT_TYPE_HASH,
            _output.outputType,
            _output.outputGuard,
            _output.token,
            _output.amount
        ));
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/Bits.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @title Bits
 * @dev Operations on individual bits of a word
 */
library Bits {
    /*
     * Storage
     */

    uint constant internal ONE = uint(1);

    /*
     * Internal functions
     */
    /**
     * @dev Sets the bit at the given '_index' in '_self' to '1'
     * @param _self Uint to modify
     * @param _index Index of the bit to set
     * @return The modified value
     */
    function setBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint)
    {
        return _self | ONE << _index;
    }

    /**
     * @dev Sets the bit at the given '_index' in '_self' to '0'
     * @param _self Uint to modify
     * @param _index Index of the bit to set
     * @return The modified value
     */
    function clearBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint)
    {
        return _self & ~(ONE << _index);
    }

    /**
     * @dev Returns the bit at the given '_index' in '_self'
     * @param _self Uint to check
     * @param _index Index of the bit to retrieve
     * @return The value of the bit at '_index'
     */
    function getBit(uint _self, uint8 _index)
        internal
        pure
        returns (uint8)
    {
        return uint8(_self >> _index & 1);
    }

    /**
     * @dev Checks if the bit at the given '_index' in '_self' is '1'
     * @param _self Uint to check
     * @param _index Index of the bit to check
     * @return True, if the bit is '0'; otherwise, False
     */
    function bitSet(uint _self, uint8 _index)
        internal
        pure
        returns (bool)
    {
        return getBit(_self, _index) == 1;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/FailFastReentrancyGuard.sol": {
      "content": "pragma solidity 0.5.11;

import "../framework/ExitGameController.sol";

/**
 * @notice Reentrancy guard that fails immediately when a reentrace occurs
 *         Works on multi-contracts level by activating and deactivating a reentrancy guard kept in plasma framework's state
 */
contract FailFastReentrancyGuard {

    /**
     * @dev Prevents reentrant calls by using a mutex.
     */
    modifier nonReentrant(ExitGameController exitGameController) {
        exitGameController.activateNonReentrant();
        _;
        exitGameController.deactivateNonReentrant();
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/Merkle.sol": {
      "content": "pragma solidity 0.5.11;

/**
 * @title Merkle
 * @dev Library for working with Merkle trees
 */
library Merkle {
    byte private constant LEAF_SALT = 0x00;
    byte private constant NODE_SALT = 0x01;

    /**
     * @notice Checks that a leaf hash is contained in a root hash
     * @param leaf Leaf hash to verify
     * @param index Position of the leaf hash in the Merkle tree
     * @param rootHash Root of the Merkle tree
     * @param proof A Merkle proof demonstrating membership of the leaf hash
     * @return True, if the leaf hash is in the Merkle tree; otherwise, False
    */
    function checkMembership(bytes memory leaf, uint256 index, bytes32 rootHash, bytes memory proof)
        internal
        pure
        returns (bool)
    {
        require(proof.length != 0, "Merkle proof must not be empty");
        require(proof.length % 32 == 0, "Length of Merkle proof must be a multiple of 32");

        // see https://github.com/omisego/plasma-contracts/issues/546
        require(index < 2**(proof.length/32), "Index does not match the length of the proof");

        bytes32 proofElement;
        bytes32 computedHash = keccak256(abi.encodePacked(LEAF_SALT, leaf));
        uint256 j = index;
        // Note: We're skipping the first 32 bytes of `proof`, which holds the size of the dynamically sized `bytes`
        for (uint256 i = 32; i <= proof.length; i += 32) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                proofElement := mload(add(proof, i))
            }
            if (j % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(NODE_SALT, computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(NODE_SALT, proofElement, computedHash));
            }
            j = j / 2;
        }

        return computedHash == rootHash;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/OnlyFromAddress.sol": {
      "content": "pragma solidity 0.5.11;

contract OnlyFromAddress {

    modifier onlyFrom(address caller) {
        require(msg.sender == caller, "Caller address is unauthorized");
        _;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/OnlyWithValue.sol": {
      "content": "pragma solidity 0.5.11;

contract OnlyWithValue {
    modifier onlyWithValue(uint256 _value) {
        require(msg.value == _value, "Input value must match msg.value");
        _;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/PosLib.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @dev UTXO position = (blknum * BLOCK_OFFSET + txIndex * TX_OFFSET + outputIndex).
 * TX position = (blknum * BLOCK_OFFSET + txIndex * TX_OFFSET)
 */
library PosLib {
    struct Position {
        uint64 blockNum;
        uint16 txIndex;
        uint16 outputIndex;
    }

    uint256 constant internal BLOCK_OFFSET = 1000000000;
    uint256 constant internal TX_OFFSET = 10000;
    
    uint256 constant internal MAX_OUTPUT_INDEX = TX_OFFSET - 1;
    // since we are using merkle tree of depth 16, max tx index size is 2^16 - 1
    uint256 constant internal MAX_TX_INDEX = 2 ** 16 - 1;
    // in ExitPriority, only 54 bits are reserved for both blockNum and txIndex
    uint256 constant internal MAX_BLOCK_NUM = ((2 ** 54 - 1) - MAX_TX_INDEX) / (BLOCK_OFFSET / TX_OFFSET);

    /**
     * @notice Returns transaction position which is an utxo position of zero index output
     * @param pos UTXO position of the output
     * @return Position of a transaction
     */
    function toStrictTxPos(Position memory pos)
        internal
        pure
        returns (Position memory)
    {
        return Position(pos.blockNum, pos.txIndex, 0);
    }

    /**
     * @notice Used for calculating exit priority
     * @param pos UTXO position for the output
     * @return Identifier of the transaction
     */
    function getTxPositionForExitPriority(Position memory pos)
        internal
        pure
        returns (uint256)
    {
        return encode(pos) / TX_OFFSET;
    }

    /**
     * @notice Encodes a position
     * @param pos Position
     * @return Position encoded as an integer
     */
    function encode(Position memory pos) internal pure returns (uint256) {
        require(pos.outputIndex <= MAX_OUTPUT_INDEX, "Invalid output index");
        require(pos.blockNum <= MAX_BLOCK_NUM, "Invalid block number");

        return pos.blockNum * BLOCK_OFFSET + pos.txIndex * TX_OFFSET + pos.outputIndex;
    }

    /**
     * @notice Decodes a position from an integer value
     * @param pos Encoded position
     * @return Position
     */
    function decode(uint256 pos) internal pure returns (Position memory) {
        uint256 blockNum = pos / BLOCK_OFFSET;
        uint256 txIndex = (pos % BLOCK_OFFSET) / TX_OFFSET;
        uint16 outputIndex = uint16(pos % TX_OFFSET);

        require(blockNum <= MAX_BLOCK_NUM, "blockNum exceeds max size allowed in PlasmaFramework");
        require(txIndex <= MAX_TX_INDEX, "txIndex exceeds the size of uint16");
        return Position(uint64(blockNum), uint16(txIndex), outputIndex);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/RLPReader.sol": {
      "content": "/**
 * @author Hamdi Allam hamdi.allam97@gmail.com
 * @notice RLP decoding library forked from https://github.com/hamdiallam/Solidity-RLP
 * @dev Some changes that were made to the library are:
 *      - Added more test cases from https://github.com/ethereum/tests/tree/master/RLPTests
 *      - Created more custom invalid test cases
 *      - Added more checks to ensure the decoder reads within bounds of the input length
 *      - Moved utility functions necessary to run some of the tests to the RLPMock.sol
*/

pragma solidity 0.5.11;

library RLPReader {
    uint8 constant internal STRING_SHORT_START = 0x80;
    uint8 constant internal STRING_LONG_START  = 0xb8;
    uint8 constant internal LIST_SHORT_START   = 0xc0;
    uint8 constant internal LIST_LONG_START    = 0xf8;
    uint8 constant internal MAX_SHORT_LEN      = 55;
    uint8 constant internal WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    /**
     * @notice Convert a dynamic bytes array into an RLPItem
     * @param item RLP encoded bytes
     * @return An RLPItem
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /**
    * @notice Convert a dynamic bytes array into a list of RLPItems
    * @param item RLP encoded list in bytes
    * @return A list of RLPItems
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item), "Item is not a list");

        (uint256 listLength, uint256 offset) = decodeLengthAndOffset(item.memPtr);
        require(listLength == item.len, "Decoded RLP length for list is invalid");

        uint256 items = countEncodedItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 dataMemPtr = item.memPtr + offset;
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            (dataLen, ) = decodeLengthAndOffset(dataMemPtr);
            result[i] = RLPItem(dataLen, dataMemPtr);
            dataMemPtr = dataMemPtr + dataLen;
        }

        return result;
    }

    /**
    * @notice Check whether the RLPItem is either a list
    * @param item RLP encoded list in bytes
    * @return A boolean whether the RLPItem is a list
    */
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /**
     * @notice Create an address from a RLPItem
     * @dev Function is not a standard RLP decoding function and it used to decode to the Solidity native address type
     * @param item RLPItem
     */
    function toAddress(RLPItem memory item) internal pure returns (address) {
        require(item.len == 21, "Item length must be 21");
        require(!isList(item), "Item must not be a list");

        (uint256 itemLen, uint256 offset) = decodeLengthAndOffset(item.memPtr);
        require(itemLen == 21, "Decoded item length must be 21");

        uint256 dataMemPtr = item.memPtr + offset;
        uint256 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(dataMemPtr)
            // right shift by 12 to make bytes20
            result := div(result, exp(256, 12))
        }

        return address(result);
    }

    /**
     * @notice Create a uint256 from a RLPItem. Leading zeros are invalid.
     * @dev Function is not a standard RLP decoding function and it used to decode to the Solidity native uint256 type
     * @param item RLPItem
     */
    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33, "Item length must be between 1 and 33 bytes");
        require(!isList(item), "Item must not be a list");
        (uint256 itemLen, uint256 offset) = decodeLengthAndOffset(item.memPtr);
        require(itemLen == item.len, "Decoded item length must be equal to the input data length");

        uint256 dataLen = itemLen - offset;

        uint result;
        uint dataByte0;
        uint dataMemPtr = item.memPtr + offset;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(dataMemPtr)
            dataByte0 := byte(0, result)
            // shift to the correct location if necessary
            if lt(dataLen, WORD_SIZE) {
                result := div(result, exp(256, sub(WORD_SIZE, dataLen)))
            }
        }
        // Special case: scalar 0 should be encoded as 0x80 and _not_ as 0x00
        require(!(dataByte0 == 0 && offset == 0), "Scalar 0 should be encoded as 0x80");

        // Disallow leading zeros
        require(!(dataByte0 == 0 && dataLen > 1), "Leading zeros are invalid");

        return result;
    }

    /**
     * @notice Create a bytes32 from a RLPItem
    * @dev Function is not a standard RLP decoding function and it used to decode to the Solidity native bytes32 type
     * @param item RLPItem
     */
    function toBytes32(RLPItem memory item) internal pure returns (bytes32) {
        // 1 byte for the length prefix
        require(item.len == 33, "Item length must be 33");
        require(!isList(item), "Item must not be a list");

        (uint256 itemLen, uint256 offset) = decodeLengthAndOffset(item.memPtr);
        require(itemLen == 33, "Decoded item length must be 33");

        uint256 dataMemPtr = item.memPtr + offset;
        bytes32 result;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(dataMemPtr)
        }

        return result;
    }

    /**
    * @notice Counts the number of payload items inside an RLP encoded list
    * @param item RLPItem
    * @return The number of items in a inside an RLP encoded list
    */
    function countEncodedItems(RLPItem memory item) private pure returns (uint256) {
        uint256 count = 0;
        (, uint256 offset) = decodeLengthAndOffset(item.memPtr);
        uint256 currPtr = item.memPtr + offset;
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            (uint256 currLen, ) = decodeLengthAndOffset(currPtr);
            currPtr = currPtr + currLen;
            require(currPtr <= endPtr, "Invalid decoded length of RLP item found during counting items in a list");
            count++;
        }

        return count;
    }

    /**
     * @notice Decodes the RLPItem's length and offset.
     * @dev This function is dangerous. Ensure that the returned length is within bounds that memPtr points to.
     * @param memPtr Pointer to the dynamic bytes array in memory
     * @return The length of the RLPItem (including the length field) and the offset of the payload
     */
    function decodeLengthAndOffset(uint256 memPtr) internal pure returns (uint256, uint256) {
        uint256 decodedLength;
        uint256 offset;
        uint256 byte0;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            // Item is a single byte
            decodedLength = 1;
            offset = 0;
        } else if (STRING_SHORT_START <= byte0 && byte0 < STRING_LONG_START) {
            // The range of the first byte is between 0x80 and 0xb7 therefore it is a short string
            // decodedLength is between 1 and 56 bytes
            decodedLength = (byte0 - STRING_SHORT_START) + 1;
            if (decodedLength == 2){
                uint256 byte1;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    byte1 := byte(0, mload(add(memPtr, 1)))
                }
                // A single byte below 0x80 must be encoded as itself.
                require(byte1 >= STRING_SHORT_START, "Invalid short string encoding");
            }
            offset = 1;
        } else if (STRING_LONG_START <= byte0 && byte0 < LIST_SHORT_START) {
            // The range of the first byte is between 0xb8 and 0xbf therefore it is a long string
            // lengthLen is between 1 and 8 bytes
            // dataLen is greater than 55 bytes
            uint256 dataLen;
            uint256 byte1;
            uint256 lengthLen;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                lengthLen := sub(byte0, 0xb7) // The length of the length of the payload is encoded in the first byte.
                memPtr := add(memPtr, 1) // skip over the first byte

                // right shift to the correct position
                dataLen := div(mload(memPtr), exp(256, sub(WORD_SIZE, lengthLen)))
                decodedLength := add(dataLen, add(lengthLen, 1))
                byte1 := byte(0, mload(memPtr))
            }

            // Check that the length has no leading zeros
            require(byte1 != 0, "Invalid leading zeros in length of the length for a long string");
            // Check that the value of length > MAX_SHORT_LEN
            require(dataLen > MAX_SHORT_LEN, "Invalid length for a long string");
            // Calculate the offset
            offset = lengthLen + 1;
        } else if (LIST_SHORT_START <= byte0 && byte0 < LIST_LONG_START) {
            // The range of the first byte is between 0xc0 and 0xf7 therefore it is a short list
            // decodedLength is between 1 and 56 bytes
            decodedLength = (byte0 - LIST_SHORT_START) + 1;
            offset = 1;
        } else {
            // The range of the first byte is between 0xf8 and 0xff therefore it is a long list
            // lengthLen is between 1 and 8 bytes
            // dataLen is greater than 55 bytes
            uint256 dataLen;
            uint256 byte1;
            uint256 lengthLen;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                lengthLen := sub(byte0, 0xf7) // The length of the length of the payload is encoded in the first byte.
                memPtr := add(memPtr, 1) // skip over the first byte

                // right shift to the correct position
                dataLen := div(mload(memPtr), exp(256, sub(WORD_SIZE, lengthLen)))
                decodedLength := add(dataLen, add(lengthLen, 1))
                byte1 := byte(0, mload(memPtr))
            }

            // Check that the length has no leading zeros
            require(byte1 != 0, "Invalid leading zeros in length of the length for a long list");
            // Check that the value of length > MAX_SHORT_LEN
            require(dataLen > MAX_SHORT_LEN, "Invalid length for a long list");
            // Calculate the offset
            offset = lengthLen + 1;
        }

        return (decodedLength, offset);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/utils/SafeEthTransfer.sol": {
      "content": "pragma solidity 0.5.11;

/**
* @notice Utility library to safely transfer ETH
* @dev transfer is no longer the recommended way to do ETH transfer.
*      see issue: https://github.com/omisego/plasma-contracts/issues/312
*
*      This library limits the amount of gas used for external calls with value to protect against potential DOS/griefing attacks that try to use up all the gas.
*      see issue: https://github.com/omisego/plasma-contracts/issues/385
*/
library SafeEthTransfer {
    /**
     * @notice Try to transfer eth without using more gas than `gasStipend`.
     *         Reverts if it fails to transfer the ETH.
     * @param receiver the address to receive ETH
     * @param amount the amount of ETH (in wei) to transfer
     * @param gasStipend the maximum amount of gas to be used for the call
     */
    function transferRevertOnError(address payable receiver, uint256 amount, uint256 gasStipend)
        internal
    {
        bool success = transferReturnResult(receiver, amount, gasStipend);
        require(success, "SafeEthTransfer: failed to transfer ETH");
    }

    /**
     * @notice Transfer ETH without using more gas than the `gasStipend`.
     *         Returns whether the transfer call is successful or not.
     * @dev EVM will revert with "out of gas" error if there is not enough gas left for the call
     * @param receiver the address to receive ETH
     * @param amount the amount of ETH (in wei) to transfer
     * @param gasStipend the maximum amount of gas to be used during the transfer call
     * @return a flag showing the call is successful or not
     */
    function transferReturnResult(address payable receiver, uint256 amount, uint256 gasStipend)
        internal
        returns (bool)
    {
        (bool success, ) = receiver.call.gas(gasStipend).value(amount)("");
        return success;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/Erc20Vault.sol": {
      "content": "pragma solidity 0.5.11;

import "./Vault.sol";
import "./verifiers/IErc20DepositVerifier.sol";
import "../framework/PlasmaFramework.sol";

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract Erc20Vault is Vault {
    using SafeERC20 for IERC20;

    event Erc20Withdrawn(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    event DepositCreated(
        address indexed depositor,
        uint256 indexed blknum,
        address indexed token,
        uint256 amount
    );

    constructor(PlasmaFramework _framework) public Vault(_framework) {}

    /**
     * @notice Deposits approved amount of ERC20 token(s) into the contract
     * Once the deposit is recognized, the owner (depositor) can transact on the OmiseGO Network
     * The approve function of the ERC20 token contract must be called before calling this function
     * for at least the amount that is deposited into the contract
     * @param depositTx RLP-encoded transaction to act as the deposit
     */
    function deposit(bytes calldata depositTx) external {
        address depositVerifier = super.getEffectiveDepositVerifier();
        require(depositVerifier != address(0), "Deposit verifier has not been set");

        (address depositor, address token, uint256 amount) = IErc20DepositVerifier(depositVerifier)
            .verify(depositTx, msg.sender, address(this));

        IERC20(token).safeTransferFrom(depositor, address(this), amount);

        uint256 blknum = super.submitDepositBlock(depositTx);

        emit DepositCreated(msg.sender, blknum, token, amount);
    }

    /**
    * @notice Withdraw ERC20 tokens that have successfully exited from the OmiseGO Network
    * @param receiver Address of the recipient
    * @param token Address of ERC20 token contract
    * @param amount Amount to transfer
    */
    function withdraw(address payable receiver, address token, uint256 amount) external onlyFromNonQuarantinedExitGame {
        IERC20(token).safeTransfer(receiver, amount);
        emit Erc20Withdrawn(receiver, token, amount);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/EthVault.sol": {
      "content": "pragma solidity 0.5.11;

import "./Vault.sol";
import "./verifiers/IEthDepositVerifier.sol";
import "../framework/PlasmaFramework.sol";
import "../utils/SafeEthTransfer.sol";

contract EthVault is Vault {
    event EthWithdrawn(
        address indexed receiver,
        uint256 amount
    );

    event WithdrawFailed(
        address indexed receiver,
        uint256 amount
    );

    event DepositCreated(
        address indexed depositor,
        uint256 indexed blknum,
        address indexed token,
        uint256 amount
    );

    uint256 public safeGasStipend;

    constructor(PlasmaFramework _framework, uint256 _safeGasStipend) public Vault(_framework) {
        safeGasStipend = _safeGasStipend;
    }

    /**
     * @notice Allows a user to deposit ETH into the contract
     * Once the deposit is recognized, the owner may transact on the OmiseGO Network
     * @param _depositTx RLP-encoded transaction to act as the deposit
     */
    function deposit(bytes calldata _depositTx) external payable {
        address depositVerifier = super.getEffectiveDepositVerifier();
        require(depositVerifier != address(0), "Deposit verifier has not been set");

        IEthDepositVerifier(depositVerifier).verify(_depositTx, msg.value, msg.sender);
        uint256 blknum = super.submitDepositBlock(_depositTx);

        emit DepositCreated(msg.sender, blknum, address(0), msg.value);
    }

    /**
    * @notice Withdraw ETH that has successfully exited from the OmiseGO Network
    * @dev We do not want to block exit queue if a transfer is unsuccessful, so we don't revert on transfer error.
    *      However, if there is not enough gas left for the safeGasStipend, then the EVM _will_ revert with an 'out of gas' error.
    *      If this happens, the user should retry with higher gas.
    * @param receiver Address of the recipient
    * @param amount The amount of ETH to transfer
    */
    function withdraw(address payable receiver, uint256 amount) external onlyFromNonQuarantinedExitGame {
        bool success = SafeEthTransfer.transferReturnResult(receiver, amount, safeGasStipend);
        if (success) {
            emit EthWithdrawn(receiver, amount);
        } else {
            emit WithdrawFailed(receiver, amount);
        }
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/Vault.sol": {
      "content": "pragma solidity 0.5.11;

import "../framework/PlasmaFramework.sol";
import "../utils/OnlyFromAddress.sol";

/**
 * @notice Base contract for vault implementation
 * @dev This is the functionality to swap "deposit verifier"
 *      Setting a new deposit verifier allows an upgrade to a new deposit tx type without upgrading the vault
 */
contract Vault is OnlyFromAddress {

    byte private constant LEAF_SALT = 0x00;
    byte private constant NODE_SALT = 0x01;

    event SetDepositVerifierCalled(address nextDepositVerifier);
    PlasmaFramework internal framework;
    bytes32[16] internal zeroHashes; // Pre-computes zero hashes to be used for building merkle tree for deposit block

    /**
     * @notice Stores deposit verifier contract addresses; first contract address is effective until the
     *  `newDepositVerifierMaturityTimestamp`; second contract address becomes effective after that timestamp
    */
    address[2] public depositVerifiers;
    uint256 public newDepositVerifierMaturityTimestamp = 2 ** 255; // point far in the future

    constructor(PlasmaFramework _framework) public {
        framework = _framework;
        zeroHashes = getZeroHashes();
    }

    /**
     * @dev Pre-computes zero hashes to be used for building Merkle tree for deposit block
     */
    function getZeroHashes() private pure returns (bytes32[16] memory) {
        bytes32[16] memory hashes;
        bytes32 zeroHash = keccak256(abi.encodePacked(LEAF_SALT, uint256(0)));
        for (uint i = 0; i < 16; i++) {
            hashes[i] = zeroHash;
            zeroHash = keccak256(abi.encodePacked(NODE_SALT, zeroHash, zeroHash));
        }
        return hashes;
    }

    /**
     * @notice Checks whether the call originates from a non-quarantined exit game contract
    */
    modifier onlyFromNonQuarantinedExitGame() {
        require(
            ExitGameRegistry(framework).isExitGameSafeToUse(msg.sender),
            "Called from a non-registered or quarantined exit game contract"
        );
        _;
    }

    /**
     * @notice Sets the deposit verifier contract, which may be called only by the operator
     * @dev emit SetDepositVerifierCalled
     * @dev When one contract is already set, the next one is effective after 2 * MIN_EXIT_PERIOD.
     *      This is to protect deposit transactions already in mempool,
     *      and also make sure user only needs to SE within first week when invalid vault is registered.
     *
     *      see: https://github.com/omisego/plasma-contracts/issues/412
     *           https://github.com/omisego/plasma-contracts/issues/173
     *
     * @param _verifier Address of the verifier contract
     */
    function setDepositVerifier(address _verifier) public onlyFrom(framework.getMaintainer()) {
        require(_verifier != address(0), "Cannot set an empty address as deposit verifier");

        if (depositVerifiers[0] != address(0)) {
            depositVerifiers[0] = getEffectiveDepositVerifier();
            depositVerifiers[1] = _verifier;
            newDepositVerifierMaturityTimestamp = now + 2 * framework.minExitPeriod();
        } else {
            depositVerifiers[0] = _verifier;
        }

        emit SetDepositVerifierCalled(_verifier);
    }

    /**
     * @notice Retrieves the currently effective deposit verifier contract address
     * @return Contract address of the deposit verifier
     */
    function getEffectiveDepositVerifier() public view returns (address) {
        if (now < newDepositVerifierMaturityTimestamp) {
            return depositVerifiers[0];
        } else {
            return depositVerifiers[1];
        }
    }

    /**
     * @notice Generate and submit a deposit block root to the PlasmaFramework
     * @dev Designed to be called by the contract that inherits Vault
     */
    function submitDepositBlock(bytes memory depositTx) internal returns (uint256) {
        bytes32 root = getDepositBlockRoot(depositTx);

        uint256 depositBlkNum = framework.submitDepositBlock(root);
        return depositBlkNum;
    }

    function getDepositBlockRoot(bytes memory depositTx) private view returns (bytes32) {
        bytes32 root = keccak256(abi.encodePacked(LEAF_SALT, depositTx));
        for (uint i = 0; i < 16; i++) {
            root = keccak256(abi.encodePacked(NODE_SALT, root, zeroHashes[i]));
        }
        return root;
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/verifiers/Erc20DepositVerifier.sol": {
      "content": "pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "./IErc20DepositVerifier.sol";
import {PaymentTransactionModel as DepositTx} from "../../transactions/PaymentTransactionModel.sol";

/**
 * @notice Implementation of Erc20 deposit verifier using payment transaction as the deposit tx
 */
contract Erc20DepositVerifier is IErc20DepositVerifier {
    uint256 public depositTxType;
    uint256 public supportedOutputType;

    constructor(uint256 txType, uint256 outputType) public {
        depositTxType = txType;
        supportedOutputType = outputType;
    }

    /**
     * @notice Overrides the function of IErc20DepositVerifier and implements the verification logic
     *         for payment transaction
     * @dev Vault address must be approved to transfer from the sender address before doing the deposit
     * @return Verified (owner, token, amount) of the deposit ERC20 token data
     */
    function verify(bytes calldata depositTx, address sender, address vault)
        external
        view
        returns (
            address owner,
            address token,
            uint256 amount
        )
    {
        DepositTx.Transaction memory decodedTx = DepositTx.decode(depositTx);

        require(decodedTx.txType == depositTxType, "Invalid transaction type");

        require(decodedTx.inputs.length == 0, "Deposit must have no inputs");

        require(decodedTx.outputs.length == 1, "Deposit must have exactly one output");
        require(decodedTx.outputs[0].token != address(0), "Invalid output currency (ETH)");
        require(decodedTx.outputs[0].outputType == supportedOutputType, "Invalid output type");

        address depositorsAddress = DepositTx.getOutputOwner(decodedTx.outputs[0]);
        require(depositorsAddress == sender, "Depositor's address must match sender's address");

        IERC20 erc20 = IERC20(decodedTx.outputs[0].token);
        require(erc20.allowance(depositorsAddress, vault) >= decodedTx.outputs[0].amount, "Tokens have not been approved");

        return (depositorsAddress, decodedTx.outputs[0].token, decodedTx.outputs[0].amount);
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/verifiers/EthDepositVerifier.sol": {
      "content": "pragma solidity 0.5.11;

import "./IEthDepositVerifier.sol";
import {PaymentTransactionModel as DepositTx} from "../../transactions/PaymentTransactionModel.sol";

/**
 * @notice Implementation of ETH deposit verifier using payment transaction as the deposit transaction
 */
contract EthDepositVerifier is IEthDepositVerifier {
    uint256 public depositTxType;
    uint256 public supportedOutputType;

    constructor(uint256 txType, uint256 outputType) public {
        depositTxType = txType;
        supportedOutputType = outputType;
    }

    /**
     * @notice Overrides the function of IEthDepositVerifier and implements the verification logic
     *         for payment transaction
     */
    function verify(bytes calldata depositTx, uint256 amount, address sender) external view {
        DepositTx.Transaction memory decodedTx = DepositTx.decode(depositTx);

        require(decodedTx.txType == depositTxType, "Invalid transaction type");

        require(decodedTx.inputs.length == 0, "Deposit must have no inputs");

        require(decodedTx.outputs.length == 1, "Deposit must have exactly one output");
        require(decodedTx.outputs[0].amount == amount, "Deposited value must match sent amount");
        require(decodedTx.outputs[0].token == address(0), "Output requires correct currency (ETH)");
        require(decodedTx.outputs[0].outputType == supportedOutputType, "Invalid output type");

        address depositorsAddress = DepositTx.getOutputOwner(decodedTx.outputs[0]);
        require(depositorsAddress == sender, "Depositor's address must match sender's address");
    }
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/verifiers/IErc20DepositVerifier.sol": {
      "content": "pragma solidity 0.5.11;

interface IErc20DepositVerifier {
    /**
     * @notice Verifies a deposit transaction
     * @param depositTx The deposit transaction
     * @param sender The owner of the deposit transaction
     * @param vault The address of the Erc20Vault contract
     * @return Verified (owner, token, amount) of the deposit ERC20 token data
     */
    function verify(bytes calldata depositTx, address sender, address vault)
        external
        view
        returns (address owner, address token, uint256 amount);
}
"
    },
    "/Users/jake/plasma-contracts/plasma_framework/contracts/src/vaults/verifiers/IEthDepositVerifier.sol": {
      "content": "pragma solidity 0.5.11;

interface IEthDepositVerifier {
    /**
     * @notice Verifies a deposit transaction
     * @param depositTx The deposit transaction
     * @param amount The amount deposited
     * @param sender The owner of the deposit transaction
     */
    function verify(bytes calldata depositTx, uint256 amount, address sender) external view;
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol": {
      "content": "pragma solidity ^0.5.0;

import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}
"
    },
    "openzeppelin-solidity/contracts/math/SafeMath.sol": {
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
"
    },
    "openzeppelin-solidity/contracts/cryptography/ECDSA.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n Ã· 2 + 1, and for v in (282): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
"
    },
    "openzeppelin-solidity/contracts/ownership/Ownable.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "openzeppelin-solidity/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
"
    },
    "openzeppelin-solidity/contracts/math/Math.sol": {
      "content": "pragma solidity ^0.5.0;

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
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
"
    },
    "openzeppelin-solidity/contracts/access/roles/MinterRole.sol": {
      "content": "pragma solidity ^0.5.0;

import "../Roles.sol";

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
"
    },
    "openzeppelin-solidity/contracts/access/Roles.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
"
    }
  },
  "settings": {
    "libraries": {
      "": {
        "PaymentStartStandardExit": "0xf38380bbf08961123960fAd630a0609906849751",
        "PaymentChallengeStandardExit": "0x24c0a84090135AD04F257C85E10db6B4A74E0738",
        "PaymentProcessStandardExit": "0x5E84DF30ce17A9AC34E5474fc37a9c2267454518",
        "PaymentStartInFlightExit": "0x081d7B167a94E7421Ea5D0016C3D01E0cFf6B557",
        "PaymentPiggybackInFlightExit": "0x5d3EE50E31293B45A7eb8B864c0B015E169AC7D8",
        "PaymentChallengeIFENotCanonical": "0x9e3108FB11cAEDA64e264B2953a0eDa81cf1a650",
        "PaymentChallengeIFEInputSpent": "0xEf6133d149460C9B79e132517934f77F1E62b23e",
        "PaymentChallengeIFEOutputSpent": "0x7A8C0D7F1e6dBe36AB3A9adE0C44a0b868bB703F",
        "PaymentDeleteInFlightExit": "0x4f05855B6dF026726037500D10D91652b5C9e784",
        "PaymentProcessInFlightExit": "0x67C3E5524dBE05B54fE08c3D4af65c273B87E630"
      }
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "remappings": [],
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