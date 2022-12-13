{"multisend.sol":{"content":"pragma solidity ^0.4.24;

import './SafeMath.sol';
import './Ownable.sol';

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multisend is Ownable {
    using SafeMath for uint256;

    uint256 public fee;
    uint256 public arrayLimit;
    
    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Refund(uint256 _refund);
    event Payload(string _payload);
    event Withdraw(address _owner, uint256 _balance);

    constructor(uint256 _fee,uint256 _arrayLimit) public {
        fee = _fee; 
        arrayLimit = _arrayLimit;
    }
    
    function sendCoin(address[] recipients, uint256[] amounts, string payload) public payable{
        require(recipients.length == amounts.length);
        require(recipients.length <= arrayLimit);
        uint256 totalAmount = fee;
        for(uint256 i = 0; i < recipients.length; i++) {
            totalAmount = SafeMath.add(totalAmount, amounts[i]);
        }
        require(msg.value >= totalAmount);
        uint256 refund = SafeMath.sub(msg.value, totalAmount);
        for(i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
            emit Transfer(msg.sender, recipients[i],amounts[i]);
        }
        if (refund > 0) {
            msg.sender.transfer(refund);
            emit Refund(refund);
        }
        emit Payload(payload);
    }

    function sendToken(address token, address[] recipients, uint256[] amounts, string payload) public payable {
        require(msg.value >= fee);
        require(recipients.length == amounts.length);
        require(recipients.length <= arrayLimit);
        ERC20 erc20token = ERC20(token);
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
        uint256 refund = SafeMath.sub(msg.value, fee);
        if (refund > 0) {
            msg.sender.transfer(refund);
            emit Refund(refund);
        }
        emit Payload(payload);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(owner, balance);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setArrayLimit(uint256 _arrayLimit) public onlyOwner {
        arrayLimit = _arrayLimit;
    }
}
"},"Ownable.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  /*@CTK owner_set_on_success
    @pre __reverted == false -> __post.owner == owner
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  /*@CTK transferOwnership
    @post __reverted == false -> (msg.sender == owner -> __post.owner == newOwner)
    @post (owner != msg.sender) -> (__reverted == true)
    @post (newOwner == address(0)) -> (__reverted == true)
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
"},"SafeMath.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
"}}