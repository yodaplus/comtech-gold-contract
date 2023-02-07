require("dotenv").config();
module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy } = deployments;
  const { owner } = await getNamedAccounts();

  // const { address: tknAddress } = await deploy("Goldtoken", {
  //   from: owner,
  // });
  // console.log("Goldtoken deployed to:", tknAddress);

  // deploy with contructor
  const { address: cgoController } = await deploy("CGOController", {
    contract: "CGOController_V2",
    from: owner,
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      // execute: {
      //   methodName: "initialize",
      //   // args: [tknAddress],
      //   args: ["0xb162D21D85d3E4d0C436645D9cd85853D871437A"],
      // },
    },
  });

  console.log("CGOController deployed to:", cgoController);
};

module.exports.tags = ["Goldtoken"];
