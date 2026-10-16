import SwiftUI

/// 止损页：走进内圈时出现。不追问，不分析，分析留给明天。
struct StopView: View {
    let stage: Stage
    let night: Bool

    @Environment(AppFlow.self) private var flow
    @State private var checked: Set<Int> = []

    private var items: [String] { night ? Copy.stopNight : Copy.stopDay }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 40)

            Text(Copy.stopTitle)
                .font(.title.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(Copy.stopSubtitle)
                .font(.body)
                .foregroundStyle(Theme.muted)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button {
                        if checked.contains(index) {
                            checked.remove(index)
                        } else {
                            checked.insert(index)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: checked.contains(index) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(checked.contains(index) ? Theme.river : Theme.line)
                            Text(item)
                                .font(.title3)
                                .foregroundStyle(Theme.text)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 32)

            if stage == .soughtServices {
                Text(Copy.pepNote)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 24)
            }

            Spacer(minLength: 24)

            PrimaryButton(title: Copy.stopButton(night: night)) {
                flow.finishSaved()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
    }
}

/// 保存后的确认页。
struct SavedView: View {
    @Environment(AppFlow.self) private var flow

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.river)
            Text(Copy.saved)
                .font(.title2.weight(.semibold))
                .padding(.top, 16)
            Spacer()
            PrimaryButton(title: flow.afterSaved == nil ? "回到生活" : "继续") {
                flow.finishSaved()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Theme.pagePadding)
    }
}
