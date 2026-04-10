import Cocoa

@Observable
final class OverlayController {
    private var panel: OverlayPanel?
    private var textField: NSTextField?
    private var hintLabel: NSTextField?
    var isVisible: Bool = false

    func show(text: String, near cursorRect: CGRect) {
        guard !text.isEmpty else {
            hide()
            return
        }

        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.show(text: text, near: cursorRect) }
            return
        }

        if panel == nil {
            setupPanel()
        }

        guard let panel, let textField else { return }

        // Update text content only
        textField.stringValue = text

        // Calculate size
        let maxWidth: CGFloat = 450
        let padding: CGFloat = 20
        let textSize = textField.sizeThatFits(NSSize(width: maxWidth - padding, height: 200))
        let width = min(max(textSize.width + padding, 100), maxWidth)
        let height = textSize.height + 36 // text + hint + padding

        // Update text field frame
        textField.frame = NSRect(x: 10, y: 22, width: width - padding, height: textSize.height)
        hintLabel?.frame = NSRect(x: 10, y: 4, width: width - padding, height: 14)

        // Determine window position
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        var x: CGFloat
        var y: CGFloat

        if cursorRect.origin.x > 0 && cursorRect.origin.y > 0 && cursorRect.origin.y < screenFrame.height {
            x = cursorRect.origin.x
            let axBottom = cursorRect.origin.y + cursorRect.height + 4
            y = screenFrame.height - axBottom - height
        } else {
            // Fallback: center of screen
            x = (screenFrame.width - width) / 2
            y = screenFrame.height * 0.3
        }

        x = max(0, min(x, screenFrame.width - width))
        y = max(0, min(y, screenFrame.height - height))

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        isVisible = true
    }

    func hide() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.hide() }
            return
        }
        guard isVisible, let panel else { return }
        panel.orderOut(nil)
        isVisible = false
    }

    private func setupPanel() {
        let panel = OverlayPanel()

        // Background view
        let bgView = NSVisualEffectView()
        bgView.material = .hudWindow
        bgView.state = .active
        bgView.wantsLayer = true
        bgView.layer?.cornerRadius = 6

        // Text field for completion content
        let tf = NSTextField(labelWithString: "")
        tf.font = .systemFont(ofSize: 14)
        tf.textColor = .secondaryLabelColor
        tf.lineBreakMode = .byWordWrapping
        tf.maximumNumberOfLines = 5
        tf.isSelectable = false

        // Hint label
        let hint = NSTextField(labelWithString: "[Tab] 接受")
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .tertiaryLabelColor
        hint.isSelectable = false

        bgView.addSubview(tf)
        bgView.addSubview(hint)
        panel.contentView = bgView

        self.panel = panel
        self.textField = tf
        self.hintLabel = hint
    }
}
