import Foundation
import SwiftUI
import Combine

enum AppSection: String, Identifiable, CaseIterable {
    case setup = "Setup"
    case templateEditor = "Template Editor"
    case dashboard = "Dashboard"
    case printBrowser = "Print Browser"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .setup: return "gearshape"
        case .templateEditor: return "rectangle.3.group"
        case .dashboard: return "play.circle"
        case .printBrowser: return "photo.on.rectangle.angled"
        }
    }
}

enum EventState: String {
    case idle = "Idle"
    case running = "Running"
    case paused = "Paused"

    var isActive: Bool { self == .running || self == .paused }
}

class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var selectedSection: AppSection = .setup

    // MARK: - Watch Folder
    @Published var watchFolderURL: URL? {
        didSet {
            if let url = watchFolderURL {
                UserDefaults.standard.set(url.path, forKey: "watchFolderPath")
            }
        }
    }

    // MARK: - Event
    @Published var eventState: EventState = .idle
    @Published var defaultCopies: Int = 1 {
        didSet { UserDefaults.standard.set(defaultCopies, forKey: "defaultCopies") }
    }

    // MARK: - Incoming photos queue
    @Published var incomingPhotos: [URL] = []
    @Published var photosReceived: Int = 0

    // MARK: - Services
    let folderWatcher = FolderWatcher()
    let printService = PrintService()
    let templateManager = TemplateManager()
    let compositor = ImageCompositor()
    let duplicateDetector = DuplicateDetector()
    var printQueueManager: PrintQueueManager!

    // MARK: - Session
    @Published var sessionOutputDirectory: URL?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Restore persisted settings
        if let path = UserDefaults.standard.string(forKey: "watchFolderPath") {
            watchFolderURL = URL(fileURLWithPath: path)
        }
        defaultCopies = max(1, UserDefaults.standard.integer(forKey: "defaultCopies"))
        if defaultCopies == 0 { defaultCopies = 1 }

        if let printerName = UserDefaults.standard.string(forKey: "selectedPrinter") {
            printService.selectedPrinterName = printerName
        }

        // Init print queue with a temporary directory; will be updated when event starts
        let tempDir = ImageUtils.createSessionOutputDirectory()
        sessionOutputDirectory = tempDir
        printQueueManager = PrintQueueManager(
            printService: printService,
            compositor: compositor,
            outputDirectory: tempDir
        )

        setupBindings()
    }

    private func setupBindings() {
        // Watch for new files from folder watcher
        folderWatcher.newFilesSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newFiles in
                guard let self = self, self.eventState == .running else { return }
                self.handleNewFiles(newFiles)
            }
            .store(in: &cancellables)

        // Persist printer selection
        printService.$selectedPrinterName
            .compactMap { $0 }
            .sink { name in
                UserDefaults.standard.set(name, forKey: "selectedPrinter")
            }
            .store(in: &cancellables)
    }

    // MARK: - Event Control

    func startEvent() {
        guard let folder = watchFolderURL else { return }
        guard templateManager.selectedTemplate != nil else { return }

        // Create fresh session output directory
        let outputDir = ImageUtils.createSessionOutputDirectory()
        sessionOutputDirectory = outputDir
        printQueueManager = PrintQueueManager(
            printService: printService,
            compositor: compositor,
            outputDirectory: outputDir
        )

        incomingPhotos.removeAll()
        photosReceived = 0
        duplicateDetector.reset()

        folderWatcher.startWatching(folder: folder)
        eventState = .running
    }

    func pauseEvent() {
        folderWatcher.stopWatching()
        eventState = .paused
    }

    func resumeEvent() {
        guard let folder = watchFolderURL else { return }
        folderWatcher.startWatching(folder: folder)
        eventState = .running
    }

    func stopEvent() {
        folderWatcher.stopWatching()
        eventState = .idle
        incomingPhotos.removeAll()
    }

    // MARK: - File Handling

    private func handleNewFiles(_ files: [URL]) {
        guard let template = templateManager.selectedTemplate else { return }

        for file in files {
            guard !duplicateDetector.checkAndRecord(file) else { continue }
            photosReceived += 1
            incomingPhotos.append(file)

            // Check if we have enough photos to fill the template
            if incomingPhotos.count >= template.imageCount {
                let batch = Array(incomingPhotos.prefix(template.imageCount))
                incomingPhotos.removeFirst(template.imageCount)

                let job = PrintJob(
                    template: template,
                    sourceImagePaths: batch,
                    copies: defaultCopies
                )
                printQueueManager.enqueue(job)
            }
        }
    }

    // MARK: - Computed State

    var isReadyToStart: Bool {
        watchFolderURL != nil &&
        templateManager.selectedTemplate != nil &&
        printService.selectedPrinterName != nil
    }

    var statusMessage: String {
        switch eventState {
        case .idle:
            if !isReadyToStart {
                return "Configure watch folder, template, and printer to begin"
            }
            return "Ready to start"
        case .running:
            return "Watching for photos..."
        case .paused:
            return "Event paused"
        }
    }
}
