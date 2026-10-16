import Foundation

/// 本机设置的键名。界面里用 @AppStorage 读写同一组键。
enum SettingsKey {
    static let timerMinutes = "timerMinutes"
    static let innerStages = "innerStages"
    static let lockEnabled = "lockEnabled"
    static let emergencyDraft = "emergencyDraft"
}

enum SettingsDefault {
    static let timerMinutes = 20
    static let innerStages = Boundaries.default.storage
    static let lockEnabled = true
    static let timerChoices = [10, 15, 20, 30]
}

enum AppSettings {
    static var boundaries: Boundaries {
        let stored = UserDefaults.standard.string(forKey: SettingsKey.innerStages)
        return Boundaries(storage: stored ?? SettingsDefault.innerStages)
    }

    static var lockEnabled: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.lockEnabled) as? Bool ?? SettingsDefault.lockEnabled
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
