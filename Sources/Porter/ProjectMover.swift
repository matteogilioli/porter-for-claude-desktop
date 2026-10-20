import Foundation

/// Moves a project folder, or points its sessions at a folder that was already moved, without
/// losing them: Claude Desktop stores the absolute path in each session, in its worktree list and
/// in its config, and Claude Code files conversations under a folder named after the path.
enum ProjectMover {
    /// Whether `path` is `folder` or inside it.
    static func isInside(_ path: String, _ folder: String) -> Bool {
        path == folder || path.hasPrefix(folder + "/")
    }

    /// Sessions of every account whose working folder is the project or inside it (its worktrees).
    static func sessions(of folder: String, in stores: [Store]) -> [(store: Store, session: SessionInfo)] {
        stores.flatMap { store in
            store.sessions.filter { $0.cwd.map { isInside($0, folder) } ?? false }.map { (store, $0) }
        }
    }

    /// Blocking: call it off the main thread. `moveFolder` moves the folder on disk; without it the
    /// folder must already be at `new`. `expected` is how many sessions use the project. Everything is
    /// undone if a step fails.
    static func relocate(from old: String, to new: String, moveFolder: Bool, expected: Int, dirs: [DataDir]) throws -> Outcome {
        let fm = FileManager.default
        // Sessions keep the path as Claude saw it, which may go through a symlink (or keep /private):
        // match it as given, normalized and fully resolved.
        let recorded = old.count > 1 && old.hasSuffix("/") ? String(old.dropLast()) : old
        // The new path as chosen: resolving it would drop a /private Claude keeps.
        let real = Paths.normalize(old), new = URL(fileURLWithPath: new).standardizedFileURL.path
        let resolved = realpath(recorded, nil).map { p in defer { free(p) }; return String(cString: p) }
        let olds = Array(Set([recorded, real] + (resolved.map { [$0] } ?? [])))
        guard !olds.contains(new), !olds.contains(where: { isInside(new, $0) }) else {
            throw MoveError.message(tr("Choose a folder outside the project."))
        }
        if moveFolder {
            guard !fm.fileExists(atPath: new) else { throw MoveError.message(tr("%@ already exists.", new)) }
        } else {
            guard fm.fileExists(atPath: new) else { throw MoveError.message(tr("%@ does not exist.", new)) }
        }

        // Running Claude apps keep sessions in memory and would write the old paths back.
        var outcome = Outcome()
        outcome.reopen = try AppControl.quitAll(dirs)
        let backup: Backup
        do {
            backup = try Backup("Project \(recorded) → \(new)")
        } catch {
            AppControl.reopen(outcome.reopen)
            throw error
        }
        var moves: [(from: String, to: String)] = []
        do {
            outcome.report.append(tr("Backup: %@", backup.path))
            if moveFolder {
                try fm.createDirectory(atPath: (new as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
                try fm.moveItem(atPath: real, toPath: new)
                moves.append((real, new))
                outcome.report.append(tr("Moved the folder to %@.", (new as NSString).abbreviatingWithTildeInPath))
            }
            let (sessions, others, cwds) = try rewriteFiles(olds, new, dirs: dirs, backup: backup)
            guard sessions > 0 || expected == 0 else {
                throw MoveError.message(tr("No session could be updated, so nothing was changed."))
            }
            outcome.report.append(tr("Updated %ld session(s).", sessions))
            if others > 0 { outcome.report.append(tr("Updated %ld Claude Desktop file(s) (worktrees, settings).", others)) }

            let conversations = try moveConversations(cwds, olds, new, moves: &moves)
            if conversations > 0 { outcome.report.append(tr("Moved %ld conversation(s) in ~/.claude/projects.", conversations)) }
            try backup.finish()
        } catch {
            for move in moves.reversed() { try? fm.moveItem(atPath: move.to, toPath: move.from) }
            backup.restore()
            AppControl.reopen(outcome.reopen)
            throw error
        }
        if repairWorktrees(of: new, olds) { outcome.report.append(tr("Repaired the project's git worktrees.")) }
        if !outcome.reopen.isEmpty { outcome.report.append(tr("Reopening %@.", outcome.reopen.map(\.label).joined(separator: ", "))) }
        return outcome
    }

    /// Rewrites every Claude Desktop file that can hold the path: sessions, worktrees, config, presets.
    /// Returns how many session and other files changed, and the folders the project's sessions ran in.
    private static func rewriteFiles(_ olds: [String], _ new: String, dirs: [DataDir], backup: Backup) throws
        -> (sessions: Int, others: Int, cwds: Set<String>) {
        var files: [(path: String, isSession: Bool)] = []
        for dir in dirs {
            for name in ["git-worktrees.json", "claude_desktop_config.json", "ccd-session-presets.json"] {
                files.append((dir.path + "/" + name, false))
            }
            files += Discovery.sessionFiles(under: dir.sessionsRoot).map { ($0, true) }
        }
        // Cheap check before parsing, on the raw bytes: most files never mention the project.
        let needles = olds.flatMap { [Data($0.utf8), Data($0.replacingOccurrences(of: "/", with: "\\/").utf8)] }
        var sessions = 0, others = 0
        var cwds: Set<String> = []
        for file in files {
            try autoreleasepool {
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: file.path), options: .alwaysMapped),
                      needles.contains(where: { data.range(of: $0) != nil }) else { return }
                guard let json = try? JSONSerialization.jsonObject(with: data) else {
                    throw MoveError.message(tr("Cannot read %@.", file.path))
                }
                var changed = false
                let rewritten = rewrite(json, olds, new, &changed)
                guard changed else { return }
                if file.isSession, let d = json as? [String: Any] {
                    for key in ["cwd", "originCwd"] {
                        if let cwd = d[key] as? String, olds.contains(where: { isInside(cwd, $0) }) { cwds.insert(cwd) }
                    }
                }
                try backup.save(file.path)
                try writeJSON(rewritten, to: file.path, pretty: !file.isSession)
                if file.isSession { sessions += 1 } else { others += 1 }
            }
        }
        for old in olds { cwds.insert(old) }
        return (sessions, others, cwds)
    }

    /// Conversations: `~/.claude/projects/<folder named after the path>`, for the project and each worktree.
    private static func moveConversations(_ cwds: Set<String>, _ olds: [String], _ new: String,
                                          moves: inout [(from: String, to: String)]) throws -> Int {
        let fm = FileManager.default
        var count = 0
        for cwd in cwds {
            guard let old = olds.first(where: { isInside(cwd, $0) }) else { continue }
            let from = Transcripts.projects + "/" + Transcripts.folderName(cwd)
            let to = Transcripts.projects + "/" + Transcripts.folderName(new + cwd.dropFirst(old.count))
            guard from != to, let items = try? fm.contentsOfDirectory(atPath: from) else { continue }
            try fm.createDirectory(atPath: to, withIntermediateDirectories: true)
            for item in items where !fm.fileExists(atPath: to + "/" + item) {
                try fm.moveItem(atPath: from + "/" + item, toPath: to + "/" + item)
                moves.append((from + "/" + item, to + "/" + item))
                if item.hasSuffix(".jsonl") { count += 1 }
            }
            if (try? fm.contentsOfDirectory(atPath: from))?.isEmpty == true { try? fm.removeItem(atPath: from) }
        }
        return count
    }

    /// Git keeps absolute paths between a repository and its worktrees, in both directions. Repairing
    /// needs the path of each worktree that moved; the repository lists where they were.
    private static func repairWorktrees(of new: String, _ olds: [String]) -> Bool {
        let fm = FileManager.default
        let admin = new + "/.git/worktrees"
        guard let names = try? fm.contentsOfDirectory(atPath: admin) else { return false }
        let paths = names.compactMap { name -> String? in
            guard let gitdir = try? String(contentsOfFile: "\(admin)/\(name)/gitdir", encoding: .utf8) else { return nil }
            var path = (gitdir.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).deletingLastPathComponent
            if let old = olds.first(where: { isInside(path, $0) }) { path = new + path.dropFirst(old.count) }
            return fm.fileExists(atPath: path) ? path : nil
        }
        guard !paths.isEmpty else { return false }
        let git = Process()
        git.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        git.arguments = ["-C", new, "worktree", "repair"] + paths
        git.standardOutput = FileHandle.nullDevice
        git.standardError = FileHandle.nullDevice
        guard (try? git.run()) != nil else { return false }
        git.waitUntilExit()
        return git.terminationStatus == 0
    }

    /// The new value of a string that starts with the project path (as a path, or as the
    /// `<path>\0<branch>` keys Claude Desktop uses for branches), or nil.
    private static func replaced(_ s: String, _ olds: [String], _ new: String) -> String? {
        for old in olds where s == old || s.hasPrefix(old + "/") || s.hasPrefix(old + "\u{0}") {
            return new + s.dropFirst(old.count)
        }
        return nil
    }

    /// Replaces the project path at the start of every string value and key.
    private static func rewrite(_ value: Any, _ olds: [String], _ new: String, _ changed: inout Bool) -> Any {
        switch value {
        case let s as String:
            guard let r = replaced(s, olds, new) else { return s }
            changed = true
            return r
        case let d as [String: Any]:
            var out: [String: Any] = [:]
            // Keys can be paths too (worktree and project maps). One already under the new path wins.
            for (k, v) in d where replaced(k, olds, new) == nil { out[k] = rewrite(v, olds, new, &changed) }
            for (k, v) in d {
                guard let key = replaced(k, olds, new) else { continue }
                changed = true
                if out[key] == nil { out[key] = rewrite(v, olds, new, &changed) }
            }
            return out
        case let a as [Any]:
            return a.map { rewrite($0, olds, new, &changed) }
        default:
            return value
        }
    }
}
