import Foundation

enum BatchMetadataField: String, CaseIterable, Identifiable, Sendable {
    case title
    case artist
    case album
    case releaseYear
    case genre

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
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
        }
    }
}

struct BatchMetadataRow: Identifiable, Hashable, Sendable {
    enum Status: Hashable, Sendable {
        case pending
        case loading
        case loaded
        case readOnly
        case saving
        case saved
        case failed(String)

        var displayText: String {
            switch self {
            case .pending:
                "Pending"
            case .loading:
                "Loading"
            case .loaded:
                "Ready"
            case .readOnly:
                "Read-only"
            case .saving:
                "Saving"
            case .saved:
                "Saved"
            case let .failed(message):
                message
            }
        }
    }

    let id: URL
    let audioFile: AudioFile
    var originalMetadata: AudioMetadata
    var title: String
    var artist: String
    var contributingArtist: String
    var album: String
    var releaseYear: String
    var genre: String
    var status: Status

    init(audioFile: AudioFile) {
        id = audioFile.url
        self.audioFile = audioFile
        originalMetadata = audioFile.metadata
        title = audioFile.metadata.title
        artist = audioFile.metadata.artist
        contributingArtist = audioFile.metadata.contributingArtist
        album = audioFile.metadata.album
        releaseYear = audioFile.metadata.releaseYear
        genre = audioFile.metadata.genre
        status = audioFile.supportsMetadataWriting ? .pending : .readOnly
    }

    var fileName: String {
        audioFile.fileName
    }

    var isEditable: Bool {
        audioFile.supportsMetadataWriting
    }

    var hasDraftChanges: Bool {
        isEditable && (
            title != originalMetadata.title ||
            artist != originalMetadata.artist ||
            contributingArtist != originalMetadata.contributingArtist ||
            album != originalMetadata.album ||
            releaseYear != originalMetadata.releaseYear ||
            genre != originalMetadata.genre
        )
    }

    mutating func applyLoadedMetadata(_ metadata: AudioMetadata) {
        originalMetadata = metadata
        title = metadata.title
        artist = metadata.artist
        contributingArtist = metadata.contributingArtist
        album = metadata.album
        releaseYear = metadata.releaseYear
        genre = metadata.genre
        status = isEditable ? .loaded : .readOnly
    }

    mutating func discardDraftChanges() {
        title = originalMetadata.title
        artist = originalMetadata.artist
        contributingArtist = originalMetadata.contributingArtist
        album = originalMetadata.album
        releaseYear = originalMetadata.releaseYear
        genre = originalMetadata.genre
        status = isEditable ? .loaded : .readOnly
    }

    var metadataForSaving: AudioMetadata {
        var metadata = originalMetadata
        metadata.title = title
        metadata.artist = artist
        metadata.contributingArtist = contributingArtist
        metadata.album = album
        metadata.releaseYear = releaseYear
        metadata.genre = genre
        return metadata
    }

    func value(for field: BatchMetadataField) -> String {
        switch field {
        case .title:
            title
        case .artist:
            artist
        case .album:
            album
        case .releaseYear:
            releaseYear
        case .genre:
            genre
        }
    }

    mutating func setValue(_ value: String, for field: BatchMetadataField) {
        switch field {
        case .title:
            title = value
        case .artist:
            artist = value
        case .album:
            album = value
        case .releaseYear:
            releaseYear = value
        case .genre:
            genre = value
        }
    }
}
