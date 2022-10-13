// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0-solc-0.7/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract CGOController is Ownable {
  address public tokenAddr;

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
    IERC20(tokenAddr).burn(amount * 1e18);
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
    if (
      keccak256(abi.encodePacked(barNumWarrantNum[Bar_Number])) ==
      keccak256(abi.encodePacked(Warrant_Number))
    ) {
      revert("Bar already exist");
    }
    barNumWarrantNum[Bar_Number] = Warrant_Number;
    emit BarAdded(Bar_Number, Warrant_Number);
  }

  function withdrawFunds(address to, uint256 amount) public onlyOwner {
    IERC20(tokenAddr).transfer(to, amount);
    emit WithdrawFunds(to, amount);
  }

  function getBalance() public view returns (uint256) {
    return IERC20(tokenAddr).balanceOf(address(this));
  }

  function getBool(uint256 amount) public view returns (bool[3] memory flags) {
    flags[0] = IERC20(tokenAddr).balanceOf(address(this)) < (amount * 1e18);
    flags[1] = IERC20(tokenAddr).balanceOf(address(this)) < amount * 1e18;
    flags[2] = IERC20(tokenAddr).balanceOf(address(this)) != amount * 1e18;
  }

  function transferCgoOwnership(address newOwner) public onlyOwner {
    IERC20(tokenAddr).transferOwnership(newOwner);
  }
}
