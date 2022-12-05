{{
  "language": "Solidity",
  "sources": {
    "/Users/zechariahmalachi/stage_1/contracts/custodian/MultisigGHOST.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../utils/Address.sol";

contract MultiSigWallet {
	event Deposit(address indexed sender, uint amount, uint balance);
	event SubmitTransaction(
		address indexed owner,
		uint indexed txIndex,
		address indexed to,
		uint value,
		bytes data
	);
	event ConfirmTransaction(address indexed owner, uint indexed txIndex);
	event RevokeConfirmation(address indexed owner, uint indexed txIndex);
	event ExecuteTransaction(address indexed owner, uint indexed txIndex);
	
	address[] private owners;
	mapping(address => bool) private isOwner;
	uint private numConfirmationsRequired;
	
	struct Transaction {
		address to;
		uint value;
		bytes data;
		bool executed;
		uint numConfirmations;
	}
	
	// mapping from tx index => owner => bool
	mapping(uint => mapping(address => bool)) public isConfirmed;
	
	Transaction[] public transactions;
	

	/**
	 * @dev Throws if sender is not one of the owners.
	 */
	modifier onlyOwner() {
		require(isOwner[msg.sender], "not owner");
		_;
	}
	

	/**
	 * @dev Throws if txIndex exists in transactions array.
	 * @param _txIndex Transaction index.
	 */
	modifier txExists(uint _txIndex) {
		require(_txIndex < transactions.length, "tx does not exist");
		_;
	}
	

	/**
	 * @dev Throws if field `executed` equal to `true`.
	 * @param _txIndex Transaction index.
	 */
	modifier notExecuted(uint _txIndex) {
		require(!transactions[_txIndex].executed, "tx already executed");
		_;
	}
	

	/**
	 * @dev Throws if transaction not confirmed by sender.
	 * @param _txIndex Transaction index.
	 */
	modifier notConfirmed(uint _txIndex) {
		require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
		_;
	}
	
	
	/**
	 * @dev Constructor for MultiSigWallet.
	 * Required: array of owners to be not empty.
	 * Required: confirmations to be between 1 and length of owners array.
	 * Required: every owner not to be zero-address.
	 * Required: every onwer not to be smart-contract???
	 * Required: no duplicates in owner array.
	 * 
	 * @param _owners Array of owners addresses.
	 * @param _numConfirmationsRequired Minimal number of confirmations needed to pass transaction.
	 */
	constructor(address[] memory _owners, uint _numConfirmationsRequired) {
		require(_owners.length > 0, "owners required");
		require(_numConfirmationsRequired > 0, "invalid number of required confirmations, less zero");
		require(_numConfirmationsRequired <= _owners.length, "invalid number of required confirmations, more than owners");
		
		for (uint i = 0; i < _owners.length; i++) {
			address owner = _owners[i];
			
			require(owner != address(0), "invalid owner");
			require(!isOwner[owner], "owner not unique");
			require(!Address.isContract(owner), "owner is smart contract");
			
			isOwner[owner] = true;
			owners.push(owner);
		}
		
		numConfirmationsRequired = _numConfirmationsRequired;
	}
	
	
	/**
	 * @dev Fallback function that will take ether and log event.
	 */
	receive() payable external {
		emit Deposit(msg.sender, msg.value, address(this).balance);
	}
	
	
	/**
	 * @dev Offers withdrawal transaction.
	 *
	 * @param _to Address where to withdraw funds.
	 * @param _value Amount of wei to withdraw.
	 * @param _data Complete calldata. 
	 */
	function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
		require(!Address.isContract(_to), "cannot withdraw to smart contract");
		require(_to != address(0), "canot withdraw to zero-address");
		require(_value > 0.3 ether, "cannot withdraw less 0.3 ETH");
		
		uint txIndex = transactions.length;
		transactions.push(Transaction({
			to: _to,
			value: _value,
			data: _data,
			executed: false,
			numConfirmations: 0
		}));
		
		emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
	}
	
	
	/**
	 * @dev Confirm proposed withdrawal transaction.
	 * Only address from owners array can use this function.
	 * Transaction should exist.
	 * Transaction should not be executed before.
	 * Transaction should not be confirmed by sender address.
	 * 
	 * @param _txIndex Transaction index.
	 */
	function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		transaction.numConfirmations += 1;
		isConfirmed[_txIndex][msg.sender] = true;
		
		emit ConfirmTransaction(msg.sender, _txIndex);
	}
	
	
	/**
	 * @dev Execute transaction that previously was confirmed by
	 * majority of owners (>= numConfirmationsRequired)
	 *
	 * Only address from owners array can execute it.
	 * Transaction should exist.
	 * Transaction should not be executed before.
	 *
	 * @param _txIndex Transaction index
	 */
	function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
		
		transaction.executed = true;
		
		(bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
		require(success, "tx failed");
		
		emit ExecuteTransaction(msg.sender, _txIndex);
	}
	
	
	/**
	 * @dev Revoke vote for withdrawal transaction.
	 *
	 * Only address from the owners array.
	 * Transaction should exists.
	 * Transaction should not be executed before.
	 * Transaction should be confirmed by this address before.
	 * 
	 * @param _txIndex Transaction index.
	 */
	function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
		
		transaction.numConfirmations -= 1;
		isConfirmed[_txIndex][msg.sender] = false;
		
		emit RevokeConfirmation(msg.sender, _txIndex);
	}
	
	
	/**
	 * @return Array of owners.
	 */
	function getOwners() public view returns (address[] memory) {
		return owners;
	}
	
	
	/**
	 * @return Number of minimum confirmations required
	 */
	function getConfirmationsCount() public view returns (uint) {
		return numConfirmationsRequired;
	}
	
	
	/**
	 * @return Total amount of transactions.
	 */
	function getTransactionCount() public view returns (uint) {
		return transactions.length;
	}
	
	
	/**
	 * @dev Get transaction full information.
	 * @param _txIndex Transaction index.
	 */
	function getTransaction(uint _txIndex) public view txExists(_txIndex) returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
		Transaction storage transaction = transactions[_txIndex];
		
		return (
			transaction.to,
			transaction.value,
			transaction.data,
			transaction.executed,
			transaction.numConfirmations
		);
	}
	
	
	/**
	 * @return Balance of current smart contract.
	 */
	function balance() public view returns (uint256) {
		return address(this).balance;
	}
	
	
	/**
	 * @dev Funciton that will clean up wallet balance.
	 * Only main owner can call.
	 * Balance should be less 0.3 ETH (otherwise call submitTransaction).
	 * Address to withdraw not zero-address.
	 * Address to withdraw not smart contract.
	 * 
	 * @param _to Address where all funds of smart-contract should go.
	 */
	function destructor(address payable _to) public {
		require(msg.sender == owners[0], "not the master");
		require(address(this).balance <= 0.3 ether, "too much balance");
		require(address(this).balance > 0, "not due payment");
		require(_to != address(0), "cannot be zero-address");
		require(!Address.isContract(_to), "cannot be smart contract");
		
		selfdestruct(_to);
	}

}
"
    },
    "/Users/zechariahmalachi/stage_1/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 5000
    },
    "evmVersion": "istanbul",
    "libraries": {},
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}