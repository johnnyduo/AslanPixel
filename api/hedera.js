/**
 * Vercel Edge API Route: GET /api/hedera
 * Proxies Hedera Mirror Node (testnet)
 */

export const config = { runtime: "edge" };

const MIRROR = "https://testnet.mirrornode.hedera.com";

export default async function handler(req) {
  const url = new URL(req.url);
  const path = url.searchParams.get("path") ?? "/api/v1/network/exchangerate";

  try {
    const upstream = await fetch(`${MIRROR}${path}`, {
      headers: { Accept: "application/json" },
    });
    const data = await upstream.json();

    return new Response(JSON.stringify(data), {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "s-maxage=15",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
