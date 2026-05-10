"use client";

import Link from "next/link";
import {
  useAccount,
  useConnect,
  useDisconnect,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { parseEther } from "viem";
import { useState } from "react";

const SEADROP = "0x00005EA00Ac477B1030CE78506496e8C2dE24bf5" as const;
const TOKEN = "0x571C58ad432Aaed18d81fCA7f4b55Bb4bd32280a" as const;
const FEE_RECIPIENT = "0x0000a26b00c1F0DF003000390027140000fAa719" as const;
const MINT_PRICE = parseEther("0.001");

const seaDropAbi = [
  {
    type: "function",
    name: "mintPublic",
    stateMutability: "payable",
    inputs: [
      { name: "nftContract", type: "address" },
      { name: "feeRecipient", type: "address" },
      { name: "minterIfNotPayer", type: "address" },
      { name: "quantity", type: "uint256" },
    ],
    outputs: [],
  },
] as const;

export default function MintPage() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const [qty, setQty] = useState(1);

  const { data: hash, writeContract, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  function mint() {
    if (!address) return;
    writeContract({
      address: SEADROP,
      abi: seaDropAbi,
      functionName: "mintPublic",
      args: [TOKEN, FEE_RECIPIENT, address, BigInt(qty)],
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
        0.001 ETH per tablet. Max 2 per wallet. On-chain SVG, no IPFS.
      </p>

      <hr className="divider" />

      {!isConnected ? (
        <div>
          <p>Connect your wallet to mint.</p>
          {connectors.map((c) => (
            <button
              key={c.id}
              className="cta"
              onClick={() => connect({ connector: c })}
              style={{ marginRight: 8, marginBottom: 8 }}
            >
              {c.name}
            </button>
          ))}
        </div>
      ) : (
        <div>
          <p>
            Connected: <code>{address?.slice(0, 6)}…{address?.slice(-4)}</code>{" "}
            <button onClick={() => disconnect()} style={{ opacity: 0.5, cursor: "pointer", background: "none", border: "none", color: "inherit", textDecoration: "underline" }}>
              disconnect
            </button>
          </p>

          <hr className="divider" />

          <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 16 }}>
            <label>
              Quantity:{" "}
              <select
                value={qty}
                onChange={(e) => setQty(Number(e.target.value))}
                style={{ background: "#0a0a0a", color: "#33ff33", border: "1px solid #33ff33", padding: "4px 8px", fontFamily: "monospace" }}
              >
                <option value={1}>1</option>
                <option value={2}>2</option>
              </select>
            </label>
            <span className="dim">{(0.001 * qty).toFixed(3)} ETH + gas</span>
          </div>

          <button
            className="cta"
            onClick={mint}
            disabled={isPending || isConfirming}
          >
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
        Minting calls SeaDrop.mintPublic directly on Ethereum mainnet.
        <br />
        Contract:{" "}
        <a
          href={`https://etherscan.io/address/${TOKEN}`}
          target="_blank"
          rel="noopener noreferrer"
        >
          {TOKEN.slice(0, 10)}…
        </a>
      </p>
    </main>
  );
}
