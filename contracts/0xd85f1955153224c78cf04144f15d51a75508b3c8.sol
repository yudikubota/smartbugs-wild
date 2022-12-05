{{
  "language": "Solidity",
  "sources": {
    "/contracts/core/market/SGXStaticDataMarketPlace.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "./interface/ProgramProxyInterface.sol";
import "./interface/KeyVerifierInterface.sol";
import "../../utils/Ownable.sol";
import "./SignatureVerifier.sol";
import "../../erc20/IERC20.sol";
import "./SGXRequest.sol";
import "./SGXStaticData.sol";
import "../../plugins/GasRewardTool.sol";
import "../PaymentConfirmTool.sol";
import "../../TrustListTools.sol";
import "./SGXStaticDataMarketStorage.sol";

contract SGXStaticDataMarketPlace is SGXStaticDataMarketStorage{

  using SGXStaticData for mapping(bytes32=>SGXStaticData.Data);
  using SignatureVerifier for bytes32;
  using ECDSA for bytes32;

  constructor(address _program_proxy, address _owner_proxy, address _payment_token) public {
    require(_program_proxy != address(0x0), "invalid program proxy");
    program_proxy = ProgramProxyInterface(_program_proxy);
    payment_token = _payment_token;
    owner_proxy = OwnerProxyInterface(_owner_proxy);
    ratio_base = 1000000;
  }

  event SDMarketChangeProgramProxy(address old_program_proxy, address new_program_proxy);
  function changeProgramProxy(address _program_proxy) onlyOwner public{
    address old = address(program_proxy);
    require(_program_proxy != address(0x0), "invalid program proxy");
    program_proxy = ProgramProxyInterface(_program_proxy);
    emit SDMarketChangeProgramProxy(old, _program_proxy);
  }
  event SDMarketChangeFee(uint256 old_fee_ratio, uint256 new_fee_ratio);
  function changeFee(uint256 _fee_ratio) onlyOwner public {
    uint256 old = fee_ratio;
    fee_ratio = _fee_ratio;
    emit SDMarketChangeFee(old, fee_ratio);
  }
  event SDMarketChangeFeePool(address old_fee_pool, address new_fee_pool);
  function changeFeePool(address payable _addr) onlyOwner public{
    address old = fee_pool;
    fee_pool = _addr;
    emit SDMarketChangeFeePool(old, fee_pool);
  }

  event SDMarketPause(bool paused);
  function pause(bool _paused) public onlyOwner{
    paused = _paused;
    emit SDMarketPause(paused);
  }

  event SDMarketChangeRevokePeriod(uint256 old_period, uint256 new_period);
  function changeRevokePeriod(uint256 _new_period) onlyOwner public{
    uint256 old = request_revoke_block_num;
    request_revoke_block_num = _new_period;
    emit SDMarketChangeRevokePeriod(old, _new_period);
  }

  function getDataInfo(bytes32 _vhash) public view returns(bytes32 data_hash, string memory extra_info, uint256 price, bytes memory pkey, address owner, bool removed, uint256 revoke_timeout_block_num, bool exists){
    SGXStaticData.Data storage d = all_data[_vhash];
    return (d.data_hash, d.extra_info, d.price, d.pkey, owner_proxy.ownerOf(data_hash), d.removed, d.revoke_timeout_block_num, d.exists);
  }

  function getRequestInfo1(bytes32 _vhash, bytes32 request_hash) public view returns(
          address from, bytes memory pkey4v, bytes memory secret, bytes memory input, bytes memory forward_sig, bytes32 program_hash, bytes32 result_hash
      ){
    SGXRequest.Request storage r = all_data[_vhash].requests[request_hash];
    return (r.from, r.pkey4v, r.secret, r.input, r.forward_sig, r.program_hash, r.result_hash);
  }
  function getRequestInfo2(bytes32 _vhash, bytes32 request_hash) public view returns(
          address target_token, uint gas_price, uint block_number, uint256 revoke_block_num, uint256 data_use_price, uint program_use_price, SGXRequest.RequestStatus status, SGXRequest.ResultType result_type
      ){
    SGXRequest.Request storage r = all_data[_vhash].requests[request_hash];
    return (r.target_token, r.gas_price, r.block_number, r.revoke_block_num, r.data_use_price, r.program_use_price, r.status, r.result_type);
  }

  /////////////////////////////////////////////////////

  function delegateCallUseData(address _e, bytes memory _data) public is_trusted(msg.sender) returns(bytes memory){
    (bool succ, bytes memory returndata) = _e.delegatecall(_data);

    if (succ == false) {
      assembly {
        let ptr := mload(0x40)
        let size := returndatasize
        returndatacopy(ptr, 0, size)
        revert(ptr, size)
      }
    }
    require(succ, "delegateCallUseData failed");
    return returndata;
  }
  function getRequestStatus(bytes32 _vhash, bytes32 request_hash) public view returns(int){
    return int(all_data[_vhash].requests[request_hash].status);
  }
  function updateRequestStatus(bytes32 _vhash, bytes32 request_hash, int status) public is_trusted(msg.sender){
    all_data[_vhash].requests[request_hash].status = SGXRequest.RequestStatus(status);
  }
}

contract SGXStaticDataMarketPlaceFactory{
  event NewSGXStaticDataMarketPlace(address addr);
  function createSGXStaticDataMarketPlace(address _program_proxy, address _owner_proxy, address _payment_token) public returns(address){
    SGXStaticDataMarketPlace m = new SGXStaticDataMarketPlace(_program_proxy, _owner_proxy, _payment_token);
    m.transferOwnership(msg.sender);
    emit NewSGXStaticDataMarketPlace(address(m));
    return address(m);
  }
}
"
    },
    "/contracts/utils/SafeMath.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}
"
    },
    "/contracts/utils/Ownable.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}
"
    },
    "/contracts/utils/ECDSA.sol": {
      "content": "// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n Ã· 2 + 1, and for v in (282): v â {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
"
    },
    "/contracts/utils/Address.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
"
    },
    "/contracts/plugins/GasRewardTool.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "../utils/Ownable.sol";
contract GasRewardInterface{
  function reward(address payable to, uint256 amount) public;
}

contract GasRewardTool is Ownable{
  GasRewardInterface public gas_reward_contract;

  modifier rewardGas{
    uint256 gas_start = gasleft();
    _;
    uint256 gasused = (gas_start - gasleft()) * tx.gasprice;
    if(gas_reward_contract != GasRewardInterface(0x0)){
      gas_reward_contract.reward(tx.origin, gasused);
    }
  }

  event ChangeRewarder(address _old, address _new);
  function changeRewarder(address _rewarder) public onlyOwner{
    address old = address(gas_reward_contract);
    gas_reward_contract = GasRewardInterface(_rewarder);
    emit ChangeRewarder(old, _rewarder);
  }
}
"
    },
    "/contracts/erc20/SafeERC20.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

import "../utils/SafeMath.sol";
import "../utils/Address.sol";
import "./IERC20.sol";

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
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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
    "/contracts/erc20/IERC20.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Property{
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}
"
    },
    "/contracts/core/market/interface/ProgramProxyInterface.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
  function program_owner(bytes32 hash) public view returns(address);
  function enclave_hash(bytes32 hash) public view returns(bytes32);
}
"
    },
    "/contracts/core/market/interface/OwnerProxyInterface.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
contract OwnerProxyInterface{
  function ownerOf(bytes32 hash) public view returns(address);
  function initOwnerOf(bytes32 hash, address owner) external returns(bool);
}
"
    },
    "/contracts/core/market/interface/KeyVerifierInterface.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
contract KeyVerifierInterface{
  function verify_pkey(bytes memory _pkey, bytes memory _pkey_sig) public view returns(bool);
}
"
    },
    "/contracts/core/market/SignatureVerifier.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "../../utils/ECDSA.sol";

library SignatureVerifier{
  using ECDSA for bytes32;
  function verify_signature(bytes32 hash, bytes memory sig, bytes memory pkey) internal pure returns (bool){
    address expected = getAddressFromPublicKey(pkey);
    return hash.recover(sig) == expected;
  }

  function getAddressFromPublicKey(bytes memory _publicKey) internal pure returns (address addr) {
    bytes32 hash = keccak256(_publicKey);
    assembly {
      mstore(0, hash)
      addr := mload(0)
    }
  }

}
"
    },
    "/contracts/core/market/SGXStaticDataMarketStorage.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "./interface/ProgramProxyInterface.sol";
import "./interface/KeyVerifierInterface.sol";
import "../../utils/Ownable.sol";
import "./SignatureVerifier.sol";
import "../../plugins/GasRewardTool.sol";
import "../PaymentConfirmTool.sol";
import "../../TrustListTools.sol";
import "./SGXStaticData.sol";
import "./interface/OwnerProxyInterface.sol";

contract SGXStaticDataMarketStorage is Ownable, GasRewardTool, PaymentConfirmTool, TrustListTools{
  mapping(bytes32=>SGXStaticData.Data) public all_data;

  bool public paused;

  ProgramProxyInterface public program_proxy;
  OwnerProxyInterface public owner_proxy;
  address public payment_token;
  uint256 public request_revoke_block_num;

  address payable public fee_pool;
  uint256 public ratio_base;
  uint256 public fee_ratio;
}
"
    },
    "/contracts/core/market/SGXStaticData.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "../../utils/Ownable.sol";
import "../../utils/ECDSA.sol";
import "./interface/KeyVerifierInterface.sol";
import "./interface/ProgramProxyInterface.sol";
import "./SGXRequest.sol";



library SGXStaticData {
  using SGXRequest for mapping(bytes32 => SGXRequest.Request);

  struct Data{
    bytes32 data_hash;
    string extra_info; //os, sgx sdk, cpu, compiler, data format, we leave this to user
    uint256 price;
    bytes pkey;
    mapping(bytes32 => SGXRequest.Request) requests;
    bool removed;
    uint256 revoke_timeout_block_num;
    bool exists;
  }


  function init(mapping(bytes32=>SGXStaticData.Data) storage all_data,
                bytes32 _hash,
              string memory _data_uri,
              uint _price, uint256 _revoke_block_num,
              bytes memory _pkey) public returns(bytes32){
    bytes32 vhash = keccak256(abi.encodePacked(_hash, _data_uri, _price, block.number));
    require(!all_data[vhash].exists, "data already exist");
    all_data[vhash].data_hash = _hash;
    all_data[vhash].extra_info= _data_uri;
    all_data[vhash].price = _price;
    all_data[vhash].pkey = _pkey;
    all_data[vhash].removed = false;
    all_data[vhash].revoke_timeout_block_num = _revoke_block_num;
    all_data[vhash].exists = true;

    return vhash;
  }

  function remove(mapping(bytes32=>SGXStaticData.Data) storage all_data,
                  bytes32 _vhash) public {
    require(all_data[_vhash].exists, "data vhash not exist");
    /*require(all_data[_vhash].owner == msg.sender, "only owner can remove the data");*/
    all_data[_vhash].removed = true;
  }

}

"
    },
    "/contracts/core/market/SGXRequest.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "../../erc20/IERC20.sol";
import "../../erc20/SafeERC20.sol";
import "./SignatureVerifier.sol";
import "../../utils/SafeMath.sol";
import "./interface/ProgramProxyInterface.sol";

library SGXRequest{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;
  using SignatureVerifier for bytes32;

  enum RequestStatus{
    invalid, //invalid request
    init, init_need_confirm,
    ready, ready_need_confirm,
    request_key, request_key_need_confirm,
    settled, settled_need_confirm,
    revoked, revoked_need_confirm,
    rejected, rejected_need_confirm}

  enum ResultType{offchain, onchain}

    struct Request{
      address payable from;
      bytes pkey4v;
      bytes secret;
      bytes input;
      bytes forward_sig;
      bytes32 program_hash;
      bytes32 result_hash;
      address target_token;
      uint token_amount;
      uint gas_price;
      uint block_number;
      uint256 revoke_block_num;
      uint data_use_price;
      uint program_use_price;
      RequestStatus status;
      ResultType result_type;
      bool exists;
    }
    struct RequestInitParam{
      bytes secret;
      bytes input;
      bytes forward_sig;
      bytes32 program_hash;
      uint gas_price;
      bytes pkey;
      uint data_use_price;
      uint program_use_price;
      ProgramProxyInterface program_proxy;
    }

  function refund_request(mapping(bytes32=>SGXRequest.Request) storage request_infos, bytes32 request_hash, uint256 refund_amount) internal {
    require(request_infos[request_hash].exists, "request not exist");
    require(request_infos[request_hash].status == SGXRequest.RequestStatus.init , "invalid status");

    request_infos[request_hash].token_amount = request_infos[request_hash].token_amount.safeAdd(refund_amount);

    if(request_infos[request_hash].target_token != address(0x0)){
      IERC20(request_infos[request_hash].target_token).safeTransferFrom(msg.sender, address(this), refund_amount);
    }
  }

  function remind_cost(mapping(bytes32=>SGXRequest.Request) storage request_infos,
                         bytes32 data_hash,
                         uint256 data_price,
                         ProgramProxyInterface program_proxy,
                         bytes32 request_hash, uint64 cost,
                         bytes memory sig, uint256 ratio_base, uint256 fee_ratio) internal view returns(uint256 gap){
    require(request_infos[request_hash].exists, "request not exist");
    require(request_infos[request_hash].status == SGXRequest.RequestStatus.init, "invalid status");

    SGXRequest.Request storage r = request_infos[request_hash];
    {
      bytes memory cost_msg = abi.encodePacked(r.input, data_hash, program_proxy.enclave_hash(r.program_hash), uint64(cost));
      bytes32 vhash = keccak256(cost_msg);

      bool v = vhash.toEthSignedMessageHash().verify_signature(sig, r.pkey4v);
      require(v, "invalid cost signature");
    }

    uint256 c = cost;
    uint amount = c.safeMul(r.gas_price);
    amount = amount.safeAdd(data_price).safeAdd(program_proxy.program_price(r.program_hash));
    uint256 fee = amount.safeMul(fee_ratio).safeDiv(ratio_base);
    amount = amount.safeAdd(fee);

    if(amount > request_infos[request_hash].token_amount){
      return amount-request_infos[request_hash].token_amount;
    }else{
      return 0;
    }
  }

  function revoke_request(mapping(bytes32=>SGXRequest.Request) storage request_infos,
                          bytes32 request_hash) internal returns(uint256){
    require(request_infos[request_hash].exists, "request not exist");
    SGXRequest.Request storage r = request_infos[request_hash];
    require(r.status == SGXRequest.RequestStatus.init || r.status == SGXRequest.RequestStatus.ready || r.status == SGXRequest.RequestStatus.request_key, "invalid status");

    require(block.number - r.block_number >= r.revoke_block_num, "not long enough for revoke");

    //TODO: charge fee for revoke
    r.status = SGXRequest.RequestStatus.revoked;
    if(r.target_token != address(0x0)){
      IERC20(r.target_token).safeTransfer(r.from, r.token_amount);
    }
    return r.token_amount;
  }

}
"
    },
    "/contracts/core/PaymentConfirmTool.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "../utils/Ownable.sol";

contract IPaymentProxy{
  function startTransferRequest() public returns(bytes32);
  function endTransferRequest() public returns(bytes32);
  function currentTransferRequestHash() public view returns(bytes32);
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8);
  function transferCommit(bytes32 _hash, bool _status) public ;
}

contract PaymentConfirmTool is Ownable{
  address public confirm_proxy;

  //@return 0 is init or pending, 1 is for succ, 2 is for fail
  function getTransferRequestStatus(bytes32 _hash) public view returns(uint8){
    return IPaymentProxy(confirm_proxy).getTransferRequestStatus(_hash) ;
  }

  event ChangeConfirmProxy(address old_proxy, address new_proxy);
  function changeConfirmProxy(address new_proxy) public onlyOwner{
    address old = confirm_proxy;
    confirm_proxy = new_proxy;
    emit ChangeConfirmProxy(old, new_proxy);
  }

}
"
    },
    "/contracts/TrustListTools.sol": {
      "content": "pragma solidity >=0.4.21 <0.6.0;
import "./utils/Ownable.sol";

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
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
    "evmVersion": "petersburg",
    "libraries": {},
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
    }
  }
}}