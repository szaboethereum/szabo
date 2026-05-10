# DEPLOYMENT.md — SZABO deployment ledger

Chronological record of all on-chain actions across networks.

---

## Mainnet (chain id 1) — CURRENT

### Canonical addresses

| Contract      | Address                                        | Status                                                   |
|---------------|------------------------------------------------|----------------------------------------------------------|
| SzaboObjects  | `0x571C58ad432Aaed18d81fCA7f4b55Bb4bd32280a`  | live, verified, OpenSea Studio compatible (v3)           |
| SzaboRenderer | `0x8B7ee142C7143940Be11B26a283d30E8b56888A3`  | live, verified (reused across v1/v2/v3)                  |

Etherscan:
- https://etherscan.io/address/0x571c58ad432aaed18d81fca7f4b55bb4bd32280a
- https://etherscan.io/address/0x8b7ee142c7143940be11b26a283d30e8b56888a3

External contracts (mainnet):
- SeaDrop singleton: `0x00005EA00Ac477B1030CE78506496e8C2dE24bf5`
- OpenSea fee recipient: `0x0000a26b00c1F0DF003000390027140000fAa719`

### Deployer

`0x4D9E6f1Dab6eE15a603FD6036C63F03E67B996B5` (one-time soft wallet; key in `.env`
as `MAINNET_DEPLOYER_KEY`, not committed).

### Deploy + config txs (v3)

Renderer from earlier deploy. Token contract redeployed to add:
- `multiConfigure(MultiConfigureStruct)` — selector `0x911f456b`, matches
  upstream `ERC721SeaDrop`, unlocks OpenSea Studio "Publish changes" UI.
- `setBaseURI` is now a no-op — OpenSea cannot repoint metadata to IPFS
  even via `multiConfigure`. On-chain SVG is permanent.

Run script: `script/DeployReuse.s.sol:DeployReuse`

| Step                              | Tx                                                                   | Gas    |
|-----------------------------------|----------------------------------------------------------------------|--------|
| CREATE SzaboObjects               | (see broadcast/DeployReuse.s.sol/1/run-latest.json)                  | ~2.6M  |
| updateCreatorPayoutAddress         | embedded in broadcast                                                | ~55k   |
| updateAllowedFeeRecipient          | embedded in broadcast                                                | ~100k  |
| updatePayer (deployer)             | embedded in broadcast                                                | ~55k   |
| updatePublicDrop (placeholder)     | embedded in broadcast                                                | ~55k   |
| setContractURI (post-deploy)       | `0xa59e7f346b06cd095e59d9ff5006c1d3c34af8c431ceb1b2acfae705ff9e0347` | 461,462|

### PublicDrop parameters (placeholder — mint is CLOSED)

```
mintPrice:                 1_000_000_000_000_000 wei  (0.001 ETH)
startTime:                 block.timestamp + 365 days (set at deploy)
endTime:                   block.timestamp + 730 days
maxTotalMintableByWallet:  2
feeBps:                    1000                      (10% to OpenSea)
restrictFeeRecipients:     true
```

Minting is closed until owner pushes a new PublicDrop with a current
`startTime` via `cast send` or OpenSea Studio's "Publish changes".

### Deprecated deployments (on mainnet, not used)

| Address                                          | Reason                                         |
|--------------------------------------------------|------------------------------------------------|
| `0x8410b70eB54a95877305d6cD727Adda65de09f50` (v1)| No `multiConfigure` — Studio UI fails Publish. |
| `0x28566ccE1FB9DCd34057A62857D6f5A92dA96b54` (v2)| `multiConfigure` present but selector off (`0xcceb11aa` vs upstream `0x911f456b`) due to struct field order drift. |

Both are owned by the deployer and verified on Etherscan. They can stay on
chain indefinitely; they don't consume anything. No mints were made on
either, so no assets are stranded.

### Remaining launch steps

- [ ] Real `startTime` via OpenSea Studio (or `cast send`) on announcement day
- [ ] OpenSea Studio collection page: logo, banner, description, drop page
- [ ] szabo.art frontend production deploy (Vercel)
- [ ] Announcement (MANIFESTO + drop link)
- [ ] Optional: `transferOwnership` to a hardware wallet for long-term safety

---

## Sepolia (chain id 11155111) — v2 rehearsal (
retained for reference)

### Deployer
`0x046322a6C44c0FAfF548F00d25BFd7afbA168Aae`

### Contracts
| Contract      | Address                                        |
|---------------|------------------------------------------------|
| SzaboObjects  | `0x061077B2cdc9774cD77aC098326422667aE5a650`  |
| SzaboRenderer | `0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB`  |

Blockscout:
- https://eth-sepolia.blockscout.com/token/0x061077B2cdc9774cD77aC098326422667aE5a650
- https://eth-sepolia.blockscout.com/address/0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB

### Test mints (Sepolia)

| # | Recipient                                    | Qty | Token IDs | Tx                                                                   |
|---|----------------------------------------------|-----|-----------|----------------------------------------------------------------------|
| 1 | `0x118ebF25b1970Fd35356E552218dFA01e43e7798` | 1   | #1        | `0xec34c5b552406796ab5682520bb658ee583dc15660a77d79e717d45a75e2a8e8` |
| 2 | `0xf5501e736D12059c19f87713738663Cd76D10ad2` | 2   | #2, #3    | `0x95d192fb4ec0c50f559b24c0448b16938a050f7bf255cfa93cbc7ffa89d254c4` |

Rolled trait distribution:

| Token | Essay                    | Inscription | Terminal       | Frame  | Symbol | Rarity |
|-------|--------------------------|-------------|----------------|--------|--------|--------|
| #1    | Smart Contracts          | Sparse      | Amber          | None   | None   | 55     |
| #2    | Secure Property Titles   | Blank       | Amber          | None   | None   | 65     |
| #3    | Bit Gold                 | Dense       | Phosphor Green | Ornate | None   | 62     |

### Verified revert paths

| Scenario                                    | Result                                             |
|---------------------------------------------|----------------------------------------------------|
| mintPublic payer not in allow-list          | `PayerNotAllowed`                                  |
| mintPublic recipient == deployer            | `DeployerCannotMint` (contract-level)              |
| mintPublic 3rd NFT to same wallet           | `MintQuantityExceedsMaxMintedPerWallet(3, 2)`      |
| updatePayer with already-allowed address    | `DuplicatePayer`                                   |

### Fork tests against live Sepolia deploy

`test/SepoliaFork.t.sol` — 3/3 pass:
- `test_Fork_TokenOneExists`
- `test_Fork_PatinaProgression` (Fresh → Aged → Antique → Relic)
- `test_Fork_TokenURIChangesWithPatina`

Note: Sepolia contract does not have `multiConfigure`. That's fine — Sepolia
only serves as a behavioural rehearsal of the rendering, mint-guard, and
patina logic, all of which are identical between v1/v2/v3 on mainnet.

---

## Notes

- Mainnet has zero mints so far. The placeholder `startTime` keeps the drop
  closed. You can test Publish on OpenSea Studio (as owner) without anyone
  being able to mint.
- All mainnet contracts use the same `SzaboRenderer` at
  `0x8B7ee142C7143940Be11B26a283d30E8b56888A3`. When v1/v2/v3 query
  `renderer()`, they all point here. No renderer redeploys were necessary.
