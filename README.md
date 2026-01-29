# SS-Maa

> 基于 [Lyxot/maa-template](https://github.com/Lyxot/maa-template) 项目进行魔改

## 📖 项目简介

本项目通过 **GitHub Actions** 自动运行 [MAA (MaaAssistantArknights)](https://github.com/MaaAssistantArknights/MaaAssistantArknights)，实现明日方舟游戏的自动化任务执行。

**核心特性：**
- ☁️ 完全基于云端运行，无需本地设备
- 🔄 支持定时自动执行日常任务
- 📱 Telegram 消息通知（可选）

---

## ⚠️ 重要提示

### 仓库可见性建议

**强烈建议使用公开仓库（Public Repository）**

- ✅ **公开仓库**：GitHub Actions 性能充足，运行稳定
- ⚠️ **私有仓库**：性能受限，可能导致以下问题：
  - 游戏运行卡顿
  - 模拟器响应缓慢
  - MAA 识别超时
  - 任务执行失败或闪退

### 安全风险警告

**请务必谨慎配置和使用本项目：**

- 🔐 **配置不当可能导致敏感信息泄露**（账号密码、Token 等）
- 🚫 **切勿将他人添加为仓库协作者**
- 🚫 **切勿在公开场合分享配置信息**
- 🚫 **切勿将 Secrets 硬编码到代码中**
- ⚠️ **公开仓库的 Actions 日志任何人都可以查看**（虽已做隐私保护，但无法保证 100% 安全）

### 免责声明

- 本项目**仅供学习交流使用**
- 使用本项目可能**违反游戏服务条款**，可能导致**账号被封禁**
- 使用者需**自行承担一切风险和后果**
- 作者**不对任何直接或间接损失负责**
- 如果你不能接受这些风险，**请不要使用本项目**

**使用本项目即表示你已完全理解并接受上述所有风险。**

---

## 📁 项目结构

```
maa/
├── .github/
│   └── workflows/
│       └── maa.yml              # GitHub Actions 工作流配置
├── .config/
│   └── maa/
│       ├── cli.toml             # MAA CLI 配置
│       ├── profiles/
│       │   └── default.toml     # 默认配置文件
│       └── tasks/
│           └── daily.toml       # 日常任务配置
├── scripts/                     # 自动化脚本目录
│   ├── prepare_env.sh           # 环境准备
│   ├── setup_container.sh       # 容器设置
│   ├── install_maa.sh           # MAA 安装
│   ├── install_game.sh          # 游戏安装
│   ├── setup_tunnel.sh          # 远程访问设置
│   ├── backup_to_release.sh     # 容器备份
│   ├── restore_from_release.sh  # 容器恢复
│   └── ...                      # 其他辅助脚本
├── run.py                       # MAA 运行脚本
├── send_msg.py                  # 消息发送脚本
├── download.py                  # 资源下载脚本
├── format_summary.py            # 日志格式化脚本
├── docker-compose.yml           # Docker 容器编排
├── SETUP.md                     # 详细配置指南
└── README.md                    # 本文件
```

---

## 🚀 快速开始

### 前置要求

1. GitHub 账号
2. Cloudflare 账号（用于远程访问）
3. Telegram Bot（可选，用于接收通知）
4. 明日方舟游戏账号

### 配置步骤

**详细配置过程请查看：[📖 SETUP.md](./SETUP.md)**

配置步骤概览：

1. **配置 Cloudflare Tunnel** - 创建隧道并获取 Token
2. **配置 Telegram Bot**（可选）- 创建 Bot 并获取 Token 和 Chat ID
3. **配置 GitHub Secrets** - 添加必需的密钥信息
4. **修改 Workflow 配置** - 设置时区、服务器类型和域名
5. **首次手动初始化** - 登录游戏并完成初始设置
6. **配置自动化任务** - 编辑任务配置文件

---

## 📝 使用说明

### 手动运行

1. 进入仓库的 **Actions** 页面
2. 选择 **MAA** workflow
3. 点击 **Run workflow**
4. 点击绿色的 **Run workflow** 按钮

### 定时自动运行

编辑 `.github/workflows/maa.yml` 文件，取消注释并修改定时配置：

```yaml
schedule:
  - cron: '0* * *'  # 每天 UTC 8:00 和 20:00（北京时间 16:00 和 04:00）
```

### 任务配置

编辑 `.config/maa/tasks/daily.toml` 文件来配置你想要执行的任务。

**配置文档：** [MAA CLI 配置说明](https://github.com/MaaAssistantArknights/maa-cli/blob/main/crates/maa-cli/docs/zh-CN/config.md)

---

## 🔧 技术栈

- **GitHub Actions** - CI/CD 平台，提供免费计算资源
- **Docker** - 容器化技术
- **Redroid** - Android 容器模拟器
- **MAA (MaaAssistantArknights)** - 明日方舟游戏助手
- **Cloudflare Tunnel** - 安全的远程访问隧道
- **ws-scrcpy** - Web 端 Android 远程控制
- **Telegram Bot** - 消息通知服务

---

## 📚 相关链接

- [原始项目 (maa-template)](https://github.com/Lyxot/maa-template)
- [MAA 官方项目](https://github.com/MaaAssistantArknights/MaaAssistantArknights)
- [MAA CLI 文档](https://github.com/MaaAssistantArknights/maa-cli)
- [详细配置指南 (SETUP.md)](./SETUP.md)

---

## 📄 许可证

本项目采用 [GNU General Public License v3.0 (GPL-3.0)](./LICENSE) 许可证。

---

## ⚖️ 法律声明

- 请遵守当地法律法规和游戏服务条款
- 使用本项目的一切法律责任由使用者自行承担
- 如果你所在地区法律禁止使用此类工具，请不要使用

---

**⚠️ 再次提醒：使用本项目需要一定的技术能力和风险意识，请谨慎使用！**
