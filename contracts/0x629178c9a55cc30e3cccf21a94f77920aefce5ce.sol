{"ConfinaleToken.sol":{"content":"pragma solidity >=0.5.16 <0.7.0;

import "./ERC20.sol";
import "./Latency.sol";

contract ConfinaleToken is ERC20 {
    string  public name = "Confinale Token";
    string  public symbol = "CNFI";

    //the Latency Contract is managing the value that one is allowed to withdraw
    mapping(address => Latency) _latencyOf;
    address public owner;

    event TransferWei(
        address indexed _from,
        uint256 _value
    );

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    constructor(uint256  _initialSupply) public
    {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    function etherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function modifyTotalSupply(int256 _value) public onlyOwner returns (uint256 New_totalSupply)
    {
        uint256 absValue;
        if (_value<0)
        {
            absValue = uint256(-_value);
            _burn(msg.sender, absValue);
        }
        else
        {
            absValue = uint256(_value);
            _mint(msg.sender, absValue);
        }
        return totalSupply();
    }

    function initialTransfer(address _to, uint256 _value, uint256 _waitingTime) public onlyOwner returns (bool success) {
        require(_to != msg.sender,'you cant transfer token to yourself');
        require(_value>0,'you have to transfer more than zero');
        require(balanceOf(msg.sender) >= _value, 'You have not sufficent Token in our balance');

         if (balanceOf(_to)==0)
        // if( _latencyOf[_to] == Latency(0))
        {
            // we need to initialize the _latencyOf Contract
            _latencyOf[_to] = new Latency();
        }

        _latencyOf[_to].addValueCustomTime(_value, _waitingTime);
        super.transfer(_to, _value);
        return true;
    }

    //the parameter _waitingTime is only needed for the owner
    // for all others the waiting time is computed as an averaged weight of all future times
     function transfer(address _to, uint256 _value) public returns (bool success)
     {
        require(_to != msg.sender,'you cant transfer token to yourself');
        require(_value>0,'you have to transfer more than zero');
        require(super.balanceOf(msg.sender) >= _value, 'You have not sufficent Token in our balance');

        require(super.balanceOf(_to)!=0,"Use initalTransfer to send Token to new addresses");
        require(msg.sender != owner, "The owner must use the initialTransfer function to send Token");

        uint256 steps = _latencyOf[msg.sender].withdrawSteps(_value);
        uint256 amount = 0;

        if (_to != owner)
        {
                uint256 waitingTime = 0;
                if (steps > 0 ) // first in - first out logic
                {
                    // equivalent to:
                    // amount= _latencyOf[msg.sender].withdrawValue(0);
                    // waitingTime=_latencyOf[msg.sender].withdrawTime(0);
                    (waitingTime,amount) = _latencyOf[msg.sender].withdrawTupel(0);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);

                    for (uint i = 1; i<steps; i++)
                    {
                        amount = (_latencyOf[msg.sender].withdrawValue(i)-_latencyOf[msg.sender].withdrawValue(i-1));
                        waitingTime = _latencyOf[msg.sender].withdrawTime(i);
                        _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                    }

                    amount = _value - _latencyOf[msg.sender].withdrawValue(steps-1);
                    waitingTime = _latencyOf[msg.sender].withdrawTime(steps);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                }
                else //the amount is smaller than the first block
                {
                    amount = _value;
                    waitingTime = _latencyOf[msg.sender].withdrawTime(0);
                    _latencyOf[_to].addValueCustomTime(amount,waitingTime);
                }
        }

        _latencyOf[msg.sender].reduceValue(_value);
        super.transfer(_to, _value);

        return true;
    }


    function withdraw(uint256 _AmountConf) public
    {
        require(_AmountConf <= balanceOf(msg.sender),' not sufficient Confinale token to withdraw');
        if (msg.sender != owner)
        {
            require(_latencyOf[msg.sender].withdrawableAmount() >= _AmountConf,' value cant be withdrawn yet - wait longer');
        }

        uint256 value = SafeMath.div(address(this).balance*_AmountConf, totalSupply());
        msg.sender.transfer(value);
        _burn(msg.sender, _AmountConf);

        if (msg.sender != owner)
        {
            _latencyOf[msg.sender].withdraw(_AmountConf);
        }
    }

    //everyone can deposit ether into the contract
    function deposit() public payable
    {
        // nothing else to do!
       // require(msg.value>0); // value is always unsigned -> if someone sends negative values it will increase the balance
        emit TransferWei(msg.sender, msg.value);
    }

    function valueConfinaleToken(uint256 _amountConf) public view returns (uint256 val)
    {
        return SafeMath.div(address(this).balance * _amountConf, totalSupply());
    }

    // optional functions useful for debugging
    function withdrawableAmount(address _addr) public view returns(uint256 value)
    {
        if (balanceOf(_addr)==0) {
            return 0;
        }
        if (_addr != owner)
        {
            return  _latencyOf[_addr].withdrawableAmount();
        }
        else
        {
            return balanceOf(_addr); // the owner can always access its token
        }
    }

    function withdrawSteps(address _addr, uint256 _amount) public view returns (uint256 steps)
    {
        if (balanceOf(_addr)==0) {
            return 0;
        }
        return _latencyOf[_addr].withdrawSteps(_amount);
    }

    function withdrawTupel(address _addr, uint256 _index) public view returns (uint256 holdingPeriod, uint256 token)
    {

        if(_addr==owner){
            if(_index==0){
                return(0, balanceOf(_addr));
            } else {
                return (0,0);
            }
        }
        else
        {
        if (balanceOf(_addr)==0) {
            return (0, 0);
        }
        return _latencyOf[_addr].withdrawTupel(_index);
        }

    }

    function changeOwner(address _newOwner) public onlyOwner returns (bool success)
    {
        uint256 ownerBalance= balanceOf(owner);
        super.transfer(_newOwner, ownerBalance);
        owner=  _newOwner;

        return true;

    }

    // emergency function
    function fixValueDifference (address _address) public onlyOwner
    {
        uint256 balance = balanceOf(_address);
        uint256 steps = _latencyOf[_address].withdrawSteps(balance);
        uint256 maxValue = _latencyOf[_address].withdrawValue(steps);
        if (maxValue < balance)
        {
            _latencyOf[_address].addValueCustomTime(balance - maxValue, 0);
        }
    }

}
"},"Context.sol":{"content":"pragma solidity ^0.5.0;

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
"},"ERC20.sol":{"content":"pragma solidity ^0.5.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
"},"Latency.sol":{"content":"pragma solidity >=0.5.16 <0.7.0;

contract Latency {
  

    struct LatencyPoint
    {
        uint256 time;
        uint256 value;
    }

    LatencyPoint[] public _latencyArray;
    address owner;
     
    constructor ( ) public
    {
        owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "only latency owner allowed");
        _;
    }

    // the value which is incremeted in the struct after the waitingTime
    function addValueCustomTime(uint256 _transferedValue, uint256 _waitingTime)   public onlyOwner
    {
       if(_transferedValue > 0 ) // otherwise there is no need to add a value in the array
        {
            uint256 unlockTime = block.timestamp + _waitingTime;
            bool found = false;
            uint256 index;

            for(uint i = 0; i<_latencyArray.length; i++)
            {
                if (_latencyArray[i].time > unlockTime)
                {
                    index = i;
                    found = true;
                    break;
                }
            }

            if (found)
            {  // we need to shift all the indices
            _latencyArray.push(LatencyPoint(_latencyArray[_latencyArray.length-1].time, _latencyArray[_latencyArray.length-1].value + _transferedValue));

                 for(uint i = _latencyArray.length - 2; i>index; i--)
                 {
                     _latencyArray[i].time = _latencyArray[i-1].time;
                     _latencyArray[i].value = _latencyArray[i-1].value + _transferedValue;
                 }

                 _latencyArray[index].time = unlockTime;

                 if (index>0){
                    _latencyArray[index].value = _latencyArray[index-1].value + _transferedValue;
                 }else
                 {
                    _latencyArray[index].value = _transferedValue;
                 }
            }else
            { // the timestamp is after all the others
                 if (_latencyArray.length>0){
                    _latencyArray.push(LatencyPoint(unlockTime,_latencyArray[_latencyArray.length-1].value + _transferedValue));
                 }
                 else
                 {
                    _latencyArray.push(LatencyPoint(unlockTime, _transferedValue));
                 }
            }
        }
    }

    function withdrawableAmount() public view returns(uint256 value)
    {
        uint i = 0;
        if (_latencyArray.length==0)
        {
            return 0;
        }

        while (i < _latencyArray.length && _latencyArray[i].time < block.timestamp)
        {
          i++;
        }

        if (i==0) // nothing can be taken out
        {
            return 0;
        }
        else
        {
          return _latencyArray[i-1].value;
        }
    }

    function currentTime() public view returns(uint256 time) {
        return block.timestamp;
    }

    function removePoint(uint i) private
    {
        while (i<_latencyArray.length-1)
        {
            _latencyArray[i] = _latencyArray[i+1];
            i++;
        }
        _latencyArray.length--;
    }

    // you need to keep at least the last one such that you know how much you can withdraw
    function removePastPoints() private
    {
        uint i = 0;
        while (i < _latencyArray.length && _latencyArray[i].time < block.timestamp)
        {
            i++;
        }
        if (i==0) // everything is still in the future
        {
            //_latencyArray.length=0;
        }
        else if (i == _latencyArray.length) // then we need to keep the last entry
        {
          _latencyArray[0] = _latencyArray[i-1];
          _latencyArray.length = 1;
        }
        else // i is the first item that is bigger -> so we need to keep all the coming ones
        {
            i--; // you need to keep the last entry of the past if its not zero
            uint j = 0;
            while (j<_latencyArray.length-i)
            {
              _latencyArray[j] = _latencyArray[j+i];
              j++;
            }
            _latencyArray.length = _latencyArray.length-i;
        }
    }

    // you need to keep at least the last one such that you know how much you can withdraw
    function removeZeroValues() private
    {
        uint i = 0;
        while (i < _latencyArray.length && _latencyArray[i].value == 0)
        {
            i++;
        }
        if (i==0) // everything is still in the future
        {
            //_latencyArray.length=0;
        }
        else if (i == _latencyArray.length) // then we need to keep the last entry
        {
          _latencyArray[0] = _latencyArray[i-1];
          _latencyArray.length = 1;
        }
        else // i is the first item that is not zero -> so we need to keep from i on all values  all the coming ones
        {
            //i--; // you need to keep the last entry of the past if its not zero
            uint j=0;
            while (j<_latencyArray.length-i)
            {
                _latencyArray[j] = _latencyArray[j+i];
                j++;
            }
            _latencyArray.length = _latencyArray.length-i;
        }
    }

    function withdraw(uint256 _value) public onlyOwner
    {
        require (withdrawableAmount() >= _value,'you cant withdraw that amount at this moment');
        removePastPoints();
        removeZeroValues();
        for(uint i=0; i<_latencyArray.length; i++)
        {
            _latencyArray[i].value -= _value;
        }
    }

    //if you transfer token from one address to the other you reduce the total amount
    function reduceValue(uint256 _value) public onlyOwner
    {
        removePastPoints();

        for(uint i=0; i<_latencyArray.length; i++)
        {
            if(_latencyArray[i].value<_value)
            {
                _latencyArray[i].value = 0;
            }
            else
            {
                _latencyArray[i].value -= _value;
            }
        }
        removeZeroValues(); //removes zero values form the array
    }

    // returns the first point that is strictly larger than the amount
    function withdrawSteps(uint256 _amount) public view returns (uint256 Steps)
    {
        uint256 steps = 0;
        // we need the first index, that is larger or euqal to the amount
        for(uint i = 0;i<_latencyArray.length;i++)
        {
            steps = i;
            if(_latencyArray[i].value > _amount)
            {
                break;
            }

        }
        return steps;
    }

    function withdrawTupel(uint256 _index) public view returns (uint256 Time, uint256 Val)
    {
        if(_index < _latencyArray.length)
        {
            if (_latencyArray[_index].time>block.timestamp)
            {
                return (_latencyArray[_index].time-block.timestamp, _latencyArray[_index].value) ;
            }
            else // time is already in the past
            {
                return (0,_latencyArray[_index].value) ;
            }
        } else //index out of range
        {
            return (0,0);
        }
    }


    function withdrawTime(uint256 _index) public view returns (uint256 Time)
    {
        if(_index < _latencyArray.length)
        {
            if (_latencyArray[_index].time>block.timestamp)
            {
                return _latencyArray[_index].time-block.timestamp;
            }
            else // time is already in the past
            {
                return 0;
            }
        }
        else //index out of range 
        {
            return 0;
        }
    }

    function withdrawValue(uint256 _index) public view returns (uint256 Value){
        if(_index < _latencyArray.length)
        {
            return _latencyArray[_index].value;
        }
        else
        {
            return 0;
        }
    }

}"},"Migrations.sol":{"content":"pragma solidity >=0.4.21 <0.7.0;

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
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"}}