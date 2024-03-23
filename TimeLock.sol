// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "contracts/nft.sol";
import "contracts/donation.sol";

interface INFT {
    function transferOnce(address to, uint256 tokenId) external;
    function mint(address owner, uint256 tokenId, string memory link, address creator) external;
    function owner() external view returns (address);
}

interface IDonationContract {
    function currentLeader(uint256 eventId) external view returns (address); 
    function toggleDonationStatus(bool _isActive) external;
    function withdraw() external;
    function owner() external view returns (address);
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

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to check if TimeLock is the owner of MyNFT
    function isOwnerOfMyNFT() public view returns (bool) {
        address myNFTOwner = INFT(myNFTAddress).owner();
        return myNFTOwner == address(this);
    }

    // Function to check if TimeLock is the owner of Donation
    function isOwnerOfDonation() public view returns (bool) {
        address donationOwner = IDonationContract(donationAddress).owner();
        return donationOwner == address(this);
    }

    // function to create an NFT, interacting with mint function
    function CreateNft(uint256 tokenId, string memory link) public {
        INFT(myNFTAddress).mint(address(this), tokenId, link, msg.sender);
    }

    // Deploy NFt contract
    function deployMyNFT(string memory name, string memory symbol) public onlyOwner {
        MyNFT myNFT = new MyNFT(name, symbol);
        myNFTAddress = address(myNFT);
    }

    // Deploy donation contract
    function deployDonation() public onlyOwner {
        donation don = new donation(address(this)); 
        donationAddress = address(don);
    }

    /// @dev Creates a nftevent storing all the info about it (release time, nft and donation contracts, id of the token)
    /// @param _releaseTime : time at which the NFT will be given to highest donor, set by the creator
    /// @param _nftContract : the address of the nftcontract that created the token (should also be the same)
    /// @param _tokenId : id of the token
    /// @param _donationContract : the address of the donation contract to which donations are made (should always be the same)
    function createNftEvent(uint256 _releaseTime, address _nftContract, uint256 _tokenId, address _donationContract) public onlyOwner {
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

    /// @dev Transfers the NFT to the winner, checks that the release time has been reached
    /// @param _eventId : ID of the NFT event (many NFTs can be managed at the same time)
    function transferNFTToWinner(uint256 _eventId) public onlyOwner {
        nftEvent storage nftCurrentEvent = nftEvents[_eventId];
        require(block.timestamp >= nftCurrentEvent.releaseTime, "Donation period is not over.");
        require(nftCurrentEvent.isActive, "Event is not active.");
        
        address donationContractAddress = nftCurrentEvent.donationContract;
        address winner;

        /// @notice Assembly (YUL) code to optimize gas cost (to find the highest donor, using the donation contract)
        bytes4 sig = bytes4(keccak256("currentLeader(uint256)"));
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
