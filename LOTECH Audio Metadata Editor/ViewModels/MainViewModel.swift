import AppKit
import Combine
import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published var selectedItemID: AudioLibraryItem.ID? {
        didSet {
            updateMetadataForSelection()
        }
    }

    @Published var metadata = AudioMetadata.sample
    @Published private(set) var statusMessage = "Ready"
    @Published private(set) var isScanning = false
    @Published private(set) var isReadingMetadata = false
    @Published private(set) var isSavingMetadata = false
    @Published private(set) var failedMetadataField: EditableMetadataField?
    @Published private(set) var didFailArtworkSave = false

    @Published private(set) var libraryItems: [AudioLibraryItem] = []

    private let folderBookmarkService = FolderBookmarkService()
    private let metadataReaderService = AudioMetadataReaderService()
    private let metadataWriterService = AudioMetadataWriterService()
    private let artworkImageService = ArtworkImageService()
    private let fileRenameService = FileRenameService()
    private var folderScanTask: Task<Void, Never>?
    private var metadataReadTask: Task<Void, Never>?
    private var metadataSaveTask: Task<Void, Never>?
    private var lastSavedMetadata: AudioMetadata?
    private var securityScopedFolderURL: URL?
    private var didStartSecurityScopedFolderAccess = false

    deinit {
        folderScanTask?.cancel()
        metadataReadTask?.cancel()
        metadataSaveTask?.cancel()
        MainActor.assumeIsolated {
            stopAccessingCurrentFolder()
        }
    }

    init() {
        Task {
            await reopenLastFolderIfPossible()
        }
    }

    var selectedItem: AudioLibraryItem? {
        guard let selectedItemID else {
            return nil
        }

        return libraryItems.firstItem(withID: selectedItemID)
    }

    func openFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Open Folder"
        panel.message = "Choose a folder containing audio files."

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        loadFolder(at: folderURL, rememberFolder: true)
    }

    private func updateMetadataForSelection() {
        guard let audioFile = selectedItem?.audioFile else {
            metadataReadTask?.cancel()
            isReadingMetadata = false
            lastSavedMetadata = nil
            return
        }

        metadata = audioFile.metadata
        lastSavedMetadata = audioFile.metadata
        isReadingMetadata = true
        statusMessage = "Loading metadata"

        metadataReadTask?.cancel()
        metadataReadTask = Task {
            do {
                let loadedMetadata = try await metadataReaderService.metadata(for: audioFile)

                guard !Task.isCancelled else {
                    return
                }

                metadata = loadedMetadata
                lastSavedMetadata = loadedMetadata
                failedMetadataField = nil
                didFailArtworkSave = false
                isReadingMetadata = false
                statusMessage = loadedMetadata.artwork == nil
                    ? "Metadata loaded"
                    : "Metadata and artwork loaded"
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                metadata = audioFile.metadata
                lastSavedMetadata = audioFile.metadata
                isReadingMetadata = false
                statusMessage = error.localizedDescription
            }
        }
    }

    func commitMetadataField(_ field: EditableMetadataField) {
        if field == .fileName {
            commitFileName()
            return
        }

        guard
            let audioFile = selectedItem?.audioFile,
            audioFile.supportsMetadataWriting,
            !isReadingMetadata,
            metadata.value(for: field) != lastSavedMetadata?.value(for: field)
        else {
            if selectedItem?.audioFile?.supportsMetadataWriting == false {
                statusMessage = "This file format is read-only in v1.0.0"
            }
            return
        }

        let metadataSnapshot = metadata
        let previousSaveTask = metadataSaveTask
        isSavingMetadata = true
        failedMetadataField = nil
        didFailArtworkSave = false
        statusMessage = "Saving \(field.displayName)"

        metadataSaveTask = Task {
            await previousSaveTask?.value

            do {
                try await metadataWriterService.save(metadata: metadataSnapshot, to: audioFile)
                let reloadedMetadata = try await metadataReaderService.metadata(for: audioFile)

                guard !Task.isCancelled else {
                    return
                }

                if selectedItemID == audioFile.url {
                    metadata = reloadedMetadata
                    lastSavedMetadata = reloadedMetadata
                    failedMetadataField = nil
                    didFailArtworkSave = false
                    isSavingMetadata = false
                    statusMessage = "Metadata saved"
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                isSavingMetadata = false
                failedMetadataField = field
                statusMessage = error.localizedDescription
            }
        }
    }

    private func commitFileName() {
        guard
            let audioFile = selectedItem?.audioFile,
            audioFile.supportsMetadataWriting,
            metadata.fileName != lastSavedMetadata?.fileName
        else {
            if selectedItem?.audioFile?.supportsMetadataWriting == false {
                statusMessage = "This file format is read-only in v1.0.0"
            }
            return
        }

        isSavingMetadata = true
        failedMetadataField = nil
        didFailArtworkSave = false
        statusMessage = "Renaming file"

        do {
            let renamedURL = try fileRenameService.rename(audioFile: audioFile, to: metadata.fileName)
            var renamedFile = AudioFile(url: renamedURL)
            let renamedMetadata = metadata.renamedFileMetadata(for: renamedFile)
            renamedFile.metadata = renamedMetadata

            libraryItems = libraryItems.replacingAudioFile(
                oldURL: audioFile.url,
                with: renamedFile
            )
            metadata = renamedMetadata
            lastSavedMetadata = renamedMetadata
            selectedItemID = renamedURL
            isSavingMetadata = false
            statusMessage = "File renamed"
        } catch {
            metadata.fileName = lastSavedMetadata?.fileName ?? audioFile.fileName
            failedMetadataField = .fileName
            isSavingMetadata = false
            statusMessage = error.localizedDescription
        }
    }

    func chooseArtworkImage() {
        guard let artworkData = artworkImageService.chooseArtworkImage() else {
            return
        }

        commitArtwork(artworkData)
    }

    func pasteArtworkImage() {
        guard let artworkData = artworkImageService.pastedArtworkImage() else {
            didFailArtworkSave = true
            statusMessage = "Use a JPG or PNG image for artwork."
            return
        }

        commitArtwork(artworkData)
    }

    func dropArtworkImage(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            return false
        }

        Task {
            do {
                let artworkData = try await artworkImageService.imageData(from: provider)
                commitArtwork(artworkData)
            } catch {
                didFailArtworkSave = true
                statusMessage = error.localizedDescription
            }
        }

        return true
    }

    func removeArtwork() {
        commitArtwork(nil)
    }

    private func commitArtwork(_ artworkData: Data?) {
        guard
            let audioFile = selectedItem?.audioFile,
            audioFile.supportsMetadataWriting,
            !isReadingMetadata,
            metadata.artwork != artworkData
        else {
            if selectedItem?.audioFile?.supportsMetadataWriting == false {
                statusMessage = "This file format is read-only in v1.0.0"
            }
            return
        }

        var metadataSnapshot = metadata
        metadataSnapshot.artwork = artworkData
        metadata = metadataSnapshot

        let previousSaveTask = metadataSaveTask
        isSavingMetadata = true
        didFailArtworkSave = false
        failedMetadataField = nil
        statusMessage = "Saving artwork"

        metadataSaveTask = Task {
            await previousSaveTask?.value

            do {
                try await metadataWriterService.save(metadata: metadataSnapshot, to: audioFile)
                let reloadedMetadata = try await metadataReaderService.metadata(for: audioFile)

                guard !Task.isCancelled else {
                    return
                }

                if selectedItemID == audioFile.url {
                    metadata = reloadedMetadata
                    lastSavedMetadata = reloadedMetadata
                    didFailArtworkSave = false
                    isSavingMetadata = false
                    statusMessage = "Artwork updated"
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                didFailArtworkSave = true
                isSavingMetadata = false
                statusMessage = error.localizedDescription
            }
        }
    }

    private func reopenLastFolderIfPossible() async {
        guard
            let folderURL = folderBookmarkService.restoredFolderURL(),
            folderExists(at: folderURL)
        else {
            return
        }

        loadFolder(at: folderURL, rememberFolder: false)
    }

    private func loadFolder(
        at folderURL: URL,
        rememberFolder: Bool,
        selectAfterLoad: AudioLibraryItem.ID? = nil
    ) {
        metadataReadTask?.cancel()
        metadataSaveTask?.cancel()
        folderScanTask?.cancel()
        failedMetadataField = nil
        didFailArtworkSave = false
        isReadingMetadata = false
        isSavingMetadata = false
        isScanning = true
        statusMessage = "Scanning folder"
        let folderBrowserService = FolderBrowserService()
        startAccessingFolder(folderURL)

        folderScanTask = Task {
            do {
                let rootItem = try await Task.detached(priority: .userInitiated) {
                    try Task.checkCancellation()
                    return try folderBrowserService.libraryTree(for: folderURL)
                }.value

                guard !Task.isCancelled else {
                    return
                }

                libraryItems = [rootItem]
                selectedItemID = selectAfterLoad
                lastSavedMetadata = nil
                isScanning = false

                if rememberFolder {
                    try? folderBookmarkService.saveFolder(folderURL)
                }

                statusMessage = rootItem.audioFileCount == 0
                    ? "No supported audio files found"
                    : "Folder opened"
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                isScanning = false
                statusMessage = error.localizedDescription
            }
        }
    }

    private func folderExists(at folderURL: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func startAccessingFolder(_ folderURL: URL) {
        stopAccessingCurrentFolder()
        securityScopedFolderURL = folderURL
        didStartSecurityScopedFolderAccess = folderURL.startAccessingSecurityScopedResource()
        SavePipelineDiagnostic.log("Folder security scope started: \(didStartSecurityScopedFolderAccess) path=\(folderURL.path)")
    }

    private func stopAccessingCurrentFolder() {
        guard didStartSecurityScopedFolderAccess, let securityScopedFolderURL else {
            self.securityScopedFolderURL = nil
            didStartSecurityScopedFolderAccess = false
            return
        }

        securityScopedFolderURL.stopAccessingSecurityScopedResource()
        self.securityScopedFolderURL = nil
        didStartSecurityScopedFolderAccess = false
    }
}

private extension Array where Element == AudioLibraryItem {
    func firstItem(withID id: AudioLibraryItem.ID) -> AudioLibraryItem? {
        for item in self {
            if item.id == id {
                return item
            }

            if let child = item.children?.firstItem(withID: id) {
                return child
            }
        }

        return nil
    }
}

private extension Array where Element == AudioLibraryItem {
    func replacingAudioFile(oldURL: URL, with audioFile: AudioFile) -> [AudioLibraryItem] {
        map { item in
            item.replacingAudioFile(oldURL: oldURL, with: audioFile)
        }
        .sortedForDisplay()
    }
}

private extension AudioLibraryItem {
    var audioFileCount: Int {
        let childCount = children?.reduce(0) { partialResult, item in
            partialResult + item.audioFileCount
        } ?? 0

        return isAudioFile ? childCount + 1 : childCount
    }
}

private extension AudioLibraryItem {
    func replacingAudioFile(oldURL: URL, with audioFile: AudioFile) -> AudioLibraryItem {
        if id == oldURL, isAudioFile {
            return AudioLibraryItem(
                id: audioFile.url,
                name: audioFile.fileName,
                kind: .audioFile(audioFile)
            )
        }

        return AudioLibraryItem(
            id: id,
            name: name,
            kind: kind,
            children: children?.replacingAudioFile(oldURL: oldURL, with: audioFile)
        )
    }
}

private extension Array where Element == AudioLibraryItem {
    func sortedForDisplay() -> [AudioLibraryItem] {
        sorted { lhs, rhs in
            switch (lhs.kind, rhs.kind) {
            case (.folder, .audioFile):
                true
            case (.audioFile, .folder):
                false
            default:
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }
}
