import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynastyBattles = buildModule("LootDynastyBattles", (m) => {
    const lootDynastyBattles = m.contract("LootDynastyBattles", [ADMIN_ADDRESS, address0x0, address0x0, address0x0]);

    return { lootDynastyBattles };
});

export default LootDynastyBattles;
