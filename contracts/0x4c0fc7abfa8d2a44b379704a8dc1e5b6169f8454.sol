{"AgreementManager.sol":{"content":"pragma solidity 0.5.3;

import "./SafeUtils.sol";
import "./EvidenceProducer.sol";

/**
    @notice
    AgreementManager allows two parties (A and B) to represent some sort of agreement that
    involves staking ETH. The general flow is: they both deposit a stake (they can withdraw until
    both stakes have been deposited), then their agreement is either fulfilled or not based on
    actions outside of this contract, then either party can "resolve" by specifying how they think
    funds should be split based on each party's actions in relation to the agreement terms.
    Funds are automatically dispersed once there's a resolution. If the parties disagree, they can
    summon a predefined arbitrator to settle their dispute.

    @dev
    There are several types of AgreementManager which inherit from this contract. The inheritance
    tree looks like:
    AgreementManager
        AgreementManagerETH
            AgreementManagerETH_Simple
            AgreementManagerETH_ERC792
        AgreementManagerERC20
            AgreementManagerERC20_Simple
            AgreementManagerERC792_Simple

    Essentially there are two options:
    (1) Does the agreement use exclusively ETH, or also at least one ERC20 Token?
    (2) Does the agreement use simple arbitration (an agreed upon external address), or ERC792
        (Kleros) arbitration?
    There are four contracts, one for each combination of options, although much of their code is
    shared. AgreementManagerERC20 can handle purely ETH agreements, but it's cheaper to use
    AgreementManagerETH.

    To avoid comment duplication, comments have been pushed as high in the inheritance tree as
    possible. Several functions are declared for the first time in AgreementManagerETH and
    AgreementManagerERC20 rather than in AgreementManager, because they take slightly different
    arguments.

    **** NOTES ON REENTRANCY ****

    For ease of review, functions that call untrusted external functions (even via multiple calls)
    and which have these external calls wrapped in a reentrancy guard will have
    "_Untrusted_Guarded" appended to the function name. Untrusted functions which don't have their
    external calls wrapped in a reentrancy guard will have _Untrusted_Unguarded appended to their
    name. One function has "_Sometimes_Untrusted_Guarded" appended to its name, as it's
    _Untrusted_Guarded untrusted in some inheriting functions. This naming convention does not
    apply to public and external functions.

    An external function call is safe if (a) nothing after the function call depends on any
    contract state that can change after the call is made, and (b) no contract state will be
    changed after the external call. When those two conditions don't obviously hold we use a
    reentrancy guard. When those two conditions do hold we safely ignore reentrancy protection.
    We'll refer to calls that clearly meet both conditions as being "Reentrancy Safe" in other
    comments.

    You can prove to yourself that our code is reentrancy safe by verifying these things:
    (1) Every function whose name ends with "_Untrusted_Guarded" has a reentrancy guard wrapped
    around any external calls that it contains.
    (2) Every function call whose name ends with "_Untrusted_Unguarded" is either Reentrancy Safe
    as described above, or it's wrapped in a reentrancy guard.
    (3) The body of every function whose name ends with "_Untrusted_Unguarded" contains only
    Reentrancy Safe calls.
    (4) Every external function in our contracts that modifies the state of a pre-existing
    agreement is protected by a reentrancy check.

    Note that a reentrancy guard looks like "getThenSetPendingExternalCall(agreement, true)"
    before the code that it's guarding, and "setPendingExternalCall(agreement, previousValue)"
    after the code that it's guarding. A reentrancy check looks like:
    'require(!pendingExternalCall(agreement), "Reentrancy protection is on");'
*/

contract AgreementManager is SafeUtils, EvidenceProducer {
    // -------------------------------------------------------------------------------------------
    // --------------------------------- special values ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // When the parties to an agreement report the outcome, they enter a "resolution", which is
    // the amount of wei that party A should get. Party B is understood to get the remaining wei.
    // RESOLUTION_NULL is a special value indicating "no resolution has been entered yet".
    uint48 constant RESOLUTION_NULL = ~(uint48(0)); // set all bits to one.

    uint constant MAX_DAYS_TO_RESPOND_TO_ARBITRATION_REQUEST = 365*30; // Approximately 30 years

    // "party A" and "party B" are the two parties to the agreement
    enum Party { A, B }

    // ---------------------------------
    // Offsets for AgreementData.boolValues
    // --------------------------------
    // We pack all of our bool values into a uint32 for gas cost optimization. Each constant below
    // represents a "virtual" boolean variable.
    // These are the offets into that uint32 (AgreementData.boolValues)

    uint constant PARTY_A_STAKE_PAID = 0; // Has party A fully paid their stake?
    uint constant PARTY_B_STAKE_PAID = 1; // Has party B fully paid their stake?
    uint constant PARTY_A_REQUESTED_ARBITRATION = 2; // Has party A requested arbitration?
    uint constant PARTY_B_REQUESTED_ARBITRATION = 3; // Has party B requested arbitration?
    // The "RECEIVED_DISTRIBUTION" values represent whether we've either sent an
    // automatic funds distribution to the party, or they've explicitly withdrawn.
    // There's a non-intuitive edge case: these variables can be true even if the distribution
    // amount is zero, as long as we went through the process that would have resulted in a
    // positive distribution if there was one.
    uint constant PARTY_A_RECEIVED_DISTRIBUTION = 4;
    uint constant PARTY_B_RECEIVED_DISTRIBUTION = 5;
    /** PARTY_A_RESOLVED_LAST is used to detect certain bad behavior where a party will first
    resolve to a "bad" value, wait for their counterparty to summon an arbitrator, and then
    resolve to the correct value to avoid having the arbitator rule against them. At any point
    where the arbitrator has been paid before the dishonest party switches to a reasonable ruling,
    we want the person who switched to the eventually official ruling last to be the one to pay
    the arbitration fee.*/
    uint constant PARTY_A_RESOLVED_LAST = 6;
    uint constant ARBITRATOR_RESOLVED = 7; // Did the arbitrator enter a resolution?
    uint constant ARBITRATOR_RECEIVED_DISPUTE_FEE = 8; // Did arbitrator receive the dispute fee?
    // The DISPUTE_FEE_LIABILITY are used to keep track if which party is responsible for paying
    // the arbitrator's dispute fee. If both are true then each party is responsible for half.
    uint constant PARTY_A_DISPUTE_FEE_LIABILITY = 9;
    uint constant PARTY_B_DISPUTE_FEE_LIABILITY = 10;
    // We use this flag internally to guard against reentrancy attacks.
    uint constant PENDING_EXTERNAL_CALL = 11;

    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    // Some events specific to inheriting contracts are only defined in those contracts, so this
    // is not a full list of events that the instantiated contracts will output.

    /// @notice links the agreementID to the hash of the agreement, so the written agreement terms
    /// can be associated with this Ethereum contract.
    event AgreementCreated(uint32 indexed agreementID, bytes32 agreementHash);

    event PartyBDeposited(uint32 indexed agreementID);
    event PartyAWithdrewEarly(uint32 indexed agreementID);
    event PartyWithdrew(uint32 indexed agreementID);
    event FundsDistributed(uint32 indexed agreementID);
    event ArbitratorReceivedDisputeFee(uint32 indexed agreementID);
    event ArbitrationRequested(uint32 indexed agreementID);
    event DefaultJudgment(uint32 indexed agreementID);
    event AutomaticResolution(uint32 indexed agreementID);

    // -------------------------------------------------------------------------------------------
    // --------------------------- public / external functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice A fallback function that prevents anyone from sending ETH directly to this
    /// and inheriting contracts, since it isn't payable.
    function () external {}

    // -------------------------------------------------------------------------------------------
    // ----------------------- internal getter and setter functions ------------------------------
    // -------------------------------------------------------------------------------------------

    /// @param flagField bitfield containing a bunch of virtual bool values
    /// @param offset index into flagField of the bool we want to know the value of
    /// @return value of the bool specified by offset
    function getBool(uint flagField, uint offset) internal pure returns (bool) {
        return ((flagField >> offset) & 1) == 1;
    }

    /// @param flagField bitfield containing a bunch of virtual bool values
    /// @param offset index into flagField of the bool we want to set the value of
    /// @param value value to set the bit specified by offset to
    /// @return the new value of flagField containing the modified bool value
    function setBool(uint32 flagField, uint offset, bool value) internal pure returns (uint32) {
        if (value) {
            return flagField | uint32(1 << offset);
        } else {
            return flagField & ~(uint32(1 << offset));
        }
    }

    // -------------------------------------------------------------------------------------------
    // -------------------------- internal helper functions --------------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice Emit some events upon every contract creation
    /// @param agreementHash hash of the text of the agreement
    /// @param agreementURI URL of JSON representing the agreement
    function emitAgreementCreationEvents(
        uint agreementID,
        bytes32 agreementHash,
        string memory agreementURI
    )
        internal
    {
        // We want to emit both of these because we want to emit the agreement hash, and we also
        // want to adhere to ERC1497
        emit MetaEvidence(agreementID, agreementURI);
        emit AgreementCreated(uint32(agreementID), agreementHash);
    }
}
"},"AgreementManagerETH.sol":{"content":"pragma solidity 0.5.3;

import "./AgreementManager.sol";

/**
    @notice
    See AgreementManager for comments on the overall nature of this contract.

    This is the contract defining how ETH-only agreements work.

    @dev
    The relevant part of the inheritance tree is:
    AgreementManager
        AgreementManagerETH
            AgreementManagerETH_Simple
            AgreementManagerETH_ERC792
*/

contract AgreementManagerETH is AgreementManager {
    // -------------------------------------------------------------------------------------------
    // --------------------------------- special values ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // We store ETH amounts in millionths of ETH, not Wei. So we need to do conversions using this
    // factor. 10^6 * 10^12 = 10^18, the number of wei in one Ether
    uint constant ETH_AMOUNT_ADJUST_FACTOR = 1000*1000*1000*1000;

    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    event PartyResolved(uint32 indexed agreementID, uint resolution);

    // -------------------------------------------------------------------------------------------
    // -------------------------------- struct definitions ---------------------------------------
    // -------------------------------------------------------------------------------------------

    /** Whenever an agreement is created, we store its state in an AgreementDataETH object. One of
    the main differences between this contract and the ERC20 version is the struct that they use
    to store agreement data. This struct is smaller than the one needed for ERC20. The variables
    are arranged so that the compiler can easily "pack" them into 4 uint256s under the hood. Look
    at the comments for createAgreementA to see what all these variables represent.
    Spacing shows the uint256s that we expect these to be packed in -- there are four groups
    separated by spaces, representing the four uint256s that will be used internally.*/
    struct AgreementDataETH {
        // Put the data that can change all in the first "uint" slot, for gas cost optimization.
        uint48 partyAResolution; // Resolution for partyA
        uint48 partyBResolution; // Resolution for partyB
        // An agreement can be created with an optional "automatic" resolution which either party
        // can trigger after autoResolveAfterTimestamp.
        uint48 automaticResolution;
        // Resolution holds the "official, final" resolution of the agreement. Once this value has
        // been set, it means the agreement is over and funds can be withdrawn.
        uint48 resolution;
        /** nextArbitrationStepAllowedAfterTimestamp is the most complex state variable, as we
        want to keep the contract small to save gas cost. Initially it represents the timestamp
        after which the parties are allowed to request arbitration. Once arbitration is requested
        the first time, it represents how long the party who hasn't yet requested arbitration (or
        fully paid for arbitration in the case of ERC 792 arbitration) has until they lose via a
        "default judgment" (aka lose the dispute simply because they didn't post the arbitration
        fee) */
        uint32 nextArbitrationStepAllowedAfterTimestamp;
        // A bitmap that holds all of our "virtual" bool values.
        // See the offsets for bool values defined above for a list of the boolean info we store.
        uint32 boolValues;

        address partyAAddress; // ETH address of party A
        uint48 partyAStakeAmount; // Amount that party A is required to stake
        // An optional arbitration fee that is sent to the arbitrator's ETH address once both
        // parties have deposited their stakes.
        uint48 partyAInitialArbitratorFee;

        address partyBAddress; // ETH address of party B
        uint48 partyBStakeAmount; // Amount that party B is required to stake
        // An optional arbitration fee that is sent to the arbitrator's ETH address once both
        // parties have deposited their stakes.
        uint48 partyBInitialArbitratorFee;

        address arbitratorAddress; // ETH address of Arbitrator
        uint48 disputeFee; // Fee paid to arbitrator only if there's a dispute and they do work.
        // The timestamp after which either party can trigger the "automatic resolution". This can
        // only be triggered if no one has requested arbitration.
        uint32 autoResolveAfterTimestamp;
        // The # of days that the other party has to respond to an arbitration request from the
        // other party. If they fail to respond in time, the other party can trigger a default
        // judgment.
        uint16 daysToRespondToArbitrationRequest;
    }

    // -------------------------------------------------------------------------------------------
    // --------------------------------- internal state ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // We store our agreements in a single array. When a new agreement is created we add it to the
    // end. The index into this array is the agreementID.
    AgreementDataETH[] agreements;

    // -------------------------------------------------------------------------------------------
    // ---------------------------- external getter functions ------------------------------------
    // -------------------------------------------------------------------------------------------

    function getResolutionNull() external pure returns (uint) {
        return resolutionToWei(RESOLUTION_NULL);
    }
    function getNumberOfAgreements() external view returns (uint) {
        return agreements.length;
    }

    /// @return the full internal state of an agreement.
    function getState(
        uint agreementID
    )
        external
        view
        returns (address[3] memory, uint[16] memory, bool[12] memory, bytes memory);

    // -------------------------------------------------------------------------------------------
    // -------------------- main external functions that affect state ----------------------------
    // -------------------------------------------------------------------------------------------

    /**
    @notice Adds a new agreement to the agreements array.
    This is only callable by partyA. So the caller needs to rearrange addresses so that they're
    partyA. Party A needs to pay their stake as part of calling this function by sending ETH.
    @dev createAgreementA differs between versions, so is defined low in the inheritance tree.
    We don't need re-entrancy protection here because createAgreementA can't influence
    existing agreeemnts.
    @param agreementHash hash of agreement details. Not stored, just emitted in an event.
    @param agreementURI URI to 'metaEvidence' as defined in ERC 1497. Not stored, just emitted.
    @param participants :
    participants[0]: Address of partyA
    participants[1]: Address of partyB
    participants[2]: Address of arbitrator
    @param quantities :
    quantities[0]: Amount that party A is staking
    quantities[1]: Amount that party B is staking
    quantities[2]: Amount that party A pays arbitrator regardless of if there's a dispute
    quantities[3]: Amount that party B pays arbitrator regardless of if there's a dispute
    quantities[4]: Fee for arbitrator if there is a dispute
    quantities[5]: Amount of wei to go to party A if an automatic resolution is triggered.
    quantities[6]: 16 bit value, # of days to respond to arbitration request
    quantities[7]: 32 bit timestamp value before which arbitration can't be requested.
    quantities[8]: 32 bit timestamp value after which auto-resolution is allowed if no one
                   requested arbitration. 0 means never.
    @param arbExtraData Data to pass in to ERC792 arbitrator if a dispute is ever created. Use
    null when creating non-ERC792 agreements
    @return the agreement id of the newly added agreement*/
    function createAgreementA(
        bytes32 agreementHash,
        string calldata agreementURI,
        address[3] calldata participants,
        uint[9] calldata quantities,
        bytes calldata arbExtraData
    )
        external
        payable
        returns (uint)
    {
        require(msg.sender == participants[0], "Only party A can call createAgreementA.");
        require(msg.value == add(quantities[0], quantities[2]), "Payment not correct.");
        require(
            (
                participants[0] != participants[1] &&
                participants[0] != participants[2] &&
                participants[1] != participants[2]
            ),
            "partyA, partyB, and arbitrator addresses must be unique."
        );
        require(
            quantities[6] >= 1 && quantities[6] <= MAX_DAYS_TO_RESPOND_TO_ARBITRATION_REQUEST,
            "Days to respond to arbitration was out of range."
        );

        // Populate a AgreementDataETH struct with the info provided.
        AgreementDataETH memory agreement;
        agreement.partyAAddress = participants[0];
        agreement.partyBAddress = participants[1];
        agreement.arbitratorAddress = participants[2];
        agreement.partyAResolution = RESOLUTION_NULL;
        agreement.partyBResolution = RESOLUTION_NULL;
        agreement.resolution = RESOLUTION_NULL;
        agreement.partyAStakeAmount = toMillionth(quantities[0]);
        agreement.partyBStakeAmount = toMillionth(quantities[1]);
        uint sumOfStakes = add(agreement.partyAStakeAmount, agreement.partyBStakeAmount);
        require(sumOfStakes < RESOLUTION_NULL, "Stake amounts were too large.");
        agreement.partyAInitialArbitratorFee = toMillionth(quantities[2]);
        agreement.partyBInitialArbitratorFee = toMillionth(quantities[3]);
        agreement.disputeFee = toMillionth(quantities[4]);
        agreement.automaticResolution = toMillionth(quantities[5]);
        require(agreement.automaticResolution <= sumOfStakes, "Automatic resolution too large.");
        agreement.daysToRespondToArbitrationRequest = toUint16(quantities[6]);
        agreement.nextArbitrationStepAllowedAfterTimestamp = toUint32(quantities[7]);
        agreement.autoResolveAfterTimestamp = toUint32(quantities[8]);
        // set boolean values
        uint32 tempBools = setBool(0, PARTY_A_STAKE_PAID, true);
        if (add(quantities[1], quantities[3]) == 0) {
            tempBools = setBool(tempBools, PARTY_B_STAKE_PAID, true);
        }
        agreement.boolValues = tempBools;

        // Add the new agreement to our array and create the agreementID
        uint agreementID = sub(agreements.push(agreement), 1);

        // This is a function because we want it to be a no-op for non-ERC792 agreements.
        storeArbitrationExtraData(agreementID, arbExtraData);

        emitAgreementCreationEvents(agreementID, agreementHash, agreementURI);

        // Pay the arbitrator if needed, which happens if B was staking no funds and needed no
        // initial fee, but there was an initial fee from A.
        if ((add(quantities[1], quantities[3]) == 0) && (quantities[2] > 0)) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreementID);
        }
        return agreementID;
    }

    /// @notice Called by PartyB to deposit their stake, locking in the agreement so no one can
    /// unilaterally withdraw. PartyA already deposited funds in createAgreementA, so we only need
    /// a deposit function for partyB.
    function depositB(uint agreementID) external payable {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyBAddress, "Function can only be called by party B.");
        require(!partyStakePaid(agreement, Party.B), "Party B already deposited their stake.");
        // No need to check that party A deposited: they can't create an agreement otherwise.

        require(
            msg.value == toWei(
                add(agreement.partyBStakeAmount, agreement.partyBInitialArbitratorFee)
            ),
            "Party B deposit amount was unexpected."
        );

        setPartyStakePaid(agreement, Party.B, true);

        emit PartyBDeposited(uint32(agreementID));

        if (add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee) > 0) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreementID);
        }
    }

    /// @notice Called to report a resolution of the agreement by a party. The resolution
    /// specifies how funds should be distributed between the parties.
    /// @param resolutionWei The amount of wei that the caller thinks should go to party A.
    /// The remaining amount of wei staked for this agreement would go to party B.
    /// @param distributeFunds Whether to distribute funds to the two parties if this call
    /// results in an official resolution to the agreement.
    function resolveAsParty(uint agreementID, uint resolutionWei, bool distributeFunds) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        uint48 res = toMillionth(resolutionWei);
        require(
            res <= add(agreement.partyAStakeAmount, agreement.partyBStakeAmount),
            "Resolution out of range."
        );

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        // Keep track of who was the last to resolve.. useful for punishing 'late' resolutions.
        // We check the existing state of partyAResolvedLast only as a perf optimization,
        // to avoid unnecessary writes.
        if (callingParty == Party.A && !partyAResolvedLast(agreement)) {
            setPartyAResolvedLast(agreement, true);
        } else if (callingParty == Party.B && partyAResolvedLast(agreement)) {
            setPartyAResolvedLast(agreement, false);
        }

        // See if we need to update the deadline to respond to arbitration. We want to avoid a
        // situation where someone has (or will soon have) the right to request a default
        // judgment, then they change their resolution to be more favorable to them and
        // immediately request a default judgment for the new resolution.
        if (partyIsCloserToWinningDefaultJudgment(agreementID, agreement, callingParty)) {
            // If new resolution isn't compatible with the existing one, then the caller
            // made the resolution more favorable to themself.
            // We know that an old resolution exists because for the caller to be closer to
            // winning a default judgment they must have requested arbitration, and they can only
            // request arbitration after resolving.
            if (
                !resolutionsAreCompatibleBothExist(
                    res,
                    partyResolution(agreement, callingParty),
                    callingParty
                )
            ) {
                updateArbitrationResponseDeadline(agreement);
            }
        }

        setPartyResolution(agreement, callingParty, res);

        emit PartyResolved(uint32(agreementID), resolutionWei);

        // If the resolution is 'compatible' with that of the other person, make it the
        // final resolution.
        uint otherRes = partyResolution(agreement, otherParty);
        if (resolutionsAreCompatible(agreement, res, otherRes, callingParty)) {
            finalizeResolution_Untrusted_Unguarded(
                agreementID,
                agreement,
                res,
                distributeFunds,
                false
            );
        }
    }

    /// @notice If A calls createAgreementA but B is delaying in calling depositB, A can get their
    /// funds back by calling earlyWithdrawA. This closes the agreement to further deposits. A or
    /// B would have to call createAgreementA again if they still wanted to do an agreement.
    function earlyWithdrawA(uint agreementID) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyAAddress, "withdrawA must be called by party A.");
        require(
            partyStakePaid(agreement, Party.A) && !partyStakePaid(agreement, Party.B),
            "Early withdraw not allowed."
        );
        require(!partyReceivedDistribution(agreement, Party.A), "partyA already received funds.");

        setPartyReceivedDistribution(agreement, Party.A, true);

        emit PartyAWithdrewEarly(uint32(agreementID));

        msg.sender.transfer(
            toWei(add(agreement.partyAStakeAmount, agreement.partyAInitialArbitratorFee))
        );
    }

    /// @notice This can only be called after a resolution is established.
    /// Each party calls this to withdraw the funds they're entitled to, based on the resolution.
    /// Normally funds are distributed automatically when the agreement gets resolved. However
    /// it is possible for a malicious user to prevent their counterparty from getting an
    /// automatic distribution, by using an address for the agreement that can't receive payments.
    /// If this happens, the agreement should be resolved by setting the distributeFunds parameter
    /// to false in whichever function is called to resolve the disagreement. Then the parties can
    /// independently extract their funds via this function.
    function withdraw(uint agreementID) external {
        AgreementDataETH storage agreement = agreements[agreementID];
        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreement.resolution != RESOLUTION_NULL, "Agreement is not resolved.");

        emit PartyWithdrew(uint32(agreementID));

        distributeFundsToPartyHelper_Untrusted_Unguarded(
            agreementID,
            agreement,
            getCallingParty(agreement)
        );
    }

    /// @notice Request that the arbitrator get involved to settle the disagreement.
    /// Each party needs to pay the full arbitration fee when calling this. However they will be
    /// refunded the full fee if the arbitrator agrees with them.
    function requestArbitration(uint agreementID) external payable;

    /// @notice If the other person hasn't paid their arbitration fee in time, this function
    /// allows the caller to cause the agreement to be resolved in their favor without the
    /// arbitrator getting involved.
    /// @param distributeFunds Whether to distribute funds to both parties.
    function requestDefaultJudgment(uint agreementID, bool distributeFunds) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        require(
            RESOLUTION_NULL != partyResolution(agreement, callingParty),
            "requestDefaultJudgment called before party resolved."
        );
        require(
            block.timestamp > agreement.nextArbitrationStepAllowedAfterTimestamp,
            "requestDefaultJudgment not allowed yet."
        );

        emit DefaultJudgment(uint32(agreementID));

        require(
            partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
                agreementID,
                agreement,
                callingParty
            ),
            "Party didn't fully pay the dispute fee."
        );
        require(
            !partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
                agreementID,
                agreement,
                otherParty
            ),
            "Other party fully paid the dispute fee."
        );

        finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            partyResolution(agreement, callingParty),
            distributeFunds,
            false
        );
    }

    /// @notice If enough time has elapsed, either party can trigger auto-resolution (if enabled)
    /// by calling this function, provided that neither party has requested arbitration yet.
    /// @param distributeFunds Whether to distribute funds to both parties
    function requestAutomaticResolution(uint agreementID, bool distributeFunds) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");
        require(
            (
                !partyRequestedArbitration(agreement, Party.A) &&
                !partyRequestedArbitration(agreement, Party.B)
            ),
            "Arbitration stops auto-resolution"
        );
        require(
            msg.sender == agreement.partyAAddress || msg.sender == agreement.partyBAddress,
            "Unauthorized sender."
        );
        require(
            agreement.autoResolveAfterTimestamp > 0,
            "Agreement does not support automatic resolutions."
        );
        require(
            block.timestamp > agreement.autoResolveAfterTimestamp,
            "AutoResolution not allowed yet."
        );

        emit AutomaticResolution(uint32(agreementID));

         finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            agreement.automaticResolution,
            distributeFunds,
            false
        );
    }

    /// @notice Either party can record evidence on the blockchain in case off-chain communication
    /// breaks down. Uses ERC1497. Allows submitting evidence even after an agreement is closed in
    /// case someone wants to clear their name.
    /// @param evidence can be any string containing evidence. Usually will be a URI to a document
    /// or video containing evidence.
    function submitEvidence(uint agreementID, string calldata evidence) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(
            (
                msg.sender == agreement.partyAAddress ||
                msg.sender == agreement.partyBAddress ||
                msg.sender == agreement.arbitratorAddress
            ),
            "Unauthorized sender."
        );

        emit Evidence(Arbitrator(agreement.arbitratorAddress), agreementID, msg.sender, evidence);
    }

    // -------------------------------------------------------------------------------------------
    // ----------------------- internal getter and setter functions ------------------------------
    // -------------------------------------------------------------------------------------------

    // Functions that simulate direct access to AgreementDataETH state variables. These are used
    // either for bools (where we need to use a bitmask), or for functions when we need to vary
    // between party A/B depending on the argument. The later is necessary because the solidity
    // compiler can't pack structs well when their elements are arrays. So we can't just index
    // into an array.

    // ------------- Some getter functions ---------------

    function partyResolution(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (uint48)
    {
        if (party == Party.A) return agreement.partyAResolution;
        else return agreement.partyBResolution;
    }

    function partyAddress(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (address)
    {
        if (party == Party.A) return agreement.partyAAddress;
        else return agreement.partyBAddress;
    }

    function partyStakePaid(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_STAKE_PAID);
        else return getBool(agreement.boolValues, PARTY_B_STAKE_PAID);
    }

    function partyRequestedArbitration(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_REQUESTED_ARBITRATION);
        else return getBool(agreement.boolValues, PARTY_B_REQUESTED_ARBITRATION);
    }

    function partyReceivedDistribution(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_RECEIVED_DISTRIBUTION);
        else return getBool(agreement.boolValues, PARTY_B_RECEIVED_DISTRIBUTION);
    }

    function partyAResolvedLast(AgreementDataETH storage agreement) internal view returns (bool) {
        return getBool(agreement.boolValues, PARTY_A_RESOLVED_LAST);
    }

    function arbitratorResolved(AgreementDataETH storage agreement) internal view returns (bool) {
        return getBool(agreement.boolValues, ARBITRATOR_RESOLVED);
    }

    function arbitratorReceivedDisputeFee(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, ARBITRATOR_RECEIVED_DISPUTE_FEE);
    }

    function partyDisputeFeeLiability(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_DISPUTE_FEE_LIABILITY);
        else return getBool(agreement.boolValues, PARTY_B_DISPUTE_FEE_LIABILITY);
    }

    function pendingExternalCall(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, PENDING_EXTERNAL_CALL);
    }

    // ------------- Some setter functions ---------------

    function setPartyResolution(
        AgreementDataETH storage agreement,
        Party party,
        uint48 value
    )
        internal
    {
        if (party == Party.A) agreement.partyAResolution = value;
        else agreement.partyBResolution = value;
    }

    function setPartyStakePaid(
        AgreementDataETH storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A)
            agreement.boolValues = setBool(agreement.boolValues, PARTY_A_STAKE_PAID, value);
        else
            agreement.boolValues = setBool(agreement.boolValues, PARTY_B_STAKE_PAID, value);
    }

    function setPartyRequestedArbitration(
        AgreementDataETH storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_REQUESTED_ARBITRATION,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_REQUESTED_ARBITRATION,
                value
            );
        }
    }

    function setPartyReceivedDistribution(
        AgreementDataETH storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_RECEIVED_DISTRIBUTION,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_RECEIVED_DISTRIBUTION,
                value
            );
        }
    }

    function setPartyAResolvedLast(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PARTY_A_RESOLVED_LAST, value);
    }

    function setArbitratorResolved(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, ARBITRATOR_RESOLVED, value);
    }

    function setArbitratorReceivedDisputeFee(
        AgreementDataETH storage agreement,
        bool value
    )
        internal
    {
        agreement.boolValues = setBool(
            agreement.boolValues,
            ARBITRATOR_RECEIVED_DISPUTE_FEE,
            value
        );
    }

    function setPartyDisputeFeeLiability(
        AgreementDataETH storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_DISPUTE_FEE_LIABILITY,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_DISPUTE_FEE_LIABILITY,
                value
            );
        }
    }

    function setPendingExternalCall(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PENDING_EXTERNAL_CALL, value);
    }

    /// @notice set the value of PENDING_EXTERNAL_CALL and return the previous value.
    function getThenSetPendingExternalCall(
        AgreementDataETH storage agreement,
        bool value
    )
        internal
        returns (bool)
    {
        uint32 previousBools = agreement.boolValues;
        agreement.boolValues = setBool(previousBools, PENDING_EXTERNAL_CALL, value);
        return getBool(previousBools, PENDING_EXTERNAL_CALL);
    }

    // -------------------------------------------------------------------------------------------
    // ----------------------------- internal helper functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice We store ETH/token amounts in uint48s demoninated in "millionths of ETH." toWei
    /// converts from our internal representation to the wei amount.
    /// @param millionthValue millionths of ETH that we want to convert
    /// @return the wei value of millionthValue
    function toWei(uint millionthValue) internal pure returns (uint) {
        return mul(millionthValue, ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Like toWei, but resolutionToWei is for "resolution" values which might have a
    /// special value of RESOLUTION_NULL, which we need to handle separately.
    /// @param millionthValue millionths of ETH that we want to convert
    /// @return the wei value of millionthValue
    function resolutionToWei(uint millionthValue) internal pure returns (uint) {
        if (millionthValue == RESOLUTION_NULL) {
            return uint(~0); // set all bits of a uint to 1
        }
        return mul(millionthValue, ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Convert a value expressed in wei to our internal representation in "millionths of
    /// ETH"
    function toMillionth(uint weiValue) internal pure returns (uint48) {
        return toUint48(weiValue / ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Requires that the caller be party A or party B.
    /// @return whichever party the caller is.
    function getCallingParty(AgreementDataETH storage agreement) internal view returns (Party) {
        if (msg.sender == agreement.partyAAddress) {
            return Party.A;
        } else if (msg.sender == agreement.partyBAddress) {
            return Party.B;
        } else {
            require(false, "getCallingParty must be called by a party to the agreement.");
        }
    }

    /// @notice Returns the "other" party.
    function getOtherParty(Party party) internal pure returns (Party) {
        if (party == Party.A) {
            return Party.B;
        }
        return Party.A;
    }

    /// @notice Fails if called by anyone other than a party.
    /// @return the calling party first and the "other party" second.
    function getCallingPartyAndOtherParty(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (Party, Party)
    {
        if (msg.sender == agreement.partyAAddress) {
            return (Party.A, Party.B);
        } else if (msg.sender == agreement.partyBAddress) {
            return (Party.B, Party.A);
        } else {
            require(
                false,
                "getCallingPartyAndOtherParty must be called by a party to the agreement."
            );
        }
    }

    /// @notice This is a version of resolutionsAreCompatible where we know that both resolutions
    /// are not RESOLUTION_NULL. It's more gas efficient so we should use it when possible.
    /// See comments for resolutionsAreCompatible to understand the purpose and arguments.
    function resolutionsAreCompatibleBothExist(
        uint resolution,
        uint otherResolution,
        Party resolutionParty
    )
        internal
        pure
        returns (bool)
    {
        if (resolutionParty == Party.A) {
            return resolution <= otherResolution;
        } else {
            return resolution >= otherResolution;
        }
    }

    /// @notice Compatible means that the participants don't disagree in a selfish direction.
    /// Alternatively, it means that we know some resolution will satisfy both parties.
    /// If one person resolves to give the other person the maximum possible amount, this is
    /// always compatible with the other person's resolution, even if that resolution is
    /// RESOLUTION_NULL. Otherwise, one person having a resolution of RESOLUTION_NULL
    /// implies the resolutions are not compatible.
    /// @param resolution Must be a resolution provided by either party A or party B, and this
    /// resolution must not be RESOLUTION_NULL
    /// @param otherResolution The resolution from either the other party or by the arbitrator.
    /// This resolution can be RESOLUTION_NULL.
    /// @param resolutionParty The party corresponding to the resolution provided by the
    /// 'resolution' parameter.
    /// @return whether the resolutions are compatible.
    function resolutionsAreCompatible(
        AgreementDataETH storage agreement,
        uint resolution,
        uint otherResolution,
        Party resolutionParty
    )
        internal
        view
        returns (bool)
    {
        // If we're not dealing with the NULL case, we can use resolutionsAreCompatibleBothExist
        if (otherResolution != RESOLUTION_NULL) {
            return resolutionsAreCompatibleBothExist(
                resolution,
                otherResolution,
                resolutionParty
            );
        }

        // Now we know otherResolution is RESOLUTION_NULL.
        // See if resolutionParty wants to give all funds to the other party.
        if (resolutionParty == Party.A) {
            // only 0 from Party A is compatible with RESOLUTION_NULL
            return resolution == 0;
        } else {
            // only the max possible amount from Party B is compatible with RESOLUTION_NULL
            return resolution == add(agreement.partyAStakeAmount, agreement.partyBStakeAmount);
        }
    }

    /// @return Whether the party provided is closer to winning a default judgment than the other
    /// party.
    function partyIsCloserToWinningDefaultJudgment(
        uint agreementID,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        returns (bool);

    /**
    @notice When a party withdraws, they may be owed a refund for any arbitration fee that they've
    paid in because this contract requires the loser of arbitration to pay the full fee.
    But since we don't know who the loser will be ahead of time, both parties must pay in the
    full arbitration amount when requesting arbitration.
    We assume we're only calling this function from an agreement with an official resolution.
    If this function has a it has a bug that overestimates the total amount that partyA and partyB
    can withdraw it could cause funds to be drained from the contract. Therefore
    it will be commented extensively in the implementations by inheriting contracts.
    @param agreementID id of the agreement
    @param agreement the agreement struct
    @param party the party for whom we are calculating the refund
    @return the value of the refund in wei.*/
    function getPartyArbitrationRefundInWei(
        uint agreementID,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (uint);

    /// @notice This lets us write one version of createAgreementA for both ERC792 and simple
    /// arbitration.
    /// @param arbExtraData some data that the creator of the agreement optionally passes in
    /// when creating an ERC792 agreement.
    function storeArbitrationExtraData(uint agreementID, bytes memory arbExtraData) internal;

    /// @dev '_Sometimes_Untrusted_Guarded' means that in some inheriting contracts it's
    /// _Untrusted_Guarded, in some it isn't. Look at the implementation in the specific
    /// contract you're interested in to know.
    function partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
        uint agreementID,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        returns (bool);

    /// @notice 'Open' means people should be allowed to take steps toward a future resolution.
    /// An agreement isn't open after it has ended (a final resolution exists), or if someone
    /// withdrew their funds before the second party could deposit theirs.
    /// @dev partyB can't do an early withdrawal, so we only need to check if partyA withdrew
    function agreementIsOpen(AgreementDataETH storage agreement) internal view returns (bool) {
        return agreement.resolution == RESOLUTION_NULL &&
            !partyReceivedDistribution(agreement, Party.A);

    }

    /// @notice 'Locked in' means both parties have deposited their stake. It conveys that the
    /// agreement is fully accepted and no one can withdraw without someone else's approval.
    function agreementIsLockedIn(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return partyStakePaid(agreement, Party.A) && partyStakePaid(agreement, Party.B);
    }

    /// @notice When both parties have deposited their stakes, the arbitrator is paid any
    /// 'initial' arbitration fee that was required. We assume we've already checked that the
    /// arbitrator is owed a nonzero amount.
    function payOutInitialArbitratorFee_Untrusted_Unguarded(uint agreementID) internal {
        AgreementDataETH storage agreement = agreements[agreementID];

        uint totalInitialFeesWei = toWei(
            add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee)
        );

        // Convert address to make it payable
        address(uint160(agreement.arbitratorAddress)).transfer(totalInitialFeesWei);
    }

    /// @notice Set or extend the deadline for both parties to pay the arbitration fee.
    function updateArbitrationResponseDeadline(AgreementDataETH storage agreement) internal {
        agreement.nextArbitrationStepAllowedAfterTimestamp =
            toUint32(
                add(
                    block.timestamp,
                    mul(agreement.daysToRespondToArbitrationRequest, (1 days))
                )
            );
    }

    /// @notice A helper function that sets the final resolution for the agreement, and
    /// also distributes funds to the participants based on distributeFundsToParties and
    /// distributeFundsToArbitrator.
    function finalizeResolution_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataETH storage agreement,
        uint48 res,
        bool distributeFundsToParties,
        bool distributeFundsToArbitrator
    )
        internal
    {
        agreement.resolution = res;
        calculateDisputeFeeLiability(agreementID, agreement);
        if (distributeFundsToParties) {
            emit FundsDistributed(uint32(agreementID));
            // These calls are not "Reentrancy Safe" (see AgreementManager.sol comments).
            // Using reentrancy guard.
            bool previousValue = getThenSetPendingExternalCall(agreement, true);
            distributeFundsToPartyHelper_Untrusted_Unguarded(agreementID, agreement, Party.A);
            distributeFundsToPartyHelper_Untrusted_Unguarded(agreementID, agreement, Party.B);
            setPendingExternalCall(agreement, previousValue);
        }
        if (distributeFundsToArbitrator) {
            distributeFundsToArbitratorHelper_Untrusted_Unguarded(agreementID, agreement);
        }
    }

    /// @notice This can only be called after a resolution is established.
    /// A helper function to distribute funds owed to a party based on the resolution and any
    /// arbitration fee refund they're owed.
    /// Assumes that a resolution exists.
    function distributeFundsToPartyHelper_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
    {
        require(!partyReceivedDistribution(agreement, party), "party already received funds.");
        setPartyReceivedDistribution(agreement, party, true);

        uint distributionAmount = 0;
        if (party == Party.A) {
            distributionAmount = agreement.resolution;
        } else {
            distributionAmount = sub(
                add(agreement.partyAStakeAmount, agreement.partyBStakeAmount),
                agreement.resolution
            );
        }

        uint distributionWei = add(
            toWei(distributionAmount),
            getPartyArbitrationRefundInWei(agreementID, agreement, party)
        );

        if (distributionWei > 0) {
            // Need to do this conversion to make the address payable
            address(uint160(partyAddress(agreement, party))).transfer(distributionWei);
        }
    }

    /// @notice A helper function to distribute funds owed to the arbitrator. These funds can be
    /// distributed either when the arbitrator calls withdrawDisputeFee or resolveAsArbitrator.
    function distributeFundsToArbitratorHelper_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataETH storage agreement
    )
        internal
    {
        require(!arbitratorReceivedDisputeFee(agreement), "Already received dispute fee.");
        setArbitratorReceivedDisputeFee(agreement, true);

        emit ArbitratorReceivedDisputeFee(uint32(agreementID));

        uint feeAmount = agreement.disputeFee;
        if (feeAmount > 0) {
            address(uint160(agreement.arbitratorAddress)).transfer(toWei(feeAmount));
        }
    }

    /// @notice Calculate and store in state variables who is responsible for paying any
    /// arbitration fee (if it was paid).
    /// @dev
    /// We set PARTY_A_DISPUTE_FEE_LIABILITY if partyA needs to pay some portion of the fee.
    /// We set PARTY_B_DISPUTE_FEE_LIABILITY if partyB needs to pay some portion of the fee.
    /// If both of the above values are true, then partyA and partyB are each liable for half of
    /// the arbitration fee.
    function calculateDisputeFeeLiability(
        uint argreementID,
        AgreementDataETH storage agreement
    )
        internal
    {
        // If arbitrator hasn't or won't get the dispute fee, there's no liability.
        if (!arbitratorGetsDisputeFee(argreementID, agreement)) {
            return;
        }

        // If A and B have compatible resolutions, then the arbitrator never issued a
        // ruling. Whichever of partyA and partyB resolved latest should have to pay the full
        // fee (because if they had resolved earlier, the arbitrator would never have had to be
        // called). See comments for PARTY_A_RESOLVED_LAST.
        if (
            resolutionsAreCompatibleBothExist(
                agreement.partyAResolution,
                agreement.partyBResolution,
                Party.A
            )
        ) {
            if (partyAResolvedLast(agreement)) {
                setPartyDisputeFeeLiability(agreement, Party.A, true);
            } else {
                setPartyDisputeFeeLiability(agreement, Party.B, true);
            }
            return;
        }

        // Now we know the parties rulings are not compatible with each other. If the ruling
        // from the arbitrator is compatible with either party, that party pays no fee and the
        // other party pays the full fee. Otherwise the parties are both liable for half the fee.
        if (
            resolutionsAreCompatibleBothExist(
                agreement.partyAResolution,
                agreement.resolution,
                Party.A
            )
        ) {
            setPartyDisputeFeeLiability(agreement, Party.B, true);
        } else if (
            resolutionsAreCompatibleBothExist(
                agreement.partyBResolution,
                agreement.resolution,
                Party.B
            )
        ) {
            setPartyDisputeFeeLiability(agreement, Party.A, true);
        } else {
            setPartyDisputeFeeLiability(agreement, Party.A, true);
            setPartyDisputeFeeLiability(agreement, Party.B, true);
        }
    }

    /// @return whether the arbitrator has either already gotten or is entitled to withdraw
    /// the dispute fee
    function arbitratorGetsDisputeFee(
        uint argreementID,
        AgreementDataETH storage agreement
    )
        internal
        returns (bool);
}"},"AgreementManagerETH_Simple.sol":{"content":"pragma solidity 0.5.3;

import "./AgreementManagerETH.sol";
import "./SimpleArbitrationInterface.sol";

/**
    @notice
    See AgreementManager for comments on the overall nature of this contract.

    This is the contract defining how ETH-only agreements with simple (non-ERC792)
    arbitration work.

    @dev
    The relevant part of the inheritance tree is:
    AgreementManager
        AgreementManagerETH
            AgreementManagerETH_Simple

    We also inherit from SimpleArbitrationInterface, a very simple interface that lets us avoid
    a small amount of code duplication for non-ERC792 arbitration.

    There should be no risk of re-entrancy attacks in this contract, since it makes no external
    calls aside from ETH transfers which always occur in ways that are Reentrancy Safe (see the
    comments in AgreementManager.sol for the meaning of "Reentrancy Safe").
*/

contract AgreementManagerETH_Simple is AgreementManagerETH, SimpleArbitrationInterface {
    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    event ArbitratorResolved(uint32 indexed agreementID, uint resolution);

    // -------------------------------------------------------------------------------------------
    // ---------------------------- external getter functions ------------------------------------
    // -------------------------------------------------------------------------------------------

    /// @return the full state of an agreement.
    /// Return value interpretation is self explanatory if you look at the code
    function getState(
        uint agreementID
    )
        external
        view
        returns (address[3] memory, uint[16] memory, bool[12] memory, bytes memory)
    {
        if (agreementID >= agreements.length) {
            address[3] memory zeroAddrs;
            uint[16] memory zeroUints;
            bool[12] memory zeroBools;
            bytes memory zeroBytes;
            return (zeroAddrs, zeroUints, zeroBools, zeroBytes);
        }

        AgreementDataETH storage agreement = agreements[agreementID];

        address[3] memory addrs = [
            agreement.partyAAddress,
            agreement.partyBAddress,
            agreement.arbitratorAddress
        ];
        uint[16] memory uints = [
            resolutionToWei(agreement.partyAResolution),
            resolutionToWei(agreement.partyBResolution),
            resolutionToWei(agreement.resolution),
            resolutionToWei(agreement.automaticResolution),
            toWei(agreement.partyAStakeAmount),
            toWei(agreement.partyBStakeAmount),
            toWei(agreement.partyAInitialArbitratorFee),
            toWei(agreement.partyBInitialArbitratorFee),
            toWei(agreement.disputeFee),
            agreement.nextArbitrationStepAllowedAfterTimestamp,
            agreement.autoResolveAfterTimestamp,
            agreement.daysToRespondToArbitrationRequest,
            // Return a bunch of zeroes where the ERC792 arbitration data is so we can have the
            // same API for all contracts.
            0,
            0,
            0,
            0
        ];
        bool[12] memory boolVals = [
            partyStakePaid(agreement, Party.A),
            partyStakePaid(agreement, Party.B),
            partyRequestedArbitration(agreement, Party.A),
            partyRequestedArbitration(agreement, Party.B),
            partyReceivedDistribution(agreement, Party.A),
            partyReceivedDistribution(agreement, Party.B),
            partyAResolvedLast(agreement),
            arbitratorResolved(agreement),
            arbitratorReceivedDisputeFee(agreement),
            partyDisputeFeeLiability(agreement, Party.A),
            partyDisputeFeeLiability(agreement, Party.B),
            // Return a false value where the ERC792 arbitration data is so we can have the
            // same API for all contracts.
            false
        ];
        // Return empty bytes value to keep the same API as for the ERC792 version
        bytes memory bytesVal;

        return (addrs, uints, boolVals, bytesVal);
    }

    // -------------------------------------------------------------------------------------------
    // -------------------- main external functions that affect state ----------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice Called by arbitrator to report their resolution.
    /// Can only be called after arbitrator is asked to arbitrate by both parties.
    /// @param resolutionWei The amount of wei that the caller thinks should go to party A.
    /// The remaining amount of wei staked for this agreement would go to party B.
    /// @param distributeFunds Whether to distribute funds to both parties and the arbitrator (if
    /// the arbitrator hasn't already called withdrawDisputeFee).
    function resolveAsArbitrator(
        uint agreementID,
        uint resolutionWei,
        bool distributeFunds
    )
        external
    {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        uint48 res = toMillionth(resolutionWei);

        require(
            msg.sender == agreement.arbitratorAddress,
            "resolveAsArbitrator can only be called by arbitrator."
        );
        require(
            res <= add(agreement.partyAStakeAmount, agreement.partyBStakeAmount),
            "Resolution out of range."
        );
        require(
            (
                partyRequestedArbitration(agreement, Party.A) &&
                partyRequestedArbitration(agreement, Party.B)
            ),
            "Arbitration not requested by both parties."
        );

        setArbitratorResolved(agreement, true);

        emit ArbitratorResolved(uint32(agreementID), resolutionWei);

        bool distributeToArbitrator = !arbitratorReceivedDisputeFee(agreement) && distributeFunds;

        finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            res,
            distributeFunds,
            distributeToArbitrator
        );
    }

    /// @notice Request that the arbitrator get involved to settle the disagreement.
    /// Each party needs to pay the full arbitration fee when calling this. However they will be
    /// refunded the full fee if the arbitrator agrees with them.
    /// If one party calls this and the other refuses to, the party who called this function can
    /// eventually call requestDefaultJudgment.
    function requestArbitration(uint agreementID) external payable {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");
        require(agreement.arbitratorAddress != address(0), "Arbitration is disallowed.");
        require(msg.value == toWei(agreement.disputeFee), "Arbitration fee amount is incorrect.");

        Party callingParty = getCallingParty(agreement);
        require(
            RESOLUTION_NULL != partyResolution(agreement, callingParty),
            "Need to enter a resolution before requesting arbitration."
        );
        require(
            !partyRequestedArbitration(agreement, callingParty),
            "This party already requested arbitration."
        );

        bool firstArbitrationRequest =
            !partyRequestedArbitration(agreement, Party.A) &&
            !partyRequestedArbitration(agreement, Party.B);

        require(
            (
                !firstArbitrationRequest ||
                block.timestamp > agreement.nextArbitrationStepAllowedAfterTimestamp
            ),
            "Arbitration not allowed yet."
        );

        setPartyRequestedArbitration(agreement, callingParty, true);

        emit ArbitrationRequested(uint32(agreementID));

        if (firstArbitrationRequest) {
            updateArbitrationResponseDeadline(agreement);
        } else {
            // Both parties have requested arbitration. Emit this event to conform to ERC1497.
            emit Dispute(
                Arbitrator(agreement.arbitratorAddress),
                agreementID,
                agreementID,
                agreementID
            );
        }
    }

    /// @notice Allow the arbitrator to indicate they're working on the dispute by withdrawing the
    /// funds. We can't prevent dishonest arbitrator from taking funds without doing work, because
    /// they can always call 'resolveAsArbitrator' quickly. So we prevent the arbitrator from
    /// actually being paid until they either call this function or 'resolveAsArbitrator' to avoid
    /// the case where we send funds to a nonresponsive arbitrator.
    function withdrawDisputeFee(uint agreementID) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(
            (
                partyRequestedArbitration(agreement, Party.A) &&
                partyRequestedArbitration(agreement, Party.B)
            ),
            "Arbitration not requested"
        );
        require(
            msg.sender == agreement.arbitratorAddress,
            "withdrawDisputeFee can only be called by Arbitrator."
        );
        require(
            !resolutionsAreCompatibleBothExist(
                agreement.partyAResolution,
                agreement.partyBResolution,
                Party.A
            ),
            "partyA and partyB already resolved their dispute."
        );

        distributeFundsToArbitratorHelper_Untrusted_Unguarded(agreementID, agreement);
    }

    // -------------------------------------------------------------------------------------------
    // ----------------------------- internal helper functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @dev This function is NOT untrusted in this contract.
    /// @return whether the given party has paid the arbitration fee in full.
    function partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
        uint, /*agreementID is unused in this version*/
        AgreementDataETH storage agreement,
        Party party) internal returns (bool) {

        // Since the arbitration fee can't change mid-agreement in simple arbitration,
        // having requested arbitration means the dispute fee is paid.
        return partyRequestedArbitration(agreement, party);
    }

    /// @return Whether the party provided is closer to winning a default judgment than the other
    /// party. For simple arbitration this means just that they'd paid the arbitration fee
    /// and the other party hasn't.
    function partyIsCloserToWinningDefaultJudgment(
        uint /*agreementID*/,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        returns (bool)
    {
        return partyRequestedArbitration(agreement, party) &&
            !partyRequestedArbitration(agreement, getOtherParty(party));
    }


    /// @notice See comments in AgreementManagerETH to understand the goal of this
    /// important function.
    /// @dev We don't use the first argument (agreementID) in this version, but it's there because
    /// we use inheritance.
    function getPartyArbitrationRefundInWei(
        uint /*agreementID*/,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (uint)
    {
        if (!partyRequestedArbitration(agreement, party)) {
            // party didn't pay an arbitration fee, so gets no refund.
            return 0;
        }

        // Now we know party paid an arbitration fee, so figure out how much of it they get back.

        if (partyDisputeFeeLiability(agreement, party)) {
            // party has liability for the dispute fee. The only question is whether they
            // pay the full amount or half.
            Party otherParty = getOtherParty(party);
            if (partyDisputeFeeLiability(agreement, otherParty)) {
                // party pays half the fee
                return toWei(agreement.disputeFee/2);
            }
            return 0; // pays the full fee
        }
        // No liability -- full refund
        return toWei(agreement.disputeFee);
    }

    /// @return whether the arbitrator has either already received or is entitled to withdraw
    /// the dispute fee
    function arbitratorGetsDisputeFee(
        uint /*agreementID*/,
        AgreementDataETH storage agreement
    )
        internal
        returns (bool)
    {
        return arbitratorResolved(agreement) || arbitratorReceivedDisputeFee(agreement);
    }
}
"},"Arbitrable.sol":{"content":"pragma solidity 0.5.3;

import "./Arbitrator.sol";

contract Arbitrable {

    function rule(uint _dispute, uint _ruling) public;

    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);
}"},"Arbitrator.sol":{"content":"pragma solidity 0.5.3;

import "./Arbitrable.sol";

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
contract Arbitrator {

    enum DisputeStatus { Waiting, Appealable, Solved }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes memory _extraData) public payable returns(uint disputeID);

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public view returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes memory _extraData) public payable;

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes memory _extraData) public view returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end);

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}"},"ERC20Interface.sol":{"content":"pragma solidity 0.5.3;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}"},"EvidenceProducer.sol":{"content":"pragma solidity 0.5.3;

import "./Arbitrator.sol";

// See ERC 1497
contract EvidenceProducer {
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);
}"},"SafeUtils.sol":{"content":"pragma solidity 0.5.3;

contract SafeUtils {
    function toUint48(uint val) internal pure returns (uint48) {
        uint48 ret = uint48(val);
        require(ret == val, "toUint48 lost some value.");
        return ret;
    }
    function toUint32(uint val) internal pure returns (uint32) {
        uint32 ret = uint32(val);
        require(ret == val, "toUint32 lost some value.");
        return ret;
    }
    function toUint16(uint val) internal pure returns (uint16) {
        uint16 ret = uint16(val);
        require(ret == val, "toUint16 lost some value.");
        return ret;
    }
    function toUint8(uint val) internal pure returns (uint8) {
        uint8 ret = uint8(val);
        require(ret == val, "toUint8 lost some value.");
        return ret;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Bad safe math multiplication.");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Attempt to divide by zero in safe math.");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Bad subtraction in safe math.");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Bad addition in safe math.");

        return c;
    }
}"},"SimpleArbitrationInterface.sol":{"content":"pragma solidity 0.5.3;

/**
    @notice A contract that AgreementManagers that implement simple (non-ERC792) arbitration can
    inherit from.

    This is currently too simple to be that useful, but things may be added to it in the future.
*/

contract SimpleArbitrationInterface {
    // -------------------------------------------------------------------------------------------
    // ----------------------------- internal helper functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @dev This is a no-op when using simple arbitration.
    /// Extra arbitration data is only needed for ERC792 arbitration.
    function storeArbitrationExtraData(uint, bytes memory) internal { }
}
"}}