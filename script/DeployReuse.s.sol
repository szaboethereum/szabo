// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {SzaboObjects} from "../src/SzaboObjects.sol";
import {SzaboRenderer} from "../src/SzaboRenderer.sol";
import {ISeaDrop} from "../src/seadrop/ISeaDrop.sol";
import {PublicDrop} from "../src/seadrop/SeaDropStructs.sol";

/// @title DeployReuse
/// @notice Deploys ONLY a new SzaboObjects contract, reusing the existing
///         SzaboRenderer at address `RENDERER`. Use this when only the token
///         contract needs to change (e.g. adding multiConfigure for OpenSea
///         Studio compatibility). Saves ~2.5M gas vs. full redeploy.
///
/// Key selection is chain-aware:
///   - chain id 1        -> MAINNET_DEPLOYER_KEY
///   - chain id 11155111 -> DEPLOYER_KEY
contract DeployReuse is Script {
    address constant SEADROP = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    address constant OPENSEA_FEE_RECIPIENT = 0x0000a26b00c1F0DF003000390027140000fAa719;

    // Existing renderer addresses per chain (deployed earlier in this project).
    address constant RENDERER_MAINNET = 0x8B7ee142C7143940Be11B26a283d30E8b56888A3;
    address constant RENDERER_SEPOLIA = 0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB;

    string constant NAME = "Szabo Objects";
    string constant SYMBOL = "SZABO";
    uint256 constant MAX_SUPPLY = 2000;
    uint96 constant ROYALTY_BPS = 250;

    uint80 constant MINT_PRICE = 0.001 ether;
    uint16 constant MAX_PER_WALLET = 2;
    uint16 constant SEADROP_FEE_BPS = 1000;

    function run() external {
        uint256 deployerKey = _resolveKey();
        address deployer = vm.addr(deployerKey);
        address rendererAddr = _resolveRenderer();

        console2.log("=== SZABO redeploy (reusing renderer) ===");
        console2.log("chain id:", block.chainid);
        console2.log("deployer:", deployer);
        console2.log("balance :", deployer.balance);
        console2.log("renderer:", rendererAddr);

        vm.startBroadcast(deployerKey);

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = SEADROP;

        SzaboObjects token = new SzaboObjects(
            NAME, SYMBOL, deployer, rendererAddr, allowedSeaDrop, MAX_SUPPLY, deployer, ROYALTY_BPS
        );
        console2.log("SzaboObjects:", address(token));

        token.updateCreatorPayoutAddress(SEADROP, deployer);
        token.updateAllowedFeeRecipient(SEADROP, OPENSEA_FEE_RECIPIENT, true);
        token.updatePayer(SEADROP, deployer, true);

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
        console2.log("Post-deploy:");
        console2.log("1. setContractURI (via cast or Studio)");
        console2.log("2. OpenSea Studio Publish should now work (multiConfigure present)");
        console2.log("3. updatePublicDrop with the real startTime on launch day");
    }

    function _resolveKey() internal view returns (uint256) {
        if (block.chainid == 1) return vm.envUint("MAINNET_DEPLOYER_KEY");
        if (block.chainid == 11155111) return vm.envUint("DEPLOYER_KEY");
        revert("DeployReuse: unsupported chain");
    }

    function _resolveRenderer() internal view returns (address) {
        if (block.chainid == 1) return RENDERER_MAINNET;
        if (block.chainid == 11155111) return RENDERER_SEPOLIA;
        revert("DeployReuse: no renderer on this chain");
    }
}
