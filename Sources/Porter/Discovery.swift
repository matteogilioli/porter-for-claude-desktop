import AppKit

/// A Claude desktop data folder (the app's `--user-data-dir`).
struct DataDir: Hashable {
    let path: String
    let label: String
    var isDefault: Bool { path == Paths.defaultDataDir }
    /// Where Claude Desktop keeps its session lists: `<account>/<organization>/local_*.json`.
    var sessionsRoot: String { path + "/claude-code-sessions" }
}

struct Usage {
    let fiveHour: Int?
    let sevenDay: Int?
    let sampledAt: Date
    /// Every limit claude.ai reports (the session, the week, the week of one model…), with when it
    /// resets. Empty for usage read from Claude Desktop's file, which only has the first two.
    var limits: [Limit] = []
    /// claude.ai says the account has no seat (license) in the organization: no limits, and no use of Claude.
    var noSeat = false

    struct Limit: Hashable {
        let label: String
        let percent: Int
        let resetsAt: Date?
    }

    /// What to draw: the limits claude.ai reported, or the two windows of the file.
    struct Window: Hashable {
        let label: String
        let percent: Int
        let resetsAt: Date?
        /// The window has started over since the sample.
        let expired: Bool
    }

    var windows: [Window] {
        if noSeat { return [] }
        if !limits.isEmpty {
            return limits.map { Window(label: $0.label, percent: $0.percent, resetsAt: $0.resetsAt,
                                       expired: $0.resetsAt.map { $0 < Date() } ?? false) }
        }
        return [Window(label: "5h", percent: fiveHour ?? 0, resetsAt: nil, expired: fiveHourExpired),
                Window(label: "7d", percent: sevenDay ?? 0, resetsAt: nil, expired: sevenDayExpired)]
    }

    /// Claude Desktop records usage only now and then: a sample older than a window means that
    /// window has started over since, whatever the sample says.
    var fiveHourExpired: Bool { age > 5 * 3600 }
    var sevenDayExpired: Bool { age > 7 * 86400 }
    /// Old enough to be shown faded, with its age.
    var isStale: Bool { age > 3600 }
    private var age: TimeInterval { Date().timeIntervalSince(sampledAt) }

    var exhausted: Bool {
        (!fiveHourExpired && (fiveHour ?? 0) >= 100) || (!sevenDayExpired && (sevenDay ?? 0) >= 100)
    }
}

struct SessionInfo {
    let id: String
    let title: String
    let error: String?
    let lastActivity: Date?
    let isArchived: Bool
    /// Claude Code's own session id: the transcript is `~/.claude/projects/<project>/<cliSessionId>.jsonl`.
    var cliSessionId: String? = nil
    /// Transcripts the session used before its current one (Claude Code starts a new one now and then).
    var priorCliSessionIds: [String] = []
    /// The project folder the session was started in.
    var cwd: String? = nil
    /// The folder it runs in: the project, or a git worktree of it.
    var runCwd: String? = nil
    /// The Claude Desktop environment (session preset) it was started from, if any.
    var environmentId: String? = nil

    /// The project folder: sessions in a git worktree of the project belong to the project itself.
    var projectPath: String? { cwd.map(Self.projectRoot) }

    /// The git worktree the session works in, if it is not the project folder itself.
    var worktree: String? {
        guard let run = runCwd, run != cwd, let r = run.range(of: "/.claude/worktrees/") else { return nil }
        return run[r.upperBound...].split(separator: "/").first.map(String.init)
    }

    /// Every conversation the session can reach: its transcript and the earlier ones.
    var conversationIds: [String] { (cliSessionId.map { [$0] } ?? []) + priorCliSessionIds }

    /// Claude Desktop shows a usage limit as an error like "You've hit your weekly limit · resets …".
    var stoppedByLimit: Bool {
        guard let error, !isArchived else { return false }
        return error.range(of: "limit", options: .caseInsensitive) != nil
    }

    static func projectRoot(_ path: String) -> String {
        path.range(of: "/.claude/worktrees/").map { String(path[..<$0.lowerBound]) } ?? path
    }
}

/// The sessions one account has in one data folder:
/// `<dataDir>/claude-code-sessions/<accountUuid>/<orgUuid>/local_*.json`.
struct Store {
    let dataDir: DataDir
    let accountUuid: String
    let orgUuid: String
    let path: String
    let sessions: [SessionInfo]
    let isSignedIn: Bool
    let usage: Usage?

    var key: String { "\(dataDir.path)|\(accountUuid)|\(orgUuid)" }
    var open: [SessionInfo] { sessions.filter { !$0.isArchived } }
    var archived: [SessionInfo] { sessions.filter(\.isArchived) }
    var stopped: [SessionInfo] { sessions.filter(\.stoppedByLimit) }
    var lastActivity: Date? { open.compactMap(\.lastActivity).max() }
}

enum Paths {
    static let home = NSHomeDirectory()
    static let appSupport = home + "/Library/Application Support"
    static let defaultDataDir = normalize(appSupport + "/Claude")
    static let ownDir = appSupport + "/Porter"
    static let backups = ownDir + "/backups"
    static let profiles = ownDir + "/Profiles"

    static func normalize(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).resolvingSymlinksInPath().standardizedFileURL.path
    }
}

func readJSON(_ path: String) -> Any? {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    return try? JSONSerialization.jsonObject(with: data)
}

/// Writes atomically, through a symlink rather than over it. Claude Desktop writes its own files
/// compact, except the small settings-like ones (`pretty`).
func writeJSON(_ object: Any, to path: String, pretty: Bool = false) throws {
    var options: JSONSerialization.WritingOptions = [.withoutEscapingSlashes]
    if pretty { options.insert(.prettyPrinted) }
    let data = try JSONSerialization.data(withJSONObject: object, options: options)
    try data.write(to: URL(fileURLWithPath: path).resolvingSymlinksInPath(), options: .atomic)
}

enum Discovery {
    static let claudeBundleId = "com.anthropic.claudefordesktop"
    /// Data folders passed with --data-dir on the command line (not persisted).
    static var extraDataDirs: [String] = []

    /// Every data folder we know about: the default one, profiles created from this app and folders
    /// Claude was ever seen running with. Those are remembered, so their sessions still count when the
    /// app is closed (a conversation they list is never taken for an orphan).
    static func dataDirs(running: Set<String>) -> [DataDir] {
        let unknown = running.subtracting(Settings.seenDataDirs).subtracting(Settings.profiles.keys).subtracting([Paths.defaultDataDir])
        if !unknown.isEmpty { Settings.seenDataDirs += unknown.sorted() }
        var labels: [String: String] = [Paths.defaultDataDir: "Claude"]
        for (dir, name) in Settings.profiles { labels[dir] = name }
        for dir in Settings.seenDataDirs + extraDataDirs where labels[dir] == nil {
            labels[dir] = (dir as NSString).lastPathComponent
        }
        for (dir, name) in Settings.profileNames where labels[dir] != nil && !name.isEmpty { labels[dir] = name }
        return labels
            // Profiles made by this app are listed even before Claude has created any session there.
            .filter { FileManager.default.fileExists(atPath: $0.key + "/claude-code-sessions") || Settings.profiles[$0.key] != nil }
            .map { DataDir(path: $0.key, label: $0.value) }
            .sorted { ($0.isDefault ? 0 : 1, $0.label) < ($1.isDefault ? 0 : 1, $1.label) }
    }

    /// The signed-in account of a data folder, as last recorded by the app.
    static func signedInAccount(in dir: DataDir) -> String? {
        (readJSON(dir.path + "/config.json") as? [String: Any])?["lastKnownAccountUuid"] as? String
    }

    static func stores(in dir: DataDir, signedIn: String?) -> [Store] {
        let fm = FileManager.default
        let root = dir.sessionsRoot
        let samples = usageSamples(in: dir)
        let orgs = signedIn.map { Set((try? fm.contentsOfDirectory(atPath: "\(root)/\($0)")) ?? []) } ?? []
        // The organization claude.ai answered for is the active one; the samples are only a guess.
        let live = signedIn == nil ? nil : LiveUsage.sample(in: dir).flatMap { orgs.contains($0.org) ? $0 : nil }
        let activeOrg = live?.org ?? self.activeOrg(samples, among: orgs)
        var result: [Store] = []
        for account in (try? fm.contentsOfDirectory(atPath: root)) ?? [] {
            for org in (try? fm.contentsOfDirectory(atPath: "\(root)/\(account)")) ?? [] {
                let path = "\(root)/\(account)/\(org)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
                let sessions = self.sessions(in: path)
                // An account can belong to several organizations; only one of them is active.
                let isSignedIn = account == signedIn && (activeOrg == nil || org == activeOrg)
                // Empty folders are hidden, except the one the app is signed in to: a valid destination.
                // Archived-only ones stay: their sessions can be restored, and the account removed.
                guard !sessions.isEmpty || (isSignedIn && hasEverHeldSessions(path)) else { continue }
                result.append(Store(dataDir: dir, accountUuid: account, orgUuid: org, path: path,
                                    sessions: sessions, isSignedIn: isSignedIn,
                                    usage: isSignedIn ? newest(live.flatMap { $0.org == org ? $0.usage : nil }, usage(samples, org: org)) : nil))
            }
        }
        return result.sorted { ($0.isSignedIn ? 0 : 1, -$0.open.count) < ($1.isSignedIn ? 0 : 1, -$1.open.count) }
    }

    private static func hasEverHeldSessions(_ path: String) -> Bool {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        return files.contains { $0.hasPrefix("local_") || $0.hasPrefix("deleted_") || $0 == "scheduled-tasks.json" }
    }

    static func archivedIds(in path: String) -> Set<String> {
        let idx = readJSON(path + "/archived-sessions.idx") as? [String: Any]
        return Set((idx?["archived"] as? [String]) ?? [])
    }

    /// Every session file (`local_*.json`) under `root`, as full paths.
    static func sessionFiles(under root: String) -> [String] {
        guard let walker = FileManager.default.enumerator(atPath: root) else { return [] }
        var files: [String] = []
        for case let file as String in walker {
            let name = (file as NSString).lastPathComponent
            if name.hasPrefix("local_") && name.hasSuffix(".json") { files.append("\(root)/\(file)") }
        }
        return files
    }

    /// Open sessions under `root`, counted from the files: including the ones Claude Desktop keeps out
    /// of its sidebar (and so does Porter), which removing the folder trashes as well.
    static func openSessionCount(under root: String) -> Int {
        var archivedByStore: [String: Set<String>] = [:]
        return sessionFiles(under: root).filter { file in
            guard let h = header(at: file) else { return false }
            let store = (file as NSString).deletingLastPathComponent
            if archivedByStore[store] == nil { archivedByStore[store] = archivedIds(in: store) }
            return h.isArchived != true && !(archivedByStore[store]?.contains(h.sessionId) ?? false)
        }.count
    }

    /// The few fields we need from a session file. Session files can be hundreds of KB
    /// (tool and prompt snapshots), so only these are extracted, and cached by modification time.
    struct SessionHeader: Codable {
        let sessionId: String
        let title: String?
        let error: String?
        let lastActivityAt: Double?
        let isArchived: Bool?
        let cliSessionId: String?
        var priorCliSessionIds: [String]? = nil
        /// The project folder (`originCwd`), or the folder it runs in for older sessions.
        let cwd: String?
        /// The folder it runs in: the project or one of its worktrees.
        var runCwd: String? = nil
        let environmentId: String?
        /// Started on this Mac by a Claude conversation in a claude.ai project, one per task it hands out.
        /// Claude Desktop keeps these out of its sidebar; they are reached from the project instead.
        let projectThreadChild: Bool

        var conversationIds: [String] { (cliSessionId.map { [$0] } ?? []) + (priorCliSessionIds ?? []) }
    }

    private struct CacheEntry: Codable {
        let sec: Int
        let nsec: Int
        let size: Int64
        let header: SessionHeader?
    }

    private static var headerCache: [String: CacheEntry] = [:]
    private static var headerCacheLoaded = false
    private static var headerCacheDirty = false
    private static let cacheLock = NSLock()
    private static let headerKeys: Set<String> = ["sessionId", "title", "error", "lastActivityAt", "isArchived", "cliSessionId",
                                                  "priorCliSessionIds", "cwd", "originCwd", "envScopeId", "remoteControlSpawn"]
    /// Reading every header means reading every session file in full (the fields can come last), so the
    /// cache is kept on disk: the first listing after a login then reads only what changed.
    private static let headerCachePath = Paths.ownDir + "/header-cache.json"

    static func header(at path: String) -> SessionHeader? {
        var info = stat()
        guard stat(path, &info) == 0 else { return nil }
        let modified = info.st_mtimespec
        cacheLock.lock()
        if !headerCacheLoaded {
            headerCacheLoaded = true
            if let data = FileManager.default.contents(atPath: headerCachePath),
               let saved = try? JSONDecoder().decode([String: CacheEntry].self, from: data) {
                headerCache = saved
            }
        }
        if let cached = headerCache[path], cached.sec == modified.tv_sec, cached.nsec == modified.tv_nsec,
           cached.size == info.st_size {
            cacheLock.unlock()
            return cached.header
        }
        cacheLock.unlock()
        // Parsed outside the lock, so a slow file never holds up other readers.
        let header = autoreleasepool { () -> SessionHeader? in
            guard let d = JSONPeek.read(path, keys: headerKeys), let id = d["sessionId"] as? String else { return nil }
            let runCwd = d["cwd"] as? String
            return SessionHeader(sessionId: id, title: d["title"] as? String, error: d["error"] as? String,
                                 lastActivityAt: d["lastActivityAt"] as? Double, isArchived: d["isArchived"] as? Bool,
                                 cliSessionId: d["cliSessionId"] as? String,
                                 priorCliSessionIds: (d["priorCliSessionIds"] as? [Any])?.compactMap { $0 as? String },
                                 cwd: (d["originCwd"] as? String) ?? runCwd, runCwd: runCwd,
                                 environmentId: d["envScopeId"] as? String,
                                 projectThreadChild: (d["remoteControlSpawn"] as? [String: Any])?["projectThreadChild"] as? Bool == true)
        }
        cacheLock.lock()
        headerCache[path] = CacheEntry(sec: modified.tv_sec, nsec: modified.tv_nsec, size: info.st_size, header: header)
        headerCacheDirty = true
        cacheLock.unlock()
        return header
    }

    /// Saves the header cache, keeping only files that still exist.
    static func saveHeaderCache() {
        cacheLock.lock()
        guard headerCacheDirty else { cacheLock.unlock(); return }
        headerCacheDirty = false
        headerCache = headerCache.filter { FileManager.default.fileExists(atPath: $0.key) }
        let data = try? JSONEncoder().encode(headerCache)
        cacheLock.unlock()
        guard let data else { return }
        try? FileManager.default.createDirectory(atPath: Paths.ownDir, withIntermediateDirectories: true)
        try? data.write(to: URL(fileURLWithPath: headerCachePath), options: .atomic)
    }

    /// Sessions of a store, most recent first, archived ones included.
    static func sessions(in path: String) -> [SessionInfo] {
        let archived = archivedIds(in: path)
        let files = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
        var out: [(Double, SessionInfo)] = []
        for file in files where file.hasPrefix("local_") && file.hasSuffix(".json") {
            // Hidden by Claude Desktop too: listing them would show sessions its sidebar does not have.
            guard let h = header(at: "\(path)/\(file)"), !h.projectThreadChild else { continue }
            let last = h.lastActivityAt ?? 0
            out.append((last, SessionInfo(id: h.sessionId,
                                          title: h.title.flatMap { $0.isEmpty ? nil : $0 } ?? tr("(untitled)"),
                                          error: h.error,
                                          lastActivity: last > 0 ? Date(timeIntervalSince1970: last / 1000) : nil,
                                          isArchived: h.isArchived == true || archived.contains(h.sessionId),
                                          cliSessionId: h.cliSessionId, priorCliSessionIds: h.priorCliSessionIds ?? [],
                                          cwd: h.cwd, runCwd: h.runCwd, environmentId: h.environmentId)))
        }
        return out.sorted { $0.0 > $1.0 }.map(\.1)
    }

    /// Names of the Claude Desktop environments (session presets) of every data folder, by preset id
    /// and by folder, so sessions can be grouped under the name the user gave their project.
    static func environmentNames(in dirs: [DataDir]) -> (byId: [String: String], byPath: [String: String]) {
        var byId: [String: String] = [:], byPath: [String: String] = [:]
        for dir in dirs {
            let presets = (readJSON(dir.path + "/ccd-session-presets.json") as? [String: Any])?["byAccount"] as? [String: Any]
            for case let account as [String: Any] in (presets ?? [:]).values {
                for case let preset as [String: Any] in (account["presets"] as? [Any]) ?? [] {
                    guard let name = preset["name"] as? String, !name.isEmpty else { continue }
                    if let id = preset["id"] as? String { byId[id] = name }
                    if let cwd = (preset["target"] as? [String: Any])?["cwd"] as? String { byPath[cwd] = byPath[cwd] ?? name }
                }
            }
        }
        return (byId, byPath)
    }

    // MARK: - Usage

    private static func usageSamples(in dir: DataDir) -> [[String: Any]] {
        (readJSON(dir.path + "/plan-usage-history.json") as? [String: Any])?["samples"] as? [[String: Any]] ?? []
    }

    /// The app does not record the active organization explicitly; its newest usage sample among the
    /// signed-in account's organizations is for it (samples of the previous account are left out).
    private static func activeOrg(_ samples: [[String: Any]], among orgs: Set<String>) -> String? {
        samples.filter { ($0["org"] as? String).map(orgs.contains) ?? false }
            .max { ($0["t"] as? Double ?? 0) < ($1["t"] as? Double ?? 0) }?["org"] as? String
    }

    private static func newest(_ a: Usage?, _ b: Usage?) -> Usage? {
        guard let a, let b else { return a ?? b }
        return a.sampledAt >= b.sampledAt ? a : b
    }

    /// Latest usage sample the app recorded for this org (only meaningful for the signed-in account).
    /// Claude Desktop stores the raw utilization, which can have decimals; it shows it rounded down.
    private static func usage(_ samples: [[String: Any]], org: String) -> Usage? {
        func percent(_ value: Any?) -> Int? { (value as? Double).map { Int($0.rounded(.down)) } }
        for s in samples.reversed() {
            guard (s["org"] as? String) == org, let u = s["u"] as? [String: Any], !u.isEmpty,
                  let t = s["t"] as? Double else { continue }
            return Usage(fiveHour: percent(u["fh"]), sevenDay: percent(u["sd"]), sampledAt: Date(timeIntervalSince1970: t / 1000))
        }
        return nil
    }

    // MARK: - Account names

    /// The desktop app does not store account emails in plain files; we remember those found in its
    /// claude.ai cache and in the Claude Code CLI login (~/.claude.json), or use a short UUID.
    static func accountName(_ uuid: String) -> String {
        knownAccountName(uuid) ?? tr("Account %@", String(uuid.prefix(8)))
    }

    /// The email of this account, if it was ever found.
    static func knownAccountName(_ uuid: String) -> String? {
        if let login = cliLogin(), login.uuid == uuid { return login.email }
        return Settings.accountEmails[uuid]
    }

    private static var cliLoginCache: (modified: timespec, login: (uuid: String, email: String)?)?
    private static let loginLock = NSLock()

    /// The account the Claude Code CLI is signed in to. ~/.claude.json can be several MB and changes
    /// often, so only its `oauthAccount` is read, and again only when the file changes.
    private static func cliLogin() -> (uuid: String, email: String)? {
        let path = Paths.home + "/.claude.json"
        var info = stat()
        let modified = stat(path, &info) == 0 ? info.st_mtimespec : timespec()
        loginLock.lock()
        defer { loginLock.unlock() }
        if let cached = cliLoginCache, cached.modified.tv_sec == modified.tv_sec, cached.modified.tv_nsec == modified.tv_nsec {
            return cached.login
        }
        var login: (uuid: String, email: String)?
        if let oauth = JSONPeek.read(path, keys: ["oauthAccount"])?["oauthAccount"] as? [String: Any],
           let uuid = oauth["accountUuid"] as? String, let email = oauth["emailAddress"] as? String {
            login = (uuid, email)
            if Settings.accountEmails[uuid] != email { Settings.accountEmails[uuid] = email }
        }
        cliLoginCache = (modified, login)
        return login
    }

    private static let emailMarker = Data("\"\u{0D}email_address\"".utf8)

    /// Learns the email of the account signed in to `dir`, once. The claude.ai page keeps its query
    /// cache in IndexedDB, serialized by V8 (strings are `"`, a length byte, the bytes) and stored as
    /// blob files that are rewritten often; its `account` entry has `uuid` right before `email_address`.
    static func learnEmail(in dir: DataDir, account: String?) {
        guard let account, Settings.accountEmails[account] == nil else { return }
        let root = dir.path + "/IndexedDB/https_claude.ai_0.indexeddb.blob"
        guard let files = FileManager.default.enumerator(atPath: root) else { return }
        var found: [String: String] = [:]
        for case let file as String in files {
            guard let data = FileManager.default.contents(atPath: root + "/" + file) else { continue }
            var from = data.startIndex
            while let marker = data.range(of: emailMarker, in: from..<data.endIndex) {
                from = marker.upperBound
                // `"$` and the 36-character uuid, then the marker; the email follows it.
                let uuidStart = marker.lowerBound - 36
                guard uuidStart - 2 >= data.startIndex, data[uuidStart - 2] == 0x22, data[uuidStart - 1] == 36,
                      marker.upperBound < data.endIndex else { continue }
                let length = Int(data[marker.upperBound])
                let emailStart = marker.upperBound + 1
                guard length < 0x80, emailStart + length <= data.endIndex,
                      let uuid = String(data: data[uuidStart..<marker.lowerBound], encoding: .ascii),
                      let email = String(data: data[emailStart..<emailStart + length], encoding: .utf8),
                      email.contains("@") else { continue }
                found[uuid] = email
            }
        }
        if !found.isEmpty { Settings.accountEmails.merge(found) { _, new in new } }
    }

    static func orgName(_ uuid: String) -> String { tr("Org %@", String(uuid.prefix(8))) }

    /// "account · organization", plus the data folder when stores from several folders are shown.
    static func displayName(_ store: Store, includeFolder: Bool) -> String {
        let name = "\(accountName(store.accountUuid)) · \(orgName(store.orgUuid))"
        return includeFolder ? "\(name) — \(store.dataDir.label)" : name
    }

    // MARK: - Running instances

    struct Instance {
        let app: NSRunningApplication
        let dataDir: String
    }

    static func runningInstances() -> [Instance] {
        NSRunningApplication.runningApplications(withBundleIdentifier: claudeBundleId).compactMap { app in
            guard !app.isTerminated, isAlive(app.processIdentifier) else { return nil }
            let flag = "--user-data-dir="
            let arg = processArguments(app.processIdentifier).first { $0.hasPrefix(flag) }
            let dir = arg.map { Paths.normalize(String($0.dropFirst(flag.count))) } ?? Paths.defaultDataDir
            return Instance(app: app, dataDir: dir)
        }
    }

    static func instances(for dir: DataDir) -> [Instance] {
        runningInstances().filter { $0.dataDir == dir.path }
    }

    /// Whether the process exists. NSRunningApplication's state only updates while the main run loop
    /// turns, which never happens on the command line.
    static func isAlive(_ pid: pid_t) -> Bool { kill(pid, 0) == 0 || errno == EPERM }

    /// Command-line arguments of another process, via sysctl(KERN_PROCARGS2).
    static func processArguments(_ pid: pid_t) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else { return [] }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return [] }
        let argc = buffer.withUnsafeBytes { Int($0.load(as: Int32.self)) }
        var i = MemoryLayout<Int32>.size
        while i < size, buffer[i] != 0 { i += 1 }  // executable path
        while i < size, buffer[i] == 0 { i += 1 }  // padding
        var args: [String] = []
        while args.count < argc, i < size {
            let start = i
            while i < size, buffer[i] != 0 { i += 1 }
            args.append(String(decoding: buffer[start..<i], as: UTF8.self))
            i += 1
        }
        return args
    }
}

enum Settings {
    private static let defaults = UserDefaults.standard

    /// Names the user gave to profiles (data folder path → name), overriding folder names.
    static var profileNames: [String: String] {
        get { defaults.dictionary(forKey: "profileNames") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "profileNames") }
    }

    /// Emails of the accounts seen in Claude's cache or the Claude Code CLI login: account UUID → email.
    static var accountEmails: [String: String] {
        get { defaults.dictionary(forKey: "accountEmails") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "accountEmails") }
    }

    /// Claude profiles created from this app: data folder path → name.
    static var profiles: [String: String] {
        get { defaults.dictionary(forKey: "profiles") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "profiles") }
    }

    /// Data folders Claude was seen running with, outside the ones above.
    static var seenDataDirs: [String] {
        get { defaults.stringArray(forKey: "seenDataDirs") ?? [] }
        set { defaults.set(newValue, forKey: "seenDataDirs") }
    }

    /// Ask claude.ai for usage with each profile's session (LiveUsage). Off by default: it needs the Keychain.
    static var liveUsage: Bool {
        get { defaults.bool(forKey: "liveUsage") }
        set { defaults.set(newValue, forKey: "liveUsage") }
    }

    /// Show the Claude Profiles section (several Claude apps side by side). Off means the classic
    /// setup: one Claude app, switching accounts by signing out and in. On by default once there are profiles.
    static var multipleProfiles: Bool {
        get { defaults.object(forKey: "multipleProfiles") as? Bool ?? !profiles.isEmpty }
        set { defaults.set(newValue, forKey: "multipleProfiles") }
    }

    /// Forgets a profile: its name and that it exists.
    static func forget(_ dir: String) {
        profiles[dir] = nil
        profileNames[dir] = nil
        seenDataDirs.removeAll { $0 == dir }
    }
}
