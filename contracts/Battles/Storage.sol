// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import { IValidators } from "../Validators/Storage.sol";
import { IUserKeys } from "../UserKeys/Storage.sol";
import { ILootDynasty } from "../LootDynasty/Storage.sol";
import "../Ownable.sol";

error NoWonItemFound();
error Forbidden();

contract Storage is Ownable {
    event NewBattle(uint256 indexed id, Battle battle, string blockHash);
    struct Battle {
        uint256 userId;
        uint256 packId;
        uint256 randomness;
        uint256 itemIdWon;
        uint256 prize;
        bytes8 battlemode;
        string purchaseReference;
    }

    uint256 public id;
    mapping(uint256 => Battle) public battles;
    address public validatorsManager;
    address public userKeysManager;
    address public lootDynastyManager;
    address public methods;

    constructor(
        address _validatorsManager,
        address _userKeysManager,
        address _lootDynastyManager,
        address _methods
    ) 
        Ownable(msg.sender) 
    {
        validatorsManager = _validatorsManager;
        userKeysManager = _userKeysManager;
        lootDynastyManager = _lootDynastyManager;
        methods = _methods;
    }
}
