import Foundation

/// Persists user settings between app launches using UserDefaults.
enum UserDefaultsManager {
    private static let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key: String {
        case watchFolderPath
        case watchFolderBookmark
        case marketingFolderPath
        case marketingFolderBookmark
        case selectedDisplayID
        case slideDurationSeconds
        case transitionDurationSeconds
        case marketingInterval
        case watchRecursively
        case autoStartSlideshow
        case videoAudioEnabled
        case backgroundColorHex
    }

    // MARK: - Watch Folder

    static var watchFolderBookmark: Data? {
        get { defaults.data(forKey: Key.watchFolderBookmark.rawValue) }
        set { defaults.set(newValue, forKey: Key.watchFolderBookmark.rawValue) }
    }

    static var watchFolderPath: String? {
        get { defaults.string(forKey: Key.watchFolderPath.rawValue) }
        set { defaults.set(newValue, forKey: Key.watchFolderPath.rawValue) }
    }

    /// Resolve the stored bookmark to a URL, refreshing the bookmark if needed.
    static func resolveWatchFolder() -> URL? {
        return resolveBookmark(data: watchFolderBookmark, pathFallback: watchFolderPath)
    }

    /// Save a folder URL as a security-scoped bookmark.
    static func saveWatchFolder(_ url: URL) {
        watchFolderPath = url.path
        watchFolderBookmark = createBookmark(for: url)
    }

    // MARK: - Marketing Folder

    static var marketingFolderBookmark: Data? {
        get { defaults.data(forKey: Key.marketingFolderBookmark.rawValue) }
        set { defaults.set(newValue, forKey: Key.marketingFolderBookmark.rawValue) }
    }

    static var marketingFolderPath: String? {
        get { defaults.string(forKey: Key.marketingFolderPath.rawValue) }
        set { defaults.set(newValue, forKey: Key.marketingFolderPath.rawValue) }
    }

    static func resolveMarketingFolder() -> URL? {
        return resolveBookmark(data: marketingFolderBookmark, pathFallback: marketingFolderPath)
    }

    static func saveMarketingFolder(_ url: URL) {
        marketingFolderPath = url.path
        marketingFolderBookmark = createBookmark(for: url)
    }

    static func clearMarketingFolder() {
        defaults.removeObject(forKey: Key.marketingFolderPath.rawValue)
        defaults.removeObject(forKey: Key.marketingFolderBookmark.rawValue)
    }

    // MARK: - Display

    static var selectedDisplayID: UInt32? {
        get {
            let val = defaults.integer(forKey: Key.selectedDisplayID.rawValue)
            return val > 0 ? UInt32(val) : nil
        }
        set {
            if let id = newValue {
                defaults.set(Int(id), forKey: Key.selectedDisplayID.rawValue)
            } else {
                defaults.removeObject(forKey: Key.selectedDisplayID.rawValue)
            }
        }
    }

    // MARK: - Slideshow Settings

    static var slideDurationSeconds: Double {
        get {
            let val = defaults.double(forKey: Key.slideDurationSeconds.rawValue)
            return val > 0 ? val : 8.0
        }
        set { defaults.set(newValue, forKey: Key.slideDurationSeconds.rawValue) }
    }

    static var transitionDurationSeconds: Double {
        get {
            let val = defaults.double(forKey: Key.transitionDurationSeconds.rawValue)
            return val > 0 ? val : 1.0
        }
        set { defaults.set(newValue, forKey: Key.transitionDurationSeconds.rawValue) }
    }

    static var marketingInterval: Int {
        get {
            let val = defaults.integer(forKey: Key.marketingInterval.rawValue)
            return val > 0 ? val : 4
        }
        set { defaults.set(newValue, forKey: Key.marketingInterval.rawValue) }
    }

    static var watchRecursively: Bool {
        get { defaults.bool(forKey: Key.watchRecursively.rawValue) }
        set { defaults.set(newValue, forKey: Key.watchRecursively.rawValue) }
    }

    static var autoStartSlideshow: Bool {
        get { defaults.bool(forKey: Key.autoStartSlideshow.rawValue) }
        set { defaults.set(newValue, forKey: Key.autoStartSlideshow.rawValue) }
    }

    static var videoAudioEnabled: Bool {
        get { defaults.bool(forKey: Key.videoAudioEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.videoAudioEnabled.rawValue) }
    }

    static var backgroundColorHex: String {
        get { defaults.string(forKey: Key.backgroundColorHex.rawValue) ?? "000000" }
        set { defaults.set(newValue, forKey: Key.backgroundColorHex.rawValue) }
    }

    // MARK: - Bookmark Helpers

    private static func createBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            return nil
        }
    }

    private static func resolveBookmark(data: Data?, pathFallback: String?) -> URL? {
        if let bookmarkData = data {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if isStale {
                    // Re-create the bookmark
                    print("Bookmark is stale, will refresh on next save")
                }
                return url
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }

        // Fall back to plain path
        if let path = pathFallback {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }
}
