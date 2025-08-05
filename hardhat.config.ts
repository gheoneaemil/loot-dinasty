import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import '@nomicfoundation/hardhat-chai-matchers';
import 'hardhat-gas-reporter'
import '@nomiclabs/hardhat-ethers';
import 'solidity-coverage';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-deploy-ethers'
import { HardhatUserConfig } from 'hardhat/config';
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 50_000,
      },
    },
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
  paths: {
    sources: './contracts',
    artifacts: './artifacts',
    root: './',
    tests: './test',
    cache: './cache'
  },
  gasReporter: {
    currency: 'ETH',
    gasPrice: 40,
    enabled: true
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    timeout: 100000000,
    reporterOptions : {

    }
  }
};

export default config;
