require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("hardhat-deploy");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const { MNEMONIC, APOTHEM_RPC_URL, MAINNET_RPC_URL } = process.env;
const DEFAULT_MNEMONIC =
  "vague address accident certain range neither vapor void rural little ensure resource";

const sharedNetworkConfig = {
  accounts: {
    mnemonic: MNEMONIC ?? DEFAULT_MNEMONIC,
  },
};

// APOTHEM_RPC_URL = "https://rpc-apothem.xinfin.yodaplus.net";
// MAINNET_RPC_URL = "https://rpc.xinfin.yodaplus.net";

module.exports = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    mainnet: {
      ...sharedNetworkConfig,
      url: MAINNET_RPC_URL,
    },
    apothem: {
      ...sharedNetworkConfig,
      url: APOTHEM_RPC_URL,
    },
  },
  watcher: {
    test: {
      tasks: ["test"],
      files: ["./contracts", "./test"],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
  },
  namedAccounts: {
    owner: {
      default: 0,
    },
  },
};
