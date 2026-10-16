import Foundation

/// 统计用的只读快照，和数据库模型解耦，方便测试。
struct EventSnapshot: Equatable {
    var startedAt: Date
    var tzOffsetMinutes: Int
    var source: EventSource
    var stage: Stage
    var leftEnvironment: Bool
    var triggers: [Trigger]
    var place: Place?
    var reviewed: Bool = false
}

/// 过去 7 天的概览。全部从记录里实时算出，不另外存储。
struct WeekSummary: Equatable {
    struct TriggerCount: Equatable {
        var trigger: Trigger
        var count: Int
    }

    struct Pattern: Equatable {
        var label: String
        var count: Int
    }

    var total = 0
    /// 通过"我现在有冲动"按钮记录的次数。中性指标：用得多说明在用。
    var buttonPresses = 0
    /// 没有走进内圈的次数。
    var notCrossed = 0
    /// 走进内圈的次数。
    var crossed = 0
    /// 主动离开了房间的次数。
    var leftEnvironment = 0
    /// 平均截断点（0–4），越小越好。
    var averageStage: Double?
    var topTriggers: [TriggerCount] = []
    /// 最常见的"时段 · 地点 · 触发"组合；至少出现两次才算规律。
    var topPattern: Pattern?

    static func make(
        from events: [EventSnapshot],
        boundaries: Boundaries,
        now: Date,
        days: Int = 7
    ) -> WeekSummary {
        let windowStart = now.addingTimeInterval(-Double(days) * 86_400)
        let recent = events.filter { $0.startedAt > windowStart && $0.startedAt <= now }

        var summary = WeekSummary()
        summary.total = recent.count
        summary.buttonPresses = recent.filter { $0.source == .button }.count
        summary.crossed = recent.filter { boundaries.isInner($0.stage) }.count
        summary.notCrossed = recent.count - summary.crossed
        summary.leftEnvironment = recent.filter(\.leftEnvironment).count
        if !recent.isEmpty {
            let stageSum = recent.map(\.stage.rawValue).reduce(0, +)
            summary.averageStage = Double(stageSum) / Double(recent.count)
        }

        var triggerCounts: [Trigger: Int] = [:]
        var patternCounts: [String: Int] = [:]
        for event in recent {
            let hour = LocalTime.hour(event.startedAt, offsetMinutes: event.tzOffsetMinutes)
            let period = DayPeriod(hour: hour)
            for trigger in Set(event.triggers) {
                triggerCounts[trigger, default: 0] += 1
                let label = [period.label, event.place?.label, trigger.label]
                    .compactMap { $0 }
                    .joined(separator: " · ")
                patternCounts[label, default: 0] += 1
            }
        }

        summary.topTriggers = triggerCounts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key.order < rhs.key.order
            }
            .prefix(3)
            .map { TriggerCount(trigger: $0.key, count: $0.value) }

        let best = patternCounts.max { lhs, rhs in
            lhs.value != rhs.value ? lhs.value < rhs.value : lhs.key > rhs.key
        }
        if let best, best.value >= 2 {
            summary.topPattern = Pattern(label: best.key, count: best.value)
        }

        return summary
    }
}
