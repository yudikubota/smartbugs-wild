{"LiquidBase.sol":{"content":"// SPDX-License-Identifier: WISE

pragma solidity =0.8.12;

contract LiquidBase {

    // Precision factor for interest rate in orders of 1E18
    uint256 public constant PRECISION_R = 100E18;

    // Team fee relative in orders of 1E18
    uint256 public constant FEE = 20E18;

    // Time before a liquidation will occur
    uint256 public constant DEADLINE_TIME = 7 days;

    // How long the contribution phase lasts
    uint256 public constant CONTRIBUTION_TIME = 5 days;

    // Amount of seconds in one day unit
    uint256 public constant SECONDS_IN_DAY = 86400;

    // Address if factory that creates lockers
    address public constant FACTORY_ADDRESS = 0x9961f05a53A1944001C0dF650A5aFF65B21A37D0;

    // Address to tranfer NFT to in event of non singleProvider liquidation
    address public constant TRUSTEE_MULTISIG = 0xfEc4264F728C056bD528E9e012cf4D943bd92b53;

    // ERC20 used for payments of this locker
    address public constant PAYMENT_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Helper constant for comparison with 0x0 address
    address constant ZERO_ADDRESS = address(0);

    /*@dev
    * @element tokenID: NFT IDs
    * @element tokenAddress: address of NFT contract
    * @element paymentTime: how long loan will last
    * @element paymentRate: how much must be paid for loan
    * @element lockerOwner: who is taking out loan
    */
    struct Globals {
        uint256[] tokenId;
        uint256 paymentTime;
        uint256 paymentRate;
        address lockerOwner;
        address tokenAddress;
    }

    Globals public globals;

    // Address of single provider, is zero address if there is no single provider
    address public singleProvider;

    // Minimum the owner wants for the loan. If less than this contributors refunded
    uint256 public floorAsked;

    // Maximum the owner wants for the loan
    uint256 public totalAsked;

    // How many tokens have been collected for far for this loan
    uint256 public totalCollected;

    // Balance contributors can claim at a given moment
    uint256 public claimableBalance;

    // Balance the locker owner still owes
    uint256 public remainingBalance;

    // Time next payoff must happen to avoid penalties
    uint256 public nextDueTime;

    // Timestamp initialize was called
    uint256 public creationTime;

    // How much a user has contributed to loan during contribution phase
    mapping(address => uint256) public contributions;

    // How much a user has received payed back for their potion of contributing to the loan
    mapping(address => uint256) public compensations;

    // Event for when the single provider is established
    event SingleProvider(
        address singleProvider
    );

    // Event for when the loan payback is made
    event PaymentMade(
        uint256 paymentAmount,
        address paymentAddress
    );

    // Event for when the contributor gets refunded
    event RefundMade(
        uint256 refundAmount,
        address refundAddress
    );

    // Event for when the contributor claims funds
    event ClaimMade(
        uint256 claimAmount,
        address claimAddress
    );

    // Event for when the loan is liquidated or defaulted
    event Liquidated(
        address liquidatorAddress
    );

    // Event for when the interest rate is increased
    event PaymentRateIncrease(
        uint256 newRateIncrease
    );

    // Event for when the payback time is decreased
    event PaymentTimeDecrease(
        uint256 newPaymentTime
    );
}
"},"LiquidHelper.sol":{"content":"// SPDX-License-Identifier: WISE

pragma solidity =0.8.12;

import "./LiquidBase.sol";

contract LiquidHelper is LiquidBase {

    /**
     * @dev encoding for transfer
     */
    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                "transfer(address,uint256)"
            )
        )
    );

    /**
     * @dev encoding for transferFrom
     */
    bytes4 constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                "transferFrom(address,address,uint256)"
            )
        )
    );

    /**
     * @dev returns IDs of NFTs being held
     */
    function getTokens()
        public
        view
        returns (uint256[] memory)
    {
        return globals.tokenId;
    }

    /**
     * @dev returns true if contributions have not reached min asked
     */
    function floorNotReached()
        public
        view
        returns (bool)
    {
        return contributionPhase() == false && belowFloorAsked() == true;
    }

    /**
     * @dev returns true if the provider address is not the single provider
     */
    function notSingleProvider(
        address _checkAddress
    )
        public
        view
        returns (bool)
    {
        address provider = singleProvider;
        return
            provider != _checkAddress &&
            provider != ZERO_ADDRESS;
    }

    /**
     * @dev returns true if the contributor will reach the ceiling asked with the provided token amount
     */
    function reachedTotal(
        address _contributor,
        uint256 _tokenAmount
    )
        public
        view
        returns (bool)
    {
        return contributions[_contributor] + _tokenAmount >= totalAsked;
    }

    /**
     * @dev returns true if locker has not been enabled within 7 days after contribution phase
     */
    function missedActivate()
        public
        view
        returns (bool)
    {
        return
            floorNotReached() &&
            startingTimestamp() + DEADLINE_TIME < block.timestamp;
    }

    /**
     * @dev returns true if owner has not paid back within 7 days of last payment
     */
    function missedDeadline()
        public
        view
        returns (bool)
    {
        uint256 nextDueOrDeadline = nextDueTime > paybackTimestamp()
            ? paybackTimestamp()
            : nextDueTime;

        return
            nextDueTime > 0 &&
            nextDueOrDeadline + DEADLINE_TIME < block.timestamp;
    }

    /**
     * @dev returns true total collected is below the min asked
     */
    function belowFloorAsked()
        public
        view
        returns (bool)
    {
        return totalCollected < floorAsked;
    }

    /**
     * @dev returns true if nextDueTime is 0, mean it has not been initialized (unix timestamp)
     */
    function paymentTimeNotSet()
        public
        view
        returns (bool)
    {
        return nextDueTime == 0;
    }

    /**
     * @dev returns true if contract is in contribution phase time window
     */
    function contributionPhase()
        public
        view
        returns (bool)
    {
        return timeSince(creationTime) < CONTRIBUTION_TIME;
    }

    /**
     * @dev returns final due time of loan
     */
    function paybackTimestamp()
        public
        view
        returns (uint256)
    {
        return startingTimestamp() + globals.paymentTime;
    }

    /**
     * @dev returns approximate time the loan will/did start
     */
    function startingTimestamp()
        public
        view
        returns (uint256)
    {
        return creationTime + CONTRIBUTION_TIME;
    }

    /**
     * @dev returns address to transfer NFT to in event of liquidation
     */
    function liquidateTo()
        public
        view
        returns (address)
    {
        return singleProvider == ZERO_ADDRESS
            ? TRUSTEE_MULTISIG
            : singleProvider;
    }

    /**
     * @dev returns bool if owner was removed
     */
    function ownerlessLocker()
        public
        view
        returns (bool)
    {
        return globals.lockerOwner == ZERO_ADDRESS;
    }

    /**
     * @dev returns calc of time since a certain timestamp to block timestamp
     */
    function timeSince(
        uint256 _timeStamp
    )
        public
        view
        returns (uint256)
    {
        return block.timestamp - _timeStamp;
    }

    /**
     * @dev sets due time to 0
     */
    function _revokeDueTime()
        internal
    {
        nextDueTime = 0;
    }

    /**
     * @dev adds a contribution on to the currently stored amount of contributions for a user
     */
    function _increaseContributions(
        address _contributorsAddress,
        uint256 _contributionAmount
    )
        internal
    {
        contributions[_contributorsAddress] =
        contributions[_contributorsAddress] + _contributionAmount;
    }

    /**
     * @dev adds an amount to totalCollected
     */
    function _increaseTotalCollected(
        uint256 _increaseAmount
    )
        internal
    {
        totalCollected =
        totalCollected + _increaseAmount;
    }

    /**
     * @dev subs an amount to totalCollected
     */
    function _decreaseTotalCollected(
        uint256 _decreaseAmount
    )
        internal
    {
        totalCollected =
        totalCollected - _decreaseAmount;
    }

    /**
     * @dev Helper function to add payment tokens and penalty tokens to their internal variables
     * Also calculates remainingBalance due for the owner.
     */
    function _adjustBalances(
        uint256 _paymentTokens,
        uint256 _penaltyTokens
    )
        internal
    {
        claimableBalance = claimableBalance
            + _paymentTokens;

        uint256 newBalance = remainingBalance
            + _penaltyTokens;

        remainingBalance = _paymentTokens < newBalance
            ? newBalance - _paymentTokens : 0;
    }

    /**
     * @dev does an erc20 transfer then check for success
     */
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "LiquidHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @dev does an erc20 transferFrom then check for success
     */
    function _safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            "LiquidHelper: TRANSFER_FROM_FAILED"
        );
    }
}
"},"LiquidLocker.sol":{"content":"// SPDX-License-Identifier: WISE

pragma solidity =0.8.12;

import "./LiquidHelper.sol";
import "./LiquidTransfer.sol";

contract LiquidLocker is LiquidTransfer, LiquidHelper {

    modifier onlyLockerOwner() {
        require(
           msg.sender == globals.lockerOwner,
           "LiquidLocker: INVALID_OWNER"
        );
        _;
    }

    modifier onlyFromFactory() {
        require(
            msg.sender == FACTORY_ADDRESS,
            "LiquidLocker: INVALID_ADDRESS"
        );
        _;
    }

    modifier onlyDuringContributionPhase() {
        require(
            contributionPhase() == true &&
            paymentTimeNotSet() == true,
            "LiquidLocker: INVALID_PHASE"
        );
        _;
    }

    /**
     * @dev This is a call made by the constructor to set up variables on a new locker.
     * This is essentially equivalent to a constructor, but for our gas saving cloning operation instead.
     */
    function initialize(
        uint256[] calldata _tokenId,
        address _tokenAddress,
        address _tokenOwner,
        uint256 _floorAsked,
        uint256 _totalAsked,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        external
        onlyFromFactory
    {
        globals = Globals({
            tokenId: _tokenId,
            lockerOwner: _tokenOwner,
            tokenAddress: _tokenAddress,
            paymentTime: _paymentTime,
            paymentRate: _paymentRate
        });

        floorAsked = _floorAsked;
        totalAsked = _totalAsked;
        creationTime = block.timestamp;
    }

     /* @dev During the contribution phase, the owner can increase the rate they will pay for the loan.
     * The owner can only increase the rate to make the deal better for contributors, he cannot decrease it.
     */
    function increasePaymentRate(
        uint256 _newPaymntRate
    )
        external
        onlyLockerOwner
        onlyDuringContributionPhase
    {
        require(
            _newPaymntRate > globals.paymentRate,
            "LiquidLocker: INVALID_INCREASE"
        );

        globals.paymentRate = _newPaymntRate;

        emit PaymentRateIncrease(
            _newPaymntRate
        );
    }

    /**
     * @dev During the contribution phase, the owner can decrease the duration of the loan.
     * The owner can only decrease the loan to a shorter duration, he cannot make it longer once the
     * contribution phase has started.
     */
    function decreasePaymentTime(
        uint256 _newPaymentTime
    )
        external
        onlyLockerOwner
        onlyDuringContributionPhase
    {
        require(
            _newPaymentTime < globals.paymentTime,
            "LiquidLocker: INVALID_DECREASE"
        );

        globals.paymentTime = _newPaymentTime;

        emit PaymentTimeDecrease(
            _newPaymentTime
        );
    }

    /* @dev During the contribution phase, the owner can increase the rate and decrease time
    * This function executes both actions at the same time to save on one extra transaction
    */
    function updateSettings(
        uint256 _newPaymntRate,
        uint256 _newPaymentTime
    )
        external
        onlyLockerOwner
        onlyDuringContributionPhase
    {
        require(
            _newPaymntRate > globals.paymentRate,
            "LiquidLocker: INVALID_RATE"
        );

        require(
            _newPaymentTime < globals.paymentTime,
            "LiquidLocker: INVALID_TIME"
        );

        globals.paymentRate = _newPaymntRate;
        globals.paymentTime = _newPaymentTime;

        emit PaymentRateIncrease(
            _newPaymntRate
        );

        emit PaymentTimeDecrease(
            _newPaymentTime
        );
    }

    /**
     * @dev Public users can add tokens to the pool to be used for the loan.
     * The contributions for each user along with the total are recorded for splitting funds later.
     * If a user contributes up to the maximum asked on a loan, they will become the sole provider
     * (See _usersIncrease and _reachedTotal for functionality on becoming the sole provider)
     * The sole provider will receive the token instead of the trusted multisig in the case if a liquidation.
     */
    function makeContribution(
        uint256 _tokenAmount,
        address _tokenHolder
    )
        external
        onlyFromFactory
        onlyDuringContributionPhase
        returns (
            uint256 totalIncrease,
            uint256 usersIncrease
        )
    {
        totalIncrease = _totalIncrease(
            _tokenAmount
        );

        usersIncrease = _usersIncrease(
            _tokenHolder,
            _tokenAmount,
            totalIncrease
        );

        _increaseContributions(
            _tokenHolder,
            usersIncrease
        );

        _increaseTotalCollected(
            totalIncrease
        );
    }

    /**
     * @dev Check if this contribution adds enough for the user to become the sole contributor.
     * Make them the sole contributor if so, otherwise return the totalAmount
     */
    function _usersIncrease(
        address _tokenHolder,
        uint256 _tokenAmount,
        uint256 _totalAmount
    )
        internal
        returns (uint256)
    {
        return reachedTotal(_tokenHolder, _tokenAmount)
            ? _reachedTotal(_tokenHolder)
            : _totalAmount;
    }

    /**
     * @dev Calculate whether a contribution go over the maximum asked.
     * If so only allow it to go up to the totalAsked an not over
     */
    function _totalIncrease(
        uint256 _tokenAmount
    )
        internal
        view
        returns (uint256 totalIncrease)
    {
        totalIncrease = totalCollected
            + _tokenAmount < totalAsked
            ? _tokenAmount : totalAsked - totalCollected;
    }

    /**
     * @dev Make the user the singleProvider.
     * Making the user the singleProvider allows all other contributors to claim their funds back.
     * Essentially if you contribute the whole maximum asked on your own you will kick everyone else out
     */
    function _reachedTotal(
        address _tokenHolder
    )
        internal
        returns (uint256 totalReach)
    {
        require(
            singleProvider == ZERO_ADDRESS,
            "LiquidLocker: PROVIDER_EXISTS"
        );

        totalReach =
        totalAsked - contributions[_tokenHolder];

        singleProvider = _tokenHolder;

        emit SingleProvider(
            _tokenHolder
        );
    }

    /**
     * @dev Locker owner calls this once the contribution phase is over to receive the funds for the loan.
     * This can only be done once the floor is reached, and can be done before the end of the contribution phase.
     */
    function enableLocker(
        uint256 _prepayAmount
    )
        external
        onlyLockerOwner
    {
        require(
            belowFloorAsked() == false,
            "LiquidLocker: BELOW_FLOOR"
        );

        require(
            paymentTimeNotSet() == true,
            "LiquidLocker: ENABLED_LOCKER"
        );

        (

        uint256 totalPayback,
        uint256 epochPayback,
        uint256 teamsPayback

        ) = calculatePaybacks(
            totalCollected,
            globals.paymentTime,
            globals.paymentRate
        );

        claimableBalance = claimableBalance
            + _prepayAmount;

        remainingBalance = totalPayback
            - _prepayAmount;

        nextDueTime = startingTimestamp()
            + _prepayAmount
            / epochPayback;

        _safeTransfer(
            PAYMENT_TOKEN,
            msg.sender,
            totalCollected - _prepayAmount - teamsPayback
        );

        _safeTransfer(
            PAYMENT_TOKEN,
            TRUSTEE_MULTISIG,
            teamsPayback
        );

        emit PaymentMade(
            _prepayAmount,
            msg.sender
        );
    }

    /**
     * @dev Until floor is not reached the owner has ability to remove his NFTs
       as soon as floor is reached the owner can no longer back-out from the loan
     */
    function disableLocker()
        external
        onlyLockerOwner
    {
        require(
            belowFloorAsked() == true,
            "LiquidLocker: FLOOR_REACHED"
        );

        _returnOwnerTokens();
    }

    /**
     * @dev Internal function that does the work for disableLocker
       it returns all the NFT tokens to the original owner.
     */
    function _returnOwnerTokens()
        internal
    {
        address lockerOwner = globals.lockerOwner;
        globals.lockerOwner = ZERO_ADDRESS;

        for (uint256 i = 0; i < globals.tokenId.length; i++) {
            _transferNFT(
                address(this),
                lockerOwner,
                globals.tokenAddress,
                globals.tokenId[i]
            );
        }
    }

    /**
     * @dev There are a couple edge cases with extreme payment rates that cause enableLocker to revert.
     * These are never callable on our UI and doing so would require a manual transaction.
     * This function will disable a locker in this senario, allow contributors to claim their money and transfer the NFT back to the owner.
     * Only the team multisig has permission to do this
     */
    function rescueLocker()
        external
    {
        require(
            msg.sender == TRUSTEE_MULTISIG,
            "LiquidLocker: INVALID_TRUSTEE"
        );

        require(
            timeSince(creationTime) > DEADLINE_TIME,
            "LiquidLocker: NOT_ENOUGHT_TIME"
        );

        require(
            paymentTimeNotSet() == true,
           "LiquidLocker: ALREADY_STARTED"
        );

        _returnOwnerTokens();
    }

    /**
     * @dev Allow users to claim funds when a locker is disabled
     */
    function refundDueExpired(
        address _refundAddress
    )
        external
    {
        require(
            floorNotReached() == true ||
            ownerlessLocker() == true,
            "LiquidLocker: ENABLED_LOCKER"
        );

        uint256 tokenAmount = contributions[_refundAddress];

        _refundTokens(
            tokenAmount,
            _refundAddress
        );

        _decreaseTotalCollected(
            tokenAmount
        );
    }

    /**
     * @dev Allow users to claim funds when a someone kicks them out to become the single provider
     */
    function refundDueSingle(
        address _refundAddress
    )
        external
    {
        require(
            notSingleProvider(_refundAddress) == true,
            "LiquidLocker: INVALID_SENDER"
        );

        _refundTokens(
            contributions[_refundAddress],
            _refundAddress
        );
    }

    /**
     * @dev Someone can add funds to the locker and they will be split among the contributors
     * This does not count as a payment on the loan.
     */
    function donateFunds(
        uint256 _donationAmount
    )
        external
        onlyFromFactory
    {
        claimableBalance =
        claimableBalance + _donationAmount;
    }

    /**
     * @dev Locker owner can payback funds.
     * Penalties are given if the owner does not pay the earnings linearally over the loan duration.
     * If the owner pays back the earnings, loan amount, and penalties aka fully pays off the loan
     * they will be transfered their nft back
     */
    function payBackFunds(
        uint256 _paymentAmount,
        address _paymentAddress
    )
        external
        onlyFromFactory
    {
        require(
            missedDeadline() == false,
            "LiquidLocker: TOO_LATE"
        );

        _adjustBalances(
            _paymentAmount,
            _penaltyAmount()
        );

        emit PaymentMade(
            _paymentAmount,
            _paymentAddress
        );

        if (remainingBalance == 0) {

            _revokeDueTime();
            _returnOwnerTokens();

            return;
        }

        uint256 payedTimestamp = nextDueTime;
        uint256 finalTimestamp = paybackTimestamp();

        if (payedTimestamp == finalTimestamp) return;

        uint256 purchasedTime = _paymentAmount
            / calculateEpoch(
                totalCollected,
                globals.paymentTime,
                globals.paymentRate
            );

        require(
            purchasedTime >= SECONDS_IN_DAY,
            "LiquidLocker: Minimum Payoff"
        );

        payedTimestamp = payedTimestamp > block.timestamp
            ? payedTimestamp + purchasedTime
            : block.timestamp + purchasedTime;

        nextDueTime = payedTimestamp;
    }

    /**
     * @dev If the owner has missed payments by 7 days this call will transfer the NFT to either the
     * singleProvider address or the trusted multisig to be auctioned
     */
    function liquidateLocker()
        external
    {
        require(
            missedActivate() == true ||
            missedDeadline() == true,
            "LiquidLocker: TOO_EARLY"
        );

        _revokeDueTime();
        globals.lockerOwner = ZERO_ADDRESS;

        for (uint256 i = 0; i < globals.tokenId.length; i++) {
            _transferNFT(
                address(this),
                liquidateTo(),
                globals.tokenAddress,
                globals.tokenId[i]
            );
        }

        emit Liquidated(
            msg.sender
        );
    }

    /**
     * @dev Public pure accessor for _getPenaltyAmount
     */
    function penaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        external
        pure
        returns (uint256 result)
    {
        result = _getPenaltyAmount(
            _totalCollected,
            _lateDaysAmount
        );
    }

    /**
     * @dev calculate how much in penalties the owner has due to late time since last payment
     */
    function _penaltyAmount()
        internal
        view
        returns (uint256 amount)
    {
        amount = _getPenaltyAmount(
            totalCollected,
            getLateDays()
        );
    }

    /**
     * @dev Calculate penalties. .5% for first 4 days and 1% for each day after the 4th
     */
    function _getPenaltyAmount(
        uint256 _totalCollected,
        uint256 _lateDaysAmount
    )
        private
        pure
        returns (uint256 penalty)
    {
        penalty = _totalCollected
            * _daysBase(_lateDaysAmount)
            / 200;
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */
    function _daysBase(
        uint256 _daysAmount
    )
        internal
        pure
        returns (uint256 res)
    {
        res = _daysAmount > 4
            ? _daysAmount * 2 - 4
            : _daysAmount;
    }

    /**
     * @dev Helper for the days math of calcualte penalties.
     * Returns +1 per day before the 4th day and +2 for each day after the 4th day
     */
    function getLateDays()
        public
        view
        returns (uint256 late)
    {
        late = block.timestamp > nextDueTime
            ? (block.timestamp - nextDueTime) / SECONDS_IN_DAY : 0;
    }

    /**
     * @dev Calulate how much the usage fee takes off a payments,
     * and how many tokens are due per second of loan
     * (epochPayback is amount of tokens to extend loan by 1 second. Only need to pay off earnings)
     */
    function calculatePaybacks(
        uint256 _totalValue,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        public
        pure
        returns (
            uint256 totalPayback,
            uint256 epochPayback,
            uint256 teamsPayback
        )
    {
        totalPayback = (_paymentRate + PRECISION_R)
            * _totalValue
            / PRECISION_R;

        teamsPayback = (totalPayback - _totalValue)
            * FEE
            / PRECISION_R;

        epochPayback = (totalPayback - _totalValue)
            / _paymentTime;
    }

    /**
     * @dev Calculate how many sends should be added before the next payoff is due based on payment amount
     */
    function calculateEpoch(
        uint256 _totalValue,
        uint256 _paymentTime,
        uint256 _paymentRate
    )
        public
        pure
        returns (uint256 result)
    {
        result = _totalValue
            * _paymentRate
            / PRECISION_R
            / _paymentTime;
    }

    /**
     * @dev Claim payed back tokens
     */
    function claimInterest()
        external
    {
        address provider = singleProvider;

        require(
            provider == ZERO_ADDRESS ||
            provider == msg.sender,
            "LiquidLocker: NOT_AUTHORIZED"
        );

        _claimInterest(
            msg.sender
        );
    }

    /**
     * @dev Does the internal work of claiming payed back tokens.
     * Amount to claimed is based on share of contributions, and we record what someone has claimed in the
     * compensations mapping
     */
    function _claimInterest(
        address _claimAddress
    )
        internal
    {
        uint256 claimAmount = claimableBalance
            * contributions[_claimAddress]
            / totalCollected;

        uint256 tokensToTransfer = claimAmount
            - compensations[_claimAddress];

        compensations[_claimAddress] = claimAmount;

        _safeTransfer(
            PAYMENT_TOKEN,
            _claimAddress,
            tokensToTransfer
        );

        emit ClaimMade(
            tokensToTransfer,
            _claimAddress
        );
    }

    /**
     * @dev Does the internal reset and transfer for refunding tokens on either condition that refunds are issued
     */
    function _refundTokens(
        uint256 _refundAmount,
        address _refundAddress
    )
        internal
    {
        contributions[_refundAddress] =
        contributions[_refundAddress] - _refundAmount;

        _safeTransfer(
            PAYMENT_TOKEN,
            _refundAddress,
            _refundAmount
        );

        emit RefundMade(
            _refundAmount,
            _refundAddress
        );
    }
}
"},"LiquidTransfer.sol":{"content":"// SPDX-License-Identifier: WISE

pragma solidity =0.8.12;

contract LiquidTransfer {

    // cryptoPunks contract address
    address constant PUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    // local: 0xEb59fE75AC86dF3997A990EDe100b90DDCf9a826;
    // ropsten: 0x2f1dC6E3f732E2333A7073bc65335B90f07fE8b0;
    // mainnet: 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    // cryptoKitties contract address
    address constant KITTIES = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    /* @dev
    * Checks if contract is nonstandard, does transfer according to contract implementation
    */
    function _transferNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        if (_tokenAddress == KITTIES) {
            data = abi.encodeWithSignature(
                "transfer(address,uint256)",
                _to,
                _tokenId
            );
        } else if (_tokenAddress == PUNKS) {
            data = abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                _to,
                _tokenId
            );
        } else {
            data = abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                _from,
                _to,
                _tokenId
            );
        }

        (bool success,) = address(_tokenAddress).call(
            data
        );

        require(
            success == true,
            'NFT_TRANSFER_FAILED'
        );
    }

    /* @dev
    * Checks if contract is nonstandard, does transferFrom according to contract implementation
    */
    function _transferFromNFT(
        address _from,
        address _to,
        address _tokenAddress,
        uint256 _tokenId
    )
        internal
    {
        bytes memory data;

        if (_tokenAddress == KITTIES) {
            data = abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _from,
                _to,
                _tokenId
            );
        } else if (_tokenAddress == PUNKS) {
            bytes memory punkIndexToAddress = abi.encodeWithSignature(
                "punkIndexToAddress(uint256)",
                _tokenId
            );

            (bool checkSuccess, bytes memory result) = address(_tokenAddress).staticcall(
                punkIndexToAddress
            );

            (address owner) = abi.decode(
                result,
                (address)
            );

            require(
                checkSuccess &&
                owner == msg.sender,
                'INVALID_OWNER'
            );

            bytes memory buyData = abi.encodeWithSignature(
                "buyPunk(uint256)",
                _tokenId
            );

            (bool buySuccess, bytes memory buyResultData) = address(_tokenAddress).call(
                buyData
            );

            require(
                buySuccess,
                string(buyResultData)
            );

            data = abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                _to,
                _tokenId
            );

        } else {
            data = abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                _from,
                _to,
                _tokenId
            );
        }

        (bool success, bytes memory resultData) = address(_tokenAddress).call(
            data
        );

        require(
            success,
            string(resultData)
        );
    }

    event ERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns (bytes4)
    {
        emit ERC721Received(
            _operator,
            _from,
            _tokenId,
            _data
        );

        return this.onERC721Received.selector;
    }
}
"}}