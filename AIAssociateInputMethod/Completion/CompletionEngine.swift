import Foundation
import os

@Observable
final class CompletionEngine {
    var currentCompletion: String?

    private let apiClient: DoubaoAPIClient
    private let settings: AppSettings
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "CompletionEngine")

    private var debouncer: Debouncer
    private var currentTask: Task<Void, Never>?
    @ObservationIgnored private var completionContinuation: AsyncStream<String>.Continuation?
    @ObservationIgnored private(set) var completions: AsyncStream<String>!

    init(apiClient: DoubaoAPIClient, settings: AppSettings) {
        self.apiClient = apiClient
        self.settings = settings
        self.debouncer = Debouncer(milliseconds: settings.debounceMs)

        self.completions = AsyncStream { [weak self] continuation in
            self?.completionContinuation = continuation
        }
    }

    /// Called when the user's text input changes
    func textDidChange(currentInput: String, pageContent: String) {
        // Don't predict if input is too short
        guard currentInput.count >= 2 else {
            clearCompletion()
            return
        }

        guard settings.isConfigured else {
            logger.warning("API not configured, skipping completion")
            return
        }

        let context = ConversationContext(pageContent: pageContent, currentInput: currentInput)

        Task {
            await debouncer.debounce { [weak self] in
                await self?.requestCompletion(context: context)
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        Task { await debouncer.cancel() }
    }

    func clearCompletion() {
        currentCompletion = nil
        completionContinuation?.yield("")
        cancel()
    }

    @MainActor
    private func requestCompletion(context: ConversationContext) async {
        // Cancel any existing request
        currentTask?.cancel()

        currentTask = Task {
            var accumulated = ""
            let messages = PromptBuilder.buildMessages(context: context, settings: settings)

            logger.debug("Requesting completion for: \(context.currentInput.prefix(30))...")

            for await token in apiClient.streamCompletion(messages: messages) {
                if Task.isCancelled { return }

                accumulated += token
                currentCompletion = accumulated
                completionContinuation?.yield(accumulated)
            }

            if !Task.isCancelled {
                logger.debug("Completion finished: \(accumulated.prefix(50))...")
            }
        }
    }
}
