import AppKit
import SwiftUI

struct BatchEditView: View {
    private struct BatchEditTarget: Hashable {
        let rowID: BatchMetadataRow.ID
        let field: BatchMetadataField
    }

    private enum SortColumn: String {
        case file
        case title
        case artist
        case album
        case releaseYear
        case genre
        case status
    }

    @Binding var rows: [BatchMetadataRow]
    @Binding var selection: Set<BatchMetadataRow.ID>
    let isLoading: Bool
    let isSaving: Bool
    let hasDraftChanges: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onReload: () -> Void
    let onDone: () -> Void

    @State private var sortColumn: SortColumn = .file
    @State private var isSortAscending = true
    @State private var lastSelectedRowID: BatchMetadataRow.ID?
    @State private var batchEditTarget: BatchEditTarget?
    @State private var batchEditValue = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            table
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Batch Edit")
                    .font(.title2.weight(.semibold))
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onReload) {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .disabled(isLoading || isSaving || hasDraftChanges)

            Button(role: .destructive, action: onDiscard) {
                Label("Discard", systemImage: "arrow.uturn.backward")
            }
            .disabled(!hasDraftChanges || isLoading || isSaving)

            Button(action: onSave) {
                Label("Save Changes", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasDraftChanges || isLoading || isSaving)

            Button(action: onDone) {
                Label("Done", systemImage: "checkmark")
            }
            .disabled(isLoading || isSaving)
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 18)
    }

    private var table: some View {
        Group {
            if rows.isEmpty {
                emptyState
            } else {
                ScrollView([.horizontal, .vertical]) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerRow
                            .background(Color(nsColor: .controlBackgroundColor))
                        Divider()

                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach($rows) { $row in
                                dataRow($row)
                                Divider()
                            }
                        }
                    }
                    .frame(minWidth: 1_280, alignment: .leading)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            sortHeader("File", column: .file, width: 320, alignment: .leading)
            sortHeader("Title", column: .title, width: 190, alignment: .leading)
            sortHeader("Artist", column: .artist, width: 190, alignment: .leading)
            sortHeader("Album", column: .album, width: 190, alignment: .leading)
            sortHeader("Year", column: .releaseYear, width: 90, alignment: .leading)
            sortHeader("Genre", column: .genre, width: 150, alignment: .leading)
            sortHeader("Status", column: .status, width: 150, alignment: .leading)
        }
        .frame(height: 34)
    }

    private func sortHeader(
        _ title: String,
        column: SortColumn,
        width: CGFloat,
        alignment: Alignment
    ) -> some View {
        Button {
            sortRows(by: column)
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                if sortColumn == column {
                    Image(systemName: isSortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
            }
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private func dataRow(_ row: Binding<BatchMetadataRow>) -> some View {
        let rowValue = row.wrappedValue

        return HStack(spacing: 0) {
            Text(rowValue.fileName)
                .lineLimit(1)
                .frame(width: 320, alignment: .leading)
                .padding(.horizontal, 8)

            editableField(.title, text: row.title, row: rowValue)
                .frame(width: 190, alignment: .leading)
                .padding(.horizontal, 8)

            editableField(.artist, text: row.artist, row: rowValue)
                .frame(width: 190, alignment: .leading)
                .padding(.horizontal, 8)

            editableField(.album, text: row.album, row: rowValue)
                .frame(width: 190, alignment: .leading)
                .padding(.horizontal, 8)

            editableField(.releaseYear, text: row.releaseYear, row: rowValue)
                .frame(width: 90, alignment: .leading)
                .padding(.horizontal, 8)

            editableField(.genre, text: row.genre, row: rowValue)
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal, 8)

            statusView(for: rowValue.status)
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal, 8)
        }
        .frame(height: 34)
        .background(selection.contains(rowValue.id) ? Color.accentColor.opacity(0.16) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectRow(rowValue)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tablecells")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(.secondary)

            Text("No batch-editable files")
                .font(.title3.weight(.semibold))

            Text("Open a folder containing supported audio files.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryText: String {
        if isLoading {
            return "Loading metadata"
        }

        if isSaving {
            return "Saving changes"
        }

        let changedCount = rows.filter(\.hasDraftChanges).count

        if changedCount > 0 {
            return "\(changedCount) unsaved change\(changedCount == 1 ? "" : "s")"
        }

        return "\(rows.count) file\(rows.count == 1 ? "" : "s") loaded"
    }

    private func statusView(for status: BatchMetadataRow.Status) -> some View {
        Text(status.displayText)
            .font(.caption)
            .foregroundStyle(statusColor(for: status))
            .lineLimit(1)
    }

    private func statusColor(for status: BatchMetadataRow.Status) -> Color {
        switch status {
        case .failed:
            .red
        case .readOnly:
            .secondary
        case .saved:
            .green
        default:
            .secondary
        }
    }

    private func editableField(_ field: BatchMetadataField, text: Binding<String>, row: BatchMetadataRow) -> some View {
        TextField(field.displayName, text: text)
            .textFieldStyle(.plain)
            .disabled(!row.isEditable || isLoading || isSaving)
            .overlay(
                RightClickCatcher {
                    showBatchEditor(for: field, row: row)
                }
            )
            .popover(
                isPresented: Binding(
                    get: { batchEditTarget == BatchEditTarget(rowID: row.id, field: field) },
                    set: { isPresented in
                        if !isPresented {
                            batchEditTarget = nil
                        }
                    }
                ),
                arrowEdge: .bottom
            ) {
                batchEditPopover(for: field)
            }
    }

    private func showBatchEditor(for field: BatchMetadataField, row: BatchMetadataRow) {
        guard row.isEditable, !isLoading, !isSaving else {
            return
        }

        if !selection.contains(row.id) {
            selection = [row.id]
        }

        batchEditValue = row.value(for: field)
        batchEditTarget = BatchEditTarget(rowID: row.id, field: field)
    }

    private func batchEditPopover(for field: BatchMetadataField) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(field.displayName)
                .font(.headline)

            TextField(field.displayName, text: $batchEditValue)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .onSubmit {
                    applyBatchEdit(field)
                }

            HStack {
                Spacer()
                Button("Cancel") {
                    batchEditTarget = nil
                }
                Button("Apply") {
                    applyBatchEdit(field)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
    }

    private func applyBatchEdit(_ field: BatchMetadataField) {
        let selectedIDs = selection.isEmpty
            ? Set(batchEditTarget.map { [$0.rowID] } ?? [])
            : selection

        for index in rows.indices where selectedIDs.contains(rows[index].id) && rows[index].isEditable {
            rows[index].setValue(batchEditValue, for: field)
        }

        batchEditTarget = nil
    }

    private func selectRow(_ row: BatchMetadataRow) {
        let modifiers = NSApp.currentEvent?.modifierFlags ?? []

        if modifiers.contains(.shift),
           let lastSelectedRowID,
           let startIndex = rows.firstIndex(where: { $0.id == lastSelectedRowID }),
           let endIndex = rows.firstIndex(where: { $0.id == row.id }) {
            let range = startIndex <= endIndex ? startIndex...endIndex : endIndex...startIndex
            selection = Set(rows[range].map(\.id))
        } else if modifiers.contains(.command) {
            if selection.contains(row.id) {
                selection.remove(row.id)
            } else {
                selection.insert(row.id)
            }
            lastSelectedRowID = row.id
        } else {
            selection = [row.id]
            lastSelectedRowID = row.id
        }
    }

    private func sortRows(by column: SortColumn) {
        if sortColumn == column {
            isSortAscending.toggle()
        } else {
            sortColumn = column
            isSortAscending = true
        }

        rows.sort { lhs, rhs in
            let result = compare(lhs, rhs, by: column)
            return isSortAscending ? result == .orderedAscending : result == .orderedDescending
        }
    }

    private func compare(_ lhs: BatchMetadataRow, _ rhs: BatchMetadataRow, by column: SortColumn) -> ComparisonResult {
        switch column {
        case .file:
            lhs.fileName.localizedStandardCompare(rhs.fileName)
        case .title:
            lhs.title.localizedStandardCompare(rhs.title)
        case .artist:
            lhs.artist.localizedStandardCompare(rhs.artist)
        case .album:
            lhs.album.localizedStandardCompare(rhs.album)
        case .releaseYear:
            lhs.releaseYear.localizedStandardCompare(rhs.releaseYear)
        case .genre:
            lhs.genre.localizedStandardCompare(rhs.genre)
        case .status:
            lhs.status.displayText.localizedStandardCompare(rhs.status.displayText)
        }
    }
}

private struct RightClickCatcher: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        RightClickView(onRightClick: onRightClick)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? RightClickView else {
            return
        }

        view.onRightClick = onRightClick
    }

    private final class RightClickView: NSView {
        var onRightClick: () -> Void

        init(onRightClick: @escaping () -> Void) {
            self.onRightClick = onRightClick
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            NSApp.currentEvent?.type == .rightMouseDown ? self : nil
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick()
        }
    }
}
