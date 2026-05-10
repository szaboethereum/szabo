import Link from "next/link";

export default function HomePage() {
  return (
    <main>
      <header>
        <h1>SZABO</h1>
        <p className="dim">
          on-chain terminal tablets. 2,000 edition. no ipfs, no oracle, no team.
        </p>
      </header>

      <hr className="divider" />

      <p>
        Every time you pay gas on Ethereum, your client converts the fee into wei. One of
        the denominations is named <em>szabo</em> — 10<sup>12</sup> wei — after Nick
        Szabo, who coined "smart contracts" in 1994 and described digital objects in 1997.
      </p>

      <p>
        You have been paying tribute to him since 2015. Almost no one knows this.
      </p>

      <p>
        SZABO is that acknowledgment. A 2,000-edition ERC-721. Each token's image is
        rendered directly from contract state — no IPFS, no oracle. The SVG ages with
        block height, shifting through four patina levels over ~19 years. The object
        and its record of time are the same thing.
      </p>

      <p>
        <Link href="/manifesto">read the manifesto →</Link>
      </p>

      <hr className="divider" />

      <h2>Mint</h2>
      <p>
        0.001 ETH per tablet. Two per wallet. No middleman — 100% of mint revenue
        goes to the creator. The deployer address is permanently blocked from
        receiving tokens, enforced in the contract.
      </p>
      <p>
        <Link className="cta" href="/mint">
          mint a tablet →
        </Link>
      </p>

      <hr className="divider" />

      <h2>Links</h2>
      <ul>
        <li>
          <Link href="/explore">explore minted tablets →</Link>
        </li>
        <li>
          <a
            href="https://github.com/szaboethereum/szabo"
            target="_blank"
            rel="noopener noreferrer"
          >
            source code →
          </a>
        </li>
      </ul>

      <p className="dim" style={{ marginTop: 64, fontSize: 12 }}>
        everything else is on-chain or it does not exist.
      </p>
    </main>
  );
}
