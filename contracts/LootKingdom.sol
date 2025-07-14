// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();
error NoWonItemFound();

contract LootKingdom is Ownable {
    event UsersKeysUpdated(uint256[] userIds, string[] updatedKeys);
    event NewOpening(uint256 indexed id, Opening opening);
    event NewVirtualOpening(uint256 indexed id, Opening opening);
    struct Pack {
        string name;
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
    }

    struct OpenOperation {
        uint256[] userIds;
        uint256[] packIds;
        bytes32[] blocksHash;
        bytes16[] batchValidateReference;
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
        bytes32 hash;
        bool isVirtual;
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
        validator 
        external 
    {
        for (uint256 i; i < userIds.length; ++i) {
            userIdToKey[userIds[i]] = updatedKeys[i];
        }
        emit UsersKeysUpdated(userIds, updatedKeys);
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

    function batchValidateBattles(
        OpenOperation[] calldata operations
    ) 
        validator 
        external 
    {
        for (uint256 j; j < operations.length; ++j) {
            uint256[] memory scores = new uint256[](operations[j].packIds.length);
            for (uint256 i; i < operations[j].packIds.length; ++i) {
                uint256 rand = getRandomness(userIdToKey[operations[j].userIds[i]], operations[j].blocksHash[i]);
                Pack memory pack = packs[operations[j].packIds[i]];
                uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
                uint256 itemIdWon = getItemWon(pack, chanceValue);
                scores[i] = packs[operations[j].packIds[i]].prices[itemIdWon];
            }

            uint256 winnerId = _findTopWinner(packs[operations[j].packIds[i]].prices);            

            _handleOpeningCreation(
                pack, 
                operations[j].packIds[i], 
                operations[j].userIds[i], 
                rand, 
                operations[j].packIds[itemIdWon], 
                operations[j].blocksHash[i], 
                true
            );
        }
    }

    function batchValidateVirtualOpens(
        OpenOperation calldata operation
    ) 
        validator 
        external 
    {
        for (uint256 i; i < operation.packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[operation.userIds[i]], operation.blocksHash[i]);
            Pack memory pack = packs[operation.packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            _handleOpeningCreation(
                pack, 
                operation.packIds[i], 
                operation.userIds[i], 
                rand, 
                operation.packIds[itemIdWon], 
                operation.blocksHash[i], 
                true
            );
        }
    }

    function batchValidateOpens(
        OpenOperation calldata operation
    ) 
        validator 
        external 
    {
        for (uint256 i; i < operation.packIds.length; ++i) {
            uint256 rand = getRandomness(userIdToKey[operation.userIds[i]], operation.blocksHash[i]);
            Pack memory pack = packs[operation.packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            _handleOpeningCreation(
                pack, 
                operation.packIds[i], 
                operation.userIds[i], 
                rand, 
                operation.packIds[itemIdWon], 
                operation.blocksHash[i], 
                false
            );
        }
    }

    function _findTopWinner(
        uint256[] memory userIds,
        uint256[] memory prizes
    ) private pure returns (uint256 topUserId) {
        uint256[] memory uniqueUserIds = new uint256[](userIds.length);
        uint256[] memory totals = new uint256[](userIds.length);
        uint256 uniqueCount;

        for (uint256 i; i < userIds.length; i++) {
            uint256 userId = userIds[i];
            uint256 prize = prizes[i];

            bool found = false;
            for (uint256 j; j < uniqueCount; j++) {
                if (uniqueUserIds[j] == userId) {
                    totals[j] += prize;
                    found = true;
                    break;
                }
            }

            if (!found) {
                uniqueUserIds[uniqueCount] = userId;
                totals[uniqueCount] = prize;
                uniqueCount++;
            }
        }

        uint256 topTotal;
        for (uint256 i; i < uniqueCount; i++) {
            if (totals[i] > topTotal) {
                topTotal = totals[i];
                topUserId = uniqueUserIds[i];
            }
        }
    }

    function _handleOpeningCreation(
        Pack memory pack,
        uint256 packId,
        uint256 userId, 
        uint256 rand, 
        uint256 itemWon,
        bytes32 blockHash, // next block hash
        bool isVirtual
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
        openings[id].isVirtual = isVirtual;
        if (isVirtual) {
            emit NewVirtualOpening(id, openings[id++]);
        } else {
            emit NewOpening(id, openings[id++]);
        }
    }
}
