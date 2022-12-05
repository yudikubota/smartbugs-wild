{{
  "language": "Solidity",
  "sources": {
    "contracts/SweepersCompetitionVault.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import './external/gelato/OpsReady.sol';
import './interfaces/IDust.sol';
import './interfaces/INFT.sol';
import './interfaces/IRandomizer.sol';


contract SweepersCompetitionVault is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver, OpsReady {

    INFT public SWEEPERS;
    IDust public DUST;
    IRandomizer public randomizer;
    address payable public sweepersTreasury;
    address payable public legacyTreasury;

    address public admin;

    address payable public Dev;
    address payable public VRF;
    uint256 public DevFee = 0.0025 ether;
    uint256 public VRFCost = .005 ether;
    uint256 public SettlementCost = .02 ether;
    uint256 public gasLimit = 60 gwei;
    uint256 public autoSettleTimer = 3 minutes;

    uint16 public sweepersCut = 8500;
    uint16 public legacyCut = 500;
    uint16 public devCut = 1000;        

    // The competition info
    struct Comp {
        // The Token ID for the listed NFT
        uint256 tokenId;
        // The Contract Address for the listed NFT
        address contractAddress;
        // The NFT Contract Type
        bool is1155;
        // The time that the competition started
        uint32 startTime;
        // The time that the competition is scheduled to end
        uint32 endTime;
        // The entry prices for the competition
        uint256 entryPriceDust;
        uint256 entryPriceETH;
        // The tx cost to buy an entry in eth
        uint256 entryCost;
        // The total entries allowed for a competition
        uint16 entryCap;
        // The entry limit per wallet 
        uint16 entryLimit;
        // The number of entries received
        uint16 numberEntries;
        // The statuses of the competition
        bool blind;
        bool settled;
        bool failed;
        string hiddenImage;
        string openseaSlug;
    }
    mapping(uint32 => Comp) public compId;
    uint32 private currentCompId = 0;
    uint32 private currentEntryId = 0;
    uint32 public activeCompCount;
    mapping(uint32 => uint256) public ethCollected;

    struct Entries {
        address entrant;
        uint32 compId;
        bool useETH;
        bool winner;
    }
    mapping(uint32 => Entries) public entryId;
    mapping(uint32 => uint32[]) public compEntries;
    mapping(uint32 => mapping(address => uint32[])) public userEntries;
    mapping(uint32 => bool) public winnerRequested;
    mapping(uint32 => uint256) public winnerRequestedTime;
    mapping(uint32 => address) public compWinner;
    bool public mustHold;

    modifier holdsSweeper() {
        require(!mustHold || SWEEPERS.balanceOf(msg.sender) > 0, "Must hold a Sweeper");
        _;
    }

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner() || msg.sender == admin, "Sender not allowed");
        _;
    }

    modifier onlyRandomizer() {
        require(msg.sender == address(randomizer), "Sender not allowed");
        _;
    }

    event CompCreated(uint32 indexed CompId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint256 indexed TokenId, uint32 entryLimit, uint32 entryCap, uint256 entryPriceDust, uint256 entryPriceETH, bool BlindComp);
    event CompSettled(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID, address winner, uint32 winningEntryID, bool withETH);
    event CompFailed(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event CompCanceled(uint32 indexed CompId, address indexed NFTProjectAddress, uint256 tokenID);
    event EntryReceived(uint32 indexed EntryIds, uint32 indexed CompId, address sender, uint256 entryPrice, bool withETH);
    event Received(address indexed From, uint256 Amount);

    constructor(
        address _sweepers,
        address _dust,
        address payable _ops,
        IRandomizer _randomizer,
        address payable _vrf,
        address payable _legacy
    ) OpsReady(_ops) {
        DUST = IDust(_dust);
        SWEEPERS = INFT(_sweepers);
        Dev = payable(msg.sender);
        randomizer = _randomizer;
        VRF = _vrf;
        legacyTreasury = _legacy;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == this.supportsInterface.selector;
    }

    function setSweepers(address _sweepers) external onlyOwner {
        SWEEPERS = INFT(_sweepers);
    }

    function setDust(address _dust) external onlyOwner {
        DUST = IDust(_dust);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setDistribution(uint16 _sweepersCut, uint16 _legacyCut, uint16 _devCut) external onlyOwner {
        require(_sweepersCut + _legacyCut + _devCut == 10000, "Sets must equal 10,000 / 100%");
        sweepersCut = _sweepersCut;
        legacyCut = _legacyCut;
        devCut = _devCut;  
    }

    function setMustHold(bool _flag) external onlyOwner {
        mustHold = _flag;
    }

    function updateSweepersTreasury(address payable _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    function updateLegacyTreasury(address payable _treasury) external onlyOwner {
        legacyTreasury = _treasury;
    }

    function updateAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function updateSettlementParams(
        IRandomizer _randomizer, 
        address payable _vrf, 
        uint256 _vrfCost, 
        uint256 _settlementCost, 
        uint256 _gasLimit, 
        uint256 _autoSettleTimer
    ) external onlyOwner {
        randomizer = _randomizer;
        VRF = _vrf;
        VRFCost = _vrfCost;
        SettlementCost = _settlementCost;
        gasLimit = _gasLimit;
        autoSettleTimer = _autoSettleTimer;
    }

    function createComp(
        address _nftContract, 
        uint256 _tokenId, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH, 
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {

        uint32 id = currentCompId++;
        uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;

        compId[id] = Comp({
            contractAddress : _nftContract,
            tokenId : _tokenId,
            is1155 : _is1155,
            startTime : _startTime,
            endTime : _endTime,
            entryPriceDust : _entryPriceDust,
            entryPriceETH : _entryPriceETH,
            entryCap : _entryCap,
            entryLimit : _entryLimit,
            numberEntries : 0,
            entryCost : _entryCost,
            blind : false,
            settled : false,
            failed : false,
            hiddenImage : 'null',
            openseaSlug : _slug
        });
        activeCompCount++;

        if(_is1155) {
            IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        }

        emit CompCreated(id, _startTime, _endTime, _nftContract, _tokenId, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, false);
    }

    function createManyCompSameProject(
        address _nftContract, 
        uint256[] calldata _tokenIds, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint32 id = currentCompId++;
            uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;
            compId[id] = Comp({
                contractAddress : _nftContract,
                tokenId : _tokenIds[i],
                is1155 : _is1155,
                startTime : _startTime,
                endTime : _endTime,
                entryPriceDust : _entryPriceDust,
                entryPriceETH : _entryPriceETH,
                entryCap : _entryCap,
                entryLimit : _entryLimit,
                numberEntries : 0,
                entryCost : _entryCost,
                blind : false,
                settled : false,
                failed : false,
                hiddenImage : 'null',
                openseaSlug : _slug
            });
            activeCompCount++;

            if(_is1155) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i], 1, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            }

            emit CompCreated(id, _startTime, _endTime, _nftContract, _tokenIds[i], _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, false);
        }
    }

    function createBlindComp(
        address _nftContract, 
        bool _is1155, 
        uint32 _startTime, 
        uint32 _endTime, 
        string calldata _hiddenImage, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit, 
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {

        uint32 id = currentCompId++;
        uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;

        compId[id] = Comp({
            contractAddress : _nftContract,
            tokenId : 0,
            is1155 : _is1155,
            startTime : _startTime,
            endTime : _endTime,
            entryPriceDust : _entryPriceDust,
            entryPriceETH : _entryPriceETH,
            entryCap : _entryCap,
            entryLimit : _entryLimit,
            numberEntries : 0,
            entryCost : _entryCost,
            blind : true,
            settled : false,
            failed : false,
            hiddenImage : _hiddenImage,
            openseaSlug : _slug
        });
        activeCompCount++;       

        emit CompCreated(id, _startTime, _endTime, _nftContract, 0, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, true);
    }

    function createManyBlindCompSameProject(
        address _nftContract, 
        bool _is1155, 
        uint16 _numComps, 
        uint32 _startTime, 
        uint32 _endTime, 
        string calldata _hiddenImage, 
        uint256 _entryPriceDust,
        uint256 _entryPriceETH,  
        uint16 _entryCap,
        uint16 _entryLimit,
        string calldata _slug
    ) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _numComps; i++) {
            uint32 id = currentCompId++;
            uint256 _entryCost = (VRFCost + SettlementCost) / _entryCap;
            compId[id] = Comp({
                contractAddress : _nftContract,
                tokenId : 0,
                is1155 : _is1155,
                startTime : _startTime,
                endTime : _endTime,
                entryPriceDust : _entryPriceDust,
                entryPriceETH : _entryPriceETH,
                entryCap : _entryCap,
                entryLimit : _entryLimit,
                numberEntries : 0,
                entryCost : _entryCost,
                blind : true,
                settled : false,
                failed : false,
                hiddenImage : _hiddenImage,
                openseaSlug : _slug
            });
            activeCompCount++;

            emit CompCreated(id, _startTime, _endTime, _nftContract, 0, _entryLimit, _entryCap, _entryPriceDust, _entryPriceETH, true);
        }
    }

    function updateBlindComp(uint32 _id, uint256 _tokenId) external onlySweepersTreasury {
        require(compId[_id].tokenId == 0, "Comp already updated");
        compId[_id].tokenId = _tokenId;
        if(compId[_id].is1155) {
            IERC1155(compId[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
        } else {
            IERC721(compId[_id].contractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        }
        compId[_id].blind = false;
    }

    function updateBlindComp1155(uint32 _id, bool _is1155) external onlySweepersTreasury {
        compId[_id].is1155 = _is1155;
    }

    function updateBlindImage(uint32 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        compId[_id].hiddenImage = _hiddenImage;
    }

    function updateOpenseaSlug(uint32 _id, string calldata _slug) external onlySweepersTreasury {
        compId[_id].openseaSlug = _slug;
    }

    function updateCompEntryPrice(uint32 _id, uint256 _entryPriceDust, uint256 _entryPriceETH) external onlySweepersTreasury {
        compId[_id].entryPriceDust = _entryPriceDust;
        compId[_id].entryPriceETH = _entryPriceETH;
    }

    function updateCompEndTime(uint32 _id, uint32 _endTime) external onlySweepersTreasury {
        compId[_id].endTime = _endTime;
    }

    function emergencyCancelComp(uint32 _id) external onlySweepersTreasury {
        require(compStatus(_id) == 1 || compStatus(_id) == 0, 'Can only cancel active comps');
        _cancelComp(_id);
    }

    function _cancelComp(uint32 _id) private {
        compId[_id].endTime = uint32(block.timestamp);
        compId[_id].failed = true;

        uint256 entryLength = compEntries[_id].length;
        if(entryLength > 0) {
            address _entrant;
            uint256 _refundAmount;
            for(uint i = 0; i < entryLength; i++) {
                _entrant = entryId[compEntries[_id][i]].entrant;

                if(!entryId[compEntries[_id][i]].useETH) {
                    _refundAmount = compId[_id].entryPriceDust;
                    DUST.mint(_entrant, _refundAmount);
                } else {
                    _refundAmount = compId[_id].entryPriceETH;
                    payable(_entrant).transfer(_refundAmount);
                }
            }
        }

        if (!compId[_id].blind) {
            if(compId[_id].is1155) {
                IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId, 1, "");
            } else {
                IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId);
            }
        }
        emit CompCanceled(_id, address(compId[_id].contractAddress), compId[_id].tokenId);
    }

    function emergencyRescueNFT(address _nft, uint256 _tokenId, bool _is1155) external onlySweepersTreasury {
        if(_is1155) {
            IERC1155(_nft).safeTransferFrom(address(this), Dev, _tokenId, 1, "");
        } else {
            IERC721(_nft).safeTransferFrom(address(this), Dev, _tokenId);
        }
    }

    function emergencyRescueETH(uint256 amount) external onlySweepersTreasury {
        Dev.transfer(amount);
    }

    /**
     * @notice Buy a competition entry using DUST.
     */
    function buyEntryDust(uint32 _id, uint16 _numEntries) external payable holdsSweeper nonReentrant {
        require(compStatus(_id) == 1, 'Comp is not Active');
        require(block.timestamp < compId[_id].endTime, 'Comp expired');
        require(_numEntries + compId[_id].numberEntries <= compId[_id].entryCap, 'Entry cap exceeded');
        require(_numEntries + userEntries[_id][msg.sender].length <= compId[_id].entryLimit, 'Entry limit exceeded');
        require(msg.value == DevFee + (compId[_id].entryCost * _numEntries), 'Fee not covered');

        // start the automation tasks if this is the first entry
        if(compId[_id].numberEntries == 0) {
            startPickWinnerTask(_id);
        }

        uint32 _entryId;
        uint256 _entryCost = _numEntries * compId[_id].entryPriceDust;

        for(uint i = 0; i < _numEntries; i++) {
            _entryId = currentEntryId++;

            compEntries[_id].push(_entryId);
            entryId[_entryId].entrant = msg.sender;
            entryId[_entryId].compId = _id;
            entryId[_entryId].useETH = false;
            entryId[_entryId].winner = false;
            userEntries[_id][msg.sender].push(_entryId);
            emit EntryReceived(_entryId, _id, msg.sender, compId[_id].entryPriceDust, false);
        }

        compId[_id].numberEntries = compId[_id].numberEntries + _numEntries;

        DUST.burnFrom(msg.sender, _entryCost);
        
        Dev.transfer(DevFee);
    }

    /**
     * @notice Buy a competition entry using ETH.
     */
    function buyEntryETH(uint32 _id, uint16 _numEntries) external payable holdsSweeper nonReentrant {
        require(compStatus(_id) == 1, 'Comp not Active');
        require(block.timestamp < compId[_id].endTime, 'Comp expired');
        require(_numEntries + compId[_id].numberEntries <= compId[_id].entryCap, 'Cap exceeded');
        require(_numEntries + userEntries[_id][msg.sender].length <= compId[_id].entryLimit, 'Entry limit exceeded');
        require(msg.value == (compId[_id].entryCost * _numEntries) + (compId[_id].entryPriceETH * _numEntries), 'Fee not covered');

        // start the automation tasks if this is the first entry
        if(compId[_id].numberEntries == 0) {
            startPickWinnerTask(_id);
        }

        uint32 _entryId;
        uint256 _entryCost = _numEntries * compId[_id].entryPriceETH;

        for(uint i = 0; i < _numEntries; i++) {
            _entryId = currentEntryId++;

            compEntries[_id].push(_entryId);
            entryId[_entryId].entrant = msg.sender;
            entryId[_entryId].compId = _id;
            entryId[_entryId].useETH = true;
            entryId[_entryId].winner = false;
            userEntries[_id][msg.sender].push(_entryId);
            emit EntryReceived(_entryId, _id, msg.sender, compId[_id].entryPriceDust, true);
        }

        compId[_id].numberEntries = compId[_id].numberEntries + _numEntries;

        ethCollected[_id] = _entryCost;
    }

    function startPickWinnerTask(uint32 _id) internal {
        IOps(ops).createTaskNoPrepayment(
            address(this), 
            this._pickCompWinner.selector,
            address(this),
            abi.encodeWithSelector(this.canPickChecker.selector, _id),
            ETH
        );
    }

    function canPickChecker(uint32 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 2 && !winnerRequested[_id] && tx.gasprice < gasLimit);
        
        execPayload = abi.encodeWithSelector(
            this._pickCompWinner.selector,
            _id
        );
    }

    function pickCompWinner(uint32 _id) public {
        require(compStatus(_id) == 2, 'cant be settled now');
        
        if(compEntries[_id].length > 0) {
            randomizer.requestRandomWords();
            winnerRequested[_id] = true;
            winnerRequestedTime[_id] = block.timestamp;
            startSettleTask(_id);
            VRF.transfer(VRFCost);
        } else {
            winnerRequested[_id] = true;
            _settleComp(_id);
        }
    }

    function _pickCompWinner(uint32 _id) external onlyOps {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        pickCompWinner(_id);
    }

    function startSettleTask(uint32 _id) internal {
        IOps(ops).createTaskNoPrepayment(
            address(this), 
            this.autoSettleComp.selector,
            address(this),
            abi.encodeWithSelector(this.canSettleChecker.selector, _id),
            ETH
        );
    }

    function canSettleChecker(uint32 _id) 
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (compStatus(_id) == 6 && block.timestamp - winnerRequestedTime[_id] >= autoSettleTimer && tx.gasprice < gasLimit);
        
        execPayload = abi.encodeWithSelector(
            this.autoSettleComp.selector,
            _id
        );
    }

    function settleComp(uint32 _id) external {
        _settleComp(_id);
    }

    function autoSettleComp(uint32 _id) external onlyOps {
        (uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
        _transfer(fee, feeToken);

        _settleComp(_id);
    }
    
    /**
     * @notice Settle an competition, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no entries, the competition is failed and can be relisted.
     */
    function _settleComp(uint32 _id) internal {
        require(compStatus(_id) == 6, 'cant be settled now');
        require(compId[_id].tokenId != 0, 'update comp tokenID');

        compId[_id].settled = true;
        uint32 _winningEntryId;
        address _compWinner;
        if (compId[_id].numberEntries == 0) {
            compId[_id].failed = true;
            if (!compId[_id].blind) {
                if(compId[_id].is1155) {
                    IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId, 1, "");
                } else {
                    IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), Dev, compId[_id].tokenId);
                }
            }
            emit CompFailed(_id, address(compId[_id].contractAddress), compId[_id].tokenId);
        } else {
            uint256 seed = randomizer.getRandomWord();
            uint256 entryIndex = seed % compEntries[_id].length;
            _winningEntryId = compEntries[_id][entryIndex];
            _compWinner = entryId[_winningEntryId].entrant;
            compWinner[_id] = _compWinner;

            if(compId[_id].is1155) {
                IERC1155(compId[_id].contractAddress).safeTransferFrom(address(this), _compWinner, compId[_id].tokenId, 1, "");
            } else {
                IERC721(compId[_id].contractAddress).safeTransferFrom(address(this), _compWinner, compId[_id].tokenId);
            }

            if(ethCollected[_id] > 0) {
                uint256 treasuryAmount = ethCollected[_id] * sweepersCut / 10000;
                uint256 legacyAmount = ethCollected[_id] * legacyCut / 10000;
                uint256 devAmount = ethCollected[_id] * devCut / 10000;
                sweepersTreasury.transfer(treasuryAmount);
                legacyTreasury.transfer(legacyAmount);
                Dev.transfer(devAmount);
            }
        }
        activeCompCount--;
        emit CompSettled(_id, address(compId[_id].contractAddress), compId[_id].tokenId, _compWinner, _winningEntryId, entryId[_winningEntryId].useETH);
    }

    function compStatus(uint32 _id) public view returns (uint8) {
        if (winnerRequested[_id] && !compId[_id].settled) {
        return 6; // AWAITING SETTLEMENT - Winner selected and awaiting settlement    
        }
        if (block.timestamp >= compId[_id].endTime && compId[_id].tokenId == 0) {
        return 5; // AWAITING TOKENID - Comp finished
        }
        if (compId[_id].failed) {
        return 4; // FAILED - not sold by end time
        }
        if (compId[_id].settled) {
        return 3; // SUCCESS - Entrant won 
        }
        if (block.timestamp >= compId[_id].endTime || compId[_id].numberEntries == compId[_id].entryCap) {
        return 2; // AWAITING WINNER SELECTION - Comp finished
        }
        if (block.timestamp <= compId[_id].endTime && block.timestamp >= compId[_id].startTime) {
        return 1; // ACTIVE - entries enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getEntriesByCompId(uint32 _id) external view returns (uint32[] memory entryIds) {
        uint256 length = compEntries[_id].length;
        entryIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            entryIds[i] = compEntries[_id][i];
        }
    }

    function getEntriesByUser(uint32 _id, address _user) external view returns (uint32[] memory entryIds) {
        uint256 length = userEntries[_id][_user].length;
        entryIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            entryIds[i] = userEntries[_id][_user][i];
        }
    }

    function getTotalEntriesLength() external view returns (uint32) {
        return currentEntryId;
    }

    function getEntriesLengthForComp(uint32 _id) external view returns (uint256) {
        return compEntries[_id].length;
    }

    function getEntriesLengthForUser(uint32 _id, address _user) external view returns (uint256) {
        return userEntries[_id][_user].length;
    }

    function getEntryInfoByIndex(uint32 _entryId) external view returns (address _entrant, uint32 _compId, string memory _entryStatus) {
        _entrant = entryId[_entryId].entrant;
        _compId = entryId[_entryId].compId;
        if(compId[entryId[_entryId].compId].settled && entryId[_entryId].winner) {
            _entryStatus = 'won';
        } else if(compId[entryId[_entryId].compId].settled && !entryId[_entryId].winner) {
            _entryStatus = 'lost';
        } else {
            _entryStatus = 'entered';
        }
    }

    function getAllComps() external view returns (uint32[] memory comps, uint8[] memory status) {
        comps = new uint32[](currentCompId);
        status = new uint8[](currentCompId);
        for(uint32 i = 0; i < currentCompId; i++) {
            comps[i] = i;
            status[i] = compStatus(i);
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}"
    },
    "contracts/interfaces/IRandomizer.sol": {
      "content": "// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    
    function getRandomWord() external returns (uint256);
    function requestRandomWords() external;
    
}"
    },
    "contracts/interfaces/INFT.sol": {
      "content": "// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    
}"
    },
    "contracts/interfaces/IDust.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDust {
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
}"
    },
    "contracts/external/gelato/OpsReady.sol": {
      "content": "// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);
    function createTaskNoPrepayment(address _execAddress, bytes4 _execSelector, address _resolverAddress, bytes calldata _resolverData, address _feeToken) external returns (bytes32 task);
    function getFeeDetails() external view returns (uint256, address);
}

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}"
    },
    "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
"
    },
    "@openzeppelin/contracts/token/ERC1155/IERC1155.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
"
    },
    "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol": {
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
"
    },
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC721/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}
"
    },
    "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
      "runs": 500
    },
    "viaIR": true,
    "evmVersion": "istanbul",
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