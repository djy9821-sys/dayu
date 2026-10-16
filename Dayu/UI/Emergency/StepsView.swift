import SwiftUI
import SwiftData

/// 第一页：不填任何东西，读一遍，起身，出门。
struct StepsView: View {
    @Environment(AppFlow.self) private var flow
    @AppStorage(SettingsKey.timerMinutes) private var timerMinutes = SettingsDefault.timerMinutes
    @AppStorage(SettingsKey.soloUntil) private var soloUntil: Double = 0
    @Query(sort: \IfThenPlan.createdAt, order: .reverse) private var plans: [IfThenPlan]

    var body: some View {
        let solo = soloUntil > Date.now.timeIntervalSince1970

        VStack(alignment: .leading, spacing: 0) {
            FlowTopBar(leading: "先不用了") {
                flow.discardAndClose()
            }

            Text(Copy.stepsHeadline)
                .font(.title2.weight(.bold))
                .padding(.top, 8)

            if let plan = plans.first(where: { $0.active }) {
                PlanCard(plan: plan)
                    .padding(.top, 20)
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(Copy.emergencySteps(solo: solo).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text("\(index + 1)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Theme.river)
                            .frame(width: 20, alignment: .leading)
                        Text(step)
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 28)

            Spacer(minLength: 24)

            PrimaryButton(
                title: "我出门了，开始计时",
                subtitle: "\(timerMinutes) 分钟。开始后可以锁屏，时间到了会提醒你。"
            ) {
                flow.startTimer(minutes: timerMinutes, leftEnvironment: true)
            }

            HStack {
                Spacer()
                QuietButton(title: "出不了门，就在这里计时") {
                    flow.startTimer(minutes: timerMinutes, leftEnvironment: false)
                }
                Spacer()
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
    }
}

/// 你自己写的预案。自己的话比通用文案管用。
struct PlanCard: View {
    let plan: IfThenPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: "你的预案")
            Text("如果 \(plan.ifText)")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("那么我\(plan.thenText)")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}
