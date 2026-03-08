import SwiftUI

struct ControlPanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TrainingControlsView()
                PrepareControlsView()
                HyperparametersView()
            }
            .padding()
        }
        .navigationTitle("Control Panel")
    }
}

// MARK: - Training Controls

struct TrainingControlsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Start Training", systemImage: "play.fill", action: startTraining)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(appState.isTraining || appState.isPreparing)

                Button("Stop", systemImage: "stop.fill", action: stopTraining)
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(!appState.isTraining)
            }

            if appState.isTraining {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }

    private func startTraining() {
        appState.startTraining()
    }

    private func stopTraining() {
        appState.stopTraining()
    }
}

// MARK: - Prepare Controls

struct PrepareControlsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Preparation")
                .font(.headline)

            Button("Run prepare.py", systemImage: "arrow.down.circle", action: runPrepare)
                .buttonStyle(.bordered)
                .disabled(appState.isTraining || appState.isPreparing)

            if appState.isPreparing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }

    private func runPrepare() {
        appState.runPrepare()
    }
}

// MARK: - Hyperparameters

struct HyperparametersView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Hyperparameters")
                    .font(.headline)
                Spacer()
                Button("Reload", systemImage: "arrow.clockwise", action: reload)
                    .buttonStyle(.borderless)
            }

            let hp = appState.hyperparameters
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 8) {
                HyperparamRow(name: "DEPTH", value: "\(hp.depth)")
                HyperparamRow(name: "ASPECT_RATIO", value: "\(hp.aspectRatio)")
                HyperparamRow(name: "HEAD_DIM", value: "\(hp.headDim)")
                HyperparamRow(name: "WINDOW_PATTERN", value: "\"\(hp.windowPattern)\"")
                HyperparamRow(name: "BATCH_SIZE", value: "\(hp.totalBatchSize)")
                HyperparamRow(name: "DEVICE_BATCH", value: "\(hp.deviceBatchSize)")
                HyperparamRow(name: "EMBEDDING_LR", value: hp.embeddingLR.formatted(.number.precision(.fractionLength(4))))
                HyperparamRow(name: "UNEMBED_LR", value: hp.unembeddingLR.formatted(.number.precision(.fractionLength(4))))
                HyperparamRow(name: "MATRIX_LR", value: hp.matrixLR.formatted(.number.precision(.fractionLength(4))))
                HyperparamRow(name: "SCALAR_LR", value: hp.scalarLR.formatted(.number.precision(.fractionLength(4))))
                HyperparamRow(name: "WEIGHT_DECAY", value: hp.weightDecay.formatted(.number.precision(.fractionLength(2))))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
    }

    private func reload() {
        let trainPy = appState.projectDirectory.appending(path: "train.py")
        appState.hyperparameters = ResultsParser.parseHyperparameters(from: trainPy)
    }
}
