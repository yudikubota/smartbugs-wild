{{
  "language": "Solidity",
  "sources": {
    "solidity/contracts/deposit/Deposit.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

import {DepositLiquidation} from "./DepositLiquidation.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositFunding} from "./DepositFunding.sol";
import {DepositRedemption} from "./DepositRedemption.sol";
import {DepositStates} from "./DepositStates.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {IERC721} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

import "../system/DepositFactoryAuthority.sol";

/// @title  Deposit.
/// @notice This is the main contract for tBTC. It is the state machine
/// that (through various libraries) handles bitcoin funding,
/// bitcoin-spv proofs, redemption, liquidation, and fraud logic.
/// @dev This is the execution context for libraries:
/// `DepositFunding`, `DepositLiquidaton`, `DepositRedemption`,
/// `DepositStates`, `DepositUtils`, `OutsourceDepositLogging`, and `TBTCConstants`.
contract Deposit is DepositFactoryAuthority {

    using DepositRedemption for DepositUtils.Deposit;
    using DepositFunding for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;

    DepositUtils.Deposit self;

    // We separate the constructor from createNewDeposit to make proxy factories easier.
    /* solium-disable-next-line no-empty-blocks */
    constructor () public {
        initialize(address(0));
    }

    function () external payable {
        require(msg.data.length == 0, "Deposit contract was called with unknown function selector.");
    }

    /// @notice     Get the keep contract address associated with the Deposit.
    /// @dev        The keep contract address is saved on Deposit initialization.
    /// @return     Address of the Keep contract.
    function getKeepAddress() public view returns (address) {
        return self.keepAddress;
    }

    /// @notice     Get the integer representing the current state.
    /// @dev        We implement this because contracts don't handle foreign enums well.
    ///             see DepositStates for more info on states.
    /// @return     The 0-indexed state from the DepositStates enum.
    function getCurrentState() public view returns (uint256) {
        return uint256(self.currentState);
    }

    /// @notice     Check if the Deposit is in ACTIVE state.
    /// @return     True if state is ACTIVE, fale otherwise.
    function inActive() public view returns (bool) {
        return self.inActive();
    }

    /// @notice Retrieve the remaining term of the deposit in seconds.
    /// @dev    The value accuracy is not guaranteed since block.timestmap can
    ///         be lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at term.
    function remainingTerm() public view returns(uint256){
        return self.remainingTerm();
    }

    /// @notice     Get the signer fee for the Deposit.
    /// @dev        This is the one-time fee required by the signers to perform .
    ///             the tasks needed to maintain a decentralized and trustless
    ///             model for tBTC. It is a percentage of the lotSize (deposit size).
    /// @return     Fee amount in tBTC.
    function signerFee() public view returns (uint256) {
        return self.signerFee();
    }

    /// @notice     Get the deposit's BTC lot size in satoshi.
    /// @return     uint64 lot size in satoshi.
    function lotSizeSatoshis() public view returns (uint64){
        return self.lotSizeSatoshis;
    }

    /// @notice     Get the Deposit ERC20 lot size.
    /// @dev        This is the same as lotSizeSatoshis(),
    ///             but is multiplied to scale to ERC20 decimal.
    /// @return     uint256 lot size in erc20 decimal (max 18 decimal places).
    function lotSizeTbtc() public view returns (uint256){
        return self.lotSizeTbtc();
    }

    /// @notice     Get the size of the funding UTXO.
    /// @dev        This will only return 0 unless
    ///             the funding transaction has been confirmed on-chain.
    ///             See `provideBTCFundingProof` for more info on the funding proof.
    /// @return     Uint256 UTXO size in satoshi.
    ///             0 if no funding proof has been provided.
    function utxoSize() public view returns (uint256){
        return self.utxoSize();
    }

    // THIS IS THE INIT FUNCTION
    /// @notice        The Deposit Factory can spin up a new deposit.
    /// @dev           Only the Deposit factory can call this.
    /// @param _tbtcSystem        `TBTCSystem` contract. More info in `TBTCSystem`.
    /// @param _tbtcToken         `TBTCToken` contract. More info in TBTCToken`.
    /// @param _tbtcDepositToken  `TBTCDepositToken` (TDT) contract. More info in `TBTCDepositToken`.
    /// @param _feeRebateToken    `FeeRebateToken` (FRT) contract. More info in `FeeRebateToken`.
    /// @param _vendingMachineAddress    `VendingMachine` address. More info in `VendingMachine`.
    /// @param _m           Signing group honesty threshold.
    /// @param _n           Signing group size.
    /// @param _lotSizeSatoshis The minimum amount of satoshi the funder is required to send.
    ///                         This is also the amount of TBTC the TDT holder will receive:
    ///                         (10**7 satoshi == 0.1 BTC == 0.1 TBTC).
    /// @return             True if successful, otherwise revert.
    function createNewDeposit(
        ITBTCSystem _tbtcSystem,
        TBTCToken _tbtcToken,
        IERC721 _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        address _vendingMachineAddress,
        uint16 _m,
        uint16 _n,
        uint64 _lotSizeSatoshis
    ) public onlyFactory payable returns (bool) {
        self.tbtcSystem = _tbtcSystem;
        self.tbtcToken = _tbtcToken;
        self.tbtcDepositToken = _tbtcDepositToken;
        self.feeRebateToken = _feeRebateToken;
        self.vendingMachineAddress = _vendingMachineAddress;
        self.createNewDeposit(_m, _n, _lotSizeSatoshis);
        return true;
    }

    /// @notice                     Deposit owner (TDT holder) can request redemption.
    ///                             Once redemption is requested
    ///                             a proof with sufficient accumulated difficulty is
    ///                             required to complete redemption.
    /// @dev                        The redeemer specifies details about the Bitcoin redemption tx.
    /// @param  _outputValueBytes   The 8-byte Little Endian output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @return                     True if successful, otherwise revert.
    function requestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public returns (bool) {
        self.requestRedemption(_outputValueBytes, _redeemerOutputScript);
        return true;
    }

    /// @notice                     Deposit owner (TDT holder) can request redemption.
    ///                             Once redemption is requested a proof with
    ///                             sufficient accumulated difficulty is required
    ///                             to complete redemption.
    /// @dev                        The caller specifies details about the Bitcoin redemption tx and pays
    ///                             for the redemption. The TDT (deposit ownership) is transfered to _finalRecipient, and
    ///                             _finalRecipient is marked as the deposit redeemer.
    /// @param  _outputValueBytes   The 8-byte LE output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The address to receive the TDT and later be recorded as deposit redeemer.
    function transferAndRequestRedemption(
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public returns (bool) {
        self.transferAndRequestRedemption(
            _outputValueBytes,
            _redeemerOutputScript,
            _finalRecipient
        );
        return true;
    }

    /// @notice             Get TBTC amount required for redemption by a specified _redeemer.
    /// @dev                Will revert if redemption is not possible by _redeemer.
    /// @param _redeemer    The deposit redeemer.
    /// @return             The amount in TBTC needed to redeem the deposit.
    function getRedemptionTbtcRequirement(address _redeemer) public view returns(uint256){
        return self.getRedemptionTbtcRequirement(_redeemer);
    }

    /// @notice             Get TBTC amount required for redemption assuming _redeemer
    ///                     is this deposit's owner (TDT holder).
    /// @param _redeemer    The assumed owner of the deposit's TDT .
    /// @return             The amount in TBTC needed to redeem the deposit.
    function getOwnerRedemptionTbtcRequirement(address _redeemer) public view returns(uint256){
        return self.getOwnerRedemptionTbtcRequirement(_redeemer);
    }

    /// @notice     Anyone may provide a withdrawal signature if it was requested.
    /// @dev        The signers will be penalized if this (or provideRedemptionProof) is not called.
    /// @param  _v  Signature recovery value.
    /// @param  _r  Signature R value.
    /// @param  _s  Signature S value. Should be in the low half of secp256k1 curve's order.
    /// @return     True if successful, False if prevented by timeout, otherwise revert.
    function provideRedemptionSignature(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public returns (bool) {
        self.provideRedemptionSignature(_v, _r, _s);
        return true;
    }

    /// @notice                             Anyone may notify the contract that a fee bump is needed.
    /// @dev                                This sends us back to AWAITING_WITHDRAWAL_SIGNATURE.
    /// @param  _previousOutputValueBytes   The previous output's value.
    /// @param  _newOutputValueBytes        The new output's value.
    /// @return                             True if successful, False if prevented by timeout, otherwise revert.
    function increaseRedemptionFee(
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) public returns (bool) {
        return self.increaseRedemptionFee(_previousOutputValueBytes, _newOutputValueBytes);
    }

    /// @notice                 Anyone may provide a withdrawal proof to prove redemption.
    /// @dev                    The signers will be penalized if this is not called.
    /// @param  _txVersion      Transaction version number (4-byte Little Endian).
    /// @param  _txInputVector  All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param  _txOutputVector All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param  _txLocktime     Final 4 bytes of the transaction.
    /// @param  _merkleProof    The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param  _txIndexInBlock The index of the tx in the Bitcoin block (0-indexed).
    /// @param  _bitcoinHeaders An array of tightly-packed bitcoin headers.
    function provideRedemptionProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public returns (bool) {
        self.provideRedemptionProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
        return true;
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a signature.
    /// @dev        This is considered fraud, and is punished.
    /// @return     True if successful, otherwise revert.
    function notifySignatureTimeout() public returns (bool) {
        self.notifySignatureTimeout();
        return true;
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a redemption proof.
    /// @dev        This is considered fraud, and is punished.
    /// @return     True if successful, otherwise revert.
    function notifyRedemptionProofTimeout() public returns (bool) {
        self.notifyRedemptionProofTimeout();
        return true;
    }

    //
    // FUNDING FLOW
    //

    /// @notice     Anyone may notify the contract that signing group setup has timed out.
    /// @return     True if successful, otherwise revert.
    function notifySignerSetupFailure() public returns (bool) {
        self.notifySignerSetupFailure();
        return true;
    }

    /// @notice             Poll the Keep contract to retrieve our pubkey.
    /// @dev                Store the pubkey as 2 bytestrings, X and Y.
    /// @return             True if successful, otherwise revert.
    function retrieveSignerPubkey() public returns (bool) {
        self.retrieveSignerPubkey();
        return true;
    }

    /// @notice     Anyone may notify the contract that the funder has failed to send BTC.
    /// @dev        This is considered a funder fault, and we revoke their bond.
    /// @return     True if successful, otherwise revert.
    function notifyFundingTimeout() public returns (bool) {
        self.notifyFundingTimeout();
        return true;
    }

    /// @notice Requests a funder abort for a failed-funding deposit; that is,
    ///         requests the return of a sent UTXO to _abortOutputScript. It
    ///         imposes no requirements on the signing group. Signers should
    ///         send their UTXO to the requested output script, but do so at
    ///         their discretion and with no penalty for failing to do so. This
    ///         can be used for example when a UTXO is sent that is the wrong
    ///         size for the lot.
    /// @dev This is a self-admitted funder fault, and is only be callable by
    ///      the TDT holder. This function emits the FunderAbortRequested event,
    ///      but stores no additional state.
    /// @param _abortOutputScript The output script the funder wishes to request
    ///        a return of their UTXO to.
    function requestFunderAbort(bytes memory _abortOutputScript) public {
        require(
            self.depositOwner() == msg.sender,
            "Only TDT holder can request funder abort"
        );

        self.requestFunderAbort(_abortOutputScript);
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud during funding.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    /// @return                 True if successful, otherwise revert.
    function provideFundingECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public returns (bool) {
        self.provideFundingECDSAFraudProof(_v, _r, _s, _signedDigest, _preimage);
        return true;
    }

    /// @notice                     Anyone may notify the deposit of a funding proof to activate the deposit.
    ///                             This is the happy-path of the funding flow. It means that we have succeeded.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    /// @return                     True if no errors are thrown.
    function provideBTCFundingProof(
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public returns (bool) {
        self.provideBTCFundingProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );
        return true;
    }

    //
    // FRAUD
    //

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    /// @return                 True if successful, otherwise revert.
    function provideECDSAFraudProof(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public returns (bool) {
        self.provideECDSAFraudProof(_v, _r, _s, _signedDigest, _preimage);
        return true;
    }

    //
    // LIQUIDATION
    //

    /// @notice Get the current collateralization level for this Deposit.
    /// @dev    This value represents the percentage of the backing BTC value the signers
    ///         currently must hold as bond.
    /// @return The current collateralization level for this deposit.
    function getCollateralizationPercentage() public view returns (uint256) {
        return self.getCollateralizationPercentage();
    }

    /// @notice Get the initial collateralization level for this Deposit.
    /// @dev    This value represents the percentage of the backing BTC value the signers hold initially.
    /// @return The initial collateralization level for this deposit.
    function getInitialCollateralizedPercent() public view returns (uint16) {
        return self.initialCollateralizedPercent;
    }

    /// @notice Get the undercollateralization level for this Deposit.
    /// @dev    This collateralization level is semi-critical. If the collateralization level falls
    ///         below this percentage the Deposit can get courtesy-called. This value represents the percentage
    ///         of the backing BTC value the signers must hold as bond in order to not be undercollateralized.
    /// @return The undercollateralized level for this deposit.
    function getUndercollateralizedThresholdPercent() public view returns (uint16) {
        return self.undercollateralizedThresholdPercent;
    }

    /// @notice Get the severe undercollateralization level for this Deposit.
    /// @dev    This collateralization level is critical. If the collateralization level falls
    ///         below this percentage the Deposit can get liquidated. This value represents the percentage
    ///         of the backing BTC value the signers must hold as bond in order to not be severely undercollateralized.
    /// @return The severely undercollateralized level for this deposit.
    function getSeverelyUndercollateralizedThresholdPercent() public view returns (uint16) {
        return self.severelyUndercollateralizedThresholdPercent;
    }

    /// @notice     Calculates the amount of value at auction right now.
    /// @dev        We calculate the % of the auction that has elapsed, then scale the value up.
    /// @return     The value in wei to distribute in the auction at the current time.
    function auctionValue() public view returns (uint256) {
        return self.auctionValue();
    }

    /// @notice     Closes an auction and purchases the signer bonds. Payout to buyer, funder, then signers if not fraud.
    /// @dev        For interface, reading auctionValue will give a past value. the current is better.
    /// @return     True if successful, revert otherwise.
    function purchaseSignerBondsAtAuction() public returns (bool) {
        self.purchaseSignerBondsAtAuction();
        return true;
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @return     True if successful, otherwise revert.
    function notifyCourtesyCall() public returns (bool) {
        self.notifyCourtesyCall();
        return true;
    }

    /// @notice     Goes from courtesy call to active.
    /// @dev        Only callable if collateral is sufficient and the deposit is not expiring.
    /// @return     True if successful, otherwise revert.
    function exitCourtesyCall() public returns (bool) {
        self.exitCourtesyCall();
        return true;
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @return     True if successful, otherwise revert.
    function notifyUndercollateralizedLiquidation() public returns (bool) {
        self.notifyUndercollateralizedLiquidation();
        return true;
    }

    /// @notice     Notifies the contract that the courtesy period has elapsed.
    /// @dev        This is treated as an abort, rather than fraud.
    /// @return     True if successful, otherwise revert.
    function notifyCourtesyTimeout() public returns (bool) {
        self.notifyCourtesyTimeout();
        return true;
    }

    /// @notice     Withdraw caller's allowance.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    /// @return     True if successful, otherwise revert.
    function withdrawFunds() public returns (bool) {
        self.withdrawFunds();
        return true;
    }

    /// @notice     Get caller's withdraw allowance.
    /// @return     The withdraw allowance in wei.
    function getWithdrawAllowance() public view returns (uint256) {
        return self.getWithdrawAllowance();
    }
}
"
    },
    "solidity/contracts/deposit/DepositRedemption.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {CheckBitcoinSigs} from "@summa-tx/bitcoin-spv-sol/contracts/CheckBitcoinSigs.sol";
import {IERC721} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositStates} from "./DepositStates.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {DepositLiquidation} from "./DepositLiquidation.sol";

library DepositRedemption {

    using SafeMath for uint256;
    using CheckBitcoinSigs for bytes;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice     Pushes signer fee to the Keep group by transferring it to the Keep address.
    /// @dev        Approves the keep contract, then expects it to call transferFrom.
    function distributeSignerFee(DepositUtils.Deposit storage _d) internal {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);

        _d.tbtcToken.approve(_d.keepAddress, _d.signerFee());
        _keep.distributeERC20Reward(address(_d.tbtcToken), _d.signerFee());
    }

    /// @notice Approves digest for signing by a keep.
    /// @dev Calls given keep to sign the digest. Records a current timestamp
    /// for given digest.
    /// @param _digest Digest to approve.
    function approveDigest(DepositUtils.Deposit storage _d, bytes32 _digest) internal {
        IBondedECDSAKeep(_d.keepAddress).sign(_digest);

        _d.approvedDigests[_digest] = block.timestamp;
    }

    /// @notice Handles TBTC requirements for redemption.
    /// @dev Burns or transfers depending on term and supply-peg impact.
    function performRedemptionTBTCTransfers(DepositUtils.Deposit storage _d) internal {
        address tdtHolder = _d.depositOwner();
        address vendingMachineAddress = _d.vendingMachineAddress;

        uint256 tbtcLot = _d.lotSizeTbtc();
        uint256 signerFee = _d.signerFee();
        uint256 tbtcOwed = _d.getRedemptionTbtcRequirement(_d.redeemerAddress);

        // if we owe 0 TBTC, msg.sender is TDT holder and FRT holder.
        if(tbtcOwed == 0){
            return;
        }
        // if we owe > 0 & < signerfee, msg.sender is TDT holder but not FRT holder.
        if(tbtcOwed <= signerFee){
            _d.tbtcToken.transferFrom(msg.sender, address(this), tbtcOwed);
            return;
        }
        // Redemmer always owes a full TBTC for at-term redemption.
        if(tbtcOwed == tbtcLot){
            // the TDT holder has exclusive redemption rights to a UXTO up until the depositâs term.
            // At that point, we open it up so anyone may redeem it.
            // As compensation, the TDT holder is reimbursed in TBTC
            // Vending Machine-owned TDTs have been used to mint TBTC,
            // and we should always burn a full TBTC to redeem the deposit.
            if(tdtHolder == vendingMachineAddress){
                _d.tbtcToken.burnFrom(msg.sender, tbtcLot);
            }
            // if signer fee is not escrowed, escrow and it here and send the rest to TDT holder
            else if(_d.tbtcToken.balanceOf(address(this)) < signerFee){
                _d.tbtcToken.transferFrom(msg.sender, address(this), signerFee);
                _d.tbtcToken.transferFrom(msg.sender, tdtHolder, tbtcLot.sub(signerFee));
            }
            // tansfer a full TBTC to TDT holder if signerFee is escrowed
            else{
                _d.tbtcToken.transferFrom(msg.sender, tdtHolder, tbtcLot);
            }
            return;
        }
        revert("tbtcOwed value must be 0, SignerFee, or a full TBTC");
    }

    function _requestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _redeemer
    ) internal {
        require(_d.inRedeemableState(), "Redemption only available from Active or Courtesy state");
        require(_redeemerOutputScript.length > 0, "cannot send value to zero output script");

        // set redeemerAddress early to enable direct access by other functions
        _d.redeemerAddress = _redeemer;

        performRedemptionTBTCTransfers(_d);

        // Convert the 8-byte LE ints to uint256
        uint256 _outputValue = abi.encodePacked(_outputValueBytes).reverseEndianness().bytesToUint();
        uint256 _requestedFee = _d.utxoSize().sub(_outputValue);
        require(_requestedFee >= TBTCConstants.getMinimumRedemptionFee(), "Fee is too low");

        // Calculate the sighash
        bytes32 _sighash = CheckBitcoinSigs.wpkhSpendSighash(
            _d.utxoOutpoint,
            _d.signerPKH(),
            _d.utxoSizeBytes,
            _outputValueBytes,
            _redeemerOutputScript);

        // write all request details
        _d.redeemerOutputScript = _redeemerOutputScript;
        _d.initialRedemptionFee = _requestedFee;
        _d.latestRedemptionFee = _requestedFee;
        _d.withdrawalRequestTime = block.timestamp;
        _d.lastRequestedDigest = _sighash;

        approveDigest(_d, _sighash);

        _d.setAwaitingWithdrawalSignature();
        _d.logRedemptionRequested(
            _redeemer,
            _sighash,
            _d.utxoSize(),
            _redeemerOutputScript,
            _requestedFee,
            _d.utxoOutpoint);
    }

    /// @notice                     Anyone can request redemption as long as they can.
    ///                             approve the TDT transfer to the final recipient.
    /// @dev                        The redeemer specifies details about the Bitcoin redemption tx and pays for the redemption
    ///                             on behalf of _finalRecipient.
    /// @param  _d                  Deposit storage pointer.
    /// @param  _outputValueBytes   The 8-byte LE output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The address to receive the TDT and later be recorded as deposit redeemer.
    function transferAndRequestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public {
        _d.tbtcDepositToken.transferFrom(msg.sender, _finalRecipient, uint256(address(this)));

        _requestRedemption(_d, _outputValueBytes, _redeemerOutputScript, _finalRecipient);
    }

    /// @notice                     Only TDT holder can request redemption,
    ///                             unless Deposit is expired or in COURTESY_CALL.
    /// @dev                        The redeemer specifies details about the Bitcoin redemption transaction.
    /// @param  _d                  Deposit storage pointer.
    /// @param  _outputValueBytes   The 8-byte LE output size.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    function requestRedemption(
        DepositUtils.Deposit storage _d,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript
    ) public {
        _requestRedemption(_d, _outputValueBytes, _redeemerOutputScript, msg.sender);
    }

    /// @notice     Anyone may provide a withdrawal signature if it was requested.
    /// @dev        The signers will be penalized if this (or provideRedemptionProof) is not called.
    /// @param  _d  Deposit storage pointer.
    /// @param  _v  Signature recovery value.
    /// @param  _r  Signature R value.
    /// @param  _s  Signature S value. Should be in the low half of secp256k1 curve's order.
    function provideRedemptionSignature(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(_d.inAwaitingWithdrawalSignature(), "Not currently awaiting a signature");

        // If we're outside of the signature window, we COULD punish signers here
        // Instead, we consider this a no-harm-no-foul situation.
        // The signers have not stolen funds. Most likely they've just inconvenienced someone

        // Validate `s` value for a malleability concern described in EIP-2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order are considered valid.
        require(
            uint256(_s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Malleable signature - s should be in the low half of secp256k1 curve's order"
        );

        // The signature must be valid on the pubkey
        require(
            _d.signerPubkey().checkSig(
                _d.lastRequestedDigest,
                _v, _r, _s
            ),
            "Invalid signature"
        );

        // A signature has been provided, now we wait for fee bump or redemption
        _d.setAwaitingWithdrawalProof();
        _d.logGotRedemptionSignature(
            _d.lastRequestedDigest,
            _r,
            _s);

    }

    /// @notice                             Anyone may notify the contract that a fee bump is needed.
    /// @dev                                This sends us back to AWAITING_WITHDRAWAL_SIGNATURE.
    /// @param  _d                          Deposit storage pointer.
    /// @param  _previousOutputValueBytes   The previous output's value.
    /// @param  _newOutputValueBytes        The new output's value.
    /// @return                             True if successful, False if prevented by timeout, otherwise revert.
    function increaseRedemptionFee(
        DepositUtils.Deposit storage _d,
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) public returns (bool) {
        require(_d.inAwaitingWithdrawalProof(), "Fee increase only available after signature provided");
        require(block.timestamp >= _d.withdrawalRequestTime.add(TBTCConstants.getIncreaseFeeTimer()), "Fee increase not yet permitted");

        uint256 _newOutputValue = checkRelationshipToPrevious(_d, _previousOutputValueBytes, _newOutputValueBytes);
        _d.latestRedemptionFee = _newOutputValue;
        // Calculate the next sighash
        bytes32 _sighash = CheckBitcoinSigs.wpkhSpendSighash(
            _d.utxoOutpoint,
            _d.signerPKH(),
            _d.utxoSizeBytes,
            _newOutputValueBytes,
            _d.redeemerOutputScript);

        // Ratchet the signature and redemption proof timeouts
        _d.withdrawalRequestTime = block.timestamp;
        _d.lastRequestedDigest = _sighash;

        approveDigest(_d, _sighash);

        // Go back to waiting for a signature
        _d.setAwaitingWithdrawalSignature();
        _d.logRedemptionRequested(
            msg.sender,
            _sighash,
            _d.utxoSize(),
            _d.redeemerOutputScript,
            _d.utxoSize().sub(_newOutputValue),
            _d.utxoOutpoint);
    }

    function checkRelationshipToPrevious(
        DepositUtils.Deposit storage _d,
        bytes8 _previousOutputValueBytes,
        bytes8 _newOutputValueBytes
    ) public view returns (uint256 _newOutputValue){

        // Check that we're incrementing the fee by exactly the redeemer's initial fee
        uint256 _previousOutputValue = DepositUtils.bytes8LEToUint(_previousOutputValueBytes);
        _newOutputValue = DepositUtils.bytes8LEToUint(_newOutputValueBytes);
        require(_previousOutputValue.sub(_newOutputValue) == _d.initialRedemptionFee, "Not an allowed fee step");

        // Calculate the previous one so we can check that it really is the previous one
        bytes32 _previousSighash = CheckBitcoinSigs.wpkhSpendSighash(
            _d.utxoOutpoint,
            _d.signerPKH(),
            _d.utxoSizeBytes,
            _previousOutputValueBytes,
            _d.redeemerOutputScript);
        require(
            _d.wasDigestApprovedForSigning(_previousSighash) == _d.withdrawalRequestTime,
            "Provided previous value does not yield previous sighash"
        );
    }

    /// @notice                 Anyone may provide a withdrawal proof to prove redemption.
    /// @dev                    The signers will be penalized if this is not called.
    /// @param  _d              Deposit storage pointer.
    /// @param  _txVersion      Transaction version number (4-byte LE).
    /// @param  _txInputVector  All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param  _txOutputVector All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param  _txLocktime     Final 4 bytes of the transaction.
    /// @param  _merkleProof    The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param  _txIndexInBlock The index of the tx in the Bitcoin block (0-indexed).
    /// @param  _bitcoinHeaders An array of tightly-packed bitcoin headers.
    function provideRedemptionProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        bytes32 _txid;
        uint256 _fundingOutputValue;

        require(_d.inRedemption(), "Redemption proof only allowed from redemption flow");

        _fundingOutputValue = redemptionTransactionChecks(_d, _txInputVector, _txOutputVector);

        _txid = abi.encodePacked(_txVersion, _txInputVector, _txOutputVector, _txLocktime).hash256();
        _d.checkProofFromTxId(_txid, _merkleProof, _txIndexInBlock, _bitcoinHeaders);

        require((_d.utxoSize().sub(_fundingOutputValue)) <= _d.latestRedemptionFee, "Incorrect fee amount");

        // Transfer TBTC to signers and close the keep.
        distributeSignerFee(_d);
        _d.closeKeep();

        _d.distributeFeeRebate();

        // We're done yey!
        _d.setRedeemed();
        _d.redemptionTeardown();
        _d.logRedeemed(_txid);
    }

    /// @notice                 Check the redemption transaction input and output vector to ensure the transaction spends
    ///                         the correct UTXO and sends value to the appropriate public key hash.
    /// @dev                    We only look at the first input and first output. Revert if we find the wrong UTXO or value recipient.
    ///                         It's safe to look at only the first input/output as anything that breaks this can be considered fraud
    ///                         and can be caught by ECDSAFraudProof.
    /// @param  _d              Deposit storage pointer.
    /// @param _txInputVector   All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector  All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @return                 The value sent to the redeemer's public key hash.
    function redemptionTransactionChecks(
        DepositUtils.Deposit storage _d,
        bytes memory _txInputVector,
        bytes memory _txOutputVector
    ) public view returns (uint256) {
        require(_txInputVector.validateVin(), "invalid input vector provided");
        require(_txOutputVector.validateVout(), "invalid output vector provided");

        bytes memory _input = _txInputVector.slice(1, _txInputVector.length-1);
        bytes memory _output = _txOutputVector.slice(1, _txOutputVector.length-1);

        require(
            keccak256(_input.extractOutpoint()) == keccak256(_d.utxoOutpoint),
            "Tx spends the wrong UTXO"
        );
        require(
            keccak256(_output.slice(8, 3).concat(_output.extractHash())) == keccak256(abi.encodePacked(_d.redeemerOutputScript)),
            "Tx sends value to wrong pubkeyhash"
        );
        return (uint256(_output.extractValue()));
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a signature.
    /// @dev        This is considered fraud, and is punished.
    /// @param  _d  Deposit storage pointer.
    function notifySignatureTimeout(DepositUtils.Deposit storage _d) public {
        require(_d.inAwaitingWithdrawalSignature(), "Not currently awaiting a signature");
        require(block.timestamp > _d.withdrawalRequestTime.add(TBTCConstants.getSignatureTimeout()), "Signature timer has not elapsed");
        _d.startLiquidation(false);  // not fraud, just failure
    }

    /// @notice     Anyone may notify the contract that the signers have failed to produce a redemption proof.
    /// @dev        This is considered fraud, and is punished.
    /// @param  _d  Deposit storage pointer.
    function notifyRedemptionProofTimeout(DepositUtils.Deposit storage _d) public {
        require(_d.inAwaitingWithdrawalProof(), "Not currently awaiting a redemption proof");
        require(block.timestamp > _d.withdrawalRequestTime.add(TBTCConstants.getRedemptionProofTimeout()), "Proof timer has not elapsed");
        _d.startLiquidation(false);  // not fraud, just failure
    }
}
"
    },
    "solidity/contracts/deposit/DepositLiquidation.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";

library DepositLiquidation {

    using BTCUtils for bytes;
    using BytesLib for bytes;
    using SafeMath for uint256;
    using SafeMath for uint64;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice                 Notifies the keep contract of fraud.
    /// @dev                    Calls out to the keep contract. this could get expensive if preimage is large.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    /// @return                 True if fraud, otherwise revert.
    function submitSignatureFraud(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public returns (bool _isFraud) {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        return _keep.submitSignatureFraud(_v, _r, _s, _signedDigest, _preimage);
    }

    /// @notice     Determines the collateralization percentage of the signing group.
    /// @dev        Compares the bond value and lot value.
    /// @param _d   Deposit storage pointer.
    /// @return     Collateralization percentage as uint.
    function getCollateralizationPercentage(DepositUtils.Deposit storage _d) public view returns (uint256) {

        // Determine value of the lot in wei
        uint256 _satoshiPrice = _d.fetchBitcoinPrice();
        uint64 _lotSizeSatoshis = _d.lotSizeSatoshis;
        uint256 _lotValue = _lotSizeSatoshis.mul(_satoshiPrice);

        // Amount of wei the signers have
        uint256 _bondValue = _d.fetchBondAmount();

        // This converts into a percentage
        return (_bondValue.mul(100).div(_lotValue));
    }

    /// @dev              Starts signer liquidation by seizing signer bonds.
    ///                   If the deposit is currently being redeemed, the redeemer
    ///                   receives the full bond value; otherwise, a falling price auction
    ///                   begins to buy 1 TBTC in exchange for a portion of the seized bonds;
    ///                   see purchaseSignerBondsAtAuction().
    /// @param _wasFraud  True if liquidation is being started due to fraud, false if for any other reason.
    /// @param _d         Deposit storage pointer.
    function startLiquidation(DepositUtils.Deposit storage _d, bool _wasFraud) internal {
        _d.logStartedLiquidation(_wasFraud);

        uint256 seized = _d.seizeSignerBonds();
        address redeemerAddress = _d.redeemerAddress;

        // Reclaim used state for gas savings
        _d.redemptionTeardown();

        // if we come from the redemption flow we shouldn't go to auction.
        // Instead give the signer bonds to redeemer
        if (_d.inRedemption()) {
            _d.setLiquidated();
            _d.enableWithdrawal(redeemerAddress, seized);
            _d.logLiquidated();
            return;
        }

        _d.liquidationInitiator = msg.sender;
        _d.liquidationInitiated = block.timestamp;  // Store the timestamp for auction

        if(_wasFraud){
            _d.setFraudLiquidationInProgress();
        }
        else{
            _d.setLiquidationInProgress();
        }
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    function provideECDSAFraudProof(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        require(
            !_d.inFunding(),
            "Use provideFundingECDSAFraudProof instead"
        );
        require(
            !_d.inSignerLiquidation(),
            "Signer liquidation already in progress"
        );
        require(!_d.inEndState(), "Contract has halted");
        submitSignatureFraud(_d, _v, _r, _s, _signedDigest, _preimage);

        startLiquidation(_d, true);
    }

    /// @notice                 Search _txOutputVector for output paying the redeemer.
    /// @dev                    Require that outputs checked are witness.
    /// @param  _d              Deposit storage pointer.
    /// @param _txOutputVector  All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @return                 False if output paying redeemer was found, true otherwise.
    function validateRedeemerNotPaid(
        DepositUtils.Deposit storage _d,
        bytes memory _txOutputVector
    ) internal view returns (bool){
        bytes memory _output;
        uint256 _offset = 1;
        uint256 _permittedFeeBumps = TBTCConstants.getPermittedFeeBumps();
        uint256 _requiredOutputValue = _d.utxoSize().sub((_d.initialRedemptionFee.mul((_permittedFeeBumps.add(1)))));

        uint8 _numOuts = uint8(_txOutputVector.slice(0, 1)[0]);
        for (uint8 i = 0; i < _numOuts; i++) {
            _output = _txOutputVector.slice(_offset, _txOutputVector.length.sub(_offset));
            _offset = _offset.add(_output.determineOutputLength());

            if (_output.extractValue() >= _requiredOutputValue &&
                keccak256(_output.slice(8, 3).concat(_output.extractHash())) == keccak256(abi.encodePacked(_d.redeemerOutputScript))) {
                return false;
            }
        }
        return true;
    }

    /// @notice     Closes an auction and purchases the signer bonds. Payout to buyer, funder, then signers if not fraud.
    /// @dev        For interface, reading auctionValue will give a past value. the current is better.
    /// @param  _d  Deposit storage pointer.
    function purchaseSignerBondsAtAuction(DepositUtils.Deposit storage _d) public {
        bool _wasFraud = _d.inFraudLiquidationInProgress();
        require(_d.inSignerLiquidation(), "No active auction");

        _d.setLiquidated();
        _d.logLiquidated();

        // send the TBTC to the TDT holder. If the TDT holder is the Vending Machine, burn it to maintain the peg.
        address tdtHolder = _d.depositOwner();
        uint256 lotSizeTbtc = _d.lotSizeTbtc();

        require(_d.tbtcToken.balanceOf(msg.sender) >= lotSizeTbtc, "Not enough TBTC to cover outstanding debt");

        if(tdtHolder == _d.vendingMachineAddress){
            _d.tbtcToken.burnFrom(msg.sender, lotSizeTbtc);  // burn minimal amount to cover size
        }
        else{
            _d.tbtcToken.transferFrom(msg.sender, tdtHolder, lotSizeTbtc);
        }

        // Distribute funds to auction buyer
        uint256 valueToDistribute = _d.auctionValue();
        _d.enableWithdrawal(msg.sender, valueToDistribute);

        // Send any TBTC left to the Fee Rebate Token holder
        _d.distributeFeeRebate();

        // For fraud, pay remainder to the liquidation initiator.
        // For non-fraud, split 50-50 between initiator and signers. if the transfer amount is 1,
        // division will yield a 0 value which causes a revert; instead,
        // we simply ignore such a tiny amount and leave some wei dust in escrow
        uint256 contractEthBalance = address(this).balance;
        address payable initiator = _d.liquidationInitiator;

        if (initiator == address(0)){
            initiator = address(0xdead);
        }
        if (contractEthBalance > valueToDistribute + 1) {
            uint256 remainingUnallocated = contractEthBalance.sub(valueToDistribute);
            if (_wasFraud) {
                _d.enableWithdrawal(initiator, remainingUnallocated);
            } else {
                // There will always be a liquidation initiator.
                uint256 split = remainingUnallocated.div(2);
                _d.pushFundsToKeepGroup(split);
                _d.enableWithdrawal(initiator, remainingUnallocated.sub(split));
            }
        }
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyCall(DepositUtils.Deposit storage _d) public  {
        require(_d.inActive(), "Can only courtesy call from active state");
        require(getCollateralizationPercentage(_d) < _d.undercollateralizedThresholdPercent, "Signers have sufficient collateral");
        _d.courtesyCallInitiated = block.timestamp;
        _d.setCourtesyCall();
        _d.logCourtesyCalled();
    }

    /// @notice     Goes from courtesy call to active.
    /// @dev        Only callable if collateral is sufficient and the deposit is not expiring.
    /// @param  _d  Deposit storage pointer.
    function exitCourtesyCall(DepositUtils.Deposit storage _d) public {
        require(_d.inCourtesyCall(), "Not currently in courtesy call");
        require(getCollateralizationPercentage(_d) >= _d.undercollateralizedThresholdPercent, "Deposit is still undercollateralized");
        _d.setActive();
        _d.logExitedCourtesyCall();
    }

    /// @notice     Notify the contract that the signers are undercollateralized.
    /// @dev        Calls out to the system for oracle info.
    /// @param  _d  Deposit storage pointer.
    function notifyUndercollateralizedLiquidation(DepositUtils.Deposit storage _d) public {
        require(_d.inRedeemableState(), "Deposit not in active or courtesy call");
        require(getCollateralizationPercentage(_d) < _d.severelyUndercollateralizedThresholdPercent, "Deposit has sufficient collateral");
        startLiquidation(_d, false);
    }

    /// @notice     Notifies the contract that the courtesy period has elapsed.
    /// @dev        This is treated as an abort, rather than fraud.
    /// @param  _d  Deposit storage pointer.
    function notifyCourtesyTimeout(DepositUtils.Deposit storage _d) public {
        require(_d.inCourtesyCall(), "Not in a courtesy call period");
        require(block.timestamp >= _d.courtesyCallInitiated.add(TBTCConstants.getCourtesyCallTimeout()), "Courtesy period has not elapsed");
        startLiquidation(_d, false);
    }
}
"
    },
    "solidity/contracts/deposit/DepositUtils.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {IERC721} from "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {DepositStates} from "./DepositStates.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";
import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {FeeRebateToken} from "../system/FeeRebateToken.sol";

library DepositUtils {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;
    using DepositStates for DepositUtils.Deposit;

    struct Deposit {

        // SET DURING CONSTRUCTION
        ITBTCSystem tbtcSystem;
        TBTCToken tbtcToken;
        IERC721 tbtcDepositToken;
        FeeRebateToken feeRebateToken;
        address vendingMachineAddress;
        uint64 lotSizeSatoshis;
        uint8 currentState;
        uint16 signerFeeDivisor;
        uint16 initialCollateralizedPercent;
        uint16 undercollateralizedThresholdPercent;
        uint16 severelyUndercollateralizedThresholdPercent;
        uint256 keepSetupFee;

        // SET ON FRAUD
        uint256 liquidationInitiated;  // Timestamp of when liquidation starts
        uint256 courtesyCallInitiated; // When the courtesy call is issued
        address payable liquidationInitiator;

        // written when we request a keep
        address keepAddress;  // The address of our keep contract
        uint256 signingGroupRequestedAt;  // timestamp of signing group request

        // written when we get a keep result
        uint256 fundingProofTimerStart;  // start of the funding proof period. reused for funding fraud proof period
        bytes32 signingGroupPubkeyX;  // The X coordinate of the signing group's pubkey
        bytes32 signingGroupPubkeyY;  // The Y coordinate of the signing group's pubkey

        // INITIALLY WRITTEN BY REDEMPTION FLOW
        address payable redeemerAddress;  // The redeemer's address, used as fallback for fraud in redemption
        bytes redeemerOutputScript;  // The redeemer output script
        uint256 initialRedemptionFee;  // the initial fee as requested
        uint256 latestRedemptionFee; // the fee currently required by a redemption transaction
        uint256 withdrawalRequestTime;  // the most recent withdrawal request timestamp
        bytes32 lastRequestedDigest;  // the digest most recently requested for signing

        // written when we get funded
        bytes8 utxoSizeBytes;  // LE uint. the size of the deposit UTXO in satoshis
        uint256 fundedAt; // timestamp when funding proof was received
        bytes utxoOutpoint;  // the 36-byte outpoint of the custodied UTXO

        /// @dev Map of ETH balances an address can withdraw after contract reaches ends-state.
        mapping(address => uint256) withdrawalAllowances;

        /// @dev Map of timestamps representing when transaction digests were approved for signing
        mapping (bytes32 => uint256) approvedDigests;
    }

    /// @notice Closes keep associated with the deposit.
    /// @dev Should be called when the keep is no longer needed and the signing
    /// group can disband.
    function closeKeep(DepositUtils.Deposit storage _d) internal {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.closeKeep();
    }

    /// @notice         Gets the current block difficulty.
    /// @dev            Calls the light relay and gets the current block difficulty.
    /// @return         The difficulty.
    function currentBlockDifficulty(Deposit storage _d) public view returns (uint256) {
        return _d.tbtcSystem.fetchRelayCurrentDifficulty();
    }

    /// @notice         Gets the previous block difficulty.
    /// @dev            Calls the light relay and gets the previous block difficulty.
    /// @return         The difficulty.
    function previousBlockDifficulty(Deposit storage _d) public view returns (uint256) {
        return _d.tbtcSystem.fetchRelayPreviousDifficulty();
    }

    /// @notice                     Evaluates the header difficulties in a proof.
    /// @dev                        Uses the light oracle to source recent difficulty.
    /// @param  _bitcoinHeaders     The header chain to evaluate.
    /// @return                     True if acceptable, otherwise revert.
    function evaluateProofDifficulty(Deposit storage _d, bytes memory _bitcoinHeaders) public view {
        uint256 _reqDiff;
        uint256 _current = currentBlockDifficulty(_d);
        uint256 _previous = previousBlockDifficulty(_d);
        uint256 _firstHeaderDiff = _bitcoinHeaders.extractTarget().calculateDifficulty();

        if (_firstHeaderDiff == _current) {
            _reqDiff = _current;
        } else if (_firstHeaderDiff == _previous) {
            _reqDiff = _previous;
        } else {
            revert("not at current or previous difficulty");
        }

        uint256 _observedDiff = _bitcoinHeaders.validateHeaderChain();

        require(_observedDiff != ValidateSPV.getErrBadLength(), "Invalid length of the headers chain");
        require(_observedDiff != ValidateSPV.getErrInvalidChain(), "Invalid headers chain");
        require(_observedDiff != ValidateSPV.getErrLowWork(), "Insufficient work in a header");

        require(
            _observedDiff >= _reqDiff.mul(TBTCConstants.getTxProofDifficultyFactor()),
            "Insufficient accumulated difficulty in header chain"
        );
    }

    /// @notice                 Syntactically check an SPV proof for a bitcoin transaction with its hash (ID).
    /// @dev                    Stateless SPV Proof verification documented elsewhere (see https://github.com/summa-tx/bitcoin-spv).
    /// @param _d               Deposit storage pointer.
    /// @param _txId            The bitcoin txid of the tx that is purportedly included in the header chain.
    /// @param _merkleProof     The merkle proof of inclusion of the tx in the bitcoin block.
    /// @param _txIndexInBlock  The index of the tx in the Bitcoin block (0-indexed).
    /// @param _bitcoinHeaders  An array of tightly-packed bitcoin headers.
    function checkProofFromTxId(
        Deposit storage _d,
        bytes32 _txId,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view{
        require(
            _txId.prove(
                _bitcoinHeaders.extractMerkleRootLE().toBytes32(),
                _merkleProof,
                _txIndexInBlock
            ),
            "Tx merkle proof is not valid for provided header and txId");
        evaluateProofDifficulty(_d, _bitcoinHeaders);
    }

    /// @notice                     Find and validate funding output in transaction output vector using the index.
    /// @dev                        Gets `_fundingOutputIndex` output from the output vector and validates if it's
    ///                             Public Key Hash matches a Public Key Hash of the deposit.
    /// @param _d                   Deposit storage pointer.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC outputs.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector.
    /// @return                     Funding value.
    function findAndParseFundingOutput(
        DepositUtils.Deposit storage _d,
        bytes memory _txOutputVector,
        uint8 _fundingOutputIndex
    ) public view returns (bytes8) {
        bytes8 _valueBytes;
        bytes memory _output;

        // Find the output paying the signer PKH
        _output = _txOutputVector.extractOutputAtIndex(_fundingOutputIndex);

        if (keccak256(_output.extractHash()) == keccak256(abi.encodePacked(signerPKH(_d)))) {
            _valueBytes = bytes8(_output.slice(0, 8).toBytes32());
            return _valueBytes;
        }
        // If we don't return from inside the loop, we failed.
        revert("could not identify output funding the required public key hash");
    }

    /// @notice                     Validates the funding tx and parses information from it.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param  _d                  Deposit storage pointer.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    /// @return                     The 8-byte LE UTXO size in satoshi, the 36byte outpoint.
    function validateAndParseFundingSPVProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public view returns (bytes8 _valueBytes, bytes memory _utxoOutpoint){
        require(_txInputVector.validateVin(), "invalid input vector provided");
        require(_txOutputVector.validateVout(), "invalid output vector provided");

        bytes32 txID = abi.encodePacked(_txVersion, _txInputVector, _txOutputVector, _txLocktime).hash256();

        _valueBytes = findAndParseFundingOutput(_d, _txOutputVector, _fundingOutputIndex);

        require(bytes8LEToUint(_valueBytes) >= _d.lotSizeSatoshis, "Deposit too small");

        checkProofFromTxId(_d, txID, _merkleProof, _txIndexInBlock, _bitcoinHeaders);

        // The utxoOutpoint is the LE txID plus the index of the output as a 4-byte LE int
        // _fundingOutputIndex is a uint8, so we know it is only 1 byte
        // Therefore, pad with 3 more bytes
        _utxoOutpoint = abi.encodePacked(txID, _fundingOutputIndex, hex"000000");
    }

    /// @notice Retreive the remaining term of the deposit
    /// @dev    The return value is not guaranteed since block.timestmap can be lightly manipulated by miners.
    /// @return The remaining term of the deposit in seconds. 0 if already at term
    function remainingTerm(DepositUtils.Deposit storage _d) public view returns(uint256){
        uint256 endOfTerm = _d.fundedAt.add(TBTCConstants.getDepositTerm());
        if(block.timestamp < endOfTerm ) {
            return endOfTerm.sub(block.timestamp);
        }
        return 0;
    }

    /// @notice     Calculates the amount of value at auction right now.
    /// @dev        We calculate the % of the auction that has elapsed, then scale the value up.
    /// @param _d   Deposit storage pointer.
    /// @return     The value in wei to distribute in the auction at the current time.
    function auctionValue(Deposit storage _d) public view returns (uint256) {
        uint256 _elapsed = block.timestamp.sub(_d.liquidationInitiated);
        uint256 _available = address(this).balance;
        if (_elapsed > TBTCConstants.getAuctionDuration()) {
            return _available;
        }

        // This should make a smooth flow from base% to 100%
        uint256 _basePercentage = getAuctionBasePercentage(_d);
        uint256 _elapsedPercentage = uint256(100).sub(_basePercentage).mul(_elapsed).div(TBTCConstants.getAuctionDuration());
        uint256 _percentage = _basePercentage.add(_elapsedPercentage);

        return _available.mul(_percentage).div(100);
    }

    /// @notice         Gets the lot size in erc20 decimal places (max 18)
    /// @return         uint256 lot size in 10**18 decimals.
    function lotSizeTbtc(Deposit storage _d) public view returns (uint256){
        return _d.lotSizeSatoshis.mul(TBTCConstants.getSatoshiMultiplier());
    }

    /// @notice         Determines the fees due to the signers for work performed.
    /// @dev            Signers are paid based on the TBTC issued.
    /// @return         Accumulated fees in smallest TBTC unit (tsat).
    function signerFee(Deposit storage _d) public view returns (uint256) {
        return lotSizeTbtc(_d).div(_d.signerFeeDivisor);
    }

    /// @notice             Determines the prefix to the compressed public key.
    /// @dev                The prefix encodes the parity of the Y coordinate.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 1-byte prefix for the compressed key.
    function determineCompressionPrefix(bytes32 _pubkeyY) public pure returns (bytes memory) {
        if(uint256(_pubkeyY) & 1 == 1) {
            return hex"03";  // Odd Y
        } else {
            return hex"02";  // Even Y
        }
    }

    /// @notice             Compresses a public key.
    /// @dev                Converts the 64-byte key to a 33-byte key, bitcoin-style.
    /// @param  _pubkeyX    The X coordinate of the public key.
    /// @param  _pubkeyY    The Y coordinate of the public key.
    /// @return             The 33-byte compressed pubkey.
    function compressPubkey(bytes32 _pubkeyX, bytes32 _pubkeyY) public pure returns (bytes memory) {
        return abi.encodePacked(determineCompressionPrefix(_pubkeyY), _pubkeyX);
    }

    /// @notice    Returns the packed public key (64 bytes) for the signing group.
    /// @dev       We store it as 2 bytes32, (2 slots) then repack it on demand.
    /// @return    64 byte public key.
    function signerPubkey(Deposit storage _d) public view returns (bytes memory) {
        return abi.encodePacked(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
    }

    /// @notice    Returns the Bitcoin pubkeyhash (hash160) for the signing group.
    /// @dev       This is used in bitcoin output scripts for the signers.
    /// @return    20-bytes public key hash.
    function signerPKH(Deposit storage _d) public view returns (bytes20) {
        bytes memory _pubkey = compressPubkey(_d.signingGroupPubkeyX, _d.signingGroupPubkeyY);
        bytes memory _digest = _pubkey.hash160();
        return bytes20(_digest.toAddress(0));  // dirty solidity hack
    }

    /// @notice    Returns the size of the deposit UTXO in satoshi.
    /// @dev       We store the deposit as bytes8 to make signature checking easier.
    /// @return    UTXO value in satoshi.
    function utxoSize(Deposit storage _d) public view returns (uint256) {
        return bytes8LEToUint(_d.utxoSizeBytes);
    }

    /// @notice     Gets the current price of Bitcoin in Ether.
    /// @dev        Polls the price feed via the system contract.
    /// @return     The current price of 1 sat in wei.
    function fetchBitcoinPrice(Deposit storage _d) public view returns (uint256) {
        return _d.tbtcSystem.fetchBitcoinPrice();
    }

    /// @notice     Fetches the Keep's bond amount in wei.
    /// @dev        Calls the keep contract to do so.
    /// @return     The amount of bonded ETH in wei.
    function fetchBondAmount(Deposit storage _d) public view returns (uint256) {
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        return _keep.checkBondAmount();
    }

    /// @notice         Convert a LE bytes8 to a uint256.
    /// @dev            Do this by converting to bytes, then reversing endianness, then converting to int.
    /// @return         The uint256 represented in LE by the bytes8.
    function bytes8LEToUint(bytes8 _b) public pure returns (uint256) {
        return abi.encodePacked(_b).reverseEndianness().bytesToUint();
    }

    /// @notice         Gets timestamp of digest approval for signing.
    /// @dev            Identifies entry in the recorded approvals by keep ID and digest pair.
    /// @param _digest  Digest to check approval for.
    /// @return         Timestamp from the moment of recording the digest for signing.
    ///                 Returns 0 if the digest was not approved for signing.
    function wasDigestApprovedForSigning(Deposit storage _d, bytes32 _digest) public view returns (uint256) {
        return _d.approvedDigests[_digest];
    }

    /// @notice         Looks up the Fee Rebate Token holder.
    /// @return         The current token holder if the Token exists.
    ///                 address(0) if the token does not exist.
    function feeRebateTokenHolder(Deposit storage _d) public view returns (address payable) {
        address tokenHolder;
        if(_d.feeRebateToken.exists(uint256(address(this)))){
            tokenHolder = address(uint160(_d.feeRebateToken.ownerOf(uint256(address(this)))));
        }
        return address(uint160(tokenHolder));
    }

    /// @notice         Looks up the deposit beneficiary by calling the tBTC system.
    /// @dev            We cast the address to a uint256 to match the 721 standard.
    /// @return         The current deposit beneficiary.
    function depositOwner(Deposit storage _d) public view returns (address payable) {
        return address(uint160(_d.tbtcDepositToken.ownerOf(uint256(address(this)))));
    }

    /// @notice     Deletes state after termination of redemption process.
    /// @dev        We keep around the redeemer address so we can pay them out.
    function redemptionTeardown(Deposit storage _d) public {
        _d.redeemerOutputScript = "";
        _d.initialRedemptionFee = 0;
        _d.withdrawalRequestTime = 0;
        _d.lastRequestedDigest = bytes32(0);
        _d.redeemerAddress = address(0);
    }


    /// @notice     Get the starting percentage of the bond at auction.
    /// @dev        This will return the same value regardless of collateral price.
    /// @return     The percentage of the InitialCollateralizationPercent that will result
    ///             in a 100% bond value base auction given perfect collateralization.
    function getAuctionBasePercentage(Deposit storage _d) internal view returns (uint256) {
        return uint256(10000).div(_d.initialCollateralizedPercent);
    }

    /// @notice     Seize the signer bond from the keep contract.
    /// @dev        we check our balance before and after.
    /// @return     The amount seized in wei.
    function seizeSignerBonds(Deposit storage _d) internal returns (uint256) {
        uint256 _preCallBalance = address(this).balance;

        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.seizeSignerBonds();

        uint256 _postCallBalance = address(this).balance;
        require(_postCallBalance > _preCallBalance, "No funds received, unexpected");
        return _postCallBalance.sub(_preCallBalance);
    }

    /// @notice     Adds a given amount to the withdraw allowance for the address.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function enableWithdrawal(DepositUtils.Deposit storage _d, address _withdrawer, uint256 _amount) internal {
        _d.withdrawalAllowances[_withdrawer] = _d.withdrawalAllowances[_withdrawer].add(_amount);
    }

    /// @notice     Withdraw caller's allowance.
    /// @dev        Withdrawals can only happen when a contract is in an end-state.
    function withdrawFunds(DepositUtils.Deposit storage _d) internal {
        uint256 available = _d.withdrawalAllowances[msg.sender];

        require(_d.inEndState(), "Contract not yet terminated");
        require(available > 0, "Nothing to withdraw");
        require(address(this).balance >= available, "Insufficient contract balance");

        // zero-out to prevent reentrancy
        _d.withdrawalAllowances[msg.sender] = 0;

        /* solium-disable-next-line security/no-call-value */
        (bool ok,) = msg.sender.call.value(available)("");
        require(
            ok,
            "Failed to send withdrawal allowance to sender"
        );
    }

    /// @notice     Get the caller's withdraw allowance.
    /// @return     The caller's withdraw allowance in wei.
    function getWithdrawAllowance(DepositUtils.Deposit storage _d) internal view returns (uint256) {
        return _d.withdrawalAllowances[msg.sender];
    }

    /// @notice     Distributes the fee rebate to the Fee Rebate Token owner.
    /// @dev        Whenever this is called we are shutting down.
    function distributeFeeRebate(Deposit storage _d) internal {
        address rebateTokenHolder = feeRebateTokenHolder(_d);

        // exit the function if there is nobody to send the rebate to
        if(rebateTokenHolder == address(0)){
            return;
        }

        // pay out the rebate if it is available
        if(_d.tbtcToken.balanceOf(address(this)) >= signerFee(_d)) {
            _d.tbtcToken.transfer(rebateTokenHolder, signerFee(_d));
        }
    }

    /// @notice             Pushes ether held by the deposit to the signer group.
    /// @dev                Ether is returned to signing group members bonds.
    /// @param  _ethValue   The amount of ether to send.
    /// @return             True if successful, otherwise revert.
    function pushFundsToKeepGroup(Deposit storage _d, uint256 _ethValue) internal returns (bool) {
        require(address(this).balance >= _ethValue, "Not enough funds to send");
        IBondedECDSAKeep _keep = IBondedECDSAKeep(_d.keepAddress);
        _keep.returnPartialSignerBonds.value(_ethValue)();
        return true;
    }

    /// @notice             Get TBTC amount required for redemption assuming _redeemer
    ///                     is this deposit's TDT holder.
    /// @param _redeemer    The assumed owner of the deposit's TDT.
    /// @return             The amount in TBTC needed to redeem the deposit.
    function getOwnerRedemptionTbtcRequirement(DepositUtils.Deposit storage _d, address _redeemer) internal view returns(uint256) {
        uint256 fee = signerFee(_d);
        bool inCourtesy = _d.inCourtesyCall();
        if(remainingTerm(_d) > 0 && !inCourtesy){
            if(feeRebateTokenHolder(_d) != _redeemer) {
                return fee;
            }
        }
        uint256 contractTbtcBalance = _d.tbtcToken.balanceOf(address(this));
        if(contractTbtcBalance < fee) {
            return fee.sub(contractTbtcBalance);
        }
        return 0;
    }

    /// @notice             Get TBTC amount required by redemption by a specified _redeemer.
    /// @dev                Will revert if redemption is not possible by msg.sender.
    /// @param _redeemer    The deposit redeemer.
    /// @return             The amount in TBTC needed to redeem the deposit.
    function getRedemptionTbtcRequirement(DepositUtils.Deposit storage _d, address _redeemer) internal view returns(uint256) {
        bool inCourtesy = _d.inCourtesyCall();
        if (depositOwner(_d) == _redeemer && !inCourtesy) {
            return getOwnerRedemptionTbtcRequirement(_d, _redeemer);
        }
        require(remainingTerm(_d) == 0 || inCourtesy, "Only TDT holder can redeem unless deposit is at-term or in COURTESY_CALL");
        return lotSizeTbtc(_d);
    }
}
"
    },
    "solidity/contracts/deposit/DepositStates.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

import {DepositUtils} from "./DepositUtils.sol";

library DepositStates {

    enum States {
        // DOES NOT EXIST YET
        START,

        // FUNDING FLOW
        AWAITING_SIGNER_SETUP,
        AWAITING_BTC_FUNDING_PROOF,

        // FAILED SETUP
        FAILED_SETUP,

        // ACTIVE
        ACTIVE,  // includes courtesy call

        // REDEMPTION FLOW
        AWAITING_WITHDRAWAL_SIGNATURE,
        AWAITING_WITHDRAWAL_PROOF,
        REDEEMED,

        // SIGNER LIQUIDATION FLOW
        COURTESY_CALL,
        FRAUD_LIQUIDATION_IN_PROGRESS,
        LIQUIDATION_IN_PROGRESS,
        LIQUIDATED
    }

    /// @notice     Check if the contract is currently in the funding flow.
    /// @dev        This checks on the funding flow happy path, not the fraud path.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the funding flow else False.
    function inFunding(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (
            _d.currentState == uint8(States.AWAITING_SIGNER_SETUP)
         || _d.currentState == uint8(States.AWAITING_BTC_FUNDING_PROOF)
        );
    }

    /// @notice     Check if the contract is currently in the signer liquidation flow.
    /// @dev        This could be caused by fraud, or by an unfilled margin call.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the liquidaton flow else False.
    function inSignerLiquidation(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (
            _d.currentState == uint8(States.LIQUIDATION_IN_PROGRESS)
         || _d.currentState == uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS)
        );
    }

    /// @notice     Check if the contract is currently in the redepmtion flow.
    /// @dev        This checks on the redemption flow, not the REDEEMED termination state.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the redemption flow else False.
    function inRedemption(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (
            _d.currentState == uint8(States.AWAITING_WITHDRAWAL_SIGNATURE)
         || _d.currentState == uint8(States.AWAITING_WITHDRAWAL_PROOF)
        );
    }

    /// @notice     Check if the contract has halted.
    /// @dev        This checks on any halt state, regardless of triggering circumstances.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract has halted permanently.
    function inEndState(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (
            _d.currentState == uint8(States.LIQUIDATED)
         || _d.currentState == uint8(States.REDEEMED)
         || _d.currentState == uint8(States.FAILED_SETUP)
        );
    }

    /// @notice     Check if the contract is available for a redemption request.
    /// @dev        Redemption is available from active and courtesy call.
    /// @param _d   Deposit storage pointer.
    /// @return     True if available, False otherwise.
    function inRedeemableState(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (
            _d.currentState == uint8(States.ACTIVE)
         || _d.currentState == uint8(States.COURTESY_CALL)
        );
    }

    /// @notice     Check if the contract is currently in the start state (awaiting setup).
    /// @dev        This checks on the funding flow happy path, not the fraud path.
    /// @param _d   Deposit storage pointer.
    /// @return     True if contract is currently in the start state else False.
    function inStart(DepositUtils.Deposit storage _d) public view returns (bool) {
        return (_d.currentState == uint8(States.START));
    }

    function inAwaitingSignerSetup(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.AWAITING_SIGNER_SETUP);
    }

    function inAwaitingBTCFundingProof(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.AWAITING_BTC_FUNDING_PROOF);
    }

    function inFailedSetup(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.FAILED_SETUP);
    }

    function inActive(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.ACTIVE);
    }

    function inAwaitingWithdrawalSignature(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.AWAITING_WITHDRAWAL_SIGNATURE);
    }

    function inAwaitingWithdrawalProof(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.AWAITING_WITHDRAWAL_PROOF);
    }

    function inRedeemed(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.REDEEMED);
    }

    function inCourtesyCall(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.COURTESY_CALL);
    }

    function inFraudLiquidationInProgress(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS);
    }

    function inLiquidationInProgress(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.LIQUIDATION_IN_PROGRESS);
    }

    function inLiquidated(DepositUtils.Deposit storage _d) external view returns (bool) {
        return _d.currentState == uint8(States.LIQUIDATED);
    }

    function setAwaitingSignerSetup(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.AWAITING_SIGNER_SETUP);
    }

    function setAwaitingBTCFundingProof(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.AWAITING_BTC_FUNDING_PROOF);
    }

    function setFailedSetup(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.FAILED_SETUP);
    }

    function setActive(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.ACTIVE);
    }

    function setAwaitingWithdrawalSignature(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.AWAITING_WITHDRAWAL_SIGNATURE);
    }

    function setAwaitingWithdrawalProof(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.AWAITING_WITHDRAWAL_PROOF);
    }

    function setRedeemed(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.REDEEMED);
    }

    function setCourtesyCall(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.COURTESY_CALL);
    }

    function setFraudLiquidationInProgress(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.FRAUD_LIQUIDATION_IN_PROGRESS);
    }

    function setLiquidationInProgress(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.LIQUIDATION_IN_PROGRESS);
    }

    function setLiquidated(DepositUtils.Deposit storage _d) external {
        _d.currentState = uint8(States.LIQUIDATED);
    }
}
"
    },
    "solidity/contracts/system/TBTCSystem.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

/* solium-disable function-order */
pragma solidity 0.5.17;

import {IBondedECDSAKeepFactory} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol";

import {VendingMachine} from "./VendingMachine.sol";
import {DepositFactory} from "../proxy/DepositFactory.sol";

import {IRelay} from "@summa-tx/relay-sol/contracts/Relay.sol";
import "../external/IMedianizer.sol";

import {ITBTCSystem} from "../interfaces/ITBTCSystem.sol";
import {ISatWeiPriceFeed} from "../interfaces/ISatWeiPriceFeed.sol";
import {DepositLog} from "../DepositLog.sol";

import {TBTCDepositToken} from "./TBTCDepositToken.sol";
import "./TBTCToken.sol";
import "./FeeRebateToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./KeepFactorySelection.sol";

/// @title  TBTC System.
/// @notice This contract acts as a central point for access control,
///         value governance, and price feed.
/// @dev    Governable values should only affect new deposit creation.
contract TBTCSystem is Ownable, ITBTCSystem, DepositLog {

    using SafeMath for uint256;
    using KeepFactorySelection for KeepFactorySelection.Storage;

    event EthBtcPriceFeedAdditionStarted(address _priceFeed, uint256 _timestamp);
    event LotSizesUpdateStarted(uint64[] _lotSizes, uint256 _timestamp);
    event SignerFeeDivisorUpdateStarted(uint16 _signerFeeDivisor, uint256 _timestamp);
    event CollateralizationThresholdsUpdateStarted(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent,
        uint256 _timestamp
    );
    event KeepFactorySingleShotUpdateStarted(
        address _factorySelector,
        address _ethBackedFactory,
        uint256 _timestamp
    );


    event EthBtcPriceFeedAdded(address _priceFeed);
    event LotSizesUpdated(uint64[] _lotSizes);
    event AllowNewDepositsUpdated(bool _allowNewDeposits);
    event SignerFeeDivisorUpdated(uint16 _signerFeeDivisor);
    event CollateralizationThresholdsUpdated(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent
    );
    event KeepFactorySingleShotUpdated(
        address _factorySelector,
        address _ethBackedFactory
    );

    bool _initialized = false;
    uint256 pausedTimestamp;
    uint256 constant pausedDuration = 10 days;

    ISatWeiPriceFeed public priceFeed;
    IRelay public relay;

    KeepFactorySelection.Storage keepFactorySelection;

    // Parameters governed by the TBTCSystem owner
    bool private allowNewDeposits = false;
    uint16 private signerFeeDivisor = 2000; // 1/2000 == 5bps == 0.05% == 0.0005
    uint16 private initialCollateralizedPercent = 150; // percent
    uint16 private undercollateralizedThresholdPercent = 125;  // percent
    uint16 private severelyUndercollateralizedThresholdPercent = 110; // percent
    uint64[] lotSizesSatoshis = [10**5, 10**6, 10**7, 2 * 10**7, 5 * 10**7, 10**8]; // [0.001, 0.01, 0.1, 0.2, 0.5, 1.0] BTC

    uint256 constant governanceTimeDelay = 48 hours;

    uint256 private signerFeeDivisorChangeInitiated;
    uint256 private lotSizesChangeInitiated;
    uint256 private collateralizationThresholdsChangeInitiated;
    uint256 private keepFactorySingleShotUpdateInitiated;

    uint16 private newSignerFeeDivisor;
    uint64[] newLotSizesSatoshis;
    uint16 private newInitialCollateralizedPercent;
    uint16 private newUndercollateralizedThresholdPercent;
    uint16 private newSeverelyUndercollateralizedThresholdPercent;
    address private newFactorySelector;
    address private newEthBackedFactory;

    // price feed
    uint256 priceFeedGovernanceTimeDelay = 90 days;
    uint256 ethBtcPriceFeedAdditionInitiated;
    IMedianizer nextEthBtcPriceFeed;

    constructor(address _priceFeed, address _relay) public {
        priceFeed = ISatWeiPriceFeed(_priceFeed);
        relay = IRelay(_relay);
    }

    /// @notice        Initialize contracts
    /// @dev           Only the Deposit factory should call this, and only once.
    /// @param _defaultKeepFactory       ECDSA keep factory backed by KEEP stake.
    /// @param _depositFactory    Deposit Factory. More info in `DepositFactory`.
    /// @param _masterDepositAddress  Master Deposit address. More info in `Deposit`.
    /// @param _tbtcToken         TBTCToken. More info in `TBTCToken`.
    /// @param _tbtcDepositToken  TBTCDepositToken (TDT). More info in `TBTCDepositToken`.
    /// @param _feeRebateToken    FeeRebateToken (FRT). More info in `FeeRebateToken`.
    /// @param _vendingMachine    Vending Machine. More info in `VendingMachine`.
    /// @param _keepThreshold     Signing group honesty threshold.
    /// @param _keepSize          Signing group size.
    function initialize(
        IBondedECDSAKeepFactory _defaultKeepFactory,
        DepositFactory _depositFactory,
        address payable _masterDepositAddress,
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        VendingMachine _vendingMachine,
        uint16 _keepThreshold,
        uint16 _keepSize
    ) external onlyOwner {
        require(!_initialized, "already initialized");

        keepFactorySelection.initialize(_defaultKeepFactory);

        _vendingMachine.setExternalAddresses(
            _tbtcToken,
            _tbtcDepositToken,
            _feeRebateToken
        );
        _depositFactory.setExternalDependencies(
            _masterDepositAddress,
            this,
            _tbtcToken,
            _tbtcDepositToken,
            _feeRebateToken,
            address(_vendingMachine),
            _keepThreshold,
            _keepSize
        );
        setTbtcDepositToken(_tbtcDepositToken);
        _initialized = true;
        allowNewDeposits = true;
    }

    /// @notice gets whether new deposits are allowed.
    function getAllowNewDeposits() external view returns (bool) { return allowNewDeposits; }

    /// @notice One-time-use emergency function to disallow future deposit creation for 10 days.
    function emergencyPauseNewDeposits() external onlyOwner returns (bool) {
        require(pausedTimestamp == 0, "emergencyPauseNewDeposits can only be called once");
        pausedTimestamp = block.timestamp;
        allowNewDeposits = false;
        emit AllowNewDepositsUpdated(false);
    }

    /// @notice Anyone can reactivate deposit creations after the pause duration is over.
    function resumeNewDeposits() public {
        require(allowNewDeposits == false, "New deposits are currently allowed");
        require(pausedTimestamp != 0, "Deposit has not been paused");
        require(block.timestamp.sub(pausedTimestamp) >= pausedDuration, "Deposits are still paused");
        allowNewDeposits = true;
        emit AllowNewDepositsUpdated(true);
    }

    function getRemainingPauseTerm() public view returns (uint256) {
        require(allowNewDeposits == false, "New deposits are currently allowed");
        return (block.timestamp.sub(pausedTimestamp) >= pausedDuration)?
            0:
            pausedDuration.sub(block.timestamp.sub(pausedTimestamp));
    }

    /// @notice Set the system signer fee divisor.
    /// @dev    This can be finalized by calling `finalizeSignerFeeDivisorUpdate`
    ///         Anytime after `governanceTimeDelay` has elapsed.
    /// @param _signerFeeDivisor The signer fee divisor.
    function beginSignerFeeDivisorUpdate(uint16 _signerFeeDivisor)
        external onlyOwner
    {
        require(
            _signerFeeDivisor > 9,
            "Signer fee divisor must be greater than 9, for a signer fee that is <= 10%"
        );
        require(
            _signerFeeDivisor < 5000,
            "Signer fee divisor must be less than 5000, for a signer fee that is > 0.02%"
        );

        newSignerFeeDivisor = _signerFeeDivisor;
        signerFeeDivisorChangeInitiated = block.timestamp;
        emit SignerFeeDivisorUpdateStarted(_signerFeeDivisor, block.timestamp);
    }

    /// @notice Set the allowed deposit lot sizes.
    /// @dev    Lot size array should always contain 10**8 satoshis (1 BTC) and
    ///         cannot contain values less than 50000 satoshis (0.0005 BTC) or
    ///         greater than 10**9 satoshis (10 BTC).
    ///         This can be finalized by calling `finalizeLotSizesUpdate`
    ///         anytime after `governanceTimeDelay` has elapsed.
    /// @param _lotSizes Array of allowed lot sizes.
    function beginLotSizesUpdate(uint64[] calldata _lotSizes)
        external onlyOwner
    {
        bool hasSingleBitcoin = false;
        for (uint i = 0; i < _lotSizes.length; i++) {
            if (_lotSizes[i] == 10**8) {
                hasSingleBitcoin = true;
            } else if (_lotSizes[i] < 50 * 10**3) {
                // Failed the minimum requirement, break on out.
                revert("Lot sizes less than 0.0005 BTC are not allowed");
            } else if (_lotSizes[i] > 10 * 10**8) {
                // Failed the maximum requirement, break on out.
                revert("Lot sizes greater than 10 BTC are not allowed");
            }
        }

        require(hasSingleBitcoin, "Lot size array must always contain 1 BTC");

        lotSizesSatoshis = _lotSizes;
        emit LotSizesUpdateStarted(_lotSizes, block.timestamp);
        newLotSizesSatoshis = _lotSizes;
        lotSizesChangeInitiated = block.timestamp;
    }

    /// @notice Set the system collateralization levels
    /// @dev    This can be finalized by calling `finalizeCollateralizationThresholdsUpdate`
    ///         Anytime after `governanceTimeDelay` has elapsed.
    /// @param _initialCollateralizedPercent default signing bond percent for new deposits
    /// @param _undercollateralizedThresholdPercent first undercollateralization trigger
    /// @param _severelyUndercollateralizedThresholdPercent second undercollateralization trigger
    function beginCollateralizationThresholdsUpdate(
        uint16 _initialCollateralizedPercent,
        uint16 _undercollateralizedThresholdPercent,
        uint16 _severelyUndercollateralizedThresholdPercent
    ) external onlyOwner {
        require(
            _initialCollateralizedPercent <= 300,
            "Initial collateralized percent must be <= 300%"
        );
        require(
            _initialCollateralizedPercent > 100,
            "Initial collateralized percent must be >= 100%"
        );
        require(
            _initialCollateralizedPercent > _undercollateralizedThresholdPercent,
            "Undercollateralized threshold must be < initial collateralized percent"
        );
        require(
            _undercollateralizedThresholdPercent > _severelyUndercollateralizedThresholdPercent,
            "Severe undercollateralized threshold must be < undercollateralized threshold"
        );

        newInitialCollateralizedPercent = _initialCollateralizedPercent;
        newUndercollateralizedThresholdPercent = _undercollateralizedThresholdPercent;
        newSeverelyUndercollateralizedThresholdPercent = _severelyUndercollateralizedThresholdPercent;
        collateralizationThresholdsChangeInitiated = block.timestamp;
        emit CollateralizationThresholdsUpdateStarted(
            _initialCollateralizedPercent,
            _undercollateralizedThresholdPercent,
            _severelyUndercollateralizedThresholdPercent,
            block.timestamp
        );
    }

    /// @notice Sets the address of the ETH-only-backed ECDSA keep factory and
    ///         the selection strategy that will choose between it and the
    ///         default KEEP-backed factory for new deposits. When the
    ///         ETH-only-backed factory and strategy are set, TBTCSystem load
    ///         balances between two factories based on the selection strategy.
    /// @dev It can be finalized by calling `finalizeKeepFactorySingleShotUpdate`
    ///      any time after `governanceTimeDelay` has elapsed. This can be
    ///      called more than once until finalized to reset the values and
    ///      timer, but it can only be finalized once!
    /// @param _factorySelector Address of the keep factory selection strategy.
    /// @param _ethBackedFactory Address of the ETH-stake-based factory.
    function beginKeepFactorySingleShotUpdate(
        address _factorySelector,
        address _ethBackedFactory
    )
        external onlyOwner
    {
        require(
            // Either an update is in progress,
            keepFactorySingleShotUpdateInitiated != 0 ||
            // or we're trying to start a fresh one, in which case we must not
            // have an already-finalized one (indicated by newEthBackedFactory
            // being set).
            newEthBackedFactory == address(0),
            "Keep factory data can only be updated once"
        );
        require(
            _factorySelector != address(0),
            "Factory selector must be a nonzero address"
        );
        require(
            _ethBackedFactory != address(0),
            "ETH-backed factory must be a nonzero address"
        );

        newFactorySelector = _factorySelector;
        newEthBackedFactory = _ethBackedFactory;
        keepFactorySingleShotUpdateInitiated = block.timestamp;
        emit KeepFactorySingleShotUpdateStarted(
            _factorySelector,
            _ethBackedFactory,
            block.timestamp
        );
    }

    /// @notice Add a new ETH/BTC price feed contract to the priecFeed.
    /// @dev This can be finalized by calling `finalizeEthBtcPriceFeedAddition`
    ///      anytime after `priceFeedGovernanceTimeDelay` has elapsed.
    function beginEthBtcPriceFeedAddition(IMedianizer _ethBtcPriceFeed) external onlyOwner {
        bool ethBtcActive;
        (, ethBtcActive) = _ethBtcPriceFeed.peek();
        require(ethBtcActive, "Cannot add inactive feed");

        nextEthBtcPriceFeed = _ethBtcPriceFeed;
        ethBtcPriceFeedAdditionInitiated = block.timestamp;
        emit EthBtcPriceFeedAdditionStarted(address(_ethBtcPriceFeed), block.timestamp);
    }

    modifier onlyAfterGovernanceDelay(
        uint256 _changeInitializedTimestamp,
        uint256 _delay
    ) {
        require(_changeInitializedTimestamp > 0, "Change not initiated");
        require(
            block.timestamp.sub(_changeInitializedTimestamp) >= _delay,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Finish setting the system signer fee divisor.
    /// @dev `beginSignerFeeDivisorUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the signer fee divisor to the
    ///       value set in `beginSignerFeeDivisorUpdate`
    function finalizeSignerFeeDivisorUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(signerFeeDivisorChangeInitiated, governanceTimeDelay)
    {
        signerFeeDivisor = newSignerFeeDivisor;
        emit SignerFeeDivisorUpdated(newSignerFeeDivisor);
        newSignerFeeDivisor = 0;
        signerFeeDivisorChangeInitiated = 0;
    }
    /// @notice Finish setting the accepted system lot sizes.
    /// @dev `beginLotSizesUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the lot sizes to the
    ///       value set in `beginLotSizesUpdate`
    function finalizeLotSizesUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(lotSizesChangeInitiated, governanceTimeDelay) {

        lotSizesSatoshis = newLotSizesSatoshis;
        emit LotSizesUpdated(newLotSizesSatoshis);
        lotSizesChangeInitiated = 0;
        newLotSizesSatoshis.length = 0;
    }

    /// @notice Finish setting the system collateralization levels
    /// @dev `beginCollateralizationThresholdsUpdate` must be called first, once `governanceTimeDelay`
    ///       has passed, this function can be called to set the collateralization thresholds to the
    ///       value set in `beginCollateralizationThresholdsUpdate`
    function finalizeCollateralizationThresholdsUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            collateralizationThresholdsChangeInitiated,
            governanceTimeDelay
        ) {

        initialCollateralizedPercent = newInitialCollateralizedPercent;
        undercollateralizedThresholdPercent = newUndercollateralizedThresholdPercent;
        severelyUndercollateralizedThresholdPercent = newSeverelyUndercollateralizedThresholdPercent;

        emit CollateralizationThresholdsUpdated(
            newInitialCollateralizedPercent,
            newUndercollateralizedThresholdPercent,
            newSeverelyUndercollateralizedThresholdPercent
        );

        newInitialCollateralizedPercent = 0;
        newUndercollateralizedThresholdPercent = 0;
        newSeverelyUndercollateralizedThresholdPercent = 0;
        collateralizationThresholdsChangeInitiated = 0;
    }

    /// @notice Finish setting the address of the ETH-only-backed ECDSA keep
    ///         factory and the selection strategy that will choose between it
    ///         and the default KEEP-backed factory for new deposits.
    /// @dev `beginKeepFactorySingleShotUpdate` must be called first; once
    ///      `governanceTimeDelay` has passed, this function can be called to
    ///      set the collateralization thresholds to the value set in
    ///      `beginKeepFactorySingleShotUpdate`.
    function finalizeKeepFactorySingleShotUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            keepFactorySingleShotUpdateInitiated,
            governanceTimeDelay
        ) {

        keepFactorySelection.setKeepFactorySelector(newFactorySelector);
        keepFactorySelection.setFullyBackedKeepFactory(newEthBackedFactory);

        emit KeepFactorySingleShotUpdated(
            newFactorySelector,
            newEthBackedFactory
        );

        keepFactorySingleShotUpdateInitiated = 0;
        newFactorySelector = address(0);
        // Keep newEthBackedFactory set as a marker that the update has already
        // occurred.
    }

    /// @notice Finish adding a new price feed contract to the priceFeed.
    /// @dev `beginEthBtcPriceFeedAddition` must be called first; once
    ///      `ethBtcPriceFeedAdditionInitiated` has passed, this function can be
    ///      called to append a new price feed.
    function finalizeEthBtcPriceFeedAddition()
            external
            onlyOwner
            onlyAfterGovernanceDelay(
                ethBtcPriceFeedAdditionInitiated,
                priceFeedGovernanceTimeDelay
            ) {
        // This process interacts with external contracts, so
        // Checks-Effects-Interactions it.
        IMedianizer _nextEthBtcPriceFeed = nextEthBtcPriceFeed;
        nextEthBtcPriceFeed = IMedianizer(0);
        ethBtcPriceFeedAdditionInitiated = 0;

        priceFeed.addEthBtcFeed(_nextEthBtcPriceFeed);

        emit EthBtcPriceFeedAdded(address(_nextEthBtcPriceFeed));
    }

    /// @notice Gets the system signer fee divisor.
    /// @return The signer fee divisor.
    function getSignerFeeDivisor() external view returns (uint16) { return signerFeeDivisor; }

    /// @notice Gets the allowed lot sizes
    /// @return Uint64 array of allowed lot sizes
    function getAllowedLotSizes() external view returns (uint64[] memory){
        return lotSizesSatoshis;
    }

    /// @notice Check if a lot size is allowed.
    /// @param _lotSizeSatoshis Lot size to check.
    /// @return True if lot size is allowed, false otherwise.
    function isAllowedLotSize(uint64 _lotSizeSatoshis) external view returns (bool){
        for( uint i = 0; i < lotSizesSatoshis.length; i++){
            if (lotSizesSatoshis[i] == _lotSizeSatoshis){
                return true;
            }
        }
        return false;
    }

    /// @notice Get the system undercollateralization level for new deposits
    function getUndercollateralizedThresholdPercent() external view returns (uint16) {
        return undercollateralizedThresholdPercent;
    }

    /// @notice Get the system severe undercollateralization level for new deposits
    function getSeverelyUndercollateralizedThresholdPercent() external view returns (uint16) {
        return severelyUndercollateralizedThresholdPercent;
    }

    /// @notice Get the system initial collateralized level for new deposits.
    function getInitialCollateralizedPercent() external view returns (uint16) {
        return initialCollateralizedPercent;
    }

    /// @notice Get the price of one satoshi in wei.
    /// @dev Reverts if the price of one satoshi is 0 wei, or if the price of
    ///      one satoshi is 1 ether. Can only be called by a deposit with minted
    ///      TDT.
    /// @return The price of one satoshi in wei.
    function fetchBitcoinPrice() external view returns (uint256) {
        require(
            tbtcDepositToken.exists(uint256(msg.sender)),
            "Caller must be a Deposit contract"
        );

        uint256 price = priceFeed.getPrice();
        if (price == 0 || price > 10 ** 18) {
            // This is if a sat is worth 0 wei, or is worth >1 ether. Revert at
            // once.
            revert("System returned a bad price");
        }
        return price;
    }

    // Difficulty Oracle
    function fetchRelayCurrentDifficulty() external view returns (uint256) {
        return relay.getCurrentEpochDifficulty();
    }

    function fetchRelayPreviousDifficulty() external view returns (uint256) {
        return relay.getPrevEpochDifficulty();
    }

    /// @notice Get the time remaining until the signer fee divisor can be updated.
    function getRemainingSignerFeeDivisorUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            signerFeeDivisorChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the lot sizes can be updated.
    function getRemainingLotSizesUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            lotSizesChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the collateralization thresholds can be updated.
    function getRemainingCollateralizationThresholdsUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            collateralizationThresholdsChangeInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the Keep ETH-only-backed ECDSA keep
    ///         factory and the selection strategy that will choose between it
    ///         and the KEEP-backed factory can be updated.
    function getRemainingKeepFactorySingleShotUpdateTime() external view returns (uint256) {
        return getRemainingChangeTime(
            keepFactorySingleShotUpdateInitiated,
            governanceTimeDelay
        );
    }

    /// @notice Get the time remaining until the signer fee divisor can be updated.
    function getRemainingEthBtcPriceFeedAdditionTime() external view returns (uint256) {
        return getRemainingChangeTime(
            ethBtcPriceFeedAdditionInitiated,
            priceFeedGovernanceTimeDelay
        );
    }

    /// @notice Returns the time delay used for governance actions except for
    ///         price feed additions.
    function getGovernanceTimeDelay() public pure returns (uint256) {
        return governanceTimeDelay;
    }

    /// @notice Returns the time delay used for price feed addition governance
    ///         actions.
    function getPriceFeedGovernanceTimeDelay() public view returns (uint256) {
        return priceFeedGovernanceTimeDelay;
    }

    /// @notice Gets a fee estimate for creating a new Deposit.
    /// @return Uint256 estimate.
    function getNewDepositFeeEstimate()
        external
        view
        returns (uint256)
    {
        IBondedECDSAKeepFactory _keepFactory = keepFactorySelection.selectFactory();
        return _keepFactory.openKeepFeeEstimate();
    }

    /// @notice Request a new keep opening.
    /// @param _m Minimum number of honest keep members required to sign.
    /// @param _n Number of members in the keep.
    /// @param _maxSecuredLifetime Duration of stake lock in seconds.
    /// @return Address of a new keep.
    function requestNewKeep(
        uint256 _m,
        uint256 _n,
        uint256 _bond,
        uint256 _maxSecuredLifetime
    )
        external
        payable
        returns (address)
    {
        require(tbtcDepositToken.exists(uint256(msg.sender)), "Caller must be a Deposit contract");
        IBondedECDSAKeepFactory _keepFactory = keepFactorySelection.selectFactoryAndRefresh();
        return _keepFactory.openKeep.value(msg.value)(_n, _m, msg.sender, _bond, _maxSecuredLifetime);
    }

    /// @notice Get the time remaining until the function parameter timer value can be updated.
    function getRemainingChangeTime(
        uint256 _changeTimestamp,
        uint256 _delayAmount
    ) internal view returns (uint256){
        require(_changeTimestamp > 0, "Update not initiated");
        uint256 elapsed = block.timestamp.sub(_changeTimestamp);
        if (elapsed >= _delayAmount) {
            return 0;
        } else {
            return _delayAmount.sub(elapsed);
        }
    }
}
"
    },
    "solidity/contracts/interfaces/ITBTCSystem.sol": {
      "content": "/*
 Authored by Satoshi Nakamoto ?
*/

pragma solidity 0.5.17;

/**
 * @title Keep interface
 */

interface ITBTCSystem {

    // expected behavior:
    // return the price of 1 sat in wei
    // these are the native units of the deposit contract
    function fetchBitcoinPrice() external view returns (uint256);

    // passthrough requests for the oracle
    function fetchRelayCurrentDifficulty() external view returns (uint256);
    function fetchRelayPreviousDifficulty() external view returns (uint256);
    function getNewDepositFeeEstimate() external view returns (uint256);
    function getAllowNewDeposits() external view returns (bool);
    function isAllowedLotSize(uint64 _lotSizeSatoshis) external view returns (bool);
    function requestNewKeep(uint256 _m, uint256 _n, uint256 _bond, uint256 _maxSecuredLifetime) external payable returns (address);
    function getSignerFeeDivisor() external view returns (uint16);
    function getInitialCollateralizedPercent() external view returns (uint16);
    function getUndercollateralizedThresholdPercent() external view returns (uint16);
    function getSeverelyUndercollateralizedThresholdPercent() external view returns (uint16);
}
"
    },
    "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol": {
      "content": "/**
âââ ââ âââ ââââââââââââââââââââââââââââââ ââââââââââââââââââ ââââââââââââââââââ
ââââââââââ ââââââââââââââââââââââââââââââ ââââââââââââââââââ âââââââââââââââââââ
  ââââââ    ââââââââ    âââââââ    ââââââ   ââââââ     âââââ   âââââââ   âââââââ
  ââââââââââââââââ      âââââââââââ         ââââââââââ         âââââââ   âââââââ
  ââââââââââââââ        âââââââââââ         âââââââââââ        âââââââââââââââââ
  âââââââââââââââ       âââââââââââ         ââââââââââ         ââââââââââââââââ
  ââââââ   ââââââââ     âââââââ     âââââ   ââââââ     âââââ   âââââââ
ââââââââââ ââââââââââ âââââââââââââââââââ ââââââââââââââââââ  ââââââââââ
ââââââââââ ââââââââââ âââââââââââââââââââ ââââââââââââââââââ  ââââââââââ

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;


/// @title Bonded ECDSA Keep Factory
/// @notice Factory for Bonded ECDSA Keeps.
interface IBondedECDSAKeepFactory {
    /// @notice Open a new ECDSA Keep.
    /// @param _groupSize Number of members in the keep.
    /// @param _honestThreshold Minimum number of honest keep members.
    /// @param _owner Address of the keep owner.
    /// @param _bond Value of ETH bond required from the keep.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    /// @return Address of the opened keep.
    function openKeep(
        uint256 _groupSize,
        uint256 _honestThreshold,
        address _owner,
        uint256 _bond,
        uint256 _stakeLockDuration
    ) external payable returns (address keepAddress);

    /// @notice Gets a fee estimate for opening a new keep.
    /// @return Uint256 estimate.
    function openKeepFeeEstimate() external view returns (uint256);

    /// @notice Gets the total weight of operators
    /// in the sortition pool for the given application.
    /// @param _application Address of the application.
    /// @return The sum of all registered operators' weights in the pool.
    /// Reverts if sortition pool for the application does not exist.
    function getSortitionPoolWeight(
        address _application
    ) external view returns (uint256);
}
"
    },
    "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol": {
      "content": "/**
âââ ââ âââ ââââââââââââââââââââââââââââââ ââââââââââââââââââ ââââââââââââââââââ
ââââââââââ ââââââââââââââââââââââââââââââ ââââââââââââââââââ âââââââââââââââââââ
  ââââââ    ââââââââ    âââââââ    ââââââ   ââââââ     âââââ   âââââââ   âââââââ
  ââââââââââââââââ      âââââââââââ         ââââââââââ         âââââââ   âââââââ
  ââââââââââââââ        âââââââââââ         âââââââââââ        âââââââââââââââââ
  âââââââââââââââ       âââââââââââ         ââââââââââ         ââââââââââââââââ
  ââââââ   ââââââââ     âââââââ     âââââ   ââââââ     âââââ   âââââââ
ââââââââââ ââââââââââ âââââââââââââââââââ ââââââââââââââââââ  ââââââââââ
ââââââââââ ââââââââââ âââââââââââââââââââ ââââââââââââââââââ  ââââââââââ

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;


/// @title ECDSA Keep
/// @notice Contract reflecting an ECDSA keep.
contract IBondedECDSAKeep {
    /// @notice Returns public key of this keep.
    /// @return Keeps's public key.
    function getPublicKey() external view returns (bytes memory);

    /// @notice Returns the amount of the keep's ETH bond in wei.
    /// @return The amount of the keep's ETH bond in wei.
    function checkBondAmount() external view returns (uint256);

    /// @notice Calculates a signature over provided digest by the keep. Note that
    /// signatures from the keep not explicitly requested by calling `sign`
    /// will be provable as fraud via `submitSignatureFraud`.
    /// @param _digest Digest to be signed.
    function sign(bytes32 _digest) external;

    /// @notice Distributes ETH reward evenly across keep signer beneficiaries.
    /// @dev Only the value passed to this function is distributed.
    function distributeETHReward() external payable;

    /// @notice Distributes ERC20 reward evenly across keep signer beneficiaries.
    /// @dev This works with any ERC20 token that implements a transferFrom
    /// function.
    /// This function only has authority over pre-approved
    /// token amount. We don't explicitly check for allowance, SafeMath
    /// subtraction overflow is enough protection.
    /// @param _tokenAddress Address of the ERC20 token to distribute.
    /// @param _value Amount of ERC20 token to distribute.
    function distributeERC20Reward(address _tokenAddress, uint256 _value)
        external;

    /// @notice Seizes the signers' ETH bonds. After seizing bonds keep is
    /// terminated so it will no longer respond to signing requests. Bonds can
    /// be seized only when there is no signing in progress or requested signing
    /// process has timed out. This function seizes all of signers' bonds.
    /// The application may decide to return part of bonds later after they are
    /// processed using returnPartialSignerBonds function.
    function seizeSignerBonds() external;

    /// @notice Returns partial signer's ETH bonds to the pool as an unbounded
    /// value. This function is called after bonds have been seized and processed
    /// by the privileged application after calling seizeSignerBonds function.
    /// It is entirely up to the application if a part of signers' bonds is
    /// returned. The application may decide for that but may also decide to
    /// seize bonds and do not return anything.
    function returnPartialSignerBonds() external payable;

    /// @notice Submits a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign.
    /// @dev The function expects the signed digest to be calculated as a sha256
    /// hash of the preimage: `sha256(_preimage)`.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, error otherwise.
    function submitSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes calldata _preimage
    )
        external returns (bool _isFraud);

    /// @notice Closes keep when no longer needed. Releases bonds to the keep
    /// members. Keep can be closed only when there is no signing in progress or
    /// requested signing process has timed out.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() external;
}
"
    },
    "solidity/contracts/system/VendingMachine.sol": {
      "content": "pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {TBTCDepositToken} from "./TBTCDepositToken.sol";
import {FeeRebateToken} from "./FeeRebateToken.sol";
import {TBTCToken} from "./TBTCToken.sol";
import {TBTCConstants} from "./TBTCConstants.sol";
import "../deposit/Deposit.sol";
import "./TBTCSystemAuthority.sol";

/// @title  Vending Machine
/// @notice The Vending Machine swaps TDTs (`TBTCDepositToken`)
///         to TBTC (`TBTCToken`) and vice versa.
/// @dev    The Vending Machine should have exclusive TBTC and FRT (`FeeRebateToken`) minting
///         privileges.
contract VendingMachine is TBTCSystemAuthority{
    using SafeMath for uint256;

    TBTCToken tbtcToken;
    TBTCDepositToken tbtcDepositToken;
    FeeRebateToken feeRebateToken;

    constructor(address _systemAddress)
        TBTCSystemAuthority(_systemAddress)
    public {}

    /// @notice Set external contracts needed by the Vending Machine.
    /// @dev    Addresses are used to update the local contract instance.
    /// @param _tbtcToken        TBTCToken contract. More info in `TBTCToken`.
    /// @param _tbtcDepositToken TBTCDepositToken (TDT) contract. More info in `TBTCDepositToken`.
    /// @param _feeRebateToken   FeeRebateToken (FRT) contract. More info in `FeeRebateToken`.
    function setExternalAddresses(
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken
    ) public onlyTbtcSystem {
        tbtcToken = _tbtcToken;
        tbtcDepositToken = _tbtcDepositToken;
        feeRebateToken = _feeRebateToken;
    }

    /// @notice Determines whether a deposit is qualified for minting TBTC.
    /// @param _depositAddress The address of the deposit
    function isQualified(address payable _depositAddress) public view returns (bool) {
        return Deposit(_depositAddress).inActive();
    }

    /// @notice Burns TBTC and transfers the tBTC Deposit Token to the caller
    ///         as long as it is qualified.
    /// @dev    We burn the lotSize of the Deposit in order to maintain
    ///         the TBTC supply peg in the Vending Machine. VendingMachine must be approved
    ///         by the caller to burn the required amount.
    /// @param _tdtId ID of tBTC Deposit Token to buy.
    function tbtcToTdt(uint256 _tdtId) public {
        require(tbtcDepositToken.exists(_tdtId), "tBTC Deposit Token does not exist");
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        uint256 depositValue = Deposit(address(uint160(_tdtId))).lotSizeTbtc();
        require(tbtcToken.balanceOf(msg.sender) >= depositValue, "Not enough TBTC for TDT exchange");
        tbtcToken.burnFrom(msg.sender, depositValue);

        // TODO do we need the owner check below? transferFrom can be approved for a user, which might be an interesting use case.
        require(tbtcDepositToken.ownerOf(_tdtId) == address(this), "Deposit is locked");
        tbtcDepositToken.transferFrom(address(this), msg.sender, _tdtId);
    }

    /// @notice Transfer the tBTC Deposit Token and mint TBTC.
    /// @dev    Transfers TDT from caller to vending machine, and mints TBTC to caller.
    ///         Vending Machine must be approved to transfer TDT by the caller.
    /// @param _tdtId ID of tBTC Deposit Token to sell.
    function tdtToTbtc(uint256 _tdtId) public {
        require(tbtcDepositToken.exists(_tdtId), "tBTC Deposit Token does not exist");
        require(isQualified(address(_tdtId)), "Deposit must be qualified");

        tbtcDepositToken.transferFrom(msg.sender, address(this), _tdtId);

        // If the backing Deposit does not have a signer fee in escrow, mint it.
        Deposit deposit = Deposit(address(uint160(_tdtId)));
        uint256 signerFee = deposit.signerFee();
        uint256 depositValue = deposit.lotSizeTbtc();

        if(tbtcToken.balanceOf(address(_tdtId)) < signerFee) {
            tbtcToken.mint(msg.sender, depositValue.sub(signerFee));
            tbtcToken.mint(address(_tdtId), signerFee);
        }
        else{
            tbtcToken.mint(msg.sender, depositValue);
        }

        // owner of the TDT during first TBTC mint receives the FRT
        if(!feeRebateToken.exists(_tdtId)){
            feeRebateToken.mint(msg.sender, _tdtId);
        }
    }

    // WRAPPERS

    /// @notice Qualifies a deposit and mints TBTC.
    /// @dev User must allow VendingManchine to transfer TDT.
    function unqualifiedDepositToTbtc(
        address payable _depositAddress,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public {
        Deposit _d = Deposit(_depositAddress);
        require(
            _d.provideBTCFundingProof(
                _txVersion,
                _txInputVector,
                _txOutputVector,
                _txLocktime,
                _fundingOutputIndex,
                _merkleProof,
                _txIndexInBlock,
                _bitcoinHeaders
            ),
            "failed to provide funding proof");

        tdtToTbtc(uint256(_depositAddress));
    }

    /// @notice Redeems a Deposit by purchasing a TDT with TBTC for _finalRecipient,
    ///         and using the TDT to redeem corresponding Deposit as _finalRecipient.
    ///         This function will revert if the Deposit is not in ACTIVE state.
    /// @dev Vending Machine transfers TBTC allowance to Deposit.
    /// @param  _depositAddress     The address of the Deposit to redeem.
    /// @param  _outputValueBytes   The 8-byte Bitcoin transaction output size in Little Endian.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _finalRecipient     The deposit redeemer. This address will receive the TDT.
    function tbtcToBtc(
        address payable _depositAddress,
        bytes8 _outputValueBytes,
        bytes memory _redeemerOutputScript,
        address payable _finalRecipient
    ) public {
        require(tbtcDepositToken.exists(uint256(_depositAddress)), "tBTC Deposit Token does not exist");
        Deposit _d = Deposit(_depositAddress);

        tbtcToken.burnFrom(msg.sender, _d.lotSizeTbtc());
        tbtcDepositToken.approve(_depositAddress, uint256(_depositAddress));

        uint256 tbtcOwed = _d.getOwnerRedemptionTbtcRequirement(msg.sender);

        if(tbtcOwed != 0){
            tbtcToken.transferFrom(msg.sender, address(this), tbtcOwed);
            tbtcToken.approve(_depositAddress, tbtcOwed);
        }

        _d.transferAndRequestRedemption(_outputValueBytes, _redeemerOutputScript, _finalRecipient);
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
    "solidity/contracts/system/TBTCDepositToken.sol": {
      "content": "pragma solidity 0.5.17;

import {ERC721Metadata} from "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import {DepositFactoryAuthority} from "./DepositFactoryAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title tBTC Deposit Token for tracking deposit ownership
/// @notice The tBTC Deposit Token, commonly referenced as the TDT, is an
///         ERC721 non-fungible token whose ownership reflects the ownership
///         of its corresponding deposit. Each deposit has one TDT, and vice
///         versa. Owning a TDT is equivalent to owning its corresponding
///         deposit. TDTs can be transferred freely. tBTC's VendingMachine
///         contract takes ownership of TDTs and in exchange returns fungible
///         TBTC tokens whose value is backed 1-to-1 by the corresponding
///         deposit's BTC.
/// @dev Currently, TDTs are minted using the uint256 casting of the
///      corresponding deposit contract's address. That is, the TDT's id is
///      convertible to the deposit's address and vice versa. TDTs are minted
///      automatically by the factory during each deposit's initialization. See
///      DepositFactory.createNewDeposit() for more info on how the TDT is minted.
contract TBTCDepositToken is ERC721Metadata, DepositFactoryAuthority {

    constructor(address _depositFactoryAddress)
        ERC721Metadata("tBTC Deposit Token", "TDT")
    public {
        initialize(_depositFactoryAddress);
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token
    /// @param _tokenId uint256 ID of the token to be minted
    function mint(address _to, uint256 _tokenId) public onlyFactory {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /// @notice           Allow another address to spend on the caller's behalf.
    ///                   Set allowance for other address and notify.
    ///                   Allows `_spender` to transfer the specified TDT
    ///                   on your behalf and then ping the contract about it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface below to receive approval notifications.
    /// @param _spender   `ITokenRecipient`-conforming contract authorized to
    ///        operate on the approved token.
    /// @param _tdtId     The TDT they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(ITokenRecipient _spender, uint256 _tdtId, bytes memory _extraData) public returns (bool) {
        approve(address(_spender), _tdtId);
        _spender.receiveApproval(msg.sender, _tdtId, address(this), _extraData);
        return true;
    }
}
"
    },
    "solidity/contracts/proxy/DepositFactory.sol": {
      "content": "pragma solidity 0.5.17;

import "./CloneFactory.sol";
import "../deposit/Deposit.sol";
import "../system/TBTCSystem.sol";
import "../system/TBTCToken.sol";
import "../system/FeeRebateToken.sol";
import "../system/TBTCSystemAuthority.sol";
import {TBTCDepositToken} from "../system/TBTCDepositToken.sol";


/// @title Deposit Factory
/// @notice Factory for the creation of new deposit clones.
/// @dev We avoid redeployment of deposit contract by using the clone factory.
/// Proxy delegates calls to Deposit and therefore does not affect deposit state.
/// This means that we only need to deploy the deposit contracts once.
/// The factory provides clean state for every new deposit clone.
contract DepositFactory is CloneFactory, TBTCSystemAuthority{

    // Holds the address of the deposit contract
    // which will be used as a master contract for cloning.
    address payable public masterDepositAddress;
    TBTCDepositToken tbtcDepositToken;
    TBTCSystem public tbtcSystem;
    TBTCToken public tbtcToken;
    FeeRebateToken public feeRebateToken;
    address public vendingMachineAddress;
    uint16 public keepThreshold;
    uint16 public keepSize;

    constructor(address _systemAddress)
        TBTCSystemAuthority(_systemAddress)
    public {}

    /// @dev                          Set the required external variables.
    /// @param _masterDepositAddress  The address of the master deposit contract.
    /// @param _tbtcSystem            Tbtc system contract.
    /// @param _tbtcToken             TBTC token contract.
    /// @param _tbtcDepositToken      TBTC Deposit Token contract.
    /// @param _feeRebateToken        AFee Rebate Token contract.
    /// @param _vendingMachineAddress Address of the Vending Machine contract.
    /// @param _keepThreshold         Minimum number of honest keep members.
    /// @param _keepSize              Number of all members in a keep.
    function setExternalDependencies(
        address payable _masterDepositAddress,
        TBTCSystem _tbtcSystem,
        TBTCToken _tbtcToken,
        TBTCDepositToken _tbtcDepositToken,
        FeeRebateToken _feeRebateToken,
        address _vendingMachineAddress,
        uint16 _keepThreshold,
        uint16 _keepSize
    ) public onlyTbtcSystem {
        masterDepositAddress = _masterDepositAddress;
        tbtcDepositToken = _tbtcDepositToken;
        tbtcSystem = _tbtcSystem;
        tbtcToken = _tbtcToken;
        feeRebateToken = _feeRebateToken;
        vendingMachineAddress = _vendingMachineAddress;
        keepThreshold = _keepThreshold;
        keepSize = _keepSize;
    }

    event DepositCloneCreated(address depositCloneAddress);

    /// @notice                Creates a new deposit instance and mints a TDT.
    ///                        This function is currently the only way to create a new deposit.
    /// @dev                   Calls `Deposit.createNewDeposit` to initialize the instance.
    ///                        Mints the TDT to the function caller.
    //                         (See `TBTCDepositToken` for more info on TDTs).
    /// @return                True if successful, otherwise revert.
    function createDeposit (uint64 _lotSizeSatoshis) public payable returns(address) {
        address cloneAddress = createClone(masterDepositAddress);

        TBTCDepositToken(tbtcDepositToken).mint(msg.sender, uint256(cloneAddress));

        Deposit deposit = Deposit(address(uint160(cloneAddress)));
        deposit.initialize(address(this));
        deposit.createNewDeposit.value(msg.value)(
                tbtcSystem,
                tbtcToken,
                tbtcDepositToken,
                feeRebateToken,
                vendingMachineAddress,
                keepThreshold,
                keepSize,
                _lotSizeSatoshis
            );

        emit DepositCloneCreated(cloneAddress);

        return cloneAddress;
    }
}
"
    },
    "solidity/contracts/proxy/CloneFactory.sol": {
      "content": "pragma solidity 0.5.17;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length

// Implementation of [EIP-1167] based on [clone-factory]
// source code.
//
// EIP 1167: https://eips.ethereum.org/EIPS/eip-1167
// clone-factory: https://github.com/optionality/clone-factory
// Modified to use ^0.5.10; instead of ^0.4.23 solidity version
/* solium-disable */

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}
"
    },
    "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol": {
      "content": "pragma solidity ^0.5.10;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";

library BTCUtils {
    using BytesLib for bytes;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    uint256 public constant ERR_BAD_ARG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /* ***** */
    /* UTILS */
    /* ***** */

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _flag    The first byte of a VarInt
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLength(bytes memory _flag) internal pure returns (uint8) {
        if (uint8(_flag[0]) == 0xff) {
            return 8;  // one-byte flag, 8 bytes data
        }
        if (uint8(_flag[0]) == 0xfe) {
            return 4;  // one-byte flag, 4 bytes data
        }
        if (uint8(_flag[0]) == 0xfd) {
            return 2;  // one-byte flag, 2 bytes data
        }

        return 0;  // flag is data
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string starting with a VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarInt(bytes memory _b) internal pure returns (uint256, uint256) {
      uint8 _dataLen = determineVarIntDataLength(_b);

      if (_dataLen == 0) {
        return (0, uint8(_b[0]));
      }
      if (_b.length < 1 + _dataLen) {
          return (ERR_BAD_ARG, 0);
      }
      uint256 _number = bytesToUint(reverseEndianness(_b.slice(1, _dataLen)));
      return (_dataLen, _number);
    }

    /// @notice          Changes the endianness of a byte array
    /// @dev             Returns a new, backwards, bytes
    /// @param _b        The bytes to reverse
    /// @return          The reversed bytes
    function reverseEndianness(bytes memory _b) internal pure returns (bytes memory) {
        bytes memory _newValue = new bytes(_b.length);

        for (uint i = 0; i < _b.length; i++) {
            _newValue[_b.length - i - 1] = _b[i];
        }

        return _newValue;
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return          The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// @notice          Converts big-endian bytes to a uint
    /// @dev             Traverses the byte array and sums the bytes
    /// @param _b        The big-endian bytes-encoded integer
    /// @return          The integer representation
    function bytesToUint(bytes memory _b) internal pure returns (uint256) {
        uint256 _number;

        for (uint i = 0; i < _b.length; i++) {
            _number = _number + uint8(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }

        return _number;
    }

    /// @notice          Get the last _num bytes from a byte array
    /// @param _b        The byte array to slice
    /// @param _num      The number of bytes to extract from the end
    /// @return          The last _num bytes of _b
    function lastBytes(bytes memory _b, uint256 _num) internal pure returns (bytes memory) {
        uint256 _start = _b.length.sub(_num);

        return _b.slice(_start, _num);
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash160(bytes memory _b) internal pure returns (bytes memory) {
        return abi.encodePacked(ripemd160(abi.encodePacked(sha256(_b))));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256(bytes memory _b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(_b)));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256View(bytes memory _b) internal view returns (bytes32 res) {
        assembly {
            let ptr := mload(0x40)
            pop(staticcall(gas, 2, add(_b, 32), mload(_b), ptr, 32))
            pop(staticcall(gas, 2, ptr, 32, ptr, 32))
            res := mload(ptr)
        }
    }

    /* ************ */
    /* Legacy Input */
    /* ************ */

    /// @notice          Extracts the nth input from the vin (0-indexed)
    /// @dev             Iterates over the vin. If you need to extract several, write a custom function
    /// @param _vin      The vin as a tightly-packed byte array
    /// @param _index    The 0-indexed location of the input to extract
    /// @return          The input as a byte array
    function extractInputAtIndex(bytes memory _vin, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index <= _nIns, "Vin read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vin.slice(_offset, _vin.length - _offset);
            _len = determineInputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
            _offset = _offset + _len;
        }

        _remaining = _vin.slice(_offset, _vin.length - _offset);
        _len = determineInputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _vin.slice(_offset, _len);
    }

    /// @notice          Determines whether an input is legacy
    /// @dev             False if no scriptSig, otherwise True
    /// @param _input    The input
    /// @return          True for legacy, False for witness
    function isLegacyInput(bytes memory _input) internal pure returns (bool) {
        return _input.keccak256Slice(36, 1) != keccak256(hex"00");
    }

    /// @notice          Determines the length of a scriptSig in an input
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The LEGACY input
    /// @return          The length of the script sig
    function extractScriptSigLen(bytes memory _input) internal pure returns (uint256, uint256) {
        if (_input.length < 37) {
          return (ERR_BAD_ARG, 0);
        }
        bytes memory _afterOutpoint = _input.slice(36, _input.length - 36);

        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = parseVarInt(_afterOutpoint);

        return (_varIntDataLen, _scriptSigLen);
    }

    /// @notice          Determines the length of an input from its scriptsig
    /// @dev             36 for outpoint, 1 for scriptsig length, 4 for sequence
    /// @param _input    The input
    /// @return          The length of the input in bytes
    function determineInputLength(bytes memory _input) internal pure returns (uint256) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        if (_varIntDataLen == ERR_BAD_ARG) {
          return ERR_BAD_ARG;
        }

        return 36 + 1 + _varIntDataLen + _scriptSigLen + 4;
    }

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The LEGACY input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLELegacy(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36 + 1 + _varIntDataLen + _scriptSigLen, 4);
    }

    /// @notice          Extracts the sequence from the input
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The LEGACY input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceLegacy(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLELegacy(_input);
        bytes memory _beSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_beSequence));
    }
    /// @notice          Extracts the VarInt-prepended scriptSig from the input in a tx
    /// @dev             Will return hex"00" if passed a witness input
    /// @param _input    The LEGACY input
    /// @return          The length-prepended script sig
    function extractScriptSig(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36, 1 + _varIntDataLen + _scriptSigLen);
    }


    /* ************* */
    /* Witness Input */
    /* ************* */

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The WITNESS input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLEWitness(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(37, 4);
    }

    /// @notice          Extracts the sequence from the input in a tx
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The WITNESS input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceWitness(bytes memory _input) internal pure returns (uint32) {
        bytes memory _leSeqence = extractSequenceLEWitness(_input);
        bytes memory _inputeSequence = reverseEndianness(_leSeqence);
        return uint32(bytesToUint(_inputeSequence));
    }

    /// @notice          Extracts the outpoint from the input in a tx
    /// @dev             32 byte tx id with 4 byte index
    /// @param _input    The input
    /// @return          The outpoint (LE bytes of prev tx hash + LE bytes of prev tx index)
    function extractOutpoint(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(0, 36);
    }

    /// @notice          Extracts the outpoint tx id from an input
    /// @dev             32 byte tx id
    /// @param _input    The input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLE(bytes memory _input) internal pure returns (bytes32) {
        return _input.slice(0, 32).toBytes32();
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    /// @dev             4 byte tx index
    /// @param _input    The input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLE(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(32, 4);
    }

    /* ****** */
    /* Output */
    /* ****** */

    /// @notice          Determines the length of an output
    /// @dev             5 types: WPKH, WSH, PKH, SH, and OP_RETURN
    /// @param _output   The output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLength(bytes memory _output) internal pure returns (uint256) {
        if (_output.length < 9) {
          return ERR_BAD_ARG;
        }
        bytes memory _afterValue = _output.slice(8, _output.length - 8);

        uint256 _varIntDataLen;
        uint256 _scriptPubkeyLength;
        (_varIntDataLen, _scriptPubkeyLength) = parseVarInt(_afterValue);

        if (_varIntDataLen == ERR_BAD_ARG) {
          return ERR_BAD_ARG;
        }

        // 8 byte value, 1 byte for tag itself
        return 8 + 1 + _varIntDataLen + _scriptPubkeyLength;
    }

    /// @notice          Extracts the output at a given index in the TxIns vector
    /// @dev             Iterates over the vout. If you need to extract multiple, write a custom function
    /// @param _vout     The _vout to extract from
    /// @param _index    The 0-indexed location of the output to extract
    /// @return          The specified output
    function extractOutputAtIndex(bytes memory _vout, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index <= _nOuts, "Vout read overrun");

        bytes memory _remaining;

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _remaining = _vout.slice(_offset, _vout.length - _offset);
            _len = determineOutputLength(_remaining);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            _offset += _len;
        }

        _remaining = _vout.slice(_offset, _vout.length - _offset);
        _len = determineOutputLength(_remaining);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");

        return _vout.slice(_offset, _len);
    }

    /// @notice          Extracts the output script length
    /// @dev             Indexes the length prefix on the pk_script
    /// @param _output   The output
    /// @return          The 1 byte length prefix
    function extractOutputScriptLen(bytes memory _output) internal pure returns (bytes memory) {
        return _output.slice(8, 1);
    }

    /// @notice          Extracts the value bytes from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value as LE bytes
    function extractValueLE(bytes memory _output) internal pure returns (bytes memory) {
        return _output.slice(0, 8);
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value
    function extractValue(bytes memory _output) internal pure returns (uint64) {
        bytes memory _leValue = extractValueLE(_output);
        bytes memory _beValue = reverseEndianness(_leValue);
        return uint64(bytesToUint(_beValue));
    }

    /// @notice          Extracts the data from an op return output
    /// @dev             Returns hex"" if no data or not an op return
    /// @param _output   The output
    /// @return          Any data contained in the opreturn output, null if not an op return
    function extractOpReturnData(bytes memory _output) internal pure returns (bytes memory) {
        if (_output.keccak256Slice(9, 1) != keccak256(hex"6a")) {
            return hex"";
        }
        bytes memory _dataLen = _output.slice(10, 1);
        return _output.slice(11, bytesToUint(_dataLen));
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The output
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHash(bytes memory _output) internal pure returns (bytes memory) {
        if (uint8(_output.slice(9, 1)[0]) == 0) {
            uint256 _len = uint8(extractOutputScriptLen(_output)[0]);
            if (_len < 2) {
              return hex"";
            }
            _len -= 2;
            // Check for maliciously formatted witness outputs
            if (uint8(_output.slice(10, 1)[0]) != uint8(_len)) {
                return hex"";
            }
            return _output.slice(11, _len);
        } else {
            bytes32 _tag = _output.keccak256Slice(8, 3);
            // p2pkh
            if (_tag == keccak256(hex"1976a9")) {
                // Check for maliciously formatted p2pkh
                if (uint8(_output.slice(11, 1)[0]) != 0x14 ||
                    _output.keccak256Slice(_output.length - 2, 2) != keccak256(hex"88ac")) {
                    return hex"";
                }
                return _output.slice(12, 20);
            //p2sh
            } else if (_tag == keccak256(hex"17a914")) {
                // Check for maliciously formatted p2sh
                if (uint8(_output.slice(_output.length - 1, 1)[0]) != 0x87) {
                    return hex"";
                }
                return _output.slice(11, 20);
            }
        }
        return hex"";  /* NB: will trigger on OPRETURN and non-standard that don't overrun */
    }

    /* ********** */
    /* Witness TX */
    /* ********** */


    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vin  Raw bytes length-prefixed input vector
    /// @return      True if it represents a validly formatted vin
    function validateVin(bytes memory _vin) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);

        // Not valid if it says there are too many or no inputs
        if (_nIns == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nIns; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vin.length) {
              return false;
            }

            // Grab the next input and determine its length.
            bytes memory _next = _vin.slice(_offset, _vin.length - _offset);
            uint256 _nextLen = determineInputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
              return false;
            }

            // Increase the offset by that much
            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vin.length;
    }

    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vout Raw bytes length-prefixed output vector
    /// @return      True if it represents a validly formatted bout
    function validateVout(bytes memory _vout) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);

        // Not valid if it says there are too many or no inputs
        if (_nOuts == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nOuts; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vout.length) {
              return false;
            }

            // Grab the next output and determine its length.
            // Increase the offset by that much
            bytes memory _next = _vout.slice(_offset, _vout.length - _offset);
            uint256 _nextLen = determineOutputLength(_next);
            if (_nextLen == ERR_BAD_ARG) {
              return false;
            }

            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vout.length;
    }



    /* ************ */
    /* Block Header */
    /* ************ */

    /// @notice          Extracts the transaction merkle root from a block header
    /// @dev             Use verifyHash256Merkle to verify proofs with this root
    /// @param _header   The header
    /// @return          The merkle root (little-endian)
    function extractMerkleRootLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(36, 32);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256 bit number encoded as a 3-byte mantissa and 1 byte exponent
    /// @param _header   The header
    /// @return          The target threshold
    function extractTarget(bytes memory _header) internal pure returns (uint256) {
        bytes memory _m = _header.slice(72, 3);
        uint8 _e = uint8(_header[75]);
        uint256 _mantissa = bytesToUint(reverseEndianness(_m));
        uint _exponent = _e - 3;

        return _mantissa * (256 ** _exponent);
    }

    /// @notice          Calculate difficulty from the difficulty 1 target and current target
    /// @dev             Difficulty 1 is 0x1d00ffff on mainnet and testnet
    /// @dev             Difficulty 1 is a 256 bit number encoded as a 3-byte mantissa and 1 byte exponent
    /// @param _target   The current target
    /// @return          The block difficulty (bdiff)
    function calculateDifficulty(uint256 _target) internal pure returns (uint256) {
        // Difficulty 1 calculated from 0x1d00ffff
        return DIFF1_TARGET.div(_target);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(4, 32);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (little-endian bytes)
    function extractTimestampLE(bytes memory _header) internal pure returns (bytes memory) {
        return _header.slice(68, 4);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (uint)
    function extractTimestamp(bytes memory _header) internal pure returns (uint32) {
        return uint32(bytesToUint(reverseEndianness(extractTimestampLE(_header))));
    }

    /// @notice          Extracts the expected difficulty from a block header
    /// @dev             Does NOT verify the work
    /// @param _header   The header
    /// @return          The difficulty as an integer
    function extractDifficulty(bytes memory _header) internal pure returns (uint256) {
        return calculateDifficulty(extractTarget(_header));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes memory _a, bytes memory _b) internal pure returns (bytes32) {
        return hash256(abi.encodePacked(_a, _b));
    }

    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed.
    /// @param _proof    The proof. Tightly packed LE sha256 hashes. The last hash is the root
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(bytes memory _proof, uint _index) internal pure returns (bool) {
        // Not an even number of hashes
        if (_proof.length % 32 != 0) {
            return false;
        }

        // Special case for coinbase-only blocks
        if (_proof.length == 32) {
            return true;
        }

        // Should never occur
        if (_proof.length == 64) {
            return false;
        }

        uint _idx = _index;
        bytes32 _root = _proof.slice(_proof.length - 32, 32).toBytes32();
        bytes32 _current = _proof.slice(0, 32).toBytes32();

        for (uint i = 1; i < (_proof.length.div(32)) - 1; i++) {
            if (_idx % 2 == 1) {
                _current = _hash256MerkleStep(_proof.slice(i * 32, 32), abi.encodePacked(_current));
            } else {
                _current = _hash256MerkleStep(abi.encodePacked(_current), _proof.slice(i * 32, 32));
            }
            _idx = _idx >> 1;
        }
        return _current == _root;
    }

    /*
    NB: https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp#L49-L72
    NB: We get a full-bitlength target from this. For comparison with
        header-encoded targets we need to mask it with the header target
        e.g. (full & truncated) == truncated
    */
    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
          NB: high targets e.g. ffff0020 can cause overflows here
              so we divide it by 256**2, then multiply by 256**2 later
              we know the target is evenly divisible by 256**2, so this isn't an issue
        */

        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}
"
    },
    "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol": {
      "content": "pragma solidity ^0.5.10;

/*

https://github.com/GNSPS/solidity-bytes-utils/

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/


/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
                add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                        ),
                        // and now shift left the number of bytes to
                        // leave space for the length in the slot
                        exp(0x100, sub(32, newlength))
                        ),
                        // increase length by the double of the memory
                        // bytes length
                        mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                    ),
                    and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint _start, uint _length) internal  pure returns (bytes memory res) {
        if (_length == 0) {
            return hex"";
        }
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        uint _totalLen = _start + 20;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Address conversion out of bounds.");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        uint _totalLen = _start + 32;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Uint conversion out of bounds.");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function toBytes32(bytes memory _source) pure internal returns (bytes32 result) {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(bytes memory _bytes, uint _start, uint _length) pure internal returns (bytes32 result) {
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}
"
    },
    "@summa-tx/bitcoin-spv-sol/contracts/SafeMath.sol": {
      "content": "pragma solidity ^0.5.10;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}
"
    },
    "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol": {
      "content": "pragma solidity ^0.5.10;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";
import {BTCUtils} from "./BTCUtils.sol";


library ValidateSPV {

    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes { NONE, LEGACY, COMPATIBILITY, WITNESS }
    enum OutputTypes { NONE, WPKH, WSH, OP_RETURN, PKH, SH, NONSTANDARD }

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint _index
    ) internal pure returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.length == 0) {
            return true;
        }

        bytes memory _proof = abi.encodePacked(_txid, _intermediateNodes, _merkleRoot);
        // If the Merkle proof failed, bubble up error
        return _proof.verifyHash256Merkle(_index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime   4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes memory _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes memory _locktime
    ) internal pure returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256();
    }

    /// @notice             Checks validity of header chain
    /// @notice             Compares the hash of each header to the prevHash in the next header
    /// @param _headers     Raw byte array of header chain
    /// @return             The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(bytes memory _headers) internal view returns (uint256 _totalDifficulty) {

        // Check header chain length
        if (_headers.length % 80 != 0) {return ERR_BAD_LENGTH;}

        // Initialize header start index
        bytes32 _digest;

        _totalDifficulty = 0;

        for (uint256 _start = 0; _start < _headers.length; _start += 80) {

            // ith header start index and ith header
            bytes memory _header = _headers.slice(_start, 80);

            // After the first header, check that headers are in a chain
            if (_start != 0) {
                if (!validateHeaderPrevHash(_header, _digest)) {return ERR_INVALID_CHAIN;}
            }

            // ith header target
            uint256 _target = _header.extractTarget();

            // Require that the header has sufficient work
            _digest = _header.hash256View();
            if(uint256(_digest).reverseUint256() > _target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            _totalDifficulty = _totalDifficulty.add(_target.calculateDifficulty());
        }
    }

    /// @notice             Checks validity of header work
    /// @param _digest      Header digest
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(bytes32 _digest, uint256 _target) internal pure returns (bool) {
        if (_digest == bytes32(0)) {return false;}
        return (abi.encodePacked(_digest).reverseEndianness().bytesToUint() < _target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function validateHeaderPrevHash(bytes memory _header, bytes32 _prevHeaderDigest) internal pure returns (bool) {

        // Extract prevHash of current header
        bytes32 _prevHash = _header.extractPrevBlockLE().toBytes32();

        // Compare prevHash of current header to previous header's digest
        if (_prevHash != _prevHeaderDigest) {return false;}

        return true;
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
"
    },
    "openzeppelin-solidity/contracts/introspection/IERC165.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
"
    },
    "solidity/contracts/system/TBTCConstants.sol": {
      "content": "pragma solidity 0.5.17;

library TBTCConstants {
    // This is intended to make it easy to update system params
    // During testing swap this out with another constats contract

    // System Parameters
    uint256 public constant BENEFICIARY_FEE_DIVISOR = 1000;  // 1/1000 = 10 bps = 0.1% = 0.001
    uint256 public constant SATOSHI_MULTIPLIER = 10 ** 10; // multiplier to convert satoshi to TBTC token units
    uint256 public constant DEPOSIT_TERM_LENGTH = 180 * 24 * 60 * 60; // 180 days in seconds
    uint256 public constant TX_PROOF_DIFFICULTY_FACTOR = 6; // confirmations on the Bitcoin chain

    // Redemption Flow
    uint256 public constant REDEMPTION_SIGNATURE_TIMEOUT = 2 * 60 * 60;  // seconds
    uint256 public constant INCREASE_FEE_TIMER = 4 * 60 * 60;  // seconds
    uint256 public constant REDEMPTION_PROOF_TIMEOUT = 6 * 60 * 60;  // seconds
    uint256 public constant MINIMUM_REDEMPTION_FEE = 2000; // satoshi

    // Funding Flow
    uint256 public constant FUNDING_PROOF_TIMEOUT = 3 * 60 * 60; // seconds
    uint256 public constant FORMATION_TIMEOUT = 3 * 60 * 60; // seconds

    // Liquidation Flow
    uint256 public constant COURTESY_CALL_DURATION = 6 * 60 * 60; // seconds
    uint256 public constant AUCTION_DURATION = 24 * 60 * 60; // seconds
    uint256 public constant PERMITTED_FEE_BUMPS = 5; // number of times the fee can be increased

    // Getters for easy access
    function getBeneficiaryRewardDivisor() public pure returns (uint256) { return BENEFICIARY_FEE_DIVISOR; }
    function getSatoshiMultiplier() public pure returns (uint256) { return SATOSHI_MULTIPLIER; }
    function getDepositTerm() public pure returns (uint256) { return DEPOSIT_TERM_LENGTH; }
    function getTxProofDifficultyFactor() public pure returns (uint256) { return TX_PROOF_DIFFICULTY_FACTOR; }

    function getSignatureTimeout() public pure returns (uint256) { return REDEMPTION_SIGNATURE_TIMEOUT; }
    function getIncreaseFeeTimer() public pure returns (uint256) { return INCREASE_FEE_TIMER; }
    function getRedemptionProofTimeout() public pure returns (uint256) { return REDEMPTION_PROOF_TIMEOUT; }
    function getMinimumRedemptionFee() public pure returns (uint256) { return MINIMUM_REDEMPTION_FEE; }

    function getFundingTimeout() public pure returns (uint256) { return FUNDING_PROOF_TIMEOUT; }
    function getSigningGroupFormationTimeout() public pure returns (uint256) { return FORMATION_TIMEOUT; }

    function getCourtesyCallTimeout() public pure returns (uint256) { return COURTESY_CALL_DURATION; }
    function getAuctionDuration() public pure returns (uint256) { return AUCTION_DURATION; }
    function getPermittedFeeBumps() public pure returns (uint256) {return PERMITTED_FEE_BUMPS; }
}
"
    },
    "solidity/contracts/system/TBTCToken.sol": {
      "content": "pragma solidity 0.5.17;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {ERC20Detailed} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import {VendingMachineAuthority} from "./VendingMachineAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title  TBTC Token.
/// @notice This is the TBTC ERC20 contract.
/// @dev    Tokens can only be minted by the `VendingMachine` contract.
contract TBTCToken is ERC20Detailed, ERC20, VendingMachineAuthority {
    /// @dev Constructor, calls ERC20Detailed constructor to set Token info
    ///      ERC20Detailed(TokenName, TokenSymbol, NumberOfDecimals)
    constructor(address _VendingMachine)
        ERC20Detailed("tBTC", "TBTC", 18)
        VendingMachineAuthority(_VendingMachine)
    public {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev             Mints an amount of the token and assigns it to an account.
    ///                  Uses the internal _mint function.
    /// @param _account  The account that will receive the created tokens.
    /// @param _amount   The amount of tokens that will be created.
    function mint(address _account, uint256 _amount) public onlyVendingMachine returns (bool) {
        // NOTE: this is a public function with unchecked minting.
        _mint(_account, _amount);
        return true;
    }

    /// @dev             Burns an amount of the token from the given account's balance.
    ///                  deducting from the sender's allowance for said account.
    ///                  Uses the internal _burn function.
    /// @param _account  The account whose tokens will be burnt.
    /// @param _amount   The amount of tokens that will be burnt.
    function burnFrom(address _account, uint256 _amount) public {
        _burnFrom(_account, _amount);
    }

    /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
    /// total supply.
    /// @param _amount   The amount of tokens that will be burnt.
    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    /// @notice           Set allowance for other address and notify.
    ///                   Allows `_spender` to spend no more than `_value`
    ///                   tokens on your behalf and then ping the contract about
    ///                   it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface to receive approval notifications.
    /// @param _spender   Address of contract authorized to spend.
    /// @param _value     The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    /// @return true if the `_spender` was successfully approved and acted on
    ///         the approval, false (or revert) otherwise.
    function approveAndCall(ITokenRecipient _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
        if (approve(address(_spender), _value)) {
            _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
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
    "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
"
    },
    "solidity/contracts/system/VendingMachineAuthority.sol": {
      "content": "pragma solidity 0.5.17;

/// @title  Vending Machine Authority.
/// @notice Contract to secure function calls to the Vending Machine.
/// @dev    Secured by setting the VendingMachine address and using the
///         onlyVendingMachine modifier on functions requiring restriction.
contract VendingMachineAuthority {
    address internal VendingMachine;

    constructor(address _vendingMachine) public {
        VendingMachine = _vendingMachine;
    }

    /// @notice Function modifier ensures modified function caller address is the vending machine.
    modifier onlyVendingMachine() {
        require(msg.sender == VendingMachine, "caller must be the vending machine");
        _;
    }
}
"
    },
    "solidity/contracts/interfaces/ITokenRecipient.sol": {
      "content": "pragma solidity 0.5.17;

/// @title Interface of recipient contract for `approveAndCall` pattern.
///        Implementors will be able to be used in an `approveAndCall`
///        interaction with a supporting contract, such that a token approval
///        can call the contract acting on that approval in a single
///        transaction.
///
///        See the `FundingScript` and `RedemptionScript` contracts as examples.
interface ITokenRecipient {
    /// Typically called from a token contract's `approveAndCall` method, this
    /// method will receive the original owner of the token (`_from`), the
    /// transferred `_value` (in the case of an ERC721, the token id), the token
    /// address (`_token`), and a blob of `_extraData` that is informally
    /// specified by the implementor of this method as a way to communicate
    /// additional parameters.
    ///
    /// Token calls to `receiveApproval` should revert if `receiveApproval`
    /// reverts, and reverts should remove the approval.
    ///
    /// @param _from The original owner of the token approved for transfer.
    /// @param _value For an ERC20, the amount approved for transfer; for an
    ///        ERC721, the id of the token approved for transfer.
    /// @param _token The address of the contract for the token whose transfer
    ///        was approved.
    /// @param _extraData An additional data blob forwarded unmodified through
    ///        `approveAndCall`, used to allow the token owner to pass
    ///         additional parameters and data to this method. The structure of
    ///         the extra data is informally specified by the implementor of
    ///         this interface.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}
"
    },
    "solidity/contracts/system/FeeRebateToken.sol": {
      "content": "pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol";
import "./VendingMachineAuthority.sol";

/// @title  Fee Rebate Token
/// @notice The Fee Rebate Token (FRT) is a non fungible token (ERC721)
///         the ID of which corresponds to a given deposit address.
///         If the corresponding deposit is still active, ownership of this token
///         could result in reimbursement of the signer fee paid to open the deposit.
/// @dev    This token is minted automatically when a TDT (`TBTCDepositToken`)
///         is exchanged for TBTC (`TBTCToken`) via the Vending Machine (`VendingMachine`).
///         When the Deposit is redeemed, the TDT holder will be reimbursed
///         the signer fee if the redeemer is not the TDT holder and Deposit is not
///         at-term or in COURTESY_CALL.
contract FeeRebateToken is ERC721Metadata, VendingMachineAuthority {

    constructor(address _vendingMachine)
        ERC721Metadata("Fee Rebate Token", "FRT")
        VendingMachineAuthority(_vendingMachine)
    public {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev Mints a new token.
    /// Reverts if the given token ID already exists.
    /// @param _to The address that will own the minted token.
    /// @param _tokenId uint256 ID of the token to be minted.
    function mint(address _to, uint256 _tokenId) public onlyVendingMachine {
        _mint(_to, _tokenId);
    }

    /// @dev Returns whether the specified token exists.
    /// @param _tokenId uint256 ID of the token to query the existence of.
    /// @return bool whether the token exists.
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol": {
      "content": "pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "../../introspection/ERC165.sol";

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
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
    "openzeppelin-solidity/contracts/drafts/Counters.sol": {
      "content": "pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
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
"
    },
    "openzeppelin-solidity/contracts/introspection/ERC165.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
"
    },
    "solidity/contracts/deposit/OutsourceDepositLogging.sol": {
      "content": "pragma solidity 0.5.17;

import {DepositLog} from "../DepositLog.sol";
import {DepositUtils} from "./DepositUtils.sol";

library OutsourceDepositLogging {


    /// @notice               Fires a Created event.
    /// @dev                  `DepositLog.logCreated` fires a Created event with
    ///                       _keepAddress, msg.sender and block.timestamp.
    ///                       msg.sender will be the calling Deposit's address.
    /// @param  _keepAddress  The address of the associated keep.
    function logCreated(DepositUtils.Deposit storage _d, address _keepAddress) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCreated(_keepAddress);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _redeemer       The ethereum address of the redeemer.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoSize       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The redeemer or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        DepositUtils.Deposit storage _d,
        address _redeemer,
        bytes32 _digest,
        uint256 _utxoSize,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public { // not external to allow bytes memory output scripts
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedemptionRequested(
            _redeemer,
            _digest,
            _utxoSize,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest Signed digest.
    /// @param  _r      Signature r value.
    /// @param  _s      Signature s value.
    /// @return         True if successful, else revert.
    function logGotRedemptionSignature(
        DepositUtils.Deposit storage _d,
        bytes32 _digest,
        bytes32 _r,
        bytes32 _s
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logGotRedemptionSignature(
            _digest,
            _r,
            _s
        );
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRegisteredPubkey(
        DepositUtils.Deposit storage _d,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRegisteredPubkey(
            _signingGroupPubkeyX,
            _signingGroupPubkeyY);
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logSetupFailed(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logSetupFailed();
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunderRequestedAbort(
        DepositUtils.Deposit storage _d,
        bytes memory _abortOutputScript
    ) public {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunderRequestedAbort(_abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFraudDuringSetup(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFraudDuringSetup();
    }

    /// @notice     Fires a Funded event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logFunded(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logFunded();
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logCourtesyCalled(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logCourtesyCalled();
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(DepositUtils.Deposit storage _d, bool _wasFraud) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logStartedLiquidation(_wasFraud);
    }

    /// @notice     Fires a Redeemed event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logRedeemed(DepositUtils.Deposit storage _d, bytes32 _txid) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logRedeemed(_txid);
    }

    /// @notice     Fires a Liquidated event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logLiquidated(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logLiquidated();
    }

    /// @notice     Fires a ExitedCourtesyCall event.
    /// @dev        The logger is on a system contract, so all logs from all deposits are from the same address.
    function logExitedCourtesyCall(DepositUtils.Deposit storage _d) external {
        DepositLog _logger = DepositLog(address(_d.tbtcSystem));
        _logger.logExitedCourtesyCall();
    }
}
"
    },
    "solidity/contracts/DepositLog.sol": {
      "content": "pragma solidity 0.5.17;

import {TBTCDepositToken} from "./system/TBTCDepositToken.sol";


contract DepositLog {
    /*
    Logging philosophy:
      Every state transition should fire a log
      That log should have ALL necessary info for off-chain actors
      Everyone should be able to ENTIRELY rely on log messages
    */

    // `TBTCDepositToken` mints a token for every new Deposit.
    // If a token exists for a given ID, we know it is a valid Deposit address.
    TBTCDepositToken tbtcDepositToken;

    // This event is fired when we init the deposit
    event Created(
        address indexed _depositContractAddress,
        address indexed _keepAddress,
        uint256 _timestamp
    );

    // This log event contains all info needed to rebuild the redemption tx
    // We index on request and signers and digest
    event RedemptionRequested(
        address indexed _depositContractAddress,
        address indexed _requester,
        bytes32 indexed _digest,
        uint256 _utxoSize,
        bytes _redeemerOutputScript,
        uint256 _requestedFee,
        bytes _outpoint
    );

    // This log event contains all info needed to build a witnes
    // We index the digest so that we can search events for the other log
    event GotRedemptionSignature(
        address indexed _depositContractAddress,
        bytes32 indexed _digest,
        bytes32 _r,
        bytes32 _s,
        uint256 _timestamp
    );

    // This log is fired when the signing group returns a public key
    event RegisteredPubkey(
        address indexed _depositContractAddress,
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY,
        uint256 _timestamp
    );

    // This event is fired when we enter the FAILED_SETUP state for any reason
    event SetupFailed(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when a funder requests funder abort after
    // FAILED_SETUP has been reached. Funder abort is a voluntary signer action
    // to return UTXO(s) that were sent to a signer-controlled wallet despite
    // the funding proofs having failed.
    event FunderAbortRequested(
        address indexed _depositContractAddress,
        bytes _abortOutputScript
    );

    // This event is fired when we detect an ECDSA fraud before seeing a funding proof
    event FraudDuringSetup(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we enter the ACTIVE state
    event Funded(address indexed _depositContractAddress, uint256 _timestamp);

    // This event is called when we enter the COURTESY_CALL state
    event CourtesyCalled(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This event is fired when we go from COURTESY_CALL to ACTIVE
    event ExitedCourtesyCall(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    // This log event is fired when liquidation
    event StartedLiquidation(
        address indexed _depositContractAddress,
        bool _wasFraud,
        uint256 _timestamp
    );

    // This event is fired when the Redemption SPV proof is validated
    event Redeemed(
        address indexed _depositContractAddress,
        bytes32 indexed _txid,
        uint256 _timestamp
    );

    // This event is fired when Liquidation is completed
    event Liquidated(
        address indexed _depositContractAddress,
        uint256 _timestamp
    );

    //
    // AUTH
    //

    /// @notice             Checks if an address is an allowed logger.
    /// @dev                checks tbtcDepositToken to see if the caller represents
    ///                     an existing deposit.
    ///                     We don't require this, so deposits are not bricked if the system borks.
    /// @param  _caller     The address of the calling contract.
    /// @return             True if approved, otherwise false.
    function approvedToLog(address _caller) public view returns (bool) {
        return tbtcDepositToken.exists(uint256(_caller));
    }

    //
    // Logging
    //

    /// @notice               Fires a Created event.
    /// @dev                  We append the sender, which is the deposit contract that called.
    /// @param  _keepAddress  The address of the associated keep.
    /// @return               True if successful, else revert.
    function logCreated(address _keepAddress) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Created(msg.sender, _keepAddress, block.timestamp);
    }

    /// @notice                 Fires a RedemptionRequested event.
    /// @dev                    This is the only event without an explicit timestamp.
    /// @param  _requester      The ethereum address of the requester.
    /// @param  _digest         The calculated sighash digest.
    /// @param  _utxoSize       The size of the utxo in sat.
    /// @param  _redeemerOutputScript The redeemer's length-prefixed output script.
    /// @param  _requestedFee   The requester or bump-system specified fee.
    /// @param  _outpoint       The 36 byte outpoint.
    /// @return                 True if successful, else revert.
    function logRedemptionRequested(
        address _requester,
        bytes32 _digest,
        uint256 _utxoSize,
        bytes memory _redeemerOutputScript,
        uint256 _requestedFee,
        bytes memory _outpoint
    ) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RedemptionRequested(
            msg.sender,
            _requester,
            _digest,
            _utxoSize,
            _redeemerOutputScript,
            _requestedFee,
            _outpoint
        );
    }

    /// @notice         Fires a GotRedemptionSignature event.
    /// @dev            We append the sender, which is the deposit contract that called.
    /// @param  _digest signed digest.
    /// @param  _r      signature r value.
    /// @param  _s      signature s value.
    function logGotRedemptionSignature(bytes32 _digest, bytes32 _r, bytes32 _s)
        public
    {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit GotRedemptionSignature(
            msg.sender,
            _digest,
            _r,
            _s,
            block.timestamp
        );
    }

    /// @notice     Fires a RegisteredPubkey event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRegisteredPubkey(
        bytes32 _signingGroupPubkeyX,
        bytes32 _signingGroupPubkeyY
    ) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit RegisteredPubkey(
            msg.sender,
            _signingGroupPubkeyX,
            _signingGroupPubkeyY,
            block.timestamp
        );
    }

    /// @notice     Fires a SetupFailed event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logSetupFailed() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit SetupFailed(msg.sender, block.timestamp);
    }

    /// @notice     Fires a FunderAbortRequested event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunderRequestedAbort(bytes memory _abortOutputScript) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FunderAbortRequested(msg.sender, _abortOutputScript);
    }

    /// @notice     Fires a FraudDuringSetup event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFraudDuringSetup() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit FraudDuringSetup(msg.sender, block.timestamp);
    }

    /// @notice     Fires a Funded event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logFunded() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Funded(msg.sender, block.timestamp);
    }

    /// @notice     Fires a CourtesyCalled event.
    /// @dev        We append the sender, which is the deposit contract that called.
    function logCourtesyCalled() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit CourtesyCalled(msg.sender, block.timestamp);
    }

    /// @notice             Fires a StartedLiquidation event.
    /// @dev                We append the sender, which is the deposit contract that called.
    /// @param _wasFraud    True if liquidating for fraud.
    function logStartedLiquidation(bool _wasFraud) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit StartedLiquidation(msg.sender, _wasFraud, block.timestamp);
    }

    /// @notice     Fires a Redeemed event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logRedeemed(bytes32 _txid) public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Redeemed(msg.sender, _txid, block.timestamp);
    }

    /// @notice     Fires a Liquidated event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logLiquidated() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit Liquidated(msg.sender, block.timestamp);
    }

    /// @notice     Fires a ExitedCourtesyCall event
    /// @dev        We append the sender, which is the deposit contract that called.
    function logExitedCourtesyCall() public {
        require(
            approvedToLog(msg.sender),
            "Caller is not approved to log events"
        );
        emit ExitedCourtesyCall(msg.sender, block.timestamp);
    }

    /// @notice               Sets the tbtcDepositToken contract.
    /// @dev                  The contract is used by `approvedToLog` to check if the
    ///                       caller is a Deposit contract. This should only be called once.
    /// @param  _tbtcDepositTokenAddress  The address of the tbtcDepositToken.
    function setTbtcDepositToken(TBTCDepositToken _tbtcDepositTokenAddress)
        internal
    {
        require(
            address(tbtcDepositToken) == address(0),
            "tbtcDepositToken is already set"
        );
        tbtcDepositToken = _tbtcDepositTokenAddress;
    }
}
"
    },
    "solidity/contracts/system/DepositFactoryAuthority.sol": {
      "content": "pragma solidity 0.5.17;

/// @title  Deposit Factory Authority
/// @notice Contract to secure function calls to the Deposit Factory.
/// @dev    Secured by setting the depositFactory address and using the onlyFactory
///         modifier on functions requiring restriction.
contract DepositFactoryAuthority {

    bool internal _initialized = false;
    address internal _depositFactory;

    /// @notice Set the address of the System contract on contract initialization.
    function initialize(address _factory) public {
        require(! _initialized, "Factory can only be initialized once.");

        _depositFactory = _factory;
        _initialized = true;
    }

    /// @notice Function modifier ensures modified function is only called by set deposit factory.
    modifier onlyFactory(){
        require(_initialized, "Factory initialization must have been called.");
        require(msg.sender == _depositFactory, "Caller must be depositFactory contract");
        _;
    }
}
"
    },
    "solidity/contracts/deposit/DepositFunding.sol": {
      "content": "pragma solidity 0.5.17;

import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {IBondedECDSAKeep} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {TBTCToken} from "../system/TBTCToken.sol";
import {DepositUtils} from "./DepositUtils.sol";
import {DepositLiquidation} from "./DepositLiquidation.sol";
import {DepositStates} from "./DepositStates.sol";
import {OutsourceDepositLogging} from "./OutsourceDepositLogging.sol";
import {TBTCConstants} from "../system/TBTCConstants.sol";

library DepositFunding {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using BTCUtils for bytes;
    using BytesLib for bytes;

    using DepositUtils for DepositUtils.Deposit;
    using DepositStates for DepositUtils.Deposit;
    using DepositLiquidation for DepositUtils.Deposit;
    using OutsourceDepositLogging for DepositUtils.Deposit;

    /// @notice     Deletes state after funding.
    /// @dev        This is called when we go to ACTIVE or setup fails without fraud.
    function fundingTeardown(DepositUtils.Deposit storage _d) internal {
        _d.signingGroupRequestedAt = 0;
        _d.fundingProofTimerStart = 0;
    }

    /// @notice     Deletes state after the funding ECDSA fraud process.
    /// @dev        This is only called as we transition to setup failed.
    function fundingFraudTeardown(DepositUtils.Deposit storage _d) internal {
        _d.keepAddress = address(0);
        _d.signingGroupRequestedAt = 0;
        _d.fundingProofTimerStart = 0;
        _d.signingGroupPubkeyX = bytes32(0);
        _d.signingGroupPubkeyY = bytes32(0);
    }

    /// @notice         Internally called function to set up a newly created Deposit instance.
    ///                 This should not be called by developers, use `DepositFactory.createNewDeposit`
    ///                 to create a new deposit.
    /// @dev            If called directly, the transaction will revert since the call will be
    ///                 executed on an already set-up instance.
    /// @param _d       Deposit storage pointer.
    /// @param _m       Signing group honesty threshold.
    /// @param _n       Signing group size.
    /// @return         True if successful, otherwise revert.
    function createNewDeposit(
        DepositUtils.Deposit storage _d,
        uint16 _m,
        uint16 _n,
        uint64 _lotSizeSatoshis
    ) public returns (bool) {
        require(_d.tbtcSystem.getAllowNewDeposits(), "Opening new deposits is currently disabled.");
        require(_d.inStart(), "Deposit setup already requested");
        require(_d.tbtcSystem.isAllowedLotSize(_lotSizeSatoshis), "provided lot size not supported");

        _d.lotSizeSatoshis = _lotSizeSatoshis;
        uint256 _bondRequirementSatoshi = _lotSizeSatoshis.mul(_d.tbtcSystem.getInitialCollateralizedPercent()).div(100);
        uint256 _bondRequirementWei = _d.fetchBitcoinPrice().mul(_bondRequirementSatoshi);

        _d.keepSetupFee = _d.tbtcSystem.getNewDepositFeeEstimate();
        /* solium-disable-next-line value-in-payable */
        _d.keepAddress = _d.tbtcSystem.requestNewKeep.value(msg.value)(
            _m,
            _n,
            _bondRequirementWei,
            TBTCConstants.getDepositTerm()
        );

        _d.signerFeeDivisor = _d.tbtcSystem.getSignerFeeDivisor();
        _d.undercollateralizedThresholdPercent = _d.tbtcSystem.getUndercollateralizedThresholdPercent();
        _d.severelyUndercollateralizedThresholdPercent = _d.tbtcSystem.getSeverelyUndercollateralizedThresholdPercent();
        _d.initialCollateralizedPercent = _d.tbtcSystem.getInitialCollateralizedPercent();
        _d.signingGroupRequestedAt = block.timestamp;

        _d.setAwaitingSignerSetup();
        _d.logCreated(_d.keepAddress);

        return true;
    }

    /// @notice     Anyone may notify the contract that signing group setup has timed out.
    /// @param  _d  Deposit storage pointer.
    function notifySignerSetupFailure(DepositUtils.Deposit storage _d) public {
        require(_d.inAwaitingSignerSetup(), "Not awaiting setup");
        require(
            block.timestamp > _d.signingGroupRequestedAt.add(TBTCConstants.getSigningGroupFormationTimeout()),
            "Signing group formation timeout not yet elapsed"
        );

        // refund the deposit owner the cost to create a new Deposit at the time the Deposit was opened.
        uint256 _seized = _d.seizeSignerBonds();

        /* solium-disable-next-line security/no-send */
        _d.enableWithdrawal(_d.depositOwner(), _d.keepSetupFee);
        _d.pushFundsToKeepGroup(_seized.sub(_d.keepSetupFee));

        _d.setFailedSetup();
        _d.logSetupFailed();

        fundingTeardown(_d);
    }

    /// @notice             we poll the Keep contract to retrieve our pubkey.
    /// @dev                We store the pubkey as 2 bytestrings, X and Y.
    /// @param  _d          Deposit storage pointer.
    /// @return             True if successful, otherwise revert.
    function retrieveSignerPubkey(DepositUtils.Deposit storage _d) public {
        require(_d.inAwaitingSignerSetup(), "Not currently awaiting signer setup");

        bytes memory _publicKey = IBondedECDSAKeep(_d.keepAddress).getPublicKey();
        require(_publicKey.length == 64, "public key not set or not 64-bytes long");

        _d.signingGroupPubkeyX = _publicKey.slice(0, 32).toBytes32();
        _d.signingGroupPubkeyY = _publicKey.slice(32, 32).toBytes32();
        require(_d.signingGroupPubkeyY != bytes32(0) && _d.signingGroupPubkeyX != bytes32(0), "Keep returned bad pubkey");
        _d.fundingProofTimerStart = block.timestamp;

        _d.setAwaitingBTCFundingProof();
        _d.logRegisteredPubkey(
            _d.signingGroupPubkeyX,
            _d.signingGroupPubkeyY);
    }

    /// @notice     Anyone may notify the contract that the funder has failed to send BTC.
    /// @dev        This is considered a funder fault, and the funder's payment
    ///             for opening the deposit is not refunded.
    /// @param  _d  Deposit storage pointer.
    function notifyFundingTimeout(DepositUtils.Deposit storage _d) public {
        require(_d.inAwaitingBTCFundingProof(), "Funding timeout has not started");
        require(
            block.timestamp > _d.fundingProofTimerStart.add(TBTCConstants.getFundingTimeout()),
            "Funding timeout has not elapsed."
        );
        _d.setFailedSetup();
        _d.logSetupFailed();

        _d.closeKeep();
        fundingTeardown(_d);
    }

    /// @notice Requests a funder abort for a failed-funding deposit; that is,
    ///         requests return of a sent UTXO to `_abortOutputScript`. This can
    ///         be used for example when a UTXO is sent that is the wrong size
    ///         for the lot. Must be called after setup fails for any reason,
    ///         and imposes no requirement or incentive on the signing group to
    ///         return the UTXO.
    /// @dev This is a self-admitted funder fault, and should only be callable
    ///      by the TDT holder.
    /// @param _d Deposit storage pointer.
    /// @param _abortOutputScript The output script the funder wishes to request
    ///        a return of their UTXO to.
    function requestFunderAbort(
        DepositUtils.Deposit storage _d,
        bytes memory _abortOutputScript
    ) public {
        require(
            _d.inFailedSetup(),
            "The deposit has not failed funding"
        );

        _d.logFunderRequestedAbort(_abortOutputScript);
    }

    /// @notice                 Anyone can provide a signature that was not requested to prove fraud during funding.
    /// @dev                    Calls out to the keep to verify if there was fraud.
    /// @param  _d              Deposit storage pointer.
    /// @param  _v              Signature recovery value.
    /// @param  _r              Signature R value.
    /// @param  _s              Signature S value.
    /// @param _signedDigest    The digest signed by the signature vrs tuple.
    /// @param _preimage        The sha256 preimage of the digest.
    /// @return                 True if successful, otherwise revert.
    function provideFundingECDSAFraudProof(
        DepositUtils.Deposit storage _d,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public {
        require(
            _d.inAwaitingBTCFundingProof(),
            "Signer fraud during funding flow only available while awaiting funding"
        );

        _d.submitSignatureFraud(_v, _r, _s, _signedDigest, _preimage);
        _d.logFraudDuringSetup();

        // Allow deposit owner to withdraw seized bonds after contract termination.
        uint256 _seized = _d.seizeSignerBonds();
        _d.enableWithdrawal(_d.depositOwner(), _seized);

        fundingFraudTeardown(_d);
        _d.setFailedSetup();
        _d.logSetupFailed();
    }

    /// @notice                     Anyone may notify the deposit of a funding proof to activate the deposit.
    ///                             This is the happy-path of the funding flow. It means that we have succeeded.
    /// @dev                        Takes a pre-parsed transaction and calculates values needed to verify funding.
    /// @param  _d                  Deposit storage pointer.
    /// @param _txVersion           Transaction version number (4-byte LE).
    /// @param _txInputVector       All transaction inputs prepended by the number of inputs encoded as a VarInt, max 0xFC(252) inputs.
    /// @param _txOutputVector      All transaction outputs prepended by the number of outputs encoded as a VarInt, max 0xFC(252) outputs.
    /// @param _txLocktime          Final 4 bytes of the transaction.
    /// @param _fundingOutputIndex  Index of funding output in _txOutputVector (0-indexed).
    /// @param _merkleProof         The merkle proof of transaction inclusion in a block.
    /// @param _txIndexInBlock      Transaction index in the block (0-indexed).
    /// @param _bitcoinHeaders      Single bytestring of 80-byte bitcoin headers, lowest height first.
    /// @return                     True if no errors are thrown.
    function provideBTCFundingProof(
        DepositUtils.Deposit storage _d,
        bytes4 _txVersion,
        bytes memory _txInputVector,
        bytes memory _txOutputVector,
        bytes4 _txLocktime,
        uint8 _fundingOutputIndex,
        bytes memory _merkleProof,
        uint256 _txIndexInBlock,
        bytes memory _bitcoinHeaders
    ) public returns (bool) {

        require(_d.inAwaitingBTCFundingProof(), "Not awaiting funding");

        bytes8 _valueBytes;
        bytes memory  _utxoOutpoint;

        (_valueBytes, _utxoOutpoint) = _d.validateAndParseFundingSPVProof(
            _txVersion,
            _txInputVector,
            _txOutputVector,
            _txLocktime,
            _fundingOutputIndex,
            _merkleProof,
            _txIndexInBlock,
            _bitcoinHeaders
        );

        // Write down the UTXO info and set to active. Congratulations :)
        _d.utxoSizeBytes = _valueBytes;
        _d.utxoOutpoint = _utxoOutpoint;
        _d.fundedAt = block.timestamp;

        fundingTeardown(_d);
        _d.setActive();
        _d.logFunded();

        return true;
    }
}
"
    },
    "solidity/contracts/external/IMedianizer.sol": {
      "content": "pragma solidity 0.5.17;

/// @notice A medianizer price feed.
/// @dev Based off the MakerDAO medianizer (https://github.com/makerdao/median)
interface IMedianizer {
    /// @notice Get the current price.
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    function read() external view returns (uint256);

    /// @notice Get the current price and check if the price feed is active
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    /// @return true if price is > 0, else returns false
    function peek() external view returns (uint256, bool);
}
"
    },
    "solidity/contracts/interfaces/ISatWeiPriceFeed.sol": {
      "content": "pragma solidity 0.5.17;

import "../external/IMedianizer.sol";

/// @notice satoshi/wei price feed interface.
interface ISatWeiPriceFeed {
    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice() external view returns (uint256);

    /// @notice add a new ETH/BTC meidanizer to the internal ethBtcFeeds array
    function addEthBtcFeed(IMedianizer _ethBtcFeed) external;
}
"
    },
    "solidity/contracts/price-feed/SatWeiPriceFeed.sol": {
      "content": "pragma solidity 0.5.17;

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../external/IMedianizer.sol";
import "../interfaces/ISatWeiPriceFeed.sol";

/// @notice satoshi/wei price feed.
/// @dev Used ETH/USD medianizer values converted to sat/wei.
contract SatWeiPriceFeed is Ownable, ISatWeiPriceFeed {
    using SafeMath for uint256;

    bool private _initialized = false;
    address internal tbtcSystemAddress;

    IMedianizer[] private ethBtcFeeds;

    constructor() public {
    // solium-disable-previous-line no-empty-blocks
    }

    /// @notice Initialises the addresses of the ETHBTC price feeds.
    /// @param _tbtcSystemAddress Address of the `TBTCSystem` contract. Used for access control.
    /// @param _ETHBTCPriceFeed The ETHBTC price feed address.
    function initialize(
        address _tbtcSystemAddress,
        IMedianizer _ETHBTCPriceFeed
    )
        external onlyOwner
    {
        require(!_initialized, "Already initialized.");
        tbtcSystemAddress = _tbtcSystemAddress;
        ethBtcFeeds.push(_ETHBTCPriceFeed);
        _initialized = true;
    }

    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice()
        external onlyTbtcSystem view returns (uint256)
    {
        bool ethBtcActive;
        uint256 ethBtc;

        for(uint i = 0; i < ethBtcFeeds.length; i++){
            (ethBtc, ethBtcActive) = ethBtcFeeds[i].peek();
            if(ethBtcActive) {
                break;
            }
        }

        require(ethBtcActive, "Price feed offline");

        // convert eth/btc to sat/wei
        // We typecast down to uint128, because the first 128 bits of
        // the medianizer value is unrelated to the price.
        return uint256(10**28).div(uint256(uint128(ethBtc)));
    }

    /// @notice Get the first active Medianizer contract from the ethBtcFeeds array.
    /// @return The address of the first Active Medianizer. address(0) if none found
    function getWorkingEthBtcFeed() external view returns (address){
        bool ethBtcActive;

        for(uint i = 0; i < ethBtcFeeds.length; i++){
            (, ethBtcActive) = ethBtcFeeds[i].peek();
            if(ethBtcActive) {
                return address(ethBtcFeeds[i]);
            }
        }
        return address(0);
    }

    /// @notice Add _ethBtcFeed to internal ethBtcFeeds array.
    /// @dev IMedianizer must be active in order to add.
    function addEthBtcFeed(IMedianizer _ethBtcFeed) external onlyTbtcSystem {
        bool ethBtcActive;
        (, ethBtcActive) = _ethBtcFeed.peek();
        require(ethBtcActive, "Cannot add inactive feed");
        ethBtcFeeds.push(_ethBtcFeed);
    }

    /// @notice Function modifier ensures modified function is only called by tbtcSystemAddress.
    modifier onlyTbtcSystem(){
        require(msg.sender == tbtcSystemAddress, "Caller must be tbtcSystem contract");
        _;
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
    "solidity/contracts/system/TBTCSystemAuthority.sol": {
      "content": "pragma solidity 0.5.17;

/// @title  TBTC System Authority.
/// @notice Contract to secure function calls to the TBTC System contract.
/// @dev    The `TBTCSystem` contract address is passed as a constructor parameter.
contract TBTCSystemAuthority {

    address internal tbtcSystemAddress;

    /// @notice Set the address of the System contract on contract initialization.
    constructor(address _tbtcSystemAddress) public {
        tbtcSystemAddress = _tbtcSystemAddress;
    }

    /// @notice Function modifier ensures modified function is only called by TBTCSystem.
    modifier onlyTbtcSystem(){
        require(msg.sender == tbtcSystemAddress, "Caller must be tbtcSystem contract");
        _;
    }
}
"
    },
    "@summa-tx/relay-sol/contracts/Relay.sol": {
      "content": "pragma solidity ^0.5.10;

/** @title Relay */
/** @author Summa (https://summa.one) */

import {SafeMath} from "@summa-tx/bitcoin-spv-sol/contracts/SafeMath.sol";
import {BytesLib} from "@summa-tx/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@summa-tx/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {ValidateSPV} from "@summa-tx/bitcoin-spv-sol/contracts/ValidateSPV.sol";

interface IRelay {

    event Extension(bytes32 indexed _first, bytes32 indexed _last);
    event Reorg(bytes32 indexed _from, bytes32 indexed _to, bytes32 indexed _gcd);

    function isMostRecentAncestor(
        bytes32 _ancestor,
        bytes32 _left,
        bytes32 _right,
        uint256 _limit
    ) external view returns (bool);

    function getCurrentEpochDifficulty() external view returns (uint256);
    function getPrevEpochDifficulty() external view returns (uint256);
    function getRelayGenesis() external view returns (bytes32);
    function getBestKnownDigest() external view returns (bytes32);
    function getLastReorgCommonAncestor() external view returns (bytes32);

    function findHeight(bytes32 _digest) external view returns (uint256);

    function findAncestor(bytes32 _digest, uint256 _offset) external view returns (bytes32);

    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool);

    function heaviestFromAncestor(
        bytes32 _ancestor,
        bytes calldata _left,
        bytes calldata _right
    ) external view returns (bytes32);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool);

    function markNewHeaviest(
        bytes32 _ancestor,
        bytes calldata _currentBest,
        bytes calldata _newBest,
        uint256 _limit
    ) external returns (bool);
}

contract Relay is IRelay {
    using SafeMath for uint256;
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using ValidateSPV for bytes;

    // How often do we store the height?
    // A higher number incurs less storage cost, but more lookup cost
    uint32 public constant HEIGHT_INTERVAL = 4;

    bytes32 internal relayGenesis;
    bytes32 internal bestKnownDigest;
    bytes32 internal lastReorgCommonAncestor;
    mapping (bytes32 => bytes32) internal previousBlock;
    mapping (bytes32 => uint256) internal blockHeight;

    uint256 internal currentEpochDiff;
    uint256 internal prevEpochDiff;


    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _genesisHeader    The starting header
    /// @param  _height           The starting height
    /// @param  _periodStart      The hash of the first header in the genesis epoch
    constructor(bytes memory _genesisHeader, uint256 _height, bytes32 _periodStart) public {
        require(_genesisHeader.length == 80, "Stop being dumb");
        bytes32 _genesisDigest = _genesisHeader.hash256();

        require(
            _periodStart & bytes32(0x0000000000000000000000000000000000000000000000000000000000ffffff) == bytes32(0),
            "Period start hash does not have work. Hint: wrong byte order?");

        relayGenesis = _genesisDigest;
        bestKnownDigest = _genesisDigest;
        lastReorgCommonAncestor = _genesisDigest;
        blockHeight[_genesisDigest] = _height;
        blockHeight[_periodStart] = _height.sub(_height % 2016);

        currentEpochDiff = _genesisHeader.extractDifficulty();
    }

    /// @notice             Adds headers to storage after validating
    /// @dev                We check integrity and consistency of the header chain
    /// @param  _anchor     The header immediately preceeding the new chain
    /// @param  _headers    A tightly-packed list of new 80-byte Bitcoin headers to record
    /// @param  _internal   True if called internally from addHeadersWithRetarget, false otherwise
    /// @return             True if successfully written, error otherwise
    function _addHeaders(bytes memory _anchor, bytes memory _headers, bool _internal) internal returns (bool) {
        uint256 _height;
        bytes memory _header;
        bytes32 _currentDigest;
        bytes32 _previousDigest = _anchor.hash256();

        uint256 _target = _headers.slice(0, 80).extractTarget();
        uint256 _anchorHeight = _findHeight(_previousDigest);  /* NB: errors if unknown */

        require(
            _internal || _anchor.extractTarget() == _target,
            "Unexpected retarget on external call");
        require(_headers.length % 80 == 0, "Header array length must be divisible by 80");

        /*
        NB:
        1. check that the header has sufficient work
        2. check that headers are in a coherent chain (no retargets, hash links good)
        3. Store the block connection
        4. Store the height
        */
        for (uint256 i = 0; i < _headers.length / 80; i = i.add(1)) {
            _header = _headers.slice(i.mul(80), 80);
            _height = _anchorHeight.add(i + 1);
            _currentDigest = _header.hash256();

            /*
            NB:
            if the block is already authenticated, we don't need to a work check
            Or write anything to state. This saves gas
            */
            if (previousBlock[_currentDigest] == bytes32(0)) {
                require(
                    abi.encodePacked(_currentDigest).reverseEndianness().bytesToUint() <= _target,
                    "Header work is insufficient");
                previousBlock[_currentDigest] = _previousDigest;
                if (_height % HEIGHT_INTERVAL == 0) {
                    /*
                    NB: We store the height only every 4th header to save gas
                    */
                    blockHeight[_currentDigest] = _height;
                }
            }

            /* NB: we do still need to make chain level checks tho */
            require(_header.extractTarget() == _target, "Target changed unexpectedly");
            require(_header.validateHeaderPrevHash(_previousDigest), "Headers do not form a consistent chain");

            _previousDigest = _currentDigest;
        }

        emit Extension(
            _anchor.hash256(),
            _currentDigest);
        return true;
    }

    /// @notice             Adds headers to storage after validating
    /// @dev                We check integrity and consistency of the header chain
    /// @param  _anchor     The header immediately preceeding the new chain
    /// @param  _headers    A tightly-packed list of 80-byte Bitcoin headers
    /// @return             True if successfully written, error otherwise
    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool) {
        return _addHeaders(_anchor, _headers, false);
    }

    /// @notice                       Adds headers to storage, performs additional validation of retarget
    /// @dev                          Checks the retarget, the heights, and the linkage
    /// @param  _oldPeriodStartHeader The first header in the difficulty period being closed
    /// @param  _oldPeriodEndHeader   The last header in the difficulty period being closed
    /// @param  _headers              A tightly-packed list of 80-byte Bitcoin headers
    /// @return                       True if successfully written, error otherwise
    function addHeadersWithRetarget(
        bytes calldata _oldPeriodStartHeader,
        bytes calldata _oldPeriodEndHeader,
        bytes calldata _headers
    ) external returns (bool) {
        return _addHeadersWithRetarget(_oldPeriodStartHeader, _oldPeriodEndHeader, _headers);
    }

    /// @notice                       Adds headers to storage, performs additional validation of retarget
    /// @dev                          Checks the retarget, the heights, and the linkage
    /// @param  _oldPeriodStartHeader The first header in the difficulty period being closed
    /// @param  _oldPeriodEndHeader   The last header in the difficulty period being closed
    /// @param  _headers              A tightly-packed list of 80-byte Bitcoin headers
    /// @return                       True if successfully written, error otherwise
    function _addHeadersWithRetarget(
        bytes memory _oldPeriodStartHeader,
        bytes memory _oldPeriodEndHeader,
        bytes memory _headers
    ) internal returns (bool) {
        /* NB: requires that both blocks are known */
        uint256 _startHeight = _findHeight(_oldPeriodStartHeader.hash256());
        uint256 _endHeight = _findHeight(_oldPeriodEndHeader.hash256());

        /* NB: retargets should happen at 2016 block intervals */
        require(
            _endHeight % 2016 == 2015,
            "Must provide the last header of the closing difficulty period");
        require(
            _endHeight == _startHeight.add(2015),
            "Must provide exactly 1 difficulty period");
        require(
            _oldPeriodStartHeader.extractDifficulty() == _oldPeriodEndHeader.extractDifficulty(),
            "Period header difficulties do not match");

        /* NB: This comparison looks weird because header nBits encoding truncates targets */
        bytes memory _newPeriodStart = _headers.slice(0, 80);
        uint256 _actualTarget = _newPeriodStart.extractTarget();
        uint256 _expectedTarget = BTCUtils.retargetAlgorithm(
            _oldPeriodStartHeader.extractTarget(),
            _oldPeriodStartHeader.extractTimestamp(),
            _oldPeriodEndHeader.extractTimestamp()
        );
        require(
            (_actualTarget & _expectedTarget) == _actualTarget,
            "Invalid retarget provided");

        // If the current known prevEpochDiff doesn't match, and this old period is near the chaintip/
        // update the stored prevEpochDiff
        // Don't update if this is a deep past epoch
        uint256 _oldDiff = _oldPeriodStartHeader.extractDifficulty();
        if (prevEpochDiff != _oldDiff && _endHeight > _findHeight(bestKnownDigest).sub(2016)) {
          prevEpochDiff = _oldDiff;
        }

        // Pass all but the first through to be added
        return _addHeaders(_oldPeriodEndHeader, _headers, true);
    }

    /// @notice         Finds the height of a header by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header
    function _findHeight(bytes32 _digest) internal view returns (uint256) {
        uint256 _height = 0;
        bytes32 _current = _digest;
        for (uint256 i = 0; i < HEIGHT_INTERVAL + 1; i = i.add(1)) {
            _height = blockHeight[_current];
            if (_height == 0) {
                _current = previousBlock[_current];
            } else {
                return _height.add(i);
            }
        }
        revert("Unknown block");
    }

    /// @notice         Finds the height of a header by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function findHeight(bytes32 _digest) external view returns (uint256) {
        return _findHeight(_digest);
    }

    /// @notice         Finds an ancestor for a block by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function _findAncestor(bytes32 _digest, uint256 _offset) internal view returns (bytes32) {
        bytes32 _current = _digest;
        for (uint256 i = 0; i < _offset; i = i.add(1)) {
            _current = previousBlock[_current];
        }
        require(_current != bytes32(0), "Unknown ancestor");
        return _current;
    }

    /// @notice         Finds an ancestor for a block by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function findAncestor(bytes32 _digest, uint256 _offset) external view returns (bytes32) {
        return _findAncestor(_digest, _offset);
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective ancestor
    /// @param _descendant  The descendant to check
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
    function _isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) internal view returns (bool) {
        bytes32 _current = _descendant;
        /* NB: 200 gas/read, so gas is capped at ~200 * limit */
        for (uint256 i = 0; i < _limit; i = i.add(1)) {
            if (_current == _ancestor) {
                return true;
            }
            _current = previousBlock[_current];
        }
        return false;
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective ancestor
    /// @param _descendant  The descendant to check
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool) {
        return _isAncestor(_ancestor, _descendant, _limit);
    }

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _ancestor         The digest of the most recent common ancestor
    /// @param  _currentBest      The 80-byte header referenced by bestKnownDigest
    /// @param  _newBest          The 80-byte header to mark as the new best
    /// @param  _limit            Limit the amount of traversal of the chain
    /// @return                   True if successfully updates bestKnownDigest, error otherwise
    function _markNewHeaviest(
        bytes32 _ancestor,
        bytes memory _currentBest,
        bytes memory _newBest,
        uint256 _limit
    ) internal returns (bool) {
        bytes32 _newBestDigest = _newBest.hash256();
        bytes32 _currentBestDigest = _currentBest.hash256();
        require(_currentBestDigest == bestKnownDigest, "Passed in best is not best known");
        require(
            previousBlock[_newBestDigest] != bytes32(0),
            "New best is unknown");
        require(
            _isMostRecentAncestor(_ancestor, bestKnownDigest, _newBestDigest, _limit),
            "Ancestor must be heaviest common ancestor");
        require(
            _heaviestFromAncestor(_ancestor, _currentBest, _newBest) == _newBestDigest,
            "New best hash does not have more work than previous");

        bestKnownDigest = _newBestDigest;
        lastReorgCommonAncestor = _ancestor;

        uint256 _newDiff = _newBest.extractDifficulty();
        if (_newDiff != currentEpochDiff) {
          currentEpochDiff = _newDiff;
        }

        emit Reorg(
            _currentBestDigest,
            _newBestDigest,
            _ancestor);
        return true;
    }

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _ancestor         The digest of the most recent common ancestor
    /// @param  _currentBest      The 80-byte header referenced by bestKnownDigest
    /// @param  _newBest          The 80-byte header to mark as the new best
    /// @param  _limit            Limit the amount of traversal of the chain
    /// @return                   True if successfully updates bestKnownDigest, error otherwise
    function markNewHeaviest(
        bytes32 _ancestor,
        bytes calldata _currentBest,
        bytes calldata _newBest,
        uint256 _limit
    ) external returns (bool) {
        return _markNewHeaviest(_ancestor, _currentBest, _newBest, _limit);
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function _isMostRecentAncestor(
        bytes32 _ancestor,
        bytes32 _left,
        bytes32 _right,
        uint256 _limit
    ) internal view returns (bool) {
        /* NB: sure why not */
        if (_ancestor == _left && _ancestor == _right) {
            return true;
        }

        bytes32 _leftCurrent = _left;
        bytes32 _rightCurrent = _right;
        bytes32 _leftPrev = _left;
        bytes32 _rightPrev = _right;

        for(uint256 i = 0; i < _limit; i = i.add(1)) {
            if (_leftPrev != _ancestor) {
                _leftCurrent = _leftPrev;  // cheap
                _leftPrev = previousBlock[_leftPrev];  // expensive
            }
            if (_rightPrev != _ancestor) {
                _rightCurrent = _rightPrev;  // cheap
                _rightPrev = previousBlock[_rightPrev];  // expensive
            }
        }
        if (_leftCurrent == _rightCurrent) {return false;} /* NB: If the same, they're a nearer ancestor */
        if (_leftPrev != _rightPrev) {return false;} /* NB: Both must be ancestor */
        return true;
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function isMostRecentAncestor(
        bytes32 _ancestor,
        bytes32 _left,
        bytes32 _right,
        uint256 _limit
    ) external view returns (bool) {
        return _isMostRecentAncestor(_ancestor, _left, _right, _limit);
    }

    /// @notice             Decides which header is heaviest from the ancestor
    /// @dev                Does not support reorgs above 2017 blocks (:
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function _heaviestFromAncestor(
        bytes32 _ancestor,
        bytes memory _left,
        bytes memory _right
    ) internal view returns (bytes32) {
        uint256 _ancestorHeight = _findHeight(_ancestor);
        uint256 _leftHeight = _findHeight(_left.hash256());
        uint256 _rightHeight = _findHeight(_right.hash256());

        require(
            _leftHeight >= _ancestorHeight && _rightHeight >= _ancestorHeight,
            "A descendant height is below the ancestor height");

        /* NB: we can shortcut if one block is in a new difficulty window and the other isn't */
        uint256 _nextPeriodStartHeight = _ancestorHeight.add(2016).sub(_ancestorHeight % 2016);
        bool _leftInPeriod = _leftHeight < _nextPeriodStartHeight;
        bool _rightInPeriod = _rightHeight < _nextPeriodStartHeight;

        /*
        NB:
        1. Left is in a new window, right is in the old window. Left is heavier
        2. Right is in a new window, left is in the old window. Right is heavier
        3. Both are in the same window, choose the higher one
        4. They're in different new windows. Choose the heavier one
        */
        if (!_leftInPeriod && _rightInPeriod) {return _left.hash256();}
        if (_leftInPeriod && !_rightInPeriod) {return _right.hash256();}
        if (_leftInPeriod && _rightInPeriod) {
            return _leftHeight >= _rightHeight ? _left.hash256() : _right.hash256();
        } else {  // if (!_leftInPeriod && !_rightInPeriod) {
            if (((_leftHeight % 2016).mul(_left.extractDifficulty())) <
                (_rightHeight % 2016).mul(_right.extractDifficulty())) {
                return _right.hash256();
            } else {
                return _left.hash256();
            }
        }
    }

    /// @notice             Decides which header is heaviest from the ancestor
    /// @dev                Does not support reorgs above 2017 blocks (:
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function heaviestFromAncestor(
        bytes32 _ancestor,
        bytes calldata _left,
        bytes calldata _right
    ) external view returns (bytes32) {
        return _heaviestFromAncestor(_ancestor, _left, _right);
    }

    /// @notice     Getter for currentEpochDiff
    /// @dev        This is updated when a new heavist header has a new diff
    /// @return     The difficulty of the bestKnownDigest
    function getCurrentEpochDifficulty() external view returns (uint256) {
      return currentEpochDiff;
    }
    /// @notice     Getter for prevEpochDiff
    /// @dev        This is updated when a difficulty change is accepted
    /// @return     The difficulty of the previous epoch
    function getPrevEpochDifficulty() external view returns (uint256) {
      return prevEpochDiff;
    }

    /// @notice     Getter for relayGenesis
    /// @dev        This is an initialization parameter
    /// @return     The hash of the first block of the relay
    function getRelayGenesis() public view returns (bytes32) {
        return relayGenesis;
    }

    /// @notice     Getter for bestKnownDigest
    /// @dev        This updated only by calling markNewHeaviest
    /// @return     The hash of the best marked chain tip
    function getBestKnownDigest() public view returns (bytes32) {
        return bestKnownDigest;
    }

    /// @notice     Getter for relayGenesis
    /// @dev        This is updated only by calling markNewHeaviest
    /// @return     The hash of the shared ancestor of the most recent fork
    function getLastReorgCommonAncestor() public view returns (bytes32) {
        return lastReorgCommonAncestor;
    }
}
"
    },
    "solidity/contracts/system/KeepFactorySelection.sol": {
      "content": "pragma solidity 0.5.17;

import {IBondedECDSAKeepFactory} from "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol";

/// @title Bonded ECDSA keep factory selection strategy.
/// @notice The strategy defines the algorithm for selecting a factory. tBTC
/// uses two bonded ECDSA keep factories, selecting one of them for each new
/// deposit being opened.
interface KeepFactorySelector {

    /// @notice Selects keep factory for the new deposit.
    /// @param _seed Request seed.
    /// @param _keepStakeFactory Regular, KEEP-stake based keep factory.
    /// @param _ethStakeFactory Fully backed, ETH-stake based keep factory.
    /// @return The selected keep factory.
    function selectFactory(
        uint256 _seed,
        IBondedECDSAKeepFactory _keepStakeFactory,
        IBondedECDSAKeepFactory _ethStakeFactory
    ) external view returns (IBondedECDSAKeepFactory);
}

/// @title Bonded ECDSA keep factory selection library.
/// @notice tBTC uses two bonded ECDSA keep factories: one based on KEEP stake
/// and ETH bond, and another based on ETH stake and ETH bond. The library holds
/// a reference to both factories as well as a reference to a selection strategy
/// deciding which factory to choose for the new deposit being opened.
library KeepFactorySelection {

    struct Storage {
        uint256 requestCounter;

        IBondedECDSAKeepFactory selectedFactory;

        KeepFactorySelector factorySelector;

        // Standard ECDSA keep factory: KEEP stake and ETH bond.
        // Guaranteed to be set for initialized factory.
        IBondedECDSAKeepFactory keepStakeFactory;

        // Fully backed ECDSA keep factory: ETH stake and ETH bond.
        IBondedECDSAKeepFactory ethStakeFactory;
    }

    /// @notice Initializes the library with the default KEEP-stake-based
    /// factory. The default factory is guaranteed to be set and this function
    /// must be called when creating contract using this library.
    /// @dev This function can be called only one time.
    function initialize(
        Storage storage _self,
        IBondedECDSAKeepFactory _defaultFactory
    ) internal {
        require(
            address(_self.keepStakeFactory) == address(0),
            "Already initialized"
        );

        _self.keepStakeFactory = IBondedECDSAKeepFactory(_defaultFactory);
        _self.selectedFactory = _self.keepStakeFactory;
    }

    /// @notice Returns the selected keep factory.
    /// This function guarantees that the same factory is returned for every
    /// call until selectFactoryAndRefresh is executed. This lets to evaluate
    /// open keep fee estimate on the same factory that will be used later for
    /// opening a new keep (fee estimate and open keep requests are two
    /// separate calls).
    /// @return Selected keep factory. The same vale will be returned for every
    /// call of this function until selectFactoryAndRefresh is executed.
    function selectFactory(
        Storage storage _self
    ) public view returns (IBondedECDSAKeepFactory) {
        return _self.selectedFactory;
    }

    /// @notice Returns the selected keep factory and refreshes the choice
    /// for the next select call. The value returned by this function has been
    /// evaluated during the previous call. This lets to return the same value
    /// from selectFactory and selectFactoryAndRefresh, thus, allowing to use
    /// the same factory for which open keep fee estimate was evaluated (fee
    /// estimate and open keep requests are two separate calls).
    /// @return Selected keep factory.
    function selectFactoryAndRefresh(
        Storage storage _self
    ) public returns (IBondedECDSAKeepFactory) {
        IBondedECDSAKeepFactory factory = selectFactory(_self);
        refreshFactory(_self);

        return factory;
    }

    /// @notice Refreshes the keep factory choice. If either ETH-stake factory
    /// or selection strategy is not set, KEEP-stake factory is selected.
    /// Otherwise, calls selection strategy providing addresses of both
    /// factories to make a choice. Additionally, passes the selection seed
    /// evaluated from the current request counter value.
    function refreshFactory(Storage storage _self) internal {
        if (
            address(_self.ethStakeFactory) == address(0) ||
            address(_self.factorySelector) == address(0)
        ) {
            // KEEP-stake factory is guaranteed to be there. If the selection
            // can not be performed, this is the default choice.
            _self.selectedFactory = _self.keepStakeFactory;
            return;
        }

        _self.requestCounter++;
        uint256 seed = uint256(
            keccak256(abi.encodePacked(address(this), _self.requestCounter))
        );
        _self.selectedFactory = _self.factorySelector.selectFactory(
            seed,
            _self.keepStakeFactory,
            _self.ethStakeFactory
        );
    }

    /// @notice Sets the address of the fully backed, ETH-stake based keep
    /// factory. KeepFactorySelection can work without the fully-backed keep
    /// factory set, always selecting the default KEEP-stake-based factory.
    /// Once both fully-backed keep factory and factory selection strategy are
    /// set, KEEP-stake-based factory is no longer the default choice and it is
    /// up to the selection strategy to decide which factory should be chosen.
    /// @dev Can be called only one time!
    /// @param _fullyBackedFactory Address of the fully-backed, ETH-stake based
    /// keep factory.
    function setFullyBackedKeepFactory(
        Storage storage _self,
        address _fullyBackedFactory
    ) internal {
        require(
            address(_self.ethStakeFactory) == address(0),
            "Fully backed factory already set"
        );
        require(
            address(_fullyBackedFactory) != address(0),
            "Invalid address"
        );

        _self.ethStakeFactory = IBondedECDSAKeepFactory(_fullyBackedFactory);
    }

    /// @notice Sets the address of the keep factory selection strategy contract.
    /// KeepFactorySelection can work without the keep factory selection
    /// strategy set, always selecting the default KEEP-stake-based factory.
    /// Once both fully-backed keep factory and factory selection strategy are
    /// set, KEEP-stake-based factory is no longer the default choice and it is
    /// up to the selection strategy to decide which factory should be chosen.
    /// @dev Can be called only one time!
    /// @param _factorySelector Address of the keep factory selection strategy.
    function setKeepFactorySelector(
        Storage storage _self,
        address _factorySelector
    ) internal {
        require(
            address(_self.factorySelector) == address(0),
            "Factory selector already set"
        );
        require(
            address(_factorySelector) != address(0),
            "Invalid address"
        );

        _self.factorySelector = KeepFactorySelector(_factorySelector);
    }
}
"
    },
    "@summa-tx/bitcoin-spv-sol/contracts/CheckBitcoinSigs.sol": {
      "content": "pragma solidity ^0.5.10;

/** @title CheckBitcoinSigs */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {BTCUtils} from "./BTCUtils.sol";


library CheckBitcoinSigs {

    using BytesLib for bytes;
    using BTCUtils for bytes;

    /// @notice          Derives an Ethereum Account address from a pubkey
    /// @dev             The address is the last 20 bytes of the keccak256 of the address
    /// @param _pubkey   The public key X & Y. Unprefixed, as a 64-byte array
    /// @return          The account address
    function accountFromPubkey(bytes memory _pubkey) internal pure returns (address) {
        require(_pubkey.length == 64, "Pubkey must be 64-byte raw, uncompressed key.");

        // keccak hash of uncompressed unprefixed pubkey
        bytes32 _digest = keccak256(_pubkey);
        return address(uint256(_digest));
    }

    /// @notice          Calculates the p2wpkh output script of a pubkey
    /// @dev             Compresses keys to 33 bytes as required by Bitcoin
    /// @param _pubkey   The public key, compressed or uncompressed
    /// @return          The p2wkph output script
    function p2wpkhFromPubkey(bytes memory _pubkey) internal pure returns (bytes memory) {
        bytes memory _compressedPubkey;
        uint8 _prefix;

        if (_pubkey.length == 64) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice(0, 32));
        } else if (_pubkey.length == 65) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice(1, 32));
        } else {
            _compressedPubkey = _pubkey;
        }

        require(_compressedPubkey.length == 33, "Witness PKH requires compressed keys");

        bytes memory _pubkeyHash = _compressedPubkey.hash160();
        return abi.encodePacked(hex"0014", _pubkeyHash);
    }

    /// @notice          checks a signed message's validity under a pubkey
    /// @dev             does this using ecrecover because Ethereum has no soul
    /// @param _pubkey   the public key to check (64 bytes)
    /// @param _digest   the message digest signed
    /// @param _v        the signature recovery value
    /// @param _r        the signature r value
    /// @param _s        the signature s value
    /// @return          true if signature is valid, else false
    function checkSig(
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");
        address _expected = accountFromPubkey(_pubkey);
        address _actual = ecrecover(_digest, _v, _r, _s);
        return _actual == _expected;
    }

    /// @notice                     checks a signed message against a bitcoin p2wpkh output script
    /// @dev                        does this my verifying the p2wpkh matches an ethereum account
    /// @param _p2wpkhOutputScript  the bitcoin output script
    /// @param _pubkey              the uncompressed, unprefixed public key to check
    /// @param _digest              the message digest signed
    /// @param _v                   the signature recovery value
    /// @param _r                   the signature r value
    /// @param _s                   the signature s value
    /// @return                     true if signature is valid, else false
    function checkBitcoinSig(
        bytes memory _p2wpkhOutputScript,
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");

        bool _isExpectedSigner = keccak256(p2wpkhFromPubkey(_pubkey)) == keccak256(_p2wpkhOutputScript);  // is it the expected signer?
        if (!_isExpectedSigner) {return false;}

        bool _sigResult = checkSig(_pubkey, _digest, _v, _r, _s);
        return _sigResult;
    }

    /// @notice             checks if a message is the sha256 preimage of a digest
    /// @dev                this is NOT the hash256!  this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isSha256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return sha256(_candidate) == _digest;
    }

    /// @notice             checks if a message is the keccak256 preimage of a digest
    /// @dev                this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isKeccak256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return keccak256(_candidate) == _digest;
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin output script
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputScript    the length-prefixed output script
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhSpendSighash(
        bytes memory _outpoint,  // 36 byte UTXO id
        bytes20 _inputPKH,       // 20 byte hash160
        bytes8 _inputValue,      // 8-byte LE
        bytes8 _outputValue,     // 8-byte LE
        bytes memory _outputScript    // lenght-prefixed output script
    ) internal pure returns (bytes32) {
        // Fixes elements to easily make a 1-in 1-out sighash digest
        // Does not support timelocks
        bytes memory _scriptCode = abi.encodePacked(
            hex"1976a914",  // length, dup, hash160, pkh_length
            _inputPKH,
            hex"88ac");  // equal, checksig
        bytes32 _hashOutputs = abi.encodePacked(
            _outputValue,  // 8-byte LE
            _outputScript).hash256();
        bytes memory _sighashPreimage = abi.encodePacked(
            hex"01000000",  // version
            _outpoint.hash256(),  // hashPrevouts
            hex"8cb9012517c817fead650287d61bdd9c68803b6bf9c64133dcab3e65b5a50cb9",  // hashSequence(00000000)
            _outpoint,  // outpoint
            _scriptCode,  // p2wpkh script code
            _inputValue,  // value of the input in 8-byte LE
            hex"00000000",  // input nSequence
            _hashOutputs,  // hash of the single output
            hex"00000000",  // nLockTime
            hex"01000000"  // SIGHASH_ALL
        );
        return _sighashPreimage.hash256();
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin output script
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhToWpkhSighash(
        bytes memory _outpoint,  // 36 byte UTXO id
        bytes20 _inputPKH,  // 20 byte hash160
        bytes8 _inputValue,  // 8-byte LE
        bytes8 _outputValue,  // 8-byte LE
        bytes20 _outputPKH  // 20 byte hash160
    ) internal pure returns (bytes32) {
        return wpkhSpendSighash(
          _outpoint,
          _inputPKH,
          _inputValue,
          _outputValue,
          abi.encodePacked(
              hex"160014",  // wpkh tag
              _outputPKH)
          );
    }

    /// @notice                 Preserved for API compatibility with older version
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin output script
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function oneInputOneOutputSighash(
      bytes memory _outpoint,  // 36 byte UTXO id
      bytes20 _inputPKH,  // 20 byte hash160
      bytes8 _inputValue,  // 8-byte LE
      bytes8 _outputValue,  // 8-byte LE
      bytes20 _outputPKH  // 20 byte hash160
    ) internal pure returns (bytes32) {
      return wpkhToWpkhSighash(_outpoint, _inputPKH, _inputValue, _outputValue, _outputPKH);
    }

}
"
    }
  },
  "settings": {
    "libraries": {
      "solidity/contracts/deposit/Deposit.sol": {
        "TBTCConstants": "0x5f8F05622228c37E245d71Fa959E458C6e26538E",
        "DepositUtils": "0x1C1469f4F95f253070636314D1c760BC8e8A0B99",
        "DepositStates": "0x80F8CAC84EC3E16a5891Cb255EA731D7b121CEFD",
        "DepositRedemption": "0x03bC6CDE6be15AA7D366AFd6925FD92FF60e1768",
        "DepositLiquidation": "0xAd23d386Ff5bE971fcF57f34f477217f91BbC44D",
        "DepositFunding": "0x4DF881De3552BCB6A9c0bEDb9EAF22c5c5A2c88C"
      }
    },
    "metadata": {
      "useLiteralContent": true
    },
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
    }
  }
}}