import SwiftUI
import Observation

enum LogMode: Equatable {
    /// 冲动计时结束后的记录
    case afterEmergency
    /// 事后补记
    case backfill
}

/// 全屏流程里的每一页。
enum FlowStep: Equatable {
    case steps
    case timer
    case done
    case log(LogMode)
    case stop(stage: Stage, night: Bool)
    case saved
    case morning
    case evening
    case nightMode
    case workout
}

/// 管理所有全屏流程：冲动、补记、晨间打卡、晚间小结、Night Mode、运动。
@MainActor
@Observable
final class AppFlow {
    static let shared = AppFlow()

    var isPresented = false
    var step: FlowStep = .steps
    var tab: AppTab = .today
    private(set) var draft: EmergencyDraft?

    /// 补记时预填的时间（例如早上补记昨晚）
    var backfillPreset: Date?
    /// 记录保存后回到哪一页（例如从晨间打卡去补记，记完回到晨间打卡）
    var afterSaved: FlowStep?

    init() {
        draft = DraftStore.load()
    }

    // MARK: 入口

    func open(_ route: AppRoute) {
        switch route {
        case .urge:
            startUrge()
        case .timer:
            if draft?.hasStartedTimer == true {
                startUrge()
            }
        case .morning:
            present(.morning)
        case .evening:
            present(.evening)
        case .trends:
            close()
            tab = .trends
        }
    }

    /// 首页大按钮。如果上一次还在计时，就回到计时；时间已到，就去结束页。
    func startUrge() {
        afterSaved = nil
        if let draft, draft.hasStartedTimer {
            present(draft.isTimerRunning(at: .now) ? .timer : .done)
        } else {
            setDraft(draft ?? EmergencyDraft(startedAt: .now))
            present(.steps)
        }
    }

    func startBackfill(preset: Date? = nil, returnTo: FlowStep? = nil) {
        backfillPreset = preset
        afterSaved = returnTo
        if isPresented {
            go(.log(.backfill))
        } else {
            present(.log(.backfill))
        }
    }

    func present(_ newStep: FlowStep) {
        step = newStep
        isPresented = true
    }

    /// 点了"时间到了"的通知。
    func resumeFromNotification() {
        guard let draft, draft.hasStartedTimer else { return }
        present(draft.isTimerRunning(at: .now) ? .timer : .done)
    }

    // MARK: 计时

    func startTimer(minutes: Int, leftEnvironment: Bool) {
        var current = draft ?? EmergencyDraft(startedAt: .now)
        current.startTimer(at: .now, minutes: minutes, leftEnvironment: leftEnvironment)
        setDraft(current)
        go(.timer)
        scheduleEndNotification()
        startActivity()
    }

    func extendTimer(minutes: Int) {
        guard var current = draft else { return }
        Notifier.shared.cancel(id: current.notificationID)
        current.notificationID = nil
        current.extendTimer(at: .now, minutes: minutes)
        setDraft(current)
        go(.timer)
        scheduleEndNotification()
        startActivity()
    }

    /// 冲动已经下去了，提前结束计时。
    func endTimerEarly() {
        Notifier.shared.cancel(id: draft?.notificationID)
        updateDraft { $0.notificationID = nil }
        TimerActivity.endAll()
        go(.done)
    }

    /// 倒计时走完。
    func timerFinished() {
        TimerActivity.endAll()
        go(.done)
    }

    private func startActivity() {
        guard let started = draft?.timerStartedAt, let ends = draft?.timerEndsAt else { return }
        TimerActivity.start(startedAt: started, endsAt: ends)
    }

    /// 回到前台时：没有进行中的计时，就收起锁屏上的倒计时。
    func syncActivity() {
        if draft?.isTimerRunning(at: .now) != true {
            TimerActivity.endAll()
        }
    }

    private func scheduleEndNotification() {
        guard let endsAt = draft?.timerEndsAt else { return }
        Task {
            guard await Notifier.shared.requestAuthorizationIfNeeded() else { return }
            let id = await Notifier.shared.scheduleTimerEnd(at: endsAt)
            // 期间如果流程已经被清掉或时间被改过，就撤回这条通知
            if let current = draft, current.timerEndsAt == endsAt {
                updateDraft { $0.notificationID = id }
            } else {
                Notifier.shared.cancel(id: id)
            }
        }
    }

    // MARK: 草稿

    func updateDraft(_ change: (inout EmergencyDraft) -> Void) {
        guard var current = draft else { return }
        change(&current)
        setDraft(current)
    }

    func setDraft(_ newValue: EmergencyDraft?) {
        draft = newValue
        DraftStore.save(newValue)
    }

    func clearDraft() {
        Notifier.shared.cancel(id: draft?.notificationID)
        TimerActivity.endAll()
        setDraft(nil)
    }

    // MARK: 导航

    func go(_ newStep: FlowStep) {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = newStep
        }
    }

    /// 记录完成后：回到来的地方，或者关掉流程。
    func finishSaved() {
        if let next = afterSaved {
            afterSaved = nil
            backfillPreset = nil
            go(next)
        } else {
            close()
        }
    }

    /// 关掉全屏流程但保留草稿（例如"稍后再记"）。
    func close() {
        backfillPreset = nil
        afterSaved = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            isPresented = false
        }
    }

    /// 不用了：丢掉还没开始计时的这次。
    func discardAndClose() {
        clearDraft()
        close()
    }
}
