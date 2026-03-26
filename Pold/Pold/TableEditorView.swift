import SwiftUI

struct TableEditorView: View {
    let appState: AppState

    @State private var selectedInputId: UUID?
    @State private var targetDouble: Double = 0

    private var currentRecord: Record? {
        appState.currentRecord
    }

    private var localInputs: [InputData] {
        currentRecord?.inputs ?? []
    }

    private var stats: (min: UInt64, max: UInt64, avg: UInt64) {
        (
            min: currentRecord?.minValue ?? 0,
            max: currentRecord?.maxValue ?? 0,
            avg: currentRecord?.targetValue ?? 0
        )
    }

    private var sliderRange: ClosedRange<Double> {
        let min = currentRecord?.minValue.map { Double($0) } ?? 0
        let max = currentRecord?.maxValue.map { Double($0) } ?? 100
        return min...max
    }

    var body: some View {
        VStack(spacing: 0) {
            inputTable
            bottomControls
            statsBar
        }
        .onAppear {
            syncTargetFromRecord()
        }
        .onChange(of: appState.currentRecord?.id) { _, _ in
            syncTargetFromRecord()
        }
        .onChange(of: appState.currentRecord?.targetValue) { _, _ in
            syncTargetFromRecord()
        }
    }

    @ViewBuilder
    private var inputTable: some View {
        Table(of: InputData.self, selection: $selectedInputId) {
            TableColumn("名称") { input in
                DraftTextField(
                    value: input.name,
                    placeholder: "名称",
                    alignment: .leading
                ) { newName in
                    let normalized = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let committedName = normalized.isEmpty ? input.name : normalized
                    updateInput(id: input.id) { $0.name = committedName }
                    return committedName
                }
            }
            .width(min: 80, ideal: 120)
            TableColumn("体积") { input in
                DraftTextField(
                    value: String(input.volumn),
                    placeholder: "体积",
                    alignment: .trailing
                ) { newVol in
                    let committedVolumn = UInt8(newVol) ?? input.volumn
                    updateInput(id: input.id) { $0.volumn = committedVolumn }
                    return String(committedVolumn)
                }
            }
            .width(min: 60, ideal: 80)
            TableColumn("值") { input in
                DraftTextField(
                    value: formattedValue(input.value),
                    placeholder: "值",
                    alignment: .trailing
                ) { newValue in
                    let committedValue = Double(newValue) ?? input.value
                    updateInput(id: input.id) { $0.value = committedValue }
                    return formattedValue(committedValue)
                }
            }
            .width(min: 60, ideal: 80)
            TableColumn("修改后体积") { input in
                Text(input.modifiedVolumn.map { String($0) } ?? "-")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 120)
        } rows: {
            ForEach(localInputs) { input in
                TableRow(input)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var bottomControls: some View {
        HStack(spacing: 12) {
            Button {
                appState.appendDefaultInputToCurrentRecord()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .controlSize(.regular)

            Button {
                guard var rec = appState.currentRecord else { return }
                var updatedInputs = rec.inputs
                if let id = selectedInputId {
                    updatedInputs.removeAll { $0.id == id }
                    selectedInputId = nil
                }
                rec.setInputs(updatedInputs)
                rec.modifiedInputVolumn()
                appState.replaceCurrentRecord(rec)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .controlSize(.regular)
            .disabled(selectedInputId == nil)

            Spacer()

            if currentRecord?.minValue != nil && currentRecord?.maxValue != nil {
                Text("目标值: \(Int(targetDouble))")
                    .monospacedDigit()
                Slider(value: $targetDouble, in: sliderRange)
                    .onChange(of: targetDouble) { _, newValue in
                        appState.updateLoadingVolumn(target: UInt64(newValue.rounded()))
                    }
                .frame(width: 200)
            }
        }
        .padding(.horizontal)
        .frame(minHeight: 42)
        .background(toolbarBackground)
    }

    private var statsBar: some View {
        HStack {
            Text("最小值: \(stats.min)")
            Text("最大值: \(stats.max)")
            Text("平均值: \(stats.avg)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .frame(minHeight: 42, alignment: .leading)
        .background(toolbarBackground)
    }

    private func syncTargetFromRecord() {
        targetDouble = Double(currentRecord?.targetValue ?? 0)
    }

    private func updateInput(id: UUID, _ update: (inout InputData) -> Void) {
        guard var rec = appState.currentRecord else { return }
        var updatedInputs = rec.inputs
        if let idx = updatedInputs.firstIndex(where: { $0.id == id }) {
            update(&updatedInputs[idx])
        }
        rec.setInputs(updatedInputs)
        rec.modifiedInputVolumn()
        appState.replaceCurrentRecord(rec)
    }

    private func formattedValue(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...2))
                .grouping(.never)
        )
    }

    private var toolbarBackground: some View {
        Color(nsColor: .controlBackgroundColor)
    }
}

private struct DraftTextField: View {
    let value: String
    let placeholder: String
    let alignment: TextAlignment
    let commit: (String) -> String

    @FocusState private var isFocused: Bool
    @State private var draft = ""

    var body: some View {
        TextField(placeholder, text: $draft)
            .textFieldStyle(.plain)
            .multilineTextAlignment(alignment)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isFocused ? Color.accentColor.opacity(0.14) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isFocused ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
            }
            .focused($isFocused)
            .onAppear {
                draft = value
            }
            .onChange(of: value) { _, newValue in
                if !isFocused {
                    draft = newValue
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    commitDraft()
                }
            }
            .onSubmit {
                commitDraft()
            }
    }

    private func commitDraft() {
        draft = commit(draft)
    }
}
