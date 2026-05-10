# DEPLOYMENT.md — SZABO deployment ledger

Kronolojik sırayla tüm zincir-üstü işlemler. Tekrar-erişim için.

---

## Mainnet (chain id 1)

### Deployer

| Alan     | Değer                                        |
|----------|----------------------------------------------|
| Address  | `0x4D9E6f1Dab6eE15a603FD6036C63F03E67B996B5` |
| Purpose  | One-time mainnet deploy + drop admin         |

> Private key lives in `.env` under `MAINNET_DEPLOYER_KEY`. Not checked in.

---

### Canlı kontratlar

| Kontrat       | Adres                                        | Deploy Tx                                                            | Etherscan                                                                 |
|---------------|----------------------------------------------|----------------------------------------------------------------------|---------------------------------------------------------------------------|
| SzaboRenderer | `0x8B7ee142C7143940Be11B26a283d30E8b56888A3` | (see run-latest.json)                                                | https://etherscan.io/address/0x8b7ee142c7143940be11b26a283d30e8b56888a3   |
| SzaboObjects  | `0x8410b70eB54a95877305d6cD727Adda65de09f50` | (see run-latest.json)                                                | https://etherscan.io/address/0x8410b70eb54a95877305d6cd727adda65de09f50   |

**Both contracts verified on Etherscan via `forge verify-contract` during deploy.**

Dış kontratlar (mainnet):
- SeaDrop singleton: `0x00005EA00Ac477B1030CE78506496e8C2dE24bf5`
- OpenSea fee recipient: `0x0000a26b00c1F0DF003000390027140000fAa719`

---

### Post-deploy konfigürasyon

Deploy script içinde otomatik:
1. `updateCreatorPayoutAddress(SEADROP, deployer)` — mint gelirleri deployer'a
2. `updateAllowedFeeRecipient(SEADROP, OPENSEA_FEE_RECIPIENT, true)`
3. `updatePayer(SEADROP, deployer, true)` — deployer başka adrese mintleyebilir
4. `updatePublicDrop(SEADROP, publicDrop)` — placeholder startTime

Deploy sonrası manuel:
| # | Çağrı                  | Tx                                                                   | Gas     |
|---|------------------------|----------------------------------------------------------------------|---------|
| 5 | `setContractURI`       | `0xb297567276d2c4b032649eb322abd323a62895630aaab1d29c89c04a26f463cc` | 461,440 |

Live PublicDrop parametreleri (placeholder):
```
mintPrice:                 1_000_000_000_000_000 wei  (0.001 ETH)
startTime:                 1809915911                (≈ 1 year out, placeholder)
endTime:                   1841451911                (≈ 2 years out)
maxTotalMintableByWallet:  2
feeBps:                    1000                      (10% OpenSea fee)
restrictFeeRecipients:     true
```

**Mint is closed until the owner pushes a new PublicDrop with a real startTime.**

---

### Kalan işler (mainnet)

- [ ] Gerçek `startTime` ile `updatePublicDrop` (launch günü)
- [ ] OpenSea Studio'da koleksiyon sayfası (logo, description)
- [ ] `transferOwnership` soğuk cüzdana (opsiyonel, önerilen)
- [ ] szabo.art frontend production deploy (Vercel)
- [ ] Duyuru (MANIFESTO + mint link)

---

## Sepolia (chain id 11155111) — v2 rehearsal

### Deployer
- Address: `0x046322a6C44c0FAfF548F00d25BFd7afbA168Aae`

### Kontratlar
| Kontrat       | Adres                                        |
|---------------|----------------------------------------------|
| SzaboRenderer | `0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB` |
| SzaboObjects  | `0x061077B2cdc9774cD77aC098326422667aE5a650` |

Blockscout:
- Token: https://eth-sepolia.blockscout.com/token/0x061077B2cdc9774cD77aC098326422667aE5a650
- Renderer: https://eth-sepolia.blockscout.com/address/0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB

### Test mintleri (sepolia)

| # | Recipient                                    | Qty | Token IDs | Tx                                                                   |
|---|----------------------------------------------|-----|-----------|----------------------------------------------------------------------|
| 1 | `0x118ebF25b1970Fd35356E552218dFA01e43e7798` | 1   | #1        | `0xec34c5b552406796ab5682520bb658ee583dc15660a77d79e717d45a75e2a8e8` |
| 2 | `0xf5501e736D12059c19f87713738663Cd76D10ad2` | 2   | #2, #3    | `0x95d192fb4ec0c50f559b24c0448b16938a050f7bf255cfa93cbc7ffa89d254c4` |

Trait roll sonuçları:

| Token | Essay                    | Inscription | Terminal       | Frame  | Symbol | Rarity |
|-------|--------------------------|-------------|----------------|--------|--------|--------|
| #1    | Smart Contracts          | Sparse      | Amber          | None   | None   | 55     |
| #2    | Secure Property Titles   | Blank       | Amber          | None   | None   | 65     |
| #3    | Bit Gold                 | Dense       | Phosphor Green | Ornate | None   | 62     |

### Doğrulanmış revert senaryoları (sepolia)

| Senaryo                                    | Sonuç                                              |
|--------------------------------------------|----------------------------------------------------|
| mintPublic payer allowed değil             | `PayerNotAllowed` ✓                                |
| mintPublic minter == deployer              | `DeployerCannotMint` ✓ (kontrat seviyesi)          |
| mintPublic 3. NFT aynı cüzdana             | `MintQuantityExceedsMaxMintedPerWallet(3, 2)` ✓    |
| updatePayer zaten eklenmiş adresle         | `DuplicatePayer` ✓                                 |

### Fork testleri (sepolia canlı deploy üstünde)

`test/SepoliaFork.t.sol` — 3/3 pass:
- `test_Fork_TokenOneExists` ✓
- `test_Fork_PatinaProgression` ✓ (Fresh → Aged → Antique → Relic)
- `test_Fork_TokenURIChangesWithPatina` ✓

---

## Notlar

- Mainnet'te hiç test mint yapılmadı — PublicDrop placeholder `startTime`
  (~1 yıl ileri) mint'i engelliyor. Test için launch öncesi `updatePublicDrop`
  ile kısa süreli aktif pencere açıp kapatılabilir.
- Sepolia deployment'ı kalıcı olarak referans için bırakıldı.
