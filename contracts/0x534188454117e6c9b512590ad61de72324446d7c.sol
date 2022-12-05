{"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}"},"VaultERC.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract VaultERC {

    address private _owner;

    mapping(address => uint) _totalSupply;
    mapping(address => mapping(address => uint)) balances;
    mapping(address => mapping(address => uint)) _principal;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function totalSupply(address token) public view returns (uint) {
        return _totalSupply[token];
    }

    function balanceOf(address token, address account) public view returns (uint) {
        return balances[token][account];
    }
    
    function principalOf(address token, address account) public view returns (uint) {
        return _principal[token][account];
    }

    function deposit(address token, uint amount) public returns (bool success) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token][msg.sender] = SafeMath.safeAdd(balances[token][msg.sender], amount);
        _totalSupply[token] = SafeMath.safeAdd(_totalSupply[token], amount);
        return true;
    }

    function withdraw(address token, uint amount) public onlyOwner returns (bool success) {
        require(amount != 0, "Amount must be greater than zero");
        require (amount <= _totalSupply[token], "Amount must be less than total supply");
        IERC20(token).transfer(_owner, amount);
        _totalSupply[token] = SafeMath.safeSub(_totalSupply[token], amount);
        return true;
    }
    
    function increasesPrincipal(address token, address account, uint amount) public onlyOwner returns (bool success) {
        require(account != address(0), "BEP20: deposit from the zero address");
        _principal[token][account] = SafeMath.safeAdd(_principal[token][account], amount);
        return true;
    }
    
    function withdrawUnderlying(address token, uint amount) public returns (bool success) {
        require(amount != 0, "Amount must be greater than zero");
        require (amount <= _totalSupply[token], "Amount must be less than total supply");
        require (amount <= _principal[token][msg.sender], "Amount must be less than principal sender");
        IERC20(token).transfer(msg.sender, amount);
        _totalSupply[token] = SafeMath.safeSub(_totalSupply[token], amount);
        _principal[token][msg.sender] = SafeMath.safeSub(_principal[token][msg.sender], amount);
        return true;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

library SafeMath {

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}
"}}