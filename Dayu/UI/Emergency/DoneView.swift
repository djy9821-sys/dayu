import SwiftUI

/// 计时结束：再打一次分，亲眼看到冲动回落。
struct DoneView: View {
    @Environment(AppFlow.self) private var flow
    @State private var endIntensity: Int?

    var body: some View {
        let start = flow.draft?.intensityStart
        let finishedNaturally = !(flow.draft?.isTimerRunning(at: .now) ?? false)

        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 40)

            Text(finishedNaturally ? "时间到了。" : "好，先停在这里。")
                .font(.largeTitle.weight(.bold))

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: start.map { "开始时是 \($0) 分。现在几分？" } ?? "现在冲动几分？")
                IntensityPicker(value: $endIntensity)
            }
            .padding(.top, 28)

            Text(Copy.doneMessage(start: start, end: endIntensity))
                .font(.title3)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 28)
                .animation(.easeInOut, value: endIntensity)

            Spacer(minLength: 24)

            if Copy.shouldOfferExtension(start: start, end: endIntensity) {
                SecondaryButton(title: "再走 10 分钟") {
                    flow.extendTimer(minutes: 10)
                }
                .padding(.bottom, 12)
            }

            PrimaryButton(title: "记一下", subtitle: "15 秒") {
                flow.go(.log(.afterEmergency))
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
        .onAppear {
            endIntensity = flow.draft?.intensityEnd
        }
        .onChange(of: endIntensity) { _, newValue in
            flow.updateDraft { $0.intensityEnd = newValue }
        }
    }
}
