import Foundation

@MainActor
final class ProcessManager {
    private var process: Process?
    private var outputPipe: Pipe?

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    func run(
        command: String,
        arguments: [String],
        workingDirectory: URL,
        environment: [String: String]? = nil,
        onOutput: @escaping @MainActor (String) -> Void,
        onComplete: @escaping @MainActor (Int32) -> Void
    ) {
        stop()

        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        process.currentDirectoryURL = workingDirectory
        process.standardOutput = pipe
        process.standardError = pipe

        if let environment {
            var env = ProcessInfo.processInfo.environment
            env.merge(environment) { _, new in new }
            process.environment = env
        }

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let text = String(data: data, encoding: .utf8) else { return }

            let lines = text.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }

            Task { @MainActor in
                for line in lines {
                    onOutput(line)
                }
            }
        }

        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                // Drain remaining buffered output before closing
                let remaining = pipe.fileHandleForReading.readDataToEndOfFile()
                pipe.fileHandleForReading.readabilityHandler = nil

                if !remaining.isEmpty, let text = String(data: remaining, encoding: .utf8) {
                    for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                        onOutput(line)
                    }
                }

                self?.process = nil
                self?.outputPipe = nil
                onComplete(proc.terminationStatus)
            }
        }

        do {
            try process.run()
            self.process = process
            self.outputPipe = pipe
        } catch {
            onOutput("Failed to start process: \(error.localizedDescription)")
            onComplete(-1)
        }
    }

    func stop() {
        guard let process, process.isRunning else {
            self.process = nil
            self.outputPipe = nil
            return
        }
        process.terminate()
        // Don't nil out here — let terminationHandler clean up
    }
}
