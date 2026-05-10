// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Vendored subset of ProjectOpenSea/seadrop ISeaDrop.
// Only the functions our token contract actually calls (push-config flow +
// view helpers used in tests) are kept. Struct types come from SeaDropStructs.sol.
// Pragma bumped 0.8.17 → ^0.8.20 to match the rest of the project.

import {AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams} from "./SeaDropStructs.sol";

/// @title ISeaDrop
/// @notice Minimal interface for interacting with the SeaDrop singleton
///         (0x00005EA00Ac477B1030CE78506496e8C2dE24bf5 on mainnet/sepolia).
///         The token contract pushes drop-stage configuration into SeaDrop;
///         end-users call SeaDrop.mintPublic(), which in turn calls
///         mintSeaDrop() on the token contract.
interface ISeaDrop {
    /// @notice Update the public drop stage for the caller (nft contract).
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /// @notice Update the allow list for the caller (nft contract).
    function updateAllowList(AllowListData calldata allowListData) external;

    /// @notice Update a token gated drop stage for the caller.
    function updateTokenGatedDrop(address allowedNftToken, TokenGatedDropStage calldata dropStage) external;

    /// @notice Update the drop URI for the caller.
    function updateDropURI(string calldata dropURI) external;

    /// @notice Update the creator payout address for the caller.
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /// @notice Allow or disallow a fee recipient for the caller.
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed) external;

    /// @notice Update signed-mint validation params for a signer.
    function updateSignedMintValidationParams(
        address signer,
        SignedMintValidationParams calldata signedMintValidationParams
    ) external;

    /// @notice Add or remove an allowed payer for the caller.
    function updatePayer(address payer, bool allowed) external;

    /// @notice Public mint entry point called by users through the OpenSea UI.
    function mintPublic(address nftContract, address feeRecipient, address minterIfNotPayer, uint256 quantity)
        external
        payable;

    /// @notice Returns the configured public drop for an nft contract.
    function getPublicDrop(address nftContract) external view returns (PublicDrop memory);

    /// @notice Returns the configured creator payout address.
    function getCreatorPayoutAddress(address nftContract) external view returns (address);
}
