import AppKit

/// Shows an NSAlert without `runModal()`, so it never blocks the app: the menu-bar menu keeps opening
/// while a dialog is on screen. Over the main window it is a sheet of it, so it cannot end up behind
/// anything; otherwise it is a window of its own, kept in front.
final class Dialog: NSObject {
    private static var open: Set<Dialog> = []
    /// The window dialogs attach to while it is on screen (the main window), if any.
    static var host: () -> NSWindow? = { nil }

    private let alert: NSAlert
    private let completion: ((NSApplication.ModalResponse) -> Void)?

    private init(_ alert: NSAlert, _ completion: ((NSApplication.ModalResponse) -> Void)?) {
        self.alert = alert
        self.completion = completion
    }

    /// `completion` receives `.alertFirstButtonReturn`, `.alertSecondButtonReturn`, … like `runModal()`.
    static func show(_ alert: NSAlert, focus: NSView? = nil, completion: ((NSApplication.ModalResponse) -> Void)? = nil) {
        if alert.buttons.isEmpty { alert.addButton(withTitle: tr("OK")) }
        if let focus { alert.window.initialFirstResponder = focus }
        NSApp.activate()
        if let window = host(), window.isVisible, window.isOnActiveSpace, window.attachedSheet == nil {
            window.makeKeyAndOrderFront(nil)
            alert.beginSheetModal(for: window) { completion?($0) }
            return
        }

        let dialog = Dialog(alert, completion)
        open.insert(dialog)
        // Outside a modal session the buttons would do nothing, so they report to us instead.
        for (index, button) in alert.buttons.enumerated() {
            button.tag = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + index
            button.target = dialog
            button.action = #selector(buttonPressed(_:))
        }
        alert.layout()
        let window = alert.window
        window.isReleasedWhenClosed = false
        // Above other apps' windows, on the Space the user is on, even over a full-screen app.
        window.level = .modalPanel
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        // Centered on the screen with the pointer: "main" can be another display for a menu-bar app.
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
            let area = screen.visibleFrame, size = window.frame.size
            window.setFrameOrigin(NSPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2 + area.height / 6))
        } else {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        if let focus { window.makeFirstResponder(focus) }
        // Activation happens a moment later and brings the app's other windows forward: come back on top.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            guard window.isVisible else { return }
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            if let focus { window.makeFirstResponder(focus) }
        }
    }

    /// A one-button message.
    static func inform(_ title: String, _ text: String, style: NSAlert.Style = .informational) {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = text
        show(alert)
    }

    @objc private func buttonPressed(_ sender: NSButton) {
        alert.window.orderOut(nil)
        Dialog.open.remove(self)
        completion?(NSApplication.ModalResponse(rawValue: sender.tag))
    }
}
