// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BridgeAdmin {

    address public admin;

    struct Token {
        bool isRun; // æ¯å¦è¿è¡
        bool isMain; // æ¯å¦ä¸»é¾
        address local; // æ¬é¾å°å
    }

    // tokens[toChainId][toToken] = localPairInfo
    mapping(uint => mapping(address => Token)) public tokens;

    // natives[toChainId][isMain] = localPairInfo
    mapping(uint => mapping(bool => Token)) public natives;

    event adminChanged(address _address);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Bridge Admin: only use admin to call");
        _;
    }

    function setAdmin(address payable newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    // ä»£å¸æ¯å¦æ¯æè·¨é¾
    function tokenCanBridge(uint toChainId, address toToken) view internal returns (bool){
        return tokens[toChainId][toToken].isRun;
    }


    // ä¾§é¾,ä¾§é¾ä»£å¸,æ¬é¾ä»£å¸,æ¯å¦è¿è¡,æ¬é¾æ¯å¦ä¸»é¾
    function tokenInsert(uint toChainId, address toToken, address fromToken, bool isRun, bool isMain) external onlyAdmin {
        tokens[toChainId][toToken] = Token({
        isRun : isRun,
        isMain : isMain,
        local : fromToken
        });
    }

    // æ·»å æ¯æçä¸»ç½å¸
    function nativeInsert(uint toChainId, address fromAddress,bool isRun) external onlyAdmin {
        bool isMain = false;
        if(fromAddress == address(0)){
            isMain = true;
        }
        natives[toChainId][isMain] = Token({
        isMain : isMain,
        isRun : isRun,
        local : fromAddress
        });
    }

    function switchTokenMain(uint toChainId, address toToken) external onlyAdmin returns (bool){
        Token storage pair = tokens[toChainId][toToken];
        require(pair.local != address(0),"Bridge Admin: pair is not exist");
        bool isMain = pair.isMain? false : true;
        tokens[toChainId][toToken] = Token({
        isRun : pair.isRun,
        isMain : isMain,
        local : pair.local
        });
        return true;
    }

    // è®¾ç½®ä»£å¸ç¶æ
    function setTokenIsRun(uint toChainId, address toToken, bool state) public {
        require(
            msg.sender == admin,
            "Bridge Admin: no operation permission"
        );

        tokens[toChainId][toToken].isRun = state;
    }

    // è®¾ç½®ä¸»ç½å¸ç¶æ
    function setNativeIsRun(uint toChainId, bool isMain, bool state) public {
        require(
            msg.sender == admin,
            "Bridge Admin: no operation permission"
        );

        natives[toChainId][isMain].isRun = state;
    }


    // èµäº§è½¬è´¦
    function tokenTransfer(address fromToken, address recipient, uint256 value) public onlyAdmin {
        IERC20 token = IERC20(fromToken);
        token.transfer(recipient, value);
    }

    // ä¸»ç½å¸è½¬è´¦
    function nativeTransfer(address payable recipient, uint256 value) public onlyAdmin {
        require(address(this).balance > value, "Bridge Admin: not enough native token");
        recipient.transfer(value);
    }
}

contract Bridge is BridgeAdmin {

    address public owner;

    address public manager;

    event Deposit(uint toChainId, address fromToken, address toToken, address recipient, uint256 value);

    event DepositNative(uint toChainId, bool isMain, address recipient, uint256 value);

    event WithdrawDone(uint toChainId, address fromToken, address toToken, address recipient, uint256 value, bytes depositHash);

    event WithdrawNativeDone(uint fromChainId, address recipient, bool isMain, uint256 value, bytes depositHash);

    modifier onlyOwner {
        require(msg.sender == owner, "Bridge: only owner can call this function");
        _;
    }

    modifier onlyManager {
        require(manager != address(0), "Bridge: must set manager before call this function");
        require(msg.sender == manager, "Bridge: only manager can call this function");
        _;
    }

    modifier canBridge(uint chainId, address toToken) {
        require(tokenCanBridge(chainId, toToken), "Bridge: token is can not use bridge");
        _;
    }

    constructor(address _owner) {
        admin = _owner;
        owner = _owner;
    }

    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Bridge: manager must be a contract address");
        manager = _manager;
    }

    function setOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }


    function deposit(
        uint chainId,
        address toToken,
        uint256 value
    ) public canBridge(chainId, toToken) {
        Token storage local = tokens[chainId][toToken];
        IERC20 token = IERC20(local.local);
        if (local.isMain) {
            // ä¸»é¾
            token.transferFrom(msg.sender, address(this), value);
        } else {
            // ä¾§é¾ çç§
            token.burn(msg.sender, value);
        }
        emit Deposit(chainId, local.local, toToken, msg.sender, value);
    }

    function depositNative(uint toChainId, bool isMain, uint256 value) public payable {
        Token storage native = natives[toChainId][isMain];
        require(native.isRun, "Bridge: chain is not support");

        if (native.isMain) {
            // ä¸»é¾è·¨åº
            require(msg.value == value, "Bridge: value is wrong");
            require(msg.value > 0, "Bridge: value is 0");
        } else {
            // ä¾§é¾ çç§
            IERC20 token = IERC20(native.local);
            token.burn(msg.sender, value);
        }
        emit DepositNative(toChainId, isMain, msg.sender, value);
    }

    function withdraw(uint toChainId, address toToken, address recipient, uint256 value, bytes memory depositHash) public onlyManager {
        Token storage local = tokens[toChainId][toToken];
        IERC20 token = IERC20(local.local);
        if (local.isMain) {
            // ä¸»é¾ è½¬è´¦
            token.transfer(recipient, value);
        } else {
            // ä¾§é¾ é¸å¸
            token.mint(recipient, value);
        }
        emit WithdrawDone(toChainId, local.local, toToken, recipient, value, depositHash);
    }


    function withdrawNative(uint toChainId, address payable recipient, bool isMain, uint256 value, bytes memory depositHash) public onlyManager {
        Token storage native = natives[toChainId][isMain];
        require(native.isRun, "Bridge: chain is not support");
        if (native.isMain) {
            // ä¸»é¾è·¨å¥
            require(address(this).balance > value, "Bridge: not enough native token");
            recipient.transfer(value);
        } else {
            // ä¾§é¾è·¨å¥
            IERC20 token = IERC20(native.local);
            token.mint(recipient, value);
        }
        emit WithdrawNativeDone(toChainId, recipient, isMain, value, depositHash);
    }

    receive() external payable {}
}