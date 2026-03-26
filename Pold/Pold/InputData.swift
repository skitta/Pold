import Foundation

struct InputData: Codable, Identifiable {
    let id: UUID
    var key: String
    var name: String
    var volumn: UInt8
    var value: Double
    var modifiedVolumn: UInt64?

    init(key: String, name: String? = nil, volumn: UInt8 = 0, value: Double, modifiedVolumn: UInt64? = nil) {
        self.id = UUID()
        self.key = key
        self.name = name ?? key
        self.volumn = volumn
        self.value = value
        self.modifiedVolumn = modifiedVolumn
    }

    static func parseImageJLine(_ line: String) -> InputData? {
        let parts = line.split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 2,
              let value = Double(parts[1]) else {
            return nil
        }
        let key = String(parts[0])
        return InputData(key: key, value: value)
    }

    func valuePerVolumn() -> UInt64? {
        guard volumn > 0 else { return nil }
        return UInt64((value / Double(volumn)).rounded())
    }

    mutating func calcModifiedVolumn(targetValue: UInt64) {
        guard let valuePerVolumn = valuePerVolumn(), valuePerVolumn > 0 else {
            modifiedVolumn = nil
            return
        }
        modifiedVolumn = targetValue / valuePerVolumn
    }

    func getValue() -> Double {
        value
    }
}
