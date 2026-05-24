#!/bin/bash
set -e

echo "🚀 一闪AI 上架脚本"
echo "===================="
echo ""

# ── Step 1: GitHub SSH Key ──
echo "📦 Step 1/3: 添加 GitHub SSH 公钥"
echo "----------------------------------------"
echo "公钥内容："
cat ~/.ssh/id_ed25519_shanian.pub
echo ""
echo "👉 打开 https://github.com/settings/ssh/new"
echo "   Title 随便填（如 MacBook），Key 粘贴上面这行"
echo "   点 Add SSH Key"
echo ""
read -p "完成后按回车继续..." _

# ── Step 2: Push to GitHub ──
echo ""
echo "📤 Step 2/3: 推送代码到 GitHub"
echo "----------------------------------------"
cd "/Users/jhllol/Documents/New project"
git push origin main
echo "✅ 代码已推送到 GitHub"

# ── Step 3: Deploy Cloudflare Worker ──
echo ""
echo "☁️  Step 3/3: 部署 Cloudflare Worker"
echo "----------------------------------------"
cd "/Users/jhllol/Documents/New project/ShanNianAI/api"

if ! wrangler whoami &>/dev/null; then
    echo "🔐 需要登录 Cloudflare..."
    wrangler login
fi

echo "🚀 部署 Worker..."
wrangler deploy

echo ""
echo "===================="
echo "🎉 全部完成！"
echo ""
echo "Vercel  API: https://shanian-9921r5nrh-chenxiangyun-s-projects.vercel.app/api/chat"
echo "GitHub  Repo: https://github.com/chengxiangyun194-jpg/ShanNianAI"
echo ""
echo "📱 App Store 上架: Xcode 打开项目 → Product → Archive → Distribute App"
