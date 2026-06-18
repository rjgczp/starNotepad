import { NextRequest } from "next/server";

const BACKEND_URL = process.env.BLOG_PROFILE_API_URL
  ? process.env.BLOG_PROFILE_API_URL.replace(/\/public\/json-config\/.*$/, "")
  : "http://127.0.0.1:9999/api/v1";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { messages, profile_json } = body;

    // 转发到 fast-soy-admin 后端（流式）
    const resp = await fetch(`${BACKEND_URL}/public/bc-chat/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ messages, profile_json }),
    });

    if (!resp.ok || !resp.body) {
      const errorText = await resp.text();
      return new Response(errorText, { status: resp.status });
    }

    // 创建 ReadableStream 代理 SSE 数据
    const reader = resp.body.getReader();
    const stream = new ReadableStream({
      async start(controller) {
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            controller.enqueue(value);
          }
        } finally {
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch {
    return new Response(
      JSON.stringify({ code: 500, msg: "AI 聊天服务暂时不可用" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}