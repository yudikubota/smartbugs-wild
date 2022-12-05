{"IERC20.sol":{"content":"pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}"},"IERC721.sol":{"content":"pragma solidity ^0.6.0;

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}"},"IERC721Receiver.sol":{"content":"pragma solidity ^0.6.0;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}"},"IMVDProxy.sol":{"content":"pragma solidity ^0.6.0;

interface IMVDProxy {

    function init(address votingTokenAddress, address functionalityProposalManagerAddress, address stateHolderAddress, address functionalityModelsManagerAddress, address functionalitiesManagerAddress, address walletAddress) external;

    function getDelegates() external view returns(address,address,address,address,address,address);
    function getToken() external view returns(address);
    function getMVDFunctionalityProposalManagerAddress() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function getMVDFunctionalityModelsManagerAddress() external view returns(address);
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns(address);
    function setDelegate(uint256 position, address newAddress) external returns(address oldAddress);
    function changeProxy(address newAddress, bytes calldata initPayload) external;
    function isValidProposal(address proposal) external view returns (bool);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
    function newProposal(string calldata codeName, bool emergency, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string calldata methodSignature, string calldata returnParametersJSONArray, bool isInternal, bool needsSender, string calldata replaces) external returns(address proposalAddress);
    function startProposal(address proposalAddress) external;
    function disableProposal(address proposalAddress) external;
    function transfer(address receiver, uint256 value, address token) external;
    function transfer721(address receiver, uint256 tokenId, bytes calldata data, bool safe, address token) external;
    function setProposal() external;
    function read(string calldata codeName, bytes calldata data) external view returns(bytes memory returnData);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
    function callFromManager(address location, bytes calldata payload) external returns(bool, bytes memory);
    function emitFromManager(string calldata codeName, address proposal, string calldata replaced, address replacedSourceLocation, uint256 replacedSourceLocationId, address location, bool submitable, string calldata methodSignature, bool isInternal, bool needsSender, address proposalAddress) external;

    function emitEvent(string calldata eventSignature, bytes calldata firstIndex, bytes calldata secondIndex, bytes calldata data) external;

    event ProxyChanged(address indexed newAddress);
    event DelegateChanged(uint256 position, address indexed oldAddress, address indexed newAddress);

    event Proposal(address proposal);
    event ProposalCheck(address indexed proposal);
    event ProposalSet(address indexed proposal, bool success);
    event FunctionalitySet(string codeName, address indexed proposal, string replaced, address replacedSourceLocation, uint256 replacedSourceLocationId, address indexed replacedLocation, bool replacedWasSubmitable, string replacedMethodSignature, bool replacedWasInternal, bool replacedNeededSender, address indexed replacedProposal);

    event Event(string indexed key, bytes32 indexed firstIndex, bytes32 indexed secondIndex, bytes data);
}"},"IMVDWallet.sol":{"content":"pragma solidity ^0.6.0;

interface IMVDWallet {

    function getProxy() external view returns (address);

    function setProxy() external;

    function setNewWallet(address payable newWallet, address tokenAddress) external;

    function transfer(address receiver, uint256 value, address tokenAddress) external;
    
    function transfer(address receiver, uint256 tokenId, bytes calldata data, bool safe, address token) external;

    function flushToNewWallet(address token) external;

    function flush721ToNewWallet(uint256 tokenId, bytes calldata data, bool safe, address tokenAddress) external;
}"},"MVDWallet.sol":{"content":"pragma solidity ^0.6.0;

import "./IMVDWallet.sol";
import "./IMVDProxy.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract MVDWallet is IMVDWallet, IERC721Receiver {

    address private _proxy;
    address payable private _newWallet;

    function setNewWallet(address payable newWallet, address tokenAddress) public override {
        require(msg.sender == _proxy, "Unauthorized Access!");
        _newWallet = newWallet;
        _newWallet.transfer(address(this).balance);
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_newWallet, token.balanceOf(address(this)));
    }

    function flushToNewWallet(address tokenAddress) public override {
        require(_newWallet != address(0), "Unauthorized Access!");
        if(tokenAddress == address(0)) {
            payable(_newWallet).transfer(address(this).balance);
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_newWallet, token.balanceOf(address(this)));
    }

    function flush721ToNewWallet(uint256 tokenId, bytes memory data, bool safe, address tokenAddress) public override {
        require(_newWallet != address(0), "Unauthorized Access!");
        _transfer(_newWallet, tokenId, data, safe, tokenAddress);
    }

    function transfer(address receiver, uint256 value, address token) public override {
        require(msg.sender == _proxy, "Unauthorized Access!");
        if(value == 0) {
            return;
        }
        if(token == address(0)) {
            payable(receiver).transfer(value);
            return;
        }
        IERC20(token).transfer(receiver, value);
    }

    function transfer(address receiver, uint256 tokenId, bytes memory data, bool safe, address token) public override {
        require(msg.sender == _proxy, "Unauthorized Access!");
        _transfer(receiver, tokenId, data, safe, token);
    }

    function _transfer(address receiver, uint256 tokenId, bytes memory data, bool safe, address token) private {
        if(safe) {
            IERC721(token).safeTransferFrom(address(this), receiver, tokenId, data);
        } else {
            IERC721(token).transferFrom(address(this), receiver, tokenId);
        }
    }

    receive() external payable {
        if(_newWallet != address(0)) {
            _newWallet.transfer(address(this).balance);
        }
    }

    function getProxy() public override view returns(address) {
        return _proxy;
    }

    function setProxy() public override {
        require(_proxy == address(0) || _proxy == msg.sender, _proxy != address(0) ? "Proxy already set!" : "Only Proxy can toggle itself!");
        _proxy = _proxy == address(0) ?  msg.sender : address(0);
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory data) public override returns (bytes4) {
        if(_newWallet != address(0)) {
            _transfer(_newWallet, tokenId, data, true, msg.sender);
        }
        return 0x150b7a02;
    }
}"}}