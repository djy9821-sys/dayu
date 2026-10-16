import AppIntents
import Foundation

/// App 里可以直接打开的位置。锁屏小组件、控制中心、Siri、通知都从这里进入。
enum AppRoute: String {
    case urge
    case timer
    case morning
    case evening
    case trends

    init?(url: URL) {
        guard url.scheme == "dayu", let host = url.host else { return nil }
        self.init(rawValue: host)
    }

    var url: URL {
        URL(string: "dayu://\(rawValue)")!
    }
}

/// App 启动时设置 handler；小组件扩展里不会用到。
@MainActor
enum IntentRouter {
    static var handler: ((AppRoute) -> Void)?
    static var pending: AppRoute?

    static func route(_ route: AppRoute) {
        if let handler {
            handler(route)
        } else {
            pending = route
        }
    }
}

/// "开始 Dayu"：直接进入冲动流程的第一步。
///
/// 名字保持中性：它会出现在快捷指令、操作按钮、控制中心和 Siri 里。
struct StartUrgeIntent: AppIntent {
    static let title: LocalizedStringResource = "开始 Dayu"
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentRouter.route(.urge)
        return .result()
    }
}
