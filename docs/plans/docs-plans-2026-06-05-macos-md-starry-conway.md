# Breathe 实施计划评审与实施指南

## Context

基于 `docs/plans/2026-06-05-macOS菜单栏呼吸练习应用.md` 的完整设计文档，结合对以下三者的深度探索：

1. **breathe 项目现状**：完全空白，仅有设计文档
2. **menu-bar-executor 参考**：21 个 Swift 文件 + 7 个测试文件，架构模式成熟
3. **breathe-cli 源码**（v1.9）：Python 单文件，所有行为细节已确认

本文件是对原计划的**评审 + 补充**，不是替代。原计划的架构、文件结构、实现顺序都经过了验证，直接采用。这里只记录发现的问题和补充。

---

## 评审结论：通过 ✅

原计划质量很高，架构选择合理，文件映射准确，实现顺序具备独立性。以下是发现的需要修正/补充的点。

---

## 发现的问题与补充

### 1. 项目未初始化 Git（遗漏）

原计划 Phase 1 未提及 `git init`。当前目录不是 git 仓库。

**补充**：Phase 1 第一步执行 `git init`，创建 `.gitignore`，做首次提交。

### 2. 暂停恢复的边界条件（遗漏）

原计划正确记录了「暂停恢复回到 INHALE 起始点」，但遗漏了一个边界条件：

> 如果暂停时 `breathingBase >= duration_s`（即当前呼吸周期已经完成全部时长），恢复时应直接完成会话，而不是重新开始吸气。

**来源**：breathe-cli `run_session()` 中 resume 后的检查：
```python
if breathingBase >= config.duration_s:
    # render final frame, sleep 0.4s, completed = True, break
```

**处理**：在 `BreathingEngine.resume()` 中加入此检查。

### 3. 会话完成的 0.4s 视觉停顿（遗漏）

breathe-cli 在最后一次呼气完成后，会额外停顿 0.4 秒再显示完成状态，给用户一个「定格」的视觉反馈。

**处理**：`BreathingEngine` 在检测到 `breathingBase >= duration_s` 后，延迟 0.4 秒再切换到 `.idle` 并播放完成通知。用 `DispatchQueue.main.asyncAfter(deadline: .now() + 0.4)` 实现。

### 4. `NotificationManager.swift` 缺少核心文件设计

原计划项目结构中列出了 `NotificationManager.swift`，但「核心文件设计」部分没有对应章节。

**处理**：补充简要设计：
- 使用 `UNUserNotificationCenter` 发送两种通知
- 会话完成通知：「呼吸练习完成！完成了 X 个呼吸周期」
- 每日提醒通知：在用户设定时间触发，使用 `UNCalendarNotificationTrigger`
- 需在 `AppDelegate.applicationDidFinishLaunching` 中请求通知权限

### 5. `TimeOfDay.swift` 缺少核心文件设计

同上，项目结构中列出但未设计。

**处理**：这是一个简单工具：
```swift
enum TimeOfDay {
    case morning    // 06:00-11:59 → balanced
    case afternoon  // 12:00-17:59 → extended
    case evening    // 18:00-21:59 → calm
    case night      // 22:00-05:59 → calm (避免高强度)
    
    static func current() -> TimeOfDay { ... }
    var recommendedPreset: Preset { ... }
}
```

### 6. 图标素材的具体方案（模糊）

Phase 1 说「准备菜单栏图标素材」但没有具体方案。

**推荐方案**：
- 菜单栏图标：16x16 template 图标（简洁的呼吸/风/波浪符号）
- 用 SF Symbols 作为起点（macOS 12+ 内置），比如 `wind` 或 `leaf.fill`
- AppIcon：1024x1024，可用脚本从 SVG 生成（复用 menu-bar-executor 的 `generate_appicon.py`）
- 如果不想用 SF Symbols，用 `NSImage(systemSymbolName:accessibilityDescription:)` 作为 fallback

### 7. RatioValidator 验证顺序（精确性）

原计划列出了全部 5 条规则，但未指定顺序。breathe-cli 的 `parse_ratio()` 对「三段比例」的拒绝（如 `4-7-8`）在「格式错误」之前。

**处理**：Swift 版保持相同顺序，先检查段数 > 2（屏息警告），再检查段数 != 2（格式错误），这样 `4-7-8` 会得到更友好的错误提示。

---

## 关键复用文件清单

从 menu-bar-executor 直接复制/修改的文件：

| 目标文件 | 参考源文件 | 修改程度 |
|----------|-----------|---------|
| `project.yml` | `menu-bar-executor/project.yml` | 去掉 KeyboardShortcuts 依赖，改 bundle ID |
| `Resources/Info.plist` | `menu-bar-executor/Resources/Info.plist` | 改版本号和 bundle ID |
| `.gitignore` | `menu-bar-executor/.gitignore` | 几乎不变 |
| `BreatheApp.swift` | `Sources/App/MenuBarExecutorApp.swift` | 几乎一致 |
| `AppDelegate.swift` | `Sources/App/AppDelegate.swift` | 改菜单结构+左键行为 |
| `AppPaths.swift` | `Sources/App/AppPaths.swift` | 改路径为 `~/.config/breathe/` |
| `AppSettings.swift` | `Sources/App/AppSettings.swift` | 改字段，保留原子写入+文件监听 |
| `BreathingPanelWC.swift` | `Sources/App/CommandPaletteWindowController.swift` | 改关闭行为（不自动关闭） |
| `SettingsWindowController.swift` | `Sources/App/SettingsWindowController.swift` | 高度复用 |
| `HistoryWindowController.swift` | `Sources/App/HistoryWindowController.swift` | 高度复用 |
| `LaunchAtLoginManager.swift` | `Sources/App/LaunchAtLoginManager.swift` | 直接复用 |
| `NotificationManager.swift` | `Sources/App/NotificationManager.swift` | 中度修改（改通知内容） |
| `release.sh` | `menu-bar-executor/release.sh` | 改项目名 |
| `scripts/update_build_number.sh` | `menu-bar-executor/scripts/update_build_number.sh` | 直接复用 |

---

## 实施顺序（沿用原计划，加入补充项）

### Phase 1：基础骨架
1. `git init` + `.gitignore`
2. `project.yml` + `Resources/Info.plist`
3. `BreatheApp.swift` + `AppDelegate.swift`（最小化，仅图标+空菜单）
4. `AppPaths.swift`
5. 菜单栏图标（SF Symbol 或 template image）
6. `xcodegen generate` + `xcodebuild build` 验证

**验证**：菜单栏出现图标，右键显示空菜单。

### Phase 2：模型 + 安全验证
7. `Preset.swift`
8. `BreathingConfig.swift`（含时长取整算术）
9. `RatioValidator.swift`（保持与 breathe-cli 相同的验证顺序）
10. `SessionRecord.swift`
11. 对应单元测试

**验证**：`xcodebuild test` 全部通过。

### Phase 3：呼吸引擎
12. `BreathingEngine.swift`（含 0.4s 完成停顿 + 暂停恢复边界条件）
13. `AudioManager.swift`（NSSound，Tink/Pop，音量 0.3）
14. `BreathingEngineTests.swift`

**验证**：引擎测试通过（剩余时间单调递减、周期对齐、暂停恢复、边界条件）。

### Phase 4：配置持久化
15. `AppSettings.swift`（复用原子写入 + 文件监听 + isLoaded）
16. `SessionLogger.swift`（CSV 格式与 breathe-cli 兼容）
17. 测试

**验证**：配置序列化/反序列化 + CSV 兼容性测试通过。

### Phase 5：UI 视图
18. `BreathingCircle.swift`（动画圆环）
19. `BreathingPanelView.swift`（呼吸面板）
20. `SettingsView.swift`
21. `HistoryView.swift`

**验证**：各视图可独立预览。

### Phase 6：窗口管理 + 集成
22. `BreathingPanelWindowController.swift`（NSPanel，会话期间不自动关闭）
23. `SettingsWindowController.swift` + `HistoryWindowController.swift`
24. `TimeOfDay.swift`
25. `NotificationManager.swift`（请求权限 + 两种通知）
26. `LaunchAtLoginManager.swift`
27. `AppDelegate.swift` 完善（完整菜单、预设子菜单、状态联动）

**验证**：完整交互流程可用。

### Phase 7：收尾
28. AppIcon
29. `release.sh` + `scripts/update_build_number.sh`
30. `CLAUDE.md` + `README.md`

**验证**：端到端测试 + CSV 导出兼容 breathe-cli。

---

## 最脆弱假设

> **此计划假设 macOS 12.0 的 SwiftUI API 足以实现所需的动画效果。** 如果 `scaleEffect` + `.animation(.linear)` 在 20Hz 更新下出现卡顿，可能需要降级到 `NSView` + `CoreAnimation` 的 `CAShapeLayer` 方案。这个风险较低但值得在 Phase 5 验证。

---

## 未列出但需要的依赖

| 依赖 | 用途 | 获取方式 |
|------|------|---------|
| XcodeGen | 从 `project.yml` 生成 `.xcodeproj` | `brew install xcodegen` |
| 图标素材 | 菜单栏 template 图 + AppIcon | SF Symbols 或自定义 SVG |

无外部 Swift 包依赖。零依赖是明确的设计目标。
