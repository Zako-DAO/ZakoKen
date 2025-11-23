import "dotenv/config";
import "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
    ],
  },
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainType: "l1",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("PRIVATE_KEY")],
    },
    baseSepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("BASE_SEPOLIA_RPC_URL"),
      accounts: [configVariable("PRIVATE_KEY")],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: configVariable("ETHERSCAN_API_KEY"),
      baseSepolia: configVariable("BASESCAN_API_KEY"),
    },
  },
});
