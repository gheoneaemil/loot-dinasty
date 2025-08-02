import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const ValidatorsMethods = buildModule("ValidatorsMethods", (m) => {
    const validatorsMethods = m.contract("ValidatorsMethods", [ADMIN_ADDRESS, address0x0]);
    return { validatorsMethods };
});

export default ValidatorsMethods;
