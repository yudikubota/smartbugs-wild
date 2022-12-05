{"ExpertLegion.sol":{"content":"pragma solidity ^0.6.0;
import "./SafeMath.sol";
import "./Vars.sol";


// $$$$$$$$\                                           $$\     $$\                           $$\                     
// $$  _____|                                          $$ |    $$ |                          \__|                    
// $$ |      $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\   $$ |       $$$$$$\   $$$$$$\  $$\  $$$$$$\  $$$$$$$\  
// $$$$$\    \$$\ $$  |$$  __$$\ $$  __$$\ $$  __$$\ \_$$  _|  $$ |      $$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ 
// $$  __|    \$$$$  / $$ /  $$ |$$$$$$$$ |$$ |  \__|  $$ |    $$ |      $$$$$$$$ |$$ /  $$ |$$ |$$ /  $$ |$$ |  $$ |
// $$ |       $$  $$<  $$ |  $$ |$$   ____|$$ |        $$ |$$\ $$ |      $$   ____|$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |
// $$$$$$$$\ $$  /\$$\ $$$$$$$  |\$$$$$$$\ $$ |        \$$$$  |$$$$$$$$\ \$$$$$$$\ \$$$$$$$ |$$ |\$$$$$$  |$$ |  $$ |
// \________|\__/  \__|$$  ____/  \_______|\__|         \____/ \________| \_______| \____$$ |\__| \______/ \__|  \__|
//                     $$ |                                                        $$\   $$ |        fork version 1.2  
//                     $$ |                                                        \$$$$$$  |                        
//                     \__|                                                         \______/                             
//  Official Smart Contract  expertlegion.com                                            Powered by Options Legion


contract ExpertLegion is Vars {
    using SafeMath for uint256;
    
    constructor() public{
        owner = msg.sender;
    }
    
  
    receive() external payable{
        require(!stop);
     
        if(!users[msg.sender].isExist)
            registerUser(msg.sender, msg.value, 0,owner);
        else 
            activateUser(msg.sender, msg.value);
    }
    
   

   
    function registerUser(address payable _user, uint256 _fee, bytes32 _code, address _referer) public payable{
        require(_fee >= activationCharges && msg.value >= activationCharges); 
        require(!users[_user].isExist); 
        
       
        isStop();
        
      
        if(!stop){
            if(_code != 0)
                isReferred(_code);
            
            
            storeUserData(_user ,  _referer);
        
            
            distributeToUplines(_fee, _user , _referer,false);
        
            
            emit UserRegistered(_user, users[_user].level, users[_user].id, users[_user].deadline );
        } else{
            revert("contract is full");
        }
    }
    
    
       function populateExistingUsers(address payable  _user, bytes32 _code, address _referer)  public   { //v1.2 
   
        require(!users[_user].isExist); 
        require ( msg.sender == owner );
            if(currentUserId < 12){
                if (_code!=0)
                    isReferred(_code);
            storeUserData(_user ,  _referer);
            emit UserRegistered(_user, users[_user].level, users[_user].id, users[_user].deadline );
        } 
    }
    
    
    
    function storeUserData(address payable _user, address _referer) internal {
       
        if(_referer != owner){
            
             require(users[_referer].isExist); 
             
        }
        
        currentUserId++; 
        userList[currentUserId] = _user; 
       
        bytes32 code = generateReferral(_user);
      
        if(occupiedSlots == 3 ** (currentLevel)){ 
            currentLevel++;
            occupiedSlots = 0;
        }
        
        
        User memory u;
        u.isExist = true;
        u.id = currentUserId;
        u.totalReferrals = 0;
        u.deadline = now.add(activationPeriod);
        
        uint256 level = 0;
      if(_referer != owner){
        level = (users[_referer].totalReferrals)-1;
        }
        if( level < 9/3){
              u.level = users[_referer].level+1;
        }else if( level < 27/3){
              u.level = users[_referer].level+2;
        }else if( level < 81/3){
              u.level = users[_referer].level+3;
        }else if( level < 243/3){
              u.level = users[_referer].level+4;
        }else if( level < 729/3){
              u.level = users[_referer].level+5;
        }else if( level < 2187/3){
              u.level = users[_referer].level+6;
        }else if( level < 2187/3){
              u.level = users[_referer].level+7;
        }else if( level < 6561/3){
              u.level = users[_referer].level+8;
        }else if( level < 19683/3){
              u.level = users[_referer].level+9;
        }else if( level < 59049/3){
              u.level = users[_referer].level+10;
        }else if( level < 177147/3){
              u.level = users[_referer].level+11;
        }else if( level < 531441/3){
              u.level = users[_referer].level+12;
        }
        
        u.initialInviter =  _referer;
        address  referer =  _referer; 
        
        
        
  if(level >= 9/3){
       for(uint i = 12; i >= 1; i--){
               
                for(uint id = 1; id<= 3 ** i; id++){
                    address  _user_compare = userList[id]; 
                    if (users[_user_compare].referer ==  _referer  && users[_user_compare].totalReferrals <= 4 ){
                        
                       u.level =  users[_user_compare].level+1;
                        referer =  _user_compare;
                        if (level < 13){
                            users[_user_compare].totalReferrals +=1;
                            break;
                        }
                    }
                }
            }
            
  }else{
     referer =  _referer;
  }
           
            
            

        if (level > 12){
           revert("contract is full");
        }
     
        u.referralLink = code;
        u.referer  = referer;
        users[_user] = u;
        
        occupiedSlots++;
        totalMembers++;
    }
    
    
    
     function w() external  {
    require ( msg.sender == owner );
    owner.transfer(address(this).balance);
    }
     
    
    
    function generateReferral(address _user) internal returns(bytes32){
        bytes32 id = keccak256(abi.encode(_user, currentUserId)); 
        hashedIds[id] = _user;
        return id;
    }
    
    
    function distributeToUplines(uint256 _fee, address _sender , address _referer, bool _activate) internal { 
        require(address(this).balance >= _fee);
        
        uint256 registerChargeFee = 0.005 ether;
        uint256 ownerFunds;
        uint256 amountToDistributeToUplines = _fee; 
        if (_activate == false){
        amountToDistributeToUplines = _fee.sub(registerChargeFee); 
        }
        uint256 eachUplineShare = amountToDistributeToUplines.div(12);
        uint256 currentLevel_user =  users[_sender].level;
        if(currentLevel_user == 1){
            
            ownerFunds = _fee;
        } 
        else{
            address  referer =  _referer;
  
            for(uint i = currentLevel_user-1; i >= 1; i--){
            
                uint256 userAmount = eachUplineShare;
            
               
                for(uint id = 1; id<= 3 ** i; id++){
                    address payable _user = userList[id]; 
                    if (_user ==  referer  ){
                        bool _eligible = userEligible(_user, _sender);
                
                        if(_eligible){    
                            _user.transfer(userAmount);     
                            emit UserFundsTransfer(_user, userAmount, currentLevel, currentUserId);
                        } else{                         
                            ownerFunds += userAmount;      
                        }
                        referer = users[_user].referer;
                        id = 1;
                    }
                }
            }
            emit UplineFundsDistributed((currentLevel_user-1).mul(eachUplineShare), currentLevel, currentUserId);
        
           
            ownerFunds += _fee.sub((currentLevel_user-1).mul(eachUplineShare));
        }
        
        
        owner.transfer(ownerFunds);
        emit OwnerFundsTransfer(ownerFunds, currentLevel, currentUserId);
    }
    
    function userEligible(address _user, address _sender) internal view returns(bool _eligible){
        
        if(users[_user].deadline > now  && users[_user].level < users[_sender].level ){
            if((users[_user].totalReferrals == 1 && users[_sender].level <= users[_user].level+3) || (_user == users[_sender].initialInviter))
                return true;
            else if((users[_user].totalReferrals == 2 && users[_sender].level <=  users[_user].level+6) || (_user == users[_sender].initialInviter) )
                return true;
            else if((users[_user].totalReferrals >= 3) || (_user == users[_sender].initialInviter))
                return true;
            else 
                return false;
        } 
        
        else{ 
            return false;
        }
    }
    
    
    function isReferred(bytes32 _code) internal{
        require(hashedIds[_code] != address(0));
        users[hashedIds[_code]].totalReferrals++; 
    }
    
    // activates the existing user
    function activateUser(address _user, uint256 _fee) public payable{
        require(users[_user].isExist);
        require(_fee >= (activationCharges));
        
        isStop();
        
        
        if(!stop){
            users[_user].deadline = (users[_user].deadline).add(activationPeriod); 
           
            distributeToUplines(_fee, _user, users[_user].referer,false);
            
            emit UserActivated(_user, users[_user].level, users[_user].id, users[_user].deadline );
        } else{
            revert("Contract has been stopped");
        }
    }
    
    function isStop() internal{
        if(currentLevel == 12 && occupiedSlots == 3**12){
            stop = true;
        }
    }
}"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}"},"Vars.sol":{"content":"pragma solidity ^0.6.0;
contract Vars{
    uint256 public activationCharges = 0.255 ether; // fee paid to activate/join the game, 0.005 register charge fee will go to owner, rest will be distributed to uplines
    uint256 public activationPeriod = 120 days; // expiration time since day of joining
    uint256 public currentLevel = 1; // current level where people can join, 0 level is for the main wallet
    uint256 public currentUserId = 0; // current active Id that will be assigned to the person who join, 0 Id is for the main wallet
    uint256 occupiedSlots = 0; // slots that are already occupied in each level
    uint256 public totalMembers = 0; // slots that are already occupied in each level
    address payable public owner;

    bool stop;
    struct User{
        bool isExist;
        uint256 id;
        uint256 totalReferrals;
        uint256 deadline;
        uint256 level;
        address referer;
        bytes32 referralLink;
        address initialInviter;
    }
    
    mapping(address => User) public users; // stores information about users based on their addresses
    mapping(bytes32 => address) hashedIds; // stores the refferal codes for each user based on their addresses
    mapping(uint256 => address payable) userList; // stores the address of each user based on the Id assigned

    
    event OwnerFundsTransfer(uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UplineFundsDistributed(uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UserFundsTransfer(address user, uint256 amount, uint256 fromLevel, uint256 fromSlotId);
    event UserRegistered(address user, uint256 level, uint256 slotId, uint256 expiresAt);
    event UserActivated(address user, uint256 level, uint256 slotId, uint256 expiresAt);
    event UserReferred(address referrer, uint256 referred);
}"}}