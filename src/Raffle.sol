// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Raffle
 * @author eason
 * @notice A simple raffle contract
 * @dev Implements Chainlink VRFv2
  */
contract Raffle {

    error Raffle_NotEnoughETHSent(string msg);

    event RaffleEnter(address indexed player);

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address[] private s_players;

    constructor(
        uint256 entranceFee, 
        uint256 interval
    ) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }


    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughETHSent("Not Enough ETH Sent!");
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert("Not Enough Time Passed!");
        }
    }

    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }

}