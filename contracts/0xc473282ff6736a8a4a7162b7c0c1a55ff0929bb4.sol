// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() private view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity ^0.6.6;

contract PullCollectorOperatorETH is Ownable 
{
    address[] private users; // ÑÐ¿Ð¸ÑÐ¾Ðº Ð²ÑÐµÑ ÑÐ·ÐµÑÐ¾Ð² ÐºÑÐ¾ Ð²Ð»Ð¾Ð¶Ð¸Ð»
    mapping(address => uint256) public balances; // Ð¼ÐµÐ¿ ÑÐ·ÐµÑÐ¾Ð² Ð¸ Ð¸Ñ Ð²Ð»Ð¾Ð¶ÐµÐ½Ð½ÑÑ Ð±Ð°Ð»Ð°Ð½ÑÐ¾Ð²
    address payable public distributor; //Ð°Ð´ÑÐµÑ  ÐºÐ¾ÑÐµÐ»ÑÐºÐ° ÑÐ°ÑÐ¿ÑÐµÐ´ÐµÐ»Ð¸ÑÐµÐ»Ñ
    address public admin;
    event NewInvestor(address investor);

    constructor() public {
        distributor = msg.sender;
        admin = msg.sender;
    }

    function set_admin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function set_new_distributor(address payable _distributor)
        public
        onlyOwner
    {
        // ÑÑÐ°Ð²Ð¸Ð¼ Ð½Ð¾Ð²Ð¾Ð³Ð¾ ÑÐ°ÑÐ¿ÑÐµÐ´ÐµÐ»Ð¸ÑÐµÐ»Ñ
        distributor = _distributor;
    }

    function get_users(uint256 _id) public view returns (address) {
        // Ð¿Ð¾Ð»ÑÑÐµÐ½Ð¸Ðµ ÑÐ·ÐµÑÐ° Ð¿Ð¾ ÐµÐ³Ð¾ Ð°Ð¹Ð´Ð¸
        return users[_id];
    }

    function get_count_users() public view returns (uint256) {
        // Ð¿Ð¾Ð»ÑÑÐµÐ½Ð¸Ðµ Ð¾Ð±ÑÐµÐ³Ð¾ ÐºÐ¾Ð»Ð¸ÑÐµÑÑÐ²Ð° Ð²Ð»Ð¾Ð¶Ð¸Ð²ÑÐ¸ÑÑÑ ÑÐ·ÐµÑÐ¾Ð² ÑÐµÑÐµÐ· ÐºÐ¾Ð½ÑÑÐ°ÐºÑ
        return users.length;
    }

    function get_en_balances(address _user) public view returns (uint256) {
        // Ð¿Ð¾Ð»ÑÑÐ¸ÑÑ ÑÐºÐ¾Ð»ÑÐºÐ¾ Ð²Ð»Ð¾Ð¶Ð¸Ð» ÑÐ·ÐµÑ Ð¿Ð¾ ÐµÐ³Ð¾ Ð°Ð´ÑÐµÑÑ
        return balances[_user];
    }

    function invest() external payable {
        // Ð¼ÐµÑÐ¾Ð´ Ð¸Ð½Ð²ÐµÑÑÐ¸ÑÐ¾Ð²Ð°Ð½Ð¸Ñ ÑÑÐµÐ´ÑÑÐ² Ð² ÑÐµÐºÑÑÐ¸Ð¹ ÐºÐ¾ÑÑÐ°ÐºÑ
        if (balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);
        }
        balances[msg.sender] += msg.value;
        users.push(msg.sender);
    }

    function transfer_native(uint256 _amount) public payable {
        //Ð¼ÐµÑÐ¾Ð´ Ð¾ÑÑÑÐ»ÐºÐ¸ Ð½Ð°ÑÐ¸Ð²ÐºÐ¸ Ð½Ð° ÐºÐ¾ÑÐµÐ»Ñ ÑÐ°ÑÐ¿ÑÐµÐ´ÐµÐ»Ð¸ÑÐµÐ»Ñ
        require(msg.sender == admin, "Sign adress not Admin");
        distributor.transfer(_amount);
    }
}