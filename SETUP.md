# MAA 自动化配置指南

本文档提供详细的配置步骤和故障排查指南。

---

## 📋 目录

- [前置要求](#前置要求)
- [配置步骤](#配置步骤)
  - [1. 配置 Cloudflare Tunnel](#1-配置-cloudflare-tunnel)
  - [2. 配置 Telegram Bot](#2-配置-telegram-bot)
  - [3. 配置 GitHub Secrets](#3-配置-github-secrets)
  - [4. 修改 Workflow 配置](#4-修改-workflow-配置)
  - [5. 首次手动初始化](#5-首次手动初始化)
  - [6. 配置自动化任务](#6-配置自动化任务)
- [常见问题](#常见问题)
- [故障排查](#故障排查)

---

## 前置要求

1. **GitHub 账号**
2. **Cloudflare 账号**（用于远程访问）
3. **Telegram Bot**（可选，用于接收通知）
4. **明日方舟游戏账号**

---

## 配置步骤

### 1. 配置 Cloudflare Tunnel

#### 1.1 创建 Cloudflare Tunnel

1. 访问 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. 登录你的 Cloudflare 账号
3. 左侧菜单：**Access** → **Tunnels**
4. 点击 **Create a tunnel**
5. 选择 **Cloudflared**
6. 输入 Tunnel 名称（如：`maa-tunnel`）
7. 点击 **Save tunnel**

#### 1.2 配置 Public Hostname

1. 在 Tunnel 配置页面，找到 **Public Hostname**
2. 点击 **Add a public hostname**
3. 填写配置：
   ```
   Subdomain:  maa（或你喜欢的名字）
   Domain:     选择你的域名
   Path:       留空
   
   Service:
     Type:     HTTP
     URL:      localhost:8000
   ```
   
   **⚠️ 重要：**
   - Type 必须是 `HTTP`（不是 HTTPS）
   - URL 必须是 `localhost:8000`（不要加 `http://` 前缀）
   - Path 必须留空

4. 点击 **Save hostname**

#### 1.3 获取 Tunnel Token

1. 在 Tunnel 详情页面，找到 **Install and run a connector**
2. 你会看到类似这样的命令：
   ```bash
   cloudflared tunnel run --token eyJhIjoixxxxxxxx...
   ```
3. **复制 `eyJhIjoixxxxxxxx...` 这部分**（就是 Token）

#### 1.4 记住你的访问域名

你的访问地址是：`https://[subdomain].[domain]`

例如：`https://maa.yourdomain.com`

---

### 2. 配置 Telegram Bot

#### 2.1 创建 Telegram Bot

1. 在 Telegram 中搜索 [@BotFather](https://t.me/BotFather)
2. 发送 `/newbot` 创建新 Bot
3. 按提示设置 Bot 名称
4. 复制 Bot Token（格式：`1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`）

#### 2.2 获取 Chat ID

1. 在 Telegram 中搜索 [@userinfobot](https://t.me/userinfobot)
2. 发送任意消息
3. 复制你的 Chat ID（纯数字）

---

### 3. 配置 GitHub Secrets 和 Variables

#### 3.1 配置 Secrets

1. 打开你的 GitHub 仓库
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **Secrets** 标签页
4. 点击 **New repository secret**，添加以下 Secrets：

| Name | Value | 说明 |
|------|-------|------|
| `CLOUDFLARE_TUNNEL_TOKEN` | `eyJhIjoixxxxxxxx...` | Cloudflare Tunnel Token（必需） |
| `CONTAINER_ENCRYPTION_KEY` | `MyS3cur3P@ssw0rd!2024` | 容器加密密码（必需，建议20+字符） |
| `TELEGRAM_BOT_TOKEN` | `1234567890:ABCdefGHI...` | Telegram Bot Token（可选） |
| `TELEGRAM_CHAT_ID` | `123456789` | Telegram Chat ID（可选） |

**重要说明：**
- `CONTAINER_ENCRYPTION_KEY`：用于加密容器快照，存储在 GitHub Release 中
- 容器快照会自动分卷上传（每个分卷最大 1900MB）
- 系统会自动清理旧的快照，只保留最新的

#### 3.2 配置 Variables

1. 在同一页面，点击 **Variables** 标签页
2. 点击 **New repository variable**，添加以下 Variable：

| Name | Value | 说明 |
|------|-------|------|
| `SEND_MSG` | `true` 或 `false` | 是否发送 Telegram 通知（可选，默认不发送） |

**说明：**
- 如果不设置 `SEND_MSG` 变量，默认**不会发送**任何 Telegram 通知
- 设置为 `true` 才会发送通知（需要同时配置 `TELEGRAM_BOT_TOKEN` 和 `TELEGRAM_CHAT_ID`）
- 设置为 `false` 或不设置，则不发送通知

#### 3.3 配置 Environment（可选但推荐）

1. 在仓库设置中，点击 **Environments**
2. 点击 **New environment**
3. 输入名称：`production`
4. 点击 **Configure environment**
5. 可以配置保护规则（可选）

**说明：**
- 工作流使用 `production` environment
- 如果不创建，工作流仍可运行，但建议创建以便更好地管理

---

### 4. 修改 Workflow 配置

编辑 `.github/workflows/maa.yml` 文件：

```yaml
env:
  TZ: Asia/Shanghai        # 时区设置
  CLIENT_TYPE: Official    # 官服用 Official，B服用 Bilibili
```

**配置说明：**
- `TZ`：时区设置，默认为 `Asia/Shanghai`（北京时间）
- `CLIENT_TYPE`：游戏服务器类型
  - `Official`：官服
  - `Bilibili`：B服

**注意：**
- 工作流使用 `ubuntu-24.04-arm` 运行环境（ARM 架构）
- MAA 运行超时时间为 7200 秒（2 小时）
- 如需启用 Telegram 通知，请在仓库设置中添加 `SEND_MSG` 变量并设为 `true`

---

### 5. 首次手动初始化

#### 5.1 启动 Workflow

1. 进入仓库的 **Actions** 页面
2. 选择 **MAA** workflow
3. 点击 **Run workflow**
4. ✅ **勾选 `manual_setup`**（手动初始化模式）
5. 点击绿色的 **Run workflow** 按钮

**说明：**
- `manual_setup` 选项用于首次使用或重新登录游戏
- 勾选后会启动 SSH 调试会话，超时时间为 60 分钟
- 等待手动设置的超时时间为 240 分钟（4 小时）

#### 5.2 连接 SSH

1. 等待 Telegram 消息（或查看 GitHub Actions 日志）
2. 找到 SSH 连接命令（格式：`ssh xxx@xxx.tmate.io`）
3. 在你的电脑终端执行该命令
4. 连接成功后按 `q` 键进入终端
5. 保持 SSH 连接，等待下一步

**说明：**
- SSH 会话使用 `mxschmitt/action-tmate@v3`
- 会话为 detached 模式，不限制访问者
- 如果配置了 Telegram，SSH 信息会通过 Telegram 发送

#### 5.3 登录游戏

1. 收到 Telegram 的"准备登录游戏"消息
2. 打开浏览器，访问你的 Cloudflare Tunnel 域名
3. 点击 **H264 Converter** 按钮
4. 你会看到 Android 模拟器界面
5. 在浏览器中操作：
   - 打开明日方舟游戏
   - 下载**基础资源**（不要下载语音包）
   - 登录你的游戏账号
   - 进入游戏设置：
     - 画质：**低画质**
     - 帧率：**30 帧**
     - 关闭"退出基建提示"
   - 进入剿灭页面，关掉剿灭的新手提示

#### 5.4 完成初始化

1. 回到 SSH 终端
2. 执行命令：
   ```bash
   create_flag && exit
   ```
3. SSH 连接会断开
4. Workflow 会自动保存容器状态
5. 等待完成（约 5-10 分钟）

---

### 6. 配置自动化任务

编辑 `.config/maa/tasks/daily.toml` 文件，配置你想要执行的任务。

**配置文档：** [MAA CLI 配置说明](https://github.com/MaaAssistantArknights/maa-cli/blob/main/crates/maa-cli/docs/zh-CN/config.md)

**配置文件说明：**

- **`.config/maa/cli.toml`**：MAA CLI 全局配置
  - `channel`：更新渠道（Beta/Stable）
  - `auto_update`：是否自动更新资源

- **`.config/maa/profiles/default.toml`**：连接配置
  - `address`：ADB 连接地址（默认 `127.0.0.1:5555`）
  - `touch_mode`：触控模式（默认 `MaaTouch`）

- **`.config/maa/tasks/daily.toml`**：日常任务配置
  - 定义要执行的任务列表
  - 可配置公招、战斗、基建、商店等任务
  - 支持条件变体（如周一执行剿灭）

**示例任务配置：**
```toml
[[tasks]]
name = "开始唤醒"
type = "StartUp"
params = { client_type = "Official", start_game_enabled = true }

[[tasks]]
name = "公开招募"
type = "Recruit"
params = { refresh = true, select = [1, 3, 4, 5], confirm = [1, 3, 4, 5], times = 4 }

[[tasks]]
name = "基建换班"
type = "Infrast"
params = { mode = 0, facility = ["Office", "Mfg", "Trade", "Control", "Power", "Reception", "Dorm"] }
```

---

## 常见问题

### Q: 502 Bad Gateway 错误

**A:** Cloudflare Tunnel 配置问题，确保：
- Service Type 是 `HTTP`
- Service URL 是 `localhost:8000`（不要加前缀）
- 等待 1-2 分钟让服务完全启动

### Q: SSH 连接信息没有显示

**A:** 
- 查看 GitHub Actions 日志中的 "Setup Debug Session" 步骤
- SSH 地址会在日志中显示
- 也会通过 Telegram 发送（如果配置了）

### Q: 游戏登录后无法保存

**A:** 
- 确保在 SSH 终端执行了 `create_flag && exit`
- 检查 workflow 是否超时（60 分钟）

### Q: 定时任务没有运行

**A:** 
- GitHub Actions 的定时任务有延迟
- 通常延迟 5-20 分钟
- 可以手动触发测试

### Q: MAA 执行超时

**A:**
- MAA 默认超时时间为 7200 秒（2 小时）
- 如果超过此时间没有新的日志输出，任务会被自动终止
- 可能原因：游戏卡住、MAA 遇到无法识别的界面
- 解决方法：检查游戏设置、查看日志、手动重新初始化

### Q: 容器恢复失败

**A:**
- 检查 `CONTAINER_ENCRYPTION_KEY` 是否正确
- 确认 GitHub Release 中有快照文件
- 首次使用需要先手动初始化，不能直接恢复

---

## 故障排查

### 检查配置状态

工作流会在开始时自动检查配置状态，查看 GitHub Actions 日志中的"检查配置状态"步骤：

```
📋 环境配置检查
🌍 环境变量：
  TZ: Asia/Shanghai
  CLIENT_TYPE: Official
🔐 Secrets 配置状态：
  ✅ CONTAINER_ENCRYPTION_KEY: 已配置
  ✅ CLOUDFLARE_TUNNEL_TOKEN: 已配置
  ✅ TELEGRAM_BOT_TOKEN: 已配置
  ✅ TELEGRAM_CHAT_ID: 已配置
📊 Variables 配置状态：
  SEND_MSG: true
```

### 检查容器状态

在 SSH 终端执行：

```bash
docker ps
```

应该看到 3 个容器在运行：
- `cloudflared`（Cloudflare Tunnel）
- `ws-scrcpy`（远程控制）
- `redroid`（Android 模拟器）

### 检查 ws-scrcpy 服务

```bash
curl -I http://localhost:8000
```

应该返回 `HTTP/1.1 200 OK`

### 检查 cloudflared 日志

```bash
docker logs cloudflared | tail -30
```

查看是否有错误信息。

### 检查 ADB 连接

```bash
docker exec ws-scrcpy adb devices
```

应该看到设备列表。

### 查看 MAA 日志

MAA 运行日志会自动上传到 GitHub Artifacts：

1. 进入 **Actions** → 选择对应的运行记录
2. 在页面底部找到 **Artifacts**
3. 下载 `log` 文件
4. 解压后查看 `asst.log`

### 容器备份恢复问题

**容器快照存储：**
- 存储位置：GitHub Release（tag 格式：`snapshot-YYYYMMDD-HHMM`）
- 加密方式：使用 `CONTAINER_ENCRYPTION_KEY` 加密
- 分卷大小：每个分卷最大 1900MB
- 自动清理：保留最新快照，自动删除旧快照

**恢复失败排查：**
1. 检查 `CONTAINER_ENCRYPTION_KEY` 是否配置正确
2. 查看 GitHub Release 中是否有快照文件
3. 检查网络连接是否正常
4. 查看 Actions 日志中的"恢复容器"步骤

---

## 日常使用

### 手动运行

1. 进入 **Actions** → **MAA** → **Run workflow**
2. **不勾选** `manual_setup`（自动运行模式）
3. 点击 **Run workflow**

**说明：**
- 自动运行模式会从 GitHub Release 恢复容器快照
- 运行完成后会自动保存容器状态
- 如果 MAA 执行超过 2 小时无响应，会自动终止

### 定时自动运行

编辑 `.github/workflows/maa.yml` 的定时配置：

```yaml
schedule:
  - cron: '0 8,20 * * *'  # 每天 UTC 8:00 和 20:00（北京时间 16:00 和 04:00）
```

**Cron 表达式说明：**
- 格式：`分 时 日 月 周`
- `0 8,20 * * *`：每天 8:00 和 20:00（UTC 时间）
- `0 */6 * * *`：每 6 小时运行一次
- `30 2 * * *`：每天 2:30（UTC 时间）

**注意：**
- GitHub Actions 的定时任务基于 UTC 时间
- 北京时间 = UTC + 8
- 定时任务可能有 5-20 分钟的延迟

---

## 重新初始化

如果需要重新登录游戏（例如清理了会话或超过 7 天未运行）：

1. 进入 **Actions** → **MAA** → **Run workflow**
2. ✅ **勾选 `Update manually`**
3. 重复首次初始化的步骤

---

## 技术支持

如有问题，请查看：
- [MAA 官方文档](https://maa.plus/)
- [maa-cli 文档](https://github.com/MaaAssistantArknights/maa-cli)
- GitHub Issues
