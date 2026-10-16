import AppIntents

/// 让"开始 Dayu"出现在 Siri、聚焦搜索、快捷指令和操作按钮里。
struct DayuShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartUrgeIntent(),
            phrases: [
                "开始 \(.applicationName)",
                "\(.applicationName) 开始",
            ],
            shortTitle: "开始",
            systemImageName: "water.waves"
        )
    }
}
