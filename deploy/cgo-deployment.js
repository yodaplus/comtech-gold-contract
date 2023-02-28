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
    from: owner,
    // args: [tknAddress],
    args: ["0x731073599d495aC0e1F11407a85627c1Bdcbaab1"],
  });

  console.log("CGOController deployed to:", cgoController);
};

module.exports.tags = ["Goldtoken"];
