import Foundation
import AppKit
import CoreGraphics
import CoreImage

class ImageCompositor {

    enum CompositorError: LocalizedError {
        case cannotCreateContext
        case cannotLoadImage(URL)
        case cannotCreateOutput
        case cannotWriteFile(URL)

        var errorDescription: String? {
            switch self {
            case .cannotCreateContext: return "Failed to create graphics context"
            case .cannotLoadImage(let url): return "Failed to load image: \(url.lastPathComponent)"
            case .cannotCreateOutput: return "Failed to create composited image"
            case .cannotWriteFile(let url): return "Failed to write file: \(url.path)"
            }
        }
    }

    /// Composites images into a print layout based on the template.
    /// Returns the URL of the saved composited image.
    func composite(
        template: PrintTemplate,
        images: [URL],
        outputDirectory: URL
    ) throws -> URL {
        let width = template.printSize.pixelWidth
        let height = template.printSize.pixelHeight
        let size = CGSize(width: width, height: height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw CompositorError.cannotCreateContext
        }

        // Flip coordinate system (CG is bottom-left origin, we want top-left)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // 1. Draw background color
        let bgColor = template.backgroundColor
        context.setFillColor(CGColor(
            red: bgColor.red,
            green: bgColor.green,
            blue: bgColor.blue,
            alpha: bgColor.opacity
        ))
        context.fill(CGRect(origin: .zero, size: size))

        // 2. Draw background image (if any)
        if let bgPath = template.backgroundImagePath,
           let bgImage = loadCGImage(from: URL(fileURLWithPath: bgPath)) {
            drawImageFill(context: context, image: bgImage, rect: CGRect(origin: .zero, size: size))
        }

        // 3. Draw each image slot
        for (index, slot) in template.imageSlots.enumerated() {
            guard index < images.count else { break }
            guard let image = loadCGImage(from: images[index]) else { continue }

            let slotRect = CGRect(
                x: slot.x * CGFloat(width),
                y: slot.y * CGFloat(height),
                width: slot.width * CGFloat(width),
                height: slot.height * CGFloat(height)
            )

            context.saveGState()

            // Apply rotation around slot center
            if slot.rotation != 0 {
                let centerX = slotRect.midX
                let centerY = slotRect.midY
                context.translateBy(x: centerX, y: centerY)
                context.rotate(by: -slot.rotation * .pi / 180)
                context.translateBy(x: -centerX, y: -centerY)
            }

            // Apply corner radius clipping
            if slot.cornerRadius > 0 {
                let radiusPixels = slot.cornerRadius * CGFloat(min(width, height)) / 100
                let path = CGPath(roundedRect: slotRect, cornerWidth: radiusPixels, cornerHeight: radiusPixels, transform: nil)
                context.addPath(path)
                context.clip()
            }

            // Draw image with fit mode
            switch slot.fitMode {
            case .fill:
                drawImageFill(context: context, image: image, rect: slotRect)
            case .fit:
                drawImageFit(context: context, image: image, rect: slotRect)
            case .stretch:
                context.draw(image, in: slotRect)
            }

            // Draw border
            if let border = slot.border, border.width > 0 {
                let borderColor = CGColor(
                    red: border.color.red,
                    green: border.color.green,
                    blue: border.color.blue,
                    alpha: border.color.opacity
                )
                let borderWidth = border.width * CGFloat(min(width, height)) / 100
                context.setStrokeColor(borderColor)
                context.setLineWidth(borderWidth)
                if slot.cornerRadius > 0 {
                    let radiusPixels = slot.cornerRadius * CGFloat(min(width, height)) / 100
                    let path = CGPath(roundedRect: slotRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2),
                                      cornerWidth: radiusPixels, cornerHeight: radiusPixels, transform: nil)
                    context.addPath(path)
                    context.strokePath()
                } else {
                    context.stroke(slotRect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2))
                }
            }

            context.restoreGState()
        }

        // 4. Draw overlay image (if any)
        if let overlayPath = template.overlayImagePath,
           let overlayImage = loadCGImage(from: URL(fileURLWithPath: overlayPath)) {
            context.draw(overlayImage, in: CGRect(origin: .zero, size: size))
        }

        // 5. Draw text overlays
        for textOverlay in template.textOverlays {
            drawTextOverlay(context: context, overlay: textOverlay, canvasSize: size)
        }

        // 6. Export
        guard let cgImage = context.makeImage() else {
            throw CompositorError.cannotCreateOutput
        }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let filename = "print_\(timestamp).png"
        let outputURL = outputDirectory.appendingPathComponent(filename)

        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
            throw CompositorError.cannotCreateOutput
        }

        try pngData.write(to: outputURL)
        return outputURL
    }

    // MARK: - Private Helpers

    private func loadCGImage(from url: URL) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              CGImageSourceGetCount(imageSource) > 0 else { return nil }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

    private func drawImageFill(context: CGContext, image: CGImage, rect: CGRect) {
        let imageAspect = CGFloat(image.width) / CGFloat(image.height)
        let rectAspect = rect.width / rect.height
        var drawRect = rect

        if imageAspect > rectAspect {
            // Image is wider — scale by height, crop width
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.origin.x - (scaledWidth - rect.width) / 2,
                y: rect.origin.y,
                width: scaledWidth,
                height: rect.height
            )
        } else {
            // Image is taller — scale by width, crop height
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y - (scaledHeight - rect.height) / 2,
                width: rect.width,
                height: scaledHeight
            )
        }

        context.saveGState()
        context.clip(to: rect)
        context.draw(image, in: drawRect)
        context.restoreGState()
    }

    private func drawImageFit(context: CGContext, image: CGImage, rect: CGRect) {
        let imageAspect = CGFloat(image.width) / CGFloat(image.height)
        let rectAspect = rect.width / rect.height
        var drawRect: CGRect

        if imageAspect > rectAspect {
            // Image is wider — fit by width
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.height - scaledHeight) / 2,
                width: rect.width,
                height: scaledHeight
            )
        } else {
            // Image is taller — fit by height
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.origin.x + (rect.width - scaledWidth) / 2,
                y: rect.origin.y,
                width: scaledWidth,
                height: rect.height
            )
        }

        context.draw(image, in: drawRect)
    }

    private func drawTextOverlay(context: CGContext, overlay: TextOverlay, canvasSize: CGSize) {
        let fontSize = overlay.fontSize * canvasSize.height / 100

        var fontTraits: NSFontTraitMask = []
        if overlay.isBold { fontTraits.insert(.boldFontMask) }
        if overlay.isItalic { fontTraits.insert(.italicFontMask) }

        let baseFont = NSFont(name: overlay.fontName, size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)
        let font = NSFontManager.shared.convert(baseFont, toHaveTrait: fontTraits)

        let color = NSColor(
            red: overlay.color.red,
            green: overlay.color.green,
            blue: overlay.color.blue,
            alpha: overlay.color.opacity
        )

        var paragraphStyle = NSMutableParagraphStyle()
        switch overlay.alignment {
        case .leading: paragraphStyle.alignment = .left
        case .center: paragraphStyle.alignment = .center
        case .trailing: paragraphStyle.alignment = .right
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        let text = overlay.text as NSString
        let textSize = text.size(withAttributes: attributes)

        let x = overlay.x * canvasSize.width - textSize.width / 2
        let y = overlay.y * canvasSize.height - textSize.height / 2

        // Push NSGraphicsContext for text drawing
        let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        if overlay.rotation != 0 {
            let transform = NSAffineTransform()
            transform.translateX(by: x + textSize.width / 2, yBy: y + textSize.height / 2)
            transform.rotate(byDegrees: -overlay.rotation)
            transform.translateX(by: -(x + textSize.width / 2), yBy: -(y + textSize.height / 2))
            transform.concat()
        }

        text.draw(in: CGRect(x: x, y: y, width: textSize.width + 10, height: textSize.height + 4), withAttributes: attributes)

        NSGraphicsContext.restoreGraphicsState()
    }
}
