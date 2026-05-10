import Link from "next/link";
import { getCollectionStats, getTokenMetadata } from "@/lib/szabo";

export const revalidate = 30;

export const metadata = {
  title: "SZABO — explore",
};

async function loadAll() {
  const stats = await getCollectionStats();
  const total = Number(stats.totalSupply);
  const ids: number[] = [];
  for (let i = 1; i <= total; i++) ids.push(i);

  const items = await Promise.all(
    ids.map(async (id) => {
      try {
        const md = await getTokenMetadata(BigInt(id));
        return { id, md, ok: true as const };
      } catch {
        return { id, ok: false as const };
      }
    })
  );
  return { total, maxSupply: Number(stats.maxSupply), items };
}

export default async function ExplorePage() {
  let data: Awaited<ReturnType<typeof loadAll>> | null = null;
  try {
    data = await loadAll();
  } catch {
    data = null;
  }

  return (
    <main>
      <h1>Explore</h1>
      {!data ? (
        <p className="dim">RPC unreachable.</p>
      ) : data.items.length === 0 ? (
        <p className="dim">no tokens minted yet.</p>
      ) : (
        <>
          <p className="dim">
            {data.total} / {data.maxSupply} minted
          </p>
          <div className="grid">
            {data.items.map((item) =>
              item.ok ? (
                <Link key={item.id} href={`/t/${item.id}`} className="card">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={item.md.image} alt={item.md.name} />
                  <div className="meta">
                    #{item.id} ·{" "}
                    {item.md.attributes.find((a) => a.trait_type === "Essay")?.value ??
                      "?"}
                  </div>
                </Link>
              ) : (
                <div key={item.id} className="card dim">
                  <div className="meta">#{item.id} · error</div>
                </div>
              )
            )}
          </div>
        </>
      )}
    </main>
  );
}
