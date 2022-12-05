{"SwipeTimeLock.sol":{"content":"pragma solidity ^0.5.0;

import "./SwipeToken.sol";

// ----------------------------------------------------------------------------

// Swipe Tokens Time Lock Contract

// ----------------------------------------------------------------------------

contract SwipeTimeLock is Owned {
    using SafeMath for uint;
    SwipeToken token;
    uint tokenslocked;
    
    // Release 10M tokens time period
    uint[] unlockTimestamps = [
        1596240000,             // 08/01/2020
        1627776000,             // 08/01/2021 
        1659312000,             // 08/01/2022 
        1690848000,             // 08/01/2023 
        1722470400,             // 08/01/2024 
        1754006400              // 08/01/2025
    ];

    constructor(address payable addrToken) public {
        token = SwipeToken(addrToken);
    }
    
    function getLockCount() public view returns (uint) {
        uint lock = 60000000000000000000000000;
        for (uint i = 0; i < 6; i ++) {
            if (now < unlockTimestamps[i]) break;
            lock = lock.sub(10000000000000000000000000);
        }
        
        return lock;
    }
    
    function getLockedTokenAmount() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    
    function withdraw() public onlyOwner returns (uint withdrawed) {
        uint tokenLocked = getLockedTokenAmount();
        uint lockCount = getLockCount();
        
        require(tokenLocked >= lockCount, 'no unlocked tokens');
        uint allowed = tokenLocked.sub(lockCount);
        
        if (token.transfer(msg.sender, allowed)) {
            return allowed;
        }
        
        return 0;
    }
    
        // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () external payable {

        revert();

    }



    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != address(token), 'SXP token is not allowed');

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }
}
"},"SwipeToken.sol":{"content":"pragma solidity ^0.5.0;


// ----------------------------------------------------------------------------

// 'SXP' 'Swipe' token contract

//

// Symbol      : SXP

// Name        : Swipe

// Total supply: 300,000,000.000000000000000000

// Decimals    : 18

// Website     : https://swipe.io


//


// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}



// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

// ----------------------------------------------------------------------------

contract ERC20Interface {

    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}



// ----------------------------------------------------------------------------

// Contract function to receive approval and execute function in one call

//

// Borrowed from MiniMeToken

// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;

}



// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

contract Owned {

    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address newOwner) public onlyOwner {

        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);

    }

}

// ----------------------------------------------------------------------------

// Tokenlock contract

// ----------------------------------------------------------------------------
contract Tokenlock is Owned {
    
    uint8 isLocked = 0;       //flag indicates if token is locked

    event Freezed();
    event UnFreezed();

    modifier validLock {
        require(isLocked == 0);
        _;
    }
    
    function freeze() public onlyOwner {
        isLocked = 1;
        
        emit Freezed();
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;
        
        emit UnFreezed();
    }
}

// ----------------------------------------------------------------------------

// Limit users in blacklist

// ----------------------------------------------------------------------------
contract UserLock is Owned {
    
    mapping(address => bool) blacklist;
        
    event LockUser(address indexed who);
    event UnlockUser(address indexed who);

    modifier permissionCheck {
        require(!blacklist[msg.sender]);
        _;
    }
    
    function lockUser(address who) public onlyOwner {
        blacklist[who] = true;
        
        emit LockUser(who);
    }

    function unlockUser(address who) public onlyOwner {
        blacklist[who] = false;
        
        emit UnlockUser(who);
    }
}


// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and a

// fixed supply

// ----------------------------------------------------------------------------

contract SwipeToken is ERC20Interface, Tokenlock, UserLock {

    using SafeMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint _totalSupply;


    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;



    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    constructor() public {

        symbol = "SXP";

        name = "Swipe";

        decimals = 18;

        _totalSupply = 300000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);

    }



    // ------------------------------------------------------------------------

    // Total supply

    // ------------------------------------------------------------------------

    function totalSupply() public view returns (uint) {

        return _totalSupply.sub(balances[address(0)]);

    }



    // ------------------------------------------------------------------------

    // Get the token balance for account `tokenOwner`

    // ------------------------------------------------------------------------

    function balanceOf(address tokenOwner) public view returns (uint balance) {

        return balances[tokenOwner];

    }



    // ------------------------------------------------------------------------

    // Transfer the balance from token owner's account to `to` account

    // - Owner's account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public validLock permissionCheck returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account

    //

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    // recommends that there are no checks for the approval double-spend attack

    // as this should be implemented in user interfaces

    // ------------------------------------------------------------------------

    function approve(address spender, uint tokens) public validLock permissionCheck returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Transfer `tokens` from the `from` account to the `to` account

    //

    // The calling account must already have sufficient tokens approve(...)-d

    // for spending from the `from` account and

    // - From account must have sufficient balance to transfer

    // - Spender must have sufficient allowance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transferFrom(address from, address to, uint tokens) public validLock permissionCheck returns (bool success) {

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Returns the amount of tokens approved by the owner that can be

    // transferred to the spender's account

    // ------------------------------------------------------------------------

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


     // ------------------------------------------------------------------------
     // Destroys `amount` tokens from `account`, reducing the
     // total supply.
     
     // Emits a `Transfer` event with `to` set to the zero address.
     
     // Requirements
     
     // - `account` cannot be the zero address.
     // - `account` must have at least `amount` tokens.
     
     // ------------------------------------------------------------------------
    function burn(uint256 value) public validLock permissionCheck returns (bool success) {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes memory data) public validLock permissionCheck returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;

    }


    // ------------------------------------------------------------------------
    // Destoys `amount` tokens from `account`.`amount` is then deducted
    // from the caller's allowance.
    
    //  See `burn` and `approve`.
    // ------------------------------------------------------------------------
    function burnForAllowance(address account, address feeAccount, uint256 amount) public onlyOwner returns (bool success) {
        require(account != address(0), "burn from the zero address");
        require(balanceOf(account) >= amount, "insufficient balance");

        uint feeAmount = amount.mul(2).div(10);
        uint burnAmount = amount.sub(feeAmount);
        
        _totalSupply = _totalSupply.sub(burnAmount);
        balances[account] = balances[account].sub(amount);
        balances[feeAccount] = balances[feeAccount].add(feeAmount);
        emit Transfer(account, address(0), burnAmount);
        emit Transfer(account, msg.sender, feeAmount);
        return true;
    }


    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () external payable {

        revert();

    }



    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}
"}}