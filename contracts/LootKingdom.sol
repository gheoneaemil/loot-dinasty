// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    // uint32 for pack id
    // uint256[] is an array representing the smaller value of chance for each prize
    // e.g: Item 1 10% chance, value 0 and Item 2 90% chance, value 10 
    // + the last element of the array represinting the last max value of last item(Item 1), 99
    mapping(uint32 => uint256[]) public packsToPrizes;

    // uint32 for pack id
    // uint256 for the smallest value obtained from the packsToPrizes array
    // uint256 for the amount/price of the prize
    // address for the token address of the amount/price 
    mapping(uint32 => mapping(uint256 => uint256)) packsToPrizeToPrice;
    mapping(uint32 => mapping(uint256 => address)) packsToPrizeToToken;


    constructor() {
    }

    function rtp(uint32 packId) external view returns(uint8) {
        
    }
}
