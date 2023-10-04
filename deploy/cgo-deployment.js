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
  });

  console.log("CGOController deployed to:", cgoController);
};

module.exports.tags = ["Goldtoken"];
