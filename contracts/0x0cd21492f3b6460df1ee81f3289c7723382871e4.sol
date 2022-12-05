{{
  "language": "Solidity",
  "sources": {
    "contracts/MimicCustom/Guild/MimicologistsGuild.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import { CoreGuild } from "./CoreGuild.sol";


// Guild Genesis Calculation
// Can be any time in the past, we choose block 1 because it gives a reasonable number of cheap expeditions.
//
// ~ 1 years ago
// (block.timestamp - (60*60*24*365))
//
// Block 1
// 1438269988

// Guild Rate Calculation
//
// ~ 1 mimic / 1 eth / 1 day
//
//               target price      with 18 decimals     per 24 hours ------------------------------------------------------------]
// guildRate18 = BigNumber("1e18").multipliedBy("1e18").multipliedBy("60").multipliedBy("60").multipliedBy("24").dividedBy("1e18");
//             = 86400000000000000000000

contract MimicologistsGuild is CoreGuild {
    constructor()
        CoreGuild(1438269988, 86400000000000000000000)
        {}

    function innerLore() internal pure override returns (string memory) {
         return ""
        "MIMICS"
        "\n\n"

        "The Mimic [Mimicus Etheriensis] is a mischevious but honorable "
        "digital creature that lives deep within the ethereum blockchain."
        "\n\n"

        "Mimicologists have noted the contrast between the mimic's curious and exploratory "
        "juvenile state, and the stoic and disciplined adult state. The transition between these "
        "states being moderated by a strict ritualistic practice."
        "\n\n"

        "JUVENILE MIMICS"
        "\n\n"

        "Juvenile mimics have been observed on various Expedition()s. The young mimics "
        "are generally bright in color with flickering facial elements. When discovered, "
        "juvenile mimics are known to develop an immediate affinity to the explorer who "
        "finds them, henceforth allowing the explorer to act as the mimic's caretaker. Interestingly, "
        "all Expedition()s to date have each found one and only one juvenile mimic."
        "\n\n"

        "Juvenile mimics have been observed to playfully poke other NFTs that they are presented "
        "with from throughout the ethereum ecosystem. This immediately results in the mimic "
        "transforming to have the appearance of the poked NFT. The change in the creature's appearance "
        "can be the source of some confusion and amusement and is what gives the mimic its name."
        "\n\n"

        "A juvenile mimic that has previously poked another NFT may at a later time Relax(). This "
        "results in the mimic returning to its normal juvenile appearance."
        "\n\n"

        "A transformed mimic may also sometimes poke another NFT without first Relax()ing. "
        "This results in the mimic losing the appearance of the previous NFT and changing to have "
        "the appearance of the new NFT."
        "\n\n"

        "POKE 721"
        "\n\n"

        "In order to successfully Poke721() an ERC721 NFT, the poking mimic must be informed as to "
        "the contract address and tokenId of the NFT in question."
        "\n\n"

        "POKE 1155"
        "\n\n"

        "In order to successfully Poke1155() an ERC1155 NFT, the poking mimic must be informed as to "
        "the contract address, tokenId and the address of the owner of the NFT in question."
        "\n\n"

        "MIMIC RITES OF ADULTHOOD"
        "\n\n"

        "The second and final stage of a mimic's lifecycle is the adult stage. Transition to this "
        "stage requires the undertaking of a sacred rite that conforms to the rules and "
        "expectations of mimic society. A mimic can only undertake a rite if it has poked and not "
        "relaxed from that poke. The nature of the rite that can be performed is dependent on the nature "
        "of the poked NFT."
        "\n\n"

        "During a rite, the mimic sheds its superficial ephemeral essence, which is then reified into "
        "a mimic shield. Mimic shields are distinct objects that have a notable similarity "
        "of character to the juvenile form of mimic from whom then were crafted. Before the rite "
        "completes, the shield is presented to the owner of the poked NFT."
        "\n\n"

        "In the undertaking of the rite, the mimic's form is forever frozen to that of the poked NFT. "
        "Mimic society dictates that no other mimic may ever again poke that same NFT, and any other "
        "juvenile mimics who have already also poked the NFT will revert to thier natural appearence."
        "\n\n"

        "RITE OF 721"
        "\n\n"

        "Undertaking the RiteOf721() requires a mimic to have poked an NFT conforming to the standards "
        "commonly known as ERC721. The mimic is permanently bound to the form of that NFT and the "
        "oiner of the poked NFT is presented with the mimic's shield."
        "\n\n"

        "RITE OF 1155"
        "\n\n"

        "Undertaking the RiteOf1155() requires a mimic to have poked an NFT conforming to the standards "
        "commonly known as ERC1155. In addition, the rite must be given knowledge of the owner of "
        "the poked NFT. The mimic is permanently bound to the form of the poked NFT and the NFT owner is "
        "presented with the mimic's shield."
        "\n\n"

        "DETERMINING INFORMATION ABOUT NFTS"
        "\n\n"

        "While contract, tokenId, and ownership can sometimes be hard to determine, many mimic caretakers have had luck "
        "asking the sailors around the ports for information, it seems there is much to be learned from "
        "those who travel the open sea."
        "\n\n"

        "The Mimicologists Guild also employs a number of tokenologists who's services are made available to the "
        "public for no cost."
        "\n\n"

        "MIMIC SHIELDS"
        "\n\n"

        "Mimic Shields are rare artifacts forged during a mimic rite, and bestowed upon the owners of "
        "entangled NFTs at the rite's completion. Aside from thier A E S T H E T I C and symbolic value, shields "
        "have an additional power of aura that may be Activate()d or Deactivate()d at the discretion of the shield's "
        "holder."
        "\n\n"

        "If a shield holder would like to ward off all poking upon the NFTs in thier collection "
        "they can Activate() the aura on one or more of their shields. Mimics will refuse to poke "
        "any NFT who's owner also holds a mimic shield with an activated aura."
        "\n\n"

        "Equally, if a shield owner would like to allow mimics to poke at and entagle their NFTs in rites, either for "
        "prestige or for the prospect of acquiring more shields, the may choose to Deactivate() all of the shields in "
        "their collection. Deactivated shields will be ignored by mimics and provide no aura. Mimics will however "
        "never poke a shield itself as this is forbidden by mimic society."
        "\n\n"

        "All shields are initially deactivated when forged, and may be Activate()d and Deactivate()d without limit."
        "\n\n"

        "THE MIMICOLOGISTS GUILD"
        "\n\n"

        "The Mimicologists Guild organizes various Expedition()s to foreign lands known to be inhabited by "
        "mimics. While ships and sailors are freely supplied by the guild, there is a constraint on the available "
        "sauerkraut for stocking such voyages and hence a natural limit to the rate at which Expedition()s "
        "can be undertaken at a reasonable price. When an Expedition() is undertaken, the guild will expect "
        "an associated payment to cover the cost of sauerkraut which will vary over time."
        "\n\n"

        "For the benefit of prospective voyagers, the guild provides functionality to "
        "GetExpeditionCostInWei() at the current date and time based on the sauerkraut markets. "
        "If few Expedition()s are undertaken the cost of sauerkraut decreases and Expedition()s become "
        "cheaper to stock, and conversely if many Expedition()s are undertaken faster than the sauerkraut "
        "markets can supply them then the cost of funding Expedition()s will tend to go up."
        "\n\n"

        "NOTE: At the time of writing there is a large surplus of sauerkraut on the market. The cost of "
        "funding Expedition()s should be low until this excess stock has been consumed."
        "\n\n"

        "";
    }
}

"
    },
    "contracts/MimicCustom/Guild/CoreGuild.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import { ILore } from "../Interfaces/ILore.sol";
import { IERC721Metadata } from "../Interfaces/IERC721Metadata.sol";
import { IERC1155MetadataURI } from "../Interfaces/IERC1155MetadataURI.sol";

import { CoreMimic } from "../Mimic/CoreMimic.sol";
import { GuildOwnable } from "./GuildOwnable.sol";


contract CoreGuild is GuildOwnable, ILore {

    ////
    // Guild Data

    CoreMimic cMimic;
    address aShield;
    address aMeta;

    uint256 guildGenesis;
    uint256 guildRate18;

    ////
    // Events

    event Expedition(address indexed voyager, uint256 cost);

    ////
    // Constructor / init

    constructor(uint256 _guildGenesis, uint256 _guildRate18) {
        guildGenesis = _guildGenesis;
        guildRate18 = _guildRate18;
    }

    function init(address _mimic, address _shield, address _meta) external onlyOwner {
        require(address(cMimic) == address(0x0), "already initialized");
        cMimic = CoreMimic(_mimic);
        aShield = _shield;
        aMeta = _meta;
    }

    ////
    // Expeditions / Guild

    function guild_Expedition() public payable {
        require(cMimic.balanceOf(msg.sender) <= (cMimic.totalSupply() / 10), "gateway timeout"); // The Tourist - Chorus
        uint256 cost = guild_GetExpeditionCostInWei();
        require(msg.value >= cost, "We'll need more sauerkraut, Cap'n!");
        require(msg.value <= (cost + 2e16), "That's too much sauerkraut, Cap'n!");
        cMimic.cGuild_Mint(msg.sender);
        emit Expedition(msg.sender, msg.value);
    }

    function guild_GetExpeditionCostInWei() public view returns (uint256) {
        uint256 foundRate18 = guildRate18 * cMimic.totalSupply();
        uint256 epoch = block.timestamp - guildGenesis;
        uint256 price = foundRate18  / epoch;
        return price;
    }

    function guildmaster_Withdraw(uint256 _amount) external onlyOwnerOrActiveBackup {
        (bool success, ) = payable(msg.sender).call{ value: _amount }("");
        require(success, "nope");
    }

    ////
    // Lore / Introspection

    function lore() external view returns (string memory) {
        return string(abi.encodePacked(
            innerLore(),
            "\n",
            loreAddress("   Guild", address(this)),
            loreAddress("   Mimic", address(cMimic)),
            loreAddress("  Shield", aShield),
            loreAddress("Metadata", aMeta)
        ));
    }

    function loreAddress(string memory _name, address _address) internal pure returns (string memory) {
        return string(abi.encodePacked(_name, " Contract: 0x", string(addressToPaddedBytesHex(_address)), "\n"));
    }

    function innerLore() internal pure virtual returns (string memory) {
        return "OVERRIDE ME";
    }

    function getGuildAddress() external view returns(address) { return address(this); }
    function getMimicAddress() external view returns(address) { return address(cMimic); }
    function getShieldAddress() external view returns(address) { return aShield; }
    function getMetadataAddress() external view returns(address) { return aMeta; }

    ////
    // Tokenology

    function tokenologist_IsTokenErc721(address _tokenContract, uint _tokenId) public view returns (bool) {
        (bool uriCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", _tokenId));
        (bool ownerCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", _tokenId));

        return uriCheck && ownerCheck;
    }

    function tokenologist_IsTokenErc1155(address _tokenContract, uint _tokenId) public view returns (bool) {
        (bool uriCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("uri(uint256)", _tokenId));
        (bool ownerCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", address(0x1337), _tokenId));

        return uriCheck && ownerCheck;
    }

    function tokenologist_IdentifyTokenFormat(address _tokenContract, uint256 _tokenId) public view returns (string memory) {
        if (tokenologist_IsTokenErc721(_tokenContract, _tokenId)) {
            return "ERC721";
        }

        if (tokenologist_IsTokenErc1155(_tokenContract, _tokenId)) {
            return "ERC1155";
        }

        return "Unknown Token Format";
    }

    function tokenologist_DoesTokenUseIdReplace(address _tokenContract, uint256 _tokenId) public view returns (bool) {
        bytes memory uriBytes;
        bool success;

        (success, uriBytes) = _tokenContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", _tokenId));

        if (!success) {
            (success, uriBytes) = _tokenContract.staticcall(abi.encodeWithSignature("uri(uint256)", _tokenId));
        }

        if (!success) {
            revert("Unknown Result");
        }

        return uriIdDetect(abi.decode(uriBytes, (string)));
    }

    ////
    // Util

    function uriIdDetect(string memory uri) internal pure returns (bool) {
        bytes memory s = bytes(uri);
        uint sLen = s.length;
        if (sLen < 4) {
            return false; // can't fit "{id}
        }

        uint sLenM3 = sLen - 3;

        uint si = 0;
        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                return true;
            }
            si++;
        }

        return false;
    }

    function addressToPaddedBytesHex(address _address) internal pure returns(bytes memory) {
        bytes20 _bytes = bytes20(_address);
        bytes memory HEX = "0123456789abcdef";
        bytes memory _out = new bytes(40);
        for(uint i = 0; i < 20; i++) {
            _out[i*2] = HEX[uint8(_bytes[i] >> 4)];
            _out[1+i*2] = HEX[uint8(_bytes[i] & 0x0f)];
        }
        return _out;
    }
}

"
    },
    "contracts/MimicCustom/Interfaces/ILore.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


interface ILore {
    function lore() external view returns (string memory);
}




"
    },
    "contracts/MimicCustom/Interfaces/IERC721Metadata.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.11;

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
}
"
    },
    "contracts/MimicCustom/Interfaces/IERC1155MetadataURI.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity 0.8.11;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}
"
    },
    "contracts/MimicCustom/Mimic/CoreMimic.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import { ILore } from "../Interfaces/ILore.sol";

import { Combo721Base } from "./Combo721Base.sol";

import { MimicMeta } from "./MimicMeta.sol";
import { CoreShield } from "./CoreShield.sol";


abstract contract CoreMimic is Combo721Base {
    MimicMeta cMeta;
    CoreShield cShield;
    address aGuild;

    ////
    // Mimic Data

    mapping(uint256 => address) POKED_CONTRACTS;
    mapping(uint256 => uint256) POKED_IDS;
    mapping(uint256 => uint256) MATURITIES;
    mapping(uint256 => bool) SKIP_ID_REPLACEMENT;

    ////
    // Guild Data

    uint256 guildGenesis;
    uint256 guildPrice;
    uint256 guildRate18;

    ////
    // Events

    event Poke(uint256 indexed _mimicId, address _targetContract, uint256 _targetId);
    event Rite(uint256 indexed _mimicId);
    event SkipIdReplace(uint256 indexed _mimicId, bool _trueOrFalse);

    ////
    // Init

    function init(address _guild, address _shield, address _meta) external {
        require(aGuild == address(0x0), "already initialized");

        aGuild = _guild;
        cShield = CoreShield(_shield);
        cMeta = MimicMeta(_meta);
    }

    ////
    // Mimic Lifecycle

    function maturityHash(address _targetContract, uint256 _targetId) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked("MH", _targetContract, _targetId)));
    }

    function maturityHashForMimic(uint256 _mimicId) internal view returns (uint) {
        return maturityHash(POKED_CONTRACTS[_mimicId], POKED_IDS[_mimicId]);
    }

    function _pokeShared(uint256 _mimicId, address _targetContract, uint256 _targetId) internal {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");
        require(_targetContract != address(0x0), "that's not poking, that's pointing");
        require(_targetContract != address(this), "this would cause poor mimic to explode");
        require(_targetContract != address(cShield), "this is essence-ally a bad idea");
        uint256 mimicMatHashMimicId = MATURITIES[maturityHashForMimic(_mimicId)];
        require(mimicMatHashMimicId != _mimicId, "mature mimics won't poke");
        uint256 targetMatHashMimicId = MATURITIES[maturityHash(_targetContract, _targetId)];
        require(targetMatHashMimicId == 0x0, "mimic honor code violation");

        POKED_CONTRACTS[_mimicId] = _targetContract;
        POKED_IDS[_mimicId] = _targetId;
        emit Poke(_mimicId, _targetContract, _targetId);
    }

    function _riteShared(uint256 _mimicId) internal view returns (address pokedContract, uint256 matHash) {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        pokedContract = POKED_CONTRACTS[_mimicId];
        require(pokedContract != address(0x0), "need to poke first");
        matHash = maturityHashForMimic(_mimicId);
        uint256 matHashMimicId = MATURITIES[matHash];
        require(matHashMimicId != _mimicId, "mimic is already mature");
        require(matHashMimicId == 0x0, "mimic honor code violation");
    }

    function mimic_IsAdult(uint256 _mimicId) external view returns (bool) {
        if (_exists(_mimicId) && (MATURITIES[maturityHashForMimic(_mimicId)] == _mimicId)) {
            return true;
        }

        return false;
    }

    function mimic_Poke721(uint256 _mimicId, address _pokeNftContract, uint256 _pokeNftId) external {
        (bool success, bytes memory ownerResult) = _pokeNftContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", _pokeNftId));
        require(success, "not a valid 721");
        address owner721 = abi.decode(ownerResult, (address));
        uint256 auraCount = cShield.activeCount(owner721);
        require(auraCount == 0, "blocked by active shield");

        _pokeShared(_mimicId, _pokeNftContract, _pokeNftId);
   }

    function mimic_Poke1155(uint256 _mimicId, address _pokeNftContract, uint256 _pokeNftId, address _ownerOf1155) external {
        (bool success, bytes memory countResult) = _pokeNftContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", _ownerOf1155, _pokeNftId));
        require(success, "not a valid 1155");
        require(abi.decode(countResult, (uint256)) > 0, "not a valid owner of the NFT");
        require(cShield.activeCount(_ownerOf1155) == 0, "blocked by active shield");

        _pokeShared(_mimicId, _pokeNftContract, _pokeNftId);
    }

    function mimic_Relax(uint256 _mimicId) external {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        require(MATURITIES[maturityHashForMimic(_mimicId)] != _mimicId, "adult mimics can never relax");
        delete POKED_CONTRACTS[_mimicId];
        delete POKED_IDS[_mimicId];
        emit Poke(_mimicId, address(0x0), 0x0);
    }

    function mimic_RiteOf721(uint256 _mimicId) external {
        (address pokedContract, uint256 matHash) = _riteShared(_mimicId);

        (bool success, bytes memory ownerResult) = pokedContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", POKED_IDS[_mimicId]));
        require(success, "rite of 721 failed");

        MATURITIES[matHash] = _mimicId;

        cShield.cMimic_Mint(abi.decode(ownerResult, (address)), _mimicId);
        emit Rite(_mimicId);
    }

    function mimic_RiteOf1155(uint256 _mimicId, address _ownerOf1155) external {
        require(_ownerOf1155 != address(0x0), "nowner!");

        (address pokedContract, uint256 matHash) = _riteShared(_mimicId);

        (bool success, bytes memory ownershipCountResult) = pokedContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", _ownerOf1155, POKED_IDS[_mimicId]));
        require(success, "rite of 1155 failed");
        require(abi.decode(ownershipCountResult, (uint256)) > 0, "not the owner you're looking for");

        MATURITIES[matHash] = _mimicId;

        cShield.cMimic_Mint(_ownerOf1155, _mimicId);
        emit Rite(_mimicId);
    }

    function mimic_SkipIdReplacement(uint256 _mimicId, bool _trueOrFalse) external {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        SKIP_ID_REPLACEMENT[_mimicId] = _trueOrFalse;

        emit SkipIdReplace(_mimicId, _trueOrFalse);
    }

    ////
    // Metadata

    function tokenURI(uint256 _mimicId) public view override returns (string memory) {
        require(msg.sender.code.length == 0, "nah!");
        require(_exists(_mimicId), "no such mimic");

        address pokedContract = POKED_CONTRACTS[_mimicId];

        // juvenile mimic that has not poked
        if (pokedContract == address(0x0)) {
            return cMeta.mimicNative(_mimicId, "");  // normal eyes
        }

        uint256 pokedId = POKED_IDS[_mimicId];

        // juvenile mimic that has poked an NFT that is another mimic's maturity NFT
        uint256 matHash = maturityHash(pokedContract, pokedId);
        uint256 matHashMimicId = MATURITIES[matHash];
        if ( (matHashMimicId != _mimicId) && (matHashMimicId != 0x0) ) {
            return cMeta.mimicNative(_mimicId, "");  // normal eyes
        }

        (bool success, bytes memory uriBytes) = pokedContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", pokedId));
        // 721
        if (success) {
            if (SKIP_ID_REPLACEMENT[_mimicId]) {
                return abi.decode(uriBytes, (string));
            }

            return uriIdReplace(abi.decode(uriBytes, (string)), pokedId);
        }

        (success, uriBytes) = pokedContract.staticcall(abi.encodeWithSignature("uri(uint256)", pokedId));
        // 1155
        if (success) {
            if (SKIP_ID_REPLACEMENT[_mimicId]) {
                return abi.decode(uriBytes, (string));
            }

            return uriIdReplace(abi.decode(uriBytes, (string)), pokedId);
        }

        // if we get here then that is bad, poor mimic is sick :(

        if (matHashMimicId == _mimicId) {
            return cMeta.mimicNative(_mimicId, "X"); // adult sick eyes (whoops)
        }

        return cMeta.mimicNative(_mimicId, "x"); // juvenile sick eyes
    }

    ////
    // Guild Mint

    function cGuild_Mint(address _owner) external {
        require(msg.sender == aGuild);
        _mint(_owner, totalSupply() + 1);
    }

    ////
    // Lore

    function lore() external view returns (string memory) {
        return ILore(aGuild).lore();
    }

    ////
    // Util

    function uriIdReplace(string memory uri, uint tokenId) internal pure returns (string memory) {
        bytes memory s = bytes(uri);
        uint sLen = s.length;
        if (sLen < 4) {
            return uri; // can't fit "{id}"
        }

        bytes memory t = uint256ToPaddedBytesHex(tokenId);
        uint sLenM3 = sLen - 3;

        bytes memory o = bytes(uri);

        uint si = 0;
        uint oi = 0;

        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                o = bytes.concat(o, new bytes(60));
                for (uint ti = 0; ti < 64; ti++) {
                    o[oi++] = t[ti];
                }
                si += 4;
                break;
            } else {
                oi++;
                si++;
            }
        }

        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                o = bytes.concat(o, new bytes(60));
                for (uint ti = 0; ti < 64; ti++) {
                    o[oi++] = t[ti];
                }
                si += 4;
            } else {
                o[oi++] = s[si++];
            }
        }

        while (si < sLen) {
            o[oi++] = s[si++];
        }

        return string(o);
    }

    function uint256ToPaddedBytesHex(uint256 value) internal pure returns (bytes memory) {
        bytes memory o = new bytes(64);
        uint256 mask = 0xf; // hex 15
        uint i = 63;
        while (true) {
            uint8 end = uint8(value & mask);
            if (end < 10) {
                o[i] = bytes1(end + 48);
            } else {
                o[i] = bytes1(end + 87);
            }
            value >>= 4;
            if (i == 0) {
                break;
            }
            i--;
        }
        return o;
    }

    function d() external pure returns (string memory) {
        return "Rm9yIG15IGZhdGhlciwgd2hvIG5ldmVyIGNvbXBsYWlucyBhYm91dCBteSBob25vcmFibGUgbWlzY2hpZWYu";
    }
}

"
    },
    "contracts/MimicCustom/Guild/GuildOwnable.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract GuildOwnable {
    address internal __owner;
    address internal __backup;
    uint256 internal __lastOwnerUsage;
    uint256 internal __backupActivationWait;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BackupTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function setBackupActivationWait(uint256 _backupActivationWait) public onlyOwner {
        __backupActivationWait = _backupActivationWait;
        _activity();
    }

    function owner() public view returns (address) {
        return __owner;
    }

    function backupOwner() public view returns (address) {
        return __backup;
    }

    function isBackupActive() public view returns (bool) {
        if (__backup == address(0x0)) {
            return false;
        }
        if ((__lastOwnerUsage + __backupActivationWait) <= block.timestamp) {
            return true;
        }

        return false;
    }

    function isOwnerOrActiveBackup(address _addr) public view returns (bool) {
        return (_addr == owner() ||
            (isBackupActive() && (_addr == backupOwner()))
        );
    }

    modifier onlyOwnerOrActiveBackup() {
        require(isOwnerOrActiveBackup(msg.sender), "Ownable: caller is not owner or active backup");
        _;
    }

    modifier onlyOwnerOrBackup() {
        require(msg.sender == __owner || msg.sender == __backup, "Ownable: caller is not owner or backup");
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferBackup(address newBackup) public onlyOwnerOrBackup {
        if (newBackup == address(0)) {
            require(msg.sender == __owner, "Ownable: new backup is the zero address");
        }

        _transferBackup(newBackup);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = __owner;
        __owner = newOwner;
        _activity();
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _transferBackup(address newBackup) internal {
        address oldBackup = __backup;
        __backup = newBackup;
        _activity();
        emit BackupTransferred(oldBackup, newBackup);
    }

    function _activity() internal {
        if (msg.sender == __owner) {
            __lastOwnerUsage = block.timestamp;
        }
    }
}
"
    },
    "contracts/MimicCustom/Interfaces/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}"
    },
    "contracts/MimicCustom/Interfaces/IERC1155.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity 0.8.11;

import "./IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
    "contracts/MimicCustom/Interfaces/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}"
    },
    "contracts/MimicCustom/Mimic/Combo721Base.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../Interfaces/IERC721.sol";
import "../Interfaces/IERC721Receiver.sol";
import "../Interfaces/IERC721Metadata.sol";
import "../Interfaces/IERC721Enumerable.sol";
import "../Interfaces/IERC165.sol";


abstract contract Combo721Base is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {

    ////
    // 721 Vanilla - Storage

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _approvals;
    mapping(address => mapping(address => bool)) private _operators; // approved for all owner's tokens

    ////
    // 721 Metadata - Storage

    string private _name;
    string private _symbol;

    ////
    // 721 Enumerable - Storage

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    ////
    // 165

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    // Constructor

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    ////
    // 721 Metadata

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    ////
    // 721 Vanilla - Ownership

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    ////
    // 721 Vanilla - Auth

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approvals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _approvals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operators[owner][operator];
    }

    ////
    // 721 Vanilla - Transfers

    function safeTransferFrom( address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require( _isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        if (to.code.length > 0) {
            bytes4 ret = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
            require(ret == IERC721Receiver.onERC721Received.selector, "receiver");
        }
    }

    function _transfer( address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _innerTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _approvals[tokenId] = address(0x0);
    }

    function _innerTransfer(address from, address to, uint256 tokenId) internal {
        _beforeTokenTransfer(from, to, tokenId);

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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual { }

    ////
    // 721 Vanilla - Mint

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _innerTransfer(address(0), to, tokenId);
    }

    ////
    // 721 Enumerable

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
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
    "contracts/MimicCustom/Mimic/MimicMeta.sol": {
      "content": "
// SPDX-License-Identifier: MIT

// Initial structure and some code copied from Loot - MIT license
// https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1

pragma solidity 0.8.11;

contract MimicMeta {

    address aMimic;
    address aShield;

    string constant COLOR = "COLORS";
    string constant EYE = "EYE";
    string constant MOUTH = "MOUTH";
    string constant TOOTH = "TOOTH";

    string[] private colors = [
        "#abffbc", // forest
        "#abffbc",
        "#abffbc",
        "#abffbc",
        "#abffbc",
        "#abfff5", // sky
        "#abfff5",
        "#abfff5",
        "#abfff5",
        "#abfff5",
        "#aaddff", // sea
        "#aaddff",
        "#aaddff",
        "#aaddff",
        "#aaddff",
        "#abb2ff", // lavender
        "#abb2ff",
        "#abb2ff",
        "#abb2ff",
        "#abb2ff",
        "#ffa8a8", // clay
        "#ffa8a8",
        "#ffa8a8",
        "#ffa8a8",
        "#ffa8a8",
        "#ffd2aa", // wheat
        "#ffd2aa",
        "#ffd2aa",
        "#ffd2aa",
        "#ffd2aa",
        "#ffaafa", // pink
        "#ffaafa",
        "#ffaafa",
        "#ffaafa",
        "#ffaafa",
        "#f72585", // cyber pink
        "#f72585",
        "#a025f7", // cyber purple
        "#a025f7",
        "#2538f7", // cyber blue
        "#2538f7",
        "#f5f725", // cyber yellow
        "#f5f725",
        "#27fb6b", // cyber green
        "#27fb6b",
        "#f51000", // cyber red
        "#f51000",
        "#edc531", // gold
        "#dee2e6", // silver
        "#33333a"  // shadow
    ];

    string[] private eyes = [
        "0", // 0
        "0",
        "0",
        "0",
        "0",
        "0",
        "O", // O
        "O",
        "O",
        "O",
        "O",
        "O",
        "^", // ^
        "^",
        "^",
        "^",
        "^",
        "^",
        "'", // '
        "'",
        "'",
        "'",
        "'",
        "'",
        "~", // ~
        "~",
        "~",
        "~",
        "~",
        "~",
        "-", // -
        "-",
        "-",
        "-",
        "-",
        "-",
        "o", // o
        "o",
        "o",
        "o",
        "o",
        "o",
        "#", // #
        "@", // @
        "$"  // $
    ];

    string[] private left_mouths = [
        "[",  // [
        "[",
        "(",  // (
        "(",
        "{",  // {
        "{",
        "\\", // \
        ":"   // :
    ];

    string[] private right_mouths = [
        "]", // ]
        "]",
        ")", // }
        ")",
        "}", // }
        "}",
        "/", // /
        ":"  // :
    ];

    string[] private teeth = [
        "=",
        "_",
        "."
    ];

    function init(address _mimic, address _shield) external {
        require(aMimic == address(0x0));
        aMimic = _mimic;
        aShield = _shield;
    }

    function randomUS(uint256 input, string memory input2) internal pure returns (uint) {
        return uint256(keccak256(abi.encodePacked(input, input2)));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = randomUS(tokenId, keyPrefix);
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    ////
    // Mimic

    function mimicNative(uint256 _tokenId, string calldata _eye) external view returns (string memory output) {
        require(msg.sender == aMimic);
        string memory tidString = uintToString(_tokenId);
        string memory json = Base64.encodeNew(bytes(string(abi.encodePacked(
            '{',
                '"name": "Mimic #',
                    tidString,
                '",'
                '"description": "Mimic #',
                    tidString,
                    '\\n\\n'
                    'Mimics are mischeivous but honorable digital creatures that live deep within the ethereum blockchain.'
                    '\\n\\n'
                    'They are known to interact in interesting ways with other NFTs from throughout the ethereum ecosystem.'
                '",'
                '"image": "data:image/svg+xml;base64,',
                    Base64.encodeNew(bytes(imageFace(_tokenId, _eye))),
                '"'
            '}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function imageFace(uint256 _mimicId, string memory _eye) internal view returns (string memory) {
        string memory color = pluck(_mimicId, COLOR, colors);
        if (bytes(_eye).length == 0) {
            _eye = pluck(_mimicId, EYE, eyes);
        }
        string memory tooth = pluck(_mimicId, TOOTH, teeth);
        uint256 rand_mouth = randomUS(_mimicId, MOUTH) % left_mouths.length;

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
                '<style>'
                    '.base { fill: ', color, '; font-family: monospace; text-anchor: middle; font-size: 80px; } '
                    '@keyframes glow { 0% { opacity: 0.2; } 3% { opacity: 0.9; } 30% { opacity: 0.2 } 70% {opacity: 0.9} } '
                    '.face { animation: glow 3s linear infinite alternate } '
                    '.f1 { animation-delay: 0.5s } '
                    '.f2 { animation-delay: 1.5s } '
                    '.f3 { animation-delay: 0.7s } '
                    '.f4 { animation-delay: 2.5s } '
                    '.f5 { animation-delay: 0.3s } '
                    '.f6 { animation-delay: 2.2s } '
                    '.d1 { animation-duration: 2.7s } '
                    '.d2 { animation-duration: 2.8s } '
                    '.d3 { animation-duration: 2.9s } '
                    '.d4 { animation-duration: 3.0s } '
                    '.d5 { animation-duration: 3.1s } '
                    '.d6 { animation-duration: 3.2s } '
                    '.d7 { animation-duration: 3.3s } '
                '</style>'
                '<rect width="100%" height="100%" fill="black" />'
                '<text x="100" y="130" class="base face f1 d1">',
                _eye,
                '</text>'
                '<text x="250" y="130" class="base face f2 d2">',
                _eye,
                '</text>'
                '<text x="100" y="260" class="base face f3 d3">',
                left_mouths[rand_mouth],
                '</text>'
                '<text x="150" y="260" class="base face f4 d4">',
                tooth,
                '</text>'
                '<text x="200" y="260" class="base face f5 d5">',
                tooth,
                '</text>'
                '<text x="250" y="260" class="base face f6 d6">',
                right_mouths[rand_mouth],
                '</text>'
                '<rect class="face d7" width="100%" height="100%" fill="#000000ee" />'
            '</svg>'
        ));
    }

    ////
    // Shield

    function shieldNative(uint256 _tokenId, bool _active) external view returns (string memory output) {
        require(msg.sender == aShield);
        string memory tidString = uintToString(_tokenId);
        string memory aura;
        if (_active) {
            aura = "Active";
        } else {
            aura = "Inactive";
        }
        string memory json = Base64.encodeNew(bytes(string(abi.encodePacked(
            '{',
                '"name": "Mimic Shield #',
                    tidString,
                '",'
                '"description": "Mimic Shield #',
                    tidString,
                    '\\n\\n'
                    'A Mimic Shield is the reified character of a mimic that has undertaken a sacred rite to become an adult.'
                    '\\n\\n'
                    "The aura of a shield is of great significance to mimics and their ritual practice."
                '",'
                '"attributes": [{ "trait_type": "Aura", "value": "',
                    aura,
                '"}],'
                '"image": "data:image/svg+xml;base64,',
                    Base64.encodeNew(bytes(imageShield(_tokenId, _active))),
                '"'
            '}'
        ))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function imageShield(uint256 _mimicId, bool _active) internal view returns (string memory) {
        string memory color = pluck(_mimicId, COLOR, colors);
        string memory aura = shieldAura(_active);

        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
                '<style>'
                    '.base { fill: ', color, '; font-family: monospace; text-anchor: middle; font-size: 30px; }'
                    '@keyframes glow { 0% { opacity: 0.4; } 3% { opacity: 0.9; } 30% { opacity: 0.4 } 70% {opacity: 0.9} }'
                    '@keyframes rx {0% { transform: translateX(11px) } 2% { transform: translateX(83px) } 3% { transform: translateX(227px) } 4% { transform: translateX(19px) } 5% { transform: translateX(160px) } 6% { transform: translateX(252px) } 7% { transform: translateX(177px) } 8% { transform: translateX(64px) } 9% { transform: translateX(317px) } 10% { transform: translateX(192px) } 11% { transform: translateX(310px) } 12% { transform: translateX(92px) } 13% { transform: translateX(184px) } 14% { transform: translateX(248px) } 15% { transform: translateX(64px) } 16% { transform: translateX(205px) } 17% { transform: translateX(243px) } 18% { transform: translateX(11px) } 19% { transform: translateX(348px) } 20% { transform: translateX(232px) } 21% { transform: translateX(191px) } 22% { transform: translateX(313px) } 23% { transform: translateX(154px) } 24% { transform: translateX(4px) } 25% { transform: translateX(105px) } 26% { transform: translateX(140px) } 27% { transform: translateX(229px) } 28% { transform: translateX(262px) } 29% { transform: translateX(200px) } 30% { transform: translateX(107px) } 31% { transform: translateX(30px) } 32% { transform: translateX(193px) } 33% { transform: translateX(105px) } 34% { transform: translateX(222px) } 35% { transform: translateX(64px) } 36% { transform: translateX(285px) } 37% { transform: translateX(224px) } 38% { transform: translateX(96px) } 39% { transform: translateX(284px) } 40% { transform: translateX(32px) } 41% { transform: translateX(216px) } 42% { transform: translateX(273px) } 43% { transform: translateX(28px) } 44% { transform: translateX(6px) } 45% { transform: translateX(303px) } 46% { transform: translateX(177px) } 47% { transform: translateX(145px) } 48% { transform: translateX(103px) } 49% { transform: translateX(85px) } 50% { transform: translateX(342px) } 51% { transform: translateX(201px) } 52% { transform: translateX(321px) } 53% { transform: translateX(152px) } 54% { transform: translateX(204px) } 55% { transform: translateX(267px) } 56% { transform: translateX(19px) } 57% { transform: translateX(137px) } 58% { transform: translateX(1px) } 59% { transform: translateX(314px) } 60% { transform: translateX(174px) } 61% { transform: translateX(143px) } 62% { transform: translateX(132px) } 63% { transform: translateX(130px) } 64% { transform: translateX(219px) } 65% { transform: translateX(281px) } 66% { transform: translateX(272px) } 67% { transform: translateX(244px) } 68% { transform: translateX(311px) } 69% { transform: translateX(110px) } 70% { transform: translateX(59px) } 71% { transform: translateX(72px) } 72% { transform: translateX(285px) } 73% { transform: translateX(296px) } 74% { transform: translateX(319px) } 75% { transform: translateX(96px) } 76% { transform: translateX(192px) } 77% { transform: translateX(293px) } 78% { transform: translateX(26px) } 79% { transform: translateX(174px) } 80% { transform: translateX(246px) } 81% { transform: translateX(276px) } 82% { transform: translateX(255px) } 83% { transform: translateX(298px) } 84% { transform: translateX(137px) } 85% { transform: translateX(296px) } 86% { transform: translateX(112px) } 87% { transform: translateX(32px) } 88% { transform: translateX(66px) } 89% { transform: translateX(288px) } 90% { transform: translateX(76px) } 91% { transform: translateX(116px) } 92% { transform: translateX(158px) } 93% { transform: translateX(280px) } 94% { transform: translateX(161px) } 95% { transform: translateX(81px) } 96% { transform: translateX(260px) } 97% { transform: translateX(185px) } 98% { transform: translateX(213px) } 99% { transform: translateX(102px) } 100% { transform: translateX(160px) }}'
                    '@keyframes ry {0% { transform: translateY(41px) } 1% { transform: translateY(320px) } 2% { transform: translateY(239px) } 3% { transform: translateY(220px) } 4% { transform: translateY(158px) } 5% { transform: translateY(301px) } 6% { transform: translateY(335px) } 8% { transform: translateY(39px) } 9% { transform: translateY(171px) } 10% { transform: translateY(305px) } 11% { transform: translateY(148px) } 12% { transform: translateY(152px) } 13% { transform: translateY(168px) } 14% { transform: translateY(178px) } 15% { transform: translateY(57px) } 16% { transform: translateY(94px) } 17% { transform: translateY(307px) } 18% { transform: translateY(19px) } 19% { transform: translateY(249px) } 20% { transform: translateY(48px) } 21% { transform: translateY(332px) } 22% { transform: translateY(234px) } 23% { transform: translateY(302px) } 24% { transform: translateY(139px) } 25% { transform: translateY(255px) } 26% { transform: translateY(80px) } 27% { transform: translateY(184px) } 28% { transform: translateY(87px) } 29% { transform: translateY(337px) } 30% { transform: translateY(83px) } 31% { transform: translateY(204px) } 32% { transform: translateY(182px) } 33% { transform: translateY(348px) } 34% { transform: translateY(285px) } 35% { transform: translateY(273px) } 36% { transform: translateY(273px) } 37% { transform: translateY(99px) } 38% { transform: translateY(206px) } 39% { transform: translateY(217px) } 40% { transform: translateY(345px) } 41% { transform: translateY(329px) } 42% { transform: translateY(128px) } 43% { transform: translateY(61px) } 44% { transform: translateY(79px) } 45% { transform: translateY(302px) } 46% { transform: translateY(153px) } 47% { transform: translateY(98px) } 48% { transform: translateY(294px) } 49% { transform: translateY(189px) } 50% { transform: translateY(347px) } 51% { transform: translateY(20px) } 52% { transform: translateY(300px) } 53% { transform: translateY(216px) } 54% { transform: translateY(285px) } 55% { transform: translateY(72px) } 56% { transform: translateY(53px) } 57% { transform: translateY(178px) } 58% { transform: translateY(292px) } 59% { transform: translateY(340px) } 60% { transform: translateY(273px) } 61% { transform: translateY(197px) } 62% { transform: translateY(71px) } 63% { transform: translateY(279px) } 64% { transform: translateY(247px) } 65% { transform: translateY(120px) } 66% { transform: translateY(22px) } 67% { transform: translateY(20px) } 68% { transform: translateY(217px) } 69% { transform: translateY(12px) } 70% { transform: translateY(246px) } 71% { transform: translateY(219px) } 72% { transform: translateY(347px) } 73% { transform: translateY(252px) } 74% { transform: translateY(155px) } 75% { transform: translateY(290px) } 76% { transform: translateY(163px) } 77% { transform: translateY(132px) } 78% { transform: translateY(146px) } 79% { transform: translateY(121px) } 80% { transform: translateY(227px) } 81% { transform: translateY(189px) } 82% { transform: translateY(311px) } 83% { transform: translateY(243px) } 84% { transform: translateY(83px) } 85% { transform: translateY(59px) } 86% { transform: translateY(44px) } 87% { transform: translateY(75px) } 88% { transform: translateY(312px) } 89% { transform: translateY(161px) } 90% { transform: translateY(31px) } 91% { transform: translateY(310px) } 92% { transform: translateY(119px) } 93% { transform: translateY(292px) } 94% { transform: translateY(187px) } 95% { transform: translateY(176px) } 96% { transform: translateY(20px) } 97% { transform: translateY(312px) } 98% { transform: translateY(342px) } 99% { transform: translateY(47px) } 100% { transform: translateY(336px) }}'
                    '.aura { animation: glow 5s ease infinite alternate-reverse }'
                    '.shield { opacity: 0.6 }'
                    '.xv { animation-name: rx; animation-timing-function: step-end; animation-iteration-count: infinite; }'
                    '.yv { animation: ry 87s step-end infinite }'
                    '.t { transform: rotateY(260deg) }'
                    '.f1 { animation-delay: -0.5s }'
                    '.f2 { animation-delay: -10.5s }'
                    '.f3 { animation-delay: -15.7s }'
                    '.f4 { animation-delay: -32.5s }'
                    '.f5 { animation-delay: -37.3s }'
                    '.f6 { animation-delay: -32.2s }'
                    '.a1 { animation-duration: 31.11s }'
                    '.a2 { animation-duration: 37.91s }'
                    '.a3 { animation-duration: 42.31s }'
                    '.a4 { animation-duration: 47.71s }'
                    '.a5 { animation-duration: 131.11s }'
                    '.a6 { animation-duration: 141.01s }'
                '</style>'
                '<defs>'
                    '<radialGradient id="rgaura">'
                        '<stop offset="30%" stop-color="transparent" />'
                        '<stop offset="70%" stop-color="',
                        color,
                        '" stop-opacity="0.30" />'
                    '</radialGradient>'
                '</defs>'
                '<rect width="100%" height="100%" fill="111111" />',
                shieldFeatures(_mimicId),
                '<rect class="aura a4" x="0%" y="0" width="100%" height="100%" fill="#aaddff11" />',
                aura,
                '<g transform="translate(175, 175)">', shield(_mimicId, color), '</g>'
            '</svg>'
        ));
    }

    function shieldFeatures(uint256 _mimicId) internal view returns (string memory) {
        string memory eye = pluck(_mimicId, EYE, eyes);
        string memory tooth = pluck(_mimicId, TOOTH, teeth);
        uint256 rand_mouth = randomUS(_mimicId, MOUTH) % left_mouths.length;

        return string(abi.encodePacked(
            '<g class="xv f2 a1"><g class="yv f1 a3"><text class="base aura f1">', eye, '</text></g></g>'
            '<g class="xv f4 a2"><g class="yv f3 a4"><text class="base aura f3">', eye, '</text></g></g>'
            '<g class="xv f3 a3"><g class="yv f4 a5"><text class="base aura f2">', left_mouths[rand_mouth], '</text></g></g>'
            '<g class="xv f1 a4"><g class="yv f2 a6"><text class="base aura f4">', tooth, '</text></g></g>'
            '<g class="xv f5 a5"><g class="yv f2 a1"><text class="base aura f2">', tooth, '</text></g></g>'
            '<g class="xv f2 a6"><g class="yv f5 a2"><text class="base aura f5">', right_mouths[rand_mouth], '</text></g></g>'
        ));
    }

    function shieldAura(bool _active) internal pure returns (string memory) {
        if (_active) {
            return '<rect width="200%" height="200%" x="-175" y="-175" fill="url(#rgaura)" />';
        }
        return "";
    }

    function shield(uint256 _mimicId, string memory _color) internal pure returns (string memory) {
        string memory vdx = uintToString((randomUS(_mimicId, "VDX") % 100)+25);
        string memory vdy = uintToString((randomUS(_mimicId, "VDY") % 100)+25);
        string memory vvx = uintToString((randomUS(_mimicId, "VVX") % 100)+25);
        string memory hdx = uintToString((randomUS(_mimicId, "HDX") % 100)+25);
        string memory hdy = uintToString((randomUS(_mimicId, "HDY") % 100)+25);
        string memory hhy = uintToString((randomUS(_mimicId, "HHY") % 100)+25);

        return string(abi.encodePacked(
            poly1(_color, vdx, vdy, vvx),
            poly2(_color, vdx, vdy, vvx),
            poly3(_color, hdx, hdy, hhy),
            poly4(_color, hdx, hdy, hhy)
        ));
    }

    function poly1(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f2 a1" points="0,0 ', _x, ',-', _y, ' 0,-', _z, ' -', _x, ',-', _y, '" />'
        ));
    }

    function poly2(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f3 a2" points="0,0 ', _x, ',', _y, ' 0,', _z, ' -', _x, ',', _y, '" />'
        ));
    }

    function poly3(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f4 a3" points="0,0 ', _x, ',', _y, ' ', _z, ',0 ', _x, ',-', _y, '" />'
        ));
    }

    function poly4(string memory _color, string memory _x, string memory _y, string memory _z) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<polygon fill="', _color, '" class="shield aura f5 a4" points="0,0 -', _x, ',', _y, ' -', _z, ',0 -', _x, ',-', _y, '" />'
        ));
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encodeNew(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

"
    },
    "contracts/MimicCustom/Mimic/CoreShield.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { ILore } from "../Interfaces/ILore.sol";

import { MimicMeta } from "./MimicMeta.sol";
import { Combo721Base } from "./Combo721Base.sol";

abstract contract CoreShield is Combo721Base {
    address aGuild;
    address aMimic;
    MimicMeta cMeta;

    mapping(uint256 => bool) ACTIVE;
    mapping(address => uint256) ACTIVE_BALANCES;

    string internal constant NOT_SHIELD_OWNER = "you do not own this this shield";

    event Activation(uint256 indexed _shieldId, bool _active);

    function init(address _guild, address _mimic, address _meta) external {
        require(aMimic == address(0x0), "already initialized");
        aGuild = _guild;
        aMimic = _mimic;
        cMeta = MimicMeta(_meta);
    }

    function cMimic_Mint(address _recipient, uint256 _mimicId) external {
        require(msg.sender == aMimic, "can't touch this");
        _mint(_recipient, _mimicId);
    }

    function tokenURI(uint256 _shieldId) public view override returns (string memory) {
        require(msg.sender.code.length == 0, "nope");
        require(_exists(_shieldId));
        return cMeta.shieldNative(_shieldId, ACTIVE[_shieldId]);
    }

    ////
    // ACTIVATIONS

    function activeCount(address _owner) external view returns (uint256) {
        return ACTIVE_BALANCES[_owner];
    }

    function shield_Activate(uint256 _shieldId) external {
        require(_isApprovedOrOwner(msg.sender, _shieldId), NOT_SHIELD_OWNER);
        require(!ACTIVE[_shieldId], "Mimic Shield: aura is already active");
        ACTIVE[_shieldId] = true;
        ACTIVE_BALANCES[msg.sender] += 1;
        emit Activation(_shieldId, true);
    }

    function shield_Deactivate(uint256 _shieldId) external {
        require(_isApprovedOrOwner(msg.sender, _shieldId), NOT_SHIELD_OWNER);
        require(ACTIVE[_shieldId], "Mimic Shield: aura is already inactive");
        delete ACTIVE[_shieldId];
        ACTIVE_BALANCES[msg.sender] -= 1;
        emit Activation(_shieldId, false);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        if (ACTIVE[_tokenId]) {
            ACTIVE_BALANCES[_from] -= 1;
            ACTIVE_BALANCES[_to] += 1;
        }
    }

    ////
    // Lore

    function lore() external view returns (string memory) {
        return ILore(aGuild).lore();
    }
}"
    },
    "contracts/MimicCustom/Interfaces/IERC721Receiver.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}"
    },
    "contracts/MimicCustom/Interfaces/IERC721Enumerable.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": false,
      "runs": 200
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
    "libraries": {}
  }
}}