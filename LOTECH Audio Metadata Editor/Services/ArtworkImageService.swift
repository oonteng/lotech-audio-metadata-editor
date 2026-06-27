import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
struct ArtworkImageService {
    enum ArtworkImageError: LocalizedError {
        case unsupportedImage
        case unreadableImage

        var errorDescription: String? {
            switch self {
            case .unsupportedImage:
                "Use a JPG or PNG image for artwork."
            case .unreadableImage:
                "The artwork image could not be read."
            }
        }
    }

    func chooseArtworkImage() -> Data? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png]
        panel.prompt = "Choose Artwork"
        panel.message = "Choose a JPG or PNG image."

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return try? imageData(from: url)
    }

    func pastedArtworkImage() -> Data? {
        let pasteboard = NSPasteboard.general

        if let fileURL = pasteboard.readObjects(forClasses: [NSURL.self])?.first as? URL,
           let data = try? imageData(from: fileURL) {
            return data
        }

        if let pngData = pasteboard.data(forType: .png) {
            return pngData
        }

        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData) {
            return pngData(from: image)
        }

        return nil
    }

    nonisolated func imageData(from url: URL) throws -> Data {
        let fileExtension = url.pathExtension.lowercased()

        guard ["jpg", "jpeg", "png"].contains(fileExtension) else {
            throw ArtworkImageError.unsupportedImage
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw ArtworkImageError.unreadableImage
        }
    }

    nonisolated func imageData(from provider: NSItemProvider) async throws -> Data {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let data = try? await provider.dataRepresentation(for: .fileURL),
           let url = URL(dataRepresentation: data, relativeTo: nil) {
            return try imageData(from: url)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
            return try await provider.dataRepresentation(for: .png)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) {
            return try await provider.dataRepresentation(for: .jpeg)
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
           let data = try? await provider.dataRepresentation(for: .image),
           let image = NSImage(data: data),
           let pngData = pngData(from: image) {
            return pngData
        }

        throw ArtworkImageError.unsupportedImage
    }

    nonisolated private func pngData(from image: NSImage) -> Data? {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }
}

private extension NSItemProvider {
    func dataRepresentation(for type: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? ArtworkImageService.ArtworkImageError.unreadableImage)
                }
            }
        }
    }
}
