import Foundation

actor Debouncer {
    private let duration: Duration
    private var task: Task<Void, Never>?

    init(milliseconds: Int) {
        self.duration = .milliseconds(milliseconds)
    }

    func debounce(action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
