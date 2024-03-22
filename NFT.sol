// SPDX-License-Identifier: UNLICENSED
// Your code here
pragma solidity ^0.8.20;

import "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";


/// @title MyNFT - A contract for creating and managing NFTs
contract MyNFT is ERC721, Ownable {
    struct tokenMetadata {
        string link;
    }
    
    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    mapping(uint256 => bool) private _transferred;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }
    
    /// @dev Mints a new NFT and assigns it to the parent timelock contract
    /// @param dapp The address to assign the NFT to
    /// @param tokenId The ID of the NFT - we can maybe change this to a string combo of creator name and content name
    /// @param link The metadata link associated with the NFT - ie the IPFS/Filecoin link to content
    function mint(address dapp, uint256 tokenId, string memory link) external onlyOwner {
        require(!_exists(tokenId), "Token already minted");
        _mint(dapp, tokenId);
        _tokenMetadata[tokenId] = tokenMetadata(link);
    }
    
    /// @dev Transfers the NFT to the specified address, largest donor or content creator, but only once
    /// @param to The address to transfer the NFT to
    /// @param tokenId The ID of the NFT - same as from mint
    function transferOnce(address to, uint256 tokenId) external {
        // add onlyOwner modifier to prevent anyone from transferring the token if we need for more fns
        require(ownerOf(tokenId) == msg.sender, "Only token owner can transfer");
        // this might be redundant given the _beforetoken transfer function - but keeping for now
        require(!_transferred[tokenId], "Token already transferred once");
        
        _transfer(msg.sender, to, tokenId);
        _transferred[tokenId] = true;
    }
    
    /// @dev Returns the metadata link associated with the NFT
    /// @param tokenId The ID of the NFT
    /// @return The metadata link
    function tokenLink(uint256 tokenId) external view returns (string memory) {
        return _tokenMetadata[tokenId].link;
    }
    
    /** SOLIDITY VERSION
     * @dev Function that is called before any token transfer.
     * It checks if the token has already been transferred once - if no, transfer is allowed.
     * If the transfer is not allowed, it reverts the transaction with an error message.
     * This function overrides the parent implementation from the ERC721 contract.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param tokenId The ID of the token being transferred.

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal override virtual {
        require(from == address(0) || to == address(0) || !_transferred[tokenId], "Token transfer is blocked");
        super._beforeTokenTransfer(from, to, tokenId);
    }      
    */


    /**
     * @dev Function that is called before any token approval. - YUL version
     * It checks if the token has already been transferred once - if no, approval is allowed.
     * If the approval is not allowed, it reverts the transaction with an error message.
     * This function overrides the parent implementation from the ERC721 contract.
     * @param owner The address giving approval.
     * @param approved The address receiving approval.
     * @param tokenId The ID of the token being approved.
     */
     function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
     ) internal override virtual {
        // because require takes up more gas than if statement
        assembly {
            let transferred := sload(_transferred.slot)
            switch transferred
            case 0 {
                sstore(_transferred.slot, 1)
            }
            default {
                // revert/return if token has already been transferred
            revert(0,0)
            }
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }
}
