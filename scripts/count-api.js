/**
 * count-api.js — Vercel Edge Function for page view counting
 * Uses Upstash Redis for serverless-compatible persistence.
 *
 * Deploy: Place in /api/count.js (or /api/count/route.js for App Router)
 *
 * Setup:
 *   1. Create a free Upstash Redis database at https://console.upstash.com
 *   2. Add environment variables to Vercel:
 *      UPSTASH_REDIS_REST_URL=https://xxxxx.upstash.io
 *      UPSTASH_REDIS_REST_TOKEN=AXxxxxxxxxxxxxxx
 *   3. Deploy this file as /api/count.js
 *
 * Usage:
 *   GET  /api/count?page=/blog/my-post         → {"page":"/blog/my-post","views":42}
 *   POST /api/count?page=/blog/my-post         → increments view count, returns new count
 *   GET  /api/count?page=/blog/my-post&top=10  → top 10 most-viewed pages
 *
 * Client-side usage:
 *   fetch('/api/count?page=' + encodeURIComponent(window.location.pathname), { method: 'POST' })
 *     .then(r => r.json())
 *     .then(d => console.log('Views:', d.views))
 */

export const config = {
  runtime: "edge",
};

const REDIS_URL = process.env.UPSTASH_REDIS_REST_URL;
const REDIS_TOKEN = process.env.UPSTASH_REDIS_REST_TOKEN;

/**
 * Execute a Redis command via Upstash REST API
 * @param {string[]} command - Redis command array e.g. ["INCR", "key"]
 * @returns {Promise<any>} Redis response result
 */
async function redis(command) {
  if (!REDIS_URL || !REDIS_TOKEN) {
    throw new Error("Missing UPSTASH_REDIS_REST_URL or UPSTASH_REDIS_REST_TOKEN env vars");
  }

  const response = await fetch(`${REDIS_URL}/${command.join("/")}`, {
    headers: {
      Authorization: `Bearer ${REDIS_TOKEN}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Redis error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  return data.result;
}

/**
 * Sanitize and validate page path
 * @param {string|null} page
 * @returns {string|null}
 */
function sanitizePage(page) {
  if (!page) return null;

  // Must start with /
  if (!page.startsWith("/")) page = "/" + page;

  // Remove query strings and fragments
  page = page.split("?")[0].split("#")[0];

  // Limit length
  if (page.length > 200) return null;

  // Allow only safe characters
  if (!/^[a-zA-Z0-9\-_./]+$/.test(page)) return null;

  return page;
}

/**
 * CORS headers for cross-origin requests
 */
function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
  };
}

/**
 * Main Edge Function handler
 */
export default async function handler(request) {
  const { searchParams } = new URL(request.url);
  const origin = request.headers.get("origin");

  // Handle CORS preflight
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(origin),
    });
  }

  // Validate Redis config
  if (!REDIS_URL || !REDIS_TOKEN) {
    return new Response(
      JSON.stringify({
        error: "Redis not configured. Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN.",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
      }
    );
  }

  // GET /api/count?top=10 — return top N pages
  const topParam = searchParams.get("top");
  if (request.method === "GET" && topParam) {
    const limit = Math.min(parseInt(topParam, 10) || 10, 100);
    try {
      // Use sorted set: ZREVRANGE pageviews:sorted 0 N WITHSCORES
      const results = await redis(["ZREVRANGE", "pageviews:sorted", "0", String(limit - 1), "WITHSCORES"]);

      const pages = [];
      if (Array.isArray(results)) {
        for (let i = 0; i < results.length; i += 2) {
          pages.push({ page: results[i], views: parseInt(results[i + 1], 10) });
        }
      }

      return new Response(JSON.stringify({ pages, limit }), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-cache",
          ...corsHeaders(origin),
        },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
      });
    }
  }

  // GET or POST /api/count?page=/path
  const rawPage = searchParams.get("page");
  const page = sanitizePage(rawPage);

  if (!page) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid ?page= parameter. Must start with / and use safe characters." }),
      {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
      }
    );
  }

  const key = `pageviews:${page}`;

  try {
    let views;

    if (request.method === "POST") {
      // Increment counter (hash for O(1) per page, sorted set for rankings)
      views = await redis(["INCR", key]);

      // Update sorted set for leaderboard queries
      await redis(["ZADD", "pageviews:sorted", String(views), page]);

      return new Response(JSON.stringify({ page, views }), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-cache",
          ...corsHeaders(origin),
        },
      });
    } else {
      // GET — read current count
      const raw = await redis(["GET", key]);
      views = raw ? parseInt(raw, 10) : 0;

      return new Response(JSON.stringify({ page, views }), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "public, max-age=60, stale-while-revalidate=600",
          ...corsHeaders(origin),
        },
      });
    }
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders(origin) },
    });
  }
}
