{"IERC20.sol":{"content":"pragma solidity >= 0.6.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external;
  function burn(uint256 amount) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"ownable.sol":{"content":"pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
"},"synsales.sol":{"content":"pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

contract synSales is Owned {
  using SafeMath for uint256;

  constructor() public {
    SYN = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    maxSYN = 2 * 10**6 * 10**18;
    initPrice = 101089 * 10**10;
    maxPriceInc = 2 * 10**15;
    maxETH = maxSYN.mul(initPrice).div(10**18)
              .add(maxSYN.mul(maxPriceInc).div(2 * 10**18));
  }

  event userBuy(
      address account,
      uint256 syn,
      uint256 eth,
      uint256 date
  );
  event userWithdraw(
      address account,
      uint256 syn
  );

  struct buyStruct {
    uint256 syn;
    uint256 date;
    bool withdrawn;
  }

  IERC20 public SYN;
  uint256 public maxSYN;
  uint256 public maxETH;
  uint256 public initPrice;
  uint256 public maxPriceInc;

  mapping(address => uint256) public userNonce;
  mapping(address => mapping(uint256 => buyStruct)) public userBuys;

  uint256 public synSold;
  uint256 public ethPaid;

  function buy(uint256 maxPrice) public payable {
    require(msg.value > 0);
    uint256 eth = msg.value;
    uint256 buyPrice = getBuyPrice(eth);
    require(maxPrice >= buyPrice);
    uint256 syn = eth.mul(1 ether).div(buyPrice);
    uint256 date = block.timestamp.add(1 weeks);
    userBuys[msg.sender][userNonce[msg.sender]].syn = syn;
    userBuys[msg.sender][userNonce[msg.sender]].date = date;

    require(maxSYN >= synSold.add(syn));
    synSold = synSold.add(syn);
    ethPaid = ethPaid.add(eth);

    userNonce[msg.sender] += 1;

    emit userBuy(msg.sender, syn, eth, date);
  }

  function withdraw(uint256[] memory nonces) public returns(uint256) {
    for(uint256 i = 0; i < nonces.length; i++) {
      if(userBuys[msg.sender][nonces[i]].date <= block.timestamp && userBuys[msg.sender][nonces[i]].date != 0){
        if(userBuys[msg.sender][nonces[i]].withdrawn == false){
          userBuys[msg.sender][nonces[i]].withdrawn = true;
          SYN.transfer(msg.sender, userBuys[msg.sender][nonces[i]].syn);
        }
      }
    }
    return(block.timestamp);
  }

  function getBuyPrice(uint256 eth) public view returns(uint256) {
    uint256 p1 = ethPaid.mul(maxPriceInc).div(maxETH);
    uint256 p2 = ethPaid.add(eth).mul(maxPriceInc).div(maxETH);
    return(p1.add(p2).div(2).add(initPrice));
  }

  function tokenremove(IERC20 token, uint256 amount) public onlyOwner() {
    require(token != SYN);
    token.transfer(msg.sender, amount);
  }

  function ethremove() public onlyOwner() {
    address payable owner = msg.sender;
    owner.transfer(address(this).balance);
  }

}
"}}