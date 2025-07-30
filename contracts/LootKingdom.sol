// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();
error NoWonItemFound();

contract LootKingdom is Ownable {
    event UserKeyUpdated(uint256 indexed userId, string updatedKey);
    event NewOpening(uint256 indexed id, Opening opening);
    event NewVirtualOpening(uint256 indexed id, Opening opening);
    struct Pack {
        string name;
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
    }

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

    uint256 public id;
    mapping(uint256 => Pack) public packs;
    mapping(address => bool) public validators;
    mapping(uint256 => string) public userIdToKey;
    mapping(uint256 => Opening) public openings;

    address public houseAddress;

    constructor(
        address _houseAddress
    ) 
        Ownable(msg.sender) 
    {
        houseAddress = _houseAddress;
    }

    modifier validator {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
        onlyOwner 
    {
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

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
        onlyOwner 
    {
        for (uint i; i < proposedValidators.length; ++i) {
            validators[proposedValidators[i]] = !validators[proposedValidators[i]];
        }
    }

    function setUserKeys(
        uint256[] calldata userIds,
        string[] calldata updatedKeys
    )
        validator 
        external 
    {
        for (uint256 i; i < userIds.length; ++i) {
            userIdToKey[userIds[i]] = updatedKeys[i];
            emit UserKeyUpdated(userIds[i], updatedKeys[i]);
        }
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
            purchaseReferences, 
            false
        );
    }

    function batchValidateVirtualBattleOpens(
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
            purchaseReferences, 
            true
        );
    }

    function batchValidateVirtualOpens(
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
            purchaseReferences, 
            true
        );
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
            purchaseReferences, 
            false
        );
    }

    function _handleOpenings(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences,
        bool isVirtual
    ) private {
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[userIds[i]], blocksHash[i]);
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
                purchaseReferences[i],
                isVirtual
            );
        }
    }

    function _handleBattleOpenings(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes8[] calldata battlemodes,
        string[] calldata blocksHash,
        string[] calldata purchaseReferences,
        bool isVirtual
    ) private {
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[userIds[i]], blocksHash[i]);
            Pack memory pack = packs[packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            _handleBattleOpeningCreation(
                packIds[i], 
                userIds[i], 
                rand, 
                pack.prices[itemIdWon], 
                pack.ids[itemIdWon],
                battlemodes[i],
                blocksHash[i],
                purchaseReferences[i],
                isVirtual
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
        string calldata purchaseReference, // purchase UUID
        bool isVirtual
    ) private {
        openings[id].packId = packId;
        openings[id].userId = userId;
        openings[id].randomness = rand;
        openings[id].prize = prize;
        openings[id].hash = blockHash;
        openings[id].key = userIdToKey[userId];
        openings[id].purchaseReference = purchaseReference;
        openings[id].itemIdWon = itemIdWon;
        if (isVirtual) {
            emit NewVirtualOpening(id, openings[id++]);
        } else {
            emit NewOpening(id, openings[id++]);
        }
    }

    function _handleBattleOpeningCreation(
        uint256 packId,
        uint256 userId, 
        uint256 rand, 
        uint256 prize,
        uint256 itemIdWon,
        bytes8 battlemode,
        string calldata blockHash, // next block hash
        string calldata purchaseReference, // purchase UUID
        bool isVirtual
    ) private {
        openings[id].packId = packId;
        openings[id].userId = userId;
        openings[id].randomness = rand;
        openings[id].prize = prize;
        openings[id].hash = blockHash;
        openings[id].key = userIdToKey[userId];
        openings[id].battlemode = battlemode;
        openings[id].purchaseReference = purchaseReference;
        openings[id].itemIdWon = itemIdWon;
        if (isVirtual) {
            emit NewVirtualOpening(id, openings[id++]);
        } else {
            emit NewOpening(id, openings[id++]);
        }
    }
}
