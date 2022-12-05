{"ConsensusUSD.sol":{"content":"pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IConsensusUSD.sol";


contract ConsensusUSD is ERC20, IConsensusUSD {

fallback() external payable {
revert();
}

receive() external payable {
revert();
}

string public name;
uint8 public decimals;
string public symbol;
string public version = 'H1.0';

mapping (address => uint256) validStablecoins;
mapping (address => mapping (address => uint256)) lockedAssets;

using SafeMath for uint256;


constructor() public {
decimals = 18;
totalSupply = 0;
name = "Consensus USD";
symbol = "XUSD";

validStablecoins[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 1; // DAI  (MC DAI       )
validStablecoins[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 1; // USDT (ERC20 Tether )
validStablecoins[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = 1; // BUSD (Binance USD  )
validStablecoins[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 1; // USDC (USD Coin     )
validStablecoins[0x0000000000085d4780B73119b644AE5ecd22b376] = 1; // tUSD (TrueUSD      )

}


function isValidAsset(address _asset) external view override returns (bool isValid) {
return validStablecoins[_asset] == 1;
}

function assetLockedOf(address _owner, address _asset) external view override returns (uint256 asset) {
return lockedAssets[_owner][_asset];
}


function mint(uint256 _amount, address _assetUsed) public override returns (bool success) {

assert(validStablecoins[_assetUsed] == 1 );
require(IERC20(_assetUsed).transferFrom(msg.sender, address(this), _amount));

lockedAssets[msg.sender][_assetUsed] = lockedAssets[msg.sender][_assetUsed].add(_amount);

totalSupply          = totalSupply          .add(_amount);
balances[msg.sender] = balances[msg.sender] .add(_amount);

emit Mint(msg.sender, _amount);

return true;
}

function retrieve(uint256 _amount, address _assetRetrieved) public override returns (bool success) {

assert(validStablecoins[_assetRetrieved] == 1 );

assert( balances[msg.sender]                               .sub(_amount) >= 0 );
assert( lockedAssets[msg.sender][_assetRetrieved] .sub(_amount) >= 0 );

balances[msg.sender] = balances[msg.sender] .sub(_amount);
totalSupply          = totalSupply          .sub(_amount);

require(IERC20(_assetRetrieved).transfer(msg.sender, _amount));
lockedAssets[msg.sender][_assetRetrieved] = lockedAssets[msg.sender][_assetRetrieved].sub(_amount);

emit Burn(msg.sender, _amount);

return true;
}

}
"},"ERC20.sol":{"content":"pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";


contract ERC20 is IERC20 {

uint256 public override totalSupply;
mapping (address => uint256) balances;
mapping (address => mapping (address => uint256)) allowed;
using SafeMath for uint256;


function transfer(address _to, uint256 _value) public override returns (bool success) {
if (balances[msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {

balances[msg.sender] = balances[msg.sender] .sub(_value);
balances[_to]        = balances[_to]        .add(_value);

emit Transfer(msg.sender, _to, _value);

return true;
} else { return false; }
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {

balances[_to]              = balances[_to]              .add(_value);
balances[_from]            = balances[_from]            .sub(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender] .sub(_value);

emit Transfer(_from, _to, _value);

return true;
} else { return false; }
}


function balanceOf(address _owner) external view override returns (uint256 balance) {
return balances[_owner];
}

function approve(address _spender, uint256 _value) public override returns (bool success) {

allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);

return true;
}

function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
return allowed[_owner][_spender];
}

}
"},"IConsensusUSD.sol":{"content":"pragma solidity ^0.6.0;



interface IConsensusUSD {

    /// @param _amount The amount of consensus dollar tokens to mint
    /// @param _assetUsed The token address of asset used to mint consensus dollar tokens
    /// @return success indicating if minting was successful
    function mint(uint256 _amount, address _assetUsed) external returns (bool success);

    /// @param _amount The amount of asset to retrieve from contract, equals the amount of tokens burnt
    /// @param _assetRetrieved The token address of asset which is going to be retrieved
    /// @return success indicating if retrieval was successful
    function retrieve(uint256 _amount,  address _assetRetrieved) external returns (bool success);

    /// @param _asset Token address of asset
    /// @return success indicating if token address is valid asset or not
    function isValidAsset(address _asset) external view returns (bool success);

    /// @param _owner Address of which to consult locked asset balance
    /// @param _asset Token address of asset
    /// @return asset uint256 amount of specified asset locked by _owner
    function assetLockedOf(address _owner, address _asset) external view returns (uint256 asset);

    event Mint(address indexed _minter, uint256 _value);
    event Burn(address indexed _burner, uint256 _value);

}
"},"IERC20.sol":{"content":"pragma solidity ^0.6.0;



interface IERC20 {

    /// @return total amount of tokens
    function totalSupply() external view returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance of address _owner
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
"},"SafeMath.sol":{"content":"pragma solidity ^0.6.0;

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
        // Solidity only automatically asserts when dividing by 0
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
}"}}