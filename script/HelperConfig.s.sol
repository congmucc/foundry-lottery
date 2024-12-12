// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

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
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        // } else if (block.chainid == 421611) {
        //     activeNetworkConfig = getSepoliaArbConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetWorkConfig memory) {
        return NetWorkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            vrfCoordinatorV2: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    // function getSepoliaArbConfig() public pure returns (NetWorkConfig memory) {
    //     return NetWorkConfig({});
    // }

    function getAnvilEthConfig() public returns (NetWorkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        vm.stopBroadcast();

        return NetWorkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            vrfCoordinatorV2: address(vrfCoordinatorV2Mock)
        });
    }
}
