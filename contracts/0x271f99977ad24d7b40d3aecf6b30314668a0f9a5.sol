{"IBancorNetwork.sol":{"content":"pragma solidity 0.5.11;

import "./IERC20.sol";

contract IBancorNetwork {
    // to get rate, return dest amount + fee amount
    function getReturnByPath(IERC20[] calldata _path, uint256 _amount) external view returns (uint256, uint256);
    // to convert ETH to token, return dest amount
    function convert2(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);

    // to convert token to ETH, return dest amount
    function claimAndConvert2(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external returns (uint256);
}
"},"IERC20.sol":{"content":"pragma solidity 0.5.11;


interface IERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
"},"IKyberReserve.sol":{"content":"pragma solidity 0.5.11;

import "./IERC20.sol";


/// @title Kyber Reserve contract
interface IKyberReserve {

    function trade(
        IERC20 srcToken,
        uint srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        external
        payable
        returns(bool);

    function getConversionRate(IERC20 src, IERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}
"},"KyberBancorReserve.sol":{"content":"pragma solidity 0.5.11;

import "./IERC20.sol";
import "./IKyberReserve.sol";
import "./WithdrawableV5.sol";
import "./UtilsV5.sol";
import "./IBancorNetwork.sol";

contract KyberBancorReserve is IKyberReserve, Withdrawable, Utils {

    uint constant internal BPS = 10000; // 10^4
    uint constant ETH_BNT_DECIMALS = 18;

    address public kyberNetwork;
    bool public tradeEnabled;
    uint public feeBps;

    IBancorNetwork public bancorNetwork; // 0x3ab6564d5c214bc416ee8421e05219960504eead

    // IERC20 public bancorEth; // 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315
    // IERC20 public bancorETHBNT; // 0xb1CD6e4153B2a390Cf00A6556b0fC1458C4A5533
    IERC20 public bancorToken; // 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C
    IERC20[] public ethToBntPath;
    IERC20[] public bntToEthPath;

    constructor(
        address _bancorNetwork,
        address _kyberNetwork,
        uint _feeBps,
        address _bancorToken,
        address _admin
    )
        public
    {
        require(_bancorNetwork != address(0), "constructor: bancorNetwork address is missing");
        require(_kyberNetwork != address(0), "constructor: kyberNetwork address is missing");
        require(_bancorToken != address(0), "constructor: bancorToken address is missing");
        require(_admin != address(0), "constructor: admin address is missing");
        require(_feeBps < BPS, "constructor: fee is too big");

        bancorNetwork = IBancorNetwork(_bancorNetwork);
        bancorToken = IERC20(_bancorToken);
        tradeEnabled = true;

        require(bancorToken.approve(address(bancorNetwork), 2 ** 255));
    }

    function() external payable { }

    function getConversionRate(IERC20 src, IERC20 dest, uint srcQty, uint) public view returns(uint) {
        if (!tradeEnabled) { return 0; }
        if (srcQty == 0) { return 0; }

        if (src != ETH_TOKEN_ADDRESS && dest != ETH_TOKEN_ADDRESS) {
            return 0; // either src or dest must be ETH
        }
        IERC20 token = src == ETH_TOKEN_ADDRESS ? dest : src;
        if (token != bancorToken) { return 0; } // not BNT token

        IERC20[] memory path = getConversionPath(src, dest);

        uint destQty;
        (destQty, ) = bancorNetwork.getReturnByPath(path, srcQty);

        // src and dest can be only BNT or ETH
        uint rate = calcRateFromQty(srcQty, destQty, ETH_BNT_DECIMALS, ETH_BNT_DECIMALS);

        rate = valueAfterReducingFee(rate);

        return rate;
    }

    event TradeExecute(
        address indexed sender,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address payable destAddress
    );

    function trade(
        IERC20 srcToken,
        uint srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool)
    {

        require(tradeEnabled, "trade: trade is not enabled");
        require(msg.sender == kyberNetwork, "trade: sender is not network");
        require(srcAmount > 0, "trade: src amount must be greater than 0");
        require(srcToken == ETH_TOKEN_ADDRESS || destToken == ETH_TOKEN_ADDRESS, "trade: src or dest must be ETH");
        require(srcToken == bancorToken || destToken == bancorToken, "trade: src or dest must be BNT");

        require(doTrade(srcToken, srcAmount, destToken, destAddress, conversionRate, validate), "trade: doTrade function returns false");

        return true;
    }

    event KyberNetworkSet(address kyberNetwork);

    function setKyberNetwork(address _kyberNetwork) public onlyAdmin {
        require(_kyberNetwork != address(0), "setKyberNetwork: kyberNetwork address is missing");

        kyberNetwork = _kyberNetwork;
        emit KyberNetworkSet(_kyberNetwork);
    }

    event BancorNetworkSet(address _bancorNetwork);

    function setBancorContract(address _bancorNetwork) public onlyAdmin {
        require(_bancorNetwork != address(0), "setBancorContract: bancorNetwork address is missing");

        if (address(bancorNetwork) != address(0)) {
            require(bancorToken.approve(address(bancorNetwork), 0), "setBancorContract: can not reset approve token");
        }
        bancorNetwork = IBancorNetwork(_bancorNetwork);
        require(bancorToken.approve(address(bancorNetwork), 2 ** 255), "setBancorContract: can not approve token");

        emit BancorNetworkSet(_bancorNetwork);
    }

    event FeeBpsSet(uint feeBps);

    function setFeeBps(uint _feeBps) public onlyAdmin {
        require(_feeBps < BPS, "setFeeBps: feeBps >= BPS");

        feeBps = _feeBps;
        emit FeeBpsSet(feeBps);
    }

    event TradeEnabled(bool enable);

    function enableTrade() public onlyAdmin returns(bool) {
        tradeEnabled = true;
        emit TradeEnabled(true);

        return true;
    }

    event NewPathsSet(IERC20[] ethToBntPath, IERC20[] bntToEthPath);

    function setNewEthBntPath(IERC20[] memory _ethToBntPath, IERC20[] memory _bntToEthPath) public onlyAdmin {
        require(_ethToBntPath.length != 0, "setNewEthBntPath: path should have some elements");
        require(_bntToEthPath.length != 0, "setNewEthBntPath: path should have some elements");
        ethToBntPath = _ethToBntPath;
        bntToEthPath = _bntToEthPath;
        emit NewPathsSet(_ethToBntPath, _bntToEthPath);
    }

    function disableTrade() public onlyAlerter returns(bool) {
        tradeEnabled = false;
        emit TradeEnabled(false);

        return true;
    }

    function doTrade(
        IERC20 srcToken,
        uint srcAmount,
        IERC20 destToken,
        address payable destAddress,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        // can skip validation if done at kyber network level
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount, "doTrade: msg value is not correct for ETH trade");
            else
                require(msg.value == 0, "doTrade: msg value is not correct for token trade");
        }

        if (srcToken != ETH_TOKEN_ADDRESS) {
            // collect source amount
            require(srcToken.transferFrom(msg.sender, address(this), srcAmount), "doTrade: collect src token failed");
        }

        IERC20[] memory path = getConversionPath(srcToken, destToken);
        require(path.length > 0, "doTrade: couldn't find path");

        // BNT and ETH have the same decimals
        uint userExpectedDestAmount = calcDstQty(srcAmount, ETH_BNT_DECIMALS, ETH_BNT_DECIMALS, conversionRate);
        require(userExpectedDestAmount > 0, "doTrade: user expected amount must be greater than 0");
        uint destAmount;

        if (srcToken == ETH_TOKEN_ADDRESS) {
            destAmount = bancorNetwork.convert2.value(srcAmount)(path, srcAmount, userExpectedDestAmount, address(0), 0);
        } else {
            destAmount = bancorNetwork.claimAndConvert2(path, srcAmount, userExpectedDestAmount, address(0), 0);
        }

        require(destAmount >= userExpectedDestAmount, "doTrade: dest amount is lower than expected amount");

        // transfer back only expected dest amount
        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(userExpectedDestAmount);
        } else {
            require(destToken.transfer(destAddress, userExpectedDestAmount), "doTrade: transfer back dest token failed");
        }

        emit TradeExecute(msg.sender, address(srcToken), srcAmount, address(destToken), userExpectedDestAmount, destAddress);
        return true;
    }

    function getConversionPath(IERC20 src, IERC20 dest) public view returns(IERC20[] memory path) {
        if (src == bancorToken) {
            path = bntToEthPath;
        } else if (dest == bancorToken) {
            path = ethToBntPath;
        }
        return path;
    }

    function valueAfterReducingFee(uint val) internal view returns(uint) {
        require(val <= MAX_QTY, "valueAfterReducingFee: val > MAX_QTY");
        return ((BPS - feeBps) * val) / BPS;
    }
}
"},"PermissionGroupsV5.sol":{"content":"pragma solidity 0.5.11;


contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) internal operators;
    mapping(address=>bool) internal alerters;
    address[] internal operatorsGroup;
    address[] internal alertersGroup;
    uint constant internal MAX_GROUP_SIZE = 50;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    function getOperators () external view returns(address[] memory) {
        return operatorsGroup;
    }

    function getAlerters () external view returns(address[] memory) {
        return alertersGroup;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        require(alertersGroup.length < MAX_GROUP_SIZE);

        emit AlerterAdded(newAlerter, true);
        alerters[newAlerter] = true;
        alertersGroup.push(newAlerter);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;

        for (uint i = 0; i < alertersGroup.length; ++i) {
            if (alertersGroup[i] == alerter) {
                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];
                alertersGroup.length--;
                emit AlerterAdded(alerter, false);
                break;
            }
        }
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE);

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;

        for (uint i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.length -= 1;
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}
"},"UtilsV5.sol":{"content":"pragma solidity 0.5.11;

import "./IERC20.sol";


/// @title Kyber utils and utils2 contracts
contract Utils {

    IERC20 constant internal ETH_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;

    mapping(address=>uint) internal decimals;

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(IERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function setDecimals(IERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS)
            decimals[address(token)] = ETH_DECIMALS;
        else
            decimals[address(token)] = token.decimals();
    }

    function getDecimals(IERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[address(token)];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if (tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcDestAmount(IERC20 src, IERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(IERC20 src, IERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }

    function minOf(uint x, uint y) internal pure returns(uint) {
        return x > y ? y : x;
    }
}
"},"WithdrawableV5.sol":{"content":"pragma solidity 0.5.11;

import "./IERC20.sol";
import "./PermissionGroupsV5.sol";


contract Withdrawable is PermissionGroups {

    event TokenWithdraw(IERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all IERC20 compatible tokens
     * @param token IERC20 The address of the token contract
     */
    function withdrawToken(IERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address payable sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}
"}}