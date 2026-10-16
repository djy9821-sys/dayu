import SwiftUI
import WidgetKit

/// 锁屏上的一个小圆图标：点一下直接进入第一步。
/// 只有水波图标，别人看不出用途。
struct UrgeLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.djy9821.dayu.lock", provider: StaticProvider()) { _ in
            UrgeLockWidgetView()
        }
        .configurationDisplayName("Dayu")
        .description("点一下直接进入第一步。")
        .supportedFamilies([.accessoryCircular])
    }
}

struct StaticEntry: TimelineEntry {
    let date: Date
}

struct StaticProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticEntry {
        StaticEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (StaticEntry) -> Void) {
        completion(StaticEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StaticEntry>) -> Void) {
        completion(Timeline(entries: [StaticEntry(date: .now)], policy: .never))
    }
}

struct UrgeLockWidgetView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "water.waves")
                .font(.system(size: 22, weight: .semibold))
        }
        .widgetURL(AppRoute.urge.url)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
