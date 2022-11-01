// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0-solc-0.7/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract CGOController is Ownable {
  address public tokenAddr;

  bool public isEditBarPaused = false;

  // BarNumber => WarrantNumber
  mapping(string => string) public barNumWarrantNum;

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

  constructor(address _tokenAddr) {
    tokenAddr = _tokenAddr;
  }

  function mint(
    address to,
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyOwner {
    IERC20(tokenAddr).mint(to, amount * 1e18);
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    if (amount != 1000) {
      revert("Mint amount should be 1000");
    }
    barNumWarrantNum[Bar_Number] = Warrant_Number;
    emit BarMint(to, amount * 1e18, Bar_Number, Warrant_Number);
  }

  // burn implementation
  function burn(
    uint256 amount,
    string memory Bar_Number,
    string memory Warrant_Number
  ) public onlyOwner {
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) !=
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Incorrect Bar details");
    }
    if (amount != 1000) {
      revert("Burn amount should be 1000");
    }
    if (IERC20(tokenAddr).balanceOf(address(this)) < amount * 1e18) {
      revert("Insufficient Funds");
    }
    IERC20(tokenAddr).burn(amount * 1e18);
    delete barNumWarrantNum[Bar_Number];
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
