import XCTest
@testable import AutoResearchApp

@MainActor
final class AppStateTests: XCTestCase {

    func testInitialState() {
        let state = AppState()
        XCTAssertFalse(state.isTraining)
        XCTAssertFalse(state.isPreparing)
        XCTAssertTrue(state.experiments.isEmpty)
        XCTAssertTrue(state.logLines.isEmpty)
        XCTAssertNil(state.currentMetrics)
        XCTAssertNil(state.finalResults)
        XCTAssertNil(state.bestBPB)
    }

    func testBestBPB() throws {
        let state = AppState()
        state.experiments = [
            ExperimentResult(index: 0, commit: "aaa", valBPB: 0.998, memoryGB: 44, status: .keep, description: "a"),
            ExperimentResult(index: 1, commit: "bbb", valBPB: 0.990, memoryGB: 44, status: .keep, description: "b"),
            ExperimentResult(index: 2, commit: "ccc", valBPB: 1.005, memoryGB: 44, status: .discard, description: "c"),
            ExperimentResult(index: 3, commit: "ddd", valBPB: 0.985, memoryGB: 44, status: .keep, description: "d"),
        ]

        let best = try XCTUnwrap(state.bestBPB)
        XCTAssertEqual(best, 0.985, accuracy: 0.001)
    }

    func testBestBPBIgnoresDiscardAndCrash() throws {
        let state = AppState()
        state.experiments = [
            ExperimentResult(index: 0, commit: "aaa", valBPB: 0.998, memoryGB: 44, status: .keep, description: "a"),
            ExperimentResult(index: 1, commit: "bbb", valBPB: 0.500, memoryGB: 44, status: .discard, description: "b"),
            ExperimentResult(index: 2, commit: "ccc", valBPB: 0.0, memoryGB: 0, status: .crash, description: "c"),
        ]

        let best = try XCTUnwrap(state.bestBPB)
        XCTAssertEqual(best, 0.998, accuracy: 0.001)
    }

    func testBestBPBNilWhenNoKept() {
        let state = AppState()
        state.experiments = [
            ExperimentResult(index: 0, commit: "aaa", valBPB: 0.998, memoryGB: 44, status: .discard, description: "a"),
        ]

        XCTAssertNil(state.bestBPB)
    }

    func testBestBPBNilWhenEmpty() {
        let state = AppState()
        XCTAssertNil(state.bestBPB)
    }

    func testCounts() {
        let state = AppState()
        state.experiments = [
            ExperimentResult(index: 0, commit: "a", valBPB: 0.99, memoryGB: 44, status: .keep, description: ""),
            ExperimentResult(index: 1, commit: "b", valBPB: 1.0, memoryGB: 44, status: .keep, description: ""),
            ExperimentResult(index: 2, commit: "c", valBPB: 1.1, memoryGB: 44, status: .discard, description: ""),
            ExperimentResult(index: 3, commit: "d", valBPB: 0.0, memoryGB: 0, status: .crash, description: ""),
        ]

        XCTAssertEqual(state.keptCount, 2)
        XCTAssertEqual(state.discardedCount, 1)
        XCTAssertEqual(state.crashedCount, 1)
    }

    func testCountsEmpty() {
        let state = AppState()
        XCTAssertEqual(state.keptCount, 0)
        XCTAssertEqual(state.discardedCount, 0)
        XCTAssertEqual(state.crashedCount, 0)
    }

    func testAppendLogCapsAt5000() {
        let state = AppState()

        for i in 0..<5100 {
            state.appendLog("line \(i)")
        }

        XCTAssertEqual(state.logLines.count, 5000)
        XCTAssertEqual(state.logLines.first, "line 100")
        XCTAssertEqual(state.logLines.last, "line 5099")
    }

    func testAppendLogUnderCap() {
        let state = AppState()
        state.appendLog("hello")
        state.appendLog("world")

        XCTAssertEqual(state.logLines.count, 2)
        XCTAssertEqual(state.logLines[0], "hello")
        XCTAssertEqual(state.logLines[1], "world")
    }

    func testClearLog() {
        let state = AppState()
        state.appendLog("test")
        state.appendLog("test2")
        XCTAssertEqual(state.logLines.count, 2)

        state.clearLog()
        XCTAssertTrue(state.logLines.isEmpty)
    }

    func testLoadDataWithMissingFiles() {
        let state = AppState()
        state.projectDirectory = URL(fileURLWithPath: "/nonexistent/path")
        state.loadData()

        XCTAssertTrue(state.experiments.isEmpty)
        // Hyperparameters should be defaults
        XCTAssertEqual(state.hyperparameters.depth, 4)
    }

    func testLoadDataWithValidTSV() throws {
        let tmpDir = FileManager.default.temporaryDirectory.appending(path: "test_\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let tsv = "commit\tval_bpb\tmemory_gb\tstatus\tdescription\nabc1234\t0.99\t44.0\tkeep\tbaseline"
        try tsv.write(to: tmpDir.appending(path: "results.tsv"), atomically: true, encoding: .utf8)

        let state = AppState()
        state.projectDirectory = tmpDir
        state.loadData()

        XCTAssertEqual(state.experiments.count, 1)
        XCTAssertEqual(state.experiments[0].commit, "abc1234")
    }
}
