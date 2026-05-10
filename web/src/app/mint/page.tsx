"use client";

import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  useAccount,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseEther, createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";
import { useState, useEffect } from "react";

// V2 contract deployed on mainnet
const TOKEN = "0x24E5b6c4E31dfe50da1f449d1a4D19d521250938" as const;
const MINT_PRICE = parseEther("0.001");
const MAX_SUPPLY = 2000;

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http("https://ethereum-rpc.publicnode.com"),
});

const mintAbi = [
  {
    type: "function",
    name: "mint",
    stateMutability: "payable",
    inputs: [{ name: "quantity", type: "uint256" }],
    outputs: [],
  },
  {
    type: "function",
    name: "totalSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "result", type: "uint256" }],
  },
] as const;

export default function MintPage() {
  const { address, isConnected } = useAccount();
  const [qty, setQty] = useState(1);
  const [minted, setMinted] = useState(0);

  const { data: hash, writeContract, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    async function fetchSupply() {
      try {
        const res = await fetch("https://ethereum-rpc.publicnode.com", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "eth_call",
            params: [
              {
                to: TOKEN,
                data: "0x18160ddd", // totalSupply() selector
              },
              "latest",
            ],
          }),
        });
        const json = await res.json();
        if (json.result) {
          setMinted(parseInt(json.result, 16));
        }
      } catch (e) {
        console.error("Failed to fetch supply:", e);
      }
    }
    fetchSupply();
    const interval = setInterval(fetchSupply, 10000);
    return () => clearInterval(interval);
  }, [isSuccess]);

  const progress = (minted / MAX_SUPPLY) * 100;

  function mint() {
    if (!address) return;
    writeContract({
      address: TOKEN,
      abi: mintAbi,
      functionName: "mint",
      args: [BigInt(qty)],
      value: MINT_PRICE * BigInt(qty),
    });
  }

  return (
    <main>
      <p>
        <Link href="/">← home</Link>
      </p>

      <h1>Mint</h1>
      <p className="dim">
        0.001 ETH per tablet. Max 2 per wallet. On-chain SVG, no IPFS. No middleman.
      </p>

      <hr className="divider" />

      {/* Supply tracker */}
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, fontSize: 13 }}>
          <span>{minted} / {MAX_SUPPLY} minted</span>
          <span className="dim">{(MAX_SUPPLY - minted).toLocaleString()} remaining</span>
        </div>
        <div style={{ width: "100%", height: 6, background: "#1a1a1a", border: "1px solid #33ff3333" }}>
          <div
            style={{
              width: `${progress}%`,
              height: "100%",
              background: "#33ff33",
              transition: "width 0.5s ease",
            }}
          />
        </div>
      </div>

      <hr className="divider" />

      <div style={{ marginBottom: 24 }}>
        <ConnectButton />
      </div>

      {isConnected && (
        <div>
          <hr className="divider" />

          <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 16 }}>
            <label>
              Quantity:{" "}
              <select
                value={qty}
                onChange={(e) => setQty(Number(e.target.value))}
                style={{
                  background: "#0a0a0a",
                  color: "#33ff33",
                  border: "1px solid #33ff33",
                  padding: "4px 8px",
                  fontFamily: "monospace",
                }}
              >
                <option value={1}>1</option>
                <option value={2}>2</option>
              </select>
            </label>
            <span className="dim">{(0.001 * qty).toFixed(3)} ETH + gas</span>
          </div>

          <button className="cta" onClick={mint} disabled={isPending || isConfirming}>
            {isPending
              ? "confirm in wallet…"
              : isConfirming
              ? "minting…"
              : `mint ${qty} tablet${qty > 1 ? "s" : ""}`}
          </button>

          {isSuccess && hash && (
            <p style={{ marginTop: 16 }}>
              ✓ Minted!{" "}
              <a
                href={`https://etherscan.io/tx/${hash}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                view tx →
              </a>
            </p>
          )}

          {error && (
            <p style={{ marginTop: 16, color: "#ff4444" }}>
              Error: {error.message.slice(0, 120)}
            </p>
          )}
        </div>
      )}

      <hr className="divider" />

      <p className="dim" style={{ fontSize: 12 }}>
        Minting calls the contract directly on Ethereum mainnet. No middleman fees.
        <br />
        100% of mint revenue goes to the creator.
        <br />
        Contract:{" "}
        <a
          href={`https://etherscan.io/address/${TOKEN}`}
          target="_blank"
          rel="noopener noreferrer"
        >
          {TOKEN.slice(0, 10)}...{TOKEN.slice(-4)}
        </a>
      </p>
    </main>
  );
}
