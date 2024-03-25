// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/Donations.sol";
import "src/NFT.sol";

interface INFT {
    function transferOnce(address to, uint256 tokenId) external;
    function mint(address owner, address creator, uint256 tokenId, string memory link, address DonationsContractAddress) external;
    function owner() external view returns (address);
}

interface IDonationContract {
    function getDonorAddress(uint256 tokenId) external view returns (address); 
    function toggleDonationStatus(bool _isActive) external;
    function withdraw() external;
    function owner() external view returns (address);
    function addOwner(address newOwner) external;
}

/// @title TimeLock - A contract for locking NFT tokens until they are transfered to highest donors
contract TimeLock {


    event nftTransferred(address indexed beneficiary, address nftContract, uint256 tokenId);

    /// @dev Structure of an NFT event
    struct nftEvent {
        address nftContract;
        uint256 tokenId;
        uint256 releaseTime;
        address donationContract;
        bool isActive;
    }

    address public owner;
    mapping(uint256 => nftEvent) public nftEvents;
    uint256 public nextEventId;

    address public myNFTAddress;
    address public donationAddress;

    mapping(address => bool) public authorizedAddresses;

    // @dev Modifier to restrict access to the owner or authorized addresses
    modifier onlyAuthorized() {
        require(msg.sender == owner || authorizedAddresses[msg.sender], "Not owner or authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedAddresses[owner] = true;
        authorizedAddresses[0xb1126484E1A7468F617534D7f51943fF2eeC2591] = true;
        authorizedAddresses[0xfF37d103d038bBca1837B43A848BB9221b1B0004] = true;
        authorizedAddresses[0x66E7996EB76946167B8050610307a5BB8Bb36D73] = true;
    }

    /**
     * @dev gives contract's balance
     * @return contract's balance
     */
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    
    /**
    * @dev Function to check if TimeLock is the owner of MyNFT
    * @return true if the Timelock is truly the NFT owner
    */
    function isOwnerOfMyNFT() public view returns (bool) {
        address myNFTOwner = INFT(myNFTAddress).owner();
        return myNFTOwner == address(this);
    }

    /**
    * @dev Function to check if TimeLock is the owner of Donation
    * @return true if the Timelock is truly the donation owner
    */
    function isOwnerOfDonation() public view returns (bool) {
        address donationOwner = IDonationContract(donationAddress).owner();
        return donationOwner == address(this);
    }

    /**
    * @dev Function to create the NFT
    * @param tokenId The ID of the NFT
    * @param link The metadata link associated with the NFT - ie the IPFS/Filecoin link to content
    * @param releaseTime time at which the NFT will be given to highest donor, set by the creator
    */
    function CreateNft(uint256 tokenId, string memory link, uint256 releaseTime) public {
        INFT(myNFTAddress).mint(address(this), msg.sender, tokenId, link, donationAddress);
        createNftEvent(releaseTime, myNFTAddress, tokenId, donationAddress);
    }

    /**
    * @dev Function to deploy the NFT
    */
    function deployMyNFT(string memory name, string memory symbol) public onlyAuthorized {
        MyNFT myNFT = new MyNFT(name, symbol);
        myNFTAddress = address(myNFT);
    }

    /**
    * @dev Function to deploy donations
    */
    function deployDonation() public onlyAuthorized {
        Donation don = new Donation(address(this)); 
        donationAddress = address(don);
    }

    /**
    * @dev Function to set the NFT contract as owner of the donations
    */
    function addNFTContractAsOwnerToDonations() public onlyAuthorized {
        address nftContractAddress = myNFTAddress;
        IDonationContract(donationAddress).addOwner(nftContractAddress);
    }

    /** @dev Creates a nftevent storing all the info about it (release time, nft and donation contracts, id of the token)
    * @param _releaseTime : time at which the NFT will be given to highest donor, set by the creator
    * @param _nftContract : the address of the nftcontract that created the token (should also be the same)
    * @param _tokenId : id of the token
    * @param _donationContract : the address of the donation contract to which donations are made (should always be the same)
    */
    function createNftEvent(uint256 _releaseTime, address _nftContract, uint256 _tokenId, address _donationContract) public onlyAuthorized {
        require(_releaseTime > block.timestamp, "Release time is before current time.");

        nftEvents[nextEventId] = nftEvent({
            nftContract: _nftContract,
            tokenId: _tokenId,
            releaseTime: _releaseTime,
            donationContract: _donationContract,
            isActive: true
        });

        nextEventId++;
    }
    /** 
    * @dev Transfers the NFT to the winner, checks that the release time has been reached
    * @param _eventId : ID of the NFT event (many NFTs can be managed at the same time)
    */
    function transferNFTToWinner(uint256 _eventId) public onlyAuthorized {
        nftEvent storage nftCurrentEvent = nftEvents[_eventId];
        require(block.timestamp >= nftCurrentEvent.releaseTime, "Donation period is not over.");
        require(nftCurrentEvent.isActive, "Event is not active.");
        
        address donationContractAddress = nftCurrentEvent.donationContract;
        address winner;

        /// @notice Assembly (YUL) code to optimize gas cost (to find the highest donor, using the donation contract)
        bytes4 sig = bytes4(keccak256("getDonorAddress(uint256)"));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,sig) 
            mstore(add(ptr,0x04), _eventId) 

            let result := call(
                15000, 
                donationContractAddress, 
                0, 
                ptr, 
                0x24, 
                ptr, 
                0x20 
            )

            if iszero(result) {
                revert(0, 0)
            }

            winner := mload(ptr) 
        }

        require(winner != address(0), "Winner cannot be the zero address.");
        
        INFT(nftCurrentEvent.nftContract).transferOnce(winner, nftCurrentEvent.tokenId);
        IDonationContract(donationContractAddress).toggleDonationStatus(false);
        nftCurrentEvent.isActive = false;

        /// @dev Withdraw the 3% share of donations to the TimeLock contract 

        IDonationContract(donationContractAddress).withdraw();

        emit nftTransferred(winner, nftCurrentEvent.nftContract, nftCurrentEvent.tokenId);
    }

}

