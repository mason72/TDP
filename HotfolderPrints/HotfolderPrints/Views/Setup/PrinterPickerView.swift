import SwiftUI

struct PrinterPickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SetupCard(
            title: "Printer",
            icon: "printer",
            isConfigured: appState.printService.selectedPrinterName != nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Picker("Printer", selection: $appState.printService.selectedPrinterName) {
                        Text("Select a printer...")
                            .tag(nil as String?)
                        ForEach(appState.printService.availablePrinters) { printer in
                            HStack {
                                Text(printer.name)
                                if printer.isDefault {
                                    Text("(Default)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(printer.name as String?)
                        }
                    }
                    .labelsHidden()

                    Button(action: { appState.printService.refreshPrinters() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Refresh printer list")
                }

                if appState.printService.availablePrinters.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                        Text("No printers found. Make sure a printer is connected and set up in System Settings.")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}
