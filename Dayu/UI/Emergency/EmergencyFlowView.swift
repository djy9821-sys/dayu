import SwiftUI

/// 全屏流程的容器：按当前步骤显示对应的页面。
struct EmergencyFlowView: View {
    @Environment(AppFlow.self) private var flow

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Group {
                switch flow.step {
                case .steps:
                    StepsView()
                case .timer:
                    TimerView()
                case .done:
                    DoneView()
                case .log(let mode):
                    LogView(mode: mode)
                case .stop(let stage, let night):
                    StopView(stage: stage, night: night)
                case .saved:
                    SavedView()
                }
            }
            .transition(.opacity)
        }
        .foregroundStyle(Theme.text)
    }
}
