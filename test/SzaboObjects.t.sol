// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SzaboObjects} from "../src/SzaboObjects.sol";
import {SzaboRenderer} from "../src/SzaboRenderer.sol";
import {INonFungibleSeaDropToken, MultiConfigureStruct} from "../src/seadrop/INonFungibleSeaDropToken.sol";
import {ISeaDropTokenContractMetadata} from "../src/seadrop/ISeaDropTokenContractMetadata.sol";
import {
    AllowListData,
    PublicDrop,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "../src/seadrop/SeaDropStructs.sol";
import {SzaboTraits} from "../src/libraries/SzaboTraits.sol";
import {MockSeaDrop} from "./mocks/MockSeaDrop.sol";

contract SzaboObjectsTest is Test {
    SzaboObjects internal token;
    SzaboRenderer internal renderer;
    MockSeaDrop internal seaDrop;

    address internal deployer = makeAddr("deployer");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256 constant MAX_SUPPLY = 2000;
    uint96 constant ROYALTY_BPS = 250;

    function setUp() public {
        seaDrop = new MockSeaDrop();
        renderer = new SzaboRenderer();

        address[] memory allowed = new address[](1);
        allowed[0] = address(seaDrop);

        vm.prank(deployer);
        token = new SzaboObjects(
            "Szabo Objects", "SZABO", deployer, address(renderer), allowed, MAX_SUPPLY, deployer, ROYALTY_BPS
        );
    }

    // ─── Construction ────────────────────────────────────────────────────────

    function test_Constructor_SetsBasicFields() public view {
        assertEq(token.name(), "Szabo Objects");
        assertEq(token.symbol(), "SZABO");
        assertEq(token.owner(), deployer);
        assertEq(token.deployer(), deployer);
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertEq(token.royaltyAddress(), deployer);
        assertEq(token.royaltyBasisPoints(), ROYALTY_BPS);
        assertEq(address(token.renderer()), address(renderer));
    }

    function test_Constructor_SeaDropAllowListed() public view {
        address[] memory got = token.allowedSeaDrop();
        assertEq(got.length, 1);
        assertEq(got[0], address(seaDrop));
    }

    function test_Constructor_RevertsOnZeroDeployer() public {
        address[] memory allowed = new address[](0);
        vm.expectRevert();
        new SzaboObjects("N", "S", address(0), address(renderer), allowed, 1, deployer, 0);
    }

    function test_Constructor_RevertsOnZeroRenderer() public {
        address[] memory allowed = new address[](0);
        vm.expectRevert(SzaboObjects.ZeroAddress.selector);
        new SzaboObjects("N", "S", deployer, address(0), allowed, 1, deployer, 0);
    }

    function test_Constructor_RevertsOnTooHighRoyalty() public {
        address[] memory allowed = new address[](0);
        vm.expectRevert(SzaboObjects.RoyaltyTooHigh.selector);
        new SzaboObjects("N", "S", deployer, address(renderer), allowed, 1, deployer, 1001);
    }

    // ─── Mint: happy path ────────────────────────────────────────────────────

    function test_Mint_SingleFromSeaDrop() public {
        seaDrop.mintTo(address(token), alice, 1);
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.ownerOf(1), alice);

        (bytes32 seed, uint256 birthBlock, address originalMinter) = token.objects(1);
        assertTrue(seed != bytes32(0));
        assertEq(birthBlock, block.number);
        assertEq(originalMinter, alice);
    }

    function test_Mint_BatchDifferentSeeds() public {
        seaDrop.mintTo(address(token), alice, 5);

        bytes32[] memory seeds = new bytes32[](5);
        for (uint256 i = 0; i < 5; i++) {
            (bytes32 s,,) = token.objects(i + 1);
            seeds[i] = s;
        }
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = i + 1; j < 5; j++) {
                assertTrue(seeds[i] != seeds[j], "seed collision in batch");
            }
        }
    }

    function test_Mint_OriginalMinterPreservedAcrossTransfer() public {
        seaDrop.mintTo(address(token), alice, 1);
        vm.prank(alice);
        token.transferFrom(alice, bob, 1);

        (,, address originalMinter) = token.objects(1);
        assertEq(originalMinter, alice, "originalMinter must not change on transfer");
        assertEq(token.ownerOf(1), bob);
    }

    // ─── Mint: guards ────────────────────────────────────────────────────────

    function test_Mint_RevertsFromNonSeaDrop() public {
        vm.expectRevert(INonFungibleSeaDropToken.OnlyAllowedSeaDrop.selector);
        token.mintSeaDrop(alice, 1);
    }

    function test_Mint_RevertsWhenRecipientIsDeployer() public {
        vm.expectRevert(SzaboObjects.DeployerCannotMint.selector);
        seaDrop.mintTo(address(token), deployer, 1);
    }

    function test_Mint_RevertsWhenExceedsSupply() public {
        vm.expectRevert(SzaboObjects.ExceedsMaxSupply.selector);
        seaDrop.mintTo(address(token), alice, MAX_SUPPLY + 1);
    }

    // ─── Pause ───────────────────────────────────────────────────────────────

    function test_Pause_BlocksMint() public {
        vm.prank(deployer);
        token.emergencyPauseMinting();

        vm.expectRevert(SzaboObjects.MintingIsPaused.selector);
        seaDrop.mintTo(address(token), alice, 1);
    }

    function test_Pause_AutoExpiresAfter48h() public {
        vm.prank(deployer);
        token.emergencyPauseMinting();

        vm.warp(block.timestamp + 48 hours + 1);

        seaDrop.mintTo(address(token), alice, 1);
        assertEq(token.balanceOf(alice), 1);
        assertFalse(token.mintingPaused());
    }

    function test_Pause_OwnerCanResumeEarly() public {
        vm.prank(deployer);
        token.emergencyPauseMinting();

        vm.prank(deployer);
        token.resumeMinting();

        seaDrop.mintTo(address(token), alice, 1);
        assertEq(token.balanceOf(alice), 1);
    }

    // ─── setMaxSupply ratchet ────────────────────────────────────────────────

    function test_SetMaxSupply_CanDecrease() public {
        vm.prank(deployer);
        token.setMaxSupply(1500);
        assertEq(token.maxSupply(), 1500);
    }

    function test_SetMaxSupply_CannotIncrease() public {
        vm.prank(deployer);
        vm.expectRevert(SzaboObjects.CannotIncreaseMaxSupply.selector);
        token.setMaxSupply(MAX_SUPPLY + 1);
    }

    function test_SetMaxSupply_CannotGoBelowAlreadyMinted() public {
        seaDrop.mintTo(address(token), alice, 10);

        vm.prank(deployer);
        vm.expectRevert(SzaboObjects.ExceedsMaxSupply.selector);
        token.setMaxSupply(5);
    }

    // ─── Royalty (ERC-2981) ──────────────────────────────────────────────────

    function test_Royalty_ReturnsExpectedSplit() public view {
        (address receiver, uint256 amount) = token.royaltyInfo(1, 1 ether);
        assertEq(receiver, deployer);
        assertEq(amount, (1 ether * ROYALTY_BPS) / 10_000);
    }

    function test_SetRoyalty_CannotExceedCap() public {
        vm.prank(deployer);
        ISeaDropTokenContractMetadata.RoyaltyInfo memory info =
            ISeaDropTokenContractMetadata.RoyaltyInfo({royaltyAddress: alice, royaltyBps: 1001});
        vm.expectRevert();
        token.setRoyaltyInfo(info);
    }

    // ─── tokenURI (on-chain SVG) ────────────────────────────────────────────

    function test_TokenURI_ReturnsDataURI() public {
        seaDrop.mintTo(address(token), alice, 1);
        string memory uri = token.tokenURI(1);
        assertTrue(bytes(uri).length > 50);
        bytes memory prefix = bytes("data:application/json;base64,");
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(bytes(uri)[i], prefix[i]);
        }
    }

    function test_TokenURI_RevertsForNonexistent() public {
        vm.expectRevert(SzaboObjects.InvalidTokenId.selector);
        token.tokenURI(999);
    }

    // ─── Patina (via renderer) ──────────────────────────────────────────────

    function test_Patina_StartsFresh() public {
        seaDrop.mintTo(address(token), alice, 1);
        (, uint256 birthBlock,) = token.objects(1);
        assertEq(renderer.patinaLevel(birthBlock), 0);
    }

    function test_Patina_AdvancesWithBlockNumber() public {
        seaDrop.mintTo(address(token), alice, 1);
        (, uint256 birthBlock,) = token.objects(1);

        vm.roll(block.number + 50_001);
        assertEq(renderer.patinaLevel(birthBlock), 1);

        vm.roll(block.number + 150_000);
        assertEq(renderer.patinaLevel(birthBlock), 2);

        vm.roll(block.number + 300_000);
        assertEq(renderer.patinaLevel(birthBlock), 3);
    }

    // ─── getMintStats (SeaDrop integration) ─────────────────────────────────

    function test_GetMintStats_TracksPerWalletCount() public {
        seaDrop.mintTo(address(token), alice, 2);
        seaDrop.mintTo(address(token), bob, 1);

        (uint256 aliceMinted, uint256 total, uint256 max) = token.getMintStats(alice);
        assertEq(aliceMinted, 2);
        assertEq(total, 3);
        assertEq(max, MAX_SUPPLY);
    }

    // ─── updateAllowedSeaDrop ────────────────────────────────────────────────

    function test_UpdateAllowedSeaDrop_ReplacesList() public {
        MockSeaDrop newDrop = new MockSeaDrop();
        address[] memory next = new address[](1);
        next[0] = address(newDrop);

        vm.prank(deployer);
        token.updateAllowedSeaDrop(next);

        vm.expectRevert(INonFungibleSeaDropToken.OnlyAllowedSeaDrop.selector);
        seaDrop.mintTo(address(token), alice, 1);

        newDrop.mintTo(address(token), alice, 1);
        assertEq(token.balanceOf(alice), 1);
    }

    // ─── supportsInterface ──────────────────────────────────────────────────

    function test_SupportsInterface_ERC721() public view {
        assertTrue(token.supportsInterface(0x80ac58cd));
    }

    function test_SupportsInterface_ERC2981() public view {
        assertTrue(token.supportsInterface(0x2a55205a));
    }

    function test_SupportsInterface_ERC4906() public view {
        assertTrue(token.supportsInterface(0x49064906));
    }

    // ─── Trait decoding sanity (renderer-side) ──────────────────────────────

    function test_Renderer_TokenURI_ValidForMintedToken() public {
        seaDrop.mintTo(address(token), alice, 1);
        (bytes32 seed, uint256 birthBlock, address originalMinter) = token.objects(1);
        string memory uri = renderer.tokenURI(seed, birthBlock, originalMinter, 1);
        assertTrue(bytes(uri).length > 50);
    }

    // ─── Fuzz: per-wallet limit is not enforced at contract level ───────────
    // (SeaDrop enforces maxTotalMintableByWallet; the contract only enforces
    // maxSupply and the deployer block.)

    function testFuzz_ContractAllowsUnlimitedPerWallet_WithinSupply(uint256 n) public {
        n = bound(n, 1, 100);
        seaDrop.mintTo(address(token), alice, n);
        assertEq(token.balanceOf(alice), n);
    }
}


// ─── Lock-in tests for OpenSea Studio compatibility + immutability ──────────

contract SzaboObjectsLockInTest is Test {
    SzaboObjects internal token;
    SzaboRenderer internal renderer;
    MockSeaDrop internal seaDrop;

    address internal deployer = makeAddr("deployer");
    address internal alice = makeAddr("alice");

    function setUp() public {
        seaDrop = new MockSeaDrop();
        renderer = new SzaboRenderer();

        address[] memory allowed = new address[](1);
        allowed[0] = address(seaDrop);

        vm.prank(deployer);
        token = new SzaboObjects(
            "Szabo Objects",
            "SZABO",
            deployer,
            address(renderer),
            allowed,
            2000,
            deployer,
            250
        );
    }

    /// setBaseURI must be a no-op. Even if OpenSea pushes an IPFS URI via
    /// multiConfigure, tokenURI keeps returning the on-chain SVG.
    function test_SetBaseURI_IsNoOp_TokenURIStaysOnChain() public {
        seaDrop.mintTo(address(token), alice, 1);

        string memory before = token.tokenURI(1);

        vm.prank(deployer);
        token.setBaseURI("ipfs://evil-metadata");

        string memory afterCall = token.tokenURI(1);
        assertEq(
            keccak256(bytes(before)),
            keccak256(bytes(afterCall)),
            "tokenURI must not change after setBaseURI"
        );
        assertEq(bytes(token.baseURI()).length, 0, "baseURI must remain empty");
    }

    /// multiConfigure must ignore the `baseURI` field entirely.
    function test_MultiConfigure_IgnoresBaseURI() public {
        // Build a minimal config with a hostile baseURI and contractURI.
        PublicDrop memory emptyDrop;
        AllowListData memory emptyAllowList;

        MultiConfigureStruct memory config = MultiConfigureStruct({
            maxSupply: 0,
            baseURI: "ipfs://should-be-ignored",
            contractURI: "data:application/json;base64,abc",
            seaDropImpl: address(seaDrop),
            publicDrop: emptyDrop,
            dropURI: "",
            allowListData: emptyAllowList,
            creatorPayoutAddress: address(0),
            provenanceHash: bytes32(0),
            allowedFeeRecipients: new address[](0),
            disallowedFeeRecipients: new address[](0),
            allowedPayers: new address[](0),
            disallowedPayers: new address[](0),
            tokenGatedDropStages: new TokenGatedDropStage[](0),
            tokenGatedAllowedNftTokens: new address[](0),
            disallowedTokenGatedAllowedNftTokens: new address[](0),
            signedMintValidationParams: new SignedMintValidationParams[](0),
            signers: new address[](0),
            disallowedSigners: new address[](0)
        });

        vm.prank(deployer);
        token.multiConfigure(config);

        assertEq(bytes(token.baseURI()).length, 0, "baseURI leaked through multiConfigure");
        assertEq(token.contractURI(), "data:application/json;base64,abc");
    }

    /// multiConfigure applied by non-owner must revert.
    function test_MultiConfigure_OnlyOwner() public {
        PublicDrop memory emptyDrop;
        AllowListData memory emptyAllowList;

        MultiConfigureStruct memory config = MultiConfigureStruct({
            maxSupply: 0,
            baseURI: "",
            contractURI: "",
            seaDropImpl: address(seaDrop),
            publicDrop: emptyDrop,
            dropURI: "",
            allowListData: emptyAllowList,
            creatorPayoutAddress: address(0),
            provenanceHash: bytes32(0),
            allowedFeeRecipients: new address[](0),
            disallowedFeeRecipients: new address[](0),
            allowedPayers: new address[](0),
            disallowedPayers: new address[](0),
            tokenGatedDropStages: new TokenGatedDropStage[](0),
            tokenGatedAllowedNftTokens: new address[](0),
            disallowedTokenGatedAllowedNftTokens: new address[](0),
            signedMintValidationParams: new SignedMintValidationParams[](0),
            signers: new address[](0),
            disallowedSigners: new address[](0)
        });

        vm.prank(alice);
        vm.expectRevert();
        token.multiConfigure(config);
    }

    /// multiConfigure must reject unapproved SeaDrop impls.
    function test_MultiConfigure_RejectsForeignSeaDrop() public {
        address foreignDrop = makeAddr("evil-seadrop");
        PublicDrop memory emptyDrop;
        AllowListData memory emptyAllowList;

        MultiConfigureStruct memory config = MultiConfigureStruct({
            maxSupply: 0,
            baseURI: "",
            contractURI: "",
            seaDropImpl: foreignDrop,
            publicDrop: emptyDrop,
            dropURI: "",
            allowListData: emptyAllowList,
            creatorPayoutAddress: address(0),
            provenanceHash: bytes32(0),
            allowedFeeRecipients: new address[](0),
            disallowedFeeRecipients: new address[](0),
            allowedPayers: new address[](0),
            disallowedPayers: new address[](0),
            tokenGatedDropStages: new TokenGatedDropStage[](0),
            tokenGatedAllowedNftTokens: new address[](0),
            disallowedTokenGatedAllowedNftTokens: new address[](0),
            signedMintValidationParams: new SignedMintValidationParams[](0),
            signers: new address[](0),
            disallowedSigners: new address[](0)
        });

        vm.prank(deployer);
        vm.expectRevert(INonFungibleSeaDropToken.OnlyAllowedSeaDrop.selector);
        token.multiConfigure(config);
    }

    /// maxSupply clamp: multiConfigure can only decrease.
    function test_MultiConfigure_MaxSupplyDownOnly() public {
        PublicDrop memory emptyDrop;
        AllowListData memory emptyAllowList;

        MultiConfigureStruct memory config = MultiConfigureStruct({
            maxSupply: 5000, // higher than 2000
            baseURI: "",
            contractURI: "",
            seaDropImpl: address(seaDrop),
            publicDrop: emptyDrop,
            dropURI: "",
            allowListData: emptyAllowList,
            creatorPayoutAddress: address(0),
            provenanceHash: bytes32(0),
            allowedFeeRecipients: new address[](0),
            disallowedFeeRecipients: new address[](0),
            allowedPayers: new address[](0),
            disallowedPayers: new address[](0),
            tokenGatedDropStages: new TokenGatedDropStage[](0),
            tokenGatedAllowedNftTokens: new address[](0),
            disallowedTokenGatedAllowedNftTokens: new address[](0),
            signedMintValidationParams: new SignedMintValidationParams[](0),
            signers: new address[](0),
            disallowedSigners: new address[](0)
        });

        vm.prank(deployer);
        token.multiConfigure(config); // should silently ignore the increase

        assertEq(token.maxSupply(), 2000, "maxSupply must not increase");

        // now decrease
        config.maxSupply = 1500;
        vm.prank(deployer);
        token.multiConfigure(config);
        assertEq(token.maxSupply(), 1500);
    }
}


/// @notice The `multiConfigure` function selector must stay aligned with the
///         upstream ProjectOpenSea/seadrop ERC721SeaDrop.sol so the OpenSea
///         Studio UI's "Publish changes" calldata resolves to our
///         implementation. Drifting the MultiConfigureStruct field order
///         silently breaks the Studio integration — this test catches that
///         at CI time.
contract MultiConfigureSelectorTest is Test {
    function test_MultiConfigure_Selector_MatchesUpstream() public pure {
        bytes4 expected = 0x911f456b;
        bytes4 actual = SzaboObjects.multiConfigure.selector;
        assertEq(actual, expected, "multiConfigure selector drifted from OpenSea upstream");
    }
}
