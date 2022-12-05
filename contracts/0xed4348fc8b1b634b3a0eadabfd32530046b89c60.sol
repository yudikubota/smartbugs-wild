{"Admin.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./AdminInterface.sol";

/**
 * @title Admin
 * @author Paul Razvan Berg
 * @notice Contract module which provides a basic access control mechanism, where there is
 * an account (an admin) that can be granted exclusive access to specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This can later
 * be changed with {transferAdmin}.
 *
 * This module is used through inheritance. It will make available the modifier `onlyAdmin`,
 * which can be applied to your functions to restrict their use to the admin.
 *
 * @dev Forked from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/access/Ownable.sol
 */
abstract contract Admin is AdminInterface {
    /**
     * @notice Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin == msg.sender, "ERR_NOT_ADMIN");
        _;
    }

    /**
     * @notice Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        address msgSender = msg.sender;
        admin = msgSender;
        emit TransferAdmin(address(0x00), msgSender);
    }

    /**
     * @notice Leaves the contract without admin, so it will not be possible to call
     * `onlyAdmin` functions anymore.
     *
     * Requirements:
     *
     * - The caller must be the administrator.
     *
     * WARNING: Doing this will leave the contract without an admin,
     * thereby removing any functionality that is only available to the admin.
     */
    function _renounceAdmin() external virtual override onlyAdmin {
        emit TransferAdmin(admin, address(0x00));
        admin = address(0x00);
    }

    /**
     * @notice Transfers the admin of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     * @param newAdmin The acount of the new admin.
     */
    function _transferAdmin(address newAdmin) external virtual override onlyAdmin {
        require(newAdmin != address(0x00), "ERR_SET_ADMIN_ZERO_ADDRESS");
        emit TransferAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}
"},"AdminInterface.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./AdminStorage.sol";

/**
 * @title AdminInterface
 * @author Paul Razvan Berg
 */
abstract contract AdminInterface is AdminStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function _renounceAdmin() external virtual;

    function _transferAdmin(address newAdmin) external virtual;

    /**
     * EVENTS
     */
    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);
}
"},"AdminStorage.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

abstract contract AdminStorage {
    /**
     * @notice The address of the administrator account or contract.
     */
    address public admin;
}
"},"AggregatorV3Interface.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

/**
 * @title AggregatorV3Interface
 * @author Hifi
 * @dev Forked from Chainlink
 * https://github.com/smartcontractkit/chainlink/blob/v0.9.9/evm-contracts/src/v0.7/interfaces/AggregatorV3Interface.sol
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    /*
     * getRoundData and latestRoundData should both raise "No data present"
     * if they do not have data to report, instead of returning unset values
     * which could be misinterpreted as actual reported values.
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
"},"BalanceSheetInterface.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./BalanceSheetStorage.sol";

/**
 * @title BalanceSheetInterface
 * @author Hifi
 */
abstract contract BalanceSheetInterface is BalanceSheetStorage {
    /**
     * CONSTANT FUNCTIONS
     */
    function getClutchableCollateral(FyTokenInterface fyToken, uint256 repayAmount)
        external
        view
        virtual
        returns (uint256);

    function getCurrentCollateralizationRatio(FyTokenInterface fyToken, address borrower)
        public
        view
        virtual
        returns (uint256);

    function getHypotheticalCollateralizationRatio(
        FyTokenInterface fyToken,
        address borrower,
        uint256 lockedCollateral,
        uint256 debt
    ) public view virtual returns (uint256);

    function getVault(FyTokenInterface fyToken, address borrower)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getVaultDebt(FyTokenInterface fyToken, address borrower) external view virtual returns (uint256);

    function getVaultLockedCollateral(FyTokenInterface fyToken, address borrower)
        external
        view
        virtual
        returns (uint256);

    function isAccountUnderwater(FyTokenInterface fyToken, address borrower) external view virtual returns (bool);

    function isVaultOpen(FyTokenInterface fyToken, address borrower) external view virtual returns (bool);

    /**
     * NON-CONSTANT FUNCTIONS
     */

    function clutchCollateral(
        FyTokenInterface fyToken,
        address liquidator,
        address borrower,
        uint256 clutchedCollateralAmount
    ) external virtual returns (bool);

    function depositCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function freeCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function lockCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    function openVault(FyTokenInterface fyToken) external virtual returns (bool);

    function setVaultDebt(
        FyTokenInterface fyToken,
        address borrower,
        uint256 newVaultDebt
    ) external virtual returns (bool);

    function withdrawCollateral(FyTokenInterface fyToken, uint256 collateralAmount) external virtual returns (bool);

    /**
     * EVENTS
     */

    event ClutchCollateral(
        FyTokenInterface indexed fyToken,
        address indexed liquidator,
        address indexed borrower,
        uint256 clutchedCollateralAmount
    );

    event DepositCollateral(FyTokenInterface indexed fyToken, address indexed borrower, uint256 collateralAmount);

    event FreeCollateral(FyTokenInterface indexed fyToken, address indexed borrower, uint256 collateralAmount);

    event LockCollateral(FyTokenInterface indexed fyToken, address indexed borrower, uint256 collateralAmount);

    event OpenVault(FyTokenInterface indexed fyToken, address indexed borrower);

    event SetVaultDebt(FyTokenInterface indexed fyToken, address indexed borrower, uint256 oldDebt, uint256 newDebt);

    event WithdrawCollateral(FyTokenInterface indexed fyToken, address indexed borrower, uint256 collateralAmount);
}
"},"BalanceSheetStorage.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FyTokenInterface.sol";

/**
 * @title BalanceSheetStorage
 * @author Hifi
 */
abstract contract BalanceSheetStorage {
    struct Vault {
        uint256 debt;
        uint256 freeCollateral;
        uint256 lockedCollateral;
        bool isOpen;
    }

    /**
     * @notice The unique Fintroller associated with this contract.
     */
    FintrollerInterface public fintroller;

    /**
     * @dev One vault for each fyToken for each account.
     */
    mapping(address => mapping(address => Vault)) internal vaults;

    /**
     * @notice Indicator that this is a BalanceSheet contract, for inspection.
     */
    bool public constant isBalanceSheet = true;
}
"},"CarefulMath.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

/**
 * @notice Possible error codes that can be returned.
 */
enum MathError { NO_ERROR, DIVISION_BY_ZERO, INTEGER_OVERFLOW, INTEGER_UNDERFLOW, MODULO_BY_ZERO }

/**
 * @title CarefulMath
 * @author Paul Razvan Berg
 * @notice Exponential module for storing fixed-precision decimals.
 * @dev Forked from Compound
 * https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/CarefulMath.sol
 */
abstract contract CarefulMath {
    /**
     * @notice Adds two numbers, returns an error on overflow.
     */
    function addUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        uint256 c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
     * @notice Add `a` and `b` and then subtract `c`.
     */
    function addThenSubUInt(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (MathError, uint256) {
        (MathError err0, uint256 sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }

    /**
     * @notice Integer division of two numbers, truncating the quotient.
     */
    function divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
     * @notice Returns the remainder of dividing two numbers.
     * @dev Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     */
    function modUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b == 0) {
            return (MathError.MODULO_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a % b);
    }

    /**
     * @notice Multiplies two numbers, returns an error on overflow.
     */
    function mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint256 c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
     * @notice Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
     */
    function subUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }
}
"},"ChainlinkOperatorInterface.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./Erc20Interface.sol";

import "./ChainlinkOperatorStorage.sol";
import "./AggregatorV3Interface.sol";

/**
 * @title ChainlinkOperatorInterface
 * @author Hifi
 */
abstract contract ChainlinkOperatorInterface is ChainlinkOperatorStorage {
    /**
     * EVENTS
     */
    event DeleteFeed(Erc20Interface indexed asset, AggregatorV3Interface indexed feed);

    event SetFeed(Erc20Interface indexed asset, AggregatorV3Interface indexed feed);

    /**
     * CONSTANT FUNCTIONS.
     */
    function getAdjustedPrice(string memory symbol) external view virtual returns (uint256);

    function getFeed(string memory symbol)
        external
        view
        virtual
        returns (
            Erc20Interface,
            AggregatorV3Interface,
            bool
        );

    function getPrice(string memory symbol) public view virtual returns (uint256);

    /**
     * NON-CONSTANT FUNCTIONS.
     */
    function deleteFeed(string memory symbol) external virtual returns (bool);

    function setFeed(Erc20Interface asset, AggregatorV3Interface feed) external virtual returns (bool);
}
"},"ChainlinkOperatorStorage.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Erc20Interface.sol";

import "./AggregatorV3Interface.sol";

/**
 * @title ChainlinkOperatorStorage
 * @author Hifi
 */
abstract contract ChainlinkOperatorStorage {
    struct Feed {
        Erc20Interface asset;
        AggregatorV3Interface id;
        bool isSet;
    }

    /**
     * @dev Mapping between Erc20 symbols and Feed structs.
     */
    mapping(string => Feed) internal feeds;

    /**
     * @notice Chainlink price precision for USD-quoted data.
     */
    uint256 public constant pricePrecision = 8;

    /**
     * @notice The ratio between mantissa precision (1e18) and the Chainlink price precision (1e8).
     */
    uint256 public constant pricePrecisionScalar = 1.0e10;
}
"},"Erc20Interface.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Erc20Storage.sol";

/**
 * @title Erc20Interface
 * @author Paul Razvan Berg
 * @notice Interface of the Erc20 standard
 * @dev Forked from OpenZeppelin
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC20/IERC20.sol
 */
abstract contract Erc20Interface is Erc20Storage {
    /**
     * CONSTANT FUNCTIONS
     */
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /**
     * NON-CONSTANT FUNCTIONS
     */
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /**
     * EVENTS
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 amount);
}
"},"Erc20Storage.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

/**
 * @title ExponentialStorage
 * @author Paul Razvan Berg
 * @notice The storage interface ancillary to an Erc20 contract.
 */
abstract contract Erc20Storage {
    /**
     * @notice Returns the number of decimals used to get its user representation.
     */
    uint8 public decimals;

    /**
     * @notice Returns the name of the token.
     */
    string public name;

    /**
     * @notice Returns the symbol of the token, usually a shorter version of
     * the name.
     */
    string public symbol;

    /**
     * @notice Returns the amount of tokens in existence.
     */
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}
"},"Exponential.sol":{"content":"/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./ExponentialStorage.sol";

/**
 * @title Exponential module for storing fixed-precision decimals.
 * @author Paul Razvan Berg
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 * Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is: `Exp({mantissa: 5100000000000000000})`.
 * @dev Forked from Compound
 * https://github.com/compound-finance/compound-protocol/blob/v2.6/contracts/Exponential.sol
 */
abstract contract Exponential is
    CarefulMath, /* no dependency */
    ExponentialStorage /* no dependency */
{
    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     * (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b.
     * NOTE: Returns an error if (`num` * 10e18) > MAX_INT, or if `denom` is zero.
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(a.mantissa, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (MathError err1, uint256 rational) = divUInt(scaledNumerator, b.mantissa);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        /*
         * We add half the scale before dividing so that we get rounding instead of truncation.
         * See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
         * Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
         */
        (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        /* The only possible error `div` is MathError.DIVISION_BY_ZERO but we control `expScale` and it's not zero. */
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({ mantissa: product }));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }
}
"},"ExponentialStorage.sol":{"content":"/* SPDX-License-Identifier: LPGL-3.0-or-later */
pragma solidity ^0.7.0;

/**
 * @title ExponentialStorage
 * @author Paul Razvan Berg
 * @notice The storage interface ancillary to an Exponential contract.
 */
abstract contract ExponentialStorage {
    struct Exp {
        uint256 mantissa;
    }

    /**
     * @dev In Exponential denomination, 1e18 is 1.
     */
    uint256 internal constant expScale = 1e18;
    uint256 internal constant halfExpScale = expScale / 2;
    uint256 internal constant mantissaOne = expScale;
}
"},"Fintroller.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./Exponential.sol";

import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";
import "./ChainlinkOperatorInterface.sol";

/**
 * @notice Fintroller
 * @author Hifi
 * @notice Controls the financial permissions and risk parameters for all fyTokens.
 */
contract Fintroller is
    FintrollerInterface, /* one dependency */
    Admin /* two dependencies */
{
    /* solhint-disable-next-line no-empty-blocks */
    constructor() Admin() {
        /* Set a default value of 110% for the liquidation incentive. */
        liquidationIncentiveMantissa = 1.1e18;
    }

    /**
     * CONSTANT FUNCTIONS
     */

    /**
     * @notice Reads the storage properties of the bond.
     * @dev It is not an error to provide an invalid fyToken address. The returned values would all be zero.
     * @param fyToken The address of the bond contract.
     */
    function getBond(FyTokenInterface fyToken)
        external
        view
        override
        returns (
            uint256 collateralizationRatioMantissa,
            uint256 debtCeiling,
            bool isBorrowAllowed,
            bool isDepositCollateralAllowed,
            bool isLiquidateBorrowAllowed,
            bool isListed,
            bool isRedeemFyTokenAllowed,
            bool isRepayBorrowAllowed,
            bool isSupplyUnderlyingAllowed
        )
    {
        collateralizationRatioMantissa = bonds[fyToken].collateralizationRatio.mantissa;
        debtCeiling = bonds[fyToken].debtCeiling;
        isBorrowAllowed = bonds[fyToken].isBorrowAllowed;
        isDepositCollateralAllowed = bonds[fyToken].isDepositCollateralAllowed;
        isLiquidateBorrowAllowed = bonds[fyToken].isLiquidateBorrowAllowed;
        isListed = bonds[fyToken].isListed;
        isRedeemFyTokenAllowed = bonds[fyToken].isRedeemFyTokenAllowed;
        isRepayBorrowAllowed = bonds[fyToken].isRepayBorrowAllowed;
        isSupplyUnderlyingAllowed = bonds[fyToken].isSupplyUnderlyingAllowed;
    }

    /**
     * @notice Reads the collateralization ratio of the given bond.
     * @dev It is not an error to provide an invalid fyToken address.
     * @param fyToken The address of the bond contract.
     * @return The collateralization ratio as a mantissa, or zero if an invalid address was provided.
     */
    function getBondCollateralizationRatio(FyTokenInterface fyToken) external view override returns (uint256) {
        return bonds[fyToken].collateralizationRatio.mantissa;
    }

    /**
     * @notice Reads the debt ceiling of the given bond.
     * @dev It is not an error to provide an invalid fyToken address.
     * @param fyToken The address of the bond contract.
     * @return The debt ceiling as a uint256, or zero if an invalid address was provided.
     */
    function getBondDebtCeiling(FyTokenInterface fyToken) external view override returns (uint256) {
        return bonds[fyToken].debtCeiling;
    }

    /**
     * @notice Check if the account should be allowed to borrow fyTokens.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to deposit collateral.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getDepositCollateralAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isDepositCollateralAllowed;
    }

    /**
     * @notice Check if the account should be allowed to liquidate fyToken borrows.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getLiquidateBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isLiquidateBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to redeem the underlying asset from the Redemption Pool.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getRedeemFyTokensAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isRedeemFyTokenAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to repay borrows.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getRepayBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isRepayBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to the supply underlying asset to the Redemption Pool.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getSupplyUnderlyingAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isSupplyUnderlyingAllowed;
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    /**
     * @notice Marks the bond as listed in this Fintroller's registry. It is not an error to list a bond twice.
     *
     * @dev Emits a {ListBond} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The fyToken must pass the inspection.
     *
     * @param fyToken The fyToken contract to list.
     * @return bool true = success, otherwise it reverts.
     */
    function listBond(FyTokenInterface fyToken) external override onlyAdmin returns (bool) {
        require(fyToken.isFyToken(), "ERR_LIST_BOND_FYTOKEN_INSPECTION");
        bonds[fyToken] = Bond({
            collateralizationRatio: Exp({ mantissa: defaultCollateralizationRatioMantissa }),
            debtCeiling: 0,
            isBorrowAllowed: true,
            isDepositCollateralAllowed: true,
            isLiquidateBorrowAllowed: true,
            isListed: true,
            isRedeemFyTokenAllowed: true,
            isRepayBorrowAllowed: true,
            isSupplyUnderlyingAllowed: true
        });
        emit ListBond(admin, fyToken);
        return true;
    }

    /**
     * @notice Updates the bond's collateralization ratio.
     *
     * @dev Emits a {SetBondCollateralizationRatio} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     * - The new collateralization ratio cannot be higher than the maximum collateralization ratio.
     * - The new collateralization ratio cannot be lower than the minimum collateralization ratio.
     *
     * @param fyToken The bond for which to update the collateralization ratio.
     * @param newCollateralizationRatioMantissa The new collateralization ratio as a mantissa.
     * @return bool true = success, otherwise it reverts.
     */
    function setBondCollateralizationRatio(FyTokenInterface fyToken, uint256 newCollateralizationRatioMantissa)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: bond is listed. */
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");

        /* Checks: new collateralization ratio is within the accepted bounds. */
        require(
            newCollateralizationRatioMantissa <= collateralizationRatioUpperBoundMantissa,
            "ERR_SET_BOND_COLLATERALIZATION_RATIO_UPPER_BOUND"
        );
        require(
            newCollateralizationRatioMantissa >= collateralizationRatioLowerBoundMantissa,
            "ERR_SET_BOND_COLLATERALIZATION_RATIO_LOWER_BOUND"
        );

        /* Effects: update storage. */
        uint256 oldCollateralizationRatioMantissa = bonds[fyToken].collateralizationRatio.mantissa;
        bonds[fyToken].collateralizationRatio = Exp({ mantissa: newCollateralizationRatioMantissa });

        emit SetBondCollateralizationRatio(
            admin,
            fyToken,
            oldCollateralizationRatioMantissa,
            newCollateralizationRatioMantissa
        );

        return true;
    }

    /**
     * @notice Updates the debt ceiling, which limits how much debt can be created in the bond market.
     *
     * @dev Emits a {SetBondDebtCeiling} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     * - The debt ceiling cannot be zero.
     * - The debt ceiling cannot fall below the current total supply of fyTokens.
     *
     * @param fyToken The bond for which to update the debt ceiling.
     * @param newDebtCeiling The uint256 value of the new debt ceiling, specified in the bond's decimal system.
     * @return bool true = success, otherwise it reverts.
     */
    function setBondDebtCeiling(FyTokenInterface fyToken, uint256 newDebtCeiling)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: bond is listed. */
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");

        /* Checks: the zero edge case. */
        require(newDebtCeiling > 0, "ERR_SET_BOND_DEBT_CEILING_ZERO");

        /* Checks: above total supply of fyTokens. */
        uint256 totalSupply = fyToken.totalSupply();
        require(newDebtCeiling >= totalSupply, "ERR_SET_BOND_DEBT_CEILING_UNDERFLOW");

        /* Effects: update storage. */
        uint256 oldDebtCeiling = bonds[fyToken].debtCeiling;
        bonds[fyToken].debtCeiling = newDebtCeiling;

        emit SetBondDebtCeiling(admin, fyToken, oldDebtCeiling, newDebtCeiling);

        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a borrow.
     *
     * @dev Emits a {SetBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setBorrowAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isBorrowAllowed = state;
        emit SetBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a collateral deposit.
     *
     * @dev Emits a {SetDepositCollateralAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setDepositCollateralAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isDepositCollateralAllowed = state;
        emit SetDepositCollateralAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a liquidate borrow.
     *
     * @dev Emits a {SetLiquidateBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setLiquidateBorrowAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isLiquidateBorrowAllowed = state;
        emit SetLiquidateBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Sets a new value for the liquidation incentive, which is applicable
     * to all listed bonds.
     *
     * @dev Emits a {SetLiquidationIncentive} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The new liquidation incentive cannot be higher than the maximum liquidation incentive.
     * - The new liquidation incentive cannot be lower than the minimum liquidation incentive.

     * @param newLiquidationIncentiveMantissa The new liquidation incentive as a mantissa.
     * @return bool true = success, otherwise it reverts.
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: new collateralization ratio is within the accepted bounds. */
        require(
            newLiquidationIncentiveMantissa <= liquidationIncentiveUpperBoundMantissa,
            "ERR_SET_LIQUIDATION_INCENTIVE_UPPER_BOUND"
        );
        require(
            newLiquidationIncentiveMantissa >= liquidationIncentiveLowerBoundMantissa,
            "ERR_SET_LIQUIDATION_INCENTIVE_LOWER_BOUND"
        );

        /* Effects: update storage. */
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        emit SetLiquidationIncentive(admin, oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return true;
    }

    /**
     * @notice Updates the oracle contract's address saved in storage.
     *
     * @dev Emits a {SetOracle} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The new address cannot be the zero address.
     *
     * @param newOracle The new oracle contract.
     * @return bool true = success, otherwise it reverts.
     */
    function setOracle(ChainlinkOperatorInterface newOracle) external override onlyAdmin returns (bool) {
        require(address(newOracle) != address(0x00), "ERR_SET_ORACLE_ZERO_ADDRESS");
        address oldOracle = address(oracle);
        oracle = newOracle;
        emit SetOracle(admin, oldOracle, address(newOracle));
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the Redemption Pool before a redemption of underlying.
     *
     * @dev Emits a {SetRedeemFyTokensAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setRedeemFyTokensAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isRedeemFyTokenAllowed = state;
        emit SetRedeemFyTokensAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a repay borrow.
     *
     * @dev Emits a {SetRepayBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setRepayBorrowAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isRepayBorrowAllowed = state;
        emit SetRepayBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the Redemption Pool before a supply of underlying.
     *
     * @dev Emits a {SetSupplyUnderlyingAllowed} event.
     *
     * Requirements:
     * - The caller must be the admin
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setSupplyUnderlyingAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isSupplyUnderlyingAllowed = state;
        emit SetSupplyUnderlyingAllowed(admin, fyToken, state);
        return true;
    }
}
"},"FintrollerInterface.sol":{"content":"/* SPDX-License-Identifier: LPGL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FintrollerStorage.sol";
import "./FyTokenInterface.sol";
import "./ChainlinkOperatorInterface.sol";

abstract contract FintrollerInterface is FintrollerStorage {
    /**
     * CONSTANT FUNCTIONS
     */

    function getBond(FyTokenInterface fyToken)
        external
        view
        virtual
        returns (
            uint256 debtCeiling,
            uint256 collateralizationRatioMantissa,
            bool isBorrowAllowed,
            bool isDepositCollateralAllowed,
            bool isLiquidateBorrowAllowed,
            bool isListed,
            bool isRedeemFyTokenAllowed,
            bool isRepayBorrowAllowed,
            bool isSupplyUnderlyingAllowed
        );

    function getBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getBondCollateralizationRatio(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getBondDebtCeiling(FyTokenInterface fyToken) external view virtual returns (uint256);

    function getDepositCollateralAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getLiquidateBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRedeemFyTokensAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getRepayBorrowAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    function getSupplyUnderlyingAllowed(FyTokenInterface fyToken) external view virtual returns (bool);

    /**
     * NON-CONSTANT FUNCTIONS
     */

    function listBond(FyTokenInterface fyToken) external virtual returns (bool);

    function setBondCollateralizationRatio(FyTokenInterface fyToken, uint256 newCollateralizationRatioMantissa)
        external
        virtual
        returns (bool);

    function setBondDebtCeiling(FyTokenInterface fyToken, uint256 newDebtCeiling) external virtual returns (bool);

    function setBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setDepositCollateralAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setLiquidateBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external virtual returns (bool);

    function setOracle(ChainlinkOperatorInterface newOracle) external virtual returns (bool);

    function setRedeemFyTokensAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setRepayBorrowAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    function setSupplyUnderlyingAllowed(FyTokenInterface fyToken, bool state) external virtual returns (bool);

    /**
     * EVENTS
     */
    event ListBond(address indexed admin, FyTokenInterface indexed fyToken);

    event SetBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetBondCollateralizationRatio(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldCollateralizationRatio,
        uint256 newCollateralizationRatio
    );

    event SetBondDebtCeiling(
        address indexed admin,
        FyTokenInterface indexed fyToken,
        uint256 oldDebtCeiling,
        uint256 newDebtCeiling
    );

    event SetDepositCollateralAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetLiquidateBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetLiquidationIncentive(
        address indexed admin,
        uint256 oldLiquidationIncentive,
        uint256 newLiquidationIncentive
    );

    event SetRedeemFyTokensAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetRepayBorrowAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);

    event SetOracle(address indexed admin, address oldOracle, address newOracle);

    event SetSupplyUnderlyingAllowed(address indexed admin, FyTokenInterface indexed fyToken, bool state);
}
"},"FintrollerStorage.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Exponential.sol";

import "./FyTokenInterface.sol";
import "./ChainlinkOperatorInterface.sol";

/**
 * @title FintrollerStorage
 * @author Hifi
 */
abstract contract FintrollerStorage is Exponential {
    struct Bond {
        Exp collateralizationRatio;
        uint256 debtCeiling;
        bool isBorrowAllowed;
        bool isDepositCollateralAllowed;
        bool isLiquidateBorrowAllowed;
        bool isListed;
        bool isRedeemFyTokenAllowed;
        bool isRepayBorrowAllowed;
        bool isSupplyUnderlyingAllowed;
    }

    /**
     * @dev Maps the fyToken address to the Bond structs.
     */
    mapping(FyTokenInterface => Bond) internal bonds;

    /**
     * @notice The contract that provides price data for the collateral and the underlying asset.
     */
    ChainlinkOperatorInterface public oracle;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives.
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @dev The threshold below which the collateralization ratio cannot be set, equivalent to 100%.
     */
    uint256 internal constant collateralizationRatioLowerBoundMantissa = 1.0e18;

    /**
     * @dev The threshold above which the collateralization ratio cannot be set, equivalent to 10,000%.
     */
    uint256 internal constant collateralizationRatioUpperBoundMantissa = 1.0e20;

    /**
     * @dev The dafault collateralization ratio set when a new bond is listed, equivalent to 150%.
     */
    uint256 internal constant defaultCollateralizationRatioMantissa = 1.5e18;

    /**
     * @dev The threshold below which the liquidation incentive cannot be set, equivalent to 100%.
     */
    uint256 internal constant liquidationIncentiveLowerBoundMantissa = 1.0e18;

    /**
     * @dev The threshold above which the liquidation incentive cannot be set, equivalent to 150%.
     */
    uint256 internal constant liquidationIncentiveUpperBoundMantissa = 1.5e18;

    /**
     * @notice Indicator that this is a Fintroller contract, for inspection.
     */
    bool public constant isFintroller = true;
}
"},"FyTokenInterface.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Erc20Interface.sol";
import "./FyTokenStorage.sol";

/**
 * @title FyTokenInterface
 * @author Hifi
 */
abstract contract FyTokenInterface is
    FyTokenStorage, /* no dependency */
    Erc20Interface /* one dependency */
{
    /**
     * CONSTANT FUNCTIONS
     */
    function isMatured() public view virtual returns (bool);

    /**
     * NON-CONSTANT FUNCTIONS
     */
    function borrow(uint256 borrowAmount) external virtual returns (bool);

    function burn(address holder, uint256 burnAmount) external virtual returns (bool);

    function liquidateBorrow(address borrower, uint256 repayAmount) external virtual returns (bool);

    function mint(address beneficiary, uint256 mintAmount) external virtual returns (bool);

    function repayBorrow(uint256 repayAmount) external virtual returns (bool);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (bool);

    function _setFintroller(FintrollerInterface newFintroller) external virtual returns (bool);

    /**
     * EVENTS
     */
    event Borrow(address indexed borrower, uint256 borrowAmount);

    event LiquidateBorrow(
        address indexed liquidator,
        address indexed borrower,
        uint256 repayAmount,
        uint256 clutchedCollateralAmount
    );

    event RepayBorrow(address indexed payer, address indexed borrower, uint256 repayAmount, uint256 newDebt);

    event SetFintroller(address indexed admin, FintrollerInterface oldFintroller, FintrollerInterface newFintroller);
}
"},"FyTokenStorage.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Erc20Interface.sol";
import "./BalanceSheetInterface.sol";
import "./FintrollerInterface.sol";
import "./RedemptionPoolInterface.sol";

/**
 * @title FyTokenStorage
 * @author Hifi
 */
abstract contract FyTokenStorage {
    /**
     * STORAGE PROPERTIES
     */

    /**
     * @notice The global debt registry.
     */
    BalanceSheetInterface public balanceSheet;

    /**
     * @notice The Erc20 asset that backs the borrows of this fyToken.
     */
    Erc20Interface public collateral;

    /**
     * @notice The ratio between mantissa precision (1e18) and the collateral precision.
     */
    uint256 public collateralPrecisionScalar;

    /**
     * @notice Unix timestamp in seconds for when this token expires.
     */
    uint256 public expirationTime;

    /**
     * @notice The unique Fintroller associated with this contract.
     */
    FintrollerInterface public fintroller;

    /**
     * @notice The unique Redemption Pool associated with this contract.
     */
    RedemptionPoolInterface public redemptionPool;

    /**
     * @notice The Erc20 underlying, or target, asset for this fyToken.
     */
    Erc20Interface public underlying;

    /**
     * @notice The ratio between mantissa precision (1e18) and the underlying precision.
     */
    uint256 public underlyingPrecisionScalar;

    /**
     * @notice Indicator that this is a FyToken contract, for inspection.
     */
    bool public constant isFyToken = true;
}
"},"RedemptionPoolInterface.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./RedemptionPoolStorage.sol";

/**
 * @title RedemptionPoolInterface
 * @author Hifi
 */
abstract contract RedemptionPoolInterface is RedemptionPoolStorage {
    /**
     * NON-CONSTANT FUNCTIONS
     */
    function redeemFyTokens(uint256 fyTokenAmount) external virtual returns (bool);

    function supplyUnderlying(uint256 underlyingAmount) external virtual returns (bool);

    /**
     * EVENTS
     */
    event RedeemFyTokens(address indexed account, uint256 fyTokenAmount, uint256 underlyingAmount);

    event SupplyUnderlying(address indexed account, uint256 underlyingAmount, uint256 fyTokenAmount);
}
"},"RedemptionPoolStorage.sol":{"content":"/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";

/**
 * @title RedemptionPoolStorage
 * @author Hifi
 */
abstract contract RedemptionPoolStorage {
    /**
     * @notice The unique Fintroller associated with this contract.
     */
    FintrollerInterface public fintroller;

    /**
     * @notice The amount of the underlying asset available to be redeemed after maturation.
     */
    uint256 public totalUnderlyingSupply;

    /**
     * The unique fyToken associated with this Redemption Pool.
     */
    FyTokenInterface public fyToken;

    /**
     * @notice Indicator that this is a Redemption Pool contract, for inspection.
     */
    bool public constant isRedemptionPool = true;
}
"}}