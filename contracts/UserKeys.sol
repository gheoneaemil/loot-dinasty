// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();

contract UserKeys is Ownable {
    address public userKeysManager;
    mapping(uint256 => bytes8) public userIdToKey;
    
    constructor(
        address _userKeysManager
    ) Ownable(msg.sender) {
        userKeysManager = _userKeysManager;
    }

    function setConfig(
        address _userKeysManager
    )
        external
        onlyOwner
    {
        userKeysManager = _userKeysManager;
    }

    function setUserKeys(
        uint256[] calldata userIds,
        bytes8[] calldata updatedKeys
    )
        external 
    {
        if (userKeysManager != msg.sender) {
            revert Forbidden();
        }

        for (uint256 i; i < userIds.length; ++i) {
            userIdToKey[userIds[i]] = updatedKeys[i];
        }
    }

    function getRandomness(
        string memory userKey,
        string calldata serverKey
    ) 
        external 
        view 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(serverKey, userKey)));
    }
}
