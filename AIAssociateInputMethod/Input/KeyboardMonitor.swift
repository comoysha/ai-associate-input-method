import Cocoa
import os

final class KeyboardMonitor {
    var onTabAccept: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let logger = Logger(subsystem: "com.aiassociate.inputmethod", category: "Keyboard")

    // Shared reference for C callback
    private static var shared: KeyboardMonitor?

    /// Whether the overlay is currently showing (set by AppState)
    var isOverlayVisible: Bool = false

    func start() {
        KeyboardMonitor.shared = self

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: KeyboardMonitor.eventCallback,
            userInfo: nil
        ) else {
            logger.error("Failed to create event tap. Check accessibility permissions.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        logger.info("Keyboard monitor started")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        KeyboardMonitor.shared = nil
        logger.info("Keyboard monitor stopped")
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, _ in
        // Handle tap being disabled by timeout
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = KeyboardMonitor.shared?.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Tab key = keycode 48
        if keyCode == 48, let monitor = KeyboardMonitor.shared, monitor.isOverlayVisible {
            // Consume Tab and trigger acceptance
            DispatchQueue.main.async {
                monitor.onTabAccept?()
            }
            return nil // Suppress the Tab event
        }

        return Unmanaged.passRetained(event)
    }
}
