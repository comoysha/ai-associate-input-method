import Cocoa
import os

final class TextInjector {
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "TextInjector")

    func inject(text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type) else { return nil }
            return (type.rawValue, data)
        } ?? []

        // Set completion text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulatePaste()

        // Restore clipboard after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            pasteboard.clearContents()
            for (typeStr, data) in savedItems {
                let type = NSPasteboard.PasteboardType(typeStr)
                pasteboard.setData(data, forType: type)
            }
        }

        logger.debug("Injected text: \(text.prefix(50))...")
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        // Key down: Cmd + V
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand

        // Key up: Cmd + V
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
