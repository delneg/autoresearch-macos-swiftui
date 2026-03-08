import SwiftUI
import Charts

struct BPBChartView: View {
    @Environment(AppState.self) private var appState

    private var keptExperiments: [ExperimentResult] {
        appState.experiments.filter { $0.status == .keep && $0.valBPB > 0 }
    }

    var body: some View {
        if !keptExperiments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("val_bpb Progression (Kept Experiments)")
                    .font(.headline)

                Chart(keptExperiments) { experiment in
                    LineMark(
                        x: .value("Experiment", experiment.index),
                        y: .value("BPB", experiment.valBPB)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Experiment", experiment.index),
                        y: .value("BPB", experiment.valBPB)
                    )
                    .foregroundStyle(.blue)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxisLabel("Experiment #")
                .chartYAxisLabel("Bits Per Byte")
                .frame(height: 250)
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
        }
    }
}
