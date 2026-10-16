import SwiftUI

// MARK: 按钮

struct PrimaryButton: View {
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .opacity(0.75)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(Theme.onRiver)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(Theme.river, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

/// 不显眼的文字按钮，用于"先不用了""补记一次"这类次要操作。
struct QuietButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.footnote)
            .foregroundStyle(Theme.muted)
            .padding(.vertical, 8)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: 选择

struct Chip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(selected ? Theme.onRiver : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(selected ? Theme.river : Theme.surfaceRaised)
                )
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// 冲动强度 1–10，一排按钮。再点一次已选的数字可以取消。
struct IntensityPicker: View {
    @Binding var value: Int?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...10, id: \.self) { number in
                let selected = value == number
                Button {
                    value = selected ? nil : number
                } label: {
                    Text("\(number)")
                        .font(.subheadline.weight(selected ? .bold : .regular).monospacedDigit())
                        .foregroundStyle(selected ? Theme.onRiver : Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Theme.river : Theme.surfaceRaised)
                        )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("\(number) 分")
            }
        }
    }
}

/// 竖向的"河道"：这次走到了哪一步。选中的那一步以及之前的步骤会点亮。
struct StageChain: View {
    @Binding var selection: Stage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Stage.allCases) { stage in
                let reached = selection.map { stage.rawValue <= $0.rawValue } ?? false
                let isSelected = selection == stage
                Button {
                    selection = stage
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(reached ? Theme.river : Theme.line, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            if reached {
                                Circle()
                                    .fill(Theme.river)
                                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                            }
                        }
                        .frame(width: 22)
                        Text(stage.title)
                            .font(isSelected ? .body.weight(.semibold) : .body)
                            .foregroundStyle(reached ? Theme.text : Theme.muted)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])

                if stage != Stage.allCases.last {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(width: 2, height: 8)
                        .padding(.leading, 10)
                }
            }
        }
    }
}

// MARK: 布局

/// 自动换行的标签布局。
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(Theme.muted)
    }
}

/// 全屏流程顶部的关闭按钮。
struct FlowTopBar: View {
    var leading: String? = nil
    var leadingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let leading, let leadingAction {
                QuietButton(title: leading, action: leadingAction)
            }
            Spacer()
        }
        .frame(height: 44)
    }
}
