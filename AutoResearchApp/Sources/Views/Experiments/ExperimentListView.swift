import SwiftUI

struct ExperimentListView: View {
    @Environment(AppState.self) private var appState
    @State private var sortOrder = [KeyPathComparator(\ExperimentResult.index, order: .reverse)]
    @State private var selectedID: String?

    private var sortedExperiments: [ExperimentResult] {
        appState.experiments.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            Table(sortedExperiments, selection: $selectedID, sortOrder: $sortOrder) {
                TableColumn("#", value: \.index) { experiment in
                    Text("\(experiment.index + 1)")
                        .monospaced()
                }
                .width(40)

                TableColumn("Commit", value: \.commit) { experiment in
                    Text(experiment.commit)
                        .monospaced()
                        .lineLimit(1)
                }
                .width(min: 70, ideal: 80)

                TableColumn("val_bpb") { experiment in
                    if experiment.valBPB > 0 {
                        Text(experiment.valBPB, format: .number.precision(.fractionLength(6)))
                            .monospaced()
                            .foregroundStyle(experiment.status == .keep ? .primary : .secondary)
                    } else {
                        Text("\u{2014}")
                            .monospaced()
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 90, ideal: 100)

                TableColumn("Memory (GB)") { experiment in
                    if experiment.memoryGB > 0 {
                        Text(experiment.memoryGB, format: .number.precision(.fractionLength(1)))
                            .monospaced()
                    } else {
                        Text("\u{2014}")
                            .monospaced()
                    }
                }
                .width(min: 80, ideal: 90)

                TableColumn("Status", value: \.status.rawValue) { experiment in
                    StatusBadge(status: experiment.status)
                }
                .width(min: 70, ideal: 80)

                TableColumn("Description", value: \.description) { experiment in
                    Text(experiment.description)
                        .lineLimit(2)
                }
            }

            if let selectedID, let selected = appState.experiments.first(where: { $0.id == selectedID }) {
                Divider()
                ExperimentDetailView(experiment: selected)
                    .frame(height: 120)
            }
        }
        .navigationTitle("Experiments (\(appState.experiments.count))")
    }
}
