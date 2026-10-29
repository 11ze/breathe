# 🌬️ Breathe

自用 macOS 呼吸练习应用，基于科学验证的共振呼吸（Resonance Breathing）方法。

## 什么是共振呼吸？

共振呼吸以每分钟 **6 次** 的频率引导呼吸，通过激活迷走神经（vagal tone）来：
- 降低心率和血压
- 减少焦虑和压力
- 提高专注力和情绪调节能力

> 科学依据：6 次/分钟的呼吸频率能最大化心率变异性（HRV），是自主神经系统训练的最佳频率。

## 功能

- 🫁 **四种预设**：morning (5-5, 10分钟)、midday (4-6, 20分钟)、evening (4-6, 15分钟)、night (3-7, 20分钟)，全部 6.0 bpm
- 🕐 **按时段自动选择**：早晨 morning、下午 midday、傍晚 evening、夜间 night
- ⭕ **动画呼吸圆环**：吸气膨胀（绿色）、呼气收缩（橙红色），桌面浮动球支持拖动
- **原生界面**：分组设置、预设摘要、会话历史表格，跟随系统明暗模式
- 🔊 **音频提示**：系统音效引导呼吸节奏，设置中的声音开关与菜单静音即时同步并保存
- 📊 **会话记录**：CSV 格式，与 [breathe-cli](https://github.com/marekkowalczyk/breathe-cli) 兼容
- 🚀 **开机自启**：macOS 13+ 原生支持

## 截图

*待补充*

## 安装

### 下载

从 [Releases](../../releases) 下载最新版本，解压后拖入「应用程序」文件夹。

### 从源码构建

```bash
# 需要安装 XcodeGen
brew install xcodegen

# 克隆并构建
git clone https://github.com/user/breathe.git
cd breathe
xcodegen generate
# 构建到 /tmp 而非 ./build：项目位于 iCloud 同步路径下，
# iCloud 注入的扩展属性会导致 codesign 失败（见 release.sh 同理）。
xcodebuild -project breathe.xcodeproj -scheme Breathe -configuration Release \
  -derivedDataPath /tmp/breathe-build build
```

## 使用

1. 启动后菜单栏出现风图标 🌬️
2. **左键或右键**点击图标打开菜单
3. 选择「开始呼吸」或使用菜单快捷键 `⌘B` 开始，桌面出现呼吸球
4. 跟随圆环动画和音频提示呼吸
5. 从菜单打开「设置…」调整预设，或打开「历史记录」查看会话

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘B` | 开始/停止呼吸 |
| `Space` | 暂停/继续 |
| `S` | 静音切换 |
| `⌘H` | 历史记录 |
| `⌘,` | 设置 |
| `⌘Q` | 退出 |

## 安全约束

应用对自定义呼吸比例有严格的安全限制（移植自 breathe-cli）：

| 规则 | 约束 |
|------|------|
| 禁止屏息 | 拒绝三段比例如 4-7-8 |
| 禁止快速呼吸 | 总周期 ≥ 8 秒 |
| 吸气范围 | 3~10 秒 |
| 呼气范围 | 3~10 秒 |

## 数据存储

```
~/.config/breathe/
├── settings.json     # 应用配置
└── sessions.csv      # 会话记录（与 breathe-cli 兼容）
```

## 致谢

- [breathe-cli](https://github.com/marekkowalczyk/breathe-cli) — 原始 CLI 工具，呼吸算术和安全规则的来源

## 许可

MIT License
