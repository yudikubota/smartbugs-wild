pragma solidity >=0.4.21 <0.7.0;

interface Usdt_ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract UsdtLottery {
    event WithdrawMember(uint indexed orderId, address indexed from, address to, uint amount);
    event WithdrawSystem(address indexed from, address indexed to, uint amount);

    address private owner; 
    //ç®¡çè´¦æ·
    address private adminAddr;
    //usdt-erc20åçº¦å°å
    address private usdtContractAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    string private privateKey = "hello";

    mapping(uint => uint) withdrawOrderMap;

    constructor(address _owner) public {
        owner = _owner;
    }

    function balanceOf() public view returns (uint) {
        return Usdt_ERC20(usdtContractAddr).balanceOf(address(this));
    }

    function getBytes(uint num) internal pure returns (bytes memory) {
        bytes memory numBytes = new bytes(32);
        assembly { mstore(add(numBytes, 32), num) }
        return numBytes;
    }
    
    function getBytes(string memory str) internal pure returns (bytes memory) {
        return bytes(str);
    }
    
    function getBytes(address addr) internal pure returns (bytes memory) {
        return abi.encodePacked(addr);
    }

    function copy(bytes memory src, bytes memory dest, uint from) internal pure returns (bytes memory) {
        for (uint idx=0; idx<src.length; idx++) {
            dest[from + idx] = src[idx];
        }
        return dest;
    }

    function transfer(uint flowId, address to, uint amount, bytes32 checkSum) public returns (bool) {
        require(to != address(0x0), "address error");
        //1ãèº«ä»½æ ¡éª
        require(msg.sender == adminAddr, "permission denied");
        //2ãé²æ­¢éå¤æäº¤
        require(withdrawOrderMap[flowId] == 0, "duplicate transaction");
        //3ãæ°æ®æ ¡éª
        //3ã1æµæ°´åå·   
        //æµæ°´åå·   
        bytes memory flowIdBytes = getBytes(flowId);
        //æ¶æ¬¾å°å  
        bytes memory toBytes = getBytes(to);
        //è½¬è´¦éé¢ 
        bytes memory amountBytes = getBytes(amount);
        //ç§é¥
        bytes memory privateKeyBytes = getBytes(privateKey);
        uint totalBytes = flowIdBytes.length + toBytes.length + amountBytes.length;
        bytes memory inputBytes = new bytes(totalBytes);
        inputBytes = copy(flowIdBytes, inputBytes, 0);
        inputBytes = copy(toBytes, inputBytes, flowIdBytes.length);
        inputBytes = copy(amountBytes, inputBytes, flowIdBytes.length + toBytes.length);
        inputBytes = copy(privateKeyBytes, inputBytes, flowIdBytes.length + toBytes.length + amountBytes.length);
        bytes32 tmpCheckSum = sha256(inputBytes);
        
        bool checkSuccess = true;
        for (uint idx=0; idx<32; idx++) {
            if (tmpCheckSum[idx] != checkSum[idx]) {
                checkSuccess = false;
            }
        }
        require(checkSuccess, "permission denied");

        Usdt_ERC20(usdtContractAddr).transfer(to, amount);
        emit WithdrawMember(flowId, msg.sender, to, amount);
        withdrawOrderMap[flowId] = flowId;
        return true;
    }

    function transfer(address to, uint amount) public returns (bool) {
        require(to != address(0x0), "address error");
        require(msg.sender == owner, "permission denied");
        Usdt_ERC20(usdtContractAddr).transfer(to, amount);
        emit WithdrawSystem(msg.sender, to, amount);
        return true;
    }

    function resetAdmin(address _adminAddr) public returns (bool) {
        require(msg.sender == owner, "permission denied");
        adminAddr = _adminAddr;
    }

    function destroy() public {
        require(msg.sender == owner, "permission denied");
        uint balance = Usdt_ERC20(usdtContractAddr).balanceOf(address(this));
        Usdt_ERC20(usdtContractAddr).transfer(owner, balance);
        selfdestruct(msg.sender);
    }

    function () external payable {}
}