const {
  ethers,
  upgrades,
  deployments,
  getNamedAccounts,
  network,
} = require("hardhat");

async function main() {
  //   const { owner } = await getNamedAccounts();

  const [owner, initiator, executor, acc1, acc2, acc3] =
    await ethers.getSigners();

  const tkn = await ethers.getContractFactory("Goldtoken");
  const tknDeploy = await tkn.connect(owner).deploy();
  await tknDeploy.deployed();
  console.log("Goldtoken deployed to:", tknDeploy.address);

  const controller = await ethers.getContractFactory("CGOController");
  const controllerDeploy = await upgrades.deployProxy(
    controller,
    [tknDeploy.address],
    {
      initializer: "initialize",
      from: owner,
    }
  );
  await controllerDeploy.deployed();
  console.log("CGOController deployed to:", controllerDeploy.address);
}

main();
