import SwiftUI
import SwiftData

@main
struct DayuApp: App {
    private let container: ModelContainer

    init() {
        Notifier.shared.configure()

        let schema = Schema([UrgeEvent.self])
        // 只存在这台手机上：不连 iCloud，不用 App Group。
        let configuration = ModelConfiguration(
            "Dayu",
            schema: schema,
            isStoredInMemoryOnly: DemoMode.isActive,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法打开本地数据库：\(error)")
        }

        #if DEBUG
        if DemoMode.isActive {
            DemoMode.seed(container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
