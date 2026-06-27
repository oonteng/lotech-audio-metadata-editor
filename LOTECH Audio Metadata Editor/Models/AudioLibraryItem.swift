import Foundation

nonisolated struct AudioLibraryItem: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case folder
        case audioFile(AudioFile)

        var systemImageName: String {
            switch self {
            case .folder:
                "folder"
            case .audioFile:
                "music.note"
            }
        }
    }

    let id: URL
    let name: String
    let kind: Kind
    let children: [AudioLibraryItem]?

    init(
        id: URL,
        name: String,
        kind: Kind,
        children: [AudioLibraryItem]? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.children = children
    }

    var isAudioFile: Bool {
        audioFile != nil
    }

    var audioFile: AudioFile? {
        guard case let .audioFile(audioFile) = kind else {
            return nil
        }

        return audioFile
    }
}
