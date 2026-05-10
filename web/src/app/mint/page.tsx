"use client";

import Link from "next/link";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseEther } from "viem";
import { useState } from "react";

// V2 contract deployed on mainnet
const TOKEN = "0x24E5b6c4E31dfe50da1f449d1a4D19d521250938" as const;
const MINT_PRICE = parseEther("0.001");

const mintAbi = [
  {
    type: "function",
    name: "mint",
    stateMutability: "payable",
    inputs: [{ name: "quantity", type: "uint256" }],
    outputs: [],
  },
] as const;

export default function MintPage() {
  const { address, isConnected } = useAccount();
  const [qty, setQty] = useState(1);

  const { data: hash, writeContract, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const contractReady = TOKEN !== "0x0000000000000000000000000000000000000000";

  function mint() {
    if (!address || !contractReady) return;
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

      <div style={{ marginBottom: 24 }}>
        <ConnectButton />
      </div>

      {isConnected && (
        <div>
          <hr className="divider" />

          {!contractReady ? (
            <p className="dim">Mint contract not yet deployed. Coming soon.</p>
          ) : (
            <>
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
            </>
          )}
        </div>
      )}

      <hr className="divider" />

      <p className="dim" style={{ fontSize: 12 }}>
        Minting calls the contract directly on Ethereum mainnet. No middleman fees.
        <br />
        100% of mint revenue goes to the creator.
      </p>
    </main>
  );
}
