/**
 * 闪念AI 后端代理 — Cloudflare Workers / Vercel 通用
 *
 * 部署步骤：
 * 1. 在 Cloudflare Workers 中创建新 Worker，粘贴此文件
 * 2. 设置环境变量 DEEPSEEK_API_KEY = sk-xxx
 * 3. 设置环境变量 APP_TOKEN = shan-nian-ai-2026（可选，默认值）
 * 4. 绑定自定义域名（可选）
 *
 * 部署后把 AIService.swift 中的 proxyURL 改为你的 Worker URL
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname !== '/api/chat') {
      return new Response(JSON.stringify({ error: 'Not Found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const expectedToken = env.APP_TOKEN || 'shan-nian-ai-2026';
    const appToken = request.headers.get('X-App-Token');
    if (appToken !== expectedToken) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const apiKey = env.DEEPSEEK_API_KEY;
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'Server not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    try {
      const body = await request.json();

      const deepseekResp = await fetch('https://api.deepseek.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: body.model || 'deepseek-chat',
          messages: body.messages || [],
          temperature: body.temperature ?? 0.3,
          max_tokens: body.max_tokens || 800,
        }),
      });

      const data = await deepseekResp.json();

      return new Response(JSON.stringify(data), {
        status: deepseekResp.status,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: 'Internal Server Error', detail: e.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  },
};
