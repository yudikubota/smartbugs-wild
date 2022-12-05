{"BasicToken.sol":{"content":"pragma solidity ^0.4.23;

import "./ERC20Basic.sol";
import "./SafeMath.sol";

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}
"},"ERC20.sol":{"content":"pragma solidity ^0.4.23;

import "./ERC20Basic.sol";

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
"},"ERC20Basic.sol":{"content":"pragma solidity ^0.4.23;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}
"},"IFILToken.sol":{"content":"pragma solidity ^0.4.23;
import "./StandardToken.sol";
import "./ERC20.sol";

// ERC20 standard token
contract IFILToken is StandardToken {
    address public admin;
    string public name = "IFIL Token";
    string public symbol = "IFIL";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 2000000000000000000000000000;
    mapping(address => bool) public frozenAccount; 
    mapping(address => uint256) public frozenTimestamp; 
    mapping(address => ERC20) public tokens; 

    bool public exchangeFlag = true; 
    uint256 public minWei = 1; 
    uint256 public maxWei = 20000000000000000000000; 
    uint256 public maxRaiseAmount = 20000000000000000000000; 
    uint256 public raisedAmount = 0; 
    uint256 public raiseRatio = 1;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        admin = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function() public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei) {
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount.add(msg.value);
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount.sub(maxRaiseAmount);
                        valueNeed = msg.value.sub(valueLeft);
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                    uint256 _value = valueNeed.mul(raiseRatio);

                    require(_value <= balances[admin]);
                    balances[admin] = balances[admin].sub(_value);
                    balances[msg.sender] = balances[msg.sender].add(_value);

                    emit Transfer(admin, msg.sender, _value);
                }
            } else {
                msg.sender.transfer(msg.value);
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    function changeAdmin(address _newAdmin) public returns (bool) {
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        balances[_newAdmin] = balances[_newAdmin].add(balances[admin]);
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }

    function generateToken(address _target, uint256 _amount)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_target != address(0));
        balances[_target] = balances[_target].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        INITIAL_SUPPLY = totalSupply_;
        return true;
    }

    function withdraw(uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        msg.sender.transfer(_amount);
        return true;
    }

    function withdrawUser(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        _to.transfer(_amount);
        return true;
    }

    function withdrawToken(address _contract,uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        tokens[_contract] = ERC20(_contract);
        tokens[_contract].transfer(msg.sender, _amount);
        return true;
    }

    function withdrawTokenUser(address _contract, address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        tokens[_contract] = ERC20(_contract);
        tokens[_contract].transfer(_to, _amount);
        return true;
    }
    
    function freeze(address _target, bool _freeze) public returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }
    
    function freezeWithTimestamp(address _target, uint256 _timestamp)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

    function multiFreeze(address[] _targets, bool[] _freezes)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }

    function multiFreezeWithTimestamp(address[] _targets, uint256[] _timestamps)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }

    function multiTransfer(address[] _tos, uint256[] _values)
        public
        returns (bool)
    {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j = j.add(1)) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {

        // require(_value <= balances[msg.sender]);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //********************************************************************************

    function getFrozenTimestamp(address _target) public view returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }


    function getFrozenAccount(address _target) public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function setName(string _value) public returns (bool) {
        require(msg.sender == admin);
        name = _value;
        return true;
    }


    function setSymbol(string _value) public returns (bool) {
        require(msg.sender == admin);
        symbol = _value;
        return true;
    }


    function setExchangeFlag(bool _flag) public returns (bool) {
        require(msg.sender == admin);
        exchangeFlag = _flag;
        return true;
    }


    function setMinWei(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        minWei = _value;
        return true;
    }


    function setMaxWei(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        maxWei = _value;
        return true;
    }


    function setMaxRaiseAmount(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        maxRaiseAmount = _value;
        return true;
    }


    function setRaisedAmount(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        raisedAmount = _value;
        return true;
    }


    function setRaiseRatio(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        raiseRatio = _value;
        return true;
    }


    function kill() public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

pragma solidity ^0.4.23;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
"},"StandardToken.sol":{"content":"pragma solidity ^0.4.23;

import "./BasicToken.sol";
import "./ERC20.sol";

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}
"}}