# 架构

入口链路：BreatheApp (@main) → AppDelegate（菜单栏图标，左键呼吸面板/右键菜单）→ 三个 WindowController 各自挂 SwiftUI 视图。

## 单例关系

所有单例均为 `@MainActor` + `static let shared`：

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
│   ├── Preset.swift                          # 预设枚举 (morning/midday/evening/night)
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
