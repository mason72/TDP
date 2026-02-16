import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSection {
        case .setup:
            SetupView()
        case .templateEditor:
            TemplateEditorView()
        case .dashboard:
            DashboardView()
        case .printBrowser:
            PrintBrowserView()
        }
    }
}
