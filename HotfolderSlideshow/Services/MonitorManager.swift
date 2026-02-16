import AppKit
import Combine

/// Represents an available display/monitor.
struct DisplayInfo: Identifiable, Hashable {
    let id: CGDirectDisplayID
    let name: String
    let resolution: NSSize
    let isBuiltIn: Bool
    let screen: NSScreen

    var displayString: String {
        let res = "\(Int(resolution.width))x\(Int(resolution.height))"
        let builtIn = isBuiltIn ? " (Built-in)" : ""
        return "\(name) — \(res)\(builtIn)"
    }
}

/// Detects connected monitors and observes connect/disconnect events.
final class MonitorManager: ObservableObject {
    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?

    private var screenObserver: Any?

    init() {
        refreshDisplays()
        startObserving()
    }

    deinit {
        stopObserving()
    }

    // MARK: - Public

    /// The currently selected display, if still connected.
    var selectedDisplay: DisplayInfo? {
        guard let id = selectedDisplayID else { return nil }
        return displays.first { $0.id == id }
    }

    /// The NSScreen for the selected display.
    var selectedScreen: NSScreen? {
        selectedDisplay?.screen
    }

    /// Select a display by its ID.
    func selectDisplay(_ id: CGDirectDisplayID) {
        selectedDisplayID = id
    }

    /// Refresh the list of connected displays.
    func refreshDisplays() {
        displays = NSScreen.screens.enumerated().map { index, screen in
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let name = screen.localizedName
            let size = screen.frame.size
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

            return DisplayInfo(
                id: displayID,
                name: name,
                resolution: size,
                isBuiltIn: isBuiltIn,
                screen: screen
            )
        }

        // If the selected display is no longer connected, clear the selection
        if let selectedID = selectedDisplayID,
           !displays.contains(where: { $0.id == selectedID }) {
            selectedDisplayID = nil
        }
    }

    // MARK: - Screen Change Observation

    private func startObserving() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDisplays()
        }
    }

    private func stopObserving() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
