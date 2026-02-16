import Foundation
import AppKit

class PrintService: ObservableObject {
    @Published var availablePrinters: [PrinterInfo] = []
    @Published var selectedPrinterName: String?

    struct PrinterInfo: Identifiable, Hashable {
        let id: String
        let name: String
        let type: String
        let isDefault: Bool
    }

    init() {
        refreshPrinters()
    }

    func refreshPrinters() {
        let printerNames = NSPrinter.printerNames
        let defaultName = NSPrintInfo.shared.printer.name

        availablePrinters = printerNames.map { name in
            PrinterInfo(
                id: name,
                name: name,
                type: NSPrinter(name: name)?.type ?? "Unknown",
                isDefault: name == defaultName
            )
        }

        if selectedPrinterName == nil {
            selectedPrinterName = defaultName
        }
    }

    func printImage(at url: URL, copies: Int = 1, printSize: PrintSize) -> Bool {
        guard let image = NSImage(contentsOf: url) else { return false }
        guard let printerName = selectedPrinterName,
              let printer = NSPrinter(name: printerName) else { return false }

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.printer = printer
        printInfo.paperSize = NSSize(
            width: printSize.widthInches * 72,
            height: printSize.heightInches * 72
        )
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true
        printInfo.jobDisposition = .spool
        printInfo.dictionary().setObject(NSNumber(value: copies), forKey: NSPrintInfo.AttributeKey.copies as NSCopying)

        let imageView = NSImageView(frame: NSRect(
            origin: .zero,
            size: NSSize(
                width: printSize.widthInches * 72,
                height: printSize.heightInches * 72
            )
        ))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown

        let printOperation = NSPrintOperation(view: imageView, printInfo: printInfo)
        printOperation.showsPrintPanel = false
        printOperation.showsProgressPanel = false
        printOperation.canSpawnSeparateThread = true

        return printOperation.run()
    }
}
