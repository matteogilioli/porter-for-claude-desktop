import Foundation

/// Claude Code conversation files, shared by every profile and by the CLI:
/// `~/.claude/projects/<folder named after the working directory>/<id>.jsonl`, plus a sidecar folder `<id>/`.
enum Transcripts {
    static let projects = Paths.home + "/.claude/projects"

    /// Claude Code's folder name for a working directory: every UTF-16 unit that is not an ASCII letter
    /// or digit becomes "-", and names over 200 characters are cut, with a hash of the path appended.
    static func folderName(_ path: String) -> String {
        let units = path.utf16.map { u -> Character in
            (u >= 0x30 && u <= 0x39) || (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A) ? Character(UnicodeScalar(u)!) : "-"
        }
        guard units.count > 200 else { return String(units) }
        // JavaScript's `(h << 5) - h + charCode | 0` over UTF-16 units, then `Math.abs(h).toString(36)`.
        var hash: Int32 = 0
        for u in path.utf16 { hash = (hash &<< 5) &- hash &+ Int32(u) }
        return String(units.prefix(200)) + "-" + String(abs(Int64(hash)), radix: 36)
    }

    /// Conversations of the session files `isMine` picks that no other session file anywhere lists,
    /// open or archived: the ones nothing could reach once those files are gone. Values are the folder
    /// each one ran in, to find its transcript. Reads every session file: call it off the main thread.
    static func orphaned(among dirs: [DataDir], isMine: (String) -> Bool) -> [String: String] {
        var mine: [String: String] = [:], elsewhere: Set<String> = []
        for dir in dirs {
            for file in Discovery.sessionFiles(under: dir.sessionsRoot) {
                guard let header = Discovery.header(at: file) else { continue }
                if isMine(file) {
                    for id in header.conversationIds { mine[id] = header.runCwd ?? header.cwd ?? "" }
                } else {
                    elsewhere.formUnion(header.conversationIds)
                }
            }
        }
        return mine.filter { !elsewhere.contains($0.key) }
    }

    /// Conversations only the session files under `path` (a data folder's sessions or one store) list.
    static func orphaned(by path: String, among dirs: [DataDir]) -> [String: String] {
        let prefix = path.hasSuffix("/") ? path : path + "/"
        return orphaned(among: dirs) { $0.hasPrefix(prefix) }
    }

    /// The project folder holding conversation `id`: the one named after `cwd` if it has it, else any.
    static func folder(of id: String, cwd: String?) -> String? {
        let fm = FileManager.default
        func has(_ folder: String) -> Bool {
            fm.fileExists(atPath: "\(folder)/\(id).jsonl") || fm.fileExists(atPath: "\(folder)/\(id)")
        }
        if let cwd, !cwd.isEmpty, case let guess = "\(projects)/\(folderName(cwd))", has(guess) { return guess }
        return ((try? fm.contentsOfDirectory(atPath: projects)) ?? []).lazy.map { "\(projects)/\($0)" }.first(where: has)
    }

    /// Copies a conversation under a new id, next to the original: the transcript with its own
    /// session id rewritten, and its sidecar folder as is. Returns the new id and the files it made,
    /// or nil when there is no transcript.
    static func fork(_ id: String, cwd: String?) throws -> (id: String, files: [String])? {
        let fm = FileManager.default
        guard let folder = folder(of: id, cwd: cwd), fm.fileExists(atPath: "\(folder)/\(id).jsonl") else { return nil }
        let new = UUID().uuidString.lowercased()
        let data = try Data(contentsOf: URL(fileURLWithPath: "\(folder)/\(id).jsonl"), options: .alwaysMapped)
        let copy = "\(folder)/\(new).jsonl", sidecar = "\(folder)/\(new)"
        do {
            // The ids are ASCII: replacing bytes is exact and much faster than going through String.
            try replacing(Data(id.utf8), with: Data(new.utf8), in: data).write(to: URL(fileURLWithPath: copy), options: .atomic)
            if fm.fileExists(atPath: "\(folder)/\(id)") { try fm.copyItem(atPath: "\(folder)/\(id)", toPath: sidecar) }
        } catch {
            try? fm.removeItem(atPath: copy)
            try? fm.removeItem(atPath: sidecar)
            throw error
        }
        return (new, fm.fileExists(atPath: sidecar) ? [copy, sidecar] : [copy])
    }

    private static func replacing(_ target: Data, with replacement: Data, in data: Data) -> Data {
        var out = Data()
        out.reserveCapacity(data.count)
        var start = data.startIndex
        while let r = data.range(of: target, in: start..<data.endIndex) {
            out.append(data[start..<r.lowerBound])
            out.append(replacement)
            start = r.upperBound
        }
        out.append(data[start...])
        return out
    }

    /// Moves the transcript and sidecar folder of each conversation (id → folder it ran in) to the Trash.
    @discardableResult
    static func trash(_ conversations: [String: String]) -> Int {
        let fm = FileManager.default
        var count = 0
        for (id, cwd) in conversations where !id.isEmpty {
            guard let folder = folder(of: id, cwd: cwd) else { continue }
            var trashed = false
            for path in ["\(folder)/\(id).jsonl", "\(folder)/\(id)"] where fm.fileExists(atPath: path) {
                if (try? fm.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)) != nil { trashed = true }
            }
            if trashed { count += 1 }
        }
        return count
    }
}
