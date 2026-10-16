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
    static func apply(flow: AppFlow) {
        guard let screen else { return }
        let now = Date.now

        func timerDraft(startedMinutesAgo: Double, minutes: Int, start: Int?, end: Int?, outside: Bool = true) -> EmergencyDraft {
            var draft = EmergencyDraft(startedAt: now.addingTimeInterval(-startedMinutesAgo * 60 - 40))
            draft.startTimer(at: now.addingTimeInterval(-startedMinutesAgo * 60), minutes: minutes, leftEnvironment: outside)
            draft.intensityStart = start
            draft.intensityEnd = end
            return draft
        }

        switch screen {
        case "today-timer":
            flow.setDraft(timerDraft(startedMinutesAgo: 6, minutes: 20, start: 7, end: nil))
        case "steps":
            flow.setDraft(EmergencyDraft(startedAt: now.addingTimeInterval(-20)))
            flow.present(.steps)
        case "timer":
            flow.setDraft(timerDraft(startedMinutesAgo: 3.2, minutes: 20, start: 7, end: nil))
            flow.present(.timer)
        case "timer-inside":
            flow.setDraft(timerDraft(startedMinutesAgo: 1, minutes: 20, start: 6, end: nil, outside: false))
            flow.present(.timer)
        case "done":
            flow.setDraft(timerDraft(startedMinutesAgo: 21, minutes: 20, start: 8, end: 3))
            flow.present(.done)
        case "log":
            flow.setDraft(timerDraft(startedMinutesAgo: 21, minutes: 20, start: 8, end: 3))
            flow.present(.log(.afterEmergency))
        case "backfill":
            flow.present(.log(.backfill))
        case "stop":
            flow.present(.stop(stage: .watched, night: true))
        case "stop-services":
            flow.present(.stop(stage: .soughtServices, night: false))
        case "saved":
            flow.present(.saved)
        case "morning":
            flow.present(.morning)
        case "evening":
            flow.present(.evening)
        case "night":
            flow.present(.nightMode)
        case "workout":
            flow.present(.workout)
        case "trends":
            flow.tab = .trends
        case "me":
            flow.tab = .me
        default:
            break
        }
    }

    /// 演示用的一周记录。
    static func seed(_ context: ModelContext) {
        let now = Date.now
        let vietnam = 420
        let manila = 480
        let calendar = Calendar.current

        func at(daysAgo: Int, hour: Int, minute: Int, offset: Int) -> Date {
            let local = LocalTime.calendar(offsetMinutes: offset)
            let day = local.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return local.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        func key(daysAgo: Int) -> String {
            LocalTime.dateString(calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now, calendar: calendar)
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
            UrgeEvent(startedAt: now.addingTimeInterval(-9 * 3600), tzOffsetMinutes: LocalTime.offsetMinutes(at: now),
                      source: .backfill, emergencyDone: false, timerMinutes: nil, intensityStart: 8, intensityEnd: nil,
                      triggers: [.alone, .instagram], place: .hotel, leftEnvironment: false, stage: .watched,
                      watchMinutes: 20, note: nil),
        ]
        for event in samples {
            context.insert(event)
        }

        let sleeps = [440, 390, 465, 350, 420, 400]
        for (index, minutes) in sleeps.enumerated() {
            let log = DailyLog(localDate: key(daysAgo: index + 1))
            log.sleepMinutes = minutes
            log.mitText = "把报价发出去"
            log.mitDone = index % 2 == 0
            log.connected = index != 2
            log.nightModeDone = index % 3 != 1
            context.insert(log)
        }
        let today = DailyLog(localDate: key(daysAgo: 0))
        today.sleepMinutes = 425
        today.bedMinutes = 23 * 60 + 50
        today.wakeMinutes = 7 * 60 + 0
        today.mitText = "回复三个经销商"
        context.insert(today)

        context.insert(Workout(localDate: key(daysAgo: 4), type: .strength, minutes: 30, isMinimum: false))
        context.insert(Workout(localDate: key(daysAgo: 2), type: .walk, minutes: 40, isMinimum: false))
        context.insert(IfThenPlan(ifText: "深夜 · 酒店 · 独处、Instagram", thenText: "带电脑去大堂工作 20 分钟"))

        try? context.save()
    }
}
#endif
