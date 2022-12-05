{"AddressUtils.sol":{"content":"pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_account) }
    return size > 0;
  }

}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"ERC165.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"ERC721Basic.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC165.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^ 
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */
   
//   bytes4 constant public InterfaceId_ERC721 =   //0x6dd562d1
//     bytes4(keccak256('balanceOf(address)')) ^
//     bytes4(keccak256('ownerOf(uint256)')) ^
//     bytes4(keccak256('exists(uint256)')) ^
//     bytes4(keccak256('approve(address,uint256)')) ^
//     bytes4(keccak256('getApproved(uint256)')) ^
//     //bytes4(keccak256('setApprovalForAll(address,bool)')) ^
//     bytes4(keccak256('isApprovedForAll(address,address)')) ^
//     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
//     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
//     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */
  //all the basic functions start here...basically....
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data ) public;
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"ERC721BasicTokenSoloArcade.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC721Basic.sol";
import "./ERC721Receiver.sol";
import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./SupportsInterfaceWithLookup.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicTokenSoloArcade is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;
  
  //@dev stores all the game contracts that ERC721BasicToken will safely interact with
  mapping (address => bool) public gameContracts;
  
  //@dev sets the "gameMaster" who can add game contracts to marbles contract
  address public gameMaster;
  
  // @dev Throws if called by any account other than the gameMaster
  modifier onlyGameMaster() {
    require(msg.sender == gameMaster);
    _;
  }
  
  //@dev sets the game contracts that are allowed to interact with the marbles contract
  function setGameContracts(address _newGameContract) public onlyGameMaster{
      gameContracts[_newGameContract] = true;
  }
  
  //@dev stores all the transfered marbles in a form of a queue, helps the database to keep in sync
  mapping (uint256 => uint256) public transferedMarbleIndex;
  
  //@dev sets the status of the marble to transfered marble, helps the increment function to not increment over a marble thats has not being looked at by the database
  mapping (uint256 => bool) public transferedMarbles;
  
  //@dev used at the first number in the transfered queue
  uint256 public firstFirst = 1;
  
  //@dev used as last number in the transfered queue
  uint256 public lastLast = 0;
  
  
  constructor()
    public
  {
     //@dev sets the "gameMaster" to the address of the owner of the contract
     gameMaster = msg.sender;
    //@dev register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator. Disabled for now.
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_to != address(0));
    
    clearRemoveAdd(_from, _to, _tokenId);
    
    insertTokenTransferQue(_tokenId); 
    emit Transfer(_from, _to, _tokenId);
  }
  
   /**
   * @dev Transfers the ownership of a given token ID from the game contract
   * Requires the msg.sender to one of the game contracts approved by the game master
   * @param gameContract stores the address of the game contract the function was called from
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFromGameSolo(address gameContract, address _from, address _to, uint256 _tokenId) public {
      require(gameContracts[gameContract]);
      require(gameContracts[msg.sender]);
      require(ownerOf(_tokenId) == msg.sender);
      require(_to != address(0));
      
      clearRemoveAdd(_from, _to, _tokenId);
      
      emit Transfer(_from, _to, _tokenId);
      
  }
  
   /**
   * @dev internal function used to insert token ID into the transfer queue
   * @param _tokenId uint256 ID of the token to be inserted in the toke queue
  */
  function insertTokenTransferQue(uint256 _tokenId) internal{
    lastLast += 1;
    transferedMarbleIndex[lastLast] = _tokenId;
    transferedMarbles[_tokenId] = true;
  }
  
  /**
   * @dev internal function changes ownership of a token ID, makes it easier to recycle code
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearRemoveAdd(address _from, address _to, uint256 _tokenId) internal {
       clearApproval(_from, _tokenId);
       removeTokenFrom(_from, _tokenId);
       addTokenTo(_to, _tokenId);
  }
  
  /**
   *@dev transfer function with the same logic as "transfeFrom" function, but this one does not place the marble
   *into the transfer queue. Please don't use this function without the the front end. The database will not be in sync with your transfer.
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFromGameERC721(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(gameContracts[msg.sender]);
    require(isApprovedOrOwner(tx.origin, _tokenId));
    require(_to != address(0));

    clearRemoveAdd(_from, _to, _tokenId);
    
    emit Transfer(_from, _to, _tokenId);
  }
  
  /**
   * @dev uses the same logic as the transferFrom function, but this function is only used to transfer prizes from games to a winning player.
   * requires that the msg.sender is the game contract added by the game master of the contract
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferPrizeFromGame(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(gameContracts[msg.sender]);
    require(_to != address(0));
    clearRemoveAdd(_from, _to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }
  
  
  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   /**
    * @dev Internal function to mint a new token
    * Reverts if the given token ID already exists
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */ 
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

 

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"ERC721MetadataSoloArcade.sol":{"content":"pragma solidity ^0.4.11;

import "./ERC721BasicTokenSoloArcade.sol";  
import "./OwnableSolo.sol";

contract ERC721MetadataSoloArcade is ERC721BasicTokenSoloArcade, OwnableSolo {

    
    //@dev declares the token name as "Marble"
	string public constant name = "Marble";
    
    //@dev declares the token symbol as "MIB"
    string public constant symbol = "MIB";

    //@dev mapping for token URIs
    mapping(uint256 => string) public tokenURIs;

    //@dev function which sets the token URI, throws if token ID does not exist, only wallet address that is set as creator can set meta data
    //@param tokenId ID of the token to set its URI 
    //@param uri string URI to assign  (example https://api.cryptomibs.co/marbles/)
    function setTokenURI(uint256 tokenId, string uri) onlyCreator public {
        
        if(bytes(tokenURIs[tokenId]).length != 0){ //checks if there is already any metadata recorded for that token ID.
           delete tokenURIs[tokenId];       //clears old metadata if any, for that token ID
        }

        require(_exists(tokenId));   //checks to see if tokenId exists
        
        tokenURIs[tokenId] = uri;    // sets token URI to a given string in tokenURIs mapping

    }

    //@dev returns a URI for a given token ID, throws if token ID does not exists. Turns the URI into bytes and concatenates the token ID to the end of URI base
    //This method uses a turorial from coinmonks.
    //Ref: https://medium.com/coinmonks/jumping-into-solidity-the-erc721-standard-part-6-7ea4af3366fd
    //@param tokenId ID of token to query
    function tokenURI(uint256 tokenId) public view returns (string){
        require(_exists(tokenId)); //checks if token ID exists.
        
        bytes storage uriBase = bytes(tokenURIs[tokenId]);  
    
        //prepare our tokenId's byte array
        uint maxLength = 78;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
    
        //loop through and add byte values to the array
        while (tokenId != 0) {
        uint remainder = tokenId % 10;
        tokenId /= 10;
        reversed[i++] = byte(48 + remainder);
        }
    
        //prepare the final array
        bytes memory result = new bytes(uriBase.length + i);
        uint j;
        //add the base to the final array
        for (j = 0; j < uriBase.length; j++) {
        result[j] = uriBase[j];
        }
    
        //add the tokenId to the final array
        for (j = 0; j < i; j++) {
        result[j + uriBase.length] = reversed[i - 1 - j];
        }  
    

        return string(result);  //turn it into a string and return it  
    

    }

}"},"ERC721Receiver.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"marbles.sol":{"content":"pragma solidity ^0.4.11;

import "./ERC721BasicTokenSoloArcade.sol";  
import "./OwnableSolo.sol";
import "./PayableSolo.sol";
import "./ERC721MetadataSoloArcade.sol";


//@title Marbles
//@dev marbles contract inherets ERC721 Non-Fungible Token Standard basic implementation.
//@author Oleg Mitrakhovich                        
contract Marbles is ERC721BasicTokenSoloArcade, OwnableSolo, PayableSolo, ERC721MetadataSoloArcade {

    //@dev basic structure of a marble, 8 attributes.
    struct Marble {
    
        uint256 batch;    //assigns which batch the marble is from (1, 2, 3, 4, etc.)
        string material;  // glass, clay, agate, steel, alabaster
        uint size;        // 12mm, 14mm, 16mm, 18mm, 19mm, 22mm, 25mm, 35mm, 41mm, 48mm
        string pattern;   /*1.Corkscrew Swirls 
                            2.Ribbon Swirls 
                            3.Fancy Swirls 
                            4.Catâs Eye 
                            5.Clouds 
                            6.Onionskins 
                            7.Bullseye 
                            8.Clearies 
                            9.Opaques
                          */ 

        string origin; /* 1.Germany 
                          2.Belgium 
                          3.Japan 
                          4.China 420
                          5.US 
                          6.Mexico 
                         */
        string forged; // handmade, machined, custom
        string grade;  // mint, near mint, good, exprienced, senior 
        string color;  //list of colors
        
    } 

    //@dev emits add marble attributes event
    //@param _tokenId ID of the token that just had all of its attributes changed
    event addMarbleAttributesConfirmed(uint256 indexed _tokenId);
    

    //@dev stores all the marble prices by its ID.
    mapping(uint256 => uint256) public marblePrices;

    //@dev storing total created marble count
    uint public marbleCount;
    
    
    //@dev storing the count of all place holder marbles.
    uint public placeHolderMarbleCount;

    //@dev stores the highest marble ID created.
    uint public highestMarbleCreated;
    
    //@dev stores the highest Marble ID in the catalaug
    uint public highestMarbleInventory;
    
    //@dev stores highest place holder marble ID created.
    uint public highestPlaceHolderCreated;
    
    //@dev stores all the place holder marbles IDs 
    mapping(uint256 => bool) public placeHolderMarbles;

    //@dev stores marble IDs to marble struct 
    mapping(uint256 => Marble) public marbles; 
    
    //@dev stores all the placeholder marbles by index
    mapping (uint256 => uint256) public placeHolderMarbleIndex;
    
    //@dev first queue number used in placeholdermarbleIndex
    uint256 public first = 1;
    
    //@dev last queue number used in placeholdermarbleIndex
    uint256 public last = 0;
    
    
    //@dev checks to see if the price being used to buy a marble is correct, throws if its not
    modifier priceCheck(uint256 _tokenId) {
       require(marblePrices[_tokenId] == msg.value);
       _;
    }

    
    //@dev upon deployment ETH will be deposited to marbles contract, if there is any.
    constructor () public payable {
        deposit(msg.value);
    }
    
    //@dev fall back function, will execute when someone tries to send ETH to this contract address
    function () public payable {
        deposit(msg.value); //deposit ETH to contract
    }
    
    //@dev returns the total supply of marbles
    function totalSupply() public view returns (uint256 total){
        return marbleCount;
    }

    
     //@dev returns the placeholder marble ID that is located in the first Index.
     function getPlaceHolderMarble() public view returns(uint256 placeholdermarble){
      return placeHolderMarbleIndex[first];
     }

     //@dev returns all marbles of owner by index. should be used on the back end to sync the database. run this in a loop.
     function getMarblesOwnedByIndex(uint256 index, address _owner) public view returns(uint256 marbleId){
      address owner = tokenOwner[index];
      require(owner == _owner);
      return index;
     }

     //@dev returns all marbles created on the contract by index. should be used on the back end to sync. run this in a loop.
     function getAllMarblesCreatedByIndex(uint256 index) public view returns(uint256 marbleId){
      address owner = tokenOwner[index];
      require(owner != address(0));
      return index;
     }

     //@credit CryptoKitties contract (https://ethfiddle.com/09YbyJRfiI) (https://etherscan.io/token/0x06012c8cf97bead5deae237070f9587f8e7a266d#readContract)
     //@dev searches for all the marbles that were assigned to a specific address, returns an array of marble IDs.
     //@dev DO NOT USE THIS FUNCTION inside the contract, it is too expensive and your function call will time out, if their is too many marbles to find. 
     //@dev This function is used to support web3 calls. 
     //@dev When tested with web3 calls this function stopped looking for marbles at 1000 on Rikenby test network.
     //@param _owner wallet address of the owner who owns marble IDs
     function marblesOwned(address _owner) external view returns(uint256[] MarblesOwned) {
        uint256 CountOfMarbles = balanceOf(_owner);   //stores the total number of marbles that are owned by the "_owner" address

        if (CountOfMarbles == 0) {                    //checks to see if the count of marbles is at zero
        
            return new uint256[](0);                  // function returns an empty array of the above if statement returns true  
        
        } else {                                        
        
            uint256[] memory result = new uint256[](CountOfMarbles); //allocating memory in the result array to the count of possible owned marbles by the "_owner"
            uint256 totalMarbles = highestMarbleCreated;             //setting totalMarbles to the highest marble ID. This is done to keep the value constant when used in the for loop.
            uint256 resultIndex = 0;                                 //initializing resultIndex at 0

            uint256 MarbleId;                                        //initializing MarbleId to use later in the for loop 

            for (MarbleId = 1; MarbleId <= totalMarbles; MarbleId++) { //MarbleId gets intialized at 1, the loop will keep going till MarbleId is higher than the total number of Marbles. Adds 1 to MarbleId each loop cycle
                if (tokenOwner[MarbleId] == _owner) { //uses TokenOwner mapping from ERC721BasicToken contract, returns true if MarbleId was mapped to "_owner" address
                    result[resultIndex] = MarbleId;   //stores the MarbleId in a array of uint256 called result, uses resultIndex to expand the array
                    resultIndex++;                    //add one to resultIdex
                }

                if (CountOfMarbles == resultIndex){   //returns the function early when the result count is equal to the total owner's marbles.
                    return result;
                }
            }                                         

            return result;                            //returns an array of MarbleIds
        }
    }
 
    //@dev returns all the marble Token IDs that were created
    //DO NOT USE THIS FUNCTION INTERNALLY. For testing purposes only
    function allMarblesCreated() external view returns(uint256[] MarblesCreated){
        uint256 allMarblesCreatedCount = marbleCount;
        uint256[] memory result = new uint256[](allMarblesCreatedCount); //allocating enough memory to store all the Marble IDs created
        uint256 resultIndex = 0; //setting result index to 0
        uint256 allTokens = highestMarbleCreated;
        uint256 tokenIndex;      //token index that will be used in tokenOwner mapping

        for(tokenIndex = 1; tokenIndex <= allTokens; tokenIndex++){
            if(tokenOwner[tokenIndex] != 0){ //checks if the index of that token owner is not equal to zero
            result[resultIndex] = tokenIndex; //if the above statement returns true, stores the token Id in array called result
            resultIndex++;//increases result index by one
            
            }
        }

        return result;  //returns the final result of all token IDs created
    }
   
    //@dev returns a list of marbles that are still placeholder marbles
    function getPlaceHolderMarbles() external view returns(uint256[] resultPlaceHolders){
              uint256 allPlaceHoldersCreatedCount = placeHolderMarbleCount;
              uint256[] memory result = new uint256[](allPlaceHoldersCreatedCount);
              uint256 resultIndex = 0;
              uint256 allPlaceHolders = highestMarbleCreated;
              uint256 index;

              for(index = 1; index <= allPlaceHolders; index++){
                  if(placeHolderMarbles[index]){
                  result[resultIndex] = index;
                  resultIndex++;
                  }
              }

              return result;
    }


    
    //@dev configures the marble price and stores the highest marble ID currently available for sale
    //@param _newPriceInWei takes in the marble price in wei of one marble
    //@param _highestMarbleInventory takes in the highest token ID currently available in store
    function configStore (uint256 _newPriceInWei, uint256 startingId, uint endingId) external onlyOwner {
                  for(uint i = startingId; i <= endingId; i++){
                    marblePrices[i] = _newPriceInWei;
                  } 
                  
                  if(highestMarbleInventory < endingId){
                      highestMarbleInventory = endingId; //sets the highest marble ID in store catalogue, used inside modifiers to check if the marble ID being requested is a valid one.
                  }            
                   
    }

    //@dev returns the token price in string format, uint to string
    //@credit "ORACLIZE_API" https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    // <ORACLIZE_API>
    /*
    Copyright (c) 2015-2016 Oraclize SRL
    Copyright (c) 2016 Oraclize LTD
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
    */
    function getMarblePrice(uint256 _tokenId) external view returns (string){
                uint256 marblePrice = marblePrices[_tokenId];
               
                if(marblePrice == 0) return "0";
                uint j = marblePrice;
                uint len;
                while(j != 0){
                    len++;
                    j /= 10;
                }

                bytes memory bstr = new bytes(len);
                uint k = len - 1;
                
                while(marblePrice != 0){
                    bstr[k--] = byte(48 + marblePrice % 10);
                    marblePrice /= 10;
                }

                return string(bstr);
    }

           
  
    //@dev used in requestBuy function. Makes sure that token ID was not created on the contract and creates a placeholder structure for that specific marble.
    modifier MarblePlaceHolderCreation(uint256 _marbleId){
        require(!_exists(_marbleId)); //makes sure marble Id was not created on the contract
        require(_marbleId <= highestMarbleInventory); //makes sure marble Id is lower than highest marble ID available for sale
        marbles[_marbleId] = Marble(_marbleId,"NULL", _marbleId, "NULL", "NULL", "NULL", "NULL", "NULL"); //creates a place holder structure for clients future marble
        placeHolderMarbles[_marbleId] = true; //sets marble ID to true for being a placeholder marble
        last += 1;
        placeHolderMarbleIndex[last] = _marbleId;
        placeHolderMarbleCount++;             //adds one to total placeholder marble account, later used for memorory allocation
         if(highestPlaceHolderCreated < _marbleId){ //checks to see if the highest place holder marble created is lower than marble ID.
            highestPlaceHolderCreated = _marbleId; //if above statement is true  sets the current marble ID to highest place holder marble created
        }
        _;
    }
    
    //@dev used in requestBuy function. uses ERC721BasicToken minting function.
    modifier TokenMint(address _wallet, uint256 _tokenId){
        _mint(_wallet, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        marbleCount++; //adds one to total marble count
        _;
    }

    //@dev before function can be executed it, the priceCheck modifier checks if the price matches to what is stored in marblePrice.
    //IfNotPaused checks to see if the function was paused by the owner of the contract.
    //MarblePlaceHolderCreation creates a marble placeholder structure that will be modified later with attributes from the database
    //TokenMint modifier mints the token Id to that specific wallet, prevents double buying of the same marble in the store.
    //@param _wallet address of a wallet thats making a request to buy a marble
    //@param _tokenId ID of the token thats being requested for purchase
    function requestBuy(uint256 _tokenId) payable external ifNotPaused priceCheck(_tokenId) MarblePlaceHolderCreation(_tokenId) TokenMint(msg.sender, _tokenId) {
                 deposit(msg.value);
    }
     
     //@dev allows the owner of the contract to buy marbles for free
     function requestBuyOwner(uint256 _tokenId) external ifNotPaused onlyOwner MarblePlaceHolderCreation(_tokenId) TokenMint(msg.sender, _tokenId) {
                 
     }

     modifier checkIfMarblePlaceHolder(uint256 _marbleId){
         require(placeHolderMarbles[_marbleId]);
         _;
     }
     
     modifier changePlaceHolderMarbleToFalse(uint256 _marbleId){
         placeHolderMarbles[_marbleId] = false;
         _;
     }
     
     //@dev adds marble attributes to a created marble placeholder
     //@param _tokenId   stores token ID that needs to created
     //@param _material  glass, clay, agate, steel, alabaster
     //@param _size      12mm, 14mm, 16mm, 18mm, 19mm, 22mm, 25mm, 35mm, 41mm, 48mm
     //@param _pattern   1.Corkscrew Swirls 2.Ribbon Swirls 3.Fancy Swirls 4.Catâs Eyes 5.Clouds 6.Onionskins 7.Bullseye 8.Clearies 9.Opaques
     //@param _origin    1.Germany 2.Belgium 3.Japan 4.China 5.US 6.Mexico 
     //@param _forged    handmade, machined, custom
     //@param _grade     mint, near mint, good, exprienced, senior
     //@param _color     list of colors, Example "188-142-94/229-66-251/63-89-145" 
     //@param _uriBase   takes a string of the URI base string, where metadata for that token will be stored, Example (https://api.cryptomibs.co/marbles/10000)                                                                                                 
    function addMarbleAttributes(uint256 _marbleId, uint256 _batch, string _material, uint _size, string _pattern, string _origin, string _forged, string _grade, string _color, string _uriBase) ifNotPaused onlyCreator checkIfMarblePlaceHolder(_marbleId) changePlaceHolderMarbleToFalse(_marbleId) public  {
        marbles[_marbleId] = Marble(_batch, _material, _size, _pattern, _origin, _forged, _grade, _color); //modifies the placeholder marble.
        setTokenURI(_marbleId, _uriBase); //sets token URI
        
        if(highestMarbleCreated < _marbleId){ //checks to see if the highestMarbleCreated is lower than marble ID.
            highestMarbleCreated = _marbleId; //if the above statement returns true, set the new marble ID to highestMarbleCreated.
        }

        
        
        if(last >= first){
            delete placeHolderMarbleIndex[first];
            first += 1;
        }
       
        if(placeHolderMarbleCount != 0){
        placeHolderMarbleCount--;             //decreases the count of all place holder marbles by one.
        }
        
        emit addMarbleAttributesConfirmed(_marbleId); //emits an events sending the wallet address and marble ID of the token that was created and modified with new attributes from database.
        
    }
    
    //@dev used for games to change marble attributes depending on the result of the game. only one of the pre set creator wallets can use this function.
    function changeMarbleAttributes(uint256 _marbleId, uint256 _batch, string _material, uint _size, string _pattern, string _origin, string _forged, string _grade, string _color) public {
          require(gameContracts[msg.sender]);
          marbles[_marbleId] = Marble(_batch, _material, _size, _pattern, _origin, _forged, _grade, _color);
    }
    
    //@dev returns a transfered  marble ID, for processing
    function getTransferedMarbleId() public view returns(uint256 transferedMarble){
        return transferedMarbleIndex[firstFirst];
    }
    
    //@dev checks if marble ID is a recently transfered marble
    modifier checkIfTransferedMarbleIsTrue(uint256 tokenId){
        require(transferedMarbles[tokenId]);
        _;
    }
    
    //@dev changes the status of the transfered marble to false
    modifier changeTransferedMarbleStatusToFalse(uint256 tokenId){
        transferedMarbles[tokenId] = false;
        _;
    }
    
    //@dev increments the transfer marble queue
    function incrementTransferMarbleIndex(uint256 tokenId) public onlyCreator checkIfTransferedMarbleIsTrue(tokenId) changeTransferedMarbleStatusToFalse(tokenId){
         if(lastLast >= firstFirst){
          delete transferedMarbleIndex[firstFirst];
          firstFirst += 1;
        }
    }
    
    //@dev emergency function that force incrments the transfer queue, can only be used by one of the creator wallets
    function forceIncrementTransferMarbleIndex() public onlyCreator returns(bool increment){
        if(lastLast >= firstFirst){
          delete transferedMarbleIndex[firstFirst];
          firstFirst += 1;
          return true;
        }
        return false;
    }    
    

}"},"OwnableSolo.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableSolo {
  
  //@dev stores the wallet address of the owner of the contract
  address public owner;
  
  //@dev stores the wallet address to allow token creation
  address[] public accounts;

  //@dev keeps track if a function is paused or not, only owner of the contract can change this value to true.
  bool public paused = false;
  
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  //@dev throws if "paused" set to true.
  modifier ifNotPaused() {
        require(!paused);
        _;
    }

  //@dev sets the paused variable to false.
  function unpause() public onlyOwner {
        paused = false;
  }
   
  //@dev set the paused varible to true.
  function pause() public onlyOwner{
        paused = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //@dev Throws if called by any account other than the owners wallet address.
  modifier onlyCreator(){
    for (uint i = 0; i < accounts.length; i++){
     if(accounts[i] == msg.sender){
      _;
      return;
     }
    }
    revert();
  }

  //@dev sets a wallet address to be able to create marbles, only the owner of the contract can set a creator
  //@param _newcreator takes the wallet address of a new creator
  function setCreator(address _newcreator) public onlyOwner {
    accounts.push(_newcreator);
  }
  

  //@dev clears the array of all accounts stored
  function deleteCreators() public onlyOwner{
    delete accounts;
  }


  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"PayableSolo.sol":{"content":"pragma solidity ^0.4.11;

import "./OwnableSolo.sol";

contract PayableSolo is OwnableSolo {
    
    //@dev withdraws any funds available on the contract, only the owner of the contract can withdraw funds
    function withdraw() onlyOwner public  {
        msg.sender.transfer(this.balance);  //change above to "(address(contract).balance)"
                          
    }

    //@dev deposits ETH to contract
    //@parm amount the amount being deposited
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        
    }

    //@dev returns the total balance of ETH on the contract
    function getBalance() public view returns (uint256) {
        return this.balance; //changed this to "return address(contract).balance;"
    } 
}

// The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"SafeMath.sol":{"content":"pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."},"SupportsInterfaceWithLookup.sol":{"content":"pragma solidity ^0.4.24;

import "./ERC165.sol";


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

//The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Â© 2018 GitHub, Inc."}}