// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721A} from "erc721a/ERC721A.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {SzaboRenderer} from "./SzaboRenderer.sol";
import {INonFungibleSeaDropToken} from "./seadrop/INonFungibleSeaDropToken.sol";
import {ISeaDropTokenContractMetadata} from "./seadrop/ISeaDropTokenContractMetadata.sol";
import {ISeaDrop} from "./seadrop/ISeaDrop.sol";
import {MultiConfigureStruct} from "./seadrop/INonFungibleSeaDropToken.sol";
import {AllowListData, PublicDrop, TokenGatedDropStage, SignedMintValidationParams} from "./seadrop/SeaDropStructs.sol";

/// @title SzaboObjects
/// @notice On-chain pixel-art cuneiform tablets. Every token is a SzaboObject
///         with an immutable seed, a birthBlock, and a permanent originalMinter
///         address. The SVG is rendered on demand by SzaboRenderer using only
///         contract state and block.number — no IPFS, no oracle, no off-chain
///         metadata.
///
///         Distribution: OpenSea Drops via SeaDrop singleton. Secondary market
///         is Seaport with 2.5% creator royalty (ERC-2981).
///
///         Hardcoded rules (cannot be changed after deploy):
///         - max supply never increases above deploy-time cap (one-way ratchet)
///         - deployer cannot mint or receive objects
///         - emergency pause auto-expires after 48h
///         - royalty ceiling: 10% (MAX_ROYALTY_BPS)
contract SzaboObjects is ERC721A, INonFungibleSeaDropToken, Ownable2Step, ReentrancyGuard {
    /// @dev Inlined ERC-4906 events so OpenSea refreshes metadata on
    ///      emitBatchMetadataUpdate(). We do not inherit OZ's IERC4906
    ///      because it re-declares IERC721, which conflicts with ERC721A.
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // ─── Errors ──────────────────────────────────────────────────────────────
    error ZeroAddress();
    error DeployerCannotMint();
    error MintingIsPaused();
    error ExceedsMaxSupply();
    error CannotIncreaseMaxSupply();
    error RoyaltyTooHigh();
    error InvalidTokenId();

    // ─── Events ──────────────────────────────────────────────────────────────
    event MintingPausedUntil(uint256 expiry);
    event MintingResumed();
    event ObjectSeeded(uint256 indexed tokenId, bytes32 seed, uint256 birthBlock, address indexed minter);
    event RendererSet(address indexed renderer);

    // ─── Constants ───────────────────────────────────────────────────────────

    /// @notice Maximum duration the owner can freeze mints for. After this
    ///         window, mints resume automatically without a transaction.
    uint256 public constant MAX_PAUSE_DURATION = 48 hours;

    /// @notice Hard ceiling for creator royalty. Keeps owner from setting
    ///         predatory royalties after mint. Typical value at deploy: 250 (2.5%).
    uint96 public constant MAX_ROYALTY_BPS = 1000;

    // ─── Immutable state ─────────────────────────────────────────────────────

    /// @notice The deploying address. Permanently banned from receiving tokens
    ///         or being the mint target — enforced in _beforeTokenTransfers.
    address public immutable deployer;

    // ─── SeaDrop integration ─────────────────────────────────────────────────

    mapping(address => bool) internal _allowedSeaDrop;
    address[] internal _enumeratedAllowedSeaDrop;

    // ─── Per-token object state ──────────────────────────────────────────────

    struct SzaboObject {
        bytes32 seed; // trait source, immutable per token
        uint256 birthBlock; // render-time input, drives patina
        address originalMinter; // permanent provenance
    }

    /// @notice tokenId → object. tokenIds start at 1.
    mapping(uint256 => SzaboObject) public objects;

    // ─── Supply / drop config ────────────────────────────────────────────────

    /// @notice External renderer contract. Deploying the renderer separately
    ///         keeps this token under the 24 KB contract-size limit.
    SzaboRenderer public renderer;

    /// @notice Maximum tokens that can ever be minted. One-way ratchet: owner
    ///         may only decrease.
    uint256 internal _maxSupply;

    /// @notice Collection-level JSON blob URI (or inline data URI).
    string internal _contractURI;

    address internal _royaltyReceiver;
    uint96 internal _royaltyBps;

    /// @notice Metadata commitment for pre-reveal collections. Unused for
    ///         fully on-chain art — kept for SeaDrop compatibility.
    bytes32 internal _provenanceHash;

    // ─── Pause state ─────────────────────────────────────────────────────────

    bool public mintingPaused;
    uint256 public pauseExpiry;

    // ─── Modifiers ───────────────────────────────────────────────────────────

    modifier onlyAllowedSeaDrop(address seaDrop) {
        _checkAllowedSeaDrop(seaDrop);
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    constructor(
        string memory name_,
        string memory symbol_,
        address _deployer,
        address renderer_,
        address[] memory allowedSeaDrop_,
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint96 royaltyBps_
    ) ERC721A(name_, symbol_) Ownable(_deployer) {
        if (_deployer == address(0)) revert ZeroAddress();
        if (renderer_ == address(0)) revert ZeroAddress();
        if (royaltyReceiver_ == address(0)) revert ZeroAddress();
        if (royaltyBps_ > MAX_ROYALTY_BPS) revert RoyaltyTooHigh();

        deployer = _deployer;
        renderer = SzaboRenderer(renderer_);
        _maxSupply = maxSupply_;
        _royaltyReceiver = royaltyReceiver_;
        _royaltyBps = royaltyBps_;

        uint256 n = allowedSeaDrop_.length;
        for (uint256 i = 0; i < n; i++) {
            _allowedSeaDrop[allowedSeaDrop_[i]] = true;
        }
        _enumeratedAllowedSeaDrop = allowedSeaDrop_;

        emit AllowedSeaDropUpdated(allowedSeaDrop_);
        emit RendererSet(renderer_);
    }

    // ─── ERC721A overrides ───────────────────────────────────────────────────

    /// @dev SeaDrop's ERC721SeaDrop starts tokenIds at 1 (avoids the 0 = unset
    ///      ambiguity common in ERC-721 tooling). Mirror that choice.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Core hook: on every mint path, verify deployer is not the recipient,
    ///      honour the pause, then write one SzaboObject per tokenId. This runs
    ///      before _safeMint's onERC721Received callback, so an adversarial
    ///      receiver cannot see the tokenURI before the seed is committed.
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (from != address(0)) return;

        if (to == deployer) revert DeployerCannotMint();
        _checkPause();

        uint256 lastTokenId = startTokenId + quantity - 1;
        if (lastTokenId > _maxSupply) revert ExceedsMaxSupply();

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            bytes32 seed = keccak256(
                abi.encodePacked(block.prevrandao, block.timestamp, block.number, tokenId, to, address(this))
            );
            objects[tokenId] = SzaboObject({seed: seed, birthBlock: block.number, originalMinter: to});
            emit ObjectSeeded(tokenId, seed, block.number, to);
        }
    }

    /// @dev On-chain tokenURI: always delegates to SzaboRenderer. baseURI is
    ///      permanently empty (setBaseURI is a no-op), so there is no
    ///      "escape hatch" to IPFS or any off-chain pointer. See setBaseURI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        SzaboObject memory obj = objects[tokenId];
        return renderer.tokenURI(obj.seed, obj.birthBlock, obj.originalMinter, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    // ─── SeaDrop mint entrypoint ─────────────────────────────────────────────

    /// @notice Invoked by the canonical SeaDrop contract when a user mints via
    ///         OpenSea Drops. Caller is validated against the allow list; all
    ///         supply / per-wallet limit / payment logic lives inside SeaDrop
    ///         itself and is configured through updatePublicDrop().
    function mintSeaDrop(address minter, uint256 quantity) external override nonReentrant {
        _checkAllowedSeaDrop(msg.sender);
        if (_totalMinted() + quantity > _maxSupply) revert ExceedsMaxSupply();
        _safeMint(minter, quantity);
    }

    /// @notice Mint statistics read by SeaDrop to enforce per-wallet and
    ///         per-supply caps configured on the PublicDrop.
    function getMintStats(address minter)
        external
        view
        override
        returns (uint256 minterNumMinted, uint256 currentTotalSupply, uint256 maxSupply_)
    {
        minterNumMinted = _numberMinted(minter);
        currentTotalSupply = _totalMinted();
        maxSupply_ = _maxSupply;
    }

    // ─── SeaDrop allow list administration ───────────────────────────────────

    function updateAllowedSeaDrop(address[] calldata newAllowedSeaDrop) external override onlyOwner {
        uint256 prevLen = _enumeratedAllowedSeaDrop.length;
        for (uint256 i = 0; i < prevLen; i++) {
            _allowedSeaDrop[_enumeratedAllowedSeaDrop[i]] = false;
        }
        uint256 newLen = newAllowedSeaDrop.length;
        for (uint256 i = 0; i < newLen; i++) {
            _allowedSeaDrop[newAllowedSeaDrop[i]] = true;
        }
        _enumeratedAllowedSeaDrop = newAllowedSeaDrop;
        emit AllowedSeaDropUpdated(newAllowedSeaDrop);
    }

    function allowedSeaDrop() external view returns (address[] memory) {
        return _enumeratedAllowedSeaDrop;
    }

    // ─── SeaDrop push-config forwarders (owner-gated) ────────────────────────

    function updatePublicDrop(address seaDropImpl, PublicDrop calldata publicDrop)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updatePublicDrop(publicDrop);
    }

    function updateAllowList(address seaDropImpl, AllowListData calldata allowListData)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updateAllowList(allowListData);
    }

    function updateTokenGatedDrop(address seaDropImpl, address allowedNftToken, TokenGatedDropStage calldata dropStage)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updateTokenGatedDrop(allowedNftToken, dropStage);
    }

    function updateDropURI(address seaDropImpl, string calldata dropURI)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updateDropURI(dropURI);
    }

    function updateCreatorPayoutAddress(address seaDropImpl, address payoutAddress)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        if (payoutAddress == address(0)) revert ZeroAddress();
        ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(payoutAddress);
    }

    function updateAllowedFeeRecipient(address seaDropImpl, address feeRecipient, bool allowed)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(feeRecipient, allowed);
    }

    function updateSignedMintValidationParams(
        address seaDropImpl,
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external override onlyOwner onlyAllowedSeaDrop(seaDropImpl) {
        ISeaDrop(seaDropImpl).updateSignedMintValidationParams(signer, signedMintValidationParams);
    }

    function updatePayer(address seaDropImpl, address payer, bool allowed)
        external
        override
        onlyOwner
        onlyAllowedSeaDrop(seaDropImpl)
    {
        ISeaDrop(seaDropImpl).updatePayer(payer, allowed);
    }

    // ─── Contract metadata (ISeaDropTokenContractMetadata) ──────────────────

    /// @notice Intentional no-op. SZABO tokens render exclusively from
    ///         contract state via SzaboRenderer; the base URI is permanently
    ///         empty. We accept this call silently (rather than revert) so
    ///         OpenSea Studio's `multiConfigure` can execute successfully —
    ///         its payload inevitably includes a prefilled `baseURI` pointing
    ///         at IPFS. That pointer is dropped here and `tokenURI()` keeps
    ///         serving the on-chain SVG. The "object itself, not a receipt"
    ///         invariant holds.
    function setBaseURI(string calldata) external override onlyOwner {
        // solhint-disable-next-line no-empty-blocks
        // no state change. _tokenBaseURI is permanently empty.
    }

    function setContractURI(string calldata newContractURI) external override onlyOwner {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    /// @notice One-way ratchet. The owner can only *decrease* the cap.
    function setMaxSupply(uint256 newMaxSupply) external override onlyOwner {
        if (newMaxSupply > _maxSupply) revert CannotIncreaseMaxSupply();
        if (newMaxSupply < _totalMinted()) revert ExceedsMaxSupply();
        if (newMaxSupply > type(uint64).max) revert CannotExceedMaxSupplyOfUint64(newMaxSupply);
        _maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    function setProvenanceHash(bytes32 newProvenanceHash) external override onlyOwner {
        if (_totalMinted() > 0) revert ProvenanceHashCannotBeSetAfterMintStarted();
        bytes32 previous = _provenanceHash;
        _provenanceHash = newProvenanceHash;
        emit ProvenanceHashUpdated(previous, newProvenanceHash);
    }

    function setRoyaltyInfo(RoyaltyInfo calldata newInfo) external override onlyOwner {
        if (newInfo.royaltyAddress == address(0)) revert RoyaltyAddressCannotBeZeroAddress();
        if (newInfo.royaltyBps > MAX_ROYALTY_BPS) revert InvalidRoyaltyBasisPoints(newInfo.royaltyBps);
        _royaltyReceiver = newInfo.royaltyAddress;
        _royaltyBps = newInfo.royaltyBps;
        emit RoyaltyInfoUpdated(newInfo.royaltyAddress, newInfo.royaltyBps);
    }

    function emitBatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId) external override onlyOwner {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    // ─── Views ──────────────────────────────────────────────────────────────

    function baseURI() external pure override returns (string memory) {
        return "";
    }

    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    function maxSupply() public view override returns (uint256) {
        return _maxSupply;
    }

    function provenanceHash() external view override returns (bytes32) {
        return _provenanceHash;
    }

    function royaltyAddress() external view override returns (address) {
        return _royaltyReceiver;
    }

    function royaltyBasisPoints() external view override returns (uint256) {
        return _royaltyBps;
    }

    // ─── ERC-2981 ────────────────────────────────────────────────────────────

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyBps) / 10_000;
    }

    // ─── Emergency pause ────────────────────────────────────────────────────

    /// @notice Freeze new mints. Expires automatically after MAX_PAUSE_DURATION.
    ///         Kill-switch for a live vulnerability; cannot be extended
    ///         indefinitely. Existing tokens are unaffected.
    function emergencyPauseMinting() external onlyOwner {
        mintingPaused = true;
        pauseExpiry = block.timestamp + MAX_PAUSE_DURATION;
        emit MintingPausedUntil(pauseExpiry);
    }

    function resumeMinting() external onlyOwner {
        mintingPaused = false;
        pauseExpiry = 0;
        emit MintingResumed();
    }

    // ─── Internal helpers ────────────────────────────────────────────────────

    function _checkAllowedSeaDrop(address seaDrop) internal view {
        if (!_allowedSeaDrop[seaDrop]) revert OnlyAllowedSeaDrop();
    }

    function _checkPause() internal {
        if (!mintingPaused) return;
        if (block.timestamp >= pauseExpiry) {
            mintingPaused = false;
            pauseExpiry = 0;
            emit MintingResumed();
            return;
        }
        revert MintingIsPaused();
    }

    // ─── multiConfigure ──────────────────────────────────────────────────────

    /// @notice Push every SeaDrop-related setting in one tx.
    ///         Mirrors OpenSea's `ERC721SeaDrop.multiConfigure` so the Studio
    ///         UI's "Publish changes" button succeeds against this contract.
    ///
    ///         Deliberate deviations from the reference implementation:
    ///         - `config.baseURI` and `config.provenanceHash` are ignored.
    ///           SZABO tokens must render from contract state; we do not let
    ///           OpenSea repoint metadata to IPFS under any circumstance.
    ///         - `config.maxSupply` is silently capped at the deploy-time
    ///           value (setMaxSupply is a one-way ratchet; see the function).
    ///         Everything else forwards to SeaDrop exactly as upstream.
    function multiConfigure(MultiConfigureStruct calldata config) external onlyOwner {
        address seaDropImpl = config.seaDropImpl;
        _checkAllowedSeaDrop(seaDropImpl);

        // maxSupply: only accepted if it is a strict *decrease*. Ignore otherwise.
        if (config.maxSupply > 0 && config.maxSupply < _maxSupply) {
            if (config.maxSupply >= _totalMinted()) {
                _maxSupply = config.maxSupply;
                emit MaxSupplyUpdated(config.maxSupply);
            }
        }

        // baseURI: intentionally ignored. See setBaseURI().

        // contractURI: accepted. Does not affect per-token metadata.
        if (bytes(config.contractURI).length != 0) {
            _contractURI = config.contractURI;
            emit ContractURIUpdated(config.contractURI);
        }

        // publicDrop: forwarded when either timestamp is set.
        if (config.publicDrop.startTime != 0 || config.publicDrop.endTime != 0) {
            ISeaDrop(seaDropImpl).updatePublicDrop(config.publicDrop);
        }

        // dropURI: forwarded.
        if (bytes(config.dropURI).length != 0) {
            ISeaDrop(seaDropImpl).updateDropURI(config.dropURI);
        }

        // allow list.
        if (config.allowListData.merkleRoot != bytes32(0)) {
            ISeaDrop(seaDropImpl).updateAllowList(config.allowListData);
        }

        // creator payout — forwarded as given. Owner is responsible for
        // validating the address off-chain (OpenSea Studio already warns
        // about changing it).
        if (config.creatorPayoutAddress != address(0)) {
            ISeaDrop(seaDropImpl).updateCreatorPayoutAddress(config.creatorPayoutAddress);
        }

        // provenanceHash: intentionally ignored. Fully on-chain art has no
        // off-chain reveal to commit to.

        // fee recipient allowlist toggles.
        uint256 n = config.allowedFeeRecipients.length;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(config.allowedFeeRecipients[i], true);
        }
        n = config.disallowedFeeRecipients.length;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateAllowedFeeRecipient(config.disallowedFeeRecipients[i], false);
        }

        // payer allowlist toggles.
        n = config.allowedPayers.length;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updatePayer(config.allowedPayers[i], true);
        }
        n = config.disallowedPayers.length;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updatePayer(config.disallowedPayers[i], false);
        }

        // token-gated drop stages.
        n = config.tokenGatedDropStages.length;
        require(n == config.tokenGatedAllowedNftTokens.length, "Szabo: token gated mismatch");
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateTokenGatedDrop(
                config.tokenGatedAllowedNftTokens[i], config.tokenGatedDropStages[i]
            );
        }
        n = config.disallowedTokenGatedAllowedNftTokens.length;
        TokenGatedDropStage memory emptyStage;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateTokenGatedDrop(
                config.disallowedTokenGatedAllowedNftTokens[i], emptyStage
            );
        }

        // signed mint validation params.
        n = config.signedMintValidationParams.length;
        require(n == config.signers.length, "Szabo: signers mismatch");
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateSignedMintValidationParams(
                config.signers[i], config.signedMintValidationParams[i]
            );
        }
        n = config.disallowedSigners.length;
        SignedMintValidationParams memory emptyParams;
        for (uint256 i = 0; i < n; i++) {
            ISeaDrop(seaDropImpl).updateSignedMintValidationParams(config.disallowedSigners[i], emptyParams);
        }
    }

    // ─── ERC165 ──────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return interfaceId == type(INonFungibleSeaDropToken).interfaceId
            || interfaceId == type(ISeaDropTokenContractMetadata).interfaceId
            || interfaceId == type(IERC2981).interfaceId || interfaceId == bytes4(0x49064906)
            || super.supportsInterface(interfaceId);
    }
}
