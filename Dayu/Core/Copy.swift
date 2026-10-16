import Foundation

/// App 里所有的话都集中在这里。
///
/// 人格：教练 + 朋友 + 督导。温和，但不纵容。
/// 永远不出现：失败、破戒、Day 0、你没有意志力。
enum Copy {
    // MARK: 冲动流程

    static let stepsHeadline = "换环境，而不是和欲望辩论。"

    static let emergencySteps = [
        "关掉正在看的东西",
        "站起来",
        "穿上鞋",
        "离开房间",
        "去大堂、咖啡厅，或者任何有人的地方",
    ]

    static let stayInsideHint = "至少离开床，坐到门口或桌边。"

    /// 计时页轮播的句子。
    static func timerPrompts(minutes: Int, leftEnvironment: Bool) -> [String] {
        [
            "冲动不是命令。",
            "你不用解决一辈子，只需要解决接下来的这 \(minutes) 分钟。",
            "不需要消灭欲望，只需要暂时不要执行。",
            "换环境，而不是和欲望辩论。",
            "冲动像一道浪：会升高，也一定会落下。",
            "注意一下：冲动现在在身体的哪里？比刚才强还是弱？",
            "等计时结束再决定。到时候你多半已经不想了。",
            leftEnvironment ? "你现在在外面，这就已经赢了一半。" : "你已经停下来了，这就已经赢了一半。",
        ]
    }

    /// 每 3.5 分钟换一句。
    static let promptInterval: TimeInterval = 210

    static func timerPrompt(elapsed: TimeInterval, minutes: Int, leftEnvironment: Bool) -> String {
        let prompts = timerPrompts(minutes: minutes, leftEnvironment: leftEnvironment)
        let index = max(0, Int(elapsed / promptInterval)) % prompts.count
        return prompts[index]
    }

    static let timerEndNotification = "时间到了。"

    /// 计时结束后，根据开始和结束时的冲动分数给一句话。
    static func doneMessage(start: Int?, end: Int?) -> String {
        if let start, let end {
            if end < start {
                return "冲动从 \(start) 降到了 \(end)。它每次都会这样。"
            }
            return "冲动还在。可以再走 10 分钟，或者先记下来。"
        }
        return "你守住了这一次。记下来，然后回到你的生活。"
    }

    /// 结束分数不低于开始分数时，提供"再走 10 分钟"。
    static func shouldOfferExtension(start: Int?, end: Int?) -> Bool {
        guard let start, let end else { return false }
        return end >= start
    }

    // MARK: 记录

    static let saved = "记录完成。"

    // MARK: 止损页

    static let stopTitle = "事情已经发生了，到这里停止。"
    static let stopSubtitle = "一次失控是一个数据点，不是一个结论。"

    static let stopNight = ["关掉屏幕，放下手机", "洗个澡", "去睡觉"]
    static let stopDay = ["关掉屏幕，放下手机", "洗把脸，或者冲个澡", "离开房间，回到今天的事"]

    static let pepNote = "如果发生了无保护的性接触，72 小时内可以去医院咨询暴露后预防（PEP）。照顾好身体，也是回主线的一部分。"

    static func stopButton(night: Bool) -> String {
        night ? "晚安。明天回主线。" : "回到主线"
    }

    /// 补记的事件超过这么久，就不再弹止损页，只显示"记录完成"。
    static let stopPageWindow: TimeInterval = 3 * 3600
}
