{{
  "language": "Solidity",
  "sources": {
    "contracts/NestPool.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./lib/SafeMath.sol";
import "./lib/AddressPayable.sol";
import "./lib/SafeERC20.sol";
import './lib/TransferHelper.sol';
import "./iface/INestPool.sol";
import "./iface/INestDAO.sol";
import "./iface/INestMining.sol";
import "./iface/INestQuery.sol";
import "./iface/INestStaking.sol";
import "./iface/INNRewardPool.sol";
import "./iface/INTokenController.sol";

/// @title NestPool
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

/// @dev The contract is for bookkeeping ETH, NEST and Tokens. It is served as a vault, such that 
///     assets are transferred internally to save GAS.
contract NestPool is INestPool {
    
    using address_make_payable for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint8 private flag;  // 0: UNINITIALIZED  | 1: INITIALIZED
    uint256 public minedNestAmount; 

    address override public governance;
    address public addrOfNestBurning = address(0x1);

    // Contracts 
    address public C_NestDAO;
    address public C_NestMining;
    ERC20   public C_NestToken;
    address public C_NTokenController;
    address public C_NNToken;
    address public C_NNRewardPool;
    address public C_NestStaking;
    address public C_NestQuery;

    // eth ledger for all miners
    mapping(address => uint256) _eth_ledger;
    // token => miner => amount 
    mapping(address => mapping(address => uint256)) _token_ledger;

    // mapping(address => uint256) _nest_ledger;

    mapping(address => address) _token_ntoken_mapping;

    // parameters 

    constructor() public 
    {
        governance = msg.sender;
    }

    receive() external payable { }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:Pool:!governance");
        _;
    }

    modifier onlyBy(address _contract) 
    {
        require(msg.sender == _contract, "Nest:Pool:!Auth");
        _;
    }

    modifier onlyGovOrBy(address _contract) 
    {
        require(msg.sender == governance || msg.sender == _contract, "Nest:Pool:!Auth");
        _;
    }

    /*
    modifier onlyGovOrBy2(address _contract, address _contract2)
    {
        require(msg.sender == governance || msg.sender == _contract || msg.sender == _contract2, "Nest:Pool:!Auth");
        _;
    }

    modifier onlyGovOrBy3(address _contract1, address _contract2, address _contract3)
    {
        require(msg.sender == governance
            || msg.sender == _contract1
            || msg.sender == _contract2
            || msg.sender == _contract3, "Nest:Pool:!Auth");
        _;
    }
    */
    modifier onlyByNest()
    {
        require(msg.sender == C_NestMining
            || msg.sender == C_NTokenController 
            || msg.sender == C_NestDAO 
            || msg.sender == C_NestStaking 
            || msg.sender == C_NNRewardPool 
            || msg.sender == C_NestQuery, "Nest:Pool:!Auth");
        _;
    }

    modifier onlyMiningContract()
    {
        require(address(msg.sender) == C_NestMining, "Nest:Pool:onlyMining");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function setGovernance(address _gov) 
        override external onlyGovernance 
    { 
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];
        _nest_ledger[_gov] = _nest_ledger[governance];  
        _nest_ledger[governance] = 0;
        governance = _gov;
    }

    function setContracts(
            address NestToken, address NestMining, 
            address NestStaking, address NTokenController, 
            address NNToken, address NNRewardPool, 
            address NestQuery, address NestDAO
        ) 
        external onlyGovernance
    {
        if (NestToken != address(0)) {
            C_NestToken = ERC20(NestToken);
        }
        if (NestMining != address(0)) {
            C_NestMining = NestMining;
        }
        if (NTokenController != address(0)) {
            C_NTokenController = NTokenController;
        }
        if (NNToken != address(0)) {
            C_NNToken = NNToken;
        }
        if (NNRewardPool != address(0)) {
            C_NNRewardPool = NNRewardPool;
        }
        if (NestStaking != address(0)) {
            C_NestStaking = NestStaking;
        }
        if (NestQuery != address(0)) {
            C_NestQuery = NestQuery;
        }
        if (NestDAO != address(0)) {
            C_NestDAO = NestDAO;
        }
    }

    /// @dev Set the total amount of NEST in the pool. After Nest v3.5 upgrading, all 
    ///    of the unmined NEST will be transferred by the governer to this pool. 
    function initNestLedger(uint256 amount) 
        override external onlyGovernance 
    {
        require(_token_ledger[address(C_NestToken)][address(governance)] == 0, "Nest:Pool:!init"); 
        _token_ledger[address(C_NestToken)][address(governance)] = amount;
    }

    function getNTokenFromToken(address token) 
        override view public returns (address) 
    {
        return _token_ntoken_mapping[token];
    }

    function setNTokenToToken(address token, address ntoken) 
        override 
        public
        onlyGovOrBy(C_NTokenController) 
    {
        _token_ntoken_mapping[token] = ntoken;
        _token_ntoken_mapping[ntoken] = ntoken;
    }

    /* ========== ONLY FOR EMERGENCY ========== */

    // function drainEth(address to, uint256 amount) 
    //     external onlyGovernance
    // {
    //     TransferHelper.safeTransferETH(to, amount);
    // }

    function drainNest(address to, uint256 amount, address gov) 
         override external onlyGovernance
    {
         require(_token_ledger[address(C_NestToken)][gov] >= amount, "Nest:Pool:!amount");
         C_NestToken.transfer(to, amount);
    }

    function transferNestInPool(address from, address to, uint256 amount) 
        external onlyByNest
    {
        if (amount == 0) {
            return;
        }
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];
        uint256 blnc = _nest_ledger[from];
        require (blnc >= amount, "Nest:Pool:!amount");
        _nest_ledger[from] = blnc.sub(amount);
        _nest_ledger[to] = _nest_ledger[to].add(amount);
    }

    function transferTokenInPool(address token, address from, address to, uint256 amount) 
        external onlyByNest
    {
        if (amount == 0) {
            return;
        }
        uint256 blnc = _token_ledger[token][from];
        require (blnc >= amount, "Nest:Pool:!amount");
        _token_ledger[token][from] = blnc.sub(amount);
        _token_ledger[token][to] = _token_ledger[token][to].add(amount);
    }

    function transferEthInPool(address from, address to, uint256 amount) 
        external onlyByNest
    {
        if (amount == 0) {
            return;
        }
        uint256 blnc = _eth_ledger[from];
        require (blnc >= amount, "Nest:Pool:!amount");
        _eth_ledger[from] = blnc.sub(amount);
        _eth_ledger[to] = _eth_ledger[to].add(amount);
    }


    /* ========== FREEZING/UNFREEZING ========== */

    // NOTE: Guarded by onlyMiningContract

    function freezeEth(address miner, uint256 ethAmount) 
        override public onlyBy(C_NestMining) 
    {
        // emit LogAddress("freezeEthAndToken> miner", miner);
        // emit LogAddress("freezeEthAndToken> token", token);
        uint256 blncs = _eth_ledger[miner];
        require(blncs >= ethAmount, "Nest:Pool:BAL(eth)<0");
        _eth_ledger[miner] = blncs - ethAmount;  //safe_math: checked before
        _eth_ledger[address(this)] =  _eth_ledger[address(this)].add(ethAmount);
    }

    function unfreezeEth(address miner, uint256 ethAmount) 
        override public onlyBy(C_NestMining)  
    {
        if (ethAmount > 0) {
            // LogUint("unfreezeEthAndToken> _eth_ledger[address(0x0)]", _eth_ledger[address(0x0)]);
            // LogUint("unfreezeEthAndToken> _eth_ledger[miner]", _eth_ledger[miner]);
            // LogUint("unfreezeEthAndToken> ethAmount", ethAmount);
            _eth_ledger[address(this)] =  _eth_ledger[address(this)].sub(ethAmount);
            _eth_ledger[miner] = _eth_ledger[miner].add(ethAmount);
        } 
    }

    function freezeNest(address miner, uint256 nestAmount) 
        override public onlyBy(C_NestMining)  
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];

        uint256 blncs = _nest_ledger[miner];
        
        _nest_ledger[address(this)] =  _nest_ledger[address(this)].add(nestAmount);

        if (blncs < nestAmount) {
            _nest_ledger[miner] = 0; 
            require(C_NestToken.transferFrom(miner,  address(this), nestAmount - blncs), "Nest:Pool:!transfer"); //safe math
        } else {
            _nest_ledger[miner] = blncs - nestAmount;  //safe math
        }
    }

    function unfreezeNest(address miner, uint256 nestAmount) 
        override public onlyBy(C_NestMining)  
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];

        if (nestAmount > 0) {
            _nest_ledger[address(this)] =  _nest_ledger[address(this)].sub(nestAmount);
            _nest_ledger[miner] = _nest_ledger[miner].add(nestAmount); 
        }
    }

    function freezeToken(address miner, address token, uint256 tokenAmount) 
        override external onlyBy(C_NestMining)  
    {
        uint256 blncs = _token_ledger[token][miner];
        _token_ledger[token][address(this)] =  _token_ledger[token][address(this)].add(tokenAmount);
        if (blncs < tokenAmount) {
            _token_ledger[token][miner] = 0; 
            ERC20(token).safeTransferFrom(address(miner),  address(this), tokenAmount - blncs); //safe math
        } else {
            _token_ledger[token][miner] = blncs - tokenAmount;  //safe math
        }
    }

    function unfreezeToken(address miner, address token, uint256 tokenAmount) 
        override external onlyBy(C_NestMining)  
    {
        if (tokenAmount > 0) {
            _token_ledger[token][address(this)] =  _token_ledger[token][address(this)].sub(tokenAmount);
            _token_ledger[token][miner] = _token_ledger[token][miner].add(tokenAmount); 
        }
    }

    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) 
        override external onlyBy(C_NestMining)  
    {
        uint256 blncs = _eth_ledger[miner];
        require(blncs >= ethAmount, "Nest:Pool:!eth");
        _eth_ledger[miner] = blncs - ethAmount;  //safe_math: checked before
        _eth_ledger[address(this)] =  _eth_ledger[address(this)].add(ethAmount);

        blncs = _token_ledger[token][miner];
        _token_ledger[token][address(this)] =  _token_ledger[token][address(this)].add(tokenAmount);
        if (blncs < tokenAmount) {
            _token_ledger[token][miner] = 0;
            ERC20(token).safeTransferFrom(address(miner),  address(this), tokenAmount - blncs); //safe math
        } else {
            _token_ledger[token][miner] = blncs - tokenAmount;  //safe math
        }
    }

    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) 
        override external onlyBy(C_NestMining)  
    {
        if (ethAmount > 0) {
            _eth_ledger[address(this)] =  _eth_ledger[address(this)].sub(ethAmount);
            _eth_ledger[miner] = _eth_ledger[miner].add(ethAmount);
        } 

        if (tokenAmount > 0) {
            _token_ledger[token][address(this)] =  _token_ledger[token][address(this)].sub(tokenAmount);
            _token_ledger[token][miner] = _token_ledger[token][miner].add(tokenAmount); 
        }
    }

    /* ========== BALANCE ========== */


    function balanceOfNestInPool(address miner) 
        override public view returns (uint256)
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];

        return _nest_ledger[miner];
    }

    function balanceOfEthInPool(address miner) 
        override public view returns (uint256)
    {
        return _eth_ledger[miner];
    }

    function balanceOfTokenInPool(address miner, address token) 
        override public view returns (uint256)
    {
        return _token_ledger[token][miner];
    }

    function balanceOfEthFreezed() public view returns (uint256)
    {
        return _eth_ledger[address(this)];
    }

    function balanceOfTokenFreezed(address token) public view returns (uint256)
    {
        return _token_ledger[token][address(this)];
    }

    /* ========== DISTRIBUTING ========== */

    function addNest(address miner, uint256 amount) 
        override public onlyBy(C_NestMining)
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];
        _nest_ledger[governance] = _nest_ledger[governance].sub(amount);
        _nest_ledger[miner] = _nest_ledger[miner].add(amount);
        minedNestAmount = minedNestAmount.add(amount);
    }

    function addNToken(address miner, address ntoken, uint256 amount) 
        override public onlyBy(C_NestMining)
    {
        _token_ledger[ntoken][miner] = _token_ledger[ntoken][miner].add(amount);
    }

    /* ========== DEPOSIT ========== */

    // NOTE: Guarded by onlyMiningContract

    function depositEth(address miner) 
        override payable external onlyGovOrBy(C_NestMining) 
    {
        _eth_ledger[miner] =  _eth_ledger[miner].add(msg.value);
    }

    function depositNToken(address miner, address from, address ntoken, uint256 amount) 
        override external onlyGovOrBy(C_NestMining) 
    {
        ERC20(ntoken).transferFrom(from, address(this), amount);
        _token_ledger[ntoken][miner] =  _token_ledger[ntoken][miner].add(amount);
    }

    /* ========== WITHDRAW ========== */

    // NOTE: Guarded by onlyGovOrBy(C_NestMining), onlyGovOrBy(C_NestStaking)
    
    /// @dev If amount == 0, it won't go stuck
    function withdrawEth(address miner, uint256 ethAmount) 
        override public onlyByNest
    {
        uint256 blncs = _eth_ledger[miner];
        require(ethAmount <= blncs, "Nest:Pool:!blncs");
        if (ethAmount > 0) {
            _eth_ledger[miner] = blncs - ethAmount; // safe math
            TransferHelper.safeTransferETH(miner, ethAmount);
        }
    }

    /// @dev If amount == 0, it won't go stuck
    function withdrawToken(address miner, address token, uint256 tokenAmount) 
        override public onlyByNest
    {
        uint256 blncs = _token_ledger[token][miner];
        require(tokenAmount <= blncs, "Nest:Pool:!blncs");
        if (tokenAmount > 0) {
            _token_ledger[token][miner] = blncs - tokenAmount; // safe math
            ERC20(token).safeTransfer(miner, tokenAmount);
        }
    }


    /// @dev If amount == 0, it won't go stuck
    function withdrawNest(address miner, uint256 amount) 
        override public onlyByNest
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];

        uint256 blncs = _nest_ledger[miner];
        require(amount <= blncs, "Nest:Pool:!blncs");
        if (amount > 0) {
            _nest_ledger[miner] = blncs - amount;  // safe math
            require(C_NestToken.transfer(miner, amount),"Nest:Pool:!TRANS");
        }
    }


    /// @dev If amount == 0, it won't go stuck
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) 
        override public onlyBy(C_NestMining)
    {
        uint256 blncs = _eth_ledger[miner];
        if (ethAmount <= blncs && ethAmount > 0) {
            _eth_ledger[miner] = blncs - ethAmount;  // safe math
            TransferHelper.safeTransferETH(miner, ethAmount);
        }

        blncs = _token_ledger[token][miner];
        if (tokenAmount <= blncs && tokenAmount > 0) {
            _token_ledger[token][miner] = blncs - tokenAmount;  // safe math
            ERC20(token).safeTransfer(miner, tokenAmount);
        }
    }

    /// @dev If amount == 0, it won't go stuck
    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) 
        override public onlyBy(C_NestStaking)
    {
        uint256 blncs = _token_ledger[ntoken][miner];
        require(amount <= blncs, "Nest:Pool:!blncs");
        if (amount > 0) {
            _token_ledger[ntoken][miner] = blncs - amount;  // safe math
            require(ERC20(ntoken).transfer(to, amount),"Nest:Pool:!TRANS");
        }
    }

    /* ========== HELPERS (VIEWS) ========== */
    // the user needs to be reminded of the parameter settings    
    function assetsList(uint256 len, address[] memory tokenList) 
        public view returns (uint256[] memory) 
    {
        // len < = length(tokenList) + 1
        require(len == tokenList.length + 1, "Nest: Pool: !assetsList");
        uint256[] memory list = new uint256[](len);
        list[0] = _eth_ledger[address(msg.sender)];
        for (uint i = 0; i < len - 1; i++) {
            address _token = tokenList[i];
            list[i+1] = _token_ledger[_token][address(msg.sender)];
        }
        return list;
    }

    function addrOfNestMining() override public view returns (address) 
    {
        return C_NestMining;
    }

    function addrOfNestToken() override public view returns (address) 
    {
        return address(C_NestToken);
    }

    function addrOfNTokenController() override public view returns (address) 
    {
        return C_NTokenController;
    }
    
    function addrOfNNRewardPool() override public view returns (address) 
    {
        return C_NNRewardPool;
    }

    function addrOfNNToken() override public view returns (address) 
    {
        return C_NNToken;
    }

    function addrOfNestStaking() override public view returns (address) 
    {
        return C_NestStaking;
    }

    function addrOfNestQuery() override public view returns (address) 
    {
        return C_NestQuery;
    }

    function addrOfNestDAO() override public view returns (address) 
    {
        return C_NestDAO;
    }

    function addressOfBurnedNest() override public view returns (address) 
    {
        return addrOfNestBurning;
    }

    // function getMinerNToken(address miner, address token) public view returns (uint256 tokenAmount) 
    // {
    //     if (token != address(0x0)) {
    //         tokenAmount = _token_ledger[token][miner];
    //     }
    // } 
        
    function getMinerEthAndToken(address miner, address token) 
        public view returns (uint256 ethAmount, uint256 tokenAmount) 
    {
        ethAmount = _eth_ledger[miner];
        if (token != address(0x0)) {
            tokenAmount = _token_ledger[token][miner];
        }
    } 

    function getMinerNest(address miner) public view returns (uint256 nestAmount) 
    {
        mapping(address => uint256) storage _nest_ledger = _token_ledger[address(C_NestToken)];

        nestAmount = _nest_ledger[miner];
    } 

}
"
    },
    "contracts/lib/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}"
    },
    "contracts/lib/AddressPayable.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}"
    },
    "contracts/lib/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}"
    },
    "contracts/lib/TransferHelper.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}"
    },
    "contracts/iface/INestPool.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "../lib/SafeERC20.sol";

interface INestPool {

    // function getNTokenFromToken(address token) view external returns (address);
    // function setNTokenToToken(address token, address ntoken) external; 

    function addNest(address miner, uint256 amount) external;
    function addNToken(address contributor, address ntoken, uint256 amount) external;

    function depositEth(address miner) external payable;
    function depositNToken(address miner,  address from, address ntoken, uint256 amount) external;

    function freezeEth(address miner, uint256 ethAmount) external; 
    function unfreezeEth(address miner, uint256 ethAmount) external;

    function freezeNest(address miner, uint256 nestAmount) external;
    function unfreezeNest(address miner, uint256 nestAmount) external;

    function freezeToken(address miner, address token, uint256 tokenAmount) external; 
    function unfreezeToken(address miner, address token, uint256 tokenAmount) external;

    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;

    function getNTokenFromToken(address token) external view returns (address); 
    function setNTokenToToken(address token, address ntoken) external; 

    function withdrawEth(address miner, uint256 ethAmount) external;
    function withdrawToken(address miner, address token, uint256 tokenAmount) external;

    function withdrawNest(address miner, uint256 amount) external;
    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;
    // function withdrawNToken(address miner, address ntoken, uint256 amount) external;
    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) external;


    function balanceOfNestInPool(address miner) external view returns (uint256);
    function balanceOfEthInPool(address miner) external view returns (uint256);
    function balanceOfTokenInPool(address miner, address token)  external view returns (uint256);

    function addrOfNestToken() external view returns (address);
    function addrOfNestMining() external view returns (address);
    function addrOfNTokenController() external view returns (address);
    function addrOfNNRewardPool() external view returns (address);
    function addrOfNNToken() external view returns (address);
    function addrOfNestStaking() external view returns (address);
    function addrOfNestQuery() external view returns (address);
    function addrOfNestDAO() external view returns (address);

    function addressOfBurnedNest() external view returns (address);

    function setGovernance(address _gov) external; 
    function governance() external view returns(address);
    function initNestLedger(uint256 amount) external;
    function drainNest(address to, uint256 amount, address gov) external;

}"
    },
    "contracts/iface/INestDAO.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

interface INestDAO {

    function addETHReward(address ntoken) external payable; 

    function addNestReward(uint256 amount) external;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external;
    
    /// @dev Only for governance
    function start() external; 

    function initEthLedger(address ntoken, uint256 amount) external;

    event NTokenRedeemed(address ntoken, address user, uint256 amount);

    event AssetsCollected(address user, uint256 ethAmount, uint256 nestAmount);

    event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);

    event FlagSet(address gov, uint256 flag);

}"
    },
    "contracts/iface/INestMining.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/SafeERC20.sol";


interface INestMining {
    
    struct Params {
        uint8    miningEthUnit;     // = 10;
        uint32   nestStakedNum1k;   // = 1;
        uint8    biteFeeRate;       // = 1; 
        uint8    miningFeeRate;     // = 10;
        uint8    priceDurationBlock; 
        uint8    maxBiteNestedLevel; // = 3;
        uint8    biteInflateFactor;
        uint8    biteNestInflateFactor;
    }

    function priceOf(address token) external view returns(uint256 ethAmount, uint256 tokenAmount, uint256 bn);
    
    function priceListOfToken(address token, uint8 num) external view returns(uint128[] memory data, uint256 bn);

    // function priceOfTokenAtHeight(address token, uint64 atHeight) external view returns(uint256 ethAmount, uint256 tokenAmount, uint64 bn);

    function latestPriceOf(address token) external view returns (uint256 ethAmount, uint256 tokenAmount, uint256 bn);

    function priceAvgAndSigmaOf(address token) 
        external view returns (uint128, uint128, int128, uint32);

    function minedNestAmount() external view returns (uint256);

    /// @dev Only for governance
    function loadContracts() external; 
    
    function loadGovernance() external;

    function upgrade() external;

    function setup(uint32   genesisBlockNumber, uint128  latestMiningHeight, uint128  minedNestTotalAmount, Params calldata initParams) external;

    function setParams1(uint128  latestMiningHeight, uint128  minedNestTotalAmount) external;
}"
    },
    "contracts/iface/INestQuery.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

/// @title The interface of NestQuery
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>
interface INestQuery {

    /// @notice Activate a pay-per-query defi client with NEST tokens
    /// @dev No contract is allowed to call it
    /// @param defi The addres of client (DeFi DApp)
    function activate(address defi) external;

    /// @notice Deactivate a pay-per-query defi client
    /// @param defi The address of a client (DeFi DApp)
    function deactivate(address defi) external;

    /// @notice Query for PPQ (pay-per-query) clients
    /// @dev Consider that if a user call a DeFi that queries NestQuery, DeFi should
    ///     pass the user's wallet address to query() as `payback`.
    /// @param token The address of token contract
    /// @param payback The address of change
    function query(address token, address payback) 
        external payable returns (uint256, uint256, uint256);

    /// @notice Query for PPQ (pay-per-query) clients
    /// @param token The address of token contract
    /// @param payback The address of change
    /// @return ethAmount The amount of ETH in pair (ETH, TOKEN)
    /// @return tokenAmount The amount of TOKEN in pair (ETH, TOKEN)
    /// @return avgPrice The average of last 50 prices 
    /// @return vola The volatility of prices 
    /// @return bn The block number when (ETH, TOKEN) takes into effective
    function queryPriceAvgVola(address token, address payback) 
        external payable returns (uint256, uint256, uint128, int128, uint256);

    /// @notice The main function called by DeFi clients, compatible to Nest Protocol v3.0 
    /// @dev  The payback address is ZERO, so the changes are kept in this contract
    ///         The ABI keeps consist with Nest v3.0
    /// @param tokenAddress The address of token contract address
    /// @return ethAmount The amount of ETH in price pair (ETH, ERC20)
    /// @return erc20Amount The amount of ERC20 in price pair (ETH, ERC20)
    /// @return blockNum The block.number where the price is being in effect
    function updateAndCheckPriceNow(address tokenAddress) 
        external payable returns (uint256, uint256, uint256);

    /// @notice A non-free function for querying price 
    /// @param token  The address of the token contract
    /// @param num    The number of price sheets in the list
    /// @param payback The address for change
    /// @return The array of prices, each of which is (blockNnumber, ethAmount, tokenAmount)
    function queryPriceList(address token, uint8 num, address payback) 
        external payable returns (uint128[] memory);

    /// @notice A view function returning the historical price list from the current block
    /// @param token  The address of the token contract
    /// @param num    The number of price sheets in the list
    /// @return The array of prices, each of which is (blockNnumber, ethAmount, tokenAmount)
    function priceList(address token, uint8 num) 
        external view returns (uint128[] memory);

    /// @notice A view function returning the latestPrice
    /// @param token  The address of the token contract
    function latestPrice(address token)
    external view returns (uint256 ethAmount, uint256 tokenAmount, uint128 avgPrice, int128 vola, uint256 bn) ;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 


    event ClientActivated(address, uint256, uint256);
    // event ClientRenewed(address, uint256, uint256, uint256);
    event PriceQueried(address client, address token, uint256 ethAmount, uint256 tokenAmount, uint256 bn);
    event PriceAvgVolaQueried(address client, address token, uint256 bn, uint128 avgPrice, int128 vola);

    event PriceListQueried(address client, address token, uint256 bn, uint8 num);

    // governance events
    event ParamsSetup(address gov, uint256 oldParams, uint256 newParams);
    event FlagSet(address gov, uint256 flag);
}"
    },
    "contracts/iface/INestStaking.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


interface INestStaking {
    // Views

    /// @dev How many stakingToken (XToken) deposited into to this reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @return The total amount of XTokens deposited in this staking pool
    function totalStaked(address ntoken) external view returns (uint256);

    /// @dev How many stakingToken (XToken) deposited by the target account
    /// @param  ntoken The address of NToken
    /// @param  account The target account
    /// @return The total amount of XToken deposited in this staking pool
    function stakedBalanceOf(address ntoken, address account) external view returns (uint256);


    // Mutative
    /// @dev Stake/Deposit into the reward pool (staking pool)
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function stake(address ntoken, uint256 amount) external;

    function stakeFromNestPool(address ntoken, uint256 amount) external;

    /// @dev Withdraw from the reward pool (staking pool), get the original tokens back
    /// @param  ntoken The address of NToken
    /// @param  amount The target amount
    function unstake(address ntoken, uint256 amount) external;

    /// @dev Claim the reward the user earned
    /// @param ntoken The address of NToken
    /// @return The amount of ethers as rewards
    function claim(address ntoken) external returns (uint256);

    /// @dev Add ETH reward to the staking pool
    /// @param ntoken The address of NToken
    function addETHReward(address ntoken) external payable;

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    function pause() external;

    function resume() external;

    //function setParams(uint8 dividendShareRate) external;

    /* ========== EVENTS ========== */

    // Events
    event RewardAdded(address ntoken, address sender, uint256 reward);
    event NTokenStaked(address ntoken, address indexed user, uint256 amount);
    event NTokenUnstaked(address ntoken, address indexed user, uint256 amount);
    event SavingWithdrawn(address ntoken, address indexed to, uint256 amount);
    event RewardClaimed(address ntoken, address indexed user, uint256 reward);

    event FlagSet(address gov, uint256 flag);
}"
    },
    "contracts/iface/INNRewardPool.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

/// @title NNRewardPool
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

interface INNRewardPool {
    
    /* [DEPRECATED]
        uint256 constant DEV_REWARD_PERCENTAGE   = 5;
        uint256 constant NN_REWARD_PERCENTAGE    = 15;
        uint256 constant MINER_REWARD_PERCENTAGE = 80;
    */

    /// @notice Add rewards for Nest-Nodes, only governance or NestMining (contract) are allowed
    /// @dev  The rewards need to pull from NestPool
    /// @param _amount The amount of Nest token as the rewards to each nest-node
    function addNNReward(uint256 _amount) external;

    /// @notice Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() external ;  

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) external;

    /// @notice Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() external view returns (uint256 reward);

    /// @dev Only for governance
    function loadContracts() external; 

    /// @dev Only for governance
    function loadGovernance() external; 

    /* ========== EVENTS ============== */

    /// @notice When rewards are added to the pool
    /// @param reward The amount of Nest Token
    /// @param allRewards The snapshot of all rewards accumulated
    event NNRewardAdded(uint256 reward, uint256 allRewards);

    /// @notice When rewards are claimed by nodes 
    /// @param nnode The address of the nest node
    /// @param share The amount of Nest Token claimed by the nest node
    event NNRewardClaimed(address nnode, uint256 share);

    /// @notice When flag of state is set by governance 
    /// @param gov The address of the governance
    /// @param flag The value of the new flag
    event FlagSet(address gov, uint256 flag);
}"
    },
    "contracts/iface/INTokenController.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface INTokenController {

    /// @dev A struct for an ntoken
    ///     size: 2 x 256bit
    struct NTokenTag {
        address owner;          // the owner with the highest bid
        uint128 nestFee;        // NEST amount staked for opening a NToken
        uint64  startTime;      // the start time of service
        uint8   state;          // =0: normal | =1 disabled
        uint56  _reserved;      // padding space
    }

    function open(address token) external;
    
    function NTokenTagOf(address token) external view returns (NTokenTag memory);

    /// @dev Only for governance
    function loadContracts() external; 

    function loadGovernance() external;

    function setParams(uint256 _openFeeNestAmount) external;

    event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);

    event FlagSet(address gov, uint256 flag);

}
"
    },
    "contracts/lib/Address.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}"
    }
  },
  "settings": {
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
    },
    "libraries": {}
  }
}}