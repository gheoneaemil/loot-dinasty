// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../deps/Ownable.sol";
import "../deps/ReentrancyGuard.sol";
import "../deps/IERC20.sol";

contract LootKingdom is Ownable, ReentrancyGuard {
    event NewPack(uint32 indexed packId);
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
        uint256 forbiddenHashChangeAccess;
    }

    mapping(uint256 => Pack) public packs;
    mapping(address => mapping(uint32 => Session)) public userToSession;

    uint256 public forbiddenHashChangeAccess = 20 minutes;
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
            pack.prizes.length == pack.prices.length,
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

    function open(
        uint32 packId,
        uint32 qty, 
        string calldata hashkey
    ) external payable nonReentrant {
        Pack memory pack = packs[packId];
        if (pack.token == address(0)) {
            require(msg.value >= qty * pack.price, "Insufficient balance");
            payable(houseAddress).transfer(msg.value);
        } else {
            IERC20 token = IERC20(pack.token);
            uint256 balance = token.balanceOf(address(this));
            require(balance >= qty * pack.price, "Insufficient balance");
            token.transfer(houseAddress, balance);
        }

        Session memory session = userToSession[msg.sender][packId];
        if (keccak256(abi.encodePacked(session.hashkey)) != keccak256(abi.encodePacked(hashkey))) {
            if (session.forbiddenHashChangeAccess < block.timestamp) {
                session.hashkey = hashkey;
                session.forbiddenHashChangeAccess = block.timestamp + forbiddenHashChangeAccess;
            }
        }
        session.remaining += qty;
    }

    function fulfillUserOpen(
        string calldata hashkey,
        address user,
        uint32 packId
    ) external nonReentrant onlyOwner {
        Session memory session = userToSession[user][packId];
        require(session.remaining > 0, "No more attempts left");
        Pack memory pack = packs[packId];
        uint256 randomness = uint256(keccak256(abi.encodePacked(session.hashkey, hashkey))) % pack.prizes[pack.prizes.length-1];
        --session.remaining;
        emit OpenFulfillment(user, packId, pack.prizes, pack.prices, randomness);
    }
}
