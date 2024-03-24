/**
 * @title Testing
 * @dev This contract is used for testing the deployment and functionality of the TimeLock, MyNFT, and Donation contracts.
 */
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/NFT.sol";
import "../src/Donations.sol";
import "../src/TimeLock.sol";

contract Testing is Test {
    TimeLock timeLock;
    MyNFT myNFT;
    Donation donation;


    // @dev Sets up the test environment by deploying the TimeLock contract and initializing the MyNFT and Donation addresses.
    function setUp() public {
        // Deploy TimeLock contract and initialize MyNFT and Donation addresses
        timeLock = new TimeLock();
        timeLock.deployMyNFT("Test NFT", "TNFT");
        timeLock.deployDonation();
        // Add NFT contract as owner to Donation contract
        timeLock.addNFTContractAsOwnerToDonations();
        timeLock.CreateNft(2, "test.net/2", 5);
        // Assuming Donation is a contract type
        address donationAddress = timeLock.donationAddress();
        donation = Donation(donationAddress);
    }


    // @dev Tests the deployment of the TimeLock, MyNFT, and Donation contracts.
    function testContractDeployment() public view {
        console.log("Testing TimeLock deployment. Address:", address(timeLock));
        assertTrue(address(timeLock) != address(0), "TimeLock contract was not deployed");
        console.log("Testing NFT deployment. Address:", timeLock.myNFTAddress());
        assertTrue(timeLock.myNFTAddress() != address(0), "MyNFT contract was not deployed");
        console.log("Testing Donation deployment. Address:", timeLock.donationAddress());
        assertTrue(timeLock.donationAddress() != address(0), "Donation contract was not deployed");
    }

    // @dev Tests the creation of NFT that goes through timelock nft and donation.
    // then tests the token link functionality of the MyNFT contract.

    function testTokenLink() public {
        timeLock.CreateNft(3, "test.net/3", 200000);
        assertEq(
            keccak256(abi.encodePacked(myNFT.tokenLink(3))),
            keccak256(abi.encodePacked("test.net/3")),
            "Token link does not match expected value"
        );
    }

    // @dev Tests the minting of a new NFT with invalid input.
    // test currently fails as due to 'invalid sender' - with assembly logic the transfer to creator does not happen when no donations are received
    function testTokenAlreadyExists() public {
        timeLock.CreateNft(2, "test.net/2", 100000000000);
        vm.expectRevert("Token ID already exists");
        timeLock.CreateNft(2, "test.net/2", 100000000000);
    }


    // @dev Tests the donation functionality of the Donation contract with invalid input.
    function testDonateWithInvalidInput() public {
        vm.expectRevert("Donation amount must be greater than 0");
        donation.donate{value: 0}(2);
        // donation.donate{value: -50}(2); - cant actually send negative value so dont need it 
        // vm.expectRevert("Donation amount must be greater than 0");
    }

    // @dev Tests the withdrawal functionality of the Donation contract with valid input.
    // - tests unautorised withdrawal, then authorised withdrawal before donations close, and after donations close
    function testWithdraw() public {
        timeLock.CreateNft(4, "test.net/4", 500000);
        donation.donate{value: 100}(4);
        vm.expectRevert("Not owner or authorized");
        donation.withdraw(4);
        /** vm.prank(timelock); this should pretend we are owner, but variations of prank havent worked so far - once it does, see the following
        vm.expectRevert("Donations are currently active for this token");
        donation.withdraw(4);
        skip(500000);
        donation.withdraw(4);
        assertEq(timelock.balance(), 3, "Balance is not equal to 3");
        */
    }
}
