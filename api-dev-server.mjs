/**
 * Local dev API server — mirrors Vercel edge routes for local testing
 * Run: node api-dev-server.mjs
 * Vite proxies /api/* to http://localhost:3001
 */

import { createServer } from "http";
import { readFileSync } from "fs";
import { Readable } from "stream";

// Load env from .env.deploy
try {
  const envRaw = readFileSync(".env.deploy", "utf8");
  for (const line of envRaw.split("\n")) {
    const m = line.match(/^([^#=\s][^=]*)=(.*)$/);
    if (m) process.env[m[1].trim()] = m[2].trim();
  }
} catch {}

process.env.HEDERA_PRIVATE_KEY ??= process.env.DEPLOY_PRIVATE_KEY;

if (process.env.GEMINI_API_KEY) console.log("✓ GEMINI_API_KEY set");
else console.log("⚠ GEMINI_API_KEY not set — agents will use fallback text");

async function pipeResponse(res, nodeRes) {
  const status = res.status ?? 200;
  const headers = { "Access-Control-Allow-Origin": "*" };
  if (res.headers) {
    for (const [k, v] of res.headers.entries()) headers[k] = v;
  }
  nodeRes.writeHead(status, headers);

  if (!res.body) { nodeRes.end(); return; }

  // Native ReadableStream (Node 22) → pipe to http response
  const reader = res.body.getReader();
  const push = async () => {
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) { nodeRes.end(); break; }
        nodeRes.write(Buffer.from(value));
      }
    } catch (e) {
      nodeRes.end();
    }
  };
  push();
}

async function routeRequest(path, nodeReq, nodeRes) {
  const url = `http://localhost:3001${path}`;

  const body = await new Promise((resolve) => {
    const chunks = [];
    nodeReq.on("data", (d) => chunks.push(d));
    nodeReq.on("end", () => resolve(Buffer.concat(chunks).toString() || undefined));
  });

  let handler;
  const route = path.split("?")[0];
  try {
    if (route === "/api/quest") handler = (await import("./api/quest.js?t=" + Date.now())).default;
    else if (route === "/api/stream") handler = (await import("./api/stream.js?t=" + Date.now())).default;
    else if (route === "/api/hedera") handler = (await import("./api/hedera.js?t=" + Date.now())).default;
    else if (route === "/api/saucerswap") handler = (await import("./api/saucerswap.js?t=" + Date.now())).default;
    else if (route === "/api/store-receipt") handler = (await import("./api/store-receipt.js?t=" + Date.now())).default;
    else { nodeRes.writeHead(404); nodeRes.end("Not found"); return; }
  } catch (e) {
    console.error("Import error:", e.message);
    nodeRes.writeHead(500); nodeRes.end(e.message); return;
  }

  const reqHeaders = {};
  nodeReq.rawHeaders.forEach((v, i) => { if (i % 2 === 0) reqHeaders[v.toLowerCase()] = nodeReq.rawHeaders[i + 1]; });

  const req = new Request(url, {
    method: nodeReq.method,
    headers: reqHeaders,
    body: body && nodeReq.method !== "GET" && nodeReq.method !== "HEAD" ? body : undefined,
  });

  try {
    const res = await handler(req);
    await pipeResponse(res, nodeRes);
  } catch (e) {
    console.error("Handler error:", e.message);
    if (!nodeRes.headersSent) { nodeRes.writeHead(500); nodeRes.end(e.message); }
  }
}

const server = createServer(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    });
    res.end();
    return;
  }
  console.log(`[api] ${req.method} ${req.url}`);
  try {
    await routeRequest(req.url, req, res);
  } catch (e) {
    if (!res.headersSent) { res.writeHead(500); res.end(e.message); }
  }
});

server.listen(3001, () => {
  console.log("✓ API dev server on http://localhost:3001");
});
