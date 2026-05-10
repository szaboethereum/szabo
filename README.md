# SZABO — On-chain cuneiform tablets via OpenSea Drops

SZABO is an on-chain ERC-721 collection. 2,000 unique pixel-terminal tablets.
Each token's SVG is rendered directly from contract state — no IPFS, no
oracle, no off-chain metadata. The image ages with block height, shifting
through four patina states over ~19 years.

Distribution is handled by the canonical SeaDrop contract (OpenSea Drops).
Secondary market is Seaport with 2.5% creator royalty (ERC-2981).

Named after Nick Szabo. His "szabo" unit (10^12 wei) sits inside every
Ethereum gas calculation.

---

## Repo layout

```
src/
├── SzaboObjects.sol        ← ERC721A + SeaDrop-compatible token
├── SzaboRenderer.sol       ← On-chain SVG renderer (deployed separately)
├── libraries/
│   └── SzaboTraits.sol     ← Deterministic trait decoding
└── seadrop/                ← Vendored SeaDrop interfaces (pragma ^0.8.20)
    ├── ISeaDrop.sol
    ├── INonFungibleSeaDropToken.sol
    ├── ISeaDropTokenContractMetadata.sol
    └── SeaDropStructs.sol

script/
└── Deploy.s.sol

test/
├── SzaboObjects.t.sol
├── SepoliaFork.t.sol
└── mocks/
    └── MockSeaDrop.sol
```

## Collection parameters

| Parameter           | Value                     | Enforced by               |
|---------------------|---------------------------|---------------------------|
| Max supply          | 2,000                     | Contract (one-way ratchet)|
| Mint price          | 0.001 ETH                 | SeaDrop PublicDrop        |
| Per-wallet limit    | 2                         | SeaDrop PublicDrop        |
| Creator royalty     | 2.5% (250 bps)            | Contract (ERC-2981)       |
| Royalty ceiling     | 10% (1000 bps)            | Contract constant         |
| Deployer mint block | Yes                       | Contract                  |
| Emergency pause     | ≤ 48h, auto-expires       | Contract                  |

## Setup

```bash
# install dependencies (lib/ is gitignored, install locally)
forge install foundry-rs/forge-std --no-git --shallow
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-git --shallow
forge install chiru-labs/ERC721A@v4.3.0 --no-git --shallow

# build + test
forge build
forge test -vvv

# format
forge fmt
```

## Deploy

Requires `.env` with `DEPLOYER_KEY`, `SEPOLIA_RPC_URL`, `MAINNET_RPC_URL`,
`ETHERSCAN_API_KEY`. See `.env.example`.

```bash
# Sepolia
forge script script/Deploy.s.sol:Deploy --rpc-url sepolia \
  --private-key $DEPLOYER_KEY --broadcast

# Verify on Blockscout (Sepolia)
forge verify-contract <addr> src/SzaboObjects.sol:SzaboObjects \
  --verifier blockscout \
  --verifier-url "https://eth-sepolia.blockscout.com/api/"
```

After deploy, configure drop metadata + real start/end times via the
OpenSea Studio UI or push directly with `updatePublicDrop`.

## Live deployment

See `DEPLOYMENT.md` for current Sepolia addresses and transaction ledger.
