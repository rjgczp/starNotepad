import { NextRequest } from "next/server";

const BACKEND_URL = process.env.BACKEND_URL || "http://127.0.0.1:8888";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { messages } = body;

    const resp = await fetch(`${BACKEND_URL}/api/bc/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ messages }),
      signal: req.signal,
      cache: "no-store",
    });

    if (!resp.ok) {
      const errorText = await resp.text();
      return new Response(errorText || JSON.stringify({ code: 500, msg: "AI 聊天服务暂时不可用" }), {
        status: resp.status || 500,
        headers: { "Content-Type": resp.headers.get("Content-Type") || "application/json" },
      });
    }


    // Go 后端返回 SSE；直接透传响应流，避免将流式内容误当 JSON 解析。
    return new Response(resp.body, {
      status: resp.status,
      headers: {
        "Content-Type": resp.headers.get("Content-Type") || "text/event-stream",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no",
      },
    });
  } catch {
    return new Response(
      JSON.stringify({ code: 500, msg: "AI 聊天服务暂时不可用" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}
