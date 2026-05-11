import { createPublicClient, http } from "viem";
import { mainnet, sepolia } from "viem/chains";

const chainName = process.env.NEXT_PUBLIC_CHAIN ?? "mainnet";
const rpcUrl = process.env.NEXT_PUBLIC_RPC_URL;

export const chain = chainName === "mainnet" ? mainnet : sepolia;

export const publicClient = createPublicClient({
  chain,
  transport: http(rpcUrl),
});

export const szaboAddress = (process.env.NEXT_PUBLIC_SZABO_ADDRESS ??
  "0x24E5b6c4E31dfe50da1f449d1a4D19d521250938") as `0x${string}`;

export const openseaSlug = process.env.NEXT_PUBLIC_OPENSEA_SLUG ?? "";

/// Minimal ABI — only the views we use.
export const szaboAbi = [
  {
    type: "function",
    name: "name",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "string" }],
  },
  {
    type: "function",
    name: "symbol",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "string" }],
  },
  {
    type: "function",
    name: "maxSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },
  {
    type: "function",
    name: "totalSupply",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },
  {
    type: "function",
    name: "tokenURI",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ type: "string" }],
  },
  {
    type: "function",
    name: "ownerOf",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [{ type: "address" }],
  },
  {
    type: "function",
    name: "objects",
    stateMutability: "view",
    inputs: [{ name: "tokenId", type: "uint256" }],
    outputs: [
      { name: "seed", type: "bytes32" },
      { name: "birthBlock", type: "uint256" },
      { name: "originalMinter", type: "address" },
    ],
  },
] as const;
