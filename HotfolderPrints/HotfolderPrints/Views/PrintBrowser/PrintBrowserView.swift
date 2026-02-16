import SwiftUI

struct PrintBrowserView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedJob: PrintJob?
    @State private var showReprintSheet = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .newest

    enum SortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Print Browser")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(completedJobs.count) prints · \(totalCopies) total copies")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Controls
                HStack(spacing: 12) {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .frame(width: 140)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)

            Divider()

            if completedJobs.isEmpty {
                emptyState
            } else {
                printGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showReprintSheet) {
            if let job = selectedJob {
                ReprintSheet(job: job, isPresented: $showReprintSheet)
            }
        }
    }

    // MARK: - Computed

    private var completedJobs: [PrintJob] {
        let jobs = appState.printQueueManager.completedJobs.filter { $0.status == .completed }
        switch sortOrder {
        case .newest: return jobs.reversed()
        case .oldest: return jobs
        }
    }

    private var totalCopies: Int {
        appState.printQueueManager.totalCopiesPrinted
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("No Prints Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Completed prints will appear here for easy browsing and reprinting.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            if appState.eventState == .idle {
                Button("Start an Event") {
                    appState.selectedSection = .setup
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
    }

    // MARK: - Print Grid

    private var printGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
            ], spacing: 16) {
                ForEach(completedJobs) { job in
                    PrintThumbnailCard(job: job) {
                        selectedJob = job
                        showReprintSheet = true
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Print Thumbnail Card

struct PrintThumbnailCard: View {
    @ObservedObject var job: PrintJob
    let onTap: () -> Void

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                if let image = thumbnail {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                }

                // Hover overlay
                if isHovered {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "printer")
                                    .font(.title2)
                                Text("Tap to Reprint")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                        )
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack(spacing: 4) {
                        Text("\(job.sourceImagePaths.count) photos")
                        Text("·")
                        Text("×\(job.copies)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(job.template.printSize.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: 6, y: 3)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { onTap() }
        .onAppear { loadThumbnail() }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: job.completedAt ?? job.createdAt)
    }

    private func loadThumbnail() {
        guard let url = job.compositedImagePath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let thumb = ImageUtils.thumbnail(for: url, maxSize: 400)
            DispatchQueue.main.async {
                self.thumbnail = thumb
            }
        }
    }
}
