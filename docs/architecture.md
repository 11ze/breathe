# 架构

入口链路：BreatheApp (@main) → AppDelegate（菜单栏图标，左右键均打开菜单）→ 三个 WindowController 各自挂 SwiftUI 视图。

## 原生界面

界面按 `designs/breathe/` 原型一比一实现，使用 SwiftUI/AppKit。原型外层的场景导航、桌面背景和演示标签不属于应用界面。

- 窗口：设置与历史使用隐藏系统标题栏与交通灯的自定义窗口（`BreatheWindow` + `fullSizeContentView`），系统红黄绿按钮隐藏，`BreatheWindowTitlebar` 绘制标题、品牌和交通灯。`BreatheHostingView` 把 `safeAreaInsets` 置零，避免系统标题栏把内容下推 32pt；`BreatheTrafficLightMonitor` 在事件派发前接管 47pt 标题栏：三个圆点执行窗口动作，其余区域拖动或双击缩放。窗口强制浅色外观以匹配设计稿调色板。
- 设置：默认 540×640，最小 540×560；顶部为 `≋`/通用分类，内容可滚动。预设摘要复用 `BreathingConfig`，自动模式每分钟刷新时段；时段映射只在自动模式显示，并给当前时段加“当前”标记，固定预设时隐藏；自定义比例使用文本输入，直接展示周期、实际时长与原有安全校验反馈，无效时隐藏摘要。
- 历史记录：默认 860×560，最小 860×540；自定义表头与行，保留全部 CSV 字段，状态显示“已完成”或“提前结束”。空状态隐藏表头，仍可刷新和导入旧日志。原型中的“演示数据”徽标不进入原生界面，数据来自本地 CSV。
- 原型专用元素：演示数据徽标、通用页演示开关脚注、浏览器上海时区和 Unicode 字形不进入原生界面；原生使用本地 CSV、系统时间和 SF Symbols。
- 菜单：`BreatheMenuController` 用 260pt 自定义面板替代 NSMenu，锚定状态栏按钮，包含品牌头部、动态开始/暂停、预设内联子菜单、静音与窗口入口；点击面板外、切换到其他应用或按 Esc 关闭。⌘B/⌘H/⌘,/⌘Q 由隐藏主菜单分发，Space/S 在面板显示时由事件监听处理。
- 状态栏：自绘 `≋` 模板图标；会话中在图标后显示绿色等宽剩余时间。
- 声音状态以 `AppSettings.soundEnabled` 为准。`AudioManager` 持续订阅配置（包括启动与文件重载）；菜单静音通过同一配置入口更新并保存，设置开关和音频状态即时同步。音频测试注入内存配置流，避免操作真实配置文件。
- 颜色与字体：`BreatheStyle` 固定设计稿的浅色调色板、边框和分组表面；呼吸球使用设计稿的绿色吸气、橙红色呼气、蓝色倒计时与琥珀色暂停，尺寸 240、球体 200、文字 36。

原生验证：设置页检查预设、自定义有效/无效、通用开关与日志路径；历史页检查表格、空状态、刷新与导入；菜单检查空闲/会话中、预设展开、静音与退出；呼吸球检查四种阶段颜色、暂停符号与拖动。此类布局修改使用构建、业务测试及离屏渲染截图检查，不使用视图结构快照作为业务测试。

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
    ├── BreatheMenuController.shared ── 状态栏菜单面板
    ├── BreathingPanelWindowController.shared ── 呼吸面板窗口
    ├── SettingsWindowController.shared ── 设置窗口
    ├── HistoryWindowController.shared ── 历史窗口
    ├── LaunchAtLoginManager.shared ── 开机自启 (macOS 13+)
    └── NotificationManager.shared ── 会话完成通知
```

## 项目结构

```
Sources/App/
├── BreatheApp.swift                          # @main 入口
├── AppDelegate.swift                         # 菜单栏 + 左右键分发 + 引擎回调
│
├── Models/
│   ├── Preset.swift                          # 预设枚举（内部 ID 英文，界面显示中文）
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
│   └── NotificationManager.swift             # 会话完成通知
│
├── Views/
│   ├── BreatheDesign.swift                   # 设计令牌、标题栏与通用控件
│   ├── BreatheMenuView.swift                 # 状态栏菜单内容
│   ├── BreathingPanelView.swift              # 呼吸面板主视图
│   ├── BreathingCircle.swift                 # 动画呼吸圆环
│   ├── SettingsView.swift                    # 设置视图 (预设/通用)
│   └── HistoryView.swift                     # 会话历史自定义表格
│
└── WindowControllers/
    ├── BreatheWindow.swift                   # 自定义窗口与交通灯点击接管
    ├── BreatheMenuController.swift           # 自定义状态栏菜单面板
    ├── BreathingPanelWindowController.swift  # NSPanel 呼吸面板
    ├── SettingsWindowController.swift        # BreatheWindow 设置窗口
    └── HistoryWindowController.swift         # BreatheWindow 历史窗口

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
