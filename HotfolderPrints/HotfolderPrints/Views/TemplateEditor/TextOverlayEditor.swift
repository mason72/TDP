import SwiftUI

struct TextOverlayEditor: View {
    @Binding var overlay: TextOverlay

    @State private var availableFonts: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Overlay")
                .font(.headline)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text("Text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Enter text...", text: $overlay.text)
                    .textFieldStyle(.roundedBorder)
            }

            // Font
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Font")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $overlay.fontName) {
                        ForEach(availableFonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", value: $overlay.fontSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            // Style toggles
            HStack(spacing: 8) {
                Toggle(isOn: $overlay.isBold) {
                    Image(systemName: "bold")
                }
                .toggleStyle(.button)
                .controlSize(.small)

                Toggle(isOn: $overlay.isItalic) {
                    Image(systemName: "italic")
                }
                .toggleStyle(.button)
                .controlSize(.small)

                Spacer()

                ColorPicker("Color", selection: Binding(
                    get: { overlay.color.color },
                    set: { newColor in
                        let nsColor = NSColor(newColor).usingColorSpace(.sRGB) ?? NSColor(newColor)
                        overlay.color = CodableColor(
                            red: Double(nsColor.redComponent),
                            green: Double(nsColor.greenComponent),
                            blue: Double(nsColor.blueComponent),
                            opacity: Double(nsColor.alphaComponent)
                        )
                    }
                ))
                .labelsHidden()
            }

            // Position
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("X Position")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $overlay.x, in: 0...1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Y Position")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $overlay.y, in: 0...1)
                }
            }

            // Rotation
            HStack {
                Text("Rotation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $overlay.rotation, in: -180...180, step: 1)
                Text("\(Int(overlay.rotation))°")
                    .font(.caption.monospacedDigit())
                    .frame(width: 40)
            }

            // Alignment
            Picker("Alignment", selection: $overlay.alignment) {
                Image(systemName: "text.alignleft").tag(TextOverlay.TextAlignment.leading)
                Image(systemName: "text.aligncenter").tag(TextOverlay.TextAlignment.center)
                Image(systemName: "text.alignright").tag(TextOverlay.TextAlignment.trailing)
            }
            .pickerStyle(.segmented)
        }
        .onAppear {
            loadFonts()
        }
    }

    private func loadFonts() {
        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
        availableFonts = fontFamilies
    }
}
