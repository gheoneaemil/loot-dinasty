import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynastyOpenings = buildModule("LootDynastyOpenings", (m) => {
    const lootDynastyOpenings = m.contract("LootDynastyOpenings", [ADMIN_ADDRESS, address0x0, address0x0, address0x0]);
    return { lootDynastyOpenings };
});

export default LootDynastyOpenings;
