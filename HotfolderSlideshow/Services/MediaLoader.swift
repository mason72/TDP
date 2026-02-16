import AppKit
import AVFoundation
import Combine

/// Asynchronously loads and caches media (images and video assets) for smooth slideshow transitions.
final class MediaLoader: ObservableObject {
    /// Cache for loaded NSImage objects
    private var imageCache = NSCache<NSURL, NSImage>()

    /// Cache for prepared AVPlayerItem factories (we store the AVAsset, create items on demand)
    private var assetCache = NSCache<NSURL, AVAsset>()

    private let loadQueue = DispatchQueue(label: "com.hotfolderslideshow.medialoader", qos: .userInitiated, attributes: .concurrent)

    init() {
        imageCache.countLimit = 20
        assetCache.countLimit = 10
    }

    // MARK: - Image Loading

    /// Load an image asynchronously. Returns cached version if available.
    func loadImage(from url: URL) async -> NSImage? {
        // Check cache first
        if let cached = imageCache.object(forKey: url as NSURL) {
            return cached
        }

        return await withCheckedContinuation { continuation in
            loadQueue.async { [weak self] in
                guard let image = NSImage(contentsOf: url) else {
                    continuation.resume(returning: nil)
                    return
                }

                // Prepare the image for display — force a bitmap rep to load
                // This prevents jank when the image is first drawn on screen
                image.cacheMode = .always
                if let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData) {
                    let prepared = NSImage(size: bitmap.size)
                    prepared.addRepresentation(bitmap)
                    self?.imageCache.setObject(prepared, forKey: url as NSURL)
                    continuation.resume(returning: prepared)
                } else {
                    self?.imageCache.setObject(image, forKey: url as NSURL)
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Load a video AVAsset asynchronously.
    func loadVideoAsset(from url: URL) async -> AVAsset? {
        // Check cache
        if let cached = assetCache.object(forKey: url as NSURL) {
            return cached
        }

        let asset = AVAsset(url: url)
        do {
            // Pre-load essential properties so playback starts without delay
            let _ = try await asset.load(.isPlayable, .duration, .tracks)
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else { return nil }
            assetCache.setObject(asset, forKey: url as NSURL)
            return asset
        } catch {
            print("Failed to load video asset at \(url): \(error)")
            return nil
        }
    }

    /// Create an AVPlayerItem for a video URL (always a fresh item — AVPlayerItem cannot be reused).
    func makePlayerItem(from url: URL) async -> AVPlayerItem? {
        guard let asset = await loadVideoAsset(from: url) else { return nil }
        return AVPlayerItem(asset: asset)
    }

    // MARK: - Preloading

    /// Preload the next N slides for smooth transitions.
    func preload(items: [SlideItem]) {
        for item in items {
            switch item.mediaType {
            case .image:
                Task {
                    let _ = await loadImage(from: item.url)
                }
            case .video:
                Task {
                    let _ = await loadVideoAsset(from: item.url)
                }
            }
        }
    }

    // MARK: - Cache Management

    /// Remove a specific URL from all caches.
    func evict(url: URL) {
        imageCache.removeObject(forKey: url as NSURL)
        assetCache.removeObject(forKey: url as NSURL)
    }

    /// Clear all caches.
    func clearAll() {
        imageCache.removeAllObjects()
        assetCache.removeAllObjects()
    }
}
