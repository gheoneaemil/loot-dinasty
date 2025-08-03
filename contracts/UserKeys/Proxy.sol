// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract UserKeys is Storage {
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
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function getRandomness(
        uint256 userId,
        string calldata serverKey
    ) 
        external 
        view 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(serverKey, userIdToKey[userId])));
    }
}
