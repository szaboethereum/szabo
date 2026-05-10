# MAINNET_CHECKLIST.md — V2 (no SeaDrop)

## Before deploy

- [ ] `forge test -vvv` — all tests pass
- [ ] `forge build --sizes` — SzaboObjectsV2 < 24,576 bytes
- [ ] `forge fmt --check` — clean
- [ ] Deployer wallet funded (≥ 0.002 ETH for deploy + openMint + buffer)
- [ ] `.env` has `MAINNET_DEPLOYER_KEY` and `MAINNET_RPC_URL`

## Deploy

```bash
forge script script/DeployV2.s.sol:DeployV2 \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --slow
```

## After deploy

- [ ] Verify on Etherscan (auto via --verify flag)
- [ ] Call `openMint()` when ready to launch:
  ```bash
  cast send $TOKEN "openMint()" \
    --rpc-url $MAINNET_RPC_URL \
    --private-key $MAINNET_DEPLOYER_KEY
  ```
- [ ] Update `web/src/app/mint/page.tsx` — set TOKEN to new address
- [ ] `git push` → Vercel auto-deploys
- [ ] Test mint from a non-deployer wallet
- [ ] Verify tokenURI returns on-chain SVG
- [ ] Set `contractURI` (optional, for OpenSea collection metadata):
  ```bash
  cast send $TOKEN "setContractURI(string)" "data:application/json;base64,..." \
    --rpc-url $MAINNET_RPC_URL \
    --private-key $MAINNET_DEPLOYER_KEY
  ```
- [ ] Announce (Twitter, szabo.art)

## Emergency

```bash
# Pause minting (48h auto-expire)
cast send $TOKEN "emergencyPauseMinting()" --rpc-url $MAINNET_RPC_URL --private-key $MAINNET_DEPLOYER_KEY

# Resume early
cast send $TOKEN "resumeMinting()" --rpc-url $MAINNET_RPC_URL --private-key $MAINNET_DEPLOYER_KEY

# Withdraw mint revenue
cast send $TOKEN "withdraw()" --rpc-url $MAINNET_RPC_URL --private-key $MAINNET_DEPLOYER_KEY
```
