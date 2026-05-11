"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

const TOKEN = "0x24E5b6c4E31dfe50da1f449d1a4D19d521250938" as const;
const RPC_URL = "https://ethereum-rpc.publicnode.com";
const PAGE_SIZE = 24;

type Tablet = {
  id: number;
  image: string;
  name: string;
};

// eth_call helper for a function with one uint256 arg
async function ethCall(data: string) {
  const res = await fetch(RPC_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "eth_call",
      params: [{ to: TOKEN, data }, "latest"],
    }),
  });
  const json = await res.json();
  if (json.error) throw new Error(json.error.message);
  return json.result as string;
}

function encodeUint256(n: number): string {
  return n.toString(16).padStart(64, "0");
}

// decode abi-encoded string return
function decodeAbiString(hex: string): string {
  const data = hex.startsWith("0x") ? hex.slice(2) : hex;
  // [0..64) offset, [64..128) length, [128..) data
  const length = parseInt(data.slice(64, 128), 16);
  const dataHex = data.slice(128, 128 + length * 2);
  let out = "";
  for (let i = 0; i < dataHex.length; i += 2) {
    out += String.fromCharCode(parseInt(dataHex.slice(i, i + 2), 16));
  }
  return out;
}

function decodeTokenURI(uri: string): { image: string; name: string } | null {
  const prefix = "data:application/json;base64,";
  if (!uri.startsWith(prefix)) return null;
  try {
    const json = JSON.parse(atob(uri.slice(prefix.length)));
    return { image: json.image, name: json.name };
  } catch {
    return null;
  }
}

export default function ExplorePage() {
  const [total, setTotal] = useState(0);
  const [tablets, setTablets] = useState<Tablet[]>([]);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  // fetch total supply once
  useEffect(() => {
    (async () => {
      try {
        const res = await ethCall("0x18160ddd"); // totalSupply()
        setTotal(parseInt(res, 16));
      } catch (e: unknown) {
        setErr(e instanceof Error ? e.message : "failed to load total supply");
      }
    })();
  }, []);

  // fetch a page of tokenURIs
  useEffect(() => {
    if (total === 0) return;
    setLoading(true);
    setErr(null);

    const start = page * PAGE_SIZE + 1;
    const end = Math.min(start + PAGE_SIZE - 1, total);
    const ids = Array.from({ length: end - start + 1 }, (_, i) => start + i);

    (async () => {
      try {
        const results = await Promise.all(
          ids.map(async (id) => {
            // tokenURI(uint256) selector = 0xc87b56dd
            const calldata = "0xc87b56dd" + encodeUint256(id);
            const raw = await ethCall(calldata);
            const uri = decodeAbiString(raw);
            const meta = decodeTokenURI(uri);
            return meta ? { id, image: meta.image, name: meta.name } : null;
          })
        );
        setTablets(results.filter((t): t is Tablet => t !== null));
      } catch (e: unknown) {
        setErr(e instanceof Error ? e.message : "failed to load tablets");
      } finally {
        setLoading(false);
      }
    })();
  }, [page, total]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <main>
      <p>
        <Link href="/">← home</Link>
      </p>

      <h1>Explore</h1>
      <p className="dim">
        {total === 0
          ? "Loading on-chain supply…"
          : `${total} tablets minted so far. Each one rendered from contract state.`}
      </p>

      <hr className="divider" />

      {err && (
        <p style={{ color: "#ff4d4d", fontSize: 13 }}>error: {err}</p>
      )}

      {loading && tablets.length === 0 && (
        <p className="dim" style={{ fontSize: 13 }}>reading the chain…</p>
      )}

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))",
          gap: 16,
          marginTop: 16,
        }}
      >
        {tablets.map((t) => (
          <Link
            key={t.id}
            href={`/t/${t.id}`}
            style={{
              textDecoration: "none",
              color: "inherit",
              border: "1px solid #ffb00033",
              padding: 8,
              background: "#0f0a00",
            }}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={t.image}
              alt={t.name}
              style={{ width: "100%", display: "block", imageRendering: "pixelated" }}
            />
            <div style={{ marginTop: 8, fontSize: 12, fontFamily: "monospace" }}>
              {t.name}
            </div>
          </Link>
        ))}
      </div>

      {total > PAGE_SIZE && (
        <>
          <hr className="divider" />
          <div style={{ display: "flex", gap: 12, alignItems: "center", fontSize: 13 }}>
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0 || loading}
              style={{
                background: "transparent",
                color: "#ffb000",
                border: "1px solid #ffb000",
                padding: "4px 12px",
                fontFamily: "monospace",
                cursor: page === 0 ? "not-allowed" : "pointer",
                opacity: page === 0 ? 0.4 : 1,
              }}
            >
              ← prev
            </button>
            <span className="dim">
              page {page + 1} / {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1 || loading}
              style={{
                background: "transparent",
                color: "#ffb000",
                border: "1px solid #ffb000",
                padding: "4px 12px",
                fontFamily: "monospace",
                cursor: page >= totalPages - 1 ? "not-allowed" : "pointer",
                opacity: page >= totalPages - 1 ? 0.4 : 1,
              }}
            >
              next →
            </button>
          </div>
        </>
      )}
    </main>
  );
}
