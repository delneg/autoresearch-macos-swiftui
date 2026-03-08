import Foundation

enum ResultsParser {

    // MARK: - Cached regex patterns

    private static let stepPattern: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"step\s+(\d+)\s+\(([\d.]+)%\)\s+\|\s+loss:\s+([\d.]+)\s+\|\s+lrm:\s+([\d.]+)\s+\|\s+dt:\s+([\d.]+)ms\s+\|\s+tok/sec:\s+([\d,]+)\s+\|\s+mfu:\s+([\d.]+)%\s+\|\s+epoch:\s+(\d+)\s+\|\s+remaining:\s+([\d.]+)s"#
    )

    private static let intPattern: [String: NSRegularExpression] = {
        var cache: [String: NSRegularExpression] = [:]
        for name in ["DEPTH", "ASPECT_RATIO", "HEAD_DIM", "TOTAL_BATCH_SIZE", "DEVICE_BATCH_SIZE"] {
            cache[name] = try? NSRegularExpression(pattern: "\(name)\\s*=\\s*(\\d+)")
        }
        return cache
    }()

    private static let doublePattern: [String: NSRegularExpression] = {
        var cache: [String: NSRegularExpression] = [:]
        for name in ["EMBEDDING_LR", "UNEMBEDDING_LR", "MATRIX_LR", "SCALAR_LR", "WEIGHT_DECAY"] {
            cache[name] = try? NSRegularExpression(pattern: "\(name)\\s*=\\s*([\\d.]+)")
        }
        return cache
    }()

    private static let stringPattern: [String: NSRegularExpression] = {
        var cache: [String: NSRegularExpression] = [:]
        for name in ["WINDOW_PATTERN"] {
            cache[name] = try? NSRegularExpression(pattern: "\(name)\\s*=\\s*\"([^\"]+)\"")
        }
        return cache
    }()

    private static let finalResultPatterns: [String: NSRegularExpression] = {
        var cache: [String: NSRegularExpression] = [:]
        for key in ["val_bpb", "training_seconds", "total_seconds", "peak_vram_mb",
                     "mfu_percent", "total_tokens_M", "num_steps", "num_params_M", "depth"] {
            cache[key] = try? NSRegularExpression(pattern: "\(key):\\s+([\\d.]+)")
        }
        return cache
    }()

    // MARK: - results.tsv parsing

    static func parseResultsTSV(at url: URL) -> [ExperimentResult] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        // Skip header line
        guard lines.count > 1 else { return [] }

        return lines.dropFirst().enumerated().compactMap { index, line in
            parseResultLine(line, index: index)
        }
    }

    static func parseResultLine(_ line: String, index: Int) -> ExperimentResult? {
        let fields = line.components(separatedBy: "\t")
        guard fields.count >= 5 else { return nil }

        let commit = fields[0].trimmingCharacters(in: .whitespaces)
        let valBPB = Double(fields[1].trimmingCharacters(in: .whitespaces)) ?? 0.0
        let memoryGB = Double(fields[2].trimmingCharacters(in: .whitespaces)) ?? 0.0
        let statusStr = fields[3].trimmingCharacters(in: .whitespaces).lowercased()
        let description = fields[4].trimmingCharacters(in: .whitespaces)

        let status: ExperimentResult.ExperimentStatus
        switch statusStr {
        case "keep": status = .keep
        case "discard": status = .discard
        default: status = .crash
        }

        return ExperimentResult(
            index: index,
            commit: commit,
            valBPB: valBPB,
            memoryGB: memoryGB,
            status: status,
            description: description
        )
    }

    // MARK: - Real-time stdout metrics parsing

    static func parseMetricsLine(_ line: String) -> TrainingMetrics? {
        guard let stepPattern else { return nil }

        let range = NSRange(line.startIndex..., in: line)
        guard let match = stepPattern.firstMatch(in: line, range: range) else {
            return nil
        }

        func group(_ i: Int) -> String {
            guard let r = Range(match.range(at: i), in: line) else { return "" }
            return String(line[r])
        }

        return TrainingMetrics(
            step: Int(group(1)) ?? 0,
            progress: Double(group(2)) ?? 0.0,
            loss: Double(group(3)) ?? 0.0,
            learningRate: Double(group(4)) ?? 0.0,
            dtMs: Double(group(5)) ?? 0.0,
            tokensPerSec: Int(group(6).replacing(",", with: "")) ?? 0,
            mfu: Double(group(7)) ?? 0.0,
            epoch: Int(group(8)) ?? 0,
            remainingSeconds: Double(group(9)) ?? 0.0
        )
    }

    // MARK: - Final results parsing

    static func parseFinalResults(_ output: String) -> FinalResults? {
        func extractDouble(_ key: String) -> Double {
            guard let regex = finalResultPatterns[key],
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let range = Range(match.range(at: 1), in: output) else { return 0.0 }
            return Double(output[range]) ?? 0.0
        }

        let valBPB = extractDouble("val_bpb")
        guard valBPB > 0 else { return nil }

        return FinalResults(
            valBPB: valBPB,
            trainingSeconds: extractDouble("training_seconds"),
            totalSeconds: extractDouble("total_seconds"),
            peakVRAMMB: extractDouble("peak_vram_mb"),
            mfuPercent: extractDouble("mfu_percent"),
            totalTokensM: extractDouble("total_tokens_M"),
            numSteps: Int(extractDouble("num_steps")),
            numParamsM: extractDouble("num_params_M"),
            depth: Int(extractDouble("depth"))
        )
    }

    // MARK: - Hyperparameter extraction from train.py

    static func parseHyperparameters(from url: URL) -> Hyperparameters {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return Hyperparameters()
        }

        func extractInt(_ name: String, default defaultVal: Int) -> Int {
            guard let regex = intPattern[name],
                  let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
                  let range = Range(match.range(at: 1), in: content) else { return defaultVal }
            return Int(content[range]) ?? defaultVal
        }

        func extractDouble(_ name: String, default defaultVal: Double) -> Double {
            guard let regex = doublePattern[name],
                  let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
                  let range = Range(match.range(at: 1), in: content) else { return defaultVal }
            return Double(content[range]) ?? defaultVal
        }

        func extractString(_ name: String, default defaultVal: String) -> String {
            guard let regex = stringPattern[name],
                  let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
                  let range = Range(match.range(at: 1), in: content) else { return defaultVal }
            return String(content[range])
        }

        return Hyperparameters(
            depth: extractInt("DEPTH", default: 4),
            aspectRatio: extractInt("ASPECT_RATIO", default: 64),
            headDim: extractInt("HEAD_DIM", default: 128),
            windowPattern: extractString("WINDOW_PATTERN", default: "L"),
            totalBatchSize: extractInt("TOTAL_BATCH_SIZE", default: 65536),
            embeddingLR: extractDouble("EMBEDDING_LR", default: 0.6),
            unembeddingLR: extractDouble("UNEMBEDDING_LR", default: 0.004),
            matrixLR: extractDouble("MATRIX_LR", default: 0.04),
            scalarLR: extractDouble("SCALAR_LR", default: 0.5),
            weightDecay: extractDouble("WEIGHT_DECAY", default: 0.2),
            deviceBatchSize: extractInt("DEVICE_BATCH_SIZE", default: 16)
        )
    }
}
