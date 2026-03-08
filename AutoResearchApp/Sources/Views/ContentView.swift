import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: SidebarItem = .dashboard
    @State private var resultsWatcher: FileWatcher?

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .experiments:
                ExperimentListView()
            case .control:
                ControlPanelView()
            case .logs:
                LogView()
            }
        }
        .task(id: appState.projectDirectory) {
            appState.loadData()
            setupWatching()
        }
    }

    private func setupWatching() {
        resultsWatcher?.stop()

        let watcher = FileWatcher { [appState] in
            appState.loadData()
        }
        watcher.watch(url: appState.projectDirectory.appending(path: "results.tsv"))
        resultsWatcher = watcher
    }
}
