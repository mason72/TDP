import SwiftUI

struct PrintQueueView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Print Queue", systemImage: "printer")
                    .font(.headline)

                Spacer()

                if !appState.printQueueManager.jobs.isEmpty {
                    Button("Clear Completed") {
                        appState.printQueueManager.clearCompleted()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if allJobs.isEmpty {
                emptyState
            } else {
                jobList
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var allJobs: [PrintJob] {
        appState.printQueueManager.jobs + appState.printQueueManager.completedJobs.suffix(20).reversed()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "printer")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No print jobs yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var jobList: some View {
        List {
            // Active jobs
            if !appState.printQueueManager.jobs.isEmpty {
                Section("Active") {
                    ForEach(appState.printQueueManager.jobs) { job in
                        PrintJobRow(job: job)
                    }
                }
            }

            // Recent completed
            if !appState.printQueueManager.completedJobs.isEmpty {
                Section("Recent") {
                    ForEach(appState.printQueueManager.completedJobs.suffix(20).reversed()) { job in
                        PrintJobRow(job: job)
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Print Job Row

struct PrintJobRow: View {
    @ObservedObject var job: PrintJob

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon

            // Job info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(job.isReprint ? "Reprint" : "Print")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("× \(job.copies)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }

                HStack(spacing: 8) {
                    Text("\(job.sourceImagePaths.count) photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(job.template.printSize.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = job.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Status badge
            Text(job.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1), in: Capsule())

            // Progress indicator for active jobs
            if job.status == .compositing || job.status == .printing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: some View {
        Image(systemName: job.status.iconName)
            .font(.title3)
            .foregroundStyle(statusColor)
            .frame(width: 28)
    }

    private var statusColor: Color {
        switch job.status {
        case .pending: return .secondary
        case .compositing: return .blue
        case .printing: return .orange
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: job.completedAt ?? job.createdAt)
    }
}
