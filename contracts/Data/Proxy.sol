// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Index.sol";

contract LootKingdomProxy is DataIndex {

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
    {
        (bool success, ) = methodsAddress.delegatecall(
            abi.encodeWithSignature("setConfig(address, address)", msg.data)
        );
        require(success);
    }

    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
    {
        (bool success, ) = methodsAddress.delegatecall(
            abi.encodeWithSignature("setPack(uint256, (string,uint256[],uint256[],uint256[],uint256))", msg.data)
        );
        require(success);
    }

    function setWhitelist(
        address[] calldata proposedValidators
    ) 
        external 
    {
        (bool success, ) = methodsAddress.delegatecall(
            abi.encodeWithSignature("setWhitelist(address[])", msg.data)
        );
        require(success);
    }

    function setUserKeys(
        uint256[] calldata userIds,
        string[] calldata updatedKeys
    )
        external 
    {
        (bool success, ) = methodsAddress.delegatecall(
            abi.encodeWithSignature("setUserKeys(uint256[],string[])", msg.data)
        );
        require(success);
    }
}
