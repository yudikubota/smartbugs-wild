{"Crowdsale.sol":{"content":"pragma solidity ^0.5.0;

import "./RHC.sol";

contract Crowdsale {

  /// @dev represents a round of token sale
  struct Round {
    /// @dev price per token for every token
    uint tokenPrice;
    /// @dev total number of tokens available in the round
    uint capacityLeft;
  }
  
  /// @notice event is raised when a token sale occurs
  /// @param amountSent amount of money sent by the purchaser
  /// @param amountReturned amount of money returned to the purchaser in case amount sent was not exact
  /// @param buyer the address which purchased the tokens
  event Sale(uint amountSent, uint amountReturned, uint tokensSold, address buyer);

  /// @notice raised when all tokens are sold out
  event SaleCompleted();

  /// @notice raised when a round completes and the next round starts
  /// @param oldTokenPrice previous price per token
  /// @param newTokenPrice new price per token
  event RoundChanged(uint oldTokenPrice, uint newTokenPrice);

  /// @dev information about rounds of fundraising in the crowdsale
  Round[] private _rounds;
  uint8 private _currentRound;

  /// @notice where the contract wires funds in exchange for tokens
  address payable private wallet;

  /// @notice a refenence to the RHC token being sold
  RHC public token;

  /// @notice reports whether the sale is still open
  bool public isSaleOpen;

  /// @dev how much wei has been raised so far
  uint public weiRaised;

  /// @dev how many tokens have been sold so far
  uint public tokensSold;

  /// @notice creates the crowdsale. Only intended to be used by Robinhood team.
  constructor(address payable targetWallet, uint[] memory roundPrices, uint[] memory roundCapacities,
              address advisors, address founders, address legal, address developers, address reserve) public {
    require(roundPrices.length == roundCapacities.length, "Equal number of round parameters must be specified");
    require(roundPrices.length >= 1, "Crowdsale must have at least one round");
    require(roundPrices.length < 10, "Rounds are limited to 10 at most");

    // store rounds
    _currentRound = 0;
    for (uint i = 0; i < roundPrices.length; i++) {
      _rounds.push(Round(roundPrices[i], roundCapacities[i]));
    }

    wallet = targetWallet;
    isSaleOpen = true;
    weiRaised = 0;
    tokensSold = 0;

    // Create token with this contract as the owner
    token = new RHC(address(this));

    // add target wallet as an additional owner
    token.addAdmin(wallet);

    // Grants future tokens for internal parties. These shares can only be claimed one year
    // after the start of the crowdsale
    uint in12Months = block.timestamp + (1000 * 60 * 60 * 24 * 365);
    // 21.5% reserved for developers
    token.grant(developers, 21500000, in12Months);
    // 5% reserved for advisors
    token.grant(advisors, 5000000, in12Months);
    // 14% reserved for founders
    token.grant(founders, 14000000, in12Months);
    // 7% reserved for future use
    token.grant(reserve, 7000000, in12Months);
    // 8.5% reserved for legal
    token.grant(legal, 8500000, in12Months);
  }

  function() external payable {
    uint amount = msg.value;
    address payable buyer = msg.sender;
    require(amount > 0, "must send money to get tokens");
    require(buyer != address(0), "can't send from address 0");
    require(isSaleOpen, "sale must be open in order to purchase tokens");

    (uint tokenCount, uint change) = calculateTokenCount(amount);

    // if insufficient money is sent, return the buyer's mone
    if (tokenCount == 0) {
      buyer.transfer(change);
      return;
    }

    // this is how much of the money will be consumed by this token purchase
    uint acceptedFunds = amount - change;

    // forward funds to owner
    wallet.transfer(acceptedFunds);

    // return left over (unused) funds back to the sender
    buyer.transfer(change);

    // assign tokens to whoever is purchasing
    token.issue(buyer, tokenCount);

    // update state tracking how much wei has been raised so far
    weiRaised += acceptedFunds;
    tokensSold += tokenCount;

    updateRounds(tokenCount);

    emit Sale(amount, change, tokenCount, buyer);
  }

  /// @notice given an amount of money returns how many tokens the money will result in with the
  /// current round's pricing
  function calculateTokenCount(uint money) public view returns (uint count, uint change) {
    require(isSaleOpen, "sale is no longer open and tokens can't be purchased");

    // get current token price
    uint price = _rounds[_currentRound].tokenPrice;
    uint capacityLeft = _rounds[_currentRound].capacityLeft;

    // money sent must be bigger than or equal the price, otherwise, no purchase is necessary
    if (money < price) {
      // return all the money
      return (0, money);
    }

    count = money / price;
    change = money % price;

    // Ensure there's sufficient capacity in the current round. If the user wishes to
    // purchase more, they can send money again to purchase tokens at the next round
    if (count > capacityLeft) {
      change += price * (count - capacityLeft);
      count = capacityLeft;
    }

    return (count, change);
  }

  /// increases the round or closes the sale if tokens are sold out
  function updateRounds(uint tokens) private {
    Round storage currentRound = _rounds[_currentRound];
    currentRound.capacityLeft -= tokens;

    if (currentRound.capacityLeft <= 0) {
      if (_currentRound == _rounds.length - 1) {
        isSaleOpen = false;
        emit SaleCompleted();
      } else {
        _currentRound++;
        emit RoundChanged(currentRound.tokenPrice, _rounds[_currentRound].tokenPrice);
      }
    }
  }
}"},"EIP20.sol":{"content":"pragma solidity ^0.5.0;

/// ERC20 interface, as defined by Ethereum Improvement Proposals,
/// see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract EIP20 {
    /// this automatically generates the totalSupply() getter required by the ERC20 interface
    /// since it's a public parameter
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with
    /// the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}"},"RHC.sol":{"content":"pragma solidity ^0.5.0;

import './EIP20.sol';

/// @author robinhood.casino
/// @title Robinhood (RHC) ERC20 token
contract RHC is EIP20 {

  /// @notice reports number of tokens that are promised to vest in a future date
  uint256 public pendingGrants;

  /// @notice raised when tokens are issued for an account
  event Issuance(address indexed _beneficiary, uint256 _amount);

  struct Grant {
    /// number of shares in the grant
    uint256 amount;
    /// a linux timestamp of when shares can be claimed
    uint vestTime;
    /// whether the claim has been cancelled by admins
    bool isCancelled;
    /// whether the grant has been claimed by the user
    bool isClaimed;
  }

  /// @dev token balance of all addresses
  mapping (address => uint256) private _balances;

  /// @dev tracks who can spend how much.
  mapping (address => mapping (address => uint256)) private _allowances;

  /// @dev balance of tokens that are not vested yet
  mapping (address => Grant[]) private _grants;

  // used for access management
  address private _owner;
  mapping (address => bool) private _admins;

  constructor(address admin) public {
    _owner = admin;
  }

  /// @notice name of the Robinhood token
  function name() public pure returns (string memory) {
    return "Robinhood";
  }

  /// @notice symbol of the Robinhood token
  function symbol() public pure returns (string memory) {
    return "RHC";
  }

  /// @notice RHC does not allow breaking up of tokens into fractions.
  function decimals() public pure returns (uint8) {
    return 0;
  }

  modifier onlyAdmins() {
    require(msg.sender == _owner || _admins[msg.sender] == true, "only admins can invoke this function");
    _;
  }

  /// @dev registers a new admin
  function addAdmin(address admin) public onlyAdmins() {
    _admins[admin] = true;
  }

  /// @dev removes an existing admin
  function removeAdmin(address admin) public onlyAdmins() {
    require(admin != _owner, "owner can't be removed");
    delete _admins[admin];
  }

  /// @dev Gets the balance of the specified address.
  /// @param owner The address to query the balance of.
  /// @return A uint256 representing the amount owned by the passed address.
  function balanceOf(address owner) public view returns (uint256) {
      return _balances[owner];
  }

  /// @dev Function to check the amount of tokens that an owner allowed to a spender.
  /// @param owner address The address which owns the funds.
  /// @param spender address The address which will spend the funds.
  /// @return A uint256 specifying the amount of tokens still available for the spender.
  function allowance(address owner, address spender) public view returns (uint256) {
      return _allowances[owner][spender];
  }

  /// @dev Transfer token to a specified address.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function transfer(address to, uint256 value) public returns (bool success) {
    require(to != address(0), "Can't transfer tokens to address 0");
    require(balanceOf(msg.sender) >= value, "You don't have sufficient balance to move tokens");

    _move(msg.sender, to, value);

    return true;
  }

  /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
  /// Beware that changing an allowance with this method brings the risk that someone may use both the old
  /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
  /// race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
  /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  /// @param spender The address which will spend the funds.
  /// @param value The amount of tokens to be spent.
  function approve(address spender, uint256 value) public returns (bool success) {
    require(spender != address(0), "Can't set allowance for address 0");
    require(spender != msg.sender, "Use transfer to move your own funds");

    _allowances[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /// @dev Transfer tokens from one address to another.
  /// @param from address The address which you want to send tokens from
  /// @param to address The address which you want to transfer to
  /// @param value uint256 the amount of tokens to be transferred
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(to != address(0), "Can't transfer funds to address 0");

    // Validate that the sender is allowed to move funds on behalf of the owner
    require(allowance(from, msg.sender) >= value, "You're not authorized to transfer funds from this account");
    require(balanceOf(from) >= value, "Owner of funds does not have sufficient balance");

    // Decrease allowance
    _allowances[from][msg.sender] -= value;

    // Move actual token balances
    _move(from, to, value);

    return true;
  }

  /// @notice cancels all grants pending for a given beneficiary. If you want to cancel a single
  /// vest, cancel all pending grants, and reinstate the ones you plan to keep
  function cancelGrants(address beneficiary) public onlyAdmins() {
    Grant[] storage userGrants = _grants[beneficiary];
    for (uint i = 0; i < userGrants.length; i++) {
      Grant storage grant = userGrants[i];
      if (!grant.isCancelled && !grant.isClaimed) {
        grant.isCancelled = true;

        // remove from pending grants
        pendingGrants -= grant.amount;
      }
    }
  }

  /// @notice Converts a vest schedule into actual shares. Must be called by the beneficiary
  // to convert their vests into actual shares
  function claimGrant() public {
    Grant[] storage userGrants = _grants[msg.sender];
    for (uint i = 0; i < userGrants.length; i++) {
      Grant storage grant = userGrants[i];
      if (!grant.isCancelled && !grant.isClaimed && now >= grant.vestTime) {
        grant.isClaimed = true;

        // remove from pending grants
        pendingGrants -= grant.amount;

        // issue tokens to the user
        _issue(msg.sender, grant.amount);
      }
    }
  }

  /// @notice returns information about a grant that user has. Returns a tuple indicating
  /// the amount of the grant, when it will vest, whether it's been cancelled, and whether it's been claimed
  /// already.
  /// @param grantIndex a 0-based index of user's grant to retrieve
  function getGrant(address beneficiary, uint grantIndex) public view returns (uint, uint, bool, bool) {
    Grant[] storage grants = _grants[beneficiary];
    if (grantIndex < grants.length) {
      Grant storage grant = grants[grantIndex];
      return (grant.amount, grant.vestTime, grant.isCancelled, grant.isClaimed);
    } else {
      revert("grantIndex must be smaller than length of grants");
    }
  }

  /// @notice returns number of grants a user has
  function getGrantCount(address beneficiary) public view returns (uint) {
    return _grants[beneficiary].length;
  }

  /// @dev Internal function that increases the token supply by issuing new ones
  /// and assigning them to an owner.
  /// @param account The account that will receive the created tokens.
  /// @param amount The amount that will be created.
  function issue(address account, uint256 amount) public onlyAdmins() {
    require(account != address(0), "can't mint to address 0");
    require(amount > 0, "must issue a positive amount of tokens");
    _issue(account, amount);
  }

  /// @dev Internal function that grants shares to a beneficiary in a future date.
  /// @param vestTime milliseconds since epoch at which time shares can be claimed
  function grant(address account, uint256 amount, uint vestTime) public onlyAdmins() {
    require(account != address(0), "grant to the zero address is not allowed");
    require(vestTime > now, "vest schedule must be in the future");

    pendingGrants += amount;
    _grants[account].push(Grant(amount, vestTime, false, false));
  }

  /// @dev Internal helper to move balances around between two accounts.
  function _move(address from, address to, uint256 value) private {
    _balances[from] -= value;
    _balances[to] += value;
    emit Transfer(from, to, value);
  }

  /// @dev issues/mints new tokens for the specified account
  function _issue(address account, uint256 amount) private {
    totalSupply += amount;
    _balances[account] += amount;
    emit Issuance(account, amount);
  }
}"}}