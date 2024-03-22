import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Donations
 * @dev Contract for accepting and managing donations for multiple tokens.
 */
contract Donations is Ownable {
    struct TokenInfo {
        address largestDonor;
        uint256 largestDonation;
        uint256 totalDonations;
        address creator;
        bool isActive;
    }

    mapping(uint256 => TokenInfo) private tokenInfos;

    // might add in our addresses as multiple owners for the MVP demo

    // Events
    event donationReceived(uint256 tokenId, address donor);
    event withdrawal(uint256 tokenId, uint256 ownerShare, uint256 creatorShare);
    event donationStatusChanged(uint256 tokenId, bool isActive);

    /**
     * @dev Constructor function
     * @param timeLockAddress The address of the time lock contract that will become the owner of this contract
     */
    constructor(address timeLockAddress) Ownable() {
        transferOwnership(timeLockAddress);
    }

    /**
     * @dev Function to set a new token ID
     * @param tokenId The ID of the token to set
     * @param creator The address of the creator of the NFT associated with the token ID
     * @param isActive Boolean indicating whether donations are active for this token
     */
     function setToken(uint256 tokenId, address creator, bool isActive) external onlyOwner {
        require(tokenInfos[tokenId].creator == address(0), "Token ID already exists");
        tokenInfos[tokenId].creator = creator;
        tokenInfos[tokenId].isActive = isActive;
    }

    /**
     * @dev donate function
     * @notice Allows users to donate funds to the contract/NFT creator for a specific token ID
     * @param tokenId The ID of the token for which the donation is made
     */
    function donate(uint256 tokenId) external payable {
        TokenInfo storage tokenInfo = tokenInfos[tokenId];
        require(tokenInfo.isActive, "Donations are currently not active for this token");
        require(msg.value > 0, "Donation amount must be greater than 0");

        // Update total donations for the token - in YUL 
        // instead of tokenInfo.totalDonations += msg.value;
        assembly {
            let tokenInfo := sload(tokenInfos_slot)
            let totalDonations := add(sload(add(tokenInfo, 0x40)), calldataload(0x0))
            sstore(add(tokenInfo, 0x40), totalDonations)
        }

        if (msg.value > tokenInfo.largestDonation) {
            tokenInfo.largestDonor = msg.sender;
            tokenInfo.largestDonation = msg.value;
        }
        emit donationReceived(tokenId, msg.sender);
    }

    /**
     * @dev withdraw function
     * @notice Timelock will be able to withdraw funds from the contract to the timelock and creator for each token ID
     * @param tokenId The ID of the token for which the withdrawal is made
     */
    function withdraw(uint256 tokenId) external onlyOwner {
        TokenInfo storage tokenInfo = tokenInfos[tokenId];
        require(tokenInfo.isActive, "Donations are currently not active for this token");

        uint256 balance = tokenInfo.totalDonations;
        uint256 ownerShare = (balance * 3) / 100;
        uint256 creatorShare = balance - ownerShare;
    
        payable(owner()).transfer(ownerShare);
        payable(tokenInfo.creator).transfer(creatorShare);

        emit withdrawal(tokenId, ownerShare, creatorShare);
    }

    /**
     * @dev Change donation status for a specific token ID - designed to close donations after time period
     * @notice Only the owner (ie timelock) can call
     * @param tokenId The ID of the token for which the donations open/close
     * @param isActive Bool flag indicating whether donations should be active or not
     */
    function toggleDonationStatus(uint256 tokenId, bool isActive) external onlyOwner {
        tokenInfos[tokenId].isActive = isActive;
        emit donationStatusChanged(tokenId, isActive);
    }
}
