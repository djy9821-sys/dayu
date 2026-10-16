import SwiftUI

/// 首页：一个大按钮。没有天数，没有分数。
struct TodayView: View {
    @Environment(AppFlow.self) private var flow
    @State private var pressCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Self.dateTitle(.now))
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .padding(.top, 12)
            Text("今天")
                .font(.largeTitle.weight(.bold))
                .padding(.top, 2)

            if let draft = flow.draft {
                DraftBanner(draft: draft)
                    .padding(.top, 20)
            }

            Spacer(minLength: 24)

            urgeButton

            Spacer(minLength: 24)

            HStack {
                Spacer()
                QuietButton(title: "补记一次") {
                    flow.startBackfill()
                }
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
        .pageBackground()
        .sensoryFeedback(.impact(weight: .medium), trigger: pressCount)
    }

    private var urgeButton: some View {
        Button {
            pressCount += 1
            flow.startUrge()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "water.waves")
                    .font(.system(size: 30, weight: .regular))
                Spacer()
                Text("我现在有冲动")
                    .font(.system(size: 32, weight: .semibold))
                Text("按下就开始，不用填任何东西")
                    .font(.subheadline)
                    .opacity(0.75)
            }
            .foregroundStyle(Theme.onRiver)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 260)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Theme.river, Theme.riverDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("我现在有冲动")
        .accessibilityHint("开始冲动应对流程")
    }

    static func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}

/// 上一次冲动流程还没走完时的提示条。
private struct DraftBanner: View {
    @Environment(AppFlow.self) private var flow
    let draft: EmergencyDraft

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            content(now: context.date)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if draft.isTimerRunning(at: now) {
            let minutes = max(1, Int((Double(draft.remainingSeconds(at: now)) / 60).rounded(.up)))
            banner(title: "计时还在继续", detail: "还剩 \(minutes) 分钟", action: "回到计时") {
                flow.startUrge()
            }
        } else if draft.hasStartedTimer {
            banner(title: "时间到了", detail: "记一下刚才那次，15 秒", action: "去记录") {
                flow.startUrge()
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("刚才那次还没开始计时")
                        .font(.subheadline.weight(.semibold))
                    Text("还需要的话，接着走")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                QuietButton(title: "不用了") { flow.clearDraft() }
                Button("继续") { flow.startUrge() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.river)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
    }

    private func banner(title: String, detail: String, action: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.river)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.river)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}
