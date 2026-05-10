// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {SzaboObjectsV2} from "../src/SzaboObjectsV2.sol";

/// @title DeployV2
/// @notice Deploys SzaboObjectsV2 (no SeaDrop, no middleman).
///         Reuses the existing SzaboRenderer on mainnet/sepolia.
///         After deploy: owner calls openMint() when ready to launch.
contract DeployV2 is Script {
    address constant RENDERER_MAINNET = 0x8B7ee142C7143940Be11B26a283d30E8b56888A3;
    address constant RENDERER_SEPOLIA = 0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB;

    uint256 constant MAX_SUPPLY = 2000;
    uint96 constant ROYALTY_BPS = 250; // 2.5%

    function run() external {
        uint256 deployerKey = _resolveKey();
        address deployer = vm.addr(deployerKey);
        address rendererAddr = block.chainid == 1 ? RENDERER_MAINNET : RENDERER_SEPOLIA;

        console2.log("=== SzaboObjectsV2 deploy (no SeaDrop) ===");
        console2.log("chain:", block.chainid);
        console2.log("deployer:", deployer);
        console2.log("renderer:", rendererAddr);
        console2.log("balance:", deployer.balance);

        vm.startBroadcast(deployerKey);

        SzaboObjectsV2 token = new SzaboObjectsV2(deployer, rendererAddr, MAX_SUPPLY, deployer, ROYALTY_BPS);
        console2.log("SzaboObjectsV2:", address(token));

        vm.stopBroadcast();

        console2.log("---");
        console2.log("Next: owner calls openMint() when ready to launch.");
        console2.log("Then update frontend TOKEN address to:", address(token));
    }

    function _resolveKey() internal view returns (uint256) {
        if (block.chainid == 1) return vm.envUint("MAINNET_DEPLOYER_KEY");
        if (block.chainid == 11155111) return vm.envUint("DEPLOYER_KEY");
        revert("unsupported chain");
    }
}
