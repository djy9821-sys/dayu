# Dayu

一个只给自己用的 iPhone App：旧的自动行为链启动时，帮我切换到新路径；失控之后，帮我快速止损、回到主线。

设计思路、数据模型和路线图见 [DESIGN.md](DESIGN.md)。

- SwiftUI + SwiftData，iOS 17+，只做 iPhone
- 没有任何第三方依赖
- 所有记录只存在手机上：没有账号、没有服务器、不连 iCloud

## 当前进度：M0 + M1

| 已完成 | 内容 |
|---|---|
| M0 骨架 | 本地数据库、Face ID / 密码锁（后台超过 1 分钟回来重新上锁）、切后台遮挡画面、今天 / 趋势 / 我的 三个页面 |
| M1 冲动流程 | 首页大按钮 → 步骤页 → 计时（可锁屏，到点通知）→ 结束打分（亲眼看到冲动回落）→ 15 秒记录 → 止损页或"记录完成"；补记；7 天概览和全部记录；边界设置；删除全部数据 |

下一步是 M2：晨间打卡、运动、晚间小结、Night Mode 和定时提醒。

## 装到 iPhone 上

第一次大约 20 分钟，之后每次更新只需要点一下运行。

1. **装 Xcode**：在 Mac 的 App Store 搜索 Xcode，免费下载（文件很大，需要一些时间）。装好后打开一次，按提示安装组件。
2. **拿到代码**：在 GitHub 打开这个仓库，点绿色的 **Code → Download ZIP**，解压。
   用过 git 的话也可以：`git clone https://github.com/djy9821-sys/dayu.git`
3. **打开项目**：双击 `Dayu.xcodeproj`。
4. **登录 Apple ID**：Xcode 菜单 **Xcode → Settings → Accounts**，点左下角 **+** 添加你的 Apple ID。
5. **选签名**：左侧点最上面的 **Dayu** 项目 → 中间选 **Dayu** target → **Signing & Capabilities** → **Team** 选你的 Apple ID（Personal Team）。
   如果提示 Bundle Identifier 不可用，把 `com.djy9821.dayu` 改成别的，例如 `com.jackson.dayu.app`。
6. **连接 iPhone**：用数据线连 Mac，手机上点"信任此电脑"。
   第一次还要在 iPhone 打开 **设置 → 隐私与安全性 → 开发者模式**，按提示重启。
7. **运行**：Xcode 顶部选择你的 iPhone，点左上角 ▶︎。
8. **信任证书**（只需第一次）：iPhone **设置 → 通用 → VPN 与设备管理**，信任你的开发者 App。

### 关于有效期

- **免费 Apple ID**：装好后 7 天有效。到期后连上 Mac 再点一次 ▶︎ 就行，记录不会丢。
- **Apple Developer Program（$99/年）**：一年有效，也可以通过 TestFlight 安装，不用连电脑。

## 项目结构

```
Dayu/
  DayuApp.swift          入口：本地数据库（不连 iCloud）、通知
  Core/                  纯逻辑，只依赖 Foundation，有自动检查
    Vocabulary.swift     河道上的步骤、触发标签、地点
    LocalTime.swift      按事发当地时间计算"今天""深夜"
    Boundaries.swift     三圈模型的内圈
    EmergencyDraft.swift 进行中的冲动流程、止损页规则
    WeekSummary.swift    7 天概览
    Copy.swift           App 里所有的话
  Model/UrgeEvent.swift  记录（SwiftData）
  Services/              全屏流程、通知、锁、设置
  UI/                    页面
  Debug/DemoMode.swift   仅开发版：截图用的演示数据
Tests/CoreChecks/        核心逻辑检查
```

## 自动检查

每次推送到 `main`，GitHub Actions 会在云端 Mac 上：

1. 运行核心逻辑检查（`Tests/CoreChecks`）；
2. 编译模拟器版（Debug）和真机版（Release）；
3. 在模拟器里逐页截图，截图在每次运行的 **Artifacts → screenshots** 里。

本地也可以跑核心检查：

```bash
swiftc Dayu/Core/*.swift Tests/CoreChecks/main.swift -o /tmp/corechecks && /tmp/corechecks
```

开发时可以用启动参数直接打开某一页（只在 Debug 版有效，用内存里的演示数据）：
Xcode → Product → Scheme → Edit Scheme → Run → Arguments，添加 `-uiDemo timer`。
可选值：`today` `today-timer` `steps` `timer` `done` `log` `backfill` `stop` `stop-services` `saved` `trends` `me`。

## 隐私

- 记录只存在这台手机上，App 不联网。
- 打开 App 需要 Face ID 或手机密码（可在"我的"里关闭）。
- 切到后台时画面被遮住，多任务界面看不到内容。
- 通知文案永远是中性的（例如"时间到了。"），锁屏上看不出用途。
- 桌面图标和名称是中性的。
- "我的 → 删除全部数据"可以清空所有记录。
- 这个仓库里只有代码，不含任何个人数据。
