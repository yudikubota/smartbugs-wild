{"Address.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
"},"BDIMarketMaker.sol":{"content":"// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IBasket.sol";
import "./IATokenV1.sol";
import "./IUniswapV2.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ICToken.sol";
import "./ICurve.sol";
import "./ILendingPoolV1.sol";
import "./IWETH.sol";
import "./IYearn.sol";



contract MarketMakerHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Curve
    address constant CURVE_LINK = 0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    // Yearn tokens
    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;
    address constant yLinkCRV = 0xf2db9a7c0ACd427A680D640F02d90f6186E71725;

    // Curve Tokens
    address constant linkCRV = 0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;
    address constant gaugeLinkCRV = 0xFD4D8a17df4C27c1dD245d153ccf4499e806C87D;

    // Compound
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // Router address
    address constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // CTokens
    address constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // SUSHI
    address constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // WETH
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // DPI
    address constant DPI = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

    // BDI
    address constant BDI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;
    address constant SUSHI_BDI_ETH = 0x8d782C5806607E9AAFB2AC38c1DA3838Edf8BD03;

    // Defi tokens
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    address constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    // ATokens v1
    address constant AYFIv1 = 0x12e51E77DAAA58aA0E9247db7510Ea4B46F9bEAd;
    address constant ASNXv1 = 0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE;
    address constant AMKRv1 = 0x7deB5e830be29F91E298ba5FF1356BB7f8146998;
    address constant ARENv1 = 0x69948cC03f478B95283F7dbf1CE764d0fc7EC54C;
    address constant AKNCv1 = 0x9D91BE44C06d373a8a226E1f3b146956083803eB;

    // BDPI
    IBasket constant BDPI = IBasket(0x0309c98B1bffA350bcb3F9fB9780970CA32a5060);

    /// @notice Enters Compound market. *Must be called before toCToken*
    /// @param  _markets  Compound markets to enter (underlying, not cTokens)
    function enterMarkets(address[] memory _markets) public {
        IComptroller(COMPTROLLER).enterMarkets(_markets);
    }

    // **** Internal ****

    /// @notice Converts a derivative to its underlying
    /// @param _derivative Derivate token address, if its the underlying it won't do anything
    /// @return Underlying address
    function _toUnderlying(address _derivative, uint256 _amount) internal returns (address, uint256) {
        if (_isCToken(_derivative)) {
            return _fromCToken(_derivative, _amount);
        }

        if (_isATokenV1(_derivative)) {
            return _fromATokenV1(_derivative, _amount);
        }

        if (_derivative == XSUSHI) {
            return _fromXSushi(_amount);
        }

        if (_derivative == linkCRV) {
            return _fromLinkCRV(_amount);
        }

        if (_derivative == gaugeLinkCRV) {
            (, uint256 amount) = _fromGaugeLinkCRV(_amount);
            return _fromLinkCRV(amount);
        }

        if (_derivative == yLinkCRV) {
            (, uint256 amount) = _fromYearnLinkCRV(_amount);
            return _fromLinkCRV(amount);
        }

        if (_derivative == yvBOOST || _derivative == yveCRV) {
            if (_derivative == yveCRV) {
                _toYveBoost();
            }

            // Just sell directly on uniswap
            address[] memory path = new address[](2);
            path[0] = yvBOOST;
            path[1] = WETH;

            uint256 _bamount = IERC20(yvBOOST).balanceOf(address(this));

            IERC20(yvBOOST).approve(SUSHISWAP_ROUTER, _bamount);
            uint256[] memory outs =
                IUniswapV2Router02(SUSHISWAP_ROUTER).swapExactTokensForTokens(
                    _bamount,
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );

            return (WETH, outs[1]);
        }

        return (_derivative, _amount);
    }

    /// @notice Converts underlying to derivative
    /// @param  _derivative  Address of the derivative token
    function _toDerivative(address _underlying, address _derivative) internal {
        if (_underlying == _derivative) {
            return;
        }

        if (_isCToken(_derivative)) {
            _toCToken(_underlying);
        } else if (_isATokenV1(_derivative)) {
            _toATokenV1(_underlying);
        } else if (_derivative == XSUSHI) {
            _toXSushi();
        } else if (_underlying == LINK && _derivative == linkCRV) {
            _toLinkCRV();
        } else if (_underlying == LINK && _derivative == yLinkCRV) {
            _toLinkCRV();
            _toYearnLinkCRV();
        } else if (_underlying == LINK && _derivative == gaugeLinkCRV) {
            // Underlying should always be LINK
            // as we cannot get linkCRV on exchanges
            _toLinkCRV();
            _toGaugeLinkCRV();
        } else if (_underlying == CRV && _derivative == yveCRV) {
            // Underlying should always be CRV
            _toYveCRV();
        } else if (_underlying == CRV && _derivative == yvBOOST) {
            // Underlying should always be CRV
            _toYveCRV();
            _toYveBoost();
        }
    }

    /// @notice Checks if a token is aTokenV1
    /// @param  _atoken Token address
    /// @return Boolean value indicating if token is an aTokenV1
    function _isATokenV1(address _atoken) public pure returns (bool) {
        return (_atoken == AYFIv1 || _atoken == ASNXv1 || _atoken == AMKRv1 || _atoken == ARENv1 || _atoken == AKNCv1);
    }

    /// @notice Checks if a token is cToken
    /// @param  _ctoken Token address
    /// @return Boolean value indicating if token is a cToken
    function _isCToken(address _ctoken) public pure returns (bool) {
        return (_ctoken == CCOMP || _ctoken == CUNI);
    }

    /// @notice Supplies assets to the Compound market
    /// @param  _token  Underlying token to supply to Compound
    function _toCToken(address _token) internal {
        // Only doing UNI or COMP for CTokens
        require(_token == UNI || _token == COMP, "!valid-to-ctoken");

        address _ctoken = _getTokenToCToken(_token);
        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(_ctoken, 0);
        IERC20(_token).safeApprove(_ctoken, balance);
        require(ICToken(_ctoken).mint(balance) == 0, "!ctoken-mint");
    }

    /// @notice Redeems assets from the Compound market
    /// @param  _ctoken  CToken to redeem from Compound
    function _fromCToken(address _ctoken, uint256 _camount) internal returns (address _token, uint256 _amount) {
        // Only doing CUNI or CCOMP
        require(_ctoken == CUNI || _ctoken == CCOMP, "!valid-from-ctoken");

        _token = ICToken(_ctoken).underlying();

        uint256 before = IERC20(_token).balanceOf(address(this));
        require(ICToken(_ctoken).redeem(_camount) == 0, "!ctoken-redeem");
        _amount = IERC20(_token).balanceOf(address(this)).sub(before);
    }

    /// @notice Supplies assets to the Aave market
    /// @param  _token  Underlying to supply to Aave
    function _toATokenV1(address _token) internal {
        require(_token != UNI && _token != COMP, "no-uni-or-comp");

        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, 0);
        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, balance);
        ILendingPoolV1(LENDING_POOL_V1).deposit(_token, balance, 0);
    }

    /// @notice Redeems assets from the Aave market
    /// @param  _atoken  AToken to redeem from Aave
    function _fromATokenV1(address _atoken, uint256 _aamount) internal returns (address _token, uint256 _amount) {
        _token = IATokenV1(_atoken).underlyingAssetAddress();

        uint256 before = IERC20(_token).balanceOf(address(this));
        IATokenV1(_atoken).redeem(_aamount);
        _amount = IERC20(_token).balanceOf(address(this)).sub(before);
    }

    /// @notice Converts link to linkCRV
    function _toLinkCRV() internal {
        // Deposit into gauge
        uint256 balance = IERC20(LINK).balanceOf(address(this));

        IERC20(LINK).safeApprove(CURVE_LINK, 0);
        IERC20(LINK).safeApprove(CURVE_LINK, balance);

        ICurveLINK(CURVE_LINK).add_liquidity([balance, uint256(0)], 0);
    }

    /// @notice Converts linkCRV to link
    function _fromLinkCRV(uint256 _lamount) internal returns (address, uint256) {
        uint256 _before = IERC20(LINK).balanceOf(address(this));
        ICurveLINK(CURVE_LINK).remove_liquidity_one_coin(_lamount, 0, 0);
        uint256 _after = IERC20(LINK).balanceOf(address(this));
        return (LINK, _after.sub(_before));
    }

    /// @notice Converts linkCRV to GaugeLinkCRV
    function _toGaugeLinkCRV() internal {
        // Deposit into gauge
        uint256 balance = IERC20(linkCRV).balanceOf(address(this));
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, 0);
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, balance);
        ILinkGauge(gaugeLinkCRV).deposit(balance);
    }

    /// @notice Converts GaugeLinkCRV to linkCRV
    function _fromGaugeLinkCRV(uint256 _amount) internal returns (address, uint256) {
        // Deposit into gauge
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        ILinkGauge(gaugeLinkCRV).withdraw(_amount);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts from crv to yveCRV
    function _toYveCRV() internal {
        uint256 balance = IERC20(CRV).balanceOf(address(this));
        IERC20(CRV).safeApprove(yveCRV, 0);
        IERC20(CRV).safeApprove(yveCRV, balance);
        IveCurveVault(yveCRV).deposit(balance);
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _toYveBoost() internal {
        uint256 balance = IERC20(yveCRV).balanceOf(address(this));
        IERC20(yveCRV).safeApprove(yvBOOST, 0);
        IERC20(yveCRV).safeApprove(yvBOOST, balance);
        IYearn(yvBOOST).deposit(balance);
    }

    /// @notice Converts from linkCRV to yearnLinkCRV
    function _toYearnLinkCRV() internal {
        uint256 balance = IERC20(linkCRV).balanceOf(address(this));
        IERC20(linkCRV).safeApprove(yLinkCRV, 0);
        IERC20(linkCRV).safeApprove(yLinkCRV, balance);
        IYearn(yLinkCRV).deposit(balance);
    }

    /// @notice Converts from yearnLinkCRV to linkCRV
    function _fromYearnLinkCRV(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        IYearn(yLinkCRV).withdraw(_amount);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _fromYveBoost(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yveCRV).balanceOf(address(this));
        IYearn(yvBOOST).withdraw(_amount);
        uint256 _after = IERC20(yveCRV).balanceOf(address(this));
        return (yveCRV, _after.sub(_before));
    }

    /// @dev Token to CToken mapping
    /// @param  _token Token address
    function _getTokenToCToken(address _token) internal pure returns (address) {
        if (_token == UNI) {
            return CUNI;
        }
        if (_token == COMP) {
            return CCOMP;
        }
        revert("!supported-token-to-ctoken");
    }

    /// @notice Converts sushi to xsushi
    function _toXSushi() internal {
        uint256 balance = IERC20(SUSHI).balanceOf(address(this));
        require(balance > 0, "!sushi-bal");

        IERC20(SUSHI).safeApprove(XSUSHI, 0);
        IERC20(SUSHI).safeApprove(XSUSHI, balance);
        ISushiBar(XSUSHI).enter(balance);
    }

    /// @notice Goes from xsushi to sushi
    function _fromXSushi(uint256 _xsushiAmount) internal returns (address, uint256) {
        uint256 before = IERC20(SUSHI).balanceOf(address(this));
        ISushiBar(XSUSHI).leave(_xsushiAmount);
        uint256 delta = IERC20(SUSHI).balanceOf(address(this)).sub(before);
        return (SUSHI, delta);
    }
}

contract MarketMakerMinter is MarketMakerHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Converts ETH into a Basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasket  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasket  How much 1 basket token is worth in ETH
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function _mintWithWETH(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasket,
        uint256 ethPerBasket,
        uint256 minMintAmount,
        uint256 deadline
    ) internal returns (uint256) {
        require(block.timestamp <= deadline, "expired");

        // BDPI to mint
        uint256 bdpiToMint =
            _convertETHToDerivativeAndGetMintAmount(
                routers,
                derivatives,
                underlyings,
                underlyingsInEthPerBasket,
                ethPerBasket
            );

        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Mint tokens
        BDPI.mint(bdpiToMint);

        return bdpiToMint;
    }

    /// @notice Converts ETH into the specific derivative and get mint amount for basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasketToken  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasketToken  How much 1 basket token is worth in ETH
    function _convertETHToDerivativeAndGetMintAmount(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasketToken,
        uint256 ethPerBasketToken
    ) internal returns (uint256) {
        // Path
        address[] memory path = new address[](2);
        path[0] = WETH;

        // Convert them all to the underlyings
        uint256 bdpiToMint;

        // Get total amount in bdpi
        (, uint256[] memory tokenAmountsInBasket) = BDPI.getAssetsAndBalances();

        // BDPI total supply
        uint256 basketTotalSupply = BDPI.totalSupply();

        uint256 ethAmount = IERC20(WETH).balanceOf(address(this));

        {
            uint256 ratio;
            uint256 ethToSend;
            for (uint256 i = 0; i < derivatives.length; i++) {
                ratio = underlyingsInEthPerBasketToken[i].mul(1e18).div(ethPerBasketToken);

                // Convert them from ETH to their respective tokens (truncate 1e4 for rounding errors)
                ethToSend = ethAmount.mul(ratio).div(1e24).mul(1e6);

                path[1] = underlyings[i];
                IUniswapV2Router02(routers[i]).swapExactTokensForTokens(
                    ethToSend,
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );

                // Convert to from respective token to derivative
                _toDerivative(underlyings[i], derivatives[i]);

                // Approve derivative and calculate mint amount
                bdpiToMint = _approveDerivativeAndGetMintAmount(
                    derivatives[i],
                    basketTotalSupply,
                    tokenAmountsInBasket[i],
                    bdpiToMint
                );
            }
        }

        return bdpiToMint;
    }

    /// @notice Approves derivative to the basket address and gets the mint amount.
    ///         Mainly here to avoid stack too deep errors
    /// @param  derivative  Address of the derivative (e.g. cUNI, aYFI)
    /// @param  basketTotalSupply  Total supply of the basket token
    /// @param  tokenAmountInBasket  Amount of derivative currently in the basket
    /// @param  curMintAmount  Accumulator - whats the minimum mint amount right now
    function _approveDerivativeAndGetMintAmount(
        address derivative,
        uint256 basketTotalSupply,
        uint256 tokenAmountInBasket,
        uint256 curMintAmount
    ) internal returns (uint256) {
        uint256 derivativeBal = IERC20(derivative).balanceOf(address(this));

        IERC20(derivative).safeApprove(address(BDPI), 0);
        IERC20(derivative).safeApprove(address(BDPI), derivativeBal);

        // Calculate how much BDPI we can mint at max
        // Formula: min(e for e in bdpiSupply * tokenWeHave[e] / tokenInBDPI[e])
        if (curMintAmount == 0) {
            return basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        }

        uint256 temp = basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        if (temp < curMintAmount) {
            return temp;
        }

        return curMintAmount;
    }
}

contract MarketMakerBurner is MarketMakerHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // **** Internals **** //

    // Burns BDPI to ETH
    function _burnToWETH(address[] memory routers, uint256 _amount, uint256 _minETHAmount) internal returns (uint256) {
        (address[] memory underlyings, uint256[] memory underlyingAmounts) =
            _burnBDPIAndGetUnderlyingAndAmounts(_amount);

        // Convert underlying to WETH
        address[] memory path = new address[](2);
        path[1] = WETH;
        for (uint256 i = 0; i < underlyings.length; i++) {
            // If we already have WETH (e.g. yvBOOST or yveCRV)
            if (underlyings[i] != WETH) {
                path[0] = underlyings[i];

                IERC20(underlyings[i]).safeApprove(routers[i], 0);
                IERC20(underlyings[i]).safeApprove(routers[i], underlyingAmounts[i]);
                IUniswapV2Router02(routers[i]).swapExactTokensForTokens(
                    underlyingAmounts[i],
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );
            }
        }
        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));
        require(totalWETH >= _minETHAmount, "!min-eth-amount");

        return totalWETH;
    }

    function _burnBDPIAndGetUnderlyingAndAmounts(uint256 _amount)
        internal
        returns (address[] memory, uint256[] memory)
    {
        (address[] memory assets, ) = IBasket(BDPI).getAssetsAndBalances();
        uint256[] memory deltas = new uint256[](assets.length);
        address[] memory underlyings = new address[](assets.length);
        uint256[] memory underlyingAmounts = new uint256[](assets.length);

        address underlying;
        uint256 underlyingAmount;

        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this));
        }
        IBasket(BDPI).burn(_amount);
        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this)).sub(deltas[i]);

            (underlying, underlyingAmount) = _toUnderlying(assets[i], deltas[i]);

            underlyings[i] = underlying;
            underlyingAmounts[i] = underlyingAmount;
        }

        return (underlyings, underlyingAmounts);
    }
}

contract BDIMarketMaker is MarketMakerBurner, MarketMakerMinter {
    receive() external payable {}
}
"},"Context.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
"},"DelayedMinter.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasket.sol";
import "./IBasicIssuanceModule.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./BDIMarketMaker.sol";

// Mint tokens with a delay
contract DelayedMinter is MarketMakerMinter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Can only mint after 20 mins, and only has a 20 mins window to mint
    // 20 min window to mint
    uint256 public mintDelaySeconds = 1200;
    uint256 public maxMintDelaySeconds = 2400;

    address public governance;

    // User deposited
    mapping(address => uint256) public deposits;

    // When user deposited
    mapping(address => uint256) public timestampWhenDeposited;

    // Blacklist
    mapping(address => bool) public isBlacklisted;

    // **** Constructor and modifiers ****

    constructor(address _governance) {
        governance = _governance;

        // Enter compound markets
        address[] memory markets = new address[](2);
        markets[0] = CUNI;
        markets[0] = CCOMP;
        enterMarkets(markets);

        IERC20(WETH).safeApprove(SUSHISWAP_ROUTER, uint256(-1));
        IERC20(WETH).safeApprove(UNIV2_ROUTER, uint256(-1));
    }

    receive() external payable {}

    // **** Modifiers ****

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!eoa");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "blacklisted");
        _;
    }

    // **** Restricted functions ****

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    function recoverERC20(address _token) public onlyGov {
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    function recoverERC20s(address[] memory _tokens) public onlyGov {
        for (uint256 i = 0; i < _tokens.length; i++) {
            recoverERC20(_tokens[i]);
        }
    }

    function setMintDelaySeconds(uint256 _seconds) public onlyGov {
        mintDelaySeconds = _seconds;
    }

    function setMaxMintDelaySeconds(uint256 _seconds) public onlyGov {
        maxMintDelaySeconds = _seconds;
    }

    function setBlacklist(address _user, bool _b) public onlyGov {
        isBlacklisted[_user] = _b;
    }

    // **** Public Functions ****

    function deposit() public payable {
        require(msg.value > 0, "!value");

        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        timestampWhenDeposited[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 _amount) public {
        deposits[msg.sender] = deposits[msg.sender].sub(_amount);

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "!eth-transfer");
    }

    /// @notice Converts ETH into a Basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasket  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasket  How much 1 basket token is worth in ETH
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function mintWithETH(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasket,
        uint256 ethPerBasket,
        uint256 minMintAmount,
        uint256 deadline
    ) public onlyEOA notBlacklisted returns (uint256) {
        require(block.timestamp <= deadline, "expired");

        uint256 _amount = deposits[msg.sender];

        require(_amount > 0, "!amount");
        require(_canMint(timestampWhenDeposited[msg.sender]), "!timestamp");

        uint256 sum = 0;
        for (uint256 i = 0; i < underlyingsInEthPerBasket.length; i++) {
            sum = sum.add(underlyingsInEthPerBasket[i]);
        }
        require(ethPerBasket >= sum, "!valid-inputs");

        // Wrap user amount ETH to WETH
        IWETH(WETH).deposit{ value: deposits[msg.sender] }();

        // BDPI to mint
        uint256 bdpiToMint =
            _convertETHToDerivativeAndGetMintAmount(
                routers,
                derivatives,
                underlyings,
                underlyingsInEthPerBasket,
                ethPerBasket
            );

        // Reset deposit
        deposits[msg.sender] = 0;

        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Mint tokens and transfer to user
        BDPI.mint(bdpiToMint);
        IERC20(address(BDPI)).safeTransfer(msg.sender, bdpiToMint);

        return bdpiToMint;
    }

    // **** Internal functions ****

    function _canMint(uint256 _depositTime) public view returns (bool) {
        return
            block.timestamp >= _depositTime + mintDelaySeconds && block.timestamp <= _depositTime + maxMintDelaySeconds;
    }
}
"},"ERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
"},"IATokenV1.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IATokenV1 {
    function UINT_MAX_VALUE() external view returns (uint256);

    function allowInterestRedirectionTo(address _to) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function burnOnLiquidation(address _account, uint256 _value) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function getInterestRedirectionAddress(address _user) external view returns (address);

    function getRedirectedBalance(address _user) external view returns (uint256);

    function getUserIndex(address _user) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);

    function mintOnDeposit(address _account, uint256 _amount) external;

    function name() external view returns (string memory);

    function principalBalanceOf(address _user) external view returns (uint256);

    function redeem(uint256 _amount) external;

    function redirectInterestStream(address _to) external;

    function redirectInterestStreamOf(address _from, address _to) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOnLiquidation(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function underlyingAssetAddress() external view returns (address);
}
"},"IBasicIssuanceModule.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IBasicIssuanceModule {
    function controller() external view returns (address);

    function getRequiredComponentUnitsForIssue(address _setToken, uint256 _quantity)
        external
        view
        returns (address[] memory, uint256[] memory);

    function initialize(address _setToken, address _preIssueHook) external;

    function issue(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function managerIssuanceHook(address) external view returns (address);

    function redeem(
        address _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function removeModule() external;
}
"},"IBasket.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IBasket {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function mint(uint256) external;

    function getOne() external view returns (address[] memory, uint256[] memory);

    function getAssetsAndBalances() external view returns (address[] memory, uint256[] memory);

    function burn(uint256) external;

    function execute(address _module, bytes memory _data) external payable returns (bytes memory response);

    function grantRole(bytes32, address) external;

    function MARKET_MAKER() external view returns (bytes32);
}
"},"ICompoundLens.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ICompoundLens {
    function getCompBalanceMetadataExt(
        address comp,
        address comptroller,
        address account
    )
        external
        returns (
            uint256 balance,
            uint256 votes,
            address delegate,
            uint256 allocated
        );
}
"},"IComptroller.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IComptroller {
    function _addCompMarkets(address[] memory cTokens) external;

    function _become(address unitroller) external;

    function _borrowGuardianPaused() external view returns (bool);

    function _dropCompMarket(address cToken) external;

    function _grantComp(address recipient, uint256 amount) external;

    function _mintGuardianPaused() external view returns (bool);

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;

    function _setBorrowPaused(address cToken, bool state) external returns (bool);

    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256);

    function _setCollateralFactor(address cToken, uint256 newCollateralFactorMantissa) external returns (uint256);

    function _setCompRate(uint256 compRate_) external;

    function _setContributorCompSpeed(address contributor, uint256 compSpeed) external;

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256);

    function _setMarketBorrowCaps(address[] memory cTokens, uint256[] memory newBorrowCaps) external;

    function _setMintPaused(address cToken, bool state) external returns (bool);

    function _setPauseGuardian(address newPauseGuardian) external returns (uint256);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setSeizePaused(bool state) external returns (bool);

    function _setTransferPaused(bool state) external returns (bool);

    function _supportMarket(address cToken) external returns (uint256);

    function accountAssets(address, uint256) external view returns (address);

    function admin() external view returns (address);

    function allMarkets(uint256) external view returns (address);

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowCapGuardian() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function checkMembership(address account, address cToken) external view returns (bool);

    function claimComp(address holder, address[] memory cTokens) external;

    function claimComp(
        address[] memory holders,
        address[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    function claimComp(address holder) external;

    function closeFactorMantissa() external view returns (uint256);

    function compAccrued(address) external view returns (uint256);

    function compBorrowState(address) external view returns (uint224 index, uint32);

    function compBorrowerIndex(address, address) external view returns (uint256);

    function compClaimThreshold() external view returns (uint256);

    function compContributorSpeeds(address) external view returns (uint256);

    function compInitialIndex() external view returns (uint224);

    function compRate() external view returns (uint256);

    function compSpeeds(address) external view returns (uint256);

    function compSupplierIndex(address, address) external view returns (uint256);

    function compSupplyState(address) external view returns (uint224 index, uint32);

    function comptrollerImplementation() external view returns (address);

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);

    function exitMarket(address cTokenAddress) external returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAllMarkets() external view returns (address[] memory);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getBlockNumber() external view returns (uint256);

    function getCompAddress() external view returns (address);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function isComptroller() external view returns (bool);

    function lastContributorBlock(address) external view returns (uint256);

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external;

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function maxAssets() external view returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintGuardianPaused(address) external view returns (bool);

    function mintVerify(
        address cToken,
        address minter,
        uint256 actualMintAmount,
        uint256 mintTokens
    ) external;

    function oracle() external view returns (address);

    function pauseGuardian() external view returns (address);

    function pendingAdmin() external view returns (address);

    function pendingComptrollerImplementation() external view returns (address);

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function refreshCompSpeeds() external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeGuardianPaused() external view returns (bool);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferGuardianPaused() external view returns (bool);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function updateContributorRewards(address contributor) external;
}
"},"ICToken.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ICToken {
    function _acceptAdmin() external returns (uint256);

    function _addReserves(uint256 addAmount) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setComptroller(address newComptroller) external returns (uint256);

    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;

    function _setInterestRateModel(address newInterestRateModel) external returns (uint256);

    function _setPendingAdmin(address newPendingAdmin) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function admin() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function comptroller() external view returns (address);

    function decimals() external view returns (uint8);

    function delegateToImplementation(bytes memory data) external returns (bytes memory);

    function delegateToViewImplementation(bytes memory data) external view returns (bytes memory);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);

    function implementation() external view returns (address);

    function interestRateModel() external view returns (address);

    function isCToken() external view returns (bool);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function name() external view returns (string memory);

    function pendingAdmin() external view returns (address);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalBorrows() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);
}
"},"ICurve.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ICurveLINK {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(uint256 _new_fee, uint256 _new_admin_fee) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function previous_balances(uint256 arg0) external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_owner() external view returns (address);
}

interface ILinkGauge {
    function decimals() external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address _addr, address _token) external returns (uint256);

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_historic_rewards(address[8] memory _reward_tokens) external;

    function claim_historic_rewards(address[8] memory _reward_tokens, address _addr) external;

    function kick(address addr) external;

    function set_approve_deposit(address addr, bool can_deposit) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);

    function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);

    function set_rewards(
        address _reward_contract,
        bytes32 _sigs,
        address[8] memory _reward_tokens
    ) external;

    function set_killed(bool _is_killed) external;

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function minter() external view returns (address);

    function crv_token() external view returns (address);

    function lp_token() external view returns (address);

    function controller() external view returns (address);

    function voting_escrow() external view returns (address);

    function future_epoch_time() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function approved_to_deposit(address arg0, address arg1) external view returns (bool);

    function working_balances(address arg0) external view returns (uint256);

    function working_supply() external view returns (uint256);

    function period() external view returns (int128);

    function period_timestamp(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply_of(address arg0) external view returns (uint256);

    function integrate_checkpoint_of(address arg0) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);

    function inflation_rate() external view returns (uint256);

    function reward_contract() external view returns (address);

    function reward_tokens(uint256 arg0) external view returns (address);

    function reward_integral(address arg0) external view returns (uint256);

    function reward_integral_for(address arg0, address arg1) external view returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function is_killed() external view returns (bool);
}

interface IveCurveVault {
    function CRV() external view returns (address);

    function DELEGATION_TYPEHASH() external view returns (bytes32);

    function DOMAINSEPARATOR() external view returns (bytes32);

    function DOMAIN_TYPEHASH() external view returns (bytes32);

    function LOCK() external view returns (address);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function acceptGovernance() external;

    function allowance(address account, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function bal() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function checkpoints(address, uint32) external view returns (uint32 fromBlock, uint256 votes);

    function claim() external;

    function claimFor(address recipient) external;

    function claimable(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function delegates(address) external view returns (address);

    function deposit(uint256 _amount) external;

    function depositAll() external;

    function feeDistribution() external view returns (address);

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governance() external view returns (address);

    function index() external view returns (uint256);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function numCheckpoints(address) external view returns (uint32);

    function pendingGovernance() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function proxy() external view returns (address);

    function rewards() external view returns (address);

    function setFeeDistribution(address _feeDistribution) external;

    function setGovernance(address _governance) external;

    function setProxy(address _proxy) external;

    function supplyIndex(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function update() external;

    function updateFor(address recipient) external;
}
"},"IERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
"},"ILendingPoolV1.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ILendingPoolV1 {
    function LENDINGPOOL_REVISION() external view returns (uint256);

    function UINT_MAX_VALUE() external view returns (uint256);

    function addressesProvider() external view returns (address);

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function core() external view returns (address);

    function dataProvider() external view returns (address);

    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    function flashLoan(
        address _receiver,
        address _reserve,
        uint256 _amount,
        bytes memory _params
    ) external;

    function getReserveConfigurationData(address _reserve)
        external
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address interestRateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
        );

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );

    function getReserves() external view returns (address[] memory);

    function getUserAccountData(address _user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );

    function initialize(address _addressesProvider) external;

    function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external payable;

    function parametersProvider() external view returns (address);

    function rebalanceStableBorrowRate(address _reserve, address _user) external;

    function redeemUnderlying(
        address _reserve,
        address _user,
        uint256 _amount,
        uint256 _aTokenBalanceAfterRedeem
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address _onBehalfOf
    ) external payable;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external;

    function swapBorrowRateMode(address _reserve) external;
}
"},"ISushiBar.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ISushiBar {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function enter(uint256 _amount) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function leave(uint256 _share) external;

    function name() external view returns (string memory);

    function sushi() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
"},"IUniswapV2.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
"},"IWETH.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IWETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}
"},"IYearn.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IYearn {
    function initialize(
        address token,
        address governance,
        address rewards,
        string memory nameOverride,
        string memory symbolOverride
    ) external;

    function initialize(
        address token,
        address governance,
        address rewards,
        string memory nameOverride,
        string memory symbolOverride,
        address guardian
    ) external;

    function apiVersion() external pure returns (string memory);

    function setName(string memory name) external;

    function setSymbol(string memory symbol) external;

    function setGovernance(address governance) external;

    function acceptGovernance() external;

    function setManagement(address management) external;

    function setGuestList(address guestList) external;

    function setRewards(address rewards) external;

    function setLockedProfitDegration(uint256 degration) external;

    function setDepositLimit(uint256 limit) external;

    function setPerformanceFee(uint256 fee) external;

    function setManagementFee(uint256 fee) external;

    function setGuardian(address guardian) external;

    function setEmergencyShutdown(bool active) external;

    function setWithdrawalQueue(address[20] memory queue) external;

    function transfer(address receiver, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 amount) external returns (bool);

    function decreaseAllowance(address spender, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes memory signature
    ) external returns (bool);

    function totalAssets() external view returns (uint256);

    function deposit() external returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function deposit(uint256 _amount, address recipient) external returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function pricePerShare() external view returns (uint256);

    function addStrategy(
        address strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    ) external;

    function updateStrategyDebtRatio(address strategy, uint256 debtRatio) external;

    function updateStrategyMinDebtPerHarvest(address strategy, uint256 minDebtPerHarvest) external;

    function updateStrategyMaxDebtPerHarvest(address strategy, uint256 maxDebtPerHarvest) external;

    function updateStrategyPerformanceFee(address strategy, uint256 performanceFee) external;

    function migrateStrategy(address oldVersion, address newVersion) external;

    function revokeStrategy() external;

    function revokeStrategy(address strategy) external;

    function addStrategyToQueue(address strategy) external;

    function removeStrategyFromQueue(address strategy) external;

    function debtOutstanding() external view returns (uint256);

    function debtOutstanding(address strategy) external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function creditAvailable(address strategy) external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function expectedReturn(address strategy) external view returns (uint256);

    function report(
        uint256 gain,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function sweep(address token) external;

    function sweep(address token, uint256 amount) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function precisionFactor() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);

    function governance() external view returns (address);

    function management() external view returns (address);

    function guardian() external view returns (address);

    function guestList() external view returns (address);

    function strategies(address arg0)
        external
        view
        returns (
            uint256 performanceFee,
            uint256 activation,
            uint256 debtRatio,
            uint256 minDebtPerHarvest,
            uint256 maxDebtPerHarvest,
            uint256 lastReport,
            uint256 totalDebt,
            uint256 totalGain,
            uint256 totalLoss
        );

    function withdrawalQueue(uint256 arg0) external view returns (address);

    function emergencyShutdown() external view returns (bool);

    function depositLimit() external view returns (uint256);

    function debtRatio() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function activation() external view returns (uint256);

    function lockedProfit() external view returns (uint256);

    function lockedProfitDegration() external view returns (uint256);

    function rewards() external view returns (address);

    function managementFee() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function nonces(address arg0) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
"},"SafeERC20.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
"},"SafeMath.sol":{"content":"// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
"}}