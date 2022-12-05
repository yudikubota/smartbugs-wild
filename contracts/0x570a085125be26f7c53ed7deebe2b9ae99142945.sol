pragma solidity ^0.4.22;

/// @title ERC-721ã«æºæ ããå¥ç´ã®ã¤ã³ã¿ãã§ã¼ã¹
contract ERC721 {
    // ã¤ãã³ã
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // å¿è¦ãªã¡ã½ãã
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function totalSupply() public view returns (uint);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    *               å¥ç´ãä¸æåæ­¢ããã¦ããå ´åã«ã®ã¿ã¢ã¯ã·ã§ã³ãè¨±å¯ãã
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    *               å¥ç´ãä¸æåæ­¢ããã¦ããªãå ´åã«ã®ã¿ã¢ã¯ã·ã§ã³ãè¨±å¯ãã
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    *             ä¸æåæ­¢ããããã«ææèã«ãã£ã¦å¼ã³åºãããåæ­¢ç¶æãããªã¬ãã
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    *             ãã¼ãºãã¨ãããã«ãªã¼ãã¼ãå¼ã³åºããéå¸¸ã®ç¶æã«æ»ãã¾ã
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract RocsCoreRe {

    function getRoc(uint _tokenId) public returns (
        uint rocId,
        string dna,
        uint marketsFlg);

    function getRocIdToTokenId(uint _rocId) public view returns (uint);
    function getRocIndexToOwner(uint _rocId) public view returns (address);
}

contract ItemsBase is Pausable {
    // ãã³ãä»£
    uint public huntingPrice = 5 finney;
    function setHuntingPrice(uint256 price) public onlyOwner {
        huntingPrice = price;
    }

    // ERC721
    event Transfer(address from, address to, uint tokenId);
    event ItemTransfer(address from, address to, uint tokenId);

    // Itemã®ä½æ
    event ItemCreated(address owner, uint tokenId, uint ticketId);

    event HuntingCreated(uint huntingId, uint rocId);

    /// @dev Itemã®æ§é ä½
    struct Item {
        uint itemId;
        uint8 marketsFlg;
        uint rocId;
        uint8 equipmentFlg;
    }
    Item[] public items;

    // itemIdã¨tokenIdã®ãããã³ã°
    mapping(uint => uint) public itemIndex;
    // itemIdããtokenIdãåå¾
    function getItemIdToTokenId(uint _itemId) public view returns (uint) {
        return itemIndex[_itemId];
    }

    /// @dev itemã®ææããã¢ãã¬ã¹ã¸ã®ãããã³ã°
    mapping (uint => address) public itemIndexToOwner;
    // @dev itemã®ææèã¢ãã¬ã¹ããææãããã¼ã¯ã³æ°ã¸ã®ãããã³ã°
    mapping (address => uint) public itemOwnershipTokenCount;
    /// @dev itemã®å¼ã³åºããæ¿èªãããã¢ãã¬ã¹ã¸ã®ãããã³ã°
    mapping (uint => address) public itemIndexToApproved;

    /// @dev ç¹å®ã®itemæææ¨©ãã¢ãã¬ã¹ã«å²ãå½ã¦ã¾ãã
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        itemOwnershipTokenCount[_to]++;
        itemOwnershipTokenCount[_from]--;
        itemIndexToOwner[_tokenId] = _to;
        // ã¤ãã³ãéå§
        emit ItemTransfer(_from, _to, _tokenId);
    }

    address public rocCoreAddress;
    RocsCoreRe rocCore;

    function setRocCoreAddress(address _rocCoreAddress) public onlyOwner {
        rocCoreAddress = _rocCoreAddress;
        rocCore = RocsCoreRe(rocCoreAddress);
    }
    function getRocCoreAddress() 
        external
        view
        onlyOwner
        returns (
        address
    ) {
        return rocCore;
    }

    /// @dev Huntingã®æ§é ä½
    struct Hunting {
        uint huntingId;
    }
    // Huntingã®mapping rocHuntingIndex[rocId][tokenId] = Hunting
    mapping(uint => mapping (uint => Hunting)) public rocHuntingIndex;

    /// @notice Huntingãä½æãã¦ä¿å­ããåé¨ã¡ã½ããã 
    /// @param _rocId 
    /// @param _huntingId 
    function _createRocHunting(
        uint _rocId,
        uint _huntingId
    )
        internal
        returns (bool)
    {
        Hunting memory _hunting = Hunting({
            huntingId: _huntingId
        });

        rocHuntingIndex[_rocId][_huntingId] = _hunting;
        // HuntingCreatedã¤ãã³ã
        emit HuntingCreated(_huntingId, _rocId);

        return true;
    }
}

/// @title Itemæææ¨©ãç®¡çããã³ã³ãã©ã¯ã
/// @dev OpenZeppelinã®ERC721ãã©ããå®è£ã«æºæ 
contract ItemsOwnership is ItemsBase, ERC721 {

    /// @notice ERC721ã§å®ç¾©ããã¦ãããç½®ãæãä¸å¯è½ãªãã¼ã¯ã³ã®ååã¨è¨å·ã
    string public constant name = "CryptoFeatherItems";
    string public constant symbol = "CCHI";

    bytes4 constant InterfaceSignature_ERC165 = 
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('totalSupply()'));

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  ãã®å¥ç´ã«ãã£ã¦å®è£ãããæ¨æºåãããã¤ã³ã¿ãã§ã¼ã¹ã§trueãè¿ãã¾ãã
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev ç¹å®ã®ã¢ãã¬ã¹ã«æå®ãããitemã®ç¾å¨ã®ææèã§ãããã©ããããã§ãã¯ãã¾ãã
    /// @param _claimant 
    /// @param _tokenId 
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return itemIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev ç¹å®ã®ã¢ãã¬ã¹ã«æå®ãããitemãå­å¨ãããã©ããããã§ãã¯ãã¾ãã
    /// @param _claimant the address we are confirming kitten is approved for.
    /// @param _tokenId kitten id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return itemIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev ä»¥åã®æ¿èªãä¸æ¸ããã¦ãtransferFromï¼ï¼ã«å¯¾ãã¦æ¿èªãããã¢ãã¬ã¹ããã¼ã¯ãã¾ãã
    function _approve(uint256 _tokenId, address _approved) internal {
        itemIndexToApproved[_tokenId] = _approved;
    }

    // æå®ãããã¢ãã¬ã¹ã®itemæ°ãåå¾ãã¾ãã
    function balanceOf(address _owner) public view returns (uint256 count) {
        return itemOwnershipTokenCount[_owner];
    }

    /// @notice itemã®ææèãå¤æ´ãã¾ãã
    /// @dev ERC-721ã¸ã®æºæ ã«å¿è¦
    function transfer(address _to, uint256 _tokenId) public whenNotPaused {
        // å®å¨ãã§ãã¯
        require(_to != address(0));
        // èªåã®itemããéããã¨ã¯ã§ãã¾ããã
        require(_owns(msg.sender, _tokenId));
        // æææ¨©ã®åå²ãå½ã¦ãä¿çä¸­ã®æ¿èªã®ã¯ãªã¢ãè»¢éã¤ãã³ãã®éä¿¡
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice transferFromï¼ï¼ãä»ãã¦å¥ã®ã¢ãã¬ã¹ã«ç¹å®ã®itemãè»¢éããæ¨©å©ãä¸ãã¾ãã
    /// @dev ERC-721ã¸ã®æºæ ã«å¿è¦
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        // ææèã®ã¿ãè­²æ¸¡æ¿èªãèªãããã¨ãã§ãã¾ãã
        require(_owns(msg.sender, _tokenId));
        // æ¿èªãç»é²ãã¾ãï¼ä»¥åã®æ¿èªãç½®ãæãã¾ãï¼ã
        _approve(_tokenId, _to);
        // æ¿èªã¤ãã³ããçºè¡ããã
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice itemææèã®å¤æ´ãè¡ãã¾ãããè»¢éãã¾ãããã®ã¢ãã¬ã¹ã«ã¯ãä»¥åã®ææèããè»¢éæ¿èªãä¸ãããã¦ãã¾ãã
    /// @dev ERC-721ã¸ã®æºæ ã«å¿è¦
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        // å®å¨ãã§ãã¯ã
        require(_to != address(0));
        // æ¿èªã¨æå¹ãªæææ¨©ã®ç¢ºèª
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
        // æææ¨©ãåå²ãå½ã¦ãã¾ãï¼ä¿çä¸­ã®æ¿èªãã¯ãªã¢ããè»¢éã¤ãã³ããçºè¡ãã¾ãï¼ã
        _transfer(_from, _to, _tokenId);
    }

    /// @notice ç¾å¨å­å¨ããitemã®ç·æ°ãè¿ãã¾ãã
    /// @dev ERC-721ã¸ã®æºæ ã«å¿è¦ã§ãã
    function totalSupply() public view returns (uint) {
        return items.length - 1;
    }

    /// @notice æå®ãããitemã®ç¾å¨æææ¨©ãå²ãå½ã¦ããã¦ããã¢ãã¬ã¹ãè¿ãã¾ãã
    /// @dev ERC-721ã¸ã®æºæ ã«å¿è¦ã§ãã
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = itemIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    /// @dev ãã®å¥ç´ã«æææ¨©ãå²ãå½ã¦ãNFTãå¼·å¶çµäºãã¾ãã
    /// @param _owner 
    /// @param _tokenId 
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        transferFrom(_owner, this, _tokenId);
    }

}

/// @title Itemã«é¢ããç®¡çãè¡ãã³ã³ãã©ã¯ã
contract ItemsBreeding is ItemsOwnership {

    /// @notice Itemãä½æãã¦ä¿å­ã 
    /// @param _itemId 
    /// @param _marketsFlg 
    /// @param _rocId 
    /// @param _equipmentFlg 
    /// @param _owner 
    function _createItem(
        uint _itemId,
        uint _marketsFlg,
        uint _rocId,
        uint _equipmentFlg,
        address _owner
    )
        internal
        returns (uint)
    {
        Item memory _item = Item({
            itemId: _itemId,
            marketsFlg: uint8(_marketsFlg),
            rocId: _rocId,
            equipmentFlg: uint8(_equipmentFlg)
        });

        uint newItemId = items.push(_item) - 1;
        // åä¸ã®ãã¼ã¯ã³IDãçºçããå ´åã¯å®è¡ãåæ­¢ãã¾ã
        require(newItemId == uint(newItemId));
        // RocCreatedã¤ãã³ã
        emit ItemCreated(_owner, newItemId, _itemId);

        // ããã«ããæææ¨©ãå²ãå½ã¦ãããERC721ãã©ãããã¨ã«è»¢éã¤ãã³ããçºè¡ããã¾ã
        itemIndex[_itemId] = newItemId;
        _transfer(0, _owner, newItemId);

        return newItemId;
    }

    /// @notice ã¢ã¤ãã ã®è£åç¶æãæ´æ°ãã¾ãã 
    /// @param _reItems 
    /// @param _inItems 
    /// @param _rocId 
    function equipmentItem(
        uint[] _reItems,
        uint[] _inItems,
        uint _rocId
    )
        external
        whenNotPaused
        returns(bool)
    {
        uint checkTokenId = rocCore.getRocIdToTokenId(_rocId);
        uint i;
        uint itemTokenId;
        Item memory item;
        // è§£é¤
        for (i = 0; i < _reItems.length; i++) {
            itemTokenId = getItemIdToTokenId(_reItems[i]);
            // itemã®ãã©ã¡ã¼ã¿ãã§ãã¯
            item = items[itemTokenId];
            // ãã¼ã±ããã¸ã®åºåä¸­ãç¢ºèªãã¦ãã ããã
            require(uint(item.marketsFlg) == 0);
            // ã¢ã¤ãã è£çä¸­ãç¢ºèªãã¦ãã ããã
            require(uint(item.equipmentFlg) == 1);
            // è£çããã¯ãåä¸ãç¢ºèªãã¦ãã ããã
            require(uint(item.rocId) == _rocId);
            // è£åè§£é¤
            items[itemTokenId].rocId = 0;
            items[itemTokenId].equipmentFlg = 0;
            // ã¢ã¤ãã ã®ãªã¼ãã¼ãéãã°ããã¯ã®ãªã¼ãã¼ãã»ããããªããã¾ãã
            address itemOwner = itemIndexToOwner[itemTokenId];
            address checkOwner = rocCore.getRocIndexToOwner(checkTokenId);
            if (itemOwner != checkOwner) {
                itemIndexToOwner[itemTokenId] = checkOwner;
            }
        }
        // è£ç
        for (i = 0; i < _inItems.length; i++) {
            itemTokenId = getItemIdToTokenId(_inItems[i]);
            // itemã®ãã©ã¡ã¼ã¿ãã§ãã¯
            item = items[itemTokenId];
            // itemã®ãªã¼ãã¼ã§ããäº
            require(_owns(msg.sender, itemTokenId));
            // ãã¼ã±ããã¸ã®åºåä¸­ãç¢ºèªãã¦ãã ããã
            require(uint(item.marketsFlg) == 0);
            // ã¢ã¤ãã æªè£åãç¢ºèªãã¦ãã ããã
            require(uint(item.equipmentFlg) == 0);
            // è£åå¦ç
            items[itemTokenId].rocId = _rocId;
            items[itemTokenId].equipmentFlg = 1;
        }
        return true;
    }

    /// @notice æ¶è²»ããäºã§åé¤ã®å¦çãè¡ãã¾ãã
    /// @param _itemId 
    function usedItem(
        uint _itemId
    )
        external
        whenNotPaused
        returns(bool)
    {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        Item memory item = items[itemTokenId];
        // itemã®ãªã¼ãã¼ã§ããäº
        require(_owns(msg.sender, itemTokenId));
        // ãã¼ã±ããã¸ã®åºåä¸­ãç¢ºèªãã¦ãã ããã
        require(uint(item.marketsFlg) == 0);
        // ã¢ã¤ãã æªè£åãç¢ºèªãã¦ãã ããã
        require(uint(item.equipmentFlg) == 0);
        delete itemIndex[_itemId];
        delete items[itemTokenId];
        delete itemIndexToOwner[itemTokenId];
        return true;
    }

    /// @notice Huntingã®å¦çãè¡ãã¾ãã
    /// @param _rocId 
    /// @param _huntingId 
    /// @param _items 
    function processHunting(
        uint _rocId,
        uint _huntingId,
        uint[] _items
    )
        external
        payable
        whenNotPaused
        returns(bool)
    {
        require(msg.value >= huntingPrice);

        uint checkTokenId = rocCore.getRocIdToTokenId(_rocId);
        uint marketsFlg;
        ( , , marketsFlg) = rocCore.getRoc(checkTokenId);

        // marketsä¸­ãç¢ºèªãã¦ãã ããã
        require(marketsFlg == 0);
        bool createHunting = false;
        // Huntingå¦ç
        require(_huntingId > 0);
        createHunting = _createRocHunting(
            _rocId,
            _huntingId
        );

        uint i;
        for (i = 0; i < _items.length; i++) {
            _createItem(
                _items[i],
                0,
                0,
                0,
                msg.sender
            );
        }

        // è¶éåãè²·ãæã«è¿ã
        uint256 bidExcess = msg.value - huntingPrice;
        msg.sender.transfer(bidExcess);

        return createHunting;
    }

    /// @notice Itemãä½æãã¾ããã¤ãã³ãç¨
    /// @param _items 
    /// @param _owners 
    function createItems(
        uint[] _items,
        address[] _owners
    )
        external onlyOwner
        returns (uint)
    {
        uint i;
        uint createItemId;
        for (i = 0; i < _items.length; i++) {
            createItemId = _createItem(
                _items[i],
                0,
                0,
                0,
                _owners[i]
            );
        }
        return createItemId;
    }

}

/// @title Itemã®Marketã«é¢ããå¦ç
contract ItemsMarkets is ItemsBreeding {

    event ItemMarketsCreated(uint256 tokenId, uint128 marketsPrice);
    event ItemMarketsSuccessful(uint256 tokenId, uint128 marketsPriceice, address buyer);
    event ItemMarketsCancelled(uint256 tokenId);

    // ERC721
    event Transfer(address from, address to, uint tokenId);

    // NFTä¸ã®Market
    struct ItemMarkets {
        // ç»é²æã®NFTå£²æ
        address seller;
        // Marketã®ä¾¡æ ¼
        uint128 marketsPrice;
    }

    // ãã¼ã¯ã³IDããå¯¾å¿ãããã¼ã±ããã¸ã®åºåã«ããããã¾ãã
    mapping (uint256 => ItemMarkets) tokenIdToItemMarkets;

    // ãã¼ã±ããã¸ã®åºåã®ææ°æãè¨­å®
    uint256 public ownerCut = 0;
    function setOwnerCut(uint256 _cut) public onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }

    /// @notice Itemãã¼ã±ããã¸ã®åºåãä½æããéå§ãã¾ãã
    /// @param _itemId 
    /// @param _marketsPrice 
    function createItemSaleMarkets(
        uint256 _itemId,
        uint256 _marketsPrice
    )
        external
        whenNotPaused
    {
        require(_marketsPrice == uint256(uint128(_marketsPrice)));

        // ãã§ãã¯ç¨ã®tokenIdãã»ãã
        uint itemTokenId = getItemIdToTokenId(_itemId);
        // itemã®ãªã¼ãã¼ã§ããäº
        require(_owns(msg.sender, itemTokenId));
        // itemã®ãã©ã¡ã¼ã¿ãã§ãã¯
        Item memory item = items[itemTokenId];
        // ãã¼ã±ããã¸ã®åºåä¸­ãç¢ºèªãã¦ãã ããã
        require(uint(item.marketsFlg) == 0);
        // è£åä¸­ãç¢ºèªãã¦ãã ããã
        require(uint(item.rocId) == 0);
        require(uint(item.equipmentFlg) == 0);
        // æ¿èª
        _approve(itemTokenId, msg.sender);
        // ãã¼ã±ããã¸ã®åºåã»ãã
        _escrow(msg.sender, itemTokenId);
        ItemMarkets memory itemMarkets = ItemMarkets(
            msg.sender,
            uint128(_marketsPrice)
        );

        // ãã¼ã±ããã¸ã®åºåFLGãã»ãã
        items[itemTokenId].marketsFlg = 1;

        _itemAddMarkets(itemTokenId, itemMarkets);
    }

    /// @dev ãã¼ã±ããã¸ã®åºåãå¬éãã¼ã±ããã¸ã®åºåã®ãªã¹ãã«è¿½å ãã¾ãã 
    ///  ã¾ããItemMarketsCreatedã¤ãã³ããçºçããã¾ãã
    /// @param _tokenId The ID of the token to be put on markets.
    /// @param _markets Markets to add.
    function _itemAddMarkets(uint256 _tokenId, ItemMarkets _markets) internal {
        tokenIdToItemMarkets[_tokenId] = _markets;
        emit ItemMarketsCreated(
            uint256(_tokenId),
            uint128(_markets.marketsPrice)
        );
    }

    /// @dev ãã¼ã±ããã¸ã®åºåãå¬éãã¼ã±ããã¸ã®åºåã®ãªã¹ãããåé¤ãã¾ãã
    /// @param _tokenId 
    function _itemRemoveMarkets(uint256 _tokenId) internal {
        delete tokenIdToItemMarkets[_tokenId];
    }

    /// @dev ç¡æ¡ä»¶ã«ãã¼ã±ããã¸ã®åºåãåãæ¶ãã¾ãã
    /// @param _tokenId 
    function _itemCancelMarkets(uint256 _tokenId) internal {
        _itemRemoveMarkets(_tokenId);
        emit ItemMarketsCancelled(_tokenId);
    }

    /// @dev ã¾ã ç²å¾ããã¦ããªããã¼ã±ããã¸ã®åºåãã­ã£ã³ã»ã«ãã¾ãã
    ///  åã®ææèã«NFTãè¿ãã¾ãã
    /// @notice ããã¯ãå¥ç´ãä¸æåæ­¢ãã¦ããéã«å¼ã³åºããã¨ãã§ããç¶æå¤æ´é¢æ°ã§ãã
    /// @param _itemId 
    function itemCancelMarkets(uint _itemId) external {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        ItemMarkets storage markets = tokenIdToItemMarkets[itemTokenId];
        address seller = markets.seller;
        require(msg.sender == seller);
        _itemCancelMarkets(itemTokenId);
        itemIndexToOwner[itemTokenId] = seller;
        items[itemTokenId].marketsFlg = 0;
    }

    /// @dev å¥ç´ãä¸æåæ­¢ãããã¨ãã«ãã¼ã±ããã¸ã®åºåãã­ã£ã³ã»ã«ãã¾ãã
    ///  ææèã ãããããè¡ããã¨ãã§ããNFTã¯å£²ãæã«è¿ããã¾ãã 
    ///  ç·æ¥æã«ã®ã¿ä½¿ç¨ãã¦ãã ããã
    /// @param _itemId 
    function itemCancelMarketsWhenPaused(uint _itemId) whenPaused onlyOwner external {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        ItemMarkets storage markets = tokenIdToItemMarkets[itemTokenId];
        address seller = markets.seller;
        _itemCancelMarkets(itemTokenId);
        itemIndexToOwner[itemTokenId] = seller;
        items[itemTokenId].marketsFlg = 0;
    }

    /// @dev ãã¼ã±ããã¸ã®åºåå¥æ­
    ///  ååãªéã®Etherãä¾çµ¦ãããã°NFTã®æææ¨©ãç§»è»¢ããã
    /// @param _itemId 
    function itemBid(uint _itemId) external payable whenNotPaused {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        // ãã¼ã±ããã¸ã®åºåæ§é ä½ã¸ã®åç§ãåå¾ãã
        ItemMarkets storage markets = tokenIdToItemMarkets[itemTokenId];

        uint128 sellingPrice = uint128(markets.marketsPrice);
        // å¥æ­é¡ãä¾¡æ ¼ä»¥ä¸ã§ããäºãç¢ºèªããã
        // msg.valueã¯weiã®æ°
        require(msg.value >= sellingPrice);
        // ãã¼ã±ããã¸ã®åºåæ§é ä½ãåé¤ãããåã«ãè²©å£²èã¸ã®åç§ãåå¾ãã¾ãã
        address seller = markets.seller;

        // ãã¼ã±ããã¸ã®åºåãåé¤ãã¾ãã
        _itemRemoveMarkets(itemTokenId);

        if (sellingPrice > 0) {
            // ç«¶å£²äººã®ã«ãããè¨ç®ãã¾ãã
            uint128 marketseerCut = uint128(_computeCut(sellingPrice));
            uint128 sellerProceeds = sellingPrice - marketseerCut;

            // å£²ãæã«ééãã
            seller.transfer(sellerProceeds);
        }

        // è¶éåãè²·ãæã«è¿ã
        msg.sender.transfer(msg.value - sellingPrice);
        // ã¤ãã³ã
        emit ItemMarketsSuccessful(itemTokenId, sellingPrice, msg.sender);

        _transfer(seller, msg.sender, itemTokenId);
        // ãã¼ã±ããã¸ã®åºåFLGãã»ãã
        items[itemTokenId].marketsFlg = 0;
    }

    /// @dev ææ°æè¨ç®
    /// @param _price 
    function _computeCut(uint128 _price) internal view returns (uint) {
        return _price * ownerCut / 10000;
    }

}

/// @title CryptoFeather
contract ItemsCore is ItemsMarkets {

    // ã³ã¢å¥ç´ãå£ãã¦ã¢ããã°ã¬ã¼ããå¿è¦ãªå ´åã«è¨­å®ãã¾ã
    address public newContractAddress;

    /// @dev ä¸æåæ­¢ãç¡å¹ã«ããã¨ãå¥ç´ãä¸æåæ­¢ããåã«ãã¹ã¦ã®å¤é¨å¥ç´ã¢ãã¬ã¹ãè¨­å®ããå¿è¦ãããã¾ãã
    function unpause() public onlyOwner whenPaused {
        require(newContractAddress == address(0));
        // å®éã«å¥ç´ãä¸æåæ­¢ããªãã§ãã ããã
        super.unpause();
    }

    // @dev å©ç¨å¯è½ãªæ®é«ãåå¾ã§ããããã«ãã¾ãã
    function withdrawBalance(uint _subtractFees) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > _subtractFees) {
            owner.transfer(balance - _subtractFees);
        }
    }

    /// @notice tokenIdããItemã«é¢ãããã¹ã¦ã®é¢é£æå ±ãè¿ãã¾ãã
    /// @param _tokenId 
    function getItem(uint _tokenId)
        external
        view
        returns (
        uint itemId,
        uint marketsFlg,
        uint rocId,
        uint equipmentFlg
    ) {
        Item memory item = items[_tokenId];
        itemId = uint(item.itemId);
        marketsFlg = uint(item.marketsFlg);
        rocId = uint(item.rocId);
        equipmentFlg = uint(item.equipmentFlg);
    }

    /// @notice itemIdããItemã«é¢ãããã¹ã¦ã®é¢é£æå ±ãè¿ãã¾ãã
    /// @param _itemId 
    function getItemItemId(uint _itemId)
        external
        view
        returns (
        uint itemId,
        uint marketsFlg,
        uint rocId,
        uint equipmentFlg
    ) {
        Item memory item = items[getItemIdToTokenId(_itemId)];
        itemId = uint(item.itemId);
        marketsFlg = uint(item.marketsFlg);
        rocId = uint(item.rocId);
        equipmentFlg = uint(item.equipmentFlg);
    }

    /// @notice itemIdããMarketsæå ±ãè¿ãã¾ãã
    /// @param _itemId 
    function getMarketsItemId(uint _itemId)
        external
        view
        returns (
        address seller,
        uint marketsPrice
    ) {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        ItemMarkets storage markets = tokenIdToItemMarkets[itemTokenId];
        seller = markets.seller;
        marketsPrice = uint(markets.marketsPrice);
    }

    /// @notice itemIdãããªã¼ãã¼æå ±ãè¿ãã¾ãã
    /// @param _itemId 
    function getItemIndexToOwner(uint _itemId)
        external
        view
        returns (
        address owner
    ) {
        uint itemTokenId = getItemIdToTokenId(_itemId);
        owner = itemIndexToOwner[itemTokenId];
    }

    /// @notice rocIdã¨huntingIdããhuntingã®å­å¨ãã§ãã¯
    /// @param _rocId 
    /// @param _huntingId 
    function getHunting(uint _rocId, uint _huntingId)
        public
        view
        returns (
        uint huntingId
    ) {
        Hunting memory hunting = rocHuntingIndex[_rocId][_huntingId];
        huntingId = uint(hunting.huntingId);
    }

    /// @notice _rocIdãããªã¼ãã¼æå ±ãè¿ãã¾ãã
    /// @param _rocId 
    function getRocOwnerItem(uint _rocId)
        external
        view
        returns (
        address owner
    ) {
        uint checkTokenId = rocCore.getRocIdToTokenId(_rocId);
        owner = rocCore.getRocIndexToOwner(checkTokenId);
    }

}