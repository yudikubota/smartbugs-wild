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
}"},"Forwarder.sol":{"content":"pragma solidity ^0.4.18;

import "./DelegateProxy.sol";

contract Forwarder is DelegateProxy {
  // After compiling contract, `beefbeef...` is replaced in the bytecode by the real target address
  address public constant target = 0x1ed7fc52ac5a37aa3ff6d9b94c894724e2f992b1; // checksumed to silence warning

  /*
  * @dev Forwards all calls to target
  */
  function() payable {
    delegatedFwd(target, msg.data);
  }
}"}}