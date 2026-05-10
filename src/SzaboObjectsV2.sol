// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721A} from "erc721a/ERC721A.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {SzaboRenderer} from "./SzaboRenderer.sol";

/// @title SzaboObjectsV2
/// @notice On-chain terminal tablets. 2,000 edition. No SeaDrop, no middleman.
///         Mint directly from szabo.art. 100% of mint revenue goes to the creator.
///
///         Every token is a SzaboObject with an immutable seed, a birthBlock,
///         and a permanent originalMinter. The SVG is rendered on demand from
///         contract state + block.number. No IPFS. No oracle.
///
///         Hardcoded rules:
///         - max supply: one-way ratchet (can only decrease)
///         - deployer cannot mint or receive
///         - emergency pause auto-expires after 48h
///         - royalty ceiling: 10%
///         - mint price: immutable 0.001 ETH
///         - per-wallet limit: 2
contract SzaboObjectsV2 is ERC721A, Ownable2Step, ReentrancyGuard {
    // ─── Events ──────────────────────────────────────────────────────────────
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event MintingPausedUntil(uint256 expiry);
    event MintingResumed();
    event ObjectSeeded(uint256 indexed tokenId, bytes32 seed, uint256 birthBlock, address indexed minter);
    event Withdrawn(address indexed to, uint256 amount);

    // ─── Errors ──────────────────────────────────────────────────────────────
    error ZeroAddress();
    error DeployerCannotMint();
    error MintingIsPaused();
    error MintNotOpen();
    error ExceedsMaxSupply();
    error ExceedsPerWalletLimit();
    error WrongPayment();
    error WithdrawFailed();
    error InvalidTokenId();
    error RoyaltyTooHigh();
    error CannotIncreaseMaxSupply();

    // ─── Constants ───────────────────────────────────────────────────────────
    uint256 public constant PRICE = 0.001 ether;
    uint256 public constant MAX_PER_WALLET = 2;
    uint256 public constant MAX_PAUSE_DURATION = 48 hours;
    uint96 public constant MAX_ROYALTY_BPS = 1000; // 10%

    // ─── Immutables ──────────────────────────────────────────────────────────
    address public immutable deployer;

    // ─── State ───────────────────────────────────────────────────────────────
    SzaboRenderer public renderer;
    uint256 internal _maxSupply;
    bool public mintOpen;
    bool public mintingPaused;
    uint256 public pauseExpiry;

    address internal _royaltyReceiver;
    uint96 internal _royaltyBps;
    string internal _contractURI;

    struct SzaboObject {
        bytes32 seed;
        uint256 birthBlock;
        address originalMinter;
    }

    mapping(uint256 => SzaboObject) public objects;

    // ─── Constructor ─────────────────────────────────────────────────────────
    constructor(
        address _deployer,
        address renderer_,
        uint256 maxSupply_,
        address royaltyReceiver_,
        uint96 royaltyBps_
    ) ERC721A("Szabo Objects", "SZABO") Ownable(_deployer) {
        if (_deployer == address(0)) revert ZeroAddress();
        if (renderer_ == address(0)) revert ZeroAddress();
        if (royaltyReceiver_ == address(0)) revert ZeroAddress();
        if (royaltyBps_ > MAX_ROYALTY_BPS) revert RoyaltyTooHigh();

        deployer = _deployer;
        renderer = SzaboRenderer(renderer_);
        _maxSupply = maxSupply_;
        _royaltyReceiver = royaltyReceiver_;
        _royaltyBps = royaltyBps_;
    }

    // ─── Mint ────────────────────────────────────────────────────────────────

    /// @notice Public mint. 0.001 ETH per token, max 2 per wallet.
    ///         100% of payment stays in this contract. Owner withdraws.
    function mint(uint256 quantity) external payable nonReentrant {
        if (!mintOpen) revert MintNotOpen();
        if (msg.sender == deployer) revert DeployerCannotMint();
        if (msg.value != PRICE * quantity) revert WrongPayment();
        if (quantity == 0 || quantity > MAX_PER_WALLET) revert ExceedsPerWalletLimit();
        if (_numberMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsPerWalletLimit();
        if (_totalMinted() + quantity > _maxSupply) revert ExceedsMaxSupply();

        _checkPause();
        _safeMint(msg.sender, quantity);
    }

    /// @notice Owner opens mint. One-way: once open, cannot be closed
    ///         (only paused temporarily via emergencyPauseMinting).
    function openMint() external onlyOwner {
        mintOpen = true;
    }

    // ─── ERC721A Hooks ───────────────────────────────────────────────────────

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // Deployer can never receive tokens — not via mint, not via transfer.
        if (to == deployer) revert DeployerCannotMint();

        if (from != address(0)) return; // only seed on mint path

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            bytes32 seed = keccak256(
                abi.encodePacked(block.prevrandao, block.timestamp, block.number, tokenId, to, address(this))
            );
            objects[tokenId] = SzaboObject({seed: seed, birthBlock: block.number, originalMinter: to});
            emit ObjectSeeded(tokenId, seed, block.number, to);
        }
    }

    // ─── Token URI (on-chain) ────────────────────────────────────────────────

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        SzaboObject memory obj = objects[tokenId];
        return renderer.tokenURI(obj.seed, obj.birthBlock, obj.originalMinter, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    // ─── Withdraw ────────────────────────────────────────────────────────────

    /// @notice Owner withdraws all ETH from mint sales.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert WithdrawFailed();
        (bool ok,) = msg.sender.call{value: balance}("");
        if (!ok) revert WithdrawFailed();
        emit Withdrawn(msg.sender, balance);
    }

    // ─── Admin ───────────────────────────────────────────────────────────────

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (newMaxSupply > _maxSupply) revert CannotIncreaseMaxSupply();
        if (newMaxSupply < _totalMinted()) revert ExceedsMaxSupply();
        _maxSupply = newMaxSupply;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function setRoyaltyInfo(address receiver, uint96 bps) external onlyOwner {
        if (receiver == address(0)) revert ZeroAddress();
        if (bps > MAX_ROYALTY_BPS) revert RoyaltyTooHigh();
        _royaltyReceiver = receiver;
        _royaltyBps = bps;
    }

    // ─── Emergency Pause ─────────────────────────────────────────────────────

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

    // ─── Views ───────────────────────────────────────────────────────────────

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    // ─── ERC-2981 ────────────────────────────────────────────────────────────

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_royaltyReceiver, (salePrice * _royaltyBps) / 10_000);
    }

    // ─── ERC-165 ─────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId
            || interfaceId == bytes4(0x49064906) // ERC-4906
            || super.supportsInterface(interfaceId);
    }
}
