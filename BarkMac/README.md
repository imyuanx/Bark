# Bark Mac

原生 macOS 菜单栏首版，和 iOS / watchOS 工程分开。默认不签名、不注册、不发送推送。

English summary: this is an unsigned AppKit + SwiftUI menu-bar app. It does not change the iOS or watch targets. It does not contact a Bark server or APNs. Closing the last window leaves the app running unless you turn that off. The Dock icon can be hidden only while the menu-bar icon exists. Logic tests and an unsigned compile are the verification; nobody has launched this build on a Mac in this change.

## 首版有什么

- 菜单栏图标一直在。菜单里是通知权限、服务器配置、注册状态、最近消息的摘要，以及打开主窗口、打开设置、退出。
- 复制推送 URL 只有在本应用自己的 key 非空时才可点。首版不写入这个 key，所以这一项是停用的，菜单标题里也不放 key。
- 关闭最后一扇窗口后默认继续运行。设置里可以改成关闭窗口即退出。
- Dock 图标默认显示，可以关掉。关掉之后激活策略是辅助程序（没有 Dock 图标），菜单栏图标仍能打开窗口。菜单栏图标若没有创建出来，会把 Dock 图标改回显示。
- 服务器地址只保存在本机 `UserDefaults`。保存不发起网络请求。
- 状态只用这些说法：未配置、未注册、未连接、未验证、未向 APNs 注册。通知权限来自系统的 `UNAuthorizationStatus`。允许通知不会被写成“推送可用”。

## 首版没有什么

- 不向 `api.day.app` 或任何其他服务器发送 `/register`，启动时也不自动注册。
- 不调用 `registerForRemoteNotifications`，没有 device token。
- 不读取、不迁移 iOS 的 key 或服务器列表。本应用自己的 key 槽位 `barkmac.independentDeviceKey` 只定义了读取规则，界面不会写入。
- 没有消息历史数据。`LocalHistory.latest()` 固定返回空。
- 没有 Notification Service Extension，因此不能在通知展示前解密，也不能承诺后台收到远程通知就写入历史。
- 没有自定义通知声音、30 秒来电铃声、通信通知头像、关键通知。
- 没有改 `Finb/bark-server`。现有服务端只接受 `device_type` 为 `ios` 或 `watchos`，topic 也是固定的 iOS / watch bundle。`device_type=macos` 还没有服务端。

一次 HTTP 成功（将来如果有）也不表示 APNs 可用。本版没有任何成功请求可以展示。

## 通知扩展为什么没做

依据 Apple 文档，而不是把 iOS 扩展直接搬过来：

- [`UNNotificationServiceExtension`](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension) 的可用性包含 macOS 10.14+ 和 Mac Catalyst 13.1+。类在 macOS SDK 里存在。
- 同一页写明：系统只在通知会显示 alert，并且 `aps` 里 `mutable-content` 为 `1` 时调用扩展。不能改静默通知，也不能改只响铃或只改角标的通知。处理时间有限，超时就显示原始内容。
- [Modifying content in newly delivered notifications](https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications) 把这条路径写成 iOS 应用包、在 iOS 设备上于展示前修改内容。它没有给出原生 AppKit 应用已经验证可用的嵌入步骤。
- 因此这里不添加 appex，也不把“后台收到的远程通知都会归档”写成已经实现。加密通知兼容延后到扩展的实际调用被证实之后。

声音和通信通知同样先记限制、不做实现：

- [`UNNotificationSound`](https://developer.apple.com/documentation/usernotifications/unnotificationsound) 在 macOS 10.14+ 可用。自定义声音要已经在设备上，格式是 Linear PCM、MA4、µLaw 或 aLaw，封装为 aiff、wav 或 caf，短于 30 秒，否则改播默认音。查找位置是当前可执行文件的主 bundle，或应用容器 / App Group 容器的 `Library/Sounds`。iOS 那套扩展里临时下载再播放，依赖扩展真的被调用。
- [Implementing communication notifications](https://developer.apple.com/documentation/usernotifications/implementing-communication-notifications) 要求打开 Communication Notifications 能力，并在收到通知的路径里（文档示例是 NSE）用 intent 更新内容。首版不打开这项能力，也不做每条通知的自定义头像。

## 构建

在一台有 Xcode 的 Mac 上，从仓库根目录：

```bash
bash BarkMac/scripts/unsigned-build.sh
```

脚本会先跑 `swift test --package-path BarkMac`，再用 `xcodebuild -project BarkMac/BarkMac.xcodeproj -scheme BarkMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build`。也可以只打开 `BarkMac/BarkMac.xcodeproj`。不要用 `Bark.xcworkspace` 编这个应用，那个工作区仍是 iOS。

GitHub Actions 工作流 `.github/workflows/macos-unsigned.yml` 在改到 `BarkMac/**` 的 pull request 上跑同一脚本。它只申请 `contents: read`，不使用 secrets，不调用 fastlane，不跑 TestFlight。

这个脚本验证的是逻辑测试和编译。它不启动应用，也不等于真机或 APNs 测试。Linux 上的阅读或静态检查同样不是 Mac 构建。

较新的 macOS 可能拒绝直接打开完全没有签名的 app。本地可以用 `codesign --force --deep --sign -` 对编出来的 `BarkMac.app` 做 ad-hoc 签名。那不是 Apple Developer 签名，没有 Push 能力，也不能当成已经能收推送。

## 签名和 APNs 隔离

- 工程里的 bundle id 是 `local.barkmac.unsigned`。不设置 `DEVELOPMENT_TEAM`，`CODE_SIGNING_ALLOWED` 为 `NO`。
- `BarkMac/Signing/Local.xcconfig.example` 和 `Push.entitlements.example` 没有接到 target 上。要用你自己的 Apple Developer team 时，复制 xcconfig、换成你自己的 team 和 bundle id，再自己打开签名。不要复制 iOS / watch target 的 team、bundle id、描述文件或 match 仓库。
- 云端 Mac 构建池因为 Cursor 侧没有 active team 而起不来。这只说明那次 pool 不可用，不能据此判断你有没有 Apple Developer Program 账号。
- 推送要等三件事同时成立：你自己的 App ID 打开了 Push、描述文件签进这个 Mac bundle、以及一个接受 `device_type=macos` 并用这个 bundle 作为 APNs topic 的隔离后端。官方服务器和未改过的自建 bark-server 目前做不到。在那之前，客户端保持注册关闭。
- 不要把官方 APNs auth key 放进这个仓库或这台构建机器。

## 回滚

删掉分支，或不要合并这个 PR。变更都在 `BarkMac/`、`.github/workflows/macos-unsigned.yml`、`.gitignore`，以及 README 里指向这里的一小段。iOS / watch 的 target、平台、bundle id、签名、Info.plist、fastlane 和原来的 Tests / TestFlight / 文档部署工作流都没有改。

已经装在手机或 Mac 上的现有 Bark 不会被这个工程覆盖：bundle id 不同，这个构建也不会去安装或退出别的应用。

## 测试记录

写这份说明时，当前环境没有 Swift，也没有 Xcode，所以这里不能宣称逻辑测试或 Mac 编译已经通过。无签名编译和 `BarkMacCore` 测试以 GitHub Actions 工作流 `macOS unsigned` 的结果为准，写在 pull request 里。没有在 Mac 上打开过界面，也没有发过注册或推送。Linux 上的检查不是 Mac 构建。
