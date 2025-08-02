// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyBattles is Storage {
    constructor(
        address _validatorsAddress,
        address _userKeysManager,
        address _lootDynastyManager,
        address _methods
    ) 
        Storage(_validatorsAddress, _userKeysManager, _lootDynastyManager, _methods) 
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
        (bool success, ) = methods.delegatecall(
            abi.encodeWithSignature("batchValidateBattleOpens(uint256[],uint256[],string[],string[],bytes8[])", msg.data)
        );
        require(success);
    }
}
