{"Address.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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



"},"Context.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
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
        return msg.data;
    }
}
"},"DORToken.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract DORToken is ERC721Enumerable, ReentrancyGuard, Pausable, WhitelistAdminRole {
    using SafeMath for uint256;

    enum TokenType {
        NONE,
        SILVER, // 1. Mix & Match Silver Grade Daughter
        GOLD, // 2. Mix & Match Gold Grade Daughter
        RAINBOW, // 3. Mix & Match Rainbow Grade Daughter
        EBIBLE, // 4. Daughter E-bible
        RANDOM, // 5. NONE
        M3D, // 6. 3D Mother NFT
        AIRDROPS, // 7. Limited Daughter NFT
        SPARK, // 8. SPARK Token NFT
        DAUGHTER, // 9. daughters
        ALIEN, // 10. daughters of alien
        RARE, // 11. rare daughters
        MOTHER // 12. the mother
    }

    uint256 public salePrice = 0.05 ether;
    string private _baseTokenURI;
    mapping(uint256 => uint256) typeMapping;

    // params
    uint256 public SILVER_CLAIM_DAUGHTER_MIN_NUM = 5;
    uint256 public GOLD_CLAIM_DAUGHTER_MIN_NUM = 10;
    uint256 public RAINBOW_CLAIM_DAUGHTER_MIN_NUM = 20;

    // claim flags
    mapping(uint256 => bool) claimFlags; // claim flags for silver/gold/rainbow
    mapping(uint256 => bool) claim3DFlags; // claim flags for m3d
    mapping(uint256 => bool) claimEbibleFlags; // claim flags for ebible
    mapping(address => bool) claimAirdropsFlags; // claim flags for airdrops type
    mapping(address => bool) claimSparkFlags; // claim flags for spark type

    mapping(address => bool) whitelistAirdrops; // whitelist for AIRDROPS type
    mapping(address => bool) whitelistSpark; // whitelist for SPARK type

    ////////////////////////////////////////////////////
    // nft index
    ////////////////////////////////////////////////////
    // daughter index
    uint256 nextDaughterIndex = 1;
    uint256 daughterIndexMin = 1;
    uint256 daughterIndexMax = 999;
    // alien index
    uint256 nextAlienIndex = daughterIndexMax + 1;
    uint256 alienIndexMin = daughterIndexMax + 1;
    uint256 alienIndexMax = daughterIndexMax + 44;
    // silver index
    uint256 nextSilverIndex = alienIndexMax + 1;
    uint256 silverIndexMin = alienIndexMax + 1;
    uint256 silverIndexMax = alienIndexMax + 300;
    // gold index
    uint256 nextGoldIndex = silverIndexMax + 1;
    uint256 goldIndexMin = silverIndexMax + 1;
    uint256 goldIndexMax = silverIndexMax + 150;
    // rainbow index
    uint256 nextRainbowIndex = goldIndexMax + 1;
    uint256 rainbowIndexMin = goldIndexMax + 1;
    uint256 rainbowIndexMax = goldIndexMax + 50;
    // rare index
    uint256 nextRareIndex = rainbowIndexMax + 1;
    uint256 rareIndexMin = rainbowIndexMax + 1;
    uint256 rareIndexMax = rainbowIndexMax + 450;
    // ebible index
    uint256 nextEbibleIndex = rareIndexMax + 1;
    uint256 ebibleIndexMin = rareIndexMax + 1;
    uint256 ebibleIndexMax = rareIndexMax + 500;
    // mother index
    uint256 nextMotherIndex = ebibleIndexMax + 1;
    uint256 motherIndexMin = ebibleIndexMax + 1;
    uint256 motherIndexMax = ebibleIndexMax + 30;
    // m3d index
    uint256 nextM3dIndex = motherIndexMax + 1;
    uint256 m3dIndexMin = motherIndexMax + 1;
    uint256 m3dIndexMax = motherIndexMax + 30;
    // airdrop index
    uint256 nextAirdropsIndex = m3dIndexMax + 1;
    uint256 airdropsIndexMin = m3dIndexMax + 1;
    uint256 airdropsIndexMax = m3dIndexMax + 300;
    // spark index
    uint256 nextSparkIndex = airdropsIndexMax + 1;
    uint256 sparkIndexMin = airdropsIndexMax + 1;
    uint256 sparkIndexMax = airdropsIndexMax + 500;
    ////////////////////////////////////////////////////
    // nft index
    ////////////////////////////////////////////////////

    bool whitelistEnabled = true;  // whitelist switch, for pre-sale
    mapping(address => bool) whitelist; // whitelist for mint
    mapping (address => uint256) public whitelistMintCounts; // limit for pre-sale
    uint256 public whitelistMintMaxCount = 2;

    bool public sgrClaimEnabled; // silver/gold/rainbow switch
    bool public ebibleClaimEnabled; // ebible claim switch
    bool public m3dClaimEnabled;  // m3d claim switch

    /////////////////////////////////////////////////////
    // params
    function setWhitelistMintMaxCount(uint256 value) public onlyWhitelistAdmin {
        whitelistMintMaxCount = value;
    }

    function setSGREnabled(bool flag) public onlyWhitelistAdmin {
        sgrClaimEnabled = flag;
    }

    function setEbileEnabled(bool flag) public onlyWhitelistAdmin {
        ebibleClaimEnabled = flag;
    }

    function set3DEnabled(bool flag) public onlyWhitelistAdmin {
        m3dClaimEnabled = flag;
    }

    function setWhitelistEnabled(bool flag) public onlyWhitelistAdmin {
        whitelistEnabled = flag;
    }

    function setSalePrice(uint256 value) public onlyWhitelistAdmin {
        salePrice = value;
    }

    function setSilverClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        SILVER_CLAIM_DAUGHTER_MIN_NUM = value;
    }

    function setGoldClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        GOLD_CLAIM_DAUGHTER_MIN_NUM = value;
    }

    function setRainbowClaimDaughterMinNum(uint256 value) public onlyWhitelistAdmin {
        RAINBOW_CLAIM_DAUGHTER_MIN_NUM = value;
    }
    /////////////////////////////////////////////////////


    constructor() ERC721("Daughters of Rainbow", "DOR") {
        // _baseTokenURI = "ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/";
        // metadata: ipfs://QmaWSLDeJ3Urn47RX3fNEKcU4Tg7TXHpLy1t4t8z466AUP/<tokenId>.json
    }

    function getNextDaughterId() internal returns (uint256 id) {
        id = nextDaughterIndex;
        nextDaughterIndex = nextDaughterIndex.add(1);
    }

    function getNextAlienId() internal returns (uint256 id) {
        id = nextAlienIndex;
        nextAlienIndex = nextAlienIndex.add(1);
    }

    function getNextSilverId() internal returns (uint256 id) {
        id = nextSilverIndex;
        nextSilverIndex = nextSilverIndex.add(1);
    }

    function getNextGoldId() internal returns (uint256 id) {
        id = nextGoldIndex;
        nextGoldIndex = nextGoldIndex.add(1);
    }

    function getNextRainbowId() internal returns (uint256 id) {
        id = nextRainbowIndex;
        nextRainbowIndex = nextRainbowIndex.add(1);
    }

    function getNextRareId() internal returns (uint256 id) {
        id = nextRareIndex;
        nextRareIndex = nextRareIndex.add(1);
    }

    function getNextEbibleId() internal returns (uint256 id) {
        id = nextEbibleIndex;
        nextEbibleIndex = nextEbibleIndex.add(1);
    }

    function getNextMotherId() internal returns (uint256 id) {
        id = nextMotherIndex;
        nextMotherIndex = nextMotherIndex.add(1);
    }

    function getNextM3dId() internal returns (uint256 id) {
        id = nextM3dIndex;
        nextM3dIndex = nextM3dIndex.add(1);
    }

    function getNextAirdropsId() internal returns (uint256 id) {
        id = nextAirdropsIndex;
        nextAirdropsIndex = nextAirdropsIndex.add(1);
    }

    function getNextSparkId() internal returns (uint256 id) {
        id = nextSparkIndex;
        nextSparkIndex = nextSparkIndex.add(1);
    }

    //////////////////////////////////////////////////////////////
    // NFT type and count functions
    function daughterLeftover() public view returns (uint256) {
        if (nextDaughterIndex > daughterIndexMax) {
            return 0;
        }
        return daughterIndexMax.sub(nextDaughterIndex).add(1);
    }

    function getDaughterCount() public view returns (uint256) {
        return daughterCurrentCount();
    }

    function daughterCurrentCount() public view returns (uint256) {
        return nextDaughterIndex.sub(daughterIndexMin);
    }

    function alienLeftover() public view returns (uint256) {
        if (nextAlienIndex > alienIndexMax) {
            return 0;
        }
        return alienIndexMax.sub(nextAlienIndex).add(1);
    }

    function alienCurrentCount() public view returns (uint256) {
        return nextAlienIndex.sub(alienIndexMin);
    }

    function silverLeftover() public view returns (uint256) {
        if (nextSilverIndex > silverIndexMax) {
            return 0;
        }
        return silverIndexMax.sub(nextSilverIndex).add(1);
    }

    function silverCurrentCount() public view returns (uint256) {
        return nextSilverIndex.sub(silverIndexMin);
    }

    function goldLeftover() public view returns (uint256) {
        if (nextGoldIndex > goldIndexMax) {
            return 0;
        }
        return goldIndexMax.sub(nextGoldIndex).add(1);
    }

    function goldCurrentCount() public view returns (uint256) {
        return nextGoldIndex.sub(goldIndexMin);
    }

    function rainbowLeftover() public view returns (uint256) {
        if (nextRainbowIndex > rainbowIndexMax) {
            return 0;
        }
        return rainbowIndexMax.sub(nextRainbowIndex).add(1);
    }

    function rainbowCurrentCount() public view returns (uint256) {
        return nextRainbowIndex.sub(rainbowIndexMin);
    }

    function rareLeftover() public view returns (uint256) {
        if (nextRareIndex > rareIndexMax) {
            return 0;
        }
        return rareIndexMax.sub(nextRareIndex).add(1);
    }

    function rareCurrentCount() public view returns (uint256) {
        return nextRareIndex.sub(rareIndexMin);
    }

    function ebibleLeftover() public view returns (uint256) {
        if (nextEbibleIndex > ebibleIndexMax) {
            return 0;
        }
        return ebibleIndexMax.sub(nextEbibleIndex).add(1);
    }

    function ebibleCurrentCount() public view returns (uint256) {
        return nextEbibleIndex.sub(ebibleIndexMin);
    }

    function motherLeftover() public view returns (uint256) {
        if (nextMotherIndex > motherIndexMax) {
            return 0;
        }
        return motherIndexMax.sub(nextMotherIndex).add(1);
    }

    function motherCurrentCount() public view returns (uint256) {
        return nextMotherIndex.sub(motherIndexMin);
    }

    function m3dLeftover() public view returns (uint256) {
        if (nextM3dIndex > m3dIndexMax) {
            return 0;
        }
        return m3dIndexMax.sub(nextM3dIndex).add(1);
    }

    function m3dCurrentCount() public view returns (uint256) {
        return nextM3dIndex.sub(m3dIndexMin);
    }

    function airdropsLeftover() public view returns (uint256) {
        if (nextAirdropsIndex > airdropsIndexMax) {
            return 0;
        }
        return airdropsIndexMax.sub(nextAirdropsIndex).add(1);
    }

    function airdropsCurrentCount() public view returns (uint256) {
        return nextAirdropsIndex.sub(airdropsIndexMin);
    }

    function sparkLeftover() public view returns (uint256) {
        if (nextSparkIndex > sparkIndexMax) {
            return 0;
        }
        return sparkIndexMax.sub(nextSparkIndex).add(1);
    }

    function sparkCurrentCount() public view returns (uint256) {
        return nextSparkIndex.sub(sparkIndexMin);
    }
    //////////////////////////////////////////////////////////////


    //////////////////////////////////////////////////////////////
    // claim flags
    function setClaimFlag(uint256 tokenId, bool flag) internal {
        claimFlags[tokenId] = flag;
    }

    function setClaim3DFlag(uint256 tokenId, bool flag) internal {
        claim3DFlags[tokenId] = flag;
    }

    function setClaimEbibleFlag(uint256 tokenId, bool flag) internal {
        claimEbibleFlags[tokenId] = flag;
    }

    function setClaimAirdropsFlag(address account, bool flag) internal {
        claimAirdropsFlags[account] = flag;
    }

    function setClaimSparkFlag(address account, bool flag) internal {
        claimSparkFlags[account] = flag;
    }

    function getClaimFlag(uint256 tokenId) public view returns (bool) {
        return claimFlags[tokenId];
    }

    function getClaim3DFlag(uint256 tokenId) public view returns (bool) {
        return claim3DFlags[tokenId];
    }

    function getClaimEbibleFlag(uint256 tokenId) public view returns (bool) {
        return claimEbibleFlags[tokenId];
    }

    function getClaimAirdropsFlag(address account) public view returns (bool) {
        return claimAirdropsFlags[account];
    }

    function getClaimSparkFlag(address account) public view returns (bool) {
        return claimSparkFlags[account];
    }
    //////////////////////////////////////////////////////////////

    function addWhitelist(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function isWhitelist(address account) public view returns (bool) {
        return whitelist[account];
    }

    function addWhitelistAirdrops(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistAirdrops[accounts[i]] = true;
        }
    }

    function isWhitelistAirdrops(address account) public view returns (bool) {
        return whitelistAirdrops[account];
    }

    function addWhitelistSpark(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistSpark[accounts[i]] = true;
        }
    }

    function isWhitelistSpark(address account) public view returns (bool) {
        return whitelistSpark[account];
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseTokenURI) external onlyWhitelistAdmin {
        _baseTokenURI = baseTokenURI;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "!(owner|approved)");
        _burn(tokenId);
    }

    function getType(uint256 tokenId) public view returns (uint256) {
        return typeMapping[tokenId];
    }

    function getTokenTypes(uint256[] memory tokenIds) public view returns (uint256[] memory types) {
        types = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            types[i] = getType(tokenIds[i]);
        }
    }

    function setTokenType(uint256 tokenId, uint256 tp) public onlyWhitelistAdmin {
        setType(tokenId, tp);
    }

    function setType(uint256 tokenId, uint256 tp) internal {
        typeMapping[tokenId] = tp;
    }

    function _mintDaughter(address account, uint256 num) internal {
        require(nextDaughterIndex.add(num) <= daughterIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextDaughterId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.DAUGHTER));
        }
    }

    function _mintAlien(address account, uint256 num) internal {
        require(nextAlienIndex.add(num) <= alienIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextAlienId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.ALIEN));
        }
    }

    function claimSGR(uint256 tp) public {
        require(sgrClaimEnabled, "not start");

        address account = _msgSender();
        // check silver/gold/rainbow
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        uint256 daughterCount;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                daughterCount = daughterCount.add(1);
            }
        }

        uint256 cnt;
        if (tp == uint256(TokenType.RAINBOW)) {
            cnt = RAINBOW_CLAIM_DAUGHTER_MIN_NUM;
            require(rainbowLeftover() > 0, "no rainbow leftover");
        } else if (tp == uint256(TokenType.GOLD)) {
            cnt = GOLD_CLAIM_DAUGHTER_MIN_NUM;
            require(goldLeftover() > 0, "no gold leftover");
        } else if (tp == uint256(TokenType.SILVER)) {
            cnt = SILVER_CLAIM_DAUGHTER_MIN_NUM;
            require(silverLeftover() > 0, "no silver leftover");
        } else {
            require(false, "type error");
        }
        require(daughterCount >= cnt, "can't claim SGR");
        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length && cnt > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                setClaimFlag(tokenIds[i], true);
                cnt = cnt.sub(1);
            }
        }

        // mint
        if (tp == uint256(TokenType.RAINBOW)) {
            _mintRainbow(account, 1);
        } else if (tp == uint256(TokenType.GOLD)) {
            _mintGold(account, 1);
        } else if (tp == uint256(TokenType.SILVER)) {
            _mintSilver(account, 1);
        }
    }

    function _mintSilver(address account, uint256 num) internal {
        require(nextSilverIndex.add(num) <= silverIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextSilverId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.SILVER));
        }
    }

    function _mintGold(address account, uint256 num) internal {
        require(nextGoldIndex.add(num) <= goldIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextGoldId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.GOLD));
        }
    }

    function _mintRainbow(address account, uint256 num) internal {
        require(nextRainbowIndex.add(num) <= rainbowIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextRainbowId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.RAINBOW));
        }
    }

    function _mintRare(address account, uint256 num) internal {
        require(nextRareIndex.add(num) <= rareIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextRareId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.RARE));
        }
    }

    function _mintEbible(address account, uint256 num) internal {
        require(nextEbibleIndex.add(num) <= ebibleIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextEbibleId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.EBIBLE));
        }
    }

    function _mintMother(address account, uint256 num) internal {
        require(nextMotherIndex.add(num) <= motherIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextMotherId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.MOTHER));
        }
    }

    function _mintM3d(address account, uint256 num) internal {
        require(nextM3dIndex.add(num) <= m3dIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextM3dId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.M3D));
        }
    }

    function _mintAirdrops(address account, uint256 num) internal {
        require(nextAirdropsIndex.add(num) <= airdropsIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextAirdropsId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.AIRDROPS));
        }
    }

    function _mintSpark(address account, uint256 num) internal {
        require(nextSparkIndex.add(num) <= sparkIndexMax.add(1), "num limited");
        for (uint256 i; i < num; i++) {
            // get new token id
            uint256 tokenId = getNextSparkId();
            // mint and set token type
            _safeMint(account, tokenId);
            setType(tokenId, uint256(TokenType.SPARK));
        }
    }

    // presale for daughter
    function mint(uint256 num) public payable nonReentrant WhenNotPaused {
        if (whitelistEnabled) { // check whitelist
            require(isWhitelist(_msgSender()), "not in whitelist");
            require(whitelistMintCounts[_msgSender()].add(num) <= whitelistMintMaxCount, "whitelist mint num limited");
            whitelistMintCounts[_msgSender()] =  whitelistMintCounts[_msgSender()].add(num);
        }
        // validate
        require(msg.value >= salePrice.mul(num), "payment invalid");
        // mint daughter
        _mintDaughter(_msgSender(), num);
    }

    // returns (uint256[] tokenIds, uint256[] tokenTypes)
    function getTokens(address owner) public view returns (uint256[] memory, uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory tokenTypes = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = id;
            tokenTypes[i] = getType(id);
        }
        return (tokenIds, tokenTypes);
    }

    function canClaimSGR(address owner) public view returns (bool silver, bool gold, bool rainbow) {
        if (!sgrClaimEnabled) { // not enabled
            return (false, false, false);
        }

        // check silver/gold/rainbow
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(owner);
        uint256 daughterCount;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.DAUGHTER) && !getClaimFlag(tokenIds[i])) {
                daughterCount = daughterCount.add(1);
            }
        }

        if (daughterCount >= RAINBOW_CLAIM_DAUGHTER_MIN_NUM && rainbowLeftover() > 0) {
            rainbow = true;
        } else if (daughterCount >= GOLD_CLAIM_DAUGHTER_MIN_NUM && goldLeftover() > 0) {
            gold = true;
        } else if (daughterCount >= SILVER_CLAIM_DAUGHTER_MIN_NUM && silverLeftover() > 0) {
            silver = true;
        }
    }

    function canClaim(address account) public view
        returns
        (bool silver, bool gold, bool rainbow, bool ebible, bool random, bool m3d, bool airdrops, bool spark) {
        // check silver/gold/rainbow
        (silver, gold, rainbow) = canClaimSGR(account);

        // check ebible
        ebible = canClaimEbible(account);

        // check random silver/gold/rainbow
        random = false;

        // check m3d
        m3d = canClaim3D(account);

        // check airdrops
        airdrops = canClaimAirdrops(account);

        // check spark
        spark = canClaimSpark(account);
    }

    function canClaim3D(address account) public view returns (bool) {
        if (!m3dClaimEnabled) {
            return false;
        }

        // mint over
        if (m3dLeftover() == 0) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function canClaimEbible(address account) public view returns (bool) {
        if (!ebibleClaimEnabled) { // not enabled
            return false;
        }

        // mint over
        if (ebibleLeftover() == 0) {
            return false;
        }

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(account);
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        if (cnt >= 3) {
            return true;
        }
        return false;
    }

    function claim3D() public {
        require(m3dClaimEnabled, "not start");

        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        bool can;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                can = true;
                break;
            }
        }
        require(can, "can't claim 3D mother");

        // set claim flag
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.MOTHER) && !getClaim3DFlag(tokenIds[i])) {
                setClaim3DFlag(tokenIds[i], true);
                break;
            }
        }

        // mint
        _mintM3d(_msgSender(), 1);
    }

    function canClaimAirdrops(address account) public view returns (bool) {
        if (isWhitelistAirdrops(account) && !getClaimAirdropsFlag(account) && airdropsLeftover() > 0) {
            return true;
        }
        return false;
    }

    function claimAirdrops() public {
        address account = _msgSender();
        require(canClaimAirdrops(account), "can't claim airdrops");

        // set claim flags
        setClaimAirdropsFlag(account, true);

        // mint
        _mintAirdrops(account, 1);
    }

    function canClaimSpark(address account) public view returns (bool) {
        if (isWhitelistSpark(account) && !getClaimSparkFlag(account) && sparkLeftover() > 0) {
            return true;
        }
        return false;
    }

    function claimSpark() public {
        address account = _msgSender();
        require(canClaimSpark(account), "can't claim spark");

        // set claim flags
        setClaimSparkFlag(account, true);

        // mint
        _mintSpark(account, 1);
    }

    function claim(uint256 tp) public {
        if (tp == uint256(TokenType.SILVER) || tp == uint256(TokenType.GOLD) || tp == uint256(TokenType.RAINBOW)) {
            claimSGR(tp);
        } else if (tp == uint256(TokenType.EBIBLE)) {
            claimEbible();
        } else if (tp == uint256(TokenType.M3D)) {
            claim3D();
        } else if (tp == uint256(TokenType.AIRDROPS)) {
            claimAirdrops();
        } else if (tp == uint256(TokenType.SPARK)) {
            claimSpark();
        }
    }

    function claimEbible() public {
        require(ebibleClaimEnabled, "not start");

        // check and set claim flag
        (uint256[] memory tokenIds, uint256[] memory tokenTypes) = getTokens(_msgSender());
        uint256 cnt;
        for (uint256 i = 0; i < tokenTypes.length; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                cnt = cnt.add(1);
            }
        }

        require(cnt >= 3, "can claim ebile");

        // set claim flag
        uint256 c = 3;
        for (uint256 i = 0; i < tokenTypes.length && c > 0; i++) {
            if (tokenTypes[i] == uint256(TokenType.RARE) && !getClaimEbibleFlag(tokenIds[i])) {
                setClaimEbibleFlag(tokenIds[i], true);
                c = c.sub(1);
            }
        }

        // mint
        _mintEbible(_msgSender(), 1);
    }

    ////////////////////////////////////////////////////
    // admin operation
    ////////////////////////////////////////////////////

    function adminMintDaughter(address account, uint256 num) public onlyWhitelistAdmin {
        _mintDaughter(account, num);
    }

    // admin mint alien
    function adminMintAlien(address account, uint256 num) public onlyWhitelistAdmin {
        _mintAlien(account, num);
    }

    // admin mint alien
    function adminMintRare(address account, uint256 num) public onlyWhitelistAdmin {
        _mintRare(account, num);
    }

    // admin mint mother
    function adminMintMother(address account, uint256 num) public onlyWhitelistAdmin {
        _mintMother(account, num);
    }

    // admin mint airdrops
    function adminMintAirdrops(address account, uint256 num) public onlyWhitelistAdmin {
        _mintAirdrops(account, num);
    }

    // admin mint spark
    function adminMintSpark(address account, uint256 num) public onlyWhitelistAdmin {
        _mintSpark(account, num);
    }

    function adminMint(address account, uint256 tp, uint256 num) public onlyWhitelistAdmin {
        if (tp == uint256(TokenType.DAUGHTER)) {
            _mintDaughter(account, num);
        } else if (tp == uint256(TokenType.ALIEN)) {
            _mintAlien(account, num);
        } else if (tp == uint256(TokenType.SILVER)) {
            _mintSilver(account, num);
        } else if (tp == uint256(TokenType.GOLD)) {
            _mintGold(account, num);
        } else if (tp == uint256(TokenType.RAINBOW)) {
            _mintRainbow(account, num);
        } else if (tp == uint256(TokenType.RARE)) {
            _mintRare(account, num);
        } else if (tp == uint256(TokenType.EBIBLE)) {
            _mintEbible(account, num);
        } else if (tp == uint256(TokenType.MOTHER)) {
            _mintMother(account, num);
        } else if (tp == uint256(TokenType.M3D)) {
            _mintM3d(account, num);
        } else if (tp == uint256(TokenType.AIRDROPS)) {
            _mintAirdrops(account, num);
        } else if (tp == uint256(TokenType.SPARK)) {
            _mintSpark(account, num);
        }
    }

    function adminMintx(address account, uint256 tp, uint256 tokenId) public onlyWhitelistAdmin {
        // mint and set token type
        _safeMint(account, tokenId);
        setType(tokenId, tp);
    }

    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    ////////////////////////////////////////////////////
}"},"ERC165.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
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
}"},"ERC721.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";

import "./Address.sol";
import "./Strings.sol";

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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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
}


"},"ERC721Enumerable.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721.sol";
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
"},"IERC165.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

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
}"},"IERC721.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

"},"IERC721Enumerable.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
"},"IERC721Metadata.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
}"},"IERC721Receiver.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}"},"Migrations.sol":{"content":"// SPDX-License-Identifier: MIT
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
"},"Ownable.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

"},"Pausable.sol":{"content":"// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool public paused;

    constructor ()  {
        paused = false;
    }

    modifier WhenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier WhenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function Pause() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function Unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}"},"ReentrancyGuard.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

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
     * by making the `nonReentrant` function external, and make it call a
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



"},"Roles.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

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
}
"},"Strings.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

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


"},"WhitelistAdminRole.sol":{"content":"// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}
"}}