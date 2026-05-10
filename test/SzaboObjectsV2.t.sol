// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {SzaboObjectsV2} from "../src/SzaboObjectsV2.sol";
import {SzaboRenderer} from "../src/SzaboRenderer.sol";

contract SzaboObjectsV2Test is Test {
    SzaboObjectsV2 internal token;
    SzaboRenderer internal renderer;

    address internal deployer = makeAddr("deployer");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        renderer = new SzaboRenderer();
        vm.prank(deployer);
        token = new SzaboObjectsV2(deployer, address(renderer), 2000, deployer, 250);
        vm.prank(deployer);
        token.openMint();
    }

    // ─── Mint ────────────────────────────────────────────────────────────────

    function test_Mint_Single() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.ownerOf(1), alice);
    }

    function test_Mint_Batch() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.002 ether}(2);
        assertEq(token.balanceOf(alice), 2);
    }

    function test_Mint_DifferentSeeds() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.002 ether}(2);
        (bytes32 s1,,) = token.objects(1);
        (bytes32 s2,,) = token.objects(2);
        assertTrue(s1 != s2);
    }

    function test_Mint_OriginalMinterPreserved() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);
        vm.prank(alice);
        token.transferFrom(alice, bob, 1);
        (,, address minter) = token.objects(1);
        assertEq(minter, alice);
        assertEq(token.ownerOf(1), bob);
    }

    // ─── Deployer Block ──────────────────────────────────────────────────────

    function test_Deployer_CannotMint() public {
        vm.deal(deployer, 1 ether);
        vm.prank(deployer);
        vm.expectRevert(SzaboObjectsV2.DeployerCannotMint.selector);
        token.mint{value: 0.001 ether}(1);
    }

    function test_Deployer_CannotReceiveTransfer() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);

        vm.prank(alice);
        vm.expectRevert(SzaboObjectsV2.DeployerCannotMint.selector);
        token.transferFrom(alice, deployer, 1);
    }

    // ─── Payment ─────────────────────────────────────────────────────────────

    function test_Mint_WrongPayment() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(SzaboObjectsV2.WrongPayment.selector);
        token.mint{value: 0.002 ether}(1); // overpay
    }

    function test_Mint_RevenueStaysInContract() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);
        assertEq(address(token).balance, 0.001 ether);
    }

    function test_Withdraw() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.002 ether}(2);

        uint256 before = deployer.balance;
        vm.prank(deployer);
        token.withdraw();
        assertEq(deployer.balance - before, 0.002 ether);
    }

    // ─── Per-wallet limit ────────────────────────────────────────────────────

    function test_Mint_ExceedsPerWallet() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.002 ether}(2);

        vm.prank(alice);
        vm.expectRevert(SzaboObjectsV2.ExceedsPerWalletLimit.selector);
        token.mint{value: 0.001 ether}(1);
    }

    // ─── Supply cap ──────────────────────────────────────────────────────────

    function test_Mint_ExceedsSupply() public {
        // Deploy with maxSupply = 2
        vm.prank(deployer);
        SzaboObjectsV2 small = new SzaboObjectsV2(deployer, address(renderer), 2, deployer, 250);
        vm.prank(deployer);
        small.openMint();

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        small.mint{value: 0.002 ether}(2);

        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert(SzaboObjectsV2.ExceedsMaxSupply.selector);
        small.mint{value: 0.001 ether}(1);
    }

    // ─── Pause ───────────────────────────────────────────────────────────────

    function test_Pause_BlocksMint() public {
        vm.prank(deployer);
        token.emergencyPauseMinting();

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(SzaboObjectsV2.MintingIsPaused.selector);
        token.mint{value: 0.001 ether}(1);
    }

    function test_Pause_AutoExpires() public {
        vm.prank(deployer);
        token.emergencyPauseMinting();
        vm.warp(block.timestamp + 48 hours + 1);

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);
        assertEq(token.balanceOf(alice), 1);
    }

    // ─── openMint ────────────────────────────────────────────────────────────

    function test_MintNotOpen() public {
        vm.prank(deployer);
        SzaboObjectsV2 closed = new SzaboObjectsV2(deployer, address(renderer), 2000, deployer, 250);

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert(SzaboObjectsV2.MintNotOpen.selector);
        closed.mint{value: 0.001 ether}(1);
    }

    // ─── setMaxSupply ratchet ────────────────────────────────────────────────

    function test_SetMaxSupply_CanDecrease() public {
        vm.prank(deployer);
        token.setMaxSupply(1500);
        assertEq(token.maxSupply(), 1500);
    }

    function test_SetMaxSupply_CannotIncrease() public {
        vm.prank(deployer);
        vm.expectRevert(SzaboObjectsV2.CannotIncreaseMaxSupply.selector);
        token.setMaxSupply(2001);
    }

    // ─── Royalty ─────────────────────────────────────────────────────────────

    function test_Royalty() public view {
        (address receiver, uint256 amount) = token.royaltyInfo(1, 1 ether);
        assertEq(receiver, deployer);
        assertEq(amount, 0.025 ether); // 2.5%
    }

    function test_Royalty_CannotExceedCap() public {
        vm.prank(deployer);
        vm.expectRevert(SzaboObjectsV2.RoyaltyTooHigh.selector);
        token.setRoyaltyInfo(alice, 1001);
    }

    // ─── tokenURI ────────────────────────────────────────────────────────────

    function test_TokenURI_OnChain() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.mint{value: 0.001 ether}(1);

        string memory uri = token.tokenURI(1);
        bytes memory prefix = bytes("data:application/json;base64,");
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(bytes(uri)[i], prefix[i]);
        }
    }

    // ─── ERC-165 ─────────────────────────────────────────────────────────────

    function test_SupportsERC721() public view {
        assertTrue(token.supportsInterface(0x80ac58cd));
    }

    function test_SupportsERC2981() public view {
        assertTrue(token.supportsInterface(0x2a55205a));
    }
}
