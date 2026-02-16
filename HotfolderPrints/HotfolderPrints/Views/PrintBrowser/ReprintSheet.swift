import SwiftUI

struct ReprintSheet: View {
    @ObservedObject var job: PrintJob
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState

    @State private var copies: Int = 1
    @State private var thumbnail: NSImage?
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Reprint")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(20)

            Divider()

            // Content
            HStack(spacing: 24) {
                // Preview
                ZStack {
                    Color(nsColor: .controlBackgroundColor)
                    if let image = thumbnail {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 250, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )

                // Controls
                VStack(alignment: .leading, spacing: 20) {
                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: "Template", value: job.template.name)
                        infoRow(label: "Print Size", value: job.template.printSize.displayName)
                        infoRow(label: "Photos", value: "\(job.sourceImagePaths.count)")
                        infoRow(label: "Printer", value: appState.printService.selectedPrinterName ?? "None")
                    }

                    Divider()

                    // Copies selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Copies")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 16) {
                            // Quick select buttons
                            ForEach([1, 2, 3, 5, 10], id: \.self) { count in
                                Button("\(count)") {
                                    copies = count
                                }
                                .buttonStyle(copies == count ? .borderedProminent : .bordered)
                                .controlSize(.regular)
                            }
                        }

                        // Custom stepper
                        HStack(spacing: 8) {
                            Text("Custom:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(action: { if copies > 1 { copies -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderless)
                            .disabled(copies <= 1)

                            Text("\(copies)")
                                .font(.title.monospacedDigit())
                                .fontWeight(.bold)
                                .frame(minWidth: 50)

                            Button(action: { if copies < 99 { copies += 1 } }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderless)
                            .disabled(copies >= 99)
                        }
                    }

                    Spacer()

                    // Print button
                    if showConfirmation {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Sent to printer!")
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(action: reprint) {
                            HStack(spacing: 8) {
                                Image(systemName: "printer.fill")
                                Text("Print \(copies) \(copies == 1 ? "Copy" : "Copies")")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 620, height: 400)
        .onAppear { loadThumbnail() }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private func reprint() {
        appState.printQueueManager.reprint(job: job, copies: copies)

        withAnimation(.spring()) {
            showConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }

    private func loadThumbnail() {
        guard let url = job.compositedImagePath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let thumb = ImageUtils.thumbnail(for: url, maxSize: 500)
            DispatchQueue.main.async {
                self.thumbnail = thumb
            }
        }
    }
}
