import SwiftUI
import SwiftData

/// 晨间打卡：睡眠、昨晚怎么样（可以一键补记）、1 分钟复盘、今天最重要的一件事。30 秒完成。
struct MorningView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UrgeEvent.startedAt, order: .reverse) private var events: [UrgeEvent]
    @AppStorage(SettingsKey.innerStages) private var innerStages = SettingsDefault.innerStages
    @AppStorage(SettingsKey.bedMinutes) private var bedTarget = SettingsDefault.bedMinutes
    @AppStorage(SettingsKey.wakeMinutes) private var wakeTarget = SettingsDefault.wakeMinutes

    @State private var bed = Date.now
    @State private var wake = Date.now
    @State private var calm: Bool?
    @State private var mit = ""
    @State private var cut: Stage?
    @State private var nextTime = ""
    @State private var loaded = false

    private var calendar: Calendar { .current }

    private var reviewTarget: UrgeEvent? {
        let boundaries = Boundaries(storage: innerStages)
        let now = Date.now
        return events.first { ReviewQueue.needsReview($0.snapshot, boundaries: boundaries, now: now) }
    }

    /// 从昨天 18:00 到现在记下的次数。
    private var lastNightCount: Int {
        let now = Date.now
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return 0 }
        let from = TimeOfDay(hour: 18, minute: 0).date(on: yesterday, calendar: calendar)
        return events.filter { $0.startedAt >= from && $0.startedAt <= now }.count
    }

    private var sleepMinutes: Int {
        SleepMath.minutes(bed: TimeOfDay(date: bed, calendar: calendar), wake: TimeOfDay(date: wake, calendar: calendar))
    }

    var body: some View {
        VStack(spacing: 0) {
            FlowTopBar(leading: "稍后再说") {
                flow.close()
            }
            .padding(.horizontal, Theme.pagePadding)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Copy.morningTitle)
                            .font(.largeTitle.weight(.bold))
                        Text(Copy.morningSubtitle)
                            .font(.title3)
                            .foregroundStyle(Theme.muted)
                    }

                    sleepSection
                    lastNightSection
                    if let event = reviewTarget {
                        reviewSection(event)
                    }
                    mitSection
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: Copy.morningDone) {
                save()
                flow.close()
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .onAppear(perform: load)
    }

    // MARK: 分区

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "睡眠")
            HStack {
                Text("昨晚几点睡")
                Spacer()
                DatePicker("昨晚几点睡", selection: $bed, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            HStack {
                Text("今早几点起")
                Spacer()
                DatePicker("今早几点起", selection: $wake, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            Text("睡了 \(SleepMath.label(sleepMinutes))")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .tint(Theme.river)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }

    private var lastNightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "昨晚怎么样")
            if lastNightCount > 0 {
                Text("昨晚已经记了 \(lastNightCount) 次。")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            FlowLayout(spacing: 8) {
                Chip(label: "平稳度过", selected: calm == true) {
                    calm = calm == true ? nil : true
                }
                Chip(label: "有一次，补记一下", selected: false) {
                    calm = false
                    save()
                    flow.startBackfill(preset: BackfillDefault.date(now: .now, calendar: calendar), returnTo: .morning)
                }
            }
        }
    }

    private func reviewSection(_ event: UrgeEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "1 分钟复盘")
            Text("\(event.localTimeLabel) · 走到了「\(event.stage.title)」")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text("最早可以在哪一步截断？")
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(ReviewQueue.cutOptions(for: event.stage)) { stage in
                    Chip(label: stage.cutLabel, selected: cut == stage) {
                        cut = cut == stage ? nil : stage
                    }
                }
            }

            Text("下次我会……")
                .font(.headline)
                .padding(.top, 4)
            TextField("", text: $nextTime, prompt: Text("例如：带电脑去大堂工作").foregroundStyle(Theme.muted))
                .padding(14)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .submitLabel(.done)
            Text("写下来会存成你的预案，下次冲动时显示在第一屏：如果 \(ReviewQueue.condition(for: event.snapshot))，那么我……")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }

    private var mitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "今天最重要的一件事")
            TextField("", text: $mit, prompt: Text("例如：把报价发出去").foregroundStyle(Theme.muted))
                .padding(14)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .submitLabel(.done)
        }
    }

    // MARK: 数据

    private func load() {
        guard !loaded else { return }
        loaded = true
        let log = DailyStore.existing(for: DailyStore.todayKey, in: modelContext)
        let now = Date.now
        bed = TimeOfDay(minutes: log?.bedMinutes ?? bedTarget).date(on: now, calendar: calendar)
        wake = TimeOfDay(minutes: log?.wakeMinutes ?? wakeTarget).date(on: now, calendar: calendar)
        mit = log?.mitText ?? ""
        calm = log?.lastNightCalm
    }

    private func save() {
        let log = DailyStore.log(for: DailyStore.todayKey, in: modelContext)
        let bedTime = TimeOfDay(date: bed, calendar: calendar)
        let wakeTime = TimeOfDay(date: wake, calendar: calendar)
        log.bedMinutes = bedTime.minutes
        log.wakeMinutes = wakeTime.minutes
        log.sleepMinutes = SleepMath.minutes(bed: bedTime, wake: wakeTime)
        log.mitText = mit.trimmed.isEmpty ? nil : mit.trimmed
        if let calm {
            log.lastNightCalm = calm
        }
        log.updatedAt = .now

        let plan = nextTime.trimmed
        if let event = reviewTarget, cut != nil || !plan.isEmpty {
            event.reviewedAt = .now
            event.cutStageRaw = cut?.rawValue
            if !plan.isEmpty {
                modelContext.insert(IfThenPlan(
                    ifText: ReviewQueue.condition(for: event.snapshot),
                    thenText: plan,
                    sourceEventID: event.id
                ))
            }
            cut = nil
            nextTime = ""
        }
        try? modelContext.save()
    }
}
