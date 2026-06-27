import Foundation

nonisolated struct FolderBrowserService: Sendable {
    enum FolderBrowserError: LocalizedError {
        case unreadableFolder

        var errorDescription: String? {
            switch self {
            case .unreadableFolder:
                "The selected folder could not be read."
            }
        }
    }

    private static let supportedAudioExtensions: Set<String> = [
        "aac",
        "aif",
        "aiff",
        "alac",
        "flac",
        "m4a",
        "mp3",
        "wav"
    ]

    nonisolated func libraryTree(for folderURL: URL) throws -> AudioLibraryItem {
        try makeFolderItem(for: folderURL)
    }

    nonisolated func isSupportedAudioFile(_ url: URL) -> Bool {
        Self.supportedAudioExtensions.contains(url.pathExtension.lowercased())
    }

    private nonisolated func makeFolderItem(for folderURL: URL) throws -> AudioLibraryItem {
        let contents: [URL]

        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .isRegularFileKey,
                    .isHiddenKey,
                    .fileSizeKey,
                    .creationDateKey,
                    .contentModificationDateKey
                ],
                options: [.skipsPackageDescendants]
            )
        } catch {
            throw FolderBrowserError.unreadableFolder
        }

        let childItems = try contents
            .filter { url in
                let values = try? url.resourceValues(forKeys: [.isHiddenKey])
                return values?.isHidden != true
            }
            .compactMap { url -> AudioLibraryItem? in
                let resourceValues = try url.resourceValues(
                    forKeys: [
                        .isDirectoryKey,
                        .isRegularFileKey,
                        .fileSizeKey,
                        .creationDateKey,
                        .contentModificationDateKey
                    ]
                )

                if resourceValues.isDirectory == true {
                    return try makeFolderItem(for: url)
                }

                guard resourceValues.isRegularFile == true, isSupportedAudioFile(url) else {
                    return nil
                }

                let audioFile = AudioFile(url: url, resourceValues: resourceValues)

                return AudioLibraryItem(
                    id: url,
                    name: url.lastPathComponent,
                    kind: .audioFile(audioFile)
                )
            }
            .sortedForDisplay()

        return AudioLibraryItem(
            id: folderURL,
            name: folderURL.lastPathComponent,
            kind: .folder,
            children: childItems
        )
    }
}

private extension Array where Element == AudioLibraryItem {
    nonisolated func sortedForDisplay() -> [AudioLibraryItem] {
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
