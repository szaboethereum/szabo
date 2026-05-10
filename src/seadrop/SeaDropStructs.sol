// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Vendored from ProjectOpenSea/seadrop @ main
// src/lib/SeaDropStructs.sol
// Pragma bumped from 0.8.17 → ^0.8.20 for 0.8.26 compilation.
// No behavioural changes. Storage layout identical.

/// @notice Public drop data. Designed to fit in one storage slot.
struct PublicDrop {
    uint80 mintPrice; // 80/256
    uint48 startTime; // 128/256
    uint48 endTime; // 176/256
    uint16 maxTotalMintableByWallet; // 224/256
    uint16 feeBps; // 240/256
    bool restrictFeeRecipients; // 248/256
}

/// @notice Token gated drop stage data. Fits in one storage slot.
struct TokenGatedDropStage {
    uint80 mintPrice;
    uint16 maxTotalMintableByWallet;
    uint48 startTime;
    uint48 endTime;
    uint8 dropStageIndex; // must be non-zero
    uint32 maxTokenSupplyForStage;
    uint16 feeBps;
    bool restrictFeeRecipients;
}

/// @notice Mint params for an allow list leaf.
struct MintParams {
    uint256 mintPrice;
    uint256 maxTotalMintableByWallet;
    uint256 startTime;
    uint256 endTime;
    uint256 dropStageIndex; // must be non-zero
    uint256 maxTokenSupplyForStage;
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/// @notice Token gated mint params.
struct TokenGatedMintParams {
    address allowedNftToken;
    uint256[] allowedNftTokenIds;
}

/// @notice Allow list configuration.
struct AllowListData {
    bytes32 merkleRoot;
    string[] publicKeyURIs;
    string allowListURI;
}

/// @notice Min/max parameters for signed-mint validation.
struct SignedMintValidationParams {
    uint80 minMintPrice;
    uint24 maxMaxTotalMintableByWallet;
    uint40 minStartTime;
    uint40 maxEndTime;
    uint40 maxMaxTokenSupplyForStage;
    uint16 minFeeBps;
    uint16 maxFeeBps;
}
