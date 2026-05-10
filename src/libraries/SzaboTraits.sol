// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title SzaboTraits
/// @notice Deterministic trait decoding from a bytes32 seed.
///         Pure library — no state, no storage, no external calls.
library SzaboTraits {
    // ─── Essay (bits 0-7) ───────────────────────────────────────────────────
    // Named after Nick Szabo's four foundational essays.
    uint8 public constant ESSAY_SHELLING_OUT = 0; // 40% — most common
    uint8 public constant ESSAY_SMART_CONTRACTS = 1; // 30%
    uint8 public constant ESSAY_BIT_GOLD = 2; // 20%
    uint8 public constant ESSAY_SECURE_PROPERTY = 3; // 10% — rarest

    // ─── Inscription density (bits 8-15) ────────────────────────────────────
    uint8 public constant INSCRIPTION_BLANK = 0; // 15% — reverse rare
    uint8 public constant INSCRIPTION_SPARSE = 1; // 45%
    uint8 public constant INSCRIPTION_DENSE = 2; // 30%
    uint8 public constant INSCRIPTION_FULL = 3; // 10% — rare

    // ─── Terminal color (bits 16-23) ────────────────────────────────────────
    uint8 public constant COLOR_GREEN = 0; // 55%
    uint8 public constant COLOR_AMBER = 1; // 25%
    uint8 public constant COLOR_WHITE = 2; // 15%
    uint8 public constant COLOR_RED = 3; // 5% — rarest

    // ─── Frame (bits 24-31) ─────────────────────────────────────────────────
    uint8 public constant FRAME_NONE = 0; // 55%
    uint8 public constant FRAME_SIMPLE = 1; // 30%
    uint8 public constant FRAME_ORNATE = 2; // 15% — rare

    // ─── Symbol (bits 32-39) ────────────────────────────────────────────────
    uint8 public constant SYMBOL_NONE = 0; // 70%
    uint8 public constant SYMBOL_BITCOIN = 1; // 20%
    uint8 public constant SYMBOL_CYPHERPUNK = 2; // 10% — rarest

    struct Traits {
        uint8 essay;
        uint8 inscription;
        uint8 color;
        uint8 frame;
        uint8 symbol;
        // Bits 40-255 used for color palette (r,g,b values for layers)
        uint8 bgR;
        uint8 bgG;
        uint8 bgB;
        uint8 textR;
        uint8 textG;
        uint8 textB;
    }

    /// @notice Decode traits from a bytes32 seed deterministically.
    function decode(bytes32 seed) internal pure returns (Traits memory t) {
        bytes memory b = abi.encodePacked(seed);

        t.essay = _weightedPick(uint8(b[0]), _essayWeights());
        t.inscription = _weightedPick(uint8(b[1]), _inscriptionWeights());
        t.color = _weightedPick(uint8(b[2]), _colorWeights());
        t.frame = _weightedPick(uint8(b[3]), _frameWeights());
        t.symbol = _weightedPick(uint8(b[4]), _symbolWeights());

        // Color palette from remaining bytes
        t.bgR = uint8(b[5]);
        t.bgG = uint8(b[6]);
        t.bgB = uint8(b[7]);
        t.textR = uint8(b[8]);
        t.textG = uint8(b[9]);
        t.textB = uint8(b[10]);
    }

    /// @notice Rarity score 0-100. Higher is rarer.
    ///         Computed as the mean per-trait (100 - probability%) and
    ///         used for metadata display; it is not used to gate mints.
    function rarityScore(Traits memory t) internal pure returns (uint256 score) {
        uint256[4] memory essayRarity = [uint256(60), 70, 80, 90];
        uint256[4] memory inscriptionRarity = [uint256(85), 55, 70, 90];
        uint256[4] memory colorRarity = [uint256(45), 75, 85, 95];
        uint256[3] memory frameRarity = [uint256(45), 70, 85];
        uint256[3] memory symbolRarity = [uint256(30), 80, 90];

        score =
            (essayRarity[t.essay]
                    + inscriptionRarity[t.inscription]
                    + colorRarity[t.color]
                    + frameRarity[t.frame]
                    + symbolRarity[t.symbol]) / 5;
    }

    /// @notice Count how many non-default traits are present.
    ///         Used to distinguish "blank tablet" from "full tablet".
    function traitCount(Traits memory t) internal pure returns (uint256 count) {
        if (t.essay != ESSAY_SHELLING_OUT) count++;
        if (t.inscription != INSCRIPTION_BLANK) count++;
        if (t.color != COLOR_GREEN) count++;
        if (t.frame != FRAME_NONE) count++;
        if (t.symbol != SYMBOL_NONE) count++;
    }

    // ─── Internal helpers ────────────────────────────────────────────────────

    function _weightedPick(uint8 rand, uint8[] memory weights) private pure returns (uint8) {
        uint256 cumulative = 0;
        uint256 total = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            total += weights[i];
        }
        uint256 pick = uint256(rand) * total / 256;
        for (uint8 i = 0; i < weights.length; i++) {
            cumulative += weights[i];
            if (pick < cumulative) return i;
        }
        return uint8(weights.length - 1);
    }

    function _essayWeights() private pure returns (uint8[] memory w) {
        w = new uint8[](4);
        w[0] = 102; // ~40%
        w[1] = 77; // ~30%
        w[2] = 51; // ~20%
        w[3] = 26; // ~10%
    }

    function _inscriptionWeights() private pure returns (uint8[] memory w) {
        w = new uint8[](4);
        w[0] = 38; // ~15%
        w[1] = 115; // ~45%
        w[2] = 77; // ~30%
        w[3] = 26; // ~10%
    }

    function _colorWeights() private pure returns (uint8[] memory w) {
        w = new uint8[](4);
        w[0] = 140; // ~55%
        w[1] = 64; // ~25%
        w[2] = 38; // ~15%
        w[3] = 13; // ~5%
    }

    function _frameWeights() private pure returns (uint8[] memory w) {
        w = new uint8[](3);
        w[0] = 140; // ~55%
        w[1] = 77; // ~30%
        w[2] = 39; // ~15%
    }

    function _symbolWeights() private pure returns (uint8[] memory w) {
        w = new uint8[](3);
        w[0] = 179; // ~70%
        w[1] = 51; // ~20%
        w[2] = 26; // ~10%
    }
}
