{"CashBack.sol":{"content":"pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract CashBack is Modifiers {
    using SafeMath for uint;

    function cashBackAmount(address _painter) public view returns (uint cashBackInWei) {
        // last cashBack Calculation Round for Painter
        uint round = cashBackCalculationRound[_painter];

        uint calcCashBack = cashBackCalculated[_painter];
        uint curCashBackPerPaint = maxCashBackPerPaintForRound[round].sub(cashBackPerPaintForRound[round][_painter]);
        uint curCashBack = curCashBackPerPaint.mul(userPaintsForRound[round][_painter]);

        cashBackInWei = calcCashBack.add(curCashBack);
    }

    function withdrawCashBack() external isLiveGame() {
        address withdrawer = msg.sender;
        uint curCashBack = cashBackAmount(withdrawer);
        require(curCashBack > 0, "Cashback can not be 0");

        // last cashBack Calculation Round for Withdrawer
        uint round = cashBackCalculationRound[withdrawer];

        // update states
        cashBackCalculated[withdrawer] = 0;
        cashBackPerPaintForRound[round][withdrawer] = maxCashBackPerPaintForRound[round];

        // transfer cashback
        withdrawer.transfer(curCashBack);
        emit CashBackWithdrawn(currentRound, withdrawer, curCashBack);
    }

    function _distributeCashBack(uint _value) internal {
        uint curRound = currentRound;  // gas consumption optimization
        address painter = msg.sender;

        uint totalPaints = totalPaintsForRound[curRound];
        uint curCashBackPerPaint = _value.div(totalPaints);
        uint updCashBackPerPaint = maxCashBackPerPaintForRound[curRound].add(curCashBackPerPaint);

        // update maxCashBackPerPaintForRound state
        maxCashBackPerPaintForRound[curRound] = updCashBackPerPaint;

        // update already earned cashback in this or prev rounds
        cashBackCalculated[painter] = cashBackAmount(painter);

        // update cashBackCalculationRound state
        if (cashBackCalculationRound[painter] < curRound) {
            cashBackCalculationRound[painter] = curRound;
            // add current round cashback
            cashBackCalculated[painter] = cashBackAmount(painter);
        }

        // update cashBackPerPaintForRound state
        cashBackPerPaintForRound[curRound][painter] = updCashBackPerPaint;

        // update totalCashBackForRound state
        totalCashBackForRound[curRound] = totalCashBackForRound[curRound].add(_value);
    }
}"},"DividendsDistributor.sol":{"content":"pragma solidity 0.4.24;
import "./Modifiers.sol";

contract DividendsDistributor is Modifiers {

    function withdrawFoundersComission() external onlyAdmin() returns (bool) {
        _withdrawDividensHelper(founders);
        return true;
    }

    function withdrawDividends() external returns (bool) {
        _withdrawDividensHelper(msg.sender);
        return true;
    }

    function _withdrawDividensHelper(address _beneficiary) private {
        uint balance = pendingWithdrawals[_beneficiary];
        require(balance > 0, "Dividends withdrawal balance is zero.");

        // set state
        pendingWithdrawals[_beneficiary] = 0;

        // withdrawal dividends
        _beneficiary.transfer(balance);
        emit DividendsWithdrawn(_beneficiary, balance);
    }
}"},"ERC1538Delegate.sol":{"content":"pragma solidity 0.4.24;
import "./IERC1538.sol";
import "./ERC1538QueryDelegates.sol";

/******************************************************************************\
* Implementation of ERC1538.
* Function signatures are stored in an array so functions can be queried.
/******************************************************************************/

contract ERC1538Delegate is IERC1538, ERC1538QueryDelegates {

    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external onlyOwner {
        // pos is first used to check the size of the delegate contract.
        // After that pos is the current memory location of _functionSignatures.
        // It is used to move through the characters of _functionSignatures
        uint256 pos;
        if(_delegate != address(0)) {
            assembly {
                pos := extcodesize(_delegate)
            }
            require(pos > 0, "_delegate address is not a contract and is not address(0)");
        }
        // creates a bytes vesion of _functionSignatures
        bytes memory signatures = bytes(_functionSignatures);
        // stores the position in memory where _functionSignatures ends.
        uint256 signaturesEnd;
        // stores the starting position of a function signature in _functionSignatures
        uint256 start;
        assembly {
            pos := add(signatures,32)
            start := pos
            signaturesEnd := add(pos,mload(signatures))
        }
        // the function id of the current function signature
        bytes4 funcId;
        // the delegate address that is being replaced or address(0) if removing functions
        address oldDelegate;
        // the length of the current function signature in _functionSignatures
        uint256 num;
        // the current character in _functionSignatures
        uint256 char;
        // the position of the current function signature in the funcSignatures array
        uint256 index;
        // the last position in the funcSignatures array
        uint256 lastIndex;
        // parse the _functionSignatures string and handle each function
        for (; pos < signaturesEnd; pos++) {
            assembly {char := byte(0,mload(pos))}
            // 0x29 == )
            if (char == 0x29) {
                pos++;
                num = (pos - start);
                start = pos;
                assembly {
                    mstore(signatures,num)
                }
                funcId = bytes4(keccak256(signatures));
                oldDelegate = delegates[funcId];
                if(_delegate == address(0)) {
                    index = funcSignatureToIndex[signatures];
                    require(index != 0, "Function does not exist.");
                    index--;
                    lastIndex = funcSignatures.length - 1;
                    if (index != lastIndex) {
                        funcSignatures[index] = funcSignatures[lastIndex];
                        funcSignatureToIndex[funcSignatures[lastIndex]] = index + 1;
                    }
                    funcSignatures.length--;
                    delete funcSignatureToIndex[signatures];
                    delete delegates[funcId];
                    emit FunctionUpdate(funcId, oldDelegate, address(0), string(signatures));
                }
                else if (funcSignatureToIndex[signatures] == 0) {
                    require(oldDelegate == address(0), "Funcion id clash.");
                    delegates[funcId] = _delegate;
                    funcSignatures.push(signatures);
                    funcSignatureToIndex[signatures] = funcSignatures.length;
                    emit FunctionUpdate(funcId, address(0), _delegate, string(signatures));
                }
                else if (delegates[funcId] != _delegate) {
                    delegates[funcId] = _delegate;
                    emit FunctionUpdate(funcId, oldDelegate, _delegate, string(signatures));

                }
                assembly {signatures := add(signatures,num)}
            }
        }
        emit CommitMessage(commitMessage);
    }
}"},"ERC1538QueryDelegates.sol":{"content":"pragma solidity 0.4.24;
/******************************************************************************\
* 
* Contains functions for retrieving function signatures and delegate contract
* addresses.
/******************************************************************************/

import "./StorageV0.sol";
import "./IERC1538Query.sol";

contract ERC1538QueryDelegates is IERC1538Query, StorageV0 {

    function totalFunctions() external view returns(uint256) {
        return funcSignatures.length;
    }

    function functionByIndex(uint256 _index) external view returns(string memory functionSignature, bytes4 functionId, address delegate) {
        require(_index < funcSignatures.length, "functionSignatures index does not exist.");
        bytes memory signature = funcSignatures[_index];
        functionId = bytes4(keccak256(signature));
        delegate = delegates[functionId];
        return (string(signature), functionId, delegate);
    }

    function functionExists(string _functionSignature) external view returns(bool) {
        return funcSignatureToIndex[bytes(_functionSignature)] != 0;
    }

    function functionSignatures() external view returns(string) {
        uint256 signaturesLength;
        bytes memory signatures;
        bytes memory signature;
        uint256 functionIndex;
        uint256 charPos;
        uint256 funcSignaturesNum = funcSignatures.length;
        bytes[] memory memoryFuncSignatures = new bytes[](funcSignaturesNum);
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = funcSignatures[functionIndex];
            signaturesLength += signature.length;
            memoryFuncSignatures[functionIndex] = signature;
        }
        signatures = new bytes(signaturesLength);
        functionIndex = 0;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = memoryFuncSignatures[functionIndex];
            for(uint256 i = 0; i < signature.length; i++) {
                signatures[charPos] = signature[i];
                charPos++;
            }
        }
        return string(signatures);
    }

    function delegateFunctionSignatures(address _delegate) external view returns(string) {
        uint256 funcSignaturesNum = funcSignatures.length;
        bytes[] memory delegateSignatures = new bytes[](funcSignaturesNum);
        uint256 delegateSignaturesPos;
        uint256 signaturesLength;
        bytes memory signatures;
        bytes memory signature;
        uint256 functionIndex;
        uint256 charPos;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            signature = funcSignatures[functionIndex];
            if(_delegate == delegates[bytes4(keccak256(signature))]) {
                signaturesLength += signature.length;
                delegateSignatures[delegateSignaturesPos] = signature;
                delegateSignaturesPos++;
            }

        }
        signatures = new bytes(signaturesLength);
        functionIndex = 0;
        for(; functionIndex < delegateSignatures.length; functionIndex++) {
            signature = delegateSignatures[functionIndex];
            if(signature.length == 0) {
                break;
            }
            for(uint256 i = 0; i < signature.length; i++) {
                signatures[charPos] = signature[i];
                charPos++;
            }
        }
        return string(signatures);
    }

    function delegateAddress(string _functionSignature) external view returns(address) {
        require(funcSignatureToIndex[bytes(_functionSignature)] != 0, "Function signature not found.");
        return delegates[bytes4(keccak256(bytes(_functionSignature)))];
    }

    function functionById(bytes4 _functionId) external view returns(string signature, address delegate) {
        for(uint256 i = 0; i < funcSignatures.length; i++) {
            if(_functionId == bytes4(keccak256(funcSignatures[i]))) {
                return (string(funcSignatures[i]), delegates[_functionId]);
            }
        }
        revert("functionId not found");
    }

    function delegateAddresses() external view returns(address[]) {
        uint256 funcSignaturesNum = funcSignatures.length;
        address[] memory delegatesBucket = new address[](funcSignaturesNum);
        uint256 numDelegates;
        uint256 functionIndex;
        bool foundDelegate;
        address delegate;
        for(; functionIndex < funcSignaturesNum; functionIndex++) {
            delegate = delegates[bytes4(keccak256(funcSignatures[functionIndex]))];
            for(uint256 i = 0; i < numDelegates; i++) {
                if(delegate == delegatesBucket[i]) {
                    foundDelegate = true;
                    break;
                }
            }
            if(foundDelegate == false) {
                delegatesBucket[numDelegates] = delegate;
                numDelegates++;
            }
            else {
                foundDelegate = false;
            }
        }
        address[] memory delegates_ = new address[](numDelegates);
        functionIndex = 0;
        for(; functionIndex < numDelegates; functionIndex++) {
            delegates_[functionIndex] = delegatesBucket[functionIndex];
        }
        return delegates_;
    }
}"},"Game.sol":{"content":"pragma solidity 0.4.24;
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./CashBack.sol";
import "./Utils.sol";

contract Game is PaintDiscount, PaintsPool, CashBack {
    using SafeMath for uint;

    // set new value of priceLimitPaints
    function setPriceLimitPaints(uint _paintsNumber) external onlyAdmin() {
        priceLimitPaints = _paintsNumber;
    }

    // function estimating call price for given color
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {
        uint moneySpent = moneySpentByUser[msg.sender];
        bool hasDiscount = hasPaintDiscount[msg.sender];
        uint discount = usersPaintDiscount[msg.sender];

        // next paint number
        uint curPaintNum = totalPaintsForRound[currentRound] + 1;

        // external call â add extra paints
        if (!isPaintCall) {
            curPaintNum += priceLimitPaints;
        }

        uint curPrice = _getPaintPrice(curPaintNum);  // price for next painting without discount
        uint price = curPrice;  // price for next painting

        for (uint i = 0; i < _pixels.length; i++) {
            if (hasDiscount) {
                price = curPrice.mul(100 - discount).div(100); // discount call price
            }

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                hasDiscount = true;
                discount = moneySpent / 1 ether;

                if (moneySpent >= 10 ether) {
                    discount = 10;
                }
            }
        }

    }

    function drawTimeBank() public {
        uint curRound = currentRound;
        uint lastPaintTime = lastPaintTimeForRound[curRound];
        require ((now - lastPaintTime) > 20 minutes && lastPaintTime > 0, "20 minutes have not passed yet.");

        address winner = lastPainterForRound[curRound];
        uint curTbIter = tbIteration;
        uint prize = timeBankForRound[curRound].mul(90).div(100);  // 90% of time bank goes to winner;

        winnerOfRound[curRound] = winner;  // set winner of round
        winnerBankForRound[curRound] = 1;  // timebank(1) was drawn for this round
        timeBankForRound[curRound + 1] = timeBankForRound[curRound].div(10);  // 10% of time bank goes to next round
        timeBankForRound[curRound] = prize;

        colorBankForRound[curRound + 1] = colorBankForRound[curRound];  // color bank goes to next round
        colorBankForRound[curRound] = 0;

        // change global state - new game
        currentRound = curRound.add(1);
        tbIteration = curTbIter.add(1);
        _resetPaintsPool();

        // transfer time bank to winner
        winner.transfer(prize);
        emit TimeBankWithdrawn(curRound, curTbIter, winner, prize);
    }

    function paint(uint[] _pixels, uint _color, string _refLink) external payable isRegistered(_refLink) isLiveGame() {
        require (_pixels.length >= 1 && _pixels.length <= 15, "The number of pixels should be from 1 to 15 pixels");
        require(_color > 0 && _color <= totalColorsNumber, "The color with such id does not exist.");

        // drawTimeBank call and exit if 20 minutes passed since last paint
        if ((now - lastPaintTimeForRound[currentRound]) > 20 minutes &&
            lastPaintTimeForRound[currentRound] > 0) {

            drawTimeBank();
            msg.sender.transfer(msg.value);
            return;
        }

        // call estimateCallPrice from paint function
        isPaintCall = true;
        uint callPrice = estimateCallPrice(_pixels, _color);
        isPaintCall = false;

        require(msg.value >= callPrice, "Wrong call price â insufficient funds");

        // Add remaining money
        if (msg.value - callPrice > 0) {
            uint remainingMoney = msg.value - callPrice;
            // Update cashback amount for msg.sender
            cashBackCalculated[msg.sender] = cashBackCalculated[msg.sender].add(remainingMoney);
        }

        // distribute money to banks, cashBack and dividends
        if (totalPaintsForRound[currentRound] == 0) {
            // need for first cashback distribution to first painter
            totalPaintsForRound[currentRound] = _pixels.length;
            userPaintsForRound[currentRound][msg.sender] = _pixels.length;
            _setBanks(_color, _refLink, callPrice);
        } else {
            // for other cases â distribute cashback to prev painters
            _setBanks(_color, _refLink, callPrice);
            totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(_pixels.length);
            userPaintsForRound[currentRound][msg.sender] = userPaintsForRound[currentRound][msg.sender].add(_pixels.length);
        }

        colorToTotalPaintsForCBIteration[cbIteration][_color] = colorToTotalPaintsForCBIteration[cbIteration][_color].add(_pixels.length);

        //paint pixels
        for (uint i = 0; i < _pixels.length; i++) {
            _paint(_pixels[i], _color);
        }

        // save user spended money for this color
        _setMoneySpentByUserForColor(_color);

        _setUsersPaintDiscountForColor(_color);

        if (paintsCounterForColor[_color] == 0) {
            paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] = now;
        }

        paintsCounter++; //counter for all users paints
        paintsCounterForColor[_color]++; //counter for given color
        counterToPainter[paintsCounter] = msg.sender; //counter for given user
        counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender;

        if (isUserCountedForRound[currentRound][msg.sender] == false) {
            usersCounterForRound[currentRound] = usersCounterForRound[currentRound].add(1);
            isUserCountedForRound[currentRound][msg.sender] = true;
        }

        // check the winning in color bank
        if (winnerBankForRound[currentRound] == 2) {
            _drawColorBank();
        }
    }

    function _paint(uint _pixel, uint _color) internal {
        //set paints amount in a pool and price for paint
        _fillPaintsPool(_color);

        require(msg.sender == tx.origin, "Can not be a contract");
        require(_pixel > 0 && _pixel <= totalPixelsNumber, "The pixel with such id does not exist.");

        uint oldColor = pixelToColorForRound[currentRound][_pixel];

        pixelToColorForRound[currentRound][_pixel] = _color; // save old color for pixel
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; // set new color for pixel

        lastPaintTimeForRound[currentRound] = now;
        lastPainterForRound[currentRound] = msg.sender;

        // decrease number of old color pixels
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) {
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1);
        }

        // increase number of new color pixels
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1);

        pixelToPaintTimeForRound[currentRound][_pixel] = now;

        lastPaintTimeOfUser[msg.sender] = now;
        lastPaintTimeOfUserForColor[_color][msg.sender] = now;

        // decrease paints pool by 1
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);

        lastPaintedPixelForRound[currentRound] = _pixel;
        lastPlayedRound[msg.sender] = currentRound;

        emit Paint(_pixel, _color, msg.sender, currentRound, now);

        // check wherether all pixels are the same color
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == totalPixelsNumber) {
            winnerColorForRound[currentRound] = _color;
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];

            // color bank is 2
            winnerBankForRound[currentRound] = 2;

            // 10% of colorbank goes to next round
            colorBankForRound[currentRound + 1] = colorBankForRound[currentRound].div(10);

            // 90% of colorbank for winner
            colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(90).div(100);

            //timebank goes to next round
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];
            timeBankForRound[currentRound] = 0;
        }
    }

    function _setBanks(uint _color, string _refLink, uint _callPrice) private {
        bytes32 refLink32 = Utils.toBytes16(_refLink);

        uint valueToTimeBank = _callPrice.mul(40).div(100);  // 40% to TimeBank
        uint valueToColorBank = _callPrice.div(10);  // 10% to ColorBank
        uint valueToLuckyPot = _callPrice.div(20);  // 5% to LuckyPot
        uint valueGameFee = _callPrice.div(20);  // 5% Game Fee to Founders
        uint valueRef = _callPrice.div(20);  // 5% to Referrer
        uint valueCashBack = _callPrice.mul(35).div(100);  // 35% CashBack (+ valueRef without Referrer)

        // reflink provided
        if (refLinkExists[refLink32]) {
            pendingWithdrawals[refLinkToUser[refLink32]] = pendingWithdrawals[refLinkToUser[refLink32]].add(valueRef);
            _distributeCashBack(valueCashBack);  // CashBack with Refferer
        } else {
            _distributeCashBack(valueCashBack + valueRef);  // CashBack without Refferer
        }

        // set bank states
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(valueToTimeBank);
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(valueToColorBank);
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(valueToColorBank);
        luckyPotBank = luckyPotBank.add(valueToLuckyPot);
        pendingWithdrawals[founders] = pendingWithdrawals[founders].add(valueGameFee);
    }

    function _drawColorBank() private {
        uint curRound = currentRound;
        uint curCbIter = cbIteration;
        address winner = winnerOfRound[curRound];
        uint prize = colorBankForRound[curRound];

        // change global state - new game
        currentRound = curRound.add(1);
        cbIteration = curCbIter.add(1);
        _resetPaintsPool();

        // transfer color bank to winner
        winner.transfer(prize);
        emit ColorBankWithdrawn(curRound, curCbIter, winner, prize);
    }

    function _resetPaintsPool() private {
        uint firstPaintGenForColor = 1;

        for (uint i = 1; i <= totalColorsNumber; i++){
            callPriceForColor[i] = 0.005 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            currentPaintGenForColor[i] = firstPaintGenForColor;

            paintGenToAmountForColor[i][firstPaintGenForColor] = maxPaintsInPool;
            paintGenStartedForColor[i][firstPaintGenForColor] = true;
            paintGenToStartTimeForColor[i][firstPaintGenForColor] = now;
        }
    }

    modifier isRegistered(string _refLink) {

        if (isRegisteredUser[msg.sender] != true) {
            bytes32 refLink32 = Utils.toBytes16(_refLink);

            if (refLinkExists[refLink32]) {
                address referrer = refLinkToUser[refLink32];
                referrerToReferrals[referrer].push(msg.sender);
                referralToReferrer[msg.sender] = referrer;
                hasReferrer[msg.sender] = true;
            }
            uniqueUsersCount = uniqueUsersCount.add(1);
            newUserToCounter[msg.sender] = uniqueUsersCount;
            registrationTimeForUser[msg.sender] = now;
            isRegisteredUser[msg.sender] = true;
        }
        _;
    }

    function _getPaintPrice(uint _number) private pure returns (uint) {
        uint paintPrice = uint((int(_sqrt(_number * 22222222 + 308641358025)) - 7777777)*1e18 / 12345678 + 0.589996*1e18);
        uint temp = 1e13;  // for round - 10^-5
        return ((paintPrice + temp - 1) / temp) * temp;
    }

    // gives square root of given x.
    function _sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}"},"GameStateController.sol":{"content":"pragma solidity 0.4.24;
import "./Roles.sol";
import "./Modifiers.sol";

contract GameStateController is Modifiers {

    function pauseGame() external onlyAdmin() {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin() {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }

    function withdrawEther() external onlyAdmin() returns (bool) {
        require (isGamePaused == true, "Can withdraw when game is live");
        uint balance = address(this).balance;
        uint colorBank = colorBankForRound[currentRound];
        uint timeBank = timeBankForRound[currentRound];
        owner().transfer(balance);
        colorBankForRound[currentRound]= 0;
        timeBankForRound[currentRound]= 0;
        emit EtherWithdrawn(balance, colorBank, timeBank, now);
        return true;
    }
    
}
"},"Helpers.sol":{"content":"pragma solidity 0.4.24;
import "./Modifiers.sol";

contract Helpers is Modifiers {

    function getUsername(address _painter) external view returns(string username) {
        username = addressToUsername[_painter];
    }

    function isUsernameExists(string _username) external view returns(bool) {
        return usernameExists[_username];
    }

    // username lenght 1-16 symbols
    function createUsername(string _username) external isValidUsername(_username) {
        require(!usernameExists[_username], "This username already exists, try different one.");
        require(bytes(addressToUsername[msg.sender]).length == 0, "You have already created your username.");

        addressToUsername[msg.sender] = _username;
        usernameExists[_username] = true;

        emit UsernameCreated(msg.sender, _username);
    }

    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }

    //function adding new color to the game after minting
    function addNewColor() external onlyAdmin() {
        totalColorsNumber++; 
        currentPaintGenForColor[totalColorsNumber] = 1;
        callPriceForColor[totalColorsNumber] = 0.01 ether;
        nextCallPriceForColor[totalColorsNumber] = callPriceForColor[totalColorsNumber];
        paintGenToAmountForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = maxPaintsInPool;
        paintGenStartedForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = true;
        paintGenToEndTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber] - 1] = now;
        paintGenToStartTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = now;
    }

}"},"IColor.sol":{"content":"pragma solidity 0.4.24;

interface Color {
    function totalSupply() external view returns (uint);
    function ownerOf(uint _tokenId) external view returns (address);
}

"},"IERC1538.sol":{"content":"pragma solidity 0.4.24;

interface IERC1538 {
    event CommitMessage(string message);
    event FunctionUpdate(bytes4 indexed functionId, address indexed oldDelegate, address indexed newDelegate, string functionSignature);
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external;
}"},"IERC1538Query.sol":{"content":"pragma solidity 0.4.24;

interface IERC1538Query {
    function totalFunctions() external view returns(uint256);
    function functionByIndex(uint256 _index) external view returns(string memory functionSignature, bytes4 functionId, address delegate);
    function functionExists(string _functionSignature) external view returns(bool);
    function functionSignatures() external view returns(string);
    function delegateFunctionSignatures(address _delegate) external view returns(string);
    function delegateAddress(string _functionSignature) external view returns(address);
    function functionById(bytes4 _functionId) external view returns(string signature, address delegate);
    function delegateAddresses() external view returns(address[]);
}"},"Initializer.sol":{"content":"pragma solidity 0.4.24;
import "./StorageV1.sol";

contract Initializer is StorageV1 {

    //constructor
    function _initializer() internal {
        totalColorsNumber = 8;
        totalPixelsNumber = 49;

        isAdmin[msg.sender] = true;
        maxPaintsInPool = totalPixelsNumber;
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;

        priceLimitPaints = 100;

        for (uint i = 1; i <= totalColorsNumber; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.005 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
        }
        
    }
}
"},"IPixel.sol":{"content":"pragma solidity 0.4.24;

interface Pixel {
    function totalSupply() external view returns (uint);
    function ownerOf(uint _tokenId) external view returns (address);
}

"},"LuckyPot.sol":{"content":"pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract LuckyPot is Modifiers {
    using SafeMath for uint;

    function increaseLuckyPot() external payable {
        require(msg.value != 0, "msg.value is 0");
        luckyPotBank = luckyPotBank.add(msg.value);
    }

    function drawLuckyPot(address _user, uint _bankPercent, uint _pixelId) external onlyAdmin() {
        require(luckyPotBank > 0, "luckyPotBank is empty");
        require(_bankPercent > 0 && _bankPercent <= 100, "Invalid percent");
        require(_pixelId > 0 && _pixelId <= totalPixelsNumber, "The pixel with such id does not exist.");

        uint luckyPotBankAmountForWinner = luckyPotBank.mul(_bankPercent).div(100);

        // change luckyPotBank state
        luckyPotBank = luckyPotBank.sub(luckyPotBankAmountForWinner);
        luckyPotBankWinner[_user] = true;

        // transfer luckypot
        _user.transfer(luckyPotBankAmountForWinner);
        emit LuckyPotDrawn(_pixelId, _user, luckyPotBankAmountForWinner);
    }
}"},"Migrations.sol":{"content":"pragma solidity ^0.4.23;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
"},"Modifiers.sol":{"content":"pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract Modifiers is StorageV1 {
    using SafeMath for uint;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin rights.");
        _;
    }

    modifier isLiveGame() {
        require(isGamePaused == false, "Game is paused.");
        _;
    }

    // should be 4-8 symbols
    modifier isValidRefLink(string _str) {
        require(bytes(_str).length >= 4, "Ref link should be of length [4,8]");
        require(bytes(_str).length <= 8, "Ref link should be of length [4,8]");
        _;
    }

    // should be 1-16 symbols
    modifier isValidUsername(string _str) {
        require(bytes(_str).length >= 1, "Name should be of length [1,16]");
        require(bytes(_str).length <= 16, "Name should be of length [1,16]");
        _;
    }

}"},"Ownable.sol":{"content":"pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
"},"PaintDiscount.sol":{"content":"pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintDiscount is StorageV1 {
    using SafeMath for uint;

    // saving discount for user
    function _setUsersPaintDiscountForColor(uint _color) internal {

        //each 1 eth = 1% discount
        usersPaintDiscount[msg.sender] = moneySpentByUser[msg.sender] / 1 ether; // for all colors
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether; // for current color

        //max discount 10% for all colors
        if (moneySpentByUser[msg.sender] >= 10 ether) {
            usersPaintDiscount[msg.sender] = 10;
        }

        //max discount 10% for current color
        if (moneySpentByUserForColor[_color][msg.sender] >= 10 ether) {
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        }
    }

    //  Money spent by user buying this color
    function _setMoneySpentByUserForColor(uint _color) internal {

        moneySpentByUser[msg.sender] += msg.value; // for all colors
        moneySpentByUserForColor[_color][msg.sender] += msg.value; // for current color

        // for all colors
        if (moneySpentByUser[msg.sender] >= 1 ether) {
            hasPaintDiscount[msg.sender] = true;
        }

        // for current color
        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether) {
            hasPaintDiscountForColor[_color][msg.sender] = true;
        }
    }
}"},"PaintsPool.sol":{"content":"pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintsPool is StorageV1 {
    using SafeMath for uint;

    //update paint price
    function _updateCallPrice(uint _color) private {
        
        //increase call price for 5%(for frontend)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        
        emit CallPriceUpdated(callPriceForColor[_color]);
    }
     
    
    
    function _fillPaintsPool(uint _color) internal {

        
        uint nextPaintGen = currentPaintGenForColor[_color].add(1);
        //each 5 min we produce new paint generation
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 5 minutes) { 
            
            
            uint paintsRemain = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]]; 
            
            //if 5 min passed and new gen not yet started     
            if (paintGenStartedForColor[_color][nextPaintGen] == false) {
                
                //we create new gen with amount of paints remaining 
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                
                paintGenToStartTimeForColor[_color][nextPaintGen] = now; 

                paintGenStartedForColor[_color][nextPaintGen] = true;
            }
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 1) {
                
                
                _updateCallPrice(_color);
                
                //current gen paiints ends now 
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;
            }
               
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
               
                callPriceForColor[_color] = nextCallPriceForColor[_color];

                if (paintGenToAmountForColor[_color][nextPaintGen] == 0) {
                    paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                }
                //now we use next gen paints
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
        ///if 5 min not yet passed
        else {

            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
               
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                //we use next paint gen
                currentPaintGenForColor[_color] = nextPaintGen;
            }

        }
    }
}"},"Referral.sol":{"content":"pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";
import "./Utils.sol";

contract Referral is Modifiers {
    using SafeMath for uint;

    // ref link lenght 4-8 symbols
    function createRefLink(string _refLink) external isValidRefLink(_refLink) {
        require(!hasRefLink[msg.sender], "You have already generated your ref link.");
        bytes32 refLink32 = Utils.toBytes16(_refLink);
        require(!refLinkExists[refLink32], "This referral link already exists, try different one.");
        hasRefLink[msg.sender] = true;
        userToRefLink[msg.sender] = _refLink;
        refLinkExists[refLink32] = true;
        refLinkToUser[refLink32] = msg.sender;
    }

    function getReferralsForUser(address _user) external view returns (address[]) {
        return referrerToReferrals[_user];
    }

    function getReferralData(address _user) external view returns (uint registrationTime, uint moneySpent) {
        registrationTime = registrationTimeForUser[_user];
        moneySpent = moneySpentByUser[_user];
    }
}"},"Roles.sol":{"content":"pragma solidity 0.4.24;
import "./Modifiers.sol";

contract Roles is Modifiers {
    
    function addAdmin(address _new) external onlyOwner() {
        isAdmin[_new] = true;
    }
    
    function removeAdmin(address _admin) external onlyOwner() {
        isAdmin[_admin] = false;
    }

    function renounceAdmin() external onlyAdmin() {
        isAdmin[msg.sender] = false;
    }

}"},"Router.sol":{"content":"pragma solidity 0.4.24;
pragma experimental "v0.5.0";
import "./Initializer.sol";

contract Router is Initializer {
    
    event CommitMessage(string message);
    event FunctionUpdate(bytes4 indexed functionId, address indexed oldDelegate, address indexed newDelegate, string functionSignature);

    constructor(address _erc1538Delegate) public  {

        //Adding ERC1538 updateContract function
        bytes memory signature = "updateContract(address,string,string)";
        bytes4 funcId = bytes4(keccak256(signature));
        delegates[funcId] = _erc1538Delegate;
        funcSignatures.push(signature);
        funcSignatureToIndex[signature] = funcSignatures.length;
        emit FunctionUpdate(funcId, address(0), _erc1538Delegate, string(signature));
        emit CommitMessage("Added ERC1538 updateContract function at contract creation");
    
        _initializer();
    }

    function() external payable {
        address delegate = delegates[msg.sig];
        require(delegate != address(0), "Function does not exist.");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, delegate, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {revert(ptr, size)}
            default {return (ptr, size)}
        }
    }
}"},"SafeMath.sol":{"content":"pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}"},"StorageV0.sol":{"content":"pragma solidity 0.4.24;
import "./Ownable.sol";

contract StorageV0 is Ownable {

    // maps functions to the delegate contracts that execute the functions
    // funcId => delegate contract
    mapping(bytes4 => address) internal delegates;

    // array of function signatures supported by the contract
    bytes[] internal funcSignatures;

    // maps each function signature to its position in the funcSignatures array.
    // signature => index+1
    mapping(bytes => uint256) internal funcSignatureToIndex;

}"},"StorageV1.sol":{"content":"pragma solidity 0.4.24;
import "./StorageV0.sol";
import "./IColor.sol";
import "./IPixel.sol";

contract StorageV1 is StorageV0 {

    //pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound;

    //old pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound;

    // (round => color => pixel amount)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound;

    //color bank for round (round => color bank)
    mapping (uint => uint) public colorBankForRound;

    //color bank for  color for round (round => color => color bank)
    mapping (uint => mapping (uint => uint)) public colorBankToColorForRound;

    //time bank for round (round => time bank)
    mapping (uint => uint) public timeBankForRound;

    // (round => timestamp)
    mapping (uint => uint) public lastPaintTimeForRound;

    // (round => adress)
    mapping (uint => address) public lastPainterForRound;

    // (round => pixel)
    mapping (uint => uint) public lastPaintedPixelForRound;

    // (round => color)
    mapping (uint => uint) public winnerColorForRound;

    // (round => color => paints amount)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForCBIteration;

    // (round => adress)
    mapping (uint => address) public winnerOfRound;

    //bank drawn in round (round => drawn bank) (1 = time bank, 2 = color bank)
    mapping (uint => uint) public winnerBankForRound;

    // (round => pixel => timestamp)
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;


    // number of paints for paint price limit
    uint public priceLimitPaints;

    // is paint function call â for paint price limit logic
    bool public isPaintCall;


    // (round => paints number)
    mapping (uint => uint) public totalPaintsForRound;

    // (round => address => paints number)
    mapping (uint => mapping (address => uint)) public userPaintsForRound;


    // total cashback for round (round => total cashback)
    mapping (uint => uint) public totalCashBackForRound;

    // max cashback since the beginning of the round (round => cashback per paint)
    mapping (uint => uint) public maxCashBackPerPaintForRound;

    // cashback per painter for round in time of painter's last paint (round => painter's address => cashback per paint)
    mapping (uint => mapping (address => uint)) public cashBackPerPaintForRound;

    // unwithdrawn cashback + remaining money from paints (address => cashback per painter)
    mapping (address => uint) public cashBackCalculated;

    // last cashback calculation round in cashBackCalculated (address => round)
    mapping (address => uint) public cashBackCalculationRound;


    mapping (uint => mapping (uint => uint)) public paintGenToAmountForColor;
    mapping (uint => mapping (uint => uint)) public paintGenToStartTimeForColor;
    mapping (uint => mapping (uint => uint)) public paintGenToEndTimeForColor;
    mapping (uint => mapping (uint => bool)) public paintGenStartedForColor;
    mapping (uint => uint) public currentPaintGenForColor;
    mapping (uint => uint) public callPriceForColor;
    mapping (uint => uint) public nextCallPriceForColor;


    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;
    mapping (address => uint) public moneySpentByUser;


    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    mapping (address => bool) public hasPaintDiscount;
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;  //in percent
    mapping (address => uint) public usersPaintDiscount;  //in percent



    mapping (address => uint) public registrationTimeForUser;
    mapping (address => bool) public isRegisteredUser;


    mapping (address => bool) public hasRefLink;
    mapping (address => address) public referralToReferrer;
    mapping (address => address[]) public referrerToReferrals;
    mapping (address => bool) public hasReferrer;
    mapping (address => string) public userToRefLink;
    mapping (bytes32 => address) public refLinkToUser;
    mapping (bytes32 => bool) public refLinkExists;
    mapping (address => uint) public newUserToCounter;


    mapping (address => string) public addressToUsername;
    mapping (string => bool) internal usernameExists;  // not public â string accessor


    mapping(address => bool)  public luckyPotBankWinner;
    uint public luckyPotBank;


    uint public uniqueUsersCount;

    uint public maxPaintsInPool;

    uint public currentRound;

    //time bank iteration
    uint public tbIteration;

   //color bank iteration
    uint public cbIteration;


    uint public paintsCounter;
    mapping (uint => uint) public paintsCounterForColor;


    // (counter => user)
    mapping (uint => address) public counterToPainter;

    // (color => counter => user)
    mapping (uint => mapping (uint => address)) public counterToPainterForColor;

    mapping (address => uint) public lastPlayedRound;


    // For dividends distribution
    mapping (address => uint) public pendingWithdrawals;

    // (adress => time)
    mapping (address => uint) public addressToLastWithdrawalTime;


    address public founders = 0xe04f921cf3d6c882C0FAa79d0810a50B1101e2D4;


    bool public isGamePaused;

    mapping(address => bool) public isAdmin;

    Color public colorInstance;
    Pixel public pixelInstance;

    uint public totalColorsNumber; // 8
    uint public totalPixelsNumber; //225 in V1


    mapping (address => uint) public lastPaintTimeOfUser;
    mapping (uint => mapping (address => uint)) public lastPaintTimeOfUserForColor;


    mapping (uint => uint) public usersCounterForRound;
    mapping (uint => mapping (address => bool)) public isUserCountedForRound;


    // ***** Events *****

    event ColorBankWithdrawn(uint indexed round, uint indexed cbIteration, address indexed winnerOfRound, uint prize);
    event TimeBankWithdrawn(uint indexed round, uint indexed tbIteration, address indexed winnerOfRound, uint prize);
    event Paint(uint indexed pixelId, uint colorId, address indexed painter, uint indexed round, uint timestamp);
    event CallPriceUpdated(uint indexed newCallPrice);
    event EtherWithdrawn(uint balance, uint colorBank, uint timeBank, uint timestamp);
    event LuckyPotDrawn(uint pixelId, address indexed winnerOfLuckyPot, uint prize);
    event CashBackWithdrawn(uint indexed round, address indexed withdrawer, uint cashback);
    event DividendsWithdrawn(address indexed withdrawer, uint withdrawalAmount);
    event UsernameCreated(address indexed user, string username);
}"},"Utils.sol":{"content":"pragma solidity 0.4.24;

library Utils {
    
    // convert a string less than 32 characters long to bytes32
    function toBytes16(string _string) pure internal returns (bytes16) {
        // make sure that the string isn't too long for this function
        // will work but will cut off the any characters past the 32nd character
        bytes16 _stringBytes;
        string memory str = _string;
    
        // simplest way to convert 32 character long string
        assembly {
          // load the memory pointer of string with an offset of 32
          // 32 passes over non-core data parts of string such as length of text
          _stringBytes := mload(add(str, 32))
        }
        return _stringBytes;
    }

    
    
}"},"Wrapper.sol":{"content":"pragma solidity 0.4.24;
import "./Modifiers.sol";

/**
** Wrapper for Router Contract to interact with all the functions' signatures
**/

contract Wrapper is Modifiers {

    //DividendsDistributor.sol
    function withdrawDividends() external returns (bool) {}
    function withdrawFoundersComission() external returns (bool) {}

    //LuckyPot
    function increaseLuckyPot() external payable {}
    function drawLuckyPot(address _user, uint _bankPercent, uint _pixelId) external {}

    //GameStateController.sol
    function pauseGame() external {}
    function resumeGame() external {}
    function withdrawEther() external returns (bool) {}

    //Referral.sol
    function createRefLink(string _refLink) external {}
    function getReferralsForUser(address _user) external view returns (address[]) {}
    function getReferralData(address _user) external view returns (uint registrationTime, uint moneySpent) {}

    //Roles.sol
    function addAdmin(address _new) external {}
    function removeAdmin(address _admin) external {}
    function renounceAdmin() external {}

    //Game.sol
    function setPriceLimitPaints(uint _paintsNumber) external {}
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {}
    function paint(uint[] _pixels, uint _color, string _refLink) external payable {}
    function drawTimeBank() public {}
    function cashBackAmount(address _painter) public view returns(uint cashBackInWei) {}
    function withdrawCashBack() external {}

    //ERC1538.sol
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external {}

    //GameMock.sol
    function mock() external {}
    function mock2() external {}
    function mock3(uint _winnerColor) external {}
    function mockMaxPaintsInPool() external {}

    //Helpers.sol
    function getUsername(address _painter) external view returns(string username) {}
    function isUsernameExists(string _username) external view returns(bool) {}
    function createUsername(string _username) external {}
    function getPixelColor(uint _pixel) external view returns (uint) {}
    function addNewColor() external {}

}"}}