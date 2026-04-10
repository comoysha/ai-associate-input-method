import Cocoa
import os

@Observable
final class AccessibilityPermission {
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "Permission")
    private var timer: Timer?

    var isTrusted: Bool = AXIsProcessTrusted()

    init() {
        // Poll every 2 seconds to detect permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.isTrusted = AXIsProcessTrusted()
        }
    }

    deinit {
        timer?.invalidate()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        isTrusted = trusted
        logger.info("Accessibility permission requested, currently trusted: \(trusted)")

        if !trusted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
