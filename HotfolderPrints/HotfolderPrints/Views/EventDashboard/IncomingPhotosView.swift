import SwiftUI

struct IncomingPhotosView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Incoming Photos", systemImage: "photo.stack")
                    .font(.headline)

                Spacer()

                if let template = appState.templateManager.selectedTemplate {
                    Text("\(appState.incomingPhotos.count) / \(template.imageCount) for next print")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if appState.incomingPhotos.isEmpty {
                emptyState
            } else {
                photoGrid
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("Waiting for photos...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if appState.eventState == .running {
                ProgressView()
                    .controlSize(.small)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(appState.incomingPhotos.enumerated()), id: \.offset) { index, url in
                    incomingPhotoThumbnail(url: url, index: index)
                }
            }
            .padding(12)
        }
    }

    private func incomingPhotoThumbnail(url: URL, index: Int) -> some View {
        VStack(spacing: 4) {
            AsyncThumbnailView(url: url)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("#\(index + 1)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Async Thumbnail

struct AsyncThumbnailView: View {
    let url: URL
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay(
                        ProgressView()
                            .controlSize(.small)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let thumb = ImageUtils.thumbnail(for: url, maxSize: 200)
            DispatchQueue.main.async {
                self.image = thumb
            }
        }
    }
}
