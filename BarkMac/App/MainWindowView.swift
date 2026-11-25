import SwiftUI

struct MainWindowView: View {
    @ObservedObject var model: AppModel
    let requestPermission: () -> Void
    let openSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bark")
                        .font(.title)
                    Text("菜单栏常驻。下面每一项都是本机状态：未配置、未连接、未验证会照实显示。保存地址不会访问服务器。")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        statusLine(model.stages.permissionLine)
                        statusLine(model.stages.apnsLine)
                        statusLine(model.stages.backendLine)
                        statusLine(model.stages.deliveryLine)
                        statusLine(model.registration.statusLine)
                        statusLine(MacNotificationSDKProbe.summary)
                        statusLine(model.staysRunningLabel)
                        statusLine(model.dockLabel)
                        if !model.statusNote.isEmpty {
                            statusLine(model.statusNote)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                } label: {
                    Text("当前状态")
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("这一步只问系统能不能显示通知。它不向 APNs 要 token，也不向服务器注册。")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("向系统询问通知权限", action: requestPermission)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                } label: {
                    Text("通知权限")
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("只写入本机。不会读取 iOS 里保存的 key，也不会发送 /register。")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        TextField("https://bark.example", text: $model.addressDraft)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Button("仅保存到本机") {
                                model.saveDraft()
                            }
                            Button("清空") {
                                clearAddress()
                            }
                        }
                        if let addressError = model.addressError {
                            Text(addressError)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(RegistrationPolicy.decision(forAddress: model.addressDraft).statusLine)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                } label: {
                    Text("服务器")
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("四个开关默认都是关。关着的时候不会调用 registerForRemoteNotifications，也不会发送 /register。官方地址即使打开也会被拒绝。")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Toggle("我已用自己的团队为新的 Mac bundle 打开 Push", isOn: Binding(
                            get: { model.signingAcknowledged },
                            set: { model.setSigningAcknowledged($0) }
                        ))
                        Toggle("允许向 APNs 请求 token", isOn: Binding(
                            get: { model.userEnabledAPNs },
                            set: { model.setUserEnabledAPNs($0) }
                        ))
                        Toggle("这个地址是隔离后端，接受 device_type=macos", isOn: Binding(
                            get: { model.backendMarkedCompatible },
                            set: { model.setBackendMarkedCompatible($0) }
                        ))
                        Toggle("允许向该后端注册", isOn: Binding(
                            get: { model.userEnabledBackend },
                            set: { model.setUserEnabledBackend($0) }
                        ))
                        HStack {
                            Button("请求 APNs token") {
                                model.requestAPNsToken()
                            }
                            Button("执行后端注册") {
                                model.runBackendRegistration()
                            }
                        }
                        Text("注册成功只会把返回的新 key 写进本应用自己的槽位。没有独立 key 时，请求里不带 key，避免覆盖已有设备。")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                } label: {
                    Text("APNs 与后端")
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("尚无本地消息。")
                        Text("这个构建没有安装 Notification Service Extension。SDK 探针只证明类能编译，不证明系统会调用扩展，也不能把远程通知写入历史。")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                } label: {
                    Text("消息历史")
                }

                Button("打开设置", action: openSettings)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func statusLine(_ text: String) -> some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func clearAddress() {
        model.addressDraft = ""
        model.saveDraft()
    }
}
