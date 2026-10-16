import ActivityKit
import Foundation

/// 锁屏和灵动岛上的倒计时。只显示剩余时间，不显示任何文字内容。
struct DayuTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var endsAt: Date

        /// 倒计时的区间；保证起点不晚于终点。
        var range: ClosedRange<Date> {
            min(startedAt, endsAt)...endsAt
        }
    }
}
