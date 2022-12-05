{{
  "language": "Solidity",
  "sources": {
    "./contracts/external/UniswapV2Router.sol": {
      "content": "pragma solidity ^0.5.17;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
"
    },
    "./contracts/external/UniswapV2OracleLibrary.sol": {
      "content": "pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
    internal
    view
    returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}"
    },
    "./contracts/external/Decimal.sol": {
      "content": "/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}
"
    },
    "./contracts/external/UniswapV2Library.sol": {
      "content": "pragma solidity >=0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}"
    },
    "./contracts/external/Require.sol": {
      "content": "/*
    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.7;

/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}"
    },
    "./contracts/external/LibEIP712.sol": {
      "content": "/*
    Copyright 2019 ZeroEx Intl.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.9;


library LibEIP712 {

    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    )
    internal
    pure
    returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
        // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

        // Load free memory pointer
            let memPtr := mload(64)

        // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

        // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
    internal
    pure
    returns (bytes32 result)
    {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
        // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

        // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}"
    },
    "./contracts/oracle/PoolSetters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PoolState.sol";
import "./PoolGetters.sol";

contract PoolSetters is PoolState, PoolGetters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function pause() internal {
        _state.paused = true;
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address account, uint256 amount) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.add(amount);
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementBalanceOfBonded(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.sub(amount, reason);
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfClaimable(address account, uint256 amount) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.add(amount);
        _state.balance.claimable = _state.balance.claimable.add(amount);
    }

    function decrementBalanceOfClaimable(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.sub(amount, reason);
        _state.balance.claimable = _state.balance.claimable.sub(amount, reason);
    }

    function incrementBalanceOfPhantom(address account, uint256 amount) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.add(amount);
        _state.balance.phantom = _state.balance.phantom.add(amount);
    }

    function decrementBalanceOfPhantom(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.sub(amount, reason);
        _state.balance.phantom = _state.balance.phantom.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getPoolExitLockupEpochs());
    }
}
"
    },
    "./contracts/oracle/PoolState.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/IDollar.sol";
import "./IDAO.sol";

contract PoolAccount {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        uint256 fluidUntil;
    }
}

contract PoolStorage {
    struct Balance {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
    }

    struct State {
        IDAO dao;

        IERC20 stakingToken;
        IERC20 rewardsToken;

        Balance balance;
        bool paused;

        mapping(address => PoolAccount.State) accounts;
    }
}

contract PoolState {
    PoolStorage.State _state;
}
"
    },
    "./contracts/token/IDollar.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}
"
    },
    "./contracts/oracle/IDAO.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./IOracle.sol";
import "../external/Decimal.sol";

contract IDAO {
    function epoch() external view returns (uint256);
    function oracle() external view returns (IOracle);
    function bootstrappingAt(uint256) external view returns (bool);
    function oracleCaptureP() public returns (Decimal.D256 memory);
}"
    },
    "./contracts/oracle/IOracle.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";

contract IOracle {
    function setup() public;
    function capture() public returns (Decimal.D256 memory, bool);
    function pair() external view returns (address);
}"
    },
    "./contracts/oracle/PoolGetters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IDAO.sol";
import "../external/Decimal.sol";
import "./PoolState.sol";
import "../Constants.sol";

contract PoolGetters is PoolState {
    using SafeMath for uint256;

    /**
     * Global
     */

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function dao() public view returns (IDAO) {
        return _state.dao;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable() public view returns (uint256) {
        return _state.balance.claimable;
    }

    function totalPhantom() public view returns (uint256) {
        return _state.balance.phantom;
    }

    function totalRewarded() public view returns (uint256) {
        return rewardsToken().balanceOf(address(this)).sub(totalClaimable());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable(address account) public view returns (uint256) {
        return _state.accounts[account].claimable;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom(address account) public view returns (uint256) {
        return _state.accounts[account].phantom;
    }

    function balanceOfRewarded(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function statusOf(address account) public view returns (PoolAccount.Status) {
        return epoch() >= _state.accounts[account].fluidUntil ? PoolAccount.Status.Frozen : PoolAccount.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }

    function bootstrappingAt(uint256 epoch) internal returns (bool) {
        return dao().bootstrappingAt(epoch);
    }

    function oracleCapture() internal returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = dao().oracle().capture();

        if (dao().bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }

        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    /**
     * Staking Rewards
     */

    function stakingToken() public view returns (IERC20) {
        return _state.stakingToken;
    }

    function rewardsToken() public view returns (IERC20) {
        return _state.rewardsToken;
    }
}
"
    },
    "./contracts/Constants.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    // QSD #3
    uint256 private constant BOOTSTRAPPING_PERIOD = 72;
    uint256 private constant BOOTSTRAPPING_PRICE = 11e17; // 1.10 DAI

    /* Oracle */
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 10000e18; // 10,000 DAI

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 ESD -> 100M ESDS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant PREVIOUS_EPOCH_OFFSET = 0;
    uint256 private constant PREVIOUS_EPOCH_START = 0;
    uint256 private constant PREVIOUS_EPOCH_PERIOD = 0;

    // QSD #1
    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START =  1612008000;// 2020/01/30 12:00 UTC;
    uint256 private constant CURRENT_EPOCH_PERIOD = 14400; // 4 hours

    /* Governance */
    // QSD #C.a
    uint256 private constant GOVERNANCE_MAX_SUPPLY = 999999999e18; // 999,999,999
    uint256 private constant GOVERNANCE_DISTRIBUTED_PER_BLOCK = 9e16; // 0.09

    // QSD #C.g
    uint256 private constant GOVERNANCE_PERIOD = 9; // 9 epochs
    uint256 private constant GOVERNANCE_EXPIRATION = 2; // 2 + 1 epochs
    uint256 private constant GOVERNANCE_QUORUM = 33e16; // 33%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 9e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 ESD    
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 1; // 1 epochs fluid

    /* Pool */
    // QSD #9
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 1; // 1 epochs fluid

    /* Market */
    uint256 private constant DEBT_RATIO_CAP = 15e16; // 15%

    /* Regulator (post-bootstrap) */
    // QSD #2
    uint256 private constant SUPPLY_CHANGE_LIMIT = 54e15; // 5.4% Expansion/Contraction limit
    uint256 private constant POOL_BONDING_RATIO = 67; // 67%
    uint256 private constant POOL_LP_RATIO = 23; // 23%
    uint256 private constant TREASURY_RATIO = 5; // 5%
    uint256 private constant GOV_STAKING_RATIO = 5; // 5%

    /* External */
    address private constant TREASURY_ADDRESS = address(0x61c32f08B0cbe61feF4166f09363504b4b5F38d8);

    /**
     * Getters
     */

    function getDaiAddress() internal pure returns (address) {
        return DAI;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getPreviousEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: PREVIOUS_EPOCH_OFFSET,
            start: PREVIOUS_EPOCH_START,
            period: PREVIOUS_EPOCH_PERIOD
        });
    }

    function getCurrentEpochStrategy() internal pure returns (EpochStrategy memory) {
        return EpochStrategy({
            offset: CURRENT_EPOCH_OFFSET,
            start: CURRENT_EPOCH_START,
            period: CURRENT_EPOCH_PERIOD
        });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint256) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }
    
    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getPoolLPRatio() internal pure returns (uint256) {
        return POOL_LP_RATIO;
    }

    function getPoolBondingRatio() internal pure returns (uint256) {
        return POOL_BONDING_RATIO;
    }

    function getGovStakingRatio() internal pure returns (uint256) {
        return GOV_STAKING_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function getGovernanceTokenMaxSupply() internal pure returns (uint256) {
        return GOVERNANCE_MAX_SUPPLY;
    }

    function getGovernanceTokenPerBlock() internal pure returns (uint256) {
        return GOVERNANCE_DISTRIBUTED_PER_BLOCK;
    }
}
"
    },
    "./contracts/oracle/Liquidity.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../external/UniswapV2Library.sol";
import "../external/UniswapV2Router.sol";
import "../Constants.sol";
import "./Permission.sol";
import "./PoolSetters.sol";

contract Liquidity is PoolSetters, Permission {
    using SafeERC20 for IERC20;

    bytes32 private constant FILE = "Liquidity";

    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Provide(address indexed account, uint256 value, uint256 lessDai, uint256 newUniv2);

    function provide(uint256 value) external onlyFrozen(msg.sender) notPaused validBalance {
        Require.that(totalBonded() > 0, FILE, "insufficient total bonded");

        Require.that(totalRewarded() > 0, FILE, "insufficient total rewarded");

        Require.that(balanceOfRewarded(msg.sender) >= value, FILE, "insufficient rewarded balance");

        (uint256 lessDai, uint256 newUniv2) = addLiquidity(value);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom()).add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom.mul(newUniv2).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, newUniv2);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));

        emit Provide(msg.sender, value, lessDai, newUniv2);
    }

    function provideOneSided(uint256 value) external onlyFrozen(msg.sender) notPaused validBalance {
        Require.that(totalBonded() > 0, FILE, "insufficient total bonded");
        Require.that(totalRewarded() > 0, FILE, "insufficient total rewarded");
        Require.that(balanceOfRewarded(msg.sender) >= value, FILE, "insufficient rewarded balance");

        uint256 newUniv2 = optimalOneSidedAddLiquidity(value);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom()).add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom.mul(newUniv2).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, newUniv2);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));

        emit Provide(msg.sender, value, 0, newUniv2);
    }

    // https://github.com/AlphaFinanceLab/alphahomora/blob/734affeb76695c16517fe184d714dfa3033a6484/contracts/5/StrategyAddETHOnly.sol#L40
    function optimalOneSidedAddLiquidity(uint256 dollarAmount) internal returns (uint256) {
        // Optimal one side liquidity supply
        IUniswapV2Pair pair = IUniswapV2Pair(address(stakingToken()));

        address dai = dai();
        address dollar = pair.token0() == dai ? pair.token1() : pair.token0();

        // Compute optimal amount of dollar to be converted to DAI
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 rIn = pair.token0() == dollar ? r0 : r1;
        uint256 aIn = getOptimalSwapAmount(rIn, dollarAmount);

        // Convert that portion into DAI
        address[] memory path = new address[](2);
        path[0] = dollar;
        path[1] = dai;

        IERC20(dollar).safeApprove(address(router), 0);
        IERC20(dollar).safeApprove(address(router), uint256(-1));
        uint256[] memory outputs = router.swapExactTokensForTokens(aIn, 0, path, address(this), now + 60);

        // Supply liquidity
        uint256 supplyDollarAmount = dollarAmount.sub(aIn);
        uint256 supplyDaiAmount = outputs[1];

        IERC20(dollar).safeApprove(address(router), 0);
        IERC20(dollar).safeApprove(address(router), supplyDollarAmount);

        IERC20(dai).safeApprove(address(router), 0);
        IERC20(dai).safeApprove(address(router), supplyDaiAmount);
        (, , uint256 lpAmountMinted) =
            router.addLiquidity(dollar, dai, supplyDollarAmount, supplyDaiAmount, 0, 0, address(this), now + 60);

        return lpAmountMinted;
    }

    function getOptimalSwapAmount(uint256 amt, uint256 res) internal pure returns (uint256) {
        return sqrt(amt.mul(res.mul(3988000).add(amt.mul(3988009)))).sub(amt.mul(1997)) / 1994;
    }

    function addLiquidity(uint256 dollarAmount) internal returns (uint256, uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(stakingToken()));

        (address tokenA, address tokenB) = (pair.token0(), pair.token1());
        (address dollar, address dai) = (tokenA == dai() ? tokenB : tokenA, dai());
        (uint256 reserveA, uint256 reserveB) = getReserves(dollar, dai);

        uint256 daiAmount =
            (reserveA == 0 && reserveB == 0) ? dollarAmount : UniswapV2Library.quote(dollarAmount, reserveA, reserveB);

        // Assume that the staking token is the pair
        IERC20(dollar).transfer(address(pair), dollarAmount);
        IERC20(dai).transferFrom(msg.sender, address(pair), daiAmount);
        return (daiAmount, pair.mint(address(this)));
    }

    // overridable for testing
    function getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_FACTORY, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
"
    },
    "./contracts/oracle/Permission.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PoolState.sol";
import "./PoolGetters.sol";
import "../external/Require.sol";

contract Permission is PoolState, PoolGetters {
    bytes32 private constant FILE = "Permission";

    modifier onlyFrozen(address account) {
        Require.that(
            statusOf(account) == PoolAccount.Status.Frozen,
            FILE,
            "Not frozen"
        );

        _;
    }

    modifier onlyDao() {
        Require.that(
            msg.sender == address(dao()),
            FILE,
            "Not dao"
        );

        _;
    }

    modifier notPaused() {
        Require.that(
            !paused(),
            FILE,
            "Paused"
        );

        _;
    }

    modifier validBalance() {
        _;

        Require.that(
            stakingToken().balanceOf(address(this)) >= totalStaged().add(totalBonded()),
            FILE,
            "Inconsistent balances"
        );
    }
}
"
    },
    "./contracts/oracle/pool-bonding/State.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../token/IDollar.sol";
import "../IDAO.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 claimable1;
        uint256 claimable2;
        uint256 bonded;
        uint256 phantom1;
        uint256 phantom2;
        uint256 fluidUntil;
    }
}

contract Storage {
    struct Balance {
        uint256 staged;
        uint256 claimable1;
        uint256 claimable2;
        uint256 bonded;
        uint256 phantom1;
        uint256 phantom2;
    }

    struct State {
        IDAO dao;

        IERC20 stakingToken;
        IERC20 rewardsToken1;
        IERC20 rewardsToken2;

        Balance balance;
        bool paused;

        mapping(address => Account.State) accounts;
    }
}

contract State {
    Storage.State _state;
}
"
    },
    "./contracts/oracle/pool-bonding/Pool.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../external/Require.sol";
import "../../external/Decimal.sol";
import "../../Constants.sol";
import "./Permission.sol";
import "./Setters.sol";

contract PoolBonding is Setters, Permission {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Pool";

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken1,
        IERC20 _rewardsToken2
    ) public {
        _state.dao = _dao;
        _state.stakingToken = _stakingToken;
        _state.rewardsToken1 = _rewardsToken1;
        _state.rewardsToken2 = _rewardsToken2;
    }

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Claim(address indexed account, address token, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 newClaimable1, uint256 newClaimable2);

    function deposit(uint256 value) external onlyFrozen(msg.sender) notPaused {
        stakingToken().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozen(msg.sender) validBalance {
        stakingToken().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Withdraw(msg.sender, value);
    }

    function bond(uint256 value) public validBalance {
        // QSD #B
        // Logic kicks in post bootstrapping epoch - 2
        // -2 to give 1 extra epoch time for ppl to bond
        if (epoch() > 2) {
            if (!bootstrappingAt(epoch().sub(2))) {
                Decimal.D256 memory price = oracleCapture();
                
                Require.that(price.lessThan(Decimal.one()), FILE, "Cannot bond when price >1");
            }
        }

        _bond(value);
    }

    function _bond(uint256 value) internal notPaused {
        unfreeze(msg.sender);

        uint256 totalRewardedWithPhantom1 = totalRewarded1().add(totalPhantom1());
        uint256 newPhantom1 =
            totalBonded() == 0
                ? totalRewarded1() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0
                : totalRewardedWithPhantom1.mul(value).div(totalBonded());

        uint256 totalRewardedWithPhantom2 = totalRewarded2().add(totalPhantom2());
        uint256 newPhantom2 =
            totalBonded() == 0
                ? totalRewarded2() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0
                : totalRewardedWithPhantom2.mul(value).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, value);
        incrementBalanceOfPhantom1(msg.sender, newPhantom1);
        incrementBalanceOfPhantom2(msg.sender, newPhantom2);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Bond(msg.sender, epoch().add(1), value);
    }

    // QSD #C.b
    function unbond(uint256 value) public validBalance {
        unfreeze(msg.sender);

        uint256 balanceOfBonded = balanceOfBonded(msg.sender);
        Require.that(balanceOfBonded > 0, FILE, "insufficient bonded balance");

        uint256 newClaimable1 = balanceOfRewarded1(msg.sender).mul(value).div(balanceOfBonded);
        uint256 newClaimable2 = balanceOfRewarded2(msg.sender).mul(value).div(balanceOfBonded);

        uint256 lessPhantom1 = balanceOfPhantom1(msg.sender).mul(value).div(balanceOfBonded);
        uint256 lessPhantom2 = balanceOfPhantom2(msg.sender).mul(value).div(balanceOfBonded);

        incrementBalanceOfStaged(msg.sender, value);
        incrementBalanceOfClaimable1(msg.sender, newClaimable1);
        incrementBalanceOfClaimable2(msg.sender, newClaimable2);
        decrementBalanceOfBonded(msg.sender, value, "Pool: insufficient bonded balance");
        decrementBalanceOfPhantom1(msg.sender, lessPhantom1, "Pool: insufficient phantom1 balance");
        decrementBalanceOfPhantom2(msg.sender, lessPhantom2, "Pool: insufficient phantom2 balance");

        emit Unbond(msg.sender, epoch().add(1), value, newClaimable1, newClaimable2);
    }

    // Function to allow users to move rewards to claimable
    // while twap is < 1
    function pokeRewards() external {
        uint256 balanceOfBonded = balanceOfBonded(msg.sender);

        unbond(balanceOfBonded);
        _bond(balanceOfBonded);
    }

    function claimAll() external {
        claim1(balanceOfClaimable1(msg.sender));
        claim2(balanceOfClaimable2(msg.sender));
    }

    function claim1(uint256 value) public onlyFrozen(msg.sender) validBalance {
        rewardsToken1().transfer(msg.sender, value);
        decrementBalanceOfClaimable1(msg.sender, value, "Pool: insufficient claimable balance");

        emit Claim(msg.sender, address(rewardsToken1()), value);
    }

    function claim2(uint256 value) public onlyFrozen(msg.sender) validBalance {
        rewardsToken2().transfer(msg.sender, value);
        decrementBalanceOfClaimable2(msg.sender, value, "Pool: insufficient claimable balance");

        emit Claim(msg.sender, address(rewardsToken2()), value);
    }

    function emergencyWithdraw(address token, uint256 value) external onlyDao {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause() external onlyDao {
        pause();
    }
}
"
    },
    "./contracts/oracle/pool-bonding/Permission.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./State.sol";
import "./Getters.sol";
import "../../external/Require.sol";

contract Permission is State, Getters {
    bytes32 private constant FILE = "Permission";

    modifier onlyFrozen(address account) {
        Require.that(
            statusOf(account) == Account.Status.Frozen,
            FILE,
            "Not frozen"
        );

        _;
    }

    modifier onlyDao() {
        Require.that(
            msg.sender == address(dao()),
            FILE,
            "Not dao"
        );

        _;
    }

    modifier notPaused() {
        Require.that(
            !paused(),
            FILE,
            "Paused"
        );

        _;
    }

    modifier validBalance() {
        _;

        Require.that(
            stakingToken().balanceOf(address(this)) >= totalStaged().add(totalBonded()),
            FILE,
            "Inconsistent balances"
        );
    }
}
"
    },
    "./contracts/oracle/pool-bonding/Getters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../IDAO.sol";
import "../../external/Decimal.sol";
import "./State.sol";
import "../../Constants.sol";

contract Getters is State {
    using SafeMath for uint256;

    /**
     * Global
     */

    function dai() public view returns (address) {
        return Constants.getDaiAddress();
    }

    function dao() public view returns (IDAO) {
        return _state.dao;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalClaimable1() public view returns (uint256) {
        return _state.balance.claimable1;
    }

    function totalClaimable2() public view returns (uint256) {
        return _state.balance.claimable2;
    }

    function totalPhantom1() public view returns (uint256) {
        return _state.balance.phantom1;
    }

    function totalPhantom2() public view returns (uint256) {
        return _state.balance.phantom2;
    }

    function totalRewarded1() public view returns (uint256) {
        // If staking token and rewards token are the same
        if (stakingToken() == rewardsToken1()) {
            return
                rewardsToken1().balanceOf(address(this)).sub(totalClaimable1()).sub(totalBonded()).sub(totalStaged());
        }

        return rewardsToken1().balanceOf(address(this)).sub(totalClaimable1());
    }

    function totalRewarded2() public view returns (uint256) {
        // If staking token and rewards token are the same
        if (stakingToken() == rewardsToken2()) {
            return
                rewardsToken2().balanceOf(address(this)).sub(totalClaimable2()).sub(totalBonded()).sub(totalStaged());
        }

        return rewardsToken2().balanceOf(address(this)).sub(totalClaimable2());
    }

    function paused() public view returns (bool) {
        return _state.paused;
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfClaimable1(address account) public view returns (uint256) {
        return _state.accounts[account].claimable1;
    }

    function balanceOfClaimable2(address account) public view returns (uint256) {
        return _state.accounts[account].claimable2;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }

    function balanceOfPhantom1(address account) public view returns (uint256) {
        return _state.accounts[account].phantom1;
    }

    function balanceOfPhantom2(address account) public view returns (uint256) {
        return _state.accounts[account].phantom2;
    }

    function balanceOfRewarded1(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded1().add(totalPhantom1());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom1(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function balanceOfRewarded2(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }

        uint256 totalRewardedWithPhantom = totalRewarded2().add(totalPhantom2());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom.mul(balanceOfBonded(account)).div(totalBonded);

        uint256 balanceOfPhantom = balanceOfPhantom2(account);
        if (balanceOfRewardedWithPhantom > balanceOfPhantom) {
            return balanceOfRewardedWithPhantom.sub(balanceOfPhantom);
        }
        return 0;
    }

    function statusOf(address account) public view returns (Account.Status) {
        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    /**
     * Epoch
     */

    function epoch() internal view returns (uint256) {
        return dao().epoch();
    }

    function bootstrappingAt(uint256 epoch) internal returns (bool) {
        return dao().bootstrappingAt(epoch);
    }

    function oracleCapture() internal returns (Decimal.D256 memory) {
        return dao().oracleCaptureP();
    }

    /**
     * Staking Rewards
     */

    function stakingToken() public view returns (IERC20) {
        return _state.stakingToken;
    }

    function rewardsToken1() public view returns (IERC20) {
        return _state.rewardsToken1;
    }

    function rewardsToken2() public view returns (IERC20) {
        return _state.rewardsToken2;
    }
}
"
    },
    "./contracts/oracle/pool-bonding/Setters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./State.sol";
import "./Getters.sol";

contract Setters is State, Getters {
    using SafeMath for uint256;

    /**
     * Global
     */

    function pause() internal {
        _state.paused = true;
    }

    /**
     * Account
     */

    function incrementBalanceOfBonded(address account, uint256 amount) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.add(amount);
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementBalanceOfBonded(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.sub(amount, reason);
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function incrementBalanceOfClaimable1(address account, uint256 amount) internal {
        _state.accounts[account].claimable1 = _state.accounts[account].claimable1.add(amount);
        _state.balance.claimable1 = _state.balance.claimable1.add(amount);
    }

    function incrementBalanceOfClaimable2(address account, uint256 amount) internal {
        _state.accounts[account].claimable2 = _state.accounts[account].claimable2.add(amount);
        _state.balance.claimable2 = _state.balance.claimable2.add(amount);
    }

    function decrementBalanceOfClaimable1(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].claimable1 = _state.accounts[account].claimable1.sub(amount, reason);
        _state.balance.claimable1 = _state.balance.claimable1.sub(amount, reason);
    }

    function decrementBalanceOfClaimable2(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].claimable2 = _state.accounts[account].claimable2.sub(amount, reason);
        _state.balance.claimable2 = _state.balance.claimable2.sub(amount, reason);
    }

    function incrementBalanceOfPhantom1(address account, uint256 amount) internal {
        _state.accounts[account].phantom1 = _state.accounts[account].phantom1.add(amount);
        _state.balance.phantom1 = _state.balance.phantom1.add(amount);
    }

    function incrementBalanceOfPhantom2(address account, uint256 amount) internal {
        _state.accounts[account].phantom2 = _state.accounts[account].phantom2.add(amount);
        _state.balance.phantom2 = _state.balance.phantom2.add(amount);
    }

    function decrementBalanceOfPhantom1(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].phantom1 = _state.accounts[account].phantom1.sub(amount, reason);
        _state.balance.phantom1 = _state.balance.phantom1.sub(amount, reason);
    }

    function decrementBalanceOfPhantom2(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].phantom2 = _state.accounts[account].phantom2.sub(amount, reason);
        _state.balance.phantom2 = _state.balance.phantom2.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getPoolExitLockupEpochs());
    }
}
"
    },
    "./contracts/oracle/PoolLP.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Pool.sol";
import "./Liquidity.sol";

contract PoolLP is Pool, Liquidity {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Pool Liquidity";

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken
    ) public Pool(_dao, _stakingToken, _rewardsToken) {}
}
"
    },
    "./contracts/oracle/Pool.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../external/Require.sol";
import "../Constants.sol";
import "./IDAO.sol";
import "./Permission.sol";
import "./PoolSetters.sol";

contract Pool is PoolSetters, Permission {
    using SafeMath for uint256;

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken
    ) public {
        _state.dao = _dao;
        _state.stakingToken = _stakingToken;
        _state.rewardsToken = _rewardsToken;
    }

    bytes32 private constant FILE = "Pool";

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Claim(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 newClaimable);

    function deposit(uint256 value) external onlyFrozen(msg.sender) notPaused {
        stakingToken().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) public onlyFrozen(msg.sender) validBalance {
        stakingToken().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Withdraw(msg.sender, value);
    }

    function claim(uint256 value) external onlyFrozen(msg.sender) validBalance {
        rewardsToken().transfer(msg.sender, value);
        decrementBalanceOfClaimable(msg.sender, value, "Pool: insufficient claimable balance");

        emit Claim(msg.sender, value);
    }

    function bond(uint256 value) public notPaused validBalance {
        unfreeze(msg.sender);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 newPhantom =
            totalBonded() == 0
                ? totalRewarded() == 0 ? Constants.getInitialStakeMultiple().mul(value) : 0
                : totalRewardedWithPhantom.mul(value).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, value);
        incrementBalanceOfPhantom(msg.sender, newPhantom);
        decrementBalanceOfStaged(msg.sender, value, "Pool: insufficient staged balance");

        emit Bond(msg.sender, epoch().add(1), value);
    }

    function unbond(uint256 value) public validBalance {
        unfreeze(msg.sender);

        uint256 balanceOfBonded = balanceOfBonded(msg.sender);
        Require.that(balanceOfBonded > 0, FILE, "insufficient bonded balance");

        uint256 newClaimable = balanceOfRewarded(msg.sender).mul(value).div(balanceOfBonded);
        uint256 lessPhantom = balanceOfPhantom(msg.sender).mul(value).div(balanceOfBonded);

        incrementBalanceOfStaged(msg.sender, value);
        incrementBalanceOfClaimable(msg.sender, newClaimable);
        decrementBalanceOfBonded(msg.sender, value, "Pool: insufficient bonded balance");
        decrementBalanceOfPhantom(msg.sender, lessPhantom, "Pool: insufficient phantom balance");

        emit Unbond(msg.sender, epoch().add(1), value, newClaimable);
    }

    function emergencyWithdraw(address token, uint256 value) external onlyDao {
        IERC20(token).transfer(address(dao()), value);
    }

    function emergencyPause() external onlyDao {
        pause();
    }
}
"
    },
    "./contracts/oracle/PoolGov.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";
import "./Pool.sol";
import "./Liquidity.sol";

contract PoolGov is Pool {
    // Staking for governance token

    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Pool Gov";

    mapping(address => uint256) public lockedUntil;

    constructor(
        IDAO _dao,
        IERC20 _stakingToken,
        IERC20 _rewardsToken
    ) public Pool(_dao, _stakingToken, _rewardsToken) {}

    // Locks token in place i.e. they can't unbond it
    function placeLock(address account, uint256 newLock) external onlyDao {
        if (newLock > lockedUntil[account]) {
            lockedUntil[account] = newLock;
        }
    }

    function withdraw(uint256 value) public {
        // When voting, dao can place a lock on the contract
        Require.that(epoch() > lockedUntil[msg.sender], FILE, "Locked till gov passes");

        Pool.withdraw(value);
    }

    function statusOf(address user) public view returns (PoolAccount.Status) {
        if (epoch() <= lockedUntil[user]) {
            return PoolAccount.Status.Locked;
        }

        return PoolGetters.statusOf(user);
    }
}
"
    },
    "./contracts/oracle/IUSDC.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;

contract IUSDC {
    function isBlacklisted(address _account) external view returns (bool);
}"
    },
    "./contracts/oracle/Oracle.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../external/UniswapV2OracleLibrary.sol";
import "../external/UniswapV2Library.sol";
import "../external/Require.sol";
import "../external/Decimal.sol";
import "./IOracle.sol";
import "./IUSDC.sol";
import "../Constants.sol";

contract Oracle is IOracle {
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Oracle";
    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address internal _dao;
    address internal _dollar;

    bool internal _initialized;
    IUniswapV2Pair internal _pair;
    uint256 internal _index;
    uint256 public _cumulative;
    uint32 public _timestamp;

    uint256 internal _reserve;

    constructor(address dollar) public {
        _dao = msg.sender;
        _dollar = dollar;
    }

    function setup() public onlyDao {
        if (IUniswapV2Factory(UNISWAP_FACTORY).getPair(_dollar, dai()) == address(0)) {
            _pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).createPair(_dollar, dai()));
        } else {
            _pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(_dollar, dai()));
        }

        (address token0, address token1) = (_pair.token0(), _pair.token1());
        _index = _dollar == token0 ? 0 : 1;

        Require.that(_index == 0 || _dollar == token1, FILE, "DÃ¸llar not found");
    }

    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture() public onlyDao returns (Decimal.D256 memory, bool) {
        if (_initialized) {
            return updateOracle();
        } else {
            initializeOracle();
            return (Decimal.one(), false);
        }
    }

    function initializeOracle() private {
        IUniswapV2Pair pair = _pair;
        uint256 priceCumulative = _index == 0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        if (reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            _cumulative = priceCumulative;
            _timestamp = blockTimestampLast;
            _initialized = true;
            _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        }
    }

    function updateOracle() private returns (Decimal.D256 memory, bool) {
        Decimal.D256 memory price = updatePrice();
        uint256 lastReserve = updateReserve();

        bool valid = true;
        if (lastReserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (_reserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }

        return (price, valid);
    }

    function updatePrice() private returns (Decimal.D256 memory) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - _timestamp; // overflow is desired
        uint256 priceCumulative = _index == 0 ? price0Cumulative : price1Cumulative;
        Decimal.D256 memory price = Decimal.ratio((priceCumulative - _cumulative) / timeElapsed, 2**112);

        _timestamp = blockTimestamp;
        _cumulative = priceCumulative;

        return price;
    }

    function updateReserve() private returns (uint256) {
        uint256 lastReserve = _reserve;
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve

        return lastReserve;
    }

    function dai() internal view returns (address) {
        return Constants.getDaiAddress();
    }

    function pair() external view returns (address) {
        return address(_pair);
    }

    function reserve() external view returns (uint256) {
        return _reserve;
    }

    modifier onlyDao() {
        Require.that(msg.sender == _dao, FILE, "Not dao");

        _;
    }
}
"
    },
    "./contracts/mock/MockPoolLP.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/PoolLP.sol";

contract MockPoolLP is PoolLP {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address _stakingToken,
        address _rewardsToken
    ) public PoolLP(IDAO(address(0)), IERC20(_stakingToken), IERC20(_rewardsToken)) {}

    function set(address dao, address dai, address dollar) external {
        _dao = dao;
        _dai = dai;
        _dollar = dollar;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }

    function getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IUniswapV2Pair(address(stakingToken())).getReserves();
    }
}
"
    },
    "./contracts/mock/MockSettableOracle.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";
import "../oracle/IOracle.sol";

contract MockSettableOracle is IOracle {
    Decimal.D256 internal _price;
    bool internal _valid;
    uint256 internal _lastReserve;
    uint256 internal _reserve;

    function set(uint256 numerator, uint256 denominator, bool valid) external {
        _price = Decimal.ratio(numerator, denominator);
        _valid = valid;
    }

    function setup() public { }

    function capture() public returns (Decimal.D256 memory, bool) {
        return (_price, _valid);
    }

    function pair() external view returns (address) { revert("Should not use"); }
}
"
    },
    "./contracts/mock/MockToken.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract MockToken is ERC20Detailed, ERC20Burnable {
    constructor(string memory name, string memory symbol, uint8 decimals)
    ERC20Detailed(name, symbol, decimals)
    public
    { }

    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }
}
"
    },
    "./contracts/mock/MockOracle.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../oracle/Oracle.sol";
import "../external/Decimal.sol";

contract MockOracle is Oracle {
    Decimal.D256 private _latestPrice;
    bool private _latestValid;
    address private _usdc;

    constructor (address pair, address dollar, address usdc) Oracle(dollar) public {
        _pair = IUniswapV2Pair(pair);
        _index = 0;
        _usdc = usdc;
    }

    function usdc() internal view returns (address) {
        return _usdc;
    }

    function capture() public returns (Decimal.D256 memory, bool) {
        (_latestPrice, _latestValid) = super.capture();
        return (_latestPrice, _latestValid);
    }

    function latestPrice() external view returns (Decimal.D256 memory) {
        return _latestPrice;
    }

    function latestValid() external view returns (bool) {
        return _latestValid;
    }

    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    function cumulative() external view returns (uint256) {
        return _cumulative;
    }

    function timestamp() external view returns (uint256) {
        return _timestamp;
    }

    function reserve() external view returns (uint256) {
        return _reserve;
    }
}
"
    },
    "./contracts/mock/MockRegulator.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Regulator.sol";
import "../oracle/IOracle.sol";
import "./MockComptroller.sol";
import "./MockState.sol";

contract MockRegulator is MockComptroller, Regulator {
    constructor (address oracle, address poolLP, address poolBonding) MockComptroller(poolLP, poolBonding) public {
        _state.provider.oracle = IOracle(oracle);
    }

    function stepE() external {
        super.step();
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= 5;
    }

    function setGovernanceToken(address _token) external {
        _state.provider.governance = IERC20(_token);
    }
}
"
    },
    "./contracts/dao/Regulator.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Comptroller.sol";
import "../external/Require.sol";
import "../external/Decimal.sol";
import "../Constants.sol";

contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed epoch, uint256 price, uint256 newRedeemable, uint256 lessDebt, uint256 newBonded);
    event SupplyDecrease(uint256 indexed epoch, uint256 price, uint256 newDebt);
    event SupplyNeutral(uint256 indexed epoch);

    bytes32 private constant FILE = "Permission";

    function step() internal {
        Decimal.D256 memory price = oracleCapture();

        if (price.greaterThan(Decimal.one())) {
            // Expand supply
            growSupply(price);
            return;
        }

        if (price.lessThan(Decimal.one())) {
            // Distribute governance tokens to stakers
            distributeGovernanceTokens();
            return;
        }

        emit SupplyNeutral(epoch());
    }

    function growSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(price.sub(Decimal.one()), price);
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        (uint256 newRedeemable, uint256 newBonded) = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), price.value, newRedeemable, 0, newBonded);
    }

    function limit(Decimal.D256 memory delta, Decimal.D256 memory price) private view returns (Decimal.D256 memory) {
        Decimal.D256 memory supplyChangeLimit = Constants.getSupplyChangeLimit();
        return delta.greaterThan(supplyChangeLimit) ? supplyChangeLimit : delta;
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (bootstrappingAt(epoch().sub(1))) {
            return Constants.getBootstrappingPrice();
        }
        if (!valid) {
            return Decimal.one();
        }

        return price;
    }

    function oracleCaptureP() public returns (Decimal.D256 memory) {
        Require.that(
            msg.sender == poolBonding(),
            FILE,
            "Not pool bonding"
        );

        return oracleCapture();
    }
}
"
    },
    "./contracts/dao/Comptroller.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "./IERC20Mintable.sol";
import "../external/Require.sol";

contract Comptroller is Setters {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Comptroller";

    function mintToAccount(address account, uint256 amount) internal {
        dollar().mint(account, amount);
        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) {
        // QSD #7
        // If we're still bootstrapping
        if (bootstrappingAt(epoch().sub(1))) {
            uint256 rewards = newSupply.div(2);

            // 50% to Bonding (auto-compounding)
            mintToPoolLP(rewards);

            // 50% to Liquidity
            mintToDAO(rewards);

            // Redeemable always 0 since we don't have any coupon mechanism
            // Bonded will always be the new supply as well
            return (0, newSupply);
        } else {
            // QSD #B

            // 0-a. Pay out to Pool (LP)
            uint256 poolLPReward = newSupply.mul(Constants.getPoolLPRatio()).div(100);
            mintToPoolLP(poolLPReward);

            // 0-b. Pay out to Pool (Bonding)
            uint256 poolBondingReward = newSupply.mul(Constants.getPoolBondingRatio()).div(100);
            mintToPoolBonding(poolBondingReward);

            // 0-c. Pay out to Treasury
            uint256 treasuryReward = newSupply.mul(Constants.getTreasuryRatio()).div(100);
            mintToTreasury(treasuryReward);

            // 0-d. Pay out to Gov Stakers
            uint256 govStakerReward = newSupply.mul(Constants.getGovStakingRatio()).div(100);
            mintToPoolGov(govStakerReward);

            balanceCheck();
            return (0, newSupply);
        }
    }

    function distributeGovernanceTokens() internal {
        // Assume blocktime is 15 seconds
        uint256 blocksPerEpoch = Constants.getCurrentEpochStrategy().period.div(15);
        uint256 govTokenToMint = blocksPerEpoch.mul(Constants.getGovernanceTokenPerBlock());

        uint256 maxSupply = Constants.getGovernanceTokenMaxSupply();
        uint256 totalSupply = governance().totalSupply();

        // Maximum of 999,999,999 tokens
        if (totalSupply.add(govTokenToMint) >= maxSupply) {
            govTokenToMint = maxSupply.sub(totalSupply);
        }

        // Mint Governance token to pool bonding
        mintGovTokensToPoolBonding(govTokenToMint);
    }

    function balanceCheck() private {
        Require.that(
            dollar().balanceOf(address(this)) >= totalBonded().add(totalStaged()),
            FILE,
            "Inconsistent balances"
        );
    }

    /**
     * Dollar functions
     */

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToPoolLP(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolLP(), amount);
        }
    }

    function mintToPoolBonding(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolBonding(), amount);
        }
    }

    function mintToPoolGov(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(poolGov(), amount);
        }
    }

    function mintToTreasury(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(Constants.getTreasuryAddress(), amount);
        }
    }

    /**
     * Governance token functions
     */

    function mintGovTokensToPoolBonding(uint256 amount) private {
        if (amount > 0) {
            IERC20Mintable(address(governance())).mint(poolBonding(), amount);
        }
    }
}
"
    },
    "./contracts/dao/Setters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IPoolGov.sol";
import "./State.sol";
import "./Getters.sol";

contract Setters is State, Getters {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * ERC20 Interface
     */

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return false;
    }

    /**
     * Global
     */

    function incrementTotalBonded(uint256 amount) internal {
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementTotalBonded(uint256 amount, string memory reason) internal {
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOf(address account, uint256 amount) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.add(amount);
        _state.balance.supply = _state.balance.supply.add(amount);

        emit Transfer(address(0), account, amount);
    }

    function decrementBalanceOf(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].balance = _state.accounts[account].balance.sub(amount, reason);
        _state.balance.supply = _state.balance.supply.sub(amount, reason);

        emit Transfer(account, address(0), amount);
    }

    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }

    function decrementBalanceOfStaged(
        address account,
        uint256 amount,
        string memory reason
    ) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }

    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getDAOExitLockupEpochs());
    }

    /**
     * Epoch
     */

    function incrementEpoch() internal {
        _state.epoch.current = _state.epoch.current.add(1);
    }

    function snapshotTotalBonded() internal {
        _state.epochs[epoch()].bonded = IPoolGov(poolGov()).totalBonded();
    }

    /**
     * Governance
     */

    function createCandidate(address candidate, uint256 period) internal {
        _state.candidates[candidate].start = epoch();
        _state.candidates[candidate].period = period;
    }

    function recordVote(
        address account,
        address candidate,
        Candidate.Vote vote
    ) internal {
        _state.candidates[candidate].votes[account] = vote;
    }

    function incrementApproveFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.add(amount);
    }

    function decrementApproveFor(
        address candidate,
        uint256 amount,
        string memory reason
    ) internal {
        _state.candidates[candidate].approve = _state.candidates[candidate].approve.sub(amount, reason);
    }

    function incrementRejectFor(address candidate, uint256 amount) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.add(amount);
    }

    function decrementRejectFor(
        address candidate,
        uint256 amount,
        string memory reason
    ) internal {
        _state.candidates[candidate].reject = _state.candidates[candidate].reject.sub(amount, reason);
    }

    function placeLock(address account, address candidate) internal {
        uint256 currentLock = _state.accounts[account].lockedUntil;
        uint256 newLock = startFor(candidate).add(periodFor(candidate));
        if (newLock > currentLock) {
            _state.accounts[account].lockedUntil = newLock;
        }
    }

    function initialized(address candidate) internal {
        _state.candidates[candidate].initialized = true;
    }
}
"
    },
    "./contracts/dao/IPoolGov.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;

contract IPoolGov {
    function balanceOfBonded(address account) external view returns (uint256);
    function placeLock(address account, uint256 newLock) external;
    function totalBonded() external view returns (uint256);
}
"
    },
    "./contracts/dao/State.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "../token/IDollar.sol";
import "../oracle/IOracle.sol";
import "../external/Decimal.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 balance;
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}

contract Epoch {
    struct Global {
        uint256 start;
        uint256 period;
        uint256 current;
    }

    struct State {
        uint256 bonded;
    }
}

contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }

    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => Vote) votes;
        bool initialized;
    }
}

contract Storage {
    struct Provider {
        IDollar dollar; // Dollar token
        IERC20 governance; // Governance token
        IOracle oracle;
        address poolLP;
        address poolBonding;
        address poolGov;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
    }

    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;

        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(address => Candidate.State) candidates;
    }
}

contract State {
    Storage.State _state;
}
"
    },
    "./contracts/dao/Getters.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./State.sol";
import "../Constants.sol";

contract Getters is State {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * ERC20 Interface
     */

    function name() public view returns (string memory) {
        return "Flexible Supply Dollar Stake";
    }

    function symbol() public view returns (string memory) {
        return "FSDS";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _state.accounts[account].balance;
    }

    function totalSupply() public view returns (uint256) {
        return _state.balance.supply;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    /**
     * Global
     */

    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }

    function governance() public view returns (IERC20) {
        return _state.provider.governance;
    }

    function oracle() public view returns (IOracle) {
        return _state.provider.oracle;
    }

    function poolLP() public view returns (address) {
        return _state.provider.poolLP;
    }

    function poolBonding() public view returns (address) {
        return _state.provider.poolBonding;
    }

    function poolGov() public view returns (address) {
        return _state.provider.poolGov;
    }

    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }

    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }

    function totalNet() public view returns (uint256) {
        return dollar().totalSupply();
    }

    /**
     * Account
     */

    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }

    function balanceOfBonded(address account) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            return 0;
        }
        return totalBonded().mul(balanceOf(account)).div(totalSupply);
    }

    function statusOf(address account) public view returns (Account.Status) {
        if (_state.accounts[account].lockedUntil > epoch()) {
            return Account.Status.Locked;
        }

        return epoch() >= _state.accounts[account].fluidUntil ? Account.Status.Frozen : Account.Status.Fluid;
    }

    function fluidUntil(address account) public view returns (uint256) {
        return _state.accounts[account].fluidUntil;
    }

    function lockedUntil(address account) public view returns (uint256) {
        return _state.accounts[account].lockedUntil;
    }

    /**
     * Epoch
     */

    function epoch() public view returns (uint256) {
        return _state.epoch.current;
    }

    function epochTime() public view returns (uint256) {
        Constants.EpochStrategy memory current = Constants.getCurrentEpochStrategy();
        Constants.EpochStrategy memory previous = Constants.getPreviousEpochStrategy();

        return blockTimestamp() < current.start ?
            epochTimeWithStrategy(previous) :
            epochTimeWithStrategy(current);
    }

    function epochTimeWithStrategy(Constants.EpochStrategy memory strategy) private view returns (uint256) {
        return blockTimestamp()
            .sub(strategy.start)
            .div(strategy.period)
            .add(strategy.offset);
    }

    // Overridable for testing
    function blockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function totalBondedAt(uint256 epoch) public view returns (uint256) {
        return _state.epochs[epoch].bonded;
    }

    function bootstrappingAt(uint256 epoch) public view returns (bool) {
        return epoch <= Constants.getBootstrappingPeriod();
    }

    /**
     * Governance
     */

    function recordedVote(address account, address candidate) public view returns (Candidate.Vote) {
        return _state.candidates[candidate].votes[account];
    }

    function startFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].start;
    }

    function periodFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].period;
    }

    function approveFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].approve;
    }

    function rejectFor(address candidate) public view returns (uint256) {
        return _state.candidates[candidate].reject;
    }

    function votesFor(address candidate) public view returns (uint256) {
        return approveFor(candidate).add(rejectFor(candidate));
    }

    function isNominated(address candidate) public view returns (bool) {
        return _state.candidates[candidate].start > 0;
    }

    function isInitialized(address candidate) public view returns (bool) {
        return _state.candidates[candidate].initialized;
    }

    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}
"
    },
    "./contracts/dao/IERC20Mintable.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20Mintable is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}
"
    },
    "./contracts/mock/MockComptroller.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Comptroller.sol";
import "../token/Dollar.sol";
import "./MockState.sol";

contract MockComptroller is Comptroller, MockState {
    constructor(address poolLP, address poolBonding) public {
        _state.provider.dollar = new Dollar();
        _state.provider.poolLP = poolLP;
        _state.provider.poolBonding = poolBonding;
    }

    function mintToAccountE(address account, uint256 amount) external {
        super.mintToAccount(account, amount);
    }

    /* For testing only */
    function mintToE(address account, uint256 amount) external {
        dollar().mint(account, amount);
    }
}
"
    },
    "./contracts/token/Dollar.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";
import "./Permittable.sol";
import "./IDollar.sol";


contract Dollar is IDollar, MinterRole, ERC20Detailed, Permittable, ERC20Burnable  {

    constructor()
    ERC20Detailed("Quantum Set Dollar", "QSD", 18)
    Permittable()
    public
    { }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (allowance(sender, _msgSender()) != uint256(-1)) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(amount, "Dollar: transfer amount exceeds allowance"));
        }
        return true;
    }
}
"
    },
    "./contracts/token/Permittable.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../external/Require.sol";
import "../external/LibEIP712.sol";
import "../Constants.sol";

contract Permittable is ERC20Detailed, ERC20 {
    bytes32 constant FILE = "Permittable";

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant EIP712_PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    string private constant EIP712_VERSION = "1";

    bytes32 public EIP712_DOMAIN_SEPARATOR;

    mapping(address => uint256) nonces;

    constructor() public {
        EIP712_DOMAIN_SEPARATOR = LibEIP712.hashEIP712Domain(name(), EIP712_VERSION, Constants.getChainId(), address(this));
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = LibEIP712.hashEIP712Message(
            EIP712_DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                EIP712_PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            ))
        );

        address recovered = ecrecover(digest, v, r, s);
        Require.that(
            recovered == owner,
            FILE,
            "Invalid signature"
        );

        Require.that(
            recovered != address(0),
            FILE,
            "Zero address"
        );

        Require.that(
            now <= deadline,
            FILE,
            "Expired"
        );

        _approve(owner, spender, value);
    }
}"
    },
    "./contracts/mock/MockState.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Setters.sol";

contract MockState is Setters {
    uint256 internal _blockTimestamp;

    constructor () public {
        _blockTimestamp = block.timestamp;
    }

    /**
     * Global
     */

    function incrementTotalBondedE(uint256 amount) external {
        super.incrementTotalBonded(amount);
    }

    function decrementTotalBondedE(uint256 amount, string calldata reason) external {
        super.decrementTotalBonded(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOfE(address account, uint256 amount) external {
        super.incrementBalanceOf(account, amount);
    }

    function decrementBalanceOfE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOf(account, amount, reason);
    }

    function incrementBalanceOfStagedE(address account, uint256 amount) external {
        super.incrementBalanceOfStaged(account, amount);
    }

    function decrementBalanceOfStagedE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfStaged(account, amount, reason);
    }

    function unfreezeE(address account) external {
        super.unfreeze(account);
    }

    /**
     * Epoch
     */

    function setEpochParamsE(uint256 start, uint256 period) external {
        _state.epoch.start = start;
        _state.epoch.period = period;
    }

    function incrementEpochE() external {
        super.incrementEpoch();
    }

    function snapshotTotalBondedE() external {
        super.snapshotTotalBonded();
    }

    /**
     * Governance
     */

    function createCandidateE(address candidate, uint256 period) external {
        super.createCandidate(candidate, period);
    }

    function recordVoteE(address account, address candidate, Candidate.Vote vote) external {
        super.recordVote(account, candidate, vote);
    }

    function incrementApproveForE(address candidate, uint256 amount) external {
        super.incrementApproveFor(candidate, amount);
    }

    function decrementApproveForE(address candidate, uint256 amount, string calldata reason) external {
        super.decrementApproveFor(candidate, amount, reason);
    }

    function incrementRejectForE(address candidate, uint256 amount) external {
        super.incrementRejectFor(candidate, amount);
    }

    function decrementRejectForE(address candidate, uint256 amount, string calldata reason) external {
        super.decrementRejectFor(candidate, amount, reason);
    }

    function placeLockE(address account, address candidate) external {
        super.placeLock(account, candidate);
    }

    function initializedE(address candidate) external {
        super.initialized(candidate);
    }

    /**
     * Mock
     */

    function setBlockTimestamp(uint256 timestamp) external {
        _blockTimestamp = timestamp;
    }

    function blockTimestamp() internal view returns (uint256) {
        return _blockTimestamp;
    }

    /**
     * 
     */
     
    function setPoolGov(address poolGov) external {
        _state.provider.poolGov = poolGov;
    }
}
"
    },
    "./contracts/mock/MockPool.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/Pool.sol";

contract MockPool is Pool {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address _stakingToken,
        address _rewardsToken
    ) public Pool(IDAO(address(0)), IERC20(_stakingToken), IERC20(_rewardsToken)) {}

    function set(address dao, address dai, address dollar) external {
        _dao = dao;
        _dai = dai;
        _dollar = dollar;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }
}
"
    },
    "./contracts/mock/MockUniswapV2PairLiquidity.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MockUniswapV2PairLiquidity is IUniswapV2Pair {
    using SafeMath for uint256;

    address public token0;
    address public token1;
    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint256 private liquidity;

    function setToken0(address t) external {
        token0 = t;
    }

    function setToken1(address t) external {
        token1 = t;
    }

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (reserve0, reserve1, 0);
    }

    function mint(address to) external returns (uint256) {
        _balances[to] = _balances[to].add(liquidity);
        return liquidity;
    }

    function set(
        uint112 newReserve0,
        uint112 newReserve1,
        uint256 newLiquidity
    ) external {
        reserve0 = newReserve0;
        reserve1 = newReserve1;
        liquidity = newLiquidity;
    }

    function faucet(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    /**
     * Should not use
     */

    function name() external pure returns (string memory) {
        return "Uniswap V2";
    }

    function symbol() external pure returns (string memory) {
        return "UNI-V2";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        revert("Should not use");
    }

    function PERMIT_TYPEHASH() external pure returns (bytes32) {
        revert("Should not use");
    }

    function nonces(address owner) external view returns (uint256) {
        revert("Should not use");
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        revert("Should not use");
    }

    function MINIMUM_LIQUIDITY() external pure returns (uint256) {
        revert("Should not use");
    }

    function factory() external view returns (address) {
        revert("Should not use");
    }

    function price0CumulativeLast() external view returns (uint256) {
        revert("Should not use");
    }

    function price1CumulativeLast() external view returns (uint256) {
        revert("Should not use");
    }

    function kLast() external view returns (uint256) {
        revert("Should not use");
    }

    function burn(address to) external returns (uint256 amount0, uint256 amount1) {
        revert("Should not use");
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external {
        revert("Should not use");
    }

    function skim(address to) external {
        revert("Should not use");
    }

    function sync() external {
        revert("Should not use");
    }

    function initialize(address, address) external {
        revert("Should not use");
    }

    // @openzeppelin/contracts/token/ERC20/ERC20.sol

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance")
        );
    }
}
"
    },
    "./contracts/mock/MockBonding.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./MockState.sol";
import "../dao/Bonding.sol";
import "./MockComptroller.sol";

contract MockBonding is MockComptroller, Bonding {
    constructor() MockComptroller(address(0), address(0)) public { }

    function stepE() external {
        Bonding.step();
    }

    function setPoolGov(address poolGov) external {
        _state.provider.poolGov = poolGov;
    }
}
"
    },
    "./contracts/dao/Bonding.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "./Permission.sol";
import "../external/Require.sol";
import "../Constants.sol";

contract Bonding is Setters, Permission {
    using SafeMath for uint256;

    bytes32 private constant FILE = "Bonding";

    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Bond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);
    event Unbond(address indexed account, uint256 start, uint256 value, uint256 valueUnderlying);

    function step() internal {
        Require.that(epochTime() > epoch(), FILE, "Still current epoch");

        snapshotTotalBonded(); // For governance
        incrementEpoch();
    }

    function deposit(uint256 value) external onlyFrozenOrLocked(msg.sender) {
        dollar().transferFrom(msg.sender, address(this), value);
        incrementBalanceOfStaged(msg.sender, value);

        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) external onlyFrozenOrLocked(msg.sender) {
        dollar().transfer(msg.sender, value);
        decrementBalanceOfStaged(msg.sender, value, "Bonding: insufficient staged balance");

        emit Withdraw(msg.sender, value);
    }

    function bond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 balance =
            totalBonded() == 0
                ? value.mul(Constants.getInitialStakeMultiple())
                : value.mul(totalSupply() > 0 ? totalSupply() : 1).div(totalBonded());

        incrementBalanceOf(msg.sender, balance);
        incrementTotalBonded(value);
        decrementBalanceOfStaged(msg.sender, value, "Bonding: insufficient staged balance");

        emit Bond(msg.sender, epoch().add(1), balance, value);
    }

    function unbond(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 staged = value.mul(balanceOfBonded(msg.sender)).div(balanceOf(msg.sender));
        incrementBalanceOfStaged(msg.sender, staged);
        decrementTotalBonded(staged, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, value, "Bonding: insufficient balance");

        emit Unbond(msg.sender, epoch().add(1), value, staged);
    }

    function unbondUnderlying(uint256 value) external onlyFrozenOrFluid(msg.sender) {
        unfreeze(msg.sender);

        uint256 balance = value.mul(totalSupply()).div(totalBonded());
        incrementBalanceOfStaged(msg.sender, value);
        decrementTotalBonded(value, "Bonding: insufficient total bonded");
        decrementBalanceOf(msg.sender, balance, "Bonding: insufficient balance");

        emit Unbond(msg.sender, epoch().add(1), balance, value);
    }
}
"
    },
    "./contracts/dao/Permission.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Setters.sol";
import "../external/Require.sol";

contract Permission is Setters {

    bytes32 private constant FILE = "Permission";

    // Can modify account state
    modifier onlyFrozenOrFluid(address account) {
        Require.that(
            statusOf(account) != Account.Status.Locked,
            FILE,
            "Not frozen or fluid"
        );

        _;
    }

    // Can participate in balance-dependant activities
    modifier onlyFrozenOrLocked(address account) {
        Require.that(
            statusOf(account) != Account.Status.Fluid,
            FILE,
            "Not frozen or locked"
        );

        _;
    }

    modifier initializer() {
        Require.that(
            !isInitialized(implementation()),
            FILE,
            "Already initialized"
        );

        initialized(implementation());

        _;
    }
}
"
    },
    "./contracts/mock/MockUpgradeable.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Upgradeable.sol";
import "../dao/Permission.sol";

contract MockUpgradeable is Upgradeable, Permission {
    constructor () public { }

    function initialize() public {
        revert("Should not call");
    }

    function upgradeToE(address newImplementation) external {
        super.upgradeTo(newImplementation);
    }
}
"
    },
    "./contracts/dao/Upgradeable.sol": {
      "content": "/*
    Copyright 2018-2019 zOS Global Limited
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/utils/Address.sol";
import "./State.sol";

/**
 * Based off of, and designed to interface with, openzeppelin/upgrades package
 */
contract Upgradeable is State {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    function initialize() public;

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) internal {
        setImplementation(newImplementation);

        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success, string(reason));

        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function setImplementation(address newImplementation) private {
        require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}
"
    },
    "./contracts/mock/MockPoolBonding.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/pool-bonding/Pool.sol";

contract MockPoolBonding is PoolBonding {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address _stakingToken,
        address _rewardsToken1,
        address _rewardsToken2
    ) public PoolBonding(IDAO(address(0)), IERC20(_stakingToken), IERC20(_rewardsToken1), IERC20(_rewardsToken2)) {}

    function set(
        address dao,
        address dai,
        address dollar
    ) external {
        _dao = dao;
        _dai = dai;
        _dollar = dollar;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }
}
"
    },
    "./contracts/mock/MockPoolState.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/PoolSetters.sol";

contract MockPoolState is PoolSetters {
    address private _dao;
    address private _dollar;

    function set(address dao, address dollar) external {
        _dao = dao;
        _dollar = dollar;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }

    /**
     * Account
     */

    function incrementBalanceOfBondedE(address account, uint256 amount) external {
        super.incrementBalanceOfBonded(account, amount);
    }

    function decrementBalanceOfBondedE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfBonded(account, amount, reason);
    }

    function incrementBalanceOfStagedE(address account, uint256 amount) external {
        super.incrementBalanceOfStaged(account, amount);
    }

    function decrementBalanceOfStagedE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfStaged(account, amount, reason);
    }

    function incrementBalanceOfClaimableE(address account, uint256 amount) external {
        super.incrementBalanceOfClaimable(account, amount);
    }

    function decrementBalanceOfClaimableE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfClaimable(account, amount, reason);
    }

    function incrementBalanceOfPhantomE(address account, uint256 amount) external {
        super.incrementBalanceOfPhantom(account, amount);
    }

    function decrementBalanceOfPhantomE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfPhantom(account, amount, reason);
    }

    function unfreezeE(address account) external {
        super.unfreeze(account);
    }

    function setStakingToken(address _stakingToken) external {
        _state.stakingToken = IERC20(_stakingToken);
    }

    function setRewardsToken(address _rewardsToken) external {
        _state.rewardsToken = IERC20(_rewardsToken);
    }
}
"
    },
    "./contracts/mock/MockSettableDAO.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../external/Decimal.sol";
import "../oracle/IDAO.sol";

contract MockSettableDAO is IDAO {
    uint256 internal _epoch;
    address internal _oracle;

    function set(uint256 epoch) external {
        _epoch = epoch;
    }

    function setOracle(address oracle) external {
        _oracle = oracle;
    }

    function oracle() external view returns (IOracle) {
        return IOracle(_oracle);
    }

    function epoch() external view returns (uint256) {
        return _epoch;
    }

    function bootstrappingAt(uint256 i) external view returns (bool) {
        return i < 5;
    }

    function oracleCaptureP() public returns (Decimal.D256 memory price) {
        (price, ) = IOracle(_oracle).capture();
    }
}
"
    },
    "./contracts/mock/MockImplA.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Upgradeable.sol";
import "../dao/Permission.sol";

contract MockImplA is Upgradeable, Permission {
    constructor () public { }

    event MockInitializedA();

    function initialize() public initializer {
        emit MockInitializedA();
    }

    function upgradeToE(address newImplementation) external {
        super.upgradeTo(newImplementation);
    }
}
"
    },
    "./contracts/mock/MockImplB.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Upgradeable.sol";
import "../dao/Permission.sol";

contract MockImplB is Upgradeable, Permission {
    constructor () public { }

    event MockInitializedB();

    function initialize() public initializer {
        emit MockInitializedB();
    }

    function upgradeToE(address newImplementation) external {
        super.upgradeTo(newImplementation);
    }
}
"
    },
    "./contracts/mock/TestnetUSDC.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../oracle/IUSDC.sol";

contract TestnetUSDC is ERC20Detailed, ERC20Burnable, IUSDC {
    constructor()
    ERC20Detailed("USD//C", "USDC", 6)
    public
    { }

    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    function isBlacklisted(address account) external view returns (bool) {
        return false;
    }
}
"
    },
    "./contracts/mock/MockGovern.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Govern.sol";
import "./MockUpgradeable.sol";
import "./MockComptroller.sol";

contract MockGovern is Govern, MockComptroller {
    uint256 internal _epochTime;

    constructor() public MockComptroller(address(0), address(0)) {}

    function initialize() public {
        revert("Should not call");
    }

    function upgradeToE(address newImplementation) external {
        super.upgradeTo(newImplementation);
    }

    function setPoolGov(address poolGov) external {
        _state.provider.poolGov = poolGov;
    }

    function setEpochTime(uint256 epochTime) external {
        _epochTime = epochTime;
    }

    function setEpoch(uint256 epoch) external {
        _state.epoch.current = epoch;
    }

    function epochTime() public view returns (uint256) {
        return _epochTime;
    }
}
"
    },
    "./contracts/dao/Govern.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Setters.sol";
import "./Permission.sol";
import "./Upgradeable.sol";
import "../external/Require.sol";
import "../external/Decimal.sol";
import "../Constants.sol";
import "./IPoolGov.sol";

contract Govern is Setters, Permission, Upgradeable {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Govern";

    event Proposal(address indexed candidate, address indexed account, uint256 indexed start, uint256 period);
    event Vote(address indexed account, address indexed candidate, Candidate.Vote vote, uint256 bonded);
    event Commit(address indexed account, address indexed candidate);

    // QSD #6
    modifier onlyPostBootstrapping() {
        Require.that(!bootstrappingAt(epoch().sub(1)), FILE, "No govern during bootstrapping");
        _;
    }

    function vote(address candidate, Candidate.Vote vote)
        external
        onlyPostBootstrapping
    {
        uint256 govStaked = IPoolGov(poolGov()).balanceOfBonded(msg.sender);

        Require.that(govStaked > 0, FILE, "Must have stake");

        if (!isNominated(candidate)) {
            Require.that(canPropose(msg.sender), FILE, "Not enough stake to propose");

            createCandidate(candidate, Constants.getGovernancePeriod());
            emit Proposal(candidate, msg.sender, epoch(), Constants.getGovernancePeriod());
        }

        uint256 candidateEndEpoch = startFor(candidate).add(periodFor(candidate));
        
        Require.that(epoch() < candidateEndEpoch, FILE, "Ended");

        Candidate.Vote recordedVote = recordedVote(msg.sender, candidate);
        if (vote == recordedVote) {
            return;
        }

        if (recordedVote == Candidate.Vote.REJECT) {
            decrementRejectFor(candidate, govStaked, "Govern: Insufficient reject");
        }
        if (recordedVote == Candidate.Vote.APPROVE) {
            decrementApproveFor(candidate, govStaked, "Govern: Insufficient approve");
        }
        if (vote == Candidate.Vote.REJECT) {
            incrementRejectFor(candidate, govStaked);
        }
        if (vote == Candidate.Vote.APPROVE) {
            incrementApproveFor(candidate, govStaked);
        }

        recordVote(msg.sender, candidate, vote);
        IPoolGov(poolGov()).placeLock(msg.sender, candidateEndEpoch);

        emit Vote(msg.sender, candidate, vote, govStaked);
    }

    function commit(address candidate) external onlyPostBootstrapping {
        Require.that(isNominated(candidate), FILE, "Not nominated");

        uint256 endsAfter = startFor(candidate).add(periodFor(candidate)).sub(1);

        Require.that(epoch() > endsAfter, FILE, "Not ended");

        Require.that(epoch() <= endsAfter.add(1).add(Constants.getGovernanceExpiration()), FILE, "Expired");

        Require.that(
            Decimal.ratio(votesFor(candidate), totalBondedAt(endsAfter)).greaterThan(Constants.getGovernanceQuorum()),
            FILE,
            "Must have quorom"
        );

        Require.that(approveFor(candidate) > rejectFor(candidate), FILE, "Not approved");

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function emergencyCommit(address candidate) external onlyPostBootstrapping {
        Require.that(isNominated(candidate), FILE, "Not nominated");

        Require.that(epochTime() > epoch().add(Constants.getGovernanceEmergencyDelay()), FILE, "Epoch synced");

        Require.that(
            Decimal.ratio(approveFor(candidate), IPoolGov(poolGov()).totalBonded()).greaterThan(Constants.getGovernanceSuperMajority()),
            FILE,
            "Must have super majority"
        );

        Require.that(approveFor(candidate) > rejectFor(candidate), FILE, "Not approved");

        upgradeTo(candidate);

        emit Commit(msg.sender, candidate);
    }

    function canPropose(address account) private view returns (bool) {
        uint256 govStaked = IPoolGov(poolGov()).balanceOfBonded(msg.sender);
        uint256 totalGovStaked = IPoolGov(poolGov()).totalBonded();

        if (totalGovStaked == 0) {
            return false;
        }

        Decimal.D256 memory stake = Decimal.ratio(govStaked, totalGovStaked);
        return stake.greaterThan(Constants.getGovernanceProposalThreshold());
    }
}
"
    },
    "./contracts/mock/MockUniswapV2PairTrade.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/lib/contracts/libraries/FixedPoint.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract MockUniswapV2PairTrade is IUniswapV2Pair {
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function simulateTrade(uint112 newReserve0, uint112 newReserve1) external {
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            price0CumulativeLast += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1CumulativeLast += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
        reserve0 = newReserve0;
        reserve1 = newReserve1;
        blockTimestampLast = blockTimestamp;
    }

    /**
     * Should not use
     */
    function name() external pure returns (string memory) { revert("Should not use"); }
    function symbol() external pure returns (string memory) { revert("Should not use"); }
    function decimals() external pure returns (uint8) { revert("Should not use"); }
    function totalSupply() external view returns (uint) { revert("Should not use"); }
    function balanceOf(address owner) external view returns (uint) { revert("Should not use"); }
    function allowance(address owner, address spender) external view returns (uint) { revert("Should not use"); }

    function approve(address spender, uint value) external returns (bool) { revert("Should not use"); }
    function transfer(address to, uint value) external returns (bool) { revert("Should not use"); }
    function transferFrom(address from, address to, uint value) external returns (bool) { revert("Should not use"); }

    function DOMAIN_SEPARATOR() external view returns (bytes32) { revert("Should not use"); }
    function PERMIT_TYPEHASH() external pure returns (bytes32) { revert("Should not use"); }
    function nonces(address owner) external view returns (uint) { revert("Should not use"); }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external { revert("Should not use"); }

    function MINIMUM_LIQUIDITY() external pure returns (uint) { revert("Should not use"); }
    function factory() external view returns (address) { revert("Should not use"); }
    function token0() external view returns (address) { revert("Should not use"); }
    function token1() external view returns (address) { revert("Should not use"); }
    function kLast() external view returns (uint) { revert("Should not use"); }

    function mint(address to) external returns (uint liquidity) { revert("Should not use"); }
    function burn(address to) external returns (uint amount0, uint amount1) { revert("Should not use"); }
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external { revert("Should not use"); }
    function skim(address to) external { revert("Should not use"); }
    function sync() external { revert("Should not use"); }

    function initialize(address, address) external { revert("Should not use"); }
}
"
    },
    "./contracts/mock/MockUSDC.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/IUSDC.sol";

contract MockUSDC is IUSDC {
    bool private _blacklisted;

    function isBlacklisted(address _account) external view returns (bool) {
        return _blacklisted;
    }

    function setIsBlacklisted(bool blacklisted) external {
        _blacklisted = blacklisted;
    }
}
"
    },
    "./contracts/mock/MockPoolGov.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../oracle/PoolGov.sol";

contract MockPoolGov is PoolGov {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address _stakingToken,
        address _rewardsToken
    ) public PoolGov(IDAO(address(0)), IERC20(_stakingToken), IERC20(_rewardsToken)) {}

    function set(address dao, address dai, address dollar) external {
        _dao = dao;
        _dai = dai;
        _dollar = dollar;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }

    function incrementBalanceOfE(address account, uint56 amount) external {
        incrementBalanceOfBonded(account, amount);
    }

    function decrementBalanceOfE(address account, uint56 amount) external {
        decrementBalanceOfBonded(account, amount, "failed");
    }

    function incrementTotalBondedE(uint256 amount) external {
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }

    function decrementTotalBondedE(uint256 amount) external {
        _state.balance.bonded = _state.balance.bonded.sub(amount);
    }
}
"
    },
    "./contracts/dao/Implementation.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../oracle/Oracle.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "../Constants.sol";

contract Implementation is State, Bonding, Regulator, Govern {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize() public initializer {
        if (address(_state.provider.dollar) != address(0)) {
            // Reward committer
            incentivize(msg.sender, Constants.getAdvanceIncentive());
        }
    }

    function initializeOracle() public {
        require(address(dollar()) != address(0), "dollar not initialized!");
        require(address(_state.provider.oracle) == address(0), "oracle initialized!");
        Oracle oracle = new Oracle(address(dollar()));
        oracle.setup();
        
        _state.provider.oracle = IOracle(address(oracle));
    }

    function initializeTokenAddresses(IDollar dollar, IERC20 gov) public {
        require(address(_state.provider.dollar) == address(0), "dollar initialized!");
        require(address(_state.provider.governance) == address(0), "governance initialized!");

        _state.provider.dollar = dollar;
        _state.provider.governance = gov;
    }

    function initializePoolAddresses(
        address poolBonding,
        address poolLP,
        address poolGov
    ) public {
        require(_state.provider.poolBonding == address(0), "pool bonding initialized!");
        require(_state.provider.poolLP == address(0), "pool LP initialized!");
        require(_state.provider.poolGov == address(0), "pool gov initialized!");

        _state.provider.poolBonding = poolBonding;
        _state.provider.poolLP = poolLP;
        _state.provider.poolGov = poolGov;
    }

    function advance() external {
        // No -1 here as epoch only gets incremented on Bonding.step
        if (bootstrappingAt(epoch())) {
            // QSD #4
            // QSD #5
            incentivize(0xC1b89f59c600e4beFfD6df16186048f828d411f6, 1682e16); // 16.82
            incentivize(0xdBba5c9AB0F3Ac341Fc741b053678Ade367236e6, 1683e16); // 16.83
            incentivize(0x5aB60b1c7d78014c4490D5e78BA551D51729E1De, 6e18);
            incentivize(0xbcb8171050Fe9c08066a5008f5Da484cC5E8e3FF, 6e18);
            incentivize(0x8d4CA87F859D9581954586e671a66B2636fD7Bdd, 5e18);
            incentivize(0xB006be3e08b54DBdA89725a313803f4B1875259f, 6e18);
            incentivize(0xD6F82502F20647dd8d78DFFb6AD7F8D8193d5e29, 1093e16); // 10.93
            incentivize(0x81725dFB3F92f8301DDADe77E29536605e8Df162, 2986e16); // 29.86
            incentivize(0x82e1dE949DF695AAA8053f53008320F8EAd52814,  528e16); // 5.28
            incentivize(0x5dDE36a3d062150AdbF1107c976A33D8E835aE62,  528e16); // 5.28
        } else {
            incentivize(poolGov(), 108e18); // 108 QSD to QSG stakers every epoch
        }

        Bonding.step();
        Regulator.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function incentivize(address account, uint256 amount) private {
        mintToAccount(account, amount);
        emit Incentivization(account, amount);
    }
}
"
    },
    "./contracts/dao/Root.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/upgradeability/UpgradeabilityProxy.sol";

contract Root is UpgradeabilityProxy {
    constructor(address implementation)
        public
        UpgradeabilityProxy(implementation, abi.encodeWithSignature("initialize()"))
    {}
}
"
    },
    "./contracts/token/Governance.sol": {
      "content": "/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";
import "./Permittable.sol";


contract Governance is MinterRole, ERC20Detailed, Permittable, ERC20Burnable  {
    constructor()
    ERC20Detailed("Quantum Set Governance", "QSG", 18)
    Permittable()
    public
    { }

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (allowance(sender, _msgSender()) != uint256(-1)) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(amount, "Dollar: transfer amount exceeds allowance"));
        }
        return true;
    }
}
"
    },
    "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol": {
      "content": "pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
"
    },
    "@uniswap/lib/contracts/libraries/FixedPoint.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}
"
    },
    "@uniswap/lib/contracts/libraries/Babylonian.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}
"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}
"
    },
    "@openzeppelin/contracts/token/ERC20/SafeERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol": {
      "content": "pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}
"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol": {
      "content": "pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
"
    },
    "@openzeppelin/contracts/access/roles/MinterRole.sol": {
      "content": "pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
"
    },
    "@openzeppelin/contracts/access/Roles.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
"
    },
    "@openzeppelin/upgrades/contracts/utils/Address.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
"
    },
    "@openzeppelin/upgrades/contracts/upgradeability/UpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}
"
    },
    "@openzeppelin/upgrades/contracts/upgradeability/BaseUpgradeabilityProxy.sol": {
      "content": "pragma solidity ^0.5.0;

import './Proxy.sol';
import '../utils/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}
"
    },
    "@openzeppelin/upgrades/contracts/upgradeability/Proxy.sol": {
      "content": "pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}
"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
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