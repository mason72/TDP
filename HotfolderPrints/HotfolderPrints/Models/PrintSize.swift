import Foundation
import CoreGraphics

enum PrintSize: String, Codable, CaseIterable, Identifiable {
    case fourBySix = "4x6"
    case fiveBySeven = "5x7"
    case eightByTen = "8x10"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fourBySix: return "4\" × 6\""
        case .fiveBySeven: return "5\" × 7\""
        case .eightByTen: return "8\" × 10\""
        }
    }

    var widthInches: CGFloat {
        switch self {
        case .fourBySix: return 4
        case .fiveBySeven: return 5
        case .eightByTen: return 8
        }
    }

    var heightInches: CGFloat {
        switch self {
        case .fourBySix: return 6
        case .fiveBySeven: return 7
        case .eightByTen: return 10
        }
    }

    var dpi: CGFloat { 300 }

    var pixelWidth: Int { Int(widthInches * dpi) }
    var pixelHeight: Int { Int(heightInches * dpi) }

    var aspectRatio: CGFloat { widthInches / heightInches }

    var pixelSize: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }

    var inchSize: CGSize {
        CGSize(width: widthInches, height: heightInches)
    }
}
