{{
  "language": "Solidity",
  "sources": {
    "contracts/IPRegistrarController.sol": {
      "content": "//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./ENS.sol";

import {BaseRegistrar} from "./BaseRegistrar.sol";
import {PublicResolver} from "./PublicResolver.sol";
import {ReverseRegistrar} from "./ReverseRegistrar.sol";
import {IETHRegistrarController, IPriceOracle} from "@ensdomains/ens-contracts/contracts/ethregistrar/IETHRegistrarController.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20Recoverable} from "@ensdomains/ens-contracts/contracts/utils/ERC20Recoverable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "./Normalize4.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/SSTORE2.sol";

error NameNotAvailable(string name);
error DurationTooShort(uint256 duration);
error InsufficientValue();

import "hardhat/console.sol";

contract IPRegistrarController is
    Ownable,
    IETHRegistrarController,
    IERC165,
    ERC20Recoverable,
    ReentrancyGuard
{
    using LibString for *;
    using Address for *;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeTransferLib for address;
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;

    uint256 public constant MIN_REGISTRATION_DURATION = 28 days;
    BaseRegistrar immutable base;
    IPriceOracle public immutable prices;
    
    ENS public immutable ens;
    address public defaultResolver;
    ReverseRegistrar public reverseRegistrar;
    Normalize4 public normalizer;
    
    string public constant tldString = 'ip';
    bytes32 public constant tldLabel = keccak256(abi.encodePacked(tldString));
    bytes32 public constant rootNode = bytes32(0);
    bytes32 public immutable tldNode = keccak256(abi.encodePacked(rootNode, tldLabel));
    
    mapping (uint => string) public hashToLabelString;
    
    uint64 public auctionTimeBuffer = 15 minutes;
    uint256 public auctionMinBidIncrementPercentage = 10;
    uint64 public auctionDuration = 24 hours;
    bool public contractInAuctionMode = true;
    
    mapping(uint => Auction) public auctions;
    EnumerableSet.UintSet activeAuctionIds;

    uint public ethAvailableToWithdraw;
    address payable public withdrawAddress;
    
    address public logoSVG;
    address[] public fonts;
    
    struct Auction {
        uint tokenId;
        string name;
        uint64 startTime;
        uint64 endTime;
        Bid[] bids;
    }
    
    struct AuctionInfo {
        uint tokenId;
        string name;
        uint64 startTime;
        uint64 endTime;
        Bid[] bids;
        uint minNextBid;
        address highestBidder;
        uint highestBidAMount;
    }
    
    struct Bid {
        uint80 amount;
        address bidder;
    }
    
    event AuctionStarted(uint indexed tokenId, uint startTime, uint endTime);
    event AuctionExtended(uint indexed tokenId, uint endTime);
    event AuctionBid(uint indexed tokenId, address bidder, uint bidValue, bool auctionExtended);
    event AuctionSettled(uint indexed tokenId, address winner, uint amount);

    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner,
        uint256 baseCost,
        uint256 premium,
        uint256 expires
    );
    event NameRenewed(
        string name,
        bytes32 indexed label,
        uint256 cost,
        uint256 expires
    );
    
    event AuctionWithdraw(address indexed addr, uint indexed total);
    event Withdraw(address indexed addr, uint indexed total);
    
    function setDefaultResolver(address _defaultResolver) public onlyOwner {
        defaultResolver = _defaultResolver;
    }
    
    function setReverseRegistrar(ReverseRegistrar _reverseRegistrar) public onlyOwner {
        reverseRegistrar = _reverseRegistrar;
    }
    
    function setNormalizer(Normalize4 _normalizer) public onlyOwner {
        normalizer = _normalizer;
    }
    
    function setAuctionTimeBuffer(uint64 _auctionTimeBuffer) public onlyOwner {
        auctionTimeBuffer = _auctionTimeBuffer;
    }
    
    function setAuctionMinBidIncrementPercentage(uint256 _auctionMinBidIncrementPercentage) public onlyOwner {
        auctionMinBidIncrementPercentage = _auctionMinBidIncrementPercentage;
    }
    
    function setAuctionDuration(uint64 _auctionDuration) public onlyOwner {
        auctionDuration = _auctionDuration;
    }
    
    function setContractInAuctionMode(bool _contractInAuctionMode) public onlyOwner {
        contractInAuctionMode = _contractInAuctionMode;
    }
    
    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = payable(_withdrawAddress);
    }
    
    modifier onlyBaseRegistrar() {
        require(msg.sender == address(base), "Only base registrar");
        _;
    }

    constructor(
        ENS _ens,
        BaseRegistrar _base,
        IPriceOracle _prices,
        ReverseRegistrar _reverseRegistrar,
        Normalize4 _normalizer,
        string memory _logoSVG,
        string[5] memory _fonts
    ) {
        ens = _ens;
        base = _base;
        prices = _prices;
        reverseRegistrar = _reverseRegistrar;
        normalizer = _normalizer;
        
        setLogoSVG(_logoSVG);
        setFonts(_fonts);
    }
    
    bool preRegisterDone;
    function preRegisterNames(
        string[] calldata names,
        bytes[][] calldata data,
        address owner
    ) external onlyOwner {
        require(!preRegisterDone);
        
        for (uint i; i < names.length; ++i) {
            _registerWithoutCommitment(
                names[i],
                owner,
                365 days,
                address(0),
                data[0],
                false,
                0,
                0
            );
        }
        
        preRegisterDone = true;
    }
    
    function rentPrice(string memory name, uint256 duration)
        public
        view
        override
        returns (IPriceOracle.Price memory price)
    {
        bytes32 label = keccak256(bytes(name));
        price = prices.price(name, base.nameExpires(uint256(label)), duration);
    }

    function valid(string memory name) public view returns (bool) {
        if (bytes(name).length == 0) return false;
        
        try normalizer.normalize(name) returns (string[] memory _norm) {
            if (!(name.eq(_norm[0]) && _norm.length == 1)) return false;
        } catch {
            return false;
        }
        
        return true;
    }

    function available(string memory name) public view override returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint32 fuses,
        uint64 wrapperExpiry
    ) public payable override {
        return registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord
        );
    }
    
    function auctionMinNextBid(uint currentHighestBid) public view returns (uint) {
        return currentHighestBid + (currentHighestBid * auctionMinBidIncrementPercentage / 100);
    }
    
    function max(uint a, uint b) internal pure returns (uint) {
        return a > b ? a : b;
    }
    
    function auctionHighestBid(uint tokenId) public view returns (Bid memory) {
        Auction storage auction = auctions[tokenId];
        if (auction.bids.length == 0) {
            return Bid({amount: 0, bidder: address(0)});
        }
        return auction.bids[auction.bids.length - 1];
    }
    
    function getAuction(string memory name) public view returns (AuctionInfo memory) {
        uint256 tokenId = uint256(keccak256(bytes(name)));

        Auction memory auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);
        
        uint reservePrice = (rentPrice(name, 365 days)).base;
        uint minNextBid = max(auctionMinNextBid(highestBid.amount), reservePrice);
        
        return AuctionInfo({
            tokenId: tokenId,
            name: name,
            startTime: auction.startTime,
            endTime: auction.endTime,
            bids: auction.bids,
            minNextBid: minNextBid,
            highestBidder: highestBid.bidder,
            highestBidAMount: highestBid.amount
        });
    }
    
    function bidOnName(string calldata name) external payable nonReentrant returns (bool success) {
        uint256 tokenId = uint256(keccak256(bytes(name)));

        Auction storage auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);
        
        require(contractInAuctionMode, "Contract not in auction mode");
        require(msg.value < type(uint80).max, "Out of range");
        require(msg.value >= auctionMinNextBid(highestBid.amount), 'Must send at least min increment');
        
        require(auction.endTime == 0 || block.timestamp < auction.endTime, "Auction ended");
        
        if (auction.startTime == 0) {
            uint reservePrice = (rentPrice(name, 365 days)).base;
            require(msg.value >= reservePrice, 'Must send at least reservePrice');
            require(available(name), "Not available");
            
            auction.startTime = uint64(block.timestamp);
            auction.endTime = uint64(block.timestamp + auctionDuration);
            auction.tokenId = tokenId;
            auction.name = name;
            
            activeAuctionIds.add(tokenId);
            emit AuctionStarted(tokenId, auction.startTime, auction.endTime);
        }
        
        if (highestBid.bidder != address(0)) {
            highestBid.bidder.forceSafeTransferETH(highestBid.amount);
        }
        
        Bid memory newBid = Bid({
            amount: uint80(msg.value),
            bidder: msg.sender
        });
        
        auction.bids.push(newBid);
        
        bool extendAuction = auction.endTime - block.timestamp < auctionTimeBuffer;
        if (extendAuction) {
            auction.endTime = uint64(block.timestamp + auctionTimeBuffer);
            emit AuctionExtended(tokenId, auction.endTime);
        }

        emit AuctionBid(tokenId, newBid.bidder, newBid.amount, extendAuction);
        
        return true;
    }
    
    function settleAuction(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord
    ) external nonReentrant {
        uint tokenId = uint256(keccak256(bytes(name)));
        Auction memory auction = auctions[tokenId];
        Bid memory highestBid = auctionHighestBid(tokenId);

        require(owner == highestBid.bidder, "Only highest bidder");
        require(duration == 365 days, "Must be 365 days");
        require(auction.startTime != 0, "Auction hasn't begun");
        require(block.timestamp >= auction.endTime, "Auction hasn't completed");
        
        _registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord,
            highestBid.amount,
            0
        );
        
        ethAvailableToWithdraw += highestBid.amount;
        activeAuctionIds.remove(tokenId);
        
        emit AuctionSettled(tokenId, highestBid.bidder, highestBid.amount);
    }
    
    function registerWithoutCommitment(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord
    ) public payable nonReentrant {
        require(!contractInAuctionMode, "Contract in auction mode");
        
        uint tokenId = uint256(keccak256(bytes(name)));
        require(!activeAuctionIds.contains(tokenId), "Name in auction");
        
        IPriceOracle.Price memory price = rentPrice(name, duration);
        
        if (msg.value < price.base + price.premium) revert InsufficientValue();
        if (duration < MIN_REGISTRATION_DURATION) revert DurationTooShort(duration);

        _registerWithoutCommitment(
            name,
            owner,
            duration,
            resolver,
            data,
            reverseRecord,
            price.base,
            price.premium
        );

        if (msg.value > (price.base + price.premium)) {
            msg.sender.forceSafeTransferETH(
                msg.value - (price.base + price.premium)
            );
        }
    }
    
    function _registerWithoutCommitment(
        string calldata name,
        address owner,
        uint256 duration,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint basePrice,
        uint pricePremium
    ) internal {
        if (!available(name)) {
            revert NameNotAvailable(name);
        }
        uint256 tokenId = uint256(keccak256(bytes(name)));
        
        uint256 expires = base.registerOnly(tokenId, owner, duration);
        if (resolver == address(0)) {
            resolver = defaultResolver;
        }
        
        ens.setSubnodeRecord(tldNode, bytes32(tokenId), owner, resolver, 0);
        bytes32 node = _makeNode(tldNode, keccak256(bytes(name)));
        
        PublicResolver(resolver).setAddr(node, owner);
        if (data.length > 0) {
            _setRecords(resolver, keccak256(bytes(name)), data);
        }

        if (reverseRecord && msg.sender == owner) {
            _setReverseRecord(name, resolver, msg.sender);
        }
        
        hashToLabelString[tokenId] = name;
        
        emit NameRegistered(
            name,
            keccak256(bytes(name)),
            owner,
            basePrice,
            pricePremium,
            expires
        );
    }

    function renew(string calldata name, uint256 duration) external payable override nonReentrant {
        bytes32 labelhash = keccak256(bytes(name));
        uint256 tokenId = uint256(labelhash);
        IPriceOracle.Price memory price = rentPrice(name, duration);
        if (msg.value < price.base) {
            revert InsufficientValue();
        }
        uint256 expires;
        expires = base.renew(tokenId, duration);

        if (msg.value > price.base) {
            msg.sender.forceSafeTransferETH(msg.value - price.base);
        }

        emit NameRenewed(name, labelhash, msg.value, expires);
    }
    
    function auctionWithdraw() external nonReentrant {
        require(contractInAuctionMode, "Contract not in auction mode");
        require(ethAvailableToWithdraw > 0, "Nothing to withdraw");
        require(withdrawAddress != address(0), "Withdraw address not set");
        
        uint balance = ethAvailableToWithdraw;
        ethAvailableToWithdraw = 0;
        
        withdrawAddress.sendValue(balance);
        emit AuctionWithdraw(withdrawAddress, balance);
    }
    
    function withdraw() external nonReentrant onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        
        withdrawAddress.sendValue(balance);
        emit Withdraw(withdrawAddress, balance);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IETHRegistrarController).interfaceId;
    }
    
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {}
    
    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {
        if (from == address(0) || to == address(0)) return;
        
        ens.setSubnodeOwner(tldNode, bytes32(tokenId), to);
    }
    
    function getAllActiveAuctions() external view returns (AuctionInfo[] memory) {
        return getActiveAuctionsInBatches(0, activeAuctionIds.length());
    }
    
    function getActiveAuctionsInBatches(uint batchIdx, uint batchSize) public view returns (AuctionInfo[] memory) {
        uint auctionCount = activeAuctionIds.length();
        uint startIdx = batchIdx * batchSize;
        uint endIdx = startIdx + batchSize;
        if (endIdx > auctionCount) {
            endIdx = auctionCount;
        }
        AuctionInfo[] memory ret = new AuctionInfo[](endIdx - startIdx);
        
        for (uint i = startIdx; i < endIdx; ++i) {
            Auction memory auction = auctions[activeAuctionIds.at(i)];
            string memory name = auction.name;
            ret[i - startIdx] = getAuction(name);
        }
        return ret;
    }

    /* Internal functions */
    
    function _setRecords(
        address resolverAddress,
        bytes32 label,
        bytes[] calldata data
    ) internal {
        bytes32 nodehash = keccak256(abi.encodePacked(tldNode, label));
        PublicResolver resolver = PublicResolver(resolverAddress);
        resolver.multicallWithNodeCheck(nodehash, data);
    }

    function _setReverseRecord(
        string memory name,
        address resolver,
        address owner
    ) internal {
        reverseRegistrar.setNameForAddr(
            msg.sender,
            owner,
            resolver,
            string.concat(name, ".", tldString)
        );
    }
    
    function _makeNode(bytes32 node, bytes32 labelhash)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, labelhash));
    }
    
    function makeCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint32 fuses,
        uint64 wrapperExpiry
    ) public pure override returns (bytes32) {
        revert("No commitment required, call register() directly");
    }

    function commit(bytes32 commitment) public override {
        revert("No commitment required, call register() directly");
    }
    
   function allFonts() public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory fontData;
        
        for (uint i = 0; i < fonts.length; i++) {
            fontData.append(SSTORE2.read(fonts[i]));
        }
        
        return string(fontData.data);
    }
    
    function setFonts(string[5] memory _fonts) public onlyOwner {
        for (uint i = 0; i < _fonts.length; i++) {
            fonts.push(SSTORE2.write(bytes(_fonts[i])));
        }
    }
    
    function setLogoSVG(string memory _logoSVG) public onlyOwner {
        logoSVG = SSTORE2.write(bytes(_logoSVG));
    }
}
"
    },
    "contracts/ENS.sol": {
      "content": "pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}"
    },
    "contracts/BaseRegistrar.sol": {
      "content": "pragma solidity >=0.8.4;

import "./IBaseRegistrar.sol";
import "./IPRegistrarController.sol";
import "./IPTokenRenderer.sol";
import "./ERC721PTO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseRegistrar is ERC721PTO, IBaseRegistrar, Ownable {
    ENS public ens;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public immutable baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
    
    IPTokenRenderer public tokenRenderer;
    IPRegistrarController public registrarController;
    
    uint256 public constant GRACE_PERIOD = 90 days;
    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
                keccak256("ownerOf(uint256)") ^
                keccak256("approve(address,uint256)") ^
                keccak256("getApproved(uint256)") ^
                keccak256("setApprovalForAll(address,bool)") ^
                keccak256("isApprovedForAll(address,address)") ^
                keccak256("transferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256)") ^
                keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID =
        bytes4(keccak256("reclaim(uint256,address)"));

    function setENS(ENS _ens) public onlyOwner {
        ens = _ens;
    }
    
    function setRenderer(IPTokenRenderer _renderer) public onlyOwner {
        tokenRenderer = _renderer;
    }
    
    function setRegistrarController(IPRegistrarController _registrarController) external onlyOwner {
        registrarController = _registrarController;
        setOperator(address(_registrarController), true);
        addController(address(_registrarController));
    }
    
    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    
    constructor(ENS _ens, bytes32 _baseNode) ERC721PTO("EBPTO: IP Domains", "IP") {
        ens = _ens;
        baseNode = _baseNode;
    }
    
    function setTokenRenderer(IPTokenRenderer _tokenRenderer) public onlyOwner {
        tokenRenderer = _tokenRenderer;
    }

    modifier live() {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId)
        public
        view
        override(IERC721, ERC721PTO)
        returns (address)
    {
        require(_getExpiryTimestamp(tokenId) > block.timestamp, "Expiration invalid");
        return super.ownerOf(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721PTO) returns (string memory) {
        require(_exists(tokenId), "Doesn't exist");
        
        return tokenRenderer.constructTokenURI(tokenId);
    }
    
    function exists(uint tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) public override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }
    
    function setOperator(address operator, bool status) public onlyOwner {
        ens.setApprovalForAll(operator, status);
    }
    
    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external override onlyOwner {
        ens.setResolver(baseNode, resolver);
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view override returns (uint256) {
        return _getExpiryTimestamp(id);
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view override returns (bool) {
        // Not available if it's registered here or in its grace period.
        return _getExpiryTimestamp(id) + GRACE_PERIOD < block.timestamp;
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external override returns (uint256) {
        return _register(id, owner, duration, true);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     * @param duration Duration in seconds for the registration.
     */
    function registerOnly(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256) {
        return _register(id, owner, duration, false);
    }

    function _register(
        uint256 id,
        address owner,
        uint256 duration,
        bool updateRegistry
    ) internal live onlyController returns (uint256) {
        require(available(id), "Name not available");
        
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);

        _setExpiryTimestamp(id, uint48(block.timestamp + duration));

        if (updateRegistry) {
            ens.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner, block.timestamp + duration);

        return block.timestamp + duration;
    }

    function renew(uint256 id, uint256 duration)
        external
        override
        live
        onlyController
        returns (uint256)
    {
        uint currentExpiry = _getExpiryTimestamp(id);
        uint48 newExpiry = uint48(currentExpiry + duration);
        
        require(currentExpiry + GRACE_PERIOD >= block.timestamp); // Name must be registered here or in grace period

        _setExpiryTimestamp(id, newExpiry);
        emit NameRenewed(id, newExpiry);
        return newExpiry;
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721PTO, IERC165)
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721PTO)
    {
        registrarController.beforeTokenTransfer(from, to, tokenId, batchSize);
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721PTO)
    {
        registrarController.afterTokenTransfer(from, to, tokenId, batchSize);
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}"
    },
    "contracts/PublicResolver.sol": {
      "content": "//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "./ENS.sol";

import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/DNSResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/PubkeyResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";

import "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol";

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver is
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver
{
    ENS immutable ens;
    address immutable trustedETHController;
    address immutable trustedReverseRegistrar;

    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(
        ENS _ens,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) {
        ens = _ens;
        trustedETHController = _trustedETHController;
        trustedReverseRegistrar = _trustedReverseRegistrar;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        if (
            msg.sender == trustedETHController ||
            msg.sender == trustedReverseRegistrar
        ) {
            return true;
        }
        address owner = ens.owner(node);
        
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            Multicallable,
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            DNSResolver,
            InterfaceResolver,
            NameResolver,
            PubkeyResolver,
            TextResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}"
    },
    "contracts/ReverseRegistrar.sol": {
      "content": "pragma solidity >=0.8.4;

import "./ENS.sol";
import "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/root/Controllable.sol";

abstract contract NameResolver {
    function setName(bytes32 node, string memory name) public virtual;
}

bytes32 constant lookup = 0x3031323334353637383961626364656600000000000000000000000000000000;

bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

contract ReverseRegistrar is Ownable, Controllable, IReverseRegistrar {
    ENS public immutable ens;
    NameResolver public defaultResolver;

    event ReverseClaimed(address indexed addr, bytes32 indexed node);
    event DefaultResolverChanged(NameResolver indexed resolver);

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     */
    constructor(ENS ensAddr) {
        ens = ensAddr;

        // Assign ownership of the reverse record to our deployer
        ReverseRegistrar oldRegistrar = ReverseRegistrar(
            ensAddr.owner(ADDR_REVERSE_NODE)
        );
        if (address(oldRegistrar) != address(0x0)) {
            oldRegistrar.claim(msg.sender);
        }
    }

    modifier authorised(address addr) {
        require(
            addr == msg.sender ||
                controllers[msg.sender] ||
                ens.isApprovedForAll(addr, msg.sender) ||
                ownsContract(addr),
            "ReverseRegistrar: Caller is not a controller or authorised by address or the address itself"
        );
        _;
    }

    function setDefaultResolver(address resolver) public override onlyOwner {
        require(
            address(resolver) != address(0),
            "ReverseRegistrar: Resolver address must not be 0"
        );
        defaultResolver = NameResolver(resolver);
        emit DefaultResolverChanged(NameResolver(resolver));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public override returns (bytes32) {
        return claimForAddr(msg.sender, owner, address(defaultResolver));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param addr The reverse record to set
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The resolver of the reverse node
     * @return The ENS node hash of the reverse record.
     */
    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) public override authorised(addr) returns (bytes32) {
        bytes32 labelHash = sha3HexAddress(addr);
        bytes32 reverseNode = keccak256(
            abi.encodePacked(ADDR_REVERSE_NODE, labelHash)
        );
        emit ReverseClaimed(addr, reverseNode);
        ens.setSubnodeRecord(ADDR_REVERSE_NODE, labelHash, owner, resolver, 0);
        return reverseNode;
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver)
        public
        override
        returns (bytes32)
    {
        return claimForAddr(msg.sender, owner, resolver);
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public override returns (bytes32) {
        return
            setNameForAddr(
                msg.sender,
                msg.sender,
                address(defaultResolver),
                name
            );
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the account provided. Updates the resolver to a designated resolver
     * Only callable by controllers and authorised users
     * @param addr The reverse record to set
     * @param owner The owner of the reverse node
     * @param resolver The resolver of the reverse node
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) public override returns (bytes32) {
        bytes32 node = claimForAddr(addr, owner, resolver);
        NameResolver(resolver).setName(node, name);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public pure override returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr))
            );
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return ret The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        assembly {
            for {
                let i := 40
            } gt(i, 0) {

            } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

    function ownsContract(address addr) internal view returns (bool) {
        try Ownable(addr).owner() returns (address owner) {
            return owner == msg.sender;
        } catch {
            return false;
        }
    }
}"
    },
    "contracts/Normalize4.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Normalize4 is Ownable {

	error InvalidCodepoint(uint256 cp);

	uint256 constant STOP = 0x2E;
	uint256 constant EMOJI_STATE_MASK  = 0x07FF; 
	uint256 constant EMOJI_STATE_QUIRK = 0x0800;
	uint256 constant EMOJI_STATE_VALID = 0x1000;
	uint256 constant EMOJI_STATE_SAVE  = 0x2000;
	uint256 constant EMOJI_STATE_CHECK = 0x4000;
	uint256 constant EMOJI_STATE_FE0F  = 0x8000;

	mapping (uint256 => uint256) _emoji;
	mapping (uint256 => uint256) _valid;   // bitmap
	mapping (uint256 => uint256) _ignored; // bitmap
	mapping (uint256 => uint256) _small; // 1-2 cp
	mapping (uint256 => uint256) _large; // 3-6 cp
	mapping (uint256 => uint256) _class;
	mapping (uint256 => uint256) _cm;
	mapping (uint256 => uint256) _recomp;
	mapping (uint256 => uint256) _decomp;

	function normhash(string memory name) public view returns (bytes32 node) {
		string[] memory labels = normalize(name);
		uint256 i = labels.length;
		while (i > 0) {
			bytes32 label = keccak256(bytes(labels[--i]));
			node = keccak256(abi.encodePacked(node, label));
		}
	}

	function normalize(string memory name) public view returns (string[] memory labels) {
        (uint256[] memory values, uint256 label_count) = process(decodeUTF8(bytes(name)), false);
		//n = label_count;
		//v = values;
		values = nfd(values);
		labels = new string[](label_count);
		uint256 prev;
		for (uint256 i; i < label_count; i++) {
			uint256 end = prev;
			while (end < values.length && values[end] != STOP) end++;
			labels[i] = string(post_check_label(values, prev, end));
			prev = end + 1;
		}
	}

	function beautify(string memory name) public view returns (string memory) {
		(uint256[] memory values, ) = process(decodeUTF8(bytes(name)), true);
		return string(nfc(nfd(values)));
	}


	function updateMapping(mapping (uint256 => uint256) storage map, bytes calldata data, uint256 key_bytes) private {
		uint256 i;
		uint256 e;
	    uint256 mask = ~(type(uint256).max << (key_bytes << 3));
		assembly {
			i := data.offset
			e := add(i, data.length)
		}
		while (i < e) {
			uint256 k;
			uint256 v;
			assembly {
				// key-value pairs are packed in reverse 
				// eg. [value1][key1][value2][key2]...
				v := calldataload(i)
				i := add(i, key_bytes)
				k := and(calldataload(i), mask)
				i := add(i, 32)
			}
			map[k] = v;
		}
	}
	
	function updateBatch1(bytes[] calldata data) public onlyOwner {
		updateClass(data[0]);
        updateCM(data[1]);
        updateDecomp(data[2]);
        updateIgnored(data[3]);
        updateLarge(data[4]);
        updateValid(data[5]);
        updateLarge(data[6]);
	}
    
    function updateBatch2(bytes[] calldata data) public onlyOwner {
        updateRecomp(data[0]);
        uploadEmoji(data[1]);
    }

	function uploadEmoji(bytes calldata data) public onlyOwner {
		updateMapping(_emoji, data, 4);
	}
	function updateValid(bytes calldata data) public onlyOwner {
		updateMapping(_valid, data, 2);
	}
	function updateIgnored(bytes calldata data) public onlyOwner {
		updateMapping(_ignored, data, 2);
	}
	function updateSmall(bytes calldata data) public onlyOwner {
		updateMapping(_small, data, 3);
	}
	function updateLarge(bytes calldata data) public onlyOwner {
		updateMapping(_large, data, 3);
	}
	function updateClass(bytes calldata data) public onlyOwner {
		updateMapping(_class, data, 2);
	}
	function updateCM(bytes calldata data) public onlyOwner {
		updateMapping(_cm, data, 2);
	}
	function updateDecomp(bytes calldata data) public onlyOwner {
		updateMapping(_decomp, data, 3);
	}
	function updateRecomp(bytes calldata data) public onlyOwner {
		updateMapping(_recomp, data, 5);
	}

	// bitmaps
	function isCM(uint256 cp) public view returns (bool) {
		return ((_cm[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isValid(uint256 cp) public view returns (bool) {
		return ((_valid[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isIgnored(uint256 cp) public view returns (bool) {
		return ((_ignored[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}

 	function getDecomp(uint256 cp) public view returns (uint256) {
        return (_decomp[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
    }
	function getRecomp(uint256 a, uint256 b) public view returns (uint256) {
		return (_recomp[(b << 29) | (a >> 3)] >> ((a & 0x7) << 5)) & 0xFFFFFFFF;
	}
	function getClass(uint256 cp) public view returns (uint256) {
		return (_class[cp >> 5] >> ((cp & 0x1F) << 3)) & 0xFF;
	}

	function getSmall(uint256 cp) public view returns (uint256) {
		return (_small[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
	}
	function getLarge(uint256 cp) public view returns (uint256) {
		return (_large[cp >> 1] >> ((cp & 0x1) << 7)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	}

	function getEmoji(uint256 s0, uint256 cp) private view returns (uint256) {
		return (_emoji[(s0 << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
	}

	
	function debugEmojiState(uint256 s0, uint256 cp) public view returns (uint256 value, bool fe0f, bool check, bool save, bool valid, bool quirk, uint256 s1) {
		// (state0, Floor[cp/16]) => array: uint32[16]
		// array[cp%16] => [flags: (4 bits), state1: (12 bits)]
		value = getEmoji(s0, cp);
		fe0f = (value & EMOJI_STATE_FE0F) != 0;
		check = (value & EMOJI_STATE_CHECK) != 0;
		save = (value & EMOJI_STATE_SAVE) != 0;
		valid = (value & EMOJI_STATE_VALID) != 0;
		quirk = (value & EMOJI_STATE_QUIRK) != 0;
		s1 = value & EMOJI_STATE_MASK; // next state
	}

	function isOneEmoji(string memory s) public view returns (bool) {
		uint256[] memory cps = decodeUTF8(bytes(s));
		uint256[] memory ret = new uint256[](cps.length);
		(uint256 pos, uint256 len) = consumeEmoji(cps, 0, ret, 0, false);
		return pos == cps.length && len > 0;
	}

	// https://www.unicode.org/versions/Unicode14.0.0/ch03.pdf
	uint256 constant S0 = 0xAC00;
	uint256 constant L0 = 0x1100;
	uint256 constant V0 = 0x1161;
	uint256 constant T0 = 0x11A7;
	uint256 constant L_COUNT = 19;
	uint256 constant V_COUNT = 21;
	uint256 constant T_COUNT = 28;
	uint256 constant N_COUNT = V_COUNT * T_COUNT;
	uint256 constant S_COUNT = L_COUNT * N_COUNT;
	uint256 constant S1 = S0 + S_COUNT;
	uint256 constant L1 = L0 + L_COUNT;
	uint256 constant V1 = V0 + V_COUNT;
	uint256 constant T1 = T0 + T_COUNT;
	uint256 constant CP_MASK = 0xFFFFFF;

	function isHangul(uint256 cp) private pure returns (bool) {
		return cp >= S0 && cp < S1;
	}
	function getComposed(uint256 a, uint256 b) private view returns (uint256) {
		if (a >= L0 && a < L1 && b >= V0 && b < V1) { // LV
			return S0 + (a - L0) * N_COUNT + (b - V0) * T_COUNT;
		} else if (isHangul(a) && b > T0 && b < T1 && (a - S0) % T_COUNT == 0) {
			return a + (b - T0);
		} else {
			return getRecomp(a, b);
		}
	}

	function decodeUTF8(bytes memory src) private pure returns (uint256[] memory ret) {
		ret = new uint256[](src.length);
		uint256 ptr;
		assembly {
			ptr := src
		}
		uint256 len;
		uint256 end = ptr + src.length;
		while (ptr < end) {
			(uint256 cp, uint256 step) = readUTF8(ptr);
			ret[len++] = cp;
			ptr += step;
		}
		assembly {
			mstore(ret, len) // truncate
		}
	}

	// read one cp from memory at ptr
	// step is number of encoded bytes (1-4)
	// raw is encoded bytes
	// warning: assumes valid UTF8
	function readUTF8(uint256 ptr) private pure returns (uint256 cp, uint256 step) {
		// 0xxxxxxx => 1 :: 0aaaaaaa ???????? ???????? ???????? =>                   0aaaaaaa
		// 110xxxxx => 2 :: 110aaaaa 10bbbbbb ???????? ???????? =>          00000aaa aabbbbbb
		// 1110xxxx => 3 :: 1110aaaa 10bbbbbb 10cccccc ???????? => 000000aa aaaabbbb bbcccccc
		// 11110xxx => 4 :: 11110aaa 10bbbbbb 10cccccc 10dddddd => 000aaabb bbbbcccc ccdddddd
		uint256 raw;
		assembly {
			raw := and(mload(add(ptr, 4)), 0xFFFFFFFF)
		}
		uint256 upper = raw >> 28;
		if (upper < 0x8) {
			step = 1;
			raw >>= 24;
			cp = raw;
		} else if (upper < 0xE) {
			step = 2;
			raw >>= 16;
			cp = ((raw & 0x1F00) >> 2) | (raw & 0x3F);
		} else if (upper < 0xF) {
			step = 3;
			raw >>= 8;
			cp = ((raw & 0x0F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		} else {
			step = 4;
			cp = ((raw & 0x07000000) >> 6) | ((raw & 0x3F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		}
	}

	function encodeUTF8(uint256[] memory cps) private pure returns (bytes memory ret) {
		ret = new bytes(cps.length << 2);
		uint256 ret_off;
		assembly {
			ret_off := add(ret, 32)
		}
		uint256 ret_end = ret_off;
		for (uint256 i; i < cps.length; i++) {
			ret_end = writeUTF8(ret_end, cps[i] & CP_MASK);
		}
		assembly {
			mstore(ret, sub(ret_end, ret_off))
		}
	}

    function writeUTF8(uint256 ptr, uint256 cp) private pure returns (uint256) {
		if (cp < 0x80) {
            assembly {
                mstore8(ptr, cp)
            }
            return ptr + 1;
		} else if (cp < 0x800) {
            assembly {
                mstore8(ptr,         or(0xC0, shr(6, cp)))
                mstore8(add(ptr, 1), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 2;
		} else if (cp < 0x10000) {
            assembly {
                mstore8(ptr,         or(0xE0, shr(12, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 3;
		} else {
            assembly {
                mstore8(ptr,         or(0xF0, shr(18, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(12, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 3), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 4;
		}
	}

	function process(uint256[] memory cps, bool pretty) public view returns (uint256[] memory ret, uint256 label_count) {
		ret = new uint256[](cps.length * 6); // maximum expansion factor
		label_count = 1;
		uint256 len;
		uint256 i;
		while(i < cps.length) {
			(uint256 new_i, uint256 new_len) = consumeEmoji(cps, i, ret, len, pretty);
			if (new_i > i) {
				i = new_i;
				if (pretty && (new_len & VALUE_EMOJI) != 0) {
					len = (new_len ^ VALUE_EMOJI) - 1;
					for (uint256 j = i + 1; j < len; j++) {
						ret[j] = ret[j+1];
					}
				} else {
					len = new_len;
				}
				continue;
			}
			uint256 cp = cps[i++];
			uint256 mapped = getMapped(cp); 
			if (mapped != 0) {
				ret[len++] = mapped;
				continue;
			}
			if (isValid(cp)) {		
				if (cp == STOP) label_count++;		
 				ret[len++] = cp;
				continue;
			}
			if (isIgnored(cp)) { 
				continue;
			}
			mapped = getSmall(cp);
			if (mapped != 0) {
				if (mapped < 0xFFFFFF) {
					ret[len++] = mapped;
				} else {
					ret[len++] = mapped >> 24;
					ret[len++] = mapped & 0xFFFFFF;
				}
				continue;
			}
			mapped = getLarge(cp);
			if (mapped == 0) revert InvalidCodepoint(cp);
			while (mapped != 0) {
				ret[len++] = mapped & 0x1FFFFF;
				mapped >>= 21;
			}
		}
		assembly {
			mstore(ret, len)
		}
	}

    function addClass(uint256 cp) private view returns (uint256) {
        return (getClass(cp) << 24) | cp;
    }
	function nfd(uint256[] memory cps) private view returns (uint256[] memory ret) {
        ret = new uint256[](cps.length * 3); // growth factor
        uint256 len;
        uint256 has_nz_class;
        for (uint256 i; i < cps.length; i++) {
            uint256 buf = cps[i];
            uint256 width = 32;
            while (width != 0) {
                uint256 cp = buf & 0xFFFFFFFF;
                buf >>= 32;
                width -= 32;
                if (cp < 0x80 || cp >= CP_MASK) {
                    ret[len++] = cp;
                } else if (isHangul(cp)) {
                    uint256 s_index = cp - S0;
                    uint256 l_index = s_index / N_COUNT | 0;
                    uint256 v_index = (s_index % N_COUNT) / T_COUNT | 0;
                    uint256 t_index = s_index % T_COUNT;
                    uint256 l_cp = addClass(L0 + l_index);
                    uint256 v_cp = addClass(V0 + v_index);
                    ret[len++] = l_cp;
                    ret[len++] = v_cp;
                    if (has_nz_class == 0 && (l_cp | v_cp) > CP_MASK) has_nz_class = 1;
                    if (t_index != 0) {
                        uint256 t_cp = addClass(T0 + t_index);
                        if (has_nz_class == 0 && t_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = t_cp;
                    }
                } else {
                    uint256 decomp = getDecomp(cp);
                    if (decomp != 0) {
                        buf |= (decomp << width);
                        width += (decomp >> 32) == 0 ? 32 : 64;
                    } else {
                        uint256 x_cp = addClass(cp);
                        if (has_nz_class == 0 && x_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = x_cp;
                    }
                }
            }
        }
        if (has_nz_class != 0) {
            uint256 prev = ret[0] >> 24;
            for (uint256 i = 1; i < len; i++) {
                uint256 rank = ret[i] >> 24;
                if (prev == 0 || rank == 0 || prev <= rank) {
                    prev = rank;
                    continue;
                }
                uint256 j = i - 1;
                while (true) {
                    (ret[j+1], ret[j]) = (ret[j], ret[j+1]);
                    if (j == 0) break;
                    prev = ret[--j] >> 24;
                    if (prev <= rank) break;
                }
                prev = ret[i] >> 24;
            }
        }
        assembly {
            mstore(ret, len) // truncate
        }
    }

	
	function nfc(uint256[] memory values) private view returns (bytes memory utf8) {
		utf8 = new bytes(values.length << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		for (uint256 i; i < values.length; i++) {
			uint256 cp = values[i] & CP_MASK;
			if (prev_cp != 0) {
				if (cp >= 0x80) {
					uint256 composed = getComposed(prev_cp, cp);
					if (composed != 0) {
						prev_cp = composed;
						continue;
					}
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		if (prev_cp != 0) {
			utf_end = writeUTF8(utf_end, prev_cp);
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}


	function post_check_label(uint256[] memory values, uint256 start, uint256 end) private view returns (bytes memory utf8) {
		uint256 len = end - start;
		if (len == 0) return ('');
		uint256 non_ascii;
		uint256 fail_if_underscore;
		uint256 fail_if_cm = 1;
		utf8 = new bytes(len << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		while (start < end) {
			uint256 value = values[start++];
			uint256 cp = value & 0xFFFFFF;
			if (cp < 0x80) { // ascii
				if (cp == 0x5F) { // underscore
					require(fail_if_underscore == 0, "underscore");
				} else {
					fail_if_underscore = 1;
				}
				if (prev_cp != 0) {
					utf_end = writeUTF8(utf_end, prev_cp);	
				}
				prev_cp = cp;
				fail_if_cm = 0;
				continue;
			}
			non_ascii = 1;
			if (isCM(cp)) {
				require(fail_if_cm == 0, "cm");
				fail_if_cm = 1;
			} else if ((value & VALUE_EMOJI) != 0) {
				fail_if_cm = 1;
			} else {
				fail_if_cm = 0;
			}
			if (prev_cp != 0) {
				uint256 composed = getComposed(prev_cp, cp);
				if (composed != 0) {
					prev_cp = composed;
					continue;
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		utf_end = writeUTF8(utf_end, prev_cp);	
		// label extension
		if (len >= 4 && non_ascii == 0 && utf8[2] == '-' && utf8[3] == '-') {
			revert("label extension");
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}

	uint256 constant VALUE_EMOJI = 0x80000000;

	function consumeEmoji(uint256[] memory cps, uint256 pos, uint256[] memory ret, uint256 len, bool add_fe0f) private view returns (uint256 out_pos, uint256 out_len) {
		uint256 state;
		uint256 saved;
		while (pos < cps.length) {
			uint256 cp = cps[pos++];
			state = getEmoji(state & EMOJI_STATE_MASK, cp);
			if (state == 0) break;
			if ((state & EMOJI_STATE_SAVE) != 0) { 
				saved = cp; 
			} else if ((state & EMOJI_STATE_CHECK) != 0) { 
				if (cp == saved) break;
			}
			ret[len++] = cp | VALUE_EMOJI;
			if ((state & EMOJI_STATE_FE0F) != 0) {
				if (add_fe0f) ret[len++] = 0xFE0F | VALUE_EMOJI;
				if (pos < cps.length && cps[pos] == 0xFE0F) pos++;
			}
			if ((state & EMOJI_STATE_VALID) != 0) {
				out_pos = pos;
				out_len = len;
				if (add_fe0f && (state & EMOJI_STATE_QUIRK) != 0) {
					out_len |= VALUE_EMOJI;
				}			
			}
		}
	}

/*
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
        return 0;
    }*/

	// auto-generated
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
		if (cp <= 0x1D734) {
			if (cp <= 0xFFB3) {
				if (cp <= 0x2099) {
					if (cp <= 0x1CBA) {
						if (cp <= 0x3FF) {
							if (cp <= 0xDE) {
								if (cp >= 0x41 && cp <= 0x5A) { // Mapped11: 26
									ret = cp + 0x20;
								} else if (cp >= 0xC0 && cp <= 0xD6) { // Mapped11: 23
									ret = cp + 0x20;
								} else if (cp >= 0xD8 && cp <= 0xDE) { // Mapped11: 7
									ret = cp + 0x20;
								}
							} else {
								if (cp >= 0x388 && cp <= 0x38A) { // Mapped11: 3
									ret = cp + 0x25;
								} else if (cp >= 0x391 && cp <= 0x3A1) { // Mapped11: 17
									ret = cp + 0x20;
								} else if (cp >= 0x3A3 && cp <= 0x3AB) { // Mapped11: 9
									ret = cp + 0x20;
								} else if (cp >= 0x3FD && cp <= 0x3FF) { // Mapped11: 3
									ret = cp - 0x82;
								}
							}
						} else {
							if (cp <= 0x556) {
								if (cp >= 0x400 && cp <= 0x40F) { // Mapped11: 16
									ret = cp + 0x50;
								} else if (cp >= 0x410 && cp <= 0x42F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x531 && cp <= 0x556) { // Mapped11: 38
									ret = cp + 0x30;
								}
							} else {
								if (cp >= 0x6F0 && cp <= 0x6F3) { // Mapped11: 4
									ret = cp - 0x90;
								} else if (cp >= 0x6F7 && cp <= 0x6F9) { // Mapped11: 3
									ret = cp - 0x90;
								} else if (cp >= 0x13F8 && cp <= 0x13FD) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1C90 && cp <= 0x1CBA) { // Mapped11: 43
									ret = cp - 0xBC0;
								}
							}
						}
					} else {
						if (cp <= 0x1F0F) {
							if (cp <= 0x1D5F) {
								if (cp >= 0x1CBD && cp <= 0x1CBF) { // Mapped11: 3
									ret = cp - 0xBC0;
								} else if (cp >= 0x1D33 && cp <= 0x1D3A) { // Mapped11: 8
									ret = cp - 0x1CCC;
								} else if (cp >= 0x1D5D && cp <= 0x1D5F) { // Mapped11: 3
									ret = cp - 0x19AB;
								}
							} else {
								if (cp >= 0x1DA4 && cp <= 0x1DA6) { // Mapped11: 3
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DAE && cp <= 0x1DB1) { // Mapped11: 4
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DBC && cp <= 0x1DBE) { // Mapped11: 3
									ret = cp - 0x1B2C;
								} else if (cp >= 0x1F08 && cp <= 0x1F0F) { // Mapped11: 8
									ret = cp - 0x8;
								}
							}
						} else {
							if (cp <= 0x1F4D) {
								if (cp >= 0x1F18 && cp <= 0x1F1D) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1F28 && cp <= 0x1F2F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F38 && cp <= 0x1F3F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F48 && cp <= 0x1F4D) { // Mapped11: 6
									ret = cp - 0x8;
								}
							} else {
								if (cp >= 0x1F68 && cp <= 0x1F6F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x2074 && cp <= 0x2079) { // Mapped11: 6
									ret = cp - 0x2040;
								} else if (cp >= 0x2080 && cp <= 0x2089) { // Mapped11: 10
									ret = cp - 0x2050;
								} else if (cp >= 0x2096 && cp <= 0x2099) { // Mapped11: 4
									ret = cp - 0x202B;
								}
							}
						}
					}
				} else {
					if (cp <= 0x32E9) {
						if (cp <= 0x313F) {
							if (cp <= 0x24CF) {
								if (cp >= 0x2135 && cp <= 0x2138) { // Mapped11: 4
									ret = cp - 0x1B65;
								} else if (cp >= 0x2460 && cp <= 0x2468) { // Mapped11: 9
									ret = cp - 0x242F;
								} else if (cp >= 0x24B6 && cp <= 0x24CF) { // Mapped11: 26
									ret = cp - 0x2455;
								}
							} else {
								if (cp >= 0x24D0 && cp <= 0x24E9) { // Mapped11: 26
									ret = cp - 0x246F;
								} else if (cp >= 0x2C00 && cp <= 0x2C2F) { // Mapped11: 48
									ret = cp + 0x30;
								} else if (cp >= 0x3137 && cp <= 0x3139) { // Mapped11: 3
									ret = cp - 0x2034;
								} else if (cp >= 0x313A && cp <= 0x313F) { // Mapped11: 6
									ret = cp - 0x1F8A;
								}
							}
						} else {
							if (cp <= 0x317C) {
								if (cp >= 0x3141 && cp <= 0x3143) { // Mapped11: 3
									ret = cp - 0x203B;
								} else if (cp >= 0x3145 && cp <= 0x314E) { // Mapped11: 10
									ret = cp - 0x203C;
								} else if (cp >= 0x314F && cp <= 0x3163) { // Mapped11: 21
									ret = cp - 0x1FEE;
								} else if (cp >= 0x3178 && cp <= 0x317C) { // Mapped11: 5
									ret = cp - 0x204D;
								}
							} else {
								if (cp >= 0x3184 && cp <= 0x3186) { // Mapped11: 3
									ret = cp - 0x202D;
								} else if (cp >= 0x3263 && cp <= 0x3265) { // Mapped11: 3
									ret = cp - 0x215E;
								} else if (cp >= 0x3269 && cp <= 0x326D) { // Mapped11: 5
									ret = cp - 0x215B;
								} else if (cp >= 0x32E4 && cp <= 0x32E9) { // Mapped11: 6
									ret = cp - 0x21A;
								}
							}
						}
					} else {
						if (cp <= 0xFF19) {
							if (cp <= 0x32FE) {
								if (cp >= 0x32EE && cp <= 0x32F2) { // Mapped11: 5
									ret = cp - 0x210;
								} else if (cp >= 0x32F5 && cp <= 0x32FA) { // Mapped11: 6
									ret = cp - 0x20D;
								} else if (cp >= 0x32FB && cp <= 0x32FE) { // Mapped11: 4
									ret = cp - 0x20C;
								}
							} else {
								if (cp >= 0xAB70 && cp <= 0xABBF) { // Mapped11: 80
									ret = cp - 0x97D0;
								} else if (cp >= 0xFB24 && cp <= 0xFB26) { // Mapped11: 3
									ret = cp - 0xF549;
								} else if (cp >= 0xFE41 && cp <= 0xFE44) { // Mapped11: 4
									ret = cp - 0xCE35;
								} else if (cp >= 0xFF10 && cp <= 0xFF19) { // Mapped11: 10
									ret = cp - 0xFEE0;
								}
							}
						} else {
							if (cp <= 0xFF93) {
								if (cp >= 0xFF21 && cp <= 0xFF3A) { // Mapped11: 26
									ret = cp - 0xFEC0;
								} else if (cp >= 0xFF41 && cp <= 0xFF5A) { // Mapped11: 26
									ret = cp - 0xFEE0;
								} else if (cp >= 0xFF85 && cp <= 0xFF8A) { // Mapped11: 6
									ret = cp - 0xCEBB;
								} else if (cp >= 0xFF8F && cp <= 0xFF93) { // Mapped11: 5
									ret = cp - 0xCEB1;
								}
							} else {
								if (cp >= 0xFF96 && cp <= 0xFF9B) { // Mapped11: 6
									ret = cp - 0xCEAE;
								} else if (cp >= 0xFFA7 && cp <= 0xFFA9) { // Mapped11: 3
									ret = cp - 0xEEA4;
								} else if (cp >= 0xFFAA && cp <= 0xFFAF) { // Mapped11: 6
									ret = cp - 0xEDFA;
								} else if (cp >= 0xFFB1 && cp <= 0xFFB3) { // Mapped11: 3
									ret = cp - 0xEEAB;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0x1D503) {
					if (cp <= 0x118BF) {
						if (cp <= 0x10427) {
							if (cp <= 0xFFCF) {
								if (cp >= 0xFFB5 && cp <= 0xFFBE) { // Mapped11: 10
									ret = cp - 0xEEAC;
								} else if (cp >= 0xFFC2 && cp <= 0xFFC7) { // Mapped11: 6
									ret = cp - 0xEE61;
								} else if (cp >= 0xFFCA && cp <= 0xFFCF) { // Mapped11: 6
									ret = cp - 0xEE63;
								}
							} else {
								if (cp >= 0xFFD2 && cp <= 0xFFD7) { // Mapped11: 6
									ret = cp - 0xEE65;
								} else if (cp >= 0xFFDA && cp <= 0xFFDC) { // Mapped11: 3
									ret = cp - 0xEE67;
								} else if (cp >= 0xFFE9 && cp <= 0xFFEC) { // Mapped11: 4
									ret = cp - 0xDE59;
								} else if (cp >= 0x10400 && cp <= 0x10427) { // Mapped11: 40
									ret = cp + 0x28;
								}
							}
						} else {
							if (cp <= 0x1058A) {
								if (cp >= 0x104B0 && cp <= 0x104D3) { // Mapped11: 36
									ret = cp + 0x28;
								} else if (cp >= 0x10570 && cp <= 0x1057A) { // Mapped11: 11
									ret = cp + 0x27;
								} else if (cp >= 0x1057C && cp <= 0x1058A) { // Mapped11: 15
									ret = cp + 0x27;
								}
							} else {
								if (cp >= 0x1058C && cp <= 0x10592) { // Mapped11: 7
									ret = cp + 0x27;
								} else if (cp >= 0x107B6 && cp <= 0x107B8) { // Mapped11: 3
									ret = cp - 0x105F6;
								} else if (cp >= 0x10C80 && cp <= 0x10CB2) { // Mapped11: 51
									ret = cp + 0x40;
								} else if (cp >= 0x118A0 && cp <= 0x118BF) { // Mapped11: 32
									ret = cp + 0x20;
								}
							}
						}
					} else {
						if (cp <= 0x1D481) {
							if (cp <= 0x1D433) {
								if (cp >= 0x16E40 && cp <= 0x16E5F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x1D400 && cp <= 0x1D419) { // Mapped11: 26
									ret = cp - 0x1D39F;
								} else if (cp >= 0x1D41A && cp <= 0x1D433) { // Mapped11: 26
									ret = cp - 0x1D3B9;
								}
							} else {
								if (cp >= 0x1D434 && cp <= 0x1D44D) { // Mapped11: 26
									ret = cp - 0x1D3D3;
								} else if (cp >= 0x1D44E && cp <= 0x1D454) { // Mapped11: 7
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D456 && cp <= 0x1D467) { // Mapped11: 18
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D468 && cp <= 0x1D481) { // Mapped11: 26
									ret = cp - 0x1D407;
								}
							}
						} else {
							if (cp <= 0x1D4B9) {
								if (cp >= 0x1D482 && cp <= 0x1D49B) { // Mapped11: 26
									ret = cp - 0x1D421;
								} else if (cp >= 0x1D4A9 && cp <= 0x1D4AC) { // Mapped11: 4
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4AE && cp <= 0x1D4B5) { // Mapped11: 8
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4B6 && cp <= 0x1D4B9) { // Mapped11: 4
									ret = cp - 0x1D455;
								}
							} else {
								if (cp >= 0x1D4BD && cp <= 0x1D4C3) { // Mapped11: 7
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4C5 && cp <= 0x1D4CF) { // Mapped11: 11
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4D0 && cp <= 0x1D4E9) { // Mapped11: 26
									ret = cp - 0x1D46F;
								} else if (cp >= 0x1D4EA && cp <= 0x1D503) { // Mapped11: 26
									ret = cp - 0x1D489;
								}
							}
						}
					}
				} else {
					if (cp <= 0x1D621) {
						if (cp <= 0x1D550) {
							if (cp <= 0x1D51C) {
								if (cp >= 0x1D507 && cp <= 0x1D50A) { // Mapped11: 4
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D50D && cp <= 0x1D514) { // Mapped11: 8
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D516 && cp <= 0x1D51C) { // Mapped11: 7
									ret = cp - 0x1D4A3;
								}
							} else {
								if (cp >= 0x1D51E && cp <= 0x1D537) { // Mapped11: 26
									ret = cp - 0x1D4BD;
								} else if (cp >= 0x1D53B && cp <= 0x1D53E) { // Mapped11: 4
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D540 && cp <= 0x1D544) { // Mapped11: 5
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D54A && cp <= 0x1D550) { // Mapped11: 7
									ret = cp - 0x1D4D7;
								}
							}
						} else {
							if (cp <= 0x1D5B9) {
								if (cp >= 0x1D552 && cp <= 0x1D56B) { // Mapped11: 26
									ret = cp - 0x1D4F1;
								} else if (cp >= 0x1D56C && cp <= 0x1D585) { // Mapped11: 26
									ret = cp - 0x1D50B;
								} else if (cp >= 0x1D586 && cp <= 0x1D59F) { // Mapped11: 26
									ret = cp - 0x1D525;
								} else if (cp >= 0x1D5A0 && cp <= 0x1D5B9) { // Mapped11: 26
									ret = cp - 0x1D53F;
								}
							} else {
								if (cp >= 0x1D5BA && cp <= 0x1D5D3) { // Mapped11: 26
									ret = cp - 0x1D559;
								} else if (cp >= 0x1D5D4 && cp <= 0x1D5ED) { // Mapped11: 26
									ret = cp - 0x1D573;
								} else if (cp >= 0x1D5EE && cp <= 0x1D607) { // Mapped11: 26
									ret = cp - 0x1D58D;
								} else if (cp >= 0x1D608 && cp <= 0x1D621) { // Mapped11: 26
									ret = cp - 0x1D5A7;
								}
							}
						}
					} else {
						if (cp <= 0x1D6C0) {
							if (cp <= 0x1D66F) {
								if (cp >= 0x1D622 && cp <= 0x1D63B) { // Mapped11: 26
									ret = cp - 0x1D5C1;
								} else if (cp >= 0x1D63C && cp <= 0x1D655) { // Mapped11: 26
									ret = cp - 0x1D5DB;
								} else if (cp >= 0x1D656 && cp <= 0x1D66F) { // Mapped11: 26
									ret = cp - 0x1D5F5;
								}
							} else {
								if (cp >= 0x1D670 && cp <= 0x1D689) { // Mapped11: 26
									ret = cp - 0x1D60F;
								} else if (cp >= 0x1D68A && cp <= 0x1D6A3) { // Mapped11: 26
									ret = cp - 0x1D629;
								} else if (cp >= 0x1D6A8 && cp <= 0x1D6B8) { // Mapped11: 17
									ret = cp - 0x1D2F7;
								} else if (cp >= 0x1D6BA && cp <= 0x1D6C0) { // Mapped11: 7
									ret = cp - 0x1D2F7;
								}
							}
						} else {
							if (cp <= 0x1D6FA) {
								if (cp >= 0x1D6C2 && cp <= 0x1D6D2) { // Mapped11: 17
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6D4 && cp <= 0x1D6DA) { // Mapped11: 7
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6E2 && cp <= 0x1D6F2) { // Mapped11: 17
									ret = cp - 0x1D331;
								} else if (cp >= 0x1D6F4 && cp <= 0x1D6FA) { // Mapped11: 7
									ret = cp - 0x1D331;
								}
							} else {
								if (cp >= 0x1D6FC && cp <= 0x1D70C) { // Mapped11: 17
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D70E && cp <= 0x1D714) { // Mapped11: 7
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D71C && cp <= 0x1D72C) { // Mapped11: 17
									ret = cp - 0x1D36B;
								} else if (cp >= 0x1D72E && cp <= 0x1D734) { // Mapped11: 7
									ret = cp - 0x1D36B;
								}
							}
						}
					}
				}
			}
		} else {
			if (cp <= 0xFB69) {
				if (cp <= 0x1DB) {
					if (cp <= 0x1D7F5) {
						if (cp <= 0x1D7A0) {
							if (cp <= 0x1D766) {
								if (cp >= 0x1D736 && cp <= 0x1D746) { // Mapped11: 17
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D748 && cp <= 0x1D74E) { // Mapped11: 7
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D756 && cp <= 0x1D766) { // Mapped11: 17
									ret = cp - 0x1D3A5;
								}
							} else {
								if (cp >= 0x1D768 && cp <= 0x1D76E) { // Mapped11: 7
									ret = cp - 0x1D3A5;
								} else if (cp >= 0x1D770 && cp <= 0x1D780) { // Mapped11: 17
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D782 && cp <= 0x1D788) { // Mapped11: 7
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D790 && cp <= 0x1D7A0) { // Mapped11: 17
									ret = cp - 0x1D3DF;
								}
							}
						} else {
							if (cp <= 0x1D7C2) {
								if (cp >= 0x1D7A2 && cp <= 0x1D7A8) { // Mapped11: 7
									ret = cp - 0x1D3DF;
								} else if (cp >= 0x1D7AA && cp <= 0x1D7BA) { // Mapped11: 17
									ret = cp - 0x1D3F9;
								} else if (cp >= 0x1D7BC && cp <= 0x1D7C2) { // Mapped11: 7
									ret = cp - 0x1D3F9;
								}
							} else {
								if (cp >= 0x1D7CE && cp <= 0x1D7D7) { // Mapped11: 10
									ret = cp - 0x1D79E;
								} else if (cp >= 0x1D7D8 && cp <= 0x1D7E1) { // Mapped11: 10
									ret = cp - 0x1D7A8;
								} else if (cp >= 0x1D7E2 && cp <= 0x1D7EB) { // Mapped11: 10
									ret = cp - 0x1D7B2;
								} else if (cp >= 0x1D7EC && cp <= 0x1D7F5) { // Mapped11: 10
									ret = cp - 0x1D7BC;
								}
							}
						}
					} else {
						if (cp <= 0x1F149) {
							if (cp <= 0x1EE0D) {
								if (cp >= 0x1D7F6 && cp <= 0x1D7FF) { // Mapped11: 10
									ret = cp - 0x1D7C6;
								} else if (cp >= 0x1E900 && cp <= 0x1E921) { // Mapped11: 34
									ret = cp + 0x22;
								} else if (cp >= 0x1EE0A && cp <= 0x1EE0D) { // Mapped11: 4
									ret = cp - 0x1E7C7;
								}
							} else {
								if (cp >= 0x1EE2A && cp <= 0x1EE2D) { // Mapped11: 4
									ret = cp - 0x1E7E7;
								} else if (cp >= 0x1EE8B && cp <= 0x1EE8D) { // Mapped11: 3
									ret = cp - 0x1E847;
								} else if (cp >= 0x1EEAB && cp <= 0x1EEAD) { // Mapped11: 3
									ret = cp - 0x1E867;
								} else if (cp >= 0x1F130 && cp <= 0x1F149) { // Mapped11: 26
									ret = cp - 0x1F0CF;
								}
							}
						} else {
							if (cp <= 0x147) {
								if (cp >= 0x1FBF0 && cp <= 0x1FBF9) { // Mapped11: 10
									ret = cp - 0x1FBC0;
								} else if (cp >= 0x100 && cp < 0x130 && (cp & 1 == 0)) { // Mapped22: 24
									ret = cp + 1;
								} else if (cp >= 0x139 && cp < 0x13F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x141 && cp < 0x149 && (cp & 1 == 0)) { // Mapped22: 4
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x14A && cp < 0x178 && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0x179 && cp < 0x17F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1A0 && cp < 0x1A6 && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1CD && cp < 0x1DD && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								}
							}
						}
					}
				} else {
					if (cp <= 0xA69A) {
						if (cp <= 0x4BE) {
							if (cp <= 0x232) {
								if (cp >= 0x1DE && cp < 0x1F0 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								} else if (cp >= 0x1F8 && cp < 0x220 && (cp & 1 == 0)) { // Mapped22: 20
									ret = cp + 1;
								} else if (cp >= 0x222 && cp < 0x234 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x246 && cp < 0x250 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								} else if (cp >= 0x3D8 && cp < 0x3F0 && (cp & 1 == 0)) { // Mapped22: 12
									ret = cp + 1;
								} else if (cp >= 0x460 && cp < 0x482 && (cp & 1 == 0)) { // Mapped22: 17
									ret = cp + 1;
								} else if (cp >= 0x48A && cp < 0x4C0 && (cp & 1 == 0)) { // Mapped22: 27
									ret = cp + 1;
								}
							}
						} else {
							if (cp <= 0x1EFE) {
								if (cp >= 0x4C1 && cp < 0x4CF && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0x4D0 && cp < 0x530 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								} else if (cp >= 0x1E00 && cp < 0x1E96 && (cp & 1 == 0)) { // Mapped22: 75
									ret = cp + 1;
								} else if (cp >= 0x1EA0 && cp < 0x1F00 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x2C67 && cp < 0x2C6D && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x2C80 && cp < 0x2CE4 && (cp & 1 == 0)) { // Mapped22: 50
									ret = cp + 1;
								} else if (cp >= 0xA640 && cp < 0xA66E && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0xA680 && cp < 0xA69C && (cp & 1 == 0)) { // Mapped22: 14
									ret = cp + 1;
								}
							}
						}
					} else {
						if (cp <= 0x210E) {
							if (cp <= 0xA786) {
								if (cp >= 0xA722 && cp < 0xA730 && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0xA732 && cp < 0xA770 && (cp & 1 == 0)) { // Mapped22: 31
									ret = cp + 1;
								} else if (cp >= 0xA77E && cp < 0xA788 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								}
							} else {
								if (cp >= 0xA796 && cp < 0xA7AA && (cp & 1 == 0)) { // Mapped22: 10
									ret = cp + 1;
								} else if (cp >= 0xA7B4 && cp < 0xA7C4 && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								} else if (cp >= 0x2010 && cp <= 0x2015) { // Mapped10: 6
									ret = 0x2D;
								} else if (cp >= 0x210B && cp <= 0x210E) { // Mapped10: 4
									ret = 0x68;
								}
							}
						} else {
							if (cp <= 0xFB59) {
								if (cp >= 0x211B && cp <= 0x211D) { // Mapped10: 3
									ret = 0x72;
								} else if (cp >= 0x23BA && cp <= 0x23BD) { // Mapped10: 4
									ret = 0x2D;
								} else if (cp >= 0xFB52 && cp <= 0xFB55) { // Mapped10: 4
									ret = 0x67B;
								} else if (cp >= 0xFB56 && cp <= 0xFB59) { // Mapped10: 4
									ret = 0x67E;
								}
							} else {
								if (cp >= 0xFB5A && cp <= 0xFB5D) { // Mapped10: 4
									ret = 0x680;
								} else if (cp >= 0xFB5E && cp <= 0xFB61) { // Mapped10: 4
									ret = 0x67A;
								} else if (cp >= 0xFB62 && cp <= 0xFB65) { // Mapped10: 4
									ret = 0x67F;
								} else if (cp >= 0xFB66 && cp <= 0xFB69) { // Mapped10: 4
									ret = 0x679;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0xFECC) {
					if (cp <= 0xFBE7) {
						if (cp <= 0xFB91) {
							if (cp <= 0xFB75) {
								if (cp >= 0xFB6A && cp <= 0xFB6D) { // Mapped10: 4
									ret = 0x6A4;
								} else if (cp >= 0xFB6E && cp <= 0xFB71) { // Mapped10: 4
									ret = 0x6A6;
								} else if (cp >= 0xFB72 && cp <= 0xFB75) { // Mapped10: 4
									ret = 0x684;
								}
							} else {
								if (cp >= 0xFB76 && cp <= 0xFB79) { // Mapped10: 4
									ret = 0x683;
								} else if (cp >= 0xFB7A && cp <= 0xFB7D) { // Mapped10: 4
									ret = 0x686;
								} else if (cp >= 0xFB7E && cp <= 0xFB81) { // Mapped10: 4
									ret = 0x687;
								} else if (cp >= 0xFB8E && cp <= 0xFB91) { // Mapped10: 4
									ret = 0x6A9;
								}
							}
						} else {
							if (cp <= 0xFBA3) {
								if (cp >= 0xFB92 && cp <= 0xFB95) { // Mapped10: 4
									ret = 0x6AF;
								} else if (cp >= 0xFB96 && cp <= 0xFB99) { // Mapped10: 4
									ret = 0x6B3;
								} else if (cp >= 0xFB9A && cp <= 0xFB9D) { // Mapped10: 4
									ret = 0x6B1;
								} else if (cp >= 0xFBA0 && cp <= 0xFBA3) { // Mapped10: 4
									ret = 0x6BB;
								}
							} else {
								if (cp >= 0xFBA6 && cp <= 0xFBA9) { // Mapped10: 4
									ret = 0x6C1;
								} else if (cp >= 0xFBAA && cp <= 0xFBAD) { // Mapped10: 4
									ret = 0x6BE;
								} else if (cp >= 0xFBD3 && cp <= 0xFBD6) { // Mapped10: 4
									ret = 0x6AD;
								} else if (cp >= 0xFBE4 && cp <= 0xFBE7) { // Mapped10: 4
									ret = 0x6D0;
								}
							}
						}
					} else {
						if (cp <= 0xFEA4) {
							if (cp <= 0xFE92) {
								if (cp >= 0xFBFC && cp <= 0xFBFF) { // Mapped10: 4
									ret = 0x6CC;
								} else if (cp >= 0xFE89 && cp <= 0xFE8C) { // Mapped10: 4
									ret = 0x626;
								} else if (cp >= 0xFE8F && cp <= 0xFE92) { // Mapped10: 4
									ret = 0x628;
								}
							} else {
								if (cp >= 0xFE95 && cp <= 0xFE98) { // Mapped10: 4
									ret = 0x62A;
								} else if (cp >= 0xFE99 && cp <= 0xFE9C) { // Mapped10: 4
									ret = 0x62B;
								} else if (cp >= 0xFE9D && cp <= 0xFEA0) { // Mapped10: 4
									ret = 0x62C;
								} else if (cp >= 0xFEA1 && cp <= 0xFEA4) { // Mapped10: 4
									ret = 0x62D;
								}
							}
						} else {
							if (cp <= 0xFEBC) {
								if (cp >= 0xFEA5 && cp <= 0xFEA8) { // Mapped10: 4
									ret = 0x62E;
								} else if (cp >= 0xFEB1 && cp <= 0xFEB4) { // Mapped10: 4
									ret = 0x633;
								} else if (cp >= 0xFEB5 && cp <= 0xFEB8) { // Mapped10: 4
									ret = 0x634;
								} else if (cp >= 0xFEB9 && cp <= 0xFEBC) { // Mapped10: 4
									ret = 0x635;
								}
							} else {
								if (cp >= 0xFEBD && cp <= 0xFEC0) { // Mapped10: 4
									ret = 0x636;
								} else if (cp >= 0xFEC1 && cp <= 0xFEC4) { // Mapped10: 4
									ret = 0x637;
								} else if (cp >= 0xFEC5 && cp <= 0xFEC8) { // Mapped10: 4
									ret = 0x638;
								} else if (cp >= 0xFEC9 && cp <= 0xFECC) { // Mapped10: 4
									ret = 0x639;
								}
							}
						}
					}
				} else {
					if (cp <= 0xD7A3) {
						if (cp <= 0xFEE8) {
							if (cp <= 0xFED8) {
								if (cp >= 0xFECD && cp <= 0xFED0) { // Mapped10: 4
									ret = 0x63A;
								} else if (cp >= 0xFED1 && cp <= 0xFED4) { // Mapped10: 4
									ret = 0x641;
								} else if (cp >= 0xFED5 && cp <= 0xFED8) { // Mapped10: 4
									ret = 0x642;
								}
							} else {
								if (cp >= 0xFED9 && cp <= 0xFEDC) { // Mapped10: 4
									ret = 0x643;
								} else if (cp >= 0xFEDD && cp <= 0xFEE0) { // Mapped10: 4
									ret = 0x644;
								} else if (cp >= 0xFEE1 && cp <= 0xFEE4) { // Mapped10: 4
									ret = 0x645;
								} else if (cp >= 0xFEE5 && cp <= 0xFEE8) { // Mapped10: 4
									ret = 0x646;
								}
							}
						} else {
							if (cp <= 0x167F) {
								if (cp >= 0xFEE9 && cp <= 0xFEEC) { // Mapped10: 4
									ret = 0x647;
								} else if (cp >= 0xFEF1 && cp <= 0xFEF4) { // Mapped10: 4
									ret = 0x64A;
								} else if (cp >= 0x2F831 && cp <= 0x2F833) { // Mapped10: 3
									ret = 0x537F;
								} else if (cp >= 0x1400 && cp <= 0x167F) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2801 && cp <= 0x2933) { // Valid
									ret = cp;
								} else if (cp >= 0x3400 && cp <= 0xA48C) { // Valid
									ret = cp;
								} else if (cp >= 0xA4D0 && cp <= 0xA62B) { // Valid
									ret = cp;
								} else if (cp >= 0xAC00 && cp <= 0xD7A3) { // Valid
									ret = cp;
								}
							}
						}
					} else {
						if (cp <= 0x18CD5) {
							if (cp <= 0x1342E) {
								if (cp >= 0x10600 && cp <= 0x10736) { // Valid
									ret = cp;
								} else if (cp >= 0x11FFF && cp <= 0x12399) { // Valid
									ret = cp;
								} else if (cp >= 0x13000 && cp <= 0x1342E) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x14400 && cp <= 0x14646) { // Valid
									ret = cp;
								} else if (cp >= 0x16800 && cp <= 0x16A38) { // Valid
									ret = cp;
								} else if (cp >= 0x17000 && cp <= 0x187F7) { // Valid
									ret = cp;
								} else if (cp >= 0x18800 && cp <= 0x18CD5) { // Valid
									ret = cp;
								}
							}
						} else {
							if (cp <= 0x2A6DF) {
								if (cp >= 0x1B000 && cp <= 0x1B122) { // Valid
									ret = cp;
								} else if (cp >= 0x1B170 && cp <= 0x1B2FB) { // Valid
									ret = cp;
								} else if (cp >= 0x1D800 && cp <= 0x1DA8B) { // Valid
									ret = cp;
								} else if (cp >= 0x20000 && cp <= 0x2A6DF) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2A700 && cp <= 0x2B738) { // Valid
									ret = cp;
								} else if (cp >= 0x2B820 && cp <= 0x2CEA1) { // Valid
									ret = cp;
								} else if (cp >= 0x2CEB0 && cp <= 0x2EBE0) { // Valid
									ret = cp;
								} else if (cp >= 0x30000 && cp <= 0x3134A) { // Valid
									ret = cp;
								}
							}
						}
					}
				}
			}
		}
	}
}"
    },
    "hardhat/console.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    },
    "@openzeppelin/contracts/security/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
"
    },
    "solady/src/utils/LibString.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                         CONSTANTS                          */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = type(uint256).max;

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                     DECIMAL OPERATIONS                     */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                   HEXADECIMAL OPERATIONS                   */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        str = toHexStringNoPrefix(value, length);
        /// @solidity memory-safe-assembly
        assembly {
            let strLength := add(mload(str), 2) // Compute the length.
            mstore(str, 0x3078) // Write the "0x" prefix.
            str := sub(str, 2) // Move the pointer.
            mstore(str, strLength) // Write the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := sub(end, str)
            // Move the pointer and write the length.
            str := sub(str, 0x20)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        str = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let strLength := add(mload(str), 2) // Compute the length.
            mstore(str, 0x3078) // Write the "0x" prefix.
            str := sub(str, 2) // Move the pointer.
            mstore(str, strLength) // Write the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2` bytes.
    function toHexStringNoPrefix(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := sub(end, str)
            // Move the pointer and write the length.
            str := sub(str, 0x20)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x", encoded using 2 hexadecimal digits per byte,
    /// and the alphabets are capitalized conditionally according to
    /// https://eips.ethereum.org/EIPS/eip-55
    function toHexStringChecksumed(address value) internal pure returns (string memory str) {
        str = toHexString(value);
        /// @solidity memory-safe-assembly
        assembly {
            let mask := shl(6, div(not(0), 255)) // `0b010000000100000000 ...`
            let o := add(str, 0x22)
            let hashed := and(keccak256(o, 40), mul(34, mask)) // `0b10001000 ... `
            let t := shl(240, 136) // `0b10001000 << 240`
            // prettier-ignore
            for { let i := 0 } 1 {} {
                mstore(add(i, i), mul(t, byte(i, hashed)))
                i := add(i, 1)
                // prettier-ignore
                if eq(i, 20) { break }
            }
            mstore(o, xor(mload(o), shr(1, and(mload(0x00), and(mload(o), mask)))))
            o := add(o, 0x20)
            mstore(o, xor(mload(o), shr(1, and(mload(0x20), and(mload(o), mask)))))
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        str = toHexStringNoPrefix(value);
        /// @solidity memory-safe-assembly
        assembly {
            let strLength := add(mload(str), 2) // Compute the length.
            mstore(str, 0x3078) // Write the "0x" prefix.
            str := sub(str, 2) // Move the pointer.
            mstore(str, strLength) // Write the length.
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is encoded using 2 hexadecimal digits per byte.
    function toHexStringNoPrefix(address value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            str := mload(0x40)

            // Allocate the memory.
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x28) is 0x80.
            mstore(0x40, add(str, 0x80))

            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            str := add(str, 2)
            mstore(str, 40)

            let o := add(str, 0x20)
            mstore(add(o, 40), 0)

            value := shl(96, value)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let i := 0 } 1 {} {
                let p := add(o, add(i, i))
                let temp := byte(i, value)
                mstore8(add(p, 1), mload(and(temp, 15)))
                mstore8(p, mload(shr(4, temp)))
                i := add(i, 1)
                // prettier-ignore
                if eq(i, 20) { break }
            }
        }
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                   RUNE STRING OPERATIONS                   */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Returns the number of UTF characters in the string.
    function runeCount(string memory s) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(s) {
                mstore(0x00, div(not(0), 255))
                mstore(0x20, 0x0202020202020202020202020202020202020202020202020303030304040506)
                let o := add(s, 0x20)
                let end := add(o, mload(s))
                // prettier-ignore
                for { result := 1 } 1 { result := add(result, 1) } {
                    o := add(o, byte(0, mload(shr(250, mload(o)))))
                    // prettier-ignore
                    if iszero(lt(o, end)) { break }
                }
            }
        }
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                   BYTE STRING OPERATIONS                   */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurrences of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(
        string memory subject,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                let w := not(31)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), w) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), w)))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(31)
            let indexPtr := add(indices, 0x20)
            let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
            mstore(add(indicesEnd, w), mload(subject))
            mstore(indices, add(mload(indices), 1))
            let prevIndex := 0
            // prettier-ignore
            for {} 1 {} {
                let index := mload(indexPtr)
                mstore(indexPtr, 0x60)                        
                if iszero(eq(index, prevIndex)) {
                    let element := mload(0x40)
                    let elementLength := sub(index, prevIndex)
                    mstore(element, elementLength)
                    // Copy the `subject` one word at a time, backwards.
                    // prettier-ignore
                    for { let o := and(add(elementLength, 31), w) } 1 {} {
                        mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                        o := add(o, w) // `sub(o, 0x20)`.
                        // prettier-ignore
                        if iszero(o) { break }
                    }
                    // Zeroize the slot after the string.
                    mstore(add(add(element, 0x20), elementLength), 0)
                    // Allocate memory for the length and the bytes,
                    // rounded up to a multiple of 32.
                    mstore(0x40, add(element, and(add(elementLength, 63), w)))
                    // Store the `element` into the array.
                    mstore(indexPtr, element)                        
                }
                prevIndex := add(index, mload(delimiter))
                indexPtr := add(indexPtr, 0x20)
                // prettier-ignore
                if iszero(lt(indexPtr, indicesEnd)) { break }
            }
            result := indices
            if iszero(mload(delimiter)) {
                result := add(indices, 0x20)
                mstore(result, sub(mload(indices), 2))
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(31)
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), w) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), w) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), w))
        }
    }

    /// @dev Returns a copy of the string in either lowercase or UPPERCASE.
    function toCase(string memory subject, bool toUpper) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(subject)
            if length {
                result := add(mload(0x40), 0x20)
                subject := add(subject, 1)
                let flags := shl(add(70, shl(5, toUpper)), 67108863)
                let w := not(0)
                // prettier-ignore
                for { let o := length } 1 {} {
                    o := add(o, w)
                    let b := and(0xff, mload(add(subject, o)))
                    mstore8(add(result, o), xor(b, and(shr(b, flags), 0x20)))
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Restore the result.
                result := mload(0x40)
                // Stores the string length.
                mstore(result, length)
                // Zeroize the slot after the string.
                let last := add(add(result, 0x20), length)
                mstore(last, 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, and(add(last, 31), not(31)))
            }
        }
    }

    /// @dev Returns a lowercased copy of the string.
    function lower(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, false);
    }

    /// @dev Returns an UPPERCASED copy of the string.
    function upper(string memory subject) internal pure returns (string memory result) {
        result = toCase(subject, true);
    }

    /// @dev Escapes the string to be used within HTML tags.
    function escapeHTML(string memory s) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {
                let end := add(s, mload(s))
                result := add(mload(0x40), 0x20)
                // Store the bytes of the packed offsets and strides into the scratch space.
                // `packed = (stride << 5) | offset`. Max offset is 20. Max stride is 6.
                mstore(0x1f, 0x900094)
                mstore(0x08, 0xc0000000a6ab)
                // Store "&quot;&amp;&#39;&lt;&gt;" into the scratch space.
                mstore(0x00, shl(64, 0x2671756f743b26616d703b262333393b266c743b2667743b))
            } iszero(eq(s, end)) {} {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                // Not in `["\"","'","&","<",">"]`.
                if iszero(and(shl(c, 1), 0x500000c400000000)) { 
                    mstore8(result, c)
                    result := add(result, 1)
                    continue    
                }
                let t := shr(248, mload(c))
                mstore(result, mload(and(t, 31)))
                result := add(result, shr(5, t))
            }
            let last := result
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Restore the result to the start of the free memory.
            result := mload(0x40)
            // Store the length of the result.
            mstore(result, sub(last, add(result, 0x20)))
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Escapes the string to be used within double-quotes in a JSON.
    function escapeJSON(string memory s) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {
                let end := add(s, mload(s))
                result := add(mload(0x40), 0x20)
                // Store "\\u0000" in scratch space.
                // Store "0123456789abcdef" in scratch space.
                // Also, store `{0x08:"b", 0x09:"t", 0x0a:"n", 0x0c:"f", 0x0d:"r"}`.
                // into the scratch space.
                mstore(0x15, 0x5c75303030303031323334353637383961626364656662746e006672)
                // Bitmask for detecting `["\"","\\"]`.
                let e := or(shl(0x22, 1), shl(0x5c, 1))
            } iszero(eq(s, end)) {} {
                s := add(s, 1)
                let c := and(mload(s), 0xff)
                if iszero(lt(c, 0x20)) {
                    if iszero(and(shl(c, 1), e)) { // Not in `["\"","\\"]`.
                        mstore8(result, c)
                        result := add(result, 1)
                        continue    
                    }
                    mstore8(result, 0x5c) // "\\".
                    mstore8(add(result, 1), c) 
                    result := add(result, 2)
                    continue
                }
                if iszero(and(shl(c, 1), 0x3700)) { // Not in `["\b","\t","\n","\f","\d"]`.
                    mstore8(0x1d, mload(shr(4, c))) // Hex value.
                    mstore8(0x1e, mload(and(c, 15))) // Hex value.
                    mstore(result, mload(0x19)) // "\\u00XX".
                    result := add(result, 6)    
                    continue
                }
                mstore8(result, 0x5c) // "\\".
                mstore8(add(result, 1), mload(add(c, 8)))
                result := add(result, 2)
            }
            let last := result
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Restore the result to the start of the free memory.
            result := mload(0x40)
            // Store the length of the result.
            mstore(result, sub(last, add(result, 0x20)))
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Returns whether `a` equals `b`.
    function eq(string memory a, string memory b) internal pure returns (bool result) {
        assembly {
            result := eq(keccak256(add(a, 0x20), mload(a)), keccak256(add(b, 0x20), mload(b)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Assumes that the string does not start from the scratch space.
            let retStart := sub(a, 0x20)
            let retSize := add(mload(a), 0x40)
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(retStart, retSize), 0)
            // Store the return offset.
            mstore(retStart, 0x20)
            // End the transaction, returning the string.
            return(retStart, retSize)
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/ethregistrar/IETHRegistrarController.sol": {
      "content": "//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "./IPriceOracle.sol";

interface IETHRegistrarController {
    function rentPrice(string memory, uint256)
        external
        returns (IPriceOracle.Price memory);

    function available(string memory) external returns (bool);

    function makeCommitment(
        string memory,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint32,
        uint64
    ) external returns (bytes32);

    function commit(bytes32) external;

    function register(
        string calldata,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint32,
        uint64
    ) external payable;

    function renew(string calldata, uint256) external payable;
}
"
    },
    "@openzeppelin/contracts/utils/introspection/IERC165.sol": {
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
    "@openzeppelin/contracts/utils/structs/EnumerableSet.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/utils/ERC20Recoverable.sol": {
      "content": "//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @notice Contract is used to recover ERC20 tokens sent to the contract by mistake.
 */

contract ERC20Recoverable is Ownable {
    /**
    @notice Recover ERC20 tokens sent to the contract by mistake.
    @dev The contract is Ownable and only the owner can call the recover function.
    @param _to The address to send the tokens to.
@param _token The address of the ERC20 token to recover
    @param _amount The amount of tokens to recover.
 */
    function recoverFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}
"
    },
    "solady/src/utils/SSTORE2.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                         WRITE LOGIC                        */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        // Note: The assembly block below does not expand the memory.
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASZIE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                         READ LOGIC                         */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, 1)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), 1, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + 1` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, 1))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, 1), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where `end + 1` or `start + 1` overflow.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, 1), size)
        }
    }
}
"
    },
    "solady/src/utils/DynamicBufferLib.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for buffers with automatic capacity resizing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DynamicBuffer.sol)
/// @author Modified from cozyco (https://github.com/samkingco/cozyco/blob/main/contracts/utils/DynamicBuffer.sol)
library DynamicBufferLib {
    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                          STRUCTS                           */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Type to represent a dynamic buffer in memory.
    /// You can directly assign to `data`, and the `append` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                         OPERATIONS                         */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Appends `data` to `buffer`.
    function append(DynamicBuffer memory buffer, bytes memory data) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                let w := not(31)
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
                // Some random prime number to multiply `capacity`, so that
                // we know that the `capacity` is for a dynamic buffer.
                // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(add(bufferData, w))

                // Extract `capacity`, and set it to 0, if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

                // Expand / Reallocate memory if required.
                // Note that we need to allocate an exta word for the length, and
                // and another extra word as a safety word (giving a total of 0x40 bytes).
                // Without the safety word, the data at the next free memory word can be overwritten,
                // because the backwards copying can exceed the buffer space used for storage.
                // prettier-ignore
                for {} iszero(lt(newBufferDataLength, capacity)) {} {
                    // Approximately double the memory with a heuristic,
                    // ensuring more than enough space for the combined data,
                    // rounding up to the next multiple of 32.
                    let newCapacity := and(add(capacity, add(or(capacity, newBufferDataLength), 32)), w)

                    // If next word after current buffer is not eligible for use.
                    if iszero(eq(mload(0x40), add(bufferData, add(0x40, capacity)))) {
                        // Set the `newBufferData` to point to the word after capacity.
                        let newBufferData := add(mload(0x40), 0x20)
                        // Reallocate the memory.
                        mstore(0x40, add(newBufferData, add(0x40, newCapacity)))
                        // Store the `newBufferData`.
                        mstore(buffer, newBufferData)
                        // Copy `bufferData` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(bufferDataLength, 32), w) } 1 {} {
                            mstore(add(newBufferData, o), mload(add(bufferData, o)))
                            o := add(o, w) // `sub(o, 0x20)`.
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Store the `capacity` multiplied by `prime` in the word before the `length`.
                        mstore(add(newBufferData, w), mul(prime, newCapacity))
                        // Assign `newBufferData` to `bufferData`.
                        bufferData := newBufferData
                        break
                    }
                    // Expand the memory.
                    mstore(0x40, add(bufferData, add(0x40, newCapacity)))
                    // Store the `capacity` multiplied by `prime` in the word before the `length`.
                    mstore(add(bufferData, w), mul(prime, newCapacity))
                    break
                }
                // Initalize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
                // Copy `data` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(mload(data), 32), w) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := add(o, w)  // `sub(o, 0x20)`.
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the word after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
                // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
    }
}
"
    },
    "solady/src/utils/SafeTransferLib.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                         CONSTANTS                          */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(
        address to,
        uint256 amount,
        uint256 gasStipend
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(
        address to,
        uint256 amount,
        uint256 gasStipend
    ) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*Â´:Â°â¢.Â°+.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°â¢.*â¢Â´.*:Ë.Â°*.Ëâ¢Â´.Â°:Â°â¢.Â°+.*â¢Â´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.â¢Â°:Â°.Â´+Ë.*Â°.Ë:*.Â´â¢*.+Â°.â¢Â°:Â´*.Â´â¢*.â¢Â°.â¢Â°:Â°.Â´:â¢ËÂ°.*Â°.Ë:*.Â´+Â°.â¢*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}
"
    },
    "contracts/IPTokenRenderer.sol": {
      "content": "pragma solidity >=0.8.4;

import "./ENS.sol";
import "./PublicResolver.sol";
import "./IPRegistrarController.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SSTORE2.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "hardhat/console.sol";

contract IPTokenRenderer is Ownable {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using LibString for *;
    
    IPRegistrarController public immutable controller;
    BaseRegistrar public immutable base;
    
    string public tokenImageBaseUrl = "https://token-image.vercel.app/api";
    string public tokenBackgroundImageBaseURL = "https://ipfs.io/ipfs/";
    
    ENS public ethEns = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    ReverseRegistrar public ethReverseResolver;
    
    function addressToEthName(address addr) public view returns (string memory) {
        bytes32 node = ethReverseResolver.node(addr);
        address resolverAddr = ethEns.resolver(node);
        
        if (resolverAddr == address(0)) return addr.toHexStringChecksumed();
        
        string memory name = PublicResolver(resolverAddr).name(node);
        
        bytes32 tldNode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes("eth"))));
        
        bytes32 forwardNode = controller._makeNode(tldNode, keccak256(bytes(name.split(".")[0])));
        
        address forwardResolver = ethEns.resolver(forwardNode);
        
        if (forwardResolver == address(0)) return addr.toHexStringChecksumed();
        
        address resolved = PublicResolver(forwardResolver).addr(forwardNode);
        
        if (resolved == addr) {
            return name;
        } else {
            return addr.toHexStringChecksumed();
        }
    }

    constructor(
        BaseRegistrar _base,
        IPRegistrarController _controller
    ) {
        base = _base;
        controller = _controller;
        
        address reverseEthRegAddress = block.chainid == 5 ?
            0xD5610A08E370051a01fdfe4bB3ddf5270af1aA48 :
            0x084b1c3C81545d370f3634392De611CaaBFf8148;
            
        ethReverseResolver = ReverseRegistrar(reverseEthRegAddress);
    }
    
    function setTokenImageBaseUrl(string calldata _tokenImageBaseUrl) public onlyOwner {
        tokenImageBaseUrl = _tokenImageBaseUrl;
    }
    
    function setTokenBackgroundImageBaseURL(string calldata _tokenBackgroundImageBaseURL) public onlyOwner {
        tokenBackgroundImageBaseURL = _tokenBackgroundImageBaseURL;
    }
    
    function stringIsASCII(string memory str) public pure returns (bool) {
        return bytes(str).length == str.runeCount();
    }
    
    function getAvatarTextRecord(uint tokenId) public view returns (string memory) {
        bytes32 node = keccak256(abi.encodePacked(controller.tldNode(), bytes32(tokenId)));
        
        TextResolver resolver = TextResolver(ENS(controller.ens()).resolver(node));
        return resolver.text(node, "avatar");
    }
    
    function getNode(uint tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(controller.tldNode(), bytes32(tokenId)));
    }
    
    function tokenImageURL(uint tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            tokenImageBaseUrl,
            "?id=", tokenId.toString(),
            "&address=", address(this).toHexString(),
            "&chainId=", block.chainid.toString()
            ));
    }
    
    function constructTokenURI(uint tokenId) external view returns (string memory) {
        require(base.exists(tokenId), "Doesn't exist");

        string memory html = tokenHTMLPage(tokenId);
        string memory labelString = controller.hashToLabelString(tokenId);
        
        bool isAscii = stringIsASCII(labelString);
        
        string memory w1 = isAscii ? "" : unicode" â ï¸";
        
        string memory w2 = isAscii ? "" : unicode" â ï¸This name contains non-ASCII characters";
        
        string memory tokenDescription = string.concat(
            "The IP Domain ", labelString, ".ip.", w2
        );
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', string.concat(labelString, ".ip", w1).escapeJSON(), '",'
                                '"description":"', tokenDescription.escapeJSON(), '",'
                                '"image":"', tokenImageURL(tokenId), '",'
                                '"owner":"', base.ownerOf(tokenId).toHexStringChecksumed(), '",'
                                '"animation_url":"data:text/html;charset=utf-8;base64,', Base64.encode(bytes(html)), '",'
                                '"attributes": ', tokenAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function tokenAttributesAsJSON(uint tokenId) public view returns (string memory) {
        require(base.exists(tokenId), "Doesn't exist");
        
        uint nameLength = controller.hashToLabelString(tokenId).runeCount();
        uint expirationTimestamp = base.nameExpires(tokenId);
        uint registeredAsOf = base.getLastTransferTimestamp(tokenId);
        
        address owner = base.ownerOf(tokenId);
        string memory ownerString = addressToEthName(owner);

        return string(abi.encodePacked(
            '[',
            '{"display_type": "date", "trait_type": "Expiration Date", "value":', expirationTimestamp.toString(), '},'
            '{"display_type": "date", "trait_type": "Registered As Of", "value":', registeredAsOf.toString(), '},'
            '{"trait_type": "Registered To", "value":"', ownerString.escapeJSON(), '"},'
            '{"display_type": "number", "trait_type":"Length", "value":', nameLength.toString(), '}'
            ']'
        ));
    }
    
    function tokenHTMLPage(uint tokenId) public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory HTMLBytes;
        
        string memory label = controller.hashToLabelString(tokenId);
        uint lastTransferTime = base.getLastTransferTimestamp(tokenId);
        address owner = base.ownerOf(tokenId);
        
        string memory bg = bytes(getAvatarTextRecord(tokenId)).length > 0
            ? string.concat("url(", tokenBackgroundImageBaseURL, getAvatarTextRecord(tokenId).escapeHTML(), ")") :
            "linear-gradient(135deg, #00728C 0%, #009CA3 50%, #00A695 100%);";
        
        string memory overlay = bytes(getAvatarTextRecord(tokenId)).length > 0 ? '<div style="width: 100%; height: 100%; position: fixed; top:0; left: 0; background:rgba(0,0,0,.2)"></div>' : "";
        
        string memory ownerString = addressToEthName(owner);
        
        HTMLBytes.append('<!DOCTYPE html><html lang="en">');
        HTMLBytes.append('<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,minimal-ui,viewport-fit=cover,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/></head>');
        HTMLBytes.append(abi.encodePacked('<body><div style="background:', bg, ';background-size: cover;color:#fff;left: 50%;top: 50%;transform: translate(-50%, -50%);position: fixed;aspect-ratio: 1 / 1;max-width: 100vmin;max-height: 100vmin;width: 100%; height: 100%;display:flex;flex-direction:column; justify-content: center; align-items:center;box-sizing:border-box"><style>*{box-sizing:border-box;margin:0;padding:0;border:0;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;overflow-wrap:break-word;overflow:hidden; word-break:break-all;user-select: none;text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.2);}'
        ,controller.allFonts(),
        '</style>', overlay, '<div style="width:84%; height:84%; top:0;left:0; z-index: 10000; display:flex; flex-direction: column; justify-content:space-between"><div style="font-size:3.6vw; line-height: 1.3;  letter-spacing: -0.03em;font-family: SatoshiBlack, sans-serif; display: flex; flex-direction:column;">',
        SSTORE2.read(controller.logoSVG()),
        '<div style="margin-top:2vh">Registered to:</div>'
        '<div style="font-family: SatoshiBold;font-size: 3.4vw; line-height: 1.3">',  ownerString.escapeHTML(), '</div>'
        '<div style="font-family: SatoshiBold; font-size: 3.4vw; line-height: 1.3">as of ', timestampToString(lastTransferTime),' UTC</div>'
        '</div>'
        '<div style="font-size:11vw; letter-spacing: -0.03em;line-height:1.2; display: flex; align-items:center; font-family: SatoshiBlack">', label.escapeHTML(), '.ip</div>'
        '</div></div>'));
        
        HTMLBytes.append('</body></html>');

        return string(HTMLBytes.data);
    }
    
    function timestampToString(uint timestamp) internal pure returns (string memory) {
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        
        return string(abi.encodePacked(
          year.toString(), "-",
          zeroPadTwoDigits(month), "-",
          zeroPadTwoDigits(day), ' at ',
            zeroPadTwoDigits(hour), ":",
            zeroPadTwoDigits(minute), ":",
            zeroPadTwoDigits(second)
        ));
    }
    
    function zeroPadTwoDigits(uint number) internal pure returns (string memory) {
        string memory numberString = number.toString();
        
        if (bytes(numberString).length < 2) {
            numberString = string(abi.encodePacked("0", numberString));
        }
        
        return numberString;
    }
}"
    },
    "contracts/ERC721PTO.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721PTO is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    struct TokenData {
        address ownerAddress;
        uint48 expiryTimestamp;
        uint48 lastTransferTimestamp;
    }

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 firstRegistrationTimestamp;
        uint64 largestExpiryTimestamp;
    }

    // Mapping from token ID to owner address
    mapping(uint256 => TokenData) internal _tokenData;

    // Mapping owner address to token count
    mapping(address => AddressData) private _addressData;

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _addressData[owner].balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
        address owner = ERC721PTO.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _tokenData[tokenId].ownerAddress;
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721PTO.ownerOf(tokenId);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");
        
        AddressData storage addressData = _addressData[to];
        TokenData storage tokenData = _tokenData[tokenId];
        
        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            addressData.balance += 1;
            addressData.numberMinted += 1;
        }

        tokenData.ownerAddress = to;
        tokenData.lastTransferTimestamp = uint48(block.timestamp);
        
        if (addressData.firstRegistrationTimestamp == 0) {
            addressData.firstRegistrationTimestamp = uint64(block.timestamp);
        }

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721PTO.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721PTO.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];
        
        AddressData storage addressData = _addressData[owner];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            addressData.balance -= 1;
        }
        delete _tokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721PTO.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721PTO.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];
        
        AddressData storage fromAddressData = _addressData[from];
        AddressData storage toAddressData = _addressData[to];
        TokenData storage tokenData = _tokenData[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            fromAddressData.balance -= 1;
            toAddressData.balance += 1;
        }
        tokenData.ownerAddress = to;
        tokenData.lastTransferTimestamp = uint48(block.timestamp);

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721PTO.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        AddressData storage fromAddressData = _addressData[from];
        AddressData storage toAddressData = _addressData[to];

        if (batchSize > 1) {
            if (from != address(0)) {
                fromAddressData.balance -= uint64(batchSize);
            }
            if (to != address(0)) {
                toAddressData.balance += uint64(batchSize);
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    function _setExpiryTimestamp(uint tokenId, uint48 expiryTimestamp) internal {
        TokenData storage tokenData = _tokenData[tokenId];
        AddressData storage addressData = _addressData[tokenData.ownerAddress];
        
        tokenData.expiryTimestamp = expiryTimestamp;
        
        if (expiryTimestamp > addressData.largestExpiryTimestamp) {
            addressData.largestExpiryTimestamp = expiryTimestamp;
        }
    }
    
    function _getExpiryTimestamp(uint tokenId) internal view returns (uint48) {
        return _tokenData[tokenId].expiryTimestamp;
    }
    
    function getLastTransferTimestamp(uint tokenId) public view returns (uint48) {
        return _tokenData[tokenId].lastTransferTimestamp;
    }

    function getNumberMinted(address owner) public view returns (uint256) {
        return _addressData[owner].numberMinted;
    }
    
    function getLargestExpiryTimestamp(address owner) public view returns (uint64) {
        return _addressData[owner].largestExpiryTimestamp;
    }
    
    function getFirstRegistrationTimestamp(address owner) public view returns (uint64) {
        return _addressData[owner].firstRegistrationTimestamp;
    }
}"
    },
    "contracts/IBaseRegistrar.sol": {
      "content": "import "./ENS.sol";
import "./IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBaseRegistrar is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(uint256 indexed id, uint256 expires);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256);

    function renew(uint256 id, uint256 duration) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}
"
    },
    "contracts/BokkyPooBahsDateTimeLibrary.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}
"
    },
    "solady/src/utils/Base64.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <brecht@loopring.org>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe) internal pure returns (string memory result) {
        result = encode(data, fileSafe, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                // prettier-ignore
                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)
                    
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMulticallable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract Multicallable is IMulticallable, ERC165 {
    function _multicall(bytes32 nodehash, bytes[] calldata data)
        internal
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            if (nodehash != bytes32(0)) {
                bytes32 txNamehash = bytes32(data[i][4:36]);
                require(
                    txNamehash == nodehash,
                    "multicall: All records must have a matching namehash"
                );
            }
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }
        return results;
    }

    // This function provides an extra security check when called
    // from priviledged contracts (such as EthRegistrarController)
    // that can set records on behalf of the node owners
    function multicallWithNodeCheck(bytes32 nodehash, bytes[] calldata data)
        external
        returns (bytes[] memory results)
    {
        return _multicall(nodehash, data);
    }

    function multicall(bytes[] calldata data)
        public
        override
        returns (bytes[] memory results)
    {
        return _multicall(bytes32(0), data);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IMulticallable).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

abstract contract ABIResolver is IABIResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => mapping(uint256 => bytes))) versionable_abis;

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes calldata data
    ) external virtual authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        versionable_abis[recordVersions[node]][node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes)
        external
        view
        virtual
        override
        returns (uint256, bytes memory)
    {
        mapping(uint256 => bytes) storage abiset = versionable_abis[
            recordVersions[node]
        ][node];

        for (
            uint256 contentType = 1;
            contentType <= contentTypes;
            contentType <<= 1
        ) {
            if (
                (contentType & contentTypes) != 0 &&
                abiset[contentType].length > 0
            ) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IABIResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IAddrResolver.sol";
import "./IAddressResolver.sol";

abstract contract AddrResolver is
    IAddrResolver,
    IAddressResolver,
    ResolverBase
{
    uint256 private constant COIN_TYPE_ETH = 60;

    mapping(uint64 => mapping(bytes32 => mapping(uint256 => bytes))) versionable_addresses;

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a)
        external
        virtual
        authorised(node)
    {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node)
        public
        view
        virtual
        override
        returns (address payable)
    {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public virtual authorised(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        versionable_addresses[recordVersions[node]][node][coinType] = a;
    }

    function addr(bytes32 node, uint256 coinType)
        public
        view
        virtual
        override
        returns (bytes memory)
    {
        return versionable_addresses[recordVersions[node]][node][coinType];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IAddrResolver).interfaceId ||
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b)
        internal
        pure
        returns (address payable a)
    {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../ResolverBase.sol";
import "./AddrResolver.sol";
import "./IInterfaceResolver.sol";

abstract contract InterfaceResolver is IInterfaceResolver, AddrResolver {
    mapping(uint64 => mapping(bytes32 => mapping(bytes4 => address))) versionable_interfaces;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(
        bytes32 node,
        bytes4 interfaceID,
        address implementer
    ) external virtual authorised(node) {
        versionable_interfaces[recordVersions[node]][node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID)
        external
        view
        virtual
        override
        returns (address)
    {
        address implementer = versionable_interfaces[recordVersions[node]][node][interfaceID];
        if (implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if (a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(
            abi.encodeWithSignature(
                "supportsInterface(bytes4)",
                type(IERC165).interfaceId
            )
        );
        if (!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 165 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(
            abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID)
        );
        if (!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IInterfaceResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/DNSResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "../../dnssec-oracle/RRUtils.sol";
import "./IDNSRecordResolver.sol";
import "./IDNSZoneResolver.sol";

abstract contract DNSResolver is
    IDNSRecordResolver,
    IDNSZoneResolver,
    ResolverBase
{
    using RRUtils for *;
    using BytesUtils for bytes;

    // Zone hashes for the domains.
    // A zone hash is an EIP-1577 content hash in binary format that should point to a
    // resource containing a single zonefile.
    // node => contenthash
    mapping(uint64 => mapping(bytes32 => bytes)) private versionable_zonehashes;

    // The records themselves.  Stored as binary RRSETs
    // node => version => name => resource => data
    mapping(uint64 => mapping(bytes32 => mapping(bytes32 => mapping(uint16 => bytes))))
        private versionable_records;

    // Count of number of entries for a given name.  Required for DNS resolvers
    // when resolving wildcards.
    // node => version => name => number of records
    mapping(uint64 => mapping(bytes32 => mapping(bytes32 => uint16)))
        private versionable_nameEntriesCount;

    /**
     * Set one or more DNS records.  Records are supplied in wire-format.
     * Records with the same node/name/resource must be supplied one after the
     * other to ensure the data is updated correctly. For example, if the data
     * was supplied:
     *     a.example.com IN A 1.2.3.4
     *     a.example.com IN A 5.6.7.8
     *     www.example.com IN CNAME a.example.com.
     * then this would store the two A records for a.example.com correctly as a
     * single RRSET, however if the data was supplied:
     *     a.example.com IN A 1.2.3.4
     *     www.example.com IN CNAME a.example.com.
     *     a.example.com IN A 5.6.7.8
     * then this would store the first A record, the CNAME, then the second A
     * record which would overwrite the first.
     *
     * @param node the namehash of the node for which to set the records
     * @param data the DNS wire format records to set
     */
    function setDNSRecords(bytes32 node, bytes calldata data)
        external
        virtual
        authorised(node)
    {
        uint16 resource = 0;
        uint256 offset = 0;
        bytes memory name;
        bytes memory value;
        bytes32 nameHash;
        uint64 version = recordVersions[node];
        // Iterate over the data to add the resource records
        for (
            RRUtils.RRIterator memory iter = data.iterateRRs(0);
            !iter.done();
            iter.next()
        ) {
            if (resource == 0) {
                resource = iter.dnstype;
                name = iter.name();
                nameHash = keccak256(abi.encodePacked(name));
                value = bytes(iter.rdata());
            } else {
                bytes memory newName = iter.name();
                if (resource != iter.dnstype || !name.equals(newName)) {
                    setDNSRRSet(
                        node,
                        name,
                        resource,
                        data,
                        offset,
                        iter.offset - offset,
                        value.length == 0,
                        version
                    );
                    resource = iter.dnstype;
                    offset = iter.offset;
                    name = newName;
                    nameHash = keccak256(name);
                    value = bytes(iter.rdata());
                }
            }
        }
        if (name.length > 0) {
            setDNSRRSet(
                node,
                name,
                resource,
                data,
                offset,
                data.length - offset,
                value.length == 0,
                version
            );
        }
    }

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(
        bytes32 node,
        bytes32 name,
        uint16 resource
    ) public view virtual override returns (bytes memory) {
        return versionable_records[recordVersions[node]][node][name][resource];
    }

    /**
     * Check if a given node has records.
     * @param node the namehash of the node for which to check the records
     * @param name the namehash of the node for which to check the records
     */
    function hasDNSRecords(bytes32 node, bytes32 name)
        public
        view
        virtual
        returns (bool)
    {
        return (versionable_nameEntriesCount[recordVersions[node]][node][
            name
        ] != 0);
    }

    /**
     * setZonehash sets the hash for the zone.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The zonehash to set
     */
    function setZonehash(bytes32 node, bytes calldata hash)
        external
        virtual
        authorised(node)
    {
        uint64 currentRecordVersion = recordVersions[node];
        bytes memory oldhash = versionable_zonehashes[currentRecordVersion][
            node
        ];
        versionable_zonehashes[currentRecordVersion][node] = hash;
        emit DNSZonehashChanged(node, oldhash, hash);
    }

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node)
        external
        view
        virtual
        override
        returns (bytes memory)
    {
        return versionable_zonehashes[recordVersions[node]][node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IDNSRecordResolver).interfaceId ||
            interfaceID == type(IDNSZoneResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function setDNSRRSet(
        bytes32 node,
        bytes memory name,
        uint16 resource,
        bytes memory data,
        uint256 offset,
        uint256 size,
        bool deleteRecord,
        uint64 version
    ) private {
        bytes32 nameHash = keccak256(name);
        bytes memory rrData = data.substring(offset, size);
        if (deleteRecord) {
            if (
                versionable_records[version][node][nameHash][resource].length !=
                0
            ) {
                versionable_nameEntriesCount[version][node][nameHash]--;
            }
            delete (versionable_records[version][node][nameHash][resource]);
            emit DNSRecordDeleted(node, name, resource);
        } else {
            if (
                versionable_records[version][node][nameHash][resource].length ==
                0
            ) {
                versionable_nameEntriesCount[version][node][nameHash]++;
            }
            versionable_records[version][node][nameHash][resource] = rrData;
            emit DNSRecordChanged(node, name, resource, rrData);
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => string)) versionable_names;

    /**
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName)
        external
        virtual
        authorised(node)
    {
        versionable_names[recordVersions[node]][node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return versionable_names[recordVersions[node]][node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(INameResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/PubkeyResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IPubkeyResolver.sol";

abstract contract PubkeyResolver is IPubkeyResolver, ResolverBase {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(uint64 => mapping(bytes32 => PublicKey)) versionable_pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an ENS node.
     * @param node The ENS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(
        bytes32 node,
        bytes32 x,
        bytes32 y
    ) external virtual authorised(node) {
        versionable_pubkeys[recordVersions[node]][node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node)
        external
        view
        virtual
        override
        returns (bytes32 x, bytes32 y)
    {
        uint64 currentRecordVersion = recordVersions[node];
        return (
            versionable_pubkeys[currentRecordVersion][node].x,
            versionable_pubkeys[currentRecordVersion][node].y
        );
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IPubkeyResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./IContentHashResolver.sol";

abstract contract ContentHashResolver is IContentHashResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => bytes)) versionable_hashes;

    /**
     * Sets the contenthash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash)
        external
        virtual
        authorised(node)
    {
        versionable_hashes[recordVersions[node]][node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node)
        external
        view
        virtual
        override
        returns (bytes memory)
    {
        return versionable_hashes[recordVersions[node]][node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IContentHashResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../ResolverBase.sol";
import "./ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(uint64 => mapping(bytes32 => mapping(string => string))) versionable_texts;

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual authorised(node) {
        versionable_texts[recordVersions[node]][node][key] = value;
        emit TextChanged(node, key, key, value);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return versionable_texts[recordVersions[node]][node][key];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(ITextResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@openzeppelin/contracts/utils/introspection/ERC165.sol": {
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
    "@ensdomains/ens-contracts/contracts/resolvers/IMulticallable.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMulticallable {
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);

    function multicallWithNodeCheck(bytes32, bytes[] calldata data)
        external
        returns (bytes[] memory results);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/ResolverBase.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./profiles/IVersionableResolver.sol";

abstract contract ResolverBase is ERC165, IVersionableResolver {
    mapping(bytes32 => uint64) public recordVersions;

    function isAuthorised(bytes32 node) internal view virtual returns (bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    /**
     * Increments the record version associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     */
    function clearRecords(bytes32 node) public virtual authorised(node) {
        recordVersions[node]++;
        emit VersionChanged(node, recordVersions[node]);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IVersionableResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IABIResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes)
        external
        view
        returns (uint256, bytes memory);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IVersionableResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IVersionableResolver {
    event VersionChanged(bytes32 indexed node, uint64 newVersion);

    function recordVersions(bytes32 node) external view returns (uint64);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IInterfaceResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(
        bytes32 indexed node,
        bytes4 indexed interfaceID,
        address implementer
    );

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID)
        external
        view
        returns (address);
}
"
    },
    "@ensdomains/ens-contracts/contracts/dnssec-oracle/RRUtils.sol": {
      "content": "pragma solidity ^0.8.4;

import "./BytesUtils.sol";
import "@ensdomains/buffer/contracts/Buffer.sol";

/**
 * @dev RRUtils is a library that provides utilities for parsing DNS resource records.
 */
library RRUtils {
    using BytesUtils for *;
    using Buffer for *;

    /**
     * @dev Returns the number of bytes in the DNS name at 'offset' in 'self'.
     * @param self The byte array to read a name from.
     * @param offset The offset to start reading at.
     * @return The length of the DNS name at 'offset', in bytes.
     */
    function nameLength(bytes memory self, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        uint256 idx = offset;
        while (true) {
            assert(idx < self.length);
            uint256 labelLen = self.readUint8(idx);
            idx += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
        }
        return idx - offset;
    }

    /**
     * @dev Returns a DNS format name at the specified offset of self.
     * @param self The byte array to read a name from.
     * @param offset The offset to start reading at.
     * @return ret The name.
     */
    function readName(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes memory ret)
    {
        uint256 len = nameLength(self, offset);
        return self.substring(offset, len);
    }

    /**
     * @dev Returns the number of labels in the DNS name at 'offset' in 'self'.
     * @param self The byte array to read a name from.
     * @param offset The offset to start reading at.
     * @return The number of labels in the DNS name at 'offset', in bytes.
     */
    function labelCount(bytes memory self, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        uint256 count = 0;
        while (true) {
            assert(offset < self.length);
            uint256 labelLen = self.readUint8(offset);
            offset += labelLen + 1;
            if (labelLen == 0) {
                break;
            }
            count += 1;
        }
        return count;
    }

    uint256 constant RRSIG_TYPE = 0;
    uint256 constant RRSIG_ALGORITHM = 2;
    uint256 constant RRSIG_LABELS = 3;
    uint256 constant RRSIG_TTL = 4;
    uint256 constant RRSIG_EXPIRATION = 8;
    uint256 constant RRSIG_INCEPTION = 12;
    uint256 constant RRSIG_KEY_TAG = 16;
    uint256 constant RRSIG_SIGNER_NAME = 18;

    struct SignedSet {
        uint16 typeCovered;
        uint8 algorithm;
        uint8 labels;
        uint32 ttl;
        uint32 expiration;
        uint32 inception;
        uint16 keytag;
        bytes signerName;
        bytes data;
        bytes name;
    }

    function readSignedSet(bytes memory data)
        internal
        pure
        returns (SignedSet memory self)
    {
        self.typeCovered = data.readUint16(RRSIG_TYPE);
        self.algorithm = data.readUint8(RRSIG_ALGORITHM);
        self.labels = data.readUint8(RRSIG_LABELS);
        self.ttl = data.readUint32(RRSIG_TTL);
        self.expiration = data.readUint32(RRSIG_EXPIRATION);
        self.inception = data.readUint32(RRSIG_INCEPTION);
        self.keytag = data.readUint16(RRSIG_KEY_TAG);
        self.signerName = readName(data, RRSIG_SIGNER_NAME);
        self.data = data.substring(
            RRSIG_SIGNER_NAME + self.signerName.length,
            data.length - RRSIG_SIGNER_NAME - self.signerName.length
        );
    }

    function rrs(SignedSet memory rrset)
        internal
        pure
        returns (RRIterator memory)
    {
        return iterateRRs(rrset.data, 0);
    }

    /**
     * @dev An iterator over resource records.
     */
    struct RRIterator {
        bytes data;
        uint256 offset;
        uint16 dnstype;
        uint16 class;
        uint32 ttl;
        uint256 rdataOffset;
        uint256 nextOffset;
    }

    /**
     * @dev Begins iterating over resource records.
     * @param self The byte string to read from.
     * @param offset The offset to start reading at.
     * @return ret An iterator object.
     */
    function iterateRRs(bytes memory self, uint256 offset)
        internal
        pure
        returns (RRIterator memory ret)
    {
        ret.data = self;
        ret.nextOffset = offset;
        next(ret);
    }

    /**
     * @dev Returns true iff there are more RRs to iterate.
     * @param iter The iterator to check.
     * @return True iff the iterator has finished.
     */
    function done(RRIterator memory iter) internal pure returns (bool) {
        return iter.offset >= iter.data.length;
    }

    /**
     * @dev Moves the iterator to the next resource record.
     * @param iter The iterator to advance.
     */
    function next(RRIterator memory iter) internal pure {
        iter.offset = iter.nextOffset;
        if (iter.offset >= iter.data.length) {
            return;
        }

        // Skip the name
        uint256 off = iter.offset + nameLength(iter.data, iter.offset);

        // Read type, class, and ttl
        iter.dnstype = iter.data.readUint16(off);
        off += 2;
        iter.class = iter.data.readUint16(off);
        off += 2;
        iter.ttl = iter.data.readUint32(off);
        off += 4;

        // Read the rdata
        uint256 rdataLength = iter.data.readUint16(off);
        off += 2;
        iter.rdataOffset = off;
        iter.nextOffset = off + rdataLength;
    }

    /**
     * @dev Returns the name of the current record.
     * @param iter The iterator.
     * @return A new bytes object containing the owner name from the RR.
     */
    function name(RRIterator memory iter) internal pure returns (bytes memory) {
        return
            iter.data.substring(
                iter.offset,
                nameLength(iter.data, iter.offset)
            );
    }

    /**
     * @dev Returns the rdata portion of the current record.
     * @param iter The iterator.
     * @return A new bytes object containing the RR's RDATA.
     */
    function rdata(RRIterator memory iter)
        internal
        pure
        returns (bytes memory)
    {
        return
            iter.data.substring(
                iter.rdataOffset,
                iter.nextOffset - iter.rdataOffset
            );
    }

    uint256 constant DNSKEY_FLAGS = 0;
    uint256 constant DNSKEY_PROTOCOL = 2;
    uint256 constant DNSKEY_ALGORITHM = 3;
    uint256 constant DNSKEY_PUBKEY = 4;

    struct DNSKEY {
        uint16 flags;
        uint8 protocol;
        uint8 algorithm;
        bytes publicKey;
    }

    function readDNSKEY(
        bytes memory data,
        uint256 offset,
        uint256 length
    ) internal pure returns (DNSKEY memory self) {
        self.flags = data.readUint16(offset + DNSKEY_FLAGS);
        self.protocol = data.readUint8(offset + DNSKEY_PROTOCOL);
        self.algorithm = data.readUint8(offset + DNSKEY_ALGORITHM);
        self.publicKey = data.substring(
            offset + DNSKEY_PUBKEY,
            length - DNSKEY_PUBKEY
        );
    }

    uint256 constant DS_KEY_TAG = 0;
    uint256 constant DS_ALGORITHM = 2;
    uint256 constant DS_DIGEST_TYPE = 3;
    uint256 constant DS_DIGEST = 4;

    struct DS {
        uint16 keytag;
        uint8 algorithm;
        uint8 digestType;
        bytes digest;
    }

    function readDS(
        bytes memory data,
        uint256 offset,
        uint256 length
    ) internal pure returns (DS memory self) {
        self.keytag = data.readUint16(offset + DS_KEY_TAG);
        self.algorithm = data.readUint8(offset + DS_ALGORITHM);
        self.digestType = data.readUint8(offset + DS_DIGEST_TYPE);
        self.digest = data.substring(offset + DS_DIGEST, length - DS_DIGEST);
    }

    function compareNames(bytes memory self, bytes memory other)
        internal
        pure
        returns (int256)
    {
        if (self.equals(other)) {
            return 0;
        }

        uint256 off;
        uint256 otheroff;
        uint256 prevoff;
        uint256 otherprevoff;
        uint256 counts = labelCount(self, 0);
        uint256 othercounts = labelCount(other, 0);

        // Keep removing labels from the front of the name until both names are equal length
        while (counts > othercounts) {
            prevoff = off;
            off = progress(self, off);
            counts--;
        }

        while (othercounts > counts) {
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            othercounts--;
        }

        // Compare the last nonequal labels to each other
        while (counts > 0 && !self.equals(off, other, otheroff)) {
            prevoff = off;
            off = progress(self, off);
            otherprevoff = otheroff;
            otheroff = progress(other, otheroff);
            counts -= 1;
        }

        if (off == 0) {
            return -1;
        }
        if (otheroff == 0) {
            return 1;
        }

        return
            self.compare(
                prevoff + 1,
                self.readUint8(prevoff),
                other,
                otherprevoff + 1,
                other.readUint8(otherprevoff)
            );
    }

    /**
     * @dev Compares two serial numbers using RFC1982 serial number math.
     */
    function serialNumberGte(uint32 i1, uint32 i2)
        internal
        pure
        returns (bool)
    {
        return int32(i1) - int32(i2) >= 0;
    }

    function progress(bytes memory body, uint256 off)
        internal
        pure
        returns (uint256)
    {
        return off + 1 + body.readUint8(off);
    }

    /**
     * @dev Computes the keytag for a chunk of data.
     * @param data The data to compute a keytag for.
     * @return The computed key tag.
     */
    function computeKeytag(bytes memory data) internal pure returns (uint16) {
        /* This function probably deserves some explanation.
         * The DNSSEC keytag function is a checksum that relies on summing up individual bytes
         * from the input string, with some mild bitshifting. Here's a Naive solidity implementation:
         *
         *     function computeKeytag(bytes memory data) internal pure returns (uint16) {
         *         uint ac;
         *         for (uint i = 0; i < data.length; i++) {
         *             ac += i & 1 == 0 ? uint16(data.readUint8(i)) << 8 : data.readUint8(i);
         *         }
         *         return uint16(ac + (ac >> 16));
         *     }
         *
         * The EVM, with its 256 bit words, is exceedingly inefficient at doing byte-by-byte operations;
         * the code above, on reasonable length inputs, consumes over 100k gas. But we can make the EVM's
         * large words work in our favour.
         *
         * The code below works by treating the input as a series of 256 bit words. It first masks out
         * even and odd bytes from each input word, adding them to two separate accumulators `ac1` and `ac2`.
         * The bytes are separated by empty bytes, so as long as no individual sum exceeds 2^16-1, we're
         * effectively summing 16 different numbers with each EVM ADD opcode.
         *
         * Once it's added up all the inputs, it has to add all the 16 bit values in `ac1` and `ac2` together.
         * It does this using the same trick - mask out every other value, shift to align them, add them together.
         * After the first addition on both accumulators, there's enough room to add the two accumulators together,
         * and the remaining sums can be done just on ac1.
         */
        unchecked {
            require(data.length <= 8192, "Long keys not permitted");
            uint256 ac1;
            uint256 ac2;
            for (uint256 i = 0; i < data.length + 31; i += 32) {
                uint256 word;
                assembly {
                    word := mload(add(add(data, 32), i))
                }
                if (i + 32 > data.length) {
                    uint256 unused = 256 - (data.length - i) * 8;
                    word = (word >> unused) << unused;
                }
                ac1 +=
                    (word &
                        0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >>
                    8;
                ac2 += (word &
                    0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF);
            }
            ac1 =
                (ac1 &
                    0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) +
                ((ac1 &
                    0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >>
                    16);
            ac2 =
                (ac2 &
                    0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) +
                ((ac2 &
                    0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >>
                    16);
            ac1 = (ac1 << 8) + ac2;
            ac1 =
                (ac1 &
                    0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) +
                ((ac1 &
                    0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >>
                    32);
            ac1 =
                (ac1 &
                    0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) +
                ((ac1 &
                    0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >>
                    64);
            ac1 =
                (ac1 &
                    0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) +
                (ac1 >> 128);
            ac1 += (ac1 >> 16) & 0xFFFF;
            return uint16(ac1);
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IDNSRecordResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(
        bytes32 indexed node,
        bytes name,
        uint16 resource,
        bytes record
    );
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(
        bytes32 node,
        bytes32 name,
        uint16 resource
    ) external view returns (bytes memory);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IDNSZoneResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(
        bytes32 indexed node,
        bytes lastzonehash,
        bytes zonehash
    );

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}
"
    },
    "@ensdomains/buffer/contracts/Buffer.sol": {
      "content": "pragma solidity ^0.8.4;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/dnssec-oracle/BytesUtils.sol": {
      "content": "pragma solidity ^0.8.4;

library BytesUtils {
    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two bytes are equal.
     * @param self The first bytes to compare.
     * @param other The second bytes to compare.
     * @return The result of the comparison.
     */
    function compare(bytes memory self, bytes memory other)
        internal
        pure
        returns (int256)
    {
        return compare(self, 0, self.length, other, 0, other.length);
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two bytes are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first bytes to compare.
     * @param offset The offset of self.
     * @param len    The length of self.
     * @param other The second bytes to compare.
     * @param otheroffset The offset of the other string.
     * @param otherlen    The length of the other string.
     * @return The result of the comparison.
     */
    function compare(
        bytes memory self,
        uint256 offset,
        uint256 len,
        bytes memory other,
        uint256 otheroffset,
        uint256 otherlen
    ) internal pure returns (int256) {
        uint256 shortest = len;
        if (otherlen < len) shortest = otherlen;

        uint256 selfptr;
        uint256 otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask;
                if (shortest > 32) {
                    mask = type(uint256).max;
                } else {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                int256 diff = int256(a & mask) - int256(b & mask);
                if (diff != 0) return diff;
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int256(len) - int256(otherlen);
    }

    /*
     * @dev Returns true if the two byte ranges are equal.
     * @param self The first byte range to compare.
     * @param offset The offset into the first byte range.
     * @param other The second byte range to compare.
     * @param otherOffset The offset into the second byte range.
     * @param len The number of bytes to compare
     * @return True if the byte ranges are equal, false otherwise.
     */
    function equals(
        bytes memory self,
        uint256 offset,
        bytes memory other,
        uint256 otherOffset,
        uint256 len
    ) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

    /*
     * @dev Returns true if the two byte ranges are equal with offsets.
     * @param self The first byte range to compare.
     * @param offset The offset into the first byte range.
     * @param other The second byte range to compare.
     * @param otherOffset The offset into the second byte range.
     * @return True if the byte ranges are equal, false otherwise.
     */
    function equals(
        bytes memory self,
        uint256 offset,
        bytes memory other,
        uint256 otherOffset
    ) internal pure returns (bool) {
        return
            keccak(self, offset, self.length - offset) ==
            keccak(other, otherOffset, other.length - otherOffset);
    }

    /*
     * @dev Compares a range of 'self' to all of 'other' and returns True iff
     *      they are equal.
     * @param self The first byte range to compare.
     * @param offset The offset into the first byte range.
     * @param other The second byte range to compare.
     * @return True if the byte ranges are equal, false otherwise.
     */
    function equals(
        bytes memory self,
        uint256 offset,
        bytes memory other
    ) internal pure returns (bool) {
        return
            self.length >= offset + other.length &&
            equals(self, offset, other, 0, other.length);
    }

    /*
     * @dev Returns true if the two byte ranges are equal.
     * @param self The first byte range to compare.
     * @param other The second byte range to compare.
     * @return True if the byte ranges are equal, false otherwise.
     */
    function equals(bytes memory self, bytes memory other)
        internal
        pure
        returns (bool)
    {
        return
            self.length == other.length &&
            equals(self, 0, other, 0, self.length);
    }

    /*
     * @dev Returns the 8-bit number at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes
     * @return The specified 8 bits of the string, interpreted as an integer.
     */
    function readUint8(bytes memory self, uint256 idx)
        internal
        pure
        returns (uint8 ret)
    {
        return uint8(self[idx]);
    }

    /*
     * @dev Returns the 16-bit number at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes
     * @return The specified 16 bits of the string, interpreted as an integer.
     */
    function readUint16(bytes memory self, uint256 idx)
        internal
        pure
        returns (uint16 ret)
    {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

    /*
     * @dev Returns the 32-bit number at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes
     * @return The specified 32 bits of the string, interpreted as an integer.
     */
    function readUint32(bytes memory self, uint256 idx)
        internal
        pure
        returns (uint32 ret)
    {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

    /*
     * @dev Returns the 32 byte value at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes
     * @return The specified 32 bytes of the string.
     */
    function readBytes32(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes32 ret)
    {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
     * @dev Returns the 32 byte value at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes
     * @return The specified 32 bytes of the string.
     */
    function readBytes20(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes20 ret)
    {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(
                mload(add(add(self, 32), idx)),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
            )
        }
    }

    /*
     * @dev Returns the n byte value at the specified index of self.
     * @param self The byte string.
     * @param idx The index into the bytes.
     * @param len The number of bytes.
     * @return The specified 32 bytes of the string.
     */
    function readBytesN(
        bytes memory self,
        uint256 idx,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)), mask)
        }
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256**(32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }
    }

    /*
     * @dev Copies a substring into a new byte string.
     * @param self The byte string to copy from.
     * @param offset The offset to start copying at.
     * @param len The number of bytes to copy.
     */
    function substring(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    // Maps characters from 0x30 to 0x7A to their base32 values.
    // 0xFF represents invalid characters in that range.
    bytes constant base32HexTable =
        hex"00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F";

    /**
     * @dev Decodes unpadded base32 data of up to one word in length.
     * @param self The data to decode.
     * @param off Offset into the string to start at.
     * @param len Number of characters to decode.
     * @return The decoded data, left aligned.
     */
    function base32HexDecodeWord(
        bytes memory self,
        uint256 off,
        uint256 len
    ) internal pure returns (bytes32) {
        require(len <= 52);

        uint256 ret = 0;
        uint8 decoded;
        for (uint256 i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint256(uint8(char)) - 0x30]);
            require(decoded <= 0x20);
            if (i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint256 bitlen = len * 5;
        if (len % 8 == 0) {
            // Multiple of 8 characters, no padding
            ret = (ret << 5) | decoded;
        } else if (len % 8 == 2) {
            // Two extra characters - 1 byte
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if (len % 8 == 4) {
            // Four extra characters - 2 bytes
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if (len % 8 == 5) {
            // Five extra characters - 3 bytes
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if (len % 8 == 7) {
            // Seven extra characters - 4 bytes
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }

    /**
     * @dev Finds the first occurrence of the byte `needle` in `self`.
     * @param self The string to search
     * @param off The offset to start searching at
     * @param len The number of bytes to search
     * @param needle The byte to search for
     * @return The offset of `needle` in `self`, or 2**256-1 if it was not found.
     */
    function find(
        bytes memory self,
        uint256 off,
        uint256 len,
        bytes1 needle
    ) internal pure returns (uint256) {
        for (uint256 idx = off; idx < off + len; idx++) {
            if (self[idx] == needle) {
                return idx;
            }
        }
        return type(uint256).max;
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/INameResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IPubkeyResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/IContentHashResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}
"
    },
    "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key,
        string value
    );

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);
}
"
    },
    "@openzeppelin/contracts/utils/Strings.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}
"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
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
    "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol": {
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
    "@openzeppelin/contracts/token/ERC721/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol": {
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
    "@openzeppelin/contracts/utils/math/Math.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // â `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // â `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol": {
      "content": "pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(address owner, address resolver)
        external
        returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}
"
    },
    "@ensdomains/ens-contracts/contracts/root/Controllable.sol": {
      "content": "pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController() {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}
"
    },
    "@ensdomains/ens-contracts/contracts/ethregistrar/IPriceOracle.sol": {
      "content": "//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return base premium tuple of base price + premium price
     */
    function price(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200,
      "details": {
        "yul": false
      }
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
    },
    "metadata": {
      "useLiteralContent": true
    },
    "libraries": {}
  }
}}