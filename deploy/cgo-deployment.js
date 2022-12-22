require("dotenv").config();
module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  const { address: tknAddress } = await deploy("Goldtoken", {
    from: owner,
  });
  console.log("Goldtoken deployed to:", tknAddress);

  // deploy with contructor
  const { address: cgoController } = await deploy("CGOController", {
    from: owner,
    args: [tknAddress],
    // args: ["0x84bD9f6B49B2C821AcAcb7fD22C5866F5c346b86"],
  });

  console.log("CGOController deployed to:", cgoController);
};

module.exports.tags = ["Goldtoken"];
