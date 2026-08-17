// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Crowdfunding} from "../src/Crowdfunding.sol";

contract CrowdfundingTest is Test {
    Crowdfunding crowdfunding;

    address creator = makeAddr("creator");
    address contributor = makeAddr("contributor");

    function setUp() public {
        crowdfunding = new Crowdfunding();
    }

    function testCreateCampaign() public {
        vm.prank(creator);

        crowdfunding.createCampaign(
            "Build a dApp",
            "A crowdfunding campaign for building a dApp",
            10 ether,
            7 days
        );

        (
            address campaignCreator,
            string memory title,
            string memory description,
            uint256 goal,
            uint256 deadline,
            uint256 amountRaised
        ) = crowdfunding.campaigns(1);

        assertEq(campaignCreator, creator);
        assertEq(title, "Build a dApp");
        assertEq(description, "A crowdfunding campaign for building a dApp");
        assertEq(goal, 10 ether);
        assertEq(deadline, block.timestamp + 7 days);
        assertEq(amountRaised, 0);
    }
}