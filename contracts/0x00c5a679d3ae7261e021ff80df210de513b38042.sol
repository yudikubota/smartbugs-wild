{"Context.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
"},"SmartAdToken.sol":{"content":"// contracts/SmartAdToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SMARTERC20.sol";
import "./SmartSafeMath.sol";
contract SmartAdToken is SMARTERC20 {
    address public _owner;
    mapping (address => uint256) private _fees;
    using SmartSafeMath for uint256;
    event SmartTransfer(address indexed _from, address _to);
    event SmartWithdraw(address indexed _to, uint256 _amount);
    constructor() public payable SMARTERC20() {
        _owner = msg.sender;
    }
    modifier onlyOwner () {
       require(msg.sender == _owner, "This can only be called by the contract owner!");
       _;
    }
    function smartTransfer(address payable recipient) payable public {
        require(msg.value > 0, 'Error, message value cannot be 0');
        require(msg.sender != address(this));
        uint256 amount = msg.value;
        uint256 fee = calculateFee(amount, recipient);
        uint256 amountToSend = amount.sub(fee);
        require(amountToSend < amount, 'Error, amount to send should be less than original value');
        recipient.transfer(amountToSend);
        emit SmartTransfer(msg.sender, recipient);
    }
    function smartTokenTransfer(SMARTERC20 token, address payable recipient, uint256 amount) public {
        require(amount > 0, 'Error, amount cannot be 0');
        require(msg.sender != address(this));
        uint256 fee = calculateFee(amount, recipient);
        uint256 amountToSend = amount.sub(fee);
        require(amountToSend < amount, 'Error, amount to send should be less than original value');
        token.transferFrom(msg.sender, address(this), fee);
        token.transferFrom(msg.sender, recipient, amountToSend);
        emit SmartTransfer(msg.sender, recipient);
    }
    function calculateFee(uint256 amount, address recipient) internal view returns(uint256 _fee) {
        uint256 fee = amount.div(100);
        if( _fees[recipient] > 1 ) {
            fee = fee.mul(_fees[recipient]);
        }
        return fee;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function withdraw(uint256 amount) onlyOwner public {
        require(amount <= address(this).balance, 'Insufficience funds to withdraw that amount');
        address payable sendTo = payable(msg.sender);
        sendTo.transfer(amount);
        emit SmartWithdraw(msg.sender, amount);
    }
    function withdrawToken(SMARTERC20 token, uint256 amount) onlyOwner public {
        require(amount <= token.balanceOf(address(this)), 'Insufficience funds to withdraw that amount');
        address payable sendTo = payable(msg.sender);
        token.transfer(sendTo, amount);
        emit SmartWithdraw(msg.sender, amount);
    }
    function setFee(uint256 fee, address recipient) onlyOwner public {
        require(fee < 100, 'Cannot set fee to more than 99');
        _fees[recipient] = fee;
    }
}
"},"SMARTERC20.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SMARTIERC20.sol";
import "./Context.sol";
contract SMARTERC20 is Context, SMARTIERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor () {}
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
"},"SMARTIERC20.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface SMARTIERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"SmartSafeMath.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library SmartSafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}
"}}