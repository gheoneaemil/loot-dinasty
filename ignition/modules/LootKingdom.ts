// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LootKingdomModule = buildModule("LootKingdom", (m) => {
  const lock = m.contract("LootKingdom", [String(process.env.ADMIN_ADDRESS)]);
  return { lock };
});

export default LootKingdomModule;