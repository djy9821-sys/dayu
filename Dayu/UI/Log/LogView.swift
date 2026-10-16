import SwiftUI
import SwiftData

/// 快速记录 / 补记。15 秒内完成；保存后只显示"记录完成"。
struct LogView: View {
    let mode: LogMode

    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.innerStages) private var innerStages = SettingsDefault.innerStages

    @State private var when = Date.now
    @State private var triggers: Set<Trigger> = []
    @State private var intensity: Int?
    @State private var place: Place?
    @State private var stage: Stage?
    @State private var leftRoom: Bool?
    @State private var watchMinutes: Int?
    @State private var note = ""
    @State private var didPrefill = false

    private var isBackfill: Bool { mode == .backfill }

    var body: some View {
        VStack(spacing: 0) {
            FlowTopBar(leading: isBackfill ? "取消" : "稍后再记") {
                if let back = flow.afterSaved {
                    flow.afterSaved = nil
                    flow.backfillPreset = nil
                    flow.go(back)
                } else {
                    flow.close()
                }
            }
            .padding(.horizontal, Theme.pagePadding)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if isBackfill {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "大概什么时候")
                            DatePicker(
                                "时间",
                                selection: $when,
                                in: Date.now.addingTimeInterval(-14 * 86_400)...Date.now,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Theme.river)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "这次走到了哪一步")
                        StageChain(selection: $stage)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "是什么触发的（可多选）")
                        FlowLayout(spacing: 8) {
                            ForEach(Trigger.allCases) { trigger in
                                Chip(label: trigger.label, selected: triggers.contains(trigger)) {
                                    if triggers.contains(trigger) {
                                        triggers.remove(trigger)
                                    } else {
                                        triggers.insert(trigger)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "在哪里")
                        FlowLayout(spacing: 8) {
                            ForEach(Place.allCases) { option in
                                Chip(label: option.label, selected: place == option) {
                                    place = place == option ? nil : option
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: isBackfill ? "冲动强度" : "冲动强度（开始时）")
                        IntensityPicker(value: $intensity)
                    }

                    if isBackfill {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "中途离开房间了吗")
                            HStack(spacing: 8) {
                                Chip(label: "离开了", selected: leftRoom == true) {
                                    leftRoom = leftRoom == true ? nil : true
                                }
                                Chip(label: "没有", selected: leftRoom == false) {
                                    leftRoom = leftRoom == false ? nil : false
                                }
                            }
                        }
                    }

                    if let stage, stage.rawValue >= Stage.watched.rawValue {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel(text: "大概看了多久")
                            FlowLayout(spacing: 8) {
                                ForEach(Self.watchOptions, id: \.minutes) { option in
                                    Chip(label: option.label, selected: watchMinutes == option.minutes) {
                                        watchMinutes = watchMinutes == option.minutes ? nil : option.minutes
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "一句话（可以不写）")
                        TextField("", text: $note, prompt: Text("例如：去大堂坐了一会儿").foregroundStyle(Theme.muted))
                            .padding(14)
                            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .submitLabel(.done)
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(title: "保存") {
                save()
            }
            .disabled(stage == nil)
            .opacity(stage == nil ? 0.4 : 1)
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .onAppear(perform: prefill)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isBackfill ? "补记一次" : "记一下刚才那次")
                .font(.title2.weight(.bold))
            Text("不评判，只是记下来。")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
        .padding(.top, 4)
    }

    private func prefill() {
        guard !didPrefill else { return }
        didPrefill = true
        if isBackfill, let preset = flow.backfillPreset {
            when = min(preset, .now)
        }
        if !isBackfill, let draft = flow.draft {
            // 走完了计时：默认这次截断在第 0 步
            stage = .stimulus
            intensity = draft.intensityStart
            leftRoom = draft.leftEnvironment
        }
    }

    private func save() {
        guard let stage else { return }
        let now = Date.now
        let draft = isBackfill ? nil : flow.draft
        let startedAt = isBackfill ? when : (draft?.startedAt ?? now)
        let offset = LocalTime.offsetMinutes(at: startedAt)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let event = UrgeEvent(
            startedAt: startedAt,
            tzOffsetMinutes: offset,
            source: isBackfill ? .backfill : .button,
            emergencyDone: draft?.hasStartedTimer ?? false,
            timerMinutes: draft?.elapsedTimerMinutes(at: now),
            intensityStart: intensity,
            intensityEnd: draft?.intensityEnd,
            triggers: Trigger.allCases.filter { triggers.contains($0) },
            place: place,
            leftEnvironment: leftRoom ?? false,
            stage: stage,
            watchMinutes: stage.rawValue >= Stage.watched.rawValue ? watchMinutes : nil,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        modelContext.insert(event)
        try? modelContext.save()

        if !isBackfill {
            flow.clearDraft()
        }

        let boundaries = Boundaries(storage: innerStages)
        if StopDecision.shouldShowStopPage(stage: stage, boundaries: boundaries, eventStart: startedAt, now: now) {
            let hour = LocalTime.hour(now, offsetMinutes: LocalTime.offsetMinutes(at: now))
            flow.go(.stop(stage: stage, night: LocalTime.isNight(hour: hour)))
        } else {
            flow.go(.saved)
        }
    }

    private struct WatchOption {
        let label: String
        let minutes: Int
    }

    private static let watchOptions = [
        WatchOption(label: "10 分钟左右", minutes: 10),
        WatchOption(label: "半小时", minutes: 30),
        WatchOption(label: "1 小时", minutes: 60),
        WatchOption(label: "更久", minutes: 90),
    ]
}
