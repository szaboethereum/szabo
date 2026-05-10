import Link from "next/link";

export const metadata = {
  title: "SZABO — manifesto",
};

export default function ManifestoPage() {
  return (
    <main>
      <p>
        <Link href="/">← home</Link>
      </p>

      <h1>On Szabo</h1>
      <p className="dim">published on-chain. no company. no team. no roadmap.</p>

      <h2>I. The Unit You Never Noticed</h2>
      <p>
        Every time you pay gas on Ethereum, your client converts the fee into wei. Behind
        every calculation sits a hierarchy of eight denominations, each named after a
        person:
      </p>
      <pre>{`1 wei          — Wei Dai
1 kwei         —
1 mwei         —
1 gwei         — giga-wei, used everywhere
1 szabo        — Nick Szabo        ← 10^12 wei
1 finney       — Hal Finney        ← 10^15 wei
1 ether        —`}</pre>
      <p>
        You have been paying tribute to Nick Szabo with every transaction since 2015.
        Almost no one knows this.
      </p>
      <p>
        Szabo coined "smart contracts" in 1994. He described digital objects that could
        be owned and transferred without an intermediary in 1997. He published Bit Gold in
        1998 — a proof-of-work scarcity scheme that Satoshi Nakamoto cited.
      </p>
      <p>This project is called SZABO.</p>

      <h2>II. The Cypherpunk Mailing List</h2>
      <p>Before Bitcoin. Before Ethereum. Before smart contracts ran at scale.</p>
      <p>
        In 1992, Eric Hughes, Timothy C. May, and John Gilmore started a mailing list.
        They wrote in plain text, signed with PGP, and believed cryptography was a tool
        for individual sovereignty.
      </p>
      <pre>{`"Privacy is the power to selectively reveal oneself to the world."

"Cypherpunks write code."`}</pre>
      <p>
        They wrote it in terminals. Green phosphor on black. Amber CRTs. Monospace
        characters, line by line, committed to a global mailing list with no moderation
        and no hierarchy.
      </p>
      <p>
        Szabo was on this list. Wei Dai was on this list. Hal Finney was on this list.
        Satoshi Nakamoto announced Bitcoin to a descendant of this list on October 31,
        2008.
      </p>

      <h2>III. What Szabo Actually Said</h2>
      <p>In 1994:</p>
      <pre>{`"A set of promises, specified in digital form, including
protocols within which the parties perform on these promises."`}</pre>
      <p>In 1997:</p>
      <pre>{`Objects are sequences of bits that have value because of
what they represent — rights, claims, access.`}</pre>
      <p>
        In 2002, in "Shelling Out," he traced money back to its origin: scarce
        collectibles that early humans gathered because they were costly to find and easy
        to verify. He called them proto-money.
      </p>
      <p>
        The szabo denomination was not a coincidence. It was placed in the Ethereum
        specification as acknowledgment.
      </p>

      <h2>IV. What Went Wrong With Digital Objects</h2>
      <p>
        CryptoPunks, 2017. On-chain. No IPFS. Correct.
      </p>
      <p>
        By 2021, almost no NFTs stored their images on-chain:
      </p>
      <pre>{`ERC-721.tokenURI()
  → "https://api.project.io/metadata/1234"
  → { "image": "ipfs://Qm..." }
  → [image at IPFS node]`}</pre>
      <p>
        What the user owned: a receipt for a claim on an image that lived elsewhere.
      </p>
      <p>
        The correct criticism: <strong>most of what was sold was not a digital object.
        It was a digital receipt.</strong>
      </p>

      <h2>V. The Mechanism</h2>
      <p>
        SZABO corrects this. 2,000 terminal tablets. Every token is a SzaboObject:
      </p>
      <pre>{`struct SzaboObject {
    bytes32 seed;           // all visual traits
    uint256 birthBlock;     // drives patina
    address originalMinter; // permanent provenance
}`}</pre>
      <p>
        The seed is generated at mint from block.prevrandao, block parameters, tokenId,
        and the minter's address. The SVG is computed — not stored — from the seed plus
        block.number every time tokenURI() is called.
      </p>
      <pre>{`Age (blocks)       Patina
─────────────────────────────────────
0 – 50,000         Fresh     (~7 months)
50,000 – 200,000   Aged      (~2.5 years)
200,000 – 500,000  Antique   (~6 years)
500,000+           Relic     (~19+ years)`}</pre>
      <p>
        Terminal aesthetic. Phosphor green. Amber. Red alert. The layout recalls a VT100
        session — cypherpunks in rooms with CRT glow.
      </p>

      <h2>VI. No Middleman</h2>
      <p>
        Mint directly from szabo.art. 0.001 ETH. Two per wallet. 100% of mint revenue
        goes to the creator. No platform fees. No allowlist. No Discord roles. No
        pre-mine.
      </p>
      <p>
        The deployer cannot mint or receive tokens. Enforced in code, not by trust.
      </p>

      <h2>VII. The Deployer</h2>
      <p>
        One person. Anonymous. No team. No investors.
      </p>
      <ul>
        <li>Cannot mint or receive tokens (code-enforced)</li>
        <li>Max supply can only decrease, never increase</li>
        <li>Royalty cannot exceed 10% (deploy value: 2.5%)</li>
        <li>Emergency pause capped at 48h, auto-expires</li>
        <li>Mint price immutable: 0.001 ETH</li>
        <li>Per-wallet limit immutable: 2</li>
        <li>Trait probabilities are constants, no admin function</li>
      </ul>
      <p>
        The deployer cannot rug. Not because they promised not to. Because the contract
        makes it impossible.
      </p>

      <h2>VIII. The Name</h2>
      <p>
        In 1994, Nick Szabo wrote "Smart Contracts" on a mailing list. In 2015, Ethereum
        named its fourth denomination unit "szabo" — 10<sup>12</sup> wei — after him.
      </p>
      <p>
        Every year since, every Ethereum user has paid gas in a unit carrying his name.
        Silently. Without acknowledgment.
      </p>
      <p>SZABO is that acknowledgment.</p>
      <p>
        The szabo unit is already in your wallet. It has been since the beginning.
        Now it has a form.
      </p>

      <hr className="divider" />

      <p className="dim" style={{ fontSize: 12 }}>
        mint: szabo.art/mint · source: github.com/szaboethereum/szabo
        <br />
        everything else is on-chain or it does not exist.
      </p>
    </main>
  );
}
