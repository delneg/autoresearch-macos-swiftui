import SwiftUI

struct StatusHeaderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(appState.isTraining ? .green : .secondary)
                .frame(width: 12, height: 12)

            Text(appState.isTraining ? "Training in progress" : "Idle")
                .font(.headline)

            Spacer()

            if let best = appState.bestBPB {
                HStack(spacing: 0) {
                    Text("Best BPB: ")
                    Text(best, format: .number.precision(.fractionLength(6)))
                }
                .font(.title3.monospaced())
                .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }
}
