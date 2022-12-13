/**
 *Submitted for verification at Etherscan.io on 2019-12-23
*/

pragma solidity ^0.4.24;

//-------------------------safe_math-----------------------------------

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


contract DistributeTokens {
    using SafeMath for uint;
    
    address public owner; 
    address[] investors; 
    uint[] public usage_count;
    uint  interest;
    uint public count;//ç®åäººæ¸
    uint public total_count;//åèéçäººæ¸
    uint public son = 2;
    uint public mon = 3;
    
   

    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address=>uint)my_interest;
    mapping(address=>user_info) public userinfo; 
    mapping(address=>address)public verification;
    mapping(address=>uint) public Dividing_times;
    mapping(uint=>address) number;
    mapping(address=>uint)public Amount_invested;
    mapping(address=>address)public quite_user;
    mapping(address=>address)public propose;
    
    event invest_act(address user, uint value, uint interest);
    event Recommended( address recommend ,address recommended);
    event end( address user);
    
    struct user_info{
        uint amount;
        uint user_profit; //æè³èçå©æ¯
        uint block_number;
        uint timestamp;
    }

    //------------------æè³------------------------------
    function invest() public payable {
        require(msg.sender != verification[msg.sender],"éçµå¸³èä½¿ç¨é");
        require(msg.value != 0 ,"ä¸è½çºé¶");
        verification[msg.sender]=msg.sender;
        
        Amount_invested[msg.sender]=msg.value;
        my_interest[msg.sender]=interest;
        
        investors.push(msg.sender);  //push å°±æ¯ææ±è¥¿å é²å»é£åè£¡é¢
        usage_count.push(1);
        fee();//æçºè²»
        
        userinfo[msg.sender]=user_info(msg.value,interest,block.number,block.timestamp);
        count=count.add(1);
        total_count=total_count.add(1);
        
        emit invest_act(msg.sender,msg.value,interest);
        
    }
    
    
    function fee()private{
        owner.transfer(msg.value.div(50));
    }
    
    function querybalance()public view returns (uint){
        return address(this).balance;
    }
    
    //------------------æ¨è¦äºº------------------------------
    function recommend (address Recommend) public {
        require(verification[Recommend] == Recommend,"æ²æéåå°å");
        require(Recommend != msg.sender,"ä¸å¯ä»¥æ¨è¦èªå·±");
        require(propose[msg.sender] != Recommend,"ä½ å·²ç¶æ¨è¦ééçµå°åäº");
        propose[msg.sender]=Recommend;
        Recommend.transfer(Amount_invested[msg.sender].div(100));
        emit Recommended(msg.sender,Recommend);
    }
    
    
    //------------------åéçé------------------------------

    function distribute(uint a, uint b) public {
        require(msg.sender == owner); 
        owner.transfer(address(this).balance.div(200));
        
        for(uint i = a; i < b; i++) {
            investors[i].transfer(Amount_invested[investors[i]].div(my_interest[investors[i]]));
            number[i]=investors[i];
            Dividing_times[number[i]] = usage_count[i]++;
        } 
    }
   
    //------------------å°è£å©æ¯è³è¨------------------------------
    
    function getInterest() public view returns(uint){
        if(interest <= 50000 && interest >= 0)
         return interest;
        else
         return 0;
    }    
    
    
    function Set_Interest(uint key)public{
        require(msg.sender==owner);
        if(key<=50000){
            interest = key;
        }else{
            interest = interest;
        }
    }
    
    //------------------ç§»ç½®å®å¨åå------------------------------
    
    function Safe_trans_A() public {
        require(owner==msg.sender);
        owner.transfer(querybalance());
    } 
    
     function Safe_trans_B( uint volume) public {
        require(owner==msg.sender);
        owner.transfer(volume);
    } 
    
    
    
    //------------------éåºä¸¦åºé------------------------------
    
    function Set_quota(uint _son, uint _mon)public {
        require(owner == msg.sender);
        if(_son<_mon && _son<=100 && _mon<=100){
            son=_son;
            mon=_mon;
        }else{
            son=son;
            mon=mon;
        }
    }
    
    
    function quit()public {
        
        if(quite_user[msg.sender]==msg.sender){
            revert("ä½ å·²ç¶éåºäº");
        }else{
        msg.sender.transfer(Amount_invested[msg.sender].mul(son).div(mon));
        quite_user[msg.sender]=msg.sender;
        my_interest[msg.sender]=1000000;
        Amount_invested[msg.sender]=1;
        userinfo[msg.sender]=user_info(0,0,block.number,block.timestamp);
        count=count.sub(1);
        }
        
        emit end(msg.sender);
    }
    
    
}