{"Address.sol":{"content":"pragma solidity ^0.5.0;

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
}
"},"Context.sol":{"content":"pragma solidity ^0.5.0;

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
contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }
	// solhint-disable-previous-line no-empty-blocks

    /**
     * @dev return msg.sender
     * @return msg.sender
     */
	function _msgSender()
        internal
        view
        returns (address payable)
    {
		return msg.sender;
	}

    /**
     * @dev return msg.value
     * @return msg.value
     */
	function _msgValue()
        internal
        view
        returns (uint)
    {
		return msg.value;
	}

    /**
     * @dev return msg.data
     * @return msg.data
     */
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

        /**
     * @dev return tx.origin
     * @return tx.origin
     */
	function _txOrigin()
        internal
        view
        returns (address)
    {
		return tx.origin;
	}
}"},"Contract_Code.sol":{"content":"pragma solidity ^0.5.0;

import './SafeMath.sol';
import './String.sol';
import './Address.sol';
import './Context.sol';
import './HumanChsek.sol';
import './Whitelist.sol';
import './DBUtilli.sol';


/**
 * @title Utillibrary
 * @dev This integrates the basic functions.
 */
contract Utillibrary is Whitelist {
    //lib using list
	using SafeMath for *;

    //Loglist
    event TransferEvent(address indexed _from, address indexed _to, uint _value, uint time);

    //base param setting
    // uint internal ethWei = 1 ether;
    uint internal ethWei = 10 finney;//Test 0.01ether

    /**
     * @dev Transfer to designated user
     * @param userAddress user address
     * @param money transfer-out amount
     */
	function sendMoneyToUser(address payable userAddress, uint money)
        internal
    {
		if (money > 0) {
			userAddress.transfer(money);
		}
	}

    /**
     * @dev Check and correct transfer amount
     * @param sendMoney transfer-out amount
     * @return bool,amount
     */
	function isEnoughBalance(uint sendMoney)
        internal
        view
        returns (bool, uint)
    {
		if (sendMoney >= address(this).balance) {
			return (false, address(this).balance);
		} else {
			return (true, sendMoney);
		}
	}

    /**
     * @dev get UserLevel for the investment amount
     * @param value investment amount
     * @return UserLevel
     */
	function getLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11) && value <= ethWei.mul(15)) {
			return 3;
		}
		return 0;
	}

    /**
     * @dev get NodeLevel for the investment amount
     * @param value investment amount
     * @return NodeLevel
     */
	function getNodeLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11)) {
			return 3;
		}
		return 0;
	}

    /**
     * @dev get scale for the level
     * @param level level
     * @return scale
     */
	function getScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 5;
		}
		if (level == 2) {
			return 7;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

    /**
     * @dev get recommend scal for the level and times
     * @param level level
     * @param times The layer number of recommended
     * @return recommend scale
     */
	function getRecommendScaleByLevelAndTim(uint level, uint times)
        public
        pure
        returns (uint)
    {
		if (level == 1 && times == 1) {
			return 50;
		}
		if (level == 2 && times == 1) {
			return 70;
		}
		if (level == 2 && times == 2) {
			return 50;
		}
		if (level == 3) {
			if (times == 1) {
				return 100;
			}
			if (times == 2) {
				return 70;
			}
			if (times == 3) {
				return 50;
			}
			if (times >= 4 && times <= 10) {
				return 10;
			}
			if (times >= 11 && times <= 20) {
				return 5;
			}
			if (times >= 21) {
				return 1;
			}
		}
		return 0;
	}

    /**
     * @dev get burn scal for the level
     * @param level level
     * @return burn scale
     */
	function getBurnScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 3;
		}
		if (level == 2) {
			return 6;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

    /**
     * @dev Transfer to designated addr
     * Authorization Required
     * @param _addr transfer-out address
     * @param _val transfer-out amount
     */
    function sendMoneyToAddr(address _addr, uint _val)
        public
        payable
        onlyOwner
    {
        require(_addr != address(0), "not the zero address");
        address(uint160(_addr)).transfer(_val);
        emit TransferEvent(address(this), _addr, _val, now);
    }
}


contract HYPlay is Context, HumanChsek, Whitelist, DBUtilli, Utillibrary {
    //lib using list
	using SafeMath for *;
    using String for string;
    using Address for address;

    //struct
	struct User {
		uint id;
		address userAddress;
        uint lineAmount;//bonus calculation mode line
        uint freezeAmount;//invest lock
		uint freeAmount;//invest out unlock
        uint dayBonusAmount;//Daily bonus amount (static bonus)
        uint bonusAmount;//add up static bonus amonut (static bonus)
		uint inviteAmonut;//add up invite bonus amonut (dynamic bonus)
		uint level;//user level
		uint nodeLevel;//user node Level
		uint investTimes;//settlement bonus number
		uint rewardIndex;//user current index of award
		uint lastRwTime;//last settlement time
	}
	struct AwardData {
        uint time;//settlement bonus time
        uint staticAmount;//static bonus of reward amount
		uint oneInvAmount;//One layer of reward amount
		uint twoInvAmount;//Two layer reward amount
		uint threeInvAmount;//Three layer or more bonus amount
	}

    //Loglist
    event InvestEvent(address indexed _addr, string _code, string _rCode, uint _value, uint time);
    event WithdrawEvent(address indexed _addr, uint _value, uint time);

    //base param setting
	address payable private devAddr = address(0);//The special account
	address payable private foundationAddr = address(0);//Foundation address

    //start Time setting
    uint startTime = 0;
	uint canSetStartTime = 1;
	uint period = 1 days;

    //Bonus calculation mode (0 invested,!=0 line)
    uint lineStatus = 0;

    //Round setting
	uint rid = 1;
	mapping(uint => uint) roundInvestCount;//RoundID InvestCount Mapping
	mapping(uint => uint) roundInvestMoney;//RoundID InvestMoney Mapping
	mapping(uint => uint[]) lineArrayMapping;//RoundID UID[] Mapping
    //RoundID [address User Mapping] Mapping
	mapping(uint => mapping(address => User)) userRoundMapping;
    //RoundID [address [rewardIndex AwardData Mapping] Mapping] Mapping
	mapping(uint => mapping(address => mapping(uint => AwardData))) userAwardDataMapping;

    //limit setting
	uint bonuslimit = ethWei.mul(15);
	uint sendLimit = ethWei.mul(100);
	uint withdrawLimit = ethWei.mul(15);

    /**
     * @dev the content of contract is Beginning
     */
	constructor (address _dbAddr, address _devAddr, address _foundationAddr) public {
        db = IDB(_dbAddr);
        devAddr = address(_devAddr).toPayable();
        foundationAddr = address(_foundationAddr).toPayable();
	}

    /**
     * @dev deposit
     */
	function() external payable {
	}

    /**
     * @dev Set invest mode
     * @param line invest mode
     */
	function actUpdateLine(uint line)
        external
        onlyIfWhitelisted
    {
		lineStatus = line;
	}

    /**
     * @dev Set start time
     * @param time start time
     */
	function actSetStartTime(uint time)
        external
        onlyIfWhitelisted
    {
		require(canSetStartTime == 1, "verydangerous, limited!");
		require(time > now, "no, verydangerous");
		startTime = time;
		canSetStartTime = 0;
	}

    /**
     * @dev Set End Round
     */
	function actEndRound()
        external
        onlyIfWhitelisted
    {
		require(address(this).balance < ethWei.mul(1), "contract balance must be lower than 1 ether");
		rid++;
		startTime = now.add(period).div(1 days).mul(1 days);
		canSetStartTime = 1;
	}

    /**
     * @dev Set all limit
     * @param _bonuslimit bonus limit
     * @param _sendLimit send limit
     * @param _withdrawLimit withdraw limit
     */
	function actAllLimit(uint _bonuslimit, uint _sendLimit, uint _withdrawLimit)
        external
        onlyIfWhitelisted
    {
		require(_bonuslimit >= ethWei.mul(15) && _sendLimit >= ethWei.mul(100) && _withdrawLimit >= ethWei.mul(15), "invalid amount");
		bonuslimit = _bonuslimit;
		sendLimit = _sendLimit;
		withdrawLimit = _withdrawLimit;
	}

    /**
     * @dev Set user status
     * @param addr user address
     * @param status user status
     */
	function actUserStatus(address addr, uint status)
        external
        onlyIfWhitelisted
    {
		require(status == 0 || status == 1 || status == 2, "bad parameter status");
        _setUser(addr, status);
	}

    /**
     * @dev Calculation of contract bonus
     * @param start start the entry
     * @param end end the entry
     * @param isUID parameter is UID
     */
	function calculationBonus(uint start, uint end, uint isUID)
        external
        isHuman()
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			uint userId = 0;
			if (isUID == 0) {
				userId = lineArrayMapping[rid][i];
			} else {
				userId = i;
			}
			address userAddr = _getIndexMapping(userId);
			User storage user = userRoundMapping[rid][userAddr];
			if (user.freezeAmount == 0 && user.lineAmount >= ethWei.mul(1) && user.lineAmount <= ethWei.mul(15)) {
				user.freezeAmount = user.lineAmount;
				user.level = getLevel(user.freezeAmount);
				user.lineAmount = 0;
				sendFeeToDevAddr(user.freezeAmount);
				countBonus_All(user.userAddress);
			}
		}
	}

    /**
     * @dev settlement bonus
     * @param start start the entry
     * @param end end the entry
     */
	function settlement(uint start, uint end)
        external
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			address userAddr = _getIndexMapping(i);
			User storage user = userRoundMapping[rid][userAddr];

            uint[2] memory user_data;
            (user_data, , ) = _getUserInfo(userAddr);
            uint user_status = user_data[1];

			if (now.sub(user.lastRwTime) <= 12 hours) {
				continue;
			}
			user.lastRwTime = now;

			if (user_status == 1) {
                user.rewardIndex = user.rewardIndex.add(1);
				continue;
			}

            //static bonus
			uint bonusStatic = 0;
			if (user.id != 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit) {
				if (user.investTimes < 5) {
					bonusStatic = bonusStatic.add(user.dayBonusAmount);
					user.bonusAmount = user.bonusAmount.add(bonusStatic);
					user.investTimes = user.investTimes.add(1);
				} else {
					user.freeAmount = user.freeAmount.add(user.freezeAmount);
					user.freezeAmount = 0;
					user.dayBonusAmount = 0;
					user.level = 0;
				}
			}

            //dynamic bonus
			uint inviteSend = 0;
            if (user_status == 0) {
                inviteSend = getBonusAmount_Dynamic(userAddr, rid, 0, false);
            }

            //sent bonus amonut
			if (bonusStatic.add(inviteSend) <= sendLimit) {
				user.inviteAmonut = user.inviteAmonut.add(inviteSend);
				bool isEnough = false;
				uint resultMoney = 0;
				(isEnough, resultMoney) = isEnoughBalance(bonusStatic.add(inviteSend));
				if (resultMoney > 0) {
					uint foundationMoney = resultMoney.div(10);
					sendMoneyToUser(foundationAddr, foundationMoney);
					resultMoney = resultMoney.sub(foundationMoney);
					address payable sendAddr = address(uint160(userAddr));
					sendMoneyToUser(sendAddr, resultMoney);
				}
			}

            AwardData storage awData = userAwardDataMapping[rid][userAddr][user.rewardIndex];
            //Record static bonus
            awData.staticAmount = bonusStatic;
            //Record settlement bonus time
            awData.time = now;

            //user reward Index since the increase
            user.rewardIndex = user.rewardIndex.add(1);
		}
	}

    /**
     * @dev the invest withdraw of contract is Beginning
     */
    function withdraw()
        public
        isHuman()
    {
		require(isOpen(), "Contract no open");
		User storage user = userRoundMapping[rid][_msgSender()];
		require(user.id != 0, "user not exist");
		uint sendMoney = user.freeAmount + user.lineAmount;

		require(sendMoney > 0, "Incorrect sendMoney");

		bool isEnough = false;
		uint resultMoney = 0;

		(isEnough, resultMoney) = isEnoughBalance(sendMoney);

        require(resultMoney > 0, "not Enough Balance");

		if (resultMoney > 0 && resultMoney <= withdrawLimit) {
			user.freeAmount = 0;
			user.lineAmount = 0;
			user.nodeLevel = getNodeLevel(user.freezeAmount);
            sendMoneyToUser(_msgSender(), resultMoney);
		}

        emit WithdrawEvent(_msgSender(), resultMoney, now);
	}

    /**
     * @dev the invest of contract is Beginning
     * @param code user invite Code
     * @param rCode recommend code
     */
	function invest(string memory code, string memory rCode)
        public
        payable
        isHuman()
    {
		require(isOpen(), "Contract no open");
		require(_msgValue() >= ethWei.mul(1) && _msgValue() <= ethWei.mul(15), "between 1 and 15");
		require(_msgValue() == _msgValue().div(ethWei).mul(ethWei), "invalid msg value");

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(_msgSender());
        uint user_id = user_data[0];

		if (user_id == 0) {
			_registerUser(_msgSender(), code, rCode);
            (user_data, , ) = _getUserInfo(_msgSender());
            user_id = user_data[0];
		}

		uint investAmout;
		uint lineAmount;
		if (isLine()) {
			lineAmount = _msgValue();
		} else {
			investAmout = _msgValue();
		}
		User storage user = userRoundMapping[rid][_msgSender()];
		if (user.id != 0) {
			require(user.freezeAmount.add(user.lineAmount) == 0, "only once invest");
		} else {
			user.id = user_id;
			user.userAddress = _msgSender();
		}
        user.freezeAmount = investAmout;
        user.lineAmount = lineAmount;
        user.level = getLevel(user.freezeAmount);
        user.nodeLevel = getNodeLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount));

		roundInvestCount[rid] = roundInvestCount[rid].add(1);
		roundInvestMoney[rid] = roundInvestMoney[rid].add(_msgValue());
		if (!isLine()) {
			sendFeeToDevAddr(_msgValue());
			countBonus_All(user.userAddress);
		} else {
			lineArrayMapping[rid].push(user.id);
		}

        emit InvestEvent(_msgSender(), code, rCode, _msgValue(), now);
	}

    /**
     * @dev Show contract state view
     * @return contract state view
     */
    function stateView()
        public
        view
        returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint)
    {
		return (
            _getCurrentUserID(),
            rid,
            startTime,
            canSetStartTime,
            roundInvestCount[rid],
            roundInvestMoney[rid],
            bonuslimit,
            sendLimit,
            withdrawLimit,
            lineStatus,
            lineArrayMapping[rid].length
		);
	}

    /**
     * @dev determine if contract open
     * @return bool
     */
	function isOpen()
        public
        view
        returns (bool)
    {
		return startTime != 0 && now > startTime;
	}

    /**
     * @dev Whether bonus is calculated when determining contract investment
     * @return bool
     */
	function isLine()
        private
        view
        returns (bool)
    {
		return lineStatus != 0;
	}

    /**
     * @dev get the user id of the round ID or current round [lineArrayMapping] based on the index
     * @param index the index of [lineArrayMapping]
     * @param roundId round ID (Go to the current for empty)
     * @return user ID
     */
	function getLineUserId(uint index, uint roundId)
        public
        view
        returns (uint)
    {
		require(checkWhitelist(), "Permission denied");
		if (roundId == 0) {
			roundId = rid;
		}
		return lineArrayMapping[rid][index];
	}

    /**
     * @dev get the user info based on user ID and round ID
     * @param addr user address
     * @param roundId round ID (Go to the current for empty)
     * @param rewardIndex user current index of award
     * @param useRewardIndex use user current index of award
     * @return user info
     */
	function getUserByAddress(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        public
        view
        returns (uint[17] memory info, string memory code, string memory rCode)
    {
		require(checkWhitelist() || _msgSender() == addr, "Permission denied for view user's privacy");

		if (roundId == 0) {
			roundId = rid;
		}

        uint[2] memory user_data;
        (user_data, code, rCode) = _getUserInfo(addr);
        uint user_id = user_data[0];
        uint user_status = user_data[1];

		User memory user = userRoundMapping[roundId][addr];

        uint historyDayBonusAmount = 0;
        uint settlementbonustime = 0;
        if (useRewardIndex)
        {
            AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            historyDayBonusAmount = awData.staticAmount;
            settlementbonustime = awData.time;
        }

        uint grantAmount = 0;
		if (user.id > 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user.investTimes < 5 && user_status != 1) {
            if (!useRewardIndex)
            {
                grantAmount = grantAmount.add(user.dayBonusAmount);
            }
		}

        grantAmount = grantAmount.add(getBonusAmount_Dynamic(addr, roundId, rewardIndex, useRewardIndex));

		info[0] = user_id;
		info[1] = user.lineAmount;//bonus calculation mode line
        info[2] = user.freezeAmount;//invest lock
        info[3] = user.freeAmount;//invest out unlock
        info[4] = user.dayBonusAmount;//Daily bonus amount (static bonus)
        info[5] = user.bonusAmount;//add up static bonus amonut (static bonus)
        info[6] = grantAmount;//No settlement of invitation bonus amount (dynamic bonus)
		info[7] = user.inviteAmonut;//add up invite bonus amonut (dynamic bonus)
        info[8] = user.level;//user level
        info[9] = user.nodeLevel;//user node Level
        info[10] = _getRCodeMappingLength(code);//user node number
        info[11] = user.investTimes;//settlement bonus number
		info[12] = user.rewardIndex;//user current index of award
        info[13] = user.lastRwTime;//last settlement time
        info[14] = user_status;//user status
        info[15] = historyDayBonusAmount;//history daily bonus amount (static bonus) (reward Index is not zero)
        info[16] = settlementbonustime;//history daily settlement bonus time (reward Index is not zero)

		return (info, code, rCode);
	}

    /**
     * @dev Calculate the bonus (All)
     * @param addr user address
     */
	function countBonus_All(address addr)
        private
    {
		User storage user = userRoundMapping[rid][addr];
		if (user.id == 0) {
			return;
		}
		uint staticScale = getScaleByLevel(user.level);
		user.dayBonusAmount = user.freezeAmount.mul(staticScale).div(1000);
		user.investTimes = 0;

        uint[2] memory user_data;
        string memory user_rCode;
        (user_data, , user_rCode) = _getUserInfo(addr);
        uint user_status = user_data[1];

		if (user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user_status == 0) {
			countBonus_Dynamic(user_rCode, user.freezeAmount, staticScale);
		}
	}

    /**
     * @dev Calculate the bonus (dynamic)
     * @param rCode user recommend code
     * @param money invest money
     * @param staticScale static scale
     */
	function countBonus_Dynamic(string memory rCode, uint money, uint staticScale)
        private
    {
		string memory tmpReferrerCode = rCode;

		for (uint i = 1; i <= 25; i++) {
			if (tmpReferrerCode.compareStr("")) {
				break;
			}
			address tmpUserAddr = _getCodeMapping(tmpReferrerCode);
			User memory tmpUser = userRoundMapping[rid][tmpUserAddr];

            string memory tmpUser_rCode;
            (, , tmpUser_rCode) = _getUserInfo(tmpUserAddr);

			if (tmpUser.freezeAmount.add(tmpUser.freeAmount).add(tmpUser.lineAmount) == 0) {
				tmpReferrerCode = tmpUser_rCode;
				continue;
			}

            //use max Recommend Level Scale
            //The actual proportion is used for settlement
			uint recommendScale = getRecommendScaleByLevelAndTim(3, i);
			uint moneyResult = 0;
			if (money <= ethWei.mul(15)) {
				moneyResult = money;
			} else {
				moneyResult = ethWei.mul(15);
			}

			if (recommendScale != 0) {
				uint tmpDynamicAmount = moneyResult.mul(staticScale).mul(recommendScale);
				tmpDynamicAmount = tmpDynamicAmount.div(1000).div(100);
				recordAwardData(tmpUserAddr, tmpDynamicAmount, tmpUser.rewardIndex, i);
			}
			tmpReferrerCode = tmpUser_rCode;
		}
	}

    /**
     * @dev Record bonus data
     * @param addr user address
     * @param awardAmount Calculated award amount
     * @param rewardIndex user current index of award
     * @param times The layer number of recommended
     */
	function recordAwardData(address addr, uint awardAmount, uint rewardIndex, uint times)
        private
    {
		for (uint i = 0; i < 5; i++) {
			AwardData storage awData = userAwardDataMapping[rid][addr][rewardIndex.add(i)];
			if (times == 1) {
				awData.oneInvAmount = awData.oneInvAmount.add(awardAmount);
			}
			if (times == 2) {
				awData.twoInvAmount = awData.twoInvAmount.add(awardAmount);
			}
			awData.threeInvAmount = awData.threeInvAmount.add(awardAmount);
		}
	}

    /**
     * @dev send fee to the develop addr
     * @param amount send amount (4%)
     */
	function sendFeeToDevAddr(uint amount)
        private
    {
        sendMoneyToUser(devAddr, amount.div(25));
	}

    /**
     * @dev  get the bonus bmount based on user address and reward Index  (dynamic)
     * @param addr user address
     * @param roundId round ID
     * @param rewardIndex user current index of award
     * @param useRewardIndex use user current index of award
     * @return bonus amount
     */
	function getBonusAmount_Dynamic(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        private
        view
        returns (uint)
    {
        uint resultAmount = 0;
		User memory user = userRoundMapping[roundId][addr];

        if (!useRewardIndex) {
			rewardIndex = user.rewardIndex;
		}

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(addr);
        uint user_status = user_data[1];

        uint lineAmount = user.freezeAmount.add(user.freeAmount).add(user.lineAmount);
		if (user_status == 0 && lineAmount >= ethWei.mul(1) && lineAmount <= withdrawLimit) {
			uint inviteAmount = 0;
			AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            uint lineValue = lineAmount.div(ethWei);
            if (lineValue >= 15) {
                inviteAmount = inviteAmount.add(awData.threeInvAmount);
            } else {
                if (user.nodeLevel == 1 && lineAmount >= ethWei.mul(1) && awData.oneInvAmount > 0) {
                    //dev getRecommendScaleByLevelAndTim(3, 1)/getRecommendScaleByLevelAndTim(1, 1)=2   100/50=2
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).div(2));
                }
                if (user.nodeLevel == 2 && lineAmount >= ethWei.mul(1) && (awData.oneInvAmount > 0 || awData.twoInvAmount > 0)) {
                    //mul getRecommendScaleByLevelAndTim(3, 1)  100 â  getRecommendScaleByLevelAndTim(2, 1)  70
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).mul(7).div(10));
                    //mul getRecommendScaleByLevelAndTim(3, 2)  70 â  getRecommendScaleByLevelAndTim(2, 2)  50
                    inviteAmount = inviteAmount.add(awData.twoInvAmount.div(15).mul(lineValue).mul(5).div(7));
                }
                if (user.nodeLevel == 3 && lineAmount >= ethWei.mul(1) && awData.threeInvAmount > 0) {
                    inviteAmount = inviteAmount.add(awData.threeInvAmount.div(15).mul(lineValue));
                }
                if (user.nodeLevel < 3) {
                    //bonus burn
                    uint burnScale = getBurnScaleByLevel(user.nodeLevel);
                    inviteAmount = inviteAmount.mul(burnScale).div(10);
                }
            }
            resultAmount = resultAmount.add(inviteAmount);
		}

        return resultAmount;
	}
}"},"DBUtilli.sol":{"content":"pragma solidity ^0.5.0;

import './Context.sol';
import './Whitelist.sol';
import './IDB.sol';

/**
 * @title DBUtilli
 * @dev This Provide database support services (db)
 */
contract DBUtilli is Context, Whitelist {

    //include other contract
    IDB internal db;

    /**
     * @dev Create store user information (db)
     * @param addr user address
     * @param code user invite Code
     * @param rCode recommend code
     */
    function _registerUser(address addr, string memory code, string memory rCode)
        internal
    {
        db.registerUser(addr, code, rCode);
	}

    /**
     * @dev Set store user information
     * @param addr user addr
     * @param status user status
     */
    function _setUser(address addr, uint status)
        internal
    {
		db.setUser(addr, status);
	}

    /**
     * @dev determine if user invite code is use (db)
     * @param code user invite Code
     * @return bool
     */
    function _isUsedCode(string memory code)
        internal
        view
        returns (bool isUser)
    {
        isUser = db.isUsedCode(code);
		return isUser;
	}

    /**
     * @dev get the user address of the corresponding user invite code (db)
     * Authorization Required
     * @param code user invite Code
     * @return address
     */
    function _getCodeMapping(string memory code)
        internal
        view
        returns (address addr)
    {
        addr = db.getCodeMapping(code);
        return  addr;
	}

    /**
     * @dev get the user address of the corresponding user id (db)
     * Authorization Required
     * @param uid user id
     * @return address
     */
    function _getIndexMapping(uint uid)
        internal
        view
        returns (address addr)
    {
        addr = db.getIndexMapping(uid);
		return addr;
	}

    /**
     * @dev get the user address of the corresponding User info (db)
     * Authorization Required or addr is owner
     * @param addr user address
     * @return info[id,status],code,rCode
     */
    function _getUserInfo(address addr)
        internal
        view
        returns (uint[2] memory info, string memory code, string memory rCode)
    {
        (info, code, rCode) = db.getUserInfo(addr);
		return (info, code, rCode);
	}

    /**
     * @dev get the current latest ID (db)
     * Authorization Required
     * @return current uid
     */
    function _getCurrentUserID()
        internal
        view
        returns (uint uid)
    {
        uid = db.getCurrentUserID();
		return uid;
	}

    /**
     * @dev get the rCodeMapping array length of the corresponding recommend Code (db)
     * Authorization Required
     * @param rCode recommend Code
     * @return rCodeMapping array length
     */
    function _getRCodeMappingLength(string memory rCode)
        internal
        view
        returns (uint length)
    {
        length = db.getRCodeMappingLength(rCode);
		return length;
	}

    /**
     * @dev get the user invite code of the recommend Code [rCodeMapping] based on the index (db)
     * Authorization Required
     * @param rCode recommend Code
     * @param index the index of [rCodeMapping]
     * @return user invite code
     */
    function _getRCodeMapping(string memory rCode, uint index)
        internal
        view
        returns (string memory code)
    {
        code = db.getRCodeMapping(rCode, index);
		return code;
	}

    /**
     * @dev determine if user invite code is use (db)
     * @param code user invite Code
     * @return bool
     */
    function isUsedCode(string memory code)
        public
        view
        returns (bool isUser)
    {
        isUser = _isUsedCode(code);
		return isUser;
	}

    /**
     * @dev get the user address of the corresponding user invite code (db)
     * Authorization Required
     * @param code user invite Code
     * @return address
     */
    function getCodeMapping(string memory code)
        public
        view
        returns (address addr)
    {
        require(checkWhitelist(), "DBUtilli: Permission denied");
        addr = _getCodeMapping(code);
		return addr;
	}

    /**
     * @dev get the user address of the corresponding user id (db)
     * Authorization Required
     * @param uid user id
     * @return address
     */
    function getIndexMapping(uint uid)
        public
        view
        returns (address addr)
    {
        require(checkWhitelist(), "DBUtilli: Permission denied");
		addr = _getIndexMapping(uid);
        return addr;
	}

    /**
     * @dev get the user address of the corresponding User info (db)
     * Authorization Required or addr is owner
     * @param addr user address
     * @return info[id,status],code,rCode
     */
    function getUserInfo(address addr)
        public
        view
        returns (uint[2] memory info, string memory code, string memory rCode)
    {
        require(checkWhitelist() || _msgSender() == addr, "DBUtilli: Permission denied for view user's privacy");
        (info, code, rCode) = _getUserInfo(addr);
		return (info, code, rCode);
	}
}
"},"HumanChsek.sol":{"content":"pragma solidity ^0.5.11;

import './Context.sol';

/**
 * @title HumanChsek
 * @dev This Provide check address is contract
 */
contract HumanChsek is Context {

    /**
     * @dev modifier to scope access to a Contract (uses tx.origin and msg.sender)
     */
	modifier isHuman() {
		require(_msgSender() == _txOrigin(), "HumanChsek: sorry, humans only");
		_;
	}

}
"},"IDB.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @title DB interface
 * @dev This Provide database support services interface
 */
contract IDB {
    function registerUser(address addr, string memory code, string memory rCode) public;
    function setUser(address addr, uint status) public;
    function isUsedCode(string memory code) public view returns (bool);
    function getCodeMapping(string memory code) public view returns (address);
    function getIndexMapping(uint uid) public view returns (address);
    function getUserInfo(address addr) public view returns (uint[2] memory info, string memory code, string memory rCode);
    function getCurrentUserID() public view returns (uint);
    function getRCodeMappingLength(string memory rCode) public view returns (uint);
    function getRCodeMapping(string memory rCode, uint index) public view returns (string memory);
}"},"Ownable.sol":{"content":"pragma solidity ^0.5.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
    constructor () internal {
        _owner = _msgSender();
        emit OwnerTransferred(address(0), _owner);
    }

    /**
     * @dev modifier Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: it is not called by the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     * @return bool
     */
    function isOwner()
        internal
        view
        returns(bool)
    {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        require(newOwner != address(0),'Ownable: new owner is the zero address');
        emit OwnerTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner()
        public
        view
        returns(address)
    {
        return _owner;
    }
}"},"RBAC.sol":{"content":"pragma solidity ^0.5.0;

import './Context.sol';
import './Roles.sol';

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC is Context {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param _role the name of the role
     * // reverts
     */
    modifier onlyRole(string memory _role)
    {
        checkRole(_msgSender(), _role);
        _;
    }

    /**
     * @dev add a role to an address
     * @param _operator address
     * @param _role the name of the role
     */
    function addRole(address _operator, string memory _role)
        internal
    {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    /**
     * @dev remove a role from an address
     * @param _operator address
     * @param _role the name of the role
     */
    function removeRole(address _operator, string memory _role)
        internal
    {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

        /**
     * @dev reverts if addr does not have role
     * @param _operator address
     * @param _role the name of the role
     * // reverts
     */
    function checkRole(address _operator, string memory _role)
        internal
        view
    {
        roles[_role].check(_operator);
    }

    /**
     * @dev determine if addr has role
     * @param _operator address
     * @param _role the name of the role
     * @return bool
     */
    function hasRole(address _operator, string memory _role)
        internal
        view
        returns (bool)
    {
        return roles[_role].has(_operator);
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
     * @dev give an address access to this role
     */
    function add(Role storage _role, address _addr)
        internal
    {
        require(!has(_role, _addr), "Roles: addr already has role");
        _role.bearer[_addr] = true;
    }

    /**
     * @dev remove an address' access to this role
     */
    function remove(Role storage _role, address _addr)
        internal
    {
        require(has(_role, _addr), "Roles: addr do not have role");
        _role.bearer[_addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage _role, address _addr)
        internal
        view
    {
        require(has(_role, _addr),'Roles: addr do not have role');
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage _role, address _addr)
        internal
        view
        returns (bool)
    {
        require(_addr != address(0), "Roles: not the zero address");
        return _role.bearer[_addr];
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
}
"},"String.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @title String
 * @dev This integrates the basic functions.
 */
library String {
    /**
     * @dev determine if strings are equal
     * @param _str1 strings
     * @param _str2 strings
     * @return bool
     */
    function compareStr(string memory _str1, string memory _str2)
        internal
        pure
        returns(bool)
    {
        if(keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))) {
            return true;
        }
        return false;
    }
}"},"Whitelist.sol":{"content":"pragma solidity ^0.5.0;

import './Context.sol';
import './Ownable.sol';
import './Roles.sol';
import './RBAC.sol';

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Context, Ownable, RBAC {
    string private constant ROLE_WHITELISTED = "whitelist";

    /**
     * @dev Throws if operator is not whitelisted.
     */
    modifier onlyIfWhitelisted() {
        require(isWhitelist(_msgSender()), "Whitelist: The operator is not whitelisted");
        _;
    }

    /**
     * @dev check current operator is in whitelist
     * @return bool
     */
    function checkWhitelist()
        internal
        view
        returns (bool)
    {
        return isWhitelist(_msgSender());
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }
    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

    /**
     * @dev determine if address is in whitelist
     * @param _operator address
     * @return bool
     */
    function isWhitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED) || isOwner();
    }
}
"}}