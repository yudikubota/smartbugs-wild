{"ERC20.sol":{"content":"// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed require messages to save space
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass

pragma solidity >=0.8;

import "./IERC20.sol";
import "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

abstract contract ERC20 is IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint8 public override decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
        bool success = transfer(recipient, amount);
        if (success){
            IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        require(recipient != address(0));

        _beforeTokenTransfer(address(0), recipient, amount);

        _totalSupply += amount;
        _balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal;
}"},"ERC20Recoverable.sol":{"content":"/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "./ERC20.sol";
import "./IERC20.sol";

/**
 * @title Recoverable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function to post a deposit and claim that the shares assigned to a specific address are
 * lost. To prevent front running, a commit reveal scheme is used. If he actually is the owner of the shares,
 * he needs to wait for a certain period and can then reclaim the lost shares as well as the deposit.
 * If he is an attacker trying to claim shares belonging to someone else, he risks losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function.
 */

abstract contract ERC20Recoverable is ERC20 {

    // A struct that represents a claim made
    struct Claim {
        address claimant; // the person who created the claim
        uint256 collateral; // the amount of collateral deposited
        uint256 timestamp;  // the timestamp of the block in which the claim was made
        address currencyUsed; // The currency (XCHF) can be updated, we record the currency used for every request
    }

    uint256 public claimPeriod = 180 days; // Default of 180 days;

    mapping(address => Claim) public claims; // there can be at most one claim per address, here address is claimed address
    mapping(address => bool) public recoveryDisabled; // disable claimability (e.g. for long term storage)

    // ERC-20 token that can be used as collateral or 0x0 if disabled
    address public customCollateralAddress;
    uint256 public customCollateralRate;

    /**
     * Returns the collateral rate for the given collateral type and 0 if that type
     * of collateral is not accepted. By default, only the token itself is accepted at
     * a rate of 1:1.
     *
     * Subclasses should override this method if they want to add additional types of
     * collateral.
     */
    function getCollateralRate(address collateralType) public virtual view returns (uint256) {
        if (collateralType == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

    /**
     * Allows subclasses to set a custom collateral besides the token itself.
     * The collateral must be an ERC-20 token that returns true on successful transfers and
     * throws an exception or returns false on failure.
     * Also, do not forget to multiply the rate in accordance with the number of decimals of the collateral.
     * For example, rate should be 7*10**18 for 7 units of a collateral with 18 decimals.
     */
    function _setCustomClaimCollateral(address collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (customCollateralAddress == address(0)) {
            customCollateralRate = 0; // disabled
        } else {
            require(rate > 0, "Collateral rate can't be zero");
            customCollateralRate = rate;
        }
        emit CustomClaimCollateralChanged(collateral, rate);
    }

    function getClaimDeleter() virtual public view returns (address);

    /**
     * Allows subclasses to change the claim period, but not to fewer than 90 days.
     */
    function _setClaimPeriod(uint256 claimPeriodInDays) internal {
        require(claimPeriodInDays > 90, "Claim period must be at least 90 days"); // must be at least 90 days
        uint256 claimPeriodInSeconds = claimPeriodInDays * (1 days);
        claimPeriod = claimPeriodInSeconds;
        emit ClaimPeriodChanged(claimPeriod);
    }

    function setRecoverable(bool enabled) public {
        recoveryDisabled[msg.sender] = !enabled;
    }

    /**
     * Some users might want to disable claims for their address completely.
     * For example if they use a deep cold storage solution or paper wallet.
     */
    function isRecoveryEnabled(address target) public view returns (bool) {
        return !recoveryDisabled[target];
    }

    event ClaimMade(address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimCleared(address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimPeriodChanged(uint256 newClaimPeriodInDays);
    event CustomClaimCollateralChanged(address newCustomCollateralAddress, uint256 newCustomCollareralRate);

  /** Anyone can declare that the private key to a certain address was lost by calling declareLost
    * providing a deposit/collateral. There are three possibilities of what can happen with the claim:
    * 1) The claim period expires and the claimant can get the deposit and the shares back by calling recover
    * 2) The "lost" private key is used at any time to call clearClaim. In that case, the claim is deleted and
    *    the deposit sent to the shareholder (the owner of the private key). It is recommended to call recover
    *    whenever someone transfers funds to let claims be resolved automatically when the "lost" private key is
    *    used again.
    * 3) The owner deletes the claim and assigns the deposit to the claimant. This is intended to be used to resolve
    *    disputes. Generally, using this function implies that you have to trust the issuer of the tokens to handle
    *    the situation well. As a rule of thumb, the contract owner should assume the owner of the lost address to be the
    *    rightful owner of the deposit.
    * It is highly recommended that the owner observes the claims made and informs the owners of the claimed addresses
    * whenever a claim is made for their address (this of course is only possible if they are known to the owner, e.g.
    * through a shareholder register).
    * To prevent frontrunning attacks, a claim can only be made if the information revealed when calling "declareLost"
    * was previously commited using the "prepareClaim" function.
    */
    function declareLost(address collateralType, address lostAddress) public {
        require(isRecoveryEnabled(lostAddress), "Claims disabled for this address");
        uint256 collateralRate = getCollateralRate(collateralType);
        require(collateralRate > 0, "Unsupported collateral");
        address claimant = msg.sender;
        uint256 balance = balanceOf(lostAddress);
        uint256 collateral = balance * collateralRate;
        IERC20 currency = IERC20(collateralType);
        require(balance > 0, "Claimed address holds no shares");
        require(claims[lostAddress].collateral == 0, "Address already claimed");
        require(currency.transferFrom(claimant, address(this), collateral), "Collateral transfer failed");

        claims[lostAddress] = Claim({
            claimant: claimant,
            collateral: collateral,
            timestamp: block.timestamp,
            currencyUsed: collateralType
        });

        emit ClaimMade(lostAddress, claimant, balance);
    }

    function getClaimant(address lostAddress) public view returns (address) {
        return claims[lostAddress].claimant;
    }

    function getCollateral(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].collateral;
    }

    function getCollateralType(address lostAddress) public view returns (address) {
        return claims[lostAddress].currencyUsed;
    }

    function getTimeStamp(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].timestamp;
    }

    function transfer(address recipient, uint256 amount) override virtual public returns (bool) {
        require(super.transfer(recipient, amount), "Transfer failed");
        clearClaim();
        return true;
    }

    /**
     * Clears a claim after the key has been found again and assigns the collateral to the "lost" address.
     * This is the price an adverse claimer pays for filing a false claim and makes it risky to do so.
     */
    function clearClaim() public {
        if (claims[msg.sender].collateral != 0) {
            uint256 collateral = claims[msg.sender].collateral;
            IERC20 currency = IERC20(claims[msg.sender].currencyUsed);
            delete claims[msg.sender];
            require(currency.transfer(msg.sender, collateral), "Collateral transfer failed");
            emit ClaimCleared(msg.sender, collateral);
        }
    }

   /**
    * After the claim period has passed, the claimant can call this function to send the
    * tokens on the lost address as well as the collateral to himself.
    */
    function recover(address lostAddress) public {
        Claim memory claim = claims[lostAddress];
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "No claim found");
        require(claim.claimant == msg.sender, "Only claimant can resolve claim");
        require(claim.timestamp + claimPeriod <= block.timestamp, "Claim period not over yet");
        address claimant = claim.claimant;
        delete claims[lostAddress];
        require(currency.transfer(claimant, collateral), "Collateral transfer failed");
        _transfer(lostAddress, claimant, balanceOf(lostAddress));
        emit ClaimResolved(lostAddress, claimant, collateral);
    }

    /**
     * This function is to be executed by the claim deleter only in case a dispute needs to be resolved manually.
     */
    function deleteClaim(address lostAddress) public {
        require(msg.sender == getClaimDeleter(), "You cannot delete claims");
        Claim memory claim = claims[lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "No claim found");
        delete claims[lostAddress];
        require(currency.transfer(claim.claimant, claim.collateral), "Collateral transfer failed");
        emit ClaimDeleted(lostAddress, claim.claimant, claim.collateral);
    }

}"},"IERC20.sol":{"content":"/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity >=0.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}"},"IERC677Receiver.sol":{"content":"// SPDX-License-Identifier: MIT
// Copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol
pragma solidity >=0.8;

interface IERC677Receiver {

    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external;

}"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
//
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//
// Modifications:
// - Replaced Context._msgSender() with msg.sender
// - Made leaner

pragma solidity >=0.8;

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
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}"},"Shares.sol":{"content":"/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "./Ownable.sol";
import "./ERC20Recoverable.sol";
import "./IERC677Receiver.sol";

/**
 * @title CompanyName AG Shares
 * @author Luzius Meisser, luzius@aktionariat.com
 *
 * These tokens are uncertified shares (Wertrechte according to the Swiss code of obligations),
 * with this smart contract serving as onwership registry (Wertrechtebuch), but not as shareholder
 * registry, which is kept separate and run by the company. This is equivalent to the traditional system
 * of having physical share certificates kept at home by the shareholders and a shareholder registry run by
 * the company. Just like with physical certificates, the owners of the tokens are the owners of the shares.
 * However, in order to exercise their rights (for example receive a dividend), shareholders must register
 * with the company. For example, in case the company pays out a dividend to a previous shareholder because
 * the current shareholder did not register, the company cannot be held liable for paying the dividend to
 * the "wrong" shareholder. In relation to the company, only the registered shareholders count as such.
 * Registration requires setting up an account with ledgy.com providing your name and address and proving
 * ownership over your addresses.
 * @notice The main addition is a functionality that allows the user to claim that the key for a certain address is lost.
 * @notice In order to prevent malicious attempts, a collateral needs to be posted.
 * @notice The contract owner can delete claims in case of disputes.
 */
contract Shares is ERC20Recoverable, Ownable {

    string public override name;
    string public override symbol;
    string public terms;

    uint256 public totalShares = 0; // total number of shares, maybe not all tokenized
    uint256 public invalidTokens = 0;

    address[] public subregisters;

    event Announcement(string message);
    event TokensDeclaredInvalid(address indexed holder, uint256 amount, string message);
    event ShareNumberingEvent(address indexed holder, uint256 firstInclusive, uint256 lastInclusive);
    event SubRegisterAdded(address contractAddress);
    event SubRegisterRemoved(address contractAddress);

    constructor(string memory _symbol, string memory _name, string memory _terms, uint256 _totalShares) ERC20(0) {
        setName(_symbol, _name);
        setTotalShares(_totalShares);
        terms = _terms;
    }

    function setName(string memory _symbol, string memory _name) public onlyOwner {
        symbol = _symbol;
        name = _name;
        emit Announcement(string(abi.encodePacked("New name: ", _name, " (", _symbol, ")")));
    }

    function setTerms(string memory _terms) public onlyOwner {
        terms = _terms;
        emit Announcement(string(abi.encodePacked("New terms: ", _terms)));
    }

    /**
     * Declares the number of total shares, including those that have not been tokenized and those
     * that are held by the company itself. This number can be substiantially higher than totalSupply()
     * in case not all shares have been tokenized. Also, it can be lower than totalSupply() in case some
     * tokens have become invalid.
     */
    function setTotalShares(uint256 _newTotalShares) public onlyOwner() {
        require(_newTotalShares >= totalValidSupply(), "There can't be fewer tokens than shares");
        totalShares = _newTotalShares;
    }

    function countSubregisters() public view returns (uint256){
        return subregisters.length;
    }

    /**
     * Sometimes, tokens are held by smart contracts that are ERC20 contracts themselves.
     * For example, some tokens might be held by a smart contract representing a shareholder agreement.
     * In that case, the owners of that sub-contract are the shareholders, and not the contract itself
     * For such cases, having a list of recognized such subregisters might be helpful with the automated
     * registration and tracking of shareholders.
     * We assume that the number of sub registers stays limited, such that they are safe to iterate.
     * Subregisters should always have the same number of decimals as the main register and their total
     * balance must not exceed the number of tokens assigned to the subregister.
     * In order to preserve FIFO-rules meaningfully, subregisters must be empty when added or removed.
     */
    function recognizeSubRegister(address contractAddress) public onlyOwner () {
        require(balanceOf(contractAddress) == 0, "Subregisters must be empty when added");
        subregisters.push(contractAddress);
        emit SubRegisterAdded(contractAddress);
    }

    function removeSubRegister(address contractAddress) public onlyOwner() {
        require(balanceOf(contractAddress) == 0, "Subregisters must be empty when removed");
        for (uint256 i = 0; i<subregisters.length; i++) {
            if (subregisters[i] == contractAddress) {
                subregisters[i] = subregisters[subregisters.length - 1];
                subregisters.pop();
                emit SubRegisterRemoved(contractAddress);
            }
        }
    }

    /**
     * A deep balanceOf operator that also considers indirectly held tokens in
     * recognized sub registers.
     */
    function balanceOfDeep(address holder) public view returns (uint256) {
        uint256 balance = balanceOf(holder);
        for (uint256 i = 0; i<subregisters.length; i++) {
            IERC20 subERC = IERC20(subregisters[i]);
            balance += subERC.balanceOf(holder);
        }
        return balance;
    }

    /**
     * Allows the issuer to make public announcements that are visible on the blockchain.
     */
    function announcement(string calldata message) external onlyOwner() {
        emit Announcement(message);
    }

    function setClaimPeriod(uint256 claimPeriodInDays) public onlyOwner() {
        super._setClaimPeriod(claimPeriodInDays);
    }

    /**
     * See parent method for collateral requirements.
     */
    function setCustomClaimCollateral(address collateral, uint256 rate) public onlyOwner() {
        super._setCustomClaimCollateral(collateral, rate);
    }

    function getClaimDeleter() public override view returns (address) {
        return owner;
    }

    /**
     * Signals that the indicated tokens have been declared invalid (e.g. by a court ruling in accordance
     * with article 973g of the Swiss Code of Obligations) and got detached from
     * the underlying shares. Invalid tokens do not carry any shareholder rights any more.
     *
     * This function is purely declarative. It does not technically immobilize the affected tokens as
     * that would give the issuer too much power.
     */
    function declareInvalid(address holder, uint256 amount, string calldata message) external onlyOwner() {
        uint256 holderBalance = balanceOf(holder);
        require(amount <= holderBalance);
        invalidTokens += amount;
        emit TokensDeclaredInvalid(holder, amount, message);
    }

    /**
     * The total number of valid tokens in circulation. In case some tokens have been declared invalid, this
     * number might be lower than totalSupply(). Also, it will always be lower than or equal to totalShares().
     */
    function totalValidSupply() public view returns (uint256) {
        return totalSupply() - invalidTokens;
    }

    /**
     * Allows the company to tokenize shares. If these shares are newly created, setTotalShares must be
     * called first in order to adjust the total number of shares.
     */
    function mint(address shareholder, uint256 _amount) public onlyOwner() {
        _mint(shareholder, _amount);
    }

    function mintAndCall(address shareholder, address callee, uint256 amount, bytes calldata data) public {
        mint(callee, amount);
        IERC677Receiver(callee).onTokenTransfer(shareholder, amount, data);
    }

    /**
     * Some companies like to number their shares so they can refer to them more explicitely in legal contracts.
     * A minority of Swiss lawyers even believes that numbering shares is compulsory (which is not true).
     * Nonetheless, this function allows to signal the numbers of freshly tokenized shares.
     * In case the shares ever get de-tokenized again, this information might help in deducing their
     * numbers again - although there might be some room for interpretation of what went where.
     * By convention, transfers should be considered FIFO (first in, first out) and transactions in
     * recognized subregisters be taken into account.
     */
    function mintNumbered(address shareholder, uint256 firstShareNumber, uint256 lastShareNumber) public onlyOwner() {
        emit ShareNumberingEvent(shareholder, firstShareNumber, lastShareNumber); // emit mint event before transfer event
        _mint(shareholder, lastShareNumber - firstShareNumber + 1);
    }

    function mintNumberedAndCall(address shareholder, address callee, uint256 firstShareNumber, uint256 lastShareNumber, bytes calldata data) public {
        mintNumbered(shareholder, firstShareNumber, lastShareNumber);
        IERC677Receiver(callee).onTokenTransfer(shareholder, lastShareNumber - firstShareNumber + 1, data);
    }

    function _mint(address account, uint256 amount) internal override {
        require(totalValidSupply() + amount <= totalShares, "There can't be fewer shares than valid tokens");
        super._mint(account, amount);
    }

    /**
     * Transfers _amount tokens to the company and burns them.
     * The meaning of this operation depends on the circumstances and the fate of the shares does
     * not necessarily follow the fate of the tokens. For example, the company itself might call
     * this function to implement a formal decision to destroy some of the outstanding shares.
     * Also, this function might be called by an owner to return the shares to the company and
     * get them back in another form under an according agreement (e.g. printed certificates or
     * tokens on a different blockchain). It is not recommended to call this function without
     * having agreed with the company on the further fate of the shares in question.
     */
    function burn(uint256 _amount) public {
        require(_amount <= balanceOf(msg.sender), "Not enough shares available");
        _transfer(msg.sender, address(this), _amount);
        _burn(address(this), _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal {
    }

}"}}