# Breathe

macOS 呼吸练习应用 —— 基于 [breathe-cli](https://github.com/marekkowalczyk/breathe-cli) 的共振呼吸引导，移植为原生 macOS 菜单栏应用。

技术：Swift + SwiftUI/AppKit，XcodeGen 管理项目（`project.yml`），零外部依赖。

## 构建与测试

```bash
# 生成 Xcode 项目（改动 project.yml 或增删源文件后需要）
xcodegen generate

# Debug 构建
# 注意：构建到 /tmp 而非 ./build，因为项目位于 iCloud 同步路径下，
# iCloud 注入的扩展属性会导致 codesign 失败（见 release.sh 同理）。
xcodebuild -project breathe.xcodeproj \
  -scheme Breathe \
  -configuration Debug \
  -derivedDataPath /tmp/breathe-build \
  CODE_SIGN_IDENTITY="-" \
  build

# 运行测试
xcodebuild test -project breathe.xcodeproj \
  -scheme BreatheTests \
  -configuration Debug \
  -derivedDataPath /tmp/breathe-build \
  CODE_SIGN_IDENTITY="-"

# 本地打包自测（不上传）
./release.sh 1.3.4
```

发版：改 `Resources/Info.plist` 版本并提交后，打 `v*` tag 推到 origin，由 [.github/workflows/release.yml](.github/workflows/release.yml) 校验版本、构建通用包（arm64 + x86_64）并发布 Release。`release.sh` 只做本地自测打包，不上传。发布说明由 [scripts/release-notes.sh](scripts/release-notes.sh) 生成，本地和 CI 共用。

## 参考文档

- [架构与项目结构](docs/architecture.md)
- [开发规范](docs/conventions.md)
