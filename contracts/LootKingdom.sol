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
        uint256 prize;
        string key;
        bytes32 hash;
        bytes32 battleId; // if part of battle then it must be > 0
        bytes32 batchValidateReference;
        bytes8 battlemode;
        bool isVirtual;
    }

    uint256 public id;
    uint256 public battleId = 1;
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
        bytes32 serverKey
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
        bytes32[] calldata battleIds,
        bytes8[] calldata battlemodes,
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes32[] calldata blocksHash
    ) 
        validator 
        external 
    {
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[userIds[i]], blocksHash[i]);
            Pack memory pack = packs[packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            openings[id].packId = packIds[i];
            openings[id].userId = userIds[i];
            openings[id].randomness = rand;
            openings[id].prize = packs[packIds[i]].prices[itemIdWon];
            openings[id].hash = blocksHash[i];
            openings[id].key = userIdToKey[userIds[i]];
            openings[id].batchValidateReference = battleIds[i];
            openings[id].battlemode = battlemodes[i];
            emit NewOpening(id, openings[id++]);
        }
    }

    function batchValidateVirtualOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes32[] calldata blocksHash,
        bytes32[] calldata batchValidateReference
    ) 
        validator 
        external 
    {
        _handleOpenings(
            userIds, 
            packIds, 
            blocksHash, 
            batchValidateReference, 
            true
        );
    }

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes32[] calldata blocksHash,
        bytes32[] calldata batchValidateReference
    ) 
        validator 
        external 
    {
        _handleOpenings(
            userIds, 
            packIds, 
            blocksHash, 
            batchValidateReference, 
            false
        );
    }

    function _handleOpenings(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        bytes32[] calldata blocksHash,
        bytes32[] calldata batchValidateReference,
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
                blocksHash[i],
                batchValidateReference[i],
                isVirtual
            );
        }
    }

    function _handleOpeningCreation(
        uint256 packId,
        uint256 userId, 
        uint256 rand, 
        uint256 prize,
        bytes32 blockHash, // next block hash
        bytes32 batchValidateReference, // purchase UUID
        bool isVirtual
    ) private {
        openings[id].packId = packId;
        openings[id].userId = userId;
        openings[id].randomness = rand;
        openings[id].prize = prize;
        openings[id].hash = blockHash;
        openings[id].key = userIdToKey[userId];
        openings[id].isVirtual = isVirtual;
        openings[id].batchValidateReference = batchValidateReference;
        if (isVirtual) {
            emit NewVirtualOpening(id, openings[id++]);
        } else {
            emit NewOpening(id, openings[id++]);
        }
    }
}
