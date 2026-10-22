import CommonCrypto
import Foundation
import Security
import SQLite3

/// Usage asked to claude.ai with the session each profile is signed in with, as the app's own usage
/// screen does. Claude Desktop records usage in plan-usage-history.json only now and then; this is
/// what is shown when it works, and the file otherwise.
enum LiveUsage {
    struct Sample {
        let org: String
        let usage: Usage
        /// claude.ai's answer as it came, for `Porter --usage-json`.
        var response: Data? = nil
    }

    private struct State {
        var sample: Sample?
        var nextAttempt = Date.distantPast
        var failures = 0
    }

    private static var states: [String: State] = [:]
    private static let lock = NSLock()
    /// Asking claude.ai more often than this brings nothing: usage moves slowly.
    private static let interval: TimeInterval = 180

    /// The latest usage of the account signed in to `dir`, asked again when due. Blocks for the request:
    /// call it off the main thread.
    static func sample(in dir: DataDir) -> Sample? {
        guard Settings.liveUsage else { return nil }
        lock.lock()
        var state = states[dir.path] ?? State()
        lock.unlock()
        if Date() >= state.nextAttempt {
            switch fetch(in: dir) {
            case .success(let sample):
                state.sample = sample
                state.failures = 0
                state.nextAttempt = Date().addingTimeInterval(interval)
            case .failure(let failure):
                if case .signedOut = failure { state.sample = nil }
                state.failures += 1
                // Wait longer after each failure, or as long as claude.ai asks.
                state.nextAttempt = Date().addingTimeInterval(failure.retryAfter ?? interval * pow(2, Double(min(state.failures, 5))))
            }
            lock.lock()
            states[dir.path] = state
            lock.unlock()
        }
        return state.sample
    }

    /// Forgets the key and every sample, so turning the option on asks macOS again at once.
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        states = [:]
        keyLookup = (false, nil)
    }

    private enum Failure: Error {
        case noKey, signedOut, refused(retryAfter: TimeInterval?), unreadable

        var retryAfter: TimeInterval? {
            if case .refused(let after) = self { return after }
            return nil
        }
    }

    private static func fetch(in dir: DataDir) -> Result<Sample, Failure> {
        guard let key = cookieKey() else { return .failure(.noKey) }
        let cookies = claudeCookies(in: dir.path, key: key)
        guard let session = cookies["sessionKey"], let org = cookies["lastActiveOrg"],
              let url = URL(string: "https://claude.ai/api/organizations/\(org)/usage") else { return .failure(.signedOut) }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("sessionKey=\(session); lastActiveOrg=\(org)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        var result: Result<Sample, Failure> = .failure(.unreadable)
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            defer { done.signal() }
            guard let http = response as? HTTPURLResponse else { return }
            switch http.statusCode {
            case 200:
                guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json.keys.contains("five_hour") || json.keys.contains("seven_day") else { return }
                // A percentage with decimals; Claude Desktop shows it rounded down.
                func percent(_ window: String) -> Int? {
                    ((json[window] as? [String: Any])?["utilization"] as? Double).map { Int($0.rounded(.down)) }
                }
                var usage = Usage(fiveHour: percent("five_hour"), sevenDay: percent("seven_day"),
                                  sampledAt: Date(), limits: limits(json["limits"]))
                // A member without a seat gets every window as null and no limits ("unassigned_seat"):
                // that is not 0%.
                usage.noSeat = usage.fiveHour == nil && usage.sevenDay == nil && usage.limits.isEmpty
                result = .success(Sample(org: org, usage: usage, response: data))
            case 401, 403:
                result = .failure(.signedOut)
            default:
                result = .failure(.refused(retryAfter: http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)))
            }
        }.resume()
        done.wait()
        return result
    }

    /// The `limits` list: the session (5h), the whole week (7d), and weeks limited to one model or
    /// surface, named as claude.ai names them ("Fable"). Kinds it may add later show up the same way.
    private static func limits(_ value: Any?) -> [Usage.Limit] {
        ((value as? [[String: Any]]) ?? []).compactMap { limit in
            guard let percent = limit["percent"] as? Double else { return nil }
            let scope = limit["scope"] as? [String: Any]
            let name = ["model", "surface"].lazy.compactMap { (scope?[$0] as? [String: Any])?["display_name"] as? String }.first
            let label: String
            switch limit["kind"] as? String {
            case "session": label = "5h"
            case "weekly_all": label = "7d"
            default:
                guard let name else { return nil }
                label = name
            }
            return Usage.Limit(label: label, percent: Int(percent.rounded(.down)), resetsAt: date(limit["resets_at"]))
        }
    }

    /// "2026-10-21T12:49:59.824259+00:00": the fraction (microseconds) is dropped, a second is enough.
    private static func date(_ value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        return ISO8601DateFormatter().date(from: text.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression))
    }

    // MARK: - Claude's cookies

    private static var keyLookup: (done: Bool, key: Data?) = (false, nil)

    /// Claude Desktop encrypts its cookies like Chrome, with a key derived from the password it keeps
    /// in the Keychain as "Claude Safe Storage"; every profile uses the same one. macOS asks the user
    /// once; if they refuse, Porter does not ask again until it restarts or the option is turned on again.
    private static func cookieKey() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        if keyLookup.done { return keyLookup.key }
        keyLookup.done = true
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "Claude Safe Storage",
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let password = item as? Data, !password.isEmpty else { return nil }
        var key = Data(count: kCCKeySizeAES128)
        let salt = Array("saltysalt".utf8)
        let status = key.withUnsafeMutableBytes { k in
            password.withUnsafeBytes { p in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), p.baseAddress?.assumingMemoryBound(to: CChar.self), password.count,
                                     salt, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), 1003,
                                     k.baseAddress?.assumingMemoryBound(to: UInt8.self), kCCKeySizeAES128)
            }
        }
        keyLookup.key = status == kCCSuccess ? key : nil
        return keyLookup.key
    }

    /// The claude.ai cookies Porter needs, decrypted. The database is read as it is on disk, without
    /// locking it, since a running Claude app keeps it open.
    private static func claudeCookies(in dir: String, key: Data) -> [String: String] {
        let path = dir + "/Cookies"
        guard FileManager.default.fileExists(atPath: path) else { return [:] }
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        let uri = URL(fileURLWithPath: path).absoluteString + "?immutable=1"
        guard sqlite3_open_v2(uri, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK else { return [:] }
        var statement: OpaquePointer?
        // From version 24 the decrypted value starts with a hash of the cookie's domain.
        var version = 0
        if sqlite3_prepare_v2(db, "SELECT value FROM meta WHERE key = 'version'", -1, &statement, nil) == SQLITE_OK,
           sqlite3_step(statement) == SQLITE_ROW, let text = sqlite3_column_text(statement, 0) {
            version = Int(String(cString: text)) ?? 0
        }
        sqlite3_finalize(statement)
        let query = "SELECT name, encrypted_value FROM cookies WHERE host_key IN ('claude.ai', '.claude.ai') AND name IN ('sessionKey', 'lastActiveOrg')"
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(statement) }
        var cookies: [String: String] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let name = sqlite3_column_text(statement, 0), let bytes = sqlite3_column_blob(statement, 1),
                  var value = decrypt(Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 1))), key: key) else { continue }
            if version >= 24 { value = value.dropFirst(32) }
            if let text = String(data: value, encoding: .utf8) { cookies[String(cString: name)] = text }
        }
        return cookies
    }

    /// "v10", then AES-128-CBC with an IV of 16 spaces.
    private static func decrypt(_ data: Data, key: Data) -> Data? {
        guard data.count > 3, data.prefix(3) == Data("v10".utf8) else { return nil }
        let cipher = data.dropFirst(3)
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
        var plain = Data(count: cipher.count + kCCBlockSizeAES128)
        let capacity = plain.count
        var length = 0
        let status = plain.withUnsafeMutableBytes { p in
            cipher.withUnsafeBytes { c in
                key.withUnsafeBytes { k in
                    CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                            k.baseAddress, key.count, iv, c.baseAddress, cipher.count, p.baseAddress, capacity, &length)
                }
            }
        }
        return status == kCCSuccess ? Data(plain.prefix(length)) : nil
    }
}
