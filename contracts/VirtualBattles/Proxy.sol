// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyVirtualBattles is Storage {
    constructor(
        address _validatorsManager,
        address _userKeysManager,
        address _lootDynastyManager,
        address _methods
    ) 
        Storage(_validatorsManager, _userKeysManager, _lootDynastyManager, _methods) 
    {}

    function batchValidateBattleOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences,
        bytes8[] calldata battlemodes
    ) 
        external 
    {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }
}
