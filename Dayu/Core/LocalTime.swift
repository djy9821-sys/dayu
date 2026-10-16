import Foundation

/// 事发当地时间。
///
/// 经常跨时区出差，所以每条记录都存"当时的时区偏移"。
/// "今天""深夜"一律按事发地计算：在马尼拉晚上 11 点就是深夜，
/// 不受之后手机系统时区变化的影响。
enum LocalTime {
    /// 某一时刻在某个时区的 UTC 偏移（分钟）。越南是 +420。
    static func offsetMinutes(at date: Date, in timeZone: TimeZone = .current) -> Int {
        timeZone.secondsFromGMT(for: date) / 60
    }

    static func timeZone(offsetMinutes: Int) -> TimeZone {
        TimeZone(secondsFromGMT: offsetMinutes * 60) ?? TimeZone(identifier: "UTC")!
    }

    static func calendar(offsetMinutes: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone(offsetMinutes: offsetMinutes)
        return calendar
    }

    /// 当地日期，格式 "YYYY-MM-DD"。
    static func dateString(_ date: Date, offsetMinutes: Int) -> String {
        let parts = calendar(offsetMinutes: offsetMinutes).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// 当地日期，按给定日历（通常是手机当前的日历）。
    static func dateString(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// 把 "YYYY-MM-DD" 解析成那一天（按 UTC 计算，只用来算日期差）。
    static func parseDate(_ string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return utcCalendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// 两个当地日期之间相差几天。
    static func daysBetween(_ from: String, _ to: String) -> Int? {
        guard let start = parseDate(from), let end = parseDate(to) else { return nil }
        return utcCalendar.dateComponents([.day], from: start, to: end).day
    }

    /// 以某天为最后一天，往前数 count 天（含当天）。
    static func recentDates(endingAt today: String, count: Int) -> [String] {
        guard let end = parseDate(today) else { return [today] }
        return (0..<max(0, count)).compactMap { offset in
            utcCalendar.date(byAdding: .day, value: -offset, to: end).map { dateString($0, offsetMinutes: 0) }
        }
    }

    private static var utcCalendar: Calendar {
        calendar(offsetMinutes: 0)
    }

    static func hour(_ date: Date, offsetMinutes: Int) -> Int {
        calendar(offsetMinutes: offsetMinutes).component(.hour, from: date)
    }

    /// 23:00–04:59 算深夜。
    static func isLateNight(hour: Int) -> Bool {
        hour >= 23 || hour < 5
    }

    /// 21:00–04:59 止损页按"晚上"处理：洗澡、睡觉。
    static func isNight(hour: Int) -> Bool {
        hour >= 21 || hour < 5
    }

    /// 按事发当地时间显示，例如 "10月16日 周五 23:40"。
    static func display(_ date: Date, offsetMinutes: Int, format: String = "M月d日 EEE HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = timeZone(offsetMinutes: offsetMinutes)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    /// 偏移量写成 "UTC+7"、"UTC+5:30" 这样的形式。
    static func offsetLabel(_ offsetMinutes: Int) -> String {
        let sign = offsetMinutes >= 0 ? "+" : "-"
        let absolute = abs(offsetMinutes)
        let hours = absolute / 60
        let minutes = absolute % 60
        return minutes == 0 ? "UTC\(sign)\(hours)" : String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }
}

/// 一天里的四个时段，按事发当地时间划分。
enum DayPeriod: String, CaseIterable, Hashable {
    case morning
    case afternoon
    case evening
    case lateNight

    init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<18: self = .afternoon
        case 18..<23: self = .evening
        default: self = .lateNight
        }
    }

    var label: String {
        switch self {
        case .morning: return "早上"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        case .lateNight: return "深夜"
        }
    }
}
