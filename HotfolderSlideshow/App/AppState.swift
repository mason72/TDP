import SwiftUI
import Combine
import AVFoundation

/// Central app state that coordinates all services, playlists, and the slideshow lifecycle.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Services
    let monitorManager = MonitorManager()
    let mainFolderWatcher = FolderWatcher()
    let marketingFolderWatcher = FolderWatcher()
    let mediaLoader = MediaLoader()

    // MARK: - Playlists
    let marketingPlaylist = MarketingPlaylist()
    @Published private(set) var slideshowPlaylist: SlideshowPlaylist!

    // MARK: - Slideshow State
    @Published var isPlaying: Bool = false
    @Published private(set) var currentSlide: SlideItem?
    @Published private(set) var currentImage: NSImage?
    @Published private(set) var currentPlayerItem: AVPlayerItem?
    @Published private(set) var statusMessage: String = "Select a folder to begin"

    // MARK: - Settings (bound to UI)
    @Published var slideDuration: Double {
        didSet { UserDefaultsManager.slideDurationSeconds = slideDuration }
    }
    @Published var transitionDuration: Double {
        didSet { UserDefaultsManager.transitionDurationSeconds = transitionDuration }
    }
    @Published var marketingInterval: Int {
        didSet {
            UserDefaultsManager.marketingInterval = marketingInterval
            slideshowPlaylist?.marketingInterval = marketingInterval
        }
    }
    @Published var watchRecursively: Bool {
        didSet {
            UserDefaultsManager.watchRecursively = watchRecursively
            // Restart watcher with new setting if currently watching
            if let url = mainFolderWatcher.folderURL {
                mainFolderWatcher.startWatching(url: url, recursive: watchRecursively)
            }
        }
    }
    @Published var videoAudioEnabled: Bool {
        didSet { UserDefaultsManager.videoAudioEnabled = videoAudioEnabled }
    }
    @Published var autoStartSlideshow: Bool {
        didSet { UserDefaultsManager.autoStartSlideshow = autoStartSlideshow }
    }

    // MARK: - Slideshow Window
    private var slideshowWindowController: SlideshowWindowController?
    private var slideTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Video Playback
    let videoPlayer = AVPlayer()
    private var videoEndObserver: Any?

    // MARK: - Init

    init() {
        // Load persisted settings
        self.slideDuration = UserDefaultsManager.slideDurationSeconds
        self.transitionDuration = UserDefaultsManager.transitionDurationSeconds
        self.marketingInterval = UserDefaultsManager.marketingInterval
        self.watchRecursively = UserDefaultsManager.watchRecursively
        self.videoAudioEnabled = UserDefaultsManager.videoAudioEnabled
        self.autoStartSlideshow = UserDefaultsManager.autoStartSlideshow

        self.slideshowPlaylist = SlideshowPlaylist(marketingPlaylist: marketingPlaylist)
        self.slideshowPlaylist.marketingInterval = marketingInterval

        // Restore saved display selection
        if let savedDisplayID = UserDefaultsManager.selectedDisplayID {
            monitorManager.selectDisplay(savedDisplayID)
        }

        setupBindings()
        restoreFolders()
    }

    // MARK: - Folder Selection

    func selectWatchFolder(_ url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        UserDefaultsManager.saveWatchFolder(url)
        mainFolderWatcher.startWatching(url: url, recursive: watchRecursively)
        statusMessage = "Watching: \(url.lastPathComponent)"
    }

    func selectMarketingFolder(_ url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        UserDefaultsManager.saveMarketingFolder(url)
        marketingFolderWatcher.startWatching(url: url, recursive: false)
    }

    func clearMarketingFolder() {
        marketingFolderWatcher.stopWatching()
        marketingPlaylist.clear()
        UserDefaultsManager.clearMarketingFolder()
    }

    // MARK: - Monitor Selection

    func selectMonitor(_ displayID: CGDirectDisplayID) {
        monitorManager.selectDisplay(displayID)
        UserDefaultsManager.selectedDisplayID = displayID

        // If slideshow is running, move window to new monitor
        if isPlaying, let screen = monitorManager.selectedScreen {
            slideshowWindowController?.moveToScreen(screen)
        }
    }

    // MARK: - Slideshow Controls

    func play() {
        guard !slideshowPlaylist.allItems.isEmpty || marketingPlaylist.hasItems else {
            statusMessage = "No media files found"
            return
        }

        guard monitorManager.selectedDisplay != nil else {
            statusMessage = "Please select a monitor"
            return
        }

        isPlaying = true
        statusMessage = "Playing"

        showSlideshowWindow()
        advanceToNextSlide()
    }

    func pause() {
        isPlaying = false
        statusMessage = "Paused"
        slideTimer?.invalidate()
        slideTimer = nil
        videoPlayer.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func nextSlide() {
        advanceToNextSlide()
    }

    func previousSlide() {
        // For simplicity, "previous" just advances to the next random slide
        // A full history stack could be added later
        advanceToNextSlide()
    }

    func stop() {
        pause()
        hideSlideshowWindow()
        currentSlide = nil
        currentImage = nil
        currentPlayerItem = nil
        statusMessage = mainFolderWatcher.isWatching ? "Watching: \(mainFolderWatcher.folderURL?.lastPathComponent ?? "")" : "Select a folder to begin"
    }

    // MARK: - Slideshow Window

    private func showSlideshowWindow() {
        guard let screen = monitorManager.selectedScreen else { return }

        if slideshowWindowController == nil {
            slideshowWindowController = SlideshowWindowController(appState: self)
        }
        slideshowWindowController?.showOnScreen(screen)
    }

    private func hideSlideshowWindow() {
        slideshowWindowController?.close()
        slideshowWindowController = nil
    }

    // MARK: - Slide Advancement

    private func advanceToNextSlide() {
        slideTimer?.invalidate()
        slideTimer = nil

        guard let nextItem = slideshowPlaylist.next() else {
            if slideshowPlaylist.allItems.isEmpty {
                statusMessage = "Waiting for content..."
                // Retry in a few seconds
                slideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.advanceToNextSlide()
                    }
                }
            }
            return
        }

        currentSlide = nextItem

        // Preload upcoming slides
        if let peekItem = slideshowPlaylist.peekNext() {
            mediaLoader.preload(items: [peekItem])
        }

        switch nextItem.mediaType {
        case .image:
            showImage(nextItem)
        case .video:
            showVideo(nextItem)
        }
    }

    private func showImage(_ item: SlideItem) {
        currentPlayerItem = nil
        videoPlayer.replaceCurrentItem(with: nil)

        Task {
            let image = await mediaLoader.loadImage(from: item.url)
            guard currentSlide?.id == item.id else { return } // Stale

            if let image = image {
                currentImage = image
                slideshowWindowController?.displayImage(image, transitionDuration: transitionDuration)

                // Schedule next slide
                slideTimer = Timer.scheduledTimer(withTimeInterval: slideDuration, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        guard self?.isPlaying == true else { return }
                        self?.advanceToNextSlide()
                    }
                }
            } else {
                // Skip corrupt file
                print("Failed to load image: \(item.url)")
                advanceToNextSlide()
            }
        }
    }

    private func showVideo(_ item: SlideItem) {
        currentImage = nil

        Task {
            guard let playerItem = await mediaLoader.makePlayerItem(from: item.url) else {
                print("Failed to load video: \(item.url)")
                advanceToNextSlide()
                return
            }

            guard currentSlide?.id == item.id else { return } // Stale

            currentPlayerItem = playerItem
            videoPlayer.replaceCurrentItem(with: playerItem)
            videoPlayer.isMuted = !videoAudioEnabled
            slideshowWindowController?.displayVideo(player: videoPlayer, transitionDuration: transitionDuration)

            // Remove previous observer
            if let observer = videoEndObserver {
                NotificationCenter.default.removeObserver(observer)
            }

            // Advance when video finishes
            videoEndObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndOfTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard self?.isPlaying == true else { return }
                    self?.advanceToNextSlide()
                }
            }

            videoPlayer.play()
        }
    }

    // MARK: - Bindings

    private func setupBindings() {
        // React to main folder watcher file changes
        mainFolderWatcher.$mediaFiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files in
                self?.slideshowPlaylist.syncItems(files)
                if let count = self?.slideshowPlaylist.totalCount {
                    if count == 0 && self?.isPlaying == false {
                        self?.statusMessage = "Watching folder — no media files found"
                    }
                }
            }
            .store(in: &cancellables)

        // React to marketing folder watcher file changes
        marketingFolderWatcher.$mediaFiles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] files in
                self?.marketingPlaylist.syncItems(files)
            }
            .store(in: &cancellables)

        // React to monitor changes
        monitorManager.$displays
            .receive(on: DispatchQueue.main)
            .sink { [weak self] displays in
                // If selected monitor disconnected, pause and warn
                if let selectedID = self?.monitorManager.selectedDisplayID,
                   !displays.contains(where: { $0.id == selectedID }) {
                    self?.pause()
                    self?.hideSlideshowWindow()
                    self?.statusMessage = "Selected monitor disconnected"
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Restore

    private func restoreFolders() {
        if let watchURL = UserDefaultsManager.resolveWatchFolder() {
            _ = watchURL.startAccessingSecurityScopedResource()
            mainFolderWatcher.startWatching(url: watchURL, recursive: watchRecursively)
            statusMessage = "Watching: \(watchURL.lastPathComponent)"
        }

        if let marketingURL = UserDefaultsManager.resolveMarketingFolder() {
            _ = marketingURL.startAccessingSecurityScopedResource()
            marketingFolderWatcher.startWatching(url: marketingURL, recursive: false)
        }

        // Auto-start if configured
        if autoStartSlideshow && mainFolderWatcher.isWatching && monitorManager.selectedDisplay != nil {
            // Delay slightly to allow initial scan to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.play()
            }
        }
    }
}
