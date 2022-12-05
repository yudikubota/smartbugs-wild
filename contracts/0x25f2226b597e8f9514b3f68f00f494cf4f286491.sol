{{
  "language": "Solidity",
  "sources": {
    "contracts/AaveGenesisExecutor.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IProxyWithAdminActions} from './interfaces/IProxyWithAdminActions.sol';
import {
  ILendToAaveMigratorImplWithInitialize
} from './interfaces/ILendToAaveMigratorImplWithInitialize.sol';
import {IAaveTokenImpl} from './interfaces/IAaveTokenImpl.sol';
import {
  IAaveIncentivesVaultImplWithInitialize
} from './interfaces/IAaveIncentivesVaultImplWithInitialize.sol';
import {IStakedAaveImplWithInitialize} from './interfaces/IStakedAaveImplWithInitialize.sol';

import {IAaveGenesisExecutor} from './interfaces/IAaveGenesisExecutor.sol';

/**
 * @title AaveGenesisExecutor
 * @notice Smart contract to trigger the LEND -> AAVE migration and enable the staking Safety Module
 * - The Aave Governance, on the payload of the proposal will call `setActivationBlock()` with the block
 *   number at which the migration and staking starts
 * - Once that block number is reached, `startMigration()` will be opened to call by anybody, to execute the
 *   programmed process
 * - As to execute all the operations with proxy contracts this contract needs to be the admin, a `returnAdminsToGovernance()`
 *   function has be added to return back the admin rights to the Aave Governance if after 1 day of the `activationBlock` the
 *   ownership of the proxies is still on this contract
 * @author Aave
 **/
contract AaveGenesisExecutor is IAaveGenesisExecutor {
  address public immutable AAVE_GOVERNANCE;
  IProxyWithAdminActions public immutable LEND_TO_AAVE_MIGRATOR_PROXY;
  ILendToAaveMigratorImplWithInitialize public immutable LEND_TO_AAVE_MIGRATOR_IMPL;
  IProxyWithAdminActions public immutable AAVE_TOKEN_PROXY;
  IAaveTokenImpl public immutable AAVE_TOKEN_IMPL;
  IProxyWithAdminActions public immutable AAVE_INCENTIVES_VAULT_PROXY;
  IAaveIncentivesVaultImplWithInitialize public immutable AAVE_INCENTIVES_VAULT_IMPL;
  IProxyWithAdminActions public immutable STAKED_AAVE_PROXY;

  /// @dev Number of blocks per day
  uint256 public constant BLOCKS_PER_DAY = 6650;

  /// @dev Allowance of AAVE given by the AaveIncentivesVault to the StakedAave to pull incentives for stakers
  uint256 public immutable AAVE_ALLOWANCE_FOR_STAKE;

  /// @dev Block number of when the activateMigration() will be triggered
  uint256 internal activationBlock;

  constructor(
    address aaveGovernance,
    uint256 aaveAllowanceForStake,
    IProxyWithAdminActions lendToAaveMigratorProxy,
    ILendToAaveMigratorImplWithInitialize lendToAaveMigratorImpl,
    IProxyWithAdminActions aaveTokenProxy,
    IAaveTokenImpl aaveTokenImpl,
    IProxyWithAdminActions aaveIncentivesVaultProxy,
    IAaveIncentivesVaultImplWithInitialize aaveIncentivesVaultImpl,
    IProxyWithAdminActions stakedAaveProxy
  ) public {
    AAVE_GOVERNANCE = aaveGovernance;
    AAVE_ALLOWANCE_FOR_STAKE = aaveAllowanceForStake;
    LEND_TO_AAVE_MIGRATOR_PROXY = lendToAaveMigratorProxy;
    LEND_TO_AAVE_MIGRATOR_IMPL = lendToAaveMigratorImpl;
    AAVE_TOKEN_PROXY = aaveTokenProxy;
    AAVE_TOKEN_IMPL = aaveTokenImpl;
    AAVE_INCENTIVES_VAULT_PROXY = aaveIncentivesVaultProxy;
    AAVE_INCENTIVES_VAULT_IMPL = aaveIncentivesVaultImpl;
    STAKED_AAVE_PROXY = stakedAaveProxy;
  }

  /**
   * @dev Called by the Aave Governance contract to set the block at which the LEND -> AAVE and the staking will start
   * @param blockNumber The future block number
   */
  function setActivationBlock(uint256 blockNumber) external override {
    require(msg.sender == AAVE_GOVERNANCE);

    activationBlock = blockNumber;

    emit MigrationProgrammedForBlock(blockNumber);
  }

  /**
   * @dev Once the `activationBlock` is reached, this funcion can be called by anybody to trigger the migration + startup of staking
   */
  function startMigration() external override {
    // ensures that the migration can only be called after the initialization has been performed
    require(activationBlock != 0 && block.number >= activationBlock);

    // step 1: Initializes the LendToAaveMigrator to enable the migration contract
    bytes memory migratorParams = abi.encodeWithSelector(
      LEND_TO_AAVE_MIGRATOR_IMPL.initialize.selector
    );
    LEND_TO_AAVE_MIGRATOR_PROXY.upgradeToAndCall(
      address(LEND_TO_AAVE_MIGRATOR_IMPL),
      migratorParams
    );

    // step 2: Initializes the AAVE token. The initialization triggers the following events:
    // - 13M AAVE are minted to the LendToAaveMigrator, which enables the migration process
    // - 3M AAVE are minted to the incentives vault
    bytes memory aaveTokenParams = abi.encodeWithSelector(
      AAVE_TOKEN_IMPL.initialize.selector,
      address(LEND_TO_AAVE_MIGRATOR_PROXY),
      address(AAVE_INCENTIVES_VAULT_PROXY), // Where the incentives will be minted to
      address(0) // No hook to the governance is needed for now on the AaveToken
    );
    AAVE_TOKEN_PROXY.upgradeToAndCall(address(AAVE_TOKEN_IMPL), aaveTokenParams);

    // step 3: Initializes the Aave incentives vault.
    // The initialization will approve the Aave stake to pull funds from the vault in order to distribute
    // staking incentives
    bytes memory aaveIncentivesVaultParams = abi.encodeWithSelector(
      AAVE_INCENTIVES_VAULT_IMPL.initialize.selector,
      address(AAVE_TOKEN_PROXY),
      address(STAKED_AAVE_PROXY), // The StakedAave will be approved to pull AAVE for incentives
      AAVE_ALLOWANCE_FOR_STAKE
    );
    AAVE_INCENTIVES_VAULT_PROXY.upgradeToAndCall(
      address(AAVE_INCENTIVES_VAULT_IMPL),
      aaveIncentivesVaultParams
    );

    _returnAdminsToGovernance();

    emit MigrationStarted();
  }

  /**
   * @dev Emergency function to return the admin rights on all the proxy contracts if something went wrong on `startMigration()`.
   * - Anybody can call it once > ~1 day in blocks passed since the `activationBlock`
   */
  function returnAdminsToGovernance() external override {
    require(activationBlock != 0 && block.number >= activationBlock + BLOCKS_PER_DAY);

    _returnAdminsToGovernance();
  }

  function _returnAdminsToGovernance() private {
    LEND_TO_AAVE_MIGRATOR_PROXY.changeAdmin(AAVE_GOVERNANCE);
    AAVE_TOKEN_PROXY.changeAdmin(AAVE_GOVERNANCE);
    AAVE_INCENTIVES_VAULT_PROXY.changeAdmin(AAVE_GOVERNANCE);
    STAKED_AAVE_PROXY.changeAdmin(AAVE_GOVERNANCE);
  }
}
"
    },
    "contracts/interfaces/IProxyWithAdminActions.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProxyWithAdminActions {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
  function changeAdmin(address newAdmin) external;
}
"
    },
    "contracts/interfaces/ILendToAaveMigratorImplWithInitialize.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILendToAaveMigratorImplWithInitialize {
  function initialize() external;
}
"
    },
    "contracts/interfaces/IAaveTokenImpl.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveTokenImpl {
  function initialize(
    address migrator,
    address distributor,
    address aaveGovernance
  ) external;
}
"
    },
    "contracts/interfaces/IAaveIncentivesVaultImplWithInitialize.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveIncentivesVaultImplWithInitialize {
  function initialize(
    address aave,
    address stakedAave,
    uint256 initialStakingDistribution
  ) external;
}
"
    },
    "contracts/interfaces/IStakedAaveImplWithInitialize.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IStakedAaveImplWithInitialize {
  function initialize(
    address aaveGovernance,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external;
}
"
    },
    "contracts/interfaces/IAaveGenesisExecutor.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveGenesisExecutor {
    event MigrationProgrammedForBlock(uint256 blockNumber);
    event MigrationStarted();

    function setActivationBlock(uint256 blockNumber) external;
    function startMigration() external;
    function returnAdminsToGovernance() external;
}"
    },
    "contracts/AaveGenesisProposalPayload.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IProposalExecutor} from './interfaces/IProposalExecutor.sol';
import {IAaveGenesisExecutor} from './interfaces/IAaveGenesisExecutor.sol';
import {IProxyWithAdminActions} from './interfaces/IProxyWithAdminActions.sol';
import {IERC20} from './interfaces/IERC20.sol';
import {IAssetVotingWeightProvider} from './interfaces/IAssetVotingWeightProvider.sol';
import {IStakedAaveConfig} from './interfaces/IStakedAaveConfig.sol';

/**
 * @title AaveGenesisProposalPayload
 * @notice Proposal payload to be executed by the Aave Governance contract via DELEGATECALL
 * - Transfers ownership of the different proxies to the `AaveGenesisExecutor`
 * - Lists AAVE and stkAAVE as voting asset in the Aave Governance
 * - Activates the cooldown for the activation of the LEND -> AAVE migration
 * @author Aave
 **/
contract AaveGenesisProposalPayload is IProposalExecutor {
  event ProposalExecuted();

  /// @dev Initial emission per second approved by the Aave community: 400 AAVE/day
  uint128 public constant EMISSION_PER_SECOND_FOR_STAKED_AAVE = 0.00462962962962963 ether;

  /// @dev Delta of blocks from the execution of this payload until the activation of the migration
  uint256 public immutable ACTIVATION_BLOCK_DELAY;

  /// @dev The smart contract that will execute the activation of the migration (`AaveGenesisExecutor`)
  IAaveGenesisExecutor public immutable AAVE_GENESIS_EXECUTOR;

  /// @dev The smart contract registry for the voting weights of all the whitelisted voting assets on the Aave governance
  IAssetVotingWeightProvider public immutable ASSET_VOTING_WEIGHT_PROVIDER;

  /// @dev Proxy contracts involved in the migration. This payload contract will need to transfer the admin rights of them,
  /// to allow it to do the upgrade of the implementations
  IProxyWithAdminActions public immutable LEND_TO_AAVE_MIGRATOR_PROXY;
  IProxyWithAdminActions public immutable AAVE_TOKEN_PROXY;
  IProxyWithAdminActions public immutable AAVE_INCENTIVES_VAULT_PROXY;
  IProxyWithAdminActions public immutable STAKED_AAVE_PROXY;

  /// @dev Address of wrapper aggregating LEND and aLEND balances
  address public immutable LEND_VOTE_STRATEGY_TOKEN;

  /// @dev Address of wrapper aggregating AAVE and stkAAVE balances
  address public immutable AAVE_VOTE_STRATEGY_TOKEN;

  constructor(
    uint256 activationBlockDelay,
    IAssetVotingWeightProvider assetVotingWeightProvider,
    IAaveGenesisExecutor aaveGenesisExecutor,
    IProxyWithAdminActions lendToAaveMigratorProxy,
    IProxyWithAdminActions aaveTokenProxy,
    IProxyWithAdminActions aaveIncentivesVaultProxy,
    IProxyWithAdminActions stakedAaveProxy,
    address lendVoteStrategyToken,
    address aaveVoteStrategyToken
  ) public {
    ACTIVATION_BLOCK_DELAY = activationBlockDelay;
    ASSET_VOTING_WEIGHT_PROVIDER = assetVotingWeightProvider;
    AAVE_GENESIS_EXECUTOR = aaveGenesisExecutor;
    LEND_TO_AAVE_MIGRATOR_PROXY = lendToAaveMigratorProxy;
    AAVE_TOKEN_PROXY = aaveTokenProxy;
    AAVE_INCENTIVES_VAULT_PROXY = aaveIncentivesVaultProxy;
    STAKED_AAVE_PROXY = stakedAaveProxy;
    LEND_VOTE_STRATEGY_TOKEN = lendVoteStrategyToken;
    AAVE_VOTE_STRATEGY_TOKEN = aaveVoteStrategyToken;
  }

  /**
   * @dev Payload execution function, called once a proposal passed in the Aave governance
   */
  function execute() external override {
    address newAdmin = address(AAVE_GENESIS_EXECUTOR);

    LEND_TO_AAVE_MIGRATOR_PROXY.changeAdmin(newAdmin);
    AAVE_TOKEN_PROXY.changeAdmin(newAdmin);
    AAVE_INCENTIVES_VAULT_PROXY.changeAdmin(newAdmin);
    STAKED_AAVE_PROXY.changeAdmin(newAdmin);

    // We disable the LEND voting strategy (LEND+aLEND)
    ASSET_VOTING_WEIGHT_PROVIDER.setVotingWeight(IERC20(LEND_VOTE_STRATEGY_TOKEN), 0);

    // We enable the AAVE voting strategy (AAVE+stkAAVE). As LEND is not listed already, they can have weight 1
    ASSET_VOTING_WEIGHT_PROVIDER.setVotingWeight(IERC20(AAVE_VOTE_STRATEGY_TOKEN), 1);

    // After transferring the admin to `newAdmin`, as this contract is the EMISSION_MANAGER of StakedAave,
    // we configure the initial emission of AAVE incentives
    IStakedAaveConfig.AssetConfigInput[] memory config = new IStakedAaveConfig.AssetConfigInput[](
      1
    );
    config[0] = IStakedAaveConfig.AssetConfigInput({
      emissionPerSecond: EMISSION_PER_SECOND_FOR_STAKED_AAVE,
      totalStaked: 0,
      underlyingAsset: address(STAKED_AAVE_PROXY)
    });

    IStakedAaveConfig(address(STAKED_AAVE_PROXY)).configureAssets(config);

    AAVE_GENESIS_EXECUTOR.setActivationBlock(block.number + ACTIVATION_BLOCK_DELAY);
    emit ProposalExecuted();
  }
}
"
    },
    "contracts/interfaces/IProposalExecutor.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IProposalExecutor {
    function execute() external;
}"
    },
    "contracts/interfaces/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
    "contracts/interfaces/IAssetVotingWeightProvider.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IAssetVotingWeightProvider {
    function getVotingWeight(IERC20 _asset) external view returns(uint256);
    function setVotingWeight(IERC20 _asset, uint256 _weight) external;
}"
    },
    "contracts/interfaces/IStakedAaveConfig.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IStakedAaveConfig {
  struct AssetConfigInput {
    uint128 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  function configureAssets(AssetConfigInput[] calldata assetsConfigInput) external;
}
"
    },
    "contracts/AaveIncentivesVault.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './interfaces/IERC20.sol';
import {VersionedInitializable} from './libs/VersionedInitializable.sol';
import {SafeERC20} from './libs/SafeERC20.sol';

/**
 * @title AaveIncentivesVault
 * @notice Stores all the AAVE kept for incentives, just giving approval to the different
 * systems that will pull AAVE funds for their specific use case
 * @author Aave
 **/
contract AaveIncentivesVault is VersionedInitializable {
  using SafeERC20 for IERC20;

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal override pure returns (uint256) {
    return REVISION;
  }

  /**
   * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
   * On this first revision:
   * - Approves the StakedAave contract to pull AAVE funds to distribute as incentives
   * @param aave Address of the AAVE token
   * @param stakedAave Address of the stkAAVE token (AAVE staking contract)
   * @param initialStakingDistribution Amount of AAVE to approve to the stkAAVE contract
   */
  function initialize(
    IERC20 aave,
    address stakedAave,
    uint256 initialStakingDistribution
  ) external initializer {
    aave.safeApprove(stakedAave, initialStakingDistribution);
  }
}
"
    },
    "contracts/libs/VersionedInitializable.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 internal lastInitializedRevision = 0;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(revision > lastInitializedRevision, 'Contract instance has already been initialized');

    lastInitializedRevision = revision;

    _;
  }

  /// @dev returns the revision number of the contract.
  /// Needs to be defined in the inherited class as a constant.
  function getRevision() internal virtual pure returns (uint256);

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
"
    },
    "contracts/libs/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}
"
    },
    "contracts/libs/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}
"
    },
    "contracts/libs/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}
"
    },
    "contracts/AaveVoteStrategyToken.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './interfaces/IERC20.sol';
import {IVoteStrategyToken} from './interfaces/IVoteStrategyToken.sol';
import {SafeMath} from './libs/SafeMath.sol';

/**
 * @title AaveVoteStrategyToken
 * @notice Wrapper contract to allow fetching aggregated balance of AAVE and stkAAVE from an address,
 * used on the AaveProtoGovernance
 * @author Aave
 **/
contract AaveVoteStrategyToken is IVoteStrategyToken {
  using SafeMath for uint256;

  IERC20 public immutable AAVE;
  IERC20 public immutable STKAAVE;
  string internal constant NAME = 'Aave Vote Strategy (Aave Token + Staked Aave)';
  string internal constant SYMBOL = 'AAVE + stkAAVE';
  uint8 internal constant DECIMALS = 18;

  constructor(IERC20 aave, IERC20 stkAave) public {
    AAVE = aave;
    STKAAVE = stkAave;
  }

  function name() external override view returns (string memory) {
    return NAME;
  }

  function symbol() external override view returns (string memory) {
    return SYMBOL;
  }

  function decimals() external override view returns (uint8) {
    return DECIMALS;
  }

  /**
   * @dev Returns the aggregated AAVE + stkAAVE balance of `voter`
   * @param voter The address of the voter
   * @return The aggregated balance
   */
  function balanceOf(address voter) external override view returns (uint256) {
    return AAVE.balanceOf(voter).add(STKAAVE.balanceOf(voter));
  }
}
"
    },
    "contracts/interfaces/IVoteStrategyToken.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IVoteStrategyToken {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address voter) external view returns (uint256);
}
"
    },
    "contracts/interfaces/IERC20Detailed.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}
"
    },
    "contracts/LendVoteStrategyToken.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './interfaces/IERC20.sol';
import {IVoteStrategyToken} from './interfaces/IVoteStrategyToken.sol';
import {SafeMath} from './libs/SafeMath.sol';

/**
 * @title LendVoteStrategyToken
 * @notice Wrapper contract to allow fetching aggregated balance of LEND and aLEND from an address,
 * used on the AaveProtoGovernance
 * @author Aave
 **/
contract LendVoteStrategyToken is IVoteStrategyToken {
  using SafeMath for uint256;

  IERC20 public immutable LEND;
  IERC20 public immutable ALEND;
  string internal constant NAME = 'Lend Vote Strategy (EthLend Token + Aave Interest bearing LEND)';
  string internal constant SYMBOL = 'LEND + aLEND';
  uint8 internal constant DECIMALS = 18;

  constructor(IERC20 lend, IERC20 aLend) public {
    LEND = lend;
    ALEND = aLend;
  }

  function name() external override view returns (string memory) {
    return NAME;
  }

  function symbol() external override view returns (string memory) {
    return SYMBOL;
  }

  function decimals() external override view returns (uint8) {
    return DECIMALS;
  }

  /**
   * @dev Returns the aggregated LEND + aLEND balance of `voter`
   * @param voter The address of the voter
   * @return The aggregated balance
   */
  function balanceOf(address voter) external override view returns (uint256) {
    return LEND.balanceOf(voter).add(ALEND.balanceOf(voter));
  }
}
"
    },
    "contracts/libs/BaseAdminUpgradeabilityProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32
    internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), 'Cannot change the admin of a proxy to the zero address');
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}
"
    },
    "contracts/libs/UpgradeabilityProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}
"
    },
    "contracts/libs/BaseUpgradeabilityProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32
    internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal override view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}
"
    },
    "contracts/libs/Proxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal virtual view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
        // delegatecall returns 0 on error.
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}
"
    },
    "contracts/libs/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}
"
    },
    "contracts/libs/ERC20.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from '../interfaces/IERC20.sol';
import {IERC20Detailed} from '../interfaces/IERC20Detailed.sol';
import {Context} from './Context.sol';
import {SafeMath} from './SafeMath.sol';

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave
 **/
contract ERC20 is Context, IERC20, IERC20Detailed {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token
   **/
  function name() public override view returns (string memory) {
    return _name;
  }

  /**
   * @return the symbol of the token
   **/
  function symbol() public override view returns (string memory) {
    return _symbol;
  }

  /**
   * @return the decimals of the token
   **/
  function decimals() public override view returns (uint8) {
    return _decimals;
  }

  /**
   * @return the total supply of the token
   **/
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @return the balance of the token
   **/
  function balanceOf(address account) public override view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev executes a transfer of tokens from msg.sender to recipient
   * @param recipient the recipient of the tokens
   * @param amount the amount of tokens being transferred
   * @return true if the transfer succeeds, false otherwise
   **/
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev returns the allowance of spender on the tokens owned by owner
   * @param owner the owner of the tokens
   * @param spender the user allowed to spend the owner's tokens
   * @return the amount of owner's tokens spender is allowed to spend
   **/
  function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev allows spender to spend the tokens owned by msg.sender
   * @param spender the user allowed to spend msg.sender tokens
   * @return true
   **/
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev executes a transfer of token from sender to recipient, if msg.sender is allowed to do so
   * @param sender the owner of the tokens
   * @param recipient the recipient of the tokens
   * @param amount the amount of tokens being transferred
   * @return true if the transfer succeeds, false otherwise
   **/
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  /**
   * @dev increases the allowance of spender to spend msg.sender tokens
   * @param spender the user allowed to spend on behalf of msg.sender
   * @param addedValue the amount being added to the allowance
   * @return true
   **/
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev decreases the allowance of spender to spend msg.sender tokens
   * @param spender the user allowed to spend on behalf of msg.sender
   * @param subtractedValue the amount being subtracted to the allowance
   * @return true
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setName(string memory newName) internal {
    _name = newName;
  }

  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}
"
    },
    "contracts/libs/InitializableAdminUpgradeabilityProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is
  BaseAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}
"
    },
    "contracts/libs/InitializableUpgradeabilityProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}
"
    },
    "contracts/mocks/MintableErc20.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC20} from '../libs/ERC20.sol';

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableErc20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol, decimals) {}

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    _mint(msg.sender, value);
    return true;
  }
}
"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": false
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
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
    "evmVersion": "istanbul",
    "libraries": {}
  }
}}