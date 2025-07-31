// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";

error Forbidden();
error NoWonItemFound();

contract LootKingdom is Ownable {
    event UserKeyUpdated(uint256 indexed userId, string updatedKey);
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

    address public validatorsManagerAddress;
    address public packManagerAddress;

    constructor(
        address _validatorsManagerAddress,
        address _packManagerAddress
    ) 
        Ownable(msg.sender) 
    {
        validatorsManagerAddress = _validatorsManagerAddress;
        packManagerAddress = _packManagerAddress;
    }

    modifier validator {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    function setConfig(
        address _validatorsManagerAddress,
        address _packManagerAddress
    ) 
        external 
        onlyOwner 
    {
        validatorsManagerAddress = _validatorsManagerAddress;
        packManagerAddress = _packManagerAddress;
    }

    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
    {
        if (msg.sender != packManagerAddress) {
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

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
    {
        if (msg.sender != validatorsManagerAddress) {
            revert Forbidden();
        }

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
        uint256 userId,
        string calldata serverKey
    ) 
        public 
        view 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(serverKey, userIdToKey[userId])));
    }

    function getItemWon(
        uint256 packId, 
        uint256 chanceValue
    ) 
        public 
        pure 
        returns (uint256) 
    {
        for (uint256 j; j < packs[packId].chances.length - 1; ++j) {
            if (chanceValue > packs[packId].chances[j] && chanceValue <= packs[packId].chances[j+1]) {
                return j;
            }
        }
        
        revert NoWonItemFound();
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
        openings[id].key = userIdToKey[userId];
        openings[id].purchaseReference = purchaseReference;
        openings[id].itemIdWon = itemIdWon;
        emit NewOpening(id, openings[id++]);
    }
}
