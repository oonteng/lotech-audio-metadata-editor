import Foundation

nonisolated struct AudioFile: Hashable, Sendable {
    let url: URL
    let path: String
    let fileName: String
    let fileExtension: String
    let fileSize: Int64?
    let createdDate: Date?
    let modifiedDate: Date?
    var metadata: AudioMetadata
    var artwork: Data?
    var isDirty: Bool

    var supportsMetadataWriting: Bool {
        ["mp3", "m4a", "mp4"].contains(fileExtension.lowercased())
    }

    init(url: URL, resourceValues: URLResourceValues = URLResourceValues()) {
        self.url = url
        path = url.path
        fileName = url.lastPathComponent
        fileExtension = url.pathExtension
        fileSize = resourceValues.fileSize.map(Int64.init)
        createdDate = resourceValues.creationDate
        modifiedDate = resourceValues.contentModificationDate
        metadata = AudioMetadata.placeholder(for: url)
        artwork = nil
        isDirty = false
    }
}
