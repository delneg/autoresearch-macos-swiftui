import Foundation

struct TrainingMetrics {
    var step: Int = 0
    var progress: Double = 0.0
    var loss: Double = 0.0
    var learningRate: Double = 0.0
    var dtMs: Double = 0.0
    var tokensPerSec: Int = 0
    var mfu: Double = 0.0
    var epoch: Int = 0
    var remainingSeconds: Double = 0.0
}

struct FinalResults {
    var valBPB: Double = 0.0
    var trainingSeconds: Double = 0.0
    var totalSeconds: Double = 0.0
    var peakVRAMMB: Double = 0.0
    var mfuPercent: Double = 0.0
    var totalTokensM: Double = 0.0
    var numSteps: Int = 0
    var numParamsM: Double = 0.0
    var depth: Int = 0
}

struct Hyperparameters {
    var depth: Int = 4
    var aspectRatio: Int = 64
    var headDim: Int = 128
    var windowPattern: String = "L"
    var totalBatchSize: Int = 65536
    var embeddingLR: Double = 0.6
    var unembeddingLR: Double = 0.004
    var matrixLR: Double = 0.04
    var scalarLR: Double = 0.5
    var weightDecay: Double = 0.2
    var deviceBatchSize: Int = 16
}
