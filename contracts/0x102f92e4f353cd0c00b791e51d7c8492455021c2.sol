{"contract.sol":{"content":"pragma solidity ^0.7.5;

import "./IERC20.sol";

contract BouncyCoinRefund {

    event Refunded(address addr, uint256 tokenAmount, uint256 ethAmount);

    uint256 public constant MIN_EXCHANGE_RATE = 100000000;

    address payable public owner;

    uint256 public exchangeRate;

    uint256 public totalRefunded;

    IERC20 public bouncyCoinToken; 

    State public state;

    enum State {
        Active,
        Inactive
    }

    /* Modifiers */

    modifier atState(State _state) {
        require(state == _state);
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    /* Constructor */

    constructor(address _bouncyCoinToken, uint256 _exchangeRate)
        public
        payable {
        require(_bouncyCoinToken != address(0));
        require(_exchangeRate >= MIN_EXCHANGE_RATE);

        owner = msg.sender;
        bouncyCoinToken = IERC20(_bouncyCoinToken);
        exchangeRate = _exchangeRate;
        state = State.Inactive;
    }

    /* Public functions */

    fallback() external payable {
        // no-op, just accept ETH        
    }

    function refund(uint256 _tokenAmount)
        public
        atState(State.Active) {

        uint256 toRefund = _tokenAmount / exchangeRate;
        uint256 bal = address(this).balance;

        uint256 tokensToBurn;
        if (toRefund > bal) {
            // not enough ETH in contract, refund all
            tokensToBurn = bal * exchangeRate;
            toRefund = bal;
        } else {
            // we're good
            tokensToBurn = _tokenAmount;
        }

        assert(bouncyCoinToken.transferFrom(msg.sender, address(1), tokensToBurn));
        msg.sender.transfer(toRefund);
        totalRefunded += toRefund;

        emit Refunded(msg.sender, tokensToBurn, toRefund);
    }

    function setExchangeRate(uint256 _exchangeRate)
        public
        isOwner {
        require(_exchangeRate > MIN_EXCHANGE_RATE);

        exchangeRate = _exchangeRate;
    }

    function start()
        public
        isOwner {
        state = State.Active;
    }

    function stop()
        public
        isOwner {
        state = State.Inactive;
    }

    // In case of accidental ether lock on contract
    function withdraw()
        public
        isOwner {
        owner.transfer(address(this).balance);
    }

    // In case of accidental token transfer to this address, owner can transfer it elsewhere
    function transferERC20Token(address _tokenAddress, address _to, uint256 _value)
        public
        isOwner {
        IERC20 token = IERC20(_tokenAddress);
        assert(token.transfer(_to, _value));
    }

}

"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
"}}