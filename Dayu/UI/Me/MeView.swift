import SwiftUI
import SwiftData

/// 我的：计时长度、边界、锁、删除全部数据。
struct MeView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKey.timerMinutes) private var timerMinutes = SettingsDefault.timerMinutes
    @AppStorage(SettingsKey.innerStages) private var innerStages = SettingsDefault.innerStages
    @AppStorage(SettingsKey.lockEnabled) private var lockEnabled = SettingsDefault.lockEnabled

    @State private var confirmDeleteAll = false
    @State private var deletedAll = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("计时长度", selection: $timerMinutes) {
                        ForEach(SettingsDefault.timerChoices, id: \.self) { minutes in
                            Text("\(minutes) 分钟").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("冲动计时")
                } footer: {
                    Text("计时期间可以锁屏，时间到了会提醒你。")
                }
                .listRowBackground(Theme.surface)

                Section {
                    ForEach(Stage.configurable) { stage in
                        Toggle(stage.title, isOn: binding(for: stage))
                            .tint(Theme.river)
                    }
                } header: {
                    Text("我的边界")
                } footer: {
                    Text("打开的步骤算作“走进内圈”：记录走到这一步时，会出现止损页，帮你停下来。App 不会说“失败”。")
                }
                .listRowBackground(Theme.surface)

                Section {
                    Toggle("打开 App 需要 Face ID 或密码", isOn: $lockEnabled)
                        .tint(Theme.river)
                } header: {
                    Text("隐私")
                } footer: {
                    Text("所有记录只存在这台手机上。没有账号，没有服务器，不上传任何数据。通知文案永远是中性的，锁屏上看不出用途。")
                }
                .listRowBackground(Theme.surface)

                Section {
                    Button("删除全部数据") {
                        confirmDeleteAll = true
                    }
                    .foregroundStyle(Theme.warm)
                } footer: {
                    Text(deletedAll ? "已删除。" : "删除所有记录和进行中的流程，设置会保留。")
                }
                .listRowBackground(Theme.surface)

                Section {
                    LabeledContent("版本", value: Self.versionLabel)
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("我的")
            .alert("删除全部数据？", isPresented: $confirmDeleteAll) {
                Button("永久删除", role: .destructive, action: deleteAll)
                Button("取消", role: .cancel) {}
            } message: {
                Text("所有记录都会从这台手机上删除，无法恢复。")
            }
        }
    }

    private func binding(for stage: Stage) -> Binding<Bool> {
        Binding(
            get: { Boundaries(storage: innerStages).isInner(stage) },
            set: { isInner in
                innerStages = Boundaries(storage: innerStages).setting(stage, inner: isInner).storage
            }
        )
    }

    private func deleteAll() {
        try? modelContext.delete(model: UrgeEvent.self)
        try? modelContext.save()
        flow.clearDraft()
        Notifier.shared.cancelAll()
        deletedAll = true
    }

    private static var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.1"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
