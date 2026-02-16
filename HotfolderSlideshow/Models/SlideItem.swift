import Foundation
import UniformTypeIdentifiers

/// Represents a single media item (image or video) in the slideshow.
enum MediaType: String, Codable {
    case image
    case video
}

struct SlideItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let mediaType: MediaType
    let dateAdded: Date
    let filename: String

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.filename = url.lastPathComponent
        self.dateAdded = Date()
        self.mediaType = SlideItem.detectMediaType(for: url)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: SlideItem, rhs: SlideItem) -> Bool {
        lhs.url == rhs.url
    }

    private static func detectMediaType(for url: URL) -> MediaType {
        let ext = url.pathExtension.lowercased()
        let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv"]
        if videoExtensions.contains(ext) {
            return .video
        }
        return .image
    }
}
