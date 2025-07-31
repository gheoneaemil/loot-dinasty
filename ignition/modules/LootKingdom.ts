// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const real = "LootKingdom";
const virtual = "VirtualLootKingdom";
const LootKingdomModule = buildModule(real, (m) => {
  const realContract = m.contract(real, [String(process.env.ADMIN_ADDRESS)]);
  const virtualContract = m.contract(virtual, [String(process.env.ADMIN_ADDRESS)]);

  return { realContract, virtualContract };
});

export default LootKingdomModule