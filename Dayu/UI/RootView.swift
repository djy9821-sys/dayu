import SwiftUI

enum AppTab: Hashable {
    case today
    case trends
    case me
}

/// 最外层。叠放顺序（从下到上）：三个 Tab → 全屏流程 → 锁屏 → 后台遮挡。
/// 全屏流程不用系统的 fullScreenCover，这样锁屏一定能盖在它上面。
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var flow = AppFlow.shared
    @State private var lock = AppLock()
    @State private var tab: AppTab = .today

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                TodayView()
                    .tabItem { Label("今天", systemImage: "sun.max") }
                    .tag(AppTab.today)
                TrendsView()
                    .tabItem { Label("趋势", systemImage: "water.waves") }
                    .tag(AppTab.trends)
                MeView()
                    .tabItem { Label("我的", systemImage: "person.crop.circle") }
                    .tag(AppTab.me)
            }
            .tint(Theme.river)

            if flow.isPresented {
                EmergencyFlowView()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            if lock.isLocked {
                LockView(lock: lock)
                    .transition(.opacity)
                    .zIndex(2)
            }

            if scenePhase != .active {
                PrivacyCover()
                    .zIndex(3)
            }
        }
        .environment(flow)
        .animation(.easeInOut(duration: 0.25), value: flow.isPresented)
        .animation(.easeInOut(duration: 0.2), value: lock.isLocked)
        .onChange(of: scenePhase) { _, newPhase in
            lock.handle(phase: newPhase)
        }
        .onAppear {
            #if DEBUG
            DemoMode.apply(flow: flow) { tab = $0 }
            #endif
        }
    }
}

/// 切到后台时盖住内容：多任务切换界面里看不到任何记录。
struct PrivacyCover: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.riverDeep)
        }
    }
}

struct LockView: View {
    let lock: AppLock

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "water.waves")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Theme.river)
                Text("Dayu")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Button {
                    Task { await lock.unlock() }
                } label: {
                    Text("解锁")
                        .font(.headline)
                        .foregroundStyle(Theme.onRiver)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(Theme.river, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 8)
            }
        }
        .task {
            await lock.unlock()
        }
    }
}
