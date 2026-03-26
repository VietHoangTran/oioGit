import Foundation

/// Watches .git directories for changes using DispatchSource.
/// All mutable state is confined to `queue` for thread safety.
final class FileWatcherService: @unchecked Sendable {
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var debounceItems: [String: DispatchWorkItem] = [:]
    private let debounceInterval: TimeInterval
    private let queue = DispatchQueue(
        label: "com.oioGit.fileWatcher", qos: .utility
    )

    init(debounceInterval: TimeInterval = 1.0) {
        self.debounceInterval = debounceInterval
    }

    deinit {
        stopAllSync()
    }

    func startWatching(
        repoId: String, directory: URL, onChange: @escaping @Sendable () -> Void
    ) {
        queue.async { [self] in
            // Stop existing watcher for this repo if any
            stopWatchingSync(repoId: repoId)

            let gitDir = directory.appendingPathComponent(".git")
            let fd = open(gitDir.path, O_EVTONLY)
            guard fd >= 0 else { return }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: .write,
                queue: queue
            )

            source.setEventHandler { [weak self] in
                self?.debounceSync(repoId: repoId, action: onChange)
            }

            source.setCancelHandler {
                close(fd)
            }

            sources[repoId] = source
            source.resume()
        }
    }

    func stopWatching(repoId: String) {
        queue.async { [self] in
            stopWatchingSync(repoId: repoId)
        }
    }

    func stopAll() {
        queue.async { [self] in
            stopAllSync()
        }
    }

    // MARK: - Queue-confined (must be called on `queue`)

    private func stopWatchingSync(repoId: String) {
        debounceItems[repoId]?.cancel()
        debounceItems.removeValue(forKey: repoId)

        if let source = sources.removeValue(forKey: repoId) {
            source.cancel()
        }
    }

    private func stopAllSync() {
        for repoId in Array(sources.keys) {
            stopWatchingSync(repoId: repoId)
        }
    }

    private func debounceSync(
        repoId: String, action: @escaping @Sendable () -> Void
    ) {
        debounceItems[repoId]?.cancel()
        let item = DispatchWorkItem { action() }
        debounceItems[repoId] = item
        queue.asyncAfter(
            deadline: .now() + debounceInterval, execute: item
        )
    }
}
