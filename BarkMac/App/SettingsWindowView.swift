import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("设置")
                    .font(.title2)
                Text("默认关闭最后一扇窗口后继续运行。菜单栏图标一直保留，所以隐藏 Dock 之后仍然可以从菜单打开窗口。")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("关闭最后窗口后继续运行", isOn: Binding(
                    get: { model.stayResident },
                    set: { model.setStayResident($0) }
                ))
                Toggle("在 Dock 中显示图标", isOn: Binding(
                    get: { model.showDockIcon },
                    set: { model.setShowDock($0) }
                ))

                Text("隐藏 Dock 时，应用改为辅助程序：没有 Dock 图标，菜单栏图标仍可打开主窗口和设置。若菜单栏图标没有创建成功，会自动恢复 Dock 图标。")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("若同时关闭“继续运行”和 Dock 图标，关闭最后一扇窗口会退出进程，菜单栏图标随之消失。这是退出，不是把还在运行的应用藏起来。")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                Text(model.staysRunningLabel)
                Text(model.dockLabel)
                if !model.statusNote.isEmpty {
                    Text(model.statusNote)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
