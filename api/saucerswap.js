/**
 * Vercel Edge API Route: GET /api/saucerswap
 * Proxies SaucerSwap testnet API with caching
 */

export const config = { runtime: "edge" };

const BASE = "https://testnet.saucerswap.finance/api/v1";

export default async function handler(req) {
  const url = new URL(req.url);
  const path = url.searchParams.get("path") ?? "/pools";

  try {
    const upstream = await fetch(`${BASE}${path}`, {
      headers: { Accept: "application/json" },
    });

    const data = await upstream.json();

    return new Response(JSON.stringify(data), {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "s-maxage=30",
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
