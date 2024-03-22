// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol"; 

import "../hedera-services/hedera-node/test-clients/src/main/resource/contract/solidity/hip-206/HederaResponseCodes.sol";
import "../hedera-services/hedera-node/test-clients/src/main/resource/contract/solidity/hip-206/IHederaTokenService.sol";
import  "../hedera-services/hedera-node/test-clients/src/main/resource/contract/solidity/hip-206/HederaResponseCodes.sol";

contract Donation is ERC721, Ownable {


    constructor() Ownable(msg.sender) 
    ERC721("GoFundMyLifestyle", "GFML") {}
  
    bool auctionActive = true;

    uint256 donationCounter;
    mapping(address => uint256) allBids;
    address largestDonor;
    uint256 largestOffer;
    uint256[] allOffers;

    function mint(address to, uint256 tokenId)  public // uint256 amount
    {
        _mint(to, tokenId);
        //_safeMint(msg.sender);
        
    }

    function makeAnOffer(address to, uint256 amount) public payable returns(address) {
        require(auctionActive, "The auction isn't active anymore");
        require(msg.value > 0.01 ether, "Need to send 0.01 ether for the fees");

        donationCounter++;

        bool highest = true;
        for (uint i=0; i < allOffers.length; i++) {
            if (allOffers[i] < amount) {
                 highest = false;
            }
        }
        
        if (highest == true) {
            largestDonor = to;
            largestOffer = amount;

        }

        
        allOffers.push(amount);
        return to;

    }

    function MakeDonation() public payable returns(bool) {

        require(auctionActive, "The auction isn't active anymore");
        require(msg.value > 0.01 ether, "Need to send 0.01 ether for the fees");
    

        uint256 newOffer = msg.value;
        uint256 temporaryBestOffer = allBids[largestDonor];

        allBids[msg.sender] = newOffer;
        donationCounter++; 

        if (newOffer > temporaryBestOffer) {
            largestOffer = newOffer;
            largestDonor = msg.sender;

        }
        return true;
    }

    function transferNft( address token, address receiver, int64 serial) external returns(int){

        IHederaTokenService ihts = new IHederaTokenService();
        int response = ihts.transferNFT(token, address(this), receiver, serial);

        if(response != HederaResponseCodes.SUCCESS){
            revert("Failed to transfer non-fungible token");
        }

        return response;
    }

}