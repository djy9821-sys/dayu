import Foundation

enum WorkoutType: String, CaseIterable, Identifiable, Codable, Hashable {
    case strength
    case cardio
    case walk
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: return "力量"
        case .cardio: return "有氧"
        case .walk: return "走路"
        case .other: return "其他"
        }
    }
}

struct DaySnapshot: Equatable {
    var localDate: String
    var sleepMinutes: Int?
    var mitText: String?
    var mitDone: Bool?
    var connected: Bool?
    var nightModeDone: Bool
}

struct WorkoutSnapshot: Equatable {
    var localDate: String
    var type: WorkoutType
    var minutes: Int?
}

/// 过去 7 天的"底盘"：睡眠、运动、最重要的事、真人交流、Night Mode。
struct BaseSummary: Equatable {
    var averageSleepMinutes: Int?
    var sleepDays = 0
    var strength = 0
    var otherWorkouts = 0
    var mitDone = 0
    var connected = 0
    var nightMode = 0

    static let strengthGoal = 3

    static func make(days: [DaySnapshot], workouts: [WorkoutSnapshot], today: String, window: Int = 7) -> BaseSummary {
        let dates = Set(LocalTime.recentDates(endingAt: today, count: window))
        let recentDays = days.filter { dates.contains($0.localDate) }
        let recentWorkouts = workouts.filter { dates.contains($0.localDate) }

        var summary = BaseSummary()
        let sleeps = recentDays.compactMap(\.sleepMinutes).filter { $0 > 0 }
        summary.sleepDays = sleeps.count
        if !sleeps.isEmpty {
            summary.averageSleepMinutes = Int((Double(sleeps.reduce(0, +)) / Double(sleeps.count)).rounded())
        }
        summary.strength = recentWorkouts.filter { $0.type == .strength }.count
        summary.otherWorkouts = recentWorkouts.count - summary.strength
        summary.mitDone = recentDays.filter { $0.mitDone == true }.count
        summary.connected = recentDays.filter { $0.connected == true }.count
        summary.nightMode = recentDays.filter(\.nightModeDone).count
        return summary
    }
}

enum Rhythm {
    /// 可以少练，但不要连续两次不练：距离上一次力量训练 3 天及以上（或者还没有记录）时提醒一句。
    static func shouldNudgeStrength(lastStrengthDate: String?, today: String) -> Bool {
        guard let last = lastStrengthDate, let days = LocalTime.daysBetween(last, today) else { return true }
        return days >= 3
    }
}

/// 第二天早上的 1 分钟复盘。
enum ReviewQueue {
    /// 36 小时内、走进了内圈、还没复盘过的记录。
    static let window: TimeInterval = 36 * 3600

    static func needsReview(_ event: EventSnapshot, boundaries: Boundaries, now: Date) -> Bool {
        guard !event.reviewed, boundaries.isInner(event.stage) else { return false }
        let age = now.timeIntervalSince(event.startedAt)
        return age >= 0 && age <= window
    }

    /// 可以选的截断点：这次走到的那一步之前的每一步。
    static func cutOptions(for stage: Stage) -> [Stage] {
        Stage.allCases.filter { $0.rawValue < stage.rawValue }
    }

    /// 预案里"如果"的部分，例如 "深夜 · 酒店 · 独处、Instagram"。
    static func condition(for event: EventSnapshot) -> String {
        let hour = LocalTime.hour(event.startedAt, offsetMinutes: event.tzOffsetMinutes)
        var parts = [DayPeriod(hour: hour).label]
        if let place = event.place {
            parts.append(place.label)
        }
        let triggers = event.triggers.prefix(2).map(\.label)
        if !triggers.isEmpty {
            parts.append(triggers.joined(separator: "、"))
        }
        return parts.joined(separator: " · ")
    }
}

extension Stage {
    /// 复盘时"最早可以在哪一步截断"的说法。
    var cutLabel: String {
        switch self {
        case .stimulus: return "刚刷到的时候"
        case .searched: return "开始搜索的时候"
        case .watched: return "开始看的时候"
        case .masturbated: return "结束之后，出门之前"
        case .soughtServices: return "—"
        }
    }
}
