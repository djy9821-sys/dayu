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
}

/// 管理"我现在有冲动"和"补记"这两个全屏流程。
@MainActor
@Observable
final class AppFlow {
    static let shared = AppFlow()

    var isPresented = false
    var step: FlowStep = .steps
    private(set) var draft: EmergencyDraft?

    init() {
        draft = DraftStore.load()
    }

    // MARK: 入口

    /// 首页大按钮。如果上一次还在计时，就回到计时；时间已到，就去结束页。
    func startUrge() {
        if let draft, draft.hasStartedTimer {
            step = draft.isTimerRunning(at: .now) ? .timer : .done
        } else {
            setDraft(draft ?? EmergencyDraft(startedAt: .now))
            step = .steps
        }
        isPresented = true
    }

    func startBackfill() {
        step = .log(.backfill)
        isPresented = true
    }

    /// 点了"时间到了"的通知。
    func resumeFromNotification() {
        guard let draft, draft.hasStartedTimer else { return }
        step = draft.isTimerRunning(at: .now) ? .timer : .done
        isPresented = true
    }

    // MARK: 计时

    func startTimer(minutes: Int, leftEnvironment: Bool) {
        var current = draft ?? EmergencyDraft(startedAt: .now)
        current.startTimer(at: .now, minutes: minutes, leftEnvironment: leftEnvironment)
        setDraft(current)
        go(.timer)
        scheduleEndNotification()
    }

    func extendTimer(minutes: Int) {
        guard var current = draft else { return }
        Notifier.shared.cancel(id: current.notificationID)
        current.notificationID = nil
        current.extendTimer(at: .now, minutes: minutes)
        setDraft(current)
        go(.timer)
        scheduleEndNotification()
    }

    /// 冲动已经下去了，提前结束计时。
    func endTimerEarly() {
        Notifier.shared.cancel(id: draft?.notificationID)
        updateDraft { $0.notificationID = nil }
        go(.done)
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
        setDraft(nil)
    }

    // MARK: 导航

    func go(_ newStep: FlowStep) {
        withAnimation(.easeInOut(duration: 0.25)) {
            step = newStep
        }
    }

    /// 关掉全屏流程但保留草稿（例如"稍后再记"）。
    func close() {
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
