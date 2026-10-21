import AppKit
import os

/// Claude links (claude://…, for example the way back to the app after signing in in the browser).
/// Every profile is the same app, so macOS hands such a link to any one of the open ones. When Porter
/// is the app for these links, it passes each one to the Claude profile used last instead.
enum LinkRouter {
    static let scheme = "claude"
    private static let log = Logger(subsystem: "io.github.matteogilioli.porter", category: "links")
    /// The Claude instance that was in front last: the one that just sent you to the browser.
    private static var lastActive: pid_t?

    /// Starts following which Claude instance is in front.
    static func start() {
        lastActive = NSWorkspace.shared.frontmostApplication.flatMap {
            $0.bundleIdentifier == Discovery.claudeBundleId ? $0.processIdentifier : nil
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil, queue: .main) { note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == Discovery.claudeBundleId else { return }
            lastActive = app.processIdentifier
        }
    }

    /// Whether macOS opens Claude links with Porter.
    static var isEnabled: Bool {
        guard let url = URL(string: "\(scheme)://"), let handler = NSWorkspace.shared.urlForApplication(toOpen: url) else { return false }
        return handler.standardizedFileURL.path == Bundle.main.bundleURL.standardizedFileURL.path
    }

    /// Makes Porter (or Claude again) the app for Claude links. macOS may ask the user to confirm.
    static func setEnabled(_ on: Bool, completion: @escaping (Error?) -> Void) {
        let app = on ? Bundle.main.bundleURL : NSWorkspace.shared.urlForApplication(withBundleIdentifier: Discovery.claudeBundleId)
        guard let app else { return completion(CocoaError(.fileNoSuchFile)) }
        NSWorkspace.shared.setDefaultApplication(at: app, toOpenURLsWithScheme: scheme) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    /// Passes a link to the Claude instance used last, or, before any was used while Porter runs,
    /// to the one started last (usually a profile just created, waiting for its sign-in).
    static func open(_ url: URL) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: Discovery.claudeBundleId)
            .filter { !$0.isTerminated && Discovery.isAlive($0.processIdentifier) }
        let target = running.first { $0.processIdentifier == lastActive }
            ?? running.max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
        log.info("Link \(url.scheme ?? "", privacy: .public) for pid \(target?.processIdentifier ?? 0, privacy: .public) (last active \(lastActive ?? 0, privacy: .public), \(running.count, privacy: .public) open)")
        if let target, send(url, to: target) {
            target.activate()
            return
        }
        // No Claude open, or it could not be reached: let macOS open the link in Claude its own way.
        guard let claude = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Discovery.claudeBundleId) else { return }
        NSWorkspace.shared.open([url], withApplicationAt: claude, configuration: NSWorkspace.OpenConfiguration())
    }

    /// The "open URL" Apple Event, addressed to one process rather than to the app.
    private static func send(_ url: URL, to app: NSRunningApplication) -> Bool {
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(kInternetEventClass), eventID: AEEventID(kAEGetURL),
                                           targetDescriptor: NSAppleEventDescriptor(processIdentifier: app.processIdentifier),
                                           returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(NSAppleEventDescriptor(string: url.absoluteString), forKeyword: keyDirectObject)
        do {
            _ = try event.sendEvent(options: [.noReply], timeout: 5)
            return true
        } catch {
            log.error("Could not pass the link to pid \(app.processIdentifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
