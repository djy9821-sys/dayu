import Foundation
import UserNotifications

/// 本地通知。所有文案保持中性：锁屏上别人能看到通知预览。
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    static let kindKey = "kind"
    static let timerEndKind = "timer_end"

    private var center: UNUserNotificationCenter { .current() }

    /// 在 App 启动时调用，这样冷启动时点通知也能接住。
    func configure() {
        center.delegate = self
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 第一次需要时才请求权限，用户知道为什么需要它。
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            if granted {
                await Reminders.refreshNow()
            }
            return granted
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func scheduleTimerEnd(at date: Date) async -> String? {
        let content = UNMutableNotificationContent()
        content.body = Copy.timerEndNotification
        content.sound = .default
        content.userInfo = [Self.kindKey: Self.timerEndKind]

        let seconds = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let id = "timer-" + UUID().uuidString
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            return id
        } catch {
            return nil
        }
    }

    func cancel(id: String?) {
        guard let id else { return }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: UNUserNotificationCenterDelegate

    /// App 在前台时：计时结束不弹横幅（计时页自己会跳到结束页），其他提醒照常显示。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let kind = notification.request.content.userInfo[Self.kindKey] as? String
        completionHandler(kind == Self.timerEndKind ? [] : [.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let kind = response.notification.request.content.userInfo[Self.kindKey] as? String
        Task { @MainActor in
            switch kind {
            case Self.timerEndKind:
                AppFlow.shared.resumeFromNotification()
            case ReminderKind.night.rawValue:
                AppFlow.shared.open(.evening)
            case ReminderKind.morning.rawValue:
                AppFlow.shared.open(.morning)
            case ReminderKind.weekly.rawValue:
                AppFlow.shared.open(.trends)
            default:
                break
            }
        }
        completionHandler()
    }
}
