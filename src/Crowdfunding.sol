// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
    }

    uint256 public campaignCount;

    mapping(uint256 => Campaign) public campaigns;

    mapping(uint256 => mapping(address => uint256)) public contributions;

    function createCampaign(
        string calldata title,
        string calldata description,
        uint256 goal,
        uint256 duration
    ) external {
        require(goal > 0, "Goal must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");

        campaignCount++;

        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            title: title,
            description: description,
            goal: goal,
            deadline: block.timestamp + duration,
            amountRaised: 0
        });
    }

    function contribute(uint256 campaignId) external payable {
        Campaign storage campaign = campaigns[campaignId];

        require(campaign.creator != address(0), "Campaign does not exist");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than zero");

        campaign.amountRaised += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
    }

    function withdraw(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];

        require(campaign.creator != address(0), "Campaign does not exist");
        require(msg.sender == campaign.creator, "Not campaign creator");
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(campaign.amountRaised >= campaign.goal, "Funding goal not reached");

        uint256 amount = campaign.amountRaised;

        campaign.amountRaised = 0;

        (bool success, ) = payable(campaign.creator).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function refund(uint256 campaignId) external {
    Campaign storage campaign = campaigns[campaignId];

    require(campaign.creator != address(0), "Campaign does not exist");
    require(block.timestamp >= campaign.deadline, "Campaign is still active");
    require(campaign.amountRaised < campaign.goal, "Funding goal was reached");

    uint256 amount = contributions[campaignId][msg.sender];

    require(amount > 0, "No contribution to refund");

    contributions[campaignId][msg.sender] = 0;
    campaign.amountRaised -= amount;

    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Refund failed");
}

// testnet contract address
// Contract Address: 0x240e17677f0a90aCFfc4742c9d7A55f11E7FACC0
}