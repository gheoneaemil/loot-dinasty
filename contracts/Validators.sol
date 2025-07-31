// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Ownable.sol";

contract Validators is Ownable {
    mapping(address => bool) public validators;

    constructor() Ownable(msg.sender) {}

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
}
