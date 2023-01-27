require("dotenv").config();
const {
  ethers,
  upgrades,
  deployments,
  getNamedAccounts,
  network,
} = require("hardhat");

async function main() {
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  const controller2 = await ethers.getContractFactory("CGOController2");
  await upgrades.upgradeProxy(
    "0x303a8900389DC5b531B95252c9E06a0bBe979869",
    controller2
  );
  console.log("CGOController2 deployed to:", controller2.address);
}

main();
