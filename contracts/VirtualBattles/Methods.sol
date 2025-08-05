// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyVirtualBattlesMethods is Storage {
    constructor(
        address _validatorsManager,
        address _userKeysManager,
        address _lootDynastyManager,
        address _methods
    ) 
        Storage(_validatorsManager, _userKeysManager, _lootDynastyManager, _methods) 
    {}

    function virtualBatchValidateBattleOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences,
        bytes8[] calldata battlemodes
    ) 
        validator 
        external 
    {
        _handleBattleOpenings(
            userIds,
            packIds,
            battlemodes,
            blocksHash,
            purchaseReferences
        );
    }

    function _handleBattleOpenings(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes8[] calldata battlemodes,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences
    ) private {
        for (uint256 i; i < packIds.length; ) {
            uint256 userId = userIds[i];
            uint256 packId = packIds[i];
            uint256 rand = IUserKeys(userKeysManager).getRandomness(userId, blocksHash[i]);
            (uint256[] memory ids, uint256[] memory chances, uint256[] memory prices) = 
                ILootDynasty(lootDynastyManager).getPackArrays(packId);
            uint256 chanceValue = rand % chances[chances.length-1];
            uint256 itemIdWon = ILootDynasty(lootDynastyManager).getItemWon(packId, chanceValue);
            battleOpenings[id].packId = packId;
            battleOpenings[id].userId = userId;
            battleOpenings[id].randomness = rand;
            battleOpenings[id].prize = prices[itemIdWon];
            battleOpenings[id].battlemode = battlemodes[i];
            battleOpenings[id].purchaseReference = purchaseReferences[i];
            battleOpenings[id].itemIdWon = ids[itemIdWon];
            emit NewVirtualBattleOpening(id, battleOpenings[id++], blocksHash[i]);
            unchecked { ++i; }
        }
    }
}
