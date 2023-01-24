// SPDX-License-Identifier: UNLICESNED

pragma solidity >=0.7.0 <0.8.0;

import "./interfaces/IERC20.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0-solc-0.7/contracts/access/Ownable.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.2.0-solc-0.7/contracts/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "hardhat/console.sol";

contract CGOController is Initializable, OwnableUpgradeable {
  using AddressUpgradeable for address;

  address public tokenAddr; // CGO token address

  address public initiatorAddr; // Initiator address

  address public executorAddr; // Executor address

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
    string Warrant_Number
  );

  event BarBurn(
    address burn_from,
    uint256 amount,
    string Bar_Number,
    string Warrant_Number
  );

  event WithdrawFunds(address to, uint256 amount);

  event BarAdded(string Bar_Number, string Warrant_Number);

  event EditBarStatusPaused(bool status);

  event MintInitiated(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status
  );

  event BurnInitiated(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status
  );

  event MintCancelled(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status
  );

  event BurnCancelled(
    string Bar_Number,
    string Warrant_Number,
    txnStatus status
  );

  // Set token address and initiator address on contract creation
  function initialize(address _tokenAddr) public initializer {
    tokenAddr = _tokenAddr;
    initiatorAddr = msg.sender;
    __Ownable_init();
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
  function setInitiatorAddr(address _initiatorAddr) public onlyOwner {
    initiatorAddr = _initiatorAddr;
  }

  // set executor address
  function setExecutorAddr(address _executorAddr) public onlyOwner {
    executorAddr = _executorAddr;
  }

  // initiate mint with bar details (Bar_Number, Warrant_Number)
  function initiateMint(string memory Bar_Number, string memory Warrant_Number)
    public
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
    emit MintInitiated(Bar_Number, Warrant_Number, txnStatus.MINT_INITIATED);
  }

  // cancel Initiate mint request
  function cancelInitiateMint(
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyExecutor {
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
    emit MintCancelled(Bar_Number, Warrant_Number, txnStatus.NOT_EXIST);
  }

  // Execute mint with bar details (Bar_Number, Warrant_Number)
  // Call mint function of CGO token contract using ERC20 interface
  function mint(
    address to,
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyExecutor {
    // mint function call on CGO token contract
    IERC20(tokenAddr).mint(to, amount * 1e18);
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
    emit BarMint(to, amount * 1e18, Bar_Number, Warrant_Number);
  }

  // initiate burn with bar details (Bar_Number, Warrant_Number)
  function initiateBurn(string memory Bar_Number, string memory Warrant_Number)
    public
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
    emit BurnInitiated(Bar_Number, Warrant_Number, txnStatus.BURN_INITIATED);
  }

  // cancel Initiate burn request
  function cancelInitiateBurn(
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyExecutor {
    // check inititation request
    if (IERC20(tokenAddr).balanceOf(address(this)) < 1000 * 1e18) {
      revert("Insufficient CGO Balance");
    }
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
    emit BurnCancelled(Bar_Number, Warrant_Number, txnStatus.MINT_COMPLETED);
  }

  // burn implementation with bar details (Bar_Number, Warrant_Number)
  // Call burn function of CGO token contract using ERC20 interface
  function burn(
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyExecutor {
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
    IERC20(tokenAddr).burn(amount * 1e18);
    delete barNumWarrantNum[Bar_Number];
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.BURN_COMPLETED;
    emit BarBurn(address(this), amount * 1e18, Bar_Number, Warrant_Number);
  }

  // Blacklist update function call on CGO token contract
  function blacklistUpdate(address user, bool value) public virtual onlyOwner {
    IERC20(tokenAddr).blacklistUpdate(user, value);
  }

  // Add Bar Details (Bar_Number, Warrant_Number) for existing tokens in market
  // This function will be use for onboarding Existing Bars
  // This function will be depreciated after onboarding all existing bars
  function addBarNumWarrantNum(
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyOwner {
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
    emit BarAdded(Bar_Number, Warrant_Number);
  }

  // Remove Bar Details (Bar_Number, Warrant_Number) for existing tokens in market
  // This function will be use for onboarding Existing Bars
  // This function will be depreciated after onboarding all existing bars
  function removeBarNumWarrantNum(
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyOwner {
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
  function pauseEditBar(bool status) public onlyOwner {
    isEditBarPaused = status;
    emit EditBarStatusPaused(status);
  }

  // Withdraw CGO tokens from contract to owner address using ERC20 interface
  function withdrawFunds(address to, uint256 amount) public onlyOwner {
    IERC20(tokenAddr).transfer(to, amount);
    emit WithdrawFunds(to, amount);
  }

  // Transfer ownership of CGO token contract to new owner using ERC20 interface
  function transferCgoOwnership(address newOwner) public onlyOwner {
    IERC20(tokenAddr).transferOwnership(newOwner);
  }
}
