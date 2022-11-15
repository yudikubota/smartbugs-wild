{"Adminable.sol":{"content":"pragma solidity ^0.5.2;

import "./Ownable.sol";

contract Adminable is Ownable {
    mapping (address => bool) public admins;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "not admin");
        _;
    }

    function setAdmin(address user, bool value) external onlyOwner {
        admins[user] = value;
    }

    function isAdmin(address user) internal view returns (bool) {
      return admins[user] || isOwner();
    }
}
"},"Lottery.sol":{"content":"pragma solidity ^0.5.2;

import "./Adminable.sol";

interface ILottoshi {
    function contribute(address referral) external payable;
    function decentralize() external;
    function totalSupply() external view returns (uint);
}

contract Lottery is Adminable {
    struct Round {
        uint256 seed;
        uint256 perWinnerPrizes1;
        uint256 perWinnerPrizes2;
        uint256 prizes;
        uint128 ticketCount;
        uint128 checkedCount;
        uint56 result;
        uint128 revealedCount;
        mapping (address => bytes32) commitments;
        mapping (uint256 => Ticket) tickets;
        mapping (uint256 => ComboTicket) comboTickets;
    }

    struct Ticket {
        bool claimed;
        address payable owner;
        uint56 number;
    }

    struct ComboTicket {
        uint256 number1; // zone1Count,zone2Count,zone2Number,zone1Numbers
        uint256 number2;
    }

    struct Number {
        uint256 n0;
        uint256 n1;
        uint256 n2;
        uint256 n3;
        uint256 n4;
        uint256 n5;
        uint256 n6;
    }

    // production
    uint256 internal constant NORMAL_DURATION = 24 hours;
    uint256 internal constant REVEALING_DURATION = 50 minutes;
    uint256 internal constant CONFIRMING_DURATION = 10 minutes;
    uint256 internal constant OWNER_TIMEOUT = 10 days;

    uint256 internal constant PRIZE_TARGET = 20000 ether;
    uint256 internal constant DEADLINE_ROUNDS = 365;
    uint256 internal constant COST_PER_TICKET = 0.01 ether;
    uint256 internal constant REVEAL_PRIZE = 0.5 ether;
    uint256 internal constant REVEAL_PRIZE_PLACE = 11;
    uint256 internal constant PERCENTAGE_TO_FUND = 3000;
    uint256 internal constant OFFSET = 10000;
    uint256 internal constant PERCENTAGE_OF_PRIZE1 = 5340; // 53.4%
    uint256 internal constant PERCENTAGE_OF_PRIZE2 = 660;  // 6.6%
    uint256[8] internal PRIZES = [
        COST_PER_TICKET * 1500,
        COST_PER_TICKET * 200,
        COST_PER_TICKET * 40,
        COST_PER_TICKET * 8,
        COST_PER_TICKET * 4,
        COST_PER_TICKET * 2,
        COST_PER_TICKET * 1,
        COST_PER_TICKET * 1
    ];

    mapping (uint256 => Round) public rounds;
    uint256 public roundId = 1;
    uint256 public lastAvailablePrize;
    uint256 public pendingPrize;
    uint256 public revealingUntil;
    uint256 public normalUntil;
    address payable public lottoshi;
    Status public status = Status.normal;
    bool public decentralized;
    bool public liquidated;
    bool public targetReached;

    event Buy(address indexed user, uint256 roundId, uint256 ticketId, address referral, uint56 number, uint256 number1, uint256 number2);
    event Result(uint256 roundId, uint256 result, uint256 perWinnerPrizes1, uint256 perWinnerPrizes2, uint256 prizes, uint128 ticketCount);
    event ClaimReward(uint256 roundId, uint256 ticketId);
    event Commit(uint256 roundId, address user);
    event Reveal(uint256 roundId, address user);
    event RevealPrize(uint256 roundId, address user);

    enum Status {
        normal,
        revealing,
        checking
    }

    modifier onlyHuman() {
        require(msg.sender == tx.origin, "not human");
        _;
    }

    constructor() public {
        normalUntil = uint32(getTime() + NORMAL_DURATION);
    }

    function() external payable {
    }

    function liquidate() external {
        require(status == Status.normal, "invalid status");
        require(!liquidated, "method disabled");
        require(roundId > DEADLINE_ROUNDS, "invalid round");
        require(!targetReached, "target is reached");
        liquidated = true;
        if (!decentralized) {
            decentralized = true;
            ILottoshi(lottoshi).decentralize();
        }
        ILottoshi(lottoshi).contribute.value(getAvailablePrize())(address(0));
    }

    function setLottoshiAddress(address payable addr) external onlyOwner {
        require(lottoshi == address(0), "already set");
        lottoshi = addr;
    }

    function backToNormal() external payable onlyAdmin {
        require(!decentralized, "method disabled");
        require(status == Status.revealing, "invalid status");
        uint256 cost = REVEAL_PRIZE * 100;
        require(msg.value >= cost, "insufficient money");
        status = Status.normal;
        --roundId;
        normalUntil = uint32(getTime() + NORMAL_DURATION);
        rounds[roundId].revealedCount = 0;
        if (msg.value > cost) {
            msg.sender.transfer(msg.value - cost);
        }
    }

    function buyTickets(uint256[] calldata numbers, address referral) external payable {
        uint256 length = numbers.length;
        uint256 totalCost = length * COST_PER_TICKET;
        require(msg.value >= totalCost, "insufficient money");

        address ref = referral == msg.sender ? address(0) : referral;
        uint256 tmpRoundId = roundId;
        uint128 ticketCount = rounds[tmpRoundId].ticketCount;
        for (uint256 i = 0; i < length; i++) {
            uint256 number = numbers[i];
            validateNumber(number);
            ++ticketCount;
            rounds[tmpRoundId].tickets[ticketCount] = Ticket(false, msg.sender, uint56(number));
            emit Buy(msg.sender, tmpRoundId, ticketCount, ref, uint56(number), 0, 0);
        }
        rounds[tmpRoundId].ticketCount = ticketCount;

        ILottoshi(lottoshi).contribute.value(totalCost * PERCENTAGE_TO_FUND / OFFSET)(ref);
        if (msg.value - totalCost > 0) {
            msg.sender.transfer(msg.value - totalCost);
        }
    }

    function buyComboTicket(uint256 number1, uint256 number2, address referral) external payable {
        uint256 zone1Count = number1 >> 248;
        uint256 zone2Count = (number1 >> 240) & 0xff;
        require(zone1Count >= 6 && zone1Count <= 38, "invalid zone1Count");
        require(zone2Count >= 1 && zone2Count <= 8, "invalid zone2Count");
        uint256 count = combinations(zone1Count, 6) * zone2Count;
        uint256 totalCost = count * COST_PER_TICKET;
        require(msg.value >= totalCost, "insufficient money");
        validateComboTicket(number1, number2, zone1Count, zone2Count);

        address ref = referral == msg.sender ? address(0) : referral;
        uint256 tmpRoundId = roundId;
        uint128 ticketCount = rounds[tmpRoundId].ticketCount;
        ++ticketCount;
        rounds[tmpRoundId].tickets[ticketCount] = Ticket(false, msg.sender, 0);
        rounds[tmpRoundId].comboTickets[ticketCount].number1 = number1;
        if (number2 != 0) {
            rounds[tmpRoundId].comboTickets[ticketCount].number2 = number2;
        }
        emit Buy(msg.sender, tmpRoundId, ticketCount, ref, 0, number1, number2);
        rounds[tmpRoundId].ticketCount = ticketCount;
        ILottoshi(lottoshi).contribute.value(totalCost * PERCENTAGE_TO_FUND / OFFSET)(ref);
        if (msg.value - totalCost > 0) {
            msg.sender.transfer(msg.value - totalCost);
        }
    }

    function validateComboTicket(uint256 number1, uint256 number2, uint256 zone1Count, uint256 zone2Count) internal pure {
        uint256 n1 = (number1 >> 232) & 0xff;
        require(n1 >= 1, "invalid number");
        uint256 length = (zone2Count + 2) << 3;
        n1 = validateComboNumber(number1, n1, 24, length);
        require(n1 <= 8, "invalid number");

        n1 = (number1 >> (248 - length)) & 0xff;
        require(n1 >= 1, "invalid number");
        length = (zone1Count > 30 - zone2Count ? 32 : zone1Count + zone2Count + 2) << 3;
        n1 = validateComboNumber(number1, n1, (zone2Count + 3) << 3, length);
        if (zone1Count > 30 - zone2Count) {
            length = (zone1Count - 30 + zone2Count) << 3;
            n1 = validateComboNumber(number2, n1, (zone2Count + 3) << 3, length);
        }
        require(n1 <= 38, "invalid number");
    }

    function commit(bytes32 commitment) external onlyHuman {
        if (isAdmin(msg.sender) && !decentralized) {
            require(getTime() >= normalUntil, "invalid time");
            startRevealing();
            rounds[roundId - 1].commitments[address(0)] = commitment;
            emit Commit(roundId - 1, address(0));
        } else {
            rounds[roundId].commitments[msg.sender] = commitment;
            emit Commit(roundId, msg.sender);
        }
    }

    function endCommit() external {
        require(getTime() >= (decentralized ? normalUntil : normalUntil + OWNER_TIMEOUT), "invalid time");
        startRevealing();
        if (!decentralized) {
            decentralized = true;
            ILottoshi(lottoshi).decentralize();
        }
    }

    function startRevealing() internal {
        require(status == Status.normal, "invalid status");
        uint256 prize = getAvailablePrize();
        require(prize >= REVEAL_PRIZE, "insufficient money");
        ++roundId;
        status = Status.revealing;
        revealingUntil = getTime() + REVEALING_DURATION;
        lastAvailablePrize = prize - REVEAL_PRIZE;
        if (lastAvailablePrize >= PRIZE_TARGET && !targetReached) {
            targetReached = true;
        }
    }

    function reveal(uint256 secret) external onlyHuman {
        require(status == Status.revealing, "invalid status");
        uint256 tmpRoundId = roundId - 1;
        if (isAdmin(msg.sender) && !decentralized) {
            require(getTime() >= revealingUntil + CONFIRMING_DURATION, "invalid time");
            require(getHash(secret) == rounds[tmpRoundId].commitments[address(0)], "invalid secret");
            rounds[tmpRoundId].commitments[address(0)] = 0;
            uint256 seed = rounds[tmpRoundId].seed;
            seed += uint256(getBlockHash(block.number - 20));
            seed += secret;
            startChecking(seed);
            rounds[tmpRoundId].seed = seed;
            emit Reveal(tmpRoundId, address(0));
        } else {
            require(getTime() < revealingUntil, "invalid time");
            require(getHash(secret) == rounds[tmpRoundId].commitments[msg.sender], "invalid secret");
            rounds[tmpRoundId].commitments[msg.sender] = 0;
            rounds[tmpRoundId].seed += secret;
            emit Reveal(tmpRoundId, msg.sender);
        }
        ++rounds[tmpRoundId].revealedCount;
        if (rounds[tmpRoundId].revealedCount == REVEAL_PRIZE_PLACE) {
            msg.sender.transfer(REVEAL_PRIZE);
            emit RevealPrize(tmpRoundId, msg.sender);
        }
    }

    function endReveal() external {
        require(status == Status.revealing, "invalid status");
        uint256 time = decentralized ? revealingUntil + CONFIRMING_DURATION : revealingUntil + CONFIRMING_DURATION + OWNER_TIMEOUT;
        require(getTime() >= time, "invalid time");
        uint256 seed = rounds[roundId - 1].seed;
        seed += uint256(getBlockHash(block.number - 20));
        rounds[roundId - 1].seed = seed;
        startChecking(seed);
        if (!decentralized) {
            decentralized = true;
            ILottoshi(lottoshi).decentralize();
        }
    }

    function startChecking(uint256 seed) internal {
        status = Status.checking;
        uint256[6] memory numbers = drawNumbers(seed);
        uint256 ns = random(seed + 6, 8) + 1;
        rounds[roundId - 1].result = uint56(
            (numbers[0] << 48) | (numbers[1] << 40) | (numbers[2] << 32) |
            (numbers[3] << 24) | (numbers[4] << 16) | (numbers[5] << 8) | ns
        );
    }

    function checkTickets(uint256 count) external {
        require (status == Status.checking, "invalid status");
        uint256 tmpRoundId = roundId - 1;
        Round memory round = rounds[tmpRoundId];
        if (round.ticketCount == 0) {
            status = Status.normal;
            normalUntil = getTime() + NORMAL_DURATION;
            emit Result(tmpRoundId, round.result, 0, 0, 0, 0);
            return;
        }
        require (count > 0, "invalid count");
        uint256 end = round.checkedCount + count;
        if (end > round.ticketCount) {
            end = round.ticketCount;
        }
        uint256[10] memory prizes = decodePrize(round.prizes);
        Number memory result = decodeNumberAsStruct(round.result);
        bool prizesChanged = false;
        for (uint256 i = round.checkedCount + 1; i <= end; ++i) {
            uint56 number = rounds[tmpRoundId].tickets[i].number;
            if (number == 0) {
                uint256[10] memory levels = getComboPrizeLevels(
                    rounds[tmpRoundId].comboTickets[i].number1, rounds[tmpRoundId].comboTickets[i].number2, result
                );
                for (uint256 j = 0; j < 10; ++j) {
                    uint256 prizeCount = levels[j];
                    if (prizeCount > 0) {
                        prizes[j] += prizeCount;
                        prizesChanged = true;
                    }
                }
            } else {
                uint256 level = getPrizeLevel(number, result);
                if (level > 0) {
                    ++prizes[level - 1];
                    prizesChanged = true;
                }
            }
        }
        round.checkedCount = uint128(end);
        if (prizesChanged) {
            rounds[tmpRoundId].prizes = encodePrize(prizes);
        }
        // all done
        if (round.checkedCount == round.ticketCount) {
            updatePrizes(tmpRoundId, round, prizes);
            status = Status.normal;
            normalUntil = uint32(getTime() + NORMAL_DURATION);
            emit Result(tmpRoundId, round.result, round.perWinnerPrizes1, round.perWinnerPrizes2, rounds[tmpRoundId].prizes, round.ticketCount);
        }
        rounds[tmpRoundId].checkedCount = round.checkedCount;
    }

    function updatePrizes(uint256 tmpRoundId, Round memory round, uint256[10] memory prizes) internal {
        uint256 fixedPrize;
        for (uint256 i = 0; i < 8; ++i) {
            fixedPrize += prizes[i + 2] * PRIZES[i];
        }
        require(getAvailablePrize() >= fixedPrize, "insufficient money");
        uint256 remainPrize = lastAvailablePrize;
        remainPrize = remainPrize >= fixedPrize ? remainPrize - fixedPrize : 0;
        uint256 prize1 = remainPrize * PERCENTAGE_OF_PRIZE1 / OFFSET;
        uint256 prize2 = remainPrize * PERCENTAGE_OF_PRIZE2 / OFFSET;
        uint256 length1 = prizes[0];
        uint256 length2 = prizes[1];
        round.perWinnerPrizes1 = length1 == 0 ? 0 : prize1 / length1;
        round.perWinnerPrizes2 = length2 == 0 ? 0 : prize2 / length2;
        uint256 totalPrize = fixedPrize + round.perWinnerPrizes2 * length2 + round.perWinnerPrizes1 * length1;
        if (totalPrize > 0) {
            pendingPrize += totalPrize;
        }
        if (round.perWinnerPrizes1 > 0) {
            rounds[tmpRoundId].perWinnerPrizes1 = round.perWinnerPrizes1;
        }
        if (round.perWinnerPrizes2 > 0) {
            rounds[tmpRoundId].perWinnerPrizes2 = round.perWinnerPrizes2;
        }
    }

    function claimRewards(uint256[] calldata inputs) external {
        require(inputs.length % 2 == 0 && inputs.length >= 2, "invalid length");
        uint256 tmpRoundId = inputs[0];
        require(rounds[tmpRoundId].checkedCount == rounds[tmpRoundId].ticketCount, "invalid status");
        uint256 totalPrize;
        address payable user = rounds[tmpRoundId].tickets[inputs[1]].owner;
        Number memory result = decodeNumberAsStruct(rounds[tmpRoundId].result);
        for (uint256 i = 0; i < inputs.length; i += 2) {
            if (tmpRoundId != inputs[i]) {
                tmpRoundId = inputs[i];
                require(rounds[tmpRoundId].checkedCount == rounds[tmpRoundId].ticketCount, "invalid status");
                result = decodeNumberAsStruct(rounds[tmpRoundId].result);
            }
            uint256 ticketId = inputs[i + 1];
            Ticket memory ticket = rounds[tmpRoundId].tickets[ticketId];
            if (ticket.claimed || ticket.owner == address(0) || user != ticket.owner) {
                continue;
            }
            uint256 prize;
            if (ticket.number == 0) {
                uint256[10] memory levels = getComboPrizeLevels(
                    rounds[tmpRoundId].comboTickets[ticketId].number1, rounds[tmpRoundId].comboTickets[ticketId].number2, result
                );
                for (uint256 level = 1; level <= 10; ++level) {
                    uint256 count = levels[level - 1];
                    if (count > 0) {
                        if (level == 1) {
                            prize += rounds[tmpRoundId].perWinnerPrizes1;
                        } else if (level == 2) {
                            prize += rounds[tmpRoundId].perWinnerPrizes2 * count;
                        } else {
                            prize += PRIZES[level - 3] * count;
                        }
                    }
                }
            } else {
                uint256 level = getPrizeLevel(ticket.number, result);
                if (level == 1) {
                    prize = rounds[tmpRoundId].perWinnerPrizes1;
                } else if (level == 2) {
                    prize = rounds[tmpRoundId].perWinnerPrizes2;
                } else if (level > 0) {
                    prize = PRIZES[level - 3];
                }
            }
            if (prize > 0) {
                totalPrize += prize;
                rounds[tmpRoundId].tickets[ticketId].claimed = true;
                emit ClaimReward(tmpRoundId, ticketId);
            }
        }
        require(totalPrize > 0, "no prize");
        require(pendingPrize >= totalPrize, "insufficient money");
        pendingPrize -= totalPrize;
        user.transfer(totalPrize);
    }

    function getCommitment(uint256 _roundId, address user) external view returns (bytes32) {
        return rounds[_roundId].commitments[user];
    }

    function getTicket(uint256 _roundId, uint256 ticketId) external view returns (bool, address, uint256, uint256, uint256) {
        Ticket memory ticket = rounds[_roundId].tickets[ticketId];
        ComboTicket memory comboTicket = rounds[_roundId].comboTickets[ticketId];
        return (ticket.claimed, ticket.owner, ticket.number, comboTicket.number1, comboTicket.number2);
    }

    function getAvailablePrize() public view returns (uint256) {
        return address(this).balance - pendingPrize;
    }

    function getSystemStatus() external view returns (uint256, Status, uint256, uint256, uint256, uint128, uint128) {
        uint256 tmpRoundId = roundId;
        if (status != Status.normal) {
            --tmpRoundId;
        }
        return (
            roundId,
            status,
            normalUntil,
            revealingUntil + CONFIRMING_DURATION,
            now,
            rounds[tmpRoundId].ticketCount,
            rounds[tmpRoundId].checkedCount
        );
    }

    function getPrizeLevel(uint256 number, Number memory result) internal pure returns (uint256) {
        uint256 hit = 0;
        uint256 n0 = result.n0;
        uint256 n1 = result.n1;
        uint256 n2 = result.n2;
        uint256 n3 = result.n3;
        uint256 n4 = result.n4;
        uint256 n5 = result.n5;
        for (uint256 i = 8; i <= 48; i += 8) {
            uint256 n = (number >> i) & 0xff;
            if (n < n3) {
                if (n == n0 || n == n1 || n == n2) {
                    ++hit;
                }
            } else {
                if (n == n3 || n == n4 || n == n5) {
                    ++hit;
                }
            }
        }
        if (hit == 0) {
            return 0;
        } else if (number & 0xff == result.n6) {
            if (hit == 1) {
                return 10;
            } else if (hit == 2) {
                return 8;
            } else if (hit == 3) {
                return 7;
            } else if (hit == 4) {
                return 5;
            } else if (hit == 5) {
                return 3;
            } else {
                return 1;
            }
        } else {
            if (hit < 3) {
                return 0;
            } else if (hit == 3) {
                return 9;
            } else if (hit == 4) {
                return 6;
            } else if (hit == 5) {
                return 4;
            } else {
                return 2;
            }
        }
    }

    function getComboPrizeLevels(uint256 number1, uint256 number2, Number memory result) internal pure returns (uint256[10] memory) {
        uint256[10] memory levels;
        uint256 zone1Count = number1 >> 248;
        uint256 zone2Count = (number1 >> 240) & 0xff;
        uint256 n6 = result.n6;
        uint256 length = (zone2Count + 2) << 3;
        uint256 zone2HitCombinations;
        for (uint256 i = 16; i < length; i += 8) {
            uint256 n = (number1 >> (248 - i)) & 0xff;
            if (n == n6) {
                zone2HitCombinations = 1;
                break;
            }
        }
        uint256 zone1Hit = getZone1Hit(zone1Count, zone2Count, number1, number2, result);
        if (zone1Hit > 0) {
            uint256 zone2NoHitCombinations = zone2Count - zone2HitCombinations;
            if (zone2HitCombinations == 1) {
                levels[9] = zone1Hit * combinations(zone1Count - zone1Hit, 5);
            }

            if (zone1Hit > 1) {
                if (zone2HitCombinations == 1) {
                    levels[7] = combinations(zone1Hit, 2) * combinations(zone1Count - zone1Hit, 4);
                }

                if (zone1Hit > 2) {
                    uint256 zone1Combinations = combinations(zone1Hit, 3) * combinations(zone1Count - zone1Hit, 3);
                    levels[6] = zone1Combinations * zone2HitCombinations;
                    levels[8] = zone1Combinations * zone2NoHitCombinations;

                    if (zone1Hit > 3) {
                        zone1Combinations = combinations(zone1Hit, 4) * combinations(zone1Count - zone1Hit, 2);
                        levels[4] = zone1Combinations * zone2HitCombinations;
                        levels[5] = zone1Combinations * zone2NoHitCombinations;

                        if (zone1Hit > 4) {
                            zone1Combinations = combinations(zone1Hit, 5) * combinations(zone1Count - zone1Hit, 1);
                            levels[2] = zone1Combinations * zone2HitCombinations;
                            levels[3] = zone1Combinations * zone2NoHitCombinations;

                            if (zone1Hit > 5) {
                                levels[0] = zone2HitCombinations;
                                levels[1] = zone2NoHitCombinations;
                            }
                        }
                    }
                }
            }
        }

        return levels;
    }

    function getZone1Hit(
        uint256 zone1Count, uint256 zone2Count, uint256 number1, uint256 number2, Number memory result
    ) internal pure returns (uint256) {
        uint256 hit = 0;
        uint256 n0 = result.n0;
        uint256 n1 = result.n1;
        uint256 n2 = result.n2;
        uint256 n3 = result.n3;
        uint256 n4 = result.n4;
        uint256 n5 = result.n5;
        uint256 length = (zone1Count > 30 - zone2Count ? 32 : zone1Count + zone2Count + 2) << 3;
        for (uint256 i = (zone2Count + 2) << 3; i < length; i += 8) {
            uint256 n = (number1 >> (248 - i)) & 0xff;
            if (n < n3) {
                if (n == n0 || n == n1 || n == n2) {
                    ++hit;
                }
            } else {
                if (n == n3 || n == n4 || n == n5) {
                    ++hit;
                }
            }
        }
        if (zone1Count > 30 - zone2Count) {
            length = (zone1Count - 30 + zone2Count) * 8;
            for (uint256 i = 0; i < length; i += 8) {
                uint256 n = (number2 >> (248 - i)) & 0xff;
                if (n < n3) {
                    if (n == n0 || n == n1 || n == n2) {
                        ++hit;
                    }
                } else {
                    if (n == n3 || n == n4 || n == n5) {
                        ++hit;
                    }
                }
            }
        }
        return hit;
    }

    function decodeNumberAsStruct(uint256 number) internal pure returns (Number memory) {
        Number memory numbers;
        numbers.n6 = number & 0xff;
        numbers.n5 = (number >> 8) & 0xff;
        numbers.n4 = (number >> 16) & 0xff;
        numbers.n3 = (number >> 24) & 0xff;
        numbers.n2 = (number >> 32) & 0xff;
        numbers.n1 = (number >> 40) & 0xff;
        numbers.n0 = (number >> 48) & 0xff;
        return numbers;
    }

    function decodePrize(uint256 prize) internal pure returns (uint256[10] memory) {
        return [
            (prize >> 240) & 0xffff,
            (prize >> 224) & 0xffff,
            (prize >> 208) & 0xffff,
            (prize >> 192) & 0xffff,
            (prize >> 160) & 0xffffffff,
            (prize >> 128) & 0xffffffff,
            (prize >> 96) & 0xffffffff,
            (prize >> 64) & 0xffffffff,
            (prize >> 32) & 0xffffffff,
            prize & 0xffffffff
        ];
    }

    function encodePrize(uint256[10] memory prizes) internal pure returns (uint256) {
        return (prizes[0] << 240) | (prizes[1] << 224) | (prizes[2] << 208) | (prizes[3] << 192) | (prizes[4] << 160) |
            (prizes[5] << 128) | (prizes[6] << 96) | (prizes[7] << 64) | (prizes[8] << 32) | prizes[9];
    }

    function drawNumbers(uint256 seed) internal pure returns (uint256[6] memory) {
        uint256[6] memory numbers;
        uint256[38] memory all;
        for (uint256 i = 0; i < 6; ++i) {
            uint256 j = random(seed + i, 38 - i) + i;
            uint256 a = all[i];
            uint256 b = all[j];
            all[j] = a == 0 ? i + 1 : a;
            all[i] = b == 0 ? j + 1 : b;
        }
        for (uint256 i = 0; i < 6; ++i) {
            numbers[i] = all[i];
        }
        for (uint256 i = 1; i < 6; ++i) {
            uint256 n = numbers[i];
            uint256 j;
            for (j = i; j > 0 && numbers[j - 1] > n; --j) {
                numbers[j] = numbers[j - 1];
            }
            numbers[j] = n;
        }
        return numbers;
    }

    function getHash(uint256 secret) internal pure returns (bytes32) {
        return keccak256(abi.encode(secret));
    }

    function random(uint256 seed, uint256 max) internal pure returns (uint256) {
        return uint256(getHash(seed)) % max;
    }

    function validateNumber(uint256 number) internal pure {
        uint256 n0 = (number >> 48) & 0xff;
        uint256 n1 = (number >> 40) & 0xff;
        uint256 n2 = (number >> 32) & 0xff;
        uint256 n3 = (number >> 24) & 0xff;
        uint256 n4 = (number >> 16) & 0xff;
        uint256 n5 = (number >> 8) & 0xff;
        uint256 n6 = number & 0xff;
        require(n6 >= 1 && n6 <= 8, "invalid number");
        require(n5 <= 38, "invalid number");
        require(n5 > n4, "invalid number");
        require(n4 > n3, "invalid number");
        require(n3 > n2, "invalid number");
        require(n2 > n1, "invalid number");
        require(n1 > n0, "invalid number");
        require(n0 >= 1, "invalid number");
    }

    function validateComboNumber(uint256 number, uint256 startN, uint256 start, uint256 end) internal pure returns (uint256) {
        uint256 n1 = startN;
        for (uint256 i = start; i < end; i += 8) {
            uint256 n2 = (number >> (248 - i)) & 0xff;
            require(n2 > n1, "invalid number");
            n1 = n2;
        }
        return n1;
    }

    function combinations(uint256 n, uint256 m) internal pure returns (uint256) {
        if (n < m) {
            return 0;
        } else if (n == m) {
            return 1;
        } else {
            uint256 r = m < n - m ? m : n - m;
            if (r == 1) {
                return n;
            }
            uint256 a = n - r + 1;
            for (uint256 i = a + 1; i <= n; ++i) {
                a *= i;
            }
            uint256 b = 1;
            for (uint256 i = b + 1; i <= r; ++i) {
                b *= i;
            }
            return a / b;
        }
    }

    function getTime() internal view returns (uint256) {
        return now;
    }

    function getBlockHash(uint256 number) internal view returns (bytes32) {
        return blockhash(number);
    }
}
"},"Ownable.sol":{"content":"pragma solidity ^0.5.2;

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

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}"}}