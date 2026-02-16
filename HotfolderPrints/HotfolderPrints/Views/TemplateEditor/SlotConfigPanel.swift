import SwiftUI

struct SlotConfigPanel: View {
    @Binding var template: PrintTemplate
    @Binding var selectedSlotID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Properties")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if let slotIndex = selectedSlotIndex {
                ScrollView {
                    VStack(spacing: 20) {
                        slotProperties(index: slotIndex)
                    }
                    .padding(16)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Select a slot to edit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var selectedSlotIndex: Int? {
        guard let id = selectedSlotID else { return nil }
        return template.imageSlots.firstIndex(where: { $0.id == id })
    }

    // MARK: - Slot Properties

    @ViewBuilder
    private func slotProperties(index: Int) -> some View {
        let slot = template.imageSlots[index]

        // Position
        propertySection(title: "Position") {
            HStack(spacing: 12) {
                propertyField(label: "X", value: Binding(
                    get: { slot.x * 100 },
                    set: { template.imageSlots[index].x = $0 / 100 }
                ), suffix: "%")

                propertyField(label: "Y", value: Binding(
                    get: { slot.y * 100 },
                    set: { template.imageSlots[index].y = $0 / 100 }
                ), suffix: "%")
            }
        }

        // Size
        propertySection(title: "Size") {
            HStack(spacing: 12) {
                propertyField(label: "W", value: Binding(
                    get: { slot.width * 100 },
                    set: { template.imageSlots[index].width = max(5, $0) / 100 }
                ), suffix: "%")

                propertyField(label: "H", value: Binding(
                    get: { slot.height * 100 },
                    set: { template.imageSlots[index].height = max(5, $0) / 100 }
                ), suffix: "%")
            }
        }

        // Rotation
        propertySection(title: "Rotation") {
            HStack {
                Slider(value: Binding(
                    get: { slot.rotation },
                    set: { template.imageSlots[index].rotation = $0 }
                ), in: -180...180, step: 1)

                Text("\(Int(slot.rotation))°")
                    .font(.caption.monospacedDigit())
                    .frame(width: 40, alignment: .trailing)
            }
        }

        // Fit Mode
        propertySection(title: "Fit Mode") {
            Picker("", selection: Binding(
                get: { slot.fitMode },
                set: { template.imageSlots[index].fitMode = $0 }
            )) {
                ForEach(FitMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(slot.fitMode.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }

        // Corner Radius
        propertySection(title: "Corner Radius") {
            HStack {
                Slider(value: Binding(
                    get: { slot.cornerRadius },
                    set: { template.imageSlots[index].cornerRadius = $0 }
                ), in: 0...20, step: 0.5)

                Text(String(format: "%.1f", slot.cornerRadius))
                    .font(.caption.monospacedDigit())
                    .frame(width: 35, alignment: .trailing)
            }
        }

        // Border
        propertySection(title: "Border") {
            Toggle("Show border", isOn: Binding(
                get: { slot.border != nil },
                set: { enabled in
                    if enabled {
                        template.imageSlots[index].border = SlotBorder()
                    } else {
                        template.imageSlots[index].border = nil
                    }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            if let border = slot.border {
                HStack {
                    Text("Color")
                        .font(.caption)
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { border.color.color },
                        set: { newColor in
                            let nsColor = NSColor(newColor).usingColorSpace(.sRGB) ?? NSColor(newColor)
                            template.imageSlots[index].border?.color = CodableColor(
                                red: Double(nsColor.redComponent),
                                green: Double(nsColor.greenComponent),
                                blue: Double(nsColor.blueComponent),
                                opacity: Double(nsColor.alphaComponent)
                            )
                        }
                    ))
                    .labelsHidden()
                }

                HStack {
                    Text("Width")
                        .font(.caption)
                    Slider(value: Binding(
                        get: { border.width },
                        set: { template.imageSlots[index].border?.width = $0 }
                    ), in: 0.1...5, step: 0.1)
                    Text(String(format: "%.1f", border.width))
                        .font(.caption.monospacedDigit())
                        .frame(width: 30)
                }
            }
        }

        // Quick presets
        propertySection(title: "Quick Size") {
            HStack(spacing: 8) {
                presetButton("Full", x: 0, y: 0, w: 1, h: 1, index: index)
                presetButton("Half L", x: 0, y: 0, w: 0.5, h: 1, index: index)
                presetButton("Half T", x: 0, y: 0, w: 1, h: 0.5, index: index)
                presetButton("Quarter", x: 0, y: 0, w: 0.5, h: 0.5, index: index)
            }
        }
    }

    // MARK: - Components

    private func propertySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
    }

    private func propertyField(label: String, value: Binding<Double>, suffix: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            TextField("", value: value, format: .number.precision(.fractionLength(1)))
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospacedDigit())
                .frame(maxWidth: .infinity)

            Text(suffix)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func presetButton(_ label: String, x: Double, y: Double, w: Double, h: Double, index: Int) -> some View {
        Button(label) {
            template.imageSlots[index].x = x
            template.imageSlots[index].y = y
            template.imageSlots[index].width = w
            template.imageSlots[index].height = h
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .font(.caption2)
    }
}
