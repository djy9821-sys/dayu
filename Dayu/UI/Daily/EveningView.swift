import SwiftUI
import SwiftData

/// 晚间小结：两道点击题，然后进入 Night Mode。
struct EveningView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @State private var mitDone: Bool?
    @State private var connected: Bool?
    @State private var mitText: String?
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowTopBar(leading: "稍后") {
                flow.close()
            }

            Spacer(minLength: 24)

            Text(Copy.eveningTitle)
                .font(.largeTitle.weight(.bold))

            VStack(alignment: .leading, spacing: 28) {
                if let mitText {
                    YesNoQuestion(
                        title: "今天最重要的事推进了吗？",
                        detail: mitText,
                        yes: "推进了",
                        no: "还没有",
                        value: $mitDone
                    )
                }
                YesNoQuestion(
                    title: "今天和真人说过话吗？",
                    detail: "当面、电话、语音都算。",
                    yes: "有",
                    no: "没有",
                    value: $connected
                )
            }
            .padding(.top, 32)

            Spacer(minLength: 24)

            PrimaryButton(title: "进入 Night Mode") {
                save()
                flow.go(.nightMode)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        let log = DailyStore.existing(for: DailyStore.todayKey, in: modelContext)
        mitText = (log?.hasMit ?? false) ? log?.mitText : nil
        mitDone = log?.mitDone
        connected = log?.connected
    }

    private func save() {
        let log = DailyStore.log(for: DailyStore.todayKey, in: modelContext)
        if let mitDone { log.mitDone = mitDone }
        if let connected { log.connected = connected }
        log.updatedAt = .now
        try? modelContext.save()
    }
}

struct YesNoQuestion: View {
    let title: String
    var detail: String? = nil
    let yes: String
    let no: String
    @Binding var value: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                Chip(label: yes, selected: value == true) {
                    value = value == true ? nil : true
                }
                Chip(label: no, selected: value == false) {
                    value = value == false ? nil : false
                }
            }
        }
    }
}

/// Night Mode：黑底大字，三件事，出口只有"晚安"。
struct NightModeView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.soloUntil) private var soloUntil: Double = 0
    @State private var checked: Set<Int> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 60)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Copy.nightLines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 34, weight: .semibold))
                    }
                }

                if soloUntil > Date.now.timeIntervalSince1970 {
                    Text(Copy.nightSoloLine)
                        .font(.body)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(Copy.nightChecks.enumerated()), id: \.offset) { index, item in
                        Button {
                            if checked.contains(index) {
                                checked.remove(index)
                            } else {
                                checked.insert(index)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: checked.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(checked.contains(index) ? Theme.river : Theme.line)
                                Text(item)
                                    .font(.title3)
                                    .foregroundStyle(Theme.text)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 40)

                Spacer(minLength: 24)

                PrimaryButton(title: Copy.goodnight) {
                    let log = DailyStore.log(for: DailyStore.todayKey, in: modelContext)
                    log.nightModeDone = true
                    log.updatedAt = .now
                    try? modelContext.save()
                    flow.close()
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, Theme.pagePadding)
        }
    }
}
