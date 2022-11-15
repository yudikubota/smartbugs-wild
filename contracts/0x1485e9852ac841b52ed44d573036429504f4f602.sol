{"Bridge.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./MasterToken.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

/**
 * Provides functionality of the HASHI bridge
 */
contract Bridge {
    bool internal initialized_;
    bool internal preparedForMigration_;

    mapping(address => bool) public isPeer;
    uint public peersCount;

    /** Substrate proofs used */
    mapping(bytes32 => bool) public used;
    mapping(address => bool) public _uniqueAddresses;

    /** White list of ERC-20 ethereum native tokens */
    mapping(address => bool) public acceptedEthTokens;

    /** White lists of ERC-20 SORA native tokens
    * We use several representations of the white list for optimisation purposes.
    */
    mapping(bytes32 => address) public _sidechainTokens;
    mapping(address => bytes32) public _sidechainTokensByAddress;
    address[] public _sidechainTokenAddressArray;

    event Withdrawal(bytes32 txHash);
    event Deposit(bytes32 destination, uint amount, address token, bytes32 sidechainAsset);
    event ChangePeers(address peerId, bool removal);
    event PreparedForMigration();
    event Migrated(address to);

    /**
     * For XOR and VAL use old token contracts, created for SORA 1 bridge.
     * Also for XOR and VAL transfers from SORA 2 to Ethereum old bridges will be used.
     */
    address public _addressVAL;
    address public _addressXOR;
    /** EVM netowrk ID */
    bytes32 public _networkId;

    /**
     * Constructor.
     * @param initialPeers - list of initial bridge validators on substrate side.
     * @param addressVAL address of VAL token Contract
     * @param addressXOR address of XOR token Contract
     * @param networkId id of current EvM network used for bridge purpose.
     */
    constructor(
        address[] memory initialPeers,
        address addressVAL,
        address addressXOR,
        bytes32 networkId)  {
        for (uint8 i = 0; i < initialPeers.length; i++) {
            addPeer(initialPeers[i]);
        }
        _addressXOR = addressXOR;
        _addressVAL = addressVAL;
        _networkId = networkId;
        initialized_ = true;
        preparedForMigration_ = false;

        acceptedEthTokens[_addressXOR] = true;
        acceptedEthTokens[_addressVAL] = true;
    }

    modifier shouldBeInitialized {
        require(initialized_ == true, "Contract should be initialized to use this function");
        _;
    }

    modifier shouldNotBePreparedForMigration {
        require(preparedForMigration_ == false, "Contract should not be prepared for migration to use this function");
        _;
    }

    modifier shouldBePreparedForMigration {
        require(preparedForMigration_ == true, "Contract should be prepared for migration to use this function");
        _;
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }
    
    /*
    Used only for migration
    */
    function receivePayment() external payable {}

    /**
     * Adds new token to whitelist.
     * Token should not been already added.
     *
     * @param newToken new token contract address
     * @param ticker token ticker (symbol)
     * @param name token title
     * @param decimals count of token decimal places
     * @param txHash transaction hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addEthNativeToken(
        address newToken,
        string memory ticker,
        string memory name,
        uint8 decimals,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized {
        require(used[txHash] == false);
        require(acceptedEthTokens[newToken] == false);
        require(checkSignatures(keccak256(abi.encodePacked(newToken, ticker, name, decimals, txHash, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        acceptedEthTokens[newToken] = true;
        used[txHash] = true;
    }

    /**
     * Preparations for migration to new Bridge contract
     *
     * @param thisContractAddress address of this bridge contract
     * @param salt unique data used for signature
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function prepareForMigration(
        address thisContractAddress,
        bytes32 salt,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized shouldNotBePreparedForMigration {
        require(preparedForMigration_ == false);
        require(address(this) == thisContractAddress);
        require(checkSignatures(keccak256(abi.encodePacked(thisContractAddress, salt, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        preparedForMigration_ = true;
        emit PreparedForMigration();
    }

    /**
    * Shutdown this contract and migrate tokens ownership to the new contract.
    *
    * @param thisContractAddress this bridge contract address
    * @param salt unique data used for signature generation
    * @param newContractAddress address of the new bridge contract
    * @param erc20nativeTokens list of ERC20 tokens with non zero balances for this contract. Can be taken from substrate bridge peers.
    * @param v array of signatures of tx_hash (v-component)
    * @param r array of signatures of tx_hash (r-component)
    * @param s array of signatures of tx_hash (s-component)
    */
    function shutDownAndMigrate(
        address thisContractAddress,
        bytes32 salt,
        address payable newContractAddress,
        address[] calldata erc20nativeTokens,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized shouldBePreparedForMigration {
        require(address(this) == thisContractAddress);
        require(checkSignatures(keccak256(abi.encodePacked(thisContractAddress, newContractAddress, salt, erc20nativeTokens, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        for (uint i = 0; i < _sidechainTokenAddressArray.length; i++) {
            Ownable token = Ownable(_sidechainTokenAddressArray[i]);
            token.transferOwnership(newContractAddress);
        }
        for (uint i = 0; i < erc20nativeTokens.length; i++) {
            IERC20 token = IERC20(erc20nativeTokens[i]);
            token.transfer(newContractAddress, token.balanceOf(address(this)));
        }
        Bridge(newContractAddress).receivePayment{value: address(this).balance}();
        initialized_ = false;
        emit Migrated(newContractAddress);
    }

    /**
    * Add new token from sidechain to the bridge white list.
    *
    * @param name token title
    * @param symbol token symbol
    * @param decimals number of decimals
    * @param sidechainAssetId token id on the sidechain
    * @param txHash sidechain transaction hash
    * @param v array of signatures of tx_hash (v-component)
    * @param r array of signatures of tx_hash (r-component)
    * @param s array of signatures of tx_hash (s-component)
    */
    function addNewSidechainToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes32 sidechainAssetId,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s)
    public shouldBeInitialized {
        require(used[txHash] == false);
        require(checkSignatures(keccak256(abi.encodePacked(
                name,
                symbol,
                decimals,
                sidechainAssetId,
                txHash,
                _networkId
            )),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        // Create new instance of the token
        MasterToken tokenInstance = new MasterToken(name, symbol, decimals, address(this), 0, sidechainAssetId);
        address tokenAddress = address(tokenInstance);
        _sidechainTokens[sidechainAssetId] = tokenAddress;
        _sidechainTokensByAddress[tokenAddress] = sidechainAssetId;
        _sidechainTokenAddressArray.push(tokenAddress);
        used[txHash] = true;
    }

    /**
    * Send Ethereum to sidechain.
    *
    * @param to destionation address on sidechain.
    */
    function sendEthToSidechain(
        bytes32 to
    )
    public
    payable
    shouldBeInitialized shouldNotBePreparedForMigration {
        require(msg.value > 0, "ETH VALUE SHOULD BE MORE THAN 0");
        bytes32 empty;
        emit Deposit(to, msg.value, address(0x0), empty);
    }

    /**
     * Send ERC-20 token to sidechain.
     *
     * @param to destination address on the sidechain
     * @param amount amount to sendERC20ToSidechain
     * @param tokenAddress contract address of token to send
     */
    function sendERC20ToSidechain(
        bytes32 to,
        uint amount,
        address tokenAddress)
    external
    shouldBeInitialized shouldNotBePreparedForMigration {
        IERC20 token = IERC20(tokenAddress);

        require(token.allowance(msg.sender, address(this)) >= amount, "NOT ENOUGH DELEGATED TOKENS ON SENDER BALANCE");

        bytes32 sidechainAssetId = _sidechainTokensByAddress[tokenAddress];
        if (sidechainAssetId != "" || _addressVAL == tokenAddress || _addressXOR == tokenAddress) {
            ERC20Burnable mtoken = ERC20Burnable(tokenAddress);
            mtoken.burnFrom(msg.sender, amount);
        } else {
            require(acceptedEthTokens[tokenAddress], "The Token is not accepted for transfer to sidechain");
            token.transferFrom(msg.sender, address(this), amount);
        }
        emit Deposit(to, amount, tokenAddress, sidechainAssetId);
    }

    /**
     * Add new peer using peers quorum.
     *
     * @param newPeerAddress address of the peer to add
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addPeerByPeer(
        address newPeerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized
    returns (bool)
    {
        require(used[txHash] == false);
        require(checkSignatures(keccak256(abi.encodePacked(newPeerAddress, txHash, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );

        addPeer(newPeerAddress);
        used[txHash] = true;
        emit ChangePeers(newPeerAddress, false);
        return true;
    }

    /**
     * Remove peer using peers quorum.
     *
     * @param peerAddress address of the peer to remove
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function removePeerByPeer(
        address peerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized
    returns (bool)
    {
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(peerAddress, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        removePeer(peerAddress);
        used[txHash] = true;
        emit ChangePeers(peerAddress, true);
        return true;
    }

    /**
     * Withdraws specified amount of ether or one of ERC-20 tokens to provided sidechain address
     * @param tokenAddress address of token to withdraw (0 for ether)
     * @param amount amount of tokens or ether to withdraw
     * @param to target account address
     * @param txHash hash of transaction from sidechain
     * @param from source of transfer
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveByEthereumAssetAddress(
        address tokenAddress,
        uint256 amount,
        address payable to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized
    {
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(tokenAddress, amount, to, from, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        if (tokenAddress == address(0)) {
            used[txHash] = true;
            // untrusted transfer, relies on provided cryptographic proof
            to.transfer(amount);
        } else {
            IERC20 coin = IERC20(tokenAddress);
            used[txHash] = true;
            // untrusted call, relies on provided cryptographic proof
            coin.transfer(to, amount);
        }
        emit Withdrawal(txHash);
    }

    /**
     * Mint new Token
     * @param sidechainAssetId id of sidechainToken to mint
     * @param amount how much to mint
     * @param to destination address
     * @param from sender address
     * @param txHash hash of transaction from Iroha
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveBySidechainAssetId(
        bytes32 sidechainAssetId,
        uint256 amount,
        address to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized
    {
        require(_sidechainTokens[sidechainAssetId] != address(0x0), "Sidechain asset is not registered");
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(sidechainAssetId, amount, to, from, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        MasterToken tokenInstance = MasterToken(_sidechainTokens[sidechainAssetId]);
        tokenInstance.mintTokens(to, amount);
        used[txHash] = true;
        emit Withdrawal(txHash);
    }

    /**
     * Checks given addresses for duplicates and if they are peers signatures
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return true if all given addresses are correct or false otherwise
     */
    function checkSignatures(bytes32 hash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    private
    returns (bool) {
        require(peersCount >= 1);
        require(v.length == r.length);
        require(r.length == s.length);
        uint needSigs = peersCount - (peersCount - 1) / 3;
        require(s.length >= needSigs);

        uint count = 0;
        address[] memory recoveredAddresses = new address[](s.length);
        for (uint i = 0; i < s.length; ++i) {
            address recoveredAddress = recoverAddress(
                hash,
                v[i],
                r[i],
                s[i]
            );

            // not a peer address or not unique
            if (isPeer[recoveredAddress] != true || _uniqueAddresses[recoveredAddress] == true) {
                continue;
            }
            recoveredAddresses[count] = recoveredAddress;
            count = count + 1;
            _uniqueAddresses[recoveredAddress] = true;
        }

        // restore state for future usages
        for (uint i = 0; i < count; ++i) {
            _uniqueAddresses[recoveredAddresses[i]] = false;
        }

        return count >= needSigs;
    }

    /**
     * Recovers address from a given single signature
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return address recovered from signature
     */
    function recoverAddress(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
    private
    pure
    returns (address) {
        bytes32 simple_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address res = ecrecover(simple_hash, v, r, s);
        return res;
    }

    /**
     * Adds new peer to list of signature verifiers.
     * Internal function
     * @param newAddress address of new peer
     */
    function addPeer(address newAddress)
    internal
    returns (uint) {
        require(isPeer[newAddress] == false);
        isPeer[newAddress] = true;
        ++peersCount;
        return peersCount;
    }

    function removePeer(address peerAddress)
    internal {
        require(isPeer[peerAddress] == true);
        isPeer[peerAddress] = false;
        --peersCount;
    }
}"},"ERC20.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}"},"ERC20Burnable.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./ERC20.sol";

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}"},"ERC20Detailed.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    } 

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}"},"IERC20.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}"},"MasterToken.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MasterToken is ERC20Burnable, ERC20Detailed, Ownable {

    bytes32 public _sidechainAssetId;

    /**
     * @dev Constructor that gives the specified address all of existing tokens.
     */
    constructor(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        address beneficiary, 
        uint256 supply,
        bytes32 sidechainAssetId) 
        ERC20Detailed(name, symbol, decimals) {
        _sidechainAssetId = sidechainAssetId;    
        _mint(beneficiary, supply);
        
    }
    
    fallback() external {
        revert();
    }

    function mintTokens(address beneficiary, uint256 amount) public onlyOwner {
        _mint(beneficiary, amount);
    }

}"},"Ownable.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}"},"SafeMath.sol":{"content":"pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"


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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}"}}