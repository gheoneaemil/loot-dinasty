import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const Validators = buildModule("Validators", (m) => {
    const validators = m.contract("Validators", [ADMIN_ADDRESS, address0x0]);
    return { validators };
});

export default Validators;
