import Foundation
import UserNotifications

/// 把 ReminderPlan 算出来的提醒交给系统。
///
/// 每次 App 回到前台、改了作息或打开独处模式时调用：先撤掉旧的，再排未来 7 天。
@MainActor
enum Reminders {
    static func refresh() {
        Task { await refreshNow() }
    }

    static func refreshNow() async {
        guard !DemoMode.isActive else { return }
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let pending = await center.pendingNotificationRequests()
        let old = pending.map(\.identifier).filter { $0.hasPrefix(ReminderPlan.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: old)

        let calendar = Calendar.current
        for item in upcoming() {
            let content = UNMutableNotificationContent()
            content.body = item.body
            content.sound = .default
            content.userInfo = [Notifier.kindKey: item.kind.rawValue]
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }

    static func upcoming(now: Date = .now) -> [ReminderItem] {
        ReminderPlan.make(
            now: now,
            calendar: .current,
            settings: AppSettings.reminders,
            soloUntil: AppSettings.soloUntil
        )
    }

    /// "今天 22:45" / "明天 07:15" / "10月18日 20:00"
    static func describe(_ date: Date, now: Date = .now) -> String {
        let calendar = Calendar.current
        let time = TimeOfDay(date: date, calendar: calendar).label
        if calendar.isDate(date, inSameDayAs: now) {
            return "今天 " + time
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "明天 " + time
        }
        let parts = calendar.dateComponents([.month, .day], from: date)
        return "\(parts.month ?? 0)月\(parts.day ?? 0)日 " + time
    }
}
