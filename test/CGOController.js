const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy } = deployments;

describe("CGOController", function () {
  let cgo_contract;
  let cgoController_contract;
  let owner, acc1, acc2, acc3, acc4, acc5;

  beforeEach("Should deploy CGO token", async function () {
    [owner, acc1, acc2, acc3, acc4, acc5] = await ethers.getSigners();

    const CGO = await ethers.getContractFactory("Goldtoken");
    cgo_contract = await CGO.deploy();
    await cgo_contract.deployed();
    expect(await cgo_contract.symbol()).to.equal("CGO_T_D");
  });

  it("Should deploy CGOController & verify the tknAddr, ownership", async function () {
    // cgoController_contract = await deploy("CGOController", {
    //   // from: owner,
    //   args: [cgo_contract.address],
    // });
    const CGOController = await ethers.getContractFactory("CGOController");
    cgoController_contract = await CGOController.deploy(cgo_contract.address);
    expect(await cgoController_contract.owner()).to.equal(owner.address);
    expect(await cgoController_contract.tokenAddr()).to.equal(
      cgo_contract.address
    );
  });

  it("transfer ownership of CGO token to Controller Contract", async function () {
    await cgo_contract.transferOwnership(cgoController_contract.address);
    expect(await cgo_contract.owner()).to.equal(cgoController_contract.address);
  });

  it("set initiator and executor", async function () {
    await cgoController_contract.setInitiatorAddr(acc1.address);
    await cgoController_contract.setExecutorAddr(acc2.address);
    expect(await cgoController_contract.initiatorAddr()).to.equal(acc1.address);
    expect(await cgoController_contract.executorAddr()).to.equal(acc2.address);
  });

  it("initiate bar mint", async function () {
    await cgoController_contract.connect(acc1).initiateMint("abc", "xyz");
    console.log(
      "Output: ⚽️",
      await cgoController_contract.txnStatusRecord("abc", "xyz")
    );
  });
});
