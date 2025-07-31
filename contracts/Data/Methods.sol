// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Index.sol";

contract LootKingdom is DataIndex {

    constructor(
        address _validatorsManagerAddress,
        address _packManagerAddress,
        address _methodsAddress
    ) 
        DataIndex(_validatorsManagerAddress, _packManagerAddress, _methodsAddress) 
    {}

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
}
