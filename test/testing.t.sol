pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/NFT.sol";
import "../src/Donations.sol";
import "../src/TimeLock.sol";


contract Testing is Test {
    TimeLock timeLock;
    MyNFT myNFT;
    Donation donation;


    function setUp() public {

        // Deploy TimeLock contract and initialize MyNFT and Donation addresses
        timeLock = new TimeLock();
        timeLock.deployMyNFT("Test NFT", "TNFT");
        timeLock.deployDonation();
        // Add NFT contract as owner to Donation contract
        timeLock.addNFTContractAsOwnerToDonations();
    }

    function testTokenLink() public {
        timeLock.CreateNft(2, "test.net/2", 5);
        assertEq(
            keccak256(abi.encodePacked(myNFT.tokenLink(2))),
            keccak256(abi.encodePacked("test.net/2")),
            "Token link does not match expected value"
        );
    }
}


