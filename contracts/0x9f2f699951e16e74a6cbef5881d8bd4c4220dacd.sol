{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"},"ERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"},"Properties.sol":{"content":"/*
* SPDX-License-Identifier: UNLICENSED
* Copyright Â© 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./PropToken.sol";

/// @title Properties
contract Properties is PropToken {
    uint256 private _commonEquity;
    uint256 private _preferredEquity;
    uint256 private _mezzanine;
    uint256 private _juniorDebt;
    uint256 private _seniorDebt;

    uint16 private _royaltyPercentage;

    modifier onlyPropManagerOrSpecialWallet {
        require(PropTokenHelpers(getDataAddress()).canEditProperty(_msgSender(), address(this)) || _msgSender() == PropTokenHelpers(getDataAddress()).getSpecialWallet(), "Properties: You need to be property manager!");
        _;
    }

    event CapitalStackChange(address indexed property, uint256 tokenizationAmount, uint256 commonEquity, uint256 preferredEquity, uint256 mezzanine,
        uint256 juniorDebt, uint256 seniorDebt);

    constructor(address owner, address propertyRegistry) public PropToken("BlocksquarePropertyToken", "BSPT") {
        transferOwnership(owner);
        _propertyRegistry = propertyRegistry;
    }

    /// @notice change royalty percentage
    /// @param royaltyPercentage Percent for royalties (5% is entered as 500)
    function addRoyaltyPercentage(uint16 royaltyPercentage) public onlyPropManagerOrSpecialWallet {
        require(_royaltyPercentage == 0, "Properties: Royalty percentage already set!");
        require(_royaltyPercentage <= 10000, "Properties: Royalty percentage must be less or equal to 10000");
        _royaltyPercentage = royaltyPercentage;
    }

    /// @notice change capital stack information
    /// @param cap Max amount of tokens that can be minted
    /// @param commonEquity Common equity amount
    /// @param preferredEquity Preferred equity amount
    /// @param mezzanine Mezzanine amount
    /// @param juniorDebt Junior debt amount
    /// @param seniorDebt Senior debt amount
    function changeCapitalStack(uint256 cap, uint256 commonEquity, uint256 preferredEquity, uint256 mezzanine,
        uint256 juniorDebt, uint256 seniorDebt) public onlyPropManagerOrSpecialWallet {
        require(cap.add(commonEquity).add(preferredEquity).add(mezzanine).add(juniorDebt).add(seniorDebt) == 100000 * 1 ether,
            "Properties: The sum of the capital stack needs to be same as maximum supply of BSPT");
        require(cap >= totalSupply(), "Properties: Cap needs to be bigger or equal to total supply");
        _cap = cap;
        _commonEquity = commonEquity;
        _preferredEquity = preferredEquity;
        _mezzanine = mezzanine;
        _juniorDebt = juniorDebt;
        _seniorDebt = seniorDebt;
        emit CapitalStackChange(address(this), cap, commonEquity, preferredEquity, mezzanine, juniorDebt, seniorDebt);
    }

    /// @notice can only be called by property registry
    function changeTokenNameAndSymbol(string memory name, string memory symbol) external {
        require(msg.sender == _propertyRegistry, "Properties: Transaction must come from registry!");
        _name = name;
        _symbol = symbol;
    }

    /// @notice see property registry contract
    function getProperty(uint64 index) public view returns (string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart) {
        return PropTokenHelpers(_propertyRegistry).getPropertyInfo(address(this), index);
    }

    /// @notice see property registry contract
    function getBasicInfo() public view returns (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency) {
        return PropTokenHelpers(_propertyRegistry).getBasicInfo(address(this));
    }

    /// @notice see property registry contract
    function getIPFSHash() public view returns (string memory) {
        return PropTokenHelpers(_propertyRegistry).getIPFS(address(this));
    }

    /// @notice retrieves current capital stack information
    function getCapitalStack() public view returns (uint256 tokenization, uint256 commonEquity, uint256 preferredEquity,
        uint256 mezzanine, uint256 juniorDebt, uint256 seniorDebt) {
        return (_cap,
        _commonEquity,
        _preferredEquity,
        _mezzanine,
        _juniorDebt,
        _seniorDebt);
    }

    /// @notice retrieves current royalty percent
    function getRoyaltyPercentage() public view returns (uint16) {
        return _royaltyPercentage;
    }

    /// @dev fallback function to prevent any ether to be sent to this contract
    receive() external payable {
        revert();
    }
}
"},"PropToken.sol":{"content":"/*
* SPDX-License-Identifier: UNLICENSED
* Copyright Â© 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./Context.sol";

interface PropTokenHelpers {
    function freezeProperty(address prop) external;

    function unfreezeProperty(address prop) external;

    function isPropTokenFrozen(address property) external view returns (bool);

    function hasSystemAdminRights(address addr) external view returns (bool);

    function getLicencedIssuerFee() external view returns (uint256);

    function getBlocksquareFee() external view returns (uint256);

    function getCertifiedPartnerFee() external view returns (uint256);

    function getBlocksquareAddress() external view returns (address);

    function getDataProxy() external view returns (address);

    function canTransferPropTokensTo(address wallet, address property) external view returns (bool);

    function isCPAdminOfProperty(address user, address property) external view returns (bool);

    function getCPOfProperty(address prop) external view returns (address);

    function getSpecialWallet() external view returns (address);

    function getBasicInfo(address property) external view returns (string memory streetLocation, string memory geoLocation, uint256 propertyValuation, uint256 tokenValuation, string memory propertyValuationCurrency);

    function getPropertyInfo(address property, uint64 index) external view returns (string memory propertyType, string memory kadastralMunicipality, string memory parcelNumber, string memory ID, uint64 buildingPart);

    function getIPFS(address property) external view returns (string memory);

    function getOceanPointContract() external view returns (address);

    function canEditProperty(address wallet, address property) external view returns (bool);

    function isContractWhitelisted(address cont) external view returns (bool);
}

contract Owned is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

/// @title Property Token
contract PropToken is ERC20, Owned {
    using SafeMath for uint256;

    uint256 internal _cap;

    address private _mintContract;
    address private _burnContract;
    address internal _propertyRegistry;

    bool private _canMint;

    modifier onlySystemAdmin {
        require(PropTokenHelpers(getDataAddress()).hasSystemAdminRights(msg.sender), "PropToken: You need to have system admin rights!");
        _;
    }

    modifier onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)) || msg.sender == PropTokenHelpers(getDataAddress()).getCPOfProperty(address(this)),
            "PropToken: you don't have permission!");
        _;
    }

    constructor(string memory name, string memory symbol) internal ERC20(name, symbol) {
    }

    function changeLI(address newOwner) public onlySystemAdmin {
        _owner = newOwner;
    }

    /**
    * @dev Sends `amount` of token from caller address to `recipient`
    * @param recipient Address where we are sending to
    * @param amount Amount of tokens to send
    * @return bool Returns true if transfer was successful
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @dev Sends `amount` of token from `sender` to `recipient`
    * @param sender Address from which we send
    * @param recipient Address where we are sending to
    * @param amount Amount of tokens to send
    * @return bool Returns true if transfer was successful
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transferWithFee(sender, recipient, amount);
        return true;
    }

    /// @notice mint tokens for given wallets
    /// @param accounts Array of wallets
    /// @param amounts Amount of tokens to mint to each wallet
    function mint(address[] memory accounts, uint256[] memory amounts) public returns (bool) {
        require(_canMint, "PropToken: Minting is not enabled!");
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)) || _mintContract == msg.sender, "PropToken: you don't have permission to mint");
        require(accounts.length == amounts.length, "PropToken: Arrays must be of same length!");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(totalSupply().add(amounts[i]) <= _cap, "PropToken: cap exceeded");
            require(PropTokenHelpers(getDataAddress()).canTransferPropTokensTo(accounts[i], address(this)), "PropToken: Wallet is not whitelisted");
            _mint(accounts[i], amounts[i]);
        }
        return true;
    }

    /// @notice burn and mint at he same time
    /// @param from Address from which we burn
    /// @param to Address to which we mint
    /// @param amount Amount of tokens to burn and mint
    function burnAndMint(address from, address to, uint256 amount) public onlySystemAdmin returns (bool) {
        _burn(from, amount);
        _mint(to, amount);
        return true;
    }

    function contractBurn(address user, uint256 amount) public returns (bool) {
        require(msg.sender == _burnContract, "PropToken: Only burn contract can burn tokens from users!");
        _burn(user, amount);
        return true;
    }

    /// @notice You need permission to call this function
    function freezeToken() public onlyPropManager {
        PropTokenHelpers(getDataAddress()).freezeProperty(address(this));
    }


    /// @notice You need permission to call this function
    function unfreezeToken() public onlyPropManager {
        PropTokenHelpers(getDataAddress()).unfreezeProperty(address(this));
    }

    /// @notice set contract that is allowed to mint
    /// @param mintContract Address of contract that is allowed to mint
    function setMintContract(address mintContract) public onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isContractWhitelisted(mintContract), "PropToken: Contract is not whitelisted");
        _mintContract = mintContract;
    }

    /// @notice set contract that is allowed to burn
    /// @param burnContract Address of contract that is allowed to burn
    function setBurnContract(address burnContract) public onlyPropManager {
        require(PropTokenHelpers(getDataAddress()).isContractWhitelisted(burnContract), "PropToken: Contract is not whitelisted");
        _burnContract = burnContract;
    }

    /// @notice set this contract into minting mode
    function allowMint() public {
        require(PropTokenHelpers(getDataAddress()).isCPAdminOfProperty(msg.sender, address(this)), "PropToken: Only CP admin!");
        _canMint = true;
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "PropToken: transfer from the zero address");
        require(recipient != address(0), "PropToken: transfer to the zero address");
        require(!PropTokenHelpers(getDataAddress()).isPropTokenFrozen(address(this)), "PropToken: Transactions are frozen");
        address blocksquare = PropTokenHelpers(getDataAddress()).getBlocksquareAddress();
        address cp = PropTokenHelpers(getDataAddress()).getCPOfProperty(address(this));

        if (PropTokenHelpers(getDataAddress()).hasSystemAdminRights(sender) || recipient == getOceanPointContract() || recipient == _burnContract) {
            _transfer(sender, recipient, amount);
        }
        else if (recipient == blocksquare || recipient == cp || recipient == owner()) {
            _transfer(sender, recipient, amount);
        }
        else {
            require(PropTokenHelpers(getDataAddress()).canTransferPropTokensTo(recipient, address(this)), "PropToken: Can't send tokens to!");
            if (sender == blocksquare || sender == cp || sender == owner()) {
                _transfer(sender, recipient, amount);
            }
            else {
                _fee(sender, recipient, amount, blocksquare, cp);
            }
        }
    }

    function _fee(address sender, address recipient, uint256 amount, address blocksquare, address cp) private {
        uint256 blocksquareFee = (amount.mul(PropTokenHelpers(getDataAddress()).getBlocksquareFee())).div(1000);
        uint256 liFee = (amount.mul(PropTokenHelpers(getDataAddress()).getLicencedIssuerFee())).div(1000);
        uint256 cpFee = (amount.mul(PropTokenHelpers(getDataAddress()).getCertifiedPartnerFee())).div(1000);

        uint256 together = blocksquareFee.add(liFee).add(cpFee);

        _transfer(sender, blocksquare, blocksquareFee);
        _transfer(sender, cp, cpFee);
        _transfer(sender, owner(), liFee);

        _transfer(sender, recipient, amount.sub(together));
    }

    function getDataAddress() internal view returns (address) {
        return PropTokenHelpers(_propertyRegistry).getDataProxy();
    }

    /// @notice gets maximum number of tokens that can be created
    function cap() public view returns (uint256) {
        return _cap;
    }

    /// @notice check if this property can be minted
    function canBeMinted() public view returns (bool) {
        return _canMint;
    }

    /// @notice retrieves address of contract that is allowed to mint
    function getMintContract() public view returns (address) {
        return _mintContract;
    }

    /// @notice retrieves address of contract that is allowed to burn
    function getBurnContract() public view returns (address) {
        return _burnContract;
    }

    /// @notice retrieves ocean point contract address
    function getOceanPointContract() public view returns (address) {
        return PropTokenHelpers(getDataAddress()).getOceanPointContract();
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"}}