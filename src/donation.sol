// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol"; 



contract Donation is ERC721, Ownable {


    constructor() Ownable(msg.sender) 
    ERC721("GoFundMyLifestyle", "GFML") {}
  
    uint256 donationCounter;
    mapping(address => uint256) highestBidder;
    address largestDonor;
    uint256 largestOffer;
    uint256[] allOffers;

    function mint(address to, uint256 tokenId)  public // uint256 amount
    {
        _mint(to, tokenId);
        //_safeMint(msg.sender);
        
    }

    function makeAnOffer (address to, uint256 amount) public returns(address) {

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
            //mapping(address => uint256) highestBidder;
            highestBidder[to] = amount;

        }

        
        allOffers.push(amount);
        return to;

    }

}