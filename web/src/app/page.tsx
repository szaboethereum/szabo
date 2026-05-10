import Link from "next/link";
import { getCollectionStats } from "@/lib/szabo";
import { openseaSlug, szaboAddress, chain } from "@/lib/chain";

export const revalidate = 60;

function explorerBase() {
  if (chain.id === 1) return "https://etherscan.io";
  if (chain.id === 11155111) return "https://eth-sepolia.blockscout.com";
  return "https://etherscan.io";
}

export default async function HomePage() {
  let stats: Awaited<ReturnType<typeof getCollectionStats>> | null = null;
  try {
    stats = await getCollectionStats();
  } catch {
    stats = null;
  }

  const mintUrl = openseaSlug
    ? `https://opensea.io/collection/${openseaSlug}/drop`
    : `${explorerBase()}/token/${szaboAddress}`;

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
        Minting happens on OpenSea Drops. 0.001 ETH. Two per wallet. The deployer
        address is permanently blocked from receiving tokens — enforced in the
        contract, not by trust.
      </p>
      <p>
        <a className="cta" href={mintUrl} target="_blank" rel="noopener noreferrer">
          {openseaSlug ? "mint on opensea →" : "view contract →"}
        </a>
      </p>

      <hr className="divider" />

      <h2>Status</h2>
      {stats ? (
        <dl className="kv">
          <dt>minted</dt>
          <dd>
            {stats.totalSupply.toString()} / {stats.maxSupply.toString()}
          </dd>
          <dt>chain</dt>
          <dd>{chain.name}</dd>
          <dt>contract</dt>
          <dd>
            <a
              href={`${explorerBase()}/address/${szaboAddress}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              {szaboAddress}
            </a>
          </dd>
        </dl>
      ) : (
        <p className="dim">RPC unreachable. Set NEXT_PUBLIC_RPC_URL in .env.</p>
      )}

      <hr className="divider" />

      <h2>Links</h2>
      <ul>
        <li>
          <Link href="/explore">explore all minted tablets →</Link>
        </li>
        <li>
          <a
            href={`${explorerBase()}/token/${szaboAddress}`}
            target="_blank"
            rel="noopener noreferrer"
          >
            contract on {explorerBase().replace("https://", "")} →
          </a>
        </li>
      </ul>

      <p className="dim" style={{ marginTop: 64, fontSize: 12 }}>
        everything else is on-chain or it does not exist.
      </p>
    </main>
  );
}
