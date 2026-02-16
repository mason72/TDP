import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Event Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Configure your watch folder, printer, and template before starting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Setup cards
                VStack(spacing: 16) {
                    FolderPickerView()
                    PrinterPickerView()
                    TemplatePickerCard()
                    EventSettingsView()
                }
                .padding(.horizontal, 40)

                // Start button
                startButton
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var startButton: some View {
        VStack(spacing: 12) {
            Button(action: handleEventToggle) {
                HStack(spacing: 8) {
                    Image(systemName: eventButtonIcon)
                        .font(.title3)
                    Text(eventButtonTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(eventButtonColor)
            .disabled(!appState.isReadyToStart && appState.eventState == .idle)
            .controlSize(.large)

            if appState.eventState == .running {
                Button("Pause Event") {
                    appState.pauseEvent()
                }
                .buttonStyle(.bordered)
            } else if appState.eventState == .paused {
                Button("Resume Event") {
                    appState.resumeEvent()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            Text(appState.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var eventButtonTitle: String {
        switch appState.eventState {
        case .idle: return "Start Event"
        case .running: return "Stop Event"
        case .paused: return "Stop Event"
        }
    }

    private var eventButtonIcon: String {
        switch appState.eventState {
        case .idle: return "play.fill"
        case .running: return "stop.fill"
        case .paused: return "stop.fill"
        }
    }

    private var eventButtonColor: Color {
        appState.eventState == .idle ? .accentColor : .red
    }

    private func handleEventToggle() {
        switch appState.eventState {
        case .idle:
            appState.startEvent()
            appState.selectedSection = .dashboard
        case .running, .paused:
            appState.stopEvent()
        }
    }
}

// MARK: - Template Picker Card

struct TemplatePickerCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SetupCard(
            title: "Print Template",
            icon: "rectangle.3.group",
            isConfigured: appState.templateManager.selectedTemplate != nil
        ) {
            if let template = appState.templateManager.selectedTemplate {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(template.displayDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Edit") {
                        appState.selectedSection = .templateEditor
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                HStack {
                    Text("No template selected")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose Template") {
                        appState.selectedSection = .templateEditor
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

// MARK: - Reusable Setup Card

struct SetupCard<Content: View>: View {
    let title: String
    let icon: String
    let isConfigured: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: isConfigured ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isConfigured ? .green : .secondary)
            }

            content()
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}
