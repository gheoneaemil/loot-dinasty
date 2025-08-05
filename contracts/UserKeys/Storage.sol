// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";

error Forbidden();

interface IUserKeys {
    function getRandomness(
        uint256 userId,
        string calldata serverKey
    ) 
        external 
        view 
        returns (uint256);
}

contract Storage is Ownable {
    address public userKeysManager;
    address public methods;
    mapping(uint256 => bytes8) public userIdToKey;
    
    constructor(
        address _userKeysManager,
        address _methods
    ) Ownable(msg.sender) {
        userKeysManager = _userKeysManager;
        methods = _methods;
    }

    function setConfig(
        address _userKeysManager,
        address _methods
    )
        external
        onlyOwner
    {
        userKeysManager = _userKeysManager;
        methods = _methods;
    }
}
