// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0-solc-0.7/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract CGOController is Ownable {
  address public tokenAddr;

  address public initiatorAddr;

  address public executorAddr;

  bool public isEditBarPaused = false;

  // Transaction status
  enum txnStatus {
    NOT_EXIST,
    MINT_INITIATED,
    MINT_COMPLETED,
    BURN_INITIATED,
    BURN_COMPLETED
  }

  // BarNumber => WarrantNumber
  mapping(string => string) public barNumWarrantNum;

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

  constructor(address _tokenAddr) {
    tokenAddr = _tokenAddr;
    initiatorAddr = msg.sender;
  }

  modifier onlyInitiator() {
    if (msg.sender != initiatorAddr) {
      revert("Only Initiator can call this function");
    }
    _;
  }

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

  // initiate mint
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

  // Execute mint
  function mint(
    address to,
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyExecutor {
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

  // initiate burn
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
    if (
      txnStatusRecord[Bar_Number][Warrant_Number] != txnStatus.MINT_COMPLETED
    ) {
      revert("Mint request not exist");
    }
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.MINT_COMPLETED;
    emit BurnCancelled(Bar_Number, Warrant_Number, txnStatus.MINT_COMPLETED);
  }

  // burn implementation
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
    IERC20(tokenAddr).burn(amount * 1e18);
    delete barNumWarrantNum[Bar_Number];
    txnStatusRecord[Bar_Number][Warrant_Number] = txnStatus.BURN_COMPLETED;
    emit BarBurn(address(this), amount * 1e18, Bar_Number, Warrant_Number);
  }

  function blacklistUpdate(address user, bool value) public virtual onlyOwner {
    IERC20(tokenAddr).blacklistUpdate(user, value);
  }

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

  function pauseEditBar(bool status) public onlyOwner {
    isEditBarPaused = status;
    emit EditBarStatusPaused(status);
  }

  function withdrawFunds(address to, uint256 amount) public onlyOwner {
    IERC20(tokenAddr).transfer(to, amount);
    emit WithdrawFunds(to, amount);
  }

  function transferCgoOwnership(address newOwner) public onlyOwner {
    IERC20(tokenAddr).transferOwnership(newOwner);
  }
}
