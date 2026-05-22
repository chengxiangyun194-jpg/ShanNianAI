// Vercel Serverless Function — AI 代理
// 部署后 App 请求此端点，服务端持有 API Key 转发到 DeepSeek/OpenAI

const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const MODEL = process.env.AI_MODEL || "deepseek-chat";
const API_KEY = process.env.DEEPSEEK_API_KEY || process.env.OPENAI_API_KEY || "";
const APP_TOKEN = process.env.APP_TOKEN || "shan-nian-ai-2026";

export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-App-Token");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  // 轻量鉴权：防止裸奔被滥用
  const token = req.headers["x-app-token"];
  if (!token || token !== APP_TOKEN) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // 限频：单 IP 每秒最多 5 次
  const ip = req.headers["x-forwarded-for"] || req.socket.remoteAddress;
  if (!rateLimit(ip)) {
    return res.status(429).json({ error: "Too many requests" });
  }

  try {
    const body = req.body;

    // 强制使用服务端配置的模型，忽略客户端传来的
    body.model = MODEL;

    const response = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${API_KEY}`,
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Upstream error:", data);
      return res.status(response.status).json({
        error: "AI 服务暂时不可用，请稍后重试",
        detail: data.error?.message || "Unknown",
      });
    }

    return res.status(200).json(data);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(500).json({ error: "服务内部错误" });
  }
}

// 简易内存限频（Vercel 冷启动会重置，对轻度使用足够）
const rateLimitMap = new Map();
function rateLimit(ip) {
  const now = Date.now();
  const window = rateLimitMap.get(ip) || [];
  const recent = window.filter((t) => now - t < 1000);
  rateLimitMap.set(ip, recent);
  if (recent.length >= 5) return false;
  recent.push(now);
  return true;
}
