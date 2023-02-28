const request = require("request");
const url = "https://apothem.blocksscan.io/api/contracts";

// Load the file
const fs = require("fs");
const file = fs.readFileSync("flat/CGOController-flat.sol", "utf8");

async function verify() {
  const body = {
    contractAddress: "xdc7af454bEBA644ac40519B8c94cF5E40c88Ea52F2",
    contractName: "CGOController",
    optimization: 0,
    version: "19",
    sourceCode: file.toString(),
  };
  await request.post(url, { json: body }, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      console.log(body);
    }
    console.log(error);
    console.log(response.statusCode);
    console.log(response.statusMessage);
  });
}

verify();
