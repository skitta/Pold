import SwiftUI

struct ContentView: View {
    private enum DetailState: Equatable {
        case about
        case record(Int64)
        case empty
    }

    @State private var appState = AppState()
    @State private var showClipboardError = false
    @State private var clipboardErrorMessage = ""
    @State private var navigateToAbout = false
    @State private var editingRecordID: Int64?

    private var selectedRecordIDBinding: Binding<Int64?> {
        Binding(
            get: { appState.currentRecord?.id },
            set: { newID in
                guard let newID else { return }
                selectRecord(withID: newID)
            }
        )
    }

    private var detailState: DetailState {
        if navigateToAbout {
            return .about
        }
        if let record = appState.currentRecord, !record.inputs.isEmpty {
            return .record(record.id)
        }
        return .empty
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            detailContainer
        }
        .navigationTitle(toolbarTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAbout()
                } label: {
                    Label("使用说明", systemImage: "info.circle")
                }
            }

            if navigateToAbout {
                ToolbarItem(placement: .navigation) {
                    Button {
                        performDetailTransition {
                            navigateToAbout = false
                        }
                    } label: {
                        Label("返回", systemImage: "chevron.left")
                    }
                }
            }
        }
        .alert("导入失败", isPresented: $showClipboardError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(clipboardErrorMessage)
        }
    }

    private var detailContainer: some View {
        ZStack {
            switch detailState {
            case .about:
                AboutView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .record(let recordID):
                TableEditorView(appState: appState)
                    .id(recordID)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .empty:
                EmptyDetailView(
                    onImportClipboard: importClipboard,
                    onAddInput: addInput
                )
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .animation(UIAnimations.detail, value: detailState)
    }

    private var sidebarView: some View {
        HistorySidebarView(
            records: appState.recordHistory,
            selectedRecordID: selectedRecordIDBinding,
            editingRecordID: editingRecordID,
            onSelectRecord: selectRecord,
            onDeleteRecord: deleteRecord,
            onStartRename: { editingRecordID = $0 },
            onRenameRecord: renameRecord,
            onCancelRename: { editingRecordID = nil },
            onCreateRecord: createRecord
        )
    }

    private var toolbarTitle: String {
        if navigateToAbout {
            return "使用说明"
        }
        if let record = appState.currentRecord {
            return record.getDisplayName()
        }
        return "Pold"
    }

    private func selectRecord(withID id: Int64) {
        performHistoryTransition {
            appState.selectRecord(withID: id)
            navigateToAbout = false
        }
    }

    private func createRecord() {
        performHistoryTransition {
            let _ = appState.createRecord()
            navigateToAbout = false
        }
    }

    private func showAbout() {
        performDetailTransition {
            navigateToAbout = true
        }
    }

    private func addInput() {
        performHistoryTransition {
            appState.appendDefaultInputToCurrentRecord()
            navigateToAbout = false
        }
    }

    private func deleteRecord(withID id: Int64) {
        performHistoryTransition {
            appState.deleteRecord(withID: id)
        }
    }

    private func renameRecord(withID id: Int64, name: String) {
        appState.renameRecord(withID: id, name: name)
        editingRecordID = nil
    }

    private func importClipboard() {
        appState.ensureCurrentRecord()

        let result = appState.readClipboard()
        switch result {
        case .success(let inputs):
            appState.calcLoadingVolumn(inputs: inputs)
            navigateToAbout = false
        case .failure(let error):
            clipboardErrorMessage = error.localizedDescription
            showClipboardError = true
        }
    }

    private func performHistoryTransition(_ changes: () -> Void) {
        withAnimation(UIAnimations.history) {
            changes()
        }
    }

    private func performDetailTransition(_ changes: () -> Void) {
        withAnimation(UIAnimations.detail) {
            changes()
        }
    }
}

private struct HistorySidebarView: View {
    let records: [Record]
    let selectedRecordID: Binding<Int64?>
    let editingRecordID: Int64?
    let onSelectRecord: (Int64) -> Void
    let onDeleteRecord: (Int64) -> Void
    let onStartRename: (Int64) -> Void
    let onRenameRecord: (Int64, String) -> Void
    let onCancelRename: () -> Void
    let onCreateRecord: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            List(selection: selectedRecordID) {
                Section {
                    ForEach(records) { record in
                        HistoryRow(
                            record: record,
                            isEditing: editingRecordID == record.id,
                            onSelect: {
                                onSelectRecord(record.id)
                            },
                            onDelete: {
                                onDeleteRecord(record.id)
                            },
                            onStartRename: {
                                onStartRename(record.id)
                            },
                            onRename: { newName in
                                onRenameRecord(record.id, newName)
                            },
                            onCancelRename: onCancelRename
                        )
                        .tag(record.id as Int64?)
                        .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Text("记录")
                        .font(.headline)
                        .textCase(nil)
                        .padding(.bottom, 10)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            SidebarToolbarButton(systemImage: "plus", help: "新建记录", action: onCreateRecord)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }
}

private struct EmptyDetailView: View {
    let onImportClipboard: () -> Void
    let onAddInput: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("从剪贴板导入或新增数据")
                .font(.title2)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("从剪贴板导入", action: onImportClipboard)
                Button("新增一行", action: onAddInput)
            }
        }
    }
}

private struct SidebarToolbarButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            action()
        } label: {
            Label("", systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .focusable(false)
        .help(help)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
    }
}

#Preview("ContentView") {
    ContentView()
}

#Preview("History Sidebar") {
    HistorySidebarView(
        records: [
            Record(id: 1, name: "Sample A"),
            Record(id: 2, name: "Sample B")
        ],
        selectedRecordID: .constant(Int64?.some(1)),
        editingRecordID: nil,
        onSelectRecord: { _ in },
        onDeleteRecord: { _ in },
        onStartRename: { _ in },
        onRenameRecord: { _, _ in },
        onCancelRename: {},
        onCreateRecord: {}
    )
    .frame(width: 240, height: 360)
}

#Preview("Empty Detail") {
    EmptyDetailView(
        onImportClipboard: {},
        onAddInput: {}
    )
    .frame(width: 420, height: 240)
}
