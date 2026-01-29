# SS-Maa

> 基于 [Lyxot/maa-template](https://github.com/Lyxot/maa-template) 魔改

## 使用方法
***如果你担心账号泄露，不要使用！有关账号泄露的问题概不负责，详见注意事项1***
1. Fork 这个仓库或者 Use this template 创建新仓库
2. 修改`.github/workflows/maa.yml`的 [L16](https://github.com/StillSand/SS-Maa/blob/main/.github/workflows/maa.yml#L16)
    | 参数 | 描述 | 选项 |
    | --- | --- | --- |
    | `CLIENT_TYPE` | 客户端版本 | `Official` `Bilibili` |
3. 在仓库的`Settings`-`Secrets and variables`-`Actions`-`Repository secrets`中创建 secret
    | 变量 | 描述 | 说明 |
    | --- | --- | --- |
    | `CONTAINER_ENCRYPTION_KEY` | 容器加密密钥 | 随便填一个字符串，用于加密备份数据 |
    | `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel Token | 到 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) 创建隧道，协议选 HTTP，URL 填 `localhost:8000` |
    | `TELEGRAM_BOT_TOKEN` | Telegram Bot Token | 可选，不需要通知就不填，找 [@BotFather](https://t.me/BotFather) 创建 Bot |
    | `TELEGRAM_CHAT_ID` | Telegram Chat ID | 可选，找 [@userinfobot](https://t.me/userinfobot) 获取你的 Chat ID |
4. 进入仓库的 Actions，选择 MAA，点击 Run workflow，勾选`手动初始化模式`，点击 Run workflow
5. 运行到`🔧 设置远程访问隧道`时，在 log 中找到 Cloudflare Tunnel 的访问地址
6. 浏览器打开这个地址，点击 `H264 Converter` 进行远程控制
7. 打开游戏，下载选择基础资源，不下载语音包，登录账号，设置低画质30帧，关掉退出基建提示，进剿灭页面关掉剿灭的提示
8. 回到 Actions 页面，点击 `Approve` 按钮继续运行，等待 workflow 运行完毕
9. 修改`.config/maa/tasks/daily.toml`，[配置文档](https://github.com/MaaAssistantArknights/maa-cli/blob/main/crates/maa-cli/docs/zh-CN/config.md)，不会改就使用示例即可
10. 进入 Actions，选择 MAA，点击 Run workflow，不勾选任何选项，点击 Run workflow
11. 同步骤6，观察 MAA 是否正常运行
12. 修改`.github/workflows/maa.yml`的 [L11-12](https://github.com/StillSand/SS-Maa/blob/main/.github/workflows/maa.yml#L11-L12) 来配置定时运行，取消注释并按照UTC时区配置，示例中的为每天5点和17点运行
13. 快乐自动化

## 注意事项
1. 账号数据存储在 GitHub Release 中加密备份，通常情况下其他人不能访问数据，请不要将其他人添加为仓库的合作者，也不要泄露你的 `CONTAINER_ENCRYPTION_KEY`，以防账号泄露
2. 游戏会自动更新，配置好后就不需要管了，除非在其它设备上执行了清理会话，或者超过7天没有运行 workflow，需要重新执行步骤4 到步骤8
3. 建议仓库设置为公开仓库，私有仓库的 Actions 有限制，普通用户每月只有 2000 分钟的额度，超出后无法使用 Actions，另外公开仓库的 runner 性能更好，私有仓库可能导致游戏卡顿或崩溃
4. 定时任务不会准时运行，通常在配置时间的 5~20 分钟后开始运行
5. 要使用 Cloudflare Tunnel 才能远程控制登录游戏，有能力的自己改
6. 示例中使用 Telegram Bot 发送通知，不需要的可以不配置 `TELEGRAM_BOT_TOKEN` 和 `TELEGRAM_CHAT_ID`，有能力的可以自己改
7. 如果你自己修改了注意事项 5 或 6，确保你的 token、url 等隐私数据存储在 secrets 中，且无法在任何 commit 中找到其明文
