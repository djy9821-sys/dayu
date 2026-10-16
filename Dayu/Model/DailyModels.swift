import Foundation
import SwiftData

/// 每天一行的"底盘"：睡眠、最重要的事、真人交流、Night Mode。
@Model
final class DailyLog {
    @Attribute(.unique) var localDate: String
    /// 昨晚入睡、今早起床的钟点（从午夜开始的分钟数）
    var bedMinutes: Int?
    var wakeMinutes: Int?
    var sleepMinutes: Int?
    /// 今天最重要的一件事
    var mitText: String?
    var mitDone: Bool?
    /// 今天有没有和真人交流
    var connected: Bool?
    var nightModeDone: Bool
    /// 早上回答的"昨晚怎么样"
    var lastNightCalm: Bool?
    var updatedAt: Date

    init(localDate: String) {
        self.localDate = localDate
        self.nightModeDone = false
        self.updatedAt = .now
    }

    var hasMit: Bool {
        !(mitText ?? "").trimmed.isEmpty
    }

    var snapshot: DaySnapshot {
        DaySnapshot(
            localDate: localDate,
            sleepMinutes: sleepMinutes,
            mitText: mitText,
            mitDone: mitDone,
            connected: connected,
            nightModeDone: nightModeDone
        )
    }
}

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var localDate: String
    var typeRaw: String
    var minutes: Int?
    var isMinimum: Bool
    var createdAt: Date

    init(localDate: String, type: WorkoutType, minutes: Int?, isMinimum: Bool, createdAt: Date = .now) {
        self.id = UUID()
        self.localDate = localDate
        self.typeRaw = type.rawValue
        self.minutes = minutes
        self.isMinimum = isMinimum
        self.createdAt = createdAt
    }

    var kind: WorkoutType { WorkoutType(rawValue: typeRaw) ?? .other }

    var snapshot: WorkoutSnapshot {
        WorkoutSnapshot(localDate: localDate, type: kind, minutes: minutes)
    }

    var shortLabel: String {
        if let minutes {
            return "\(kind.label) \(minutes) 分"
        }
        return kind.label
    }
}

/// If-Then 预案：如果……那么我……
@Model
final class IfThenPlan {
    @Attribute(.unique) var id: UUID
    var ifText: String
    var thenText: String
    var sourceEventID: UUID?
    var active: Bool
    var createdAt: Date

    init(ifText: String, thenText: String, sourceEventID: UUID? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.ifText = ifText
        self.thenText = thenText
        self.sourceEventID = sourceEventID
        self.active = true
        self.createdAt = createdAt
    }
}

enum DailyStore {
    /// 今天（按手机现在的时区）。
    static var todayKey: String {
        LocalTime.dateString(.now, calendar: .current)
    }

    static func existing(for key: String, in context: ModelContext) -> DailyLog? {
        let all = (try? context.fetch(FetchDescriptor<DailyLog>())) ?? []
        return all.first { $0.localDate == key }
    }

    /// 取出某天的记录，没有就新建一条。
    static func log(for key: String, in context: ModelContext) -> DailyLog {
        if let existing = existing(for: key, in: context) {
            return existing
        }
        let log = DailyLog(localDate: key)
        context.insert(log)
        return log
    }
}
