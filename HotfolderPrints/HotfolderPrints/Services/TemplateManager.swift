import Foundation

class TemplateManager: ObservableObject {
    @Published var templates: [PrintTemplate] = []
    @Published var selectedTemplate: PrintTemplate?

    private let templatesDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        templatesDirectory = appSupport.appendingPathComponent("HotfolderPrints/Templates")
        try? FileManager.default.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        loadTemplates()

        if templates.isEmpty {
            createDefaultTemplates()
            loadTemplates()
        }
    }

    func loadTemplates() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: templatesDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        templates = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> PrintTemplate? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(PrintTemplate.self, from: data)
            }
            .sorted { $0.name < $1.name }
    }

    func save(_ template: PrintTemplate) throws {
        var updated = template
        updated.updatedAt = Date()

        let data = try encoder.encode(updated)
        let fileURL = templatesDirectory.appendingPathComponent("\(updated.id.uuidString).json")
        try data.write(to: fileURL)

        loadTemplates()

        if selectedTemplate?.id == updated.id {
            selectedTemplate = updated
        }
    }

    func delete(_ template: PrintTemplate) throws {
        guard !template.isDefault else { return }
        let fileURL = templatesDirectory.appendingPathComponent("\(template.id.uuidString).json")
        try FileManager.default.removeItem(at: fileURL)
        loadTemplates()

        if selectedTemplate?.id == template.id {
            selectedTemplate = templates.first
        }
    }

    func duplicate(_ template: PrintTemplate) throws {
        var copy = template
        copy.id = UUID()
        copy.name = "\(template.name) Copy"
        copy.isDefault = false
        copy.createdAt = Date()
        copy.updatedAt = Date()
        try save(copy)
    }

    // MARK: - Default Templates

    private func createDefaultTemplates() {
        let defaults: [PrintTemplate] = [
            classicSingle(),
            sideBySide(),
            photoStrip(),
            gridFour(),
            headshotWithBranding(),
            eventCollage()
        ]

        for template in defaults {
            try? save(template)
        }
    }

    private func classicSingle() -> PrintTemplate {
        PrintTemplate(
            name: "Classic Single",
            printSize: .fourBySix,
            imageSlots: [
                ImageSlot(x: 0, y: 0, width: 1, height: 1, fitMode: .fill)
            ],
            isDefault: true
        )
    }

    private func sideBySide() -> PrintTemplate {
        let gap = 0.02
        let slotWidth = (1.0 - gap * 3) / 2
        return PrintTemplate(
            name: "Side by Side",
            printSize: .fourBySix,
            imageSlots: [
                ImageSlot(x: gap, y: gap, width: slotWidth, height: 1 - gap * 2, fitMode: .fill),
                ImageSlot(x: gap * 2 + slotWidth, y: gap, width: slotWidth, height: 1 - gap * 2, fitMode: .fill)
            ],
            isDefault: true
        )
    }

    private func photoStrip() -> PrintTemplate {
        let gap = 0.02
        let slotHeight = (1.0 - gap * 4) / 3
        return PrintTemplate(
            name: "Photo Strip",
            printSize: .fourBySix,
            imageSlots: [
                ImageSlot(x: gap, y: gap, width: 1 - gap * 2, height: slotHeight, fitMode: .fill),
                ImageSlot(x: gap, y: gap * 2 + slotHeight, width: 1 - gap * 2, height: slotHeight, fitMode: .fill),
                ImageSlot(x: gap, y: gap * 3 + slotHeight * 2, width: 1 - gap * 2, height: slotHeight, fitMode: .fill)
            ],
            isDefault: true
        )
    }

    private func gridFour() -> PrintTemplate {
        let gap = 0.02
        let slotWidth = (1.0 - gap * 3) / 2
        let slotHeight = (1.0 - gap * 3) / 2
        return PrintTemplate(
            name: "Grid (2×2)",
            printSize: .fourBySix,
            imageSlots: [
                ImageSlot(x: gap, y: gap, width: slotWidth, height: slotHeight, fitMode: .fill),
                ImageSlot(x: gap * 2 + slotWidth, y: gap, width: slotWidth, height: slotHeight, fitMode: .fill),
                ImageSlot(x: gap, y: gap * 2 + slotHeight, width: slotWidth, height: slotHeight, fitMode: .fill),
                ImageSlot(x: gap * 2 + slotWidth, y: gap * 2 + slotHeight, width: slotWidth, height: slotHeight, fitMode: .fill)
            ],
            isDefault: true
        )
    }

    private func headshotWithBranding() -> PrintTemplate {
        PrintTemplate(
            name: "Headshot with Branding",
            printSize: .fiveBySeven,
            imageSlots: [
                ImageSlot(x: 0.08, y: 0.05, width: 0.84, height: 0.75, fitMode: .fill, border: SlotBorder(color: .init(red: 0.9, green: 0.9, blue: 0.9), width: 0.3))
            ],
            textOverlays: [
                TextOverlay(text: "Your Event Name", x: 0.5, y: 0.9, fontSize: 3, fontName: "Helvetica Neue", color: .init(red: 0.3, green: 0.3, blue: 0.3), isBold: true, alignment: .center)
            ],
            isDefault: true
        )
    }

    private func eventCollage() -> PrintTemplate {
        PrintTemplate(
            name: "Event Collage",
            printSize: .eightByTen,
            imageSlots: [
                ImageSlot(x: 0.03, y: 0.03, width: 0.6, height: 0.6, fitMode: .fill),
                ImageSlot(x: 0.66, y: 0.03, width: 0.31, height: 0.29, fitMode: .fill),
                ImageSlot(x: 0.66, y: 0.34, width: 0.31, height: 0.29, fitMode: .fill),
                ImageSlot(x: 0.03, y: 0.66, width: 0.94, height: 0.31, fitMode: .fill)
            ],
            isDefault: true
        )
    }
}
