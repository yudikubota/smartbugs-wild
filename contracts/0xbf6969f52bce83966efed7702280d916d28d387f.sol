{"Address.sol":{"content":"pragma solidity ^0.5.0;

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
"},"CapperRole.sol":{"content":"pragma solidity ^0.5.0;

import "../Roles.sol";

contract CapperRole {
    using Roles for Roles.Role;

    event CapperAdded(address indexed account);
    event CapperRemoved(address indexed account);

    Roles.Role private _cappers;

    constructor () internal {
        _addCapper(msg.sender);
    }

    modifier onlyCapper() {
        require(isCapper(msg.sender), "CapperRole: caller does not have the Capper role");
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return _cappers.has(account);
    }

    function addCapper(address account) public onlyCapper {
        _addCapper(account);
    }

    function renounceCapper() public {
        _removeCapper(msg.sender);
    }

    function _addCapper(address account) internal {
        _cappers.add(account);
        emit CapperAdded(account);
    }

    function _removeCapper(address account) internal {
        _cappers.remove(account);
        emit CapperRemoved(account);
    }
}
"},"CrowdliExchangeVault.sol":{"content":"pragma solidity 0.5.0;

import "./CrowdliSTO.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

/**
* This contract can be in one of the following states:
* - Active      The contract is open to new payment requests
* - Closed      No new payments will be accepted nor payments can be rejected though refunds can be claimed for payments that had been prior to closing.
*/
contract CrowdliExchangeVault is Ownable, Pausable {

    struct EtherPayment {
        address from;
        uint64 date;
        PaymentStatus status;
        uint weiAmount;
        uint pendingTokens;
        uint mintedTokens;
        uint exchangeRate;
    }

    struct ExchangeOrder {
        uint256 exchangeRate;
        uint64 date;
        address exchangeWallet;
        ExchangeStatus status;
    }
    
    /**
     * Defines the statuses an exchange order can have
     */
    enum ExchangeStatus { Pending, Confirmed }

    /**
    * Defines the statuses an payment can have
    */
    enum PaymentStatus { None, Requested, Accepted, TokensDelivered, Rejected, Refunded, PurchaseFailed }
    
    /**
    * The safe math library for safety math operations provided by Zeppelin
    */
    using SafeMath for uint256;

    /**
    * Holds all exchange orders, each of them containing multiple payments
    */
   	ExchangeOrder[] public exchangeOrders;
   
    /**
    * Holds all ether payments in different states (PaymentStatu
    */
    EtherPayment[] public payments;
    
    /**
     * A dictionary holind the number of requested payment per investor
     */
    mapping(address => uint) public nrRequestedPayments; 
    
    /**
     * A dictionary to lookup the related payments (paymentsIds: uint[]) for a given exchange order (exchangeOrderId: uint)
     */
    mapping(uint => uint[]) private exchangeOrderForPayments; //exchangeOrderId => array of paymentsIds
    
    
    address public paymentConfirmer;
    
    /**
     * Used to process payments once they are confirmed 
     */
    CrowdliSTO private crowdliSTO;
    
     /**
     * Event will be fired whenever payments processing is enabled
     * @param sender The account that has enabled the payment processing
     */
    event PaymentsEnabled(address indexed sender);
    
    /**
     * Event will be fired whenever payments processing is disabled
     * @param sender The account that has disabled the payment processing
     */
    event PaymentsDisabled(address indexed sender);
    event EtherPaymentRefunded(address indexed beneficiary, uint256 weiAmount);
    event EtherPaymentRequested(address indexed beneficiary, uint256 weiAmount, uint paymentIndex);
    event EtherPaymentRejected(address indexed sender, uint etherPaymentIndex);
    event LogGasUsed(address indexed sender, uint indexed value);
    event EtherPaymentPurchaseFailed(address indexed sender, uint indexed etherPaymentIndex);
    event OrderCreated(address indexed sender, uint[] payments);
    event OrderConfirmed(address indexed sender, uint indexed etherPaymentIndex);

	modifier isInInvestmentState() {
         require(crowdliSTO.hasState(CrowdliSTO.States.Investment) || !crowdliSTO.paused(), "bot in state investment");
        _;
    }

    modifier onlyCrowdliSTO() {
        require((msg.sender == address(crowdliSTO)), "Sender should be CrowdliSTO");
        _;
    }
    
    modifier onlyEtherPaymentConfirmer() {
        require((msg.sender == paymentConfirmer), "Sender should be EtherPaymentConfirmer");
        _;
    }
    
    constructor(address _paymentConfirmer) public {
        paymentConfirmer = _paymentConfirmer; 
    }
    
	function setCrowdliSTO(CrowdliSTO _crowdliSTO) external onlyOwner {
    	crowdliSTO = _crowdliSTO;
    }

	function initExchangeVault(address _directorsBoard, address _crowdliSTO) external onlyOwner{
    	crowdliSTO = CrowdliSTO(_crowdliSTO);
    	transferOwnership(_crowdliSTO);
    	addPauser(_directorsBoard);
    	addPauser(_crowdliSTO);
    }
    
    function confirmMintedTokensForPayment(uint paymentId, uint _mintedTokens) external onlyOwner {
        payments[paymentId].mintedTokens = payments[paymentId].mintedTokens.add(_mintedTokens);
    }
    /**
    * @dev The ether provided by the investor will be collected for a new fiat exchange order will be triggered by the owner
    * @dev Since the exact conversion rate that will be used for the fiat exchange is unknown the tokens will be minted AFTER once the order is completed
    */

    function requestPayment() external whenNotPaused payable  {
        uint[] memory tokenStatement = crowdliSTO.calculateTokenStatementEther(msg.sender, msg.value, CrowdliSTO.Currency.ETH, false, 0); 
        // only process if validation code == OK
        require(CrowdliSTO.TokenStatementValidation(tokenStatement[8]) == CrowdliSTO.TokenStatementValidation.OK, crowdliSTO.resolvePaymentError(CrowdliSTO.TokenStatementValidation(tokenStatement[8])));
        
        payments.push(EtherPayment(msg.sender, uint64(now), PaymentStatus.Requested, msg.value, 0, 0, 0));
        nrRequestedPayments[msg.sender] = nrRequestedPayments[msg.sender].add(1);
        emit EtherPaymentRequested(msg.sender, msg.value, payments.length.sub(1));
    }
    
    /**
    * @dev An investor can be subsequently rejected if the AML and PEP checks were negative
    */
    function rejectPayment(uint[] calldata _paymentIds) external onlyEtherPaymentConfirmer {
        for(uint id = 0; id < _paymentIds.length; id++){
        	uint paymentId = _paymentIds[id];
            // we only allow payments that have not been confirmed, rejected or refunded yet
            require(payments[paymentId].status == PaymentStatus.Requested, "Payment must be in state Requested");
    
            // mark ether payment as rejected and therby allowing the investor to claim refund
            payments[paymentId].status = PaymentStatus.Rejected;
            
            nrRequestedPayments[payments[paymentId].from] = nrRequestedPayments[payments[paymentId].from].sub(1);
            // fire an event so the investor can be informed that his payment was rejected
            emit EtherPaymentRejected(payments[paymentId].from, paymentId);
        }
    }

    /**
    * @dev Once an investor has been rejected a refund can be claimed
    */
    function refundPayment(uint index) external {
    
        EtherPayment storage etherPayment = payments[index];
        uint256 depositedValue = etherPayment.weiAmount;

        // only allow refund for payments which have been rejected 
        require((etherPayment.from == msg.sender) || (msg.sender == paymentConfirmer), "Refund are not enabled for sender");
        require(etherPayment.status == PaymentStatus.Rejected , "etherPayment.status should be PaymentStatus.Rejected");
		require(address(this).balance >= depositedValue , "Exchange Vault balance doesn't have enough funds.");
        // mark ether payment status to refunded
        etherPayment.status = PaymentStatus.Refunded;

        // send the ether back to investors address
        msg.sender.transfer(depositedValue);

        emit EtherPaymentRefunded(msg.sender, depositedValue);
    }

    /**
     * @param _exchangeWallet The wallet of the exchange provider where the ether will be sent for FIAT exchange
     */
    function createOrder(address payable _exchangeWallet, uint[] calldata _paymentsToAccept) external whenNotPaused onlyEtherPaymentConfirmer isInInvestmentState {
        require(payments.length > 0, "At least one payment is required to exchange");
        ExchangeOrder memory exchangeOrder = ExchangeOrder(0, uint64(now), _exchangeWallet, ExchangeStatus.Pending);
        exchangeOrders.push(exchangeOrder);
        uint weiAmountForTransfering = 0;
        // iterate through all payments which are not assigned to an exchange order
       	uint[] storage orderForPaymentIds = exchangeOrderForPayments[exchangeOrders.length-1];
        for (uint64 i = 0; i < _paymentsToAccept.length; i++) {
            uint paymentId = _paymentsToAccept[i];
            EtherPayment storage etherPayment = payments[paymentId];
            require(etherPayment.status == PaymentStatus.Requested, "should be in status requested"); 
            etherPayment.status = PaymentStatus.Accepted;
            orderForPaymentIds.push(paymentId);
            processPayment(paymentId);
            weiAmountForTransfering = weiAmountForTransfering.add(etherPayment.weiAmount);
        }
        emit OrderCreated(msg.sender, orderForPaymentIds);
        _exchangeWallet.transfer(weiAmountForTransfering);
    }

	/**
	* buy tokens on behalf of the investor
	*/
	function processPayment(uint _paymentId) internal {
		EtherPayment storage etherPayment = payments[_paymentId];
	    nrRequestedPayments[etherPayment.from] = nrRequestedPayments[etherPayment.from].sub(1);
	    crowdliSTO.processEtherPayment(etherPayment.from, etherPayment.weiAmount, _paymentId);
	    etherPayment.status = PaymentStatus.TokensDelivered;
	    etherPayment.exchangeRate = crowdliSTO.exchangeRate();
    }
    
    function confirmOrder(uint64 _orderIndex, uint256 _exchangeRate) external whenNotPaused onlyEtherPaymentConfirmer {
        require(_orderIndex < exchangeOrders.length, "_orderIndex is too high");
        ExchangeOrder storage exchangeOrder = exchangeOrders[_orderIndex];
        require(exchangeOrder.status != ExchangeStatus.Confirmed, "exchangeOrder.status is confirmed");
        exchangeOrder.exchangeRate = _exchangeRate;
        exchangeOrder.status = ExchangeStatus.Confirmed;
    }
    
    function hasRequestedPayments(address _beneficiary) public view returns(bool) {
        return (nrRequestedPayments[_beneficiary] != 0);
    }    
        
    function getEtherPaymentsCount() external view returns(uint256) {
        return payments.length;
    }
    
    function getExchangeOrdersCount() external view returns(uint256) {
        return exchangeOrders.length;
    }
    
    function getExchangeOrdersToPayments(uint orderId) external view returns (uint[] memory) {
        return exchangeOrderForPayments[orderId];
    }     
    
}
"},"CrowdliKYCProvider.sol":{"content":"
pragma solidity 0.5.0;

import "./Pausable.sol";
import "./WhitelistAdminRole.sol";

contract CrowdliKYCProvider is Pausable, WhitelistAdminRole {

	/**
	 * The verification levels supported by this ICO
	 */
	enum VerificationTier { None, KYCAccepted, VideoVerified, ExternalTokenAgent } 
    
    /**
     * Defines the max. amount of tokens an investor can purchase for a given verification level (tier)
     */
	mapping (uint => uint) public maxTokenAmountPerTier; 
    
    /**
    * Dictionary that maps addresses to investors which have successfully been verified by the external KYC process
    */
    mapping (address => VerificationTier) public verificationTiers;

    /**
    * This event is fired when a user has been successfully verified by the external KYC verification process
    */
    event LogKYCConfirmation(address indexed sender, VerificationTier verificationTier);

	/**
	 * This constructor initializes a new  CrowdliKYCProvider initializing the provided token amount threshold for the supported verification tiers
	 */
    constructor(address _kycConfirmer, uint _maxTokenForKYCAcceptedTier, uint _maxTokensForVideoVerifiedTier, uint _maxTokensForExternalTokenAgent) public {
        addWhitelistAdmin(_kycConfirmer);
        // Max token amount for non-verified investors
        maxTokenAmountPerTier[uint(VerificationTier.None)] = 0;
        
        // Max token amount for auto KYC auto verified investors
        maxTokenAmountPerTier[uint(VerificationTier.KYCAccepted)] = _maxTokenForKYCAcceptedTier;
        
        // Max token amount for auto KYC video verified investors
        maxTokenAmountPerTier[uint(VerificationTier.VideoVerified)] = _maxTokensForVideoVerifiedTier;
        
        // Max token amount for external token sell providers
        maxTokenAmountPerTier[uint(VerificationTier.ExternalTokenAgent)] = _maxTokensForExternalTokenAgent;
    }

    function confirmKYC(address _addressId, VerificationTier _verificationTier) public onlyWhitelistAdmin whenNotPaused {
        emit LogKYCConfirmation(_addressId, _verificationTier);
        verificationTiers[_addressId] = _verificationTier;
    }

    function hasVerificationLevel(address _investor, VerificationTier _verificationTier) public view returns (bool) {
        return (verificationTiers[_investor] == _verificationTier);
    }
    
    function getMaxChfAmountForInvestor(address _investor) public view returns (uint) {
        return maxTokenAmountPerTier[uint(verificationTiers[_investor])];
    }    
}"},"CrowdliSTO.sol":{"content":"pragma solidity 0.5.0;

import "./CrowdliToken.sol";
import "./CrowdliKYCProvider.sol";
import "./CrowdliExchangeVault.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

/**
 * @title Crowdli STO Contract
 */
contract CrowdliSTO is Pausable, Ownable {
    /**
     * The safe math library for safety math operations provided by Open Zeppelin
     */
    using SafeMath for uint;

    /**
     * Defines all states the STO can be in
     */
    enum States {
        PrepareInvestment,
        Investment,
        Finalizing,
        Finalized
    }

    struct InvestmentPhase {
        bytes32 label;
        bool allowManualSwitch;
        uint discountBPS;
        uint capAmount;
        uint tokensSoldAmount;
    }

    struct TokenAllocation {
        bytes32 label;
        AllocationActionType actionType;
        AllocationValueType valueType;
        uint valueAmount;
        address beneficiary;
        bool isAllocated;
    }

    struct TokenStatement {
        uint requestedBase;
        uint requestedCHF;
        uint feesCHF;
        uint currentPhaseDiscount;
        uint earlyBirdCreditTokenAmount;
        uint voucherCreditTokenAmount;
        uint currentPhaseTokenAmount;
        uint nextPhaseBaseAmount;
        TokenStatementValidation validationCode;
    }

    enum Currency {
        ETH,
        CHF,
        EUR
    }

    enum ExecutionType {
        SinglePayment,
        SplitPayment
    }

    enum AllocationActionType {
        POST_ALLOCATE
    }

    enum AllocationValueType {
        FIXED_TOKEN_AMOUNT,
        BPS_OF_TOKENS_SOLD
    }

    enum TokenStatementValidation {
        OK,
        BELOW_MIN_LIMIT,
        ABOVE_MAX_LIMIT,
        EXCEEDS_HARD_CAP
    }

    /**
     * This event is fired when a ether payment is confirmed by payment confirmer
     */
    event LogPaymentConfirmation(address indexed beneficiary, uint indexed investment, uint[] paymentDetails, uint id, Currency currency, ExecutionType executionType);
    /**
     * This event is fired when a new investment sub-phase is registered during the PrepareInvestment phase
     */
    event LogRegisterInvestmentPhase(address indexed sender, bool allowManualSwitch, bytes32 indexed label, uint indexed discountBPS, uint cap);

    /**
     * This event is fired when the start date is updated
     */
    event LogSaleStartUpdated(address indexed sender, uint indexed saleStartDate);

    /**
     * This event is fired whenever the CrowdliKYCProvider used for the STO is updated
     */
    event LogKYCProviderUpdated(address indexed sender, address indexed crowdliKycProvider);

    /**
     * This event is fired when the STO has started
     */
    event LogStarted(address indexed sender);

    /**
     * This event is fired when a new investment phase starts
     */
    event LogInvestmentPhaseSwitched(uint phaseIndex);

    /**
     * This event is fired when the STO closes
     */
    event LogEndDateExtended(address indexed sender, uint endDate);

    /**
     * This event is fired when the STO closes
     */
    event LogClosed(address indexed sender, bool stoSucessfull);

    /**
     * This event will be fired when the customer finalizes the STO
     */
    event LogFinalized(address indexed sender);

    /**
     * Whenever the state of the contract changes, this event will be fired.
     */
    event LogStateChanged(States _states);
    
    /**
     * Whenever the investor gets pending voucher.
     */
    event LogPendingVoucherAdded(address _investor);

    /**
     * State variable: Defines the state of the STO
     */
    States public state;

    /**
     * Only the foundation board is able to finalize the STO.
     * Two of four members have to confirm the finalization. Therefore a multisig contract is used.
     */
    address public directorsBoard;

    /**
     * This account is authorized to confirm payments
     */
    address public paymentConfirmer;

    /**
     * This the wallet where for an external agent all tokens tokens are minted for the incoming payments
     */
    address public tokenAgentWallet;

    /**
     * The token we are giving the investors in return for their investments
     */
    CrowdliToken public token;

    /**
     * The exchange vault used to exchange ether payments in a restricted an safe manner with the authorized bank into fiat money
     */
    CrowdliExchangeVault public crowdliExchangeVault;

    /**
     * The kyc provider used to whitelist the investors for verification tiers
     */
    CrowdliKYCProvider public crowdliKycProvider;

    /**
     * STO settings & statistics: Pre- and post allocated tokens
     */
    TokenAllocation[] public tokenAllocations;

    /**
     * STO settings & statistics: Defines the phases for an STO
     */
    InvestmentPhase[] public investmentPhases;

    /**
     * STO Setting:  The total amount of tokens sold during the STO(includes all phases)
     */
    uint public hardCapAmount = 0;

    /**
     * The lower hardcap threshold allows a bandwith in which the hard cap is regarded as reached
     */
    uint public hardCapThresholdAmount;

    /**
     * STO Setting: The min. token amount that have to be sold so that the STO successful
     */
    uint public softCapAmount;

    /**
     * STO Setting: Minimum amount of tokens a investor is able to buy
     */
    uint public minChfAmountPerInvestment;
    /**
     * STO Setting: The UNIX timestamp (in seconds) defining when 1the STO will start
     */
    uint public saleStartDate;

    /**
     * The date the STO Organizer can extend the STO at latest for the defined offset
     */
    uint public endDateExtensionDecissionDate;

    /**
     * The endDate can be extended with this offset
     */
    uint public endDateExtensionOffset;

    /**
     * STO Setting: 
     */
    uint public endDate;

    /**
     * STO settings: Video Verification cost
     */
    uint public videoVerificationCostAmount ;

    /**
     * STO settings: gas fees used for further processing of payments
     */
    uint internal gasCostAmount;

    /**
     * STO state: Defines the index of the current phase
     */
    uint public investmentPhaseIndex;

    /**
     * The board of directors can comment the finalization
     * Crowdli change: change to bytes32 to reduce gas costs
     */
    bytes32 public boardComment;

    /**
     * Threshold to define if the investor should get 'earlyBird' status.
     */
    uint public earlyBirdTokensThresholdAmount;

    /**
     * Token to be added to the purchased tokens amount.
     */
    uint public earlyBirdAdditionalTokensAmount;

    /**
     * Maximum number of the 'earlyBird' investors.
     */
    uint public earlyBirdInvestorsCount;

    /**
     * First available investment phase for 'earlyBird' investor.
     */
    uint public earlyBirdInvestmentPhase = 0;

    /**
     * Current number of the 'earlyBird' investor.
     */
    uint public currentEarlyBirdInvestorsCount = 0;

    /**
     * The token amount an investor receives for redeeming a voucher
     */
    uint public voucherTokensAmount;

    /**
     * Investors that have a pending vouchers to be redeemed
     */
    mapping(address => bool) public investorsWithEarlyBird;

    /**
     * Investors that have pending vouchers.
     */
    mapping(address => bool) public investorsWithPendingVouchers;

    /**
     * Investors that have paid for the video verification
     */
    mapping(address => bool) public paidForVideoVerification;

    /**
     * STO Statistic: The total amount of tokens sold
     */
    uint public tokensSoldAmount;

    /**
     * STO Statistic: The total amount of WEI invested by this STO
     */
    uint public weiInvested ;

    /**
     * STO Statistic: The number of investors that have invested in this STO
     */
    uint public numberOfInvestors;

    /**
     * STO Statistic: The total amount of investments (FIAT and ETH) in CHF
     */
    mapping(address => uint) public allInvestmentsInChf;

    /**
     * STO Statistic: The total amount of WEI's per investor
     */
    mapping(address => uint) public weiPerInvestor;

    /**
     * STO Statistic: The total amount of CHF's per investor
     */
    mapping(address => uint) public chfPerInvestor;

    /**
     * STO Statistic: The total amount of CHF's investments
     */
    uint public chfOverallInvested;

    /**
     * STO Statistic: The total amount of EUR's per investor
     */
    mapping(address => uint) public eurPerInvestor;

    /**
     * STO Statistic: The total amount of EUR's investments
     */
    uint public eurOverallInvested;

    /**
     * The exchangeRate that was last used 
     */
    uint public exchangeRate;

    uint public exchangeRateDecimals;

    /**
     * Limit the size of arrays to avoid gas limit deadlocks 
     */
	uint constant public arrayMaxEntryLimit = 10;
	
    // ============================================================================================================================================================================================================================   
    // All modifiers come here
    // ============================================================================================================================================================================================================================
    /**
     * @dev Throws if called by any account other than the foundation board
     */
    modifier onlyDirectorsBoard() {
        require(msg.sender == directorsBoard, "not directorsBoard");
        _;
    }

    /**
     * @dev Throws if sender is not payment confirmer
     */
    modifier onlyFiatPaymentConfirmer() {
        require((msg.sender == paymentConfirmer), "not paymentConfirmer");
        _;
    }

    /**
     * @dev Throws if sender is not payment confirmer
     */
    modifier onlyEtherPaymentProvider() {
        require(msg.sender == address(crowdliExchangeVault), "not crowdliExchangeVault");
        _;
    }

    /**
     * @dev Throws if sender is not token agent payment confirmer
     */
    modifier onlyTokenAgentPaymentConfirmer() {
        require((msg.sender == paymentConfirmer), "not tokenAgentPaymentConfirmer");
        _;
    }

    /**
     * @dev Throws if sender is not in state
     */
    modifier inState(States _state) {
        require(hasState(_state), "not in required state");
        _;
    }


    constructor (CrowdliToken _token, CrowdliKYCProvider _crowdliKycProvider, CrowdliExchangeVault _crowdliExchangeVault, address _directorsBoard, address _paymentConfirmer, address _tokenAgentWallet) public {
        token = _token;
        crowdliKycProvider = _crowdliKycProvider;
        crowdliExchangeVault = _crowdliExchangeVault;
        directorsBoard = _directorsBoard;
        paymentConfirmer = _paymentConfirmer;
        tokenAgentWallet = _tokenAgentWallet;
    }

    // ============================================================================================================================================================================================================================   
    // External functions
    // ============================================================================================================================================================================================================================v
    function initSTO(uint _saleStartDate, uint _earlyBirdTokensThreshold,
        uint _earlyBirdAdditionalTokens,
        uint _earlyBirdInvestorsCount,
        uint _earlyBirdInvestmentPhase,
        uint _voucherTokensAmount,
        uint _videoVerificationCost,
        uint _softCap,
        uint _endDate,
        uint _endDateExtensionDecissionDate,
        uint _endDateExtensionOffset,
        uint _gasCost,
        uint _hardCapThresholdAmount,
        uint _minChfAmountPerInvestment) external onlyOwner {

        // we must disallow any transfers until the end of the STO
        token.pause();

        saleStartDate = _saleStartDate;
        state = States.PrepareInvestment;
        earlyBirdTokensThresholdAmount = _earlyBirdTokensThreshold;
        earlyBirdInvestorsCount = _earlyBirdInvestorsCount;
        earlyBirdAdditionalTokensAmount = _earlyBirdAdditionalTokens;
        earlyBirdInvestmentPhase = _earlyBirdInvestmentPhase;
        voucherTokensAmount = _voucherTokensAmount;
        videoVerificationCostAmount = _videoVerificationCost;
        gasCostAmount = _gasCost;
        softCapAmount = _softCap;
        endDate = _endDate;
        endDateExtensionDecissionDate = _endDateExtensionDecissionDate;
        endDateExtensionOffset = _endDateExtensionOffset;
        hardCapThresholdAmount = _hardCapThresholdAmount;
        minChfAmountPerInvestment = _minChfAmountPerInvestment;

    }

    function registerPostAllocation(bytes32 _label, AllocationValueType _valueType, address _beneficiary, uint _value) external onlyOwner inState(States.PrepareInvestment) {
        require(_label != 0, "_label not set");
        require(_beneficiary != address(0), "_beneficiary not set");
        require(_value > 0, "_value not set");
        require(tokenAllocations.length < arrayMaxEntryLimit, "tokenAllocations.length is too high");
        tokenAllocations.push(TokenAllocation(_label, AllocationActionType.POST_ALLOCATE, _valueType, _value, _beneficiary, false));
    }

    function updateStartDate(uint _saleStartDate) external onlyOwner inState(States.PrepareInvestment) {
        require(_saleStartDate >= now, "saleStartDate not in future");
        saleStartDate = _saleStartDate;
        emit LogSaleStartUpdated(msg.sender, _saleStartDate);
    }

    function updateCrowdliKYCProvider(CrowdliKYCProvider _crowdliKycProvider) external onlyOwner inState(States.PrepareInvestment) {
        crowdliKycProvider = _crowdliKycProvider;
        emit LogKYCProviderUpdated(msg.sender, address(_crowdliKycProvider));
    }

    function updateExchangeRate(uint _exchangeRate, uint _exchangeRateDecimals) external onlyOwner {
        exchangeRate = _exchangeRate;
        exchangeRateDecimals = _exchangeRateDecimals;
    }

    function registerInvestmentPhase(bytes32 _label, bool allowManualSwitch, uint _discountBPS, uint _cap) external onlyOwner inState(States.PrepareInvestment) {
        require(_label != 0, "label should not be empty");
        require(investmentPhases.length <= arrayMaxEntryLimit, "investmentPhases.length is too high");
        investmentPhases.push(InvestmentPhase(_label, allowManualSwitch, _discountBPS, _cap, 0));
        emit LogRegisterInvestmentPhase(msg.sender, allowManualSwitch, _label, _discountBPS, _cap);
        //the hardcap is the sum of all phases caps
        hardCapAmount = hardCapAmount.add(_cap);
    }

    function processEtherPayment(address _beneficiary, uint _weiAmount, uint _paymentId) external whenNotPaused onlyEtherPaymentProvider inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _weiAmount, Currency.ETH, exchangeRate, exchangeRateDecimals, false, true);
    }

    function processBankPaymentCHF(address _beneficiary, uint _chfAmount, bool _hasRequestedPayments, uint _paymentId) external whenNotPaused onlyFiatPaymentConfirmer inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _chfAmount, Currency.CHF, 1, 1, _hasRequestedPayments, true);
    }

    function processBankPaymentEUR(address _beneficiary, uint _eurAmount, uint _exchangeRate, uint _exchangeRateDecimals, bool _hasRequestedPayments, uint _paymentId) external whenNotPaused onlyFiatPaymentConfirmer inState(States.Investment) {
        processPayment(_beneficiary, _paymentId, _eurAmount, Currency.EUR, _exchangeRate, _exchangeRateDecimals, _hasRequestedPayments, true);
    }

    function processTokenAgentPaymentCHF(uint _chfAmount, uint _paymentId) external whenNotPaused onlyTokenAgentPaymentConfirmer inState(States.Investment) {
        processPayment(tokenAgentWallet, _paymentId, _chfAmount, Currency.CHF, 1, 1, false, true);
    }

    function addPendingVoucher(address _investor) external onlyOwner whenNotPaused {
        investorsWithPendingVouchers[_investor] = true;
        emit LogPendingVoucherAdded(_investor);
    }

    function switchCurrentPhaseManually() external onlyDirectorsBoard inState(States.Investment) {
        require(isCurrentPhaseManuallySwitchable(), "manual switch disallowed");

        // calculate the gap between current phase and cap amount
        InvestmentPhase memory currentInvestmentPhase = investmentPhases[investmentPhaseIndex];
        uint phaseDeltaTokenAmount = currentInvestmentPhase.capAmount.sub(currentInvestmentPhase.tokensSoldAmount);

        // all tokens which were not sold after manual close will be made available in the last investment phase
        uint lastIndex = investmentPhases.length.sub(1);
        investmentPhases[lastIndex].capAmount = investmentPhases[lastIndex].capAmount.add(phaseDeltaTokenAmount);
        nextInvestmentPhase();
    }

    function start() external onlyDirectorsBoard inState(States.PrepareInvestment) {
        startInternal();
    }
    
    function calculateTokenStatementFiat(address _investor, uint _currencyAmount, Currency _currency, uint256 _exchangeRate, uint256 _exchangeRateDecimals, bool _hasRequestedBankPayments, uint investmentPhaseOffset) external view returns(uint[] memory) {
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, (investmentPhaseOffset == 0), investmentPhaseOffset);
        return convertTokenStatementToArray(tokenStatement);
    }
    
    function calculateTokenStatementEther(address _investor, uint _currencyAmount, Currency _currency, bool _hasRequestedBankPayments, uint investmentPhaseOffset) external view returns(uint[] memory) {
        //exchangeRate and exchangeRateDecimals will be used from internal parameters
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, exchangeRate, exchangeRateDecimals, _hasRequestedBankPayments, (investmentPhaseOffset == 0), investmentPhaseOffset);
        return convertTokenStatementToArray(tokenStatement);
    }

    function evalTimedStates() external view returns (bool) {
        return ((isEndDateReached() && state == States.Investment) || isStartRequired());
    }

    function extendEndDate() external inState(States.Investment) onlyDirectorsBoard {
        require(isEndDateExtendable(), "isEndDateExtendable() is false");
        endDate = endDate.add(endDateExtensionOffset);
        endDateExtensionOffset = 0;
        emit LogEndDateExtended(msg.sender, endDate);
    }

    function updateTimedStates() external {
        if (isEndDateReached()) {
            if (isSoftCapReached()) {
                close(true);
            } else {
                close(false);
            }
        }
        if(isStartRequired()){
        	startInternal();
        }
    }

    function closeManually() external onlyDirectorsBoard inState(States.Investment) {
        require(isHardCapWithinCapThresholdReached(), "Cap is not reached.");
        close(true);
    }

    /**
     * Once the STO is in state Finalizing the directors board account has to finalize in order to make the tokens transferable
     * @param _message An official statement why the STO is considered as successful
     * 
     * Visibility: OK
     */
    function finalize(bytes32 _message) external onlyDirectorsBoard inState(States.Finalizing) {
        // the directors board has to give an statement why the STO is successful
        setBoardComment(_message);

        // Make token transferable otherwise the transfer call used when granting vesting to teams will be rejected.
        allocateTokens(AllocationActionType.POST_ALLOCATE);

        // release the token so can be transfered or 
        token.unpause();

        // finally the state of the STO is set to the final state 'Finalized' 
        updateState(States.Finalized);

        emit LogFinalized(msg.sender);
    }

    // ============================================================================================================================================================================================================================   
    // Public functions
    // ============================================================================================================================================================================================================================v
    function getInvestmentPhaseCount() public view returns(uint) {
        return investmentPhases.length;
    }

    function  getTokenAllocationsCount() public view returns(uint) {
        return tokenAllocations.length;
    }

    function validate() public view returns (uint) {
        uint statusCode = 0;
        if (address(token) == address(0)) {
            statusCode = 1;
        } else if (address(crowdliKycProvider) == address(0)) {
            statusCode = 2;
        } else if (softCapAmount == 0) {
            statusCode = 3;
        } else if (hardCapAmount == 0) {
            statusCode = 4;
        } else if (hardCapAmount < softCapAmount) {
            statusCode = 5;
        } else if (minChfAmountPerInvestment == 0) {
            statusCode = 6;
        } else if (investmentPhases.length == 0) {
            statusCode = 9;
        }
        return statusCode;
    }

    /**
     * @dev there is no direct way to convert an enum to string
     */
    function resolvePaymentError(TokenStatementValidation validationCode) public pure returns(string memory) {
        if (validationCode == TokenStatementValidation.BELOW_MIN_LIMIT) {
            return "BELOW_MIN_LIMIT";
        } else if (validationCode == TokenStatementValidation.ABOVE_MAX_LIMIT) {
            return "ABOVE_MAX_LIMIT";
        } else if (validationCode == TokenStatementValidation.EXCEEDS_HARD_CAP) {
            return "EXCEEDS_HARD_CAP";
        }
    }

    /**
     * @dev access permissions (onlyPauser) is checked in super function
     */
    function pause() public {
        super.pause();
        crowdliExchangeVault.pause();
        crowdliKycProvider.pause();
    }

    /**
     * @dev access permissions (onlyPauser) is checked in super function
     */
    function unpause () public {
        super.unpause();
        crowdliExchangeVault.unpause();
        crowdliKycProvider.unpause();
    }

    function setBoardComment(bytes32 _boardComment) public onlyDirectorsBoard {
        boardComment = _boardComment;
    }

    function hasPendingVideoVerificationFees(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (crowdliKycProvider.hasVerificationLevel(_investor, CrowdliKYCProvider.VerificationTier.VideoVerified) && (!paidForVideoVerification[_investor]) && !hasUnconfirmedPayments(_investor, _hasRequestedBankPayments));
    }

    function isEntitledForEarlyBird(address _investor, uint tokenAmount, uint _investmentPhaseIndex) private view returns (bool) {
        return ((tokenAmount >= earlyBirdTokensThresholdAmount) && (currentEarlyBirdInvestorsCount < earlyBirdInvestorsCount) && !investorsWithEarlyBird[_investor] && _investmentPhaseIndex >= earlyBirdInvestmentPhase);
    }

    function hasPendingVouchers(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (investorsWithPendingVouchers[_investor] && !hasUnconfirmedPayments(_investor, _hasRequestedBankPayments));
    }

    function hasUnconfirmedPayments(address _investor, bool _hasRequestedBankPayments) private view returns (bool) {
        return (_hasRequestedBankPayments || crowdliExchangeVault.hasRequestedPayments(_investor));
    }

    function isEndDateExtendable() public view returns (bool) {
        return ((endDateExtensionDecissionDate >= now) && (endDateExtensionOffset > 0));
    }

    function isCurrentPhaseManuallySwitchable() public view returns(bool) {
        return investmentPhases[investmentPhaseIndex].allowManualSwitch;
    }

    function isLastPhase() public view returns (bool) {
        return (investmentPhaseIndex.add(1) >= investmentPhases.length);
    }

    function isCurrentPhaseCapReached() public view returns(bool) {
        InvestmentPhase memory investmentPhase = investmentPhases[investmentPhaseIndex];
        return (investmentPhase.tokensSoldAmount >= investmentPhase.capAmount);
    }

    function isHardCapWithinCapThresholdReached() public view returns (bool) {
        return (isLastPhase() && (investmentPhases[investmentPhaseIndex].tokensSoldAmount >= investmentPhases[investmentPhaseIndex].capAmount.sub(hardCapThresholdAmount)));
    }

 	function isHardCapReached() public view returns (bool) {
        return (isLastPhase() && (investmentPhases[investmentPhaseIndex].tokensSoldAmount >= investmentPhases[investmentPhaseIndex].capAmount));
    }
    
    function isSoftCapReached() public view returns (bool) {
        return (tokensSoldAmount >= softCapAmount);
    }

    function isManuallyClosable() public view returns(bool) {
        return(hasState(States.Investment) && isHardCapWithinCapThresholdReached());
    }

    function isEndDateReached() public view returns (bool) {
        return (now > endDate);
    }

    function hasState(States _state) public view returns (bool) {
        return (state == _state);
    }

    /**
     * Used by the STO user interface to retrieve the STO statistics with a single call
     */
    function getStatisticsData() public view returns(uint[] memory) {
        uint[] memory result= new uint[](7);
        result[0] = softCapAmount;
        result[1] = hardCapAmount;
        result[2] = weiInvested;
        result[3] = chfOverallInvested;
        result[4] = eurOverallInvested;
        result[5] = tokensSoldAmount;
        result[6] = numberOfInvestors;
        return result;
    }

    // ============================================================================================================================================================================================================================   
    // Private functions
    // ============================================================================================================================================================================================================================v
    function nextInvestmentPhase() private returns (bool) {
        if (!isLastPhase()) {
            // there is a next phase, so we can switch
            investmentPhaseIndex = investmentPhaseIndex.add(1);
            emit LogInvestmentPhaseSwitched(investmentPhaseIndex);
            return false;

        } else {
            revert("payment exceeds hard cap");
        }
    }

    function confirmMintedTokensForPayment(uint _paymentId, uint tokenAmountToBuy, Currency _currency) private {
        if (Currency.ETH == _currency) {
            crowdliExchangeVault.confirmMintedTokensForPayment(_paymentId, tokenAmountToBuy);
        }
    }

    function updateState(States _state) private {
        require (_state > state, "the state can never transit backwards");
        state = _state;
        emit LogStateChanged(state);
    }

    function close(bool stoSucessfull) private inState(States.Investment) {
        require(hasState(States.Investment), "Requires state Investment");
        updateState(States.Finalizing);
        emit LogClosed(msg.sender, stoSucessfull);
    }

    function allocateTokens(AllocationActionType _actionType) private {
        for (uint i = 0; i < tokenAllocations.length;i++) {
            if (tokenAllocations[i].actionType == _actionType) {
                uint tokensToAllocate = 0;
                if (tokenAllocations[i].valueType == AllocationValueType.BPS_OF_TOKENS_SOLD) {
                    tokensToAllocate = tokensSoldAmount.mul(tokenAllocations[i].valueAmount).div(10000);
                } else if (tokenAllocations[i].valueType == AllocationValueType.FIXED_TOKEN_AMOUNT) {
                    tokensToAllocate = tokenAllocations[i].valueAmount;
                }
                token.mint(tokenAllocations[i].beneficiary, tokensToAllocate);
                tokenAllocations[i].isAllocated = true;
            }
        }
    }

    function processPayment(address _investor, uint _paymentId, uint _currencyAmount, Currency _currency, uint _exchangeRate, uint _exchangeRateDecimals, bool _hasRequestedBankPayments, bool _isFirstPayment) private {
        require(crowdliKycProvider.verificationTiers(_investor) > CrowdliKYCProvider.VerificationTier.None, "Verification tier not > 0");

        InvestmentPhase storage investmentPhase = investmentPhases[investmentPhaseIndex];
        // ============================================================================================
        // Step 1: Calculate token statement
        // ============================================================================================
        TokenStatement memory tokenStatement = calculateTokenStatementStruct(_investor, _currencyAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, _isFirstPayment, 0);

        // only process if validation code == OK
        require(tokenStatement.validationCode == TokenStatementValidation.OK, resolvePaymentError(tokenStatement.validationCode));

        // ============================================================================================
        // Update the STO states and statistics
        // ============================================================================================ 
        // sum up the tokens sold for the current investment phase
        investmentPhase.tokensSoldAmount = investmentPhase.tokensSoldAmount.add(tokenStatement.currentPhaseTokenAmount);

        // sum up the amount of tokens sold during the STO
        tokensSoldAmount = tokensSoldAmount.add(tokenStatement.currentPhaseTokenAmount);

        if (_isFirstPayment) {
            allInvestmentsInChf[_investor] = allInvestmentsInChf[_investor].add(tokenStatement.requestedCHF);

            if (tokenStatement.feesCHF > gasCostAmount)
	        	paidForVideoVerification[_investor] = true;

            if (Currency.CHF == _currency) {
                chfPerInvestor[_investor] = chfPerInvestor[_investor].add(_currencyAmount);
                chfOverallInvested = chfOverallInvested.add(_currencyAmount);
            } else if (Currency.EUR == _currency) {
                eurPerInvestor[_investor] = eurPerInvestor[_investor].add(_currencyAmount);
                eurOverallInvested = eurOverallInvested.add(_currencyAmount);
            } else if (Currency.ETH == _currency) {
                weiPerInvestor[_investor] = weiPerInvestor[_investor].add(_currencyAmount);
                weiInvested = weiInvested.add(_currencyAmount);
            }

            // update the statistic counting the number of investors involved in a token purchase
            if (token.balanceOf(_investor) == 0) {
                numberOfInvestors = numberOfInvestors.add(1);
            }
        }

        if (tokenStatement.earlyBirdCreditTokenAmount > 0) { // earlyBird         
        // update early bird investor statistics
            currentEarlyBirdInvestorsCount = currentEarlyBirdInvestorsCount.add(1);

            // store flag that the investor has received early bird tokens
            investorsWithEarlyBird[_investor] = true;
        }

        if (tokenStatement.voucherCreditTokenAmount > 0) {
            // mark voucher as redeemed for investor
            investorsWithPendingVouchers[_investor] = false;
        }


        // ============================================================================================
        // Mint the STO tokens
        // ============================================================================================        
        token.mint(_investor, tokenStatement.currentPhaseTokenAmount);

        if (tokenStatement.nextPhaseBaseAmount > 0) {
            ExecutionType executionType;

            executionType = ExecutionType.SplitPayment;

            emit LogPaymentConfirmation(_investor, tokenStatement.requestedBase, convertTokenStatementToArray(tokenStatement), _paymentId, _currency, executionType);
            confirmMintedTokensForPayment(_paymentId, tokenStatement.currentPhaseTokenAmount, _currency);

            // switch to next phase
            nextInvestmentPhase();

            // process payment in the new phase
            processPayment(_investor, _paymentId, tokenStatement.nextPhaseBaseAmount, _currency, _exchangeRate, _exchangeRateDecimals, _hasRequestedBankPayments, false);
        } else {

            // no further payments to process
            emit LogPaymentConfirmation(_investor, tokenStatement.requestedBase, convertTokenStatementToArray(tokenStatement), _paymentId, _currency, ExecutionType.SinglePayment);
            confirmMintedTokensForPayment(_paymentId, tokenStatement.currentPhaseTokenAmount, _currency);
        }
    }

    function convertTokenStatementToArray(TokenStatement memory tokenStatement) private pure returns(uint[] memory) {
        uint[] memory tokenStatementArray = new uint[](9);
        tokenStatementArray[0] = tokenStatement.requestedBase;
        tokenStatementArray[1] = tokenStatement.requestedCHF;
        tokenStatementArray[2] = tokenStatement.feesCHF;
        tokenStatementArray[3] = tokenStatement.currentPhaseDiscount;
        tokenStatementArray[4] = tokenStatement.earlyBirdCreditTokenAmount;
        tokenStatementArray[5] = tokenStatement.voucherCreditTokenAmount;
        tokenStatementArray[6] = tokenStatement.currentPhaseTokenAmount;
        tokenStatementArray[7] = tokenStatement.nextPhaseBaseAmount;
        tokenStatementArray[8] = uint(tokenStatement.validationCode);
        return tokenStatementArray;
    }

    function calculateDiscountUptick(uint _amount, InvestmentPhase memory investmentPhase) private pure returns (uint) {
        uint currentRate = uint(10000).sub(investmentPhase.discountBPS);
        return _amount.mul(investmentPhase.discountBPS).div(currentRate);
    }

    function calculateDiscount(uint _amount, InvestmentPhase memory investmentPhase) private pure returns (uint) {
        return _amount.mul(investmentPhase.discountBPS).div(10000);
    }

    function calculateConversionFromBase(uint _currencyAmount, uint _exchangeRate, uint _exchangeRateDecimals) private pure returns (uint) {
        return _currencyAmount.mul(_exchangeRate).div(_exchangeRateDecimals);
    }

    function calculateConversionToBase(uint _currencyAmount, uint _exchangeRate, uint _exchangeRateDecimals) private pure returns (uint) {
        return _currencyAmount.mul(_exchangeRateDecimals).div(_exchangeRate);
    }

    function calculateTokenStatementStruct(address _investor, uint _currencyAmount, Currency _currency, uint256 _exchangeRate, uint256 _exchangeRateDecimals, bool _hasRequestedBankPayments, bool _isFirstPayment, uint _investmentPhaseOffset) private view returns(TokenStatement memory) {
        TokenStatement memory tokenStatement;

        // the struct containing the data for the current investment phase
        uint investmentPhaseWithOffset = investmentPhaseIndex.add(_investmentPhaseOffset);
        InvestmentPhase memory investmentPhase = investmentPhases[investmentPhaseWithOffset];

        // the requested amount in the currency provided
        tokenStatement.requestedBase = _currencyAmount;

        // ============================================================================================
        // Step 1: Convert requested payment to CHF
        // ============================================================================================
        if (Currency.CHF == _currency) {
            tokenStatement.requestedCHF = tokenStatement.requestedBase;
        } else if (Currency.EUR == _currency) {
            tokenStatement.requestedCHF = calculateConversionFromBase(tokenStatement.requestedBase, _exchangeRate, _exchangeRateDecimals);
        } else if (Currency.ETH == _currency) {
            tokenStatement.requestedCHF = calculateConversionFromBase(tokenStatement.requestedBase, _exchangeRate, _exchangeRateDecimals);
        } else revert("Currency not supported");

        // the requested amount in the currency provided
        tokenStatement.requestedCHF = roundUp(tokenStatement.requestedCHF);

        uint investmentNetCHF = tokenStatement.requestedCHF;

        // calculate the fees (gas cost always, video verification once, if previously processed)
        // we have to make sure that the credits are not recognized twice in case of a split payment
        if (_isFirstPayment) {
            // ============================================================================================
	        // Verify/validate investment thresholds
	        // ============================================================================================
	        tokenStatement.validationCode = validatePayment(_investor, tokenStatement);
 
            tokenStatement.feesCHF = gasCostAmount;
            if (hasPendingVideoVerificationFees(_investor, _hasRequestedBankPayments)) {
                tokenStatement.feesCHF = tokenStatement.feesCHF.add(videoVerificationCostAmount);
            }
            investmentNetCHF = tokenStatement.requestedCHF.sub(tokenStatement.feesCHF);
        }

        // check whether the payment can be handled in the current phase OR we have to create a second payment to be executed in the next phase
        uint phaseDeltaTokenAmount = investmentPhase.capAmount.sub(investmentPhase.tokensSoldAmount);
        tokenStatement.currentPhaseDiscount = roundUp(calculateDiscountUptick(investmentNetCHF, investmentPhase));
        uint tokenAmountWithCurrentPhaseDiscount = investmentNetCHF.add(tokenStatement.currentPhaseDiscount);



        // create second payment (split) if tokens exceed current phase cap
        if (tokenAmountWithCurrentPhaseDiscount > phaseDeltaTokenAmount) {
        	if (isLastPhase())
            	tokenStatement.validationCode = TokenStatementValidation.EXCEEDS_HARD_CAP;
        
            tokenStatement.currentPhaseTokenAmount = roundUp(phaseDeltaTokenAmount);
            tokenStatement.currentPhaseDiscount = roundUp(calculateDiscount(phaseDeltaTokenAmount, investmentPhase));
            uint currentPhaseNetTokenAmount = phaseDeltaTokenAmount.sub(tokenStatement.currentPhaseDiscount);
            tokenStatement.nextPhaseBaseAmount = calculateConversionToBase(investmentNetCHF.sub(currentPhaseNetTokenAmount), _exchangeRate, _exchangeRateDecimals);
        } else {
            tokenStatement.currentPhaseDiscount = tokenStatement.currentPhaseDiscount;
            tokenStatement.currentPhaseTokenAmount = tokenAmountWithCurrentPhaseDiscount;
            tokenStatement.nextPhaseBaseAmount = 0;

            // we have to make sure that the credits are not recognized twice in case of a split payment
            // the first x investors starting from phase y will receive some bonus tokens
            if (isEntitledForEarlyBird(_investor, tokenStatement.currentPhaseTokenAmount, investmentPhaseWithOffset)) {
                tokenStatement.earlyBirdCreditTokenAmount = earlyBirdAdditionalTokensAmount;
                tokenStatement.currentPhaseTokenAmount = tokenStatement.currentPhaseTokenAmount.add(tokenStatement.earlyBirdCreditTokenAmount);
            }
            // investor receives some bonus tokens if he has previously redeemed a valid STO voucher
            if (hasPendingVouchers(_investor, _hasRequestedBankPayments)) {
                tokenStatement.voucherCreditTokenAmount = voucherTokensAmount;
                tokenStatement.currentPhaseTokenAmount = tokenStatement.currentPhaseTokenAmount.add(tokenStatement.voucherCreditTokenAmount);
            }
        }
        
        // the STO requires to round up the decimals
        tokenStatement.currentPhaseTokenAmount = roundUp(tokenStatement.currentPhaseTokenAmount);
        return tokenStatement;
    }

    function validatePayment(address _investor, TokenStatement memory tokenStatement) private view returns(TokenStatementValidation) {
        if (tokenStatement.requestedCHF < minChfAmountPerInvestment) {
            // a single investment (token purchase) musn't be below the defined min. token amount threshold
            return TokenStatementValidation.BELOW_MIN_LIMIT; // a single investment (token purchase) musn't exceed the max token amount per KYC Verification Tier
        } else if (allInvestmentsInChf[_investor].add(tokenStatement.requestedCHF) > crowdliKycProvider.getMaxChfAmountForInvestor(_investor)) {
            // a single investment (token purchase) musn't exceed the max token amount per KYC Verification Tier 
            return TokenStatementValidation.ABOVE_MAX_LIMIT;
        } else return TokenStatementValidation.OK;

    }
    
    function isStartRequired() private view returns(bool) {
    	return ((now > saleStartDate) && state == States.PrepareInvestment);
    }
    
    function startInternal() private {
    	require(validate() == 0, "Start validation failed");
        saleStartDate = now;
        updateState(States.Investment);
        emit LogStarted(msg.sender);
    }

    function roundUp(uint amount) private pure returns(uint) {
        uint decimals = 10 ** 18;
        uint result = amount;
        uint remainder = amount % decimals;
        if (remainder > 0) {
            result = amount - remainder + decimals;
        }
        return result;
    }
}
"},"CrowdliToken.sol":{"content":"pragma solidity 0.5.0;

import "./Ownable.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./ERC20Pausable.sol";

/**
* @title CrowdliToken
*/
contract CrowdliToken is ERC20Detailed, ERC20Mintable, ERC20Pausable, Ownable {
	/**
	 * Holds the addresses of the investors
	 */
    address[] public investors;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) ERC20Detailed(_name,_symbol,_decimals) public {
    }
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
         if (balanceOf(account) == 0) {
            investors.push(account);
         }
         return super.mint(account, amount);
    }
    
    
    function initToken(address _directorsBoard,address _crowdliSTO) external onlyOwner{
    	addMinter(_directorsBoard);
    	addMinter(_crowdliSTO);
    	addPauser(_directorsBoard);
    	addPauser(_crowdliSTO);
    }
    
}

"},"ERC20.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

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
"},"ERC20Capped.sol":{"content":"pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";

/**
 * @dev Extension of `ERC20Mintable` that adds a cap to the supply of tokens.
 */
contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See `ERC20Mintable.mint`.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }
}
"},"ERC20Detailed.sol":{"content":"pragma solidity ^0.5.0;

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
"},"ERC20Mintable.sol":{"content":"pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./MinterRole.sol";

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
"},"ERC20Pausable.sol":{"content":"pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Pausable.sol";

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 */
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

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
"},"MinterRole.sol":{"content":"pragma solidity ^0.5.0;

import "./Roles.sol";

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
"},"Ownable.sol":{"content":"pragma solidity ^0.5.0;

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
"},"Pausable.sol":{"content":"pragma solidity ^0.5.0;

import "./PauserRole.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
"},"PauserRole.sol":{"content":"pragma solidity ^0.5.0;

import "./Roles.sol";

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}
"},"Roles.sol":{"content":"pragma solidity ^0.5.0;

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
"},"SafeERC20.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;

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
"},"SignerRole.sol":{"content":"pragma solidity ^0.5.0;

import "./Roles.sol";

contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(msg.sender);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}
"},"WhitelistAdminRole.sol":{"content":"pragma solidity ^0.5.0;

import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}
"},"WhitelistedRole.sol":{"content":"pragma solidity ^0.5.0;

import "./Roles.sol";
import "./WhitelistAdminRole.sol";

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}
"}}