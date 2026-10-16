import SwiftUI
import SwiftData

/// If-Then 预案。大多数来自早上的 1 分钟复盘，也可以自己写。
struct PlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IfThenPlan.createdAt, order: .reverse) private var plans: [IfThenPlan]
    @State private var ifText = ""
    @State private var thenText = ""

    var body: some View {
        List {
            Section {
                TextField("如果……", text: $ifText, prompt: Text("如果：晚上 11 点后一个人在酒店").foregroundStyle(Theme.muted))
                TextField("那么我……", text: $thenText, prompt: Text("那么我：带电脑去大堂工作").foregroundStyle(Theme.muted))
                Button("保存这条预案") {
                    modelContext.insert(IfThenPlan(ifText: ifText.trimmed, thenText: thenText.trimmed))
                    try? modelContext.save()
                    ifText = ""
                    thenText = ""
                }
                .disabled(ifText.trimmed.isEmpty || thenText.trimmed.isEmpty)
                .foregroundStyle(Theme.river)
            } header: {
                Text("写一条新的")
            } footer: {
                Text("提前想好“如果……那么我……”，比临场做决定可靠得多。")
            }
            .listRowBackground(Theme.surface)

            if !plans.isEmpty {
                Section {
                    ForEach(plans) { plan in
                        Toggle(isOn: Binding(
                            get: { plan.active },
                            set: { plan.active = $0; try? modelContext.save() }
                        )) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("如果 \(plan.ifText)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.muted)
                                Text("那么我\(plan.thenText)")
                            }
                            .padding(.vertical, 2)
                        }
                        .tint(Theme.river)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(plans[index])
                        }
                        try? modelContext.save()
                    }
                } header: {
                    Text("我的预案")
                } footer: {
                    Text("左滑可以删除。关掉的预案不会出现在冲动流程里。")
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("我的预案")
        .navigationBarTitleDisplayMode(.inline)
    }
}
