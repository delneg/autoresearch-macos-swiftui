import SwiftUI

struct ExperimentDetailView: View {
    let experiment: ExperimentResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Experiment Detail")
                .font(.headline)

            HStack(spacing: 24) {
                LabeledContent("Commit", value: experiment.commit)
                LabeledContent("val_bpb", value: experiment.valBPB > 0
                    ? experiment.valBPB.formatted(.number.precision(.fractionLength(6)))
                    : "N/A")
                LabeledContent("Memory", value: experiment.memoryGB > 0
                    ? experiment.memoryGB.formatted(.number.precision(.fractionLength(1))) + " GB"
                    : "N/A")
                LabeledContent("Status", value: experiment.status.label)
            }

            Text(experiment.description)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
    }
}
