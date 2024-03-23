// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Donation Contract
 * @dev A contract that allows users to donate funds to the contract/NFT creator for a specific token ID.
 * Users can also withdraw funds and change the donation status for a specific token ID.
 */
contract Donation is Ownable {
    struct TokenInfo {
        address largestDonor;
        uint256 largestDonation;
        uint256 totalDonations;
        address creator;
        bool isActive;
    }

    mapping(uint256 => TokenInfo) private allTokenInfos;
    mapping(address => bool) private owners;

    // Events
    event DonationReceived(uint256 tokenId, address donor);
    event Withdrawal(uint256 tokenId, uint256 ownerShare, uint256 creatorShare);
    event DonationStatusChanged(uint256 tokenId, bool isActive);

    /**
     * @dev Constructor function
     * @param timeLockAddress The address of the time lock contract that will become the owner of this contract
     */
    constructor(address timeLockAddress) Ownable(msg.sender) {
        transferOwnership(timeLockAddress);
    }

    // @dev Modifier to restrict access to the owner or authorized addresses
    modifier onlyOwner() {
        require(msg.sender == owner() || owners[msg.sender], "Not owner or authorized");
        _;
    }

    /**
     * @dev Function to add another owner
     * @param newOwner The address of the new owner to be added
     */
    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        owners[newOwner] = true;
    }

    /**
     * @dev Function to set a new token ID
     * @param tokenId The ID of the token to set
     * @param creator The address of the creator of the NFT associated with the token ID
     */
    function setToken(uint256 tokenId, address creator) external onlyOwner {
        require(allTokenInfos[tokenId].creator == address(0), "Token ID already exists");
        allTokenInfos[tokenId].creator = creator;
        allTokenInfos[tokenId].isActive = true;
    }

    /**
     * @dev Donate function
     * @notice Allows users to donate funds to the contract/NFT creator for a specific token ID
     * @param tokenId The ID of the token for which the donation is made
     */
    function donate(uint256 tokenId) external payable {
        TokenInfo storage tokenInfo = allTokenInfos[tokenId];
        require(tokenInfo.isActive, "Donations are currently not active for this token");
        require(msg.value > 0, "Donation amount must be greater than 0");


        // Update total donations for the token - in YUL 
        // instead of tokenInfo.totalDonations += msg.value;       
        assembly {
            let tokenInfoAssembly := sload(allTokenInfos.slot)
            let totalDonations := add(sload(add(tokenInfoAssembly, 0x40)), calldataload(0x0))
            sstore(add(tokenInfoAssembly, 0x40), totalDonations)
        }

        if (msg.value > tokenInfo.largestDonation) {
            tokenInfo.largestDonor = msg.sender;
            tokenInfo.largestDonation = msg.value;
        }
        emit DonationReceived(tokenId, msg.sender);
    }

    /**
     * @dev Withdraw function
     * @notice Timelock will be able to withdraw funds from the contract to the timelock and creator for each token ID
     * @param tokenId The ID of the token for which the withdrawal is made
     */
    function withdraw(uint256 tokenId) external onlyOwner {
        TokenInfo storage tokenInfo = allTokenInfos[tokenId];
        require(tokenInfo.isActive, "Donations are currently not active for this token");

        uint256 balance = tokenInfo.totalDonations;
        uint256 ownerShare = (balance * 3) / 100;
        uint256 creatorShare = balance - ownerShare;

        payable(owner()).transfer(ownerShare);
        payable(tokenInfo.creator).transfer(creatorShare);

        emit Withdrawal(tokenId, ownerShare, creatorShare);
    }

    /**
     * @dev Change donation status for a specific token ID - designed to close donations after time period
     * @notice Only the owner (i.e., timelock) can call
     * @param tokenId The ID of the token for which the donations open/close
     * @param isActive Bool flag indicating whether donations should be active or not
     */
    function toggleDonationStatus(uint256 tokenId, bool isActive) external onlyOwner {
        allTokenInfos[tokenId].isActive = isActive;
        emit DonationStatusChanged(tokenId, isActive);
    }

    /**
     * @dev Function to get the address of the largest donor for a specific token ID
     * @param tokenId The ID of the token
     * @return The address of the largest donor
     */
    function getDonorAddress(uint256 tokenId) public view returns (address) {
        TokenInfo storage myToken = allTokenInfos[tokenId];
        return myToken.largestDonor;
    }
}
