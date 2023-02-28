const request = require("request");
// const url = "https://apothem.blocksscan.io/api/contracts";
const url = "https://xdc.blocksscan.io/api/contracts";

// Load the file
const fs = require("fs");
const file = fs.readFileSync("flat/CGOController-flat.sol", "utf8");

async function verify() {
  const body = {
    contractAddress: "0x1614F4Bb66303f178098FC1E1Be89024089530f2",
    contractName: "CGOController",
    optimization: 0,
    // version: "19", // apothem version v0.7.6+commit.7338295f
    version: "20", // xinfin version v0.7.6+commit.7338295f
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
