{"BytesLib.sol":{"content":"// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author GonÃ§alo SÃ¡ <goncalo.sa@consensys.net>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.4;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

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
}"},"IUniswapV3Router.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}"},"IWETH.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}"},"matrEXRouterV3.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV3Router.sol";
import "./IWETH.sol";
import {Path} from "./Path.sol";

contract matrEXRouterV3 is Ownable, IUniswapV3Router{
    using Path for bytes;

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
    * _uniswapV3Router: Uniswap router that all swaps go through
    * _WETH: The address of the WETH token
    */
    uint256 private _charityFee;
    address private _charityAddress;
    IUniswapV3Router private _uniswapV3Router;
    address private _WETH;

    /**
    * @dev Sets the Uniswap router, the charity fee, the charity address and
    * the WETH token address 
    */
    constructor(){
        _uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _charityFee = 20;
        _charityAddress = address(0x830be1dba01bfF12C706b967AcDeCd2fDEa48990);
        _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /**
    * @dev Calculates the fee and takes it, transfers the fee to the charity
    * address and the remains to this contract.
    * emits feeTaken()
    * Then, it checks if there is enough approved for the swap, if not it
    * approves it to the uniswap contract. Emits approvedForTrade() if so.
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
        if (token.allowance(address(this), address(_uniswapV3Router)) < totalAmount){
            token.approve(address(_uniswapV3Router), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
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
    function takeFeeETH(uint256 totalAmount) internal returns (uint256 fee){
        uint256 _feeTaken = (totalAmount * _charityFee) / 10000;
        emit feeTakenInETH(_msgSender(), _feeTaken);
        return totalAmount - _feeTaken;
    }
    
    /**
    * @dev The functions below are all the same as the Uniswap contract but
    * they call takeFeeAndApprove() or takeFeeETH() (See the functions above)
    * and deduct the fee from the amount that will be traded.
    */

    function exactInputSingle(ExactInputSingleParams calldata params) external virtual override payable returns (uint256){
        if (params.tokenIn == _WETH && msg.value >= params.amountIn){
            uint256 newValue = takeFeeETH(params.amountIn);
            ExactInputSingleParams memory params_ = params;
            params_.amountIn = newValue;
            return _uniswapV3Router.exactInputSingle{value: params_.amountIn}(params_);
        }else{
            IERC20 token = IERC20(params.tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), token, params.amountIn);
            ExactInputSingleParams memory _params = params;
            _params.amountIn = newAmount;
            return _uniswapV3Router.exactInputSingle(_params);
        }
    }
    
    function exactInput(ExactInputParams calldata params) external virtual override payable returns (uint256){
        (address tokenIn, address tokenOut, uint24 fee) = params.path.decodeFirstPool();
        if (tokenIn == _WETH && msg.value >= params.amountIn){
            uint256 newValue = takeFeeETH(params.amountIn);
            ExactInputParams memory params_ = params;
            params_.amountIn = newValue;
            return _uniswapV3Router.exactInput{value: params_.amountIn}(params_);
        }else{
            IERC20 token = IERC20(tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(token), params.amountIn);
            ExactInputParams memory _params = params;
            _params.amountIn = newAmount;
            return _uniswapV3Router.exactInput(_params);
        }
    }
    
     function exactOutputSingle(ExactOutputSingleParams calldata params) external virtual payable override returns (uint256){
        if (params.tokenIn == address(_WETH) && msg.value >= params.amountOut){
            uint256 newValue = takeFeeETH(params.amountOut);
            ExactOutputSingleParams memory params_ = params;
            params_.amountOut = newValue;
            return _uniswapV3Router.exactOutputSingle{value: params_.amountOut}(params_);
        }else{
            IERC20 token = IERC20(params.tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), token, params.amountOut);
            ExactOutputSingleParams memory _params = params;
            _params.amountOut = newAmount;
            return _uniswapV3Router.exactOutputSingle(_params);
        }
    }
    
    function exactOutput(ExactOutputParams calldata params) external virtual override payable returns (uint256){
        (address tokenIn, address tokenOut, uint24 fee) = params.path.decodeFirstPool();
         if (tokenIn == address(_WETH) && msg.value >= params.amountOut){
            uint256 newValue = takeFeeETH(params.amountOut);
            ExactOutputParams memory params_ = params;
            params_.amountOut == newValue;
            return _uniswapV3Router.exactOutput{value: params_.amountOut}(params_);
        }else{
            IERC20 token = IERC20(tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(token), params.amountOut);
            ExactOutputParams memory _params = params;
            _params.amountOut == newAmount;
            return _uniswapV3Router.exactOutput(_params);
        }
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
    
    function setUniswapV3Router(IUniswapV3Router newUniswapV3Router) external onlyOwner {
        _uniswapV3Router = newUniswapV3Router;
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
    function uniswapV3Router() external view returns (IUniswapV3Router) {
        return _uniswapV3Router;
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
}"},"Path.sol":{"content":"// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}"}}