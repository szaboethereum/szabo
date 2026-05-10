// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Vendored from ProjectOpenSea/seadrop
// src/interfaces/ISeaDropTokenContractMetadata.sol
// Pragma bumped 0.8.17 → ^0.8.20.
// The original extends IERC2981 from openzeppelin; we inline the minimal
// IERC2981 view to avoid dragging the full OZ royalty module into this interface.

/// @notice ERC-2981 royalty standard (inlined to keep this interface self-contained).
interface IERC2981Lite {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/// @title ISeaDropTokenContractMetadata
/// @notice Contract-level metadata + royalty + supply admin hooks that SeaDrop
///         expects every drop-compatible nft to expose.
interface ISeaDropTokenContractMetadata is IERC2981Lite {
    error InvalidRoyaltyBasisPoints(uint256 basisPoints);
    error RoyaltyAddressCannotBeZeroAddress();
    error ProvenanceHashCannotBeSetAfterMintStarted();
    error CannotExceedMaxSupplyOfUint64(uint256 newMaxSupply);

    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event ProvenanceHashUpdated(bytes32 previousHash, bytes32 newHash);
    event RoyaltyInfoUpdated(address receiver, uint256 basisPoints);

    /// @notice Royalty configuration struct.
    struct RoyaltyInfo {
        address royaltyAddress;
        uint96 royaltyBps;
    }

    /// @notice Set the base URI. Used when token metadata is revealed off-chain;
    ///         on-chain SVG tokens may return a constant value instead.
    function setBaseURI(string calldata tokenURI) external;

    /// @notice Set the collection-level contract URI (name, image, etc.).
    function setContractURI(string calldata newContractURI) external;

    /// @notice Set the max mintable supply.
    function setMaxSupply(uint256 newMaxSupply) external;

    /// @notice Set the provenance hash (metadata commitment). Must be set
    ///         before minting begins.
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /// @notice Set the royalty destination + basis points.
    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external;

    /// @notice Emit a metadata-updated event so OpenSea refreshes the token.
    function emitBatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId) external;

    function baseURI() external view returns (string memory);
    function contractURI() external view returns (string memory);
    function maxSupply() external view returns (uint256);
    function provenanceHash() external view returns (bytes32);
    function royaltyAddress() external view returns (address);
    function royaltyBasisPoints() external view returns (uint256);
}
