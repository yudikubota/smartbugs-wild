{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


/**
 * Utility library of inline functions on addresses
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

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	/**
		* @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
		* `errorMessage` as a fallback revert reason when `target` reverts.
		*
		* _Available since v3.1._
		*/
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
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
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}


	/**
		* @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
		* with `errorMessage` as a fallback revert reason when `target` reverts.
		*
		* _Available since v3.1._
		*/
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}


	/**
		* @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
		* revert reason using the provided one.
		*
		* _Available since v4.3._
		*/
	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract IERC20 {
  function transfer(address to, uint tokens) public virtual returns (bool success);
  function balanceOf(address _sender) public virtual view returns (uint _bal);
  function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
}"},"MarktPlace.sol":{"content":"
// SPDX-License-Identifier: MIT

// This version supports ETH and ERC20
pragma solidity 0.8.0;
import "./SafeErc20.sol";

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _value, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

interface ISecondaryMarketFees {
  struct Fee {
    address recipient;
    uint256 value;
  }
  function getFeeRecipients(uint256 tokenId) external view returns(address[] memory);
  function getFeeBps(uint256 tokenId) external view returns(uint256[] memory);
}

contract Marketplace {

  using SafeERC20 for IERC20;
  bytes4 private constant INTERFACE_ID_FEES = 0xb7799584;
  address public beneficiary;
  address public orderSigner;
  address public owner;

  enum AssetType { ETH, ERC20, ERC721, ERC1155, ERC721Deprecated }
  enum OrderStatus { LISTED, COMPLETED, CANCELLED }

  struct Asset {
    address contractAddress;
    uint256 tokenId;
    AssetType assetType;
    uint256 value;
  }

  struct Order {
    address seller;
    Asset sellAsset;
    Asset buyAsset;
    uint256 salt;
  }

  struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  mapping(bytes32 => Order) orders;
  mapping(bytes32 => OrderStatus) public orderStatus;

  event Buy(
    address indexed sellContract, uint256 indexed sellTokenId, uint256 sellValue,
    address owner,
    address buyContract, uint256 buyTokenId, uint256 buyValue,
    address buyer,
    uint256 salt
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner is allowed");
    _;
  }

  constructor(address _beneficiary, address _orderSigner) {
    beneficiary = _beneficiary;
    orderSigner = _orderSigner;
    owner = msg.sender;
  }

  function updateOrderSigner(address newOrderSigner) public onlyOwner {
    orderSigner =  newOrderSigner;
  }

  function updateBeneficiary(address newBeneficiary) public onlyOwner {
    beneficiary = newBeneficiary;
  }

   function exchange(
    Order calldata order,
    Signature calldata sellerSignature,
    Signature calldata buyerSignature,
    address buyer,
    uint256 sellerFee,
    uint256 buyerFee
  ) public payable {
    if(buyer == address(0)) buyer = msg.sender;

    validateSellerSignature(order, sellerFee, sellerSignature);
    validateBuyerSignature(order, buyer, buyerFee, buyerSignature);
    
    require(order.sellAsset.assetType == AssetType.ERC721 || order.sellAsset.assetType == AssetType.ERC1155  , "Only ERC721 are supported on seller side");
    require(order.buyAsset.assetType == AssetType.ETH || order.buyAsset.assetType == AssetType.ERC20, "Only Eth/ERC20 supported on buy side");
    require(order.buyAsset.tokenId == 0, "Buy token id must be UINT256_MAX");
    if(order.buyAsset.assetType == AssetType.ETH) {
      validateEthTransfer(order.buyAsset.value, buyerFee);
    }

    uint256 remainingAmount = transferFeeToBeneficiary(
      order.buyAsset, 
      buyer,
      order.buyAsset.value,
      sellerFee,
      buyerFee
    );

    transfer(order.sellAsset, order.seller, buyer, order.sellAsset.value);
    transferWithFee(order.buyAsset, buyer, order.seller, remainingAmount, order.sellAsset);
    emitBuy(order, buyer);
  }

  
  function transferFeeToBeneficiary(
    Asset memory asset, address from, uint256 amount, uint256 sellerFee, uint256 buyerFee
  ) internal returns(uint256) {
    uint256 sellerCommission = getPercentageCalc(amount, sellerFee);
    uint256 buyerCommission = getPercentageCalc(amount, buyerFee);
    require(sellerCommission <= amount, "Seller commission exceeds amount");
    uint256 totalCommission = sellerCommission + buyerCommission;
    if(totalCommission > 0) {
      transfer(asset, from, beneficiary, totalCommission);
    }
    return amount - sellerCommission;
  }

  function transferWithFee(
    Asset memory _primaryAsset,
    address from,
    address to,
    uint256 amount,
    Asset memory _secondaryAsset
  ) internal {
    uint256 remainingAmount = amount;
    if(supportsSecondaryFees(_secondaryAsset)) {
      ISecondaryMarketFees _secondaryMktContract = ISecondaryMarketFees(_secondaryAsset.contractAddress);
      address[] memory recipients = _secondaryMktContract.getFeeRecipients(_secondaryAsset.tokenId);
      uint[] memory fees = _secondaryMktContract.getFeeBps(_secondaryAsset.tokenId);
      require(fees.length == recipients.length, "Invalid fees arguments");
      for(uint256 i=0; i<fees.length; i++) {
        uint256 _fee = getPercentageCalc(_primaryAsset.value, fees[i]);
        remainingAmount = remainingAmount - _fee;
        transfer(_primaryAsset, from, recipients[i], _fee);
      }
    }
    transfer(_primaryAsset, from, to, remainingAmount);
  }

  function transfer(Asset memory _asset, address from, address to, uint256 value) internal {
    if(_asset.assetType == AssetType.ETH) {
      payable(to).transfer(value);
    } else if(_asset.assetType == AssetType.ERC20) {
      IERC20(_asset.contractAddress).safeTransferFrom(from, to, value);
    } else if(_asset.assetType == AssetType.ERC721) {
      require(value == 1, "value should be 1 for ERC-721");
      IERC721(_asset.contractAddress).safeTransferFrom(from, to, _asset.tokenId);
    } else if(_asset.assetType == AssetType.ERC1155) {
      IERC1155(_asset.contractAddress).safeTransferFrom(from, to, _asset.tokenId, value, "0x");
    } else {
      require(value == 1, "value should be 1 for ERC-721");
      IERC721(_asset.contractAddress).transferFrom(from, to, _asset.tokenId);
    }
  }

  function validateEthTransfer(uint amount, uint buyerFee) internal view {
    uint256 buyerCommission =  getPercentageCalc(amount, buyerFee);
    require(msg.value == amount + buyerCommission, "msg.value is incorrect");
  }

  function validateSellerSignature(Order calldata _order, uint256 sellerFee, Signature calldata _sig) public pure {
    bytes32 signature = getMessageForSeller(_order, sellerFee);
    require(getSigner(signature, _sig) == _order.seller, "Seller must sign order data");
  }

  function validateBuyerSignature(Order calldata order, address buyer, uint256 buyerFee,
    Signature calldata sig) public view {
    bytes32 message = getMessageForBuyer(order, buyer, buyerFee);
    require(getSigner(message, sig) == orderSigner, "Order signer must sign");
  }

  function getMessageForSeller(Order calldata order, uint256 sellerFee) public pure returns(bytes32) {
    return keccak256(abi.encode(order, sellerFee));
  }

  function getMessageForBuyer(Order calldata order, address buyer, uint256 buyerFee) public pure returns(bytes32) {
    return keccak256(abi.encode(order, buyer, buyerFee));
  }

  function getSigner(bytes32 message, Signature memory _sig) public pure returns (address){
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return ecrecover(keccak256(abi.encodePacked(prefix, message)),_sig.v, _sig.r, _sig.s);
  }

  function emitBuy(Order calldata order, address buyer) internal {
    emit Buy(
      order.sellAsset.contractAddress,
      order.sellAsset.tokenId,
      order.sellAsset.value,
      order.seller,
      order.buyAsset.contractAddress,
      order.buyAsset.tokenId,
      order.buyAsset.value,
      buyer,
      order.salt
    );
  }

  function getPercentageCalc(uint256 totalValue, uint _percentage) internal pure returns(uint256) {
    return (totalValue * _percentage) / 1000 / 100;
  }
  
  function supportsSecondaryFees(Asset memory asset) internal view returns(bool) {
    return (
      (asset.assetType == AssetType.ERC1155 &&
      IERC1155(asset.contractAddress).supportsInterface(INTERFACE_ID_FEES)) ||
      ( isERC721(asset.assetType) &&
      IERC721(asset.contractAddress).supportsInterface(INTERFACE_ID_FEES))
    );
  }
  
  function isERC721(AssetType assetType) internal pure returns(bool){
    return assetType == AssetType.ERC721 || assetType == AssetType.ERC721Deprecated;
  }

}"},"SafeErc20.sol":{"content":"
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
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
    
	using Address for address;


    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        // functionCall(target, data, "Address: low-level call failed")
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

"}}