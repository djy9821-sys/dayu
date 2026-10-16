import Foundation

/// 本机设置的键名。界面里用 @AppStorage 读写同一组键。
enum SettingsKey {
    static let timerMinutes = "timerMinutes"
    static let innerStages = "innerStages"
    static let lockEnabled = "lockEnabled"
    static let emergencyDraft = "emergencyDraft"

    static let bedMinutes = "bedMinutes"
    static let wakeMinutes = "wakeMinutes"
    static let nightLeadMinutes = "nightLeadMinutes"
    static let reminderNight = "reminderNight"
    static let reminderMorning = "reminderMorning"
    static let reminderWeekly = "reminderWeekly"
    /// 今晚独处模式的结束时间（timeIntervalSince1970），0 表示关闭
    static let soloUntil = "soloUntil"
}

enum SettingsDefault {
    static let timerMinutes = 20
    static let innerStages = Boundaries.default.storage
    static let lockEnabled = true
    static let timerChoices = [10, 15, 20, 30]

    static let bedMinutes = ReminderSettings.default.bed.minutes
    static let wakeMinutes = ReminderSettings.default.wake.minutes
    static let nightLeadMinutes = ReminderSettings.default.nightLeadMinutes
    static let nightLeadChoices = [30, 45, 60]
}

enum AppSettings {
    private static var defaults: UserDefaults { .standard }

    static var boundaries: Boundaries {
        Boundaries(storage: defaults.string(forKey: SettingsKey.innerStages) ?? SettingsDefault.innerStages)
    }

    static var lockEnabled: Bool {
        defaults.object(forKey: SettingsKey.lockEnabled) as? Bool ?? SettingsDefault.lockEnabled
    }

    static var reminders: ReminderSettings {
        ReminderSettings(
            bed: TimeOfDay(minutes: defaults.object(forKey: SettingsKey.bedMinutes) as? Int ?? SettingsDefault.bedMinutes),
            wake: TimeOfDay(minutes: defaults.object(forKey: SettingsKey.wakeMinutes) as? Int ?? SettingsDefault.wakeMinutes),
            nightLeadMinutes: defaults.object(forKey: SettingsKey.nightLeadMinutes) as? Int ?? SettingsDefault.nightLeadMinutes,
            nightOn: defaults.object(forKey: SettingsKey.reminderNight) as? Bool ?? true,
            morningOn: defaults.object(forKey: SettingsKey.reminderMorning) as? Bool ?? true,
            weeklyOn: defaults.object(forKey: SettingsKey.reminderWeekly) as? Bool ?? true
        )
    }

    static var soloUntil: Date? {
        let stored = defaults.double(forKey: SettingsKey.soloUntil)
        return stored > 0 ? Date(timeIntervalSince1970: stored) : nil
    }

    static var isSoloActive: Bool {
        (soloUntil ?? .distantPast) > .now
    }
}

/// 进行中的冲动流程，存在本机设置里，App 被关掉也能接着计时。
enum DraftStore {
    static func load() -> EmergencyDraft? {
        guard !DemoMode.isActive,
              let data = UserDefaults.standard.data(forKey: SettingsKey.emergencyDraft)
        else { return nil }
        return try? JSONDecoder().decode(EmergencyDraft.self, from: data)
    }

    static func save(_ draft: EmergencyDraft?) {
        guard !DemoMode.isActive else { return }
        if let draft, let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: SettingsKey.emergencyDraft)
        } else {
            UserDefaults.standard.removeObject(forKey: SettingsKey.emergencyDraft)
        }
    }
}
