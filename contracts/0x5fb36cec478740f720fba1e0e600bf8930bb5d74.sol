{"Context.sol":{"content":"pragma solidity ^0.7.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
}
"},"Migrations.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}
"},"Ownable.sol":{"content":"pragma solidity ^0.7.3;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"},"uniswapBought.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./UniswapInterface.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract UniswapBought is Ownable {
    // list of authorized address
    mapping(address => bool) authorized;

    // using this to add address who can call the contract
    function addAuthorized(address _a) public onlyOwner {
        authorized[_a] = true;
    }

    // using this to add address who can call the contract
    function deleteAuthorized(address _a) public onlyOwner {
        authorized[_a] = false;
    }

    function isAuthorized(address _a) public view onlyOwner returns (bool) {
        if (owner() == _a) {
            return true;
        } else {
            return authorized[_a];
        }
    }

    modifier onlyAuth() {
        require(isAuthorized(msg.sender));
        _;
    }

    // =========================================================================================
    // Settings uniswap
    // =========================================================================================

    address public constant UNIROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETHAddress = UniswapExchangeInterface(UNIROUTER).WETH();
    UniswapExchangeInterface uniswap = UniswapExchangeInterface(UNIROUTER);

    // =========================================================================================
    // Buy and Sell Functions
    // =========================================================================================

    // using this to buy token , first arg is eth value (1 eth = 1*1E18), arg2 is token address
    function buyToken(
        uint256 _value,
        address _token,
        uint256 _mintoken,
        uint256 _blockDeadLine
    ) public onlyAuth returns (uint256) {
        uint256 deadline = block.timestamp + _blockDeadLine; // deadline during 15 blocks
        address[] memory path = new address[](2);
        path[0] = WETHAddress;
        path[1] = _token;
        uint256[] memory amount =
            uniswap.swapExactETHForTokens{value: _value}(
                _mintoken,
                path,
                address(this),
                deadline
            );
        return amount[1];
    }

    // using this to allow uniswap to sell tokens of contract
    function allowUniswapForToken(address _token) public onlyOwner {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(UNIROUTER, _balance);
    }

    // using this to sell token , first arg is eth value (1 eth = 1*1E18), arg2 is token address
    function sellToken(
        uint256 _amountToSell,
        uint256 _amountOutMin,
        address _token,
        uint256 _blockDeadLine
    ) public onlyAuth returns (uint256) {
        uint256 deadline = block.timestamp + _blockDeadLine; // deadline during 15 blocks
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETHAddress;
        uint256[] memory amount =
            uniswap.swapExactTokensForETH(
                _amountToSell,
                _amountOutMin,
                path,
                address(this),
                deadline
            );
        return amount[1];
    }

    // =========================================================================================
    // Desposit and withdraw functions
    // =========================================================================================

    // using this to send Eth to contract
    fallback() external payable {}

    receive() external payable {}

    // Using this to withdraw eth balance of contract => send to msg.sender
    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // using this to withdraw all tokens in the contract => send to msg.sender
    function withdrawToken(address _token) public onlyOwner() {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }
}
"},"UniswapInterface.sol":{"content":"pragma solidity ^0.7.3;

// Interface Uniswap

interface UniswapExchangeInterface {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}
"}}