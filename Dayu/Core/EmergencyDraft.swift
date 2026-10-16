import Foundation

/// 一次冲动流程进行到一半时的状态。
///
/// 只有在"记录"那一步保存后，才会变成数据库里的一条记录；
/// 在那之前它存在本机设置里，App 被关掉也能接着计时。
struct EmergencyDraft: Codable, Equatable {
    var startedAt: Date
    var timerStartedAt: Date?
    var timerEndsAt: Date?
    var timerMinutesTotal: Int = 0
    var leftEnvironment: Bool = false
    var intensityStart: Int?
    var intensityEnd: Int?
    var notificationID: String?
    /// 冲动下去了，提前结束了计时（可选：旧版本存下的草稿没有这个字段）
    var endedEarly: Bool?

    init(startedAt: Date) {
        self.startedAt = startedAt
    }

    var hasStartedTimer: Bool { timerStartedAt != nil }

    func isTimerRunning(at now: Date) -> Bool {
        guard let timerEndsAt else { return false }
        return timerEndsAt > now
    }

    /// 剩余秒数（向上取整，最小为 0）。
    func remainingSeconds(at now: Date) -> Int {
        guard let timerEndsAt else { return 0 }
        return max(0, Int(timerEndsAt.timeIntervalSince(now).rounded(.up)))
    }

    /// 实际计时了多少分钟（提前结束时按实际时间算）。
    func elapsedTimerMinutes(at now: Date) -> Int? {
        guard let timerStartedAt else { return nil }
        let end = min(now, timerEndsAt ?? now)
        return max(0, Int((end.timeIntervalSince(timerStartedAt) / 60).rounded()))
    }

    /// 开始计时。
    mutating func startTimer(at now: Date, minutes: Int, leftEnvironment: Bool) {
        timerStartedAt = now
        timerEndsAt = now.addingTimeInterval(TimeInterval(minutes * 60))
        timerMinutesTotal = minutes
        self.leftEnvironment = leftEnvironment
    }

    /// 再加几分钟：如果已经结束，就从现在开始重新算。
    mutating func extendTimer(at now: Date, minutes: Int) {
        let base = max(now, timerEndsAt ?? now)
        if timerStartedAt == nil { timerStartedAt = now }
        timerEndsAt = base.addingTimeInterval(TimeInterval(minutes * 60))
        timerMinutesTotal += minutes
        endedEarly = nil
    }

    /// 提前结束：把结束时间改成现在，之后再进来会直接到结束页，而不是接着计时。
    mutating func endTimer(at now: Date) {
        guard let ends = timerEndsAt, ends > now else { return }
        timerEndsAt = now
        endedEarly = true
    }

    /// 计时页 mm:ss。
    static func clock(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

enum StopDecision {
    /// 是否在保存后弹出止损页：走进了内圈，并且事情发生在最近几个小时内。
    /// 补记很久以前的事时，只需要"记录完成"，不需要"到这里停止"。
    static func shouldShowStopPage(
        stage: Stage,
        boundaries: Boundaries,
        eventStart: Date,
        now: Date
    ) -> Bool {
        boundaries.isInner(stage) && now.timeIntervalSince(eventStart) <= Copy.stopPageWindow
    }
}
