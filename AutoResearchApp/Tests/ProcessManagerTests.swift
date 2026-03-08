import XCTest
@testable import AutoResearchApp

@MainActor
final class ProcessManagerTests: XCTestCase {

    func testInitialState() {
        let pm = ProcessManager()
        XCTAssertFalse(pm.isRunning)
    }

    func testRunEchoCommand() async throws {
        let pm = ProcessManager()
        let expectation = XCTestExpectation(description: "Process completes")
        var capturedLines: [String] = []
        var exitStatus: Int32 = -1

        pm.run(
            command: "echo",
            arguments: ["hello world"],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { line in
                capturedLines.append(line)
            },
            onComplete: { status in
                exitStatus = status
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 10)

        XCTAssertEqual(exitStatus, 0)
        XCTAssertTrue(capturedLines.contains("hello world"))
        XCTAssertFalse(pm.isRunning)
    }

    func testRunFailingCommand() async throws {
        let pm = ProcessManager()
        let expectation = XCTestExpectation(description: "Process completes")
        var exitStatus: Int32 = 0

        pm.run(
            command: "false",
            arguments: [],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { _ in },
            onComplete: { status in
                exitStatus = status
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 10)

        XCTAssertNotEqual(exitStatus, 0)
        XCTAssertFalse(pm.isRunning)
    }

    func testRunNonexistentCommand() async throws {
        let pm = ProcessManager()
        let expectation = XCTestExpectation(description: "Process completes")
        var capturedLines: [String] = []

        pm.run(
            command: "nonexistent_command_xyz_12345",
            arguments: [],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { line in
                capturedLines.append(line)
            },
            onComplete: { _ in
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 10)

        XCTAssertFalse(pm.isRunning)
    }

    func testStopTerminatesProcess() async throws {
        let pm = ProcessManager()
        let startExpectation = XCTestExpectation(description: "Process started")
        let completeExpectation = XCTestExpectation(description: "Process completes")

        pm.run(
            command: "sleep",
            arguments: ["60"],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { _ in
                startExpectation.fulfill()
            },
            onComplete: { _ in
                completeExpectation.fulfill()
            }
        )

        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(200))

        pm.stop()

        await fulfillment(of: [completeExpectation], timeout: 10)

        XCTAssertFalse(pm.isRunning)
    }

    func testStopWhenNotRunning() {
        let pm = ProcessManager()
        // Should not crash
        pm.stop()
        XCTAssertFalse(pm.isRunning)
    }

    func testRunMultilineOutput() async throws {
        let pm = ProcessManager()
        let expectation = XCTestExpectation(description: "Process completes")
        var capturedLines: [String] = []

        pm.run(
            command: "printf",
            arguments: ["line1\\nline2\\nline3\\n"],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { line in
                capturedLines.append(line)
            },
            onComplete: { _ in
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 10)

        XCTAssertTrue(capturedLines.count >= 3)
        XCTAssertTrue(capturedLines.contains("line1"))
        XCTAssertTrue(capturedLines.contains("line2"))
        XCTAssertTrue(capturedLines.contains("line3"))
    }

    func testSecondRunStopsFirst() async throws {
        let pm = ProcessManager()
        let firstComplete = XCTestExpectation(description: "First process completes")
        let secondComplete = XCTestExpectation(description: "Second process completes")

        pm.run(
            command: "sleep",
            arguments: ["60"],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { _ in },
            onComplete: { _ in
                firstComplete.fulfill()
            }
        )

        try await Task.sleep(for: .milliseconds(200))

        // Starting a second run should terminate the first
        pm.run(
            command: "echo",
            arguments: ["second"],
            workingDirectory: URL(fileURLWithPath: "/tmp"),
            onOutput: { _ in },
            onComplete: { _ in
                secondComplete.fulfill()
            }
        )

        await fulfillment(of: [firstComplete, secondComplete], timeout: 10)

        XCTAssertFalse(pm.isRunning)
    }
}
