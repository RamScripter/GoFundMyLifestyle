// SPDX-Licence Identifier: MIT
pragma solidity ^0.8.20;

interface INFT {
    function transferOnce(address to, uint256 tokenId) external;
}


interface IDonationContract {
    function currentLeader(uint256 eventId) external view returns (address); 
}

contract TimeLock {

    event NFTTransferred(address indexed beneficiary, address nftContract, uint256 tokenId);

    struct NFTEvent {
        address nftContract;
        uint256 tokenId;
        uint256 releaseTime;
        address donationContract;
        bool isActive;
    }

    address public owner;
    mapping(uint256 => NFTEvent) public nftEvents;
    uint256 public nextEventId;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createNFTEvent(uint256 _releaseTime, address _nftContract, uint256 _tokenId, address _donationContract) public onlyOwner {
        require(_releaseTime > block.timestamp, "Release time is before current time.");

        nftEvents[nextEventId] = NFTEvent({
            nftContract: _nftContract,
            tokenId: _tokenId,
            releaseTime: _releaseTime,
            donationContract: _donationContract,
            isActive: true
        });

        nextEventId++;
    }

    function transferNFTToWinner(uint256 _eventId) public onlyOwner {
        NFTEvent storage nftEvent = nftEvents[_eventId];
        require(block.timestamp >= nftEvent.releaseTime, "Donation period is not over.");
        require(nftEvent.isActive, "Event is not active.");
        
        address donationContractAddress = nftEvent.donationContract;
        address winner;

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
        
        INFT(nftEvent.nftContract).transferOnce(winner, nftEvent.tokenId);
        nftEvent.isActive = false;

        emit NFTTransferred(winner, nftEvent.nftContract, nftEvent.tokenId);
    }

}

