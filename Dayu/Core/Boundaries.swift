import Foundation

/// 三圈模型里的"内圈"：走到这些步骤时，App 弹出止损页。
///
/// App 永远不说"失败"。边界只决定一件事：什么时候帮你停下来。
/// 默认内圈是"观看色情内容"和"寻找性服务"；自慰默认不算越界，可以在"我的"里改。
struct Boundaries: Equatable {
    var innerStages: Set<Stage>

    static let `default` = Boundaries(innerStages: [.watched, .soughtServices])

    init(innerStages: Set<Stage>) {
        self.innerStages = innerStages.subtracting([.stimulus])
    }

    /// 从设置里保存的字符串还原，例如 "2,4"。空字符串表示一个都不算。
    init(storage: String) {
        let stages = storage
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .compactMap(Stage.init(rawValue:))
        self.init(innerStages: Set(stages))
    }

    var storage: String {
        innerStages.map(\.rawValue).sorted().map(String.init).joined(separator: ",")
    }

    func isInner(_ stage: Stage) -> Bool {
        innerStages.contains(stage)
    }

    func setting(_ stage: Stage, inner: Bool) -> Boundaries {
        var copy = self
        if inner {
            copy.innerStages.insert(stage)
        } else {
            copy.innerStages.remove(stage)
        }
        copy.innerStages.remove(.stimulus)
        return copy
    }
}
