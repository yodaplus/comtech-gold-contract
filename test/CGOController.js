const { expect } = require("chai");
const { ethers, deployments } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy } = deployments;

const data = require("./test-data.json");

describe("CGOController", function () {
  let cgo_contract;
  let cgoController_contract;
  let owner, initiator, executor, acc1, acc2, acc3;

  const mintAmt = ethers.utils.parseEther("1000");
  const partialAmt = ethers.utils.parseEther("500");

  const NOT_EXIST = 0;
  const MINT_INITIATED = 1;
  const MINT_COMPLETED = 2;
  const BURN_INITIATED = 3;
  const BURN_COMPLETED = 4;

  it("Should deploy CGO token", async function () {
    [owner, initiator, executor, acc1, acc2, acc3] = await ethers.getSigners();

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
    await cgoController_contract.setInitiatorAddr(initiator.address);
    await cgoController_contract.setExecutorAddr(executor.address);
    expect(await cgoController_contract.initiatorAddr()).to.equal(
      initiator.address
    );
    expect(await cgoController_contract.executorAddr()).to.equal(
      executor.address
    );
  });

  it("initiate mint should fail if not initiated by initiator", async function () {
    await expect(
      cgoController_contract
        .connect(acc1)
        .initiateMint(data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Only Initiator can call this function");
  });

  it("mint should fail if not initiated", async function () {
    // console.log("CGO_Token owner:", await cgo_contract.owner());
    // console.log("CGOController address:", await cgoController_contract.address);
    await expect(
      cgoController_contract
        .connect(executor)
        .mint(
          acc2.address,
          1000,
          data.bar1.bar_number,
          data.bar1.warrant_number
        )
    ).to.be.revertedWith("Mint initiation request not exist");
    // console.log("Data:", data.bar1.bar_number, data.bar1.warrant_number);
  });

  it("initiate bar mint", async function () {
    const _initiate_mint = await cgoController_contract
      .connect(initiator)
      .initiateMint(data.bar1.bar_number, data.bar1.warrant_number);

    // await expect(
    //   cgoController_contract
    //     .connect(initiator)
    //     .initiateMint(data.bar1.bar_number, data.bar1.warrant_number)
    // ).to.emit(cgoController_contract, "MintInitiated");

    await expect(_initiate_mint)
      .to.emit(cgoController_contract, "MintInitiated")
      .withArgs(data.bar1.bar_number, data.bar1.warrant_number, MINT_INITIATED);

    // let receipt = await _initiate_mint.wait();
    // console.log(
    //   "🚀 _initiate_mint event: ",
    //   receipt.events?.filter((x) => {
    //     return x.event == "MintInitiated";
    //   })
    // );

    // console.log(
    //   "Output: ⚽️",
    //   await cgoController_contract.txnStatusRecord(
    //     data.bar1.bar_number,
    //     data.bar1.warrant_number
    //   )
    // );

    expect(
      await cgoController_contract.txnStatusRecord(
        data.bar1.bar_number,
        data.bar1.warrant_number
      )
    ).to.equal(MINT_INITIATED);
  });

  it("initiate bar mint 2", async function () {
    const _initiate_mint = await cgoController_contract
      .connect(initiator)
      .initiateMint(data.bar2.bar_number, data.bar2.warrant_number);

    await expect(_initiate_mint)
      .to.emit(cgoController_contract, "MintInitiated")
      .withArgs(data.bar2.bar_number, data.bar2.warrant_number, MINT_INITIATED);

    expect(
      await cgoController_contract.txnStatusRecord(
        data.bar2.bar_number,
        data.bar2.warrant_number
      )
    ).to.equal(MINT_INITIATED);
  });

  it("initiated bar should exist", async function () {
    await expect(
      cgoController_contract
        .connect(initiator)
        .initiateMint(data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Mint initiation request already exist");
  });

  it("mint should fail if not executed by executor", async function () {
    await expect(
      cgoController_contract
        .connect(acc1)
        .mint(
          acc2.address,
          1000,
          data.bar1.bar_number,
          data.bar1.warrant_number
        )
    ).to.be.revertedWith("Only Executor can call this function");
  });

  it("should mint the token", async function () {
    const _mint = await cgoController_contract
      .connect(executor)
      .mint(acc1.address, 1000, data.bar1.bar_number, data.bar1.warrant_number);
    expect(_mint)
      .to.emit(cgoController_contract, "BarMint")
      .withArgs(
        acc1.address,
        mintAmt,
        data.bar1.bar_number,
        data.bar1.warrant_number
      );
    expect(
      await cgoController_contract.txnStatusRecord(
        data.bar1.bar_number,
        data.bar1.warrant_number
      )
    ).to.equal(MINT_COMPLETED);
    expect(await cgo_contract.balanceOf(acc1.address)).to.equal(mintAmt);
  });

  it("should fail if mint already executed", async function () {
    await expect(
      cgoController_contract
        .connect(executor)
        .mint(
          acc1.address,
          1000,
          data.bar1.bar_number,
          data.bar1.warrant_number
        )
    ).to.be.revertedWith("Bar already exist");
  });

  it("initiate mint should fail if bar already exist", async function () {
    await expect(
      cgoController_contract
        .connect(initiator)
        .initiateMint(data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Bar already exist");
  });

  it("should revert as Burn initiation request not exist", async function () {
    await expect(
      cgoController_contract
        .connect(executor)
        .burn(1000, data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Burn initiation request not exist");
  });

  it("initiate burn should fail if not initiated by initiator", async function () {
    await expect(
      cgoController_contract
        .connect(acc1)
        .initiateBurn(data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Only Initiator can call this function");
  });

  it("burn initiate should revert if bar not exist", async function () {
    await expect(
      cgoController_contract
        .connect(initiator)
        .initiateBurn(data.bar3.bar_number, data.bar3.warrant_number)
    ).to.be.revertedWith("Incorrect Bar details");
  });

  it("initiate burn request", async function () {
    const _initiate_burn = await cgoController_contract
      .connect(initiator)
      .initiateBurn(data.bar1.bar_number, data.bar1.warrant_number);
    await expect(_initiate_burn)
      .to.emit(cgoController_contract, "BurnInitiated")
      .withArgs(data.bar1.bar_number, data.bar1.warrant_number, BURN_INITIATED);
    expect(
      await cgoController_contract.txnStatusRecord(
        data.bar1.bar_number,
        data.bar1.warrant_number
      )
    ).to.equal(BURN_INITIATED);
  });

  it("transfer 500 CGO token", async function () {
    const _transfer = await cgo_contract
      .connect(acc1)
      .transfer(cgoController_contract.address, partialAmt);
    await expect(_transfer)
      .to.emit(cgo_contract, "Transfer")
      .withArgs(acc1.address, cgoController_contract.address, partialAmt);
    expect(await cgo_contract.balanceOf(acc1.address)).to.equal(partialAmt);
    expect(
      await cgo_contract.balanceOf(cgoController_contract.address)
    ).to.equal(partialAmt);
  });

  it("should revert as insufficient balance", async function () {
    await expect(
      cgoController_contract
        .connect(executor)
        .burn(1000, data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Burn amount should be 1000");
  });

  it("burn should revert with Incorrect Bar details", async function () {
    await expect(
      cgoController_contract
        .connect(executor)
        .burn(1000, data.bar3.bar_number, data.bar3.warrant_number)
    ).to.be.revertedWith("Incorrect Bar details");
  });

  it("burn should revert with Only Executor can call this function", async function () {
    await expect(
      cgoController_contract
        .connect(acc1)
        .burn(1000, data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Only Executor can call this function");
  });

  it("transfer another 500 CGO token", async function () {
    const _transfer = await cgo_contract
      .connect(acc1)
      .transfer(cgoController_contract.address, partialAmt);
    await expect(_transfer)
      .to.emit(cgo_contract, "Transfer")
      .withArgs(acc1.address, cgoController_contract.address, partialAmt);
    expect(await cgo_contract.balanceOf(acc1.address)).to.equal(0);
    expect(
      await cgo_contract.balanceOf(cgoController_contract.address)
    ).to.equal(mintAmt);
  });

  it("inititae mint revert as Burn request already exist", async function () {
    await expect(
      cgoController_contract
        .connect(initiator)
        .initiateMint(data.bar1.bar_number, data.bar1.warrant_number)
    ).to.be.revertedWith("Burn request exist for this Bar");
  });

  it("should burn the token", async function () {
    const _burn = await cgoController_contract
      .connect(executor)
      .burn(1000, data.bar1.bar_number, data.bar1.warrant_number);
    await expect(_burn)
      .to.emit(cgoController_contract, "BarBurn")
      .withArgs(
        cgoController_contract.address,
        mintAmt,
        data.bar1.bar_number,
        data.bar1.warrant_number
      );
    expect(
      await cgoController_contract.txnStatusRecord(
        data.bar1.bar_number,
        data.bar1.warrant_number
      )
    ).to.equal(BURN_COMPLETED);
    expect(await cgo_contract.balanceOf(acc1.address)).to.equal(0);
    expect(
      await cgo_contract.balanceOf(cgoController_contract.address)
    ).to.equal(0);
  });
});
