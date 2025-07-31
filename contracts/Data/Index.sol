// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../Ownable.sol";

error Forbidden();
error NoWonItemFound();

contract DataIndex is Ownable {
    event UserKeyUpdated(uint256 indexed userId, string updatedKey);
    struct Pack {
        string name;
        uint256[] ids;
        uint256[] chances;
        uint256[] prices; // in USD cents
        uint256 price; // in USD cents
    }

    mapping(uint256 => Pack) public packs;
    mapping(address => bool) public validators;
    mapping(uint256 => string) public userIdToKey;

    address public validatorsManagerAddress;
    address public packManagerAddress;
    address public methodsAddress;

    constructor(
        address _validatorsManagerAddress,
        address _packManagerAddress,
        address _methodsAddress
    ) 
        Ownable(msg.sender) 
    {
        validatorsManagerAddress = _validatorsManagerAddress;
        packManagerAddress = _packManagerAddress;
        methodsAddress = _methodsAddress;
    }

    modifier validator {
        if (!validators[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    function getRandomness(
        uint256 userId,
        string calldata serverKey
    ) 
        public 
        view 
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked(serverKey, userIdToKey[userId])));
    }

    function getItemWon(
        uint256 packId, 
        uint256 chanceValue
    ) 
        public 
        view 
        returns (uint256) 
    {
        for (uint256 j; j < packs[packId].chances.length - 1; ++j) {
            if (chanceValue > packs[packId].chances[j] && chanceValue <= packs[packId].chances[j+1]) {
                return j;
            }
        }
        
        revert NoWonItemFound();
    }

    function isValidator(address sender) 
        external 
        view 
        returns(bool) 
    {
        return validators[sender];
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
}
