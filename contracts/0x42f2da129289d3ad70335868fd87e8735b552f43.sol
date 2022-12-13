{"MultiplierCBD.sol":{"content":"// Written by Ermin Nurovic <contact@multiplierpay.com>

pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract CreateBuyDistribute is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint8;

    uint256 public dayOfLastActivity;
    uint8 public numberOfAddressesToPay;
    uint8 public randomPayCreatorOnceEvery;

    // Buyer details including how much buyer has paid for a product and when the buyer has either contributed or
    // had the dividend paid out.
    struct Buyer {
    	uint256 contribution;
    	uint256 totalAtPurchase;
    	uint256 dividendPaid;
    	address payable buyerNext;  // next buyer for creating circular linked list allowing Buyer payout
        address payable buyerPrev;  // previous buyer for creating circular linked list allowing Buyer payout
    }

    // Product details including the creator cut percentage and nested with the Buyers.
    struct Product {
        address payable creator;
        address payable buyerNextPayout;
        address payable buyerPrevPayout;
        bytes32 productName1;
        bytes32 productName2;
        uint256 productPrice;
        uint256 totalPaid;
        uint256 creatorPaidAmount;
        uint256 leftoverDividend;
        uint256 totalAtLeftoverUpdate;
        uint256 ownerPaidAmount;
        uint32 dayOfLastActivity;
        uint32 creatorCut;
        uint32 multiplier;
        mapping (address => Buyer) buyer;
    }

    mapping (address => Product) public product;
    mapping (address => address) public productNext;
    mapping (address => address) public productPrev;

    constructor() public {
        numberOfAddressesToPay = 5;
        randomPayCreatorOnceEvery = 1;
        dayOfLastActivity = now.div(1 days).sub(182);
    }

    event productCreated(address productAddress, bytes32 name1, bytes32 name2, uint8 creatorCut, uint8 multiplier, uint256 price);
    event productBought(address productAddress, address buyerAddress, uint256 totalPaid, uint256 totalAtPurchase);
    event productDeleted(address productAddress);
    event buyerClosed(address productAddress, address buyerAddress);

    function endContract() external onlyOwner {
        require((now.div(1 days)) >= (dayOfLastActivity.add(182)));
        selfdestruct(msg.sender);
    }

    function payAddresses(uint8 _numberOfAddressesToPay, uint8 _randomPayCreatorOnceEvery) external onlyOwner {
        numberOfAddressesToPay = _numberOfAddressesToPay;
        randomPayCreatorOnceEvery = _randomPayCreatorOnceEvery;
    }

    function getBuyer(address _productAddress, address _buyerAddress) external view returns (uint256 contribution, uint256 totalAtPurchase, uint256 dividendPaid, address buyerPrev) {
        contribution = product[_productAddress].buyer[_buyerAddress].contribution;
        totalAtPurchase = product[_productAddress].buyer[_buyerAddress].totalAtPurchase;
        dividendPaid = product[_productAddress].buyer[_buyerAddress].dividendPaid;
        buyerPrev = product[_productAddress].buyer[_buyerAddress].buyerPrev;
        // buyerNext = product[_productAddress].buyer[_buyerAddress].buyerNext;
    }

    function productPrice(address _productAddress, uint256 _productPrice) external {
        require((msg.sender == product[_productAddress].creator) && (_productPrice >= 1000));
        product[_productAddress].productPrice = _productPrice;
    }

    function getCreatorAddress(address _productAddress) external view returns (address payable) {
        return product[_productAddress].creator;
    }

    //Creates a new product
    function createProduct(bytes32 _productName1, bytes32 _productName2, uint _productPrice, uint8 _creatorCut, uint8 _buyerMultiplier) public {
        require(_buyerMultiplier >= 2 && _buyerMultiplier <= 5);
        require(_creatorCut >= 0 && _creatorCut <= 80);
        require(_productPrice >= 1000);

        dayOfLastActivity = now.div(1 days);

        ProductStorage productAddress = new ProductStorage();
        if (!(productPrev[address(0)] == address(0))) { // not the first product ever created
            productNext[productPrev[address(0)]] = address(productAddress);
            productPrev[address(productAddress)] = productPrev[address(0)];
            productPrev[address(0)] = address(productAddress);
        } else { // first product ever
            productPrev[address(0)] = address(productAddress);
            productNext[address(0)] = address(productAddress);
        }
        product[address(productAddress)].productName1 = _productName1;
        product[address(productAddress)].productName2 = _productName2;
        product[address(productAddress)].productPrice = _productPrice;
        product[address(productAddress)].creatorCut = _creatorCut;
        product[address(productAddress)].multiplier = _buyerMultiplier;
        product[address(productAddress)].buyerNextPayout = address(0);
        product[address(productAddress)].buyerPrevPayout = address(0);
        product[address(productAddress)].creator = msg.sender;
        product[address(productAddress)].dayOfLastActivity = uint32(now.div(1 days));

        emit productCreated(address(productAddress), _productName1, _productName2, _creatorCut, _buyerMultiplier, _productPrice);
    }

    function deleteProduct(address payable _productAddress) public {
        require(((now.div(1 days)) >= (product[_productAddress].dayOfLastActivity.add(182))) ||
        ((product[_productAddress].creator == msg.sender) && (product[_productAddress].totalPaid == 0)));
        // remove product from linked list
        productPrev[productNext[_productAddress]] =
        productPrev[productPrev[productNext[_productAddress]]];
        productNext[productPrev[_productAddress]] =
        productNext[productNext[productPrev[_productAddress]]];
        delete productNext[_productAddress];
        delete productPrev[_productAddress];
        // Delete buyer mappings from product
        address buyerToDelete = address(0);
        address buyerToDeleteNext = product[_productAddress].buyer[buyerToDelete].buyerNext;
        buyerToDelete = buyerToDeleteNext;
        buyerToDeleteNext = product[_productAddress].buyer[buyerToDelete].buyerNext;
        do {
            delete product[_productAddress].buyer[buyerToDelete];
            buyerToDelete = buyerToDeleteNext;
            buyerToDeleteNext = product[_productAddress].buyer[buyerToDelete].buyerNext;
        } while(buyerToDeleteNext != address(0));
        // Set totalPaid to 0 for re-entrancy protection
        product[_productAddress].totalPaid = 0;
        product[_productAddress].totalAtLeftoverUpdate = 0;
        // pay creator with any leftover funds
        ProductStorage PS = ProductStorage(_productAddress);
        PS.payTo(address(PS).balance, product[_productAddress].creator);
        // delete product struct
        delete product[_productAddress];
        // delete product contract
        PS.close();

        emit productDeleted(_productAddress);
    }

    // Used for buying a product then calls function to pay dividend to other buyers.
    function buyProduct(address payable _productAddress, address payable _buyerAddress, uint _value) external nonReentrant {
        require(product[_productAddress].creator != address(0));
        require(_value >= product[_productAddress].productPrice);
        require(msg.sender == _productAddress);

        uint contributionValue;
        contributionValue = _value.mul((uint8(100).sub(product[_productAddress].creatorCut).sub(3)));
        contributionValue = contributionValue.div(100);

        if (product[_productAddress].buyer[_buyerAddress].contribution == 0) {
            // Buyer had not bought this product before.
            if (product[_productAddress].buyer[address(0)].buyerNext == address(0)) {
                // First ever buyer of this product.
                product[_productAddress].buyer[address(0)].buyerNext = _buyerAddress;
                product[_productAddress].buyer[address(0)].buyerPrev = _buyerAddress;
            } else {
                product[_productAddress].buyer[
                    product[_productAddress].buyer[address(0)].buyerPrev
                ].buyerNext = _buyerAddress;
                product[_productAddress].buyer[_buyerAddress].buyerPrev = product[_productAddress].buyer[address(0)].buyerPrev;
                product[_productAddress].buyer[address(0)].buyerPrev = _buyerAddress;
            }

            // Record product total for first time buyer
            product[_productAddress].buyer[_buyerAddress].totalAtPurchase = product[_productAddress].totalPaid;

        } else {
            // Buyer has purchased this product before.
            uint _newTotalAtPurchase;
            _newTotalAtPurchase = product[_productAddress].totalPaid.sub(product[_productAddress].buyer[_buyerAddress].totalAtPurchase);
            _newTotalAtPurchase = _newTotalAtPurchase.sub(product[_productAddress].buyer[_buyerAddress].contribution);
            _newTotalAtPurchase = _newTotalAtPurchase.mul(contributionValue);
            _newTotalAtPurchase = _newTotalAtPurchase.div(product[_productAddress].buyer[_buyerAddress].contribution.add(contributionValue));
            _newTotalAtPurchase = _newTotalAtPurchase.add(product[_productAddress].buyer[_buyerAddress].totalAtPurchase);
            product[_productAddress].buyer[_buyerAddress].totalAtPurchase = _newTotalAtPurchase;
        }
        // Add buyer contribution value
        product[_productAddress].buyer[_buyerAddress].contribution = product[_productAddress].buyer[_buyerAddress].contribution.add(contributionValue);

        // Add contribution to the total product contribution
        product[_productAddress].totalPaid = product[_productAddress].totalPaid.add(contributionValue);

        // Update day of last activity for product
        product[_productAddress].dayOfLastActivity = uint32(now.div(1 days));

        // Pay creator cut every random number of transactions
        uint randomPayCreator;
        if (randomPayCreatorOnceEvery > 0) {
            randomPayCreator = uint(keccak256(abi.encodePacked(now, _productAddress))) % randomPayCreatorOnceEvery;
        }
        if ((randomPayCreator == 1) || (randomPayCreatorOnceEvery == 1)) {
            payCreatorCut(_productAddress);
        } else {
            randomPayCreator = 0;
        }

        // Pay dividend to previous buyers
        if (numberOfAddressesToPay > 0) {
            uint8 _didPay;
            address payable _buyerNext = product[_productAddress].buyerNextPayout;
            address payable _buyerPrev = product[_productAddress].buyerPrevPayout;
            // Cycle in both direction of previous buyers to pay out
            for (uint i = 0; i < (numberOfAddressesToPay.sub(randomPayCreator)); i++) {
                _didPay = 0;
                if (uint(keccak256(abi.encodePacked(now, _productAddress, i))) % 2 == 1) {
                    _buyerNext = product[_productAddress].buyer[_buyerNext].buyerNext;
                    if(_buyerNext != address(0)) {
                        _didPay = payDividendToBuyer(_productAddress, _buyerNext);
                    }
                } else {
                    _buyerPrev = product[_productAddress].buyer[_buyerPrev].buyerPrev;
                    if(_buyerPrev != address(0)) {
                        _didPay = payDividendToBuyer(_productAddress, _buyerPrev);
                    }
                }
                i += _didPay;
            }
            product[_productAddress].buyerNextPayout = _buyerNext;
            product[_productAddress].buyerPrevPayout = _buyerPrev;
        }

        emit productBought(_productAddress, _buyerAddress, product[_productAddress].totalPaid, product[_productAddress].buyer[_buyerAddress].totalAtPurchase);
    }

    // Pay dividend to buyer
    function payDividendToBuyer(address payable _productAddress, address payable _buyerAddress) public returns (uint8 didPay) {
        didPay = 0;
        if (product[_productAddress].buyer[_buyerAddress].contribution > 0) {
            uint totalPaidAdjusted = product[_productAddress].totalPaid.add(product[_productAddress].leftoverDividend.mul(product[_productAddress].totalPaid.sub(product[_productAddress].totalAtLeftoverUpdate)).div(product[_productAddress].totalPaid));
            uint dividend = product[_productAddress].buyer[_buyerAddress].totalAtPurchase.div(2);
            dividend = dividend.add(product[_productAddress].buyer[_buyerAddress].contribution.div(4));
            dividend = dividend.mul(product[_productAddress].multiplier.mul(105)).div(100 - product[_productAddress].creatorCut - 3);
            if (totalPaidAdjusted > dividend) {
                dividend = totalPaidAdjusted.sub(dividend);
                dividend = dividend.mul(product[_productAddress].buyer[_buyerAddress].contribution);
                dividend = dividend.div(totalPaidAdjusted);
                dividend = dividend.mul(product[_productAddress].multiplier.mul(105)).div(100 - product[_productAddress].creatorCut - 3);
                if (dividend > product[_productAddress].buyer[_buyerAddress].dividendPaid) { // buyer has some dividend owing. pay the buyer
                    dividend = dividend.sub(product[_productAddress].buyer[_buyerAddress].dividendPaid);
                    product[_productAddress].buyer[_buyerAddress].dividendPaid = product[_productAddress].buyer[_buyerAddress].dividendPaid.add(dividend);
                    ProductStorage PS = ProductStorage(_productAddress);
                    if (PS.payTo(dividend, _buyerAddress)) {
                        didPay = 1;
                    } else {
                        product[_productAddress].buyer[_buyerAddress].dividendPaid = product[_productAddress].buyer[_buyerAddress].dividendPaid.sub(dividend);
                        didPay = 0;
                    }
                }
            } else didPay = 0;
            // check if buyer's dividend is paid out past the multiplier limit
            uint maximumToBePaid = product[_productAddress].buyer[_buyerAddress].contribution.mul(product[_productAddress].multiplier.mul(100)).div(100 - product[_productAddress].creatorCut - 3);
            // check if buyer should be closed out
            if (product[_productAddress].buyer[_buyerAddress].dividendPaid >= maximumToBePaid) {  // pay back  multiplier amount before closing out buyer
                // move remaining funds to a side pot
                uint originalLeftoverDividend = product[_productAddress].leftoverDividend;
                maximumToBePaid = maximumToBePaid.mul(105).div(100);
                product[_productAddress].leftoverDividend = originalLeftoverDividend.add(maximumToBePaid).sub(product[_productAddress].buyer[_buyerAddress].dividendPaid);
                product[_productAddress].totalAtLeftoverUpdate = (product[_productAddress].totalAtLeftoverUpdate.mul(originalLeftoverDividend).div(product[_productAddress].leftoverDividend)).add((product[_productAddress].totalPaid.mul(maximumToBePaid.sub(product[_productAddress].buyer[_buyerAddress].dividendPaid)).div(product[_productAddress].leftoverDividend)));
                // delete buyer details
                deleteBuyer(_productAddress, _buyerAddress);
                emit buyerClosed(_productAddress, _buyerAddress);
            }

        }
        return didPay;
    }

    // Pay the creator's cut as per the percentage cut specified in the product
    function payCreatorCut(address payable _productAddress) public {
        uint payCreatorAmount = product[_productAddress].totalPaid.div(100 - product[_productAddress].creatorCut - 3);
        payCreatorAmount = payCreatorAmount.mul(product[_productAddress].creatorCut);
        payCreatorAmount = payCreatorAmount.sub(product[_productAddress].creatorPaidAmount);
        product[_productAddress].creatorPaidAmount = product[_productAddress].creatorPaidAmount.add(payCreatorAmount);
        ProductStorage PS = ProductStorage(_productAddress);
        PS.payTo(payCreatorAmount, product[_productAddress].creator);
    }

    // Pay the owner's cut
    function payOwnerCut(address payable _productAddress) public {
        uint payOwnerAmount = product[_productAddress].totalPaid.div(100 - product[_productAddress].creatorCut - 3);
        payOwnerAmount = payOwnerAmount.mul(3);
        payOwnerAmount = payOwnerAmount.sub(product[_productAddress].ownerPaidAmount);
        product[_productAddress].ownerPaidAmount = product[_productAddress].creatorPaidAmount.add(payOwnerAmount);
        ProductStorage PS = ProductStorage(_productAddress);
        PS.payTo(payOwnerAmount, owner());
    }

    // Delete a buyer from ProductStorage, close the mapping link gap
    function deleteBuyer(address _productAddress, address _buyerAddress) private {
        product[_productAddress].buyer[
            product[_productAddress].buyer[_buyerAddress].buyerNext
        ].buyerPrev =
        product[_productAddress].buyer[
            product[_productAddress].buyer[
                product[_productAddress].buyer[_buyerAddress].buyerNext
            ].buyerPrev
        ].buyerPrev;

        product[_productAddress].buyer[
            product[_productAddress].buyer[_buyerAddress].buyerPrev
        ].buyerNext =
        product[_productAddress].buyer[
            product[_productAddress].buyer[
                product[_productAddress].buyer[_buyerAddress].buyerPrev
            ].buyerNext
        ].buyerNext;

        delete product[_productAddress].buyer[_buyerAddress];
    }
}

contract ProductStorage {

    CreateBuyDistribute public CBD;

    constructor() public {
        CBD = CreateBuyDistribute(msg.sender);
    }

    function () external payable {
        CBD.buyProduct(address(this), msg.sender, msg.value);
    }

    function payFrom(address payable _fromAddress) external payable {
        CBD.buyProduct(address(this), _fromAddress, msg.value);
    }

    function payTo(uint _value,address payable _address) external returns (bool transferred) {
        require(msg.sender == address(CBD));
        if (!_address.send(_value)) {
            return false;
        } else return true;
    }

    function close() public {
        require(msg.sender == address(CBD));
        selfdestruct(CBD.getCreatorAddress(address(this)));
    }
}
"},"Ownable.sol":{"content":"pragma solidity ^0.5.8;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address payable) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipTransferred(_owner, address(0));
//     _owner = address(0);
//   }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
"},"ReentrancyGuard.sol":{"content":"pragma solidity ^0.5.8;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2Ï.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}
"},"SafeMath.sol":{"content":"pragma solidity ^0.5.8;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    // function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    //     require(b != 0);
    //     return a % b;
    // }
}
"}}