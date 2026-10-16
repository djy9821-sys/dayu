import SwiftUI
import SwiftData

/// 记一次运动。10 分钟也算一次完整记录。
struct WorkoutView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.modelContext) private var modelContext
    @State private var kind: WorkoutType = .strength
    @State private var minutes: Int? = 20
    @State private var isMinimum = false

    private static let minuteChoices = [10, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowTopBar(leading: "取消") {
                flow.close()
            }

            Text("记一次运动")
                .font(.title2.weight(.bold))
                .padding(.top, 4)
            Text(Copy.workoutLine)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "类型")
                    FlowLayout(spacing: 8) {
                        ForEach(WorkoutType.allCases) { option in
                            Chip(label: option.label, selected: kind == option) {
                                kind = option
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "多久")
                    FlowLayout(spacing: 8) {
                        ForEach(Self.minuteChoices, id: \.self) { value in
                            Chip(label: "\(value) 分钟", selected: minutes == value) {
                                minutes = minutes == value ? nil : value
                            }
                        }
                    }
                }

                Toggle(isOn: $isMinimum) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("最小版本")
                            .font(.body)
                        Text(Copy.minimumNote)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.river)
            }
            .padding(.top, 28)

            Spacer(minLength: 24)

            PrimaryButton(title: "保存") {
                modelContext.insert(Workout(
                    localDate: DailyStore.todayKey,
                    type: kind,
                    minutes: minutes,
                    isMinimum: isMinimum
                ))
                try? modelContext.save()
                flow.go(.saved)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
    }
}
