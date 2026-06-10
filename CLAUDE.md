# Breathe

macOS 呼吸练习应用 —— 基于 [breathe-cli](https://github.com/marekkowalczyk/breathe-cli) 的共振呼吸引导，移植为原生 macOS 应用。

```
  菜单栏图标 → 呼吸面板 → 动画圆环引导 → 完成 → 查看历史
```

## 技术栈

| 层面       | 技术                                                    |
|------------|---------------------------------------------------------|
| 语言       | Swift 5.9+                                              |
| UI 框架    | SwiftUI + AppKit (NSPanel, NSStatusItem)                |
| 项目管理   | XcodeGen (`project.yml`)                                |
| 依赖       | 零外部依赖                                              |
| 音频       | NSSound (Tink/Pop)                                      |
| 通知       | UserNotifications + NSAlert                              |
| 测试       | XCTest                                                  |

## 架构总览

```
                          ┌──────────────┐
                          │  BreatheApp  │  ← @main, SwiftUI App
                          └──────┬───────┘
                                 │ @NSApplicationDelegateAdaptor
                          ┌──────▼───────┐
                          │  AppDelegate │  ← 菜单栏图标 + 左键面板/右键菜单
                          └──────┬───────┘
                                 │
               ┌─────────────────┼─────────────────┐
               │                 │                 │
      ┌────────▼──────┐  ┌──────▼──────┐  ┌───────▼──────┐
      │ Breathing     │  │  Settings   │  │  History     │
      │ Panel WC      │  │  WC         │  │  WC          │
      └────────┬──────┘  └──────┬──────┘  └───────┬──────┘
               │                │                  │
      ┌────────▼──────┐  ┌──────▼──────┐  ┌───────▼──────┐
      │ Breathing     │  │  Settings   │  │  History     │
      │ PanelView     │  │  View       │  │  View        │
      └───────────────┘  └─────────────┘  └──────────────┘
```

## 单例关系

所有单例均为 `@MainActor` + `static let shared`，视图通过 `@ObservedObject` 引用。

```
AppSettingsManager.shared ──── 配置持久化 (~/.config/breathe/settings.json)
    │
    ├── BreathingEngine.shared ──── 呼吸状态机 + Timer (20Hz)
    │       │
    │       ├── AudioManager.shared ──── NSSound 音频提示
    │       └── SessionLogger.shared ──── CSV 会话记录
    │
    ├── BreathingPanelWindowController.shared ── 呼吸面板窗口
    ├── SettingsWindowController.shared ── 设置窗口
    ├── HistoryWindowController.shared ── 历史窗口
    ├── LaunchAtLoginManager.shared ── 开机自启 (macOS 13+)
    └── NotificationManager.shared ── 会话完成 + 每日提醒
```

## 项目结构

```
Sources/App/
├── BreatheApp.swift                          # @main 入口
├── AppDelegate.swift                         # 菜单栏 + 左右键分发 + 引擎回调
│
├── Models/
│   ├── Preset.swift                          # 预设枚举 (balanced/calm/extended)
│   ├── BreathingConfig.swift                 # 会话配置 (比例、时长、取整算术)
│   └── SessionRecord.swift                   # CSV 可记录的会话结果
│
├── Engine/
│   ├── BreathingEngine.swift                 # 核心状态机 (idle/countdown/inhale/exhale/paused)
│   ├── RatioValidator.swift                  # 安全约束 (移植自 breathe-cli)
│   └── TimeOfDay.swift                       # 按时段自动选择预设
│
├── Managers/
│   ├── AppPaths.swift                        # 路径常量 (~/.config/breathe/)
│   ├── AppSettings.swift                     # 配置模型 + Manager (原子写入 + 文件监听)
│   ├── AudioManager.swift                    # NSSound 音频播放
│   ├── SessionLogger.swift                   # CSV 日志 + 旧版导入
│   ├── LaunchAtLoginManager.swift            # SMAppService (macOS 13+)
│   └── NotificationManager.swift             # 会话完成 + 每日提醒通知
│
├── Views/
│   ├── BreathingPanelView.swift              # 呼吸面板主视图
│   ├── BreathingCircle.swift                 # 动画呼吸圆环
│   ├── SettingsView.swift                    # 设置视图 (预设/通用)
│   └── HistoryView.swift                     # 会话历史表格
│
└── WindowControllers/
    ├── BreathingPanelWindowController.swift  # NSPanel 呼吸面板
    ├── SettingsWindowController.swift        # NSWindow 设置窗口
    └── HistoryWindowController.swift         # NSWindow 历史窗口

Tests/
├── RatioValidatorTests.swift                 # 安全验证边界条件
├── PresetTests.swift                         # 预设不变量 (6bpm, 周期≥8s, 整除性)
├── BreathingConfigTests.swift                # 时长取整算术
├── SessionRecordTests.swift                  # CSV 序列化兼容性
├── BreathingEngineTests.swift                # 引擎状态机
├── AppSettingsTests.swift                    # 配置序列化
├── SessionLoggerTests.swift                  # 日志记录
└── TimeOfDayTests.swift                      # 时段预设选择

scripts/
└── update_build_number.sh                    # 自动更新构建号

project.yml                                   # XcodeGen 项目定义
release.sh                                    # 自动化发布
```

## 配置文件

```
~/.config/breathe/
├── settings.json     ← 主配置 (预设/音频/日志/自启/提醒)
└── sessions.csv      ← 会话记录 (与 breathe-cli 格式兼容)
```

## 开发规范

- **单例**: `@MainActor` + `static let shared`，视图用 `@ObservedObject`（非 `@StateObject`）
- **配置写入**: 原子写入 + `isLoaded` 保护 + `skipNextFileChange` 避免重载循环
- **文件监听**: `DispatchSource.makeFileSystemObjectSource`，300ms 防抖
- **面板**: `NSPanel`（无标题栏，floating 级别），会话期间不自动关闭
- **Dock 隐藏**: `LSUIElement = true`
- **引擎**: 20Hz Timer，时间连续性（phaseStartTime = 上一阶段起始 + 时长），暂停时停止 Timer，`isCompleting` 防定格期间双触发
- **安全验证**: 与 breathe-cli 相同的 5 条规则，验证顺序一致

## 构建

```bash
# 生成 Xcode 项目
xcodegen generate

# Debug 构建
xcodebuild -project breathe.xcodeproj \
  -scheme Breathe \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  build

# 运行测试
xcodebuild test -project breathe.xcodeproj \
  -scheme BreatheTests \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-"

# 发布
./release.sh 1.0.0
```
