// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol"; 



contract Donation is ERC721, Ownable {


    constructor() Ownable(msg.sender) 
    ERC721("GoFundMyLifestyle", "GFML") {}
  
    uint256 donationCounter;
    address largestDonor;
    uint256 largestOffer;
    uint256[] offers;

    function mint(address to, uint256 tokenId)  public // uint256 amount
    {
        _mint(to, tokenId);
        //_safeMint(msg.sender);
        
    }

    function makeAnOffer (address to, uint256 amount) public {

        donationCounter++;

        bool highest = true;
        for (uint i=0; i < offers.length; i++) {
            if (offers[i] < amount) {
                 highest = false;
            }
        }
        
        if (highest == true) {
            largestDonor = to;
            largestOffer = amount;

        }

        offers.push(amount);


    }

}