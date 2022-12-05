{"DelegateProxy.sol":{"content":"pragma solidity ^0.4.18;

contract DelegateProxy {
  /**
  * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
  * @param _dst Destination address to perform the delegatecall
  * @param _calldata Calldata for the delegatecall
  */
  function delegatedFwd(address _dst, bytes _calldata) internal {
    require(isContract(_dst));
    assembly {
      let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
      let size := returndatasize

      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)

    // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
    // if the call returned error data, forward it
      switch result case 0 {revert(ptr, size)}
      default {return (ptr, size)}
    }
  }

  function isContract(address _target) internal view returns (bool) {
    uint256 size;
    assembly {size := extcodesize(_target)}
    return size > 0;
  }
}"},"DSAuth.sol":{"content":"// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.13;

contract DSAuthority {
  function canCall(
    address src, address dst, bytes4 sig
  ) public view returns (bool);
}

contract DSAuthEvents {
  event LogSetAuthority (address indexed authority);
  event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
  DSAuthority  public  authority;
  address      public  owner;

  function DSAuth() public {
    owner = msg.sender;
    LogSetOwner(msg.sender);
  }

  function setOwner(address owner_)
  public
  auth
  {
    owner = owner_;
    LogSetOwner(owner);
  }

  function setAuthority(DSAuthority authority_)
  public
  auth
  {
    authority = authority_;
    LogSetAuthority(authority);
  }

  modifier auth {
    require(isAuthorized(msg.sender, msg.sig));
    _;
  }

  function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
    if (src == address(this)) {
      return true;
    } else if (src == owner) {
      return true;
    } else if (authority == DSAuthority(0)) {
      return false;
    } else {
      return authority.canCall(src, this, sig);
    }
  }
}
"},"MutableForwarder.sol":{"content":"pragma solidity ^0.4.18;

import "./DelegateProxy.sol";
import "./DSAuth.sol";

/**
 * @title Forwarder proxy contract with editable target
 *
 * @dev For TCR Registry contracts (Registry.sol, ParamChangeRegistry.sol) we use mutable forwarders instead of using
 * contracts directly. This is for better upgradeability. Since registry contracts fire all events related to registry
 * entries, we want to be able to access whole history of events always on the same address. Which would be address of
 * a MutableForwarder. When a registry contract is replaced with updated one, mutable forwarder just replaces target
 * and all events stay still accessible on the same address.
 */

contract MutableForwarder is DelegateProxy, DSAuth {

  address public target = 0xf4e6e033921b34f89b0586beb2d529e8eae3e021; // checksumed to silence warning

  /**
   * @dev Replaces targer forwarder contract is pointing to
   * Only authenticated user can replace target

   * @param _target New target to proxy into
  */
  function setTarget(address _target) public auth {
    target = _target;
  }

  function() payable {
    delegatedFwd(target, msg.data);
  }

}"}}