// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyMethods is Storage {
    constructor(
        address _packsManager,
        address _methods
    ) 
        Storage(_packsManager, _methods) 
    {}

    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
    {
        if (packsManager != msg.sender) {
            revert Forbidden();
        }

        packs[packId] = pack;
    }
}
