import Foundation
import Combine

/// Manages the slideshow playback order with:
/// - Full-cycle shuffle (no repeats until all shown)
/// - New content priority (newly added files play next)
/// - Marketing slide insertion at configurable intervals
final class SlideshowPlaylist: ObservableObject {
    @Published private(set) var allItems: [URL: SlideItem] = [:]
    @Published private(set) var currentItem: SlideItem?
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var currentIndex: Int = 0

    private var shuffledQueue: [SlideItem] = []
    private var newItemQueue: [SlideItem] = []
    private var shownInCurrentCycle: Set<URL> = []

    private let marketingPlaylist: MarketingPlaylist
    private var slidesSinceLastMarketing: Int = 0
    var marketingInterval: Int = 4

    init(marketingPlaylist: MarketingPlaylist) {
        self.marketingPlaylist = marketingPlaylist
    }

    // MARK: - Content Management

    /// Add new files discovered by the folder watcher.
    func addItems(_ urls: [URL]) {
        var newlyAdded: [SlideItem] = []
        for url in urls {
            guard allItems[url] == nil else { continue }
            let item = SlideItem(url: url)
            allItems[url] = item
            newlyAdded.append(item)
        }

        // New items get priority — queue them to play next
        newItemQueue.append(contentsOf: newlyAdded)
        totalCount = allItems.count
    }

    /// Remove files that were deleted from the watched folder.
    func removeItems(_ urls: [URL]) {
        for url in urls {
            allItems.removeValue(forKey: url)
            newItemQueue.removeAll { $0.url == url }
            shuffledQueue.removeAll { $0.url == url }
            shownInCurrentCycle.remove(url)
        }
        totalCount = allItems.count
    }

    /// Full sync: set the complete list of files. Detects additions and removals.
    func syncItems(_ urls: Set<URL>) {
        let currentURLs = Set(allItems.keys)
        let added = urls.subtracting(currentURLs)
        let removed = currentURLs.subtracting(urls)

        if !removed.isEmpty {
            removeItems(Array(removed))
        }
        if !added.isEmpty {
            addItems(Array(added))
        }
    }

    // MARK: - Playback

    /// Returns the next slide to display.
    func next() -> SlideItem? {
        guard !allItems.isEmpty else { return nil }

        // Check if a marketing slide is due
        if marketingPlaylist.hasItems && slidesSinceLastMarketing >= marketingInterval {
            if let marketingSlide = marketingPlaylist.next() {
                slidesSinceLastMarketing = 0
                currentItem = marketingSlide
                return marketingSlide
            }
        }

        // Priority: new items first
        if let newItem = nextNewItem() {
            slidesSinceLastMarketing += 1
            currentIndex += 1
            currentItem = newItem
            return newItem
        }

        // Otherwise: next from shuffled queue
        if let shuffled = nextShuffledItem() {
            slidesSinceLastMarketing += 1
            currentIndex += 1
            currentItem = shuffled
            return shuffled
        }

        return nil
    }

    /// Peek at what's coming next without advancing.
    func peekNext() -> SlideItem? {
        if marketingPlaylist.hasItems && slidesSinceLastMarketing >= marketingInterval {
            return marketingPlaylist.peekNext()
        }
        if let first = newItemQueue.first {
            return first
        }
        if shuffledQueue.isEmpty {
            // Would reshuffle — just return a random item
            return allItems.values.first
        }
        return shuffledQueue.first
    }

    /// Reset playback to the beginning.
    func reset() {
        shuffledQueue.removeAll()
        newItemQueue.removeAll()
        shownInCurrentCycle.removeAll()
        slidesSinceLastMarketing = 0
        currentIndex = 0
        currentItem = nil
    }

    // MARK: - Private

    private func nextNewItem() -> SlideItem? {
        while !newItemQueue.isEmpty {
            let item = newItemQueue.removeFirst()
            // Verify the item still exists in our collection
            if allItems[item.url] != nil {
                shownInCurrentCycle.insert(item.url)
                return item
            }
        }
        return nil
    }

    private func nextShuffledItem() -> SlideItem? {
        // If the shuffled queue is empty, reshuffle all items
        if shuffledQueue.isEmpty {
            reshuffle()
        }

        while !shuffledQueue.isEmpty {
            let item = shuffledQueue.removeFirst()
            // Verify the item still exists
            if allItems[item.url] != nil {
                shownInCurrentCycle.insert(item.url)
                return item
            }
        }

        return nil
    }

    private func reshuffle() {
        shownInCurrentCycle.removeAll()
        currentIndex = 0
        shuffledQueue = Array(allItems.values).shuffled()
    }
}
