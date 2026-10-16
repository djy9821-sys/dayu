import SwiftUI

/// 第一页：不填任何东西，读一遍，起身，出门。
struct StepsView: View {
    @Environment(AppFlow.self) private var flow
    @AppStorage(SettingsKey.timerMinutes) private var timerMinutes = SettingsDefault.timerMinutes

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowTopBar(leading: "先不用了") {
                flow.discardAndClose()
            }

            Text(Copy.stepsHeadline)
                .font(.title2.weight(.bold))
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(Copy.emergencySteps.enumerated()), id: \.offset) { index, step in
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
            .padding(.top, 32)

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
