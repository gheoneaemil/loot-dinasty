// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Validators.sol";
import "./UserKeys.sol";
import "./Ownable.sol";

error NoWonItemFound();

contract Openings is Ownable {
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
    mapping(uint256 => Opening) public openings;
    address public validatorsAddress;
    address public whitelistManagerAddress;
    address public userKeysManagerAddress;

    constructor(
        address _validatorsAddress,
        address _userKeysManagerAddress,
        address _whitelistManagerAddress
    ) 
        Ownable(msg.sender) 
    {
        validatorsAddress = _validatorsAddress;
        whitelistManagerAddress = _whitelistManagerAddress;
        userKeysManagerAddress = _userKeysManagerAddress;
    }

    modifier validator {
        if (!Validators(validatorsAddress).validators(msg.sender)) {
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
        UserKeys userKeys = UserKeys(userKeysManagerAddress);
        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = getRandomness(userKeys.userIdToKey(userIds[i]), blocksHash[i]);
            Pack memory pack = packs[packIds[i]];
            uint256 chanceValue = rand % pack.chances[pack.chances.length-1];
            uint256 itemIdWon = getItemWon(pack, chanceValue);
            uint256 userId = userIds[i];
            openings[id].packId = packIds[i];
            openings[id].userId = userId;
            openings[id].randomness = rand;
            openings[id].prize = pack.prices[itemIdWon];
            openings[id].hash = blocksHash[i];
            openings[id].key = userKeys.userIdToKey(userId);
            openings[id].battlemode = battlemodes[i];
            openings[id].purchaseReference = purchaseReferences[i];
            openings[id].itemIdWon = itemIdWon;
            emit NewOpening(id, openings[id++]);
        }
    }
}
