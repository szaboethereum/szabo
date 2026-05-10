# MAINNET_CHECKLIST.md — before pulling the trigger

Mainnet deployment is irreversible. Walk through this list before running
`forge script ... --rpc-url mainnet --broadcast`.

---

## 1. Code

- [ ] `forge test -vvv` — all 30+ unit tests pass
- [ ] `forge test --fork-url $SEPOLIA_RPC_URL --match-contract SepoliaForkTest` — 3/3 pass
- [ ] `forge fmt --check` — clean
- [ ] `forge build --sizes` — `SzaboObjects` < 24,576 bytes (margin > 10,000)
- [ ] No uncommitted changes (`git status` clean)
- [ ] `main` branch is the one being deployed (no feature branches)

## 2. Configuration

- [ ] `.env` contains `MAINNET_DEPLOYER_KEY`
- [ ] `MAINNET_RPC_URL` set to a reliable endpoint (Alchemy, Infura, or
      publicnode). Avoid single-source RPCs — provider downtime breaks broadcast.
- [ ] `ETHERSCAN_API_KEY` set (for `--verify` flag)
- [ ] `Deploy.s.sol` constants reviewed:
  - [ ] `NAME = "Szabo Objects"`
  - [ ] `SYMBOL = "SZABO"`
  - [ ] `MAX_SUPPLY = 2000`
  - [ ] `ROYALTY_BPS = 250` (2.5%)
  - [ ] `MINT_PRICE = 0.001 ether`
  - [ ] `MAX_PER_WALLET = 2`
  - [ ] `SEADROP_FEE_BPS = 1000` (10%, OpenSea's mandated value)
  - [ ] `OPENSEA_FEE_RECIPIENT` — confirm this is the mainnet address (may
        differ from Sepolia; check OpenSea docs before deploy)

## 3. Deployer wallet

- [ ] Using `MAINNET_DEPLOYER_KEY`, *not* `DEPLOYER_KEY`
- [ ] Wallet has ≥ 0.2 ETH funded (~0.1 ETH for deploy + buffer for mint config
      and post-deploy admin tx)
- [ ] Wallet's only purpose is this deploy. Do not reuse for anything else.
- [ ] Private key is backed up in a password manager (not just in `.env`)
- [ ] Cold wallet alternative: if using Ledger, replace `--private-key` with
      `--ledger --hd-paths "m/44'/60'/0'/0/0"` in the deploy command.

## 4. Post-deploy plan

Every step after `Deploy.s.sol` runs is an owner-only transaction from the
deployer wallet. Plan them before you need them.

- [ ] Transfer ownership to cold wallet? If yes:
      `cast send $TOKEN "transferOwnership(address)" $COLD_WALLET ...`
      (Ownable2Step — receiver must accept with `acceptOwnership()`.)
- [ ] Set `contractURI` (base64 data URI or IPFS pointer with collection
      name / description / image)
- [ ] Set real `startTime` via `updatePublicDrop` when launch day arrives
      (placeholder in deploy script is +365 days)
- [ ] Authorize deployer as allowed payer *if* planning to mint for others:
      `cast send $TOKEN "updatePayer(address,address,bool)" $SEADROP $PAYER true`

## 5. OpenSea side

- [ ] OpenSea collection created via Studio UI (or discovered automatically
      once the first mint happens)
- [ ] Collection logo uploaded
- [ ] Collection description / external link set
- [ ] Drop page published (Studio UI) — this exposes the mint button
- [ ] Drop schedule announced publicly before startTime

## 6. Frontend

- [ ] `szabo.art` domain configured
- [ ] DNS pointing to Vercel / hosting
- [ ] `NEXT_PUBLIC_SZABO_ADDRESS` set to the mainnet contract
- [ ] `NEXT_PUBLIC_CHAIN=mainnet`
- [ ] `NEXT_PUBLIC_RPC_URL` set (mainnet endpoint)
- [ ] `NEXT_PUBLIC_OPENSEA_SLUG` set to the collection slug

## 7. Social / announce

- [ ] MANIFESTO.md published at `szabo.art/manifesto`
- [ ] Twitter/X account set up (or other channels)
- [ ] Post-launch monitoring plan (first 24h):
  - [ ] Watch mint count
  - [ ] Watch for OpenSea fee recipient changes (shouldn't happen)
  - [ ] Watch wallet balance growth
  - [ ] Have emergency pause runbook ready

## 8. Emergency runbook

If something goes wrong *after* deploy but *before* going public:

```bash
# Pause minting (48h auto-expire)
cast send $TOKEN "emergencyPauseMinting()" --rpc-url mainnet --private-key $MAINNET_DEPLOYER_KEY

# Resume (if issue fixed)
cast send $TOKEN "resumeMinting()" --rpc-url mainnet --private-key $MAINNET_DEPLOYER_KEY
```

If something goes wrong *after* going public:

1. Evaluate severity: funds at risk? Metadata corruption? Minter DoS?
2. If funds at risk, pause immediately.
3. Document what went wrong. Open source a post-mortem.
4. If it's a permanent bug (can't be fixed in 48h), no redeploy is possible —
   the token address is canonical. Consider social coordination to deprecate.
5. Contracts do not have proxy / upgrade paths by design. This is the
   commitment that makes them trustworthy.

## 9. Deploy command

When every box above is checked:

```bash
cd szabo-v2
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $MAINNET_DEPLOYER_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --slow
```

`--slow` adds delay between txs so RPC doesn't rate-limit across the 5
transactions (renderer deploy, token deploy, 3 config calls).

## 10. Post-deploy record

Update `DEPLOYMENT.md` with:
- Mainnet contract addresses
- Deploy tx hashes
- Final configuration state (PublicDrop values, contractURI)
- Post-deploy admin actions with tx hashes

---

## Red lines

Regardless of how urgent it feels, **do not**:

- Deploy without running the full test suite in the same session
- Deploy with a private key that was ever in a file that touched the public
  internet (GitHub, screenshots, chat logs)
- Skip `--verify` (verified source is a basic trust signal)
- Set `startTime` to `block.timestamp` on deploy (lets MEV bots frontrun
  the first mints)
- Push a broadcast file (`broadcast/`) to GitHub — contains sensitive tx state

If you catch yourself rationalizing any of these, stop and wait a day.
