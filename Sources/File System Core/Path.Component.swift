public import Kernel
public import Path

extension Path.Component {

    /// The portable bound on a component's length, in UTF-8 bytes.
    ///
    /// APFS and ext4 bound a name at 255 UTF-8 bytes (`NAME_MAX`); NTFS bounds it at 255 UTF-16 code
    /// units. A scalar never takes fewer UTF-8 bytes than UTF-16 units (1–4 bytes against 1–2 units),
    /// so 255 UTF-8 bytes is the stricter of the two and holds on all three.
    public static let limit: Int = 255

    /// The component cut to at most `bytes` UTF-8 bytes, on a character boundary, or `nil` when not
    /// even its first character fits.
    ///
    /// A component that already fits comes back unchanged. The cut keeps the characters as they are,
    /// so a cut name may end in a space or a dot: a caller that prefers to cut at a word does so on the
    /// result, then makes it portable again with ``init(cleaning:)``.
    public func bounded(to bytes: Int = Path.Component.limit) -> Path.Component? {
        let text = string
        guard text.utf8.count > bytes else {
            return self
        }
        var end = text.startIndex
        while end < text.endIndex {
            let next = text.index(after: end)
            guard text.utf8.distance(from: text.startIndex, to: next) <= bytes else {
                break
            }
            end = next
        }
        guard end > text.startIndex else {
            return nil
        }
        return Path.Component(unchecked: Swift.String(text[..<end]))
    }
}

extension Path.Component {

    /// A portable component made from arbitrary text, or `nil` when nothing nameable remains.
    ///
    /// The rules are the union of POSIX and Windows, on every platform, so a name made on one system
    /// opens on the others:
    /// - `/ \ : * ? " < > |`, control and format characters (including bidirectional overrides and
    ///   zero-width joiners), and line and paragraph separators become a space;
    /// - each run of white space becomes one space;
    /// - leading and trailing spaces and dots go (Windows drops them, and a leading dot hides a file);
    /// - a name whose part before the first dot is one of ``reserved`` gets `_` after that part,
    ///   so `con.txt` becomes `con_.txt`.
    ///
    /// The result is not bounded in length; see ``bounded(to:)``.
    public init?(cleaning text: Swift.String) {
        var replaced = ""
        for scalar in text.unicodeScalars {
            replaced.unicodeScalars.append(Self.isPortable(scalar) ? scalar : " ")
        }
        let words = replaced.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard
            let first = words.firstIndex(where: { !Self.isLoose($0) }),
            let last = words.lastIndex(where: { !Self.isLoose($0) })
        else {
            return nil
        }
        var name = Swift.String(words[first...last])
        let device = name.prefix { $0 != "." }
        if Self.reserved.contains(device.uppercased()) {
            name.insert("_", at: device.endIndex)
        }
        self.init(unchecked: name)
    }

    /// A portable component made from arbitrary text, or `fallback` when nothing nameable remains.
    ///
    /// Total: it never throws and never fails. The rules are those of ``init(cleaning:)``.
    public init(cleaning text: Swift.String, fallback: Path.Component) {
        self = Path.Component(cleaning: text) ?? fallback
    }
}

extension Path.Component {

    /// Whether a portable name can hold the scalar.
    private static func isPortable(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
        case "/", "\\", ":", "*", "?", "\"", "<", ">", "|":
            return false

        default:
            switch scalar.properties.generalCategory {
            case .control, .format, .lineSeparator, .paragraphSeparator:
                return false

            default:
                return true
            }
        }
    }

    /// Whether the character may not begin or end a portable name.
    private static func isLoose(_ character: Character) -> Bool {
        character == " " || character == "."
    }
}
