// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SzaboObjects} from "../src/SzaboObjects.sol";
import {SzaboRenderer} from "../src/SzaboRenderer.sol";

/// @notice Fork-only sanity check against the live Sepolia deploy.
///         Pulls tokenURI from the deployed renderer at different block
///         heights to confirm patina evolves as designed.
///
/// Run with:
///   forge test --fork-url $SEPOLIA_RPC_URL --match-contract SepoliaForkTest -vvv
contract SepoliaForkTest is Test {
    address constant TOKEN = 0x061077B2cdc9774cD77aC098326422667aE5a650;

    SzaboObjects internal token;

    function setUp() public {
        try vm.envString("SEPOLIA_RPC_URL") returns (string memory url) {
            vm.createSelectFork(url);
            token = SzaboObjects(TOKEN);
        } catch {
            vm.skip(true);
        }
    }

    function test_Fork_TokenOneExists() public view {
        assertEq(token.ownerOf(1), 0x118ebF25b1970Fd35356E552218dFA01e43e7798);
    }

    function test_Fork_PatinaProgression() public {
        (, uint256 birthBlock,) = token.objects(1);
        SzaboRenderer renderer = token.renderer();

        // Fresh
        assertEq(renderer.patinaLevel(birthBlock), 0, "fresh");

        // Jump forward to Aged (+50_001 blocks from birth)
        vm.roll(birthBlock + 50_001);
        assertEq(renderer.patinaLevel(birthBlock), 1, "aged");

        // Antique
        vm.roll(birthBlock + 200_001);
        assertEq(renderer.patinaLevel(birthBlock), 2, "antique");

        // Relic
        vm.roll(birthBlock + 500_001);
        assertEq(renderer.patinaLevel(birthBlock), 3, "relic");
    }

    function test_Fork_TokenURIChangesWithPatina() public {
        string memory fresh = token.tokenURI(1);

        (, uint256 birthBlock,) = token.objects(1);
        vm.roll(birthBlock + 500_001);

        string memory relic = token.tokenURI(1);

        // Different block numbers should produce different SVG bytes
        // (patina overlay added, "Age (blocks)" attribute changed).
        assertFalse(keccak256(bytes(fresh)) == keccak256(bytes(relic)), "uri identical across patina");
    }
}
