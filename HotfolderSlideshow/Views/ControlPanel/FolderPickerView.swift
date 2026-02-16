import SwiftUI

/// Folder selection UI for the main slideshow folder and optional marketing folder.
struct FolderPickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main slideshow folder
            VStack(alignment: .leading, spacing: 8) {
                Text("Slideshow Folder")
                    .font(.headline)

                FolderRow(
                    label: "Watch Folder",
                    folderURL: appState.mainFolderWatcher.folderURL,
                    fileCount: appState.slideshowPlaylist.totalCount,
                    isWatching: appState.mainFolderWatcher.isWatching,
                    onSelect: selectWatchFolder,
                    onClear: nil
                )
            }

            // Marketing folder
            VStack(alignment: .leading, spacing: 8) {
                Text("Marketing Folder")
                    .font(.headline)

                FolderRow(
                    label: "Marketing",
                    folderURL: appState.marketingFolderWatcher.folderURL,
                    fileCount: appState.marketingPlaylist.allItems.count,
                    isWatching: appState.marketingFolderWatcher.isWatching,
                    onSelect: selectMarketingFolder,
                    onClear: appState.marketingFolderWatcher.isWatching ? appState.clearMarketingFolder : nil
                )

                if appState.marketingFolderWatcher.isWatching {
                    HStack(spacing: 4) {
                        Text("Show every")
                        Stepper(
                            value: $appState.marketingInterval,
                            in: 1...50,
                            step: 1
                        ) {
                            Text("\(appState.marketingInterval)")
                                .monospacedDigit()
                                .frame(width: 28, alignment: .center)
                        }
                        Text("slides")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: - Folder Pickers

    private func selectWatchFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder of images and videos for the slideshow"
        panel.prompt = "Select Folder"

        if panel.runModal() == .OK, let url = panel.url {
            appState.selectWatchFolder(url)
        }
    }

    private func selectMarketingFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder of marketing images/videos"
        panel.prompt = "Select Marketing Folder"

        if panel.runModal() == .OK, let url = panel.url {
            appState.selectMarketingFolder(url)
        }
    }
}

// MARK: - Folder Row

private struct FolderRow: View {
    let label: String
    let folderURL: URL?
    let fileCount: Int
    let isWatching: Bool
    let onSelect: () -> Void
    let onClear: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isWatching ? "folder.fill" : "folder.badge.plus")
                .font(.title3)
                .foregroundColor(isWatching ? .accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                if let url = folderURL {
                    Text(url.lastPathComponent)
                        .font(.subheadline)
                        .lineLimit(1)

                    Text("\(fileCount) media file\(fileCount == 1 ? "" : "s") — \(url.path)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No folder selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let onClear = onClear {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove \(label.lowercased()) folder")
            }

            Button("Browse...", action: onSelect)
                .controlSize(.small)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isWatching ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
