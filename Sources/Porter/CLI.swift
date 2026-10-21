import Foundation

/// Command-line mode, for scripting and debugging. Without any of these flags the menu-bar app starts.
///
///     Porter --list [--data-dir PATH ...]
///     Porter --usage-json            (claude.ai's usage answer for each profile; needs Live Usage)
///     Porter --move --from STORE_PATH --to STORE_PATH [--session ID ...]
///                        [--copy] [--restart] [--dry-run] [--include-archived] [--data-dir PATH ...]
///
/// --move archives the sessions in the source; --copy leaves them there and gives each copy a
/// conversation of its own. A Claude app that has to close for that (a running source, or the app of
/// a move within one data folder) is only closed and reopened with --restart, which also restarts or
/// opens the target app so it loads the sessions. --dry-run says what would happen.
/// STORE_PATH is a path printed by --list (`<dataDir>/claude-code-sessions/<account>/<org>`).
enum CLI {
    static func runIfRequested(_ args: [String]) -> Int32? {
        if let i = args.firstIndex(of: "--write-iconset"), i + 1 < args.count {
            // Used by scripts/build-app.sh to produce AppIcon.icns from the code-drawn artwork.
            do { try Icon.writeIconset(to: args[i + 1]); return 0 } catch {
                fputs("\(error.localizedDescription)\n", stderr)
                return 1
            }
        }
        if args.contains("--usage-json") {
            // What claude.ai answers for each profile, to see which limits it reports (needs Live Usage).
            for dir in Discovery.dataDirs(running: []) {
                print("== \(dir.label)")
                print(LiveUsage.sample(in: dir)?.response.flatMap { String(data: $0, encoding: .utf8) } ?? "no answer")
            }
            return 0
        }
        guard args.contains("--list") || args.contains("--move") else { return nil }
        Discovery.extraDataDirs = values("--data-dir", args).map(Paths.normalize)
        return args.contains("--move") ? move(args) : list()
    }

    static func list() -> Int32 {
        let snapshot = Snapshot.load()
        for store in snapshot.stores {
            let running = snapshot.running.contains(store.dataDir.path) ? "running" : "closed"
            print("\(store.dataDir.label) [\(running)] · \(Discovery.displayName(store, includeFolder: false))"
                  + (store.isSignedIn ? " (signed in)" : "")
                  + " · \(store.open.count) open, \(store.archived.count) archived, \(store.stopped.count) stopped by limit"
                  + (store.usage.map { usage in
                      " · " + usage.windows.map { w in
                          "\(w.label) \(w.percent)%" + (w.resetsAt.map { " (resets \($0.formatted(date: .abbreviated, time: .shortened)))" } ?? "")
                      }.joined(separator: " ") + " as of \(usage.sampledAt.formatted(date: .omitted, time: .shortened))"
                  } ?? ""))
            print("    \(store.path)")
        }
        return 0
    }

    static func move(_ args: [String]) -> Int32 {
        let snapshot = Snapshot.load()
        func store(_ flag: String) -> Store? {
            guard let path = values(flag, args).first.map(Paths.normalize) else { return nil }
            return snapshot.stores.first { Paths.normalize($0.path) == path }
        }
        guard let source = store("--from"), let target = store("--to") else {
            fputs("--from and --to must be store paths printed by --list\n", stderr)
            return 2
        }
        guard source.key != target.key else {
            fputs("--from and --to are the same store\n", stderr)
            return 2
        }
        let ids = Set(values("--session", args))
        // Open sessions only, unless --include-archived (or explicit --session ids) asks for archived ones too.
        let pool = args.contains("--include-archived") || !ids.isEmpty ? source.sessions : source.open
        let sessions = ids.isEmpty ? pool : pool.filter { ids.contains($0.id) }
        let plan = Mover.plan(sessions, from: source, to: target)
        let options = MoveOptions(mode: args.contains("--copy") ? .copy : .move, restartTarget: args.contains("--restart"))
        let effects = MoveEffects(plan, options, running: snapshot.running)
        print("\(plan.new.count) new, \(plan.updated.count) to update, \(plan.upToDate.count) up to date")
        plan.new.forEach { print("  + \($0.title)") }
        plan.updated.forEach { print("  ~ \($0.title)") }
        for dir in effects.closing(plan) { print("Closes and reopens \(dir.label).") }
        if effects.opensTarget { print("Opens \(target.dataDir.label) afterwards.") }
        if effects.targetStaysOpen { print("\(target.dataDir.label) stays open: sessions it would overwrite are skipped.") }
        if args.contains("--dry-run") { return 0 }
        if !options.restartTarget, let dir = effects.closing(plan).first {
            fputs("\(dir.label) is running and has to close for this. Quit it first, or pass --restart to let Porter close and reopen it.\n", stderr)
            return 2
        }
        do {
            let outcome = try OperationLock.run { try Mover.execute(plan, options: options) }
            print(outcome.text)
            AppControl.finish(outcome)
            return 0
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            return 1
        }
    }

    private static func values(_ flag: String, _ args: [String]) -> [String] {
        args.indices.compactMap { i in args[i] == flag && i + 1 < args.count ? args[i + 1] : nil }
    }
}
