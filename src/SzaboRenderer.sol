// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SzaboTraits} from "./libraries/SzaboTraits.sol";

/// @title SzaboRenderer
/// @notice Fully on-chain SVG renderer for SZABO objects.
///         Deployed as a separate contract so its bytecode doesn't count
///         against the token's 24 KB deployed-size cap.
///         No IPFS. No external dependencies. The image IS the contract.
///         Patina is computed from block.number at render time — the tablet
///         visually ages without any transaction.
contract SzaboRenderer {
    using Strings for uint256;
    using Strings for uint8;

    // ─── Patina levels ───────────────────────────────────────────────────────
    uint256 internal constant PATINA_FRESH = 0; // 0–50k blocks     (~7 months)
    uint256 internal constant PATINA_AGED = 1; // 50k–200k          (~2.5 years)
    uint256 internal constant PATINA_ANTIQUE = 2; // 200k–500k       (~6 years)
    uint256 internal constant PATINA_RELIC = 3; // 500k+             (~19+ years)

    /// @notice External entrypoint used by SzaboObjects.tokenURI(tokenId).
    ///         Pure output: `data:application/json;base64,...`.
    function tokenURI(bytes32 seed, uint256 birthBlock, address originalMinter, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        SzaboTraits.Traits memory traits = SzaboTraits.decode(seed);
        uint256 patina = _patinaLevel(birthBlock);
        string memory svg = _buildSVG(traits, patina, birthBlock);
        string memory attrs = _buildAttributes(traits, patina, birthBlock, originalMinter);

        string memory json = string(
            abi.encodePacked(
                '{"name":"SZABO #',
                tokenId.toString(),
                '","description":"A szabo is 10^12 wei. Nick Szabo coined smart contracts in 1994. Every Ethereum transaction carries his name. Almost no one knows it.","image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '","attributes":',
                attrs,
                "}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Current patina level for a token (0-3). Exposed for frontends
    ///         that want to render the level without fetching the full SVG.
    function patinaLevel(uint256 birthBlock) external view returns (uint256) {
        return _patinaLevel(birthBlock);
    }

    // ─── SVG Builder ─────────────────────────────────────────────────────────

    function _buildSVG(SzaboTraits.Traits memory t, uint256 patina, uint256 birthBlock)
        private
        pure
        returns (string memory)
    {
        string memory bgColor = _bgColor(t, patina);
        string memory textColor = _terminalColor(t);

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="400" height="400">',
                "<style>",
                ".bg{fill:",
                bgColor,
                "}",
                ".text{font-family:monospace;fill:",
                textColor,
                ";font-size:11px}",
                ".dim{opacity:0.6}",
                ".header{font-size:9px;fill:",
                textColor,
                ";opacity:0.5}",
                "</style>",
                '<rect class="bg" width="400" height="400"/>',
                _frameLayer(t),
                _inscriptionLayer(t, birthBlock),
                _symbolLayer(t),
                _patinaOverlay(patina),
                '<text x="370" y="390" text-anchor="end" class="header">block #',
                birthBlock.toString(),
                "</text>",
                "</svg>"
            )
        );
    }

    function _bgColor(SzaboTraits.Traits memory t, uint256 patina) private pure returns (string memory) {
        if (t.color == SzaboTraits.COLOR_GREEN) {
            if (patina == PATINA_RELIC) return "#0a1a0a";
            if (patina == PATINA_ANTIQUE) return "#0d200d";
            return "#0f2d0f";
        }
        if (t.color == SzaboTraits.COLOR_AMBER) {
            if (patina == PATINA_RELIC) return "#1a1000";
            return "#1a1200";
        }
        if (t.color == SzaboTraits.COLOR_WHITE) {
            if (patina == PATINA_RELIC) return "#1a1a1a";
            return "#111111";
        }
        // RED
        if (patina == PATINA_RELIC) return "#1a0505";
        return "#1a0808";
    }

    function _terminalColor(SzaboTraits.Traits memory t) private pure returns (string memory) {
        if (t.color == SzaboTraits.COLOR_GREEN) return "#33ff33";
        if (t.color == SzaboTraits.COLOR_AMBER) return "#ffb000";
        if (t.color == SzaboTraits.COLOR_WHITE) return "#e0e0e0";
        return "#ff4444"; // RED
    }

    function _frameLayer(SzaboTraits.Traits memory t) private pure returns (string memory) {
        if (t.frame == SzaboTraits.FRAME_NONE) return "";

        string memory color = _terminalColor(t);

        if (t.frame == SzaboTraits.FRAME_SIMPLE) {
            return string(
                abi.encodePacked(
                    '<rect x="10" y="10" width="380" height="380" ',
                    'fill="none" stroke="',
                    color,
                    '" stroke-width="1" opacity="0.4"/>'
                )
            );
        }

        // FRAME_ORNATE
        return string(
            abi.encodePacked(
                '<rect x="10" y="10" width="380" height="380" fill="none" stroke="',
                color,
                '" stroke-width="1" opacity="0.5"/>',
                '<rect x="16" y="16" width="368" height="368" fill="none" stroke="',
                color,
                '" stroke-width="1" opacity="0.25"/>',
                '<line x1="10" y1="30" x2="30" y2="10" stroke="',
                color,
                '" stroke-width="1" opacity="0.4"/>',
                '<line x1="370" y1="10" x2="390" y2="30" stroke="',
                color,
                '" stroke-width="1" opacity="0.4"/>',
                '<line x1="10" y1="370" x2="30" y2="390" stroke="',
                color,
                '" stroke-width="1" opacity="0.4"/>',
                '<line x1="370" y1="390" x2="390" y2="370" stroke="',
                color,
                '" stroke-width="1" opacity="0.4"/>'
            )
        );
    }

    function _inscriptionLayer(SzaboTraits.Traits memory t, uint256 birthBlock) private pure returns (string memory) {
        if (t.inscription == SzaboTraits.INSCRIPTION_BLANK) {
            return string(
                abi.encodePacked(
                    '<text x="200" y="205" text-anchor="middle" class="text dim" opacity="0.15">',
                    _essayTitle(t.essay),
                    "</text>"
                )
            );
        }

        string memory color = _terminalColor(t);
        string memory essayCode = _essayCode(t.essay);

        string memory header =
            string(abi.encodePacked('<text x="30" y="50" class="header">', "SZABO // ", essayCode, "</text>"));

        string memory title =
            string(abi.encodePacked('<text x="30" y="80" class="text">', _essayTitle(t.essay), "</text>"));

        if (t.inscription == SzaboTraits.INSCRIPTION_SPARSE) {
            return string(abi.encodePacked(header, title));
        }

        string memory body = _denseBody(t, color, birthBlock);

        if (t.inscription == SzaboTraits.INSCRIPTION_DENSE) {
            return string(abi.encodePacked(header, title, body));
        }

        return string(abi.encodePacked(header, title, body, _contractFragment(color)));
    }

    function _denseBody(SzaboTraits.Traits memory t, string memory color, uint256 birthBlock)
        private
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '<text x="30" y="110" class="text dim">',
                _essayQuote(t.essay),
                "</text>",
                '<line x1="30" y1="125" x2="370" y2="125" stroke="',
                color,
                '" stroke-width="1" opacity="0.2"/>',
                '<text x="30" y="145" class="text dim">origin: block #',
                birthBlock.toString(),
                "</text>",
                '<text x="30" y="165" class="text dim">1 szabo = 10^12 wei</text>'
            )
        );
    }

    function _contractFragment(string memory color) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<line x1="30" y1="185" x2="370" y2="185" stroke="',
                color,
                '" stroke-width="1" opacity="0.2"/>',
                '<text x="30" y="210" class="text dim" font-size="9">',
                "// smart contracts (1994)",
                "</text>",
                '<text x="30" y="228" class="text dim" font-size="9">',
                "// bit gold (1998)",
                "</text>",
                '<text x="30" y="246" class="text dim" font-size="9">',
                "// shelling out (2002)",
                "</text>",
                '<text x="30" y="264" class="text dim" font-size="9">',
                "// secure property titles (1998)",
                "</text>"
            )
        );
    }

    function _symbolLayer(SzaboTraits.Traits memory t) private pure returns (string memory) {
        if (t.symbol == SzaboTraits.SYMBOL_NONE) return "";

        string memory color = _terminalColor(t);

        if (t.symbol == SzaboTraits.SYMBOL_BITCOIN) {
            return string(
                abi.encodePacked(
                    '<text x="360" y="50" text-anchor="middle" ',
                    'style="font-size:28px;fill:',
                    color,
                    ';opacity:0.7">',
                    "&#x20BF;",
                    "</text>"
                )
            );
        }

        // CYPHERPUNK — lock (⚿)
        return string(
            abi.encodePacked(
                '<text x="360" y="50" text-anchor="middle" ',
                'style="font-size:22px;fill:',
                color,
                ';opacity:0.7">',
                "&#x26BF;",
                "</text>"
            )
        );
    }

    function _patinaOverlay(uint256 patina) private pure returns (string memory) {
        if (patina == PATINA_FRESH) return "";

        if (patina == PATINA_AGED) {
            return '<rect width="400" height="400" fill="#4a3000" opacity="0.05"/>';
        }

        if (patina == PATINA_ANTIQUE) {
            return string(
                abi.encodePacked(
                    '<rect width="400" height="400" fill="#4a3000" opacity="0.10"/>',
                    '<rect x="0" y="0" width="400" height="8" fill="#000" opacity="0.3"/>',
                    '<rect x="0" y="392" width="400" height="8" fill="#000" opacity="0.3"/>',
                    '<rect x="0" y="0" width="8" height="400" fill="#000" opacity="0.3"/>',
                    '<rect x="392" y="0" width="8" height="400" fill="#000" opacity="0.3"/>'
                )
            );
        }

        // PATINA_RELIC
        return string(
            abi.encodePacked(
                '<rect width="400" height="400" fill="#3a2000" opacity="0.18"/>',
                '<rect x="0" y="0" width="400" height="12" fill="#000" opacity="0.5"/>',
                '<rect x="0" y="388" width="400" height="12" fill="#000" opacity="0.5"/>',
                '<rect x="0" y="0" width="12" height="400" fill="#000" opacity="0.5"/>',
                '<rect x="388" y="0" width="12" height="400" fill="#000" opacity="0.5"/>',
                '<rect x="50" y="50" width="300" height="2" fill="#c8a000" opacity="0.15"/>',
                '<rect x="50" y="348" width="300" height="2" fill="#c8a000" opacity="0.15"/>'
            )
        );
    }

    // ─── Metadata helpers ────────────────────────────────────────────────────

    function _buildAttributes(SzaboTraits.Traits memory t, uint256 patina, uint256 birthBlock, address originalMinter)
        private
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "[",
                _attr("Essay", _essayTitle(t.essay)),
                ",",
                _attr("Inscription", _inscriptionName(t.inscription)),
                ",",
                _attr("Terminal", _colorName(t.color)),
                ",",
                _attr("Frame", _frameName(t.frame)),
                ",",
                _attr("Symbol", _symbolName(t.symbol)),
                ",",
                _attr("Patina", _patinaName(patina)),
                ",",
                _attrNum("Birth Block", birthBlock),
                ",",
                _attrNum("Age (blocks)", block.number - birthBlock),
                ",",
                _attrNum("Rarity Score", SzaboTraits.rarityScore(t)),
                ",",
                _attrAddr("Original Minter", originalMinter),
                "]"
            )
        );
    }

    function _attr(string memory key, string memory value) private pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', key, '","value":"', value, '"}'));
    }

    function _attrNum(string memory key, uint256 value) private pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type":"', key, '","value":', value.toString(), "}"));
    }

    function _attrAddr(string memory key, address value) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('{"trait_type":"', key, '","value":"', Strings.toHexString(uint160(value), 20), '"}')
            );
    }

    // ─── String lookup tables ────────────────────────────────────────────────

    function _essayTitle(uint8 essay) private pure returns (string memory) {
        if (essay == SzaboTraits.ESSAY_SHELLING_OUT) return "Shelling Out";
        if (essay == SzaboTraits.ESSAY_SMART_CONTRACTS) return "Smart Contracts";
        if (essay == SzaboTraits.ESSAY_BIT_GOLD) return "Bit Gold";
        return "Secure Property Titles";
    }

    function _essayCode(uint8 essay) private pure returns (string memory) {
        if (essay == SzaboTraits.ESSAY_SHELLING_OUT) return "S.O.";
        if (essay == SzaboTraits.ESSAY_SMART_CONTRACTS) return "S.C.";
        if (essay == SzaboTraits.ESSAY_BIT_GOLD) return "B.G.";
        return "S.P.T.";
    }

    function _essayQuote(uint8 essay) private pure returns (string memory) {
        if (essay == SzaboTraits.ESSAY_SHELLING_OUT) {
            return "collectibles bridged the gap";
        }
        if (essay == SzaboTraits.ESSAY_SMART_CONTRACTS) {
            return "a set of promises in digital form";
        }
        if (essay == SzaboTraits.ESSAY_BIT_GOLD) {
            return "unforgeable costly bits";
        }
        return "owner authority over property";
    }

    function _inscriptionName(uint8 v) private pure returns (string memory) {
        if (v == SzaboTraits.INSCRIPTION_BLANK) return "Blank";
        if (v == SzaboTraits.INSCRIPTION_SPARSE) return "Sparse";
        if (v == SzaboTraits.INSCRIPTION_DENSE) return "Dense";
        return "Full";
    }

    function _colorName(uint8 v) private pure returns (string memory) {
        if (v == SzaboTraits.COLOR_GREEN) return "Phosphor Green";
        if (v == SzaboTraits.COLOR_AMBER) return "Amber";
        if (v == SzaboTraits.COLOR_WHITE) return "White";
        return "Red Alert";
    }

    function _frameName(uint8 v) private pure returns (string memory) {
        if (v == SzaboTraits.FRAME_NONE) return "None";
        if (v == SzaboTraits.FRAME_SIMPLE) return "Simple";
        return "Ornate";
    }

    function _symbolName(uint8 v) private pure returns (string memory) {
        if (v == SzaboTraits.SYMBOL_NONE) return "None";
        if (v == SzaboTraits.SYMBOL_BITCOIN) return "Bitcoin";
        return "Cypherpunk";
    }

    function _patinaName(uint256 v) private pure returns (string memory) {
        if (v == PATINA_FRESH) return "Fresh";
        if (v == PATINA_AGED) return "Aged";
        if (v == PATINA_ANTIQUE) return "Antique";
        return "Relic";
    }

    function _patinaLevel(uint256 birthBlock) private view returns (uint256) {
        uint256 age = block.number - birthBlock;
        if (age < 50_000) return PATINA_FRESH;
        if (age < 200_000) return PATINA_AGED;
        if (age < 500_000) return PATINA_ANTIQUE;
        return PATINA_RELIC;
    }
}
