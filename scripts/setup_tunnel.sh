#!/bin/bash
# Cloudflare Tunnel 和 ws-scrcpy 设置脚本

# 从环境变量读取 token（更安全，不会出现在进程列表中）
CLOUDFLARE_TOKEN="${CLOUDFLARE_TUNNEL_TOKEN}"

if [ -z "$CLOUDFLARE_TOKEN" ]; then
    echo "❌ 错误：未设置 CLOUDFLARE_TUNNEL_TOKEN 环境变量"
    exit 1
fi

echo "🔒 设置远程访问通道..."
echo ""

# 清理可能存在的旧容器
echo "🧹 [1/4] 清理旧容器..."
docker rm -f cloudflared ws-scrcpy > /dev/null 2>&1 || true
echo "✅ 清理完成"
echo ""

# 拉取 Cloudflare Tunnel 镜像
echo "📥 [2/4] 拉取 Cloudflare Tunnel 镜像..."
echo "    镜像: cloudflare/cloudflared:latest"
if docker pull cloudflare/cloudflared:latest 2>&1 | grep -E '(Downloaded|up to date|Already exists)'; then
    echo "✅ 镜像准备完成"
else
    echo "⚠️  镜像拉取可能失败，尝试继续..."
fi
echo ""

# 启动 Cloudflare Tunnel（使用 host 网络模式，避免容器网络隔离问题）
echo "🚀 [3/4] 启动 Cloudflare Tunnel..."
if docker run -d --name cloudflared --network host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token "${CLOUDFLARE_TOKEN}" > /dev/null 2>&1; then
    echo "✅ Cloudflare Tunnel 已启动"
    echo "    容器名: cloudflared"
    echo "    网络模式: host"
else
    echo "❌ Cloudflare Tunnel 启动失败"
    exit 1
fi
echo ""

# 拉取 ws-scrcpy 镜像
echo "📥 [3.5/4] 拉取 ws-scrcpy 镜像..."
echo "    镜像: haris132/ws-scrcpy"
if docker pull haris132/ws-scrcpy 2>&1 | grep -E '(Downloaded|up to date|Already exists)'; then
    echo "✅ 镜像准备完成"
else
    echo "⚠️  镜像拉取可能失败，尝试继续..."
fi
echo ""

# 启动 ws-scrcpy（远程控制）
echo "🚀 [4/4] 启动 ws-scrcpy（远程控制）..."
if docker run --name ws-scrcpy -d --add-host=host.docker.internal:host-gateway -p 8000:8000 haris132/ws-scrcpy > /dev/null 2>&1; then
    echo "✅ ws-scrcpy 已启动"
    echo "    容器名: ws-scrcpy"
    echo "    端口: 8000"
else
    echo "❌ ws-scrcpy 启动失败"
    exit 1
fi
echo ""

# 连接 ADB
echo "🔌 连接 ADB 到容器..."
sleep 2  # 等待容器完全启动
if docker exec ws-scrcpy adb connect host.docker.internal:5555 > /dev/null 2>&1; then
    echo "✅ ADB 连接成功"
else
    echo "⚠️  ADB 连接失败（可能需要稍后重试）"
fi
echo ""

echo "✅ 远程访问通道已建立"
echo ""
echo "📋 容器状态："
docker ps --filter "name=cloudflared" --filter "name=ws-scrcpy" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
