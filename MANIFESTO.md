# On Szabo

*published on-chain. no company. no team. no roadmap.*

---

## I. The Unit You Never Noticed

Every time you pay gas on Ethereum, your client converts the fee into wei.

Behind every calculation sits a hierarchy of eight denominations, each named
after a person:

```
1 wei          — Wei Dai
1 kwei         —
1 mwei         —
1 gwei         — giga-wei, used everywhere
1 szabo        — Nick Szabo        ← 10^12 wei
1 finney       — Hal Finney        ← 10^15 wei
1 ether        —
```

You have been paying tribute to Nick Szabo with every transaction since 2015.
Almost no one knows this.

Szabo coined "smart contracts" in 1994. He described digital objects that
could be owned and transferred without an intermediary in 1997. He published
Bit Gold in 1998, a proof-of-work scarcity scheme that Satoshi Nakamoto
cited.

The entire stack you are using was anticipated, named, and philosophically
grounded by this person before any of it existed. His unit lives in every
transaction. His name is almost never spoken.

This project is called SZABO.

---

## II. The Cypherpunk Mailing List

Before Bitcoin. Before Ethereum. Before smart contracts ran at scale.

In 1992, Eric Hughes, Timothy C. May, and John Gilmore started a mailing
list. They wrote in plain text, signed with PGP, and believed cryptography
was a tool for individual sovereignty.

The Cypherpunk Manifesto, March 9, 1993:

> *"Privacy is the power to selectively reveal oneself to the world."*

And:

> *"Cypherpunks write code."*

They wrote it in terminals. Green phosphor on black. Amber CRTs. Monospace
characters, line by line, committed to a global mailing list with no
moderation and no hierarchy. The medium was the message: if you can type,
you can participate. If you can read plain text, you can verify.

Szabo was on this list. Wei Dai was on this list. Hal Finney was on this
list. Satoshi Nakamoto announced Bitcoin to a descendant of this list on
October 31, 2008.

The lineage is unbroken:

- 1992: cypherpunk mailing list founded
- 1993: Cypherpunk Manifesto
- 1994: Szabo — "Smart Contracts"
- 1997: Szabo — "Formalizing and Securing Relationships on Public Networks"
- 1998: Wei Dai — "b-money"; Szabo — "Bit Gold"
- 2002: Szabo — "Shelling Out: The Origins of Money"
- 2008: Satoshi — Bitcoin whitepaper
- 2009: Finney receives the first Bitcoin transaction
- 2013: Buterin — Ethereum whitepaper
- 2015: Ethereum launches; the szabo unit is in the spec
- 2017: CryptoPunks — first Ethereum NFTs
- 2026: SZABO

---

## III. What Szabo Actually Said

In 1994, Szabo defined smart contracts:

> *"A set of promises, specified in digital form, including protocols within
> which the parties perform on these promises."*

In 1997, he described what we'd later call digital objects:

> *Objects are sequences of bits that have value because of what they
> represent — rights, claims, access.*

In 2002, in "Shelling Out," he traced money back to its origin: scarce
collectibles — shells, bones, beads — that early humans gathered because
they were costly to find and easy to verify. He called them proto-money.

His thesis: the first money was not coins. Not gold. It was objects that
were hard to acquire and impossible to forge. Objects that could be
transferred as proof of value. Objects that lasted.

> *"The proto-money of our ancestors shared one property: they were
> difficult to counterfeit and expensive to produce."*

This is the intellectual foundation of everything that followed — Bitcoin's
21 million limit, Ethereum's on-chain provenance, NFT scarcity. Szabo wrote
it in 2002, not as a product whitepaper. As intellectual groundwork.

The szabo denomination was not a coincidence. It was placed in the Ethereum
specification as acknowledgment: this man saw it coming.

---

## IV. What Went Wrong With Digital Objects

CryptoPunks, 2017. 10,000 pixel-art characters. On-chain. No IPFS. The
image data lived in the contract. This was correct.

Then came the boom.

By 2021, almost no NFTs stored their images on-chain. The standard pattern:

```
ERC-721.tokenURI()
  → "https://api.project.io/metadata/1234"
  → { "image": "ipfs://Qm..." }
  → [image at IPFS node]
```

The user owned a token ID. The token ID pointed to a URL. The URL pointed
to a file on a server or a node in a distributed storage network.

What the user owned: a receipt for a claim on an image that lived elsewhere.

Szabo's 1997 definition of a digital object was violated at every layer.
The thing the user held was not the object. It was a pointer. The pointer
was on-chain. The object was not.

If the company shut down: the URL returned 404. The IPFS node unpinned. The
image vanished. The token remained — a receipt for nothing.

The correct criticism of the 2021 NFT market was not "digital art has no
value." It was: **most of what was sold was not a digital object. It was a
digital receipt.**

---

## V. The Mechanism

SZABO corrects this at the primitive level.

**What it is:**

An ERC-721 collection of 2,000 terminal tablets. Every token is a
SzaboObject:

```solidity
struct SzaboObject {
    bytes32 seed;           // all visual traits encoded here
    uint256 birthBlock;     // the block this object was born in
    address originalMinter; // first owner, immutable, permanent provenance
}
```

The seed is generated at the moment of mint from:

- `block.prevrandao` — random value from the block proposer, unpredictable
  until the block lands (EIP-4399)
- `block.timestamp`
- `block.number`
- `tokenId` — ensures siblings minted in the same transaction receive
  different seeds
- `msg.sender` — the minter's address
- the contract's own address

These inputs are hashed with keccak256. The resulting seed determines every
trait this object will ever have. The hash is written to the contract in
the same transaction as the mint. No reveal. No IPFS.

**The image:**

The SVG is not stored. It is computed.

Every time `tokenURI()` is called, the contract derives the image from the
stored seed plus `block.number`. The visual changes over time without any
transaction. A tablet minted today looks different in seven months.
Different in two years. Different in a decade.

No external call. No oracle. The image is a deterministic function of the
contract's own state and the current chain height.

**The aesthetic:**

Terminal interfaces. Phosphor green. Amber. Red alert. White on black. The
fonts are monospace. The layout recalls a VT100 session mid-1980s —
cypherpunks in rooms with CRT glow, PGP keys on floppies, text-only
mailing lists as the most important social network ever built.

A SZABO tablet is a contract written on a screen. Not clay. Not paper.
Phosphor.

**The patina:**

```
Age (blocks)       Patina
─────────────────────────────────────
0 – 50,000         Fresh     (~7 months)
50,000 – 200,000   Aged      (~2.5 years)
200,000 – 500,000  Antique   (~6 years)
500,000+           Relic     (~19+ years)
```

A tablet held for nineteen years carries a visual record of that time.
Burn-in. Color shift. Golden shimmer on the edges like oxidation on a
CRT's copper. It cannot be faked. birthBlock is written at mint. Age is
computed from chain state at render. There is no mechanism to accelerate
it.

**The distribution:**

Mint directly. 0.001 ETH per tablet. Two per wallet. No
middleman — 100% of mint revenue goes to the creator. No platform fees.
No allowlist. No Discord roles. No pre-mine.

The deployer address is permanently banned from receiving tokens, enforced
in code.

---

## VI. What It Is. What It Is Not.

**It is an ERC-721.** Exactly that. Each token has a tokenId, an owner,
and a `tokenURI` that returns a fully on-chain data URI containing the
SVG, the attributes, and the provenance.

**It is not an ERC-721 with a pointer.** The token URI does not resolve
to an IPFS hash or an HTTPS URL. It resolves to the object itself, encoded
as base64 data, rendered from contract state every time it is requested.

**It is not a receipt.** What lives in the contract is the image, the
traits, the age, and the original minter. Transferring a SZABO transfers
the object, not a claim to an object stored elsewhere.

The closest prior description was written in 1997:

> *"Objects are sequences of bits that have value because of what they
> represent — rights, claims, access."*

A SZABO is what Szabo described. On-chain. Self-contained. Not a receipt.
Not a pointer. Not a representation of something stored elsewhere.

The object itself is the thing.

---

## VII. The Deployer

This contract was deployed by one person. Anonymous. No team. No
investors. No KOL round. No Discord.

What is written in the contract about the deployer:

- The deployer cannot mint or receive tokens. Enforced in
  `_beforeTokenTransfers`. Not by trust. By code.
- Max supply can only be *decreased*, never increased. Enforced in
  `setMaxSupply`. No rug through dilution.
- Creator royalty cannot exceed 10% (`MAX_ROYALTY_BPS = 1000`). Deploy
  value is 2.5%.
- Emergency pause is capped at 48 hours. After that window it expires
  automatically. The contract cannot be permanently frozen.
- Trait probabilities are constants in a pure library. No function can
  change them.
- Mint price is immutable: 0.001 ETH. Cannot be changed after deploy.
- Per-wallet limit is immutable: 2. Cannot be changed after deploy.

What the deployer earns:

- 100% of mint revenue (0.001 ETH × minted count). No platform cut.
- 2.5% creator royalty on secondary sales (ERC-2981).

There is no hidden allocation. There is no pre-mine. The only SZABO
tokens in existence come from public mints by real buyers.

The deployer cannot rug. Not because they promised not to. Because the
contract makes it impossible.

---

## VIII. The Name

In 1994, Nick Szabo wrote "Smart Contracts" on a mailing list.

In 2015, Ethereum named its fourth denomination unit "szabo" — 10^12 wei —
after him.

Every year since, every Ethereum user has paid gas in a unit carrying his
name. Silently. Without acknowledgment.

SZABO is that acknowledgment.

Each SZABO object is a terminal tablet — a block of monospace text in
phosphor green or amber, containing the title of one of Szabo's four
essays, a quote if the inscription is dense enough, and the birthBlock
recorded in the bottom-right watermark. The rendering ages with the chain.

The object is a contract about contracts. Named after the person who saw
it first.

The szabo unit is already in your wallet. It has been since the beginning.

Now it has a form.

---

*mint: /mint*
*source: github.com/szaboethereum/szabo*
*writing: this*

*everything else is on-chain or it does not exist.*
