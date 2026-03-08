import SwiftUI

@Observable
@MainActor
final class AppState {
    var projectDirectory: URL {
        didSet {
            UserDefaults.standard.set(projectDirectory.path, forKey: "projectDirectory")
        }
    }
    var uvPath: String {
        didSet {
            UserDefaults.standard.set(uvPath, forKey: "uvPath")
        }
    }

    var experiments: [ExperimentResult] = []
    var isTraining: Bool = false
    var isPreparing: Bool = false
    var currentMetrics: TrainingMetrics?
    var finalResults: FinalResults?
    var logLines: [String] = []
    var hyperparameters: Hyperparameters = Hyperparameters()

    let processManager = ProcessManager()

    var bestBPB: Double? {
        experiments
            .filter { $0.status == .keep && $0.valBPB > 0 }
            .map(\.valBPB)
            .min()
    }

    var keptCount: Int { experiments.count(where: { $0.status == .keep }) }
    var discardedCount: Int { experiments.count(where: { $0.status == .discard }) }
    var crashedCount: Int { experiments.count(where: { $0.status == .crash }) }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "projectDirectory") {
            self.projectDirectory = URL(fileURLWithPath: saved)
        } else {
            self.projectDirectory = URL(fileURLWithPath: NSHomeDirectory())
                .appending(path: "autoresearch-macos")
        }
        self.uvPath = UserDefaults.standard.string(forKey: "uvPath") ?? Self.findUV()
    }

    /// Searches common install locations for the `uv` binary.
    private static func findUV() -> String {
        let candidates = [
            "\(NSHomeDirectory())/.local/bin/uv",      // curl installer default
            "\(NSHomeDirectory())/.cargo/bin/uv",       // cargo install
            "/opt/homebrew/bin/uv",                     // Homebrew on Apple Silicon
            "/usr/local/bin/uv",                        // Homebrew on Intel / manual install
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "uv" // fallback — hope it's on PATH
    }

    func appendLog(_ line: String) {
        logLines.append(line)
        if logLines.count > 5000 {
            logLines = Array(logLines.suffix(5000))
        }
    }

    func clearLog() {
        logLines.removeAll()
    }

    // MARK: - Data loading

    func loadData() {
        let resultsTSV = projectDirectory.appending(path: "results.tsv")
        let trainPy = projectDirectory.appending(path: "train.py")
        experiments = ResultsParser.parseResultsTSV(at: resultsTSV)
        hyperparameters = ResultsParser.parseHyperparameters(from: trainPy)
    }

    // MARK: - Process control

    func startTraining() {
        isTraining = true
        currentMetrics = nil
        finalResults = nil
        clearLog()

        // Only keep the tail of output needed to parse final results
        var outputTail: [String] = []

        processManager.run(
            command: uvPath,
            arguments: ["run", "train.py"],
            workingDirectory: projectDirectory,
            onOutput: { [weak self] line in
                guard let self else { return }
                self.appendLog(line)
                outputTail.append(line)
                // Keep only last 50 lines — final results are always at the end
                if outputTail.count > 50 {
                    outputTail.removeFirst(outputTail.count - 50)
                }
                if let metrics = ResultsParser.parseMetricsLine(line) {
                    self.currentMetrics = metrics
                }
            },
            onComplete: { [weak self] status in
                guard let self else { return }
                self.isTraining = false
                self.appendLog("Process exited with status: \(status)")

                let fullTail = outputTail.joined(separator: "\n")
                if let results = ResultsParser.parseFinalResults(fullTail) {
                    self.finalResults = results
                    self.currentMetrics = nil
                }
            }
        )
    }

    func stopTraining() {
        processManager.stop()
        appendLog("Training stopped by user.")
    }

    func runPrepare() {
        isPreparing = true
        clearLog()

        processManager.run(
            command: uvPath,
            arguments: ["run", "prepare.py"],
            workingDirectory: projectDirectory,
            onOutput: { [weak self] line in
                self?.appendLog(line)
            },
            onComplete: { [weak self] status in
                guard let self else { return }
                self.isPreparing = false
                self.appendLog("Prepare finished with status: \(status)")
            }
        )
    }
}
