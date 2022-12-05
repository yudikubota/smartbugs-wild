{{
  "language": "Solidity",
  "sources": {
    "contracts/BentoBox.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

// The BentoBox

//  ââââÂ· âââ . â â âââââ      ââââÂ·       âââ¢ â 
//  ââ âââªââ.âÂ·â¢âââââ¢ââ  âª     ââ âââªâª      âââââª
//  ââââââââââªââââââ ââ.âª ââââ ââââââ ââââ  Â·ââÂ· 
//  ââââªââââââââââââ âââÂ·âââ.ââââââªâââââ.âââªââÂ·ââ
//  Â·ââââ  âââ ââ ââª âââ  âââââªÂ·ââââ  âââââªâ¢ââ ââ

// This contract stores funds, handles their transfers.

// Copyright (c) 2020 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// WARNING!!! DO NOT USE!!! BEING AUDITED!!!

// solhint-disable no-inline-assembly
// solhint-disable avoid-low-level-calls
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./libraries/BoringMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IMasterContract.sol";
import "./Ownable.sol";

contract BentoBox is Ownable{
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool indexed approved);
    event LogDeposit(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);
    event LogWithdraw(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);
    event LogTransfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    mapping(address => address) public masterContractOf; // Mapping from clone contracts to their masterContract
    mapping(address => mapping(address => bool)) public masterContractApproved; // masterContract to user to approval state
    mapping(IERC20 => mapping(address => uint256)) public balanceOf; // Balance per token per address/contract
    mapping(IERC20 => uint256) public totalSupply;
    // solhint-disable-next-line var-name-mixedcase
    IERC20 public immutable WethToken;

    mapping(address => uint256) public nonces;

    mapping(address => bool) public whitelistedMasterContracts;

    // solhint-disable-next-line var-name-mixedcase
    constructor(IERC20 WethToken_) public {
        WethToken = WethToken_;
    }

    // Deploys a given master Contract as a clone.
    function deploy(address masterContract, bytes calldata data) external {
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        address cloneAddress; // Address where the clone contract will reside.

        // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneAddress := create(0, clone, 0x37)
        }
        masterContractOf[cloneAddress] = masterContract;

        IMasterContract(cloneAddress).init(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }

    function domainSeparator() public view returns (bytes32) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return keccak256(abi.encode(keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"), "BentoBox V1", chainId, address(this)));
    }

    // *** Public actions *** //
    function whitelistMasterContract(address masterContract, bool approved) external onlyOwner{
        whitelistedMasterContracts[masterContract] = approved;
    }

    function setMasterContractApprovalFallback(address masterContract, bool approved) external {
        require(masterContract != address(0), "BentoBox: masterContract not set"); // Important for security
        require(whitelistedMasterContracts[masterContract], "BentoBox: not whitelisted");
        masterContractApproved[masterContract][msg.sender] = approved;
        emit LogSetMasterContractApproval(masterContract, msg.sender, approved);
    }

    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external {
        require(user != address(0), "BentoBox: User cannot be 0");
        require(masterContract != address(0), "BentoBox: masterContract not set"); // Important for security

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01", domainSeparator(),
            keccak256(abi.encode(
                // keccak256("SetMasterContractApproval(string warning,address user,address masterContract,bool approved,uint256 nonce)");
                0x1962bc9f5484cb7a998701b81090e966ee1fce5771af884cceee7c081b14ade2,
                approved ? "Give FULL access to funds in (and approved to) BentoBox?" : "Revoke access to BentoBox?",
                user, masterContract, approved, nonces[user]++
            ))
        ));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == user, "BentoBox: Invalid Signature");

        masterContractApproved[masterContract][user] = approved;
        emit LogSetMasterContractApproval(masterContract, user, approved);
    }

    modifier allowed(address from) {
        require(msg.sender == from || masterContractApproved[masterContractOf[msg.sender]][from], "BentoBox: Transfer not approved");
        _;
    }

    function permit(IERC20 token, address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        token.permit(from, address(this), amount, deadline, v, r, s);
    }

    function deposit(IERC20 token, address from, uint256 amount) external payable { depositTo(token, from, msg.sender, amount); }
    function depositTo(IERC20 token, address from, address to, uint256 amount) public payable allowed(from) {
        _deposit(token, from, to, amount);
    }

    function withdraw(IERC20 token, address to, uint256 amount) external { withdrawFrom(token, msg.sender, to, amount); }
    function withdrawFrom(IERC20 token, address from, address to, uint256 amount) public allowed(from) {
        _withdraw(token, from, to, amount);
    }

    // *** Approved contract actions *** //
    // Clones of master contracts can transfer from any account that has approved them
    function transfer(IERC20 token, address to, uint256 amount) external { transferFrom(token, msg.sender, to, amount); }
    function transferFrom(IERC20 token, address from, address to, uint256 amount) public allowed(from) {
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds
        balanceOf[token][from] = balanceOf[token][from].sub(amount);
        balanceOf[token][to] = balanceOf[token][to].add(amount);

        emit LogTransfer(token, from, to, amount);
    }

    function transferMultiple(IERC20 token, address[] calldata tos, uint256[] calldata amounts) external
    {
        transferMultipleFrom(token, msg.sender, tos, amounts);
    }
    function transferMultipleFrom(IERC20 token, address from, address[] calldata tos, uint256[] calldata amounts) public allowed(from) {
        require(tos[0] != address(0), "BentoBox: to[0] not set"); // To avoid a bad UI from burning funds
        uint256 totalAmount;
        for (uint256 i=0; i < tos.length; i++) {
            address to = tos[i];
            balanceOf[token][to] = balanceOf[token][to].add(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            emit LogTransfer(token, from, to, amounts[i]);
        }
        balanceOf[token][from] = balanceOf[token][from].sub(totalAmount);
    }

    function skim(IERC20 token) external returns (uint256 amount) { amount = skimTo(token, msg.sender); }
    function skimTo(IERC20 token, address to) public returns (uint256 amount) {
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds
        amount = token.balanceOf(address(this)).sub(totalSupply[token]);
        balanceOf[token][to] = balanceOf[token][to].add(amount);
        totalSupply[token] = totalSupply[token].add(amount);
        emit LogDeposit(token, address(this), to, amount);
    }

    function skimETH() external returns (uint256 amount) { amount = skimETHTo(msg.sender); }
    function skimETHTo(address to) public returns (uint256 amount) {
        IWETH(address(WethToken)).deposit{value: address(this).balance}();
        amount = skimTo(WethToken, to);
    }

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, "BentoBox: Transaction failed");
            successes[i] = success;
            results[i] = result;
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // *** Private functions *** //
    function _deposit(IERC20 token, address from, address to, uint256 amount) private {
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds
        balanceOf[token][to] = balanceOf[token][to].add(amount);
        uint256 supply = totalSupply[token];
        totalSupply[token] = supply.add(amount);

        if (address(token) == address(WethToken)) {
            IWETH(address(WethToken)).deposit{value: amount}();
        } else {
            if (supply == 0) { // During the first deposit, we check that this token is 'real'
                require(token.totalSupply() > 0, "BentoBox: No tokens");
            }
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "BentoBox: TransferFrom failed");
        }
        emit LogDeposit(token, from, to, amount);
    }

    function _withdraw(IERC20 token, address from, address to, uint256 amount) private {
        require(to != address(0), "BentoBox: to not set"); // To avoid a bad UI from burning funds
        balanceOf[token][from] = balanceOf[token][from].sub(amount);
        totalSupply[token] = totalSupply[token].sub(amount);
        if (address(token) == address(WethToken)) {
            IWETH(address(WethToken)).withdraw(amount);
            (bool success,) = to.call{value: amount}(new bytes(0));
            require(success, "BentoBox: ETH transfer failed");
        } else {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "BentoBox: Transfer failed");
        }
        emit LogWithdraw(token, from, to, amount);
    }
}
"
    },
    "contracts/libraries/BoringMath.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}"
    },
    "contracts/interfaces/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // non-standard
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}"
    },
    "contracts/interfaces/IWETH.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}
"
    },
    "contracts/interfaces/IMasterContract.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterContract {
    function init(bytes calldata data) external;
}"
    },
    "contracts/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function transferOwnershipDirect(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, "Ownable: caller != pending owner");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}"
    },
    "contracts/mocks/OwnableMock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "../Ownable.sol";

contract OwnableMock is Ownable {}
"
    },
    "contracts/LendingPair.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

// Medium Risk LendingPair

// âââ  âââ . â â Â·ââââ  âª   â â  ââ â¢  âââÂ· âââÂ· âª  âââ
// âââ¢  ââ.âÂ·â¢âââââââª ââ ââ â¢ââââââ â âªââ ââââ ââ ââ ââ âÂ·
// âââª  ââââªââââââââÂ· âââââÂ·âââââââ âââ âââÂ·âââââ ââÂ·ââââ
// âââââââââââââââââ. ââ ââââââââââââªâââââªÂ·â¢ââ âªââââââââ¢ââ
// .âââ  âââ ââ ââªââââââ¢ âââââ ââªÂ·ââââ .â    â  â âââ.â  â

// Copyright (c) 2020 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @burger_crypto - for the idea of trying to let the LPs benefit from liquidations

// WARNING!!! DO NOT USE!!! BEING AUDITED!!!

// solhint-disable avoid-low-level-calls

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/BoringMath.sol";
import "./interfaces/IOracle.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./interfaces/IMasterContract.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IWETH.sol";

// TODO: check all reentrancy paths
// TODO: what to do when the entire pool is underwater?
// TODO: check that all actions on a users funds can only be initiated by that user as msg.sender

contract LendingPair is ERC20, Ownable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    // MasterContract variables
    IBentoBox public immutable bentoBox;
    LendingPair public immutable masterContract;
    address public feeTo;
    address public dev;
    mapping(ISwapper => bool) public swappers;

    // Per clone variables
    // Clone settings
    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;
    bytes public oracleData;

    // User balances
    mapping(address => uint256) public userCollateralAmount;
    // userAssetFraction is called balanceOf for ERC20 compatibility
    mapping(address => uint256) public userBorrowFraction;

    struct TokenTotals {
        uint128 amount;
        uint128 fraction;
    }

    // Total amounts
    uint256 public totalCollateralAmount;
    TokenTotals public totalAsset; // The total assets belonging to the suppliers (including any borrowed amounts).
    TokenTotals public totalBorrow; // Total units of asset borrowed

    // totalSupply for ERC20 compatibility
    function totalSupply() public view returns(uint256) {
        return totalAsset.fraction;
    }

    // Exchange and interest rate tracking
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 interestPerBlock;
        uint64 lastBlockAccrued;
        uint128 feesPendingAmount;
    }
    AccrueInfo public accrueInfo;

    // ERC20 'variables'
    function symbol() public view returns(string memory) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x95d89b41));
        string memory assetSymbol = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        (success, data) = address(collateral).staticcall(abi.encodeWithSelector(0x95d89b41));
        string memory collateralSymbol = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        return string(abi.encodePacked("bm", collateralSymbol, ">", assetSymbol, "-", oracle.symbol(oracleData)));
    }

    function name() public view returns(string memory) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x06fdde03));
        string memory assetName = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        (success, data) = address(collateral).staticcall(abi.encodeWithSelector(0x06fdde03));
        string memory collateralName = success && data.length > 0 ? abi.decode(data, (string)) : "???";

        return string(abi.encodePacked("Bento Med Risk ", collateralName, ">", assetName, "-", oracle.symbol(oracleData)));
    }

    function decimals() public view returns (uint8) {
        (bool success, bytes memory data) = address(asset).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint256 accruedAmount, uint256 feeAmount, uint256 rate, uint256 utilization);
    event LogAddCollateral(address indexed user, uint256 amount);
    event LogAddAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogAddBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveCollateral(address indexed user, uint256 amount);
    event LogRemoveAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogFeeTo(address indexed newFeeTo);
    event LogDev(address indexed newDev);
    event LogWithdrawFees();

    constructor(IBentoBox bentoBox_) public {
        bentoBox = bentoBox_;
        masterContract = LendingPair(this);
        dev = msg.sender;
        feeTo = msg.sender;
        emit LogDev(msg.sender);
        emit LogFeeTo(msg.sender);

        // Not really an issue, but https://blog.trailofbits.com/2020/12/16/breaking-aave-upgradeability/
        collateral = IERC20(address(1));
    }

    // Settings for the Medium Risk LendingPair
    uint256 private constant CLOSED_COLLATERIZATION_RATE = 75000; // 75%
    uint256 private constant OPEN_COLLATERIZATION_RATE = 77000; // 77%
    uint256 private constant MINIMUM_TARGET_UTILIZATION = 7e17; // 70%
    uint256 private constant MAXIMUM_TARGET_UTILIZATION = 8e17; // 80%

    uint256 private constant STARTING_INTEREST_PER_BLOCK = 4566210045; // approx 1% APR
    uint256 private constant MINIMUM_INTEREST_PER_BLOCK = 1141552511; // approx 0.25% APR
    uint256 private constant MAXIMUM_INTEREST_PER_BLOCK = 4566210045000;  // approx 1000% APR
    uint256 private constant INTEREST_ELASTICITY = 2000e36; // Half or double in 2000 blocks (approx 8 hours)

    uint256 private constant LIQUIDATION_MULTIPLIER = 112000; // add 12%

    // Fees
    uint256 private constant PROTOCOL_FEE = 10000; // 10%
    uint256 private constant DEV_FEE = 10000; // 10% of the PROTOCOL_FEE = 1%
    uint256 private constant BORROW_OPENING_FEE = 50; // 0.05%

    // Serves as the constructor, as clones can't have a regular constructor
    function init(bytes calldata data) public override {
        require(address(collateral) == address(0), "LendingPair: already initialized");
        (collateral, asset, oracle, oracleData) = abi.decode(data, (IERC20, IERC20, IOracle, bytes));

        accrueInfo.interestPerBlock = uint64(STARTING_INTEREST_PER_BLOCK);  // 1% APR, with 1e18 being 100%
        updateExchangeRate();
    }

    function getInitData(IERC20 collateral_, IERC20 asset_, IOracle oracle_, bytes calldata oracleData_) public pure returns(bytes memory data) {
        return abi.encode(collateral_, asset_, oracle_, oracleData_);
    }

    function setApproval(address user, bool approved, uint8 v, bytes32 r, bytes32 s) external {
        bentoBox.setMasterContractApproval(user, address(masterContract), approved, v, r, s);
    }

    function permitToken(IERC20 token, address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        bentoBox.permit(token, from, amount, deadline, v, r, s);
    }

    // Accrues the interest on the borrowed tokens and handles the accumulation of fees
    function accrue() public {
        AccrueInfo memory info = accrueInfo;
        // Number of blocks since accrue was called
        uint256 blocks = block.number - info.lastBlockAccrued;
        if (blocks == 0) {return;}
        info.lastBlockAccrued = uint64(block.number);

        uint256 extraAmount = 0;
        uint256 feeAmount = 0;

        TokenTotals memory _totalBorrow = totalBorrow;
        TokenTotals memory _totalAsset = totalAsset;
        if (_totalBorrow.amount > 0) {
            // Accrue interest
            extraAmount = uint256(_totalBorrow.amount).mul(info.interestPerBlock).mul(blocks) / 1e18;
            feeAmount = extraAmount.mul(PROTOCOL_FEE) / 1e5; // % of interest paid goes to fee
            _totalBorrow.amount = _totalBorrow.amount.add(extraAmount.to128());
            totalBorrow = _totalBorrow;
            _totalAsset.amount = _totalAsset.amount.add(extraAmount.sub(feeAmount).to128());
            totalAsset = _totalAsset;
            info.feesPendingAmount = info.feesPendingAmount.add(feeAmount.to128());
        }

        if (_totalAsset.amount == 0) {
            if (info.interestPerBlock != STARTING_INTEREST_PER_BLOCK) {
                info.interestPerBlock = uint64(STARTING_INTEREST_PER_BLOCK);
                emit LogAccrue(extraAmount, feeAmount, STARTING_INTEREST_PER_BLOCK, 0);
            }
            accrueInfo = info; return;
        }

        // Update interest rate
        uint256 utilization = uint256(_totalBorrow.amount).mul(1e18) / _totalAsset.amount;
        uint256 newInterestPerBlock;
        if (utilization < MINIMUM_TARGET_UTILIZATION) {
            uint256 underFactor = MINIMUM_TARGET_UTILIZATION.sub(utilization).mul(1e18) / MINIMUM_TARGET_UTILIZATION;
            uint256 scale = INTEREST_ELASTICITY.add(underFactor.mul(underFactor).mul(blocks));
            newInterestPerBlock = uint256(info.interestPerBlock).mul(INTEREST_ELASTICITY) / scale;
            if (newInterestPerBlock < MINIMUM_INTEREST_PER_BLOCK) {newInterestPerBlock = MINIMUM_INTEREST_PER_BLOCK;} // 0.25% APR minimum
       } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
            uint256 overFactor = utilization.sub(MAXIMUM_TARGET_UTILIZATION).mul(1e18) / uint256(1e18).sub(MAXIMUM_TARGET_UTILIZATION);
            uint256 scale = INTEREST_ELASTICITY.add(overFactor.mul(overFactor).mul(blocks));
            newInterestPerBlock = uint256(info.interestPerBlock).mul(scale) / INTEREST_ELASTICITY;
            if (newInterestPerBlock > MAXIMUM_INTEREST_PER_BLOCK) {newInterestPerBlock = MAXIMUM_INTEREST_PER_BLOCK;} // 1000% APR maximum
        } else {
            emit LogAccrue(extraAmount, feeAmount, info.interestPerBlock, utilization);
            accrueInfo = info; return;
        }

        info.interestPerBlock = uint64(newInterestPerBlock);
        emit LogAccrue(extraAmount, feeAmount, newInterestPerBlock, utilization);
        accrueInfo = info;
    }

    // Checks if the user is solvent.
    // Has an option to check if the user is solvent in an open/closed liquidation case.
    function isSolvent(address user, bool open) public view returns (bool) {
        // accrue must have already been called!
        if (userBorrowFraction[user] == 0) return true;
        if (totalCollateralAmount == 0) return false;

        TokenTotals memory _totalBorrow = totalBorrow;

        return userCollateralAmount[user].mul(1e13).mul(open ? OPEN_COLLATERIZATION_RATE : CLOSED_COLLATERIZATION_RATE)
            >= userBorrowFraction[user].mul(_totalBorrow.amount).mul(exchangeRate) / _totalBorrow.fraction;
    }

    function peekExchangeRate() public view returns (bool, uint256) {
        return oracle.peek(oracleData);
    }

    // Gets the exchange rate. How much collateral to buy 1e18 asset.
    function updateExchangeRate() public returns (uint256) {
        (bool success, uint256 rate) = oracle.get(oracleData);

        // TODO: How to deal with unsuccessful fetch
        if (success) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        }
        return exchangeRate;
    }

    // Handles internal variable updates when collateral is deposited
    function _addCollateralAmount(address user, uint256 amount) private {
        // Adds this amount to user
        userCollateralAmount[user] = userCollateralAmount[user].add(amount);
        // Adds the amount deposited to the total of collateral
        totalCollateralAmount = totalCollateralAmount.add(amount);
        emit LogAddCollateral(msg.sender, amount);
    }

    // Handles internal variable updates when supply (the borrowable token) is deposited
    function _addAssetAmount(address user, uint256 amount) private {
        TokenTotals memory _totalAsset = totalAsset;
        // Calculates what amount of the pool the user gets for the amount deposited
        uint256 newFraction = _totalAsset.amount == 0 ? amount : amount.mul(_totalAsset.fraction) / _totalAsset.amount;
        // Adds this amount to user
        balanceOf[user] = balanceOf[user].add(newFraction);
        // Adds this amount to the total of supply amounts
        _totalAsset.fraction = _totalAsset.fraction.add(newFraction.to128());
        // Adds the amount deposited to the total of supply
        _totalAsset.amount = _totalAsset.amount.add(amount.to128());
        totalAsset = _totalAsset;
        emit LogAddAsset(msg.sender, amount, newFraction);
    }

    // Handles internal variable updates when supply (the borrowable token) is borrowed
    function _addBorrowAmount(address user, uint256 amount) private {
        TokenTotals memory _totalBorrow = totalBorrow;
        // Calculates what amount of the borrowed funds the user gets for the amount borrowed
        uint256 newFraction = _totalBorrow.amount == 0 ? amount : amount.mul(_totalBorrow.fraction) / _totalBorrow.amount;
        // Adds this amount to the user
        userBorrowFraction[user] = userBorrowFraction[user].add(newFraction);
        // Adds amount borrowed to the total amount borrowed
        _totalBorrow.fraction = _totalBorrow.fraction.add(newFraction.to128());
        // Adds amount borrowed to the total amount borrowed
        _totalBorrow.amount = _totalBorrow.amount.add(amount.to128());
        totalBorrow = _totalBorrow;
        emit LogAddBorrow(msg.sender, amount, newFraction);
    }

    // Handles internal variable updates when collateral is withdrawn and returns the amount of collateral withdrawn
    function _removeCollateralAmount(address user, uint256 amount) private {
        // Subtracts the amount from user
        userCollateralAmount[user] = userCollateralAmount[user].sub(amount);
        // Subtracts the amount from the total of collateral
        totalCollateralAmount = totalCollateralAmount.sub(amount);
        emit LogRemoveCollateral(msg.sender, amount);
    }

    // Handles internal variable updates when supply is withdrawn and returns the amount of supply withdrawn
    function _removeAssetFraction(address user, uint256 fraction) private returns (uint256 amount) {
        TokenTotals memory _totalAsset = totalAsset;
        // Subtracts the fraction from user
        balanceOf[user] = balanceOf[user].sub(fraction);
        // Calculates the amount of tokens to withdraw
        amount = fraction.mul(_totalAsset.amount) / _totalAsset.fraction;
        // Subtracts the calculated fraction from the total of supply
        _totalAsset.fraction = _totalAsset.fraction.sub(fraction.to128());
        // Subtracts the amount from the total of supply amounts
        _totalAsset.amount = _totalAsset.amount.sub(amount.to128());
        totalAsset = _totalAsset;
        emit LogRemoveAsset(msg.sender, amount, fraction);
    }

    // Handles internal variable updates when supply is repaid
    function _removeBorrowFraction(address user, uint256 fraction) private returns (uint256 amount) {
        TokenTotals memory _totalBorrow = totalBorrow;
        // Subtracts the fraction from user
        userBorrowFraction[user] = userBorrowFraction[user].sub(fraction);
        // Calculates the amount of tokens to repay
        amount = fraction.mul(_totalBorrow.amount) / _totalBorrow.fraction;
        // Subtracts the fraction from the total of amounts borrowed
        _totalBorrow.fraction = _totalBorrow.fraction.sub(fraction.to128());
        // Subtracts the calculated amount from the total amount borrowed
        _totalBorrow.amount = _totalBorrow.amount.sub(amount.to128());
        totalBorrow = _totalBorrow;
        emit LogRemoveBorrow(msg.sender, amount, fraction);
    }

    // Deposits an amount of collateral from the caller
    function addCollateral(uint256 amount, bool useBento) public payable { addCollateralTo(amount, msg.sender, useBento); }
    function addCollateralTo(uint256 amount, address to, bool useBento) public payable {
        _addCollateralAmount(to, amount);
        useBento 
            ? bentoBox.transferFrom(collateral, msg.sender, address(this), amount)
            : bentoBox.deposit{value: msg.value}(collateral, msg.sender, amount);
    }

    // Deposits an amount of supply (the borrowable token) from the caller
    function addAsset(uint256 amount, bool useBento) public payable { addAssetTo(amount, msg.sender, useBento); }
    function addAssetTo(uint256 amount, address to, bool useBento) public payable {
        // Accrue interest before calculating pool amounts in _addAssetAmount
        accrue();
        _addAssetAmount(to, amount);
        useBento ? bentoBox.transferFrom(asset, msg.sender, address(this), amount) : bentoBox.deposit{value: msg.value}(asset, msg.sender, amount);
    }

    // Withdraws a amount of collateral of the caller to the specified address
    function removeCollateral(uint256 amount, address to, bool useBento) public {
        accrue();
        _removeCollateralAmount(msg.sender, amount);
        // Only allow withdrawing if user is solvent (in case of a closed liquidation)
        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
        useBento ? bentoBox.transfer(collateral, to, amount) : bentoBox.withdraw(collateral, to, amount);
    }

    // Withdraws a amount of supply (the borrowable token) of the caller to the specified address
    function removeAsset(uint256 fraction, address to, bool useBento) public {
        // Accrue interest before calculating pool amounts in _removeAssetFraction
        accrue();
        uint256 amount = _removeAssetFraction(msg.sender, fraction);
        useBento ? bentoBox.transfer(asset, to, amount) : bentoBox.withdraw(asset, to, amount);
    }

    // Borrows the given amount from the supply to the specified address
    function borrow(uint256 amount, address to, bool useBento) public {
        accrue();
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / 1e5; // A flat % fee is charged for any borrow
        _addBorrowAmount(msg.sender, amount.add(feeAmount));
        totalAsset.amount = totalAsset.amount.add(feeAmount.to128());
        useBento ? bentoBox.transfer(asset, to, amount) : bentoBox.withdraw(asset, to, amount);
        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }

    // Repays the given fraction
    function repay(uint256 fraction, bool useBento) public { repayFor(fraction, msg.sender, useBento); }
    function repayFor(uint256 fraction, address beneficiary, bool useBento) public {
        accrue();
        uint256 amount = _removeBorrowFraction(beneficiary, fraction);
        useBento ? bentoBox.transferFrom(asset, msg.sender, address(this), amount) : bentoBox.deposit(asset, msg.sender, amount);
    }

    // Handles shorting with an approved swapper
    function short(ISwapper swapper, uint256 assetAmount, uint256 minCollateralAmount) public {
        require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");
        accrue();
        _addBorrowAmount(msg.sender, assetAmount);
        bentoBox.transferFrom(asset, address(this), address(swapper), assetAmount);

        // Swaps the borrowable asset for collateral
        swapper.swap(asset, collateral, assetAmount, minCollateralAmount);
        uint256 returnedCollateralAmount = bentoBox.skim(collateral); // TODO: Reentrancy issue? Should we take a before and after balance?
        require(returnedCollateralAmount >= minCollateralAmount, "LendingPair: not enough");
        _addCollateralAmount(msg.sender, returnedCollateralAmount);

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }

    // Handles unwinding shorts with an approved swapper
    function unwind(ISwapper swapper, uint256 borrowFraction, uint256 maxAmountCollateral) public {
        require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");
        accrue();
        bentoBox.transferFrom(collateral, address(this), address(swapper), maxAmountCollateral);

        uint256 borrowAmount = _removeBorrowFraction(msg.sender, borrowFraction);

        // Swaps the collateral back for the borrowal asset
        uint256 usedAmount = swapper.swapExact(collateral, asset, maxAmountCollateral, borrowAmount, address(this));
        uint256 returnedAssetAmount = bentoBox.skim(asset); // TODO: Reentrancy issue? Should we take a before and after balance?
        require(returnedAssetAmount >= borrowAmount, "LendingPair: Not enough");

        _removeCollateralAmount(msg.sender, maxAmountCollateral.sub(usedAmount));

        require(isSolvent(msg.sender, false), "LendingPair: user insolvent");
    }

    // Handles the liquidation of users' balances, once the users' amount of collateral is too low
    function liquidate(address[] calldata users, uint256[] calldata borrowFractions, address to, ISwapper swapper, bool open) public {
        accrue();
        updateExchangeRate();

        uint256 allCollateralAmount = 0;
        uint256 allBorrowAmount = 0;
        uint256 allBorrowFraction = 0;
        TokenTotals memory _totalBorrow = totalBorrow;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!isSolvent(user, open)) {
                // Gets the user's amount of the total borrowed amount
                uint256 borrowFraction = borrowFractions[i];
                // Calculates the user's amount borrowed
                uint256 borrowAmount = borrowFraction.mul(_totalBorrow.amount) / _totalBorrow.fraction;
                // Calculates the amount of collateral that's going to be swapped for the asset
                uint256 collateralAmount = borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(exchangeRate) / 1e23;

                // Removes the amount of collateral from the user's balance
                userCollateralAmount[user] = userCollateralAmount[user].sub(collateralAmount);
                // Removes the amount of user's borrowed tokens from the user
                userBorrowFraction[user] = userBorrowFraction[user].sub(borrowFraction);
                emit LogRemoveCollateral(user, collateralAmount);
                emit LogRemoveBorrow(user, borrowAmount, borrowFraction);

                // Keep totals
                allCollateralAmount = allCollateralAmount.add(collateralAmount);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowFraction = allBorrowFraction.add(borrowFraction);
            }
        }
        require(allBorrowAmount != 0, "LendingPair: all are solvent");
        _totalBorrow.amount = _totalBorrow.amount.sub(allBorrowAmount.to128());
        _totalBorrow.fraction = _totalBorrow.fraction.sub(allBorrowFraction.to128());
        totalBorrow = _totalBorrow;
        totalCollateralAmount = totalCollateralAmount.sub(allCollateralAmount);

        if (!open) {
            // Closed liquidation using a pre-approved swapper for the benefit of the LPs
            require(masterContract.swappers(swapper), "LendingPair: Invalid swapper");

            // Swaps the users' collateral for the borrowed asset
            bentoBox.transferFrom(collateral, address(this), address(swapper), allCollateralAmount);
            swapper.swap(collateral, asset, allCollateralAmount, allBorrowAmount);
            uint256 returnedAssetAmount = bentoBox.skim(asset); // TODO: Reentrancy issue? Should we take a before and after balance?
            uint256 extraAssetAmount = returnedAssetAmount.sub(allBorrowAmount);

            // The extra asset gets added to the pool
            uint256 feeAmount = extraAssetAmount.mul(PROTOCOL_FEE) / 1e5; // % of profit goes to fee
            accrueInfo.feesPendingAmount = accrueInfo.feesPendingAmount.add(feeAmount.to128());
            totalAsset.amount = totalAsset.amount.add(extraAssetAmount.sub(feeAmount).to128());
            emit LogAddAsset(address(0), extraAssetAmount, 0);
        } else if (address(swapper) == address(0)) {
            // Open liquidation directly using the caller's funds, without swapping using token transfers
            bentoBox.deposit(asset, msg.sender, allBorrowAmount);
            bentoBox.withdraw(collateral, to, allCollateralAmount);
        } else if (address(swapper) == address(1)) {
            // Open liquidation directly using the caller's funds, without swapping using funds in BentoBox
            bentoBox.transferFrom(asset, msg.sender, address(this), allBorrowAmount);
            bentoBox.transfer(collateral, to, allCollateralAmount);
        } else {
            // Swap using a swapper freely chosen by the caller
            // Open (flash) liquidation: get proceeds first and provide the borrow after
            bentoBox.transferFrom(collateral, address(this), address(swapper), allCollateralAmount);
            swapper.swap(collateral, asset, allCollateralAmount, allBorrowAmount);
            uint256 returnedAssetAmount = bentoBox.skim(asset); // TODO: Reentrancy issue? Should we take a before and after balance?
            uint256 extraAssetAmount = returnedAssetAmount.sub(allBorrowAmount);

            totalAsset.amount = totalAsset.amount.add(extraAssetAmount.to128());
            emit LogAddAsset(address(0), extraAssetAmount, 0);
        }
    }

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory, bytes[] memory) {
        bool[] memory successes = new bool[](calls.length);
        bytes[] memory results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, "LendingPair: Transaction failed");
            successes[i] = success;
            results[i] = result;
        }
        return (successes, results);
    }

    // Withdraws the fees accumulated
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        address _dev = masterContract.dev();
        uint256 feeAmount = accrueInfo.feesPendingAmount.sub(1);
        uint256 devFeeAmount = _dev == address(0) ? 0 : feeAmount.mul(DEV_FEE) / 1e5;
        accrueInfo.feesPendingAmount = 1; // Don't set it to 0 as that would increase the gas cost for the next accrue called by a user.
        bentoBox.withdraw(asset, _feeTo, feeAmount.sub(devFeeAmount));
        if (devFeeAmount > 0) {
            bentoBox.withdraw(asset, _dev, devFeeAmount);
        }
        emit LogWithdrawFees();
    }

    // MasterContract Only Admin functions
    function setSwapper(ISwapper swapper, bool enable) public onlyOwner {
        swappers[swapper] = enable;
    }

    function setFeeTo(address newFeeTo) public onlyOwner
    {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    function setDev(address newDev) public
    {
        require(msg.sender == dev || (dev == address(0) && msg.sender == owner), "LendingPair: Not dev");
        dev = newDev;
        emit LogDev(newDev);
    }

    // Clone contract Admin functions
    function swipe(IERC20 token) public {
        require(msg.sender == masterContract.owner(), "LendingPair: caller is not owner");

        if (address(token) == address(0)) {
            uint256 balanceETH = address(this).balance;
            if (balanceETH > 0) {
                (bool success,) = msg.sender.call{value: balanceETH}(new bytes(0));
                require(success, "LendingPair: ETH transfer failed");
            }
        } else if (address(token) != address(asset) && address(token) != address(collateral)) {
            uint256 balanceAmount = token.balanceOf(address(this));
            if (balanceAmount > 0) {
                (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, msg.sender, balanceAmount));
                require(success && (data.length == 0 || abi.decode(data, (bool))), "LendingPair: Transfer failed");
            }
        } else {
            uint256 excessAmount = bentoBox.balanceOf(token, address(this)).sub(token == asset ? totalAsset.amount : totalCollateralAmount);
            bentoBox.transfer(token, msg.sender, excessAmount);
        }
    }
}
"
    },
    "contracts/interfaces/IOracle.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOracle {
    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(bytes calldata data) external returns (bool, uint256);
    function peek(bytes calldata data) external view returns (bool, uint256);
    function symbol(bytes calldata data) external view returns (string memory);
    function name(bytes calldata data) external view returns (string memory);
}"
    },
    "contracts/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

pragma solidity 0.6.12;

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping(address => uint256) public nonces;
}

contract ERC20 is ERC20Data {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address to, uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "ERC20: balance too low");
        require(balanceOf[to] + amount >= balanceOf[to], "ERC20: overflow detected");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(balanceOf[from] >= amount, "ERC20: balance too low");
        require(allowance[from][msg.sender] >= amount, "ERC20: allowance too low");
        require(balanceOf[to] + amount >= balanceOf[to], "ERC20: overflow detected");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32){
      uint256 chainId;
      assembly {chainId := chainid()}
      return keccak256(abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), chainId, address(this)));
    }

    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01", DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
                owner_, spender, value, nonces[owner_]++, deadline
            ))
        ));
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner_, "ERC20: Invalid Signature");
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}
"
    },
    "contracts/interfaces/ISwapper.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IBentoBox.sol";

interface ISwapper {
    // Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper
    // Swaps it for at least 'amountToMin' of token 'to'
    // Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer
    // Returns the amount of tokens 'to' transferred to BentoBox
    // (The BentoBox skim function will be used by the caller to get the swapped funds)
    function swap(IERC20 from, IERC20 to, uint256 amountFrom, uint256 amountToMin) external returns (uint256 amountTo);

    // Calculates the amount of token 'from' needed to complete the swap (amountFrom), this should be less than or equal to amountFromMax
    // Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper
    // Swaps it for exactly 'exactAmountTo' of token 'to'
    // Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer
    // Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom)
    // Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom)
    // (The BentoBox skim function will be used by the caller to get the swapped funds)
    function swapExact(
        IERC20 from, IERC20 to, uint256 amountFromMax,
        uint256 exactAmountTo, address refundTo
    ) external returns (uint256 amountFrom);
}"
    },
    "contracts/interfaces/IBentoBox.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";

interface IBentoBox {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool indexed approved);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 amount);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount);
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (IERC20);
    function balanceOf(IERC20, address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);
    function deploy(address masterContract, bytes calldata data) external;
    function deposit(IERC20 token, address from, uint256 amount) external payable;
    function depositTo(IERC20 token, address from, address to, uint256 amount) external payable;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function nonces(address) external view returns (uint256);
    function permit(IERC20 token, address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function skim(IERC20 token) external returns (uint256 amount);
    function skimETH() external returns (uint256 amount);
    function skimETHTo(address to) external returns (uint256 amount);
    function skimTo(IERC20 token, address to) external returns (uint256 amount);
    function totalSupply(IERC20) external view returns (uint256);
    function transfer(IERC20 token, address to, uint256 amount) external;
    function transferFrom(IERC20 token, address from, address to, uint256 amount) external;
    function transferMultiple(IERC20 token, address[] calldata tos, uint256[] calldata amounts) external;
    function transferMultipleFrom(IERC20 token, address from, address[] calldata tos, uint256[] calldata amounts) external;
    function withdraw(IERC20 token, address to, uint256 amount) external;
    function withdrawFrom(IERC20 token, address from, address to, uint256 amount) external;
}"
    },
    "contracts/mocks/LendingPairMock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IBentoBox.sol";
import "../LendingPair.sol";

contract LendingPairMock is LendingPair {
    constructor(IBentoBox bentoBox) public LendingPair(bentoBox) {}

    function setInterestPerBlock(uint64 interestPerBlock) public {
        accrueInfo.interestPerBlock = interestPerBlock;
    }
}
"
    },
    "contracts/swappers/SushiSwapSwapper.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ISwapper.sol";

contract SushiSwapSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBox public bentoBox;
    IUniswapV2Factory public factory;

    constructor(IBentoBox bentoBox_, IUniswapV2Factory factory_) public {
        bentoBox = bentoBox_;
        factory = factory_;
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(IERC20 from, IERC20 to, uint256 amountFrom, uint256 amountToMin) public override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(from), address(to)));

        bentoBox.withdraw(from, address(pair), amountFrom);

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountTo;
        if (pair.token0() == address(from)) {
            amountTo = getAmountOut(amountFrom, reserve0, reserve1);
            require(amountTo >= amountToMin, "SushiSwapSwapper: not enough");
            pair.swap(0, amountTo, address(bentoBox), new bytes(0));
        } else {
            amountTo = getAmountOut(amountFrom, reserve1, reserve0);
            require(amountTo >= amountToMin, "SushiSwapSwapper: not enough");
            pair.swap(amountTo, 0, address(bentoBox), new bytes(0));
        }
        return amountTo;
    }

    // Swaps to an exact amount, from a flexible input amount
    function swapExact(
        IERC20 from, IERC20 to, uint256 amountFromMax, uint256 exactAmountTo, address refundTo
    ) public override returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(from), address(to)));

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

        uint256 amountFrom;
        if (pair.token0() == address(from)) {
            amountFrom = getAmountIn(exactAmountTo, reserve0, reserve1);
            require(amountFrom <= amountFromMax, "SushiSwapSwapper: not enough");
            bentoBox.withdraw(from, address(pair), amountFrom);
            pair.swap(0, exactAmountTo, address(bentoBox), new bytes(0));
        } else {
            amountFrom = getAmountIn(exactAmountTo, reserve1, reserve0);
            require(amountFrom <= amountFromMax, "SushiSwapSwapper: not enough");
            bentoBox.withdraw(from, address(pair), amountFrom);
            pair.swap(exactAmountTo, 0, address(bentoBox), new bytes(0));
        }

        bentoBox.transferFrom(from, address(this), refundTo, amountFromMax.sub(amountFrom));

        return amountFrom;
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol": {
      "content": "pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol": {
      "content": "pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}"
    },
    "contracts/interfaces/ILendingPair.sol": {
      "content": "// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./IOracle.sol";
import "./ISwapper.sol";
import "./IERC20.sol";
import "./IBentoBox.sol";

interface ILendingPair {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogAccrue(uint256 accruedAmount, uint256 feeAmount, uint256 rate, uint256 utilization);
    event LogAddAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogAddBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogAddCollateral(address indexed user, uint256 amount);
    event LogDev(address indexed newDev);
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveBorrow(address indexed user, uint256 amount, uint256 fraction);
    event LogRemoveCollateral(address indexed user, uint256 amount);
    event LogWithdrawFees();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function accrue() external;
    function accrueInfo() external view returns (uint64 interestPerBlock, uint64 lastBlockAccrued, uint128 feesPendingAmount);
    function addAsset(uint256 amount, bool useBento) external payable;
    function addAssetTo(uint256 amount, address to, bool useBento) external payable;
    function addCollateral(uint256 amount, bool useBento) external payable;
    function addCollateralTo(uint256 amount, address to, bool useBento) external payable;
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool success);
    function asset() external view returns (IERC20);
    function balanceOf(address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory, bytes[] memory);
    function bentoBox() external view returns (IBentoBox);
    function borrow(uint256 amount, address to, bool useBento) external;
    function claimOwnership() external;
    function collateral() external view returns (IERC20);
    function decimals() external view returns (uint8);
    function dev() external view returns (address);
    function exchangeRate() external view returns (uint256);
    function feeTo() external view returns (address);
    function getInitData(
        IERC20 collateral_, IERC20 asset_, IOracle oracle_, bytes calldata oracleData_) external pure returns (bytes memory data);
    function init(bytes calldata data) external;
    function isSolvent(address user, bool open) external view returns (bool);
    function liquidate(address[] calldata users, uint256[] calldata borrowFractions, address to, ISwapper swapper, bool open) external;
    function masterContract() external view returns (ILendingPair);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function oracle() external view returns (IOracle);
    function oracleData() external view returns (bytes memory);
    function owner() external view returns (address);
    function peekExchangeRate() external view returns (bool, uint256);
    function pendingOwner() external view returns (address);
    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function permitToken(IERC20 token, address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function removeAsset(uint256 fraction, address to, bool useBento) external;
    function removeCollateral(uint256 amount, address to, bool useBento) external;
    function renounceOwnership() external;
    function repay(uint256 fraction, bool useBento) external;
    function repayFor(uint256 fraction, address beneficiary, bool useBento) external;
    function setApproval(address user, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function setDev(address newDev) external;
    function setFeeTo(address newFeeTo) external;
    function setSwapper(ISwapper swapper, bool enable) external;
    function short(ISwapper swapper, uint256 assetAmount, uint256 minCollateralAmount) external;
    function swappers(ISwapper) external view returns (bool);
    function swipe(IERC20 token) external;
    function symbol() external view returns (string memory);
    function totalAsset() external view returns (uint128 amount, uint128 fraction);
    function totalBorrow() external view returns (uint128 amount, uint128 fraction);
    function totalCollateralAmount() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function transferOwnership(address newOwner) external;
    function transferOwnershipDirect(address newOwner) external;
    function unwind(ISwapper swapper, uint256 borrowFraction, uint256 maxAmountCollateral) external;
    function updateExchangeRate() external returns (uint256);
    function userBorrowFraction(address) external view returns (uint256);
    function userCollateralAmount(address) external view returns (uint256);
    function withdrawFees() external;
}"
    },
    "contracts/oracles/SimpleSLPTWAP1Oracle.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only

// Using the same Copyleft License as in the original Repository
// solhint-disable not-rely-on-time

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "../libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol

contract SimpleSLPTWAP1Oracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 5 minutes;

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 priceAverage;
    }

    mapping(IUniswapV2Pair => PairInfo) public pairs; // Map of pairs and their info
    mapping(address => IUniswapV2Pair) public callerInfo; // Map of callers to pairs

    function _get(IUniswapV2Pair pair, uint32 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = pair.price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            priceCumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (blockTimestamp - blockTimestampLast); // overflows ok
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    function getDataParameter(IUniswapV2Pair pair) public pure returns (bytes memory) { return abi.encode(pair); }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(bytes calldata data) external override returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            pairs[pair].blockTimestampLast = blockTimestamp;
            pairs[pair].priceCumulativeLast = _get(pair, blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }

        uint256 priceCumulative = _get(pair, blockTimestamp);
        pairs[pair].priceAverage = FixedPoint.uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));
        pairs[pair].blockTimestampLast = blockTimestamp;
        pairs[pair].priceCumulativeLast = priceCumulative;

        return (true, pairs[pair].priceAverage.mul(10**18).decode144());
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public override view returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }

        uint256 priceCumulative = _get(pair, blockTimestamp);
        FixedPoint.uq112x112 memory priceAverage = FixedPoint
            .uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));

        return (true, priceAverage.mul(10**18).decode144());
    }

    function name(bytes calldata) public override view returns (string memory) {
        return "SushiSwap TWAP";
    }

    function symbol(bytes calldata) public override view returns (string memory) {
        return "S";
    }
}
"
    },
    "contracts/libraries/FixedPoint.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./FullMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint256, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: div by 0");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }
}
"
    },
    "contracts/libraries/FullMath.sol": {
      "content": "// SPDX-License-Identifier: CC-BY-4.0
// solium-disable security/no-assign-params
pragma solidity 0.6.12;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}
"
    },
    "contracts/oracles/SimpleSLPTWAP0Oracle.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only

// Using the same Copyleft License as in the original Repository
// solhint-disable not-rely-on-time

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "../libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol

contract SimpleSLPTWAP0Oracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 5 minutes;

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 priceAverage;
    }

    mapping(IUniswapV2Pair => PairInfo) public pairs; // Map of pairs and their info
    mapping(address => IUniswapV2Pair) public callerInfo; // Map of callers to pairs

    function _get(IUniswapV2Pair pair, uint32 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = pair.price0CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            priceCumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * (blockTimestamp - blockTimestampLast); // overflows ok
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    function getDataParameter(IUniswapV2Pair pair) public pure returns (bytes memory) { return abi.encode(pair); }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(bytes calldata data) external override returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            pairs[pair].blockTimestampLast = blockTimestamp;
            pairs[pair].priceCumulativeLast = _get(pair, blockTimestamp);

            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }

        uint256 priceCumulative = _get(pair, blockTimestamp);
        pairs[pair].priceAverage = FixedPoint.uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));
        pairs[pair].blockTimestampLast = blockTimestamp;
        pairs[pair].priceCumulativeLast = priceCumulative;

        return (true, pairs[pair].priceAverage.mul(10**18).decode144());
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public override view returns (bool, uint256) {
        IUniswapV2Pair pair = abi.decode(data, (IUniswapV2Pair));
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        if (pairs[pair].blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairs[pair].blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairs[pair].priceAverage.mul(10**18).decode144());
        }

        uint256 priceCumulative = _get(pair, blockTimestamp);
        FixedPoint.uq112x112 memory priceAverage = FixedPoint
            .uq112x112(uint224((priceCumulative - pairs[pair].priceCumulativeLast) / timeElapsed));

        return (true, priceAverage.mul(10**18).decode144());
    }

    function name(bytes calldata) public override view returns (string memory) {
        return "SushiSwap TWAP";
    }

    function symbol(bytes calldata) public override view returns (string memory) {
        return "S";
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/UniswapV2Pair.sol": {
      "content": "pragma solidity =0.6.12;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';


interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != uint256(-1), "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/UniswapV2ERC20.sol": {
      "content": "pragma solidity =0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'SushiSwap LP Token';
    string public constant symbol = 'SLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/libraries/Math.sol": {
      "content": "pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/libraries/UQ112x112.sol": {
      "content": "pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/interfaces/IERC20.sol": {
      "content": "pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Callee.sol": {
      "content": "pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
"
    },
    "@sushiswap/core/contracts/uniswapv2/libraries/SafeMath.sol": {
      "content": "pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
"
    },
    "contracts/mocks/SushiSwapPairMock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@sushiswap/core/contracts/uniswapv2/UniswapV2Pair.sol";

contract SushiSwapPairMock is UniswapV2Pair {}
"
    },
    "@sushiswap/core/contracts/uniswapv2/UniswapV2Factory.sol": {
      "content": "pragma solidity =0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}
"
    },
    "contracts/mocks/SushiSwapFactoryMock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/UniswapV2Factory.sol";

contract SushiSwapFactoryMock is UniswapV2Factory {
	constructor() public UniswapV2Factory(msg.sender) {}
}
"
    },
    "contracts/oracles/PeggedOracle.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

contract PeggedOracle is IOracle {
    using BoringMath for uint256;

    function getDataParameter(uint256 rate) public pure returns (bytes memory) { return abi.encode(rate); }

    // Get the exchange rate
    function get(bytes calldata data) public override returns (bool, uint256) {
        uint256 rate = abi.decode(data, (uint256));
        return (rate != 0, rate);
    }

    // Check the exchange rate without any state changes
    function peek(bytes calldata data) public override view returns (bool, uint256) {
        uint256 rate = abi.decode(data, (uint256));
        return (rate != 0, rate);
    }

    function name(bytes calldata) public override view returns (string memory) {
        return "Pegged";
    }

    function symbol(bytes calldata) public override view returns (string memory) {
        return "PEG";
    }
}"
    },
    "contracts/oracles/CompoundOracle.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

interface IUniswapAnchoredView {
    function price(string memory symbol) external view returns (uint256);
}

contract CompoundOracle is IOracle {
    using BoringMath for uint256;

    IUniswapAnchoredView constant private ORACLE = IUniswapAnchoredView(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1);

    struct PriceInfo {
        uint128 price;
        uint128 blockNumber;
    }

    mapping(string => PriceInfo) public prices;

    function _peekPrice(string memory symbol) internal view returns(uint256) {
        if (bytes(symbol).length == 0) {return 1000000;} // To allow only using collateralSymbol or assetSymbol if paired against USDx
        PriceInfo memory info = prices[symbol];
        if (block.number > info.blockNumber + 8) {
            return uint128(ORACLE.price(symbol)); // Prices are denominated with 6 decimals, so will fit in uint128
        }
        return info.price;
    }

    function _getPrice(string memory symbol) internal returns(uint256) {
        if (bytes(symbol).length == 0) {return 1000000;} // To allow only using collateralSymbol or assetSymbol if paired against USDx
        PriceInfo memory info = prices[symbol];
        if (block.number > info.blockNumber + 8) {
            info.price = uint128(ORACLE.price(symbol)); // Prices are denominated with 6 decimals, so will fit in uint128
            info.blockNumber = uint128(block.number); // Blocknumber will fit in uint128
            prices[symbol] = info;
        }
        return info.price;
    }

    function getDataParameter(string memory collateralSymbol, string memory assetSymbol, uint256 division) public pure returns (bytes memory) {
        return abi.encode(collateralSymbol, assetSymbol, division);
    }

    // Get the latest exchange rate
    function get(bytes calldata data) public override returns (bool, uint256) {
        (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
        return (true, uint256(1e36).mul(_getPrice(assetSymbol)) / _getPrice(collateralSymbol) / division);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public override view returns(bool, uint256) {
        (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
        return (true, uint256(1e36).mul(_peekPrice(assetSymbol)) / _peekPrice(collateralSymbol) / division);
    }

    function name(bytes calldata) public override view returns (string memory) {
        return "Compound";
    }

    function symbol(bytes calldata) public override view returns (string memory) {
        return "COMP";
    }
}
"
    },
    "contracts/oracles/CompositeOracle.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only

// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

contract CompositeOracle is IOracle {
    using BoringMath for uint256;

    function getDataParameter(IOracle oracle1, IOracle oracle2, bytes memory data1, bytes memory data2) public pure returns (bytes memory) {
        return abi.encode(oracle1, oracle2, data1, data2);
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(bytes calldata data) external override returns (bool status, uint256 amountOut){
        (IOracle oracle1, IOracle oracle2, bytes memory data1, bytes memory data2) = abi.decode(data, (IOracle, IOracle, bytes, bytes));
        (bool success1, uint256 price1) = oracle1.get(data1);
        (bool success2, uint256 price2) = oracle2.get(data2);
        return (success1 && success2, price1.mul(price2) / 10**18);
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public override view returns (bool success, uint256 amountOut) {
        (IOracle oracle1, IOracle oracle2, bytes memory data1, bytes memory data2) = abi.decode(data, (IOracle, IOracle, bytes, bytes));
        (bool success1, uint256 price1) = oracle1.peek(data1);
        (bool success2, uint256 price2) = oracle2.peek(data2);
        return (success1 && success2, price1.mul(price2) / 10**18);
    }

    function name(bytes calldata data) public override view returns (string memory) {
        (IOracle oracle1, IOracle oracle2, bytes memory data1, bytes memory data2) = abi.decode(data, (IOracle, IOracle, bytes, bytes));
        return string(abi.encodePacked(oracle1.name(data1), "+", oracle2.name(data2)));
    }

    function symbol(bytes calldata data) public override view returns (string memory) {
        (IOracle oracle1, IOracle oracle2, bytes memory data1, bytes memory data2) = abi.decode(data, (IOracle, IOracle, bytes, bytes));
        return string(abi.encodePacked(oracle1.symbol(data1), "+", oracle2.symbol(data2)));
    }
}
"
    },
    "contracts/oracles/ChainlinkOracle.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator
interface IAggregator {
    function latestRoundData() external view returns (uint80, int256 answer, uint256, uint256, uint80);
}

contract ChainlinkOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get(address multiply, address divide, uint256 decimals) public view returns (uint256) {
        uint256 price = uint256(1e18);
        if (multiply != address(0)) {
            // We only care about the second value - the price
            (, int256 priceC,,,) = IAggregator(multiply).latestRoundData();
            price = price.mul(uint256(priceC));
        } else {
            price = price.mul(1e18);
        }

        if (divide != address(0)) {
            // We only care about the second value - the price
            (, int256 priceC,,,) = IAggregator(divide).latestRoundData();
            price = price / uint256(priceC);
        }

        return price / decimals;
    }

    function getDataParameter(address multiply, address divide, uint256 decimals) public pure returns (bytes memory) {
        return abi.encode(multiply, divide, decimals);
    }

    // Get the latest exchange rate
    function get(bytes calldata data) public override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    // Check the last exchange rate without any state changes
    function peek(bytes calldata data) public override view returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    function name(bytes calldata) public override view returns (string memory) {
        return "Chainlink";
    }

    function symbol(bytes calldata) public override view returns (string memory) {
        return "LINK";
    }
}
"
    },
    "contracts/mocks/OracleMock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
import "../libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// WARNING: This oracle is only for testing, please use PeggedOracle for a fixed value oracle
contract OracleMock is IOracle {
	using BoringMath for uint256;

	uint256 rate;

	function set(uint256 rate_, address) public {
		// The rate can be updated.
		rate = rate_;
	}

	function getDataParameter() public pure returns (bytes memory) {
		return abi.encode("0x0");
	}

	// Get the latest exchange rate
	function get(bytes calldata) public override returns (bool, uint256) {
		return (true, rate);
	}

	// Check the last exchange rate without any state changes
	function peek(bytes calldata) public view override returns (bool, uint256) {
		return (true, rate);
	}

	function name(bytes calldata) public view override returns (string memory) {
		return "Test";
	}

	function symbol(bytes calldata) public view override returns (string memory) {
		return "TEST";
	}
}
"
    },
    "contracts/BentoHelper.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./interfaces/ILendingPair.sol";
import "./interfaces/IOracle.sol";

contract BentoHelper {
    struct PairInfo {
        ILendingPair pair;
        IOracle oracle;
        IBentoBox bentoBox;
        address masterContract;
        bool masterContractApproved;
        IERC20 tokenAsset;
        IERC20 tokenCollateral;

        uint256 latestExchangeRate;
        uint256 lastBlockAccrued;
        uint256 interestRate;
        uint256 totalCollateralAmount;
        uint256 totalAssetAmount;
        uint256 totalBorrowAmount;

        uint256 totalAssetFraction;
        uint256 totalBorrowFraction;

        uint256 interestPerBlock;

        uint256 feesPendingAmount;

        uint256 userCollateralAmount;
        uint256 userAssetFraction;
        uint256 userAssetAmount;
        uint256 userBorrowFraction;
        uint256 userBorrowAmount;

        uint256 userAssetBalance;
        uint256 userCollateralBalance;
        uint256 userAssetAllowance;
        uint256 userCollateralAllowance;
    }

    function getPairs(address user, ILendingPair[] calldata pairs) public view returns (PairInfo[] memory info) {
        info = new PairInfo[](pairs.length);
        for(uint256 i = 0; i < pairs.length; i++) {
            ILendingPair pair = pairs[i];
            info[i].pair = pair;
            info[i].oracle = pair.oracle();
            IBentoBox bentoBox = pair.bentoBox();
            info[i].bentoBox = bentoBox;
            info[i].masterContract = address(pair.masterContract());
            info[i].masterContractApproved = bentoBox.masterContractApproved(info[i].masterContract, user);
            IERC20 asset = pair.asset();
            info[i].tokenAsset = asset;
            IERC20 collateral = pair.collateral();
            info[i].tokenCollateral = collateral;

            (, info[i].latestExchangeRate) = pair.peekExchangeRate();
            (info[i].interestPerBlock, info[i].lastBlockAccrued, info[i].feesPendingAmount) = pair.accrueInfo();
            info[i].totalCollateralAmount = pair.totalCollateralAmount();
            (info[i].totalAssetAmount, info[i].totalAssetFraction ) = pair.totalAsset();
            (info[i].totalBorrowAmount, info[i].totalBorrowFraction) = pair.totalBorrow();

            info[i].userCollateralAmount = pair.userCollateralAmount(user);
            info[i].userAssetFraction = pair.balanceOf(user);
            info[i].userAssetAmount = info[i].totalAssetFraction == 0 ? 0 :
                 info[i].userAssetFraction * info[i].totalAssetAmount / info[i].totalAssetFraction;
            info[i].userBorrowFraction = pair.userBorrowFraction(user);
            info[i].userBorrowAmount = info[i].totalBorrowFraction == 0 ? 0 :
                info[i].userBorrowFraction * info[i].totalBorrowAmount / info[i].totalBorrowFraction;

            info[i].userAssetBalance = info[i].tokenAsset.balanceOf(user);
            info[i].userCollateralBalance = info[i].tokenCollateral.balanceOf(user);
            info[i].userAssetAllowance = info[i].tokenAsset.allowance(user, address(bentoBox));
            info[i].userCollateralAllowance = info[i].tokenCollateral.allowance(user, address(bentoBox));
        }
    }
}
"
    },
    "contracts/mocks/ERC20Mock.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "../ERC20.sol";

contract ERC20Mock is ERC20 {
	uint256 public totalSupply;

	constructor(uint256 _initialAmount) public {
		// Give the creator all initial tokens
		balanceOf[msg.sender] = _initialAmount;
		// Update total supply
		totalSupply = _initialAmount;
	}
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 500
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "metadata": {
      "useLiteralContent": true
    },
    "libraries": {
      "": {
        "__CACHE_BREAKER__": "0x00000000d41867734bbee4c6863d9255b2b06ac1"
      }
    }
  }
}}