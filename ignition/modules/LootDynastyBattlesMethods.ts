import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const LootDynastyBattlesMethods = buildModule("LootDynastyBattlesMethods", (m) => {
    const lootDynastyBattlesMethods = m.contract("LootDynastyBattlesMethods", [ADMIN_ADDRESS, address0x0, address0x0, address0x0]);

    return { lootDynastyBattlesMethods };
});

export default LootDynastyBattlesMethods;
