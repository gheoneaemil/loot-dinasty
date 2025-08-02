import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynastyOpeningsMethods = buildModule("LootDynastyOpeningsMethods", (m) => {
    const lootDynastyOpeningsMethods = m.contract("LootDynastyOpeningsMethods", [ADMIN_ADDRESS, address0x0, address0x0, address0x0]);
    return { lootDynastyOpeningsMethods };
});

export default LootDynastyOpeningsMethods;
