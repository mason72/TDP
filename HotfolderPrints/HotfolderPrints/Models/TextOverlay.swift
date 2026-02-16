import Foundation
import SwiftUI

struct TextOverlay: Codable, Identifiable, Equatable {
    var id: UUID
    var text: String
    /// Position as percentages (0-1) of the canvas
    var x: Double
    var y: Double
    var fontSize: Double
    var fontName: String
    var color: CodableColor
    var rotation: Double
    var isBold: Bool
    var isItalic: Bool
    var alignment: TextAlignment

    enum TextAlignment: String, Codable, CaseIterable {
        case leading, center, trailing
    }

    init(
        id: UUID = UUID(),
        text: String = "Event Name",
        x: Double = 0.5,
        y: Double = 0.9,
        fontSize: Double = 24,
        fontName: String = "Helvetica Neue",
        color: CodableColor = .black,
        rotation: Double = 0,
        isBold: Bool = false,
        isItalic: Bool = false,
        alignment: TextAlignment = .center
    ) {
        self.id = id
        self.text = text
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.fontName = fontName
        self.color = color
        self.rotation = rotation
        self.isBold = isBold
        self.isItalic = isItalic
        self.alignment = alignment
    }
}
