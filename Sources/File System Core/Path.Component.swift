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
