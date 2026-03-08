import Foundation

@MainActor
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var watchedURL: URL?
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    func watch(url: URL) {
        stop()
        watchedURL = url

        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            Task { @MainActor in
                self.onChange()
                // If file was deleted or renamed, re-watch after a short delay
                if flags.contains(.delete) || flags.contains(.rename) {
                    self.rewatch()
                }
            }
        }

        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }

        source.resume()
        self.source = source
    }

    private func rewatch() {
        guard let url = watchedURL else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            self?.watch(url: url)
        }
    }

    func stop() {
        source?.cancel()
        source = nil
        // fileDescriptor is closed by the cancel handler
    }

    deinit {
        source?.cancel()
    }
}
