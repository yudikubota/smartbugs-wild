{"destructible.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

    constructor() public payable { }

    /**
     * @dev Transfers the current balance to the owner and terminates the contract.
     */
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}"},"ownable.sol":{"content":"pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

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
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}"},"pausable.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns(bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}"},"repayable.sol":{"content":"pragma solidity ^0.4.25;

import "./SafeMath.sol";

contract Repaying {
    using SafeMath for uint256;
    bool repayLock;
    uint256 maxGasPrice = 4000000000;
    event Repaid(address user, uint256 amt);

    modifier repayable {
        if(!repayLock) {
            repayLock = true;
            uint256 startGas = gasleft();
            _;
            uint256 gasUsed = startGas.sub(gasleft());
            uint256 gasPrice = maxGasPrice.min256(tx.gasprice);
            uint256 repayal = gasPrice.mul(gasUsed.add(41761));
            tx.origin.send(repayal);
            emit Repaid(tx.origin, repayal);
            repayLock = false;
        }
        else {
            _;
        }
    }
}"},"SafeMath.sol":{"content":"pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function abs128(int128 a) internal constant returns (int128) {
        return a < 0 ? a * -1 : a;
    }
}"},"tokenInterfaces.sol":{"content":"pragma solidity ^0.4.25;

//for any ERC20 token
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

//WednesdayCoin Interface
contract WednesdayCoin is ERC20Interface {
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success);
}"},"WednesdayClub.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";
import "./pausable.sol";
import "./destructible.sol";
import "./tokenInterfaces.sol";
import "./repayable.sol";
import "./WednesdayClubPost.sol";
import "./WednesdayClubComment.sol";
import "./WednesdayClubUser.sol";

contract WednesdayClub is Ownable, Destructible, Pausable, Repaying, WednesdayClubPost, WednesdayClubComment, WednesdayClubUser {

    //onlyWednesdays Modifier
    modifier onlyWednesdays() {
        //require true only for testing
        //require(true);
        uint8 dayOfWeek = uint8((now / 86400 + 4) % 7);
        require(dayOfWeek == 3);
        _;
    }

    // WednesdayCoin contract being held
    WednesdayCoin public wednesdayCoin;

    //constructor
    constructor() public {
        //for testing -- 0xEDFc38FEd24F14aca994C47AF95A14a46FBbAA16
        //for prod -- 0x7848ae8F19671Dc05966dafBeFbBbb0308BDfAbD
        wednesdayCoin = WednesdayCoin(0x7848ae8F19671Dc05966dafBeFbBbb0308BDfAbD);
        amountForPost = 10000000000000000000000; //10k
        amountForComment = 1000000000000000000000; //1k
        postInterval = 10 minutes;
        commentInterval = 5 minutes;
        minimumToLikePost = 1000000000000000000000; //1k
        minimumToLikeComment = 100000000000000000000; //100
        minimumForFollow = 100000000000000000000; //100
        minimumForReporting = 100000000000000000000; //100
        minimumForUpdatingProfile = 100000000000000000000; //100
        minimumForBlockingUser = 100000000000000000000; //100
        reportInterval = 10 minutes;
    }

    function () public payable {}

    /*****************************************************************************************
     * Posts logic - add, like, report, delete
     * ***************************************************************************************/
    // Adds a new post
    function writePost(uint256 _id, uint256 _value, string _content, string _media) public onlyWednesdays repayable whenNotPaused whenNotSuspended whenTimeElapsedPost {
        require(amountForPost == _value);
        require(bytes(_content).length > 0 || bytes(_media).length > 0);
        _id = uint256(keccak256(_id, now, blockhash(block.number - 1), block.coinbase));
        //ensure that post doesnot exists
        require(posts[_id].id != _id);
        //for create
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            emit PostContent(_id, _content, _media);
            Post memory post = Post(_id, msg.sender, 0, 0, now, 0);
            userPosts[msg.sender].push(_id);
            posts[_id] = post;
            postIds.push(_id);
            postTime[msg.sender] = now;
        } else {
            revert();
        }
    }

    function likePost(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumToLikePost);
        //ensure that post exists
        if (posts[_id].id == _id) {
            //shouldnt be able to like your own post
            require(posts[_id].poster != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, posts[_id].poster, _value)) {
                posts[_id].value += _value;
                posts[_id].likes++;
            } else {
                revert();
            }
        }
    }

    function reportPost(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(hasElapsedReport());
        //ensure that post exists
        if (posts[_id].id == _id) {
            //shouldnt be able to report your own post
            require(posts[_id].poster != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
                posts[_id].reportCount++;
                reportTime[msg.sender] = now;
            } else {
                revert();
            }
        }
    }

    //delete a user post
    function deleteUserPost(address _user, uint256 _id) public onlyOwner {
        for(uint i = 0; i < userPosts[_user].length; i++) {
            if(userPosts[_user][i] == _id){
                delete userPosts[_user][i];
            }
        }
    }

    //delete a public post
    function deletePublicPost(uint256 _id) public onlyOwner {
        if(posts[_id].id == _id){
            delete posts[_id];
        }
    }

    function deleteIdFromPostIds(uint256 _id) public onlyOwner  {
        uint256 indexToDelete;
        for(uint i = 0; i < postIds.length; i++) {
            if(postIds[i] == _id) {
                indexToDelete = i;
            }
        }
        delete postIds[indexToDelete];
    }
    // deleteAllPosts from PostIds
    function deleteAllPosts() public onlyOwner {
        deleteAllPosts(postIds.length);
    }

    // deleteAllPosts in groups i.e. delete 100, then 100 again, etc - for saving on gas and incase to many
    function deleteAllPosts(uint256 _amountToDelete) public onlyOwner {
        for(uint i = 0; i < _amountToDelete; i++) {
            address poster = posts[postIds[i]].poster;
            deleteUserPost(poster, posts[postIds[i]].id);
            deletePublicPost(posts[postIds[i]].id);
            deleteIdFromPostIds(posts[postIds[i]].id);
        }
    }

    //to make it easier this one calls all delete functions
    function deletePost(address _user, uint256 _id) public onlyOwner {
        deleteUserPost(_user, _id);
        deletePublicPost(_id);
        deleteIdFromPostIds(_id);
    }

    /*****************************************************************************************
     * Comments logic - add, like, report, delete
     * ***************************************************************************************/
    // Adds a new comment
    function writeComment(uint256 _id, uint256 _parentId, uint256 _value, string _content, string _media) public onlyWednesdays repayable whenNotPaused whenNotSuspended whenTimeElapsedComment {
        require(amountForComment == _value);
        require(bytes(_content).length > 0 || bytes(_media).length > 0);
        _id = uint256(keccak256(_id, now, blockhash(block.number - 1), block.coinbase));
        //require post exists
        require(posts[_parentId].id == _parentId);
        require(comments[_id].id != _id);
        //for create
        if (wednesdayCoin.transferFrom(msg.sender, posts[_parentId].poster, _value)) {
            emit CommentContent(_id, _content, _media);
            Comment memory comment = Comment(_id, _parentId, msg.sender, 0, 0, now, 0);
            userComments[msg.sender].push(_id);
            comments[_id] = comment;
            postComments[_parentId].push(_id);
            commentTime[msg.sender] = now;
        } else {
            revert();
        }
    }

    function likeComment(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumToLikeComment);
        //ensure that comment exists
        if (comments[_id].id == _id) {
            //shouldnt be able to like your own comment
            require(comments[_id].commenter != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, comments[_id].commenter, _value)) {
                comments[_id].value += _value;
                comments[_id].likes++;
            } else {
                revert();
            }
        }
    }

    function reportComment(uint256 _id, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(hasElapsedReport());
        //ensure that post exists
        if (comments[_id].id == _id) {
            //shouldnt be able to report your own post
            require(comments[_id].commenter != msg.sender);
            if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
                comments[_id].reportCount++;
                reportTime[msg.sender] = now;
            } else {
                revert();
            }
        }
    }

    //delete a user comment
    function deleteUserComment(address _user, uint256 _id) public onlyOwner {
        for(uint i = 0; i < userComments[_user].length; i++) {
            if(userComments[_user][i] == _id){
                delete userComments[_user][i];
            }
        }
    }

    //delete a public comment
    function deletePublicComment(uint256 _id) public onlyOwner {
        if(comments[_id].id == _id){
            delete comments[_id];
        }
    }

    //to make it easier this one calls all delete functions
    function deleteComment(address _user, uint256 _id) public onlyOwner {
        deleteUserComment(_user, _id);
        deletePublicComment(_id);
    }

    /*****************************************************************************************
     * User logic - add/update profile info
     * ***************************************************************************************/

    function updateProfile(string _username, string _about, string _profilePic, string _site, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForUpdatingProfile);
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            if (users[msg.sender].id != msg.sender) {
                User memory user = User(msg.sender, '', '', '', '');
                users[msg.sender] = user;
            }
            if (bytes(_username).length > 0) {
                users[msg.sender].username = _username;
            }
            if (bytes(_about).length > 0) {
                users[msg.sender].about = _about;
            }
            if (bytes(_profilePic).length > 0) {
                users[msg.sender].profilePic = _profilePic;
            }
            if (bytes(_site).length > 0) {
                users[msg.sender].site = _site;
            }
        } else {
            revert();
        }
    }


    /*****************************************************************************************
     * Following/Followers logic
     * ***************************************************************************************/

    function follow(address _address, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForFollow);
        require(msg.sender != _address);
        // update that user is following address
        if (wednesdayCoin.transferFrom(msg.sender, _address, _value)) {
            following[msg.sender].push(_address);
            // update address followers
            followers[_address].push(msg.sender);
        } else {
            revert();
        }
    }

    function unfollow(address _address) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(msg.sender != _address);
        // delete that user is folowing address
        for(uint i = 0; i < following[msg.sender].length; i++) {
            if(following[msg.sender][i] == _address){
                delete following[msg.sender][i];
            }
        }
        // delete address followers
        for(i = 0; i < followers[_address].length; i++) {
            if(followers[_address][i] == msg.sender){
                delete followers[_address][i];
            }
        }
    }

    /*****************************************************************************************
     * Blocking/Unblocking users logic
     * ***************************************************************************************/

    function blockUser(address _address, uint256 _value) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(_value >= minimumForBlockingUser);
        require(msg.sender != _address);
        // update that user is following address
        if (wednesdayCoin.transferFrom(msg.sender, this, _value)) {
            blockedUsers[msg.sender].push(_address);
        } else {
            revert();
        }
    }

    function unblockUser(address _address) public onlyWednesdays repayable whenNotPaused whenNotSuspended {
        require(msg.sender != _address);
        // delete that user is folowing address
        for(uint i = 0; i < blockedUsers[msg.sender].length; i++) {
            if(blockedUsers[msg.sender][i] == _address){
                delete blockedUsers[msg.sender][i];
            }
        }
    }

    /*****************************************************************************************
     * Just in case logic
     * ***************************************************************************************/

    // Used for transferring any accidentally sent ERC20 Token by the owner only
    function transferAnyERC20Token(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }

    // Used for transferring any accidentally sent Ether by the owner only
    function transferEther(address _dest, uint _amount) public onlyOwner {
        _dest.transfer(_amount);
    }

    // Used if a user wants to delete all their data
    function nukeMe() public {
        nukePosts();
        nukeComments();
        nukeUser();
    }

    function nukePosts() public {
        for (uint i = 0; i < userPosts[msg.sender].length; i++) {
            uint256 id = userPosts[msg.sender][i];
            delete posts[id];
            delete postIds[id];
        }
        delete userPosts[msg.sender];
    }

    function nukeComments() public {
        for (uint i = 0; i < userComments[msg.sender].length; i++) {
            uint256 id = userComments[msg.sender][i];
            delete comments[id];
        }
        delete userComments[msg.sender];
    }

    function nukeUser() public {
        delete users[msg.sender];
        delete blockedUsers[msg.sender];
        delete followers[msg.sender];
        delete following[msg.sender];
    }
}"},"WednesdayClubComment.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubComment is Ownable {
    //Structure of a comment
    struct Comment {
        uint256 id;
        uint256 parentId;
        address commenter;
        uint256 value;
        uint256 likes;
        uint256 timestamp;
        uint256 reportCount;
    }

    modifier whenTimeElapsedComment() {
        require(hasElapsedComment());
        _;
    }

    event CommentContent(uint256 indexed id, string content, string media);

    // list of ids of all comments
    mapping(uint256 => Comment) public comments;

    // The comments that each user has commented
    mapping(address => uint256[]) public userComments;

    // list of comments for each post id
    mapping(uint256 => uint256[]) public postComments;

    // amountForComment
    uint256 public amountForComment;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public commentTime;

    //interval user has to wait to be able to post
    uint public commentInterval;

    // minimum amount For likes
    uint256 public minimumToLikeComment;

    function hasElapsedComment() public view returns (bool) {
        if (now >= commentTime[msg.sender] + commentInterval) {
            //has elapsed from postTime[msg.sender]
            return true;
        }
        return false;
    }

    function setMinimumToLikeComment(uint _minimumToLikeComment) public onlyOwner {
        minimumToLikeComment = _minimumToLikeComment;
    }

    function postCommentsLength(uint256 _postId) public view returns (uint256) {
        return postComments[_postId].length;
    }
}"},"WednesdayClubPost.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubPost is Ownable {
    // The structure of a post
    struct Post {
        uint256 id;
        address poster;
        uint256 value;
        uint256 likes;
        uint256 timestamp;
        uint256 reportCount;
    }

    modifier whenTimeElapsedPost() {
        require(hasElapsedPost());
        _;
    }

    event PostContent(uint256 indexed id, string content, string media);

    // The posts that each address has written
    mapping(address => uint256[]) public userPosts;

    // All the posts ever written by ID
    mapping(uint256 => Post) public posts;

    // Keep track of all IDs - use for loading
    uint256[] public postIds;

    // amountForPost
    uint256 public amountForPost;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public postTime;

    //interval user has to wait to be able to post
    uint public postInterval;

    // minimum amount For likes
    uint256 public minimumToLikePost;

    // minimum amount For reporting
    uint256 public minimumForReporting;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public reportTime;

    //interval user has to wait to be able to post
    uint public reportInterval;

    function getUserPostLength(address _user) public view returns (uint256){
        return userPosts[_user].length;
    }

    function hasElapsedPost() public view returns (bool) {
        if (now >= postTime[msg.sender] + postInterval) {
            //has elapsed from postTime[msg.sender]
            return true;
        }
        return false;
    }

    function hasElapsedReport() public view returns (bool) {
        if (now >= reportTime[msg.sender] + reportInterval) {
            //has elapsed from reportTime[msg.sender]
            return true;
        }
        return false;
    }

    function getPostIdsLength() public view returns (uint256){
        return postIds.length;
    }

    function setAmountForPost(uint256 _amountForPost) public onlyOwner {
        amountForPost = _amountForPost;
    }

    function setPostInterval(uint _postInterval) public onlyOwner {
        postInterval = _postInterval;
    }

    function setReportingInterval(uint _reportInterval) public onlyOwner {
        reportInterval = _reportInterval;
    }

    function setMinimumForReporting(uint _minimumForReporting) public onlyOwner {
        minimumForReporting = _minimumForReporting;
    }

    function setMinimumToLikePost(uint _minimumToLikePost) public onlyOwner {
        minimumToLikePost = _minimumToLikePost;
    }
}"},"WednesdayClubUser.sol":{"content":"pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubUser is Ownable {

    struct User {
        address id;
        string username;
        string about;
        string profilePic;
        string site;
    }

    modifier whenNotSuspended() {
        require(hasSuspensionElapsed());
        _;
    }

    mapping(address => User) public users;

    // banned users
    mapping (address => uint) public suspendedUsers;

    // blocked users
    mapping (address => address[]) public blockedUsers;

    // followers: list of who is following
    mapping(address => address[]) public followers;

    // following: list of who you are following
    mapping(address => address[]) public following;

    // minimum amount For following
    uint256 public minimumForFollow;

    // minimum amount For updating profile
    uint256 public minimumForUpdatingProfile;

    // minimum amount For blocking user
    uint256 public minimumForBlockingUser;

    function hasSuspensionElapsed() public view returns (bool) {
        if (now >= suspendedUsers[msg.sender]) {
            //has elapsed from suspendedUsers[msg.sender]
            return true;
        }
        return false;
    }

    function suspendUser(address _user, uint _time) public onlyOwner {
        suspendedUsers[_user] = now + _time;
    }

    function setMinimumForFollow(uint _minimumForFollow) public onlyOwner {
        minimumForFollow = _minimumForFollow;
    }

    function getFollowersLength(address _address) public view returns (uint256){
        return followers[_address].length;
    }

    function getFollowingLength(address _address) public view returns (uint256){
        return following[_address].length;
    }
}"}}