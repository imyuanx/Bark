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
                        statusLine(NotificationPermissionCopy.permissionLine(statusName: model.permissionText))
                        statusLine(model.capability.serverLine)
                        statusLine(model.registration.statusLine)
                        statusLine(CapabilityStatement.apnsLine)
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
                        Text("询问系统是否允许本应用显示通知。允许之后仍然是未向 APNs 注册、未验证。")
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
                        Text("尚无本地消息。")
                        Text("首版没有 Notification Service Extension，应用启动时也不接收远程通知，因此不能把后台收到的推送写入历史。加密推送的解密一并延后。")
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
