import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynastyMethods = buildModule("LootDynastyMethods", (m) => {
    const lootDynastyMethods = m.contract("LootDynastyMethods", [ADMIN_ADDRESS, address0x0]);
    return { lootDynastyMethods };
});

export default LootDynastyMethods;
