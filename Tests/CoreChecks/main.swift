// 核心逻辑检查：时间、边界、7 天统计、计时草稿、文案。
// 只依赖 Foundation，在 Mac 上用 swiftc 和 Dayu/Core 里的文件一起编译运行：
//   swiftc Dayu/Core/*.swift Tests/CoreChecks/main.swift -o /tmp/corechecks && /tmp/corechecks

import Foundation

var failures = 0
var checks = 0

func expect(_ condition: @autoclosure () -> Bool, _ message: String, file: String = #file, line: Int = #line) {
    checks += 1
    if !condition() {
        failures += 1
        print("✗ \(message)  (line \(line))")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, line: Int = #line) {
    checks += 1
    if actual != expected {
        failures += 1
        print("✗ \(message): got \(actual), expected \(expected)  (line \(line))")
    }
}

func utc(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string)!
}

let vietnam = 420   // UTC+7
let manila = 480    // UTC+8

// MARK: LocalTime

do {
    // 越南 2026-10-16 23:40 = UTC 16:40
    let date = utc("2026-10-16T16:40:00Z")
    expectEqual(LocalTime.dateString(date, offsetMinutes: vietnam), "2026-10-16", "越南当地日期")
    expectEqual(LocalTime.hour(date, offsetMinutes: vietnam), 23, "越南当地小时")
    // 同一时刻在马尼拉已经是第二天 00:40
    expectEqual(LocalTime.dateString(date, offsetMinutes: manila), "2026-10-17", "马尼拉跨过午夜")
    expectEqual(LocalTime.hour(date, offsetMinutes: manila), 0, "马尼拉当地小时")
    expectEqual(LocalTime.display(date, offsetMinutes: vietnam, format: "HH:mm"), "23:40", "按事发当地时间显示")

    expect(LocalTime.isLateNight(hour: 23), "23 点是深夜")
    expect(LocalTime.isLateNight(hour: 4), "4 点是深夜")
    expect(!LocalTime.isLateNight(hour: 5), "5 点不算深夜")
    expect(!LocalTime.isLateNight(hour: 22), "22 点不算深夜")
    expect(LocalTime.isNight(hour: 21), "21 点止损页按晚上处理")
    expect(!LocalTime.isNight(hour: 20), "20 点止损页按白天处理")

    expectEqual(DayPeriod(hour: 7), .morning, "7 点是早上")
    expectEqual(DayPeriod(hour: 12), .afternoon, "12 点是下午")
    expectEqual(DayPeriod(hour: 18), .evening, "18 点是晚上")
    expectEqual(DayPeriod(hour: 23), .lateNight, "23 点是深夜时段")
    expectEqual(DayPeriod(hour: 2), .lateNight, "2 点是深夜时段")

    expectEqual(LocalTime.offsetLabel(420), "UTC+7", "时区标签")
    expectEqual(LocalTime.offsetLabel(330), "UTC+5:30", "半小时时区")
    expectEqual(LocalTime.offsetLabel(-300), "UTC-5", "负时区")

    let saigon = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
    expectEqual(LocalTime.offsetMinutes(at: date, in: saigon), 420, "越南时区偏移")
}

// MARK: Boundaries

do {
    let defaults = Boundaries.default
    expect(defaults.isInner(.watched), "默认：观看色情内容算内圈")
    expect(defaults.isInner(.soughtServices), "默认：寻找性服务算内圈")
    expect(!defaults.isInner(.masturbated), "默认：自慰不算越界")
    expect(!defaults.isInner(.searched), "默认：主动搜索不算越界")
    expect(!defaults.isInner(.stimulus), "第 0 步永远不算越界")
    expectEqual(defaults.storage, "2,4", "默认存储格式")

    expectEqual(Boundaries(storage: "2,4"), defaults, "从存储还原")
    expectEqual(Boundaries(storage: "").innerStages, [], "空字符串表示都不算")
    expectEqual(Boundaries(storage: " 3 , 1 ,x,9").innerStages, [.searched, .masturbated], "忽略无效值和空格")
    expect(!Boundaries(storage: "0,2").isInner(.stimulus), "第 0 步不能放进内圈")

    let withMasturbation = defaults.setting(.masturbated, inner: true)
    expectEqual(withMasturbation.storage, "2,3,4", "打开一个步骤")
    expectEqual(withMasturbation.setting(.watched, inner: false).storage, "3,4", "关掉一个步骤")
}

// MARK: StopDecision

do {
    let now = utc("2026-10-16T16:40:00Z")
    let boundaries = Boundaries.default
    expect(StopDecision.shouldShowStopPage(stage: .watched, boundaries: boundaries, eventStart: now, now: now),
           "刚发生的内圈行为：弹止损页")
    expect(!StopDecision.shouldShowStopPage(stage: .masturbated, boundaries: boundaries, eventStart: now, now: now),
           "不在内圈：不弹止损页")
    expect(!StopDecision.shouldShowStopPage(stage: .watched, boundaries: boundaries,
                                            eventStart: now.addingTimeInterval(-5 * 3600), now: now),
           "补记 5 小时前的事：只显示记录完成")
    expect(StopDecision.shouldShowStopPage(stage: .soughtServices, boundaries: boundaries,
                                           eventStart: now.addingTimeInterval(-2 * 3600), now: now),
           "2 小时内的事：仍然弹止损页")
}

// MARK: EmergencyDraft

do {
    let start = utc("2026-10-16T16:00:00Z")
    var draft = EmergencyDraft(startedAt: start)
    expect(!draft.hasStartedTimer, "刚按下按钮还没开始计时")
    expectEqual(draft.remainingSeconds(at: start), 0, "没开始计时剩余为 0")
    expectEqual(draft.elapsedTimerMinutes(at: start), nil, "没开始计时没有时长")

    draft.startTimer(at: start, minutes: 20, leftEnvironment: true)
    expect(draft.hasStartedTimer, "开始计时")
    expect(draft.leftEnvironment, "记录离开了房间")
    expect(draft.isTimerRunning(at: start.addingTimeInterval(60)), "1 分钟后还在计时")
    expectEqual(draft.remainingSeconds(at: start.addingTimeInterval(0.4)), 1200, "剩余秒数向上取整")
    expectEqual(draft.remainingSeconds(at: start.addingTimeInterval(1199.5)), 1, "最后半秒显示 1")
    expect(!draft.isTimerRunning(at: start.addingTimeInterval(1200)), "20 分钟到")
    expectEqual(draft.remainingSeconds(at: start.addingTimeInterval(1500)), 0, "过时后剩余为 0")
    expectEqual(draft.elapsedTimerMinutes(at: start.addingTimeInterval(7 * 60 + 10)), 7, "提前结束按实际时间")
    expectEqual(draft.elapsedTimerMinutes(at: start.addingTimeInterval(3600)), 20, "超时后最多算到结束")

    // 计时中加 10 分钟：在原结束时间上加
    var running = draft
    running.extendTimer(at: start.addingTimeInterval(300), minutes: 10)
    expectEqual(running.timerEndsAt, start.addingTimeInterval(1800), "计时中加时")
    expectEqual(running.timerMinutesTotal, 30, "总时长累加")

    // 已经结束再加 10 分钟：从现在开始算
    var ended = draft
    let later = start.addingTimeInterval(1500)
    ended.extendTimer(at: later, minutes: 10)
    expectEqual(ended.timerEndsAt, later.addingTimeInterval(600), "结束后加时从现在算")

    // 提前结束：之后再进来是结束页，不是接着计时
    var early = draft
    let fiveMin = start.addingTimeInterval(300)
    early.endTimer(at: fiveMin)
    expect(!early.isTimerRunning(at: fiveMin.addingTimeInterval(1)), "提前结束后不再计时")
    expectEqual(early.endedEarly, true, "记下提前结束")
    expectEqual(early.elapsedTimerMinutes(at: start.addingTimeInterval(3600)), 5, "时长按提前结束的时间算")
    var reopened = early
    reopened.extendTimer(at: fiveMin.addingTimeInterval(60), minutes: 10)
    expect(reopened.isTimerRunning(at: fiveMin.addingTimeInterval(120)), "提前结束后还可以再走 10 分钟")
    expectEqual(reopened.endedEarly, nil, "再走 10 分钟后不再算提前结束")
    var finished = draft
    finished.endTimer(at: start.addingTimeInterval(1500))
    expectEqual(finished.endedEarly, nil, "已经走完的计时不算提前结束")

    // 旧版本存下的草稿（没有 endedEarly 字段）也能读出来
    let legacy = #"{"startedAt":0,"timerMinutesTotal":20,"leftEnvironment":true}"#.data(using: .utf8)!
    expect((try? JSONDecoder().decode(EmergencyDraft.self, from: legacy)) != nil, "兼容旧草稿")

    // 存储往返
    let data = try! JSONEncoder().encode(running)
    let decoded = try! JSONDecoder().decode(EmergencyDraft.self, from: data)
    expectEqual(decoded, running, "草稿可以存取")

    expectEqual(EmergencyDraft.clock(1200), "20:00", "计时显示")
    expectEqual(EmergencyDraft.clock(65), "01:05", "计时补零")
}

// MARK: WeekSummary

do {
    let now = utc("2026-10-16T12:00:00Z")
    func event(hoursAgo: Double, stage: Stage, source: EventSource = .button, left: Bool = false,
               triggers: [Trigger] = [], place: Place? = nil, offset: Int = vietnam) -> EventSnapshot {
        EventSnapshot(startedAt: now.addingTimeInterval(-hoursAgo * 3600), tzOffsetMinutes: offset,
                      source: source, stage: stage, leftEnvironment: left, triggers: triggers, place: place)
    }

    let empty = WeekSummary.make(from: [], boundaries: .default, now: now)
    expectEqual(empty.total, 0, "没有记录")
    expectEqual(empty.averageStage, nil, "没有记录时没有平均值")
    expectEqual(empty.topPattern, nil, "没有记录时没有规律")

    // UTC 12:00 = 越南 19:00；往前推的小时决定时段
    let events = [
        event(hoursAgo: 20, stage: .stimulus, left: true, triggers: [.alone, .instagram], place: .hotel),   // 越南 23:00 深夜
        event(hoursAgo: 44, stage: .watched, source: .backfill, triggers: [.alone, .instagram], place: .hotel), // 23:00
        event(hoursAgo: 68, stage: .searched, left: true, triggers: [.instagram], place: .hotel),           // 23:00
        event(hoursAgo: 10, stage: .stimulus, left: true, triggers: [.stress], place: .office),             // 09:00
        event(hoursAgo: 30, stage: .soughtServices, source: .backfill, triggers: [.lonely]),               // 13:00
        event(hoursAgo: 8 * 24, stage: .watched, triggers: [.alone]),                                       // 超出 7 天
    ]
    let summary = WeekSummary.make(from: events, boundaries: .default, now: now)
    expectEqual(summary.total, 5, "只统计 7 天内")
    expectEqual(summary.buttonPresses, 3, "冲动按钮次数")
    expectEqual(summary.crossed, 2, "走进内圈次数（观看 + 性服务）")
    expectEqual(summary.notCrossed, 3, "没有越界次数")
    expectEqual(summary.leftEnvironment, 3, "离开房间次数")
    expectEqual(summary.averageStage, Double(0 + 2 + 1 + 0 + 4) / 5, "平均截断点")
    expectEqual(summary.topTriggers.first?.trigger, .instagram, "最常见触发是 Instagram")
    expectEqual(summary.topTriggers.first?.count, 3, "Instagram 3 次")
    expectEqual(summary.topTriggers.count, 3, "最多列 3 个触发")
    expectEqual(summary.topTriggers[1].trigger, .alone, "第二常见是独处")
    expectEqual(summary.topPattern?.label, "深夜 · 酒店 · Instagram", "最常见组合")
    expectEqual(summary.topPattern?.count, 3, "组合出现 3 次")

    // 改了边界，统计跟着变
    let strict = Boundaries.default.setting(.searched, inner: true)
    expectEqual(WeekSummary.make(from: events, boundaries: strict, now: now).crossed, 3, "边界变严后越界次数变多")

    // 同一事件里重复的触发只算一次；只出现一次的组合不算规律
    let single = WeekSummary.make(from: [event(hoursAgo: 1, stage: .stimulus, triggers: [.bored, .bored])],
                                  boundaries: .default, now: now)
    expectEqual(single.topTriggers.first?.count, 1, "重复触发只算一次")
    expectEqual(single.topPattern, nil, "只出现一次不算规律")
}

// MARK: Copy

do {
    expectEqual(Copy.doneMessage(start: 8, end: 3), "冲动从 8 降到了 3。它每次都会这样。", "冲动回落")
    expect(Copy.doneMessage(start: 5, end: 6).hasPrefix("冲动还在"), "冲动没降")
    expect(Copy.doneMessage(start: nil, end: nil).hasPrefix("你守住了这一次"), "没打分")
    expect(Copy.shouldOfferExtension(start: 5, end: 5), "没降就提供再走 10 分钟")
    expect(!Copy.shouldOfferExtension(start: 8, end: 3), "降了就不提供")
    expect(!Copy.shouldOfferExtension(start: nil, end: 3), "没有开始分数就不提供")

    expectEqual(Copy.timerPrompt(elapsed: 0, minutes: 20, leftEnvironment: true), "冲动不是命令。", "第一句")
    expect(Copy.timerPrompt(elapsed: 215, minutes: 15, leftEnvironment: true).contains("15 分钟"), "第二句带上实际分钟数")
    let prompts = Copy.timerPrompts(minutes: 20, leftEnvironment: false)
    expect(!prompts.contains { $0.contains("在外面") }, "没出门时不说你在外面")
    expectEqual(Copy.timerPrompt(elapsed: 210 * Double(prompts.count), minutes: 20, leftEnvironment: true),
                "冲动不是命令。", "轮播回到第一句")

    // 产品原则：任何文案里都不出现这些词
    let banned = ["失败", "破戒", "Day 0", "意志力", "坏人", "犯罪", "惩罚"]
    let allCopy = Copy.allFixedTexts
        + Copy.timerPrompts(minutes: 20, leftEnvironment: true)
        + Copy.timerPrompts(minutes: 20, leftEnvironment: false)
        + [Copy.doneMessage(start: 8, end: 3), Copy.doneMessage(start: 3, end: 8), Copy.doneMessage(start: nil, end: nil)]
    expect(allCopy.count > 50, "文案清单覆盖了所有固定文案")
    for text in allCopy {
        for word in banned {
            expect(!text.contains(word), "文案里出现了「\(word)」：\(text)")
        }
    }

    // 通知文案保持中性：锁屏上看不出用途
    let sensitive = ["色", "冲动", "性", "porn", "自慰", "戒", "失控"]
    for text in Copy.allNotificationTexts {
        for word in sensitive {
            expect(!text.contains(word), "通知文案里出现敏感词「\(word)」：\(text)")
        }
    }

    expectEqual(Copy.emergencySteps().count, 5, "五个步骤")
    expectEqual(Copy.emergencySteps(solo: true).last, Copy.soloStep, "独处模式换成酒店版最后一步")
    expect(Copy.stayInsideHint.contains("俯卧撑"), "出不了门时给出替代动作")
}

// MARK: TimeOfDay / SleepMath

do {
    let bed = TimeOfDay(hour: 23, minute: 30)
    expectEqual(bed.minutes, 1410, "23:30 的分钟数")
    expectEqual(bed.label, "23:30", "钟点显示")
    expectEqual(bed.adding(minutes: -45).label, "22:45", "提前 45 分钟")
    expectEqual(TimeOfDay(hour: 0, minute: 15).adding(minutes: -45).label, "23:30", "跨午夜往前")
    expectEqual(TimeOfDay(minutes: 1500).label, "01:00", "超过一天取余")
    expectEqual(TimeOfDay(minutes: -30).label, "23:30", "负数取余")

    let wake = TimeOfDay(hour: 7, minute: 0)
    expectEqual(SleepMath.minutes(bed: bed, wake: wake), 450, "23:30 到 7:00 是 7.5 小时")
    expectEqual(SleepMath.minutes(bed: TimeOfDay(hour: 1, minute: 10), wake: wake), 350, "凌晨入睡")
    expectEqual(SleepMath.label(450), "7 小时 30 分", "睡眠显示")
    expectEqual(SleepMath.label(420), "7 小时", "整小时")
    expectEqual(SleepMath.label(40), "40 分钟", "不到一小时")
    expectEqual(SleepMath.short(450), "7h30", "短写法")
    expectEqual(SleepMath.short(485), "8h05", "短写法补零")

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
    let day = utc("2026-10-16T05:00:00Z") // 越南 12:00
    expectEqual(LocalTime.display(bed.date(on: day, calendar: calendar), offsetMinutes: vietnam, format: "yyyy-MM-dd HH:mm"),
                "2026-10-16 23:30", "某天的某个钟点")
    expectEqual(TimeOfDay(date: utc("2026-10-16T16:40:00Z"), calendar: calendar).label, "23:40", "从时刻取出钟点")
    expectEqual("  去大堂  \n".trimmed, "去大堂", "去掉首尾空白")
}

// MARK: LocalTime 日期

do {
    expectEqual(LocalTime.daysBetween("2026-10-13", "2026-10-16"), 3, "相差 3 天")
    expectEqual(LocalTime.daysBetween("2026-09-30", "2026-10-01"), 1, "跨月")
    expectEqual(LocalTime.daysBetween("bad", "2026-10-01"), nil, "无效日期")
    expectEqual(LocalTime.recentDates(endingAt: "2026-10-02", count: 3), ["2026-10-02", "2026-10-01", "2026-09-30"], "往前数 3 天")
    expectEqual(LocalTime.recentDates(endingAt: "2026-10-16", count: 7).count, 7, "7 天")
}

// MARK: ReminderPlan

do {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
    // 2026-10-16 是周五；越南 20:00 = UTC 13:00
    let now = utc("2026-10-16T13:00:00Z")
    let settings = ReminderSettings.default
    expectEqual(settings.nightTime.label, "22:45", "默认收尾提醒 22:45")
    expectEqual(settings.morningTime.label, "07:15", "默认晨间提醒 7:15")

    func local(_ date: Date) -> String {
        LocalTime.display(date, offsetMinutes: vietnam, format: "MM-dd HH:mm")
    }

    let items = ReminderPlan.make(now: now, calendar: calendar, settings: settings, soloUntil: nil)
    expectEqual(items.filter { $0.kind == .night }.count, 7, "7 个收尾提醒（今晚还没到）")
    expectEqual(items.filter { $0.kind == .morning }.count, 6, "6 个晨间提醒（今早已过）")
    expectEqual(items.filter { $0.kind == .weekly }.count, 1, "7 天里一个周日")
    expectEqual(items.filter { $0.kind == .solo }.count, 0, "没开独处模式")
    expectEqual(items.first.map { local($0.fireDate) }, "10-16 22:45", "第一个是今晚收尾")
    expectEqual(ReminderPlan.next(.morning, in: items).map { local($0.fireDate) }, "10-17 07:15", "下一个晨间提醒")
    expectEqual(ReminderPlan.next(.weekly, in: items).map { local($0.fireDate) }, "10-18 20:00", "周日 20:00 回顾")
    expect(items.allSatisfy { $0.id.hasPrefix(ReminderPlan.idPrefix) }, "提醒编号统一前缀")
    expectEqual(Set(items.map(\.id)).count, items.count, "提醒编号不重复")
    expect(zip(items, items.dropFirst()).allSatisfy { $0.fireDate <= $1.fireDate }, "按时间排序")

    // 独处模式：今晚 21:00 去楼下坐坐，收尾提前 30 分钟；明早结束
    let until = SoloMode.until(now: now, calendar: calendar, wake: settings.wake)
    expectEqual(local(until), "10-17 07:00", "独处模式到明早起床")
    let solo = ReminderPlan.make(now: now, calendar: calendar, settings: settings, soloUntil: until)
    let soloItems = solo.filter { $0.kind == .solo }
    expectEqual(soloItems.count, 1, "只有今晚一个 21:00 提醒")
    expectEqual(soloItems.first.map { local($0.fireDate) }, "10-16 21:00", "今晚 21:00")
    let nights = solo.filter { $0.kind == .night }.map { local($0.fireDate) }
    expectEqual(nights.first, "10-16 22:15", "今晚收尾提前到 22:15")
    expectEqual(nights.dropFirst().first, "10-17 22:45", "明晚恢复正常")

    // 22:30 打开独处模式：21:00 已过，提前后的 22:15 也已过
    let late = utc("2026-10-16T15:30:00Z")
    let lateItems = ReminderPlan.make(now: late, calendar: calendar, settings: settings,
                                      soloUntil: SoloMode.until(now: late, calendar: calendar, wake: settings.wake))
    expectEqual(lateItems.filter { $0.kind == .solo }.count, 0, "21:00 已过")
    expectEqual(lateItems.first { $0.kind == .night }.map { local($0.fireDate) }, "10-17 22:45", "今晚的收尾已过，下一个是明晚")

    // 凌晨 1 点：独处模式到今早 7:00
    let small = utc("2026-10-16T18:00:00Z") // 越南 10-17 01:00
    expectEqual(local(SoloMode.until(now: small, calendar: calendar, wake: settings.wake)), "10-17 07:00", "凌晨打开到当天早上")

    // 全部关掉
    var off = settings
    off.nightOn = false
    off.morningOn = false
    off.weeklyOn = false
    expectEqual(ReminderPlan.make(now: now, calendar: calendar, settings: off, soloUntil: nil).count, 0, "全部关闭没有提醒")

    // 补记默认时间
    let morning = utc("2026-10-17T00:30:00Z") // 越南 07:30
    expectEqual(local(BackfillDefault.date(now: morning, calendar: calendar)), "10-16 23:00", "早上补记默认昨晚 23:00")
    expectEqual(BackfillDefault.date(now: now, calendar: calendar), now, "晚上补记默认现在")
}

// MARK: BaseSummary / Rhythm / ReviewQueue

do {
    let days = [
        DaySnapshot(localDate: "2026-10-16", sleepMinutes: 420, mitText: "报价", mitDone: true, connected: true, nightModeDone: true),
        DaySnapshot(localDate: "2026-10-15", sleepMinutes: 360, mitText: nil, mitDone: nil, connected: false, nightModeDone: false),
        DaySnapshot(localDate: "2026-10-14", sleepMinutes: nil, mitText: "客户", mitDone: false, connected: true, nightModeDone: true),
        DaySnapshot(localDate: "2026-10-01", sleepMinutes: 600, mitText: nil, mitDone: true, connected: true, nightModeDone: true),
    ]
    let workouts = [
        WorkoutSnapshot(localDate: "2026-10-16", type: .strength, minutes: 30),
        WorkoutSnapshot(localDate: "2026-10-13", type: .strength, minutes: 10),
        WorkoutSnapshot(localDate: "2026-10-12", type: .walk, minutes: 40),
        WorkoutSnapshot(localDate: "2026-10-02", type: .strength, minutes: 30),
    ]
    let base = BaseSummary.make(days: days, workouts: workouts, today: "2026-10-16")
    expectEqual(base.averageSleepMinutes, 390, "平均睡眠只算 7 天内有记录的")
    expectEqual(base.sleepDays, 2, "两天有睡眠记录")
    expectEqual(base.strength, 2, "7 天内两次力量")
    expectEqual(base.otherWorkouts, 1, "一次走路")
    expectEqual(base.mitDone, 1, "最重要的事完成一天")
    expectEqual(base.connected, 2, "真人交流两天")
    expectEqual(base.nightMode, 2, "Night Mode 两天")
    expectEqual(BaseSummary.make(days: [], workouts: [], today: "2026-10-16").averageSleepMinutes, nil, "没有记录")

    expect(Rhythm.shouldNudgeStrength(lastStrengthDate: nil, today: "2026-10-16"), "从没练过：提醒")
    expect(Rhythm.shouldNudgeStrength(lastStrengthDate: "2026-10-13", today: "2026-10-16"), "隔了 3 天：提醒")
    expect(!Rhythm.shouldNudgeStrength(lastStrengthDate: "2026-10-14", today: "2026-10-16"), "隔了 2 天：不提醒")
    expect(!Rhythm.shouldNudgeStrength(lastStrengthDate: "2026-10-16", today: "2026-10-16"), "今天练了：不提醒")

    let now = utc("2026-10-17T00:30:00Z")
    let lastNight = EventSnapshot(startedAt: utc("2026-10-16T16:20:00Z"), tzOffsetMinutes: vietnam, source: .backfill,
                                  stage: .watched, leftEnvironment: false, triggers: [.alone, .instagram, .bored], place: .hotel)
    expect(ReviewQueue.needsReview(lastNight, boundaries: .default, now: now), "昨晚走进内圈：需要复盘")
    var reviewed = lastNight
    reviewed.reviewed = true
    expect(!ReviewQueue.needsReview(reviewed, boundaries: .default, now: now), "复盘过的不再出现")
    var mild = lastNight
    mild.stage = .masturbated
    expect(!ReviewQueue.needsReview(mild, boundaries: .default, now: now), "不在内圈不需要复盘")
    expect(!ReviewQueue.needsReview(lastNight, boundaries: .default, now: now.addingTimeInterval(3 * 86_400)), "太久以前的不再出现")
    expectEqual(ReviewQueue.condition(for: lastNight), "深夜 · 酒店 · 独处、Instagram", "预案条件最多两个触发")
    expectEqual(ReviewQueue.cutOptions(for: .watched), [.stimulus, .searched], "截断点只能比这次更早")
    expectEqual(ReviewQueue.cutOptions(for: .stimulus), [], "第 0 步没有更早的截断点")
}

// MARK: Vocabulary

do {
    expectEqual(Stage.allCases.map(\.rawValue), [0, 1, 2, 3, 4], "步骤编号连续")
    expect(!Stage.configurable.contains(.stimulus), "第 0 步不出现在边界设置里")
    expectEqual(Set(Trigger.allCases.map(\.rawValue)).count, Trigger.allCases.count, "触发编码不重复")
    expectEqual(Trigger.instagram.order, 3, "触发顺序和需求一致")
    expect(!Trigger.allCases.map(\.label).contains("深夜"), "深夜由时间自动算，不作为标签")
    expect(!Trigger.allCases.map(\.label).contains("酒店"), "酒店放在地点里")
}

print("\(checks - failures)/\(checks) checks passed")
if failures > 0 {
    exit(1)
}
