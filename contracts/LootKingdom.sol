// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../deps/Ownable.sol";

error Forbidden();

contract LootKingdom is Ownable {
    event OpensValidated(
        bytes32 hashkey,
        uint32[] packIds,
        uint256[] randoms
    );

    struct Pack {
        string[] ids;
        uint256[] prizes;
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
            packs[packId].prizes, 
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
        bytes32 blockHash,
        uint32[] calldata packIds,
        string[] calldata keys
    ) 
        external 
    {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }

        uint256[] memory randValues = new uint256[](packIds.length);
        uint256 rand = uint256(blockHash);

        for (uint256 i; i < packIds.length; ++i) {
            randValues[i] = rand % packs[packIds[i]].prizes[packs[packIds[i]].prizes.length-1];
        }
        
        emit OpensValidated(blockHash, packIds, randValues);
    }
}
