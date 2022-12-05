{"Context.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}"},"IUniswapV2Router.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}"},"IWETH.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}"},"matrEXRouterV2.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Ownable.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract matrEXRouterV2 is Ownable, IUniswapV2Router{
    /**
    * @dev Event emitted when the charity fee is taken
    * @param from: The user it is taken from
    * @param token: The token that was taken from the user
    * @param amount: The amount of the token taken for charity
    */
    event feeTaken(address from, IERC20 token, uint256 amount);

    /**
    * @dev Event emitted when the charity fee is taken (in ETH)
    * @param from: The user it was taken from
    * @param amount: The amount of ETH taken in wei
    */
    event feeTakenInETH(address from, uint256 amount);

    /**
    * @dev Event emmited when a token is approved for trade for the first
    * time on Uniswap (check takeFeeAndApprove())
    * @param token: The tokens that was approved for trade
    */
    event approvedForTrade(IERC20 token);

    /**
    * @dev 
    * _charityFee: The % that is taken from each swap that gets sent to charity
    * _charityAddress: The address that the charity funds get sent to
    * _uniswapV2Router: Uniswap router that all swaps go through
    */
    uint256 private _charityFee;
    address private _charityAddress;
    address private _WETH;
    IUniswapV2Router private _uniswapV2Router;

    /**
    * @dev Sets the Uniswap Router, Charity Fee and Charity Address 
    */
    constructor(){
        _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _charityFee = 20;
        _charityAddress = address(0x830be1dba01bfF12C706b967AcDeCd2fDEa48990);
        _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /**
    * @dev Calculates the fee and takes it, transfers the fee to the charity
    * address and the remains to this contract.
    * emits feeTaken()
    * Then, it checks if there is enough approved for the swap, if not it
    * approves it to the uniswap contract. Emits approvedForTrade if so.
    * @param user: The payer
    * @param token: The token that will be swapped and the fee will be paid
    * in
    * @param totalAmount: The total amount of tokens that will be swapped, will
    * be used to calculate how much the fee will be
    */
    function takeFeeAndApprove(address user, IERC20 token, uint256 totalAmount) internal returns (uint256){
        uint256 _feeTaken = (totalAmount * _charityFee) / 10000;
        token.transferFrom(user, address(this), totalAmount - _feeTaken);
        token.transferFrom(user, _charityAddress, _feeTaken);
        if (token.allowance(address(this), address(_uniswapV2Router)) < totalAmount){
            token.approve(address(_uniswapV2Router), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            emit approvedForTrade(token);
        }
        emit feeTaken(user, token, _feeTaken);
        return totalAmount -= _feeTaken;
    }
    
    /**
    * @dev Calculates the fee and takes it, holds the fee in the contract and 
    * can be sent to charity when someone calls withdraw()
    * This makes sure:
    * 1. That the user doesn't spend extra gas for an ERC20 transfer + 
    * wrap
    * 2. That funds can be safely transfered to a contract
    * emits feeTakenInETH()
    * @param totalAmount: The total amount of tokens that will be swapped, will
    * be used to calculate how much the fee will be
    */
    function takeFeeETH(uint256 totalAmount) internal returns (uint256){
        uint256 fee = (totalAmount * _charityFee) / 10000;
        emit feeTakenInETH(_msgSender(), fee);
        return totalAmount - fee;
    }
    
    /**
    * @dev The functions below are all the same as the Uniswap contract but
    * they call takeFeeAndApprove() or takeFeeETH() (See the functions above)
    * and deduct the fee from the amount that will be traded.
    */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts){
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForTokens(newAmount, amountOutMin, path, to,deadline);
    }
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts){
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountOut);
        return _uniswapV2Router.swapTokensForExactTokens(newAmount, amountInMax, path, to,deadline);
        
    }
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        override
        returns (uint[] memory amounts){
            uint256 newValue = takeFeeETH(msg.value);
            return _uniswapV2Router.swapExactETHForTokens{value: newValue}(amountOutMin, path, to, deadline);
        }
        
        
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external override
        returns (uint[] memory amounts){
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountOut);
            return _uniswapV2Router.swapTokensForExactETH(newAmount, amountInMax, path, to, deadline);
        }
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external override
        returns (uint[] memory amounts) {
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
            return _uniswapV2Router.swapExactTokensForETH(newAmount, amountOutMin, path, to, deadline);
        }
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable override
        returns (uint[] memory amounts){
            uint256 newValue = takeFeeETH(msg.value);
            return _uniswapV2Router.swapETHForExactTokens{value: newValue}(amountOut, path, to, deadline);
        }
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override {
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(newAmount, amountOutMin, path, to, deadline);
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override payable{
        uint256 newValue = takeFeeETH(msg.value);
        return _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: newValue}(amountOutMin, path, to, deadline);
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override {
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(newAmount, amountOutMin, path, to, deadline);
    }

    /**
    * @dev Same as Uniswap
    */
    function quote(uint amountA, uint reserveA, uint reserveB) external override pure returns (uint amountB){
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure override returns (uint amountOut){
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external override pure returns (uint amountIn){
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external override view returns (uint[] memory amounts){
        return _uniswapV2Router.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external override view returns (uint[] memory amounts){
        return _uniswapV2Router.getAmountsIn(amountOut, path);
    }
    
    /**
    * @dev Wraps all tokens in the contract and sends them to the charity 
    * address 
    * To know why, see takeFeeETH() 
    */
    function withdraw() external {
        uint256 contractBalance = address(this).balance;
        IWETH(_WETH).deposit{value: contractBalance}();
        IWETH(_WETH).transfer(_charityAddress, contractBalance);
    }

    /**
    * @dev Functions that only the owner can call that change the variables
    * in this contract
    */
    function setCharityFee(uint256 newCharityFee) external onlyOwner {
        _charityFee = newCharityFee;
    }
    
    function setCharityAddress(address newCharityAddress) external onlyOwner {
        _charityAddress = newCharityAddress;
    }
    
    function setUniswapV2Router(IUniswapV2Router newUniswapV2Router) external onlyOwner {
        _uniswapV2Router = newUniswapV2Router;
    }

    function setWETH(address newWETH) external onlyOwner {
        _WETH = newWETH;
    }
    
    /**
    * @return Returns the % fee taken from each swap that goes to charity
    */
    function charityFee() external view returns (uint256) {
        return _charityFee;
    }
    
    /**
    * @return The address that the "Charity Fee" is sent to
    */
    function charityAddress() external view returns (address) {
        return _charityAddress;
    }
    
    /**
    * @return The router that all swaps will be directed through
    */
    function uniswapV2Router() external view returns (IUniswapV2Router) {
        return _uniswapV2Router;
    }

    /**
    * @return The current WETH contract that's being used
    */
    function WETH() external view returns (address) {
        return _WETH;
    }
}"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}"}}