import AppKit
import Sparkle

/// Updates through Sparkle, from the appcast attached to the latest GitHub release (SUFeedURL).
/// Each update is checked against the EdDSA key in Info.plist, since the app is only signed ad hoc.
final class Updater: NSObject, SPUStandardUserDriverDelegate {
    static let shared = Updater()

    /// Nil when run outside the app bundle (`swift run`), which has no feed to check.
    private lazy var controller: SPUStandardUpdaterController? = {
        guard Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil else { return nil }
        return SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
    }()

    var isAvailable: Bool { controller != nil }

    func start() { _ = controller }

    func checkForUpdates() {
        NSApp.activate()
        controller?.checkForUpdates(nil)
    }

    var checksAutomatically: Bool {
        get { controller?.updater.automaticallyChecksForUpdates ?? false }
        set { controller?.updater.automaticallyChecksForUpdates = newValue }
    }

    // A menu-bar app has no window to show a reminder in, so Sparkle shows found updates right away.
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        true
    }
}
