import Foundation

enum FitMode: String, Codable, CaseIterable, Identifiable {
    case fill = "fill"
    case fit = "fit"
    case stretch = "stretch"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fill: return "Fill (Crop)"
        case .fit: return "Fit (Letterbox)"
        case .stretch: return "Stretch"
        }
    }

    var description: String {
        switch self {
        case .fill: return "Fills the slot, cropping edges if needed"
        case .fit: return "Fits entire image within the slot"
        case .stretch: return "Stretches image to fill exactly"
        }
    }

    var iconName: String {
        switch self {
        case .fill: return "crop"
        case .fit: return "aspectratio"
        case .stretch: return "arrow.up.left.and.arrow.down.right"
        }
    }
}
