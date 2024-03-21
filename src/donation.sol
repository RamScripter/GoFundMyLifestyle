// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol"; 

/// @title Coinflip 10 in a Row
/// @author Stellan WEA
/// @notice Contract used as part of the course Solidity and Smart Contract development

//contract Donation is Ownable {

contract Donation is ERC721, Ownable {
    constructor() Ownable(msg.sender) 
    ERC721("GoFundMyLifestyle", "GFML") {}
  
    function mint(address to, uint256 tokenId)  public //, uint256 amount
    {
        //require(msg.value>0,"Your account is empty");
        _mint(to, tokenId) ;
    }

}