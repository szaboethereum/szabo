# DEPLOYMENT.md — SZABO v2 Sepolia deployment ledger

Kronolojik sırayla tüm zincir-üstü işlemler. Tekrar-erişim için.

---

## Sepolia (chain id 11155111)

### Deployer

| Alan     | Değer                                        |
|----------|----------------------------------------------|
| Address  | `0x046322a6C44c0FAfF548F00d25BFd7afbA168Aae` |
| Funding  | 0.05 ETH (Sepolia faucet)                    |

> Private key `.env` içinde, git ignore edildi. Kiro chat log'unda da geçti — mainnet için kullanılmayacak.

---

### Canlı kontratlar

| Kontrat       | Adres                                        | Deploy tx                                                            |
|---------------|----------------------------------------------|----------------------------------------------------------------------|
| SzaboRenderer | `0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB` | `0x5df6e4844520bdea021526147d7c1512dac8b001f9436d830b61fc8506d3179b` |
| SzaboObjects  | `0x061077B2cdc9774cD77aC098326422667aE5a650` | `0x368556b5e52aa532b8f2c8242eca37e914c8712c8951b6cb9a05ed53b7af9e51` |

Dış kontratlar (Sepolia):
- SeaDrop singleton: `0x00005EA00Ac477B1030CE78506496e8C2dE24bf5`
- OpenSea fee recipient: `0x0000a26b00c1F0DF003000390027140000fAa719`

Blockscout:
- Token: https://eth-sepolia.blockscout.com/token/0x061077B2cdc9774cD77aC098326422667aE5a650
- Renderer: https://eth-sepolia.blockscout.com/address/0xdF365FbC67654351dC3f1315c250E8Fdd81c1ecB

---

### Post-deploy konfigürasyon

Sırayla çalıştırılan owner-only çağrılar:

| # | Çağrı                          | Tx                                                                   | Gas    |
|---|--------------------------------|----------------------------------------------------------------------|--------|
| 1 | updateCreatorPayoutAddress     | `0xaa8cdb43263a3d9e1a4b1e79cfef1c0d5e001b732b4da34ac0ea43933e817bb7` | 54,942 |
| 2 | updateAllowedFeeRecipient      | `0xc11d6990496075d9ef7d782b4dece9b486143ff0f3a5fca30bc7fcddedcce9bb` | 100,027|
| 3 | updatePublicDrop (placeholder) | `0xb06afdedf7b0d3a3e827daa6c8f5eff5663fcfbfc33a0d2be4a5f325c7839c31` | 58,984 |
| 4 | updatePublicDrop (live)        | `0x90f168f8bcb271639c7c75ba9d3301371ae927e0c5411e472e9481d6e9e8e15f` | 41,872 |
| 5 | updatePayer (deployer)         | *(ilk başarılı tx, grep yakalamadı; DuplicatePayer retry teyit etti)* | ~40k  |

Live PublicDrop parametreleri:
```
mintPrice:                 1_000_000_000_000_000 wei  (0.001 ETH)
startTime:                 1778376448                (epoch, ~deploy anı)
endTime:                   1809912508                (~1 yıl sonra)
maxTotalMintableByWallet:  2
feeBps:                    1000                      (10% OpenSea fee)
restrictFeeRecipients:     true
```

---

### Test mint'leri

| # | Recipient                                    | Qty | Token IDs | Tx                                                                   |
|---|----------------------------------------------|-----|-----------|----------------------------------------------------------------------|
| 1 | `0x118ebF25b1970Fd35356E552218dFA01e43e7798` | 1   | #1        | `0xec34c5b552406796ab5682520bb658ee583dc15660a77d79e717d45a75e2a8e8` |
| 2 | `0xf5501e736D12059c19f87713738663Cd76D10ad2` | 2   | #2, #3    | `0x95d192fb4ec0c50f559b24c0448b16938a050f7bf255cfa93cbc7ffa89d254c4` |

Trait roll sonuçları (on-chain SVG'den):

| Token | Essay                    | Inscription | Terminal       | Frame  | Symbol | Rarity |
|-------|--------------------------|-------------|----------------|--------|--------|--------|
| #1    | Smart Contracts          | Sparse      | Amber          | None   | None   | 55     |
| #2    | Secure Property Titles   | Blank       | Amber          | None   | None   | 65     |
| #3    | Bit Gold                 | Dense       | Phosphor Green | Ornate | None   | 62     |

---

### Doğrulanmış revert senaryoları

| Senaryo                                      | Sonuç                                                       |
|----------------------------------------------|-------------------------------------------------------------|
| mintPublic payer != minter, payer allowed değil | `PayerNotAllowed` ✓                                         |
| mintPublic minter == deployer                | `DeployerCannotMint` ✓ (kontrat seviyesi)                   |
| mintPublic 3. NFT aynı cüzdana               | `MintQuantityExceedsMaxMintedPerWallet(3, 2)` ✓ (SeaDrop)   |
| updatePayer zaten eklenmiş adresle           | `DuplicatePayer` ✓                                          |

### Doğrulanmış fork (patina) testleri

`test/SepoliaFork.t.sol` — 3/3 pass:
- `test_Fork_TokenOneExists` ✓
- `test_Fork_PatinaProgression` ✓ (Fresh → Aged → Antique → Relic)
- `test_Fork_TokenURIChangesWithPatina` ✓

---

### Kalan işler

- [ ] Kontrat verify (Etherscan veya Blockscout)
- [ ] `setContractURI` — koleksiyon-düzeyi metadata
- [ ] `setBaseURI` ayarlanmayacak (on-chain SVG zorunlu tutulsun)
- [ ] szabo.art frontend (opsiyonel, öncelik değil)
- [ ] Mainnet deploy hazırlığı (MANIFESTO-v2 final, soğuk cüzdan, vs.)

---

### Bakiye durumu (son kontrol)

Deploy + post-config + 3 test mint sonrası:
- Deployer: `0.049693720744517499 ETH` (başlangıç 0.05, harcama ~0.000306 ETH)
- Test cüzdan #1 `0x118e...7798`: 0.0 ETH (NFT alıcı, ödeme yapmadı)
- Test cüzdan #2 `0xf550...0ad2`: 0.0 ETH (NFT alıcı)

Harcama dağılımı:
- 2 deploy + 4 config tx + 3 mint + 1 edge-case revert = ~6M gas
- Sepolia gaz ~0.001-0.05 gwei aralığında
- OpenSea fee olarak 3 × 0.0001 = 0.0003 ETH opensea fee recipient'a
- Creator payout (0.0027 ETH) geri deployer'a döndü

> Not: Creator payout deployer adresine geri geldi çünkü `updateCreatorPayoutAddress(deployer)` çağrılmış. Net maliyet ~0.000306 ETH (0.0003 OpenSea fee + 0.000006 gas).
