import "node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Donations
 * @dev A contract for accepting and managing donations.
 */
contract Donations is Ownable {
    address public largestDonor;
    uint256 private largestDonation;
    bool public isActive = true; // Flag to indicate if donations are active
    address public creator = msg.sender; // Address of the creator of the NFT

    // only emitting the address as confirmation of receipt as donation amount doesn't need to be public
    event donationReceived(address donor);
    event withdrawal(uint256 ownerShare, uint256 creatorShare);
    event donationStatusChanged(bool isActive);

    /**
     * @dev Constructor function
     * @param timeLockAddress The address of the time lock contract that will become the owner of this contract
     */
    constructor(address timeLockAddress) {
        transferOwnership(timeLockAddress);
    }

    /**
     * @dev donate function
     * @notice Allows users to donate funds to the contract/NFT creator
     */
    function donate() external payable {
        require(isActive, "Donations are currently not active");
        require(msg.value > 0, "Donation amount must be greater than 0");

        emit donationReceived(msg.sender);

        if (msg.value > largestDonation) {
            largestDonor = msg.sender;
            largestDonation = msg.value;
        }
    }

    /**
     * @dev Withdraw function
     * @notice Timelock will be able to withdraw funds from the contract to itself and owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 ownerShare = (balance * 3) / 100;
        uint256 creatorShare = balance - ownerShare;
    
        payable(creator).transfer(creatorShare);
        payable(owner()).transfer(ownerShare);
        
        emit withdrawal(ownerShare, creatorShare);
    }
    /**
    * @dev Function to toggle the donation status
    * @notice Only the owner can change the donation status
    * @param _isActive Boolean flag indicating whether donations should be active or not
    */
   function toggleDonationStatus(bool _isActive) external onlyOwner {
       isActive = _isActive;
       emit donationStatusChanged(_isActive);

}
}
