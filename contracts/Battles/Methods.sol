// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyBattlesMethods is Storage {
    constructor(
        address _validatorsAddress,
        address _userKeysManager,
        address _lootDynastyManager,
        address _methods
    ) 
        Storage(_validatorsAddress, _userKeysManager, _lootDynastyManager, _methods) 
    {}

    modifier validator {
        if (!IValidators(validatorsManager).isValidator(msg.sender)) {
            revert Forbidden();
        }
        _;
    }

    function batchValidateBattleOpens(
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
            uint256 rand = IUserKeys(userKeysManager).getRandomness(userIds[i], blocksHash[i]);
            (uint256[] memory ids, uint256[] memory chances, uint256[] memory prices) = 
                ILootDynasty(lootDynastyManager).getPackArrays(packIds[i]);
            uint256 chanceValue = rand % chances[chances.length-1];
            uint256 itemIdWon = ILootDynasty(lootDynastyManager).getItemWon(packIds[i], chanceValue);
            uint256 userId = userIds[i];
            battles[id].packId = packIds[i];
            battles[id].userId = userId;
            battles[id].randomness = rand;
            battles[id].prize = prices[itemIdWon];
            battles[id].battlemode = battlemodes[i];
            battles[id].purchaseReference = purchaseReferences[i];
            battles[id].itemIdWon = ids[itemIdWon];
            emit NewBattle(id, battles[id++]);
            unchecked { ++i; }
        }
    }
}
