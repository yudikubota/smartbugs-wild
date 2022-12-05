/**
 *Submitted for verification at Etherscan.io on 2019-06-25
*/

/*
 * ì»¨í¸ëí¸ ê°ì
 * 1. ëª©ì 
 *  ë©ì¸ë· ì´ìì´ ììëê¸° ì ê¹ì§ íìì ì¸ ì´ìì ëª©ì ì¼ë¡ íê³  ìë¤.
 *  ë©ì¸ë·ì´ ì´ìëë©´ ì»¨í¸ëí¸ì ê±°ëë ëª¨ë ì¤ë¨ëë©°, ë©ì¸ë· ì½ì¸í¸ë¡ ì íì ììíë©°,
 *  ì í ì ì°¨ë¥¼ ê°ë¨íê² ìíí  ì ìì¼ë©°, ë¸ë¡ì²´ì¸ ë´ ê¸°ë¡ì íµí´ ì ë¢°ëë¥¼ ì»ì ì ìëë¡ ì¤ê³ ëìë¤.
 * 2. ì©ì´ ì¤ëª
 *  Owner : ì»¨í¸ëí¸ë¥¼ ìì±í ì»¨í¸ëí¸ì ì£¼ì¸
 *  Delegator : Ownerì Private Keyë¥¼ ë§¤ë² ì¬ì©íê¸°ìë ë³´ìì ì¸ ì´ìê° ë°ìí  ì ìê¸° ëë¬¸ì ëìë
 *              ì¼ë¶ Owner ê¶íì ì¤íí  ì ìëë¡ ìëªí ëíì
 *              í¹í, ì»¨í¸ëí¸ì ê±°ëê° ì¤ë¨ë ìíìì Delegatorë§ ì¤íí  ì ìë ì ì© í¨ìë¥¼ ì¤ííì¬
 *              ì»¨í¸ëí¸ì í í°ì íìíê³ , ë©ì¸ë·ì ì½ì¸ì¼ë¡ ì íí´ì£¼ë íµì¬ì ì¸ ê¸°ë¥ì ìí
 *  Holder : í í°ì ë³´ì í  ì ìë Addressë¥¼ ê°ì§ê³  ìë ê³ì 
 * 3. ì´ì©
 *  3.1. TokenContainer Structure
 *   3.1.1 Charge Amount
 *    Charge Amountë Holderê° êµ¬ë§¤íì¬ ì¶©ì í í í°ëìëë¤.
 *    Ownerì ê²½ì°ìë ì»¨í¸ëí¸ ì ì²´ì ì¶©ì ë í í°ë. ì¦, Total Supplyì ê°ìµëë¤.
 *   3.1.2 Unlock Amount
 *    ê¸°ë³¸ì ì¼ë¡ ëª¨ë  í í°ì Lock ìíì¸ ê²ì´ ê¸°ë³¸ ìíì´ë©°, Owner ëë Delegatorê° Unlock í´ì¤ ë§í¼ Balanceë¡ ì íë©ëë¤.
 *    Unlock Amountë Charge Amount ì¤ Unlock ë ë§í¼ë§ íìí©ëë¤.
 *    Unlock Amountë Charge Amount ë³´ë¤ ì»¤ì§ ì ììµëë¤.
 *   3.1.3 Balance
 *    ERC20ì Balanceì ê°ì¼ë©°, ê¸°ë³¸ì ì¼ë¡ë Charge Amount - Unlock Amount ê°ìì ë¶í° ììí©ëë¤.
 *    ìì ë¡­ê² ê±°ëê° ê°ë¥íë¯ë¡ Balanceë ë í¬ê±°ë ììì§ ì ììµëë¤.
 * 4. í í° -> ì½ì¸ ì í ì ì°¨
 *  4.1. Owner ê¶íì¼ë¡ ì»¨í¸ëí¸ì ê±°ëë¥¼ ìì í ì¤ë¨ ìí´(lock())
 *  4.2. êµíì ì¤ííê¸° ìí ExchangeContractë¥¼ ìì±
 *  4.3. ExchangeContractì Addressë¥¼ Ownerì ê¶íì¼ë¡ Delegatorë¡ ì§ì 
 *  4.4. Holderê° ExchangeContractì exchangeSYM()ì ì¤ííì¬ ìì¡ì ExchangeHolderìê² ëª¨ë ì ë¬
 *  4.5. ExchangeHolderë¡ì ìê¸ì íì¸
 *  4.6. ìì²­ì ëìëë ë©ì¸ë·ì ê³ì ì¼ë¡ í´ë¹ëë ìë§í¼ ì¡ê¸
 *  4.7. ExchangeContractì withdraw()ë¥¼ ì¬ì©íì¬ Ownerê° ìµì¢ì ì¼ë¡ íìíë ê²ì¼ë¡ ì íì ì°¨ ìë£
 */
 /*
  *  * Contract Overview 
 * 1. Purpose
 *  It is intended to operate for a limited time until mainnet launch.
 *  When the mainnet is launched, all transactions of the contract will be suspended from that day on forward and will initiate the token swap to the mainnet.
 * 2. Key Definitions
 *  Owner : An entity from which smart contract is created
 *  Delegator : The appointed agent is created to prevent from using the contract owner's private key for every transaction made, since it can cause a serious security issue.  
 *              In particular, it performs core functons at the time of the token swap event, such as executing a dedicated, Delegator-specific function while contract transaction is under suspension and
 *              withdraw contract's tokens. 
 *  Holder : An account in which tokens can be stored (also referrs to all users of the contract: Owner, Delegator, Spender, ICO buyers, ect.)
 * 3. Operation
 *  3.1. TokenContainer Structure
 *   3.1.1 Charge Amount
 *    Charge Amount is the charged token amount purcahsed by Holder.
 *    In case for the Owner, the total charged amount in the contract equates to the Total Supply.
 *   3.1.2 Unlock Amount
 *    Generally, all tokens are under a locked state by default and balance appears according to the amount that Owner or Delegator Unlocks.
 *    Unlock Amount only displays tokens that are unlocked from the Charge Amount.
 *    Unlock Amount cannot be greater than the Charge Amount.
 *   3.1.3 Balance
 *     Similiar to the ERC20 Balance; It starts from Charged Amount - Unlock Amount value.
 *     You can send & receive tokens at will and it will offset the Balance amount accordingly.
 * 4. Token Swap Process
 *  4.1. Completely suspend trading operations from the contract address with owner privileges (lock ()).
 *  4.2. Create an ExchangeContract contract to execute the exchange.
 *  4.3. Owner appoints the ExchangeContract address to the Delegator.
 *  4.4. The Holder executes an exchangeSYM() embedded in the ExchangeContract to transfer all the Balance to ExchangeHolder
 *  4.5. Verify ExchangeHolder's deposit amount. 
 *  4.6. Remit an appropriate amount into the mainnet account that corresponds to the request.  
 *  4.7. By using the ExchangeContract's withdraw(), the token swap process completes as the Owner makes the final withdrawal.
  */

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /*
     * ì´ì©ì Owner ë³ê²½ì ì¬ì©íì§ ìì¼ë¯ë¡ ê¶í ë³ê²½ í¨ì ì ê±°íìë¤.
     */
    /*
     * The privilege change function is removed since the Owner change isn't used during the operation.
     */
    /* not used
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    */
}

/*
 * Ownerì ê¶í ì¤ ì¼ë¶ë¥¼ ëì  íì¬í  ì ìëë¡ ëíìë¥¼ ì§ì /í´ì  í  ì ìë ì¸í°íì´ì¤ë¥¼ ì ìíê³  ìë¤.
 */
 /*
 * It defines an interface where the Owner can appoint / dismiss an agent that can partially excercize privileges in lieu of the Owner's 
 */
contract Delegable is Ownable {
    address private _delegator;
    
    event DelegateAppointed(address indexed previousDelegator, address indexed newDelegator);
    
    constructor () internal {
        _delegator = address(0);
    }
    
    /*
     * delegatorë¥¼ ê°ì ¸ì´
     */
    /*
     * Call-up Delegator
     */
    function delegator() public view returns (address) {
        return _delegator;
    }
    
    /*
     * delegatorë§ ì¤í ê°ë¥íëë¡ ì§ì íë ì ê·¼ ì í
     */
    /*
     * Access restriction in which only appointed delegator is executable
     */
    modifier onlyDelegator() {
        require(isDelegator());
        _;
    }
    
    /*
     * owner ëë delegatorê° ì¤í ê°ë¥íëë¡ ì§ì íë ì ê·¼ ì í
     */
    /*
     * Access restriction in which only appointed delegator or Owner are executable
     */
    modifier ownerOrDelegator() {
        require(isOwner() || isDelegator());
        _;
    }
    
    function isDelegator() public view returns (bool) {
        return msg.sender == _delegator;
    }
    
    /*
     * delegatorë¥¼ ìëª
     */
    /*
     * Appoint the delegator
     */
    function appointDelegator(address delegator) public onlyOwner returns (bool) {
        require(delegator != address(0));
        require(delegator != owner());
        return _appointDelegator(delegator);
    }
    
    /*
     * ì§ì ë delegatorë¥¼ í´ì
     */
    /*
     * Dimiss the appointed delegator
     */
    function dissmissDelegator() public onlyOwner returns (bool) {
        require(_delegator != address(0));
        return _appointDelegator(address(0));
    }
    
    /*
     * delegatorë¥¼ ë³ê²½íë ë´ë¶ í¨ì
     */
    /*
     * An internal function that allows delegator changes 
     */
    function _appointDelegator(address delegator) private returns (bool) {
        require(_delegator != delegator);
        emit DelegateAppointed(_delegator, delegator);
        _delegator = delegator;
        return true;
    }
}

/*
 * ERC20ì ê¸°ë³¸ ì¸í°íì´ì¤ë ì ì§íì¬ ì¼ë°ì ì¸ í í° ì ì¡ì´ ê°ë¥íë©´ì,
 * ì¼ë¶ ì¶ê° ê´ë¦¬ ê¸°ë¥ì êµ¬ííê¸° ìí Struct ë° í¨ìê° ì¶ê°ëì´ ììµëë¤.
 * í¹í, í í° -> ì½ì¸ êµíì ìí Delegator ìëªì Ownerê° ì§ì  ìíí  ì»¨í¸ëí¸ì ì£¼ìë¥¼ ìëªíê¸° ëë¬¸ì
 * ì¸ë¶ìì ììë¡ ê¶íì íëíê¸° ë§¤ì° ì´ë ¤ì´ êµ¬ì¡°ë¥¼ ê°ì§ëë¤.
 * ëí, exchange() í¨ìì ì¤íì ExchangeContractìì Holderê° ì§ì  exchangeSYM() í¨ìë¥¼
 * ì¤íí ê²ì´ í¸ë¦¬ê±°ê° ëê¸° ëë¬¸ì ììì ì¬ì©ìê° ë¤ë¥¸ ì¬ëì í í°ì íì·¨í  ì ììµëë¤.
 */
 /*
 * The basic interface of ERC20 is remained untouched therefore basic functions like token transactions will be available. 
 * On top of that, Structs and functions have been added to implement some additional management functions.
 * In particular, we created an additional Delegator agent to initiate the token swap so that the swap is performed by the delegator but directly from the Owner's contract address.
 * By implementing an additional agent, it has built a difficult structure to acquire rights arbitrarily from the outside.
 * In addition, the execution of exchange() cannot be taken by any other Holders' because the exchangeSYM() is triggered directly by the Holder's execution 
 */
contract ERC20Like is IERC20, Delegable {
    using SafeMath for uint256;

    uint256 internal _totalSupply;  // ì´ ë°íë // Total Supply
    bool isLock = false;  // ê³ì½ ì ê¸ íëê·¸ // Contract Lock Flag

    /*
     * í í° ì ë³´(ì¶©ì ë, í´ê¸ë, ê°ì©ìì¡) ë° Spender ì ë³´ë¥¼ ì ì¥íë êµ¬ì¡°ì²´
     */
    /*
     * Structure that stores token information (charge, unlock, balance) as well as Spender information
     */
    struct TokenContainer {
        uint256 chargeAmount; // ì¶©ì ë // charge amount
        uint256 unlockAmount; // í´ê¸ë // unlock amount
        uint256 balance;  // ê°ì©ìì¡ // available balance
        mapping (address => uint256) allowed; // Spender
    }

    mapping (address => TokenContainer) internal _tokenContainers;
    
    event ChangeCirculation(uint256 circulationAmount);
    event Charge(address indexed holder, uint256 chargeAmount, uint256 unlockAmount);
    event IncreaseUnlockAmount(address indexed holder, uint256 unlockAmount);
    event DecreaseUnlockAmount(address indexed holder, uint256 unlockAmount);
    event Exchange(address indexed holder, address indexed exchangeHolder, uint256 amount);
    event Withdraw(address indexed holder, uint256 amount);

    // ì´ ë°íë 
    // Total token supply 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // ê°ì©ìì¡ ê°ì ¸ì¤ê¸°
    // Call-up available balance
    function balanceOf(address holder) public view returns (uint256) {
        return _tokenContainers[holder].balance;
    }

    // Spenderì ë¨ì ìì¡ ê°ì ¸ì¤ê¸°
    // Call-up Spender's remaining balance
    function allowance(address holder, address spender) public view returns (uint256) {
        return _tokenContainers[holder].allowed[spender];
    }

    // í í°ì¡ê¸
    // Transfer token
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // Spender ì§ì  ë° ê¸ì¡ ì§ì 
    // Appoint a Spender and set an amount 
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    // Spender í í°ì¡ê¸
    // Transfer token via Spender 
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _tokenContainers[from].allowed[msg.sender].sub(value));
        return true;
    }

    // Spenderê° í ë¹ ë°ì ì ì¦ê°
    // Increase a Spender amount alloted by the Owner/Delegator
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(!isLock);
        uint256 value = _tokenContainers[msg.sender].allowed[spender].add(addedValue);
        if (msg.sender == owner()) {  // Senderê° ê³ì½ ìì ìì¸ ê²½ì° ì ì²´ ë°íë ì¡°ì 
            require(_tokenContainers[msg.sender].chargeAmount >= _tokenContainers[msg.sender].unlockAmount.add(addedValue));
            _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.add(addedValue);
            _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(addedValue);
        }
        _approve(msg.sender, spender, value);
        return true;
    }

    // Spenderê° í ë¹ ë°ì ì ê°ì
    // Decrease a Spender amount alloted by the Owner/Delegator
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(!isLock);
        // ê¸°ì¡´ì í ë¹ë ê¸ì¡ì ìì¡ë³´ë¤ ë ë§ì ê¸ì¡ì ì¤ì´ë ¤ê³  íë ê²½ì° í ë¹ì¡ì´ 0ì´ ëëë¡ ì²ë¦¬
        //// If you reduce more than the alloted amount in the balance, we made sure the alloted amount is set to zero instead of minus
        if (_tokenContainers[msg.sender].allowed[spender] < subtractedValue) {
            subtractedValue = _tokenContainers[msg.sender].allowed[spender];
        }
        
        uint256 value = _tokenContainers[msg.sender].allowed[spender].sub(subtractedValue);
        if (msg.sender == owner()) {  // Senderê° ê³ì½ ìì ìì¸ ê²½ì° ì ì²´ ë°íë ì¡°ì  // // Adjust the total circulation amount if the Sender equals the contract owner
            _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.sub(subtractedValue);
            _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.sub(subtractedValue);
        }
        _approve(msg.sender, spender, value);
        return true;
    }

    // í í°ì¡ê¸ ë´ë¶ ì¤í í¨ì 
    // An internal execution function for troken transfer
    function _transfer(address from, address to, uint256 value) private {
        require(!isLock);
        // 3.1. Known vulnerabilities of ERC-20 token
        // íì¬ ì»¨í¸ëí¸ë¡ë ì¡ê¸í  ì ìëë¡ ìì¸ ì²ë¦¬ // Exceptions were added to not allow deposits to be made in the current contract . 
        require(to != address(this));
        require(to != address(0));

        _tokenContainers[from].balance = _tokenContainers[from].balance.sub(value);
        _tokenContainers[to].balance = _tokenContainers[to].balance.add(value);
        emit Transfer(from, to, value);
    }

    // Spender ì§ì  ë´ë¶ ì¤í í¨ì
    // Internal execution function for assigning a Spender
    function _approve(address holder, address spender, uint256 value) private {
        require(!isLock);
        require(spender != address(0));
        require(holder != address(0));

        _tokenContainers[holder].allowed[spender] = value;
        emit Approval(holder, spender, value);
    }

    /* extension */
    /**
     * ì¶©ì ë 
     */
    /**
     * Charge Amount 
     */
    function chargeAmountOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].chargeAmount;
    }

    /**
     * í´ê¸ë
     */
    /**
     * Unlock Amount
     */
    function unlockAmountOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].unlockAmount;
    }

    /**
     * ê°ì©ìì¡
     */
    /**
     * Available amount in the balance
     */
    function availableBalanceOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].balance;
    }

    /**
     * Holderì ê³ì  ìì¡ ìì½ ì¶ë ¥(JSON í¬ë§·)
     */
    /**
     * An output of Holder's account balance summary (JSON format)
     */
    function receiptAccountOf(address holder) external view returns (string memory) {
        bytes memory blockStart = bytes("{");
        bytes memory chargeLabel = bytes(""chargeAmount" : "");
        bytes memory charge = bytes(uint2str(_tokenContainers[holder].chargeAmount));
        bytes memory unlockLabel = bytes("", "unlockAmount" : "");
        bytes memory unlock = bytes(uint2str(_tokenContainers[holder].unlockAmount));
        bytes memory balanceLabel = bytes("", "availableBalance" : "");
        bytes memory balance = bytes(uint2str(_tokenContainers[holder].balance));
        bytes memory blockEnd = bytes(""}");

        string memory receipt = new string(blockStart.length + chargeLabel.length + charge.length + unlockLabel.length + unlock.length + balanceLabel.length + balance.length + blockEnd.length);
        bytes memory receiptBytes = bytes(receipt);

        uint readIndex = 0;
        uint writeIndex = 0;

        for (readIndex = 0; readIndex < blockStart.length; readIndex++) {
            receiptBytes[writeIndex++] = blockStart[readIndex];
        }
        for (readIndex = 0; readIndex < chargeLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = chargeLabel[readIndex];
        }
        for (readIndex = 0; readIndex < charge.length; readIndex++) {
            receiptBytes[writeIndex++] = charge[readIndex];
        }
        for (readIndex = 0; readIndex < unlockLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = unlockLabel[readIndex];
        }
        for (readIndex = 0; readIndex < unlock.length; readIndex++) {
            receiptBytes[writeIndex++] = unlock[readIndex];
        }
        for (readIndex = 0; readIndex < balanceLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = balanceLabel[readIndex];
        }
        for (readIndex = 0; readIndex < balance.length; readIndex++) {
            receiptBytes[writeIndex++] = balance[readIndex];
        }
        for (readIndex = 0; readIndex < blockEnd.length; readIndex++) {
            receiptBytes[writeIndex++] = blockEnd[readIndex];
        }

        return string(receiptBytes);
    }

    // uint ê°ì string ì¼ë¡ ë³ííë ë´ë¶ í¨ì
    // An internal function that converts an uint value to a string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // ì ì²´ ì íµë - Ownerì unlockAmount
    // Total circulation supply, or the unlockAmount of the Owner's
    function circulationAmount() external view returns (uint256) {
        return _tokenContainers[owner()].unlockAmount;
    }

    // ì ì²´ ì íµë ì¦ê°
    // Increase the token's total circulation supply 
    /*
     * ì»¨í¸ëí¸ ìì ì íµëë í í°ëì ì¦ê° ìíµëë¤.
     * Ownerê° ë³´ì í ì ì²´ í í°ëìì Unlock ë ì ë§í¼ì´ íì¬ ì íµëì´ë¯ë¡,
     * Unlock Amountì Balance ê° ì¦ê°íë©°, Charge Amountë ë³ëëì§ ììµëë¤.
     */
    /*
     * This function increases the amount of circulated tokens that are distributed on the contract.
     * The circulated token is referring to the Unlock tokens out of the contract Owner's total supply, so the Charge Amount is not affected (refer back to the Balance definition above).
     * This function increases in the Unlock Amount as well as in the Balance.
     */
    function increaseCirculation(uint256 amount) external onlyOwner returns (uint256) {
        require(!isLock);
        require(_tokenContainers[msg.sender].chargeAmount >= _tokenContainers[msg.sender].unlockAmount.add(amount));
        _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.add(amount);
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(amount);
        emit ChangeCirculation(_tokenContainers[msg.sender].unlockAmount);
        return _tokenContainers[msg.sender].unlockAmount;
    }

    // ì ì²´ ì íµë ê°ì
    // Reduction of the token's total supply
    /*
     * ì»¨í¸ëí¸ ìì ì íµëë í í°ëì ê°ì ìíµëë¤.
     * Ownerê° ë³´ì í ì ì²´ í í°ëìì Unlock ë ì ë§í¼ì´ íì¬ ì íµëì´ë¯ë¡,
     * Unlock Amountì Balance ê° ê°ìíë©°, Charge Amountë ë³ëëì§ ììµëë¤.
     * Ownerë§ ì¤íí  ì ìì¼ë©°, ì ì±ì ì¸ ê³íì ë§ì¶ì´ ì¤íëì´ì¼íë¯ë¡ 0ë³´ë¤ ììì§ë ê°ì´ ìë ¥ëë ê²½ì° ì¤íì ì¤ë¨í©ëë¤.
     */
    /*
     * This function decreases the amount of circulated tokens that are distributed on the contract.
     * The circulated token is referring to the Unlock tokens out of the contract Owner's total supply, so the Charge Amount is not affected (refer back to the Balance definition above).
     * This function decreases in the Unlock Amount as well as in the Balance.
     */
    function decreaseCirculation(uint256 amount) external onlyOwner returns (uint256) {
        require(!isLock);
        _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.sub(amount);
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.sub(amount);
        emit ChangeCirculation(_tokenContainers[msg.sender].unlockAmount);
        return _tokenContainers[msg.sender].unlockAmount;
    }

    /*
     * í¹ì  ì¬ì©ì(ICO, PreSale êµ¬ë§¤ì)ê° êµ¬ë§¤í ê¸ì¡ ë§í¼ì ì¶©ì ëì ì§ì  ìë ¥í  ë ì¬ì©í©ëë¤.
     * ì»¨í¸ëí¸ ë´ í í°ì ì íµëì ë§ì¶ì´ ëìíë¯ë¡, Ownerì Balanceê° ë¶ì¡±íë©´ ì¤íì ì¤ë¨íëë¤.
     * ì¶©ì í í í°ì lockì¸ ìíë¡ ììëë©°, charge() í¨ìë ì¶©ì ê³¼ ëìì Unlockíë ìì ì§ì íì¬
     * increaseUnlockAmount() í¨ìì ì¤í íìë¥¼ ì¤ì¼ ì ìë¤.
     */
    /*
     * This function is used to directly input the token amount that is purchased by particular Holders (ICO, Pre-sale buyers). It can be performed by the Owner or the Delegator.
     * Since the contract operates in concurrent to the tokens in circulation, the function will fail to execute when Owner's balance is insuffient. 
     * All charged tokens are locked amount. 
     */
    function charge(address holder, uint256 chargeAmount, uint256 unlockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(chargeAmount > 0);
        require(chargeAmount >= unlockAmount);
        require(_tokenContainers[owner()].balance >= chargeAmount);

        _tokenContainers[owner()].balance = _tokenContainers[owner()].balance.sub(chargeAmount);

        _tokenContainers[holder].chargeAmount = _tokenContainers[holder].chargeAmount.add(chargeAmount);
        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
        
        emit Charge(holder, chargeAmount, unlockAmount);
    }
    
    /*
     * í¹ì  ì¬ì©ì(ICO, PreSale êµ¬ë§¤ì)ê° êµ¬ë§¤í ê¸ì¡ ììì í´ê¸ëì ë³ê²½í  ë ì¬ì©í©ëë¤.
     * ì´ ì¶©ì ë ììì ë³íê° ì¼ì´ëë¯ë¡ Unlock Amountê° Charge Amountë³´ë¤ ì»¤ì§ ì ììµëë¤.
     */
    /*
     * This function is used to change the Unlock Amount of tokens that is purchased by particular Holders (ICO, Pre-sale buyers).
     * Unlock Amount cannot be larger than Charge Amount because changes occur within the total charge amount.
     */
    function increaseUnlockAmount(address holder, uint256 unlockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(_tokenContainers[holder].chargeAmount >= _tokenContainers[holder].unlockAmount.add(unlockAmount));

        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
        
        emit IncreaseUnlockAmount(holder, unlockAmount);
    }
    
    /*
     * í¹ì  ì¬ì©ì(ICO, PreSale êµ¬ë§¤ì)ê° êµ¬ë§¤í ê¸ì¡ ììì í´ê¸ëì ë³ê²½í  ë ì¬ì©í©ëë¤.
     * Balanceë¥¼ Lock ìíë¡ ì ííë ê²ì´ë¯ë¡ Lock Amountì ê°ì Balanceë³´ë¤ ì»¤ì§ ì ììµëë¤.
     */
    /*
     * This function is used to change the Unlock Amount of tokens that is purchased by particular Holders (ICO, Pre-sale buyers).
     * Since the Balance starts from a locked state, the number of locked tokens cannot be greater than the Balance.
     */
    function decreaseUnlockAmount(address holder, uint256 lockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(_tokenContainers[holder].balance >= lockAmount);

        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.sub(lockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.sub(lockAmount);
        
        emit DecreaseUnlockAmount(holder, lockAmount);
    }

    /*
     * í¹ì  ì¬ì©ì(ICO, PreSale êµ¬ë§¤ì)ê° êµ¬ë§¤í ê¸ì¡ ììì ì ì²´ë¥¼ í´ê¸í  ë ì¬ì©í©ëë¤.
     * Charge Amount ì¤ Unlock Amount ëì ì ì¸í ëë¨¸ì§ ë§í¼ì ì¼ê´ì ì¼ë¡ í´ì í©ëë¤.
     */
    /*
     * This function is used to change the Unlock Amount of tokens that is purchased by particular Holders (ICO, Pre-sale buyers).
     * It unlocks all locked tokens in the Charge Amount, other than tokens already unlocked. 
     */
    function unlockAmountAll(address holder) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());

        uint256 unlockAmount = _tokenContainers[holder].chargeAmount.sub(_tokenContainers[holder].unlockAmount);

        require(unlockAmount > 0);
        
        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
    }

    /*
     * ê³ì½ ì ê¸
     * ê³ì½ì´ ì ê¸°ë©´ ì»¨í¸ëí¸ì ê±°ëê° ì¤ë¨ë ìíê° ëë©°,
     * ê±°ëê° ì¤ë¨ë ìíììë Ownerì Delegatorë¥¼ í¬í¨í ëª¨ë  Holderë ê±°ëë¥¼ í  ì ìê² ëë¤.
     * ëª¨ë  ê±°ëê° ì¤ë¨ë ìíìì ëª¨ë  Holderì ìíê° ë³ê²½ëì§ ìê² ë§ë  íì
     * í í° -> ì½ì¸ ì í ì ì°¨ë¥¼ ì§ííê¸° ìí¨ì´ë¤.
     * ë¨, ì´ ìíììë Exchange Contractë¥¼ Ownerê° ì§ì  Delegatorë¡ ìëªíì¬
     * Holderì ìì²­ì ì²ë¦¬íëë¡ íë©°, ì´ëë í í° -> ì½ì¸ êµííìë¥¼ ìí exchange(), withdraw() í¨ì ì¤íë§ íì©ì´ ëë¤.
     */
    /*
     * Contract lock
     * If the contract is locked, all transactions will be suspended.
     * All Holders including Owner and Delegator will not be able to make transaction during suspension.
     * After all transactions have been stopped and all Holders have not changed their status
     * This function is created primarily for the token swap event. 
     * In this process, it's important to note that the Owner of the Exchange contract should directly appoint a delegator when handling Holders' requests.
     * Only the exchange () and withdraw () are allowed to be executed for token swap.
     */
    function lock() external onlyOwner returns (bool) {
        isLock = true;
        return isLock;
    }

    /*
     * ê³ì½ ì ê¸ í´ì 
     * ì ê¸´ ê³ì½ì í´ì í  ë ì¬ì©ëë¤.
     */
    /*
     * Release contract lock
     * The function is used to revert a locked contract to a normal state. 
     */
    function unlock() external onlyOwner returns (bool) {
        isLock = false;
        return isLock;
    }
    
    /*
     * í í° êµí ì²ë¦¬ì© ì¸ë¶ í¸ì¶ í¨ì
     * ê³ì½ ì ì²´ê° ì ê¸´ ìíì¼ ë(êµí ì²ë¦¬ ì¤ ê³ì½ ì¤ë¨),
     * ì¸ë¶ììë§ í¸ì¶ ê°ë¥íë©°, Delegatorì´ë©´ì Contractì¸ ê²½ì°ìë§ í¸ì¶ ê°ë¥íë¤.
     */
    /*
     * It is an external call function for token exchange processing
     * This function is used when the entire contract is locked (contract lock during the token swap),
     * It can be called only externally. Also, it can be only called when the agent is both Delegator and Contract.
     */
    function exchange(address holder) external onlyDelegator returns (bool) {
        require(isLock);    // lock state only
        require((delegator() == msg.sender) && isContract(msg.sender));    // contract delegator only
        
        uint256 balance = _tokenContainers[holder].balance;
        _tokenContainers[holder].balance = 0;
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(balance);
        
        emit Exchange(holder, msg.sender, balance);
        return true;
    }
    
    /*
     * í í° êµí ì²ë¦¬ í íìë í í°ì Owneríí ëë ¤ì£¼ë í¨ì
     * ê³ì½ ì ì²´ê° ì ê¸´ ìíì¼ ë(êµí ì²ë¦¬ ì¤ ê³ì½ ì¤ë¨),
     * ì¸ë¶ììë§ í¸ì¶ ê°ë¥íë©°, Delegatorì´ë©´ì Contractì¸ ê²½ì°ìë§ í¸ì¶ ê°ë¥íë¤.
     */
    /*
     * This is a function in which the Delegator returns tokens to the Owner after the token swap process
     * This function is used when the entire contract is locked (contract lock during the token swap),
     * It can be called only externally. Also, it can be only called when the agent is both Delegator and Contract Owner.
     */
    function withdraw() external onlyDelegator returns (bool) {
        require(isLock);    // lock state only
        require((delegator() == msg.sender) && isContract(msg.sender));    // contract delegator only
        
        uint256 balance = _tokenContainers[msg.sender].balance;
        _tokenContainers[msg.sender].balance = 0;
        _tokenContainers[owner()].balance = _tokenContainers[owner()].balance.add(balance);
        
        emit Withdraw(msg.sender, balance);
    }
    
    /*
     * íì¬ì ì£¼ìê° ìì§ë´ì ì°¨ì§íê³  ìë ì½ëì í¬ê¸°ë¥¼ ê³ì°íì¬ ì»¨í¸ëí¸ì¸ì§ íì¸íë ëêµ¬
     * ì»¨í¸ëí¸ì¸ ê²½ì°ìë§ ì ì¥ë ì½ëì í¬ê¸°ê° ì¡´ì¬íë¯ë¡ ì½ëì í¬ê¸°ê° ì¡´ì¬íë¤ë©´
     * ì»¨í¸ëí¸ë¡ íë¨í  ììë¤.
     */
    /*
     * This is a tool used for confirming a contract. It determines the size of code that the current address occupies within the blockchain network.
     * Since the size of a stored code exists only in the case of a contract, it is can be used as a validation tool.
     */
    function isContract(address addr) private returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
}

contract NoX is ERC20Like {
    string public name = "NoX";
    string public symbol = "NoX";
    uint256 public decimals = 18;

    constructor () public {
        _totalSupply = 30000 * (10 ** decimals);
        _tokenContainers[msg.sender].chargeAmount = _totalSupply;
        emit Charge(msg.sender, _tokenContainers[msg.sender].chargeAmount, _tokenContainers[msg.sender].unlockAmount);
    }
}