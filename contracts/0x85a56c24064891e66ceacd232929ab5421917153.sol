{"Genesis.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";
import "./IgOHM.sol";
import "./IStaking.sol";
import "./Ownable.sol";

interface IClaim {
    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 claimed; // static number
        uint256 wClaimed; // rebase-tracking number
        uint256 max; // maximum nominal OHM amount can claim
    }
    function terms(address _address) external view returns (Term memory);
}

/**
 *  This contract allows Olympus genesis contributors to claim OHM. It has been
 *  revised to consider 9/10 tokens as staked at the time of claim; previously,
 *  no claims were treated as staked. This change keeps network ownership in check. 
 *  100% can be treated as staked, if the DAO sees fit to do so.
 */
contract GenesisClaim is Ownable {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STRUCTS ========== */

    struct Term {
        uint256 percent; // 4 decimals ( 5000 = 0.5% )
        uint256 claimed; // static number
        uint256 gClaimed; // rebase-tracking number
        uint256 max; // maximum nominal OHM amount can claim
    }

    /* ========== STATE VARIABLES ========== */

    // claim token
    IERC20 internal immutable ohm = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5); 
    // payment token
    IERC20 internal immutable dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); 
    // mints claim token
    ITreasury internal immutable treasury = ITreasury(0x9A315BdF513367C0377FB36545857d12e85813Ef); 
    // stake OHM for sOHM
    IStaking internal immutable staking = IStaking(0xB63cac384247597756545b500253ff8E607a8020); 
    // holds non-circulating supply
    address internal immutable dao = 0x245cc372C84B3645Bf0Ffe6538620B04a217988B; 
    // tracks rebase-agnostic balance
    IgOHM internal immutable gOHM = IgOHM(0x0ab87046fBb341D058F17CBC4c1133F25a20a52f);
    // previous deployment of contract (to migrate terms)
    IClaim internal immutable previous = IClaim(0xEaAA9d97Be33a764031eDdEbA1cB6Cb385350Ca3);

    // track 1/10 as static. governance can disable if desired.
    bool public useStatic;
    // tracks address info
    mapping( address => Term ) public terms;
    // facilitates address change
    mapping( address => address ) public walletChange;
    // as percent of supply (4 decimals: 10000 = 1%)
    uint256 public totalAllocated;
    // maximum portion of supply can allocate. == 7.8%
    uint256 public maximumAllocated = 78000; 

    constructor() {useStatic = true;}

    /* ========== MUTABLE FUNCTIONS ========== */
    
    /**
     * @notice allows wallet to claim OHM
     * @param _to address
     * @param _amount uint256
     */
    function claim(address _to, uint256 _amount) external {
        ohm.safeTransfer(_to, _claim(_amount));
    }

    /**
     * @notice allows wallet to claim OHM and stake. set _claim = true if warmup is 0.
     * @param _to address
     * @param _amount uint256
     * @param _rebasing bool
     * @param _claimFromStaking bool
     */
    function stake(address _to, uint256 _amount, bool _rebasing, bool _claimFromStaking) external {
        staking.stake(_to, _claim(_amount), _rebasing, _claimFromStaking);
    }

    /**
     * @notice logic for claiming OHM
     * @param _amount uint256
     * @return toSend_ uint256
     */
    function _claim(uint256 _amount) internal returns (uint256 toSend_) {
        Term memory info = terms[msg.sender];

        dai.safeTransferFrom(msg.sender, address(this), _amount);
        toSend_ = treasury.deposit(_amount, address(dai), 0);

        require(redeemableFor(msg.sender).div(1e9) >= toSend_, "Claim more than vested");
        require(info.max.sub(claimed(msg.sender)) >= toSend_, "Claim more than max");

        if(useStatic) {
            terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_.mul(9).div(10)));
            terms[msg.sender].claimed = info.claimed.add(toSend_.div(10));
        } else terms[msg.sender].gClaimed = info.gClaimed.add(gOHM.balanceTo(toSend_));
    }

    /**
     * @notice allows address to push terms to new address
     * @param _newAddress address
     */
    function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }
    
    /**
     * @notice allows new address to pull terms
     * @param _oldAddress address
     */
    function pullWalletChange(address _oldAddress) external {
        require(walletChange[_oldAddress] == msg.sender, "Old wallet did not push");
        require(terms[msg.sender].percent != 0, "Wallet already exists");
        
        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
    }

    /**
     * @notice mass approval saves gas
     */
    function approve() external {
        ohm.approve(address(staking), 1e33);
        dai.approve(address(treasury), 1e33);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice view OHM claimable for address. DAI decimals (18).
     * @param _address address
     * @return uint256
     */
    function redeemableFor(address _address) public view returns (uint256) {
        Term memory info = terms[_address];
        uint256 max = circulatingSupply().mul(info.percent).mul(1e3);
        if (max > info.max) max = info.max;
        return max.sub(claimed(_address).mul(1e9));
    }

    /**
     * @notice view OHM claimed by address. OHM decimals (9).
     * @param _address address
     * @return uint256
     */
    function claimed(address _address) public view returns (uint256) {
        return gOHM.balanceFrom(terms[_address].gClaimed).add(terms[_address].claimed);
    }

    /**
     * @notice view circulating supply of OHM
     * @notice calculated as total supply minus DAO holdings
     * @return uint256
     */
    function circulatingSupply() public view returns (uint256) {
        return treasury.baseSupply().sub(ohm.balanceOf(dao));
    }

    /* ========== OWNER FUNCTIONS ========== */

    /**
     * @notice bulk migrate users from previous contract
     * @param _addresses address[] memory
     */
    function migrate(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IClaim.Term memory term = previous.terms(_addresses[i]);
            setTerms(
                _addresses[i], 
                term.percent,
                term.claimed,
                term.wClaimed,
                term.max
            );
        }
    }

    /**
     *  @notice set terms for new address
     *  @notice cannot lower for address or exceed maximum total allocation
     *  @param _address address
     *  @param _percent uint256
     *  @param _claimed uint256
     *  @param _gClaimed uint256
     *  @param _max uint256
     */
    function setTerms(
        address _address, 
        uint256 _percent, 
        uint256 _claimed, 
        uint256 _gClaimed, 
        uint256 _max
    ) public onlyOwner {
        require(terms[_address].max == 0, "address already exists");
        terms[_address] = Term({
            percent: _percent,
            claimed: _claimed,
            gClaimed: _gClaimed,
            max: _max
        });
        require(totalAllocated.add(_percent) <= maximumAllocated, "Cannot allocate more");
        totalAllocated = totalAllocated.add(_percent);
    }

    /* ========== DAO FUNCTIONS ========== */

    /**
     * @notice all claims tracked under gClaimed (and track rebase)
     */
     function treatAllAsStaked() external {
        require(msg.sender == dao, "Sender is not DAO");
        useStatic = false;
     }
}"},"IERC20.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

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
"},"IgOHM.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IgOHM is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

  function migrate( address _staking, address _sOHM ) external;
}
"},"IOwnable.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;


interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}"},"IStaking.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}
"},"ITreasury.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IOwnable.sol";

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}
"},"SafeERC20.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.5;

import "./IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}"}}