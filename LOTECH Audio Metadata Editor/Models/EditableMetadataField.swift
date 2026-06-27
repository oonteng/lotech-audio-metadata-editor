import Foundation

nonisolated enum EditableMetadataField: Hashable, Sendable {
    case fileName
    case title
    case artist
    case contributingArtist
    case album
    case releaseYear
    case composer
    case genre
    case lyrics
    case description
    case vibeMood

    var displayName: String {
        switch self {
        case .fileName:
            "File Name"
        case .title:
            "Title"
        case .artist:
            "Artist"
        case .contributingArtist:
            "Contributing Artist"
        case .album:
            "Album"
        case .releaseYear:
            "Release Year"
        case .composer:
            "Composer"
        case .genre:
            "Genre"
        case .lyrics:
            "Lyrics"
        case .description:
            "Description"
        case .vibeMood:
            "Vibe / Mood"
        }
    }

    var failureMessage: String {
        "Cannot write to file"
    }
}
