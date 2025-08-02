import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynasty = buildModule("LootDynasty", (m) => {
    const lootDynasty = m.contract("LootDynasty", [ADMIN_ADDRESS, address0x0]);
    return { lootDynasty };
});

export default LootDynasty;
