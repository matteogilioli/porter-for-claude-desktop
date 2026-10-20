import AppKit

/// What a move would do, computed before touching anything.
struct MovePlan {
    let source: Store
    let target: Store
    /// Sessions the target does not have yet.
    let new: [SessionInfo]
    /// Sessions the target has, but older than the source copy, or archived there while open in the source.
    let updated: [SessionInfo]
    /// Sessions the target already has, as recent as the source copy.
    let upToDate: [SessionInfo]

    var all: [SessionInfo] { new + updated + upToDate }
    var sameDataDir: Bool { source.dataDir == target.dataDir }
}

struct MoveOptions {
    enum Mode {
        /// The sessions end up in the target only: archived in the source, whose app is closed
        /// and reopened if it is running (it would undo the change otherwise).
        case move
        /// The sessions stay where they are and the target gets copies with conversations of their
        /// own, so writing in one never shows up in the other.
        case copy
    }
    var mode: Mode
    /// Quit the target app before writing and reopen it afterwards, so it loads the sessions
    /// (or open it afterwards, if it is closed).
    var restartTarget: Bool
}

/// Which Claude apps a move closes and reopens. The move sheet, `--dry-run` and the move itself
/// all read it, so what the user is told is what happens.
struct MoveEffects {
    /// The source app is running and would undo the archiving: it is closed and reopened.
    let closesSource: Bool
    /// The target app is running and is closed and reopened, so it loads the sessions.
    let restartsTarget: Bool
    /// Moving within one data folder archives in the app being restarted: it must be restarted.
    let restartForced: Bool
    /// The target app is closed and is opened afterwards.
    let opensTarget: Bool
    /// The target app keeps running: sessions it would overwrite are skipped.
    let targetStaysOpen: Bool

    init(_ plan: MovePlan, _ options: MoveOptions, running: Set<String>) {
        let sourceRunning = running.contains(plan.source.dataDir.path)
        let targetRunning = running.contains(plan.target.dataDir.path)
        restartForced = options.mode == .move && plan.sameDataDir && targetRunning
        restartsTarget = targetRunning && (options.restartTarget || restartForced)
        closesSource = options.mode == .move && !plan.sameDataDir && sourceRunning
        opensTarget = !targetRunning && options.restartTarget
        targetStaysOpen = targetRunning && !restartsTarget
    }

    /// The apps that are closed while the files change.
    func closing(_ plan: MovePlan) -> [DataDir] {
        (closesSource ? [plan.source.dataDir] : []) + (restartsTarget ? [plan.target.dataDir] : [])
    }
}

enum MoveError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let m) = self { return m }; return nil }
}

/// What an operation did, and the Claude apps to bring back once it is done. The caller reopens
/// them (`AppControl.finish`), so the menu-bar app can report first and stay busy until they are up.
struct Outcome {
    var report: [String] = []
    /// Apps closed for the change, reopened afterwards.
    var reopen: [DataDir] = []
    /// Apps that were closed and are opened afterwards, on request.
    var open: [DataDir] = []

    var text: String { report.joined(separator: "\n") }
}

enum Mover {
    /// Fields the app uses to show a session as failed (e.g. "You've hit your limit").
    static let errorKeys = ["error", "errorAt", "errorRows", "priorErrorMark"]
    /// Links to the source account's Remote Control sessions on claude.ai. The target app opens
    /// sessions of its own when Remote Control is on, so these only point at another account.
    static let remoteControlKeys = ["bridgeSessionId", "bridgeSessionIds", "bridgeSessionUrl", "steeredByRemoteClient", "remoteControlSpawn"]

    static func plan(_ sessions: [SessionInfo], from source: Store, to target: Store) -> MovePlan {
        let archived = Discovery.archivedIds(in: target.path)
        var new: [SessionInfo] = [], updated: [SessionInfo] = [], upToDate: [SessionInfo] = []
        for s in sessions {
            guard let existing = Discovery.header(at: sessionFile(target, s.id)) else {
                new.append(s)
                continue
            }
            let mine = Discovery.header(at: sessionFile(source, s.id))?.lastActivityAt ?? 0
            let theirs = existing.lastActivityAt ?? 0
            // An open session archived in the target is revived. A copy that is not newer never
            // replaces the target's: that is where the session went on after an earlier move.
            let targetArchived = existing.isArchived == true || archived.contains(s.id)
            if mine > theirs || (mine == theirs && targetArchived && !s.isArchived) {
                updated.append(s)
            } else {
                upToDate.append(s)
            }
        }
        return MovePlan(source: source, target: target, new: new, updated: updated, upToDate: upToDate)
    }

    /// Runs the whole move. Blocking: call it off the main thread. `progress` hears each step as it starts.
    static func execute(_ plan: MovePlan, options: MoveOptions, progress: (String) -> Void = { _ in }) throws -> Outcome {
        let copy = options.mode == .copy
        let effects = MoveEffects(plan, options, running: Set(Discovery.runningInstances().map(\.dataDir)))
        var outcome = Outcome()
        // Copies get new ids, so the target never has them yet.
        var sessions = copy ? plan.all : plan.new + plan.updated
        var skipped = 0
        if effects.targetStaysOpen {
            // A running app rewrites the files it knows, its archive list and its worktree list: only new,
            // open sessions without a worktree are safe to add under it.
            let leased = copy || plan.sameDataDir ? [] : worktreeLeases(in: plan.source.dataDir)
            if !copy { skipped += plan.updated.count; sessions = plan.new }
            let safe = sessions.filter { !$0.isArchived && !leased.contains($0.id) }
            skipped += sessions.count - safe.count
            sessions = safe
        }

        outcome.reopen = try AppControl.quitAll(effects.closing(plan), progress: progress)
        // The apps may rewrite their files while quitting, so the backup and the writes come after.
        progress(tr("Copying sessions…"))
        let backup: Backup
        do {
            backup = try Backup("\(copy ? "Copy" : "Move") \(sessions.count) session(s)\nfrom: \(plan.source.path)\nto: \(plan.target.path)")
        } catch {
            AppControl.reopen(outcome.reopen)
            throw error
        }
        do {
            try write(plan, sessions: sessions, copy: copy, worktrees: !effects.targetStaysOpen, backup: backup, report: &outcome.report)
            try backup.finish()
        } catch {
            // Never leave a half-done move, or the user's apps closed, because something failed.
            backup.restore()
            AppControl.reopen(outcome.reopen)
            throw error
        }
        outcome.report.insert(tr("Backup: %@", backup.path), at: 0)
        if skipped > 0 {
            outcome.report.append(tr("Skipped %ld session(s) that %@ would overwrite while it is open: turn on the restart to move them.",
                                     skipped, plan.target.dataDir.label))
        }
        if effects.targetStaysOpen && !sessions.isEmpty {
            outcome.report.append(tr("Restart %@ to see the new sessions.", plan.target.dataDir.label))
        }
        for app in outcome.reopen { outcome.report.append(tr("Reopening %@.", app.label)) }
        if effects.opensTarget {
            outcome.open = [plan.target.dataDir]
            outcome.report.append(tr("Opened %@.", plan.target.dataDir.label))
        }
        if !plan.target.isSignedIn {
            outcome.report.append(tr("Note: %@ is not the account currently signed in to %@. The sessions will show up once you sign in to it.",
                                     Discovery.accountName(plan.target.accountUuid), plan.target.dataDir.label))
        }
        log(outcome.text)
        return outcome
    }

    // MARK: - Writing

    private static func write(_ plan: MovePlan, sessions: [SessionInfo], copy: Bool, worktrees: Bool, backup: Backup,
                              report: inout [String]) throws {
        var ids: [String] = [], archivedIds: Set<String> = []
        for session in sessions {
            try autoreleasepool {
                guard var d = readJSON(sessionFile(plan.source, session.id)) as? [String: Any] else {
                    throw MoveError.message(tr("Cannot read session %@ in the source.", session.id))
                }
                errorKeys.forEach { d.removeValue(forKey: $0) }
                remoteControlKeys.forEach { d.removeValue(forKey: $0) }
                var id = session.id
                if copy {
                    // A copy sharing a conversation file would write into the same history as the original.
                    id = "local_" + UUID().uuidString.lowercased()
                    d["sessionId"] = id
                    let cwd = session.runCwd ?? session.cwd
                    if let cli = d["cliSessionId"] as? String {
                        if let forked = try Transcripts.fork(cli, cwd: cwd) {
                            d["cliSessionId"] = forked.id
                            forked.files.forEach(backup.created)
                        } else {
                            // No transcript left: a conversation id of its own all the same.
                            d["cliSessionId"] = UUID().uuidString.lowercased()
                        }
                    }
                    if let prior = d["priorCliSessionIds"] as? [String] {
                        d["priorCliSessionIds"] = try prior.compactMap { old -> String? in
                            guard let forked = try Transcripts.fork(old, cwd: cwd) else { return nil }
                            forked.files.forEach(backup.created)
                            return forked.id
                        }
                    }
                }
                d["isArchived"] = session.isArchived
                let file = sessionFile(plan.target, id)
                try backup.save(file)
                try writeJSON(d, to: file)
                ids.append(id)
                if session.isArchived { archivedIds.insert(id) }
            }
        }
        try updateArchiveIndex(plan.target, backup: backup) { $0.subtracting(ids).union(archivedIds) }
        report.append(tr(copy ? "Copied %ld session(s) to %@, each with a conversation of its own." : "Copied %ld session(s) to %@.",
                         ids.count, Discovery.displayName(plan.target, includeFolder: true)))

        // A worktree is leased by one session: copies leave it to the original.
        if worktrees && !copy && !plan.sameDataDir {
            let names = try mergeWorktrees(from: plan.source.dataDir, to: plan.target.dataDir,
                                           sessionIds: Set(sessions.map(\.id) + plan.upToDate.map(\.id)), backup: backup)
            if !names.isEmpty { report.append(tr("Registered worktrees: %@.", names.joined(separator: ", "))) }
        }

        if !copy {
            // What the target now has: skipped sessions stay usable in the source.
            let moved = sessions.map(\.id) + plan.upToDate.map(\.id)
            try setArchived(moved, true, in: plan.source, backup: backup)
            report.append(tr("Archived %ld session(s) in the source.", moved.count))
        }
    }

    /// Sessions that lease a worktree in this data folder.
    private static func worktreeLeases(in dir: DataDir) -> Set<String> {
        let worktrees = (readJSON(dir.path + "/git-worktrees.json") as? [String: Any])?["worktrees"] as? [String: Any] ?? [:]
        return Set(worktrees.values.compactMap { ($0 as? [String: Any])?["leasedBy"] as? String })
    }

    /// Worktrees are registered per data folder and leased by a session id.
    private static func mergeWorktrees(from source: DataDir, to target: DataDir, sessionIds: Set<String>, backup: Backup) throws -> [String] {
        guard let src = readJSON(source.path + "/git-worktrees.json") as? [String: Any] else { return [] }
        let targetPath = target.path + "/git-worktrees.json"
        var dst = readJSON(targetPath) as? [String: Any] ?? ["schemaVersion": src["schemaVersion"] ?? 2]
        var worktrees = dst["worktrees"] as? [String: Any] ?? [:]
        var names: [String] = []
        for (name, value) in src["worktrees"] as? [String: Any] ?? [:] {
            guard let w = value as? [String: Any], let lease = w["leasedBy"] as? String, sessionIds.contains(lease) else { continue }
            worktrees[name] = w
            names.append(name)
        }
        guard !names.isEmpty else { return [] }
        dst["worktrees"] = worktrees
        for key in ["originUrls", "originPins"] {
            let merged = (dst[key] as? [String: Any] ?? [:]).merging(src[key] as? [String: Any] ?? [:]) { _, new in new }
            dst[key] = merged
        }
        try backup.save(targetPath)
        try writeJSON(dst, to: targetPath, pretty: true)
        return names.sorted()
    }

    // MARK: - Session lists

    static func sessionFile(_ store: Store, _ id: String) -> String { "\(store.path)/\(id).json" }

    /// Archives or restores sessions the way Claude Desktop does: the flag in each file and the store's index.
    static func setArchived(_ ids: [String], _ archived: Bool, in store: Store, backup: Backup) throws {
        for id in ids {
            try autoreleasepool {
                let file = sessionFile(store, id)
                guard FileManager.default.fileExists(atPath: file) else { return }
                guard var d = readJSON(file) as? [String: Any] else { throw MoveError.message(tr("Cannot read %@.", file)) }
                guard d["isArchived"] as? Bool != archived else { return }
                d["isArchived"] = archived
                try backup.save(file)
                try writeJSON(d, to: file)
            }
        }
        try updateArchiveIndex(store, backup: backup) { archived ? $0.union(ids) : $0.subtracting(ids) }
    }

    static func updateArchiveIndex(_ store: Store, backup: Backup, _ change: (Set<String>) -> Set<String>) throws {
        let path = store.path + "/archived-sessions.idx"
        var idx = readJSON(path) as? [String: Any] ?? ["v": 1]
        let before = Set(idx["archived"] as? [String] ?? [])
        let after = change(before)
        guard after != before else { return }
        idx["archived"] = after.sorted()
        try backup.save(path)
        try writeJSON(idx, to: path)
    }

    private static func log(_ text: String) {
        let path = Paths.ownDir + "/mover.log"
        let line = "[\(ISO8601DateFormatter().string(from: Date()))]\n\(text)\n\n"
        try? FileManager.default.createDirectory(atPath: Paths.ownDir, withIntermediateDirectories: true)
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            handle.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}

/// A copy of every file a change touches, taken just before it is written, under its full path, plus
/// the list of files the change created. `restore()` puts everything back when the change fails; the
/// README tells the user how to do the same by hand.
final class Backup {
    let path: String
    private let title: String
    private var saved: [String] = []
    private var created: [String] = []
    private let fm = FileManager.default

    init(_ title: String) throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss.SSS"
        let base = "\(Paths.backups)/\(formatter.string(from: Date()))"
        var path = base, n = 2
        while FileManager.default.fileExists(atPath: path) { path = "\(base)-\(n)"; n += 1 }
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        self.path = path
        self.title = title
        try finish()
    }

    /// Keeps a copy of `file` before it changes (once). A file that does not exist yet is recorded as created.
    func save(_ file: String) throws {
        guard !saved.contains(file), !created.contains(file) else { return }
        guard fm.fileExists(atPath: file) else { created.append(file); return }
        let dest = path + file
        try fm.createDirectory(atPath: (dest as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try fm.copyItem(atPath: file, toPath: dest)
        saved.append(file)
    }

    /// Records a file or folder the change made.
    func created(_ file: String) { if !created.contains(file) { created.append(file) } }

    /// Writes the README: what changed and how to undo it.
    func finish() throws {
        var text = "\(title)\n\nTo undo it, quit Claude Desktop, then copy each saved file back to the path it is saved under"
            + " (this folder stands for /)"
        text += created.isEmpty ? ".\n" : " and delete the files this change created:\n" + created.map { "  \($0)\n" }.joined()
        try text.write(toFile: path + "/README.txt", atomically: true, encoding: .utf8)
    }

    /// Undoes what was written so far.
    func restore() {
        for file in created { try? fm.removeItem(atPath: file) }
        for file in saved {
            try? fm.removeItem(atPath: file)
            try? fm.copyItem(atPath: path + file, toPath: file)
        }
        try? (title + "\n\nThis change failed and was undone.\n").write(toFile: path + "/README.txt", atomically: true, encoding: .utf8)
    }
}

enum SessionAction { case archive, unarchive, delete }

/// Archiving, restoring and deleting sessions of one account, with the same care as a move:
/// the account's Claude app closed while its files change, and a backup first.
enum SessionActions {
    /// Blocking: call it off the main thread.
    static func apply(_ action: SessionAction, to sessions: [SessionInfo], in store: Store,
                      among dirs: [DataDir]) throws -> Outcome {
        var outcome = Outcome()
        outcome.reopen = try AppControl.quitAll([store.dataDir])
        let ids = sessions.map(\.id)
        var backup: Backup?
        do {
            let title: String
            switch action {
            case .archive: title = "Archive \(ids.count) session(s) in \(store.path)"
            case .unarchive: title = "Restore \(ids.count) session(s) in \(store.path)"
            case .delete: title = "Delete \(ids.count) session(s) in \(store.path) (they are in the Trash)"
            }
            let b = try Backup(title)
            backup = b
            outcome.report.append(tr("Backup: %@", b.path))
            switch action {
            case .archive, .unarchive:
                let archived = action == .archive
                try Mover.setArchived(ids, archived, in: store, backup: b)
                outcome.report.append(archived ? tr("Archived %ld session(s).", ids.count) : tr("Restored %ld session(s).", ids.count))
            case .delete:
                let files = Set(ids.map { Mover.sessionFile(store, $0) })
                let orphaned = Transcripts.orphaned(among: dirs) { files.contains($0) }
                try Mover.updateArchiveIndex(store, backup: b) { $0.subtracting(ids) }
                // Last, as it cannot be undone from here (the files are in the Trash).
                for file in files where FileManager.default.fileExists(atPath: file) {
                    try FileManager.default.trashItem(at: URL(fileURLWithPath: file), resultingItemURL: nil)
                }
                outcome.report.append(tr("Moved %ld session(s) to the Trash.", files.count))
                let conversations = Transcripts.trash(orphaned)
                if conversations > 0 { outcome.report.append(tr("%ld conversation(s) no other account lists went to the Trash too.", conversations)) }
            }
        } catch {
            backup?.restore()
            AppControl.reopen(outcome.reopen)
            throw error
        }
        for app in outcome.reopen { outcome.report.append(tr("Reopening %@.", app.label)) }
        return outcome
    }
}

/// One operation that changes Claude's files at a time, across the menu-bar app and the command line.
enum OperationLock {
    static func run<T>(_ work: () throws -> T) throws -> T {
        try? FileManager.default.createDirectory(atPath: Paths.ownDir, withIntermediateDirectories: true)
        let fd = open(Paths.ownDir + "/operation.lock", O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else { return try work() }
        defer { close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else {
            throw MoveError.message(tr("Porter is already changing sessions: try again when it is done."))
        }
        defer { flock(fd, LOCK_UN) }
        return try work()
    }
}

/// Quitting and launching the Claude desktop app for a given data folder.
enum AppControl {
    /// Quits the apps of `dirs` that are running and returns them. If one does not quit, the ones
    /// already closed are reopened and nothing else happens.
    static func quitAll(_ dirs: [DataDir], progress: (String) -> Void = { _ in }) throws -> [DataDir] {
        var closed: [DataDir] = []
        for dir in dirs where !Discovery.instances(for: dir).isEmpty {
            progress(tr("Closing %@…", dir.label))
            guard quit(dir) else {
                reopen(closed)
                throw MoveError.message(tr("%@ did not quit within 30 seconds (maybe it asked for confirmation). Nothing was changed: quit it yourself and try again.", dir.label))
            }
            closed.append(dir)
        }
        return closed
    }

    static func quit(_ dir: DataDir, timeout: TimeInterval = 30) -> Bool {
        let instances = Discovery.instances(for: dir)
        instances.forEach { $0.app.terminate() }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !instances.contains(where: { Discovery.isAlive($0.app.processIdentifier) }) {
                // Its helper processes finish writing a moment later.
                Thread.sleep(forTimeInterval: 1.5)
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// Reopens apps closed for a change. Some launchers reopen the app by themselves; opening it too
    /// would start a second instance on the same data folder, which can corrupt it.
    static func reopen(_ dirs: [DataDir]) {
        for dir in dirs where !waitForRelaunch(dir, seconds: 3) { launch(dir) }
    }

    /// Brings back what an operation closed, and opens what it was asked to open. Blocking.
    static func finish(_ outcome: Outcome) {
        reopen(outcome.reopen)
        outcome.open.forEach(launch)
    }

    private static func waitForRelaunch(_ dir: DataDir, seconds: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if !Discovery.instances(for: dir).isEmpty { return true }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    static func launch(_ dir: DataDir) {
        guard Discovery.instances(for: dir).isEmpty,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Discovery.claudeBundleId) else { return }
        let config = NSWorkspace.OpenConfiguration()
        // Without a new instance, macOS would just focus whichever Claude window is already open.
        config.createsNewApplicationInstance = true
        if !dir.isDefault { config.arguments = ["--user-data-dir=\(dir.path)"] }
        let done = DispatchSemaphore(value: 0)
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in done.signal() }
        _ = done.wait(timeout: .now() + 10)
    }

    static func activate(_ dir: DataDir) {
        if let instance = Discovery.instances(for: dir).first {
            instance.app.activate()
        } else {
            DispatchQueue.global().async { launch(dir) }
        }
    }
}
