// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();
error NoWonItemFound();

contract LootKingdom is Ownable {
    event UsersKeysUpdated(uint256[] userIds, string[] updatedKeys);
    event NewOpening(uint256 indexed id, Opening opening);
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
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
        uint256 itemWon;
        string key;
        string hash;
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
            openings[openingId].ids, 
            openings[openingId].chances, 
            openings[openingId].prices
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
        external
        onlyOwner
    {
        for (uint256 i; i < userIds.length; ++i) {
            userIdToKey[userIds[i]] = updatedKeys[i];
        }
        emit UsersKeysUpdated(userIds, updatedKeys);
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
                return pack.ids[j];
            }
        }
        
        revert NoWonItemFound();
    }

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string[] calldata blocksHash
    ) 
        external 
    {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }

        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[userIds[i]], blocksHash[i]);
            Pack memory pack = packs[packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemWon = getItemWon(pack, chanceValue);
            _handleOpeningCreation(pack, packIds[i], userIds[i], rand, itemWon, blocksHash[i]);
        }
    }


    function _handleOpeningCreation(
        Pack memory pack,
        uint256 packId,
        uint256 userId, 
        uint256 rand, 
        uint256 itemWon,
        string calldata blockHash // next block hash
    ) private {
        openings[id].ids = pack.ids;
        openings[id].packId = packId;
        openings[id].chances = pack.chances;
        openings[id].prices = pack.prices;
        openings[id].userId = userId;
        openings[id].randomness = rand;
        openings[id].price = pack.price;
        openings[id].itemWon = itemWon;
        openings[id].hash = blockHash;
        openings[id].key = userIdToKey[userId];
        emit NewOpening(id, openings[id++]);
    }
}
