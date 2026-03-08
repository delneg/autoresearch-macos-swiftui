import Foundation

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case experiments = "Experiments"
    case control = "Control"
    case logs = "Logs"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.33percent"
        case .experiments: "flask"
        case .control: "play.circle"
        case .logs: "text.alignleft"
        }
    }
}
