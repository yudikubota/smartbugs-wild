{"ERC721.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
"},"ERC721URIStorage.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
"},"Finalizable.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./Owned.sol";

contract Finalizable is Owned {
    bool public running;

    event LogRunSwitch(address sender, bool switchSetting);

    modifier onlyIfRunning() {
        require(running, "Is not running.");
        _;
    }

    modifier onlyIfNotRunning() {
        require(!running, "Is still running.");
        _;
    }

    constructor() {
        running = true;
    }

    function runSwitch(bool onOff)
        external
        onlyOwner
        onlyIfRunning
        returns (bool success)
    {
        running = onOff;
        emit LogRunSwitch(msg.sender, onOff);
        return true;
    }
}
"},"Owned.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract Owned {
    address public owner;

    event LogActualOwner(address sender, address oldOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address newOwner)
        internal
        onlyOwner
        returns (bool success)
    {
        require(
            newOwner != address(0x0),
            "You are not the owner of the contract."
        );
        owner = newOwner;
        emit LogActualOwner(msg.sender, owner, newOwner);
        return true;
    }
}
"},"RaffleCashier.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./RaffleManager.sol";
import "./RaffleOperator.sol";

interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract RaffleCashier is Owned {
    IRouter public router;
    address public immutable WETH;
    address public immutable FMON;
    address public treasuryAddress;
    AggregatorV3Interface internal priceFeed;

    RaffleManager raffleManagerInstance;

    error Unauthorized();

    constructor(
        address _routerAddress,
        address _WETH,
        address _FMON
    ) {
        IRouter _router = IRouter(_routerAddress);
        router = _router;
        WETH = _WETH;
        FMON = _FMON;
        raffleManagerInstance = RaffleManager(msg.sender);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function getCurrentPriceOfTokenByETHInUSDC(address _tokenA, address _USDC)
        public
        view
        returns (uint256 _currentPriceOfTokenWithoutDecimalsInUSD)
    {
        // tokenA always the token which we want to know the price
        address _pair = IFactory(router.factory()).getPair(_tokenA, WETH);
        uint256 decimalsUSDC = IERC20(_USDC).decimals();
        uint256 decimalsToken0 = IERC20(IPair(_pair).token0()).decimals();
        uint256 decimalsToken1 = IERC20(IPair(_pair).token1()).decimals();
        (uint256 reserve0, uint256 reserve1, ) = IPair(_pair).getReserves();

        uint256 currentToken0PriceWithoutDecimals = (1 *
            10**decimalsToken0 *
            reserve1) / reserve0; // --> For 1 FMON is this ETH
        uint256 currentToken1PriceWithoutDecimals = (1 *
            10**decimalsToken1 *
            reserve0) / reserve1; // --> For 1 ETH is this FMON

        uint256 currentETHPrice = uint256(getETHLatestPrice());
        uint8 ETHPriceDecimals = getETHPriceDecimals();
        uint256 currentPriceETHInUSD = currentETHPrice / 10**ETHPriceDecimals;
        uint256 currentPriceETHInUSDWithoutDecimals = 1 *
            10**decimalsUSDC *
            currentPriceETHInUSD;

        // If token0 is ETH, token1 is FMON
        if (_tokenA == IPair(_pair).token0()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken0) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken1PriceWithoutDecimals;
        } else if (_tokenA == IPair(_pair).token1()) {
            _currentPriceOfTokenWithoutDecimalsInUSD =
                ((1 * 10**decimalsToken1) *
                    currentPriceETHInUSDWithoutDecimals) /
                currentToken0PriceWithoutDecimals;
        }
    }

    function addUSDCLiquidity(
        address _USDC,
        address _liquidityProvider,
        uint256 _liquidityToAdd
    ) external onlyOwner returns (bool _success) {
        TransferHelper.safeTransferFrom(
            _USDC,
            _liquidityProvider,
            address(this),
            _liquidityToAdd
        );
        return true;
    }

    function removeUSDCLiquidity(
        address _USDC,
        uint256 _liquidityToRemove,
        address _liquidityReceiver
    ) external onlyOwner returns (bool _removeLiquiditySuccess) {
        TransferHelper.safeTransfer(
            _USDC,
            _liquidityReceiver,
            _liquidityToRemove
        );
        return true;
    }

    function changeRouterToMakeSwap(address _newRouterAddress)
        external
        onlyOwner
        returns (bool _success)
    {
        IRouter _router = IRouter(_newRouterAddress);
        router = _router;
        return true;
    }

    function transferAmountToBuyTickets(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        uint256 _amountToBuyTickets
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        TransferHelper.safeTransferFrom(
            _USDC,
            _ticketsBuyer,
            _raffleOperator,
            _amountToBuyTickets
        );
        return true;
    }

    function transferAmountOfUSDFromLiquidityToBuyTickets(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        address _tokenToUseToBuyTickets,
        uint256 _amountToBuyTickets,
        uint256 _amountOfUSDCToBuyTickets
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        TransferHelper.safeTransferFrom(
            _tokenToUseToBuyTickets,
            _ticketsBuyer,
            address(this),
            _amountToBuyTickets
        );
        TransferHelper.safeTransfer(
            _USDC,
            _raffleOperator,
            _amountOfUSDCToBuyTickets
        );
        return true;
    }

    function swapTokenToUSDC(
        address _USDC,
        address _ticketsBuyer,
        address _raffleOperator,
        address _tokenToUseToBuyTickets,
        uint256 _amountToBuyTickets,
        uint256 _amountOfUSDCToReceive
    ) external returns (bool _swapSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        address[] memory path = new address[](2);
        path[0] = address(_tokenToUseToBuyTickets);
        path[1] = address(_USDC);

        TransferHelper.safeTransferFrom(
            _tokenToUseToBuyTickets,
            _ticketsBuyer,
            address(this),
            _amountToBuyTickets
        );

        router.swapTokensForExactTokens(
            _amountOfUSDCToReceive,
            _amountToBuyTickets,
            path,
            address(this),
            block.timestamp + 600
        );

        TransferHelper.safeTransfer(
            _USDC,
            _raffleOperator,
            _amountOfUSDCToReceive
        );
        return true;
    }

    function transferPrizeToWinner(
        address _raffleOperator,
        address _USDC,
        address _raffleWinnerPlayer,
        uint256 _prizeToDeliverToWinner
    ) external returns (bool _transferSuccess) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        uint256 currentPriceOfFMONByETHInUSDC = getCurrentPriceOfTokenByETHInUSDC(
                FMON,
                _USDC
            );
        uint256 decimalsFMON = IERC20(FMON).decimals();
        uint256 currentFMONBalanceOfCashier = IERC20(FMON).balanceOf(
            address(this)
        );

        uint256 prizeToDeliverToWinnerInFMON = ((_prizeToDeliverToWinner *
            (1 * 10**decimalsFMON)) / currentPriceOfFMONByETHInUSDC);
        TransferHelper.safeTransfer(
            FMON,
            _raffleWinnerPlayer,
            prizeToDeliverToWinnerInFMON
        );

        if (currentFMONBalanceOfCashier < prizeToDeliverToWinnerInFMON) {
            uint256 extraAmountToSend = prizeToDeliverToWinnerInFMON -
                currentFMONBalanceOfCashier;
            TransferHelper.safeTransferFrom(
                FMON,
                address(raffleManagerInstance.treasuryAddress()),
                _raffleWinnerPlayer,
                extraAmountToSend
            );
        }

        return true;
    }

    function approveRouterToSwapToken(address _tokenToApprove)
        external
        onlyOwner
        returns (bool _approvalSuccess)
    {
        uint256 tokenTotalSupply = IERC20(_tokenToApprove).totalSupply();
        IERC20(_tokenToApprove).approve(address(router), tokenTotalSupply);
        return true;
    }

    function getETHLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getETHPriceDecimals() public view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }
}
"},"RaffleManager.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity =0.8;

import "./Owned.sol";
import "./RaffleCashier.sol";
import "./RaffleOperator.sol";
import "./RaffleWinnerNumberGenerator.sol";

contract RaffleManager is Owned {
    address[] private adminUsers;
    address public raffleCashier;
    address public treasuryAddress;
    address public megaVaultAddress;
    address[] public rafflesAddresses;
    uint256 public currentRaffleId = 0;
    address public xPresidentsVaultAddress;
    uint16 private constant MAX_ADMINS = 10;
    address public raffleWinnerNumberGenerator;
    mapping(address => bool) public isAdminUser;
    uint256 private constant RAFFLE_IN_PROGRESS = 3200000;

    error TooManyAdminUsers();
    error OwnerCantBeRemoved();
    error AdminUsersCantBeEmpty();
    error AdminUserAlreadyAdded();
    error UserToRemoveIsNotAdmin();

    event AdminUserAdded(address indexed adminUserAddress);
    event AdminUserRemoved(address indexed adminUserAddress);
    event RaffleFinished(address indexed raffleOperatorContract);
    event RaffleRestarted(address indexed raffleOperatorContract);
    event RaffleCashierCreated(
        address indexed raffleCashierContract,
        bytes32 indexed raffleCashierSalt
    );
    event RaffleCreated(
        address indexed raffleOperatorContract,
        bytes32 indexed raffleSalt,
        uint256 currentRafflesLength
    );
    event RaffleWinnerNumberGeneratorCreated(
        address indexed raffleWinnerNumberGeneratorContract,
        bytes32 indexed raffleWinnerNumberGeneratorSalt
    );

    modifier onlyIfAdminUser() {
        require(isAdminUser[msg.sender] == true, "You are not authorized");
        _;
    }

    constructor(
        uint64 _subscriptionId,
        address _routerAddress,
        address _treasuryAddress,
        address _megaVaultAddress,
        address _xPresidentsVaultAddress,
        address _WETH,
        address _FMON
    ) {
        owner = msg.sender;
        adminUsers.push(msg.sender);
        isAdminUser[msg.sender] = true;
        treasuryAddress = _treasuryAddress;
        megaVaultAddress = _megaVaultAddress;
        xPresidentsVaultAddress = _xPresidentsVaultAddress;

        raffleCashier = createRaffleCashier(_routerAddress, _WETH, _FMON);
        raffleWinnerNumberGenerator = createRaffleWinnerNumberGenerator(
            address(this),
            _subscriptionId
        );
    }

    function getCurrentAdminUsers()
        external
        view
        onlyIfAdminUser
        returns (address[] memory _currentAdminUsers)
    {
        return adminUsers;
    }

    function getIfUserIsAdmin(address userToCheck)
        external
        view
        returns (bool _userIsAdmin)
    {
        return isAdminUser[userToCheck];
    }

    function allRafflesLength()
        external
        view
        returns (uint256 _rafflesAddressesQuantity)
    {
        return rafflesAddresses.length;
    }

    function updateMegaVaultWallet(address newWallet) external onlyOwner {
        require(megaVaultAddress != newWallet, "Wallet already set");
        megaVaultAddress = newWallet;
    }

    function updateXPresidentsVaultWallet(address newWallet)
        external
        onlyOwner
    {
        require(xPresidentsVaultAddress != newWallet, "Wallet already set");
        xPresidentsVaultAddress = newWallet;
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner {
        require(treasuryAddress != newWallet, "Wallet already set");
        treasuryAddress = newWallet;
    }

    function approveRouterToSwapToken(address _tokenToApprove)
        external
        onlyIfAdminUser
        returns (bool _approvalSuccess)
    {
        RaffleCashier(raffleCashier).approveRouterToSwapToken(_tokenToApprove);
        return true;
    }

    function addUSDCLiquidity(address _USDC, uint256 _liquidityToAdd)
        external
        onlyOwner
        returns (bool _removeLiquiditySuccess)
    {
        require(_USDC != address(0), "FmoneyRaffleV1: ZERO_USDC_ADDRESS");
        require(
            _liquidityToAdd > 0,
            "Please set the quantity of liquidity that you want to add"
        );
        RaffleCashier(raffleCashier).addUSDCLiquidity(
            _USDC,
            msg.sender,
            _liquidityToAdd
        );
        return true;
    }

    function removeUSDCLiquidity(address _USDC, uint256 _liquidityToRemove)
        external
        onlyOwner
        returns (bool _removeLiquiditySuccess)
    {
        RaffleCashier(raffleCashier).removeUSDCLiquidity(
            _USDC,
            _liquidityToRemove,
            msg.sender
        );
        return true;
    }

    function changeRouterToBuyTickets(address _newRouterAddress)
        external
        onlyOwner
        returns (bool _success)
    {
        RaffleCashier(raffleCashier).changeRouterToMakeSwap(_newRouterAddress);
        return true;
    }

    function addAdminUser(address adminUserToAdd) external onlyOwner {
        // Already maxed, cannot add any more admin users.
        if (adminUsers.length == MAX_ADMINS) revert TooManyAdminUsers();
        if (isAdminUser[adminUserToAdd] == true) revert AdminUserAlreadyAdded();

        adminUsers.push(adminUserToAdd);
        isAdminUser[adminUserToAdd] = true;

        emit AdminUserAdded(adminUserToAdd);
    }

    function removeAdminUser(address adminUserToRemove)
        external
        onlyIfAdminUser
    {
        if (adminUsers.length == 1) revert AdminUsersCantBeEmpty();
        if (adminUserToRemove == owner) revert OwnerCantBeRemoved();
        if (!isAdminUser[adminUserToRemove]) revert UserToRemoveIsNotAdmin();

        uint256 lastAdminUserIndex = adminUsers.length - 1;
        for (uint256 i = 0; i < adminUsers.length; i++) {
            if (adminUsers[i] == adminUserToRemove) {
                address last = adminUsers[lastAdminUserIndex];
                adminUsers[i] = last;
                adminUsers.pop();
                break;
            }
        }

        isAdminUser[adminUserToRemove] = false;
        emit AdminUserRemoved(adminUserToRemove);
    }

    function createRaffleCashier(
        address _routerAddress,
        address _WETH,
        address _FMON
    ) internal returns (address _raffleCashier) {
        bytes32 salt = keccak256(abi.encodePacked(_routerAddress));

        RaffleCashier _raffleCashierContract = new RaffleCashier{salt: salt}(
            _routerAddress,
            _WETH,
            _FMON
        );

        emit RaffleCashierCreated(address(_raffleCashierContract), salt);
        return address(_raffleCashierContract);
    }

    function createRaffleWinnerNumberGenerator(
        address _raffleManagerAddress,
        uint64 _subscriptionId
    ) internal returns (address _raffleWinnerNumberGenerator) {
        bytes32 salt = keccak256(
            abi.encodePacked(_raffleManagerAddress, _subscriptionId)
        );

        RaffleWinnerNumberGenerator _raffleWinnerNumberGeneratorContract = new RaffleWinnerNumberGenerator{
                salt: salt
            }(_raffleManagerAddress, _subscriptionId);

        emit RaffleWinnerNumberGeneratorCreated(
            address(_raffleWinnerNumberGeneratorContract),
            salt
        );
        return address(_raffleWinnerNumberGeneratorContract);
    }

    function createRaffle(
        address _USDC,
        uint256 _dateOfDraw,
        string memory _raffleName,
        uint16 _minNumberOfPlayers,
        uint16 _maxNumberOfPlayers,
        string memory _raffleSymbol,
        uint16 _percentageOfPrizeToOperator,
        uint256 _priceOfTheRaffleTicketInUSDC
    ) external onlyIfAdminUser returns (address _raffleOperatorAddress) {
        require(_USDC != address(0), "FmoneyRaffleV1: ZERO_USDC_ADDRESS");

        bytes32 salt = keccak256(
            abi.encodePacked(
                _USDC,
                _dateOfDraw,
                _raffleName,
                _minNumberOfPlayers,
                _maxNumberOfPlayers,
                _raffleSymbol,
                _percentageOfPrizeToOperator,
                _priceOfTheRaffleTicketInUSDC,
                raffleWinnerNumberGenerator,
                raffleCashier
            )
        );

        RaffleOperator _raffleOperatorContract = new RaffleOperator{salt: salt}(
            _USDC,
            _dateOfDraw,
            owner,
            _raffleName,
            _minNumberOfPlayers,
            _maxNumberOfPlayers,
            _raffleSymbol,
            _percentageOfPrizeToOperator,
            _priceOfTheRaffleTicketInUSDC,
            raffleWinnerNumberGenerator,
            raffleCashier
        );

        rafflesAddresses.push(address(_raffleOperatorContract));
        currentRaffleId++;

        emit RaffleCreated(
            address(_raffleOperatorContract),
            salt,
            rafflesAddresses.length
        );
        return address(_raffleOperatorContract);
    }

    function drawRaffle(address _raffleOperatorContract)
        external
        onlyIfAdminUser
        returns (bool _raffleIsInProgress)
    {
        uint256 _dateOfDraw = RaffleOperator(_raffleOperatorContract)
            .dateOfDraw();
        uint32 _maxNumberOfPlayers = RaffleOperator(_raffleOperatorContract)
            .maxNumberOfPlayers();
        uint32 _minNumberOfPlayers = RaffleOperator(_raffleOperatorContract)
            .minNumberOfPlayers();
        address payable[] memory _ticketBuyers = RaffleOperator(
            _raffleOperatorContract
        ).getRaffleTicketBuyers();

        if (_ticketBuyers.length < _maxNumberOfPlayers) {
            require(block.timestamp >= _dateOfDraw, "The draw is not yet.");
        }

        if (_ticketBuyers.length == 0) {
            RaffleOperator(_raffleOperatorContract).runSwitch(false); // We close the raffle because there is no players
            return true;
        }

        if (_ticketBuyers.length < _minNumberOfPlayers) {
            RaffleOperator(_raffleOperatorContract).returnMoneyToOwners(); // We close the raffle because there is less players
            return true;
        }

        RaffleWinnerNumberGenerator(raffleWinnerNumberGenerator).launchRaffle(
            _raffleOperatorContract
        );
        return true;
    }

    function getRaffleWinner(address _raffleOperatorContract)
        external
        onlyOwner
        returns (uint256 _raffleWinnerNumber)
    {
        _raffleWinnerNumber = RaffleWinnerNumberGenerator(
            raffleWinnerNumberGenerator
        ).getRaffleWinnerNumber(_raffleOperatorContract);
        require(
            _raffleWinnerNumber != RAFFLE_IN_PROGRESS,
            "Raffle in progress."
        );
        RaffleOperator(_raffleOperatorContract).setRaffleWinner(
            _raffleWinnerNumber
        );
    }
}
"},"RaffleOperator.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./Finalizable.sol";
import "./RaffleManager.sol";
import "./RaffleCashier.sol";
import "./ERC721URIStorage.sol";
import "./RaffleWinnerNumberGenerator.sol";

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

contract RaffleOperator is Finalizable, ERC721URIStorage {
    uint256 public dateOfDraw;
    bool public prizeClaimed;
    uint256 public drawLaunchedAt;
    address public immutable USDC;
    address public raffleMegaVault;
    uint256 public raffleTotalPrize;
    address public raffleWinnerPlayer; // The address of the owner of the NFT token that claim the prize
    uint16 public minNumberOfPlayers;
    uint16 public maxNumberOfPlayers;
    uint256[] public currentSpotsBought;
    address payable[] public ticketBuyers; // The player that buy the ticket to enter, can be different to the winner because can sell the ticket to other person
    address public xPresidentsVaultAddress;
    uint256 public raffleWinnerPositionNumber;
    uint16 public percentageOfPrizeToOperator;
    uint256 public priceOfTheRaffleTicketInUSDC;
    uint256 public raffleCostsDeliveredToOperator;
    mapping(address => bool) public isTicketBuyer;
    uint256 public rafflePotPrizeDeliveredToWinner;

    RaffleCashier raffleCashierInstance;
    RaffleManager raffleManagerInstance;
    RaffleWinnerNumberGenerator raffleWinnerNumberGeneratorInstance;

    constructor(
        address _USDC,
        uint256 _dateOfDraw,
        address _raffleMegaVault,
        string memory _raffleName,
        uint16 _minNumberOfPlayers,
        uint16 _maxNumberOfPlayers,
        string memory _raffleSymbol,
        uint16 _percentageOfPrizeToOperator,
        uint256 _priceOfTheRaffleTicketInUSDC,
        address _raffleWinnerNumberGeneratorAddress,
        address _raffleCashier
    ) ERC721(_raffleName, _raffleSymbol) {
        USDC = _USDC;
        owner = msg.sender;
        dateOfDraw = _dateOfDraw;
        raffleMegaVault = _raffleMegaVault;
        minNumberOfPlayers = _minNumberOfPlayers;
        maxNumberOfPlayers = _maxNumberOfPlayers;
        raffleManagerInstance = RaffleManager(msg.sender);
        raffleCashierInstance = RaffleCashier(_raffleCashier);
        percentageOfPrizeToOperator = _percentageOfPrizeToOperator;
        priceOfTheRaffleTicketInUSDC = _priceOfTheRaffleTicketInUSDC;
        raffleWinnerNumberGeneratorInstance = RaffleWinnerNumberGenerator(
            _raffleWinnerNumberGeneratorAddress
        );
    }

    function getRaffleTicketPlayerBySpotTicketId(uint256 _raffleSpotToSearch)
        external
        view
        returns (address _rafflePlayerBySpotTicketId)
    {
        return ownerOf(_raffleSpotToSearch);
    }

    function getRaffleTicketBuyers()
        external
        view
        returns (address payable[] memory _raffleBuyers)
    {
        return ticketBuyers;
    }

    function getRaffleTicketOwners()
        external
        view
        returns (
            address[] memory _ticketOwners,
            uint256[] memory _currentRafflePlayerNumbers
        )
    {
        _currentRafflePlayerNumbers = raffleWinnerNumberGeneratorInstance
            .getPlayerNumbers(address(this));
        _ticketOwners = new address[](_currentRafflePlayerNumbers.length);

        for (uint256 i = 0; i < _currentRafflePlayerNumbers.length; ++i) {
            _ticketOwners[i] = ownerOf(_currentRafflePlayerNumbers[i]);
        }
    }

    function getCurrentSpotsBought()
        external
        view
        returns (uint256[] memory _currentSpotsBought)
    {
        return currentSpotsBought;
    }

    function getIfAddressPlay(address _addressToCheck)
        external
        view
        returns (bool _addressPlay)
    {
        return (_balances[_addressToCheck] > 0);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyIfRunning {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyIfRunning {
        safeTransferFrom(from, to, tokenId, "");
    }

    function setDateOfTheLaunch() public returns (bool success) {
        require(
            msg.sender == address(raffleWinnerNumberGeneratorInstance),
            "Unauthorized"
        );
        drawLaunchedAt = block.timestamp;
        return true;
    }

    function buyTicketsToPlay(
        uint256 _amountToBuyTickets,
        uint256[] memory _raffleTicketIds,
        string[] memory _raffleTicketTokenURIs,
        address _tokenToUseToBuyTickets
    ) public payable onlyIfRunning returns (bool success) {
        require(
            dateOfDraw - 600 >= block.timestamp,
            "The buying of the tickets for the raffle is closed."
        ); // 10 minutes
        require(
            ticketBuyers.length < maxNumberOfPlayers,
            "The maximum number of players was reached."
        );
        require(
            _raffleTicketIds.length == _raffleTicketTokenURIs.length,
            "tokenIds and tokenURIs length mismatch"
        );

        if (_tokenToUseToBuyTickets == USDC) {
            require(
                _amountToBuyTickets ==
                    (_raffleTicketIds.length * priceOfTheRaffleTicketInUSDC),
                "The amount to buy ticket is not correct."
            );

            uint256 balanceOfUSDCOfSender = IERC20(USDC).balanceOf(msg.sender);
            require(
                balanceOfUSDCOfSender >=
                    (_raffleTicketIds.length * priceOfTheRaffleTicketInUSDC),
                "You dont have USDC balance to buy tickets."
            );

            raffleCashierInstance.transferAmountToBuyTickets(
                USDC,
                msg.sender,
                address(this),
                _amountToBuyTickets
            );
        } else {
            // All amounts are without decimals
            uint256 decimalsOfToken = IERC20(_tokenToUseToBuyTickets)
                .decimals();
            uint256 balanceOfTokenOfSender = IERC20(_tokenToUseToBuyTickets)
                .balanceOf(msg.sender);

            uint256 currentPriceOfTokenByETHInUSDC = raffleCashierInstance
                .getCurrentPriceOfTokenByETHInUSDC(
                    _tokenToUseToBuyTickets,
                    USDC
                );
            uint256 amountOfTokensRequiredToBuy = ((priceOfTheRaffleTicketInUSDC *
                    (1 * 10**decimalsOfToken)) /
                    currentPriceOfTokenByETHInUSDC) * _raffleTicketIds.length;

            require(
                _amountToBuyTickets >= amountOfTokensRequiredToBuy,
                "The amount to buy ticket is not correct."
            );
            require(
                balanceOfTokenOfSender >= amountOfTokensRequiredToBuy,
                "You dont have token balance to buy tickets."
            );

            raffleCashierInstance.transferAmountOfUSDFromLiquidityToBuyTickets(
                USDC,
                msg.sender,
                address(this),
                _tokenToUseToBuyTickets,
                _amountToBuyTickets,
                _raffleTicketIds.length * priceOfTheRaffleTicketInUSDC
            );
        }

        for (uint256 i = 0; i < _raffleTicketIds.length; ++i) {
            require(
                _raffleTicketIds[i] != 0,
                "All the ticket ids has to be different from 0."
            );
            require(
                _raffleTicketIds[i] <= maxNumberOfPlayers,
                "Tickets cannot be greater than the number of players."
            );

            giveRaffleTicket(
                msg.sender,
                _raffleTicketIds[i],
                _raffleTicketTokenURIs[i]
            );
            raffleWinnerNumberGeneratorInstance.setNewRafflePlayingSpot(
                address(this),
                _raffleTicketIds[i]
            );

            ticketBuyers.push(payable(msg.sender));
            isTicketBuyer[msg.sender] = true;
            currentSpotsBought.push(_raffleTicketIds[i]);
        }

        return true;
    }

    function giveRaffleTicket(
        address buyer,
        uint256 newRaffleTicketId,
        string memory tokenURI
    ) internal returns (uint256) {
        require(!_exists(newRaffleTicketId), "Raffle ticket id already sold.");

        _mint(buyer, newRaffleTicketId);
        _setTokenURI(newRaffleTicketId, tokenURI);

        return newRaffleTicketId;
    }

    function returnMoneyToOwners()
        public
        onlyOwner
        onlyIfRunning
        returns (bool _raffleIsFinished)
    {
        for (uint256 i = 0; i < currentSpotsBought.length; ++i) {
            address spotOwner = ownerOf(currentSpotsBought[i]);
            TransferHelper.safeTransfer(
                USDC,
                spotOwner,
                priceOfTheRaffleTicketInUSDC
            );
        }

        running = false;
        return true;
    }

    function setRaffleWinner(uint256 _raffleWinnerNumber)
        public
        onlyOwner
        onlyIfRunning
        returns (bool _raffleIsFinished)
    {
        raffleWinnerPlayer = ownerOf(_raffleWinnerNumber);
        raffleTotalPrize = IERC20(USDC).balanceOf(address(this));

        sendRaffleCostsToOperator();
        claimRafflePrizePot(raffleWinnerPlayer);

        raffleWinnerPositionNumber = _raffleWinnerNumber;
        running = false;
        return true;
    }

    function sendRaffleCostsToOperator() internal returns (bool _success) {
        raffleCostsDeliveredToOperator = ((raffleTotalPrize *
            percentageOfPrizeToOperator) / 100);
        uint256 raffleCostsDeliveredToMegaVault = (raffleCostsDeliveredToOperator *
                85) / 100;
        uint256 raffleCostsDeliveredToProject = (raffleCostsDeliveredToOperator *
                15) / 100;

        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.megaVaultAddress()),
            raffleCostsDeliveredToMegaVault
        );
        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.treasuryAddress()),
            raffleCostsDeliveredToProject / 2
        );
        TransferHelper.safeTransfer(
            USDC,
            address(raffleManagerInstance.xPresidentsVaultAddress()),
            raffleCostsDeliveredToProject / 2
        );
        return true;
    }

    function claimRafflePrizePot(address _raffleWinnerPlayer)
        internal
        returns (bool _success)
    {
        require(!prizeClaimed, "The prize was already claimed.");

        uint16 percentageOfThePotToTheWinner = 100 -
            percentageOfPrizeToOperator;
        rafflePotPrizeDeliveredToWinner = ((raffleTotalPrize *
            percentageOfThePotToTheWinner) / 100);

        TransferHelper.safeTransfer(
            USDC,
            address(raffleCashierInstance),
            rafflePotPrizeDeliveredToWinner
        );
        raffleCashierInstance.transferPrizeToWinner(
            address(this),
            USDC,
            _raffleWinnerPlayer,
            rafflePotPrizeDeliveredToWinner
        );

        prizeClaimed = true;
        return true;
    }
}
"},"RaffleWinnerNumberGenerator.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./RaffleOperator.sol";
import "./VRFConsumerBaseV2.sol";

interface VRFCoordinatorV2Interface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_provingKeyHashes list of registered key hashes
     */
    function getRequestConfig()
        external
        view
        returns (
            uint16,
            uint32,
            bytes32[] memory
        );

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a particular oracle job which uses
     * that key for generating the VRF proof. Different keyHash's have different gas price
     * ceilings, so you can select a specific one to bound your maximum per request cost.
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     * @dev Note to fund the subscription, use transferAndCall. For example
     * @dev  LINKTOKEN.transferAndCall(
     * @dev    address(COORDINATOR),
     * @dev    amount,
     * @dev    abi.encode(subId));
     */
    function createSubscription() external returns (uint64 subId);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId)
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        );

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
        external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     * @param to - Where to send the remaining LINK to
     */
    function cancelSubscription(uint64 subId, address to) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);
}

contract RaffleWinnerNumberGenerator is VRFConsumerBaseV2 {
    mapping(uint256 => address) private rafflesHistory;
    mapping(address => uint256) public rafflesResults;
    mapping(address => uint256[]) private rafflesPlayerNumbers;
    uint256 public constant RAFFLE_IN_PROGRESS = 3200000;
    uint64 s_subscriptionId;

    VRFCoordinatorV2Interface COORDINATOR;
    error Unauthorized();

    address s_owner;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 40000;
    uint32 limitOfRequestedNumber;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 s_keyHash =
        0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

    event RaffleLaunched(
        uint256 indexed requestId,
        address indexed raffleOperatorAddress
    );
    event RaffleLanded(
        uint256 indexed requestId,
        address indexed raffleOperatorAddress,
        uint256 indexed result
    );

    modifier onlyOwner() {
        require(msg.sender == s_owner, "You are not the owner");
        _;
    }

    modifier onlyIfRaffleRunning(address _raffleOperator) {
        bool isRaffleRunning = RaffleOperator(_raffleOperator).running();
        require(isRaffleRunning == true, "Raffle was finished");
        _;
    }

    constructor(address raffleManager, uint64 subscriptionId)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = raffleManager;
        s_subscriptionId = subscriptionId;
    }

    function getPlayerNumbers(address _raffleOperator)
        external
        view
        returns (uint256[] memory _currentRafflePlayerNumbers)
    {
        return rafflesPlayerNumbers[_raffleOperator];
    }

    function getRaffleWinnerNumber(address _raffleOperator)
        public
        view
        onlyOwner
        returns (uint256 _raffleWinnerNumber)
    {
        require(rafflesResults[_raffleOperator] != 0, "Raffle not subscribed");

        if (rafflesResults[_raffleOperator] == RAFFLE_IN_PROGRESS) {
            return RAFFLE_IN_PROGRESS;
        }

        return rafflesResults[_raffleOperator];
    }

    function setNewRafflePlayingSpot(
        address _raffleOperator,
        uint256 _playerNumber
    ) public returns (bool _success) {
        if (msg.sender != _raffleOperator) revert Unauthorized();

        rafflesPlayerNumbers[_raffleOperator].push(_playerNumber);
        return true;
    }

    function restartRaffle(address _raffleOperator)
        public
        onlyOwner
        returns (bool _raffleRestarted)
    {
        require(
            rafflesResults[_raffleOperator] != RAFFLE_IN_PROGRESS,
            "Raffle in progress"
        );
        rafflesResults[_raffleOperator] = 0;
        return true;
    }

    function launchRaffle(address _raffleOperator)
        public
        onlyOwner
        onlyIfRaffleRunning(_raffleOperator)
        returns (uint256 requestId)
    {
        require(rafflesResults[_raffleOperator] == 0, "Already drawn");
        // Will revert if subscription is not set and funded.

        RaffleOperator(_raffleOperator).setDateOfTheLaunch();
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        limitOfRequestedNumber = uint32(
            rafflesPlayerNumbers[_raffleOperator].length
        );
        rafflesHistory[requestId] = _raffleOperator;
        rafflesResults[_raffleOperator] = RAFFLE_IN_PROGRESS;

        emit RaffleLaunched(requestId, _raffleOperator);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomNumbers
    ) internal override {
        uint256 positionOfWinnerNumber = (randomNumbers[0] %
            limitOfRequestedNumber) + 1;
        uint256 winnerNumber = rafflesPlayerNumbers[rafflesHistory[requestId]][
            positionOfWinnerNumber - 1
        ]; // Because zero counts
        rafflesResults[rafflesHistory[requestId]] = winnerNumber;
    }
}
"},"VRFConsumerBaseV2.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private immutable vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}
"}}