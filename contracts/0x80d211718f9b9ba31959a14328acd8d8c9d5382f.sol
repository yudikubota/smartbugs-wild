{"ERC20Detailed.sol":{"content":"pragma solidity ^0.5.1;

// Palmes token

import "./IERC20.sol";

contract ERC20Detailed is IERC20 {

    uint8 private _Tokendecimals; 
    string private _Tokenname; 
    string private _Tokensymbol;

constructor(string memory name, string memory symbol, uint8 decimals) public {

   _Tokendecimals = decimals; 
   _Tokenname = name; 
   _Tokensymbol = symbol;
  
   }

   function name() public view returns(string memory) { return _Tokenname; }

   function symbol() public view returns(string memory) { return _Tokensymbol; }

   function decimals() public view returns(uint8) { return _Tokendecimals; } 
    
}

"},"IERC20.sol":{"content":"pragma solidity ^0.5.1;

/**
 * Palmes token
  */
interface IERC20 {
    
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}"},"Owned.sol":{"content":"pragma solidity ^0.5.1;

//Palmes token

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}"},"Palmes.sol":{"content":"pragma solidity ^0.5.1;

//Palmes token

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Owned.sol";
import "./ERC20Detailed.sol";

contract Palmes is ERC20Detailed { 
    
    using SafeMath for uint256; 
    string constant tokenName = "Palmes"; 
    string constant tokenSymbol = "PLM"; 
    uint8 constant tokenDecimals = 6; 
    uint256 _totalSuplly= _initialSupply;
    uint256 _initialSupply = 100000000000;
    
    
     mapping (address => uint256) private _PalmesTokenBalances; 
     mapping (address => mapping (address => uint256)) private _allowed;
//
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) { _mint(msg.sender, _initialSupply); }
           
            function totalSupply() public view returns (uint256) { return _initialSupply; }

            function balanceOf(address owner) public view returns (uint256) { return _PalmesTokenBalances[owner]; }

            function allowance(address owner, address spender) public view returns (uint256) { return _allowed[owner][spender]; }

            function transfer(address to, uint256 value) public returns (bool) { require(value <= _PalmesTokenBalances[msg.sender]); require(to != address(0));
  

   uint256 PalmesIncrease = value.div(1000000);
   uint256 tokensToTransfer = value.add(0);
   
   
   _PalmesTokenBalances[msg.sender] = _PalmesTokenBalances[msg.sender].sub(value);
   _PalmesTokenBalances[msg.sender] = _PalmesTokenBalances[msg.sender].add(value.div(1000000));
   _PalmesTokenBalances[to] = _PalmesTokenBalances[to].add(tokensToTransfer);
  
   _totalSuplly = _initialSupply.add(PalmesIncrease);

   emit Transfer(msg.sender, to, tokensToTransfer);
   emit Transfer(address(0), address(msg.sender), PalmesIncrease);

   return true;
   }

   function multiTransfer(address[] memory receivers, uint256[] memory amounts) public { for (uint256 i = 0; i < receivers.length; i++) { transfer(receivers[i], amounts[i]); } }

   function approve(address spender, uint256 value) public returns (bool) { require(spender != address(0)); 
   _allowed[msg.sender][spender] = value; 
   emit Approval(msg.sender, spender, value); 
   return true; }

   function transferFrom(address from, address to, uint256 value) public returns (bool) { require(value <= _PalmesTokenBalances[from]); 
   require(value <= _allowed[from][msg.sender]); 
   require(to != address(0));

_PalmesTokenBalances[from] = _PalmesTokenBalances[from].sub(value);

   uint256 PalmesIncrease = value.div(1000000);
   uint256 tokensToTransfer = value.add(0);

_PalmesTokenBalances[to] = _PalmesTokenBalances[to].add(tokensToTransfer);
_initialSupply = _initialSupply.add(PalmesIncrease);

_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
_allowed[from][msg.sender] = _allowed[from][msg.sender].add(value.div(1000000));

emit Transfer(from, to, tokensToTransfer);
emit Transfer(address(0), address(msg.sender), PalmesIncrease);

return true;
}

function increaseAllowance(address spender, uint256 addedValue) public returns (bool) { require(spender != address(0)); 
_allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue)); 
emit Approval(msg.sender, spender, _allowed[msg.sender][spender]); return true; }

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) { require(spender != address(0)); 
_allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue)); 
emit Approval(msg.sender, spender, _allowed[msg.sender][spender]); return true; }

function _mint(address account, uint256 amount) internal { require(amount != 0); 
_PalmesTokenBalances[account] = _PalmesTokenBalances[account].add(amount); emit Transfer(address(0), account, amount); }

function create(uint256 amount) external { _create(msg.sender, amount); }

function _create(address account, uint256 amount) internal { require(amount != 0); 
require(amount <= _PalmesTokenBalances[account]);
_totalSuplly = _initialSupply.add(amount); 
_PalmesTokenBalances[account] = _PalmesTokenBalances[account].add(amount); 
emit Transfer(account, address(0), amount); }

function createFrom(address account, uint256 amount) external { require(amount <= _allowed[account][msg.sender]); 
_allowed[account][msg.sender] = _allowed[account][msg.sender].add(amount); 
_create(account, amount); } }"},"SafeMath.sol":{"content":"pragma solidity ^0.5.1;

// Palmes token

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
        require(b > 0);
        uint256 c = a / b;
        
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) { 
        uint256 c = add(a,m); 
        uint256 d = sub(c,1); 
        return mul(div(d,m),m); }
}"}}