import SwiftUI
import SwiftData
import UserNotifications

/// 首页：一个大按钮，下面是今天的底盘。没有连续天数，没有分数。
struct TodayView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var logs: [DailyLog]
    @Query(sort: \Workout.createdAt, order: .reverse) private var workouts: [Workout]
    @AppStorage(SettingsKey.soloUntil) private var soloUntil: Double = 0
    @AppStorage(SettingsKey.wakeMinutes) private var wakeTarget = SettingsDefault.wakeMinutes
    @State private var pressCount = 0
    @State private var notificationStatus: UNAuthorizationStatus?

    var body: some View {
        let today = DailyStore.todayKey
        let log = logs.first { $0.localDate == today }
        let todaysWorkouts = workouts.filter { $0.localDate == today }
        let lastStrength = workouts.first { $0.kind == .strength }?.localDate
        let hour = Calendar.current.component(.hour, from: .now)
        let solo = soloUntil > Date.now.timeIntervalSince1970

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(Self.dateTitle(.now))
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)
                Text("今天")
                    .font(.largeTitle.weight(.bold))
                    .padding(.top, 2)

                if let draft = flow.draft {
                    DraftBanner(draft: draft)
                        .padding(.top, 20)
                }

                if notificationStatus == .notDetermined {
                    NotificationCard {
                        Task {
                            _ = await Notifier.shared.requestAuthorizationIfNeeded()
                            await loadStatus()
                        }
                    }
                    .padding(.top, 16)
                }

                urgeButton
                    .padding(.top, 24)

                BaseGrid(
                    log: log,
                    workouts: todaysWorkouts,
                    onSleep: { flow.open(.morning) },
                    onWorkout: { flow.present(.workout) },
                    onMit: { flow.open(.morning) },
                    onConnect: { toggleConnected(today: today) }
                )
                .padding(.top, 16)

                if Rhythm.shouldNudgeStrength(lastStrengthDate: lastStrength, today: today) {
                    Text(Copy.strengthNudge)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 10)
                        .padding(.leading, 4)
                }

                SoloRow(isOn: Binding(
                    get: { solo },
                    set: { setSolo($0) }
                ))
                .padding(.top, 20)

                HStack(spacing: 24) {
                    Spacer()
                    if hour >= 20 || hour < 5 {
                        QuietButton(title: "进入 Night Mode") {
                            flow.open(.evening)
                        }
                    }
                    QuietButton(title: "补记一次") {
                        flow.startBackfill()
                    }
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, Theme.pagePadding)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Theme.text)
        .background(Theme.background.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .medium), trigger: pressCount)
        .task {
            await loadStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await loadStatus() }
            }
        }
    }

    private var urgeButton: some View {
        Button {
            pressCount += 1
            flow.startUrge()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "water.waves")
                    .font(.system(size: 30, weight: .regular))
                Spacer()
                Text("我现在有冲动")
                    .font(.system(size: 32, weight: .semibold))
                Text("按下就开始，不用填任何东西")
                    .font(.subheadline)
                    .opacity(0.75)
            }
            .foregroundStyle(Theme.onRiver)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 210)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Theme.river, Theme.riverDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("我现在有冲动")
        .accessibilityHint("开始冲动应对流程")
    }

    private func loadStatus() async {
        notificationStatus = await Notifier.shared.authorizationStatus()
    }

    private func toggleConnected(today: String) {
        let log = DailyStore.log(for: today, in: modelContext)
        log.connected = !(log.connected ?? false)
        log.updatedAt = .now
        try? modelContext.save()
    }

    private func setSolo(_ on: Bool) {
        if on {
            let until = SoloMode.until(now: .now, calendar: .current, wake: TimeOfDay(minutes: wakeTarget))
            soloUntil = until.timeIntervalSince1970
        } else {
            soloUntil = 0
        }
        Reminders.refresh()
    }

    static func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}

// MARK: 今日底盘

private struct BaseGrid: View {
    let log: DailyLog?
    let workouts: [Workout]
    let onSleep: () -> Void
    let onWorkout: () -> Void
    let onMit: () -> Void
    let onConnect: () -> Void

    var body: some View {
        let sleep = log?.sleepMinutes
        let mit = (log?.hasMit ?? false) ? (log?.mitText ?? "") : nil

        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                BaseTile(icon: "bed.double", title: "睡眠",
                         value: sleep.map(SleepMath.short) ?? "记一下",
                         done: sleep != nil, action: onSleep)
                BaseTile(icon: "figure.strengthtraining.traditional", title: "运动",
                         value: workouts.isEmpty ? "记一次" : workouts.map(\.shortLabel).joined(separator: " · "),
                         done: !workouts.isEmpty, action: onWorkout)
            }
            GridRow {
                BaseTile(icon: "scope", title: "最重要的事",
                         value: mit ?? "写一件",
                         done: log?.mitDone == true, action: onMit)
                BaseTile(icon: "person.2", title: "真人交流",
                         value: log?.connected == true ? "有" : "点一下记录",
                         done: log?.connected == true, action: onConnect)
            }
        }
    }
}

private struct BaseTile: View {
    let icon: String
    let title: String
    let value: String
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.footnote)
                    Text(title)
                        .font(.footnote)
                    Spacer(minLength: 0)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.river)
                    }
                }
                .foregroundStyle(Theme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(done ? Theme.text : Theme.muted)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

private struct SoloRow: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.soloTitle)
                    .font(.subheadline.weight(.semibold))
                Text(isOn ? Copy.soloOn : Copy.soloOff)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Theme.river)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

private struct NotificationCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("开启提醒")
                .font(.subheadline.weight(.semibold))
            Text("每晚提醒你收尾，早上提醒你先离开床。锁屏上只显示中性的文字。")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("开启", action: action)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.river)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

/// 上一次冲动流程还没走完时的提示条。
private struct DraftBanner: View {
    @Environment(AppFlow.self) private var flow
    let draft: EmergencyDraft

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if draft.isTimerRunning(at: now) {
            let minutes = max(1, Int((Double(draft.remainingSeconds(at: now)) / 60).rounded(.up)))
            banner(title: "计时还在继续", detail: "还剩 \(minutes) 分钟", action: "回到计时") {
                flow.startUrge()
            }
        } else if draft.hasStartedTimer {
            banner(title: "时间到了", detail: "记一下刚才那次，15 秒", action: "去记录") {
                flow.startUrge()
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("刚才那次还没开始计时")
                        .font(.subheadline.weight(.semibold))
                    Text("还需要的话，接着走")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                QuietButton(title: "不用了") { flow.clearDraft() }
                Button("继续") { flow.startUrge() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.river)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
    }

    private func banner(title: String, detail: String, action: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.river)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.river)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}
