import ActivityKit
import SwiftUI
import WidgetKit

/// 计时期间锁屏和灵动岛上的倒计时。手机可以真的放下，抬手看一眼就知道还剩多久。
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayuTimerAttributes.self) { context in
            TimerLockScreenView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(WidgetPalette.background)
                .activitySystemActionForegroundColor(WidgetPalette.text)
                .widgetURL(AppRoute.timer.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "water.waves")
                        .font(.title2)
                        .foregroundStyle(WidgetPalette.river)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(state: context.state, isStale: context.isStale)
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .foregroundStyle(WidgetPalette.text)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.isStale ? "时间到了" : "还剩")
                        .font(.footnote)
                        .foregroundStyle(WidgetPalette.muted)
                }
            } compactLeading: {
                Image(systemName: "water.waves")
                    .foregroundStyle(WidgetPalette.river)
            } compactTrailing: {
                Countdown(state: context.state, isStale: context.isStale)
                    .foregroundStyle(WidgetPalette.river)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "water.waves")
                    .foregroundStyle(WidgetPalette.river)
            }
            .widgetURL(AppRoute.timer.url)
        }
    }
}

private struct Countdown: View {
    let state: DayuTimerAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale {
            Text("00:00")
                .monospacedDigit()
        } else {
            Text(timerInterval: state.range, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct TimerLockScreenView: View {
    let state: DayuTimerAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "water.waves")
                .font(.title)
                .foregroundStyle(WidgetPalette.river)
            VStack(alignment: .leading, spacing: 2) {
                Text(isStale ? "时间到了" : "还剩")
                    .font(.subheadline)
                    .foregroundStyle(WidgetPalette.muted)
                if !isStale {
                    Text(timerInterval: state.range, countsDown: true)
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(WidgetPalette.text)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
