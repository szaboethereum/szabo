import { publicClient, szaboAbi, szaboAddress } from "./chain";

export type SzaboMetadata = {
  name: string;
  description: string;
  image: string; // data:image/svg+xml;base64,...
  attributes: Array<{ trait_type: string; value: string | number }>;
};

export type SzaboObject = {
  seed: `0x${string}`;
  birthBlock: bigint;
  originalMinter: `0x${string}`;
};

/// Decode a `data:application/json;base64,...` URI into an object.
export function decodeTokenURI(uri: string): SzaboMetadata {
  const prefix = "data:application/json;base64,";
  if (!uri.startsWith(prefix)) {
    throw new Error("Unexpected tokenURI scheme: " + uri.slice(0, 64));
  }
  const b64 = uri.slice(prefix.length);
  const json = atob(b64);
  return JSON.parse(json) as SzaboMetadata;
}

export async function getCollectionStats() {
  const [name, totalSupply, maxSupply] = await Promise.all([
    publicClient.readContract({ address: szaboAddress, abi: szaboAbi, functionName: "name" }),
    publicClient.readContract({
      address: szaboAddress,
      abi: szaboAbi,
      functionName: "totalSupply",
    }),
    publicClient.readContract({
      address: szaboAddress,
      abi: szaboAbi,
      functionName: "maxSupply",
    }),
  ]);
  return { name, totalSupply, maxSupply };
}

export async function getTokenMetadata(tokenId: bigint): Promise<SzaboMetadata> {
  const uri = await publicClient.readContract({
    address: szaboAddress,
    abi: szaboAbi,
    functionName: "tokenURI",
    args: [tokenId],
  });
  return decodeTokenURI(uri);
}

export async function getTokenOwner(tokenId: bigint): Promise<`0x${string}`> {
  return publicClient.readContract({
    address: szaboAddress,
    abi: szaboAbi,
    functionName: "ownerOf",
    args: [tokenId],
  });
}

export async function getTokenObject(tokenId: bigint): Promise<SzaboObject> {
  const [seed, birthBlock, originalMinter] = await publicClient.readContract({
    address: szaboAddress,
    abi: szaboAbi,
    functionName: "objects",
    args: [tokenId],
  });
  return { seed, birthBlock, originalMinter };
}

export function shortAddress(addr: string): string {
  return addr.slice(0, 6) + "…" + addr.slice(-4);
}
