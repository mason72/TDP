import Foundation
import Combine

class PrintQueueManager: ObservableObject {
    @Published var jobs: [PrintJob] = []
    @Published var completedJobs: [PrintJob] = []
    @Published var isProcessing = false

    private let printService: PrintService
    private let compositor: ImageCompositor
    private var cancellables = Set<AnyCancellable>()
    private let outputDirectory: URL
    private var processingQueue = DispatchQueue(label: "com.hotfolderprints.printqueue", qos: .userInitiated)

    var totalPrintsMade: Int {
        completedJobs.filter { $0.status == .completed }.count
    }

    var totalCopiesPrinted: Int {
        completedJobs.filter { $0.status == .completed }.reduce(0) { $0 + $1.copies }
    }

    init(printService: PrintService, compositor: ImageCompositor, outputDirectory: URL) {
        self.printService = printService
        self.compositor = compositor
        self.outputDirectory = outputDirectory
    }

    func enqueue(_ job: PrintJob) {
        DispatchQueue.main.async { [weak self] in
            self?.jobs.append(job)
            self?.processNext()
        }
    }

    func reprint(job: PrintJob, copies: Int) {
        let reprintJob = PrintJob(
            template: job.template,
            sourceImagePaths: job.sourceImagePaths,
            copies: copies,
            isReprint: true
        )
        reprintJob.compositedImagePath = job.compositedImagePath
        enqueue(reprintJob)
    }

    func cancelJob(_ job: PrintJob) {
        DispatchQueue.main.async {
            job.status = .cancelled
        }
    }

    func clearCompleted() {
        jobs.removeAll { !$0.status.isActive }
    }

    private func processNext() {
        guard !isProcessing else { return }
        guard let nextJob = jobs.first(where: { $0.status == .pending }) else { return }

        isProcessing = true

        processingQueue.async { [weak self] in
            guard let self = self else { return }
            self.processJob(nextJob)
        }
    }

    private func processJob(_ job: PrintJob) {
        // Step 1: Composite (skip if already composited, e.g., reprint)
        if job.compositedImagePath == nil {
            DispatchQueue.main.async { job.status = .compositing }

            do {
                let outputURL = try compositor.composite(
                    template: job.template,
                    images: job.sourceImagePaths,
                    outputDirectory: outputDirectory
                )
                DispatchQueue.main.async { job.compositedImagePath = outputURL }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    job.status = .failed
                    job.errorMessage = error.localizedDescription
                    self?.moveToCompleted(job)
                    self?.isProcessing = false
                    self?.processNext()
                }
                return
            }
        }

        // Step 2: Print
        DispatchQueue.main.async { job.status = .printing }

        guard let compositedURL = job.compositedImagePath else {
            DispatchQueue.main.async { [weak self] in
                job.status = .failed
                job.errorMessage = "No composited image available"
                self?.moveToCompleted(job)
                self?.isProcessing = false
                self?.processNext()
            }
            return
        }

        let success = printService.printImage(
            at: compositedURL,
            copies: job.copies,
            printSize: job.template.printSize
        )

        DispatchQueue.main.async { [weak self] in
            if success {
                job.status = .completed
                job.completedAt = Date()
            } else {
                job.status = .failed
                job.errorMessage = "Print operation failed"
            }
            self?.moveToCompleted(job)
            self?.isProcessing = false
            self?.processNext()
        }
    }

    private func moveToCompleted(_ job: PrintJob) {
        completedJobs.append(job)
        jobs.removeAll { $0.id == job.id }
    }
}
