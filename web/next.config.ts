import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // The tokenURI image is a base64 data URI — no external images, no
  // <Image> optimization needed.
  images: { unoptimized: true },
};

export default nextConfig;
