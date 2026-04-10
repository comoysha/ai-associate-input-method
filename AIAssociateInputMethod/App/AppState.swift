import SwiftUI
import os

@Observable
final class AppState {
    var isEnabled: Bool = false {
        didSet {
            DebugLog.log("isEnabled changed to \(isEnabled)")
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }
    var statusMessage: String = "Idle"

    var settings = AppSettings()
    let accessibilityPermission = AccessibilityPermission()
    let accessibilityMonitor = AccessibilityMonitor()
    let completionEngine: CompletionEngine
    let overlayController = OverlayController()
    let keyboardMonitor = KeyboardMonitor()
    let textInjector = TextInjector()

    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "AppState")
    /// Tracks text length right after injection, to detect whether user typed new content
    private var textLengthAfterInjection: Int?

    init() {
        DebugLog.log("AppState init")
        let s = AppSettings()
        self.settings = s
        self.completionEngine = CompletionEngine(
            apiClient: DoubaoAPIClient(settings: s),
            settings: s
        )

        overlayController.dismissSeconds = s.overlayDismissSec

        DebugLog.log("API configured: \(s.isConfigured), key prefix: \(String(s.apiKey.prefix(8)))")

        keyboardMonitor.onTabAccept = { [weak self] in
            self?.acceptCompletion()
        }

        accessibilityMonitor.onTextChanged = { [weak self] text in
            guard let self, self.isEnabled else { return }
            DebugLog.log("Text changed: \(text.prefix(50))")
            self.handleTextChanged(text)
        }
    }

    private func start() {
        DebugLog.log("start() called, isTrusted=\(accessibilityPermission.isTrusted)")
        guard accessibilityPermission.isTrusted else {
            accessibilityPermission.requestPermission()
            statusMessage = "Need accessibility permission"
            isEnabled = false
            return
        }

        accessibilityMonitor.startMonitoring()
        keyboardMonitor.start()
        statusMessage = "Monitoring..."
        DebugLog.log("Monitoring started")

        Task { @MainActor in
            for await completion in completionEngine.completions {
                if !isEnabled { break }
                handleCompletionUpdate(completion)
            }
        }
    }

    private func stop() {
        accessibilityMonitor.stopMonitoring()
        keyboardMonitor.stop()
        overlayController.hide()
        completionEngine.cancel()
        keyboardMonitor.isOverlayVisible = false
        statusMessage = "Idle"
    }

    private func handleTextChanged(_ text: String) {
        overlayController.hide()
        keyboardMonitor.isOverlayVisible = false

        // After Tab injection, only trigger new completion if user actually typed more
        if let expectedLen = textLengthAfterInjection {
            if text.count <= expectedLen {
                // Text change is from injection itself, or user deleted — don't trigger
                DebugLog.log("Skipping completion: post-injection, no new input (len \(text.count) <= \(expectedLen))")
                textLengthAfterInjection = text.count == expectedLen ? expectedLen : nil
                return
            }
            // User typed new content beyond the injected text
            DebugLog.log("Post-injection: user typed new content (len \(text.count) > \(expectedLen))")
            textLengthAfterInjection = nil
        }

        let pageContent = accessibilityMonitor.readPageContent()
        DebugLog.log("Page content length: \(pageContent.count)")

        completionEngine.textDidChange(currentInput: text, pageContent: pageContent)
        statusMessage = "Monitoring: \(accessibilityMonitor.focusedAppName)"
    }

    func syncOverlayDismiss() {
        overlayController.dismissSeconds = settings.overlayDismissSec
    }

    @MainActor
    private func handleCompletionUpdate(_ completion: String) {
        DebugLog.log("Completion update: \(completion.prefix(50))")
        if completion.isEmpty {
            overlayController.hide()
            keyboardMonitor.isOverlayVisible = false
        } else {
            let cursorRect = accessibilityMonitor.cursorScreenRect
            overlayController.show(text: completion, near: cursorRect)
            keyboardMonitor.isOverlayVisible = true
        }
    }

    private func acceptCompletion() {
        guard let completion = completionEngine.currentCompletion, !completion.isEmpty else {
            return
        }
        // Record expected text length after injection so we can suppress auto-trigger
        let currentLen = accessibilityMonitor.currentText.count
        textLengthAfterInjection = currentLen + completion.count

        overlayController.hide()
        keyboardMonitor.isOverlayVisible = false
        textInjector.inject(text: completion)
        completionEngine.clearCompletion()
    }
}
