import Foundation
import SwiftUI

struct PrintTemplate: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var printSize: PrintSize
    var imageSlots: [ImageSlot]
    var backgroundImagePath: String?
    var overlayImagePath: String?
    var textOverlays: [TextOverlay]
    var backgroundColor: CodableColor
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Untitled Template",
        printSize: PrintSize = .fourBySix,
        imageSlots: [ImageSlot] = [],
        backgroundImagePath: String? = nil,
        overlayImagePath: String? = nil,
        textOverlays: [TextOverlay] = [],
        backgroundColor: CodableColor = .white,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.printSize = printSize
        self.imageSlots = imageSlots
        self.backgroundImagePath = backgroundImagePath
        self.overlayImagePath = overlayImagePath
        self.textOverlays = textOverlays
        self.backgroundColor = backgroundColor
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var imageCount: Int { imageSlots.count }

    var displayDescription: String {
        let size = printSize.displayName
        let slots = imageCount == 1 ? "1 photo" : "\(imageCount) photos"
        return "\(size) — \(slots)"
    }
}
