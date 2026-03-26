import Foundation

struct Record: Codable, Identifiable {
    private static let displayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    let id: Int64
    var name: String?
    var inputs: [InputData]
    var minValue: UInt64?
    var maxValue: UInt64?
    var targetValue: UInt64?

    init(
        id: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        name: String? = nil,
        inputs: [InputData] = [],
        minValue: UInt64? = nil,
        maxValue: UInt64? = nil,
        targetValue: UInt64? = nil
    ) {
        self.id = id
        self.name = name
        self.inputs = inputs
        self.minValue = minValue
        self.maxValue = maxValue
        self.targetValue = targetValue
    }

    mutating func setInputs(_ inputs: [InputData], preserveTarget: Bool = true) {
        let (minStat, maxStat, avg) = Self.computeStatistics(inputs)
        let previousTarget = targetValue
        minValue = minStat
        maxValue = maxStat
        self.inputs = inputs

        guard !inputs.isEmpty else {
            targetValue = nil
            return
        }

        if preserveTarget, let previousTarget {
            targetValue = Swift.min(
                Swift.max(previousTarget, minValue ?? previousTarget),
                maxValue ?? previousTarget
            )
        } else {
            targetValue = avg
        }
    }

    mutating func setTarget(_ target: UInt64) {
        targetValue = target
    }

    mutating func modifiedInputVolumn() {
        guard let target = targetValue else { return }
        for i in inputs.indices {
            inputs[i].calcModifiedVolumn(targetValue: target)
        }
    }

    func getDisplayName() -> String {
        if let name = name {
            return name
        }
        let date = Date(timeIntervalSince1970: Double(id) / 1000)
        return Self.displayNameFormatter.string(from: date)
    }

    mutating func setName(_ name: String) {
        self.name = name
    }

    static func computeStatistics(_ inputs: [InputData]) -> (min: UInt64, max: UInt64, avg: UInt64) {
        guard !inputs.isEmpty else { return (0, 0, 0) }
        let values = inputs.map { $0.getValue() }
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        let sum = values.reduce(0, +)
        let avgVal = sum / Double(inputs.count)
        return (
            UInt64(minVal.rounded()),
            UInt64(maxVal.rounded()),
            UInt64(avgVal.rounded())
        )
    }
}
