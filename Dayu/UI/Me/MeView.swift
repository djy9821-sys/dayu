import SwiftUI
import SwiftData
import UIKit
import UserNotifications

/// 我的：作息和提醒、预案、边界、计时长度、快捷入口、隐私、删除全部数据。
struct MeView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Query private var plans: [IfThenPlan]

    @AppStorage(SettingsKey.timerMinutes) private var timerMinutes = SettingsDefault.timerMinutes
    @AppStorage(SettingsKey.innerStages) private var innerStages = SettingsDefault.innerStages
    @AppStorage(SettingsKey.lockEnabled) private var lockEnabled = SettingsDefault.lockEnabled
    @AppStorage(SettingsKey.bedMinutes) private var bedMinutes = SettingsDefault.bedMinutes
    @AppStorage(SettingsKey.wakeMinutes) private var wakeMinutes = SettingsDefault.wakeMinutes
    @AppStorage(SettingsKey.nightLeadMinutes) private var nightLead = SettingsDefault.nightLeadMinutes
    @AppStorage(SettingsKey.reminderNight) private var nightOn = true
    @AppStorage(SettingsKey.reminderMorning) private var morningOn = true
    @AppStorage(SettingsKey.reminderWeekly) private var weeklyOn = true
    @AppStorage(SettingsKey.soloUntil) private var soloUntil: Double = 0

    @State private var confirmDeleteAll = false
    @State private var deletedAll = false
    @State private var notificationStatus: UNAuthorizationStatus?

    var body: some View {
        NavigationStack {
            Form {
                scheduleSection
                remindersSection

                Section {
                    NavigationLink {
                        PlansView()
                    } label: {
                        LabeledContent("我的预案", value: "\(plans.filter(\.active).count) 条")
                    }
                } footer: {
                    Text("“如果……那么我……”。最新的一条会显示在冲动流程的第一屏。")
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
                    Text("打开的步骤算作“走进内圈”：记录走到这一步时，会出现止损页，帮你停下来。第二天早上会请你做 1 分钟复盘。App 不会说“失败”。")
                }
                .listRowBackground(Theme.surface)

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
                    Text("计时期间可以锁屏：锁屏和灵动岛上会显示倒计时，时间到了会提醒你。")
                }
                .listRowBackground(Theme.surface)

                shortcutsSection

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
                    Text(deletedAll ? "已删除。" : "删除所有记录、每日打卡、运动和预案，设置会保留。")
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
            .task { await loadStatus() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await loadStatus() } }
            }
            .onChange(of: bedMinutes) { _, _ in Reminders.refresh() }
            .onChange(of: wakeMinutes) { _, _ in Reminders.refresh() }
            .onChange(of: nightLead) { _, _ in Reminders.refresh() }
            .onChange(of: nightOn) { _, _ in Reminders.refresh() }
            .onChange(of: morningOn) { _, _ in Reminders.refresh() }
            .onChange(of: weeklyOn) { _, _ in Reminders.refresh() }
        }
    }

    // MARK: 分区

    private var scheduleSection: some View {
        Section {
            DatePicker("目标入睡", selection: timeBinding($bedMinutes), displayedComponents: .hourAndMinute)
            DatePicker("目标起床", selection: timeBinding($wakeMinutes), displayedComponents: .hourAndMinute)
            Picker("收尾提醒提前", selection: $nightLead) {
                ForEach(SettingsDefault.nightLeadChoices, id: \.self) { minutes in
                    Text("\(minutes) 分钟").tag(minutes)
                }
            }
        } header: {
            Text("作息")
        } footer: {
            Text("收尾提醒在目标入睡前发出，打开就是晚间小结和 Night Mode。晨间提醒在目标起床后 15 分钟。")
        }
        .tint(Theme.river)
        .listRowBackground(Theme.surface)
    }

    private var remindersSection: some View {
        // 读一下 soloUntil，让独处模式开关变化时这里也刷新
        let items = soloUntil >= 0 ? Reminders.upcoming() : []
        let nextNight = ReminderPlan.next(.night, in: items)
        let nextMorning = ReminderPlan.next(.morning, in: items)

        return Section {
            Toggle("每晚收尾提醒", isOn: $nightOn)
            Toggle("早上提醒", isOn: $morningOn)
            Toggle("周日晚上回顾这一周", isOn: $weeklyOn)
            if notificationStatus == .notDetermined {
                Button("开启通知") {
                    Task {
                        _ = await Notifier.shared.requestAuthorizationIfNeeded()
                        await loadStatus()
                    }
                }
                .foregroundStyle(Theme.river)
            } else if notificationStatus == .denied {
                Button("通知已关闭，去系统设置打开") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .foregroundStyle(Theme.warm)
            }
        } header: {
            Text("提醒")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if let nextNight {
                    Text("下一次收尾提醒：\(Reminders.describe(nextNight.fireDate))")
                }
                if let nextMorning {
                    Text("下一次晨间提醒：\(Reminders.describe(nextMorning.fireDate))")
                }
                Text("锁屏上只显示“今天结束了。”“早。先离开床。”这样的中性文字。")
            }
        }
        .tint(Theme.river)
        .listRowBackground(Theme.surface)
    }

    private var shortcutsSection: some View {
        Section {
            ShortcutRow(icon: "lock", title: "锁屏小组件", detail: "长按锁屏 → 自定 → 锁定屏幕 → 添加小组件 → Dayu")
            ShortcutRow(icon: "switch.2", title: "控制中心", detail: "下拉控制中心 → 左上角 + → 添加控制 → 搜索 Dayu")
            ShortcutRow(icon: "button.horizontal.top.press", title: "操作按钮", detail: "设置 → 操作按钮 → 快捷指令 → 开始 Dayu（iPhone 15 Pro 及以后）")
            ShortcutRow(icon: "mic", title: "Siri", detail: "说“开始 Dayu”")
        } header: {
            Text("更快的入口")
        } footer: {
            Text("这几个入口都会直接打开第一步，不用先找 App。图标和名字都是中性的。")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: 工具

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { TimeOfDay(minutes: minutes.wrappedValue).date(on: .now, calendar: .current) },
            set: { minutes.wrappedValue = TimeOfDay(date: $0, calendar: .current).minutes }
        )
    }

    private func binding(for stage: Stage) -> Binding<Bool> {
        Binding(
            get: { Boundaries(storage: innerStages).isInner(stage) },
            set: { isInner in
                innerStages = Boundaries(storage: innerStages).setting(stage, inner: isInner).storage
            }
        )
    }

    private func loadStatus() async {
        notificationStatus = await Notifier.shared.authorizationStatus()
    }

    private func deleteAll() {
        try? modelContext.delete(model: UrgeEvent.self)
        try? modelContext.delete(model: DailyLog.self)
        try? modelContext.delete(model: Workout.self)
        try? modelContext.delete(model: IfThenPlan.self)
        try? modelContext.save()
        flow.clearDraft()
        Notifier.shared.cancelAll()
        Reminders.refresh()
        deletedAll = true
    }

    private static var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.1"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct ShortcutRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Theme.river)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}
