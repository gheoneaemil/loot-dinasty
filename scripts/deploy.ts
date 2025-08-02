import hre from "hardhat";
import path from "path";

import ValidatorsMethods from "../ignition/modules/ValidatorsMethods";
import Validators from "../ignition/modules/Validators";
import UserKeysMethods from "../ignition/modules/UserKeysMethods";
import UserKeys from "../ignition/modules/UserKeys";
import LootDynastyMethods from "../ignition/modules/LootDynastyMethods";
import LootDynasty from "../ignition/modules/LootDynasty";
import LootDynastyOpeningsMethods from "../ignition/modules/LootDynastyOpeningsMethods";
import LootDynastyOpenings from "../ignition/modules/LootDynastyOpenings";
import LootDynastyBattlesMethods from "../ignition/modules/LootDynastyBattlesMethods";
import LootDynastyBattles from "../ignition/modules/LootDynastyBattles";

async function main() {
  const validatorsMethods = await hre.ignition.deploy(ValidatorsMethods, {
    // This must be an absolute path to your parameters JSON file
    parameters: path.resolve(__dirname, "../ignition/parameters.json"),
  });

  console.log(`Apollo deployed to: ${await validatorsMethods.getAddress()}`);
}

main().catch(console.error);
