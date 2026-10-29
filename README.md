# Breathe

macOS 菜单栏呼吸练习应用。开始练习后，跟随桌面浮动球和声音提示吸气、呼气。

[下载](https://github.com/11ze/breathe/releases/latest) · [原型预览](https://11ze.github.io/breathe/)

在线原型使用演示数据，不读取本地配置或日志，也不更改系统设置。

- 四种按时段选择的预设，每分钟 6 次呼吸，支持自定义吸呼比例与练习时长。
- 可拖动的呼吸球，绿色吸气、橙红色呼气，支持暂停与继续。
- 声音开关与菜单静音同步，会话记录保存为与 breathe-cli 兼容的 CSV。
- 按设计稿复刻的浅色原生界面，支持开机自启（macOS 13+）。

macOS 12.0+ · SwiftUI + AppKit · 无外部依赖

## 安装与使用

1. 从 [Releases](https://github.com/11ze/breathe/releases/latest) 下载并解压，将 `Breathe.app` 拖入应用程序文件夹。
2. 打开应用；若被系统拦截，在系统设置的“隐私与安全性”中允许打开。启动后点击菜单栏图标，选择“开始呼吸”。
3. 跟随呼吸球练习；通过菜单暂停、继续、停止或切换静音。
4. 从菜单打开“设置…”调整预设，或打开“历史记录”查看会话。

菜单提供开始/停止、静音、历史、设置与退出的快捷键，以菜单显示为准。

## 自定义练习

内置预设为晨间（5-5，10 分钟）、午间（4-6，20 分钟）、晚间（4-6，15 分钟）、深夜（3-7，20 分钟）。自动模式按当前时段选择。配置和 CSV 中仍使用 morning / midday / evening / night 作为内部 ID。

自定义吸气和呼气各为 3 至 10 秒，总周期至少 8 秒，练习时长为 1 至 60 分钟。不支持屏息；实际时长向上取整到完整呼吸周期。

配置位于 `~/.config/breathe/settings.json`，会话记录位于 `~/.config/breathe/sessions.csv`。

## 从源码构建

需要 Xcode 15.0+ 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

```bash
git clone https://github.com/11ze/breathe.git
cd breathe
brew install xcodegen
xcodegen generate
xcodebuild -project breathe.xcodeproj \
  -scheme Breathe \
  -configuration Release \
  -derivedDataPath /tmp/breathe-build \
  CODE_SIGN_IDENTITY="-" build
open /tmp/breathe-build/Build/Products/Release/Breathe.app
```

派生数据放在 `/tmp`，避免 iCloud 同步目录的扩展属性导致签名失败。修改 `project.yml` 或增删源文件后需重新运行 `xcodegen generate`。

运行测试：

```bash
xcodebuild test -project breathe.xcodeproj \
  -scheme BreatheTests \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/breathe-build \
  CODE_SIGN_IDENTITY="-"
```

开发约定见[开发规范](docs/conventions.md)与[架构说明](docs/architecture.md)。原型的本地预览和 Pages 发布方式见[设计说明](designs/breathe/README.md#在线预览与发布)。

## 致谢

[breathe-cli](https://github.com/marekkowalczyk/breathe-cli) 提供了原始呼吸预设、安全规则和会话记录格式。

## 许可

MIT License
