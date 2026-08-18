# 开发规范

- **单例**: `@MainActor` + `static let shared`，视图用 `@ObservedObject`（非 `@StateObject`）
- **配置写入**: 原子写入 + `isLoaded` 保护 + `skipNextFileChange` 避免重载循环
- **文件监听**: `DispatchSource.makeFileSystemObjectSource`，300ms 防抖
- **面板**: `NSPanel`（无标题栏，floating 级别），会话期间不自动关闭
- **Dock 隐藏**: `LSUIElement = true`
- **引擎**: 20Hz Timer，时间连续性（phaseStartTime = 上一阶段起始 + 时长），暂停时停止 Timer，`isCompleting` 防定格期间双触发
- **安全验证**: 与 breathe-cli 相同的 5 条规则，验证顺序一致
