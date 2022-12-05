{{
  "language": "Solidity",
  "sources": {
    "/contracts/PCPasture.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./PocketCow.sol";

/// @title An epoch-based proportional eth distributor.
/// @author Ethan Pendergraft
/// @notice Allows a user to withdraw a proportional amount based off of how many tokens they have burnt.
contract PCPasture is Ownable {

	event ValueAdded(uint256 unIncreaseAmount);
	event PasturePayout(address Receiver, uint256 Amount);
	event OwnerWithdrawal(address Receiver, uint256 Amount);

	/// @dev The target contract we use to derive an addresses' burn count.
	PocketCow m_pcHolderContract;

	/// @dev An address that is allowed to withdraw from the owner's share.
	address m_adrWithdrawProxy;

	/// @dev The previouly measured balance, used to detect deposits.
	uint256 m_unPrevContractBalance = 0;

	struct MasterEpoch {
		uint256 TokenCount;
		uint256 Value;
	}

	/// @dev The id of the most recent master epoch. It will increase by 1 the first a cow is burn after each deposit.
	uint256 m_unCurrMasterEpochID = 0;
	
	/// @dev Maps epoch IDs to master epochs, no epoch is ever destroyed.
	mapping(uint256 => MasterEpoch) m_mapIDToMasterEpoch;

	/// @dev The id of the last epoch that the owner withdrew from.
	uint256 m_unOwnerEpochID = 0;

	/// @dev The raw, unscaled amount of eth that the owner has withdrawn. The actual amount is lower.
	uint256 m_unOwnerCurrEpochWidthdrawAmount = 0;

	struct HolderEpoch {
		uint256 TokenCount;	// Number of burned tokens held by address
		uint256 EpochID;		// ID of Epoch, used to get total token count
		uint256 ValueWitnessed;	// Unscaled value consumed
	}

	/// @dev Maps each address to its list of epochs. Older epochs will be destryoed once a token holder has withdrawn all of their proportional value.
	mapping(address => HolderEpoch[]) m_mapAddressToHolderEpochs;

	///
	constructor(address payable adrHolderCon) {
		setHolderContract(adrHolderCon);
		startNewMasterEpoch();
	}

	// @notice Will receive any eth sent to the contract
	// https://docs.soliditylang.org/en/v0.8.14/contracts.html#receive-ether-function
	receive () external payable {

	}

	// Admin Functions ===========================================================
	/// @notice Sets the token contract that contains burnt token information.
	/// @param adrHolderCon The address of the contract managing burnt tokens.
	function setHolderContract(address payable adrHolderCon) public onlyOwner {
		m_pcHolderContract = PocketCow(adrHolderCon);
	}

	/// @notice Provides the address of the contract being referenced for burnt token information.
	/// @return Address of reference contract.
	function getHolderContract() external view returns(address) {
		return address(m_pcHolderContract);
	}

	/// @notice Sets who can withdraw from the owner's share other than the owner. Only 1 at a time.
	/// @param adrTarget The address to allow to withdraw from the owner's share
	function setWithdrawProxy(address adrTarget) external onlyOwner {
		m_adrWithdrawProxy = adrTarget;
	}

	/// @return The current address that is allowed to withdraw from the owner's share
	function getWithdrawProxy() external view onlyOwner returns(address) {
		return m_adrWithdrawProxy;
	}

	// General Information Access ================================================

	/// @return The number of burnt tokens there were during the last update
	function getLatestTokenCountInMasterEpoch() public view returns (uint256){
		return m_mapIDToMasterEpoch[m_unCurrMasterEpochID].TokenCount;
	}

	/// @param adrTarget The address to get the epoch count for
	/// @return The number of epochs that an address has
	function getEpochCountOf(address adrTarget) public view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget].length;
	}

	/// @param adrTarget The address to get the value from
	/// @param unIndex The epoch index to get the value from
	/// @return The value that has been marked as consumed for a given address in a given epoch
	function getValueWitnessedInEpochOf(address adrTarget, uint256 unIndex) external view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget][unIndex].ValueWitnessed;
	}

	/// @param adrTarget The address to get the token count from
	/// @param unIndex The epoch index to get the token count from
	/// @return The number of tokens that the target address owned during the epoch at unIndex
	function getTokenCountInEpochOf(address adrTarget, uint256 unIndex) public view returns(uint256) {
		return m_mapAddressToHolderEpochs[adrTarget][unIndex].TokenCount;
	}

	/// @param adrHolder The address to get the token count from
	/// @return The number of tokens that the target address owned during the last update
	function getLatestTokenCountOf(address adrHolder) external view returns(uint256) {
		
		HolderEpoch[] storage liHeCurr = m_mapAddressToHolderEpochs[adrHolder];
		if(liHeCurr.length < 1)
			return 0;

		return getTokenCountInEpochOf(adrHolder, liHeCurr.length - 1);
	}

	/// @dev This caps balance change so that its never negative, and never underflows.
	/// @return The amount that the value stored in the contract has increased since the last update.
	function getBalanceIncrease() public view returns(uint256) {

		if(address(this).balance <= m_unPrevContractBalance)
			return 0;

		return address(this).balance - m_unPrevContractBalance;
	}

	// Internal Structure Functions ==============================================

	function updatePrevValue(uint256 unDiff) private {
		m_unPrevContractBalance = address(this).balance - unDiff;
	}

	function getLastBalance() external view returns(uint256) {
		return m_unPrevContractBalance;
	}

	function startNewMasterEpoch() private {
		m_unCurrMasterEpochID++;
		updateMasterEpoch();
	}

	function updateMasterEpoch() private {
		m_mapIDToMasterEpoch[m_unCurrMasterEpochID].TokenCount = m_pcHolderContract.BurntTokenTotal();
	}

	function addValueToMasterEpoch(uint256 unNewValue) private {
		m_mapIDToMasterEpoch[m_unCurrMasterEpochID].Value += unNewValue;
	}

	function getValueOfMasterEpoch() private view returns(uint256) {
		return m_mapIDToMasterEpoch[m_unCurrMasterEpochID].Value;
	}

	function startNewHolderEpoch(address adrHolder, uint256 unValue) private {
		m_mapAddressToHolderEpochs[adrHolder].push(HolderEpoch(
			m_pcHolderContract.burnBalanceOf(adrHolder),
			m_unCurrMasterEpochID,
			unValue
		));
	}

	//============================================================================

	function updateValue() public {

		uint256 unValInc = getBalanceIncrease();
		if(unValInc > 0) {
			addValueToMasterEpoch(unValInc);
			updatePrevValue(0);

			emit ValueAdded(unValInc);
		}
	}

	function processPayout() private returns(uint256) {

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];

		require(arrCurrHoldEpochs.length > 0, "Address has no epochs.");

		uint256 unPayoutTotal = 0;
		uint256 unMasterEpochCountTotal = 0;
		uint256 unHoldEpochIdx = 0;
		HolderEpoch storage currHoldEpoch = arrCurrHoldEpochs[0];

		for(uint256 unMEID = arrCurrHoldEpochs[0].EpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			uint256 unNextHoldEpochIdx = unHoldEpochIdx + 1;
			if(unNextHoldEpochIdx < arrCurrHoldEpochs.length) {

				if(unMEID == arrCurrHoldEpochs[unNextHoldEpochIdx].EpochID) {
					currHoldEpoch = arrCurrHoldEpochs[unNextHoldEpochIdx];
					unHoldEpochIdx = unNextHoldEpochIdx;

					unMasterEpochCountTotal = 0;
				}
			}

			unMasterEpochCountTotal += currMastEpoch.Value;

			if(currHoldEpoch.ValueWitnessed >= unMasterEpochCountTotal)
				continue;

			uint256 unDelta = unMasterEpochCountTotal - currHoldEpoch.ValueWitnessed;
			currHoldEpoch.ValueWitnessed += unDelta;
			
			uint256 unScaledUp = unDelta * currHoldEpoch.TokenCount;
			unPayoutTotal += unScaledUp / 10.0 / currMastEpoch.TokenCount;
		}

		return unPayoutTotal;
	}

	function getBalance() external view returns(uint256) {

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];

		require(arrCurrHoldEpochs.length > 0, "Address has no epochs.");

		uint256 unPayoutTotal = 0;
		uint256 unMasterEpochCountTotal = 0;
		uint256 unHoldEpochIdx = 0;

		HolderEpoch storage currHoldEpoch = arrCurrHoldEpochs[0];
		uint256 unCurrEpochValueWitnessed = currHoldEpoch.ValueWitnessed;

		for(uint256 unMEID = arrCurrHoldEpochs[0].EpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			uint256 unNextHoldEpochIdx = unHoldEpochIdx + 1;
			if(unNextHoldEpochIdx < arrCurrHoldEpochs.length) {

				if(unMEID == arrCurrHoldEpochs[unNextHoldEpochIdx].EpochID) {
					currHoldEpoch = arrCurrHoldEpochs[unNextHoldEpochIdx];
					unCurrEpochValueWitnessed = currHoldEpoch.ValueWitnessed;
					unHoldEpochIdx = unNextHoldEpochIdx;
					unMasterEpochCountTotal = 0;
				}
			}

			unMasterEpochCountTotal += currMastEpoch.Value;

			if(unCurrEpochValueWitnessed >= unMasterEpochCountTotal)
				continue;

			uint256 unDelta = unMasterEpochCountTotal - unCurrEpochValueWitnessed;
			unCurrEpochValueWitnessed += unDelta;
			
			uint256 unScaledUp = unDelta * currHoldEpoch.TokenCount;
			unPayoutTotal += unScaledUp / 10.0 / currMastEpoch.TokenCount;
		}

		return unPayoutTotal;
	}
	
	function withdrawBalance() external {

		require(getLatestTokenCountInMasterEpoch() == m_pcHolderContract.BurntTokenTotal(),
			"onTokenBurnt() needs to be called for each address not registered.");

		updateValue();

		uint256 un256Payout = processPayout();
		require(un256Payout > 0, "Nothing to collect.");

		HolderEpoch[] storage arrCurrHoldEpochs = m_mapAddressToHolderEpochs[msg.sender];
		HolderEpoch memory epHoldMostRecent = arrCurrHoldEpochs[arrCurrHoldEpochs.length - 1];
		delete m_mapAddressToHolderEpochs[msg.sender];
		m_mapAddressToHolderEpochs[msg.sender].push(epHoldMostRecent);

		emit PasturePayout(msg.sender, un256Payout);
		updatePrevValue(un256Payout);

		(bool bSuccess, ) = msg.sender.call{value: un256Payout}("");
		require(bSuccess, "Transfer to pasture holder failed.");

	}

	// Called when it is discovered that a token has burnt.
	function onTokenBurnt(address adrHolder) external {

		uint32 unBurnBalance = m_pcHolderContract.burnBalanceOf(adrHolder);
		require(unBurnBalance > 0, "Address has not burnt any tokens.");

		updateValue();

		if(getValueOfMasterEpoch() > 0) startNewMasterEpoch();
		else updateMasterEpoch();

		uint256 unEpochCount = getEpochCountOf(adrHolder);

		if(unEpochCount < 1) {
			startNewHolderEpoch(adrHolder, 0);
			return;
		}

		HolderEpoch storage currHoldEpoch = m_mapAddressToHolderEpochs[adrHolder][unEpochCount - 1];
		require(unBurnBalance > currHoldEpoch.TokenCount, "No new burnt tokens to process.");

		if(currHoldEpoch.EpochID != m_unCurrMasterEpochID) {
			startNewHolderEpoch(adrHolder, 0);
			return;
		}

		// Update the token count if it still points to the current epoch.
		currHoldEpoch.TokenCount = unBurnBalance;
	}

	function getOwnerBalance() public view returns (uint256) {

		require(owner() == _msgSender() || m_adrWithdrawProxy == _msgSender(), 
			"Caller must be owner or proxy");

		uint256 unRootWithdrawTotal = 0;

		for(uint256 unMEID = m_unOwnerEpochID; unMEID <= m_unCurrMasterEpochID; ++unMEID) {

			MasterEpoch storage currMastEpoch = m_mapIDToMasterEpoch[unMEID];

			// Special case for withdrawing eth deposited in an epoch after last withdrawal.
			if(unMEID == m_unOwnerEpochID 
					&& currMastEpoch.Value > m_unOwnerCurrEpochWidthdrawAmount) {

				uint256 unDiff = currMastEpoch.Value - m_unOwnerCurrEpochWidthdrawAmount;
				unRootWithdrawTotal += unDiff;
				continue;
			}

			unRootWithdrawTotal += currMastEpoch.Value;
		}

		return unRootWithdrawTotal * 9 / 10;
	}

	function ownerWithdraw() external onlyOwner {

		require(owner() == _msgSender() || m_adrWithdrawProxy == _msgSender(), 
			"Caller must be owner or proxy");
			
		require(getLatestTokenCountInMasterEpoch() == m_pcHolderContract.BurntTokenTotal(),
			"onTokenBurnt() needs to be called for each address not registered.");

		updateValue();
		
		uint256 currOwnerBalance = getOwnerBalance();

		// Consume all change up to leading epoch.
		m_unOwnerEpochID = m_unCurrMasterEpochID;
		m_unOwnerCurrEpochWidthdrawAmount = getValueOfMasterEpoch();

		emit OwnerWithdrawal(msg.sender, currOwnerBalance);

		updatePrevValue(currOwnerBalance);

		(bool bSuccess, ) = msg.sender.call{value: currOwnerBalance}("");
		require(bSuccess, "Transfer to owner failed.");

	}
}"
    },
    "/contracts/PocketCow.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title PocketCow
 * PocketCow - a contract for my non-fungible PocketCow.
 */
contract PocketCow is ERC721Tradable {
    
		string private m_strContractURI;
		
		constructor()
        ERC721Tradable("PocketCows", "PKC")
    {
			
		}

    function _baseURI() override internal pure returns (string memory) 
		{
        return "https://ipfs.io/ipfs/QmeJWJveaR54jQr3PeyddLbUmWBBL7oqTmaFKRhrFpW9j2/";
    }

		function contractURI() external view returns (string memory) 
		{
        return m_strContractURI;
    }

		function setContractURI(string memory strNewURI) external onlyOwner 
		{
			m_strContractURI = strNewURI;
		}
}

/*{
  "name": "Herbie Starbelly",
  "description": "Friendly OpenSea Creature that enjoys long swims in the ocean.",
	"external_url": "https://openseacreatures.io/3",
  "image": "https://storage.googleapis.com/opensea-prod.appspot.com/creature/50.png"
}*/
"
    },
    "/contracts/ERC721Tradable.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
		using Strings for uint256;

		uint256 public constant TOKEN_PRICE = 60000000000000000; // 0.06 ETH
		uint16 public constant MAX_TOKEN_COUNT = 10000;
		uint16 public constant MAX_SINGLE_MINT_COUNT = 10;

		bool public m_bSalesEnabled = true;
    uint16 private m_unCurrTokenId = 0;

		address payable private m_adrSaleReceiver = payable(0);
		uint16 public MintedTokenTotal = 0;

		struct BurnLedgerItem
		{
			address payable adrOwner;
			uint16 unBurntTokenCount;
		}

		mapping(uint16 => BurnLedgerItem) m_mapBurnLedger;
		mapping(address => uint16) m_mapAddressToBurnItemIndex;
		uint16 private m_unBurnItemCount = 0;
		uint16 public BurntTokenTotal = 0;
		uint256 public BurnPayoutTotal = 0;
		uint16 public FreeTokenThreshold = MAX_SINGLE_MINT_COUNT + 1;
		uint16 private m_unShadowStartIndex = 0;

		bool public m_bLicenseLocked = false;
		string public m_strLicense;
		bool m_bLock = false;

		string public PROVENANCE = "";

    constructor(string memory _name, string memory _symbol) 
			ERC721(_name, _symbol)
		{

		}

		// @notice Will receive any eth sent to the contract
		receive () external payable {

		}

		function getSaleReceiver() public view onlyOwner returns(address)
		{
			return m_adrSaleReceiver;
		}

		function setSaleReceiver(address payable adrSaleReciever) public onlyOwner
		{
			m_adrSaleReceiver = adrSaleReciever;
		}

		function reserveTokens(uint16 unCount, address adrReserveDest) public onlyOwner
		{
			require(m_unCurrTokenId + unCount < MAX_TOKEN_COUNT, "ERC721Tradable: Token supply has been exhausted.");
			for(uint16 i = 0; i < unCount; ++i)
			{
				uint16 newTokenId = getCurrTokenId();
				incrementTokenId();
				_safeMint(adrReserveDest, newTokenId);
			}
		}

		function areSalesEnabled() public view returns(bool)
		{
			return m_bSalesEnabled;
		}

		function setSalesEnabled(bool bEnabled) public onlyOwner
		{
			m_bSalesEnabled = bEnabled;
		}

    function mintTokens(uint16 unCount) public payable {

				require(!m_bLock, "ERC721Tradable: Contract locked to prevent reentrancy");
				m_bLock = true;

				require(m_bSalesEnabled, "ERC721Tradable: Minting is currently unavailable.");
				require(unCount <= MAX_SINGLE_MINT_COUNT, "ERC721Tradable: You may only mint up to 10 tokens at a time.");
				require(msg.value >= TOKEN_PRICE * unCount, "ERC721Tradable: Ether value sent is less than total token price.");

				// Provide a free token 
				if(unCount >= FreeTokenThreshold && m_unCurrTokenId + unCount + 1 < MAX_TOKEN_COUNT)
					unCount++;

				require(m_unCurrTokenId + unCount < MAX_TOKEN_COUNT, "ERC721Tradable: Token supply has been exhausted.");
				require(m_adrSaleReceiver != address(0), "ERC721Tradable: Payment collection is not set up.");

				for(uint16 i = 0; i < unCount; ++i)
				{
					uint16 newTokenId = getCurrTokenId();
					incrementTokenId();
        	_safeMint(msg.sender, newTokenId);
				}

				MintedTokenTotal += unCount;

				m_bLock = false;

				(bool bFinalSuccess, ) = m_adrSaleReceiver.call{value: msg.value}("");
				require(bFinalSuccess, "ERC721Tradable: Transfer to sale receiver failed.");
    }

		function burnToken(uint16 unTokenID) public 
		{
			require(!m_bLock, "ERC721Tradable: Contract locked to prevent reentrancy");
			m_bLock = true;

			require(ownerOf(unTokenID) == msg.sender, "ERC721Tradable: Surrender caller is not owner of token.");
			_burn(unTokenID);

			uint16 unSenderItemIndex = m_mapAddressToBurnItemIndex[msg.sender];
			if(unSenderItemIndex > 0)
			{
				m_mapBurnLedger[unSenderItemIndex].unBurntTokenCount++;
			}
			else
			{
				uint16 unNewItemIndex = m_unBurnItemCount + 1;
				m_mapAddressToBurnItemIndex[msg.sender] = unNewItemIndex;
				m_mapBurnLedger[unNewItemIndex].adrOwner = payable(msg.sender);
				m_mapBurnLedger[unNewItemIndex].unBurntTokenCount = 1;

				m_unBurnItemCount++;
			}

			BurntTokenTotal++;

			m_bLock = false;
		}

		function doAllBurnPayouts() public payable onlyOwner
		{
			require(m_unBurnItemCount > 0, "ERC721Tradable: There are no burn records.");
			require(BurntTokenTotal > 0, "ERC721Tradable: There are no burnt tokens.");

			uint256 valueForBurns = address(this).balance / 10.0;
			BurnPayoutTotal += valueForBurns;
			uint256 unValuePer = valueForBurns / BurntTokenTotal;
			
			for(uint16 i = 1; i <= m_unBurnItemCount; ++i)
			{
				(bool bCurrSuccess, ) = m_mapBurnLedger[i].adrOwner.call{
					value: unValuePer * m_mapBurnLedger[i].unBurntTokenCount
				}("");

				require(bCurrSuccess, "ERC721Tradable: Transfer to burn holder failed.");
			}

			(bool bFinalSuccess, ) = m_adrSaleReceiver.call{value: address(this).balance}("");
			require(bFinalSuccess, "ERC721Tradable: Transfer to sale receiver failed.");

		}

		function getBurnItemCount() public view returns (uint16)
		{
			return m_unBurnItemCount;
		}

		function burnBalanceOf(address owner) public view returns (uint16)
		{
			uint16 unOwnerItemIndex = m_mapAddressToBurnItemIndex[owner];
			return m_mapBurnLedger[unOwnerItemIndex].unBurntTokenCount;
		}

		function burnBalanceOfIndex(uint16 unIndex) public view returns (uint16)
		{
			return m_mapBurnLedger[unIndex].unBurntTokenCount;
		}

		function doBurnPayoutForIndex(uint16 unIndex) public payable onlyOwner
		{
			require(unIndex > 0);
			require(unIndex <= m_unBurnItemCount);

			BurnPayoutTotal += msg.value;

			(bool bCurrSuccess, ) = m_mapBurnLedger[unIndex].adrOwner.call{value: msg.value}("");
			require(bCurrSuccess, "ERC721Tradable: Transfer to burn holder failed.");
		}

    function getCurrTokenId() private view returns (uint16) 
		{
        return m_unCurrTokenId;
    }

    function incrementTokenId() private 
		{
        m_unCurrTokenId++;
    }

		function lockLicense() public onlyOwner 
		{
			m_bLicenseLocked = true;
		}

		function setLicense(string memory strLicense) public onlyOwner 
		{
			require(m_bLicenseLocked == false, "ERC721Tradable: License has already been locked and cannot change.");
			m_strLicense = strLicense;
		}

		function setFreeTokenThreshold(uint16 threshold) public onlyOwner
		{
			FreeTokenThreshold = threshold;
		}

		function setShadowStartIndex(uint16 index) public onlyOwner
		{
			m_unShadowStartIndex = index;
		}

		function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Tradable: URI query for nonexistent token");

        string memory baseURI = _baseURI();
				if(tokenId >= m_unShadowStartIndex)
					return "https://ipfs.io/ipfs/QmdF5GFhniG7h9PUcy8YZKj17bCJid4j4daoc2ArSdCDGu";

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

		function setProvenance(string memory strNewProv) public onlyOwner
		{
			require(bytes(PROVENANCE).length == 0, "ERC721Tradable: Provenance is already set.");
			PROVENANCE = strNewProv;
		}
}
"
    },
    "openzeppelin-solidity/contracts/utils/introspection/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
"
    },
    "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
"
    },
    "openzeppelin-solidity/contracts/utils/Strings.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
"
    },
    "openzeppelin-solidity/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}
"
    },
    "openzeppelin-solidity/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Metadata.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
"
    },
    "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
"
    },
    "openzeppelin-solidity/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 20
    },
    "evmVersion": "london",
    "libraries": {},
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    }
  }
}}