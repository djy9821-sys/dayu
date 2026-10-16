import SwiftUI

/// 深色、安静的配色。夜里是主战场，界面不能刺眼。
/// 全 App 不用红色：没有任何东西是"错误"。
enum Theme {
    static let background = Color(red: 0.055, green: 0.075, blue: 0.086)   // #0E1316
    static let surface = Color(red: 0.094, green: 0.122, blue: 0.137)      // #181F23
    static let surfaceRaised = Color(red: 0.133, green: 0.169, blue: 0.188) // #222B30
    static let line = Color(red: 0.204, green: 0.247, blue: 0.267)         // #343F44
    static let text = Color(red: 0.918, green: 0.933, blue: 0.937)         // #EAEEEF
    static let muted = Color(red: 0.561, green: 0.612, blue: 0.635)        // #8F9CA2
    static let river = Color(red: 0.310, green: 0.702, blue: 0.659)        // #4FB3A8
    static let riverDeep = Color(red: 0.169, green: 0.463, blue: 0.435)    // #2B766F
    static let onRiver = Color(red: 0.035, green: 0.098, blue: 0.094)      // #091918
    static let warm = Color(red: 0.851, green: 0.643, blue: 0.373)         // #D9A45F

    static let corner: CGFloat = 18
    static let pagePadding: CGFloat = 24
}

/// 每个全屏页统一的背景和边距。
struct PageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.background.ignoresSafeArea())
    }
}

extension View {
    func pageBackground() -> some View {
        modifier(PageBackground())
    }
}
