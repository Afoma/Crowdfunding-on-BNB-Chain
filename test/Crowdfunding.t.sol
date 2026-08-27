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
    function testContributeToCampaign() public {
    vm.prank(creator);
    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 5 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 3 ether}(1);

    (
        ,
        ,
        ,
        ,
        ,
        uint256 amountRaised
    ) = crowdfunding.campaigns(1);

    assertEq(amountRaised, 3 ether);
    assertEq(crowdfunding.contributions(1, contributor), 3 ether);
}
function testCreatorCanWithdraw() public {
    vm.prank(creator);
    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 15 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 10 ether}(1);

    vm.warp(block.timestamp + 8 days);

    uint256 creatorBalanceBefore = creator.balance;

    vm.prank(creator);
    crowdfunding.withdraw(1);

    uint256 creatorBalanceAfter = creator.balance;

    assertEq(creatorBalanceAfter, creatorBalanceBefore + 10 ether);

    (
        ,
        ,
        ,
        ,
        ,
        uint256 amountRaised
    ) = crowdfunding.campaigns(1);

    assertEq(amountRaised, 0);
}

function testReentrancyAttackFails() public {
    ReentrantAttacker attacker = new ReentrantAttacker(crowdfunding);

    vm.prank(address(attacker));
    crowdfunding.createCampaign(
        "Malicious Campaign",
        "Testing reentrancy protection",
        10 ether,
        7 days
    );

    vm.deal(contributor, 10 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 10 ether}(1);

    vm.warp(block.timestamp + 8 days);

    vm.expectRevert();
    attacker.attack(1);
}

function testContributorCanRefundFailedCampaign() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 5 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 3 ether}(1);

    vm.warp(block.timestamp + 8 days);

    uint256 contributorBalanceBefore = contributor.balance;

    vm.prank(contributor);
    crowdfunding.refund(1);

    uint256 contributorBalanceAfter = contributor.balance;

    assertEq(
        contributorBalanceAfter,
        contributorBalanceBefore + 3 ether
    );

    assertEq(crowdfunding.contributions(1, contributor), 0);

    (
        ,
        ,
        ,
        ,
        ,
        uint256 amountRaised
    ) = crowdfunding.campaigns(1);

    assertEq(amountRaised, 0);
}

function testNonCreatorCannotWithdraw() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 10 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 10 ether}(1);

    vm.warp(block.timestamp + 8 days);

    vm.prank(contributor);

    vm.expectRevert("Not campaign creator");
    crowdfunding.withdraw(1);
}

function testCannotWithdrawBeforeDeadline() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 10 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 10 ether}(1);

    vm.prank(creator);

    vm.expectRevert("Campaign is still active");
    crowdfunding.withdraw(1);
}

function testCannotWithdrawIfGoalNotReached() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 5 ether);

    vm.prank(contributor);
    crowdfunding.contribute{value: 5 ether}(1);

    vm.warp(block.timestamp + 8 days);

    vm.prank(creator);

    vm.expectRevert("Funding goal not reached");
    crowdfunding.withdraw(1);
}
function testCannotContributeAfterDeadline() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.warp(block.timestamp + 8 days);

    vm.deal(contributor, 5 ether);

    vm.prank(contributor);

    vm.expectRevert("Campaign has ended");
    crowdfunding.contribute{value: 1 ether}(1);
}
function testCannotContributeZero() public {
    vm.prank(creator);

    crowdfunding.createCampaign(
        "Build a dApp",
        "Funding a BNB Chain project",
        10 ether,
        7 days
    );

    vm.deal(contributor, 5 ether);

    vm.prank(contributor);

    vm.expectRevert("Contribution must be greater than zero");
    crowdfunding.contribute{value: 0}(1);
}
}

contract ReentrantAttacker {
    Crowdfunding public crowdfunding;
    uint256 public campaignId;

    constructor(Crowdfunding _crowdfunding) {
        crowdfunding = _crowdfunding;
    }

    function attack(uint256 _campaignId) external {
        campaignId = _campaignId;
        crowdfunding.withdraw(_campaignId);
    }

    receive() external payable {
        crowdfunding.withdraw(campaignId);
    }
}