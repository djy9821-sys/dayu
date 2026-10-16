import Foundation
import SwiftData

/// 一次冲动或失控的记录。按钮触发和补记都存在这里。
///
/// 只保存在这台手机上（SwiftData 本地数据库，不连 iCloud）。
@Model
final class UrgeEvent {
    @Attribute(.unique) var id: UUID
    /// 事发时刻（绝对时间）
    var startedAt: Date
    /// 事发当时的时区偏移（分钟），例如越南 +420
    var tzOffsetMinutes: Int
    /// 事发当地日期 "YYYY-MM-DD"
    var localDate: String
    var sourceRaw: String
    /// 是否走了计时流程
    var emergencyDone: Bool
    var timerMinutes: Int?
    var intensityStart: Int?
    var intensityEnd: Int?
    var triggerRaws: [String]
    var placeRaw: String?
    var leftEnvironment: Bool
    /// 这次走到了哪一步（0–4）
    var furthestStageRaw: Int
    var watchMinutes: Int?
    var note: String?
    /// 复盘（M3 使用）
    var reviewedAt: Date?
    var cutStageRaw: Int?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        startedAt: Date,
        tzOffsetMinutes: Int,
        source: EventSource,
        emergencyDone: Bool,
        timerMinutes: Int?,
        intensityStart: Int?,
        intensityEnd: Int?,
        triggers: [Trigger],
        place: Place?,
        leftEnvironment: Bool,
        stage: Stage,
        watchMinutes: Int?,
        note: String?,
        createdAt: Date = .now
    ) {
        self.id = id
        self.startedAt = startedAt
        self.tzOffsetMinutes = tzOffsetMinutes
        self.localDate = LocalTime.dateString(startedAt, offsetMinutes: tzOffsetMinutes)
        self.sourceRaw = source.rawValue
        self.emergencyDone = emergencyDone
        self.timerMinutes = timerMinutes
        self.intensityStart = intensityStart
        self.intensityEnd = intensityEnd
        self.triggerRaws = triggers.map(\.rawValue)
        self.placeRaw = place?.rawValue
        self.leftEnvironment = leftEnvironment
        self.furthestStageRaw = stage.rawValue
        self.watchMinutes = watchMinutes
        self.note = note
        self.reviewedAt = nil
        self.cutStageRaw = nil
        self.createdAt = createdAt
    }

    var source: EventSource { EventSource(rawValue: sourceRaw) ?? .button }
    var stage: Stage { Stage(rawValue: furthestStageRaw) ?? .stimulus }
    var triggers: [Trigger] { triggerRaws.compactMap(Trigger.init(rawValue:)) }
    var place: Place? { placeRaw.flatMap(Place.init(rawValue:)) }

    var snapshot: EventSnapshot {
        EventSnapshot(
            startedAt: startedAt,
            tzOffsetMinutes: tzOffsetMinutes,
            source: source,
            stage: stage,
            leftEnvironment: leftEnvironment,
            triggers: triggers,
            place: place
        )
    }

    /// 按事发当地时间显示；如果和手机现在的时区不同，附上时区。
    var localTimeLabel: String {
        let text = LocalTime.display(startedAt, offsetMinutes: tzOffsetMinutes)
        if tzOffsetMinutes != LocalTime.offsetMinutes(at: startedAt) {
            return text + " · " + LocalTime.offsetLabel(tzOffsetMinutes)
        }
        return text
    }
}
