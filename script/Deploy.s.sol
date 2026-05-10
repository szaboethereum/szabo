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
///         stage in a single run.
///
///         Key selection is chain-aware to prevent mixing Sepolia and mainnet
///         keys:
///         - chain id 1        -> reads MAINNET_DEPLOYER_KEY
///         - chain id 11155111 -> reads DEPLOYER_KEY (Sepolia)
///         - anything else     -> reverts (no local deploys via this script)
///
///         After this script:
///         - Contract is live with 2000 max supply and on-chain renderer.
///         - SeaDrop knows the creator payout address and fee recipient.
///         - Deployer is registered as an allowed payer (lets the owner mint
///           to other addresses for e.g. post-launch verification).
///         - A PublicDrop stage with the correct price/per-wallet is pushed,
///           but with a placeholder startTime 365 days in the future. Replace
///           startTime via `updatePublicDrop` once the launch day is set.
///
/// Usage:
///   # Sepolia
///   forge script script/Deploy.s.sol:Deploy \
///     --rpc-url sepolia --broadcast
///
///   # Mainnet
///   forge script script/Deploy.s.sol:Deploy \
///     --rpc-url mainnet --broadcast --verify --slow
contract Deploy is Script {
    /// @notice Canonical SeaDrop address (identical on mainnet and Sepolia).
    address constant SEADROP = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;

    /// @notice OpenSea's fee recipient for Drops. Identical on mainnet and
    ///         Sepolia. If OpenSea publishes a new address, update here and
    ///         call updateAllowedFeeRecipient(SEADROP, newAddr, true).
    address constant OPENSEA_FEE_RECIPIENT = 0x0000a26b00c1F0DF003000390027140000fAa719;

    // ─── Collection parameters ───────────────────────────────────────────────

    string constant NAME = "Szabo Objects";
    string constant SYMBOL = "SZABO";
    uint256 constant MAX_SUPPLY = 2000;
    uint96 constant ROYALTY_BPS = 250; // 2.5%

    // ─── PublicDrop parameters ───────────────────────────────────────────────
    // 0.001 ETH mint price, per-wallet cap of 2, 10% fee to OpenSea.
    uint80 constant MINT_PRICE = 0.001 ether;
    uint16 constant MAX_PER_WALLET = 2;
    uint16 constant SEADROP_FEE_BPS = 1000;

    function run() external {
        uint256 deployerKey = _resolveKey();
        address deployer = vm.addr(deployerKey);

        console2.log("=== SZABO deploy ===");
        console2.log("chain id:", block.chainid);
        console2.log("deployer:", deployer);
        console2.log("balance :", deployer.balance);

        vm.startBroadcast(deployerKey);

        // 1. Deploy renderer first so SzaboObjects can bind to it.
        SzaboRenderer renderer = new SzaboRenderer();
        console2.log("SzaboRenderer:", address(renderer));

        // 2. Deploy token.
        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = SEADROP;

        SzaboObjects token = new SzaboObjects(
            NAME,
            SYMBOL,
            deployer,
            address(renderer),
            allowedSeaDrop,
            MAX_SUPPLY,
            deployer,
            ROYALTY_BPS
        );
        console2.log("SzaboObjects:", address(token));

        // 3. Direct creator payouts (mint revenue) to the deployer.
        token.updateCreatorPayoutAddress(SEADROP, deployer);

        // 4. Allow OpenSea's Drops fee recipient. The UI won't list the drop
        //    unless at least this recipient is allowed.
        token.updateAllowedFeeRecipient(SEADROP, OPENSEA_FEE_RECIPIENT, true);

        // 5. Register deployer as an allowed payer so the owner can mint to
        //    other addresses for post-deploy verification (e.g. press preview,
        //    archive sample). End-users always pay for themselves and are
        //    implicitly allowed by SeaDrop — this only changes `payer != minter`
        //    behaviour.
        token.updatePayer(SEADROP, deployer, true);

        // 6. Push a PublicDrop with a placeholder startTime 365 days out so
        //    minting stays closed until the launch day is scheduled. The owner
        //    rewrites this via updatePublicDrop once startTime is known.
        PublicDrop memory publicDrop = PublicDrop({
            mintPrice: MINT_PRICE,
            startTime: uint48(block.timestamp + 365 days),
            endTime: uint48(block.timestamp + 730 days),
            maxTotalMintableByWallet: MAX_PER_WALLET,
            feeBps: SEADROP_FEE_BPS,
            restrictFeeRecipients: true
        });
        token.updatePublicDrop(SEADROP, publicDrop);

        vm.stopBroadcast();

        console2.log("---");
        console2.log("Post-deploy next steps:");
        console2.log("1. setContractURI (collection metadata)");
        console2.log("2. updatePublicDrop with the real startTime on launch day");
        console2.log("3. transferOwnership to cold wallet (optional, recommended)");
    }

    /// @dev Chain-aware key resolution. Prevents accidentally using a Sepolia
    ///      key against mainnet (or vice versa).
    function _resolveKey() internal view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 1) {
            return vm.envUint("MAINNET_DEPLOYER_KEY");
        }
        if (chainId == 11155111) {
            return vm.envUint("DEPLOYER_KEY");
        }
        revert("Deploy: unsupported chain");
    }
}
