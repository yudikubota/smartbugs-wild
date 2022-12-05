{{
  "language": "Solidity",
  "sources": {
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
    }
  },
  "settings": {
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