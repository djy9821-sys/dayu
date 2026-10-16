import SwiftUI
import SwiftData

/// 一条记录的详情。可以删除记错的记录。
struct EventDetailView: View {
    let event: UrgeEvent

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        List {
            Section {
                row("时间", event.localTimeLabel)
                row("走到了哪一步", event.stage.title)
                if !event.triggers.isEmpty {
                    row("触发", event.triggers.map(\.label).joined(separator: " · "))
                }
                if let place = event.place {
                    row("地点", place.label)
                }
                row("离开了房间", event.leftEnvironment ? "是" : "否")
            }
            .listRowBackground(Theme.surface)

            Section {
                row("来源", event.source == .button ? "冲动按钮" : "补记")
                if let start = event.intensityStart {
                    if let end = event.intensityEnd {
                        row("冲动强度", "\(start) → \(end)")
                    } else {
                        row("冲动强度", "\(start)")
                    }
                }
                if let minutes = event.timerMinutes {
                    row("计时", "\(minutes) 分钟")
                }
                if let watch = event.watchMinutes {
                    row("大概看了", watch >= 90 ? "1 小时以上" : "\(watch) 分钟")
                }
                if let cut = event.cutStageRaw.flatMap(Stage.init(rawValue:)) {
                    row("复盘：最早可以截断在", cut.cutLabel)
                }
            }
            .listRowBackground(Theme.surface)

            if let note = event.note {
                Section("一句话") {
                    Text(note)
                }
                .listRowBackground(Theme.surface)
            }

            Section {
                Button("删除这条记录") {
                    confirmDelete = true
                }
                .foregroundStyle(Theme.warm)
            }
            .listRowBackground(Theme.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("记录")
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除这条记录？", isPresented: $confirmDelete) {
            Button("删除", role: .destructive, action: delete)
            Button("取消", role: .cancel) {}
        } message: {
            Text("只删除这一条，删除后无法恢复。")
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    /// 先离开这一页再删除，避免页面还在显示一条已删除的记录。
    private func delete() {
        let target = event
        let context = modelContext
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            context.delete(target)
            try? context.save()
        }
    }
}
