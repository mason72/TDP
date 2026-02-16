import Foundation
import Combine

/// Watches a folder for file system changes using DispatchSource and periodic scanning.
/// Publishes the current set of media file URLs whenever changes are detected.
final class FolderWatcher: ObservableObject {
    @Published private(set) var mediaFiles: Set<URL> = []
    @Published private(set) var isWatching: Bool = false
    @Published private(set) var folderURL: URL?
    @Published private(set) var error: String?

    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var scanTimer: DispatchSourceTimer?
    private let watchQueue = DispatchQueue(label: "com.hotfolderslideshow.folderwatcher", qos: .utility)
    private let scanInterval: TimeInterval = 2.0
    private var watchRecursively: Bool = false

    deinit {
        stopWatching()
    }

    // MARK: - Public API

    /// Start watching the specified folder.
    func startWatching(url: URL, recursive: Bool = false) {
        stopWatching()

        guard FileManager.default.fileExists(atPath: url.path) else {
            DispatchQueue.main.async {
                self.error = "Folder does not exist: \(url.path)"
            }
            return
        }

        self.watchRecursively = recursive

        DispatchQueue.main.async {
            self.folderURL = url
            self.error = nil
        }

        // Open file descriptor for the directory
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            DispatchQueue.main.async {
                self.error = "Cannot open folder for watching: \(url.path)"
            }
            return
        }

        // Create dispatch source to watch for file writes and renames
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: watchQueue
        )

        source.setEventHandler { [weak self] in
            self?.performScan()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        dispatchSource = source
        source.resume()

        // Also set up a periodic timer to catch changes the dispatch source might miss
        // (e.g., changes in subdirectories or files being modified in place)
        let timer = DispatchSource.makeTimerSource(queue: watchQueue)
        timer.schedule(deadline: .now(), repeating: scanInterval)
        timer.setEventHandler { [weak self] in
            self?.performScan()
        }
        scanTimer = timer
        timer.resume()

        DispatchQueue.main.async {
            self.isWatching = true
        }

        // Perform initial scan
        performScan()
    }

    /// Stop watching the current folder.
    func stopWatching() {
        scanTimer?.cancel()
        scanTimer = nil
        dispatchSource?.cancel()
        dispatchSource = nil

        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }

        DispatchQueue.main.async {
            self.isWatching = false
            self.mediaFiles.removeAll()
            self.folderURL = nil
        }
    }

    // MARK: - Scanning

    private func performScan() {
        guard let folderURL = folderURL else { return }

        let fm = FileManager.default
        var foundFiles = Set<URL>()

        if watchRecursively {
            // Recursive enumeration
            if let enumerator = fm.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let fileURL as URL in enumerator {
                    if FileFilterUtility.isMediaFile(fileURL) {
                        foundFiles.insert(fileURL)
                    }
                }
            }
        } else {
            // Flat scan — only the top-level folder
            if let contents = try? fm.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
            ) {
                for fileURL in contents {
                    if FileFilterUtility.isMediaFile(fileURL) {
                        foundFiles.insert(fileURL)
                    }
                }
            }
        }

        // Only publish if the set actually changed
        if foundFiles != self.mediaFiles {
            DispatchQueue.main.async {
                self.mediaFiles = foundFiles
            }
        }
    }
}
