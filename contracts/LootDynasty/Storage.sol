// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";

error NoWonItemFound();
error Forbidden();

interface ILootDynasty {
    function getPackArrays(
        uint256 packId
    ) 
        external 
        view 
        returns(
            uint256[] memory, 
            uint256[] memory, 
            uint256[] memory
        );
    function getItemWon(
        uint256 packId, 
        uint256 chanceValue
    ) 
        external 
        view 
        returns (uint256);
}

contract Storage is Ownable {
    struct Pack {
        string name;
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
    }

    mapping(uint256 => Pack) public packs;
    address public packsManager;
    address public methods;

    constructor(
        address _packsManager,
        address _methods
    ) 
        Ownable(msg.sender) 
    {
        packsManager = _packsManager;
        methods = _methods;
    }

    function setConfig(
        address _packsManager,
        address _methods
    )
        external
        onlyOwner
    {
        packsManager = _packsManager;
        methods = _methods;
    }
}
