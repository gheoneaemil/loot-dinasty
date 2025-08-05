// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract UserKeysMethods is Storage {
    constructor(
        address _userKeysManager,
        address _methods        
    ) 
        Storage(_userKeysManager, _methods) 
    {}

    function setUserKeys(
        uint256[] calldata userIds,
        bytes8[] calldata updatedKeys
    )
        external 
    {
        if (userKeysManager != msg.sender) {
            revert Forbidden();
        }

        for (uint256 i; i < userIds.length; ) {
            userIdToKey[userIds[i]] = updatedKeys[i];
            unchecked { ++i; }
        }
    }
}
