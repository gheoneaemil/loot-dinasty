import "@nomicfoundation/hardhat-toolbox-viem";
import * as dotenv from "dotenv";
dotenv.config();

const config = {
  solidity: "0.8.19",
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
  },
  networks: {
      arbitrumSepolia: {
          url: process.env.ARBITRUM_SEPOLIA_RPC_URL || "",
          accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
          chainId: 421614
      },
      hardhat: {
          chainId: 31337, // Hardhat local network chainId
      },
  },
  etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY || ""
  }, 
  sourcify: {
      enabled: true
  }
};

export default config;
