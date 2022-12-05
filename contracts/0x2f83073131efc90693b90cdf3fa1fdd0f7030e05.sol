{"AggregatorV3Interface.sol":{"content":"pragma solidity >=0.4.24;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
"},"ChainLink.sol":{"content":"pragma solidity 0.4.24;

import "./AggregatorV3Interface.sol";
import './TestTokens.sol';

contract ChainLink {
    
    mapping(address => AggregatorV3Interface) internal priceContractMapping;
    mapping (address => bool) public assetsWithPriceFeedBasedOnUSD;
    address public admin;
    bool public paused = false;
    address public wethAddress;
    AggregatorV3Interface public USDETHPriceFeed;

    /**
     * Sets the initial assets and admin
     * Add assets and set Weth Address using their own functions
     */
    constructor() public {
        admin = msg.sender;
    }
    
    /**
     * Modifier to restrict functions only by admins
     */
    modifier onlyAdmin() {
        require(msg.sender == admin,"Only the Admin can perform this operation");
        _;
    }
    
    /**
     * Event declarations for all the operations of this contract
     */
    event assetAdded(address assetAddress, address priceFeedContract);
    event assetRemoved(address assetAddress);
    event adminChanged(address oldAdmin, address newAdmin);
    event wethAddressSet(address wethAddress);
    event USDETHPriceFeedSet(address USDETHPriceFeed);
    event contractPausedOrUnpaused(bool currentStatus);

    /**
     * Allows admin to add a new asset for price tracking
     */
    function addAsset(address assetAddress, address priceFeedContract, bool _assetWithPriceFeedBasedOnUSD) public onlyAdmin {
        if (_assetWithPriceFeedBasedOnUSD) {
            require(USDETHPriceFeed != address(0),"USDETHPriceFeed not set");
        }
        priceContractMapping[assetAddress] = AggregatorV3Interface(priceFeedContract);
        assetsWithPriceFeedBasedOnUSD[assetAddress] = _assetWithPriceFeedBasedOnUSD;
        emit assetAdded(assetAddress, priceFeedContract);
    }
    
    /**
     * Allows admin to remove an existing asset from price tracking
     */
    function removeAsset(address assetAddress) public onlyAdmin {
        priceContractMapping[assetAddress] = AggregatorV3Interface(address(0));
        emit assetRemoved(assetAddress);
    }
    
    /**
     * Allows admin to change the admin of the contract
     */
    function changeAdmin(address newAdmin) public onlyAdmin {
        emit adminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * Allows admin to set the weth address
     */
    function setWethAddress(address _wethAddress) public onlyAdmin {
        wethAddress = _wethAddress;
        emit wethAddressSet(_wethAddress);
    }

    /**
     * Allows admin to set the weth address
     */
    function setUSDETHPriceFeedAddress(AggregatorV3Interface _USDETHPriceFeed) public onlyAdmin {
        USDETHPriceFeed = _USDETHPriceFeed;
        emit USDETHPriceFeedSet(_USDETHPriceFeed);
    }

    /**
     * Allows admin to pause and unpause the contract
     */
    function togglePause() public onlyAdmin {
        if (paused) {
            paused = false;
            emit contractPausedOrUnpaused(false);
        }
        else {
            paused = true;
            emit contractPausedOrUnpaused(true);
        }
    }

    /**
     * Returns the latest price
     */
    function getAssetPrice(address asset) public view returns (uint) {
        // Return 1 * 10^18 for WETH, otherwise return actual price
        if(!paused && asset == wethAddress) {
            return 1000000000000000000;
        }
        // Capture the decimals in the ERC20 token
        uint8 assetDecimals = TestTokens(asset).decimals();
        if(!paused && priceContractMapping[asset] != address(0)) {
            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = priceContractMapping[asset].latestRoundData();
            // If the round is not complete yet, timestamp is 0
            require(timeStamp > 0, "Round not complete");
            // Calculate USD/ETH price for contracts using USD based price feed
            if(assetsWithPriceFeedBasedOnUSD[asset]) {
                int priceUSD;
                (
                    roundID, 
                    priceUSD,
                    startedAt,
                    timeStamp,
                    answeredInRound
                ) = USDETHPriceFeed.latestRoundData();
                // If the round is not complete yet, timestamp is 0
                require(timeStamp > 0, "Round not complete");
                uint returnedPrice = uint(price) * uint(priceUSD) / (10 ** 8);
                return returnedPrice;
            } else {
                if(price >0) {
                // Magnify the result based on decimals
                return (uint(price) * (10 ** (18 - uint(assetDecimals))));
            }
            else {
                return 0;
            }
            }
        }
        else {
            return 0;
        }
    }

    function fallback() public payable {
        require(msg.sender.send(msg.value),"Fallback function initiated but refund failed");
    }
}"},"TestTokens.sol":{"content":"pragma solidity 0.4.24;

contract TestTokens {
//Variables
string public name;
string public symbol; // Usually is 3 or 4 letters long
uint8 public decimals; // maximum is 18 decimals
uint256 public supply;

mapping(address => uint) public balances;
mapping(address => mapping(address => uint)) public allowed;
//Events
event Transfer(address sender, address receiver, uint256 tokens);
event Approval(address sender, address delegate, uint256 tokens);
//constructor
constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    supply = _supply * 10**18;
    balances[msg.sender] = _supply * 10**18;
}
//Functions
//return the total number of tokens that you have
function totalSupply() external view returns (uint256){
    return supply;
} 

//How many tokens does this person have
function balanceOf(address tokenOwner) external view returns (uint){
    return balances[tokenOwner];
} 

//helps in transferring from your account to another person
function transfer(address receiver, uint numTokens) external returns (bool){
    require(msg.sender != receiver,"Sender and receiver can't be the same");
    require(balances[msg.sender] >= numTokens,"Not enough balance");
    balances[msg.sender] -= numTokens;
    balances[receiver] += numTokens;
    emit Transfer(msg.sender,receiver,numTokens);
    return true;
} 

// Used to delegate authority to send tokens without my approval
function approve(address delegate, uint numTokens) external returns (bool){
    require(msg.sender != delegate,"Sender and delegate can't be the same");
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender,delegate,numTokens);
    return true;
} 

// How much has the owner delegated/approved to the delegate
function allowance(address owner, address delegate) external view returns (uint){
    return allowed[owner][delegate];
} 

// Used by exchanges to send money from owner to buyer
function transferFrom(address owner, address buyer, uint numTokens) external returns (bool){
    require(owner != buyer,"Owner and Buyer can't be the same");
    require(balances[owner] >= numTokens,"Not enough balance");
    require(allowed[owner][msg.sender] >= numTokens,"Not enough allowance");
    balances[owner] -= numTokens;
    balances[buyer] += numTokens;
    allowed[owner][msg.sender] -= numTokens;
    emit Transfer(owner,buyer,numTokens);
    return true;
}

// Should not be used in production
// Only to allocate testnet tokens to user for testing purposes
function allocateTo(address _owner, uint256 value) public {
        balances[_owner] += value;
        supply += value;
        emit Transfer(address(this), _owner, value);
    }
}"}}