import Foundation
import AppKit
import CoreGraphics

class ColorProfileManager {

    enum ColorProfile: String, CaseIterable, Identifiable {
        case sRGB = "sRGB"
        case adobeRGB = "Adobe RGB"
        case displayP3 = "Display P3"
        case printerDefault = "Printer Default"

        var id: String { rawValue }

        var colorSpace: CGColorSpace? {
            switch self {
            case .sRGB: return CGColorSpace(name: CGColorSpace.sRGB)
            case .adobeRGB: return CGColorSpace(name: CGColorSpace.adobeRGB1998)
            case .displayP3: return CGColorSpace(name: CGColorSpace.displayP3)
            case .printerDefault: return nil
            }
        }
    }

    static func availableICCProfiles() -> [URL] {
        let paths = [
            "/Library/ColorSync/Profiles",
            NSHomeDirectory() + "/Library/ColorSync/Profiles",
            "/System/Library/ColorSync/Profiles"
        ]

        return paths.flatMap { path -> [URL] in
            let url = URL(fileURLWithPath: path)
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) else { return [] }
            return contents.filter { $0.pathExtension.lowercased() == "icc" || $0.pathExtension.lowercased() == "icm" }
        }
    }
}
