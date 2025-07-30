import "@nomicfoundation/hardhat-toolbox-viem";
import * as dotenv from "dotenv";
dotenv.config();

const config = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 50_000
      },
      viaIR: true,
    },
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
  },
  networks: {
      hardhat: {
          chainId: 31337,
      },
      alphaDuneTestnet: {
        chainId: 1555201,
        url: String(process.env.RPC_URL),
        accounts: process.env.PRIVATE_KEY ? [String(process.env.PRIVATE_KEY)] : []
      }
  },
  etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY || ""
  }, 
  sourcify: {
      enabled: true
  },
  ignition: {
    defaultConfirmations: 1,
  },
};

export default config;
