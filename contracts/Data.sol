// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Validators.sol";
import "./UserKeys.sol";
import "./Ownable.sol";

error NoWonItemFound();

contract Data is Ownable {
    struct Pack {
        string name;
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
    }

    mapping(uint256 => Pack) public packs;
    address public packsManagerAddress;

    constructor(
        address _packsManagerAddress
    ) 
        Ownable(msg.sender) 
    {
        packsManagerAddress = _packsManagerAddress;
    }

    function setConfig(
        address _packsManagerAddress
    )
        external
        onlyOwner
    {
        packsManagerAddress = _packsManagerAddress;
    }


    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
    {
        if (packsManagerAddress != msg.sender) {
            revert Forbidden();
        }

        packs[packId] = pack;
    }

    function getPackArrays(
        uint256 packId
    ) 
        external 
        view 
        returns(
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        ) 
    {
        return (
            packs[packId].ids, 
            packs[packId].chances, 
            packs[packId].prices
        );
    }

    function getOpeningArrays(
        uint256 openingId
    ) 
        external 
        view 
        returns(
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        ) 
    {
        return (
            packs[openings[openingId].packId].ids, 
            packs[openings[openingId].packId].chances, 
            packs[openings[openingId].packId].prices
        );
    }

    function getRandomness(
        string memory userKey,
        string calldata serverKey
    ) 
        public 
        pure 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(serverKey, userKey)));
    }

    function getItemWon(
        Pack memory pack, 
        uint256 chanceValue
    ) 
        public 
        pure 
        returns (uint256) 
    {
        for (uint256 j; j < pack.chances.length - 1; ++j) {
            if (chanceValue > pack.chances[j] && chanceValue <= pack.chances[j+1]) {
                return j;
            }
        }
        
        revert NoWonItemFound();
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
        UserKeys userKeys = UserKeys(userKeysManagerAddress);
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userKeys.userIdToKey(userIds[i]), blocksHash[i]);
            Pack memory pack = packs[packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            _handleOpeningCreation(
                packIds[i], 
                userIds[i], 
                rand, 
                pack.prices[itemIdWon], 
                pack.ids[itemIdWon],
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
        openings[id].key = UserKeys(userKeysManagerAddress).userIdToKey(userId);
        openings[id].purchaseReference = purchaseReference;
        openings[id].itemIdWon = itemIdWon;
        emit NewOpening(id, openings[id++]);
    }
}
