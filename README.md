# SZABO — On-chain terminal tablets

2,000 unique ERC-721 tokens. Each SVG is rendered directly from contract
state — no IPFS, no oracle, no off-chain metadata. The image ages with
block height, shifting through four patina states over ~19 years.

Mint directly from [szabo.art/mint](https://szabo.art/mint). 0.001 ETH.
Two per wallet. No middleman — 100% of mint revenue goes to the creator.

Named after Nick Szabo. His "szabo" unit (10^12 wei) sits inside every
Ethereum gas calculation.

---

## Repo layout

```
src/
├── SzaboObjectsV2.sol      ← Main contract (ERC721A, direct mint)
├── SzaboRenderer.sol       ← On-chain SVG renderer (deployed separately)
├── libraries/
│   └── SzaboTraits.sol     ← Deterministic trait decoding
└── seadrop/                ← Legacy vendor (deprecated, kept for reference)

script/
├── DeployV2.s.sol          ← Current deploy script (no SeaDrop)
├── Deploy.s.sol            ← Legacy (SeaDrop-based, deprecated)
└── DeployReuse.s.sol       ← Legacy

web/                        ← Next.js frontend (szabo.art)

test/
└── SzaboObjects.t.sol      ← Unit tests
```

## Collection parameters

| Parameter        | Value              | Enforced by          |
|------------------|--------------------|----------------------|
| Max supply       | 2,000              | Contract (immutable) |
| Mint price       | 0.001 ETH          | Contract (immutable) |
| Per-wallet limit | 2                  | Contract (immutable) |
| Creator royalty  | 2.5% (250 bps)     | Contract (ERC-2981)  |
| Royalty ceiling  | 10% (1000 bps)     | Contract constant    |
| Deployer block   | Cannot mint/receive | Contract             |
| Emergency pause  | ≤ 48h, auto-expire | Contract             |
| Platform fee     | 0%                 | No middleman         |

## Commands

```bash
# Install dependencies
forge install foundry-rs/forge-std --no-git --shallow
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-git --shallow
forge install chiru-labs/ERC721A@v4.3.0 --no-git --shallow

# Build + test
forge build
forge test -vvv

# Deploy (mainnet)
forge script script/DeployV2.s.sol:DeployV2 \
  --rpc-url mainnet --broadcast --verify --slow

# After deploy: owner calls openMint() to start
```

## Frontend

```bash
cd web
npm install
npm run dev     # localhost:3000
npm run build   # production build
```

Deploy to Vercel with Root Directory = `web`.

## Live

- Renderer (mainnet): `0x8B7ee142C7143940Be11B26a283d30E8b56888A3`
- Token V2: pending deploy
- Frontend: szabo.vercel.app
