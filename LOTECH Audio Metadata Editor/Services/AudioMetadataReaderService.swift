import AVFoundation
import Foundation

nonisolated struct AudioMetadataReaderService: Sendable {
    enum AudioMetadataReaderError: LocalizedError {
        case unreadableMetadata

        var errorDescription: String? {
            switch self {
            case .unreadableMetadata:
                "The selected audio file's metadata could not be read."
            }
        }
    }

    func metadata(for audioFile: AudioFile) async throws -> AudioMetadata {
        let didStartSecurityScope = audioFile.url.startAccessingSecurityScopedResource()

        defer {
            if didStartSecurityScope {
                audioFile.url.stopAccessingSecurityScopedResource()
            }
        }

        let asset = AVURLAsset(url: audioFile.url)

        do {
            let commonMetadata = try await asset.load(.commonMetadata)
            let formatMetadata = try await asset.load(.metadata)
            let metadataItems = commonMetadata + formatMetadata

            return AudioMetadata(
                fileName: audioFile.fileName,
                title: await metadataItems.firstString(matching: .title) ?? audioFile.metadata.title,
                artist: await metadataItems.firstString(matching: .artist) ?? audioFile.metadata.artist,
                contributingArtist: await metadataItems.firstString(matching: .contributingArtist) ?? audioFile.metadata.contributingArtist,
                album: await metadataItems.firstString(matching: .album) ?? audioFile.metadata.album,
                releaseYear: await metadataItems.firstYear(matching: .releaseYear) ?? audioFile.metadata.releaseYear,
                composer: await metadataItems.firstString(matching: .composer) ?? audioFile.metadata.composer,
                genre: await metadataItems.firstString(matching: .genre) ?? audioFile.metadata.genre,
                lyrics: await metadataItems.firstString(matching: .lyrics) ?? audioFile.metadata.lyrics,
                description: await metadataItems.firstString(matching: .description) ?? audioFile.metadata.description,
                vibeMood: await metadataItems.firstString(matching: .vibeMood) ?? audioFile.metadata.vibeMood,
                artwork: await metadataItems.firstData(matching: .artwork)
            )
        } catch {
            throw AudioMetadataReaderError.unreadableMetadata
        }
    }
}

private enum MetadataField {
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
    case artwork

    var identifiers: Set<String> {
        switch self {
        case .title:
            [
                AVMetadataIdentifier.commonIdentifierTitle.rawValue,
                AVMetadataIdentifier.id3MetadataTitleDescription.rawValue,
                AVMetadataIdentifier.iTunesMetadataSongName.rawValue
            ]
        case .artist:
            [
                AVMetadataIdentifier.commonIdentifierArtist.rawValue,
                AVMetadataIdentifier.id3MetadataLeadPerformer.rawValue,
                AVMetadataIdentifier.iTunesMetadataArtist.rawValue
            ]
        case .contributingArtist:
            [
                AVMetadataIdentifier.id3MetadataBand.rawValue,
                AVMetadataIdentifier.iTunesMetadataAlbumArtist.rawValue
            ]
        case .album:
            [
                AVMetadataIdentifier.commonIdentifierAlbumName.rawValue,
                AVMetadataIdentifier.id3MetadataAlbumTitle.rawValue,
                AVMetadataIdentifier.iTunesMetadataAlbum.rawValue
            ]
        case .releaseYear:
            [
                AVMetadataIdentifier.commonIdentifierCreationDate.rawValue,
                AVMetadataIdentifier.id3MetadataYear.rawValue,
                AVMetadataIdentifier.id3MetadataRecordingTime.rawValue,
                AVMetadataIdentifier.iTunesMetadataReleaseDate.rawValue
            ]
        case .composer:
            [
                AVMetadataIdentifier.commonIdentifierCreator.rawValue,
                AVMetadataIdentifier.id3MetadataComposer.rawValue,
                AVMetadataIdentifier.iTunesMetadataComposer.rawValue
            ]
        case .genre:
            [
                AVMetadataIdentifier.commonIdentifierType.rawValue,
                AVMetadataIdentifier.id3MetadataContentType.rawValue,
                AVMetadataIdentifier.iTunesMetadataUserGenre.rawValue,
                AVMetadataIdentifier.quickTimeMetadataGenre.rawValue
            ]
        case .lyrics:
            [
                AVMetadataIdentifier.id3MetadataUnsynchronizedLyric.rawValue,
                AVMetadataIdentifier.iTunesMetadataLyrics.rawValue
            ]
        case .description:
            [
                AVMetadataIdentifier.commonIdentifierDescription.rawValue,
                AVMetadataIdentifier.id3MetadataComments.rawValue,
                AVMetadataIdentifier.iTunesMetadataDescription.rawValue
            ]
        case .vibeMood:
            [
                AVMetadataIdentifier.id3MetadataMood.rawValue,
                AVMetadataIdentifier.id3MetadataContentGroupDescription.rawValue
            ]
        case .artwork:
            [
                AVMetadataIdentifier.commonIdentifierArtwork.rawValue,
                AVMetadataIdentifier.id3MetadataAttachedPicture.rawValue,
                AVMetadataIdentifier.iTunesMetadataCoverArt.rawValue
            ]
        }
    }

    var keyFragments: [String] {
        switch self {
        case .title:
            ["title", "songname"]
        case .artist:
            ["artist", "performer", "leadperformer"]
        case .contributingArtist:
            ["albumartist", "contributing", "band", "accompaniment"]
        case .album:
            ["album"]
        case .releaseYear:
            ["year", "date", "creationdate", "releasedate", "recordingtime"]
        case .composer:
            ["composer", "creator"]
        case .genre:
            ["genre", "contenttype"]
        case .lyrics:
            ["lyric", "lyrics"]
        case .description:
            ["description", "comment"]
        case .vibeMood:
            ["mood", "grouping", "contentgroup"]
        case .artwork:
            ["artwork", "picture", "coverart", "covr", "apic"]
        }
    }
}

private extension Array where Element == AVMetadataItem {
    func firstString(matching field: MetadataField) async -> String? {
        for item in self where item.matches(field) {
            let loadedValue = try? await item.load(.stringValue)
            let value = loadedValue?.trimmingCharacters(in: .whitespacesAndNewlines)

            if value?.isEmpty == false {
                return value
            }
        }

        return nil
    }

    func firstData(matching field: MetadataField) async -> Data? {
        for item in self where item.matches(field) {
            if let data = try? await item.load(.dataValue) {
                return data
            }
        }

        return nil
    }

    func firstYear(matching field: MetadataField) async -> String? {
        guard let value = await firstString(matching: field) else {
            return nil
        }

        let year = value.prefix(4)
        return year.allSatisfy(\.isNumber) ? String(year) : value
    }
}

private extension AVMetadataItem {
    func matches(_ field: MetadataField) -> Bool {
        if let identifier, field.identifiers.contains(identifier.rawValue) {
            return true
        }

        let searchableParts = [
            identifier?.rawValue,
            keySpace?.rawValue,
            key.flatMap(String.init(describing:))
        ]
        .compactMap { $0?.lowercased() }

        return searchableParts.contains { part in
            field.keyFragments.contains { part.contains($0) }
        }
    }
}
