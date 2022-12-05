pragma solidity ^0.5.0;

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


/**
 * @dev APIX í í°ì 1ë ëì ì ê·¸ë ê¸°ë¥ì ìííë¤.
 * ë§¤ ë¶ê¸°ë§ë¤(1ëì 4ë² - 3, 6, 9, 12ê°ì ì°¨) ì ê¸´ í í°ì 1/4 ë§í¼ ì© ì ê¸ í´ì íë¤.
 * 
 * ì»¨í¸ë í¸ ì¬ì© ì ì°¨ : 
 * 1. ì»¨í¸ë í¸ë¥¼ ìì±íë¤.
 * 2. ìì±ë ì»¨í¸ë í¸ ì£¼ìì APIX í í°ì ì ì¡íë¤.
 * 3. initLockedBalance() ë©ìëë¥¼ í¸ì¶íë¤.
 * 4. getNextRound() ë° getNextRoundTime() ê°ì íì¸íì¬ ë¤ì ì ê¸í´ì  ì ë³´ë¥¼ íì¸íë¤.
 * 5. í´ì  ê°ë¥ ìì ì ëë¬íë©´ unlock() ë©ìëë¥¼ ì¤ííë¤.
 */

 /**
 * @dev This contract locks specific amount of APIX tokens for 1 year.
 * In every quarter of the year(4 times in 1 year - 3rd, 6th, 9th, 12th months), contract unlocks 1/4 of annually locked tokens.
 * 
 * Contract use sequence : 
 * 1. Deploy contract.
 * 2. Transfer APIX tokens to the generated contract address.
 * 3. Call initLockedBalance() method.
 * 4. Check getNextRound() and getNextRoundTime() value to find out next unlock information.
 * 5. Call unlock() method when unlockable time has come.
 */

contract Locker {
    IERC20  APIX;
    address receiver;
    uint32 unlockStartYear;
    uint256 unlockStartTime;
    uint256 unlockOffsetTime = 7884000; /* (365*24*60*60)/4 */
    uint256 totalLockedBalance = 0;
    uint256 unlockBalancePerRound = 0;
    uint8 lastRound = 0;
    
    /**
     * @dev APIX í í°ì´ ë½ìë  ë emitë©ëë¤.
     *
     * ì ìì¬í­ : `value`ë 0ì¼ ìë ììµëë¤.
     */

    /**
     * @dev Emits when APIX token is locked.
     *
     * Note that `value` may be zero.
     */
    event APIXLock(uint256 value);
    
    /**
     * @dev APIX í í°ì´ ë½ì í´ì ëê³  (`receiver`)ìê² ì ì¡ë  ë emitë©ëë¤.
     *
     * ì ìì¬í­ : `value`ë 0ì¼ ìë ììµëë¤.
     */

    /**
     * @dev Emitted when APIX token is unlocked and transfer tokens to (`receiver`)
     *
     * Note that `value` may be zero.
     */
    event APIXUnlock(uint256 value, address receiver);
    
    /**
     * @dev ì»¨í¸ë í¸ë¥¼ ìì±íë¤.
     * 
     * @param _APIX í í° ì»¨í¸ë í¸ ì£¼ì
     * @param _receiver ì ê¸ í´ì ë í í°ì ìë ¹í  ì£¼ì
     * @param _unlockStartTime ì ê¸ í´ì ê° ììëë ëëì 1ì 1ì¼ 0ì 0ë¶ 0ì´ ìê°(GMT, Unix Timestamp)
     * @param _unlockStartYear ì ê¸ í´ì ê° ììëë ëë(ì ì)
     */

     /**
     * @dev Creates contract.
     * 
     * @param _APIXContractAddress Address of APIX token contract
     * @param _receiver Address which will receive unlocked tokens
     * @param _unlockStartTime Time of the Jan 1st, 00:00:00 of the year that unlocking will be started(GMT, Unix Timestamp)
     * @param _unlockStartYear Year that unlocking will be started
     */
    constructor (address _APIXContractAddress, address _receiver, uint256 _unlockStartTime, uint32 _unlockStartYear) public {
        APIX = IERC20(_APIXContractAddress);
        receiver = _receiver;
        unlockStartTime = _unlockStartTime;
        unlockStartYear = _unlockStartYear;
    }
    
    /**
     * @dev Lock ì»¨í¸ë í¸ê° ë³´ì í í í°ì ìëì ë°ííë¤.
     * @return íì¬ ì»¨í¸ë í¸ìì ë³´ì í APIX ìë (wei)
     */
    /**
     * @dev Returns APIX token balance of this Lock contract.
     * @return Current contract's APIX balance (wei)
     */
    function getContractBalance() external view returns (uint256) {
        return APIX.balanceOf(address(this));
    }
    
    /**
     * @dev ì ê²¨ì§ í í°ì ì ì²´ ìëì ë°ííë¤.
     * @return ì»¨í¸ë í¸ ì´ê¸°í ì ì¤ì ë ì ê¸ ìë
     */
    /**
     * @dev Returns amount of total locked tokens.
     * @return Locked amount set at the contract initalization step
     */
    function totalLockedTokens() external view returns (uint256) {
        return totalLockedBalance;
    }
    
    /**
     * @dev ë¤ì ì ê¸ì´ í´ì ëë íì°¨ë¥¼ íì¸íë¤.
     * @return ë¤ì ë¼ì´ë ë²í¸
     */
    /**
     * @dev Check next unlock round.
     * @return Next round number
     */
    function getNextRound() external view returns (uint8) {
        return lastRound + 1;
    }
    
    /**
     * @dev ë¤ì ì ê¸ì´ í´ì ëë ìê°ì íì¸íë¤.
     */
     /**
     * @dev Check next round's unlock time.
     */
    function getNextRoundTime() external view returns (uint256) {
        return _getNextRoundTime();
    }
    
    function _getNextRoundTime() internal view returns (uint256) {
        return unlockStartTime + unlockOffsetTime * (lastRound + 1);
    }
    /**
     * @dev ë¤ì ë¼ì´ëìì í´ì ëë ìëì ì¡°ííë¤
     * @return í´ì ëë í í° ìë
     */
    /**
     * @dev Check next round's APIX unlock amount
     * @return Unlock amount
     */
    function getNextRoundUnlock() external view returns (uint256) {
        return _getNextRoundUnlock();
    }
    function _getNextRoundUnlock() internal view returns (uint256) {
        uint8 round = lastRound + 1;
        uint256 unlockAmount;
        
        if(round < 4) {
            unlockAmount = unlockBalancePerRound;
        }
        else {
            unlockAmount = APIX.balanceOf(address(this));
        }
        
        return unlockAmount;
    }
    
    /**
     * @dev íì¬ ì»¨í¸ë í¸ì ëí ì ë³´ë¥¼ ë°ííë¤.
     * @return  initLockedToken ì»¨í¸ë í¸ì ì ê²¨ì§ ìë
     *          balance íì¬ ì»¨í¸ë í¸ê° ë³´ê´íê³  ìë í í°ì ìë
     *          unlockYear ë½ ì»¨í¸ë í¸ê° í´ì ëë ëë
     *          nextRound ë¤ì íì°¨ ë²í¸
     *          nextRoundUnlockAt ë¤ì íì°¨ ìì ìê° (Unix timestamp)
     *          nextRoundUnlockToken ë¤ì íì°¨ì íë¦¬ë í í°ì ìë
     */
     /**
     * @dev Returns information of current contract.
     * @return  initLockedToken - Locked APIX token amount
     *          balance - APIX token balance of contract
     *          unlockYear - Contract unlock year
     *          nextRound - Next unlock round number
     *          nextRoundUnlockAt - Next unlock round start time (Unix timestamp)
     *          nextRoundUnlockToken - Unlocking APIX amount of next unlock round
     */
    function getLockInfo() external view returns (uint256 initLockedToken, uint256 balance, uint32 unlockYear, uint8 nextRound, uint256 nextRoundUnlockAt, uint256 nextRoundUnlockToken) {
        initLockedToken = totalLockedBalance;
        balance = APIX.balanceOf(address(this));
        nextRound = lastRound + 1;
        nextRoundUnlockAt = _getNextRoundTime();
        nextRoundUnlockToken = _getNextRoundUnlock();
        unlockYear = unlockStartYear;
    }
    
    
    /**
     * ì»¨í¸ëí¸ìì ë³´ê´íê³  ìë ì ê¸´ ìëì ì¤ì íë¤.
     * ì´ í¨ìë¥¼ ì¤ííê¸° ì ì í í°ì ë¨¼ì  ë³´ë´ì¼ íë¤.
     * 
     * !!** ì ê¸´ ìëì í ë² ì¤ì ëë©´ ë¤ì ë³ê²½í  ì ìì **!!
     * 
     * @return ì ê²¨ì§ í í°ì ìë
     */
    /**
     * Sets locked amount of current contract.
     * Must transfer APIX tokens to this contract.
     * 
     * !!** After locked amount is set, it cannot be updated again **!!
     * 
     * @return Locked token amount
     */
    function initLockedBalance() public returns (uint256) {
        require(totalLockedBalance == 0, "Locker: There is no token stored");
        
        totalLockedBalance = APIX.balanceOf(address(this));
        unlockBalancePerRound = totalLockedBalance / 4;
        
        emit APIXLock (totalLockedBalance);
        
        return totalLockedBalance;
    }
    
    
    /**
     * @dev í í° ì ê¹ì í´ì íê³  ë³´ì ììê² ë°ííë¤.
     * 
     * @param round í í° ì ê¹ í´ì  íì°¨
     * @return ì±ê³µíì ê²½ì° TRUE, ìëë©´ FALSE
     */
    /**
     * @dev Unlocks APIX token and transfer it to the receiver.
     * 
     * @param round Round to unlock the token
     * @return TRUE if successed, FALSE in other situations.
     */
    function unlock(uint8 round) public returns (bool) {
        // ì ê¸´ í í°ì´ ì¡´ì¬í´ì¼ íë¤.
        // Locked token must be exist.
        require(totalLockedBalance > 0, "Locker: There is no locked token");
        
        
        // ì§ì ì ì¶ê¸ë ë¼ì´ëë³´ë¤ í ë² ì¦ê°ë ë¼ì´ëì¬ì¼ íë¤.
        // Round should be 1 round bigger than the latest unlocked round.
        require(round == lastRound + 1, "Locker: The round value is incorrect");
        
        
        // 4ë¼ì´ëê¹ì§ë§ ì¤í ê°ë¥íë¤.
        // Can only be executed for the round 4.
        require(round <= 4, "Locker: The round value has exceeded the executable range");
        
        
        // í´ë¹ ë¼ì´ëì ìê°ì´ ìì§ ëì§ ììì ê²½ì° ì¤ííì§ ëª»íëë¡ íë¤.
        // Cannot execute when the round's unlock time has not yet reached.
        require(block.timestamp >= _getNextRoundTime(), "Locker: It's not time to unlock yet");
        
        
        // ì¶ê¸ ì¤í
        // Withdrawal
        uint256 amount = _getNextRoundUnlock();
        require(amount > 0, 'Locker: There is no unlockable token');
        require(APIX.transfer(receiver, amount));
        
        emit APIXUnlock(amount, receiver);
        
        // ì¤íë íì°¨ë¥¼ ê¸°ë¡íë¤.
        // Records executed round.
        lastRound = round;
        return true;
    }
}