import SwiftUI

struct PrintDetailView: View {
    @ObservedObject var job: PrintJob
    @EnvironmentObject var appState: AppState
    @State private var fullImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Print Detail")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Open in Finder
                    if let url = job.compositedImagePath {
                        Button(action: { NSWorkspace.shared.activateFileViewerSelecting([url]) }) {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // Open in Preview
                    if let url = job.compositedImagePath {
                        Button(action: { NSWorkspace.shared.open(url) }) {
                            Label("Open", systemImage: "eye")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            .padding(20)

            Divider()

            // Full-size preview
            ZStack {
                Color(nsColor: .controlBackgroundColor)

                if let image = fullImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                } else {
                    ProgressView("Loading...")
                }
            }

            Divider()

            // Info bar
            HStack(spacing: 20) {
                infoItem(title: "Template", value: job.template.name)
                Divider().frame(height: 30)
                infoItem(title: "Size", value: job.template.printSize.displayName)
                Divider().frame(height: 30)
                infoItem(title: "Photos", value: "\(job.sourceImagePaths.count)")
                Divider().frame(height: 30)
                infoItem(title: "Copies Printed", value: "\(job.copies)")
                Divider().frame(height: 30)
                infoItem(title: "Status", value: job.status.displayName)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear { loadFullImage() }
    }

    private func infoItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: job.completedAt ?? job.createdAt)
    }

    private func loadFullImage() {
        guard let url = job.compositedImagePath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let img = NSImage(contentsOf: url)
            DispatchQueue.main.async {
                self.fullImage = img
            }
        }
    }
}
