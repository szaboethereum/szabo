import Link from "next/link";

export const metadata = {
  title: "SZABO — explore",
};

export default function ExplorePage() {
  return (
    <main>
      <p>
        <Link href="/">← home</Link>
      </p>
      <h1>Explore</h1>
      <p className="dim">
        Collection explorer will be available after mint opens. Each tablet's
        on-chain SVG, traits, and patina level will be viewable here.
      </p>
    </main>
  );
}
