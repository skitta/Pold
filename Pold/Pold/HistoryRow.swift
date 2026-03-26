import SwiftUI

struct HistoryRow: View {
    let record: Record
    let isEditing: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onStartRename: () -> Void
    let onRename: (String) -> Void
    let onCancelRename: () -> Void

    @State private var isHovered = false
    @State private var renameText = ""
    @FocusState private var isRenameFieldFocused: Bool

    var body: some View {
        HStack {
            if isEditing {
                TextField("名称", text: $renameText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isRenameFieldFocused)
                    .onSubmit {
                        commitRename()
                    }
                Button {
                    commitRename()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help("保存")
                Button {
                    cancelRename()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help("取消")
            } else {
                HStack {
                    Text(record.getDisplayName())
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("删除记录")
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
                }
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .onTapGesture(perform: onSelect)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            withAnimation(UIAnimations.hover) {
                isHovered = hovering
            }
        }
        .onAppear {
            renameText = record.name ?? ""
        }
        .onChange(of: isEditing) { _, editing in
            renameText = record.name ?? ""
            if editing {
                isRenameFieldFocused = true
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onStartRename()
            }
        )
        .onExitCommand {
            if isEditing {
                cancelRename()
            }
        }
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        onRename(trimmed)
    }

    private func cancelRename() {
        renameText = record.name ?? ""
        onCancelRename()
    }
}
