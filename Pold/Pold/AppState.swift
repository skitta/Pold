import Foundation

@Observable
final class AppState {
    var recordHistory: [Record] = []
    var currentIndex: Int?
    private var pendingSaveTask: Task<Void, Never>?
    private let isRunningInXcodePreviewHost =
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"

    var currentRecord: Record? {
        get {
            guard let index = currentIndex, index < recordHistory.count else { return nil }
            return recordHistory[index]
        }
        set {
            guard let newValue, let index = currentIndex, index < recordHistory.count else { return }
            recordHistory[index] = newValue
        }
    }

    private let storeURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Pold", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }()

    init() {
        if isRunningInXcodePreviewHost == false {
            loadFromStore()
        }
        if !recordHistory.isEmpty && currentIndex == nil {
            currentIndex = 0
        }
    }

    func createRecord() -> Record {
        let record = Record(id: nextRecordID())
        recordHistory.insert(record, at: 0)
        currentIndex = 0
        saveToStore()
        return record
    }

    @discardableResult
    func ensureCurrentRecord() -> Record {
        if let currentRecord {
            return currentRecord
        }
        return createRecord()
    }

    func setIndex(_ index: Int) {
        guard index >= 0 && index < recordHistory.count else { return }
        currentIndex = index
    }

    func selectRecord(withID id: Int64) {
        guard let index = recordHistory.firstIndex(where: { $0.id == id }) else { return }
        setIndex(index)
    }

    func deleteHistory(at index: Int) {
        guard index >= 0 && index < recordHistory.count else { return }
        recordHistory.remove(at: index)
        if recordHistory.isEmpty {
            currentIndex = nil
        } else if let current = currentIndex {
            if index < current {
                currentIndex = current - 1
            } else if index == current {
                currentIndex = min(current, recordHistory.count - 1)
            }
        }
        saveToStore()
    }

    func deleteRecord(withID id: Int64) {
        guard let index = recordHistory.firstIndex(where: { $0.id == id }) else { return }
        deleteHistory(at: index)
    }

    func clearHistory() {
        recordHistory.removeAll()
        currentIndex = nil
        saveToStore()
    }

    func renameHistory(at index: Int, name: String) {
        guard index >= 0 && index < recordHistory.count else { return }
        recordHistory[index].setName(name)
        saveToStore()
    }

    func renameRecord(withID id: Int64, name: String) {
        guard let index = recordHistory.firstIndex(where: { $0.id == id }) else { return }
        renameHistory(at: index, name: name)
    }

    func replaceCurrentRecord(_ record: Record, saveImmediately: Bool = false) {
        currentRecord = record
        if saveImmediately {
            saveToStore()
        } else {
            scheduleSave()
        }
    }

    func readClipboard() -> Result<[InputData], ClipboardService.ClipboardError> {
        ClipboardService.readClipboard()
    }

    func calcLoadingVolumn(inputs: [InputData]) {
        guard var record = currentRecord else { return }
        record.setInputs(inputs)
        record.modifiedInputVolumn()
        replaceCurrentRecord(record, saveImmediately: true)
    }

    func updateLoadingVolumn(target: UInt64) {
        guard var record = currentRecord else { return }
        record.setTarget(target)
        record.modifiedInputVolumn()
        replaceCurrentRecord(record)
    }

    func appendDefaultInputToCurrentRecord() {
        var record = ensureCurrentRecord()
        var newInput = InputData(key: "New", value: 0)
        newInput.volumn = 1
        var updatedInputs = record.inputs
        updatedInputs.append(newInput)
        record.setInputs(updatedInputs)
        record.modifiedInputVolumn()
        replaceCurrentRecord(record)
    }

    private func nextRecordID() -> Int64 {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let highestExistingID = recordHistory.reduce(Int64.min) { max($0, $1.id) }
        return max(now, highestExistingID + 1)
    }

    private func loadFromStore() {
        do {
            let data = try Data(contentsOf: storeURL)
            recordHistory = try JSONDecoder().decode([Record].self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // First run, no history file yet - expected
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveToStore() {
        guard isRunningInXcodePreviewHost == false else { return }
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        do {
            let data = try JSONEncoder().encode(recordHistory)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    private func scheduleSave() {
        guard isRunningInXcodePreviewHost == false else { return }
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, Task.isCancelled == false else { return }
            self.saveToStore()
        }
    }
}
