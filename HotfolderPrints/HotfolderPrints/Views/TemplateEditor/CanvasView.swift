import SwiftUI

struct CanvasView: View {
    @Binding var template: PrintTemplate
    @Binding var selectedSlotID: UUID?

    @State private var canvasSize: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var resizeHandle: ResizeHandle?
    @State private var initialSlotRect: CGRect = .zero

    enum ResizeHandle {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        GeometryReader { geometry in
            let canvasRect = calculateCanvasRect(in: geometry.size)

            ZStack {
                // Background fill
                Color(nsColor: .controlBackgroundColor)

                // Centered canvas
                ZStack {
                    // Canvas background
                    canvasBackground(size: canvasRect.size)

                    // Image slots
                    ForEach(Array(template.imageSlots.enumerated()), id: \.element.id) { index, slot in
                        SlotOverlayView(
                            slot: slot,
                            index: index,
                            canvasSize: canvasRect.size,
                            isSelected: selectedSlotID == slot.id,
                            onSelect: { selectedSlotID = slot.id },
                            onMove: { newOrigin in
                                moveSlot(id: slot.id, to: newOrigin, canvasSize: canvasRect.size)
                            },
                            onResize: { newRect in
                                resizeSlot(id: slot.id, to: newRect, canvasSize: canvasRect.size)
                            }
                        )
                    }

                    // Text overlays preview
                    ForEach(template.textOverlays) { overlay in
                        TextOverlayPreview(overlay: overlay, canvasSize: canvasRect.size)
                    }

                    // Overlay image preview
                    if let overlayPath = template.overlayImagePath,
                       let image = NSImage(contentsOfFile: overlayPath) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: canvasRect.size.width, height: canvasRect.size.height)
                            .clipped()
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: canvasRect.size.width, height: canvasRect.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                selectedSlotID = nil
            }
        }
        .padding(20)
    }

    // MARK: - Canvas Background

    @ViewBuilder
    private func canvasBackground(size: CGSize) -> some View {
        ZStack {
            // Background color
            Rectangle()
                .fill(Color(
                    red: template.backgroundColor.red,
                    green: template.backgroundColor.green,
                    blue: template.backgroundColor.blue,
                    opacity: template.backgroundColor.opacity
                ))

            // Background image
            if let bgPath = template.backgroundImagePath,
               let image = NSImage(contentsOfFile: bgPath) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: - Canvas Sizing

    private func calculateCanvasRect(in containerSize: CGSize) -> CGRect {
        let padding: CGFloat = 40
        let availableWidth = containerSize.width - padding * 2
        let availableHeight = containerSize.height - padding * 2
        let printAspect = template.printSize.aspectRatio

        var canvasWidth: CGFloat
        var canvasHeight: CGFloat

        if availableWidth / availableHeight > printAspect {
            // Container is wider — fit by height
            canvasHeight = availableHeight
            canvasWidth = canvasHeight * printAspect
        } else {
            // Container is taller — fit by width
            canvasWidth = availableWidth
            canvasHeight = canvasWidth / printAspect
        }

        let x = (containerSize.width - canvasWidth) / 2
        let y = (containerSize.height - canvasHeight) / 2

        return CGRect(x: x, y: y, width: canvasWidth, height: canvasHeight)
    }

    // MARK: - Slot Manipulation

    private func moveSlot(id: UUID, to newOrigin: CGPoint, canvasSize: CGSize) {
        guard let index = template.imageSlots.firstIndex(where: { $0.id == id }) else { return }
        template.imageSlots[index].x = max(0, min(1 - template.imageSlots[index].width, Double(newOrigin.x / canvasSize.width)))
        template.imageSlots[index].y = max(0, min(1 - template.imageSlots[index].height, Double(newOrigin.y / canvasSize.height)))
    }

    private func resizeSlot(id: UUID, to newRect: CGRect, canvasSize: CGSize) {
        guard let index = template.imageSlots.firstIndex(where: { $0.id == id }) else { return }
        template.imageSlots[index].x = max(0, Double(newRect.origin.x / canvasSize.width))
        template.imageSlots[index].y = max(0, Double(newRect.origin.y / canvasSize.height))
        template.imageSlots[index].width = max(0.05, min(1, Double(newRect.width / canvasSize.width)))
        template.imageSlots[index].height = max(0.05, min(1, Double(newRect.height / canvasSize.height)))
    }
}

// MARK: - Slot Overlay View

struct SlotOverlayView: View {
    let slot: ImageSlot
    let index: Int
    let canvasSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onMove: (CGPoint) -> Void
    let onResize: (CGRect) -> Void

    @State private var dragStart: CGPoint?

    private var slotFrame: CGRect {
        CGRect(
            x: slot.x * canvasSize.width,
            y: slot.y * canvasSize.height,
            width: slot.width * canvasSize.width,
            height: slot.height * canvasSize.height
        )
    }

    var body: some View {
        ZStack {
            // Slot fill
            RoundedRectangle(cornerRadius: slot.cornerRadius * min(canvasSize.width, canvasSize.height) / 100)
                .fill(Color.accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: slot.cornerRadius * min(canvasSize.width, canvasSize.height) / 100)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.accentColor.opacity(0.4),
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [6, 3])
                        )
                )

            // Slot label
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Image \(index + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // Resize handles (when selected)
            if isSelected {
                ForEach(Corner.allCases, id: \.self) { corner in
                    resizeHandleView(corner: corner)
                }
            }
        }
        .frame(width: slotFrame.width, height: slotFrame.height)
        .rotationEffect(.degrees(slot.rotation))
        .position(
            x: slotFrame.midX,
            y: slotFrame.midY
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragStart == nil {
                        dragStart = CGPoint(x: slot.x * canvasSize.width, y: slot.y * canvasSize.height)
                    }
                    if let start = dragStart {
                        let newX = start.x + value.translation.width
                        let newY = start.y + value.translation.height
                        onMove(CGPoint(x: newX, y: newY))
                    }
                }
                .onEnded { _ in
                    dragStart = nil
                }
        )
        .onTapGesture {
            onSelect()
        }
    }

    enum Corner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func resizeHandleView(corner: Corner) -> some View {
        let handleSize: CGFloat = 10

        return Circle()
            .fill(Color.accentColor)
            .frame(width: handleSize, height: handleSize)
            .shadow(radius: 2)
            .position(cornerPosition(corner))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleResize(corner: corner, translation: value.translation)
                    }
            )
    }

    private func cornerPosition(_ corner: Corner) -> CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .topRight: return CGPoint(x: slotFrame.width, y: 0)
        case .bottomLeft: return CGPoint(x: 0, y: slotFrame.height)
        case .bottomRight: return CGPoint(x: slotFrame.width, y: slotFrame.height)
        }
    }

    private func handleResize(corner: Corner, translation: CGSize) {
        var newRect = slotFrame

        switch corner {
        case .topLeft:
            newRect.origin.x += translation.width
            newRect.origin.y += translation.height
            newRect.size.width -= translation.width
            newRect.size.height -= translation.height
        case .topRight:
            newRect.origin.y += translation.height
            newRect.size.width += translation.width
            newRect.size.height -= translation.height
        case .bottomLeft:
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width
            newRect.size.height += translation.height
        case .bottomRight:
            newRect.size.width += translation.width
            newRect.size.height += translation.height
        }

        // Enforce minimum size
        if newRect.width >= 20 && newRect.height >= 20 {
            onResize(newRect)
        }
    }
}

// MARK: - Text Overlay Preview

struct TextOverlayPreview: View {
    let overlay: TextOverlay
    let canvasSize: CGSize

    var body: some View {
        Text(overlay.text)
            .font(.system(size: max(8, overlay.fontSize * canvasSize.height / 100)))
            .fontWeight(overlay.isBold ? .bold : .regular)
            .italic(overlay.isItalic)
            .foregroundStyle(Color(
                red: overlay.color.red,
                green: overlay.color.green,
                blue: overlay.color.blue,
                opacity: overlay.color.opacity
            ))
            .rotationEffect(.degrees(overlay.rotation))
            .position(
                x: overlay.x * canvasSize.width,
                y: overlay.y * canvasSize.height
            )
            .allowsHitTesting(false)
    }
}
