{"ethBridge.sol":{"content":"pragma solidity 0.4.25;

import "./multiOwnable.sol";
import "./IERC20.sol";

contract ethBridge is Multiownable {
    IERC20 private token;

    mapping(address => uint256) public tokensSent;
    mapping(address => uint256) public tokensRecieved;
    mapping(address => uint256) public tokensRecievedButNotSent;
    address[] public feeOwners;
    mapping(address => uint) public feeOwnersIndices;
    uint256 public fee;

    event FeeOwnersUpdated(address[] previousCallers, address[] newCallers);

    constructor (address _token) public {
        token = IERC20(_token);
        feeOwners.push(msg.sender);
        feeOwnersIndices[msg.sender] = 1;
        fee = 150000 * 10**9;
    }

    uint256 amountToSent;
    bool transferStatus;

    bool avoidReentrancy = false;

    function updateBaseFee(uint256 _feeGwei) public onlyAllOwners {
        fee = _feeGwei * 10**9;
    }

    function setOwnersForFee(address[] _feeOwners) public onlyAllOwners {
        for (uint j = 0; j < owners.length; j++) {
            delete feeOwnersIndices[owners[j]];
        }
        for (uint i = 0; i < _feeOwners.length; i++) {
            require(_feeOwners[i] != address(0), "FeeOwners: callers array contains zero");
            require(feeOwnersIndices[_feeOwners[i]] == 0, "FeeOwners: callers array contains duplicates");
            require(ownersIndices[_feeOwners[i]] > 0, "FeeOwners: owners not match to callers");
            feeOwnersIndices[_feeOwners[i]] = i + 1;
        }
        emit FeeOwnersUpdated(feeOwners, _feeOwners);
        feeOwners = _feeOwners;
    }

    function sendTokens(uint256 amount) public {
        require(msg.sender != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(token.balanceOf(msg.sender) >= amount,"Not enough balance");

        transferStatus = token.transferFrom(msg.sender, address(this), amount);
        if (transferStatus == true) {
            tokensRecieved[msg.sender] += amount;
        }
    }

    function writeTransaction(address user, uint256 amount) public onlySomeOwners(feeOwners.length) {
        require(user != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(!avoidReentrancy);

        avoidReentrancy = true;
        tokensRecievedButNotSent[user] += amount;
        avoidReentrancy = false;
    }

    function recieveTokens(uint256[] memory commissions) public payable {
        if (tokensRecievedButNotSent[msg.sender] != 0) {
            require(commissions.length == feeOwners.length, "The number of commissions and owners does not match");
            uint256 sum;
            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }
            require(msg.value >= sum, "Not enough ETH (The amount of ETH is less than the amount of commissions.)");
            require(msg.value >= feeOwners.length * fee, "Not enough ETH (The amount of ETH is less than the internal commission.)");

            for (i = 0; i < feeOwners.length; i++) {
                uint256 commission = commissions[i];
                feeOwners[i].transfer(commission);
            }

            amountToSent = tokensRecievedButNotSent[msg.sender] - tokensSent[msg.sender];
            token.transfer(msg.sender, amountToSent);
            tokensSent[msg.sender] += amountToSent;
        }
    }

    function withdrawTokens(uint256 amount, address reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(token.balanceOf(address(this)) >= amount,"Not enough balance");

        token.transfer(reciever, amount);
    }

    function withdrawETHer(uint256 amount, address reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(address(this).balance >= amount,"Not enough balance");

        reciever.transfer(amount);
    }
}
"},"IERC20.sol":{"content":"pragma solidity 0.4.25;

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
"},"multiOwnable.sol":{"content":"pragma solidity ^0.4.25;

contract Multiownable {

    // VARIABLES

    uint256 public ownersGeneration;
    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address internal insideCallSender;
    uint256 internal insideCallCount;

    // Reverse lookup tables for owners and allOperations
    mapping(address => uint) public ownersIndices; // Starts from 1
    mapping(bytes32 => uint) public allOperationsIndicies;

    // Owners voting mask per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

    // EVENTS

    event OwnershipTransferred(address[] previousOwners, uint howManyOwnersDecide, address[] newOwners, uint newHowManyOwnersDecide);
    event OperationCreated(bytes32 operation, uint howMany, uint ownersCount, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint howMany, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany, uint ownersCount, address performer);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller);
    
    // ACCESSORS

    function isOwner(address wallet) public view returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public view returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public view returns(uint) {
        return allOperations.length;
    }

    // MODIFIERS

    /**
    * @dev Allows to perform method by any of the owners
    */
    modifier onlyAnyOwner {
        if (checkHowManyOwners(1)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = 1;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after many owners call it with the same arguments
    */
    modifier onlyManyOwners {
        if (checkHowManyOwners(howManyOwnersDecide)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howManyOwnersDecide;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after all owners call it with the same arguments
    */
    modifier onlyAllOwners {
        if (checkHowManyOwners(owners.length)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = owners.length;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    /**
    * @dev Allows to perform method only after some owners call it with the same arguments
    */
    modifier onlySomeOwners(uint howMany) {
        require(howMany > 0, "onlySomeOwners: howMany argument is zero");
        require(howMany <= owners.length, "onlySomeOwners: howMany argument exceeds the number of owners");
        
        if (checkHowManyOwners(howMany)) {
            bool update = (insideCallSender == address(0));
            if (update) {
                insideCallSender = msg.sender;
                insideCallCount = howMany;
            }
            _;
            if (update) {
                insideCallSender = address(0);
                insideCallCount = 0;
            }
        }
    }

    // CONSTRUCTOR

    constructor() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

    // INTERNAL METHODS

    /**
     * @dev onlyManyOwners modifier helper
     */
    function checkHowManyOwners(uint howMany) internal returns(bool) {
        if (insideCallSender == msg.sender) {
            require(howMany <= insideCallCount, "checkHowManyOwners: nested owners modifier check require more owners");
            return true;
        }

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require(ownerIndex < owners.length, "checkHowManyOwners: msg.sender is not an owner");
        bytes32 operation = keccak256(abi.encodePacked(msg.data, ownersGeneration));

        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0, "checkHowManyOwners: owner already voted for the operation");
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] + 1;
        votesCountByOperation[operation] = operationVotesCount;
        if (operationVotesCount == 1) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
            emit OperationCreated(operation, howMany, owners.length, msg.sender);
        }
        emit OperationUpvoted(operation, operationVotesCount, howMany, owners.length, msg.sender);

        // If enough owners confirmed the same operation
        if (votesCountByOperation[operation] == howMany) {
            deleteOperation(operation);
            emit OperationPerformed(operation, howMany, owners.length, msg.sender);
            return true;
        }

        return false;
    }

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) { // Not last
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        //allOperations.length-1
        allOperations.push(allOperations[allOperations.length-1]);

        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

    // PUBLIC METHODS

    /**
    * @dev Allows owners to change their mind by cacnelling votesMaskByOperation operations
    * @param operation defines which operation to delete
    */
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0, "cancelPending: operation not found for this user");
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        uint operationVotesCount = votesCountByOperation[operation] - 1;
        votesCountByOperation[operation] = operationVotesCount;
        emit OperationDownvoted(operation, operationVotesCount, owners.length, msg.sender);
        if (operationVotesCount == 0) {
            deleteOperation(operation);
            emit OperationCancelled(operation, msg.sender);
        }
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    */
    function transferOwnership(address[] memory newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

    /**
    * @dev Allows owners to change ownership
    * @param newOwners defines array of addresses of new owners
    * @param newHowManyOwnersDecide defines how many owners can decide
    */
    function transferOwnershipWithHowMany(address[] memory newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0, "transferOwnershipWithHowMany: owners array is empty");
        require(newOwners.length <= 256, "transferOwnershipWithHowMany: owners count is greater then 256");
        require(newHowManyOwnersDecide > 0, "transferOwnershipWithHowMany: newHowManyOwnersDecide equal to 0");
        require(newHowManyOwnersDecide <= newOwners.length, "transferOwnershipWithHowMany: newHowManyOwnersDecide exceeds the number of owners");

        // Reset owners reverse lookup table
        for (uint j = 0; j < owners.length; j++) {
            delete ownersIndices[owners[j]];
        }
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0), "transferOwnershipWithHowMany: owners array contains zero");
            require(ownersIndices[newOwners[i]] == 0, "transferOwnershipWithHowMany: owners array contains duplicates");
            ownersIndices[newOwners[i]] = i + 1;
        }
        
        emit OwnershipTransferred(owners, howManyOwnersDecide, newOwners, newHowManyOwnersDecide);
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;
        // allOperations.length = 0;
        allOperations.push(allOperations[0]);
        ownersGeneration++;
    }

}"}}