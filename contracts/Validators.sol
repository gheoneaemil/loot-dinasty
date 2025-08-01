// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

error Forbidden();

contract Validators is Ownable {
    address public validatorsManagerAddress;
    mapping(address => bool) public validators;

    constructor(
        address _validatorsManagerAddress
    ) 
        Ownable(msg.sender) 
    {
        validatorsManagerAddress = _validatorsManagerAddress;
    }

    function setConfig(
        address _validatorsManagerAddress
    )
        external
        onlyOwner
    {
        validatorsManagerAddress = _validatorsManagerAddress;
    }

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
    {
        if (validatorsManagerAddress != msg.sender) {
            revert Forbidden();
        }

        for (uint i; i < proposedValidators.length; ++i) {
            validators[proposedValidators[i]] = !validators[proposedValidators[i]];
        }
    }
}
