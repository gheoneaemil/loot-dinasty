// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract ValidatorsMethods is Storage {
    constructor(
        address _validatorsManager,
        address _methods
    ) 
        Storage(_validatorsManager, _methods) 
    {}

    function setConfig(
        address _validatorsManager,
        address _methods
    )
        external
        onlyOwner
    {
        validatorsManager = _validatorsManager;
        methods = _methods;
    }

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
    {
        if (validatorsManager != msg.sender) {
            revert Forbidden();
        }

        for (uint i; i < proposedValidators.length; ) {
            validators[proposedValidators[i]] = !validators[proposedValidators[i]];
            unchecked { ++i; }
        }
    }
}
