import SwiftUI

struct LayersPanelView: View {
    @Binding var template: PrintTemplate
    @Binding var selectedSlotID: UUID?

    @State private var showBackgroundPicker = false
    @State private var showOverlayPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Layers")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    // Overlay layer
                    layerRow(
                        icon: "square.stack.3d.up",
                        title: "Overlay",
                        subtitle: template.overlayImagePath != nil ? "Image set" : "None",
                        isHighlighted: false
                    ) {
                        HStack(spacing: 4) {
                            Button(action: pickOverlayImage) {
                                Image(systemName: "photo")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)

                            if template.overlayImagePath != nil {
                                Button(action: { template.overlayImagePath = nil }) {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, 12)

                    // Image slots
                    ForEach(Array(template.imageSlots.enumerated()), id: \.element.id) { index, slot in
                        layerRow(
                            icon: "photo",
                            title: "Image \(index + 1)",
                            subtitle: "\(Int(slot.width * 100))% × \(Int(slot.height * 100))%",
                            isHighlighted: selectedSlotID == slot.id
                        ) {
                            Button(action: { removeSlot(slot) }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .onTapGesture {
                            selectedSlotID = slot.id
                        }
                        .contentShape(Rectangle())
                    }

                    Divider()
                        .padding(.horizontal, 12)

                    // Background layer
                    layerRow(
                        icon: "rectangle.fill",
                        title: "Background",
                        subtitle: template.backgroundImagePath != nil ? "Image set" : colorDescription,
                        isHighlighted: false
                    ) {
                        HStack(spacing: 4) {
                            ColorPicker("", selection: Binding(
                                get: { template.backgroundColor.color },
                                set: { newColor in
                                    // Simple color binding — full NSColor conversion at runtime
                                    template.backgroundColor = colorToCodable(newColor)
                                }
                            ))
                            .labelsHidden()
                            .frame(width: 24)

                            Button(action: pickBackgroundImage) {
                                Image(systemName: "photo")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)

                            if template.backgroundImagePath != nil {
                                Button(action: { template.backgroundImagePath = nil }) {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, 12)

                    // Text overlays section
                    HStack {
                        Text("Text Overlays")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(action: addTextOverlay) {
                            Image(systemName: "plus")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    ForEach(Array(template.textOverlays.enumerated()), id: \.element.id) { index, overlay in
                        layerRow(
                            icon: "textformat",
                            title: overlay.text.isEmpty ? "Empty Text" : overlay.text,
                            subtitle: "\(overlay.fontName), \(Int(overlay.fontSize))pt",
                            isHighlighted: false
                        ) {
                            Button(action: { removeTextOverlay(overlay) }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Layer Row

    private func layerRow<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        isHighlighted: Bool,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isHighlighted ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }

    // MARK: - Actions

    private func removeSlot(_ slot: ImageSlot) {
        template.imageSlots.removeAll { $0.id == slot.id }
        if selectedSlotID == slot.id {
            selectedSlotID = template.imageSlots.first?.id
        }
    }

    private func addTextOverlay() {
        let overlay = TextOverlay()
        template.textOverlays.append(overlay)
    }

    private func removeTextOverlay(_ overlay: TextOverlay) {
        template.textOverlays.removeAll { $0.id == overlay.id }
    }

    private func pickBackgroundImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Background Image"
        panel.allowedContentTypes = FileFilterUtility.supportedImageTypes
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            template.backgroundImagePath = url.path
        }
    }

    private func pickOverlayImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Overlay Image (PNG with transparency)"
        panel.allowedContentTypes = [.png]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            template.overlayImagePath = url.path
        }
    }

    private var colorDescription: String {
        let c = template.backgroundColor
        if c.red == 1 && c.green == 1 && c.blue == 1 { return "White" }
        if c.red == 0 && c.green == 0 && c.blue == 0 { return "Black" }
        return "Custom"
    }

    private func colorToCodable(_ color: Color) -> CodableColor {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return CodableColor(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            opacity: Double(nsColor.alphaComponent)
        )
    }
}
