import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = Self.mainMenu()
        controller = AppController()
    }

    /// The menu bar shown while the main window is open (the app is then in the Dock).
    private static func mainMenu() -> NSMenu {
        let main = NSMenu()
        func submenu(_ title: String, _ items: [NSMenuItem]) {
            let menu = NSMenu(title: title)
            items.forEach(menu.addItem)
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.submenu = menu
            main.addItem(item)
        }
        func item(_ title: String, _ action: Selector, _ key: String, _ modifiers: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = modifiers
            return item
        }
        submenu("Porter", [
            item(tr("Hide Porter"), #selector(NSApplication.hide(_:)), "h"),
            .separator(),
            item(tr("Quit"), #selector(NSApplication.terminate(_:)), "q"),
        ])
        submenu(tr("Edit"), [
            item(tr("Undo"), Selector(("undo:")), "z"),
            item(tr("Redo"), Selector(("redo:")), "z", [.command, .shift]),
            .separator(),
            item(tr("Cut"), #selector(NSText.cut(_:)), "x"),
            item(tr("Copy"), #selector(NSText.copy(_:)), "c"),
            item(tr("Paste"), #selector(NSText.paste(_:)), "v"),
            item(tr("Select All"), #selector(NSText.selectAll(_:)), "a"),
        ])
        submenu(tr("Window"), [
            item(tr("Minimize"), #selector(NSWindow.performMiniaturize(_:)), "m"),
            item(tr("Close"), #selector(NSWindow.performClose(_:)), "w"),
        ])
        return main
    }
}

if let status = CLI.runIfRequested(CommandLine.arguments) { exit(status) }

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
