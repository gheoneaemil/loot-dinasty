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
        string[] itemIds
    );

    struct Pack {
        string[] ids;
        uint256[] chances;
        uint256[] prices;
    }

    mapping(uint256 => Pack) private packs;
    mapping(address => bool) public validators;

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
    }

    function getPack(
        uint256 packId
    ) 
        external 
        view 
        returns(
            string[] memory, 
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

    function batchValidateOpens(
        uint256[] calldata userIds,
        uint256[] calldata packIds,
        string calldata blockHash, // next block hash
        string[] calldata keys // user hashed keys
    ) 
        external 
    {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }

        uint256[] memory randValues = new uint256[](packIds.length);
        string[] memory itemIds = new string[](packIds.length);

        for (uint256 i; i < packIds.length; ++i) {
            uint256 rand = uint256(keccak256(abi.encodePacked(blockHash, keys[i])));
            randValues[i] = rand % packs[packIds[i]].chances[packs[packIds[i]].chances.length-1];
            for (uint256 j; j < packs[packIds[i]].chances.length - 1; ++j) {
                if (randValues[i] > packs[packIds[i]].chances[j] && randValues[i] <= packs[packIds[i]].chances[j+1]) {
                    itemIds[i] = packs[packIds[i]].ids[j];
                    break;
                }
            }
        }
        
        emit OpensValidated(blockHash, userIds, packIds, randValues, itemIds);
    }
}
