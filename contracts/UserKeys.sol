// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Validators.sol";
import "./Ownable.sol";

error Forbidden();

contract UserKeys is Ownable {
    event UserKeyUpdated(uint256 indexed userId, string updatedKey);
    address public validatorAddress;
    mapping(uint256 => string) public userIdToKey;
    
    constructor(
        address _validatorAddress
    ) Ownable(msg.sender) {
        validatorAddress = _validatorAddress;
    }

    function setUserKeys(
        uint256[] calldata userIds,
        string[] calldata updatedKeys
    )
        external 
    {
        if (!Validators(validatorAddress).validators(msg.sender)) {
            revert Forbidden();
        }

        for (uint256 i; i < userIds.length; ++i) {
            userIdToKey[userIds[i]] = updatedKeys[i];
            emit UserKeyUpdated(userIds[i], updatedKeys[i]);
        }
    }
}
