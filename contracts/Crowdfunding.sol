// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    event campaignCreated(address indexed _owner);
    event donatedTo(address indexed _donor, string _title, uint256 _amount);

    /**
     * ! This is the structure of a campaign and is required
     */
    struct Campaign {
        address campaignOwner;
        string campaignTitle;
        string campaignDescription;
        uint256 amountRealised;
        address[] campaignDonors;
    }

    //? Contract States
    Campaign[] public campaigns;
    mapping(address => Campaign) donors;

    //? Contract Modifiers
    modifier blankCompliance(string memory _title, string memory _description) {
        require(
            bytes(_title).length > 0 && bytes(_description).length > 0,
            "can't be left blank"
        );
        _;
    }

    modifier withdrawlPermit(uint256 _campaignId) {
        require(
            msg.sender == campaigns[_campaignId].campaignOwner,
            "Only Campaign Owner can call this function"
        );
        _;
    }

    modifier campaignValidity(uint256 _campaignId) {
        require(_campaignId < campaigns.length, "Invalid Campaign");
        _;
    }

    /**
     *
     * @param _campaignTitle this is the title for the campaign
     * @param _campaignDescription this is the description for the campaign
     */
    function createCampaign(
        string memory _campaignTitle,
        string memory _campaignDescription
    ) public blankCompliance(_campaignTitle, _campaignDescription) {
        address campaignOwner = msg.sender;
        Campaign memory newCamapign = Campaign({
            campaignOwner: campaignOwner,
            campaignTitle: _campaignTitle,
            campaignDescription: _campaignDescription,
            amountRealised: 0,
            campaignDonors: new address[](0)
        });

        campaigns.push(newCamapign);
        emit campaignCreated(newCamapign.campaignOwner);
    }

    /**
     *
     * @param _campaignId this is the identifier of the campaign to be donated to
     */
    function donate(
        uint256 _campaignId,
        uint256 _amount
    ) public payable campaignValidity(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        address donor = msg.sender;
        uint256 amount = _amount > 0 ? _amount : msg.value;

        if (donors[donor].campaignDonors.length == 0) {
            campaign.campaignDonors.push(donor);
        }

        campaign.amountRealised += amount;
        donors[donor] = campaign;
        emit donatedTo(donor, campaign.campaignTitle, amount);
    }

    //? This will get all the donors addresses from every campaign
    function getAllDonors() public view returns (address[][] memory) {
        address[][] memory allDonors = new address[][](campaigns.length);

        for (uint256 i = 0; i < campaigns.length; i++) {
            allDonors[i] = campaigns[i].campaignDonors;
        }

        return allDonors;
    }

    /**
     * ? this function gets all donors of a specific campaign
     * @param _campaignId this is the key for the specific campaign
     */
    function getDonorsOfCampaign(
        uint256 _campaignId
    ) public view campaignValidity(_campaignId) returns (address[] memory) {
        Campaign memory specificCampaign = campaigns[_campaignId];

        address[] memory campaignDonors = new address[](
            specificCampaign.campaignDonors.length
        );

        for (uint256 i = 0; i < specificCampaign.campaignDonors.length; i++) {
            campaignDonors[i] = specificCampaign.campaignDonors[i];
        }

        return campaignDonors;
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    /**
     * ? this function withdraws the amount realised from a campaign
     * @param _campaignId this is the key for a specific campaign
     */
    function withdraw(
        uint256 _campaignId
    ) public payable nonReentrant withdrawlPermit(_campaignId) {
        uint256 campaignBalance = campaigns[_campaignId].amountRealised;
        campaigns[_campaignId].amountRealised = 0;
        (bool sent, ) = msg.sender.call{value: campaignBalance}("");

        require(sent, "transaction failed");
    }

    fallback() external payable {
        donate(campaigns.length - 1, msg.value);
    }

    receive() external payable {
        donate(campaigns.length - 1, msg.value);
    }
}
