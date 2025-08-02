// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynastyOpeningsMethods is Storage {
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

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences
    ) 
        validator 
        external 
    {
        _handleOpenings(
            userIds, 
            packIds, 
            blocksHash, 
            purchaseReferences
        );
    }

    function _handleOpenings(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences
    ) private {
        for (uint256 i; i < packIds.length; ) {
            uint256 rand = IUserKeys(userKeysManager).getRandomness(userIds[i], blocksHash[i]);
            (uint256[] memory ids, uint256[] memory chances, uint256[] memory prices) = 
                ILootDynasty(lootDynastyManager).getPackArrays(packIds[i]);
            uint256 chanceValue = rand % chances[chances.length-1];
            uint256 itemIdWon = ILootDynasty(lootDynastyManager).getItemWon(packIds[i], chanceValue);
            openings[id].packId = packIds[i];
            openings[id].userId = userIds[i];
            openings[id].randomness = rand;
            openings[id].prize = prices[itemIdWon];
            openings[id].purchaseReference = purchaseReferences[i];
            openings[id].itemIdWon = ids[itemIdWon];
            emit NewOpening(id, openings[id++], blocksHash[i]);
            unchecked { ++i; }
        }
    }
}
