import SwiftUI

struct TemplateGalleryView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTemplate: PrintTemplate?
    @Binding var isPresented: Bool

    @State private var filterSize: PrintSize?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Template Gallery")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Filter by size
                Picker("Size", selection: $filterSize) {
                    Text("All Sizes").tag(nil as PrintSize?)
                    ForEach(PrintSize.allCases) { size in
                        Text(size.displayName).tag(size as PrintSize?)
                    }
                }
                .frame(width: 140)

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(20)

            Divider()

            // Templates grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredTemplates) { template in
                        TemplateCardView(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            onSelect: {
                                selectedTemplate = template
                                isPresented = false
                            },
                            onDuplicate: {
                                try? appState.templateManager.duplicate(template)
                            },
                            onDelete: template.isDefault ? nil : {
                                try? appState.templateManager.delete(template)
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 700, height: 500)
    }

    private var filteredTemplates: [PrintTemplate] {
        if let size = filterSize {
            return appState.templateManager.templates.filter { $0.printSize == size }
        }
        return appState.templateManager.templates
    }
}

// MARK: - Template Card

struct TemplateCardView: View {
    let template: PrintTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Preview
            templatePreview
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(8)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    if template.isDefault {
                        Text("Built-in")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }

                HStack {
                    Text(template.printSize.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(template.imageCount == 1 ? "1 photo" : "\(template.imageCount) photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : .quaternary, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.08 : 0), radius: 4, y: 2)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect() }
        .contextMenu {
            Button("Duplicate") { onDuplicate() }
            if let delete = onDelete {
                Divider()
                Button("Delete", role: .destructive) { delete() }
            }
        }
    }

    private var templatePreview: some View {
        GeometryReader { geo in
            let aspect = template.printSize.aspectRatio
            let previewWidth = min(geo.size.width, geo.size.height * aspect)
            let previewHeight = previewWidth / aspect

            ZStack {
                // Background
                Rectangle()
                    .fill(Color(
                        red: template.backgroundColor.red,
                        green: template.backgroundColor.green,
                        blue: template.backgroundColor.blue
                    ))

                // Slots
                ForEach(Array(template.imageSlots.enumerated()), id: \.element.id) { index, slot in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        )
                        .frame(
                            width: slot.width * previewWidth,
                            height: slot.height * previewHeight
                        )
                        .rotationEffect(.degrees(slot.rotation))
                        .position(
                            x: (slot.x + slot.width / 2) * previewWidth,
                            y: (slot.y + slot.height / 2) * previewHeight
                        )
                }
            }
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
