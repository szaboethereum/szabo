// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {SzaboObjects} from "../src/SzaboObjects.sol";
import {SzaboRenderer} from "../src/SzaboRenderer.sol";
import {ISeaDrop} from "../src/seadrop/ISeaDrop.sol";
import {PublicDrop} from "../src/seadrop/SeaDropStructs.sol";
import {ISeaDropTokenContractMetadata} from "../src/seadrop/ISeaDropTokenContractMetadata.sol";

/// @title Deploy
/// @notice Deploys SzaboObjects and configures the OpenSea SeaDrop PublicDrop
///         stage in a single run. After this script:
///         - Contract is live with 2000 max supply and on-chain renderer.
///         - SeaDrop knows the creator payout address and fee recipient.
///         - OpenSea Drops page is listed automatically once the Studio
///           metadata is populated.
///
/// Usage:
///   forge script script/Deploy.s.sol:Deploy \
///     --rpc-url sepolia \
///     --private-key $DEPLOYER_KEY \
///     --broadcast
contract Deploy is Script {
    /// @notice Canonical SeaDrop address (same on mainnet, sepolia, etc.).
    address constant SEADROP = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;

    /// @notice OpenSea's fee recipient for Drops (mainnet). The fee is set
    ///         via the SeaDrop PublicDrop struct and paid on top of the mint
    ///         price; this is informational. OpenSea docs list allowed
    ///         recipients. For sepolia / testnet, this same address is used.
    ///         If this address changes upstream, update both here and in the
    ///         SeaDrop admin UI.
    address constant OPENSEA_FEE_RECIPIENT = 0x0000a26b00c1F0DF003000390027140000fAa719;

    // ─── Collection parameters ───────────────────────────────────────────────

    string constant NAME = "Szabo Objects";
    string constant SYMBOL = "SZABO";
    uint256 constant MAX_SUPPLY = 2000;
    uint96 constant ROYALTY_BPS = 250; // 2.5%

    // ─── PublicDrop parameters ───────────────────────────────────────────────
    // 0.001 ETH mint price, per-wallet cap of 2, fee of 10% to OpenSea
    // (OpenSea charges this flat on Drops; creator keeps the rest).

    uint80 constant MINT_PRICE = 0.001 ether;
    uint16 constant MAX_PER_WALLET = 2;
    uint16 constant SEADROP_FEE_BPS = 1000; // 10%, mandated by OpenSea Studio

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // 1. Deploy renderer first so SzaboObjects can bind to it.
        SzaboRenderer renderer = new SzaboRenderer();
        console2.log("SzaboRenderer deployed:", address(renderer));

        // 2. Deploy token.
        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = SEADROP;

        SzaboObjects token = new SzaboObjects(
            NAME, SYMBOL, deployer, address(renderer), allowedSeaDrop, MAX_SUPPLY, deployer, ROYALTY_BPS
        );
        console2.log("SzaboObjects deployed:", address(token));

        // 3. Tell SeaDrop where to send creator payouts.
        token.updateCreatorPayoutAddress(SEADROP, deployer);

        // 4. Allow OpenSea's Drops fee recipient. The UI will not list the
        //    drop unless at least this recipient is allowed.
        token.updateAllowedFeeRecipient(SEADROP, OPENSEA_FEE_RECIPIENT, true);

        // 5. Push a PublicDrop stage that is still paused (startTime == 0
        //    means inactive on SeaDrop's side). We populate real timestamps
        //    through the OpenSea Studio UI once the drop page is ready.
        PublicDrop memory publicDrop = PublicDrop({
            mintPrice: MINT_PRICE,
            startTime: uint48(block.timestamp + 365 days), // placeholder
            endTime: uint48(block.timestamp + 730 days),
            maxTotalMintableByWallet: MAX_PER_WALLET,
            feeBps: SEADROP_FEE_BPS,
            restrictFeeRecipients: true
        });
        token.updatePublicDrop(SEADROP, publicDrop);

        // 6. Optional: collection-level contract URI for OpenSea (can also
        //    be set through the Studio UI). Leaving empty here; update via
        //    token.setContractURI("ipfs://...") post-deploy.

        console2.log("Configured SeaDrop with placeholder start time.");
        console2.log("Open the Drops UI and set the real start/end times.");

        vm.stopBroadcast();
    }
}
