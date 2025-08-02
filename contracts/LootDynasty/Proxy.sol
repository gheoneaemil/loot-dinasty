// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./Storage.sol";

contract LootDynasty is Storage {
    constructor(
        address _packsManager,
        address _methods
    ) 
        Storage(_packsManager, _methods) 
    {}

    function setConfig(
        address _packsManager,
        address _methods
    )
        external
    {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function setPack(
        uint256 packId,
        Pack calldata pack
    ) 
        external 
    {
        (bool success, ) = methods.delegatecall(msg.data);
        require(success);
    }

    function getPackArrays(
        uint256 packId
    ) 
        external 
        view 
        returns(
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        ) 
    {
        return (
            packs[packId].ids, 
            packs[packId].chances, 
            packs[packId].prices
        );
    }

    function getItemWon(
        uint256 packId, 
        uint256 chanceValue
    ) 
        external 
        view 
        returns (uint256) 
    {
        for (uint256 i; i < packs[packId].chances.length - 1; ) {
            if (chanceValue > packs[packId].chances[i] && chanceValue <= packs[packId].chances[i+1]) {
                return i;
            }
            unchecked { ++i; }
        }
        
        revert NoWonItemFound();
    }
}
