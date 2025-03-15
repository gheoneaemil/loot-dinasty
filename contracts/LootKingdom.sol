// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../deps/Ownable.sol";

error NotEditable();
error Forbidden();

contract LootKingdom is Ownable {
    event OpensValidated(
        bytes32 hashkey,
        uint32[] packIds,
        uint256[] orderIds,
        uint256[] randoms
    );

    struct Pack {
        uint256[] prizes;
        uint256[] prices;
        bool editable;
    }

    mapping(uint256 => Pack) public packs;
    mapping(address => bool) public validators;

    address public houseAddress;

    constructor(address _houseAddress) Ownable(msg.sender) {
        houseAddress = _houseAddress;
    }

    function setPack(
        uint32 packId,
        Pack calldata pack
    ) external onlyOwner {
        if (packs[packId].prizes.length != 0 && !packs[packId].editable) {
            revert NotEditable();
        }

        packs[packId] = pack;
    }

    function setWhitelist(address[] calldata proposedValidators) external onlyOwner {
        for (uint i; i < proposedValidators.length; ++i) {
            validators[proposedValidators[i]] = !validators[proposedValidators[i]];
        }
    }

    function setAllowedEditAccess(
        uint32 packId
    ) external onlyOwner {
        packs[packId].editable = !packs[packId].editable;
    }

    function batchValidateOpens(
        bytes32 blockHash,
        uint32[] calldata packIds,
        uint256[] calldata orderIds
    ) external {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }

        uint256[] memory randValues = new uint256[](orderIds.length);
        uint256 rand = uint256(blockHash);

        for (uint256 i; i < orderIds.length; ++i) {
            randValues[i] = rand % packs[packIds[i]].prizes[packs[packIds[i]].prizes.length-1];
        }
        
        emit OpensValidated(blockHash, packIds, orderIds, randValues);
    }
}
