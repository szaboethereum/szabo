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
      <p>
        The entire stack you are using was anticipated, named, and philosophically
        grounded by this person before any of it existed. His unit lives in every
        transaction. His name is almost never spoken.
      </p>
      <p>This project is called SZABO.</p>

      <h2>II. The Cypherpunk Mailing List</h2>
      <p>Before Bitcoin. Before Ethereum. Before smart contracts ran at scale.</p>
      <p>
        In 1992, Eric Hughes, Timothy C. May, and John Gilmore started a mailing list.
        They wrote in plain text, signed with PGP, and believed cryptography was a tool
        for individual sovereignty.
      </p>
      <p>The Cypherpunk Manifesto, March 9, 1993:</p>
      <pre>{`"Privacy is the power to selectively reveal oneself to the world."`}</pre>
      <p>And:</p>
      <pre>{`"Cypherpunks write code."`}</pre>
      <p>
        They wrote it in terminals. Green phosphor on black. Amber CRTs. Monospace
        characters, line by line, committed to a global mailing list with no moderation
        and no hierarchy. The medium was the message: if you can type, you can
        participate. If you can read plain text, you can verify.
      </p>
      <p>
        Szabo was on this list. Wei Dai was on this list. Hal Finney was on this list.
        Satoshi Nakamoto announced Bitcoin to a descendant of this list on October 31,
        2008.
      </p>

      <h2>III. What Szabo Actually Said</h2>
      <p>In 1994, Szabo defined smart contracts:</p>
      <pre>{`"A set of promises, specified in digital form, including
protocols within which the parties perform on these promises."`}</pre>
      <p>In 1997, he described what we'd later call digital objects:</p>
      <pre>{`Objects are sequences of bits that have value because of
what they represent — rights, claims, access.`}</pre>
      <p>
        In 2002, in "Shelling Out," he traced money back to its origin: scarce
        collectibles — shells, bones, beads — that early humans gathered because they
        were costly to find and easy to verify. He called them proto-money.
      </p>
      <p>
        His thesis: the first money was not coins. Not gold. It was objects that were
        hard to acquire and impossible to forge. Objects that could be transferred as
        proof of value. Objects that lasted.
      </p>
      <p>
        The szabo denomination was not a coincidence. It was placed in the Ethereum
        specification as acknowledgment.
      </p>

      <h2>IV. What Went Wrong With Digital Objects</h2>
      <p>
        CryptoPunks, 2017. 10,000 pixel-art characters. On-chain. No IPFS. The image
        data lived in the contract. This was correct.
      </p>
      <p>Then came the boom.</p>
      <p>By 2021, almost no NFTs stored their images on-chain. The standard pattern:</p>
      <pre>{`ERC-721.tokenURI()
  → "https://api.project.io/metadata/1234"
  → { "image": "ipfs://Qm..." }
  → [image at IPFS node]`}</pre>
      <p>
        What the user owned: a receipt for a claim on an image that lived elsewhere.
      </p>
      <p>
        Szabo's 1997 definition was violated at every layer. The thing the user held was
        not the object. It was a pointer.
      </p>
      <p>
        The correct criticism of the 2021 NFT market was not "digital art has no
        value." It was: <strong>most of what was sold was not a digital object. It was a
        digital receipt.</strong>
      </p>

      <h2>V. The Mechanism</h2>
      <p>
        SZABO corrects this at the primitive level. An ERC-721 collection of 2,000
        terminal tablets. Every token is a SzaboObject:
      </p>
      <pre>{`struct SzaboObject {
    bytes32 seed;           // all visual traits encoded here
    uint256 birthBlock;     // the block this object was born in
    address originalMinter; // first owner, immutable, permanent provenance
}`}</pre>
      <p>
        The seed is generated at mint from block.prevrandao (EIP-4399), block
        parameters, tokenId, and the minter's address — hashed together with keccak256.
        The SVG is not stored. It is computed from the stored seed plus block.number
        every time tokenURI() is called.
      </p>
      <p>
        A tablet minted today looks different in seven months. Different in two years.
        Different in a decade. The medium ages with the chain. There is no mechanism to
        accelerate it.
      </p>
      <pre>{`Age (blocks)       Patina
─────────────────────────────────────
0 – 50,000         Fresh     (~7 months)
50,000 – 200,000   Aged      (~2.5 years)
200,000 – 500,000  Antique   (~6 years)
500,000+           Relic     (~19+ years)`}</pre>

      <h2>VI. The Deployer</h2>
      <p>
        This contract was deployed by one person. Anonymous. No team. No investors. No
        KOL round. No Discord.
      </p>
      <p>What is written in the contract about the deployer:</p>
      <ul>
        <li>Cannot mint or receive tokens. Enforced in <code>_beforeTokenTransfers</code>.</li>
        <li>Max supply can only be <em>decreased</em>.</li>
        <li>Creator royalty cannot exceed 10% (deploy value: 2.5%).</li>
        <li>Emergency pause is capped at 48h. Auto-expires.</li>
        <li>Trait probabilities are constants. No function can change them.</li>
      </ul>
      <p>
        The deployer cannot rug. Not because they promised not to. Because the contract
        makes it impossible.
      </p>

      <h2>VII. The Name</h2>
      <p>In 1994, Nick Szabo wrote "Smart Contracts" on a mailing list.</p>
      <p>
        In 2015, Ethereum named its fourth denomination unit "szabo" — 10<sup>12</sup>{" "}
        wei — after him.
      </p>
      <p>
        Every year since, every Ethereum user has paid gas in a unit carrying his name.
        Silently. Without acknowledgment.
      </p>
      <p>SZABO is that acknowledgment.</p>
      <p>
        Each SZABO object is a terminal tablet — a block of monospace text in phosphor
        green or amber, containing the title of one of Szabo's four essays, a quote if
        the inscription is dense enough, and the birthBlock recorded in the bottom-right
        watermark. The rendering ages with the chain.
      </p>
      <p>The object is a contract about contracts. Named after the person who saw it first.</p>
      <p className="dim" style={{ marginTop: 48, fontSize: 12 }}>
        everything else is on-chain or it does not exist.
      </p>
    </main>
  );
}
