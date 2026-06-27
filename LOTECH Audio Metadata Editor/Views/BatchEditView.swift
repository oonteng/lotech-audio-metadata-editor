import AppKit
import SwiftUI

struct BatchEditView: View {
    private struct BatchEditTarget: Hashable {
        let rowID: BatchMetadataRow.ID
        let field: BatchMetadataField
    }

    private enum SortColumn: String, CaseIterable {
        case file
        case title
        case artist
        case album
        case releaseYear
        case genre
        case status

        var title: String {
            switch self {
            case .file:
                "File"
            case .title:
                "Title"
            case .artist:
                "Artist"
            case .album:
                "Album"
            case .releaseYear:
                "Year"
            case .genre:
                "Genre"
            case .status:
                "Status"
            }
        }

        var defaultWidth: CGFloat {
            switch self {
            case .file:
                320
            case .title, .artist, .album:
                190
            case .releaseYear:
                90
            case .genre, .status:
                150
            }
        }

        var minimumWidth: CGFloat {
            switch self {
            case .file:
                180
            case .releaseYear:
                70
            default:
                110
            }
        }

        static var defaultWidths: [SortColumn: CGFloat] {
            Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.defaultWidth) })
        }
    }

    @Binding var rows: [BatchMetadataRow]
    @Binding var selection: Set<BatchMetadataRow.ID>
    let isLoading: Bool
    let isSaving: Bool
    let hasDraftChanges: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onReload: () -> Void

    @State private var sortColumn: SortColumn = .file
    @State private var isSortAscending = true
    @State private var columnWidths = SortColumn.defaultWidths
    @State private var resizeStartWidths: [SortColumn: CGFloat] = [:]
    @State private var lastSelectedRowID: BatchMetadataRow.ID?
    @State private var batchEditTarget: BatchEditTarget?
    @State private var batchEditValue = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            table
            Spacer(minLength: 0)
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
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 10)
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
                    .frame(width: tableWidth, alignment: .topLeading)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 0)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(SortColumn.allCases, id: \.self) { column in
                sortHeader(column)
            }
        }
        .frame(height: 34)
    }

    private func sortHeader(_ column: SortColumn) -> some View {
        ZStack(alignment: .trailing) {
            Button {
                sortRows(by: column)
            } label: {
                HStack(spacing: 4) {
                    Text(column.title)
                        .font(.caption.weight(.semibold))
                    if sortColumn == column {
                        Image(systemName: isSortAscending ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .frame(width: width(for: column), height: 34, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            resizeHandle(for: column)
                .zIndex(2)
        }
        .frame(width: width(for: column), height: 34)
    }

    private func dataRow(_ row: Binding<BatchMetadataRow>) -> some View {
        let rowValue = row.wrappedValue

        return HStack(spacing: 0) {
            tableCell(column: .file) {
                Text(rowValue.fileName)
                    .lineLimit(1)
            }

            tableCell(column: .title) {
                editableField(.title, text: row.title, row: rowValue)
            }

            tableCell(column: .artist) {
                editableField(.artist, text: row.artist, row: rowValue)
            }

            tableCell(column: .album) {
                editableField(.album, text: row.album, row: rowValue)
            }

            tableCell(column: .releaseYear) {
                editableField(.releaseYear, text: row.releaseYear, row: rowValue)
            }

            tableCell(column: .genre) {
                editableField(.genre, text: row.genre, row: rowValue)
            }

            tableCell(column: .status) {
                statusView(for: rowValue.status)
            }
        }
        .frame(height: 34)
        .background(selection.contains(rowValue.id) ? Color.accentColor.opacity(0.16) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectRow(rowValue)
        }
    }

    private func tableCell<Content: View>(
        column: SortColumn,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, 8)
            .frame(width: width(for: column), height: 34, alignment: .leading)
            .clipped()
    }

    private func resizeHandle(for column: SortColumn) -> some View {
        ColumnResizeHandle(
            onDrag: { delta in
                if resizeStartWidths[column] == nil {
                    resizeStartWidths[column] = width(for: column)
                }

                let startWidth = resizeStartWidths[column] ?? width(for: column)
                let nextWidth = max(column.minimumWidth, startWidth + delta)
                columnWidths[column] = nextWidth
            },
            onEnd: {
                resizeStartWidths[column] = nil
            }
        )
        .frame(width: 9, height: 34)
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

    private var tableWidth: CGFloat {
        SortColumn.allCases.reduce(0) { total, column in
            total + width(for: column)
        }
    }

    private func width(for column: SortColumn) -> CGFloat {
        columnWidths[column] ?? column.defaultWidth
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

private struct ColumnResizeHandle: NSViewRepresentable {
    let onDrag: (CGFloat) -> Void
    let onEnd: () -> Void

    func makeNSView(context: Context) -> ResizeHandleView {
        ResizeHandleView(onDrag: onDrag, onEnd: onEnd)
    }

    func updateNSView(_ nsView: ResizeHandleView, context: Context) {
        nsView.onDrag = onDrag
        nsView.onEnd = onEnd
    }

    final class ResizeHandleView: NSView {
        var onDrag: (CGFloat) -> Void
        var onEnd: () -> Void
        private var startX: CGFloat?
        private var trackingAreaRef: NSTrackingArea?

        init(onDrag: @escaping (CGFloat) -> Void, onEnd: @escaping () -> Void) {
            self.onDrag = onDrag
            self.onEnd = onEnd
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            if let trackingAreaRef {
                removeTrackingArea(trackingAreaRef)
            }

            let area = NSTrackingArea(
                rect: bounds,
                options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            trackingAreaRef = area
            addTrackingArea(area)
        }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            NSColor.separatorColor.setFill()
            NSRect(x: bounds.maxX - 1, y: 0, width: 1, height: bounds.height).fill()
        }

        override func mouseEntered(with event: NSEvent) {
            NSCursor.resizeLeftRight.push()
        }

        override func mouseExited(with event: NSEvent) {
            NSCursor.pop()
        }

        override func mouseDown(with event: NSEvent) {
            startX = event.locationInWindow.x
        }

        override func mouseDragged(with event: NSEvent) {
            guard let startX else {
                return
            }

            onDrag(event.locationInWindow.x - startX)
        }

        override func mouseUp(with event: NSEvent) {
            startX = nil
            onEnd()
        }
    }
}
