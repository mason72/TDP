import Foundation
import Combine
import AppKit

class FolderWatcher: ObservableObject {
    @Published var detectedFiles: [URL] = []
    @Published var isWatching = false
    @Published var watchFolderURL: URL?

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var pollingTimer: Timer?
    private var knownFiles: Set<String> = []
    private let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "tiff", "tif", "bmp", "gif", "webp"
    ]

    let newFilesSubject = PassthroughSubject<[URL], Never>()

    func startWatching(folder: URL) {
        stopWatching()
        watchFolderURL = folder

        // Catalog existing files so we don't re-trigger on them
        knownFiles = Set(existingImageFiles(in: folder).map { $0.lastPathComponent })

        // Use polling approach for reliability across all file systems
        isWatching = true
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForNewFiles()
        }
    }

    func stopWatching() {
        pollingTimer?.invalidate()
        pollingTimer = nil

        if let source = source {
            source.cancel()
            self.source = nil
        }
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        isWatching = false
    }

    private func checkForNewFiles() {
        guard let folder = watchFolderURL else { return }

        let currentFiles = existingImageFiles(in: folder)
        let currentFileNames = Set(currentFiles.map { $0.lastPathComponent })
        let newFileNames = currentFileNames.subtracting(knownFiles)

        if !newFileNames.isEmpty {
            let newURLs = currentFiles.filter { newFileNames.contains($0.lastPathComponent) }
                .sorted { ($0.lastPathComponent) < ($1.lastPathComponent) }

            // Wait briefly to ensure files are fully written
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                let verifiedURLs = newURLs.filter { self.isFileReady($0) }
                if !verifiedURLs.isEmpty {
                    self.knownFiles.formUnion(verifiedURLs.map { $0.lastPathComponent })
                    self.detectedFiles.append(contentsOf: verifiedURLs)
                    self.newFilesSubject.send(verifiedURLs)
                }
            }
        }
    }

    private func existingImageFiles(in folder: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return [] }

        return contents.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }
    }

    private func isFileReady(_ url: URL) -> Bool {
        // Check if file is fully written by verifying it can be read
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int,
              fileSize > 0 else {
            return false
        }
        // Try to open and read a small portion
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        let data = handle.readData(ofLength: min(1024, fileSize))
        handle.closeFile()
        return !data.isEmpty
    }

    func resetDetectedFiles() {
        detectedFiles.removeAll()
    }

    deinit {
        stopWatching()
    }
}
