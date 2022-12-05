{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
"},"Launchpad.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Launchpad{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
   
    uint256 private constant _BASE_PRICE = 100000000000;

    uint256 private constant _totalPercent = 10000;
    
    uint256 private constant _fee1 = 100;

    uint256 private constant _fee3 = 300;

    address private constant _layerFeeAddress = 0xa6A7cFCFEFe8F1531Fc4176703A81F570d50D6B5;
    
    address private constant _stakeFeeAddress = 0xfB5B0474B28f18A635579c1bF073fc05bE1BB63b;
    
    address private constant _supportFeeAddress = 0xD3cDe6FA51A69EEdFB1B8f58A1D7DCee00EC57A8;

    mapping (address => uint256) private _balancesToClaim;

    mapping (address => uint256) private _balancesToClaimTokens;

    uint256 private _liquidityPercent;

    uint256 private _teamPercent;

    uint256 private _end;

    uint256 private _start;

    uint256 private _releaseTime;
    
    uint256[3] private _priceInv;
     
    uint256[3] private _caps;

    uint256 private _priceUniInv;

    bool    private _isRefunded = false;

    bool    private _isSoldOut = false;

    bool    private _isLiquiditySetup = false;

    uint256 private _raisedETH;

    uint256 private _claimedAmount;

    uint256 private _softCap;

    uint256 private _maxCap;

    address private _teamWallet;

    address private _owner;
    
    address private _liquidityCreator;

    IERC20 public _token;
    
    string private _tokenName;
    
    string private _tokenSymbol;

    string private _siteUrl;
    
    string private _paperUrl;

    string private _twitterUrl;

    string private _telegramUrl;

    string private _mediumUrl;
    
    string private _gitUrl;
    
    string private _discordUrl;
    
    string private _tokenDesc;
    
    uint256 private _tokenTotalSupply;
    
    uint256 private _tokensForSale;
    
    uint256 private _minContribution = 1 ether;
    
    uint256 private _maxContribution = 50 ether;
    
    uint256 private _round;
    
    bool private _uniListing;
    
    bool private _tokenMint;
    
    /**
    * @dev Emitted when maximum value of ETH is raised
    *
    */    
    event SoldOut();
    
    /**
    * @dev Emitted when ETH are Received by this wallet
    *
    */
    event Received(address indexed from, uint256 value);
    
    /**
    * @dev Emitted when tokens are claimed by user
    *
    */
    event Claimed(address indexed from, uint256 value);
    /**
    * @dev Emitted when refunded if not successful
    *
    */
    event Refunded(address indexed from, uint256 value);
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }    

    constructor(
        IERC20 token, 
        uint256 priceUniInv, 
        uint256 softCap, 
        uint256 maxCap, 
        uint256 liquidityPercent, 
        uint256 teamPercent, 
        uint256 end, 
        uint256 start, 
        uint256 releaseTime,
        uint256[3] memory caps, 
        uint256[3] memory priceInv,
        address owner, 
        address teamWallet,
        address liquidityCreator
    ) 
    public 
    {
        require(start > block.timestamp, "start time needs to be above current time");
        require(releaseTime > block.timestamp, "release time above current time");
        require(end > start, "End time above start time");
        require(liquidityPercent <= 3000, "Max Liquidity allowed is 30 %");
        require(owner != address(0), "Not valid address" );
        require(caps.length > 0, "Caps can not be zero" );
        require(caps.length == priceInv.length, "Caps and price not same length" );
    
        uint256 totalPercent = teamPercent.add(liquidityPercent).add(_fee1.mul(2)).add(_fee3);
        require(totalPercent == _totalPercent, "Funds are distributed max 100 %");

        _softCap = softCap;
        _maxCap = maxCap;
        _start = start;
        _end = end;
        _liquidityPercent = liquidityPercent;
        _teamPercent = teamPercent;
        _caps = caps;
        _priceInv = priceInv;
        _owner = owner;
        _liquidityCreator = liquidityCreator;
        _releaseTime = releaseTime;
        _token = token;
        _teamWallet = teamWallet;
        _priceUniInv = priceUniInv;
    }
    
    /**
    * @dev Function to set the end time
    * @param end - end time
    */    
    function setEndTime(uint256 end) external onlyOwner {
        require(end > _start, "End time above start time");
        _end = end;
    }
    
    /**
    * @dev Function to set the release time
    * @param releaseTime - release time
    */       
    function setReleaseTime(uint256 releaseTime) external onlyOwner {
        require(releaseTime > block.timestamp, "release time above current time");
        _releaseTime = releaseTime;
    }    
    
    /**
    * @dev Function to set projetct details
    * @param tokenName - token name
    * @param tokenSymbol - token symbol
    * @param siteUrl - site url
    * @param paperUrl - paper url
    * @param twitterUrl - twitter url
    * @param telegramUrl - telegram url
    * @param mediumUrl - medium url
    * @param gitUrl - git url
    * @param discordUrl - discord url
    * @param tokenDesc - token desc
    * @param tokensForSale - amount tokens for sale
    * @param tokenTotalSupply - total token supply
    * @param uniListing - is uniswap listing
    * @param tokenMint - is token mint
    */    
    function setDetails(
        string memory tokenName,
        string memory tokenSymbol,
        string memory siteUrl,
        string memory paperUrl,
        string memory twitterUrl,
        string memory telegramUrl,
        string memory mediumUrl,
        string memory gitUrl,
        string memory discordUrl,
        string memory tokenDesc,
        uint256 tokensForSale,
        uint256 tokenTotalSupply,
        bool uniListing,
        bool tokenMint
    ) external onlyOwner {
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;
        _siteUrl = siteUrl;
        _paperUrl = paperUrl;
        _twitterUrl = twitterUrl;
        _telegramUrl = telegramUrl;
        _mediumUrl = mediumUrl;
        _gitUrl = gitUrl;
        _discordUrl = discordUrl;
        _tokenDesc = tokenDesc;
        _tokensForSale = tokensForSale;
        _uniListing = uniListing;
        _tokenMint = tokenMint;
        _tokenTotalSupply = tokenTotalSupply;
    }
    
    /**
    * @dev Function to get details of project part-1.
    */
    function getDetails() public view returns 
    (
        uint256 priceUniInv,
        address owner,
        address teamWallet, 
        uint256 softCap, 
        uint256 maxCap, 
        uint256 liquidityPercent, 
        uint256 teamPercent, 
        uint256 end, 
        uint256 start, 
        uint256 releaseTime,
        uint256 raisedETH,
        uint256 tokensForSale,
        uint256 minContribution,
        uint256 maxContribution
    ) {
        priceUniInv = _priceUniInv;
        owner = _owner;
        teamWallet = _teamWallet; 
        softCap = _softCap; 
        maxCap = _maxCap; 
        liquidityPercent = _liquidityPercent; 
        teamPercent = _teamPercent;
        end = _end;
        start = _start; 
        releaseTime = _releaseTime;
        raisedETH = _raisedETH;
        tokensForSale = _tokensForSale;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
    }

    /**
    * @dev Function to get details of project part-2.
    */
    function getMoreDetails() public view returns 
    (
        bool uniListing,
        bool tokenMint,
        bool isRefunded,
        bool isSoldOut,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenTotalSupply,
        uint256 liquidityLock,
        uint256 round
    ) {
        uniListing = _uniListing;
        tokenMint = _tokenMint;
        isRefunded = _isRefunded;
        isSoldOut = _isSoldOut;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenTotalSupply = _tokenTotalSupply;
        liquidityLock = _maxCap.mul(_liquidityPercent).div(_totalPercent);
        round = _round;
    }

    /**
    * @dev Function to get details of project
    * @return details of project part-3.
    */
    function getInfos() public view returns (string memory, string memory) {
        string memory res = '';
        res = append(_siteUrl, '|', _paperUrl, '|', _twitterUrl);
        res = append(res, '|', _telegramUrl, '|', _mediumUrl );
        res = append(res, '|', _gitUrl, '|', _discordUrl );
        return(res, _tokenDesc);
    }

    /**
    * @dev Function to get details of project for listing
    */
    function getMinInfos() public view returns (
        string memory siteUrl,
        string memory tokenName,
        bool isRefunded,
        bool isSoldOut,
        uint256 start, 
        uint256 end,
        uint256 softCap,
        uint256 maxCap,
        uint256 raisedETH
    ) {
        siteUrl = _siteUrl;
        tokenName = _tokenName;
        isRefunded = _isRefunded;
        isSoldOut = _isSoldOut;
        start = _start;
        end = _end;
        softCap = _softCap;
        maxCap = _maxCap;
        raisedETH = _raisedETH;
    }
    
    /**
    * @dev Function to get the length of caps array
    * @return length
    */        
    function getCapSize() public view returns(uint) {
        return _caps.length;
    }

    /**
    * @dev Function to get the cap value, price inverse and amount.
    * @param index - cap index.
    * @return cap value, price inverse and amount.
    */ 
    function getCapPrice(uint index) public view returns(uint, uint, uint) {
        return (_caps[index], _priceInv[index], ( _caps[index].mul(_BASE_PRICE).div(_priceInv[index])));
    }

    /**
    * @dev Function to get the balance to claim of user in ETH.
    * @param account - user address.
    * @return balance to claim.
    */
    function getBalanceToClaim(address account) public view returns (uint256) {
        return _balancesToClaim[account];
    }

    /**
    * @dev Function to get the balance to claim of user in TOKEN.
    * @param account - user address.
    * @return balance to claim.
    */
    function getBalanceToClaimTokens(address account) public view returns (uint256) {
        return _balancesToClaimTokens[account];
    }
    
    /**
    * @dev Receive ETH and updates the launchpad values.
    */
    receive() external payable {
        require(block.timestamp > _start , "LaunchpadToken: not started yet");
        require(block.timestamp < _end , "LaunchpadToken: finished");
        require(_isRefunded == false , "LaunchpadToken: Refunded is activated");
        require(_isSoldOut == false , "LaunchpadToken: SoldOut");
        uint256 amount = msg.value;
        require(amount >= _minContribution && amount <= _maxContribution, 'Amount must be between MIN and MAX');
        uint256 price = _priceInv[2];
        require(amount > 0, "LaunchpadToken: eth value sent needs to be above zero");
      
        _raisedETH = _raisedETH.add(amount);
        uint total = 0;
        for (uint256 index = 0; index < _caps.length; index++) {
            total = total + _caps[index];
            if(_raisedETH < total){
                price = _priceInv[index];
                _round = index;
                break;
            }
        }
        
        _balancesToClaim[msg.sender] = _balancesToClaim[msg.sender].add(amount);
        _balancesToClaimTokens[msg.sender] = _balancesToClaimTokens[msg.sender].add(amount.mul(_BASE_PRICE).div(price));

        if(_raisedETH >= _maxCap){
            _isSoldOut = true;
            uint256 refundAmount = _raisedETH.sub(_maxCap);
            if(refundAmount > 0){
                // Subtract value that is higher than maxCap
                 _raisedETH = _raisedETH.sub(refundAmount);
                _balancesToClaim[msg.sender] = _balancesToClaim[msg.sender].sub(refundAmount);
                _balancesToClaimTokens[msg.sender] = _balancesToClaimTokens[msg.sender].sub(refundAmount.mul(_BASE_PRICE).div(price));
                payable(msg.sender).transfer(refundAmount);
            }
            emit SoldOut();
        }

        emit Received(msg.sender, amount);
    }

    /**
    * @dev Function to claim tokens to user, after release time, if project not reached softcap funds are returned back.
    */
    function claim() public returns (bool)  {
        // if sold out no need to wait for the time to finish, make sure liquidity is setup
        require(block.timestamp >= _end || (!_isSoldOut && _isLiquiditySetup), "LaunchpadToken: sales still going on");
        require(_balancesToClaim[msg.sender] > 0, "LaunchpadToken: No ETH to claim");
        require(_balancesToClaimTokens[msg.sender] > 0, "LaunchpadToken: No ETH to claim");
       // require(_isRefunded != false , "LaunchpadToken: Refunded is activated");
        uint256 amount =  _balancesToClaim[msg.sender];
        _balancesToClaim[msg.sender] = 0;
         uint256 amountTokens =  _balancesToClaimTokens[msg.sender];
        _balancesToClaimTokens[msg.sender] = 0;
        if(_isRefunded){
            // return back funds
            payable(msg.sender).transfer(amount);
            emit Refunded(msg.sender, amount);
        }
        else {
            // Transfer Tokens to User
            _token.safeTransfer(msg.sender, amountTokens);
            _claimedAmount = _claimedAmount.add(amountTokens);
            emit Claimed(msg.sender, amountTokens);            
        }
        return true;
    }

    /**
    * @dev Function to setup liquidity and transfer all amounts according to defined percents, if softcap not reached set Refunded flag.
    */
    function setupLiquidity() public onlyOwner {
        require(_isSoldOut == true || block.timestamp > _end , "LaunchpadToken: not sold out or time not elapsed yet" );
        require(_isRefunded == false, "Launchpad: refunded is activated");
        require(_isLiquiditySetup == false, "Setup has already been completed");
        _isLiquiditySetup = true;
        if(_raisedETH < _softCap){
            _isRefunded = true;
            return;
        }
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "LaunchpadToken: eth balance needs to be above zero" );
        uint256 liquidityAmount = ethBalance.mul(_liquidityPercent).div(_totalPercent);
        uint256 tokensAmount = _token.balanceOf(address(this));
        require(tokensAmount >= liquidityAmount.mul(_BASE_PRICE).div(_priceUniInv), "Launchpad: Not sufficient tokens amount");
        uint256 teamAmount = ethBalance.mul(_teamPercent).div(_totalPercent);
        uint256 layerFeeAmount = ethBalance.mul(_fee3).div(_totalPercent);
        uint256 supportFeeAmount = ethBalance.mul(_fee1).div(_totalPercent);
        uint256 stakeFeeAmount = ethBalance.mul(_fee1).div(_totalPercent);
        payable(_layerFeeAddress).transfer(layerFeeAmount);
        payable(_supportFeeAddress).transfer(supportFeeAmount);
        payable(_stakeFeeAddress).transfer(stakeFeeAmount);
        payable(_teamWallet).transfer(teamAmount);
        payable(_liquidityCreator).transfer(liquidityAmount);
        _token.safeTransfer(address(_liquidityCreator), liquidityAmount.mul(_BASE_PRICE).div(_priceUniInv));
    }

    /**
     * @notice Transfers non used tokens held by Lock to owner.
       @dev Able to withdraw funds after end time and liquidity setup, if refunded is enabled just let token owner 
       be able to withraw.
     */
    function release(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        if(_isRefunded){
             token.safeTransfer(_owner, amount);
        }
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _end || _isSoldOut == true, "Launchpad: current time is before release time");
        require(_isLiquiditySetup == true, "Launchpad: Liquidity is not setup");
        // TO Define: Tokens not claimed should go back to time after release time?
        require(_claimedAmount == _raisedETH || block.timestamp >= _releaseTime, "Launchpad: Tokens still to be claimed");
        require(amount > 0, "Launchpad: no tokens to release");

        token.safeTransfer(_owner, amount);
    }
    
    /**
    * @dev Function to append strings.
    * @param a - string a.
    * @param b - string b.
    * @param c - string c.
    * @param d - string d.
    * @param e - string e.
    * @return new string.
    */    
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d, e));
    }    
}"},"SafeERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"}}