import Link from "next/link";

export default function TokenPage() {
  return (
    <main>
      <p>
        <Link href="/explore">← explore</Link>
      </p>
      <h1>Token Detail</h1>
      <p className="dim">
        Token detail pages will be available after the new contract is deployed.
      </p>
    </main>
  );
}
