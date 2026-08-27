// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingScript is Script {
    function run() external returns (Crowdfunding) {
        vm.startBroadcast();

        Crowdfunding crowdfunding = new Crowdfunding();

        vm.stopBroadcast();

        return crowdfunding;
    }
}