// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {INonFungibleSeaDropToken} from "../../src/seadrop/INonFungibleSeaDropToken.sol";
import {
    PublicDrop,
    AllowListData,
    TokenGatedDropStage,
    SignedMintValidationParams
} from "../../src/seadrop/SeaDropStructs.sol";

/// @title MockSeaDrop
/// @notice Test-only stand-in for the canonical SeaDrop contract.
///         Acts as a passthrough: any test that wants to simulate a mint just
///         calls mintSeaDrop on this mock, which calls the real token.
contract MockSeaDrop {
    /// @notice Simulate a public mint originating from the SeaDrop singleton.
    function mintTo(address token, address minter, uint256 quantity) external payable {
        INonFungibleSeaDropToken(token).mintSeaDrop(minter, quantity);
    }

    /// @notice Push-config endpoints (no-ops — just accept the call so the
    ///         token's owner-forwarders don't revert).
    function updatePublicDrop(PublicDrop calldata) external {}
    function updateAllowList(AllowListData calldata) external {}
    function updateTokenGatedDrop(address, TokenGatedDropStage calldata) external {}
    function updateDropURI(string calldata) external {}
    function updateCreatorPayoutAddress(address) external {}
    function updateAllowedFeeRecipient(address, bool) external {}
    function updateSignedMintValidationParams(address, SignedMintValidationParams calldata) external {}
    function updatePayer(address, bool) external {}
}
