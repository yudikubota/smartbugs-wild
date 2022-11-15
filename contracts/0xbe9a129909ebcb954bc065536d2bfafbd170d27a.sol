{"Common.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

/*
  Common Utility librarries.
  I. Addresses (extending address).
*/
library Addresses {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function performEthTransfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}(""); // NOLINT: low-level-calls.
        require(success, "ETH_TRANSFER_FAILED");
    }

    /*
      Safe wrapper around ERC20/ERC721 calls.
      This is required because many deployed ERC20 contracts don't return a value.
      See https://github.com/ethereum/solidity/issues/4116.
    */
    function safeTokenContractCall(address tokenAddress, bytes memory callData) internal {
        require(isContract(tokenAddress), "BAD_TOKEN_ADDRESS");
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = tokenAddress.call(callData);
        require(success, string(returndata));

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "TOKEN_OPERATION_FAILED");
        }
    }

    /*
      Similar to safeTokenContractCall, but always ignores the return value.

      Assumes some other method is used to detect the failures
      (e.g. balance is checked before and after the call).
    */
    function uncheckedTokenContractCall(address tokenAddress, bytes memory callData) internal {
        // NOLINTNEXTLINE: low-level-calls.
        (bool success, bytes memory returndata) = tokenAddress.call(callData);
        require(success, string(returndata));
    }

}

library UintArray {
    function hashSubArray(uint256[] memory array, uint256 subArrayStart, uint256 subArraySize)
        internal pure
        returns(bytes32 subArrayHash)
    {
        require(array.length >= subArrayStart + subArraySize, "ILLEGAL_SUBARRAY_DIMENSIONS");
        uint256 startOffsetBytes = 0x20 * (1 + subArrayStart);
        uint256 dataSizeBytes = 0x20 * subArraySize;
        assembly {
            subArrayHash := keccak256(add(array, startOffsetBytes), dataSizeBytes)
        }
    }

    /*
      Returns the address of a cell in offset within a uint256[] array.
      This allows assigning new variable of dynamic unit256[] pointing to a sub_array
      with a layout of serialied uint256[] (i.e. length+content).
    */
    function extractSerializedUintArray(uint256[] memory programOutput, uint256 offset)
        internal pure
        returns (uint256[] memory addr)
    {
        uint256 memOffset = 0x20 * (offset + 1);
        assembly {
            addr := add(programOutput, memOffset)
        }
    }

}

/*
  II. StarkExTypes - Common data types.
*/
library StarkExTypes {

    // Structure representing a list of verifiers (validity/availability).
    // A statement is valid only if all the verifiers in the list agree on it.
    // Adding a verifier to the list is immediate - this is used for fast resolution of
    // any soundness issues.
    // Removing from the list is time-locked, to ensure that any user of the system
    // not content with the announced removal has ample time to leave the system before it is
    // removed.
    struct ApprovalChainData {
        address[] list;
        // Represents the time after which the verifier with the given address can be removed.
        // Removal of the verifier with address A is allowed only in the case the value
        // of unlockedForRemovalTime[A] != 0 and unlockedForRemovalTime[A] < (current time).
        mapping (address => uint256) unlockedForRemovalTime;
    }
}
"},"FactRegistry.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "IQueryableFactRegistry.sol";

contract FactRegistry is IQueryableFactRegistry {
    // Mapping: fact hash -> true.
    mapping (bytes32 => bool) private verifiedFact;

    // Indicates whether the Fact Registry has at least one fact registered.
    bool anyFactRegistered;

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact)
        external view override
        returns(bool)
    {
        return _factCheck(fact);
    }


    /*
      This is an internal method to check if the fact is already registered.
      In current implementation of FactRegistry it's identical to isValid().
      But the check is against the local fact registry,
      So for a derived referral fact registry, it's not the same.
    */
    function _factCheck(bytes32 fact)
        internal view
        returns(bool)
    {
        return verifiedFact[fact];
    }

    function registerFact(
        bytes32 factHash
        )
        internal
    {
        // This function stores the fact hash in the mapping.
        verifiedFact[factHash] = true;

        // Mark first time off.
        if (!anyFactRegistered) {
            anyFactRegistered = true;
        }
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact()
        external view override
        returns(bool)
    {
        return anyFactRegistered;
    }

}
"},"Identity.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

interface Identity {

    /*
      Allows a caller, typically another contract,
      to ensure that the provided address is of the expected type and version.
    */
    function identify()
        external pure
        returns(string memory);
}
"},"IERC20.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

/*
  Interface of the ERC20 standard as defined in the EIP. Does not include
  the optional functions; to access them see {ERC20Detailed}.
*/
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
     external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"IFactRegistry.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact)
        external view
        returns(bool);
}
"},"IQueryableFactRegistry.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {

    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact()
        external view
        returns(bool);

}
"},"TransferRegistry.sol":{"content":"/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "FactRegistry.sol";
import "Identity.sol";
import "Common.sol";
import "IERC20.sol";

contract TransferRegistry is FactRegistry, Identity {

    event LogRegisteredTransfer(
        address recipient,
        address token,
        uint256 amount,
        uint256 salt
    );

    using Addresses for address;

    function identify()
        external pure virtual override
        returns(string memory)
    {
        return "StarkWare_TransferRegistry_2020_1";
    }

    /*
      The actual transfer is extracted to a function, so that we can easily mock the contract.
    */
    function performEthTransfer(address recipient, uint256 value)
        internal
        virtual {
        recipient.performEthTransfer(value);
    }

    /*
      The actual transfer is extracted to a function, so that we can easily mock the contract.
    */
    function performErc20Transfer(address recipient, address erc20, uint256 amount)
        internal
        virtual {
        erc20.safeTokenContractCall(
            abi.encodeWithSelector(IERC20(0).transferFrom.selector, msg.sender, recipient, amount)
        );
    }

    /*
      Passes on the transaction ETH value onto the recipient address,
      and register the associated fact.
      Reverts if the fact has already been registered.
    */
    function transfer(address recipient, uint256 salt) // NOLINT: erc20-interface.
        external
        payable {
        bytes32 transferFact = keccak256(
            abi.encodePacked(recipient, msg.value, address(0x0), salt));
        require(!_factCheck(transferFact), "TRANSFER_ALREADY_REGISTERED");
        registerFact(transferFact);
        emit LogRegisteredTransfer(recipient, address(0x0), msg.value, salt);
        performEthTransfer(recipient, msg.value);
    }

    /*
      Transfer the specified amount of erc20 tokens from msg.sender balance to the recipient's
      balance.
      Pre-conditions to successful transfer are that the msg.sender has sufficient balance,
      and the the approval (for the transfer) was granted to this contract.
      A fact with the transfer details is registered upon success.
      Reverts if the fact has already been registered.
    */
    function transferERC20(address recipient, address erc20, uint256 amount, uint256 salt)
        external {
        bytes32 transferFact = keccak256(
            abi.encodePacked(recipient, amount, erc20, salt));
        require(!_factCheck(transferFact), "TRANSFER_ALREADY_REGISTERED");
        registerFact(transferFact);
        emit LogRegisteredTransfer(recipient, erc20, amount, salt);
        performErc20Transfer(recipient, erc20, amount);
    }

}
"}}