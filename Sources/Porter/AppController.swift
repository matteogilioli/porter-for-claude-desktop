import AppKit
import ServiceManagement

/// Everything the panel shows, read from disk off the main thread.
struct Snapshot {
    var dataDirs: [DataDir] = []
    var stores: [Store] = []
    var running: Set<String> = []
    /// Data folder path → account the app is signed in to.
    var signedIn: [String: String] = [:]
    /// Names the user gave their projects in Claude Desktop (session presets), by preset id and folder.
    var environments: (byId: [String: String], byPath: [String: String]) = ([:], [:])
    /// Project folders sessions use that no longer exist (checked here, off the main thread).
    var missingProjects: Set<String> = []
    /// Changes whenever anything shown changes, so an identical reload does not redraw every view.
    var signature = 0

    static func load() -> Snapshot {
        let running = Set(Discovery.runningInstances().map(\.dataDir))
        let dirs = Discovery.dataDirs(running: running)
        var snapshot = Snapshot(dataDirs: dirs, running: running)
        for dir in dirs {
            autoreleasepool {
                let signedIn = Discovery.signedInAccount(in: dir)
                snapshot.signedIn[dir.path] = signedIn
                snapshot.stores += Discovery.stores(in: dir, signedIn: signedIn)
            }
        }
        snapshot.environments = Discovery.environmentNames(in: dirs)
        let projects = Set(snapshot.stores.flatMap { $0.sessions.compactMap(\.projectPath) })
        snapshot.missingProjects = projects.filter { !FileManager.default.fileExists(atPath: $0) }
        snapshot.signature = snapshot.fingerprint()
        Discovery.saveHeaderCache()
        return snapshot
    }

    private func fingerprint() -> Int {
        var h = Hasher()
        for dir in dataDirs { h.combine(dir) }
        h.combine(running.sorted())
        h.combine(signedIn.sorted { $0.key < $1.key }.map { $0.key + "=" + $0.value })
        h.combine(environments.byId.sorted { $0.key < $1.key }.map { $0.key + "=" + $0.value })
        h.combine(environments.byPath.sorted { $0.key < $1.key }.map { $0.key + "=" + $0.value })
        h.combine(missingProjects.sorted())
        for store in stores {
            h.combine(store.key)
            h.combine(store.isSignedIn)
            h.combine(store.usage?.fiveHour)
            h.combine(store.usage?.sevenDay)
            h.combine(store.usage?.sampledAt)
            for s in store.sessions {
                h.combine(s.id); h.combine(s.title); h.combine(s.error); h.combine(s.lastActivity); h.combine(s.isArchived)
                h.combine(s.cwd); h.combine(s.runCwd); h.combine(s.environmentId); h.combine(s.cliSessionId)
            }
        }
        return h.finalize()
    }

    func stores(in dir: DataDir) -> [Store] { stores.filter { $0.dataDir == dir } }

    func isPrevious(_ store: Store) -> Bool { signedIn[store.dataDir.path] != store.accountUuid }

    /// Names come from what is known, never from the user: the account signed in to a profile shows
    /// its email if known (else the profile's name), an account that left the profile is a
    /// "previous account", and the same account in another organization is "other organization".
    func name(_ store: Store) -> String {
        if isPrevious(store) {
            if let known = Discovery.knownAccountName(store.accountUuid) { return known }
            let previous = Set(stores.filter { $0.dataDir == store.dataDir && isPrevious($0) }.map(\.accountUuid))
            return previous.count > 1 ? tr("Previous account %@", String(store.accountUuid.prefix(8))) : tr("Previous account")
        }
        if !store.isSignedIn { return tr("Other organization") }
        return Discovery.knownAccountName(store.accountUuid) ?? store.dataDir.label
    }
}

/// A move the user started (from the action bar, a drag or the panel), waiting for its options.
struct MoveDraft: Identifiable {
    let id = UUID()
    let sourceKey: String
    let sessionIds: [String]
    let targetKey: String?
}

/// One Claude app (data folder) as the panel lists it: the account signed in there, plus the
/// accounts and organizations that used it before.
struct ProfileEntry: Identifiable {
    let dir: DataDir
    let main: Store?
    let others: [Store]
    var id: String { dir.path }
}

/// Whether a reload is running, apart from the data: only the spinners redraw when it changes.
final class LoadState: ObservableObject {
    @Published fileprivate(set) var refreshing = false
}

/// Owns the menu-bar item, the data and every action. Data is refreshed in the background (on a
/// timer and whenever the panel opens), so opening it never waits for the disk.
final class AppController: NSObject, ObservableObject {
    @Published private(set) var snapshot = Snapshot()
    let loading = LoadState()
    /// When the views last got a snapshot: times like "5 min ago" are refreshed at least this often.
    private var publishedAt = Date.distantPast
    @Published private(set) var busy = false { didSet { updateIcon() } }
    /// What the running operation is doing, for the panel.
    @Published private(set) var activity: String?
    @Published private(set) var multipleProfiles = Settings.multipleProfiles
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var routeLinks = LinkRouter.isEnabled
    @Published private(set) var checksForUpdates = Updater.shared.checksAutomatically
    /// The account shown in the main window (a store key).
    @Published var selectedKey: String?
    @Published var moveDraft: MoveDraft?
    /// Bumped after every move or action that changed sessions, so views can drop their selection.
    @Published private(set) var changes = 0

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var reloadAgain = false
    private lazy var panel = StatusPanel(controller: self)
    private lazy var mainWindow = MainWindow(controller: self)


    override init() {
        super.init()
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
        Dialog.host = { [weak self] in self?.mainWindow.window }
        reload()
        let timer = Timer(timeInterval: 300, repeats: true) { [weak self] _ in self?.reload() }
        timer.tolerance = 60
        RunLoop.main.add(timer, forMode: .common)
    }

    /// Reloads in the background. A request that arrives during a reload runs right after it,
    /// so a change made meanwhile (a setting, a move) is never lost.
    func reload() {
        guard !loading.refreshing else { reloadAgain = true; return }
        loading.refreshing = true
        DispatchQueue.global(qos: .utility).async {
            let fresh = Snapshot.load()
            // Hand the memory used while reading back to the system.
            malloc_zone_pressure_relief(nil, 0)
            DispatchQueue.main.async {
                if fresh.signature != self.snapshot.signature || Date().timeIntervalSince(self.publishedAt) > 60 {
                    self.snapshot = fresh
                    self.publishedAt = Date()
                }
                self.loading.refreshing = false
                self.updateIcon()
                if self.reloadAgain {
                    self.reloadAgain = false
                    self.reload()
                }
            }
        }
    }

    private func updateIcon() {
        let stopped = snapshot.stores.reduce(0) { $0 + $1.stopped.count }
        statusItem.button?.image = Icon.menuBar(badge: stopped > 0 && !busy, busy: busy)
        statusItem.button?.toolTip = stopped > 0 ? tr("%ld session(s) stopped by a usage limit", stopped) : "Porter for Claude Desktop"
    }

    // MARK: - Status item

    /// A click opens the panel; a right-click a short menu with the settings, as in other menu-bar apps.
    @objc private func statusItemClicked() {
        guard let button = statusItem.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            panel.close()
            statusItem.menu = contextMenu()
            button.performClick(nil)
            statusItem.menu = nil
            return
        }
        if panel.isVisible {
            panel.close()
        } else {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            routeLinks = LinkRouter.isEnabled
            checksForUpdates = Updater.shared.checksAutomatically
            panel.show(below: button)
            // Show what we have now and fresh data a moment later.
            reload()
        }
    }

    private func contextMenu() -> NSMenu {
        let menu = NSMenu()
        let profiles = NSMenuItem(title: tr("Multiple Profiles"), action: #selector(menuToggleProfiles), keyEquivalent: "")
        profiles.target = self
        profiles.state = multipleProfiles ? .on : .off
        menu.addItem(profiles)
        if showsRouteLinks {
            let links = NSMenuItem(title: tr("Open Links in the Right Profile"), action: #selector(menuToggleLinks), keyEquivalent: "")
            links.target = self
            links.state = LinkRouter.isEnabled ? .on : .off
            menu.addItem(links)
        }
        let login = NSMenuItem(title: tr("Launch at Login"), action: #selector(menuToggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        if Updater.shared.isAvailable {
            let auto = NSMenuItem(title: tr("Check for Updates Automatically"), action: #selector(menuToggleUpdates), keyEquivalent: "")
            auto.target = self
            auto.state = Updater.shared.checksAutomatically ? .on : .off
            menu.addItem(auto)
            let check = NSMenuItem(title: tr("Check for Updates…"), action: #selector(menuCheckForUpdates), keyEquivalent: "")
            check.target = self
            menu.addItem(check)
        }
        let backups = NSMenuItem(title: tr("Show Backups"), action: #selector(menuShowBackups), keyEquivalent: "")
        backups.target = self
        menu.addItem(backups)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: tr("Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc private func menuToggleProfiles() { toggleMultipleProfiles() }
    @objc private func menuToggleLogin() { toggleLaunchAtLogin() }
    @objc private func menuToggleLinks() { toggleRouteLinks() }
    @objc private func menuToggleUpdates() { toggleChecksForUpdates() }
    @objc private func menuCheckForUpdates() { checkForUpdates() }
    @objc private func menuShowBackups() { showBackups() }

    // MARK: - What the panel shows

    /// Classic mode: the signed-in accounts first, then the ones used before in the same app.
    var accountSections: [(title: String, stores: [Store])] {
        [(tr("Signed in"), snapshot.stores.filter(\.isSignedIn)), (tr("Not signed in"), snapshot.stores.filter { !$0.isSignedIn })]
            .filter { !$0.stores.isEmpty }
    }

    /// Multiple-profiles mode: one entry per Claude app, running ones first.
    var profileSections: [(title: String, profiles: [ProfileEntry])] {
        let entries = snapshot.dataDirs.map { dir -> ProfileEntry in
            let stores = snapshot.stores(in: dir)
            let main = stores.first(where: \.isSignedIn)
            return ProfileEntry(dir: dir, main: main, others: stores.filter { $0.key != main?.key })
        }
        return [(tr("Running"), entries.filter { isRunning($0.dir) }), (tr("Closed"), entries.filter { !isRunning($0.dir) })]
            .filter { !$0.profiles.isEmpty }
    }

    var isEmpty: Bool { snapshot.stores.isEmpty && (!multipleProfiles || snapshot.dataDirs.isEmpty) }

    func isRunning(_ dir: DataDir) -> Bool { snapshot.running.contains(dir.path) }
    func isPrevious(_ store: Store) -> Bool { snapshot.isPrevious(store) }
    func name(_ store: Store) -> String { snapshot.name(store) }
    func isMissing(_ project: PickerProject) -> Bool { snapshot.missingProjects.contains(project.path) }

    func profileTitle(_ dir: DataDir) -> String {
        dir.isDefault ? tr("Claude (default)") : dir.label
    }

    func openAppTitle(_ dir: DataDir) -> String {
        isRunning(dir) ? tr("Show Claude Desktop") : tr("Open Claude Desktop")
    }

    /// How a store is named in dialogs and destination lists: the profile, plus the account
    /// when it is not the one signed in there (a previous account or another organization).
    func label(_ store: Store) -> String {
        store.isSignedIn ? profileTitle(store.dataDir) : "\(profileTitle(store.dataDir)) · \(snapshot.name(store))"
    }

    /// The account's email, or why its sessions are not visible yet.
    func accountDetail(_ store: Store) -> String? {
        if store.isSignedIn { return Discovery.knownAccountName(store.accountUuid) }
        return isPrevious(store) ? tr("Not signed in") : tr("Switch to this organization in Claude to see them")
    }

    /// Every store sessions of `source` can go to.
    func targets(for source: Store) -> [Store] {
        snapshot.stores.filter { $0.key != source.key }
    }

    /// A signed-in account with usage left is the natural destination.
    func bestTarget(for source: Store) -> Store? {
        let all = targets(for: source)
        return all.first { $0.isSignedIn && $0.usage?.exhausted != true } ?? all.first { $0.isSignedIn } ?? all.first
    }

    // MARK: - Actions

    func store(_ key: String?) -> Store? { key.flatMap { k in snapshot.stores.first { $0.key == k } } }

    /// The project a session belongs to, named as in Claude Desktop when the user named it there.
    func project(of session: SessionInfo) -> PickerProject? {
        guard let path = session.projectPath else { return nil }
        let names = snapshot.environments
        let name = session.environmentId.flatMap { names.byId[$0] } ?? names.byPath[path]
            ?? (path == Paths.home ? "~" : (path as NSString).lastPathComponent)
        return PickerProject(path: path, name: name)
    }

    /// Opens the main window, on `store` if given.
    func openMain(_ store: Store? = nil) {
        panel.close()
        if let store { selectedKey = store.key }
        if self.store(selectedKey) == nil { selectedKey = snapshot.stores.first(where: \.isSignedIn)?.key ?? snapshot.stores.first?.key }
        mainWindow.show()
    }

    /// Opens the main window ready to move these sessions, to `target` if given.
    func move(_ sessions: [SessionInfo], from source: Store, to target: Store?) {
        openMain(source)
        moveDraft = MoveDraft(sourceKey: source.key, sessionIds: sessions.map(\.id), targetKey: target?.key)
    }

    /// Sessions dragged onto an account in the sidebar: "<store key>\n<id>,<id>…".
    func drop(_ payload: String, onto target: Store) -> Bool {
        let parts = payload.split(separator: "\n", maxSplits: 1).map(String.init)
        guard !busy, parts.count == 2, parts[0] != target.key, store(parts[0]) != nil else { return false }
        moveDraft = MoveDraft(sourceKey: parts[0], sessionIds: parts[1].split(separator: ",").map(String.init),
                              targetKey: target.key)
        return true
    }

    func toggleMultipleProfiles() {
        Settings.multipleProfiles.toggle()
        multipleProfiles = Settings.multipleProfiles
        if !multipleProfiles {
            panel.close()
            Dialog.inform(tr("Classic mode"),
                          tr("Use one Claude app and switch accounts by signing out and in. When an account hits its limit, sign in with another one, then move the sessions of the old account to it from this menu.\n\nProfiles you already have are not touched, and their sessions stay listed so you can move them."))
        }
    }

    func newProfile() {
        panel.close()
        askName(tr("New Claude profile"),
                tr("Opens a separate Claude app with its own sign-in, for example for a second account. Sign in there, then move sessions to it from this menu."),
                current: nil, placeholder: tr("e.g. Work")) { [weak self] name in
            guard !name.isEmpty else { return }
            let slug = name.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
            var path = "\(Paths.profiles)/\(slug)"
            var n = 2
            while FileManager.default.fileExists(atPath: path) { path = "\(Paths.profiles)/\(slug)-\(n)"; n += 1 }
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                Dialog.inform(tr("Could not create the profile"), error.localizedDescription, style: .warning)
                return
            }
            let dir = Paths.normalize(path)
            Settings.profiles[dir] = name
            DispatchQueue.global().async { AppControl.launch(DataDir(path: dir, label: name)) }
            self?.reload()
        }
    }

    /// Runs one change to Claude's files in the background: one at a time, here and on the command
    /// line. `done` hears the report as soon as the files are written; the app stays busy until the
    /// Claude apps closed for the change are back, so the next change never writes under one starting up.
    private func perform(_ activity: String, _ work: @escaping () throws -> Outcome,
                         done: @escaping (Result<String, Error>) -> Void) {
        guard !busy else { return done(.failure(MoveError.message(tr("Porter is already changing sessions: try again when it is done.")))) }
        busy = true
        self.activity = activity
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try OperationLock.run(work) }
            DispatchQueue.main.async {
                if case .success = result { self.changes += 1 }
                self.reload()
                done(result.map(\.text))
            }
            if case .success(let outcome) = result { AppControl.finish(outcome) }
            DispatchQueue.main.async {
                self.busy = false
                self.activity = nil
                self.reload()
            }
        }
    }

    /// Shows `alert` once `prepare` (run in the background, as it may read every session file) has
    /// filled it in.
    private func confirm(_ prepare: @escaping () -> (NSAlert) -> Void, then handle: @escaping (NSApplication.ModalResponse) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fill = prepare()
            DispatchQueue.main.async {
                let alert = NSAlert()
                fill(alert)
                Dialog.show(alert, completion: handle)
            }
        }
    }

    func run(_ plan: MovePlan, options: MoveOptions, progress: @escaping (String) -> Void = { _ in },
             done: @escaping (Result<String, Error>) -> Void) {
        perform(tr(options.mode == .move ? "Moving sessions…" : "Copying sessions…"), {
            try Mover.execute(plan, options: options) { step in DispatchQueue.main.async { progress(step) } }
        }, done: done)
    }

    /// Archives, restores or deletes sessions of one account. Deleting, or closing a running app,
    /// asks first; `done` gets nil when the user cancels.
    func apply(_ action: SessionAction, to sessions: [SessionInfo], in store: Store,
               done: @escaping (Result<String, Error>?) -> Void) {
        guard !busy, !sessions.isEmpty else { return done(nil) }
        let running = isRunning(store.dataDir)
        let dirs = snapshot.dataDirs
        let go = {
            self.perform(tr("Updating sessions…"), {
                try SessionActions.apply(action, to: sessions, in: store, among: dirs)
            }, done: done)
        }
        guard action == .delete || running else { return go() }
        confirm({
            var text: [String] = []
            if action == .delete {
                let files = Set(sessions.map { Mover.sessionFile(store, $0.id) })
                let orphaned = Transcripts.orphaned(among: dirs) { files.contains($0) }
                text.append(tr("They go to the Trash, so you can still restore them."))
                if !orphaned.isEmpty {
                    text.append(tr("%ld conversation(s) are not listed by any other account: they go to the Trash too. Worktrees in your projects are kept.", orphaned.count))
                }
            }
            if running { text.append(tr("%@ is open: it is closed and reopened to apply the change.", store.dataDir.label)) }
            return { alert in
                alert.alertStyle = action == .delete ? .warning : .informational
                switch action {
                case .archive:
                    alert.messageText = tr("Archive %ld session(s)?", sessions.count)
                    alert.addButton(withTitle: tr("Archive"))
                case .unarchive:
                    alert.messageText = tr("Restore %ld session(s)?", sessions.count)
                    alert.addButton(withTitle: tr("Restore"))
                case .delete:
                    alert.messageText = tr("Delete %ld session(s)?", sessions.count)
                    alert.addButton(withTitle: tr("Move to Trash")).hasDestructiveAction = true
                }
                alert.addButton(withTitle: tr("Cancel"))
                alert.informativeText = text.joined(separator: "\n\n")
            }
        }) { response in
            if response == .alertFirstButtonReturn { go() } else { done(nil) }
        }
    }

    /// Moves a project folder (`moveFolder`) or points its sessions at a folder already moved, after
    /// asking where and confirming.
    func relocateProject(_ project: PickerProject, moveFolder: Bool) {
        guard !busy else { return }
        panel.close()
        let pick: NSSavePanel
        if moveFolder {
            let save = NSSavePanel()
            save.nameFieldStringValue = (project.path as NSString).lastPathComponent
            save.directoryURL = URL(fileURLWithPath: (project.path as NSString).deletingLastPathComponent)
            save.canCreateDirectories = true
            save.prompt = tr("Move")
            save.message = tr("Choose the new place and name of %@.", project.name)
            pick = save
        } else {
            let open = NSOpenPanel()
            open.canChooseDirectories = true
            open.canChooseFiles = false
            open.directoryURL = URL(fileURLWithPath: (project.path as NSString).deletingLastPathComponent)
            open.prompt = tr("Relink")
            open.message = tr("Choose the folder %@ was moved to.", project.name)
            pick = open
        }
        NSApp.activate(ignoringOtherApps: true)
        let chosen: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = pick.url, let self else { return }
            self.confirmRelocate(project, to: url.path, moveFolder: moveFolder)
        }
        // A free-standing panel of a menu-bar app can open behind other apps' windows: attach it instead.
        if mainWindow.window.isVisible {
            pick.beginSheetModal(for: mainWindow.window, completionHandler: chosen)
        } else {
            pick.begin(completionHandler: chosen)
        }
    }

    private func confirmRelocate(_ project: PickerProject, to new: String, moveFolder: Bool) {
        let found = ProjectMover.sessions(of: project.path, in: snapshot.stores)
        let accounts = Set(found.map(\.store.key)).count
        let alert = NSAlert()
        alert.messageText = moveFolder ? tr("Move %@?", project.name) : tr("Relink %@?", project.name)
        var text = [tr("%ld session(s) in %ld account(s) will use %@.", found.count, accounts,
                       (new as NSString).abbreviatingWithTildeInPath),
                    tr("Their conversations in ~/.claude/projects move along. A backup of every file changed is kept.")]
        if snapshot.dataDirs.contains(where: { isRunning($0) }) {
            text.append(tr("Claude apps that are open are closed and reopened."))
        }
        alert.informativeText = text.joined(separator: "\n\n")
        alert.addButton(withTitle: moveFolder ? tr("Move") : tr("Relink"))
        alert.addButton(withTitle: tr("Cancel"))
        Dialog.show(alert) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            let dirs = self.snapshot.dataDirs
            self.perform(tr("Updating sessions…"), {
                try ProjectMover.relocate(from: project.path, to: new, moveFolder: moveFolder, expected: found.count, dirs: dirs)
            }) { result in
                switch result {
                case .success(let report): Dialog.inform(moveFolder ? tr("Project moved") : tr("Project relinked"), report)
                case .failure(let error): Dialog.inform(tr("Something went wrong"), error.localizedDescription, style: .warning)
                }
            }
        }
    }

    /// Removes an account that is no longer signed in to a profile: its session list goes to the
    /// Trash, with the conversations that no other account or profile lists. Only accounts other than
    /// the signed-in one qualify: another organization of that account may be the one in use.
    func removeAccount(_ store: Store) {
        guard !busy, snapshot.isPrevious(store) else { return }
        panel.close()
        let dirs = snapshot.dataDirs
        let name = snapshot.name(store)
        confirm({
            let orphaned = Transcripts.orphaned(by: store.path, among: dirs)
            let open = Discovery.openSessionCount(under: store.path)
            return { alert in
                alert.alertStyle = .warning
                alert.messageText = tr("Remove %@?", name)
                var text = tr("Its session list in %@ goes to the Trash. Nothing changes for the account itself, and you can still sign in with it.", store.dataDir.label)
                if open > 0 { text += "\n\n" + tr("This account has %ld open session(s): move them to another account first if you still need them.", open) }
                if !orphaned.isEmpty {
                    text += "\n\n" + tr("%ld conversation(s) are not listed by any other account: they go to the Trash too. Worktrees in your projects are kept.", orphaned.count)
                }
                alert.informativeText = text
                alert.addButton(withTitle: tr("Move to Trash"))
                alert.addButton(withTitle: tr("Cancel"))
            }
        }) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            self.perform(tr("Updating sessions…"), {
                // The account may have signed in again, or sessions moved, while the dialog was open.
                guard Discovery.signedInAccount(in: store.dataDir) != store.accountUuid else { return Outcome() }
                let orphaned = Transcripts.orphaned(by: store.path, among: dirs)
                try FileManager.default.trashItem(at: URL(fileURLWithPath: store.path), resultingItemURL: nil)
                Transcripts.trash(orphaned)
                return Outcome()
            }) { result in
                if case .failure(let error) = result {
                    Dialog.inform(tr("Could not remove the account"), error.localizedDescription, style: .warning)
                }
            }
        }
    }

    /// Closes the profile's Claude app and moves its data folder to the Trash (or only forgets it).
    func removeProfile(_ dir: DataDir) {
        guard !busy, !dir.isDefault else { return }
        panel.close()
        let dirs = snapshot.dataDirs
        confirm({
            let orphaned = Transcripts.orphaned(by: dir.sessionsRoot, among: dirs)
            let open = Discovery.openSessionCount(under: dir.sessionsRoot)
            return { alert in
                alert.alertStyle = .warning
                alert.messageText = tr("Remove %@?", dir.label)
                var text = tr("Its Claude app is closed and its data folder (sign-in, settings and session list) goes to the Trash, so you can still restore it.")
                if open > 0 { text += "\n\n" + tr("This profile has %ld open session(s): move them to another account first if you still need them.", open) }
                if !orphaned.isEmpty {
                    text += "\n\n" + tr("%ld conversation(s) were never moved to another profile: they go to the Trash too. Worktrees in your projects are kept.", orphaned.count)
                }
                alert.informativeText = text
                alert.addButton(withTitle: tr("Move to Trash"))
                alert.addButton(withTitle: tr("Remove from List Only"))
                alert.addButton(withTitle: tr("Cancel"))
            }
        }) { [weak self] response in
            guard response != .alertThirdButtonReturn, let self else { return }
            guard response == .alertFirstButtonReturn else {
                Settings.forget(dir.path)
                return self.reload()
            }
            self.perform(tr("Updating sessions…"), {
                let closed = try AppControl.quitAll([dir])
                do {
                    // Sessions may have been moved while the dialog was open.
                    let orphaned = Transcripts.orphaned(by: dir.sessionsRoot, among: dirs)
                    if FileManager.default.fileExists(atPath: dir.path) {
                        try FileManager.default.trashItem(at: URL(fileURLWithPath: dir.path), resultingItemURL: nil)
                    }
                    Transcripts.trash(orphaned)
                } catch {
                    AppControl.reopen(closed)
                    throw error
                }
                DispatchQueue.main.async { Settings.forget(dir.path) }
                return Outcome()
            }) { result in
                if case .failure(let error) = result {
                    Dialog.inform(tr("Could not remove the profile"), error.localizedDescription, style: .warning)
                }
            }
        }
    }

    func renameProfile(_ dir: DataDir) {
        panel.close()
        askName(tr("Name this profile"),
                tr("A profile is one Claude app with its own data folder. The name is only shown in Porter. Leave it empty to use the default name."),
                current: Settings.profileNames[dir.path], placeholder: tr("e.g. Work")) { [weak self] name in
            Settings.profileNames[dir.path] = name.isEmpty ? nil : name
            self?.reload()
        }
    }

    /// Calls `save` with the new name ("" clears it); nothing happens if cancelled.
    private func askName(_ title: String, _ info: String, current: String?, placeholder: String,
                         save: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = info
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = current ?? ""
        field.placeholderString = placeholder
        alert.accessoryView = field
        alert.addButton(withTitle: tr("Save"))
        alert.addButton(withTitle: tr("Cancel"))
        Dialog.show(alert, focus: field) { response in
            if response == .alertFirstButtonReturn { save(field.stringValue.trimmingCharacters(in: .whitespaces)) }
        }
    }

    func openApp(_ dir: DataDir) {
        panel.close()
        AppControl.activate(dir)
    }

    func showBackups() {
        panel.close()
        try? FileManager.default.createDirectory(atPath: Paths.backups, withIntermediateDirectories: true)
        NSWorkspace.shared.open(URL(fileURLWithPath: Paths.backups))
    }

    /// The option only matters with several profiles; it stays visible while on, so it can be turned off.
    var showsRouteLinks: Bool { multipleProfiles || routeLinks }

    func toggleRouteLinks() {
        panel.close()
        let on = !LinkRouter.isEnabled
        let apply = { [weak self] in
            LinkRouter.setEnabled(on) { error in
                if let error {
                    Dialog.inform(tr("Could not change the app for Claude links"), error.localizedDescription, style: .warning)
                }
                self?.routeLinks = LinkRouter.isEnabled
            }
        }
        guard on else { return apply() }
        let alert = NSAlert()
        alert.messageText = tr("Open links in the right profile?")
        alert.informativeText = tr("All your profiles are the same Claude app, so when the browser sends you back to Claude (after signing in, for example), macOS picks one of the open profiles, not necessarily the one you came from.\n\nWith this on, Porter receives Claude links and passes each one to the profile you used last. The first time, macOS may ask to let Porter control Claude: that is how the link is passed on. Keep Porter running (Launch at Login), so it knows which profile you used last.")
        alert.addButton(withTitle: tr("Turn On"))
        alert.addButton(withTitle: tr("Cancel"))
        Dialog.show(alert) { if $0 == .alertFirstButtonReturn { apply() } }
    }

    func toggleChecksForUpdates() {
        Updater.shared.checksAutomatically.toggle()
        checksForUpdates = Updater.shared.checksAutomatically
    }

    func checkForUpdates() {
        panel.close()
        Updater.shared.checkForUpdates()
    }

    func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            panel.close()
            Dialog.inform(tr("Could not change the login item"), error.localizedDescription, style: .warning)
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func quit() { NSApp.terminate(nil) }
}
