import SwiftUI

struct FolderPickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SetupCard(
            title: "Watch Folder",
            icon: "folder.badge.questionmark",
            isConfigured: appState.watchFolderURL != nil
        ) {
            HStack {
                if let url = appState.watchFolderURL {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.lastPathComponent)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                } else {
                    Text("No folder selected")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Browse...") {
                    selectFolder()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if appState.watchFolderURL != nil {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text("New images added to this folder will be automatically printed")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Watch Folder"
        panel.message = "Select the folder where photo booth images will be saved"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.watchFolderURL = url
        }
    }
}
