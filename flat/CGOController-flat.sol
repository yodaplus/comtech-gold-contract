// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: UNLICESNED
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;

  function blacklistUpdate(address user, bool value) external;

  function transferOwnership(address newOwner) external;

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

// File @openzeppelin/contracts/GSN/Context.sol@v3.2.0-solc-0.7

pragma solidity ^0.7.0;

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

// File @openzeppelin/contracts/access/Ownable.sol@v3.2.0-solc-0.7

pragma solidity ^0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File contracts/CGOController.sol

pragma solidity >=0.7.0 <0.8.0;

// For Remix Deployment
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0-solc-0.7/contracts/access/Ownable.sol";

contract CGOController is Ownable {
  address public tokenAddr; // CGO token address

  address public initiatorAddr; // Initiator address

  address public executorAddr; // Executor address

  address public minterWalletAddr; // Minter wallet address

  bool public isEditBarPaused = false; // Edit Bar status

  // Transaction status for Bar [Not Exist, Mint Initiated, Mint Completed, Burn Initiated, Burn Completed]
  enum txnStatus {
    NOT_EXIST,
    MINT_INITIATED,
    MINT_COMPLETED,
    BURN_INITIATED,
    BURN_COMPLETED
  }

  // Store Bar Details
  // BarNumber => WarrantNumber
  mapping(string => string) public barNumWarrantNum;

  // Store txn status for Bar
  // BarNumber => WarrantNumber
  mapping(string => mapping(string => txnStatus)) public txnStatusRecord;

  // events
  event BarMint(
    address to,
    uint256 amount,
    string Bar_Number,
    string Warrant_Number,
    uint256 blockTimestamp
  );

  event BarBurn(
    address burn_from,
    uint256 amount,
    string Bar_Number,
    string Warrant_Number,
    uint256 blockTimestamp
  );

  event WithdrawFunds(address to, uint256 amount, uint256 blockTimestamp);

  event BarAdded(
    string Bar_Number,
    string Warrant_Number,
    uint256 blockTimestamp
  );

  event EditBarStatusPaused(bool status);

  event MintInitiated(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status,
    uint256 blockTimestamp
  );

  event BurnInitiated(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status,
    uint256 blockTimestamp
  );

  event MintCancelled(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status,
    uint256 blockTimestamp
  );

  event BurnCancelled(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status,
    uint256 blockTimestamp
  );

  // Set token address and initiator address on contract creation
  constructor(address _tokenAddr) {
    if (_tokenAddr == address(0)) {
      revert("Invalid address");
    }
    tokenAddr = _tokenAddr;
    initiatorAddr = msg.sender;
    executorAddr = msg.sender;
    minterWalletAddr = msg.sender;
  }

  // Modifier - only Initiator
  modifier onlyInitiator() {
    if (msg.sender != initiatorAddr) {
      revert("Only Initiator can call this function");
    }
    _;
  }

  // Modifier - only Executor
  modifier onlyExecutor() {
    if (msg.sender != executorAddr) {
      revert("Only Executor can call this function");
    }
    _;
  }

  // set initiator address
  function setInitiatorAddr(address _initiatorAddr) external onlyOwner {
    if (_initiatorAddr == address(0)) {
      revert("Invalid address");
    }
    initiatorAddr = _initiatorAddr;
  }

  // set executor address
  function setExecutorAddr(address _executorAddr) external onlyOwner {
    if (_executorAddr == address(0)) {
      revert("Invalid address");
    }
    executorAddr = _executorAddr;
  }

  // set minter wallet address
  function setMinterWalletAddr(address _minterWalletAddr) external onlyOwner {
    if (_minterWalletAddr == address(0)) {
      revert("Invalid address");
    }
    minterWalletAddr = _minterWalletAddr;
  }

  // initiate mint with bar details (Bar_Number, Warrant_Number)
  function initiateMint(string memory Bar_Number, string memory Warrant_Number)
    external
    onlyInitiator
  {
    // check for burn initiation OR complete request
    if (
      (txnStatusRecord[Bar_Number][Warrant_Number] ==
        txnStatus.BURN_INITIATED) ||
      (txnStatusRecord[Bar_Number][Warrant_Number] == txnStatus.BURN_COMPLETED)
    ) {
      revert("Burn request exist for this Bar");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    // check inititation request
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] == txnStatus.MINT_INITIATED
    ) {
      revert("Mint initiation request already exist");
    }

    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.MINT_INITIATED;
    emit MintInitiated(
      Bar_Number,
      Warrant_Number,
      txnStatus.MINT_INITIATED,
      block.timestamp
    );
  }

  // cancel Initiate mint request
  function cancelInitiateMint(
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyExecutor {
    // check for burn initiation OR complete request
    if (
      (txnStatusRecord[Bar_Number][Warrant_Number] ==
        txnStatus.BURN_INITIATED) ||
      (txnStatusRecord[Bar_Number][Warrant_Number] == txnStatus.BURN_COMPLETED)
    ) {
      revert("Burn request exist for this Bar");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    // check inititation request
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.MINT_INITIATED
    ) {
      revert("Mint initiation request not exist");
    }

    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.NOT_EXIST;
    emit MintCancelled(
      Bar_Number,
      Warrant_Number,
      txnStatus.NOT_EXIST,
      block.timestamp
    );
  }

  // Execute mint with bar details (Bar_Number, Warrant_Number)
  // Call mint function of CGO token contract using ERC20 interface
  function mint(
    address to,
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyExecutor {
    // mint function call on CGO token contract
    if (to != minterWalletAddr || to == address(0)) {
      revert("Invalid Mint address");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.MINT_INITIATED
    ) {
      revert("Mint initiation request not exist");
    }
    if (amount != 1000) {
      revert("Mint amount should be 1000");
    }
    barNumWarrantNum[Bar_Number] = Warrant_Number;
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.MINT_COMPLETED;
    emit BarMint(
      to,
      amount * 1e18,
      Bar_Number,
      Warrant_Number,
      block.timestamp
    );
    IERC20(tokenAddr).mint(to, amount * 1e18);
  }

  // initiate burn with bar details (Bar_Number, Warrant_Number)
  function initiateBurn(string memory Bar_Number, string memory Warrant_Number)
    external
    onlyInitiator
  {
    // check inititation request
    if (IERC20(tokenAddr).balanceOf(address(this)) < 1000 * 1e18) {
      revert("Insufficient CGO Balance");
    }
    if (
      (txnStatusRecord[Bar_Number][Warrant_Number] ==
        txnStatus.BURN_INITIATED) ||
      (txnStatusRecord[Bar_Number][Warrant_Number] == txnStatus.BURN_COMPLETED)
    ) {
      revert("Burn request already exist");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) !=
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Incorrect Bar details");
    }
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.MINT_COMPLETED
    ) {
      revert("Mint request not exist");
    }
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.BURN_INITIATED;
    emit BurnInitiated(
      Bar_Number,
      Warrant_Number,
      txnStatus.BURN_INITIATED,
      block.timestamp
    );
  }

  // cancel Initiate burn request
  function cancelInitiateBurn(
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyExecutor {
    // check inititation request
    // if (IERC20(tokenAddr).balanceOf(address(this)) < 1000 * 1e18) {
    //   revert("Insufficient CGO Balance");
    // }
    if (
      (txnStatusRecord[Bar_Number][Warrant_Number] !=
        txnStatus.BURN_INITIATED) &&
      (txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.BURN_COMPLETED)
    ) {
      revert("Burn request not exist");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) !=
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Incorrect Bar details");
    }
    // if (
    //   txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.MINT_COMPLETED
    // ) {
    //   revert("Mint request not exist");
    // }
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.MINT_COMPLETED;
    emit BurnCancelled(
      Bar_Number,
      Warrant_Number,
      txnStatus.MINT_COMPLETED,
      block.timestamp
    );
  }

  // burn implementation with bar details (Bar_Number, Warrant_Number)
  // Call burn function of CGO token contract using ERC20 interface
  function burn(
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyExecutor {
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) !=
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Incorrect Bar details");
    }
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.BURN_INITIATED
    ) {
      revert("Burn initiation request not exist");
    }
    if (amount != 1000) {
      revert("Burn amount should be 1000");
    }
    if (IERC20(tokenAddr).balanceOf(address(this)) < amount * 1e18) {
      revert("Insufficient CGO Balance");
    }
    // burn function call on CGO token contract
    delete barNumWarrantNum[Bar_Number];
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.BURN_COMPLETED;
    emit BarBurn(
      address(this),
      amount * 1e18,
      Bar_Number,
      Warrant_Number,
      block.timestamp
    );
    IERC20(tokenAddr).burn(amount * 1e18);
  }

  // Blacklist update function call on CGO token contract
  function blacklistUpdate(address user, bool value)
    external
    virtual
    onlyOwner
  {
    IERC20(tokenAddr).blacklistUpdate(user, value);
  }

  // Add Bar Details (Bar_Number, Warrant_Number) for existing tokens in market
  // This function will be use for onboarding Existing Bars
  // This function will be depreciated after onboarding all existing bars
  function addBarNumWarrantNum(
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyOwner {
    if (isEditBarPaused == true) {
      revert("Manual Bar Insertion is restricted");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    barNumWarrantNum[Bar_Number] = Warrant_Number;
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.MINT_COMPLETED;
    emit BarAdded(Bar_Number, Warrant_Number, block.timestamp);
  }

  // Remove Bar Details (Bar_Number, Warrant_Number) for existing tokens in market
  // This function will be use for onboarding Existing Bars
  // This function will be depreciated after onboarding all existing bars
  function removeBarNumWarrantNum(
    string memory Bar_Number,
    string memory Warrant_Number
  ) external onlyOwner {
    if (isEditBarPaused == true) {
      revert("Manual Bar Removal is restricted");
    }
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) !=
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Incorrect Bar details");
    }
    delete barNumWarrantNum[Bar_Number];
    delete txnStatusRecord[Bar_Number][Warrant_Number];
  }

  // Pause/Unpause Edit Bar functionality
  // This function will be use for onboarding Existing Bars
  // This function will be depreciated after onboarding all existing bars
  function pauseEditBar(bool status) external onlyOwner {
    isEditBarPaused = status;
    emit EditBarStatusPaused(status);
  }

  // Withdraw CGO tokens from contract to owner address using ERC20 interface
  function withdrawFunds(address to, uint256 amount) external onlyOwner {
    emit WithdrawFunds(to, amount, block.timestamp);
    IERC20(tokenAddr).transfer(to, amount);
  }

  // Transfer ownership of CGO token contract to new owner using ERC20 interface
  function transferCgoOwnership(address newOwner) external onlyOwner {
    IERC20(tokenAddr).transferOwnership(newOwner);
  }
}
