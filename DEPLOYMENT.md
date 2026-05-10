# DEPLOYMENT.md — SZABO deployment ledger

## Current (V2 — no SeaDrop, no middleman)

**Status: pending deploy.** Awaiting deployer wallet funding.

| Contract       | Address                                        | Status    |
|----------------|------------------------------------------------|-----------|
| SzaboRenderer  | `0x8B7ee142C7143940Be11B26a283d30E8b56888A3`  | live, verified (reused) |
| SzaboObjectsV2 | TBD                                            | pending   |

Deploy script: `script/DeployV2.s.sol`
Deployer: `0x4D9E6f1Dab6eE15a603FD6036C63F03E67B996B5`

After deploy:
1. Owner calls `openMint()` to start public mint
2. Update `web/src/app/mint/page.tsx` TOKEN constant
3. Push to GitHub → Vercel auto-deploys
4. Announce

---

## Deprecated (SeaDrop-based, kept for reference)

| Contract       | Address                                        | Notes |
|----------------|------------------------------------------------|-------|
| SzaboObjects v1 | `0x8410b70eB54a95877305d6cD727Adda65de09f50` | no multiConfigure |
| SzaboObjects v2 | `0x28566ccE1FB9DCd34057A62857D6f5A92dA96b54` | wrong selector |
| SzaboObjects v3 | `0x571C58ad432Aaed18d81fCA7f4b55Bb4bd32280a` | correct selector, but SeaDrop UI incompatible with on-chain art |

All deprecated contracts are owned by the deployer, verified on Etherscan,
and have zero or one test mint. No user funds at risk.

---

## Sepolia (rehearsal)

| Contract       | Address                                        |
|----------------|------------------------------------------------|
| SzaboRenderer  | `0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB`  |
| SzaboObjects   | `0x061077B2cdc9774cD77aC098326422667aE5a650`  |

3 test mints, all verified on Blockscout.

---

## Lesson learned

OpenSea Drops requires pre-uploaded metadata (images + CSV). On-chain art
that renders via `tokenURI()` is incompatible with their Drops pipeline.
The "Mint Ended" UI state cannot be resolved without uploading placeholder
media. Solution: bypass SeaDrop entirely, mint directly from own contract
and frontend. No middleman fees, simpler contract, full control.
