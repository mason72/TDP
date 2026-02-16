import Foundation

/// Filters files to determine if they are supported media types.
enum FileFilterUtility {
    /// Supported image file extensions.
    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif",
        "bmp", "gif", "webp"
    ]

    /// Supported video file extensions.
    static let videoExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv"
    ]

    /// All supported media extensions.
    static let allMediaExtensions: Set<String> = imageExtensions.union(videoExtensions)

    /// Check if a file URL points to a supported media file.
    static func isMediaFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard allMediaExtensions.contains(ext) else { return false }

        // Also verify it's a regular file (not a directory or alias)
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }

    /// Check if a URL is a hidden file (starts with dot).
    static func isHiddenFile(_ url: URL) -> Bool {
        url.lastPathComponent.hasPrefix(".")
    }

    /// Check if a URL points to an image file.
    static func isImageFile(_ url: URL) -> Bool {
        imageExtensions.contains(url.pathExtension.lowercased())
    }

    /// Check if a URL points to a video file.
    static func isVideoFile(_ url: URL) -> Bool {
        videoExtensions.contains(url.pathExtension.lowercased())
    }
}
