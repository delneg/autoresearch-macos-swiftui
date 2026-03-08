import SwiftUI

struct MetricsGridView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let metrics = appState.currentMetrics {
            liveMetrics(metrics)
        } else if let final_ = appState.finalResults {
            finalMetrics(final_)
        }
    }

    private func liveMetrics(_ metrics: TrainingMetrics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            MetricCard(title: "Step", value: "\(metrics.step)")
            MetricCard(title: "Progress", value: metrics.progress.formatted(.number.precision(.fractionLength(1))) + "%")
            MetricCard(title: "Loss", value: metrics.loss.formatted(.number.precision(.fractionLength(6))))
            MetricCard(title: "Tok/sec", value: metrics.tokensPerSec.formatted(.number))
            MetricCard(title: "MFU", value: metrics.mfu.formatted(.number.precision(.fractionLength(1))) + "%")
            MetricCard(title: "LR", value: metrics.learningRate.formatted(.number.precision(.fractionLength(6))))
            MetricCard(title: "Step Time", value: metrics.dtMs.formatted(.number.precision(.fractionLength(1))) + "ms")
            MetricCard(title: "Remaining", value: metrics.remainingSeconds.formatted(.number.precision(.fractionLength(0))) + "s")
        }
    }

    private func finalMetrics(_ results: FinalResults) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            MetricCard(title: "val_bpb", value: results.valBPB.formatted(.number.precision(.fractionLength(6))))
            MetricCard(title: "VRAM", value: results.peakVRAMMB.formatted(.number.precision(.fractionLength(0))) + " MB")
            MetricCard(title: "MFU", value: results.mfuPercent.formatted(.number.precision(.fractionLength(1))) + "%")
            MetricCard(title: "Tokens", value: results.totalTokensM.formatted(.number.precision(.fractionLength(1))) + "M")
            MetricCard(title: "Steps", value: "\(results.numSteps)")
            MetricCard(title: "Params", value: results.numParamsM.formatted(.number.precision(.fractionLength(1))) + "M")
            MetricCard(title: "Depth", value: "\(results.depth)")
            MetricCard(title: "Time", value: results.trainingSeconds.formatted(.number.precision(.fractionLength(1))) + "s")
        }
    }
}
