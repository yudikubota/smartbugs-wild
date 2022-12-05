{"Ethc2cDAI.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

interface UserTrustLists {
    function inTrustLists(address user, address people) external returns (bool);
}

contract Ethc2cDAI {
    using SafeMath for uint256;

    IERC20 DAI;
    IERC20 HAMMER;
    UserTrustLists userTrust;
    address public feeTo;

    constructor(address _DAI, address _HAMMER, address _userTrust, address _feeTo) {
        DAI = IERC20(_DAI);
        HAMMER = IERC20(_HAMMER);
        userTrust = UserTrustLists(_userTrust);
        feeTo = _feeTo;
    }

     /*ååç¶æ
    åå®¶åå¸åå   SellerCreated
    åå®¶æååå   SellerSuspend 
    åå®¶åæ¶åå   SellerCancelled
    ååè¶æ¶èµå   SellerRedeem

    ä¹°å®¶æäº¤ä¹°å    BuyerSubmit
    ä¹°å®¶ç¡®è®¤ä»æ¬¾    BuyerConfirmPayment

    åå®¶ç¡®è®¤æ¶æ¬¾   SellerConfirmReceive
    åå®¶è¶æ¶æªç¡®è®¤ SellerOutofTime
    */
    enum State {SellerCreated,
                SellerSuspend,
                SellerCancelled, 
                SellerRedeem, 
                BuyerSubmit, 
                BuyerConfirmPayment,
                SellerConfirmReceive, 
                SellerOutofTime}
   
    uint256 public id = 0;
    uint256 public orderValidity = 4 hours;
    uint256 public paymentValidity = 2 hours;

    struct OrderMessage
    {
        uint256 orderNumber;
        uint256 amount;
        uint256 price;
        bool    isTrust;
        address seller;
        address buyer;
        uint256 submitTime;
        uint8   numberOfRounds;
        State   state;
    }

    mapping(uint256 => OrderMessage) public orders;
    
    modifier onlySeller(uint256 _uid) {
        require(msg.sender == orders[_uid].seller);
        _;
    }
    
    modifier onlyBuyer(uint256 _uid) {
        require(msg.sender == orders[_uid].buyer);
        _;
    }
    
    modifier inState(uint256 _uid, State _state) {
        require(orders[_uid].state == _state);
        _;
    }
    
    modifier orderInTime(uint256 _uid) {
        require(block.timestamp <= orders[_uid].submitTime + orderValidity);
        _;
    }
    
    modifier orderOutOfTime(uint256 _uid) {
        require(block.timestamp > orders[_uid].submitTime + orderValidity);
        _;
    }

    modifier ConfirmInTime(uint256 _uid) {
        require(block.timestamp <= orders[_uid].submitTime + paymentValidity);
        _;
    }
    
    modifier ConfirmOutOfTime(uint256 _uid) {
        require(block.timestamp > orders[_uid].submitTime + paymentValidity);
        _;
    }

    //äºä»¶æ¥å¿   
    event SetOrder(uint256 indexed orderNumber, address seller, uint256 amount, bool isTrust, uint256 orderCreated);
    event SellerSuspend(uint256 indexed orderNumber, address seller, uint256 amount, uint256 orderSuspend);
    event CancelOrder(uint256 indexed orderNumber, address seller, uint256 amount, uint256 cancelTime);
    event SellerRestart(uint256 indexed orderNumber, address seller, uint256 amount, uint256 restartTime);
    event SellerOutRestart( uint256 indexed orderNumber, address seller, uint256 amount, uint256 outRestartTime);
    event SellerRedeem(uint256 indexed orderNumber, address seller, uint256 amount, uint256 redeemTime);
    event BuyerSubmit(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerSubmitTime);
    event BuyerCancelPayment(uint256 indexed orderNumber, address seller, uint256 amount,  address buyer, uint256 buyerCancelTime);
    event BuyerConfirmPayment(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerConfirmTime);
    event BuyerOutofTimeRestart(uint256 indexed orderNumber, address seller,uint256 amount, address buyer, uint256 restart);
    event SellerConfirmReceive(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 sellerConfirmTime);
    event FallbackToBuyer(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 fallbackTime); 
    event SellerOutofTime(uint256 indexed orderNumber, address seller, uint256 amount, address buyer, uint256 buyerWithdraw);

    //åå®¶åå¸åå
    function setOrder(uint256 _orderNumber, uint256 _amount, uint256 _price, bool _isTrust)
        public 
    {       
        require(_amount > 0);
        id += 1;
        orders[id].orderNumber = _orderNumber;
        orders[id].seller = msg.sender;
        orders[id].amount = _amount;
        orders[id].price = _price;
        orders[id].isTrust = _isTrust;
        orders[id].submitTime = block.timestamp;
        orders[id].numberOfRounds = 0;

        DAI.transferFrom(msg.sender, feeTo, _amount.div(1000));
        DAI.transferFrom(msg.sender, address(this), _amount);

        emit SetOrder(_orderNumber, msg.sender, _amount, _isTrust, block.timestamp);
    }

    //åå®¶æååå
    function sellerSuspend(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderInTime(_uid)
    {
        orders[_uid].state = State.SellerSuspend;
        emit SellerSuspend(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //åå®¶åæ¶ååå¹¶èµåèµé
    function cancelOrder(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderInTime(_uid)
    {
        orders[_uid].state = State.SellerCancelled;
        DAI.transfer(msg.sender, orders[_uid].amount);
        emit CancelOrder(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //ååæååï¼åå®¶éå¯åå
    function sellerRestart(uint256 _uid)
        public
        inState(_uid, State.SellerSuspend)
        onlySeller(_uid)
    {
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.SellerCreated;
        emit SellerRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //ååè¶æ¶ï¼åå®¶éå¯åå
    function sellerOutRestart(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderOutOfTime(_uid)
    {
        orders[_uid].submitTime = block.timestamp;
        emit SellerOutRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //ååè¶æ¶ï¼åå®¶èµåèµé
    function sellerRedeem(uint256 _uid)
        public
        inState(_uid, State.SellerCreated)
        onlySeller(_uid)
        orderOutOfTime(_uid)
    {
        orders[_uid].state = State.SellerRedeem;
        DAI.transfer(msg.sender, orders[_uid].amount);
        emit SellerRedeem(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, block.timestamp);
    }

    //ä¹°å®¶æäº¤ä¹°å
    function buyerSubmit(uint256 _uid) 
        public
        inState(_uid, State.SellerCreated)
        orderInTime(_uid)
    {   
        require(orders[_uid].seller != msg.sender);

        if(orders[_uid].isTrust == true){
            require(userTrust.inTrustLists(orders[_uid].seller, msg.sender));
        }

        orders[_uid].buyer = msg.sender;
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.BuyerSubmit;
        emit BuyerSubmit(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //ä¹°å®¶åæ¶ä¹°å
    function buyerCancelPayment(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlyBuyer(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].buyer = address(0);
        orders[_uid].state = State.SellerCreated;
        emit BuyerCancelPayment(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //ä¹°å®¶ç¡®è®¤ä»æ¬¾
    function buyerConfirmPayment(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlyBuyer(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].numberOfRounds += 1;
        orders[_uid].state = State.BuyerConfirmPayment;
        emit BuyerConfirmPayment(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }

    //ä¹°å®¶è¶æ¶æªä»æ¬¾ï¼åå®¶éç½®åå
    function buyerOutofTimeRestart(uint256 _uid) 
        public
        inState(_uid, State.BuyerSubmit)
        onlySeller(_uid)
        ConfirmOutOfTime(_uid)
    {   
        emit BuyerOutofTimeRestart(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);

        orders[_uid].submitTime = block.timestamp;
        orders[_uid].buyer = address(0);
        orders[_uid].numberOfRounds = 0;
        orders[_uid].state = State.SellerCreated;
    }
    
    //åå®¶ç¡®è®¤æ¶æ¬¾å¹¶æ¾è¡èµéã
    //å¦æç¬¬ä¸è½®å°±æåï¼åå¥å±10ä¸ªé¤å­ï¼åå®¶6ä¸ªï¼ä¹°å®¶4ä¸ª
    function sellerConfirmReceive(uint256 _uid)
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlySeller(_uid)
        ConfirmInTime(_uid)
    {
        DAI.transfer(orders[_uid].buyer, orders[_uid].amount);
        orders[_uid].state = State.SellerConfirmReceive;

        if(orders[_uid].numberOfRounds == 1){
            HAMMER.mint(orders[_uid].seller, 6 * 1e18);
            HAMMER.mint(orders[_uid].buyer, 4 * 1e18);
        }
        
        emit SellerConfirmReceive(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);
    }

    //åå®¶æªæ¶å°ä»æ¬¾ï¼éåååç»ä¹°å®¶
    function fallbackToBuyer(uint256 _uid) 
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlySeller(_uid)
        ConfirmInTime(_uid)
    {   
        orders[_uid].submitTime = block.timestamp;
        orders[_uid].state = State.BuyerSubmit;
        emit FallbackToBuyer(orders[_uid].orderNumber, msg.sender, orders[_uid].amount, orders[_uid].buyer, block.timestamp);
    }

    //åå®¶è¶æ¶æªç¡®è®¤ï¼ä¹°å®¶ååºèµé
    function sellerOutofTime(uint256 _uid)
        public
        inState(_uid, State.BuyerConfirmPayment)
        onlyBuyer(_uid)
        ConfirmOutOfTime(_uid)
    {
        DAI.transfer(msg.sender, orders[_uid].amount);
        orders[_uid].state = State.SellerOutofTime;
        emit SellerOutofTime(orders[_uid].orderNumber, orders[_uid].seller, orders[_uid].amount, msg.sender, block.timestamp);
    }
}"},"IERC20.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

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

    function mint(address _to, uint256 _amount) external;

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
}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}"}}