import SwiftUI

struct TemplateEditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingTemplate: PrintTemplate?
    @State private var selectedSlotID: UUID?
    @State private var showTemplateGallery = false
    @State private var showSaveDialog = false
    @State private var templateName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            editorToolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)

            Divider()

            // Main editor area
            HStack(spacing: 0) {
                // Left: Layers panel
                LayersPanelView(
                    template: templateBinding,
                    selectedSlotID: $selectedSlotID
                )
                .frame(width: 240)

                Divider()

                // Center: Canvas
                CanvasView(
                    template: templateBinding,
                    selectedSlotID: $selectedSlotID
                )

                Divider()

                // Right: Properties panel
                SlotConfigPanel(
                    template: templateBinding,
                    selectedSlotID: $selectedSlotID
                )
                .frame(width: 280)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if editingTemplate == nil {
                editingTemplate = appState.templateManager.selectedTemplate
                    ?? appState.templateManager.templates.first
                    ?? createNewTemplate()
            }
        }
        .sheet(isPresented: $showTemplateGallery) {
            TemplateGalleryView(
                selectedTemplate: $editingTemplate,
                isPresented: $showTemplateGallery
            )
        }
        .sheet(isPresented: $showSaveDialog) {
            saveDialog
        }
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack(spacing: 12) {
            // Template selector
            Button(action: { showTemplateGallery = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.3.group")
                    Text(editingTemplate?.name ?? "Select Template")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.bordered)

            Divider()
                .frame(height: 20)

            // Print size picker
            if editingTemplate != nil {
                Picker("Size", selection: Binding(
                    get: { editingTemplate?.printSize ?? .fourBySix },
                    set: { editingTemplate?.printSize = $0 }
                )) {
                    ForEach(PrintSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .frame(width: 120)
            }

            Divider()
                .frame(height: 20)

            // Add slot button
            Button(action: addImageSlot) {
                Label("Add Image Slot", systemImage: "plus.rectangle")
            }
            .disabled((editingTemplate?.imageSlots.count ?? 0) >= 4)
            .help("Add an image slot (max 4)")

            Spacer()

            // Save actions
            Button(action: { showSaveDialog = true }) {
                Label("Save As...", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)

            Button(action: saveTemplate) {
                Label("Save", systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)

            Button("Use Template") {
                if let template = editingTemplate {
                    appState.templateManager.selectedTemplate = template
                    try? appState.templateManager.save(template)
                    appState.selectedSection = .setup
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    // MARK: - Save Dialog

    private var saveDialog: some View {
        VStack(spacing: 20) {
            Text("Save Template As")
                .font(.headline)

            TextField("Template Name", text: $templateName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack(spacing: 12) {
                Button("Cancel") {
                    showSaveDialog = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    saveTemplateAs(name: templateName)
                    showSaveDialog = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(30)
        .onAppear {
            templateName = editingTemplate?.name ?? ""
        }
    }

    // MARK: - Helpers

    private var templateBinding: Binding<PrintTemplate> {
        Binding(
            get: { editingTemplate ?? createNewTemplate() },
            set: { editingTemplate = $0 }
        )
    }

    private func createNewTemplate() -> PrintTemplate {
        PrintTemplate(
            name: "New Template",
            printSize: .fourBySix,
            imageSlots: [
                ImageSlot(x: 0.05, y: 0.05, width: 0.9, height: 0.9, fitMode: .fill)
            ]
        )
    }

    private func addImageSlot() {
        guard var template = editingTemplate, template.imageSlots.count < 4 else { return }
        let newSlot = ImageSlot(
            x: 0.1 + Double(template.imageSlots.count) * 0.05,
            y: 0.1 + Double(template.imageSlots.count) * 0.05,
            width: 0.4,
            height: 0.4,
            fitMode: .fill
        )
        template.imageSlots.append(newSlot)
        editingTemplate = template
        selectedSlotID = newSlot.id
    }

    private func saveTemplate() {
        guard let template = editingTemplate else { return }
        try? appState.templateManager.save(template)
    }

    private func saveTemplateAs(name: String) {
        guard var template = editingTemplate else { return }
        template.id = UUID()
        template.name = name
        template.isDefault = false
        try? appState.templateManager.save(template)
        editingTemplate = template
    }
}
