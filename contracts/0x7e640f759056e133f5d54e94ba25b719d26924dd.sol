{"FITHTokenSale.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMathLib.sol";

/**
 * @dev Fiatech FITH token sale contract.
 */
contract FITHTokenSale
{
	using SafeMathLib for uint;
	
    address payable public owner;
    
	IERC20 public tokenContract;
	
	uint256 public tokenPrice;
    uint256 public tokensSold;
	
	// tokens bought event raised when buyer purchases tokens
    event TokensBought(address _buyer, uint256 _amount, uint256 _tokensSold);
	
	// token price update event
	event TokenPriceUpdate(address _admin, uint256 _tokenPrice);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor(IERC20 _tokenContract, uint256 _tokenPrice) public
	{
		require(_tokenPrice > 0, "_tokenPrice greater than zero required");
		
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }
	
	modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
	
	function tokensAvailable() public view returns (uint) {
		return tokenContract.balanceOf(address(this));
	}
	
	
	
	function _buyTokens(uint256 _numberOfTokens) internal returns(bool) {
        require(tokensAvailable() >= _numberOfTokens, "insufficient tokens on token-sale contract");
        require(tokenContract.transfer(msg.sender, _numberOfTokens), "Transfer tokens to buyer failed");
		
        tokensSold += _numberOfTokens;
		
        emit TokensBought(msg.sender, _numberOfTokens, tokensSold);
		return true;
    }
	
	function updateTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0 && _tokenPrice != tokenPrice, "Token price must be greater than zero and different than current");
        
		tokenPrice = _tokenPrice;
		emit TokenPriceUpdate(owner, _tokenPrice);
    }
	
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice), "Incorrect number of tokens");
        _buyTokens(_numberOfTokens);
    }
	
    function endSale() public onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Transfer token-sale token balance to owner failed");
		
        // Just transfer the ether balance to the owner
        owner.transfer(address(this).balance);
    }
	
	/**
	 * Accept ETH for tokens
	 */
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		_buyTokens(tks);
    }
	
	
	
	/**
	 * @dev Owner can transfer out (recover) any ERC20 tokens accidentally sent to this contract.
	 * @param tokenAddress Token contract address we want to recover lost tokens from.
	 * @param tokens Amount of tokens to be recovered, usually the same as the balance of this contract.
	 * @return bool
	 */
    function recoverAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool ok) {
		ok = IERC20(tokenAddress).transfer(owner, tokens);
    }
}"},"FITHTokenSaleRefAndPromo.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMathLib.sol";
import "./FITHTokenSaleReferrals.sol";
import "./OrFeedInterface.sol";

/**
 * @dev Fiatech ETH discount sale promotion contract.
 */
contract FITHTokenSaleRefAndPromo is FITHTokenSaleReferrals
{
	using SafeMathLib for uint;
	
	// USDT stable coin smart contrat address
	address public usdtContractAddress;
	
	// Oracle feed for ETH/USDT real time exchange rate contrat address
	address public orFeedContractAddress;
	
	uint public oneEthAsWei = 10**18;
	
	uint public ethDiscountPercent = 5000; // percent = ethDiscountPercent / 10000 = 0.2 = 20%
	
	
	// eth each token sale user used to buy tokens
	mapping(address => uint) public ethBalances;
	
	// USDT balances for users participating in eth promo
	mapping(address => uint) public usdtBalances;
	
	
	// Eth Discount Percent updated event
	event EthDiscountPercentUpdated(address indexed admin, uint newEthDiscountPercent);
	
	// USDT deposit event
	event USDTDeposit(address indexed from, uint tokens);
	
	// USDT withdrawal event
	event USDTWithdrawal(address indexed from, uint tokens);
	
	// Promo ETH bought event
	event PromoEthBought(address indexed user, uint ethWei, uint usdtCost);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor(IERC20 _tokenContract, uint256 _tokenPrice, IERC20 _usdStableCoinContract, OrFeedInterface _orFeedContract)
		FITHTokenSaleReferrals(_tokenContract, _tokenPrice)
		public
	{
		usdtContractAddress = address(_usdStableCoinContract);
		orFeedContractAddress = address(_orFeedContract);
    }
	
	
	
	function setOrFeedAddress(OrFeedInterface _orFeedContract) public onlyOwner returns(bool) {
		require(orFeedContractAddress != address(_orFeedContract), "New orfeed address required");
		
		orFeedContractAddress = address(_orFeedContract);
		return true;
	}
	
	function getEthUsdPrice() public view returns(uint) {
		return OrFeedInterface(orFeedContractAddress).getExchangeRate("ETH", "USDT", "DEFAULT", oneEthAsWei);
	}
	
	function getEthWeiAmountPrice(uint ethWeiAmount) public view returns(uint) {
		return OrFeedInterface(orFeedContractAddress).getExchangeRate("ETH", "USDT", "DEFAULT", ethWeiAmount);
	}
	
	// update eth discount percent as integer down to 0.0001 discount
	function updateEthDiscountPercent(uint newEthDiscountPercent) public onlyOwner returns(bool) {
		require(newEthDiscountPercent != ethDiscountPercent, "EthPromo/same-eth-discount-percent");
		require(newEthDiscountPercent > 0 && newEthDiscountPercent < 10000, "EthPromo/eth-discount-percent-out-of-range");
		
		ethDiscountPercent = newEthDiscountPercent;
		emit EthDiscountPercentUpdated(msg.sender, newEthDiscountPercent);
		return true;
	}
	
	
	
	// referer is address instead of string
	function fithBalanceOf(address user) public view returns(uint) {
		
		return IERC20(tokenContract).balanceOf(user);
    }
	
	//---
	// NOTE: Prior to calling this function, user has to call "approve" on the USDT contract allowing this contract to transfer on his behalf.
	// Transfer usdt stable coins on behalf of the user and register amounts for the ETH promo.
	// NOTE: This is needed for the ETH prmotion:
	// -To register each user USDT amounts for eth promo calculations and also to be able to withdraw user USDT at any time.
	//---
	function depositUSDTAfterApproval(address from, uint tokens) public returns(bool) {
		
		// this contract transfers USDT for deposit on behalf of user after approval
		require(IERC20(usdtContractAddress).transferFrom(from, address(this), tokens), "depositUSDTAfterApproval failed");
		
		// register USDT amounts for each user
		usdtBalances[from] = usdtBalances[from].add(tokens);
		
		emit USDTDeposit(from, tokens);
		
		return true;
	}
	
	//---
	// User withdraws from his USDT balance available
	// NOTE: If sender is owner, he withdraws from USDT profit balance available
	//---
	function withdrawUSDT(uint tokens) public returns(bool) {
		require(usdtBalances[msg.sender] >= tokens, "EthPromo/insufficient-USDT-balance");
		
		// this contract transfers USDT to user
		require(IERC20(usdtContractAddress).transfer(msg.sender, tokens), "EthPromo/USDT.transfer failed");
		
		// register USDT withdrawals for each user
		usdtBalances[msg.sender] = usdtBalances[msg.sender].sub(tokens);
		
		emit USDTWithdrawal(msg.sender, tokens);
		
		return true;
	}
	
	
	
	
	//---
	// Given eth wei amount return cost in USDT stable coin wei with 6 decimals.
	// This function can be used for debug and testing purposes by any user
	// and it is useful to see the discounted price in USDT for given amount of eth a user wants to purchase.
	//---
	function checkEthWeiPromoCost(uint ethWei) public view returns(uint256) {
		uint usdtCost = getEthWeiAmountPrice(ethWei);
		// calculate discounted price
		return calculateUSDTWithDiscount(usdtCost);
	}
	
	//---
	// Function similar to "checkEthWeiPromoCost" but using optimized calculations to compare results.
	//---
	function checkEthWeiPromoCost_Opt(uint ethWei) public view returns(uint256) {
		uint ethPrice = getEthUsdPrice();
		require(ethPrice > 0, "EthPromo/ethPrice-is-zero");
		
		// calculate final discounted price
		//uint usdtCost = ethWei / (10**18) * ethPrice * (10000 - ethDiscountPercent) / 10000;
		uint usdtCost = ethWei.mul(ethPrice).mul(10000 - ethDiscountPercent).div(oneEthAsWei).div(10000);   //oneEthAsWei = 10**18 wei
		return usdtCost;
	}
	
	
	
	// returns eth cost in USDT stable coin wei with 6 decimals
	function calculateEthWeiCost(uint ethWei) public view returns(uint256) {
		return getEthWeiAmountPrice(ethWei);
	}
	
	function calculateUSDTWithDiscount(uint usdt) public view returns(uint256) {
		// we can represent discounts precision down to 0.01% = 0.0001, so we use 10000 factor
		return (usdt.mul(10000 - ethDiscountPercent).div(10000));
	}
	
	//---
	// User buys eth at discount according to eth promo rules and his USDT balance available
	//---
	function buyEthAtDiscount(uint ethWei) public returns(bool) {
		require(ethBalances[msg.sender] >= ethWei, "EthPromo/eth-promo-limit-reached");
		
		uint usdtCost = checkEthWeiPromoCost(ethWei);
		require(usdtCost > 0, "EthPromo/usdtCost-is-zero");
		
		// register USDT withdrawals for each user
		usdtBalances[msg.sender] = usdtBalances[msg.sender].sub(usdtCost);
		
		// USDT profit goes to owner that can withdraw anytime after eth sales excluding users balances
		usdtBalances[owner] = usdtBalances[owner].add(usdtCost);
		
		// register eth promo left for current user
		ethBalances[msg.sender] = ethBalances[msg.sender].sub(ethWei);
		
		// transfer to the user the ether he bought at promotion
        (msg.sender).transfer(ethWei);
		
		emit PromoEthBought(msg.sender, ethWei, usdtCost);
		
		return true;
	}
	
	
	
	///---
	/// NOTE: Having special end sale function to handle USDT stable coin profit as well is not needed,
	/// because owner can always withdraw that profit using 'withdrawUSDT' function.
	///---
	
	/**
	 * This contract has special end sale function to handle USDT stable coin profit as well.
	 */
	/*function endSale() public onlyOwner {
		// transfer remaining FITH tokens from this contract back to owner
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Transfer token-sale token balance to owner failed");
		
		// transfer remaining USDT profit from this contract to owner
		require(IERC20(usdtContractAddress).transfer(owner, usdtBalances[owner]), "EthPromo/USDT.profit.transfer failed");
		
        // Just transfer the ether balance to the owner
        owner.transfer(address(this).balance);
    }*/
	
	
	
	/**
	 * Accept ETH for tokens
	 */
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		
		address refererAddress = address(0);
		bytes memory msgData = msg.data;
		// 4 bytes for signature
		if (msgData.length > 4) {
			assembly {
				refererAddress := mload(add(msgData, 20))
			}
		}
		
		_buyTokens(tks, refererAddress);
		
		// store eth of each token sale user
		ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
    }
}"},"FITHTokenSaleReferrals.sol":{"content":"pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMathLib.sol";
import "./FITHTokenSale.sol";

/**
 * @dev Fiatech FITH token sale contract.
 */
contract FITHTokenSaleReferrals is FITHTokenSale
{
	using SafeMathLib for uint;
	
	uint public referralPercent = 5; // x is x%
	uint public referralTokensSpent = 0; // total referral tokens given away
	
	// referral tokens bought event raised when buyer purchases tokens via referral link
    event ReferralTokens(address indexed _buyer, address indexed _referer, uint256 _refererTokens);
	
	// referral token percent update event
	event ReferralTokenPercentUpdate(address _admin, uint256 _referralPercent);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor(IERC20 _tokenContract, uint256 _tokenPrice)
		FITHTokenSale(_tokenContract, _tokenPrice)
		public
	{
    }
	
	modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
	
	
	
	//referer is address instead of string
	function _buyTokens(uint256 _numberOfTokens, address refererAddress) internal returns(bool) {
		
		require(super._buyTokens(_numberOfTokens), "_buyTokens base failed!");
		
		// only send referral tokens if buyer has a valid referer
		if (refererAddress > address(0)) {
			
			address referer = refererAddress;
			
			// self-referrer check
			require(referer != msg.sender, "Referer is sender");
			uint refererTokens = _numberOfTokens.mul(referralPercent).div(100);
			
			// bonus for referrer
			require(tokensAvailable() >= refererTokens, "insufficient referral tokens");
			require(tokenContract.transfer(referer, refererTokens), "Transfer tokens to referer failed");
			
			referralTokensSpent += refererTokens;
			
			emit ReferralTokens(msg.sender, referer, refererTokens);
		}
		return true;
    }
	
	function updateReferralPercent(uint256 _referralPercent) public onlyOwner {
        require(_referralPercent > 0 && _referralPercent <= 100 && _referralPercent != referralPercent, "Referral percent must be in (0,100] range and different than current");
        
		referralPercent = _referralPercent;
		emit ReferralTokenPercentUpdate(owner, _referralPercent);
    }
	
	/*function buyTokens(uint256 _numberOfTokens, address refererAddress) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice), "Incorrect number of tokens");
		_buyTokens(_numberOfTokens, refererAddress);
    }*/
	
	
	
	/**
	 * Accept ETH for tokens
	 */
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		
		// (c, d) = abi.decode(msg.data[4:], (uint256, uint256));
		//address refererAddress = abi.decode(msg.data[4:], (address));
		
		address refererAddress = address(0);
		bytes memory msgData = msg.data;
		// 4 bytes for signature
		if (msgData.length > 4) {
			assembly {
				refererAddress := mload(add(msgData, 20))
			}
		}
		
		_buyTokens(tks, refererAddress);
    }
}"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @dev ERC20 contract interface.
 */
contract IERC20
{
	function totalSupply() public view returns (uint);
	
	function transfer(address _to, uint _value) public returns (bool success);
	
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	
	function balanceOf(address _owner) public view returns (uint balance);
	
	function approve(address _spender, uint _value) public returns (bool success);
	
	function allowance(address _owner, address _spender) public view returns (uint remaining);
	
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed owner, address indexed spender, uint tokens);
}"},"OrFeedInterface.sol":{"content":"pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface OrFeedInterface {
  function getExchangeRate ( string calldata fromSymbol, string calldata  toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata  symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata  symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
  //function arb(address  fundsReturnToAddress,  address liquidityProviderContractAddress, string[] calldata   tokens,  uint256 amount, string[] calldata  exchanges) external payable returns (bool);
}"},"SafeMathLib.sol":{"content":"pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

library SafeMathLib {
	
	using SafeMathLib for uint;
	
	/**
	 * @dev Sum two uint numbers.
	 * @param a Number 1
	 * @param b Number 2
	 * @return uint
	 */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMathLib.add: required c >= a");
    }
	
	/**
	 * @dev Substraction of uint numbers.
	 * @param a Number 1
	 * @param b Number 2
	 * @return uint
	 */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMathLib.sub: required b <= a");
        c = a - b;
    }
	
	/**
	 * @dev Product of two uint numbers.
	 * @param a Number 1
	 * @param b Number 2
	 * @return uint
	 */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require((a == 0 || c / a == b), "SafeMathLib.mul: required (a == 0 || c / a == b)");
    }
	
	/**
	 * @dev Division of two uint numbers.
	 * @param a Number 1
	 * @param b Number 2
	 * @return uint
	 */
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "SafeMathLib.div: required b > 0");
        c = a / b;
    }
}"}}