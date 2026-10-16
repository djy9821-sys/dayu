import SwiftUI
import WidgetKit

@main
struct DayuWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UrgeLockWidget()
        TimerLiveActivity()
        UrgeControl()
    }
}

/// 小组件里用的颜色（和 App 里的 Theme 一致）。
enum WidgetPalette {
    static let background = Color(red: 0.055, green: 0.075, blue: 0.086)
    static let text = Color(red: 0.918, green: 0.933, blue: 0.937)
    static let muted = Color(red: 0.561, green: 0.612, blue: 0.635)
    static let river = Color(red: 0.310, green: 0.702, blue: 0.659)
}
