import SwiftUI

/// 计时页：大字倒计时 + 一句话。没有任何可以刷的东西。
/// 可以锁屏，时间到了用本地通知提醒。
struct TimerView: View {
    @Environment(AppFlow.self) private var flow
    @Environment(\.openURL) private var openURL
    @State private var showMessageOptions = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let draft = flow.draft
            let remaining = draft?.remainingSeconds(at: now) ?? 0
            let elapsed = now.timeIntervalSince(draft?.timerStartedAt ?? now)
            let prompt = Copy.timerPrompt(
                elapsed: elapsed,
                minutes: draft?.timerMinutesTotal ?? SettingsDefault.timerMinutes,
                leftEnvironment: draft?.leftEnvironment ?? true
            )

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                Text("还剩")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)

                Text(EmergencyDraft.clock(remaining))
                    .font(.system(size: 88, weight: .light, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityLabel("还剩 \(remaining / 60) 分 \(remaining % 60) 秒")

                Text(prompt)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 84)
                    .padding(.top, 20)
                    .id(prompt)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: prompt)

                if draft?.leftEnvironment == false {
                    Text(Copy.stayInsideHint)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 4)
                }

                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "现在冲动几分？（可以不选）")
                    IntensityPicker(value: Binding(
                        get: { flow.draft?.intensityStart },
                        set: { newValue in flow.updateDraft { $0.intensityStart = newValue } }
                    ))
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "再加 10 分钟") {
                        flow.extendTimer(minutes: 10)
                    }
                    SecondaryButton(title: "给人发条消息") {
                        showMessageOptions = true
                    }
                }
                .padding(.top, 20)

                QuietButton(title: "冲动已经下去了，提前结束") {
                    flow.endTimerEarly()
                }
                .padding(.top, 6)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, Theme.pagePadding)
            .onChange(of: remaining == 0, initial: true) { _, finished in
                if finished, draft?.hasStartedTimer == true {
                    flow.go(.done)
                }
            }
        }
        .confirmationDialog("给谁发都行，不用提这件事。", isPresented: $showMessageOptions, titleVisibility: .visible) {
            Button("信息") { open("sms:") }
            Button("WhatsApp") { open("whatsapp://") }
            Button("微信") { open("weixin://") }
            Button("取消", role: .cancel) {}
        }
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }
}
