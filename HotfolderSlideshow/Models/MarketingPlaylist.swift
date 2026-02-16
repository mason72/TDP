import Foundation
import Combine

/// Manages marketing slides that are inserted at regular intervals.
/// Marketing slides play in alphabetical filename order (not randomized).
final class MarketingPlaylist: ObservableObject {
    @Published private(set) var allItems: [SlideItem] = []
    @Published var hasItems: Bool = false

    private var currentIndex: Int = 0

    // MARK: - Content Management

    /// Full sync: replace all items with the current folder contents, sorted alphabetically.
    func syncItems(_ urls: Set<URL>) {
        let sorted = urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        let newItems = sorted.map { SlideItem(url: $0) }

        // Preserve position if possible
        let previousFilename = currentIndex < allItems.count ? allItems[currentIndex].filename : nil
        allItems = newItems
        hasItems = !allItems.isEmpty

        // Try to maintain position based on filename
        if let prevName = previousFilename,
           let idx = allItems.firstIndex(where: { $0.filename == prevName }) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }
    }

    /// Clear all marketing items.
    func clear() {
        allItems.removeAll()
        hasItems = false
        currentIndex = 0
    }

    // MARK: - Playback

    /// Get the next marketing slide in alphabetical order, cycling back to start.
    func next() -> SlideItem? {
        guard !allItems.isEmpty else { return nil }

        if currentIndex >= allItems.count {
            currentIndex = 0
        }

        let item = allItems[currentIndex]
        currentIndex += 1
        return item
    }

    /// Peek at the next marketing slide without advancing.
    func peekNext() -> SlideItem? {
        guard !allItems.isEmpty else { return nil }
        let idx = currentIndex >= allItems.count ? 0 : currentIndex
        return allItems[idx]
    }

    /// Reset to the beginning.
    func reset() {
        currentIndex = 0
    }
}
