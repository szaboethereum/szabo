// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Vendored from ProjectOpenSea/seadrop
// src/interfaces/INonFungibleSeaDropToken.sol
// Pragma bumped 0.8.17 → ^0.8.20.
// This is the interface our token contract implements so that the canonical
// SeaDrop singleton can discover it via ERC-165 and invoke mintSeaDrop().

import {ISeaDropTokenContractMetadata} from "./ISeaDropTokenContractMetadata.sol";
import {AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams} from "./SeaDropStructs.sol";

/// @title INonFungibleSeaDropToken
/// @notice Contract-side SeaDrop integration surface. All drop-stage mutations
///         are push-only: the token contract forwards calls to the SeaDrop
///         implementation listed in its allow-list. Mint-state views are
///         pulled by SeaDrop to enforce per-wallet and per-supply limits.
interface INonFungibleSeaDropToken is ISeaDropTokenContractMetadata {
    /// @notice Thrown when a SeaDrop-gated function is called by an address
    ///         that isn't in the allowed-SeaDrop list.
    error OnlyAllowedSeaDrop();

    /// @notice Emitted when the allowed SeaDrop implementations change.
    event AllowedSeaDropUpdated(address[] allowedSeaDrop);

    /// @notice Replace the set of allowed SeaDrop implementations.
    function updateAllowedSeaDrop(address[] calldata allowedSeaDrop) external;

    /// @notice Mint `quantity` tokens to `minter`. Only callable by an allowed
    ///         SeaDrop contract. Implementers must guard against reentrancy
    ///         across multiple SeaDrops and update mint counters before
    ///         external transfers.
    function mintSeaDrop(address minter, uint256 quantity) external;

    /// @notice Returns minter-specific mint statistics used by SeaDrop to
    ///         enforce per-wallet and per-supply caps.
    function getMintStats(address minter)
        external
        view
        returns (uint256 minterNumMinted, uint256 currentTotalSupply, uint256 maxSupply);

    function updatePublicDrop(address seaDropImpl, PublicDrop calldata publicDrop) external;

    function updateAllowList(address seaDropImpl, AllowListData calldata allowListData) external;

    function updateTokenGatedDrop(address seaDropImpl, address allowedNftToken, TokenGatedDropStage calldata dropStage)
        external;

    function updateDropURI(address seaDropImpl, string calldata dropURI) external;

    function updateCreatorPayoutAddress(address seaDropImpl, address payoutAddress) external;

    function updateAllowedFeeRecipient(address seaDropImpl, address feeRecipient, bool allowed) external;

    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;

    function updatePayer(address seaDropImpl, address payer, bool allowed) external;
}
