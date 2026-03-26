import AppKit

struct ClipboardService {
    enum ClipboardError: Error, LocalizedError {
        case emptyClipboard
        case noValidData

        var errorDescription: String? {
            switch self {
            case .emptyClipboard:
                return "Clipboard is empty"
            case .noValidData:
                return "No valid ImageJ-style data found in clipboard"
            }
        }
    }

    static func readClipboard() -> Result<[InputData], ClipboardError> {
        guard let clipboardString = NSPasteboard.general.string(forType: .string),
              !clipboardString.isEmpty else {
            return .failure(.emptyClipboard)
        }

        let inputs = clipboardString
            .components(separatedBy: .newlines)
            .compactMap { InputData.parseImageJLine($0) }

        if inputs.isEmpty {
            return .failure(.noValidData)
        }

        return .success(inputs)
    }
}
