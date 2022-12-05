{"Authorizable.sol":{"content":"pragma solidity ^0.5.7;

import {Ownable} from "./Ownable.sol";

/// Access control utility to provide onlyAuthorized and onlyUserApproved modifiers
contract Authorizable is Ownable {

    // Logs when a currently authorized address is authorized or deauthorized.
    event AuthorizedAddressChanged(
        address indexed target,
        address indexed caller,
        bool allowed
    );

    // Logs when an address is user approved or unapproved.
    event UserApprovedAddressChanged(
        address indexed target,
        address indexed caller,
        bool allowed
    );

    /// Only authorized senders can invoke functions with this modifier.
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender],
            "SENDER_NOT_AUTHORIZED"
        );
        _;
    }

    /// Only user approved senders can invoke functions with this modifier.
    modifier onlyUserApproved(address user) {
        require(
            userApproved[user][msg.sender],
            "SENDER_NOT_APPROVED"
        );
        _;
    }

    // Mapping of authorized addresses.
    // authorized[target] = isAuthorized
    mapping(address => bool) public authorized;

    // Mapping of user approved addresses.
    // userApproved[user][target] = isUserApproved
    mapping(address => mapping(address => bool)) public userApproved;

    address[] authorities;
    mapping(address => address[]) userApprovals;

    /// Modifies authorization of an address. Only contract owner can call this function.
    /// @param target Address to authorize / deauthorize.
    /// @param allowed Whether the target address is authorized.
    function authorize(address target, bool allowed)
    external
    onlyOwner
    {
        if (authorized[target] == allowed) {
            return;
        }
        if (allowed) {
            authorized[target] = allowed;
            authorities.push(target);
        } else {
            delete authorized[target];
            for (uint256 i = 0; i < authorities.length; i++) {
                if (authorities[i] == target) {
                    authorities[i] = authorities[authorities.length - 1];
                    authorities.length -= 1;
                    break;
                }
            }
        }
        emit AuthorizedAddressChanged(target, msg.sender, allowed);
    }

    /// Modifies user approvals of an address.
    /// @param target Address to approve / unapprove.
    /// @param allowed Whether the target address is user approved.
    function userApprove(address target, bool allowed)
    public
    {
        if (userApproved[msg.sender][target] == allowed) {
            return;
        }
        if (allowed) {
            userApproved[msg.sender][target] = allowed;
            userApprovals[msg.sender].push(target);
        } else {
            delete userApproved[msg.sender][target];
            for (uint256 i = 0; i < userApprovals[msg.sender].length; i++) {
                if (userApprovals[msg.sender][i] == target) {
                    userApprovals[msg.sender][i] = userApprovals[msg.sender][userApprovals[msg.sender].length - 1];
                    userApprovals[msg.sender].length -= 1;
                    break;
                }
            }
        }
        emit UserApprovedAddressChanged(target, msg.sender, allowed);
    }

    /// Batch modifies user approvals.
    /// @param targetList Array of addresses to approve / unapprove.
    /// @param allowedList Array of booleans indicating whether the target address is user approved.
    function batchUserApprove(address[] calldata targetList, bool[] calldata allowedList)
    external
    {
        for (uint256 i = 0; i < targetList.length; i++) {
            userApprove(targetList[i], allowedList[i]);
        }
    }

    /// Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
    external
    view
    returns (address[] memory)
    {
        return authorities;
    }

    /// Gets all user approved addresses.
    /// @return Array of user approved addresses.
    function getUserApprovedAddresses()
    external
    view
    returns (address[] memory)
    {
        return userApprovals[msg.sender];
    }
}"},"ERC20Bank.sol":{"content":"pragma solidity ^0.5.7;

import {Authorizable} from "./Authorizable.sol";
import {ERC20SafeTransfer} from "./ERC20SafeTransfer.sol";
import {IERC20} from "./IERC20.sol";
import {LibMath} from "./LibMath.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {IBank} from "./IBank.sol";

// Simple WETH interface to wrap and unwarp ETH.
interface IWETH {
    function balanceOf(address owner) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// A bank locks ETH and ERC20 tokens. It doesn't contain any exchange logics that helps upgrade the exchange contract.
/// Users have complete control over their assets. Only user trusted contracts are able to access the assets.
/// Address 0x0 is used to represent ETH.
contract ERC20Bank is IBank, Authorizable, ReentrancyGuard, LibMath {

    mapping(address => bool) public wethAddresses;
    mapping(address => mapping(address => uint256)) public deposits;

    event SetWETH(address addr, bool autoWrap);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    function() external payable {}

    /// Sets WETH address to support auto wrap/unwrap ETH feature. ETH is required to test auto wrap/unwrap.
    /// @param addr WETH token address.
    /// @param autoWrap Whether the address supports auto wrap/unwrap.
    function setWETH(address addr, bool autoWrap) external onlyOwner payable {
        if (autoWrap) {
            uint256 testETH = msg.value;
            require(testETH > 0, "TEST_ETH_REQUIRED");
            uint256 beforeWrap = IWETH(addr).balanceOf(address(this));
            IWETH(addr).deposit.value(testETH)();
            require(IWETH(addr).balanceOf(address(this)) - beforeWrap == testETH, "FAILED_WRAP_TEST");
            uint256 beforeUnwrap = address(this).balance;
            IWETH(addr).withdraw(testETH);
            require(address(this).balance - beforeUnwrap == testETH, "FAILED_UNWRAP_TEST");
            require(msg.sender.send(testETH), "FAILED_REFUND_TEST_ETH");
        }
        wethAddresses[addr] = autoWrap;
        emit SetWETH(addr, autoWrap);
    }

    /// Checks whether the user has enough deposit.
    /// @param token Token address.
    /// @param user User address.
    /// @param amount Token amount.
    /// @return Whether the user has enough deposit.
    function hasDeposit(address token, address user, uint256 amount, bytes memory) public view returns (bool) {
        if (wethAddresses[token]) {
            return amount <= deposits[address(0)][user];
        }
        return amount <= deposits[token][user];
    }

    /// Checks token balance available to use (including user deposit amount + user approved allowance amount).
    /// @param token Token address.
    /// @param user User address.
    /// @return Token amount available.
    function getAvailable(address token, address user, bytes calldata) external view returns (uint256) {
        if (token == address(0)) {
            return deposits[address(0)][user];
        }
        uint256 allowance = min(
            IERC20(token).allowance(user, address(this)),
            IERC20(token).balanceOf(user)
        );
        return add(allowance, balanceOf(token, user));
    }

    /// Gets balance of user's deposit.
    /// @param token Token address.
    /// @param user User address.
    /// @return Token deposit amount.
    function balanceOf(address token, address user) public view returns (uint256) {
        if (wethAddresses[token]) {
            return deposits[address(0)][user];
        }
        return deposits[token][user];
    }

    /// Deposits token from user wallet to bank.
    /// @param token Token address.
    /// @param user User address (allows third-party give tokens to any users).
    /// @param amount Token amount.
    function deposit(address token, address user, uint256 amount, bytes calldata) external nonReentrant payable {
        if (token == address(0)) {
            require(amount == msg.value, "UNMATCHED_DEPOSIT_AMOUNT");
            deposits[address(0)][user] = add(deposits[address(0)][user], msg.value);
            emit Deposit(address(0), user, msg.value, deposits[address(0)][user]);
        } else {
            // Token should be approved in order to transfer
            require(ERC20SafeTransfer.safeTransferFrom(token, msg.sender, address(this), amount), "FAILED_DEPOSIT_TOKEN");
            if (wethAddresses[token]) {
                // Auto unwrap to ETH
                IWETH(token).withdraw(amount);
                deposits[address(0)][user] = add(deposits[address(0)][user], amount);
            } else {
                deposits[token][user] = add(deposits[token][user], amount);
            }
            emit Deposit(token, user, amount, deposits[token][user]);
        }
    }

    /// Withdraws token from bank to user wallet.
    /// @param token Token address.
    /// @param amount Token amount.
    function withdraw(address token, uint256 amount, bytes calldata) external nonReentrant {
        require(hasDeposit(token, msg.sender, amount, ""), "FAILED_WITHDRAW_INSUFFICIENT_DEPOSIT");
        if (token == address(0)) {
            deposits[address(0)][msg.sender] = sub(deposits[address(0)][msg.sender], amount);
            require(msg.sender.send(amount), "FAILED_WITHDRAW_SENDING_ETH");
            emit Withdraw(address(0), msg.sender, amount, deposits[address(0)][msg.sender]);
        } else {
            if (wethAddresses[token]) {
                // Auto wrap to WETH
                IWETH(token).deposit.value(amount)();
                deposits[address(0)][msg.sender] = sub(deposits[address(0)][msg.sender], amount);
            } else {
                deposits[token][msg.sender] = sub(deposits[token][msg.sender], amount);
            }
            require(ERC20SafeTransfer.safeTransfer(token, msg.sender, amount), "FAILED_WITHDRAW_SENDING_TOKEN");
            emit Withdraw(token, msg.sender, amount, deposits[token][msg.sender]);
        }
    }

    /// Transfers token from one address to another address.
    /// Only caller who are double-approved by both bank owner and token owner can invoke this function.
    /// @param token Token address.
    /// @param from The current token owner address.
    /// @param to The new token owner address.
    /// @param amount Token amount.
    /// @param fromDeposit True if use fund from bank deposit. False if use fund from user wallet.
    /// @param toDeposit True if deposit fund to bank deposit. False if send fund to user wallet.
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes calldata,
        bool fromDeposit,
        bool toDeposit
    )
    external
    onlyAuthorized
    onlyUserApproved(from)
    nonReentrant
    {
        if (amount == 0 || from == to) {
            return;
        }
        if (fromDeposit) {
            require(hasDeposit(token, from, amount, ""));
            address actualToken = token;
            if (toDeposit) {
                // Deposit to deposit
                if (wethAddresses[token]) {
                    actualToken = address(0);
                }
                deposits[actualToken][from] = sub(deposits[actualToken][from], amount);
                deposits[actualToken][to] = add(deposits[actualToken][to], amount);
            } else {
                // Deposit to wallet
                if (token == address(0)) {
                    deposits[actualToken][from] = sub(deposits[actualToken][from], amount);
                    require(address(uint160(to)).send(amount), "FAILED_TRANSFER_FROM_DEPOSIT_TO_WALLET");
                } else {
                    if (wethAddresses[token]) {
                        // Auto wrap to WETH
                        IWETH(token).deposit.value(amount)();
                        actualToken = address(0);
                    }
                    deposits[actualToken][from] = sub(deposits[actualToken][from], amount);
                    require(ERC20SafeTransfer.safeTransfer(token, to, amount), "FAILED_TRANSFER_FROM_DEPOSIT_TO_WALLET");
                }
            }
        } else {
            if (toDeposit) {
                // Wallet to deposit
                require(ERC20SafeTransfer.safeTransferFrom(token, from, address(this), amount), "FAILED_TRANSFER_FROM_WALLET_TO_DEPOSIT");
                deposits[token][to] = add(deposits[token][to], amount);
            } else {
                // Wallet to wallet
                require(ERC20SafeTransfer.safeTransferFrom(token, from, to, amount), "FAILED_TRANSFER_FROM_WALLET_TO_WALLET");
            }
        }
    }
}
"},"ERC20SafeTransfer.sol":{"content":"/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

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


/// @title ERC20 safe transfer
/// @dev see https://github.com/sec-bit/badERC20Fix
/// @author Brecht Devos - <brecht@loopring.org>
library ERC20SafeTransfer {

    function safeTransfer(
        address token,
        address to,
        uint256 value)
    internal
    returns (bool success)
    {
        // A transfer is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        // bytes4(keccak256("transfer(address,uint256)")) = 0xa9059cbb
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
    internal
    returns (bool success)
    {
        // A transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        // bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
    )
    internal
    pure
    returns (bool)
    {
        // A transfer/transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)
        if (success) {
            assembly {
                switch returndatasize()
                // Non-standard ERC20: nothing is returned so if 'call' was successful we assume the transfer succeeded
                case 0 {
                    success := 1
                }
                // Standard ERC20: a single boolean value is returned which needs to be true
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                // None of the above: not successful
                default {
                    success := 0
                }
            }
        }
        return success;
    }

}"},"IBank.sol":{"content":"pragma solidity ^0.5.7;

/// Bank Interface.
interface IBank {

    /// Modifies authorization of an address. Only contract owner can call this function.
    /// @param target Address to authorize / deauthorize.
    /// @param allowed Whether the target address is authorized.
    function authorize(address target, bool allowed) external;

    /// Modifies user approvals of an address.
    /// @param target Address to approve / unapprove.
    /// @param allowed Whether the target address is user approved.
    function userApprove(address target, bool allowed) external;

    /// Batch modifies user approvals.
    /// @param targetList Array of addresses to approve / unapprove.
    /// @param allowedList Array of booleans indicating whether the target address is user approved.
    function batchUserApprove(address[] calldata targetList, bool[] calldata allowedList) external;

    /// Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses() external view returns (address[] memory);

    /// Gets all user approved addresses.
    /// @return Array of user approved addresses.
    function getUserApprovedAddresses() external view returns (address[] memory);

    /// Checks whether the user has enough deposit.
    /// @param token Token address.
    /// @param user User address.
    /// @param amount Token amount.
    /// @param data Additional token data (e.g. tokenId for ERC721).
    /// @return Whether the user has enough deposit.
    function hasDeposit(address token, address user, uint256 amount, bytes calldata data) external view returns (bool);

    /// Checks token balance available to use (including user deposit amount + user approved allowance amount).
    /// @param token Token address.
    /// @param user User address.
    /// @param data Additional token data (e.g. tokenId for ERC721).
    /// @return Token amount available.
    function getAvailable(address token, address user, bytes calldata data) external view returns (uint256);

    /// Gets balance of user's deposit.
    /// @param token Token address.
    /// @param user User address.
    /// @return Token deposit amount.
    function balanceOf(address token, address user) external view returns (uint256);

    /// Deposits token from user wallet to bank.
    /// @param token Token address.
    /// @param user User address (allows third-party give tokens to any users).
    /// @param amount Token amount.
    /// @param data Additional token data (e.g. tokenId for ERC721).
    function deposit(address token, address user, uint256 amount, bytes calldata data) external payable;

    /// Withdraws token from bank to user wallet.
    /// @param token Token address.
    /// @param amount Token amount.
    /// @param data Additional token data (e.g. tokenId for ERC721).
    function withdraw(address token, uint256 amount, bytes calldata data) external;

    /// Transfers token from one address to another address.
    /// Only caller who are double-approved by both bank owner and token owner can invoke this function.
    /// @param token Token address.
    /// @param from The current token owner address.
    /// @param to The new token owner address.
    /// @param amount Token amount.
    /// @param data Additional token data (e.g. tokenId for ERC721).
    /// @param fromDeposit True if use fund from bank deposit. False if use fund from user wallet.
    /// @param toDeposit True if deposit fund to bank deposit. False if send fund to user wallet.
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bool fromDeposit,
        bool toDeposit
    )
    external;
}"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"LibMath.sol":{"content":"pragma solidity ^0.5.7;

contract LibMath {
    // Copied from openzeppelin Math
    /**
    * @dev Returns the largest of two numbers.
    */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
    * @dev Returns the smallest of two numbers.
    */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Calculates the average of two numbers. Since these are integers,
    * averages of an even and odd number cannot be represented, and will be
    * rounded down.
    */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // Modified from openzeppelin SafeMath
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    // Copied from 0x LibMath
    /*
      Copyright 2018 ZeroEx Intl.
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
    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorFloor(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorCeil(
            numerator,
            denominator,
            target
        ),
            "ROUNDING_ERROR"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            mul(numerator, target),
            denominator
        );
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
    internal
    pure
    returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = sub(denominator, remainder) % denominator;
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }
}"},"Ownable.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"},"ReentrancyGuard.sol":{"content":"pragma solidity ^0.5.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2Ï.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}
"}}