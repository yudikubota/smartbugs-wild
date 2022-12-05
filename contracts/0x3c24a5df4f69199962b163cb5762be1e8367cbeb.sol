{{
  "language": "Solidity",
  "sources": {
    "/Users/kyle/workspace/asciipunks/contracts/AsciiPunkFactory.sol": {
      "content": "// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AsciiPunkFactory {
  uint256 private constant TOP_COUNT = 55;
  uint256 private constant EYE_COUNT = 48;
  uint256 private constant NOSE_COUNT = 9;
  uint256 private constant MOUTH_COUNT = 32;

  function draw(uint256 seed) public pure returns (string memory) {
    uint256 rand = uint256(keccak256(abi.encodePacked(seed)));

    string memory top = _chooseTop(rand);
    string memory eyes = _chooseEyes(rand);
    string memory mouth = _chooseMouth(rand);

    string memory chin = unicode"   â    â   \n" unicode"   ââââ â   \n";
    string memory neck = unicode"     â  â   \n" unicode"     â  â   \n";

    return string(abi.encodePacked(top, eyes, mouth, chin, neck));
  }

  function _chooseTop(uint256 rand) internal pure returns (string memory) {
    string[TOP_COUNT] memory tops =
      [
        unicode"   âââââ    \n"
        unicode"   â   â¼â   \n"
        unicode"   ââââââ¼â¼  \n",
        unicode"   ââ¬â¬â¬â¬â   \n"
        unicode"   ââ¬â¬â¬â¬â   \n"
        unicode"   ââ´â´â´â´â   \n",
        unicode"   ââââââ   \n"
        unicode"  ââ´âââââ´â  \n"
        unicode"  ââ¬âââââ¬â  \n",
        unicode"   ââââââ   \n"
        unicode"   ââ¡â¡â¡â¡â   \n"
        unicode"  ââ¬âââââ¬â  \n",
        unicode"   ââââââ   \n"
        unicode"   â    â   \n"
        unicode" âââ¬âââââ¬ââ \n",
        unicode"    ââââ    \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"   âââââ    \n"
        unicode"ââââ¤   ââ   \n"
        unicode"ââââ¼âââââ¤   \n",
        unicode"    âââââ   \n"
        unicode"   ââ   ââââ\n"
        unicode"   ââââââ¼âââ\n",
        unicode"   ââââââ/  \n"
        unicode"ââââ´âââââ´âââ\n"
        unicode"ââââ¬âââââ¬âââ\n",
        unicode"   ââââââ   \n"
        unicode" âââ´âââââ´ââ \n"
        unicode" âââ¬âââââ¬ââ \n",
        unicode"  ââââââââ  \n"
        unicode"  ââ²â²â²â²â²â²â  \n"
        unicode"  ââ¬âââââ¬â  \n",
        unicode"  ââââââââ  \n"
        unicode"  ââââââââ  \n"
        unicode"  ââ¼â´âââ´â¼â  \n",
        unicode"   ââââââ   \n"
        unicode"  âââ   â   \n"
        unicode"  âââââââ   \n",
        unicode"            \n"
        unicode"   ââ¬â¬â¬â¬â   \n"
        unicode"   ââ´â´â´â´â¤   \n",
        unicode"            \n"
        unicode"    ââ¬â¥â    \n"
        unicode"   ââ¨â´â¨â´â   \n",
        unicode"            \n"
        unicode"   ââ¦â¦â¦â¦â   \n"
        unicode"   ââ©â©â©â©â¡   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ââ¼â¼â¼â¼â   \n",
        unicode"            \n"
        unicode"    ââââ    \n"
        unicode"   ââ¼â¼â¼â¼â   \n",
        unicode"      â     \n"
        unicode"     ââ     \n"
        unicode"   âââ«â«ââ   \n",
        unicode"            \n"
        unicode"    ââââ    \n"
        unicode"   ââ¨â¨â¨â¨â   \n",
        unicode"            \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"            \n"
        unicode"   \\/////   \n"
        unicode"   ââââââ   \n",
        unicode"    â â     \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"  ââ âââââ  \n"
        unicode"  âââââââ   \n"
        unicode"   ââ´â´â´â´â   \n",
        unicode"  âââââ     \n"
        unicode"  ââââââ    \n"
        unicode"   ââââââ   \n",
        unicode"            \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"            \n"
        unicode"    ââââ    \n"
        unicode"   ââ¨â¨â¨â¨â   \n",
        unicode"    âââââ   \n"
        unicode"   âââââââ  \n"
        unicode"  ââââ âââ  \n",
        unicode"   ââââââ   \n"
        unicode"  ââââââââ  \n"
        unicode"  âââ¨â¨â¨â¨ââ  \n",
        unicode"   ââââââ   \n"
        unicode"   ââ©ââ©ââ   \n"
        unicode"   ââââââ   \n",
        unicode"            \n"
        unicode"     ///    \n"
        unicode"   ââââââ   \n",
        unicode"     ââââ   \n"
        unicode"    âââââ   \n"
        unicode"   ââââââ   \n",
        unicode"     âââââ  \n"
        unicode"    ââââ    \n"
        unicode"   ââ¨â¨â¨ââ   \n",
        unicode"       ââ   \n"
        unicode"    âââââ   \n"
        unicode"   ââââââ   \n",
        unicode"   ââââââ   \n"
        unicode"  ââââââââ  \n"
        unicode"  ââââââââ¢  \n",
        unicode"    âââ     \n"
        unicode"    ââââ    \n"
        unicode"   ââââââ   \n",
        unicode"            \n"
        unicode"            \n"
        unicode"   ââ¨â¨â¨â¨â   \n",
        unicode"            \n"
        unicode"    ââââ    \n"
        unicode"   ââââââ   \n",
        unicode"   ââââââ   \n"
        unicode"   â   /ââ  \n"
        unicode"   ââââââ/  \n",
        unicode"            \n"
        unicode"   ((((((   \n"
        unicode"   ââââââ   \n",
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"   Â«Â°â      \n"
        unicode"    ââªâ     \n"
        unicode"   âââ¼âââ   \n",
        unicode"  <Â° Â°>   Â§ \n"
        unicode"   \\'/   /  \n"
        unicode"   {())}}   \n",
        unicode"   ââââââ   \n"
        unicode"  ââ ââ ââ  \n"
        unicode" â ââââââ â \n",
        unicode"    ââââ    \n"
        unicode"   ââââââ   \n"
        unicode"   âââ¼â¼ââ   \n",
        unicode"   ââ  ââ   \n"
        unicode"  Â°ââââââÂ°  \n"
        unicode"   âââ¨â¨ââ   \n",
        unicode"   Â± Â±Â± Â±   \n"
        unicode"   ââââââ   \n"
        unicode"   ââââââ   \n",
        unicode"  â«     âª   \n"
        unicode"    âª     â« \n"
        unicode" âª ââââââ   \n",
        unicode"    /â¡â¡\\    \n"
        unicode"   /â¡â¡â¡â¡\\   \n"
        unicode"  /ââââââ\\  \n",
        unicode"            \n"
        unicode"   â£â¥â¦â â£â¥   \n"
        unicode"   ââââââ   \n",
        unicode"     [â]    \n"
        unicode"      â     \n"
        unicode"   ââââââ   \n",
        unicode"  /\\/\\/\\/\\  \n"
        unicode"  \\\\/\\/\\//  \n"
        unicode"   ââââââ   \n",
        unicode"    ââââ    \n"
        unicode"   ââââAB   \n"
        unicode"   ââââââ   \n",
        unicode"    âââ¬â    \n"
        unicode"   ââââââ   \n"
        unicode"   âââ´âââ¤   \n",
        unicode"    â¼  â¼    \n"
        unicode"     \\/     \n"
        unicode"   ââââââ   \n"
      ];
    uint256 topId = rand % TOP_COUNT;
    return tops[topId];
  }

  function _chooseEyes(uint256 rand) internal pure returns (string memory) {
    string[EYE_COUNT] memory leftEyes =
      [
        unicode"â",
        unicode"*",
        unicode"â¥",
        unicode"X",
        unicode"â",
        unicode"Ë",
        unicode"Î±",
        unicode"â",
        unicode"â»",
        unicode"Â¬",
        unicode"^",
        unicode"â",
        unicode"â¼",
        unicode"â¬",
        unicode"â ",
        unicode"â",
        unicode"Ã»",
        unicode"â",
        unicode"Î´",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â¤",
        unicode"/",
        unicode"\\",
        unicode"/",
        unicode"\\",
        unicode"â¦",
        unicode"â¥",
        unicode"â ",
        unicode"â¦",
        unicode"â",
        unicode"â",
        unicode"âº",
        unicode"â",
        unicode"âº",
        unicode"I",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â¥",
        unicode"$",
        unicode"â",
        unicode"N",
        unicode"x"
      ];

    string[EYE_COUNT] memory rightEyes =
      [
        unicode"â",
        unicode"*",
        unicode"â¥",
        unicode"X",
        unicode"â",
        unicode"Ë",
        unicode"Î±",
        unicode"â",
        unicode"â»",
        unicode"Â¬",
        unicode"^",
        unicode"â",
        unicode"â¼",
        unicode"â¬",
        unicode"â ",
        unicode"â",
        unicode"Ã»",
        unicode"â",
        unicode"Î´",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â¤",
        unicode"\\",
        unicode"/",
        unicode"/",
        unicode"\\",
        unicode"â¦",
        unicode"â ",
        unicode"â£",
        unicode"â¦",
        unicode"â",
        unicode"âº",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"I",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â",
        unicode"â¥",
        unicode"$",
        unicode"â",
        unicode"N",
        unicode"x"
      ];
    uint256 eyeId = rand % EYE_COUNT;

    string memory leftEye = leftEyes[eyeId];
    string memory rightEye = rightEyes[eyeId];
    string memory nose = _chooseNose(rand);

    string memory forehead = unicode"   â    ââ  \n";
    string memory leftFace = unicode"   â";
    string memory rightFace = unicode" ââ  \n";

    return
      string(
        abi.encodePacked(
          forehead,
          leftFace,
          leftEye,
          " ",
          rightEye,
          rightFace,
          nose
        )
      );
  }

  function _chooseMouth(uint256 rand) internal pure returns (string memory) {
    string[MOUTH_COUNT] memory mouths =
      [
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   âÎ´   â   \n",
        unicode"   â    â   \n"
        unicode"   âââ¬  â   \n",
        unicode"   â    â   \n"
        unicode"   â(â) â   \n",
        unicode"   â    â   \n"
        unicode"   â[â] â   \n",
        unicode"   â    â   \n"
        unicode"   â<â> â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   ââââ â   \n",
        unicode"   â    â   \n"
        unicode"   ââââ â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   ââ¼ââ¼ â   \n",
        unicode"   â    â   \n"
        unicode"   ââââ¼ â   \n",
        unicode"   â    â   \n"
        unicode"   âÂ«âÂ» â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode" â â    â   \n"
        unicode" ââââ   â   \n",
        unicode" â â    â   \n"
        unicode" ââââ)  â   \n",
        unicode" â â    â   \n"
        unicode" ââââ]  â   \n",
        unicode"   ââÂ¬  â   \n"
        unicode" âââââ  â   \n",
        unicode"   âââ  â   \n"
        unicode"   âââ  â   \n",
        unicode"   â~~  â   \n"
        unicode"   â/\\  â   \n",
        unicode"   â    â   \n"
        unicode"   âââ  â   \n",
        unicode"   â    â   \n"
        unicode"   ââ¼â¼  â   \n",
        unicode"   ââÂ¬  â   \n"
        unicode"   âO   â   \n",
        unicode"   â    â   \n"
        unicode"   âO   â   \n",
        unicode" â ââÂ¬  â   \n"
        unicode" ââââ   â   \n",
        unicode" â ââÂ¬  â   \n"
        unicode" ââââ)  â   \n",
        unicode" â ââÂ¬  â   \n"
        unicode" ââââ]  â   \n",
        unicode"   ââÂ¬  â   \n"
        unicode"   âââ  â   \n",
        unicode"   ââ-Â¬ â   \n"
        unicode"   â    â   \n",
        unicode"   ââ-â â   \n"
        unicode"   ââ â â   \n"
      ];

    uint256 mouthId = rand % MOUTH_COUNT;

    return mouths[mouthId];
  }

  function _chooseNose(uint256 rand) internal pure returns (string memory) {
    string[NOSE_COUNT] memory noses =
      [
        unicode"â",
        unicode"â",
        unicode"<",
        unicode"â",
        unicode"â",
        unicode"^",
        unicode"â",
        unicode"â¼",
        unicode"Î"
      ];

    uint256 noseId = rand % NOSE_COUNT;
    string memory nose = noses[noseId];
    return string(abi.encodePacked(unicode"   â ", nose, unicode"  ââ  \n"));
  }
}
"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
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