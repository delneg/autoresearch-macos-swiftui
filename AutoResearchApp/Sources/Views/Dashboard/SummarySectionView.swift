import SwiftUI

struct SummarySectionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 20) {
            SummaryBadge(label: "Total", count: appState.experiments.count, color: .primary)
            SummaryBadge(label: "Kept", count: appState.keptCount, color: .green)
            SummaryBadge(label: "Discarded", count: appState.discardedCount, color: .red)
            SummaryBadge(label: "Crashed", count: appState.crashedCount, color: .orange)
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }
}
