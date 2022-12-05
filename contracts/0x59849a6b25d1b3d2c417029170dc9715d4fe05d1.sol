{"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
}"},"SwappingETH.sol":{"content":"// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import './IERC20.sol';
contract swappingEth{
    struct swappedTransaction{
        uint amount;
        uint tax;
        address sender;
        address receiver;
    }
    IERC20 public token;
    address public authorizedAccount;
    mapping(uint => swappedTransaction) transactions;
    uint totalTransactions;
    
    constructor(address _token,address _authorizedAccount){
        token = IERC20(_token);
        authorizedAccount = _authorizedAccount;
    }

    modifier onlyAuthorizedAccount(address withdrawer){
        require(authorizedAccount == withdrawer,'Only Authorized Account can submit a withdraw request');
        _;
    }
    modifier validTransaction(uint index, address transactionInitiator){
        require(index <= totalTransactions, "Invalid Transaction ID");
        _;
    }
    
    event fundingReciept(uint256 index);

    event refunded(uint256 index);

    function fund(uint _amount,uint _tax,address reciever) external payable returns(uint currentIndex){
        require(token.balanceOf(msg.sender)>= _amount,"Not Enough Balance to complete this transaction");
        // require(token.approve(address(this), _amount),"Approve Failed Try Again");
        swappedTransaction memory newTransaction = swappedTransaction(_amount,_tax,msg.sender,reciever);
        transactions[totalTransactions] = newTransaction;
        require(token.transferFrom(msg.sender,address(this),_amount),"Could not process the transaction try again");
        emit fundingReciept(totalTransactions);
        totalTransactions = totalTransactions + 1;
        return totalTransactions;
    }

    function refund(uint index) validTransaction(index,msg.sender) onlyAuthorizedAccount(msg.sender) public{
        require(token.transfer(transactions[totalTransactions].sender, transactions[totalTransactions].amount),"Transaction Failed");
        emit refunded(index);
    }
    // Removing onlyAuthorized Restriction
    function withdraw(uint _amount, address reciever) onlyAuthorizedAccount(msg.sender) public{
        token.transfer(reciever, _amount);
    }

    function getCurrentIndex() external view returns (uint256 index){
        return totalTransactions;        
    }
    // works fine
    function withDrawTax(address payable to) onlyAuthorizedAccount(msg.sender) public{
        to.transfer(address(this).balance);
    }
    // Withdraws xDNA FUNCTIOn
    function withDrawxDNA(address to,uint256 amount) onlyAuthorizedAccount(msg.sender) public{
       require(token.transfer(to, amount),"TRANSACTION FAILED WHEN TRANSFERING XDNA");
    }

    function getTransaction(uint index) external view returns (swappedTransaction memory transaction){
        require(index >= 0 && index <= totalTransactions,"Invalid Index");
        return transactions[index];        
    }
}"}}