pragma solidity ^0.5.0;

/**
 * @dev EIPì ì ìë ERC20 íì¤ ì¸í°íì´ì¤ ì¶ê° í¨ìë¥¼ í¬í¨íì§ ììµëë¤;
 * ì´ë¤ì ì ê·¼íë ¤ë©´ `ERC20Detailed`ì íì¸íì¸ì.
 */
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

library SafeMath {
    /**
     * @dev ë ë¶í¸ ìë ì ìì í©ì ë°íí©ëë¤.
     * ì¤ë²íë¡ì° ë°ì ì ìì¸ì²ë¦¬í©ëë¤.
     *
     * ìë¦¬ëí°ì `+` ì°ì°ìë¥¼ ëì²´í©ëë¤.
     *
     * ìêµ¬ì¬í­:
     * - ë§ìì ì¤ë²íë¡ì°ë  ì ììµëë¤.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev ë ë¶í¸ ìë ì ìì ì°¨ë¥¼ ë°íí©ëë¤.
     * ê²°ê³¼ê° ììì¼ ê²½ì° ì¤ë²íë¡ì°ìëë¤.
     *
     * ìë¦¬ëí°ì `-` ì°ì°ìë¥¼ ëì²´í©ëë¤.
     *
     * ìêµ¬ì¬í­:
     * - ëºìì ì¤ë²íë¡ì°ë  ì ììµëë¤.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev ë ë¶í¸ ìë ì ìì ê³±ì ë°íí©ëë¤.
     * ì¤ë²íë¡ì° ë°ì ì ìì¸ì²ë¦¬í©ëë¤.
     *
     * ìë¦¬ëí°ì `*` ì°ì°ìë¥¼ ëì²´í©ëë¤.
     *
     * ìêµ¬ì¬í­:
     * - ê³±ìì ì¤ë²íë¡ì°ë  ì ììµëë¤.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // ê°ì¤ ìµì í: ì´ë 'a'ê° 0ì´ ìëì ìêµ¬íë ê²ë³´ë¤ ì ë ´íì§ë§,
        // 'b'ë íì¤í¸í  ê²½ì° ì´ì ì´ ìì´ì§ëë¤.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev ë ë¶í¸ ìë ì ìì ëª«ì ë°íí©ëë¤. 0ì¼ë¡ ëëê¸°ë¥¼ ìëí  ê²½ì°
     * ìì¸ì²ë¦¬í©ëë¤. ê²°ê³¼ë 0ì ìë¦¬ìì ë°ì¬ë¦¼ë©ëë¤.
     *
     * ìë¦¬ëí°ì `/` ì°ì°ìë¥¼ ëì²´í©ëë¤. ì°¸ê³ : ì´ í¨ìë
     * `revert` ëªë ¹ì½ë(ìì¬ ê°ì¤ë¥¼ ê±´ë¤ì§ ìì)ë¥¼ ì¬ì©íë ë°ë©´, ìë¦¬ëí°ë
     * ì í¨íì§ ìì ëªë ¹ì½ëë¥¼ ì¬ì©í´ ë³µê·í©ëë¤(ë¨ì ëª¨ë  ê°ì¤ë¥¼ ìë¹).
     *
     * ìêµ¬ì¬í­:
     * - 0ì¼ë¡ ëë ì ììµëë¤.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // ìë¦¬ëí°ë 0ì¼ë¡ ëëê¸°ë¥¼ ìëì¼ë¡ ê²ì¶íê³  ì¤ë¨í©ëë¤.
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // ì´ë¥¼ ë§ì¡±ìí¤ì§ ìë ê²½ì°ê° ìì´ì¼ í©ëë¤.

        return c;
    }

    /**
     * @dev ë ë¶í¸ ìë ì ìì ëë¨¸ì§ë¥¼ ë°íí©ëë¤. (ë¶í¸ ìë ì ì ëª¨ëë¡ ì°ì°),
     * 0ì¼ë¡ ëë ê²½ì° ìì¸ì²ë¦¬í©ëë¤.
     *
     * ìë¦¬ëí°ì `%` ì°ì°ìë¥¼ ëì²´í©ëë¤. ì´ í¨ìë `revert`
     * ëªë ¹ì½ë(ìì¬ ê°ì¤ë¥¼ ê±´ë¤ì§ ìì)ë¥¼ ì¬ì©íë ë°ë©´, ìë¦¬ëí°ë
     * ì í¨íì§ ìì ëªë ¹ì½ëë¥¼ ì¬ì©í´ ë³µê·í©ëë¤(ë¨ì ëª¨ë  ê°ì¤ë¥¼ ìë¹).
     *
     * ìêµ¬ì¬í­:
     * - 0ì¼ë¡ ëë ì ììµëë¤.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev `IERC20` ì¸í°íì´ì¤ì êµ¬í
 *
 * ì´ êµ¬íì í í°ì´ ìì±ëë ë°©ìê³¼ ë¬´ê´í©ëë¤. ì´ë
 * íì ì»¨í¸ëí¸ì `_mint`ë¥¼ ì´ì©í ê³µê¸ ë©ì»¤ëì¦ì´ ì¶ê°ëì´ì¼ íë¤ë ìë¯¸ìëë¤.
 * ì¼ë°ì ì¸ ë©ì»¤ëì¦ì `ERC20Mintable`ì ì°¸ì¡°íì¸ì.
 *
 * *ìì¸í ë´ì©ì ê°ì´ë [How to implement supply mechanisms]
 * (https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226)ë¥¼ ì°¸ê³ íì¸ì.*
 *
 * ì¼ë°ì ì¸ OpenZeppelin ì§ì¹¨ì ë°ëìµëë¤: í¨ìë ì¤í¨ì `false`ë¥¼ ë°ííë ëì 
 * ìì¸ì²ë¦¬ë¥¼ ë°ë¦ëë¤. ê·¸ë¼ìë ì´ë ê´ìµì ì´ë©°
 * ERC20 ì íë¦¬ì¼ì´ìì ê¸°ëì ë°íì§ ììµëë¤.
 *
 * ëí, `transferFrom` í¸ì¶ ì `Approval` ì´ë²¤í¸ê° ë°ìë©ëë¤.
 * ì´ë¡ë¶í° ì íë¦¬ì¼ì´ìì í´ë¹ ì´ë²¤í¸ë¥¼ ìì íë ê²ë§ì¼ë¡
 * ëª¨ë  ê³ì ì ëí íì©ë(allowance)ì ì¬êµ¬ì± í  ì ììµëë¤. ì´ë ì¤íìì ìêµ¬ëì§ ìì¼ë¯ë¡, EIPì ëí ë¤ë¥¸ êµ¬íì²´ë
 * ì´ë¬í ì´ë²¤í¸ë¥¼ ë°ìíì§ ìì ì ììµëë¤.
 *
 * ë§ì§ë§ì¼ë¡, íì¤ì´ ìë `decreaseAllowance` ë° `increaseAllowance`
 * í¨ìê° ì¶ê°ëì´ íì©ë ì¤ì ê³¼ ê´ë ¨í´ ì ìë ¤ì§ ë¬¸ì ë¥¼
 * ìííìµëë¤. `IERC20.approve`ë¥¼ ì°¸ì¡°íì¸ì.
 */
contract SigridToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    // https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/token/ERC20/ERC20Detailed.sol ìì ë¶ë¶ì ì°¸ê³ 
    string public constant _name = "Sigrid Jin?";
    string public constant _symbol = "SIGJ?";
    uint8 public constant _decimals = 18;

    constructor() public {
        _mint(msg.sender, 180 * 10 ** uint(_decimals)); // ì£¼ì!
    }

    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev ì£¼ë¡ ì´ë¦ì ì¤ì¬ì ííí í í° ì¬ë³¼ì
     * ë°íí©ëë¤.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev ì¬ì©ì ííì ìí ìì ìë¦¿ìë¥¼ ë°íí©ëë¤.
     * ìë¥¼ ë¤ì´, `decimals`ì´  `2`ì¸ ê²½ì°, 505` í í°ì
     * ì¬ì©ììê² `5,05` (`505 / 10 ** 2`)ì ê°ì´ íìëì´ì¼ í©ëë¤.
     *
     * í í°ì ë³´íµ 18ì ê°ì ì·¨íë©°, ì´ë Etherì Weiì ê´ê³ë¥¼
     * ëª¨ë°©í ê²ìëë¤.
     *
     * > ì´ ì ë³´ë ëì¤íë ì´ ëª©ì ì¼ë¡ë§ ì¬ì©ë©ëë¤.
     * `IERC20.balanceOf`ì `IERC20.transfer`ë¥¼ í¬í¨í´
     * ì»¨í¸ëí¸ì ì°ì  ì°ì°ì ì´ë í ìí¥ì ì£¼ì§ ììµëë¤.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    // https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.3.0/contracts/token/ERC20/ERC20Detailed.sol ë ë¶ë¶ì ì°¸ê³ 

    uint256 private _totalSupply;

    /**
     * @dev `IERC20.totalSupply`ë¥¼ ì°¸ì¡°íì¸ì.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev `IERC20.balanceOf`ë¥¼ ì°¸ì¡°íì¸ì.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev `IERC20.transfer`ë¥¼ ì°¸ì¡°íì¸ì.
     *
     * ìêµ¬ì¬í­ :
     *
     * - `recipient`ë ì ì£¼ì(0x0000...0)ê° ë  ì ììµëë¤.
     * - í¸ì¶ìì ìê³ ë ì ì´ë `amount` ì´ìì´ì´ì¼ í©ëë¤.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev `IERC20.allowance`ë¥¼ ì°¸ì¡°íì¸ì.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev `IERC20.approve`ë¥¼ ì°¸ì¡°íì¸ì.
     *
     * ìêµ¬ì¬í­:
     *
     * - `spender`ë ì ì£¼ìê° ë  ì ììµëë¤.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev `IERC20.transferFrom`ë¥¼ ì°¸ì¡°íì¸ì.
     *
     * ìë°ì´í¸ë íì©ëì ëíë´ë `Approval` ì´ë²¤í¸ê° ë°ìí©ëë¤. ì´ê²ì EIPìì
     * ìêµ¬ëë ë°ê° ìëëë¤. `ERC20`ì ìì ë¶ë¶ì ìë ì°¸ê³  ì¬í­ì ì°¸ì¡°íì¸ì.
     *
     * ìêµ¬ì¬í­:
     * - `sender`ì `recipient`ë ì ì£¼ìê° ë  ì ììµëë¤.
     * - `sender`ì ìê³ ë ì ì´ë `value` ì´ìì´ì´ì¼ í©ëë¤.
     * - í¸ì¶ìë `sender`ì í í°ì ëí´ ìµìí `amount` ë§í¼ì íì©ëì
     * ê°ì ¸ì¼ í©ëë¤.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev í¸ì¶ìì ìí´ ììì (atomically)ì¼ë¡ `spender`ì ì¹ì¸ë íì©ëì ì¦ê°ìíµëë¤.
     *
     * ì´ê²ì `IERC20.approve`ì ê¸°ì ë ë¬¸ì ì ëí ìíì±ì¼ë¡ ì¬ì©ë  ì ìë
     * `approve`ì ëììëë¤.
     *
     * ìë°ì´í¸ë íì©ëì ëíë´ë `Approval` ì´ë²¤í¸ê° ë°ìí©ëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `spender`ë ì ì£¼ìê° ë  ì ììµëë¤.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev í¸ì¶ìì ìí´ ììì ì¼ë¡ `spender`ì ì¹ì¸ë íì©ëì ê°ììíµëë¤.
     *
     * ì´ê²ì `IERC20.approve`ì ê¸°ì ë ë¬¸ì ì ëí ìíì±ì¼ë¡ ì¬ì©ë  ì ìë
     * `approve`ì ëììëë¤.
     *
     * ìë°ì´í¸ë íì©ëì ëíë´ë `Approval` ì´ë²¤í¸ê° ë°ìí©ëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `spender`ë ì ì£¼ìê° ë  ì ììµëë¤.
     * - `spender`ë í¸ì¶ìì ëí´ ìµìí `subtractedValue` ë§í¼ì íì©ëì
     * ê°ì ¸ì¼ í©ëë¤.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev `amount`ë§í¼ì í í°ì `sender`ìì `recipient`ë¡ ì®ê¹ëë¤.
     *
     * ì´ë `transfer`ì ëì¼í ë´ë¶ì(internal) í¨ìì´ë©°, ìë í í° ììë£,
     * ì°¨ê° ë©ì»¤ëì¦ ë±ì êµ¬íì ì¬ì© ê°ë¥í©ëë¤.
     *
     * `Transfer` ì´ë²¤í¸ë¥¼ ë°ììíµëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `sender`ë ì ì£¼ìê° ë  ì ììµëë¤.
     * - `recipient`ì ì ì£¼ìê° ë  ì ììµëë¤.
     * - `sender`ì ìê³ ë ì ì´ë `amount` ì´ìì´ì´ì¼ í©ëë¤.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev `amount`ë§í¼ì í í°ì ìì±íê³  `account`ì í ë¹í©ëë¤.
     * ì ì²´ ê³µê¸ëì ì¦ê°ìíµëë¤.
     *
     * `from`ì´ ì ì£¼ìë¡ ì¤ì ë `Transfer` ì´ë²¤í¸ë¥¼ ë°ììíµëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `to`ë ì ì£¼ìê° ë  ì ììµëë¤.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev `account`ë¡ë¶í° `amount`ë§í¼ì í í°ì íê´´íê³ ,
     * ì ì²´ ê³µê¸ëì ê°ììíµëë¤.
     *
     * `to`ê° ì ì£¼ìë¡ ì¤ì ë `Transfer` ì´ë²¤í¸ë¥¼ ë°ììíµëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `account`ë ì ì£¼ìê° ë  ì ììµëë¤.
     * - `account`ë ì ì´ë `amount`ë§í¼ì í í°ì´ ìì´ì¼ í©ëë¤.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

    _balances[account] = _balances[account].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev `owner`ì í í°ì ëí `spender`ì íì©ëì `amount`ë§í¼ ì¤ì í©ëë¤.
     *
     * ì´ë `approve`ì ëì¼í ë´ë¶ì(internal) í¨ìì´ë©°, í¹ì  íì ìì¤íì ëí
     * ìë íì©ë ì¤ì  ë±ì êµ¬íì ì¬ì© ê°ë¥í©ëë¤.
     *
     * `Approval` ì´ë²¤í¸ë¥¼ ë°ììíµëë¤.
     *
     * ìêµ¬ì¬í­:
     *
     * - `owner`ë ì ì£¼ìê° ë  ì ììµëë¤.
     * - `spender`ë ì ì£¼ìê° ë  ì ììµëë¤.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev `account`ë¡ë¶í° `amount`ë§í¼ì í í°ì íê´´íê³ ,
     * í¸ì¶ìì íì©ëì¼ë¡ë¶í° `amount`ë§í¼ì ê³µì í©ëë¤.
     *
     * `_burn` ë° `_approve`ë¥¼ ì°¸ì¡°íì¸ì.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}