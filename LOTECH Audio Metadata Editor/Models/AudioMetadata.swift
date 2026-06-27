import Foundation

nonisolated struct AudioMetadata: Hashable, Sendable {
    var fileName: String
    var title: String
    var artist: String
    var contributingArtist: String
    var album: String
    var releaseYear: String
    var composer: String
    var genre: String
    var lyrics: String
    var description: String
    var vibeMood: String
    var artwork: Data?

    static let sample = AudioMetadata(
        fileName: "Aerial Lines.wav",
        title: "Aerial Lines",
        artist: "LOTECH",
        contributingArtist: "Sample Collaborator",
        album: "Signal Drafts",
        releaseYear: "2026",
        composer: "LOTECH",
        genre: "Electronic",
        lyrics: "Sample lyrics will appear here when metadata reading is added.",
        description: "A temporary description for the selected audio file.",
        vibeMood: "Nocturnal, precise, warm",
        artwork: nil
    )

    static func placeholder(for url: URL) -> AudioMetadata {
        AudioMetadata(
            fileName: url.lastPathComponent,
            title: url.deletingPathExtension().lastPathComponent,
            artist: "",
            contributingArtist: "",
            album: "",
            releaseYear: "",
            composer: "",
            genre: "",
            lyrics: "",
            description: "",
            vibeMood: "",
            artwork: nil
        )
    }

    func value(for field: EditableMetadataField) -> String {
        switch field {
        case .fileName:
            fileName
        case .title:
            title
        case .artist:
            artist
        case .contributingArtist:
            contributingArtist
        case .album:
            album
        case .releaseYear:
            releaseYear
        case .composer:
            composer
        case .genre:
            genre
        case .lyrics:
            lyrics
        case .description:
            description
        case .vibeMood:
            vibeMood
        }
    }

    func renamedFileMetadata(for audioFile: AudioFile) -> AudioMetadata {
        var metadata = self
        metadata.fileName = audioFile.fileName
        return metadata
    }
}
