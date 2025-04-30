// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();

contract LootKingdom is Ownable {
    event OpensValidated(
        string hashkey,
        uint256[] userIds,
        uint256[] packIds,
        uint256[] randoms,
        uint256[] itemIds
    );
    event NewPack(
        uint32 indexed packId,
        uint256[] ids,
        uint256[] chances,
        uint256[] prices
    );

    struct Pack {
        uint256[] ids;
        uint256[] chances;
        uint256[] prices;
    }

    mapping(uint256 => Pack) private packs;
    mapping(address => bool) public validators;
    mapping(uint256 => string) private keys;

    address public houseAddress;

    constructor(
        address _houseAddress
    ) 
        Ownable(msg.sender) 
    {
        houseAddress = _houseAddress;
    }

    function setPack(
        uint32 packId,
        Pack calldata pack
    ) 
        external 
        onlyOwner 
    {
        packs[packId] = pack;
        emit NewPack(packId, pack.ids, pack.chances, pack.prices);
    }

    function getPack(
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
            keys[userIds[i]] = updatedKeys[i];
        }
    }

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string calldata blockHash // next block hash
    ) 
        external 
    {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }

        uint256[] memory randValues = new uint256[](packIds.length);
        uint256[] memory itemIds = new uint256[](packIds.length);

        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = uint256(keccak256(abi.encodePacked(blockHash, keys[userIds[i]])));
            Pack memory pack = packs[packIds[i]];
            randValues[i] = rand % pack.chances[pack.chances.length-1];
            for (uint256 j; j < pack.chances.length - 1; ++j) {
                if (randValues[i] > pack.chances[j] && randValues[i] <= pack.chances[j+1]) {
                    itemIds[i] = pack.ids[j];
                    break;
                }
            }
        }
        
        emit OpensValidated(blockHash, userIds, packIds, randValues, itemIds);
    }
}
