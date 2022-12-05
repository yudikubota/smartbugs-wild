{"ERC20_base.sol":{"content":"// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;
 import "./STVKE_lib.sol";

contract ERC20_base is Context {

    using SafeMath for uint256;
    using Address for address;


    struct FEES {
    uint256  _burnOnTX;
    uint256  _feeOnTX;
    address  _feeDest;
    }
    FEES private Fees;
    

    struct BURNMINT {
    bool  _burnable;
    bool  _mintable;
    uint256 _cappedSupply;
    }
    BURNMINT private BurnMint;

    struct GOV {
    address  _owner;
    bool  _basicGovernance;
    uint256  _noTransferTimeLock;  //transfers KO before this time
    }
    GOV private Gov;
    
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

//Events

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

    event Log(string log);
    
//ERC20 MODIFIERS
    modifier onlyOwner() {
        require(Gov._owner == msg.sender, "onlyOwner");
        _;
    }


//Constructor
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol, uint8 decimals, 
                uint256 supply, address mintDest,
                uint256 BurnMintGov, uint256 burnOnTX,
                uint256 cappedSupply,
                uint256 feeOnTX, address feeDest,
                uint256 noTransferTimeLock,
                address owner) public {
        
        
        //ERC20
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
        //FEES
              
        Fees._feeOnTX = feeOnTX; //base 10000
        Fees._feeDest = feeDest;
        if(feeOnTX >  0){require(feeDest != address(0), "fee cannot be sent to 0x0");}
        
        
        //BURN-MINT-GOV
        
        //BurnMintGov = 000, 001, 101...
        uint256 _remainder;
        if(BurnMintGov >= 100){ 
            BurnMint._burnable = true;
            _remainder = BurnMintGov.sub(100);
        }

        
        if(BurnMintGov >= 10){ 
            BurnMint._mintable = true;
            _remainder = BurnMintGov.sub(10);
        }

        if(BurnMintGov >= 1){ Gov._basicGovernance = true;}


        Fees._burnOnTX = burnOnTX; //base 10000, 0.01% = 1
        if(!BurnMint._burnable){Fees._burnOnTX = 0;} //avoid users to create non burnable tokens with a burnOnTX
        

        BurnMint._cappedSupply = cappedSupply;
  
        //GOV
        Gov._owner = owner;
        Gov._noTransferTimeLock = noTransferTimeLock.add(block.timestamp);
        
        //mints!!
        if(mintDest == address(0)){mintDest = msg.sender;}
        
        //low level mint for token creation
        require(mintDest != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(supply);
        _balances[mintDest] = _balances[mintDest].add(supply);
        emit Transfer(address(0), mintDest, supply); //minted event.
    }

//Public Functions
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
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
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


//Internal Functions
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

        require(block.timestamp > Gov._noTransferTimeLock, "Transfers blocked for the moment");
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 _fee = 0; uint256 _burnFee = 0;
        
        if(Fees._feeOnTX > 0){
            _fee = amount.mul(Fees._feeOnTX).div(10000);
            _balances[sender] = _balances[sender].sub(_fee, "ERC20: transfer amount exceeds balance");
            _balances[Fees._feeDest] = _balances[Fees._feeDest].add(_fee);
            emit Transfer(sender,Fees._feeDest,_fee);
        }
        if(Fees._burnOnTX > 0){
            _burnFee = amount.mul(Fees._burnOnTX).div(10000);
            _burn(sender, _burnFee); //only if _burnable = true
        }
        
        
        uint256 netAmount = amount.sub(_fee).sub(_burnFee);
        _balances[sender] = _balances[sender].sub(netAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(netAmount);
        
        emit Transfer(sender, recipient, netAmount);
    }  


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     * - cannot exceed 'capped supply'.
     * - token must be 'mintable'.
     * - must be sent by 'owner'.
     */
    function mint(uint256 amount) external virtual onlyOwner {
        require(BurnMint._mintable, "token NOT mintable");
        require(_totalSupply.add(amount) <= BurnMint._cappedSupply || BurnMint._cappedSupply == 0);
        require(_msgSender() != address(0), "ERC20: mint to the zero address");
        
        _mint(_msgSender(), amount);
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
        require(BurnMint._mintable, "token NOT mintable");
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
        require(BurnMint._burnable, "token NOT burnable");
        
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns(uint256 netAmount) {
    }

//basic Governance & getters

function setBurnFee(uint256 _newFee) public onlyOwner {
    require(_newFee <= 2000, "Max burnFee capped at 20%");
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._burnOnTX = _newFee;
}
function viewBurnOnTX() public view returns(uint256){
    return Fees._burnOnTX;
}

function setFee(uint256 _newFee) public onlyOwner{
    require(_newFee <= 2000, "Max Fee capped at 20%");
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._feeOnTX = _newFee;
}
function viewFeeOnTX() public view returns(uint256){
    return Fees._feeOnTX;
}

function setFeeDest(address feeDest) external onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    Fees._feeDest = feeDest;
}
function viewFeeDest() public view returns(address){
    return Fees._feeDest;
}

function setOwnerShip(address _address) public onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    require(Gov._owner != address(0));
    Gov._owner = _address;
}

function revokeOwnerShip() public onlyOwner {
    require(Gov._basicGovernance, "Basic governance not enabled");
    Gov._owner = address(0);
}

function viewIfBurnable() public view returns(bool) {
    return BurnMint._burnable;   
}

function viewIfMintable() public view returns(bool) {
    return BurnMint._mintable;
}

function revokeMinting() public onlyOwner {
    require(BurnMint._mintable, "Minting not enabled");
    BurnMint._mintable = false;
}

function viewCappedSupply() public view returns(uint256) {
    return BurnMint._cappedSupply;
}

function viewOwner() public view returns(address) {
    return Gov._owner;
}
    
} "},"STVKE_lib.sol":{"content":"// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        assembly { codehash := extcodehash(account) }
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

}
"},"STVKE_token.sol":{"content":"// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;

import "./ERC20_base.sol";

interface UniswapV2Router02 {
    
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external payable;
}

contract STVKE is ERC20_base {

    using SafeMath for uint256;

    uint256 private price;
    uint256 private STVrequirement;
    uint256 private byPassPrice;
    address private treasury;
    
    address public WETH;
    address public STV;
    address[] public path;
 
    uint256 private _STVKESupply = uint256(5000000).mul(1e18); //100k tokens
    
    UniswapV2Router02 internal constant uniswap = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    event TokenGenerated(address account, uint256 supply, string name, string symbol, uint8 decimals);
    event BuyBack(uint ethAmount);

    
    constructor() public 
    ERC20_base("STVKE", "STV", 18,
                _STVKESupply, msg.sender, 
                101, 0,
                _STVKESupply,
                10, msg.sender,
                1 minutes,
                msg.sender)
    {
        treasury = msg.sender;
        price = 1e17;
        STVrequirement = uint256(100).mul(1e18);
        byPassPrice = uint256(10000).mul(1e18);
        WETH = UniswapV2Router02(uniswap).WETH();
        STV = address(this);
        path.push(WETH);
        path.push(STV);

    }
    
    
    function createToken(string memory name, string memory symbol, uint8 decimals, 
                uint256 supply, address mintDest,
                uint256 BurnMintGov, uint256 burnOnTX,
                uint256 cappedSupply,
                uint256 feeOnTX, address feeDest,
                uint256 noTransferTime,
                address owner) public payable {
         require(balanceOf(msg.sender) >= STVrequirement);
         require(balanceOf(msg.sender) >= byPassPrice || msg.value >= price);
         require(BurnMintGov <= 111);



        if(owner == address(0)){owner = msg.sender;}          
        
        
        address tokenAddress = address(new ERC20_base(name, symbol, decimals, 
                supply, mintDest,
                BurnMintGov, burnOnTX,
                cappedSupply,
                feeOnTX, feeDest,
                noTransferTime,
                owner));
                
                
        emit TokenGenerated(tokenAddress, supply, name, symbol, decimals);
                
    buyBack();
                
    }
    
    function buyBack() internal {
        if (STV.balance > 0.5 ether) {
            uint amountIn = STV.balance.sub(0.2 ether);
        emit BuyBack(amountIn);
            uint amountOutMin = 0;
            UniswapV2Router02(uniswap).swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(
                    amountOutMin, path, treasury, now.add(24 hours));
        }   
    }
    
    // function burn() external onlyOwner {
    //     _burn(treasury, balanceOf(treasury).sub(4));
    // }
    
    function setTreasury(address _address) public onlyOwner {
        treasury = _address;
    }
    function viewTreasury() public view returns(address) {
        return treasury;
    }
    function setSTVrequirement(uint256 _STVrequirement) public onlyOwner {
        STVrequirement = _STVrequirement;
    }
    function viewSTVrequirement() public view returns(uint256) {
        return STVrequirement;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function viewPrice() public view returns(uint256) {
        return price;
    }
    function setByPassPrice(uint256 _price) public onlyOwner {
        byPassPrice = _price;
    }
    function viewBypassPrice() public view returns(uint256) {
        return byPassPrice;
    }
}
"}}