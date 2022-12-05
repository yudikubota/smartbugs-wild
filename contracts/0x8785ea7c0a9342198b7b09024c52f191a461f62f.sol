{{
  "language": "Solidity",
  "sources": {
    "/Users/kstasi/Documents/side/dANT/contracts/ReferralRewards.sol": {
      "content": "pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReferralTree.sol";
import "./dANT.sol";

contract ReferralRewards is Ownable {
    using SafeMath for uint256;

    event ReferralDepositReward(
        address indexed refferer,
        address indexed refferal,
        uint256 indexed level,
        uint256 amount
    );
    event ReferralRewardPaid(address indexed user, uint256 amount);

    // Info of each deposit made by the referrer
    struct DepositInfo {
        address referrer; // Address of refferer who made this deposit
        uint256 depth; // The level of the refferal
        uint256 amount; // Amount of deposited LP tokens
        uint256 time; // Wnen the deposit is ended
        uint256 lastUpdatedTime; // Last time the referral claimed reward from the deposit
    }
    // Info of each referral
    struct ReferralInfo {
        uint256 reward; // Ammount of collected deposit rewards
        uint256 lastUpdate; // Last time the referral claimed rewards
        uint256 depositHead; // The start index in the deposit's list
        uint256 depositTail; // The end index in the deposit's list
        uint256[amtLevels] amounts; // Amounts that generate rewards on each referral level
        mapping(uint256 => DepositInfo) deposits; // Deposits that generate reward for the referral
    }

    uint256 public constant amtLevels = 3; // Number of levels by total staked amount that determine referral reward's rate
    uint256 public constant referDepth = 3; // Number of referral levels that can receive dividends

    dANT public token; // Harvested token contract
    ReferralTree public referralTree; // Contract with referral's tree
    Rewards rewards; // Main farming contract

    uint256[amtLevels] public depositBounds; // Limits of referral's stake used to determine the referral rate
    uint256[referDepth][amtLevels] public depositRate; // Referral rates based on referral's deplth and stake received from deposit
    uint256[referDepth][amtLevels] public stakingRate; // Referral rates based on referral's deplth and stake received from staking

    mapping(address => ReferralInfo) public referralReward; // Info per each referral

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _referralTree Contract with referral's tree.
    /// @param _rewards Main farming contract.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    constructor(
        dANT _token,
        ReferralTree _referralTree,
        Rewards _rewards,
        uint256[amtLevels] memory _depositBounds,
        uint256[referDepth][amtLevels] memory _depositRate,
        uint256[referDepth][amtLevels] memory _stakingRate
    ) public Ownable() {
        token = _token;
        referralTree = _referralTree;
        depositBounds = _depositBounds;
        depositRate = _depositRate;
        stakingRate = _stakingRate;
        rewards = _rewards;
    }

    /// @dev Allows an owner to update bounds.
    /// @param _depositBounds Limits of referral's stake used to determine the referral rate.
    function setBounds(uint256[amtLevels] memory _depositBounds)
        public
        onlyOwner
    {
        depositBounds = _depositBounds;
    }

    /// @dev Allows an owner to update deposit rates.
    /// @param _depositRate Referral rates based on referral's deplth and stake received from deposit.
    function setDepositRate(uint256[referDepth][amtLevels] memory _depositRate)
        public
        onlyOwner
    {
        depositRate = _depositRate;
    }

    /// @dev Allows an owner to update staking rates.
    /// @param _stakingRate Referral rates based on referral's deplth and stake received from staking.
    function setStakingRate(uint256[referDepth][amtLevels] memory _stakingRate)
        public
        onlyOwner
    {
        stakingRate = _stakingRate;
    }

    /// @dev Allows a farming contract to set user referral.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the refferal.
    function setReferral(address _referrer, address _referral) public {
        require(
            msg.sender == address(rewards),
            "assessReferalDepositReward: bad role"
        );
        referralTree.setReferral(_referrer, _referral);
    }

    /// @dev Allows the main farming contract to assess referral deposit rewards.
    /// @param _referrer Address of the referred user.
    /// @param _amount Amount of new deposit.
    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external
        virtual
    {
        require(
            msg.sender == address(rewards),
            "assessReferalDepositReward: bad role"
        );
        address[] memory referrals = referralTree.getReferrals(
            _referrer,
            referDepth
        );
        uint256[] memory referralStakes = rewards.getReferralStakes(referrals);
        uint256[] memory percents = getDepositRate(referralStakes);
        for (uint256 level = 0; level < referrals.length; level++) {
            if (referrals[level] == address(0)) {
                continue;
            }


                ReferralInfo storage referralInfo
             = referralReward[referrals[level]];
            referralInfo.deposits[referralInfo.depositTail] = DepositInfo({
                referrer: _referrer,
                depth: level,
                amount: _amount,
                lastUpdatedTime: now,
                time: now + rewards.duration()
            });
            referralInfo.amounts[level] = referralInfo.amounts[level].add(
                _amount
            );
            referralInfo.depositTail = referralInfo.depositTail.add(1);
            if (percents[level] == 0) {
                continue;
            }
            uint256 depositReward = _amount.mul(percents[level]);
            if (depositReward > 0) {
                referralInfo.reward = referralInfo.reward.add(depositReward);
                emit ReferralDepositReward(
                    _referrer,
                    referrals[level],
                    level,
                    depositReward
                );
            }
        }
    }

    /// @dev Allows a user to claim his dividends.
    function claimDividends() public {
        claimUserDividends(msg.sender);
    }

    /// @dev Allows a referral tree to claim all the dividends.
    /// @param _referral Address of user that claims his dividends.
    function claimAllDividends(address _referral) public {
        require(
            msg.sender == address(referralTree) ||
                msg.sender == address(rewards),
            "claimAllDividends: bad role"
        );
        claimUserDividends(_referral);
    }

    /// @dev Allows to decrement staked amount that generates reward to the referrals.
    /// @param _referrer Address of the referrer.
    /// @param _amount Ammount of tokens to be withdrawn by referrer.
    function removeDepositReward(address _referrer, uint256 _amount)
        external
        virtual
    {}

    /// @dev Update the staking referral reward for _user.
    /// @param _user Address of the referral.
    function accumulateReward(address _user) internal virtual {
        ReferralInfo storage referralInfo = referralReward[_user];
        if (referralInfo.lastUpdate >= now) {
            return;
        }
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        for (
            uint256 i = referralInfo.depositHead;
            i < referralInfo.depositTail;
            i++
        ) {
            DepositInfo memory deposit = referralInfo.deposits[i];
            uint256 reward = Math
                .min(now, deposit.time)
                .sub(deposit.lastUpdatedTime)
                .mul(deposit.amount)
                .mul(rewardPerSec)
                .mul(rates[deposit.depth])
                .div(1e18);
            if (reward > 0) {
                referralInfo.reward = referralInfo.reward.add(reward);
            }
            referralInfo.deposits[i].lastUpdatedTime = now;
            if (deposit.time < now) {
                if (i != referralInfo.depositHead) {
                    referralInfo.deposits[i] = referralInfo
                        .deposits[referralInfo.depositHead];
                }
                delete referralInfo.deposits[referralInfo.depositHead];
                referralInfo.depositHead = referralInfo.depositHead.add(1);
            }
        }
        referralInfo.lastUpdate = now;
    }

    /// @dev Asses and distribute claimed dividends.
    /// @param _user Address of user that claims dividends.
    function claimUserDividends(address _user) internal {
        accumulateReward(_user);
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 amount = referralInfo.reward.div(1e18);
        if (amount > 0) {
            uint256 scaledReward = amount.mul(1e18);
            referralInfo.reward = referralInfo.reward.sub(scaledReward);
            token.mint(_user, amount);
            emit ReferralRewardPaid(_user, amount);
        }
    }

    /// @dev Returns referral reward.
    /// @param _user Address of referral.
    /// @return Referral reward.
    function getReferralReward(address _user)
        external
        virtual
        view
        returns (uint256)
    {
        ReferralInfo storage referralInfo = referralReward[_user];
        uint256 rewardPerSec = rewards.rewardPerSec();
        uint256 referralStake = rewards.getReferralStake(_user);
        uint256[referDepth] memory rates = getStakingRateRange(referralStake);
        uint256 _reward = referralInfo.reward;
        for (
            uint256 i = referralInfo.depositHead;
            i < referralInfo.depositTail;
            i++
        ) {
            DepositInfo memory deposit = referralInfo.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(deposit.lastUpdatedTime)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .mul(rates[deposit.depth])
                    .div(1e18)
            );
        }
        return _reward.div(1e18);
    }

    /// @dev Returns direct user referral.
    /// @param _user Address of referrer.
    /// @return Direct user referral.
    function getReferral(address _user) public view returns (address) {
        return referralTree.referrals(_user);
    }

    /// @dev Returns stakong rate for the spesific referral stake.
    /// @param _referralStake Amount staked by referral.
    /// @return _rates Array of stakong rates by referral level.
    function getStakingRateRange(uint256 _referralStake)
        public
        view
        returns (uint256[referDepth] memory _rates)
    {
        for (uint256 i = 0; i < depositBounds.length; i++) {
            if (_referralStake >= depositBounds[i]) {
                return stakingRate[i];
            }
        }
    }

    /// @dev Returns deposit rate based on the spesific referral stake and referral level.
    /// @param _referralStakes Amounts staked by referrals.
    /// @return _rates Array of deposit rates by referral level.
    function getDepositRate(uint256[] memory _referralStakes)
        public
        view
        returns (uint256[] memory _rates)
    {
        _rates = new uint256[](_referralStakes.length);
        for (uint256 level = 0; level < _referralStakes.length; level++) {
            for (uint256 j = 0; j < depositBounds.length; j++) {
                if (_referralStakes[level] >= depositBounds[j]) {
                    _rates[level] = depositRate[j][level];
                    break;
                }
            }
        }
    }

    /// @dev Returns limits of referral's stake used to determine the referral rate.
    /// @return Array of deposit bounds.
    function getDepositBounds()
        public
        view
        returns (uint256[referDepth] memory)
    {
        return depositBounds;
    }

    /// @dev Returns referral rates based on referral's deplth and stake received from staking.
    /// @return Array of staking rates.
    function getStakingRates()
        public
        view
        returns (uint256[referDepth][amtLevels] memory)
    {
        return stakingRate;
    }

    /// @dev Returns referral rates based on referral's deplth and stake received from deposit.
    /// @return Array of deposit rates.
    function getDepositRates()
        public
        view
        returns (uint256[referDepth][amtLevels] memory)
    {
        return depositRate;
    }

    /// @dev Returns amounts that generate reward for referral bu levels.
    /// @param _user Address of referral.
    /// @return Returns amounts that generate reward for referral bu levels.
    function getReferralAmounts(address _user)
        public
        view
        returns (uint256[amtLevels] memory)
    {
        ReferralInfo memory referralInfo = referralReward[_user];
        return referralInfo.amounts;
    }
}
"
    },
    "/Users/kstasi/Documents/side/dANT/contracts/ReferralTree.sol": {
      "content": "pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ReferralRewards.sol";
import "./Rewards.sol";

contract ReferralTree is AccessControl {
    using SafeMath for uint256;

    event ReferralAdded(address indexed referrer, address indexed referral);

    bytes32 public constant REWARDS_ROLE = keccak256("REWARDS_ROLE"); // Role for those who allowed to mint new tokens

    mapping(address => address) public referrals; // Referral addresses for each referrer
    mapping(address => bool) public registered; // Map to ensure if the referrer is in the tree
    mapping(address => address[]) public referrers; // List of referrer addresses for each referral
    ReferralRewards[] public referralRewards; // Referral reward contracts that are allowed to modify the tree
    address public treeRoot; // The root of the referral tree

    /// @dev Constructor that initializes the most important configurations.
    /// @param _treeRoot The root of the referral tree.
    constructor(address _treeRoot) public AccessControl() {
        treeRoot = _treeRoot;
        registered[_treeRoot] = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Allows an admin to reanonce the DEFAULT_ADMIN_ROLE.
    /// @param _newAdmin Address of the new admin.
    function changeAdmin(address _newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "changeAdmin: bad role"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Allows a farming contract to set the users referral.
    /// @param _referrer Address of the referred user.
    /// @param _referral Address of the refferal.
    function setReferral(address _referrer, address _referral) public {
        require(hasRole(REWARDS_ROLE, _msgSender()), "setReferral: bad role");
        require(_referrer != address(0), "setReferral: bad referrer");
        if (!registered[_referrer]) {
            require(
                registered[_referral],
                "setReferral: not registered referral"
            );
            referrals[_referrer] = _referral;
            registered[_referrer] = true;
            referrers[_referral].push(_referrer);
            emit ReferralAdded(_referrer, _referral);
        }
    }

    /// @dev Allows an admin to remove the referral rewards contract from trusted list.
    /// @param _referralRewards Contract that manages referral rewards.
    function removeReferralReward(ReferralRewards _referralRewards) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "setReferral: bad role"
        );
        for (uint256 i = 0; i < referralRewards.length; i++) {
            if (_referralRewards == referralRewards[i]) {
                uint256 lastIndex = referralRewards.length - 1;
                if (i != lastIndex) {
                    referralRewards[i] = referralRewards[lastIndex];
                }
                referralRewards.pop();
                revokeRole(REWARDS_ROLE, address(_referralRewards));
                break;
            }
        }
    }

    /// @dev Allows an admin to add the referral rewards contract from trusted list.
    /// @param _referralRewards Contract that manages referral rewards.
    function addReferralReward(ReferralRewards _referralRewards) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "setReferral: bad role"
        );
        _setupRole(REWARDS_ROLE, address(_referralRewards));
        referralRewards.push(_referralRewards);
    }

    /// @dev Allows a user to claim all the dividends in all trusted products.
    function claimAllDividends() public {
        for (uint256 i = 0; i < referralRewards.length; i++) {
            ReferralRewards referralReward = referralRewards[i];
            if (referralReward.getReferralReward(_msgSender()) > 0) {
                referralReward.claimAllDividends(_msgSender());
            }
        }
    }

    /// @dev Returns user referrals up to the required depth.
    /// @param _referrer Address of referrer.
    /// @param _referDepth Number of referrals to be returned.
    /// @return List of user referrals.
    function getReferrals(address _referrer, uint256 _referDepth)
        public
        view
        returns (address[] memory)
    {
        address[] memory referralsTree = new address[](_referDepth);
        address referrer = _referrer;
        for (uint256 i = 0; i < _referDepth; i++) {
            referralsTree[i] = referrals[referrer];
            referrer = referralsTree[i];
        }
        return referralsTree;
    }

    /// @dev Returns user referrals up to the required depth.
    /// @param _referral Address of referral.
    /// @return List of user referrers.
    function getReferrers(address _referral)
        public
        view
        returns (address[] memory)
    {
        return referrers[_referral];
    }

    /// @dev Returns total user's referral reward.
    /// @param _user Address of the user.
    /// @return Total user's referral reward.
    function getUserReferralReward(address _user)
        public
        view
        returns (uint256)
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < referralRewards.length; i++) {
            ReferralRewards referralReward = referralRewards[i];
            amount = amount.add(referralReward.getReferralReward(_user));
        }
        return amount;
    }

    /// @dev Returns trusted referral reward contracts.
    /// @return List of trusted referral reward contracts.
    function getReferralRewards()
        public
        view
        returns (ReferralRewards[] memory)
    {
        return referralRewards;
    }
}
"
    },
    "/Users/kstasi/Documents/side/dANT/contracts/Rewards.sol": {
      "content": "pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReferralTree.sol";
import "./dANT.sol";
import "./ReferralRewards.sol";

abstract contract Rewards is Ownable {
    using SafeMath for uint256;

    event Deposit(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 start,
        uint256 end
    );
    event Withdraw(
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 time
    );
    event RewardPaid(address indexed user, uint256 amount);

    // Info of each deposit made by the user
    struct DepositInfo {
        uint256 amount; // Amount of deposited LP tokens
        uint256 time; // Wnen the deposit is ended
    }

    // Info of each user
    struct UserInfo {
        uint256 amount; // Total deposited amount
        uint256 unfrozen; // Amount of token to be unstaked
        uint256 reward; // Ammount of claimed rewards
        uint256 lastUpdate; // Last time the user claimed rewards
        uint256 depositHead; // The start index in the deposit's list
        uint256 depositTail; // The end index in the deposit's list
        mapping(uint256 => DepositInfo) deposits; // User's dposits
    }

    dANT public token; // Harvested token contract
    ReferralRewards public referralRewards; // Contract that manages referral rewards

    uint256 public duration; // How long the deposit works
    uint256 public rewardPerSec; // Reward rate generated each second
    uint256 public totalStake; // Amount of all staked LP tokens
    uint256 public totalClaimed; // Amount of all distributed rewards
    uint256 public lastUpdate; // Last time someone received rewards

    bool public isActive = true; // If the deposits are allowed

    mapping(address => UserInfo) public userInfo; // Info per each user

    /// @dev Constructor that initializes the most important configurations.
    /// @param _token Token to be staked and harvested.
    /// @param _duration How long the deposit works.
    /// @param _rewardPerSec Reward rate generated each second.
    constructor(
        dANT _token,
        uint256 _duration,
        uint256 _rewardPerSec
    ) public Ownable() {
        token = _token;
        duration = _duration;
        rewardPerSec = _rewardPerSec;
    }

    /// @dev Allows an owner to stop or countinue deposits.
    /// @param _isActive Whether the deposits are allowed.
    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    /// @dev Allows an owner to update referral rewards module.
    /// @param _referralRewards Contract that manages referral rewards.
    function setReferralRewards(ReferralRewards _referralRewards)
        public
        onlyOwner
    {
        referralRewards = _referralRewards;
    }

    /// @dev Allows an owner to update duration of the deposits.
    /// @param _duration How long the deposit works.
    function setDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    /// @dev Allows an owner to update reward rate per sec.
    /// @param _rewardPerSec Reward rate generated each second.
    function setRewardPerSec(uint256 _rewardPerSec) public onlyOwner {
        rewardPerSec = _rewardPerSec;
    }

    /// @dev Allows to stake for the specific user.
    /// @param _user Deposit receiver.
    /// @param _amount Amount of deposit.
    function stakeFor(address _user, uint256 _amount) public {
        require(
            referralRewards.getReferral(_user) != address(0),
            "stakeFor: referral isn't set"
        );
        proccessStake(_user, _amount, address(0));
    }

    /// @dev Allows to stake for themselves.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    function stake(uint256 _amount, address _refferal) public {
        proccessStake(msg.sender, _amount, _refferal);
    }

    /// @dev Proccess the stake.
    /// @param _receiver Deposit receiver.
    /// @param _amount Amount of deposit.
    /// @param _refferal Referral address that will be set in case of the first stake.
    function proccessStake(
        address _receiver,
        uint256 _amount,
        address _refferal
    ) internal {
        require(isActive, "stake: is paused");
        referralRewards.setReferral(_receiver, _refferal);
        referralRewards.claimAllDividends(_receiver);
        updateStakingReward(_receiver);
        if (_amount > 0) {
            token.transferFrom(msg.sender, address(this), _amount);
            UserInfo storage user = userInfo[_receiver];
            user.amount = user.amount.add(_amount);
            totalStake = totalStake.add(_amount);
            user.deposits[user.depositTail] = DepositInfo({
                amount: _amount,
                time: now + duration
            });
            emit Deposit(
                _receiver,
                user.depositTail,
                _amount,
                now,
                now + duration
            );
            user.depositTail = user.depositTail.add(1);
            referralRewards.assessReferalDepositReward(_receiver, _amount);
        }
    }

    /// @dev Accumulate new reward and remove old deposits.
    /// @param _user Address of the user.
    /// @return _reward Earned reward.
    function accumulateStakingReward(address _user)
        internal
        virtual
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
            );
            if (deposit.time < now) {
                referralRewards.claimAllDividends(_user);
                user.amount = user.amount.sub(deposit.amount);
                handleDepositEnd(_user, deposit.amount);
                delete user.deposits[i];
                user.depositHead = user.depositHead.add(1);
            }
        }
    }

    /// @dev Assess new reward.
    /// @param _user Address of the user.
    function updateStakingReward(address _user) internal virtual {
        UserInfo storage user = userInfo[_user];
        if (user.lastUpdate >= now) {
            return;
        }
        uint256 scaledReward = accumulateStakingReward(_user);
        uint256 reward = scaledReward.div(1e18);
        lastUpdate = now;
        user.reward = user.reward.add(reward);
        user.lastUpdate = now;
        if (reward > 0) {
            totalClaimed = totalClaimed.add(reward);
            token.mint(_user, reward);
            emit RewardPaid(_user, reward);
        }
    }

    /// @dev Procces deposit and by returning deposit.
    /// @param _user Address of the user.
    /// @param _amount Amount of the deposit.
    function handleDepositEnd(address _user, uint256 _amount) internal virtual {
        totalStake = totalStake.sub(_amount);
        safeTokenTransfer(_user, _amount);
        emit Withdraw(_user, 0, _amount, now);
    }

    /// @dev Safe token transfer.
    /// @param _to Address of the receiver.
    /// @param _amount Amount of the tokens to be sent.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    /// @dev Returns user's unclaimed reward.
    /// @param _user Address of the user.
    /// @param _includeDeposit Should the finnished deposits be included into calculations.
    /// @return _reward User's reward.
    function getPendingReward(address _user, bool _includeDeposit)
        public
        virtual
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .div(1e18)
            );
            if (_includeDeposit && deposit.time < now) {
                _reward = _reward.add(deposit.amount);
            }
        }
    }

    /// @dev Returns claimed and unclaimed user's reward.
    /// @param _user Address of the user.
    /// @return _reward User's reward.
    function getReward(address _user)
        public
        virtual
        view
        returns (uint256 _reward)
    {
        UserInfo storage user = userInfo[_user];
        _reward = user.reward;
        for (uint256 i = user.depositHead; i < user.depositTail; i++) {
            DepositInfo memory deposit = user.deposits[i];
            _reward = _reward.add(
                Math
                    .min(now, deposit.time)
                    .sub(user.lastUpdate)
                    .mul(deposit.amount)
                    .mul(rewardPerSec)
                    .div(1e18)
            );
        }
    }

    /// @dev Returns referral stakes.
    /// @param _referrals List of referrals[].
    /// @return _stakes List of referral stakes.
    function getReferralStakes(address[] memory _referrals)
        public
        view
        returns (uint256[] memory _stakes)
    {
        _stakes = new uint256[](_referrals.length);
        for (uint256 i = 0; i < _referrals.length; i++) {
            _stakes[i] = userInfo[_referrals[i]].amount;
        }
    }

    /// @dev Returns referral stake.
    /// @param _referral Address of referral.
    /// @return Deposited amount.
    function getReferralStake(address _referral) public view returns (uint256) {
        return userInfo[_referral].amount;
    }

    /// @dev Returns approximate reward assessed in the future.
    /// @param _delta Time to estimate.
    /// @return Predicted rewards.
    function getEstimated(uint256 _delta) public view returns (uint256) {
        return
            (now + _delta)
                .sub(lastUpdate)
                .mul(totalStake)
                .mul(rewardPerSec)
                .div(1e18);
    }

    /// @dev Returns user's deposit by id.
    /// @param _user Address of user.
    /// @param _id Deposit id.
    /// @return Deposited amount and deposit end time.
    function getDeposit(address _user, uint256 _id)
        public
        view
        returns (uint256, uint256)
    {
        DepositInfo memory deposit = userInfo[_user].deposits[_id];
        return (deposit.amount, deposit.time);
    }
}
"
    },
    "/Users/kstasi/Documents/side/dANT/contracts/dANT.sol": {
      "content": "pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract dANT is ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(uint256 initialSupply)
        public
        ERC20("Digital Antares Dollar", "dANT")
        AccessControl()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), initialSupply * 10**18);
    }

    /**
     * @dev Set the DEFAULT_ADMIN_ROLE to `_newAdmin`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function changeAdmin(address _newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "changeAdmin: bad role"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Creates `_amount` new tokens for `_to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address _to, uint256 _amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "mint: bad role");
        _mint(_to, _amount);
    }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/access/AccessControl.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"
    },
    "@openzeppelin/contracts/math/Math.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
"
    },
    "@openzeppelin/contracts/utils/EnumerableSet.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {
      "": {}
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