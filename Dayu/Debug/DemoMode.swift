import Foundation
import SwiftData

/// 只用于开发时截图检查：用启动参数 `-uiDemo <页面>` 直接打开某一页，
/// 数据放在内存里，不碰真实记录。正式版（Release）里这个开关永远关闭。
enum DemoMode {
    static var screen: String? {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "uiDemo")
        #else
        return nil
        #endif
    }

    static var isActive: Bool { screen != nil }
}

#if DEBUG
extension DemoMode {
    @MainActor
    static func apply(flow: AppFlow, selectTab: (AppTab) -> Void) {
        guard let screen else { return }
        let now = Date.now

        func timerDraft(startedMinutesAgo: Double, minutes: Int, start: Int?, end: Int?) -> EmergencyDraft {
            var draft = EmergencyDraft(startedAt: now.addingTimeInterval(-startedMinutesAgo * 60 - 40))
            draft.startTimer(at: now.addingTimeInterval(-startedMinutesAgo * 60), minutes: minutes, leftEnvironment: true)
            draft.intensityStart = start
            draft.intensityEnd = end
            return draft
        }

        switch screen {
        case "today-timer":
            flow.setDraft(timerDraft(startedMinutesAgo: 6, minutes: 20, start: 7, end: nil))
        case "steps":
            flow.setDraft(EmergencyDraft(startedAt: now.addingTimeInterval(-20)))
            flow.step = .steps
            flow.isPresented = true
        case "timer":
            flow.setDraft(timerDraft(startedMinutesAgo: 3.2, minutes: 20, start: 7, end: nil))
            flow.step = .timer
            flow.isPresented = true
        case "done":
            flow.setDraft(timerDraft(startedMinutesAgo: 21, minutes: 20, start: 8, end: 3))
            flow.step = .done
            flow.isPresented = true
        case "log":
            flow.setDraft(timerDraft(startedMinutesAgo: 21, minutes: 20, start: 8, end: 3))
            flow.step = .log(.afterEmergency)
            flow.isPresented = true
        case "backfill":
            flow.step = .log(.backfill)
            flow.isPresented = true
        case "stop":
            flow.step = .stop(stage: .watched, night: true)
            flow.isPresented = true
        case "stop-services":
            flow.step = .stop(stage: .soughtServices, night: false)
            flow.isPresented = true
        case "saved":
            flow.step = .saved
            flow.isPresented = true
        case "trends":
            selectTab(.trends)
        case "me":
            selectTab(.me)
        default:
            break
        }
    }

    /// 演示用的一周记录。
    static func seed(_ context: ModelContext) {
        let now = Date.now
        let vietnam = 420
        let manila = 480

        func at(daysAgo: Int, hour: Int, minute: Int, offset: Int) -> Date {
            let calendar = LocalTime.calendar(offsetMinutes: offset)
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let samples: [UrgeEvent] = [
            UrgeEvent(startedAt: at(daysAgo: 6, hour: 23, minute: 40, offset: vietnam), tzOffsetMinutes: vietnam,
                      source: .backfill, emergencyDone: false, timerMinutes: nil, intensityStart: 8, intensityEnd: nil,
                      triggers: [.alone, .instagram], place: .home, leftEnvironment: false, stage: .masturbated,
                      watchMinutes: 45, note: nil),
            UrgeEvent(startedAt: at(daysAgo: 5, hour: 22, minute: 10, offset: vietnam), tzOffsetMinutes: vietnam,
                      source: .button, emergencyDone: true, timerMinutes: 20, intensityStart: 7, intensityEnd: 3,
                      triggers: [.bored, .instagram], place: .home, leftEnvironment: true, stage: .stimulus,
                      watchMinutes: nil, note: "楼下便利店坐了一会儿"),
            UrgeEvent(startedAt: at(daysAgo: 4, hour: 7, minute: 5, offset: vietnam), tzOffsetMinutes: vietnam,
                      source: .button, emergencyDone: true, timerMinutes: 10, intensityStart: 6, intensityEnd: 2,
                      triggers: [.justWoke], place: .home, leftEnvironment: true, stage: .stimulus,
                      watchMinutes: nil, note: nil),
            UrgeEvent(startedAt: at(daysAgo: 3, hour: 23, minute: 55, offset: manila), tzOffsetMinutes: manila,
                      source: .backfill, emergencyDone: false, timerMinutes: nil, intensityStart: 9, intensityEnd: nil,
                      triggers: [.alone, .instagram, .workStress], place: .hotel, leftEnvironment: false, stage: .watched,
                      watchMinutes: 30, note: nil),
            UrgeEvent(startedAt: at(daysAgo: 2, hour: 23, minute: 20, offset: manila), tzOffsetMinutes: manila,
                      source: .button, emergencyDone: true, timerMinutes: 30, intensityStart: 8, intensityEnd: 4,
                      triggers: [.alone, .instagram], place: .hotel, leftEnvironment: true, stage: .searched,
                      watchMinutes: nil, note: "去大堂坐了 30 分钟"),
            UrgeEvent(startedAt: at(daysAgo: 1, hour: 15, minute: 30, offset: manila), tzOffsetMinutes: manila,
                      source: .button, emergencyDone: true, timerMinutes: 20, intensityStart: 5, intensityEnd: 2,
                      triggers: [.stress], place: .office, leftEnvironment: true, stage: .stimulus,
                      watchMinutes: nil, note: nil),
        ]
        for event in samples {
            context.insert(event)
        }
        try? context.save()
    }
}
#endif
