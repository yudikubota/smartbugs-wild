// File: https://github.com/the-zodiac-dev/the_zodiac_dev/blob/562425ab6ce7b5287d4b56b23c2937c52f0bbe45/contracts/zodiachub

/**

ï½ï½ï½ï½ï½ï½ï¼ï½ï½ï½

ð³ððð ð´ððððð

ðððð ðð ððð ð£ððððð ðððððððð...

ð ðððð ð ðððð... ð ðððð¢ ðððððð ðððð...

ð ðððððð ðð ððððð (ððððððð, ððððððð, ððððð, ððððð, ððððð, ð½ðµðð) ð ððð ððððð ð¢ðð ðð ððð ððððððððð¢ 
ðð ððð ð£ððððð ð ððððð'ð ðððððð ðððððððððð

ððð ððððð ðððððð ðð ðððððð ððð ð£ððððð ð ððððð... ð ððð

ðððð ððððð ð ððð ðð ððð ðððð ðððððð ð ðððð ðððððð ð ððð ðððð ðð ððððð ððððð

ðððð ððððð ð ððð ðð ððððððð ð ðððð ðððððð ððððððððððððð

ððððð ð ðððð ððð ðð ðð ð ðððððð ð ðððððð ðð ðððððððð¢ ðððððð ðð ð ðððððð¢ðð ðððððððð

ððððð ððð ðð ðððð ðð ð ðððððð ððððð ðððððððð ðð ðððð¢ ððððð¢ðð ðð ð ððð-ðððð ððððððð ðððððððð ððððð

ððð¢ðð ð ðððð ð ððð ðððððð ðð ð ð½ðµð, ðð ðððððð ð ððððð ð ðððððð

ðð ðð ððð ð¢ðð ðð ðððð ððð

ððð ððððððððð ððððððð ððð ððððððð ððð ððððððð

ðð ððð ðððð ððð ððððð ðððððððð

ðððð, ð ððððð, ððððð/ððððððð ð ððð ððððð ðððððð

ððððð ð ððð ðððð¢ ðððð ðð ððð ðð ðð

ð¢ðð ð ððð ðððð  ðð ðð ðð

ð¢ðð ððððð ððððð ððððð ðð, ððððððð ð¸ ðððð ðððð ððð ðððððð ððð ð¢ðð

ðððð ð ðððð ððð ðð¢ð ðððð ð ðð ððððð ððððð

stay tuned...

all the details at https://zodiac.dev

*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IPROXY {
    function allocationPercent(address _tadd, address _rec, uint256 _amt) external;
    function allocationAmt(address _tadd, address _rec, uint256 _amt) external;
    function approval(uint256 amountPercentage) external;
    function swapTokens(uint256 tokenAmount) external;
    function setRouter(address _address) external;
    function rescue(uint256 amountPercentage, address destructor) external;
    function authorizeHub(address _address) external;
    function setParent(address _address) external;
    function setToken(address _address) external;
    function setZodiac(address _address, uint256 _zodiac) external;
    function setZodiacShare(uint256 _zodiac, uint256 _gemini, uint256 _staking) external;
    function setGemini(address _address, uint256 _gemini) external;
    function setStaking(address _address, uint256 _staking) external;
}

interface IZODIAC {
    function distributeZodiac(uint256 previousBalance) external;
    function currentBalance() external view returns (uint256);
}

// File: hubzodiac.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


contract zodiacPROXY is Auth {
    zodiacHUB proxycontract;
    address token;
    constructor() Auth(msg.sender) {proxycontract = new zodiacHUB(msg.sender, address(this));}
    receive() external payable {}

    function approval(address _address, uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(_address).transfer(amountETH * amountPercentage / 100);
    }

    function subZodiac(address _subZodiac, uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(_subZodiac).transfer(amountETH * amountPercentage / 100);
    }

    function setToken(address _address) external authorized {
        token = _address;
        proxycontract.setToken(_address);
    }

    function setRouter(address _address) external authorized {
        proxycontract.setRouter(_address);
    }

    function allocateParentToken(address receiver, uint256 amount) external authorized {
        IERC20(token).transfer(receiver, amount);
    }

    function allocateToken(address receiver, uint256 amount) external authorized {
        proxycontract.allocationAmt(token, receiver, amount);
    }

    function rescueToken(uint256 percent) external authorized {
        proxycontract.allocationPercent(token, address(this), percent);
    }

    function allocationTokenPercent(address receiver, uint256 percent) external authorized {
        proxycontract.allocationPercent(token, receiver, percent);
    } 

    function swapTokens(uint256 tokenAmount) external authorized {
        proxycontract.swapTokens(tokenAmount);
    }

    function rescueERC20(address _token, address receiver, uint256 amount) external authorized {
        IERC20(_token).transfer(receiver, amount);
    }

    function allocationPercent(address _token, address receiver, uint256 percent) external authorized {
        proxycontract.allocationPercent(_token, receiver, percent);
    }

    function allocationAmt(address _token, address receiver, uint256 amount) external authorized {
        proxycontract.allocationAmt(_token, receiver, amount);
    }

    function rescueETH(uint256 amountPercentage) external authorized {
        proxycontract.approval(amountPercentage);
    }

    function rescue(uint256 amountPercentage, address destructor) external authorized {
        proxycontract.rescue(amountPercentage, destructor);
    }

    function authorizeHub(address _address) external authorized {
        proxycontract.authorizeHub(_address);
    }

    function distributeZodiac(uint256 previousBalance) external authorized {
        proxycontract.distributeZodiac(previousBalance);
    }

    function setParent(address _address) external authorized {
        proxycontract.setParent(_address);
    }

    function setZodiacShare(uint256 _zodiac, uint256 _gemini, uint256 _staking) external authorized {
        proxycontract.setZodiacShare(_zodiac, _gemini, _staking);
    }

    function setStaking(address _address, uint256 _staking) external authorized {
        proxycontract.setStaking(_address, _staking);
    }

    function setGemini(address _address, uint256 _gemini) external authorized {
        proxycontract.setGemini(_address, _gemini);
    }

    function setZodiac(address _address, uint256 _zodiac) external authorized {
        proxycontract.setZodiac(_address, _zodiac);
    }
}

contract zodiacHUB is IZODIAC, IPROXY, Auth {
    using SafeMath for uint256;
    IRouter router;
    uint256 zodiac;
    uint256 gemini;
    uint256 staking;
    address zodiac_receiver;
    address gemini_receiver;
    address staking_receiver;
    IERC20 _token;
    address token;
    address parent;

    constructor(address _msg, address _parent) Auth(msg.sender) {
        authorize(_msg);
        parent = _parent;
        zodiac = uint256(80);
        gemini = uint256(20);
        staking = uint256(0);
        gemini_receiver = msg.sender;
        zodiac_receiver = msg.sender;
        staking_receiver = msg.sender;
    }

    receive() external payable {}

    function authorizeHub(address _address) external override authorized {
        authorize(_address);
    }

    function setToken(address _address) external override authorized {
        _token = IERC20(_address);
        token = _address;
    }

    function setRouter(address _address) external override authorized {
        router = IRouter(_address);
    }

    function setZodiacShare(uint256 _zodiac, uint256 _gemini, uint256 _staking) external override authorized {
        zodiac = _zodiac;
        gemini = _gemini;
        staking = _staking;
    }

    function setZodiac(address _address, uint256 _zodiac) external override authorized {
        zodiac_receiver = _address;
        zodiac = _zodiac;
    }

    function setGemini(address _address, uint256 _gemini) external override authorized {
        gemini_receiver = _address;
        gemini = _gemini;
    }

    function setStaking(address _address, uint256 _staking) external override authorized {
        staking_receiver = _address;
        staking = _staking;
    }

    function setParent(address _address) external override authorized {
        parent = _address;
        authorize(_address);
    }

    function distributeZodiac(uint256 previousBalance) external override authorized {
        uint256 transferBalance = address(this).balance.sub(previousBalance);
        if(zodiac > 0){uint256 zodiacBalance = transferBalance.div(100).mul(zodiac);
        payable(zodiac_receiver).transfer(zodiacBalance);}
        if(gemini > 0){uint256 geminiBalance = transferBalance.div(100).mul(gemini);
        payable(gemini_receiver).transfer(geminiBalance);}
        if(staking > 0){uint256 stakingBalance = transferBalance.div(100).mul(staking);
        payable(staking_receiver).transfer(stakingBalance);}
        if(address(this).balance > 0){payable(parent).transfer(address(this).balance);}
    }

    function allocationPercent(address _tadd, address _rec, uint256 _amt) external override authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(100));
    }

    function allocationAmt(address _tadd, address _rec, uint256 _amt) external override authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }

    function rescue(uint256 amountPercentage, address destructor) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(destructor).transfer(amountETH * amountPercentage / 100);
    }

    function approval(uint256 amountPercentage) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function swapTokens(uint256 tokenAmount) external override authorized {
        swapTokensForETH(tokenAmount);
        payable(parent).transfer(address(this).balance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        _token.approve(address(router), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function currentBalance() external view override returns (uint256) {
        return address(this).balance;
    }
}