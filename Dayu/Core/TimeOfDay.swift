import Foundation

/// 一天中的某个钟点，用"从午夜开始的分钟数"表示，例如 23:30 = 1410。
struct TimeOfDay: Equatable, Hashable, Codable {
    private(set) var minutes: Int

    init(minutes: Int) {
        self.minutes = ((minutes % 1440) + 1440) % 1440
    }

    init(hour: Int, minute: Int) {
        self.init(minutes: hour * 60 + minute)
    }

    /// 取出某个时刻在给定日历里的钟点。
    init(date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }

    var hour: Int { minutes / 60 }
    var minute: Int { minutes % 60 }
    var label: String { String(format: "%02d:%02d", hour, minute) }

    func adding(minutes delta: Int) -> TimeOfDay {
        TimeOfDay(minutes: minutes + delta)
    }

    /// 某一天的这个钟点。
    func date(on day: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: day)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start)
            ?? start.addingTimeInterval(TimeInterval(minutes * 60))
    }
}

enum SleepMath {
    /// 从入睡到起床的分钟数，可以跨过午夜。
    static func minutes(bed: TimeOfDay, wake: TimeOfDay) -> Int {
        (wake.minutes - bed.minutes + 1440) % 1440
    }

    /// "7 小时 20 分"
    static func label(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if rest == 0 { return "\(hours) 小时" }
        if hours == 0 { return "\(rest) 分钟" }
        return "\(hours) 小时 \(rest) 分"
    }

    /// 首页小卡片上的短写法，例如 "7h20"。
    static func short(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours)h" : String(format: "%dh%02d", hours, rest)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
