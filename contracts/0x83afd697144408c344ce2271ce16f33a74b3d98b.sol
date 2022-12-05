{"BimodalLib.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./SafeMathLib256.sol";

/**
 * This library defines the bi-modal commit-chain ledger. It provides data
 * structure definitions, accessors and mutators.
 */
library BimodalLib {
    using SafeMathLib256 for uint256;

    // ENUMS
    enum ChallengeType {NONE, STATE_UPDATE, TRANSFER_DELIVERY, SWAP_ENACTMENT}

    // DATA MODELS
    /**
     * Aggregate field datastructure used to sum up deposits / withdrawals for an eon.
     */
    struct AmountAggregate {
        uint256 eon;
        uint256 amount;
    }

    /**
     * The structure for a submitted commit-chain checkpoint.
     */
    struct Checkpoint {
        uint256 eonNumber;
        bytes32 merkleRoot;
        uint256 liveChallenges;
    }

    /**
     * A structure representing a single commit-chain wallet.
     */
    struct Wallet {
        // Deposits performed in the last three eons
        AmountAggregate[3] depositsKept;
        // Withdrawals requested and not yet confirmed
        Withdrawal[] withdrawals;
        // Recovery flag denoting whether this account has retrieved its funds
        bool recovered;
    }

    /**
     * A structure denoting a single withdrawal request.
     */
    struct Withdrawal {
        uint256 eon;
        uint256 amount;
    }

    /**
     * A structure containing the information of a single challenge.
     */
    struct Challenge {
        // State Update Challenges
        ChallengeType challengeType; // 0
        uint256 block; // 1
        uint256 initialStateEon; // 2
        uint256 initialStateBalance; // 3
        uint256 deltaHighestSpendings; // 4
        uint256 deltaHighestGains; // 5
        uint256 finalStateBalance; // 6
        uint256 deliveredTxNonce; // 7
        uint64 trailIdentifier; // 8
    }

    /**
     * The types of parent-chain operations logged into the accumulator.
     */
    enum Operation {DEPOSIT, WITHDRAWAL, CANCELLATION}

    /* solhint-disable var-name-mixedcase */
    /**
     * The structure for an instance of the commit-chain ledger.
     */
    struct Ledger {
        // OPERATIONAL CONSTANTS
        uint8 EONS_KEPT;
        uint8 DEPOSITS_KEPT;
        uint256 MIN_CHALLENGE_GAS_COST;
        uint256 BLOCKS_PER_EON;
        uint256 BLOCKS_PER_EPOCH;
        uint256 EXTENDED_BLOCKS_PER_EPOCH;
        // STATE VARIABLES
        uint256 genesis;
        address operator;
        Checkpoint[5] checkpoints;
        bytes32[5] parentChainAccumulator; // bytes32[EONS_KEPT]
        uint256 lastSubmissionEon;
        mapping(address => mapping(address => mapping(address => Challenge))) challengeBook;
        mapping(address => mapping(address => Wallet)) walletBook;
        mapping(address => AmountAggregate[5]) deposits;
        mapping(address => AmountAggregate[5]) pendingWithdrawals;
        mapping(address => AmountAggregate[5]) confirmedWithdrawals;
        mapping(address => uint64) tokenToTrail;
        address[] trailToToken;
    }

    /* solhint-enable */

    // INITIALIZATION
    function init(
        Ledger storage self,
        uint256 blocksPerEon,
        address operator
    ) public {
        self.BLOCKS_PER_EON = blocksPerEon;
        self.BLOCKS_PER_EPOCH = self.BLOCKS_PER_EON.div(4);
        self.EXTENDED_BLOCKS_PER_EPOCH = self.BLOCKS_PER_EON.div(3);
        self.EONS_KEPT = 5; // eons kept on chain
        self.DEPOSITS_KEPT = 3; // deposit aggregates kept on chain
        self.MIN_CHALLENGE_GAS_COST = 0.005 szabo; // 5 gwei minimum gas reimbursement cost
        self.operator = operator;
        self.genesis = block.number;
    }

    // DATA ACCESS
    /**
     * This method calculates the current eon number using the genesis block number
     * and eon duration.
     */
    function currentEon(Ledger storage self) public view returns (uint256) {
        return block.number.sub(self.genesis).div(self.BLOCKS_PER_EON).add(1);
    }

    /**
     * This method calculates the current era number
     */
    function currentEra(Ledger storage self) public view returns (uint256) {
        return block.number.sub(self.genesis).mod(self.BLOCKS_PER_EON);
    }

    /**
     * This method is used to embed a parent-chain operation into the accumulator
     * through hashing its values. The on-chain accumulator is used to provide a
     * reference with respect to which the operator can commit checkpoints.
     */
    function appendOperationToEonAccumulator(
        Ledger storage self,
        uint256 eon,
        ERC20 token,
        address participant,
        Operation operation,
        uint256 value
    ) public {
        self.parentChainAccumulator[eon.mod(self.EONS_KEPT)] = keccak256(
            abi.encodePacked(
                self.parentChainAccumulator[eon.mod(self.EONS_KEPT)],
                eon,
                token,
                participant,
                operation,
                value
            )
        );
    }

    /**
     * Retrieves the total pending withdrawal amount at a specific eon.
     */
    function getPendingWithdrawalsAtEon(
        Ledger storage self,
        ERC20 token,
        uint256 eon
    ) public view returns (uint256) {
        uint256 lastAggregateEon = 0;
        for (uint256 i = 0; i < self.EONS_KEPT; i++) {
            AmountAggregate storage currentAggregate = self
                .pendingWithdrawals[token][eon.mod(self.EONS_KEPT)];
            if (currentAggregate.eon == eon) {
                return currentAggregate.amount;
            } else if (
                currentAggregate.eon > lastAggregateEon &&
                currentAggregate.eon < eon
            ) {
                // As this is a running aggregate value, if the target eon value is not set,
                // the most recent value is provided and assumed to have remained constant.
                lastAggregateEon = currentAggregate.eon;
            }
            if (eon == 0) {
                break;
            }
            eon = eon.sub(1);
        }
        if (lastAggregateEon == 0) {
            return 0;
        }
        return
            self.pendingWithdrawals[token][lastAggregateEon.mod(self.EONS_KEPT)]
                .amount;
    }

    /**
     * Increases the total pending withdrawal amount at a specific eon.
     */
    function addToRunningPendingWithdrawals(
        Ledger storage self,
        ERC20 token,
        uint256 eon,
        uint256 value
    ) public {
        AmountAggregate storage aggregate = self.pendingWithdrawals[token][eon
            .mod(self.EONS_KEPT)];
        // As this is a running aggregate, the target eon and all those that
        // come after it are updated to reflect the increase.
        if (aggregate.eon < eon) {
            // implies eon > 0
            aggregate.amount = getPendingWithdrawalsAtEon(
                self,
                token,
                eon.sub(1)
            )
                .add(value);
            aggregate.eon = eon;
        } else {
            aggregate.amount = aggregate.amount.add(value);
        }
    }

    /**
     * Decreases the total pending withdrawal amount at a specific eon.
     */
    function deductFromRunningPendingWithdrawals(
        Ledger storage self,
        ERC20 token,
        uint256 eon,
        uint256 latestEon,
        uint256 value
    ) public {
        /* Initalize empty aggregates to running values */
        for (uint256 i = 0; i < self.EONS_KEPT; i++) {
            uint256 targetEon = eon.add(i);
            AmountAggregate storage aggregate = self
                .pendingWithdrawals[token][targetEon.mod(self.EONS_KEPT)];
            if (targetEon > latestEon) {
                break;
            } else if (aggregate.eon < targetEon) {
                // implies targetEon > 0
                // Set constant running value
                aggregate.eon = targetEon;
                aggregate.amount = getPendingWithdrawalsAtEon(
                    self,
                    token,
                    targetEon.sub(1)
                );
            }
        }
        /* Update running values */
        for (i = 0; i < self.EONS_KEPT; i++) {
            targetEon = eon.add(i);
            aggregate = self.pendingWithdrawals[token][targetEon.mod(
                self.EONS_KEPT
            )];
            if (targetEon > latestEon) {
                break;
            } else if (aggregate.eon < targetEon) {
                revert("X"); // This is impossible.
            } else {
                aggregate.amount = aggregate.amount.sub(value);
            }
        }
    }

    /**
     * Get the total number of live challenges for a specific eon.
     */
    function getLiveChallenges(Ledger storage self, uint256 eon)
        public
        view
        returns (uint256)
    {
        Checkpoint storage checkpoint = self.checkpoints[eon.mod(
            self.EONS_KEPT
        )];
        if (checkpoint.eonNumber != eon) {
            return 0;
        }
        return checkpoint.liveChallenges;
    }

    /**
     * Get checkpoint data or assume it to be empty if non-existant.
     */
    function getOrCreateCheckpoint(
        Ledger storage self,
        uint256 targetEon,
        uint256 latestEon
    ) public returns (Checkpoint storage checkpoint) {
        require(
            latestEon < targetEon.add(self.EONS_KEPT) && targetEon <= latestEon
        );

        uint256 index = targetEon.mod(self.EONS_KEPT);
        checkpoint = self.checkpoints[index];

        if (checkpoint.eonNumber != targetEon) {
            checkpoint.eonNumber = targetEon;
            checkpoint.merkleRoot = bytes32(0);
            checkpoint.liveChallenges = 0;
        }

        return checkpoint;
    }

    /**
     * Get the total amount pending withdrawal by a wallet at a specific eon.
     */
    function getWalletPendingWithdrawalAmountAtEon(
        Ledger storage self,
        ERC20 token,
        address holder,
        uint256 eon
    ) public view returns (uint256 amount) {
        amount = 0;

        Wallet storage accountingEntry = self.walletBook[token][holder];
        Withdrawal[] storage withdrawals = accountingEntry.withdrawals;
        for (uint32 i = 0; i < withdrawals.length; i++) {
            Withdrawal storage withdrawal = withdrawals[i];
            if (withdrawal.eon == eon) {
                amount = amount.add(withdrawal.amount);
            } else if (withdrawal.eon > eon) {
                break;
            }
        }
    }

    /**
     * Get the total amounts deposited and pending withdrawal at the current eon.
     */
    function getCurrentEonDepositsWithdrawals(
        Ledger storage self,
        ERC20 token,
        address holder
    )
        public
        view
        returns (uint256 currentEonDeposits, uint256 currentEonWithdrawals)
    {
        currentEonDeposits = 0;
        currentEonWithdrawals = 0;

        Wallet storage accountingEntry = self.walletBook[token][holder];
        Challenge storage challengeEntry = self
            .challengeBook[token][holder][holder];

        AmountAggregate storage depositEntry = accountingEntry
            .depositsKept[challengeEntry.initialStateEon.mod(
            self.DEPOSITS_KEPT
        )];

        if (depositEntry.eon == challengeEntry.initialStateEon) {
            currentEonDeposits = currentEonDeposits.add(depositEntry.amount);
        }

        currentEonWithdrawals = getWalletPendingWithdrawalAmountAtEon(
            self,
            token,
            holder,
            challengeEntry.initialStateEon
        );

        return (currentEonDeposits, currentEonWithdrawals);
    }

    // UTILITY
    function addToAggregate(
        AmountAggregate storage aggregate,
        uint256 eon,
        uint256 value
    ) public {
        if (eon > aggregate.eon) {
            aggregate.eon = eon;
            aggregate.amount = value;
        } else {
            aggregate.amount = aggregate.amount.add(value);
        }
    }

    function clearAggregate(AmountAggregate storage aggregate) public {
        aggregate.eon = 0;
        aggregate.amount = 0;
    }

    function signedMessageECRECOVER(
        bytes32 message,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(
                            abi.encodePacked(
                                "\x19Liquidity.Network Authorization:\n32",
                                message
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );
    }
}
"},"BimodalProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./BimodalLib.sol";
import "./SafeMathLib256.sol";

contract BimodalProxy {
    using SafeMathLib256 for uint256;
    using BimodalLib for BimodalLib.Ledger;

    // EVENTS
    event CheckpointSubmission(uint256 indexed eon, bytes32 merkleRoot);

    event Deposit(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    event WithdrawalRequest(
        address indexed token,
        address indexed requestor,
        uint256 amount
    );

    event WithdrawalConfirmation(
        address indexed token,
        address indexed requestor,
        uint256 amount
    );

    event ChallengeIssued(
        address indexed token,
        address indexed recipient,
        address indexed sender
    );

    event StateUpdate(
        address indexed token,
        address indexed account,
        uint256 indexed eon,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark,
        bytes32 activeStateChecksum,
        bytes32 passiveChecksum,
        bytes32 r,
        bytes32 s,
        uint8 v
    );

    // BIMODAL LEDGER DATA
    BimodalLib.Ledger internal ledger;

    // INITIALIZATION
    constructor(uint256 blocksPerEon, address operator) public {
        ledger.init(blocksPerEon, operator);
    }

    // SAFETY MODIFIERS
    modifier onlyOperator() {
        require(msg.sender == ledger.operator);
        _;
    }

    modifier onlyWhenContractUnpunished() {
        require(
            !hasOutstandingChallenges() && !hasMissedCheckpointSubmission(),
            "p"
        );
        _;
    }

    // PUBLIC DATA EXPOSURE
    function getClientContractStateVariables(ERC20 token, address holder)
        public
        view
        returns (
            uint256 latestCheckpointEonNumber,
            bytes32[5] latestCheckpointsMerkleRoots,
            uint256[5] latestCheckpointsLiveChallenges,
            uint256 currentEonDeposits,
            uint256 previousEonDeposits,
            uint256 secondPreviousEonDeposits,
            uint256[2][] pendingWithdrawals,
            uint256 holderBalance
        )
    {
        latestCheckpointEonNumber = ledger.lastSubmissionEon;
        for (
            uint32 i = 0;
            i < ledger.EONS_KEPT && i < ledger.currentEon();
            i++
        ) {
            BimodalLib.Checkpoint storage checkpoint = ledger.checkpoints[ledger
                .lastSubmissionEon
                .sub(i)
                .mod(ledger.EONS_KEPT)];
            latestCheckpointsMerkleRoots[i] = checkpoint.merkleRoot;
            latestCheckpointsLiveChallenges[i] = checkpoint.liveChallenges;
        }

        holderBalance = ledger.currentEon();
        currentEonDeposits = getDepositsAtEon(token, holder, holderBalance);
        if (holderBalance > 1) {
            previousEonDeposits = getDepositsAtEon(
                token,
                holder,
                holderBalance - 1
            );
        }
        if (holderBalance > 2) {
            secondPreviousEonDeposits = getDepositsAtEon(
                token,
                holder,
                holderBalance - 2
            );
        }
        BimodalLib.Wallet storage wallet = ledger.walletBook[token][holder];
        pendingWithdrawals = new uint256[2][](wallet.withdrawals.length);
        for (i = 0; i < wallet.withdrawals.length; i++) {
            BimodalLib.Withdrawal storage withdrawal = wallet.withdrawals[i];
            pendingWithdrawals[i] = [withdrawal.eon, withdrawal.amount];
        }
        holderBalance = token != address(this)
            ? token.balanceOf(holder)
            : holder.balance;
    }

    function getServerContractStateVariables()
        public
        view
        returns (
            bytes32 parentChainAccumulator,
            uint256 lastSubmissionEon,
            bytes32 lastCheckpointRoot,
            bool isCheckpointSubmitted,
            bool missedCheckpointSubmission,
            uint256 liveChallenges
        )
    {
        uint256 currentEon = ledger.currentEon();
        parentChainAccumulator = getParentChainAccumulatorAtSlot(
            uint8(currentEon.mod(ledger.EONS_KEPT))
        );

        BimodalLib.Checkpoint storage lastCheckpoint = ledger.checkpoints[ledger
            .lastSubmissionEon
            .mod(ledger.EONS_KEPT)];
        lastSubmissionEon = ledger.lastSubmissionEon;
        lastCheckpointRoot = lastCheckpoint.merkleRoot;

        isCheckpointSubmitted = lastSubmissionEon == currentEon;
        missedCheckpointSubmission = hasMissedCheckpointSubmission();

        liveChallenges = getLiveChallenges(currentEon);
    }

    function getServerContractLedgerStateVariables(
        uint256 eonNumber,
        ERC20 token
    )
        public
        view
        returns (
            uint256 pendingWithdrawals,
            uint256 confirmedWithdrawals,
            uint256 deposits,
            uint256 totalBalance
        )
    {
        uint8 eonSlot = uint8(eonNumber.mod(ledger.EONS_KEPT));
        uint256 targetEon = 0;
        (targetEon, pendingWithdrawals) = getPendingWithdrawalsAtSlot(
            token,
            eonSlot
        );
        if (targetEon != eonNumber) {
            pendingWithdrawals = 0;
        }
        (targetEon, confirmedWithdrawals) = getConfirmedWithdrawalsAtSlot(
            token,
            eonSlot
        );
        if (targetEon != eonNumber) {
            confirmedWithdrawals = 0;
        }
        (targetEon, deposits) = getDepositsAtSlot(token, eonSlot);
        if (targetEon != eonNumber) {
            deposits = 0;
        }
        // totalBalance is for current state and not for eonNumber, which is stange
        totalBalance = token != address(this)
            ? token.balanceOf(this)
            : address(this).balance;
    }

    function hasOutstandingChallenges() public view returns (bool) {
        return
            ledger.getLiveChallenges(ledger.currentEon().sub(1)) > 0 &&
            ledger.currentEra() > ledger.BLOCKS_PER_EPOCH;
    }

    function hasMissedCheckpointSubmission() public view returns (bool) {
        return ledger.currentEon().sub(ledger.lastSubmissionEon) > 1;
    }

    function getCheckpointAtSlot(uint8 slot)
        public
        view
        returns (
            uint256,
            bytes32,
            uint256
        )
    {
        BimodalLib.Checkpoint storage checkpoint = ledger.checkpoints[slot];
        return (
            checkpoint.eonNumber,
            checkpoint.merkleRoot,
            checkpoint.liveChallenges
        );
    }

    function getParentChainAccumulatorAtSlot(uint8 slot)
        public
        view
        returns (bytes32)
    {
        return ledger.parentChainAccumulator[slot];
    }

    function getChallenge(
        ERC20 token,
        address sender,
        address recipient
    )
        public
        view
        returns (
            BimodalLib.ChallengeType,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint64
        )
    {
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[token][recipient][sender];
        return (
            challenge.challengeType,
            challenge.block,
            challenge.initialStateEon,
            challenge.initialStateBalance,
            challenge.deltaHighestSpendings,
            challenge.deltaHighestGains,
            challenge.finalStateBalance,
            challenge.deliveredTxNonce,
            challenge.trailIdentifier
        );
    }

    function getIsWalletRecovered(ERC20 token, address holder)
        public
        view
        returns (bool)
    {
        BimodalLib.Wallet storage wallet = ledger.walletBook[token][holder];
        return (wallet.recovered);
    }

    function getDepositsAtEon(
        ERC20 token,
        address addr,
        uint256 eon
    ) public view returns (uint256) {
        (
            uint256 aggregateEon,
            uint256 aggregateAmount
        ) = getWalletDepositAggregateAtSlot(
            token,
            addr,
            uint8(eon.mod(ledger.DEPOSITS_KEPT))
        );
        return aggregateEon == eon ? aggregateAmount : 0;
    }

    function getDepositsAtSlot(ERC20 token, uint8 slot)
        public
        view
        returns (uint256, uint256)
    {
        BimodalLib.AmountAggregate storage aggregate = ledger
            .deposits[token][slot];
        return (aggregate.eon, aggregate.amount);
    }

    function getWalletDepositAggregateAtSlot(
        ERC20 token,
        address addr,
        uint8 slot
    ) public view returns (uint256, uint256) {
        BimodalLib.AmountAggregate memory deposit = ledger
            .walletBook[token][addr]
            .depositsKept[slot];
        return (deposit.eon, deposit.amount);
    }

    function getPendingWithdrawalsAtEon(ERC20 token, uint256 eon)
        public
        view
        returns (uint256)
    {
        return ledger.getPendingWithdrawalsAtEon(token, eon);
    }

    function getPendingWithdrawalsAtSlot(ERC20 token, uint8 slot)
        public
        view
        returns (uint256, uint256)
    {
        BimodalLib.AmountAggregate storage aggregate = ledger
            .pendingWithdrawals[token][slot];
        return (aggregate.eon, aggregate.amount);
    }

    function getConfirmedWithdrawalsAtSlot(ERC20 token, uint8 slot)
        public
        view
        returns (uint256, uint256)
    {
        BimodalLib.AmountAggregate storage aggregate = ledger
            .confirmedWithdrawals[token][slot];
        return (aggregate.eon, aggregate.amount);
    }

    function getWalletPendingWithdrawalAmountAtEon(
        ERC20 token,
        address holder,
        uint256 eon
    ) public view returns (uint256) {
        return ledger.getWalletPendingWithdrawalAmountAtEon(token, holder, eon);
    }

    function getTokenTrail(ERC20 token) public view returns (uint64) {
        return ledger.tokenToTrail[token];
    }

    function getTokenAtTrail(uint64 trail) public view returns (address) {
        return ledger.trailToToken[trail];
    }

    function getCurrentEonDepositsWithdrawals(ERC20 token, address holder)
        public
        view
        returns (uint256 currentEonDeposits, uint256 currentEonWithdrawals)
    {
        return ledger.getCurrentEonDepositsWithdrawals(token, holder);
    }

    function EONS_KEPT()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint8
        )
    {
        return ledger.EONS_KEPT;
    }

    function DEPOSITS_KEPT()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint8
        )
    {
        return ledger.DEPOSITS_KEPT;
    }

    function MIN_CHALLENGE_GAS_COST()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint256
        )
    {
        return ledger.MIN_CHALLENGE_GAS_COST;
    }

    function BLOCKS_PER_EON()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint256
        )
    {
        return ledger.BLOCKS_PER_EON;
    }

    function BLOCKS_PER_EPOCH()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint256
        )
    {
        return ledger.BLOCKS_PER_EPOCH;
    }

    function EXTENDED_BLOCKS_PER_EPOCH()
        public
        view
        returns (
            // solhint-disable-line func-name-mixedcase
            uint256
        )
    {
        return ledger.EXTENDED_BLOCKS_PER_EPOCH;
    }

    function genesis() public view returns (uint256) {
        return ledger.genesis;
    }

    function operator() public view returns (address) {
        return ledger.operator;
    }

    function lastSubmissionEon() public view returns (uint256) {
        return ledger.lastSubmissionEon;
    }

    function currentEon() public view returns (uint256) {
        return ledger.currentEon();
    }

    function currentEra() public view returns (uint256) {
        return ledger.currentEra();
    }

    function getLiveChallenges(uint256 eon) public view returns (uint256) {
        BimodalLib.Checkpoint storage checkpoint = ledger.checkpoints[eon.mod(
            ledger.EONS_KEPT
        )];
        if (checkpoint.eonNumber != eon) {
            return 0;
        }
        return checkpoint.liveChallenges;
    }

    function signedMessageECRECOVER(
        bytes32 message,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address) {
        return BimodalLib.signedMessageECRECOVER(message, r, s, v);
    }
}
"},"ChallengeLib.sol":{"content":"/* solhint-disable func-order */

pragma solidity ^0.4.24;

import "./BimodalLib.sol";
import "./MerkleVerifier.sol";
import "./SafeMathLib32.sol";
import "./SafeMathLib256.sol";

/**
 * This library contains the challenge-response implementations of NOCUST.
 */
library ChallengeLib {
    using SafeMathLib256 for uint256;
    using SafeMathLib32 for uint32;
    using BimodalLib for BimodalLib.Ledger;
    // EVENTS
    event ChallengeIssued(
        address indexed token,
        address indexed recipient,
        address indexed sender
    );

    event StateUpdate(
        address indexed token,
        address indexed account,
        uint256 indexed eon,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark,
        bytes32 activeStateChecksum,
        bytes32 passiveChecksum,
        bytes32 r,
        bytes32 s,
        uint8 v
    );

    // Validation
    function verifyProofOfExclusiveAccountBalanceAllotment(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address holder,
        bytes32[2] activeStateChecksum_passiveTransfersRoot, // solhint-disable func-param-name-mixedcase
        uint64 trail,
        uint256[3] eonPassiveMark,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2] LR // solhint-disable func-param-name-mixedcase
    ) public view returns (bool) {
        BimodalLib.Checkpoint memory checkpoint = ledger
            .checkpoints[eonPassiveMark[0].mod(ledger.EONS_KEPT)];
        require(eonPassiveMark[0] == checkpoint.eonNumber, "r");

        // activeStateChecksum is set to the account node.
        activeStateChecksum_passiveTransfersRoot[0] = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(address(this))),
                keccak256(abi.encodePacked(token)),
                keccak256(abi.encodePacked(holder)),
                keccak256(
                    abi.encodePacked(
                        activeStateChecksum_passiveTransfersRoot[1], // passiveTransfersRoot
                        eonPassiveMark[1],
                        eonPassiveMark[2]
                    )
                ),
                activeStateChecksum_passiveTransfersRoot[0] // activeStateChecksum
            )
        );
        // the interval allotment is set to form the leaf
        activeStateChecksum_passiveTransfersRoot[0] = keccak256(
            abi.encodePacked(
                LR[0],
                activeStateChecksum_passiveTransfersRoot[0],
                LR[1]
            )
        );

        // This calls the merkle verification procedure, which returns the
        // checkpoint allotment size
        uint64 tokenTrail = ledger.tokenToTrail[token];
        LR[0] = MerkleVerifier.verifyProofOfExclusiveBalanceAllotment(
            trail,
            tokenTrail,
            activeStateChecksum_passiveTransfersRoot[0],
            checkpoint.merkleRoot,
            allotmentChain,
            membershipChain,
            values,
            LR
        );

        // The previous allotment size of the target eon is reconstructed from the
        // deposits and withdrawals performed so far and the current balance.
        LR[1] = address(this).balance;

        if (token != address(this)) {
            require(tokenTrail != 0, "t");
            LR[1] = token.balanceOf(this);
        }

        // Credit back confirmed withdrawals that were performed since target eon
        for (tokenTrail = 0; tokenTrail < ledger.EONS_KEPT; tokenTrail++) {
            if (
                ledger.confirmedWithdrawals[token][tokenTrail].eon >=
                eonPassiveMark[0]
            ) {
                LR[1] = LR[1].add(
                    ledger.confirmedWithdrawals[token][tokenTrail].amount
                );
            }
        }
        // Debit deposits performed since target eon
        for (tokenTrail = 0; tokenTrail < ledger.EONS_KEPT; tokenTrail++) {
            if (ledger.deposits[token][tokenTrail].eon >= eonPassiveMark[0]) {
                LR[1] = LR[1].sub(ledger.deposits[token][tokenTrail].amount);
            }
        }
        // Debit withdrawals pending since prior eon
        LR[1] = LR[1].sub(
            ledger.getPendingWithdrawalsAtEon(token, eonPassiveMark[0].sub(1))
        );
        // Require that the reconstructed allotment matches the proof allotment
        require(LR[0] <= LR[1], "b");

        return true;
    }

    function verifyProofOfActiveStateUpdateAgreement(
        ERC20 token,
        address holder,
        uint64 trail,
        uint256 eon,
        bytes32 txSetRoot,
        uint256[2] deltas,
        address attester,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public view returns (bytes32 checksum) {
        checksum = MerkleVerifier.activeStateUpdateChecksum(
            token,
            holder,
            trail,
            eon,
            txSetRoot,
            deltas
        );
        require(
            attester == BimodalLib.signedMessageECRECOVER(checksum, r, s, v),
            "A"
        );
    }

    function verifyWithdrawalAuthorization(
        ERC20 token,
        address holder,
        uint256 expiry,
        uint256 amount,
        address attester,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public view returns (bool) {
        bytes32 checksum = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(address(this))),
                keccak256(abi.encodePacked(token)),
                keccak256(abi.encodePacked(holder)),
                expiry,
                amount
            )
        );
        require(
            attester == BimodalLib.signedMessageECRECOVER(checksum, r, s, v),
            "a"
        );
        return true;
    }

    // Challenge Lifecycle Methods
    /**
     * This method increments the live challenge counter and emits and event
     * containing the challenge index.
     */
    function markChallengeLive(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address recipient,
        address sender
    ) private {
        require(ledger.currentEra() > ledger.BLOCKS_PER_EPOCH);

        uint256 eon = ledger.currentEon();
        BimodalLib.Checkpoint storage checkpoint = ledger.getOrCreateCheckpoint(
            eon,
            eon
        );
        checkpoint.liveChallenges = checkpoint.liveChallenges.add(1);
        emit ChallengeIssued(token, recipient, sender);
    }

    /**
     * This method clears all the data in a Challenge structure and decrements the
     * live challenge counter.
     */
    function clearChallenge(
        BimodalLib.Ledger storage ledger,
        BimodalLib.Challenge storage challenge
    ) private {
        BimodalLib.Checkpoint storage checkpoint = ledger.getOrCreateCheckpoint(
            challenge.initialStateEon.add(1),
            ledger.currentEon()
        );
        checkpoint.liveChallenges = checkpoint.liveChallenges.sub(1);

        challenge.challengeType = BimodalLib.ChallengeType.NONE;
        challenge.block = 0;
        // challenge.initialStateEon = 0;
        challenge.initialStateBalance = 0;
        challenge.deltaHighestSpendings = 0;
        challenge.deltaHighestGains = 0;
        challenge.finalStateBalance = 0;
        challenge.deliveredTxNonce = 0;
        challenge.trailIdentifier = 0;
    }

    /**
     * This method marks a challenge as having been successfully answered only if
     * the response was provided in time.
     */
    function markChallengeAnswered(
        BimodalLib.Ledger storage ledger,
        BimodalLib.Challenge storage challenge
    ) private {
        uint256 eon = ledger.currentEon();

        require(
            challenge.challengeType != BimodalLib.ChallengeType.NONE &&
                block.number.sub(challenge.block) < ledger.BLOCKS_PER_EPOCH &&
                (challenge.initialStateEon == eon.sub(1) ||
                    (challenge.initialStateEon == eon.sub(2) &&
                        ledger.currentEra() < ledger.BLOCKS_PER_EPOCH))
        );

        clearChallenge(ledger, challenge);
    }

    // ========================================================================
    // ========================================================================
    // ========================================================================
    // ====================================  STATE UPDATE Challenge
    // ========================================================================
    // ========================================================================
    // ========================================================================
    /**
     * This method initiates the fields of the Challenge struct to hold a state
     * update challenge.
     */
    function initStateUpdateChallenge(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        uint256 owed,
        uint256[2] spentGained,
        uint64 trail
    ) private {
        BimodalLib.Challenge storage challengeEntry = ledger
            .challengeBook[token][msg.sender][msg.sender];
        require(challengeEntry.challengeType == BimodalLib.ChallengeType.NONE);
        require(challengeEntry.initialStateEon < ledger.currentEon().sub(1));

        challengeEntry.initialStateEon = ledger.currentEon().sub(1);
        challengeEntry.initialStateBalance = owed;
        challengeEntry.deltaHighestSpendings = spentGained[0];
        challengeEntry.deltaHighestGains = spentGained[1];
        challengeEntry.trailIdentifier = trail;

        challengeEntry.challengeType = BimodalLib.ChallengeType.STATE_UPDATE;
        challengeEntry.block = block.number;

        markChallengeLive(ledger, token, msg.sender, msg.sender);
    }

    /**
     * This method checks that the updated balance is at least as much as the
     * expected balance.
     */
    function checkStateUpdateBalance(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address issuer,
        BimodalLib.Challenge storage challenge,
        uint256[2] LR, // solhint-disable func-param-name-mixedcase
        uint256[2] spentGained,
        uint256 passivelyReceived
    ) private view {
        (uint256 deposits, uint256 withdrawals) = ledger
            .getCurrentEonDepositsWithdrawals(token, issuer);
        uint256 incoming = spentGained[1] // actively received in commit chain
            .add(deposits)
            .add(passivelyReceived);
        uint256 outgoing = spentGained[0] // actively spent in commit chain
            .add(withdrawals);
        // This verification is modified to permit underflow of expected balance
        // since a client can choose to zero the `challenge.initialStateBalance`
        require(
            challenge.initialStateBalance.add(incoming) <=
                LR[1]
                    .sub(LR[0]) // final balance allotment
                    .add(outgoing),
            "B"
        );
    }

    function challengeStateUpdateWithProofOfExclusiveBalanceAllotment(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        bytes32[2] checksums,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] value,
        uint256[2][3] lrDeltasPassiveMark,
        bytes32[3] rsTxSetRoot,
        uint8 v
    ) public /* payable */
    /* onlyWithFairReimbursement(ledger) */
    {
        uint256 previousEon = ledger.currentEon().sub(1);
        address operator = ledger.operator;

        // The hub must have committed to this state update
        if (lrDeltasPassiveMark[1][0] != 0 || lrDeltasPassiveMark[1][1] != 0) {
            verifyProofOfActiveStateUpdateAgreement(
                token,
                msg.sender,
                trail,
                previousEon,
                rsTxSetRoot[2],
                lrDeltasPassiveMark[1],
                operator,
                rsTxSetRoot[0],
                rsTxSetRoot[1],
                v
            );
        }

        initStateUpdateChallenge(
            ledger,
            token,
            lrDeltasPassiveMark[0][1].sub(lrDeltasPassiveMark[0][0]),
            lrDeltasPassiveMark[1],
            trail
        );

        // The initial state must have been ratified in the commitment
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                msg.sender,
                checksums,
                trail,
                [
                    previousEon,
                    lrDeltasPassiveMark[2][0],
                    lrDeltasPassiveMark[2][1]
                ],
                allotmentChain,
                membershipChain,
                value,
                lrDeltasPassiveMark[0]
            )
        );
    }

    function challengeStateUpdateWithProofOfActiveStateUpdateAgreement(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        bytes32 txSetRoot,
        uint64 trail,
        uint256[2] deltas,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public /* payable */
    /* TODO calculate exact addition */
    /* onlyWithSkewedReimbursement(ledger, 25) */
    {
        // The hub must have committed to this transition
        verifyProofOfActiveStateUpdateAgreement(
            token,
            msg.sender,
            trail,
            ledger.currentEon().sub(1),
            txSetRoot,
            deltas,
            ledger.operator,
            r,
            s,
            v
        );

        initStateUpdateChallenge(ledger, token, 0, deltas, trail);
    }

    function answerStateUpdateChallenge(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address issuer,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark, // [ [L, R], Deltas ]
        bytes32[6] rSrStxSetRootChecksum,
        uint8[2] v
    ) public {
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[token][issuer][issuer];
        require(
            challenge.challengeType == BimodalLib.ChallengeType.STATE_UPDATE
        );

        // Transition must have been approved by issuer
        if (lrDeltasPassiveMark[1][0] != 0 || lrDeltasPassiveMark[1][1] != 0) {
            rSrStxSetRootChecksum[0] = verifyProofOfActiveStateUpdateAgreement(
                token,
                issuer,
                challenge.trailIdentifier,
                challenge.initialStateEon,
                rSrStxSetRootChecksum[4], // txSetRoot
                lrDeltasPassiveMark[1], // deltas
                issuer,
                rSrStxSetRootChecksum[0], // R[0]
                rSrStxSetRootChecksum[1], // S[0]
                v[0]
            );
            address operator = ledger.operator;
            rSrStxSetRootChecksum[1] = verifyProofOfActiveStateUpdateAgreement(
                token,
                issuer,
                challenge.trailIdentifier,
                challenge.initialStateEon,
                rSrStxSetRootChecksum[4], // txSetRoot
                lrDeltasPassiveMark[1], // deltas
                operator,
                rSrStxSetRootChecksum[2], // R[1]
                rSrStxSetRootChecksum[3], // S[1]
                v[1]
            );
            require(rSrStxSetRootChecksum[0] == rSrStxSetRootChecksum[1], "u");
        } else {
            rSrStxSetRootChecksum[0] = bytes32(0);
        }

        // Transition has to be at least as recent as submitted one
        require(
            lrDeltasPassiveMark[1][0] >= challenge.deltaHighestSpendings &&
                lrDeltasPassiveMark[1][1] >= challenge.deltaHighestGains,
            "x"
        );

        // Transition has to have been properly applied
        checkStateUpdateBalance(
            ledger,
            token,
            issuer,
            challenge,
            lrDeltasPassiveMark[0], // LR
            lrDeltasPassiveMark[1], // deltas
            lrDeltasPassiveMark[2][0]
        ); // passive amount

        // Truffle crashes when trying to interpret this event in some cases.
        emit StateUpdate(
            token,
            issuer,
            challenge.initialStateEon.add(1),
            challenge.trailIdentifier,
            allotmentChain,
            membershipChain,
            values,
            lrDeltasPassiveMark,
            rSrStxSetRootChecksum[0], // activeStateChecksum
            rSrStxSetRootChecksum[5], // passiveAcceptChecksum
            rSrStxSetRootChecksum[2], // R[1]
            rSrStxSetRootChecksum[3], // S[1]
            v[1]
        );

        // Proof of stake must be ratified in the checkpoint
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                issuer,
                [rSrStxSetRootChecksum[0], rSrStxSetRootChecksum[5]], // activeStateChecksum, passiveAcceptChecksum
                challenge.trailIdentifier,
                [
                    challenge.initialStateEon.add(1), // eonNumber
                    lrDeltasPassiveMark[2][0], // passiveAmount
                    lrDeltasPassiveMark[2][1]
                ],
                allotmentChain,
                membershipChain,
                values,
                lrDeltasPassiveMark[0]
            ), // LR
            "c"
        );

        markChallengeAnswered(ledger, challenge);
    }

    // ========================================================================
    // ========================================================================
    // ========================================================================
    // ====================================  ACTIVE DELIVERY Challenge
    // ========================================================================
    // ========================================================================
    // ========================================================================
    function initTransferDeliveryChallenge(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 txNonce,
        uint64 trail
    ) private {
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[token][recipient][sender];
        require(challenge.challengeType == BimodalLib.ChallengeType.NONE);
        require(challenge.initialStateEon < ledger.currentEon().sub(1));

        challenge.challengeType = BimodalLib.ChallengeType.TRANSFER_DELIVERY;
        challenge.initialStateEon = ledger.currentEon().sub(1);
        challenge.deliveredTxNonce = txNonce;
        challenge.block = block.number;
        challenge.trailIdentifier = trail;
        challenge.finalStateBalance = amount;

        markChallengeLive(ledger, token, recipient, sender);
    }

    function challengeTransferDeliveryWithProofOfActiveStateUpdateAgreement(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address[2] SR, // solhint-disable func-param-name-mixedcase
        uint256[2] nonceAmount,
        uint64[3] trails,
        bytes32[] chain,
        uint256[2] deltas,
        bytes32[3] rsTxSetRoot,
        uint8 v
    ) public /* payable */
    /* onlyWithFairReimbursement() */
    {
        require(msg.sender == SR[0] || msg.sender == SR[1], "d");

        // Require hub to have committed to transition
        verifyProofOfActiveStateUpdateAgreement(
            token,
            SR[0],
            trails[0],
            ledger.currentEon().sub(1),
            rsTxSetRoot[2],
            deltas,
            ledger.operator,
            rsTxSetRoot[0],
            rsTxSetRoot[1],
            v
        );

        rsTxSetRoot[0] = MerkleVerifier.transferChecksum(
            SR[1],
            nonceAmount[1], // amount
            trails[2],
            nonceAmount[0]
        ); // nonce

        // Require tx to exist in transition
        require(
            MerkleVerifier.verifyProofOfMembership(
                trails[1],
                chain,
                rsTxSetRoot[0], // transferChecksum
                rsTxSetRoot[2]
            ), // txSetRoot
            "e"
        );

        initTransferDeliveryChallenge(
            ledger,
            token,
            SR[0], // senderAddress
            SR[1], // recipientAddress
            nonceAmount[1], // amount
            nonceAmount[0], // nonce
            trails[2]
        ); // recipientTrail
    }

    function answerTransferDeliveryChallengeWithProofOfActiveStateUpdateAgreement(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address[2] SR, // solhint-disable func-param-name-mixedcase
        uint64 transferMembershipTrail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark,
        bytes32[2] txSetRootChecksum,
        bytes32[] txChain
    ) public {
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[token][SR[1]][SR[0]];
        require(
            challenge.challengeType ==
                BimodalLib.ChallengeType.TRANSFER_DELIVERY
        );

        // Assert that the challenged transaction belongs to the transfer set
        require(
            MerkleVerifier.verifyProofOfMembership(
                transferMembershipTrail,
                txChain,
                MerkleVerifier.transferChecksum(
                    SR[0],
                    challenge.finalStateBalance, // amount
                    challenge.trailIdentifier, // recipient trail
                    challenge.deliveredTxNonce
                ),
                txSetRootChecksum[0]
            )
        ); // txSetRoot

        // Require committed transition to include transfer
        txSetRootChecksum[0] = MerkleVerifier.activeStateUpdateChecksum(
            token,
            SR[1],
            challenge.trailIdentifier,
            challenge.initialStateEon,
            txSetRootChecksum[0], // txSetRoot
            lrDeltasPassiveMark[1]
        ); // Deltas

        // Assert that this transition was used to update the recipient's stake
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                SR[1], // recipient
                txSetRootChecksum, // [activeStateChecksum, passiveChecksum]
                challenge.trailIdentifier,
                [
                    challenge.initialStateEon.add(1), // eonNumber
                    lrDeltasPassiveMark[2][0], // passiveAmount
                    lrDeltasPassiveMark[2][1] // passiveMark
                ],
                allotmentChain,
                membershipChain,
                values,
                lrDeltasPassiveMark[0]
            )
        ); // LR

        markChallengeAnswered(ledger, challenge);
    }

    // ========================================================================
    // ========================================================================
    // ========================================================================
    // ====================================  PASSIVE DELIVERY Challenge
    // ========================================================================
    // ========================================================================
    // ========================================================================
    function challengeTransferDeliveryWithProofOfPassiveStateUpdate(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address[2] SR, // solhint-disable func-param-name-mixedcase
        bytes32[2] txSetRootChecksum,
        uint64[3] senderTransferRecipientTrails,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][4] lrDeltasPassiveMarkDummyAmount,
        bytes32[] transferMembershipChain
    ) public /* payable */
    /* onlyWithFairReimbursement() */
    {
        require(msg.sender == SR[0] || msg.sender == SR[1], "d");
        lrDeltasPassiveMarkDummyAmount[3][0] = ledger.currentEon().sub(1); // previousEon

        // Assert that the challenged transaction ends the transfer set
        require(
            MerkleVerifier.verifyProofOfMembership(
                senderTransferRecipientTrails[1], // transferMembershipTrail
                transferMembershipChain,
                MerkleVerifier.transferChecksum(
                    SR[1], // recipientAddress
                    lrDeltasPassiveMarkDummyAmount[3][1], // amount
                    senderTransferRecipientTrails[2], // recipientTrail
                    2**256 - 1
                ), // nonce
                txSetRootChecksum[0]
            ), // txSetRoot
            "e"
        );

        // Require committed transition to include transfer
        txSetRootChecksum[0] = MerkleVerifier.activeStateUpdateChecksum(
            token,
            SR[0], // senderAddress
            senderTransferRecipientTrails[0], // senderTrail
            lrDeltasPassiveMarkDummyAmount[3][0], // previousEon
            txSetRootChecksum[0], // txSetRoot
            lrDeltasPassiveMarkDummyAmount[1]
        ); // Deltas

        // Assert that this transition was used to update the sender's stake
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                SR[0], // senderAddress
                txSetRootChecksum, // [activeStateChecksum, passiveChecksum]
                senderTransferRecipientTrails[0], // senderTrail
                [
                    lrDeltasPassiveMarkDummyAmount[3][0].add(1), // eonNumber
                    lrDeltasPassiveMarkDummyAmount[2][0], // passiveAmount
                    lrDeltasPassiveMarkDummyAmount[2][1] // passiveMark
                ],
                allotmentChain,
                membershipChain,
                values,
                lrDeltasPassiveMarkDummyAmount[0]
            )
        ); // LR

        initTransferDeliveryChallenge(
            ledger,
            token,
            SR[0], // sender
            SR[1], // recipient
            lrDeltasPassiveMarkDummyAmount[3][1], // amount
            uint256(
                keccak256(
                    abi.encodePacked(
                        lrDeltasPassiveMarkDummyAmount[2][1],
                        uint256(2**256 - 1)
                    )
                )
            ), // mark (nonce)
            senderTransferRecipientTrails[2]
        ); // recipientTrail
    }

    function answerTransferDeliveryChallengeWithProofOfPassiveStateUpdate(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address[2] SR, // solhint-disable func-param-name-mixedcase
        uint64 transferMembershipTrail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][3] lrPassiveMarkPositionNonce,
        bytes32[2] checksums,
        bytes32[] txChainValues
    ) public {
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[token][SR[1]][SR[0]];
        require(
            challenge.challengeType ==
                BimodalLib.ChallengeType.TRANSFER_DELIVERY
        );
        require(
            challenge.deliveredTxNonce ==
                uint256(
                    keccak256(
                        abi.encodePacked(
                            lrPassiveMarkPositionNonce[2][0],
                            lrPassiveMarkPositionNonce[2][1]
                        )
                    )
                )
        );

        // Assert that the challenged transaction belongs to the passively delivered set
        require(
            MerkleVerifier.verifyProofOfPassiveDelivery(
                transferMembershipTrail,
                MerkleVerifier.transferChecksum( // node
                    SR[0], // sender
                    challenge.finalStateBalance, // amount
                    challenge.trailIdentifier, // recipient trail
                    challenge.deliveredTxNonce
                ),
                checksums[1], // passiveChecksum
                txChainValues,
                [
                    lrPassiveMarkPositionNonce[2][0],
                    lrPassiveMarkPositionNonce[2][0].add(
                        challenge.finalStateBalance
                    )
                ]
            ) <= lrPassiveMarkPositionNonce[1][0]
        );

        // Assert that this transition was used to update the recipient's stake
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                SR[1], // recipient
                checksums, // [activeStateChecksum, passiveChecksum]
                challenge.trailIdentifier, // recipientTrail
                [
                    challenge.initialStateEon.add(1), // eonNumber
                    lrPassiveMarkPositionNonce[1][0], // passiveAmount
                    lrPassiveMarkPositionNonce[1][1] // passiveMark
                ],
                allotmentChain,
                membershipChain,
                values,
                lrPassiveMarkPositionNonce[0]
            )
        ); // LR

        markChallengeAnswered(ledger, challenge);
    }

    // ========================================================================
    // ========================================================================
    // ========================================================================
    // ====================================  SWAP Challenge
    // ========================================================================
    // ========================================================================
    // ========================================================================
    function initSwapEnactmentChallenge(
        BimodalLib.Ledger storage ledger,
        ERC20[2] tokens,
        uint256[4] updatedSpentGainedPassive,
        uint256[4] sellBuyBalanceNonce,
        uint64 recipientTrail
    ) private {
        ERC20 conduit = ERC20(
            address(keccak256(abi.encodePacked(tokens[0], tokens[1])))
        );
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[conduit][msg.sender][msg.sender];
        require(challenge.challengeType == BimodalLib.ChallengeType.NONE);
        require(challenge.initialStateEon < ledger.currentEon().sub(1));

        challenge.initialStateEon = ledger.currentEon().sub(1);
        challenge.deliveredTxNonce = sellBuyBalanceNonce[3];
        challenge.challengeType = BimodalLib.ChallengeType.SWAP_ENACTMENT;
        challenge.block = block.number;
        challenge.trailIdentifier = recipientTrail;
        challenge.deltaHighestSpendings = sellBuyBalanceNonce[0];
        challenge.deltaHighestGains = sellBuyBalanceNonce[1];

        (uint256 deposits, uint256 withdrawals) = ledger
            .getCurrentEonDepositsWithdrawals(tokens[0], msg.sender);

        challenge.initialStateBalance = sellBuyBalanceNonce[2] // allotment from eon e - 1
            .add(updatedSpentGainedPassive[2]) // gained
            .add(updatedSpentGainedPassive[3]) // passively delivered
            .add(deposits)
            .sub(updatedSpentGainedPassive[1]) // spent
            .sub(withdrawals);
        challenge.finalStateBalance = updatedSpentGainedPassive[0];

        require(
            challenge.finalStateBalance >= challenge.initialStateBalance,
            "d"
        );

        markChallengeLive(ledger, conduit, msg.sender, msg.sender);
    }

    function challengeSwapEnactmentWithProofOfActiveStateUpdateAgreement(
        BimodalLib.Ledger storage ledger,
        ERC20[2] tokens,
        uint64[3] senderTransferRecipientTrails, // senderTransferRecipientTrails
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        bytes32[] txChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark,
        uint256[4] sellBuyBalanceNonce,
        bytes32[3] txSetRootChecksumDummy
    ) public /* payable */
    /* onlyWithFairReimbursement() */
    {
        // Require swap to exist in transition
        txSetRootChecksumDummy[2] = MerkleVerifier.swapOrderChecksum(
            tokens,
            senderTransferRecipientTrails[2],
            sellBuyBalanceNonce[0], // sell
            sellBuyBalanceNonce[1], // buy
            sellBuyBalanceNonce[2], // balance
            sellBuyBalanceNonce[3]
        ); // nonce

        require(
            MerkleVerifier.verifyProofOfMembership(
                senderTransferRecipientTrails[1],
                txChain,
                txSetRootChecksumDummy[2], // swapOrderChecksum
                txSetRootChecksumDummy[0]
            ), // txSetRoot
            "e"
        );

        uint256 previousEon = ledger.currentEon().sub(1);

        // Require committed transition to include swap
        txSetRootChecksumDummy[2] = MerkleVerifier.activeStateUpdateChecksum(
            tokens[0],
            msg.sender,
            senderTransferRecipientTrails[0],
            previousEon,
            txSetRootChecksumDummy[0],
            lrDeltasPassiveMark[1]
        ); // deltas

        uint256 updatedBalance = lrDeltasPassiveMark[0][1].sub(
            lrDeltasPassiveMark[0][0]
        );
        // The state must have been ratified in the commitment
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                tokens[0],
                msg.sender,
                [txSetRootChecksumDummy[2], txSetRootChecksumDummy[1]], // [activeStateChecksum, passiveChecksum]
                senderTransferRecipientTrails[0],
                [
                    previousEon.add(1), // eonNumber
                    lrDeltasPassiveMark[2][0], // passiveAmount
                    lrDeltasPassiveMark[2][1] // passiveMark
                ],
                allotmentChain,
                membershipChain,
                values,
                lrDeltasPassiveMark[0]
            )
        ); // LR

        initSwapEnactmentChallenge(
            ledger,
            tokens,
            [
                updatedBalance, // updated
                lrDeltasPassiveMark[1][0], // spent
                lrDeltasPassiveMark[1][1], // gained
                lrDeltasPassiveMark[2][0]
            ], // passiveAmount
            sellBuyBalanceNonce,
            senderTransferRecipientTrails[2]
        );
    }

    /**
     * This method just calculates the total expected balance.
     */
    function calculateSwapConsistencyBalance(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        uint256[2] deltas,
        uint256 passiveAmount,
        uint256 balance
    ) private view returns (uint256) {
        (uint256 deposits, uint256 withdrawals) = ledger
            .getCurrentEonDepositsWithdrawals(token, msg.sender);

        return
            balance
                .add(deltas[1]) // gained
                .add(passiveAmount) // passively delivered
                .add(deposits)
                .sub(withdrawals)
                .sub(deltas[0]); // spent
    }

    /**
     * This method calculates the balance expected to be credited in return for that
     * debited in another token according to the swapping price and is adjusted to
     * ignore numerical errors up to 2 decimal places.
     */
    function verifySwapConsistency(
        BimodalLib.Ledger storage ledger,
        ERC20[2] tokens,
        BimodalLib.Challenge challenge,
        uint256[2] LR, // solhint-disable func-param-name-mixedcase
        uint256[2] deltas,
        uint256 passiveAmount,
        uint256 balance
    ) private view returns (bool) {
        balance = calculateSwapConsistencyBalance(
            ledger,
            tokens[1],
            deltas,
            passiveAmount,
            balance
        );

        require(LR[1].sub(LR[0]) >= balance);

        uint256 taken = challenge
            .deltaHighestSpendings // sell amount
            .sub(
            challenge.finalStateBalance.sub(challenge.initialStateBalance)
        ); // refund
        uint256 given = LR[1]
            .sub(LR[0]) // recipient allotment
            .sub(balance); // authorized allotment

        return
            taken.mul(challenge.deltaHighestGains).div(100) >=
            challenge.deltaHighestSpendings.mul(given).div(100);
    }

    function answerSwapChallengeWithProofOfExclusiveBalanceAllotment(
        BimodalLib.Ledger storage ledger,
        ERC20[2] tokens,
        address issuer,
        uint64 transferMembershipTrail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        bytes32[] txChain,
        uint256[] values,
        uint256[2][3] lrDeltasPassiveMark,
        uint256 balance,
        bytes32[3] txSetRootChecksumDummy
    ) public {
        ERC20 conduit = ERC20(
            address(keccak256(abi.encodePacked(tokens[0], tokens[1])))
        );
        BimodalLib.Challenge storage challenge = ledger
            .challengeBook[conduit][issuer][issuer];
        require(
            challenge.challengeType == BimodalLib.ChallengeType.SWAP_ENACTMENT
        );

        // Assert that the challenged swap belongs to the transition
        txSetRootChecksumDummy[2] = MerkleVerifier.swapOrderChecksum(
            tokens,
            challenge.trailIdentifier, // recipient trail
            challenge.deltaHighestSpendings, // sell amount
            challenge.deltaHighestGains, // buy amount
            balance, // starting balance
            challenge.deliveredTxNonce
        );

        require(
            MerkleVerifier.verifyProofOfMembership(
                transferMembershipTrail,
                txChain,
                txSetRootChecksumDummy[2], // order checksum
                txSetRootChecksumDummy[0]
            ),
            "M"
        ); // txSetRoot

        // Require committed transition to include swap
        txSetRootChecksumDummy[2] = MerkleVerifier.activeStateUpdateChecksum(
            tokens[1],
            issuer,
            challenge.trailIdentifier,
            challenge.initialStateEon,
            txSetRootChecksumDummy[0], // txSetRoot
            lrDeltasPassiveMark[1]
        ); // deltas

        if (balance != 2**256 - 1) {
            require(
                verifySwapConsistency(
                    ledger,
                    tokens,
                    challenge,
                    lrDeltasPassiveMark[0],
                    lrDeltasPassiveMark[1],
                    lrDeltasPassiveMark[2][0],
                    balance
                ),
                "v"
            );
        }

        // Assert that this transition was used to update the recipient's stake
        require(
            verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                tokens[1],
                issuer,
                [txSetRootChecksumDummy[2], txSetRootChecksumDummy[1]], // activeStateChecksum, passiveChecksum
                challenge.trailIdentifier,
                [
                    challenge.initialStateEon.add(1),
                    lrDeltasPassiveMark[2][0],
                    lrDeltasPassiveMark[2][1]
                ],
                allotmentChain,
                membershipChain,
                values,
                lrDeltasPassiveMark[0]
            ), // LR
            "s"
        );

        markChallengeAnswered(ledger, challenge);
    }

    // ========================================================================
    // ========================================================================
    // ========================================================================
    // ====================================  WITHDRAWAL Challenge
    // ========================================================================
    // ========================================================================
    // ========================================================================
    function slashWithdrawalWithProofOfMinimumAvailableBalance(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address withdrawer,
        uint256[2] markerEonAvailable,
        bytes32[2] rs,
        uint8 v
    ) public returns (uint256[2] amounts) {
        uint256 latestEon = ledger.currentEon();
        require(latestEon < markerEonAvailable[0].add(3), "m");

        bytes32 checksum = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(address(this))),
                keccak256(abi.encodePacked(token)),
                keccak256(abi.encodePacked(withdrawer)),
                markerEonAvailable[0],
                markerEonAvailable[1]
            )
        );

        require(
            withdrawer ==
                BimodalLib.signedMessageECRECOVER(checksum, rs[0], rs[1], v)
        );

        BimodalLib.Wallet storage entry = ledger.walletBook[token][withdrawer];
        BimodalLib.Withdrawal[] storage withdrawals = entry.withdrawals;

        for (uint32 i = 1; i <= withdrawals.length; i++) {
            BimodalLib.Withdrawal storage withdrawal = withdrawals[withdrawals
                .length
                .sub(i)];

            if (withdrawal.eon.add(1) < latestEon) {
                break;
            } else if (withdrawal.eon == latestEon.sub(1)) {
                amounts[0] = amounts[0].add(withdrawal.amount);
            } else if (withdrawal.eon == latestEon) {
                amounts[1] = amounts[1].add(withdrawal.amount);
            }
        }

        require(amounts[0].add(amounts[1]) > markerEonAvailable[1]);

        withdrawals.length = withdrawals.length.sub(i.sub(1)); // i >= 1

        if (amounts[1] > 0) {
            ledger.deductFromRunningPendingWithdrawals(
                token,
                latestEon,
                latestEon,
                amounts[1]
            );
            ledger.appendOperationToEonAccumulator(
                latestEon,
                token,
                withdrawer,
                BimodalLib.Operation.CANCELLATION,
                amounts[1]
            );
        }

        if (amounts[0] > 0) {
            ledger.deductFromRunningPendingWithdrawals(
                token,
                latestEon.sub(1),
                latestEon,
                amounts[0]
            );
            ledger.appendOperationToEonAccumulator(
                latestEon.sub(1),
                token,
                withdrawer,
                BimodalLib.Operation.CANCELLATION,
                amounts[0]
            );
        }
    }
}
"},"ChallengeProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./BimodalProxy.sol";
import "./ERC20.sol";
import "./BimodalLib.sol";
import "./MerkleVerifier.sol";
import "./ChallengeLib.sol";
import "./SafeMathLib256.sol";

contract ChallengeProxy is BimodalProxy {
  using SafeMathLib256 for uint256;
  
  modifier onlyWithFairReimbursement() {
    uint256 gas = gasleft();
    _;
    gas = gas.sub(gasleft());
    require(
      msg.value >= gas.mul(ledger.MIN_CHALLENGE_GAS_COST) &&
      msg.value >= gas.mul(tx.gasprice),
      'r');
    ledger.operator.transfer(msg.value);
  }

  modifier onlyWithSkewedReimbursement(uint256 extra) {
    uint256 gas = gasleft();
    _;
    gas = gas.sub(gasleft());
    require(
      msg.value >= gas.add(extra).mul(ledger.MIN_CHALLENGE_GAS_COST) &&
      msg.value >= gas.add(extra).mul(tx.gasprice),
      'r');
    ledger.operator.transfer(msg.value);
  }

  // =========================================================================
  function verifyProofOfExclusiveAccountBalanceAllotment(
    ERC20 token,
    address holder,
    bytes32[2] activeStateChecksum_passiveTransfersRoot, // solhint-disable func-param-name-mixedcase
    uint64 trail,
    uint256[3] eonPassiveMark,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] values,
    uint256[2] LR // solhint-disable-line func-param-name-mixedcase
  )
    public
    view
    returns (bool)
  {
    return ChallengeLib.verifyProofOfExclusiveAccountBalanceAllotment(
      ledger,
      token,
      holder,
      activeStateChecksum_passiveTransfersRoot,
      trail,
      eonPassiveMark,
      allotmentChain,
      membershipChain,
      values,
      LR
    );
  }

  function verifyProofOfActiveStateUpdateAgreement(
    ERC20 token,
    address holder,
    uint64 trail,
    uint256 eon,
    bytes32 txSetRoot,
    uint256[2] deltas,
    address attester, bytes32 r, bytes32 s, uint8 v
  )
    public
    view
    returns (bytes32 checksum)
  {
    return ChallengeLib.verifyProofOfActiveStateUpdateAgreement(
      token,
      holder,
      trail,
      eon,
      txSetRoot,
      deltas,
      attester,
      r,
      s,
      v
    );
  }

  function verifyWithdrawalAuthorization(
    ERC20 token,
    address holder,
    uint256 expiry,
    uint256 amount,
    address attester,
    bytes32 r, bytes32 s, uint8 v
  )
    public
    view
    returns (bool)
  {
    return ChallengeLib.verifyWithdrawalAuthorization(
      token,
      holder,
      expiry,
      amount,
      attester,
      r,
      s,
      v
    );
  }

  function verifyProofOfExclusiveBalanceAllotment(
    uint64 allotmentTrail,
    uint64 membershipTrail,
    bytes32 node,
    bytes32 root,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] value,
    uint256[2] LR // solhint-disable-line func-param-name-mixedcase
  )
    public
    pure
    returns (uint256)
  {
    return MerkleVerifier.verifyProofOfExclusiveBalanceAllotment(
      allotmentTrail,
      membershipTrail,
      node,
      root,
      allotmentChain,
      membershipChain,
      value,
      LR
    );
  }

  function verifyProofOfMembership(
    uint256 trail,
    bytes32[] chain,
    bytes32 node,
    bytes32 merkleRoot
  )
    public
    pure
    returns (bool)
  {
    return MerkleVerifier.verifyProofOfMembership(
      trail,
      chain,
      node,
      merkleRoot
    );
  }

  function verifyProofOfPassiveDelivery(
    uint64 allotmentTrail,
    bytes32 node,
    bytes32 root,
    bytes32[] chainValues,
    uint256[2] LR // solhint-disable-line func-param-name-mixedcase
  )
    public
    pure
    returns (uint256)
  {
    return MerkleVerifier.verifyProofOfPassiveDelivery(
      allotmentTrail,
      node,
      root,
      chainValues,
      LR
    );
  }

  // =========================================================================
  function challengeStateUpdateWithProofOfExclusiveBalanceAllotment(
    ERC20 token,
    bytes32[2] checksums,
    uint64 trail,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] value,
    uint256[2][3] lrDeltasPassiveMark,
    bytes32[3] rsTxSetRoot,
    uint8 v
  )
    public
    payable
    onlyWithFairReimbursement()
  {
    ChallengeLib.challengeStateUpdateWithProofOfExclusiveBalanceAllotment(
      ledger,
      token,
      checksums,
      trail,
      allotmentChain,
      membershipChain,
      value,
      lrDeltasPassiveMark,
      rsTxSetRoot,
      v
    );
  }
  
  function challengeStateUpdateWithProofOfActiveStateUpdateAgreement(
    ERC20 token,
    bytes32 txSetRoot,
    uint64 trail,
    uint256[2] deltas,
    bytes32 r, bytes32 s, uint8 v
  )
    public
    payable
    onlyWithSkewedReimbursement(25) /* TODO calculate exact addition */
  {
    ChallengeLib.challengeStateUpdateWithProofOfActiveStateUpdateAgreement(
      ledger,
      token,
      txSetRoot,
      trail,
      deltas,
      r,
      s,
      v
    );
  }

  function answerStateUpdateChallenge(
    ERC20 token,
    address issuer,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] values,
    uint256[2][3] lrDeltasPassiveMark, // [ [L, R], Deltas ]
    bytes32[6] rSrStxSetRootChecksum,
    uint8[2] v
  )
    public
  {
    ChallengeLib.answerStateUpdateChallenge(
      ledger,
      token,
      issuer,
      allotmentChain,
      membershipChain,
      values,
      lrDeltasPassiveMark,
      rSrStxSetRootChecksum,
      v
    );
  }

  // =========================================================================
  function challengeTransferDeliveryWithProofOfActiveStateUpdateAgreement(
    ERC20 token,
    address[2] SR, // solhint-disable-line func-param-name-mixedcase
    uint256[2] nonceAmount,
    uint64[3] trails,
    bytes32[] chain,
    uint256[2] deltas,
    bytes32[3] rsTxSetRoot,
    uint8 v
  )
    public
    payable
    onlyWithFairReimbursement()
  {
    ChallengeLib.challengeTransferDeliveryWithProofOfActiveStateUpdateAgreement(
      ledger,
      token,
      SR,
      nonceAmount,
      trails,
      chain,
      deltas,
      rsTxSetRoot,
      v
    );
  }

  function answerTransferDeliveryChallengeWithProofOfActiveStateUpdateAgreement(
    ERC20 token,
    address[2] SR, // solhint-disable-line func-param-name-mixedcase
    uint64 transferMembershipTrail,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] values,
    uint256[2][3] lrDeltasPassiveMark,
    bytes32[2] txSetRootChecksum,
    bytes32[] txChain
  )
    public
  {
    ChallengeLib.answerTransferDeliveryChallengeWithProofOfActiveStateUpdateAgreement(
      ledger,
      token,
      SR,
      transferMembershipTrail,
      allotmentChain,
      membershipChain,
      values,
      lrDeltasPassiveMark,
      txSetRootChecksum,
      txChain
    );
  }

  // =========================================================================
  function challengeTransferDeliveryWithProofOfPassiveStateUpdate(
    ERC20 token,
    address[2] SR, // solhint-disable-line func-param-name-mixedcase
    bytes32[2] txSetRootChecksum,
    uint64[3] senderTransferRecipientTrails,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] values,
    uint256[2][4] lrDeltasPassiveMarkDummyAmount,
    bytes32[] transferMembershipChain
  )
    public
    payable
    onlyWithFairReimbursement()
  {
    ChallengeLib.challengeTransferDeliveryWithProofOfPassiveStateUpdate(
      ledger,
      token,
      SR,
      txSetRootChecksum,
      senderTransferRecipientTrails,
      allotmentChain,
      membershipChain,
      values,
      lrDeltasPassiveMarkDummyAmount,
      transferMembershipChain
    );
  }

  function answerTransferDeliveryChallengeWithProofOfPassiveStateUpdate(
    ERC20 token,
    address[2] SR, // solhint-disable-line func-param-name-mixedcase
    uint64 transferMembershipTrail,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] values,
    uint256[2][3] lrPassiveMarkPositionNonce,
    bytes32[2] checksums,
    bytes32[] txChainValues
  )
    public
  {
    ChallengeLib.answerTransferDeliveryChallengeWithProofOfPassiveStateUpdate(
      ledger,
      token,
      SR,
      transferMembershipTrail,
      allotmentChain,
      membershipChain,
      values,
      lrPassiveMarkPositionNonce,
      checksums,
      txChainValues
    );
  }

  // =========================================================================
  function challengeSwapEnactmentWithProofOfActiveStateUpdateAgreement(
    ERC20[2] tokens,
    uint64[3] senderTransferRecipientTrails,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    bytes32[] txChain,
    uint256[] values,
    uint256[2][3] lrDeltasPassiveMark,
    uint256[4] sellBuyBalanceNonce,
    bytes32[3] txSetRootChecksumDummy
  )
    public
    payable
    onlyWithFairReimbursement()
  {
    ChallengeLib.challengeSwapEnactmentWithProofOfActiveStateUpdateAgreement(
      ledger,
      tokens,
      senderTransferRecipientTrails,
      allotmentChain,
      membershipChain,
      txChain,
      values,
      lrDeltasPassiveMark,
      sellBuyBalanceNonce,
      txSetRootChecksumDummy
    );
  }

  function answerSwapChallengeWithProofOfExclusiveBalanceAllotment(
    ERC20[2] tokens,
    address issuer,
    uint64 transferMembershipTrail,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    bytes32[] txChain,
    uint256[] values,
    uint256[2][3] lrDeltasPassiveMark,
    uint256 balance,
    bytes32[3] txSetRootChecksumDummy
  )
    public
  {
    ChallengeLib.answerSwapChallengeWithProofOfExclusiveBalanceAllotment(
      ledger,
      tokens,
      issuer,
      transferMembershipTrail,
      allotmentChain,
      membershipChain,
      txChain,
      values,
      lrDeltasPassiveMark,
      balance,
      txSetRootChecksumDummy
    );
  }

  // =========================================================================
  function slashWithdrawalWithProofOfMinimumAvailableBalance(
    ERC20 token,
    address withdrawer,
    uint256[2] markerEonAvailable,
    bytes32[2] rs,
    uint8 v
  )
    public
    returns (uint256[2])
  {
    return ChallengeLib.slashWithdrawalWithProofOfMinimumAvailableBalance(
      ledger,
      token,
      withdrawer,
      markerEonAvailable,
      rs,
      v
    );
  }
}
"},"DepositLib.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./BimodalLib.sol";
import "./SafeMathLib256.sol";

/**
 * This library defines the secure deposit method. The relevant data is recorded
 * on the parent chain to ascertain that a registered wallet would always be able
 * to ensure its commit chain state update consistency with the parent chain.
 */
library DepositLib {
  using SafeMathLib256 for uint256;
  using BimodalLib for BimodalLib.Ledger;
  // EVENTS
  event Deposit(address indexed token, address indexed recipient, uint256 amount);

  function deposit(
    BimodalLib.Ledger storage ledger,
    ERC20 token,
    address beneficiary,
    uint256 amount
  )
    public
    /* payable */
    /* onlyWhenContractUnpunished() */
  {
    uint256 eon = ledger.currentEon();

    uint256 value = msg.value;
    if (token != address(this)) {
      require(ledger.tokenToTrail[token] != 0,
        't');
      require(msg.value == 0,
        'm');
      require(token.transferFrom(beneficiary, this, amount),
        'f');
      value = amount;
    }

    BimodalLib.Wallet storage entry = ledger.walletBook[token][beneficiary];
    BimodalLib.AmountAggregate storage depositAggregate = entry.depositsKept[eon.mod(ledger.DEPOSITS_KEPT)];
    BimodalLib.addToAggregate(depositAggregate, eon, value);

    BimodalLib.AmountAggregate storage eonDeposits = ledger.deposits[token][eon.mod(ledger.EONS_KEPT)];
    BimodalLib.addToAggregate(eonDeposits, eon, value);

    ledger.appendOperationToEonAccumulator(eon, token, beneficiary, BimodalLib.Operation.DEPOSIT, value);

    emit Deposit(token, beneficiary, value);
  }
}
"},"DepositProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./BimodalLib.sol";
import "./BimodalProxy.sol";
import "./DepositLib.sol";
import "./SafeMathLib256.sol";

contract DepositProxy is BimodalProxy {
  using SafeMathLib256 for uint256;

  function()
    public
    payable
  {}

  function deposit(
    ERC20 token,
    address beneficiary,
    uint256 amount
  )
    public
    payable
    onlyWhenContractUnpunished()
  {
    DepositLib.deposit(
      ledger,
      token,
      beneficiary,
      amount);
  }
}
"},"ERC20.sol":{"content":"pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
"},"ERC20TokenImplementation.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./SafeMathLib256.sol";

/* solhint-disable max-line-length */

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/1200969eb6e0a066b1e52fb2e76a786a486706ff/contracts/token/ERC20/BasicToken.sol
 */
contract BasicToken is ERC20Basic {
  using SafeMathLib256 for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/1200969eb6e0a066b1e52fb2e76a786a486706ff/contracts/token/ERC20/StandardToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  using SafeMathLib256 for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
  )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/1200969eb6e0a066b1e52fb2e76a786a486706ff/contracts/token/ERC20/DetailedERC20.sol
 */
contract DetailedERC20 is ERC20 {
  using SafeMathLib256 for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

interface ApprovalSpender {
  function receiveApproval(address from, uint256 value, address token, bytes data) external;
}

/**
 * @title Liquidity.Network Fungible Token Contract
 * Built on OpenZeppelin-Solidity Contracts https://github.com/OpenZeppelin/openzeppelin-solidity/tree/1200969eb6e0a066b1e52fb2e76a786a486706ff
 */
contract ERC20TokenImplementation is StandardToken, DetailedERC20 {
  using SafeMathLib256 for uint256;
  
  constructor()
    public
    DetailedERC20("Liquidity.Network Token", "LQD", 18)
  {
    totalSupply_ = 100000000 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply_;
    emit Transfer(0x0, msg.sender, totalSupply_);
  }

  function approveAndCall(ApprovalSpender recipientContract, uint256 value, bytes data) public returns (bool) {
    if (approve(recipientContract, value)) {
      recipientContract.receiveApproval(msg.sender, value, address(this), data);
      return true;
    }
  }
}
"},"MerkleVerifier.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./SafeMathLib32.sol";
import "./SafeMathLib64.sol";
import "./SafeMathLib256.sol";

/*
This library defines a collection of different checksumming procedures for
membership, exclusive allotment and data.
*/
library MerkleVerifier {
    using SafeMathLib32 for uint32;
    using SafeMathLib64 for uint64;
    using SafeMathLib256 for uint256;

    /**
     * Calculate a vanilla merkle root from a chain of hashes with a fixed height
     * starting from the leaf node.
     */
    function calculateMerkleRoot(
        uint256 trail,
        bytes32[] chain,
        bytes32 node
    ) public pure returns (bytes32) {
        for (uint32 i = 0; i < chain.length; i++) {
            bool linkLeft = false;
            if (trail > 0) {
                linkLeft = trail.mod(2) == 1;
                trail = trail.div(2);
            }
            node = keccak256(
                abi.encodePacked(
                    i,
                    linkLeft ? chain[i] : node,
                    linkLeft ? node : chain[i]
                )
            );
        }
        return node;
    }

    function verifyProofOfMembership(
        uint256 trail,
        bytes32[] chain,
        bytes32 node,
        bytes32 merkleRoot
    ) public pure returns (bool) {
        return calculateMerkleRoot(trail, chain, node) == merkleRoot;
    }

    /**
     * Calculate an annotated merkle tree root from a chain of hashes and sibling
     * values with a fixed height starting from the leaf node.
     * @return the allotment of the root node.
     */
    function verifyProofOfExclusiveBalanceAllotment(
        uint64 allotmentTrail,
        uint64 membershipTrail,
        bytes32 node,
        bytes32 root,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] value,
        uint256[2] LR // solhint-disable-line func-param-name-mixedcase
    ) public pure returns (uint256) {
        require(value.length == allotmentChain.length, "p");

        require(LR[1] >= LR[0], "s");
        for (uint32 i = 0; i < value.length; i++) {
            bool linkLeft = false; // is the current chain link on the left of this node
            if (allotmentTrail > 0) {
                linkLeft = allotmentTrail.mod(2) == 1;
                allotmentTrail = allotmentTrail.div(2);
            }

            node = keccak256(
                abi.encodePacked(
                    i,
                    linkLeft ? value[i] : LR[0], // leftmost value
                    keccak256(
                        abi.encodePacked(
                            linkLeft ? allotmentChain[i] : node, // left node
                            linkLeft ? LR[0] : LR[1], // middle value
                            linkLeft ? node : allotmentChain[i] // right node
                        )
                    ),
                    linkLeft ? LR[1] : value[i] // rightmost value
                )
            );

            require(linkLeft ? value[i] <= LR[0] : LR[1] <= value[i], "x");

            LR[0] = linkLeft ? value[i] : LR[0];
            LR[1] = linkLeft ? LR[1] : value[i];

            require(LR[1] >= LR[0], "t");
        }
        require(LR[0] == 0, "l");

        node = keccak256(abi.encodePacked(LR[0], node, LR[1]));

        require(
            verifyProofOfMembership(
                membershipTrail,
                membershipChain,
                node,
                root
            ),
            "m"
        );

        return LR[1];
    }

    /**
     * Calculate an annotated merkle tree root from a combined array containing
     * the chain of hashes and sibling values with a fixed height starting from the
     * leaf node.
     */
    function verifyProofOfPassiveDelivery(
        uint64 allotmentTrail,
        bytes32 node,
        bytes32 root,
        bytes32[] chainValues,
        uint256[2] LR
    ) public pure returns (uint256) {
        require(chainValues.length.mod(2) == 0, "p");

        require(LR[1] >= LR[0], "s");
        uint32 v = uint32(chainValues.length.div(2));
        for (uint32 i = 0; i < v; i++) {
            bool linkLeft = false; // is the current chain link on the left of this node
            if (allotmentTrail > 0) {
                linkLeft = allotmentTrail.mod(2) == 1;
                allotmentTrail = allotmentTrail.div(2);
            }

            node = keccak256(
                abi.encodePacked(
                    i,
                    linkLeft ? uint256(chainValues[i.add(v)]) : LR[0], // leftmost value
                    keccak256(
                        abi.encodePacked(
                            linkLeft ? chainValues[i] : node, // left node
                            linkLeft ? LR[0] : LR[1], // middle value
                            linkLeft ? node : chainValues[i] // right node
                        )
                    ),
                    linkLeft ? LR[1] : uint256(chainValues[i.add(v)]) // rightmost value
                )
            );

            require(
                linkLeft
                    ? uint256(chainValues[i.add(v)]) <= LR[0]
                    : LR[1] <= uint256(chainValues[i.add(v)]),
                "x"
            );

            LR[0] = linkLeft ? uint256(chainValues[i.add(v)]) : LR[0];
            LR[1] = linkLeft ? LR[1] : uint256(chainValues[i.add(v)]);

            require(LR[1] >= LR[0], "t");
        }
        require(LR[0] == 0, "l");

        require(node == root, "n");

        return LR[1];
    }

    function transferChecksum(
        address counterparty,
        uint256 amount,
        uint64 recipientTrail,
        uint256 nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    keccak256(abi.encodePacked(counterparty)),
                    amount,
                    recipientTrail,
                    nonce
                )
            );
    }

    function swapOrderChecksum(
        ERC20[2] tokens,
        uint64 recipientTrail,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 startBalance,
        uint256 nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    keccak256(abi.encodePacked(tokens[0])),
                    keccak256(abi.encodePacked(tokens[1])),
                    recipientTrail,
                    sellAmount,
                    buyAmount,
                    startBalance,
                    nonce
                )
            );
    }

    function activeStateUpdateChecksum(
        ERC20 token,
        address holder,
        uint64 trail,
        uint256 eon,
        bytes32 txSetRoot,
        uint256[2] deltas
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    keccak256(abi.encodePacked(address(this))),
                    keccak256(abi.encodePacked(token)),
                    keccak256(abi.encodePacked(holder)),
                    trail,
                    eon,
                    txSetRoot,
                    deltas[0],
                    deltas[1]
                )
            );
    }
}
"},"MerkleVerifierProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./MerkleVerifier.sol";

contract MerkleVerifierProxy {
  function calculateMerkleRoot(
    uint256 trail,
    bytes32[] chain,
    bytes32 node
  )
    public
    pure
    returns (bytes32)
  {
    return MerkleVerifier.calculateMerkleRoot(trail, chain, node);
  }

  function verifyProofOfExclusiveBalanceAllotment(
    uint64 allotmentTrail,
    uint64 membershipTrail,
    bytes32 node,
    bytes32 root,
    bytes32[] allotmentChain,
    bytes32[] membershipChain,
    uint256[] value,
    uint256[2] LR // solhint-disable-line func-param-name-mixedcase
  )
    public
    pure
    returns (uint256)
  {
    return MerkleVerifier.verifyProofOfExclusiveBalanceAllotment(
      allotmentTrail,
      membershipTrail,
      node,
      root,
      allotmentChain,
      membershipChain,
      value,
      LR
    );
  }

  function verifyProofOfPassiveDelivery(
    uint64 allotmentTrail,
    bytes32 node,
    bytes32 root,
    bytes32[] chainValues,
    uint256[2] LR // solhint-disable-line func-param-name-mixedcase
  )
    public
    pure
    returns (uint256)
  {
    MerkleVerifier.verifyProofOfPassiveDelivery(
      allotmentTrail,
      node,
      root,
      chainValues,
      LR
    );
  }

  function transferChecksum(
    address counterparty,
    uint256 amount,
    uint64 recipientTrail,
    uint256 nonce
  )
    public
    pure
    returns (bytes32)
  {
    return MerkleVerifier.transferChecksum(
      counterparty,
      amount,
      recipientTrail,
      nonce
    );
  }

  function swapOrderChecksum(
    ERC20[2] tokens,
    uint64 recipientTrail,
    uint256 sellAmount,
    uint256 buyAmount,
    uint256 startBalance,
    uint256 nonce
  )
    public
    pure
    returns (bytes32)
  {
    return MerkleVerifier.swapOrderChecksum(
      tokens,
      recipientTrail,
      sellAmount,
      buyAmount,
      startBalance,
      nonce
    );
  }

  function activeStateUpdateChecksum(
    ERC20 token,
    address holder,
    uint64 trail,
    uint256 eon,
    bytes32 txSetRoot,
    uint256[2] deltas
  )
    public
    view
    returns (bytes32)
  {
    return MerkleVerifier.activeStateUpdateChecksum(
      token,
      holder,
      trail,
      eon,
      txSetRoot,
      deltas
    );
  }
}
"},"Migrations.sol":{"content":"pragma solidity ^0.4.24;

contract Migrations {
  address public owner;
  uint256 public lastCompletedMigration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor()
    public
  {
    owner = msg.sender;
  }

  function setCompleted(uint256 completed)
    public
    restricted
  {
    lastCompletedMigration = completed;
  }

  function upgrade(address newAddress)
    public
    restricted
  {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(lastCompletedMigration);
  }
}
"},"NOCUSTCommitChain.sol":{"content":"pragma solidity ^0.4.24;

import "./BimodalProxy.sol";
import "./DepositProxy.sol";
import "./WithdrawalProxy.sol";
import "./ChallengeProxy.sol";
import "./RecoveryProxy.sol";
import "./SafeMathLib256.sol";

/**
 * This is the main Parent-chain Verifier contract. It inherits all of the proxy
 * contracts and provides a single address to interact with all the moderated
 * balance pools. Proxies define the exposed methods, events and enforce the
 * modifiers of library methods.
 */
contract NOCUSTCommitChain is
    BimodalProxy,
    DepositProxy,
    WithdrawalProxy,
    ChallengeProxy,
    RecoveryProxy
{
    using SafeMathLib256 for uint256;

    /**
     * This is the main constructor.
     * @param blocksPerEon - The number of blocks per eon.
     * @param operator - The IMMUTABLE address of the operator.
     */
    constructor(uint256 blocksPerEon, address operator)
        public
        BimodalProxy(blocksPerEon, operator)
    {
        // Support ETH by default
        ledger.trailToToken.push(address(this));
        ledger.tokenToTrail[address(this)] = 0;
    }

    /**
     * This allows the operator to register the existence of another ERC20 token
     * @param token - ERC20 token address
     */
    function registerERC20(ERC20 token) public onlyOperator() {
        require(ledger.tokenToTrail[token] == 0);
        ledger.tokenToTrail[token] = uint64(ledger.trailToToken.length);
        ledger.trailToToken.push(token);
    }

    /**
     * This method allows the operator to submit one checkpoint per eon that
     * synchronizes the commit-chain ledger with the parent chain.
     * @param accumulator - The accumulator of the previous eon under which this checkpoint is calculated.
     * @param merkleRoot - The checkpoint merkle root.
     */
    function submitCheckpoint(bytes32 accumulator, bytes32 merkleRoot)
        public
        onlyOperator()
        onlyWhenContractUnpunished()
    {
        uint256 eon = ledger.currentEon();
        require(
            ledger.parentChainAccumulator[eon.sub(1).mod(ledger.EONS_KEPT)] ==
                accumulator,
            "b"
        );
        require(ledger.getLiveChallenges(eon.sub(1)) == 0, "c");
        require(eon > ledger.lastSubmissionEon, "d");

        ledger.lastSubmissionEon = eon;

        BimodalLib.Checkpoint storage checkpoint = ledger.getOrCreateCheckpoint(
            eon,
            eon
        );
        checkpoint.merkleRoot = merkleRoot;

        emit CheckpointSubmission(eon, merkleRoot);
    }
}
"},"RecoveryLib.sol":{"content":"/* solhint-disable func-order */

pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./BimodalLib.sol";
import "./ChallengeLib.sol";
import "./SafeMathLib256.sol";

/**
 * This library contains the implementation for the secure commit-chain recovery
 * procedure that can be used when the operator of the commit chain is halted by
 * the main verifier contract. The methods in this library are only relevant for
 * recovering the last confirmed balances of the accounts in the commit chain.
 */
library RecoveryLib {
    using SafeMathLib256 for uint256;
    using BimodalLib for BimodalLib.Ledger;

    function reclaimUncommittedDeposits(
        BimodalLib.Ledger storage ledger,
        BimodalLib.Wallet storage wallet
    ) private returns (uint256 amount) {
        for (uint8 i = 0; i < ledger.DEPOSITS_KEPT; i++) {
            BimodalLib.AmountAggregate storage depositAggregate = wallet
                .depositsKept[i];
            // depositAggregate.eon < ledger.lastSubmissionEon.sub(1)
            if (depositAggregate.eon.add(1) < ledger.lastSubmissionEon) {
                continue;
            }
            amount = amount.add(depositAggregate.amount);
            BimodalLib.clearAggregate(depositAggregate);
        }
    }

    function reclaimFinalizedWithdrawal(
        BimodalLib.Ledger storage ledger,
        BimodalLib.Wallet storage wallet
    ) private returns (uint256 amount) {
        BimodalLib.Withdrawal[] storage withdrawals = wallet.withdrawals;
        for (uint32 i = 0; i < withdrawals.length; i++) {
            BimodalLib.Withdrawal storage withdrawal = withdrawals[i];

            if (withdrawal.eon.add(2) > ledger.lastSubmissionEon) {
                break;
            }

            amount = amount.add(withdrawal.amount);
            delete withdrawals[i];
        }
    }

    /*
     * This method can be called without an accompanying proof of exclusive allotment
     * to claim only the funds pending in the parent chain.
     */
    function recoverOnlyParentChainFunds(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address holder
    )
        public
        returns (
            /* onlyWhenContractPunished() */
            uint256 reclaimed
        )
    {
        BimodalLib.Wallet storage wallet = ledger.walletBook[token][holder];

        reclaimed = reclaimUncommittedDeposits(ledger, wallet).add(
            reclaimFinalizedWithdrawal(ledger, wallet)
        );

        if (ledger.lastSubmissionEon > 0) {
            BimodalLib.AmountAggregate storage eonWithdrawals = ledger
                .confirmedWithdrawals[token][ledger
                .lastSubmissionEon
                .sub(1)
                .mod(ledger.EONS_KEPT)];
            BimodalLib.addToAggregate(
                eonWithdrawals,
                ledger.lastSubmissionEon.sub(1),
                reclaimed
            );
        }

        if (token != address(this)) {
            require(ledger.tokenToTrail[token] != 0, "t");
            require(token.transfer(holder, reclaimed), "f");
        } else {
            holder.transfer(reclaimed);
        }
    }

    /**
     * This method requires an accompanying proof of exclusive allotment to claim
     *the funds pending in the parent chain along with those exclusively allotted
     * in the commit chain.
     */
    function recoverAllFunds(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address holder,
        bytes32[2] checksums,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2] LR, // solhint-disable func-param-name-mixedcase
        uint256[3] dummyPassiveMark
    )
        public
        returns (
            /* onlyWhenContractPunished() */
            uint256 recovered
        )
    {
        BimodalLib.Wallet storage wallet = ledger.walletBook[token][holder];
        require(!wallet.recovered, "a");
        wallet.recovered = true;

        recovered = LR[1].sub(LR[0]); // excluslive allotment
        recovered = recovered.add(reclaimUncommittedDeposits(ledger, wallet)); // unallotted parent chain deposits
        recovered = recovered.add(reclaimFinalizedWithdrawal(ledger, wallet)); // confirmed parent chain withdrawal

        if (ledger.lastSubmissionEon > 0) {
            dummyPassiveMark[0] = ledger.lastSubmissionEon.sub(1); // confirmedEon
        } else {
            dummyPassiveMark[0] = 0;
        }

        require(
            ChallengeLib.verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                holder,
                checksums,
                trail,
                dummyPassiveMark, // [confirmedEon, passiveAmount, passiveMark]
                allotmentChain,
                membershipChain,
                values,
                LR
            ),
            "p"
        );

        BimodalLib.AmountAggregate storage eonWithdrawals = ledger
            .confirmedWithdrawals[token][dummyPassiveMark[0].mod(
            ledger.EONS_KEPT
        )];
        BimodalLib.addToAggregate(
            eonWithdrawals,
            dummyPassiveMark[0],
            recovered
        );

        if (token != address(this)) {
            require(ledger.tokenToTrail[token] != 0, "t");
            require(token.transfer(holder, recovered), "f");
        } else {
            holder.transfer(recovered);
        }
    }
}
"},"RecoveryProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./BimodalProxy.sol";
import "./ERC20.sol";
import "./RecoveryLib.sol";
import "./SafeMathLib256.sol";

contract RecoveryProxy is BimodalProxy {
    using SafeMathLib256 for uint256;

    modifier onlyWhenContractPunished() {
        require(
            hasOutstandingChallenges() || hasMissedCheckpointSubmission(),
            "f"
        );
        _;
    }

    // =========================================================================
    function recoverOnlyParentChainFunds(ERC20 token, address holder)
        public
        onlyWhenContractPunished()
        returns (uint256 reclaimed)
    {
        reclaimed = RecoveryLib.recoverOnlyParentChainFunds(
            ledger,
            token,
            holder
        );
    }

    function recoverAllFunds(
        ERC20 token,
        address holder,
        bytes32[2] checksums,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2] LR, // solhint-disable-line func-param-name-mixedcase
        uint256[3] dummyPassiveMark
    ) public onlyWhenContractPunished() returns (uint256 recovered) {
        recovered = RecoveryLib.recoverAllFunds(
            ledger,
            token,
            holder,
            checksums,
            trail,
            allotmentChain,
            membershipChain,
            values,
            LR,
            dummyPassiveMark
        );
    }
}
"},"SafeMathLib256.sol":{"content":"pragma solidity ^0.4.24;

/* Overflow safety library */
library SafeMathLib256 {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, '+');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, '-');
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, '*');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, '/');
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, '%');
    return a % b;
  }
}"},"SafeMathLib32.sol":{"content":"pragma solidity ^0.4.24;

library SafeMathLib32 {
  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    require(c >= a, '+');

    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a, '-');
    return a - b;
  }

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }

    uint32 c = a * b;
    require(c / a == b, '*');

    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b > 0, '/');
    return a / b;
  }

  function mod(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b > 0, '%');
    return a % b;
  }
}"},"SafeMathLib64.sol":{"content":"pragma solidity ^0.4.24;

library SafeMathLib64 {
  function add(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a, '+');

    return c;
  }
  
  function sub(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a, '-');
    return a - b;
  }
  
  function mul(uint64 a, uint64 b) internal pure returns (uint64) {
    if (a == 0) {
      return 0;
    }

    uint64 c = a * b;
    require(c / a == b, '*');

    return c;
  }
  
  function div(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b > 0, '/');
    return a / b;
  }
  
  function mod(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b > 0, '%');
    return a % b;
  }
}"},"WithdrawalLib.sol":{"content":"/* solhint-disable func-order */

pragma solidity ^0.4.24;

import "./BimodalLib.sol";
import "./ChallengeLib.sol";
import "./SafeMathLib256.sol";

/*
This library contains the implementations of the first NOCUST withdrawal
procedures.
*/
library WithdrawalLib {
    using SafeMathLib256 for uint256;
    using BimodalLib for BimodalLib.Ledger;
    // EVENTS
    event WithdrawalRequest(
        address indexed token,
        address indexed requestor,
        uint256 amount
    );

    event WithdrawalConfirmation(
        address indexed token,
        address indexed requestor,
        uint256 amount
    );

    function initWithdrawal(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address holder,
        uint256 eon,
        uint256 withdrawalAmount
    ) private /* onlyWhenContractUnpunished() */
    {
        BimodalLib.Wallet storage entry = ledger.walletBook[token][holder];

        uint256 balance = 0;
        if (token != address(this)) {
            require(ledger.tokenToTrail[token] != 0, "t");
            balance = token.balanceOf(this);
        } else {
            balance = address(this).balance;
        }

        require(
            ledger.getPendingWithdrawalsAtEon(token, eon).add(
                withdrawalAmount
            ) <= balance,
            "b"
        );

        entry.withdrawals.push(BimodalLib.Withdrawal(eon, withdrawalAmount));

        ledger.addToRunningPendingWithdrawals(token, eon, withdrawalAmount);

        ledger.appendOperationToEonAccumulator(
            eon,
            token,
            holder,
            BimodalLib.Operation.WITHDRAWAL,
            withdrawalAmount
        );

        emit WithdrawalRequest(token, holder, withdrawalAmount);
    }

    /**
     * This method can be called freely by a client to initiate a withdrawal in the
     * parent-chain that will take 2 eons to be confirmable only if the client can
     * provide a satisfying proof of exclusive allotment.
     */
    function requestWithdrawal(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        bytes32[2] checksums,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][2] lrPassiveMark, // Left, Right
        uint256 withdrawalAmount
    ) public /* payable */
    /* onlyWithConstantReimbursement(100100) */
    {
        uint256 available = lrPassiveMark[0][1].sub(lrPassiveMark[0][0]);
        uint256 eon = ledger.currentEon();

        uint256 pending = ledger.getWalletPendingWithdrawalAmountAtEon(
            token,
            msg.sender,
            eon
        );
        require(available >= withdrawalAmount.add(pending), "b");

        require(
            ChallengeLib.verifyProofOfExclusiveAccountBalanceAllotment(
                ledger,
                token,
                msg.sender,
                checksums,
                trail,
                [eon.sub(1), lrPassiveMark[1][0], lrPassiveMark[1][1]],
                allotmentChain,
                membershipChain,
                values,
                lrPassiveMark[0]
            ),
            "p"
        );

        initWithdrawal(ledger, token, msg.sender, eon, withdrawalAmount);
    }

    /**
     * This method can be called by a client to initiate a withdrawal in the
     * parent-chain that will take 2 eons to be confirmable only if the client
     * provides a signature from the operator authorizing the initialization of this
     * withdrawal.
     */
    function requestAuthorizedWithdrawal(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        uint256 withdrawalAmount,
        uint256 expiry,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        requestDelegatedWithdrawal(
            ledger,
            token,
            msg.sender,
            withdrawalAmount,
            expiry,
            r,
            s,
            v
        );
    }

    /**
     * This method can be called by the operator to initiate a withdrawal in the
     * parent-chain that will take 2 eons to be confirmable only if the operator
     * provides a signature from the client authorizing the delegation of this
     * withdrawal initialization.
     */
    function requestDelegatedWithdrawal(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address holder,
        uint256 withdrawalAmount,
        uint256 expiry,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public /* onlyOperator() */
    {
        require(block.number <= expiry);

        uint256 eon = ledger.currentEon();
        uint256 pending = ledger.getWalletPendingWithdrawalAmountAtEon(
            token,
            holder,
            eon
        );

        require(
            ChallengeLib.verifyWithdrawalAuthorization(
                token,
                holder,
                expiry,
                withdrawalAmount.add(pending),
                holder,
                r,
                s,
                v
            )
        );

        initWithdrawal(ledger, token, holder, eon, withdrawalAmount);
    }

    /**
     * This method can be called to confirm the withdrawals of a recipient that have
     * been pending for at least two eons when the operator is not halted.
     */
    function confirmWithdrawal(
        BimodalLib.Ledger storage ledger,
        ERC20 token,
        address recipient
    )
        public
        returns (
            /* onlyWhenContractUnpunished() */
            uint256 amount
        )
    {
        BimodalLib.Wallet storage entry = ledger.walletBook[token][recipient];
        BimodalLib.Withdrawal[] storage withdrawals = entry.withdrawals;

        uint256 eon = ledger.currentEon();
        amount = 0;

        /**
         * after the loop, i is set to the index of the first pending withdrawals
         * amount is the amount to be sent to the recipient
         */
        uint32 i = 0;
        for (i = 0; i < withdrawals.length; i++) {
            BimodalLib.Withdrawal storage withdrawal = withdrawals[i];
            if (withdrawal.eon.add(1) >= eon) {
                break;
            } else if (
                withdrawal.eon.add(2) == eon &&
                ledger.currentEra() < ledger.EXTENDED_BLOCKS_PER_EPOCH
            ) {
                break;
            }

            amount = amount.add(withdrawal.amount);
        }

        // set withdrawals to contain only pending withdrawal requests
        for (uint32 j = 0; j < i && i < withdrawals.length; j++) {
            withdrawals[j] = withdrawals[i];
            i++;
        }
        withdrawals.length = withdrawals.length.sub(j);

        ledger.deductFromRunningPendingWithdrawals(token, eon, eon, amount);

        BimodalLib.AmountAggregate storage eonWithdrawals = ledger
            .confirmedWithdrawals[token][eon.mod(ledger.EONS_KEPT)];
        BimodalLib.addToAggregate(eonWithdrawals, eon, amount);

        emit WithdrawalConfirmation(token, recipient, amount);

        // if token is not chain native asset
        if (token != address(this)) {
            require(ledger.tokenToTrail[token] != 0);
            require(token.transfer(recipient, amount));
        } else {
            recipient.transfer(amount);
        }
    }
}
"},"WithdrawalProxy.sol":{"content":"pragma solidity ^0.4.24;

import "./BimodalProxy.sol";
import "./ERC20.sol";
import "./WithdrawalLib.sol";
import "./SafeMathLib256.sol";

contract WithdrawalProxy is BimodalProxy {
    using SafeMathLib256 for uint256;

    modifier onlyWithConstantReimbursement(uint256 responseGas) {
        require(
            msg.value >= responseGas.mul(ledger.MIN_CHALLENGE_GAS_COST) &&
                msg.value >= responseGas.mul(tx.gasprice),
            "r"
        );
        ledger.operator.transfer(msg.value);
        _;
    }

    // =========================================================================
    function requestWithdrawal(
        ERC20 token,
        bytes32[2] checksums,
        uint64 trail,
        bytes32[] allotmentChain,
        bytes32[] membershipChain,
        uint256[] values,
        uint256[2][2] lrPassiveMark,
        uint256 withdrawalAmount
    )
        public
        payable
        onlyWithConstantReimbursement(100100)
        onlyWhenContractUnpunished()
    {
        WithdrawalLib.requestWithdrawal(
            ledger,
            token,
            checksums,
            trail,
            allotmentChain,
            membershipChain,
            values,
            lrPassiveMark,
            withdrawalAmount
        );
    }

    function requestAuthorizedWithdrawal(
        ERC20 token,
        uint256 withdrawalAmount,
        uint256 expiry,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyWhenContractUnpunished() {
        WithdrawalLib.requestAuthorizedWithdrawal(
            ledger,
            token,
            withdrawalAmount,
            expiry,
            r,
            s,
            v
        );
    }

    function requestDelegatedWithdrawal(
        ERC20 token,
        address holder,
        uint256 withdrawalAmount,
        uint256 expiry,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyOperator() onlyWhenContractUnpunished() {
        WithdrawalLib.requestDelegatedWithdrawal(
            ledger,
            token,
            holder,
            withdrawalAmount,
            expiry,
            r,
            s,
            v
        );
    }

    function confirmWithdrawal(ERC20 token, address recipient)
        public
        onlyWhenContractUnpunished()
        returns (uint256)
    {
        return WithdrawalLib.confirmWithdrawal(ledger, token, recipient);
    }
}
"}}