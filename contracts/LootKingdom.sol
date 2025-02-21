// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../deps/Ownable.sol";
import "../deps/ReentrancyGuard.sol";
import "../deps/IERC20.sol";

contract LootKingdom is Ownable, ReentrancyGuard {
    event NewPack(uint32 indexed packId);
    event Open(uint32 indexed packId, uint32 qty);
    event OpenFulfillment(
        address indexed user, 
        uint32 indexed packId, 
        uint256[] prizes, 
        uint256[] prices,
        uint256 randomness
    );

    struct Pack {
        address token;

        // uint32 for pack id
        // uint256[] is an array representing the smaller value of chance for each prize
        // e.g: Item 1 10% chance, value 0 and Item 2 90% chance, value 10 
        // + the last element of the array represinting the last max value of last item(Item 1), 99
        uint256[] prizes;

        uint256[] prices;

        uint256 price;
        bool editable;
    }

    struct Session {
        string hashkey;
        uint32 remaining;
    }

    mapping(uint256 => Pack) public packs;
    mapping(address => mapping(uint32 => Session)) public userToSession;

    address public houseAddress;

    constructor(address _houseAddress) Ownable(msg.sender) {
        houseAddress = _houseAddress;
    }

    function setPack(
        uint32 packId,
        Pack calldata pack
    ) external onlyOwner {
        require(
            pack.prizes.length <= 100 && 
            pack.prizes.length == pack.prices.length+1,
            "Invalid length"
        );

        require(
            packs[packId].prizes.length == 0 || packs[packId].editable,
            "Cannot be edited right now"
        );

        packs[packId] = pack;
        emit NewPack(packId);
    }

    function setAllowedEditAccess(
        uint32 packId
    ) external onlyOwner {
        packs[packId].editable = !packs[packId].editable;
    }

    function setHashkey(uint32 packId, string calldata hashkey) external {
        require(userToSession[msg.sender][packId].remaining == 0, "Hashkey cannot be changed yet");
        userToSession[msg.sender][packId].hashkey = hashkey;
    }

    function open(
        uint32 packId,
        uint32 qty
    ) external payable nonReentrant {
        if (packs[packId].token == address(0)) {
            require(msg.value >= qty * packs[packId].price, "Insufficient balance");
            payable(houseAddress).transfer(msg.value);
        } else {
            IERC20 token = IERC20(packs[packId].token);
            uint256 balance = token.balanceOf(address(this));
            require(balance >= qty * packs[packId].price, "Insufficient balance");
            token.transfer(houseAddress, balance);
        }

        userToSession[msg.sender][packId].remaining += qty;
        emit Open(packId, qty);
    }

    function fulfillUserOpen(
        string calldata hashkey,
        address user,
        uint32 packId
    ) external nonReentrant onlyOwner {
        require(userToSession[user][packId].remaining > 0, "No more attempts left");
        uint256 randomness = uint256(keccak256(abi.encodePacked(userToSession[user][packId].hashkey, hashkey))) % packs[packId].prizes[packs[packId].prizes.length-1];
        --userToSession[user][packId].remaining;
        emit OpenFulfillment(user, packId, packs[packId].prizes, packs[packId].prices, randomness);
    }
}
