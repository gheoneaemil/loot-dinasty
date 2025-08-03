// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract Validators is Storage {
    constructor(
        address _validatorsManager,
        address _methods
    ) 
        Storage(_validatorsManager, _methods) 
    {}

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
    {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function isValidator(address user) external view returns (bool) {
        return validators[user];
    }
}
