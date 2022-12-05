// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/TokenExpress.sol

pragma solidity ^0.4.25;



contract TokenExpress is Ownable {
    event Deposit(bytes32 indexed escrowId, address indexed sender, uint256 amount);
    event Send(bytes32 indexed escrowId, address indexed recipient, uint256 amount);
    event Recovery(bytes32 indexed escrowId, address indexed sender, uint256 amount);

    using SafeMath for uint256;

    // ã¦ã¼ã¶ã«è² æãã¦ãããææ°æï¼weiï¼
    uint256 fee = 1000000;

    // ã¦ã¼ã¶ãååã§ããããã«ãªãã¾ã§ã®æéï¼æéï¼
    uint256 lockTime = 14 * 24;

    // ãªã¼ãã¼ä»¥å¤ã«ç®¡çæ¨©éãããã¦ã¼ã¶
    address administrator = 0x0;

    // ééæå ±ãä¿å­ããæ§é ä½
    struct TransferInfo {
        address from;
        address to;
        uint256 amount;
        uint256 date;
        bool    sent;
    }

    // ããã¸ããæå ±
    mapping (bytes32 => TransferInfo) private _transferInfo;

    /**
     * ã³ã³ã¹ãã©ã¯ã¿
     */
    constructor () public {
        owner = msg.sender;
    }

    /**
     * ããã¸ãããè¡ã
     * å¼æ°ï¼ï¼ã·ã¹ãã ã§çºè¡ãããID
     * å¼æ°ï¼ï¼ééé¡ï¼wei ã§æå®ï¼
     * å¼æ°ï¼ï¼ééåã¢ãã¬ã¹
     * â» ééé¡ï¼ææ°æåã®ETHãéã£ã¦ãããå¿è¦ããã
     *
     * df121a97
     */
    function etherDeposit(bytes32 id, uint256 amount) payable public {
        // æ¢ã«IDãç»é²ããã¦ãããå¤æ´ã¯ä¸å¯
        require(_transferInfo[id].from == 0x0, "ID is already exists.");

        // å®éã«éããã ether ãééé¡ï¼ææ°æãããä½ããã°ã¨ã©ã¼
        require(amount + fee <= msg.value, "Value is too low.");

        // ééæå ±ãç»é²ãã
        _transferInfo[id].from   = msg.sender;
        _transferInfo[id].to     = 0x0;
        _transferInfo[id].amount = amount;
        _transferInfo[id].date   = block.timestamp;
        emit Deposit(id, msg.sender, amount);
    }

    /**
     * ééãè¡ã
     * å¼æ°ï¼ï¼ã·ã¹ãã ã§çºè¡ãããID
     *
     * 3af19adb
     */
    function etherSend(bytes32 id, address to) public {
        // IDãç»é²ããã¦ããªããã°ã¨ã©ã¼
        require(_transferInfo[id].from != 0x0, "ID error.");

        // æ¢ã«ééã»ååããã¦ããã°ã¨ã©ã¼
        require(_transferInfo[id].sent == false, "Already sent.");

        // ééåãä¸æ­£ãªã¢ãã¬ã¹ãªãã¨ã©ã¼
        require(to != 0x0, "Address error.");

        // ééæç¤ºãããã¢ãã¬ã¹ãããªã¼ãã¼ãç®¡çèãããã¸ããèä»¥å¤ã ã£ããã¨ã©ã¼
        require(msg.sender == owner || msg.sender == administrator || msg.sender == _transferInfo[id].from, "Invalid address.");

        to.transfer(_transferInfo[id].amount);
        _transferInfo[id].to = to;
        _transferInfo[id].sent = true;
        emit Send(id, to, _transferInfo[id].amount);
    }

    /**
     * ååãè¡ã
     * å¼æ°ï¼ï¼ã·ã¹ãã ã§çºè¡ãããID
     *
     * 6b87124e
     */
    function etherRecovery(bytes32 id) public {
        // IDãç»é²ããã¦ããªããã°ã¨ã©ã¼
        require(_transferInfo[id].from != 0x0, "ID error.");

        // æ¢ã«ééã»ååããã¦ããã°ã¨ã©ã¼
        require(_transferInfo[id].sent == false, "Already recoveried.");

        // ã­ãã¯ã¿ã¤ã ãéãã¦ä»ããã°ã¨ã©ã¼
        require(_transferInfo[id].date + lockTime * 60 * 60 <= block.timestamp, "Locked.");

        address to = _transferInfo[id].from;
        to.transfer(_transferInfo[id].amount);
        _transferInfo[id].sent = true;
        emit Recovery(id, _transferInfo[id].from, _transferInfo[id].amount);
    }

    /**
     * æå®ããIDã®æå ±ãè¿ã
     * onlyOwner ã«ããæ¹ãè¯ããã
     */
    function etherInfo(bytes32 id) public view returns (address, address, uint256, bool) {
        return (_transferInfo[id].from, _transferInfo[id].to, _transferInfo[id].amount, _transferInfo[id].sent);
    }

    /**
     * ãªã¼ãã¼ä»¥å¤ã®ç®¡çèãè¨­å®ãã
     * å¼æ°ï¼ï¼ç®¡çèã®ã¢ãã¬ã¹
     *
     *
     */
    function setAdmin(address _admin) onlyOwner public {
        administrator = _admin;
    }

    /**
     * ãªã¼ãã¼ä»¥å¤ã®ç®¡çèãåå¾ãã
     */
    function getAdmin() public view returns (address) {
        return administrator;
    }

    /**
     * ææ°æã®å¤ãå¤æ´ãã
     * å¼æ°ï¼ï¼ææ°æã®å¤ï¼weiï¼
     *
     * 69fe0e2d
     */
    function setFee(uint256 _fee) onlyOwner public {
        fee = _fee;
    }

    /**
     * ææ°æã®å¤ãè¿ã
     */
    function getFee() public view returns (uint256) {
        return fee;
    }

    /**
     * ã­ãã¯æéãå¤æ´ãã
     * å¼æ°ï¼ï¼ã­ãã¯æéï¼æéï¼
     *
     * ae04d45d
     */
    function setLockTime(uint256 _lockTime) onlyOwner public {
        lockTime = _lockTime;
    }

    /**
     * ã­ãã¯æéã®å¤ãè¿ã
     */
    function getLockTime() public view returns (uint256) {
        return lockTime;
    }

    /**
     * ã³ã³ãã©ã¯ãã®æ®é«ç¢ºèª
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * ãªã¼ãã¼ã«ãã Ether ã®åå
     * å¼æ°ï¼ï¼éãåã¢ãã¬ã¹
     * å¼æ°ï¼ï¼ééé¡
     *
     * 3ef5e35f
     */
    function sendEtherToOwner(address to, uint256 amount) onlyOwner public {
        to.transfer(amount);
    }

}