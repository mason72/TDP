import Foundation
import SwiftUI

struct SlotBorder: Codable, Equatable {
    var color: CodableColor
    var width: Double

    init(color: Color = .white, width: Double = 2) {
        self.color = CodableColor(color)
        self.width = width
    }
}

struct ImageSlot: Codable, Identifiable, Equatable {
    var id: UUID
    /// Position and size as percentages (0-1) of the canvas
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
    var cornerRadius: Double
    var fitMode: FitMode
    var border: SlotBorder?

    init(
        id: UUID = UUID(),
        x: Double = 0.1,
        y: Double = 0.1,
        width: Double = 0.8,
        height: Double = 0.8,
        rotation: Double = 0,
        cornerRadius: Double = 0,
        fitMode: FitMode = .fill,
        border: SlotBorder? = nil
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rotation = rotation
        self.cornerRadius = cornerRadius
        self.fitMode = fitMode
        self.border = border
    }

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - CodableColor helper

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(_ color: Color) {
        // Default to white; actual NSColor conversion happens at runtime
        self.red = 1
        self.green = 1
        self.blue = 1
        self.opacity = 1
    }

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: opacity)
    }

    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)
    static let clear = CodableColor(red: 0, green: 0, blue: 0, opacity: 0)
}
