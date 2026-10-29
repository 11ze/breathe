# 开发规范

- **单例**: `@MainActor` + `static let shared`，视图用 `@ObservedObject`（非 `@StateObject`）
- **配置写入**: 原子写入 + `isLoaded` 保护 + `skipNextFileChange` 避免重载循环
- **文件监听**: `DispatchSource.makeFileSystemObjectSource`，300ms 防抖
- **面板**: `NSPanel`（无标题栏，floating 级别），会话期间不自动关闭；拖动靠 `DraggableHostingView` 的 `mouseDown` 直接 `performDrag`（新版 macOS 对 HostingView 面板的背景拖动判定已失效，不能只靠 `isMovableByWindowBackground`）；同时覆盖 `acceptsFirstMouse` 返回 `true`，否则焦点在其他窗口时第一次按下只用于激活窗口、不进入拖拽
- **Dock 隐藏**: `LSUIElement = true`
- **窗口**: 设置/历史用 `BreatheWindow`（`canBecomeKey`/`canBecomeMain` 为 true）加 `.titled + .fullSizeContentView`，隐藏系统交通灯；`BreatheHostingView` 将 `safeAreaInsets` 置零，内容才能铺满整窗。标题栏由 `BreatheTrafficLightMonitor` 在事件派发前接管：三个圆点执行关闭/最小化/缩放，其余区域拖动或双击缩放
- **菜单面板**: 自定义 `NSPanel`（`.borderless + .nonactivatingPanel`）承载 SwiftUI 菜单；显示时激活应用并高亮状态栏按钮，点击外部、应用失活或 Esc 关闭
- **引擎**: 20Hz Timer，时间连续性（phaseStartTime = 上一阶段起始 + 时长），暂停时停止 Timer，`isCompleting` 防定格期间双触发
- **安全验证**: 与 breathe-cli 相同的规则，验证顺序一致（禁止屏息、周期≥8秒、吸气 3~10 秒、呼气 3~10 秒）
