// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Raffle
 * @author eason
 * @notice A simple raffle contract
 * @dev Implements Chainlink VRFv2
  */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }
    

    function enterRaffle() public payable {

    }

    function pickWinner() public {}

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

}