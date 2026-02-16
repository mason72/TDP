import SwiftUI

/// The main control window showing all settings and playback controls.
struct ControlPanelView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                Divider()

                // Monitor selection
                MonitorPickerView()

                Divider()

                // Folder selection
                FolderPickerView()

                Divider()

                // Settings
                SettingsView()

                Divider()

                // Playback controls
                playbackControls

                Spacer()
            }
            .padding(20)
        }
        .frame(minWidth: 500, idealWidth: 520, minHeight: 600)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hotfolder Slideshow")
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(appState.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var statusColor: Color {
        if appState.isPlaying {
            return .green
        } else if appState.mainFolderWatcher.isWatching {
            return .orange
        } else {
            return .gray
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playback")
                .font(.headline)

            HStack(spacing: 16) {
                Button(action: { appState.previousSlide() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(!appState.isPlaying)

                Button(action: { appState.togglePlayPause() }) {
                    Image(systemName: appState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }
                .buttonStyle(.borderless)
                .disabled(!appState.mainFolderWatcher.isWatching || appState.monitorManager.selectedDisplay == nil)

                Button(action: { appState.nextSlide() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(!appState.isPlaying)

                Spacer()

                Button(action: { appState.stop() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(!appState.isPlaying)
            }

            // Current slide info
            if let slide = appState.currentSlide {
                HStack {
                    if let image = appState.currentImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 60)
                            .cornerRadius(4)
                            .shadow(radius: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 60)
                            .overlay(
                                Image(systemName: "video.fill")
                                    .foregroundColor(.secondary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(slide.filename)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text("\(appState.slideshowPlaylist.currentIndex) of \(appState.slideshowPlaylist.totalCount) slides")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
