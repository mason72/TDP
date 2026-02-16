import Foundation
import UniformTypeIdentifiers

struct FileFilterUtility {

    static let supportedImageTypes: [UTType] = [
        .jpeg, .png, .heic, .tiff, .bmp, .gif, .webP
    ]

    static let supportedExtensions: [String] = [
        "jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "bmp", "gif", "webp"
    ]

    static func isSupported(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }

    static func filterSupported(_ urls: [URL]) -> [URL] {
        urls.filter { isSupported($0) }
    }

    static func sortByDate(_ urls: [URL]) -> [URL] {
        urls.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            return date1 < date2
        }
    }
}
