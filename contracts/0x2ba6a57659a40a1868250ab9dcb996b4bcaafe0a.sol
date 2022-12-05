{"ClaimRewards.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./EIP712.sol";
import "./IDEXRouter.sol";

/**
 * @title ClaimRewards smart contract.
 */
contract ClaimRewards is EIP712, Ownable, ReentrancyGuard {
  /// @notice _BATCH_TYPE type hash of the Batch struct
  bytes32 private constant _BATCH_TYPE = keccak256("Batch(uint256 batchId,uint256 issuedTimestamp)");
  /// @notice _BATCH_TYPE type hash of the Ticket struct
  bytes32 private constant _TICKET_TYPE = keccak256("Ticket(uint8 rewardType,address tokenAddress,uint256 amount,address claimerAddress,uint256 ticketId,bytes32 batchProofSignature)");

  uint256 public maxTicketsPerBatch = 1_000_000;
  uint256 public minCharityDonationPercent = 15;
  uint256 public maxCharityDonationPercent = 100;

  // @notice duration since the issued date of a batch in a ticket that a user can convert ETH to reward tokens
  uint256 public durationToConvertETHToTokens = 5 days;

  // @notice the charity address that a user can distribute some proportion of claim rewards to
  address public charityAddress;
  // @notice the signer that signed the batchProofSignature
  address public batchSigner;
  // @notice the signer that signed the ticketProofSignature
  address public ticketSigner;

  // @notice total ETH claimed amount
  uint256 public totalETHClaimedAmount;
  // @notice total ETH donate amount
  uint256 public totalETHDonatedAmount;
  // @notice total ERC20 token claimed amount
  mapping(address => uint256) public totalERC20ClaimedAmount;
  // @notice total ERC20 token donated amount
  mapping(address => uint256) public totalERC20DonatedAmount;

  // @notice router address of the DEX
  IDEXRouter public dexRouter;

  constructor(
    string memory contractName,
    string memory contractVersion,
    address _dexRouter,
    address _charityAddress
  ) EIP712(contractName, contractVersion) {
    dexRouter = IDEXRouter(_dexRouter);
    charityAddress = _charityAddress;
  }

  // @notice RewardType
  // ETH - reward in Ethers
  // ERC20 - reward in ERC20 tokens
  enum RewardType {
    ETH,
    ERC20
  }

  // @notice Batch will contain multiple tickets
  struct Batch {
    uint256 batchId;
    // issuedTimestamp: the date that the batch was issued
    uint256 issuedTimestamp;
  }

  // @notice Ticket is a proof that you are eligible to claim the rewards
  // each Ticket must belong to a batch and must include a valid batch signature as well as a valid ticket signature
  struct Ticket {
    uint8 rewardType;
    // tokenAddress is the reward token that a user will receive if the rewardType is ERC20
    address tokenAddress;
    uint256 amount;
    address claimerAddress;
    uint256 ticketId;
    Batch batch;
    bytes batchProofSignature;
    bytes ticketProofSignature;
  }

  // @notice isTicketClaimed tracks if a ticket has been claimed or not
  mapping(uint256 => bool) public isTicketClaimed;

  // @notice _hashBatch compute the hash of the provided batch
  function _hashBatch(Batch calldata batch) private pure returns (bytes32) {
    return keccak256(abi.encode(_BATCH_TYPE, batch.batchId, batch.issuedTimestamp));
  }

  // @notice _hashTicket compute the hash of the provided ticket
  function _hashTicket(Ticket calldata ticket) private pure returns (bytes32) {
    return keccak256(abi.encode(_TICKET_TYPE, ticket.rewardType, ticket.tokenAddress, ticket.amount, ticket.claimerAddress, ticket.ticketId, keccak256(ticket.batchProofSignature)));
  }

  // @notice setDexRouter - owner can set the dex router address
  function setDexRouter(address router) external onlyOwner {
    dexRouter = IDEXRouter(router);
  }

  // @notice setCharityAddress - owner can set the charityAddress
  function setCharityAddress(address address_) external onlyOwner {
    charityAddress = address_;
  }

  // @notice setBatchSignerAddress - set the batch signer address
  function setBatchSignerAddress(address signer) external onlyOwner {
    batchSigner = signer;
  }

  // @notice setTicketSignerAddress - set the ticket signer address
  function setTicketSignerAddress(address signer) external onlyOwner {
    ticketSigner = signer;
  }

  // @notice setSigners - set batch signer and ticket signer
  function setSigners(address _batchSigner, address _ticketSigner) external onlyOwner {
    batchSigner = _batchSigner;
    ticketSigner = _ticketSigner;
  }

  /*
   * @notice setParams for the contract
   * @param _maxTicketsPerBatch The maximum number of tickets per batch
   * @param _minCharityDonationPercent The minimum percentage of the reward that a user must donate
   * @param _maxCharityDonationPercent The minimum percentage of the reward that a user must donate
   * @param _durationToConvertETHToTokensInSeconds Duration in seconds that a user can convert ETH reward to the desired tokens
   */
  function setParams(
    uint256 _maxTicketsPerBatch,
    uint256 _minCharityDonationPercent,
    uint256 _maxCharityDonationPercent,
    uint256 _durationToConvertETHToTokensInSeconds
  ) external onlyOwner {
    maxTicketsPerBatch = _maxTicketsPerBatch;
    minCharityDonationPercent = _minCharityDonationPercent;
    maxCharityDonationPercent = _maxCharityDonationPercent;
    durationToConvertETHToTokens = _durationToConvertETHToTokensInSeconds;
  }

  // @notice getBatchIdOfTicket calculate the batchId given ticketId
  function getBatchIdOfTicket(uint256 ticketId) private view returns (uint256) {
    return ticketId - (ticketId % maxTicketsPerBatch);
  }

  // @notice _validateDonationPercent validate if the donation percentage of the reward is valid
  function _validateDonationPercent(uint256 percent) private view {
    require(percent >= minCharityDonationPercent && percent <= maxCharityDonationPercent, "INVALID_CHARITY_DONATION_PERCENT");
  }

  // @notice _convertETHToTokenAmount calculate the expected token amount if a user decided to convert ETH reward to the desired tokens
  function _convertETHToTokenAmount(uint256 amountETH, address tokenAddress) private view returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = dexRouter.WETH();
    path[1] = tokenAddress;
    uint256[] memory amounts = dexRouter.getAmountsOut(amountETH, path);
    return amounts[1];
  }

  // @notice _swapTokensForETH swap reward tokens for ETH
  function _swapTokensForETH(address tokenAddress, uint256 tokenAmount) internal returns (uint256) {
    uint256 balanceBefore = address(this).balance;
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = dexRouter.WETH();

    if (IERC20(tokenAddress).allowance(address(this), address(dexRouter)) < tokenAmount) {
      IERC20(tokenAddress).approve(address(dexRouter), type(uint256).max);
    }

    dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    uint256 amountETH = address(this).balance - balanceBefore;
    return amountETH;
  }

  // @notice _validateTicket validate if a ticket is valid
  function _validateTicket(Ticket calldata ticket, RewardType expectedRewardType) private view {
    require(!isTicketClaimed[ticket.ticketId], "ALREADY_CLAIMED");
    require(RewardType(ticket.rewardType) == expectedRewardType, "INVALID_REWARD_TYPE");
    require(_isValidSignature(_hashBatch(ticket.batch), ticket.batchProofSignature, batchSigner), "INVALID_BATCH_SIGNATURE");
    require(_isValidSignature(_hashTicket(ticket), ticket.ticketProofSignature, ticketSigner), "INVALID_TICKET_SIGNATURE");
    require(ticket.batch.batchId == getBatchIdOfTicket(ticket.ticketId), "MISMATCHED_TICKET_ID");
    require(ticket.claimerAddress == msg.sender, "CALLER_ADDRESS_MUST_MATCH_CLAIMER_ADDRESS");
  }

  /*
   * @notice claim ETH reward by providing tickets
   * @param tickets The array of ticket struct, any tickets must contain a batchProofSignature and a ticketProofSignature
   * @param charityDonationPercent percent of the rewards that the caller want to donate to charity
   * @param shouldConvertToToken a user can choose to convert ETH rewards to a desired tokens as long as
   */
  function claimETH(
    Ticket[] calldata tickets,
    uint256 charityDonationPercent,
    bool shouldConvertToToken,
    address tokenAddress
  ) external nonReentrant {
    require(tickets.length != 0, "NO_TICKET_TO_PROCESS");
    _validateDonationPercent(charityDonationPercent);

    uint256 totalETHForClaimAmount;
    for (uint256 i; i < tickets.length; i++) {
      _validateTicket(tickets[i], RewardType.ETH);
      totalETHForClaimAmount += tickets[i].amount;
      isTicketClaimed[tickets[i].ticketId] = true;
    }

    require(totalETHForClaimAmount > 0, "INVALID_REWARD_AMOUNT");

    uint256 charityAmount = (totalETHForClaimAmount * charityDonationPercent) / 100;
    _safeTransferETH(charityAddress, charityAmount);
    totalETHForClaimAmount -= charityAmount;

    uint256 convertDeadline = tickets[0].batch.issuedTimestamp + durationToConvertETHToTokens;
    if (shouldConvertToToken && block.timestamp <= convertDeadline) {
      uint256 tokenAmount = _convertETHToTokenAmount(totalETHForClaimAmount, tokenAddress);
      require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "FAILED_TO_TRANSFER_TOKENS");
      totalERC20ClaimedAmount[tokenAddress] += tokenAmount;
    } else {
      _safeTransferETH(msg.sender, totalETHForClaimAmount);
      totalETHClaimedAmount += totalETHForClaimAmount;
    }

    totalETHDonatedAmount += charityAmount;
  }

  /*
   * @notice claim ERC20 reward tokens by providing tickets
   * @param tickets The array of ticket struct, any tickets must contain a batchProofSignature and a ticketProofSignature
   * @param charityDonationPercent percent of the rewards that the caller want to donate to charity
   */
  function claimERC20(
    Ticket[] calldata tickets,
    uint256 charityDonationPercent,
    bool shouldSwapRewardTokenToETH
  ) external nonReentrant {
    require(tickets.length != 0, "NO_TICKET_TO_PROCESS");
    _validateDonationPercent(charityDonationPercent);

    address tokenAddress = tickets[0].tokenAddress;
    require(tokenAddress != address(0), "MUST_BE_A_VALID_TOKEN_ADDRESS");

    uint256 tokenForClaimAmount;
    for (uint256 i; i < tickets.length; i++) {
      _validateTicket(tickets[i], RewardType.ERC20);
      require(tickets[i].tokenAddress == tokenAddress, "ALL_TICKETS_MUST_HAVE_SAME_TOKEN_ADDRESS");

      tokenForClaimAmount += tickets[i].amount;
      isTicketClaimed[tickets[i].ticketId] = true;
    }

    require(tokenForClaimAmount > 0, "INVALID_REWARD_AMOUNT");

    uint256 charityAmount = (tokenForClaimAmount * charityDonationPercent) / 100;
    if (shouldSwapRewardTokenToETH) {
      uint256 amountETHForClaim = _swapTokensForETH(tokenAddress, tokenForClaimAmount);
      uint256 charityAmountETH = (amountETHForClaim * charityDonationPercent) / 100;
      if (charityAmountETH > 0) {
        _safeTransferETH(charityAddress, charityAmountETH);
        amountETHForClaim = amountETHForClaim - charityAmountETH;
      }

      _safeTransferETH(msg.sender, amountETHForClaim);
      tokenForClaimAmount -= charityAmount;
    } else {
      require(IERC20(tokenAddress).transfer(charityAddress, charityAmount), "FAILED_TO_TRANSFER_TOKENS");
      tokenForClaimAmount -= charityAmount;
      require(IERC20(tokenAddress).transfer(msg.sender, tokenForClaimAmount), "FAILED_TO_TRANSFER_TOKENS");
    }

    totalERC20ClaimedAmount[tokenAddress] += tokenForClaimAmount;
    totalERC20DonatedAmount[tokenAddress] += charityAmount;
  }

  // @notice _safeTransferETH to a destination address
  function _safeTransferETH(address to, uint256 value) internal {
    require(address(this).balance >= value, "INSUFFICIENT_BALANCE");
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "SafeTransferETH: ETH transfer failed");
  }

  // @notice withdraw all ETH amount in the contract
  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // @notice withdraw all stuck ERC20 tokens in the contract
  function withdrawErc20(IERC20 token) external onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  receive() external payable {}
}
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT
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
"},"ECDSA.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n Ã· 2 + 1, and for v in (302): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
"},"EIP712.sol":{"content":"//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./ECDSA.sol";

contract EIP712 {
  using ECDSA for bytes32;

  // Domain Separator is the EIP-712 defined structure that defines what contract
  // and chain these signatures can be used for.  This ensures people can't take
  // a signature used to mint on one contract and use it for another, or a signature
  // from testnet to replay on mainnet.
  // It has to be created in the constructor so we can dynamically grab the chainId.
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
  bytes32 public DOMAIN_SEPARATOR;

  // The typehash for the data type specified in the structured data
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
  // This should match whats in the client side whitelist signing code
  // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L22

  constructor(string memory name, string memory version) {
    // This should match whats in the client side whitelist signing code
    // https://github.com/msfeldstein/EIP712-whitelisting/blob/main/test/signWhitelist.ts#L12
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        // This should match the domain you set in your client side signing.
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        block.chainid,
        address(this)
      )
    );
  }

  function _isValidSignature(
    bytes32 structHash,
    bytes calldata signature,
    address expectedSigner
  ) internal view returns (bool) {
    if (expectedSigner == address(0)) {
      return false;
    }

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    address recoveredAddress = digest.recover(signature);
    return recoveredAddress == expectedSigner;
  }
}
"},"IDEXRouter.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IDEXRouter {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
}
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
"},"Strings.sol":{"content":"// SPDX-License-Identifier: MIT
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
"}}