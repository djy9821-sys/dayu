import SwiftUI
import SwiftData

/// 趋势：过去 7 天的概览 + 全部记录。不用红色，没有连续天数。
struct TrendsView: View {
    @Query(sort: \UrgeEvent.startedAt, order: .reverse) private var events: [UrgeEvent]
    @AppStorage(SettingsKey.innerStages) private var innerStages = SettingsDefault.innerStages

    var body: some View {
        let boundaries = Boundaries(storage: innerStages)
        let summary = WeekSummary.make(from: events.map(\.snapshot), boundaries: boundaries, now: .now)

        NavigationStack {
            List {
                Section {
                    SummaryGrid(summary: summary)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("这 7 天")
                } footer: {
                    if summary.total == 0 {
                        Text("还没有记录。下次冲动来的时候，按首页那个按钮。")
                    } else if let average = summary.averageStage {
                        Text("平均截断在第 \(String(format: "%.1f", average)) 步（0 是刺激出现就停下）。这个数字往下走，就是河道在改。")
                    }
                }
                .listRowBackground(Theme.surface)

                if !summary.topTriggers.isEmpty {
                    Section("最常见的触发") {
                        ForEach(summary.topTriggers, id: \.trigger) { item in
                            HStack {
                                Text(item.trigger.label)
                                Spacer()
                                Text("\(item.count) 次")
                                    .foregroundStyle(Theme.muted)
                                    .monospacedDigit()
                            }
                        }
                        if let pattern = summary.topPattern {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("最常见的组合")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.muted)
                                Text("\(pattern.label)（\(pattern.count) 次）")
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }

                if !events.isEmpty {
                    Section("全部记录") {
                        ForEach(events) { event in
                            NavigationLink(value: event) {
                                EventRow(event: event)
                            }
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("趋势")
            .navigationDestination(for: UrgeEvent.self) { event in
                EventDetailView(event: event)
            }
        }
    }
}

private struct SummaryGrid: View {
    let summary: WeekSummary

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 16) {
            GridRow {
                StatTile(value: summary.buttonPresses, label: "按下冲动按钮")
                StatTile(value: summary.leftEnvironment, label: "离开了房间")
            }
            GridRow {
                StatTile(value: summary.notCrossed, label: "没有越界")
                StatTile(value: summary.crossed, label: "走进内圈", quiet: true)
            }
        }
    }
}

private struct StatTile: View {
    let value: Int
    let label: String
    var quiet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 30, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(quiet ? Theme.muted : Theme.text)
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EventRow: View {
    let event: UrgeEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(event.localTimeLabel)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                if let place = event.place {
                    Text("· \(place.label)")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                if event.source == .backfill {
                    Text("补记")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceRaised, in: Capsule())
                }
            }
            Text(event.stage.title)
                .font(.body)
            if !event.triggers.isEmpty {
                Text(event.triggers.map(\.label).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
