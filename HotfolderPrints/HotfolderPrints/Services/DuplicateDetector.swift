import Foundation
import CryptoKit

class DuplicateDetector {
    private var knownHashes: Set<String> = []

    func isDuplicate(_ url: URL) -> Bool {
        guard let hash = fileHash(url) else { return false }
        return knownHashes.contains(hash)
    }

    func recordFile(_ url: URL) {
        guard let hash = fileHash(url) else { return }
        knownHashes.insert(hash)
    }

    func checkAndRecord(_ url: URL) -> Bool {
        guard let hash = fileHash(url) else { return false }
        if knownHashes.contains(hash) {
            return true // is duplicate
        }
        knownHashes.insert(hash)
        return false // not duplicate
    }

    func reset() {
        knownHashes.removeAll()
    }

    private func fileHash(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
