import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { address0x0, ADMIN_ADDRESS } from "../../utils/constants";

const UserKeys = buildModule("UserKeys", (m) => {
    const userKeys = m.contract("UserKeys", [ADMIN_ADDRESS, address0x0]);
    return { userKeys };
});

export default UserKeys;
