{"CxipERC721Proxy.sol":{"content":"// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___        
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_       
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_      
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__     
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____    
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________   
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________  
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________ 
        _______\/////////__\///_______\///__\///////////__\///____________*/

import './ICxipRegistry.sol';

contract CxipERC721Proxy {

	fallback () payable external {
		address _target = ICxipRegistry (0xC267d41f81308D7773ecB3BDd863a902ACC01Ade).getERC721CollectionSource ();
		assembly {
			calldatacopy (0, 0, calldatasize ())
			let result := delegatecall (gas (), _target, 0, calldatasize (), 0, 0)
			returndatacopy (0, 0, returndatasize ())
			switch result
				case 0 {
					revert (0, returndatasize ())
				}
				default {
					return (0, returndatasize ())
				}
		}
	}

}
"},"ICxipRegistry.sol":{"content":"// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___        
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_       
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_      
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__     
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____    
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________   
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________  
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________ 
        _______\/////////__\///_______\///__\///////////__\///____________*/

interface ICxipRegistry {

	function getPA1D () external view returns (address);

	function setPA1D (address proxy) external;

	function getPA1DSource () external view returns (address);

	function setPA1DSource (address source) external;

	function getAsset () external view returns (address);

	function setAsset (address proxy) external;

	function getAssetSource () external view returns (address);

	function setAssetSource (address source) external;

	function getCopyright () external view returns (address);

	function setCopyright (address proxy) external;

	function getCopyrightSource () external view returns (address);

	function setCopyrightSource (address source) external;

	function getProvenance () external view returns (address);

	function setProvenance (address proxy) external;

	function getProvenanceSource () external view returns (address);

	function setProvenanceSource (address source) external;

	function getIdentitySource () external view returns (address);

	function setIdentitySource (address source) external;

	function getERC721CollectionSource () external view returns (address);

	function setERC721CollectionSource (address source) external;

	function getERC1155CollectionSource () external view returns (address);

	function setERC1155CollectionSource (address source) external;

	function getAssetSigner () external view returns (address);

	function setAssetSigner (address source) external;

	function getCustomSource (bytes32 name) external view returns (address);

	function getCustomSourceFromString (string memory name) external view returns (address);

	function setCustomSource (string memory name, address source) external;

	function owner () external view returns (address);

}"}}