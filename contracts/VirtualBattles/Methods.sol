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

    modifier validator {
        if (!IValidators(validatorsManager).isValidator(msg.sender)) {
            revert Forbidden();
        }
        _;
    }

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
            battles[id].packId = packId;
            battles[id].userId = userId;
            battles[id].randomness = rand;
            battles[id].prize = prices[itemIdWon];
            battles[id].battlemode = battlemodes[i];
            battles[id].purchaseReference = purchaseReferences[i];
            battles[id].itemIdWon = ids[itemIdWon];
            emit NewVirtualBattle(id, battles[id++], blocksHash[i]);
            unchecked { ++i; }
        }
    }
}
