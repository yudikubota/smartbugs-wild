{"Agent.sol":{"content":"pragma solidity ^0.5.10;

import "./Ownable.sol";

/**
 * @title Agent contract - base contract with an agent
 */
contract Agent is Ownable {
    mapping(address => bool) public Agents;

    event UpdatedAgent(address _agent, bool _status);

    modifier onlyAgent() {
        assert(Agents[msg.sender]);
        _;
    }

    function updateAgent(address _agent, bool _status) public onlyOwner {
        assert(_agent != address(0));
        Agents[_agent] = _status;

        emit UpdatedAgent(_agent, _status);
    }
}
"},"CashBackMoney.sol":{"content":"pragma solidity ^0.5.10;

import "./Agent.sol";
import "./SafeMath.sol";
import "./CashBackMoneyI.sol";

/**
 * @title CashBackMoney Investing Contract
 */
contract CashBackMoney is CashBackMoneyI, Agent {
    using SafeMath for uint256;

    // Constants
    uint256 public constant amount1 = 0.05 ether;
    uint256 public constant amount2 = 0.10 ether;
    uint256 public constant amount3 = 0.50 ether;
    uint256 public constant amount4 = 1.00 ether;
    uint256 public constant amount5 = 5.00 ether;
    uint256 public constant amount6 = 10.00 ether;

    uint256 public constant subs_amount1 = 1.00 ether;
    uint256 public constant subs_amount2 = 5.00 ether;
    uint256 public constant subs_amount3 = 10.00 ether;

    uint256 public constant subs_amount_with_fee1 = 1.18 ether;
    uint256 public constant subs_amount_with_fee2 = 5.90 ether;
    uint256 public constant subs_amount_with_fee3 = 11.80 ether;

    uint256 days1 = 1 days;
    uint256 hours24 = 24 hours;
    uint256 hours3 = 3 hours;

    // Variables
    bool public production = false;
    uint256 public deploy_block;

    address payable public reward_account;
    uint256 public reward;
    uint256 public start_point;

    uint256 public NumberOfParticipants = 0;
    uint256 public NumberOfClicks = 0;
    uint256 public NumberOfSubscriptions = 0;
    uint256 public ProfitPayoutAmount = 0;
    uint256 public FundBalance = 0;

    uint256 public LastRefererID = 0;

    // RefererID[referer address]
    mapping(address => uint256) public RefererID;

    // RefererAddr[referer ID]
    mapping(uint256 => address) public RefererAddr;

    // Referer[Referal address]
    mapping(address => uint256) public Referer;

    // Participants[address]
    mapping(address => bool) public Participants;

    // OwnerAmountStatus[owner address][payXamount]
    mapping(address => mapping(uint256 => bool)) public OwnerAmountStatus;

    // RefClickCount[referer address][payXamount]
    mapping(address => mapping(uint256 => uint256)) public RefClickCount;

    // OwnerTotalProfit[owner address]
    mapping(address => uint256) public OwnerTotalProfit;

    // RefTotalClicks[referer address]
    mapping(address => uint256) public RefTotalClicks;

    // RefTotalIncome[referer address]
    mapping(address => uint256) public RefTotalIncome;

    // Balances[address][level][payXamount]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public Balances;

    // WithdrawDate[address][level][payXamount]
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public WithdrawDate;

    // OwnerAutoClickCount[owner address][msg.value][GetPeriod(now)]
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public OwnerAutoClickCount;

    // RefAutoClickCount[referer address][msg.value][GetPeriod(now)]
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public RefAutoClickCount;

    // AutoBalances[address][payXamount]
    mapping(address => mapping(uint256 => bool)) public AutoBalances;

    // WithdrawAutoDate[address][payXamount]
    mapping(address => mapping(uint256 => uint256)) public WithdrawAutoDate;

    // Subscriptions[address][payXamount]
    mapping(address => mapping(uint256 => uint256)) public Subscriptions;

    // Intermediate[address][payXamount]
    mapping(address => mapping(uint256 => uint256)) public Intermediate;

    // RefSubscCount[referer address][payXamount][Period]
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public RefSubscCount;

    // RefSubscStatus[owner address][payXamount][Period]
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public RefSubscStatus;

    // Events
    event ChangeContractBalance(string text);

    event ChangeClickRefefalNumbers(
        address indexed referer,
        uint256 amount,
        uint256 number
    );

    event AmountInvestedByPay(address indexed owner, uint256 amount);
    event AmountInvestedByAutoPay(address indexed owner, uint256 amount);
    event AmountInvestedBySubscription(address indexed owner, uint256 amount);

    event AmountWithdrawnFromPay(address indexed owner, uint256 amount);
    event AmountWithdrawnFromAutoPay(address indexed owner, uint256 amount);
    event AmountWithdrawnFromSubscription(
        address indexed owner,
        uint256 amount
    );

    /**
    * Contructor
    */
    constructor(
        address payable _reward_account,
        uint256 _reward,
        uint256 _start_point,
        bool _mode
    ) public {
        reward_account = _reward_account;
        reward = _reward;
        start_point = _start_point;

        production = _mode;
        deploy_block = block.number;
    }

    modifier onlyFixedAmount(uint256 _amount) {
        require(
            _amount == amount1 ||
                _amount == amount2 ||
                _amount == amount3 ||
                _amount == amount4 ||
                _amount == amount5 ||
                _amount == amount6,
            "CashBackMoney: wrong msg.value"
        );
        _;
    }

    modifier onlyFixedAmountSubs(uint256 _amount) {
        require(
            _amount == subs_amount_with_fee1 ||
                _amount == subs_amount_with_fee2 ||
                _amount == subs_amount_with_fee3,
            "CashBackMoney: wrong msg.value for subscription"
        );
        _;
    }

    modifier onlyFixedAmountWithdrawSubs(uint256 _amount) {
        require(
            _amount == subs_amount1 ||
                _amount == subs_amount2 ||
                _amount == subs_amount3,
            "CashBackMoney: wrong msg.value for subscription"
        );
        _;
    }

    modifier onlyInStagingMode() {
        require(
            !production,
            "CashBackMoney: this function can only be used in the stage mode"
        );
        _;
    }

    /**
    *  Pay or Withdraw all possible "pay" amount
    */
    function() external payable {
        if (
            (msg.value == subs_amount_with_fee1) ||
            (msg.value == subs_amount_with_fee2) ||
            (msg.value == subs_amount_with_fee3)
        ) {
            Subscribe(0);
        } else if (msg.value > 0) {
            PayAll(msg.value);
        } else {
            WithdrawPayAll();
            WithdrawSubscribeAll();
        }
    }

    /**
    * To replenish the balance of the contract
    */
    function TopUpContract() external payable {
        require(msg.value > 0, "TopUpContract: msg.value must be great than 0");
        emit ChangeContractBalance("Thank you very much");
    }

    /**
    *  GetPeriod - calculate period for all functions
    */
    function GetPeriod(uint256 _timestamp)
        internal
        view
        returns (uint256 _period)
    {
        return (_timestamp.sub(start_point)).div(days1);
    }

    /**
    *  Accept payment
    */
    function Pay(uint256 _level, uint256 _refererID)
        external
        payable
        onlyFixedAmount(msg.value)
    {
        // If a RefererID is not yet assigned
        if (RefererID[msg.sender] == 0) {
            CreateRefererID(msg.sender);
        }

        require(
            RefererID[msg.sender] != _refererID,
            "Pay: you cannot be a referral to yourself"
        );
        require(_level > 0 && _level < 4, "Pay: level can only be 1,2 or 3");
        require(
            !Balances[msg.sender][_level][msg.value],
            "Pay: amount already paid"
        );

        // If owner invest this amount for the first time
        if (!OwnerAmountStatus[msg.sender][msg.value]) {
            OwnerAmountStatus[msg.sender][msg.value] = true;
        }

        // If a referrer is not yet installed
        if ((Referer[msg.sender] == 0) && (_refererID != 0)) {
            Referer[msg.sender] = _refererID;
        }

        // Add to Total & AutoClick
        if (
            (Referer[msg.sender] != 0) &&
            (OwnerAmountStatus[RefererAddr[Referer[msg.sender]]][msg.value])
        ) {
            RefTotalClicks[RefererAddr[Referer[msg.sender]]] += 1;
            RefTotalIncome[RefererAddr[Referer[msg.sender]]] += msg.value;

            RefClickCount[RefererAddr[Referer[msg.sender]]][msg.value] += 1;
            emit ChangeClickRefefalNumbers(
                RefererAddr[Referer[msg.sender]],
                msg.value,
                RefClickCount[RefererAddr[Referer[msg.sender]]][msg.value]
            );

            uint256 Current = GetPeriod(now);
            uint256 Start = Current - 30;

            OwnerAutoClickCount[msg.sender][msg.value][Current] += 1;

            uint256 CountOp = 0;

            for (uint256 k = Start; k < Current; k++) {
                CountOp += OwnerAutoClickCount[msg.sender][msg.value][k];
            }

            if (CountOp >= 30) {
                RefAutoClickCount[RefererAddr[Referer[msg.sender]]][msg
                    .value][Current] += 1;
            }
        }

        uint256 refs;
        uint256 wd_time;

        if (_level == 1) {
            if (RefClickCount[msg.sender][msg.value] > 21) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][msg.value];
            }
        }

        if (_level == 2) {
            require(
                RefClickCount[msg.sender][msg.value] >= 21,
                "Pay: not enough referrals"
            );
            if (RefClickCount[msg.sender][msg.value] > 42) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][msg.value].sub(21);
            }
        }

        if (_level == 3) {
            require(
                RefClickCount[msg.sender][msg.value] >= 42,
                "Pay: not enough referrals"
            );
            if (RefClickCount[msg.sender][msg.value] > 63) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][msg.value].sub(42);
            }
        }

        wd_time = now.add(hours24);
        wd_time = wd_time.sub((refs.div(3)).mul(hours3));

        RefClickCount[msg.sender][msg.value] = RefClickCount[msg.sender][msg
            .value]
            .sub(refs.div(3).mul(3));
        emit ChangeClickRefefalNumbers(
            msg.sender,
            msg.value,
            RefClickCount[msg.sender][msg.value]
        );

        Balances[msg.sender][_level][msg.value] = true;
        WithdrawDate[msg.sender][_level][msg.value] = wd_time;

        reward_account.transfer(msg.value.perc(reward));

        if (!Participants[msg.sender]) {
            Participants[msg.sender] = true;
            NumberOfParticipants += 1;
        }

        FundBalance += msg.value.perc(reward);
        NumberOfClicks += 1;
        emit AmountInvestedByPay(msg.sender, msg.value);
    }

    /**
    *  Withdraw "pay" sum
    */
    function WithdrawPay(uint256 _level, uint256 _amount)
        external
        onlyFixedAmount(_amount)
    {
        require(
            Balances[msg.sender][_level][_amount],
            "WithdrawPay: amount has not yet been paid"
        );
        require(
            now >= WithdrawDate[msg.sender][_level][_amount],
            "WithdrawPay: time has not come yet"
        );

        Balances[msg.sender][_level][_amount] = false;
        WithdrawDate[msg.sender][_level][_amount] = 0;

        uint256 Amount = _amount.add(_amount.perc(100));
        msg.sender.transfer(Amount);

        OwnerTotalProfit[msg.sender] += _amount.perc(100);
        ProfitPayoutAmount += Amount;
        emit AmountWithdrawnFromPay(msg.sender, Amount);
    }

    /**
    *  Accept payment and its automatic distribution
    */
    function PayAll(uint256 _amount) internal onlyFixedAmount(_amount) {
        uint256 refs;
        uint256 wd_time;
        uint256 level = 0;

        // If a RefererID is not yet assigned
        if (RefererID[msg.sender] == 0) {
            CreateRefererID(msg.sender);
        }

        if (!Balances[msg.sender][1][_amount]) {
            level = 1;
            if (RefClickCount[msg.sender][_amount] > 21) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][_amount];
            }
        }

        if (
            (level == 0) &&
            (!Balances[msg.sender][2][_amount]) &&
            (RefClickCount[msg.sender][_amount] >= 21)
        ) {
            level = 2;
            if (RefClickCount[msg.sender][_amount] > 42) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][_amount].sub(21);
            }
        }

        if (
            (level == 0) &&
            (!Balances[msg.sender][3][_amount]) &&
            (RefClickCount[msg.sender][_amount] >= 42)
        ) {
            level = 3;
            if (RefClickCount[msg.sender][_amount] > 63) {
                refs = 21;
            } else {
                refs = RefClickCount[msg.sender][_amount].sub(42);
            }
        }

        require(
            level > 0,
            "PayAll: amount already paid or not enough referals"
        );

        wd_time = now.add(hours24);
        wd_time = wd_time.sub((refs.div(3)).mul(hours3));

        RefClickCount[msg.sender][msg.value] = RefClickCount[msg.sender][msg
            .value]
            .sub(refs.div(3).mul(3));
        emit ChangeClickRefefalNumbers(
            msg.sender,
            msg.value,
            RefClickCount[msg.sender][msg.value]
        );

        Balances[msg.sender][level][_amount] = true;
        WithdrawDate[msg.sender][level][_amount] = wd_time;

        reward_account.transfer(_amount.perc(reward));

        if (!Participants[msg.sender]) {
            Participants[msg.sender] = true;
            NumberOfParticipants += 1;
        }

        FundBalance += _amount.perc(reward);
        NumberOfClicks += 1;
        emit AmountInvestedByPay(msg.sender, _amount);
    }

    /**
    *  Withdraw all possible "pay" sum
    */
    function WithdrawPayAll() public {
        uint256 Amount = 0;

        for (uint256 i = 1; i <= 3; i++) {
            if (
                (Balances[msg.sender][i][amount1]) &&
                (now >= WithdrawDate[msg.sender][i][amount1])
            ) {
                Balances[msg.sender][i][amount1] = false;
                WithdrawDate[msg.sender][i][amount1] = 0;
                Amount += amount1.add(amount1.perc(100));
                OwnerTotalProfit[msg.sender] += amount1.perc(100);
            }
            if (
                (Balances[msg.sender][i][amount2]) &&
                (now >= WithdrawDate[msg.sender][i][amount2])
            ) {
                Balances[msg.sender][i][amount2] = false;
                WithdrawDate[msg.sender][i][amount2] = 0;
                Amount += amount2.add(amount2.perc(100));
                OwnerTotalProfit[msg.sender] += amount2.perc(100);
            }
            if (
                (Balances[msg.sender][i][amount3]) &&
                (now >= WithdrawDate[msg.sender][i][amount3])
            ) {
                Balances[msg.sender][i][amount3] = false;
                WithdrawDate[msg.sender][i][amount3] = 0;
                Amount += amount3.add(amount3.perc(100));
                OwnerTotalProfit[msg.sender] += amount3.perc(100);
            }
            if (
                (Balances[msg.sender][i][amount4]) &&
                (now >= WithdrawDate[msg.sender][i][amount4])
            ) {
                Balances[msg.sender][i][amount4] = false;
                WithdrawDate[msg.sender][i][amount4] = 0;
                Amount += amount4.add(amount4.perc(100));
                OwnerTotalProfit[msg.sender] += amount4.perc(100);
            }
            if (
                (Balances[msg.sender][i][amount5]) &&
                (now >= WithdrawDate[msg.sender][i][amount5])
            ) {
                Balances[msg.sender][i][amount5] = false;
                WithdrawDate[msg.sender][i][amount5] = 0;
                Amount += amount5.add(amount5.perc(100));
                OwnerTotalProfit[msg.sender] += amount5.perc(100);
            }
            if (
                (Balances[msg.sender][i][amount6]) &&
                (now >= WithdrawDate[msg.sender][i][amount6])
            ) {
                Balances[msg.sender][i][amount6] = false;
                WithdrawDate[msg.sender][i][amount6] = 0;
                Amount += amount6.add(amount6.perc(100));
                OwnerTotalProfit[msg.sender] += amount6.perc(100);
            }
        }

        if (Amount > 0) {
            msg.sender.transfer(Amount);

            ProfitPayoutAmount += Amount;
            emit AmountWithdrawnFromPay(msg.sender, Amount);
        }
    }

    /**
    *  Accept auto payment
    */
    function AutoPay(uint256 _refererID)
        external
        payable
        onlyFixedAmount(msg.value)
    {
        // If a RefererID is not yet assigned
        if (RefererID[msg.sender] == 0) {
            CreateRefererID(msg.sender);
        }

        require(
            RefererID[msg.sender] != _refererID,
            "AutoPay: you cannot be a referral to yourself"
        );
        require(
            !AutoBalances[msg.sender][msg.value],
            "AutoPay: amount already paid"
        );

        // If a referrer is not yet installed
        if ((Referer[msg.sender] == 0) && (_refererID != 0)) {
            Referer[msg.sender] = _refererID;
        }

        // Add to Total & AutoClick
        if (
            (Referer[msg.sender] != 0) &&
            (OwnerAmountStatus[RefererAddr[Referer[msg.sender]]][msg.value])
        ) {
            RefTotalClicks[RefererAddr[Referer[msg.sender]]] += 1;
            RefTotalIncome[RefererAddr[Referer[msg.sender]]] += msg.value;

            RefClickCount[RefererAddr[Referer[msg.sender]]][msg.value] += 1;
            emit ChangeClickRefefalNumbers(
                RefererAddr[Referer[msg.sender]],
                msg.value,
                RefClickCount[RefererAddr[Referer[msg.sender]]][msg.value]
            );

            uint256 Current = GetPeriod(now);
            uint256 Start = Current - 30;

            OwnerAutoClickCount[msg.sender][msg.value][Current] += 1;

            uint256 CountOp = 0;

            for (uint256 k = Start; k < Current; k++) {
                CountOp += OwnerAutoClickCount[msg.sender][msg.value][k];
            }

            if (CountOp >= 30) {
                RefAutoClickCount[RefererAddr[Referer[msg.sender]]][msg
                    .value][Current] += 1;
            }
        }

        uint256 Current = GetPeriod(now);
        uint256 Start = Current - 30;

        uint256 Count1 = 0;
        uint256 Count2 = 0;
        uint256 Count3 = 0;
        uint256 Count4 = 0;
        uint256 Count5 = 0;
        uint256 Count6 = 0;

        for (uint256 k = Start; k < Current; k++) {
            Count1 += RefAutoClickCount[msg.sender][amount1][k];
            Count2 += RefAutoClickCount[msg.sender][amount2][k];
            Count3 += RefAutoClickCount[msg.sender][amount3][k];
            Count4 += RefAutoClickCount[msg.sender][amount4][k];
            Count5 += RefAutoClickCount[msg.sender][amount5][k];
            Count6 += RefAutoClickCount[msg.sender][amount6][k];
        }

        // Only when every slot >= 63
        require(Count1 > 62, "AutoPay: not enough autoclick1 referrals");
        require(Count2 > 62, "AutoPay: not enough autoclick2 referrals");
        require(Count3 > 62, "AutoPay: not enough autoclick3 referrals");
        require(Count4 > 62, "AutoPay: not enough autoclick4 referrals");
        require(Count5 > 62, "AutoPay: not enough autoclick5 referrals");
        require(Count6 > 62, "AutoPay: not enough autoclick6 referrals");

        AutoBalances[msg.sender][msg.value] = true;
        WithdrawAutoDate[msg.sender][msg.value] = now.add(hours24);

        reward_account.transfer(msg.value.perc(reward));

        if (!Participants[msg.sender]) {
            Participants[msg.sender] = true;
            NumberOfParticipants += 1;
        }

        FundBalance += msg.value.perc(reward);
        NumberOfClicks += 1;
        emit AmountInvestedByAutoPay(msg.sender, msg.value);
    }

    /**
    *  Withdraw "pay" sum
    */
    function WithdrawAutoPay(uint256 _amount)
        external
        onlyFixedAmount(_amount)
    {
        require(
            AutoBalances[msg.sender][_amount],
            "WithdrawAutoPay: autoclick amount has not yet been paid"
        );
        require(
            now >= WithdrawAutoDate[msg.sender][_amount],
            "WithdrawAutoPay: autoclick time has not come yet"
        );

        AutoBalances[msg.sender][_amount] = false;
        WithdrawAutoDate[msg.sender][_amount] = 0;

        uint256 Amount = _amount.add(_amount.perc(800));
        msg.sender.transfer(Amount);

        OwnerTotalProfit[msg.sender] += _amount.perc(800);
        ProfitPayoutAmount += Amount;
        emit AmountWithdrawnFromAutoPay(msg.sender, Amount);
    }

    /**
    * Buy subscription
    */
    function Subscribe(uint256 _refererID)
        public
        payable
        onlyFixedAmountSubs(msg.value)
    {
        // If a RefererID is not yet assigned
        if (RefererID[msg.sender] == 0) {
            CreateRefererID(msg.sender);
        }

        require(
            RefererID[msg.sender] != _refererID,
            "Subscribe: you cannot be a referral to yourself"
        );

        uint256 reward_amount = msg.value.perc(reward);

        uint256 Amount;

        if (msg.value == subs_amount_with_fee1) {
            Amount = subs_amount1;
        } else if (msg.value == subs_amount_with_fee2) {
            Amount = subs_amount2;
        } else if (msg.value == subs_amount_with_fee3) {
            Amount = subs_amount3;
        } else {
            require(
                true,
                "Subscribe: something went wrong, should not get here"
            );
        }

        require(
            Subscriptions[msg.sender][Amount] == 0,
            "Subscribe: subscription already paid"
        );

        // If a referrer is not yet installed
        if ((Referer[msg.sender] == 0) && (_refererID != 0)) {
            Referer[msg.sender] = _refererID;
        }

        // Add to Total
        if (Referer[msg.sender] != 0) {
            RefTotalIncome[RefererAddr[Referer[msg.sender]]] += msg.value;
        }

        uint256 Period = GetPeriod(now);

        if (
            (Referer[msg.sender] != 0) &&
            (!RefSubscStatus[msg.sender][Amount][Period])
        ) {
            // numbers of subscriptions per period (RefSubscCount[referer address][payXamount][Period])
            RefSubscCount[RefererAddr[Referer[msg
                .sender]]][Amount][Period] += 1;
            // only one subscription per period (RefSubscStatus[owner address][payXamount][Period])
            RefSubscStatus[msg.sender][Amount][Period] = true;
        }

        Subscriptions[msg.sender][Amount] = now;

        reward_account.transfer(reward_amount);

        if (!Participants[msg.sender]) {
            Participants[msg.sender] = true;
            NumberOfParticipants += 1;
        }

        FundBalance += reward_amount;
        NumberOfSubscriptions += 1;
        emit AmountInvestedBySubscription(msg.sender, Amount);
    }

    /**
    *  Withdraw "subscribe" amount
    */
    function WithdrawSubscribe(uint256 _amount)
        external
        onlyFixedAmountWithdrawSubs(_amount)
    {
        require(
            Subscriptions[msg.sender][_amount] > 0,
            "WithdrawSubscribe: subscription has not yet been paid"
        );

        uint256 Start;
        uint256 Finish;
        uint256 Current = GetPeriod(now);

        Start = GetPeriod(Subscriptions[msg.sender][_amount]);
        Finish = Start + 30;

        require(
            Current > Start,
            "WithdrawSubscribe: the withdrawal time has not yet arrived"
        );

        uint256 Amount = WithdrawAmountCalculate(msg.sender, _amount);

        msg.sender.transfer(Amount);

        ProfitPayoutAmount += Amount;
        emit AmountWithdrawnFromSubscription(msg.sender, Amount);
    }

    /**
    *  Withdraw all possible "subscribe" amount
    */
    function WithdrawSubscribeAll() internal {
        uint256 Amount = WithdrawAmountCalculate(msg.sender, subs_amount1);
        Amount += WithdrawAmountCalculate(msg.sender, subs_amount2);
        Amount += WithdrawAmountCalculate(msg.sender, subs_amount3);

        if (Amount > 0) {
            msg.sender.transfer(Amount);

            ProfitPayoutAmount += Amount;
            emit AmountWithdrawnFromSubscription(msg.sender, Amount);
        }
    }

    /**
    *  Withdraw amount calculation
    */
    function WithdrawAmountCalculate(address _sender, uint256 _amount)
        internal
        returns (uint256)
    {
        if (Subscriptions[_sender][_amount] == 0) {
            return 0;
        }

        uint256 Start;
        uint256 Finish;
        uint256 Current = GetPeriod(now);

        Start = GetPeriod(Subscriptions[_sender][_amount]);
        Finish = Start + 30;

        if (Current <= Start) {
            return 0;
        }

        if (Intermediate[_sender][_amount] == 0) {
            Intermediate[_sender][_amount] = now;
        } else {
            Start = GetPeriod(Intermediate[_sender][_amount]);
            Intermediate[_sender][_amount] = now;
        }

        uint256[30] memory Count;
        uint256 Amount = 0;
        uint256 Profit = 0;

        if (Current >= Finish) {
            Current = Finish;
            Subscriptions[_sender][_amount] = 0;
            Intermediate[_sender][_amount] = 0;
            Amount += _amount;
        }

        uint256 i = Start - 30;
        uint256 j = 0;
        uint256 k = 0;

        while (i < Current) {
            if (i <= Start) {
                j = 0;
            } else {
                j = i - Start;
            }

            while ((j <= k) && (Start + j < Current)) {
                Count[j] += RefSubscCount[_sender][_amount][i];
                j++;
            }
            i++;
            k++;
        }

        for (i = 0; i < (Current - Start); i++) {
            if (Count[i] > 15) {
                Count[i] = 15;
            }
            Profit += _amount.perc(200 + Count[i].mul(15));
        }

        OwnerTotalProfit[msg.sender] += Profit;
        Amount = Amount.add(Profit);
        return Amount;
    }

    /**
    //  Sets click referals in staging mode
    */
    function SetRefClickCount(address _address, uint256 _sum, uint256 _count)
        external
        onlyInStagingMode
    {
        RefClickCount[_address][_sum] = _count;
    }

    /**
    //  Sets autoclick owner operations for all amounts in current period in staging mode
    */
    function SetOwnerAutoClickCountAll(
        uint256 _count1,
        uint256 _count2,
        uint256 _count3,
        uint256 _count4,
        uint256 _count5,
        uint256 _count6
    ) external onlyInStagingMode {
        OwnerAutoClickCount[msg.sender][amount1][GetPeriod(now)] = _count1;
        OwnerAutoClickCount[msg.sender][amount2][GetPeriod(now)] = _count2;
        OwnerAutoClickCount[msg.sender][amount3][GetPeriod(now)] = _count3;
        OwnerAutoClickCount[msg.sender][amount4][GetPeriod(now)] = _count4;
        OwnerAutoClickCount[msg.sender][amount5][GetPeriod(now)] = _count5;
        OwnerAutoClickCount[msg.sender][amount6][GetPeriod(now)] = _count6;
    }

    /**
    //  Sets autoclick referals in staging mode
    */
    function SetRefAutoClickCount(
        address _address,
        uint256 _sum,
        uint256 _period,
        uint256 _count
    ) external onlyInStagingMode {
        RefAutoClickCount[_address][_sum][_period] = _count;
    }

    /**
    //  Sets autoclick referals for all amounts in current period in staging mode
    */
    function SetRefAutoClickCountAll(
        uint256 _count1,
        uint256 _count2,
        uint256 _count3,
        uint256 _count4,
        uint256 _count5,
        uint256 _count6
    ) external onlyInStagingMode {
        RefAutoClickCount[msg.sender][amount1][GetPeriod(now)] = _count1;
        RefAutoClickCount[msg.sender][amount2][GetPeriod(now)] = _count2;
        RefAutoClickCount[msg.sender][amount3][GetPeriod(now)] = _count3;
        RefAutoClickCount[msg.sender][amount4][GetPeriod(now)] = _count4;
        RefAutoClickCount[msg.sender][amount5][GetPeriod(now)] = _count5;
        RefAutoClickCount[msg.sender][amount6][GetPeriod(now)] = _count6;
    }

    /**
    //  Sets subscription referals in staging mode
    */
    function SetRefSubscCount(
        address _address,
        uint256 _sum,
        uint256 _period,
        uint256 _count
    ) external onlyInStagingMode {
        RefSubscCount[_address][_sum][_period] = _count;
    }

    /**
    //  Sets variables in staging mode
    */
    function SetValues(
        uint256 _NumberOfParticipants,
        uint256 _NumberOfClicks,
        uint256 _NumberOfSubscriptions,
        uint256 _ProfitPayoutAmount,
        uint256 _FundBalance
    ) external onlyInStagingMode {
        NumberOfParticipants = _NumberOfParticipants;
        NumberOfClicks = _NumberOfClicks;
        NumberOfSubscriptions = _NumberOfSubscriptions;
        ProfitPayoutAmount = _ProfitPayoutAmount;
        FundBalance = _FundBalance;
    }

    /**
    /  Return current period
    */
    function GetCurrentPeriod() external view returns (uint256 _period) {
        return GetPeriod(now);
    }

    /**
    /  Return fixed period
    */
    function GetFixedPeriod(uint256 _timestamp)
        external
        view
        returns (uint256 _period)
    {
        return GetPeriod(_timestamp);
    }

    /**
    *  Returns number of active referals
    */
    function GetAutoClickRefsNumber()
        external
        view
        returns (uint256 number_of_referrals)
    {
        uint256 Current = GetPeriod(now);
        uint256 Start = Current - 30;

        uint256 Count1 = 0;
        uint256 Count2 = 0;
        uint256 Count3 = 0;
        uint256 Count4 = 0;
        uint256 Count5 = 0;
        uint256 Count6 = 0;

        for (uint256 k = Start; k < Current; k++) {
            Count1 += RefAutoClickCount[msg.sender][amount1][k];
            Count2 += RefAutoClickCount[msg.sender][amount2][k];
            Count3 += RefAutoClickCount[msg.sender][amount3][k];
            Count4 += RefAutoClickCount[msg.sender][amount4][k];
            Count5 += RefAutoClickCount[msg.sender][amount5][k];
            Count6 += RefAutoClickCount[msg.sender][amount6][k];
        }

        if (Count1 > 63) {
            Count1 = 63;
        }
        if (Count2 > 63) {
            Count2 = 63;
        }
        if (Count3 > 63) {
            Count3 = 63;
        }
        if (Count4 > 63) {
            Count4 = 63;
        }
        if (Count5 > 63) {
            Count5 = 63;
        }
        if (Count6 > 63) {
            Count6 = 63;
        }

        return Count1 + Count2 + Count3 + Count4 + Count5 + Count6;
    }

    /**
    *  Returns number of active subscribe referals
    */
    function GetSubscribeRefsNumber(uint256 _amount)
        external
        view
        onlyFixedAmount(_amount)
        returns (uint256 number_of_referrals)
    {
        uint256 Current = GetPeriod(now);
        uint256 Start = Current - 30;

        uint256 Count = 0;
        for (uint256 k = Start; k < Current; k++) {
            Count += RefSubscCount[msg.sender][_amount][k];
        }

        if (Count > 15) {
            Count = 15;
        }

        return Count;
    }

    /**
    *  Returns subscription investment income based on the number of active referrals
    */
    function GetSubscribeIncome(uint256 _amount)
        external
        view
        onlyFixedAmount(_amount)
        returns (uint256 income)
    {
        uint256 Start = GetPeriod(now);
        uint256 Finish = Start + 30;

        uint256[30] memory Count;
        uint256 Amount = 0;

        uint256 i = Start - 30;
        uint256 j = 0;
        uint256 k = 0;

        while (i < Finish) {
            if (i <= Start) {
                j = 0;
            } else {
                j = i - Start;
            }

            while ((j <= k) && (Start + j < Finish)) {
                Count[j] += RefSubscCount[msg.sender][_amount][i];
                j++;
            }
            i++;
            k++;
        }

        for (i = 0; i < (Finish - Start); i++) {
            if (Count[i] > 15) {
                Count[i] = 15;
            }
            Amount += _amount.perc(200 + Count[i].mul(15));
        }

        return Amount;
    }

    /**
    *  Returns the end time of a subscription
    */
    function GetSubscribeFinish(uint256 _amount)
        external
        view
        onlyFixedAmount(_amount)
        returns (uint256 finish)
    {
        if (Subscriptions[msg.sender][_amount] == 0) {
            return 0;
        }

        uint256 Start = GetPeriod(Subscriptions[msg.sender][_amount]);
        uint256 Finish = Start + 30;

        return Finish.mul(days1).add(start_point);
    }

    /**
    *  Returns the near future possible withdraw
    */
    function GetSubscribeNearPossiblePeriod(uint256 _amount)
        external
        view
        onlyFixedAmount(_amount)
        returns (uint256 timestamp)
    {
        if (Subscriptions[msg.sender][_amount] == 0) {
            return 0;
        }

        uint256 Current = GetPeriod(now);
        uint256 Start = GetPeriod(Subscriptions[msg.sender][_amount]);

        if (Intermediate[msg.sender][_amount] != 0) {
            Start = GetPeriod(Intermediate[msg.sender][_amount]);
        }

        if (Current > Start) {
            return now;
        } else {
            return Start.add(1).mul(days1).add(start_point);
        }
    }

    /**
    *  Create referer id (uint256)
    */
    function CreateRefererID(address _referer) internal {
        require(
            RefererID[_referer] == 0,
            "CreateRefererID: referal id already assigned"
        );

        bytes32 hash = keccak256(abi.encodePacked(now, _referer));

        RefererID[_referer] = LastRefererID.add((uint256(hash) % 13) + 1);
        LastRefererID = RefererID[_referer];
        RefererAddr[LastRefererID] = _referer;
    }
}
"},"CashBackMoneyI.sol":{"content":"pragma solidity ^0.5.10;

/**
 * @title CashBackMoney Investing Contract Interface
 */
interface CashBackMoneyI {
    /**
    * Buy subscription
    * 0x0000000000000000000000000000000000000000
    */
    function Subscribe(uint256 refererID) external payable;
}
"},"ERC20.sol":{"content":"pragma solidity ^0.5.10;

import "./ERC20I.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the `ERC20I` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 */
contract ERC20 is ERC20I {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `ERC20I.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `ERC20I.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `ERC20I.transfer`.
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
     * @dev See `ERC20I.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `ERC20I.approve`.
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
     * @dev See `ERC20I.transferFrom`.
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
     * problems described in `ERC20I.approve`.
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
     * problems described in `ERC20I.approve`.
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
}"},"ERC20I.sol":{"content":"pragma solidity ^0.5.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include the optional functions;
 */
interface ERC20I {
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
}"},"Ownable.sol":{"content":"pragma solidity ^0.5.10;

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
}"},"SafeMath.sol":{"content":"pragma solidity ^0.5.10;

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
    * @dev Returns the integer percentage of the number.
    */
    function perc(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        c = c / 10000; // percent to hundredths

        return c;
    }

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
"}}