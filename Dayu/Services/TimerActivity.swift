import ActivityKit
import Foundation

/// 锁屏和灵动岛上的倒计时（Live Activity）。
@MainActor
enum TimerActivity {
    static func start(startedAt: Date, endsAt: Date) {
        guard !DemoMode.isActive, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = DayuTimerAttributes.ContentState(startedAt: startedAt, endsAt: endsAt)
        let content = ActivityContent(state: state, staleDate: endsAt)
        let existing = Activity<DayuTimerAttributes>.activities
        if existing.isEmpty {
            _ = try? Activity<DayuTimerAttributes>.request(
                attributes: DayuTimerAttributes(),
                content: content,
                pushType: nil
            )
        } else {
            for activity in existing {
                Task { await activity.update(content) }
            }
        }
    }

    static func endAll() {
        for activity in Activity<DayuTimerAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
