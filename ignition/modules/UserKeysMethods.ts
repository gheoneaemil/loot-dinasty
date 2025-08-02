import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const UserKeysMethods = buildModule("UserKeysMethods", (m) => {
    const userKeysMethods = m.contract("UserKeysMethods", [ADMIN_ADDRESS, address0x0]);
    return { userKeysMethods };
});

export default UserKeysMethods;
