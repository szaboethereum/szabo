"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { use } from "react";

const TOKEN = "0x24E5b6c4E31dfe50da1f449d1a4D19d521250938" as const;
const RPC_URL = "https://ethereum-rpc.publicnode.com";

type Meta = {
  name: string;
  description: string;
  image: string;
  attributes: Array<{ trait_type: string; value: string | number }>;
};

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

function decodeAbiString(hex: string): string {
  const data = hex.startsWith("0x") ? hex.slice(2) : hex;
  const length = parseInt(data.slice(64, 128), 16);
  const dataHex = data.slice(128, 128 + length * 2);
  let out = "";
  for (let i = 0; i < dataHex.length; i += 2) {
    out += String.fromCharCode(parseInt(dataHex.slice(i, i + 2), 16));
  }
  return out;
}

export default function TokenPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const tokenId = parseInt(id, 10);

  const [meta, setMeta] = useState<Meta | null>(null);
  const [owner, setOwner] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!tokenId || isNaN(tokenId)) return;
    (async () => {
      try {
        // tokenURI(uint256) = 0xc87b56dd
        const uriRaw = await ethCall("0xc87b56dd" + encodeUint256(tokenId));
        const uri = decodeAbiString(uriRaw);
        if (!uri.startsWith("data:application/json;base64,")) throw new Error("unexpected uri");
        const json = JSON.parse(atob(uri.slice("data:application/json;base64,".length)));
        setMeta(json as Meta);

        // ownerOf(uint256) = 0x6352211e
        const ownerRaw = await ethCall("0x6352211e" + encodeUint256(tokenId));
        setOwner("0x" + ownerRaw.slice(-40));
      } catch (e: unknown) {
        setErr(e instanceof Error ? e.message : "failed to load token");
      }
    })();
  }, [tokenId]);

  return (
    <main>
      <p>
        <Link href="/explore">← explore</Link>
      </p>

      <h1>{meta?.name ?? `Token #${tokenId}`}</h1>

      {err && <p style={{ color: "#ff4d4d", fontSize: 13 }}>error: {err}</p>}

      {!meta && !err && <p className="dim" style={{ fontSize: 13 }}>reading the chain…</p>}

      {meta && (
        <>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24, marginTop: 16, maxWidth: 800, margin: "16px auto 0" }}>
            <div style={{ border: "1px solid #ffb00055", background: "#0f0a00", padding: 12, aspectRatio: "1", display: "flex", alignItems: "center", justifyContent: "center" }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={meta.image} alt={meta.name} style={{ width: "100%", height: "100%", display: "block", objectFit: "contain" }} />
            </div>

            <div style={{ fontSize: 13 }}>
              <p className="dim" style={{ marginBottom: 16 }}>
                {meta.description}
              </p>

              <hr className="divider" />

              <h3 style={{ marginTop: 12, marginBottom: 8 }}>Attributes</h3>
              <table style={{ width: "100%", fontFamily: "monospace", fontSize: 12 }}>
                <tbody>
                  {meta.attributes.map((a) => (
                    <tr key={a.trait_type}>
                      <td style={{ color: "#ffb00099", padding: "4px 8px 4px 0" }}>
                        {a.trait_type}
                      </td>
                      <td style={{ color: "#ffb000" }}>{a.value}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {owner && (
                <>
                  <hr className="divider" />
                  <p className="dim" style={{ fontSize: 12 }}>
                    owner:{" "}
                    <a
                      href={`https://etherscan.io/address/${owner}`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {owner.slice(0, 6)}…{owner.slice(-4)}
                    </a>
                  </p>
                </>
              )}

              <p className="dim" style={{ fontSize: 12, marginTop: 8 }}>
                <a
                  href={`https://etherscan.io/nft/${TOKEN}/${tokenId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  view on etherscan →
                </a>
              </p>
            </div>
          </div>
        </>
      )}
    </main>
  );
}
