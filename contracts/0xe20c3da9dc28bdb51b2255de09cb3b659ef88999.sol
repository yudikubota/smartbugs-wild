{"AppBase.sol":{"content":"// SPDX-License-Identifier: MIT
// AppBase.sol : CryptoStacks(tm) Stacks721 by j0zf at ApogeeINVENT 2021-02-28

pragma solidity >=0.6.0 <0.8.0;
import "./SafeMath.sol"; 
import "./Strings.sol"; 
import "./Market.sol";
import "./Holdings.sol";

abstract contract AppBase { 
	using SafeMath for uint256;
	using Strings for uint256;
	using Market for Market.TokenContract;
	using Market for Market.Listing;
	using Holdings for Holdings.HoldingsTable;

	//	from Library Holdings.sol
	event AccountCredited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);
	event AccountDebited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);
	event PoolCredited(uint32 poolType, uint256 amount, uint256 balance);
	event PoolDebited(uint32 indexed poolType, uint256 amount, uint256 balance);

	bool internal _paused;
	uint32 internal _networkId;
	mapping(string => string) internal _values; // version, banner, whatever, etc..
	Market.TokenContract[] internal _tokenContracts;
	Market.Listing[] internal _listings; // indexed by listingId
	mapping(address => uint256[]) internal _activeListingIds; // address(0) is ALL active listings
	mapping(address => mapping(uint256 => uint256)) internal _activeListingIdIndexes; // address(0) is ALL active listings, Maintains Index into _activeListingIds 
	mapping(uint256 => mapping(string => mapping(uint256 => uint256))) internal _contractListingIds; // __[contractId]["token"|"series"][id] => listingId

	Holdings.HoldingsTable internal _holdingsTable;

	mapping(uint32 => uint256) internal _conversionTable;
	// ^^ _conversionTable[peg] => conversion multiplier so Value * Multiplier = Approx Value in Wei
	// ^^ peg is the index for the container of the conversion multiplier: 0:Wei 1:USD

	mapping(uint32 => mapping(address => bool)) internal _roles; 
	// ^^ _roles[roleType][address] => true : "Has Role"
	// ^^ roleType 0:Null 1:Admin 2:Manager 3:Publisher
	uint32 constant _Admin_Role_ = 1;
	uint32 constant _Manager_Role_ = 2;
	uint32 constant _Publisher_Role_ = 3;
	uint32 constant _Banker_Role_ = 4;

	mapping(bytes4 => address) internal _logicFunctionContracts; // for mapping specific functions to contract addresses

	// Generalized Storage Containers for Proxy Logic expansions
	mapping(string => uint256) internal uint256Db;
	mapping(string => mapping(uint256 => uint256)) internal uint256MapDb;
	mapping(string => string) internal stringDb;
	mapping(string => mapping(uint256 => string)) internal stringMapDb;
	mapping(string => address) internal addressDb;
	mapping(string => mapping(uint256 => address)) internal addressMapDb;
	mapping(string => bytes) internal bytesDb;
	mapping(string => mapping(uint256 => bytes)) internal bytesMapDb;

	mapping(uint256 => mapping(string => uint32)) internal _listingDataInt; // listingId => "name" => uint32
	mapping(uint256 => mapping(string => uint256)) internal _listingDataNumber;
	mapping(uint256 => mapping(string => string)) internal _listingDataString;

	function installLogic(address logicContract, bool allowOverride) external {
		require(_roles[_Admin_Role_][msg.sender], "DENIED"); // 1:Admin
		(bool success, ) = logicContract.delegatecall(abi.encodeWithSignature("installProxy(address,bool)", logicContract, allowOverride));
		if (!success) {
			revert("FAILED_INSTALL");
		}
	}

	bool internal reentrancyLock = false;
	modifier nonReentrant() {
		require(!reentrancyLock);
		reentrancyLock = true;
		_;
		reentrancyLock = false;
	}

	function _setLogicFunction(string memory functionSignature, address functionContract, bool allowOverride) internal {
		require(_roles[_Admin_Role_][msg.sender], "DENIED"); // 1:Admin
		bytes4 sig = bytes4(keccak256(bytes(functionSignature)));
		require(sig != bytes4(keccak256(bytes("installLogic(address)"))), "CRASH!");
		require(sig != bytes4(keccak256(bytes("installProxy(address)"))), "BOOM!");
		require(allowOverride || _logicFunctionContracts[sig] == address(0), "OVERRIDE");
		_logicFunctionContracts[sig] = functionContract;
		emit LogicFunctionSet(functionSignature, sig, functionContract, allowOverride);
	}
	event LogicFunctionSet(string functionSignature, bytes4 indexed sig, address functionContract, bool allowOverride);

	function _delegateLogic() internal {
		address _delegateContract = _logicFunctionContracts[msg.sig];
		require(_delegateContract != address(0), "NO_LOGIC"); // No Logic Function found in the lookup table
		require(!_paused || _roles[_Admin_Role_][msg.sender], "PAUSED");  // 1:Admin
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), _delegateContract, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
				case 0 { revert(ptr, size) }
				default { return(ptr, size) }
		}
	}

	function _setConversion(uint32 peg, uint256 multiplier) internal {
		// ENFORCE EXTERNALLY
		// Currency Value X multiplier = nativePrice in Wei
		// peg 0 is native Wei, peg 1 is USD, etc.
		_conversionTable[peg] = multiplier;
	}

	function _getConversion(uint32 peg, uint256 value) internal view returns (uint256) {
		// @returns the nativePrice. A value in Wei converted by using a multiplier in a currency conversion-table
		// if the peg is not set. 0 will be returned
		// 	^ (note the "0" nativePrice or askingPrice should be "not for sale")
		// peg 0 is always native Wei peg 1 is USD and so on
		return ( peg == 0 ? value : value.mul(_conversionTable[peg]) );
	}

	function _percentOf(uint256 percent, uint256 x) internal pure returns (uint256) {
		// get truncated percentage of x, discards remainder. (percent is a whole number percent)
		return x.mul(percent).div(100);
	}

	function _removeActiveListing(address owner, uint256 listingId) internal returns (bool) {
		// @param address(0) for ALL active listings
		if (listingId < 1 || _activeListingIds[owner].length < 1) return false;
		uint256 endListingIndex = _activeListingIds[owner].length - 1;
		if (_activeListingIds[owner][endListingIndex] == listingId) { // it's on the end so pop it off
			_activeListingIdIndexes[owner][listingId] = uint256(-1); // Max uint256 is Non-Indexed
			_activeListingIds[owner].pop();
			return true;
		}
		uint256 index = _getActiveListingIdIndex(owner, listingId);
		if (index != uint256(-1)) { // replace it with the one on the end
			uint256 endListingId = _activeListingIds[owner][endListingIndex]; 
			_activeListingIds[owner][index] = endListingId;
			_activeListingIdIndexes[owner][listingId] = uint256(-1);  // Max uint256 is Non-Indexed
			_activeListingIdIndexes[owner][endListingId] = index; 
			_activeListingIds[owner].pop();
			return true;
		}
		return false;
	}

	function _addActiveListing(address owner, uint256 listingId) internal returns (bool) {
		// @param address(0) for ALL active listings
		if (_getActiveListingIdIndex(owner, listingId) == uint256(-1)) {
			_activeListingIdIndexes[owner][listingId] = _activeListingIds[owner].length; // track index into the _activeListingIds
			_activeListingIds[owner].push(listingId);
			return true;
		}
		return false;
	}

	function _getActiveListingIdIndex(address owner, uint256 listingId) internal view returns (uint256) {
		uint256 index = _activeListingIdIndexes[owner][listingId];
		if ( index < _activeListingIds[owner].length && _activeListingIds[owner][index] == listingId ) {
			return index;
		}
		return uint256(-1); // Max value means not found
	}

}
"},"Holdings.sol":{"content":"// SPDX-License-Identifier: MIT
// Holdings.sol - j0zf 2021-03-14

pragma solidity >=0.6.0 <0.8.0;
import "./SafeMath.sol"; // import "@openzeppelin/contracts/math/SafeMath.sol";

library Holdings {
	using SafeMath for uint256;

	// 0:Null 1:Royalties 2:Sales 3:General 4:Bonuses 5:Refunds 6:Bids Escrow 7:Trades Escrow 8:Auction Escrow 9:Tax Escrow 10:Withdrawal Escrow
	uint32 constant _Royalties_ = 1;
	uint32 constant _Sales_ = 2;
	uint32 constant _General_ = 3;
	uint32 constant _Bonuses_ = 4;
	uint32 constant _Refunds_ = 5;
	uint32 constant _Bids_Escrow_ = 6;
	uint32 constant _Trades_Escrow_ = 7;
	uint32 constant _Auctions_Escrow_ = 8;
	uint32 constant _Tax_Escrow_ = 9;
	uint32 constant _Withdrawal_Escrow_ = 10;

	// pools poolType 0:Null 1:House Pool 2:Bonus Pool 3:Tax Pool 4:Withdrawal Pool
	uint32 constant _House_Pool_ = 1;
	uint32 constant _Bonus_Pool_ = 2;
	uint32 constant _Tax_Pool_ = 3;
	uint32 constant _Withdrawal_Pool_ = 4;

	struct HoldingsTable {
		mapping(uint32 => mapping(address => uint256)) _holdings; // holdings[accountType][address] => balance;
		mapping(uint32 => uint256) _holdingsTotals; // holdingsTotals[accountType] => total; (accounts for _holdings)
		mapping(uint32 => uint256) _pools; // pools[poolType] => balance;
	}

	function creditAccount(HoldingsTable storage holdingsTable, uint32 accountType, address account, uint256 amount) internal {
		require(accountType > 0 && account != address(0), "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._holdings[accountType][account];
		uint256 total = holdingsTable._holdingsTotals[accountType];
		balance = balance.add(amount);
		total = total.add(amount);
		holdingsTable._holdings[accountType][account] = balance;
		holdingsTable._holdingsTotals[accountType] = total;
		emit AccountCredited(accountType, account, amount, balance);
	}
	event AccountCredited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);

	function debitAccount(HoldingsTable storage holdingsTable, uint32 accountType, address account, uint256 amount) internal {
		require(accountType > 0 && account != address(0), "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._holdings[accountType][account];
		uint256 total = holdingsTable._holdingsTotals[accountType];
		require(balance >= amount && total >= amount, "NOT_ENOUGH");
		balance = balance.sub(amount);
		total = total.sub(amount);
		holdingsTable._holdings[accountType][account] = balance;
		holdingsTable._holdingsTotals[accountType] = total;
		emit AccountDebited(accountType, account, amount, balance);
	}
	event AccountDebited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);

	function transferAmount(HoldingsTable storage holdingsTable, uint32 fromAccountType, address fromAccount, uint32 toAccountType, address toAccount, uint256 amount) internal {
		Holdings.debitAccount(holdingsTable, fromAccountType, fromAccount, amount);
		Holdings.creditAccount(holdingsTable, toAccountType, toAccount, amount);
	}
	function transferPoolAmount(HoldingsTable storage holdingsTable, uint32 fromPoolType, uint32 toAccountType, address toAccount, uint256 amount) internal {
		Holdings.debitPool(holdingsTable, fromPoolType, amount);
		Holdings.creditAccount(holdingsTable, toAccountType, toAccount, amount);
	}

	function getAccountBalance(HoldingsTable storage holdingsTable, uint32 accountType, address account) internal view returns (uint256) {
		require(accountType > 0 && account != address(0), "BAD_INPUT");
		return holdingsTable._holdings[accountType][account];
	}

	function getHoldingsTotal(HoldingsTable storage holdingsTable, uint32 accountType) internal view returns (uint256) {
		// @returns totals of all accounts for each accountType in the holdingsTable
		require(accountType > 0, "BAD_INPUT");
		return holdingsTable._holdingsTotals[accountType];
	}

	function creditPool(HoldingsTable storage holdingsTable, uint32 poolType, uint256 amount) internal {
		require(poolType > 0, "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._pools[poolType];
		balance = balance.add(amount);
		holdingsTable._pools[poolType] = balance;
		emit PoolCredited(poolType, amount, balance);
	}
	event PoolCredited(uint32 poolType, uint256 amount, uint256 balance);

	function debitPool(HoldingsTable storage holdingsTable, uint32 poolType, uint256 amount) internal {
		require(poolType > 0, "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._pools[poolType];
		require(balance >= amount, "NOT_ENOUGH");
		balance = balance.sub(amount);
		holdingsTable._pools[poolType] = balance;
		emit PoolDebited(poolType, amount, balance);
	}
	event PoolDebited(uint32 indexed poolType, uint256 amount, uint256 balance);

	function getPoolBalance(HoldingsTable storage holdingsTable, uint32 poolType) internal view returns (uint256) {
		require(poolType > 0, "BAD_INPUT");
		return holdingsTable._pools[poolType];
	}

}
"},"Market.sol":{"content":"// SPDX-License-Identifier: MIT
// 20220612 j0zf - Market
// 2021-02-25 Media Library for CryptoStacks - j0zf
// 2020-07-06 MediaTokens Library for CryptoMedia - j0zf

pragma solidity >=0.6.0 <0.8.0;

library Market {

	// Status Types
	uint32 constant _Open_ = 1;
	uint32 constant _Complete_ = 2;
	uint32 constant _Cancelled_ = 3;

	// Listing Types
	uint32 constant _Mintable_ = 1;
	uint32 constant _Sale_  = 2;
	uint32 constant _Bid_  = 3;
	uint32 constant _DutchAuction_  = 4;
	uint32 constant _EnglishAuction_  = 5;
	uint32 constant _Trade_  = 6;
	uint32 constant _ClaimCode_  = 7;
	uint32 constant _Free_  = 8;

	struct TokenContract {
		string name;
		address location;
		uint32 contractType;
	}

	struct Listing {
		uint256 contractId;
		address owner;
		uint32 listingType;
		uint32 status;
	}

}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}
"},"StacksStore.sol":{"content":"// SPDX-License-Identifier: MIT
// StacksStore Marketplace - Proxy - Stacks721(tm) / StacksNET(tm) : Stacks and Stacks of Multimedia
// CryptoComics.com - A media token library marketplace built for blockchain networks.
// (c) Copyright 2022, j0zf at apogeeinvent.com
// StacksStore.sol : j0zf 2022-04-23
// Stacks721.sol : CryptoStacks(tm) Stacks721 by j0zf at ApogeeINVENT(tm) 2021-02-28
// StacksNET(tm) : Stacks and Stacks of Multimedia a Library Marketplace built upon an Ethereum sidechain PoA (proof of authority) Blockchain Network.
// .   .       .:      ...   .     * .         ..   :    .        .       .  + .     .  .  +
//   .   . x      . -      . ..       .  ...   .       .    + .          .    .    *        
//      .        .   .   .        ---=*{[ CryptoComics.com ]}*=--    .  x   .   .       .. 
//  .     .  .   . .   *   . .    +  .   .      .   .  .      :.       .              .    .
//    .  .   . .       . .       .   .      .   .  .       .       .      .     ..    .    .
//  .  :     .    ..        ____  __ __      .   *  .   :       ;  .     -=-              . 
// .        .    .   . ."_".^ .^ ^. "'.^`:`-_  .    .    .    .      .       .    :.     .  
//  .   .    +.    ,:".   .    .    "   . . .:`    .  +  .  *    .   .   . ..  .        .   
//   .     . _   ./:           `   .  ^ .  . .:``   _ .       :.     .   .  .       .       
// .   . -      ./.                   .    .  .:`\      . -      .    .  .   .    .     o  :
//   .     .   .':                       .   . .:!.   .        -+-     + + . . ..  .       :
//   O  .      .!                            . !::.      .   .         .   . .:  .     .   +
//  . . .  :.  :!    ^                    ^  . ::!:  .   .      .   :     .   .         .   
//     - .     .:.  .o..               ...o.   ::|. .   : .  .   :  .  .  .   .    .  x     
//   :     .   `: .ooooooo.          .ooooooo :::.   :.   :  _____________                :.
// .  ..  .  .. `! .ooOooooo        .ooooOooo .:'  ..  .   /   .   .       :\ .  . - .   .  
//     .+    : -. \ .ooO*Ooo.      .ooO*Oooo .:'  -     ./   ____________ ,::\ :  .  . .  . 
// .+   .   . .  . \. .oooOoo      :oOooooo..:' .  . . .!| / .   .      `::\::!" .    .  ,  
// : .     .     .. .\ .ooooo      :ooooo.::'   . .   . ( '  .  .         ::!:.)    .  .    
// .   .  .. :  -    .\    ..   .   .. ::.:' . .    : . | !   . .        .::|:|)    -      .
//   +     .  .- ." .  .\      ||     ..:'. .  .  -.  .  . .    .        ::/ //.  .    +    
//  -.   . ` . .  .   . .\.    ``     .:' .  . :. . . .  _\ \___________.:` //___    . - .  
//  .  :        .  .  _ ..:\  .___/  :'. .: _ . .  .    /  \.__ :  : _. ___/ ::""\\     .   
// .  .   . . .. .  .:  . .:\       :': . .    . .  .  !     ''..:.:::/`      `:::||       .
//   .   .     .   .  . . .:.`\_(__/ ::. . :.: .  :.   |     ! :  !  .===   ..  ::||.   x + 
//\___________-...:::::::::::!|    .:\;::::::::::::::::|:   .!  + !!  BOB :.``   :.|::..-___
//            \\:::::::::::../.  ^.: :.;:::::::::::::::!   :!`.  .!.   ^   :::   :!:::://   
//             \\::::::.::::/  .  .:: ::\:::::::::::::.:. .:|`    !! .| |  ::: . :.!:://    
//              \\:_________________________________________________________________://     

pragma solidity >=0.6.0 <0.8.0;
import "./AppBase.sol";

contract StacksStore is AppBase {
    constructor (uint32 networkId) public {
        _values["name"] = "StacksNET Marketplace";
        _values["version"] = "1.2.1";
        _networkId = networkId;
        _roles[_Admin_Role_][msg.sender] = true; // 1:Admin
        _roles[_Manager_Role_][msg.sender] = true; // 2:Manager
        _roles[_Publisher_Role_][msg.sender] = true; // 3:Publisher
    }

    receive () external payable {
        _holdingsTable.creditAccount(Holdings._Refunds_, msg.sender, msg.value);
    }

    fallback () external payable {
        return _delegateLogic();
    }
}
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
"}}