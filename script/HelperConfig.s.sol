// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract HelperConfig is Script {
    struct NetWorkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
    }

    NetWorkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            return getSepoliaEthConfig();
        } else {
            return getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetWorkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            vrfCoordinatorV2: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    function getAnvilEthConfig() public view returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorV2!= address(0)) {
            return activeNetworkConfig;
        }
    }
}