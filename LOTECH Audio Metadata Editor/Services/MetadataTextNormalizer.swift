import Foundation

nonisolated struct MetadataTextNormalizer: Sendable {
    func normalized(_ metadata: AudioMetadata) -> AudioMetadata {
        AudioMetadata(
            fileName: metadata.fileName,
            title: repaired(metadata.title),
            artist: repaired(metadata.artist),
            contributingArtist: repaired(metadata.contributingArtist),
            album: repaired(metadata.album),
            releaseYear: repaired(metadata.releaseYear),
            composer: repaired(metadata.composer),
            genre: repaired(metadata.genre),
            lyrics: repaired(metadata.lyrics),
            description: repaired(metadata.description),
            vibeMood: repaired(metadata.vibeMood),
            artwork: metadata.artwork
        )
    }

    private func repaired(_ value: String) -> String {
        guard looksLikeKnownMojibake(value) else {
            return value
        }

        var bestValue = value
        var candidate = value

        for _ in 0..<2 {
            guard let repaired = repairLatin1DecodedUTF8(candidate) else {
                break
            }

            if mojibakeScore(repaired) < mojibakeScore(bestValue) {
                bestValue = repaired
                candidate = repaired
            } else {
                break
            }
        }

        return bestValue
    }

    private func looksLikeKnownMojibake(_ value: String) -> Bool {
        let markers = ["Ã", "Â", "â€", "â€™", "â€œ", "â€", "â€“", "â€”"]
        return markers.contains { value.contains($0) }
    }

    private func repairLatin1DecodedUTF8(_ value: String) -> String? {
        var bytes: [UInt8] = []

        for scalar in value.unicodeScalars {
            if scalar.value <= UInt8.max {
                bytes.append(UInt8(scalar.value))
                continue
            }

            guard let byte = Self.windows1252ReverseMap[scalar.value] else {
                return nil
            }

            bytes.append(byte)
        }

        guard let repaired = String(bytes: bytes, encoding: .utf8), repaired != value else {
            return nil
        }

        return repaired
    }

    private func mojibakeScore(_ value: String) -> Int {
        let markers = ["Ã", "Â", "â€", "â€™", "â€œ", "â€", "â€“", "â€”", "�"]
        let markerScore = markers.reduce(0) { partialResult, marker in
            partialResult + value.components(separatedBy: marker).count - 1
        }
        let latin1FragmentScore = value.unicodeScalars.filter { scalar in
            (0x80...0xFF).contains(scalar.value)
        }.count

        return markerScore + latin1FragmentScore
    }

    private static let windows1252ReverseMap: [UInt32: UInt8] = [
        0x20AC: 0x80,
        0x201A: 0x82,
        0x0192: 0x83,
        0x201E: 0x84,
        0x2026: 0x85,
        0x2020: 0x86,
        0x2021: 0x87,
        0x02C6: 0x88,
        0x2030: 0x89,
        0x0160: 0x8A,
        0x2039: 0x8B,
        0x0152: 0x8C,
        0x017D: 0x8E,
        0x2018: 0x91,
        0x2019: 0x92,
        0x201C: 0x93,
        0x201D: 0x94,
        0x2022: 0x95,
        0x2013: 0x96,
        0x2014: 0x97,
        0x02DC: 0x98,
        0x2122: 0x99,
        0x0161: 0x9A,
        0x203A: 0x9B,
        0x0153: 0x9C,
        0x017E: 0x9E,
        0x0178: 0x9F
    ]
}
