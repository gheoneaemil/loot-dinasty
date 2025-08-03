// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";

error Forbidden();

interface IValidators {
    function isValidator(address user) external view returns (bool);
}

contract Storage is Ownable {
    address public validatorsManager;
    address public methods;
    mapping(address => bool) validators;

    constructor(
        address _validatorsManager,
        address _methods
    ) 
        Ownable(msg.sender) 
    {
        validatorsManager = _validatorsManager;
        methods = _methods;
    }

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
}
