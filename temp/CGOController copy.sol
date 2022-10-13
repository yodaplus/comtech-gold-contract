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

  // bar exist (optional)
  mapping(string => bool) public barNumberExist;

  // BarNumber => TokenBalance (make sure it should not exceed by 1000 token)
  mapping(string => uint256) public barBalance;

  mapping(address => mapping(string => unint256)) public userBarTokenBalance;

  // bars Holder (do not duplicate)
  mapping(string => address[]) public barHolder;

  // bar Holded by user (do not duplicate)
  mapping(address => string[]) public userBarHolded;

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
    barNumWarrantNum[Bar_Number] = Warrant_Number;
  }

  function onTransfer() public {
    // check  mapping(address => mapping(string => unint256)) public userBarTokenBalance;
    // if address -> barNumber == 0 then add to
    // bars Holder (do not duplicate)
    // mapping(string => address[]) public barHolder;
    // bar Holded by user (do not duplicate)
    // mapping(address => string[]) public userBarHolded;
    // else assuming it already exist continue to rest of the reassignment
  }

  function burn(address from, uint256 amount) public onlyOwner {
    IERC20(tokenAddr).burn(from, amount * 1e18);
  }

  function transferCgoOwnership(address newOwner) public onlyOwner {
    IERC20(tokenAddr).transferOwnership(newOwner);
  }
}
