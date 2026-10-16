import Foundation

/// App 里所有的话都集中在这里。
///
/// 人格：教练 + 朋友 + 督导。温和，但不纵容。
/// 永远不出现：失败、破戒、Day 0、你没有意志力。
enum Copy {
    // MARK: 冲动流程

    static let stepsHeadline = "换环境，而不是和欲望辩论。"

    static func emergencySteps(solo: Bool = false) -> [String] {
        [
            "关掉正在看的东西",
            "站起来",
            "穿上鞋",
            "离开房间",
            solo ? soloStep : "去大堂、咖啡厅，或者任何有人的地方",
        ]
    }

    static let soloStep = "带上电脑或一本书，去大堂坐 20 分钟"

    /// 出不了门时，计时页显示的替代动作。
    static let inRoomAlternatives = ["20 个俯卧撑", "冷水洗脸", "站到窗边或走廊"]
    static var stayInsideHint: String {
        "至少离开床。也可以：" + inRoomAlternatives.joined(separator: " · ")
    }

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

    /// 计时结束后，根据开始和结束时的冲动分数给一句话。
    static func doneMessage(start: Int?, end: Int?) -> String {
        if let start, let end {
            if end < start {
                return "冲动从 \(start) 降到了 \(end)。它每次都会这样。"
            }
            return "冲动还在。\n可以再走 10 分钟，或者先记下来。"
        }
        return "你守住了这一次。\n记下来，然后回到你的生活。"
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

    // MARK: 提醒（锁屏上别人能看到，必须中性）

    static let timerEndNotification = "时间到了。"
    static let nightReminder = "今天结束了。"
    static let morningReminder = "早。先离开床。"
    static let weeklyReminder = "看一眼这周。"
    static let soloReminder = "去楼下坐 20 分钟？"

    static var allNotificationTexts: [String] {
        [timerEndNotification, nightReminder, morningReminder, weeklyReminder, soloReminder]
    }

    // MARK: 早上

    static let morningTitle = "早。"
    static let morningSubtitle = "先离开床，再看手机。"
    static let morningDone = "好，开始今天"

    // MARK: 晚上

    static let eveningTitle = "今天结束了。"
    static let nightLines = ["今天已经结束。", "不要解决人生。"]
    static let nightChecks = ["手机放远，不带上床", "洗个澡", "关灯，睡觉"]
    static let nightSoloLine = "今晚一个人。手机放在房间另一头，离床远一点。"
    static let goodnight = "晚安"

    // MARK: 运动和底盘

    static let workoutLine = "我正在建设一个更强壮的身体。"
    static let strengthNudge = "今天练一次力量，10 分钟也算。"
    static let minimumNote = "状态不好时只做一点点，也算一次完整记录。"

    // MARK: 独处模式

    static let soloTitle = "今晚一个人住"
    static let soloOff = "出差住酒店时打开。"
    static let soloOn = "21:00 提醒你去楼下坐坐，收尾提醒提前 30 分钟。明早自动关闭。"

    /// 所有会显示给用户的固定文案，用于检查禁用词。
    static var allFixedTexts: [String] {
        var texts: [String] = []
        texts += emergencySteps()
        texts += emergencySteps(solo: true)
        texts += inRoomAlternatives
        texts += stopNight
        texts += stopDay
        texts += nightLines
        texts += nightChecks
        texts += allNotificationTexts
        let singles: [String] = [
            stepsHeadline, soloStep, stayInsideHint, saved, stopTitle, stopSubtitle, pepNote,
            stopButton(night: true), stopButton(night: false),
            morningTitle, morningSubtitle, morningDone, eveningTitle, nightSoloLine, goodnight,
            workoutLine, strengthNudge, minimumNote, soloTitle, soloOff, soloOn,
        ]
        texts += singles
        return texts
    }
}
