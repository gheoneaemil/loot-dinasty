// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";
import "../Data/Index.sol";

contract LootKingdom is Ownable {
    struct Opening {
        uint256 userId;
        uint256 packId;
        uint256 randomness;
        uint256 itemIdWon;
        uint256 prize;
        string key;
        string hash;
        string purchaseReference;
        bytes8 battlemode;
    }
    
    event NewOpening(uint256 indexed id, Opening opening);

    mapping(uint256 => Opening) public openings;

    uint256 public id;
    address dataAddress;

    constructor(
        address _dataAddress
    ) 
        Ownable(msg.sender) 
    {
        dataAddress = _dataAddress;
    }

    function setConfig(
        address _dataAddress
    ) 
        external 
        onlyOwner 
    {
        dataAddress = _dataAddress;
    }

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences
    ) 
        external 
    {
        if (!DataIndex(dataAddress).isValidator(msg.sender)) {
            revert Forbidden();
        }

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
        DataIndex dataIndex = DataIndex(dataAddress);
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = dataIndex.getRandomness(userIds[i], blocksHash[i]);
            (uint256[] memory ids, uint256[] memory chances, uint256[] memory prices) = dataIndex.getPackArrays(packIds[i]);
            uint256 chanceValue = rand % chances[chances.length-1];
            uint256 itemIdWon = dataIndex.getItemWon(packIds[i], chanceValue);
            _handleOpeningCreation(
                packIds[i], 
                userIds[i], 
                rand, 
                prices[itemIdWon], 
                ids[itemIdWon],
                blocksHash[i],
                purchaseReferences[i]
            );
        }
    }

    function _handleOpeningCreation(
        uint256 packId,
        uint256 userId, 
        uint256 rand, 
        uint256 prize,
        uint256 itemIdWon,
        string calldata blockHash, // next block hash
        string calldata purchaseReference // purchase UUID
    ) private {
        openings[id].packId = packId;
        openings[id].userId = userId;
        openings[id].randomness = rand;
        openings[id].prize = prize;
        openings[id].hash = blockHash;
        openings[id].key = DataIndex.userIdToKey(userId);
        openings[id].purchaseReference = purchaseReference;
        openings[id].itemIdWon = itemIdWon;
        emit NewOpening(id, openings[id++]);
    }
}
