import AVFoundation
import Foundation

nonisolated struct AudioMetadataWriterService: Sendable {
    enum AudioMetadataWriterError: LocalizedError {
        case unsupportedFileFormat
        case readFailed
        case writeFailed
        case replacementFailed

        var errorDescription: String? {
            switch self {
            case .unsupportedFileFormat:
                "This file type cannot be edited yet."
            case .readFailed:
                "The file could not be read for saving."
            case .writeFailed:
                "The metadata changes could not be written to the file."
            case .replacementFailed:
                "The file could not be updated. Check that it is not locked or open in another app."
            }
        }
    }

    private let textNormalizer = MetadataTextNormalizer()

    func save(metadata: AudioMetadata, to audioFile: AudioFile) async throws {
        let normalizedMetadata = textNormalizer.normalized(metadata)

        switch audioFile.fileExtension.lowercased() {
        case "mp3":
            try saveID3Metadata(normalizedMetadata, to: audioFile)
        case "m4a", "mp4":
            try await saveMPEG4Metadata(normalizedMetadata, to: audioFile)
        default:
            SavePipelineDiagnostic.log("Rejected unsupported write format: \(audioFile.fileExtension)")
            throw AudioMetadataWriterError.unsupportedFileFormat
        }
    }

    private func replaceOriginalFile(at originalURL: URL, with updatedURL: URL) throws {
        SavePipelineDiagnostic.log("Replacing original path=\(originalURL.path)")

        do {
            _ = try FileManager.default.replaceItemAt(
                originalURL,
                withItemAt: updatedURL,
                backupItemName: nil,
                options: []
            )
            SavePipelineDiagnostic.log("Replace succeeded")
        } catch {
            SavePipelineDiagnostic.log("Replace failed: \(error.localizedDescription)")
            throw AudioMetadataWriterError.replacementFailed
        }
    }

    private func temporaryOutputURL(nextTo originalURL: URL, fileExtension: String) -> URL {
        let fileName = ".lotech-\(UUID().uuidString).\(fileExtension)"
        return originalURL.deletingLastPathComponent().appendingPathComponent(fileName)
    }

    private func saveID3Metadata(_ metadata: AudioMetadata, to audioFile: AudioFile) throws {
        let didStartSecurityScope = audioFile.url.startAccessingSecurityScopedResource()
        SavePipelineDiagnostic.log("File security scope started: \(didStartSecurityScope) path=\(audioFile.path)")

        defer {
            if didStartSecurityScope {
                audioFile.url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            SavePipelineDiagnostic.log("File readable: \(FileManager.default.isReadableFile(atPath: audioFile.path))")
            SavePipelineDiagnostic.log("File writable: \(FileManager.default.isWritableFile(atPath: audioFile.path))")
            SavePipelineDiagnostic.log("Folder writable: \(FileManager.default.isWritableFile(atPath: audioFile.url.deletingLastPathComponent().path))")

            let fileData = try Data(contentsOf: audioFile.url)
            SavePipelineDiagnostic.log("Read source bytes: \(fileData.count)")
            let existingTag = ID3Tag(data: fileData)
            SavePipelineDiagnostic.log("Existing ID3 tag size: \(existingTag.totalSize), frames: \(existingTag.frames.count)")
            let audioData = fileData.dropFirst(existingTag.totalSize)
            let tagData = ID3TagBuilder(metadata: metadata, existingFrames: existingTag.frames).data()
            SavePipelineDiagnostic.log("New ID3 tag bytes: \(tagData.count), audio bytes preserved: \(audioData.count)")
            let updatedData = tagData + audioData
            let outputURL = temporaryOutputURL(nextTo: audioFile.url, fileExtension: audioFile.fileExtension)

            try updatedData.write(to: outputURL, options: [.atomic])
            SavePipelineDiagnostic.log("Temporary write succeeded: \(outputURL.path)")
            try replaceOriginalFile(at: audioFile.url, with: outputURL)
        } catch let error as AudioMetadataWriterError {
            throw error
        } catch {
            SavePipelineDiagnostic.log("Write failed: \(error.localizedDescription)")
            throw AudioMetadataWriterError.writeFailed
        }
    }

    private func saveMPEG4Metadata(_ metadata: AudioMetadata, to audioFile: AudioFile) async throws {
        let didStartSecurityScope = audioFile.url.startAccessingSecurityScopedResource()
        SavePipelineDiagnostic.log("MPEG-4 file security scope started: \(didStartSecurityScope) path=\(audioFile.path)")

        defer {
            if didStartSecurityScope {
                audioFile.url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            SavePipelineDiagnostic.log("MPEG-4 file readable: \(FileManager.default.isReadableFile(atPath: audioFile.path))")
            SavePipelineDiagnostic.log("MPEG-4 file writable: \(FileManager.default.isWritableFile(atPath: audioFile.path))")
            SavePipelineDiagnostic.log("MPEG-4 folder writable: \(FileManager.default.isWritableFile(atPath: audioFile.url.deletingLastPathComponent().path))")

            let asset = AVURLAsset(url: audioFile.url)

            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
                SavePipelineDiagnostic.log("MPEG-4 export session could not be created")
                throw AudioMetadataWriterError.writeFailed
            }

            let outputType: AVFileType = audioFile.fileExtension.lowercased() == "mp4" ? .mp4 : .m4a
            let compatibleTypes = await exportSession.compatibleFileTypes

            guard compatibleTypes.contains(outputType) else {
                SavePipelineDiagnostic.log("MPEG-4 export type unsupported: \(outputType.rawValue), compatible=\(compatibleTypes.map(\.rawValue).joined(separator: ","))")
                throw AudioMetadataWriterError.writeFailed
            }

            let existingMetadata = try await asset.load(.metadata)
            exportSession.metadata = MPEG4MetadataBuilder(
                metadata: metadata,
                existingItems: existingMetadata
            ).items()

            let outputURL = temporaryOutputURL(nextTo: audioFile.url, fileExtension: audioFile.fileExtension)
            SavePipelineDiagnostic.log("MPEG-4 temporary output: \(outputURL.path)")

            try await exportSession.export(to: outputURL, as: outputType)
            SavePipelineDiagnostic.log("MPEG-4 export succeeded")
            try replaceOriginalFile(at: audioFile.url, with: outputURL)
        } catch let error as AudioMetadataWriterError {
            throw error
        } catch {
            SavePipelineDiagnostic.log("MPEG-4 write failed: \(error.localizedDescription)")
            throw AudioMetadataWriterError.writeFailed
        }
    }
}

private nonisolated struct MPEG4MetadataBuilder {
    let metadata: AudioMetadata
    let existingItems: [AVMetadataItem]

    func items() -> [AVMetadataItem] {
        let preservedItems = existingItems.filter { item in
            guard let identifier = item.identifier?.rawValue else {
                return true
            }

            return !controlledIdentifiers.contains(identifier)
        }

        return preservedItems + writableItems()
    }

    private func writableItems() -> [AVMetadataItem] {
        var items: [AVMetadataItem] = []
        items.appendIfPresent(textItem(identifier: .iTunesMetadataSongName, value: metadata.title))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataArtist, value: metadata.artist))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataAlbumArtist, value: metadata.contributingArtist))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataAlbum, value: metadata.album))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataReleaseDate, value: metadata.releaseYear))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataComposer, value: metadata.composer))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataUserGenre, value: metadata.genre))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataLyrics, value: metadata.lyrics))
        items.appendIfPresent(textItem(identifier: .iTunesMetadataDescription, value: metadata.description))

        if #available(macOS 10.12, *) {
            items.appendIfPresent(textItem(identifier: .iTunesMetadataGrouping, value: metadata.vibeMood))
        }

        if let artwork = metadata.artwork {
            items.append(dataItem(identifier: .iTunesMetadataCoverArt, value: artwork))
        }

        return items
    }

    private var controlledIdentifiers: Set<String> {
        [
            AVMetadataIdentifier.commonIdentifierTitle.rawValue,
            AVMetadataIdentifier.iTunesMetadataSongName.rawValue,
            AVMetadataIdentifier.commonIdentifierArtist.rawValue,
            AVMetadataIdentifier.iTunesMetadataArtist.rawValue,
            AVMetadataIdentifier.iTunesMetadataAlbumArtist.rawValue,
            AVMetadataIdentifier.commonIdentifierAlbumName.rawValue,
            AVMetadataIdentifier.iTunesMetadataAlbum.rawValue,
            AVMetadataIdentifier.commonIdentifierCreationDate.rawValue,
            AVMetadataIdentifier.iTunesMetadataReleaseDate.rawValue,
            AVMetadataIdentifier.commonIdentifierCreator.rawValue,
            AVMetadataIdentifier.iTunesMetadataComposer.rawValue,
            AVMetadataIdentifier.commonIdentifierType.rawValue,
            AVMetadataIdentifier.iTunesMetadataUserGenre.rawValue,
            AVMetadataIdentifier.quickTimeMetadataGenre.rawValue,
            AVMetadataIdentifier.iTunesMetadataLyrics.rawValue,
            AVMetadataIdentifier.commonIdentifierDescription.rawValue,
            AVMetadataIdentifier.iTunesMetadataDescription.rawValue,
            AVMetadataIdentifier.iTunesMetadataGrouping.rawValue,
            AVMetadataIdentifier.commonIdentifierArtwork.rawValue,
            AVMetadataIdentifier.iTunesMetadataCoverArt.rawValue
        ]
    }

    private func textItem(identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem? {
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedValue.isEmpty else {
            return nil
        }

        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = cleanedValue as NSString
        return item.copy() as? AVMetadataItem ?? item
    }

    private func dataItem(identifier: AVMetadataIdentifier, value: Data) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSData
        item.dataType = value.mimeType == "image/png"
            ? "com.apple.metadata.datatype.PNG"
            : "com.apple.metadata.datatype.JPEG"
        return item.copy() as? AVMetadataItem ?? item
    }
}

private nonisolated extension Array where Element == AVMetadataItem {
    mutating func appendIfPresent(_ item: AVMetadataItem?) {
        guard let item else {
            return
        }

        append(item)
    }
}

private nonisolated struct ID3Frame {
    let id: String
    let payload: Data
}

private nonisolated struct ID3Tag {
    let totalSize: Int
    let frames: [ID3Frame]

    init(data: Data) {
        guard
            data.count >= 10,
            data[0] == UInt8(ascii: "I"),
            data[1] == UInt8(ascii: "D"),
            data[2] == UInt8(ascii: "3")
        else {
            totalSize = 0
            frames = []
            return
        }

        let version = data[3]
        let flags = data[5]
        let tagSize = Int.syncSafe(
            data[6],
            data[7],
            data[8],
            data[9]
        )
        let footerSize = flags & 0x10 == 0x10 ? 10 : 0
        totalSize = min(data.count, 10 + tagSize + footerSize)

        let frameData = data.subdata(in: 10..<min(data.count, 10 + tagSize))
        frames = ID3Tag.parseFrames(from: frameData, version: version)
    }

    private static func parseFrames(from data: Data, version: UInt8) -> [ID3Frame] {
        var offset = 0
        var frames: [ID3Frame] = []

        while offset + 10 <= data.count {
            let header = data[offset..<(offset + 10)]

            guard header.contains(where: { $0 != 0 }) else {
                break
            }

            let identifierBytes = header.prefix(4)

            guard let identifier = String(bytes: identifierBytes, encoding: .isoLatin1),
                  identifier.allSatisfy({ $0.isLetter || $0.isNumber })
            else {
                break
            }

            let sizeBytes = Array(header.dropFirst(4).prefix(4))
            let frameSize = version == 4
                ? Int.syncSafe(sizeBytes[0], sizeBytes[1], sizeBytes[2], sizeBytes[3])
                : Int.bigEndian(sizeBytes[0], sizeBytes[1], sizeBytes[2], sizeBytes[3])
            let payloadStart = offset + 10
            let payloadEnd = payloadStart + frameSize

            guard frameSize >= 0, payloadEnd <= data.count else {
                break
            }

            let payload = data.subdata(in: payloadStart..<payloadEnd)
            frames.append(ID3Frame(id: identifier, payload: payload))
            offset = payloadEnd
        }

        return frames
    }
}

private nonisolated struct ID3TagBuilder {
    let metadata: AudioMetadata
    let existingFrames: [ID3Frame]

    func data() -> Data {
        let frameData = preservedFrames() + writableFrames()
        var tag = Data()
        tag.append(contentsOf: [UInt8(ascii: "I"), UInt8(ascii: "D"), UInt8(ascii: "3")])
        tag.append(contentsOf: [0x03, 0x00, 0x00])
        tag.append(contentsOf: Int.syncSafeBytes(frameData.count))
        tag.append(frameData)
        return tag
    }

    private func preservedFrames() -> Data {
        let replacementIDs = replacementFrameIDs
        return existingFrames.reduce(into: Data()) { result, frame in
            guard !replacementIDs.contains(frame.id) else {
                return
            }

            result.append(frameData(id: frame.id, payload: frame.payload))
        }
    }

    private func writableFrames() -> Data {
        var data = Data()
        data.append(textFrame(id: "TIT2", value: metadata.title))
        data.append(textFrame(id: "TPE1", value: metadata.artist))
        data.append(textFrame(id: "TPE2", value: metadata.contributingArtist))
        data.append(textFrame(id: "TALB", value: metadata.album))
        data.append(textFrame(id: "TDRC", value: metadata.releaseYear))
        data.append(textFrame(id: "TCOM", value: metadata.composer))
        data.append(textFrame(id: "TCON", value: metadata.genre))
        data.append(lyricsFrame(value: metadata.lyrics))
        data.append(commentFrame(description: "Description", value: metadata.description))
        data.append(textFrame(id: "TMOO", value: metadata.vibeMood))

        if let artwork = metadata.artwork {
            data.append(artworkFrame(data: artwork))
        }

        return data
    }

    private var replacementFrameIDs: Set<String> {
        [
            "TIT2",
            "TPE1",
            "TPE2",
            "TALB",
            "TYER",
            "TDRC",
            "TCOM",
            "TCON",
            "USLT",
            "COMM",
            "TIT1",
            "TMOO",
            "APIC"
        ]
    }

    private func textFrame(id: String, value: String) -> Data {
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedValue.isEmpty else {
            return Data()
        }

        var payload = Data([0x01])
        payload.append(cleanedValue.id3UTF16Data)
        return frameData(id: id, payload: payload)
    }

    private func lyricsFrame(value: String) -> Data {
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedValue.isEmpty else {
            return Data()
        }

        var payload = Data([0x01])
        payload.append(contentsOf: [UInt8(ascii: "e"), UInt8(ascii: "n"), UInt8(ascii: "g"), 0x00])
        payload.append(cleanedValue.id3UTF16Data)
        return frameData(id: "USLT", payload: payload)
    }

    private func commentFrame(description: String, value: String) -> Data {
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedValue.isEmpty else {
            return Data()
        }

        var payload = Data([0x01])
        payload.append(contentsOf: [UInt8(ascii: "e"), UInt8(ascii: "n"), UInt8(ascii: "g")])
        payload.append(description.id3UTF16Data)
        payload.append(contentsOf: [0x00, 0x00])
        payload.append(cleanedValue.id3UTF16Data)
        return frameData(id: "COMM", payload: payload)
    }

    private func artworkFrame(data artwork: Data) -> Data {
        var payload = Data([0x01])
        payload.append(artwork.mimeType.data(using: .utf8) ?? Data())
        payload.append(0x00)
        payload.append(0x03)
        payload.append(contentsOf: [0xFF, 0xFE, 0x00, 0x00])
        payload.append(artwork)
        return frameData(id: "APIC", payload: payload)
    }

    private func frameData(id: String, payload: Data) -> Data {
        var frame = Data()
        frame.append(id.data(using: .isoLatin1) ?? Data())
        frame.append(contentsOf: Int.bigEndianBytes(payload.count))
        frame.append(contentsOf: [0x00, 0x00])
        frame.append(payload)
        return frame
    }
}

private nonisolated extension Data {
    static func + (lhs: Data, rhs: Data.SubSequence) -> Data {
        var data = lhs
        data.append(contentsOf: rhs)
        return data
    }

    var mimeType: String {
        if starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            "image/png"
        } else {
            "image/jpeg"
        }
    }
}

private nonisolated extension String {
    var id3UTF16Data: Data {
        var data = Data([0xFF, 0xFE])
        data.append(self.data(using: .utf16LittleEndian) ?? Data())
        return data
    }
}

private nonisolated extension Int {
    static func syncSafe(_ first: UInt8, _ second: UInt8, _ third: UInt8, _ fourth: UInt8) -> Int {
        Int(first) << 21 | Int(second) << 14 | Int(third) << 7 | Int(fourth)
    }

    static func bigEndian(_ first: UInt8, _ second: UInt8, _ third: UInt8, _ fourth: UInt8) -> Int {
        Int(first) << 24 | Int(second) << 16 | Int(third) << 8 | Int(fourth)
    }

    static func syncSafeBytes(_ value: Int) -> [UInt8] {
        [
            UInt8((value >> 21) & 0x7F),
            UInt8((value >> 14) & 0x7F),
            UInt8((value >> 7) & 0x7F),
            UInt8(value & 0x7F)
        ]
    }

    static func bigEndianBytes(_ value: Int) -> [UInt8] {
        [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ]
    }
}
