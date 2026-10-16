import AppIntents
import SwiftUI
import WidgetKit

/// 控制中心（和锁屏底部）的按钮：按一下直接进入第一步。
struct UrgeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.djy9821.dayu.control") {
            ControlWidgetButton(action: StartUrgeIntent()) {
                Label("Dayu", systemImage: "water.waves")
            }
        }
        .displayName("Dayu")
        .description("直接进入第一步。")
    }
}
