import Link from "next/link";
import { notFound } from "next/navigation";
import { getTokenMetadata, getTokenOwner, getTokenObject, shortAddress } from "@/lib/szabo";
import { chain, szaboAddress } from "@/lib/chain";

export const revalidate = 30;

function explorerBase() {
  if (chain.id === 1) return "https://etherscan.io";
  if (chain.id === 11155111) return "https://eth-sepolia.blockscout.com";
  return "https://etherscan.io";
}

function patinaBlocksRemaining(currentAge: bigint): { next: string; blocksUntil: bigint } {
  const thresholds: Array<[bigint, string]> = [
    [50_000n, "Aged"],
    [200_000n, "Antique"],
    [500_000n, "Relic"],
  ];
  for (const [threshold, name] of thresholds) {
    if (currentAge < threshold) {
      return { next: name, blocksUntil: threshold - currentAge };
    }
  }
  return { next: "—", blocksUntil: 0n };
}

export default async function TokenPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const tokenId = BigInt(id);

  let md, owner, obj;
  try {
    [md, owner, obj] = await Promise.all([
      getTokenMetadata(tokenId),
      getTokenOwner(tokenId),
      getTokenObject(tokenId),
    ]);
  } catch {
    notFound();
  }

  const ageAttr = md.attributes.find((a) => a.trait_type === "Age (blocks)");
  const currentAge = BigInt((ageAttr?.value as number) ?? 0);
  const patina = patinaBlocksRemaining(currentAge);

  return (
    <main>
      <p>
        <Link href="/explore">← explore</Link>
      </p>

      <h1>{md.name}</h1>
      <p className="dim">{md.description}</p>

      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img className="detail-img" src={md.image} alt={md.name} />

      <h2>Traits</h2>
      <dl className="kv">
        {md.attributes.map((a) => (
          <>
            <dt key={`k-${a.trait_type}`}>{a.trait_type}</dt>
            <dd key={`v-${a.trait_type}`}>{String(a.value)}</dd>
          </>
        ))}
      </dl>

      <h2>Patina</h2>
      <dl className="kv">
        <dt>current age</dt>
        <dd>{currentAge.toString()} blocks</dd>
        {patina.next !== "—" && (
          <>
            <dt>next level</dt>
            <dd>
              {patina.next} · in {patina.blocksUntil.toString()} blocks
            </dd>
          </>
        )}
      </dl>

      <h2>On-chain</h2>
      <dl className="kv">
        <dt>current owner</dt>
        <dd>
          <a
            href={`${explorerBase()}/address/${owner}`}
            target="_blank"
            rel="noopener noreferrer"
            title={owner}
          >
            {shortAddress(owner)}
          </a>
        </dd>
        <dt>original minter</dt>
        <dd>
          <a
            href={`${explorerBase()}/address/${obj.originalMinter}`}
            target="_blank"
            rel="noopener noreferrer"
            title={obj.originalMinter}
          >
            {shortAddress(obj.originalMinter)}
          </a>
        </dd>
        <dt>birth block</dt>
        <dd>{obj.birthBlock.toString()}</dd>
        <dt>seed</dt>
        <dd>
          <code style={{ fontSize: 11 }}>{obj.seed}</code>
        </dd>
        <dt>token</dt>
        <dd>
          <a
            href={`${explorerBase()}/token/${szaboAddress}/instance/${id}`}
            target="_blank"
            rel="noopener noreferrer"
          >
            open on {explorerBase().replace("https://", "")} →
          </a>
        </dd>
      </dl>
    </main>
  );
}
