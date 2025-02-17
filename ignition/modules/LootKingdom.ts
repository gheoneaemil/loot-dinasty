// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LootKingdomModule = buildModule("LootKingdomModule", (m) => {
  const deployer = m.getAccount(0);
  console.log(deployer);
  const lock = m.contract("LootKingdom", [deployer]);

  return { lock };
});

export default LootKingdomModule;
