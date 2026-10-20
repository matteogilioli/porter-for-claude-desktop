import Foundation

/// Reads a few top-level keys of a JSON object without building the whole document.
///
/// Session files can be hundreds of KB (tool and prompt snapshots) while we need five small
/// fields, so the file is memory-mapped and every other value is skipped byte by byte.
enum JSONPeek {
    /// Returns the requested keys found at the top level. Values are String, Double, Bool, NSNull,
    /// or a dictionary or array for the (small) objects and arrays asked for.
    static func read(_ path: String, keys: Set<String>) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped) else { return nil }
        return data.withUnsafeBytes { raw -> [String: Any]? in
            var scanner = Scanner(bytes: raw.bindMemory(to: UInt8.self))
            return scanner.topLevel(keys)
        }
    }

    private struct Scanner {
        let bytes: UnsafeBufferPointer<UInt8>
        var i = 0

        init(bytes: UnsafeBufferPointer<UInt8>) { self.bytes = bytes }

        mutating func topLevel(_ wanted: Set<String>) -> [String: Any]? {
            skipSpace()
            guard take(UInt8(ascii: "{")) else { return nil }
            var found: [String: Any] = [:]
            while true {
                skipSpace()
                if take(UInt8(ascii: "}")) { return found }
                guard let keyRange = stringRange() else { return nil }
                skipSpace()
                guard take(UInt8(ascii: ":")) else { return nil }
                skipSpace()
                let key = String(decoding: UnsafeBufferPointer(rebasing: bytes[keyRange]), as: UTF8.self)
                if wanted.contains(key), let value = primitive() {
                    found[key] = value
                    if found.count == wanted.count { return found }
                } else if !skipValue() {
                    return nil
                }
                skipSpace()
                if take(UInt8(ascii: ",")) { continue }
                return take(UInt8(ascii: "}")) ? found : nil
            }
        }

        // MARK: Values

        /// Parses a string, number, boolean or null; objects and arrays are decoded by Foundation.
        mutating func primitive() -> Any? {
            guard i < bytes.count else { return nil }
            switch bytes[i] {
            case UInt8(ascii: "\""):
                let start = i
                guard let range = stringRange() else { return nil }
                if !bytes[range].contains(UInt8(ascii: "\\")) {
                    return String(decoding: UnsafeBufferPointer(rebasing: bytes[range]), as: UTF8.self)
                }
                // Rare: let Foundation decode the escapes of this one string.
                let slice = Data(UnsafeBufferPointer(rebasing: bytes[start..<i]))
                return (try? JSONSerialization.jsonObject(with: slice, options: .fragmentsAllowed)) as? String
            case UInt8(ascii: "t"): return literal("true") ? true : nil
            case UInt8(ascii: "f"): return literal("false") ? false : nil
            case UInt8(ascii: "n"): return literal("null") ? NSNull() : nil
            case UInt8(ascii: "{"), UInt8(ascii: "["):
                let start = i
                guard skipValue() else { return nil }
                return try? JSONSerialization.jsonObject(with: Data(UnsafeBufferPointer(rebasing: bytes[start..<i])))
            default:
                let start = i
                while i < bytes.count, !isDelimiter(bytes[i]) { i += 1 }
                return Double(String(decoding: UnsafeBufferPointer(rebasing: bytes[start..<i]), as: UTF8.self))
            }
        }

        mutating func skipValue() -> Bool {
            guard i < bytes.count else { return false }
            switch bytes[i] {
            case UInt8(ascii: "\""):
                return stringRange() != nil
            case UInt8(ascii: "{"), UInt8(ascii: "["):
                var depth = 0
                while i < bytes.count {
                    switch bytes[i] {
                    case UInt8(ascii: "\""):
                        guard stringRange() != nil else { return false }
                        continue
                    case UInt8(ascii: "{"), UInt8(ascii: "["): depth += 1
                    case UInt8(ascii: "}"), UInt8(ascii: "]"):
                        depth -= 1
                        if depth == 0 { i += 1; return true }
                    default: break
                    }
                    i += 1
                }
                return false
            default:
                while i < bytes.count, !isDelimiter(bytes[i]) { i += 1 }
                return true
            }
        }

        /// Consumes a string and returns the range of its raw contents (without quotes).
        mutating func stringRange() -> Range<Int>? {
            guard take(UInt8(ascii: "\"")) else { return nil }
            let start = i
            while i < bytes.count {
                switch bytes[i] {
                case UInt8(ascii: "\\"): i += 2
                case UInt8(ascii: "\""):
                    defer { i += 1 }
                    return start..<i
                default: i += 1
                }
            }
            return nil
        }

        // MARK: Helpers

        mutating func literal(_ word: StaticString) -> Bool {
            let n = word.utf8CodeUnitCount
            guard i + n <= bytes.count else { return false }
            for k in 0..<n where bytes[i + k] != word.utf8Start[k] { return false }
            i += n
            return true
        }

        mutating func take(_ byte: UInt8) -> Bool {
            guard i < bytes.count, bytes[i] == byte else { return false }
            i += 1
            return true
        }

        mutating func skipSpace() {
            while i < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[i]) { i += 1 }
        }

        func isDelimiter(_ b: UInt8) -> Bool {
            b == UInt8(ascii: ",") || b == UInt8(ascii: "}") || b == UInt8(ascii: "]") || b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09
        }
    }
}
