import SwiftUI
import UniformTypeIdentifiers

struct MetadataEditorView: View {
    let item: AudioLibraryItem?
    @Binding var metadata: AudioMetadata
    let failedField: EditableMetadataField?
    let didFailArtworkSave: Bool
    let isEditingEnabled: Bool
    let onCommitField: (EditableMetadataField) -> Void
    let onChooseArtwork: () -> Void
    let onPasteArtwork: () -> Void
    let onDropArtwork: ([NSItemProvider]) -> Bool
    let onRemoveArtwork: () -> Void
    @FocusState private var focusedField: EditableMetadataField?
    @FocusState private var isArtworkPanelFocused: Bool
    @State private var isArtworkDropTargeted = false

    var body: some View {
        Group {
            if let item, item.isAudioFile {
                editor
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: focusedField) { oldField, newField in
            guard let oldField, oldField != newField else {
                return
            }

            onCommitField(oldField)
        }
        .onChange(of: focusedField) { _, newField in
            if newField != nil {
                isArtworkPanelFocused = false
            }
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 32) {
                        metadataFields
                            .frame(maxWidth: .infinity, alignment: .leading)

                        artworkPanel
                    }

                    VStack(alignment: .leading, spacing: 24) {
                        artworkPanel
                        metadataFields
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(metadata.fileName)
                .font(.title2.weight(.semibold))
            Text(isEditingEnabled ? "Editable metadata" : "Read-only format in v1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataFields: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 18, verticalSpacing: 14) {
            metadataRow(.fileName, text: $metadata.fileName)
            metadataRow(.title, text: $metadata.title)
            metadataRow(.artist, text: $metadata.artist)
            metadataRow(.contributingArtist, text: $metadata.contributingArtist)
            metadataRow(.album, text: $metadata.album)
            metadataRow(.releaseYear, text: $metadata.releaseYear)
            metadataRow(.composer, text: $metadata.composer)
            metadataRow(.genre, text: $metadata.genre)
            metadataEditorRow(.lyrics, text: $metadata.lyrics, minHeight: 130)
            metadataEditorRow(.description, text: $metadata.description, minHeight: 110)
            metadataRow(.vibeMood, text: $metadata.vibeMood)
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func metadataRow(_ field: EditableMetadataField, text: Binding<String>) -> some View {
        GridRow {
            fieldLabel(field.displayName)

            ZStack(alignment: .trailing) {
                TextField(field.displayName, text: text)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing, failedField == field ? 124 : 0)
                    .focused($focusedField, equals: field)
                    .disabled(!isEditingEnabled)
                    .onSubmit {
                        focusedField = nil
                    }

                if failedField == field {
                    failurePill(for: field)
                        .padding(.trailing, 7)
                }
            }
            .frame(minWidth: 280, idealWidth: 440, maxWidth: .infinity)
            .overlay {
                if failedField == field {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red, lineWidth: 1)
                }
            }
        }
    }

    private func metadataEditorRow(
        _ field: EditableMetadataField,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        GridRow(alignment: .top) {
            fieldLabel(field.displayName)
                .padding(.top, 6)

            PaddedTextEditor(text: text) {
                onCommitField(field)
            }
                .frame(minWidth: 280, idealWidth: 440, maxWidth: .infinity, minHeight: minHeight)
                .disabled(!isEditingEnabled)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(failedField == field ? Color.red : Color(nsColor: .separatorColor), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if failedField == field {
                        failurePill(for: field)
                            .padding(8)
                    }
                }
        }
    }

    private func failurePill(for field: EditableMetadataField) -> some View {
        Text(field.failureMessage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.12), in: Capsule())
            .accessibilityLabel(field.failureMessage)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.secondary)
            .frame(width: 140, alignment: .trailing)
    }

    private var artworkPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Album Artwork")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))

                    if let artworkImage {
                        Image(nsImage: artworkImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320, height: 320)
                            .opacity(isArtworkDropTargeted ? 0.55 : 1)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 42, weight: .regular))
                                .foregroundStyle(.secondary)

                            Text("No Artwork")
                                .font(.headline)

                            Text("Drag image here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Double-click to choose")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Command-V to paste")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .opacity(isArtworkDropTargeted ? 0.45 : 1)
                    }

                    if didFailArtworkSave {
                        failurePill(text: "Cannot write to file")
                            .padding(10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }
                .frame(width: 320, height: 320)
                .scaleEffect(isArtworkDropTargeted ? 1.025 : 1)
                .animation(.easeOut(duration: 0.16), value: isArtworkDropTargeted)
                .contentShape(Rectangle())
                .focusable()
                .focused($isArtworkPanelFocused)
                .onTapGesture {
                    isArtworkPanelFocused = true
                }
                .onTapGesture(count: 2) {
                    guard isEditingEnabled else {
                        return
                    }

                    isArtworkPanelFocused = true
                    onChooseArtwork()
                }
                .onDrop(
                    of: [.fileURL, .png, .jpeg, .image],
                    isTargeted: $isArtworkDropTargeted,
                    perform: { providers in
                        guard isEditingEnabled else {
                            return false
                        }

                        return onDropArtwork(providers)
                    }
                )
                .background(ArtworkPasteShortcutView(isActive: isArtworkPanelFocused, onPaste: onPasteArtwork))
                .contextMenu {
                    Button("Choose Artwork", action: onChooseArtwork)
                        .disabled(!isEditingEnabled)
                    Button("Paste Artwork", action: onPasteArtwork)
                        .disabled(!isEditingEnabled)

                    if metadata.artwork != nil {
                        Divider()
                        Button("Remove Artwork", role: .destructive, action: onRemoveArtwork)
                            .disabled(!isEditingEnabled)
                    }
                }

                Text("320 x 320 preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        didFailArtworkSave
                            ? Color.red
                            : isArtworkDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                        lineWidth: isArtworkDropTargeted || didFailArtworkSave ? 2 : 1
                    )
            }
        }
        .frame(width: 344, alignment: .topLeading)
    }

    private func failurePill(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.12), in: Capsule())
            .accessibilityLabel(text)
    }

    private var artworkImage: NSImage? {
        guard let artwork = metadata.artwork else {
            return nil
        }

        return NSImage(data: artwork)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Select an audio file")
                .font(.title3.weight(.semibold))

            Text("Metadata will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ArtworkPasteShortcutView: NSViewRepresentable {
    let isActive: Bool
    let onPaste: () -> Void

    func makeNSView(context: Context) -> PasteShortcutHostingView {
        let view = PasteShortcutHostingView()
        view.onPaste = onPaste
        view.isActive = isActive
        return view
    }

    func updateNSView(_ nsView: PasteShortcutHostingView, context: Context) {
        nsView.onPaste = onPaste
        nsView.isActive = isActive
    }

    final class PasteShortcutHostingView: NSView {
        var isActive = false
        var onPaste: () -> Void = {}

        override var acceptsFirstResponder: Bool {
            true
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            addLocalMonitorIfNeeded()
        }

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        private var monitor: Any?

        private func addLocalMonitorIfNeeded() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, isActive, event.isCommandV else {
                    return event
                }

                onPaste()
                return nil
            }
        }
    }
}

private extension NSEvent {
    var isCommandV: Bool {
        modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
            && charactersIgnoringModifiers?.lowercased() == "v"
    }
}
