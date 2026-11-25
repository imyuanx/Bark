# Bark Mac

原生 macOS 菜单栏首版，和 iOS / watchOS 工程分开。默认不签名、不注册、不发送推送。

English summary: this is an unsigned AppKit + SwiftUI menu-bar app. It does not change the iOS or watch targets. It does not contact a Bark server or APNs. Closing the last window leaves the app running unless you turn that off. The Dock icon can be hidden only while the menu-bar icon exists. Logic tests and an unsigned compile are the verification; nobody has launched this build on a Mac in this change.

## 首版有什么

- 菜单栏图标一直在。菜单里是通知权限、服务器配置、注册状态、最近消息的摘要，以及打开主窗口、打开设置、退出。
- 复制推送 URL 只有在本应用自己的 key 非空时才可点。首版不写入这个 key，所以这一项是停用的，菜单标题里也不放 key。
- 关闭最后一扇窗口后默认继续运行。设置里可以改成关闭窗口即退出。
- Dock 图标默认显示，可以关掉。关掉之后激活策略是辅助程序（没有 Dock 图标），菜单栏图标仍能打开窗口。菜单栏图标若没有创建出来，会把 Dock 图标改回显示。
- 服务器地址只保存在本机 `UserDefaults`。保存不发起网络请求。
- 菜单把系统通知权限、APNs token、后端注册、服务端投递分成四行。默认分别是未询问或正在读取、未请求、未请求、未观察。

## 首版没有什么

- 启动时不向 `api.day.app` 或任何其他服务器发送 `/register`，也不调用 `registerForRemoteNotifications`。
- 四个开关默认关闭。只有用户同时打开“自己的签名”“向 APNs 要 token”，才会调用 `NSApplication.registerForRemoteNotifications`。只有用户再打开“隔离后端”和“允许注册”，并且地址不是官方服务器、已经有本机 token，才会发送 `/register`。
- 不读取、不迁移 iOS 的 key。没有本机 Mac key 时，注册请求不带 `key`。响应里的 key 如果和已知旧 key 相同，不会写入。
- 没有消息历史数据。`LocalHistory.latest()` 固定返回空。
- 没有安装 Notification Service Extension，因此不能承诺系统会在展示前解密，也不能承诺后台收到远程通知就写入历史。
- 没有自定义通知声音、30 秒来电铃声、通信通知头像、关键通知。
- 没有改现有自建服务，也没有另建服务仓库。现有 bark-server 只接受 `device_type` 为 `ios` 或 `watchos`。

## 四个阶段

界面把下面四件事分开。前一件成功不会把后一件标成完成。

1. 系统通知权限：`UNUserNotificationCenter` 的授权。只表示本机能不能显示通知。
2. APNs token：`NSApplication.registerForRemoteNotifications` 的回调。默认不调用。token 不显示在菜单里。
3. 后端注册：`GET /register`。默认不发送。官方主机 `api.day.app` 即使开关打开也会拒绝。
4. 服务端投递：这个客户端观察不到。状态保持“未观察”，不能标成已送达。

## 通知扩展的 SDK 结论

[UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension) 的可用性写明 macOS 10.14+。同一页写明系统只在通知会显示 alert，且 `aps.mutable-content` 为 `1` 时调用 `didReceive`。这是符号文档，不是另一篇 iOS 操作指南。

[Registering your app with APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns) 写明 macOS 使用 `NSApplication.registerForRemoteNotifications()`，并在回调里拿 token。Push capability 在 macOS 上加入的是 APS Environment (macOS) entitlement。

`BarkMac/App/MacNotificationSDKProbe.swift` 在原生 macOS target 里子类化这个扩展类，用来让无签名编译证明 SDK 接受它。它不是已安装的 appex。编译成功只证明类存在，不证明系统会启动扩展，也不证明能解密或归档。

## 将来隔离后端的最小适配

现有自建服务保持不动。将来如果另做一台只服务这个 Mac bundle 的后端，最少要：

- 接受 `device_type=macos`。没有 `key` 时发一个新 key，不要把请求写进已有的 iOS 或 watch 记录。
- 有本机 Mac key 时只更新这一把 key 的 token。
- APNs topic 等于这个 Mac app 的 bundle id，认证密钥属于签这个 app 的团队。
- 推送 URL 仍是 `/{key}/{title}/{body}` 和现有 query。客户端不把 HTTP 成功当成已经投递。

一次 HTTP 成功（将来如果有）也不表示 APNs 可用。本版没有任何成功请求可以展示。

## 还不能当成已经会响的通知

符号文档把扩展类标成 macOS 可用，但本构建没有安装 appex，也没有收到过一条远程通知。静默通知、只有声音或角标的通知，按同一页的说明不会进入扩展。加密、自定义声音和通信通知头像仍然不做。

声音和通信通知的限制：

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

## 签名

未签名配置在 `BarkMac/Signing/Unsigned.xcconfig`，bundle id 仍是 `local.barkmac.unsigned`。占位符是 `YOUR_TEAM_ID` 和 `REPLACE_WITH_YOUR_MAC_BUNDLE_ID`。真实 Team ID 只放在 gitignore 的 `Local.xcconfig` 里，不提交。

候选 bundle id 是 `me.yuanx.BarkMac`。它还没有在 Apple 注册，本仓库也没有向 Apple 查过它是否已经存在。写入门户之前必须先查重。无签名产物不用这个 id。

```bash
bash BarkMac/scripts/unsigned-build.sh
```

脚本编出 `BarkMac/build/BarkMac-unsigned-local.barkmac.unsigned.zip`，里面有 `UNSIGNED.txt`。CI 上传同名 artifact。没有凭据。

`xcodebuild` 只有带 `-allowProvisioningUpdates` 时才会向 Apple 创建或更新 App ID、描述文件和证书。`signed-build.sh` 不传这个参数，也不传 `-allowProvisioningDeviceRegistration`，并且在 `BARK_MAC_ALLOW_SIGNING=1` 之前直接拒绝。Xcode 图形界面如果打开 Automatically manage signing 且已经登录账号，构建时仍可能注册 bundle id。示例配置因此使用 Manual，并且 `CODE_SIGNING_ALLOWED = NO`。

本地签名最少需要：你自己的 10 位 Team ID，以及查重之后的新 bundle id。证书留在本机钥匙串。不要提供密码或私钥。

## 回滚

删掉分支，或不要合并这个 PR。变更都在 `BarkMac/`、`.github/workflows/macos-unsigned.yml`、`.gitignore`，以及 README 里指向这里的一小段。iOS / watch 的 target、平台、bundle id、签名、Info.plist、fastlane 和原来的 Tests / TestFlight / 文档部署工作流都没有改。

已经装在手机或 Mac 上的现有 Bark 不会被这个工程覆盖：bundle id 不同，这个构建也不会去安装或退出别的应用。

## 测试记录

`72f1a46` 的 `macos-15-intel` 无签名编译和 13 个逻辑测试已经通过，见 PR。打包步骤加入后，以新的 `macOS unsigned` 运行结果为准。没有在 Mac 上打开过界面，也没有发过注册或推送。Linux 上的检查不是 Mac 构建。
