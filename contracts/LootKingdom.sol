// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../deps/Ownable.sol";
import "../deps/IERC20.sol";

error InvalidLength();
error NotEditable();
error CurrentlyUnchangeable();
error InsufficientBalance();
error Forbidden();

contract LootKingdom is Ownable {
    event OpensValidated(
        string hashkey,
        address[] users,
        uint256[] randomness,
        uint32[] packIds
    );
    event Open(
        string hashkey,
        address user,
        uint32 packId, 
        uint32 qty
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
    mapping(address => bool) public validators;

    address public houseAddress;

    constructor(address _houseAddress) Ownable(msg.sender) {
        houseAddress = _houseAddress;
    }

    function setPack(
        uint32 packId,
        Pack calldata pack
    ) external onlyOwner {
        if (pack.prizes.length > 100 || pack.prizes.length != pack.prices.length + 1) {
            revert InvalidLength();
        }

        if (packs[packId].prizes.length != 0 && !packs[packId].editable) {
            revert NotEditable();
        }

        packs[packId] = pack;
    }

    function setWhitelist(address[] calldata proposedValidators) external onlyOwner {
        for (uint i; i < proposedValidators.length; ++i) {
            validators[proposedValidators[i]] = !validators[proposedValidators[i]];
        }
    }

    function setAllowedEditAccess(
        uint32 packId
    ) external onlyOwner {
        packs[packId].editable = !packs[packId].editable;
    }

    function setHashkey(uint32 packId, string calldata hashkey) external {
        if (userToSession[msg.sender][packId].remaining != 0) {
            revert CurrentlyUnchangeable();
        }
        userToSession[msg.sender][packId].hashkey = hashkey;
    }

    function open(
        uint32 packId,
        uint32 qty
    ) external payable {
        if (packs[packId].token == address(0)) {
            if (msg.value < qty * packs[packId].price) {
                revert InsufficientBalance();
            }
            payable(houseAddress).transfer(msg.value);
        } else {
            IERC20 token = IERC20(packs[packId].token);
            uint256 balance = token.balanceOf(address(this));
            if (balance < qty * packs[packId].price) {
                revert InsufficientBalance();
            }
            token.transfer(houseAddress, balance);
        }

        userToSession[msg.sender][packId].remaining += qty;
        emit Open(
            userToSession[msg.sender][packId].hashkey,
            msg.sender,
            packId, 
            qty
        );
    }

    function batchValidateOpens(
        string calldata hashkey,
        address[] calldata users,
        uint32[] calldata packIds
    ) external returns(uint256[] memory randValues){
        if (!validators[msg.sender]) {
            revert Forbidden();
        }
        randValues = new uint256[](users.length);
        for (uint256 i; i < users.length; ++i) {
            randValues[i] = uint256(
                keccak256(
                    abi.encodePacked(
                        userToSession[users[i]][packIds[i]].hashkey, hashkey
                    )
                )
            ) % packs[packIds[i]].prizes[packs[packIds[i]].prizes.length-1];
            --userToSession[users[i]][packIds[i]].remaining;
        }
        emit OpensValidated(hashkey, users, randValues, packIds);
    }

}
