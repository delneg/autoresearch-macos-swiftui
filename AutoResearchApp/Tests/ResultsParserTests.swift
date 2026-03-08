import XCTest
@testable import AutoResearchApp

final class ResultsParserTests: XCTestCase {

    // MARK: - TSV Line Parsing

    func testParseResultLineKeep() throws {
        let line = "a1b2c3d\t0.997900\t44.0\tkeep\tbaseline"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 0))

        XCTAssertEqual(result.commit, "a1b2c3d")
        XCTAssertEqual(result.valBPB, 0.997900, accuracy: 0.000001)
        XCTAssertEqual(result.memoryGB, 44.0, accuracy: 0.1)
        XCTAssertEqual(result.status, .keep)
        XCTAssertEqual(result.description, "baseline")
        XCTAssertEqual(result.index, 0)
    }

    func testParseResultLineDiscard() throws {
        let line = "c3d4e5f\t1.005000\t44.0\tdiscard\tswitch to GeLU"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 2))

        XCTAssertEqual(result.status, .discard)
        XCTAssertEqual(result.valBPB, 1.005, accuracy: 0.000001)
        XCTAssertEqual(result.description, "switch to GeLU")
    }

    func testParseResultLineCrash() throws {
        let line = "d4e5f6g\t0.000000\t0.0\tcrash\tdouble width (OOM)"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 3))

        XCTAssertEqual(result.status, .crash)
        XCTAssertEqual(result.valBPB, 0.0)
        XCTAssertEqual(result.memoryGB, 0.0)
    }

    func testParseResultLineInvalidTooFewFields() {
        let line = "a1b2c3d\t0.997900"
        let result = ResultsParser.parseResultLine(line, index: 0)
        XCTAssertNil(result)
    }

    func testParseResultLineWithWhitespace() throws {
        let line = "  abc123  \t  0.987654  \t  42.5  \t  keep  \t  increased depth  "
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 5))

        XCTAssertEqual(result.commit, "abc123")
        XCTAssertEqual(result.valBPB, 0.987654, accuracy: 0.000001)
        XCTAssertEqual(result.description, "increased depth")
    }

    func testParseResultLineEmptyString() {
        let result = ResultsParser.parseResultLine("", index: 0)
        XCTAssertNil(result)
    }

    func testParseResultLineUnknownStatusDefaultsToCrash() throws {
        let line = "abc1234\t0.99\t44.0\tunknown_status\tsome desc"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 0))
        XCTAssertEqual(result.status, .crash)
    }

    func testParseResultLineInvalidNumbers() throws {
        let line = "abc1234\tnot_a_number\tnope\tkeep\tbaseline"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 0))
        XCTAssertEqual(result.valBPB, 0.0)
        XCTAssertEqual(result.memoryGB, 0.0)
    }

    func testParseResultLineExtraTabFields() throws {
        let line = "abc1234\t0.99\t44.0\tkeep\tdescription with\textra\ttabs"
        let result = try XCTUnwrap(ResultsParser.parseResultLine(line, index: 0))
        // Should still parse — only first 5 fields matter
        XCTAssertEqual(result.commit, "abc1234")
        XCTAssertEqual(result.description, "description with")
    }

    // MARK: - TSV File Parsing

    func testParseResultsTSVFromFile() throws {
        let tsv = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\na1b2c3d\t0.997900\t44.0\tkeep\tbaseline\nb2c3d4e\t0.993200\t44.2\tkeep\tincrease LR to 0.04\nc3d4e5f\t1.005000\t44.0\tdiscard\tswitch to GeLU"

        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_results_\(UUID()).tsv")
        try tsv.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let results = ResultsParser.parseResultsTSV(at: tmpURL)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].commit, "a1b2c3d")
        XCTAssertEqual(results[1].status, .keep)
        XCTAssertEqual(results[2].status, .discard)
    }

    func testParseResultsTSVEmptyFile() throws {
        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_empty_\(UUID()).tsv")
        try "".write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let results = ResultsParser.parseResultsTSV(at: tmpURL)
        XCTAssertTrue(results.isEmpty)
    }

    func testParseResultsTSVHeaderOnly() throws {
        let tsv = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\n"
        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_header_\(UUID()).tsv")
        try tsv.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let results = ResultsParser.parseResultsTSV(at: tmpURL)
        XCTAssertTrue(results.isEmpty)
    }

    func testParseResultsTSVMissingFile() {
        let url = URL(fileURLWithPath: "/nonexistent/results.tsv")
        let results = ResultsParser.parseResultsTSV(at: url)
        XCTAssertTrue(results.isEmpty)
    }

    func testParseResultsTSVIndicesAreSequential() throws {
        let tsv = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\naaa\t0.99\t44.0\tkeep\ta\nbbb\t0.98\t44.0\tkeep\tb\nccc\t0.97\t44.0\tkeep\tc"
        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_idx_\(UUID()).tsv")
        try tsv.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let results = ResultsParser.parseResultsTSV(at: tmpURL)
        XCTAssertEqual(results[0].index, 0)
        XCTAssertEqual(results[1].index, 1)
        XCTAssertEqual(results[2].index, 2)
    }

    func testParseResultsTSVSkipsMalformedRows() throws {
        let tsv = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\naaa\t0.99\t44.0\tkeep\tgood row\nbad_row_no_tabs\nccc\t0.97\t44.0\tkeep\tanother good row"
        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_malformed_\(UUID()).tsv")
        try tsv.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let results = ResultsParser.parseResultsTSV(at: tmpURL)
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - Real-time Metrics Parsing

    func testParseMetricsLineValid() throws {
        let line = "step 00953 (100.0%) | loss: 3.203126 | lrm: 0.000000 | dt: 296.3ms | tok/sec: 221,280 | mfu: 39.80% | epoch: 0 | remaining: 0.0s"
        let metrics = try XCTUnwrap(ResultsParser.parseMetricsLine(line))

        XCTAssertEqual(metrics.step, 953)
        XCTAssertEqual(metrics.progress, 100.0, accuracy: 0.1)
        XCTAssertEqual(metrics.loss, 3.203126, accuracy: 0.000001)
        XCTAssertEqual(metrics.learningRate, 0.0, accuracy: 0.000001)
        XCTAssertEqual(metrics.dtMs, 296.3, accuracy: 0.1)
        XCTAssertEqual(metrics.tokensPerSec, 221280)
        XCTAssertEqual(metrics.mfu, 39.80, accuracy: 0.01)
        XCTAssertEqual(metrics.epoch, 0)
        XCTAssertEqual(metrics.remainingSeconds, 0.0, accuracy: 0.1)
    }

    func testParseMetricsLineMidTraining() throws {
        let line = "step 00500 (52.5%) | loss: 4.123456 | lrm: 0.040000 | dt: 312.5ms | tok/sec: 198,432 | mfu: 35.20% | epoch: 0 | remaining: 148.5s"
        let metrics = try XCTUnwrap(ResultsParser.parseMetricsLine(line))

        XCTAssertEqual(metrics.step, 500)
        XCTAssertEqual(metrics.progress, 52.5, accuracy: 0.1)
        XCTAssertEqual(metrics.remainingSeconds, 148.5, accuracy: 0.1)
    }

    func testParseMetricsLineInvalid() {
        XCTAssertNil(ResultsParser.parseMetricsLine("Loading model..."))
    }

    func testParseMetricsLineEmpty() {
        XCTAssertNil(ResultsParser.parseMetricsLine(""))
    }

    func testParseMetricsLineLargeTokenCount() throws {
        let line = "step 10000 (99.9%) | loss: 2.500000 | lrm: 0.010000 | dt: 150.0ms | tok/sec: 1,234,567 | mfu: 55.00% | epoch: 2 | remaining: 1.0s"
        let metrics = try XCTUnwrap(ResultsParser.parseMetricsLine(line))
        XCTAssertEqual(metrics.tokensPerSec, 1234567)
        XCTAssertEqual(metrics.epoch, 2)
    }

    func testParseMetricsLinePartialMatch() {
        // Missing fields should not match
        let line = "step 00100 (10.0%) | loss: 5.0"
        XCTAssertNil(ResultsParser.parseMetricsLine(line))
    }

    // MARK: - Final Results Parsing

    func testParseFinalResultsComplete() throws {
        let output = """
        val_bpb:          0.997900
        training_seconds: 300.1
        total_seconds:    325.9
        peak_vram_mb:     45060.2
        mfu_percent:      39.80
        total_tokens_M:   499.6
        num_steps:        953
        num_params_M:     50.3
        depth:            8
        """

        let results = try XCTUnwrap(ResultsParser.parseFinalResults(output))
        XCTAssertEqual(results.valBPB, 0.997900, accuracy: 0.000001)
        XCTAssertEqual(results.trainingSeconds, 300.1, accuracy: 0.1)
        XCTAssertEqual(results.totalSeconds, 325.9, accuracy: 0.1)
        XCTAssertEqual(results.peakVRAMMB, 45060.2, accuracy: 0.1)
        XCTAssertEqual(results.mfuPercent, 39.80, accuracy: 0.01)
        XCTAssertEqual(results.totalTokensM, 499.6, accuracy: 0.1)
        XCTAssertEqual(results.numSteps, 953)
        XCTAssertEqual(results.numParamsM, 50.3, accuracy: 0.1)
        XCTAssertEqual(results.depth, 8)
    }

    func testParseFinalResultsNoValBPB() {
        let output = "training_seconds: 300.1\npeak_vram_mb: 45060.2"
        XCTAssertNil(ResultsParser.parseFinalResults(output))
    }

    func testParseFinalResultsZeroValBPB() {
        let output = "val_bpb:          0.000000"
        XCTAssertNil(ResultsParser.parseFinalResults(output))
    }

    func testParseFinalResultsEmbeddedInLogs() throws {
        let output = """
        Loading tokenizer...
        Starting training...
        step 00953 (100.0%) | loss: 3.203126 | lrm: 0.000000
        val_bpb:          0.978500
        training_seconds: 300.0
        total_seconds:    320.0
        peak_vram_mb:     42000.0
        mfu_percent:      41.20
        total_tokens_M:   510.0
        num_steps:        980
        num_params_M:     48.5
        depth:            6
        """

        let results = try XCTUnwrap(ResultsParser.parseFinalResults(output))
        XCTAssertEqual(results.valBPB, 0.978500, accuracy: 0.000001)
    }

    func testParseFinalResultsPartialOutput() throws {
        // Only val_bpb present, rest defaults to 0
        let output = "val_bpb:          0.950000"
        let results = try XCTUnwrap(ResultsParser.parseFinalResults(output))
        XCTAssertEqual(results.valBPB, 0.95, accuracy: 0.000001)
        XCTAssertEqual(results.trainingSeconds, 0.0)
        XCTAssertEqual(results.numSteps, 0)
    }

    func testParseFinalResultsEmptyString() {
        XCTAssertNil(ResultsParser.parseFinalResults(""))
    }

    // MARK: - Hyperparameters Parsing

    func testParseHyperparametersFromFile() throws {
        let code = """
        import torch

        ASPECT_RATIO = 64
        HEAD_DIM = 128
        WINDOW_PATTERN = "SSSL"
        TOTAL_BATCH_SIZE = 65536
        EMBEDDING_LR = 0.6
        UNEMBEDDING_LR = 0.004
        MATRIX_LR = 0.04
        SCALAR_LR = 0.5
        WEIGHT_DECAY = 0.2
        DEPTH = 8
        DEVICE_BATCH_SIZE = 16
        """

        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_train_\(UUID()).py")
        try code.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let hp = ResultsParser.parseHyperparameters(from: tmpURL)
        XCTAssertEqual(hp.depth, 8)
        XCTAssertEqual(hp.aspectRatio, 64)
        XCTAssertEqual(hp.headDim, 128)
        XCTAssertEqual(hp.windowPattern, "SSSL")
        XCTAssertEqual(hp.embeddingLR, 0.6, accuracy: 0.001)
        XCTAssertEqual(hp.matrixLR, 0.04, accuracy: 0.001)
        XCTAssertEqual(hp.deviceBatchSize, 16)
    }

    func testParseHyperparametersMissingFile() {
        let url = URL(fileURLWithPath: "/nonexistent/train.py")
        let hp = ResultsParser.parseHyperparameters(from: url)
        XCTAssertEqual(hp.depth, 4)
        XCTAssertEqual(hp.aspectRatio, 64)
    }

    func testParseHyperparametersPartialFile() throws {
        // File with only some params — rest should use defaults
        let code = "DEPTH = 12\nEMBEDDING_LR = 0.8"
        let tmpURL = FileManager.default.temporaryDirectory.appending(path: "test_partial_\(UUID()).py")
        try code.write(to: tmpURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let hp = ResultsParser.parseHyperparameters(from: tmpURL)
        XCTAssertEqual(hp.depth, 12)
        XCTAssertEqual(hp.embeddingLR, 0.8, accuracy: 0.001)
        // Defaults
        XCTAssertEqual(hp.aspectRatio, 64)
        XCTAssertEqual(hp.headDim, 128)
        XCTAssertEqual(hp.windowPattern, "L")
    }

    // MARK: - ExperimentResult Identity

    func testExperimentResultStableIdentity() {
        let a = ExperimentResult(index: 0, commit: "abc123", valBPB: 0.99, memoryGB: 44.0, status: .keep, description: "test")
        let b = ExperimentResult(index: 0, commit: "abc123", valBPB: 0.99, memoryGB: 44.0, status: .keep, description: "test")

        XCTAssertEqual(a.id, b.id)
    }

    func testExperimentResultDifferentIdentity() {
        let a = ExperimentResult(index: 0, commit: "abc123", valBPB: 0.99, memoryGB: 44.0, status: .keep, description: "test")
        let b = ExperimentResult(index: 1, commit: "def456", valBPB: 0.98, memoryGB: 44.0, status: .keep, description: "test2")

        XCTAssertNotEqual(a.id, b.id)
    }

    func testExperimentResultSameCommitDifferentIndex() {
        let a = ExperimentResult(index: 0, commit: "abc123", valBPB: 0.99, memoryGB: 44.0, status: .keep, description: "test")
        let b = ExperimentResult(index: 1, commit: "abc123", valBPB: 0.99, memoryGB: 44.0, status: .keep, description: "test")

        XCTAssertNotEqual(a.id, b.id)
    }
}
