import Foundation

/// 旧河道上的每一步：刷到刺激 → 主动搜索 → 观看 → 自慰 → 寻找性服务。
/// 数值越小，说明这一次截断得越早。
enum Stage: Int, CaseIterable, Identifiable, Codable, Hashable {
    case stimulus = 0
    case searched = 1
    case watched = 2
    case masturbated = 3
    case soughtServices = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .stimulus: return "刺激出现，没有继续"
        case .searched: return "主动搜索"
        case .watched: return "观看色情内容"
        case .masturbated: return "自慰"
        case .soughtServices: return "寻找性服务"
        }
    }

    /// 可以放进"内圈"的步骤（第 0 步本身就是截断成功，不参与边界设置）。
    static let configurable: [Stage] = [.searched, .watched, .masturbated, .soughtServices]
}

/// 触发标签。顺序和原始需求里列出的顺序一致。
/// "深夜"由记录时间自动算出，"酒店"放在地点里，所以不在这里。
enum Trigger: String, CaseIterable, Identifiable, Codable, Hashable {
    case alone
    case bored
    case stress
    case instagram
    case shortVideo = "short_video"
    case sexyImage = "sexy_image"
    case pornSeen = "porn_seen"
    case justWoke = "just_woke"
    case dream
    case workStress = "work_stress"
    case gfConflict = "gf_conflict"
    case lonely
    case anxious
    case tired
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .alone: return "独处"
        case .bored: return "无聊"
        case .stress: return "压力"
        case .instagram: return "Instagram"
        case .shortVideo: return "短视频"
        case .sexyImage: return "性感图片"
        case .pornSeen: return "色情内容"
        case .justWoke: return "刚睡醒"
        case .dream: return "春梦"
        case .workStress: return "工作压力"
        case .gfConflict: return "和女朋友有矛盾"
        case .lonely: return "孤独"
        case .anxious: return "焦虑"
        case .tired: return "睡眠不足"
        case .other: return "其他"
        }
    }

    /// 用于排序时打破平局，保持和列表顺序一致。
    var order: Int { Trigger.allCases.firstIndex(of: self) ?? 0 }
}

enum Place: String, CaseIterable, Identifiable, Codable, Hashable {
    case home
    case hotel
    case office
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "家"
        case .hotel: return "酒店"
        case .office: return "办公室"
        case .other: return "其他"
        }
    }
}

enum EventSource: String, Codable, Hashable {
    /// 通过"我现在有冲动"按钮走完流程
    case button
    /// 事后补记
    case backfill
}
