# 架构

入口链路：BreatheApp (@main) → AppDelegate（菜单栏图标，左右键均打开菜单）→ 三个 WindowController 各自挂 SwiftUI 视图。

## 原生界面

界面以 `designs/breathe/` 原型为基础，使用 SwiftUI/AppKit；呼吸球和历史页采用后续确认的调整（固定读秒、可展开记录详情）。原型外层的场景导航、桌面背景和演示标签不属于应用界面。

- 窗口：设置与历史使用隐藏系统标题栏与交通灯的自定义窗口（`BreatheWindow` + `fullSizeContentView`），系统红黄绿按钮隐藏，`BreatheWindowTitlebar` 绘制标题、品牌和交通灯。`BreatheHostingView` 把 `safeAreaInsets` 置零，避免系统标题栏把内容下推 32pt；`BreatheTrafficLightMonitor` 在事件派发前接管 47pt 标题栏：三个圆点执行窗口动作，其余区域拖动或双击缩放。窗口强制浅色外观以匹配设计稿调色板。
- 设置：默认 540×640，最小 540×560；顶部为 `≋`/通用分类，内容可滚动。预设摘要复用 `BreathingConfig`，自动模式每分钟刷新时段；时段映射只在自动模式显示，并给当前时段加“当前”标记，固定预设时隐藏；自定义比例使用文本输入，直接展示周期、实际时长与原有安全校验反馈，无效时隐藏摘要。
- 历史记录：默认 860×560，最小 860×540；自定义表头与行，默认显示日期与时间、预设、实际时长和状态（“已完成”或“提前结束”）。点击记录或聚焦后按空格展开/收起详情，查看吸气/呼气比例、目标时长、呼吸次数与完成比例；CSV 格式不变。用户可调整窗口大小，刷新记录时保持当前尺寸。空状态隐藏表头，仍可刷新和导入旧日志。原型中的“演示数据”徽标不进入原生界面，数据来自本地 CSV。
- 原型专用元素：演示数据徽标、通用页演示开关脚注和浏览器上海时区不进入原生界面；原生使用本地 CSV 和系统时间，时段图标使用同字重、同字号的 SF Symbols（sunrise、sun.max、sunset、moon），网页原型用对应的线形 SVG 预览。
- 菜单：`BreatheMenuController` 用 260pt 自定义面板替代 NSMenu，锚定状态栏按钮，包含品牌头部、动态开始/暂停、预设内联子菜单、静音与窗口入口；点击面板外、切换到其他应用或按 Esc 关闭。⌘B/⌘H/⌘,/⌘Q 由隐藏主菜单分发，Space/S 在面板显示时由事件监听处理。
- 状态栏：使用设计稿的系统字体 `≋` 字形（29pt）生成模板图标，按 Core Text 的实际字形边界在 20pt 图像内居中；会话中在图标后显示等宽剩余时间，文字通过系统状态栏按钮默认绘制，随按钮实际外观及高亮变化，不指定固定绿色或白色。菜单品牌与设置预设标签分别使用同一字形的 24pt、18pt 字号，不用手绘曲线替代。
- 声音状态以 `AppSettings.soundEnabled` 为准。`AudioManager` 持续订阅配置（包括启动与文件重载）；菜单静音通过同一配置入口更新并保存，设置开关和音频状态即时同步。音频测试注入内存配置流，避免操作真实配置文件。
- 颜色与字体：`BreatheStyle` 使用中性浅灰窗口与表头、深黑主文字，绿色用于开关和功能状态背景；设置辅助文字、历史时间与状态标签为 12pt，“当前”标签为 11pt，当前时段名称加粗。菜单栏倒计时的系统外观适配不改变设置和历史窗口的浅色外观；呼吸球使用设计稿的绿色吸气、橙红色呼气、蓝色倒计时与琥珀色暂停，尺寸 240、球体 200、文字 36；仅球体缩放，读秒与暂停符号保持固定大小，不显示阶段文字。

原生验证：设置页检查预设、自定义有效/无效、通用开关与日志路径；历史页检查折叠/展开详情（鼠标和键盘）、空状态、刷新与导入；菜单检查空闲/会话中、预设展开、静音与退出；呼吸球检查四种阶段颜色、最小/最大球体下固定大小的读秒、暂停符号与拖动。此类布局修改使用构建、业务测试及离屏渲染截图检查，不使用视图结构快照作为业务测试。

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
