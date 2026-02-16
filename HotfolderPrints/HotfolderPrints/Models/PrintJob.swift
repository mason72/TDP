import Foundation
import AppKit

enum PrintJobStatus: String, Codable {
    case pending
    case compositing
    case printing
    case completed
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .compositing: return "Compositing"
        case .printing: return "Printing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .compositing: return "gearshape.2"
        case .printing: return "printer"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    var isActive: Bool {
        self == .pending || self == .compositing || self == .printing
    }
}

class PrintJob: Identifiable, ObservableObject {
    let id: UUID
    let template: PrintTemplate
    let sourceImagePaths: [URL]
    @Published var compositedImagePath: URL?
    @Published var status: PrintJobStatus
    @Published var copies: Int
    @Published var errorMessage: String?
    let createdAt: Date
    @Published var completedAt: Date?
    let isReprint: Bool

    init(
        id: UUID = UUID(),
        template: PrintTemplate,
        sourceImagePaths: [URL],
        copies: Int = 1,
        isReprint: Bool = false
    ) {
        self.id = id
        self.template = template
        self.sourceImagePaths = sourceImagePaths
        self.status = .pending
        self.copies = copies
        self.createdAt = Date()
        self.isReprint = isReprint
    }
}
