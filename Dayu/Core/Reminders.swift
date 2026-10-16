import Foundation

enum ReminderKind: String, Codable {
    /// 睡前收尾：打开晚间小结和 Night Mode
    case night
    /// 早上：打开晨间打卡
    case morning
    /// 周日晚上：打开趋势
    case weekly
    /// 今晚独处模式：21:00 去楼下坐坐
    case solo
}

struct ReminderSettings: Equatable {
    var bed: TimeOfDay
    var wake: TimeOfDay
    /// 收尾提醒比目标入睡时间早多少分钟
    var nightLeadMinutes: Int
    var nightOn: Bool
    var morningOn: Bool
    var weeklyOn: Bool

    static let `default` = ReminderSettings(
        bed: TimeOfDay(hour: 23, minute: 30),
        wake: TimeOfDay(hour: 7, minute: 0),
        nightLeadMinutes: 45,
        nightOn: true,
        morningOn: true,
        weeklyOn: true
    )

    var nightTime: TimeOfDay { bed.adding(minutes: -nightLeadMinutes) }
    var morningTime: TimeOfDay { wake.adding(minutes: 15) }
}

struct ReminderItem: Equatable {
    var id: String
    var kind: ReminderKind
    var body: String
    var fireDate: Date
}

/// 未来几天要发的本地提醒。
///
/// 每次打开 App 都重新计算一遍，所以换了时区、改了作息、打开独处模式，都会立刻生效。
enum ReminderPlan {
    static let idPrefix = "r-"
    static let soloEarlierMinutes = 30
    static let soloLobbyTime = TimeOfDay(hour: 21, minute: 0)
    static let weeklyTime = TimeOfDay(hour: 20, minute: 0)

    static func make(
        now: Date,
        calendar: Calendar,
        settings: ReminderSettings,
        soloUntil: Date?,
        days: Int = 7
    ) -> [ReminderItem] {
        var items: [ReminderItem] = []
        let today = calendar.startOfDay(for: now)
        let solo = soloUntil.flatMap { $0 > now ? $0 : nil }

        for offset in 0..<max(0, days) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = LocalTime.dateString(day, calendar: calendar)

            if settings.nightOn {
                var fire = settings.nightTime.date(on: day, calendar: calendar)
                if let solo, fire < solo {
                    fire = fire.addingTimeInterval(-TimeInterval(soloEarlierMinutes * 60))
                }
                if fire > now {
                    items.append(ReminderItem(id: idPrefix + "night-" + key, kind: .night, body: Copy.nightReminder, fireDate: fire))
                }
            }

            if settings.morningOn {
                let fire = settings.morningTime.date(on: day, calendar: calendar)
                if fire > now {
                    items.append(ReminderItem(id: idPrefix + "morning-" + key, kind: .morning, body: Copy.morningReminder, fireDate: fire))
                }
            }

            // 公历里 weekday 1 是周日
            if settings.weeklyOn, calendar.component(.weekday, from: day) == 1 {
                let fire = weeklyTime.date(on: day, calendar: calendar)
                if fire > now {
                    items.append(ReminderItem(id: idPrefix + "weekly-" + key, kind: .weekly, body: Copy.weeklyReminder, fireDate: fire))
                }
            }

            if let solo {
                let fire = soloLobbyTime.date(on: day, calendar: calendar)
                if fire > now, fire < solo {
                    items.append(ReminderItem(id: idPrefix + "solo-" + key, kind: .solo, body: Copy.soloReminder, fireDate: fire))
                }
            }
        }

        return items.sorted { $0.fireDate < $1.fireDate }
    }

    static func next(_ kind: ReminderKind, in items: [ReminderItem]) -> ReminderItem? {
        items.first { $0.kind == kind }
    }
}

/// 今晚独处模式：出差住酒店时打开，到下一次起床时间自动结束。
enum SoloMode {
    static func until(now: Date, calendar: Calendar, wake: TimeOfDay) -> Date {
        let todayWake = wake.date(on: now, calendar: calendar)
        if todayWake > now { return todayWake }
        return calendar.date(byAdding: .day, value: 1, to: todayWake) ?? todayWake.addingTimeInterval(86_400)
    }
}

/// 补记时默认的时间：上午补记的，多半是昨晚的事。
enum BackfillDefault {
    static func date(now: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: now)
        guard hour < 12, let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return now }
        return TimeOfDay(hour: 23, minute: 0).date(on: yesterday, calendar: calendar)
    }
}
