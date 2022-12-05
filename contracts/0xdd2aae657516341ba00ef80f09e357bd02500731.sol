{{
  "language": "Solidity",
  "sources": {
    "SudoGate.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

// common OZ intefaces
import {IERC165} from "IERC165.sol";
import {IERC721} from "IERC721.sol";
import {IERC721Enumerable} from "IERC721Enumerable.sol";
import {IERC721Receiver} from "IERC721Receiver.sol";

// sudoswap interfaces
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";
import {LSSVMPair, CurveErrorCodes} from "LSSVMPair.sol";

// make sure that SudoRug and SudoGate agree on the interface to this contract
import {ISudoGate02} from "ISudoGate02.sol";
import {ISudoGatePoolSource} from "ISudoGatePoolSource.sol";

contract SudoGate is ISudoGate02, IERC721Receiver {
    address public owner; 

    address private SUDO_PAIR_FACTORY_ADDRESS = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;

    uint256 public minBalanceForTransfer = 0.1 ether;
    uint256 public contributorFeePerThousand = 2;
    uint256 public protocolFeePerThousand = 1;
    uint256 public defaultSlippagePerThousand = 20;

    address payable public protocolFeeAddress;

    /* 
    to avoid transferring eth on every small fee, 
    keep track of balances in this mapping and then 
    send eth in larger batches 
    */
    mapping (address => uint256) public balances;
    uint256 public totalBalance = 0;


    // mapping from NFT addresses to array of known pools
    mapping (address => address[]) public pools;

    mapping (address => bool) public knownPool;

    // who contributed each pool
    mapping (address => address) public poolContributors;

    constructor() { 
        owner = msg.sender; 
        protocolFeeAddress = payable(msg.sender);
    }
    
    function setPairFactoryAddress(address addr) public {
        require(msg.sender == owner, "Only owner allowed to call setPairFactoryAddress");
        SUDO_PAIR_FACTORY_ADDRESS = addr;
    }

    function setProtocolFeeAddress(address payable addr) public {
        require(msg.sender == owner, "Only owner allowed to call setProtocolFeeAddress");
        protocolFeeAddress = addr;
    }
    
    function setProtocolFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to protocol
            for every transaction
        */
        require(msg.sender == owner, "Only owner allowed to call setProtocolFee");
        protocolFeePerThousand = fee;
    }

    function setContributorFee(uint256 fee) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setContributorFee");
        contributorFeePerThousand = fee;
    }

    function setMinBalanceForTransfer(uint256 minVal) public {
        /* 
            set fee (in 1/10th of a percent) which gets sent to whoever 
            contributed the pool address to SudoGate
        */
        require(msg.sender == owner, "Only owner allowed to call setMinBalanceForTransfer");
        minBalanceForTransfer = minVal;
    }

    function setDefaultSlippage(uint256 slippagePerThousand) public {
        /* 
        controls the price fudge factor used to make sure we send enough ETH to sudoswap 
        even if our price computation doesn't quite agree with theirs
        */ 
        require(msg.sender == owner, "Only owner allowed to call setDefaultSlippage");
        defaultSlippagePerThousand = slippagePerThousand;
    }
    

    function totalFeesPerThousand() public view returns (uint256) {
        return protocolFeePerThousand + contributorFeePerThousand;
    }

    function isSudoSwapPool(address sudoswapPool) public view returns (bool) {
        return (
            ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH) ||
            ILSSVMPairFactoryLike(SUDO_PAIR_FACTORY_ADDRESS).isPair(sudoswapPool, ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH)
        );
    }

    function registerPool(address sudoswapPool) public returns (bool) {
        require(!knownPool[sudoswapPool], "Pool already known");
        require(isSudoSwapPool(sudoswapPool), "Not a valid sudoswap pool");
        knownPool[sudoswapPool] = true;
        poolContributors[sudoswapPool] = msg.sender;
        address nft = address(LSSVMPair(sudoswapPool).nft());
        pools[nft].push(sudoswapPool); 
        return true;
    }


    function calcFeesAndSlippage(uint256 price, uint256 slippagePerThousand) internal view returns (
            uint256 protocolFee, 
            uint256 contributorFee,
            uint256 slippage) {
        require(contributorFeePerThousand <= 1000, "contributorFeePerThousand must be between 0 and 1000");
        require(protocolFeePerThousand <= 1000, "protocolFeePerThousand must be between 0 and 1000");
        require(slippagePerThousand <= 1000, "slippagePerThousand must be between 0 and 1000");
        
        // first scale everything up by a thousand so we get a little more fixed point precision
        uint256 priceX1000 = price * 1000; 
        require(priceX1000 > price, "Overflow in rescaled price");

        // if price is 1000x bigger and fees are per-thousand 
        // then need to divide by 1M to get something proportional to original price
        uint256 denom = 10 ** 6; 

        contributorFee = priceX1000 * contributorFeePerThousand / denom;
        require(contributorFee < price, "Contributor fee should be less than price");

        protocolFee = priceX1000 * protocolFeePerThousand / denom; 
        require(protocolFee < price, "Protocol fee should be less than price");
       
        if (slippagePerThousand > 0) {
            slippage = priceX1000 * slippagePerThousand / denom;
            require (slippage < price, "Slippage cannot be greater than 100%");
        } else {
            slippage = 0;
        }
        
    }

    function calcFees(uint256 price) internal view returns (
            uint256 protocolFee, 
            uint256 contributorFee) {
        (protocolFee, contributorFee, ) = calcFeesAndSlippage(price, 0);
    } 


    function adjustBuyPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        uint256 protocolFee;
        uint256 contributorFee;
        uint256 slippage;
        (protocolFee, contributorFee, slippage) = calcFeesAndSlippage(price, slippagePerThousand);
        uint256 combinedAdjustment = protocolFee + contributorFee + slippage; 
        require(combinedAdjustment < price, "Fees + slippage cannot exceed 100%");
        adjustedPrice =  price + combinedAdjustment; 
    }
    
    function adjustSellPrice(uint256 price, uint256 slippagePerThousand) public view returns (uint256 adjustedPrice) {
        uint256 protocolFee;
        uint256 contributorFee;
        uint256 slippage;
        (protocolFee, contributorFee, slippage) = calcFeesAndSlippage(price, slippagePerThousand);
        uint256 combinedAdjustment = protocolFee + contributorFee + slippage; 
        require(combinedAdjustment < price, "Fees + slippage cannot exceed 100%");
        adjustedPrice = price - combinedAdjustment; 
    }
    

    function addFee(address recipient, uint256 fee) internal {
        balances[recipient] += fee;
        totalBalance += fee;

        uint256 currentBalance = balances[recipient];
        if (currentBalance >= minBalanceForTransfer) {
            require(address(this).balance >= currentBalance, "Not enough ETH on contract");
            require(totalBalance >= currentBalance, "Don't lose track of how much ETH we have!");
            balances[recipient] = 0;
            totalBalance -= currentBalance;
            payable(recipient).transfer(currentBalance);
        }
    }

    function buyFromPool(address pool) public payable returns (uint256 tokenID) {
        /* returns token ID of purchased NFT */
        require(isSudoSwapPool(pool), "Not a valid sudoswap pool");
        IERC721 nft = LSSVMPair(pool).nft();
        require(nft.balanceOf(pool) > 0, "Pool has no NFTs");
        uint256[] memory tokenIDs = LSSVMPair(pool).getAllHeldIds();
        tokenID = tokenIDs[tokenIDs.length - 1];
        uint256 startingValue = msg.value; 
        uint256 maxProtocolFee;
        uint256 maxContributorFee;
        
        (maxProtocolFee, maxContributorFee) = calcFees(startingValue);
        uint256 maxAllowedSpend = startingValue - (maxContributorFee + maxProtocolFee);

        uint256 usedAmt = LSSVMPair(pool).swapTokenForAnyNFTs{value: maxAllowedSpend}(
            1, 
            maxAllowedSpend, 
            msg.sender, 
            false, 
            address(0));
        require(usedAmt < startingValue, "Can't use more ETH than was originally sent");
        require(usedAmt > 0, "There ain't no such thing as a free lunch");
        
        // compute actual fees based on what got spent by sudoswap
        uint256 contributorFee; 
        uint256 protocolFee; 
        (protocolFee, contributorFee) = calcFees(usedAmt);
        uint256 amtWithFees = usedAmt + (protocolFee + contributorFee);
        require(amtWithFees <= startingValue, "Can't spend more than we were originally sent");
        
        addFee(poolContributors[pool], contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        uint256 diff = startingValue - amtWithFees;
        // send back unused ETH
        if (diff > 0) { payable(msg.sender).transfer(diff); }
    }

    function buy(address nft) public payable returns (uint256 tokenID) {
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = buyQuote(nft);
        require(bestPool != address(0), "No pool found");
        require(bestPrice != type(uint256).max, "Invalid price");
        uint256 adjustedPrice = adjustBuyPrice(bestPrice, 5);
        require(adjustedPrice <= msg.value, "Not enough ETH for price of NFT");
        tokenID = buyFromPool(bestPool);
    }

    function buyQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Does not include SudoGate fees, see buyQuoteWithFees
        */
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;
        require(numPools > 0, "No pools registered for given NFT");

        CurveErrorCodes.Error err;
        uint256 inputAmount;
        bestPrice = type(uint256).max;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (LSSVMPair(poolAddr).poolType() == LSSVMPair.PoolType.TOKEN) {
                // pool only buys NFTs and can't actually sell them
            } if (IERC721(nft).balanceOf(poolAddr) == 0) {
                // check if pool actually has any NFTs
                continue;
            } else {
                (err, , , inputAmount, ) = LSSVMPair(poolAddr).getBuyNFTQuote(1);
                if (err == CurveErrorCodes.Error.OK) {
                    if (inputAmount < bestPrice) {
                        bestPool = poolAddr;
                        bestPrice = inputAmount;
                    }
                }
            }
        }
        require(bestPool != address(0), "Could not find a pool to buy from");
    }


    function buyQuoteWithFees(address nftAddr) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best price for an NFT and the pool to buy it from. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = buyQuote(nftAddr);
        // add a small slippage factor 
        bestPrice = adjustBuyPrice(bestPrice, defaultSlippagePerThousand);
    }

    function _moveToContract(address nftAddr, uint256 tokenId) internal {
        // move NFT to this contract in preparation for selling it
        IERC721 nftContract = IERC721(nftAddr);
        address currentOwner = nftContract.ownerOf(tokenId);
        if (currentOwner != address(this)) {
            require(
                currentOwner == msg.sender ||
                    nftContract.isApprovedForAll(currentOwner, msg.sender) ||
                    nftContract.getApproved(tokenId) == msg.sender,
                "Caller not approved to sell NFT");
            require(
                nftContract.isApprovedForAll(currentOwner, address(this)) ||
                    nftContract.getApproved(tokenId) == address(this),
                "SudoGate contract not approved to transfer the NFT");
            IERC721(nftAddr).safeTransferFrom(currentOwner, address(this), tokenId);
        }
    }

    function sellToPool(address nftAddr, uint256 tokenId, address sudoswapPool, uint256 minPrice) public returns (uint256 priceInWei, uint256 feesInWei) {
        /* 
        Sells NFT to specific pool.

        Returns:
            - uint256 priceInWei (amount of ETH returned to seller)
            - uint256 feesInWei (amount of ETH kept as SudoGate protocol + pool registration fees)
        
        Seller must approve the SudoGate contract for the given NFT before calling this function
        */
        require(sudoswapPool != address(0), "Zero address not a valid pool");
        require(isSudoSwapPool(sudoswapPool), "Given address is not a valid sudoswap pool");
        require(address(LSSVMPair(sudoswapPool).nft()) == nftAddr, "Pool for different NFT");
        LSSVMPair.PoolType poolType = LSSVMPair(sudoswapPool).poolType();
        require(poolType == LSSVMPair.PoolType.TOKEN || poolType == LSSVMPair.PoolType.TRADE, "Wrong pool type, not able to buy");
        require(sudoswapPool.balance >= minPrice, "Not enough ETH on sudoswap pool for desired price");
        
        // move the NFT to SudoGate
        _moveToContract(nftAddr, tokenId);

        // now that we have the NFT, we can approve sudoswap transferring it
        IERC721(nftAddr).approve(sudoswapPool, tokenId);

        priceInWei = 0;
        feesInWei = 0;

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = tokenId;
        uint256 outputAmount = LSSVMPair(sudoswapPool).swapNFTsForToken(
            nftIds,
            minPrice,
            payable(address(this)),
            false,
            address(0));

        require(outputAmount > 0, "Didn't get any ETH back");
        require(outputAmount > (minPrice / 2), "Sale price slippage greater than 50%");

        // compute actual fees based on what got sent by sudoswap
        
        uint256 contributorFee; 
        uint256 protocolFee;
        
        (protocolFee, contributorFee) = calcFees(outputAmount);
        
        addFee(poolContributors[sudoswapPool], contributorFee);
        addFee(protocolFeeAddress, protocolFee);
        
        feesInWei = protocolFee + contributorFee;
        require(feesInWei < outputAmount, "Fees can't exceed ETH received for selling");
        
        priceInWei = outputAmount - feesInWei;
        
        // send back ETH after fees
        if (priceInWei > 0) { 
            payable(msg.sender).transfer(priceInWei); 
        }
    }

    function sell(address nft, uint256 tokenId) public returns (bool success, uint256 priceInWei, uint256 feesInWei) {
        /* 
        Sells NFT at best price if there are any registered pools which will buy it.
        Returns:
            - bool success (true if sale happened)
            - uint256 priceInWei (amount of ETH returned to seller)
            - uint256 feesInWei (amount of ETH kept as SudoGate protocol + pool registration fees)
        
        Seller must approve the SudoGate contract for the given NFT before calling this function
        */
        uint256 bestPrice;
        address bestPool;
        (bestPrice, bestPool) = sellQuote(nft);

        success = false;
        priceInWei = 0;
        feesInWei = 0;
        if (bestPrice > 0 && bestPool != address(0)) {
            (priceInWei, feesInWei) = sellToPool(nft, tokenId, bestPool, bestPrice);
            require(IERC721(nft).ownerOf(tokenId) == bestPool, "Ended up with wrong NFT owner!");
            success = true;
        }
    }

    function sellQuote(address nft) public view returns (uint256 bestPrice, address bestPool) {
        address[] storage nftPools = pools[nft];
        uint256 numPools = nftPools.length;

        CurveErrorCodes.Error err;
        uint256 outputAmount;
        bestPrice = 0;
        bestPool = address(0);

        address poolAddr;
        uint256 i = 0;
        for (; i < numPools; ++i) {
            poolAddr = nftPools[i];
            if (LSSVMPair(poolAddr).poolType() == LSSVMPair.PoolType.NFT) {
                // pool only sells NFTs and can't buy
                continue;
            } else if (poolAddr.balance < bestPrice) {
                // check if pool actually has enough ETH to potentially give us a better price
                continue;
            } else {
                (err, , , outputAmount, ) = LSSVMPair(poolAddr).getSellNFTQuote(1);
                // make sure the pool has enough ETH to cover its own better offer
                if ((err == CurveErrorCodes.Error.OK) && 
                        (outputAmount > bestPrice) && 
                        (poolAddr.balance >= outputAmount)) { 
                    bestPool = poolAddr;
                    bestPrice = outputAmount;
                }
            }
        }
    }   

    
    function sellQuoteWithFees(address nft) public view returns (uint256 bestPrice, address bestPool) {
        /* 
        Returns best sell price for an NFT and the pool to sell it to. 
        Price is adjusted for SudoGate fees but assumes 0 slippage.
        */ 
        (bestPrice, bestPool) = sellQuote(nft);
        // include a small slippage factor  
        bestPrice = adjustSellPrice(bestPrice, defaultSlippagePerThousand);
    }

    
    // make it possible to receive ETH on this contract
    receive() external payable { }

    function rescueETH() public {
        // in case ETH gets trapped on this contract for some reason,
        // allow owner to manually withdraw it
        require(msg.sender == owner, "Only owner allowed to call rescueETH");
        require(address(this).balance >= totalBalance, "Not enough ETH on contract for balances");
        uint256 extraETH = address(this).balance - totalBalance;
        payable(owner).transfer(extraETH);
    }

    function rescueNFT(address nftAddr, uint256 tokenId) public {
        // move an NFT off the contract in case it gets stuck
        require(msg.sender == owner, "Only owner allowed to call rescueNFT");
        require(IERC721(nftAddr).ownerOf(tokenId) == address(this), 
            "SudoGate is not the owner of this NFT");
        IERC721(nftAddr).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdraw() public {
        // let contributors withdraw ETH if they have any on the contract
        uint256 balance = balances[msg.sender];
        require(balance < address(this).balance, "Not enough ETH on contract");
        balances[msg.sender] = 0;
        totalBalance -= balance;
        payable(msg.sender).transfer(balance);
    }

    // ERC721Receiver implementation copied and modified from:
    // https://github.com/GustasKlisauskas/ERC721Receiver/blob/master/ERC721Receiver.sol
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns(bytes4) {
        return this.onERC721Received.selector;
    }

 
}"
    },
    "IERC165.sol": {
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
    "IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    "IERC721Enumerable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
    "IERC721Receiver.sol": {
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
    "ILSSVMPairFactoryLike.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);
    /*
    function routerStatus(LSSVMRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);
    */

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}
"
    },
    "LSSVMPair.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC721} from "IERC721.sol";
import {ILSSVMPairFactoryLike} from "ILSSVMPairFactoryLike.sol";

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

interface LSSVMPair {

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function factory() external pure returns (ILSSVMPairFactoryLike);
    
    function nft() external pure returns (IERC721);
    
    function poolType() external pure returns (PoolType);
    
    function getBuyNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        );

    function getSellNFTQuote(uint256 numNFTs) external view returns (
            CurveErrorCodes.Error error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        );

      /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable  returns (uint256 inputAmount);

     function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function getAllHeldIds() external view returns (uint256[] memory);

    function owner() external view returns (address);
}
"
    },
    "ISudoGate02.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

import {ISudoGate01} from "ISudoGate01.sol";

interface ISudoGate02 is ISudoGate01 { 
    // v2 API extends v1 with selling
    function sellQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function sellQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    
    function sell(address nft, uint256 tokenId) external returns (bool success, uint256 priceInWei, uint256 feesInWei);
    function sellToPool(address nft, uint256 tokenId, address sudoswapPool, uint256 minPrice) external returns (uint256 priceInWei, uint256 feesInWei);
}"
    },
    "ISudoGate01.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

import {ISudoGatePoolSource} from "ISudoGatePoolSource.sol";

interface ISudoGate01 is ISudoGatePoolSource { 
    // In addition to ISudoGatePoolSource's tracking of pools, the v1 API allows buying
    function buyQuote(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyQuoteWithFees(address nft) external view returns (uint256 bestPrice, address bestPool);
    function buyFromPool(address pool) external payable returns (uint256 tokenID);
}"
    },
    "ISudoGatePoolSource.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

interface ISudoGatePoolSource {
    // base interface that just tracks a collection of SudoSwap pools 
    function pools(address, uint256) external view returns (address);
    function knownPool(address) external view returns (bool);
    function registerPool(address sudoswapPool) external returns (bool);
}"
    }
  },
  "settings": {
    "evmVersion": "istanbul",
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "libraries": {
      "SudoGate.sol": {}
    },
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