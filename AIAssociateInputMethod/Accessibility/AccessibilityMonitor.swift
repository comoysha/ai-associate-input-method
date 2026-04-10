import Cocoa
import os

@Observable
final class AccessibilityMonitor {
    var currentText: String = ""
    var cursorScreenRect: CGRect = .zero
    var focusedAppName: String = ""
    var hasFocusedTextField: Bool = false

    private var timer: Timer?
    private var previousText: String = ""
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "AXMonitor")

    var onTextChanged: ((String) -> Void)?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
        logger.info("AX monitoring started")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        currentText = ""
        hasFocusedTextField = false
        logger.info("AX monitoring stopped")
    }

    private func poll() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        focusedAppName = frontApp.localizedName ?? "Unknown"

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Get focused element
        var focusedValue: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedValue)
        guard focusResult == .success, let focused = focusedValue else {
            hasFocusedTextField = false
            return
        }

        let focusedElement = focused as! AXUIElement

        // Check if it's a text field/area
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String ?? ""

        guard role == kAXTextFieldRole as String || role == kAXTextAreaRole as String else {
            hasFocusedTextField = false
            return
        }

        hasFocusedTextField = true

        // Read text content
        var textValue: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &textValue)
        let text = textValue as? String ?? ""
        currentText = text

        // Get cursor position on screen
        updateCursorRect(element: focusedElement)

        // Notify if text changed
        if text != previousText {
            previousText = text
            onTextChanged?(text)
        }
    }

    private func updateCursorRect(element: AXUIElement) {
        // Try to get the selected text range for cursor position
        var rangeValue: AnyObject?
        let rangeResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeValue)

        if rangeResult == .success, let range = rangeValue {
            // Try to get screen bounds for that range
            var boundsValue: AnyObject?
            let boundsResult = AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                range,
                &boundsValue
            )
            if boundsResult == .success, let boundsAX = boundsValue {
                var rect = CGRect.zero
                if AXValueGetValue(boundsAX as! AXValue, .cgRect, &rect) {
                    cursorScreenRect = rect
                    return
                }
            }
        }

        // Fallback: use element position + size
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)

        var position = CGPoint.zero
        var size = CGSize.zero

        if let pos = posValue {
            AXValueGetValue(pos as! AXValue, .cgPoint, &position)
        }
        if let sz = sizeValue {
            AXValueGetValue(sz as! AXValue, .cgSize, &size)
        }

        // Position overlay at bottom-left of text area as fallback
        cursorScreenRect = CGRect(x: position.x, y: position.y + size.height, width: 1, height: 16)
    }

    /// Read all visible text from the page (for conversation context)
    func readPageContent() -> String {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return "" }
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Get the focused window
        var windowValue: AnyObject?
        let winResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue)
        guard winResult == .success, let window = windowValue else { return "" }

        // Traverse the AX tree to collect all static text
        var texts: [String] = []
        collectTexts(element: window as! AXUIElement, texts: &texts, depth: 0, maxDepth: 15)

        return texts.joined(separator: "\n")
    }

    private func collectTexts(element: AXUIElement, texts: inout [String], depth: Int, maxDepth: Int) {
        guard depth < maxDepth else { return }

        // Get role
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String ?? ""

        // Collect text from static text and heading elements
        if role == kAXStaticTextRole as String || role == "AXHeading" {
            var textValue: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &textValue)
            if let text = textValue as? String, !text.isEmpty {
                texts.append(text)
            }
        }

        // Recurse into children
        var childrenValue: AnyObject?
        let childResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        guard childResult == .success, let children = childrenValue as? [AXUIElement] else { return }

        for child in children {
            collectTexts(element: child, texts: &texts, depth: depth + 1, maxDepth: maxDepth)
        }
    }
}
