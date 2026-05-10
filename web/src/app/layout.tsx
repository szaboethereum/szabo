import Link from "next/link";
import type { Metadata } from "next";
import { Providers } from "./providers";
import "./globals.css";

export const metadata: Metadata = {
  title: "SZABO",
  description:
    "On-chain terminal tablets. 2,000 edition. Named after Nick Szabo — the unit in every Ethereum gas calculation.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <nav>
          <Link href="/">szabo</Link>
          <Link href="/mint">mint</Link>
          <Link href="/explore">explore</Link>
          <Link href="/manifesto">manifesto</Link>
        </nav>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
