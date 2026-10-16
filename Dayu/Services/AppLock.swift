import SwiftUI
import LocalAuthentication
import Observation

/// Face ID / 密码锁。
///
/// 启动时上锁；切到后台超过 1 分钟再回来，也重新上锁。
/// 手机本身没设密码时锁不住，就不锁。
@MainActor
@Observable
final class AppLock {
    private(set) var isLocked: Bool
    private var backgroundedAt: Date?
    private var isAuthenticating = false

    static let relockAfter: TimeInterval = 60

    init() {
        isLocked = AppSettings.lockEnabled && !DemoMode.isActive
    }

    func handle(phase: ScenePhase) {
        switch phase {
        case .background:
            backgroundedAt = .now
        case .active:
            if let backgroundedAt,
               Date.now.timeIntervalSince(backgroundedAt) > Self.relockAfter,
               AppSettings.lockEnabled,
               !DemoMode.isActive {
                isLocked = true
            }
            backgroundedAt = nil
        default:
            break
        }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "打开 Dayu") {
                isLocked = false
            }
        } catch {
            // 取消或失败：保持锁定，用户可以再点一次
        }
    }
}
